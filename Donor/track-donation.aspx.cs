using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using LeftoverFoodSystem;

namespace LeftoverFood.Donor
{
    public partial class track_donation : System.Web.UI.Page
    {
        private string _status = "";

        protected string VolunteerName { get; private set; } = "";

        /// <summary>
        /// Phase 6c. Gates the rating card — you can only rate a delivery that
        /// actually completed. ~/Ratings.aspx re-checks this itself; this is
        /// only about not showing a dead link.
        /// </summary>
        protected bool IsDelivered { get { return _status == "Delivered"; } }

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Donor");

            if (!IsPostBack)
            {
                LoadDonation();
            }
        }

        private void LoadDonation()
        {
            int donationId;
            if (!int.TryParse(Request.QueryString["id"], out donationId))
            {
                ShowNotFound();
                return;
            }

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.Servings, d.Category, d.DietaryInfo,
                         d.PickupAddress, d.City, d.Status, d.CreatedAt, d.ApprovedAt, d.ExpiryTime, d.DonorID,
                         d.Latitude, d.Longitude, d.GeoPrecision,
                         r.RequestedAt, ngo.FullName AS NGOName, ngo.OrganizationName AS NGOOrgName,
                         ngo.Address AS NGOAddress, ngo.City AS NGOCity,
                         vol.FullName AS VolunteerName, a.AssignedAt, a.PickedUpAt, a.DeliveredAt
                  FROM FoodDonations d
                  LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  LEFT JOIN Users ngo ON ngo.UserID = r.NGOID
                  LEFT JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                  LEFT JOIN Users vol ON vol.UserID = a.VolunteerID
                  WHERE d.DonationID = @DonationID",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (dt.Rows.Count == 0 || Convert.ToInt32(dt.Rows[0]["DonorID"]) != SessionHelper.GetUserID())
            {
                ShowNotFound();
                return;
            }

            DataRow row = dt.Rows[0];
            _status = row["Status"].ToString();
            VolunteerName = (row["VolunteerName"] as string) ?? "";

            litDonationId.Text = row["DonationID"].ToString();
            litDetailId.Text = row["DonationID"].ToString();
            litPostedDate.Text = Convert.ToDateTime(row["CreatedAt"]).ToString("MMMM d, yyyy");
            litFoodType.Text = row["FoodDescription"].ToString();
            litCategory.Text = row["Category"] == DBNull.Value ? "—" : row["Category"].ToString();
            litQuantity.Text = row["Quantity"].ToString();
            litServings.Text = row["Servings"] == DBNull.Value ? "—" : ("~" + row["Servings"] + " people");
            litDietary.Text = row["DietaryInfo"] == DBNull.Value || string.IsNullOrWhiteSpace(row["DietaryInfo"].ToString()) ? "—" : row["DietaryInfo"].ToString();
            litPickupLocation.Text = row["PickupAddress"] + ", " + row["City"];
            litNgoAssigned.Text = row["NGOName"] == DBNull.Value ? "Not yet accepted" : NgoLabel(row["NGOOrgName"], row["NGOName"]);
            litVolunteerAssigned.Text = string.IsNullOrEmpty(VolunteerName) ? "Not yet assigned" : VolunteerName;

            pnlVolunteerInfo.Visible = !string.IsNullOrEmpty(VolunteerName);

            BuildTimeline(row);
            BuildExpiryTracker(row);
            BuildMap(row);
        }

        // ------------------------------------------------------------------
        // Map (Phase 5)
        // ------------------------------------------------------------------

        protected string MapLat { get; private set; } = "";
        protected string MapLng { get; private set; } = "";
        protected string MapPrecision { get; private set; } = "";
        protected string MapPickupLabel { get; private set; } = "";
        protected string MapDestLat { get; private set; } = "";
        protected string MapDestLng { get; private set; } = "";
        protected string MapDestLabel { get; private set; } = "";
        protected string MapTrackUrl { get; private set; } = "";
        protected string MapPollSeconds { get; private set; } = "20";
        protected string MapTileUrl { get; private set; } = "";
        protected string MapAttribution { get; private set; } = "";

