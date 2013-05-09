Clear-Host

# Framework initialization
$scriptRoot = Split-Path (Resolve-Path $myInvocation.MyCommand.Path)

$env:PSModulePath = $env:PSModulePath + ";$scriptRoot\powercore\"

Import-Module WebUtils
Import-Module ConfigUtils
Import-Module DBUtils
Import-Module IISUtils
Import-Module FileUtils
Import-Module HostsUtils

Import-Module SitecoreInstallUtils

$siteName = "PenelopeSitecore"
$sitecoreVersion = "Sitecore 6.6.0 rev. 130404"  
$targetFolder = "C:\_SITES\PenelopeSitecore.local"
$sourceRoot = "C:\_APPLICATION\penelope.sitecore.mvc"

$licensePath = "$sourceRoot\sitecore\license.xml"
$tmpFolder = "$sourceRoot\tmp"    
$sourcePath = "$sourceRoot\sitecore\$sitecoreVersion.zip"
$dataFolder = "$targetFolder\Data"
$websiteFolder = "$targetFolder\Website"
$serverName = $env:COMPUTERNAME
$sqlServerName = "$serverName"   

Remove-AppPool $siteName
Remove-Site  "$siteName.local" "local.$siteName.com"  $websiteFolder $siteName

$server = new-object ("microsoft.sqlserver.management.smo.server") $sqlservername

$databases = "core", "master", "web"

foreach ($db in $databases)
{    
    remove-database $server "$sitename.$db"
}
    
Remove-Item -Recurse -Force $targetFolder