<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="admin-dashboard.aspx.cs" Inherits="LeftoverFood.Admin.admin_dashboard" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Admin Dashboard – FoodBridge</title>
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
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item active" href="admin-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-basket2-fill"></i> All Donations <span class="badge-count">18</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-truck"></i> Deliveries</a>
      <div class="fb-sidebar-section">Users</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-lines-fill"></i> Donors</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill-heart"></i> NGOs <span class="badge-count">3</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bicycle"></i> Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill-gear"></i> All Users</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-shield-check"></i> Verifications <span class="badge-count">5</span></a>
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

  <!-- MAIN -->
  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Admin Dashboard</span>
      <div class="fb-topbar-actions">
        <div class="search-wrap"><i class="bi bi-search"></i><input class="fb-search" placeholder="Search anything..."/></div>
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">AD</div>
      </div>
    </div>

    <div class="fb-content">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">System Overview</h2>
          <p class="text-muted" style="font-size:.9rem">Wednesday, 22 April 2025 &nbsp;|&nbsp; All systems operational</p>
        </div>
        <div class="d-flex gap-2">
          <button class="btn-sm-outline" onclick="fbToast('Report generated!')"><i class="bi bi-download me-1"></i>Export Report</button>
          <button class="btn-green" onclick="fbToast('Data refreshed!')"><i class="bi bi-arrow-clockwise me-1"></i>Refresh</button>
        </div>
      </div>

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
              <span class="badge-status badge-accepted">↑ 8%</span>
            </div>
            <div class="stat-val" style="color:var(--green)">1,284</div>
            <div class="stat-lbl">Total Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-building-fill-heart"></i></div>
              <span class="badge-status badge-pending">3 Pending</span>
            </div>
            <div class="stat-val" style="color:var(--amber)">85</div>
            <div class="stat-lbl">Registered NGOs</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-people-fill"></i></div>
              <span class="badge-status badge-accepted">↑ 15%</span>
            </div>
            <div class="stat-val" style="color:var(--blue)">3,420</div>
            <div class="stat-lbl">Total Users</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-emoji-smile-fill"></i></div>
              <span class="badge-status badge-accepted">↑ 22%</span>
            </div>
            <div class="stat-val" style="color:var(--purple)">28,400</div>
            <div class="stat-lbl">Meals Served (Total)</div>
          </div>
        </div>
      </div>

      <div class="row g-4">

        <!-- All Donations Table -->
        <div class="col-lg-8">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Recent Donations (All)</h6>
              <div class="d-flex gap-2" data-filter-group>
                <button class="btn-sm-outline active" data-filter="all">All</button>
                <button class="btn-sm-outline" data-filter="pending">Pending</button>
                <button class="btn-sm-outline" data-filter="accepted">Accepted</button>
                <button class="btn-sm-outline" data-filter="delivered">Delivered</button>
              </div>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donor</th><th>Food</th><th>Qty</th><th>NGO</th><th>Volunteer</th><th>Status</th><th>Action</th></tr></thead>
                <tbody>
                  <tr data-status="delivered"><td class="ps-3"><strong>Ali's Restaurant</strong><br><small class="text-muted">Karachi</small></td><td>Biryani</td><td>30</td><td>Edhi</td><td>Usman Ali</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="accepted"><td class="ps-3"><strong>Park View Hall</strong><br><small class="text-muted">Lahore</small></td><td>Mixed</td><td>200</td><td>Saylani</td><td>Fatima Noor</td><td><span class="badge-status badge-accepted">Accepted</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="pending"><td class="ps-3"><strong>Marriott Hotel</strong><br><small class="text-muted">Karachi</small></td><td>Continental</td><td>150</td><td>—</td><td>—</td><td><span class="badge-status badge-pending">Pending</span></td><td><button class="btn-sm-amber">Assign</button></td></tr>
                  <tr data-status="delivered"><td class="ps-3"><strong>Sara Ahmed</strong><br><small class="text-muted">Islamabad</small></td><td>Dal Roti</td><td>10</td><td>Al-Khidmat</td><td>Zain Malik</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="rejected"><td class="ps-3"><strong>Home Donor</strong><br><small class="text-muted">Rawalpindi</small></td><td>Leftover</td><td>5</td><td>—</td><td>—</td><td><span class="badge-status badge-rejected">Rejected</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Right Column -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Pending Verifications -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">NGO Verifications</h6>
              <span class="badge-status badge-pending px-2">5 Pending</span>
            </div>
            <div class="d-flex flex-column gap-2">
              <div style="background:var(--cream);border-radius:10px;padding:.85rem">
                <div style="font-size:.87rem;font-weight:600">Aman Foundation</div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-bottom:.6rem">Karachi | Applied: Apr 20</div>
                <div class="d-flex gap-2"><button class="btn-sm-green" onclick="fbToast('NGO Verified!')">Verify</button><button class="btn-sm-red" onclick="fbToast('NGO Rejected!','error')">Reject</button><button class="btn-sm-outline">Docs</button></div>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:.85rem">
                <div style="font-size:.87rem;font-weight:600">Khidmat Trust</div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-bottom:.6rem">Lahore | Applied: Apr 19</div>
                <div class="d-flex gap-2"><button class="btn-sm-green" onclick="fbToast('NGO Verified!')">Verify</button><button class="btn-sm-red" onclick="fbToast('NGO Rejected!','error')">Reject</button><button class="btn-sm-outline">Docs</button></div>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:.85rem">
                <div style="font-size:.87rem;font-weight:600">Green Hands</div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-bottom:.6rem">Islamabad | Applied: Apr 18</div>
                <div class="d-flex gap-2"><button class="btn-sm-green" onclick="fbToast('NGO Verified!')">Verify</button><button class="btn-sm-red" onclick="fbToast('NGO Rejected!','error')">Reject</button><button class="btn-sm-outline">Docs</button></div>
              </div>
            </div>
          </div>

          <!-- System Stats -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">System Health</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Donation Fulfillment</span><strong style="font-size:.85rem;color:var(--green)">94%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:94%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">NGO Response Rate</span><strong style="font-size:.85rem">88%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:88%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Volunteer Availability</span><strong style="font-size:.85rem;color:var(--amber)">72%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:72%;background:var(--amber)"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">User Growth (month)</span><strong style="font-size:.85rem;color:var(--blue)">+15%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:55%;background:var(--blue)"></div></div>
              </div>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Quick Actions</h6>
            <div class="d-flex flex-column gap-2">
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Opening user management...')"><i class="bi bi-person-plus me-2 text-success"></i>Add New User</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Opening NGO management...')"><i class="bi bi-building-add me-2 text-warning"></i>Register New NGO</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Report downloading...')"><i class="bi bi-file-earmark-bar-graph me-2 text-primary"></i>Download Monthly Report</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Broadcast sent!')"><i class="bi bi-megaphone me-2 text-danger"></i>Send Broadcast</button>
            </div>
          </div>

        </div>
      </div>

      <!-- Users Table -->
      <div class="mt-4">
        <div class="fb-card p-0 overflow-hidden">
          <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
            <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Registered Users</h6>
          </div>
          <div class="table-responsive">
            <table class="fb-table">
              <thead><tr><th class="ps-3">Name</th><th>Email</th><th>Role</th><th>City</th><th>Joined</th><th>Status</th><th>Action</th></tr></thead>
              <tbody>
                <tr><td class="ps-3"><div class="d-flex align-items-center gap-2"><div class="fb-avatar" style="width:30px;height:30px;font-size:.75rem">AK</div>Ahmed Khan</div></td><td>ahmed@email.com</td><td><span class="badge-status badge-role-donor">Donor</span></td><td>Karachi</td><td>Jan 2025</td><td><span class="badge-status badge-active">Active</span></td><td><div class="d-flex gap-1"><button class="btn-sm-outline">Edit</button><button class="btn-sm-red">Ban</button></div></td></tr>
                <tr><td class="ps-3"><div class="d-flex align-items-center gap-2"><div class="fb-avatar" style="width:30px;height:30px;font-size:.75rem;background:var(--amber-light);color:var(--amber)">EF</div>Edhi Foundation</div></td><td>edhi@ngo.org</td><td><span class="badge-status badge-role-ngo">NGO</span></td><td>Karachi</td><td>Dec 2024</td><td><span class="badge-status badge-verified">Verified</span></td><td><div class="d-flex gap-1"><button class="btn-sm-outline">Edit</button><button class="btn-sm-red">Ban</button></div></td></tr>
                <tr><td class="ps-3"><div class="d-flex align-items-center gap-2"><div class="fb-avatar" style="width:30px;height:30px;font-size:.75rem;background:var(--blue-light);color:var(--blue)">UA</div>Usman Ali</div></td><td>usman@vol.pk</td><td><span class="badge-status badge-role-vol">Volunteer</span></td><td>Karachi</td><td>Feb 2025</td><td><span class="badge-status badge-active">Active</span></td><td><div class="d-flex gap-1"><button class="btn-sm-outline">Edit</button><button class="btn-sm-red">Ban</button></div></td></tr>
                <tr><td class="ps-3"><div class="d-flex align-items-center gap-2"><div class="fb-avatar" style="width:30px;height:30px;font-size:.75rem">SA</div>Sara Ahmed</div></td><td>sara@gmail.com</td><td><span class="badge-status badge-role-donor">Donor</span></td><td>Islamabad</td><td>Mar 2025</td><td><span class="badge-status badge-active">Active</span></td><td><div class="d-flex gap-1"><button class="btn-sm-outline">Edit</button><button class="btn-sm-red">Ban</button></div></td></tr>
              </tbody>
            </table>
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
