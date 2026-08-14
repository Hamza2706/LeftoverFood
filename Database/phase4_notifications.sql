/* ============================================================================
   Phase 4 — Notifications
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database.

   The Notifications table itself already exists (created by schema.sql during
   Phase 0). This script only adds what Phase 4 needs on top of it:

     1. Notifications.LinkUrl  — makes a notification clickable through to the
                                 page it is about (e.g. the donor tracking page).
                                 Additive, nullable, so existing rows are fine.
     2. NotificationPreferences — per-user, per-event opt-in/out, backing the
                                 toggle switches on Donor/notifications.aspx.

   Both steps are guarded, so re-running this script is safe.
   ============================================================================ */

/* --- 0. Reconcile the live Notifications table with schema.sql -----------

   The live table was found to have drifted from schema.sql (same class of
   divergence Phase 0 found on Users/FoodDonations):

     - the `Type` column (Approval|Delivery|Emergency|System) was missing
       entirely, even though schema.sql declares it NOT NULL;
     - `Message` was varchar(500) rather than nvarchar(500), which would
       silently mangle non-ASCII text — the app runs requestEncoding="utf-8"
       and donation descriptions are free text, so this matters.

   The table held 0 rows when this was found, so both are fixed in place with
   no data loss. ---------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.Notifications')
                 AND name = 'Type')
BEGIN
    ALTER TABLE dbo.Notifications
        ADD [Type] NVARCHAR(30) NOT NULL
            CONSTRAINT DF_Notifications_Type DEFAULT 'System';
END
GO

IF EXISTS (SELECT 1 FROM sys.columns c
           JOIN sys.types t ON t.user_type_id = c.user_type_id
           WHERE c.object_id = OBJECT_ID('dbo.Notifications')
             AND c.name = 'Message'
             AND t.name = 'varchar')
BEGIN
    ALTER TABLE dbo.Notifications ALTER COLUMN Message NVARCHAR(500) NOT NULL;
END
GO

/* --- 1. Notifications.LinkUrl ------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.Notifications')
                 AND name = 'LinkUrl')
BEGIN
    ALTER TABLE dbo.Notifications ADD LinkUrl NVARCHAR(300) NULL;
END
GO

/* Index the read path: "my unread notifications, newest first" is run on every
   page load (the topbar bell badge), so it is worth an index. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Notifications_User_Read'
                 AND object_id = OBJECT_ID('dbo.Notifications'))
BEGIN
    CREATE INDEX IX_Notifications_User_Read
        ON dbo.Notifications (UserID, IsRead, CreatedAt DESC);
END
GO

/* --- 2. NotificationPreferences ----------------------------------------- */

IF OBJECT_ID('dbo.NotificationPreferences', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationPreferences (
        PreferenceID     INT IDENTITY(1,1) PRIMARY KEY,
        UserID           INT             NOT NULL,
        EventKey         NVARCHAR(50)    NOT NULL,
        EmailEnabled     BIT             NOT NULL DEFAULT 1,
        InAppEnabled     BIT             NOT NULL DEFAULT 1,
        UpdatedAt        DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_NotifPrefs_User FOREIGN KEY (UserID)
            REFERENCES dbo.Users(UserID),
        /* One row per user per event — lets the page upsert safely and stops
           duplicate preference rows drifting out of sync. */
        CONSTRAINT UQ_NotifPrefs_User_Event UNIQUE (UserID, EventKey)
    );
END
GO

/* No seeding.

   A user with no row for an event is treated as "opted in" by
   NotificationService (see PrefersEmail / PrefersInApp). That keeps this table
   sparse — it only ever stores deliberate opt-outs — and means new users and
   newly added event keys work without a backfill. */
