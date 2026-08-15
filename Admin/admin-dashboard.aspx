<%@ Page Title="Admin Dashboard – FoodBridge" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="admin-dashboard.aspx.cs" Inherits="LeftoverFood.Admin.admin_dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminPageHeading" runat="server">Admin Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">System Overview</h2>
          <%-- Was "All systems operational" — a claim nothing measured. --%>
          <p class="text-muted" style="font-size:.9rem">Figures as at <asp:Literal ID="litAsAt" runat="server" /></p>
        </div>
        <div class="d-flex gap-2">
          <%-- Both buttons used to be fbToast() calls that did nothing. Export
               now goes to the reports page, which has the real CSV export. --%>
          <a class="btn-sm-outline" href="<%= ResolveUrl("~/Admin/reports.aspx") %>"><i class="bi bi-download me-1"></i>Reports &amp; Export</a>
          <asp:LinkButton ID="btnRefresh" runat="server" CssClass="btn-green" OnClick="btnRefresh_Click"><i class="bi bi-arrow-clockwise me-1"></i>Refresh</asp:LinkButton>
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
          <%-- id is the anchor target for the sidebar's "All Donations" item,
               which pointed at "#" until this section became real data. --%>
          <div class="fb-card p-0 overflow-hidden" id="all-donations">
            <div class="d-flex align-items-center justify-content-between p-3 border-bottom" style="border-color:var(--sand)!important">
              <h6 class="mb-0" style="font-family:'DM Serif Display',serif">Recent Donations (All)</h6>
              <%-- Buckets rather than raw statuses: the pipeline has nine
                   statuses and nine filter buttons would not fit, so the
                   in-between ones collapse into "In Progress". FilterBucket()
                   in the code-behind is the single mapping. --%>
              <div class="d-flex gap-2" data-filter-group>
                <button type="button" class="btn-sm-outline active" data-filter="all">All</button>
                <button type="button" class="btn-sm-outline" data-filter="pending">Pending</button>
                <button type="button" class="btn-sm-outline" data-filter="progress">In Progress</button>
                <button type="button" class="btn-sm-outline" data-filter="delivered">Delivered</button>
                <button type="button" class="btn-sm-outline" data-filter="closed">Closed</button>
              </div>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Donor</th><th>Food</th><th>Qty</th><th>NGO</th><th>Volunteer</th><th>Status</th><th>Action</th></tr></thead>
                <tbody>
                  <asp:Repeater ID="rptRecentDonations" runat="server">
                    <ItemTemplate>
                      <tr data-status='<%# FilterBucket(Eval("Status")) %>'>
                        <td class="ps-3">
                          <strong><%# Server.HtmlEncode(PartyName(Eval("DonorOrg"), Eval("DonorName"))) %></strong>
                          <br /><small class="text-muted"><%# Server.HtmlEncode(Dash(Eval("City"))) %></small>
                        </td>
                        <td><%# Server.HtmlEncode(Dash(Eval("FoodDescription"))) %></td>
                        <td><%# Server.HtmlEncode(Dash(Eval("Quantity"))) %></td>
                        <td><%# Server.HtmlEncode(PartyName(Eval("NgoOrg"), Eval("NgoName"))) %></td>
                        <td><%# Server.HtmlEncode(Dash(Eval("VolunteerName"))) %></td>
                        <td><span class="badge-status <%# StatusBadge(Eval("Status")) %>"><%# Eval("Status") %></span></td>
                        <td><%# ActionLink(Eval("Status")) %></td>
                      </tr>
                    </ItemTemplate>
                  </asp:Repeater>
                </tbody>
              </table>
            </div>
            <asp:Panel ID="pnlNoDonations" runat="server" Visible="false" CssClass="text-muted"
                       Style="font-size:.85rem;padding:1rem;text-align:center">
              No donations have been posted yet.
            </asp:Panel>
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
          <%-- Every figure here was invented (94% / 88% / 72% / +15%), and the
               fulfilment one actively contradicted the reports page, which
               measures the same thing and got 50%. All four are now computed,
               and fulfilment reuses reports.aspx.cs's exact definition. --%>
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">System Health</h6>
            <div class="d-flex flex-column gap-3">
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Donation Fulfilment</span><strong style="font-size:.85rem;color:var(--green)"><asp:Literal ID="litFulfilment" runat="server" /></strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barFulfilment"></div></div>
                <div style="font-size:.72rem;color:var(--text-muted);margin-top:.25rem"><asp:Literal ID="litFulfilmentNote" runat="server" /></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">NGO Response Rate</span><strong style="font-size:.85rem"><asp:Literal ID="litNgoResponse" runat="server" /></strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barNgoResponse"></div></div>
                <div style="font-size:.72rem;color:var(--text-muted);margin-top:.25rem"><asp:Literal ID="litNgoResponseNote" runat="server" /></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Volunteers Free Now</span><strong style="font-size:.85rem;color:var(--amber)"><asp:Literal ID="litVolunteerFree" runat="server" /></strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barVolunteerFree" style="background:var(--amber)"></div></div>
                <div style="font-size:.72rem;color:var(--text-muted);margin-top:.25rem"><asp:Literal ID="litVolunteerFreeNote" runat="server" /></div>
              </div>
              <div>
                <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">New Users (this month)</span><strong style="font-size:.85rem;color:var(--blue)"><asp:Literal ID="litUserGrowth" runat="server" /></strong></div>
                <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barUserGrowth" style="background:var(--blue)"></div></div>
                <div style="font-size:.72rem;color:var(--text-muted);margin-top:.25rem"><asp:Literal ID="litUserGrowthNote" runat="server" /></div>
              </div>
            </div>
          </div>

          <!-- Quick Actions -->
          <%-- Were four fbToast() buttons. "Add New User" and "Register New NGO"
               are gone rather than restyled: this app has no admin-side account
               creation at all — registration is self-serve at ~/Login.aspx and
               an admin approves it. These four go to screens that exist. --%>
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Quick Actions</h6>
            <div class="d-flex flex-column gap-2">
              <a class="btn-sm-outline w-100 text-start py-2 px-3" href="<%= ResolveUrl("~/Admin/food-approvals.aspx") %>"><i class="bi bi-clipboard2-check me-2 text-success"></i>Review Food Approvals</a>
              <a class="btn-sm-outline w-100 text-start py-2 px-3" href="<%= ResolveUrl("~/Admin/volunteer-assign.aspx") %>"><i class="bi bi-person-check me-2 text-warning"></i>Assign Volunteers</a>
              <a class="btn-sm-outline w-100 text-start py-2 px-3" href="<%= ResolveUrl("~/Admin/reports.aspx") %>"><i class="bi bi-file-earmark-bar-graph me-2 text-primary"></i>Reports &amp; Export</a>
              <a class="btn-sm-outline w-100 text-start py-2 px-3" href="<%= ResolveUrl("~/Admin/emergency-mode.aspx") %>"><i class="bi bi-megaphone me-2 text-danger"></i>Send Broadcast</a>
            </div>
          </div>

        </div>
      </div>

      <!-- Users Table -->
      <div class="mt-4">
        <div class="fb-card p-0 overflow-hidden" id="all-users">
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
