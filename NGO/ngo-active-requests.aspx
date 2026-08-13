<%@ Page Title="Active Requests – FoodBridge NGO" Language="C#" MasterPageFile="~/NGO/NGOMaster.master" AutoEventWireup="true" CodeBehind="ngo-active-requests.aspx.cs" Inherits="LeftoverFood.NGO.ngo_active_requests" %>

<asp:Content ID="Content1" ContentPlaceHolderID="NGOHeadContent" runat="server">
  <style>
    .req-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); overflow:hidden; }
    .req-card-header { padding:1rem 1.4rem; border-bottom:1.5px solid var(--sand); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.5rem; }
    .req-card-body { padding:1.2rem 1.4rem; }
    .mini-timeline { display:flex; align-items:center; gap:0; margin:.5rem 0; }
    .mt-step { flex:1; text-align:center; position:relative; }
    .mt-step::before { content:''; position:absolute; top:10px; left:50%; right:-50%; height:2px; background:var(--sand-dark); z-index:0; }
    .mt-step:last-child::before { display:none; }
    .mt-dot { width:22px; height:22px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:.65rem; margin:0 auto .3rem; position:relative; z-index:1; }
    .mt-dot.done   { background:var(--green); color:#fff; }
    .mt-dot.active { background:var(--amber); color:#fff; }
    .mt-dot.pending { background:var(--sand-dark); color:#fff; }
    .mt-label { font-size:.65rem; color:var(--text-muted); }
    .map-mini { background:linear-gradient(145deg,#e8f5ee,#d0f0e0); border-radius:8px; height:120px; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:.3rem; font-size:.78rem; color:var(--text-muted); border:1.5px dashed var(--green-light); }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="NGOPageHeading" runat="server">Active Requests</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="NGOMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">My Accepted Requests</h2>
          <p class="text-muted" style="font-size:.9rem">Track and manage all food donations your NGO has accepted.</p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- Quick Stats -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-hourglass-split"></i></div><div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litAwaitingCount" runat="server" Text="0" /></div><div class="stat-lbl">Awaiting Pickup</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-truck"></i></div><div class="stat-val" style="color:var(--blue)"><asp:Literal ID="litTransitCount" runat="server" Text="0" /></div><div class="stat-lbl">In Transit</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-all"></i></div><div class="stat-val" style="color:var(--green)"><asp:Literal ID="litArrivedCount" runat="server" Text="0" /></div><div class="stat-lbl">Arrived</div></div></div>
        <div class="col-6 col-md-3"><div class="stat-card"><div class="stat-icon mb-2" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div><div class="stat-val" style="color:var(--purple)"><asp:Literal ID="litMealsExpected" runat="server" Text="0" /></div><div class="stat-lbl">Meals Expected</div></div></div>
      </div>

      <!-- Filter Tabs -->
      <div class="d-flex gap-2 flex-wrap mb-4" data-filter-group>
        <button class="btn-sm-outline active" data-filter="all" style="border-radius:50px;padding:.4rem 1.1rem">All Active</button>
        <button class="btn-sm-outline" data-filter="awaiting" style="border-radius:50px;padding:.4rem 1.1rem">Awaiting Pickup</button>
        <button class="btn-sm-outline" data-filter="transit" style="border-radius:50px;padding:.4rem 1.1rem">In Transit</button>
        <button class="btn-sm-outline" data-filter="arrived" style="border-radius:50px;padding:.4rem 1.1rem">Arrived</button>
      </div>

      <div class="d-flex flex-column gap-3">
        <asp:Repeater ID="rptRequests" runat="server" OnItemCommand="rptRequests_ItemCommand">
          <ItemTemplate>
            <div class="req-card" data-status='<%# Bucket(Eval("DonationStatus")) %>'>
              <div class="req-card-header" style='<%# BucketHeaderStyle(Eval("DonationStatus")) %>'>
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="badge-status <%# BucketBadgeClass(Eval("DonationStatus")) %>" style="font-size:.8rem;padding:.3rem .9rem"><%# BucketLabel(Eval("DonationStatus")) %></span>
                  <span style="font-weight:600;font-size:.95rem">#<%# Eval("DonationID") %> — <%# Eval("FoodDescription") %></span>
                </div>
                <span style="font-size:.82rem;font-weight:600"><%# BucketTimeText(Eval("DonationStatus"), Eval("RequestedAt"), Eval("PickedUpAt"), Eval("DeliveredAt")) %></span>
              </div>
              <div class="req-card-body">
                <div class="row g-3 align-items-center">
                  <div class="col-md-5">
                    <div class="d-flex flex-column gap-1 mb-3" style="font-size:.85rem">
                      <div><i class="bi bi-person-fill me-2 text-muted"></i><strong><%# Eval("DonorName") %></strong></div>
                      <div><i class="bi bi-egg-fried me-2 text-muted"></i><%# Eval("Quantity") %> <%# Eval("FoodDescription") %></div>
                      <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i><%# Eval("PickupAddress") %>, <%# Eval("City") %></div>
                      <div><i class="bi bi-bicycle me-2" style="color:var(--blue)"></i>Volunteer: <strong><%# VolunteerNameOrDash(Eval("VolunteerName")) %></strong></div>
                    </div>
                    <!-- Mini Timeline -->
                    <div class="mini-timeline">
                      <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Posted</div></div>
                      <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Approved</div></div>
                      <div class="mt-step"><div class="mt-dot done"><i class="bi bi-check2" style="font-size:.55rem"></i></div><div class="mt-label">Accepted</div></div>
                      <div class="mt-step"><div class="mt-dot <%# MiniStepClass(Eval("DonationStatus"), Eval("ActualQuantityReceived"), "pickedup") %>"><i class="bi bi-truck" style="font-size:.55rem"></i></div><div class="mt-label">Picked Up</div></div>
                      <div class="mt-step"><div class="mt-dot <%# MiniStepClass(Eval("DonationStatus"), Eval("ActualQuantityReceived"), "arrived") %>"><i class="bi bi-geo-alt-fill" style="font-size:.55rem"></i></div><div class="mt-label">Arrived</div></div>
                    </div>
                  </div>
                  <div class="col-md-4">
                    <asp:Panel runat="server" Visible='<%# Bucket(Eval("DonationStatus")) == "arrived" %>'>
                      <div class="fb-form-group mb-2">
                        <label style="font-size:.78rem">Actual Quantity Received</label>
                        <asp:TextBox runat="server" ID="txtQtyReceived" CssClass="fb-input" Text='<%# Eval("Quantity") %>' />
                      </div>
                      <div class="fb-form-group mb-2">
                        <label style="font-size:.78rem">Food Condition</label>
                        <asp:DropDownList runat="server" ID="ddlCondition" CssClass="fb-input fb-select">
                          <asp:ListItem Text="Good — Fresh & Ready" Value="Good — Fresh &amp; Ready" />
                          <asp:ListItem Text="Acceptable — Minor Issues" Value="Acceptable — Minor Issues" />
                          <asp:ListItem Text="Poor — Not Usable" Value="Poor — Not Usable" />
                        </asp:DropDownList>
                      </div>
                      <div class="fb-form-group mb-0">
                        <label style="font-size:.78rem">Notes (Optional)</label>
                        <asp:TextBox runat="server" ID="txtReceiveNotes" CssClass="fb-input" placeholder="Any remarks..." />
                      </div>
                    </asp:Panel>
                  </div>
                  <div class="col-md-3">
                    <div class="d-flex flex-column gap-2">
                      <asp:LinkButton runat="server" CssClass="btn-green w-100" CommandName="ConfirmReceipt" CommandArgument='<%# Eval("RequestID") %>' Visible='<%# Bucket(Eval("DonationStatus")) == "arrived" %>'><i class="bi bi-check2-circle me-1"></i>Confirm Receipt</asp:LinkButton>
                      <span class="btn-sm-outline w-100" style="display:block;text-align:center"><i class="bi bi-telephone me-1"></i><%# Eval("DonorName") %></span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </ItemTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoRequests" runat="server" Visible="false">
          <div class="fb-card" style="text-align:center;color:var(--text-muted);font-size:.9rem">No active requests right now.</div>
        </asp:Panel>
      </div>

      <!-- Completed -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Recently Completed</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">ID</th><th>Donor</th><th>Food</th><th>Qty Received</th><th>Volunteer</th><th>Completed</th></tr></thead>
            <tbody>
              <asp:Repeater ID="rptCompleted" runat="server">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3"><strong>#<%# Eval("DonationID") %></strong></td>
                    <td><%# Eval("DonorName") %></td>
                    <td><%# Eval("FoodDescription") %></td>
                    <td><%# Eval("ActualQuantityReceived") %></td>
                    <td><%# VolunteerNameOrDash(Eval("VolunteerName")) %></td>
                    <td><%# Convert.ToDateTime(Eval("DeliveredAt")).ToString("d MMM, h:mm tt") %></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
          <asp:Panel ID="pnlNoCompleted" runat="server" Visible="false">
            <div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:.85rem">Nothing completed yet.</div>
          </asp:Panel>
        </div>
      </div>

</asp:Content>
