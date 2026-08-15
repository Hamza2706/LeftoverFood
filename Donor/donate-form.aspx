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
<form id="form1" runat="server">
<!-- NAVBAR -->
<nav class="navbar navbar-expand-lg fb-navbar">
  <div class="container">
    <%-- Both links were left over from the standalone mockup and 404'd: they
         resolved relative to /Donor/, where neither index.html nor
         donor-dashboard.html exists. A signed-in donor's home is their
         dashboard, not the static index.html prototype at the app root. --%>
    <a class="navbar-brand" href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>"><i class="bi bi-basket2-fill me-1"></i>Food<span>Bridge</span></a>
    <div class="ms-auto d-flex gap-2 align-items-center">
      <a href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>" class="nav-link btn-nav-login"><i class="bi bi-grid me-1"></i>Dashboard</a>
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

    <asp:Label ID="lblMessage" runat="server" Visible="false" CssClass="alert" Style="display:block;margin-bottom:1.5rem" />

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
                <asp:TextBox ID="txtFoodDescription" runat="server" CssClass="fb-input" placeholder="e.g. Biryani, Naan, Dal, Salad, Mixed Cuisine..." />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtFoodDescription" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
                <div class="form-hint">Be specific so NGOs can plan distribution properly</div>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Food Category <span style="color:var(--red)">*</span></label>
                <asp:DropDownList ID="ddlCategory" runat="server" CssClass="fb-input fb-select">
                  <asp:ListItem Value="">Select category...</asp:ListItem>
                  <asp:ListItem>Cooked Meals</asp:ListItem>
                  <asp:ListItem>Bakery Items</asp:ListItem>
                  <asp:ListItem>Raw Vegetables/Fruits</asp:ListItem>
                  <asp:ListItem>Packaged Food</asp:ListItem>
                  <asp:ListItem>Beverages</asp:ListItem>
                  <asp:ListItem>Other</asp:ListItem>
                </asp:DropDownList>
                <asp:RequiredFieldValidator runat="server" ControlToValidate="ddlCategory" InitialValue="" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Donor Type <span style="color:var(--red)">*</span></label>
                <asp:DropDownList ID="ddlDonorType" runat="server" CssClass="fb-input fb-select">
                  <asp:ListItem Value="">Select...</asp:ListItem>
                  <asp:ListItem>Restaurant</asp:ListItem>
                  <asp:ListItem>Hotel / Catering</asp:ListItem>
                  <asp:ListItem>Household</asp:ListItem>
                  <asp:ListItem>Corporate Event</asp:ListItem>
                  <asp:ListItem>Wedding / Function</asp:ListItem>
                  <asp:ListItem>Other</asp:ListItem>
                </asp:DropDownList>
                <asp:RequiredFieldValidator runat="server" ControlToValidate="ddlDonorType" InitialValue="" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Quantity (Plates / Kg) <span style="color:var(--red)">*</span></label>
                <div style="display:flex;gap:.5rem">
                  <asp:TextBox ID="txtQuantity" runat="server" CssClass="fb-input" placeholder="e.g. 50" Style="flex:2" TextMode="Number" />
                  <asp:DropDownList ID="ddlUnit" runat="server" CssClass="fb-input fb-select" Style="flex:1">
                    <asp:ListItem>Plates</asp:ListItem>
                    <asp:ListItem>Kg</asp:ListItem>
                    <asp:ListItem>Liters</asp:ListItem>
                    <asp:ListItem>Boxes</asp:ListItem>
                  </asp:DropDownList>
                </div>
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtQuantity" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Servings (Approx.) <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtServings" runat="server" CssClass="fb-input" placeholder="How many people can this feed?" TextMode="Number" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtServings" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Food Prepared On <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtPreparedOn" runat="server" CssClass="fb-input" TextMode="Date" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPreparedOn" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Best Before (Expiry) <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtExpiryTime" runat="server" CssClass="fb-input" TextMode="DateTimeLocal" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtExpiryTime" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Photo (Optional)</label>
                <asp:FileUpload ID="fuPhoto" runat="server" CssClass="fb-input" />
                <div class="form-hint">JPG or PNG, max 5MB</div>
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Dietary Information</label>
                <div class="d-flex flex-wrap gap-2 mt-1">
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><asp:CheckBox ID="chkHalal" runat="server" CssClass="m-0" /> Halal</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><asp:CheckBox ID="chkVegetarian" runat="server" CssClass="m-0" /> Vegetarian</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><asp:CheckBox ID="chkVegan" runat="server" CssClass="m-0" /> Vegan</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><asp:CheckBox ID="chkGlutenFree" runat="server" CssClass="m-0" /> Gluten-Free</label>
                  <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;font-weight:400;cursor:pointer;background:var(--cream);border:1.5px solid var(--sand);border-radius:50px;padding:.25rem .85rem"><asp:CheckBox ID="chkNuts" runat="server" CssClass="m-0" /> Contains Nuts</label>
                </div>
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Additional Notes</label>
                <asp:TextBox ID="txtNotes" runat="server" CssClass="fb-input fb-textarea" TextMode="MultiLine" placeholder="Any special handling instructions, storage requirements, or additional info..." />
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
                <asp:TextBox ID="txtPickupAddress" runat="server" CssClass="fb-input" placeholder="Full address where food can be picked up..." />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPickupAddress" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>City <span style="color:var(--red)">*</span></label>
                <asp:DropDownList ID="ddlCity" runat="server" CssClass="fb-input fb-select">
                  <asp:ListItem Value="">Select...</asp:ListItem>
                  <asp:ListItem>Karachi</asp:ListItem><asp:ListItem>Lahore</asp:ListItem><asp:ListItem>Islamabad</asp:ListItem>
                  <asp:ListItem>Rawalpindi</asp:ListItem><asp:ListItem>Peshawar</asp:ListItem><asp:ListItem>Quetta</asp:ListItem>
                  <asp:ListItem>Multan</asp:ListItem><asp:ListItem>Faisalabad</asp:ListItem>
                </asp:DropDownList>
                <asp:RequiredFieldValidator runat="server" ControlToValidate="ddlCity" InitialValue="" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>Available From <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtAvailableFrom" runat="server" CssClass="fb-input" TextMode="Time" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtAvailableFrom" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-4">
              <div class="fb-form-group mb-0">
                <label>Available Until <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtAvailableUntil" runat="server" CssClass="fb-input" TextMode="Time" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtAvailableUntil" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Contact Person <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtContactPerson" runat="server" CssClass="fb-input" placeholder="Name of person at pickup location" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtContactPerson" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-sm-6">
              <div class="fb-form-group mb-0">
                <label>Contact Phone <span style="color:var(--red)">*</span></label>
                <asp:TextBox ID="txtContactPhone" runat="server" CssClass="fb-input" TextMode="Phone" placeholder="+92 300 0000000" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="txtContactPhone" ErrorMessage="Required" CssClass="text-danger" Display="Dynamic" Style="font-size:.78rem" />
              </div>
            </div>
            <div class="col-12">
              <div class="fb-form-group mb-0">
                <label>Packaging Condition</label>
                <asp:DropDownList ID="ddlPackaging" runat="server" CssClass="fb-input fb-select">
                  <asp:ListItem>Properly Packaged</asp:ListItem>
                  <asp:ListItem>Loosely Packed – Needs Containers</asp:ListItem>
                  <asp:ListItem>Refrigerated</asp:ListItem>
                  <asp:ListItem>Hot / Freshly Cooked</asp:ListItem>
                </asp:DropDownList>
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
            <asp:DropDownList ID="ddlPreferredNGO" runat="server" CssClass="fb-input fb-select">
              <asp:ListItem Value="">Let the system auto-assign (Recommended)</asp:ListItem>
            </asp:DropDownList>
          </div>
          <div class="form-hint">If no preference, any verified NGO will be able to request this donation once approved.</div>
        </div>

        <!-- Submit -->
        <div class="d-flex gap-3 flex-wrap">
          <asp:Button ID="btnSubmit" runat="server" CssClass="btn-green px-4 py-2" Text="Submit Donation" OnClick="btnSubmit_Click" />
          <a href="donor-dashboard.aspx" class="btn-sm-outline px-4 py-2" style="display:inline-flex;align-items:center">Cancel</a>
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
          <%-- Was "Need help? Contact our team" linking to about.html#contact,
               which does not exist. There is no contact page, no support inbox
               and no messaging feature in this app, so the link is gone rather
               than repointed — the same call Phases 6a and 6b made for promises
               with nothing behind them. What a donor can genuinely do after
               posting is track it, so that is what this offers instead. --%>
          <div style="margin-top:1.2rem;padding-top:1rem;border-top:1px solid rgba(255,255,255,.2);font-size:.8rem;opacity:.7;text-align:center">
            Once posted, follow your donation from
            <a href="<%= ResolveUrl("~/Donor/donor-dashboard.aspx") %>" style="color:var(--green-light)">your dashboard</a>.
          </div>
        </div>
      </div>

    </div>
  </div>
</div>
</form>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="../assets/js/main.js"></script>
</body>
</html>
