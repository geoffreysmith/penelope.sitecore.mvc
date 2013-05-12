<#
	.DESCRIPTION
		Setup forms.config 
#>
function Setup-FormsConfig([string]$webroot, [xml]$config)
{	
	Write-Output "Setup forms.config"
	
	$formsConfigTemplatePath = "$webroot\website\App_Config\Include\forms.config.template"
	$formsConfigPath = $formsConfigTemplatePath.Substring(0, $formsConfigTemplatePath.LastIndexOf('.'))
	
	#get content of forms.config.template
	$formsConfig = [xml](get-content $formsConfigTemplatePath)	
		
	$connectionString = $formsConfig.configuration.sitecore.SelectSingleNode("formsDataProvider/param[@desc='connection string']")
	$connectionString.InnerText = $config.InstallSettings.ConnectionStrings.Forms.Replace("(Source)" , $config.InstallSettings.DatabaseDeployment.DatabaseServer)
			
	# save xml content to connectionStrings.config
	$formsConfig.Save($formsConfigPath)
}

<#
	.DESCRIPTION
		Uncomment analytics scheduling
#>
function Uncomment-AnalyticsSchedule([string]$webroot)
{	
	Write-Output "uncommentAnalyticsSchedule - started"
	
	$analyticsConfigPath = "$webroot\website\App_Config\Include\Sitecore.Analytics.config"
    Uncomment-ConfigSection $analyticsConfigPath "Sitecore.Analytics.Tasks.SubscriptionTask, Sitecore.Analytics"
    Uncomment-ConfigSection $analyticsConfigPath "Sitecore.Analytics.Tasks.EmailReportsTask"
    Uncomment-ConfigSection $analyticsConfigPath "Sitecore.Analytics.Tasks.UpdateReportsSummaryTask"    
}

<#
	.DESCRIPTION
		Uncomment ECM scheduling
#>
function Uncomment-ECMSchedule([string]$webroot)
{	
	Write-Output "uncommentECMSchedule - started"
	
	$ecmConfigPath = "$webroot\website\App_Config\Include\Sitecore.EmailCampaign.config"
    Uncomment-ConfigSection $ecmConfigPath "<scheduling>"  
}

<#
	.DESCRIPTION
		Disable Analytics Lookups
#>
function Disable-AnalyticsLookups([string]$webroot)
{	
	$analyticsConfigPath = "$webroot\website\App_Config\Include\Sitecore.Analytics.config"    
    Set-SitecoreSetting $analyticsConfigPath "Analytics.PerformLookup" "false"    
	
	Write-Output "Analytics lookups disabled."
}

<#
	.DESCRIPTION
		Enable Shell Redirect
        For example - redirect from /sitecore to cms.sitecore.net
#>
function Enable-ShellRedirect([string]$webroot)
{	
	$redirectConfigPath = "$webroot\website\sitecore\web.config.disabled"
	$redirectConfigEnabledPath = "$webroot\website\sitecore\web.config"

    if (Test-Path $redirectConfigPath)
    {
        $redirectConfig = Get-Item $redirectConfigPath  -ErrorAction SilentlyContinue
        Rename-Item $redirectConfigPath $redirectConfigEnabledPath -Verbose
    }
    
	Write-Output "Shell redirect enabled"
}

<#
	.DESCRIPTION
		Disable Analytics for all sites in <sites> section of Web.config
#>
function Disable-SitesAnalytics([string]$webroot)
{	
    Write-Output "Disabling analytics for <sites>" 
	$webConfigPath = "$webroot\website\Web.config"
    $webConfig = [xml](get-content $webConfigPath)

    foreach ($i in $webConfig.SelectNodes("/configuration/sitecore/sites"))
    {
        foreach ($site in $i.ChildNodes) 
        {
            $site.SetAttribute("enableAnalytics", "false")                    
        }
    }  
   
    $webConfig.Save($webConfigPath)
}

<#
	.DESCRIPTION
		Set AutomationMachineName setting in config
#>
function Set-AutomationMachineName([string]$webroot, [string]$machineName)
{	
	Write-Output "Setting Automation.MachineName to $machineName"
	$analyticsConfigPath = "$webroot\website\App_Config\Include\Sitecore.Analytics.config"    
    Set-SitecoreSetting $analyticsConfigPath "Analytics.Automation.MachineName" $machineName
}

