<%@ Page Title="My Profile – FoodBridge" Language="C#" MasterPageFile="~/Donor/DonorMaster.master" AutoEventWireup="true" CodeBehind="profile.aspx.cs" Inherits="LeftoverFood.Donor.profile" %>

<asp:Content ID="Content1" ContentPlaceHolderID="DonorHeadContent" runat="server">
  <style>
    .profile-hero { background:linear-gradient(135deg, var(--green), #1b4332); border-radius:var(--radius-lg); padding:2.5rem; color:#fff; position:relative; overflow:hidden; }
    .profile-hero::after { content:''; position:absolute; width:300px; height:300px; background:rgba(255,255,255,.05); border-radius:50%; top:-80px; right:-60px; }
    .avatar-upload { position:relative; display:inline-block; }
    .avatar-upload .avatar-main { width:90px; height:90px; border-radius:50%; background:rgba(255,255,255,.2); color:#fff; display:flex; align-items:center; justify-content:center; font-family:'DM Serif Display',serif; font-size:2.2rem; border:3px solid rgba(255,255,255,.4); }
    .avatar-upload .edit-btn { position:absolute; bottom:0; right:0; width:28px; height:28px; background:var(--amber); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:.7rem; color:#fff; cursor:pointer; }
    .section-heading { font-family:'DM Serif Display',serif; font-size:1.1rem; padding-bottom:.6rem; border-bottom:1.5px solid var(--sand); margin-bottom:1.2rem; display:flex; align-items:center; gap:.6rem; }
    .section-heading i { font-size:1rem; }
    .change-pw-toggle { color:var(--green); font-size:.85rem; font-weight:600; cursor:pointer; text-decoration:underline; }
    .activity-item { display:flex; align-items:flex-start; gap:.9rem; padding:.7rem 0; border-bottom:1px solid var(--sand); }
    .activity-item:last-child { border-bottom:none; }
    .act-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:.9rem; flex-shrink:0; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="DonorPageHeading" runat="server">My Profile</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="DonorMainContent" runat="server">

      <!-- Profile Hero -->
      <div class="profile-hero mb-4">
        <div class="d-flex flex-wrap align-items-center gap-4">
          <div class="avatar-upload">
            <div class="avatar-main"><%= LeftoverFoodSystem.SessionHelper.Initials(LeftoverFoodSystem.SessionHelper.GetFullName()) %></div>
            <div class="edit-btn" onclick="fbToast('Photo upload coming soon!')"><i class="bi bi-camera-fill"></i></div>
          </div>
          <div style="flex:1;min-width:200px">
            <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;margin-bottom:.3rem"><%= LeftoverFoodSystem.SessionHelper.GetFullName() %></div>
            <div style="display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;font-size:.85rem;opacity:.85;margin-bottom:.6rem">
              <span class="badge-status badge-role-donor" style="background:rgba(255,255,255,.2);color:#fff">Donor</span>
              <span><i class="bi bi-geo-alt me-1"></i>Karachi, Pakistan</span>
              <span><i class="bi bi-calendar3 me-1"></i>Member since Jan 2025</span>
            </div>
            <div style="display:flex;flex-wrap:wrap;gap:1.5rem;font-size:.85rem">
              <span><strong>47</strong> Donations</span>
              <span><strong>⭐ 4.8</strong> Rating</span>
              <span><strong>🥇 Gold</strong> Donor</span>
              <span><strong>1,240</strong> Meals Served</span>
            </div>
          </div>
          <div>
            <span style="background:rgba(255,255,255,.15);border:1.5px solid rgba(255,255,255,.3);color:#fff;border-radius:50px;padding:.4rem 1.1rem;font-size:.83rem;font-weight:600;display:inline-flex;align-items:center;gap:.4rem"><i class="bi bi-shield-check-fill text-success"></i> Verified Account</span>
          </div>
        </div>
      </div>

      <div class="row g-4">

        <!-- Left: Edit Form -->
        <div class="col-lg-7 d-flex flex-column gap-4">

          <!-- Personal Info -->
          <div class="fb-card">
            <div class="section-heading"><i class="bi bi-person-fill text-success"></i>Personal Information</div>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Full Name</label><input type="text" class="fb-input" value="Ahmed Khan"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Username</label><input type="text" class="fb-input" value="ahmed_donor" readonly style="background:var(--cream);color:var(--text-muted)"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Email Address <i class="bi bi-patch-check-fill text-success ms-1" style="font-size:.8rem"></i></label><input type="email" class="fb-input" value="ahmed@restaurant.pk"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Phone Number <i class="bi bi-patch-check-fill text-success ms-1" style="font-size:.8rem"></i></label><input type="tel" class="fb-input" value="+92 300 1234567"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>Role</label>
                  <select class="fb-input fb-select" disabled style="background:var(--cream)">
                    <option selected>Food Donor (Restaurant)</option>
                  </select>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0">
                  <label>City</label>
                  <select class="fb-input fb-select">
                    <option>Karachi</option><option>Lahore</option><option>Islamabad</option>
                    <option>Rawalpindi</option><option>Peshawar</option>
                  </select>
                </div>
              </div>
              <div class="col-12">
                <div class="fb-form-group mb-0"><label>Address / Pickup Location</label><input type="text" class="fb-input" value="Ali's Restaurant, Gulshan Block 2, Karachi"/></div>
              </div>
              <div class="col-12">
                <div class="fb-form-group mb-0"><label>About / Bio</label><textarea class="fb-input fb-textarea" style="min-height:80px">Ali's Restaurant has been serving Karachi for 10+ years. We donate leftover biryani and naan regularly to help the community.</textarea></div>
              </div>
            </div>
            <button class="btn-green mt-3" onclick="fbToast('Profile updated successfully!')"><i class="bi bi-check2 me-1"></i>Save Changes</button>
          </div>

          <!-- Donor-Specific Info -->
          <div class="fb-card">
            <div class="section-heading"><i class="bi bi-shop text-warning"></i>Restaurant / Organization Details</div>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Organization Name</label><input type="text" class="fb-input" value="Ali's Restaurant"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Business Type</label>
                  <select class="fb-input fb-select"><option selected>Restaurant</option><option>Hotel</option><option>Catering</option><option>Home Kitchen</option></select>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>CNIC / Business Reg No.</label><input type="text" class="fb-input" value="42201-1234567-1"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Typical Donation Frequency</label>
                  <select class="fb-input fb-select"><option>Daily</option><option selected>Weekly</option><option>Monthly</option><option>Occasional</option></select>
                </div>
              </div>
              <div class="col-12">
                <div class="fb-form-group mb-0"><label>Preferred NGO Partners</label>
                  <input type="text" class="fb-input" value="Edhi Foundation, Saylani Welfare" placeholder="Optional — leave blank for auto-assign"/>
                </div>
              </div>
            </div>
            <button class="btn-green mt-3" onclick="fbToast('Organization info saved!')"><i class="bi bi-check2 me-1"></i>Save</button>
          </div>

          <!-- Change Password -->
          <div class="fb-card">
            <div class="section-heading"><i class="bi bi-lock-fill" style="color:var(--purple)"></i>Change Password</div>
            <div class="row g-3">
              <div class="col-12">
                <div class="fb-form-group mb-0"><label>Current Password</label><input type="password" class="fb-input" placeholder="Enter current password"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>New Password</label><input type="password" class="fb-input" placeholder="Min 8 characters"/></div>
              </div>
              <div class="col-sm-6">
                <div class="fb-form-group mb-0"><label>Confirm New Password</label><input type="password" class="fb-input" placeholder="Repeat new password"/></div>
              </div>
            </div>
            <div style="background:var(--cream);border-radius:8px;padding:.7rem;margin-top:.8rem;font-size:.8rem;color:var(--text-muted)">
              <i class="bi bi-info-circle me-1"></i>Password must be at least 8 characters with 1 number and 1 special character.
            </div>
            <button class="btn-sm-outline mt-3 px-4 py-2" style="border-radius:8px" onclick="fbToast('Password changed successfully!')"><i class="bi bi-lock-fill me-1"></i>Update Password</button>
          </div>

          <!-- Danger Zone -->
          <div class="fb-card" style="border-color:#fecaca">
            <div class="section-heading" style="color:#dc2626;border-color:#fecaca"><i class="bi bi-exclamation-triangle-fill"></i>Danger Zone</div>
            <div class="d-flex flex-wrap gap-3 align-items-center justify-content-between">
              <div>
                <div style="font-weight:600;font-size:.9rem;margin-bottom:.2rem">Deactivate Account</div>
                <div style="font-size:.82rem;color:var(--text-muted)">Temporarily pause your account. You can reactivate anytime.</div>
              </div>
              <button class="btn-sm-outline px-3 py-2" style="border-color:#fecaca;color:#dc2626;border-radius:8px" onclick="fbToast('Deactivation request sent to admin.','error')">Deactivate</button>
            </div>
            <hr style="border-color:#fecaca;margin:1rem 0"/>
            <div class="d-flex flex-wrap gap-3 align-items-center justify-content-between">
              <div>
                <div style="font-weight:600;font-size:.9rem;margin-bottom:.2rem">Delete Account</div>
                <div style="font-size:.82rem;color:var(--text-muted)">Permanently delete your account and all donation history.</div>
              </div>
              <button class="btn-sm-red px-3 py-2" style="border-radius:8px" onclick="if(confirm('Are you sure? This cannot be undone.')) fbToast('Account deletion request submitted.','error')">Delete Account</button>
            </div>
          </div>

        </div>

        <!-- Right: Stats + Activity -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Trust & Badges -->
          <div class="fb-card" style="background:linear-gradient(145deg,var(--green),#1b4332);color:#fff">
            <div style="font-family:'DM Serif Display',serif;font-size:1.1rem;margin-bottom:1.2rem">Trust Level & Badges</div>
            <div style="display:flex;align-items:center;gap:1rem;background:rgba(255,255,255,.12);border-radius:10px;padding:1rem;margin-bottom:1rem">
              <div style="font-size:2.5rem">🥇</div>
              <div><div style="font-weight:700">Gold Donor</div><div style="font-size:.78rem;opacity:.75">47 donations · 4.8★ rating</div></div>
            </div>
            <div style="font-size:.8rem;opacity:.7;margin-bottom:.5rem">Progress to Platinum (60 donations)</div>
            <div style="background:rgba(255,255,255,.2);border-radius:50px;height:8px;overflow:hidden;margin-bottom:.4rem">
              <div style="background:var(--green-light);height:100%;width:78%;border-radius:50px"></div>
            </div>
            <div style="font-size:.75rem;opacity:.65">13 more donations needed</div>
            <div style="margin-top:1.2rem;display:flex;flex-wrap:wrap;gap:.5rem">
              <span style="background:rgba(255,255,255,.15);color:#fff;border-radius:50px;padding:.25rem .75rem;font-size:.75rem">🎖️ Early Adopter</span>
              <span style="background:rgba(255,255,255,.15);color:#fff;border-radius:50px;padding:.25rem .75rem;font-size:.75rem">🌟 40+ Donations</span>
              <span style="background:rgba(255,255,255,.15);color:#fff;border-radius:50px;padding:.25rem .75rem;font-size:.75rem">✅ Verified Donor</span>
              <span style="background:rgba(255,255,255,.15);color:#fff;border-radius:50px;padding:.25rem .75rem;font-size:.75rem">🍛 1000+ Meals</span>
            </div>
          </div>

          <!-- Account Info -->
          <div class="fb-card">
            <div class="section-heading" style="font-size:.95rem"><i class="bi bi-info-circle-fill text-primary"></i>Account Info</div>
            <div class="d-flex flex-column" style="font-size:.87rem">
              <div style="display:flex;justify-content:space-between;padding:.55rem 0;border-bottom:1px solid var(--sand)"><span class="text-muted">Account ID</span><strong>USR-2025-0031</strong></div>
              <div style="display:flex;justify-content:space-between;padding:.55rem 0;border-bottom:1px solid var(--sand)"><span class="text-muted">Joined</span><strong>January 15, 2025</strong></div>
              <div style="display:flex;justify-content:space-between;padding:.55rem 0;border-bottom:1px solid var(--sand)"><span class="text-muted">Last Login</span><strong>Today, 10:30 AM</strong></div>
              <div style="display:flex;justify-content:space-between;padding:.55rem 0;border-bottom:1px solid var(--sand)"><span class="text-muted">Email Verified</span><strong style="color:var(--green)">✅ Yes</strong></div>
              <div style="display:flex;justify-content:space-between;padding:.55rem 0;border-bottom:1px solid var(--sand)"><span class="text-muted">Phone Verified</span><strong style="color:var(--green)">✅ Yes</strong></div>
              <div style="display:flex;justify-content:space-between;padding:.55rem 0"><span class="text-muted">Account Status</span><span class="badge-status badge-active">Active</span></div>
            </div>
          </div>

          <!-- Recent Activity -->
          <div class="fb-card">
            <div class="section-heading" style="font-size:.95rem"><i class="bi bi-clock-history text-warning"></i>Recent Activity</div>
            <div>
              <div class="activity-item">
                <div class="act-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Donation Delivered — Biryani & Naan</div><div style="font-size:.76rem;color:var(--text-muted)">Today, 6:30 PM · 30 plates · Edhi Foundation</div></div>
              </div>
              <div class="activity-item">
                <div class="act-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-star-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Received 5★ Rating from Edhi Foundation</div><div style="font-size:.76rem;color:var(--text-muted)">Today, 7:00 PM</div></div>
              </div>
              <div class="activity-item">
                <div class="act-icon" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-plus-circle-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Posted New Donation — 30 plates</div><div style="font-size:.76rem;color:var(--text-muted)">Today, 3:00 PM</div></div>
              </div>
              <div class="activity-item">
                <div class="act-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-award-fill"></i></div>
                <div><div style="font-size:.87rem;font-weight:600">Earned 🥇 Gold Badge</div><div style="font-size:.76rem;color:var(--text-muted)">Apr 20, 2025 — 40th donation milestone</div></div>
              </div>
            </div>
          </div>

        </div>
      </div>

</asp:Content>
