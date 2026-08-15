using System;
using System.Data;
using System.Data.SqlClient;
using System.Text.RegularExpressions;

namespace LeftoverFoodSystem
{
    /// <summary>
    /// Flag types written to FraudFlags.FlagType.
    ///
    /// §2 of the roadmap sketched DuplicateDonor | FakeLocation | RepeatedCancel
    /// as a comment; there is no CHECK constraint, so this class is the real
    /// vocabulary. The names below say what the rule actually looks at rather
    /// than what it concludes — "UnverifiableLocation" rather than
    /// "FakeLocation", because an address that fails to geocode is very often a
    /// typo or a place the gazetteer simply does not know, not a lie.
    /// </summary>
    public static class FlagType
    {
        public const string DuplicateDonation = "DuplicateDonation";
        public const string RapidPosting = "RapidPosting";
        public const string RepeatedCancel = "RepeatedCancel";
        public const string QuantityMismatch = "QuantityMismatch";
        public const string UnverifiableLocation = "UnverifiableLocation";
    }

    public static class FlagStatus
    {
        public const string Open = "Open";
        public const string Reviewed = "Reviewed";
        public const string Dismissed = "Dismissed";
    }

    /// <summary>
    /// Phase 6b. Rule-based duplicate and fake-donor detection.
    ///
    /// Rule-based, not ML — the proposal's own wording is "time and
    /// location-based checks", and there is neither labelled training data nor
    /// anywhere to run a model in an ASP.NET Web Forms request.
    ///
    /// WHERE THE RULES RUN
    /// -------------------
    /// Inline, on the user actions that could trigger them (posting a donation,
    /// cancelling one, confirming receipt), exactly as the roadmap chose:
    /// building a Windows Service or scheduled job for an FYP is
    /// disproportionate, and this app has no background host — the same
    /// constraint that left ExpiryWarning dormant in Phase 4 and killed the
    /// Ramadan time windows in 6a. A manual "Run scan now" on the admin page
    /// covers re-checking history, replacing the mockup's claimed 2:00 AM
    /// automatic scan, which nothing could have been running.
    ///
    /// NOTHING HERE EVER BLOCKS A USER
    /// -------------------------------
    /// Per the roadmap's own risk note, every rule produces an entry in an
    /// admin review queue and nothing else. No account is suspended, no
    /// donation is hidden, and no posting is refused automatically. A
    /// legitimate restaurant posting the same meal from the same address every
    /// evening is the *expected* shape of this data, so thresholds are set
    /// conservatively and a human always decides.
    ///
    /// Like NotificationService, every public method is fail-soft: a detection
    /// problem must never break the donation that triggered it.
    /// </summary>
    public class FraudDetectionService
    {
        // --- Thresholds ---------------------------------------------------
        // Deliberately loose. A false positive costs an admin's attention and
        // erodes trust in the whole queue; a missed duplicate costs very
        // little, because the donation still goes through normal approval.

        /// <summary>Two posts from one donor at the same address and category inside this window look like a double-submit.</summary>
        private const int DuplicateWindowHours = 6;

        /// <summary>Posts by one donor within an hour before it is worth a look.</summary>
        private const int RapidPostingCount = 3;

        /// <summary>Cancelled donations by one donor before it is worth a look.</summary>
        private const int RepeatedCancelCount = 3;

        /// <summary>Received quantity below this fraction of the claim is a real shortfall, not rounding.</summary>
        private const double QuantityShortfallRatio = 0.5;

        // ------------------------------------------------------------------
        // Entry points
        // ------------------------------------------------------------------

        /// <summary>
        /// Runs at the moment a donation is posted. Safe to call always —
        /// swallows its own exceptions so a detection fault can never stop a
        /// donation from being created.
        /// </summary>
        public static void CheckNewDonation(int donationId, int donorId)
        {
            try
            {
                CheckDuplicateDonation(donationId, donorId);
                CheckRapidPosting(donorId);
                CheckUnverifiableLocation(donationId, donorId);
            }
            catch (Exception ex)
            {
                LogError("CheckNewDonation(donation=" + donationId + ")", ex);
            }
        }

        /// <summary>Runs when a donor cancels a donation.</summary>
        public static void CheckCancellation(int donorId)
        {
            try
            {
                CheckRepeatedCancel(donorId);
            }
            catch (Exception ex)
            {
                LogError("CheckCancellation(donor=" + donorId + ")", ex);
            }
        }

