using System;
using System.Data;
using System.Data.SqlClient;

namespace LeftoverFoodSystem
{
    /// <summary>Outcome of a moderation action, ready to render as an alert.</summary>
    public class ModerationResult
    {
        public bool Ok { get; set; }
        public string Message { get; set; }

        /// <summary>Bootstrap alert modifier — alert-success / -warning / -danger.</summary>
        public string CssClass { get; set; }

        public static ModerationResult Success(string message)
        {
            return new ModerationResult { Ok = true, Message = message, CssClass = "alert-success" };
        }

        public static ModerationResult Warn(string message)
        {
            return new ModerationResult { Ok = false, Message = message, CssClass = "alert-warning" };
        }

        public static ModerationResult Fail(string message)
        {
            return new ModerationResult { Ok = false, Message = message, CssClass = "alert-danger" };
        }
    }

    /// <summary>
    /// Account moderation: approve, reject, suspend, reinstate (Phase 10).
    ///
    /// Phase 1 wrote these inline on Admin/admin-dashboard.aspx.cs and said a
    /// service layer would be premature "since there's only one consumer".
    /// Admin/users.aspx is now a second consumer, which is the condition that
    /// produced NotificationService in Phase 4 and FraudDetectionService in 6b.
    ///
    /// The reason to share them is not line count — it is that each action has
    /// a guard that must not exist in only one of the two pages:
    ///
    ///   * an admin must not be able to suspend their own account
    ///   * approve must only affect a still-pending row
    ///   * reject must read the recipient BEFORE the delete, because the row it
    ///     needs is the row it is about to remove
    ///
    /// Every statement is scoped so a forged UserID cannot do anything a
    /// legitimate one could not; rowsAffected is checked before notifying, so a
    /// lost race never sends a message about something that did not happen —
    /// the pattern Phases 2, 3 and 4 established.
    /// </summary>
    public static class UserAdminService
    {
        /// <summary>
        /// Approve a pending registration. Scoped to IsVerified = 0 so
        /// double-clicking cannot re-notify an already-approved user.
        /// </summary>
        public static ModerationResult Verify(int userId)
        {
            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE Users SET IsVerified = 1 WHERE UserID = @UserID AND IsVerified = 0",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            if (rows == 0)
                return ModerationResult.Warn("That account was already approved.");

            // Account-status changes pass a null event key: mandatory, and not
            // something a user may switch off in preferences.
            NotificationService.Notify(userId,
                "Your FoodBridge account has been approved",
                "Good news — an administrator has verified your account. You can now sign in and start using FoodBridge.",
                NotifyType.System, null, "~/Login.aspx");

            return ModerationResult.Success("User approved. They can now log in.");
        }

        /// <summary>
        /// Reject a pending registration by deleting it (Phase 1's design
        /// decision — there is no rejected state to move it to).
        ///
        /// The recipient is looked up first because the delete removes the row
        /// that owns their email, and there is no user left afterwards to own
        /// an in-app notification. This is the one place that emails directly
        /// rather than going through Notify().
        /// </summary>
        public static ModerationResult Reject(int userId)
        {
            DataTable who = DBHelper.ExecuteQuery(
                "SELECT Email, FullName FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            int rows = DBHelper.ExecuteNonQuery(
                "DELETE FROM Users WHERE UserID = @UserID AND IsVerified = 0",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            if (rows == 0)
                return ModerationResult.Warn("That registration is no longer pending, so it was not removed.");

            if (who.Rows.Count > 0)
            {
                string name = Convert.ToString(who.Rows[0]["FullName"]);

                NotificationService.SendEmail(
                    Convert.ToString(who.Rows[0]["Email"]),
                    "Your FoodBridge registration was not approved",
                    "<p>Dear " + System.Web.HttpUtility.HtmlEncode(name) + ",</p>"
                    + "<p>Thank you for your interest in FoodBridge. After review, your registration "
                    + "was not approved and the request has been closed. You are welcome to register "
                    + "again with complete and accurate details.</p>");
            }

            return ModerationResult.Success("Registration rejected and removed.");
        }

        /// <summary>
        /// Suspend an account. Writes Users.IsActive, which login.aspx.cs
        /// already checks — there is deliberately no second notion of
        /// "blocked" to keep in step (Phase 6b reuses this same switch).
        /// </summary>
        public static ModerationResult Ban(int userId, int actingAdminId)
        {
            if (userId == actingAdminId)
                return ModerationResult.Fail("You cannot change the status of your own account.");

            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE Users SET IsActive = 0 WHERE UserID = @UserID AND IsActive = 1",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            if (rows == 0)
                return ModerationResult.Warn("That account is already suspended.");

            // The row survives a ban, so this can be a normal notification —
            // they simply cannot sign in to read the in-app copy until
            // reinstated, which is what the email is for.
            NotificationService.Notify(userId,
                "Your FoodBridge account has been suspended",
                "An administrator has suspended your account. You will not be able to sign in until it is reinstated. "
                + "Please contact the FoodBridge team if you believe this is a mistake.",
                NotifyType.System, null);

            return ModerationResult.Success("User suspended.");
        }

        /// <summary>Reinstate a suspended account.</summary>
        public static ModerationResult Unban(int userId, int actingAdminId)
        {
            if (userId == actingAdminId)
                return ModerationResult.Fail("You cannot change the status of your own account.");

            int rows = DBHelper.ExecuteNonQuery(
                "UPDATE Users SET IsActive = 1 WHERE UserID = @UserID AND IsActive = 0",
                new SqlParameter[] { new SqlParameter("@UserID", userId) });

            if (rows == 0)
                return ModerationResult.Warn("That account is already active.");

            NotificationService.Notify(userId,
                "Your FoodBridge account has been reinstated",
                "Your account has been reinstated by an administrator. You can sign in again.",
                NotifyType.System, null, "~/Login.aspx");

            return ModerationResult.Success("User reinstated.");
        }
    }
}
