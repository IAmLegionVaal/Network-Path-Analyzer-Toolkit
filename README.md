# Network Path Analyzer Toolkit

A read-only PowerShell toolkit for L2/L3 network path troubleshooting.

## Features

- DNS resolution checks
- Gateway and route context
- TCP port tests
- Traceroute output capture
- Proxy context capture
- CSV, TXT, and HTML reports

## How to run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Network_Path_Analyzer_Toolkit.ps1 -TargetHost example.com
```

## Safety

Diagnostic-only. It does not change network settings.
