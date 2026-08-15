/* ============================================================================
   Phase 6b — Fraud / Duplicate Detection
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database. Every step is guarded, so
   re-running is safe.

   FraudFlags already exists (Phase 0 created it from §2 of the roadmap; the
   live columns were verified and match, and there are no CHECK constraints on
   FlagType or Status — both are plain NVARCHAR, so the application owns that
   vocabulary). This script only adds what the review queue needs.
   ============================================================================ */

/* --- 1. When a flag was reviewed -----------------------------------------

   §2 gave the table a ReviewedBy but no timestamp, so "who closed this" was
   recorded and "when" was lost. Same gap Phase 6a filled with EndedAt on
   EmergencyBroadcasts, and it matters more here: a review queue where you
   cannot tell a flag closed an hour ago from one closed in March is not much
   of an audit trail.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.FraudFlags')
                 AND name = 'ReviewedAt')
BEGIN
    ALTER TABLE dbo.FraudFlags ADD ReviewedAt DATETIME NULL;
END
GO

/* --- 2. Queue read pattern ----------------------------------------------

   The admin page opens on "Open flags, newest first" every single time.
   -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FraudFlags_Status_Flagged'
                 AND object_id = OBJECT_ID('dbo.FraudFlags'))
BEGIN
    CREATE INDEX IX_FraudFlags_Status_Flagged
        ON dbo.FraudFlags (Status, FlaggedAt DESC);
END
GO

/* --- 3. Duplicate-flag suppression ---------------------------------------

   Every rule runs inline on ordinary user actions (posting, cancelling,
   confirming receipt) because this app has no background job host. That means
   a rule keyed on an account-level pattern — "this donor has cancelled three
   times" — re-evaluates to true on every subsequent action and would raise the
   same flag again and again, burying the queue in copies of one finding.

   FraudDetectionService.Raise() suppresses that by checking for an existing
   Open flag with the same subject first. This index is what makes that check
   cheap, since it now runs on every donation posted.

   Deliberately NOT a unique constraint: once an admin reviews or dismisses a
   flag, the same pattern recurring later is a genuinely new finding and must
   be allowed to raise a fresh row.
   -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_FraudFlags_User_Type_Status'
                 AND object_id = OBJECT_ID('dbo.FraudFlags'))
BEGIN
    CREATE INDEX IX_FraudFlags_User_Type_Status
        ON dbo.FraudFlags (UserID, FlagType, Status);
END
GO
