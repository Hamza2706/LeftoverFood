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