<#
	.DESCRIPTION
		Set Execution Timeout
#>
function Set-ExecutionTimeout([string]$webroot, [string] $timeout)
{
	Write-Output "Setting Execution Timeout in web.config to $timeout"
	
    $webConfigPath = "$webroot\website\web.config"	
    Set-ConfigAttribute $webConfigPath "system.web/httpRuntime" "executionTimeout" $timeout
}

# Enable LocalMTA
<#
	.DESCRIPTION
		
#>
function EnableLocalMTA([string]$webroot)
{
	Write-Output "Enabling local MTA"
	
	$websiteConfigPath = "$webroot\website\App_Config\Include\Sitecore.EmailCampaign.config"
    Set-SitecoreSetting $websiteConfigPath "UseLocalMTA" "true"    
    Set-SitecoreSetting $websiteConfigPath "SMTP.AuthMethod" "NONE"         
}

<#
	.DESCRIPTION
		Disable Chars Validation
#>
function Disable-CharsValidation([string]$webroot)
{
	Write-Output "Disabling Chars Validation"
	
	$webConfigPath = "$webroot\website\web.config"    
    Set-SitecoreSetting $webConfigPath "InvalidItemNameChars" ""
	Set-SitecoreSetting $webConfigPath "ItemNameValidation" "^[\w\*\$][\.\w\s\-\$]*(\(\d{1,}\)){0,1}$" 	
}

<#
	.DESCRIPTION
		Enable Chars Validation
#>
function Enable-CharsValidation([string]$webroot)
{
	Write-Output "Enabling Chars Validation"
	
	$webConfigPath = "$webroot\website\web.config"
	$InvalidItemNameChars = $config.InstallSettings.CustomSettings.InvalidItemNameChars
    Set-SitecoreSetting $webConfigPath "InvalidItemNameChars" $InvalidItemNameChars
	Set-SitecoreSetting $webConfigPath "ItemNameValidation" "^[\w\*\$][\w\s\-\$]*(\(\d{1,}\)){0,1}$" 	
}

<#
	.DESCRIPTION
		Set Config Attribute
#>
function Set-ConfigAttribute([string]$configPath, [string] $xpath, [string] $attribute, [string] $value)
{
    Write-Output "Setting attribute $xpath in $configPath to $value"
	
	$config = [xml](get-content $configPath)
	$config.configuration.SelectSingleNode($xpath).SetAttribute($attribute, $value)	
	$config.Save($configPath)
}

<#
	.DESCRIPTION
		Set Connection String
#>
function Set-ConnectionString([string]$configPath, [string] $connectionStringName, [string] $value)
{
    Write-Output "Setting connection string $connectionStringName in $configPath to $value"
	
	$config = [xml](get-content $configPath)
	$config.SelectSingleNode("connectionStrings/add[@name='$connectionStringName']").SetAttribute("connectionString", $value)	
	$config.Save($configPath)
}

<#
	.DESCRIPTION
		Set Sitecore Setting
#>
function Set-SitecoreSetting([string]$configPath, [string] $name, [string] $value)
{
    Write-Output "Setting Sitecore setting $name"
	
    $xpath = "settings/setting[@name='" + $name + "']"   
	$config = [xml](get-content $configPath)
	$config.configuration.sitecore.SelectSingleNode($xpath).SetAttribute("value", $value)	
	$config.Save($configPath)
}

<#
	.DESCRIPTION
		Uncomment config file section
#>
function Uncomment-ConfigSection([string]$configPath, [string] $pattern)
{
    Write-Output "Uncommenting section containing text $pattern in $configPath"

    $xDoc = [System.Xml.Linq.XDocument]::Load($configPath)
    $endpoints = $xDoc.Descendants("configuration") | foreach { $_.DescendantNodes()}               
    
    $configSection = $endpoints | Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Comment -and $_.Value -match $pattern }        
    if ($configSection -ne $NULL)
    {    
        $configSection | foreach { $_.ReplaceWith([System.Xml.Linq.XElement]::Parse($_.Value)) }
    }
    
    $emailReportsAgent | foreach { Write-Output $_.Value; }
    $xDoc.Save($configPath)
}

<#
	.DESCRIPTION
		Enable Elmah tool
