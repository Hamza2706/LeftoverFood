using System;
using System.Web;
using System.Web.UI;

namespace LeftoverFoodSystem
{
    /// <summary>
    /// Call SessionHelper.RequireLogin(this, "Admin") at the top of Page_Load
    /// on any page that needs to be protected.
    /// </summary>
    public class SessionHelper
    {
        // Check if user is logged in; redirect to login if not
        public static void RequireLogin(Page page)
        {
            if (HttpContext.Current.Session["UserID"] == null)
                page.Response.Redirect("~/Login.aspx");
        }

        // Check if user is logged in AND has a specific role
        public static void RequireRole(Page page, string requiredRole)
        {
            RequireLogin(page);

            string currentRole = HttpContext.Current.Session["Role"]?.ToString();
            if (currentRole != requiredRole)
                page.Response.Redirect("~/Unauthorized.aspx");
        }

        // Get current user's ID
        public static int GetUserID()
        {
            return Convert.ToInt32(HttpContext.Current.Session["UserID"]);
        }

        // Get current user's role
        public static string GetRole()
        {
            return HttpContext.Current.Session["Role"]?.ToString();
        }

        // Get current user's full name
        public static string GetFullName()
        {
            return HttpContext.Current.Session["FullName"]?.ToString();
        }

        // Log out and clear session
        public static void Logout(Page page)
        {
            HttpContext.Current.Session.Clear();
            HttpContext.Current.Session.Abandon();
            page.Response.Redirect("~/Login.aspx");
        }
    }
}
