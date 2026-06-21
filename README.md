# Network Path Analyzer Toolkit

A PowerShell toolkit for L2/L3 network-path troubleshooting and selected guarded repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Network_Path_Analyzer_Toolkit.ps1 -TargetHost example.com
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Network_Path_Repair_Toolkit.ps1 -FlushDns -DryRun
```

Examples:

```powershell
.\Network_Path_Repair_Toolkit.ps1 -AdapterName Ethernet -RestartAdapter
.\Network_Path_Repair_Toolkit.ps1 -AdapterName Ethernet -RenewDhcp
.\Network_Path_Repair_Toolkit.ps1 -FlushDns
.\Network_Path_Repair_Toolkit.ps1 -ResetWinHttpProxy
.\Network_Path_Repair_Toolkit.ps1 -AdapterName Ethernet -DnsServer 1.1.1.1,8.8.8.8
```

## What the repair does

- Restarts one selected network adapter.
- Releases and renews DHCP on the selected adapter.
- Flushes the Windows DNS resolver cache.
- Resets the WinHTTP proxy.
- Sets explicit IPv4 DNS servers on one selected adapter.
- Captures adapter, address, route, DNS and proxy state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

Network repairs can interrupt remote sessions. DNS changes persist until changed again or reset to DHCP. Confirm the correct adapter and approved DNS servers before applying changes.

## Author

Dewald Pretorius — L2 IT Support Engineer
