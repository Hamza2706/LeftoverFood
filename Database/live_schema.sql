-- Cleaned for the MonsterASP host database.
--
-- The raw "Generate Scripts" output (entire database, incl. the CREATE
-- DATABASE / ALTER DATABASE preamble and `USE [LeftoverFood]`) cannot run
-- here: the host database already exists under a different name (db64189,
-- not LeftoverFood), you don't have permission to create a database on
-- shared hosting, and the preamble's file paths point at the local machine.
-- Run this against the connection already scoped to your db64189 database —
-- no USE statement needed or wanted.
--
-- Also dropped: the [dbo].[ValidateUser] stored procedure from the original
-- export. It references columns that don't exist in the real Users table
-- ([Password], ApprovalStatus, AccountStatus, ProfilePicture — the actual
-- columns are PasswordHash / IsVerified / IsActive, and there is no profile
-- picture column). It isn't called anywhere in the C# code (grepped — no
-- hits), so it's dead legacy code, not something the app depends on.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeliveryAssignments](
	[AssignmentID] [int] IDENTITY(1,1) NOT NULL,
	[DonationID] [int] NOT NULL,
	[VolunteerID] [int] NOT NULL,
	[AssignedBy] [int] NOT NULL,
	[NoteForVolunteer] [nvarchar](300) NULL,
	[Status] [nvarchar](20) NOT NULL,
	[AssignedAt] [datetime] NOT NULL,
	[PickedUpAt] [datetime] NULL,
	[DeliveredAt] [datetime] NULL,
