<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="fraud-detection.aspx.cs" Inherits="LeftoverFood.Admin.fraud_detection" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Fraud Detection – FoodBridge Admin</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
  <style>
    .risk-high   { background:#fee2e2;color:#dc2626;border-left:4px solid #dc2626; }
    .risk-med    { background:#fff3e0;color:#92400e;border-left:4px solid var(--amber); }
    .risk-low    { background:#f0fdf4;color:#166534;border-left:4px solid var(--green); }
    .flag-badge  { display:inline-block;background:#fee2e2;color:#dc2626;font-size:.72rem;font-weight:700;border-radius:50px;padding:.18rem .65rem; }
    .fraud-stat  { background:var(--white);border-radius:var(--radius);border:1.5px solid var(--sand);padding:1.2rem; }
    .rule-card   { background:var(--cream);border-radius:10px;padding:1rem 1.2rem;border:1.5px solid var(--sand);display:flex;align-items:flex-start;gap:.9rem; }
    .rule-icon   { width:36px;height:36px;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:1rem; }
  </style>
</head>
<body style="background:var(--cream)">

<div class="fb-layout">
  <aside class="fb-sidebar" id="fbSidebar">
    <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
    <nav class="fb-sidebar-nav">
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item" href="admin-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-basket2-fill"></i> All Donations</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item" href="reports.html"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-shield-check"></i> Verifications</a>
      <a class="fb-nav-item" href="emergency-mode.html"><i class="bi bi-exclamation-triangle-fill"></i> Emergency Mode</a>
      <a class="fb-nav-item active" href="fraud-detection.html"><i class="bi bi-shield-exclamation" style="color:#dc2626"></i> Fraud Detection</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-gear-fill"></i> Settings</a>
      <a class="fb-nav-item" href="login.html" style="color:var(--red)"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </nav>
    <div class="fb-sidebar-footer">
      <div class="fb-user-chip">
        <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">AD</div>
        <div><div class="name">Admin</div><div class="role"><span class="badge-status badge-role-admin px-2">Super Admin</span></div></div>
      </div>
    </div>
  </aside>

  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Duplicate & Fake Donor Detection</span>
      <div class="fb-topbar-actions">
        <button class="btn-sm-outline" onclick="fbToast('Fraud scan running...')"><i class="bi bi-arrow-clockwise me-1"></i>Run Scan</button>
        <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">AD</div>
      </div>
    </div>

    <div class="fb-content">

      <!-- Alert Banner -->
      <div style="background:#fee2e2;border:1.5px solid #fecaca;border-radius:var(--radius);padding:1rem 1.4rem;display:flex;align-items:center;gap:1rem;margin-bottom:1.5rem">
        <i class="bi bi-exclamation-triangle-fill" style="font-size:1.4rem;color:#dc2626;flex-shrink:0"></i>
        <div style="flex:1"><strong style="color:#dc2626">3 Suspicious Accounts Detected</strong><span style="font-size:.88rem;color:#7f1d1d;margin-left:.75rem">Last scan: 2 hours ago · Auto-scan runs daily at 2:00 AM</span></div>
        <button class="btn-sm-red" onclick="fbToast('All flagged accounts notified!')">Review All</button>
      </div>

      <!-- Stats -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:#dc2626">3</div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">High Risk</div></div></div>
        <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--amber)">7</div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Medium Risk</div></div></div>
        <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--green)">318</div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Verified Clean</div></div></div>
        <div class="col-6 col-md-3"><div class="fraud-stat text-center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--blue)">12</div><div style="font-size:.78rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px">Banned This Month</div></div></div>
      </div>

      <div class="row g-4">

        <!-- Flagged Accounts -->
        <div class="col-lg-8">
          <div class="fb-card p-0 overflow-hidden mb-4">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);background:#fff5f5">
              <h6 style="font-family:'DM Serif Display',serif;margin:0;color:#dc2626"><i class="bi bi-shield-exclamation me-2"></i>Flagged Suspicious Accounts</h6>
            </div>

            <!-- High Risk 1 -->
            <div style="padding:1.2rem;border-bottom:1.5px solid var(--sand)" class="risk-high">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
                <div>
                  <div style="font-weight:700;font-size:.95rem">Unknown Donor – user_4427 &nbsp;<span class="flag-badge">🔴 HIGH RISK</span></div>
                  <div style="font-size:.8rem;color:#7f1d1d;margin-top:.2rem">Registered: Apr 20 &nbsp;|&nbsp; Karachi &nbsp;|&nbsp; 4 donations in 2 hours</div>
                </div>
                <div class="d-flex gap-2">
                  <button class="btn-sm-red" onclick="fbToast('Account banned!','error')">Ban Account</button>
                  <button class="btn-sm-outline" onclick="fbToast('Warning sent to user.')">Warn</button>
                  <button class="btn-sm-outline">Investigate</button>
                </div>
              </div>
              <div style="font-size:.83rem;margin-bottom:.7rem"><strong>Flags detected:</strong></div>
              <div class="d-flex flex-wrap gap-2">
                <span class="flag-badge">🚩 4 donations in 2 hours (unusual)</span>
                <span class="flag-badge">🚩 Same location as banned user_3891</span>
                <span class="flag-badge">🚩 No phone verification</span>
                <span class="flag-badge">🚩 Quantity mismatch reported by NGO</span>
              </div>
            </div>

            <!-- High Risk 2 -->
            <div style="padding:1.2rem;border-bottom:1.5px solid var(--sand)" class="risk-high">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
                <div>
                  <div style="font-weight:700;font-size:.95rem">Ghost Restaurant – "Fast Bites" &nbsp;<span class="flag-badge">🔴 HIGH RISK</span></div>
                  <div style="font-size:.8rem;color:#7f1d1d;margin-top:.2rem">Registered: Apr 15 &nbsp;|&nbsp; Lahore &nbsp;|&nbsp; 6 donations, 0 pickups accepted</div>
                </div>
                <div class="d-flex gap-2">
                  <button class="btn-sm-red" onclick="fbToast('Account suspended!','error')">Suspend</button>
                  <button class="btn-sm-outline">Verify ID</button>
                </div>
              </div>
              <div class="d-flex flex-wrap gap-2">
                <span class="flag-badge">🚩 Address not verifiable (Google Maps)</span>
                <span class="flag-badge">🚩 Phone number inactive</span>
                <span class="flag-badge">🚩 6 donations — 0 accepted by any NGO</span>
              </div>
            </div>

            <!-- Medium Risk -->
            <div style="padding:1.2rem;border-bottom:1.5px solid var(--sand)" class="risk-med">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
                <div>
                  <div style="font-weight:700;font-size:.95rem">Hamid Bakery &nbsp;<span style="display:inline-block;background:#fff3e0;color:var(--amber);font-size:.72rem;font-weight:700;border-radius:50px;padding:.18rem .65rem">🟡 MEDIUM RISK</span></div>
                  <div style="font-size:.8rem;color:#92400e;margin-top:.2rem">Registered: Mar 10 &nbsp;|&nbsp; Karachi &nbsp;|&nbsp; 2 NGO complaints</div>
                </div>
                <div class="d-flex gap-2">
                  <button class="btn-sm-amber" onclick="fbToast('Account placed under review.')">Flag for Review</button>
                  <button class="btn-sm-outline">View History</button>
                </div>
              </div>
              <div class="d-flex flex-wrap gap-2">
                <span style="display:inline-block;background:#fff3e0;color:#92400e;font-size:.72rem;font-weight:700;border-radius:50px;padding:.18rem .65rem">⚠️ 2 NGO quantity complaints</span>
                <span style="display:inline-block;background:#fff3e0;color:#92400e;font-size:.72rem;font-weight:700;border-radius:50px;padding:.18rem .65rem">⚠️ Repeated last-minute cancellations</span>
              </div>
            </div>

            <!-- All Clear -->
            <div style="padding:1rem;background:#f0fdf4;text-align:center;font-size:.85rem;color:#166534">
              <i class="bi bi-shield-check me-1"></i>318 other accounts passed all fraud checks. Last full scan: Apr 22, 2025 at 02:00 AM.
            </div>
          </div>

          <!-- Suspicious Donations -->
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Suspicious Donations Log</h6>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donation ID</th><th>Donor</th><th>Qty Claimed</th><th>Qty Reported</th><th>Location Check</th><th>Action</th></tr></thead>
                <tbody>
                  <tr class="risk-high" style="border-left:none">
                    <td class="ps-3">#FB-2025-0089</td><td>user_4427</td><td>200 plates</td><td>~30 plates (NGO)</td>
                    <td><span class="badge-status badge-rejected">Mismatch</span></td>
                    <td><button class="btn-sm-red" onclick="fbToast('Donation removed!')">Remove</button></td>
                  </tr>
                  <tr class="risk-med" style="border-left:none">
                    <td class="ps-3">#FB-2025-0072</td><td>Fast Bites</td><td>500 plates</td><td>No pickup (expired)</td>
                    <td><span class="badge-status badge-pending">Unverified</span></td>
                    <td><button class="btn-sm-amber" onclick="fbToast('Marked as suspicious.')">Flag</button></td>
                  </tr>
                  <tr>
                    <td class="ps-3">#FB-2025-0055</td><td>Hamid Bakery</td><td>100 plates</td><td>85 plates (NGO)</td>
                    <td><span class="badge-status badge-accepted">Minor diff</span></td>
                    <td><button class="btn-sm-outline" onclick="fbToast('Warning sent to donor.')">Warn</button></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Right Column -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Detection Rules -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Detection Rules Active</h6>
            <div class="d-flex flex-column gap-2">
              <div class="rule-card">
                <div class="rule-icon" style="background:#fee2e2;color:#dc2626"><i class="bi bi-geo-alt-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Location Check</div><div style="font-size:.78rem;color:var(--text-muted)">Flags same-location duplicate accounts</div></div>
              </div>
              <div class="rule-card">
                <div class="rule-icon" style="background:#fff3e0;color:var(--amber)"><i class="bi bi-clock-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Rapid Posting</div><div style="font-size:.78rem;color:var(--text-muted)">Flags 3+ donations posted within 1 hour</div></div>
              </div>
              <div class="rule-card">
                <div class="rule-icon" style="background:#e0f2fe;color:var(--blue)"><i class="bi bi-bar-chart-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Quantity Mismatch</div><div style="font-size:.78rem;color:var(--text-muted)">Compares donor claim vs NGO-confirmed qty</div></div>
              </div>
              <div class="rule-card">
                <div class="rule-icon" style="background:#f3e8ff;color:var(--purple)"><i class="bi bi-telephone-x-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Unverified Contact</div><div style="font-size:.78rem;color:var(--text-muted)">Flags accounts without phone verification</div></div>
              </div>
              <div class="rule-card">
                <div class="rule-icon" style="background:#fee2e2;color:#dc2626"><i class="bi bi-x-circle-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Repeat Cancellations</div><div style="font-size:.78rem;color:var(--text-muted)">Flags donors who cancel 3+ times</div></div>
              </div>
              <div class="rule-card">
                <div class="rule-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-flag-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">NGO Reports</div><div style="font-size:.78rem;color:var(--text-muted)">Auto-flags after 2 NGO complaints</div></div>
              </div>
            </div>
          </div>

          <!-- Scan Settings -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Scan Settings</h6>
            <div class="d-flex flex-column gap-3">
              <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:.87rem">Auto daily scan</span>
                <div style="width:40px;height:22px;background:var(--green);border-radius:50px;position:relative;cursor:pointer"><div style="width:18px;height:18px;background:#fff;border-radius:50%;position:absolute;top:2px;right:2px"></div></div>
              </div>
              <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:.87rem">Email admin on flag</span>
                <div style="width:40px;height:22px;background:var(--green);border-radius:50px;position:relative;cursor:pointer"><div style="width:18px;height:18px;background:#fff;border-radius:50%;position:absolute;top:2px;right:2px"></div></div>
              </div>
              <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:.87rem">Auto-suspend high risk</span>
                <div style="width:40px;height:22px;background:var(--sand-dark);border-radius:50px;position:relative;cursor:pointer"><div style="width:18px;height:18px;background:#fff;border-radius:50%;position:absolute;top:2px;left:2px"></div></div>
              </div>
              <div>
                <label style="font-size:.82rem;font-weight:600;display:block;margin-bottom:.35rem">Scan Frequency</label>
                <select class="fb-input fb-select" style="font-size:.85rem">
                  <option>Every 24 hours</option>
                  <option>Every 12 hours</option>
                  <option>Every 6 hours</option>
                  <option>Real-time</option>
                </select>
              </div>
              <button class="btn-sm-green" onclick="fbToast('Settings saved!')">Save Settings</button>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../js/main.js"></script>
</body>
</html>
