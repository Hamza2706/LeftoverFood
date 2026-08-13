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
            }
        }

        private void BindStats()
        {
            int ngoId = SessionHelper.GetUserID();

            int available = Convert.ToInt32(DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodDonations
                  WHERE Status = 'Approved' AND (PreferredNGOID IS NULL OR PreferredNGOID = @NGOID)",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) }));

            int acceptedToday = Convert.ToInt32(DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodRequests
                  WHERE NGOID = @NGOID AND CAST(RequestedAt AS DATE) = CAST(GETDATE() AS DATE)",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) }));

            litNewRequests.Text = available.ToString();
            litAvailableBadge.Text = available.ToString();
            litAcceptedToday.Text = acceptedToday.ToString();
        }

        private void BindAvailable()
        {
            int ngoId = SessionHelper.GetUserID();

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.City, d.AvailableFrom, d.AvailableUntil, u.FullName AS DonorName
                  FROM FoodDonations d
                  JOIN Users u ON u.UserID = d.DonorID
                  WHERE d.Status = 'Approved' AND (d.PreferredNGOID IS NULL OR d.PreferredNGOID = @NGOID)
                  ORDER BY d.ExpiryTime ASC",
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
