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

> **Note:** this table is the *original* pre-build audit. Only rows touched by a later phase have been updated in place, so a 🔴 here means "missing when this document was written", not necessarily today — Phases 0–5, 6a, 6b and 6c have all landed since. The per-phase sections in §4 are authoritative.

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
| Emergency Mode | ✅ Built in Phase 6a — real broadcasts with audience targeting, plus a priority flag that sorts first on approvals and NGO lists |
| Duplicate/Fake donor detection | ✅ Built in Phase 6b — five inline rules feeding an admin review queue; never auto-blocks |
| Report export (PDF/Excel) | ✅ Built in Phase 6d — CSV exports (Excel-native) and print/Save-as-PDF; no export library needed |
| Food waste analytics | ✅ Built in Phase 6d — live KPIs, charts, expiry analysis, all period-scoped |
| Ratings/trust system | ✅ Built in Phase 6c — shared `~/Ratings.aspx`, all three participant roles rate each other |

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
- **Not yet wired** (later phases): the Google Maps panel on `track-donation.aspx` (Phase 5), the rating form there (Phase 6c), and real email notifications anywhere (Phase 4) all remain static/disabled placeholders with honest "not yet implemented" labeling rather than fabricated data. *(All three have since been done — Phase 5 replaced the map panel, Phase 4 the email log, and Phase 6c swapped the disabled rating form for a link through to `~/Ratings.aspx`, shown only once the donation reaches `Delivered`.)*

### Phase 4 — Notifications (in-app + email) — ✅ IMPLEMENTED

