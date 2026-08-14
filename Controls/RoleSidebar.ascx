<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RoleSidebar.ascx.cs" Inherits="LeftoverFood.Controls.RoleSidebar" %>
<%--
  The one copy of the role sidebar.

  Phase 0 collapsed 13 duplicated page skeletons into Site.master + four role
  masters, but each role master still carried its own <aside> — four near
  identical copies. Phase 4 needs a fifth (the shared ~/Notifications.aspx,
  which lives at the app root and so cannot inherit any single role master), so
  the markup moved here instead of being copied again.

  Consumed by: Admin/NGO/Donor/VolunteerMaster.master and ~/Notifications.aspx.
  Registered globally in Web.config <pages><controls>, so no per-file
  <%@ Register %> directive is needed.
--%>
<aside class="fb-sidebar" id="fbSidebar">
  <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
  <nav class="fb-sidebar-nav">

    <% if (Role == "Admin") { %>
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item <%= IsActive("admin-dashboard.aspx") %>" href="<%= ResolveUrl("~/Admin/admin-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("food-approvals.aspx") %>" href="<%= ResolveUrl("~/Admin/food-approvals.aspx") %>"><i class="bi bi-clipboard2-check-fill"></i> Food Approvals</a>
      <a class="fb-nav-item <%= IsActive("volunteer-assign.aspx") %>" href="<%= ResolveUrl("~/Admin/volunteer-assign.aspx") %>"><i class="bi bi-person-check-fill"></i> Assign Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-basket2"></i> All Donations</a>
      <div class="fb-sidebar-section">Users</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-lines-fill"></i> Donors</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill-heart"></i> NGOs</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bicycle"></i> Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill-gear"></i> All Users</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item <%= IsActive("reports.aspx") %>" href="<%= ResolveUrl("~/Admin/reports.aspx") %>"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item <%= IsActive("emergency-mode.aspx") %>" href="<%= ResolveUrl("~/Admin/emergency-mode.aspx") %>"><i class="bi bi-exclamation-triangle-fill"></i> Emergency Mode</a>
      <a class="fb-nav-item <%= IsActive("fraud-detection.aspx") %>" href="<%= ResolveUrl("~/Admin/fraud-detection.aspx") %>"><i class="bi bi-shield-exclamation"></i> Fraud Detection</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-gear-fill"></i> Settings</a>

    <% } else if (Role == "Donor") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("donor-dashboard.aspx") %>" href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("donate-form.aspx") %>" href="<%= ResolveUrl("~/Donor/donate-form.aspx") %>"><i class="bi bi-plus-circle-fill"></i> New Donation</a>
      <a class="fb-nav-item <%= IsActive("track-donation.aspx") %>" href="<%= ResolveUrl("~/Donor/track-donation.aspx") %>"><i class="bi bi-geo-alt-fill"></i> Track Donation</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> My Donations</a>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item <%= IsActive("ratings.aspx") %>" href="<%= ResolveUrl("~/Donor/ratings.aspx") %>"><i class="bi bi-star-fill"></i> Ratings &amp; Trust</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-award-fill"></i> My Certificates</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item <%= IsActive("profile.aspx") %>" href="<%= ResolveUrl("~/Donor/profile.aspx") %>"><i class="bi bi-person-fill"></i> My Profile</a>
      <a class="fb-nav-item <%= IsActive("notifications.aspx") %>" href="<%= ResolveUrl("~/Donor/notifications.aspx") %>"><i class="bi bi-sliders"></i> Email Settings</a>

    <% } else if (Role == "NGO") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("ngo-dashboard.aspx") %>" href="<%= ResolveUrl("~/NGO/ngo-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item <%= IsActive("ngo-active-requests.aspx") %>" href="<%= ResolveUrl("~/NGO/ngo-active-requests.aspx") %>"><i class="bi bi-clipboard2-check-fill"></i> Active Requests</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> History</a>
      <div class="fb-sidebar-section">Manage</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-people-fill"></i> Our Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill"></i> NGO Profile</a>

    <% } else if (Role == "Volunteer") { %>
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item <%= IsActive("volunteer-dashboard.aspx") %>" href="<%= ResolveUrl("~/Volunteer/volunteer-dashboard.aspx") %>"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-list-task"></i> My Tasks</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> Completed</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-geo-alt-fill"></i> Nearby Pickups</a>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-chat-dots-fill"></i> Messages</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-trophy-fill"></i> My Points</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill"></i> Profile</a>
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
