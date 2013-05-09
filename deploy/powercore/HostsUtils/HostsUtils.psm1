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