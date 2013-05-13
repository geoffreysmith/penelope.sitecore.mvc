penelope.sitecore.mvc
=====================

Framework for faster and easier Sitecore 6.6 MVC development

Overview
-------------------------

Penelope makes it easy to prototype Sitecore solutions or start a new Sitecore project. Clone the repositories, run 
> LOCAL.InstallSitecore.bat 

and you will have a new Sitecore 6.6 MVC installation configured at http://local.penelopesitecore.com/

Penelope makes use of the common build tool [psake/psake](https://github.com/psake/psake), and the new [adoprog/powercore] (https://github.com/adoprog/Sitecore-PowerCore)

How to Get started
-------------------------

**Step 1**  Download the Sitecore a ZIP archive of the site root from the [Sitecore SDN](http://sdn.sitecore.net/downloads/Sitecore660rev130404.download) (N.B., this is propietary and you must have certification to access this, it is why it is not in source).

**Step 1** Place your license file and the above zip file into the .\sitecore directory:

> .\sitecore\license.xml
>
> .\sitecore\Sitecore 6.6.0 rev. 130404.zip

**Step 3** Run the following options:

> .\LOCAL.InstallSitecore.bat

This will install install and attach databases for the above default 6.6 instance. It will also configure the config files for MVC3 support and an entry in your hosts file.

> .\LOCAL.InstallSitecoreAndDeploy.bat

This will install the default installation, attach databases, upgrade your project to MVC4, add an entry to your hosts file, run tests and deploy the Penelope.Web project

> .\LOCAL.UnisntallSitecore.bat

This will entirely uninstall your site, remove hosts entry, application and databases in a complete rollback.

Architecture
-------------------------

> .\src\Penelope.Conent\

The [Hedgehog TDS project](http://www.hhogdev.com/Products/Team-Development-for-Sitecore/Overview.aspx) which is currently empty.

> .\src\Penelope.Web\

The MVC4 solution, also currently empty except for config files.

> .\src\Penelope.Tests\

NUnit Testing Project, currently empty

> .\lib\

External references unavailable on NuGet, Sitecore propietary assemblies are currently kept here

> .\sitecore\

For the Sitecore webroot archive and license file

> .\deploy\

Contains Powercore

> .\build.ps1

Wrapper and setup for build and deploy

> .\default.ps1

PSake build and deploy project. See the properties section to configure this to your own environ,ent

Current Limitations
-------------------------

This is currently not setup to support multiple environments, though it would be trivial to add this functionality.

## License

psake is released under the [MIT license](http://www.opensource.org/licenses/MIT).
