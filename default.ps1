properties {
	$base_dir  = resolve-path .
	$lib_dir = "$base_dir\lib"
	$build_dir = "$base_dir\tmp"
	$packages_dir = "$base_dir\src\packages"
	$buildartifacts_dir = "$build_dir\artifacts"
    $release_dir = "$build_dir\release"
	$sln_file = "$base_dir\src\Penelope.Sitecore.Mvc.sln"
	$version = "0.1"
	$tools_dir = "$base_dir\Tools"	
    $sitecore_files = "$base_dir\sitecore"
    
    $global:configuration = "Release"
    
    $test_prj = @("Penelope.Tests.dll")
    
    $deploy_dir = "C:\_SITES\PenelopeSitecore.local"
    $sitecore_version = "Sitecore 6.6.0 rev. 130404"
    $site_name = "PenelopeSitecore"
    $sql_server_name = "(local)"    
}
	
task default -depends DeployOnly

task Verify40 {
	if( (ls "$env:windir\Microsoft.NET\Framework\v4.0*") -eq $null ) {
		throw "Building Penelope.Sitecore.Mvc requires .NET 4.0, which doesn't appear to be installed on this machine"
	}
}


task Clean {
	Remove-Item -force -recurse $buildartifacts_dir -ErrorAction SilentlyContinue
    Exec { msbuild $sln_file /v:Quiet /t:Clean /p:Configuration=Release }
}

task Init -depends Verify40, Clean {

	if($env:BUILD_NUMBER -ne $null) {
		$env:buildlabel  = $env:BUILD_NUMBER
	}
	if($env:buildlabel -eq $null) {
		$env:buildlabel = "13"
	}	

	New-Item $build_dir -itemType directory -ErrorAction SilentlyContinue | Out-Null
}

