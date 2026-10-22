// Session-scoped Studio integration. Business operations stay in their own group.
const studioResultsMaxBytes = 64 * 1024;
const chipKeys = ['tags', 'pages', 'items'];
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const pick = (value, keys) => Object.fromEntries(keys
  .filter(key => value?.[key] !== undefined).map(key => [key, value[key]]));
const isBinary = value => /^data:[^,]*;base64,/i.test(value) ||
  (value.length >= 256 && /^[A-Za-z0-9+/]+={0,2}$/.test(value));
const short = value => typeof value === 'string' && !isBinary(value)
  ? [...value].slice(0, 200).join('') : undefined;
const rows = value => Array.isArray(value) ? value.filter(isObject).slice(0, 24) : [];

// Allowlisted projections still pass through binary redaction: never persist an
// image payload accidentally placed in a metadata string or nested draft field.
function withoutBinary(value) {
  if (typeof value === 'string') return isBinary(value) ? undefined : value;
  if (Array.isArray(value)) return value.map(withoutBinary).filter(item => item !== undefined);
  if (isObject(value)) return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !['data', 'bytes', 'base64', 'image_base64', 'imageBytes', 'image', 'image_data',
      '__proto__', 'constructor', 'prototype'].includes(key))
    .map(([key, item]) => [key, withoutBinary(item)]).filter(([, item]) => item !== undefined));
  return value;
}

function studioProjection(event, native) {
  const tool = event.toolName.replace(/^mcp__nai_studio__/, '');
  const identity = { tool: event.toolName, tool_call_id: event.toolCallId };
  if (native.ok === false || event.isError) return { ...identity, ok: false };
  let projection;
  if (tool === 'tag_query') projection = { tags: rows(native.tags).map(row => ({
    ...pick(row, ['tag', 'category', 'post_count', 'zh', 'translation']), definition: short(row.definition),
  })) };
  else if (tool === 'wiki_query') projection = { pages: rows(native.pages).map(row => ({
    ...pick(row, ['tag', 'found']), body: short(row.body),
  })) };
  else if (tool === 'studio_search') projection = { items: rows(native.items)
    .map(row => pick(row, ['name', 'category', 'post_count', 'translation'])) };
  else if (tool === 'settings_update') {
    const fields = Array.isArray(native.applied_fields) ? native.applied_fields.filter(key => typeof key === 'string') : [];
    projection = { ...pick(native, ['ok', 'version']), applied_fields: fields,
      before: pick(native.before, fields), values: pick(native.values, fields) };
  } else if (tool === 'gallery_manage') {
    projection = pick(native, ['ok', 'action', 'scope', 'unchanged', 'image_id', 'image_ids',
      'image_version', 'image_versions', 'collection_id', 'collection_name', 'collection_version',
      'source_path', 'source_paths', 'target_folder', 'file_path', 'file_paths', 'unchanged_ids', 'target', 'count']);
    // Pi's calls[].args is only a truncated string preview, not safe undo input.
    projection.arguments = pick(event.input, ['action', 'changes', 'image_id', 'image_ids', 'target_folder']);
    const beforeFields = ['favorite', 'tags', 'collection_ids'];
    if (isObject(native.before)) projection.before =
      ['collection_add', 'collection_remove'].includes(event.input?.action ?? native.action)
        ? Object.fromEntries(Object.entries(native.before).map(([id, before]) => [id, pick(before, beforeFields)]))
        : pick(native.before, beforeFields);
    if (isObject(native.backup)) projection.backup = pick(native.backup, ['path', 'file_missing']);
  } else if (tool === 'prompt_update') projection = pick(native, ['ok', 'applied', 'backup_path', 'draft']);
  if (Array.isArray(native.artifacts)) projection = { ...projection,
    artifacts: native.artifacts.map(artifact => pick(artifact, ['type', 'path', 'image_id'])),
    ...pick(native, ['image_ids', 'estimated_anlas']) };
  if (!projection) return undefined;
  const result = { ...identity, ...projection };
  const sanitized = withoutBinary(result);
  // Removing part of an undo snapshot could restore the wrong state. A change
  // projection containing binary is omitted atomically instead of half-kept.
  if (!['tag_query', 'wiki_query', 'studio_search'].includes(tool) &&
      JSON.stringify(sanitized) !== JSON.stringify(result)) return undefined;
  return sanitized;
}

// Bound the *serialized UTF-8* addition, including its key. Drop read-only chip
// rows before guarded changes; never truncate an undo snapshot into a partial one.
function boundedStudioResults(results) {
  const size = () => Buffer.byteLength(JSON.stringify({ studio_results: results }), 'utf8');
  while (size() > studioResultsMaxBytes) {
    const chip = results.findLast(result => chipKeys.some(key => result[key]?.length));
    if (chip) {
      chip[chipKeys.find(key => chip[key]?.length)].pop();
    } else results.pop();
  }
  return results;
}
export function createNaiInteractionExtension(definitions) {
  return {
    name: 'nai-interaction',
    factory(pi) {
      const artifacts = new Map();
      const studioResults = new Map();
      pi.on('agent_start', () => { artifacts.clear(); studioResults.clear(); });
      pi.on('tool_result', event => {
        if (event.toolName.startsWith('mcp__nai_studio__')) {
          const native = event.structuredContent?.structuredContent;
          if (!native || typeof native !== 'object' || Array.isArray(native)) return;
          if (event.parentToolCallId && Array.isArray(native.artifacts)) {
            const previous = artifacts.get(event.parentToolCallId) ?? [];
            artifacts.set(event.parentToolCallId, [...previous, ...native.artifacts]);
          }
          // CodeMode does not persist nested results. Keep slim UI projections
          // only in session details, never in content sent back to the model.
          if (event.parentToolCallId) {
            const projection = studioProjection(event, native);
            if (projection) {
              const previous = studioResults.get(event.parentToolCallId) ?? [];
              studioResults.set(event.parentToolCallId, boundedStudioResults([
                ...previous.filter(result => result.tool_call_id !== event.toolCallId), projection,
              ]));
            }
          }
          // Official Pi persists details, but not structuredContent. Retain the
          // original Studio result for restored cards and local image previews.
          return { details: { ...event.details, ...native } };
        }
        if (event.toolName === 'codemode') {
          const images = artifacts.get(event.toolCallId);
          artifacts.delete(event.toolCallId);
          const results = studioResults.get(event.toolCallId);
          studioResults.delete(event.toolCallId);
          if (images?.length || results?.length) return { details: { ...event.details,
            ...(images?.length ? { artifacts: images } : {}),
            ...(results?.length ? { studio_results: results } : {}),
          } };
        }
      });
      for (const definition of definitions) {
        pi.registerTool({ ...definition,
          ...(definition.name === 'ask_user'
            ? { exposure: 'model-only', executionMode: 'sequential' } : {}),
        });
      }
    },
  };
}
