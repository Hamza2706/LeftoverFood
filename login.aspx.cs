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
        SqlConnection cn1;

        protected void Page_Load(object sender, EventArgs e)
        {

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConnection"].ConnectionString;

            cn1 = new SqlConnection(connStr);

            if (!IsPostBack)
            {
                //loginErr.Text = "";
                FormsAuthentication.SignOut();
                //int aaa = VerifyADLogin("zeeshan", "KingExcalibur2022!");
            }
        }

        protected void signin_Click(object sender, EventArgs e)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email.Text) || !email.Text.Contains("@"))
                {
                    lblError.Text = "Please enter a valid email address.";
                    return;
                }
                string[] code = email.Text.Split('@');
                string level1 = code[0];
                string level2 = code[1];
                if (level2 != "")
                {
                    //string jobType = "";
                    //using (SqlCommand checkJob = new SqlCommand("SELECT job_type FROM EmployeesView WHERE email=@Email", cn1))
                    //{
                    //    checkJob.Parameters.AddWithValue("@Email", email.Text);
                    //    cn1.Open();
                    //    object result = checkJob.ExecuteScalar();
                    //    cn1.Close();

                    //    if (result != null)
                    //        jobType = result.ToString();
                    //}


                    //if (jobType == "Cleaner")
                    //{
                    //    lblError.Text = "Access is restricted. Only authorized personnel are permitted to log in. Please contact your system administrator if you require access.";
                    //    email.Text = "";
                    //    password.Text = "";
                    //    return;
                    //}

                    string DomainName = "";
                    string[] FullEmail = email.Text.Split('@');
                    if (FullEmail.Length > 1)
                    {
                        DomainName = FullEmail[1];
                    }



                    using (SqlCommand cmd = new SqlCommand("ValidateUser", cn1))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        string EncPass = FormsAuthentication.HashPasswordForStoringInConfigFile(password.Text, "SHA1");

                        SqlParameter EName = new SqlParameter("@Email", email.Text);
                        SqlParameter EPass = new SqlParameter("@UserPass", EncPass);

                        cmd.Parameters.Add(EName);
                        cmd.Parameters.Add(EPass);
                        cn1.Open();
                        int ReturnCode = (int)cmd.ExecuteScalar();
                        cn1.Close();
                        if (ReturnCode == 1 || ReturnCode == 2)
                        {
                            FormsAuthentication.RedirectFromLoginPage(email.Text, false);
                        }
                        else
                        {
                            lblError.Text = "Incorrect Email or Password. Please use organization email id only";
                            email.Text = "";
                            password.Text = "";
                        }
                    }




                }
                else
                {
                    //   lblError.Text = "Please use organization email id only";
                }
            }
            catch (Exception Exx)
            {
                //loginErr.Text = "Invalid email id!";
                lblError.Text = Exx.ToString();
                email.Text = "";
                password.Text = "";
            }



            //if (UsrName.Text == "altaf@cleanology.com" && UsrPass.Text == "systemadmin123")
            //{                
            //    bool isCookiePersistent = chckrm.Checked;

            //    FormsAuthenticationTicket authTicket = new FormsAuthenticationTicket(1, UsrName.Text, DateTime.Now, DateTime.Now.AddMinutes(180), isCookiePersistent, "");

            //    //Encrypt the ticket.
            //    string encryptedTicket = FormsAuthentication.Encrypt(authTicket);

            //    //Create a cookie, and then add the encrypted ticket to the cookie as data.
            //    HttpCookie authCookie = new HttpCookie(FormsAuthentication.FormsCookieName, encryptedTicket);

            //    if (true == isCookiePersistent)
            //        authCookie.Expires = authTicket.Expiration;

            //    //Add the cookie to the outgoing cookies collection.
            //    Response.Cookies.Add(authCookie);

            //    //You can redirect now.
            //    Response.Redirect(FormsAuthentication.GetRedirectUrl(UsrName.Text, false));
            //}
            //else
            //{
            //    loginErr.Text = "Incorrect Information!";
            //}
        }
    }
}
