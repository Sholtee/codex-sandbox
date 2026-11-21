# Agent instructions

## Global Computer State: Changes Prohibited

**Agents MUST NOT modify global computer state, including any user-wide or machine-wide settings, files, resources, or services.** Only an explicit user request for a specific global change overrides this prohibition for that change. Authorization to implement, build, test, format, install project dependencies, or troubleshoot does not authorize global changes.

The prohibition also applies to indirect changes caused by invoked tools, SDK first-run initialization, installers, and child processes. Configure tools to prevent those side effects before running them. If a required operation cannot stay within the authorized scope, stop and request explicit authorization for the specific global change.

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

- Use PowerShell (`pwsh`) for shell commands and automation. Write PowerShell syntax rather than assuming a Bash shell.
- Use UTF-8, LF line endings, and spaces for indentation.
- Use PowerShell-native filesystem operations with `-LiteralPath` when operating on an existing path. Verify resolved absolute paths and ownership before deleting task-created files or directories.
- Use installed tools' existing configuration and default cache and temporary-file locations. Do not redirect CLI homes, user-data directories, caches, or temporary directories with environment overrides.
- In automation scripts, stop on unhandled PowerShell and native-command failures:

  ```powershell
  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $true
  ```
