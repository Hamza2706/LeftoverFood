using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.SessionState;
using System.Web.UI;

namespace LeftoverFood
{
    public class Global : System.Web.HttpApplication
    {

        protected void Application_Start(object sender, EventArgs e)
        {
            // Fix: Disable UnobtrusiveValidationMode so ASP.NET validators
            // work without requiring jQuery to be registered.
            ScriptManager.ScriptResourceMapping.AddDefinition("jquery",
                new ScriptResourceDefinition
                {
                    Path = "https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js",
                    DebugPath = "https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js",
                    CdnPath = "https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js",
                    CdnDebugPath = "https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"
                });
        }
        protected void Session_Start(object sender, EventArgs e)
        {

        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            ForceHttps();
        }

        /// <summary>
        /// Redirects http:// to https:// once the site is deployed.
        ///
        /// This is not cosmetic. Volunteer live tracking calls
        /// navigator.geolocation.watchPosition, and browsers only hand the
        /// Geolocation API to a "secure context". localhost is specially
        /// exempted — which is why tracking works in development over plain
        /// http — but a deployed http:// address is not exempt, and location
        /// sharing fails there with the map still rendering, so it looks like
        /// a bug in the app rather than a missing certificate.
        ///
        /// Done in code rather than as a &lt;rewrite&gt; rule in Web.config on
        /// purpose: if the IIS URL Rewrite module is not installed on the host,
        /// an unrecognised &lt;rewrite&gt; section takes the whole site down with
        /// a 500 on every page. This cannot fail that way.
        /// </summary>
        private static void ForceHttps()
        {
            HttpContext ctx = HttpContext.Current;
            if (ctx == null) return;

            // Escape hatch, default on. Needed if the site is ever reached over
            // http on purpose — e.g. testing from a phone against this machine's
            // LAN address, where IsLocal is false but there is no certificate
            // either. Note that geolocation is refused in that setup regardless,
            // since a bare IP over http is not a secure context.
            string enabled = ConfigurationManager.AppSettings["App.ForceHttps"];
            if (!string.IsNullOrWhiteSpace(enabled) &&
                enabled.Trim().Equals("false", StringComparison.OrdinalIgnoreCase)) return;

            HttpRequest req = ctx.Request;

            // Development stays on http — IIS Express binds
            // http://localhost:50555 and there is no certificate for it.
            if (req.IsLocal) return;

            // Already secure, so nothing to do. Behind a load balancer the hop
            // to IIS is plain http even when the browser is on https, so the
            // forwarded header has to be trusted where present — without this
            // check the redirect would loop forever.
            if (req.IsSecureConnection) return;

            string forwarded = req.Headers["X-Forwarded-Proto"];
            if (!string.IsNullOrEmpty(forwarded) &&
                forwarded.Equals("https", StringComparison.OrdinalIgnoreCase)) return;

            // GET only. A 301 on a POST makes the browser re-issue it as a GET
            // and the form data is lost — and Web Forms posts back on every
            // button click, so that would be a worse failure than the one being
            // fixed. A POST arriving over http means the page that produced it
            // was already redirected, so this stays rare.
            if (!req.HttpMethod.Equals("GET", StringComparison.OrdinalIgnoreCase)) return;

            ctx.Response.StatusCode = 301;
            ctx.Response.AddHeader("Location", "https://" + req.Url.Host + req.RawUrl);

            // CompleteRequest rather than Response.End — End raises a
            // ThreadAbortException to unwind, which litters the logs.
            ctx.ApplicationInstance.CompleteRequest();
        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e)
        {

        }

        protected void Application_Error(object sender, EventArgs e)
        {

        }

        protected void Session_End(object sender, EventArgs e)
        {

        }

        protected void Application_End(object sender, EventArgs e)
        {

        }
    }
}