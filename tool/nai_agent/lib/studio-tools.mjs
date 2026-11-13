import { Type } from 'typebox';
import { domainTools } from './domain-tools.mjs';

export function studioTools(execute, extraToolNames = []) {
  const tool = (name, description, parameters) => ({
    name, label: name, description, parameters,
    execute: (id, params, signal) => execute(name, id, params, signal),
  });
  return [
    tool('studio_context', 'Read current Studio state, including local search status and tool guidance. scope=draft returns RAW editable fields, pill documents and field_versions. Never write effective preset text back.',
      Type.Object({ scope: Type.Optional(Type.Unsafe({ type: 'string', enum: ['summary', 'draft'] })) })),
    tool('image_read', 'Read one actual canvas/history or library image by image_id (selected means current canvas selection; gallery:<ID> comes from gallery_query), or any image file using its workspace-relative path (including .W.O.F/attachments/ and .W.O.F/outputs/). metadata_only=true reads original dimensions and metadata locally without returning pixels or requiring vision. Default returns a separate visual copy and original metadata, without altering the original file or draft.',
      Type.Object({ image_id: Type.Optional(Type.String()), path: Type.Optional(Type.String()), metadata_only: Type.Optional(Type.Boolean()) })),
    tool('prompt_update', 'Patch draft fields read by studio_context(scope=draft); expected maps each changed field to its field_version (aliases: clear_characters->characters, seed_lock->seed, quality_toggle->quality_preset). Backs up, rechecks and returns readback. Lanes containing blocks only accept unchanged text (else pill_conflict): edit those with block_manage instance_*.',
      Type.Object({ changes: Type.Record(Type.String(), Type.Unknown()),
        expected: Type.Record(Type.String(), Type.String()) })),
    ...domainTools.filter(definition => extraToolNames.includes(definition.name))
      .map(definition => tool(definition.name, definition.description, definition.parameters)),
    ...(extraToolNames.includes('ask_user') ? [
      tool('ask_user', 'Ask one to three concise questions when inputs/preferences are missing. Options are optional and free text is always available. Wait for this tool result; do not repeat questions as queued chat or ask routine implementation approval.',
        Type.Object({ questions: Type.Array(Type.Object({
          id: Type.String(), question: Type.String(),
          options: Type.Optional(Type.Array(Type.String(), { maxItems: 8 })),
        }), { minItems: 1, maxItems: 3 }) })),
    ] : []),
  ];
}
