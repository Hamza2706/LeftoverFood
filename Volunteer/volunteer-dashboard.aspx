<%@ Page Title="Volunteer Dashboard – FoodBridge" Language="C#" MasterPageFile="~/Volunteer/VolunteerMaster.master" AutoEventWireup="true" CodeBehind="volunteer-dashboard.aspx.cs" Inherits="LeftoverFood.Volunteer.volunteer_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="VolunteerPageHeading" runat="server">Volunteer Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="VolunteerMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Hey <%= LeftoverFoodSystem.SessionHelper.GetFullName() %>! Ready to help? 🚴</h2>
          <p class="text-muted" style="font-size:.9rem">You have <strong style="color:var(--amber)"><asp:Literal ID="litActiveTasksInline" runat="server" Text="0" /> active task(s)</strong> assigned to you.</p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- STATS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-bicycle"></i></div>
            <div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litActiveTasks" runat="server" Text="0" /></div>
            <div class="stat-lbl">Active Tasks</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-circle"></i></div>
            <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litDeliveriesDone" runat="server" Text="0" /></div>
            <div class="stat-lbl">Deliveries Done</div>
          </div>
        </div>
      </div>

      <div class="row g-4">

        <!-- Active Tasks -->
        <div class="col-lg-7">
          <div class="fb-card p-0 overflow-hidden">
            <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Active Tasks</h6>
            </div>
            <asp:Repeater ID="rptActiveTasks" runat="server" OnItemCommand="rptActiveTasks_ItemCommand">
              <ItemTemplate>
                <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
                  <div class="d-flex justify-content-between align-items-start mb-3">
                    <div><div style="font-size:1rem;font-weight:700">Pickup – <%# Eval("Quantity") %> <%# Eval("FoodDescription") %></div><div style="font-size:.82rem;color:var(--text-muted)">From: <%# Eval("PickupAddress") %>, <%# Eval("PickupCity") %></div></div>
                    <span class="badge-status <%# Eval("Status").ToString() == "PickedUp" ? "badge-accepted" : "badge-pending" %>"><%# Eval("Status").ToString() == "PickedUp" ? "In Progress" : "Pending Pickup" %></span>
                  </div>
                  <div class="d-flex gap-3 mb-3" style="font-size:.83rem;color:var(--text-muted)">
                    <span><i class="bi bi-geo-alt me-1 text-success"></i><%# Eval("PickupCity") %></span>
                    <span><i class="bi bi-arrow-right me-1"></i></span>
                    <span><i class="bi bi-geo-alt me-1 text-danger"></i><%# NgoLabel(Eval("NGOOrgName"), Eval("NGOName")) %></span>
                  </div>
                  <div class="fb-progress mb-2"><div class="fb-progress-bar" style="width:<%# Eval("Status").ToString() == "PickedUp" ? "65" : "10" %>%"></div></div>
                  <div class="d-flex justify-content-between" style="font-size:.78rem;color:var(--text-muted)">
                    <span>Pick up</span><span>In Transit</span><span>Deliver</span>
                  </div>
                  <div class="d-flex gap-2 mt-3">
                    <asp:LinkButton runat="server" CssClass="btn-sm-amber" CommandName="Pickup" CommandArgument='<%# Eval("AssignmentID") %>' Visible='<%# Eval("Status").ToString() == "Assigned" %>'><i class="bi bi-check2 me-1"></i>Confirm Pickup</asp:LinkButton>
                    <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Deliver" CommandArgument='<%# Eval("AssignmentID") %>' Visible='<%# Eval("Status").ToString() == "PickedUp" %>'><i class="bi bi-check2 me-1"></i>Mark Delivered</asp:LinkButton>
                    <span class="btn-sm-outline"><i class="bi bi-telephone me-1"></i><%# Eval("ContactPerson") %> — <%# Eval("ContactPhone") %></span>
                  </div>
                </div>
              </ItemTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoActiveTasks" runat="server" Visible="false">
              <div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:.85rem">No tasks assigned to you right now.</div>
            </asp:Panel>
          </div>
        </div>

        <!-- Right Column -->
        <div class="col-lg-5 d-flex flex-column gap-4">

          <!-- Recently Completed -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Recently Completed Deliveries</h6>
            <div class="timeline">
              <asp:Repeater ID="rptCompleted" runat="server">
                <ItemTemplate>
                  <div class="tl-item">
                    <div class="tl-dot"></div>
                    <div class="tl-time"><%# Convert.ToDateTime(Eval("DeliveredAt")).ToString("d MMM, h:mm tt") %></div>
                    <div class="tl-text">Delivered <%# Eval("Quantity") %> <%# Eval("FoodDescription") %> to <%# NgoLabel(Eval("NGOOrgName"), Eval("NGOName")) %></div>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
            </div>
            <asp:Panel ID="pnlNoCompleted" runat="server" Visible="false">
              <div style="text-align:center;color:var(--text-muted);font-size:.85rem">No completed deliveries yet.</div>
            </asp:Panel>
          </div>

        </div>
      </div>

</asp:Content>
