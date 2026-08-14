using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Web;

namespace LeftoverFoodSystem
{
    /// <summary>
    /// Event keys used by NotificationPreferences. A key identifies a *kind* of
    /// event a user can opt out of; passing null as the event key to Notify()
    /// means "mandatory, not opt-out-able" (account status changes).
    /// </summary>
    public static class NotifyEvent
    {
        // --- Events that actually fire in Phase 4 ---
        public const string DonationPosted = "DonationPosted";
        public const string DonationApproved = "DonationApproved";
        public const string NgoAccepted = "NgoAccepted";
        public const string VolunteerAssigned = "VolunteerAssigned";
        public const string FoodPickedUp = "FoodPickedUp";
        public const string DeliveryConfirmed = "DeliveryConfirmed";

        // --- Declared here so the preference UI can persist them, but nothing
        //     raises these yet. Each needs a feature that does not exist:
        //       ExpiryWarning / MonthlyImpact -> a scheduler (this app is purely
        //         request-driven; there is no background job host)
        //       RatingReceived                -> Phase 6c
        //       EmergencyAlert                -> Phase 6a
        //       NewMessages / BadgeAlerts     -> no messaging or badge feature
        //     The settings page labels these as inactive rather than implying
        //     they work.
        public const string ExpiryWarning = "ExpiryWarning";
        public const string RatingReceived = "RatingReceived";
        public const string MonthlyImpact = "MonthlyImpact";
        public const string EmergencyAlert = "EmergencyAlert";
        public const string RealtimeStatus = "RealtimeStatus";
        public const string NewMessages = "NewMessages";
        public const string BadgeAlerts = "BadgeAlerts";

        /// <summary>Event keys with no code path raising them yet.</summary>
        public static readonly string[] NotYetActive =
        {
            ExpiryWarning, RatingReceived, MonthlyImpact,
            EmergencyAlert, NewMessages, BadgeAlerts
        };

        public static bool IsActive(string eventKey)
        {
            return Array.IndexOf(NotYetActive, eventKey) < 0;
        }
    }

    /// <summary>
    /// Notification type — matches the Notifications.Type column.
    /// </summary>
    public static class NotifyType
    {
        public const string Approval = "Approval";
        public const string Delivery = "Delivery";
        public const string Emergency = "Emergency";
        public const string System = "System";
    }

    /// <summary>
    /// Phase 4. One call site per state change; two delivery channels.
    ///
    ///   In-app  — a row in Notifications. This is the source of truth and is
    ///             what the bell badge and ~/Notifications.aspx read.
    ///   Email   — best effort on top, via System.Net.Mail. Never allowed to
    ///             fail the caller: a bounced email must not stop a donation
    ///             from being approved.
    ///
    /// Everything here is deliberately fail-soft. Notify() catches its own
    /// exceptions and logs them rather than rethrowing, because every caller is
    /// a business transaction that already succeeded by the time we are called.
    /// Errors land in ~/App_Data/notification-errors.log.
    ///
    /// Style matches PasswordHelper / SessionHelper: a flat static class over
    /// DBHelper, no DI, no repository layer.
    /// </summary>
    public class NotificationService
    {
        // ------------------------------------------------------------------
        // Sending
        // ------------------------------------------------------------------

