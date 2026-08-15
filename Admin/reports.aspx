<%@ Page Title="Reports & Analytics – FoodBridge Admin" Language="C#" MasterPageFile="~/Admin/AdminMaster.master" AutoEventWireup="true" CodeBehind="reports.aspx.cs" Inherits="LeftoverFood.Admin.reports" %>

<%--
  Phase 6d. Every number on this page is now a query.

  The mockup was headed "April 2025" and hardcoded all of it: 248 donations,
  5,830 meals, a 94% fulfilment rate, four months of bar chart, five named top
  donors, five named NGOs, and five cities. It also carried change arrows
  ("↑8%") against no comparison period at all.

  EXPORTS — deliberate deviation from the roadmap, agreed before building.
  §6d planned ClosedXML for .xlsx and iTextSharp/itext7 for PDF. Neither is
  used:

    - Excel  -> CSV with a UTF-8 BOM. Excel opens it natively on double-click,
                and the BOM is what makes it read Urdu and other non-ASCII food
                descriptions correctly instead of mojibake — the same class of
                bug Phase 4 found when Notifications.Message was varchar rather
                than nvarchar. ClosedXML would have meant hand-resolving a
                dependency tree into a packages.config project with no
                nuget.exe available.
    - PDF    -> a print stylesheet plus the browser's own Save as PDF. The
                buttons say "Print / Save as PDF" rather than "PDF Format",
                because a download that is really a print dialog should say so.

  This keeps the project at exactly one NuGet package, which is where it
  started. If your supervisor requires a server-generated PDF file, that is the
  one thing here that would need a real library.
--%>