#>
function Enable-Elmah([string]$webRoot)
{    
    Write-Output "Enableing Elmah"
    
    $webConfig = "$webroot\website\web.config"

    Uncomment-ConfigSection $webConfig "Elmah.ErrorLogModule, Elmah"
    Uncomment-ConfigSection $webConfig "Elmah.ErrorFilterModule, Elmah"
    Uncomment-ConfigSection $webConfig "Elmah.ErrorMailModule, Elmah"
    
    $xpath = "elmah/errorMail"
    $attribute = "subject"
    
    $config = [xml](get-content $webConfig)
	$attrValue = $config.configuration.SelectSingleNode($xpath).GetAttribute($attribute);
    Set-ConfigAttribute $webConfig $xpath $attribute $attrValue.Replace("#SERVERNAME#", [Environment]::MachineName);
}

<#
	.DESCRIPTION
		Turn On Crm Profiling
#>
function Enable-CrmProfiling([string]$webroot)
{
    Write-Output "Enabling CRM Profiling"
    
    $webConfig = "$webroot\website\web.config"
    $crmConfig = "$webroot\website\App_Config\Include\crm.config"
    
    $attributeName = "providerName"
    $targetProvider = "wrapper"
    
    $webConfigContents = [xml](get-content $webConfig)
    
    # Change crm providers for wrappers 
    $xpath = "sitecore/switchingProviders/membership/provider[@providerName='crm']";
    $attrValue = $webConfigContents.configuration.SelectSingleNode($xpath);
    if($attrValue -ne $NULL)
    {
        Set-ConfigAttribute $webConfig $xpath $attributeName $targetProvider;
    }
    
    $xpath = "sitecore/switchingProviders/roleManager/provider[@providerName='crm']";
    $attrValue = $webConfigContents.configuration.SelectSingleNode($xpath);
    if($attrValue -ne $NULL)
    {
        Set-ConfigAttribute $webConfig $xpath $attributeName $targetProvider;        
    }
    
    $xpath = "sitecore/switchingProviders/profile/provider[@providerName='crm']";
    $attrValue = $webConfigContents.configuration.SelectSingleNode($xpath);
    if($attrValue -ne $NULL)
    {
        Set-ConfigAttribute $webConfig $xpath $attributeName $targetProvider;        
    }            
    
    # Turn on crm profiling setting
    Set-SitecoreSetting $crmConfig "Crm.CrmAccessProfiling" "true";
        
    Write-Output "Enable-CrmProfiling - done"
}

Export-ModuleMember -function Setup-FormsConfig
Export-ModuleMember -function Uncomment-AnalyticsSchedule
Export-ModuleMember -function Uncomment-ECMSchedule
Export-ModuleMember -function Disable-AnalyticsLookups
Export-ModuleMember -function Enable-ShellRedirect
Export-ModuleMember -function Disable-SitesAnalytics
Export-ModuleMember -function Set-AutomationMachineName
Export-ModuleMember -function Set-ExecutionTimeout
Export-ModuleMember -function EnableLocalMTA
Export-ModuleMember -function Disable-CharsValidation
Export-ModuleMember -function Enable-CharsValidation
Export-ModuleMember -function Set-ConfigAttribute
Export-ModuleMember -function Set-ConnectionString
Export-ModuleMember -function Set-SitecoreSetting
Export-ModuleMember -function Uncomment-ConfigSection
Export-ModuleMember -function Enable-Elmah
Export-ModuleMember -function Enable-CrmProfiling

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

<#
	.DESCRIPTION
		Drops a database
#>
Function Remove-Database($server, $databaseName)
{
    "Removing existing database - " + $databaseName
    IF ($server.databases[$databaseName] -ne $NULL) {
        $server.databases[$databaseName].drop()
    }
}

<#
	.DESCRIPTION
		Creates new database on specified SQL server. Existing DB will be overwritten
