[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [string]$AdapterName,
 [switch]$RestartAdapter,
 [switch]$RenewDhcp,
 [switch]$FlushDns,
 [switch]$ResetWinHttpProxy,
 [string[]]$DnsServer,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'NetworkPathRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Adapters=Get-NetAdapter|Select-Object Name,InterfaceDescription,Status,LinkSpeed;ifconfig=(& ipconfig /all|Out-String);Routes=Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue|Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric;Dns=Get-DnsClientServerAddress -AddressFamily IPv4|Select-Object InterfaceAlias,ServerAddresses;Proxy=(& netsh winhttp show proxy|Out-String)}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 7|Set-Content $before -Encoding UTF8
if(-not($RestartAdapter -or $RenewDhcp -or $FlushDns -or $ResetWinHttpProxy -or $DnsServer)){Write-Error 'Choose at least one repair action.';exit 2}
if(($RestartAdapter -or $RenewDhcp -or $DnsServer) -and -not $AdapterName){$AdapterName=(Get-NetAdapter|Where-Object Status -eq Up|Sort-Object ifIndex|Select-Object -First 1 -ExpandProperty Name)}
if(($RestartAdapter -or $RenewDhcp -or $DnsServer) -and -not $AdapterName){Write-Error 'Supply -AdapterName.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected network-path repairs? Connectivity may drop. Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($RestartAdapter){Act "Restarting adapter $AdapterName" {Restart-NetAdapter -Name $AdapterName -Confirm:$false}}
if($RenewDhcp){Act "Renewing DHCP on $AdapterName" {& ipconfig.exe /release "$AdapterName"|Out-Null;& ipconfig.exe /renew "$AdapterName"|Out-Null}}
if($FlushDns){Act 'Flushing DNS resolver cache' {Clear-DnsClientCache}}
if($ResetWinHttpProxy){Act 'Resetting WinHTTP proxy' {& netsh.exe winhttp reset proxy|Out-Null;if($LASTEXITCODE){throw "netsh exited $LASTEXITCODE"}}}
if($DnsServer){foreach($server in $DnsServer){[void][ipaddress]::Parse($server)};Act "Setting DNS servers on $AdapterName" {Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ServerAddresses $DnsServer}}
Start-Sleep 3;State|ConvertTo-Json -Depth 7|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
