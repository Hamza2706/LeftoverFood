<%@ Page Title="Volunteer Dashboard – FoodBridge" Language="C#" MasterPageFile="~/Volunteer/VolunteerMaster.master" AutoEventWireup="true" CodeBehind="volunteer-dashboard.aspx.cs" Inherits="LeftoverFood.Volunteer.volunteer_dashboard" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="VolunteerHeadContent" runat="server">
  <style>
    /* Same switch styling used on the donor notification settings page. */
    .toggle-switch input[type=checkbox] { -webkit-appearance:none; appearance:none; width:44px; height:24px; border-radius:50px; background:var(--sand-dark); position:relative; cursor:pointer; transition:background .2s; border:none; flex-shrink:0; margin:0; }
    .toggle-switch input[type=checkbox]:checked { background:var(--green); }
    .toggle-switch input[type=checkbox]::after { content:''; position:absolute; width:18px; height:18px; background:#fff; border-radius:50%; top:3px; left:3px; transition:left .2s; }
    .toggle-switch input[type=checkbox]:checked::after { left:23px; }
    .toggle-switch { display:flex; align-items:center; }
  </style>
  <!-- Phase 5: Leaflet (OpenStreetMap). No API key required. -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="VolunteerPageHeading" runat="server">Volunteer Dashboard</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="VolunteerMainContent" runat="server">

      <div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
        <div>
          <h2 style="font-size:1.6rem;margin-bottom:.2rem">Hey <%= LeftoverFoodSystem.SessionHelper.GetFullName() %>! Ready to help? 🚴</h2>
          <p class="text-muted" style="font-size:.9rem">You have <strong style="color:var(--amber)"><asp:Literal ID="litActiveTasksInline" runat="server" Text="0" /> active task(s)</strong> assigned to you.</p>
        </div>
      </div>

      <asp:Label ID="lblActionMessage" runat="server" Visible="false" CssClass="alert" Style="display:block" />

      <%-- Location sharing (Phase 5).

           Opt-in, off by default, and switched on only by the volunteer
           themselves. Nothing is collected while this is off — the toggle is
           re-checked server-side on every position ping, so turning it off
           stops collection immediately even if a stale tab keeps posting. --%>
      <div class="fb-card mb-4">
        <div class="d-flex align-items-start gap-3 flex-wrap">
          <div style="width:36px;height:36px;background:#e0e7ff;border-radius:8px;display:flex;align-items:center;justify-content:center;color:#1d4ed8;flex-shrink:0">
            <i class="bi bi-geo-alt-fill"></i>
          </div>
          <div style="flex:1;min-width:220px">
            <div style="font-size:.95rem;font-weight:600">Share my location during deliveries</div>
            <div style="font-size:.8rem;color:var(--text-muted);margin-top:.15rem">
              Lets the donor and the receiving NGO see where you are while a pickup is in progress.
              Your position is only recorded while you have an active delivery, is never shared with
              anyone outside that delivery, and stops automatically once you mark it delivered.
            </div>
            <div id="fbGeoStatus" style="font-size:.78rem;color:var(--text-muted);margin-top:.5rem"></div>
          </div>
          <asp:CheckBox runat="server" ID="chkShareLocation" CssClass="toggle-switch"
                        AutoPostBack="true" OnCheckedChanged="chkShareLocation_CheckedChanged" />
        </div>
      </div>

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
          <div class="fb-card p-0 overflow-hidden" id="my-tasks">
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
                  <%-- Route map (Phase 5): green pin = pickup, amber = NGO
                       drop-off. Hidden entirely when the pickup address never
                       resolved, so the address line above stays the answer. --%>
                  <div class="fb-map mb-2"
                       style='<%# HasCoords(Eval("Latitude")) ? "height:170px;border-radius:8px" : "display:none" %>'
                       data-lat='<%# Coord(Eval("Latitude")) %>'
                       data-lng='<%# Coord(Eval("Longitude")) %>'
                       data-precision='<%# Eval("GeoPrecision") %>'
                       data-label='<%# Server.HtmlEncode(Convert.ToString(Eval("PickupAddress"))) %>'
                       data-dest-lat='<%# DestLat(Eval("NGOAddress"), Eval("NGOCity")) %>'
                       data-dest-lng='<%# DestLng(Eval("NGOAddress"), Eval("NGOCity")) %>'
                       data-dest-label='<%# Server.HtmlEncode(NgoLabel(Eval("NGOOrgName"), Eval("NGOName")) + " — drop-off") %>'
                       data-tile-url='<%# MapTileUrl %>'
                       data-attribution='<%# MapAttribution %>'></div>
                  <div style='font-size:.72rem;color:var(--text-muted);margin-bottom:.5rem;<%# Convert.ToString(Eval("GeoPrecision")) == "City" ? "" : "display:none" %>'>
                    Pickup pin is approximate — city level only. Use the address and contact number above.
                  </div>

                  <div class="fb-progress mb-2"><div class="fb-progress-bar" style="width:<%# Eval("Status").ToString() == "PickedUp" ? "65" : "10" %>%"></div></div>
                  <div class="d-flex justify-content-between" style="font-size:.78rem;color:var(--text-muted)">
                    <span>Pick up</span><span>In Transit</span><span>Deliver</span>
                  </div>
                  <div class="d-flex gap-2 mt-3">
                    <asp:LinkButton runat="server" CssClass="btn-sm-amber" CommandName="Pickup" CommandArgument='<%# Eval("AssignmentID") %>' Visible='<%# Eval("Status").ToString() == "Assigned" %>'><i class="bi bi-check2 me-1"></i>Confirm Pickup</asp:LinkButton>
                    <asp:LinkButton runat="server" CssClass="btn-sm-green" CommandName="Deliver" CommandArgument='<%# Eval("AssignmentID") %>' Visible='<%# Eval("Status").ToString() == "PickedUp" %>'><i class="bi bi-check2 me-1"></i>Mark Delivered</asp:LinkButton>
                    <asp:HyperLink runat="server" CssClass="btn-sm-outline" Target="_blank"
                                   NavigateUrl='<%# DirectionsUrl(Eval("Latitude"), Eval("Longitude"), Eval("NGOAddress"), Eval("NGOCity")) %>'
                                   Visible='<%# HasCoords(Eval("Latitude")) %>'><i class="bi bi-signpost-split me-1"></i>Directions</asp:HyperLink>
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
          <div class="fb-card" id="completed">
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

<asp:Content ID="ContentFooter" ContentPlaceHolderID="VolunteerFooterScripts" runat="server">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="<%= ResolveUrl("~/assets/js/fb-map.js") %>"></script>
<script>
/* Volunteer position reporting (Phase 5).

   Runs only when the volunteer has opted in AND has an active delivery. Both
   flags come from the server, and LocationHandler re-checks both on every
   ping, so tampering with them here gains nothing.

   Uses watchPosition rather than a timer: the browser only wakes us when the
   position actually changes, which is easier on the battery than polling GPS.
   Uploads are throttled so a fast-moving volunteer does not post continuously. */
(function () {
    'use strict';

    var sharing = <%= ShareLocationJs %>;
    var hasActiveTask = <%= HasActiveTaskJs %>;
    var endpoint = '<%= ResolveUrl("~/LocationHandler.ashx") %>';
    var statusEl = document.getElementById('fbGeoStatus');

    function say(msg) { if (statusEl) statusEl.textContent = msg; }

    if (!sharing) { say('Location sharing is off.'); return; }
    if (!hasActiveTask) { say('Sharing is on. Nothing is recorded until you have an active delivery.'); return; }
    if (!navigator.geolocation) { say('This browser does not support location sharing.'); return; }

    var lastSent = 0;
    var MIN_GAP_MS = 15000;

    /* Release the GPS watch once there is nothing left to report. Without this
       the browser kept waking us for every position change until the tab was
       closed — draining a phone battery to post pings the server would only
       reject. Any postback on this page re-runs the script, so finishing a
       pickup and starting the next delivery starts a fresh watch. */
    var watchId = null;
    var stopped = false;

    function stopWatch(msg) {
        stopped = true;
        if (watchId !== null) {
            navigator.geolocation.clearWatch(watchId);
            watchId = null;
        }
        say(msg);
    }

    watchId = navigator.geolocation.watchPosition(function (pos) {
        if (stopped) return;

        var now = Date.now();
        if (now - lastSent < MIN_GAP_MS) return;
        lastSent = now;

        var body = 'lat=' + encodeURIComponent(pos.coords.latitude)
                 + '&lng=' + encodeURIComponent(pos.coords.longitude)
                 + '&accuracy=' + encodeURIComponent(pos.coords.accuracy || '');

        var xhr = new XMLHttpRequest();
        xhr.open('POST', endpoint + '?action=report', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4) return;

            // The session is gone, or the server says sharing is off — neither
            // recovers by sending the next fix.
            if (xhr.status === 401) { stopWatch('Signed out — location sharing stopped.'); return; }
            if (xhr.status === 403) { stopWatch('Location sharing is off — nothing further is being sent.'); return; }

            if (xhr.status !== 200) { say('Could not send your location.'); return; }

            var data = null;
            try { data = JSON.parse(xhr.responseText); } catch (e) { }

            // tracking:false means no active delivery — the last drop-off is
            // done, so stop until a postback says otherwise.
            if (data && data.tracking === false) {
                stopWatch('No active delivery — location sharing paused.');
                return;
            }

            say('Sharing your location · last update ' +
                new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
        };
        xhr.send(body);
    }, function (err) {
        // Most common case is the browser permission prompt being denied,
        // which is a separate decision from the in-app toggle.
        say(err.code === err.PERMISSION_DENIED
            ? 'Your browser blocked location access. Allow it to share your position.'
            : 'Could not get your location.');
    }, { enableHighAccuracy: true, maximumAge: 10000, timeout: 20000 });
})();
</script>
</asp:Content>
