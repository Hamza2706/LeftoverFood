<%@ Page Title="My Profile – FoodBridge" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Profile.aspx.cs" Inherits="LeftoverFood.ProfilePage" %>

<%--
  Phase 7. Shared by all four roles.

  This page started as Donor/profile.aspx, a Donor-only mockup. NGO and
  Volunteer had a "Profile" item in the sidebar pointing at "#", and Admin had
  no profile entry at all — so three of the four roles had no way to correct
  their own phone number, address or city. Rather than copy this markup three
  more times, it moved to the app root and is shared, the same call Phase 4 made
  for ~/Notifications.aspx and Phase 6c for ~/Ratings.aspx. It uses Site.master
  directly and renders the role sidebar through the shared RoleSidebar control,
  so it still looks native to whichever role is signed in.

  Unlike ~/Ratings.aspx, Admin is *included*: an admin has an account with a
  name, email, phone and password like anyone else. What Admin does not get is
  the trust card, because Phase 6c excluded admins from ratings entirely.

  HONESTY PASS (continuing Phases 3-6d) — the mockup promised seven things with
  no column, table or feature behind them. All were removed rather than
  restyled:

    * Username ("ahmed_donor") — dbo.Users has no Username column. This app
      authenticates by Email, which is the field now shown.
    * "Typical Donation Frequency" — no column, and nothing would read it.
    * "Email Verified: Yes" / "Phone Verified: Yes" — there is no verification
      of either in this project. Phase 6b deleted a whole fraud rule for exactly
      this reason ("Unverified Contact" would have matched every account).
      IsVerified is admin approval of the account, which is a different thing
      and is shown as such.
    * The four badges (Early Adopter, 40+ Donations, Verified Donor, 1000+
      Meals) and the "Progress to Platinum (60 donations)" bar — there is no
      badge system. The trust ladder that *is* computed lives on ~/Ratings.aspx;
      this page shows a compact summary and links there rather than keeping a
      second copy that could drift.
    * "Preferred NGO Partners" as free text ("Edhi Foundation, Saylani
      Welfare") — the schema has a single PreferredNGOID foreign key, which
      donate-form.aspx already binds as a dropdown. Same control here, bound by
      the same query, so the donor's default and the per-donation choice cannot
      disagree about what the options are.
    * The photo-upload camera button ("Photo upload coming soon!") — there is no
      avatar column on Users and no upload path for one. The initials avatar
      Phase 0 wired up is real and is what remains.

  Also gone: the Danger Zone. "Deactivate" would write IsActive = 0, the same
  column Phase 1's admin Ban and Phase 6b's Suspend use, so the user would be
  locked out by login.aspx.cs with "Your account has been suspended" — the
  mockup's "reactivate anytime" was false, and an admin reviewing the account
  could not tell a self-deactivation from a ban. "Delete Account" would fail
  outright: FK_FraudFlags_User is NO_ACTION (noted in Phase 6b) and donations,
  ratings and notifications all reference Users.

  And the hardcoded figures throughout (47 donations, 4.8 stars, Gold Donor,
  1,240 meals, USR-2025-0031, "Member since Jan 2025", four invented activity
  rows) are now real per-role queries.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
  <style>
    .profile-hero { background:linear-gradient(135deg, var(--green), #1b4332); border-radius:var(--radius-lg); padding:2.5rem; color:#fff; position:relative; overflow:hidden; }
    .profile-hero::after { content:''; position:absolute; width:300px; height:300px; background:rgba(255,255,255,.05); border-radius:50%; top:-80px; right:-60px; }
    .profile-hero .avatar-main { width:90px; height:90px; border-radius:50%; background:rgba(255,255,255,.2); color:#fff; display:flex; align-items:center; justify-content:center; font-family:'DM Serif Display',serif; font-size:2.2rem; border:3px solid rgba(255,255,255,.4); }
    .section-heading { font-family:'DM Serif Display',serif; font-size:1.1rem; padding-bottom:.6rem; border-bottom:1.5px solid var(--sand); margin-bottom:1.2rem; display:flex; align-items:center; gap:.6rem; }
    .section-heading i { font-size:1rem; }
    .activity-item { display:flex; align-items:flex-start; gap:.9rem; padding:.7rem 0; border-bottom:1px solid var(--sand); }
    .activity-item:last-child { border-bottom:none; }
    .act-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:.9rem; flex-shrink:0; }
    .info-row { display:flex; justify-content:space-between; gap:1rem; padding:.55rem 0; border-bottom:1px solid var(--sand); }
    .info-row:last-child { border-bottom:none; }
    .info-row .val { text-align:right; }
    .note-inline { font-size:.78rem; color:var(--text-muted); }
    .readonly-input { background:var(--cream) !important; color:var(--text-muted) !important; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="SidebarContent" runat="server">
  <fb:RoleSidebar runat="server" ID="roleSidebar" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="PageHeading" runat="server">My Profile</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

  <asp:Panel runat="server" ID="pnlMessage" Visible="false" CssClass="alert mb-3">
    <asp:Literal runat="server" ID="litMessage" />
  </asp:Panel>

  <!-- ================= Hero ================= -->
  <div class="profile-hero mb-4">
    <div class="d-flex flex-wrap align-items-center gap-4">
      <div class="avatar-main"><%= Server.HtmlEncode(Initials) %></div>
      <div style="flex:1;min-width:200px">
        <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;margin-bottom:.3rem"><%= Server.HtmlEncode(FullName) %></div>
        <div style="display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;font-size:.85rem;opacity:.85;margin-bottom:.6rem">
          <span class="badge-status" style="background:rgba(255,255,255,.2);color:#fff"><%= Server.HtmlEncode(RoleLabel) %></span>
          <span><i class="bi bi-geo-alt me-1"></i><%= Server.HtmlEncode(CityLabel) %></span>
          <span><i class="bi bi-calendar3 me-1"></i>Member since <%= Server.HtmlEncode(MemberSince) %></span>
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:1.5rem;font-size:.85rem">
          <asp:Literal runat="server" ID="litHeroStats" />
        </div>
      </div>
      <div>
        <asp:Literal runat="server" ID="litVerifiedChip" />
      </div>
    </div>
  </div>

  <div class="row g-4">

    <!-- ================= Left: editable details ================= -->
    <div class="col-lg-7 d-flex flex-column gap-4">

      <!-- Personal Information -->
      <div class="fb-card">
        <div class="section-heading"><i class="bi bi-person-fill text-success"></i>Personal Information</div>
        <div class="row g-3">
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Full Name</label>
              <asp:TextBox runat="server" ID="txtFullName" CssClass="fb-input" MaxLength="150" />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Email Address</label>
              <asp:TextBox runat="server" ID="txtEmail" CssClass="fb-input" TextMode="Email" MaxLength="150" />
              <div class="note-inline mt-1">This is also your sign-in name.</div>
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Phone Number</label>
              <asp:TextBox runat="server" ID="txtPhone" CssClass="fb-input" TextMode="Phone" MaxLength="30" />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Role</label>
              <asp:TextBox runat="server" ID="txtRole" CssClass="fb-input readonly-input" ReadOnly="true" />
              <div class="note-inline mt-1">Only an admin can change a role.</div>
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>City</label>
              <asp:DropDownList runat="server" ID="ddlCity" CssClass="fb-input fb-select">
                <asp:ListItem Value="">— not set —</asp:ListItem>
                <asp:ListItem>Karachi</asp:ListItem>
                <asp:ListItem>Lahore</asp:ListItem>
                <asp:ListItem>Islamabad</asp:ListItem>
                <asp:ListItem>Rawalpindi</asp:ListItem>
                <asp:ListItem>Peshawar</asp:ListItem>
              </asp:DropDownList>
              <div class="note-inline mt-1">Used to target emergency alerts for your area.</div>
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Account Status</label>
              <asp:TextBox runat="server" ID="txtStatus" CssClass="fb-input readonly-input" ReadOnly="true" />
            </div>
          </div>
          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label><asp:Literal runat="server" ID="litAddressLabel" /></label>
              <asp:TextBox runat="server" ID="txtAddress" CssClass="fb-input" MaxLength="300" />
            </div>
          </div>
          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label>About / Bio</label>
              <asp:TextBox runat="server" ID="txtBio" CssClass="fb-input fb-textarea" TextMode="MultiLine"
                           Style="min-height:80px" MaxLength="500" />
              <div class="note-inline mt-1">Up to 500 characters.</div>
            </div>
          </div>
        </div>
        <asp:Button runat="server" ID="btnSavePersonal" CssClass="btn-green mt-3"
                    Text="Save Changes" OnClick="btnSavePersonal_Click" />
      </div>

      <!-- Organisation details — Donor and NGO only -->
      <asp:Panel runat="server" ID="pnlOrg" CssClass="fb-card" Visible="false">
        <div class="section-heading">
          <i class="bi bi-shop text-warning"></i><asp:Literal runat="server" ID="litOrgHeading" />
        </div>
        <div class="row g-3">
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Organization Name</label>
              <asp:TextBox runat="server" ID="txtOrgName" CssClass="fb-input" MaxLength="150" />
            </div>
          </div>
          <asp:Panel runat="server" ID="pnlBusinessType" CssClass="col-sm-6" Visible="false">
            <div class="fb-form-group mb-0">
              <label>Business Type</label>
              <asp:DropDownList runat="server" ID="ddlBusinessType" CssClass="fb-input fb-select">
                <asp:ListItem Value="">— not set —</asp:ListItem>
                <asp:ListItem>Restaurant</asp:ListItem>
                <asp:ListItem>Hotel</asp:ListItem>
                <asp:ListItem>Catering</asp:ListItem>
                <asp:ListItem>Home Kitchen</asp:ListItem>
                <asp:ListItem>Individual</asp:ListItem>
                <asp:ListItem>Event</asp:ListItem>
              </asp:DropDownList>
            </div>
          </asp:Panel>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label><asp:Literal runat="server" ID="litRegLabel" /></label>
              <asp:TextBox runat="server" ID="txtRegNumber" CssClass="fb-input" MaxLength="100" />
            </div>
          </div>
          <asp:Panel runat="server" ID="pnlPreferredNgo" CssClass="col-12" Visible="false">
            <div class="fb-form-group mb-0">
              <label>Preferred NGO</label>
              <asp:DropDownList runat="server" ID="ddlPreferredNGO" CssClass="fb-input fb-select" />
              <div class="note-inline mt-1">
                Pre-selected on the donation form. Leave as “No preference” to offer your
                donations to every verified NGO.
              </div>
            </div>
          </asp:Panel>
        </div>
        <asp:Button runat="server" ID="btnSaveOrg" CssClass="btn-green mt-3"
                    Text="Save" OnClick="btnSaveOrg_Click" />
      </asp:Panel>

      <!-- Location sharing — Volunteer only -->
      <asp:Panel runat="server" ID="pnlVolunteerLocation" CssClass="fb-card" Visible="false">
        <div class="section-heading"><i class="bi bi-geo-alt-fill" style="color:var(--blue)"></i>Location Sharing</div>
        <div class="d-flex flex-wrap gap-3 align-items-center justify-content-between">
          <div>
            <div style="font-weight:600;font-size:.9rem;margin-bottom:.2rem">
              Share my live location during a delivery —
              <asp:Literal runat="server" ID="litShareLocation" />
            </div>
            <div class="note-inline">
              Off by default. When on, your position is recorded only while you have an
              active pickup, and only the donor, the receiving NGO and an admin can see it.
              Switching it off deletes the positions already stored.
            </div>
          </div>
          <a class="btn-sm-outline px-3 py-2" style="border-radius:8px"
             href="<%= ResolveUrl("~/Volunteer/volunteer-dashboard.aspx") %>">Change on dashboard</a>
        </div>
        <div class="note-inline mt-2">
          <i class="bi bi-info-circle me-1"></i>The switch lives on your dashboard, next to the
          delivery it applies to, so there is only one place that turns it on or off.
        </div>
      </asp:Panel>

      <!-- Change Password -->
      <div class="fb-card">
        <div class="section-heading"><i class="bi bi-lock-fill" style="color:var(--purple)"></i>Change Password</div>

        <asp:Panel runat="server" ID="pnlPwMessage" Visible="false" CssClass="alert mb-3">
          <asp:Literal runat="server" ID="litPwMessage" />
        </asp:Panel>

        <div class="row g-3">
          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label>Current Password</label>
              <asp:TextBox runat="server" ID="txtCurrentPassword" CssClass="fb-input"
                           TextMode="Password" placeholder="Enter current password" />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>New Password</label>
              <asp:TextBox runat="server" ID="txtNewPassword" CssClass="fb-input"
                           TextMode="Password" placeholder="Min 8 characters" />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Confirm New Password</label>
              <asp:TextBox runat="server" ID="txtConfirmPassword" CssClass="fb-input"
                           TextMode="Password" placeholder="Repeat new password" />
            </div>
          </div>
        </div>
        <div style="background:var(--cream);border-radius:8px;padding:.7rem;margin-top:.8rem;font-size:.8rem;color:var(--text-muted)">
          <i class="bi bi-info-circle me-1"></i>Password must be at least 8 characters and include
          at least 1 number and 1 special character.
        </div>
        <asp:Button runat="server" ID="btnChangePassword" CssClass="btn-sm-outline mt-3 px-4 py-2"
                    Style="border-radius:8px" Text="Update Password" OnClick="btnChangePassword_Click" />
      </div>

    </div>

    <!-- ================= Right: read-only facts ================= -->
    <div class="col-lg-5 d-flex flex-column gap-4">

      <!-- Trust summary — everyone except Admin -->
      <asp:Panel runat="server" ID="pnlTrust" CssClass="fb-card"
                 Style="background:linear-gradient(145deg,var(--green),#1b4332);color:#fff" Visible="false">
        <div style="font-family:'DM Serif Display',serif;font-size:1.1rem;margin-bottom:1.2rem">Trust</div>
        <div style="display:flex;align-items:center;gap:1rem;background:rgba(255,255,255,.12);border-radius:10px;padding:1rem;margin-bottom:1rem">
          <div style="font-size:2.2rem"><i class="bi bi-star-fill" style="color:#fbbf24"></i></div>
          <div>
            <div style="font-weight:700;font-size:1.2rem"><asp:Literal runat="server" ID="litTrustScore" /></div>
            <div style="font-size:.78rem;opacity:.75"><asp:Literal runat="server" ID="litTrustDetail" /></div>
          </div>
        </div>
        <a class="btn-sm-outline px-3 py-2" style="border-radius:8px;border-color:rgba(255,255,255,.4);color:#fff"
           href="<%= ResolveUrl("~/Ratings.aspx") %>">
          <i class="bi bi-star me-1"></i>View ratings &amp; trust level
        </a>
      </asp:Panel>

      <!-- Account Info -->
      <div class="fb-card">
        <div class="section-heading" style="font-size:.95rem"><i class="bi bi-info-circle-fill text-primary"></i>Account Info</div>
        <div class="d-flex flex-column" style="font-size:.87rem">
          <div class="info-row"><span class="text-muted">Account ID</span><strong class="val"><asp:Literal runat="server" ID="litAccountId" /></strong></div>
          <div class="info-row"><span class="text-muted">Joined</span><strong class="val"><asp:Literal runat="server" ID="litJoined" /></strong></div>
          <div class="info-row"><span class="text-muted">Last Login</span><strong class="val"><asp:Literal runat="server" ID="litLastLogin" /></strong></div>
          <div class="info-row"><span class="text-muted">Admin Approval</span><span class="val"><asp:Literal runat="server" ID="litApproval" /></span></div>
          <div class="info-row"><span class="text-muted">Account Status</span><span class="val"><asp:Literal runat="server" ID="litAccountStatus" /></span></div>
        </div>
        <div class="note-inline mt-2">
          <i class="bi bi-info-circle me-1"></i>Email and phone are not independently verified by
          this system — “approval” above means an admin approved the account.
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="fb-card">
        <div class="section-heading" style="font-size:.95rem"><i class="bi bi-clock-history text-warning"></i>Recent Activity</div>
        <asp:Repeater runat="server" ID="rptActivity">
          <ItemTemplate>
            <div class="activity-item">
              <div class="act-icon" style="background:var(--cream);color:<%# TypeColor(Eval("Type")) %>">
                <i class="bi <%# TypeIcon(Eval("Type")) %>"></i>
              </div>
              <div>
                <div style="font-size:.87rem;font-weight:600"><%# Server.HtmlEncode(Convert.ToString(Eval("Message"))) %></div>
                <div style="font-size:.76rem;color:var(--text-muted)"><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("dd MMM yyyy, h:mm tt") %></div>
              </div>
            </div>
          </ItemTemplate>
        </asp:Repeater>
        <asp:Panel runat="server" ID="pnlNoActivity" Visible="false" CssClass="text-muted"
                   Style="font-size:.85rem;padding:.5rem 0">
          Nothing yet. Your account activity will appear here.
        </asp:Panel>
        <div class="note-inline mt-2">
          Drawn from your notifications —
          <a href="<%= ResolveUrl("~/Notifications.aspx") %>">see all</a>.
        </div>
      </div>

    </div>
  </div>

</asp:Content>
