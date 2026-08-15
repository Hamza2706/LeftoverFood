using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Net;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;

namespace LeftoverFoodSystem
{
    /// <summary>
    /// Values for FoodDonations.GeoPrecision — how accurate a stored
    /// coordinate pair actually is.
    /// </summary>
    public static class GeoPrecision
    {
        /// <summary>Nominatim matched the full pickup address.</summary>
        public const string Exact = "Exact";

        /// <summary>Only the city resolved — treat the pin as indicative.</summary>
        public const string City = "City";
    }

    /// <summary>A resolved coordinate pair.</summary>
    public class GeoPoint
    {
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }

        /// <summary>
        /// How much to trust this point — "Exact" when the full address
        /// matched, "City" when only the city did. The UI must label a City
        /// point as approximate; a pin at the city centre presented as the
        /// pickup point would be actively misleading.
        /// </summary>
        public string Precision { get; set; }

        public bool IsExact { get { return Precision == GeoPrecision.Exact; } }

        /// <summary>Invariant-culture strings for embedding in JavaScript.</summary>
        public string LatText { get { return Latitude.ToString(CultureInfo.InvariantCulture); } }
        public string LngText { get { return Longitude.ToString(CultureInfo.InvariantCulture); } }
    }

    /// <summary>
    /// Server-side address to lat/lng, via OpenStreetMap's Nominatim service
    /// (Phase 5). No API key and no billing account — the tradeoff is that it
    /// is a free community service with a usage policy we have to respect:
    ///
    ///   1. An identifying User-Agent is REQUIRED. Requests without one are
    ///      refused. Set Geocoding.UserAgent in Web.config with a real contact.
    ///   2. Maximum one request per second. Enforced here by a process-wide
    ///      lock in Throttle().
    ///   3. Results must be cached rather than re-requested. Donations store
    ///      their coordinates on the row; everything else (NGO drop-off
    ///      addresses) goes through the GeocodeCache table.
    ///
    /// Every failure path returns null rather than throwing. Geocoding is an
    /// enhancement, never a precondition — a donation must still post when
    /// Nominatim is slow, down, or blocked by a firewall.
    /// </summary>
    public class GeocodingService
    {
        private static readonly object ThrottleLock = new object();
        private static DateTime _lastRequestUtc = DateTime.MinValue;

        /// <summary>
        /// Resolve a donation's pickup location, degrading gracefully.
        ///
        /// Tries the full address first. Real addresses here frequently do not
        /// match (typos, informal block/sector naming, incomplete streets), so
        /// on a miss it falls back to the city — which is genuinely useful for
        /// "roughly where is this", but is only acceptable because the returned
        /// Precision forces the caller to label it as approximate.
        ///
        /// Returns null when even the city fails, in which case the UI shows
        /// the address as text and no map at all.
        /// </summary>
        public static GeoPoint GeocodeDonation(string pickupAddress, string city)
        {
            string country = AppSetting("Geocoding.Country", "Pakistan");

            if (!string.IsNullOrWhiteSpace(pickupAddress))
            {
                string full = pickupAddress.Trim();
                if (!string.IsNullOrWhiteSpace(city)) full += ", " + city.Trim();
                full += ", " + country;

                GeoPoint exact = Geocode(full);
                if (exact != null)
                {
                    exact.Precision = GeoPrecision.Exact;
                    return exact;
                }
            }

            if (!string.IsNullOrWhiteSpace(city))
            {
                GeoPoint cityPoint = Geocode(city.Trim() + ", " + country);
                if (cityPoint != null)
                {
                    cityPoint.Precision = GeoPrecision.City;
                    return cityPoint;
                }
            }

            return null;
        }

        /// <summary>
        /// Resolve an address, consulting GeocodeCache first.
        /// Returns null if the address can't be resolved.
        /// </summary>
        public static GeoPoint Geocode(string address)
        {
            if (string.IsNullOrWhiteSpace(address)) return null;

            string key = Normalise(address);

            try
            {
                DataTable cached = DBHelper.ExecuteQuery(
                    "SELECT Latitude, Longitude FROM GeocodeCache WHERE AddressText = @Addr",
                    new SqlParameter[] { new SqlParameter("@Addr", key) });

                if (cached.Rows.Count > 0)
                {
                    // A cached row with NULL coordinates is a remembered
                    // failure — the address didn't resolve last time, so don't
                    // hammer Nominatim with it again on every page view.
                    if (cached.Rows[0]["Latitude"] == DBNull.Value) return null;

                    return new GeoPoint
                    {
                        Latitude = Convert.ToDecimal(cached.Rows[0]["Latitude"]),
                        Longitude = Convert.ToDecimal(cached.Rows[0]["Longitude"])
                    };
                }
            }
            catch (Exception ex)
            {
                LogError("Geocode cache read for '" + key + "'", ex);
                // Fall through and try the live lookup anyway.
            }

            GeoPoint point = Lookup(address);
            StoreInCache(key, point);
            return point;
        }

        /// <summary>
        /// Live Nominatim lookup with no cache read. Used by the backfill
        /// script and by Geocode() on a cache miss.
        /// </summary>
        public static GeoPoint Lookup(string address)
        {
            if (string.IsNullOrWhiteSpace(address)) return null;

            try
            {
                Throttle();

                // Bias results towards the app's country. Nominatim resolves
                // bare street names poorly without it — "Gulshan-e-Iqbal" alone
                // matches places in several countries.
                string url = "https://nominatim.openstreetmap.org/search"
                           + "?q=" + Uri.EscapeDataString(address.Trim())
                           + "&format=json&limit=1&addressdetails=0"
                           + "&countrycodes=" + AppSetting("Geocoding.CountryCodes", "pk");

                // .NET 4.7.2 normally negotiates TLS 1.2 from the OS default,
                // but an older machine-level default would fail the handshake
                // against Nominatim, so pin it explicitly.
                ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;

                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "GET";
                req.Accept = "application/json";
                // Required by Nominatim's usage policy — a request without a
                // meaningful User-Agent gets rejected.
                req.UserAgent = AppSetting("Geocoding.UserAgent", "FoodBridge-FYP/1.0");
                req.Timeout = 8000;
                req.ReadWriteTimeout = 8000;

                string json;
                using (WebResponse resp = req.GetResponse())
                using (StreamReader reader = new StreamReader(resp.GetResponseStream()))
                {
                    json = reader.ReadToEnd();
                }

                return ParseFirstResult(json);
            }
            catch (Exception ex)
            {
                LogError("Geocode lookup for '" + address + "'", ex);
                return null;
            }
        }

        // ------------------------------------------------------------------
        // Internals
        // ------------------------------------------------------------------

        /// <summary>
        /// Parse Nominatim's response. Uses JavaScriptSerializer from
        /// System.Web.Extensions, which is already referenced — no need to pull
        /// in Json.NET for one small payload.
        /// </summary>
        private static GeoPoint ParseFirstResult(string json)
        {
            if (string.IsNullOrWhiteSpace(json)) return null;

            var serializer = new JavaScriptSerializer();
            var results = serializer.DeserializeObject(json) as object[];
            if (results == null || results.Length == 0) return null;

            var first = results[0] as Dictionary<string, object>;
            if (first == null || !first.ContainsKey("lat") || !first.ContainsKey("lon")) return null;

            decimal lat, lon;
            // Nominatim returns coordinates as strings and always in invariant
            // format, so parse invariantly — a comma-decimal server locale
            // would otherwise mis-read "24.86" as 2486.
            if (!decimal.TryParse(Convert.ToString(first["lat"]), NumberStyles.Float, CultureInfo.InvariantCulture, out lat)) return null;
            if (!decimal.TryParse(Convert.ToString(first["lon"]), NumberStyles.Float, CultureInfo.InvariantCulture, out lon)) return null;

            // Guard against nonsense before it reaches a decimal(9,6) column,
            // which would throw on overflow.
            if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;

            return new GeoPoint { Latitude = lat, Longitude = lon };
        }

        /// <summary>
        /// Hold every caller to at most one outbound request per second, as
        /// Nominatim's policy requires. Crude but correct for a single-process
        /// app of this size; a web farm would need a shared limiter.
        /// </summary>
        private static void Throttle()
        {
            lock (ThrottleLock)
            {
                TimeSpan since = DateTime.UtcNow - _lastRequestUtc;
                int minGapMs = 1100;   // a little over 1s of headroom

                if (since.TotalMilliseconds < minGapMs)
                    Thread.Sleep(minGapMs - (int)since.TotalMilliseconds);

                _lastRequestUtc = DateTime.UtcNow;
            }
        }

        private static void StoreInCache(string key, GeoPoint point)
        {
            try
            {
                DBHelper.ExecuteNonQuery(
                    @"IF NOT EXISTS (SELECT 1 FROM GeocodeCache WHERE AddressText = @Addr)
                          INSERT INTO GeocodeCache (AddressText, Latitude, Longitude)
                          VALUES (@Addr, @Lat, @Lng)",
                    new SqlParameter[]
                    {
                        new SqlParameter("@Addr", key),
                        new SqlParameter("@Lat", point == null ? (object)DBNull.Value : point.Latitude),
                        new SqlParameter("@Lng", point == null ? (object)DBNull.Value : point.Longitude)
                    });
            }
            catch (Exception ex)
            {
                LogError("Geocode cache write for '" + key + "'", ex);
            }
        }

        /// <summary>
        /// Cache key. Collapses whitespace and case so "12 Main St" and
        /// "12  main st " don't become two separate cache entries (and two
        /// separate Nominatim requests).
        /// </summary>
        private static string Normalise(string address)
        {
            string s = (address ?? "").Trim().ToLowerInvariant();
            while (s.Contains("  ")) s = s.Replace("  ", " ");
            return s.Length > 400 ? s.Substring(0, 400) : s;
        }

        private static string AppSetting(string key, string fallback)
        {
            string v = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        /// <summary>
        /// Shares the notification error log — same fail-soft rationale, and
        /// one file is easier to check than two.
        /// </summary>
        private static void LogError(string context, Exception ex)
        {
            try
            {
                if (HttpContext.Current == null) return;

                string dir = HttpContext.Current.Server.MapPath("~/App_Data");
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                File.AppendAllText(
                    Path.Combine(dir, "notification-errors.log"),
                    string.Format("{0:yyyy-MM-dd HH:mm:ss}  [geocode] {1}{2}{3}{2}{2}",
                                  DateTime.Now, context, Environment.NewLine, ex));
            }
            catch
            {
            }
        }
    }
}
