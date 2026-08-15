<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RoleSidebar.ascx.cs" Inherits="LeftoverFood.Controls.RoleSidebar" %>
<%--
  The one copy of the role sidebar.

  Phase 0 collapsed 13 duplicated page skeletons into Site.master + four role
  masters, but each role master still carried its own <aside> — four near
  identical copies. Phase 4 needs a fifth (the shared ~/Notifications.aspx,
  which lives at the app root and so cannot inherit any single role master), so
  the markup moved here instead of being copied again.

  Consumed by: Admin/NGO/Donor/VolunteerMaster.master, ~/Notifications.aspx,
  ~/Ratings.aspx (Phase 6c, which made the same root-level move for the same
  reason — Donor had a ratings page, NGO and Volunteer did not) and
  ~/Profile.aspx (Phase 7, the same move a third time — Donor had a profile
  page, NGO and Volunteer linked theirs to "#", and Admin had no entry at all).
  Registered globally in Web.config <pages><controls>, so no per-file
  <%@ Register %> directive is needed.

  SIX ITEMS ARE ANCHORS, NOT PAGES. "All Donations", "All Users", "My
  Donations", "Our Volunteers", "My Tasks" and "Completed" all pointed at "#"
  because no such page was ever built — but each names a section that now
  exists, with real data, on that role's own dashboard. They link to the
  dashboard plus a fragment rather than to a new page, which is honest
  navigation (it genuinely moves you to the thing named) without inventing four
  more screens that would only re-query what the dashboard already shows.

  They deliberately do NOT call IsActive(): the target file is the dashboard, so
  highlighting them would light up two nav items at once.

  Three further items were DELETED rather than left on "#", because they are
  dead by design rather than merely unbuilt — each is documented at its old
  position: NGO "Reports" (the only reports page is Admin-only and would bounce
  an NGO to ~/Unauthorized.aspx), Volunteer "Nearby Pickups" (assignment is
  admin-driven, so a volunteer cannot claim one) and Volunteer "My Points"
  (there is no points system; Phases 3, 6c and 7 all removed its UI).

  The seven items still on "#" are screens that were never built but could
  reasonably exist: Admin Donors / NGOs / Volunteers / Settings, Donor My
  Certificates, NGO History, Volunteer Messages.
