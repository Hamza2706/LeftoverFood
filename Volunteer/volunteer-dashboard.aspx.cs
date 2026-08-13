using System;
using System.Data;
using System.Data.SqlClient;
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
            }
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
                         ngo.FullName AS NGOName, ngo.OrganizationName AS NGOOrgName
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
