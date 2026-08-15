<%@ Page Title="Emergency Mode – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="emergency-mode.aspx.cs" Inherits="LeftoverFood.Admin.emergency_mode" %>

<%--
  Phase 6a.

  The mockup this replaces was entirely client-side: a JS toggle that flipped a
  CSS class and showed a toast, three hardcoded donations in the priority queue,
  a hardcoded history timeline, and buttons that called fbToast() and did
  nothing else. Nothing survived a page refresh.

  Several of its promises had no implementation behind them anywhere in the app
  and were removed rather than restyled — see the About panel below and the
  Phase 6a notes in IMPLEMENTATION_ROADMAP.md:

    - "SMS broadcast": there is no SMS provider in this project, and adding one
      means a paid gateway account. Notifications are in-app plus email.
    - "48-hr Fast Track — approval time reduced to 15 minutes (from standard
      2 hours)": there is no approval SLA, no timer, and nothing measuring how
      long an approval takes. The whole card was fiction.
    - "Auto-Assign to nearest NGO": no auto-assignment exists. NGOs claim
      donations themselves (Phase 2) and admins assign volunteers by hand
      (Phase 3). Phase 5 also established that most addresses only geocode to
      city level, so "nearest" is not something this data supports.
    - Ramadan Mode's Iftar/Sehri windows and "auto-prioritize dates, fruits,
      drinks": time-window scheduling needs a scheduler this app does not have.
      It is now what it can honestly be — a preset that fills in the form.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .emergency-banner { background:linear-gradient(135deg,#dc2626,#991b1b); color:#fff; border-radius:var(--radius); padding:1.5rem 2rem; display:flex; align-items:center; gap:1.2rem; flex-wrap:wrap; }
    .emergency-banner.inactive { background:linear-gradient(135deg,#374151,#1f2937); }
    .pulse { animation:pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
    .ramadan-banner { background:linear-gradient(135deg,#0f172a,#1e293b); color:#fff; border-radius:var(--radius); padding:1.5rem; position:relative; overflow:hidden; }
    .ramadan-banner::before { content:'🌙'; position:absolute; right:1.5rem; top:50%; transform:translateY(-50%); font-size:4rem; opacity:.2; }
    .note-inline { font-size:.78rem; color:var(--text-muted); }
    .prio-row.is-priority { background:#fef2f2; }
    .hist-item { border-left:3px solid var(--sand-dark); padding:.1rem 0 .9rem 1rem; margin-left:.3rem; }
    .hist-item.active { border-left-color:#dc2626; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Emergency Mode</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

  <asp:Panel runat="server" ID="pnlMessage" Visible="false" CssClass="alert mb-3">
    <asp:Literal runat="server" ID="litMessage" />
  </asp:Panel>

  <!-- ===================== Status banner ===================== -->

  <asp:Panel runat="server" ID="pnlActive" Visible="false" CssClass="emergency-banner mb-4">
    <div style="width:50px;height:50px;background:rgba(255,255,255,.15);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.5rem;flex-shrink:0">
      <i class="bi bi-shield-exclamation pulse"></i>
    </div>
    <div style="flex:1;min-width:240px">
      <div style="font-family:'DM Serif Display',serif;font-size:1.3rem">Emergency Mode — ACTIVE</div>
      <div style="font-size:.85rem;opacity:.85;margin-top:.2rem"><asp:Literal runat="server" ID="litActiveSummary" /></div>
    </div>
    <div style="text-align:center">
      <asp:LinkButton runat="server" ID="btnDeactivate" CssClass="btn-white px-4"
                      OnClick="btnDeactivate_Click"
                      OnClientClick="return confirm('Deactivate emergency mode? Everyone notified will not be told automatically.');">
        <i class="bi bi-toggle-off me-1"></i>Deactivate
      </asp:LinkButton>
      <div style="font-size:.72rem;opacity:.65;margin-top:.3rem">Ends the active emergency</div>
    </div>
  </asp:Panel>

  <asp:Panel runat="server" ID="pnlInactive" Visible="false" CssClass="emergency-banner inactive mb-4">
    <div style="width:50px;height:50px;background:rgba(255,255,255,.15);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.5rem;flex-shrink:0">
      <i class="bi bi-shield-check"></i>
    </div>
    <div style="flex:1">
      <div style="font-family:'DM Serif Display',serif;font-size:1.3rem">Emergency Mode — INACTIVE</div>
      <div style="font-size:.85rem;opacity:.75;margin-top:.2rem">System is running normally. Activate below to broadcast an alert and start flagging priority donations.</div>
    </div>
  </asp:Panel>

  <div class="row g-4">

    <!-- ===================== Left column ===================== -->
    <div class="col-lg-8 d-flex flex-column gap-4">

      <!-- What Emergency Mode actually does -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-info-circle-fill me-2 text-primary"></i>What Emergency Mode Does</h6>
        <p style="font-size:.92rem;color:var(--text-muted);line-height:1.8;margin-bottom:1rem">
          Emergency Mode is for high-demand periods — <strong>floods, displacement, fires, Ramadan, food shortages</strong>.
          Activating it broadcasts an alert and records the emergency; these four things are what it actually changes:
        </p>
        <div class="row g-3">
          <div class="col-sm-6">
            <div style="background:var(--cream);border-radius:10px;padding:1rem">
              <i class="bi bi-lightning-charge-fill text-warning d-block mb-1 fs-5"></i>
              <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Immediate Alerts</div>
              <div style="font-size:.82rem;color:var(--text-muted)">Every targeted NGO and volunteer gets an in-app notification, plus email if SMTP is configured. <span class="note-inline">No SMS — this project has no SMS gateway.</span></div>
            </div>
          </div>
          <div class="col-sm-6">
            <div style="background:var(--cream);border-radius:10px;padding:1rem">
              <i class="bi bi-sort-down-alt text-danger d-block mb-1 fs-5"></i>
              <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Priority Queue</div>
              <div style="font-size:.82rem;color:var(--text-muted)">Flag donations below; flagged ones sort first on Food Approvals and in every NGO's available-donations list.</div>
            </div>
          </div>
          <div class="col-sm-6">
            <div style="background:var(--cream);border-radius:10px;padding:1rem">
              <i class="bi bi-geo-fill text-primary d-block mb-1 fs-5"></i>
              <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Area Targeting</div>
              <div style="font-size:.82rem;color:var(--text-muted)">The broadcast is filtered by each recipient's registered city. <span class="note-inline">It does not reroute donations — nothing in this app routes.</span></div>
            </div>
          </div>
          <div class="col-sm-6">
            <div style="background:var(--cream);border-radius:10px;padding:1rem">
              <i class="bi bi-journal-text text-success d-block mb-1 fs-5"></i>
              <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Recorded</div>
              <div style="font-size:.82rem;color:var(--text-muted)">Every activation and broadcast is stored with who sent it, when, and how many people it reached.</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Activate -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-exclamation-triangle-fill me-2 text-danger"></i>Activate Emergency Mode</h6>
        <div class="row g-3">

          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Emergency Type <span style="color:var(--red)">*</span></label>
              <asp:DropDownList runat="server" ID="ddlEmergencyType" CssClass="fb-input fb-select">
                <asp:ListItem Value="">Select type...</asp:ListItem>
                <asp:ListItem Value="Ramadan — High Demand Period">🌙 Ramadan — High Demand Period</asp:ListItem>
                <asp:ListItem Value="Flood / Natural Disaster">🌊 Flood / Natural Disaster</asp:ListItem>
                <asp:ListItem Value="IDP Camp / Displaced People">🏕️ IDP Camp / Displaced People</asp:ListItem>
                <asp:ListItem Value="Fire / Infrastructure Crisis">🔥 Fire / Infrastructure Crisis</asp:ListItem>
                <asp:ListItem Value="Food Shortage Alert">🫙 Food Shortage Alert</asp:ListItem>
                <asp:ListItem Value="Other Emergency">⚡ Other Emergency</asp:ListItem>
              </asp:DropDownList>
            </div>
          </div>

          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Affected City / Area</label>
              <asp:DropDownList runat="server" ID="ddlCity" CssClass="fb-input fb-select"
                                AutoPostBack="true" OnSelectedIndexChanged="Audience_Changed">
                <asp:ListItem Value="">All Cities</asp:ListItem>
                <asp:ListItem>Karachi</asp:ListItem><asp:ListItem>Lahore</asp:ListItem><asp:ListItem>Islamabad</asp:ListItem>
                <asp:ListItem>Rawalpindi</asp:ListItem><asp:ListItem>Peshawar</asp:ListItem><asp:ListItem>Quetta</asp:ListItem>
                <asp:ListItem>Multan</asp:ListItem><asp:ListItem>Faisalabad</asp:ListItem>
              </asp:DropDownList>
            </div>
          </div>

          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Start Date &amp; Time <span style="color:var(--red)">*</span></label>
              <asp:TextBox runat="server" ID="txtStartAt" CssClass="fb-input" TextMode="DateTimeLocal" />
            </div>
          </div>

          <div class="col-sm-6">
            <div class="fb-form-group mb-0">
              <label>Expected Duration</label>
              <asp:DropDownList runat="server" ID="ddlDuration" CssClass="fb-input fb-select">
                <asp:ListItem>24 Hours</asp:ListItem><asp:ListItem>48 Hours</asp:ListItem>
                <asp:ListItem>1 Week</asp:ListItem><asp:ListItem>30 Days (Ramadan)</asp:ListItem>
                <asp:ListItem>Until Manually Disabled</asp:ListItem>
              </asp:DropDownList>
              <div class="note-inline mt-1">Recorded for reference. Nothing expires automatically — there is no scheduler, so you end an emergency with the Deactivate button.</div>
            </div>
          </div>

          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label>Priority Distribution Areas (Specific Locations)</label>
              <asp:TextBox runat="server" ID="txtPriorityAreas" CssClass="fb-input" MaxLength="1000"
                           placeholder="e.g. Malir Camp, Orangi Town, Korangi Industrial Area..." />
              <div class="note-inline mt-1">Included in the broadcast text so recipients can read it. Not used for filtering.</div>
            </div>
          </div>

          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label>Who to notify</label>
              <asp:DropDownList runat="server" ID="ddlAudience" CssClass="fb-input fb-select"
                                AutoPostBack="true" OnSelectedIndexChanged="Audience_Changed">
                <asp:ListItem Value="Both">All NGOs + Volunteers</asp:ListItem>
                <asp:ListItem Value="NGOs">NGOs Only</asp:ListItem>
                <asp:ListItem Value="Volunteers">Volunteers Only</asp:ListItem>
                <asp:ListItem Value="All">Everyone (incl. Donors)</asp:ListItem>
              </asp:DropDownList>
            </div>
          </div>

          <div class="col-12">
            <asp:Panel runat="server" ID="pnlUnknownCity" Visible="false"
                       style="background:var(--cream);border-radius:10px;padding:.8rem 1rem">
              <asp:CheckBox runat="server" ID="chkIncludeUnknownCity" Checked="true"
                            AutoPostBack="true" OnCheckedChanged="Audience_Changed"
                            Text="&nbsp;Also notify users with no city on record" />
              <div class="note-inline mt-1"><asp:Literal runat="server" ID="litUnknownCityNote" /></div>
            </asp:Panel>
          </div>

          <div class="col-12">
            <div class="fb-form-group mb-0">
              <label>Broadcast Message <span style="color:var(--red)">*</span></label>
              <asp:TextBox runat="server" ID="txtMessage" TextMode="MultiLine" CssClass="fb-input fb-textarea"
                           style="min-height:90px" MaxLength="1000" />
            </div>
          </div>

          <div class="col-12">
            <div style="background:var(--cream);border-radius:10px;padding:.9rem 1.1rem">
              <div style="font-size:.88rem"><i class="bi bi-people-fill me-2"></i><asp:Literal runat="server" ID="litRecipientCount" /></div>
              <asp:Literal runat="server" ID="litSmtpWarning" />
            </div>
          </div>

          <div class="col-12">
            <div class="d-flex gap-2 flex-wrap">
              <asp:LinkButton runat="server" ID="btnActivate" CssClass="btn-sm-red px-4 py-2"
                              style="border-radius:8px;font-size:.93rem"
                              OnClick="btnActivate_Click"
                              OnClientClick="return confirm('Activate emergency mode and send this broadcast now?');">
                <i class="bi bi-exclamation-triangle-fill me-1"></i>Activate &amp; Broadcast
              </asp:LinkButton>
              <asp:LinkButton runat="server" ID="btnPreview" CssClass="btn-sm-outline px-4 py-2"
                              style="border-radius:8px" OnClick="btnPreview_Click">Preview Broadcast</asp:LinkButton>
            </div>
          </div>

          <div class="col-12">
            <asp:Panel runat="server" ID="pnlPreview" Visible="false"
                       style="border:1.5px dashed var(--sand-dark);border-radius:10px;padding:1rem 1.2rem">
              <div class="note-inline mb-2"><i class="bi bi-eye me-1"></i>This is exactly what recipients will see — rendered through the same template the app really sends.</div>
              <asp:Literal runat="server" ID="litPreview" />
            </asp:Panel>
          </div>

        </div>
      </div>

      <!-- Priority queue -->
      <div class="fb-card p-0 overflow-hidden">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);background:#fef2f2;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.5rem">
          <h6 style="font-family:'DM Serif Display',serif;margin:0;color:#dc2626"><i class="bi bi-exclamation-triangle-fill me-2"></i>Priority Donation Queue</h6>
          <span class="note-inline">In-flight donations, flagged ones first, then soonest to expire</span>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Priority</th><th>Donor</th><th>Food</th><th>Qty</th><th>Expires In</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
              <asp:Repeater runat="server" ID="rptPriority" OnItemCommand="rptPriority_ItemCommand">
                <ItemTemplate>
                  <tr class='prio-row <%# Convert.ToBoolean(Eval("IsPriority")) ? "is-priority" : "" %>'>
                    <td class="ps-3"><%# PriorityBadge(Eval("IsPriority"), Eval("ExpiryTime")) %></td>
                    <td><strong><%# Server.HtmlEncode(Convert.ToString(Eval("DonorName"))) %></strong><div class="note-inline"><%# Server.HtmlEncode(Convert.ToString(Eval("City"))) %></div></td>
                    <td><%# Server.HtmlEncode(Truncate(Eval("FoodDescription"), 34)) %></td>
                    <td><%# Server.HtmlEncode(Convert.ToString(Eval("Quantity"))) %></td>
                    <td><%# ExpiresIn(Eval("ExpiryTime")) %></td>
                    <td><span class="badge-status <%# StatusBadgeClass(Eval("Status")) %>"><%# Eval("Status") %></span></td>
                    <td>
                      <asp:LinkButton runat="server" CommandName="TogglePriority"
                                      CommandArgument='<%# Eval("DonationID") %>'
                                      CssClass='<%# Convert.ToBoolean(Eval("IsPriority")) ? "btn-sm-outline" : "btn-sm-red" %>'>
                        <%# Convert.ToBoolean(Eval("IsPriority")) ? "Unflag" : "Flag" %>
                      </asp:LinkButton>
                    </td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
        </div>
        <asp:Panel runat="server" ID="pnlNoPriority" Visible="false" CssClass="empty-state" style="padding:2.5rem 1rem">
          <i class="bi bi-inbox"></i>
          <p>No donations are in flight right now. Posted, approved, requested and assigned donations appear here.</p>
        </asp:Panel>
      </div>

    </div>

    <!-- ===================== Right column ===================== -->
    <div class="col-lg-4 d-flex flex-column gap-4">

      <!-- Ramadan preset -->
      <div class="ramadan-banner">
        <div style="font-family:'DM Serif Display',serif;font-size:1.2rem;margin-bottom:.5rem">🌙 Ramadan Preset</div>
        <p style="font-size:.85rem;opacity:.8;line-height:1.7;margin-bottom:1rem">
          Fills the activation form with a 30-day Ramadan emergency and a suggested message. You still review and send it yourself.
        </p>
        <div style="font-size:.78rem;opacity:.6;line-height:1.6;margin-bottom:1rem">
          Iftar/Sehri time windows and auto-prioritising dates and drinks aren't implemented — scheduling by time of day needs a background scheduler this app doesn't have.
        </div>
        <asp:LinkButton runat="server" ID="btnRamadanPreset" CssClass="btn-white px-4"
                        OnClick="btnRamadanPreset_Click">Use Ramadan Preset</asp:LinkButton>
      </div>

      <!-- History -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Emergency History</h6>
        <asp:Repeater runat="server" ID="rptHistory">
          <ItemTemplate>
            <div class='hist-item <%# Convert.ToBoolean(Eval("IsActive")) ? "active" : "" %>'>
              <div class="note-inline"><%# DateRange(Eval("StartDateTime"), Eval("EndedAt"), Eval("IsActive")) %></div>
              <div style="font-size:.9rem;font-weight:600;margin:.15rem 0">
                <%# Server.HtmlEncode(Convert.ToString(Eval("EmergencyType"))) %>
                <%# AreaSuffix(Eval("AffectedArea")) %>
                <%# Convert.ToBoolean(Eval("IsActive")) ? "<span class=\"badge-status badge-rejected ms-1\">Active</span>" : "" %>
              </div>
              <div class="note-inline">
                <%# RecipientText(Eval("RecipientCount")) %> · <%# Server.HtmlEncode(Convert.ToString(Eval("SendTo"))) %> · by <%# Server.HtmlEncode(Convert.ToString(Eval("CreatedByName"))) %>
              </div>
            </div>
          </ItemTemplate>
        </asp:Repeater>
        <asp:Panel runat="server" ID="pnlNoHistory" Visible="false" CssClass="note-inline">
          No emergencies have been declared yet.
        </asp:Panel>
      </div>

      <!-- Quick broadcast -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem"><i class="bi bi-megaphone-fill me-2 text-danger"></i>Quick Broadcast</h6>
        <div class="note-inline mb-2">Sends a message without declaring an emergency. Still recorded in history.</div>
        <div class="fb-form-group">
          <label>Send to</label>
          <asp:DropDownList runat="server" ID="ddlQuickAudience" CssClass="fb-input fb-select">
            <asp:ListItem Value="Both">All NGOs + Volunteers</asp:ListItem>
            <asp:ListItem Value="NGOs">NGOs Only</asp:ListItem>
            <asp:ListItem Value="Volunteers">Volunteers Only</asp:ListItem>
            <asp:ListItem Value="Donors">Donors Only</asp:ListItem>
          </asp:DropDownList>
        </div>
        <div class="fb-form-group mb-3">
          <label>Message</label>
          <asp:TextBox runat="server" ID="txtQuickMessage" TextMode="MultiLine" CssClass="fb-input fb-textarea"
                       style="min-height:80px" MaxLength="1000" placeholder="Type broadcast message..." />
        </div>
        <asp:LinkButton runat="server" ID="btnQuickSend" CssClass="btn-sm-red w-100 d-block text-center py-2"
                        style="border-radius:8px" OnClick="btnQuickSend_Click"
                        OnClientClick="return confirm('Send this broadcast now?');">Send Broadcast</asp:LinkButton>
      </div>

    </div>
  </div>

</asp:Content>
