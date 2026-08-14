using System;
using System.IO;
using System.Web;
using System.Web.UI;
using LeftoverFoodSystem;

namespace LeftoverFood.Controls
{
    /// <summary>
    /// Single source for the role sidebar. Renders the nav for whichever role
    /// is in session, so both the four role masters and the root-level
    /// ~/Notifications.aspx can share one copy of the markup.
    ///
    /// The IsActive / btnLogout_Click members here replace four identical
    /// copies that previously lived in each *Master.master.cs.
    /// </summary>
    public partial class RoleSidebar : UserControl
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Unread count badge next to the sidebar's Notifications link.
            // Rendered on every request, so it stays in step with the topbar
            // bell without a second query path.
            if (HttpContext.Current.Session["UserID"] != null)
            {
                int unread = NotificationService.GetUnreadCount(SessionHelper.GetUserID());
                // .fb-nav-item .badge-count is already styled in style.css for
                // exactly this (amber pill, pushed to the right of a nav item).
                litSidebarUnread.Text = unread > 0
                    ? "<span class=\"badge-count\">" + unread + "</span>"
                    : "";
            }
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            SessionHelper.Logout(Page);
        }

        /// <summary>Current user's role, or empty if not signed in.</summary>
        protected string Role
        {
            get { return SessionHelper.GetRole() ?? ""; }
        }

        protected string FullName
        {
            get { return SessionHelper.GetFullName(); }
        }

        protected string Initials
        {
            get { return SessionHelper.Initials(SessionHelper.GetFullName()); }
        }

        /// <summary>
        /// Highlights the current page in the nav. Compares file names so it
        /// works regardless of how the app is rooted in IIS.
        /// </summary>
        protected string IsActive(string pageFileName)
        {
            string current = Path.GetFileName(Request.Path);
            return string.Equals(current, pageFileName, StringComparison.OrdinalIgnoreCase) ? "active" : "";
        }

        // --- Per-role chrome ------------------------------------------------
        // Kept in step with Site.master.cs's topbar avatar colours.

        protected string AvatarStyle
        {
            get
            {
                switch (Role)
                {
                    case "Admin": return "background:var(--purple-light);color:var(--purple)";
                    case "NGO": return "background:var(--amber-light);color:var(--amber)";
                    case "Volunteer": return "background:var(--blue-light);color:var(--blue)";
                    default: return "background:#e8f5ee;color:var(--green)";
                }
            }
        }

        protected string RoleBadgeClass
        {
            get
            {
                switch (Role)
                {
                    case "Admin": return "badge-role-admin";
                    case "NGO": return "badge-role-ngo";
                    case "Volunteer": return "badge-role-vol";
                    default: return "badge-role-donor";
                }
            }
        }

        protected string RoleLabel
        {
            get { return string.IsNullOrEmpty(Role) ? "Guest" : Role; }
        }
    }
}
