using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    /// <summary>
    /// Donors / NGOs / Volunteers management (Phase 10).
    ///
    /// One page taking ?role= rather than three near-identical files. The views
    /// differ only in which role they filter to and which two activity columns
    /// are meaningful, so three copies would have meant three places to fix
    /// every future change.
    ///
    /// Moderation goes through UserAdminService: the admin dashboard does the
    /// same actions, and the self-suspension guard must not exist in only one
    /// of them.
    /// </summary>
    public partial class users : System.Web.UI.Page
    {
        /// <summary>
        /// The role being shown. Whitelisted — never taken raw from the query
        /// string into SQL, and an unrecognised value falls back to All rather
        /// than erroring or returning everything by accident.
        /// </summary>
        private string SelectedRole
        {
            get
            {
                string raw = Request.QueryString["role"];
                if (string.IsNullOrWhiteSpace(raw)) return "All";

                switch (raw.Trim().ToLowerInvariant())
                {
                    case "donor": return "Donor";
                    case "ngo": return "NGO";
                    case "volunteer": return "Volunteer";
                    case "admin": return "Admin";
                    default: return "All";
                }
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            // Headings and column labels are role-dependent and read at render
            // time, so they are set on every request rather than once.
            ApplyRoleLabels();

            if (!IsPostBack)
                BindAll();
        }

        private void BindAll()
        {
            BindCounts();
            BindUsers();
        }

        // ------------------------------------------------------------------
        // Labels
        // ------------------------------------------------------------------

        private void ApplyRoleLabels()
        {
            switch (SelectedRole)
            {
                case "Donor":
                    litHeading.Text = "Donors";
                    litSubheading.Text = "Everyone registered to post food donations.";
                    litTableHeading.Text = "Registered Donors";
                    litMetricA.Text = "Donations";
                    litMetricB.Text = "Meals Delivered";
                    break;

                case "NGO":
                    litHeading.Text = "NGOs";
                    litSubheading.Text = "Organisations that collect and distribute donated food.";
                    litTableHeading.Text = "Registered NGOs";
                    litMetricA.Text = "Accepted";
                    litMetricB.Text = "Meals Received";
                    break;

                case "Volunteer":
                    litHeading.Text = "Volunteers";
                    litSubheading.Text = "People who carry donations from donor to NGO.";
                    litTableHeading.Text = "Registered Volunteers";
                    litMetricA.Text = "Deliveries";
                    litMetricB.Text = "Active Now";
                    break;

                case "Admin":
                    litHeading.Text = "Administrators";
                    litSubheading.Text = "Accounts that approve donations and moderate users.";
                    litTableHeading.Text = "Administrators";
                    litMetricA.Text = "Reviewed";
                    litMetricB.Text = "Flags Closed";
                    break;

                default:
                    litHeading.Text = "All Users";
                    litSubheading.Text = "Every account on the platform, across all four roles.";
                    litTableHeading.Text = "All Users";
                    // Mixed roles, so the two columns hold whatever each role's
                    // own measure is — named generically rather than mislabelled
                    // as one role's metric.
                    litMetricA.Text = "Activity";
                    litMetricB.Text = "Volume";
                    break;
            }
        }

        // ------------------------------------------------------------------
        // Data
        // ------------------------------------------------------------------

        private SqlParameter[] RoleParam()
        {
            return new SqlParameter[] { new SqlParameter("@Role", SelectedRole) };
        }

        private void BindCounts()
        {
            litTotal.Text = Count("SELECT COUNT(*) FROM Users WHERE (@Role = 'All' OR Role = @Role)");
            litApproved.Text = Count("SELECT COUNT(*) FROM Users WHERE (@Role = 'All' OR Role = @Role) AND IsVerified = 1 AND IsActive = 1");
            litPending.Text = Count("SELECT COUNT(*) FROM Users WHERE (@Role = 'All' OR Role = @Role) AND IsVerified = 0");
            litSuspended.Text = Count("SELECT COUNT(*) FROM Users WHERE (@Role = 'All' OR Role = @Role) AND IsVerified = 1 AND IsActive = 0");
        }

        private string Count(string sql)
        {
            object value = DBHelper.ExecuteScalar(sql, RoleParam());
            return value == null || value == DBNull.Value ? "0" : Convert.ToInt32(value).ToString("N0");
        }

        /// <summary>
        /// The two activity figures are chosen by the user's own role via CASE,
        /// not by the page's filter. That is what lets ?role=All show a mixed
        /// list where every row still reports something true about that person,
        /// instead of a donor column full of zeroes for volunteers.
        /// </summary>
        private void BindUsers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT u.UserID, u.FullName, u.Email, u.Phone, u.City, u.Role,
                         u.OrganizationName, u.IsVerified, u.IsActive, u.TrustScore, u.CreatedAt,
                         CASE u.Role
                           WHEN 'Donor'     THEN (SELECT COUNT(*) FROM FoodDonations d WHERE d.DonorID = u.UserID)
                           WHEN 'NGO'       THEN (SELECT COUNT(*) FROM FoodRequests r WHERE r.NGOID = u.UserID AND r.Status = 'Accepted')
                           WHEN 'Volunteer' THEN (SELECT COUNT(*) FROM DeliveryAssignments a WHERE a.VolunteerID = u.UserID AND a.Status = 'Delivered')
                           ELSE                  (SELECT COUNT(*) FROM FoodDonations d WHERE d.ApprovedBy = u.UserID)
                         END AS MetricA,
                         CASE u.Role
                           WHEN 'Donor'     THEN (SELECT ISNULL(SUM(d.Servings), 0) FROM FoodDonations d
                                                   WHERE d.DonorID = u.UserID AND d.Status = 'Delivered')
                           WHEN 'NGO'       THEN (SELECT ISNULL(SUM(d.Servings), 0) FROM FoodRequests r
                                                   JOIN FoodDonations d ON d.DonationID = r.DonationID
                                                  WHERE r.NGOID = u.UserID AND r.Status = 'Accepted' AND d.Status = 'Delivered')
                           WHEN 'Volunteer' THEN (SELECT COUNT(*) FROM DeliveryAssignments a
                                                   WHERE a.VolunteerID = u.UserID AND a.Status IN ('Assigned','PickedUp'))
                           ELSE                  (SELECT COUNT(*) FROM FraudFlags f WHERE f.ReviewedBy = u.UserID)
                         END AS MetricB
                    FROM Users u
                   WHERE (@Role = 'All' OR u.Role = @Role)
                   ORDER BY u.IsVerified ASC, u.CreatedAt DESC",
                RoleParam());

            rptUsers.DataSource = dt;
            rptUsers.DataBind();

            pnlEmpty.Visible = dt.Rows.Count == 0;
            litEmpty.Text = SelectedRole == "All"
                ? "No accounts yet."
                : "No " + Server.HtmlEncode(SelectedRole) + " accounts yet.";
        }

        // ------------------------------------------------------------------
        // Actions
        // ------------------------------------------------------------------

        protected void rptUsers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int userId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out userId)) return;

            int me = SessionHelper.GetUserID();
            ModerationResult result;

            switch (e.CommandName)
            {
                case "Verify": result = UserAdminService.Verify(userId); break;
                case "Reject": result = UserAdminService.Reject(userId); break;
                case "Ban": result = UserAdminService.Ban(userId, me); break;
                case "Unban": result = UserAdminService.Unban(userId, me); break;
                default: return;
            }

            lblActionMessage.Text = result.Message;
            lblActionMessage.CssClass = "alert " + result.CssClass;
            lblActionMessage.Visible = true;

            BindAll();
        }

        // ------------------------------------------------------------------
        // Markup helpers
        // ------------------------------------------------------------------

        protected string RoleTabClass(string role)
        {
            return SelectedRole == role ? "active" : "";
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

        /// <summary>
        /// Organisation where there is one, otherwise the role. On the All tab
        /// this is what tells you which role a row belongs to.
        /// </summary>
        protected string RoleOrOrg(object role, object orgName)
        {
            string org = Convert.ToString(orgName);
            string r = Server.HtmlEncode(Convert.ToString(role));

            return string.IsNullOrWhiteSpace(org)
                ? r
                : r + " · " + Server.HtmlEncode(org);
        }

        /// <summary>
        /// Unrated reads as "unrated", not 0.0 — Phase 6c leaves TrustScore
        /// NULL until someone is actually rated, and the two must stay
        /// distinguishable.
        /// </summary>
        protected string TrustLabel(object trustScore)
        {
            if (trustScore == null || trustScore == DBNull.Value)
                return "<span class=\"text-muted\">unrated</span>";

            return "⭐ " + Convert.ToDecimal(trustScore).ToString("0.00");
        }

        /// <summary>Drives the client-side filter buttons.</summary>
        protected string StatusFilter(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "pending";
            return Convert.ToBoolean(isActive) ? "active" : "suspended";
        }

        protected string StatusBadgeClass(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "badge-pending";
            return Convert.ToBoolean(isActive) ? "badge-active" : "badge-rejected";
        }

        protected string StatusBadgeText(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "Pending";
            return Convert.ToBoolean(isActive) ? "Active" : "Suspended";
        }
    }
}