task Compile -depends Init {
	Write-Host "Compiling with '$global:configuration' configuration" -ForegroundColor Yellow
	exec { msbuild "$sln_file" /p:OutDir="$buildartifacts_dir\" /p:Configuration=$global:configuration }	
}

task Test -depends Compile {
	
	Write-Host $test_prjs
		
	$nunit = Get-PackagePath nunit.runners
	$nunit = "$nunit\tools\nunit-console-x86.exe"
	Write-Host "nunit location: $nunit"
	
	$test_prjs | ForEach-Object {
        Write-Host "Testing $buildartifacts_dir\$_"
		exec { &"$nunit" "$buildartifacts_dir\$_" }
	}	
}

task Deploy -depends Test, MergeWithSitecore {
    robocopy $release_dir "$deploy_dir\Website" /COPYALL /B /SEC /MIR /R:0 /W:0 /NJH /NFL /NDL /XF   
    
    if (!($lastexitcode -gt 3))
    {
        Exit 0
	}
     
    Write-Host "Deploy local complete"
}

task DeployAndRunTds -depends Deploy {
    Write-Host "Deploy and TDS installation complete"
}

task InstallSitecoreAndDeploy -depends InstallSitecore, Deploy {
    Write-Host "Install Sitecore and deploy local complete"
}

task MergeWithSitecore -depends ExtractSitecoreInstallation, Compile {	
	Write-Host "Done building Penelope.Sitecore.Mvc"      
    
    Write-Host "Merge $buildartifacts_dir to $release_dir"  
   
    Copy-Item "$build_dir\$sitecore_version\Website\*" $release_dir -force -recurse  
   
    robocopy "$buildartifacts_dir\_PublishedWebsites\Penelope.Web\" $release_dir /COPYALL /B /SEC /MIR /R:0 /W:0 /NJH /NFL /NDL /XF   
    
    if (!($lastexitcode -gt 3))
    {
        Exit 0
	}
}

task ExtractSitecoreInstallation {
    if (!(Test-Path "$build_dir\$sitecore_version\"))
    {        
        Write-Host "Extracting Sitecore to $build_dir"
        Unzip-Archive "$sitecore_files\$sitecore_version.zip" $build_dir       
           
        Write-Host "Sitecore already extracted to $build_dir"
    } else {
        Write-Host "Sitecore already extracted, skipping..."
    }
}

task CleanSitecoreInstallation { 
    Remove-Item "$build_dir\$sitecore_version\Databases\Oracle" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item "$build_dir\$sitecore_version\Website\Web.config.Mvc" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item "$build_dir\$sitecore_version\Website\Web.config.Oracle.mvc" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item "$build_dir\$sitecore_version\Website\App_Config\ConnectionStringsOracle.config" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item "$build_dir\$sitecore_version\Website\App_Config\Include\*.example" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item "$build_dir\$sitecore_version\Website\App_Config\Include\*.disabled" -force -recurse -ErrorAction SilentlyContinue
        
    Remove-Item "$build_dir\$sitecore_version\Website\Web.config.Mvc" -force -recurse -ErrorAction SilentlyContinue
       
    Copy-Item "$build_dir\$sitecore_version\Website\bin_NET4\*" "$build_dir\$sitecore_version\Website\bin\" -force -ErrorAction SilentlyContinue
    
    Remove-Item "$build_dir\$sitecore_version\Website\bin_NET4" -force -recurse -ErrorAction SilentlyContinue
}

task AttachSitecoreDatabases -depends  ExtractSitecoreInstallation, CleanSitecoreInstallation, CopyBaseSitecoreInstallToDeployFolder {
    $server = new-object ("microsoft.sqlserver.management.smo.server") $sql_server_name
    $databases = "core", "master", "web"
    
    foreach ($db in $databases)
    {       
        attach-database $server "$site_name.$db" "$deploy_dir\databases\sitecore.$db.mdf" "$deploy_dir\databases\sitecore.$db.ldf"
        set-connectionstring "$deploy_dir\Website\app_config\connectionstrings.config" "$db" "trusted_connection=yes;data source=$sql_server_name;database=$site_name.$db"
    }
    
    Write-Host "Sitecore databases attached"
}

task InstallSitecore -depends UninstallSitecore, CopyBaseSitecoreInstallToDeployFolder, AttachSitecoreDatabases {
    Copy-Item "$sitecore_files\License.xml" "$deploy_dir\Data" -force
        
    Set-ConfigAttribute "$deploy_dir\Website\web.config" "sitecore/sc.variable[@name='dataFolder']" "value" "$deploy_dir\Data"
    
    Create-AppPool $site_name "v4.0"
    
    Create-Site "$site_name.local" "local.$site_name.com"  "$deploy_dir\Website" $site_name
    
    Write-Host "Base sitecore installed to: local.$site_name.com"
}

task CopyBaseSitecoreInstallToDeployFolder -depends ExtractSitecoreInstallation {
    New-Item -Path $deploy_dir -ItemType directory
    Copy-Item "$build_dir\$sitecore_version\Data" $deploy_dir -recurse -force
    Copy-Item "$build_dir\$sitecore_version\Databases" $deploy_dir -recurse -force
    Copy-Item "$build_dir\$sitecore_version\Website" $deploy_dir -recurse -force
    
    Write-Host "Copy $build_dir\$sitecore_version\* to $deploy_dir complete"
}

task UninstallSitecore {
    Remove-AppPool $site_name
    Remove-Site "$site_name.local" "local.$site_name.com"  "$deploy_dir\Website" $site_name
    
    RemoveSitecoreDatabases
        
    Remove-Item $deploy_dir -Recurse -Force -ErrorAction SilentlyContinue
}

Function RemoveSitecoreDatabases {	
    $server = new-object ("microsoft.sqlserver.management.smo.server") $sql_server_name
    $databases = "core", "master", "web"
    
    foreach ($db in $databases)
    {
        if ($server.databases["$site_name.$db"] -ne $NULL) {
            $server.DetachDatabase("$site_name.$db", $false)
            Remove-Item "$deploy_dir\databases\sitecore.$db.ldf" -force
            Remove-Item "$deploy_dir\databases\sitecore.$db.mdf" -force
        }
    }
    
    Write-Host "Sitecore databases removed"       
}

TaskTearDown {	
	if ($LastExitCode -ne 0) {
		write-host "TaskTearDown detected an error. Build failed." -BackgroundColor Red -ForegroundColor Yellow		
		# throw "TaskTearDown detected an error. Build failed."
		exit 1
	}
}

Function Get-PackagePath {
	Param([string]$packageName)
		
	$packagePath = Get-ChildItem "$packages_dir\$packageName.*" |
						Sort-Object Name -Descending | 
						Select-Object -First 1
	Return "$packagePath"
}