<%@ Page Title="Donor Dashboard – FoodBridge" Language="C#" MasterPageFile="~/Donor/DonorMaster.master" AutoEventWireup="true" CodeBehind="donor-dashboard.aspx.cs" Inherits="LeftoverFood.Donor.donor_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="DonorPageHeading" runat="server">Donor Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="DonorMainContent" runat="server">

      <!-- Welcome bar -->
      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Good day, <%= LeftoverFoodSystem.SessionHelper.GetFullName() %> 👋</h2>
          <p class="text-muted" style="font-size:.9rem">Here's what's happening with your donations today.</p>
        </div>
        <a href="donate-form.aspx" class="btn-green"><i class="bi bi-plus-circle me-1"></i>New Donation</a>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
            </div>
            <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litTotalDonations" runat="server" Text="0" /></div>
            <div class="stat-lbl">Total Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:#cff4fc;color:var(--blue)"><i class="bi bi-check2-circle"></i></div>
            </div>
            <div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litDelivered" runat="server" Text="0" /></div>
            <div class="stat-lbl">Successfully Delivered</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-clock-history"></i></div>
            </div>
            <div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litPending" runat="server" Text="0" /></div>
            <div class="stat-lbl">Pending Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between align-items-start mb-2">
              <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
            </div>
            <div class="stat-val" style="color:var(--purple)"><asp:Literal ID="litMealsProvided" runat="server" Text="0" /></div>
            <div class="stat-lbl">Meals Provided</div>
          </div>
        </div>
      </div>

      <div class="row g-4">
        <!-- Donations Table -->
        <div class="col-lg-8">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0 fw-600" style="font-family:'DM Serif Display',serif">Recent Donations</h6>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Food Type</th><th>Quantity</th><th>Date</th><th>NGO</th><th>Status</th><th>Action</th></tr></thead>
                <tbody>
                  <asp:Repeater ID="rptDonations" runat="server" OnItemCommand="rptDonations_ItemCommand">
                    <ItemTemplate>
                      <tr>
                        <td class="ps-3"><i class="bi bi-egg-fried me-2 text-muted"></i><%# Eval("FoodDescription") %></td>
                        <td><%# Eval("Quantity") %></td>
                        <td><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("d MMM") %></td>
                        <td><%# NgoNameOrDash(Eval("NGOName")) %></td>
                        <td><span class="badge-status <%# StatusBadgeClass(Eval("Status")) %>"><%# Eval("Status") %></span></td>
                        <td>
                          <a class="btn-sm-outline" href='<%# ResolveUrl("~/Donor/track-donation.aspx?id=") + Eval("DonationID") %>'>Track</a>
                          <asp:LinkButton runat="server" CssClass="btn-sm-red" CommandName="Cancel" CommandArgument='<%# Eval("DonationID") %>' Visible='<%# Eval("Status").ToString() == "Posted" %>' OnClientClick="return confirm('Cancel this donation?');">Cancel</asp:LinkButton>
                        </td>
                      </tr>
                    </ItemTemplate>
                  </asp:Repeater>
                </tbody>
              </table>
              <asp:Panel ID="pnlNoDonations" runat="server" Visible="false">
                <div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:.85rem">You haven't posted any donations yet.</div>
              </asp:Panel>
            </div>
          </div>
        </div>

        <!-- Sidebar Cards -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Impact Card -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Your Impact 🌱</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Meals Provided</span><strong style="font-size:.85rem">1,240 / 2,000</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:62%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Delivery Success Rate</span><strong style="font-size:.85rem;color:var(--green)">94%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:94%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Food Saved (kg)</span><strong style="font-size:.85rem">860 kg</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:43%"></div></div>
              </div>
            </div>
            <div style="background:var(--cream);border-radius:10px;padding:1rem;margin-top:1.2rem;text-align:center">
              <i class="bi bi-award-fill text-warning fs-4 d-block mb-1"></i>
              <div style="font-size:.82rem;font-weight:600">Gold Donor Badge</div>
              <div style="font-size:.75rem;color:var(--text-muted)">Awarded for 40+ donations</div>
            </div>
          </div>

          <!-- Recent Activity -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recent Activity</h6>
            <div class="timeline">
              <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">Today, 10:30 AM</div><div class="tl-text">Donation of 30 plates delivered by Edhi Foundation</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--amber)"></div><div class="tl-time">Yesterday, 3:15 PM</div><div class="tl-text">Saylani accepted your 80-plate donation</div></div>
              <div class="tl-item"><div class="tl-dot" style="background:var(--blue)"></div><div class="tl-time">Apr 20, 9:00 AM</div><div class="tl-text">New donation posted: Continental Buffet – 150 plates</div></div>
              <div class="tl-item"><div class="tl-dot"></div><div class="tl-time">Apr 18, 6:00 PM</div><div class="tl-text">Dal & Roti donation delivered successfully</div></div>
            </div>
          </div>

        </div>
      </div>

</asp:Content>
