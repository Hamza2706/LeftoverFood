-- Final piece: CK__Users__Role blocks widening Role. Drop it, widen Role/Phone/Address, recreate it.

ALTER TABLE dbo.Users DROP CONSTRAINT CK__Users__Role__37A5467C;
GO

ALTER TABLE dbo.Users ALTER COLUMN Role NVARCHAR(20) NOT NULL;
ALTER TABLE dbo.Users ALTER COLUMN Phone NVARCHAR(30) NULL;
ALTER TABLE dbo.Users ALTER COLUMN Address NVARCHAR(300) NULL;
GO

ALTER TABLE dbo.Users ADD CONSTRAINT CK_Users_Role CHECK (Role IN ('Admin', 'Donor', 'NGO', 'Volunteer'));
GO
