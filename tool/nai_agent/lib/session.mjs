import { mkdir, realpath } from 'node:fs/promises';
import { resolve, join, relative, isAbsolute } from 'node:path';
import { createAgentSession, createReadTool, DefaultResourceLoader, SessionManager, SettingsManager,
  createCodemodeExtension, createToolSearchExtension }
  from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { getCurrentSystemMessage } from '@earendil-works/pi-ai';
import { createStudioModelRuntime } from './model.mjs';
import { domainTools } from './domain-tools.mjs';
import { createNaiInteractionExtension } from './extensions/interaction.mjs';
import { createSessionHistoryExtension } from './extensions/session-history.mjs';
import { StudioCacheWarming } from './extensions/cache-warming.mjs';
import { createNaiPermissions } from './extensions/permissions.mjs';
import { createStudioExtensionUi } from './extensions/ui.mjs';
import { createStudioMcp, mcpRedactor, validateStudioMcp } from './mcp.mjs';
import { builtinSkillsDirectory, resolveStudioSkills } from './skills.mjs';
import { resolveStudioPromptTemplates } from './prompt-templates.mjs';
import { resolveWorkspaceReadPath } from './workspace-paths.mjs';

// Pi caches loader overrides on reload; Studio prompt edits apply on the next turn.
class StudioResourceLoader extends DefaultResourceLoader {
  constructor(options, currentPrompt) {
    super(options);
    this.currentPrompt = currentPrompt;
  }
  getSystemPrompt() { return this.currentPrompt(); }
}