        /// <summary>
        /// Populate the map's data- attributes, or fall back to showing the
        /// address as text when the pickup address never resolved to
        /// coordinates — which is common with real addresses here.
        /// </summary>
        private void BuildMap(DataRow row)
        {
            MapTileUrl = Setting("Map.TileUrl", "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png");
            MapAttribution = Setting("Map.Attribution", "© OpenStreetMap contributors");
            MapPollSeconds = Setting("Map.PollSeconds", "20");

            if (row["Latitude"] == DBNull.Value || row["Longitude"] == DBNull.Value)
            {
                pnlNoMap.Visible = true;
                litFallbackAddress.Text = Server.HtmlEncode(
                    row["PickupAddress"] + ", " + row["City"]);
                litMapNote.Text = "No map available";
                return;
            }

            MapLat = Convert.ToDecimal(row["Latitude"]).ToString(CultureInfo.InvariantCulture);
            MapLng = Convert.ToDecimal(row["Longitude"]).ToString(CultureInfo.InvariantCulture);
            MapPrecision = Convert.ToString(row["GeoPrecision"]);
            MapPickupLabel = Server.HtmlEncode(Convert.ToString(row["PickupAddress"]));

            // Be explicit in the header about how much the pin can be trusted.
            // A city-level point is the city centre, not the pickup address.
            litMapNote.Text = MapPrecision == GeoPrecision.City
                ? "Approximate location — city level only"
                : "OpenStreetMap";

            // NGO drop-off. Geocoded through the cache, so an NGO's address is
            // only ever sent to Nominatim once.
            string ngoAddress = Convert.ToString(row["NGOAddress"]);
            if (!string.IsNullOrWhiteSpace(ngoAddress))
            {
                GeoPoint dest = GeocodingService.GeocodeDonation(
                    ngoAddress, Convert.ToString(row["NGOCity"]));

                if (dest != null)
                {
                    MapDestLat = dest.LatText;
                    MapDestLng = dest.LngText;
                    MapDestLabel = Server.HtmlEncode(
                        NgoLabel(row["NGOOrgName"], row["NGOName"]) + " — drop-off");
                }
            }

            // Only poll for a live volunteer position while a delivery is
            // actually in progress. The handler enforces this too, but there is
            // no point issuing requests that can only ever answer "no".
            if (_status == "Assigned" || _status == "PickedUp")
            {
                MapTrackUrl = ResolveUrl("~/LocationHandler.ashx?donationId="
                                         + Convert.ToInt32(row["DonationID"]));
            }

            pnlMap.Visible = true;
        }