        /// <summary>Runs when an NGO confirms what it actually received.</summary>
        public static void CheckReceipt(int donationId)
        {
            try
            {
                CheckQuantityMismatch(donationId);
            }
            catch (Exception ex)
            {
                LogError("CheckReceipt(donation=" + donationId + ")", ex);
            }
        }

        /// <summary>
        /// Re-runs every rule across all existing data, for the admin's manual
        /// scan. Returns how many new flags were raised.
        ///
        /// This is what makes the rules usable on history rather than only on
        /// activity from now on — the inline hooks cannot see anything that
        /// happened before they existed.
        /// </summary>
        public static int RunFullScan()
        {
            int before = OpenFlagCount();

            try
            {
                // Every donor who has ever posted, re-checked. The set is small
                // at this scale; if it ever is not, this is the method that
                // needs a queue, not the inline hooks.
                DataTable donors = DBHelper.ExecuteQuery(
                    "SELECT DISTINCT DonorID FROM FoodDonations");

                foreach (DataRow r in donors.Rows)
                {
                    int donorId = Convert.ToInt32(r["DonorID"]);
                    CheckRapidPosting(donorId);
                    CheckRepeatedCancel(donorId);
                }

                DataTable donations = DBHelper.ExecuteQuery(
                    "SELECT DonationID, DonorID FROM FoodDonations");

                foreach (DataRow r in donations.Rows)
                {
                    int donationId = Convert.ToInt32(r["DonationID"]);
                    int donorId = Convert.ToInt32(r["DonorID"]);

                    CheckDuplicateDonation(donationId, donorId);
                    CheckUnverifiableLocation(donationId, donorId);
                    CheckQuantityMismatch(donationId);
                }
            }
            catch (Exception ex)
            {
                LogError("RunFullScan", ex);
            }

            return Math.Max(0, OpenFlagCount() - before);
        }

        // ------------------------------------------------------------------
        // Rules
        // ------------------------------------------------------------------

        /// <summary>
        /// The roadmap's primary rule: the same donor posting near-identical
        /// donations in quick succession.
        ///
        /// "Near-identical" is same pickup address AND same category, which is
        /// narrow on purpose. Address alone would flag every restaurant that
        /// donates twice in an evening — which is the behaviour this platform
        /// exists to encourage.
        ///
        /// Cancelled and Rejected siblings are excluded: reposting after a
        /// rejection is the correct response to a rejection, not a duplicate.
        /// </summary>
        private static void CheckDuplicateDonation(int donationId, int donorId)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 1 other.DonationID, other.FoodDescription, other.CreatedAt
                    FROM FoodDonations d
                    JOIN FoodDonations other
                      ON other.DonorID = d.DonorID
                     AND other.DonationID <> d.DonationID
                     AND other.PickupAddress = d.PickupAddress
                     AND other.Category = d.Category
                     AND other.Status NOT IN ('Cancelled', 'Rejected')
                     AND ABS(DATEDIFF(HOUR, other.CreatedAt, d.CreatedAt)) <= @Window
                   WHERE d.DonationID = @DonationID
                     AND d.Status NOT IN ('Cancelled', 'Rejected')
                   ORDER BY other.CreatedAt DESC",
                new SqlParameter[]
                {
                    new SqlParameter("@DonationID", donationId),
                    new SqlParameter("@Window", DuplicateWindowHours)
                });

            if (dt.Rows.Count == 0) return;

