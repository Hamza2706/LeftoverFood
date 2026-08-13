<%@ Page Title="Assign Volunteers – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="volunteer-assign.aspx.cs" Inherits="LeftoverFood.Admin.volunteer_assign" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .donation-row { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.2rem 1.4rem; }
    .vol-chip { display:flex; align-items:center; gap:.6rem; background:var(--cream); border-radius:8px; padding:.6rem .9rem; cursor:pointer; border:1.5px solid transparent; transition:var(--transition); }
    .vol-chip:hover { border-color:var(--green); }
    .vol-chip.selected { border-color:var(--green); background:#e8f5ee; }
    .avail-dot { width:9px; height:9px; border-radius:50%; flex-shrink:0; }
    .map-mini { background:linear-gradient(145deg,#e8f5ee,#d0f0e0); border-radius:10px; height:160px; display:flex; flex-direction:column; align-items:center; justify-content:center; border:1.5px dashed var(--green-light); font-size:.83rem; color:var(--text-muted); text-align:center; gap:.4rem; }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Volunteer Assignment</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Assign Volunteers to Donations</h2>
          <p class="text-muted" style="font-size:.9rem">Match available volunteers to approved donations needing pickup. Sorted by expiry urgency.</p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <!-- Volunteer Availability Summary -->
      <div class="fb-card mb-4">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Volunteer Availability</h6>
        <div class="row g-2">
          <div class="col-6 col-md-4">
            <div style="background:#e8f5ee;border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--green)"><asp:Literal ID="litVerifiedVolunteers" runat="server" Text="0" /></div>
              <div style="font-size:.75rem;color:var(--text-muted)">Verified Volunteers</div>
            </div>
          </div>
          <div class="col-6 col-md-4">
            <div style="background:var(--amber-light);border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--amber)"><asp:Literal ID="litOnDelivery" runat="server" Text="0" /></div>
              <div style="font-size:.75rem;color:var(--text-muted)">On Delivery</div>
            </div>
          </div>
          <div class="col-6 col-md-4">
            <div style="background:var(--blue-light);border-radius:10px;padding:.9rem;text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.8rem;color:var(--blue)"><asp:Literal ID="litNeedAssignment" runat="server" Text="0" /></div>
              <div style="font-size:.75rem;color:var(--text-muted)">Need Assignment</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Assignment Panels -->
      <div class="d-flex flex-column gap-4">
        <asp:Repeater ID="rptNeedsAssignment" runat="server" OnItemDataBound="rptNeedsAssignment_ItemDataBound" OnItemCommand="rptNeedsAssignment_ItemCommand">
          <ItemTemplate>
            <div class="donation-row" style="padding:0;overflow:hidden">
              <div style="padding:1rem 1.4rem;border-bottom:1.5px solid var(--sand);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:.5rem">
                <div class="d-flex align-items-center gap-2">
                  <span style="border-radius:50px;padding:.2rem .8rem;font-size:.75rem;font-weight:700"><%# UrgencyBadge(Eval("ExpiryTime")) %></span>
                  <span style="font-weight:600;font-size:.95rem">#<%# Eval("DonationID") %> — <%# Eval("FoodDescription") %> (<%# Eval("Quantity") %>)</span>
                </div>
                <span style="font-size:.82rem;font-weight:700"><i class="bi bi-alarm me-1"></i><%# TimeUntil(Eval("ExpiryTime")) %></span>
              </div>
              <div class="row g-0">
                <div class="col-lg-6 p-3" style="border-right:1.5px solid var(--sand)">
                  <div style="font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:.8rem">Donation Details</div>
                  <div class="d-flex flex-column gap-2" style="font-size:.85rem">
                    <div><i class="bi bi-geo-alt-fill me-2 text-danger"></i>Pickup: <%# Eval("PickupAddress") %>, <%# Eval("City") %></div>
                    <div><i class="bi bi-people-fill me-2" style="color:var(--blue)"></i>Accepted by <%# NgoLabel(Eval("NGOOrgName"), Eval("NGOName")) %></div>
                    <div><i class="bi bi-person-fill me-2 text-muted"></i>Donor: <%# Eval("DonorName") %></div>
                    <div><i class="bi bi-telephone-fill me-2 text-muted"></i>Contact: <%# Eval("ContactPerson") %> — <%# Eval("ContactPhone") %></div>
                  </div>
                </div>
                <div class="col-lg-6 p-3">
                  <div style="font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:.8rem">Assign Volunteer</div>
                  <asp:DropDownList ID="ddlVolunteer" runat="server" CssClass="fb-input fb-select mb-3" />
                  <div class="fb-form-group mb-3">
                    <label style="font-size:.82rem">Note for Volunteer (Optional)</label>
                    <asp:TextBox ID="txtNote" runat="server" TextMode="MultiLine" CssClass="fb-input fb-textarea" Style="min-height:60px;font-size:.83rem" placeholder="Special instructions e.g. use back entrance, call donor on arrival..." />
                  </div>
                  <asp:LinkButton runat="server" CssClass="btn-green w-100" CommandName="Assign" CommandArgument='<%# Eval("DonationID") %>'><i class="bi bi-person-check-fill me-1"></i>Assign Volunteer</asp:LinkButton>
                </div>
              </div>
            </div>
          </ItemTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoNeedsAssignment" runat="server" Visible="false">
          <div class="fb-card" style="text-align:center;color:var(--text-muted);font-size:.9rem">No donations are currently awaiting a volunteer.</div>
        </asp:Panel>
      </div>

      <!-- Already Assigned Table -->
      <div class="fb-card p-0 overflow-hidden mt-4">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand)">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Already Assigned — Active Deliveries</h6>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Donation</th><th>Volunteer</th><th>Status</th><th>Assigned</th></tr></thead>
            <tbody>
              <asp:Repeater ID="rptActiveDeliveries" runat="server">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3"><strong>#<%# Eval("DonationID") %></strong> — <%# Eval("Quantity") %><br><small class="text-muted"><%# Eval("DonorName") %></small></td>
                    <td><%# Eval("VolunteerName") %></td>
                    <td><span class="badge-status <%# StatusBadgeClass(Eval("Status")) %>"><%# StatusLabel(Eval("Status")) %></span></td>
                    <td><small><%# Convert.ToDateTime(Eval("AssignedAt")).ToString("d MMM, h:mm tt") %></small></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
          <asp:Panel ID="pnlNoActiveDeliveries" runat="server" Visible="false">
            <div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:.85rem">No active deliveries right now.</div>
          </asp:Panel>
        </div>
      </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="AdminFooterScripts" runat="server">
</asp:Content>
