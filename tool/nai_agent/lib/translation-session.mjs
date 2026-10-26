import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createAgentSession, DefaultResourceLoader, SessionManager, SettingsManager } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { getCurrentSystemMessage } from '@earendil-works/pi-ai';
import { createStudioModelRuntime } from './model.mjs';
import { createStudioMcp, mcpRedactor } from './mcp.mjs';

// A separate loadout, not a permission prompt over the general Agent tools.
export async function createTranslationSession({ config, cwd, agentDir, systemPrompt,
  seedMessages = [], seedSystemPrompt, executeTool, acquireRequest, onSession,
  deferBinding = false, onExtensionError }) {
  if (!Array.isArray(seedMessages) || seedMessages.length % 2 || seedMessages.some((message, index) =>
    message.role !== (index % 2 ? 'assistant' : 'user') || typeof message.content !== 'string')) {
    throw new Error('Invalid translation seed messages');
  }
  const root = resolve(cwd), data = resolve(agentDir);
  await Promise.all([root, data].map(path => mkdir(path, { recursive: true })));
  const manager = SessionManager.inMemory(root);
  const { runtime, model } = await createStudioModelRuntime(config, { acquireRequest,
    // Pi normally folds cwd/tool updates into the leading system text. Keep the
    // original translation system/user/assistant prefix exact at the provider
    // boundary; adjustment instructions follow it, not precede it. Tool schemas
    // remain those of this restricted MCP loadout (cache policy is provider-owned).
    transformContext(context) {
      const system = getCurrentSystemMessage(context.messages);
      const messages = context.messages.filter(message => message.role !== 'system');
      return { ...context, messages: [
        { ...system, role: 'system', content: seedSystemPrompt ?? systemPrompt, sections: undefined },
        ...messages.slice(0, seedMessages.length),
        { role: 'user', content: systemPrompt, timestamp: Date.now() },
        ...messages.slice(seedMessages.length),
      ] };
    },
  });
  if (seedSystemPrompt) manager.appendMessage({ role: 'system', content: seedSystemPrompt, timestamp: Date.now() });
  for (const message of seedMessages) {
    manager.appendMessage(message.role === 'user'
      ? { ...message, timestamp: Date.now() }
      : { role: 'assistant', content: [{ type: 'text', text: message.content }],
        api: model.api, provider: model.provider, model: model.id, stopReason: 'stop',
        usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0,
          cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } }, timestamp: Date.now() });
  }
  const definitions = [
    { name: 'translation_blocks_read', description: 'Read this face translation blocks and current version.', parameters: Type.Object({}) },
    { name: 'translation_blocks_edit', description: 'One undoable batch on this face. Read first. Each operation includes scope and op. split: marker, parts [{source,translation}] whose sources concatenate EXACTLY to current source. merge: markers (arbitrary order, same scope and enabled state), explicit source order and translation; result at first document position. retranslate: marker, translation. rejoin: marker. Never change unrelated text.',
      parameters: Type.Object({ expected_version: Type.String(), operations: Type.Array(Type.Object({
        scope: Type.String(), op: Type.Union(['split', 'merge', 'retranslate', 'rejoin'].map(value => Type.Literal(value))),
        marker: Type.Optional(Type.String()), markers: Type.Optional(Type.Array(Type.String())),
        source: Type.Optional(Type.String()), translation: Type.Optional(Type.String()),
        parts: Type.Optional(Type.Array(Type.Object({ source: Type.String(), translation: Type.String() }))),
      }), { minItems: 1 }) }) },
  ];
  const mcp = { builtinExposure: 'direct' };
  const redact = mcpRedactor(config, mcp);
  const settingsManager = SettingsManager.inMemory({ defaultTools: [], retry: { enabled: false }, compaction: { enabled: false } });
  const resourceLoader = new DefaultResourceLoader({ cwd: root, agentDir: data, settingsManager,
    noExtensions: true, noSkills: true, noPromptTemplates: true, noThemes: true, noContextFiles: true,
    agentsFilesOverride: () => ({ agentsFiles: [] }),
    systemPromptOverride: () => systemPrompt, appendSystemPromptOverride: () => [],
    extensionFactories: [{ name: 'translation-mcp', factory: createStudioMcp({ mcp, definitions,
      execute: executeTool, agentDir: data, redact,
      instructions: 'Only edit the initiating translation face. Read versions before writing.' }) }],
  });
  await resourceLoader.reload();
  const { session } = await createAgentSession({ cwd: root, agentDir: data, model, modelRuntime: runtime,
    sessionManager: manager, settingsManager, resourceLoader, noTools: true,
    thinkingLevel: config.thinkingLevel ?? 'off' });
  onSession?.(session);
  let binding, closed = false;
  const bind = () => binding ??= session.bindExtensions({ mode: 'rpc', onError: onExtensionError });
  async function close() {
    if (closed) return;
    closed = true;
    try { await session.abort(); await binding; await session.extensionRunner.emit({ type: 'session_shutdown', reason: 'quit' }); }
    finally { session.dispose(); }
  }
  if (!deferBinding) { try { await bind(); } catch (error) { await close(); throw error; } }
  return { session, manager, model, redact, close, bind, sessionDirectory: data,
    getPermissionMode: () => 'auto', setPermissionMode: () => {}, cancelExtensionUi: () => {},
    contextWindowKnown: Number.isFinite(config.contextWindow), extensions: [], skills: [],
    setSystemPrompt: () => { throw new Error('Translation prompt is fixed'); } };
}
