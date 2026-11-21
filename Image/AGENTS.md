# Container agent instructions

## Serena workflow

At the start of every user turn, determine whether the request introduces code-related work. Repeat this check even when earlier turns in the same session were discussion, planning, documentation, or other non-code work.

Before searching, reading, diagnosing, or editing source code:

1. Discover Serena in the complete tool inventory, including deferred or lazy-loaded tools, if its availability is not already established in this environment. Reuse known tools; rediscover when availability changes.
2. If Serena is available and its instructions have not been read in the current session, call `initial_instructions`.
3. Activate the repository root if it is not already the confirmed active Serena project.
4. Use Serena for focused code navigation, symbol overviews, symbol reads, reference lookup, bug diagnosis, and symbol edits when it can answer cleanly.

Treat Serena as unavailable only after checking the complete tool inventory, or when its initialization or activation fails. In that case, continue with the available alternatives and mention the fallback.

Use shell reads such as `Get-Content` only for narrow patch context, exact diffs, non-code files, or command-oriented verification.

Serena is not required for simple documentation-only edits, direct command-output requests, or tasks clearly confined to non-code files.

## PowerShell usage

- Use PowerShell (`pwsh`) for shell commands and automation in this container. Write PowerShell syntax rather than assuming a Bash shell.
- Use UTF-8, LF line endings, and spaces for indentation.
- Use PowerShell-native filesystem operations with `-LiteralPath` when operating on an existing path. Verify resolved absolute paths and ownership before deleting task-created files or directories.
- Keep setup changes local to the task process and its children. Do not use `setx`, persistent `User`/`Machine` environment writes, registry edits, or global configuration commands for routine setup.
- Use installed tools' existing configuration and default cache and temporary-file locations. Do not redirect CLI homes, user-data directories, caches, or temporary directories with environment overrides.
- In automation scripts, stop on unhandled PowerShell and native-command failures:

  ```powershell
  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $true
  ```
