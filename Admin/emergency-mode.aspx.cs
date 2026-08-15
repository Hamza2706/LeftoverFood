using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    /// <summary>
    /// Emergency Mode (Phase 6a).
    ///
    /// Three things happen here: declaring an emergency (which writes an
    /// EmergencyBroadcasts row and fans a notification out to a targeted
    /// audience), flagging individual donations as priority, and sending a
    /// plain broadcast without declaring anything.
    ///
    /// Inline queries over DBHelper, per the codebase's established style. The
    /// one piece that did move into a service is the fan-out itself
    /// (NotificationService.NotifyBroadcast) — it belongs next to Notify() and
    /// has to share the preference and SMTP handling with it.
    /// </summary>
    public partial class emergency_mode : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            if (!IsPostBack)
            {
                txtStartAt.Text = DateTime.Now.ToString("yyyy-MM-ddTHH:mm");
                txtMessage.Text = DefaultMessage;
                BindAll();
            }
        }

        private const string DefaultMessage =
            "EMERGENCY ALERT: FoodBridge has activated Emergency Mode. Please check available "
            + "donations and respond as soon as you can. Your urgent response is needed.";

        private void BindAll()
        {
            BindStatus();
            BindAudiencePreview();
            BindPriorityQueue();
            BindHistory();
        }

        // ------------------------------------------------------------------
        // Status banner
        // ------------------------------------------------------------------

        /// <summary>
        /// The active emergency, or null. "Active" is a single row with
        /// IsActive = 1; activating a second one while another is running ends
        /// the first (see btnActivate_Click), so there is never more than one.
        /// </summary>
        private DataRow ActiveBroadcast()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 1 b.BroadcastID, b.EmergencyType, b.AffectedArea, b.StartDateTime,
                         b.ExpectedDuration, b.SendTo, b.RecipientCount, b.CreatedAt
                    FROM EmergencyBroadcasts b
                   WHERE b.IsActive = 1
                   ORDER BY b.CreatedAt DESC");

            return dt.Rows.Count == 0 ? null : dt.Rows[0];
        }

        private void BindStatus()
        {
            DataRow active = ActiveBroadcast();

            pnlActive.Visible = active != null;
            pnlInactive.Visible = active == null;

            if (active == null) return;

            string area = Convert.ToString(active["AffectedArea"]);
            int reached = active["RecipientCount"] == DBNull.Value
                ? 0 : Convert.ToInt32(active["RecipientCount"]);

            litActiveSummary.Text =
                Server.HtmlEncode(Convert.ToString(active["EmergencyType"]))
                + (string.IsNullOrWhiteSpace(area) ? " — all cities" : " — " + Server.HtmlEncode(area))
                + ". Started " + Convert.ToDateTime(active["StartDateTime"]).ToString("d MMM yyyy, h:mm tt")
                + ". Notified " + reached + (reached == 1 ? " person" : " people")
                + ". Expected duration: " + Server.HtmlEncode(Convert.ToString(active["ExpectedDuration"])) + ".";
        }

        // ------------------------------------------------------------------
        // Audience preview
        // ------------------------------------------------------------------

        /// <summary>Roles targeted by an audience keyword.</summary>
        private static string[] RolesFor(string sendTo)
        {
            switch (sendTo)
            {
                case "NGOs": return new[] { "NGO" };
                case "Volunteers": return new[] { "Volunteer" };
                case "Donors": return new[] { "Donor" };
                case "All": return new[] { "NGO", "Volunteer", "Donor" };
                default: return new[] { "NGO", "Volunteer" };   // "Both"
            }
        }

        private NotificationService.BroadcastAudience CurrentAudience()
        {
            return new NotificationService.BroadcastAudience
            {
                Roles = RolesFor(ddlAudience.SelectedValue),
                City = ddlCity.SelectedValue,
                IncludeUnknownCity = chkIncludeUnknownCity.Checked
            };
        }

        /// <summary>
        /// Shows how many people the current settings would actually reach,
        /// live, before anything is sent.
        ///
        /// This exists because of a real property of the data rather than as
        /// decoration: Users.City is mostly unset (24 of 28 accounts had no city
        /// when this was built), so a city-targeted broadcast can silently
        /// resolve to almost nobody. The count makes that visible, and the
        /// include-unknown-city checkbox makes it fixable.
        /// </summary>
        private void BindAudiencePreview()
        {
            NotificationService.BroadcastAudience audience = CurrentAudience();

            int total = NotificationService.CountAudience(audience);
            bool cityChosen = !string.IsNullOrWhiteSpace(ddlCity.SelectedValue);

            pnlUnknownCity.Visible = cityChosen;

            if (cityChosen)
            {
                int unknown = NotificationService.CountUnknownCity(audience);
                litUnknownCityNote.Text = unknown == 0
                    ? "Everyone in this audience has a city on record."
                    : Server.HtmlEncode(unknown + (unknown == 1 ? " user has" : " users have")
                        + " no city set. Leaving this unticked excludes them from a "
                        + ddlCity.SelectedValue + " alert.");
            }

            litRecipientCount.Text = total == 0
                ? "<strong>This would reach nobody.</strong> No active, verified users match — check the city and audience."
                : "This will notify <strong>" + total + "</strong> " + (total == 1 ? "person" : "people")
                  + " (active, verified accounts only).";

            // The synchronous email loop is the known scaling limit; say so at
            // the point where it would actually bite rather than only in docs.
            litSmtpWarning.Text = NotificationService.SmtpConfigured && total > 25
                ? "<div class=\"note-inline mt-1\" style=\"color:var(--amber)\"><i class=\"bi bi-clock-history me-1\"></i>"
                  + "SMTP is on and emails send one at a time on this request — with " + total
                  + " recipients this page may take a while to respond.</div>"
                : "";
        }

        protected void Audience_Changed(object sender, EventArgs e)
        {
            BindAudiencePreview();
        }

        // ------------------------------------------------------------------
        // Activate / deactivate
        // ------------------------------------------------------------------

        protected void btnActivate_Click(object sender, EventArgs e)
        {
            string type = ddlEmergencyType.SelectedValue;
            string message = (txtMessage.Text ?? "").Trim();

            if (string.IsNullOrWhiteSpace(type))
            {
                ShowMessage("Choose an emergency type first.", "alert-danger");
                return;
            }

            if (string.IsNullOrWhiteSpace(message))
            {
                ShowMessage("The broadcast message can't be empty — this is what recipients will read.", "alert-danger");
                return;
            }

            // MaxLength on the markup is a client-side hint only and is not
            // enforced at all for a multiline TextBox, so the column widths
            // (Message and PriorityAreas are both NVARCHAR(1000)) have to be
            // checked here or an over-long paste becomes a SQL truncation
            // error in the admin's face.
            if (message.Length > 1000)
            {
                ShowMessage("The broadcast message is " + message.Length
                            + " characters — please keep it under 1000.", "alert-danger");
                return;
            }

            if ((txtPriorityAreas.Text ?? "").Trim().Length > 1000)
            {
                ShowMessage("Priority areas must be under 1000 characters.", "alert-danger");
                return;
            }

            DateTime startAt;
            if (!DateTime.TryParse(txtStartAt.Text, out startAt))
            {
                ShowMessage("Enter a valid start date and time.", "alert-danger");
                return;
            }

            NotificationService.BroadcastAudience audience = CurrentAudience();
            int expected = NotificationService.CountAudience(audience);

            if (expected == 0)
            {
                // Declaring an emergency nobody hears about is almost certainly
                // a mistake in the city/audience selection, so refuse rather
                // than record an empty broadcast.
                ShowMessage("This would reach nobody, so nothing was sent. Widen the city or audience and try again.", "alert-danger");
                BindAll();
                return;
            }

            string city = ddlCity.SelectedValue;
            string areas = (txtPriorityAreas.Text ?? "").Trim();

            // Only one emergency runs at a time — declaring a new one closes
            // whatever was already running, so the banner and the "active"
            // lookup never have to choose between two.
            DBHelper.ExecuteNonQuery(
                "UPDATE EmergencyBroadcasts SET IsActive = 0, EndedAt = GETDATE() WHERE IsActive = 1");

            object newId = DBHelper.ExecuteScalar(
                @"INSERT INTO EmergencyBroadcasts
                      (EmergencyType, AffectedArea, StartDateTime, ExpectedDuration,
                       PriorityAreas, Message, SendTo, IsActive, CreatedBy)
                  OUTPUT INSERTED.BroadcastID
                  VALUES (@Type, @Area, @Start, @Duration, @Areas, @Message, @SendTo, 1, @CreatedBy)",
                new SqlParameter[]
                {
                    new SqlParameter("@Type", type),
                    new SqlParameter("@Area", string.IsNullOrWhiteSpace(city) ? (object)DBNull.Value : city),
                    new SqlParameter("@Start", startAt),
                    new SqlParameter("@Duration", ddlDuration.SelectedValue),
                    new SqlParameter("@Areas", areas.Length == 0 ? (object)DBNull.Value : areas),
                    new SqlParameter("@Message", message),
                    new SqlParameter("@SendTo", ddlAudience.SelectedValue),
                    new SqlParameter("@CreatedBy", SessionHelper.GetUserID())
                });

            int broadcastId = Convert.ToInt32(newId);

            int reached = NotificationService.NotifyBroadcast(
                audience,
                "Emergency: " + type,
                BroadcastBody(type, city, areas, message),
                NotifyType.Emergency,
                NotifyEvent.EmergencyAlert,
                "~/Notifications.aspx");

            // Recorded from what the send actually reported, not from the
            // pre-send estimate, so the history can't overstate reach.
            DBHelper.ExecuteNonQuery(
                "UPDATE EmergencyBroadcasts SET RecipientCount = @Count WHERE BroadcastID = @ID",
                new SqlParameter[]
                {
                    new SqlParameter("@Count", reached),
                    new SqlParameter("@ID", broadcastId)
                });

            ShowMessage(reached > 0
                ? "Emergency mode activated. " + reached + (reached == 1 ? " person" : " people") + " notified."
                : "Emergency mode activated, but the broadcast reached nobody — check ~/App_Data/notification-errors.log.",
                reached > 0 ? "alert-success" : "alert-warning");

            pnlPreview.Visible = false;
            BindAll();
        }

        protected void btnDeactivate_Click(object sender, EventArgs e)
        {
            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE EmergencyBroadcasts SET IsActive = 0, EndedAt = GETDATE() WHERE IsActive = 1");

            // Deliberately silent: no "all clear" notification is sent. Doing so
            // would mean a second fan-out to everyone, and an all-clear that
            // arrives without the app having any way to confirm the emergency
            // really passed is worse than no message. Priority flags on
            // donations are also left alone — an admin set those by hand and
            // they stay until unset by hand.
            ShowMessage(rows > 0 ? "Emergency mode deactivated." : "There was no active emergency.",
                        rows > 0 ? "alert-success" : "alert-warning");

            BindAll();
        }

        protected void btnPreview_Click(object sender, EventArgs e)
        {
            string message = (txtMessage.Text ?? "").Trim();
            if (string.IsNullOrWhiteSpace(message))
            {
                ShowMessage("Write a message first, then preview it.", "alert-danger");
                return;
            }

            string type = string.IsNullOrWhiteSpace(ddlEmergencyType.SelectedValue)
                ? "Emergency" : ddlEmergencyType.SelectedValue;

            litPreview.Text = NotificationService.PreviewHtml(
                SessionHelper.GetFullName(),
                "Emergency: " + type,
                BroadcastBody(type, ddlCity.SelectedValue, (txtPriorityAreas.Text ?? "").Trim(), message),
                "~/Notifications.aspx");

            pnlPreview.Visible = true;
            BindAudiencePreview();
        }

        protected void btnRamadanPreset_Click(object sender, EventArgs e)
        {
            ddlEmergencyType.SelectedValue = "Ramadan — High Demand Period";
            ddlDuration.SelectedValue = "30 Days (Ramadan)";
            txtStartAt.Text = DateTime.Now.ToString("yyyy-MM-ddTHH:mm");
            txtMessage.Text =
                "Ramadan has begun and demand for Iftar and Sehri meals is at its highest. "
                + "Please check available donations regularly and respond quickly — food posted "
                + "close to Iftar has very little time before it expires.";

            ShowMessage("Ramadan preset loaded. Review the form and press Activate when you're ready.", "alert-success");
            BindAll();
        }

        /// <summary>
        /// The body recipients actually read. Priority areas are folded in here
        /// because the column is stored for the record but nothing filters on
        /// it — putting it in the text is the only way it reaches anyone.
        /// </summary>
        private static string BroadcastBody(string type, string city, string areas, string message)
        {
            string body = message;

            if (!string.IsNullOrWhiteSpace(city))
                body += " Affected area: " + city + ".";

            if (!string.IsNullOrWhiteSpace(areas))
                body += " Priority locations: " + areas + ".";

            return body;
        }

        // ------------------------------------------------------------------
        // Quick broadcast
        // ------------------------------------------------------------------

        protected void btnQuickSend_Click(object sender, EventArgs e)
        {
            string message = (txtQuickMessage.Text ?? "").Trim();

            if (string.IsNullOrWhiteSpace(message))
            {
                ShowMessage("Type a message to broadcast.", "alert-danger");
                return;
            }

            if (message.Length > 1000)
            {
                ShowMessage("The message is " + message.Length
                            + " characters — please keep it under 1000.", "alert-danger");
                return;
            }

            NotificationService.BroadcastAudience audience = new NotificationService.BroadcastAudience
            {
                Roles = RolesFor(ddlQuickAudience.SelectedValue),
                City = null,                 // quick broadcasts are not area-targeted
                IncludeUnknownCity = true
            };

            int reached = NotificationService.NotifyBroadcast(
                audience, "FoodBridge broadcast", message,
                NotifyType.System, NotifyEvent.EmergencyAlert, "~/Notifications.aspx");

            // Recorded even though it declares no emergency: a message sent to
            // every NGO in the system is exactly the kind of action that should
            // leave a trail. IsActive = 0 keeps it out of the status banner.
            DBHelper.ExecuteNonQuery(
                @"INSERT INTO EmergencyBroadcasts
                      (EmergencyType, AffectedArea, StartDateTime, ExpectedDuration,
                       PriorityAreas, Message, SendTo, IsActive, CreatedBy, RecipientCount, EndedAt)
                  VALUES ('Quick Broadcast', NULL, GETDATE(), 'One-off message',
                          NULL, @Message, @SendTo, 0, @CreatedBy, @Count, GETDATE())",
                new SqlParameter[]
                {
                    new SqlParameter("@Message", message),
                    new SqlParameter("@SendTo", ddlQuickAudience.SelectedValue),
                    new SqlParameter("@CreatedBy", SessionHelper.GetUserID()),
                    new SqlParameter("@Count", reached)
                });

            ShowMessage(reached > 0
                ? "Broadcast sent to " + reached + (reached == 1 ? " person." : " people.")
                : "Nobody matched that audience, so nothing was sent.",
                reached > 0 ? "alert-success" : "alert-warning");

            if (reached > 0) txtQuickMessage.Text = "";
            BindAll();
        }

        // ------------------------------------------------------------------
        // Priority queue
        // ------------------------------------------------------------------

        private void BindPriorityQueue()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 25 d.DonationID, d.FoodDescription, d.Quantity, d.ExpiryTime,
                         d.Status, d.IsPriority, d.City, u.FullName AS DonorName
                    FROM FoodDonations d
                    JOIN Users u ON u.UserID = d.DonorID
                   WHERE d.Status IN ('Posted', 'Approved', 'Requested', 'Assigned')
                   ORDER BY d.IsPriority DESC, d.ExpiryTime ASC");

            rptPriority.DataSource = dt;
            rptPriority.DataBind();
            pnlNoPriority.Visible = dt.Rows.Count == 0;
        }

        protected void rptPriority_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "TogglePriority") return;

            int donationId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out donationId)) return;

            // Flip in one statement rather than read-then-write, so two admins
            // clicking at once can't both read "off" and both write "on".
            // Scoped to in-flight statuses so a stale page can't re-flag a
            // donation that has since been delivered or cancelled.
            int rows = DBHelper.ExecuteNonQuery(
                @"UPDATE FoodDonations
                     SET IsPriority = CASE WHEN IsPriority = 1 THEN 0 ELSE 1 END
                   WHERE DonationID = @ID
                     AND Status IN ('Posted', 'Approved', 'Requested', 'Assigned')",
                new SqlParameter[] { new SqlParameter("@ID", donationId) });

            if (rows == 0)
                ShowMessage("That donation is no longer in flight — the queue has been refreshed.", "alert-warning");

            BindPriorityQueue();
        }

        // ------------------------------------------------------------------
        // History
        // ------------------------------------------------------------------

        private void BindHistory()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 10 b.BroadcastID, b.EmergencyType, b.AffectedArea, b.StartDateTime,
                         b.EndedAt, b.IsActive, b.SendTo, b.RecipientCount,
                         u.FullName AS CreatedByName
                    FROM EmergencyBroadcasts b
                    LEFT JOIN Users u ON u.UserID = b.CreatedBy
                   ORDER BY b.CreatedAt DESC");

            rptHistory.DataSource = dt;
            rptHistory.DataBind();
            pnlNoHistory.Visible = dt.Rows.Count == 0;
        }

        private void ShowMessage(string text, string cssClass)
        {
            litMessage.Text = text;
            pnlMessage.CssClass = "alert mb-3 " + cssClass;
            pnlMessage.Visible = true;
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// The queue's leading badge. An admin flag wins; otherwise the badge
        /// reflects time left, which is the only urgency signal this data
        /// genuinely carries.
        /// </summary>
        protected string PriorityBadge(object isPriority, object expiryTime)
        {
            if (Convert.ToBoolean(isPriority))
                return "<span style=\"background:#fee2e2;color:#dc2626;border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700\">🔴 FLAGGED</span>";

            TimeSpan? left = TimeLeft(expiryTime);

            if (left == null)
                return "<span class=\"note-inline\">—</span>";

            if (left.Value.TotalHours < 2)
                return "<span style=\"background:#fee2e2;color:#dc2626;border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700\">🔴 URGENT</span>";

            if (left.Value.TotalHours < 6)
                return "<span style=\"background:#fff3e0;color:var(--amber);border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700\">🟡 HIGH</span>";

            return "<span style=\"background:#e8f5ee;color:var(--green);border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700\">🟢 NORMAL</span>";
        }

        private static TimeSpan? TimeLeft(object expiryTime)
        {
            DateTime expiry;
            if (expiryTime == null || expiryTime == DBNull.Value
                || !DateTime.TryParse(Convert.ToString(expiryTime), out expiry))
                return null;

            return expiry - DateTime.Now;
        }

        protected string ExpiresIn(object expiryTime)
        {
            TimeSpan? left = TimeLeft(expiryTime);
            if (left == null) return "<span class=\"note-inline\">unknown</span>";

            if (left.Value.TotalSeconds <= 0)
                return "<strong style=\"color:#dc2626\">expired</strong>";

            string colour = left.Value.TotalHours < 2 ? "#dc2626"
                          : left.Value.TotalHours < 6 ? "var(--amber)" : "var(--green)";

            string text = left.Value.TotalHours < 1
                ? (int)left.Value.TotalMinutes + " mins"
                : left.Value.TotalHours < 24
                    ? (int)left.Value.TotalHours + "h " + left.Value.Minutes + "m"
                    : (int)left.Value.TotalDays + "d";

            return "<strong style=\"color:" + colour + "\">" + text + "</strong>";
        }

        protected string StatusBadgeClass(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted": return "badge-pending";
                case "Approved": return "badge-accepted";
                case "Requested":
                case "Assigned": return "badge-delivered";
                default: return "badge-pending";
            }
        }

        protected string Truncate(object text, int max)
        {
            string s = Convert.ToString(text);
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length <= max ? s : s.Substring(0, max - 1) + "…";
        }

        /// <summary>"10 Apr – 11 Apr 2026", or "since 10 Apr 2026" while running.</summary>
        protected string DateRange(object startAt, object endedAt, object isActive)
        {
            DateTime start;
            if (!DateTime.TryParse(Convert.ToString(startAt), out start)) return "";

            if (Convert.ToBoolean(isActive))
                return "Since " + start.ToString("d MMM yyyy");

            DateTime ended;
            if (endedAt == null || endedAt == DBNull.Value
                || !DateTime.TryParse(Convert.ToString(endedAt), out ended))
                return start.ToString("d MMM yyyy");

            return start.ToString("d MMM") + " – " + ended.ToString("d MMM yyyy");
        }

        protected string AreaSuffix(object affectedArea)
        {
            string area = Convert.ToString(affectedArea);
            return string.IsNullOrWhiteSpace(area)
                ? "<span class=\"note-inline\">— all cities</span>"
                : "<span class=\"note-inline\">— " + Server.HtmlEncode(area) + "</span>";
        }

        protected string RecipientText(object recipientCount)
        {
            if (recipientCount == null || recipientCount == DBNull.Value)
                return "recipients not recorded";

            int n = Convert.ToInt32(recipientCount);
            return n + (n == 1 ? " recipient" : " recipients");
        }
    }
}
