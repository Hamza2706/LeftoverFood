using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Volunteer
{
    public partial class volunteer_dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Volunteer");

            if (!IsPostBack)
            {
                BindStats();
                BindActiveTasks();
                BindCompleted();
                BindLocationSharing();
            }
        }

        // ------------------------------------------------------------------
        // Map helpers (Phase 5) — called from rptActiveTasks' <%# %> bindings
        // ------------------------------------------------------------------

        /// <summary>
        /// Per-render memo of resolved NGO drop-off points.
        ///
        /// The markup asks for the destination latitude and longitude
        /// separately, and several assignments often share one NGO, so without
        /// this the same address would be resolved several times per page.
        /// GeocodeCache already avoids re-hitting Nominatim, but this avoids
        /// the repeated database round trips too.
        /// </summary>
        private readonly Dictionary<string, GeoPoint> _destCache =
            new Dictionary<string, GeoPoint>(StringComparer.OrdinalIgnoreCase);

        protected string MapTileUrl
        {
            get { return Setting("Map.TileUrl", "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"); }
        }

        protected string MapAttribution
        {
            get { return Setting("Map.Attribution", "© OpenStreetMap contributors"); }
        }

        protected bool HasCoords(object latitude)
        {
            return latitude != null && latitude != DBNull.Value;
        }

        /// <summary>
        /// Coordinate for a data- attribute, invariant so a comma-decimal
        /// server locale can't emit "24,86" and break parseFloat in the JS.
        /// </summary>
        protected string Coord(object value)
        {
            if (value == null || value == DBNull.Value) return "";
            return Convert.ToDecimal(value).ToString(CultureInfo.InvariantCulture);
        }

        private GeoPoint Dest(object address, object city)
        {
            string addr = Convert.ToString(address);
            if (string.IsNullOrWhiteSpace(addr)) return null;

            string key = addr + "|" + Convert.ToString(city);
            if (!_destCache.ContainsKey(key))
                _destCache[key] = GeocodingService.GeocodeDonation(addr, Convert.ToString(city));

            return _destCache[key];
        }

        protected string DestLat(object address, object city)
        {
            GeoPoint p = Dest(address, city);
            return p == null ? "" : p.LatText;
        }

        protected string DestLng(object address, object city)
        {
            GeoPoint p = Dest(address, city);
            return p == null ? "" : p.LngText;
        }

        /// <summary>
        /// Turn-by-turn directions on openstreetmap.org — no API key, matching
        /// the rest of Phase 5. Returns "" when the pickup point is unknown, in
        /// which case the markup hides the link rather than opening a map
        /// pointing at nothing.
        /// </summary>
        protected string DirectionsUrl(object pickupLat, object pickupLng,
                                       object ngoAddress, object ngoCity)
        {
            if (!HasCoords(pickupLat) || !HasCoords(pickupLng)) return "";

            string from = Coord(pickupLat) + "," + Coord(pickupLng);
            GeoPoint dest = Dest(ngoAddress, ngoCity);

            // Without a destination this still usefully centres on the pickup.
            string to = dest == null ? "" : dest.LatText + "," + dest.LngText;

            return "https://www.openstreetmap.org/directions?engine=fossgis_osrm_car"
                 + "&route=" + from + ";" + to;
        }

        private static string Setting(string key, string fallback)
        {
            string v = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        // ------------------------------------------------------------------
        // Location sharing (Phase 5)
        // ------------------------------------------------------------------

        /// <summary>"true"/"false" for the reporting script's guard clauses.</summary>
        protected string ShareLocationJs { get; private set; } = "false";
        protected string HasActiveTaskJs { get; private set; } = "false";

        private void BindLocationSharing()
        {
            int volunteerId = SessionHelper.GetUserID();

            object share = DBHelper.ExecuteScalar(
                "SELECT ShareLocation FROM Users WHERE UserID = @UserID",
                new SqlParameter[] { new SqlParameter("@UserID", volunteerId) });

            chkShareLocation.Checked = share != null && share != DBNull.Value && Convert.ToBoolean(share);

            // The browser only starts reporting when there is something to
            // report about; the endpoint enforces the same rule server-side.
            object active = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM DeliveryAssignments
                  WHERE VolunteerID = @VolunteerID AND Status IN ('Assigned', 'PickedUp')",
                new SqlParameter[] { new SqlParameter("@VolunteerID", volunteerId) });

            ShareLocationJs = chkShareLocation.Checked ? "true" : "false";
            HasActiveTaskJs = (active != null && Convert.ToInt32(active) > 0) ? "true" : "false";
        }

        protected void chkShareLocation_CheckedChanged(object sender, EventArgs e)
        {
            int volunteerId = SessionHelper.GetUserID();

            DBHelper.ExecuteNonQuery(
                "UPDATE Users SET ShareLocation = @Share WHERE UserID = @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@Share", chkShareLocation.Checked),
                    new SqlParameter("@UserID", volunteerId)
                });

            if (!chkShareLocation.Checked)
            {
                // Switching off deletes the positions already collected, rather
                // than just hiding them. Consent withdrawn means the data goes —
                // keeping a trail the volunteer thinks they turned off would be
                // the opposite of what the toggle promises.
                DBHelper.ExecuteNonQuery(
                    "DELETE FROM VolunteerLocations WHERE VolunteerID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", volunteerId) });

                ShowMessage("Location sharing turned off. Your stored positions have been deleted.", "alert-success");
            }
            else
            {
                ShowMessage("Location sharing is on. Your browser will ask for permission.", "alert-success");
            }

            BindLocationSharing();
        }

        private void BindStats()
        {
            int volunteerId = SessionHelper.GetUserID();

            string activeCount = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM DeliveryAssignments WHERE VolunteerID = @VolunteerID AND Status IN ('Assigned', 'PickedUp')",
                new SqlParameter[] { new SqlParameter("@VolunteerID", volunteerId) }).ToString();

            litActiveTasks.Text = activeCount;
            litActiveTasksInline.Text = activeCount;

            litDeliveriesDone.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM DeliveryAssignments WHERE VolunteerID = @VolunteerID AND Status = 'Delivered'",
                new SqlParameter[] { new SqlParameter("@VolunteerID", volunteerId) }).ToString();
        }

        private void BindActiveTasks()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT a.AssignmentID, a.Status, d.DonationID, d.FoodDescription, d.Quantity, d.PickupAddress,
                         d.City AS PickupCity, d.ContactPerson, d.ContactPhone,
                         d.Latitude, d.Longitude, d.GeoPrecision,
                         ngo.FullName AS NGOName, ngo.OrganizationName AS NGOOrgName,
                         ngo.Address AS NGOAddress, ngo.City AS NGOCity
                  FROM DeliveryAssignments a
                  JOIN FoodDonations d ON d.DonationID = a.DonationID
                  JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  JOIN Users ngo ON ngo.UserID = r.NGOID
                  WHERE a.VolunteerID = @VolunteerID AND a.Status IN ('Assigned', 'PickedUp')
                  ORDER BY a.AssignedAt ASC",
                new SqlParameter[] { new SqlParameter("@VolunteerID", SessionHelper.GetUserID()) });

            rptActiveTasks.DataSource = dt;
            rptActiveTasks.DataBind();
            pnlNoActiveTasks.Visible = dt.Rows.Count == 0;
        }

        private void BindCompleted()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 5 a.DeliveredAt, d.FoodDescription, d.Quantity, ngo.FullName AS NGOName, ngo.OrganizationName AS NGOOrgName
                  FROM DeliveryAssignments a
                  JOIN FoodDonations d ON d.DonationID = a.DonationID
                  JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  JOIN Users ngo ON ngo.UserID = r.NGOID
                  WHERE a.VolunteerID = @VolunteerID AND a.Status = 'Delivered'
                  ORDER BY a.DeliveredAt DESC",
                new SqlParameter[] { new SqlParameter("@VolunteerID", SessionHelper.GetUserID()) });

            rptCompleted.DataSource = dt;
            rptCompleted.DataBind();
            pnlNoCompleted.Visible = dt.Rows.Count == 0;
        }

        protected void rptActiveTasks_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int assignmentId = Convert.ToInt32(e.CommandArgument);
            int volunteerId = SessionHelper.GetUserID();

            if (e.CommandName == "Pickup")
            {
                int rows = DBHelper.ExecuteNonQuery(
                    @"UPDATE DeliveryAssignments SET Status = 'PickedUp', PickedUpAt = GETDATE()
                      WHERE AssignmentID = @AssignmentID AND VolunteerID = @VolunteerID AND Status = 'Assigned'",
                    new SqlParameter[]
                    {
                        new SqlParameter("@AssignmentID", assignmentId),
                        new SqlParameter("@VolunteerID", volunteerId)
                    });

                if (rows > 0)
                {
                    DBHelper.ExecuteNonQuery(
                        @"UPDATE FoodDonations SET Status = 'PickedUp'
                          WHERE DonationID = (SELECT DonationID FROM DeliveryAssignments WHERE AssignmentID = @AssignmentID)",
                        new SqlParameter[] { new SqlParameter("@AssignmentID", assignmentId) });
                    ShowMessage("Pickup confirmed! Head to the drop-off location.", "alert-success");

                    NotifyParties(assignmentId,
                        "Your donation has been picked up",
                        "has been collected by volunteer " + SessionHelper.GetFullName()
                        + " and is on its way.",
                        "Food collected — on its way",
                        "has been picked up by the volunteer and is on its way to you.",
                        NotifyEvent.FoodPickedUp);
                }
                else
                {
                    ShowMessage("Couldn't confirm pickup — this task may have already been updated.", "alert-warning");
                }
            }
            else if (e.CommandName == "Deliver")
            {
                int rows = DBHelper.ExecuteNonQuery(
                    @"UPDATE DeliveryAssignments SET Status = 'Delivered', DeliveredAt = GETDATE()
                      WHERE AssignmentID = @AssignmentID AND VolunteerID = @VolunteerID AND Status = 'PickedUp'",
                    new SqlParameter[]
                    {
                        new SqlParameter("@AssignmentID", assignmentId),
                        new SqlParameter("@VolunteerID", volunteerId)
                    });

                if (rows > 0)
                {
                    DBHelper.ExecuteNonQuery(
                        @"UPDATE FoodDonations SET Status = 'Delivered'
                          WHERE DonationID = (SELECT DonationID FROM DeliveryAssignments WHERE AssignmentID = @AssignmentID)",
                        new SqlParameter[] { new SqlParameter("@AssignmentID", assignmentId) });
                    ShowMessage("Delivery confirmed! Thanks for helping out.", "alert-success");

                    NotifyParties(assignmentId,
                        "Your donation has been delivered",
                        "has been delivered successfully. Thank you for helping reduce food waste.",
                        "A delivery has arrived",
                        "has been delivered to your organisation. Please confirm receipt on your Active Requests page.",
                        NotifyEvent.DeliveryConfirmed);
                }
                else
                {
                    ShowMessage("Couldn't confirm delivery — this task may have already been updated.", "alert-warning");
                }
            }

            BindStats();
            BindActiveTasks();
            BindCompleted();
        }

        /// <summary>
        /// Notify the donor and the receiving NGO about a delivery-status
        /// change made by this volunteer.
        ///
        /// Takes the assignment ID rather than the donation ID because that is
        /// what the postback carries; the donation, donor and NGO are all
        /// resolved from it in one query.
        /// </summary>
        private void NotifyParties(int assignmentId,
                                   string donorSubject, string donorTail,
                                   string ngoSubject, string ngoTail,
                                   string eventKey)
        {
            DataTable d = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.DonorID, d.FoodDescription, r.NGOID
                  FROM DeliveryAssignments a
                  JOIN FoodDonations d ON d.DonationID = a.DonationID
                  LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  WHERE a.AssignmentID = @AssignmentID",
                new SqlParameter[] { new SqlParameter("@AssignmentID", assignmentId) });

            if (d.Rows.Count == 0) return;

            DataRow row = d.Rows[0];
            int donationId = Convert.ToInt32(row["DonationID"]);
            string food = "\"" + Convert.ToString(row["FoodDescription"]) + "\"";

            NotificationService.Notify(Convert.ToInt32(row["DonorID"]),
                donorSubject,
                "Your donation " + food + " " + donorTail,
                NotifyType.Delivery, eventKey,
                "~/Donor/track-donation.aspx?id=" + donationId);

            if (row["NGOID"] != DBNull.Value)
            {
                NotificationService.Notify(Convert.ToInt32(row["NGOID"]),
                    ngoSubject,
                    "The donation " + food + " " + ngoTail,
                    NotifyType.Delivery, eventKey,
                    "~/NGO/ngo-active-requests.aspx");
            }
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers
        protected string NgoLabel(object orgName, object fullName)
        {
            return orgName != DBNull.Value && !string.IsNullOrWhiteSpace(orgName.ToString())
                ? orgName.ToString()
                : fullName.ToString();
        }
    }
}
