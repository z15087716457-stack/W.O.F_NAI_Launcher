# Configure Pi itself

Discover native `agent_manage` through codemode `searchTools` or `tool_search`. It remains available when Studio's business MCP is disabled. `resource` selects the area; `action` defaults to `read`. Results contain the inventory and paths.

| Resource | Actions and inputs |
|---|---|
| `skills` | `read`; `create(name, scope)`; `import(source, scope)`; `enable/disable/remove(id)`; `update(id, changes={enabled, mode})`; `refresh` |
| `extensions` | `read`; `add(source=absolute file/directory)`; `enable/disable/remove(id=path)`; `refresh` |
| `packages` | `read`; `install/update/uninstall/enable/disable(source, scope)`; source is a Pi npm, git or local package specification |
| `mcp` | `read`; `add(name, changes=config)`; `update(id, changes=patch)`; `enable/disable/remove(id)`; `test/reconnect/login/logout(id)`; an unsaved test accepts `name` and `changes` |
| `settings` | `read`; `update(changes, expected_version)` using the returned version; `read` also returns defaults |
| `instructions` | `read/update` manages the workspace base prompt by default (`customSystemPrompt: null` restores inheritance); `scope: global` manages shared settings. Use file tools for workspace/project rule paths, then `refresh` |
| `templates` | `read` returns paths and commands; edit files, then `refresh` |

Skills, packages and instructions accept `scope: workspace` (default) or `global`. MCP, local extension registrations and Agent settings use the existing shared settings. Use file tools for Skill, extension and template content, then refresh. Package resources stay in their installation and share Pi's parser; disable individual package skills or uninstall the owning package.

MCP `read` omits stored credential fields. Patch only the fields you need; headers, environment and OAuth maps merge with stored fields, and a null value removes that field. `nai_studio` is the built-in tool group; update its `enabled` or `exposure`, or enable/disable it.

Configuration changes share Settings persistence and current permission mode. Resource changes report `applies: next_turn`: they load at the next idle send in this same chat. A connection test only initializes and lists tools; it does not call a model or execute business tools. OAuth login opens the browser.

Pi's own documentation ships in `../../../node_modules/@earendil-works/pi-coding-agent/` relative to this reference: `README.md`, `docs/skills.md`, `docs/extensions.md`, `docs/packages.md`, `docs/mcp.md`, and `examples/extensions/`. Read the relevant native documentation when creating custom resources.
