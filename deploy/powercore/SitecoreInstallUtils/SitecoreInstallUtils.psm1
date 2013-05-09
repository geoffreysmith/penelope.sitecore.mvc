Clear-Host

# Framework initialization
$scriptRoot = Split-Path (Resolve-Path $myInvocation.MyCommand.Path)

$env:PSModulePath = $env:PSModulePath + ";$scriptRoot\..\"

Import-Module WebUtils
Import-Module ConfigUtils
Import-Module DBUtils
Import-Module IISUtils
Import-Module FileUtils
Import-Module HostsUtils
   
Function Install-Sitecore([string]$siteName, [string]$sitecoreVersion,  [string]$targetFolder, [string]$sourceRoot)
{ 
    Write-Host $siteName
    $licensePath = "$sourceRoot\sitecore\license.xml"
    $tmpFolder = "$sourceRoot\tmp\"    
    $sourcePath = "$sourceRoot\sitecore\$sitecoreVersion.zip"
    $dataFolder = "$targetFolder\Data"
    $websiteFolder = "$targetFolder\Website"
    $serverName = $env:COMPUTERNAME
    $sqlServerName = "$serverName"   
    Unzip-Archive $sourcePath $tmpFolder

    Write-Host "Moving Sitecore installation to: " $targetFolder
    Move-Item "$tmpFolder\$sitecoreVersion" $targetFolder

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
    #>
}

Function Uninstall-Sitecore([string]$siteName, [string]$sitecoreVersion,  [string]$targetFolder, [string]$sourceRoot)
{
    Remove-AppPool $siteName
    Remove-Site  "$siteName.local" "local.$siteName.com"  $websiteFolder $siteName

    $server = new-object ("microsoft.sqlserver.management.smo.server") $sqlservername
    $databases = "core", "master", "web"
    foreach ($db in $databases)
    {    
        remove-database $server "$sitename.db"    	
    }
    
    Remove-Item -Recurse -Force $targetFolder
}


Export-ModuleMember -function Install-Sitecore
Export-ModuleMember -function Uninstall-Sitecore