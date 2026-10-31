import { Type } from 'typebox';
import { join } from 'node:path';
import { builtinSkillsDirectory } from '../skills.mjs';

// One deferred host adapter. File content and package semantics stay native.
export function createAgentManagementExtension(execute, builtinDirectory = builtinSkillsDirectory) {
  return { name: 'nai-agent-management', factory(pi) {
    pi.registerTool({ name: 'agent_manage', label: 'Agent settings', exposure: 'deferred',
      description: 'Manage Pi itself: skills, extensions, packages, MCP servers, Agent settings, instructions and templates. read returns inventory, paths and editable fields. Use file tools for content, then refresh. Resource changes apply next idle send; current chat is retained. Usage: ' + join(builtinDirectory, 'nai-studio', 'references', 'self-management.md'),
      parameters: Type.Object({
        resource: Type.Unsafe({ type: 'string', enum: ['skills','extensions','packages','mcp','settings','instructions','templates'] }),
        action: Type.Optional(Type.String()),
        scope: Type.Optional(Type.Unsafe({ type: 'string', enum: ['workspace','global'] })),
        id: Type.Optional(Type.String()),
        name: Type.Optional(Type.String()),
        source: Type.Optional(Type.String()),
        expected_version: Type.Optional(Type.String()),
        changes: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
      }),
      execute: (id, params, signal) => execute('agent_manage', id, params, signal),
    });
  } };
}