<asp:Content ID="Content1" ContentPlaceHolderID="AdminHeadContent" runat="server">
  <style>
    .chart-bar-wrap { display:flex; flex-direction:column; gap:.5rem; }
    .chart-bar-row { display:flex; align-items:center; gap:.75rem; font-size:.83rem; }
    .chart-bar-label { width:90px; text-align:right; color:var(--text-muted); flex-shrink:0; }
    .chart-bar-bg { flex:1; height:24px; background:var(--sand); border-radius:50px; overflow:hidden; }
    .chart-bar-fill { height:100%; border-radius:50px; display:flex; align-items:center; padding-left:.6rem; color:#fff; font-size:.75rem; font-weight:600; }
    .chart-bar-val { width:42px; text-align:right; font-weight:700; color:var(--text-dark); font-size:.83rem; flex-shrink:0; }

    .donut-wrap { position:relative; width:140px; height:140px; flex-shrink:0; }
    .donut-wrap svg { transform:rotate(-90deg); }
    .donut-center { position:absolute; inset:0; display:flex; flex-direction:column; align-items:center; justify-content:center; }

    .kpi-card { background:var(--white); border-radius:var(--radius); border:1.5px solid var(--sand); padding:1.4rem; }
    .kpi-card .kpi-val { font-family:'DM Serif Display',serif; font-size:2rem; line-height:1.1; }
    .kpi-card .kpi-lbl { font-size:.76rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:.5px; margin-top:.25rem; }
    .kpi-card .kpi-change { font-size:.8rem; font-weight:600; margin-top:.5rem; }
    .up { color:#16a34a; } .down { color:var(--red); }
    .note-inline { font-size:.78rem; color:var(--text-muted); }

    /* Phase 6d: this is the "PDF export". Hiding the app chrome and the
       controls that cannot be pressed on paper turns the browser's own
       Save-as-PDF into a presentable report. */
    @media print {
      .fb-sidebar, .fb-topbar, .no-print { display:none !important; }
      .fb-main, .fb-content { margin:0 !important; padding:0 !important; }
      .fb-card, .kpi-card { break-inside:avoid; border:1px solid #ddd !important; box-shadow:none !important; }
      body { background:#fff !important; }
      a[href]:after { content:""; }
    }
  </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="AdminPageHeading" runat="server">Reports &amp; Analytics</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="AdminMainContent" runat="server">

  <div class="page-header d-flex justify-content-between align-items-start flex-wrap gap-3">
    <div>
      <h2>Food Waste Analytics — <asp:Literal runat="server" ID="litPeriodLabel" /></h2>
      <p class="text-muted mb-0">Donation activity, distribution efficiency and system performance, generated live from the database.</p>
    </div>
    <div class="d-flex gap-2 align-items-center no-print">
      <asp:DropDownList runat="server" ID="ddlPeriod" CssClass="fb-input fb-select"
                        style="width:auto;font-size:.85rem;padding:.4rem .9rem;border-radius:50px"
                        AutoPostBack="true" OnSelectedIndexChanged="ddlPeriod_SelectedIndexChanged">
        <asp:ListItem Text="This month" Value="month" />
        <asp:ListItem Text="Last 30 days" Value="30" />
        <asp:ListItem Text="This year" Value="year" />
        <asp:ListItem Text="All time" Value="all" />
      </asp:DropDownList>
      <button type="button" class="btn-sm-outline" onclick="window.print()">
        <i class="bi bi-printer me-1"></i>Print / Save as PDF
      </button>
    </div>
  </div>

  <asp:Panel runat="server" ID="pnlEmpty" Visible="false" CssClass="alert alert-warning mb-4">
    <asp:Literal runat="server" ID="litEmpty" />
  </asp:Panel>

  <!-- ===================== KPIs ===================== -->
  <div class="row g-3 mb-4">
    <div class="col-6 col-md-3">
      <div class="kpi-card">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
          <div class="stat-icon" style="background:#e8f5ee;color:var(--green)"><i class="bi bi-basket2-fill"></i></div>
          <asp:Literal runat="server" ID="litDonationsChange" />
        </div>
        <div class="kpi-val" style="color:var(--green)"><asp:Literal runat="server" ID="litTotalDonations" /></div>
        <div class="kpi-lbl">Total Donations</div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="kpi-card">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
          <div class="stat-icon" style="background:var(--purple-light);color:var(--purple)"><i class="bi bi-people-fill"></i></div>
          <asp:Literal runat="server" ID="litMealsChange" />
        </div>
        <div class="kpi-val" style="color:var(--purple)"><asp:Literal runat="server" ID="litMealsDistributed" /></div>
        <div class="kpi-lbl">Meals Distributed</div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="kpi-card">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
          <div class="stat-icon" style="background:var(--blue-light);color:var(--blue)"><i class="bi bi-check2-circle"></i></div>
        </div>
        <div class="kpi-val" style="color:var(--blue)"><asp:Literal runat="server" ID="litFulfilment" /></div>
        <div class="kpi-lbl">Fulfilment Rate</div>
        <div class="note-inline mt-1">Delivered ÷ donations that reached approval</div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="kpi-card">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.5rem">
          <div class="stat-icon" style="background:var(--amber-light);color:var(--amber)"><i class="bi bi-trash3-fill"></i></div>
        </div>
        <div class="kpi-val" style="color:var(--amber)"><asp:Literal runat="server" ID="litExpired" /></div>
        <div class="kpi-lbl">Expired Donations</div>
        <div class="note-inline mt-1">Past expiry, never delivered</div>
      </div>
    </div>
  </div>

  <div class="row g-4 mb-4">

    <!-- Monthly donations -->
    <div class="col-lg-7">
      <div class="fb-card h-100">
        <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Donations by Month — <asp:Literal runat="server" ID="litChartYear" /></h6>
        </div>
        <div class="chart-bar-wrap">
          <asp:Repeater runat="server" ID="rptMonthly">
            <ItemTemplate>
              <div class="chart-bar-row">
                <span class="chart-bar-label"><%# Eval("Label") %></span>
                <div class="chart-bar-bg"><div class="chart-bar-fill" style='width:<%# Eval("Percent") %>%;background:var(--green)'></div></div>
                <span class="chart-bar-val"><%# Eval("Count") %></span>
              </div>
            </ItemTemplate>
          </asp:Repeater>
        </div>

        <div style="margin-top:1.5rem;padding-top:1.2rem;border-top:1px solid var(--sand)">
          <div style="font-size:.82rem;color:var(--text-muted);margin-bottom:.8rem;font-weight:600">Status breakdown for the selected period</div>
          <div class="d-flex gap-3 flex-wrap">
            <asp:Repeater runat="server" ID="rptStatusBreakdown">
              <ItemTemplate>
                <div style='background:<%# Eval("Tint") %>;border-radius:8px;padding:.5rem .9rem;font-size:.82rem'>
                  <strong style='color:<%# Eval("Colour") %>'><%# Eval("Count") %></strong> <%# Eval("Status") %>
                </div>
              </ItemTemplate>
            </asp:Repeater>
          </div>
        </div>
      </div>
    </div>

    <!-- Category donut -->
    <div class="col-lg-5">
      <div class="fb-card h-100">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.5rem">Donations by Category</h6>
        <div class="d-flex align-items-center gap-4 flex-wrap">
          <div class="donut-wrap">
            <svg width="140" height="140" viewBox="0 0 140 140">
              <circle cx="70" cy="70" r="55" fill="none" stroke="var(--sand)" stroke-width="20"/>
              <asp:Repeater runat="server" ID="rptDonut">
                <ItemTemplate>
                  <circle cx="70" cy="70" r="55" fill="none" stroke='<%# Eval("Colour") %>' stroke-width="20"
                          stroke-dasharray='<%# Eval("DashArray") %>' stroke-dashoffset='<%# Eval("DashOffset") %>'/>
                </ItemTemplate>
              </asp:Repeater>
            </svg>
            <div class="donut-center">
              <div style="font-family:'DM Serif Display',serif;font-size:1.4rem;color:var(--green)"><asp:Literal runat="server" ID="litDonutTotal" /></div>
              <div style="font-size:.65rem;color:var(--text-muted);text-align:center">Total</div>
            </div>
          </div>
          <div class="d-flex flex-column gap-2 flex-grow-1">
            <asp:Repeater runat="server" ID="rptCategoryLegend">
              <ItemTemplate>
                <div style="display:flex;justify-content:space-between;font-size:.85rem">
                  <span style="display:flex;align-items:center;gap:.5rem">
                    <span style='width:10px;height:10px;background:<%# Eval("Colour") %>;border-radius:2px;display:inline-block'></span>
                    <%# Server.HtmlEncode(Convert.ToString(Eval("Category"))) %>
                  </span>
                  <strong><%# Eval("Percent") %>%</strong>
                </div>
              </ItemTemplate>
            </asp:Repeater>
            <asp:Panel runat="server" ID="pnlNoCategory" Visible="false" CssClass="note-inline">
              No donations in this period.
            </asp:Panel>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-4 mb-4">

    <!-- Top donors -->
    <div class="col-lg-6">
      <div class="fb-card p-0 overflow-hidden">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);display:flex;justify-content:space-between;align-items:center">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Top Donors</h6>
          <span class="badge-status badge-role-donor">Ranking</span>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">Rank</th><th>Donor</th><th>Donations</th><th>Meals</th><th>Rating</th></tr></thead>
            <tbody>
              <asp:Repeater runat="server" ID="rptTopDonors">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3"><%# RankLabel(Container.ItemIndex) %></td>
                    <td><strong><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></strong><br /><small class="text-muted"><%# CityOrDash(Eval("City")) %></small></td>
                    <td><%# Eval("Donations") %></td>
                    <td><%# Eval("Meals") %></td>
                    <td><%# RatingText(Eval("Rating")) %></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
        </div>
        <asp:Panel runat="server" ID="pnlNoDonors" Visible="false" CssClass="empty-state" style="padding:2rem 1rem">
          <i class="bi bi-people"></i><p>No donations in this period.</p>
        </asp:Panel>
      </div>
    </div>

    <!-- Top NGOs -->
    <div class="col-lg-6">
      <div class="fb-card p-0 overflow-hidden">
        <div style="padding:1rem 1.2rem;border-bottom:1.5px solid var(--sand);display:flex;justify-content:space-between;align-items:center">
          <h6 style="font-family:'DM Serif Display',serif;margin:0">Top NGOs</h6>
          <span class="badge-status badge-role-ngo">Performance</span>
        </div>
        <div class="table-responsive">
          <table class="fb-table">
            <thead><tr><th class="ps-3">NGO</th><th>Accepted</th><th>Delivered</th><th>Rate</th><th>Rating</th></tr></thead>
            <tbody>
              <asp:Repeater runat="server" ID="rptTopNgos">
                <ItemTemplate>
                  <tr>
                    <td class="ps-3"><strong><%# Server.HtmlEncode(Convert.ToString(Eval("FullName"))) %></strong></td>
                    <td><%# Eval("Accepted") %></td>
                    <td><%# Eval("Delivered") %></td>
                    <td><%# RateCell(Eval("Accepted"), Eval("Delivered")) %></td>
                    <td><%# RatingText(Eval("Rating")) %></td>
                  </tr>
                </ItemTemplate>
              </asp:Repeater>
            </tbody>
          </table>
        </div>
        <asp:Panel runat="server" ID="pnlNoNgos" Visible="false" CssClass="empty-state" style="padding:2rem 1rem">
          <i class="bi bi-building"></i><p>No NGO has accepted a donation in this period.</p>
        </asp:Panel>
      </div>
    </div>
  </div>

  <div class="row g-4 mb-4">

    <!-- Expiry & waste -->
    <div class="col-lg-5">
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem"><i class="bi bi-clock-fill me-2 text-warning"></i>Expiry &amp; Waste Analysis</h6>
        <div class="d-flex flex-column gap-3">
          <div>
            <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Delivered before expiry</span><strong style="color:var(--green)"><asp:Literal runat="server" ID="litOnTimePct" /></strong></div>
            <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barOnTime"></div></div>
          </div>
          <div>
            <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Expired without delivery</span><strong style="color:var(--red)"><asp:Literal runat="server" ID="litExpiredPct" /></strong></div>
            <div class="fb-progress"><div class="fb-progress-bar" runat="server" id="barExpired" style="background:var(--red)"></div></div>
          </div>
          <div>
            <div class="d-flex justify-content-between mb-1"><span style="font-size:.85rem">Avg. assign → pickup time</span><strong><asp:Literal runat="server" ID="litAvgPickup" /></strong></div>
            <div class="note-inline">From volunteer assignment to confirmed pickup</div>
          </div>
        </div>
        <div style="background:var(--cream);border-radius:10px;padding:1rem;margin-top:1.2rem;display:flex;gap:1rem;align-items:center">
          <i class="bi bi-lightbulb-fill" style="font-size:1.5rem;color:var(--amber)"></i>
          <div style="font-size:.82rem;color:var(--text-muted)"><asp:Literal runat="server" ID="litWasteNote" /></div>
        </div>
      </div>
    </div>

    <!-- By city -->
    <div class="col-lg-7">
      <div class="fb-card">
        <h6 style="font-family:'DM Serif Display',serif;margin-bottom:1.2rem">Donations by City</h6>
        <div class="chart-bar-wrap">
          <asp:Repeater runat="server" ID="rptCities">
            <ItemTemplate>
              <div class="chart-bar-row">
                <span class="chart-bar-label"><%# Server.HtmlEncode(Convert.ToString(Eval("City"))) %></span>
                <div class="chart-bar-bg"><div class="chart-bar-fill" style='width:<%# Eval("Percent") %>%;background:<%# Eval("Colour") %>'></div></div>
                <span class="chart-bar-val"><%# Eval("Count") %></span>
              </div>
            </ItemTemplate>
          </asp:Repeater>
        </div>
        <asp:Panel runat="server" ID="pnlNoCities" Visible="false" CssClass="note-inline">
          No donations in this period.
        </asp:Panel>
      </div>
    </div>
  </div>

  <!-- ===================== Exports ===================== -->
  <div class="fb-card no-print">
    <h6 style="font-family:'DM Serif Display',serif;margin-bottom:.4rem">Export Reports</h6>
    <p class="note-inline mb-3">
      CSV files open directly in Excel and cover the selected period. The report itself prints through your browser —
      choose "Save as PDF" as the destination.
    </p>
    <div class="row g-3">
      <div class="col-sm-6 col-md-3">
        <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center">
          <i class="bi bi-file-earmark-pdf-fill" style="font-size:2rem;color:#dc2626;display:block;margin-bottom:.5rem"></i>
          <div style="font-weight:600;font-size:.88rem">Full Report</div>
          <div class="note-inline mb-2">Print / Save as PDF</div>
          <button type="button" class="btn-sm-outline" onclick="window.print()">Print</button>
        </div>
      </div>
      <div class="col-sm-6 col-md-3">
        <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center">
          <i class="bi bi-file-earmark-excel-fill" style="font-size:2rem;color:#16a34a;display:block;margin-bottom:.5rem"></i>
          <div style="font-weight:600;font-size:.88rem">Donor List</div>
          <div class="note-inline mb-2">CSV</div>
          <asp:LinkButton runat="server" ID="btnExportDonors" CssClass="btn-sm-outline" OnClick="btnExportDonors_Click">Download</asp:LinkButton>
        </div>
      </div>
      <div class="col-sm-6 col-md-3">
        <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center">
          <i class="bi bi-file-earmark-bar-graph-fill" style="font-size:2rem;color:var(--blue);display:block;margin-bottom:.5rem"></i>
          <div style="font-weight:600;font-size:.88rem">NGO Performance</div>
          <div class="note-inline mb-2">CSV</div>
          <asp:LinkButton runat="server" ID="btnExportNgos" CssClass="btn-sm-outline" OnClick="btnExportNgos_Click">Download</asp:LinkButton>
        </div>
      </div>
      <div class="col-sm-6 col-md-3">
        <div style="border:1.5px solid var(--sand);border-radius:var(--radius);padding:1.2rem;text-align:center">
          <i class="bi bi-file-earmark-text-fill" style="font-size:2rem;color:var(--amber);display:block;margin-bottom:.5rem"></i>
          <div style="font-weight:600;font-size:.88rem">All Donations</div>
          <div class="note-inline mb-2">CSV</div>
          <asp:LinkButton runat="server" ID="btnExportDonations" CssClass="btn-sm-outline" OnClick="btnExportDonations_Click">Download</asp:LinkButton>
        </div>
      </div>
    </div>
  </div>

</asp:Content>
