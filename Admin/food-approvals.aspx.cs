using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    public partial class food_approvals : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            if (!IsPostBack)
            {
                BindStats();
                BindPending();
                BindProcessed();
            }
        }

        private void BindStats()
        {
            litAwaitingReview.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE Status = 'Posted'").ToString();

            litExpiringSoon.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE Status = 'Posted' AND ExpiryTime <= DATEADD(HOUR, 2, GETDATE())").ToString();

            litApprovedMonth.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE Status = 'Approved' AND MONTH(ApprovedAt) = MONTH(GETDATE()) AND YEAR(ApprovedAt) = YEAR(GETDATE())").ToString();

            litRejectedMonth.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE Status = 'Rejected' AND MONTH(ApprovedAt) = MONTH(GETDATE()) AND YEAR(ApprovedAt) = YEAR(GETDATE())").ToString();
        }

        private void BindPending()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Category, d.DonorTypeAtPost AS DonorType, d.Quantity, d.Servings,
                         d.PickupAddress, d.City, d.DietaryInfo, d.AdditionalNotes, d.ExpiryTime, d.CreatedAt,
                         u.FullName AS DonorName
                  FROM FoodDonations d
                  JOIN Users u ON u.UserID = d.DonorID
                  WHERE d.Status = 'Posted'
                  ORDER BY d.ExpiryTime ASC");

            rptPending.DataSource = dt;
            rptPending.DataBind();
            pnlNoPending.Visible = dt.Rows.Count == 0;
        }

        private void BindProcessed()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 10 d.DonationID, d.FoodDescription, d.Quantity, d.Status, d.ApprovedAt, u.FullName AS DonorName
                  FROM FoodDonations d
                  JOIN Users u ON u.UserID = d.DonorID
                  WHERE d.Status IN ('Approved', 'Rejected') AND CAST(d.ApprovedAt AS DATE) = CAST(GETDATE() AS DATE)
                  ORDER BY d.ApprovedAt DESC");

            rptProcessed.DataSource = dt;
            rptProcessed.DataBind();
        }

        protected void rptPending_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int donationId = Convert.ToInt32(e.CommandArgument);

            if (e.CommandName == "Approve")
            {
                int rows = DBHelper.ExecuteNonQuery(
                    @"UPDATE FoodDonations SET Status = 'Approved', ApprovedBy = @AdminID, ApprovedAt = GETDATE()
                      WHERE DonationID = @DonationID AND Status = 'Posted'",
                    new SqlParameter[]
                    {
                        new SqlParameter("@AdminID", SessionHelper.GetUserID()),
                        new SqlParameter("@DonationID", donationId)
                    });
                ShowMessage(rows > 0 ? "Donation approved. NGOs can now request it." : "This donation was already processed.", rows > 0 ? "alert-success" : "alert-warning");

                // Only notify when the UPDATE actually changed something —
                // rows == 0 means another admin already processed it, and
                // notifying then would send a duplicate.
                if (rows > 0)
                    NotifyDonor(donationId,
                        "Your donation has been approved",
                        "has been approved by an administrator and is now visible to NGOs. "
                        + "You'll be notified when an NGO accepts it.");
            }
            else if (e.CommandName == "Reject")
            {
                int rows = DBHelper.ExecuteNonQuery(
                    @"UPDATE FoodDonations SET Status = 'Rejected', ApprovedBy = @AdminID, ApprovedAt = GETDATE()
                      WHERE DonationID = @DonationID AND Status = 'Posted'",
                    new SqlParameter[]
                    {
                        new SqlParameter("@AdminID", SessionHelper.GetUserID()),
                        new SqlParameter("@DonationID", donationId)
                    });
                ShowMessage(rows > 0 ? "Donation rejected." : "This donation was already processed.", rows > 0 ? "alert-danger" : "alert-warning");

                if (rows > 0)
                    NotifyDonor(donationId,
                        "Your donation was not approved",
                        "was reviewed by an administrator and could not be approved. "
                        + "Please check the food details and expiry time, and feel free to post again.");
            }

            BindStats();
            BindPending();
            BindProcessed();
        }

        /// <summary>
        /// Notify the donor who owns a donation. Looks the donor up rather than
        /// trusting anything from the postback, and builds the message around
        /// the food description so the donor knows which donation it refers to.
        /// </summary>
        private void NotifyDonor(int donationId, string subject, string bodyTail)
        {
            DataTable d = DBHelper.ExecuteQuery(
                "SELECT DonorID, FoodDescription FROM FoodDonations WHERE DonationID = @DonationID",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (d.Rows.Count == 0) return;

            NotificationService.Notify(
                Convert.ToInt32(d.Rows[0]["DonorID"]),
                subject,
                "Your donation \"" + Convert.ToString(d.Rows[0]["FoodDescription"]) + "\" " + bodyTail,
                NotifyType.Approval,
                NotifyEvent.DonationApproved,
                "~/Donor/track-donation.aspx?id=" + donationId);
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers
        protected string UrgencyBucket(object expiryTime)
        {
            TimeSpan remaining = Convert.ToDateTime(expiryTime) - DateTime.Now;
            if (remaining.TotalHours <= 2) return "urgent";
            if (remaining.TotalHours <= 5) return "warning";
            return "normal";
        }

        protected string UrgencyExpiryClass(object expiryTime)
        {
            switch (UrgencyBucket(expiryTime))
            {
                case "urgent": return "expiry-red";
                case "warning": return "expiry-amber";
                default: return "expiry-green";
            }
        }

        protected string TimeUntil(object expiryTime)
        {
            TimeSpan remaining = Convert.ToDateTime(expiryTime) - DateTime.Now;
            if (remaining.TotalMinutes <= 0) return "Expired";
            if (remaining.TotalHours < 1) return $"Expires in {(int)remaining.TotalMinutes} mins";
            return $"Expires in {(int)remaining.TotalHours}h {remaining.Minutes}m";
        }

        protected string TimeAgo(object createdAt)
        {
            TimeSpan elapsed = DateTime.Now - Convert.ToDateTime(createdAt);
            if (elapsed.TotalMinutes < 1) return "just now";
            if (elapsed.TotalHours < 1) return $"{(int)elapsed.TotalMinutes}m ago";
            if (elapsed.TotalDays < 1) return $"{(int)elapsed.TotalHours}h ago";
            return $"{(int)elapsed.TotalDays}d ago";
        }
    }
}
