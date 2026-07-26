<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ngo-active-requests.aspx.cs" Inherits="LeftoverFood.NGO.ngo_active_requests" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Active Requests – FoodBridge NGO</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
  <style>
    .req-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); overflow:hidden; }
    .req-card-header { padding:1rem 1.4rem; border-bottom:1.5px solid var(--sand); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.5rem; }
    .req-card-body { padding:1.2rem 1.4rem; }
    .mini-timeline { display:flex; align-items:center; gap:0; margin:.5rem 0; }
    .mt-step { flex:1; text-align:center; position:relative; }
    .mt-step::before { content:''; position:absolute; top:10px; left:50%; right:-50%; height:2px; background:var(--sand-dark); z-index:0; }
    .mt-step:last-child::before { display:none; }
    .mt-dot { width:22px; height:22px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:.65rem; margin:0 auto .3rem; position:relative; z-index:1; }
    .mt-dot.done   { background:var(--green); color:#fff; }
    .mt-dot.active { background:var(--amber); color:#fff; }
    .mt-dot.pending { background:var(--sand-dark); color:#fff; }
    .mt-label { font-size:.65rem; color:var(--text-muted); }
    .map-mini { background:linear-gradient(145deg,#e8f5ee,#d0f0e0); border-radius:8px; height:120px; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:.3rem; font-size:.78rem; color:var(--text-muted); border:1.5px dashed var(--green-light); }
  </style>
</head>
<body style="background:var(--cream)">
<div class="fb-layout">

  <aside class="fb-sidebar" id="fbSidebar">
    <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
    <nav class="fb-sidebar-nav">
      <div class="fb-sidebar-section">Main</div>
      <a class="fb-nav-item" href="ngo-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="donations-list.html"><i class="bi bi-search"></i> Browse Donations</a>
      <a class="fb-nav-item active" href="ngo-active-requests.html"><i class="bi bi-clipboard2-check-fill"></i> Active Requests <span class="badge-count">4</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-clock-history"></i> History</a>
      <div class="fb-sidebar-section">Manage</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-people-fill"></i> Our Volunteers</a>
      <a class="fb-nav-item" href="reports.html"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="notifications.html"><i class="bi bi-bell-fill"></i> Notifications <span class="badge-count">7</span></a>
      <div class="fb-sidebar-section">Account</div>
      <a class="fb-nav-item" href="profile.html"><i class="bi bi-building-fill"></i> NGO Profile</a>
      <a class="fb-nav-item" href="login.html" style="color:var(--red)"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </nav>
    <div class="fb-sidebar-footer">
      <div class="fb-user-chip">
        <div class="fb-avatar" style="background:var(--amber-light);color:var(--amber)">EF</div>
        <div><div class="name">Edhi Foundation</div><div class="role"><span class="badge-status badge-role-ngo px-2">NGO</span> <span class="badge-status badge-verified px-2">✓ Verified</span></div></div>
      </div>
    </div>
  </aside>

  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Active Requests</span>
      <div class="fb-topbar-actions">
        <div class="search-wrap"><i class="bi bi-search"></i><input class="fb-search" placeholder="Search..."/></div>
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar" style="background:var(--amber-light);color:var(--amber)">EF</div>
      </div>
    </div>

    <div class="fb-content">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">My Accepted Requests</h2>
          <p class="text-muted" style="font-size:.9rem">Track and manage all food donations your NGO has accepted.</p>
        </div>
        <a href="donations-list.html" class="btn-amber"><i class="bi bi-search me-1"></i>Browse More Donations</a>
      </div>

      <!-- Quick Stats -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-hourglass-split"></i></div><div class="stat-val" style="color:var(--amber)">1</div><div class="stat-lbl">Awaiting Pickup</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-truck"></i></div><div class="stat-val" style="color:var(--blue)">2</div><div class="stat-lbl">In Transit</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-all"></i></div><div class="stat-val" style="color:var(--green)">1</div><div class="stat-lbl">Arrived Today</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div><div class="stat-val" style="color:var(--purple)">310</div><div class="stat-lbl">Meals Expected</div></div></div>
      </div>

      <!-- Filter Tabs -->
      <div class="d-flex gap-2 flex-wrap mb-4" data-filter-group>
        <button class="btn-sm-outline active" data-filter="all" style="border-radius:50px;padding:.4rem 1.1rem">All Active (4)</button>
        <button class="btn-sm-outline" data-filter="awaiting" style="border-radius:50px;padding:.4rem 1.1rem">Awaiting Pickup (1)</button>
        <button class="btn-sm-outline" data-filter="transit" style="border-radius:50px;padding:.4rem 1.1rem">In Transit (2)</button>
        <button class="btn-sm-outline" data-filter="arrived" style="border-radius:50px;padding:.4rem 1.1rem">Arrived (1)</button>
      </div>

      <div class="d-flex flex-column gap-3">

        <!-- Request 1 — Arrived, needs confirmation -->
        <div class="req-card" data-status="arrived">
          <div class="req-card-header" style="background:#e8f5ee">
            <div class="d-flex align-items-center gap-2 flex-wrap">
              <span class="badge-status badge-delivered" style="font-size:.8rem;padding:.3rem .9rem">✅ Arrived — Confirm Receipt</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0085 — Biryani & Naan</span>
            </div>
            <span style="font-size:.82rem;color:var(--green);font-weight:600">Arrived 5 mins ago</span>
          </div>
          <div class="req-card-body">
            <div class="row g-3 align-items-center">
              <div class="col-md-5">
                <div class="d-flex flex-column gap-1 mb-3" style="font-size:.85rem">
                  <div><i class="bi bi-person-fill me-2 text-muted"></i><strong>Ali's Restaurant</strong> &nbsp;🥇 Gold</div>
                  <div><i class="bi bi-egg-fried me-2 text-muted"></i>30 plates Biryani & Naan · Halal</div>
                  <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i>Gulshan Block 2, Karachi</div>
                  <div><i class="bi bi-bicycle me-2" style="color:var(--blue)"></i>Volunteer: <strong>Usman Ali</strong> · ⭐ 4.9</div>
                </div>
                <!-- Mini Timeline -->
                <div class="mini-timeline">
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Posted</div></div>
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Approved</div></div>
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Accepted</div></div>
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Picked Up</div></div>
                  <div class="mt-step"><div class="mt-dot active"><i class="bi bi-geo-alt-fill" style="font-size:.55rem"></i></div><div class="mt-label">Arrived</div></div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="fb-form-group mb-2">
                  <label style="font-size:.78rem">Actual Quantity Received</label>
                  <div style="display:flex;gap:.5rem">
                    <input type="number" class="fb-input" value="28" style="flex:1"/>
                    <select class="fb-input fb-select" style="width:80px">
                      <option>plates</option><option>kg</option>
                    </select>
                  </div>
                </div>
                <div class="fb-form-group mb-2">
                  <label style="font-size:.78rem">Food Condition</label>
                  <select class="fb-input fb-select">
                    <option>Good — Fresh & Ready</option>
                    <option>Acceptable — Minor Issues</option>
                    <option>Poor — Not Usable</option>
                  </select>
                </div>
                <div class="fb-form-group mb-0">
                  <label style="font-size:.78rem">Notes (Optional)</label>
                  <input type="text" class="fb-input" placeholder="Any remarks..."/>
                </div>
              </div>
              <div class="col-md-3">
                <div class="d-flex flex-column gap-2">
                  <button class="btn-green w-100" onclick="fbToast('✅ Receipt confirmed! Donor & volunteer notified. Rating form sent.')"><i class="bi bi-check2-circle me-1"></i>Confirm Receipt</button>
                  <button class="btn-sm-outline w-100" onclick="fbToast('Issue reported to admin.','error')"><i class="bi bi-exclamation-triangle me-1"></i>Report Issue</button>
                  <button class="btn-sm-outline w-100"><i class="bi bi-telephone me-1"></i>Call Volunteer</button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Request 2 — In Transit -->
        <div class="req-card" data-status="transit">
          <div class="req-card-header" style="background:#e0f2fe">
            <div class="d-flex align-items-center gap-2 flex-wrap">
              <span class="badge-status badge-accepted" style="font-size:.8rem;padding:.3rem .9rem">🚴 In Transit</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0091 — Continental Buffet</span>
            </div>
            <span style="font-size:.82rem;color:var(--blue);font-weight:600"><i class="bi bi-alarm me-1"></i>ETA: ~25 mins</span>
          </div>
          <div class="req-card-body">
            <div class="row g-3 align-items-center">
              <div class="col-md-5">
                <div class="d-flex flex-column gap-1 mb-3" style="font-size:.85rem">
                  <div><i class="bi bi-person-fill me-2 text-muted"></i><strong>Marriott Hotel Catering</strong></div>
                  <div><i class="bi bi-egg-fried me-2 text-muted"></i>150 plates Continental · Refrigerated</div>
                  <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i>Clifton, Karachi</div>
                  <div><i class="bi bi-bicycle me-2" style="color:var(--blue)"></i>Volunteer: <strong>Fatima Noor</strong></div>
                </div>
                <div class="mini-timeline">
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Posted</div></div>
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Approved</div></div>
                  <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Accepted</div></div>
                  <div class="mt-step"><div class="mt-dot active"><i class="bi bi-truck" style="font-size:.55rem"></i></div><div class="mt-label">In Transit</div></div>
                  <div class="mt-step"><div class="mt-dot pending"><i class="bi bi-geo-alt" style="font-size:.55rem"></i></div><div class="mt-label">Arrived</div></div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="map-mini">
                  <i class="bi bi-map-fill" style="font-size:1.5rem;color:var(--green-mid);opacity:.5"></i>
                  <div>Google Maps — Live tracking</div>
                  <div style="font-size:.72rem">Clifton → Edhi Center Saddar</div>
                </div>
                <div style="background:var(--blue-light);border-radius:8px;padding:.6rem;margin-top:.6rem;font-size:.78rem;color:var(--blue);text-align:center">
                  <i class="bi bi-broadcast-pin me-1"></i>Volunteer is 4.2 km away — 25 min ETA
                </div>
              </div>
              <div class="col-md-3">
                <div class="d-flex flex-column gap-2">
                  <button class="btn-sm-outline w-100"><i class="bi bi-telephone me-1"></i>Call Volunteer</button>
                  <button class="btn-sm-outline w-100"><i class="bi bi-chat me-1"></i>Message Donor</button>
                  <button class="btn-sm-red w-100" onclick="if(confirm('Cancel this request?')) fbToast('Request cancelled.','error')"><i class="bi bi-x-circle me-1"></i>Cancel Request</button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Request 3 — In Transit -->
        <div class="req-card" data-status="transit">
          <div class="req-card-header" style="background:#e0f2fe">
            <div class="d-flex align-items-center gap-2 flex-wrap">
              <span class="badge-status badge-accepted" style="font-size:.8rem;padding:.3rem .9rem">🚴 In Transit</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0090 — Biryani & Naan (Ali's)</span>
            </div>
            <span style="font-size:.82rem;color:var(--blue);font-weight:600"><i class="bi bi-alarm me-1"></i>ETA: ~40 mins</span>
          </div>
          <div class="req-card-body">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
              <div class="d-flex flex-column gap-1" style="font-size:.85rem">
                <div><i class="bi bi-egg-fried me-2 text-muted"></i>30 plates · Gulshan Block 2</div>
                <div><i class="bi bi-bicycle me-2" style="color:var(--blue)"></i>Volunteer: <strong>Usman Ali</strong></div>
              </div>
              <div class="mini-timeline" style="min-width:260px">
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Posted</div></div>
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Approved</div></div>
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Accepted</div></div>
                <div class="mt-step"><div class="mt-dot active"><i class="bi bi-truck" style="font-size:.55rem"></i></div><div class="mt-label">Transit</div></div>
                <div class="mt-step"><div class="mt-dot pending"><i class="bi bi-geo-alt" style="font-size:.55rem"></i></div><div class="mt-label">Arrived</div></div>
              </div>
              <div class="d-flex gap-2">
                <button class="btn-sm-outline" onclick="fbToast('Calling volunteer...')"><i class="bi bi-telephone me-1"></i>Call</button>
                <button class="btn-sm-red" onclick="if(confirm('Cancel?')) fbToast('Cancelled.','error')"><i class="bi bi-x me-1"></i>Cancel</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Request 4 — Awaiting Pickup -->
        <div class="req-card" data-status="awaiting">
          <div class="req-card-header" style="background:var(--amber-light)">
            <div class="d-flex align-items-center gap-2 flex-wrap">
              <span class="badge-status badge-pending" style="font-size:.8rem;padding:.3rem .9rem">⏳ Awaiting Volunteer Pickup</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0088 — Office Lunch Boxes</span>
            </div>
            <span style="font-size:.82rem;color:var(--amber);font-weight:600">Expires in 6h</span>
          </div>
          <div class="req-card-body">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
              <div class="d-flex flex-column gap-1" style="font-size:.85rem">
                <div><i class="bi bi-box-seam me-2 text-muted"></i>25 sealed boxes · Blue Area, Islamabad</div>
                <div><i class="bi bi-bicycle me-2" style="color:var(--amber)"></i>Volunteer assignment pending...</div>
                <div style="font-size:.8rem;color:var(--text-muted)">Accepted: Apr 22 at 10:00 AM · Admin notified to assign volunteer</div>
              </div>
              <div class="mini-timeline" style="min-width:260px">
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Posted</div></div>
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Approved</div></div>
                <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Accepted</div></div>
                <div class="mt-step"><div class="mt-dot active" style="background:var(--amber)"><i class="bi bi-hourglass-split" style="font-size:.55rem"></i></div><div class="mt-label">Pickup</div></div>
                <div class="mt-step"><div class="mt-dot pending"></div><div class="mt-label">Arrived</div></div>
              </div>
              <div class="d-flex gap-2">
                <button class="btn-sm-outline" onclick="fbToast('Reminder sent to admin!')"><i class="bi bi-bell me-1"></i>Remind Admin</button>
                <button class="btn-sm-red" onclick="if(confirm('Cancel request?')) fbToast('Cancelled.','error')"><i class="bi bi-x me-1"></i>Cancel</button>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Completed Today -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Completed Today</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">ID</th><th>Donor</th><th>Food</th><th>Qty Received</th><th>Volunteer</th><th>Completed</th><th>Action</th></tr></thead>
            <tbody>
              <tr><td class="ps-3"><strong>#0083</strong></td><td>Park View Hall</td><td>Mixed Cuisines</td><td>200 plates</td><td>Usman Ali</td><td>11:30 AM</td><td><button class="btn-sm-outline" onclick="fbToast('Certificate downloaded!')">Certificate</button></td></tr>
              <tr><td class="ps-3"><strong>#0081</strong></td><td>Bake House</td><td>Pastries</td><td>38 items</td><td>Fatima Noor</td><td>09:15 AM</td><td><button class="btn-sm-outline">Certificate</button></td></tr>
            </tbody>
          </table>
        </div>
      </div>

    </div>
  </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../js/main.js"></script>
</body>
</html>