PRIMARY KEY CLUSTERED
(
	[AssignmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[EmergencyBroadcasts](
	[BroadcastID] [int] IDENTITY(1,1) NOT NULL,
	[EmergencyType] [nvarchar](100) NOT NULL,
	[AffectedArea] [nvarchar](200) NULL,
	[StartDateTime] [datetime] NOT NULL,
	[ExpectedDuration] [nvarchar](100) NULL,
	[PriorityAreas] [nvarchar](1000) NULL,
	[Message] [nvarchar](1000) NOT NULL,
	[SendTo] [nvarchar](20) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
	[EndedAt] [datetime] NULL,
	[RecipientCount] [int] NULL,
PRIMARY KEY CLUSTERED
(
	[BroadcastID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[FoodDonations](
	[DonationID] [int] IDENTITY(1,1) NOT NULL,
	[DonorID] [int] NOT NULL,
	[FoodDescription] [nvarchar](300) NOT NULL,
	[Category] [nvarchar](50) NULL,
	[DonorTypeAtPost] [nvarchar](50) NULL,
	[Quantity] [nvarchar](50) NULL,
	[Servings] [int] NULL,
	[PreparedOn] [datetime] NULL,
	[ExpiryTime] [datetime] NOT NULL,
	[DietaryInfo] [nvarchar](200) NULL,
	[AdditionalNotes] [nvarchar](1000) NULL,
	[PickupAddress] [nvarchar](300) NOT NULL,
	[City] [nvarchar](100) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[Longitude] [decimal](9, 6) NULL,
	[AvailableFrom] [datetime] NULL,
	[AvailableUntil] [datetime] NULL,
	[ContactPerson] [nvarchar](100) NULL,
	[ContactPhone] [nvarchar](30) NULL,
	[PackagingCondition] [nvarchar](100) NULL,
	[PreferredNGOID] [int] NULL,
	[PhotoPath] [nvarchar](300) NULL,
	[Status] [nvarchar](20) NOT NULL,
	[ApprovedBy] [int] NULL,
	[ApprovedAt] [datetime] NULL,
	[CreatedAt] [datetime] NOT NULL,
	[GeoPrecision] [nvarchar](20) NULL,
	[IsPriority] [bit] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[DonationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[FoodRequests](
	[RequestID] [int] IDENTITY(1,1) NOT NULL,
	[DonationID] [int] NOT NULL,
	[NGOID] [int] NOT NULL,
	[RequestedAt] [datetime] NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[ActualQuantityReceived] [nvarchar](50) NULL,
	[FoodCondition] [nvarchar](100) NULL,
	[Notes] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED
(
	[RequestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[FraudFlags](
	[FlagID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NULL,
	[DonationID] [int] NULL,
	[FlagType] [nvarchar](50) NOT NULL,
	[Details] [nvarchar](500) NULL,
	[Status] [nvarchar](20) NOT NULL,
	[FlaggedAt] [datetime] NOT NULL,
	[ReviewedBy] [int] NULL,
	[ReviewedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED
(
	[FlagID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[GeocodeCache](
	[GeocodeID] [int] IDENTITY(1,1) NOT NULL,
	[AddressText] [nvarchar](400) NOT NULL,
	[Latitude] [decimal](9, 6) NULL,
	[Longitude] [decimal](9, 6) NULL,
	[ResolvedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[GeocodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_GeocodeCache_Address] UNIQUE NONCLUSTERED
(
	[AddressText] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[NotificationPreferences](
	[PreferenceID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[EventKey] [nvarchar](50) NOT NULL,
	[EmailEnabled] [bit] NOT NULL,
	[InAppEnabled] [bit] NOT NULL,
	[UpdatedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[PreferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_NotifPrefs_User_Event] UNIQUE NONCLUSTERED
(
	[UserID] ASC,
	[EventKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Notifications](
	[NotificationID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[Message] [nvarchar](500) NOT NULL,
	[IsRead] [bit] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
	[LinkUrl] [nvarchar](300) NULL,
	[Type] [nvarchar](30) NOT NULL,
PRIMARY KEY CLUSTERED
(
	[NotificationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Ratings](
	[RatingID] [int] IDENTITY(1,1) NOT NULL,
	[DonationID] [int] NOT NULL,
	[RaterID] [int] NOT NULL,
	[RateeID] [int] NOT NULL,
	[Stars] [int] NOT NULL,
	[Comments] [nvarchar](500) NULL,
	[CreatedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[RatingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Ratings_OnePerCounterparty] UNIQUE NONCLUSTERED
(
	[DonationID] ASC,
	[RaterID] ASC,
	[RateeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[UserLoginLogs](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](200) NULL,
	[UsrAction] [nvarchar](50) NULL,
	[LogTime] [datetime] NULL,
PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Users](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[FullName] [nvarchar](150) NOT NULL,
	[Email] [nvarchar](150) NOT NULL,
	[PasswordHash] [nvarchar](256) NOT NULL,
	[Role] [nvarchar](20) NOT NULL,
	[Phone] [nvarchar](30) NULL,
	[Address] [nvarchar](300) NULL,
	[IsVerified] [bit] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
	[City] [nvarchar](100) NULL,
	[Bio] [nvarchar](500) NULL,
	[OrganizationName] [nvarchar](150) NULL,
	[BusinessType] [nvarchar](100) NULL,
	[RegNumber] [nvarchar](100) NULL,
	[PreferredNGOID] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[TrustScore] [decimal](3, 2) NULL,
	[ShareLocation] [bit] NOT NULL,
	[LastLoginAt] [datetime] NULL,
PRIMARY KEY CLUSTERED
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Users_Email] UNIQUE NONCLUSTERED
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[VolunteerLocations](
	[LocationID] [int] IDENTITY(1,1) NOT NULL,
	[VolunteerID] [int] NOT NULL,
	[AssignmentID] [int] NOT NULL,
	[Latitude] [decimal](9, 6) NOT NULL,
	[Longitude] [decimal](9, 6) NOT NULL,
	[Accuracy] [decimal](9, 2) NULL,
	[RecordedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED
(
	[LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EmergencyBroadcasts_Active_Created] ON [dbo].[EmergencyBroadcasts]
(
	[IsActive] ASC,
	[CreatedAt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_FraudFlags_Status_Flagged] ON [dbo].[FraudFlags]
(
	[Status] ASC,
	[FlaggedAt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_FraudFlags_User_Type_Status] ON [dbo].[FraudFlags]
(
	[UserID] ASC,
	[FlagType] ASC,
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Notifications_User_Read] ON [dbo].[Notifications]
(
	[UserID] ASC,
	[IsRead] ASC,
	[CreatedAt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Ratings_Ratee_Created] ON [dbo].[Ratings]
(
	[RateeID] ASC,
	[CreatedAt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_VolLoc_Assignment_Recorded] ON [dbo].[VolunteerLocations]
(
	[AssignmentID] ASC,
	[RecordedAt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DeliveryAssignments] ADD  DEFAULT ('Assigned') FOR [Status]
GO
ALTER TABLE [dbo].[DeliveryAssignments] ADD  DEFAULT (getdate()) FOR [AssignedAt]
GO
ALTER TABLE [dbo].[EmergencyBroadcasts] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmergencyBroadcasts] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[FoodDonations] ADD  DEFAULT ('Posted') FOR [Status]
GO
ALTER TABLE [dbo].[FoodDonations] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[FoodDonations] ADD  CONSTRAINT [DF_FoodDonations_IsPriority]  DEFAULT ((0)) FOR [IsPriority]
GO
ALTER TABLE [dbo].[FoodRequests] ADD  DEFAULT (getdate()) FOR [RequestedAt]
GO
ALTER TABLE [dbo].[FoodRequests] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[FraudFlags] ADD  DEFAULT ('Open') FOR [Status]
GO
ALTER TABLE [dbo].[FraudFlags] ADD  DEFAULT (getdate()) FOR [FlaggedAt]
GO
ALTER TABLE [dbo].[GeocodeCache] ADD  DEFAULT (getdate()) FOR [ResolvedAt]
GO
ALTER TABLE [dbo].[NotificationPreferences] ADD  DEFAULT ((1)) FOR [EmailEnabled]
GO
ALTER TABLE [dbo].[NotificationPreferences] ADD  DEFAULT ((1)) FOR [InAppEnabled]
GO
ALTER TABLE [dbo].[NotificationPreferences] ADD  DEFAULT (getdate()) FOR [UpdatedAt]
GO
ALTER TABLE [dbo].[Notifications] ADD  DEFAULT ((0)) FOR [IsRead]
GO
ALTER TABLE [dbo].[Notifications] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Notifications] ADD  CONSTRAINT [DF_Notifications_Type]  DEFAULT ('System') FOR [Type]
GO
ALTER TABLE [dbo].[Ratings] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[UserLoginLogs] ADD  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((0)) FOR [IsVerified]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_ShareLocation]  DEFAULT ((0)) FOR [ShareLocation]
GO
ALTER TABLE [dbo].[VolunteerLocations] ADD  DEFAULT (getdate()) FOR [RecordedAt]
GO
ALTER TABLE [dbo].[DeliveryAssignments]  WITH CHECK ADD  CONSTRAINT [FK_DeliveryAssignments_AssignedBy] FOREIGN KEY([AssignedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[DeliveryAssignments] CHECK CONSTRAINT [FK_DeliveryAssignments_AssignedBy]
GO
ALTER TABLE [dbo].[DeliveryAssignments]  WITH CHECK ADD  CONSTRAINT [FK_DeliveryAssignments_Donation] FOREIGN KEY([DonationID])
REFERENCES [dbo].[FoodDonations] ([DonationID])
GO
ALTER TABLE [dbo].[DeliveryAssignments] CHECK CONSTRAINT [FK_DeliveryAssignments_Donation]
GO
ALTER TABLE [dbo].[DeliveryAssignments]  WITH CHECK ADD  CONSTRAINT [FK_DeliveryAssignments_Volunteer] FOREIGN KEY([VolunteerID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[DeliveryAssignments] CHECK CONSTRAINT [FK_DeliveryAssignments_Volunteer]
GO
ALTER TABLE [dbo].[EmergencyBroadcasts]  WITH CHECK ADD  CONSTRAINT [FK_EmergencyBroadcasts_CreatedBy] FOREIGN KEY([CreatedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[EmergencyBroadcasts] CHECK CONSTRAINT [FK_EmergencyBroadcasts_CreatedBy]
GO
ALTER TABLE [dbo].[FoodDonations]  WITH CHECK ADD  CONSTRAINT [FK_FoodDonations_ApprovedBy] FOREIGN KEY([ApprovedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FoodDonations] CHECK CONSTRAINT [FK_FoodDonations_ApprovedBy]
GO
ALTER TABLE [dbo].[FoodDonations]  WITH CHECK ADD  CONSTRAINT [FK_FoodDonations_Donor] FOREIGN KEY([DonorID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FoodDonations] CHECK CONSTRAINT [FK_FoodDonations_Donor]
GO
ALTER TABLE [dbo].[FoodDonations]  WITH CHECK ADD  CONSTRAINT [FK_FoodDonations_PreferredNGO] FOREIGN KEY([PreferredNGOID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FoodDonations] CHECK CONSTRAINT [FK_FoodDonations_PreferredNGO]
GO
ALTER TABLE [dbo].[FoodRequests]  WITH CHECK ADD  CONSTRAINT [FK_FoodRequests_Donation] FOREIGN KEY([DonationID])
REFERENCES [dbo].[FoodDonations] ([DonationID])
GO
ALTER TABLE [dbo].[FoodRequests] CHECK CONSTRAINT [FK_FoodRequests_Donation]
GO
ALTER TABLE [dbo].[FoodRequests]  WITH CHECK ADD  CONSTRAINT [FK_FoodRequests_NGO] FOREIGN KEY([NGOID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FoodRequests] CHECK CONSTRAINT [FK_FoodRequests_NGO]
GO
ALTER TABLE [dbo].[FraudFlags]  WITH CHECK ADD  CONSTRAINT [FK_FraudFlags_Donation] FOREIGN KEY([DonationID])
REFERENCES [dbo].[FoodDonations] ([DonationID])
GO
ALTER TABLE [dbo].[FraudFlags] CHECK CONSTRAINT [FK_FraudFlags_Donation]
GO
ALTER TABLE [dbo].[FraudFlags]  WITH CHECK ADD  CONSTRAINT [FK_FraudFlags_ReviewedBy] FOREIGN KEY([ReviewedBy])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FraudFlags] CHECK CONSTRAINT [FK_FraudFlags_ReviewedBy]
GO
ALTER TABLE [dbo].[FraudFlags]  WITH CHECK ADD  CONSTRAINT [FK_FraudFlags_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[FraudFlags] CHECK CONSTRAINT [FK_FraudFlags_User]
GO
ALTER TABLE [dbo].[NotificationPreferences]  WITH CHECK ADD  CONSTRAINT [FK_NotifPrefs_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[NotificationPreferences] CHECK CONSTRAINT [FK_NotifPrefs_User]
GO
ALTER TABLE [dbo].[Notifications]  WITH CHECK ADD FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Ratings]  WITH CHECK ADD  CONSTRAINT [FK_Ratings_Donation] FOREIGN KEY([DonationID])
REFERENCES [dbo].[FoodDonations] ([DonationID])
GO
ALTER TABLE [dbo].[Ratings] CHECK CONSTRAINT [FK_Ratings_Donation]
GO
ALTER TABLE [dbo].[Ratings]  WITH CHECK ADD  CONSTRAINT [FK_Ratings_Ratee] FOREIGN KEY([RateeID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Ratings] CHECK CONSTRAINT [FK_Ratings_Ratee]
GO
ALTER TABLE [dbo].[Ratings]  WITH CHECK ADD  CONSTRAINT [FK_Ratings_Rater] FOREIGN KEY([RaterID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Ratings] CHECK CONSTRAINT [FK_Ratings_Rater]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_PreferredNGO] FOREIGN KEY([PreferredNGOID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_PreferredNGO]
GO
ALTER TABLE [dbo].[VolunteerLocations]  WITH CHECK ADD  CONSTRAINT [FK_VolLoc_Assignment] FOREIGN KEY([AssignmentID])
REFERENCES [dbo].[DeliveryAssignments] ([AssignmentID])
GO
ALTER TABLE [dbo].[VolunteerLocations] CHECK CONSTRAINT [FK_VolLoc_Assignment]
GO
ALTER TABLE [dbo].[VolunteerLocations]  WITH CHECK ADD  CONSTRAINT [FK_VolLoc_Volunteer] FOREIGN KEY([VolunteerID])
REFERENCES [dbo].[Users] ([UserID])
GO
ALTER TABLE [dbo].[VolunteerLocations] CHECK CONSTRAINT [FK_VolLoc_Volunteer]
GO
ALTER TABLE [dbo].[Ratings]  WITH CHECK ADD CHECK  (([Stars]>=(1) AND [Stars]<=(5)))
GO
ALTER TABLE [dbo].[Ratings]  WITH CHECK ADD  CONSTRAINT [CK_Ratings_NoSelfRating] CHECK  (([RaterID]<>[RateeID]))
GO
ALTER TABLE [dbo].[Ratings] CHECK CONSTRAINT [CK_Ratings_NoSelfRating]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK_Users_Role] CHECK  (([Role]='Volunteer' OR [Role]='NGO' OR [Role]='Donor' OR [Role]='Admin'))
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK_Users_Role]
GO
