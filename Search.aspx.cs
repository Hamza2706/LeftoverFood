using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    /// <summary>
    /// Role-scoped search (Phase 9), behind the topbar box in Site.master.
    ///
    /// Class name is SearchPage rather than Search, matching NotificationsPage,
    /// RatingsPage and ProfilePage — the other root-level shared pages.
    ///
    /// RequireLogin, not RequireRole: all four roles have the box. What differs
    /// is the WHERE clause, which is built from the session role in
    /// DonationScope() and never from anything the caller sends.
    /// </summary>
    public partial class SearchPage : System.Web.UI.Page
    {
        private const int MinimumTermLength = 2;
        private const int MaxResults = 30;

        private string _term = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireLogin(this);

            _term = (Request.QueryString["q"] ?? "").Trim();

            litScopeNote.Text = Server.HtmlEncode(ScopeNote());

            // One character matches nearly everything and is never what anyone
            // meant, so it is treated as no search rather than run.
            if (_term.Length < MinimumTermLength)
            {
                pnlPrompt.Visible = true;
                litSummary.Text = "";
                return;
            }

            litSummary.Text = "Results for <span class=\"search-term\">"
                              + Server.HtmlEncode(_term) + "</span>";

            int donations = BindDonations();
            int users = BindUsers();

            if (donations == 0 && users == 0)
            {
                pnlDonations.Visible = false;
                pnlUsers.Visible = false;
                pnlNothing.Visible = true;
                litNothingTerm.Text = Server.HtmlEncode(_term);
                litNothingHint.Text = Server.HtmlEncode(ScopeNote());
            }
        }

        // ------------------------------------------------------------------
        // Scope
        // ------------------------------------------------------------------

        /// <summary>
        /// Stated on the page, so a user who searches for something real and
        /// gets nothing understands it is scope rather than a broken search.
        /// </summary>
        private string ScopeNote()
        {
            switch (SessionHelper.GetRole())
            {
                case "Donor": return "Searches the donations you have posted.";
                case "NGO": return "Searches donations available to you and the ones you have accepted.";
                case "Volunteer": return "Searches the donations you were assigned to deliver.";
                case "Admin": return "Searches all donations and all user accounts.";
                default: return "";
            }
        }

        /// <summary>
        /// The role filter, as SQL. @Me is always the session user.
        ///
        /// Each branch mirrors the visibility rule its own dashboard already
        /// enforces, so search cannot become a side door to rows a role could
        /// not otherwise reach — the NGO branch repeats Phase 2's
        /// "open to all, or named to me" rule, and the volunteer branch is
        /// scoped by assignment exactly as Phase 3's dashboard is.
        /// </summary>
        private string DonationScope()
        {
            switch (SessionHelper.GetRole())
            {
                case "Donor":
                    return " AND d.DonorID = @Me ";

                case "NGO":
                    return @" AND ( (d.Status = 'Approved'
                                     AND (d.PreferredNGOID IS NULL OR d.PreferredNGOID = @Me))
                                 OR EXISTS (SELECT 1 FROM FoodRequests r
                                             WHERE r.DonationID = d.DonationID
                                               AND r.NGOID = @Me AND r.Status = 'Accepted') ) ";

                case "Volunteer":
                    return @" AND EXISTS (SELECT 1 FROM DeliveryAssignments a
                                           WHERE a.DonationID = d.DonationID
                                             AND a.VolunteerID = @Me) ";

                case "Admin":
                    return "";

                default:
                    // Unknown role: match nothing rather than everything.
                    return " AND 1 = 0 ";
            }
        }

        // ------------------------------------------------------------------
        // Queries
        // ------------------------------------------------------------------

        private int BindDonations()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP (@Max)
                         d.DonationID, d.FoodDescription, d.Quantity, d.Status, d.City, d.CreatedAt,
                         u.FullName AS DonorName, u.OrganizationName AS DonorOrg
                    FROM FoodDonations d
                    JOIN Users u ON u.UserID = d.DonorID
                   WHERE (d.FoodDescription LIKE @Q
                       OR d.Category        LIKE @Q
                       OR d.Quantity        LIKE @Q
                       OR d.PickupAddress   LIKE @Q
                       OR d.City            LIKE @Q
                       OR d.Status          LIKE @Q)"
                + DonationScope() +
                " ORDER BY d.CreatedAt DESC",
                new SqlParameter[]
                {
                    new SqlParameter("@Max", MaxResults),
                    new SqlParameter("@Q", Like(_term)),
                    new SqlParameter("@Me", SessionHelper.GetUserID())
                });

            rptDonations.DataSource = dt;
            rptDonations.DataBind();

            pnlDonations.Visible = dt.Rows.Count > 0;
            pnlNoDonations.Visible = false;
            litDonationCount.Text = CountLabel(dt.Rows.Count);

            return dt.Rows.Count;
        }

        /// <summary>
        /// Admin only. The query is not merely hidden from other roles — it is
        /// never executed for them, so there is no filter to get wrong.
        /// </summary>
        private int BindUsers()
        {
            if (SessionHelper.GetRole() != "Admin")
            {
                pnlUsers.Visible = false;
                return 0;
            }

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP (@Max) UserID, FullName, Email, Role, City, OrganizationName, IsVerified, IsActive
                    FROM Users
                   WHERE FullName         LIKE @Q
                      OR Email            LIKE @Q
                      OR OrganizationName LIKE @Q
                      OR City             LIKE @Q
                      OR Role             LIKE @Q
                   ORDER BY FullName",
                new SqlParameter[]
                {
                    new SqlParameter("@Max", MaxResults),
                    new SqlParameter("@Q", Like(_term))
                });

            rptUsers.DataSource = dt;
            rptUsers.DataBind();

            pnlUsers.Visible = dt.Rows.Count > 0;
            pnlNoUsers.Visible = false;
            litUserCount.Text = CountLabel(dt.Rows.Count);

            return dt.Rows.Count;
        }

        /// <summary>
        /// Wraps the term for a LIKE, escaping the wildcards first.
        ///
        /// The value is parameterised, so this is not about injection — it is
        /// about meaning. A term containing % would otherwise match every row,
        /// and _ would match any character, which is not what someone typing an
        /// address with an underscore intends. Bracket-escaping avoids needing
        /// an ESCAPE clause on every predicate.
        /// </summary>
        private static string Like(string term)
        {
            string escaped = term
                .Replace("[", "[[]")
                .Replace("%", "[%]")
                .Replace("_", "[_]");

            return "%" + escaped + "%";
        }

        private string CountLabel(int count)
        {
            return count >= MaxResults
                ? "first " + MaxResults
                : count.ToString();
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// A link only where a screen exists for this role to act on that
        /// donation. Everything else gets nothing rather than a dead button —
        /// the same rule the admin dashboard's action column follows.
        /// </summary>
        protected string ResultLink(object donationId, object status)
        {
            string id = Convert.ToString(donationId);
            string state = Convert.ToString(status);

            switch (SessionHelper.GetRole())
            {
                case "Donor":
                    return Link("~/Donor/track-donation.aspx?id=" + id, "Track");

                case "NGO":
                    return state == "Approved"
                        ? Link("~/NGO/ngo-dashboard.aspx", "View")
                        : Link("~/NGO/ngo-active-requests.aspx", "View");

                case "Volunteer":
                    return Link("~/Volunteer/volunteer-dashboard.aspx", "View");

                case "Admin":
                    if (state == "Posted") return Link("~/Admin/food-approvals.aspx", "Review");
                    if (state == "Requested") return Link("~/Admin/volunteer-assign.aspx", "Assign");
                    return "";

                default:
                    return "";
            }
        }

        private string Link(string url, string text)
        {
            return "<a class=\"btn-sm-outline\" href=\"" + ResolveUrl(url) + "\">" + text + "</a>";
        }

        protected string DonorLine(object fullName, object orgName)
        {
            // A donor searching their own donations does not need telling who
            // the donor was.
            if (SessionHelper.GetRole() == "Donor") return "";

            string org = Convert.ToString(orgName);
            string name = !string.IsNullOrWhiteSpace(org) ? org : Convert.ToString(fullName);

            return string.IsNullOrWhiteSpace(name)
                ? ""
                : " · from " + Server.HtmlEncode(name);
        }

        protected string OrgLine(object orgName)
        {
            string org = Convert.ToString(orgName);
            return string.IsNullOrWhiteSpace(org) ? "" : " · " + Server.HtmlEncode(org);
        }

        protected string Initials(object fullName)
        {
            return SessionHelper.Initials(Convert.ToString(fullName));
        }

        protected string Dash(object value)
        {
            string text = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(text) ? "—" : text;
        }

        protected string StatusBadge(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted": return "badge-pending";
                case "Approved": return "badge-verified";
                case "Delivered": return "badge-delivered";
                case "Rejected":
                case "Cancelled":
                case "Expired": return "badge-rejected";
                default: return "badge-accepted";
            }
        }

        protected string StatusColour(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted": return "var(--amber)";
                case "Delivered": return "var(--green)";
                case "Rejected":
                case "Cancelled":
                case "Expired": return "var(--red)";
                default: return "var(--blue)";
            }
        }

        protected string RoleBadge(object role)
        {
            switch (Convert.ToString(role))
            {
                case "Donor": return "badge-role-donor";
                case "NGO": return "badge-role-ngo";
                case "Volunteer": return "badge-role-vol";
                case "Admin": return "badge-role-admin";
                default: return "";
            }
        }

        protected string UserStatusBadge(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "badge-pending";
            if (!Convert.ToBoolean(isActive)) return "badge-rejected";
            return "badge-active";
        }

        protected string UserStatusText(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "Pending";
            if (!Convert.ToBoolean(isActive)) return "Suspended";
            return "Active";
        }
    }
}
