-- Continuation of phase0_schema_migration.sql: the auto-named UNIQUE constraint on
-- Users.Email blocks ALTER COLUMN. Drop it, widen the columns, then recreate it.

DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = kc.name
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID('dbo.Users') AND c.name = 'Email';

IF @ConstraintName IS NOT NULL
    EXEC('ALTER TABLE dbo.Users DROP CONSTRAINT [' + @ConstraintName + ']');
GO

ALTER TABLE dbo.Users ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Email NVARCHAR(150) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN PasswordHash NVARCHAR(256) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Role NVARCHAR(20) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Phone NVARCHAR(30) NULL;
ALTER TABLE dbo.Users ALTER COLUMN Address NVARCHAR(300) NULL;
GO

ALTER TABLE dbo.Users ADD CONSTRAINT UQ_Users_Email UNIQUE (Email);
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
