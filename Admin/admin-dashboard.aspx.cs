using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    public partial class admin_dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            if (!IsPostBack)
            {
                BindStats();
                BindPendingUsers();
                BindAllUsers();
            }
        }

        private void BindStats()
        {
            litTotalUsers.Text = DBHelper.ExecuteScalar("SELECT COUNT(*) FROM Users").ToString();
            litTotalDonations.Text = DBHelper.ExecuteScalar("SELECT COUNT(*) FROM FoodDonations").ToString();
            litTotalNGOs.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE Role = 'NGO' AND IsVerified = 1").ToString();
            litPendingApprovals.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE IsVerified = 0").ToString();
        }

        private void BindPendingUsers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, Email, Role, City, CreatedAt FROM Users WHERE IsVerified = 0 ORDER BY CreatedAt");

            rptPending.DataSource = dt;
            rptPending.DataBind();

            pnlNoPending.Visible = dt.Rows.Count == 0;
            litPendingBadge.Text = dt.Rows.Count.ToString();
        }

        private void BindAllUsers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, Email, Role, City, IsVerified, IsActive, CreatedAt FROM Users ORDER BY CreatedAt DESC");

            rptUsers.DataSource = dt;
            rptUsers.DataBind();
        }

        protected void rptPending_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int userId = Convert.ToInt32(e.CommandArgument);

            if (e.CommandName == "Approve")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsVerified = 1 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User approved. They can now log in.", "alert-success");
            }
            else if (e.CommandName == "Reject")
            {
                DBHelper.ExecuteNonQuery(
                    "DELETE FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("Registration rejected and removed.", "alert-danger");
            }

            BindStats();
            BindPendingUsers();
            BindAllUsers();
        }

        protected void rptUsers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int userId = Convert.ToInt32(e.CommandArgument);

            if (userId == SessionHelper.GetUserID())
            {
                ShowMessage("You cannot change the status of your own account.", "alert-danger");
                return;
            }

            if (e.CommandName == "Ban")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsActive = 0 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User suspended.", "alert-success");
            }
            else if (e.CommandName == "Unban")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsActive = 1 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User reinstated.", "alert-success");
            }

            BindAllUsers();
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers, referenced from admin-dashboard.aspx via <%# %> bindings
        protected string Initials(object fullName)
        {
            return SessionHelper.Initials(fullName?.ToString());
        }

        protected string StatusBadgeClass(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "badge-pending";
            if (!Convert.ToBoolean(isActive)) return "badge-rejected";
            return "badge-active";
        }

        protected string StatusBadgeText(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "Pending";
            if (!Convert.ToBoolean(isActive)) return "Suspended";
            return "Active";
        }

        protected string RoleBadgeClass(object role)
        {
            switch (role?.ToString())
            {
                case "Donor": return "badge-role-donor";
                case "NGO": return "badge-role-ngo";
                case "Volunteer": return "badge-role-vol";
                case "Admin": return "badge-role-admin";
                default: return "";
            }
        }
    }
}
