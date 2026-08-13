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
<form id="form1" runat="server">

<!-- NAVBAR -->
<nav class="navbar navbar-expand-lg fb-navbar">
  <div class="container">
    <a class="navbar-brand" href="<%= ResolveUrl("~/index.html") %>"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></a>
    <div class="ms-auto d-flex gap-2">
      <a href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>" class="nav-link btn-nav-login"><i class="bi bi-grid me-1"></i>Dashboard</a>
    </div>
  </div>
</nav>

<div style="padding:40px 0 80px">
  <div class="container" style="max-width:1100px">

    <asp:Panel ID="pnlNotFound" runat="server" Visible="false">
      <div class="fb-card" style="text-align:center;color:var(--text-muted)">Donation not found.</div>
    </asp:Panel>

    <asp:Panel ID="pnlContent" runat="server">

    <!-- Header -->
    <div class="d-flex flex-wrap justify-content-between align-items-start mb-4 gap-3">
      <div>
        <a href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>" style="font-size:.85rem;color:var(--text-muted);display:flex;align-items:center;gap:.4rem;margin-bottom:.6rem"><i class="bi bi-arrow-left"></i> Back to Dashboard</a>
        <h1 style="font-size:1.9rem;margin-bottom:.2rem">Track Donation #<asp:Literal ID="litDonationId" runat="server" /></h1>
        <p class="text-muted" style="font-size:.9rem">Posted on <asp:Literal ID="litPostedDate" runat="server" /></p>
      </div>
    </div>

    <div class="row g-4">

      <!-- LEFT: Status Timeline + Map -->
      <div class="col-lg-7 d-flex flex-column gap-4">

        <!-- Status Timeline -->
        <div class="fb-card">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h5 style="font-family:'DM Serif Display',serif;margin:0">Live Status Timeline</h5>
            <span class="badge-status <%= StatusBadgeClass() %>" style="font-size:.82rem;padding:.35rem 1rem">● <%= StatusLabel() %></span>
          </div>

          <asp:Repeater ID="rptSteps" runat="server">
            <ItemTemplate>
              <div class="track-step" style='<%# Eval("StepClass").ToString() == "pending" ? "opacity:.5" : "" %>'>
                <div class='step-circle <%# Eval("StepClass") %>'><i class='bi <%# Eval("Icon") %>'></i></div>
                <div class="pt-1">
                  <div style='font-weight:700;font-size:.95rem;color:<%# Eval("StepClass").ToString() == "done" ? "var(--green)" : (Eval("StepClass").ToString() == "active" ? "var(--amber)" : "inherit") %>'><%# Eval("Title") %></div>
                  <div style="font-size:.82rem;color:var(--text-muted);margin:.15rem 0 .5rem"><%# Eval("When") %></div>
                  <asp:Panel runat="server" Visible='<%# !string.IsNullOrEmpty(Eval("Detail").ToString()) %>'>
                    <div style='background:<%# Eval("StepClass").ToString() == "active" ? "#fff3e0" : "#e8f5ee" %>;border-radius:8px;padding:.6rem .9rem;font-size:.85rem'><%# Eval("Detail") %></div>
                  </asp:Panel>
                </div>
              </div>
            </ItemTemplate>
          </asp:Repeater>

          <!-- Volunteer Info -->
          <asp:Panel ID="pnlVolunteerInfo" runat="server" Visible="false">
            <div style="background:var(--cream);border-radius:10px;padding:1rem;display:flex;align-items:center;gap:1rem;margin-top:1.2rem">
              <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue);width:44px;height:44px;font-size:1rem"><%= LeftoverFoodSystem.SessionHelper.Initials(VolunteerName) %></div>
              <div style="flex:1">
                <div style="font-weight:600;font-size:.9rem"><%= VolunteerName %> &nbsp;<span class="badge-status badge-role-vol">Volunteer</span></div>
              </div>
            </div>
          </asp:Panel>
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
          <div class="info-row"><span class="text-muted">Donation ID</span><strong>#<asp:Literal ID="litDetailId" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Food Type</span><strong><asp:Literal ID="litFoodType" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Category</span><strong><asp:Literal ID="litCategory" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Quantity</span><strong><asp:Literal ID="litQuantity" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Servings</span><strong><asp:Literal ID="litServings" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Dietary</span><strong><asp:Literal ID="litDietary" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Pickup Location</span><strong><asp:Literal ID="litPickupLocation" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">NGO Assigned</span><strong><asp:Literal ID="litNgoAssigned" runat="server" /></strong></div>
          <div class="info-row"><span class="text-muted">Volunteer</span><strong><asp:Literal ID="litVolunteerAssigned" runat="server" /></strong></div>
        </div>

        <!-- Expiry Tracker -->
        <asp:Panel ID="pnlExpiry" runat="server">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem"><i class="bi bi-clock-fill me-2 text-warning"></i>Expiry Time Tracker</h6>
            <div style="text-align:center;padding:1rem 0">
              <div style="font-family:'DM Serif Display',serif;font-size:2.8rem;color:var(--amber);line-height:1"><asp:Literal ID="litTimeRemaining" runat="server" /></div>
              <div style="font-size:.82rem;color:var(--text-muted);margin-top:.3rem">Remaining before expiry (<asp:Literal ID="litExpiryTime" runat="server" />)</div>
            </div>
            <div class="expiry-bar mb-2"><div class="expiry-fill" id="expiryFill" runat="server" style="background:var(--amber)"></div></div>
            <div style="display:flex;justify-content:space-between;font-size:.75rem;color:var(--text-muted)">
              <span>Posted <asp:Literal ID="litPostedTime" runat="server" /></span><span>Expires <asp:Literal ID="litExpiryTime2" runat="server" /></span>
            </div>
          </div>
        </asp:Panel>

        <!-- Notifications -->
        <div class="fb-card">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.5rem"><i class="bi bi-envelope-fill me-2" style="color:var(--blue)"></i>Email Notifications</h6>
          <div style="font-size:.83rem;color:var(--text-muted)">Not yet implemented — donors, NGOs, and volunteers currently rely on their in-app dashboards for status updates.</div>
        </div>

        <!-- Rating (post-delivery) -->
        <div class="fb-card" style="opacity:.6">
          <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.5rem">Rate This Donation</h6>
          <div style="font-size:.83rem;color:var(--text-muted);margin-bottom:1rem">Ratings aren't implemented yet</div>
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

    </asp:Panel>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../assets/js/main.js"></script>
</form>
</body>
</html>