        private static string Setting(string key, string fallback)
        {
            string v = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        private void ShowNotFound()
        {
            pnlContent.Visible = false;
            pnlNotFound.Visible = true;
        }

        private void BuildTimeline(DataRow row)
        {
            var steps = new List<TrackStep>();

            if (_status == "Rejected" || _status == "Cancelled")
            {
                steps.Add(new TrackStep
                {
                    Title = "Food Posted",
                    Icon = "bi-check2",
                    StepClass = "done",
                    When = Convert.ToDateTime(row["CreatedAt"]).ToString("MMM d, yyyy · h:mm tt"),
                    Detail = $"{row["FoodDescription"]} — {row["Quantity"]} posted ({row["PickupAddress"]}, {row["City"]})"
                });
                steps.Add(new TrackStep
                {
                    Title = _status == "Rejected" ? "Rejected by Admin" : "Cancelled",
                    Icon = "bi-x-circle",
                    StepClass = "active",
                    When = row["ApprovedAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["ApprovedAt"]).ToString("MMM d, yyyy · h:mm tt"),
                    Detail = _status == "Rejected" ? "This donation was not approved by the admin." : "You cancelled this donation."
                });
                rptSteps.DataSource = steps;
                rptSteps.DataBind();
                return;
            }

            int stage = Stage(_status);

            steps.Add(new TrackStep
            {
                Title = "Food Posted",
                Icon = "bi-check2",
                StepClass = StepClassFor(0, stage),
                When = Convert.ToDateTime(row["CreatedAt"]).ToString("MMM d, yyyy · h:mm tt"),
                Detail = $"{row["FoodDescription"]} — {row["Quantity"]} posted ({row["PickupAddress"]}, {row["City"]})"
            });

            steps.Add(new TrackStep
            {
                Title = "Approved by Admin",
                Icon = "bi-check2",
                StepClass = StepClassFor(1, stage),
                When = row["ApprovedAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["ApprovedAt"]).ToString("MMM d, yyyy · h:mm tt"),
                Detail = stage >= 1 ? "Donation verified and approved. Visible to NGOs now." : ""
            });

            steps.Add(new TrackStep
            {
                Title = "Accepted by NGO",
                Icon = "bi-check2",
                StepClass = StepClassFor(2, stage),
                When = row["RequestedAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["RequestedAt"]).ToString("MMM d, yyyy · h:mm tt"),
                Detail = stage >= 2 ? $"{NgoLabel(row["NGOOrgName"], row["NGOName"])} accepted the request." : ""
            });

            string pickupWhen = "";
            string pickupDetail = "";
            string volunteerName = string.IsNullOrEmpty(VolunteerName) ? "A volunteer" : VolunteerName;
            if (_status == "Assigned")
            {
                pickupWhen = row["AssignedAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["AssignedAt"]).ToString("MMM d, yyyy · h:mm tt");
                pickupDetail = $"{volunteerName} was assigned and is heading to pick up the food.";
            }
            else if (stage >= 3)
            {
                pickupWhen = row["PickedUpAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["PickedUpAt"]).ToString("MMM d, yyyy · h:mm tt");
                pickupDetail = $"{volunteerName} picked up the food.";
            }

            steps.Add(new TrackStep
            {
                Title = _status == "PickedUp" ? "Picked Up — In Transit" : "Picked Up",
                Icon = "bi-truck",
                StepClass = StepClassFor(3, stage),
                When = pickupWhen,
                Detail = pickupDetail
            });

            steps.Add(new TrackStep
            {
                Title = "Delivered to NGO",
                Icon = "bi-geo-alt-fill",
                StepClass = StepClassFor(4, stage),
                When = row["DeliveredAt"] == DBNull.Value ? "" : Convert.ToDateTime(row["DeliveredAt"]).ToString("MMM d, yyyy · h:mm tt"),
                Detail = stage >= 4 ? $"Delivered to {NgoLabel(row["NGOOrgName"], row["NGOName"])}." : (_status == "PickedUp" ? "In transit — awaiting delivery confirmation." : "")
            });

            rptSteps.DataSource = steps;
            rptSteps.DataBind();
        }

        private int Stage(string status)
        {
            switch (status)
            {
                case "Posted": return 0;
                case "Approved": return 1;
                case "Requested": return 2;
                case "Assigned": return 3;
                case "PickedUp": return 3;
                case "Delivered": return 4;
                default: return 0;
            }
        }

        private string StepClassFor(int stepIndex, int stage)
        {
            if (_status == "Delivered") return "done";
            if (stepIndex < stage) return "done";
            if (stepIndex == stage) return "active";
            return "pending";
        }

        private void BuildExpiryTracker(DataRow row)
        {
            if (_status == "Delivered" || _status == "Rejected" || _status == "Cancelled")
            {
                pnlExpiry.Visible = false;
                return;
            }

            DateTime expiry = Convert.ToDateTime(row["ExpiryTime"]);
            DateTime posted = Convert.ToDateTime(row["CreatedAt"]);
            TimeSpan remaining = expiry - DateTime.Now;
            TimeSpan total = expiry - posted;

            litTimeRemaining.Text = remaining.TotalMinutes <= 0
                ? "Expired"
                : (remaining.TotalHours < 1 ? $"{(int)remaining.TotalMinutes}m" : $"{(int)remaining.TotalHours}h {remaining.Minutes}m");
            litExpiryTime.Text = expiry.ToString("h:mm tt");
            litExpiryTime2.Text = expiry.ToString("h:mm tt");
            litPostedTime.Text = posted.ToString("h:mm tt");

            double pct = total.TotalMinutes > 0
                ? Math.Max(0, Math.Min(100, (1 - remaining.TotalMinutes / total.TotalMinutes) * 100))
                : 100;
            expiryFill.Style["width"] = pct.ToString("0") + "%";
            if (remaining.TotalMinutes <= 0)
                expiryFill.Style["background"] = "var(--red)";
        }

        // Markup helpers
        protected string StatusBadgeClass()
        {
            switch (_status)
            {
                case "Posted": return "badge-pending";
                case "Approved": return "badge-verified";
                case "Requested": return "badge-accepted";
                case "Assigned":
                case "PickedUp": return "badge-accepted";
                case "Delivered": return "badge-delivered";
                case "Rejected":
                case "Cancelled": return "badge-rejected";
                default: return "";
            }
        }

        protected string StatusLabel()
        {
            switch (_status)
            {
                case "Posted": return "Posted";
                case "Approved": return "Approved";
                case "Requested": return "Accepted by NGO";
                case "Assigned": return "Volunteer Assigned";
                case "PickedUp": return "In Transit";
                case "Delivered": return "Delivered";
                case "Rejected": return "Rejected";
                case "Cancelled": return "Cancelled";
                default: return _status;
            }
        }

        private string NgoLabel(object orgName, object fullName)
        {
            return orgName != DBNull.Value && !string.IsNullOrWhiteSpace(orgName.ToString())
                ? orgName.ToString()
                : fullName.ToString();
        }

        private class TrackStep
        {
            public string Title { get; set; }
            public string Icon { get; set; }
            public string StepClass { get; set; }
            public string When { get; set; }
            public string Detail { get; set; }
        }
    }
}
