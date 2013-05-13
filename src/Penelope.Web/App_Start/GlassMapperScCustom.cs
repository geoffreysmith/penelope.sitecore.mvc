using System.Linq;
using Castle.Windsor;
using Glass.Mapper.Configuration;
using Glass.Mapper.Sc.CastleWindsor;
using Glass.Mapper.Sc.CodeFirst;
using Glass.Mapper.Sc.Configuration.Attributes;
using Sitecore.SecurityModel;

namespace Penelope.Web.App_Start
{
    public static  class GlassMapperScCustom
    {
        public static void CastleConfig(IWindsorContainer container)
        {
            var config = new Config();

            container.Install(new SitecoreInstaller(config));
        }

        public static IConfigurationLoader[] GlassLoaders()
        {
            var attributes = new SitecoreAttributeConfigurationLoader("Penelope.Web");

            return new IConfigurationLoader[] {attributes};
        }

        public static void PostLoad()
        {
            var dbs = Sitecore.Configuration.Factory.GetDatabases();
            foreach (var db in dbs)
            {
                var provider = db.GetDataProviders().FirstOrDefault(x => x is GlassDataProvider) as GlassDataProvider;
                if (provider != null)
                {
                    using (new SecurityDisabler())
                    {
                        provider.Initialise(db);
                    }
                }
            }
        }
    }
}
