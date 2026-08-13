using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
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
            }
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
    }
}
