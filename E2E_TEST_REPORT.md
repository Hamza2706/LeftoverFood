# LeftoverFood — End-to-End Manual Test Report

**Date:** 2026-08-10
**Tester:** Claude (agentic browser + direct DB/API verification)
**App under test:** ASP.NET Web Forms app, built with MSBuild, hosted locally via IIS Express on `http://localhost:54321`
**Database:** SQL Server Express, instance `Elitebook\SQLEXPRESS`, database `LeftoverFood`
**Verification method:** Real browser (Claude's browser tool) driving the actual rendered UI, cross-checked against direct `sqlcmd` queries against the live database after every state-changing action, plus raw HTTP requests (PowerShell `Invoke-WebRequest`) for a few checks that needed either two independent sessions at once, or a check that bypasses client-side JS entirely.

This is a live "keep testing/fixing forward" session, not a spec doc — it reflects exactly what was clicked, typed, and verified, in order.

---

## How to reproduce this session's setup yourself

1. Build: open a shell at the repo root and run
   ```
   & "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\amd64\MSBuild.exe" LeftoverFood.csproj /p:Configuration=Debug
   ```
   (or just build via Visual Studio — same result, `bin\LeftoverFood.dll`).
2. Host it:
   ```
   "C:\Program Files\IIS Express\iisexpress.exe" /path:"C:\Users\Hamza\source\repos\LeftoverFood" /port:54321
   ```
3. Browse to `http://localhost:54321/login.aspx`.
4. DB access for spot-checks: `sqlcmd -S "Elitebook\SQLEXPRESS" -d LeftoverFood -Q "<query>"`.

IIS Express was left running on port 54321 at the end of this session so you can immediately click through the same states.

---

## Test accounts created during this session

All passwords: `QaTest123!` (except where noted). All emails `@example.com`.

| Email | Role | Purpose | End state |
|---|---|---|---|
| qa.donor@example.com | Donor | Main donor test account | Verified, Active |
| qa.ngo2@example.com | NGO | Main NGO test account (won both accept races) | Verified, Active |
| qa.ngo3@example.com | NGO | Second NGO, used only for the race-condition test | Verified, Active |
| qa.volunteer@example.com | Volunteer | Volunteer-role smoke test | Verified, Active |
| qa.admin@example.com | Admin | Admin test account (registered as Donor, then promoted via direct SQL `UPDATE Users SET Role='Admin', IsVerified=1` — there is no self-service Admin registration by design) | Verified, Active |
| qa.finalcheck@example.com | Donor | Last-minute regression check after a bug-fix correction | Pending (intentionally left unverified) |
| qatest.norole@/qatest.norole2@/rawpost.norole1-3@ | — | Used only to prove the no-role registration bug and its fix; all were correctly rejected and **no rows exist** for any of them |
| qa.regression@example.com | Donor | Used in Admin-verification testing, then rejected (deleted) by design |
| (original) qa.ngo@example.com | NGO | Registered, verified, then deliberately **rejected** during Admin-verification testing → row no longer exists |

Existing pre-session seed accounts (`admin@foodsystem.com`, `ahmed@example.com`, `edhi@example.com`, `sara@example.com`, etc.) were left untouched — their passwords were unknown, so all testing used the fresh `qa.*` accounts above, per the project's own `TESTING_CHECKLIST.md` recommendation.

---

## Testing checklist

| # | Feature | Scenario | Steps Documented | Result | Bug | Status |
|---|---|---|---|---|---|---|
| 1 | Registration | Empty form submit | Yes | Client-side validators fire, no POST sent | No | ✅ Passed |
| 2 | Registration | No role selected | Yes | Bypassed client validation, server threw raw SQL error to user | **Yes** | 🐛 Fixed |
| 3 | Registration | Invalid email format | Yes | "Enter a valid email", blocked client-side | No | ✅ Passed |
| 4 | Registration | Password < 6 chars | Yes | "Min. 6 characters", blocked client-side | No | ✅ Passed |
| 5 | Registration | Confirm password mismatch | Yes | "Passwords do not match", blocked client-side | No | ✅ Passed |
| 6 | Registration | Duplicate email | Yes | "This email is already registered. Please login." | No | ✅ Passed |
| 7 | Registration | Happy path — Donor/NGO/Volunteer | Yes | Row inserted, `IsVerified=0`, salted `PBKDF2$...` hash | No | ✅ Passed |
| 8 | Login | Unverified account | Yes | "Your account is pending admin approval..." | No | ✅ Passed |
| 9 | Login | Wrong password | Yes | "Incorrect password. Please try again." | No | ✅ Passed |
| 10 | Login | Non-existent email | Yes | "No account found with this email." | No | ✅ Passed |
| 11 | Login | Banned (`IsActive=0`) account | Yes | "Your account has been suspended..." | No | ✅ Passed |
| 12 | RBAC | Unauthenticated direct URL to protected page | Yes | Redirects to Login.aspx (verified server-side via raw HTTP, no cookies) | No | ✅ Passed |
| 13 | RBAC | Donor → Admin/NGO/Volunteer pages | Yes | `Unauthorized.aspx` "Access Denied" every time | No | ✅ Passed |
| 14 | RBAC | NGO → Admin page | Yes | `Unauthorized.aspx` | No | ✅ Passed |
| 15 | Admin verification | Verify a pending user | Yes | "User approved.", `IsVerified=1` in DB, user can now log in | No | ✅ Passed |
| 16 | Admin verification | Reject a pending user | Yes | "Registration rejected and removed.", row hard-deleted from DB | No | ✅ Passed |
| 17 | Admin verification | Ban an active user | Yes | `IsActive=0`, banned user immediately blocked at login | No | ✅ Passed |
| 18 | Admin verification | Unban a suspended user | Yes | `IsActive=1` restored, login works again | No | ✅ Passed |
| 19 | Admin verification | Admin bans own account | Yes | "You cannot change the status of your own account.", DB unchanged | No | ✅ Passed |
| 20 | Admin verification | Stat counters (Total Users / Pending / NGOs) | Yes | Move correctly with each action, no double-counting | No | ✅ Passed |
| 21 | Donation flow | Post donation — happy path | Yes | Row inserted `Status='Posted'`, correct `PreferredNGOID` | No | ✅ Passed |
| 22 | Donation flow | Post donation — expiry in the past | Yes | "Expiry time must be in the future.", no row created | No | ✅ Passed |
| 23 | Donation flow | Admin approves | Yes | `Status='Approved'`, `ApprovedBy`/`ApprovedAt` stamped | No | ✅ Passed |
| 24 | Donation flow | NGO accepts (happy path) | Yes | `Status='Requested'`, `FoodRequests` row created | No | ✅ Passed |
| 25 | Donation flow | Two NGOs race to accept the same donation | Yes | Winner gets "Donation accepted", loser gets "This donation was just claimed by another NGO.", exactly one `FoodRequests` row | No | ✅ Passed |
| 26 | Donation flow | Donor cancels while still `Posted` | Yes | "Donation cancelled.", `Status='Cancelled'`, Cancel button disappears | No | ✅ Passed |
| 27 | Donation flow | Cancel button hidden once `Requested`/`Approved` | Yes | No Cancel action rendered; server query also scoped to `Status='Posted' AND DonorID=@DonorID` (verified via code) | No | ✅ Passed |
| 28 | Logout | All roles (Admin/Donor/NGO/Volunteer) | Yes | Session cleared every time, redirected to Login.aspx | No | ✅ Passed |
| 29 | Shared layout | Master pages render per role, avatar initials live | Yes | Confirmed on Admin/Donor/NGO/Volunteer dashboards | No | ✅ Passed |
| 30 | Character encoding | Em-dashes / emoji on any page | Yes | Rendered as mojibake (`â€"`, `ðŸš«`) site-wide | **Yes** | 🐛 Fixed |
| 31 | Static resource | `donate-form.aspx` / `track-donation.aspx` JS include | Yes | `GET /js/main.js` → 404 (wrong relative path) | **Yes** | 🐛 Fixed |
| 32 | Mockup survey | Volunteer dashboard, NGO active-requests, notifications, profile, ratings, volunteer-assign, emergency-mode, fraud-detection, reports | Yes | All render without server errors, confirmed still static/mockup (2–4 `runat="server"` controls each — just RBAC/master-page wiring) | No | ✅ Passed (as-designed, not yet built) |

---

## Detailed workflow reproduction steps

### 1. Registration — happy path (Donor / NGO / Volunteer)

**Feature:** Self-service registration on `login.aspx` (Register tab).
**Expected behavior:** A new row is created in `Users` with `IsVerified=0`, a salted password hash, and the chosen role. The account cannot log in until an Admin approves it.
**Role used:** Anonymous (no login required to register).

**Steps performed:**
1. Navigate to `http://localhost:54321/login.aspx`.
2. Click **"Register here"** to switch to the Register panel.
3. Fill in:
   - Full Name: `QA Donor One`
   - Email: `qa.donor@example.com`
   - Phone: `0300-1112223`
   - Register As: `Donor`
   - Address: `123 Test Street, Karachi`
   - Password: `QaTest123!`
   - Confirm Password: `QaTest123!`
4. Click **Create Account**.
5. **Expected result:** Green success message "Registration successful! Your account is pending admin approval. You will be notified via email."
6. **Actual result:** Matched exactly.
7. Repeated identically for NGO (`qa.ngo2@example.com`) and Volunteer (`qa.volunteer@example.com`), selecting the corresponding role in the dropdown.
8. **DB verification:**
   ```sql
   SELECT UserID, Email, Role, IsVerified, LEFT(PasswordHash,10) FROM Users WHERE Email='qa.donor@example.com';
   ```
   Result: `IsVerified=0`, hash starts with `PBKDF2$100000$...` (salted PBKDF2, not legacy SHA-256).

### 2. Login — unverified account is blocked

**Steps performed:**
1. On `login.aspx` (Login tab, default), enter `qa.donor@example.com` / `QaTest123!` immediately after registering (before any Admin action).
2. Click **Sign In**.
3. **Expected:** Blocked with an approval-pending message.
4. **Actual:** "Your account is pending admin approval. Please wait for verification." — matched.

### 3. Admin — User Verification (Approve / Reject / Ban / Unban)

**Feature:** `Admin/admin-dashboard.aspx` — Pending Verifications queue + Registered Users table.
**Role used:** Admin (`qa.admin@example.com`, promoted via direct SQL since self-registration doesn't offer the Admin role by design).

**Steps performed — Verify:**
1. Log in as `qa.admin@example.com`.
2. On the Admin Dashboard, locate **Pending Verifications** → `QA Donor One` row.
3. Click **Verify**.
4. **Expected:** "User approved. They can now log in.", the row disappears from Pending, "Pending Approvals" stat drops by 1, "Total Users" stays the same (no double-count).
5. **Actual:** Matched exactly. DB check: `IsVerified` flipped `0→1`.
6. Confirmed the just-verified Donor could now log in successfully.

**Steps performed — Reject:**
1. On the same page, click **Reject** on `QA NGO One`'s pending row (confirm-dialog: "Reject and remove this registration?").
2. **Expected:** Row is hard-deleted from `Users` (by documented design — no "Rejected" audit state exists yet).
3. **Actual:** "Registration rejected and removed." — DB check confirmed `SELECT COUNT(*) FROM Users WHERE Email='qa.ngo@example.com'` → `0`.

**Steps performed — Ban / Unban:**
1. In **Registered Users**, find `QA Donor One` (now Active). Click **Ban** (confirm dialog: "Suspend this user?").
2. **Expected:** Status → "Suspended", `IsActive=0` in DB.
3. **Actual:** Matched. Then opened a fresh tab session (logged out first, since cookies are shared across tabs) and tried logging in as the banned donor → **"Your account has been suspended. Please contact support."**
4. Logged back in as Admin, clicked **Unban** on the same row.
5. **Expected:** `IsActive=1` restored, login works again.
6. **Actual:** Matched — confirmed via DB and a fresh login attempt that succeeded.

**Steps performed — Self-ban protection:**
1. As Admin, attempted to click **Ban** on the Admin's own row (`qa.admin@example.com`).
2. **Expected:** Blocked with a self-protection message, no DB change.
3. **Actual:** "You cannot change the status of your own account." — DB confirmed `IsActive` stayed `1`.

> **Tooling note:** The Reject/Ban/Unban links use `OnClientClick="return confirm(...)"`. The automated browser sandbox used for this testing **force-returns `false`** from every native `confirm()` dialog (visible in the browser console: *"native JavaScript dialogs are disabled in this browser"*), so a plain scripted click silently no-ops. To test the actual server-side behavior, these specific actions were triggered by calling the exact same `__doPostBack(...)` the button's `href` already contains — i.e., exactly what fires after a real user clicks "OK" on the dialog. The dialog's prompt text itself was independently confirmed correct via the console log. **If you reproduce this by hand in a real browser, you'll just see and answer the normal confirm popup — no special steps needed.**

### 4. RBAC — direct URL access

**Steps performed:**
1. Logged out completely.
2. Navigated directly to `http://localhost:54321/Admin/admin-dashboard.aspx` with no session.
3. **Expected:** Redirect to `Login.aspx`.
4. **Actual:** Matched. Also independently confirmed via a cookie-less raw HTTP request (PowerShell `Invoke-WebRequest -MaximumRedirection 0`): server returned **HTTP 302** to `/Login.aspx` — this is a genuine server-side redirect, not just a client-side trick.
5. Logged in as Donor (`qa.donor@example.com`), then navigated directly to `/Admin/admin-dashboard.aspx`, `/NGO/ngo-dashboard.aspx`, and `/Volunteer/volunteer-dashboard.aspx`.
6. **Expected:** `Unauthorized.aspx` ("Access Denied") every time.
7. **Actual:** Matched all three times. Repeated once more logged in as NGO (`qa.ngo2@example.com`) against `/Admin/admin-dashboard.aspx` and `/NGO/ngo-active-requests.aspx` (wrong page for that account state) → also correctly blocked.

### 5. Core Donation Flow (Donor → Admin → NGO)

**Feature:** `Donor/donate-form.aspx` → `Admin/food-approvals.aspx` → `NGO/ngo-dashboard.aspx`.
**Roles used:** Donor, Admin, NGO (three separate logins in sequence, mirroring the real workflow).

**Steps performed — Donor posts a donation:**
1. Log in as `qa.donor@example.com`.
2. Go to **New Donation** (`donate-form.aspx`).
3. Fill in: Food Type = `QA Test Biryani`, Category = `Cooked Meals`, Donor Type = `Restaurant`, Quantity = `10 Plates`, Servings = `10`, Prepared On = `2026-08-09`, Expiry = `2026-08-15T18:00`, Pickup Address = `123 QA Test Street`, City = `Karachi`, Available `10:00`–`14:00`, Contact Person = `QA Donor One`, Contact Phone = `0300-1112223`, Preferred NGO = `QA NGO Two`.
4. Click **Submit Donation**.
5. **Expected:** Redirect to Donor Dashboard with "Donation posted! It's now awaiting admin approval." and a new "Posted" row.
6. **Actual:** Matched. DB: `FoodDonations` row inserted, `Status='Posted'`, `PreferredNGOID=19`.

**Steps performed — Admin approves:**
1. Log out, log in as `qa.admin@example.com`.
2. Go to **Food Approvals**.
3. Confirm the donation appears under "Awaiting Review", sorted/color-coded by expiry urgency (this one showed 🟢 green, ~136h to expiry).
4. Click **Approve**.
5. **Expected:** "Donation approved. NGOs can now request it.", row moves to "Recently Processed" as Approved.
6. **Actual:** Matched. DB: `Status='Approved'`, `ApprovedBy`/`ApprovedAt` stamped with the Admin's UserID and current time.

**Steps performed — NGO accepts:**
1. Log out, log in as `qa.ngo2@example.com`.
2. On NGO Dashboard → **Available Donations**, confirm the donation is listed.
3. Click **Accept**.
4. **Expected:** "Donation accepted. A volunteer will be assigned for pickup.", donation disappears from Available list, "Accepted Today" stat increments.
5. **Actual:** Matched. DB: `FoodDonations.Status='Requested'`; new `FoodRequests` row with `NGOID=19`, `Status='Accepted'`.

**Steps performed — Race-condition safety (two NGOs, same donation):**
1. Posted a second open donation ("QA Race Test Rice", no Preferred NGO — open to all verified NGOs) and approved it the same way.
2. Registered a third NGO account, `qa.ngo3@example.com`, verified via SQL.
3. Using two independent authenticated HTTP sessions (PowerShell, separate cookie jars — simulating two browser tabs logged in as different NGOs), both sessions loaded the NGO dashboard while the donation was still available, capturing each session's own ViewState.
4. Session A (`qa.ngo2`) posted the Accept action first.
5. **Expected:** A succeeds.
6. **Actual:** "Donation accepted. A volunteer will be assigned for pickup." — matched.
7. Session B (`qa.ngo3`) then posted its own (stale, pre-captured) Accept action for the same donation — simulating a genuine race where B loaded the page a moment before A's accept went through.
8. **Expected:** B is rejected with a claimed-by-another-NGO message; DB shows only one accepted request, no duplicate/partial state.
9. **Actual:** Server returned: *"This donation was just claimed by another NGO."* DB confirmed exactly one `FoodRequests` row for that donation (`NGOID=19`), `FoodDonations.Status='Requested'` (not corrupted/duplicated).

**Steps performed — Donor cancels:**
1. Logged back in as `qa.donor@example.com`.
2. Confirmed the dashboard now shows both prior donations as "Requested" with the NGO name populated, and correctly shows **no Cancel button** on either (only `Posted` donations get one).
3. Posted a third donation ("QA Cancel Test Naan") and, while still `Posted`, clicked **Cancel** (confirm dialog: "Cancel this donation?" — triggered via the same `__doPostBack` technique as the Admin ban/reject actions, for the same sandboxed-dialog reason).
4. **Expected:** "Donation cancelled.", status → `Cancelled`, Cancel button disappears.
5. **Actual:** Matched. DB confirmed `Status='Cancelled'`.
6. **Code-level check (server-side authorization):** `Donor/donor-dashboard.aspx.cs`'s Cancel handler runs `UPDATE FoodDonations SET Status='Cancelled' WHERE DonationID=@ID AND DonorID=@DonorID AND Status='Posted'`. This means even if a donor forged a Cancel postback for someone else's donation, or for their own donation after it left `Posted` status, the `UPDATE` would affect 0 rows and the app shows "This donation can no longer be cancelled." — verified by reading the source; the UI already prevents the button from rendering in that state, and the query is additionally scoped so a forged request can't do anything either.

### 6. Logout & shared layout

**Steps performed:** For each of Admin / Donor / NGO / Volunteer: logged in, confirmed the sidebar showed the correct role-specific nav and a live avatar (initials computed from the logged-in user's actual name, e.g. "QO" for "QA Donor One"), then triggered Logout from the sidebar.
**Expected:** Session clears, redirected to `Login.aspx`; a subsequent direct navigation to any dashboard bounces back to Login.
**Actual:** Matched in all four roles, every time.

---

## Bugs found, fixed, and re-verified

### Bug 1 — Registering with no Role selected bypassed validation and leaked a raw SQL error

- **Feature/workflow:** Registration (`login.aspx`, Register panel).
- **Reproduction steps:**
  1. Go to `login.aspx` → Register tab.
  2. Fill in Name, Email, Password, Confirm Password — but leave **"Register As"** on `-- Select Role --`.
  3. Check the Terms checkbox and click **Create Account**.
- **Expected result:** Client-side "Please select a role" validation message, submission blocked.
- **Actual result:** The client-side validator never fired at all, the form posted to the server, and the page displayed:
  > `An error occurred: The INSERT statement conflicted with the CHECK constraint "CK_Users_Role". The conflict occurred in database "LeftoverFood", table "dbo.Users", column 'Role'. The statement has been terminated.`
- **Error/message:** Raw SQL Server exception text shown directly to the end user, including table/constraint names — an information-disclosure issue on top of the broken validation.
- **Root cause:** In `login.aspx`, the `rfvRole` `RequiredFieldValidator` for the role dropdown was missing `ValidationGroup="RegisterGroup"` — every other validator on the Register panel had it, but this one didn't, so it was never included when the "Create Account" button (which only validates group `"RegisterGroup"`) fired. The empty role then reached `login.aspx.cs`'s `btnRegister_Click`, which had no server-side null/empty check either, hit the database's `CK_Users_Role` CHECK constraint, and the generic `catch (Exception ex)` block echoed `ex.Message` straight into the page.
- **Fix applied:**
  1. `login.aspx`: added `ValidationGroup="RegisterGroup"` to `rfvRole`.
  2. `login.aspx.cs`: added an explicit server-side guard (`if (string.IsNullOrEmpty(role)) { ShowMessage("Please select a role."); return; }`) as defense-in-depth, in case client validation is ever bypassed.
  3. `login.aspx.cs`: changed the Register flow's catch block to show a generic "Registration failed. Please try again." message instead of the raw exception text, so no future unexpected DB error can leak schema details to the browser again.
- **Verification after fix:**
  1. Repeated the exact original repro (Register tab, role left unselected) → client-side "Please select a role" now shows correctly and **no request is sent to the server** (confirmed via network log).
  2. Also tested bypassing the client validator entirely via a raw HTTP POST directly to `login.aspx` with `ddlRole=""` (simulating JS-disabled / malicious client) → server responded with the validator's own "Please select a role" message (ASP.NET's automatic server-side re-validation now catches it, since the group is wired correctly) and **no database row was created** (`SELECT COUNT(*) ... → 0`).
  3. Re-ran the full happy-path registration (valid role selected) → still works correctly, new row inserted with the right role. **No regression.**
  4. Re-ran duplicate-email, invalid-email, short-password, and mismatched-password checks → all still correctly blocked. **No regression.**
- **Self-caught follow-up issue:** While applying the catch-block fix, the initial edit accidentally matched and modified the *wrong* catch block (`btnLogin_Click`'s, which is textually identical) instead of `btnRegister_Click`'s. This was caught by re-reading the diff before considering the fix done, and corrected: the login catch block now shows a login-appropriate generic message ("An error occurred while logging in. Please try again."), and the register catch block shows the intended "Registration failed. Please try again." Re-tested login (`qa.donor@example.com`) and a fresh full registration (`qa.finalcheck@example.com`) afterward — both still work correctly.

### Bug 2 — Site-wide character encoding (mojibake) on every non-ASCII character

- **Feature/workflow:** Page rendering, affects every page with an em-dash, emoji, or other non-ASCII character (page titles, "Access Denied" 🚫, Donor dashboard's 👋/🌱, NGO dashboard's 🚚, and every "—" placeholder in donation tables).
- **Reproduction steps:**
  1. Navigate to any page with a non-ASCII character, e.g. `http://localhost:54321/Unauthorized.aspx`.
  2. View the rendered page.
- **Expected result:** `🚫` renders as the prohibition emoji; page title "Login / Register – FoodBridge" shows a proper en-dash.
- **Actual result:** `🚫` rendered as `ðŸš«`; the em/en-dash rendered as `â€"` everywhere it appeared (page titles, table placeholders, donation descriptions).
- **Root cause:** `Web.config` had no `<globalization>` element. The `.aspx` source files are correctly saved as UTF-8 (confirmed with `file <path>` → "UTF-8 text"), and the HTTP response correctly declares `Content-Type: text/html; charset=utf-8`, but without an explicit `fileEncoding`, ASP.NET's page parser reads the `.aspx` markup using the OS default codepage (Windows-1252 on this en-US machine) at compile time. Each multi-byte UTF-8 character in the source gets misread as several separate Windows-1252 characters, and *that* corrupted text is what gets UTF-8-encoded for the response — a classic double-encoding/mojibake bug, independent of what the HTTP header claims.
- **Fix applied:** Added to `Web.config`'s `<system.web>`:
  ```xml
  <globalization fileEncoding="utf-8" requestEncoding="utf-8" responseEncoding="utf-8" />
  ```
- **Verification after fix:**
  1. Restarted IIS Express (Web.config changes trigger an app-pool recycle; did a clean restart to be sure).
  2. Re-checked `Unauthorized.aspx` → 🚫 now renders correctly.
  3. Re-checked the Login page title → "Login / Register **–** FoodBridge" renders with a correct en-dash.
  4. Logged in as Donor and re-checked the dashboard → "Good day, QA Donor One **👋**", "Your Impact **🌱**", "Continental Buffet **–** 150 plates" all render correctly.
  5. Checked NGO dashboard → "Active Deliveries **🚚**" and multiple em-dashes in the pickup-window column render correctly.
  6. No functional regressions observed on any page re-tested afterward (all donation/admin/RBAC flows re-verified post-fix as part of the rest of this session).

### Bug 3 — Broken relative path to `main.js` on the two standalone (no-sidebar) pages

- **Feature/workflow:** `Donor/donate-form.aspx` and `Donor/track-donation.aspx` (the two pages intentionally left outside the shared Master Page layout, per the project's own design notes).
- **Reproduction steps:** Load either page and check the browser's network tab / console.
- **Expected result:** `assets/js/main.js` loads with `200 OK`.
- **Actual result:** `GET http://localhost:54321/js/main.js → 404 Not Found`.
- **Root cause:** Both pages had `<script src="../js/main.js"></script>`, but the actual shared script lives at `/assets/js/main.js`, not `/js/main.js`. Every other page in the app correctly references `assets/js/main.js`; these two were the only stragglers with the wrong relative path.
- **Impact assessment before fixing:** Checked `assets/js/main.js`'s contents and confirmed neither `donate-form.aspx` nor `track-donation.aspx` calls any of its exposed functions (`fbToast`, `fbConfirm`, filter-tab or progress-bar wiring) — this page has no sidebar and no such elements — so the 404 had **zero functional impact**, just a console error. Fixed it anyway since it was a trivial, safe one-line correction.
- **Fix applied:** Changed both `<script src="../js/main.js">` to `<script src="../assets/js/main.js">`.
- **Verification after fix:** Reloaded `donate-form.aspx` and confirmed `GET /assets/js/main.js → 200 OK` in the network log, no more 404. `track-donation.aspx` was fixed identically (not independently browser-verified beyond the source edit, since it wasn't part of this session's active workflow testing, but it's the exact same one-line change).

---

## E2E Testing Completed Up To

**Modules tested:** Authentication (registration + login, all validation branches), Role-Based Access Control (all four roles), Admin User Verification (Phase 1), Core Donation Flow — Donor → Admin → NGO (Phase 2), Logout, and the shared Master Page layout. Also surveyed (without deep functional testing, since they're not built yet) the Volunteer dashboard, NGO active-requests, Donor notifications/profile/ratings, and Admin volunteer-assign/emergency-mode/fraud-detection/reports pages, to confirm they still match the project's own documented "static mockup, RBAC/logout wired only" state.

**Workflows tested, with exact manual steps:** See the "Detailed workflow reproduction steps" section above for registration, login, Admin verification (verify/reject/ban/unban/self-protection), RBAC (unauthenticated + cross-role), and the full donation lifecycle (post → approve → accept → race-condition safety → cancel).

**Users/roles used:** A fresh Admin (`qa.admin@example.com`, promoted via direct SQL since there's no self-service Admin registration), two fresh NGOs (`qa.ngo2@example.com`, `qa.ngo3@example.com` — the second existing solely to prove the accept-race is actually safe with two *real* independent NGO accounts, not just re-clicking as the same user), one Donor (`qa.donor@example.com`), and one Volunteer (`qa.volunteer@example.com`), all registered through the live UI with known passwords rather than using the pre-existing seed accounts (whose passwords were unknown).

**Test data used:** Three real donations were posted end-to-end ("QA Test Biryani" — preferred-NGO path, "QA Race Test Rice" — open/auto-assign path used for the race test, "QA Cancel Test Naan" — cancel path), plus several deliberately-invalid registration/login attempts (empty fields, bad email format, short password, mismatched password, duplicate email, past expiry date, no-role bypass).

**APIs/endpoints involved:** All are ASP.NET Web Forms postback handlers, not REST endpoints — `login.aspx` (`btnLogin_Click`, `btnRegister_Click`), `Admin/admin-dashboard.aspx` (`rptPending_ItemCommand`, `rptUsers_ItemCommand`), `Admin/food-approvals.aspx` (approve/reject item command), `Donor/donate-form.aspx` (`btnSubmit_Click` equivalent), `Donor/donor-dashboard.aspx` (cancel item command), `NGO/ngo-dashboard.aspx` (accept item command, including its race-safe conditional `UPDATE`). One raw cookie-less HTTP request was also made directly against `Admin/admin-dashboard.aspx` to independently confirm the RBAC redirect is server-enforced (HTTP 302), not just a client-side redirect.

**Database changes verified:** Every state-changing action in this report was cross-checked with a direct `sqlcmd` query against `LeftoverFood` immediately after the UI action — `Users.IsVerified`/`IsActive`/row-existence for verify/reject/ban/unban, `FoodDonations.Status`/`ApprovedBy`/`ApprovedAt`/`PreferredNGOID` through the full donation lifecycle, and `FoodRequests` row creation/uniqueness for the NGO-accept and race-condition tests.

**Integrations verified:** None external (no Google Maps, no email/SMTP, no payment) — these are documented as not-yet-built (Phase 4/5/6) and this session did not attempt to test them, since there's nothing to test yet.

**Negative/edge cases tested:** Empty required fields, invalid email format, too-short password, mismatched confirm-password, duplicate email, unverified-account login, wrong-password login, non-existent-email login, banned-account login, no-role-selected registration (both the UI bypass and a raw HTTP bypass), unauthenticated direct URL access, cross-role direct URL access (Donor→Admin, Donor→NGO, Donor→Volunteer, NGO→Admin, NGO→wrong-state-page), admin self-ban, past-expiry donation submission, two-NGO race for the same donation, and cancel-button absence once a donation leaves `Posted` status (plus a source-level check that the cancel endpoint is *also* guarded server-side, not just hidden in the UI).

**Bugs found:** 3 — (1) no-role registration bypassed client validation and leaked a raw SQL error message to the end user; (2) site-wide character-encoding corruption (mojibake) on every em-dash/emoji due to a missing `<globalization>` config; (3) a broken relative path to `main.js` on the two standalone donor pages (zero functional impact, fixed as a trivial cleanup).

**Bugs fixed:** All 3, each with the original repro re-run afterward to confirm the fix, plus a regression pass over the related validation/registration/login flows. One self-inflicted slip during Bug 1's fix (an edit landed on the wrong of two identical catch blocks) was caught by reviewing the diff before calling it done, and corrected in the same pass.

**What is still failing:** Nothing observed is currently failing as of the end of this session — all 32 checklist rows above are ✅ Passed after fixes.

**What has NOT been tested:** Everything the project's own roadmap marks as Phase 3 onward and not yet built: Volunteer assignment & delivery-status tracking (`volunteer-assign.aspx`, the delivery-tracking half of `ngo-active-requests.aspx`, `track-donation.aspx`'s live status view), in-app/email Notifications, Google Maps integration, Emergency Mode broadcasts, Fraud/Duplicate detection, Ratings/Trust scoring, and Reports/analytics export. These pages were confirmed to *load without server errors* and to be correctly RBAC-gated, but their business logic is still static mockup data (as documented in the project's own `IMPLEMENTATION_ROADMAP.md` / `TESTING_CHECKLIST.md`), so there is nothing functional in them yet to test.

**Why it could not be tested:** Not a testing limitation — those features simply don't have server-side logic wired up yet (confirmed by grepping each page for `runat="server"` controls: each has only the 2–4 controls that belong to RBAC/master-page/logout wiring, none tied to real business data). Testing them would just be re-confirming they're mockups, which the code inspection already establishes with certainty.

**One testing-environment note for whoever reproduces this manually:** A couple of destructive actions on the Admin dashboard (Reject / Ban / Unban) are gated behind a native browser `confirm()` popup. If you click them by hand in a normal browser, you'll see and answer that popup as usual — nothing special needed. It only mattered here because the automated browser tool used for this session force-suppresses native dialogs, so those specific actions had to be exercised via their equivalent postback call instead of a literal click; the dialog's own prompt text was still independently confirmed correct.
