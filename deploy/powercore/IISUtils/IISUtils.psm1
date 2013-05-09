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