--%>
<aside class="fb-sidebar" id="fbSidebar">
  <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
  <nav class="fb-sidebar-nav">

    <% if (Role == "Admin") { %>
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item <%= IsActive("admin-dashboard.aspx") %>" href="<%= ResolveUrl("~/Admin/admin-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("food-approvals.aspx") %>" href="<%= ResolveUrl("~/Admin/food-approvals.aspx") %>"><i class="bi bi-clipboard2-check-fill"></i> Food Approvals</a>
      <a class="fb-nav-item <%= IsActive("volunteer-assign.aspx") %>" href="<%= ResolveUrl("~/Admin/volunteer-assign.aspx") %>"><i class="bi bi-person-check-fill"></i> Assign Volunteers</a>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/Admin/admin-dashboard.aspx") %>#all-donations"><i class="bi bi-basket2"></i> All Donations</a>
      <div class="fb-sidebar-section">Users</div>
      <%-- One page, three entry points. These are the same view filtered by
           role, so ~/Admin/users.aspx takes a ?role= parameter rather than
           existing as three near-identical pages — the de-duplication call
           Phases 0, 4, 6c and 7 all made. IsRoleActive() highlights whichever
           one is showing. --%>
      <a class="fb-nav-item <%= IsRoleActive("Donor") %>" href="<%= ResolveUrl("~/Admin/users.aspx") %>?role=Donor"><i class="bi bi-person-lines-fill"></i> Donors</a>
      <a class="fb-nav-item <%= IsRoleActive("NGO") %>" href="<%= ResolveUrl("~/Admin/users.aspx") %>?role=NGO"><i class="bi bi-building-fill-heart"></i> NGOs</a>
      <a class="fb-nav-item <%= IsRoleActive("Volunteer") %>" href="<%= ResolveUrl("~/Admin/users.aspx") %>?role=Volunteer"><i class="bi bi-bicycle"></i> Volunteers</a>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/Admin/admin-dashboard.aspx") %>#all-users"><i class="bi bi-person-fill-gear"></i> All Users</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item <%= IsActive("reports.aspx") %>" href="<%= ResolveUrl("~/Admin/reports.aspx") %>"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item <%= IsActive("emergency-mode.aspx") %>" href="<%= ResolveUrl("~/Admin/emergency-mode.aspx") %>"><i class="bi bi-exclamation-triangle-fill"></i> Emergency Mode</a>
      <a class="fb-nav-item <%= IsActive("fraud-detection.aspx") %>" href="<%= ResolveUrl("~/Admin/fraud-detection.aspx") %>"><i class="bi bi-shield-exclamation"></i> Fraud Detection</a>
      <%-- "Settings" removed: there is no application-wide settings screen and
           nothing that would go on one. The only configuration this app has is
           Web.config (SMTP, connection string), which is not editable from the
           browser by design, and per-user preferences already live on
           ~/Profile.aspx and Donor/notifications.aspx. --%>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item <%= IsActive("Profile.aspx") %>" href="<%= ResolveUrl("~/Profile.aspx") %>"><i class="bi bi-person-fill"></i> My Profile</a>

    <% } else if (Role == "Donor") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("donor-dashboard.aspx") %>" href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("donate-form.aspx") %>" href="<%= ResolveUrl("~/Donor/donate-form.aspx") %>"><i class="bi bi-plus-circle-fill"></i> New Donation</a>
      <a class="fb-nav-item <%= IsActive("track-donation.aspx") %>" href="<%= ResolveUrl("~/Donor/track-donation.aspx") %>"><i class="bi bi-geo-alt-fill"></i> Track Donation</a>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>#my-donations"><i class="bi bi-clock-history"></i> My Donations</a>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item <%= IsActive("Ratings.aspx") %>" href="<%= ResolveUrl("~/Ratings.aspx") %>"><i class="bi bi-star-fill"></i> Ratings &amp; Trust</a>
      <%-- "My Certificates" removed: nothing in this app issues a certificate.
           There is no template, no generator and no store for one, and the
           closest real thing — a donor's delivery record and trust level — is
           already on the dashboard and Ratings & Trust. --%>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item <%= IsActive("Profile.aspx") %>" href="<%= ResolveUrl("~/Profile.aspx") %>"><i class="bi bi-person-fill"></i> My Profile</a>
      <a class="fb-nav-item <%= IsActive("notifications.aspx") %>" href="<%= ResolveUrl("~/Donor/notifications.aspx") %>"><i class="bi bi-sliders"></i> Email Settings</a>

    <% } else if (Role == "NGO") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("ngo-dashboard.aspx") %>" href="<%= ResolveUrl("~/NGO/ngo-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("ngo-active-requests.aspx") %>" href="<%= ResolveUrl("~/NGO/ngo-active-requests.aspx") %>"><i class="bi bi-clipboard2-check-fill"></i> Active Requests</a>
      <%-- "History" removed: ngo-active-requests.aspx already ends with a
           "Recently Completed" table of this NGO's finished deliveries, so a
           separate history screen would re-query the same rows. --%>
      <div class="fb-sidebar-section">Manage</div>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/NGO/ngo-dashboard.aspx") %>#our-volunteers"><i class="bi bi-people-fill"></i> Our Volunteers</a>
      <a class="fb-nav-item <%= IsActive("Ratings.aspx") %>" href="<%= ResolveUrl("~/Ratings.aspx") %>"><i class="bi bi-star-fill"></i> Ratings &amp; Trust</a>
      <%-- "Reports" removed, not left on "#": the only reports page in this app
           is Admin/reports.aspx, which calls RequireRole(this, "Admin") — an NGO
           following this link would land on ~/Unauthorized.aspx. NGO-scoped
           reporting would be a new page, and the NGO dashboard's Monthly
           Distribution Summary already covers the figures it would show. --%>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item <%= IsActive("Profile.aspx") %>" href="<%= ResolveUrl("~/Profile.aspx") %>"><i class="bi bi-building-fill"></i> NGO Profile</a>

    <% } else if (Role == "Volunteer") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("volunteer-dashboard.aspx") %>" href="<%= ResolveUrl("~/Volunteer/volunteer-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/Volunteer/volunteer-dashboard.aspx") %>#my-tasks"><i class="bi bi-list-task"></i> My Tasks</a>
      <a class="fb-nav-item" href="<%= ResolveUrl("~/Volunteer/volunteer-dashboard.aspx") %>#completed"><i class="bi bi-clock-history"></i> Completed</a>
      <%-- "Nearby Pickups" removed, not left on "#": Phase 3 established that
           assignment is admin-driven in this design, not self-serve, and deleted
           the dashboard's fake "Nearby Available Pickups" list for that reason.
           A volunteer cannot claim a pickup, so there is nothing for this to
           open. Phase 5 also found most addresses only geocode to city level,
           so "nearby" is not something this data could rank on either. --%>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item <%= IsActive("Ratings.aspx") %>" href="<%= ResolveUrl("~/Ratings.aspx") %>"><i class="bi bi-star-fill"></i> Ratings &amp; Trust</a>
      <%-- "Messages" removed: there is no messaging feature. Phase 4 built
           one-way notifications, not a conversation — nothing in the schema can
           hold a reply, and NotifyEvent.NewMessages has sat dormant since. The
           notification list below is where a volunteer actually hears from the
           system. --%>
      <%-- "My Points" removed, not left on "#": there is no points system.
           Phase 3 deleted the dashboard's fabricated points/badges/rank card,
           and Phases 6c and 7 removed the badge blocks from ~/Ratings.aspx and
           ~/Profile.aspx for the same reason. Recognition in this app is the
           computed trust level, which Ratings & Trust above already links to. --%>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item <%= IsActive("Profile.aspx") %>" href="<%= ResolveUrl("~/Profile.aspx") %>"><i class="bi bi-person-fill"></i> Profile</a>
    <% } %>

    <%-- Phase 4: every role now has a real notifications page. Previously the
         NGO and Volunteer sidebars linked this to "#", and the Donor one
         pointed at the email-settings page. --%>
    <a class="fb-nav-item <%= IsActive("Notifications.aspx") %>" href="<%= ResolveUrl("~/Notifications.aspx") %>">
      <i class="bi bi-bell-fill"></i> Notifications
      <asp:Literal runat="server" ID="litSidebarUnread" />
    </a>

    <asp:LinkButton runat="server" ID="btnLogout" CssClass="fb-nav-item" Style="color:var(--red)" OnClick="btnLogout_Click"><i class="bi bi-box-arrow-left"></i> Logout</asp:LinkButton>
  </nav>

  <div class="fb-sidebar-footer">
    <div class="fb-user-chip">
      <div class="fb-avatar" style="<%= AvatarStyle %>"><%= Initials %></div>
      <div>
        <div class="name"><%= FullName %></div>
        <div class="role"><span class="badge-status <%= RoleBadgeClass %> px-2"><%= RoleLabel %></span></div>
      </div>
    </div>
  </div>
</aside>
