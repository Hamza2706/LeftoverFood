using System;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Admin
{
    /// <summary>
    /// Reports &amp; Analytics (Phase 6d).
    ///
    /// Aggregate queries inline over DBHelper — this page is the only consumer,
    /// which is the same reasoning Phases 1 and 6c used. No ReportService.
    ///
    /// Everything is scoped to a period chosen in the UI. The mockup was fixed
    /// to "April 2025" and every figure in it was a literal.
    /// </summary>
    public partial class reports : System.Web.UI.Page
    {
        /// <summary>Slice colours, cycled in order. Matches the palette the rest of the app uses.</summary>
        private static readonly string[] SliceColours =
        {
            "var(--green)", "var(--amber)", "var(--blue)", "var(--purple)",
            "var(--green-mid)", "var(--red)"
        };

        /// <summary>Circumference of the donut's r=55 circle, for stroke-dasharray maths.</summary>
        private const double DonutCircumference = 2 * Math.PI * 55;

        private DateTime _from;
        private DateTime _to;
        private DateTime _prevFrom;
        private DateTime _prevTo;

        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Admin");

            ResolvePeriod();

            if (!IsPostBack)
                BindAll();
        }

        // ------------------------------------------------------------------
        // Period
        // ------------------------------------------------------------------

        /// <summary>
        /// Resolves the selected period and the equivalent preceding one.
        ///
        /// The preceding period is what makes the KPI change arrows real. The
        /// mockup showed "↑8%" against nothing at all — there was no comparison
        /// period anywhere in it.
        /// </summary>
        private void ResolvePeriod()
        {
            DateTime now = DateTime.Now;
            _to = now;

            switch (ddlPeriod.SelectedValue)
            {
                case "30":
                    _from = now.AddDays(-30);
                    break;
                case "year":
                    _from = new DateTime(now.Year, 1, 1);
                    break;
                case "all":
                    // Not DateTime.MinValue: SQL Server's DATETIME starts at
                    // 1753 and would overflow on the parameter.
                    _from = new DateTime(2000, 1, 1);
                    break;
                default:
                    _from = new DateTime(now.Year, now.Month, 1);
                    break;
            }

            TimeSpan length = _to - _from;
            _prevTo = _from;
            _prevFrom = _from - length;
        }

        private string PeriodLabel()
        {
            switch (ddlPeriod.SelectedValue)
            {
                case "30": return "Last 30 Days";
                case "year": return DateTime.Now.Year.ToString();
                case "all": return "All Time";
                default: return DateTime.Now.ToString("MMMM yyyy");
            }
        }

        private SqlParameter[] PeriodParams()
        {
            return new SqlParameter[]
            {
                new SqlParameter("@From", _from),
                new SqlParameter("@To", _to)
            };
        }

        protected void ddlPeriod_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindAll();
        }

        // ------------------------------------------------------------------
        // Binding
        // ------------------------------------------------------------------

        private void BindAll()
        {
            litPeriodLabel.Text = Server.HtmlEncode(PeriodLabel());
            litChartYear.Text = DateTime.Now.Year.ToString();

            BindKpis();
            BindMonthly();
            BindStatusBreakdown();
            BindCategories();
            BindTopDonors();
            BindTopNgos();
            BindExpiry();
            BindCities();
        }

        private void BindKpis()
        {
            int donations = Scalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            int prevDonations = Scalar(
                "SELECT COUNT(*) FROM FoodDonations WHERE CreatedAt >= @From AND CreatedAt < @To",
                new SqlParameter[] { new SqlParameter("@From", _prevFrom), new SqlParameter("@To", _prevTo) });

            // Meals uses Servings, the only numeric quantity in the schema —
            // Quantity is free text ("1 Kg", "10 Plates") and cannot be summed.
            int meals = Scalar(
                @"SELECT ISNULL(SUM(Servings), 0) FROM FoodDonations
                   WHERE Status = 'Delivered' AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            int prevMeals = Scalar(
                @"SELECT ISNULL(SUM(Servings), 0) FROM FoodDonations
                   WHERE Status = 'Delivered' AND CreatedAt >= @From AND CreatedAt < @To",
                new SqlParameter[] { new SqlParameter("@From", _prevFrom), new SqlParameter("@To", _prevTo) });

            // Fulfilment is measured against donations that actually entered
            // the pipeline. Counting rejected and cancelled ones in the
            // denominator would blame the delivery chain for admin decisions
            // and donor changes of mind.
            int approved = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE Status NOT IN ('Posted', 'Rejected', 'Cancelled')
                     AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            int delivered = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE Status = 'Delivered' AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            // 'Expired' is a status nothing in this app ever writes — there is
            // no scheduler to sweep for it. So it is derived: past its expiry
            // time and never delivered.
            int expired = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE ExpiryTime < GETDATE()
                     AND Status NOT IN ('Delivered', 'Rejected', 'Cancelled')
                     AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            litTotalDonations.Text = donations.ToString("N0");
            litMealsDistributed.Text = meals.ToString("N0");
            litFulfilment.Text = approved == 0 ? "—" : Percent(delivered, approved) + "%";
            litExpired.Text = expired.ToString("N0");

            litDonationsChange.Text = ChangeBadge(donations, prevDonations);
            litMealsChange.Text = ChangeBadge(meals, prevMeals);

            pnlEmpty.Visible = donations == 0;
            litEmpty.Text = "No donations were posted in this period, so the figures below are empty. "
                          + "Try a wider period — this database currently holds a handful of test donations.";
        }

        /// <summary>
        /// Up/down arrow against the preceding period of equal length. Returns
        /// nothing at all when there is no prior data to compare against —
        /// "↑100%" from a base of zero is noise, not information.
        /// </summary>
        private string ChangeBadge(int current, int previous)
        {
            if (previous <= 0) return "<span class=\"note-inline\">no prior period</span>";

            int pct = (int)Math.Round((current - previous) * 100.0 / previous);
            if (pct == 0) return "<span class=\"note-inline\">no change</span>";

            bool up = pct > 0;
            return "<span class=\"kpi-change " + (up ? "up" : "down") + "\"><i class=\"bi bi-arrow-"
                 + (up ? "up" : "down") + "\"></i>" + Math.Abs(pct) + "%</span>";
        }

        private void BindMonthly()
        {
            DataTable raw = DBHelper.ExecuteQuery(
                @"SELECT MONTH(CreatedAt) AS M, COUNT(*) AS C
                    FROM FoodDonations
                   WHERE YEAR(CreatedAt) = @Year
                   GROUP BY MONTH(CreatedAt)",
                new SqlParameter[] { new SqlParameter("@Year", DateTime.Now.Year) });

            int[] counts = new int[13];
            foreach (DataRow r in raw.Rows)
                counts[Convert.ToInt32(r["M"])] = Convert.ToInt32(r["C"]);

            int max = 0;
            for (int m = 1; m <= 12; m++) if (counts[m] > max) max = counts[m];

            DataTable dt = NewTable("Label", typeof(string), "Count", typeof(int), "Percent", typeof(int));

            // Months up to today only — showing empty bars for months that have
            // not happened yet reads as a data problem rather than as the
            // calendar.
            for (int m = 1; m <= DateTime.Now.Month; m++)
            {
                int pct = max == 0 ? 0 : (int)Math.Round(counts[m] * 100.0 / max);
                dt.Rows.Add(CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(m), counts[m], pct);
            }

            rptMonthly.DataSource = dt;
            rptMonthly.DataBind();
        }

        private void BindStatusBreakdown()
        {
            DataTable raw = DBHelper.ExecuteQuery(
                @"SELECT Status, COUNT(*) AS C FROM FoodDonations
                   WHERE CreatedAt >= @From AND CreatedAt < @To
                   GROUP BY Status ORDER BY COUNT(*) DESC",
                PeriodParams());

            DataTable dt = NewTable("Status", typeof(string), "Count", typeof(int),
                                    "Colour", typeof(string), "Tint", typeof(string));

            foreach (DataRow r in raw.Rows)
            {
                string status = Convert.ToString(r["Status"]);
                dt.Rows.Add(status, Convert.ToInt32(r["C"]), StatusColour(status), StatusTint(status));
            }

            rptStatusBreakdown.DataSource = dt;
            rptStatusBreakdown.DataBind();
        }

        /// <summary>
        /// Category split, rendered as a real SVG donut.
        ///
        /// Each slice is an arc drawn with stroke-dasharray "<len> <rest>" and a
        /// negative stroke-dashoffset equal to everything already drawn. The
        /// mockup hardcoded four such arcs; these are computed from the counts.
        /// </summary>
        private void BindCategories()
        {
            DataTable raw = DBHelper.ExecuteQuery(
                @"SELECT ISNULL(Category, 'Uncategorised') AS Category, COUNT(*) AS C
                    FROM FoodDonations
                   WHERE CreatedAt >= @From AND CreatedAt < @To
                   GROUP BY Category ORDER BY COUNT(*) DESC",
                PeriodParams());

            int total = 0;
            foreach (DataRow r in raw.Rows) total += Convert.ToInt32(r["C"]);

            litDonutTotal.Text = total.ToString("N0");

            DataTable arcs = NewTable("Colour", typeof(string), "DashArray", typeof(string), "DashOffset", typeof(string));
            DataTable legend = NewTable("Category", typeof(string), "Percent", typeof(int), "Colour", typeof(string));

            double drawn = 0;
            int i = 0;

            foreach (DataRow r in raw.Rows)
            {
                int count = Convert.ToInt32(r["C"]);
                string colour = SliceColours[i % SliceColours.Length];

                double length = total == 0 ? 0 : DonutCircumference * count / total;

                arcs.Rows.Add(
                    colour,
                    Round(length) + " " + Round(DonutCircumference),
                    Round(-drawn));

                legend.Rows.Add(Convert.ToString(r["Category"]), Percent(count, total), colour);

                drawn += length;
                i++;
            }

            rptDonut.DataSource = arcs;
            rptDonut.DataBind();
            rptCategoryLegend.DataSource = legend;
            rptCategoryLegend.DataBind();
            pnlNoCategory.Visible = total == 0;
        }

        private void BindTopDonors()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 5 u.UserID, u.FullName, u.City,
                         COUNT(d.DonationID) AS Donations,
                         ISNULL(SUM(CASE WHEN d.Status = 'Delivered' THEN d.Servings ELSE 0 END), 0) AS Meals,
                         u.TrustScore AS Rating
                    FROM Users u
                    JOIN FoodDonations d ON d.DonorID = u.UserID
                   WHERE d.CreatedAt >= @From AND d.CreatedAt < @To
                   GROUP BY u.UserID, u.FullName, u.City, u.TrustScore
                   ORDER BY COUNT(d.DonationID) DESC, Meals DESC",
                PeriodParams());

            rptTopDonors.DataSource = dt;
            rptTopDonors.DataBind();
            pnlNoDonors.Visible = dt.Rows.Count == 0;
        }

        private void BindTopNgos()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT TOP 5 u.UserID, u.FullName,
                         COUNT(r.RequestID) AS Accepted,
                         SUM(CASE WHEN d.Status = 'Delivered' THEN 1 ELSE 0 END) AS Delivered,
                         u.TrustScore AS Rating
                    FROM Users u
                    JOIN FoodRequests r ON r.NGOID = u.UserID AND r.Status = 'Accepted'
                    JOIN FoodDonations d ON d.DonationID = r.DonationID
                   WHERE r.RequestedAt >= @From AND r.RequestedAt < @To
                   GROUP BY u.UserID, u.FullName, u.TrustScore
                   ORDER BY COUNT(r.RequestID) DESC",
                PeriodParams());

            rptTopNgos.DataSource = dt;
            rptTopNgos.DataBind();
            pnlNoNgos.Visible = dt.Rows.Count == 0;
        }

        private void BindExpiry()
        {
            int delivered = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE Status = 'Delivered' AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            // "Before expiry" compares the volunteer's delivery timestamp
            // against the donation's own expiry time — both real columns, so
            // this is measured rather than assumed.
            int onTime = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations d
                    JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                   WHERE d.Status = 'Delivered' AND a.DeliveredAt IS NOT NULL
                     AND a.DeliveredAt <= d.ExpiryTime
                     AND d.CreatedAt >= @From AND d.CreatedAt < @To",
                PeriodParams());

            int expired = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE ExpiryTime < GETDATE()
                     AND Status NOT IN ('Delivered', 'Rejected', 'Cancelled')
                     AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            int considered = Scalar(
                @"SELECT COUNT(*) FROM FoodDonations
                   WHERE Status NOT IN ('Rejected', 'Cancelled')
                     AND CreatedAt >= @From AND CreatedAt < @To",
                PeriodParams());

            int onTimePct = Percent(onTime, delivered);
            int expiredPct = Percent(expired, considered);

            litOnTimePct.Text = delivered == 0 ? "—" : onTimePct + "%";
            litExpiredPct.Text = considered == 0 ? "—" : expiredPct + "%";

            barOnTime.Style["width"] = onTimePct + "%";
            barExpired.Style["width"] = expiredPct + "%";

            object avg = DBHelper.ExecuteScalar(
                @"SELECT AVG(CAST(DATEDIFF(MINUTE, a.AssignedAt, a.PickedUpAt) AS FLOAT))
                    FROM DeliveryAssignments a
                    JOIN FoodDonations d ON d.DonationID = a.DonationID
                   WHERE a.PickedUpAt IS NOT NULL
                     AND d.CreatedAt >= @From AND d.CreatedAt < @To",
                PeriodParams());

            litAvgPickup.Text = (avg == null || avg == DBNull.Value)
                ? "no pickups yet"
                : FormatMinutes(Convert.ToDouble(avg));

            // The mockup asserted "sending donor reminders earlier could reduce
            // expiry by ~40%" — a prediction with no model behind it. This says
            // only what the numbers say.
            litWasteNote.Text = expired == 0
                ? "No donations expired undelivered in this period."
                : Server.HtmlEncode(expired + (expired == 1 ? " donation" : " donations")
                    + " passed their expiry time without being delivered.");
        }

        private void BindCities()
        {
            DataTable raw = DBHelper.ExecuteQuery(
                @"SELECT ISNULL(City, 'Unknown') AS City, COUNT(*) AS C
                    FROM FoodDonations
                   WHERE CreatedAt >= @From AND CreatedAt < @To
                   GROUP BY City ORDER BY COUNT(*) DESC",
                PeriodParams());

            int max = 0;
            foreach (DataRow r in raw.Rows)
            {
                int c = Convert.ToInt32(r["C"]);
                if (c > max) max = c;
            }

            DataTable dt = NewTable("City", typeof(string), "Count", typeof(int),
                                    "Percent", typeof(int), "Colour", typeof(string));

            int i = 0;
            foreach (DataRow r in raw.Rows)
            {
                int c = Convert.ToInt32(r["C"]);
                dt.Rows.Add(Convert.ToString(r["City"]), c,
                            max == 0 ? 0 : (int)Math.Round(c * 100.0 / max),
                            SliceColours[i % SliceColours.Length]);
                i++;
            }

            rptCities.DataSource = dt;
            rptCities.DataBind();
            pnlNoCities.Visible = dt.Rows.Count == 0;
        }

        // ------------------------------------------------------------------
        // CSV export
        // ------------------------------------------------------------------

        protected void btnExportDonors_Click(object sender, EventArgs e)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT u.FullName AS [Donor], u.Email, u.Phone, ISNULL(u.City, '') AS City,
                         ISNULL(u.BusinessType, '') AS [Business Type],
                         COUNT(d.DonationID) AS [Donations],
                         ISNULL(SUM(CASE WHEN d.Status = 'Delivered' THEN d.Servings ELSE 0 END), 0) AS [Meals Delivered],
                         ISNULL(CAST(u.TrustScore AS NVARCHAR(10)), 'unrated') AS [Rating]
                    FROM Users u
                    JOIN FoodDonations d ON d.DonorID = u.UserID
                   WHERE d.CreatedAt >= @From AND d.CreatedAt < @To
                   GROUP BY u.FullName, u.Email, u.Phone, u.City, u.BusinessType, u.TrustScore
                   ORDER BY COUNT(d.DonationID) DESC",
                PeriodParams());

            SendCsv(dt, "donor-list");
        }

        protected void btnExportNgos_Click(object sender, EventArgs e)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT u.FullName AS [NGO], ISNULL(u.OrganizationName, '') AS [Organisation],
                         u.Email, ISNULL(u.City, '') AS City,
                         COUNT(r.RequestID) AS [Accepted],
                         SUM(CASE WHEN d.Status = 'Delivered' THEN 1 ELSE 0 END) AS [Delivered],
                         ISNULL(CAST(u.TrustScore AS NVARCHAR(10)), 'unrated') AS [Rating]
                    FROM Users u
                    JOIN FoodRequests r ON r.NGOID = u.UserID AND r.Status = 'Accepted'
                    JOIN FoodDonations d ON d.DonationID = r.DonationID
                   WHERE r.RequestedAt >= @From AND r.RequestedAt < @To
                   GROUP BY u.FullName, u.OrganizationName, u.Email, u.City, u.TrustScore
                   ORDER BY COUNT(r.RequestID) DESC",
                PeriodParams());

            SendCsv(dt, "ngo-performance");
        }

        protected void btnExportDonations_Click(object sender, EventArgs e)
        {
            DataTable dt = DBHelper.ExecuteQuery(
                @"SELECT d.DonationID AS [ID], d.FoodDescription AS [Food], d.Category,
                         d.Quantity, d.Servings, d.City, d.PickupAddress AS [Pickup Address],
                         ISNULL(d.GeoPrecision, 'not located') AS [Map Precision],
                         d.Status, d.CreatedAt AS [Posted], d.ExpiryTime AS [Expires],
                         donor.FullName AS [Donor],
                         ISNULL(ngo.FullName, '') AS [NGO],
                         ISNULL(vol.FullName, '') AS [Volunteer],
                         ISNULL(r.ActualQuantityReceived, '') AS [Received]
                    FROM FoodDonations d
                    JOIN Users donor ON donor.UserID = d.DonorID
                    LEFT JOIN FoodRequests r ON r.DonationID = d.DonationID AND r.Status = 'Accepted'
                    LEFT JOIN Users ngo ON ngo.UserID = r.NGOID
                    LEFT JOIN DeliveryAssignments a ON a.DonationID = d.DonationID
                    LEFT JOIN Users vol ON vol.UserID = a.VolunteerID
                   WHERE d.CreatedAt >= @From AND d.CreatedAt < @To
                   ORDER BY d.DonationID DESC",
                PeriodParams());

            SendCsv(dt, "donations");
        }

        /// <summary>
        /// Streams a DataTable as a CSV download.
        ///
        /// The BOM matters: without it Excel decodes the file as the system
        /// codepage and mangles Urdu or accented food descriptions. Phase 4 hit
        /// the same class of bug from the other direction, when the
        /// Notifications table turned out to be varchar rather than nvarchar.
        ///
        /// CompleteRequest() rather than Response.End(): End() raises a
        /// ThreadAbortException by design, which would be caught and logged as
        /// a failure by anything wrapping this call.
        /// </summary>
        private void SendCsv(DataTable dt, string namePrefix)
        {
            string fileName = namePrefix + "-" + DateTime.Now.ToString("yyyyMMdd-HHmm") + ".csv";

            StringBuilder sb = new StringBuilder();

            // U+FEFF written as a code point, not as a literal character: an
            // invisible byte in source is one stray "normalise whitespace"
            // edit away from vanishing, and its absence would only show up as
            // mojibake once someone opened the export in Excel.
            sb.Append((char)0xFEFF);

            for (int c = 0; c < dt.Columns.Count; c++)
            {
                if (c > 0) sb.Append(',');
                sb.Append(CsvCell(dt.Columns[c].ColumnName));
            }
            sb.Append("\r\n");

            foreach (DataRow row in dt.Rows)
            {
                for (int c = 0; c < dt.Columns.Count; c++)
                {
                    if (c > 0) sb.Append(',');
                    sb.Append(CsvCell(FormatCell(row[c])));
                }
                sb.Append("\r\n");
            }

            HttpResponse response = Response;
            response.Clear();
            response.ContentType = "text/csv";
            response.ContentEncoding = Encoding.UTF8;
            response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            response.Write(sb.ToString());
            response.Flush();
            response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }

        private static string FormatCell(object value)
        {
            if (value == null || value == DBNull.Value) return "";

            // Invariant, unambiguous dates. A locale-formatted date in a CSV is
            // how 03/04 becomes March in one machine's Excel and April in
            // another's.
            if (value is DateTime)
                return ((DateTime)value).ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);

            return Convert.ToString(value, CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// RFC 4180 quoting: wrap in quotes when the value contains a comma,
        /// quote, CR or LF, and double any embedded quotes.
        ///
        /// A leading =, +, - or @ is also prefixed with a quote character,
        /// because Excel treats such a cell as a formula. A donor-supplied food
        /// description beginning with "=" would otherwise be executed on open —
        /// CSV injection.
        /// </summary>
        private static string CsvCell(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";

            string text = value;

            if (text.Length > 0 && "=+-@".IndexOf(text[0]) >= 0)
                text = "'" + text;

            bool mustQuote = text.IndexOfAny(new[] { ',', '"', '\r', '\n' }) >= 0;

            if (mustQuote)
                text = "\"" + text.Replace("\"", "\"\"") + "\"";

            return text;
        }

        // ------------------------------------------------------------------
        // Helpers
        // ------------------------------------------------------------------

        private static int Scalar(string sql, SqlParameter[] parameters)
        {
            object o = DBHelper.ExecuteScalar(sql, parameters);
            return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
        }

        private static int Percent(int part, int whole)
        {
            return whole <= 0 ? 0 : (int)Math.Round(part * 100.0 / whole);
        }

        private static string Round(double value)
        {
            return value.ToString("0.##", CultureInfo.InvariantCulture);
        }

        private static DataTable NewTable(params object[] nameThenType)
        {
            DataTable dt = new DataTable();
            for (int i = 0; i + 1 < nameThenType.Length; i += 2)
                dt.Columns.Add((string)nameThenType[i], (Type)nameThenType[i + 1]);
            return dt;
        }

        private static string FormatMinutes(double minutes)
        {
            if (minutes < 1) return "under a minute";
            if (minutes < 60) return (int)minutes + "m";
            return (int)(minutes / 60) + "h " + (int)(minutes % 60) + "m";
        }

        private static string StatusColour(string status)
        {
            switch (status)
            {
                case "Delivered": return "var(--green)";
                case "Rejected":
                case "Cancelled": return "var(--red)";
                case "Posted": return "var(--amber)";
                default: return "var(--blue)";
            }
        }

        private static string StatusTint(string status)
        {
            switch (status)
            {
                case "Delivered": return "#e8f5ee";
                case "Rejected":
                case "Cancelled": return "#fee2e2";
                case "Posted": return "#fff3e0";
                default: return "#e0f2fe";
            }
        }

        // --- Markup helpers ---

        protected string RankLabel(int index)
        {
            switch (index)
            {
                case 0: return "🥇 1";
                case 1: return "🥈 2";
                case 2: return "🥉 3";
                default: return (index + 1).ToString();
            }
        }

        protected string CityOrDash(object city)
        {
            string s = Convert.ToString(city);
            return string.IsNullOrWhiteSpace(s) ? "no city on record" : Server.HtmlEncode(s);
        }

        /// <summary>
        /// TrustScore, or an honest blank. Phase 6c leaves this NULL until
        /// someone is actually rated, and printing "⭐ 0.0" for an unrated
        /// donor would read as a terrible score rather than as no score.
        /// </summary>
        protected string RatingText(object rating)
        {
            if (rating == null || rating == DBNull.Value)
                return "<span class=\"note-inline\">unrated</span>";

            return "⭐ " + Convert.ToDecimal(rating).ToString("0.0", CultureInfo.InvariantCulture);
        }

        protected string RateCell(object accepted, object delivered)
        {
            int a = Convert.ToInt32(accepted);
            int d = delivered == DBNull.Value ? 0 : Convert.ToInt32(delivered);

            if (a == 0) return "<span class=\"note-inline\">—</span>";

            int pct = Percent(d, a);
            string colour = pct >= 95 ? "var(--green)" : pct >= 85 ? "var(--amber)" : "var(--red)";

            return "<span style=\"color:" + colour + ";font-weight:700\">" + pct + "%</span>";
        }
    }
}
