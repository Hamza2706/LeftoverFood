using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Donor
{
    /// <summary>
    /// Notification preferences (Phase 4).
    ///
    /// Preference model: one NotificationPreferences row per event, holding both
    /// EmailEnabled and InAppEnabled. The "Email Notifications" card drives
    /// EmailEnabled per event; the single "Donation Status Updates" toggle
    /// drives InAppEnabled across all six live donation events, because there is
    /// no useful reason to silence the in-app copy of one status change but not
    /// another — and thirteen more toggles would be worse, not better.
    ///
    /// A user with no row for an event counts as opted in, so this page only
    /// ever writes rows when something is actually saved.
    /// </summary>
    public partial class notifications : System.Web.UI.Page
    {
        /// <summary>
        /// Checkbox -> event key. Order is the display order on the page.
        /// The bool marks whether anything raises the event today.
        /// </summary>
        private Dictionary<CheckBox, string> EmailToggles
        {
            get
            {
                return new Dictionary<CheckBox, string>
                {
                    { chkEmailDonationPosted,    NotifyEvent.DonationPosted },
                    { chkEmailDonationApproved,  NotifyEvent.DonationApproved },
                    { chkEmailNgoAccepted,       NotifyEvent.NgoAccepted },
                    { chkEmailVolunteerAssigned, NotifyEvent.VolunteerAssigned },
                    { chkEmailFoodPickedUp,      NotifyEvent.FoodPickedUp },
                    { chkEmailDeliveryConfirmed, NotifyEvent.DeliveryConfirmed },
                    { chkEmailExpiryWarning,     NotifyEvent.ExpiryWarning },
                    { chkEmailRatingReceived,    NotifyEvent.RatingReceived },
                    { chkEmailMonthlyImpact,     NotifyEvent.MonthlyImpact },
                    { chkEmailEmergencyAlert,    NotifyEvent.EmergencyAlert }
                };
            }
        }

        /// <summary>
        /// The six events whose in-app copy the "Donation Status Updates"
        /// toggle controls together.
        /// </summary>
        private static readonly string[] LiveStatusEvents =
        {
            NotifyEvent.DonationPosted, NotifyEvent.DonationApproved,
            NotifyEvent.NgoAccepted, NotifyEvent.VolunteerAssigned,
            NotifyEvent.FoodPickedUp, NotifyEvent.DeliveryConfirmed
        };

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Donor");

            if (!IsPostBack)
            {
                BindAccount();
                BindPreferences();
                BindRecent();
            }

            // Config-driven, so it is rebound on every request rather than
            // persisted in ViewState.
            BindSmtpStatus();
        }

        // ------------------------------------------------------------------
        // Binding
        // ------------------------------------------------------------------

        private void BindAccount()
        {
            object email = DBHelper.ExecuteScalar(
                "SELECT Email FROM Users WHERE UserID = @UserID",
                new SqlParameter[] { new SqlParameter("@UserID", SessionHelper.GetUserID()) });

            txtEmail.Text = email == null || email == DBNull.Value ? "" : Convert.ToString(email);
            litEmailPreview.Text = NotificationService.PreviewHtml(SessionHelper.GetFullName());
        }

        private void BindPreferences()
        {
            Dictionary<string, bool[]> prefs =
                NotificationService.GetPreferences(SessionHelper.GetUserID());

            // Missing row == opted in, which is why every lookup defaults true.
            foreach (KeyValuePair<CheckBox, string> pair in EmailToggles)
                pair.Key.Checked = Lookup(prefs, pair.Value, 0);

            chkInAppStatusUpdates.Checked = Lookup(prefs, NotifyEvent.DonationApproved, 1);
            chkInAppNewMessages.Checked = Lookup(prefs, NotifyEvent.NewMessages, 1);
            chkInAppBadgeAlerts.Checked = Lookup(prefs, NotifyEvent.BadgeAlerts, 1);
        }

        /// <summary>index 0 = EmailEnabled, 1 = InAppEnabled.</summary>
        private static bool Lookup(Dictionary<string, bool[]> prefs, string eventKey, int index)
        {
            return !prefs.ContainsKey(eventKey) || prefs[eventKey][index];
        }

        private void BindRecent()
        {
            DataTable dt = NotificationService.GetForUser(SessionHelper.GetUserID(), 5);
            rptRecent.DataSource = dt;
            rptRecent.DataBind();
            pnlNoRecent.Visible = dt.Rows.Count == 0;
        }

        private void BindSmtpStatus()
        {
            litSmtpHost.Text = Server.HtmlEncode(NotificationService.SmtpHost);
            litSmtpPort.Text = Server.HtmlEncode(NotificationService.SmtpPort);

            string from = NotificationService.SmtpFrom;
            litSmtpFrom.Text = string.IsNullOrWhiteSpace(from) || from.StartsWith("REPLACE_WITH")
                ? "<span class=\"text-muted\">not set</span>"
                : Server.HtmlEncode(from);

            // Honest status. The mockup hardcoded "Connected"; this reflects
            // whether Web.config actually has usable credentials.
            litSmtpStatus.Text = NotificationService.SmtpConfigured
                ? "<span class=\"badge-status badge-active\">Configured</span>"
                : "<span class=\"badge-status badge-inactive\">Not configured</span>";

            btnTestEmail.Enabled = NotificationService.SmtpConfigured;
        }

        // ------------------------------------------------------------------
        // Actions
        // ------------------------------------------------------------------

        protected void btnSave_Click(object sender, EventArgs e)
        {
            int userId = SessionHelper.GetUserID();
            bool inAppStatus = chkInAppStatusUpdates.Checked;

            foreach (KeyValuePair<CheckBox, string> pair in EmailToggles)
            {
                // For the six live donation events the in-app flag comes from
                // the shared status toggle; everything else keeps its in-app
                // copy on, so nothing silently disappears from the list.
                bool inApp = Array.IndexOf(LiveStatusEvents, pair.Value) >= 0
                             ? inAppStatus
                             : true;

                NotificationService.SavePreference(userId, pair.Value, pair.Key.Checked, inApp);
            }

            // These two have no email side, so email stays enabled for whenever
            // the feature behind them is built.
            NotificationService.SavePreference(userId, NotifyEvent.NewMessages, true, chkInAppNewMessages.Checked);
            NotificationService.SavePreference(userId, NotifyEvent.BadgeAlerts, true, chkInAppBadgeAlerts.Checked);

            ShowMessage("Notification preferences saved.", "alert-success");
        }

        protected void btnTestEmail_Click(object sender, EventArgs e)
        {
            if (!NotificationService.SmtpConfigured)
            {
                ShowMessage("Email is not configured yet — set the Smtp.* values in Web.config first.", "alert-warning");
                return;
            }

            bool sent = NotificationService.SendEmail(
                txtEmail.Text.Trim(),
                "FoodBridge test email",
                NotificationService.PreviewHtml(SessionHelper.GetFullName()));

            if (sent)
                ShowMessage("Test email sent to " + txtEmail.Text.Trim() + ". Check your inbox (and spam folder).", "alert-success");
            else
                ShowMessage("Could not send the test email. See App_Data/notification-errors.log for the reason.", "alert-danger");
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblMessage.Text = message;
            lblMessage.CssClass = "alert " + cssClass;
            pnlMessage.Visible = true;
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

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
    }
}
