-- Deletes one user and everything that references them, in FK-safe order.
--
-- A plain `DELETE FROM Users WHERE ...` fails because up to 8 other tables
-- can point at a UserID, and none of the foreign keys in live_schema.sql
-- cascade: DeliveryAssignments (VolunteerID, AssignedBy), EmergencyBroadcasts
-- (CreatedBy), FoodDonations (DonorID, ApprovedBy, PreferredNGOID),
-- FoodRequests (NGOID), FraudFlags (UserID, ReviewedBy), Notifications,
-- NotificationPreferences, Ratings (RaterID, RateeID), VolunteerLocations
-- (via DeliveryAssignments), and even Users.PreferredNGOID pointing at
-- another Users row.
--
-- A user's *own donations* also have their own dependents (requests,
-- delivery assignments, ratings, fraud flags tied to that DonationID), so
-- those have to be cleared before the donation rows themselves, before the
-- user row. The temp table just avoids repeating that subquery everywhere.
--
-- Set @Email, then run the whole script in one go.

DECLARE @Email NVARCHAR(300) = 'qa-test-donor@foodbridge.local';

DECLARE @UserID INT = (SELECT UserID FROM Users WHERE Email = @Email);

IF @UserID IS NULL
BEGIN
    PRINT 'No user found with that email — nothing to do.';
    RETURN;
END

-- Every donation this user posted (relevant when they're a Donor).
SELECT DonationID INTO #Donations FROM FoodDonations WHERE DonorID = @UserID;

-- Every delivery assignment tied to this user's donations, or where this
-- user is the volunteer or the admin who made the assignment.
SELECT AssignmentID INTO #Assignments
FROM DeliveryAssignments
WHERE DonationID IN (SELECT DonationID FROM #Donations)
   OR VolunteerID = @UserID
   OR AssignedBy = @UserID;

DELETE FROM VolunteerLocations WHERE AssignmentID IN (SELECT AssignmentID FROM #Assignments);
DELETE FROM DeliveryAssignments WHERE AssignmentID IN (SELECT AssignmentID FROM #Assignments);

DELETE FROM Ratings
WHERE DonationID IN (SELECT DonationID FROM #Donations)
   OR RaterID = @UserID
   OR RateeID = @UserID;

DELETE FROM FraudFlags
WHERE DonationID IN (SELECT DonationID FROM #Donations)
   OR UserID = @UserID
   OR ReviewedBy = @UserID;

DELETE FROM FoodRequests
WHERE DonationID IN (SELECT DonationID FROM #Donations)
   OR NGOID = @UserID;

DELETE FROM Notifications WHERE UserID = @UserID;
DELETE FROM NotificationPreferences WHERE UserID = @UserID;
DELETE FROM EmergencyBroadcasts WHERE CreatedBy = @UserID;

-- These two are nullable references, not ownership — clear the pointer
-- rather than deleting the donation/user on the other end of it.
UPDATE FoodDonations SET ApprovedBy = NULL WHERE ApprovedBy = @UserID;
UPDATE FoodDonations SET PreferredNGOID = NULL WHERE PreferredNGOID = @UserID;
UPDATE Users SET PreferredNGOID = NULL WHERE PreferredNGOID = @UserID;

-- Now safe: nothing outside #Donations points at these rows any more.
DELETE FROM FoodDonations WHERE DonationID IN (SELECT DonationID FROM #Donations);

DELETE FROM Users WHERE UserID = @UserID;

DROP TABLE #Donations;
DROP TABLE #Assignments;

PRINT 'Deleted user ' + @Email + ' (UserID ' + CAST(@UserID AS NVARCHAR(20)) + ') and all dependent rows.';
