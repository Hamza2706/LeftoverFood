using LeftoverFoodSystem;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace LeftoverFood.TestRegLogin
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // If user is already logged in, redirect to their dashboard
            if (Session["UserID"] != null)
                RedirectToDashboard(Session["Role"].ToString());
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            string email = txtEmail.Text.Trim().ToLower();
            string password = txtPassword.Text;

            // 1. Fetch user by email
            string query = @"
                SELECT UserID, FullName, Role, PasswordHash, IsVerified
                FROM Users
                WHERE Email = @Email";

            SqlParameter[] parameters = {
                new SqlParameter("@Email", email)
            };

            try
            {
                DataTable dt = DBHelper.ExecuteQuery(query, parameters);

                if (dt.Rows.Count == 0)
                {
                    ShowMessage("No account found with this email.", "alert alert-danger");
                    return;
                }

                DataRow user = dt.Rows[0];

                // 2. Verify password
                string storedHash = user["PasswordHash"].ToString();
                if (!PasswordHelper.VerifyPassword(password, storedHash))
                {
                    ShowMessage("Incorrect password. Please try again.", "alert alert-danger");
                    return;
                }

                // 3. Check if account is approved by Admin
                bool isVerified = Convert.ToBoolean(user["IsVerified"]);
                if (!isVerified)
                {
                    ShowMessage("Your account is pending admin approval. Please wait for verification.", "alert alert-warning");
                    return;
                }

                // 4. Set session variables
                Session["UserID"] = user["UserID"].ToString();
                Session["FullName"] = user["FullName"].ToString();
                Session["Role"] = user["Role"].ToString();
                Session["Email"] = email;

                // 5. Redirect based on role
                RedirectToDashboard(user["Role"].ToString());
            }
            catch (Exception ex)
            {
                ShowMessage("An error occurred: " + ex.Message, "alert alert-danger");
            }
        }

        // Redirect user to the correct dashboard based on their role
        private void RedirectToDashboard(string role)
        {
            switch (role)
            {
                case "Admin":
                    Response.Redirect("~/Admin/Dashboard.aspx");
                    break;
                case "Donor":
                    Response.Redirect("~/Donor/Dashboard.aspx");
                    break;
                case "NGO":
                    Response.Redirect("~/NGO/Dashboard.aspx");
                    break;
                case "Volunteer":
                    Response.Redirect("~/Volunteer/Dashboard.aspx");
                    break;
                default:
                    Response.Redirect("~/Login.aspx");
                    break;
            }
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblMessage.Text = message;
            lblMessage.CssClass = cssClass;
            lblMessage.Visible = true;
        }
    }
}
