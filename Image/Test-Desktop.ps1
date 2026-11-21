#
# Test-Desktop.ps1
#
# Author: Denes Solti
#

#Requires -Version 7.6

$ErrorActionPreference = 'Stop'
& xdpyinfo *> $null
if ($LASTEXITCODE -ne 0) { exit 1 }
Invoke-WebRequest -Uri 'http://127.0.0.1:6080/vnc.html' -TimeoutSec 3 | Out-Null
