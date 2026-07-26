<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="volunteer-assign.aspx.cs" Inherits="LeftoverFood.Admin.volunteer_assign" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Assign Volunteers – FoodBridge Admin</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
  <style>
    .donation-row { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.2rem 1.4rem; }
    .vol-chip { display:flex; align-items:center; gap:.6rem; background:var(--cream); border-radius:8px; padding:.6rem .9rem; cursor:pointer; border:1.5px solid transparent; transition:var(--transition); }
    .vol-chip:hover { border-color:var(--green); }
    .vol-chip.selected { border-color:var(--green); background:#e8f5ee; }
    .avail-dot { width:9px; height:9px; border-radius:50%; flex-shrink:0; }
    .map-mini { background:linear-gradient(145deg,#e8f5ee,#d0f0e0); border-radius:10px; height:160px; display:flex; flex-direction:column; align-items:center; justify-content:center; border:1.5px dashed var(--green-light); font-size:.83rem; color:var(--text-muted); text-align:center; gap:.4rem; }
  </style>
</head>
<body style="background:var(--cream)">
<div class="fb-layout">

  <aside class="fb-sidebar" id="fbSidebar">
    <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
    <nav class="fb-sidebar-nav">
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item" href="admin-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item" href="food-approvals.html"><i class="bi bi-clipboard2-check-fill"></i> Food Approvals <span class="badge-count">7</span></a>
      <a class="fb-nav-item active" href="volunteer-assign.html"><i class="bi bi-person-check-fill"></i> Assign Volunteers</a>
      <a class="fb-nav-item" href="donations-list.html"><i class="bi bi-basket2"></i> All Donations</a>
      <div class="fb-sidebar-section">Users</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-lines-fill"></i> Donors</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill-heart"></i> NGOs</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bicycle"></i> Volunteers</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item" href="reports.html"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="emergency-mode.html"><i class="bi bi-exclamation-triangle-fill"></i> Emergency Mode</a>
      <a class="fb-nav-item" href="fraud-detection.html"><i class="bi bi-shield-exclamation"></i> Fraud Detection</a>
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
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Volunteer Assignment</span>
      <div class="fb-topbar-actions">
        <button class="btn-sm-green" onclick="fbToast('Auto-assigning nearest volunteers...')"><i class="bi bi-magic me-1"></i>Auto-Assign All</button>
        <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">AD</div>
      </div>
    </div>

    <div class="fb-content">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Assign Volunteers to Donations</h2>
          <p class="text-muted" style="font-size:.9rem">Match available volunteers to approved donations needing pickup. Sorted by expiry urgency.</p>
        </div>
      </div>

      <!-- Volunteer Availability Summary -->
      <div class="fb-card mb-4">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Available Volunteers — Karachi (Today)</h6>
        <div class="row g-2">
          <div class="col-6 col-md-3">
            <div style="background:#e8f5ee;border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--green)">8</div>
              <div style="font-size:.75rem;color:var(--text-muted)">Available Now</div>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div style="background:var(--amber-light);border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--amber)">4</div>
              <div style="font-size:.75rem;color:var(--text-muted)">On Delivery</div>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div style="background:var(--cream);border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--text-muted)">3</div>
              <div style="font-size:.75rem;color:var(--text-muted)">Offline</div>
            </div>
          </div>
          <div class="col-6 col-md-3">
            <div style="background:var(--blue-light);border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--blue)">5</div>
              <div style="font-size:.75rem;color:var(--text-muted)">Need Assignment</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Assignment Panels -->
      <div class="d-flex flex-column gap-4">

        <!-- Assignment 1 -->
        <div style="background:var(--white);border-radius:var(--radius);border:1.5px solid var(--sand);overflow:hidden">
          <div style="background:#fef2f2;padding:1rem 1.4rem;border-bottom:1.5px solid #fecaca;display:flex;align-items:center;justify-content:space-between;flex-wrap:gap:1rem">
            <div class="d-flex align-items-center gap-2">
              <span style="background:#fee2e2;color:#dc2626;border-radius:50px;padding:.2rem .8rem;font-size:.75rem;font-weight:700">🔴 URGENT</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0092 — Park View Hall (500 plates Biryani)</span>
            </div>
            <span style="font-size:.82rem;color:#dc2626;font-weight:700"><i class="bi bi-alarm me-1"></i>Expires 48 mins</span>
          </div>
          <div class="row g-0">
            <div class="col-lg-6 p-3" style="border-right:1.5px solid var(--sand)">
              <div style="font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:.8rem">Donation Details</div>
              <div class="d-flex flex-column gap-2" style="font-size:.85rem">
                <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i>Pickup: Gulberg Block 3, Lahore</div>
                <div><i class="bi bi-geo-alt me-2 text-success"></i>Deliver to: Saylani Center, Lahore</div>
                <div><i class="bi bi-people-fill me-2" style="color:var(--blue)"></i>500 plates — accepted by Saylani Welfare</div>
                <div><i class="bi bi-telephone-fill me-2 text-muted"></i>Donor contact: +92 300 1234567</div>
              </div>
              <div class="map-mini mt-3">
                <i class="bi bi-map-fill" style="font-size:1.8rem;color:var(--green-mid);opacity:.5"></i>
                <span>Google Maps — Pickup → Drop-off route</span>
                <span style="font-size:.75rem">Approx. 4.2 km · 12 min drive</span>
              </div>
            </div>
            <div class="col-lg-6 p-3">
              <div style="font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:.8rem">Select Volunteer — Lahore</div>
              <div class="d-flex flex-column gap-2 mb-3">
                <div class="vol-chip selected" onclick="selectVol(this)">
                  <div class="avail-dot" style="background:#16a34a"></div>
                  <div class="fb-avatar" style="width:30px;height:30px;font-size:.72rem;background:var(--blue-light);color:var(--blue)">ZM</div>
                  <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Zain Malik</div><div style="font-size:.73rem;color:var(--text-muted)">Gulberg (1.2km away) · ⭐ 4.8 · 52 deliveries</div></div>
                  <span style="font-size:.72rem;background:#e8f5ee;color:var(--green);border-radius:50px;padding:.15rem .5rem;font-weight:700">Free</span>
                </div>
                <div class="vol-chip" onclick="selectVol(this)">
                  <div class="avail-dot" style="background:#16a34a"></div>
                  <div class="fb-avatar" style="width:30px;height:30px;font-size:.72rem;background:var(--purple-light);color:var(--purple)">HR</div>
                  <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Hassan Raza</div><div style="font-size:.73rem;color:var(--text-muted)">DHA (3.1km) · ⭐ 4.6 · 31 deliveries</div></div>
                  <span style="font-size:.72rem;background:#e8f5ee;color:var(--green);border-radius:50px;padding:.15rem .5rem;font-weight:700">Free</span>
                </div>
                <div class="vol-chip" onclick="selectVol(this)">
                  <div class="avail-dot" style="background:#fbbf24"></div>
                  <div class="fb-avatar" style="width:30px;height:30px;font-size:.72rem">NA</div>
                  <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Nadia Ali</div><div style="font-size:.73rem;color:var(--text-muted)">Johar Town (5km) · ⭐ 4.9 · 78 deliveries</div></div>
                  <span style="font-size:.72rem;background:var(--amber-light);color:var(--amber);border-radius:50px;padding:.15rem .5rem;font-weight:700">Finishing up</span>
                </div>
              </div>
              <div class="fb-form-group mb-3">
                <label style="font-size:.82rem">Note for Volunteer (Optional)</label>
                <textarea class="fb-input fb-textarea" style="min-height:60px;font-size:.83rem" placeholder="Special instructions e.g. use back entrance, call donor on arrival..."></textarea>
              </div>
              <button class="btn-green w-100" onclick="fbToast('✅ Zain Malik assigned to #0092! SMS sent to volunteer.')"><i class="bi bi-person-check-fill me-1"></i>Assign Selected Volunteer</button>
            </div>
          </div>
        </div>

        <!-- Assignment 2 -->
        <div style="background:var(--white);border-radius:var(--radius);border:1.5px solid var(--sand);overflow:hidden">
          <div style="background:#fff7ed;padding:1rem 1.4rem;border-bottom:1.5px solid #fed7aa;display:flex;align-items:center;justify-content:space-between;flex-wrap:gap:1rem">
            <div class="d-flex align-items-center gap-2">
              <span style="background:#fff3e0;color:var(--amber);border-radius:50px;padding:.2rem .8rem;font-size:.75rem;font-weight:700">🟡 NORMAL</span>
              <span style="font-weight:600;font-size:.95rem">#FB-2025-0090 — Ali's Restaurant (30 plates Biryani)</span>
            </div>
            <span style="font-size:.82rem;color:var(--amber);font-weight:700"><i class="bi bi-clock me-1"></i>Expires 3h 30m</span>
          </div>
          <div class="row g-0">
            <div class="col-lg-6 p-3" style="border-right:1.5px solid var(--sand)">
              <div class="d-flex flex-column gap-2" style="font-size:.85rem">
                <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i>Pickup: Gulshan Block 2, Karachi</div>
                <div><i class="bi bi-geo-alt me-2 text-success"></i>Deliver to: Edhi Center, Saddar</div>
                <div><i class="bi bi-people-fill me-2" style="color:var(--blue)"></i>30 plates — accepted by Edhi Foundation</div>
              </div>
              <div class="map-mini mt-3">
                <i class="bi bi-map-fill" style="font-size:1.8rem;color:var(--green-mid);opacity:.5"></i>
                <span>Google Maps — Pickup → Drop-off route</span>
                <span style="font-size:.75rem">Approx. 6.8 km · 20 min drive</span>
              </div>
            </div>
            <div class="col-lg-6 p-3">
              <div style="font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:.8rem">Select Volunteer — Karachi</div>
              <div class="d-flex flex-column gap-2 mb-3">
                <div class="vol-chip selected" onclick="selectVol(this)">
                  <div class="avail-dot" style="background:#16a34a"></div>
                  <div class="fb-avatar" style="width:30px;height:30px;font-size:.72rem;background:var(--blue-light);color:var(--blue)">UA</div>
                  <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Usman Ali</div><div style="font-size:.73rem;color:var(--text-muted)">Gulshan (0.8km) · ⭐ 4.9 · 87 deliveries</div></div>
                  <span style="font-size:.72rem;background:#e8f5ee;color:var(--green);border-radius:50px;padding:.15rem .5rem;font-weight:700">Free</span>
                </div>
                <div class="vol-chip" onclick="selectVol(this)">
                  <div class="avail-dot" style="background:#16a34a"></div>
                  <div class="fb-avatar" style="width:30px;height:30px;font-size:.72rem;background:#e8f5ee;color:var(--green)">FM</div>
                  <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Faisal Mirza</div><div style="font-size:.73rem;color:var(--text-muted)">PECHS (2.3km) · ⭐ 4.7 · 44 deliveries</div></div>
                  <span style="font-size:.72rem;background:#e8f5ee;color:var(--green);border-radius:50px;padding:.15rem .5rem;font-weight:700">Free</span>
                </div>
              </div>
              <button class="btn-green w-100" onclick="fbToast('✅ Usman Ali assigned to #0090! SMS sent.')"><i class="bi bi-person-check-fill me-1"></i>Assign Selected Volunteer</button>
            </div>
          </div>
        </div>

      </div>

      <!-- Already Assigned Table -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Already Assigned — Active Deliveries</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Donation</th><th>Volunteer</th><th>Route</th><th>ETA</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
              <tr><td class="ps-3"><strong>#0091</strong> — 150 plates<br><small class="text-muted">Marriott Hotel</small></td><td><div class="d-flex align-items-center gap-1"><div class="fb-avatar" style="width:24px;height:24px;font-size:.65rem;background:var(--purple-light);color:var(--purple)">FN</div>Fatima Noor</div></td><td><small>Clifton → Edhi Korangi</small></td><td><strong style="color:var(--amber)">~25 min</strong></td><td><span class="badge-status badge-accepted">In Transit</span></td><td><button class="btn-sm-outline">Track</button></td></tr>
              <tr><td class="ps-3"><strong>#0088</strong> — 25 boxes<br><small class="text-muted">TechCorp</small></td><td><div class="d-flex align-items-center gap-1"><div class="fb-avatar" style="width:24px;height:24px;font-size:.65rem">AM</div>Ali Mehmood</div></td><td><small>Blue Area → Al-Khidmat</small></td><td><strong style="color:var(--green)">~45 min</strong></td><td><span class="badge-status badge-accepted">Picked Up</span></td><td><button class="btn-sm-outline">Track</button></td></tr>
            </tbody>
          </table>
        </div>
      </div>

    </div>
  </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../js/main.js"></script>
<script>
function selectVol(el) {
  el.closest('.col-lg-6').querySelectorAll('.vol-chip').forEach(c => c.classList.remove('selected'));
  el.classList.add('selected');
}
</script>
</body>
</html>
