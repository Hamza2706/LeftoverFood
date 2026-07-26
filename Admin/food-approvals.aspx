<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="food-approvals.aspx.cs" Inherits="LeftoverFood.Admin.food_approvals" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Food Approvals – FoodBridge Admin</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
  <style>
    .approval-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.4rem; transition:var(--transition); }
    .approval-card:hover { box-shadow:var(--shadow); }
    .approval-card.urgent { border-left:4px solid var(--red); }
    .approval-card.warning { border-left:4px solid var(--amber); }
    .approval-card.normal  { border-left:4px solid var(--green); }
    .expiry-pill { display:inline-flex; align-items:center; gap:.35rem; font-size:.78rem; font-weight:700; border-radius:50px; padding:.25rem .8rem; }
    .expiry-red    { background:#fee2e2; color:#dc2626; }
    .expiry-amber  { background:#fff3e0; color:#92400e; }
    .expiry-green  { background:#e8f5ee; color:var(--green); }
    .detail-chip   { display:inline-flex; align-items:center; gap:.35rem; background:var(--cream); border-radius:6px; padding:.3rem .7rem; font-size:.8rem; color:var(--text-mid); }
    .filter-tab    { padding:.45rem 1.1rem; border-radius:50px; border:1.5px solid var(--sand); background:var(--white); font-size:.85rem; font-weight:500; cursor:pointer; color:var(--text-muted); transition:var(--transition); }
    .filter-tab.active { background:var(--green); color:#fff; border-color:var(--green); }
  </style>
</head>
<body style="background:var(--cream)">
<div class="fb-layout">

  <!-- SIDEBAR -->
  <aside class="fb-sidebar" id="fbSidebar">
    <div class="fb-sidebar-brand"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></div>
    <nav class="fb-sidebar-nav">
      <div class="fb-sidebar-section">Overview</div>
      <a class="fb-nav-item" href="admin-dashboard.html"><i class="bi bi-grid-fill"></i> Dashboard</a>
      <a class="fb-nav-item active" href="food-approvals.html"><i class="bi bi-clipboard2-check-fill"></i> Food Approvals <span class="badge-count">7</span></a>
      <a class="fb-nav-item" href="volunteer-assign.html"><i class="bi bi-person-check-fill"></i> Assign Volunteers</a>
      <a class="fb-nav-item" href="donations-list.html"><i class="bi bi-basket2"></i> All Donations</a>
      <div class="fb-sidebar-section">Users</div>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-lines-fill"></i> Donors</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-building-fill-heart"></i> NGOs <span class="badge-count">3</span></a>
      <a class="fb-nav-item" href="#"><i class="bi bi-bicycle"></i> Volunteers</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-person-fill-gear"></i> All Users</a>
      <div class="fb-sidebar-section">System</div>
      <a class="fb-nav-item" href="reports.html"><i class="bi bi-bar-chart-fill"></i> Reports</a>
      <a class="fb-nav-item" href="#"><i class="bi bi-shield-check"></i> NGO Verifications</a>
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

  <!-- MAIN -->
  <div class="fb-main">
    <div class="fb-topbar">
      <button id="sidebarToggle" class="d-lg-none btn btn-sm btn-light border me-2"><i class="bi bi-list"></i></button>
      <span style="font-family:'DM Serif Display',serif;font-size:1.2rem;flex:1">Food Donation Approvals</span>
      <div class="fb-topbar-actions">
        <div class="search-wrap"><i class="bi bi-search"></i><input class="fb-search" placeholder="Search donations..."/></div>
        <div class="notif-btn"><i class="bi bi-bell"></i><span class="notif-dot"></span></div>
        <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">AD</div>
      </div>
    </div>

    <div class="fb-content">

      <!-- Header -->
      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Pending Approvals</h2>
          <p class="text-muted" style="font-size:.9rem">Review and approve food donations before NGOs can access them. Sorted by expiry urgency.</p>
        </div>
        <div class="d-flex gap-2 align-items-center">
          <span style="font-size:.85rem;color:var(--text-muted)">Auto-approve trusted donors:</span>
          <button class="btn-sm-outline" onclick="fbToast('Auto-approve enabled for Gold+ donors!')">Enable</button>
        </div>
      </div>

      <!-- Stats Row -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#fee2e2;color:#dc2626"><i class="bi bi-exclamation-triangle-fill"></i></div>
            <div class="stat-val" style="color:#dc2626">2</div>
            <div class="stat-lbl">Expiring &lt; 2hrs</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-clock-history"></i></div>
            <div class="stat-val" style="color:var(--amber)">5</div>
            <div class="stat-lbl">Awaiting Review</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-circle"></i></div>
            <div class="stat-val" style="color:var(--green)">234</div>
            <div class="stat-lbl">Approved (April)</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#fee2e2;color:var(--red)"><i class="bi bi-x-circle-fill"></i></div>
            <div class="stat-val" style="color:var(--red)">8</div>
            <div class="stat-lbl">Rejected (April)</div>
          </div>
        </div>
      </div>

      <!-- Filter Tabs -->
      <div class="d-flex flex-wrap gap-2 mb-4" data-filter-group>
        <button class="filter-tab active" data-filter="all">All Pending (7)</button>
        <button class="filter-tab" data-filter="urgent">🔴 Urgent (2)</button>
        <button class="filter-tab" data-filter="warning">🟡 Expiring Soon (3)</button>
        <button class="filter-tab" data-filter="normal">🟢 Normal (2)</button>
      </div>

      <!-- APPROVAL CARDS -->
      <div class="d-flex flex-column gap-3">

        <!-- Card 1 - URGENT -->
        <div class="approval-card urgent" data-filter="urgent">
          <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div style="flex:1;min-width:260px">
              <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <span class="expiry-pill expiry-red"><i class="bi bi-alarm-fill"></i> Expires in 48 mins</span>
                <span class="badge-status badge-pending">Awaiting Approval</span>
                <span style="font-size:.75rem;color:var(--text-muted)">#FB-2025-0092 · Posted 2h ago</span>
              </div>
              <h5 style="font-size:1.05rem;margin-bottom:.6rem">Wedding Biryani & Nihari — Park View Hall</h5>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> 500 plates · ~500 people</span>
                <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> Gulberg, Lahore</span>
                <span class="detail-chip"><i class="bi bi-egg-fried"></i> Cooked Meals · Halal</span>
                <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> Private Donor · 🥈 Silver</span>
              </div>
              <p style="font-size:.85rem;color:var(--text-muted);margin:0">"Leftover from last night's wedding. Food is freshly cooked, properly sealed in containers. Available for pickup until 6 PM today."</p>
            </div>
            <div class="d-flex flex-column gap-2" style="min-width:180px">
              <button class="btn-green w-100" onclick="fbToast('✅ Donation #0092 Approved! NGOs notified.')"><i class="bi bi-check2-circle me-1"></i>Approve</button>
              <button class="btn-sm-red w-100" style="padding:.5rem;border-radius:8px;font-size:.88rem" onclick="fbToast('❌ Donation rejected.','error')"><i class="bi bi-x-circle me-1"></i>Reject</button>
              <button class="btn-sm-outline w-100" style="padding:.48rem" onclick="fbToast('Message sent to donor.')"><i class="bi bi-chat me-1"></i>Ask Donor</button>
            </div>
          </div>
          <!-- Donor Trust Info -->
          <div style="background:#fef2f2;border-radius:8px;padding:.65rem 1rem;margin-top:1rem;display:flex;align-items:center;gap:.6rem;font-size:.82rem">
            <i class="bi bi-exclamation-triangle-fill" style="color:#dc2626"></i>
            <span><strong>Action Required!</strong> Food expires in &lt;1 hour. Approving now gives NGOs maximum pickup time.</span>
          </div>
        </div>

        <!-- Card 2 - URGENT -->
        <div class="approval-card urgent" data-filter="urgent">
          <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div style="flex:1;min-width:260px">
              <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <span class="expiry-pill expiry-red"><i class="bi bi-alarm-fill"></i> Expires in 1h 12m</span>
                <span class="badge-status badge-pending">Awaiting Approval</span>
                <span style="font-size:.75rem;color:var(--text-muted)">#FB-2025-0091 · Posted 3h ago</span>
              </div>
              <h5 style="font-size:1.05rem;margin-bottom:.6rem">Continental Buffet — Marriott Hotel Catering</h5>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> 150 plates · ~150 people</span>
                <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> Clifton, Karachi</span>
                <span class="detail-chip"><i class="bi bi-egg-fried"></i> Cooked · Refrigerated</span>
                <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> Marriott Hotel · 🥇 Gold</span>
              </div>
            </div>
            <div class="d-flex flex-column gap-2" style="min-width:180px">
              <button class="btn-green w-100" onclick="fbToast('✅ Donation #0091 Approved!')"><i class="bi bi-check2-circle me-1"></i>Approve</button>
              <button class="btn-sm-red w-100" style="padding:.5rem;border-radius:8px;font-size:.88rem" onclick="fbToast('❌ Rejected.','error')"><i class="bi bi-x-circle me-1"></i>Reject</button>
              <button class="btn-sm-outline w-100" style="padding:.48rem"><i class="bi bi-eye me-1"></i>View Details</button>
            </div>
          </div>
          <div style="background:#e8f5ee;border-radius:8px;padding:.65rem 1rem;margin-top:1rem;display:flex;align-items:center;gap:.6rem;font-size:.82rem">
            <i class="bi bi-award-fill" style="color:var(--green)"></i>
            <span><strong>Gold Donor</strong> — Marriott Hotel has 9 successful donations with 4.7★ rating. <strong>Recommended for fast approval.</strong></span>
          </div>
        </div>

        <!-- Card 3 - WARNING -->
        <div class="approval-card warning" data-filter="warning">
          <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div style="flex:1;min-width:260px">
              <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <span class="expiry-pill expiry-amber"><i class="bi bi-clock"></i> Expires in 3h 30m</span>
                <span class="badge-status badge-pending">Awaiting Approval</span>
                <span style="font-size:.75rem;color:var(--text-muted)">#FB-2025-0090 · Posted 1h ago</span>
              </div>
              <h5 style="font-size:1.05rem;margin-bottom:.6rem">Biryani & Naan — Ali's Restaurant</h5>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> 30 plates</span>
                <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> Gulshan, Karachi</span>
                <span class="detail-chip"><i class="bi bi-egg-fried"></i> Halal · Cooked</span>
                <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> Ali's Restaurant · 🥇 Gold</span>
              </div>
            </div>
            <div class="d-flex flex-column gap-2" style="min-width:180px">
              <button class="btn-green w-100" onclick="fbToast('✅ Donation #0090 Approved!')"><i class="bi bi-check2-circle me-1"></i>Approve</button>
              <button class="btn-sm-red w-100" style="padding:.5rem;border-radius:8px;font-size:.88rem" onclick="fbToast('❌ Rejected.','error')"><i class="bi bi-x-circle me-1"></i>Reject</button>
              <button class="btn-sm-outline w-100" style="padding:.48rem"><i class="bi bi-chat me-1"></i>Ask Donor</button>
            </div>
          </div>
        </div>

        <!-- Card 4 - WARNING (New Donor) -->
        <div class="approval-card warning" data-filter="warning">
          <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div style="flex:1;min-width:260px">
              <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <span class="expiry-pill expiry-amber"><i class="bi bi-clock"></i> Expires in 4h 00m</span>
                <span class="badge-status badge-pending">Awaiting Approval</span>
                <span style="font-size:.75rem;color:var(--text-muted)">#FB-2025-0089 · Posted 30m ago</span>
              </div>
              <h5 style="font-size:1.05rem;margin-bottom:.6rem">Dal, Roti & Mixed Sabzi — Home Donor (Sara)</h5>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> 12 plates</span>
                <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> F-10, Islamabad</span>
                <span class="detail-chip"><i class="bi bi-egg-fried"></i> Vegetarian · Home Cooked</span>
                <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> Individual · 🆕 New Donor</span>
              </div>
            </div>
            <div class="d-flex flex-column gap-2" style="min-width:180px">
              <button class="btn-green w-100" onclick="fbToast('✅ Approved!')"><i class="bi bi-check2-circle me-1"></i>Approve</button>
              <button class="btn-sm-red w-100" style="padding:.5rem;border-radius:8px;font-size:.88rem" onclick="fbToast('❌ Rejected.','error')"><i class="bi bi-x-circle me-1"></i>Reject</button>
              <button class="btn-sm-outline w-100" style="padding:.48rem"><i class="bi bi-telephone me-1"></i>Verify Call</button>
            </div>
          </div>
          <div style="background:#fff3e0;border-radius:8px;padding:.65rem 1rem;margin-top:1rem;display:flex;align-items:center;gap:.6rem;font-size:.82rem">
            <i class="bi bi-person-fill-exclamation" style="color:var(--amber)"></i>
            <span><strong>New Donor</strong> — First donation. Consider verifying via phone before approving.</span>
          </div>
        </div>

        <!-- Card 5 - NORMAL -->
        <div class="approval-card normal" data-filter="normal">
          <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div style="flex:1;min-width:260px">
              <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                <span class="expiry-pill expiry-green"><i class="bi bi-clock"></i> Expires in 8h 00m</span>
                <span class="badge-status badge-pending">Awaiting Approval</span>
                <span style="font-size:.75rem;color:var(--text-muted)">#FB-2025-0088 · Posted 10m ago</span>
              </div>
              <h5 style="font-size:1.05rem;margin-bottom:.6rem">Office Lunch Boxes — TechCorp Pvt Ltd</h5>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> 25 sealed boxes</span>
                <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> Blue Area, Islamabad</span>
                <span class="detail-chip"><i class="bi bi-box-seam"></i> Packaged · Sealed</span>
                <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> Corporate · 🥈 Silver</span>
              </div>
            </div>
            <div class="d-flex flex-column gap-2" style="min-width:180px">
              <button class="btn-green w-100" onclick="fbToast('✅ Approved!')"><i class="bi bi-check2-circle me-1"></i>Approve</button>
              <button class="btn-sm-red w-100" style="padding:.5rem;border-radius:8px;font-size:.88rem" onclick="fbToast('❌ Rejected.','error')"><i class="bi bi-x-circle me-1"></i>Reject</button>
              <button class="btn-sm-outline w-100" style="padding:.48rem"><i class="bi bi-eye me-1"></i>View Details</button>
            </div>
          </div>
        </div>

      </div>

      <!-- Bulk Actions -->
      <div class="fb-card mt-4" style="background:var(--white)">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
          <div>
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.2rem">Bulk Actions</h6>
            <p style="font-size:.83rem;color:var(--text-muted);margin:0">Approve all trusted (Gold/Silver) donors at once, or export pending list.</p>
          </div>
          <div class="d-flex flex-wrap gap-2">
            <button class="btn-green" onclick="fbToast('✅ All Gold/Silver donor donations approved! NGOs notified.')"><i class="bi bi-check2-all me-1"></i>Approve All Trusted</button>
            <button class="btn-sm-outline px-3 py-2" style="border-radius:8px" onclick="fbToast('List exported!')"><i class="bi bi-download me-1"></i>Export Pending List</button>
          </div>
        </div>
      </div>

      <!-- Recently Processed -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Recently Processed (Today)</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">ID</th><th>Donor</th><th>Food</th><th>Qty</th><th>Decision</th><th>Time</th><th>Reason</th></tr></thead>
            <tbody>
              <tr><td class="ps-3">#0087</td><td>Bake House LHR</td><td>Pastries</td><td>40 items</td><td><span class="badge-status badge-accepted">Approved</span></td><td>10:30 AM</td><td>—</td></tr>
              <tr><td class="ps-3">#0086</td><td>user_4427</td><td>Unknown</td><td>200 plates</td><td><span class="badge-status badge-rejected">Rejected</span></td><td>09:15 AM</td><td>Fraud flag</td></tr>
              <tr><td class="ps-3">#0085</td><td>Punjab Festival</td><td>Desi Dishes</td><td>500 plates</td><td><span class="badge-status badge-accepted">Approved</span></td><td>08:00 AM</td><td>—</td></tr>
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
document.querySelectorAll('.filter-tab').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.filter-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const val = btn.dataset.filter;
    document.querySelectorAll('[data-filter]').forEach(card => {
      if (card.classList.contains('approval-card')) {
        card.style.display = (val === 'all' || card.dataset.filter === val) ? '' : 'none';
      }
    });
  });
});
</script>
</body>
</html>