export function studioTools(execute, extraToolNames = []) {
  const tool = (name, description, parameters) => ({
    name, label: name, description, parameters,
    execute: (id, params, signal) => execute(name, id, params, signal),
  });
  return [
    tool('studio_context', 'Read current Studio state on demand. scope=draft returns RAW editable fields, pill documents and field_versions. Never write effective preset text back.',
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

export async function createStudioSession({ config, cwd, agentDir, systemPrompt, executeTool,
  sessionDirectory, sessionFile, sessionName, acquireRequest, extraToolNames = [],
  extensionPaths = [], mcp = {}, skills = {}, prompts = {}, onSession, onExtensionUi, onExtensionError, onCacheWarmingChange, deferBinding = false }) {
  if (!systemPrompt?.trim()) throw new Error('NAI system prompt is required');
  const data = resolve(agentDir), sessions = resolve(sessionDirectory ?? join(data, 'sessions'));
  await Promise.all([resolve(cwd), data, sessions].map(path => mkdir(path, { recursive: true })));
  const root = await realpath(resolve(cwd));
  const sessionRoot = await realpath(sessions);
  let manager;
  if (sessionFile) {
    const path = await realpath(resolve(sessionFile));
    const inside = relative(sessionRoot, path);
    if (!inside || inside.startsWith('..') || isAbsolute(inside) || !inside.endsWith('.jsonl'))
      throw new Error('Session file leaves workspace sessions');
    manager = SessionManager.open(path, sessions);
    if (await realpath(manager.getCwd()) !== root) throw new Error('Session belongs to another workspace');
  } else manager = SessionManager.create(root, sessions);
  const restoredMcpTools = (getCurrentSystemMessage(manager.buildSessionContext().messages)?.toolsAdded ?? [])
    .map(tool => tool.name).filter(name => name.startsWith('mcp__'));
  validateStudioMcp(mcp);
  const redact = mcpRedactor(config, mcp);
  const permissions = createNaiPermissions({ cwd: root, mode: config.permissionMode ?? 'auto', labels: config.permissionLabels, redact });
  const { runtime, model } = await createStudioModelRuntime(config, { acquireRequest });
  let prompt = systemPrompt;
  const definitions = studioTools(executeTool, extraToolNames);
  const interactionTools = definitions.filter(tool => ['studio_context', 'ask_user'].includes(tool.name));
  const businessTools = definitions.filter(tool => !interactionTools.includes(tool));
  const names = ['read', 'write', 'edit', 'bash', 'codemode', ...interactionTools.map(tool => tool.name)];
  // Detailed tool usage lives in the built-in nai-studio skill; only the entry points stay here.
  const toolMap = ['Tool map:',
    '- Current Studio state: studio_context (scope=draft returns raw fields and field_versions).',
    '- Studio operations: codemode with namespace mcp__nai_studio. Read the nai-studio skill first.',
    '- Workspace files: read, write, edit, bash.',
    ...(extraToolNames.includes('ask_user') ? ['- Missing input/preferences: ask_user (direct tool, not from codemode).'] : []),
  ].join('\n');
  const skillSet = resolveStudioSkills({ builtinDirectory: skills.builtinDirectory ?? builtinSkillsDirectory,
    globalDirectory: skills.globalDirectory, workspaceDirectory: skills.workspaceDirectory,
    disabled: skills.disabled, modes: skills.modes });
  if (!Array.isArray(extensionPaths) || extensionPaths.length > 64
    || extensionPaths.some(path => typeof path !== 'string' || !isAbsolute(path)))
    throw new Error('Extensions must be explicitly selected local absolute paths');
  const settingsManager = SettingsManager.inMemory({
    retry: { enabled: (config.retryAttempts ?? 0) > 0, maxRetries: config.retryAttempts ?? 0 },
    images: { autoResize: false },
    cacheWarming: config.cacheWarming ?? 'streaming',
  });
  const cacheWarming = new StudioCacheWarming({ model, settingsManager, onChange: onCacheWarmingChange });
  const reserved = new Set([...definitions.map(tool => tool.name), '_nai_extension_ui', 'codemode', 'tool_search', 'session_history',
    'read', 'write', 'edit', 'bash', 'powershell', 'grep', 'find', 'ls']);
  function validateExtensions(extensions) {
    if (extensions.errors.length) throw new Error(extensions.errors.map(error => error.path + ': ' + error.error).join('\n'));
    for (const extension of extensions.extensions) {
      if (extension.path.startsWith('<inline:')) continue;
      for (const name of extension.tools.keys())
        if (reserved.has(name)) throw new Error('Extension cannot replace Studio tool: ' + name);
    }
    return extensions;
  }
  const templateSet = await resolveStudioPromptTemplates({ cwd: root, agentDir: data, ...prompts });
  const resourceLoader = new StudioResourceLoader({
    cwd: root, agentDir: data, settingsManager,
    noExtensions: true, noSkills: true, noPromptTemplates: true, noThemes: true, noContextFiles: true,
    additionalExtensionPaths: [...new Set(extensionPaths)],
    promptsOverride: () => ({ prompts: templateSet.prompts, diagnostics: templateSet.diagnostics }),
    // Studio resolves sources, overrides and switches; Pi formats the catalog and expands /skill:.
    skillsOverride: () => ({ skills: skillSet.active, diagnostics: [] }),
    extensionFactories: [cacheWarming.extension, createNaiInteractionExtension(interactionTools), createSessionHistoryExtension(redact),
      { name: 'nai-codemode', factory: createCodemodeExtension({ mode: 'on', models: false }) },
      { name: 'nai-tool-search', factory: createToolSearchExtension() },
      { name: 'nai-mcp', factory: createStudioMcp({ mcp, definitions: businessTools,
        execute: executeTool, agentDir: data, redact, restoredMcpTools,
        instructions: 'NAI Studio operations. Discover schemas on demand; observe real user confirmation and current versions. Usage guide: the nai-studio skill.' }) },
      permissions.extension,
    ],
    agentsFilesOverride: () => ({ agentsFiles: [] }),
    systemPromptOverride: () => prompt + '\n\n' + toolMap,
    appendSystemPromptOverride: () => [],
    extensionsOverride: validateExtensions,
  }, () => prompt + '\n\n' + toolMap);
  await resourceLoader.reload();
  const extensions = resourceLoader.getExtensions();
  settingsManager.applyOverrides({ defaultTools: [...new Set([...names,
    ...extensions.extensions.flatMap(extension => [...extension.tools.values()]
      .filter(tool => tool.definition.defaultActive !== false &&
        ['direct', 'model-only'].includes(tool.definition.exposure ?? 'direct'))
      .map(tool => tool.definition.name))])] });
  const read = createReadTool(root);
  const { session } = await createAgentSession({
    cwd: root, agentDir: data, model, modelRuntime: runtime, thinkingLevel: config.thinkingLevel ?? 'off',
    // Use official Pi tools and session persistence, not a second agent loop.
    sessionManager: manager,
    resourceLoader, settingsManager,
    customTools: [{...read, execute: async (id,args,...rest) =>
      read.execute(id,{...args,path:await resolveWorkspaceReadPath(root,args.path)},...rest)}],
  });
  cacheWarming.attach(session);
  const ui = createStudioExtensionUi(executeTool, onExtensionUi);
  let closed = false, binding;
  const bind = () => binding ??= session.bindExtensions({
    uiContext: ui.context, mode: 'rpc', onError: onExtensionError,
  });
  async function close() {
    if (closed) return;
    closed = true;
    ui.cancel(true);
    try {
      await session.abort();
      await binding?.catch(() => {});
      await session.extensionRunner.emit({ type: 'session_shutdown', reason: 'quit' });
    } finally { session.dispose(); }
  }
  onSession?.(session);
  if (!deferBinding) {
    try { await bind(); } catch (error) { await close(); throw error; }
  }
  if (sessionName && manager.getSessionName() !== sessionName) session.setSessionName(sessionName);
  return { session, manager, redact, model, cacheWarming, sessionDirectory: sessions,
    close, bind, cancelExtensionUi: () => ui.cancel(),
    setPermissionMode: permissions.setMode, getPermissionMode: permissions.getMode,
    contextWindowKnown: Number.isFinite(config.contextWindow) && config.contextWindow > 0,
    extensions: extensions.extensions.map(extension => ({ path: extension.path })),
    skills: skillSet.report,
    commands: templateSet.commands,
    setSystemPrompt(text) {
      if (!text?.trim()) throw new Error('NAI system prompt is required');
      prompt = text;
      session.setActiveToolsByName(session.getActiveToolNames());
    },
  };
}
