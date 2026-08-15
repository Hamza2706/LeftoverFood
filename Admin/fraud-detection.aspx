<%@ Page Title="Fraud Detection – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="fraud-detection.aspx.cs" Inherits="LeftoverFood.Admin.fraud_detection" %>

<%--
  Phase 6b.

  The mockup this replaces named three hardcoded suspicious accounts
  ("user_4427", "Ghost Restaurant – Fast Bites", "Hamid Bakery"), three
  hardcoded suspicious donations, and buttons that called fbToast(). It also
  advertised six detection rules and a nightly scan, none of which existed.

  Two of those six rules had nothing behind them anywhere in the app and are
  gone rather than restyled:

    - "Unverified Contact — flags accounts without phone verification": there
      is no phone verification in this project. Users.Phone is a free-text
      field captured at registration and never checked, so every account would
      qualify and the flag would mean nothing.
    - "NGO Reports — auto-flags after 2 NGO complaints": there is no complaint
      feature. An NGO can record what it received at Confirm Receipt, which is
      what the Quantity Mismatch rule below uses, but it cannot file a
      complaint against a donor.

  The "Auto daily scan at 2:00 AM" and its frequency selector are also gone:
  this app is purely request-driven and has no background job host — the same
  constraint that left ExpiryWarning dormant in Phase 4 and removed the Ramadan
  time windows in 6a. Scanning is a button you press, and it says so.

  "Auto-suspend high risk" was removed on purpose rather than for lack of
  plumbing. The roadmap's own risk note says never auto-block, because the
  expected shape of this data — a restaurant posting the same meal from the
  same address every evening — is indistinguishable from the pattern the rules
  look for. A human decides.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .risk-high   { background:#fee2e2;border-left:4px solid #dc2626; }
    .risk-med    { background:#fff3e0;border-left:4px solid var(--amber); }
    .flag-badge  { display:inline-block;background:#fee2e2;color:#dc2626;font-size:.72rem;font-weight:700;border-radius:50px;padding:.18rem .65rem; }
    .flag-badge.amber { background:#fff3e0;color:#92400e; }
    .flag-badge.grey  { background:var(--sand);color:var(--text-muted); }
    .fraud-stat  { background:var(--white);border-radius:var(--radius);border:1.5px solid var(--sand);padding:1.2rem; }
    .rule-card   { background:var(--cream);border-radius:10px;padding:1rem 1.2rem;border:1.5px solid var(--sand);display:flex;align-items:flex-start;gap:.9rem; }
    .rule-icon   { width:36px;height:36px;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:1rem; }
    .note-inline { font-size:.78rem;color:var(--text-muted); }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Duplicate &amp; Fake Donor Detection</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

  <asp:Panel runat="server" ID="pnlMessage" Visible="false" CssClass="alert mb-3">
    <asp:Literal runat="server" ID="litMessage" />
  </asp:Panel>

  <!-- Scan banner -->
  <div style="background:var(--cream);border:1.5px solid var(--sand);border-radius:var(--radius);padding:1rem 1.4rem;display:flex;align-items:center;gap:1rem;margin-bottom:1.5rem;flex-wrap:wrap">
    <i class="bi bi-shield-exclamation" style="font-size:1.4rem;color:#dc2626;flex-shrink:0"></i>
    <div style="flex:1;min-width:240px">
      <strong><asp:Literal runat="server" ID="litScanHeadline" /></strong>
      <div class="note-inline mt-1">
        Rules run automatically whenever a donation is posted, cancelled or received.
        There is no scheduled scan — this app has no background job host — so use the button to re-check existing history.
      </div>
    </div>
    <asp:LinkButton runat="server" ID="btnRunScan" CssClass="btn-sm-red" OnClick="btnRunScan_Click">
      <i class="bi bi-arrow-repeat me-1"></i>Run scan now
    </asp:LinkButton>
  </div>

  <!-- Stats -->
  <div class="row g-3 mb-4">
    <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:#dc2626"><asp:Literal runat="server" ID="litOpenCount" /></div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Open Flags</div></div></div>
    <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--amber)"><asp:Literal runat="server" ID="litFlaggedUsers" /></div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Accounts Flagged</div></div></div>
    <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--green)"><asp:Literal runat="server" ID="litCleanCount" /></div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">No Open Flags</div></div></div>
    <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--blue)"><asp:Literal runat="server" ID="litSuspendedCount" /></div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Suspended</div></div></div>
  </div>

  <div class="row g-4">

    <!-- ===================== Flags ===================== -->
    <div class="col-lg-8">
      <div class="fb-card p-0 overflow-hidden mb-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);background:#fff5f5;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.5rem">
          <h6 style="font-family:'DM Serif Display',serif;margin:0;color:#dc2626"><i class="bi bi-shield-exclamation me-2"></i>Open Flags</h6>
          <asp:DropDownList runat="server" ID="ddlFlagFilter" CssClass="fb-input fb-select"
                            style="width:auto;font-size:.83rem;padding:.35rem .8rem;border-radius:50px"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlFlagFilter_SelectedIndexChanged">
            <asp:ListItem Text="Open" Value="Open" />
            <asp:ListItem Text="Reviewed" Value="Reviewed" />
            <asp:ListItem Text="Dismissed" Value="Dismissed" />
            <asp:ListItem Text="All" Value="all" />
          </asp:DropDownList>
        </div>

        <asp:Repeater runat="server" ID="rptFlags" OnItemCommand="rptFlags_ItemCommand">
          <ItemTemplate>
            <div style="padding:1.2rem;border-bottom:1.5px solid var(--sand)" class='<%# RiskClass(Eval("FlagType")) %>'>
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
                <div style="min-width:220px">
                  <div style="font-weight:700;font-size:.95rem">
                    <%# Server.HtmlEncode(Convert.ToString(Eval("SubjectName"))) %>
                    <span class="badge-status <%# RoleBadgeClass(Eval("SubjectRole")) %> ms-1"><%# Eval("SubjectRole") %></span>
                    <%# SuspendedBadge(Eval("SubjectActive")) %>
                  </div>
                  <div class="note-inline mt-1">
                    <%# FlaggedAgo(Eval("FlaggedAt")) %>
                    <%# ReviewedNote(Eval("Status"), Eval("ReviewedAt"), Eval("ReviewedByName")) %>
                  </div>
                </div>

                <asp:PlaceHolder runat="server" Visible='<%# Convert.ToString(Eval("Status")) == "Open" %>'>
                  <div class="d-flex gap-2 flex-wrap">
                    <asp:LinkButton runat="server" CommandName="Suspend" CommandArgument='<%# Eval("FlagID") %>'
                                    CssClass="btn-sm-red"
                                    Visible='<%# Eval("UserID") != DBNull.Value && Convert.ToBoolean(Eval("SubjectActive")) %>'
                                    OnClientClick="return confirm('Suspend this account? They will not be able to sign in until reinstated.');">Suspend</asp:LinkButton>
                    <asp:LinkButton runat="server" CommandName="Reviewed" CommandArgument='<%# Eval("FlagID") %>'
                                    CssClass="btn-sm-outline">Mark Reviewed</asp:LinkButton>
                    <asp:LinkButton runat="server" CommandName="Dismiss" CommandArgument='<%# Eval("FlagID") %>'
                                    CssClass="btn-sm-outline">Dismiss</asp:LinkButton>
                  </div>
                </asp:PlaceHolder>
              </div>

              <div class="d-flex flex-wrap gap-2 align-items-center">
                <span class='flag-badge <%# BadgeTone(Eval("FlagType")) %>'>🚩 <%# Server.HtmlEncode(LeftoverFoodSystem.FraudDetectionService.Humanise(Convert.ToString(Eval("FlagType")))) %></span>
                <span style="font-size:.85rem"><%# Server.HtmlEncode(Convert.ToString(Eval("Details"))) %></span>
              </div>

              <asp:HyperLink runat="server" CssClass="note-inline"
                             Visible='<%# Eval("DonationID") != DBNull.Value %>'
                             NavigateUrl='<%# "~/Admin/food-approvals.aspx" %>'>
                <div class="mt-2">Donation #<%# Eval("DonationID") %> — <%# Server.HtmlEncode(Truncate(Eval("DonationFood"), 45)) %></div>
              </asp:HyperLink>
            </div>
          </ItemTemplate>
        </asp:Repeater>

        <asp:Panel runat="server" ID="pnlNoFlags" Visible="false" CssClass="empty-state" style="padding:3rem 1rem">
          <i class="bi bi-shield-check"></i>
          <p><asp:Literal runat="server" ID="litNoFlags" /></p>
        </asp:Panel>
      </div>

      <!-- Suspicious donations log -->
      <div class="fb-card p-0 overflow-hidden">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Claimed vs Received</h6>
          <div class="note-inline mt-1">Every delivered donation where the receiving NGO recorded a quantity, newest first.</div>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Donation</th><th>Donor</th><th>Claimed</th><th>NGO Recorded</th><th>Location</th><th>Check</th></tr></thead>
            <tbody>
              <asp:Repeater runat="server" ID="rptDonationLog">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3">#<%# Eval("DonationID") %><div class="note-inline"><%# Server.HtmlEncode(Truncate(Eval("FoodDescription"), 24)) %></div></td>
                    <td><%# Server.HtmlEncode(Convert.ToString(Eval("DonorName"))) %></td>
                    <td><%# Server.HtmlEncode(Convert.ToString(Eval("Quantity"))) %><div class="note-inline"><%# ServingsText(Eval("Servings")) %></div></td>
                    <td><%# Server.HtmlEncode(Convert.ToString(Eval("ActualQuantityReceived"))) %></td>
                    <td><%# GeoBadge(Eval("GeoPrecision")) %></td>
                    <td><%# MismatchBadge(Eval("Servings"), Eval("ActualQuantityReceived")) %></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
        </div>
        <asp:Panel runat="server" ID="pnlNoLog" Visible="false" CssClass="empty-state" style="padding:2.5rem 1rem">
          <i class="bi bi-clipboard-x"></i>
          <p>No NGO has recorded a received quantity yet. This log fills as deliveries are confirmed.</p>
        </asp:Panel>
      </div>
    </div>

    <!-- ===================== Right column ===================== -->
    <div class="col-lg-4 d-flex flex-column gap-4">

      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.4rem">Detection Rules</h6>
        <p class="note-inline mb-3">All five run automatically on the actions that could trigger them. None of them blocks anyone — every rule ends in this queue.</p>
        <div class="d-flex flex-column gap-2">

          <div class="rule-card">
            <div class="rule-icon" style="background:#fee2e2;color:#dc2626"><i class="bi bi-files"></i></div>
            <div><div style="font-size:.87rem;font-weight:600">Duplicate Donation</div><div style="font-size:.78rem;color:var(--text-muted)">Same donor, same pickup address and category, within 6 hours</div></div>
          </div>

          <div class="rule-card">
            <div class="rule-icon" style="background:#fff3e0;color:var(--amber)"><i class="bi bi-clock-fill"></i></div>
            <div><div style="font-size:.87rem;font-weight:600">Rapid Posting</div><div style="font-size:.78rem;color:var(--text-muted)">3 or more donations posted by one donor within an hour</div></div>
          </div>

          <div class="rule-card">
            <div class="rule-icon" style="background:#fee2e2;color:#dc2626"><i class="bi bi-x-circle-fill"></i></div>
            <div><div style="font-size:.87rem;font-weight:600">Repeat Cancellations</div><div style="font-size:.78rem;color:var(--text-muted)">A donor with 3 or more cancelled donations. <span class="note-inline">Donors only — NGOs and volunteers have no cancel action to count.</span></div></div>
          </div>

          <div class="rule-card">
            <div class="rule-icon" style="background:#e0f2fe;color:var(--blue)"><i class="bi bi-bar-chart-fill"></i></div>
            <div><div style="font-size:.87rem;font-weight:600">Quantity Mismatch</div><div style="font-size:.78rem;color:var(--text-muted)">NGO records under half the claimed servings. <span class="note-inline">Quantities are free text, so only the leading number is compared and units are ignored.</span></div></div>
          </div>

          <div class="rule-card">
            <div class="rule-icon" style="background:#f3e8ff;color:var(--purple)"><i class="bi bi-geo-alt-fill"></i></div>
            <div><div style="font-size:.87rem;font-weight:600">Unverifiable Location</div><div style="font-size:.78rem;color:var(--text-muted)">Pickup address did not geocode at all. <span class="note-inline">City-level matches are normal here and are not flagged.</span></div></div>
          </div>

        </div>
      </div>

      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.6rem">How this queue behaves</h6>
        <div style="font-size:.83rem;color:var(--text-muted);line-height:1.7">
          <p class="mb-2"><strong>Nothing is blocked automatically.</strong> A legitimate restaurant donating the same meal from the same address every evening looks exactly like the pattern these rules search for, so every finding waits for you.</p>
          <p class="mb-2"><strong>An open flag is not repeated.</strong> Account-level rules stay true on the donor's next action, so the same finding is suppressed while it is open.</p>
          <p class="mb-0"><strong>Reviewing re-arms it.</strong> Once you mark a flag Reviewed or Dismissed, the same pattern recurring later raises a fresh one.</p>
        </div>
      </div>

    </div>
  </div>

</asp:Content>
