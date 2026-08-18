# LeftoverFood — Manual Testing Checklist

Everything implemented so far, in the order it was built. Test top to bottom — later items depend on earlier ones working (e.g., you can't test the donation flow until user approval works).

---

## 0. Before you start

- **Build**: open the solution in Visual Studio, Build → Rebuild Solution. Zero errors expected. This itself is a test — nothing has been compiled since this refactor, only reasoned about.
- **Database**: confirm `Database/schema.sql` has been run against your `LeftoverFood` DB (it should have been already — `Database/phase0_schema_migration.sql` + `phase0_users_alter_fix.sql` + `phase0_users_alter_fix2.sql` were applied live earlier in this project). Quick sanity check in SSMS: `Users` table should have 17 columns including `IsActive`, `TrustScore`; there should be 9 tables total, no `UsersOLD`/`Deliveries`/`EmergencyMode`.
- **Existing seeded accounts** (all `IsVerified=1`, passwords unknown to me — use whatever you set when they were created):
  | Email | Role |
  |---|---|
  | admin@foodsystem.com | Admin |
  | ahmed@example.com | Donor |
  | edhi@example.com | NGO |
  | sara@example.com | Volunteer |
- **Recommended**: for a clean test with known passwords, register 2–3 fresh test accounts through the UI (Donor + NGO at minimum) rather than relying on the seeded ones. For Admin specifically — registration doesn't offer an Admin role option (by design), so either use the existing `admin@foodsystem.com` or promote a fresh test account yourself: `UPDATE Users SET Role='Admin', IsVerified=1 WHERE Email='youraccount@test.com'`.

---

## 1. Foundation & Security

### 1.1 Role-based access control (RBAC)
- **What**: every dashboard page now calls `SessionHelper.RequireRole(this, "X")` in `Page_Load`. Previously none did — any page was open to anyone.
- **Files**: all 15 `*.aspx.cs` files under `Admin/`, `Donor/`, `NGO/`, `Volunteer/`.
- **Test steps**:
  1. Without logging in, paste `/Admin/admin-dashboard.aspx` directly into the browser address bar.
  2. Log in as a Donor, then paste `/Admin/admin-dashboard.aspx` into the address bar.
  3. Log in as a Donor, then paste `/NGO/ngo-dashboard.aspx` into the address bar.
- **Expected**: step 1 redirects to `Login.aspx`. Steps 2–3 redirect to `Unauthorized.aspx` with a styled "Access Denied" message and a link back to login.
- **Limitations**: none known.

### 1.2 `Unauthorized.aspx` / `Error.aspx`
- **What**: these pages didn't exist before, despite being referenced by `Web.config` and `SessionHelper`. Any redirect to them would have 404'd.
- **Files**: `Unauthorized.aspx(.cs)`, `Error.aspx(.cs)`.
- **Test steps**: trigger 1.1's redirect scenario above; separately, try to force a server error (e.g., temporarily stop SQL Server and try to log in) to see `Error.aspx`.
- **Expected**: both render a styled page matching the app's look, not a raw ASP.NET yellow-screen or 404. `Error.aspx` only shows exception details if you're on `localhost`.
- **Limitations**: none known.

### 1.3 Password hashing upgrade
- **What**: `PasswordHelper.cs` now uses salted PBKDF2 instead of unsalted SHA-256, with automatic transparent upgrade of old-format hashes on next login.
- **Files**: `PasswordHelper.cs`, `login.aspx.cs`.
- **Test steps**:
  1. Register a brand-new account. Check `Users.PasswordHash` in SQL — should start with `PBKDF2$100000$...`.
  2. If you have any pre-existing account with an old plain 64-character hex hash, log in with it once, then re-check `PasswordHash` in SQL — it should now also start with `PBKDF2$`.
- **Expected**: new accounts get salted hashes immediately; old accounts get silently upgraded on their next successful login, no user-visible difference.
- **Limitations**: none known.

### 1.4 Database schema
- **What**: full schema for `Users` (extended), `FoodDonations`, `FoodRequests`, `DeliveryAssignments`, `Ratings`, `Notifications`, `FraudFlags`, `EmergencyBroadcasts`.
- **Files**: `Database/schema.sql` (+ migration scripts, already applied).
- **Test steps**: covered by the DB sanity check in section 0.
- **Limitations**: `Notifications`, `FraudFlags`, `EmergencyBroadcasts` tables exist but nothing writes to them yet (Phase 4/6 work).

---

## 2. Admin — User Verification (Phase 1)

### 2.1 Pending Verifications queue
- **What**: `Admin/admin-dashboard.aspx` lists every unverified registration with working Verify/Reject buttons.
- **Files**: `Admin/admin-dashboard.aspx(.cs)`.
- **Test steps**:
  1. Register a new Donor account (`Login.aspx` → Register tab). Try logging in with it immediately.
  2. Log in as Admin, go to the Dashboard. Find the new registration under "Pending Verifications."
  3. Click **Verify**.
  4. Log in as the new Donor account.
  5. Register a second test account. This time click **Reject** on the Admin dashboard instead.
  6. Check the `Users` table in SQL for that email.
- **Expected**: step 1 fails with "pending admin approval." Step 3 removes it from the pending list and shows a success message. Step 4 now succeeds and lands on `Donor/donor-dashboard.aspx`. Step 5's rejected account is **deleted entirely** from `Users` (by design — see Known limitations). Step 6 confirms no row exists.
- **Known limitations**: Reject hard-deletes the row rather than keeping a "Rejected" audit record — a rejected person has to re-register from scratch if that was a mistake.

### 2.2 Registered Users table — Ban/Unban
- **What**: full user list with a working Ban/Unban action tied to `IsActive`.
- **Test steps**:
  1. As Admin, find an active, approved test user in the "Registered Users" table. Click **Ban**.
  2. Try logging in as that user.
  3. As Admin, click **Unban** on the same user.
  4. Log in as that user again.
  5. As Admin, try to Ban your own logged-in Admin account (if it's visible in the table).
- **Expected**: step 2 fails with "Your account has been suspended." Step 4 succeeds normally. Step 5 is blocked with "You cannot change the status of your own account."
- **Limitations**: none known.

### 2.3 Stat counters
- **What**: the 4 stat cards (Total Users, Total Donations, Verified NGOs, Pending Approvals) show live counts instead of the mockup's fake numbers.
- **Test steps**: register a new account, note the "Pending Approvals" count before/after; verify it, note the count drop and "Total Users" not changing (it was already counted) — actually check it does NOT double count.
- **Expected**: numbers move in real time with your actions, no page refresh needed beyond the postback.
- **Limitations**: "Total Donations" will read 0 until you test section 3.

---

## 3. Core Donation Flow (Phase 2)

### 3.1 Donor posts a donation
- **What**: `Donor/donate-form.aspx` inserts a real row into `FoodDonations`.
- **Files**: `Donor/donate-form.aspx(.cs)`.
- **Test steps**:
  1. Log in as an approved Donor.
  2. Go to "New Donation." Fill in: Food Type = "Test Biryani", Category = "Cooked Meals", Donor Type = "Restaurant", Quantity = 10, Unit = Plates, Servings = 10, Prepared On = today, Expiry = a time a few hours from now, Pickup Address = any text, City = Karachi, Available From/Until = any times, Contact Person/Phone = any values.
  3. Optionally attach a small JPG as the photo.
  4. Submit.
  5. Try submitting again with an **expiry time in the past**.
  6. Try submitting with an oversized (>5MB) or non-image file as the photo.
- **Expected**: step 4 redirects to the Donor dashboard with "Donation posted! It's now awaiting admin approval." and a new row appears in "Recent Donations" with status **Pending**. Step 5 is rejected client- and server-side ("Expiry time must be in the future"). Step 6 shows a warning but still posts the donation (photo just gets skipped).
- **Limitations**: no client-side drag-and-drop or image preview; "Save as Draft" button from the original mockup was removed since drafts aren't implemented.

### 3.2 Admin approves/rejects a donation
- **What**: `Admin/food-approvals.aspx` lists real pending donations, sorted by actual urgency, with working Approve/Reject.
- **Test steps**:
  1. As Admin, go to Food Approvals. Find your test donation from 3.1.
  2. Check the urgency color-coding (red/amber/green border) roughly matches how soon it expires.
  3. Click **Approve**.
  4. Post a second donation as Donor, go back to Food Approvals, click **Reject** on it this time.
  5. Check "Recently Processed" at the bottom of the page.
- **Expected**: step 3 removes it from the pending list; "Recently Processed" now shows it as Approved. Step 4's donation shows as Rejected in "Recently Processed" (row stays in the DB with `Status='Rejected'`, unlike the user-rejection flow in 2.1 which deletes).
- **Limitations**: "Ask Donor" / bulk "Approve All Trusted" / PDF-Excel export buttons from the original mockup were intentionally removed — no messaging or trust-scoring system exists yet to back them.

### 3.3 NGO accepts an approved donation
- **What**: `NGO/ngo-dashboard.aspx`'s "Available Donations" table lists real `Approved` donations; Accept claims it.
- **Test steps**:
  1. Log in as an approved NGO.
  2. Confirm your approved test donation from 3.2 appears under "Available Donations."
  3. Click **Accept**.
  4. Open a second browser (or incognito window), log in as a *different* NGO, and try to Accept the same donation (post another test donation, approve it, then race two NGO sessions if you want to test this precisely).
- **Expected**: step 3 shows "Donation accepted. A volunteer will be assigned for pickup." and it disappears from "Available Donations." Step 4's second NGO gets "This donation was just claimed by another NGO" — the race-safety check works.
- **Limitations**: nothing beyond "Accept" is wired — no delivery/volunteer assignment yet (that's `ngo-active-requests.aspx`, still a static mockup, planned for Phase 3).

### 3.4 Donor dashboard reflects status + Cancel
- **What**: `Donor/donor-dashboard.aspx`'s "Recent Donations" table is real, with a Cancel action.
- **Test steps**:
  1. As the Donor from 3.1–3.3, check your donation's status badge updates: Posted → Approved → Requested (as you did the Admin/NGO steps above).
  2. Note the NGO name now appears in the table once accepted.
  3. Post a brand-new donation and immediately click **Cancel** on it (while still `Posted`, before any admin action).
  4. Try to find a Cancel button on a donation that's already been Approved or Requested.
- **Expected**: step 1 badge updates match each stage. Step 3 succeeds, status becomes `Cancelled`. Step 4 — no Cancel button is shown once a donation leaves `Posted` status.
- **Limitations**: none known.

---

## 4. Logout — all roles

- **What**: every one of the 13 dashboard pages has a working Logout link (previously only worked, if at all, nowhere — most pages didn't even have a `<form runat="server">`).
- **Test steps**: for each role (Admin, Donor, NGO, Volunteer), log in, click the red "Logout" item at the bottom of the sidebar on at least 2 different pages within that role.
- **Expected**: session clears, redirected to `Login.aspx`. Trying to go "Back" in the browser and reload a dashboard page should force you back to `Login.aspx` (RBAC catches it).
- **Limitations**: none known.

---

## 5. Shared Layout (Master Pages refactor)

- **What**: all 13 dashboard pages now share one root layout (`Site.master`) plus one sidebar layout per role (`AdminMaster`, `DonorMaster`, `NGOMaster`, `VolunteerMaster`) instead of duplicating HTML per page.
- **Test steps**:
  1. For each role, click through every sidebar link that points to a real page (not the `#` placeholders) and confirm the correct nav item highlights as "active."
  2. Check the top-right avatar shows your actual initials and the correct role-tinted background color (purple=Admin, amber=NGO, blue=Volunteer, green=Donor) on every page, not hardcoded ones like "AD" or "AK".
  3. Resize the browser narrow (or check on mobile width) and click the hamburger/sidebar-toggle button on a couple of pages.
- **Expected**: step 1 — active highlighting always matches the current page. Step 2 — avatar always reflects the logged-in user, consistently across every page in that role. Step 3 — sidebar collapses/toggles the same way on every page (this was pre-existing `main.js` behavior, just confirm it wasn't broken by the refactor).
- **Limitations**: `donate-form.aspx` and `track-donation.aspx` are NOT part of this shared layout (different design, no sidebar) — don't expect the same chrome there, that's intentional.

---

## 6. Regression check — dashboard crash fix

- **What**: `Donor/donor-dashboard.aspx` previously crashed immediately after Donor login with `System.ArgumentException: The SqlParameter is already contained by another SqlParameterCollection`.
- **Test steps**: log in as any Donor and confirm the dashboard loads without error (this is really just re-confirming section 3.4 works).
- **Expected**: no exception, stats and donation list render normally.
- **Limitations**: none — a full codebase audit confirmed this pattern didn't exist anywhere else.

---

## Summary of what's still a static mockup (expected, not a bug)

> **This list was written after Phase 2 and is almost entirely out of date.** Phases 3, 4, 5, 6a–6d and 7 have all landed since, and every page named below except the two items in the "still mockup" list has been built against real data. `IMPLEMENTATION_ROADMAP.md` §4 is authoritative.

Still mockup today (after Phase 8 rebuilt all three role dashboards against real data):

- **No fabricated data remains on any page.** Phase 8 replaced the last nine blocks — admin's Recent Donations / System Health / Quick Actions, NGO's In Transit / Meals Served / Active Deliveries / Our Volunteers / Monthly Summary, and donor's Your Impact / Recent Activity.
- **No unwired controls remain.** The topbar search box was wired in Phase 9 (role-scoped `~/Search.aspx`), and `login.aspx`'s six inert controls were removed: "Remember me", "Forgot Password?", the "or continue with" divider, the Google and Facebook buttons, and the Terms/Privacy consent row. Both checkboxes there had no `runat`, `id`, `name` or validator, so neither was ever posted or enforced.

  Anything on that list that is genuinely wanted is a **feature build**, not a link fix: password reset needs a token table and a reset email path; social sign-in needs a registered OAuth provider, secrets in `Web.config` and a callback handler; enforced terms need the documents, a server-side required check, and a column recording the accepted version.

- **The public site is real and link-clean.** `index.html` was rewritten and `about.html` added. `index.html` had been loading its CSS and JS from `../assets/…` — above the application root — so it rendered entirely unstyled; that is fixed. All `.html` link targets that never existed are gone or repointed at real pages, the invented statistics and the fake "Recent Donations" table are removed, and a twelve-item features section now describes only what is built. Verified over HTTP: 27 links on `index.html` and 23 on `about.html`, zero broken, cross-page fragments confirmed present.
- **No dead sidebar links remain.** All sixteen `#` items are resolved: **six repointed** to `#fragment` anchors on the relevant role dashboard (All Donations, All Users, My Donations, Our Volunteers, My Tasks, Completed), where each section now exists with real data; **seven deleted** as dead by design (NGO "Reports" — the only reports page is Admin-only and would bounce an NGO to `Unauthorized.aspx`; Volunteer "Nearby Pickups" — assignment is admin-driven; Volunteer "My Points" — no points system; Admin "Settings" — no application settings screen exists; Donor "My Certificates" — nothing issues certificates; NGO "History" — already covered by Recently Completed; Volunteer "Messages" — notifications are one-way, nothing can hold a reply); and **three built** as `Admin/users.aspx?role=Donor|NGO|Volunteer` (Phase 10).

Built since this list was written: `volunteer-assign.aspx`, `emergency-mode.aspx`, `fraud-detection.aspx`, `reports.aspx` (Admin); `ngo-active-requests.aspx` and the NGO dashboard panels; `notifications.aspx` plus the shared `~/Notifications.aspx`; the shared `~/Ratings.aspx` (replacing `Donor/ratings.aspx`); the shared `~/Profile.aspx` (replacing `Donor/profile.aspx`); Donor "Your Impact"/"Recent Activity"; and the whole of `volunteer-dashboard.aspx`.
