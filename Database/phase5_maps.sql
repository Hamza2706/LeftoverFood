/* ============================================================================
   Phase 5 — Maps & Volunteer Location Tracking
   ----------------------------------------------------------------------------
   Run once against the LeftoverFood database. Every step is guarded, so
   re-running is safe.

   FoodDonations.Latitude / .Longitude already exist (Phase 0 created them and
   the live table was verified to match), so there is nothing to add there —
   Phase 5 just starts populating them via server-side geocoding.

   What this script adds is the volunteer live-location feature:

     1. Users.ShareLocation  — explicit per-volunteer opt-in, default OFF.
     2. VolunteerLocations   — position pings during an active delivery.

   PRIVACY NOTE
   ------------
   This table stores a real person's GPS position. The design deliberately
   constrains it:

     - Nothing is ever recorded unless the volunteer has switched ShareLocation
       on themselves; it defaults to 0 (off) and no other role can set it.
     - Rows are always tied to an AssignmentID, so a position only exists in
       the context of a delivery the volunteer accepted — there is no
       always-on tracking.
     - The application stops reporting once the assignment reaches Delivered.
     - Reads are authorised per-donation (donor, receiving NGO, admin only) in
       LocationHandler.ashx, never by volunteer ID alone.
   ============================================================================ */

/* --- 0. Geocode precision on donations -----------------------------------

   Real addresses in this data often do not resolve — of the six donations
   present when Phase 5 was built, only one matched Nominatim exactly (the rest
   were test data or contained typos). Showing no map at all for 5 in 6
   donations makes the feature look broken.

   The compromise is a city-level fallback, but ONLY when it is labelled as
   such: a pin dropped at the city centre while implying it is the pickup point
   would be worse than no map. This column records which one we got, so the UI
   can say "approximate — city level" instead of pretending to street accuracy.

     'Exact' — Nominatim matched the full pickup address
     'City'  — only the city resolved; treat the pin as indicative
     NULL    — nothing resolved; show the address as text, no map
   -------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.FoodDonations')
                 AND name = 'GeoPrecision')
BEGIN
    ALTER TABLE dbo.FoodDonations ADD GeoPrecision NVARCHAR(20) NULL;
END
GO

/* The one row backfilled before this column existed was an exact match. */
UPDATE dbo.FoodDonations
   SET GeoPrecision = 'Exact'
 WHERE Latitude IS NOT NULL AND GeoPrecision IS NULL;
GO

/* --- 1. Consent flag ----------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.Users')
                 AND name = 'ShareLocation')
BEGIN
    ALTER TABLE dbo.Users ADD ShareLocation BIT NOT NULL
        CONSTRAINT DF_Users_ShareLocation DEFAULT 0;
END
GO

/* --- 2. Position pings --------------------------------------------------- */

IF OBJECT_ID('dbo.VolunteerLocations', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.VolunteerLocations (
        LocationID    INT IDENTITY(1,1) PRIMARY KEY,
        VolunteerID   INT             NOT NULL,
        AssignmentID  INT             NOT NULL,
        Latitude      DECIMAL(9,6)    NOT NULL,
        Longitude     DECIMAL(9,6)    NOT NULL,
        /* Browser-reported accuracy in metres. Kept so the UI can say "within
           ~50 m" instead of implying a precision the device never had. */
        Accuracy      DECIMAL(9,2)    NULL,
        RecordedAt    DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_VolLoc_Volunteer FOREIGN KEY (VolunteerID)
            REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_VolLoc_Assignment FOREIGN KEY (AssignmentID)
            REFERENCES dbo.DeliveryAssignments(AssignmentID)
    );
END
GO

/* The only read pattern is "latest ping for this assignment", polled while a
   tracking page is open, so index for exactly that. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_VolLoc_Assignment_Recorded'
                 AND object_id = OBJECT_ID('dbo.VolunteerLocations'))
BEGIN
    CREATE INDEX IX_VolLoc_Assignment_Recorded
        ON dbo.VolunteerLocations (AssignmentID, RecordedAt DESC);
END
GO

/* --- 3. Geocode cache for addresses that are not donations ---------------

   NGO drop-off points come from Users.Address, which has no lat/lng columns
   and is shared by all four roles. Rather than widening Users for one feature,
   resolved addresses are cached here and keyed by the address text itself.
   This also keeps us inside Nominatim's usage policy, which asks that results
   be cached rather than re-requested. ------------------------------------- */

IF OBJECT_ID('dbo.GeocodeCache', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.GeocodeCache (
        GeocodeID     INT IDENTITY(1,1) PRIMARY KEY,
        AddressText   NVARCHAR(400)   NOT NULL,
        Latitude      DECIMAL(9,6)    NULL,
        Longitude     DECIMAL(9,6)    NULL,
        /* A failed lookup is cached too (both coords NULL) so a bad address is
           not re-sent to Nominatim on every page view. */
        ResolvedAt    DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_GeocodeCache_Address UNIQUE (AddressText)
    );
END
GO
