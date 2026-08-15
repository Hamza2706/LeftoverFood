using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    /// <summary>
    /// Volunteer live-location endpoint (Phase 5).
    ///
    /// The roadmap's architecture note reserves .ashx handlers for the few
    /// places real AJAX is needed rather than a postback; a position ping every
    /// 20 seconds is exactly that case — a full Web Forms postback would reload
    /// the page each time.
    ///
    /// Two operations:
    ///
    ///   POST ?action=report   volunteer's browser submits its own position
    ///   GET  ?donationId=N    tracking page reads the volunteer's last position
    ///
    /// AUTHORISATION — this endpoint handles a real person's GPS position, so
    /// neither direction trusts anything the caller sends about identity:
    ///
    ///   Reporting  the volunteer is taken from the session, never from the
    ///              request body. The assignment must belong to that volunteer
    ///              and still be active, and they must have opted in via
    ///              Users.ShareLocation. A volunteer cannot report a position
    ///              "for" anyone else.
    ///
    ///   Reading    the caller must be the donor of that specific donation, the
    ///              NGO whose request was accepted for it, or an Admin. There is
    ///              deliberately no "look up volunteer X" route — position is
    ///              only ever reachable through a delivery you are part of, and
    ///              only while it is in progress.
    /// </summary>
    public class LocationHandler : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            // Position data must never be cached by a proxy or the browser.
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();

            // Not signed in — 401 rather than a redirect, since the caller is
            // JavaScript and would only choke on a login page.
            if (context.Session["UserID"] == null)
            {
                Deny(context, 401, "Not signed in.");
                return;
            }

            try
            {
                if (string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
                    HandleReport(context);
                else
                    HandleRead(context);
            }
            catch (Exception)
            {
                // Never leak exception detail from an endpoint that deals in
                // personal location data.
                Deny(context, 500, "Unexpected error.");
            }
        }

        // ------------------------------------------------------------------
        // POST — a volunteer reporting their own position
        // ------------------------------------------------------------------

        private void HandleReport(HttpContext context)
        {
            if (SessionHelper.GetRole() != "Volunteer")
            {
                Deny(context, 403, "Only volunteers report location.");
                return;
            }

            int volunteerId = SessionHelper.GetUserID();

            decimal lat, lng;
            if (!TryDecimal(context.Request.Form["lat"], out lat) ||
                !TryDecimal(context.Request.Form["lng"], out lng) ||
                lat < -90 || lat > 90 || lng < -180 || lng > 180)
            {
                Deny(context, 400, "Invalid coordinates.");
                return;
            }

            decimal accuracy;
            bool hasAccuracy = TryDecimal(context.Request.Form["accuracy"], out accuracy);

            // Consent gate. Checked server-side on every single ping, not just
            // when the toggle is flipped — switching it off must stop
            // collection immediately, even if a stale tab keeps posting.
            object share = DBHelper.ExecuteScalar(
                "SELECT ShareLocation FROM Users WHERE UserID = @UserID",
                new SqlParameter[] { new SqlParameter("@UserID", volunteerId) });

            if (share == null || share == DBNull.Value || !Convert.ToBoolean(share))
            {
                Deny(context, 403, "Location sharing is turned off.");
                return;
            }

            // Resolve the volunteer's own active assignment rather than trusting
            // an AssignmentID from the request. Scoped by VolunteerID and by
            // status, so a position can only ever attach to a delivery this
            // volunteer is actually carrying out right now.
            object assignment = DBHelper.ExecuteScalar(
                @"SELECT TOP 1 AssignmentID FROM DeliveryAssignments
                  WHERE VolunteerID = @VolunteerID AND Status IN ('Assigned', 'PickedUp')
                  ORDER BY AssignedAt DESC",
                new SqlParameter[] { new SqlParameter("@VolunteerID", volunteerId) });

            if (assignment == null || assignment == DBNull.Value)
            {
                // Not an error — the app just has nothing to track right now.
                Write(context, new Dictionary<string, object>
                {
                    { "ok", false }, { "tracking", false },
                    { "message", "No active delivery." }
                });
                return;
            }

            DBHelper.ExecuteNonQuery(
                @"INSERT INTO VolunteerLocations (VolunteerID, AssignmentID, Latitude, Longitude, Accuracy)
                  VALUES (@VolunteerID, @AssignmentID, @Lat, @Lng, @Accuracy)",
                new SqlParameter[]
                {
                    new SqlParameter("@VolunteerID", volunteerId),
                    new SqlParameter("@AssignmentID", Convert.ToInt32(assignment)),
                    new SqlParameter("@Lat", lat),
                    new SqlParameter("@Lng", lng),
                    new SqlParameter("@Accuracy", hasAccuracy ? (object)accuracy : DBNull.Value)
                });

            Write(context, new Dictionary<string, object> { { "ok", true }, { "tracking", true } });
        }

        // ------------------------------------------------------------------
        // GET — reading the volunteer's last position for one donation
        // ------------------------------------------------------------------

        private void HandleRead(HttpContext context)
        {
            int donationId;
            if (!int.TryParse(context.Request.QueryString["donationId"], out donationId))
            {
                Deny(context, 400, "Missing donationId.");
                return;
            }

            int userId = SessionHelper.GetUserID();
            string role = SessionHelper.GetRole();

            // One query establishes both "does this donation exist" and "is the
            // caller entitled to see its volunteer" — the caller's ID is
            // compared against the donor and the accepted NGO in SQL, so no
            // authorisation decision depends on anything they supplied.
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonorID, r.NGOID, a.AssignmentID, a.Status AS AssignmentStatus,
                         u.ShareLocation
                  FROM FoodDonations d
                  LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  LEFT JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                  LEFT JOIN Users u ON u.UserID = a.VolunteerID
                  WHERE d.DonationID = @DonationID",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (dt.Rows.Count == 0)
            {
                Deny(context, 404, "Donation not found.");
                return;
            }

            DataRow row = dt.Rows[0];

            bool isDonor = row["DonorID"] != DBNull.Value && Convert.ToInt32(row["DonorID"]) == userId;
            bool isNgo = row["NGOID"] != DBNull.Value && Convert.ToInt32(row["NGOID"]) == userId;
            bool isAdmin = role == "Admin";

            if (!isDonor && !isNgo && !isAdmin)
            {
                // Same response as a missing donation, so this cannot be used
                // to probe which donation IDs exist.
                Deny(context, 404, "Donation not found.");
                return;
            }

            if (row["AssignmentID"] == DBNull.Value)
            {
                Write(context, NoPosition("No volunteer assigned yet."));
                return;
            }

            string assignmentStatus = Convert.ToString(row["AssignmentStatus"]);
            if (assignmentStatus == "Delivered" || assignmentStatus == "Failed")
            {
                // Tracking ends with the delivery. Past positions stay in the
                // table as a record but are not served once the job is done.
                Write(context, NoPosition("Delivery complete.", true));
                return;
            }

            if (row["ShareLocation"] == DBNull.Value || !Convert.ToBoolean(row["ShareLocation"]))
            {
                Write(context, NoPosition("Volunteer has not enabled location sharing."));
                return;
            }

            DataTable pos = DBHelper.ExecuteQuery(
                @"SELECT TOP 1 Latitude, Longitude, Accuracy, RecordedAt
                  FROM VolunteerLocations
                  WHERE AssignmentID = @AssignmentID
                  ORDER BY RecordedAt DESC, LocationID DESC",
                new SqlParameter[] { new SqlParameter("@AssignmentID", Convert.ToInt32(row["AssignmentID"])) });

            if (pos.Rows.Count == 0)
            {
                Write(context, NoPosition("Waiting for volunteer location…"));
                return;
            }

            DateTime recordedAt = Convert.ToDateTime(pos.Rows[0]["RecordedAt"]);

            // A position from an hour ago is not "where the volunteer is". Stop
            // showing a marker that would misrepresent a stale fix as current.
            if ((DateTime.Now - recordedAt).TotalMinutes > 15)
            {
                Write(context, NoPosition("Last known position is out of date."));
                return;
            }

            Write(context, new Dictionary<string, object>
            {
                { "ok", true },
                { "lat", Convert.ToDecimal(pos.Rows[0]["Latitude"]) },
                { "lng", Convert.ToDecimal(pos.Rows[0]["Longitude"]) },
                { "accuracy", pos.Rows[0]["Accuracy"] == DBNull.Value
                                ? null : (object)Convert.ToDecimal(pos.Rows[0]["Accuracy"]) },
                { "ago", Ago(recordedAt) }
            });
        }

        // ------------------------------------------------------------------
        // Helpers
        // ------------------------------------------------------------------

        private static Dictionary<string, object> NoPosition(string message)
        {
            return NoPosition(message, false);
        }

        /// <summary>
        /// <paramref name="done"/> marks a state that can never change again, so
        /// the caller can stop polling instead of asking every 20 seconds
        /// forever. Only the delivery ending is terminal: "no volunteer yet",
        /// "sharing is off" and "position is stale" can all still resolve, so
        /// those keep the poll alive.
        ///
        /// It is an explicit flag rather than the client matching on the message
        /// text, which would break the moment the wording changed.
        /// </summary>
        private static Dictionary<string, object> NoPosition(string message, bool done)
        {
            return new Dictionary<string, object>
            {
                { "ok", false }, { "lat", null }, { "lng", null },
                { "message", message }, { "done", done }
            };
        }

        private static string Ago(DateTime when)
        {
            TimeSpan span = DateTime.Now - when;
            if (span.TotalSeconds < 60) return "just now";
            if (span.TotalMinutes < 60) return (int)span.TotalMinutes + " min ago";
            return when.ToString("h:mm tt");
        }

        /// <summary>
        /// Parse invariantly — the browser always sends coordinates with a dot
        /// decimal separator, regardless of the user's or server's locale.
        /// </summary>
        private static bool TryDecimal(string raw, out decimal value)
        {
            return decimal.TryParse(raw, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
        }

        private static void Deny(HttpContext context, int status, string message)
        {
            context.Response.StatusCode = status;
            Write(context, new Dictionary<string, object> { { "ok", false }, { "message", message } });
        }

        private static void Write(HttpContext context, Dictionary<string, object> payload)
        {
            context.Response.Write(new JavaScriptSerializer().Serialize(payload));
        }
    }
}
