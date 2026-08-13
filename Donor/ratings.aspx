<%@ Page Title="Ratings & Trust – FoodBridge" Language="C#" MasterPageFile="~/Donor/DonorMaster.master" AutoEventWireup="true" CodeBehind="ratings.aspx.cs" Inherits="LeftoverFood.Donor.ratings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="DonorHeadContent" runat="server">
  <style>
    .star-row { display:flex; gap:.25rem; }
    .star-row i { font-size:1.1rem; color:#fbbf24; }
    .star-row i.empty { color:var(--sand-dark); }
    .trust-badge { display:inline-flex; align-items:center; gap:.4rem; padding:.35rem .9rem; border-radius:50px; font-size:.8rem; font-weight:700; }
    .trust-gold    { background:#fef3c7; color:#92400e; }
    .trust-silver  { background:#f1f5f9; color:#475569; }
    .trust-bronze  { background:#fef3c7; color:#78350f; }
    .trust-new     { background:var(--sand); color:var(--text-muted); }
    .trust-flagged { background:#fee2e2; color:#dc2626; }
    .review-card { background:var(--cream); border-radius:10px; padding:1rem 1.2rem; border-left:3px solid var(--green-light); }
    .rating-stars-input { display:flex; gap:.3rem; flex-direction:row-reverse; justify-content:flex-end; }
    .rating-stars-input input { display:none; }
    .rating-stars-input label { font-size:1.6rem; color:var(--sand-dark); cursor:pointer; transition:color .15s; }
    .rating-stars-input label:hover,
    .rating-stars-input label:hover ~ label,
    .rating-stars-input input:checked ~ label { color:#fbbf24; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="DonorPageHeading" runat="server">Ratings & Trust System</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="DonorMainContent" runat="server">

      <div class="row g-4 mb-4">

        <!-- My Trust Profile -->
        <div class="col-lg-4">
          <div class="fb-card text-center" style="background:linear-gradient(145deg,var(--white),#f9fbf9)">
            <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,var(--green),var(--green-mid));color:#fff;display:flex;align-items:center;justify-content:center;font-family:'DM Serif Display',serif;font-size:2rem;margin:0 auto 1rem"><%= LeftoverFoodSystem.SessionHelper.Initials(LeftoverFoodSystem.SessionHelper.GetFullName()) %></div>
            <h5 style="margin-bottom:.2rem"><%= LeftoverFoodSystem.SessionHelper.GetFullName() %></h5>
            <div style="margin-bottom:1rem"><span class="trust-badge trust-gold">🥇 Gold Donor</span></div>
            <div class="star-row justify-content-center mb-1">
              <i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-half"></i>
            </div>
            <div style="font-family:'DM Serif Display',serif;font-size:2.2rem;color:var(--green)">4.8</div>
            <div style="font-size:.8rem;color:var(--text-muted);margin-bottom:1.5rem">Based on 47 donations</div>
            <div class="row g-2 text-center">
              <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--green)">47</div><div style="font-size:.72rem;color:var(--text-muted)">Donations</div></div></div>
              <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--blue)">94%</div><div style="font-size:.72rem;color:var(--text-muted)">Accuracy</div></div></div>
              <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--amber)">0</div><div style="font-size:.72rem;color:var(--text-muted)">Flags</div></div></div>
            </div>
            <div style="margin-top:1.2rem;padding-top:1.2rem;border-top:1.5px solid var(--sand)">
              <div style="font-size:.8rem;color:var(--text-muted);margin-bottom:.8rem">Trust Level Progress</div>
              <div class="fb-progress mb-1"><div class="fb-progress-bar" style="width:78%"></div></div>
              <div style="font-size:.75rem;color:var(--text-muted)">78% to Platinum Level (60 donations)</div>
            </div>
          </div>
        </div>

        <!-- Rating Breakdown -->
        <div class="col-lg-8 d-flex flex-column gap-4">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Rating Breakdown</h6>
            <div class="d-flex align-items-center gap-4 mb-3 flex-wrap">
              <div style="text-align:center">
                <div style="font-family:'DM Serif Display',serif;font-size:4rem;color:var(--green);line-height:1">4.8</div>
                <div class="star-row justify-content-center my-1">
                  <i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-half"></i>
                </div>
                <div style="font-size:.78rem;color:var(--text-muted)">47 reviews</div>
              </div>
              <div style="flex:1">
                <div class="d-flex align-items-center gap-2 mb-2" style="font-size:.83rem">
                  <span style="width:20px;text-align:right">5</span><i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                  <div class="fb-progress" style="flex:1;height:8px"><div class="fb-progress-bar" style="width:74%"></div></div>
                  <span style="width:28px;color:var(--text-muted)">35</span>
                </div>
                <div class="d-flex align-items-center gap-2 mb-2" style="font-size:.83rem">
                  <span style="width:20px;text-align:right">4</span><i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                  <div class="fb-progress" style="flex:1;height:8px"><div class="fb-progress-bar" style="width:17%"></div></div>
                  <span style="width:28px;color:var(--text-muted)">8</span>
                </div>
                <div class="d-flex align-items-center gap-2 mb-2" style="font-size:.83rem">
                  <span style="width:20px;text-align:right">3</span><i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                  <div class="fb-progress" style="flex:1;height:8px"><div class="fb-progress-bar" style="width:6%;background:var(--amber)"></div></div>
                  <span style="width:28px;color:var(--text-muted)">3</span>
                </div>
                <div class="d-flex align-items-center gap-2 mb-2" style="font-size:.83rem">
                  <span style="width:20px;text-align:right">2</span><i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                  <div class="fb-progress" style="flex:1;height:8px"><div class="fb-progress-bar" style="width:2%;background:var(--red)"></div></div>
                  <span style="width:28px;color:var(--text-muted)">1</span>
                </div>
                <div class="d-flex align-items-center gap-2" style="font-size:.83rem">
                  <span style="width:20px;text-align:right">1</span><i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                  <div class="fb-progress" style="flex:1;height:8px"><div class="fb-progress-bar" style="width:0%"></div></div>
                  <span style="width:28px;color:var(--text-muted)">0</span>
                </div>
              </div>
            </div>
            <div style="background:var(--cream);border-radius:10px;padding:1rem;display:flex;flex-wrap:wrap;gap:1rem">
              <div style="text-align:center;flex:1;min-width:80px"><div style="font-weight:700;color:var(--green)">4.9</div><div style="font-size:.75rem;color:var(--text-muted)">Food Quality</div></div>
              <div style="text-align:center;flex:1;min-width:80px"><div style="font-weight:700;color:var(--green)">4.8</div><div style="font-size:.75rem;color:var(--text-muted)">Quantity Accuracy</div></div>
              <div style="text-align:center;flex:1;min-width:80px"><div style="font-weight:700;color:var(--green)">4.7</div><div style="font-size:.75rem;color:var(--text-muted)">Packaging</div></div>
              <div style="text-align:center;flex:1;min-width:80px"><div style="font-weight:700;color:var(--blue)">4.8</div><div style="font-size:.75rem;color:var(--text-muted)">Punctuality</div></div>
            </div>
          </div>

          <!-- Leave a Rating -->
          <div class="fb-card" style="border:2px solid var(--green-pale)">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Rate a Completed Donation</h6>
            <div class="fb-form-group">
              <label>Select Donation</label>
              <select class="fb-input fb-select">
                <option>#FB-2025-0045 — Biryani & Naan (Apr 18) — Delivered</option>
                <option>#FB-2025-0041 — Dal & Roti (Apr 15) — Delivered</option>
                <option>#FB-2025-0038 — Desi Dishes (Apr 12) — Delivered</option>
              </select>
            </div>
            <div class="fb-form-group">
              <label>Your Rating</label>
              <div class="rating-stars-input">
                <input type="radio" id="s5" name="rating" value="5"/><label for="s5"><i class="bi bi-star-fill"></i></label>
                <input type="radio" id="s4" name="rating" value="4"/><label for="s4"><i class="bi bi-star-fill"></i></label>
                <input type="radio" id="s3" name="rating" value="3"/><label for="s3"><i class="bi bi-star-fill"></i></label>
                <input type="radio" id="s2" name="rating" value="2"/><label for="s2"><i class="bi bi-star-fill"></i></label>
                <input type="radio" id="s1" name="rating" value="1"/><label for="s1"><i class="bi bi-star-fill"></i></label>
              </div>
            </div>
            <div class="fb-form-group mb-3">
              <label>Comments</label>
              <textarea class="fb-input fb-textarea" style="min-height:75px" placeholder="How was the experience? Was food quality good? Did volunteer arrive on time?"></textarea>
            </div>
            <button class="btn-green" onclick="fbToast('Rating submitted! Thank you for your feedback.')"><i class="bi bi-send me-1"></i>Submit Rating</button>
          </div>
        </div>
      </div>

      <!-- Reviews Received -->
      <div class="fb-card mb-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Reviews Received</h6>
          <select class="fb-input fb-select" style="width:auto;font-size:.83rem;padding:.35rem .8rem;border-radius:50px">
            <option>All Reviews</option><option>5 Star</option><option>4 Star</option><option>3 Star & below</option>
          </select>
        </div>
        <div class="d-flex flex-column gap-3">
          <div class="review-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="d-flex align-items-center gap-2">
                <div class="fb-avatar" style="background:var(--amber-light);color:var(--amber);width:32px;height:32px;font-size:.75rem">EF</div>
                <div><div style="font-size:.88rem;font-weight:600">Edhi Foundation <span class="badge-status badge-role-ngo ms-1">NGO</span></div><div style="font-size:.75rem;color:var(--text-muted)">Donation #FB-2025-0047 · Apr 21</div></div>
              </div>
              <div class="star-row"><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i></div>
            </div>
            <p style="font-size:.87rem;color:var(--text-mid);margin:0">Excellent donation! Food was properly packed, quantity was accurate, and the donor was cooperative and responsive. 30 plates fed 30 families at our center. Highly appreciated.</p>
          </div>
          <div class="review-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="d-flex align-items-center gap-2">
                <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue);width:32px;height:32px;font-size:.75rem">UA</div>
                <div><div style="font-size:.88rem;font-weight:600">Usman Ali <span class="badge-status badge-role-vol ms-1">Volunteer</span></div><div style="font-size:.75rem;color:var(--text-muted)">Donation #FB-2025-0045 · Apr 18</div></div>
              </div>
              <div class="star-row"><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill empty"></i></div>
            </div>
            <p style="font-size:.87rem;color:var(--text-mid);margin:0">Good donation. Food was ready on time. I'd suggest using more sealed containers for easier transport. Overall a smooth pickup.</p>
          </div>
          <div class="review-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="d-flex align-items-center gap-2">
                <div class="fb-avatar" style="background:#e8f5ee;color:var(--green);width:32px;height:32px;font-size:.75rem">SA</div>
                <div><div style="font-size:.88rem;font-weight:600">Saylani Welfare <span class="badge-status badge-role-ngo ms-1">NGO</span></div><div style="font-size:.75rem;color:var(--text-muted)">Donation #FB-2025-0038 · Apr 12</div></div>
              </div>
              <div class="star-row"><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i><i class="bi bi-star-fill"></i></div>
            </div>
            <p style="font-size:.87rem;color:var(--text-mid);margin:0">Amazing contribution! 500 plates served at our Lahore center. Donor was very professional and the food quality was outstanding. We hope to receive more donations from this donor.</p>
          </div>
        </div>
      </div>

      <!-- Trust Levels Table -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Trust Level System</h6>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Level</th><th>Badge</th><th>Requirements</th><th>Benefits</th></tr></thead>
            <tbody>
              <tr><td class="ps-3"><strong>New Donor</strong></td><td><span class="trust-badge trust-new">🆕 New</span></td><td>0–4 donations</td><td>Basic posting access</td></tr>
              <tr><td class="ps-3"><strong>Bronze</strong></td><td><span class="trust-badge trust-bronze">🥉 Bronze</span></td><td>5–19 donations, 4.0+ rating</td><td>Priority review, email cert</td></tr>
              <tr><td class="ps-3"><strong>Silver</strong></td><td><span class="trust-badge trust-silver">🥈 Silver</span></td><td>20–39 donations, 4.5+ rating</td><td>Auto-approval, featured listing</td></tr>
              <tr style="background:#fffbeb"><td class="ps-3"><strong>Gold ← You</strong></td><td><span class="trust-badge trust-gold">🥇 Gold</span></td><td>40–59 donations, 4.7+ rating</td><td>Auto-assign NGO, priority queue</td></tr>
              <tr><td class="ps-3"><strong>Platinum</strong></td><td><span class="trust-badge" style="background:var(--purple-light);color:var(--purple)">💎 Platinum</span></td><td>60+ donations, 4.8+ rating</td><td>VIP badge, admin dashboard access</td></tr>
              <tr><td class="ps-3"><strong>Flagged</strong></td><td><span class="trust-badge trust-flagged">🚩 Flagged</span></td><td>3+ fake/expired reports</td><td>Restricted access, review required</td></tr>
            </tbody>
          </table>
        </div>
      </div>

</asp:Content>
