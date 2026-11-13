// Cross-language business-policy probe. Never starts a session or calls a tool.
import { createNaiPermissions } from '../lib/extensions/permissions.mjs';
let input = ''; for await (const chunk of process.stdin) input += chunk;
const rows = JSON.parse(input), output = [];
for (const row of rows) {
  const allowed = {};
  for (const mode of ['readonly','ask','auto']) {
    const policy = createNaiPermissions({ cwd: process.cwd(), mode });
    let invoke;
    policy.extension.factory({ on(name, handler) { if (name === 'tool_call') invoke = handler; } });
    allowed[mode] = !(await invoke({ toolName: 'mcp__nai_studio__' + row.name, input: row.args }, { hasUI: false }))?.block;
  }
  output.push(allowed.readonly ? 'read' : allowed.ask ? 'confirmation' : allowed.auto ? 'edit' : 'danger');
}
process.stdout.write(JSON.stringify(output));
