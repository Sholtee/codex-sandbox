#
# Test-Development.ps1
#
# Author: Denes Solti
#

#Requires -Version 7.6

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:DOTNET_CLI_TELEMETRY_OPTOUT = 'true'
$env:DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = 'false'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
$env:POWERSHELL_TELEMETRY_OPTOUT = 'true'

if (!$IsLinux) { throw 'Run this check inside the Codex development container.' }

Write-Host 'Checking development tools in a desktop login shell...'
# Start outside the checkout so its global.json cannot select a different SDK.
pwsh -Login -NoProfile -NonInteractive -WorkingDirectory / -Command {
  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $true
  pwsh --version
  dotnet --version
  git --version
  python3 --version
  uv --version
  serena --version
}
Write-Host 'Development checks passed.'
