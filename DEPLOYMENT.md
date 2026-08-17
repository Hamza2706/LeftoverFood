# Deployment — FoodBridge / LeftoverFood

Target: **MonsterASP.NET free plan** (Windows/IIS, MSSQL, free `*.runasp.net`
subdomain, free Let's Encrypt HTTPS).

The project is ASP.NET Web Forms on .NET Framework 4.7.2, so it needs Windows
hosting with IIS. It cannot run on Render, Railway, Fly.io, Vercel or Heroku —
those are Linux hosts and Web Forms does not run there. Don't lose time on them.

---

## What is already handled in code

These were changed so they cannot be forgotten at deploy time:

| Concern | Where | Behaviour |
|---|---|---|
| HTTP → HTTPS redirect | `Global.asax.cs` → `ForceHttps()` | Redirects live traffic to https. Skipped for `localhost`, so local debugging is unaffected. |
| Email link base URL | `NotificationService.cs` → `CurrentBaseUrl()` | Derived from the live request, so links are right even if `App.BaseUrl` is stale. |
| Upload folder missing | `Donor/donate-form.aspx.cs` → `SavePhotoIfProvided()` | Creates `uploads/images` on demand instead of throwing. |
| Connection string / debug flag | `Web.Release.config` | Swapped at publish time. `Web.config` keeps local settings. |

**Why the HTTPS redirect matters:** volunteer live tracking calls
`navigator.geolocation.watchPosition`, and browsers only grant the Geolocation
API to a secure context. `localhost` is exempt; a deployed `http://` address is
not. Over plain HTTP the map renders but the marker never moves — it looks like
an app bug, not a missing certificate.

---

## 1. Fill in the placeholders

Create the site and database in the MonsterASP panel first, then edit
`Web.Release.config` and replace:

| Placeholder | Where to find it |
|---|---|
| `SQL_SERVER_HOST` | Panel → Databases → your database → server address |
| `DB_NAME` | same screen |
| `DB_USER` | same screen |
| `DB_PASSWORD` | same screen |
| `YOURSITE` | your subdomain, e.g. `foodbridge` in `foodbridge.runasp.net` |

`YOURSITE` appears twice — in `App.BaseUrl` and in `Geocoding.UserAgent`.

## 2. Enable HTTPS on the host

Turn on the free Let's Encrypt certificate in the panel **before** testing.
Until it exists, the redirect in `ForceHttps()` sends traffic to an address that
does not answer yet.

## 3. Create the database — schema only, no data

Demo data is created directly on the live site after deploy, not migrated from
local. Only the empty schema (tables, keys, constraints — no rows) needs to move.

Do **not** run `Database/schema.sql` against the new database. The live local DB
has drifted from that file more than once (missing columns, wrong types), so it
would produce a schema the app does not match. Script the *real* local database
instead:

1. SSMS → right-click `LeftoverFood` → **Tasks → Generate Scripts**
2. Select all objects
3. **Advanced** → set *Types of data to script* = **Schema only**
4. Save to a single `.sql` file

Then load it into the host:

1. Panel → your database → **Remote access for SSMS** tab → enable it (off by default)
2. Connect SSMS to the server address / login / password shown there — same
   credentials work for both the deployed site and this connection, it's one
   toggle gating outside access, not a separate account
3. Run the generated script

## 4. Seed the one account the site cannot create itself

Public registration only offers Donor / NGO / Volunteer (`login.aspx`), and every
self-registered account starts unapproved (`IsVerified = 0`) until an Admin signs
off on it. On a brand-new database there is no Admin yet to do that — so without
one seeded manually, the very first login of any kind is rejected with "pending
admin approval" and there is no way past it through the UI.

`Database/seed_admin.sql` has the insert, with the reasoning in its comments.
Passwords are salted PBKDF2 (`PasswordHelper.cs`), so a plain-text password
cannot just be typed into the row — generate a real hash first:

```powershell
function New-FoodBridgePasswordHash {
    param([Parameter(Mandatory=$true)][string]$Password)
    $iterations = 100000
    $saltSize = 16
    $keySize = 32
    $salt = New-Object byte[] $saltSize
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $Password, $salt, $iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    $hash = $pbkdf2.GetBytes($keySize)
    return "PBKDF2$" + $iterations + "$" + [Convert]::ToBase64String($salt) + "$" + [Convert]::ToBase64String($hash)
}

New-FoodBridgePasswordHash -Password "YourChosenAdminPassword"
```

Paste the printed hash into `seed_admin.sql` in place of `PASTE_GENERATED_HASH_HERE`,
set `@Email` to whatever you'll actually sign in with, then run the script against
the host database the same way as step 3 (SSMS, remote connection).

## 5. Publish

Publish from Visual Studio in the **Release** configuration.

> **This matters.** Config transforms are applied at publish time. Copying raw
> project files over FTP skips them, and the site starts up pointing at
> `Elitebook\SQLEXPRESS` — which does not exist on the host, so every page fails
> on its first query.

Deploy payload is ~21 MB against a 5 GB quota. `packages/`, `obj/`, `.git/` and
`.vs/` are not uploaded.

## 6. Grant write access

Confirm the host allows writes to:

- `uploads/images` — donation photos
- `App_Data` — `notification-errors.log`

Both are best-effort in code, but photo uploads visibly fail without the first.

## 7. Build the demo data on the live site itself

With the schema in place, the app published, and one Admin account seeded, the
rest happens through the deployed app directly:

1. Log in as the seeded Admin
2. Register Donor / NGO / Volunteer test accounts through the normal signup form
3. As Admin, approve each one (`IsVerified` flips to 1) — Admin\users.aspx
4. Log in as those accounts and post donations, requests, ratings — whatever the
   demo needs

This exercises the exact code path a teacher will see, geocodes addresses through
the live server as they're entered (so results land straight in that database's
`GeocodeCache`, no separate warm-up step needed), and never requires typing
records by hand into a SQL panel.

