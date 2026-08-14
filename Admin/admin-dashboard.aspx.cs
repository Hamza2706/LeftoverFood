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

                // Account-status changes pass a null event key: they are
                // mandatory and cannot be switched off in preferences.
                NotificationService.Notify(userId,
                    "Your FoodBridge account has been approved",
                    "Good news — an administrator has verified your account. You can now sign in and start using FoodBridge.",
                    NotifyType.System, null, "~/Login.aspx");
            }
            else if (e.CommandName == "Reject")
            {
                // Reject deletes the row (Phase 1 design decision), so the
                // recipient must be looked up *before* the delete — and there
                // is no user left to own an in-app notification afterwards, so
                // this is the one place that emails directly instead of via
                // Notify().
                DataTable who = DBHelper.ExecuteQuery(
                    "SELECT Email, FullName FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });

                DBHelper.ExecuteNonQuery(
                    "DELETE FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("Registration rejected and removed.", "alert-danger");

                if (who.Rows.Count > 0)
                {
                    NotificationService.SendEmail(
                        Convert.ToString(who.Rows[0]["Email"]),
                        "Your FoodBridge registration was not approved",
                        "<p>Dear " + Server.HtmlEncode(Convert.ToString(who.Rows[0]["FullName"])) + ",</p>"
                        + "<p>Thank you for your interest in FoodBridge. After review, your registration "
                        + "was not approved and the request has been closed. You are welcome to register "
                        + "again with complete and accurate details.</p>");
                }
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

                // The user row survives a ban, so this can be a normal
                // notification — they just cannot sign in to read the in-app
                // copy until reinstated, which is what the email is for.
                NotificationService.Notify(userId,
                    "Your FoodBridge account has been suspended",
                    "An administrator has suspended your account. You will not be able to sign in until it is reinstated. "
                    + "Please contact the FoodBridge team if you believe this is a mistake.",
                    NotifyType.System, null);
            }
            else if (e.CommandName == "Unban")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsActive = 1 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User reinstated.", "alert-success");

                NotificationService.Notify(userId,
                    "Your FoodBridge account has been reinstated",
                    "Your account has been reinstated by an administrator. You can sign in again.",
                    NotifyType.System, null, "~/Login.aspx");
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
