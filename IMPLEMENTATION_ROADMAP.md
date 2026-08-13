# LeftoverFood — Proposal-to-Codebase Gap Analysis & Implementation Roadmap

Source proposal: `Fyp Proposal _Smart Leftover Food Redistribution System (1).docx`
Stack confirmed in repo: ASP.NET Web Forms, C# code-behind, ADO.NET (`SqlClient`) via `DBHelper`, SQL Server, ASPX + inline CSS (no Bootstrap in the app pages; Bootstrap is only used in the separate static `index.html` prototype).

## 0. Cross-cutting: Shared Layout Refactor (Master Pages) — ✅ IMPLEMENTED

Every one of the 13 dashboard-style pages (Admin ×6, Donor ×4, NGO ×2, Volunteer ×1) was duplicating the full HTML skeleton, topbar, and sidebar markup — same `<head>` CDN links, same `.fb-topbar` structure, same per-role `<aside class="fb-sidebar">` nav copy-pasted with tiny drift between copies (e.g. Donor's sidebar item list differed slightly page to page). Replaced with ASP.NET's built-in nested Master Page mechanism — the idiomatic fix for exactly this in Web Forms, not a bolted-on pattern:

- **`Site.master`** (root) — the one shared HTML skeleton: `<head>`, CDN links, `<form runat="server">`, the topbar (sidebar-toggle button, search box, notification bell, and a dynamically-computed user avatar/initials via `Site.master.cs` + `SessionHelper.Initials()`), and content placeholders (`HeadContent`, `SidebarContent`, `PageHeading`, `MainContent`, `FooterScripts`).
- **One nested master per module** — `Admin/AdminMaster.master`, `Donor/DonorMaster.master`, `NGO/NGOMaster.master`, `Volunteer/VolunteerMaster.master` — each supplies that role's `<aside>` sidebar exactly once, with nav links using `<%= ResolveUrl(...) %>` and a server-side `IsActive(pageFileName)` helper that highlights the current page automatically (previously hardcoded per file, and previously wrong/inconsistent on some pages). Logout is now wired once per master (`SessionHelper.Logout`), removing 12 duplicate `btnLogout_Click` handlers.
- **Every content page** now contains only its unique body inside `<asp:Content>` blocks targeting the role master's placeholders — no more repeated `<html>`/`<head>`/sidebar/topbar/`<form>` per file.
- **Scope decision**: `donate-form.aspx` and `track-donation.aspx` were deliberately left standalone — they use a different top-navbar-only layout with no sidebar (by original design, for a focused form/tracking view), so there's no sidebar duplication to eliminate there. Converting them to a role master would have added a sidebar that wasn't part of their design.
- **Verified**: every content page's `ContentPlaceHolderID` references resolve to a real placeholder declared in its master (scripted check, not just eyeballed); every role master covers all 5 of `Site.master`'s placeholders; brace-balance and control-ID cross-checks re-run clean on the 4 pages with real business logic (`admin-dashboard`, `food-approvals`, `donor-dashboard`, `ngo-dashboard`) to confirm the Repeater/postback wiring survived the move untouched.
- Bonus fix bundled in: sidebar/topbar avatar initials and names were hardcoded fake values (`"AD"`, `"Ahmed Khan"`, etc.) on every page — now computed live from the logged-in user's session everywhere, via the same `Site.master`/role-master code path.

---

## 1. Current State Audit

### 1.1 What's actually implemented (working, wired to DB)

| Feature | Where | Notes |
|---|---|---|
| User registration | `login.aspx(.cs)` (`btnRegister_Click`, register tab) | **Live implementation** — see confirmed status below. |
| User login | `login.aspx(.cs)` (`btnLogin_Click`, login tab) | **Live implementation** — see confirmed status below. |
| Password hashing | `PasswordHelper.cs` | Unsalted SHA-256. Functional but weak. |
| Parameterized SQL | `DBHelper.cs` | Correctly uses `SqlParameter` everywhere seen — good, no injection risk in existing queries. |
| Session-based role storage | `SessionHelper.cs` | `RequireLogin` / `RequireRole` helpers exist and are correctly written. |

### 1.2 What's scaffolded but not implemented (critical finding)

**All 15 role-specific pages are static HTML/CSS mockups with zero server controls and empty `Page_Load`:**

- Admin: `admin-dashboard`, `emergency-mode`, `food-approvals`, `fraud-detection`, `reports`, `volunteer-assign`
- Donor: `donor-dashboard`, `donate-form`, `notifications`, `profile`, `ratings`, `track-donation`
- NGO: `ngo-dashboard`, `ngo-active-requests`
- Volunteer: `volunteer-dashboard`

Verified via grep: `runat="server"` count on every one of these `.aspx` files is **0** — no `asp:` controls, no data binding, no postback handlers. They are pure design shells (nicely built, with real field labels/placeholders that clearly imply the intended data model — used below to design the schema).

### 1.2b `TestRegLogin/` — confirmed orphaned test code, not part of the live app

Investigated directly (per user request) whether `TestRegLogin/Login.aspx` + `Register.aspx` are actually used. **Confirmed: they are dead code.**

Evidence:
- `Web.config`'s forms-auth `loginUrl="~/Login.aspx"` and every redirect in `SessionHelper.cs` (`~/Login.aspx`) resolve to the **root** `login.aspx` — a root-relative `~/Login.aspx` reaches the file at the app root, not `~/TestRegLogin/Login.aspx`. A subfolder reference would have to spell out `~/TestRegLogin/Login.aspx` explicitly, and nothing does.
- Repo-wide grep for `TestRegLogin` turns up exactly three kinds of hits: the files themselves, their `LeftoverFood.csproj` `<Content>`/`<Compile>` entries, and this document. **No navbar, master page, `index.html`, or other `.aspx` file links to either page.**
- The two files only link to each other (`TestRegLogin/Login.aspx` → `Register.aspx`, and back) — a self-contained, unreferenced island.
- `login.aspx` (root) is a single page with tabbed Login/Register panels, styled to match the live "FoodBridge" branding used across `index.html`. `TestRegLogin/*` uses different, earlier "FoodShare" branding — consistent with it being an earlier draft that was superseded rather than removed.
- Both still compile today only because they're listed in `LeftoverFood.csproj` (`<Content Include="TestRegLogin\Login.aspx" />` etc.) — they build cleanly but are unreachable at runtime.

**Conclusion:** `login.aspx` (root) is the one real, live registration/login implementation. `TestRegLogin/` was leftover scratch/test work with its own duplicate insert/select logic against the same `Users` table.

**Done:** `TestRegLogin/` folder and its 6 `LeftoverFood.csproj` entries have been removed (working-tree only, not committed).

### 1.3 Launch-blocking bugs found in the existing (working) code

1. **No account can ever be approved.** Registration sets `IsVerified = 0`. No page anywhere sets it back to `1`. `Admin/food-approvals.aspx` (which sounds like it might do this) is an empty stub. Every user who registers is permanently stuck at "pending approval."
2. **No page enforces authentication.** `SessionHelper.RequireLogin`/`RequireRole` exist but are **never called** — every dashboard's `Page_Load` is empty. Anyone with the URL can currently open `/Admin/admin-dashboard.aspx` with no session at all.
3. ~~Duplicate, diverging login/register flows~~ — resolved by investigation above: `login.aspx` is the sole live flow, `TestRegLogin/` is unused. No code duplication risk in practice, just dead files worth removing during cleanup (see §1.2b).
4. **`~/Unauthorized.aspx` and `~/Error.aspx` don't exist**, but `SessionHelper.RequireRole` and `Web.config`'s `customErrors` both redirect to them — this will 404 the moment auth is enforced.
5. **Uncommitted `Web.config` change** (already sitting in your working tree) removes the `<system.codedom><compilers>` section while `packages.config` still references `Microsoft.CodeDom.Providers.DotNetCompilerPlatform` — worth resolving before it causes a build/runtime mismatch. It also changes the connection string name usage is fine (`FoodDB` already matches `DBHelper`), but the DB name/server changed (`LeftoverFood` → `LeftoverFoodDB`, `Elitebook\SQLEXPRESS` → `.\SQLEXPRESS`) — confirm that's intentional before we build the schema against it.
6. **No SQL schema file anywhere in the repo.** The `Users` table shape is only inferable from query text. Nothing else (donations, requests, deliveries, etc.) exists yet, even as a script.
7. `assets/{css,js,assets` and `assets/{css,js,assets/icons,pages}` are literal junk directories (a shell brace-expansion mistake), and `index.html` + `assets/` is a **separate static Bootstrap prototype** referencing `login.html`, `donate-form.html`, `donations-list.html`, `about.html` — none of which exist as files. Worth deciding whether this is the design reference to port into the real `.aspx` pages, or dead weight to remove.

### 1.4 Proposal feature checklist

| Proposal feature | Status |
|---|---|
| Registration/Login, 4 roles | 🟡 Partial — works via `login.aspx` (single live implementation, confirmed §1.2b), but has the approval dead-end (§1.3.1) |
| Role-based dashboards via session | 🔴 Missing — UI exists, no session gating, no data |
| Donation posting (type, qty, expiry, pickup location) | 🔴 Missing — form UI exists, not wired |
| NGO browse/request available food | 🔴 Missing — UI exists, not wired |
| Admin approve donations / manage users | 🔴 Missing — UI exists, not wired |
| Volunteer assignment & delivery tracking | 🔴 Missing — UI exists, not wired |
| Auto expiry detection | 🔴 Missing entirely |
| Real-time status (Posted/Approved/Picked/Delivered) | 🔴 Missing — no status model at all |
| Google Maps integration | 🔴 Missing entirely — no API key config, no JS |
| Email notifications | 🔴 Missing entirely — no `System.Net.Mail` usage anywhere |
| Emergency Mode | 🔴 Missing — UI exists, not wired |
| Duplicate/Fake donor detection | 🔴 Missing — UI exists, not wired |
| Report export (PDF/Excel) | 🔴 Missing — UI exists, no export library referenced |
| Food waste analytics | 🔴 Missing entirely |
| Ratings/trust system | 🔴 Missing — UI exists, not wired |

**Bottom line:** you have a real (if duplicated) auth system and a complete, well-designed set of UI mockups for every screen the proposal describes. Everything from "post a donation" onward is unbuilt. This is actually a good position — the design/IA work is done; what's left is almost entirely backend wiring + schema.

---

## 2. Proposed Database Schema

Single SQL Server database. Kept in one pragmatic style matching `DBHelper`'s flat ADO.NET usage — no ORM introduced, no unnecessary normalization beyond what the mockups actually need.

```
Users
  UserID          INT PK IDENTITY
  FullName        NVARCHAR(150)
  Email           NVARCHAR(150) UNIQUE
  PasswordHash    NVARCHAR(200)
  Role            NVARCHAR(20)   -- Admin | Donor | NGO | Volunteer
  Phone           NVARCHAR(30)
  Address         NVARCHAR(300)
  City            NVARCHAR(100)  NULL
  Bio             NVARCHAR(500)  NULL
  OrganizationName NVARCHAR(150) NULL   -- NGO
  BusinessType    NVARCHAR(100)  NULL   -- Donor (Restaurant/Individual/Event/Household)
  RegNumber       NVARCHAR(100)  NULL   -- CNIC / business reg no.
  PreferredNGOID  INT NULL FK->Users    -- Donor's default NGO
  IsVerified      BIT DEFAULT 0
  IsActive        BIT DEFAULT 1         -- for admin suspend, not just approval
  TrustScore      DECIMAL(3,2) NULL     -- rolling avg from Ratings
  CreatedAt       DATETIME DEFAULT GETDATE()

FoodDonations
  DonationID      INT PK IDENTITY
  DonorID         INT FK->Users
  FoodDescription NVARCHAR(300)
  Category        NVARCHAR(50)   -- Cooked/Raw/Packaged/Bakery...
  DonorTypeAtPost NVARCHAR(50)
  Quantity        NVARCHAR(50)
  Servings        INT NULL
  PreparedOn      DATETIME NULL
  ExpiryTime      DATETIME
  DietaryInfo     NVARCHAR(200)  NULL  -- comma-flags: Veg,Halal,NutFree...
  AdditionalNotes NVARCHAR(1000) NULL
  PickupAddress   NVARCHAR(300)
  City            NVARCHAR(100)
  Latitude        DECIMAL(9,6)   NULL
  Longitude       DECIMAL(9,6)   NULL
  AvailableFrom   DATETIME
  AvailableUntil  DATETIME
  ContactPerson   NVARCHAR(100)
  ContactPhone    NVARCHAR(30)
  PackagingCondition NVARCHAR(100) NULL
  PreferredNGOID  INT NULL FK->Users
  PhotoPath       NVARCHAR(300)  NULL  -- /uploads/images/...
  Status          NVARCHAR(20)  DEFAULT 'Posted'
                  -- Posted | Approved | Rejected | Requested | Assigned | PickedUp | Delivered | Expired | Cancelled
  ApprovedBy      INT NULL FK->Users
  ApprovedAt      DATETIME NULL
  CreatedAt       DATETIME DEFAULT GETDATE()

FoodRequests
  RequestID       INT PK IDENTITY
  DonationID      INT FK->FoodDonations
  NGOID           INT FK->Users
  RequestedAt     DATETIME DEFAULT GETDATE()
  Status          NVARCHAR(20) DEFAULT 'Pending'  -- Pending | Accepted | Rejected
  ActualQuantityReceived NVARCHAR(50) NULL
  FoodCondition   NVARCHAR(100) NULL
  Notes           NVARCHAR(500) NULL

DeliveryAssignments
  AssignmentID    INT PK IDENTITY
  DonationID      INT FK->FoodDonations
  VolunteerID     INT FK->Users
  AssignedBy      INT FK->Users        -- admin
  NoteForVolunteer NVARCHAR(300) NULL
  Status          NVARCHAR(20) DEFAULT 'Assigned' -- Assigned|PickedUp|InTransit|Delivered|Failed
  AssignedAt      DATETIME DEFAULT GETDATE()
  PickedUpAt      DATETIME NULL
  DeliveredAt     DATETIME NULL

Ratings
  RatingID        INT PK IDENTITY
  DonationID      INT FK->FoodDonations
  RaterID         INT FK->Users
  RateeID         INT FK->Users
  Stars           INT               -- 1-5
  Comments        NVARCHAR(500) NULL
  CreatedAt       DATETIME DEFAULT GETDATE()

Notifications
  NotificationID  INT PK IDENTITY
  UserID          INT FK->Users
  Message         NVARCHAR(500)
  Type            NVARCHAR(30)      -- Approval|Delivery|Emergency|System
  IsRead          BIT DEFAULT 0
  CreatedAt       DATETIME DEFAULT GETDATE()

FraudFlags
  FlagID          INT PK IDENTITY
  UserID          INT NULL FK->Users
  DonationID      INT NULL FK->FoodDonations
  FlagType        NVARCHAR(50)      -- DuplicateDonor|FakeLocation|RepeatedCancel
  Details         NVARCHAR(500)
  Status          NVARCHAR(20) DEFAULT 'Open'  -- Open|Reviewed|Dismissed
  FlaggedAt       DATETIME DEFAULT GETDATE()
  ReviewedBy      INT NULL FK->Users

EmergencyBroadcasts
  BroadcastID     INT PK IDENTITY
  EmergencyType   NVARCHAR(100)
  AffectedArea    NVARCHAR(200)
  StartDateTime   DATETIME
  ExpectedDuration NVARCHAR(100) NULL
  PriorityAreas   NVARCHAR(1000) NULL
  Message         NVARCHAR(1000)
  SendTo          NVARCHAR(20)      -- NGOs|Volunteers|Both
  IsActive        BIT DEFAULT 1
  CreatedBy       INT FK->Users
  CreatedAt       DATETIME DEFAULT GETDATE()
```

This isn't a migration tool setup — just one `schema.sql` checked into the repo (e.g. `Database/schema.sql`) that you run once against your local SQL Server instance. No EF/migrations framework needed given the codebase's existing plain-ADO.NET style.

---

## 3. Architectural approach for the whole build

To stay consistent with what's already here and avoid introducing parallel patterns:

- **Stay in Web Forms postback model.** Every screen becomes real `asp:` controls (GridView/Repeater/ListView for lists, TextBox/DropDownList/FileUpload for forms) bound in code-behind via `DBHelper`. No MVC, no Web API layer bolted on — the proposal itself says Web Forms + code-behind.
- **"API endpoints"** in this stack means: (a) postback event handlers for standard form submissions (majority of the app), and (b) a small number of **`.ashx` generic handlers** or **`[WebMethod]` static PageMethods** only where real AJAX is needed — Google Maps autocomplete, unread-notification badge polling, live status refresh on `track-donation.aspx`. Keep this list short.
- **One `DonationService` / `UserService`-style static class per domain**, thin wrappers over `DBHelper` (mirrors what `PasswordHelper`/`SessionHelper` already do), not a full repository/DI layer — matches project scale.
- **`login.aspx` (root) is the canonical, live auth implementation** (confirmed §1.2b) — build all future auth-adjacent work against it. `TestRegLogin/` is safe to delete during Phase 0 cleanup; it's unreferenced.
- **File uploads** (donation photos) go to `~/uploads/images/`, which already exists — use `FileUpload` control + `Path.GetRandomFileName()`-style naming to avoid collisions/overwrites, validate extension + size server-side.
- **Google Maps**: store `Google_Maps_API_Key` in `Web.config` `<appSettings>`, use Places Autocomplete JS on the pickup-address field, Static/Embed Map on tracking pages. No server-side Maps SDK needed — it's a client-side JS integration plus geocoding lat/lng on save (either client-side via Places `PlaceResult`, or a lightweight server geocode call).
- **Email**: `System.Net.Mail.SmtpClient` wrapped in a `NotificationService.SendEmail(...)`, credentials from `Web.config`. Pair every email with a row in `Notifications` so there's always an in-app record even if SMTP fails — don't let email delivery block the underlying DB transaction.

---

## 4. Phased Roadmap

### Phase 0 — Foundation & Stabilization *(prerequisite for all else)*
**Complexity: Low–Medium | Est. 1–2 days**

- **Features**: fix the launch-blocking bugs in §1.3 before adding anything new.
- **Dependencies**: none — this is the starting point.
- **Backend**:
  - ~~Delete `TestRegLogin/`~~ — done, see §1.2b.
  - ~~Add `SessionHelper.RequireRole(this, "X")` to every dashboard/feature page's `Page_Load`~~ — done, all 15 pages (6 Admin, 6 Donor, 2 NGO, 1 Volunteer) now call it with the matching role string.
  - ~~Create `~/Unauthorized.aspx` and `~/Error.aspx`~~ — done, both added (styled to match the app, `Error.aspx` shows exception details only when `Request.IsLocal`), and registered in `LeftoverFood.csproj`.
  - `Web.config` connection string decision — moot for now, see §1.3's note: the pending edit reverted itself outside this session: file matches HEAD (`MyDbConnection` + `FoodDB` both present, `LeftoverFood` DB on `Elitebook\SQLEXPRESS`, `system.codedom` intact). Still worth a deliberate look before Phase 1.
  - ~~Upgrade `PasswordHelper` to a salted hash~~ — done. `PasswordHelper.cs` now uses PBKDF2/`Rfc2898DeriveBytes` (SHA-256, 100k iterations, random 16-byte salt, format `PBKDF2$iter$salt$hash`), with `VerifyPassword` still accepting the old unsalted-SHA256 format for backward compatibility. `login.aspx.cs` now transparently rehashes to the new format on the first successful login after this change (`PasswordHelper.IsLegacyHash` check + `UPDATE Users SET PasswordHash = ...`).
- **Frontend**: none new; just make sure redirect targets in code-behind match real file names/casing.
- **DB/schema**: ~~run the full `schema.sql` from §2 against a fresh `LeftoverFoodDB`~~ — done. Discovered mid-Phase-0 (via direct `sqlcmd` access to the local `SQLEXPRESS` instance) that `LeftoverFoodDB` already existed with real data: 8 seeded `Users` rows (one per role, all `IsVerified=1`) and a schema that predated and diverged from this document for `Users`/`FoodDonations`/`FoodRequests`/`Ratings`. Also found three superseded legacy tables (`UsersOLD`, `Deliveries`, `EmergencyMode`, all empty) and an unrelated `UserLoginLogs` audit table (1 row, not referenced by any code, left alone). Per your direction, reconciled the live DB to match this roadmap: `Users` was `ALTER`ed additively (columns widened/added, all 8 rows preserved, existing `CK_Users_Role` check constraint on the 4 roles preserved), `FoodDonations`/`FoodRequests`/`Ratings` were dropped and recreated against the schema in §2 (all were empty, zero data loss), and the three legacy tables were dropped. Full FK graph re-verified afterward — 17 constraints, all consistent. Migration scripts are in `Database/` (`phase0_schema_migration.sql` + two follow-up fixes for constraints SQL Server wouldn't let the first pass touch directly) alongside the original `schema.sql`.
- **Models/services**: none new.
- **RBAC**: this phase *is* the RBAC fix — currently nonexistent at runtime despite the helper being written.
- **Testing**: manually confirm each role can only reach its own folder; confirm an unapproved user is blocked at login; confirm SQL Express connects with the finalized `Web.config`.
- **Risks**: forgetting a page in the `RequireRole` sweep leaves an open door; migrating password hashes needs care so existing test accounts aren't locked out.

### Phase 1 — Admin: User Verification (unblocks every other role) — ✅ IMPLEMENTED

- **Features**: `Admin/admin-dashboard.aspx` now has a live "Pending Verifications" queue (Verify/Reject, all roles — not NGO-only like the original mockup), a live "Registered Users" table with Ban/Unban (`IsActive`), and 4 real stat counters (Total Users, Total Donations, Verified NGOs, Pending Approvals) replacing the fabricated mockup numbers.
- **Backend**: `Admin/admin-dashboard.aspx.cs` — `BindPendingUsers()`/`BindAllUsers()`/`BindStats()` query `Users` directly via `DBHelper` (no separate service class — matches the codebase's existing inline-query style, and there's only one consumer so a `UserService` layer would be premature). `rptPending_ItemCommand` handles Approve (`IsVerified=1`) / Reject (`DELETE` — see note below). `rptUsers_ItemCommand` handles Ban/Unban (`IsActive`), with a self-protection check so an admin can't ban their own account.
- **Frontend**: converted the static mockup's hardcoded cards/table rows into `asp:Repeater`-bound sections, added the missing `<form runat="server">` (the page had none — no postback control could have worked at all before this), wired the sidebar Logout link to the previously-unused `SessionHelper.Logout`.
- **DB**: none beyond Phase 0 schema.
- **Design decision — Reject deletes the row**, it doesn't set a "Rejected" status. There's no rejected-state column and nothing consumes a rejection reason yet (that's Phase 4/notifications territory), so a pending registration that's rejected is just removed; the person would need to re-register. Flag if you'd rather keep a soft-rejected audit trail instead.
- **Follow-on fix**: `login.aspx.cs` previously never checked `IsActive` at all — a banned user could still log in. Now checks it and blocks with "Your account has been suspended."
- **RBAC**: Admin-only (`SessionHelper.RequireRole(this, "Admin")`, already wired in Phase 0).
- **Testing**: see chat — register a new user, confirm it appears in Pending Verifications, Verify it, confirm login now works; Ban an existing user, confirm login is now blocked with the suspended message; confirm an admin can't ban themselves.
- **Not yet wired** (left as static mockup, later phases): "Recent Donations (All)" table, "System Health" bars, "Quick Actions" (report export, broadcast), and most sidebar nav links (`#`/`.html` placeholders) — all depend on data/features from Phase 2 onward.

### Phase 2 — Core Donation Flow (Donor → Admin → NGO) — ✅ IMPLEMENTED

- **Features**: `donate-form.aspx` now inserts real `FoodDonations` rows; `food-approvals.aspx` lists real pending donations sorted by expiry urgency with working Approve/Reject; `ngo-dashboard.aspx`'s "Available Donations" table lists real `Approved` donations with working Accept.
- **Scope correction found mid-phase**: `ngo-active-requests.aspx` (the page the original plan named for browsing/requesting) turned out to actually be a **post-acceptance delivery-tracking** page (pickup/in-transit/arrived, volunteer assignment, mini-timeline) — Phase 3 territory, not buildable yet since `DeliveryAssignments` has no data. There was no existing page for "NGO browses and requests" at all. Used `ngo-dashboard.aspx`'s "Incoming Donation Requests" table instead — it was already the right shape for this (a list with Accept/Decline), just needed real data.
- **Backend**: `donate-form.aspx.cs` validates and inserts into `FoodDonations` (`Status='Posted'`), including a photo upload to `~/uploads/images/` (JPG/PNG, 5MB cap, extension-checked). `food-approvals.aspx.cs` moves `Posted`→`Approved`/`Rejected`, stamping `ApprovedBy`/`ApprovedAt`. `ngo-dashboard.aspx.cs`'s Accept does a race-safe claim (`UPDATE ... WHERE Status='Approved'`, checks rows affected before inserting the `FoodRequests` row) so two NGOs accepting simultaneously can't both win — the second gets "just claimed by another NGO." `donor-dashboard.aspx.cs` lists the donor's own donations with a Cancel action (only while still `Posted`, sets `Status='Cancelled'`).
- **Frontend**: all mockup fields bound to real `asp:` controls; added a photo `FileUpload`; the Preferred-NGO dropdown is populated live from `Users WHERE Role='NGO' AND IsVerified=1`.
- **DB**: `FoodDonations`, `FoodRequests` (Phase 0 schema, unchanged).
- **Design decision — NGO visibility**: a donation is visible to an NGO if `PreferredNGOID IS NULL` (open to all verified NGOs) or matches that NGO's `UserID` (donor's explicit choice). No separate "browse all / filter by preference" UI yet — everything eligible just shows in one list.
- **RBAC**: enforced via existing `RequireRole` — Donor only sees/cancels their own; Admin sees all pending; NGO sees only `Approved` + open-to-them.
- **Testing**: see chat — post a donation as Donor, approve as Admin, accept as NGO, confirm status flows through and stats update on all three dashboards; confirm expiry validation rejects a past expiry time; confirm a Donor can cancel a still-`Posted` donation but not one already approved.
- **Not yet wired** (Phase 3+): `ngo-active-requests.aspx` (delivery tracking), "In Transit"/"Meals Served" stats (still 0 — no `DeliveryAssignments` data yet), donor's "Your Impact"/"Recent Activity" panels, admin's "Recently Processed" table is real but only shows today's actions.

### Phase 3 — Volunteer Assignment & Delivery Tracking — ✅ IMPLEMENTED

- **Features**: `Admin/volunteer-assign.aspx` lists real `Requested` donations (NGO accepted, no volunteer yet) with a live dropdown of verified/active Volunteers (annotated with each one's current active-delivery count) and a race-safe Assign action; a real "Already Assigned — Active Deliveries" table. `Volunteer/volunteer-dashboard.aspx` lists the logged-in volunteer's assigned tasks with "Confirm Pickup" / "Mark Delivered" actions, real Active-Tasks/Deliveries-Done counters, and a real "Recently Completed Deliveries" list. `NGO/ngo-active-requests.aspx` shows the NGO's accepted requests bucketed into Awaiting Pickup / In Transit / Arrived (derived from `FoodDonations.Status` + `DeliveryAssignments` timestamps) with a working "Confirm Receipt" that writes `ActualQuantityReceived`/`FoodCondition`/`Notes` back to `FoodRequests`, plus a real "Recently Completed" table. `Donor/track-donation.aspx` (previously a static standalone mockup with no `<form runat="server">` at all — added one) now takes `?id=`, enforces ownership (404s via a "not found" panel if the donation isn't the logged-in donor's), and renders a real 5-step timeline (Posted/Approved/Accepted/Picked Up/Delivered) plus a live expiry countdown, built entirely from `FoodDonations`/`FoodRequests`/`DeliveryAssignments` timestamps. A "Track" link was added to each row on `donor-dashboard.aspx`.
- **Backend**: `Admin/volunteer-assign.aspx.cs` does a race-safe claim (`UPDATE FoodDonations SET Status='Assigned' WHERE ... AND Status='Requested'`, checks rows affected before inserting the `DeliveryAssignments` row) — same pattern as Phase 2's NGO-accept race guard. `Volunteer/volunteer-dashboard.aspx.cs`'s Confirm Pickup/Mark Delivered update both `DeliveryAssignments.Status` (+`PickedUpAt`/`DeliveredAt`) and `FoodDonations.Status` together, scoped to `WHERE VolunteerID = @VolunteerID` so a volunteer can't touch someone else's assignment. `NGO/ngo-active-requests.aspx.cs`'s Confirm Receipt is scoped to `WHERE NGOID = @NGOID AND ActualQuantityReceived IS NULL` (idempotent — can't double-confirm).
- **Frontend**: all four pages converted from static mockup HTML/fabricated numbers to `asp:Repeater`-bound sections. Dropped mockup content that had no real backing data rather than leaving it fabricated: Admin's fake "Offline volunteers" stat and per-volunteer distance/rating chips (replaced with a real active-assignment count per volunteer); Volunteer's fake points/badges/rank card and self-serve "Nearby Available Pickups" (assignment is admin-driven in this design, not self-serve — replaced with a real "Recently Completed Deliveries" list); the donor tracking page's fake per-message email log (replaced with a one-line "not yet implemented" note, since Phase 4/Notifications doesn't exist yet).
- **DB**: `DeliveryAssignments` (Phase 0 schema, unchanged) — first phase to actually write to this table.
- **Design decision — status model source of truth**: `FoodDonations.Status` is authoritative and is what every other page (`donor-dashboard`, `ngo-dashboard`, `food-approvals`) already filters on; `DeliveryAssignments.Status` is kept in lockstep by the same code paths that update `FoodDonations.Status` (Assign/Pickup/Deliver all touch both in the same handler). The schema's `InTransit` and `Failed` `DeliveryAssignments` status values are unused by this build — the volunteer flow only ever produces `Assigned → PickedUp → Delivered`, folding "in transit" into the `PickedUp` state rather than adding a third volunteer-facing button with no distinct action behind it.
- **RBAC**: enforced via existing `RequireRole` — Admin-only assign page; Volunteer only sees/updates their own assignments (verified: a `PickedUp`/`Deliver` postback scoped by `VolunteerID` silently no-ops for another volunteer's assignment); Donor tracking page additionally checks `DonorID` ownership per-row, not just role (verified: another donor's donation ID returns "Donation not found", not the data).
- **Testing**: manually walked the full chain end-to-end via a fresh browser session against the real local DB — Donor posts → Admin approves → NGO accepts → Admin assigns Volunteer → Volunteer confirms pickup → Volunteer marks delivered → NGO confirms receipt → Donor's tracking page shows the completed 5-step timeline with real timestamps throughout. Also confirmed: a non-owner role gets `Unauthorized.aspx` on the tracking page; a donor guessing another donor's donation ID gets "not found"; the volunteer-assign dropdown's active-count annotation updates live after each assignment.
- **Not yet wired** (later phases): the Google Maps panel on `track-donation.aspx` (Phase 5), the rating form there (Phase 6c), and real email notifications anywhere (Phase 4) all remain static/disabled placeholders with honest "not yet implemented" labeling rather than fabricated data.

### Phase 4 — Notifications (in-app + email)
**Complexity: Medium | Est. 2–3 days**

- **Features**: in-app notification list (`notifications.aspx`), email alerts on approval/rejection/assignment/delivery.
- **Dependencies**: Phases 1–3 (needs real events to notify about).
- **Backend**: every state-change from prior phases also inserts a `Notifications` row and calls `NotificationService.SendEmail`.
- **Frontend**: bind `notifications.aspx` list, mark-as-read; small unread-count badge in the shared header (needs a tiny shared master page or user control if one doesn't exist yet — check `Site.Master` presence, currently none found, so a simple `UserControl` header include is the low-effort option).
- **DB**: `Notifications` (§2).
- **API endpoints**: postbacks for mark-as-read; optional PageMethod for badge count if you want it AJAX-live.
- **Models/services**: `NotificationService.Notify(userId, message, type)`, `.SendEmail(to, subject, body)` via `SmtpClient`.
- **RBAC**: users only ever see their own notifications.
- **Testing**: SMTP failure shouldn't roll back the underlying business transaction (e.g., donation still gets approved even if the email bounces) — wrap email sending in try/catch, log, don't rethrow into the main flow.
- **Risks**: storing real SMTP credentials — keep them in `Web.config` (not committed with real secrets) or use an app password; rate-limit/batch if broadcasting to many users (relevant again in Phase 6's Emergency broadcast).

### Phase 5 — Google Maps Integration
**Complexity: Medium | Est. 2 days**

- **Features**: address autocomplete on `donate-form.aspx` pickup address; map view on `track-donation.aspx`/`ngo-active-requests.aspx` showing pickup location.
- **Dependencies**: Phase 2 (donation form must exist and have `PickupAddress`/`City` fields wired).
- **Backend**: none beyond persisting `Latitude`/`Longitude` alongside the address.
- **Frontend**: Google Maps JavaScript API (Places Autocomplete widget + embedded map), API key from `Web.config appSettings`, injected into the page via `<%= ConfigurationManager.AppSettings["GoogleMapsApiKey"] %>` or a `ClientScript` registration.
- **DB**: `Latitude`/`Longitude` columns already included in §2's `FoodDonations`.
- **API endpoints**: none server-side; pure client-side JS + one field write on form submit.
- **Models/services**: none new.
- **RBAC**: n/a.
- **Testing**: verify behavior when the API key is missing/quota-exceeded — form should still submit (address text is the fallback, map is progressive enhancement, not a hard requirement).
- **Risks**: API key exposed client-side is expected for Maps JS API — restrict it by HTTP referrer in Google Cloud Console rather than trying to hide it; this needs your own Google Cloud billing/API key, factor that into timeline (external dependency, not code work).

### Phase 6 — Advanced Features: Emergency Mode, Fraud Detection, Ratings, Reports
**Complexity: High | Est. 5–7 days total (can be split/parallelized across the 4 sub-features)**

**6a. Emergency Mode**
- Admin creates a broadcast (`emergency-mode.aspx` fields already defined: type, area, start time, duration, priority areas, message, audience); triggers `NotificationService` fan-out to all NGOs/Volunteers (or filtered by city).
- `EmergencyBroadcasts` table (§2). Consider a simple "priority" boolean on `FoodDonations` that Admin can flag during an active emergency so those donations sort first everywhere.
- Risk: fan-out to all users needs to not block the admin's request thread — for FYP scale (dozens–hundreds of users) synchronous is fine; note it as a scaling limit rather than solving it now.

**6b. Fraud/Duplicate Detection**
- Rule-based, not ML, given proposal's own wording ("time and location-based checks"): flag when the same donor posts near-duplicate donations (same address/food-type) within a short window, or when an NGO/Volunteer repeatedly cancels after accepting.
- `FraudFlags` table (§2); a scheduled check (simplest: run the check inline whenever a new donation is inserted, rather than building a background job/Windows Service — matches the app's request-driven architecture).
- Admin reviews flags on `fraud-detection.aspx`, can dismiss or suspend the user (`Users.IsActive = 0`).
- Risk: false positives (a legitimate restaurant posting daily at the same address) — tune thresholds conservatively, always leave it as an Admin review queue, never auto-block.

**6c. Ratings/Trust**
- After a delivery completes, Donor rates NGO/Volunteer and vice versa (`ratings.aspx`, fields already defined: select donation, stars, comments).
- `Ratings` table (§2); `Users.TrustScore` recalculated as a rolling average on each new rating (simple `AVG()` query, recompute-on-write is fine at this scale — no need for incremental aggregation).
- Risk: only allow rating a donation the rater actually participated in and only once per donation — enforce with a unique constraint on `(DonationID, RaterID)`.

**6d. Reports & Analytics**
- `reports.aspx`: dashboard charts (donations over time, waste reduced, by-city breakdown) + PDF/Excel export.
- Backend: aggregate queries via `DBHelper.ExecuteQuery`; for export, add a lightweight library — `ClosedXML` (Excel) and a PDF library (`iTextSharp`/`itext7` or similar) via NuGet, since nothing is referenced yet in `packages.config`.
- Risk: this is the one phase introducing a new external dependency — pick libraries compatible with .NET Framework 4.7.2 (not .NET Core-only packages).

---

## 4b. Cross-cutting fixes applied post-Phase-2 (bugs found via real testing)

- **Bug: `System.ArgumentException: The SqlParameter is already contained by another SqlParameterCollection`** — `Donor/donor-dashboard.aspx.cs`'s `BindStats()` built one `SqlParameter[]` and passed the same array/instance into 4 separate `DBHelper.ExecuteScalar` calls. A `SqlParameter` can only belong to one command's parameter collection at a time, so the 2nd call threw — this crashed the Donor dashboard immediately after login. Fixed by constructing a fresh `new SqlParameter[] { ... }` inline at each call site. Audited every other `DBHelper`-calling file in the project for the same pattern — nothing else had it.
- **Logout wasn't wired anywhere except Admin's dashboard.** All 13 role pages had a static `<a href="login.html">Logout</a>` — dead link, and even if `login.html` existed it wouldn't have cleared the session. Also found **9 of these pages had no `<form runat="server">` at all**, meaning no postback control could have worked on them regardless. Fixed across all 13 pages (`Admin`: admin-dashboard, food-approvals, volunteer-assign, emergency-mode, reports, fraud-detection · `Donor`: donor-dashboard, donate-form's sidebar N/A, ratings, profile, notifications · `NGO`: ngo-dashboard, ngo-active-requests · `Volunteer`: volunteer-dashboard) — added the missing `<form>` tags where absent, converted the link to `asp:LinkButton` wired to `SessionHelper.Logout(this)` (a method that existed since Phase 0 but nothing ever called).

---

## 5. Cross-cutting: Testing Strategy

Given this is Web Forms (no built-in unit-test-friendly separation of concerns), realistic testing for this project size:
- **Manual test matrix per phase**: one row per role × one row per happy path + 1–2 edge cases (already called out per phase above). Track this as a simple checklist, not automated UI tests — disproportionate effort for an FYP timeline.
- **SQL-level sanity checks**: after each phase, spot-check the DB state directly (status transitions, foreign keys) rather than trusting only the UI.
- If you do want any automated coverage, the highest-value target is `PasswordHelper`/`DBHelper`-adjacent pure logic (e.g., a status-transition validator) pulled into small testable static methods — not full page/UI automation.

---

## 6. Suggested Build Order & Complexity Summary

| Order | Phase | Complexity | Blocks |
|---|---|---|---|
| 1 | Phase 0 — Foundation & Stabilization | Low–Medium | Everything |
| 2 | Phase 1 — Admin User Verification | Low | All role-based testing |
| 3 | Phase 2 — Core Donation Flow | High | Phases 3–6 |
| 4 | Phase 3 — Volunteer Assignment & Tracking | Medium–High | Phase 4 (delivery notifications) |
| 5 | Phase 4 — Notifications | Medium | Phase 6a (emergency broadcast reuses it) |
| 6 | Phase 5 — Google Maps | Medium | Independent — can be done in parallel with Phase 4 |
| 7 | Phase 6 — Emergency Mode / Fraud / Ratings / Reports | High | Nothing — do these last, they're additive |

**Recommendation on where to start today**: Phase 0's RBAC fix + Phase 1's approval flow together are small, well-scoped, and unblock literally every other feature and every future testing session — that's the natural first coding session.

---

*This document is a working reference, not committed to git — update it as phases complete or scope shifts.*