---

## Post-deploy verification

Work through this in order — each step depends on the previous one working.

- [ ] Site loads over `https://YOURSITE.runasp.net`
- [ ] Typing the bare `http://` address redirects to `https://`
- [ ] Log in as each role (Donor, NGO, Volunteer, Admin)
- [ ] Post a donation **with a photo** — confirms DB write + `uploads/images`
- [ ] Photo displays back on the donation listing
- [ ] Map renders on NGO active requests (Leaflet + OSM tiles)
- [ ] **Volunteer dashboard → start location sharing → marker moves.** The HTTPS-dependent one. Test on a phone, and accept the browser permission prompt.
- [ ] Donor track-donation page shows the volunteer position updating
- [ ] Trigger a notification → row appears in-app
- [ ] Matching email arrives, and **the link in it opens the live site**, not localhost
- [ ] Search and filtering return results
- [ ] Ratings submit and display

## Troubleshooting

**"Your account is pending admin approval" on the very first login.** Step 4
(seeding the Admin) was skipped, or `IsVerified` wasn't set to `1` in the insert.
Check with `SELECT Email, Role, IsVerified FROM Users WHERE Role = 'Admin'`
against the host database — if that returns no rows, or `IsVerified = 0`, rerun
`seed_admin.sql`.

**Every page throws.** Almost always the connection string. Confirm the
transform applied: publish output `Web.config` should contain your real server
address, not `SQL_SERVER_HOST`.

**Need to see the real error.** `Web.config` uses
`customErrors mode="RemoteOnly"`, so on a host *everyone* is remote and everyone
gets `Error.aspx`. Temporarily set `mode="Off"` to see the actual exception —
and set it back before the demo.

**No emails arriving.** Notifications always write to the DB; email is
best-effort on top, and failures are swallowed by design. Check
`App_Data/notification-errors.log`. If SMTP is blocked outbound, the app keeps
working with in-app notifications only.

**Everyone gets logged out at once.** The free plan gives 256 MB RAM and session
state is `InProc`, so an app pool recycle drops every session. If it becomes a
problem, move session state to SQL Server.

**Site feels slow.** Free tier is EU-only; expect ~130–180 ms round trip from
Pakistan, and Web Forms posts back with ViewState on every click. Disabling
ViewState on read-only grids is the usual fix if a specific page drags.

---

## Demo day

- Load the site ~10 minutes early — free tiers idle out and the first hit is slow.
- Keep the local copy working as a fallback. The plan says "no guarantees or
  warranties" for a reason.
- If the repo is ever made public, **revoke the Gmail app password in
  `Web.config` first** and generate a new one — it is in the git history.