- **Features**: every state change in Phases 1–3 now raises a notification. In-app notifications are listed on a new shared `~/Notifications.aspx` (all four roles) with unread filtering, mark-as-read, mark-all-read and delete; the topbar bell shows a live unread count on every page; email is sent alongside via Gmail SMTP. `Donor/notifications.aspx`'s preference toggles now actually persist and are honoured.
- **Scope correction found mid-phase**: this plan assumed `Donor/notifications.aspx` was the notification *list* ("bind notifications.aspx list, mark-as-read"). It is not — it is a **settings** page (13 toggle switches, a sample-email preview, an SMTP status card, and a small recent-activity log). Worse, Admin/NGO/Volunteer had **no notifications page at all**, despite being recipients in 6 of the 8 events. So the list was built as a new root-level `~/Notifications.aspx` shared by all four roles, and the Donor page was kept as what it actually is — preferences.
- **Backend**: new `NotificationService.cs` at the project root (flat static class over `DBHelper`, matching `PasswordHelper`/`SessionHelper` — no DI, no repository layer). `Notify(userId, subject, message, type, eventKey, linkUrl)` does one query for recipient + preference (`LEFT JOIN NotificationPreferences` + `ISNULL(...,1)`), inserts the `Notifications` row, then best-effort emails. `NotifyRole("Admin", ...)` fans out to verified, active admins. Everything is fail-soft: `Notify` catches its own exceptions and logs to `~/App_Data/notification-errors.log` rather than rethrowing, because every caller is a business transaction that has *already committed* — a bounced email must never surface as a failed approval.
- **Trigger points** (8 handlers, all inside the existing `rowsAffected > 0` guards so a lost race never notifies): account verified/rejected and banned/unbanned (`admin-dashboard`), donation posted (`donate-form`, → donor + all admins), approved/rejected (`food-approvals`), NGO accepts (`ngo-dashboard`, → donor + all admins), volunteer assigned (`volunteer-assign`, → volunteer + donor + NGO), pickup and delivered (`volunteer-dashboard`, → donor + NGO), NGO confirms receipt (`ngo-active-requests`, → donor).
- **DB**: `Database/phase4_notifications.sql` (re-runnable). Found the same class of drift Phase 0 hit — the live `Notifications` table was **missing the `Type` column entirely** despite `schema.sql` declaring it `NOT NULL`, and `Message` was `varchar(500)` not `nvarchar(500)`, which would have silently mangled Urdu/non-ASCII food descriptions. Table held 0 rows, so both were fixed in place. Also added `Notifications.LinkUrl` (makes a notification clickable through to the donation it is about), an index on `(UserID, IsRead, CreatedAt DESC)` since the bell badge queries it on every page load, and the new `NotificationPreferences` table.
- **Design decision — sparse preferences**: a user with no `NotificationPreferences` row for an event counts as opted *in*. The table only ever stores deliberate opt-outs, so new users and newly added event keys work with no backfill.
- **Design decision — mandatory notifications**: account status changes (verified / suspended / reinstated) pass a `null` event key, which skips the preference check entirely. You should not be able to opt out of being told your account was suspended. Rejection is the one place that emails directly rather than via `Notify()`, because Phase 1's reject *deletes* the user row — the recipient is looked up before the delete and there is no user left to own an in-app row afterwards.
- **Cross-cutting: sidebar extracted to `~/Controls/RoleSidebar.ascx`.** The new shared page lives at the app root and so cannot inherit any single role master, but it still needs the signed-in role's sidebar. Rather than adding a fifth copy of that markup, the four role masters' `<aside>` blocks (plus their four duplicate `IsActive()` helpers and four `btnLogout_Click` handlers) were collapsed into one user control, registered globally in `Web.config`'s `<pages><controls>` so no file needs its own `<%@ Register %>`. This continues Phase 0's de-duplication rather than undoing it. The sidebar also gained a real Notifications link with an unread badge — previously `#` on NGO/Volunteer.
- **Honesty pass on the settings page** (same approach Phase 3 took): 6 of the 13 toggles have no code path raising them (`ExpiryWarning`/`MonthlyImpact` need a scheduler this app doesn't have; `RatingReceived` was Phase 6c and is **now live** — its "Not active yet" tag has been removed and it fires from `~/Ratings.aspx`; `EmergencyAlert` was Phase 6a and is **now live** too, firing from `Admin/emergency-mode.aspx`; `NewMessages`/`BadgeAlerts` have no feature at all). The remaining four are labelled **"Not active yet"** with the reason, and still persist, so they take effect the moment the feature lands. The SMTP card's fabricated `Connected` / `2,184 emails sent` was replaced with real `Web.config` values and a genuine Configured / Not configured status; the hardcoded `ahmed@restaurant.pk` field now shows the real account email; the fabricated "Recent Notifications" rows are now real data; and the email preview renders through the **actual** email template so it cannot drift from what is really sent.
- **RBAC**: `~/Notifications.aspx` uses `RequireLogin`, not `RequireRole` — every role has notifications and the page is identical for all of them. Every query is scoped by `UserID`, so mark-read/delete on a forged `NotificationID` affects zero rows rather than touching another user's data.
- **Verification**: full `MSBuild -t:Rebuild` clean, plus a full `aspnet_compiler` precompile of every `.aspx`/`.master`/`.ascx` (MSBuild alone does not compile markup, so control registrations and `<%# %>` bindings would otherwise only fail at runtime). Every SQL path in `NotificationService` was executed directly against the live DB and cleaned up afterwards: preference default-to-opted-in, the upsert (UPDATE returns 0 → INSERT), opt-out being honoured, unread count, `TOP (@Max)` listing, admin fan-out recipients, and the unique constraint correctly rejecting a duplicate preference row. Unicode round-trip confirmed (`UNICODE()` returned 1576 — Arabic *beh* — proving the `nvarchar` fix works).
- **Not yet done / limits**: email sending is **synchronous** with a 15s SMTP timeout (default is 100s, which would freeze an admin's Approve postback for over a minute). Fine at this scale, but the Phase 6a emergency broadcast to hundreds of users will need a queue. *(Phase 6a landed and made the in-app half a single bulk `INSERT … SELECT`; the email half is still one send per recipient on the request thread, and the admin page now warns when SMTP is on and the audience exceeds 25.)* `Smtp.Enabled` ships `false` with placeholder credentials — see below.

> **To turn email on**: generate a Gmail **App Password** (Google Account → Security → 2-Step Verification → App passwords; a normal account password will not work), then set `Smtp.User`, `Smtp.Password`, `Smtp.FromAddress` and `Smtp.Enabled="true"` in `Web.config`. Until then the app runs normally and notifications are in-app only. **Do not commit a real app password** — `Web.config` is tracked by git.

### Phase 5 — Maps & Volunteer Tracking — ✅ IMPLEMENTED

> **Provider changed from Google Maps to OpenStreetMap.** Google Maps requires a Google Cloud account with a card on file even to stay inside the free credit. Built on **Leaflet + OSM tiles + Nominatim geocoding** instead: no API key, no account, no billing. This is a deliberate deviation from the proposal's "Google Maps integration" wording — worth confirming with your supervisor, since only the tile URL and geocoder would need to change to swap back.

- **Features**: donations are geocoded server-side on save; the donor tracking page shows a real map with pickup point, NGO drop-off and the volunteer's live position; NGO active-requests rows each get a pickup map; volunteer task rows get a route map and an Open-Directions link; volunteers can opt in to sharing their live location during a delivery.
- **Backend**: `GeocodingService.cs` (Nominatim) honours the service's usage policy in code — identifying User-Agent, a process-wide 1-request/second throttle, TLS 1.2 pinned, and results cached in `GeocodeCache` so an address is only ever resolved once. Every failure path returns null; a geocode outage can never stop a donation posting. `LocationHandler.ashx` is the only AJAX endpoint (position report + position read).
- **DB** (`Database/phase5_maps.sql`): `VolunteerLocations`, `GeocodeCache`, `Users.ShareLocation` (opt-in, defaults 0), `FoodDonations.GeoPrecision`. `Latitude`/`Longitude` already existed from Phase 0 and were verified against the live table — no drift this time.
- **Key finding — most addresses do not geocode.** Of the 6 donations present, only **one** matched Nominatim exactly (four were test data, one had a typo). Showing no map for 5 of 6 donations reads as broken, so `GeoPrecision` records what we actually got: `Exact`, `City`, or NULL. A `City` point renders but is labelled **"Approximate — city level only"** on the marker, in the card header and under each row; NULL shows the address as text with no map at all. Dropping a pin at the city centre and presenting it as the pickup address would be the same class of fabrication Phases 3 and 4 removed. Backfill: 1 Exact, 5 City.
- **Design decision — straight line, not a road route.** The tracking map joins pickup and drop-off with a dashed line. Real road routing needs a directions service; drawing a road-looking route we didn't compute would misrepresent distance and travel time. The volunteer's Directions button links out to openstreetmap.org, which does route properly.
- **Privacy — volunteer live location.** The Phase 3 placeholder promised "real-time volunteer location" when nothing tracked volunteers. It is now real, and deliberately constrained: opt-in and off by default, settable only by the volunteer themselves; re-checked server-side on *every* ping so switching it off stops collection immediately even from a stale tab; positions only ever attach to an active `Assigned`/`PickedUp` assignment resolved from the session, never from the request body; readable only by that donation's donor, receiving NGO, or an Admin, with unauthorised reads returning 404 so the endpoint can't be used to probe which donation IDs exist; positions older than 15 minutes stop being served rather than shown as current; and **turning the toggle off deletes the stored positions**, not just hides them.
- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile of every page, master, control and the new `.ashx`. Nominatim confirmed working against the real addresses in the database.
- **Verified in the browser** (end-to-end session, 15 Aug 2026): Leaflet loads and renders real OSM tiles with markers and attribution on `track-donation.aspx`, the volunteer route map renders, and the Directions link carries real coordinates for both pickup and drop-off. Live Nominatim geocoding resolved a new donation to `Exact`.

- **Tracking loop verified end-to-end (15 Aug 2026, follow-up session).** A seeded in-flight delivery was opened on the donor's tracking page against the real database: the poll ran on a clean 20-second cadence and rendered the volunteer's live marker with its accuracy radius. Every branch of `LocationHandler`'s report path was then driven directly from a signed-in volunteer session — a valid ping inserted a row (`24.905000 / 67.075000 / 8.25`, exact decimals preserved), out-of-range coordinates returned `400`, having no active assignment returned `{ok:false, tracking:false}`, and **flipping `Users.ShareLocation` to 0 produced a `403` on the very next ping with no re-login** — confirming the consent re-check really does run per ping rather than at page load. **Still untested**: only the browser's geolocation permission prompt itself, which needs a real device that will grant location; everything downstream of it is now covered.

- **Bug found and fixed in that session — neither loop was ever torn down.** `fb-map.js` armed `setInterval` and `volunteer-dashboard.aspx` armed `watchPosition`, and nothing anywhere called `clearInterval` or `clearWatch`. A donor's tracking page left open kept polling every 20 seconds **forever** after the delivery finished, each request answered "Delivery complete."; a volunteer's dashboard kept waking on every GPS change until the tab was closed, draining a phone battery to post pings the server would only reject. Fixed on both sides, with the terminal signal coming from the server rather than from the client matching on message text: `NoPosition` gained a `done` flag, set **only** for the delivery ending — "no volunteer yet", "sharing is off" and "position is stale" can all still resolve, so those keep the poll alive. The reader also stops on `401`/`403`/`404` (which cannot fix themselves) while continuing through `500`s and dropped connections (which can). The volunteer's watch is released on `401`, on `403`, and on `tracking:false`; any postback re-runs the script, so starting the next delivery arms a fresh watch. **Verified by request count**: across two page loads the poll fired exactly three times each, then went silent through four further intervals once the delivery was marked `Delivered` mid-session.

---

### Phase 5 — Google Maps Integration *(original plan, superseded by the above)*
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

**Status: all four sub-features done (6a, 6b, 6c, 6d).** The last stub in the app, `Donor/profile.aspx.cs`, has since been built out as **Phase 7** below — it belonged to no phase in this document, which is why it was left until last. There are now no stub pages left.

**6a. Emergency Mode — ✅ IMPLEMENTED**

- **Features**: `Admin/emergency-mode.aspx` now declares real emergencies. The status banner reflects the actual active broadcast (type, area, start, how many people it reached) with a working Deactivate. The activation form writes an `EmergencyBroadcasts` row and fans a notification out to a targeted audience, with a **live recipient count that updates as you change city or audience** and a Preview that renders the real message through the real email template. The priority queue lists genuine in-flight donations with a working flag, history is real, and Quick Broadcast sends a message without declaring an emergency.

- **Backend**: `NotificationService.NotifyBroadcast(BroadcastAudience, …)`, alongside `CountAudience` / `CountUnknownCity`. A `BroadcastAudience` (roles + optional city + include-unknown-city) is resolved by one shared `BuildAudienceFilter`, used by both the count and the send, so **the number previewed cannot disagree with the number reached**. Roles expand into individually named `SqlParameter`s rather than being concatenated in. `emergency-mode.aspx.cs` keeps the page-level queries inline per the codebase's style.

- **Design decision — the in-app half is one statement, the email half is not.** `NotifyMany` loops `Notify()`, costing two round trips per recipient; that is fine for the handful of admins it was written for and wrong for a broadcast. `NotifyBroadcast` inserts every in-app notification with a single `INSERT … SELECT` that reproduces `Notify()`'s preference check as a `LEFT JOIN` (no preference row = opted in; a null event key is mandatory and skips the check). **Email is still one message per recipient on the admin's request thread**, exactly the scaling limit this document chose to accept. That limit is now surfaced in the UI rather than only in docs: with SMTP configured and more than 25 recipients the page warns that it may take a while. The real fix is a queue and a worker, which this app has no host for.

- **Key finding — city targeting would have silently reached almost nobody.** `Users.City` is nullable and mostly unset: **24 of 28 accounts had no city on record**. A strict `City = @city` filter for a Karachi alert resolves to **2 recipients**; including users with no city set resolves to **15**. Silently dropping 13 people from an emergency alert is the worst failure mode this feature has, so unknown-city users are **included by default**, the behaviour is an explicit checkbox, and the count next to it names the number it adds. Verified against the live DB across five audience combinations.

- **DB** (`Database/phase6a_emergency.sql`, re-runnable): `EmergencyBroadcasts` already existed from Phase 0 and matched §2 — no drift this time. Added `EndedAt` (§2 gave the table an `IsActive` bit but no end timestamp, so history could only ever show a start date), `RecipientCount` (recorded at send time, not recomputed later — users get verified, banned or change city afterwards, so re-deriving reach from today's `Users` table would print a different number every visit), an index on `(IsActive, CreatedAt DESC)`, and `FoodDonations.IsPriority`.

- **Design decision — one emergency at a time.** Declaring a new emergency closes whatever was running (`IsActive = 0, EndedAt = GETDATE()`), so the banner and the active-broadcast lookup never have to choose between two rows. Deactivating sends **no** all-clear broadcast: that would be a second fan-out to everyone, and the app has no way to confirm an emergency has actually passed. Priority flags survive deactivation — an admin set them by hand and they stay until unset by hand.

- **Design decision — `IsPriority` is a manual flag, and it actually does something.** The mockup showed 🔴 URGENT / 🟡 HIGH / 🟢 NORMAL bands as if derived by the system; every input such a score would use (expiry, volume) is already the queue's sort key, so a derived band would just restate the sort. What an admin cannot otherwise express is "this one matters more than the sort suggests". The flag now sorts first on `Admin/food-approvals.aspx` **and** in every NGO's available-donations list — without those two `ORDER BY` changes the flag would have been decorative.

- **Honesty pass — four mockup promises had no implementation anywhere and were removed, not restyled**:
  - *"All NGOs get immediate SMS + email broadcast"* → there is no SMS provider in this project and adding one means a paid gateway. Now reads in-app + email, with the absence of SMS stated.
  - *"48-hr Fast Track — approval time reduced to 15 minutes (from standard 2 hours)"* → **entirely fictional**. There is no approval SLA, no timer, and nothing anywhere measures how long an approval takes. Card deleted.
  - *"Auto-Assign to nearest NGO"* → no auto-assignment exists (NGOs claim donations themselves in Phase 2; admins assign volunteers by hand in Phase 3), and Phase 5 established that most addresses only geocode to city level, so "nearest" is not something this data supports. Button deleted.
  - *Ramadan Mode's Iftar/Sehri time windows and "auto-prioritize dates, fruits, drinks"* → time-of-day scheduling needs a scheduler this app does not have. It is now what it can honestly be: a preset that fills in the activation form, with the limitation stated on the card.
  - Also gone: the hardcoded history timeline ("1,200 meals distributed in 24hrs" — a figure nothing in this system can produce; replaced with recipient counts, which it genuinely knows) and the three fabricated priority-queue rows.

- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile. Audience resolution smoke-tested against the live database across all five combinations above, including the bulk-insert `SELECT` (row count matches the previewed audience). Server-side length checks added for `Message` and `PriorityAreas` — `MaxLength` is a client hint and is not enforced at all on a multiline `TextBox`, so a long paste would otherwise have surfaced as a SQL truncation error.

- **Verified in the browser** (end-to-end session, 15 Aug 2026): a real Flood emergency was declared for Karachi and **reached 17 people** through the bulk insert; the banner flipped to ACTIVE with the correct summary, `RecipientCount` recorded 17, Deactivate stamped `EndedAt`, and priority flags correctly survived deactivation. Preview rendered through the real email template with the affected area and priority locations folded in. **The city finding was reproduced live**: with Karachi selected, unticking "also notify users with no city" dropped the audience from **17 to 2**, and the panel correctly warned "15 users have no city set".

**6b. Fraud/Duplicate Detection — ✅ IMPLEMENTED**

- **Features**: `FraudDetectionService.cs` implements five rule-based checks that run inline on the actions that could trigger them. `Admin/fraud-detection.aspx` is a real review queue — live stats, a status-filtered flag list with Dismiss / Mark Reviewed / Suspend, a claimed-vs-received log for every confirmed delivery, and a manual "Run scan now". Admins get a notification whenever a flag is raised.

- **The five rules, and why each threshold is what it is**:
  | Rule | Fires when | Runs at |
  |---|---|---|
  | `DuplicateDonation` | same donor, same pickup address **and** category, within 6h | donation posted |
  | `RapidPosting` | 3+ donations by one donor within an hour | donation posted |
  | `RepeatedCancel` | donor has 3+ cancelled donations | donation cancelled |
  | `QuantityMismatch` | NGO records under 50% of claimed servings | NGO confirms receipt |
  | `UnverifiableLocation` | pickup address failed to geocode entirely | donation posted |

  Address alone would flag every restaurant that donates twice in an evening — the behaviour the platform exists to encourage — so duplicate detection needs address **and** category. Cancelled/Rejected siblings are excluded, because reposting after a rejection is the correct response to a rejection.

- **Scope correction — half of the roadmap's own rule cannot be written.** This plan specified flagging "when an NGO/Volunteer repeatedly cancels after accepting". **No such action exists anywhere in the app.** An NGO cannot un-accept a donation and a volunteer cannot drop an assignment; the only cancel path is a donor cancelling their own donation while it is still `Posted` (Phase 2), and the only other negative transition is an admin rejection. `RepeatedCancel` is therefore donor-only, and the NGO/volunteer half needs that action to exist first.

- **Design decision — a service this time, unlike 6c.** Phase 6c kept its queries inline because the page was the only consumer. Here there are four call sites (`donate-form`, `donor-dashboard`, `ngo-active-requests`, and the admin page's manual scan), which is exactly the condition that produced `NotificationService` in Phase 4. It shares that service's error log via a new `LogExternalError` rather than opening a second one.

- **Design decision — open flags suppress duplicates, reviewing re-arms them.** Every rule runs inline because there is no background job host (the same constraint that left `ExpiryWarning` dormant in Phase 4 and removed 6a's Ramadan time windows). An account-level rule like `RepeatedCancel` is still true on the donor's *next* action and every action after, so without suppression the queue would fill with copies of one finding. `Raise()` checks for an existing **Open** flag with the same subject first. It is deliberately **not** a unique constraint: once an admin reviews or dismisses a flag, the same pattern recurring later is a genuinely new finding and must raise again — an admin having looked once should not blind the system forever.

- **Nothing is ever blocked automatically**, per this document's own risk note. Every rule ends in the review queue. The mockup's "Auto-suspend high risk" toggle was removed on purpose rather than for lack of plumbing: a legitimate restaurant posting the same meal from the same address every evening is *indistinguishable* from the pattern these rules search for. Suspend reuses Phase 1's `Users.IsActive` switch (login already checks it, so there is no second notion of "blocked" to keep in step), carries Phase 1's don't-ban-yourself guard, closes the flag as Reviewed, and sends a **mandatory** notification — being suspended is not something a user may opt out of hearing about.

- **DB** (`Database/phase6b_fraud.sql`, re-runnable): `FraudFlags` already existed from Phase 0 and matched §2, with **no CHECK constraints on `FlagType` or `Status`** — both are plain `NVARCHAR`, so `FlagType`/`FlagStatus` in the service are the real vocabulary. Added `ReviewedAt` (§2 recorded *who* closed a flag but not *when* — the same gap `EndedAt` filled in 6a, and worse here since a review queue that can't distinguish an hour ago from March is a poor audit trail), plus indexes on `(Status, FlaggedAt DESC)` and `(UserID, FlagType, Status)` — the latter is what makes the suppression check cheap now that it runs on every donation posted.

- **Honesty pass — two of the mockup's six advertised rules had nothing behind them and are gone**:
  - *"Unverified Contact — flags accounts without phone verification"*: there is no phone verification in this project. `Users.Phone` is free text captured at registration and never checked, so **every** account would qualify and the flag would mean nothing.
  - *"NGO Reports — auto-flags after 2 NGO complaints"*: there is no complaint feature. An NGO can record what it received at Confirm Receipt — which is what `QuantityMismatch` uses — but cannot file a complaint.

  Also removed: the three hardcoded suspicious accounts ("user_4427", "Ghost Restaurant – Fast Bites", "Hamid Bakery"), the three hardcoded suspicious donations, the invented "318 verified clean" and "12 banned this month" counters, and the **"Auto daily scan runs at 2:00 AM"** banner with its frequency selector — nothing could have been running it. Scanning is now a button, and the page says so.

- **Known limitation — quantities are free text.** `FoodDonations.Quantity` is a string (`"1 Kg"`, `"10 Plates"`) and so is `FoodRequests.ActualQuantityReceived` (`"28 Plates"`). The claim is read from `Servings` (a real INT); the received side is parsed for its leading number and anything unparseable is **skipped rather than guessed at**. Units are not reconciled — `"1 Kg"` against `"10 Plates"` is not a comparison this data supports — which is why only a large shortfall against `Servings` counts.

- **Verification**: clean `MSBuild -t:Rebuild` plus full `aspnet_compiler` precompile. All five rule queries were run against the live database. **All five correctly raise nothing on the current data**: no donation shares an address+category, none were posted in bursts, donor 14 has 1 cancellation (threshold 3), donation #5 recorded 28 of 30 servings (93%, threshold 50%), and every address geocoded to at least city level. The free-text parse was confirmed on the real value — `"28 Plates"` → 28.

- **Verified in the browser** (end-to-end session, 15 Aug 2026): posting two donations from one donor at the same address and category raised `DuplicateDonation` automatically, and an NGO recording 15 of 40 claimed servings raised `QuantityMismatch` — the free-text parse read `"15 Plates"` correctly. Admin notifications fired to all four admins with the right deep link. The review queue rendered both flags, "Run scan now" raised 1 more, and Dismiss recorded `ReviewedBy` + `ReviewedAt`.

- **Rough edge found in testing**: the full scan flags **both sides** of a duplicate pair — #1007 as a near-duplicate of #1008 *and* #1008 of #1007 — so one incident produces two queue entries. The inline hook is correct (it only ever flags the newly-posted donation); it is `RunFullScan` that produces the reciprocal. Worth suppressing by only flagging the newer of a pair.

- **Latent issue noted, not fixed**: `FK_FraudFlags_User` is `NO_ACTION`, while Phase 1's Reject **deletes** the user row. Deleting a flagged account would fail on the FK. Not reachable today — the delete is scoped to `IsVerified = 0`, and unverified users cannot sign in to post donations, so they cannot be flagged. It would become reachable if rejection were ever widened to verified accounts.

**6c. Ratings/Trust — ✅ IMPLEMENTED**

- **Features**: a new shared `~/Ratings.aspx` lets every participant of a `Delivered` donation rate every other participant once — donor↔NGO, donor↔volunteer, NGO↔volunteer, which is the proposal's "and vice versa" in full. The page carries a real trust profile (average, star histogram, completed-delivery count, ratings count, open-flag count, computed trust level with progress to the next one), a "Rate a Completed Delivery" form, a filterable "Reviews Received" list and a "Ratings You've Given" list. `Users.TrustScore` is recomputed on every submission and `NotifyEvent.RatingReceived` — declared but dormant since Phase 4 — now actually fires.

- **Scope correction found mid-phase (same shape as Phase 4's)**: the plan named `ratings.aspx`, but that page existed **only under `Donor/`**. NGO and Volunteer had no ratings page at all, despite being half of every "and vice versa" pair. Rather than copy ~200 lines of markup into two more role folders — undoing the de-duplication Phases 0 and 4 did — the page moved to the app root as `~/Ratings.aspx` on `Site.master` + `RoleSidebar`, exactly the precedent `~/Notifications.aspx` set. `Donor/ratings.aspx(.cs/.designer.cs)` were deleted and the sidebar's Donor link repointed; NGO and Volunteer gained the link they never had. Admin is excluded (`~/Unauthorized.aspx`) — an admin never participates in a delivery, so has nobody to rate; aggregate trust reporting is 6d.

- **Backend**: `Ratings.aspx.cs`, inline queries over `DBHelper` per Phase 1's reasoning (single consumer, so no `RatingService` layer). The one genuinely shared piece of logic — "who may rate whom on this donation" — is a single `RateableSql` constant built from a `Participants` CTE (donor from `FoodDonations`, NGO from accepted `FoodRequests`, volunteer from `DeliveryAssignments`, all filtered to `Status='Delivered'`), self-joined on the current user to enforce "you were actually on this delivery". The **same constant** backs both the dropdown and the submit-time re-authorisation, so the list and the check cannot drift apart. `UNION`, not `UNION ALL`, so a donation with more than one assignment row can't offer the same volunteer twice.

- **DB** (`Database/phase6c_ratings.sql`, re-runnable): no new tables — `Ratings` already existed from Phase 0 and the live columns were verified to match §2. What changed is the constraints around it.

- **Design decision — the unique constraint had to widen.** Phase 0 built `UQ_Ratings_OnePerDonationPerRater` on `(DonationID, RaterID)`, following this document's own "only once per donation" wording. That contradicts the line above it: a delivery has three participants, so each rater has *two* counterparties. Under the old key a donor who rated the NGO could never rate the volunteer — the second insert would die on a duplicate key. Replaced with `UQ_Ratings_OnePerCounterparty` on `(DonationID, RaterID, RateeID)`, which keeps the property that matters (you can't rate the same person twice for the same delivery) while allowing one rating per counterparty. Table was empty, so nothing to migrate. Also added `CK_Ratings_NoSelfRating` and `IX_Ratings_Ratee_Created`.

- **Design decision — TrustScore is cached, but this page doesn't trust its own cache.** `Users.TrustScore` is recomputed in full (`AVG(Stars)` over ratings received) on every insert, per the plan. The profile card nonetheless reads the live `AVG` rather than the cached column, so a missed recompute could never show a user a wrong number about themselves; the cached column exists for *other* features to read cheaply. Users with no ratings hold `NULL`, not `0.00`, so "unrated" and "rated badly" stay distinguishable.

- **Honesty pass** (continuing Phases 3–5): the mockup's four per-category scores (Food Quality / Quantity Accuracy / Packaging / Punctuality) and its "94% Accuracy" tile were **removed** — `Ratings` has one `Stars` column, so there is nothing behind a four-way breakdown. The trust-level ladder was kept and is genuinely computed from real deliveries and real ratings, but its **"Benefits" column is gone**: auto-approval, featured listings, priority queues and "admin dashboard access" are behaviours no code implements, and listing them as earned would promise a functioning perk system. The table now says plainly that levels are recognition only. The "Flags" tile queries `FraudFlags` for real (currently 0 for everyone) rather than hardcoding a zero, so it starts working the moment 6b lands.

- **Security**: the posted `DonationID:RateeID` is never trusted — it is re-checked against `RateableSql` server-side before the insert, so a forged pair is rejected even though it round-tripped through the client. Verified directly against the live DB: a legitimate pair returns 1 row, a ratee who wasn't on that donation returns 0, and a rater who wasn't a participant returns 0. A double-submit that beats the check is caught by the unique constraint (`SqlException` 2627/2601) and reported as "already rated" rather than as an error.

- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile of every page, master and control. The participant query was run against the real database — for the volunteer on all three `Delivered` donations it returns exactly the 6 expected counterparty pairs, no duplicates.

- **Verified in the browser** (end-to-end session, 15 Aug 2026): the CSS star picker works — clicking a star label checks the hidden radio and `Request.Form["fbStars"]` read it back as 5. The rateable dropdown offered exactly the two counterparties of the delivered donation, the rating inserted, `Users.TrustScore` recomputed to 5.00 for the ratee only, the `RatingReceived` notification fired with the comment, and the rated pair correctly disappeared from the dropdown afterwards.

- **Bug found and fixed during that session**: `LoadProfile()` reused one `SqlParameter[]` across two `DBHelper` calls, which throws *"The SqlParameter is already contained by another SqlParameterCollection"* — ADO.NET binds a parameter instance to the command it is added to. The page failed to load at all. Replaced with a `MeParam(me)` factory that builds fresh instances per call. **This class of bug is invisible to the compiler and to `aspnet_compiler`** — only running the page finds it. The rest of the codebase was swept for the same pattern; nothing else reused an array across commands.

**6d. Reports & Analytics — ✅ IMPLEMENTED**

- **Features**: `Admin/reports.aspx` is now driven entirely by aggregate queries, scoped to a period the admin picks (This month / Last 30 days / This year / All time). Four KPIs with real period-over-period change arrows, a by-month bar chart, a computed SVG donut by category, top donors and top NGOs, expiry & waste analysis, a by-city breakdown, three CSV exports and a print/Save-as-PDF path.

- **Design decision — no new dependencies, agreed before building.** §6d planned ClosedXML and iTextSharp. Neither is used, and the project still has exactly the one NuGet package it started with:
  - **Excel → CSV with a UTF-8 BOM.** Excel opens it natively on double-click. The BOM is not decoration: without it Excel decodes as the system codepage and mangles Urdu or accented food descriptions — the same class of bug Phase 4 found from the other side when `Notifications.Message` turned out to be `varchar` rather than `nvarchar`. ClosedXML would have meant hand-resolving its dependency tree into a `packages.config` project with no `nuget.exe` present, producing something I could not verify actually opens.
  - **PDF → a `@media print` stylesheet plus the browser's Save as PDF.** The buttons say "Print / Save as PDF" rather than "PDF Format", because a button that opens a print dialog should not claim to download a file. **If your supervisor requires a server-generated PDF, this is the one thing here that would need a real library.**

- **CSV correctness**: RFC 4180 quoting (wrap on comma/quote/CR/LF, double embedded quotes), dates written invariant as `yyyy-MM-dd HH:mm` so `03/04` cannot mean March on one machine and April on another, and a leading `=`, `+`, `-` or `@` is prefixed with a quote — a donor-supplied food description starting with `=` would otherwise be executed as a formula when the file is opened (CSV injection). Downloads use `CompleteRequest()` rather than `Response.End()`, which raises a `ThreadAbortException` by design and would be logged as a failure by anything wrapping the call.

- **Derived rather than assumed**: `Status = 'Expired'` is in §2's status list but **nothing in this app ever writes it** — there is no scheduler to sweep for it. "Expired Donations" is therefore derived as *past `ExpiryTime` and never delivered*. Similarly "delivered before expiry" compares `DeliveryAssignments.DeliveredAt` against `FoodDonations.ExpiryTime` — both real columns, so it is measured rather than estimated. Meals use `Servings` (the only numeric quantity in the schema); `Quantity` is free text and cannot be summed.

- **Design decision — fulfilment excludes what the pipeline never owned.** The denominator is donations that got past `Posted` and were not rejected or cancelled. Counting admin rejections and donor changes of mind against the delivery chain would make the rate a measure of something else entirely.

- **Honesty pass**: the mockup was headed "April 2025" and every figure was a literal — 248 donations, 5,830 meals, a 94% fulfilment rate, four months of bars, five invented top donors, five invented NGOs, five cities. Its change arrows ("↑8%") had **no comparison period at all**; they now measure against the equal-length period immediately before, and render "no prior period" rather than a meaningless "↑100%" when the baseline is zero. Its advice box ("sending donor reminders earlier could reduce expiry by ~40%") was a prediction with no model behind it and now states only the count. Unrated users read "unrated" rather than "⭐ 0.0", since Phase 6c leaves `TrustScore` NULL until someone is actually rated.

- **Verification**: clean `MSBuild -t:Rebuild` plus full `aspnet_compiler` precompile. Every aggregate query was run against the live database and returns coherent figures — 7 donations, 52 meals, 3 delivered of 6 in-pipeline (**50% fulfilment, not the mockup's 94%**), 2 derived-expired, categories 6 Cooked / 1 Bakery, cities 6 Karachi / 1 Lahore, 2 of 3 deliveries completed before expiry, average assign→pickup 2.3 minutes. All four donors and all three NGOs currently show "unrated", exercising that path.

- **Verified in the browser** (end-to-end session, 15 Aug 2026): the page rendered live figures for August 2026 — 9 donations, 92 meals, 57% fulfilment, 2 derived-expired — with the month bars, real status breakdown and a correctly computed SVG donut (arc lengths 307.18 + 38.4 = 345.58, exactly the circumference, with chained offsets). The "no prior period" badge rendered correctly where the preceding period held no data. **The CSV export was driven over real HTTP and its bytes inspected**: `Content-Type: text/csv; charset=utf-8`, `Content-Disposition: attachment` with a timestamped filename, and the file starts `EF BB BF` — the UTF-8 BOM is present. Unrated users export as `unrated`, not `0.0`. **Still untested**: the print stylesheet, which needs a human to open the print dialog.

### Phase 7 — Account Profile — ✅ IMPLEMENTED

- **Features**: a shared `~/Profile.aspx` for **all four roles**. Every user can now edit their own name, email, phone, city, address and bio; Donors additionally get organization name, business type, CNIC/registration number and a preferred-NGO default; NGOs get organization name and registration number; Volunteers get a read-only mirror of their location-sharing state; Admins get the plain account fields. Everyone gets a working **change-password** form, a real Account Info card (ID, joined, last login, approval, status), a compact trust summary linking through to `~/Ratings.aspx`, and a Recent Activity list drawn from their own notifications.

- **Scope correction found up front (the same shape as Phase 4's and 6c's, for the third time)**: the plan named `profile.aspx`, but that page existed **only under `Donor/`**. `Controls/RoleSidebar.ascx` linked NGO's "NGO Profile" and Volunteer's "Profile" to `#`, and Admin had no profile entry at all — so three of the four roles had no way to correct their own phone number or address anywhere in the app. Rather than copy ~230 lines of markup three more times, the page moved to the app root on `Site.master` + `RoleSidebar`, exactly the precedent `~/Notifications.aspx` and `~/Ratings.aspx` set. `Donor/profile.aspx(.cs/.designer.cs)` were deleted and their four `LeftoverFood.csproj` entries removed. Unlike `~/Ratings.aspx`, **Admin is included** — an admin has a name, email and password like anyone else. What Admin does not get is the trust card, because Phase 6c excluded admins from ratings entirely.

- **Backend**: `Profile.aspx.cs` (`ProfilePage`, matching the `NotificationsPage`/`RatingsPage` naming), inline queries over `DBHelper` per Phase 1's reasoning — this page is the only consumer. `RequireLogin`, not `RequireRole`: every role has an account to maintain. **Every statement is scoped by `UserID` taken from the session, never from the request**, so there is no addressable way to read or write another user's row. The one query shared with another page — the verified-NGO list for the preferred-NGO dropdown — is written to match `Donor/donate-form.aspx.cs` exactly, so a donor's saved default and the per-donation picker can never offer different options.

- **DB** (`Database/phase7_profile.sql`, re-runnable): one new column, `Users.LastLoginAt`, stamped by `login.aspx.cs` on each successful sign-in. Everything else the page edits already existed from Phase 0 and was verified against the **live** table before the page was written rather than trusted from `schema.sql`. The script's second step is a guard rather than a change: it `RAISERROR`s if any column the page writes is missing, because that drift compiles cleanly and only fails on the first save.

- **Design decision — `LastLoginAt` is not backfilled.** `dbo.UserLoginLogs` exists and looks like it should already answer "last login", but it is unusable: it is keyed by a `Username` string (there is no `Username` column — this app authenticates by email), it holds one row, and no code reads or writes it. So the value is recorded for real going forward and left `NULL` for existing accounts, rendered as "not recorded yet". Backfilling `GETDATE()` would have printed a timestamp that was true of nobody. The stamp sits in its **own try/catch** inside the login handler — bookkeeping must never stop someone signing in.

- **Design decision — location sharing is mirrored, not duplicated.** The volunteer's `ShareLocation` state is shown here read-only with a link to the dashboard switch. Turning it off also *deletes* the positions already stored (Phase 5), and putting a second control on this page would mean two code paths that have to agree about a privacy guarantee.

- **Honesty pass — seven mockup promises had no column, table or feature behind them and were removed, not restyled**:
  - *Username (`ahmed_donor`)* → there is no `Username` column; the app signs in by email, which is the field now shown.
  - *"Typical Donation Frequency"* → no column, and nothing would read it.
  - *"Email Verified ✅ / Phone Verified ✅"* → **neither is verified anywhere in this project**. Phase 6b deleted a whole fraud rule ("Unverified Contact") for exactly this reason. `IsVerified` is admin approval of the account, a different thing, and is now labelled "Admin Approval" with a note stating the distinction.
  - *The four badges and the "Progress to Platinum (60 donations)" bar* → there is no badge system. The trust ladder that **is** computed lives on `~/Ratings.aspx`; this page shows a compact summary and links there rather than keeping a second copy that could drift.
  - *"Preferred NGO Partners" as free text* → the schema has a single `PreferredNGOID` foreign key. Now the same dropdown `donate-form.aspx` uses, and the posted id is **re-checked server-side** (`Role='NGO' AND IsVerified=1`) before the write, since the FK would otherwise accept any user id including the donor's own.
  - *The photo-upload camera button* → there is no avatar column and no upload path for one. The initials avatar from Phase 0 is real and is what remains.
  - Plus the hardcoded figures throughout — 47 donations, 4.8★, Gold Donor, 1,240 meals, `USR-2025-0031`, "Member since Jan 2025", "Karachi, Pakistan" and four invented activity rows — all now real per-role queries.

- **Design decision — the Danger Zone is gone, agreed before building.** *Deactivate* would write `IsActive = 0`, the **same column** Phase 1's admin Ban and Phase 6b's Suspend use: the user would then be refused at login with "Your account has been suspended", the mockup's "reactivate anytime" was simply false, and an admin reviewing the account could not tell a self-deactivation from a ban. *Delete Account* would fail outright — `FK_FraudFlags_User` is `NO_ACTION` (Phase 6b's latent note) and donations, ratings and notifications all reference `Users`. Neither was worth a fake button.

- **Security**: the change-password form verifies the current password before writing, enforces exactly the rule the card states (8+ characters, ≥1 digit, ≥1 special) **server-side**, rejects reusing the current password, and writes through `PasswordHelper.HashPassword` so the new value is always PBKDF2 — which means an account still on a legacy unsalted SHA-256 hash is upgraded by changing its password, not just by logging in. A successful change raises a **mandatory** notification (null event key, the same mechanism Phase 4 used for suspension): being told your password changed is not something a user may opt out of. Email uniqueness is re-checked on save scoped to `UserID <> @UserID`, and every free-text field is length-checked server-side because `MaxLength` is a client hint and is not enforced at all on a multiline `TextBox`.

- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile of every page, master and control. Every SQL path was executed directly against the live database, with the writes wrapped in transactions and rolled back: the four per-role stat blocks, the trust card, both email-uniqueness directions (own email → 0 clashes, another user's → 1), the preferred-NGO re-check (valid NGO → 1, a donor id posing as one → 0), and both `UPDATE` variants. Unicode round-trip confirmed on `Bio` (`UNICODE()` returned 1576, Arabic *beh*) — `nvarchar(1000)`, so the Phase 4 `varchar` class of bug is not present here.

- **Verified in the browser** (end-to-end session, 15 Aug 2026, all four roles): each role was signed in against the real database and its profile rendered with live data and the correct conditional sections — Donor saw org + business type + preferred NGO, NGO saw "NGO Details"/"NGO Registration No." with no business type, Volunteer saw the location card (flipping `ShareLocation` in the DB correctly flipped the page to "On"), Admin saw neither org nor trust card and gained the sidebar entry it never had. Saving persisted and the hero re-rendered from saved values; an Urdu bio round-tripped intact; the email-clash guard, all four password rules, the wrong-current-password path and a genuine password change all behaved, and **the new password was then used to sign in successfully**. The `LastLoginAt` stamp went from `NULL` to a real timestamp on that first sign-in, and the mandatory password-change notification landed with the right type and deep link. Test accounts created for this were deleted afterwards.

- **Bug found and fixed during that session**: an error shown by one postback stayed on screen through the *next*, unrelated one — saving a clashing email and then submitting the password form left both alerts stacked. `Panel.Visible` is persisted in ViewState, so `Visible = true` survived into the following request. Both message panels are now reset at the top of `Page_Load`. **Like Phase 6c's parameter-reuse bug, this is invisible to both the compiler and `aspnet_compiler`** — only driving the page finds it.

- **Not done / limits**: registration still does not capture City (open issue 1 below) — this page now lets a user set it themselves, but a brand-new account still starts with none. Role changes remain admin-only and are not offered here.

### Phase 8 — Dashboard Honesty Pass — ✅ IMPLEMENTED

- **Why this phase exists**: this document claimed for several phases that the admin dashboard's "Recent Donations (All)" table was *"the last fake data left in the app"*. **That was wrong.** A markup sweep found **nine** fabricated blocks across the three role dashboards — the three screens a supervisor is most likely to open first. Everything below is now a real query.

- **`Admin/admin-dashboard.aspx` — four blocks**:
  - *"Recent Donations (All)"* — five hardcoded `<tr>` (Ali's Restaurant, Marriott Hotel, Sara Ahmed…). Now a Repeater over the 15 most recent donations with real donor, NGO and volunteer names. Uses `OUTER APPLY` rather than a plain `LEFT JOIN` on `DeliveryAssignments`, because a donation can hold more than one assignment row and would otherwise appear twice.
  - *Filter buttons* — filtered fake rows. The pipeline has nine statuses and nine buttons will not fit, so they collapse into four buckets (Pending / In Progress / Delivered / Closed) via a single `FilterBucket()` mapping, so a button and a row can never disagree. **Verified**: 2 + 6 + 6 + 1 = 15, an exact partition of the table.
  - *"System Health"* — four invented percentages, one of which (**94% fulfilment**) directly contradicted `Admin/reports.aspx`, which measures the same thing from the same table and got 50%. All four now computed, each showing the counts it came from. Fulfilment reuses reports.aspx.cs's exact definition. "Volunteer Availability" became **"Volunteers Free Now"** — availability implied a roster this app has never had; who is not currently mid-delivery is something it genuinely knows. "User Growth +15%" had no baseline at all and is now a real count for the calendar month with last month named beside it.
  - *"Quick Actions"* — four `fbToast()` buttons. "Add New User" and "Register New NGO" were **deleted, not wired**: this app has no admin-side account creation at all — registration is self-serve and an admin approves it. The four that remain go to screens that exist.
  - Also: the header's *"All systems operational"* (a claim nothing measured) is now a real "figures as at" timestamp, *Export Report* links to the page with the real CSV export, and *Refresh* actually rebinds instead of showing a toast.

- **`NGO/ngo-dashboard.aspx` — five blocks**:
  - *"In Transit"* and *"Total Meals Served"* stat cards were **literal zeros in the markup**. Both now query.
  - *"Active Deliveries"* — two invented deliveries with **fabricated ETAs** ("ETA: 30 mins"). Now the NGO's real in-flight donations. **The ETA line is gone rather than restyled**: nothing in this app computes travel time, which is the same reason Phase 5 drew a straight line instead of a road route. The progress bar is now an honest 3-step indicator driven by `FoodDonations.Status`, not a time estimate.
  - *"Our Volunteers"* — three hardcoded people and a "Manage" button that did nothing. The heading itself was the lie: **this app has no concept of an NGO owning volunteers** — admins assign them centrally (Phase 3). Now "Volunteers on Our Deliveries", listing who has actually carried this NGO's deliveries, with the arrangement stated on the card.
  - *"Monthly Distribution Summary – April 2025"* — 248 / 5,830 / 96% hardcoded. Now the current calendar month scoped to this NGO.
  - Also: the header's *"Verified NGO"* badge rendered for everyone regardless of `IsVerified`.

- **`Donor/donor-dashboard.aspx` — two blocks**:
  - *"Your Impact"* — all three bars were literals. Success rate is now real and uses the same denominator as reports.aspx, so a donor's own cancellations and admin rejections do not count against their delivery record. **"Food Saved (kg)" was deleted rather than wired**: `FoodDonations` has no weight column, and `Quantity` is free text ("30 Plates", "1 Kg") that cannot be summed or converted — the limitation Phases 6b and 6d both hit. The **"/ 2,000" meals target is also gone**; no goal exists anywhere in this system. The *"Gold Donor Badge — Awarded for 40+ donations"* went the same way as Phase 7's badges: there is no badge system, so it is now the real average rating linking to Phase 6c's genuinely computed trust ladder.
  - *"Recent Activity"* — four hardcoded entries dated April 2025, now the donor's own notifications, the same real event log `~/Profile.aspx` uses.

- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile. A full-pipeline scenario was seeded (one donor with eight donations spanning every status, an NGO that accepted five, a volunteer with three assignments, a rating and notifications) and all three dashboards driven in the browser against the live database, then the data removed.
  - **Admin**: 15 real rows with correct contextual actions (Review on `Posted`, Assign on `Requested`, em dash elsewhere); health read 46% fulfilment (6 of 13), 85% NGO response (11 of 13), 75% volunteers free (6 of 8), 28 new users against 1 last month; Refresh rebound and confirmed.
  - **NGO**: 2 In Transit and 85 meals where the markup had hardcoded zeros; three active deliveries showing Steps 1, 2 and 3 with the right volunteer or "not assigned yet"; August 2026 summary reading 5 accepted / 85 meals / 40% — which matches 2 delivered of 5 by hand.
  - **Donor**: 33% success rate (2 of 6 in-pipeline), 85 meals, 5 in progress, a real 5.00 average, and three real timestamped activity entries.

- **Still static, and deliberately so**: 16 sidebar items across the four roles still point at `#`. These are a different category from the above — they link to screens that were never built, rather than faking data for screens that exist. Also unwired: the topbar search box in `Site.master` (present on every page), and `login.aspx`'s "Forgot Password?", Google and Facebook buttons, and Terms/Privacy links.

### Phase 9 — Topbar Search — ✅ IMPLEMENTED

- **What it was**: the topbar search box in `Site.master` was a plain `<input class="fb-search" placeholder="Search...">` with no `name`, no handler and nowhere to go. It rendered on **every page in the app** for **every role** and did nothing at all.

- **Features**: the box now searches, and a new shared `~/Search.aspx` shows the results — role-scoped, with the scope stated on the page so an empty result reads as "not yours to see" rather than "search is broken". Donations match on food description, category, quantity, pickup address, city and status; Admins additionally get a user search over name, email, organisation, city and role.

- **Wiring**: the box is wrapped in an `<asp:Panel DefaultButton="btnSearch">`. That matters — the master is shared by pages that each declare their own buttons, and without `DefaultButton` pressing Enter in the search box would submit whichever button the hosting page happened to render first. `Site.master.cs` redirects to `~/Search.aspx?q=…`, and re-fills the box from the query string so it reflects what is on screen. The box hides itself when there is no session.

- **Scope is the whole job.** A single query box is the easiest place in an app to leak data, because it invites one query for everybody. Every statement is filtered by the session user's own ID, never by anything in the request, and each branch of `DonationScope()` mirrors the visibility rule that role's own dashboard already enforces — so search cannot become a side door to rows a role could not otherwise reach:
  | Role | Sees |
  |---|---|
  | Donor | only their own donations |
  | NGO | donations open to them (Phase 2's "unassigned, or named to me" rule) plus ones they accepted |
  | Volunteer | only donations they were assigned to carry |
  | Admin | all donations, plus user accounts |

  The user search is **Admin-only and is never executed for anyone else** — not hidden behind a `Visible=false`, so there is no filter to get wrong. An unknown role falls through to `AND 1 = 0`, matching nothing rather than everything.

- **Design decision — LIKE wildcards are escaped.** Values are parameterised, so this is not about injection; it is about meaning. A term containing `%` would otherwise match every row in the table, and `_` would match any single character. `Like()` bracket-escapes `[`, `%` and `_`, which avoids needing an `ESCAPE` clause on each of the eleven predicates. A one-character term is treated as no search at all rather than run, since it would match nearly everything and is never what anyone meant.

- **Honest links**: a result carries an action only where a screen exists for that role to act on it — donors get Track, admins get Review on `Posted` and Assign on `Requested`, and everything else gets nothing rather than a dead button. Same rule as Phase 8's admin action column.

- **Verification**: clean `MSBuild -t:Rebuild` plus a full `aspnet_compiler` precompile. Two donors were seeded sharing one keyword (`ZEBRAFOOD`) across five donations in different statuses, with one accepted by the NGO and delivered by the volunteer, then every role was signed in and searched the same term against the live database:
  - **Donor A → 3 results**, exactly their own; donor B's two never appeared.
  - **NGO → 3**: the two `Approved` ones open to all, plus the one they accepted — both `Posted` ones correctly excluded.
  - **Volunteer → 1**: only the donation they carried.
  - **Admin → 5**, with Review shown only on the two `Posted` ones.
  - **Enter key** was dispatched on the real box from the donor dashboard and landed on `Search.aspx?q=ZEBRAFOOD`, confirming `DefaultButton`.
  - **Wildcards**: `%%` and `%a` both returned "Nothing matched" rather than the whole table, and `_a` and `[a]` likewise — proving the escaping. A single `%` fell to the minimum-length prompt without running a query.
  - **Privacy**: signed in as Donor A, searching donor B's email, donor B's name and the shared keyword all returned no Users section, no leaked email and none of donor B's donations.
  - Test data removed afterwards (back to 32 users / 9 donations).

- **Still static after this phase**: 16 sidebar items across the four roles pointing at `#` — screens that were never built, which is a different problem from a control that exists but does nothing. Also `login.aspx`'s "Forgot Password?", Google and Facebook buttons, and Terms/Privacy links.

**Follow-up — three dead-by-design sidebar items deleted (10 → 7).** These were not merely unbuilt; each names something this app has decided *not* to have, so leaving them on `#` promised a feature that is never coming:
- **NGO "Reports"** — the only reports page is `Admin/reports.aspx`, which calls `RequireRole(this, "Admin")`. An NGO following the link would have landed on `~/Unauthorized.aspx`. The NGO dashboard's Monthly Distribution Summary already carries the figures an NGO-scoped report would show.
- **Volunteer "Nearby Pickups"** — Phase 3 established assignment is admin-driven rather than self-serve and deleted the dashboard's fake "Nearby Available Pickups" list for that reason; a volunteer cannot claim a pickup, so there is nothing to open. Phase 5 also found most addresses only geocode to city level, so "nearby" is not something this data could rank on.
- **Volunteer "My Points"** — there is no points system. Phase 3 deleted the fabricated points/badges/rank card, and Phases 6c and 7 removed the badge blocks from `~/Ratings.aspx` and `~/Profile.aspx` for the same reason. Recognition here is the computed trust level, which the Ratings & Trust item already links to.

Each deletion left a comment at its old position explaining why, so it is not silently re-added. **Verified in the browser** for both affected roles: the NGO nav now reads Dashboard / Active Requests / History / Our Volunteers / Ratings &amp; Trust / NGO Profile / Notifications / Logout, and the Volunteer nav Dashboard / My Tasks / Completed / Ratings &amp; Trust / Messages / Profile / Notifications / Logout — no orphaned section headers in either. **Seven** `#` items remain, all screens that could reasonably exist: Admin Donors / NGOs / Volunteers / Settings, Donor My Certificates, NGO History, Volunteer Messages.

**Follow-up — six sidebar `#` links repointed (16 → 10).** Six of the sixteen dead nav items named a section that now genuinely exists, with real data, on that role's own dashboard. Rather than build four more screens that would only re-query what the dashboard already shows, each links to the dashboard plus a fragment: Admin "All Donations" → `#all-donations` and "All Users" → `#all-users`, Donor "My Donations" → `#my-donations`, NGO "Our Volunteers" → `#our-volunteers`, Volunteer "My Tasks" → `#my-tasks` and "Completed" → `#completed`. `id` attributes were added to the six matching cards. They deliberately do **not** call `IsActive()` — the target file is the dashboard, so highlighting them would light up two nav items at once. The remaining **ten** are screens with nothing behind them (Admin Donors/NGOs/Volunteers/Settings, Donor My Certificates, NGO History/Reports, Volunteer Nearby Pickups/Messages/My Points).

- **Bug found and fixed while verifying this**: the anchors landed in the wrong place. The browser jumps to a fragment as soon as it parses the document, but this app loads Bootstrap and two web fonts from a CDN afterwards; on the admin dashboard that reflow grows the page from ~2,845px to ~4,964px, which left the target **685px above the viewport** — the link looked broken. `assets/js/main.js` now re-applies the jump on `window.load` and again on `document.fonts.ready`, guarded so a missing id or an old browser simply does nothing. Verified before and after: `#all-users` went from `inView: false` (scrollY 2977, target at 2292) to landing exactly on the section (`targetTop: 0`). **This class of bug is invisible to both the compiler and `aspnet_compiler`** — only loading the page finds it, the same lesson Phases 6c and 7 recorded.
- **Verified in the browser**, all four roles signed in against the live database: every one of the six `id` targets exists on its page, every repointed sidebar href resolves to it, and the fragment target was in view on each. The ten remaining `#` items were confirmed still `#`, per role.

**Follow-up — three 404s on `Donor/donate-form.aspx` fixed.** This page is one of the two deliberately left standalone (§0), so it kept its own mockup navbar, and three links in it were still pointing at the static prototype's filenames. Because the page lives in `/Donor/`, they resolved *relative to that folder* and 404'd — confirmed live: `/Donor/index.html`, `/Donor/donor-dashboard.html` and `/Donor/about.html` all returned **404**, while `/index.html` at the root returns 200. The brand and the prominent **Dashboard** nav button now go to `~/Donor/donor-dashboard.aspx`; a signed-in donor's home is their dashboard, not the static `index.html` prototype (which itself still holds 18 links to files that do not exist). The third, *"Need help? Contact our team"* → `about.html#contact`, was **removed rather than repointed** — there is no contact page, no support inbox and no messaging feature in this app, so it promised a channel that does not exist; it now points at what a donor can genuinely do next, which is track the donation from their dashboard. **Verified**: every link on the rendered page was HEAD-requested and all four return 200.

### Phase 10 — User Management (Donors / NGOs / Volunteers) — ✅ IMPLEMENTED

- **What it replaces**: the Admin sidebar's Donors, NGOs and Volunteers items, which pointed at `#` because no such screen was ever built. Four other dead items were **deleted** in the same pass — Admin "Settings", Donor "My Certificates", NGO "History" and Volunteer "Messages" — each documented at its old position (there is no application settings screen and nothing that would go on one; nothing issues certificates; `ngo-active-requests.aspx` already ends with a Recently Completed table; and Phase 4 built one-way notifications, not a conversation — nothing in the schema can hold a reply). **The sidebar is now down to zero `#` links, from sixteen at the start of this sweep.**

- **One page, not three** (`Admin/users.aspx`): the three views differ only in which role they filter to and which two activity columns are meaningful, so the page takes `?role=` rather than existing as three near-identical files — the de-duplication call Phases 0, 4, 6c and 7 all made. `?role=All` is also accepted, making it a superset of the dashboard's Registered Users table. The role is matched against a **whitelist** and passed as a `SqlParameter`; it is never concatenated into SQL, and an unrecognised value falls back to All rather than erroring. Verified live: `?role=DROP TABLE` renders the All tab, 37 rows, no error.

- **Features**: four counters scoped to the selected role (total / approved / pending / suspended), a table with contact details, city, two role-appropriate activity metrics, trust score, join month and status, a client-side status filter reusing the existing `data-filter` mechanism, and per-row Approve / Reject / Suspend / Reinstate. Pending accounts sort first (`ORDER BY IsVerified ASC`) so the work an admin actually has to do is at the top.

- **Design decision — the activity metrics are chosen by the row's role, not the page's filter.** Two `CASE u.Role` expressions pick what to count: Donor → donations posted and meals delivered; NGO → donations accepted and meals received; Volunteer → deliveries completed and tasks in hand; Admin → donations reviewed and fraud flags closed. That is what lets the All tab show a mixed list where every row still reports something true about that person, instead of a "Donations" column full of zeroes for volunteers. Column headers change per tab, and read "Activity"/"Volume" on All rather than mislabelling one role's measure as another's.

- **Design decision — moderation moved into `UserAdminService`.** Phase 1 wrote approve/reject/ban/unban inline on the dashboard and said a service layer would be premature "since there's only one consumer". This page is the second, which is exactly the condition that produced `NotificationService` (Phase 4) and `FraudDetectionService` (6b). The reason is not line count — it is that each action carries a guard that must not exist in only one of the two pages: **an admin must not be able to suspend their own account**; approve must only affect a still-pending row; and reject must read the recipient *before* the delete, because the row it needs is the row it is about to remove. The dashboard was refactored onto the service in the same change, and both pages now also report "already approved" / "already suspended" instead of silently re-notifying, since every statement is scoped and `rowsAffected` is checked before any notification fires.

- **Verification**: clean `MSBuild` plus a full `aspnet_compiler` precompile. Every query was run against the live database first, including an independent cross-check that the `CASE` metrics match figures computed separately (QA Donor One: 3 posted / 10 meals; Test Donor: 2 / 42 — both matched).

- **Verified in the browser** (16 Aug 2026), with pending and suspended accounts seeded because the live data had none of either:
  - All four tabs render the right heading, column labels and counters — Donor 11/10/1/0 with "Donations"/"Meals Delivered", NGO 11/10/1/0 with "Accepted"/"Meals Received", Volunteer 9/8/0/1 with "Deliveries"/"Active Now", All 37/34/2/1 with "Activity"/"Volume".
  - **Approve** flipped the row from `pending` to `active`, swapped its buttons to Suspend alone, moved the counters to 11/11/0/0, and wrote the mandatory notification with the right type and `~/Login.aspx` deep link.
  - **Reinstate** did the same in reverse and notified correctly.
  - **The self-suspension guard held**: clicking Suspend on the signed-in admin's own row returned "You cannot change the status of your own account." in an `alert-danger` and left the row active.
  - **Regression check on the refactor**: the admin dashboard's own Verify still works through the shared service, clearing its pending queue to "No pending registrations".
  - Test accounts removed afterwards (back to 32 users, 0 pending, 0 suspended).

**Follow-up — six inert controls removed from `login.aspx`.** With the sidebar at zero dead links, these were the last non-functional controls in the app: "Remember me", "Forgot Password?", the "or continue with" divider, the Google and Facebook buttons, and the "I agree to the Terms of Service and Privacy Policy" row.

Two were worse than dead links, which the sweep only found on reading the markup: **both checkboxes had no `runat="server"`, no `id`, no `name` and no validator**, so neither was ever posted, read or enforced. "Remember me" changed nothing — sessions expire on the server timeout regardless — and registration succeeded whether the terms box was ticked or not, while its two links pointed at documents that do not exist. An unenforced consent tickbox next to non-existent terms is a claim about legal agreement that nothing backs, which is worse than not asking at all. The social buttons were inert markup: there is no OAuth anywhere — no provider registered, no client id or secret in `Web.config`, no callback handler, and `login.aspx.cs` only understands an email plus a PBKDF2 hash.

Each removal left a comment at its old position recording what it was and what building it for real would require. **Verified in the browser**: all six are gone from the rendered page, and because the deletions cut markup from inside the `<form runat="server">`, both flows were re-tested end to end — signing in reached the donor dashboard, and registering inserted a real row (`IsVerified = 0`, PBKDF2 hash) and returned the pending-approval message. The only `href="#"` left in the file are the two Login/Register tab switches, which carry real `onclick` handlers.

**Still undecided**: `index.html` and its `assets/` folder — the separate static Bootstrap prototype, holding 18 links to files that do not exist. `login.aspx`'s "Back to Home" is the one live page that points into it. It is untouched pending a decision on whether it is the design reference to keep or dead weight to delete.

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
| 5 | Phase 4 — Notifications ✅ | Medium | Phase 6a (emergency broadcast reuses it) |
| 6 | Phase 5 — Maps & Volunteer Tracking ✅ | Medium | Independent — can be done in parallel with Phase 4 |
| 7 | Phase 6c — Ratings & Trust ✅ | Medium | Feeds `Users.TrustScore` to 6b and 6d |
| 8 | Phase 6a — Emergency Mode ✅ | Medium | Nothing — reused Phase 4's notification layer |
| 9 | Phase 6b — Fraud Detection ✅ | Medium | Nothing — five inline rules, admin review queue |
| 10 | Phase 6d — Reports & Analytics ✅ | Medium | Nothing — shipped with zero new dependencies |
| 11 | Phase 7 — Account Profile ✅ | Low–Medium | Nothing — the last stub page, shared by all four roles |
| 12 | Phase 8 — Dashboard Honesty Pass ✅ | Medium | Nothing — removed the last fabricated data from all three role dashboards |
| 13 | Phase 9 — Topbar Search ✅ | Medium | Nothing — wired the app-wide search box to a role-scoped results page |
| 14 | Phase 10 — User Management ✅ | Medium | Nothing — built Donors/NGOs/Volunteers; sidebar now has zero dead links |

**All phases in this roadmap are now implemented and browser-verified, and there are no stub pages left in the app.** A full end-to-end session on 15 Aug 2026 exercised the whole chain against the live database — register → verify → post → approve → accept → assign → pick up → deliver → confirm receipt → rate → flag → broadcast → export — plus Phase 5's Leaflet maps, which had never been opened, and Phase 7's shared profile across all four roles. Each phase's verification note records what was confirmed and what still needs a human (the geolocation prompt and the print dialog).

**Open issues found during that session**, none of them blocking:

1. **Registration never sets `Users.City`.** `login.aspx.cs` contains no reference to the column; the form captures a free-text Address only. This is the root cause of the Phase 6a finding that most accounts have no city, and it means city-targeted broadcasts can only ever reach seeded accounts. *Partly addressed by Phase 7* — `~/Profile.aspx` now gives every user a City dropdown, so the value is at least reachable. A new account still starts with none until the user goes and sets it, so adding the same dropdown to registration remains the real fix.
2. **The fraud full-scan double-flags duplicate pairs** (see 6b).
3. ~~**The admin dashboard's "Recent Donations (All)" table is still fabricated mockup** — the last fake data left in the app.~~ **Resolved in Phase 8, and the claim was wrong**: a markup sweep found nine fabricated blocks across all three role dashboards, not one. All are now real queries. What remains static is listed at the end of Phase 8 — 16 `#` sidebar links to unbuilt screens, the topbar search box, and login.aspx's social/forgot-password links.
4. **Email deep links point at `https://localhost:44309`**, the old IIS Express SSL port, so links in real emails would be wrong outside that one dev setup.

**Recommendation on where to start today**: Phase 0's RBAC fix + Phase 1's approval flow together are small, well-scoped, and unblock literally every other feature and every future testing session — that's the natural first coding session.

---

*This document is a working reference, not committed to git — update it as phases complete or scope shifts.*
