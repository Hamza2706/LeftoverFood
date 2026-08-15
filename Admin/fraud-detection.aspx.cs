using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    /// <summary>
    /// Fraud review queue (Phase 6b).
    ///
    /// The rules themselves live in FraudDetectionService — unlike Phase 6c,
    /// a service is justified here because there are four call sites
    /// (donate-form, donor-dashboard, ngo-active-requests and this page's
    /// manual scan), which is the same reasoning that produced
    /// NotificationService in Phase 4.
    ///
    /// This page only reads flags and closes them.
    /// </summary>
    public partial class fraud_detection : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            if (!IsPostBack)
                BindAll();
        }

        private void BindAll()
        {
            BindStats();
            BindFlags();
            BindDonationLog();
        }

        // ------------------------------------------------------------------
        // Binding
        // ------------------------------------------------------------------

        private void BindStats()
        {
            int open = FraudDetectionService.OpenFlagCount();

            litOpenCount.Text = open.ToString();

            litFlaggedUsers.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(DISTINCT UserID) FROM FraudFlags WHERE Status = 'Open' AND UserID IS NOT NULL")
                .ToString();

            // "Clean" is deliberately every active account without an open
            // flag, not the mockup's invented 318. It moves as accounts and
            // flags change, which is the point.
            litCleanCount.Text = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM Users u
                   WHERE u.IsActive = 1
                     AND NOT EXISTS (SELECT 1 FROM FraudFlags f
                                      WHERE f.UserID = u.UserID AND f.Status = 'Open')")
                .ToString();

            litSuspendedCount.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE IsActive = 0").ToString();

            litScanHeadline.Text = open == 0
                ? "No open flags."
                : open + (open == 1 ? " open flag needs review" : " open flags need review");
        }

        private void BindFlags()
        {
            string filter = ddlFlagFilter.SelectedValue == "all"
                ? ""
                : " WHERE f.Status = @Status";

            SqlParameter[] ps = ddlFlagFilter.SelectedValue == "all"
                ? new SqlParameter[0]
                : new SqlParameter[] { new SqlParameter("@Status", ddlFlagFilter.SelectedValue) };

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT f.FlagID, f.UserID, f.DonationID, f.FlagType, f.Details, f.Status,
                         f.FlaggedAt, f.ReviewedAt,
                         ISNULL(u.FullName, '(account removed)') AS SubjectName,
                         ISNULL(u.Role, '—') AS SubjectRole,
                         ISNULL(u.IsActive, 1) AS SubjectActive,
                         d.FoodDescription AS DonationFood,
                         rev.FullName AS ReviewedByName
                    FROM FraudFlags f
                    LEFT JOIN Users u ON u.UserID = f.UserID
                    LEFT JOIN FoodDonations d ON d.DonationID = f.DonationID
                    LEFT JOIN Users rev ON rev.UserID = f.ReviewedBy"
                + filter +
                " ORDER BY f.FlaggedAt DESC", ps);

            rptFlags.DataSource = dt;
            rptFlags.DataBind();

            pnlNoFlags.Visible = dt.Rows.Count == 0;
            litNoFlags.Text = ddlFlagFilter.SelectedValue == "Open"
                ? "No open flags. Nothing in the data currently matches any of the five rules."
                : "No flags with that status.";
        }

        /// <summary>
        /// Claimed vs received for every confirmed delivery.
        ///
        /// Shown whether or not it tripped the rule: the threshold is one
        /// judgement call, and an admin looking for a pattern should be able to
        /// see the near-misses too rather than only what the rule already
        /// decided was suspicious.
        /// </summary>
        private void BindDonationLog()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 25 d.DonationID, d.FoodDescription, d.Quantity, d.Servings, d.GeoPrecision,
                         r.ActualQuantityReceived, u.FullName AS DonorName
                    FROM FoodRequests r
                    JOIN FoodDonations d ON d.DonationID = r.DonationID
                    JOIN Users u ON u.UserID = d.DonorID
                   WHERE r.Status = 'Accepted' AND r.ActualQuantityReceived IS NOT NULL
                   ORDER BY d.DonationID DESC");

            rptDonationLog.DataSource = dt;
            rptDonationLog.DataBind();
            pnlNoLog.Visible = dt.Rows.Count == 0;
        }

        // ------------------------------------------------------------------
        // Actions
        // ------------------------------------------------------------------

        protected void ddlFlagFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindFlags();
        }

        protected void btnRunScan_Click(object sender, EventArgs e)
        {
            int raised = FraudDetectionService.RunFullScan();

            ShowMessage(raised > 0
                ? "Scan complete — " + raised + (raised == 1 ? " new flag" : " new flags") + " raised."
                : "Scan complete. Nothing new was flagged.",
                raised > 0 ? "alert-warning" : "alert-success");

            BindAll();
        }

        protected void rptFlags_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int flagId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out flagId)) return;

            int adminId = SessionHelper.GetUserID();

            if (e.CommandName == "Dismiss")
            {
                FraudDetectionService.Resolve(flagId, FlagStatus.Dismissed, adminId);
                ShowMessage("Flag dismissed. If the same pattern happens again it will raise a fresh flag.", "alert-success");
            }
            else if (e.CommandName == "Reviewed")
            {
                FraudDetectionService.Resolve(flagId, FlagStatus.Reviewed, adminId);
                ShowMessage("Flag marked as reviewed.", "alert-success");
            }
            else if (e.CommandName == "Suspend")
            {
                SuspendSubject(flagId, adminId);
            }

            BindAll();
        }

        /// <summary>
        /// Suspends the account a flag is about, reusing the same
        /// Users.IsActive switch Phase 1's Ban/Unban uses — login already
        /// checks it, so there is no second notion of "blocked" to keep in
        /// step. The flag is closed as Reviewed in the same action, since
        /// acting on it is the strongest possible form of having reviewed it.
        /// </summary>
        private void SuspendSubject(int flagId, int adminId)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT f.UserID, u.FullName, u.IsActive
                    FROM FraudFlags f
                    JOIN Users u ON u.UserID = f.UserID
                   WHERE f.FlagID = @FlagID",
                new SqlParameter[] { new SqlParameter("@FlagID", flagId) });

            if (dt.Rows.Count == 0)
            {
                ShowMessage("That flag isn't about an account, so there is nothing to suspend.", "alert-warning");
                return;
            }

            int subjectId = Convert.ToInt32(dt.Rows[0]["UserID"]);

            // Same self-protection Phase 1 put on Ban: an admin cannot lock
            // themselves out through this page either.
            if (subjectId == adminId)
            {
                ShowMessage("You can't suspend your own account.", "alert-danger");
                return;
            }

            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE Users SET IsActive = 0 WHERE UserID = @UserID AND IsActive = 1",
                new SqlParameter[] { new SqlParameter("@UserID", subjectId) });

            if (rows == 0)
            {
                ShowMessage("That account was already suspended.", "alert-warning");
                return;
            }

            FraudDetectionService.Resolve(flagId, FlagStatus.Reviewed, adminId);

            // Mandatory notification (null event key) — being suspended is not
            // something a user may opt out of hearing about, the same call
            // Phase 4 made for account status changes.
            NotificationService.Notify(subjectId,
                "Your account has been suspended",
                "An administrator has suspended your FoodBridge account following a review of "
                + "automated fraud checks. You will not be able to sign in until it is reinstated. "
                + "Contact the FoodBridge team if you believe this is a mistake.",
                NotifyType.System, null, null);

            ShowMessage(Convert.ToString(dt.Rows[0]["FullName"])
                        + " has been suspended and the flag marked reviewed. "
                        + "Unban from the admin dashboard if this was wrong.", "alert-success");
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
        /// Row tint by how much the rule actually implies. Quantity mismatch
        /// and repeat cancellation describe behaviour with a victim; duplicate
        /// posting and a failed geocode are usually an accident, so they get
        /// the softer tint rather than red.
        /// </summary>
        protected string RiskClass(object flagType)
        {
            switch (Convert.ToString(flagType))
            {
                case FlagType.QuantityMismatch:
                case FlagType.RepeatedCancel: return "risk-high";
                default: return "risk-med";
            }
        }

        protected string BadgeTone(object flagType)
        {
            return RiskClass(flagType) == "risk-high" ? "" : "amber";
        }

        protected string RoleBadgeClass(object role)
        {
            switch (Convert.ToString(role))
            {
                case "NGO": return "badge-role-ngo";
                case "Volunteer": return "badge-role-vol";
                case "Admin": return "badge-role-admin";
                case "Donor": return "badge-role-donor";
                default: return "badge-pending";
            }
        }

        protected string SuspendedBadge(object isActive)
        {
            if (isActive == null || isActive == DBNull.Value) return "";
            return Convert.ToBoolean(isActive)
                ? ""
                : "<span class=\"badge-status badge-rejected ms-1\">Suspended</span>";
        }

        protected string FlaggedAgo(object flaggedAt)
        {
            DateTime dt;
            if (!DateTime.TryParse(Convert.ToString(flaggedAt), out dt)) return "";

            TimeSpan span = DateTime.Now - dt;

            if (span.TotalMinutes < 60) return "Flagged " + (int)span.TotalMinutes + " min ago";
            if (span.TotalHours < 24) return "Flagged " + (int)span.TotalHours + "h ago";
            if (span.TotalDays < 7) return "Flagged " + (int)span.TotalDays + "d ago";

            return "Flagged " + dt.ToString("d MMM yyyy");
        }

        protected string ReviewedNote(object status, object reviewedAt, object reviewedByName)
        {
            string s = Convert.ToString(status);
            if (s == "Open") return "";

            string who = Convert.ToString(reviewedByName);
            DateTime dt;
            string when = DateTime.TryParse(Convert.ToString(reviewedAt), out dt)
                ? dt.ToString("d MMM yyyy")
                : "";

            return " · " + s.ToLower()
                 + (string.IsNullOrWhiteSpace(who) ? "" : " by " + Server.HtmlEncode(who))
                 + (when.Length == 0 ? "" : " on " + when);
        }

        protected string ServingsText(object servings)
        {
            if (servings == null || servings == DBNull.Value) return "no serving count";
            return Convert.ToInt32(servings) + " servings";
        }

        /// <summary>
        /// Reuses Phase 5's precision labelling rather than inventing a second
        /// vocabulary for the same column.
        /// </summary>
        protected string GeoBadge(object geoPrecision)
        {
            switch (Convert.ToString(geoPrecision))
            {
                case "Exact": return "<span class=\"badge-status badge-accepted\">Exact</span>";
                case "City": return "<span class=\"badge-status badge-pending\">City only</span>";
                default: return "<span class=\"badge-status badge-rejected\">Not located</span>";
            }
        }

        /// <summary>
        /// The claimed-vs-received verdict, computed with the same parsing the
        /// rule uses so the table and the flag can never disagree.
        /// </summary>
        protected string MismatchBadge(object servings, object received)
        {
            if (servings == null || servings == DBNull.Value)
                return "<span class=\"note-inline\">no claim to compare</span>";

            int claimed = Convert.ToInt32(servings);
            int? got = FraudDetectionService.LeadingNumber(Convert.ToString(received));

            if (claimed <= 0 || got == null)
                return "<span class=\"note-inline\">not comparable</span>";

            if (got.Value < claimed * 0.5)
                return "<span class=\"badge-status badge-rejected\">Under half</span>";

            if (got.Value < claimed * 0.9)
                return "<span class=\"badge-status badge-pending\">Short</span>";

            return "<span class=\"badge-status badge-accepted\">Matches</span>";
        }

        protected string Truncate(object text, int max)
        {
            string s = Convert.ToString(text);
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length <= max ? s : s.Substring(0, max - 1) + "…";
        }
    }
}
