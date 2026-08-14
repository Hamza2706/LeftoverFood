using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    /// <summary>
    /// Shared notification list for all four roles (Phase 4).
    ///
    /// Class name is NotificationsPage rather than Notifications to avoid
    /// colliding with the Notifications table naming used elsewhere and, more
    /// importantly, with LeftoverFoodSystem types pulled in by the using above.
    /// </summary>
    public partial class NotificationsPage : System.Web.UI.Page
    {
        /// <summary>
        /// Filter state. Kept in ViewState so paging back and forth between
        /// All/Unread survives the postbacks from Mark-read and Delete.
        /// </summary>
        private bool ShowUnreadOnly
        {
            get { return ViewState["UnreadOnly"] != null && (bool)ViewState["UnreadOnly"]; }
            set { ViewState["UnreadOnly"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // RequireLogin, not RequireRole — every role has notifications, and
            // every query below is scoped by UserID, so there is nothing
            // role-specific to gate on here.
            SessionHelper.RequireLogin(this);

            if (!IsPostBack)
                BindList();
        }

        // ------------------------------------------------------------------
        // Binding
        // ------------------------------------------------------------------

        private void BindList()
        {
            int userId = SessionHelper.GetUserID();

            DataTable dt = NotificationService.GetForUser(userId);

            if (ShowUnreadOnly)
            {
                DataView dv = dt.DefaultView;
                dv.RowFilter = "IsRead = 0";
                dt = dv.ToTable();
            }

            rptNotifications.DataSource = dt;
            rptNotifications.DataBind();

            // Empty state, worded for whichever filter is active so "no unread"
            // doesn't read as "you have never received anything".
            pnlEmpty.Visible = dt.Rows.Count == 0;
            litEmpty.Text = ShowUnreadOnly
                ? "No unread notifications. You're all caught up."
                : "No notifications yet. You'll be notified here when your donations move through approval, pickup and delivery.";

            int unread = NotificationService.GetUnreadCount(userId);
            litSummary.Text = unread > 0
                ? unread + (unread == 1 ? " unread notification" : " unread notifications")
                : "You're all caught up.";

            btnMarkAll.Visible = unread > 0;

            // Active-tab styling
            btnFilterAll.CssClass = ShowUnreadOnly ? "filter-tab" : "filter-tab active";
            btnFilterUnread.CssClass = ShowUnreadOnly ? "filter-tab active" : "filter-tab";
        }

        // ------------------------------------------------------------------
        // Actions
        // ------------------------------------------------------------------

        protected void rptNotifications_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int notificationId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out notificationId))
                return;

            int userId = SessionHelper.GetUserID();

            // Both calls are scoped by UserID inside NotificationService, so a
            // forged NotificationID for someone else's row simply affects zero
            // rows rather than leaking or destroying data.
            if (e.CommandName == "MarkRead")
            {
                NotificationService.MarkRead(notificationId, userId);
            }
            else if (e.CommandName == "Delete")
            {
                NotificationService.Delete(notificationId, userId);
                ShowMessage("Notification deleted.");
            }

            BindList();
        }

        protected void btnMarkAll_Click(object sender, EventArgs e)
        {
            NotificationService.MarkAllRead(SessionHelper.GetUserID());
            ShowMessage("All notifications marked as read.");
            BindList();
        }

        protected void btnFilterAll_Click(object sender, EventArgs e)
        {
            ShowUnreadOnly = false;
            BindList();
        }

        protected void btnFilterUnread_Click(object sender, EventArgs e)
        {
            ShowUnreadOnly = true;
            BindList();
        }

        private void ShowMessage(string text)
        {
            litMessage.Text = text;
            pnlMessage.Visible = true;
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// Safe ResolveUrl for the optional LinkUrl column — the value is null
        /// for notifications that have nothing to link to.
        /// </summary>
        protected string ResolveLink(object linkUrl)
        {
            string s = Convert.ToString(linkUrl);
            return string.IsNullOrWhiteSpace(s) ? "" : ResolveUrl(s);
        }

        /// <summary>Dot colour per notification type.</summary>
        protected string TypeColor(object type)
        {
            switch (Convert.ToString(type))
            {
                case NotifyType.Approval: return "var(--blue)";
                case NotifyType.Delivery: return "var(--green)";
                case NotifyType.Emergency: return "var(--red)";
                default: return "var(--purple)";
            }
        }

        protected string TypeBadgeClass(object type)
        {
            switch (Convert.ToString(type))
            {
                case NotifyType.Approval: return "badge-accepted";
                case NotifyType.Delivery: return "badge-delivered";
                case NotifyType.Emergency: return "badge-rejected";
                default: return "badge-pending";
            }
        }

        /// <summary>
        /// Relative timestamp ("2 hours ago"), falling back to an absolute date
        /// once something is more than a week old.
        /// </summary>
        protected string TimeAgo(object createdAt)
        {
            DateTime dt;
            if (createdAt == null || !DateTime.TryParse(Convert.ToString(createdAt), out dt))
                return "";

            TimeSpan span = DateTime.Now - dt;

            if (span.TotalSeconds < 60) return "Just now";
            if (span.TotalMinutes < 60) return (int)span.TotalMinutes + " min ago";
            if (span.TotalHours < 24) return (int)span.TotalHours + (span.TotalHours < 2 ? " hour ago" : " hours ago");
            if (span.TotalDays < 7) return (int)span.TotalDays + (span.TotalDays < 2 ? " day ago" : " days ago");

            return dt.ToString("dd MMM yyyy, h:mm tt");
        }
    }
}
