using System;
using System.Web;

namespace LeftoverFood
{
    public partial class ErrorPage : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Exception lastError = Server.GetLastError();
            if (lastError != null)
            {
                Server.ClearError();

                // Only surface exception details on the local dev machine, never in production.
                if (Request.IsLocal)
                {
                    litDebugDetail.Text = "<div class=\"debug-detail\">" +
                        HttpUtility.HtmlEncode(lastError.ToString()) + "</div>";
                    litDebugDetail.Visible = true;
                }
            }
        }
    }
}