            Raise(donorId, donationId, FlagType.DuplicateDonation,
                  "Near-duplicate of donation #" + dt.Rows[0]["DonationID"]
                  + " (\"" + Convert.ToString(dt.Rows[0]["FoodDescription"]) + "\"): same pickup address and "
                  + "category, posted within " + DuplicateWindowHours + " hours. May simply be a double submission.");
        }

        /// <summary>
        /// Burst posting. The mockup's own stated threshold was "3+ donations
        /// posted within 1 hour", kept as-is.
        /// </summary>
        private static void CheckRapidPosting(int donorId)
        {
            object count = DBHelper.ExecuteScalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE DonorID = @DonorID
                     AND CreatedAt >= DATEADD(HOUR, -1, GETDATE())
                     AND Status NOT IN ('Cancelled', 'Rejected')",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) });

            int n = count == null || count == DBNull.Value ? 0 : Convert.ToInt32(count);
            if (n < RapidPostingCount) return;

            Raise(donorId, null, FlagType.RapidPosting,
                  n + " donations posted in the last hour. Unusual volume — worth confirming the account is genuine.");
        }

        /// <summary>
        /// Repeat cancellations.
        ///
        /// SCOPE CORRECTION: the roadmap describes this as "when an NGO/
        /// Volunteer repeatedly cancels after accepting". No such action exists
        /// anywhere in the app — an NGO cannot un-accept and a volunteer cannot
        /// drop an assignment; the only cancel path is a donor cancelling their
        /// own donation while it is still Posted (Phase 2), and the only other
        /// negative transition is an admin rejection. So this rule is
        /// donor-only, and the NGO/volunteer half of it cannot be written until
        /// that action exists.
        /// </summary>
        private static void CheckRepeatedCancel(int donorId)
        {
            object count = DBHelper.ExecuteScalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE DonorID = @DonorID AND Status = 'Cancelled'",
                new SqlParameter[] { new SqlParameter("@DonorID", donorId) });

            int n = count == null || count == DBNull.Value ? 0 : Convert.ToInt32(count);
            if (n < RepeatedCancelCount) return;

            Raise(donorId, null, FlagType.RepeatedCancel,
                  n + " donations cancelled by this donor. Repeated cancellations waste NGO and volunteer time.");
        }

        /// <summary>
        /// Claimed versus actually-received quantity, using the figure the NGO
        /// wrote down at Confirm Receipt (Phase 3).
        ///
        /// Both sides are awkward: FoodDonations.Quantity is free text ("30
        /// Plates", "1 Kg") and so is FoodRequests.ActualQuantityReceived
        /// ("28 Plates"). Servings is a real INT and is what the claim is read
        /// from; the received side has to be parsed for a leading number, and
        /// anything unparseable is skipped rather than guessed at. Units are
        /// not reconciled — "1 Kg" against "10 Plates" is not a comparison this
        /// data supports, which is why only a large shortfall against Servings
        /// counts.
        /// </summary>
        private static void CheckQuantityMismatch(int donationId)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonorID, d.Servings, d.FoodDescription, r.ActualQuantityReceived
                    FROM FoodDonations d
                    JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                   WHERE d.DonationID = @DonationID
                     AND d.Servings IS NOT NULL AND d.Servings > 0
                     AND r.ActualQuantityReceived IS NOT NULL",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (dt.Rows.Count == 0) return;

            int claimed = Convert.ToInt32(dt.Rows[0]["Servings"]);
            int? received = LeadingNumber(Convert.ToString(dt.Rows[0]["ActualQuantityReceived"]));

            if (received == null) return;                       // unparseable — say nothing
            if (received.Value >= claimed * QuantityShortfallRatio) return;

            Raise(Convert.ToInt32(dt.Rows[0]["DonorID"]), donationId, FlagType.QuantityMismatch,
                  "Claimed " + claimed + " servings but the receiving NGO recorded \""
                  + Convert.ToString(dt.Rows[0]["ActualQuantityReceived"]) + "\" — under "
                  + (int)(QuantityShortfallRatio * 100) + "% of the claim.");
        }

        /// <summary>
        /// The location-based check, built on Phase 5's GeoPrecision.
        ///
        /// Only a total geocoding failure (NULL) counts. Phase 5 established
        /// that most real addresses here resolve to city level rather than
        /// exactly, so treating 'City' as suspicious would flag nearly every
        /// donation in the database and make the queue useless. The wording of
        /// the flag says "could not be located", not "is fake" — the far more
        /// likely cause is a typo or a place Nominatim does not know.
        /// </summary>
        private static void CheckUnverifiableLocation(int donationId, int donorId)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT PickupAddress, City FROM FoodDonations
                   WHERE DonationID = @DonationID
                     AND GeoPrecision IS NULL
                     AND Latitude IS NULL
                     AND Status NOT IN ('Cancelled', 'Rejected')",
                new SqlParameter[] { new SqlParameter("@DonationID", donationId) });

            if (dt.Rows.Count == 0) return;

            Raise(donorId, donationId, FlagType.UnverifiableLocation,
                  "Pickup address could not be located on the map: \""
                  + Convert.ToString(dt.Rows[0]["PickupAddress"]) + ", "
                  + Convert.ToString(dt.Rows[0]["City"]) + "\". Often a typo rather than a false address.");
        }

        // ------------------------------------------------------------------
        // Raising and reviewing
        // ------------------------------------------------------------------

        /// <summary>
        /// Records a flag, unless an identical one is already sitting open.
        ///
        /// The suppression is what makes inline rules survivable: an
        /// account-level rule like RepeatedCancel is still true on the donor's
        /// next action and every action after that, so without this the queue
        /// would fill with copies of one finding. Once a flag is Reviewed or
        /// Dismissed the same pattern recurring is treated as new and raises
        /// again — an admin having looked once should not blind the system
        /// forever.
        /// </summary>
        public static void Raise(int? userId, int? donationId, string flagType, string details)
        {
            try
            {
                object existing = DBHelper.ExecuteScalar(
                    @"SELECT COUNT(*) FROM FraudFlags
                       WHERE Status = 'Open'
                         AND FlagType = @FlagType
                         AND ISNULL(UserID, -1) = ISNULL(@UserID, -1)
                         AND ISNULL(DonationID, -1) = ISNULL(@DonationID, -1)",
                    new SqlParameter[]
                    {
                        new SqlParameter("@FlagType", flagType),
                        new SqlParameter("@UserID", (object)userId ?? DBNull.Value),
                        new SqlParameter("@DonationID", (object)donationId ?? DBNull.Value)
                    });

                if (Convert.ToInt32(existing) > 0) return;

                DBHelper.ExecuteNonQuery(
                    @"INSERT INTO FraudFlags (UserID, DonationID, FlagType, Details, Status)
                      VALUES (@UserID, @DonationID, @FlagType, @Details, 'Open')",
                    new SqlParameter[]
                    {
                        new SqlParameter("@UserID", (object)userId ?? DBNull.Value),
                        new SqlParameter("@DonationID", (object)donationId ?? DBNull.Value),
                        new SqlParameter("@FlagType", flagType),
                        new SqlParameter("@Details", Truncate(details, 500))
                    });

                NotifyAdmins(flagType, details);
            }
            catch (Exception ex)
            {
                LogError("Raise(" + flagType + ")", ex);
            }
        }

        /// <summary>
        /// Tells admins a flag was raised. Uses the System type rather than
        /// Emergency — a duplicate donation is not an emergency, and treating
        /// it as one would devalue the notifications that are.
        /// </summary>
        private static void NotifyAdmins(string flagType, string details)
        {
            NotificationService.NotifyRole("Admin",
                "Fraud check raised a flag",
                "A " + Humanise(flagType) + " flag was raised. " + details
                + " Review it in Fraud Detection — nothing has been blocked automatically.",
                NotifyType.System, null, "~/Admin/fraud-detection.aspx");
        }

        /// <summary>Closes a flag as Reviewed or Dismissed.</summary>
        public static void Resolve(int flagId, string status, int adminId)
        {
            DBHelper.ExecuteNonQuery(
                @"UPDATE FraudFlags
                     SET Status = @Status, ReviewedBy = @AdminID, ReviewedAt = GETDATE()
                   WHERE FlagID = @FlagID AND Status = 'Open'",
                new SqlParameter[]
                {
                    new SqlParameter("@Status", status),
                    new SqlParameter("@AdminID", adminId),
                    new SqlParameter("@FlagID", flagId)
                });
        }

        public static int OpenFlagCount()
        {
            try
            {
                object o = DBHelper.ExecuteScalar(
                    "SELECT COUNT(*) FROM FraudFlags WHERE Status = 'Open'");
                return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
            }
            catch (Exception ex)
            {
                LogError("OpenFlagCount", ex);
                return 0;
            }
        }

        // ------------------------------------------------------------------
        // Helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// First integer in a free-text quantity ("28 Plates" -> 28). Returns
        /// null when there is no number to read, which the caller treats as
        /// "cannot compare" rather than as zero.
        /// </summary>
        public static int? LeadingNumber(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return null;

            Match m = Regex.Match(text, @"\d+");
            if (!m.Success) return null;

            int value;
            return int.TryParse(m.Value, out value) ? value : (int?)null;
        }

        /// <summary>"QuantityMismatch" -> "quantity mismatch", for prose.</summary>
        public static string Humanise(string flagType)
        {
            if (string.IsNullOrEmpty(flagType)) return "";
            return Regex.Replace(flagType, "(?<!^)([A-Z])", " $1").ToLower();
        }

        private static string Truncate(string text, int max)
        {
            if (string.IsNullOrEmpty(text)) return text;
            return text.Length <= max ? text : text.Substring(0, max - 1) + "…";
        }

        /// <summary>
        /// Shares NotificationService's error log rather than opening a second
        /// one — an admin chasing "why did nothing happen" should have one file
        /// to read, not two.
        /// </summary>
        private static void LogError(string context, Exception ex)
        {
            NotificationService.LogExternalError("FraudDetection." + context, ex);
        }
    }
}
