using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.NGO
{
    public partial class ngo_dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "NGO");

            if (!IsPostBack)
            {
                BindStats();
                BindAvailable();
                BindActiveDeliveries();
                BindVolunteers();
                BindMonthlySummary();
            }
        }

        private void BindStats()
        {
            int ngoId = SessionHelper.GetUserID();

            int available = Count(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE Status = 'Approved' AND (PreferredNGOID IS NULL OR PreferredNGOID = @NGOID)", ngoId);

            int acceptedToday = Count(
                @"SELECT COUNT(*) FROM FoodRequests
                  WHERE NGOID = @NGOID AND CAST(RequestedAt AS DATE) = CAST(GETDATE() AS DATE)", ngoId);

            // Was hardcoded 0 in the markup. Donations this NGO claimed that a
            // volunteer is currently carrying.
            int inTransit = Count(
                @"SELECT COUNT(*) FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted'
                    AND d.Status IN ('Assigned', 'PickedUp')", ngoId);

            // Also hardcoded 0. Meals uses Servings — Quantity is free text
            // ("30 Plates") and cannot be summed, the same limit Phases 6b and
            // 6d both hit.
            int meals = Count(
                @"SELECT ISNULL(SUM(d.Servings), 0) FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'Delivered'", ngoId);

            litNewRequests.Text = available.ToString();
            litAvailableBadge.Text = available.ToString();
            litAcceptedToday.Text = acceptedToday.ToString();
            litInTransit.Text = inTransit.ToString("N0");
            litMealsServed.Text = meals.ToString("N0");

            // The badge used to read "Verified NGO" for everyone.
            object verified = DBHelper.ExecuteScalar(
                "SELECT IsVerified FROM Users WHERE UserID = @NGOID",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) });

            litVerifiedBadge.Text = verified != null && verified != DBNull.Value && Convert.ToBoolean(verified)
                ? "<span class=\"badge-status badge-verified\">Verified NGO</span>"
                : "<span class=\"badge-status badge-pending\">Awaiting admin approval</span>";
        }

        /// <summary>
        /// Deliveries this NGO has claimed that are still in flight. Replaces
        /// two hardcoded cards. OUTER APPLY takes the live assignment, since a
        /// donation can hold more than one assignment row.
        /// </summary>
        private void BindActiveDeliveries()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.Status, v.FullName AS VolunteerName
                  FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  OUTER APPLY (SELECT TOP 1 a.VolunteerID FROM DeliveryAssignments a
                                WHERE a.DonationID = d.DonationID
                                ORDER BY a.AssignedAt DESC) asg
                  LEFT JOIN Users v ON v.UserID = asg.VolunteerID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted'
                    AND d.Status IN ('Requested', 'Assigned', 'PickedUp')
                  ORDER BY d.ExpiryTime ASC",
                new SqlParameter[] { new SqlParameter("@NGOID", SessionHelper.GetUserID()) });

            rptActiveDeliveries.DataSource = dt;
            rptActiveDeliveries.DataBind();
            pnlNoActive.Visible = dt.Rows.Count == 0;
        }

        /// <summary>
        /// Volunteers who have actually carried this NGO's deliveries. The
        /// mockup's "Our Volunteers" implied an NGO-owned roster, which does not
        /// exist — admins assign volunteers centrally (Phase 3).
        /// </summary>
        private void BindVolunteers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT u.UserID, u.FullName,
                         SUM(CASE WHEN a.Status = 'Delivered' THEN 1 ELSE 0 END) AS Completed,
                         SUM(CASE WHEN a.Status IN ('Assigned','PickedUp') THEN 1 ELSE 0 END) AS ActiveNow
                  FROM DeliveryAssignments a
                  JOIN FoodRequests r ON r.DonationID = a.DonationID AND r.Status = 'Accepted'
                  JOIN Users u ON u.UserID = a.VolunteerID
                  WHERE r.NGOID = @NGOID
                  GROUP BY u.UserID, u.FullName
                  ORDER BY ActiveNow DESC, Completed DESC",
                new SqlParameter[] { new SqlParameter("@NGOID", SessionHelper.GetUserID()) });

            rptVolunteers.DataSource = dt;
            rptVolunteers.DataBind();
            pnlNoVolunteers.Visible = dt.Rows.Count == 0;
        }

        /// <summary>
        /// Current calendar month, scoped to this NGO. Replaces a card headed
        /// "April 2025" with 248 / 5,830 / 96% hardcoded.
        /// </summary>
        private void BindMonthlySummary()
        {
            int ngoId = SessionHelper.GetUserID();
            DateTime monthStart = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);

            SqlParameter[] Params()
            {
                return new SqlParameter[]
                {
                    new SqlParameter("@NGOID", ngoId),
                    new SqlParameter("@From", monthStart),
                    new SqlParameter("@To", monthStart.AddMonths(1))
                };
            }

            litMonthLabel.Text = monthStart.ToString("MMMM yyyy");

            int accepted = Scalar(
                @"SELECT COUNT(*) FROM FoodRequests
                  WHERE NGOID = @NGOID AND Status = 'Accepted'
                    AND RequestedAt >= @From AND RequestedAt < @To", Params());

            int delivered = Scalar(
                @"SELECT COUNT(*) FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'Delivered'
                    AND r.RequestedAt >= @From AND r.RequestedAt < @To", Params());

            int meals = Scalar(
                @"SELECT ISNULL(SUM(d.Servings), 0) FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'Delivered'
                    AND r.RequestedAt >= @From AND r.RequestedAt < @To", Params());

            litMonthAccepted.Text = accepted.ToString("N0");
            litMonthMeals.Text = meals.ToString("N0");

            // "—" rather than 0%, so "nothing accepted yet this month" stays
            // distinct from "accepted plenty and delivered none".
            litMonthFulfilment.Text = accepted == 0
                ? "—"
                : (int)Math.Round(delivered * 100.0 / accepted) + "%";
        }

        private static int Count(string sql, int ngoId)
        {
            return Scalar(sql, new SqlParameter[] { new SqlParameter("@NGOID", ngoId) });
        }

        private static int Scalar(string sql, SqlParameter[] parameters)
        {
            object value = DBHelper.ExecuteScalar(sql, parameters);
            return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        protected string Initials(object fullName)
        {
            return SessionHelper.Initials(Convert.ToString(fullName));
        }

        protected string VolunteerLabel(object name)
        {
            string text = Convert.ToString(name);
            return string.IsNullOrWhiteSpace(text) ? "not assigned yet" : text;
        }

        /// <summary>
        /// The three in-flight states, mapped from FoodDonations.Status — the
        /// authoritative one per Phase 3. The bar is a step indicator, not a
        /// time estimate: nothing here computes travel time.
        /// </summary>
        protected string DeliveryPercent(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Requested": return "20";
                case "Assigned": return "50";
                case "PickedUp": return "80";
                default: return "0";
            }
        }

        protected string DeliveryStep(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Requested": return "Step 1 of 3 — waiting for a volunteer to be assigned";
                case "Assigned": return "Step 2 of 3 — volunteer assigned, collection pending";
                case "PickedUp": return "Step 3 of 3 — collected, on its way to you";
                default: return "";
            }
        }

        protected string DeliveryLabel(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Requested": return "Awaiting volunteer";
                case "Assigned": return "Pickup due";
                case "PickedUp": return "In transit";
                default: return Convert.ToString(status);
            }
        }

        protected string DeliveryBadge(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Requested": return "badge-pending";
                case "Assigned": return "badge-pending";
                case "PickedUp": return "badge-accepted";
                default: return "badge-active";
            }
        }

        private void BindAvailable()
        {
            int ngoId = SessionHelper.GetUserID();

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.City, d.AvailableFrom, d.AvailableUntil, u.FullName AS DonorName
                  FROM FoodDonations d
                  JOIN Users u ON u.UserID = d.DonorID
                  WHERE d.Status = 'Approved' AND (d.PreferredNGOID IS NULL OR d.PreferredNGOID = @NGOID)
                  -- Phase 6a: admin-flagged priority donations sort first here
                  -- too, so an emergency flag is visible to the NGOs who act on
                  -- it, not just to the admin who set it.
                  ORDER BY d.IsPriority DESC, d.ExpiryTime ASC",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) });

            rptAvailable.DataSource = dt;
            rptAvailable.DataBind();
            pnlNoAvailable.Visible = dt.Rows.Count == 0;
        }

        protected void rptAvailable_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Accept") return;

            int donationId = Convert.ToInt32(e.CommandArgument);
            int ngoId = SessionHelper.GetUserID();

            // Race-safe claim: only succeeds if still Approved (first NGO to accept wins)
            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE FoodDonations SET Status = 'Requested' WHERE DonationID = @DonationID AND Status = 'Approved'",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (rows > 0)
            {
                DBHelper.ExecuteNonQuery(
                    "INSERT INTO FoodRequests (DonationID, NGOID, Status) VALUES (@DonationID, @NGOID, 'Accepted')",
                    new SqlParameter[]
                    {
                        new SqlParameter("@DonationID", donationId),
                        new SqlParameter("@NGOID", ngoId)
                    });
                ShowMessage("Donation accepted. A volunteer will be assigned for pickup.", "alert-success");

                // Inside the rows > 0 branch, so the NGO that lost the race
                // never triggers notifications for a donation it didn't get.
                DataTable d = DBHelper.ExecuteQuery(
                    "SELECT DonorID, FoodDescription FROM FoodDonations WHERE DonationID = @DonationID",
                    new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

                if (d.Rows.Count > 0)
                {
                    string food = Convert.ToString(d.Rows[0]["FoodDescription"]);
                    string ngoName = SessionHelper.GetFullName();

                    NotificationService.Notify(
                        Convert.ToInt32(d.Rows[0]["DonorID"]),
                        "An NGO has accepted your donation",
                        ngoName + " has accepted your donation \"" + food
                        + "\". A volunteer will be assigned to collect it.",
                        NotifyType.Approval, NotifyEvent.NgoAccepted,
                        "~/Donor/track-donation.aspx?id=" + donationId);

                    // Admins need to know a volunteer assignment is now due.
                    NotificationService.NotifyRole("Admin",
                        "Donation needs a volunteer",
                        ngoName + " accepted \"" + food + "\". It now needs a volunteer assigned for pickup.",
                        NotifyType.Delivery, NotifyEvent.NgoAccepted,
                        "~/Admin/volunteer-assign.aspx");
                }
            }
            else
            {
                ShowMessage("This donation was just claimed by another NGO.", "alert-warning");
            }

            BindStats();
            BindAvailable();
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }
    }
}
