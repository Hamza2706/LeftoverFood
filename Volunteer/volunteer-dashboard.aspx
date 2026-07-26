<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="volunteer-dashboard.aspx.cs" Inherits="LeftoverFood.Volunteer.volunteer_dashboard" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Volunteer Dashboard – FoodBridge</title>
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
      <a class="fb-nav-item active" href="volunteer-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-list-task"></i> My Tasks <span class="badge-count">2</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> Completed</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-geo-alt-fill"></i> Nearby Pickups</a>
      <div class="fb-sidebar-section">Activity</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-bell-fill"></i> Notifications <span class="badge-count">2</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-chat-dots-fill"></i> Messages</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-trophy-fill"></i> My Points</a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill"></i> Profile</a>
      <a class="fb-nav-item" href="login.html" style="color:var(--red)"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </nav>
    <div class="fb-sidebar-footer">
      <div class="fb-user-chip">
        <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue)">UA</div>
        <div><div class="name">Usman Ali</div><div class="role"><span class="badge-status badge-role-vol px-2">Volunteer</span></div></div>
      </div>
    </div>
  </aside>

  <!-- MAIN -->
  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Volunteer Dashboard</span>
      <div class="fb-topbar-actions">
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue)">UA</div>
      </div>
    </div>

    <div class="fb-content">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Hey Usman! Ready to help? 🚴</h2>
          <p class="text-muted" style="font-size:.9rem">You have <strong style="color:var(--amber)">2 active tasks</strong> assigned to you today.</p>
        </div>
        <div class="d-flex gap-2 align-items-center">
          <span style="font-size:.85rem;color:var(--text-muted)">Status:</span>
          <button class="btn-sm-green" onclick="fbToast('You are now marked as Available!')"><i class="bi bi-circle-fill me-1" style="font-size:.5rem"></i>Available</button>
        </div>
      </div>

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-bicycle"></i></div>
            <div class="stat-val" style="color:var(--blue)">2</div>
            <div class="stat-lbl">Active Tasks</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-circle"></i></div>
            <div class="stat-val" style="color:var(--green)">87</div>
            <div class="stat-lbl">Deliveries Done</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-trophy-fill"></i></div>
            <div class="stat-val" style="color:var(--purple)">1,740</div>
            <div class="stat-lbl">Points Earned</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-star-fill"></i></div>
            <div class="stat-val" style="color:var(--amber)">4.9</div>
            <div class="stat-lbl">Rating</div>
          </div>
        </div>
      </div>

      <div class="row g-4">

        <!-- Active Tasks -->
        <div class="col-lg-7">
          <div class="fb-card p-0 overflow-hidden">
            <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Active Tasks</h6>
            </div>
            <!-- Task 1 -->
            <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
              <div class="d-flex justify-content-between align-items-start mb-3">
                <div><div style="font-size:1rem;font-weight:700">Pickup – 30 plates Biryani</div><div style="font-size:.82rem;color:var(--text-muted)">From: Ali's Restaurant, Gulshan</div></div>
                <span class="badge-status badge-accepted">In Progress</span>
              </div>
              <div class="d-flex gap-3 mb-3" style="font-size:.83rem;color:var(--text-muted)">
                <span><i class="bi bi-geo-alt me-1 text-success"></i>Gulshan Block 2</span>
                <span><i class="bi bi-arrow-right me-1"></i></span>
                <span><i class="bi bi-geo-alt me-1 text-danger"></i>Edhi Center, Saddar</span>
              </div>
              <div class="fb-progress mb-2"><div class="fb-progress-bar" style="width:65%"></div></div>
              <div class="d-flex justify-content-between" style="font-size:.78rem;color:var(--text-muted)">
                <span>Picked up ✓</span><span>In Transit...</span><span>Deliver</span>
              </div>
              <div class="d-flex gap-2 mt-3">
                <button class="btn-sm-green" onclick="fbToast('Delivery confirmed! Points added.')"><i class="bi bi-check2 me-1"></i>Mark Delivered</button>
                <button class="btn-sm-outline"><i class="bi bi-telephone me-1"></i>Call NGO</button>
              </div>
            </div>
            <!-- Task 2 -->
            <div class="p-3">
              <div class="d-flex justify-content-between align-items-start mb-3">
                <div><div style="font-size:1rem;font-weight:700">Pickup – 80 plates Mixed</div><div style="font-size:.82rem;color:var(--text-muted)">From: Park View Hall, DHA</div></div>
                <span class="badge-status badge-pending">Pending Pickup</span>
              </div>
              <div class="d-flex gap-3 mb-3" style="font-size:.83rem;color:var(--text-muted)">
                <span><i class="bi bi-geo-alt me-1 text-success"></i>DHA Phase 5</span>
                <span><i class="bi bi-arrow-right me-1"></i></span>
                <span><i class="bi bi-geo-alt me-1 text-danger"></i>Edhi Center, Korangi</span>
              </div>
              <div class="fb-progress mb-2"><div class="fb-progress-bar" style="width:10%"></div></div>
              <div class="d-flex justify-content-between" style="font-size:.78rem;color:var(--text-muted)">
                <span>Pick up</span><span>In Transit</span><span>Deliver</span>
              </div>
              <div class="d-flex gap-2 mt-3">
                <button class="btn-sm-amber" onclick="fbToast('Pickup confirmed!')"><i class="bi bi-check2 me-1"></i>Confirm Pickup</button>
                <button class="btn-sm-outline"><i class="bi bi-telephone me-1"></i>Call Donor</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Points & Rank -->
          <div class="fb-card" style="background:linear-gradient(135deg,var(--green),#1b4332);color:#fff">
            <div class="d-flex justify-content-between align-items-start mb-3">
              <div><div style="font-size:.8rem;opacity:.7;text-transform:uppercase;letter-spacing:.5px">Total Points</div><div style="font-family:'DM Serif Display',serif;font-size:3rem;line-height:1">1,740</div></div>
              <i class="bi bi-trophy-fill" style="font-size:2.5rem;opacity:.3"></i>
            </div>
            <div style="background:rgba(255,255,255,.15);border-radius:8px;padding:.75rem 1rem;margin-bottom:1rem">
              <div style="font-size:.82rem;opacity:.8;margin-bottom:.3rem">Next Level: Gold Volunteer</div>
              <div style="background:rgba(255,255,255,.2);border-radius:50px;height:6px;overflow:hidden"><div style="background:var(--green-light);height:100%;width:58%;border-radius:50px"></div></div>
              <div style="font-size:.75rem;opacity:.65;margin-top:.3rem">260 points to go</div>
            </div>
            <div class="d-flex justify-content-between" style="font-size:.82rem;opacity:.8">
              <span>🥉 Bronze Badge</span>
              <span>Level 7</span>
              <span>87 Deliveries</span>
            </div>
          </div>

          <!-- Available Pickups Nearby -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Nearby Available Pickups</h6>
              <span class="badge-status badge-pending">3 nearby</span>
            </div>
            <div class="d-flex flex-column gap-2">
              <div style="background:var(--cream);border-radius:10px;padding:.9rem;display:flex;justify-content:space-between;align-items:center">
                <div><div style="font-size:.87rem;font-weight:600">Dal & Roti – 10 plates</div><div style="font-size:.76rem;color:var(--text-muted)"><i class="bi bi-geo-alt me-1"></i>PECHS (1.2 km)</div></div>
                <button class="btn-sm-green" onclick="fbToast('Task assigned to you!')">Accept</button>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:.9rem;display:flex;justify-content:space-between;align-items:center">
                <div><div style="font-size:.87rem;font-weight:600">Bread & Curry – 25 plates</div><div style="font-size:.76rem;color:var(--text-muted)"><i class="bi bi-geo-alt me-1"></i>Bahadurabad (2.8 km)</div></div>
                <button class="btn-sm-green" onclick="fbToast('Task assigned to you!')">Accept</button>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:.9rem;display:flex;justify-content:space-between;align-items:center">
                <div><div style="font-size:.87rem;font-weight:600">Pulao – 40 plates</div><div style="font-size:.76rem;color:var(--text-muted)"><i class="bi bi-geo-alt me-1"></i>Korangi (3.5 km)</div></div>
                <button class="btn-sm-green" onclick="fbToast('Task assigned to you!')">Accept</button>
              </div>
            </div>
          </div>

          <!-- Activity -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recent Activity</h6>
            <div class="timeline">
              <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">Today, 10:00 AM</div><div class="tl-text">Delivered 30 plates – Biryani to Edhi Center</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--amber)"></div><div class="tl-time">Yesterday, 5:30 PM</div><div class="tl-text">Picked up 50 plates from Punjab Food Festival</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--blue)"></div><div class="tl-time">Apr 20, 2:00 PM</div><div class="tl-text">Earned Silver Badge – 50 deliveries!</div></div>
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
