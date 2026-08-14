using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    public partial class volunteer_assign : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            if (!IsPostBack)
            {
                BindStats();
                BindNeedsAssignment();
                BindActiveDeliveries();
            }
        }

        private void BindStats()
        {
            litVerifiedVolunteers.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE Role = 'Volunteer' AND IsVerified = 1 AND IsActive = 1").ToString();

            litOnDelivery.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(DISTINCT VolunteerID) FROM DeliveryAssignments WHERE Status IN ('Assigned', 'PickedUp', 'InTransit')").ToString();

            litNeedAssignment.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE Status = 'Requested'").ToString();
        }

        private void BindNeedsAssignment()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID, d.FoodDescription, d.Quantity, d.PickupAddress, d.City, d.ExpiryTime,
                         d.ContactPerson, d.ContactPhone,
                         donor.FullName AS DonorName,
                         ngo.FullName AS NGOName, ngo.OrganizationName AS NGOOrgName
                  FROM FoodDonations d
                  JOIN Users donor ON donor.UserID = d.DonorID
                  JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  JOIN Users ngo ON ngo.UserID = r.NGOID
                  WHERE d.Status = 'Requested'
                  ORDER BY d.ExpiryTime ASC");

            rptNeedsAssignment.DataSource = dt;
            rptNeedsAssignment.DataBind();
            pnlNoNeedsAssignment.Visible = dt.Rows.Count == 0;
        }

        private void BindActiveDeliveries()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT a.AssignmentID, a.Status, a.AssignedAt, d.DonationID, d.Quantity,
                         donor.FullName AS DonorName, vol.FullName AS VolunteerName
                  FROM DeliveryAssignments a
                  JOIN FoodDonations d ON d.DonationID = a.DonationID
                  JOIN Users donor ON donor.UserID = d.DonorID
                  JOIN Users vol ON vol.UserID = a.VolunteerID
                  WHERE a.Status IN ('Assigned', 'PickedUp', 'InTransit')
                  ORDER BY a.AssignedAt DESC");

            rptActiveDeliveries.DataSource = dt;
            rptActiveDeliveries.DataBind();
            pnlNoActiveDeliveries.Visible = dt.Rows.Count == 0;
        }

        protected void rptNeedsAssignment_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            DropDownList ddl = (DropDownList)e.Item.FindControl("ddlVolunteer");

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT u.UserID, u.FullName,
                         (SELECT COUNT(*) FROM DeliveryAssignments a WHERE a.VolunteerID = u.UserID AND a.Status IN ('Assigned','PickedUp','InTransit')) AS ActiveCount
                  FROM Users u
                  WHERE u.Role = 'Volunteer' AND u.IsVerified = 1 AND u.IsActive = 1
                  ORDER BY ActiveCount ASC, u.FullName ASC");

            foreach (DataRow row in dt.Rows)
            {
                int activeCount = Convert.ToInt32(row["ActiveCount"]);
                string label = row["FullName"] + (activeCount > 0 ? $" ({activeCount} active)" : " (free)");
                ddl.Items.Add(new ListItem(label, row["UserID"].ToString()));
            }

            if (ddl.Items.Count == 0)
                ddl.Items.Add(new ListItem("No verified volunteers available", ""));
        }

        protected void rptNeedsAssignment_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Assign") return;

            int donationId = Convert.ToInt32(e.CommandArgument);
            DropDownList ddl = (DropDownList)e.Item.FindControl("ddlVolunteer");
            TextBox txtNote = (TextBox)e.Item.FindControl("txtNote");

            if (string.IsNullOrEmpty(ddl.SelectedValue))
            {
                ShowMessage("No verified volunteer available to assign.", "alert-warning");
            }
            else
            {
                int volunteerId = Convert.ToInt32(ddl.SelectedValue);

                // Race-safe claim: only succeeds if still Requested (no other admin/tab beat us to it)
                int rows = DBHelper.ExecuteNonQuery(
                    "UPDATE FoodDonations SET Status = 'Assigned' WHERE DonationID = @DonationID AND Status = 'Requested'",
                    new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

                if (rows > 0)
                {
                    DBHelper.ExecuteNonQuery(
                        @"INSERT INTO DeliveryAssignments (DonationID, VolunteerID, AssignedBy, NoteForVolunteer, Status)
                          VALUES (@DonationID, @VolunteerID, @AssignedBy, @Note, 'Assigned')",
                        new SqlParameter[]
                        {
                            new SqlParameter("@DonationID", donationId),
                            new SqlParameter("@VolunteerID", volunteerId),
                            new SqlParameter("@AssignedBy", SessionHelper.GetUserID()),
                            new SqlParameter("@Note", string.IsNullOrWhiteSpace(txtNote.Text) ? (object)DBNull.Value : txtNote.Text.Trim())
                        });
                    ShowMessage("Volunteer assigned. They'll see this pickup on their dashboard.", "alert-success");

                    NotifyAssignment(donationId, volunteerId);
                }
                else
                {
                    ShowMessage("This donation was already assigned.", "alert-warning");
                }
            }

            BindStats();
            BindNeedsAssignment();
            BindActiveDeliveries();
        }

        /// <summary>
        /// Tell all three parties an assignment just happened: the volunteer
        /// who has to act, and the donor and NGO who are waiting on it.
        ///
        /// One query pulls everyone involved — the donor from FoodDonations and
        /// the NGO from the accepted FoodRequests row — so this costs a single
        /// round trip rather than three.
        /// </summary>
        private void NotifyAssignment(int donationId, int volunteerId)
        {
            DataTable d = DBHelper.ExecuteQuery(
                @"SELECT d.DonorID, d.FoodDescription, d.PickupAddress, d.City, r.NGOID
                  FROM FoodDonations d
                  LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                  WHERE d.DonationID = @DonationID",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (d.Rows.Count == 0) return;

            DataRow row = d.Rows[0];
            string food = Convert.ToString(row["FoodDescription"]);
            string pickup = Convert.ToString(row["PickupAddress"]) + ", " + Convert.ToString(row["City"]);

            // The volunteer — the only one with something to do next.
            NotificationService.Notify(volunteerId,
                "You've been assigned a pickup",
                "You have been assigned to collect \"" + food + "\" from " + pickup
                + ". Open your dashboard to confirm the pickup once you have it.",
                NotifyType.Delivery, NotifyEvent.VolunteerAssigned,
                "~/Volunteer/volunteer-dashboard.aspx");

            NotificationService.Notify(Convert.ToInt32(row["DonorID"]),
                "A volunteer is on the way",
                "A volunteer has been assigned to collect your donation \"" + food + "\".",
                NotifyType.Delivery, NotifyEvent.VolunteerAssigned,
                "~/Donor/track-donation.aspx?id=" + donationId);

            if (row["NGOID"] != DBNull.Value)
            {
                NotificationService.Notify(Convert.ToInt32(row["NGOID"]),
                    "A volunteer has been assigned",
                    "A volunteer has been assigned to collect \"" + food + "\" for your organisation.",
                    NotifyType.Delivery, NotifyEvent.VolunteerAssigned,
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
        protected string UrgencyBadge(object expiryTime)
        {
            TimeSpan remaining = Convert.ToDateTime(expiryTime) - DateTime.Now;
            return remaining.TotalHours <= 2 ? "🔴 URGENT" : "🟡 NORMAL";
        }

        protected string TimeUntil(object expiryTime)
        {
            TimeSpan remaining = Convert.ToDateTime(expiryTime) - DateTime.Now;
            if (remaining.TotalMinutes <= 0) return "Expired";
            if (remaining.TotalHours < 1) return $"Expires in {(int)remaining.TotalMinutes} mins";
            return $"Expires in {(int)remaining.TotalHours}h {remaining.Minutes}m";
        }

        protected string NgoLabel(object orgName, object fullName)
        {
            return orgName != DBNull.Value && !string.IsNullOrWhiteSpace(orgName.ToString())
                ? orgName.ToString()
                : fullName.ToString();
        }

        protected string StatusBadgeClass(object status)
        {
            switch (status?.ToString())
            {
                case "Assigned": return "badge-pending";
                case "PickedUp":
                case "InTransit": return "badge-accepted";
                default: return "";
            }
        }

        protected string StatusLabel(object status)
        {
            switch (status?.ToString())
            {
                case "Assigned": return "Awaiting Pickup";
                case "PickedUp": return "Picked Up";
                case "InTransit": return "In Transit";
                default: return status?.ToString();
            }
        }
    }
}
