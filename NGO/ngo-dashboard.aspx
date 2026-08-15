<%@ Page Title="NGO Dashboard – FoodBridge" Language="C#" MasterPageFile="~/NGO/NGOMaster.master" AutoEventWireup="true" CodeBehind="ngo-dashboard.aspx.cs" Inherits="LeftoverFood.NGO.ngo_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="NGOPageHeading" runat="server">NGO Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="NGOMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem"><%= Server.HtmlEncode(LeftoverFoodSystem.SessionHelper.GetFullName()) %> Dashboard</h2>
          <%-- Was an unconditional "Verified NGO" badge. Now reflects IsVerified. --%>
          <p class="text-muted" style="font-size:.9rem"><asp:Literal ID="litVerifiedBadge" runat="server" /></p>
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
            <div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litInTransit" runat="server" Text="0" /></div>
            <div class="stat-lbl">In Transit</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
            <div class="stat-val" style="color:var(--purple)"><asp:Literal ID="litMealsServed" runat="server" Text="0" /></div>
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
          <%-- Was two invented deliveries with fabricated ETAs ("ETA: 30 mins").
               Nothing in this app computes travel time — Phase 5 deliberately
               drew a straight line rather than a road route for exactly that
               reason — so the ETA line is gone rather than restyled. The
               progress bar is now driven by the real assignment status. --%>
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Active Deliveries 🚚</h6>
            <div class="d-flex flex-column gap-3">
              <asp:Repeater ID="rptActiveDeliveries" runat="server">
                <ItemTemplate>
                  <div style="background:var(--cream);border-radius:10px;padding:1rem">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                      <div>
                        <div style="font-size:.88rem;font-weight:600"><%# Server.HtmlEncode(Convert.ToString(Eval("FoodDescription"))) %></div>
                        <div style="font-size:.78rem;color:var(--text-muted)">
                          <%# Server.HtmlEncode(Convert.ToString(Eval("Quantity"))) %>
                          · Volunteer: <%# Server.HtmlEncode(VolunteerLabel(Eval("VolunteerName"))) %>
                        </div>
                      </div>
                      <span class="badge-status <%# DeliveryBadge(Eval("Status")) %>"><%# DeliveryLabel(Eval("Status")) %></span>
                    </div>
                    <div class="fb-progress"><div class="fb-progress-bar" style='width:<%# DeliveryPercent(Eval("Status")) %>%'></div></div>
                    <div style="font-size:.75rem;color:var(--text-muted);margin-top:.4rem"><%# Server.HtmlEncode(DeliveryStep(Eval("Status"))) %></div>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
              <asp:Panel ID="pnlNoActive" runat="server" Visible="false">
                <div style="font-size:.85rem;color:var(--text-muted);text-align:center;padding:.5rem 0">
                  Nothing in transit. Accepted donations appear here once a volunteer is assigned.
                </div>
              </asp:Panel>
            </div>
          </div>

          <!-- Volunteers on our deliveries -->
          <%-- Was three hardcoded people and a "Manage" button that did nothing.
               This app has no concept of an NGO *owning* volunteers — admins
               assign them centrally (Phase 3) — so "Our Volunteers" could never
               have been real. What is real is which volunteers have carried
               this NGO's deliveries, so that is what it shows now. --%>
          <div class="fb-card" id="our-volunteers">
            <div class="d-flex justify-content-between align-items-center" style="margin-bottom:1rem">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Volunteers on Our Deliveries</h6>
            </div>
            <div class="d-flex flex-column gap-2">
              <asp:Repeater ID="rptVolunteers" runat="server">
                <ItemTemplate>
                  <div class="d-flex align-items-center gap-2 p-2" style="background:var(--cream);border-radius:8px">
                    <div class="fb-avatar" style="background:var(--blue-light);color:var(--blue)"><%# Server.HtmlEncode(Initials(Eval("FullName"))) %></div>
                    <div style="flex:1">
                      <div style="font-size:.87rem;font-weight:600"><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></div>
                      <div style="font-size:.75rem;color:var(--text-muted)"><%# Eval("Completed") %> completed for us</div>
                    </div>
                    <span class="badge-status <%# Convert.ToInt32(Eval("ActiveNow")) > 0 ? "badge-accepted" : "badge-verified" %>">
                      <%# Convert.ToInt32(Eval("ActiveNow")) > 0 ? "On delivery" : "Free" %>
                    </span>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
              <asp:Panel ID="pnlNoVolunteers" runat="server" Visible="false">
                <div style="font-size:.85rem;color:var(--text-muted);text-align:center;padding:.5rem 0">
                  No volunteer has carried one of your deliveries yet.
                </div>
              </asp:Panel>
            </div>
            <div style="font-size:.72rem;color:var(--text-muted);margin-top:.6rem">
              <i class="bi bi-info-circle me-1"></i>Volunteers are assigned centrally by an admin, not managed per NGO.
            </div>
          </div>
        </div>
      </div>

      <!-- Monthly Stats -->
      <%-- Was headed "April 2025" with 248 / 5,830 / 96% hardcoded. Now the
           current calendar month, scoped to this NGO, using the same fulfilment
           definition as Admin/reports.aspx. --%>
      <div class="row g-3 mt-2">
        <div class="col-12">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Monthly Distribution Summary – <asp:Literal ID="litMonthLabel" runat="server" /></h6>
            <div class="row g-3">
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--green)"><asp:Literal ID="litMonthAccepted" runat="server" Text="0" /></div><div style="font-size:.8rem;color:var(--text-muted)">Donations Accepted</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--amber)"><asp:Literal ID="litMonthMeals" runat="server" Text="0" /></div><div style="font-size:.8rem;color:var(--text-muted)">Meals Distributed</div></div></div>
              <div class="col-sm-4"><div style="background:var(--cream);border-radius:10px;padding:1rem;text-align:center"><div style="font-family:'DM Serif Display',serif;font-size:2rem;color:var(--blue)"><asp:Literal ID="litMonthFulfilment" runat="server" Text="—" /></div><div style="font-size:.8rem;color:var(--text-muted)">Delivered of Accepted</div></div></div>
            </div>
          </div>
        </div>
      </div>

</asp:Content>
