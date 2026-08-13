-- Phase 0 schema reconciliation migration.
-- Brings the live LeftoverFoodDB in line with Database/schema.sql (the roadmap design).
--
-- Safe for existing data:
--   - Users: ALTERed only (columns added/widened), its 8 existing rows are untouched.
--   - FoodDonations, FoodRequests, Ratings: dropped & recreated with the new schema.
--     All three were EMPTY (0 rows) at migration time, confirmed before running this.
--   - UsersOLD, Deliveries, EmergencyMode: dropped outright — superseded, unreferenced,
--     confirmed empty (0 rows) before running this.
--   - UserLoginLogs: left untouched (has 1 row, not part of this reconciliation).

-- 1. Drop tables in dependency order (children before parents)
IF OBJECT_ID('dbo.Ratings', 'U') IS NOT NULL DROP TABLE dbo.Ratings;
IF OBJECT_ID('dbo.FoodRequests', 'U') IS NOT NULL DROP TABLE dbo.FoodRequests;
IF OBJECT_ID('dbo.Deliveries', 'U') IS NOT NULL DROP TABLE dbo.Deliveries;
IF OBJECT_ID('dbo.EmergencyMode', 'U') IS NOT NULL DROP TABLE dbo.EmergencyMode;
IF OBJECT_ID('dbo.UsersOLD', 'U') IS NOT NULL DROP TABLE dbo.UsersOLD;
GO

-- 2. Detach the tables created by the original schema.sql run from the old FoodDonations
--    so FoodDonations itself can be dropped.
IF OBJECT_ID('FK_DeliveryAssignments_Donation', 'F') IS NOT NULL
    ALTER TABLE dbo.DeliveryAssignments DROP CONSTRAINT FK_DeliveryAssignments_Donation;
IF OBJECT_ID('FK_FraudFlags_Donation', 'F') IS NOT NULL
    ALTER TABLE dbo.FraudFlags DROP CONSTRAINT FK_FraudFlags_Donation;
GO

IF OBJECT_ID('dbo.FoodDonations', 'U') IS NOT NULL DROP TABLE dbo.FoodDonations;
GO

-- 3. Recreate FoodDonations, FoodRequests, Ratings per Database/schema.sql
CREATE TABLE dbo.FoodDonations (
    DonationID          INT IDENTITY(1,1) PRIMARY KEY,
    DonorID              INT             NOT NULL,
    FoodDescription      NVARCHAR(300)   NOT NULL,
    Category             NVARCHAR(50)    NULL,
    DonorTypeAtPost      NVARCHAR(50)    NULL,
    Quantity              NVARCHAR(50)    NULL,
    Servings             INT             NULL,
    PreparedOn           DATETIME        NULL,
    ExpiryTime           DATETIME        NOT NULL,
    DietaryInfo          NVARCHAR(200)   NULL,
    AdditionalNotes      NVARCHAR(1000)  NULL,
    PickupAddress        NVARCHAR(300)   NOT NULL,
    City                 NVARCHAR(100)   NULL,
    Latitude             DECIMAL(9,6)    NULL,
    Longitude            DECIMAL(9,6)    NULL,
    AvailableFrom        DATETIME        NULL,
    AvailableUntil       DATETIME        NULL,
    ContactPerson        NVARCHAR(100)   NULL,
    ContactPhone         NVARCHAR(30)    NULL,
    PackagingCondition   NVARCHAR(100)   NULL,
    PreferredNGOID       INT             NULL,
    PhotoPath            NVARCHAR(300)   NULL,
    Status               NVARCHAR(20)    NOT NULL DEFAULT 'Posted',
    ApprovedBy           INT             NULL,
    ApprovedAt           DATETIME        NULL,
    CreatedAt            DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_FoodDonations_Donor FOREIGN KEY (DonorID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_FoodDonations_PreferredNGO FOREIGN KEY (PreferredNGOID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_FoodDonations_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.Users(UserID)
);
GO

CREATE TABLE dbo.FoodRequests (
    RequestID              INT IDENTITY(1,1) PRIMARY KEY,
    DonationID              INT             NOT NULL,
    NGOID                   INT             NOT NULL,
    RequestedAt              DATETIME        NOT NULL DEFAULT GETDATE(),
    Status                   NVARCHAR(20)    NOT NULL DEFAULT 'Pending',
    ActualQuantityReceived   NVARCHAR(50)    NULL,
    FoodCondition            NVARCHAR(100)   NULL,
    Notes                    NVARCHAR(500)   NULL,
    CONSTRAINT FK_FoodRequests_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID),
    CONSTRAINT FK_FoodRequests_NGO FOREIGN KEY (NGOID) REFERENCES dbo.Users(UserID)
);
GO

CREATE TABLE dbo.Ratings (
    RatingID     INT IDENTITY(1,1) PRIMARY KEY,
    DonationID    INT             NOT NULL,
    RaterID       INT             NOT NULL,
    RateeID       INT             NOT NULL,
    Stars         INT             NOT NULL CHECK (Stars BETWEEN 1 AND 5),
    Comments      NVARCHAR(500)   NULL,
    CreatedAt     DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Ratings_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID),
    CONSTRAINT FK_Ratings_Rater FOREIGN KEY (RaterID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Ratings_Ratee FOREIGN KEY (RateeID) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Ratings_OnePerDonationPerRater UNIQUE (DonationID, RaterID)
);
GO

-- 4. Reattach DeliveryAssignments / FraudFlags to the new FoodDonations
ALTER TABLE dbo.DeliveryAssignments
    ADD CONSTRAINT FK_DeliveryAssignments_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID);
ALTER TABLE dbo.FraudFlags
    ADD CONSTRAINT FK_FraudFlags_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID);
GO

-- 5. Bring Users up to the full roadmap schema (additive + widened columns, no data loss)
ALTER TABLE dbo.Users ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Email NVARCHAR(150) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN PasswordHash NVARCHAR(256) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Role NVARCHAR(20) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Phone NVARCHAR(30) NULL;
ALTER TABLE dbo.Users ALTER COLUMN Address NVARCHAR(300) NULL;
GO

IF COL_LENGTH('dbo.Users', 'City') IS NULL ALTER TABLE dbo.Users ADD City NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'Bio') IS NULL ALTER TABLE dbo.Users ADD Bio NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.Users', 'OrganizationName') IS NULL ALTER TABLE dbo.Users ADD OrganizationName NVARCHAR(150) NULL;
IF COL_LENGTH('dbo.Users', 'BusinessType') IS NULL ALTER TABLE dbo.Users ADD BusinessType NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'RegNumber') IS NULL ALTER TABLE dbo.Users ADD RegNumber NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'PreferredNGOID') IS NULL ALTER TABLE dbo.Users ADD PreferredNGOID INT NULL;
IF COL_LENGTH('dbo.Users', 'IsActive') IS NULL ALTER TABLE dbo.Users ADD IsActive BIT NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.Users', 'TrustScore') IS NULL ALTER TABLE dbo.Users ADD TrustScore DECIMAL(3,2) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_PreferredNGO')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_PreferredNGO FOREIGN KEY (PreferredNGOID) REFERENCES dbo.Users(UserID);
GO