#>
Function Create-Database ($server, $databaseName)
{
	$dataFileFolder = $server.Settings.DefaultFile
	$logFileFolder = $server.Settings.DefaultLog
	if ($dataFileFolder -eq $NULL -or $dataFileFolder.Length -eq 0) {
	    $dataFileFolder = $server.Information.MasterDBPath
	}
	if ($logFileFolder -eq $NULL -or $logFileFolder.Length -eq 0) {
	    $logFileFolder = $server.Information.MasterDBLogPath
	}
    
    Write-Host "Data files folder - " $dataFileFolder
    Write-Host "Log files folder"    $logFileFolder
    Write-Host " " 
    
    Remove-Database($server, $databaseName)
    
    # Instantiate the database object and add the filegroups
    $db = new-object ('Microsoft.SqlServer.Management.Smo.Database') ($server, $databaseName)
    $sysfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db, 'PRIMARY')
    $db.FileGroups.Add($sysfg)

    # Create the file for the system tables
    $syslogname = $databaseName
    $dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $syslogname)
    $sysfg.Files.Add($dbdsysfile)
    $dbdsysfile.FileName = $dataFileFolder + '\' + $syslogname + '.mdf'
    $dbdsysfile.Size = [double](5.0 * 1024.0)
    $dbdsysfile.GrowthType = 'KB'
    $dbdsysfile.Growth = 25000
    $dbdsysfile.IsPrimaryFile = 'True'

    # Create the file for the log
    $loglogname = $databaseName + '_log'
    $dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db, $loglogname)
    $db.LogFiles.Add($dblfile)
    $dblfile.FileName = $logFileFolder + '\' + $loglogname + '.ldf'
    $dblfile.Size = [double](10.0 * 1024.0)
    $dblfile.GrowthType = 'KB'
    $dblfile.Growth = 25000

    # Create the database
    $db.Collation = 'SQL_Latin1_General_CP1_CI_AS'
    $db.CompatibilityLevel = 'Version100'
    $db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
    
    "Creating new database - " + $databaseName
    $db.Create()

    $db.SetOwner('sa')
}

<#
	.DESCRIPTION
		Restores database from provided backup file
