#!/bin/bash
# Copy npm from the already verified official Node archive. No downloads here.
set -euo pipefail
runtime="$1"
agent="$2"
test -f "$runtime/lib/node_modules/npm/bin/npm-cli.js"
test -f "$runtime/lib/node_modules/npm/bin/npx-cli.js"
test -f "$runtime/lib/node_modules/npm/LICENSE"
mkdir -p "$agent"
cp -R "$runtime/lib/node_modules/npm" "$agent/npm-runtime"

# Use the adjacent universal Node even when Finder supplies only system PATH.
# Relative paths also let the app move after download without breaking npm/npx.
for tool_name in npm npx; do
  cat > "$agent/$tool_name" <<'SH'
#!/bin/sh
runtime_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
command_name=$(basename -- "$0")
exec "$runtime_dir/node" "$runtime_dir/npm-runtime/bin/$command_name-cli.js" "$@"
SH
  chmod 755 "$agent/$tool_name"
done
