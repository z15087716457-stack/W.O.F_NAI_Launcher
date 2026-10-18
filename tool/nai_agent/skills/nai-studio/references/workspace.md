# Workspace, notes and MCP servers

## Workspace

- Each workspace has its own `notes/`, `outputs/`, `attachments/`, `snapshots/`, `skills/` and Pi sessions. File tools use the workspace as cwd; original attachments and outputs stay in their workspace. Background jobs keep the workspace and chat that started them.
- Switching workspaces never changes the generation page. Loading a generation configuration is an explicit `snapshot` load.
- Long-term rules go into user-visible `instructions.md` or `notes/`. Do not promote a compaction summary into a permanent rule automatically.
- Global instructions, the text before the built-in prompt and the built-in prompt itself are three separate settings; the user can view the final prompt in Settings.
- Editing or regenerating history is handled by Pi branches. If files and history disagree, read the actual state and continue; never repeat tools automatically.

## MCP servers

- External MCP servers are added and managed in Settings (stdio or Streamable HTTP). Exposure: `codemode` (call from codemode scripts, default), `deferred` (find with `tool_search`, then call directly), `direct` (always declared), `hidden` (not callable).
- Setting changes apply on the next idle send and resume the same session.
- The four Pi file tools and user servers run with the user's local permissions; the workspace binding is not a system sandbox.
