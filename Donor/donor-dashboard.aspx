<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="donor-dashboard.aspx.cs" Inherits="LeftoverFood.Donor.donor_dashboard" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Donor Dashboard – FoodBridge</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
</head>
<body style="background:var(--cream)">

<div class="fb-layout">

  <!-- SIDEBAR -->
  <aside class="fb-sidebar" id="fbSidebar">
    <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
    <nav class="fb-sidebar-nav">
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item active" href="donor-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="donate-form.html"><i class="bi bi-plus-circle-fill"></i> New Donation</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> My Donations</a>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-bell-fill"></i> Notifications <span class="badge-count">3</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-chat-dots-fill"></i> Messages</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-award-fill"></i> My Certificates</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill"></i> Profile</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-gear-fill"></i> Settings</a>
      <a class="fb-nav-item" href="login.html" style="color:var(--red)"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </nav>
    <div class="fb-sidebar-footer">
      <div class="fb-user-chip">
        <div class="fb-avatar">AK</div>
        <div><div class="name">Ahmed Khan</div><div class="role"><span class="badge-status badge-role-donor px-2">Donor</span></div></div>
      </div>
    </div>
  </aside>

  <!-- MAIN -->
  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span class="fb-topbar-title" style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Donor Dashboard</span>
      <div class="fb-topbar-actions">
        <div class="search-wrap"><i class="bi bi-search"></i><input class="fb-search" placeholder="Search donations..."/></div>
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar">AK</div>
      </div>
    </div>

    <div class="fb-content">

      <!-- Welcome bar -->
      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Good morning, Ahmed! 👋</h2>
          <p class="text-muted" style="font-size:.9rem">Here's what's happening with your donations today.</p>
        </div>
        <a href="donate-form.html" class="btn-green"><i class="bi bi-plus-circle me-1"></i>New Donation</a>
      </div>

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
              <span class="badge-status badge-accepted">+12%</span>
            </div>
            <div class="stat-val" style="color:var(--green)">47</div>
            <div class="stat-lbl">Total Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:#cff4fc;color:var(--blue)"><i class="bi bi-check2-circle"></i></div>
              <span class="badge-status badge-delivered">Delivered</span>
            </div>
            <div class="stat-val" style="color:var(--blue)">39</div>
            <div class="stat-lbl">Successfully Delivered</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-clock-history"></i></div>
              <span class="badge-status badge-pending">Active</span>
            </div>
            <div class="stat-val" style="color:var(--amber)">5</div>
            <div class="stat-lbl">Pending Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
            </div>
            <div class="stat-val" style="color:var(--purple)">1,240</div>
            <div class="stat-lbl">Meals Provided</div>
          </div>
        </div>
      </div>

      <div class="row g-4">
        <!-- Donations Table -->
        <div class="col-lg-8">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0 fw-600" style="font-family:'DM Serif Display',serif">Recent Donations</h6>
              <div class="d-flex gap-2" data-filter-group>
                <button class="btn-sm-outline active" data-filter="all">All</button>
                <button class="btn-sm-outline" data-filter="pending">Pending</button>
                <button class="btn-sm-outline" data-filter="accepted">Accepted</button>
                <button class="btn-sm-outline" data-filter="delivered">Delivered</button>
              </div>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Food Type</th><th>Quantity</th><th>Date</th><th>NGO</th><th>Status</th><th>Action</th></tr></thead>
                <tbody>
                  <tr data-status="delivered"><td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i>Biryani & Naan</td><td>30 plates</td><td>21 Apr</td><td>Edhi Foundation</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="accepted"><td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i>Mixed Cuisines</td><td>80 plates</td><td>20 Apr</td><td>Saylani</td><td><span class="badge-status badge-accepted">Accepted</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="pending"><td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i>Continental Buffet</td><td>150 plates</td><td>20 Apr</td><td>—</td><td><span class="badge-status badge-pending">Pending</span></td><td><button class="btn-sm-red">Cancel</button></td></tr>
                  <tr data-status="delivered"><td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i>Dal & Roti</td><td>10 plates</td><td>18 Apr</td><td>Al-Khidmat</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="delivered"><td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i>Desi Dishes</td><td>50 plates</td><td>15 Apr</td><td>Akhuwat</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Sidebar Cards -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Impact Card -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Your Impact 🌱</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Meals Provided</span><strong style="font-size:.85rem">1,240 / 2,000</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:62%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Delivery Success Rate</span><strong style="font-size:.85rem;color:var(--green)">94%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:94%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Food Saved (kg)</span><strong style="font-size:.85rem">860 kg</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:43%"></div></div>
              </div>
            </div>
            <div style="background:var(--cream);border-radius:10px;padding:1rem;margin-top:1.2rem;text-align:center">
              <i class="bi bi-award-fill text-warning fs-4 d-block mb-1"></i>
              <div style="font-size:.82rem;font-weight:600">Gold Donor Badge</div>
              <div style="font-size:.75rem;color:var(--text-muted)">Awarded for 40+ donations</div>
            </div>
          </div>

          <!-- Recent Activity -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recent Activity</h6>
            <div class="timeline">
              <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">Today, 10:30 AM</div><div class="tl-text">Donation of 30 plates delivered by Edhi Foundation</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--amber)"></div><div class="tl-time">Yesterday, 3:15 PM</div><div class="tl-text">Saylani accepted your 80-plate donation</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--blue)"></div><div class="tl-time">Apr 20, 9:00 AM</div><div class="tl-text">New donation posted: Continental Buffet – 150 plates</div></div>
              <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">Apr 18, 6:00 PM</div><div class="tl-text">Dal & Roti donation delivered successfully</div></div>
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
