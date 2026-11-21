#############################################################################
#                                                                           #
# Dockerfile                                                                #
#                                                                           #
# Author: Denes Solti                                                       #
#                                                                           #
#############################################################################

ARG DOTNET_VERSION
ARG UV_VERSION
ARG DEBIAN_VERSION
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS dotnet
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
FROM debian:${DEBIAN_VERSION}

# BuildKit supplies amd64/arm64; an explicit URL can select another app release.
ARG TARGETARCH
ARG CHATGPT_DEB_URL
ARG POWERSHELL_VERSION
ARG POWERSHELL_PREREQUISITES

ENV POWERSHELL_TELEMETRY_OPTOUT=true \
    POWERSHELL_UPDATECHECK=Off \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=true

COPY --from=dotnet /usr/share/dotnet /usr/share/dotnet
COPY --from=uv /uv /uvx /usr/local/bin/

# PowerShell must exist before Docker can use it as the build shell.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ${POWERSHELL_PREREQUISITES} \
    && curl --fail --location --retry 3 \
        "https://packages.microsoft.com/repos/microsoft-debian-trixie-prod/pool/main/p/powershell/powershell_${POWERSHELL_VERSION}-1.deb_${TARGETARCH}.deb" \
        --output /tmp/powershell.deb \
    && apt-get install -y --no-install-recommends /tmp/powershell.deb \
    && rm /tmp/powershell.deb

SHELL ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command"]

ARG SERENA_VERSION
ARG CHATGPT_VERSION
ARG APT_PACKAGES
COPY Install-Desktop.ps1 /tmp/Install-Desktop.ps1
COPY container-browser.desktop /usr/share/applications/container-browser.desktop
RUN & /tmp/Install-Desktop.ps1
RUN Remove-Item -LiteralPath /tmp/Install-Desktop.ps1

COPY Start-Desktop.ps1 Test-Desktop.ps1 Test-Development.ps1 /usr/local/bin/
COPY --chmod=0755 launch-chatgpt.sh container-browser.sh /usr/local/bin/
COPY config.toml /etc/codex/config.toml

# Throwaway local viewer password, visible in the source and image metadata.
# Use 6-8 printable ASCII characters; override VNC_PASSWORD at runtime to change it.
ENV VNC_PASSWORD=codexdev \
    CODEX_HOME=/home/codex/.codex \
    DISPLAY=:1 \
    XDG_RUNTIME_DIR=/tmp/runtime-codex \
    SHELL=/usr/bin/pwsh \
    BROWSER=/usr/local/bin/container-browser.sh

USER codex
WORKDIR /workspace

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "/usr/local/bin/Start-Desktop.ps1"]
