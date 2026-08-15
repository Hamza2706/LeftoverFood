<%@ Page Title="Search – FoodBridge" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Search.aspx.cs" Inherits="LeftoverFood.SearchPage" %>

<%--
  Phase 9. Shared by all four roles.

  The topbar search box in Site.master was a plain <input> with no name, no
  handler and nowhere to go — decorative on every page in the app. It now posts
  here.

  This page lives at the app root on Site.master + RoleSidebar, the same shape
  as ~/Notifications.aspx (Phase 4), ~/Ratings.aspx (6c) and ~/Profile.aspx (7).
  It has to: the box appears in a master shared by all four roles, so a
  role-specific results page would mean four copies of it.

  SCOPING IS THE WHOLE JOB. Search is the easiest place in an app to leak data,
  because a single query box invites you to run one query for everybody. Every
  statement here is filtered by the signed-in user's own ID taken from the
  session, never from the request:

    Donor      only their own donations
    NGO        donations open to them, plus the ones they accepted
    Volunteer  only donations they were assigned to carry
    Admin      all donations, and users as well

  The user search is Admin-only. A donor being able to search the account list
  by name and email would be a straightforward privacy hole, so it is not a
  hidden section — the query is never run for anyone else.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
  <style>
    .search-summary { font-size:.9rem; color:var(--text-muted); margin-bottom:1.2rem; }
    .search-term { font-weight:700; color:var(--text); }
    .result-row { display:flex; gap:1rem; align-items:flex-start; padding:.85rem 0; border-bottom:1px solid var(--sand); }
    .result-row:last-child { border-bottom:none; }
    .result-icon { width:36px; height:36px; border-radius:9px; display:flex; align-items:center; justify-content:center; flex-shrink:0; background:var(--cream); }
    .result-main { flex:1; min-width:0; }
    .result-title { font-size:.9rem; font-weight:600; margin-bottom:.15rem; }
    .result-meta { font-size:.78rem; color:var(--text-muted); }
    .empty-note { font-size:.88rem; color:var(--text-muted); padding:1.5rem 0; text-align:center; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="SidebarContent" runat="server">
  <fb:RoleSidebar runat="server" ID="roleSidebar" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="PageHeading" runat="server">Search</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

  <div class="page-header">
    <h2>Search</h2>
    <p class="mb-0"><asp:Literal runat="server" ID="litScopeNote" /></p>
  </div>

  <div class="search-summary"><asp:Literal runat="server" ID="litSummary" /></div>

  <%-- Prompt shown when the box was submitted empty or with a single character. --%>
  <asp:Panel runat="server" ID="pnlPrompt" Visible="false" CssClass="fb-card">
    <div class="empty-note">
      <i class="bi bi-search d-block mb-2" style="font-size:1.4rem"></i>
      Type at least two characters in the search box above.
    </div>
  </asp:Panel>

  <!-- ================= Donations ================= -->
  <asp:Panel runat="server" ID="pnlDonations" Visible="false" CssClass="fb-card mb-4">
    <div style="font-family:'DM Serif Display',serif;font-size:1.05rem;margin-bottom:.4rem">
      Donations <span class="text-muted" style="font-size:.85rem;font-weight:400">(<asp:Literal runat="server" ID="litDonationCount" />)</span>
    </div>
    <div class="text-muted" style="font-size:.76rem;margin-bottom:.8rem">
      Matches on food description, category, quantity, pickup address, city or status.
    </div>

    <asp:Repeater runat="server" ID="rptDonations">
      <ItemTemplate>
        <div class="result-row">
          <div class="result-icon" style='color:<%# StatusColour(Eval("Status")) %>'><i class="bi bi-basket2-fill"></i></div>
          <div class="result-main">
            <div class="result-title"><%# Server.HtmlEncode(Convert.ToString(Eval("FoodDescription"))) %></div>
            <div class="result-meta">
              <%# Server.HtmlEncode(Convert.ToString(Eval("Quantity"))) %>
              · <%# Server.HtmlEncode(Dash(Eval("City"))) %>
              · posted <%# Convert.ToDateTime(Eval("CreatedAt")).ToString("d MMM yyyy") %>
              <%# DonorLine(Eval("DonorName"), Eval("DonorOrg")) %>
            </div>
          </div>
          <div class="d-flex align-items-center gap-2">
            <span class="badge-status <%# StatusBadge(Eval("Status")) %>"><%# Eval("Status") %></span>
            <%# ResultLink(Eval("DonationID"), Eval("Status")) %>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>

    <asp:Panel runat="server" ID="pnlNoDonations" Visible="false">
      <div class="empty-note">No donations matched.</div>
    </asp:Panel>
  </asp:Panel>

  <!-- ================= Users (Admin only) ================= -->
  <asp:Panel runat="server" ID="pnlUsers" Visible="false" CssClass="fb-card">
    <div style="font-family:'DM Serif Display',serif;font-size:1.05rem;margin-bottom:.4rem">
      Users <span class="text-muted" style="font-size:.85rem;font-weight:400">(<asp:Literal runat="server" ID="litUserCount" />)</span>
    </div>
    <div class="text-muted" style="font-size:.76rem;margin-bottom:.8rem">
      Admin only. Matches on name, email, organisation, city or role.
    </div>

    <asp:Repeater runat="server" ID="rptUsers">
      <ItemTemplate>
        <div class="result-row">
          <div class="fb-avatar" style="width:36px;height:36px;font-size:.8rem"><%# Server.HtmlEncode(Initials(Eval("FullName"))) %></div>
          <div class="result-main">
            <div class="result-title"><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></div>
            <div class="result-meta">
              <%# Server.HtmlEncode(Convert.ToString(Eval("Email"))) %>
              · <%# Server.HtmlEncode(Dash(Eval("City"))) %>
              <%# OrgLine(Eval("OrganizationName")) %>
            </div>
          </div>
          <div class="d-flex align-items-center gap-2">
            <span class="badge-status <%# RoleBadge(Eval("Role")) %>"><%# Eval("Role") %></span>
            <span class="badge-status <%# UserStatusBadge(Eval("IsVerified"), Eval("IsActive")) %>"><%# UserStatusText(Eval("IsVerified"), Eval("IsActive")) %></span>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>

    <asp:Panel runat="server" ID="pnlNoUsers" Visible="false">
      <div class="empty-note">No users matched.</div>
    </asp:Panel>
  </asp:Panel>

  <!-- Nothing at all -->
  <asp:Panel runat="server" ID="pnlNothing" Visible="false" CssClass="fb-card">
    <div class="empty-note">
      <i class="bi bi-inbox d-block mb-2" style="font-size:1.4rem"></i>
      Nothing matched <span class="search-term"><asp:Literal runat="server" ID="litNothingTerm" /></span>.
      <div style="margin-top:.4rem;font-size:.8rem"><asp:Literal runat="server" ID="litNothingHint" /></div>
    </div>
  </asp:Panel>

</asp:Content>
