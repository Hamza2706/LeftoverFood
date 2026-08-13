<%@ Page Title="NGO Dashboard – FoodBridge" Language="C#" MasterPageFile="~/NGO/NGOMaster.master" AutoEventWireup="true" CodeBehind="ngo-dashboard.aspx.cs" Inherits="LeftoverFood.NGO.ngo_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="NGOPageHeading" runat="server">NGO Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="NGOMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem"><%= LeftoverFoodSystem.SessionHelper.GetFullName() %> Dashboard</h2>
          <p class="text-muted" style="font-size:.9rem"><span class="badge-status badge-verified">Verified NGO</span></p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-inbox-fill"></i></div>
            <div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litNewRequests" runat="server" Text="0" /></div>
            <div class="stat-lbl">Available Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-all"></i></div>
            <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litAcceptedToday" runat="server" Text="0" /></div>
            <div class="stat-lbl">Accepted Today</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-truck"></i></div>
            <div class="stat-val" style="color:var(--blue)">0</div>
            <div class="stat-lbl">In Transit</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
            <div class="stat-val" style="color:var(--purple)">0</div>
            <div class="stat-lbl">Total Meals Served</div>
          </div>
        </div>
      </div>

      <div class="row g-4">
        <!-- Incoming Requests -->
        <div class="col-lg-7">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Available Donations</h6>
              <span class="badge-status badge-pending px-3"><asp:Literal ID="litAvailableBadge" runat="server" Text="0" /> Available</span>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donor</th><th>Food</th><th>Qty</th><th>Pickup Window</th><th>Action</th></tr></thead>
                <tbody>
                  <asp:Repeater ID="rptAvailable" runat="server" OnItemCommand="rptAvailable_ItemCommand">
                    <ItemTemplate>
                      <tr>
                        <td class="ps-3"><strong><%# Eval("DonorName") %></strong><br><small class="text-muted"><%# Eval("City") %></small></td>
                        <td><%# Eval("FoodDescription") %></td>
                        <td><%# Eval("Quantity") %></td>
                        <td><small><%# Convert.ToDateTime(Eval("AvailableFrom")).ToString("h:mm tt") %> – <%# Convert.ToDateTime(Eval("AvailableUntil")).ToString("h:mm tt") %></small></td>
                        <td><asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Accept" CommandArgument='<%# Eval("DonationID") %>'>Accept</asp:LinkButton></td>
                      </tr>
                    </ItemTemplate>
                  </asp:Repeater>
                </tbody>
              </table>
              <asp:Panel ID="pnlNoAvailable" runat="server" Visible="false">
                <div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:.85rem">No approved donations available to request right now.</div>
              </asp:Panel>
            </div>
          </div>
        </div>

        <!-- Right column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Active Deliveries -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Active Deliveries 🚚</h6>
            <div class="d-flex flex-column gap-3">
              <div style="background:var(--cream);border-radius:10px;padding:1rem">
                <div class="d-flex justify-content-between align-items-start mb-2">
                  <div><div style="font-size:.88rem;font-weight:600">30 plates – Biryani</div><div style="font-size:.78rem;color:var(--text-muted)">Volunteer: Usman Ali</div></div>
                  <span class="badge-status badge-accepted">In Transit</span>
                </div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:70%"></div></div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-top:.4rem">ETA: 30 mins</div>
              </div>
              <div style="background:var(--cream);border-radius:10px;padding:1rem">
                <div class="d-flex justify-content-between align-items-start mb-2">
                  <div><div style="font-size:.88rem;font-weight:600">80 plates – Mixed</div><div style="font-size:.78rem;color:var(--text-muted)">Volunteer: Fatima Noor</div></div>
                  <span class="badge-status badge-pending">Pickup</span>
                </div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:25%"></div></div>
                <div style="font-size:.75rem;color:var(--text-muted);margin-top:.4rem">ETA: 1 hr 15 mins</div>
              </div>
            </div>
          </div>

          <!-- Volunteer Summary -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-1rem" style="margin-bottom:1rem">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Our Volunteers</h6>
              <button class="btn-sm-outline">Manage</button>
            </div>
            <div class="d-flex flex-column gap-2">
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue)">UA</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Usman Ali</div><div style="font-size:.75rem;color:var(--text-muted)">On Delivery</div></div>
                <span class="badge-status badge-active">Active</span>
              </div>
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:var(--purple-light);color:var(--purple)">FN</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Fatima Noor</div><div style="font-size:.75rem;color:var(--text-muted)">Picking Up</div></div>
                <span class="badge-status badge-accepted">Busy</span>
              </div>
              <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                <div class="fb-avatar" style="background:#e8f5ee;color:var(--green)">ZM</div>
                <div style="flex:1"><div style="font-size:.87rem;font-weight:600">Zain Malik</div><div style="font-size:.75rem;color:var(--text-muted)">Available</div></div>
                <span class="badge-status badge-verified">Free</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Monthly Stats -->
      <div class="row g-3 mt-2">
        <div class="col-12">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Monthly Distribution Summary – April 2025</h6>
            <div class="row g-3">
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--green)">248</div><div style="font-size:.8rem;color:var(--text-muted)">Donations Received</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--amber)">5,830</div><div style="font-size:.8rem;color:var(--text-muted)">Meals Distributed</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--blue)">96%</div><div style="font-size:.8rem;color:var(--text-muted)">Fulfillment Rate</div></div></div>
            </div>
          </div>
        </div>
      </div>

</asp:Content>
