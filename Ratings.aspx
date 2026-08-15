<%@ Page Title="Ratings & Trust – FoodBridge" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="Ratings.aspx.cs" Inherits="LeftoverFood.RatingsPage" %>

<%--
  Phase 6c. Shared by Donor, NGO and Volunteer.

  This page started as Donor/ratings.aspx, a Donor-only mockup. The proposal
  asks for "Donor rates NGO/Volunteer and vice versa", but NGO and Volunteer had
  no ratings page at all — so the choice was to copy this markup twice more or
  move it to the app root and share it, the same call Phase 4 made for
  ~/Notifications.aspx. It uses Site.master directly and renders the role
  sidebar through the shared RoleSidebar control, so it still looks native to
  whichever role is signed in.

  Admin is excluded: an admin never participates in a delivery, so has nobody to
  rate and nobody to be rated by. Aggregate trust reporting is Phase 6d.

  Everything on this page is real data. The mockup's per-category scores (Food
  Quality / Quantity Accuracy / Packaging / Punctuality) and its "94% Accuracy"
  tile were dropped rather than faked: Ratings has a single Stars column, so
  there is nothing behind a four-way breakdown. The trust-level ladder is kept
  and is genuinely computed, but its "Benefits" column is gone — auto-approval,
  featured listings and priority queues do not exist in this app, and listing
  them as earned benefits would promise behaviour no code implements.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
  <style>
    .star-row { display:flex; gap:.25rem; }
    .star-row i { font-size:1.1rem; color:#fbbf24; }
    .star-row i.empty { color:var(--sand-dark); }
    .trust-badge { display:inline-flex; align-items:center; gap:.4rem; padding:.35rem .9rem; border-radius:50px; font-size:.8rem; font-weight:700; }
    .trust-gold     { background:#fef3c7; color:#92400e; }
    .trust-silver   { background:#f1f5f9; color:#475569; }
    .trust-bronze   { background:#fef3c7; color:#78350f; }
    .trust-new      { background:var(--sand); color:var(--text-muted); }
    .trust-platinum { background:var(--purple-light); color:var(--purple); }
    .trust-flagged  { background:#fee2e2; color:#dc2626; }
    .review-card { background:var(--cream); border-radius:10px; padding:1rem 1.2rem; border-left:3px solid var(--green-light); }
    .review-card.given { border-left-color:var(--blue); }
    .rating-stars-input { display:flex; gap:.3rem; flex-direction:row-reverse; justify-content:flex-end; }
    .rating-stars-input input { display:none; }
    .rating-stars-input label { font-size:1.6rem; color:var(--sand-dark); cursor:pointer; transition:color .15s; }
    .rating-stars-input label:hover,
    .rating-stars-input label:hover ~ label,
    .rating-stars-input input:checked ~ label { color:#fbbf24; }
    .tier-you { background:#fffbeb; }
    .note-inline { font-size:.78rem; color:var(--text-muted); }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="SidebarContent" runat="server">
  <fb:RoleSidebar runat="server" ID="roleSidebar" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="PageHeading" runat="server">Ratings &amp; Trust</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

  <div class="page-header">
    <h2>Ratings &amp; Trust System</h2>
    <p class="mb-0">Rate the people you completed a delivery with, and see how they rated you.</p>
  </div>

  <asp:Panel runat="server" ID="pnlMessage" Visible="false" CssClass="alert mb-3">
    <asp:Literal runat="server" ID="litMessage" />
  </asp:Panel>

  <div class="row g-4 mb-4">

    <!-- ================= My Trust Profile ================= -->
    <div class="col-lg-4">
      <div class="fb-card text-center" style="background:linear-gradient(145deg,var(--white),#f9fbf9)">
        <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,var(--green),var(--green-mid));color:#fff;display:flex;align-items:center;justify-content:center;font-family:'DM Serif Display',serif;font-size:2rem;margin:0 auto 1rem"><%= Server.HtmlEncode(MyInitials) %></div>
        <h5 style="margin-bottom:.2rem"><%= Server.HtmlEncode(MyName) %></h5>

        <div style="margin-bottom:1rem">
          <span class="trust-badge <%= TierCssClass %>"><%= TierIcon %> <%= Server.HtmlEncode(TierName) %></span>
        </div>

        <div class="star-row justify-content-center mb-1"><%= StarIcons(AverageStars) %></div>

        <div style="font-family:'DM Serif Display',serif;font-size:2.2rem;color:var(--green)"><%= AverageDisplay %></div>
        <div style="font-size:.8rem;color:var(--text-muted);margin-bottom:1.5rem"><%= RatingCountText %></div>

        <div class="row g-2 text-center">
          <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--green)"><%= CompletedCount %></div><div style="font-size:.72rem;color:var(--text-muted)"><%= Server.HtmlEncode(CompletedLabel) %></div></div></div>
          <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--blue)"><%= ReceivedCount %></div><div style="font-size:.72rem;color:var(--text-muted)">Ratings</div></div></div>
          <div class="col-4"><div style="background:var(--cream);border-radius:8px;padding:.7rem"><div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--amber)"><%= OpenFlagCount %></div><div style="font-size:.72rem;color:var(--text-muted)">Flags</div></div></div>
        </div>

        <div style="margin-top:1.2rem;padding-top:1.2rem;border-top:1.5px solid var(--sand)">
          <div style="font-size:.8rem;color:var(--text-muted);margin-bottom:.8rem">Trust Level Progress</div>
          <div class="fb-progress mb-1"><div class="fb-progress-bar" style="width:<%= TierProgressPercent %>%"></div></div>
          <div style="font-size:.75rem;color:var(--text-muted)"><%= Server.HtmlEncode(TierProgressText) %></div>
        </div>
      </div>
    </div>

    <div class="col-lg-8 d-flex flex-column gap-4">

      <!-- ================= Rating Breakdown ================= -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Rating Breakdown</h6>

        <asp:Panel runat="server" ID="pnlNoReceived" Visible="false" CssClass="empty-state" style="padding:2rem 1rem">
          <i class="bi bi-star"></i>
          <p>No ratings received yet. Once you complete a delivery, the other people on it can rate you here.</p>
        </asp:Panel>

        <asp:Panel runat="server" ID="pnlBreakdown" Visible="false">
          <div class="d-flex align-items-center gap-4 flex-wrap">
            <div style="text-align:center">
              <div style="font-family:'DM Serif Display',serif;font-size:4rem;color:var(--green);line-height:1"><%= AverageDisplay %></div>
              <div class="star-row justify-content-center my-1"><%= StarIcons(AverageStars) %></div>
              <div style="font-size:.78rem;color:var(--text-muted)"><%= RatingCountText %></div>
            </div>
            <div style="flex:1;min-width:220px">
              <asp:Repeater runat="server" ID="rptHistogram">
                <ItemTemplate>
                  <div class="d-flex align-items-center gap-2 mb-2" style="font-size:.83rem">
                    <span style="width:20px;text-align:right"><%# Eval("Stars") %></span>
                    <i class="bi bi-star-fill text-warning" style="font-size:.8rem"></i>
                    <div class="fb-progress" style="flex:1;height:8px">
                      <div class="fb-progress-bar" style='width:<%# Eval("Percent") %>%;<%# BarColour(Eval("Stars")) %>'></div>
                    </div>
                    <span style="width:28px;color:var(--text-muted)"><%# Eval("Count") %></span>
                  </div>
                </ItemTemplate>
              </asp:Repeater>
            </div>
          </div>
        </asp:Panel>
      </div>

      <!-- ================= Leave a Rating ================= -->
      <div class="fb-card" style="border:2px solid var(--green-pale)">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Rate a Completed Delivery</h6>

        <asp:Panel runat="server" ID="pnlNothingToRate" Visible="false" CssClass="empty-state" style="padding:2rem 1rem">
          <i class="bi bi-check2-circle"></i>
          <p><asp:Literal runat="server" ID="litNothingToRate" /></p>
        </asp:Panel>

        <asp:Panel runat="server" ID="pnlRateForm" Visible="false">
          <div class="fb-form-group">
            <label>Who are you rating?</label>
            <asp:DropDownList runat="server" ID="ddlRateable" CssClass="fb-input fb-select" />
          </div>

          <div class="fb-form-group">
            <label>Your Rating</label>
            <%-- Plain radios, not a RadioButtonList: the star widget is pure CSS
                 and depends on this exact reversed sibling order. Read back
                 server-side from Request.Form["fbStars"]. --%>
            <div class="rating-stars-input">
              <input type="radio" id="s5" name="fbStars" value="5" <%= StarChecked(5) %>/><label for="s5"><i class="bi bi-star-fill"></i></label>
              <input type="radio" id="s4" name="fbStars" value="4" <%= StarChecked(4) %>/><label for="s4"><i class="bi bi-star-fill"></i></label>
              <input type="radio" id="s3" name="fbStars" value="3" <%= StarChecked(3) %>/><label for="s3"><i class="bi bi-star-fill"></i></label>
              <input type="radio" id="s2" name="fbStars" value="2" <%= StarChecked(2) %>/><label for="s2"><i class="bi bi-star-fill"></i></label>
              <input type="radio" id="s1" name="fbStars" value="1" <%= StarChecked(1) %>/><label for="s1"><i class="bi bi-star-fill"></i></label>
            </div>
          </div>

          <div class="fb-form-group mb-3">
            <label>Comments <span class="note-inline">(optional)</span></label>
            <asp:TextBox runat="server" ID="txtComments" TextMode="MultiLine" CssClass="fb-input fb-textarea"
                         style="min-height:75px" MaxLength="500"
                         placeholder="How was the experience? Was the food quality good? Did the volunteer arrive on time?" />
          </div>

          <asp:Button runat="server" ID="btnSubmitRating" CssClass="btn-green"
                      Text="Submit Rating" OnClick="btnSubmitRating_Click" />
          <div class="note-inline mt-2">You can rate each person once per delivery. Ratings cannot be edited afterwards.</div>
        </asp:Panel>
      </div>

    </div>
  </div>

  <!-- ================= Reviews Received ================= -->
  <div class="fb-card mb-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h6 style="font-family:'DM Serif Display',serif;margin:0">Reviews Received</h6>
      <asp:DropDownList runat="server" ID="ddlReviewFilter" CssClass="fb-input fb-select"
                        style="width:auto;font-size:.83rem;padding:.35rem .8rem;border-radius:50px"
                        AutoPostBack="true" OnSelectedIndexChanged="ddlReviewFilter_SelectedIndexChanged">
        <asp:ListItem Text="All Reviews" Value="all" />
        <asp:ListItem Text="5 Star" Value="5" />
        <asp:ListItem Text="4 Star" Value="4" />
        <asp:ListItem Text="3 Star &amp; below" Value="low" />
      </asp:DropDownList>
    </div>

    <div class="d-flex flex-column gap-3">
      <asp:Repeater runat="server" ID="rptReceived">
        <ItemTemplate>
          <div class="review-card">
            <div class="d-flex justify-content-between align-items-start mb-2 gap-2">
              <div class="d-flex align-items-center gap-2">
                <div class="fb-avatar" style='<%# RoleAvatarStyle(Eval("RaterRole")) %>;width:32px;height:32px;font-size:.75rem'><%# Server.HtmlEncode(LeftoverFoodSystem.SessionHelper.Initials(Convert.ToString(Eval("RaterName")))) %></div>
                <div>
                  <div style="font-size:.88rem;font-weight:600">
                    <%# Server.HtmlEncode(Convert.ToString(Eval("RaterName"))) %>
                    <span class="badge-status <%# RoleBadgeClass(Eval("RaterRole")) %> ms-1"><%# Eval("RaterRole") %></span>
                  </div>
                  <div style="font-size:.75rem;color:var(--text-muted)">
                    Donation #<%# Eval("DonationID") %> · <%# Server.HtmlEncode(Truncate(Eval("FoodDescription"), 45)) %> · <%# ShortDate(Eval("CreatedAt")) %>
                  </div>
                </div>
              </div>
              <div class="star-row"><%# StarIcons(Convert.ToDecimal(Eval("Stars"))) %></div>
            </div>
            <p style="font-size:.87rem;color:var(--text-mid);margin:0"><%# CommentOrDash(Eval("Comments")) %></p>
          </div>
        </ItemTemplate>
      </asp:Repeater>

      <asp:Panel runat="server" ID="pnlNoReviews" Visible="false" CssClass="empty-state" style="padding:2.5rem 1rem">
        <i class="bi bi-chat-square-text"></i>
        <p><asp:Literal runat="server" ID="litNoReviews" /></p>
      </asp:Panel>
    </div>
  </div>

  <!-- ================= Ratings I've Given ================= -->
  <asp:Panel runat="server" ID="pnlGiven" Visible="false" CssClass="fb-card mb-4">
    <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Ratings You've Given</h6>
    <div class="d-flex flex-column gap-3">
      <asp:Repeater runat="server" ID="rptGiven">
        <ItemTemplate>
          <div class="review-card given">
            <div class="d-flex justify-content-between align-items-start mb-2 gap-2">
              <div class="d-flex align-items-center gap-2">
                <div class="fb-avatar" style='<%# RoleAvatarStyle(Eval("RateeRole")) %>;width:32px;height:32px;font-size:.75rem'><%# Server.HtmlEncode(LeftoverFoodSystem.SessionHelper.Initials(Convert.ToString(Eval("RateeName")))) %></div>
                <div>
                  <div style="font-size:.88rem;font-weight:600">
                    <%# Server.HtmlEncode(Convert.ToString(Eval("RateeName"))) %>
                    <span class="badge-status <%# RoleBadgeClass(Eval("RateeRole")) %> ms-1"><%# Eval("RateeRole") %></span>
                  </div>
                  <div style="font-size:.75rem;color:var(--text-muted)">
                    Donation #<%# Eval("DonationID") %> · <%# ShortDate(Eval("CreatedAt")) %>
                  </div>
                </div>
              </div>
              <div class="star-row"><%# StarIcons(Convert.ToDecimal(Eval("Stars"))) %></div>
            </div>
            <p style="font-size:.87rem;color:var(--text-mid);margin:0"><%# CommentOrDash(Eval("Comments")) %></p>
          </div>
        </ItemTemplate>
      </asp:Repeater>
    </div>
  </asp:Panel>

  <!-- ================= Trust Levels ================= -->
  <div class="fb-card">
    <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.4rem">Trust Level System</h6>
    <p class="note-inline mb-3">
      Levels are earned from completed deliveries and the average rating you receive.
      They are recognition only — no level currently changes how the app treats
      your account.
    </p>
    <div class="table-responsive">
      <table class="fb-table">
        <thead><tr><th class="ps-3">Level</th><th>Badge</th><th>Requirements</th></tr></thead>
        <tbody>
          <tr class='<%= TierRowClass("New") %>'><td class="ps-3"><strong>New<%= TierYouMarker("New") %></strong></td><td><span class="trust-badge trust-new">🆕 New</span></td><td>0–4 completed deliveries</td></tr>
          <tr class='<%= TierRowClass("Bronze") %>'><td class="ps-3"><strong>Bronze<%= TierYouMarker("Bronze") %></strong></td><td><span class="trust-badge trust-bronze">🥉 Bronze</span></td><td>5–19 completed, 4.0+ rating</td></tr>
          <tr class='<%= TierRowClass("Silver") %>'><td class="ps-3"><strong>Silver<%= TierYouMarker("Silver") %></strong></td><td><span class="trust-badge trust-silver">🥈 Silver</span></td><td>20–39 completed, 4.5+ rating</td></tr>
          <tr class='<%= TierRowClass("Gold") %>'><td class="ps-3"><strong>Gold<%= TierYouMarker("Gold") %></strong></td><td><span class="trust-badge trust-gold">🥇 Gold</span></td><td>40–59 completed, 4.7+ rating</td></tr>
          <tr class='<%= TierRowClass("Platinum") %>'><td class="ps-3"><strong>Platinum<%= TierYouMarker("Platinum") %></strong></td><td><span class="trust-badge trust-platinum">💎 Platinum</span></td><td>60+ completed, 4.8+ rating</td></tr>
          <tr class='<%= TierRowClass("Flagged") %>'><td class="ps-3"><strong>Flagged<%= TierYouMarker("Flagged") %></strong></td><td><span class="trust-badge trust-flagged">🚩 Flagged</span></td><td>3+ open fraud flags <span class="note-inline">(review queue is Phase 6b)</span></td></tr>
        </tbody>
      </table>
    </div>
  </div>

</asp:Content>
