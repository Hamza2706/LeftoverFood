using LeftoverFoodSystem;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace LeftoverFood.TestRegLogin
{
    public partial class Register : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Nothing needed on initial load
        }

        protected void btnRegister_Click(object sender, EventArgs e)
        {
            // Extra server-side guard (client validators can be bypassed)
            if (!Page.IsValid) return;

            string fullName = txtFullName.Text.Trim();
            string email = txtEmail.Text.Trim().ToLower();
            string phone = txtPhone.Text.Trim();
            string role = ddlRole.SelectedValue;
            string address = txtAddress.Text.Trim();
            string password = txtPassword.Text;

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

        private void ShowMessage(string message, string cssClass)
        {
            lblMessage.Text = message;
            lblMessage.CssClass = cssClass;
            lblMessage.Visible = true;
        }

        private void ClearForm()
        {
            txtFullName.Text = "";
            txtEmail.Text = "";
            txtPhone.Text = "";
            txtAddress.Text = "";
            txtPassword.Text = "";
            txtConfirmPass.Text = "";
            ddlRole.SelectedIndex = 0;
        }
    }
}