        /// <summary>
        /// Notify one user. Always safe to call — never throws.
        /// </summary>
        /// <param name="userId">Recipient.</param>
        /// <param name="subject">Short title, used as the email subject.</param>
        /// <param name="message">Body text. Also the in-app message.</param>
        /// <param name="type">One of NotifyType.*</param>
        /// <param name="eventKey">
        /// A NotifyEvent.* key, or null for mandatory notifications the user
        /// must not be able to opt out of (e.g. account suspended).
        /// </param>
        /// <param name="linkUrl">
        /// Optional app-relative link (e.g. "~/Donor/track-donation.aspx?id=12")
        /// making the notification clickable.
        /// </param>
        public static void Notify(int userId, string subject, string message,
                                  string type, string eventKey = null,
                                  string linkUrl = null)
        {
            try
            {
                bool emailEnabled = true;
                bool inAppEnabled = true;
                string email = null;
                string fullName = null;

                // One round trip for recipient details + their preference for
                // this event. LEFT JOIN + ISNULL means "no preference row" reads
                // as opted in, so the table only ever stores real opt-outs.
                DataTable dt = DBHelper.ExecuteQuery(
                    @"SELECT u.Email, u.FullName,
                             ISNULL(p.EmailEnabled, 1) AS EmailEnabled,
                             ISNULL(p.InAppEnabled, 1) AS InAppEnabled
                      FROM Users u
                      LEFT JOIN NotificationPreferences p
                             ON p.UserID = u.UserID AND p.EventKey = @EventKey
                      WHERE u.UserID = @UserID",
                    new SqlParameter[]
                    {
                        new SqlParameter("@UserID", userId),
                        new SqlParameter("@EventKey", (object)eventKey ?? DBNull.Value)
                    });

                if (dt.Rows.Count == 0) return;   // user no longer exists

                email = dt.Rows[0]["Email"] as string;
                fullName = dt.Rows[0]["FullName"] as string;

                // A null event key means mandatory — skip the preference check.
                if (eventKey != null)
                {
                    emailEnabled = Convert.ToBoolean(dt.Rows[0]["EmailEnabled"]);
                    inAppEnabled = Convert.ToBoolean(dt.Rows[0]["InAppEnabled"]);
                }

                if (inAppEnabled)
                {
                    DBHelper.ExecuteNonQuery(
                        @"INSERT INTO Notifications (UserID, Message, [Type], LinkUrl)
                          VALUES (@UserID, @Message, @Type, @LinkUrl)",
                        new SqlParameter[]
                        {
                            new SqlParameter("@UserID", userId),
                            new SqlParameter("@Message", Truncate(message, 500)),
                            new SqlParameter("@Type", type ?? NotifyType.System),
                            new SqlParameter("@LinkUrl", (object)linkUrl ?? DBNull.Value)
                        });
                }

                if (emailEnabled && !string.IsNullOrWhiteSpace(email))
                {
                    SendEmail(email, subject,
                              BuildHtmlBody(fullName, subject, message, linkUrl));
                }
            }
            catch (Exception ex)
            {
                // Deliberately swallowed. The caller's business transaction has
                // already committed; a notification problem must not surface as
                // a failed donation/approval.
                LogError("Notify(userId=" + userId + ", event=" + eventKey + ")", ex);
            }
        }

        /// <summary>Notify several users with the same message.</summary>
        public static void NotifyMany(IEnumerable<int> userIds, string subject,
                                      string message, string type,
                                      string eventKey = null, string linkUrl = null)
        {
            if (userIds == null) return;
            foreach (int id in userIds)
                Notify(id, subject, message, type, eventKey, linkUrl);
        }

        /// <summary>
        /// Notify every active, verified user in a role — used to tell all
        /// Admins that something needs their attention.
        ///
        /// Scaling limit: this is synchronous and sends one email per user, so
        /// it is fine for the handful of admins here but would need a queue for
        /// the Phase 6a emergency broadcast to hundreds of users.
        /// </summary>
        public static void NotifyRole(string role, string subject, string message,
                                      string type, string eventKey = null,
                                      string linkUrl = null)
        {
            try
            {
                DataTable dt = DBHelper.ExecuteQuery(
                    "SELECT UserID FROM Users WHERE Role = @Role AND IsActive = 1 AND IsVerified = 1",
                    new SqlParameter[] { new SqlParameter("@Role", role) });

                foreach (DataRow r in dt.Rows)
                    Notify(Convert.ToInt32(r["UserID"]), subject, message, type, eventKey, linkUrl);
            }
            catch (Exception ex)
            {
                LogError("NotifyRole(" + role + ")", ex);
            }
        }

        // ------------------------------------------------------------------
        // Reading
        // ------------------------------------------------------------------

