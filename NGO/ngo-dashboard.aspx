<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ngo-dashboard.aspx.cs" Inherits="LeftoverFood.NGO.ngo_dashboard" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>NGO Dashboard – FoodBridge</title>
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
      <a class="fb-nav-item active" href="ngo-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="donations-list.html"><i class="bi bi-search"></i> Browse Donations</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clipboard2-check-fill"></i> Accepted Requests <span class="badge-count">4</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-truck"></i> Deliveries</a>
      <div class="fb-sidebar-section">Manage</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-people-fill"></i> Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bell-fill"></i> Notifications <span class="badge-count">7</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-chat-dots-fill"></i> Messages</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill"></i> NGO Profile</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-gear-fill"></i> Settings</a>
      <a class="fb-nav-item" href="login.html" style="color:var(--red)"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </nav>
    <div class="fb-sidebar-footer">
      <div class="fb-user-chip">
        <div class="fb-avatar" style="background:var(--amber-light);color:var(--amber)">EF</div>
        <div><div class="name">Edhi Foundation</div><div class="role"><span class="badge-status badge-role-ngo px-2">NGO</span> <span class="badge-status badge-verified px-2">Verified</span></div></div>
      </div>
    </div>
  </aside>

  <!-- MAIN -->
  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">NGO Dashboard</span>
      <div class="fb-topbar-actions">
        <div class="search-wrap"><i class="bi bi-search"></i><input class="fb-search" placeholder="Search donations..."/></div>
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar" style="background:var(--amber-light);color:var(--amber)">EF</div>
      </div>
    </div>

    <div class="fb-content">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Edhi Foundation Dashboard</h2>
          <p class="text-muted" style="font-size:.9rem"><i class="bi bi-geo-alt me-1"></i>Karachi, Pakistan &nbsp;|&nbsp; <span class="badge-status badge-verified">Verified NGO</span></p>
        </div>
        <a href="donations-list.html" class="btn-amber"><i class="bi bi-search me-1"></i>Browse Donations</a>
      </div>

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-inbox-fill"></i></div>
            <div class="stat-val" style="color:var(--amber)">12</div>
            <div class="stat-lbl">New Requests</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-all"></i></div>
            <div class="stat-val" style="color:var(--green)">4</div>
            <div class="stat-lbl">Accepted Today</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-truck"></i></div>
            <div class="stat-val" style="color:var(--blue)">2</div>
            <div class="stat-lbl">In Transit</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
            <div class="stat-val" style="color:var(--purple)">5,830</div>
            <div class="stat-lbl">Total Meals Served</div>
          </div>
        </div>
      </div>

      <div class="row g-4">
        <!-- Incoming Requests -->
        <div class="col-lg-7">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Incoming Donation Requests</h6>
              <span class="badge-status badge-pending px-3">12 New</span>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donor</th><th>Food</th><th>Qty</th><th>Pickup</th><th>Action</th></tr></thead>
                <tbody>
                  <tr>
                    <td class="ps-3"><strong>Ali's Restaurant</strong><br><small class="text-muted">Gulshan, Karachi</small></td>
                    <td>Biryani & Naan</td><td>30 plates</td>
                    <td><small>Today 6 PM</small></td>
                    <td><div class="d-flex gap-1"><button class="btn-sm-green" onclick="fbToast('Request Accepted!')">Accept</button><button class="btn-sm-red">Decline</button></div></td>
                  </tr>
                  <tr>
                    <td class="ps-3"><strong>Park View Hall</strong><br><small class="text-muted">DHA, Karachi</small></td>
                    <td>Mixed Cuisines</td><td>200 plates</td>
                    <td><small>Today 8 PM</small></td>
                    <td><div class="d-flex gap-1"><button class="btn-sm-green" onclick="fbToast('Request Accepted!')">Accept</button><button class="btn-sm-red">Decline</button></div></td>
                  </tr>
                  <tr>
                    <td class="ps-3"><strong>Marriott Hotel</strong><br><small class="text-muted">Clifton, Karachi</small></td>
                    <td>Continental</td><td>150 plates</td>
                    <td><small>Tomorrow 10 AM</small></td>
                    <td><div class="d-flex gap-1"><button class="btn-sm-green" onclick="fbToast('Request Accepted!')">Accept</button><button class="btn-sm-red">Decline</button></div></td>
                  </tr>
                  <tr>
                    <td class="ps-3"><strong>Sara Ahmed</strong><br><small class="text-muted">PECHS, Karachi</small></td>
                    <td>Dal & Roti</td><td>10 plates</td>
                    <td><small>Today 4 PM</small></td>
                    <td><div class="d-flex gap-1"><button class="btn-sm-green" onclick="fbToast('Request Accepted!')">Accept</button><button class="btn-sm-red">Decline</button></div></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Right column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Active Deliveries -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Active Deliveries 🚚</h6>
            <div class="d-flex flex-column gap-3">
              <div style="background:var(--cream);border-radius:10px;padding:1rem">
                <div class="d-flex justify-content-between align-items-start mb-2">
                  <div><div style="font-size:.88rem;font-weight:600">30 plates – Biryani</div><div style="font-size:.78rem;color:var(--text-muted)">Volunteer: Usman Ali</div></div>
                  <span class="badge-status badge-accepted">In Transit</span>
                </div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:70%"></div></div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-top:.4rem">ETA: 30 mins</div>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:1rem">
                <div class="d-flex justify-content-between align-items-start mb-2">
                  <div><div style="font-size:.88rem;font-weight:600">80 plates – Mixed</div><div style="font-size:.78rem;color:var(--text-muted)">Volunteer: Fatima Noor</div></div>
                  <span class="badge-status badge-pending">Pickup</span>
                </div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:25%"></div></div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-top:.4rem">ETA: 1 hr 15 mins</div>
              </div>
            </div>
          </div>

          <!-- Volunteer Summary -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-1rem" style="margin-bottom:1rem">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Our Volunteers</h6>
              <button class="btn-sm-outline">Manage</button>
            </div>
            <div class="d-flex flex-column gap-2">
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue)">UA</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Usman Ali</div><div style="font-size:.75rem;color:var(--text-muted)">On Delivery</div></div>
                <span class="badge-status badge-active">Active</span>
              </div>
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">FN</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Fatima Noor</div><div style="font-size:.75rem;color:var(--text-muted)">Picking Up</div></div>
                <span class="badge-status badge-accepted">Busy</span>
              </div>
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:#e8f5ee;color:var(--green)">ZM</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Zain Malik</div><div style="font-size:.75rem;color:var(--text-muted)">Available</div></div>
                <span class="badge-status badge-verified">Free</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Monthly Stats -->
      <div class="row g-3 mt-2">
        <div class="col-12">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Monthly Distribution Summary – April 2025</h6>
            <div class="row g-3">
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--green)">248</div><div style="font-size:.8rem;color:var(--text-muted)">Donations Received</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--amber)">5,830</div><div style="font-size:.8rem;color:var(--text-muted)">Meals Distributed</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--blue)">96%</div><div style="font-size:.8rem;color:var(--text-muted)">Fulfillment Rate</div></div></div>
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
