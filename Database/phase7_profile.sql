/* ============================================================================
   Phase 7 — Account Profile
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database. Every step is guarded, so
   re-running is safe.

   Almost nothing is needed here: every field the profile page edits already
   exists on dbo.Users (FullName, Email, Phone, Address, City, Bio,
   OrganizationName, BusinessType, RegNumber, PreferredNGOID), added by Phase 0
   from §2 of the roadmap. The live column list was verified against this
   database before writing the page rather than trusted from schema.sql, which
   has drifted before (Phase 0 on Users, Phase 4 on Notifications).

   WHY LastLoginAt
   ---------------
   The profile mockup's Account Info card promised a "Last Login" row. Nothing
   in this application recorded one.

   dbo.UserLoginLogs exists and looks like it should be the answer, but it is
   not usable: it is keyed by a Username string (dbo.Users has no Username
   column — this app authenticates by Email), it holds a single row, and no code
   anywhere reads or writes it. It predates the current schema and was left
   alone by Phase 0's reconciliation.

   So rather than fabricate the row or delete it, the value is now recorded for
   real: one nullable column, stamped by login.aspx.cs on each successful sign
   in. It is deliberately left NULL for existing accounts instead of being
   backfilled with GETDATE() — nobody's last login was the moment this script
   ran, and the page renders NULL honestly as "not recorded yet" rather than
   inventing a timestamp. Every account fills itself in on its next sign in.
   ============================================================================ */

/* --- 1. Users.LastLoginAt ------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.Users')
                 AND name = 'LastLoginAt')
BEGIN
    ALTER TABLE dbo.Users ADD LastLoginAt DATETIME NULL;
END
GO

/* --- 2. Verify the columns the profile page writes ------------------------

   Not a change — a guard. If any of these is missing the page would compile
   cleanly and fail at runtime on the first save, which is precisely the class
   of drift this project has hit twice. Running this script tells you now.
   ------------------------------------------------------------------------- */

DECLARE @missing NVARCHAR(500) = N'';

SELECT @missing = @missing + name + N' '
  FROM (VALUES ('FullName'), ('Email'), ('Phone'), ('Address'), ('City'),
               ('Bio'), ('OrganizationName'), ('BusinessType'), ('RegNumber'),
               ('PreferredNGOID'), ('LastLoginAt'), ('PasswordHash')) AS c(name)
 WHERE NOT EXISTS (SELECT 1 FROM sys.columns
                    WHERE object_id = OBJECT_ID('dbo.Users')
                      AND sys.columns.name = c.name);

IF LEN(@missing) > 0
    RAISERROR('Users is missing columns the profile page needs: %s', 16, 1, @missing);
ELSE
    PRINT 'Phase 7 OK - every profile column is present on dbo.Users.';
GO
