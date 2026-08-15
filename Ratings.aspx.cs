using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    /// <summary>
    /// Shared ratings and trust page for Donor, NGO and Volunteer (Phase 6c).
    ///
    /// Class name is RatingsPage rather than Ratings to avoid colliding with the
    /// Ratings table naming used in queries throughout, matching the same choice
    /// Phase 4 made for NotificationsPage.
    ///
    /// Queries are written inline over DBHelper rather than behind a
    /// RatingService, following Phase 1's reasoning: this page is the only
    /// consumer, so a service layer would be premature. The one thing that is
    /// genuinely shared — "who may rate whom on this donation" — is a single SQL
    /// constant reused by both the dropdown and the submit-time authorisation
    /// check, so the two can never drift apart.
    /// </summary>
    public partial class RatingsPage : System.Web.UI.Page
    {
        // ------------------------------------------------------------------
        // Who may rate whom
        // ------------------------------------------------------------------

        /// <summary>
        /// Every (donation, counterparty) pair the signed-in user may still
        /// rate.
        ///
        /// A completed delivery has up to three participants — the donor who
        /// posted it, the NGO that accepted it, and the volunteer who carried
        /// it. Each may rate the others once, which is the "and vice versa" the
        /// proposal asks for. The CTE lists participants per donation; joining
        /// it to itself on @Me is what enforces "you can only rate a delivery
        /// you were actually part of".
        ///
        /// UNION rather than UNION ALL: a donation with more than one delivery
        /// assignment row would otherwise offer the same volunteer twice.
        ///
        /// Callers append either an ORDER BY (to list) or an extra AND (to
        /// authorise one specific pair).
        /// </summary>
        private const string RateableSql = @"
            WITH Participants AS (
                SELECT d.DonationID, d.DonorID AS PartyID, 'Donor' AS PartyRole
                  FROM FoodDonations d
                 WHERE d.Status = 'Delivered'
                UNION
                SELECT d.DonationID, r.NGOID, 'NGO'
                  FROM FoodDonations d
                  JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                 WHERE d.Status = 'Delivered'
                UNION
                SELECT d.DonationID, a.VolunteerID, 'Volunteer'
                  FROM FoodDonations d
                  JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                 WHERE d.Status = 'Delivered' AND a.VolunteerID IS NOT NULL
            )
            SELECT p.DonationID, p.PartyID AS RateeID, p.PartyRole AS RateeRole,
                   u.FullName AS RateeName, d.FoodDescription
              FROM Participants p
              JOIN Participants me ON me.DonationID = p.DonationID AND me.PartyID = @Me
              JOIN Users u ON u.UserID = p.PartyID
              JOIN FoodDonations d ON d.DonationID = p.DonationID
             WHERE p.PartyID <> @Me
               AND NOT EXISTS (SELECT 1 FROM Ratings rt
                                WHERE rt.DonationID = p.DonationID
                                  AND rt.RaterID = @Me
                                  AND rt.RateeID = p.PartyID)";

        // ------------------------------------------------------------------
        // Profile state, computed on every load because the markup reads it
        // through <%= %> at render time (which runs after Page_Load, but also
        // after every postback — so this cannot be inside an !IsPostBack guard).
        // ------------------------------------------------------------------

        private decimal _average;
        private int _receivedCount;
        private int _completedCount;
        private int _openFlagCount;
        private string _tier = "New";

        protected string MyName { get { return SessionHelper.GetFullName(); } }
        protected string MyInitials { get { return SessionHelper.Initials(SessionHelper.GetFullName()); } }
        protected decimal AverageStars { get { return _average; } }
        protected int ReceivedCount { get { return _receivedCount; } }
        protected int CompletedCount { get { return _completedCount; } }
        protected int OpenFlagCount { get { return _openFlagCount; } }
        protected string TierName { get { return _tier; } }

        /// <summary>Average to one decimal, or an em dash when never rated.</summary>
        protected string AverageDisplay
        {
            get { return _receivedCount == 0 ? "—" : _average.ToString("0.0", CultureInfo.InvariantCulture); }
        }

        protected string RatingCountText
        {
            get
            {
                if (_receivedCount == 0) return "No ratings yet";
                return "Based on " + _receivedCount + (_receivedCount == 1 ? " rating" : " ratings");
            }
        }

        /// <summary>
        /// What the first stat tile counts, which differs per role — a donor
        /// posts donations, an NGO receives them, a volunteer delivers them.
        /// </summary>
        protected string CompletedLabel
        {
            get
            {
                switch (SessionHelper.GetRole())
                {
                    case "NGO": return "Received";
                    case "Volunteer": return "Deliveries";
                    default: return "Donations";
                }
            }
        }

        // ------------------------------------------------------------------
        // Page lifecycle
        // ------------------------------------------------------------------

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireLogin(this);

            // Not RequireRole — three of the four roles belong here. An Admin
            // never participates in a delivery, so has nobody to rate and
            // nobody to be rated by; aggregate trust reporting is Phase 6d.
            string role = SessionHelper.GetRole();
            if (role != "Donor" && role != "NGO" && role != "Volunteer")
            {
                Response.Redirect("~/Unauthorized.aspx");
                return;
            }

            LoadProfile();

            if (!IsPostBack)
            {
                BindRateable();
                BindReceived();
                BindGiven();
            }
        }

        // ------------------------------------------------------------------
        // Binding
        // ------------------------------------------------------------------

        /// <summary>
        /// Trust profile: average, counts and the star histogram. Reads the
        /// live AVG rather than the cached Users.TrustScore so the page can
        /// never show a stale number if a recompute was ever missed — the
        /// cached column exists for other features to read cheaply, not for
        /// this page.
        /// </summary>
        private void LoadProfile()
        {
            int me = SessionHelper.GetUserID();

            DataTable hist = DBHelper.ExecuteQuery(
                "SELECT Stars, COUNT(*) AS Cnt FROM Ratings WHERE RateeID = @Me GROUP BY Stars",
                MeParam(me));

            int[] counts = new int[6];   // index 1..5
            _receivedCount = 0;
            int starSum = 0;

            foreach (DataRow row in hist.Rows)
            {
                int stars = Convert.ToInt32(row["Stars"]);
                int count = Convert.ToInt32(row["Cnt"]);
                if (stars < 1 || stars > 5) continue;

                counts[stars] = count;
                _receivedCount += count;
                starSum += stars * count;
            }

            _average = _receivedCount == 0
                ? 0m
                : Math.Round((decimal)starSum / _receivedCount, 2);

            // Histogram rows, 5 down to 1, always all five so an unused star
            // level shows an empty bar rather than vanishing.
            DataTable bars = new DataTable();
            bars.Columns.Add("Stars", typeof(int));
            bars.Columns.Add("Count", typeof(int));
            bars.Columns.Add("Percent", typeof(int));

            for (int s = 5; s >= 1; s--)
            {
                int pct = _receivedCount == 0 ? 0 : (int)Math.Round(counts[s] * 100.0 / _receivedCount);
                bars.Rows.Add(s, counts[s], pct);
            }

            rptHistogram.DataSource = bars;
            rptHistogram.DataBind();

            pnlBreakdown.Visible = _receivedCount > 0;
            pnlNoReceived.Visible = _receivedCount == 0;

            _completedCount = CountCompleted(me);

            // Open fraud flags against this user (Phase 6b). A real query
            // rather than a hardcoded zero, so the tile reflects the review
            // queue as soon as anything is flagged.
            _openFlagCount = Convert.ToInt32(DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FraudFlags WHERE UserID = @Me AND Status = 'Open'", MeParam(me)));

            _tier = ComputeTier();
        }

        /// <summary>
        /// A fresh @Me parameter per call.
        ///
        /// Not a shared array: ADO.NET binds a SqlParameter instance to the
        /// SqlCommand it is added to, so reusing one across two DBHelper calls
        /// throws "The SqlParameter is already contained by another
        /// SqlParameterCollection" on the second. Every helper here builds new
        /// instances for exactly that reason.
        /// </summary>
        private static SqlParameter[] MeParam(int me)
        {
            return new SqlParameter[] { new SqlParameter("@Me", me) };
        }

        /// <summary>Completed deliveries this user took part in, per role.</summary>
        private int CountCompleted(int me)
        {
            string sql;
            switch (SessionHelper.GetRole())
            {
                case "NGO":
                    sql = @"SELECT COUNT(*) FROM FoodRequests r
                            JOIN FoodDonations d ON d.DonationID = r.DonationID
                            WHERE r.NGOID = @Me AND r.Status = 'Accepted' AND d.Status = 'Delivered'";
                    break;
                case "Volunteer":
                    sql = "SELECT COUNT(*) FROM DeliveryAssignments WHERE VolunteerID = @Me AND Status = 'Delivered'";
                    break;
                default:
                    sql = "SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @Me AND Status = 'Delivered'";
                    break;
            }

            return Convert.ToInt32(DBHelper.ExecuteScalar(sql,
                new SqlParameter[] { new SqlParameter("@Me", me) }));
        }

        private void BindRateable()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                RateableSql + " ORDER BY p.DonationID DESC, p.PartyRole",
                new SqlParameter[] { new SqlParameter("@Me", SessionHelper.GetUserID()) });

            ddlRateable.Items.Clear();

            foreach (DataRow row in dt.Rows)
            {
                string text = "#" + row["DonationID"]
                            + " — " + Truncate(row["FoodDescription"], 40)
                            + " — rate " + Convert.ToString(row["RateeName"])
                            + " (" + Convert.ToString(row["RateeRole"]) + ")";

                ddlRateable.Items.Add(new ListItem(text,
                    Convert.ToString(row["DonationID"]) + ":" + Convert.ToString(row["RateeID"])));
            }

            bool anything = dt.Rows.Count > 0;
            pnlRateForm.Visible = anything;
            pnlNothingToRate.Visible = !anything;

            if (!anything)
            {
                // Two different "nothing here" situations, worded apart so a
                // user who has rated everyone doesn't read it as "this feature
                // is broken".
                litNothingToRate.Text = _completedCount > 0
                    ? "You've already rated everyone on your completed deliveries. New ones will appear here once they're delivered."
                    : "Nothing to rate yet. Once one of your deliveries is completed, the other people on it will appear here.";
            }
        }

        private void BindReceived()
        {
            string filter = "";
            switch (ddlReviewFilter.SelectedValue)
            {
                case "5": filter = " AND r.Stars = 5"; break;
                case "4": filter = " AND r.Stars = 4"; break;
                case "low": filter = " AND r.Stars <= 3"; break;
            }

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT r.RatingID, r.Stars, r.Comments, r.CreatedAt, r.DonationID,
                         u.FullName AS RaterName, u.Role AS RaterRole,
                         d.FoodDescription
                    FROM Ratings r
                    JOIN Users u ON u.UserID = r.RaterID
                    JOIN FoodDonations d ON d.DonationID = r.DonationID
                   WHERE r.RateeID = @Me" + filter + @"
                   ORDER BY r.CreatedAt DESC",
                new SqlParameter[] { new SqlParameter("@Me", SessionHelper.GetUserID()) });

            rptReceived.DataSource = dt;
            rptReceived.DataBind();

            pnlNoReviews.Visible = dt.Rows.Count == 0;
            litNoReviews.Text = ddlReviewFilter.SelectedValue == "all"
                ? "No reviews received yet."
                : "No reviews match this filter.";
        }

        private void BindGiven()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT r.RatingID, r.Stars, r.Comments, r.CreatedAt, r.DonationID,
                         u.FullName AS RateeName, u.Role AS RateeRole
                    FROM Ratings r
                    JOIN Users u ON u.UserID = r.RateeID
                   WHERE r.RaterID = @Me
                   ORDER BY r.CreatedAt DESC",
                new SqlParameter[] { new SqlParameter("@Me", SessionHelper.GetUserID()) });

            rptGiven.DataSource = dt;
            rptGiven.DataBind();

            // Hidden entirely rather than shown with an empty state — a user who
            // has never rated anyone does not need a section telling them so.
            pnlGiven.Visible = dt.Rows.Count > 0;
        }

        // ------------------------------------------------------------------
        // Actions
        // ------------------------------------------------------------------

        protected void ddlReviewFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindReceived();
        }

        protected void btnSubmitRating_Click(object sender, EventArgs e)
        {
            int me = SessionHelper.GetUserID();

            int donationId, rateeId;
            if (!TryParseSelection(ddlRateable.SelectedValue, out donationId, out rateeId))
            {
                ShowMessage("Please choose who you're rating.", "alert-danger");
                return;
            }

            int stars = SelectedStars;
            if (stars < 1 || stars > 5)
            {
                ShowMessage("Please pick a star rating from 1 to 5.", "alert-danger");
                return;
            }

            string comments = (txtComments.Text ?? "").Trim();
            if (comments.Length > 500)
            {
                ShowMessage("Please keep your comments under 500 characters.", "alert-danger");
                return;
            }

            // Re-authorise the pair server-side instead of trusting the posted
            // dropdown value. A forged DonationID:RateeID gets nothing back here
            // even though it round-tripped through the client.
            //
            // Narrowed by appending to the WHERE rather than wrapping the whole
            // thing in SELECT COUNT(*) FROM (...): RateableSql opens with a CTE,
            // and SQL Server rejects a WITH clause inside a derived table.
            DataTable allowed = DBHelper.ExecuteQuery(
                RateableSql + " AND p.DonationID = @DonationID AND p.PartyID = @RateeID",
                new SqlParameter[]
                {
                    new SqlParameter("@Me", me),
                    new SqlParameter("@DonationID", donationId),
                    new SqlParameter("@RateeID", rateeId)
                });

            if (allowed.Rows.Count == 0)
            {
                ShowMessage("You can't rate that — either the delivery isn't complete, you weren't part of it, or you've already rated this person for it.", "alert-danger");
                RebindAll();
                return;
            }

            try
            {
                DBHelper.ExecuteNonQuery(
                    @"INSERT INTO Ratings (DonationID, RaterID, RateeID, Stars, Comments)
                      VALUES (@DonationID, @RaterID, @RateeID, @Stars, @Comments)",
                    new SqlParameter[]
                    {
                        new SqlParameter("@DonationID", donationId),
                        new SqlParameter("@RaterID", me),
                        new SqlParameter("@RateeID", rateeId),
                        new SqlParameter("@Stars", stars),
                        new SqlParameter("@Comments", comments.Length == 0 ? (object)DBNull.Value : comments)
                    });
            }
            catch (SqlException ex) when (ex.Number == 2627 || ex.Number == 2601)
            {
                // UQ_Ratings_OnePerCounterparty. Only reachable by double
                // submitting faster than the check above — the constraint is the
                // authority, so report it plainly rather than as an error.
                ShowMessage("You've already rated this person for that delivery.", "alert-warning");
                RebindAll();
                return;
            }

            RecomputeTrustScore(rateeId);
            NotifyRatee(donationId, rateeId, stars, comments);

            txtComments.Text = "";
            ShowMessage("Rating submitted. Thanks for closing the loop.", "alert-success");

            // Profile is recomputed too: rating someone else doesn't change your
            // own average, but the dropdown, the given-list and the tier
            // progress all move.
            LoadProfile();
            RebindAll();
        }

        private void RebindAll()
        {
            BindRateable();
            BindReceived();
            BindGiven();
        }

        /// <summary>
        /// Users.TrustScore is a cached rolling average of ratings received,
        /// recomputed in full on every new rating.
        ///
        /// Recompute-on-write rather than incremental aggregation: at this scale
        /// an AVG over one person's ratings is trivial, and a full recompute
        /// cannot drift out of step with the rows the way a running total can.
        /// </summary>
        private void RecomputeTrustScore(int rateeId)
        {
            DBHelper.ExecuteNonQuery(
                @"UPDATE Users
                     SET TrustScore = (SELECT AVG(CAST(Stars AS DECIMAL(5,2)))
                                         FROM Ratings WHERE RateeID = @RateeID)
                   WHERE UserID = @RateeID",
                new SqlParameter[] { new SqlParameter("@RateeID", rateeId) });
        }

        /// <summary>
        /// Phase 6c is what finally raises NotifyEvent.RatingReceived, which
        /// Phase 4 declared and labelled "Not active yet".
        /// </summary>
        private void NotifyRatee(int donationId, int rateeId, int stars, string comments)
        {
            string body = SessionHelper.GetFullName() + " rated you " + stars + " out of 5 for donation #"
                        + donationId + ".";

            if (comments.Length > 0)
                body += " They wrote: \"" + comments + "\"";

            NotificationService.Notify(
                rateeId,
                "You received a new rating",
                body,
                NotifyType.System,
                NotifyEvent.RatingReceived,
                "~/Ratings.aspx");
        }

        private static bool TryParseSelection(string value, out int donationId, out int rateeId)
        {
            donationId = 0;
            rateeId = 0;

            if (string.IsNullOrWhiteSpace(value)) return false;

            string[] parts = value.Split(':');
            return parts.Length == 2
                && int.TryParse(parts[0], out donationId)
                && int.TryParse(parts[1], out rateeId);
        }

        private void ShowMessage(string text, string cssClass)
        {
            litMessage.Text = text;
            pnlMessage.CssClass = "alert mb-3 " + cssClass;
            pnlMessage.Visible = true;
        }

        // ------------------------------------------------------------------
        // Trust levels
        // ------------------------------------------------------------------

        /// <summary>
        /// The ladder from the original mockup, computed for real. Both halves
        /// of each rung must be met — 40 deliveries with a 3.9 average is not
        /// Gold. A user with no ratings at all has no average to test, so they
        /// stay at New however many deliveries they have completed.
        /// </summary>
        private string ComputeTier()
        {
            if (_openFlagCount >= 3) return "Flagged";

            if (_receivedCount == 0) return "New";

            if (_completedCount >= 60 && _average >= 4.8m) return "Platinum";
            if (_completedCount >= 40 && _average >= 4.7m) return "Gold";
            if (_completedCount >= 20 && _average >= 4.5m) return "Silver";
            if (_completedCount >= 5 && _average >= 4.0m) return "Bronze";

            return "New";
        }

        protected string TierCssClass
        {
            get
            {
                switch (_tier)
                {
                    case "Platinum": return "trust-platinum";
                    case "Gold": return "trust-gold";
                    case "Silver": return "trust-silver";
                    case "Bronze": return "trust-bronze";
                    case "Flagged": return "trust-flagged";
                    default: return "trust-new";
                }
            }
        }

        protected string TierIcon
        {
            get
            {
                switch (_tier)
                {
                    case "Platinum": return "💎";
                    case "Gold": return "🥇";
                    case "Silver": return "🥈";
                    case "Bronze": return "🥉";
                    case "Flagged": return "🚩";
                    default: return "🆕";
                }
            }
        }

        /// <summary>Highlights the row the user is currently on.</summary>
        protected string TierRowClass(string tier)
        {
            return tier == _tier ? "tier-you" : "";
        }

        protected string TierYouMarker(string tier)
        {
            return tier == _tier ? " ← You" : "";
        }

        private static readonly string[] TierOrder = { "New", "Bronze", "Silver", "Gold", "Platinum" };
        private static readonly int[] TierDeliveries = { 0, 5, 20, 40, 60 };
        private static readonly decimal[] TierRating = { 0m, 4.0m, 4.5m, 4.7m, 4.8m };

        private int CurrentTierIndex
        {
            get
            {
                int i = Array.IndexOf(TierOrder, _tier);
                return i < 0 ? 0 : i;   // Flagged sits outside the ladder
            }
        }

        protected int TierProgressPercent
        {
            get
            {
                if (_tier == "Flagged") return 0;

                int next = CurrentTierIndex + 1;
                if (next >= TierOrder.Length) return 100;

                int needed = TierDeliveries[next];
                if (needed <= 0) return 0;

                int pct = (int)Math.Round(_completedCount * 100.0 / needed);
                return Math.Max(0, Math.Min(100, pct));
            }
        }

        protected string TierProgressText
        {
            get
            {
                if (_tier == "Flagged")
                    return "Open fraud flags are holding your level down.";

                int next = CurrentTierIndex + 1;
                if (next >= TierOrder.Length)
                    return "Highest level reached.";

                int needed = TierDeliveries[next];
                decimal neededStars = TierRating[next];

                if (_completedCount >= needed)
                {
                    // Delivery count is already there; it's the rating half of
                    // the rung that is missing. Say so rather than showing a
                    // 100% bar that never advances.
                    return _receivedCount == 0
                        ? needed + " completed — " + TierOrder[next] + " also needs a " + neededStars.ToString("0.0", CultureInfo.InvariantCulture) + "+ average, so you need some ratings first."
                        : "Needs a " + neededStars.ToString("0.0", CultureInfo.InvariantCulture) + "+ average for " + TierOrder[next] + " (yours is " + AverageDisplay + ").";
                }

                return TierProgressPercent + "% to " + TierOrder[next]
                     + " (" + needed + " completed deliveries, " + neededStars.ToString("0.0", CultureInfo.InvariantCulture) + "+ rating)";
            }
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// The star radios are plain HTML rather than a RadioButtonList, so the
        /// posted value comes back through Request.Form. Returns 0 when nothing
        /// was picked.
        /// </summary>
        protected int SelectedStars
        {
            get
            {
                int stars;
                return int.TryParse(Request.Form["fbStars"], out stars) ? stars : 0;
            }
        }

        /// <summary>Keeps the chosen star lit when a submit fails validation.</summary>
        protected string StarChecked(int value)
        {
            return SelectedStars == value ? "checked=\"checked\"" : "";
        }

        /// <summary>Five star icons — filled, half, or empty — for an average.</summary>
        protected string StarIcons(decimal average)
        {
            int full = (int)Math.Floor(average);
            bool half = (average - full) >= 0.5m;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            for (int i = 1; i <= 5; i++)
            {
                if (i <= full) sb.Append("<i class=\"bi bi-star-fill\"></i>");
                else if (i == full + 1 && half) sb.Append("<i class=\"bi bi-star-half\"></i>");
                else sb.Append("<i class=\"bi bi-star-fill empty\"></i>");
            }
            return sb.ToString();
        }

        /// <summary>Amber for middling, red for poor, green otherwise.</summary>
        protected string BarColour(object stars)
        {
            switch (Convert.ToInt32(stars))
            {
                case 3: return "background:var(--amber)";
                case 2:
                case 1: return "background:var(--red)";
                default: return "";
            }
        }

        protected string RoleBadgeClass(object role)
        {
            switch (Convert.ToString(role))
            {
                case "NGO": return "badge-role-ngo";
                case "Volunteer": return "badge-role-vol";
                case "Admin": return "badge-role-admin";
                default: return "badge-role-donor";
            }
        }

        protected string RoleAvatarStyle(object role)
        {
            switch (Convert.ToString(role))
            {
                case "NGO": return "background:var(--amber-light);color:var(--amber)";
                case "Volunteer": return "background:var(--blue-light);color:var(--blue)";
                case "Admin": return "background:var(--purple-light);color:var(--purple)";
                default: return "background:var(--green-pale);color:var(--green)";
            }
        }

        protected string Truncate(object text, int max)
        {
            string s = Convert.ToString(text);
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length <= max ? s : s.Substring(0, max - 1) + "…";
        }

        protected string ShortDate(object createdAt)
        {
            DateTime dt;
            if (createdAt == null || !DateTime.TryParse(Convert.ToString(createdAt), out dt))
                return "";
            return dt.ToString("d MMM yyyy");
        }

        /// <summary>
        /// A rating with no comment is a legitimate rating — show the stars and
        /// say the comment is absent rather than rendering an empty paragraph.
        /// </summary>
        protected string CommentOrDash(object comments)
        {
            string s = Convert.ToString(comments);
            return string.IsNullOrWhiteSpace(s)
                ? "<span class=\"note-inline\">No comment left.</span>"
                : Server.HtmlEncode(s);
        }
    }
}
