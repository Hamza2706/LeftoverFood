<%@ Page Title="Notification Settings – FoodBridge" Language="C#" MasterPageFile="~/Donor/DonorMaster.master" AutoEventWireup="true" CodeBehind="notifications.aspx.cs" Inherits="LeftoverFood.Donor.notifications" %>

<%--
  Phase 4.

  This page is the notification *settings* page — the list of actual
  notifications lives at ~/Notifications.aspx and is shared by all four roles.

  Every toggle below now persists to NotificationPreferences. Toggles whose
  underlying feature does not exist yet are marked "Not active yet" rather than
  silently doing nothing: the preference is still stored, so it will take effect
  as soon as the feature that raises that event is built.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="DonorHeadContent" runat="server">
  <style>
    .toggle-row { display:flex; justify-content:space-between; align-items:center; padding:.85rem 0; border-bottom:1px solid var(--sand); }
    .toggle-row:last-child { border-bottom:none; }
    .toggle-row .info { flex:1; }
    .toggle-row .info .t-title { font-size:.9rem; font-weight:600; }
    .toggle-row .info .t-desc { font-size:.78rem; color:var(--text-muted); margin-top:.1rem; }

    /* The mockup styled a <button> as the switch. These are real
       asp:CheckBox controls now, so the same look is applied to the rendered
       <input type="checkbox"> instead. */
    .toggle-switch input[type=checkbox] { -webkit-appearance:none; appearance:none; width:44px; height:24px; border-radius:50px; background:var(--sand-dark); position:relative; cursor:pointer; transition:background .2s; border:none; flex-shrink:0; margin:0; }
    .toggle-switch input[type=checkbox]:checked { background:var(--green); }
    .toggle-switch input[type=checkbox]::after { content:''; position:absolute; width:18px; height:18px; background:#fff; border-radius:50%; top:3px; left:3px; transition:left .2s; }
    .toggle-switch input[type=checkbox]:checked::after { left:23px; }
    .toggle-switch { margin-left:1rem; display:flex; align-items:center; }

    .tag-inactive { font-size:.65rem; font-weight:600; text-transform:uppercase; letter-spacing:.03em; color:var(--text-muted); background:var(--sand); border-radius:50px; padding:.1rem .5rem; margin-left:.4rem; vertical-align:middle; }
    .email-preview { background:#f8fafc; border:1.5px solid var(--sand); border-radius:var(--radius); overflow:hidden; }
    .email-preview-body { padding:1rem; }
    .log-row { display:flex; align-items:center; gap:1rem; padding:.65rem 0; border-bottom:1px solid var(--sand); font-size:.85rem; }
    .log-row:last-child { border-bottom:none; }
    .log-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="DonorPageHeading" runat="server">Email &amp; Notification Settings</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="DonorMainContent" runat="server">

      <div class="page-header">
        <h2>Notification Preferences</h2>
        <p class="text-muted">Choose which events send you an email. Every event still appears in your
          <a href="<%= ResolveUrl("~/Notifications.aspx") %>">in-app notifications</a> unless you turn that off below.</p>
      </div>

      <asp:Panel runat="server" ID="pnlMessage" Visible="false">
        <asp:Label runat="server" ID="lblMessage" CssClass="alert alert-success" />
      </asp:Panel>

      <div class="row g-4">

        <!-- Left Column -->
        <div class="col-lg-7 d-flex flex-column gap-4">

          <!-- Email Notifications -->
          <div class="fb-card">
            <div class="d-flex align-items-center gap-2 mb-3">
              <div style="width:36px;height:36px;background:#e0f2fe;border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--blue);font-size:1rem"><i class="bi bi-envelope-fill"></i></div>
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Email Notifications</h6>
            </div>

            <div class="fb-form-group mb-3">
              <label>Email Address</label>
              <asp:TextBox runat="server" ID="txtEmail" CssClass="fb-input" ReadOnly="true" />
              <div class="form-hint">
                <i class="bi bi-info-circle me-1"></i>This is the address on your account. Change it from
                <a href="<%= ResolveUrl("~/Donor/profile.aspx") %>">My Profile</a>.
              </div>
            </div>

            <div class="toggle-row">
              <div class="info"><div class="t-title">Donation Posted Confirmation</div><div class="t-desc">Receive email when your donation is successfully posted</div></div>
              <asp:CheckBox runat="server" ID="chkEmailDonationPosted" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Donation Approved by Admin</div><div class="t-desc">Email when admin approves or rejects your donation</div></div>
              <asp:CheckBox runat="server" ID="chkEmailDonationApproved" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">NGO Accepted Your Donation</div><div class="t-desc">Email when an NGO accepts your food donation</div></div>
              <asp:CheckBox runat="server" ID="chkEmailNgoAccepted" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Volunteer Assigned for Pickup</div><div class="t-desc">Email when a volunteer is assigned to your donation</div></div>
              <asp:CheckBox runat="server" ID="chkEmailVolunteerAssigned" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Food Picked Up Confirmation</div><div class="t-desc">Email when the volunteer confirms pickup</div></div>
              <asp:CheckBox runat="server" ID="chkEmailFoodPickedUp" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Delivery Confirmed</div><div class="t-desc">Final email when food is delivered and the NGO confirms receipt</div></div>
              <asp:CheckBox runat="server" ID="chkEmailDeliveryConfirmed" CssClass="toggle-switch" />
            </div>

            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Expiry Warning <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Alert when a posted donation is close to expiring — needs a scheduled job, which this app doesn't have yet</div>
              </div>
              <asp:CheckBox runat="server" ID="chkEmailExpiryWarning" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Rating Received <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Email when an NGO or volunteer rates your donation — arrives with the ratings feature (Phase 6c)</div>
              </div>
              <asp:CheckBox runat="server" ID="chkEmailRatingReceived" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Monthly Impact Report <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Monthly summary of your donations and meals served — needs a scheduled job</div>
              </div>
              <asp:CheckBox runat="server" ID="chkEmailMonthlyImpact" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Emergency Mode Alerts <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Urgent alerts during an emergency broadcast — arrives with Emergency Mode (Phase 6a)</div>
              </div>
              <asp:CheckBox runat="server" ID="chkEmailEmergencyAlert" CssClass="toggle-switch" />
            </div>
          </div>

          <!-- In-App Notifications -->
          <div class="fb-card">
            <div class="d-flex align-items-center gap-2 mb-3">
              <div style="width:36px;height:36px;background:#e8f5ee;border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--green);font-size:1rem"><i class="bi bi-bell-fill"></i></div>
              <h6 style="font-family:'DM Serif Display',serif;margin:0">In-App Notifications</h6>
            </div>

            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Donation Status Updates</div>
                <div class="t-desc">Show approval, pickup and delivery updates in your notifications list and bell badge</div>
              </div>
              <asp:CheckBox runat="server" ID="chkInAppStatusUpdates" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info">
                <div class="t-title">New Messages <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Notify when an NGO or admin messages you — there is no messaging feature yet</div>
              </div>
              <asp:CheckBox runat="server" ID="chkInAppNewMessages" CssClass="toggle-switch" />
            </div>
            <div class="toggle-row">
              <div class="info">
                <div class="t-title">Badge &amp; Achievement Alerts <span class="tag-inactive">Not active yet</span></div>
                <div class="t-desc">Notify when you earn a new trust level or badge — there is no badge feature yet</div>
              </div>
              <asp:CheckBox runat="server" ID="chkInAppBadgeAlerts" CssClass="toggle-switch" />
            </div>
          </div>

          <asp:Button runat="server" ID="btnSave" CssClass="btn-green" Text="Save Preferences" OnClick="btnSave_Click" />

        </div>

        <!-- Right Column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Email Preview -->
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Sample Email Preview</h6>
              <div style="font-size:.75rem;color:var(--text-muted);margin-top:.15rem">Rendered with the real email template</div>
            </div>
            <div class="p-3">
              <div class="email-preview">
                <div class="email-preview-body">
                  <asp:Literal runat="server" ID="litEmailPreview" />
                </div>
              </div>
            </div>
          </div>

          <!-- SMTP status -->
          <div class="fb-card" style="border:1.5px dashed var(--sand-dark)">
            <div class="d-flex align-items-center gap-2 mb-3">
              <i class="bi bi-gear-fill text-muted"></i>
              <h6 style="font-family:'DM Serif Display',serif;margin:0;font-size:1rem">Email Delivery</h6>
            </div>
            <div class="d-flex flex-column gap-2" style="font-size:.85rem;color:var(--text-muted)">
              <div class="d-flex justify-content-between"><span>SMTP Host</span><strong style="color:var(--text-dark)"><asp:Literal runat="server" ID="litSmtpHost" /></strong></div>
              <div class="d-flex justify-content-between"><span>Port</span><strong style="color:var(--text-dark)"><asp:Literal runat="server" ID="litSmtpPort" /></strong></div>
              <div class="d-flex justify-content-between"><span>Sender</span><strong style="color:var(--text-dark)"><asp:Literal runat="server" ID="litSmtpFrom" /></strong></div>
              <div class="d-flex justify-content-between"><span>Status</span><asp:Literal runat="server" ID="litSmtpStatus" /></div>
            </div>
            <asp:Button runat="server" ID="btnTestEmail" CssClass="btn-sm-outline w-100 mt-3"
                        Text="Send Test Email" OnClick="btnTestEmail_Click" />
            <div style="font-size:.72rem;color:var(--text-muted);margin-top:.5rem">
              Sends a test message to your own address so you can confirm delivery works.
            </div>
          </div>

          <!-- Recent notifications -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Recent Notifications</h6>
              <a href="<%= ResolveUrl("~/Notifications.aspx") %>" style="font-size:.78rem">View all</a>
            </div>
            <div class="d-flex flex-column">
              <asp:Repeater runat="server" ID="rptRecent">
                <ItemTemplate>
                  <div class="log-row">
                    <div class="log-dot" style='background:<%# TypeColor(Eval("Type")) %>'></div>
                    <div style="flex:1;min-width:0">
                      <div style="font-size:.85rem;font-weight:500"><%# Server.HtmlEncode(Convert.ToString(Eval("Message"))) %></div>
                      <div style="font-size:.75rem;color:var(--text-muted)"><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("dd MMM, h:mm tt") %></div>
                    </div>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
              <asp:Panel runat="server" ID="pnlNoRecent" Visible="false" style="font-size:.85rem;color:var(--text-muted);padding:.5rem 0">
                Nothing yet — notifications will appear here as your donations progress.
              </asp:Panel>
            </div>
          </div>

        </div>
      </div>

</asp:Content>
