using System;
using System.Web.UI;

namespace LeftoverFood.Donor
{
    /// <summary>
    /// Donor role master. Supplies the Donor sidebar and the nested content
    /// placeholders; everything else comes from Site.master.
    ///
    /// The sidebar markup, its IsActive() highlighting and the logout handler
    /// used to live here in four near-identical copies. They now live once in
    /// ~/Controls/RoleSidebar.ascx (Phase 4), which this master renders.
    /// </summary>
    public partial class DonorMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }
    }
}