        /// <summary>Unread count for the topbar bell. Never throws.</summary>
        public static int GetUnreadCount(int userId)
        {
            try
            {
                object o = DBHelper.ExecuteScalar(
                    "SELECT COUNT(*) FROM Notifications WHERE UserID = @UserID AND IsRead = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
            }
            catch (Exception ex)
            {
                LogError("GetUnreadCount", ex);
                return 0;
            }
        }

        /// <summary>Newest-first notifications for one user.</summary>
        public static DataTable GetForUser(int userId, int max = 100)
        {
            return DBHelper.ExecuteQuery(
                @"SELECT TOP (@Max) NotificationID, Message, [Type], IsRead, CreatedAt, LinkUrl
                  FROM Notifications
                  WHERE UserID = @UserID
                  ORDER BY CreatedAt DESC, NotificationID DESC",
                new SqlParameter[]
                {
                    new SqlParameter("@Max", max),
                    new SqlParameter("@UserID", userId)
                });
        }

        /// <summary>
        /// Mark one notification read. Scoped by UserID so a guessed
        /// NotificationID cannot touch someone else's row.
        /// </summary>
        public static void MarkRead(int notificationId, int userId)
        {
            DBHelper.ExecuteNonQuery(
                "UPDATE Notifications SET IsRead = 1 WHERE NotificationID = @ID AND UserID = @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@ID", notificationId),
                    new SqlParameter("@UserID", userId)
                });
        }

