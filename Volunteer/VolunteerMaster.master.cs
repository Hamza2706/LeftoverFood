using System;
using System.Web.UI;

namespace LeftoverFood.Volunteer
{
    /// <summary>
    /// Volunteer role master. Supplies the Volunteer sidebar and the nested content
    /// placeholders; everything else comes from Site.master.
    ///
    /// The sidebar markup, its IsActive() highlighting and the logout handler
    /// used to live here in four near-identical copies. They now live once in
    /// ~/Controls/RoleSidebar.ascx (Phase 4), which this master renders.
    /// </summary>
    public partial class VolunteerMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }
    }
}
