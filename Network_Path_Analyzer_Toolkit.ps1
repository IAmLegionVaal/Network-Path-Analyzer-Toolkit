#requires -Version 5.1
<#
.SYNOPSIS
    Network Path Analyzer Toolkit.
.DESCRIPTION
    Read-only DNS, route, traceroute, and TCP path reporter for Windows support.
#>
[CmdletBinding()]
param([string]$TargetHost='www.microsoft.com',[int[]]$Ports=@(80,443),[string]$OutputPath)
$RunStamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Network_Path_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
$checks=@()
function New-Check{param($Area,$Name,$Status,$Value,$Recommendation)[PSCustomObject]@{Area=$Area;Name=$Name;Status=$Status;Value=$Value;Recommendation=$Recommendation}}
try{$ips=Resolve-DnsName $TargetHost -ErrorAction Stop|Where-Object IPAddress|Select-Object -ExpandProperty IPAddress -Unique;$checks+=New-Check 'DNS' $TargetHost 'OK' ($ips -join ', ') 'DNS resolution succeeded.'}catch{$checks+=New-Check 'DNS' $TargetHost 'Warning' $_.Exception.Message 'Review DNS configuration.'}
foreach($p in $Ports){try{$tcp=Test-NetConnection -ComputerName $TargetHost -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue}catch{$tcp=$false};$checks+=New-Check 'TCP' "$TargetHost`:$p" ($(if($tcp){'OK'}else{'Warning'})) $tcp 'Review firewall, route, or service listener if failed.'}
Get-NetRoute|Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric|Export-Csv (Join-Path $OutputPath "routes_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
Get-NetIPConfiguration|Select-Object InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer|Export-Csv (Join-Path $OutputPath "ip_config_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
try{tracert.exe $TargetHost|Out-File (Join-Path $OutputPath "tracert_$RunStamp.txt") -Encoding UTF8}catch{}
try{netsh.exe winhttp show proxy|Out-File (Join-Path $OutputPath "winhttp_proxy_$RunStamp.txt") -Encoding UTF8}catch{}
$checks|Export-Csv (Join-Path $OutputPath "network_path_checks_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$checks|ConvertTo-Html -Title 'Network Path Analyzer' -PreContent "<h1>Network Path Analyzer - $TargetHost</h1><p>Generated $(Get-Date)</p>"|Set-Content (Join-Path $OutputPath "network_path_$RunStamp.html") -Encoding UTF8
$checks|Format-Table -AutoSize -Wrap
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
