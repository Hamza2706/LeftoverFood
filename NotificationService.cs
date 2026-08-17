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

        // --- Added in Phase 6c ---
        // Raised by ~/Ratings.aspx when someone rates you.
        public const string RatingReceived = "RatingReceived";

        // --- Added in Phase 6a ---
        // Raised by Admin/emergency-mode.aspx on activation and on broadcast.
        public const string EmergencyAlert = "EmergencyAlert";

        // --- Declared here so the preference UI can persist them, but nothing
        //     raises these yet. Each needs a feature that does not exist:
        //       ExpiryWarning / MonthlyImpact -> a scheduler (this app is purely
        //         request-driven; there is no background job host)
        //       NewMessages / BadgeAlerts     -> no messaging or badge feature
        //     The settings page labels these as inactive rather than implying
        //     they work.
        public const string ExpiryWarning = "ExpiryWarning";
        public const string MonthlyImpact = "MonthlyImpact";
        public const string RealtimeStatus = "RealtimeStatus";
        public const string NewMessages = "NewMessages";
        public const string BadgeAlerts = "BadgeAlerts";

        /// <summary>Event keys with no code path raising them yet.</summary>
        public static readonly string[] NotYetActive =
        {
            ExpiryWarning, MonthlyImpact, NewMessages, BadgeAlerts
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
        // Broadcast (Phase 6a)
        // ------------------------------------------------------------------

        /// <summary>
        /// The audience for one broadcast: which roles, optionally narrowed to
        /// one city.
        ///
        /// A small struct rather than four loose parameters because the same
        /// audience has to be resolved twice — once to *count* recipients for
        /// the admin's preview, and once to actually send. Keeping it in one
        /// place is what stops the number shown from disagreeing with the
        /// number reached.
        /// </summary>
        public class BroadcastAudience
        {
            /// <summary>Roles to reach, e.g. { "NGO", "Volunteer" }.</summary>
            public string[] Roles { get; set; }

            /// <summary>Null or empty means every city.</summary>
            public string City { get; set; }

            /// <summary>
            /// Whether to also reach users whose City is blank.
            ///
            /// This matters more than it looks. Users.City is nullable and
            /// mostly unset in practice — when this feature was built, 24 of 28
            /// accounts had no city on record. Filtering strictly by city would
            /// therefore drop most of the userbase from a flood alert without
            /// saying so. For an emergency the costly mistake is not reaching
            /// someone, so this defaults to true and the admin sees the number
            /// it adds before sending.
            /// </summary>
            public bool IncludeUnknownCity { get; set; }

            public BroadcastAudience()
            {
                Roles = new string[0];
                IncludeUnknownCity = true;
            }
        }

        /// <summary>
        /// Builds the WHERE clause and parameters selecting a broadcast's
        /// recipients. Shared by the count and the send so the two can never
        /// describe different sets of people.
        ///
        /// Roles are expanded into individually named parameters rather than
        /// concatenated into the SQL — the values come from a dropdown today,
        /// but a broadcast audience is exactly the kind of thing that grows a
        /// free-text entry point later.
        /// </summary>
        private static string BuildAudienceFilter(BroadcastAudience audience,
                                                  List<SqlParameter> parameters)
        {
            StringBuilder where = new StringBuilder(
                " WHERE u.IsActive = 1 AND u.IsVerified = 1");

            if (audience.Roles != null && audience.Roles.Length > 0)
            {
                List<string> names = new List<string>();
                for (int i = 0; i < audience.Roles.Length; i++)
                {
                    string name = "@role" + i;
                    names.Add(name);
                    parameters.Add(new SqlParameter(name, audience.Roles[i]));
                }
                where.Append(" AND u.Role IN (").Append(string.Join(", ", names)).Append(")");
            }

            if (!string.IsNullOrWhiteSpace(audience.City))
            {
                parameters.Add(new SqlParameter("@city", audience.City.Trim()));

                where.Append(audience.IncludeUnknownCity
                    ? " AND (u.City = @city OR u.City IS NULL OR LTRIM(RTRIM(u.City)) = '')"
                    : " AND u.City = @city");
            }

            return where.ToString();
        }

        /// <summary>How many people a broadcast would reach, for the preview.</summary>
        public static int CountAudience(BroadcastAudience audience)
        {
            try
            {
                List<SqlParameter> ps = new List<SqlParameter>();
                string where = BuildAudienceFilter(audience, ps);

                object o = DBHelper.ExecuteScalar(
                    "SELECT COUNT(*) FROM Users u" + where, ps.ToArray());

                return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
            }
            catch (Exception ex)
            {
                LogError("CountAudience", ex);
                return 0;
            }
        }

        /// <summary>
        /// How many of an audience have no city on record — surfaced next to
        /// the recipient count so "including 24 users with no city set" is
        /// visible before the admin commits, not a silent behaviour.
        /// </summary>
        public static int CountUnknownCity(BroadcastAudience audience)
        {
            try
            {
                // Same audience minus the city clause, then counted for blanks.
                BroadcastAudience roleOnly = new BroadcastAudience
                {
                    Roles = audience.Roles,
                    City = null,
                    IncludeUnknownCity = true
                };

                List<SqlParameter> ps = new List<SqlParameter>();
                string where = BuildAudienceFilter(roleOnly, ps);

                object o = DBHelper.ExecuteScalar(
                    "SELECT COUNT(*) FROM Users u" + where +
                    " AND (u.City IS NULL OR LTRIM(RTRIM(u.City)) = '')", ps.ToArray());

                return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
            }
            catch (Exception ex)
            {
                LogError("CountUnknownCity", ex);
                return 0;
            }
        }

        /// <summary>
        /// Fan one message out to a whole audience. Returns the number of
        /// people reached (0 on failure — this never throws, same contract as
        /// Notify).
        ///
        /// Unlike NotifyMany, which loops Notify() and therefore costs two
        /// round trips per recipient, the in-app half is a single
        /// INSERT..SELECT. A broadcast is the one notification path where the
        /// recipient list is genuinely large, and 2N round trips for a few
        /// hundred users is the difference between an instant postback and a
        /// visibly hanging one.
        ///
        /// SCALING LIMIT — email is still one message per recipient, sent
        /// synchronously on the admin's request thread, with SendEmail's 15s
        /// timeout each. With SMTP switched on, a broadcast to a few hundred
        /// unreachable addresses could exceed the request timeout. That is
        /// acceptable at this project's scale and is what the roadmap chose
        /// deliberately, but it is the reason the admin page shows the
        /// recipient count and warns before sending rather than just firing.
        /// A real fix is a queue plus a worker, which this app has no host for.
        /// </summary>
        public static int NotifyBroadcast(BroadcastAudience audience, string subject,
                                          string message, string type,
                                          string eventKey = null, string linkUrl = null)
        {
            try
            {
                List<SqlParameter> countParams = new List<SqlParameter>();
                string where = BuildAudienceFilter(audience, countParams);

                int reached = CountAudience(audience);
                if (reached == 0) return 0;

                // --- In-app, in one statement -----------------------------
                // The LEFT JOIN mirrors Notify()'s per-user preference check:
                // no preference row means opted in, so only real opt-outs are
                // excluded. A null event key is mandatory and skips the check
                // entirely.
                List<SqlParameter> insertParams = new List<SqlParameter>();
                foreach (SqlParameter p in countParams)
                    insertParams.Add(new SqlParameter(p.ParameterName, p.Value));

                insertParams.Add(new SqlParameter("@Message", Truncate(message, 500)));
                insertParams.Add(new SqlParameter("@Type", type ?? NotifyType.System));
                insertParams.Add(new SqlParameter("@LinkUrl", (object)linkUrl ?? DBNull.Value));
                insertParams.Add(new SqlParameter("@EventKey", (object)eventKey ?? DBNull.Value));

                string prefClause = eventKey == null
                    ? ""
                    : " AND ISNULL(p.InAppEnabled, 1) = 1";

                DBHelper.ExecuteNonQuery(
                    @"INSERT INTO Notifications (UserID, Message, [Type], LinkUrl)
                      SELECT u.UserID, @Message, @Type, @LinkUrl
                        FROM Users u
                        LEFT JOIN NotificationPreferences p
                               ON p.UserID = u.UserID AND p.EventKey = @EventKey"
                    + where + prefClause,
                    insertParams.ToArray());

                // --- Email, one at a time ---------------------------------
                // Skipped entirely when SMTP is off, which is the shipped
                // default, so the loop below normally does not run at all.
                if (SmtpConfigured)
                {
                    List<SqlParameter> mailParams = new List<SqlParameter>();
                    foreach (SqlParameter p in countParams)
                        mailParams.Add(new SqlParameter(p.ParameterName, p.Value));
                    mailParams.Add(new SqlParameter("@EventKey", (object)eventKey ?? DBNull.Value));

                    string emailPref = eventKey == null
                        ? ""
                        : " AND ISNULL(p.EmailEnabled, 1) = 1";

                    DataTable recipients = DBHelper.ExecuteQuery(
                        @"SELECT u.Email, u.FullName
                            FROM Users u
                            LEFT JOIN NotificationPreferences p
                                   ON p.UserID = u.UserID AND p.EventKey = @EventKey"
                        + where + emailPref +
                        " AND u.Email IS NOT NULL AND LTRIM(RTRIM(u.Email)) <> ''",
                        mailParams.ToArray());

                    foreach (DataRow r in recipients.Rows)
                    {
                        SendEmail(Convert.ToString(r["Email"]), subject,
                                  BuildHtmlBody(Convert.ToString(r["FullName"]),
                                                subject, message, linkUrl));
                    }
                }

                return reached;
            }
            catch (Exception ex)
            {
                LogError("NotifyBroadcast(event=" + eventKey + ")", ex);
                return 0;
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
        /// Same template, but with the caller's real subject and body — used by
        /// Phase 6a's "Preview Broadcast", where the point is to see the actual
        /// text before it goes to everyone rather than a sample.
        /// </summary>
        public static string PreviewHtml(string fullName, string subject,
                                         string message, string linkUrl = null)
        {
            return BuildHtmlBody(fullName, subject, message, linkUrl);
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

            string baseUrl = CurrentBaseUrl();
            if (string.IsNullOrWhiteSpace(baseUrl)) return appRelative;
            if (!baseUrl.EndsWith("/")) baseUrl += "/";

            return baseUrl + appRelative.TrimStart('~', '/');
        }

        /// <summary>
        /// Where the site is actually being served from right now.
        ///
        /// The live request is preferred over the App.BaseUrl setting because
        /// the setting goes stale the moment the site moves — and a stale value
        /// is silent: every link in every notification email points at whatever
        /// it still says (e.g. someone's localhost) and 404s for the recipient,
        /// while the app itself looks perfectly healthy. A request cannot be
        /// wrong about its own address.
        ///
        /// App.BaseUrl stays as the fallback for notifications raised without a
        /// request context, such as from a background thread.
        /// </summary>
        private static string CurrentBaseUrl()
        {
            try
            {
                HttpContext ctx = HttpContext.Current;
                if (ctx != null && ctx.Request != null)
                {
                    HttpRequest req = ctx.Request;

                    // Behind a proxy the scheme IIS sees is http even when the
                    // browser is on https. Taking the forwarded header first
                    // stops email links from pointing at http, which would cost
                    // the recipient a redirect on every click.
                    string scheme = req.Headers["X-Forwarded-Proto"];
                    if (string.IsNullOrWhiteSpace(scheme))
                        scheme = req.IsSecureConnection ? "https" : "http";

                    // "/" when the app is at the site root, "/sub" when it is in
                    // a virtual directory — dropping it would break the latter.
                    string appPath = req.ApplicationPath;
                    if (string.IsNullOrEmpty(appPath)) appPath = "/";
                    if (!appPath.EndsWith("/")) appPath += "/";

                    return scheme.Trim() + "://" + req.Url.Authority + appPath;
                }
            }
            catch
            {
                // Fall through to the configured value — this is a best-effort
                // convenience and must never break sending a notification.
            }

            return AppSetting("App.BaseUrl", "");
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
        /// <summary>
        /// Lets other fail-soft services (Phase 6b's FraudDetectionService)
        /// write to the same log file. One place to look when something quietly
        /// did not happen is worth more than a log per service.
        /// </summary>
        public static void LogExternalError(string context, Exception ex)
        {
            LogError(context, ex);
        }

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
