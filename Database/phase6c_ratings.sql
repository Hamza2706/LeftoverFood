/* ============================================================================
   Phase 6c — Ratings & Trust
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database. Every step is guarded, so
   re-running is safe.

   The Ratings table itself already exists (Phase 0 created it from the schema
   in §2 of the roadmap, and the live columns were verified to match). This
   script only fixes the constraints around it.

   WHY THE UNIQUE CONSTRAINT CHANGES
   ---------------------------------
   Phase 0 created UQ_Ratings_OnePerDonationPerRater on (DonationID, RaterID),
   following the roadmap's wording: "only once per donation".

   That turns out to contradict the feature the same roadmap describes one line
   earlier — "Donor rates NGO/Volunteer and vice versa". A completed delivery
   has three participants (donor, receiving NGO, volunteer), so each rater has
   *two* counterparties, not one. Under the old key a donor who rated the NGO
   could never rate the volunteer: the second insert would fail on a duplicate
   key with no way for the UI to offer it honestly.

   Widening to (DonationID, RaterID, RateeID) keeps the property that actually
   matters — you cannot rate the same person twice for the same donation — while
   allowing one rating per counterparty. The table is empty, so this is a
   straight swap with nothing to migrate.
   ============================================================================ */

/* --- 1. Replace the too-narrow unique constraint ------------------------- */

IF EXISTS (SELECT 1 FROM sys.key_constraints
           WHERE name = 'UQ_Ratings_OnePerDonationPerRater'
             AND parent_object_id = OBJECT_ID('dbo.Ratings'))
BEGIN
    ALTER TABLE dbo.Ratings DROP CONSTRAINT UQ_Ratings_OnePerDonationPerRater;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints
               WHERE name = 'UQ_Ratings_OnePerCounterparty'
                 AND parent_object_id = OBJECT_ID('dbo.Ratings'))
BEGIN
    ALTER TABLE dbo.Ratings ADD CONSTRAINT UQ_Ratings_OnePerCounterparty
        UNIQUE (DonationID, RaterID, RateeID);
END
GO

/* --- 2. Nobody rates themselves -----------------------------------------

   The application never offers it — the rateable-counterparty query excludes
   the current user, and a donor who is somehow also the volunteer on their own
   donation would otherwise be able to award themselves five stars. This is the
   database-level backstop for that, next to the existing 1-5 star check.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_Ratings_NoSelfRating'
                 AND parent_object_id = OBJECT_ID('dbo.Ratings'))
BEGIN
    ALTER TABLE dbo.Ratings ADD CONSTRAINT CK_Ratings_NoSelfRating
        CHECK (RaterID <> RateeID);
END
GO

/* --- 3. Index the ratee lookup -------------------------------------------

   Two hot read patterns, both keyed on who was rated rather than who rated:
   the "Reviews Received" list on ~/Ratings.aspx, and the AVG(Stars) recompute
   that writes Users.TrustScore after every submission.
   ------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Ratings_Ratee_Created'
                 AND object_id = OBJECT_ID('dbo.Ratings'))
BEGIN
    CREATE INDEX IX_Ratings_Ratee_Created
        ON dbo.Ratings (RateeID, CreatedAt DESC);
END
GO

/* --- 4. Backfill TrustScore ---------------------------------------------

   Users.TrustScore already exists (Phase 0). It is a cached rolling average of
   ratings received, recomputed by the application on every insert. This sets
   the starting value so a user with no ratings reads as NULL ("no rating yet")
   rather than as a misleading 0.00.
   ------------------------------------------------------------------------- */

UPDATE u
   SET u.TrustScore = r.AvgStars
  FROM dbo.Users u
  JOIN (SELECT RateeID, AVG(CAST(Stars AS DECIMAL(3,2))) AS AvgStars
          FROM dbo.Ratings
         GROUP BY RateeID) r ON r.RateeID = u.UserID;
GO

UPDATE dbo.Users
   SET TrustScore = NULL
 WHERE UserID NOT IN (SELECT DISTINCT RateeID FROM dbo.Ratings);
GO
