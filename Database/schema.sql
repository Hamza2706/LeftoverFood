-- LeftoverFood database schema.
-- Run against the database named in Web.config's "FoodDB" connection string
-- (currently "LeftoverFood" on Elitebook\SQLEXPRESS). Safe to re-run: every
-- CREATE TABLE is guarded so existing tables/data are left untouched.
--
-- Column names for Users match what the existing code-behind (login.aspx.cs,
-- previously TestRegLogin) already reads/writes, plus additive nullable
-- columns for fields the Donor/NGO profile mockups expect later.

IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users (
        UserID            INT IDENTITY(1,1) PRIMARY KEY,
        FullName          NVARCHAR(150)   NOT NULL,
        Email             NVARCHAR(150)   NOT NULL UNIQUE,
        PasswordHash      NVARCHAR(200)   NOT NULL,
        Role              NVARCHAR(20)    NOT NULL, -- Admin | Donor | NGO | Volunteer
        Phone             NVARCHAR(30)    NULL,
        Address           NVARCHAR(300)   NULL,
        City              NVARCHAR(100)   NULL,
        Bio               NVARCHAR(500)   NULL,
        OrganizationName  NVARCHAR(150)   NULL, -- NGO
        BusinessType      NVARCHAR(100)   NULL, -- Donor: Restaurant/Individual/Event/Household
        RegNumber         NVARCHAR(100)   NULL, -- CNIC / business registration no.
        PreferredNGOID    INT             NULL, -- Donor's default NGO (FK added below)
        IsVerified        BIT             NOT NULL DEFAULT 0,
        IsActive          BIT             NOT NULL DEFAULT 1,
        TrustScore        DECIMAL(3,2)    NULL,
        CreatedAt         DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Users_PreferredNGO FOREIGN KEY (PreferredNGOID) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.FoodDonations', 'U') IS NULL
BEGIN
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
            -- Posted | Approved | Rejected | Requested | Assigned | PickedUp | Delivered | Expired | Cancelled
        ApprovedBy           INT             NULL,
        ApprovedAt           DATETIME        NULL,
        CreatedAt            DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_FoodDonations_Donor FOREIGN KEY (DonorID) REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_FoodDonations_PreferredNGO FOREIGN KEY (PreferredNGOID) REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_FoodDonations_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.FoodRequests', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FoodRequests (
        RequestID              INT IDENTITY(1,1) PRIMARY KEY,
        DonationID              INT             NOT NULL,
        NGOID                   INT             NOT NULL,
        RequestedAt              DATETIME        NOT NULL DEFAULT GETDATE(),
        Status                   NVARCHAR(20)    NOT NULL DEFAULT 'Pending', -- Pending | Accepted | Rejected
        ActualQuantityReceived   NVARCHAR(50)    NULL,
        FoodCondition            NVARCHAR(100)   NULL,
        Notes                    NVARCHAR(500)   NULL,
        CONSTRAINT FK_FoodRequests_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID),
        CONSTRAINT FK_FoodRequests_NGO FOREIGN KEY (NGOID) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.DeliveryAssignments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DeliveryAssignments (
        AssignmentID       INT IDENTITY(1,1) PRIMARY KEY,
        DonationID          INT             NOT NULL,
        VolunteerID         INT             NOT NULL,
        AssignedBy          INT             NOT NULL,
        NoteForVolunteer    NVARCHAR(300)   NULL,
        Status               NVARCHAR(20)    NOT NULL DEFAULT 'Assigned', -- Assigned|PickedUp|InTransit|Delivered|Failed
        AssignedAt           DATETIME        NOT NULL DEFAULT GETDATE(),
        PickedUpAt           DATETIME        NULL,
        DeliveredAt          DATETIME        NULL,
        CONSTRAINT FK_DeliveryAssignments_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID),
        CONSTRAINT FK_DeliveryAssignments_Volunteer FOREIGN KEY (VolunteerID) REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_DeliveryAssignments_AssignedBy FOREIGN KEY (AssignedBy) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.Ratings', 'U') IS NULL
BEGIN
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
END
GO

IF OBJECT_ID('dbo.Notifications', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Notifications (
        NotificationID   INT IDENTITY(1,1) PRIMARY KEY,
        UserID            INT             NOT NULL,
        Message           NVARCHAR(500)   NOT NULL,
        Type              NVARCHAR(30)    NOT NULL, -- Approval|Delivery|Emergency|System
        IsRead            BIT             NOT NULL DEFAULT 0,
        CreatedAt         DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Notifications_User FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.FraudFlags', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FraudFlags (
        FlagID       INT IDENTITY(1,1) PRIMARY KEY,
        UserID        INT             NULL,
        DonationID    INT             NULL,
        FlagType      NVARCHAR(50)    NOT NULL, -- DuplicateDonor|FakeLocation|RepeatedCancel
        Details       NVARCHAR(500)   NULL,
        Status        NVARCHAR(20)    NOT NULL DEFAULT 'Open', -- Open|Reviewed|Dismissed
        FlaggedAt     DATETIME        NOT NULL DEFAULT GETDATE(),
        ReviewedBy    INT             NULL,
        CONSTRAINT FK_FraudFlags_User FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
        CONSTRAINT FK_FraudFlags_Donation FOREIGN KEY (DonationID) REFERENCES dbo.FoodDonations(DonationID),
        CONSTRAINT FK_FraudFlags_ReviewedBy FOREIGN KEY (ReviewedBy) REFERENCES dbo.Users(UserID)
    );
END
GO

IF OBJECT_ID('dbo.EmergencyBroadcasts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.EmergencyBroadcasts (
        BroadcastID        INT IDENTITY(1,1) PRIMARY KEY,
        EmergencyType       NVARCHAR(100)   NOT NULL,
        AffectedArea        NVARCHAR(200)   NULL,
        StartDateTime       DATETIME        NOT NULL,
        ExpectedDuration     NVARCHAR(100)   NULL,
        PriorityAreas        NVARCHAR(1000)  NULL,
        Message              NVARCHAR(1000)  NOT NULL,
        SendTo               NVARCHAR(20)    NOT NULL, -- NGOs|Volunteers|Both
        IsActive             BIT             NOT NULL DEFAULT 1,
        CreatedBy            INT             NOT NULL,
        CreatedAt            DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_EmergencyBroadcasts_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users(UserID)
    );
END
GO
