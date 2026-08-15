/* ============================================================================
   Phase 6a — Emergency Mode
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database. Every step is guarded, so
   re-running is safe.

   EmergencyBroadcasts already exists (Phase 0 created it from §2 of the
   roadmap; the live columns were verified against that definition and match).
   This script adds the three things the feature actually needs on top.
   ============================================================================ */

/* --- 1. When a broadcast ended ------------------------------------------

   §2 gave the table an IsActive bit but no end timestamp, so switching an
   emergency off would lose when it was switched off. The history panel needs
   to show a real date range ("Apr 10 – Apr 11") rather than the open-ended
   start date, and without this the only honest thing it could print is the
   start.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.EmergencyBroadcasts')
                 AND name = 'EndedAt')
BEGIN
    ALTER TABLE dbo.EmergencyBroadcasts ADD EndedAt DATETIME NULL;
END
GO

/* --- 2. How many people it actually reached ------------------------------

   Recorded at send time rather than recomputed later, because the audience is
   a moving target: users get verified, banned, or change city afterwards, so
   re-deriving "who did this reach" from today's Users table would quietly
   produce a different number every time it is displayed.

   The original mockup's history showed "1,200 meals distributed in 24hrs" —
   a figure nothing in this system can produce. Recipient count is the number
   this feature genuinely knows.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.EmergencyBroadcasts')
                 AND name = 'RecipientCount')
BEGIN
    ALTER TABLE dbo.EmergencyBroadcasts ADD RecipientCount INT NULL;
END
GO

/* The status banner asks "is there an active emergency right now" on every
   load of the admin page, and the history list is newest-first. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_EmergencyBroadcasts_Active_Created'
                 AND object_id = OBJECT_ID('dbo.EmergencyBroadcasts'))
BEGIN
    CREATE INDEX IX_EmergencyBroadcasts_Active_Created
        ON dbo.EmergencyBroadcasts (IsActive, CreatedAt DESC);
END
GO

/* --- 3. Priority flag on donations ---------------------------------------

   §6a of the roadmap: "Consider a simple priority boolean on FoodDonations
   that Admin can flag during an active emergency so those donations sort
   first everywhere."

   Deliberately a plain admin-set flag rather than a computed urgency score.
   The mockup showed 🔴 URGENT / 🟡 HIGH / 🟢 NORMAL bands as if the system
   derived them, but every input that would drive such a score (expiry, volume)
   is already visible in the queue and sorted on directly — an extra derived
   band would just be a second, less legible copy of the sort order. What the
   admin cannot express any other way is "this one matters more than the sort
   suggests", which is exactly what a manual flag is for.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.FoodDonations')
                 AND name = 'IsPriority')
BEGIN
    ALTER TABLE dbo.FoodDonations ADD IsPriority BIT NOT NULL
        CONSTRAINT DF_FoodDonations_IsPriority DEFAULT 0;
END
GO
