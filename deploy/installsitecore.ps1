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

#Unzip-Archive $sourcePath $tmpFolder

Write-Host "Moving Sitecore $tmpFolder\$sitecoreVersion to " $targetFolder

Move-Item "$tmpFolder\$sitecoreVersion\Data" $targetFolder
Move-Item "$tmpFolder\$sitecoreVersion\Databases" $targetFolder
Move-Item "$tmpFolder\$sitecoreVersion\Website" $targetFolder

$server = new-object ("microsoft.sqlserver.management.smo.server") $sqlservername
$databases = "core", "master", "web"
foreach ($db in $databases)
{
    attach-database $server "$sitename.$db" "$targetfolder\databases\sitecore.$db.mdf" "$targetfolder\databases\sitecore.$db.ldf"
    set-connectionstring "$websitefolder\app_config\connectionstrings.config" "$db" "trusted_connection=yes;data source=$sqlservername;database=$sitename.$db"
}

Set-ConfigAttribute "$websiteFolder\web.config" "sitecore/sc.variable[@name='dataFolder']" "value" $dataFolder

Copy-Item $licensePath $dataFolder
Create-AppPool $siteName "v4.0"
Create-Site "$siteName.local" "local.$siteName.com"  $websiteFolder $siteName

Add-Host "127.0.0.1" "local.$siteName.com"