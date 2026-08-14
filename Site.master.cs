using System;
using System.Web;
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

            BindNotificationBell();
        }

        /// <summary>
        /// Live unread count on the topbar bell (Phase 4). Shows a number up to
        /// 9 and "9+" beyond that, so the badge never widens enough to break the
        /// 38px circular button.
        ///
        /// This runs on every page render for every role, which is why
        /// GetUnreadCount is a single indexed COUNT and swallows its own errors
        /// — a notification problem must never take down the shared layout.
        /// </summary>
        private void BindNotificationBell()
        {
            if (HttpContext.Current.Session["UserID"] == null)
            {
                notifBell.Visible = false;
                return;
            }

            int unread = NotificationService.GetUnreadCount(SessionHelper.GetUserID());

            if (unread <= 0)
            {
                litBellBadge.Text = "";
                notifBell.Attributes["title"] = "Notifications";
                return;
            }

            notifBell.Attributes["title"] = unread + " unread notification" + (unread == 1 ? "" : "s");
            litBellBadge.Text =
                "<span class=\"notif-dot\" style=\"width:auto;height:auto;min-width:16px;top:2px;right:2px;"
                + "padding:0 4px;font-size:.62rem;font-weight:700;line-height:16px;text-align:center;color:#fff\">"
                + (unread > 9 ? "9+" : unread.ToString())
                + "</span>";
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
