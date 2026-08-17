using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;
using LeftoverFoodSystem;

namespace LeftoverFood.Donor
{
    public partial class donate_form : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            SessionHelper.RequireRole(this, "Donor");

            if (!IsPostBack)
            {
                BindPreferredNGOs();
            }
        }

        private void BindPreferredNGOs()
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT UserID, FullName, OrganizationName, City FROM Users WHERE Role = 'NGO' AND IsVerified = 1 ORDER BY FullName");

            foreach (DataRow row in dt.Rows)
            {
                string label = row["OrganizationName"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["OrganizationName"].ToString())
                    ? row["OrganizationName"].ToString()
                    : row["FullName"].ToString();

                if (row["City"] != DBNull.Value && !string.IsNullOrWhiteSpace(row["City"].ToString()))
                    label += " – " + row["City"];

                ddlPreferredNGO.Items.Add(new ListItem(label, row["UserID"].ToString()));
            }
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            decimal quantity;
            int servings;
            DateTime preparedOn, expiryTime, availableFrom, availableUntil;

            if (!decimal.TryParse(txtQuantity.Text, out quantity) || quantity <= 0)
            {
                ShowMessage("Please enter a valid quantity.", "alert-danger");
                return;
            }
            if (!int.TryParse(txtServings.Text, out servings) || servings <= 0)
            {
                ShowMessage("Please enter a valid number of servings.", "alert-danger");
                return;
            }
            if (!DateTime.TryParse(txtPreparedOn.Text, out preparedOn))
            {
                ShowMessage("Please enter a valid preparation date.", "alert-danger");
                return;
            }
            if (!DateTime.TryParse(txtExpiryTime.Text, out expiryTime))
            {
                ShowMessage("Please enter a valid expiry date/time.", "alert-danger");
                return;
            }
            if (expiryTime <= DateTime.Now)
            {
                ShowMessage("Expiry time must be in the future.", "alert-danger");
                return;
            }
            if (!TimeSpan.TryParse(txtAvailableFrom.Text, out TimeSpan fromTime) ||
                !TimeSpan.TryParse(txtAvailableUntil.Text, out TimeSpan untilTime))
            {
                ShowMessage("Please enter a valid pickup time window.", "alert-danger");
                return;
            }
            availableFrom = DateTime.Today.Add(fromTime);
            availableUntil = DateTime.Today.Add(untilTime);

            string photoPath = SavePhotoIfProvided();

            string dietaryInfo = BuildDietaryInfo();

            int? preferredNgoId = null;
            if (!string.IsNullOrEmpty(ddlPreferredNGO.SelectedValue))
                preferredNgoId = Convert.ToInt32(ddlPreferredNGO.SelectedValue);

            string insertQuery = @"
                INSERT INTO FoodDonations
                    (DonorID, FoodDescription, Category, DonorTypeAtPost, Quantity, Servings, PreparedOn, ExpiryTime,
                     DietaryInfo, AdditionalNotes, PickupAddress, City, Latitude, Longitude, GeoPrecision, AvailableFrom, AvailableUntil,
                     ContactPerson, ContactPhone, PackagingCondition, PreferredNGOID, PhotoPath, Status, CreatedAt)
                VALUES
                    (@DonorID, @FoodDescription, @Category, @DonorType, @Quantity, @Servings, @PreparedOn, @ExpiryTime,
                     @DietaryInfo, @Notes, @PickupAddress, @City, @Latitude, @Longitude, @GeoPrecision, @AvailableFrom, @AvailableUntil,
                     @ContactPerson, @ContactPhone, @Packaging, @PreferredNGOID, @PhotoPath, 'Posted', GETDATE());
                SELECT CAST(SCOPE_IDENTITY() AS INT);";

            // Phase 5: resolve the pickup address to coordinates so the
            // donation can appear on the tracking and NGO maps.
            //
            // Address + city + country gives Nominatim far more to work with
            // than the street line alone — plenty of real Karachi addresses
            // still return no match, and that is fine: coordinates stay NULL,
            // the donation posts normally, and every map falls back to showing
            // the address as text.
            GeoPoint pickupPoint = GeocodingService.GeocodeDonation(
                txtPickupAddress.Text.Trim(), ddlCity.SelectedValue);

            SqlParameter[] parameters = {
                new SqlParameter("@DonorID", SessionHelper.GetUserID()),
                new SqlParameter("@FoodDescription", txtFoodDescription.Text.Trim()),
                new SqlParameter("@Category", ddlCategory.SelectedValue),
                new SqlParameter("@DonorType", ddlDonorType.SelectedValue),
                new SqlParameter("@Quantity", txtQuantity.Text.Trim() + " " + ddlUnit.SelectedValue),
                new SqlParameter("@Servings", servings),
                new SqlParameter("@PreparedOn", preparedOn),
                new SqlParameter("@ExpiryTime", expiryTime),
                new SqlParameter("@DietaryInfo", (object)dietaryInfo ?? DBNull.Value),
                new SqlParameter("@Notes", string.IsNullOrWhiteSpace(txtNotes.Text) ? (object)DBNull.Value : txtNotes.Text.Trim()),
                new SqlParameter("@PickupAddress", txtPickupAddress.Text.Trim()),
                new SqlParameter("@City", ddlCity.SelectedValue),
                new SqlParameter("@Latitude", pickupPoint == null ? (object)DBNull.Value : pickupPoint.Latitude),
                new SqlParameter("@Longitude", pickupPoint == null ? (object)DBNull.Value : pickupPoint.Longitude),
                new SqlParameter("@GeoPrecision", pickupPoint == null ? (object)DBNull.Value : pickupPoint.Precision),
                new SqlParameter("@AvailableFrom", availableFrom),
                new SqlParameter("@AvailableUntil", availableUntil),
                new SqlParameter("@ContactPerson", txtContactPerson.Text.Trim()),
                new SqlParameter("@ContactPhone", txtContactPhone.Text.Trim()),
                new SqlParameter("@Packaging", ddlPackaging.SelectedValue),
                new SqlParameter("@PreferredNGOID", (object)preferredNgoId ?? DBNull.Value),
                new SqlParameter("@PhotoPath", (object)photoPath ?? DBNull.Value)
            };

            try
            {
                // SCOPE_IDENTITY() gives us the new DonationID so the
                // notifications below can deep-link to this specific donation.
                object newId = DBHelper.ExecuteScalar(insertQuery, parameters);
                int donationId = newId == null || newId == DBNull.Value ? 0 : Convert.ToInt32(newId);

                string food = txtFoodDescription.Text.Trim();

                // Phase 6b: rule checks run inline here because this app has no
                // background job host. Fail-soft by contract — a detection
                // fault cannot stop a donation that has already been inserted,
                // and nothing it finds blocks the donor. Anything raised goes
                // to the admin review queue only.
                if (donationId > 0)
                    FraudDetectionService.CheckNewDonation(donationId, SessionHelper.GetUserID());

                // Confirmation to the donor...
                NotificationService.Notify(SessionHelper.GetUserID(),
                    "Your donation has been posted",
                    "Your donation \"" + food + "\" is now posted and waiting for admin approval. "
                    + "You'll be notified as soon as it is reviewed.",
                    NotifyType.System, NotifyEvent.DonationPosted,
                    donationId > 0 ? "~/Donor/track-donation.aspx?id=" + donationId : null);

                // ...and a heads-up to every admin that the approval queue moved.
                NotificationService.NotifyRole("Admin",
                    "New donation awaiting approval",
                    SessionHelper.GetFullName() + " posted \"" + food + "\" in " + ddlCity.SelectedValue
                    + ". It is waiting in the approval queue.",
                    NotifyType.Approval, NotifyEvent.DonationPosted,
                    "~/Admin/food-approvals.aspx");

                Response.Redirect("~/Donor/donor-dashboard.aspx?posted=1");
            }
            catch (Exception ex)
            {
                ShowMessage("An error occurred while posting your donation: " + ex.Message, "alert-danger");
            }
        }

        private string SavePhotoIfProvided()
        {
            if (!fuPhoto.HasFile) return null;

            string ext = Path.GetExtension(fuPhoto.FileName).ToLower();
            if (ext != ".jpg" && ext != ".jpeg" && ext != ".png")
            {
                ShowMessage("Photo must be a JPG or PNG file. Donation was posted without it.", "alert-warning");
                return null;
            }
            if (fuPhoto.PostedFile.ContentLength > 5 * 1024 * 1024)
            {
                ShowMessage("Photo must be under 5MB. Donation was posted without it.", "alert-warning");
                return null;
            }

            string fileName = Guid.NewGuid().ToString("N") + ext;
            string relativePath = "~/uploads/images/" + fileName;
            string fullPath = Server.MapPath(relativePath);

            // SaveAs does not create missing directories — it throws. A publish
            // that skips uploads/images (it only exists in source control
            // because two sample photos happen to live in it) would otherwise
            // take down every donation submitted with a photo, on a host where
            // the folder is not there to look at.
            string dir = Path.GetDirectoryName(fullPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            fuPhoto.SaveAs(fullPath);
            return "/uploads/images/" + fileName;
        }

        private string BuildDietaryInfo()
        {
            var tags = new StringBuilder();
            if (chkHalal.Checked) tags.Append("Halal,");
            if (chkVegetarian.Checked) tags.Append("Vegetarian,");
            if (chkVegan.Checked) tags.Append("Vegan,");
            if (chkGlutenFree.Checked) tags.Append("Gluten-Free,");
            if (chkNuts.Checked) tags.Append("Contains Nuts,");

            return tags.Length > 0 ? tags.ToString().TrimEnd(',') : null;
        }

        private void ShowMessage(string message, string cssClass)
        {
            lblMessage.Text = message;
            lblMessage.CssClass = "alert " + cssClass;
            lblMessage.Visible = true;
        }
    }
}
