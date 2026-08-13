<%@ Page Title="Food Approvals – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="food-approvals.aspx.cs" Inherits="LeftoverFood.Admin.food_approvals" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .approval-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.4rem; transition:var(--transition); }
    .approval-card:hover { box-shadow:var(--shadow); }
    .approval-card.urgent { border-left:4px solid var(--red); }
    .approval-card.warning { border-left:4px solid var(--amber); }
    .approval-card.normal  { border-left:4px solid var(--green); }
    .expiry-pill { display:inline-flex; align-items:center; gap:.35rem; font-size:.78rem; font-weight:700; border-radius:50px; padding:.25rem .8rem; }
    .expiry-red    { background:#fee2e2; color:#dc2626; }
    .expiry-amber  { background:#fff3e0; color:#92400e; }
    .expiry-green  { background:#e8f5ee; color:var(--green); }
    .detail-chip   { display:inline-flex; align-items:center; gap:.35rem; background:var(--cream); border-radius:6px; padding:.3rem .7rem; font-size:.8rem; color:var(--text-mid); }
    .filter-tab    { padding:.45rem 1.1rem; border-radius:50px; border:1.5px solid var(--sand); background:var(--white); font-size:.85rem; font-weight:500; cursor:pointer; color:var(--text-muted); transition:var(--transition); }
    .filter-tab.active { background:var(--green); color:#fff; border-color:var(--green); }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Food Donation Approvals</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

      <!-- Header -->
      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Pending Approvals</h2>
          <p class="text-muted" style="font-size:.9rem">Review and approve food donations before NGOs can access them. Sorted by expiry urgency.</p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- Stats Row -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#fee2e2;color:#dc2626"><i class="bi bi-exclamation-triangle-fill"></i></div>
            <div class="stat-val" style="color:#dc2626"><asp:Literal ID="litExpiringSoon" runat="server" Text="0" /></div>
            <div class="stat-lbl">Expiring &lt; 2hrs</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-clock-history"></i></div>
            <div class="stat-val" style="color:var(--amber)"><asp:Literal ID="litAwaitingReview" runat="server" Text="0" /></div>
            <div class="stat-lbl">Awaiting Review</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-check2-circle"></i></div>
            <div class="stat-val" style="color:var(--green)"><asp:Literal ID="litApprovedMonth" runat="server" Text="0" /></div>
            <div class="stat-lbl">Approved (This Month)</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="stat-card">
            <div class="stat-icon mb-2" style="background:#fee2e2;color:var(--red)"><i class="bi bi-x-circle-fill"></i></div>
            <div class="stat-val" style="color:var(--red)"><asp:Literal ID="litRejectedMonth" runat="server" Text="0" /></div>
            <div class="stat-lbl">Rejected (This Month)</div>
          </div>
        </div>
      </div>

      <!-- Filter Tabs -->
      <div class="d-flex flex-wrap gap-2 mb-4" data-filter-group>
        <button class="filter-tab active" data-filter="all">All Pending</button>
        <button class="filter-tab" data-filter="urgent">🔴 Urgent</button>
        <button class="filter-tab" data-filter="warning">🟡 Expiring Soon</button>
        <button class="filter-tab" data-filter="normal">🟢 Normal</button>
      </div>

      <!-- APPROVAL CARDS -->
      <div class="d-flex flex-column gap-3">
        <asp:Repeater ID="rptPending" runat="server" OnItemCommand="rptPending_ItemCommand">
          <ItemTemplate>
            <div class='approval-card <%# UrgencyBucket(Eval("ExpiryTime")) %>' data-filter='<%# UrgencyBucket(Eval("ExpiryTime")) %>'>
              <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
                <div style="flex:1;min-width:260px">
                  <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                    <span class='expiry-pill <%# UrgencyExpiryClass(Eval("ExpiryTime")) %>'><i class="bi bi-alarm-fill"></i> <%# TimeUntil(Eval("ExpiryTime")) %></span>
                    <span class="badge-status badge-pending">Awaiting Approval</span>
                    <span style="font-size:.75rem;color:var(--text-muted)">#FB-<%# Eval("DonationID") %> · Posted <%# TimeAgo(Eval("CreatedAt")) %></span>
                  </div>
                  <h5 style="font-size:1.05rem;margin-bottom:.6rem"><%# Eval("FoodDescription") %> — <%# Eval("DonorName") %></h5>
                  <div class="d-flex flex-wrap gap-2 mb-3">
                    <span class="detail-chip"><i class="bi bi-people-fill text-success"></i> <%# Eval("Quantity") %> · ~<%# Eval("Servings") %> people</span>
                    <span class="detail-chip"><i class="bi bi-geo-alt-fill text-danger"></i> <%# Eval("PickupAddress") %>, <%# Eval("City") %></span>
                    <span class="detail-chip"><i class="bi bi-egg-fried"></i> <%# Eval("Category") %><%# string.IsNullOrEmpty(Eval("DietaryInfo").ToString()) ? "" : " · " + Eval("DietaryInfo") %></span>
                    <span class="detail-chip"><i class="bi bi-person-fill text-muted"></i> <%# Eval("DonorType") %></span>
                  </div>
                  <p style="font-size:.85rem;color:var(--text-muted);margin:0"><%# Eval("AdditionalNotes") %></p>
                </div>
                <div class="d-flex flex-column gap-2" style="min-width:180px">
                  <asp:LinkButton runat="server" CssClass="btn-green w-100" CommandName="Approve" CommandArgument='<%# Eval("DonationID") %>'><i class="bi bi-check2-circle me-1"></i>Approve</asp:LinkButton>
                  <asp:LinkButton runat="server" CssClass="btn-sm-red w-100" Style="padding:.5rem;border-radius:8px;font-size:.88rem" CommandName="Reject" CommandArgument='<%# Eval("DonationID") %>' OnClientClick="return confirm('Reject this donation?');"><i class="bi bi-x-circle me-1"></i>Reject</asp:LinkButton>
                </div>
              </div>
            </div>
          </ItemTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoPending" runat="server" Visible="false">
          <div class="fb-card text-center" style="color:var(--text-muted)">No donations awaiting approval right now.</div>
        </asp:Panel>
      </div>

      <!-- Recently Processed -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Recently Processed (Today)</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">ID</th><th>Donor</th><th>Food</th><th>Qty</th><th>Decision</th><th>Time</th></tr></thead>
            <tbody>
              <asp:Repeater ID="rptProcessed" runat="server">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3">#FB-<%# Eval("DonationID") %></td>
                    <td><%# Eval("DonorName") %></td>
                    <td><%# Eval("FoodDescription") %></td>
                    <td><%# Eval("Quantity") %></td>
                    <td><span class='badge-status <%# Eval("Status").ToString() == "Approved" ? "badge-accepted" : "badge-rejected" %>'><%# Eval("Status") %></span></td>
                    <td><%# Convert.ToDateTime(Eval("ApprovedAt")).ToString("h:mm tt") %></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
        </div>
      </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="AdminFooterScripts" runat="server">
<script>
document.querySelectorAll('.filter-tab').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.filter-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const val = btn.dataset.filter;
    document.querySelectorAll('[data-filter]').forEach(card => {
      if (card.classList.contains('approval-card')) {
        card.style.display = (val === 'all' || card.dataset.filter === val) ? '' : 'none';
      }
    });
  });
});
</script>
</asp:Content>
