using LeftoverFoodSystem;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace LeftoverFood
{
    public partial class login : System.Web.UI.Page
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
                    Response.Redirect("~/Admin/admin-dashboard.aspx");
                    break;
                case "Donor":
                    Response.Redirect("~/Donor/donor-dashboard.aspx");
                    break;
                case "NGO":
                    Response.Redirect("~/NGO/ngo-dashboard.aspx");
                    break;
                case "Volunteer":
                    Response.Redirect("~/Volunteer/volunteer-dashboard.aspx");
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


        protected void btnRegister_Click(object sender, EventArgs e)
        {
            // Extra server-side guard (client validators can be bypassed)
            if (!Page.IsValid) return;

            string fullName = txtFullName.Text.Trim();
            string email = txtEmailReg.Text.Trim().ToLower();
            string phone = txtPhone.Text.Trim();
            string role = ddlRole.SelectedValue;
            string address = txtAddress.Text.Trim();
            string password = txtPasswordReg.Text;

            // 1. Check if email already exists
            string checkQuery = "SELECT COUNT(*) FROM Users WHERE Email = @Email";
            SqlParameter[] checkParams = {
                new SqlParameter("@Email", email)
            };
            int count = Convert.ToInt32(DBHelper.ExecuteScalar(checkQuery, checkParams));

            if (count > 0)
            {
                ShowMessage("This email is already registered. Please login.", "alert alert-danger");
                return;
            }

            // 2. Hash the password
            string hashedPassword = PasswordHelper.HashPassword(password);

            // 3. Insert new user (IsVerified = 0 until Admin approves)
            string insertQuery = @"
                INSERT INTO Users (FullName, Email, PasswordHash, Role, Phone, Address, IsVerified, CreatedAt)
                VALUES (@FullName, @Email, @PasswordHash, @Role, @Phone, @Address, 0, GETDATE())";

            SqlParameter[] insertParams = {
                new SqlParameter("@FullName",     fullName),
                new SqlParameter("@Email",        email),
                new SqlParameter("@PasswordHash", hashedPassword),
                new SqlParameter("@Role",         role),
                new SqlParameter("@Phone",        phone),
                new SqlParameter("@Address",      address)
            };

            try
            {
                int rows = DBHelper.ExecuteNonQuery(insertQuery, insertParams);

                if (rows > 0)
                {
                    ShowMessage("Registration successful! Your account is pending admin approval. You will be notified via email.", "alert alert-success");
                    ClearForm();
                }
                else
                {
                    ShowMessage("Registration failed. Please try again.", "alert alert-danger");
                }
            }
            catch (Exception ex)
            {
                ShowMessage("An error occurred: " + ex.Message, "alert alert-danger");
            }
        }

        private void ClearForm()
        {
            txtFullName.Text = "";
            txtEmail.Text = "";
            txtPhone.Text = "";
            txtAddress.Text = "";
            txtPasswordReg.Text = "";
            txtConfirmPass.Text = "";
            ddlRole.SelectedIndex = 0;
        }
    }
}
