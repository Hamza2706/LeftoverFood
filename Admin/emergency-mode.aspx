<%@ Page Title="Emergency Mode – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="emergency-mode.aspx.cs" Inherits="LeftoverFood.Admin.emergency_mode" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .emergency-banner { background:linear-gradient(135deg,#dc2626,#991b1b); color:#fff; border-radius:var(--radius); padding:1.5rem 2rem; display:flex; align-items:center; gap:1.2rem; }
    .emergency-banner.inactive { background:linear-gradient(135deg,#374151,#1f2937); }
    .pulse { animation:pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
    .mode-toggle { width:64px; height:32px; background:var(--sand-dark); border-radius:50px; position:relative; cursor:pointer; transition:background .3s; border:none; }
    .mode-toggle.on { background:#dc2626; }
    .mode-toggle::after { content:''; position:absolute; width:26px; height:26px; background:#fff; border-radius:50%; top:3px; left:3px; transition:left .3s; }
    .mode-toggle.on::after { left:35px; }
    .priority-card { border-radius:var(--radius); padding:1.4rem; border:2px solid; }
    .priority-high { border-color:#dc2626; background:#fef2f2; }
    .priority-med  { border-color:var(--amber); background:#fff7ed; }
    .priority-low  { border-color:var(--green); background:#f0fdf4; }
    .ramadan-banner { background:linear-gradient(135deg,#0f172a,#1e293b); color:#fff; border-radius:var(--radius); padding:1.5rem; position:relative; overflow:hidden; }
    .ramadan-banner::before { content:'🌙'; position:absolute; right:1.5rem; top:50%; transform:translateY(-50%); font-size:4rem; opacity:.2; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Emergency Mode</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

      <!-- Emergency Status Banner -->
      <div class="emergency-banner inactive mb-4" id="emergencyBanner">
        <div style="width:50px;height:50px;background:rgba(255,255,255,.15);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.5rem;flex-shrink:0">
          <i class="bi bi-shield-exclamation"></i>
        </div>
        <div style="flex:1">
          <div style="font-family:'DM Serif Display',serif;font-size:1.3rem">Emergency Mode — <span id="statusText">INACTIVE</span></div>
          <div style="font-size:.85rem;opacity:.75;margin-top:.2rem" id="statusDesc">System is running normally. Enable Emergency Mode for priority-based distribution.</div>
        </div>
        <div style="text-align:center">
          <button class="mode-toggle" id="emergencyToggle" onclick="toggleEmergency()"></button>
          <div style="font-size:.72rem;opacity:.65;margin-top:.3rem">Click to toggle</div>
        </div>
      </div>

      <div class="row g-4">

        <!-- Left Column -->
        <div class="col-lg-8 d-flex flex-column gap-4">

          <!-- What is Emergency Mode -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-info-circle-fill me-2 text-primary"></i>About Emergency Mode</h6>
            <p style="font-size:.92rem;color:var(--text-muted);line-height:1.8;margin-bottom:1rem">Emergency Mode activates a priority-based food distribution system during high-demand periods such as <strong>natural disasters, Ramadan, floods, or communal crises</strong>. When active:</p>
            <div class="row g-3">
              <div class="col-sm-6">
                <div style="background:var(--cream);border-radius:10px;padding:1rem">
                  <i class="bi bi-lightning-charge-fill text-warning d-block mb-1 fs-5"></i>
                  <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Instant NGO Alerts</div>
                  <div style="font-size:.82rem;color:var(--text-muted)">All NGOs in affected area get immediate SMS + email broadcast</div>
                </div>
              </div>
              <div class="col-sm-6">
                <div style="background:var(--cream);border-radius:10px;padding:1rem">
                  <i class="bi bi-sort-down-alt text-danger d-block mb-1 fs-5"></i>
                  <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Priority Queue</div>
                  <div style="font-size:.82rem;color:var(--text-muted)">Donations auto-sorted by quantity and expiry for faster distribution</div>
                </div>
              </div>
              <div class="col-sm-6">
                <div style="background:var(--cream);border-radius:10px;padding:1rem">
                  <i class="bi bi-clock-fill text-success d-block mb-1 fs-5"></i>
                  <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">48-hr Fast Track</div>
                  <div style="font-size:.82rem;color:var(--text-muted)">Approval time reduced to 15 minutes (from standard 2 hours)</div>
                </div>
              </div>
              <div class="col-sm-6">
                <div style="background:var(--cream);border-radius:10px;padding:1rem">
                  <i class="bi bi-geo-fill text-primary d-block mb-1 fs-5"></i>
                  <div style="font-weight:600;font-size:.88rem;margin-bottom:.3rem">Area Targeting</div>
                  <div style="font-size:.82rem;color:var(--text-muted)">Donations routed specifically to affected zones / camps</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Activate Emergency Form -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-exclamation-triangle-fill me-2 text-danger"></i>Activate Emergency Mode</h6>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>Emergency Type</label>
                  <select class="fb-input fb-select">
                    <option value="">Select type...</option>
                    <option>🌙 Ramadan — High Demand Period</option>
                    <option>🌊 Flood / Natural Disaster</option>
                    <option>🏕️ IDP Camp / Displaced People</option>
                    <option>🔥 Fire / Infrastructure Crisis</option>
                    <option>🫙 Food Shortage Alert</option>
                    <option>⚡ Other Emergency</option>
                  </select>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>Affected City / Area</label>
                  <select class="fb-input fb-select">
                    <option>All Cities</option>
                    <option>Karachi</option><option>Lahore</option><option>Islamabad</option>
                    <option>Peshawar</option><option>Quetta</option><option>Multan</option>
                  </select>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>Start Date & Time</label>
                  <input type="datetime-local" class="fb-input"/>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>Expected Duration</label>
                  <select class="fb-input fb-select">
                    <option>24 Hours</option><option>48 Hours</option><option>1 Week</option>
                    <option>30 Days (Ramadan)</option><option>Until Manually Disabled</option>
                  </select>
                </div>
              </div>
              <div class="col-12">
                <div class="fb-form-group mb-0">
                  <label>Priority Distribution Areas (Specific Locations)</label>
                  <input type="text" class="fb-input" placeholder="e.g. Malir Camp, Orangi Town, Korangi Industrial Area..."/>
                </div>
              </div>
              <div class="col-12">
                <div class="fb-form-group mb-0">
                  <label>Broadcast Message to NGOs & Volunteers</label>
                  <textarea class="fb-input fb-textarea" style="min-height:90px" placeholder="Emergency notice to send to all registered NGOs and volunteers via email/SMS...">⚠️ EMERGENCY ALERT: FoodBridge has activated Emergency Mode. Please check available donations and respond immediately. Faster approvals are now active. Your urgent response is needed.</textarea>
                </div>
              </div>
              <div class="col-12">
                <div class="d-flex gap-2 flex-wrap">
                  <button class="btn-sm-red px-4 py-2" onclick="fbToast('🚨 Emergency Mode ACTIVATED! All NGOs notified.','error')" style="border-radius:8px;font-size:.93rem">
                    <i class="bi bi-exclamation-triangle-fill me-1"></i>Activate Emergency Mode
                  </button>
                  <button class="btn-sm-outline px-4 py-2" style="border-radius:8px" onclick="fbToast('Preview sent to your email.')">Preview Broadcast</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Priority Queue -->
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);background:#fef2f2;display:flex;justify-content:space-between;align-items:center">
              <h6 style="font-family:'DM Serif Display',serif;margin:0;color:#dc2626"><i class="bi bi-exclamation-triangle-fill me-2"></i>Priority Donation Queue</h6>
              <span class="badge-status" style="background:#fee2e2;color:#dc2626">High Priority</span>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Priority</th><th>Donor</th><th>Food</th><th>Qty</th><th>Expires In</th><th>Action</th></tr></thead>
                <tbody>
                  <tr>
                    <td class="ps-3"><span style="background:#fee2e2;color:#dc2626;border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700">🔴 URGENT</span></td>
                    <td><strong>Park View Hall</strong></td><td>Mixed Cuisines</td><td>500 plates</td>
                    <td><strong style="color:#dc2626">48 mins</strong></td>
                    <td><button class="btn-sm-green" onclick="fbToast('Auto-assigned to nearest NGO!')">Auto-Assign</button></td>
                  </tr>
                  <tr>
                    <td class="ps-3"><span style="background:#fff3e0;color:var(--amber);border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700">🟡 HIGH</span></td>
                    <td><strong>Marriott Hotel</strong></td><td>Continental</td><td>150 plates</td>
                    <td><strong style="color:var(--amber)">2h 15m</strong></td>
                    <td><button class="btn-sm-green" onclick="fbToast('Assigned!')">Auto-Assign</button></td>
                  </tr>
                  <tr>
                    <td class="ps-3"><span style="background:#e8f5ee;color:var(--green);border-radius:50px;padding:.2rem .7rem;font-size:.75rem;font-weight:700">🟢 NORMAL</span></td>
                    <td><strong>Ali's Restaurant</strong></td><td>Biryani</td><td>30 plates</td>
                    <td><strong style="color:var(--green)">5h 00m</strong></td>
                    <td><button class="btn-sm-outline" onclick="fbToast('Assigned!')">Assign</button></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

        </div>

        <!-- Right Column -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Ramadan Mode -->
          <div class="ramadan-banner">
            <div style="font-family:'DM Serif Display',serif;font-size:1.2rem;margin-bottom:.5rem">🌙 Ramadan Mode</div>
            <p style="font-size:.85rem;opacity:.8;line-height:1.7;margin-bottom:1rem">Specially configured for Ramadan — prioritizes Iftar and Sehri food donations with extended distribution hours.</p>
            <div class="d-flex flex-column gap-2 mb-3" style="font-size:.82rem;opacity:.75">
              <div><i class="bi bi-check2 me-1"></i>Iftar time window: 5:30 PM – 9:00 PM</div>
              <div><i class="bi bi-check2 me-1"></i>Sehri window: 2:00 AM – 5:00 AM</div>
              <div><i class="bi bi-check2 me-1"></i>Auto-prioritize dates, fruits, drinks</div>
              <div><i class="bi bi-check2 me-1"></i>30-day active period preset</div>
            </div>
            <button class="btn-white px-4" onclick="fbToast('🌙 Ramadan Mode activated for 30 days!')">Activate Ramadan Mode</button>
          </div>

          <!-- Emergency History -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Emergency History</h6>
            <div class="timeline">
              <div class="tl-item">
                <div class="tl-dot" style="background:#dc2626"></div>
                <div class="tl-time">Apr 10 – Apr 11, 2025</div>
                <div class="tl-text"><strong>Flood Alert – Karachi</strong><br><small style="color:var(--text-muted)">1,200 meals distributed in 24hrs</small></div>
              </div>
              <div class="tl-item">
                <div class="tl-dot" style="background:#f59e0b"></div>
                <div class="tl-time">Mar 1 – Mar 30, 2025</div>
                <div class="tl-text"><strong>Ramadan Mode</strong><br><small style="color:var(--text-muted)">8,400 Iftar/Sehri meals served</small></div>
              </div>
              <div class="tl-item">
                <div class="tl-dot" style="background:#dc2626"></div>
                <div class="tl-time">Feb 5, 2025</div>
                <div class="tl-text"><strong>IDP Camp – Quetta</strong><br><small style="color:var(--text-muted)">680 meals emergency distribution</small></div>
              </div>
            </div>
          </div>

          <!-- Quick Broadcast -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem"><i class="bi bi-megaphone-fill me-2 text-danger"></i>Quick Broadcast</h6>
            <div class="fb-form-group">
              <label>Send to</label>
              <select class="fb-input fb-select">
                <option>All NGOs + Volunteers</option>
                <option>NGOs Only</option>
                <option>Volunteers Only</option>
                <option>Donors Only</option>
              </select>
            </div>
            <div class="fb-form-group mb-3">
              <label>Message</label>
              <textarea class="fb-input fb-textarea" style="min-height:80px" placeholder="Type broadcast message..."></textarea>
            </div>
            <div class="d-flex gap-2">
              <button class="btn-sm-red w-100" onclick="fbToast('📢 Broadcast sent to all NGOs & Volunteers!')">Send Broadcast</button>
            </div>
          </div>

        </div>
      </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="AdminFooterScripts" runat="server">
  <script>
  let emergencyActive = false;
  function toggleEmergency() {
    emergencyActive = !emergencyActive;
    const banner = document.getElementById('emergencyBanner');
    const toggle = document.getElementById('emergencyToggle');
    const statusText = document.getElementById('statusText');
    const statusDesc = document.getElementById('statusDesc');
    if (emergencyActive) {
      banner.classList.remove('inactive');
      toggle.classList.add('on');
      statusText.textContent = 'ACTIVE';
      statusDesc.textContent = 'Emergency Mode is ON. Priority distribution is active. All NGOs have been notified.';
      fbToast('🚨 Emergency Mode ACTIVATED!', 'error');
    } else {
      banner.classList.add('inactive');
      toggle.classList.remove('on');
      statusText.textContent = 'INACTIVE';
      statusDesc.textContent = 'System is running normally. Enable Emergency Mode for priority-based distribution.';
      fbToast('Emergency Mode deactivated. System returning to normal.');
    }
  }
  </script>
</asp:Content>
