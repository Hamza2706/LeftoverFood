<%@ Page Title="Reports & Analytics – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="reports.aspx.cs" Inherits="LeftoverFood.Admin.reports" %>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .chart-bar-wrap { display:flex; flex-direction:column; gap:.5rem; }
    .chart-bar-row { display:flex; align-items:center; gap:.75rem; font-size:.83rem; }
    .chart-bar-label { width:90px; text-align:right; color:var(--text-muted); flex-shrink:0; }
    .chart-bar-bg { flex:1; height:24px; background:var(--sand); border-radius:50px; overflow:hidden; }
    .chart-bar-fill { height:100%; border-radius:50px; display:flex; align-items:center; padding-left:.6rem; color:#fff; font-size:.75rem; font-weight:600; transition:width .6s ease; }
    .chart-bar-val { width:42px; text-align:right; font-weight:700; color:var(--text-dark); font-size:.83rem; flex-shrink:0; }

    .donut-wrap { position:relative; width:140px; height:140px; flex-shrink:0; }
    .donut-wrap svg { transform:rotate(-90deg); }
    .donut-center { position:absolute; inset:0; display:flex; flex-direction:column; align-items:center; justify-content:center; }

    .kpi-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.4rem; }
    .kpi-card .kpi-val { font-family:'DM Serif Display',serif; font-size:2rem; line-height:1.1; }
    .kpi-card .kpi-lbl { font-size:.76rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:.5px; margin-top:.25rem; }
    .kpi-card .kpi-change { font-size:.8rem; font-weight:600; margin-top:.5rem; }
    .up { color:#16a34a; } .down { color:var(--red); }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Reports & Analytics</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

      <div class="page-header">
        <h2>Food Waste Analytics — April 2025</h2>
        <p class="text-muted">Comprehensive report of all donation activity, distribution efficiency, and system performance.</p>
      </div>

      <!-- KPI CARDS -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="kpi-card">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
              <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
              <span class="kpi-change up"><i class="bi bi-arrow-up"></i>8%</span>
            </div>
            <div class="kpi-val" style="color:var(--green)">248</div>
            <div class="kpi-lbl">Total Donations</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="kpi-card">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
              <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
              <span class="kpi-change up"><i class="bi bi-arrow-up"></i>22%</span>
            </div>
            <div class="kpi-val" style="color:var(--purple)">5,830</div>
            <div class="kpi-lbl">Meals Distributed</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="kpi-card">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
              <div class="stat-icon" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-check2-circle"></i></div>
              <span class="kpi-change up"><i class="bi bi-arrow-up"></i>3%</span>
            </div>
            <div class="kpi-val" style="color:var(--blue)">94%</div>
            <div class="kpi-lbl">Fulfillment Rate</div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="kpi-card">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
              <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-trash3-fill"></i></div>
              <span class="kpi-change down"><i class="bi bi-arrow-down"></i>12%</span>
            </div>
            <div class="kpi-val" style="color:var(--amber)">14</div>
            <div class="kpi-lbl">Expired Donations</div>
          </div>
        </div>
      </div>

      <div class="row g-4 mb-4">

        <!-- Monthly Donations Bar Chart -->
        <div class="col-lg-7">
          <div class="fb-card h-100">
            <div class="d-flex justify-content-between align-items-center mb-4">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Monthly Donations (2025)</h6>
              <div class="d-flex gap-2">
                <span style="display:flex;align-items:center;gap:.3rem;font-size:.78rem"><span style="width:10px;height:10px;background:var(--green);border-radius:2px;display:inline-block"></span>Delivered</span>
                <span style="display:flex;align-items:center;gap:.3rem;font-size:.78rem"><span style="width:10px;height:10px;background:var(--amber);border-radius:2px;display:inline-block"></span>Pending</span>
                <span style="display:flex;align-items:center;gap:.3rem;font-size:.78rem"><span style="width:10px;height:10px;background:#f87171;border-radius:2px;display:inline-block"></span>Expired</span>
              </div>
            </div>
            <div class="chart-bar-wrap">
              <div class="chart-bar-row"><span class="chart-bar-label">January</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:60%;background:var(--green)">142</div></div><span class="chart-bar-val">142</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">February</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:68%;background:var(--green)">160</div></div><span class="chart-bar-val">160</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">March</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:77%;background:var(--green)">184</div></div><span class="chart-bar-val">184</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">April</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:100%;background:var(--green)">234</div></div><span class="chart-bar-val">248</span></div>
            </div>
            <div style="margin-top:1.5rem;padding-top:1.2rem;border-top:1px solid var(--sand)">
              <div style="font-size:.82rem;color:var(--text-muted);margin-bottom:.8rem;font-weight:600">April Breakdown</div>
              <div class="d-flex gap-3 flex-wrap">
                <div style="background:#e8f5ee;border-radius:8px;padding:.5rem .9rem;font-size:.82rem"><strong style="color:var(--green)">234</strong> Delivered</div>
                <div style="background:#fff3e0;border-radius:8px;padding:.5rem .9rem;font-size:.82rem"><strong style="color:var(--amber)">8</strong> Pending</div>
                <div style="background:#fee2e2;border-radius:8px;padding:.5rem .9rem;font-size:.82rem"><strong style="color:var(--red)">14</strong> Expired</div>
                <div style="background:var(--cream);border-radius:8px;padding:.5rem .9rem;font-size:.82rem"><strong>2</strong> Rejected</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Donation by Category Donut -->
        <div class="col-lg-5">
          <div class="fb-card h-100">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.5rem">Donations by Category</h6>
            <div class="d-flex align-items-center gap-4 flex-wrap">
              <!-- CSS Donut Chart -->
              <div class="donut-wrap">
                <svg width="140" height="140" viewBox="0 0 140 140">
                  <circle cx="70" cy="70" r="55" fill="none" stroke="var(--sand)" stroke-width="20"/>
                  <!-- Cooked 42% -->
                  <circle cx="70" cy="70" r="55" fill="none" stroke="var(--green)" stroke-width="20"
                    stroke-dasharray="145 200" stroke-dashoffset="0"/>
                  <!-- Bakery 22% -->
                  <circle cx="70" cy="70" r="55" fill="none" stroke="var(--amber)" stroke-width="20"
                    stroke-dasharray="76 345" stroke-dashoffset="-145"/>
                  <!-- Raw 18% -->
                  <circle cx="70" cy="70" r="55" fill="none" stroke="var(--blue)" stroke-width="20"
                    stroke-dasharray="62 345" stroke-dashoffset="-221"/>
                  <!-- Packaged 18% -->
                  <circle cx="70" cy="70" r="55" fill="none" stroke="var(--purple)" stroke-width="20"
                    stroke-dasharray="62 345" stroke-dashoffset="-283"/>
                </svg>
                <div class="donut-center">
                  <div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--green)">248</div>
                  <div style="font-size:.65rem;color:var(--text-muted);text-align:center">Total</div>
                </div>
              </div>
              <div class="d-flex flex-column gap-2 flex-grow-1">
                <div style="display:flex;justify-content:space-between;font-size:.85rem"><span style="display:flex;align-items:center;gap:.5rem"><span style="width:10px;height:10px;background:var(--green);border-radius:2px;display:inline-block"></span>Cooked Meals</span><strong>42%</strong></div>
                <div style="display:flex;justify-content:space-between;font-size:.85rem"><span style="display:flex;align-items:center;gap:.5rem"><span style="width:10px;height:10px;background:var(--amber);border-radius:2px;display:inline-block"></span>Bakery Items</span><strong>22%</strong></div>
                <div style="display:flex;justify-content:space-between;font-size:.85rem"><span style="display:flex;align-items:center;gap:.5rem"><span style="width:10px;height:10px;background:var(--blue);border-radius:2px;display:inline-block"></span>Raw Produce</span><strong>18%</strong></div>
                <div style="display:flex;justify-content:space-between;font-size:.85rem"><span style="display:flex;align-items:center;gap:.5rem"><span style="width:10px;height:10px;background:var(--purple);border-radius:2px;display:inline-block"></span>Packaged Food</span><strong>18%</strong></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="row g-4 mb-4">

        <!-- Top Donors -->
        <div class="col-lg-6">
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);display:flex;justify-content:space-between;align-items:center">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Top Donors — April</h6>
              <span class="badge-status badge-role-donor">Ranking</span>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">Rank</th><th>Donor</th><th>Donations</th><th>Meals</th><th>Rating</th></tr></thead>
                <tbody>
                  <tr><td class="ps-3">🥇 1</td><td><strong>Ali's Restaurant</strong><br><small class="text-muted">Karachi</small></td><td>28</td><td>840</td><td>⭐ 4.9</td></tr>
                  <tr><td class="ps-3">🥈 2</td><td><strong>Park View Catering</strong><br><small class="text-muted">Lahore</small></td><td>14</td><td>1,200</td><td>⭐ 4.8</td></tr>
                  <tr><td class="ps-3">🥉 3</td><td><strong>Marriott Hotel</strong><br><small class="text-muted">Karachi</small></td><td>9</td><td>980</td><td>⭐ 4.7</td></tr>
                  <tr><td class="ps-3">4</td><td><strong>Bake House LHR</strong><br><small class="text-muted">Lahore</small></td><td>7</td><td>280</td><td>⭐ 5.0</td></tr>
                  <tr><td class="ps-3">5</td><td><strong>Sara Ahmed (Home)</strong><br><small class="text-muted">Islamabad</small></td><td>5</td><td>50</td><td>⭐ 5.0</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Top NGOs -->
        <div class="col-lg-6">
          <div class="fb-card p-0 overflow-hidden">
            <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);display:flex;justify-content:space-between;align-items:center">
              <h6 style="font-family:'DM Serif Display',serif;margin:0">Top NGOs — April</h6>
              <span class="badge-status badge-role-ngo">Performance</span>
            </div>
            <div class="table-responsive">
              <table class="fb-table">
                <thead><tr><th class="ps-3">NGO</th><th>Accepted</th><th>Delivered</th><th>Rate</th><th>Rating</th></tr></thead>
                <tbody>
                  <tr><td class="ps-3"><strong>Edhi Foundation</strong></td><td>72</td><td>70</td><td><span style="color:var(--green);font-weight:700">97%</span></td><td>⭐ 4.9</td></tr>
                  <tr><td class="ps-3"><strong>Saylani Welfare</strong></td><td>64</td><td>61</td><td><span style="color:var(--green);font-weight:700">95%</span></td><td>⭐ 4.8</td></tr>
                  <tr><td class="ps-3"><strong>Al-Khidmat</strong></td><td>48</td><td>45</td><td><span style="color:var(--amber);font-weight:700">94%</span></td><td>⭐ 4.7</td></tr>
                  <tr><td class="ps-3"><strong>Akhuwat</strong></td><td>36</td><td>34</td><td><span style="color:var(--amber);font-weight:700">94%</span></td><td>⭐ 4.8</td></tr>
                  <tr><td class="ps-3"><strong>JDC Foundation</strong></td><td>28</td><td>24</td><td><span style="color:var(--red);font-weight:700">86%</span></td><td>⭐ 4.5</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- Expiry Stats -->
      <div class="row g-4 mb-4">
        <div class="col-lg-5">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-clock-fill me-2 text-warning"></i>Expiry & Waste Analysis</h6>
            <div class="d-flex flex-column gap-3">
              <div><div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Delivered before expiry</span><strong style="color:var(--green)">94%</strong></div><div class="fb-progress"><div class="fb-progress-bar" style="width:94%"></div></div></div>
              <div><div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Expired (not picked)</span><strong style="color:var(--red)">5.6%</strong></div><div class="fb-progress"><div class="fb-progress-bar" style="width:5.6%;background:var(--red)"></div></div></div>
              <div><div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Avg. pickup time</span><strong>1h 22m</strong></div><div class="fb-progress"><div class="fb-progress-bar" style="width:55%;background:var(--blue)"></div></div></div>
            </div>
            <div style="background:var(--cream);border-radius:10px;padding:1rem;margin-top:1.2rem;display:flex;gap:1rem;align-items:center">
              <i class="bi bi-lightbulb-fill" style="font-size:1.5rem;color:var(--amber)"></i>
              <div style="font-size:.82rem;color:var(--text-muted)">14 donations expired this month. Sending donor reminders earlier could reduce expiry by ~40%.</div>
            </div>
          </div>
        </div>
        <div class="col-lg-7">
          <div class="fb-card">
            <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Donations by City</h6>
            <div class="chart-bar-wrap">
              <div class="chart-bar-row"><span class="chart-bar-label">Karachi</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:100%;background:var(--green)">112</div></div><span class="chart-bar-val">112</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">Lahore</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:70%;background:var(--green-mid)">78</div></div><span class="chart-bar-val">78</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">Islamabad</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:40%;background:var(--blue)">44</div></div><span class="chart-bar-val">44</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">Rawalpindi</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:18%;background:var(--amber)">20</div></div><span class="chart-bar-val">20</span></div>
              <div class="chart-bar-row"><span class="chart-bar-label">Peshawar</span><div class="chart-bar-bg"><div class="chart-bar-fill" style="width:10%;background:var(--purple)">11</div></div><span class="chart-bar-val">11</span></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Export options -->
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1rem">Export Reports</h6>
        <div class="row g-3">
          <div class="col-sm-6 col-md-3">
            <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center;cursor:pointer;transition:all .2s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--sand)'" onclick="fbToast('Downloading Monthly Report PDF...')">
              <i class="bi bi-file-earmark-pdf-fill" style="font-size:2rem;color:#dc2626;display:block;margin-bottom:.5rem"></i>
              <div style="font-weight:600;font-size:.88rem">Monthly Report</div>
              <div style="font-size:.76rem;color:var(--text-muted)">PDF Format</div>
            </div>
          </div>
          <div class="col-sm-6 col-md-3">
            <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center;cursor:pointer;transition:all .2s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--sand)'" onclick="fbToast('Downloading Donor List Excel...')">
              <i class="bi bi-file-earmark-excel-fill" style="font-size:2rem;color:#16a34a;display:block;margin-bottom:.5rem"></i>
              <div style="font-weight:600;font-size:.88rem">Donor List</div>
              <div style="font-size:.76rem;color:var(--text-muted)">Excel Format</div>
            </div>
          </div>
          <div class="col-sm-6 col-md-3">
            <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center;cursor:pointer;transition:all .2s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--sand)'" onclick="fbToast('Downloading NGO Performance Report...')">
              <i class="bi bi-file-earmark-bar-graph-fill" style="font-size:2rem;color:var(--blue);display:block;margin-bottom:.5rem"></i>
              <div style="font-weight:600;font-size:.88rem">NGO Performance</div>
              <div style="font-size:.76rem;color:var(--text-muted)">Excel Format</div>
            </div>
          </div>
          <div class="col-sm-6 col-md-3">
            <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center;cursor:pointer;transition:all .2s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--sand)'" onclick="fbToast('Downloading Waste Analytics CSV...')">
              <i class="bi bi-file-earmark-text-fill" style="font-size:2rem;color:var(--amber);display:block;margin-bottom:.5rem"></i>
              <div style="font-weight:600;font-size:.88rem">Waste Analytics</div>
              <div style="font-size:.76rem;color:var(--text-muted)">CSV Format</div>
            </div>
          </div>
        </div>
      </div>

</asp:Content>
