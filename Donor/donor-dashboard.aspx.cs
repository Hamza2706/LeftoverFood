using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Donor
{
    public partial class donor_dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Donor");

            if (!IsPostBack)
            {
                if (Request.QueryString["posted"] == "1")
                    ShowMessage("Donation posted! It's now awaiting admin approval.", "alert-success");

                BindStats();
                BindDonations();
                BindImpact();
                BindActivity();
            }
        }

        /// <summary>
        /// The "Your Impact" card. Every figure it used to show was a literal.
        ///
        /// Success rate uses the same denominator as Admin/reports.aspx —
        /// donations that actually entered the pipeline — so a donor's own
        /// cancellations and admin rejections do not count against their
        /// delivery record.
        /// </summary>
        private void BindImpact()
        {
            int donorId = SessionHelper.GetUserID();

            int inPipeline = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE DonorID = @DonorID AND Status NOT IN ('Posted','Rejected','Cancelled')", donorId);

            int delivered = Scalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @DonorID AND Status = 'Delivered'", donorId);

            if (inPipeline == 0)
            {
                litSuccessRate.Text = "—";
                barSuccessRate.Style["width"] = "0%";
                litSuccessNote.Text = "no donations have entered the delivery chain yet";
            }
            else
            {
                int pct = (int)Math.Round(delivered * 100.0 / inPipeline);
                litSuccessRate.Text = pct + "%";
                barSuccessRate.Style["width"] = pct + "%";
                litSuccessNote.Text = Server.HtmlEncode(delivered + " of " + inPipeline + " delivered");
            }

            litImpactMeals.Text = Scalar(
                @"SELECT ISNULL(SUM(Servings), 0) FROM FoodDonations
                  WHERE DonorID = @DonorID AND Status = 'Delivered'", donorId).ToString("N0");

            litImpactInProgress.Text = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE DonorID = @DonorID AND Status IN ('Posted','Approved','Requested','Assigned','PickedUp')",
                donorId).ToString("N0");

            // Live average rather than the cached Users.TrustScore, matching
            // the choice ~/Ratings.aspx and ~/Profile.aspx both make.
            object avg = DBHelper.ExecuteScalar(
                "SELECT AVG(CAST(Stars AS DECIMAL(4,2))) FROM Ratings WHERE RateeID = @DonorID",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) });

            litTrust.Text = avg == null || avg == DBNull.Value
                ? "Not yet rated"
                : Convert.ToDecimal(avg).ToString("0.00") + " / 5.00 average rating";
        }

        /// <summary>
        /// Replaces four hardcoded timeline rows with this donor's own
        /// notifications — already a real per-user event log written by every
        /// phase from 4 onward.
        /// </summary>
        private void BindActivity()
        {
            DataTable dt = NotificationService.GetForUser(SessionHelper.GetUserID(), 5);
            rptActivity.DataSource = dt;
            rptActivity.DataBind();
            pnlNoActivity.Visible = dt.Rows.Count == 0;
        }

        private static int Scalar(string sql, int donorId)
        {
            object value = DBHelper.ExecuteScalar(sql,
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) });
            return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
        }

        private void BindStats()
        {
            int donorId = SessionHelper.GetUserID();

            litTotalDonations.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @DonorID",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) }).ToString();

            litDelivered.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @DonorID AND Status = 'Delivered'",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) }).ToString();

            litPending.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE DonorID = @DonorID AND Status IN ('Posted', 'Approved', 'Requested', 'Assigned', 'PickedUp')",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) }).ToString();

            object mealsResult = DBHelper.ExecuteScalar(
                "SELECT SUM(Servings) FROM FoodDonations WHERE DonorID = @DonorID AND Status = 'Delivered'",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) });
            litMealsProvided.Text = (mealsResult == DBNull.Value) ? "0" : mealsResult.ToString();
        }

        private void BindDonations()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.Status, d.CreatedAt, ngo.FullName AS NGOName
                  FROM FoodDonations d
                  LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID
                  LEFT JOIN Users ngo ON ngo.UserID = r.NGOID
                  WHERE d.DonorID = @DonorID
                  ORDER BY d.CreatedAt DESC",
                new SqlParameter[] { new SqlParameter("@DonorID", SessionHelper.GetUserID()) });

            rptDonations.DataSource = dt;
            rptDonations.DataBind();
            pnlNoDonations.Visible = dt.Rows.Count == 0;
        }

        protected void rptDonations_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Cancel") return;

            int donationId = Convert.ToInt32(e.CommandArgument);

            int rows = DBHelper.ExecuteNonQuery(
                @"UPDATE FoodDonations SET Status = 'Cancelled'
                  WHERE DonationID = @DonationID AND DonorID = @DonorID AND Status = 'Posted'",
                new SqlParameter[]
                {
                    new SqlParameter("@DonationID", donationId),
                    new SqlParameter("@DonorID", SessionHelper.GetUserID())
                });

            ShowMessage(rows > 0 ? "Donation cancelled." : "This donation can no longer be cancelled.", rows > 0 ? "alert-success" : "alert-warning");

            // Phase 6b: only when a cancellation actually happened, so a
            // double-click on an already-cancelled donation cannot inflate the
            // pattern this rule counts.
            if (rows > 0)
                FraudDetectionService.CheckCancellation(SessionHelper.GetUserID());

            BindStats();
            BindDonations();
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers
        protected string StatusBadgeClass(object status)
        {
            switch (status?.ToString())
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

        protected string NgoNameOrDash(object ngoName)
        {
            string name = ngoName?.ToString();
            return string.IsNullOrEmpty(name) ? "—" : name;
        }

        /// <summary>Timeline dot colour, keyed off the notification type.</summary>
        protected string ActivityColour(object type)
        {
            switch (Convert.ToString(type))
            {
                case NotifyType.Approval: return "var(--blue)";
                case NotifyType.Delivery: return "var(--green)";
                case NotifyType.Emergency: return "var(--red)";
                default: return "var(--purple)";
            }
        }
    }
}
