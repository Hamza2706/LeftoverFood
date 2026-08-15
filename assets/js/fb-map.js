/* ============================================================================
   FoodBridge maps (Phase 5) — Leaflet + OpenStreetMap.

   No API key and no billing account. In exchange, OSM's tile policy requires
   the attribution control stay visible; Leaflet adds it by default and we do
   not remove it.

   Every map on the site is created through fbInitMaps(), which reads its
   configuration from data- attributes so no page has to write Leaflet code:

     <div class="fb-map"
          data-lat="24.86" data-lng="67.01"
          data-precision="Exact|City"
          data-label="Pickup point"
          data-dest-lat="..." data-dest-lng="..." data-dest-label="..."
          data-track-url="/LocationHandler.ashx?donationId=12"
          data-poll-seconds="20"></div>

   A container with no data-lat renders nothing — the page is expected to show
   the address as text instead. Dropping a pin we cannot justify would be worse
   than showing no pin.
   ========================================================================== */

(function () {
    'use strict';

    // Coloured circular markers, matching the app's status palette. Leaflet's
    // default marker needs image assets; a divIcon avoids that dependency
    // entirely and keeps everything self-contained.
    function dot(color) {
        return L.divIcon({
            className: 'fb-map-dot',
            html: '<span style="display:block;width:16px;height:16px;border-radius:50%;'
                + 'background:' + color + ';border:3px solid #fff;'
                + 'box-shadow:0 0 0 1px rgba(0,0,0,.25)"></span>',
            iconSize: [16, 16],
            iconAnchor: [8, 8]
        });
    }

    var PICKUP = '#2f7a4d';     // green  — donor pickup point
    var DEST = '#b45309';       // amber  — NGO drop-off
    var VOLUNTEER = '#1d4ed8';  // blue   — volunteer, live

    function num(el, name) {
        var v = el.getAttribute(name);
        if (v === null || v === '') return null;
        var f = parseFloat(v);
        return isNaN(f) ? null : f;
    }

    function initOne(el) {
        var lat = num(el, 'data-lat');
        var lng = num(el, 'data-lng');

        // No usable coordinates — leave the container alone so the page's own
        // address-text fallback is what the user sees.
        if (lat === null || lng === null) return;

        var map = L.map(el, { scrollWheelZoom: false })
                   .setView([lat, lng], el.getAttribute('data-precision') === 'City' ? 11 : 15);

        L.tileLayer(el.getAttribute('data-tile-url'), {
            attribution: el.getAttribute('data-attribution'),
            maxZoom: 19
        }).addTo(map);

        var bounds = [[lat, lng]];

        var pickupLabel = el.getAttribute('data-label') || 'Pickup point';
        if (el.getAttribute('data-precision') === 'City') {
            // Say so on the marker itself, not just in the page text — this is
            // the city centre, not the pickup address.
            pickupLabel += '<br><em style="color:#6b7280;font-size:.75rem">'
                        + 'Approximate — city level only</em>';
        }
        L.marker([lat, lng], { icon: dot(PICKUP) }).addTo(map).bindPopup(pickupLabel);

        // Optional NGO drop-off point.
        var dLat = num(el, 'data-dest-lat'), dLng = num(el, 'data-dest-lng');
        if (dLat !== null && dLng !== null) {
            L.marker([dLat, dLng], { icon: dot(DEST) }).addTo(map)
             .bindPopup(el.getAttribute('data-dest-label') || 'Drop-off point');

            // A straight line, not a driving route. Routing needs a directions
            // service; pretending this is a road route would be a lie.
            L.polyline([[lat, lng], [dLat, dLng]],
                       { color: '#9ca3af', weight: 2, dashArray: '6,6' }).addTo(map);

            bounds.push([dLat, dLng]);
        }

        if (bounds.length > 1) map.fitBounds(bounds, { padding: [30, 30] });

        // Optional live volunteer marker.
        var trackUrl = el.getAttribute('data-track-url');
        if (trackUrl) startTracking(map, trackUrl, num(el, 'data-poll-seconds') || 20);

        // Leaflet mis-measures a container that was hidden or resized at init.
        setTimeout(function () { map.invalidateSize(); }, 200);
    }

    /* Poll the volunteer's last reported position. Deliberately a poll rather
       than a socket: this app is Web Forms with no realtime infrastructure, and
       a 20s poll is entirely adequate for a delivery. */
    function startTracking(map, url, seconds) {
        var marker = null;
        var timer = null;
        var stopped = false;
        var note = L.control({ position: 'bottomleft' });

        /* Tear the poll down once it can only ever get the same answer back.
           Without this a tracking page left open kept asking every 20 seconds
           indefinitely after the delivery had finished.

           The `stopped` flag exists because the first tick() is fired before
           setInterval is assigned. Today that callback cannot run until the
           assignment has happened, but relying on that ordering is fragile —
           the flag makes an early terminal response stop the poll outright
           rather than clearing a timer that does not exist yet. */
        function stop(noteEl, message) {
            stopped = true;
            if (timer) { clearInterval(timer); timer = null; }
            if (noteEl) noteEl.innerHTML = message;
        }

        note.onAdd = function () {
            var div = L.DomUtil.create('div', 'fb-map-note');
            div.style.cssText = 'background:rgba(255,255,255,.9);padding:3px 8px;'
                              + 'border-radius:4px;font-size:.72rem;color:#4b5563';
            div.innerHTML = 'Waiting for volunteer location…';
            return div;
        };
        note.addTo(map);

        function tick() {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', url + (url.indexOf('?') < 0 ? '?' : '&') + '_=' + Date.now(), true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== 4) return;

                var noteEl = document.querySelector('.fb-map-note');

                // 401/403/404 will not fix themselves by asking again: the
                // session is gone, or this donation is not one we may track.
                // Anything else (500, a dropped connection) may well be
                // transient, so keep polling through it.
                if (xhr.status === 401 || xhr.status === 403 || xhr.status === 404) {
                    stop(noteEl, 'Volunteer location unavailable');
                    return;
                }

                if (xhr.status !== 200) {
                    if (noteEl) noteEl.innerHTML = 'Volunteer location unavailable';
                    return;
                }

                var data;
                try { data = JSON.parse(xhr.responseText); } catch (e) { return; }

                if (!data || !data.ok || data.lat === null || typeof data.lat === 'undefined') {
                    // Distinguish "not sharing" from "sharing but no fix yet",
                    // so the donor is not left guessing why there is no pin.
                    var msg = data && data.message ? data.message : 'Volunteer location unavailable';

                    // The server marks the delivery ending as terminal; every
                    // other no-position state can still resolve.
                    if (data && data.done) stop(noteEl, msg);
                    else if (noteEl) noteEl.innerHTML = msg;
                    return;
                }

                if (marker) {
                    marker.setLatLng([data.lat, data.lng]);
                } else {
                    marker = L.marker([data.lat, data.lng], { icon: dot(VOLUNTEER) })
                              .addTo(map).bindPopup('Volunteer');
                }

                if (noteEl) {
                    noteEl.innerHTML = 'Volunteer location · updated ' + (data.ago || 'just now')
                        + (data.accuracy ? ' · within ~' + Math.round(data.accuracy) + ' m' : '');
                }
            };
            xhr.send();
        }

        tick();
        if (!stopped) timer = setInterval(tick, Math.max(10, seconds) * 1000);
    }

    window.fbInitMaps = function () {
        if (typeof L === 'undefined') return;   // Leaflet CDN blocked/offline
        var nodes = document.querySelectorAll('.fb-map');
        for (var i = 0; i < nodes.length; i++) initOne(nodes[i]);
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', window.fbInitMaps);
    } else {
        window.fbInitMaps();
    }
})();
