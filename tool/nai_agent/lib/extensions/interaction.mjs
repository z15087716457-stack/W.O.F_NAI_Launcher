// Session-scoped Studio integration. Business operations stay in their own group.
export function createNaiInteractionExtension(definitions) {
  return {
    name: 'nai-interaction',
    factory(pi) {
      const artifacts = new Map();
      pi.on('agent_start', () => artifacts.clear());
      pi.on('tool_result', event => {
        if (event.toolName.startsWith('mcp__nai_studio__')) {
          const native = event.structuredContent?.structuredContent;
          if (!native || typeof native !== 'object' || Array.isArray(native)) return;
          if (event.parentToolCallId && Array.isArray(native.artifacts)) {
            const previous = artifacts.get(event.parentToolCallId) ?? [];
            artifacts.set(event.parentToolCallId, [...previous, ...native.artifacts]);
          }
          // Official Pi persists details, but not structuredContent. Retain the
          // original Studio result for restored cards and local image previews.
          return { details: { ...event.details, ...native } };
        }
        if (event.toolName === 'codemode') {
          const images = artifacts.get(event.toolCallId);
          artifacts.delete(event.toolCallId);
          if (images?.length) return { details: { ...event.details, artifacts: images } };
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
