using System.Web.Mvc;
using Glass.Mapper.Sc;
using Penelope.Web.Models;

namespace Penelope.Web.Controllers
{
    public class HomePageController : Controller
    {
        public ActionResult Index()
        {
            var context = new SitecoreContext();
            var model = context.GetCurrentItem<HomePage>();
            return View(model);
        }

    }
}
