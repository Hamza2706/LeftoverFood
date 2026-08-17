-- Seeds the one Admin account the live database needs to be usable at all.
--
-- Public registration (login.aspx) only offers Donor / NGO / Volunteer, and
-- every self-registered account starts with IsVerified = 0 until an Admin
-- approves it (login.aspx.cs). On a brand-new database nobody exists to do
-- that approving, so without this insert the very first login attempt of
-- any kind is rejected with "pending admin approval" and there is no way
-- past it through the UI.
--
-- IsVerified and IsActive are set explicitly rather than left to column
-- defaults, unlike the columns below them — the normal registration INSERT
-- in login.aspx.cs never sets IsActive/TrustScore/ShareLocation either and
-- relies on the table's own defaults for those, so this mirrors that
-- rather than guessing values that duplicate logic already in the schema.
--
-- Replace the two values below before running:
--   @Email    the address you will actually log in with
--   @PassHash generate this with the PowerShell snippet in DEPLOYMENT.md
--             (New-FoodBridgePasswordHash) — do not paste a plain password
--             here, the column stores a salted PBKDF2 hash, not the password
--             itself.

DECLARE @Email    NVARCHAR(300) = 'admin@foodbridge.local';
DECLARE @PassHash NVARCHAR(512) = 'PBKDF2$100000$8c3jUeZ6aXI3tyGEPCy0GA==$WGkK3OXBdX/R5Aq4mVxyaqFdK6QZf37+9wcoFgMuRyw=';

INSERT INTO Users (FullName, Email, PasswordHash, Role, IsVerified, CreatedAt)
VALUES ('System Admin', @Email, @PassHash, 'Admin', 1, GETDATE());

SELECT UserID, FullName, Email, Role, IsVerified, IsActive
FROM Users WHERE Email = @Email;
