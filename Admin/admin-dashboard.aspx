<%@ Page Title="Admin Dashboard – FoodBridge" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="admin-dashboard.aspx.cs" Inherits="LeftoverFood.Admin.admin_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminPageHeading" runat="server">Admin Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">System Overview</h2>
          <p class="text-muted" style="font-size:.9rem">All systems operational</p>
        </div>
        <div class="d-flex gap-2">
          <button class="btn-sm-outline" onclick="fbToast('Report generated!')"><i class="bi bi-download me-1"></i>Export Report</button>
          <button class="btn-green" onclick="fbToast('Data refreshed!')"><i class="bi bi-arrow-clockwise me-1"></i>Refresh</button>
        </div>
      </div>

      <!-- STATS -->
      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />
      <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
            </div>
            <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litTotalDonations" runat="server" Text="0" /></div>
            <div class="stat-lbl">Total Donations</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-building-fill-heart"></i></div>
            </div>
            <div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litTotalNGOs" runat="server" Text="0" /></div>
            <div class="stat-lbl">Registered NGOs</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-people-fill"></i></div>
            </div>
            <div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litTotalUsers" runat="server" Text="0" /></div>
            <div class="stat-lbl">Total Users</div>
          </div>
        </div>
        <div class="col-6 col-lg-3">
          <div class="stat-card">
            <div class="d-flex justify-content-between mb-2">
              <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-hourglass-split"></i></div>
            </div>
            <div class="stat-val" style="color:var(--purple)"><asp:Literal ID="litPendingApprovals" runat="server" Text="0" /></div>
            <div class="stat-lbl">Pending Approvals</div>
          </div>
        </div>
      </div>

      <div class="row g-4">

        <!-- All Donations Table -->
        <div class="col-lg-8">
          <div class="fb-card p-0 overflow-hidden">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Recent Donations (All)</h6>
              <div class="d-flex gap-2" data-filter-group>
                <button class="btn-sm-outline active" data-filter="all">All</button>
                <button class="btn-sm-outline" data-filter="pending">Pending</button>
                <button class="btn-sm-outline" data-filter="accepted">Accepted</button>
                <button class="btn-sm-outline" data-filter="delivered">Delivered</button>
              </div>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donor</th><th>Food</th><th>Qty</th><th>NGO</th><th>Volunteer</th><th>Status</th><th>Action</th></tr></thead>
                <tbody>
                  <tr data-status="delivered"><td class="ps-3"><strong>Ali's Restaurant</strong><br><small class="text-muted">Karachi</small></td><td>Biryani</td><td>30</td><td>Edhi</td><td>Usman Ali</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="accepted"><td class="ps-3"><strong>Park View Hall</strong><br><small class="text-muted">Lahore</small></td><td>Mixed</td><td>200</td><td>Saylani</td><td>Fatima Noor</td><td><span class="badge-status badge-accepted">Accepted</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="pending"><td class="ps-3"><strong>Marriott Hotel</strong><br><small class="text-muted">Karachi</small></td><td>Continental</td><td>150</td><td>—</td><td>—</td><td><span class="badge-status badge-pending">Pending</span></td><td><button class="btn-sm-amber">Assign</button></td></tr>
                  <tr data-status="delivered"><td class="ps-3"><strong>Sara Ahmed</strong><br><small class="text-muted">Islamabad</small></td><td>Dal Roti</td><td>10</td><td>Al-Khidmat</td><td>Zain Malik</td><td><span class="badge-status badge-delivered">Delivered</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                  <tr data-status="rejected"><td class="ps-3"><strong>Home Donor</strong><br><small class="text-muted">Rawalpindi</small></td><td>Leftover</td><td>5</td><td>—</td><td>—</td><td><span class="badge-status badge-rejected">Rejected</span></td><td><button class="btn-sm-outline">View</button></td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Right Column -->
        <div class="col-lg-4 d-flex flex-column gap-4">

          <!-- Pending Verifications -->
          <div class="fb-card">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Pending Verifications</h6>
              <span class="badge-status badge-pending px-2"><asp:Literal ID="litPendingBadge" runat="server" Text="0" /> Pending</span>
            </div>
            <div class="d-flex flex-column gap-2">
              <asp:Repeater ID="rptPending" runat="server" OnItemCommand="rptPending_ItemCommand">
                <ItemTemplate>
                  <div style="background:var(--cream);border-radius:10px;padding:.85rem">
                    <div style="font-size:.87rem;font-weight:600"><%# Eval("FullName") %> <span class="badge-status <%# RoleBadgeClass(Eval("Role")) %>" style="font-size:.65rem"><%# Eval("Role") %></span></div>
                    <div style="font-size:.75rem;color:var(--text-muted);margin-bottom:.6rem"><%# Eval("Email") %> | <%# Eval("City", "{0}") %> | Applied: <%# Convert.ToDateTime(Eval("CreatedAt")).ToString("MMM d") %></div>
                    <div class="d-flex gap-2">
                      <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Approve" CommandArgument='<%# Eval("UserID") %>'>Verify</asp:LinkButton>
                      <asp:LinkButton runat="server" CssClass="btn-sm-red" CommandName="Reject" CommandArgument='<%# Eval("UserID") %>' OnClientClick="return confirm('Reject and remove this registration?');">Reject</asp:LinkButton>
                    </div>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
              <asp:Panel ID="pnlNoPending" runat="server" Visible="false">
                <div style="font-size:.85rem;color:var(--text-muted);text-align:center;padding:1rem 0">No pending registrations.</div>
              </asp:Panel>
            </div>
          </div>

          <!-- System Stats -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">System Health</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Donation Fulfillment</span><strong style="font-size:.85rem;color:var(--green)">94%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:94%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">NGO Response Rate</span><strong style="font-size:.85rem">88%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:88%"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Volunteer Availability</span><strong style="font-size:.85rem;color:var(--amber)">72%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:72%;background:var(--amber)"></div></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">User Growth (month)</span><strong style="font-size:.85rem;color:var(--blue)">+15%</strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" style="width:55%;background:var(--blue)"></div></div>
              </div>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Quick Actions</h6>
            <div class="d-flex flex-column gap-2">
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Opening user management...')"><i class="bi bi-person-plus me-2 text-success"></i>Add New User</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Opening NGO management...')"><i class="bi bi-building-add me-2 text-warning"></i>Register New NGO</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Report downloading...')"><i class="bi bi-file-earmark-bar-graph me-2 text-primary"></i>Download Monthly Report</button>
              <button class="btn-sm-outline w-100 text-start py-2 px-3" onclick="fbToast('Broadcast sent!')"><i class="bi bi-megaphone me-2 text-danger"></i>Send Broadcast</button>
            </div>
          </div>

        </div>
      </div>

      <!-- Users Table -->
      <div class="mt-4">
        <div class="fb-card p-0 overflow-hidden">
          <div class="p-3 border-bottom" style="border-color:var(--sand)!important">
            <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Registered Users</h6>
          </div>
          <div class="table-responsive">
            <table class="fb-table">
              <thead><tr><th class="ps-3">Name</th><th>Email</th><th>Role</th><th>City</th><th>Joined</th><th>Status</th><th>Action</th></tr></thead>
              <tbody>
                <asp:Repeater ID="rptUsers" runat="server" OnItemCommand="rptUsers_ItemCommand">
                  <ItemTemplate>
                    <tr>
                      <td class="ps-3"><div class="d-flex align-items-center gap-2"><div class="fb-avatar" style="width:30px;height:30px;font-size:.75rem"><%# Initials(Eval("FullName")) %></div><%# Eval("FullName") %></div></td>
                      <td><%# Eval("Email") %></td>
                      <td><span class="badge-status <%# RoleBadgeClass(Eval("Role")) %>"><%# Eval("Role") %></span></td>
                      <td><%# Eval("City", "{0}") %></td>
                      <td><%# Convert.ToDateTime(Eval("CreatedAt")).ToString("MMM yyyy") %></td>
                      <td><span class="badge-status <%# StatusBadgeClass(Eval("IsVerified"), Eval("IsActive")) %>"><%# StatusBadgeText(Eval("IsVerified"), Eval("IsActive")) %></span></td>
                      <td>
                        <div class="d-flex gap-1">
                          <asp:LinkButton runat="server" CssClass="btn-sm-red" CommandName="Ban" CommandArgument='<%# Eval("UserID") %>' Visible='<%# (bool)Eval("IsActive") %>' OnClientClick="return confirm('Suspend this user?');">Ban</asp:LinkButton>
                          <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Unban" CommandArgument='<%# Eval("UserID") %>' Visible='<%# !(bool)Eval("IsActive") %>'>Unban</asp:LinkButton>
                        </div>
                      </td>
                    </tr>
                  </ItemTemplate>
                </asp:Repeater>
              </tbody>
            </table>
          </div>
        </div>
      </div>

</asp:Content>
