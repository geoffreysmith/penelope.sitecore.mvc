param([string]$task = "InstallSitecoreAndDeploy")

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

get-module psake | remove-module

src\.nuget\NuGet.exe install src\.nuget\packages.config -OutputDirectory src\packages
import-module (Get-ChildItem "$scriptDir\src\packages\psake.*\tools\psake.psm1" | Select-Object -First 1)
import-module (Get-Childitem "$scriptDir\deploy\powercore.psm1" | Select-Object -First 1)

exec { invoke-psake "$scriptDir\default.ps1" $task }