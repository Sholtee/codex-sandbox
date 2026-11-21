# Codex desktop in Docker

Run the Codex desktop in your browser and work on a local Git checkout. The container includes PowerShell, .NET, Git, Python, uv, and Serena with C# support.

## Start your first session

You’ll need Docker with Linux containers and Docker Compose v2 or later. The one-time setup also uses Git and PowerShell 7 on the host.

From the sandbox directory (the folder containing `compose.yaml`), run these commands. The initializer finds your workspace and creates a local `.env` file. Compose builds the image on the first start and runs the desktop in the background.

```sh
pwsh -NoProfile -File ./Initialize-Sandbox.ps1
docker compose up -d
```

1. Open the [local desktop viewer](http://127.0.0.1:6080/vnc.html?resize=remote) on the host, click **Connect**, and enter the `VNC_PASSWORD` from `.env`. The default is `codexdev`.
2. Sign in with ChatGPT using the browser **inside the desktop**.
3. Select Codex and add `/workspace` as a project. This is your host checkout, so edits and Git operations take effect on your machine immediately. Codex runs with Full access by default and can run commands without approval prompts.

## Stop and resume

Closing the viewer tab leaves the desktop running. Reopen the same link to reconnect. To stop the desktop, run `docker compose stop` from the sandbox directory. Run `docker compose up -d` there to resume.

Your sign-in, settings, and browser data persist in a Docker volume across stops and rebuilds. `docker compose down --volumes` erases that data. If you change `COMPOSE_PROJECT_NAME`, use `docker volume ls` to find the original home volume. Set `CODEX_HOME_VOLUME` in `.env` to its exact name before starting the desktop again.

## Configure the workspace and viewer

Edit `.env` beside [compose.yaml](compose.yaml) to change the workspace or connection settings. For example, a checkout named `MyApp` with the sandbox under `Docker/Codex` could use the following settings.

```dotenv
COMPOSE_PROJECT_NAME=myapp
CODEX_WORKSPACE_PATH=../..
NOVNC_PORT=6080
VNC_PASSWORD=codexdev
```

`CODEX_WORKSPACE_PATH` points to the folder you want to open as `/workspace`. Use an absolute path or one relative to the sandbox directory. On Linux, the folder must be writable by UID/GID 1000.

The viewer listens on `127.0.0.1`. If you run two sandboxes at once, give each its own `COMPOSE_PROJECT_NAME` and `NOVNC_PORT`, then use that port in the viewer URL. Choose a throwaway viewer password of 6–8 printable ASCII characters. Run `docker compose up -d` to apply `.env` changes.

## Customize the tools and Codex instructions

- Edit [Image/dependencies.yml](Image/dependencies.yml) to change tool versions or add Debian and Python packages. `CHATGPT_VERSION` defaults to `latest`. Set it to a specific release if you want to pin the desktop app.
- Edit [Image/AGENTS.md](Image/AGENTS.md) for instructions Codex should follow in every project using this image. Put instructions specific to one repository in that repository’s `AGENTS.md`.

After changing either image file or updating the sandbox, rebuild and start it with `docker compose up -d --build`. To refresh a version set to `latest`, run `docker compose build --no-cache` followed by `docker compose up -d`.
