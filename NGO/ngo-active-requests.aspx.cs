using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.NGO
{
    public partial class ngo_active_requests : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "NGO");

            if (!IsPostBack)
            {
                BindStats();
                BindRequests();
                BindCompleted();
            }
        }

        private void BindStats()
        {
            int ngoId = SessionHelper.GetUserID();

            litAwaitingCount.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodRequests r JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status IN ('Requested', 'Assigned')",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) }).ToString();

            litTransitCount.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodRequests r JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'PickedUp'",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) }).ToString();

            litArrivedCount.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodRequests r JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'Delivered' AND r.ActualQuantityReceived IS NULL",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) }).ToString();

            object meals = DBHelper.ExecuteScalar(
                @"SELECT SUM(d.Servings) FROM FoodRequests r JOIN FoodDonations d ON d.DonationID = r.DonationID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted'
                        AND (d.Status IN ('Requested', 'Assigned', 'PickedUp') OR (d.Status = 'Delivered' AND r.ActualQuantityReceived IS NULL))",
                new SqlParameter[] { new SqlParameter("@NGOID", ngoId) });
            litMealsExpected.Text = (meals == DBNull.Value) ? "0" : meals.ToString();
        }

        private void BindRequests()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.PickupAddress, d.City, d.Status AS DonationStatus,
                         r.RequestID, r.RequestedAt, r.ActualQuantityReceived,
                         donor.FullName AS DonorName,
                         vol.FullName AS VolunteerName,
                         a.PickedUpAt, a.DeliveredAt
                  FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  JOIN Users donor ON donor.UserID = d.DonorID
                  LEFT JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                  LEFT JOIN Users vol ON vol.UserID = a.VolunteerID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted'
                        AND (d.Status IN ('Requested', 'Assigned', 'PickedUp') OR (d.Status = 'Delivered' AND r.ActualQuantityReceived IS NULL))
                  ORDER BY d.CreatedAt ASC",
                new SqlParameter[] { new SqlParameter("@NGOID", SessionHelper.GetUserID()) });

            rptRequests.DataSource = dt;
            rptRequests.DataBind();
            pnlNoRequests.Visible = dt.Rows.Count == 0;
        }

        private void BindCompleted()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 10 d.DonationID, d.FoodDescription, r.ActualQuantityReceived,
                         donor.FullName AS DonorName, vol.FullName AS VolunteerName, a.DeliveredAt
                  FROM FoodRequests r
                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                  JOIN Users donor ON donor.UserID = d.DonorID
                  LEFT JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                  LEFT JOIN Users vol ON vol.UserID = a.VolunteerID
                  WHERE r.NGOID = @NGOID AND r.Status = 'Accepted' AND d.Status = 'Delivered' AND r.ActualQuantityReceived IS NOT NULL
                  ORDER BY a.DeliveredAt DESC",
                new SqlParameter[] { new SqlParameter("@NGOID", SessionHelper.GetUserID()) });

            rptCompleted.DataSource = dt;
            rptCompleted.DataBind();
            pnlNoCompleted.Visible = dt.Rows.Count == 0;
        }

        protected void rptRequests_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "ConfirmReceipt") return;

            int requestId = Convert.ToInt32(e.CommandArgument);
            TextBox txtQty = (TextBox)e.Item.FindControl("txtQtyReceived");
            DropDownList ddlCondition = (DropDownList)e.Item.FindControl("ddlCondition");
            TextBox txtNotes = (TextBox)e.Item.FindControl("txtReceiveNotes");

            if (string.IsNullOrWhiteSpace(txtQty.Text))
            {
                ShowMessage("Please enter the actual quantity received.", "alert-danger");
            }
            else
            {
                int rows = DBHelper.ExecuteNonQuery(
                    @"UPDATE FoodRequests SET ActualQuantityReceived = @Qty, FoodCondition = @Condition, Notes = @Notes
                      WHERE RequestID = @RequestID AND NGOID = @NGOID AND ActualQuantityReceived IS NULL",
                    new SqlParameter[]
                    {
                        new SqlParameter("@Qty", txtQty.Text.Trim()),
                        new SqlParameter("@Condition", ddlCondition.SelectedValue),
                        new SqlParameter("@Notes", string.IsNullOrWhiteSpace(txtNotes.Text) ? (object)DBNull.Value : txtNotes.Text.Trim()),
                        new SqlParameter("@RequestID", requestId),
                        new SqlParameter("@NGOID", SessionHelper.GetUserID())
                    });

                ShowMessage(rows > 0 ? "Receipt confirmed. Thanks for closing the loop!" : "This request was already confirmed.", rows > 0 ? "alert-success" : "alert-warning");
            }

            BindStats();
            BindRequests();
            BindCompleted();
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers
        protected string Bucket(object donationStatus)
        {
            switch (donationStatus?.ToString())
            {
                case "Requested":
                case "Assigned": return "awaiting";
                case "PickedUp": return "transit";
                case "Delivered": return "arrived";
                default: return "";
            }
        }

        protected string BucketLabel(object donationStatus)
        {
            switch (Bucket(donationStatus))
            {
                case "awaiting": return "⏳ Awaiting Volunteer Pickup";
                case "transit": return "🚴 In Transit";
                case "arrived": return "✅ Arrived — Confirm Receipt";
                default: return "";
            }
        }

        protected string BucketBadgeClass(object donationStatus)
        {
            switch (Bucket(donationStatus))
            {
                case "awaiting": return "badge-pending";
                case "transit": return "badge-accepted";
                case "arrived": return "badge-delivered";
                default: return "";
            }
        }

        protected string BucketHeaderStyle(object donationStatus)
        {
            switch (Bucket(donationStatus))
            {
                case "awaiting": return "background:var(--amber-light)";
                case "transit": return "background:#e0f2fe";
                case "arrived": return "background:#e8f5ee";
                default: return "";
            }
        }

        protected string BucketTimeText(object donationStatus, object requestedAt, object pickedUpAt, object deliveredAt)
        {
            switch (Bucket(donationStatus))
            {
                case "awaiting": return "Accepted " + TimeAgo(requestedAt);
                case "transit": return pickedUpAt == DBNull.Value ? "" : "Picked up " + TimeAgo(pickedUpAt);
                case "arrived": return deliveredAt == DBNull.Value ? "" : "Arrived " + TimeAgo(deliveredAt);
                default: return "";
            }
        }

        protected string MiniStepClass(object donationStatus, object actualQtyReceived, string step)
        {
            string status = donationStatus?.ToString();
            bool confirmed = actualQtyReceived != DBNull.Value;

            if (step == "pickedup")
                return (status == "PickedUp" || status == "Delivered") ? "done" : "active";

            if (step == "arrived")
            {
                if (status == "Delivered") return confirmed ? "done" : "active";
                return "pending";
            }

            return "pending";
        }

        protected string VolunteerNameOrDash(object volunteerName)
        {
            string name = volunteerName?.ToString();
            return string.IsNullOrEmpty(name) ? "not yet assigned" : name;
        }

        protected string TimeAgo(object timestamp)
        {
            TimeSpan elapsed = DateTime.Now - Convert.ToDateTime(timestamp);
            if (elapsed.TotalMinutes < 1) return "just now";
            if (elapsed.TotalHours < 1) return $"{(int)elapsed.TotalMinutes}m ago";
            if (elapsed.TotalDays < 1) return $"{(int)elapsed.TotalHours}h ago";
            return $"{(int)elapsed.TotalDays}d ago";
        }
    }
}
