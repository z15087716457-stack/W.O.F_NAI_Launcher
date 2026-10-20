# Snapshots and preferences

## snapshot

`save` / `list` / `read` / `load` the complete generation configuration (default list `limit=20`). `load` restores prompts, images, characters, blocks, references and native image workflow settings; send `expected_version` from fresh `studio_context(scope=draft)`. It backs everything up first. Switching Agent workspaces never loads a snapshot automatically.

## settings_read / settings_update

Only the public preferences listed in `allowed_keys`. `settings_read` returns values, groups, `allowed_keys` and `version`; `settings_update(changes, expected_version)` validates native values, saves a workspace backup and refreshes Settings. Accounts, credentials, paths and model bindings are excluded; do not use file tools to bypass this boundary.
