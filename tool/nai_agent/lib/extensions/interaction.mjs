// Session-scoped Studio integration. Business operations stay in their own group.
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
          // CodeMode's nested call log deliberately omits native results. Keep
          // only the UI projections needed for guarded diffs / artifact billing
          // in session details, never in the content sent back to the model.
          if (event.parentToolCallId &&
              (event.toolName === 'mcp__nai_studio__prompt_update' || Array.isArray(native.artifacts))) {
            const previous = studioResults.get(event.parentToolCallId) ?? [];
            studioResults.set(event.parentToolCallId, [...previous, {
              tool: event.toolName, tool_call_id: event.toolCallId,
              ...(event.toolName === 'mcp__nai_studio__prompt_update'
                ? native
                : { artifacts: native.artifacts, image_ids: native.image_ids,
                    estimated_anlas: native.estimated_anlas }),
            }]);
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
