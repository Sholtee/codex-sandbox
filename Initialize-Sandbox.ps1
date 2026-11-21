#
# Initialize-Sandbox.ps1
#
# Author: Denes Solti
#

#Requires -Version 7

$ErrorActionPreference = 'Stop'

$envFile = Join-Path $PSScriptRoot '.env'
if (Test-Path -LiteralPath $envFile) {
  Write-Host "Using existing settings in $envFile."
  return
}

# Git prints the owning worktree first for a submodule, or just the checkout
# root when the sandbox directory is tracked directly in the workspace.
$roots = @(git -C $PSScriptRoot rev-parse --show-superproject-working-tree --show-toplevel)
if ($LASTEXITCODE -ne 0 -or !$roots) { throw 'Could not locate the Git workspace.' }

$workspace = Get-Item -LiteralPath $roots[0]
$project = ($workspace.Name.ToLowerInvariant() -creplace '[^a-z0-9_-]', '').Trim('-', '_')
$sandboxName = "$project-codex-sandbox".TrimStart('-')
New-Item -Path $envFile -ItemType File -Value (@(
  "CODEX_SANDBOX_NAME=$sandboxName"
  "CODEX_WORKSPACE_PATH=$([IO.Path]::GetRelativePath($PSScriptRoot, $workspace.FullName).Replace('\', '/'))"
  'NOVNC_PORT=6080'
  'VNC_PASSWORD=codexdev'
  ''
) -join "`n") | Out-Null
Write-Host "Configured sandbox for '$($workspace.FullName)' using project '$sandboxName'."
