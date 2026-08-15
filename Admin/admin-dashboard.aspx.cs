using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    public partial class admin_dashboard : System.Web.UI.Page
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
            BindHealth();
            BindRecentDonations();
            BindPendingUsers();
            BindAllUsers();
        }

        protected void btnRefresh_Click(object sender, EventArgs e)
        {
            // Was an fbToast('Data refreshed!') that refreshed nothing.
            BindAll();
            ShowMessage("Dashboard refreshed.", "alert-success");
        }

        private void BindStats()
        {
            litAsAt.Text = DateTime.Now.ToString("d MMM yyyy, h:mm tt");

            litTotalUsers.Text = DBHelper.ExecuteScalar("SELECT COUNT(*) FROM Users").ToString();
            litTotalDonations.Text = DBHelper.ExecuteScalar("SELECT COUNT(*) FROM FoodDonations").ToString();
            litTotalNGOs.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE Role = 'NGO' AND IsVerified = 1").ToString();
            litPendingApprovals.Text = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM Users WHERE IsVerified = 0").ToString();
        }

        // ------------------------------------------------------------------
        // System Health
        //
        // The mockup's four figures (94% / 88% / 72% / +15%) were literals, and
        // the fulfilment one contradicted Admin/reports.aspx, which measures the
        // same thing from the same table and gets 50%. Each bar below is now a
        // real query, and each carries the counts it came from so the number is
        // checkable rather than just asserted.
        // ------------------------------------------------------------------

        private void BindHealth()
        {
            // Same definition as reports.aspx.cs: donations that actually
            // entered the pipeline. Rejected and cancelled ones are excluded
            // from the denominator so the bar does not blame the delivery chain
            // for admin decisions and donor changes of mind.
            int inPipeline = Count("SELECT COUNT(*) FROM FoodDonations WHERE Status NOT IN ('Posted','Rejected','Cancelled')");
            int delivered = Count("SELECT COUNT(*) FROM FoodDonations WHERE Status = 'Delivered'");
            SetBar(litFulfilment, barFulfilment, litFulfilmentNote, delivered, inPipeline,
                   delivered + " of " + inPipeline + " in-pipeline donations delivered");

            // Of the donations an admin approved, how many an NGO then claimed.
            int approved = Count("SELECT COUNT(*) FROM FoodDonations WHERE Status NOT IN ('Posted','Rejected','Cancelled')");
            int claimed = Count(@"SELECT COUNT(DISTINCT r.DonationID) FROM FoodRequests r
                                  JOIN FoodDonations d ON d.DonationID = r.DonationID
                                  WHERE r.Status = 'Accepted' AND d.Status NOT IN ('Posted','Rejected','Cancelled')");
            SetBar(litNgoResponse, barNgoResponse, litNgoResponseNote, claimed, approved,
                   claimed + " of " + approved + " approved donations claimed by an NGO");

            // "Availability" in the mockup implied a roster this app does not
            // have. What it does know is who is not currently mid-delivery.
            int volunteers = Count("SELECT COUNT(*) FROM Users WHERE Role = 'Volunteer' AND IsVerified = 1 AND IsActive = 1");
            int busy = Count(@"SELECT COUNT(DISTINCT VolunteerID) FROM DeliveryAssignments
                               WHERE Status IN ('Assigned','PickedUp')");
            SetBar(litVolunteerFree, barVolunteerFree, litVolunteerFreeNote, volunteers - busy, volunteers,
                   (volunteers - busy) + " of " + volunteers + " active volunteers have no delivery in hand");

            // The mockup's "+15%" had no baseline at all. This is a real count
            // for the current calendar month, with last month named for
            // comparison rather than a percentage off an unstated base.
            DateTime monthStart = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
            int thisMonth = Count("SELECT COUNT(*) FROM Users WHERE CreatedAt >= @From",
                                  new SqlParameter[] { new SqlParameter("@From", monthStart) });
            int lastMonth = Count("SELECT COUNT(*) FROM Users WHERE CreatedAt >= @From AND CreatedAt < @To",
                                  new SqlParameter[]
                                  {
                                      new SqlParameter("@From", monthStart.AddMonths(-1)),
                                      new SqlParameter("@To", monthStart)
                                  });

            litUserGrowth.Text = thisMonth.ToString("N0");
            // Scaled against the busier of the two months so the bar has a
            // meaningful full width instead of an invented target.
            int scale = Math.Max(Math.Max(thisMonth, lastMonth), 1);
            barUserGrowth.Style["width"] = Percent(thisMonth, scale) + "%";
            litUserGrowthNote.Text = lastMonth == 0
                ? "no sign-ups last month to compare against"
                : Server.HtmlEncode(lastMonth + " signed up last month");
        }

        /// <summary>
        /// One bar: percentage label, width, and the raw counts underneath. A
        /// zero denominator renders "—" rather than 0%, keeping "nothing to
        /// measure yet" distinct from "measured, and it is zero".
        /// </summary>
        private void SetBar(Literal label, HtmlGenericControl bar, Literal note, int part, int whole, string detail)
        {
            if (whole <= 0)
            {
                label.Text = "—";
                bar.Style["width"] = "0%";
                note.Text = "nothing to measure yet";
                return;
            }

            int pct = Percent(part, whole);
            label.Text = pct + "%";
            bar.Style["width"] = pct + "%";
            note.Text = Server.HtmlEncode(detail);
        }

        private static int Percent(int part, int whole)
        {
            return whole <= 0 ? 0 : (int)Math.Round(part * 100.0 / whole);
        }

        private static int Count(string sql, SqlParameter[] parameters = null)
        {
            object value = DBHelper.ExecuteScalar(sql, parameters);
            return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
        }

        // ------------------------------------------------------------------
        // Recent donations
        // ------------------------------------------------------------------

        /// <summary>
        /// Replaces five hardcoded table rows. OUTER APPLY rather than a plain
        /// LEFT JOIN on DeliveryAssignments: a donation can hold more than one
        /// assignment row, which would otherwise duplicate the donation in this
        /// list. Takes the most recent one, which is the live assignment.
        /// </summary>
        private void BindRecentDonations()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 15
                         d.DonationID, d.FoodDescription, d.Quantity, d.Status, d.City,
                         don.FullName AS DonorName, don.OrganizationName AS DonorOrg,
                         ngo.FullName AS NgoName, ngo.OrganizationName AS NgoOrg,
                         vol.FullName AS VolunteerName
                    FROM FoodDonations d
                    JOIN Users don ON don.UserID = d.DonorID
                    OUTER APPLY (SELECT TOP 1 r.NGOID FROM FoodRequests r
                                  WHERE r.DonationID = d.DonationID AND r.Status = 'Accepted'
                                  ORDER BY r.RequestedAt DESC) req
                    OUTER APPLY (SELECT TOP 1 a.VolunteerID FROM DeliveryAssignments a
                                  WHERE a.DonationID = d.DonationID
                                  ORDER BY a.AssignedAt DESC) asg
                    LEFT JOIN Users ngo ON ngo.UserID = req.NGOID
                    LEFT JOIN Users vol ON vol.UserID = asg.VolunteerID
                   ORDER BY d.CreatedAt DESC");

            rptRecentDonations.DataSource = dt;
            rptRecentDonations.DataBind();
            pnlNoDonations.Visible = dt.Rows.Count == 0;
        }

        private void BindPendingUsers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, Email, Role, City, CreatedAt FROM Users WHERE IsVerified = 0 ORDER BY CreatedAt");

            rptPending.DataSource = dt;
            rptPending.DataBind();

            pnlNoPending.Visible = dt.Rows.Count == 0;
            litPendingBadge.Text = dt.Rows.Count.ToString();
        }

        private void BindAllUsers()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, Email, Role, City, IsVerified, IsActive, CreatedAt FROM Users ORDER BY CreatedAt DESC");

            rptUsers.DataSource = dt;
            rptUsers.DataBind();
        }

        protected void rptPending_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int userId = Convert.ToInt32(e.CommandArgument);

            if (e.CommandName == "Approve")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsVerified = 1 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User approved. They can now log in.", "alert-success");

                // Account-status changes pass a null event key: they are
                // mandatory and cannot be switched off in preferences.
                NotificationService.Notify(userId,
                    "Your FoodBridge account has been approved",
                    "Good news — an administrator has verified your account. You can now sign in and start using FoodBridge.",
                    NotifyType.System, null, "~/Login.aspx");
            }
            else if (e.CommandName == "Reject")
            {
                // Reject deletes the row (Phase 1 design decision), so the
                // recipient must be looked up *before* the delete — and there
                // is no user left to own an in-app notification afterwards, so
                // this is the one place that emails directly instead of via
                // Notify().
                DataTable who = DBHelper.ExecuteQuery(
                    "SELECT Email, FullName FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });

                DBHelper.ExecuteNonQuery(
                    "DELETE FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("Registration rejected and removed.", "alert-danger");

                if (who.Rows.Count > 0)
                {
                    NotificationService.SendEmail(
                        Convert.ToString(who.Rows[0]["Email"]),
                        "Your FoodBridge registration was not approved",
                        "<p>Dear " + Server.HtmlEncode(Convert.ToString(who.Rows[0]["FullName"])) + ",</p>"
                        + "<p>Thank you for your interest in FoodBridge. After review, your registration "
                        + "was not approved and the request has been closed. You are welcome to register "
                        + "again with complete and accurate details.</p>");
                }
            }

            BindStats();
            BindPendingUsers();
            BindAllUsers();
        }

        protected void rptUsers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int userId = Convert.ToInt32(e.CommandArgument);

            if (userId == SessionHelper.GetUserID())
            {
                ShowMessage("You cannot change the status of your own account.", "alert-danger");
                return;
            }

            if (e.CommandName == "Ban")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsActive = 0 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User suspended.", "alert-success");

                // The user row survives a ban, so this can be a normal
                // notification — they just cannot sign in to read the in-app
                // copy until reinstated, which is what the email is for.
                NotificationService.Notify(userId,
                    "Your FoodBridge account has been suspended",
                    "An administrator has suspended your account. You will not be able to sign in until it is reinstated. "
                    + "Please contact the FoodBridge team if you believe this is a mistake.",
                    NotifyType.System, null);
            }
            else if (e.CommandName == "Unban")
            {
                DBHelper.ExecuteNonQuery(
                    "UPDATE Users SET IsActive = 1 WHERE UserID = @UserID",
                    new SqlParameter[] { new SqlParameter("@UserID", userId) });
                ShowMessage("User reinstated.", "alert-success");

                NotificationService.Notify(userId,
                    "Your FoodBridge account has been reinstated",
                    "Your account has been reinstated by an administrator. You can sign in again.",
                    NotifyType.System, null, "~/Login.aspx");
            }

            BindAllUsers();
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblActionMessage.Text = message;
            lblActionMessage.CssClass = "alert " + cssClass;
            lblActionMessage.Visible = true;
        }

        // Markup helpers, referenced from admin-dashboard.aspx via <%# %> bindings
        protected string Initials(object fullName)
        {
            return SessionHelper.Initials(fullName?.ToString());
        }

        protected string StatusBadgeClass(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "badge-pending";
            if (!Convert.ToBoolean(isActive)) return "badge-rejected";
            return "badge-active";
        }

        protected string StatusBadgeText(object isVerified, object isActive)
        {
            if (!Convert.ToBoolean(isVerified)) return "Pending";
            if (!Convert.ToBoolean(isActive)) return "Suspended";
            return "Active";
        }

        /// <summary>
        /// Nine pipeline statuses collapsed into the four filter buttons. This
        /// is the only place the mapping lives, so a button and a row can never
        /// disagree about which bucket a status belongs to.
        /// </summary>
        protected string FilterBucket(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted": return "pending";
                case "Delivered": return "delivered";
                case "Rejected":
                case "Cancelled":
                case "Expired": return "closed";
                default: return "progress";   // Approved, Requested, Assigned, PickedUp
            }
        }

        protected string StatusBadge(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted": return "badge-pending";
                case "Delivered": return "badge-delivered";
                case "Rejected":
                case "Cancelled":
                case "Expired": return "badge-rejected";
                default: return "badge-accepted";
            }
        }

        /// <summary>
        /// The mockup's Action column held View buttons that went nowhere. This
        /// offers a link only where a screen actually exists to act on that
        /// status; everything else gets an em dash rather than a dead button.
        /// </summary>
        protected string ActionLink(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Posted":
                    return "<a class=\"btn-sm-outline\" href=\"" + ResolveUrl("~/Admin/food-approvals.aspx") + "\">Review</a>";
                case "Requested":
                    return "<a class=\"btn-sm-amber\" href=\"" + ResolveUrl("~/Admin/volunteer-assign.aspx") + "\">Assign</a>";
                default:
                    return "<span class=\"text-muted\">—</span>";
            }
        }

        /// <summary>Organisation name where there is one, otherwise the person's name.</summary>
        protected string PartyName(object orgName, object fullName)
        {
            string org = Convert.ToString(orgName);
            if (!string.IsNullOrWhiteSpace(org)) return org;

            string full = Convert.ToString(fullName);
            return string.IsNullOrWhiteSpace(full) ? "—" : full;
        }

        protected string Dash(object value)
        {
            string text = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(text) ? "—" : text;
        }

        protected string RoleBadgeClass(object role)
        {
            switch (role?.ToString())
            {
                case "Donor": return "badge-role-donor";
                case "NGO": return "badge-role-ngo";
                case "Volunteer": return "badge-role-vol";
                case "Admin": return "badge-role-admin";
                default: return "";
            }
        }
    }
}
