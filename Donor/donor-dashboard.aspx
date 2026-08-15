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
          <div class="fb-card p-0 overflow-hidden" id="my-donations">
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
          <%-- All three bars were literals (1,240 / 2,000 meals, 94% success,
               860 kg saved) and none had anything behind it.

               "Food Saved (kg)" is gone rather than wired: FoodDonations has no
               weight column at all, and Quantity is free text ("30 Plates",
               "1 Kg") that cannot be summed or converted — the same limitation
               Phases 6b and 6d both ran into. The "/ 2,000" meals target is
               gone too; no goal exists anywhere in this system. --%>
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Your Impact 🌱</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Delivery Success Rate</span><strong style="font-size:.85rem;color:var(--green)"><asp:Literal ID="litSuccessRate" runat="server" /></strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barSuccessRate"></div></div>
                <div style="font-size:.72rem;color:var(--text-muted);margin-top:.25rem"><asp:Literal ID="litSuccessNote" runat="server" /></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Meals Provided</span><strong style="font-size:.85rem"><asp:Literal ID="litImpactMeals" runat="server" Text="0" /></strong></div>
                <div style="font-size:.72rem;color:var(--text-muted)">counted from servings on delivered donations</div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Still In Progress</span><strong style="font-size:.85rem;color:var(--amber)"><asp:Literal ID="litImpactInProgress" runat="server" Text="0" /></strong></div>
                <div style="font-size:.72rem;color:var(--text-muted)">posted, approved, or out for delivery</div>
              </div>
            </div>

            <%-- Was a "Gold Donor Badge — Awarded for 40+ donations". There is
                 no badge system in this app. The rating below is real, and the
                 trust ladder it links to is the one genuinely computed thing in
                 this space (Phase 6c). --%>
            <div style="background:var(--cream);border-radius:10px;padding:1rem;margin-top:1.2rem;text-align:center">
              <i class="bi bi-star-fill text-warning fs-4 d-block mb-1"></i>
              <div style="font-size:.82rem;font-weight:600"><asp:Literal ID="litTrust" runat="server" /></div>
              <div style="font-size:.75rem;color:var(--text-muted)">
                <a href="<%= ResolveUrl("~/Ratings.aspx") %>">View your ratings &amp; trust level</a>
              </div>
            </div>
          </div>

          <!-- Recent Activity -->
          <%-- Was four hardcoded timeline entries dated April 2025. Drawn from
               this donor's own notifications, the same real per-user event log
               ~/Profile.aspx uses. --%>
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recent Activity</h6>
            <div class="timeline">
              <asp:Repeater ID="rptActivity" runat="server">
                <ItemTemplate>
                  <div class="tl-item">
                    <div class="tl-dot" style='background:<%# ActivityColour(Eval("Type")) %>'></div>
                    <div class="tl-time"><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("d MMM, h:mm tt") %></div>
                    <div class="tl-text"><%# Server.HtmlEncode(Convert.ToString(Eval("Message"))) %></div>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
            </div>
            <asp:Panel ID="pnlNoActivity" runat="server" Visible="false">
              <div style="font-size:.85rem;color:var(--text-muted);padding:.5rem 0">
                Nothing yet. Post a donation and its progress will appear here.
              </div>
            </asp:Panel>
          </div>

        </div>
      </div>

</asp:Content>
