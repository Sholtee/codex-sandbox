#
# Install-Desktop.ps1
#
# Author: Denes Solti
#

#Requires -Version 7.6

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# Runs only while building the image. Every package and setting stays inside it.
# Chromium handles sign-in; Openbox and TigerVNC supply the virtual desktop;
# noVNC/websockify expose it to the host browser. The remaining packages provide
# desktop integration, fonts, readiness probes, and development dependencies.
apt-get update
apt-get install -y --no-install-recommends @(ConvertFrom-Json -InputObject $env:APT_PACKAGES)

# Keep executables outside the persistent home so image upgrades also update
# existing profiles. Seed Roslyn's writable cache at startup, without downloads.
uv venv --python /usr/bin/python3 /opt/serena
uv pip install --python /opt/serena/bin/python @(ConvertFrom-Json -InputObject $env:UV_PACKAGES)
# Desktop login shells reset PATH, so expose both tools in a standard directory.
ln --symbolic /usr/share/dotnet/dotnet /usr/local/bin/dotnet
ln --symbolic /opt/serena/bin/serena /usr/local/bin/serena
serena download-ls-dependencies csharp
Move-Item -LiteralPath /root/.serena/language_servers/static -Destination /opt/serena-language-servers
uv cache clean

$appUrl = $env:CHATGPT_DEB_URL
if (!$appUrl) {
  $appUrl = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${env:CHATGPT_VERSION}_$($env:TARGETARCH).deb"
}
curl --fail --location --retry 3 $appUrl --output /tmp/chatgpt.deb
apt-get install -y --no-install-recommends /tmp/chatgpt.deb
Remove-Item -LiteralPath /tmp/chatgpt.deb
Get-ChildItem -LiteralPath /var/lib/apt/lists -Force | Remove-Item -Recurse -Force

git config --system --add safe.directory /workspace
useradd --create-home --uid 1000 --user-group --shell /usr/bin/pwsh codex
install -d -o codex -g codex -m 0700 /home/codex/.codex
install -d -o codex -g codex /workspace

# Preserve the package's URI handlers, applying the same container flags when
# a browser callback starts another app instance.
foreach ($path in (dpkg-query -L chatgpt)) {
  if ($path -like '/usr/share/applications/*.desktop') {
    Set-Content -LiteralPath $path -NoNewline -Value (
      (Get-Content -LiteralPath $path -Raw) -replace '(?m)^Exec=.*$', 'Exec=/usr/local/bin/launch-chatgpt.sh %U'
    )
  }
}
update-desktop-database /usr/share/applications
# Separate strings use Linux line endings even when this script was checked out
# with CRLF. A trailing CR makes xdg-mime ignore the configured desktop filename.
Set-Content -LiteralPath /etc/xdg/mimeapps.list -Value @(
  '[Default Applications]'
  'x-scheme-handler/http=container-browser.desktop'
  'x-scheme-handler/https=container-browser.desktop'
  'text/html=container-browser.desktop'
)
