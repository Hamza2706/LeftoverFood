using System;
using System.Web.UI;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string fullName = SessionHelper.GetFullName();
            topbarAvatar.InnerText = SessionHelper.Initials(fullName);
            topbarAvatar.Style["background"] = RoleAvatarBg(SessionHelper.GetRole());
            topbarAvatar.Style["color"] = RoleAvatarColor(SessionHelper.GetRole());
        }

        private string RoleAvatarBg(string role)
        {
            switch (role)
            {
                case "Admin": return "var(--purple-light)";
                case "NGO": return "var(--amber-light)";
                case "Volunteer": return "var(--blue-light)";
                default: return "#e8f5ee";
            }
        }

        private string RoleAvatarColor(string role)
        {
            switch (role)
            {
                case "Admin": return "var(--purple)";
                case "NGO": return "var(--amber)";
                case "Volunteer": return "var(--blue)";
                default: return "var(--green)";
            }
        }
    }
}
