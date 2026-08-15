<%@ Page Title="Manage Users – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="users.aspx.cs" Inherits="LeftoverFood.Admin.users" %>

<%--
  Phase 10. Admin only.

  Backs the sidebar's Donors / NGOs / Volunteers items, which pointed at "#"
  because no such screen was ever built.

  ONE PAGE, NOT THREE. The three views differ only in which role they filter to
  and which activity columns make sense, so this takes ?role= rather than
  existing as three near-identical files — the same de-duplication call Phases
  0, 4, 6c and 7 made. ?role=All is also accepted, which makes this a superset
  of the admin dashboard's "Registered Users" table.

  The role parameter is matched against a whitelist and passed as a
  SqlParameter; it is never concatenated into SQL, and an unrecognised value
  falls back to All rather than erroring.

  Moderation actions go through UserAdminService so the self-suspension guard
  and the notification wiring cannot drift from the copy on the dashboard.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .role-tab { display:inline-flex; align-items:center; gap:.4rem; padding:.45rem 1.1rem; border-radius:50px;
                border:1.5px solid var(--sand-dark); background:#fff; font-size:.85rem; font-weight:600;
                color:var(--text-muted); text-decoration:none; }
    .role-tab.active { background:var(--green); border-color:var(--green); color:#fff; }
    .u-name { display:flex; align-items:center; gap:.6rem; }
    .u-sub { font-size:.75rem; color:var(--text-muted); }
    .metric { font-weight:700; }
    .empty-note { padding:2rem 1rem; text-align:center; color:var(--text-muted); font-size:.88rem; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Manage Users</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

  <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
      <h2 style="font-size:1.6rem;margin-bottom:.2rem"><asp:Literal ID="litHeading" runat="server" /></h2>
      <p class="text-muted mb-0" style="font-size:.9rem"><asp:Literal ID="litSubheading" runat="server" /></p>
    </div>
    <div class="d-flex flex-wrap gap-2">
      <a class='role-tab <%= RoleTabClass("Donor") %>' href="?role=Donor"><i class="bi bi-person-lines-fill"></i>Donors</a>
      <a class='role-tab <%= RoleTabClass("NGO") %>' href="?role=NGO"><i class="bi bi-building-fill-heart"></i>NGOs</a>
      <a class='role-tab <%= RoleTabClass("Volunteer") %>' href="?role=Volunteer"><i class="bi bi-bicycle"></i>Volunteers</a>
      <a class='role-tab <%= RoleTabClass("All") %>' href="?role=All"><i class="bi bi-people-fill"></i>All</a>
    </div>
  </div>

  <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

  <!-- Counters, scoped to the selected role -->
  <div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
      <div class="stat-card">
        <div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-people-fill"></i></div>
        <div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litTotal" runat="server" Text="0" /></div>
        <div class="stat-lbl">Total</div>
      </div>
    </div>
    <div class="col-6 col-lg-3">
      <div class="stat-card">
        <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-patch-check-fill"></i></div>
        <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litApproved" runat="server" Text="0" /></div>
        <div class="stat-lbl">Approved</div>
      </div>
    </div>
    <div class="col-6 col-lg-3">
      <div class="stat-card">
        <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-hourglass-split"></i></div>
        <div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litPending" runat="server" Text="0" /></div>
        <div class="stat-lbl">Pending Approval</div>
      </div>
    </div>
    <div class="col-6 col-lg-3">
      <div class="stat-card">
        <div class="stat-icon mb-2" style="background:#fee2e2;color:var(--red)"><i class="bi bi-slash-circle"></i></div>
        <div class="stat-val" style="color:var(--red)"><asp:Literal ID="litSuspended" runat="server" Text="0" /></div>
        <div class="stat-lbl">Suspended</div>
      </div>
    </div>
  </div>

  <div class="fb-card p-0 overflow-hidden">
    <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 p-3 border-bottom" style="border-color:var(--sand)!important">
      <h6 class="mb-0" style="font-family:'DM Serif Display',serif"><asp:Literal ID="litTableHeading" runat="server" /></h6>
      <%-- Same client-side filter mechanism main.js already drives elsewhere. --%>
      <div class="d-flex gap-2" data-filter-group>
        <button type="button" class="btn-sm-outline active" data-filter="all">All</button>
        <button type="button" class="btn-sm-outline" data-filter="pending">Pending</button>
        <button type="button" class="btn-sm-outline" data-filter="active">Active</button>
        <button type="button" class="btn-sm-outline" data-filter="suspended">Suspended</button>
      </div>
    </div>

    <div class="table-responsive">
      <table class="fb-table">
        <thead>
          <tr>
            <th class="ps-3">Name</th>
            <th>Contact</th>
            <th>City</th>
            <th><asp:Literal ID="litMetricA" runat="server" /></th>
            <th><asp:Literal ID="litMetricB" runat="server" /></th>
            <th>Rating</th>
            <th>Joined</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <asp:Repeater ID="rptUsers" runat="server" OnItemCommand="rptUsers_ItemCommand">
            <ItemTemplate>
              <tr data-status='<%# StatusFilter(Eval("IsVerified"), Eval("IsActive")) %>'>
                <td class="ps-3">
                  <div class="u-name">
                    <div class="fb-avatar" style="width:32px;height:32px;font-size:.75rem"><%# Server.HtmlEncode(Initials(Eval("FullName"))) %></div>
                    <div>
                      <div><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></div>
                      <div class="u-sub"><%# RoleOrOrg(Eval("Role"), Eval("OrganizationName")) %></div>
                    </div>
                  </div>
                </td>
                <td>
                  <div style="font-size:.83rem"><%# Server.HtmlEncode(Convert.ToString(Eval("Email"))) %></div>
                  <div class="u-sub"><%# Server.HtmlEncode(Dash(Eval("Phone"))) %></div>
                </td>
                <td><%# Server.HtmlEncode(Dash(Eval("City"))) %></td>
                <td><span class="metric"><%# Eval("MetricA") %></span></td>
                <td><span class="metric"><%# Eval("MetricB") %></span></td>
                <td><%# TrustLabel(Eval("TrustScore")) %></td>
                <td><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("MMM yyyy") %></td>
                <td><span class="badge-status <%# StatusBadgeClass(Eval("IsVerified"), Eval("IsActive")) %>"><%# StatusBadgeText(Eval("IsVerified"), Eval("IsActive")) %></span></td>
                <td>
                  <div class="d-flex gap-1 flex-wrap">
                    <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Verify"
                                    CommandArgument='<%# Eval("UserID") %>'
                                    Visible='<%# !(bool)Eval("IsVerified") %>'>Approve</asp:LinkButton>
                    <asp:LinkButton runat="server" CssClass="btn-sm-red" CommandName="Reject"
                                    CommandArgument='<%# Eval("UserID") %>'
                                    Visible='<%# !(bool)Eval("IsVerified") %>'
                                    OnClientClick="return confirm('Reject and permanently remove this registration?');">Reject</asp:LinkButton>
                    <asp:LinkButton runat="server" CssClass="btn-sm-red" CommandName="Ban"
                                    CommandArgument='<%# Eval("UserID") %>'
                                    Visible='<%# (bool)Eval("IsVerified") && (bool)Eval("IsActive") %>'
                                    OnClientClick="return confirm('Suspend this user? They will not be able to sign in.');">Suspend</asp:LinkButton>
                    <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Unban"
                                    CommandArgument='<%# Eval("UserID") %>'
                                    Visible='<%# (bool)Eval("IsVerified") && !(bool)Eval("IsActive") %>'>Reinstate</asp:LinkButton>
                  </div>
                </td>
              </tr>
            </ItemTemplate>
          </asp:Repeater>
        </tbody>
      </table>
    </div>

    <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
      <div class="empty-note"><asp:Literal ID="litEmpty" runat="server" /></div>
    </asp:Panel>
  </div>

  <div class="text-muted mt-3" style="font-size:.78rem">
    <i class="bi bi-info-circle me-1"></i>
    Approving lets an account sign in. Suspending sets the same <code>IsActive</code> flag the
    fraud queue uses, so an account suspended here shows as suspended there too. Rejecting
    <strong>deletes</strong> a pending registration — it is only offered before approval.
  </div>

</asp:Content>
