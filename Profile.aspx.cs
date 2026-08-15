using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood
{
    /// <summary>
    /// Shared account profile for all four roles (Phase 7).
    ///
    /// Class name is ProfilePage rather than Profile to match the naming
    /// NotificationsPage and RatingsPage already use for the two other
    /// root-level shared pages.
    ///
    /// Queries are inline over DBHelper rather than behind a UserService,
    /// following Phase 1's reasoning: this page is the only consumer of them.
    /// The one query that is genuinely shared with another page — the verified
    /// NGO list for the Preferred NGO dropdown — is deliberately written to
    /// match Donor/donate-form.aspx.cs exactly, so a donor's saved default and
    /// the per-donation picker can never offer different options.
    ///
    /// RequireLogin, not RequireRole: every role has an account to maintain and
    /// the page is the same for all of them apart from three conditional
    /// sections. Every statement is scoped by UserID from the session, never
    /// from the request, so there is no way to read or write another user's row.
    /// </summary>
    public partial class ProfilePage : System.Web.UI.Page
    {
        // ------------------------------------------------------------------
        // Hero state. Read by the markup through <%= %>, which renders after
        // Page_Load but also after every postback, so these are recomputed on
        // every request rather than sitting behind an !IsPostBack guard — the
        // same pattern Ratings.aspx uses.
        // ------------------------------------------------------------------

        protected string FullName { get; private set; }
        protected string Initials { get; private set; }
        protected string RoleLabel { get; private set; }
        protected string CityLabel { get; private set; }
        protected string MemberSince { get; private set; }

        private string Role
        {
            get { return SessionHelper.GetRole() ?? ""; }
        }

        /// <summary>
        /// Fresh parameter instances per call. A SqlParameter can only belong to
        /// one command's collection at a time, so reusing an array across two
        /// DBHelper calls throws — the bug Phase 6c hit on Ratings.aspx and
        /// Phase 2 hit on donor-dashboard.aspx.
        /// </summary>
        private static SqlParameter[] MeParam(int userId)
        {
            return new SqlParameter[] { new SqlParameter("@UserID", userId) };
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireLogin(this);

            // Panel.Visible is stored in ViewState, so a message shown by one
            // postback would otherwise still be on screen after the next,
            // unrelated one — saving an email that clashes and then submitting
            // the password form left both errors stacked. Cleared on every
            // request; whatever runs later this request sets it again.
            pnlMessage.Visible = false;
            pnlPwMessage.Visible = false;

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT UserID, FullName, Email, Phone, Role, Address, City, Bio,
                         OrganizationName, BusinessType, RegNumber, PreferredNGOID,
                         IsVerified, IsActive, CreatedAt, LastLoginAt
                  FROM Users WHERE UserID = @UserID",
                MeParam(SessionHelper.GetUserID()));

            if (dt.Rows.Count == 0)
            {
                // The row backing this session is gone (Phase 1's Reject deletes
                // rejected registrations). Nothing to show and nothing to edit.
                SessionHelper.Logout(this);
                return;
            }

            DataRow user = dt.Rows[0];

            LoadHero(user);
            LoadReadOnly(user);
            ConfigureRoleSections();

            if (!IsPostBack)
            {
                LoadForm(user);
                BindActivity();
                ShowSavedMessage();
            }
        }

        // ------------------------------------------------------------------
        // Load
        // ------------------------------------------------------------------

        private void LoadHero(DataRow user)
        {
            FullName = Convert.ToString(user["FullName"]);
            Initials = SessionHelper.Initials(FullName);
            RoleLabel = Convert.ToString(user["Role"]);

            string city = Text(user["City"]);
            CityLabel = city.Length == 0 ? "City not set" : city;

            MemberSince = Convert.ToDateTime(user["CreatedAt"]).ToString("MMMM yyyy");

            litHeroStats.Text = BuildHeroStats();

            // The mockup showed "Verified Account" unconditionally. This is the
            // real IsVerified flag, which is admin approval of the account.
            bool verified = Convert.ToBoolean(user["IsVerified"]);
            litVerifiedChip.Text = verified
                ? "<span style=\"background:rgba(255,255,255,.15);border:1.5px solid rgba(255,255,255,.3);color:#fff;border-radius:50px;padding:.4rem 1.1rem;font-size:.83rem;font-weight:600;display:inline-flex;align-items:center;gap:.4rem\">"
                  + "<i class=\"bi bi-shield-check-fill\"></i> Approved Account</span>"
                : "<span style=\"background:rgba(0,0,0,.18);border:1.5px solid rgba(255,255,255,.25);color:#fff;border-radius:50px;padding:.4rem 1.1rem;font-size:.83rem;font-weight:600;display:inline-flex;align-items:center;gap:.4rem\">"
                  + "<i class=\"bi bi-hourglass-split\"></i> Awaiting admin approval</span>";
        }

        /// <summary>
        /// Hero counters, per role. Every figure is a query — the mockup's
        /// "47 donations / 4.8 / Gold Donor / 1,240 meals" were literals.
        ///
        /// Meals are counted from Servings, the only numeric quantity in the
        /// schema; Quantity is free text ("10 Plates") and cannot be summed,
        /// the same limitation Phase 6b and 6d both ran into.
        /// </summary>
        private string BuildHeroStats()
        {
            int me = SessionHelper.GetUserID();
            string html = "";

            switch (Role)
            {
                case "Donor":
                    html += Stat(Scalar("SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @UserID", me), "Donations");
                    html += Stat(Scalar(@"SELECT ISNULL(SUM(Servings), 0) FROM FoodDonations
                                          WHERE DonorID = @UserID AND Status = 'Delivered'", me), "Meals Served");
                    html += TrustStat(me);
                    break;

                case "NGO":
                    html += Stat(Scalar(@"SELECT COUNT(*) FROM FoodRequests
                                          WHERE NGOID = @UserID AND Status = 'Accepted'", me), "Donations Accepted");
                    html += Stat(Scalar(@"SELECT ISNULL(SUM(d.Servings), 0)
                                          FROM FoodRequests r
                                          JOIN FoodDonations d ON d.DonationID = r.DonationID
                                          WHERE r.NGOID = @UserID AND d.Status = 'Delivered'", me), "Meals Received");
                    html += TrustStat(me);
                    break;

                case "Volunteer":
                    html += Stat(Scalar(@"SELECT COUNT(*) FROM DeliveryAssignments
                                          WHERE VolunteerID = @UserID AND Status = 'Delivered'", me), "Deliveries Done");
                    html += Stat(Scalar(@"SELECT COUNT(*) FROM DeliveryAssignments
                                          WHERE VolunteerID = @UserID AND Status IN ('Assigned','PickedUp')", me), "Active Tasks");
                    html += TrustStat(me);
                    break;

                case "Admin":
                    // An admin never posts, accepts or delivers, so the three
                    // participant counters above are all structurally zero.
                    // These are what an admin actually does.
                    html += Stat(Scalar("SELECT COUNT(*) FROM FoodDonations WHERE ApprovedBy = @UserID", me), "Donations Reviewed");
                    html += Stat(Scalar("SELECT COUNT(*) FROM FraudFlags WHERE ReviewedBy = @UserID", me), "Flags Closed");
                    break;
            }

            return html;
        }

        private static string Stat(int value, string label)
        {
            return "<span><strong>" + value.ToString("N0") + "</strong> "
                   + HttpUtility.HtmlEncode(label) + "</span>";
        }

        /// <summary>
        /// Live AVG rather than the cached Users.TrustScore, matching the choice
        /// Ratings.aspx made: a missed recompute must never show someone a wrong
        /// number about themselves. No ratings reads as "unrated", not 0.0.
        /// </summary>
        private string TrustStat(int me)
        {
            object avg = DBHelper.ExecuteScalar(
                "SELECT AVG(CAST(Stars AS DECIMAL(4,2))) FROM Ratings WHERE RateeID = @UserID",
                MeParam(me));

            return avg == null || avg == DBNull.Value
                ? "<span><strong>unrated</strong> so far</span>"
                : "<span><strong>" + Convert.ToDecimal(avg).ToString("0.0") + "</strong> Rating</span>";
        }

        private static int Scalar(string sql, int me)
        {
            object value = DBHelper.ExecuteScalar(sql, MeParam(me));
            return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
        }

        private void LoadReadOnly(DataRow user)
        {
            // Real UserID. The mockup's "USR-2025-0031" was invented, and a
            // padded fake id would only make it harder to match a person to the
            // row an admin sees.
            litAccountId.Text = "#" + Convert.ToString(user["UserID"]);
            litJoined.Text = Convert.ToDateTime(user["CreatedAt"]).ToString("d MMMM yyyy");

            litLastLogin.Text = user["LastLoginAt"] == DBNull.Value
                ? "<span class=\"text-muted\" style=\"font-weight:400\">not recorded yet</span>"
                : Server.HtmlEncode(Convert.ToDateTime(user["LastLoginAt"]).ToString("d MMM yyyy, h:mm tt"));

            litApproval.Text = Convert.ToBoolean(user["IsVerified"])
                ? "<span class=\"badge-status badge-active\">Approved</span>"
                : "<span class=\"badge-status badge-pending\">Pending</span>";

            bool active = Convert.ToBoolean(user["IsActive"]);
            litAccountStatus.Text = active
                ? "<span class=\"badge-status badge-active\">Active</span>"
                : "<span class=\"badge-status badge-inactive\">Suspended</span>";

            txtRole.Text = Convert.ToString(user["Role"]);
            txtStatus.Text = active ? "Active" : "Suspended";
        }

        private void LoadForm(DataRow user)
        {
            txtFullName.Text = Text(user["FullName"]);
            txtEmail.Text = Text(user["Email"]);
            txtPhone.Text = Text(user["Phone"]);
            txtAddress.Text = Text(user["Address"]);
            txtBio.Text = Text(user["Bio"]);
            Select(ddlCity, Text(user["City"]));

            if (pnlOrg.Visible)
            {
                txtOrgName.Text = Text(user["OrganizationName"]);
                txtRegNumber.Text = Text(user["RegNumber"]);

                if (pnlBusinessType.Visible)
                    Select(ddlBusinessType, Text(user["BusinessType"]));

                if (pnlPreferredNgo.Visible)
                {
                    BindPreferredNGOs();
                    Select(ddlPreferredNGO, user["PreferredNGOID"] == DBNull.Value
                                            ? "" : Convert.ToString(user["PreferredNGOID"]));
                }
            }

            if (pnlVolunteerLocation.Visible)
                LoadShareLocation();
        }

        /// <summary>
        /// Which of the three conditional sections this role sees. Runs on every
        /// request, including postbacks, because a Panel with Visible=false does
        /// not create its children and its events would never fire.
        /// </summary>
        private void ConfigureRoleSections()
        {
            bool isDonor = Role == "Donor";
            bool isNgo = Role == "NGO";

            pnlOrg.Visible = isDonor || isNgo;
            pnlBusinessType.Visible = isDonor;
            pnlPreferredNgo.Visible = isDonor;
            pnlVolunteerLocation.Visible = Role == "Volunteer";

            // Admin is excluded from ~/Ratings.aspx (Phase 6c) — an admin never
            // participates in a delivery, so has no ratings to summarise and
            // nowhere for the link to usefully go.
            pnlTrust.Visible = Role != "Admin";

            litOrgHeading.Text = isNgo ? "NGO Details" : "Restaurant / Organization Details";
            litRegLabel.Text = isNgo ? "NGO Registration No." : "CNIC / Business Reg No.";
            litAddressLabel.Text = isDonor ? "Address / Pickup Location" : "Address";

            if (pnlTrust.Visible)
                LoadTrustCard();
        }

        private void LoadTrustCard()
        {
            int me = SessionHelper.GetUserID();

            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT COUNT(*) AS Received, AVG(CAST(Stars AS DECIMAL(4,2))) AS AvgStars
                  FROM Ratings WHERE RateeID = @UserID",
                MeParam(me));

            int received = Convert.ToInt32(dt.Rows[0]["Received"]);
            object avg = dt.Rows[0]["AvgStars"];

            if (received == 0)
            {
                litTrustScore.Text = "Not yet rated";
                litTrustDetail.Text = "Ratings appear after your first completed delivery.";
            }
            else
            {
                litTrustScore.Text = Convert.ToDecimal(avg).ToString("0.00") + " / 5.00";
                litTrustDetail.Text = received + (received == 1 ? " rating received" : " ratings received");
            }
        }

        /// <summary>
        /// Read-only mirror of Users.ShareLocation. The switch itself stays on
        /// the volunteer dashboard: turning it off also deletes the positions
        /// already stored (Phase 5), and duplicating that here would mean two
        /// code paths that have to agree about a privacy guarantee.
        /// </summary>
        private void LoadShareLocation()
        {
            object share = DBHelper.ExecuteScalar(
                "SELECT ShareLocation FROM Users WHERE UserID = @UserID",
                MeParam(SessionHelper.GetUserID()));

            bool on = share != null && share != DBNull.Value && Convert.ToBoolean(share);

            litShareLocation.Text = on
                ? "<span class=\"badge-status badge-active\">On</span>"
                : "<span class=\"badge-status badge-inactive\">Off</span>";
        }

        /// <summary>
        /// Same query and same label format as Donor/donate-form.aspx.cs, so the
        /// saved default and the per-donation picker always show the same list.
        /// </summary>
        private void BindPreferredNGOs()
        {
            ddlPreferredNGO.Items.Clear();
            ddlPreferredNGO.Items.Add(new ListItem("No preference — offer to all verified NGOs", ""));

            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, OrganizationName, City FROM Users WHERE Role = 'NGO' AND IsVerified = 1 ORDER BY FullName");

            foreach (DataRow row in dt.Rows)
            {
                string label = row["OrganizationName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["OrganizationName"].ToString())
                    ? row["OrganizationName"].ToString()
                    : row["FullName"].ToString();

                if (row["City"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["City"].ToString()))
                    label += " – " + row["City"];

                ddlPreferredNGO.Items.Add(new ListItem(label, row["UserID"].ToString()));
            }
        }

        /// <summary>
        /// Recent activity from the user's own notifications. The mockup had
        /// four hardcoded rows; Notifications is already a real per-user event
        /// log written by every phase from 4 onward, so it is the honest source
        /// rather than a second activity table nothing else would populate.
        /// </summary>
        private void BindActivity()
        {
            DataTable dt = NotificationService.GetForUser(SessionHelper.GetUserID(), 5);
            rptActivity.DataSource = dt;
            rptActivity.DataBind();
            pnlNoActivity.Visible = dt.Rows.Count == 0;
        }

        // ------------------------------------------------------------------
        // Save
        // ------------------------------------------------------------------

        protected void btnSavePersonal_Click(object sender, EventArgs e)
        {
            int me = SessionHelper.GetUserID();

            string fullName = txtFullName.Text.Trim();
            string email = txtEmail.Text.Trim().ToLower();
            string phone = txtPhone.Text.Trim();
            string city = ddlCity.SelectedValue;
            string address = txtAddress.Text.Trim();
            string bio = txtBio.Text.Trim();

            if (fullName.Length == 0)
            {
                ShowMessage("Full name cannot be empty.", "alert-danger");
                return;
            }

            if (email.Length == 0 || email.IndexOf('@') <= 0 || email.EndsWith("@"))
            {
                ShowMessage("Please enter a valid email address.", "alert-danger");
                return;
            }

            // MaxLength is a client hint and is not enforced at all on a
            // multiline TextBox, so a long paste would otherwise surface as a
            // SQL truncation error — the same guard Phase 6a added.
            string tooLong = FirstTooLong(fullName, 150, "Full name")
                          ?? FirstTooLong(email, 150, "Email")
                          ?? FirstTooLong(phone, 30, "Phone number")
                          ?? FirstTooLong(address, 300, "Address")
                          ?? FirstTooLong(bio, 500, "Bio");

            if (tooLong != null)
            {
                ShowMessage(tooLong, "alert-danger");
                return;
            }

            // Email is the sign-in name, so it has to stay unique. Scoped to
            // "somebody else", otherwise saving without changing it would
            // collide with the user's own row.
            int clash = Convert.ToInt32(DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE Email = @Email AND UserID <> @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@Email", email),
                    new SqlParameter("@UserID", me)
                }));

            if (clash > 0)
            {
                ShowMessage("That email address is already used by another account.", "alert-danger");
                return;
            }

            DBHelper.ExecuteNonQuery(
                @"UPDATE Users
                     SET FullName = @FullName, Email = @Email, Phone = @Phone,
                         City = @City, Address = @Address, Bio = @Bio
                   WHERE UserID = @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@FullName", fullName),
                    new SqlParameter("@Email",    email),
                    new SqlParameter("@Phone",    Nullable(phone)),
                    new SqlParameter("@City",     Nullable(city)),
                    new SqlParameter("@Address",  Nullable(address)),
                    new SqlParameter("@Bio",      Nullable(bio)),
                    new SqlParameter("@UserID",   me)
                });

            // The sidebar, the topbar avatar and the hero all read the name from
            // session, and Site.master.cs sets the avatar during its own Load —
            // before this handler runs. Redirecting rather than re-binding means
            // every one of them is rendered from the saved values, and a refresh
            // does not repost the form.
            Session["FullName"] = fullName;
            Session["Email"] = email;
            Response.Redirect("~/Profile.aspx?saved=personal");
        }

        protected void btnSaveOrg_Click(object sender, EventArgs e)
        {
            int me = SessionHelper.GetUserID();

            string orgName = txtOrgName.Text.Trim();
            string regNumber = txtRegNumber.Text.Trim();
            string businessType = pnlBusinessType.Visible ? ddlBusinessType.SelectedValue : null;

            string tooLong = FirstTooLong(orgName, 150, "Organization name")
                          ?? FirstTooLong(regNumber, 100, "Registration number");

            if (tooLong != null)
            {
                ShowMessage(tooLong, "alert-danger");
                return;
            }

            object preferredNgo = DBNull.Value;
            if (pnlPreferredNgo.Visible && ddlPreferredNGO.SelectedValue.Length > 0)
            {
                int ngoId;
                if (!int.TryParse(ddlPreferredNGO.SelectedValue, out ngoId))
                {
                    ShowMessage("That NGO selection is not valid.", "alert-danger");
                    return;
                }

                // The posted id is re-checked rather than trusted: it round
                // trips through the client, and PreferredNGOID is a foreign key
                // that would otherwise accept any existing user id, including a
                // donor's own.
                int valid = Convert.ToInt32(DBHelper.ExecuteScalar(
                    "SELECT COUNT(*) FROM Users WHERE UserID = @NgoID AND Role = 'NGO' AND IsVerified = 1",
                    new SqlParameter[] { new SqlParameter("@NgoID", ngoId) }));

                if (valid == 0)
                {
                    ShowMessage("That NGO is no longer available. Please pick another.", "alert-danger");
                    return;
                }

                preferredNgo = ngoId;
            }

            // BusinessType and PreferredNGOID are Donor-only columns, so for an
            // NGO they are left exactly as they are rather than being nulled.
            if (pnlBusinessType.Visible)
            {
                DBHelper.ExecuteNonQuery(
                    @"UPDATE Users
                         SET OrganizationName = @OrgName, RegNumber = @RegNumber,
                             BusinessType = @BusinessType, PreferredNGOID = @PreferredNGOID
                       WHERE UserID = @UserID",
                    new SqlParameter[]
                    {
                        new SqlParameter("@OrgName",        Nullable(orgName)),
                        new SqlParameter("@RegNumber",      Nullable(regNumber)),
                        new SqlParameter("@BusinessType",   Nullable(businessType)),
                        new SqlParameter("@PreferredNGOID", preferredNgo),
                        new SqlParameter("@UserID",         me)
                    });
            }
            else
            {
                DBHelper.ExecuteNonQuery(
                    @"UPDATE Users
                         SET OrganizationName = @OrgName, RegNumber = @RegNumber
                       WHERE UserID = @UserID",
                    new SqlParameter[]
                    {
                        new SqlParameter("@OrgName",   Nullable(orgName)),
                        new SqlParameter("@RegNumber", Nullable(regNumber)),
                        new SqlParameter("@UserID",    me)
                    });
            }

            Response.Redirect("~/Profile.aspx?saved=org");
        }

        protected void btnChangePassword_Click(object sender, EventArgs e)
        {
            int me = SessionHelper.GetUserID();

            string current = txtCurrentPassword.Text;
            string fresh = txtNewPassword.Text;
            string confirm = txtConfirmPassword.Text;

            if (current.Length == 0 || fresh.Length == 0)
            {
                ShowPwMessage("Enter your current password and a new one.", "alert-danger");
                return;
            }

            if (fresh != confirm)
            {
                ShowPwMessage("The two new passwords do not match.", "alert-danger");
                return;
            }

            string weakness = PasswordProblem(fresh);
            if (weakness != null)
            {
                ShowPwMessage(weakness, "alert-danger");
                return;
            }

            object storedHash = DBHelper.ExecuteScalar(
                "SELECT PasswordHash FROM Users WHERE UserID = @UserID", MeParam(me));

            if (storedHash == null || storedHash == DBNull.Value)
            {
                ShowPwMessage("Could not read your account. Please sign in again.", "alert-danger");
                return;
            }

            // VerifyPassword handles both the salted PBKDF2 format and the
            // legacy unsalted SHA-256 one, so an account that has not signed in
            // since Phase 0 can still change its password here — and doing so
            // upgrades it, because HashPassword only ever writes the new format.
            if (!PasswordHelper.VerifyPassword(current, Convert.ToString(storedHash)))
            {
                ShowPwMessage("Your current password is incorrect.", "alert-danger");
                return;
            }

            if (PasswordHelper.VerifyPassword(fresh, Convert.ToString(storedHash)))
            {
                ShowPwMessage("Your new password must be different from your current one.", "alert-danger");
                return;
            }

            DBHelper.ExecuteNonQuery(
                "UPDATE Users SET PasswordHash = @Hash WHERE UserID = @UserID",
                new SqlParameter[]
                {
                    new SqlParameter("@Hash", PasswordHelper.HashPassword(fresh)),
                    new SqlParameter("@UserID", me)
                });

            // Mandatory (null event key): being told your password changed is
            // not something a user may opt out of, the same reasoning Phase 4
            // applied to account suspension. Notify is fail-soft, so a bounced
            // email cannot undo a password that is already changed.
            NotificationService.Notify(
                me,
                "Your FoodBridge password was changed",
                "The password on your FoodBridge account was changed. If this was not you, contact an administrator immediately.",
                NotifyType.System,
                null,
                "~/Profile.aspx");

            Response.Redirect("~/Profile.aspx?saved=password");
        }

        /// <summary>
        /// Exactly the rule the card states — 8+ characters, at least one digit
        /// and at least one special character. Registration does not enforce
        /// this today, so it is stated here as what this page requires rather
        /// than as a claim about every password in the system.
        /// </summary>
        private static string PasswordProblem(string password)
        {
            if (password.Length < 8)
                return "New password must be at least 8 characters long.";

            bool hasDigit = false, hasSpecial = false;
            foreach (char c in password)
            {
                if (char.IsDigit(c)) hasDigit = true;
                else if (!char.IsLetter(c)) hasSpecial = true;
            }

            if (!hasDigit) return "New password must include at least 1 number.";
            if (!hasSpecial) return "New password must include at least 1 special character.";
            return null;
        }

        // ------------------------------------------------------------------
        // Small helpers
        // ------------------------------------------------------------------

        private static string Text(object value)
        {
            return value == null || value == DBNull.Value ? "" : Convert.ToString(value);
        }

        /// <summary>Empty text is stored as NULL, so "unset" stays distinct from "blank".</summary>
        private static object Nullable(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value.Trim();
        }

        private static string FirstTooLong(string value, int max, string label)
        {
            return value != null && value.Length > max
                ? label + " is too long (" + value.Length + " characters, maximum " + max + ")."
                : null;
        }

        /// <summary>
        /// Selects a stored value in a list, falling back to the first item when
        /// the stored value is not one of the options — an older free-text city
        /// or business type must not throw here.
        /// </summary>
        private static void Select(DropDownList list, string value)
        {
            ListItem item = list.Items.FindByValue(value ?? "");
            if (item == null && !string.IsNullOrEmpty(value))
            {
                // Keep what is actually stored visible rather than silently
                // showing the user a different value from the one in the row.
                item = new ListItem(value, value);
                list.Items.Add(item);
            }

            list.ClearSelection();
            if (item != null) item.Selected = true;
            else if (list.Items.Count > 0) list.Items[0].Selected = true;
        }

        private void ShowSavedMessage()
        {
            switch (Request.QueryString["saved"])
            {
                case "personal":
                    ShowMessage("Your details have been saved.", "alert-success");
                    break;
                case "org":
                    ShowMessage("Organization details saved.", "alert-success");
                    break;
                case "password":
                    ShowPwMessage("Your password has been changed.", "alert-success");
                    break;
            }
        }

        private void ShowMessage(string message, string cssClass)
        {
            litMessage.Text = Server.HtmlEncode(message);
            pnlMessage.CssClass = "alert " + cssClass + " mb-3";
            pnlMessage.Visible = true;
        }

        private void ShowPwMessage(string message, string cssClass)
        {
            litPwMessage.Text = Server.HtmlEncode(message);
            pnlPwMessage.CssClass = "alert " + cssClass + " mb-3";
            pnlPwMessage.Visible = true;
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

        protected string TypeIcon(object type)
        {
            switch (Convert.ToString(type))
            {
                case NotifyType.Approval: return "bi-clipboard2-check-fill";
                case NotifyType.Delivery: return "bi-truck";
                case NotifyType.Emergency: return "bi-exclamation-triangle-fill";
                default: return "bi-info-circle-fill";
            }
        }
    }
}
