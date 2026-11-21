# Codex desktop in Docker

Run the [Linux desktop preview](https://learn.chatgpt.com/docs/linux/linux-app) in your browser through noVNC. The host needs Docker with Linux containers and Docker Compose v2 or later.

## Start

Open the sandbox directory (`Docker/Codex` in this checkout). Run the initializer once with PowerShell 7. It asks Git for the owning workspace, derives the container name from that folder, and writes a local `.env` beside [compose.yaml](compose.yaml).

```sh
pwsh -NoProfile -File ./Initialize-Sandbox.ps1
docker-compose up
```

For subsequent starts, run `docker-compose up` from the sandbox directory. With the Docker CLI plugin, use `docker compose` for the same commands.

From the workspace root, use `docker-compose -f Docker/Codex/compose.yaml up`, adjusting the submodule path as needed. To use the short command there too, set `COMPOSE_FILE` to that path in your shell.

You can also set the two workspace variables in your shell or an existing `.env`. For a workspace named `MyApp` with the submodule at `Docker/Codex`, use

```dotenv
COMPOSE_PROJECT_NAME=myapp
CODEX_WORKSPACE_PATH=../..
```

Compose uses `COMPOSE_PROJECT_NAME` as the container name and appends `-codex-sandbox` to the local image tag. The example above creates the `myapp` container with the `myapp-codex-sandbox` image. The initializer lowercases the workspace folder name and normalizes it for Docker. For a manual prefix, use lowercase letters, digits, and hyphens between words. Choose a distinct prefix if two checkouts share the same normalized name.

Set `CODEX_WORKSPACE_PATH` relative to the submodule, or use an absolute path. For a submodule directly under the workspace root, use `..`.

Compose mounts the selected folder at `/workspace`. Each workspace builds its image on first use and reuses it on subsequent starts, so different workspaces can use different submodule revisions.

The initializer writes these viewer settings to new `.env` files. Add them to an existing `.env` if you want to customize them.

```dotenv
NOVNC_PORT=6080
VNC_PASSWORD=codexdev
```

To run multiple sandboxes on the same host, give each a distinct `COMPOSE_PROJECT_NAME` and `NOVNC_PORT`. For example, set `NOVNC_PORT=6081` for the second sandbox. Use a throwaway password of 6–8 printable ASCII characters.

To start a second sandbox from the same checkout, copy `.env` to a file outside the checkout and change its project name and port. From the sandbox directory, run `docker-compose --env-file /path/to/second.env up`.

1. Open [the desktop viewer](http://127.0.0.1:6080/vnc.html?resize=remote) using your configured port. Click **Connect** and enter your `VNC_PASSWORD`.
2. Sign in with ChatGPT using the browser inside the displayed desktop.
3. Select Codex and add `/workspace` as a project.

Run `docker-compose stop` to stop the desktop, or quit the desktop app. Closing the viewer tab disconnects the browser. Run `docker-compose up` to resume a stopped desktop.

## Updates and data

- Edit [Image/dependencies.yml](Image/dependencies.yml) to change tool versions, Debian packages, or Python packages. Under `services.codex.build.args`, `APT_PACKAGES` is a commented JSON array of APT arguments. Use `"package"` for the available Debian version or `"package=version"` to pin it. Compose passes the array to the installer as a single build argument.
- `UV_PACKAGES` uses the same format for Python requirements: use `"package"` for the available version or `"package==version"` to pin it. These packages share the `/opt/serena` virtual environment; keep `serena-agent` in the list for the configured MCP server and C# language server setup.
- `CHATGPT_VERSION` defaults to `"latest"`; set a numeric release version to pin the desktop app.
- After updating dependencies or the submodule, run `docker-compose up --build` to rebuild and start the desktop. Use `docker-compose build` to rebuild the image alone. To refresh floating dependencies such as ChatGPT `latest`, run `docker-compose build --no-cache` followed by `docker-compose up`.
- By default, settings, login, and browser data persist in `<project-name>-codex_desktop-home`. For example, `myapp` uses `myapp-codex_desktop-home`. Avoid `docker-compose down --volumes` unless you intend to erase them.
- If you rename the workspace folder or an older prefix is invalid in an image name (for example, `build_`), update `COMPOSE_PROJECT_NAME` in the sandbox's local `.env`.
- To reuse an existing home volume, find it with `docker volume ls` and set `CODEX_HOME_VOLUME` to its exact name in `.env` before starting. For example, use `CODEX_HOME_VOLUME=pub-codex-sandbox_desktop-home` if that volume holds your desktop data.
- `/workspace` is the writable host checkout: edits, including Git operations, immediately affect host files.
- The viewer is published only on `127.0.0.1` at the port set by `NOVNC_PORT`. The container runs non-root, but nested app/browser sandboxes are disabled and Codex defaults to Full access (`sandbox_mode = "danger-full-access"`, `approval_policy = "never"`), without command approval prompts. Credentials are stored in the home volume; outbound networking can reach host/LAN services.

On Linux, the checkout must be writable by UID/GID 1000. External Git worktree metadata is not mounted.

## Development

[Image/AGENTS.md](Image/AGENTS.md) supplies global Serena and PowerShell guidance for Codex. Put project-specific instructions in the workspace's `AGENTS.md`.

The image disables PowerShell and .NET CLI telemetry through container-wide environment defaults.

The image includes PowerShell, .NET, Git, Python, uv, and Serena with its C# language server. To print the installed tool versions from a desktop login shell, run

```sh
docker-compose exec codex pwsh -NoProfile -File /usr/local/bin/Test-Development.ps1
```
