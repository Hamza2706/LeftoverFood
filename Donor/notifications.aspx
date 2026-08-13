<%@ Page Title="Notification Settings – FoodBridge" Language="C#" MasterPageFile="~/Donor/DonorMaster.master" AutoEventWireup="true" CodeBehind="notifications.aspx.cs" Inherits="LeftoverFood.Donor.notifications" %>

<asp:Content ID="Content1" ContentPlaceHolderID="DonorHeadContent" runat="server">
  <style>
    .toggle-row { display:flex; justify-content:space-between; align-items:center; padding:.85rem 0; border-bottom:1px solid var(--sand); }
    .toggle-row:last-child { border-bottom:none; }
    .toggle-row .info { flex:1; }
    .toggle-row .info .t-title { font-size:.9rem; font-weight:600; }
    .toggle-row .info .t-desc { font-size:.78rem; color:var(--text-muted); margin-top:.1rem; }
    .toggle-switch { width:44px; height:24px; border-radius:50px; position:relative; cursor:pointer; transition:background .2s; border:none; flex-shrink:0; }
    .toggle-switch.on  { background:var(--green); }
    .toggle-switch.off { background:var(--sand-dark); }
    .toggle-switch::after { content:''; position:absolute; width:18px; height:18px; background:#fff; border-radius:50%; top:3px; transition:left .2s; }
    .toggle-switch.on::after  { left:23px; }
    .toggle-switch.off::after { left:3px; }
    .email-preview { background:#f8fafc; border:1.5px solid var(--sand); border-radius:var(--radius); overflow:hidden; }
    .email-preview-header { background:var(--green); padding:1rem 1.5rem; color:#fff; }
    .email-preview-body { padding:1.5rem; }
    .log-row { display:flex; align-items:center; gap:1rem; padding:.65rem 0; border-bottom:1px solid var(--sand); font-size:.85rem; }
    .log-row:last-child { border-bottom:none; }
    .log-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="DonorPageHeading" runat="server">Email & Notification Settings</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="DonorMainContent" runat="server">

      <div class="page-header">
        <h2>Notification Preferences</h2>
        <p class="text-muted">Manage how and when FoodBridge sends you email and system notifications. Powered by SMTP Email Service.</p>
      </div>

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
              <input type="email" class="fb-input" value="ahmed@restaurant.pk"/>
              <div class="form-hint"><i class="bi bi-check-circle-fill text-success me-1"></i>Verified email address</div>
            </div>

            <div class="toggle-row">
              <div class="info"><div class="t-title">Donation Posted Confirmation</div><div class="t-desc">Receive email when your donation is successfully posted</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Donation Approved by Admin</div><div class="t-desc">Email when admin approves/rejects your donation</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">NGO Accepted Your Donation</div><div class="t-desc">Email when an NGO accepts your food request</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Volunteer Assigned for Pickup</div><div class="t-desc">Email with volunteer details when assigned to your donation</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Food Picked Up Confirmation</div><div class="t-desc">Email when volunteer confirms food pickup</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Delivery Confirmed</div><div class="t-desc">Final email when food is delivered to NGO successfully</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Expiry Warning</div><div class="t-desc">Alert when your posted donation is expiring within 1 hour</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Rating Received</div><div class="t-desc">Email when NGO or volunteer rates your donation</div></div>
              <button class="toggle-switch off ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Monthly Impact Report</div><div class="t-desc">Monthly summary of your donations, meals served, and impact</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Emergency Mode Alerts</div><div class="t-desc">Urgent notifications during emergency or Ramadan mode</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
          </div>

          <!-- System Notifications -->
          <div class="fb-card">
            <div class="d-flex align-items-center gap-2 mb-3">
              <div style="width:36px;height:36px;background:#e8f5ee;border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--green);font-size:1rem"><i class="bi bi-bell-fill"></i></div>
              <h6 style="font-family:'DM Serif Display',serif;margin:0">In-App Notifications</h6>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Real-time Status Updates</div><div class="t-desc">Live updates in dashboard when donation status changes</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">New Messages</div><div class="t-desc">Notify when NGO or admin sends you a message</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
            <div class="toggle-row">
              <div class="info"><div class="t-title">Badge & Achievement Alerts</div><div class="t-desc">Notify when you earn a new trust level or badge</div></div>
              <button class="toggle-switch on ms-3" onclick="this.classList.toggle('on');this.classList.toggle('off')"></button>
            </div>
          </div>

          <button class="btn-green" onclick="fbToast('Notification preferences saved!')"><i class="bi bi-check2 me-1"></i>Save Preferences</button>

        </div>

        <!-- Right Column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Email Preview -->
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Sample Email Preview</h6>
            </div>
            <div class="p-3">
              <div class="email-preview">
                <div class="email-preview-header">
                  <div style="font-family:'DM Serif Display',serif;font-size:1.1rem">🥗 FoodBridge</div>
                  <div style="font-size:.78rem;opacity:.75;margin-top:.2rem">noreply@foodbridge.pk</div>
                </div>
                <div class="email-preview-body">
                  <div style="font-weight:700;font-size:.95rem;margin-bottom:.75rem">✅ Your Donation Has Been Delivered!</div>
                  <p style="font-size:.83rem;color:var(--text-mid);line-height:1.7;margin-bottom:1rem">Dear <%= LeftoverFoodSystem.SessionHelper.GetFullName() %>,</p>
                  <p style="font-size:.83rem;color:var(--text-mid);line-height:1.7;margin-bottom:1rem">Great news! Your donation of <strong>30 plates of Biryani & Naan</strong> has been successfully delivered to <strong>Edhi Foundation</strong> by volunteer Usman Ali.</p>
                  <div style="background:#e8f5ee;border-radius:8px;padding:.75rem;margin-bottom:1rem">
                    <div style="font-size:.8rem;font-weight:700;color:var(--green);margin-bottom:.4rem">Delivery Summary</div>
                    <div style="font-size:.78rem;color:var(--text-mid)">Donation ID: #FB-2025-0047<br>Delivered: Apr 21, 2025 at 6:30 PM<br>Meals Served: ~30 people<br>Volunteer: Usman Ali</div>
                  </div>
                  <p style="font-size:.8rem;color:var(--text-muted);line-height:1.65">Thank you for contributing to reducing food waste and fighting hunger. Your donation made a real difference today. 🌱</p>
                  <div style="margin-top:1rem;text-align:center">
                    <span style="background:var(--green);color:#fff;border-radius:50px;padding:.45rem 1.2rem;font-size:.82rem;font-weight:600;display:inline-block">View Donation Details</span>
                  </div>
                  <div style="margin-top:1rem;padding-top:.8rem;border-top:1px solid var(--sand);font-size:.72rem;color:var(--text-muted);text-align:center">FoodBridge · Karachi, Pakistan<br>To unsubscribe, update your <a href="#" style="color:var(--green)">notification preferences</a></div>
                </div>
              </div>
            </div>
          </div>

          <!-- SMTP Settings (Admin View) -->
          <div class="fb-card" style="border:1.5px dashed var(--sand-dark)">
            <div class="d-flex align-items-center gap-2 mb-3">
              <i class="bi bi-gear-fill text-muted"></i>
              <h6 style="font-family:'DM Serif Display',serif;margin:0;font-size:1rem">SMTP Configuration</h6>
              <span class="badge-status badge-role-admin ms-1">Admin Only</span>
            </div>
            <div class="d-flex flex-column gap-2" style="font-size:.85rem;color:var(--text-muted)">
              <div class="d-flex justify-content-between"><span>SMTP Host</span><strong style="color:var(--text-dark)">smtp.gmail.com</strong></div>
              <div class="d-flex justify-content-between"><span>Port</span><strong style="color:var(--text-dark)">587 (TLS)</strong></div>
              <div class="d-flex justify-content-between"><span>Sender</span><strong style="color:var(--text-dark)">noreply@foodbridge.pk</strong></div>
              <div class="d-flex justify-content-between"><span>Status</span><span class="badge-status badge-active">Connected</span></div>
              <div class="d-flex justify-content-between"><span>Emails sent (April)</span><strong style="color:var(--text-dark)">2,184</strong></div>
            </div>
            <button class="btn-sm-outline w-100 mt-3" onclick="fbToast('Test email sent!')">Send Test Email</button>
          </div>

          <!-- Notification Log -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recent Notifications</h6>
            <div class="d-flex flex-column">
              <div class="log-row"><div class="log-dot" style="background:var(--green)"></div><div style="flex:1"><div style="font-size:.85rem;font-weight:500">Donation delivered — #FB-0047</div><div style="font-size:.75rem;color:var(--text-muted)">Today 6:30 PM · Email sent</div></div></div>
              <div class="log-row"><div class="log-dot" style="background:var(--amber)"></div><div style="flex:1"><div style="font-size:.85rem;font-weight:500">Volunteer Usman assigned</div><div style="font-size:.75rem;color:var(--text-muted)">Today 3:45 PM · Email sent</div></div></div>
              <div class="log-row"><div class="log-dot" style="background:var(--green)"></div><div style="flex:1"><div style="font-size:.85rem;font-weight:500">Edhi Foundation accepted</div><div style="font-size:.75rem;color:var(--text-muted)">Today 3:18 PM · Email sent</div></div></div>
              <div class="log-row"><div class="log-dot" style="background:var(--blue)"></div><div style="flex:1"><div style="font-size:.85rem;font-weight:500">Donation approved by admin</div><div style="font-size:.75rem;color:var(--text-muted)">Today 3:00 PM · Email sent</div></div></div>
              <div class="log-row"><div class="log-dot" style="background:var(--purple)"></div><div style="flex:1"><div style="font-size:.85rem;font-weight:500">🥇 Gold Badge earned!</div><div style="font-size:.75rem;color:var(--text-muted)">Apr 20 · In-app + Email</div></div></div>
            </div>
          </div>

        </div>
      </div>

</asp:Content>
