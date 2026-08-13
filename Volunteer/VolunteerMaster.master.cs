using System;
using System.IO;
using System.Web.UI;
using LeftoverFoodSystem;

namespace LeftoverFood.Volunteer
{
    public partial class VolunteerMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            SessionHelper.Logout(Page);
        }

        protected string IsActive(string pageFileName)
        {
            string current = Path.GetFileName(Request.Path);
            return string.Equals(current, pageFileName, StringComparison.OrdinalIgnoreCase) ? "active" : "";
        }
    }
}
