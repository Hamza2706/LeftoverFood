<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="donate-form.aspx.cs" Inherits="LeftoverFood.Donor.donate_form" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Donate Food – FoodBridge</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet"/>
  <link href="../assets/css/style.css" rel="stylesheet"/>
</head>
<body style="background:var(--cream)">

<!-- NAVBAR -->
<nav class="navbar navbar-expand-lg fb-navbar">
  <div class="container">
    <a class="navbar-brand" href="index.html"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></a>
    <div class="ms-auto d-flex gap-2 align-items-center">
      <a href="donor-dashboard.html" class="nav-link btn-nav-login"><i class="bi bi-grid me-1"></i>Dashboard</a>
    </div>
  </div>
</nav>

<div style="padding:50px 0 80px">
  <div class="container" style="max-width:860px">

    <!-- Header -->
    <div class="text-center mb-5">
      <div style="width:70px;height:70px;background:#e8f5ee;border-radius:18px;display:flex;align-items:center;justify-content:center;margin:0 auto 1.2rem;font-size:2rem;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
      <span class="section-tag">Make a Difference</span>
      <h1 style="font-size:2.2rem;margin-bottom:.5rem">Donate Leftover Food</h1>
      <p class="text-muted">Fill in the details below so an NGO can review and arrange pickup of your surplus food.</p>
    </div>

    <!-- Progress Steps -->
    <div class="d-flex align-items-center justify-content-center mb-5 gap-0">
      <div class="text-center" style="flex:1;max-width:180px">
        <div style="width:36px;height:36px;background:var(--green);color:#fff;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto .5rem;font-weight:700;font-size:.88rem">1</div>
        <div style="font-size:.78rem;font-weight:600;color:var(--green)">Food Details</div>
      </div>
      <div style="flex:1;height:2px;background:var(--sand-dark);max-width:80px"></div>
      <div class="text-center" style="flex:1;max-width:180px">
        <div style="width:36px;height:36px;background:var(--sand-dark);color:#fff;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto .5rem;font-weight:700;font-size:.88rem">2</div>
        <div style="font-size:.78rem;color:var(--text-muted)">Pickup Info</div>
      </div>
      <div style="flex:1;height:2px;background:var(--sand-dark);max-width:80px"></div>
      <div class="text-center" style="flex:1;max-width:180px">
        <div style="width:36px;height:36px;background:var(--sand-dark);color:#fff;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto .5rem;font-weight:700;font-size:.88rem">3</div>
        <div style="font-size:.78rem;color:var(--text-muted)">Confirm</div>
      </div>
    </div>

    <div class="row g-4">

      <!-- FORM -->
      <div class="col-lg-8">

        <!-- Section 1: Food Details -->
        <div class="fb-card mb-4">
          <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem">
            <div style="width:32px;height:32px;background:#e8f5ee;border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--green)"><i class="bi bi-egg-fried"></i></div>
            <h5 style="margin:0">Food Details</h5>
          </div>
          <div class="row g-3">
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Food Type / Description <span style="color:var(--red)">*</span></label>
                <input type="text" class="fb-input" placeholder="e.g. Biryani, Naan, Dal, Salad, Mixed Cuisine..."/>
                <div class="form-hint">Be specific so NGOs can plan distribution properly</div>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Food Category <span style="color:var(--red)">*</span></label>
                <select class="fb-input fb-select">
                  <option value="">Select category...</option>
                  <option>Cooked Meals</option>
                  <option>Bakery Items</option>
                  <option>Raw Vegetables/Fruits</option>
                  <option>Packaged Food</option>
                  <option>Beverages</option>
                  <option>Other</option>
                </select>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Donor Type <span style="color:var(--red)">*</span></label>
                <select class="fb-input fb-select">
                  <option value="">Select...</option>
                  <option>Restaurant</option>
                  <option>Hotel / Catering</option>
                  <option>Household</option>
                  <option>Corporate Event</option>
                  <option>Wedding / Function</option>
                  <option>Other</option>
                </select>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Quantity (Plates / Kg) <span style="color:var(--red)">*</span></label>
                <div style="display:flex;gap:.5rem">
                  <input type="number" class="fb-input" placeholder="e.g. 50" style="flex:2"/>
                  <select class="fb-input fb-select" style="flex:1">
                    <option>Plates</option>
                    <option>Kg</option>
                    <option>Liters</option>
                    <option>Boxes</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Servings (Approx.) <span style="color:var(--red)">*</span></label>
                <input type="number" class="fb-input" placeholder="How many people can this feed?"/>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Food Prepared On <span style="color:var(--red)">*</span></label>
                <input type="date" class="fb-input"/>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Best Before (Expiry) <span style="color:var(--red)">*</span></label>
                <input type="datetime-local" class="fb-input"/>
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Dietary Information</label>
                <div class="d-flex flex-wrap gap-2 mt-1">
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><input type="checkbox" class="form-check-input m-0"/> Halal</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><input type="checkbox" class="form-check-input m-0"/> Vegetarian</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><input type="checkbox" class="form-check-input m-0"/> Vegan</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><input type="checkbox" class="form-check-input m-0"/> Gluten-Free</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><input type="checkbox" class="form-check-input m-0"/> Contains Nuts</label>
                </div>
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Additional Notes</label>
                <textarea class="fb-input fb-textarea" placeholder="Any special handling instructions, storage requirements, or additional info..."></textarea>
              </div>
            </div>
          </div>
        </div>

        <!-- Section 2: Pickup Info -->
        <div class="fb-card mb-4">
          <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem">
            <div style="width:32px;height:32px;background:var(--amber-light);border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--amber)"><i class="bi bi-geo-alt-fill"></i></div>
            <h5 style="margin:0">Pickup Information</h5>
          </div>
          <div class="row g-3">
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Pickup Address <span style="color:var(--red)">*</span></label>
                <input type="text" class="fb-input" placeholder="Full address where food can be picked up..."/>
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>City <span style="color:var(--red)">*</span></label>
                <select class="fb-input fb-select">
                  <option value="">Select...</option>
                  <option>Karachi</option><option>Lahore</option><option>Islamabad</option>
                  <option>Rawalpindi</option><option>Peshawar</option><option>Quetta</option>
                  <option>Multan</option><option>Faisalabad</option>
                </select>
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>Available From <span style="color:var(--red)">*</span></label>
                <input type="time" class="fb-input"/>
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>Available Until <span style="color:var(--red)">*</span></label>
                <input type="time" class="fb-input"/>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Contact Person <span style="color:var(--red)">*</span></label>
                <input type="text" class="fb-input" placeholder="Name of person at pickup location"/>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Contact Phone <span style="color:var(--red)">*</span></label>
                <input type="tel" class="fb-input" placeholder="+92 300 0000000"/>
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Packaging Condition</label>
                <select class="fb-input fb-select">
                  <option>Properly Packaged</option>
                  <option>Loosely Packed – Needs Containers</option>
                  <option>Refrigerated</option>
                  <option>Hot / Freshly Cooked</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <!-- Section 3: Preferred NGO -->
        <div class="fb-card mb-4">
          <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem">
            <div style="width:32px;height:32px;background:var(--blue-light);border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--blue)"><i class="bi bi-building-fill-heart"></i></div>
            <h5 style="margin:0">Preferred NGO (Optional)</h5>
          </div>
          <div class="fb-form-group mb-2">
            <label>Select Preferred NGO</label>
            <select class="fb-input fb-select">
              <option value="">Let the system auto-assign (Recommended)</option>
              <option>Edhi Foundation – Karachi</option>
              <option>Saylani Welfare Trust – Lahore</option>
              <option>Al-Khidmat Foundation – Islamabad</option>
              <option>Akhuwat Foundation – Lahore</option>
              <option>JDC Foundation – Karachi</option>
            </select>
          </div>
          <div class="form-hint">If no preference, the nearest available verified NGO will be assigned automatically.</div>
        </div>

        <!-- Submit -->
        <div class="d-flex gap-3 flex-wrap">
          <button class="btn-green px-4 py-2" onclick="fbToast('Donation posted! NGOs have been notified.')"><i class="bi bi-check2-circle me-2"></i>Submit Donation</button>
          <button class="btn-outline-green px-4 py-2">Save as Draft</button>
          <a href="donor-dashboard.html" class="btn-sm-outline px-4 py-2" style="display:inline-flex;align-items:center">Cancel</a>
        </div>

      </div>

      <!-- TIPS SIDEBAR -->
      <div class="col-lg-4">
        <div class="fb-card mb-3" style="background:linear-gradient(135deg,var(--green),#1b4332);color:#fff;position:sticky;top:80px">
          <div style="font-family:'DM Serif Display',serif;font-size:1.2rem;margin-bottom:1rem">Donation Tips 💡</div>
          <div class="d-flex flex-column gap-3">
            <div style="background:rgba(255,255,255,.12);border-radius:10px;padding:.85rem">
              <div style="font-size:.85rem;font-weight:600;margin-bottom:.3rem"><i class="bi bi-clock me-1"></i>Timing Matters</div>
              <div style="font-size:.8rem;opacity:.8;line-height:1.6">Post donations at least 2 hours before expiry so NGOs have time to arrange pickup.</div>
            </div>
            <div style="background:rgba(255,255,255,.12);border-radius:10px;padding:.85rem">
              <div style="font-size:.85rem;font-weight:600;margin-bottom:.3rem"><i class="bi bi-box-seam me-1"></i>Proper Packaging</div>
              <div style="font-size:.8rem;opacity:.8;line-height:1.6">Keep food covered and in clean containers. Label if refrigerated or needs reheating.</div>
            </div>
            <div style="background:rgba(255,255,255,.12);border-radius:10px;padding:.85rem">
              <div style="font-size:.85rem;font-weight:600;margin-bottom:.3rem"><i class="bi bi-info-circle me-1"></i>Be Accurate</div>
              <div style="font-size:.8rem;opacity:.8;line-height:1.6">Accurate quantity and type helps NGOs plan distribution effectively for communities.</div>
            </div>
          </div>
          <div style="margin-top:1.2rem;padding-top:1rem;border-top:1px solid rgba(255,255,255,.2);font-size:.8rem;opacity:.7;text-align:center">Need help? <a href="about.html#contact" style="color:var(--green-light)">Contact our team</a></div>
        </div>
      </div>

    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../js/main.js"></script>
</body>
</html>