        public static void MarkAllRead(int userId)
        {
            DBHelper.ExecuteNonQuery(
                "UPDATE Notifications SET IsRead = 1 WHERE UserID = @UserID AND IsRead = 0",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });
        }

        public static void Delete(int notificationId, int userId)
        {
            DBHelper.ExecuteNonQuery(
                "DELETE FROM Notifications WHERE NotificationID = @ID AND UserID = @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@ID", notificationId),
                    new SqlParameter("@UserID", userId)
                });
        }

        // ------------------------------------------------------------------
        // Preferences
        // ------------------------------------------------------------------

        /// <summary>
        /// All stored preferences for a user, keyed by EventKey. Missing keys
        /// mean "opted in" — callers should default to true.
        /// </summary>
        public static Dictionary<string, bool[]> GetPreferences(int userId)
        {
            var map = new Dictionary<string, bool[]>(StringComparer.OrdinalIgnoreCase);
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT EventKey, EmailEnabled, InAppEnabled FROM NotificationPreferences WHERE UserID = @UserID",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            foreach (DataRow r in dt.Rows)
            {
                map[r["EventKey"].ToString()] = new bool[]
                {
                    Convert.ToBoolean(r["EmailEnabled"]),
                    Convert.ToBoolean(r["InAppEnabled"])
                };
            }
            return map;
        }

        /// <summary>
        /// Upsert one preference. Uses the UQ_NotifPrefs_User_Event constraint
        /// as the natural key — update first, insert only if nothing matched.
        /// </summary>
        public static void SavePreference(int userId, string eventKey,
                                          bool emailEnabled, bool inAppEnabled)
        {
            int rows = DBHelper.ExecuteNonQuery(
                @"UPDATE NotificationPreferences
                  SET EmailEnabled = @Email, InAppEnabled = @InApp, UpdatedAt = GETDATE()
                  WHERE UserID = @UserID AND EventKey = @EventKey",
                new SqlParameter[]
                {
                    new SqlParameter("@Email", emailEnabled),
                    new SqlParameter("@InApp", inAppEnabled),
                    new SqlParameter("@UserID", userId),
                    new SqlParameter("@EventKey", eventKey)
                });

            if (rows == 0)
            {
                DBHelper.ExecuteNonQuery(
                    @"INSERT INTO NotificationPreferences (UserID, EventKey, EmailEnabled, InAppEnabled)
                      VALUES (@UserID, @EventKey, @Email, @InApp)",
                    new SqlParameter[]
                    {
                        new SqlParameter("@UserID", userId),
                        new SqlParameter("@EventKey", eventKey),
                        new SqlParameter("@Email", emailEnabled),
                        new SqlParameter("@InApp", inAppEnabled)
                    });
            }
        }

        // ------------------------------------------------------------------
        // Email
        // ------------------------------------------------------------------

        public static bool SmtpEnabled
        {
            get { return AppSetting("Smtp.Enabled", "false").Equals("true", StringComparison.OrdinalIgnoreCase); }
        }

        public static string SmtpHost { get { return AppSetting("Smtp.Host", "smtp.gmail.com"); } }
        public static string SmtpPort { get { return AppSetting("Smtp.Port", "587"); } }
        public static string SmtpFrom { get { return AppSetting("Smtp.FromAddress", ""); } }

        /// <summary>
        /// True only when SMTP is switched on AND the placeholder credentials
        /// have actually been replaced. Lets the settings page show an honest
        /// "Not configured" state instead of the mockup's fake "Connected".
        /// </summary>
        public static bool SmtpConfigured
        {
            get
            {
                string user = AppSetting("Smtp.User", "");
                string pass = AppSetting("Smtp.Password", "");
                return SmtpEnabled
                       && !string.IsNullOrWhiteSpace(user)
                       && !string.IsNullOrWhiteSpace(pass)
                       && !user.StartsWith("REPLACE_WITH")
                       && !pass.StartsWith("REPLACE_WITH");
            }
        }

        /// <summary>
        /// Send one email. Returns true on success, false on any failure —
        /// callers treat email as optional and ignore the result.
        /// </summary>
        public static bool SendEmail(string to, string subject, string htmlBody)
        {
            if (!SmtpConfigured) return false;          // silently skip, by design
            if (string.IsNullOrWhiteSpace(to)) return false;

            try
            {
                int port;
                if (!int.TryParse(SmtpPort, out port)) port = 587;

                using (SmtpClient client = new SmtpClient(SmtpHost, port))
                {
                    client.EnableSsl = AppSetting("Smtp.EnableSsl", "true")
                                       .Equals("true", StringComparison.OrdinalIgnoreCase);
                    client.DeliveryMethod = SmtpDeliveryMethod.Network;
                    client.UseDefaultCredentials = false;
                    client.Credentials = new NetworkCredential(
                        AppSetting("Smtp.User", ""), AppSetting("Smtp.Password", ""));

                    // Default is 100 seconds. That would freeze an admin's
                    // "Approve" postback for over a minute if the SMTP host is
                    // unreachable, so cap it well below any reasonable patience.
                    client.Timeout = 15000;

                    using (MailMessage msg = new MailMessage())
                    {
                        msg.From = new MailAddress(
                            string.IsNullOrWhiteSpace(SmtpFrom) ? AppSetting("Smtp.User", "") : SmtpFrom,
                            AppSetting("Smtp.FromName", "FoodBridge"));
                        msg.To.Add(to);
                        msg.Subject = subject;
                        msg.Body = htmlBody;
                        msg.IsBodyHtml = true;
                        msg.BodyEncoding = Encoding.UTF8;
                        msg.SubjectEncoding = Encoding.UTF8;

                        client.Send(msg);
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                LogError("SendEmail(to=" + to + ")", ex);
                return false;
            }
        }

        /// <summary>
        /// Renders the real email template with sample content, for the preview
        /// card on Donor/notifications.aspx. Using the actual template means the
        /// preview cannot drift away from what the app really sends.
        /// </summary>
        public static string PreviewHtml(string fullName)
        {
            return BuildHtmlBody(
                fullName,
                "Your donation has been delivered",
                "Your donation \"30 plates of Biryani & Naan\" has been delivered successfully. "
                + "Thank you for helping reduce food waste.",
                "~/Notifications.aspx");
        }

        /// <summary>
        /// HTML email shell, styled to match the preview card on
        /// Donor/notifications.aspx. Inline CSS only — email clients strip
        /// stylesheets.
        /// </summary>
        private static string BuildHtmlBody(string fullName, string title,
                                            string message, string linkUrl)
        {
            string greeting = string.IsNullOrWhiteSpace(fullName) ? "there" : fullName;

            var sb = new StringBuilder();
            sb.Append("<div style=\"font-family:Segoe UI,Arial,sans-serif;max-width:520px;margin:0 auto;border:1px solid #e6e0d4;border-radius:10px;overflow:hidden\">");
            sb.Append("<div style=\"background:#2f7a4d;color:#fff;padding:16px 20px\">");
            sb.Append("<div style=\"font-size:19px;font-weight:600\">&#127807; FoodBridge</div>");
            sb.Append("<div style=\"font-size:12px;opacity:.8;margin-top:2px\">Smart Leftover Food Redistribution</div>");
            sb.Append("</div>");
            sb.Append("<div style=\"padding:20px;background:#fff\">");
            sb.Append("<div style=\"font-weight:700;font-size:15px;margin-bottom:12px;color:#1f2937\">")
              .Append(HtmlEncode(title)).Append("</div>");
            sb.Append("<p style=\"font-size:13.5px;color:#4b5563;line-height:1.7;margin:0 0 12px\">Dear ")
              .Append(HtmlEncode(greeting)).Append(",</p>");
            sb.Append("<p style=\"font-size:13.5px;color:#4b5563;line-height:1.7;margin:0 0 16px\">")
              .Append(HtmlEncode(message)).Append("</p>");

            if (!string.IsNullOrWhiteSpace(linkUrl))
            {
                sb.Append("<div style=\"text-align:center;margin:18px 0\">")
                  .Append("<a href=\"").Append(HtmlEncode(ToAbsoluteUrl(linkUrl))).Append("\" ")
                  .Append("style=\"background:#2f7a4d;color:#fff;border-radius:50px;padding:10px 22px;font-size:13px;font-weight:600;text-decoration:none;display:inline-block\">")
                  .Append("View Details</a></div>");
            }

            sb.Append("<div style=\"margin-top:16px;padding-top:12px;border-top:1px solid #e6e0d4;font-size:11px;color:#9ca3af;text-align:center\">");
            sb.Append("FoodBridge &middot; Karachi, Pakistan<br/>");
            sb.Append("You can change which emails you receive in your notification preferences.");
            sb.Append("</div></div></div>");

            return sb.ToString();
        }

        // ------------------------------------------------------------------
        // Helpers
        // ------------------------------------------------------------------

        private static string AppSetting(string key, string fallback)
        {
            string v = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        /// <summary>
        /// Turn "~/Donor/track-donation.aspx?id=4" into a full URL for emails,
        /// using App.BaseUrl. Emails have no app context, so ResolveUrl alone
        /// would produce a link that only works inside the browser session.
        /// </summary>
        private static string ToAbsoluteUrl(string appRelative)
        {
            if (string.IsNullOrWhiteSpace(appRelative)) return "";
            if (appRelative.StartsWith("http://") || appRelative.StartsWith("https://"))
                return appRelative;

            string baseUrl = AppSetting("App.BaseUrl", "");
            if (string.IsNullOrWhiteSpace(baseUrl)) return appRelative;
            if (!baseUrl.EndsWith("/")) baseUrl += "/";

            return baseUrl + appRelative.TrimStart('~', '/');
        }

        private static string Truncate(string s, int max)
        {
            if (string.IsNullOrEmpty(s)) return s;
            return s.Length <= max ? s : s.Substring(0, max - 1) + "…";
        }

        private static string HtmlEncode(string s)
        {
            return string.IsNullOrEmpty(s) ? "" : HttpUtility.HtmlEncode(s);
        }

        /// <summary>
        /// Append-only error log. Best effort — a logging failure must not
        /// escape either, or it would defeat the whole fail-soft design.
        /// </summary>
        private static void LogError(string context, Exception ex)
        {
            try
            {
                if (HttpContext.Current == null) return;

                string dir = HttpContext.Current.Server.MapPath("~/App_Data");
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                File.AppendAllText(
                    Path.Combine(dir, "notification-errors.log"),
                    string.Format("{0:yyyy-MM-dd HH:mm:ss}  {1}{2}{3}{2}{2}",
                                  DateTime.Now, context, Environment.NewLine, ex));
            }
            catch
            {
                // Nothing sensible left to do.
            }
        }
    }
}
