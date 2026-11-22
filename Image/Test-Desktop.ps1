#
# Test-Desktop.ps1
#
# Author: Denes Solti
#

#Requires -Version 7.6

$ErrorActionPreference = 'Stop'
& xdpyinfo *> $null
if ($LASTEXITCODE -ne 0) { exit 1 }
# This health check runs inside the container, where websockify always listens
# on port 6080. NOVNC_PORT configures the published port on the host.
Invoke-WebRequest -Uri 'http://127.0.0.1:6080/vnc.html' -TimeoutSec 3 | Out-Null