#>
Function Restore-Database ($server, $database, $backupFile)
{
	$backupDevice = New-Object("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFile, "File")

	# Load up the Restore object settings
	$Restore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")
	$Restore.Action = 'Database' 
	$Restore.Database = $database
    $Restore.ReplaceDatabase = $true
	$Restore.Norecovery = $false
    $Restore.Devices.Add($backupDevice)

    $db = $server.databases[$database]
    
    Write-Host $db.FileGroups["PRIMARY"].Files[0].FileName
    Write-Host $db.LogFiles[0].FileName
    
    # Get information from the backup file
	$RestoreDetails = $Restore.ReadBackupHeader($server)
	$DataFiles = $Restore.ReadFileList($server)

	# Restore all backup files
	ForEach ($DataRow in $DataFiles) {
        $LogicalName = $DataRow.LogicalName
		$RestoreData = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
		$RestoreData.LogicalFileName = $LogicalName
		if ($DataRow.Type -eq "D") {
			# Restore Data file
			$RestoreData.PhysicalFileName = $db.FileGroups["PRIMARY"].Files[0].FileName 
		}
		Else {
			# Restore Log file
			$RestoreData.PhysicalFileName = $db.LogFiles[0].FileName
		}
		[Void]$Restore.RelocateFiles.Add($RestoreData)
	}
    
	$Restore.SqlRestore($server)
    "Backup restored: " + $server + $backupFile 
}

<#
	.DESCRIPTION
		Backups database with the specified name.
#>
Function Backup-Database ($d, $server, $dbName)
{
    Write-Host "Backup database" + $d.Name + "started"
    Write-Host "Backup file name is:" $dbName
    $dbBackup = new-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")

    $dbBackup.Database = $d.Name

    $backupFile = $backupFolder + "\" + $dbName + ".bak"
    Write-Host "Backup file:" $backupFile

    $dbBackup.Devices.AddDevice($backupFile, "File")

    $dbBackup.Action="Database"
    $dbBackup.Initialize = $TRUE
    $dbBackup.PercentCompleteNotification = 10
    $dbBackup.SqlBackup($server)  
    
    Write-Host "Backup database" + $d.Name + "finished"
}

<#
	.DESCRIPTION
		Attaches database on specified SQL server. Existing DB will be detached
#>
Function Attach-Database ($server, $databaseName, $dataFileName, $logFileName)
{
    if ($server.databases[$databaseName] -ne $NULL) {
        $server.DetachDatabase($databaseName, $false)
    }

	$sc = new-object System.Collections.Specialized.StringCollection; 
	$sc.Add($dataFileName) | Out-Null; 
	$sc.Add($logFileName) | Out-Null;
	
	$server.AttachDatabase($databaseName, $sc);     
}

<#
	.DESCRIPTION
		Executes SQL file at the specified server / database
#>
Function Execute-File ($server, $database, $file) 
{
    Write-Output "Executin Sql file $file at $server/$database"
    Invoke-SqlCmd -inputfile $file -serverinstance $server -database $database
}
  
Export-ModuleMember -function Create-Database
Export-ModuleMember -function Restore-Database
Export-ModuleMember -function Backup-Database
Export-ModuleMember -function Attach-Database
Export-ModuleMember -function Execute-File
Export-ModuleMember -function Remove-Database

<#
	.DESCRIPTION
		Downloads package from specified address to the temp storage. Skips download if file already exists.
#>
function Download-File([string]$url, [string]$destination)
{
	if (Test-Path $destination)
	{
		Write-Output "The file has been already downloaded. Skipping."
		return
	}

	Write-Output "Downloading file from $url to $destination"
	
	$client = new-object System.Net.WebClient
	$client.DownloadFile($url, $destination)
	
	Write-Output "Download complete!"		
}

<#
	.DESCRIPTION
		Extract package to the webroot
#>
function Extract-Package([string]$downloadLocation, [string]$webroot, [string]$extractedFolder, [string]$overwrite)
{
    if (($overwrite -eq "1") -and (Test-Path $webroot))
    {
        Write-Output "Webroot already exists. Removing...."
   		Remove-Item $webroot -Recurse -Force
        Start-sleep -milliseconds 2000
    }

    if(Test-Path $webroot)
	{
		Write-Output "Web root already exists. Skipping."
		return
	}

	# Create a web root directory and unzip archive
	New-Item $webroot -type directory -Force -Verbose
    Unzip-Archive $downloadLocation $webroot

    if (Test-Path "$webroot\$extractedFolder") {
    	move "$webroot\$extractedFolder\*" "$webroot" -Verbose
    	rm "$webroot\$extractedFolder" -Verbose
    }
}

<#
	.DESCRIPTION
		Copy license file to data folder
#>
function Copy-License([string]$wwwroot, [string]$webroot)
{
	copy "$wwwroot\Setup\License\license.xml" "$webroot\data" -Verbose
}

<#
	.DESCRIPTION
		Set file system Permissions by running setSecurity.bat
#>
function Set-Permissions([string]$wwwroot, [string]$webroot)
{
	Write-Output "Setting folder permissions ..."
	
	copy "$wwwroot\Setup\setSecurity.bat" "$webroot" -Verbose
	cd $webroot
	cmd /c "$webroot\setSecurity.bat" `>setsecurity.log 2`>`&1	
	
	Write-Output "Setting folder permissions Done."
}

<#
	.DESCRIPTION
		Remove development folders 
#>
function Cleanup-Folder([string]$folder)
{
	if (Test-Path $folder)
	{
        try
        {
		  Remove-Item $folder -Recurse -Force
		  Write-Output "Remove folder $folder. Done."
        }
        catch 
        {
            Write-Output "Remove-Item could not remove $folder"
        }
	}
}

<#
	.DESCRIPTION
		Package resources, like dictionary and indexes
#>
function Package-Resources([string]$webroot, [string]$tempFolder)
{	
    Write-Output "Packaging resources from $webroot to $tempFolder"
    
    $resourcesFolder = $tempFolder + "Resources\"
    $dataFolder = $tempFolder + "Resources\data"
    $websiteFolder = $tempFolder + "Resources\website"
    $indexesFolder = $tempFolder + "Resources\data\indexes"
    $websiteTempFolder = $tempFolder + "Resources\website\temp"
    $resourcesArchive = $tempFolder + "resources.zip"

    # Existing website
    $dictionaryPath = $webroot + "\website\temp\dictionary.dat"
    $indexesPath = $webroot + "\data\indexes"

    if(Test-Path $resourcesFolder)
	{
		Write-Output "Resources folder already exists. Let's drop it."
        rm $resourcesFolder -Force -Recurse
	}

	Write-Output "Creating new resources directory ..."
	New-Item $resourcesFolder -type directory -force
	New-Item $dataFolder -type directory -force
    New-Item $websiteFolder -type directory -force   
    New-Item $indexesFolder -type directory -force
    New-Item $websiteTempFolder -type directory -force   
    
    Write-Output "Dictionary path: $dictionaryPath"
    if(Test-Path $dictionaryPath)
	{        
        copy $dictionaryPath "$websiteTempFolder" -Verbose
	}
    
    Write-Output "Indexes path: $indexesPath"
    if(Test-Path $indexesPath)
	{
        copy "$indexesPath\*" "$indexesFolder" -Recurse -Verbose
	}
    
	Set-Content $resourcesArchive ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
	(dir $resourcesArchive).IsReadOnly = $false

    $shellApplication = new-object -com shell.application
	$zipPackage = $shellApplication.NameSpace($resourcesArchive)
	 
    $zipPackage.CopyHere($dataFolder)
    Start-sleep -milliseconds 10000
    $zipPackage.CopyHere($websiteFolder)
    Start-sleep -milliseconds 5000
    rm $resourcesFolder -force -recurse
}

<#
	.DESCRIPTION
		Extract archive
#>
function Unzip-Archive ([string]$file, [string]$targetFolder)
{
    if (Test-Path $file)
	{
        Write-Output "Unzipping package - $file"
		
    	$shell_app = new-object -com shell.application 
    	$zip_file = $shell_app.namespace($file) 
    	$destination = $shell_app.namespace($targetFolder)
    	$destination.CopyHere($zip_file.items(), 0x14)
		
    	Write-Output "Unzipping done!"	
	}
    else 
    {
        Write-Output "Package $file not found!"	
    }	
}

function Add-HostFileContent ([string]$IPAddress, [string]$computer)          
{                              
	$file = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts"            
	if (-not (Test-Path -Path $file)){            
		Throw "Hosts file not found"            
	}            
	$data = Get-Content -Path $file             
	$data += "$IPAddress  $computer"            
	Set-Content -Value $data -Path $file -Force -Encoding ASCII     
	
	Write-Output "Hosts file updated"
}
 
Export-ModuleMember -function Download-File
Export-ModuleMember -function Extract-Package
Export-ModuleMember -function Copy-License
Export-ModuleMember -function Set-Permissions
Export-ModuleMember -function Cleanup-Folder
Export-ModuleMember -function Package-Resources
Export-ModuleMember -function Unzip-Archive
Export-ModuleMember -function Add-HostFileContent


function Export-SourceModulesToSession
{
    Param(
     [Management.Automation.Runspaces.PSSession]
     [ValidateNotNull()]
     $Session,
 
    [IO.FileInfo[]]
    [ValidateNotNull()]
    [ValidateScript(
    {
      (Test-Path $_) -and (!$_.PSIsContainer) -and ($_.Extension -eq '.psm1')
    })]
   $ModulePaths
  )
 
   $remoteModuleImportScript = {
     Param($Modules)
 
     Write-Host "Writing $($Modules.Count) modules to temporary disk location"
 
     $Modules |
       % {
         $path = ([IO.Path]::GetTempFileName()  + '.psm1')
         $_.Contents | Out-File -FilePath $path -Force
         "Importing module [$($_.Name)] from [$path]"
         Import-Module $path
       }
   }
 
  $modules = $ModulePaths | % { @{Name = $_.Name; Contents = Get-Content $_ } }
  $params = @{
    Session = $Session;
    ScriptBlock = $remoteModuleImportScript;
    Argumentlist = @(,$modules);
  }
 
  Invoke-Command @params
}

Export-ModuleMember -function Export-SourceModulesToSession

#
# Powershell script for adding/removing entries to the hosts file.
#
# Known limitations:
# - does not handle entries with comments afterwards ("<ip>    <host>    # comment")
#
 
$file = "C:\Windows\System32\drivers\etc\hosts"
 
function Add-Host([string]$ip, [string]$hostname) {    
	Remove-Host $hostname
	$ip + "`t`t" + $hostname | Out-File -encoding ASCII -append $file
    Write-Output "Added to hosts file: $ip $hostname"
}
 
function Remove-Host([string]$hostname) {
    Write-Output "Removing from hosts file: $hostname"
	$c = Get-Content $file
	$newLines = @()
	
	foreach ($line in $c) {
		$bits = [regex]::Split($line, "\t+")
		if ($bits.count -eq 2) {
			if ($bits[1] -ne $hostname) {
				$newLines += $line
			}
		} else {
			$newLines += $line
		}
	}
	
	# Write file
	Clear-Content $file
	foreach ($line in $newLines) {
		$line | Out-File -encoding ASCII -append $file
	}
}
 
function Print-Hosts() {
	$c = Get-Content $file
	
	foreach ($line in $c) {
		$bits = [regex]::Split($line, "\t+")
		if ($bits.count -eq 2) {
			Write-Host $bits[0] `t`t $bits[1]
		}
	}
}
 
Export-ModuleMember -function Print-Hosts
Export-ModuleMember -function Remove-Host
Export-ModuleMember -function Add-Host

[System.Reflection.Assembly]::LoadFrom("C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll") | out-null;
Import-Module WebAdministration

<#
	.DESCRIPTION
		Creates application pool in IIS
#>
Function Create-AppPool ($siteName, $runtime, $user, $password)
{  
    Write-Output "Site Name: $sitename" 
    Write-Output "AppPool UserName: $user" 
      
    Remove-AppPool($siteName)
    
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager;
        
    $appPool = $serverManager.ApplicationPools.Add($siteName);
    Write-Output "AppPool Created"

    $appPool.ManagedRuntimeVersion = $runtime

    "Setting AppPool identity."	
	
	if ($user -and $password)
	{
	    $appPool.ProcessModel.username = [string]($user)
	    $appPool.ProcessModel.password = [string]($password)
	    $appPool.ProcessModel.IdentityType = "SpecificUser"
	}
	else
	{
		$appPool.ProcessModel.IdentityType = "LocalSystem"
	}
    $appPool.ProcessModel.IdleTimeout = [TimeSpan] "0.00:00:00"
    $appPool.Recycling.PeriodicRestart.time = [TimeSpan] "00:00:00"
    "AppPool identity set."  
    $serverManager.CommitChanges();    
    # Wait for the changes to apply
    Start-sleep -milliseconds 1000
}


<#
	.DESCRIPTION
		Removes application pool in IIS
#>
Function Remove-AppPool ($siteName)
{
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager;
    
    # Remove old AppPool (if exists with the came name)
    if ($serverManager.ApplicationPools[$siteName] -ne $NULL)
    {
        Write-Output "Old App Pool will be removed."
        $serverManager.ApplicationPools.Remove($serverManager.ApplicationPools[$siteName])
        
        $serverManager.CommitChanges();  
        Start-sleep -milliseconds 1000
    }
}

<#
	.DESCRIPTION
		Creates website in IIS
#>
Function Create-Site ($siteName, $websiteUrl, $webroot, $appPool, $port = 80)
{
    Write-Output "Website folder: $webroot" 
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager;
   
    # Remove old site (if exists with the came name)
    if ($serverManager.Sites[$siteName] -ne $NULL) 
    {
        "Old site will be removed."
        $serverManager.Sites.Remove($serverManager.Sites[$siteName])
    }
    $webSite = $serverManager.Sites.Add($siteName, "http", ":" + $port + ":$websiteUrl", $webroot);
    $webSite.Applications[0].ApplicationPoolName = $appPool;
    Write-Output "Website Created"
    Start-sleep -milliseconds 1000
    $serverManager.CommitChanges();    
    
    # Wait for the changes to apply
    Start-sleep -milliseconds 1000
}

Function Remove-Site ($siteName, $websiteUrl, $webroot, $appPool, $port = 80)
{
    Write-Output "Removing site: $siteName" 
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager;
   
    # Remove old site (if exists with the came name)
    if ($serverManager.Sites[$siteName] -ne $NULL) 
    {
        "Old site will be removed."
        $serverManager.Sites.Remove($serverManager.Sites[$siteName])
    }
    Start-sleep -milliseconds 1000
    $serverManager.CommitChanges();    
    
    # Wait for the changes to apply
    Start-sleep -milliseconds 2000
}

Export-ModuleMember -function Create-AppPool
Export-ModuleMember -function Create-Site
Export-ModuleMember -function Remove-Site
Export-ModuleMember -function Remove-AppPool