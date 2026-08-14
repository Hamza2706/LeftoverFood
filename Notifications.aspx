<%@ Page Title="Notifications – FoodBridge" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Notifications.aspx.cs" Inherits="LeftoverFood.NotificationsPage" %>

<%--
  Shared across all four roles.

  This page lives at the app root rather than under Admin/ Donor/ NGO/
  Volunteer/ because every role receives notifications and the list itself is
  identical for all of them — it is always "my own rows, newest first". It uses
  Site.master directly and renders the role sidebar through the shared
  RoleSidebar control, so it still looks native to whichever role is signed in.

  Access is RequireLogin, not RequireRole — see the code-behind. Every query is
  scoped by UserID, so one user can never read or modify another's rows.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
  <style>
    .notif-row { display:flex; align-items:flex-start; gap:.9rem; padding:1rem 1.2rem; border-bottom:1.5px solid var(--sand); transition:var(--transition); }
    .notif-row:last-child { border-bottom:none; }
    .notif-row:hover { background:var(--cream); }
    .notif-row.unread { background:#fbfaf6; }
    .notif-row.unread .notif-msg { font-weight:600; }
    .notif-dot-lg { width:10px; height:10px; border-radius:50%; flex-shrink:0; margin-top:.4rem; }
    .notif-msg { font-size:.88rem; color:var(--text-dark); line-height:1.5; }
    .notif-meta { font-size:.74rem; color:var(--text-muted); margin-top:.25rem; }
    .notif-actions { display:flex; align-items:center; gap:.5rem; flex-shrink:0; }
    .notif-actions a { font-size:.75rem; text-decoration:none; }
    .filter-tab { font-size:.82rem; padding:.35rem .9rem; border-radius:50px; text-decoration:none; color:var(--text-muted); border:1.5px solid transparent; }
    .filter-tab.active { background:var(--green-pale); color:var(--green); border-color:var(--green); font-weight:600; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="SidebarContent" runat="server">
  <fb:RoleSidebar runat="server" ID="roleSidebar" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="PageHeading" runat="server">Notifications</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

  <div class="page-header d-flex justify-content-between align-items-start flex-wrap gap-2">
    <div>
      <h2>Notifications</h2>
      <p class="text-muted mb-0">
        <asp:Literal runat="server" ID="litSummary" />
      </p>
    </div>
    <asp:LinkButton runat="server" ID="btnMarkAll" CssClass="btn-sm-outline"
                    OnClick="btnMarkAll_Click">
      <i class="bi bi-check2-all me-1"></i>Mark all as read
    </asp:LinkButton>
  </div>

  <asp:Panel runat="server" ID="pnlMessage" Visible="false" CssClass="alert alert-success mb-3">
    <asp:Literal runat="server" ID="litMessage" />
  </asp:Panel>

  <div class="d-flex gap-2 mb-3">
    <asp:LinkButton runat="server" ID="btnFilterAll" CssClass="filter-tab"
                    OnClick="btnFilterAll_Click" CausesValidation="false">All</asp:LinkButton>
    <asp:LinkButton runat="server" ID="btnFilterUnread" CssClass="filter-tab"
                    OnClick="btnFilterUnread_Click" CausesValidation="false">Unread</asp:LinkButton>
  </div>

  <div class="fb-card p-0 overflow-hidden">
    <asp:Repeater runat="server" ID="rptNotifications" OnItemCommand="rptNotifications_ItemCommand">
      <ItemTemplate>
        <div class='notif-row <%# Convert.ToBoolean(Eval("IsRead")) ? "" : "unread" %>'>

          <div class="notif-dot-lg" style='background:<%# TypeColor(Eval("Type")) %>'></div>

          <div style="flex:1;min-width:0">
            <div class="notif-msg"><%# Server.HtmlEncode(Convert.ToString(Eval("Message"))) %></div>
            <div class="notif-meta">
              <span class="badge-status <%# TypeBadgeClass(Eval("Type")) %> me-2"><%# Eval("Type") %></span>
              <%# TimeAgo(Eval("CreatedAt")) %>
            </div>
          </div>

          <div class="notif-actions">
            <asp:HyperLink runat="server"
                           NavigateUrl='<%# ResolveLink(Eval("LinkUrl")) %>'
                           Visible='<%# !string.IsNullOrEmpty(Convert.ToString(Eval("LinkUrl"))) %>'
                           CssClass="btn-sm-outline">View</asp:HyperLink>

            <asp:LinkButton runat="server" CommandName="MarkRead"
                            CommandArgument='<%# Eval("NotificationID") %>'
                            Visible='<%# !Convert.ToBoolean(Eval("IsRead")) %>'
                            CssClass="btn-sm-outline"
                            ToolTip="Mark as read"><i class="bi bi-check2"></i></asp:LinkButton>

            <asp:LinkButton runat="server" CommandName="Delete"
                            CommandArgument='<%# Eval("NotificationID") %>'
                            CssClass="btn-sm-red"
                            ToolTip="Delete"
                            OnClientClick="return confirm('Delete this notification?');"><i class="bi bi-trash"></i></asp:LinkButton>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>

    <asp:Panel runat="server" ID="pnlEmpty" Visible="false" CssClass="empty-state">
      <i class="bi bi-bell-slash"></i>
      <p><asp:Literal runat="server" ID="litEmpty" /></p>
    </asp:Panel>
  </div>

</asp:Content>
