<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="track-donation.aspx.cs" Inherits="LeftoverFood.Donor.track_donation" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Track Donation – FoodBridge</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
  <style>
    .track-step { display:flex; gap:1.2rem; position:relative; padding-bottom:2rem; }
    .track-step:last-child { padding-bottom:0; }
    .track-step::before { content:''; position:absolute; left:19px; top:40px; bottom:0; width:2px; background:var(--sand-dark); }
    .track-step:last-child::before { display:none; }
    .step-circle { width:40px; height:40px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:1.1rem; flex-shrink:0; border:2px solid var(--sand-dark); background:var(--white); position:relative; z-index:1; }
    .step-circle.done { background:var(--green); border-color:var(--green); color:#fff; }
    .step-circle.done ~ .track-step::before { background:var(--green); }
    .step-circle.active { background:var(--amber); border-color:var(--amber); color:#fff; }
    .step-circle.pending { background:var(--white); border-color:var(--sand-dark); color:var(--text-muted); }
    .track-line-done { background:var(--green) !important; }
    .map-placeholder { background:linear-gradient(145deg,#e8f5ee,#d0f0e0); border-radius:var(--radius); height:320px; display:flex; flex-direction:column; align-items:center; justify-content:center; border:2px dashed var(--green-light); }
    .expiry-bar { height:10px; border-radius:50px; background:var(--sand); overflow:hidden; }
    .expiry-fill { height:100%; border-radius:50px; transition:width .5s; }
    .info-row { display:flex; justify-content:space-between; padding:.65rem 0; border-bottom:1px solid var(--sand); font-size:.9rem; }
    .info-row:last-child { border-bottom:none; }
  </style>
</head>
<body style="background:var(--cream)">

<!-- NAVBAR -->
<nav class="navbar navbar-expand-lg fb-navbar">
  <div class="container">
    <a class="navbar-brand" href="index.html"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></a>
    <div class="ms-auto d-flex gap-2">
      <a href="donor-dashboard.html" class="nav-link btn-nav-login"><i class="bi bi-grid me-1"></i>Dashboard</a>
    </div>
  </div>
</nav>

<div style="padding:40px 0 80px">
  <div class="container" style="max-width:1100px">

    <!-- Header -->
    <div class="d-flex flex-wrap justify-content-between align-items-start mb-4 gap-3">
      <div>
        <a href="donor-dashboard.html" style="font-size:.85rem;color:var(--text-muted);display:flex;align-items:center;gap:.4rem;margin-bottom:.6rem"><i class="bi bi-arrow-left"></i> Back to Dashboard</a>
        <h1 style="font-size:1.9rem;margin-bottom:.2rem">Track Donation #FB-2025-0047</h1>
        <p class="text-muted" style="font-size:.9rem">Posted on April 21, 2025 &nbsp;|&nbsp; Ali's Restaurant, Karachi</p>
      </div>
      <div class="d-flex gap-2">
        <button class="btn-sm-outline" onclick="fbToast('Tracking link copied!')"><i class="bi bi-share me-1"></i>Share</button>
        <button class="btn-sm-outline"><i class="bi bi-printer me-1"></i>Print</button>
      </div>
    </div>

    <div class="row g-4">

      <!-- LEFT: Status Timeline + Map -->
      <div class="col-lg-7 d-flex flex-column gap-4">

        <!-- Status Timeline -->
        <div class="fb-card">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h5 style="font-family:'DM Serif Display',serif;margin:0">Live Status Timeline</h5>
            <span class="badge-status badge-accepted" style="font-size:.82rem;padding:.35rem 1rem">● In Transit</span>
          </div>

          <!-- Step 1: Posted -->
          <div class="track-step">
            <div class="step-circle done"><i class="bi bi-check2"></i></div>
            <div class="pt-1">
              <div style="font-weight:700;font-size:.95rem;color:var(--green)">Food Posted</div>
              <div style="font-size:.82rem;color:var(--text-muted);margin:.15rem 0 .5rem">Apr 21, 2025 &nbsp;·&nbsp; 03:00 PM</div>
              <div style="background:#e8f5ee;border-radius:8px;padding:.6rem .9rem;font-size:.85rem">Biryani & Naan — 30 plates posted by Ali's Restaurant (Gulshan Block 2, Karachi)</div>
            </div>
          </div>
          <div style="width:2px;height:24px;background:var(--green);margin-left:19px;margin-bottom:-4px"></div>

          <!-- Step 2: Approved -->
          <div class="track-step">
            <div class="step-circle done"><i class="bi bi-check2"></i></div>
            <div class="pt-1">
              <div style="font-weight:700;font-size:.95rem;color:var(--green)">Approved by Admin</div>
              <div style="font-size:.82rem;color:var(--text-muted);margin:.15rem 0 .5rem">Apr 21, 2025 &nbsp;·&nbsp; 03:18 PM</div>
              <div style="background:#e8f5ee;border-radius:8px;padding:.6rem .9rem;font-size:.85rem">Donation verified and approved. NGO notification sent to Edhi Foundation.</div>
            </div>
          </div>
          <div style="width:2px;height:24px;background:var(--green);margin-left:19px;margin-bottom:-4px"></div>

          <!-- Step 3: Accepted by NGO -->
          <div class="track-step">
            <div class="step-circle done"><i class="bi bi-check2"></i></div>
            <div class="pt-1">
              <div style="font-weight:700;font-size:.95rem;color:var(--green)">Accepted by NGO</div>
              <div style="font-size:.82rem;color:var(--text-muted);margin:.15rem 0 .5rem">Apr 21, 2025 &nbsp;·&nbsp; 03:45 PM</div>
              <div style="background:#e8f5ee;border-radius:8px;padding:.6rem .9rem;font-size:.85rem">Edhi Foundation accepted the request. Volunteer Usman Ali assigned for pickup.</div>
            </div>
          </div>
          <div style="width:2px;height:24px;background:var(--green);margin-left:19px;margin-bottom:-4px"></div>

          <!-- Step 4: Picked Up (Active) -->
          <div class="track-step">
            <div class="step-circle active"><i class="bi bi-truck"></i></div>
            <div class="pt-1">
              <div style="font-weight:700;font-size:.95rem;color:var(--amber)">Picked Up — In Transit ● LIVE</div>
              <div style="font-size:.82rem;color:var(--text-muted);margin:.15rem 0 .5rem">Apr 21, 2025 &nbsp;·&nbsp; 05:10 PM</div>
              <div style="background:#fff3e0;border-radius:8px;padding:.6rem .9rem;font-size:.85rem">Usman Ali picked up the food. Currently en route to Edhi Center, Saddar. ETA: ~20 mins.</div>
            </div>
          </div>
          <div style="width:2px;height:24px;background:var(--sand-dark);margin-left:19px;margin-bottom:-4px"></div>

          <!-- Step 5: Delivered (Pending) -->
          <div class="track-step" style="opacity:.5">
            <div class="step-circle pending"><i class="bi bi-geo-alt-fill"></i></div>
            <div class="pt-1">
              <div style="font-weight:700;font-size:.95rem">Delivered to NGO</div>
              <div style="font-size:.82rem;color:var(--text-muted)">Awaiting confirmation...</div>
            </div>
          </div>

          <!-- Volunteer Info -->
          <div style="background:var(--cream);border-radius:10px;padding:1rem;display:flex;align-items:center;gap:1rem;margin-top:1.2rem">
            <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue);width:44px;height:44px;font-size:1rem">UA</div>
            <div style="flex:1">
              <div style="font-weight:600;font-size:.9rem">Usman Ali &nbsp;<span class="badge-status badge-role-vol">Volunteer</span></div>
              <div style="font-size:.8rem;color:var(--text-muted)">⭐ 4.9 rating &nbsp;·&nbsp; 87 deliveries</div>
            </div>
            <button class="btn-sm-green px-3"><i class="bi bi-telephone me-1"></i>Call</button>
          </div>
        </div>

        <!-- Google Maps Placeholder -->
        <div class="fb-card p-0 overflow-hidden">
          <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);display:flex;justify-content:space-between;align-items:center">
            <h6 style="font-family:'DM Serif Display',serif;margin:0"><i class="bi bi-geo-alt-fill me-2 text-success"></i>Live Delivery Map</h6>
            <span style="font-size:.78rem;color:var(--text-muted)">Google Maps API integration</span>
          </div>
          <div class="map-placeholder" style="border-radius:0;border:none">
            <i class="bi bi-map-fill" style="font-size:3rem;color:var(--green-mid);opacity:.5;margin-bottom:1rem"></i>
            <div style="font-weight:600;color:var(--green)">Interactive Map — Google Maps API</div>
            <div style="font-size:.85rem;color:var(--text-muted);margin-top:.4rem;text-align:center;max-width:350px">Shows real-time volunteer location, donor pickup point, and NGO drop-off destination. Requires Google Maps API key in production.</div>
            <div class="d-flex gap-3 mt-4" style="font-size:.82rem">
              <div style="display:flex;align-items:center;gap:.4rem"><span style="width:12px;height:12px;border-radius:50%;background:var(--green);display:inline-block"></span>Donor Location</div>
              <div style="display:flex;align-items:center;gap:.4rem"><span style="width:12px;height:12px;border-radius:50%;background:var(--amber);display:inline-block"></span>Volunteer (Live)</div>
              <div style="display:flex;align-items:center;gap:.4rem"><span style="width:12px;height:12px;border-radius:50%;background:var(--red);display:inline-block"></span>NGO Drop-off</div>
            </div>
          </div>
        </div>

      </div>

      <!-- RIGHT: Donation Details + Expiry -->
      <div class="col-lg-5 d-flex flex-column gap-4">

        <!-- Donation Info -->
        <div class="fb-card">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Donation Details</h6>
          <div class="info-row"><span class="text-muted">Donation ID</span><strong>#FB-2025-0047</strong></div>
          <div class="info-row"><span class="text-muted">Food Type</span><strong>Biryani & Naan</strong></div>
          <div class="info-row"><span class="text-muted">Category</span><strong>Cooked Meals</strong></div>
          <div class="info-row"><span class="text-muted">Quantity</span><strong>30 plates</strong></div>
          <div class="info-row"><span class="text-muted">Servings</span><strong>~30 people</strong></div>
          <div class="info-row"><span class="text-muted">Dietary</span><strong><span class="badge-status badge-verified">Halal</span></strong></div>
          <div class="info-row"><span class="text-muted">Donor</span><strong>Ali's Restaurant</strong></div>
          <div class="info-row"><span class="text-muted">Pickup Location</span><strong>Gulshan Block 2, Karachi</strong></div>
          <div class="info-row"><span class="text-muted">NGO Assigned</span><strong>Edhi Foundation</strong></div>
          <div class="info-row"><span class="text-muted">Volunteer</span><strong>Usman Ali</strong></div>
        </div>

        <!-- Expiry Tracker -->
        <div class="fb-card">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem"><i class="bi bi-clock-fill me-2 text-warning"></i>Expiry Time Tracker</h6>
          <div style="text-align:center;padding:1rem 0">
            <div style="font-family:'DM Serif Display',serif;font-size:2.8rem;color:var(--amber);line-height:1">1h 42m</div>
            <div style="font-size:.82rem;color:var(--text-muted);margin-top:.3rem">Remaining before expiry (8:00 PM)</div>
          </div>
          <div class="expiry-bar mb-2"><div class="expiry-fill" style="width:72%;background:var(--amber)"></div></div>
          <div style="display:flex;justify-content:space-between;font-size:.75rem;color:var(--text-muted)">
            <span>Posted 3:00 PM</span><span>Expires 8:00 PM</span>
          </div>
          <div style="background:#fff3e0;border-radius:8px;padding:.75rem;margin-top:1rem;font-size:.83rem;color:#92400e">
            <i class="bi bi-exclamation-triangle-fill me-1"></i>Food is currently in transit. Delivery expected before expiry.
          </div>
        </div>

        <!-- Notifications Log -->
        <div class="fb-card">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem"><i class="bi bi-envelope-fill me-2" style="color:var(--blue)"></i>Email Notifications Sent</h6>
          <div class="timeline">
            <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">3:00 PM – To Donor</div><div class="tl-text">Donation posted confirmation sent to ali@restaurant.pk</div></div>
            <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">3:18 PM – To NGO</div><div class="tl-text">Approval notification sent to edhi@foundation.org</div></div>
            <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">3:45 PM – To Volunteer</div><div class="tl-text">Pickup assignment sent to usman@volunteer.pk</div></div>
            <div class="tl-item"><div class="tl-dot" style="background:var(--amber)"></div><div class="tl-time">5:10 PM – To Donor</div><div class="tl-text">Food picked up notification sent</div></div>
          </div>
          <div style="font-size:.78rem;color:var(--text-muted);margin-top:.8rem"><i class="bi bi-info-circle me-1"></i>Powered by SMTP Email Service (configured in system settings)</div>
        </div>

        <!-- Rating (post-delivery) -->
        <div class="fb-card" style="opacity:.6">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.5rem">Rate This Donation</h6>
          <div style="font-size:.83rem;color:var(--text-muted);margin-bottom:1rem">Available after delivery is confirmed</div>
          <div class="d-flex gap-1 mb-2">
            <i class="bi bi-star" style="font-size:1.5rem;color:var(--sand-dark)"></i>
            <i class="bi bi-star" style="font-size:1.5rem;color:var(--sand-dark)"></i>
            <i class="bi bi-star" style="font-size:1.5rem;color:var(--sand-dark)"></i>
            <i class="bi bi-star" style="font-size:1.5rem;color:var(--sand-dark)"></i>
            <i class="bi bi-star" style="font-size:1.5rem;color:var(--sand-dark)"></i>
          </div>
          <textarea class="fb-input fb-textarea" style="min-height:70px;font-size:.85rem" placeholder="Leave feedback about this donation..." disabled></textarea>
          <button class="btn-green mt-2" disabled>Submit Rating</button>
        </div>

      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../js/main.js"></script>
</body>
</html>
