#
# Start-Desktop.ps1
#
# Author: Denes Solti
#

#Requires -Version 7.6

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

function Initialize-DBusSession {
  param([string[]] $Arguments = @())

  # D-Bus needs this directory before it starts, including on a fresh /tmp mount.
  install -d -m 0700 -- $env:XDG_RUNTIME_DIR
  if (!$env:DBUS_SESSION_BUS_ADDRESS) {
    Switch-Process -WithCommand (@(
      'dbus-run-session', '--', 'pwsh', '-NoLogo', '-NoProfile', '-NonInteractive',
      '-File', $PSCommandPath
    ) + $Arguments)
  }
}

function Initialize-SerenaCache {
  $resources = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.serena/language_servers/static'
  New-Item -ItemType Directory -Path $resources -Force | Out-Null
  & /bin/cp --recursive --update=none /opt/serena-language-servers/. $resources
}

function Initialize-DesktopSignals {
  # Native signal callbacks run outside PowerShell's runspace. This small bridge
  # only records the request; the PowerShell loop owns service shutdown and cleanup.
  Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
using System.Threading;

public static class DesktopSignals
{
    public static int ExitCode;

    public static PosixSignalRegistration Register(PosixSignal signal, int exitCode)
    {
        return PosixSignalRegistration.Create(signal, context =>
        {
            context.Cancel = true;
            Interlocked.CompareExchange(ref ExitCode, exitCode, 0);
        });
    }
}
'@
}

function Start-DesktopProcess {
  param([string] $FileName, [string[]] $Arguments = @())

  # ArgumentList preserves empty arguments, spaces, and sign-in callback URLs.
  $startInfo = [Diagnostics.ProcessStartInfo]@{
    FileName = $FileName
    UseShellExecute = $false
  }
  foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
  return [Diagnostics.Process]::Start($startInfo)
}

function Initialize-VncPassword {
  # The private runtime directory protects the encoder's output while it is written.
  $password = $env:VNC_PASSWORD
  if (!$password -or $password -cnotmatch '\A[\x20-\x7e]{6,8}\z') {
    throw 'VNC_PASSWORD must contain 6 to 8 printable ASCII characters.'
  }
  $passwordFile = Join-Path $env:XDG_RUNTIME_DIR 'vnc.passwd'
  # PowerShell 7.4+ preserves native stdout bytes when redirecting to a file.
  $password | tigervncpasswd -f > $passwordFile
  chmod 0600 -- $passwordFile
  return $passwordFile
}

function Wait-DesktopDisplay {
  param([Diagnostics.Process] $DisplayProcess)

  # Failed probes are expected while the display starts; bound each attempt.
  $PSNativeCommandUseErrorActionPreference = $false
  $readiness = [Diagnostics.Stopwatch]::StartNew()
  while ($readiness.Elapsed.TotalSeconds -lt 10 -and ![DesktopSignals]::ExitCode) {
    & timeout --signal=KILL 1s xdpyinfo *> $null
    if ($LASTEXITCODE -eq 0) { return }
    if ($DisplayProcess.HasExited) { throw 'The virtual display failed to start.' }
    Start-Sleep -Milliseconds 100
  }
  if (![DesktopSignals]::ExitCode) { throw 'Timed out waiting for the virtual display.' }
}

Initialize-DBusSession -Arguments $args
Initialize-DesktopSignals
Initialize-SerenaCache

$services = [Collections.Generic.List[Diagnostics.Process]]::new()
$signals = @(
  [DesktopSignals]::Register([Runtime.InteropServices.PosixSignal]::SIGTERM, 143)
  [DesktopSignals]::Register([Runtime.InteropServices.PosixSignal]::SIGINT, 130)
)
$exitCode = 1

try {
  # Raw VNC and X11 remain container-local. Only noVNC is published by Compose.
  $display = Start-DesktopProcess 'Xtigervnc' @(
    $env:DISPLAY, '-geometry', '1600x1000', '-depth', '24',
    '-rfbport', '5900', '-localhost', 'yes', '-SecurityTypes', 'VncAuth',
    '-PasswordFile', (Initialize-VncPassword), '-AlwaysShared', '-nolisten', 'tcp', '-ac'
  )
  $services.Add($display)

  Wait-DesktopDisplay $display
  if ([DesktopSignals]::ExitCode) { return }
  # A display can exit during a successful readiness probe.
  if ($display.HasExited) { $exitCode = $display.ExitCode; return }

  $services.Add((Start-DesktopProcess 'openbox'))
  $services.Add((Start-DesktopProcess 'websockify' @('--web=/usr/share/novnc', '0.0.0.0:6080', '127.0.0.1:5900')))
  $services.Add((Start-DesktopProcess (Join-Path $PSScriptRoot 'launch-chatgpt.sh') $args))
  Write-Host "`nOpen http://127.0.0.1:6080/vnc.html?resize=remote"

  # Process objects retain early exits while the other services are starting.
  while (![DesktopSignals]::ExitCode) {
    $finished = $services | Where-Object HasExited | Select-Object -First 1
    if ($finished) { $exitCode = $finished.ExitCode; break }
    Start-Sleep -Milliseconds 100
  }
} catch {
  [Console]::Error.WriteLine($_.Exception.Message)
} finally {
  # Give all services a chance to stop together, then bound shutdown so a stuck
  # process cannot keep Docker stop (or a failed startup) waiting indefinitely.
  $PSNativeCommandUseErrorActionPreference = $false
  foreach ($service in $services) {
    if (!$service.HasExited) {
      & /usr/bin/kill -TERM -- $service.Id 2>$null
    }
  }
  foreach ($service in $services) {
    if (!$service.WaitForExit(3000)) { $service.Kill($true); $service.WaitForExit() }
    $service.Dispose()
  }
  foreach ($signal in $signals) { $signal.Dispose() }
  # SIGINT can cancel PowerShell's pipeline directly into finally, bypassing
  # normal control flow after the service loop.
  if ([DesktopSignals]::ExitCode) { $exitCode = [DesktopSignals]::ExitCode }
  exit $exitCode
}
