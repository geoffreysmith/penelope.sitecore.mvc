using Glass.Mapper.Sc.CastleWindsor;

[assembly: WebActivatorEx.PostApplicationStartMethod(typeof(Penelope.Web.App_Start.GlassMapperSc), "Start")]

namespace Penelope.Web.App_Start
{
	public static class  GlassMapperSc
	{
		public static void Start()
		{
			//create the resolver
			var resolver = DependencyResolver.CreateStandardResolver();

			//install the custom services
			GlassMapperScCustom.CastleConfig(resolver.Container);

			//create a context
			var context = Glass.Mapper.Context.Create(resolver);
			context.Load(      
				GlassMapperScCustom.GlassLoaders()        				
				);

			GlassMapperScCustom.PostLoad();
		}
	}
}