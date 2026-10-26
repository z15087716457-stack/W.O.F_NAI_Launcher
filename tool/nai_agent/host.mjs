// Private JSONL stdin/stdout transport. Credentials never enter argv or Pi files.
import { createInterface } from 'node:readline';
import { createStudioSession } from './lib/session.mjs';
import { createTranslationSession } from './lib/translation-session.mjs';
import { publicModel } from './lib/model.mjs';
import { NextSuggestion } from './lib/next-suggestion.mjs';
import { mcpRedactor } from './lib/mcp.mjs';
import { SessionManager } from '@earendil-works/pi-coding-agent';

// Extension diagnostics cannot corrupt the private JSONL transport.
console.log = console.info = console.debug = (...values) => console.error(...values);

let session, workspaceId, redact = value => value, closing = false;
let initializing = false, suggestions;
let extensionsReady = Promise.resolve(), stopEpoch = 0;
let created, requestCount = 0, requestLimit = 32, permitSequence = 0;
const pending = new Map();
const permits = new Map();
let queued = [], activePromptId;
function publishQueue(consumedQueueIds = []) {
  const previous = queued.map(item => item.queueId);
  const queue = queueState();
  consumedQueueIds.push(...previous.filter(id => !queue.some(item => item.queueId === id)));
  send({ type: 'queue', queue, consumedQueueIds });
}
let mcpStatus = '', readingMcpStatus = false;
const send = value => process.stdout.write(JSON.stringify(redact({
  protocol: 1, workspaceId, sessionId: session?.sessionId, costKnown: false, ...value,
})) + '\n');
const fail = (id, code, message) => send({ type: 'error', id, code, message });

async function acquireRequest(signal) {
  signal?.throwIfAborted();
  if (++requestCount > requestLimit) throw new Error('Run request limit reached; progress is saved. Continue explicitly.');
  const requestId = String(++permitSequence);
  await new Promise((resolve, reject) => {
    const abort = () => {
      permits.delete(requestId);
      send({ type: 'request_cancel', requestId });
      reject(new Error('Model request cancelled while waiting'));
    };
    permits.set(requestId, { resolve, reject, signal, abort });
    signal?.addEventListener('abort', abort, { once: true });
    send({ type: 'request_permit', requestId });
  });
  let released = false;
  return () => {
    if (!released) { released = true; send({ type: 'request_release', requestId }); }
  };
}
function queueState() {
  // Pi owns the queues. This sidecar only retains attachment bytes and UI IDs.
  const consumed = {
    steer: queued.filter(item => item.behavior === 'steer').length - session.getSteeringMessages().length,
    followUp: queued.filter(item => item.behavior === 'followUp').length - session.getFollowUpMessages().length,
  };
  // Pi drains each behavior FIFO. Counts identify the consumed prefix even when
  // several entries have identical text or Pi decorates attachment content.
  queued = queued.filter(item => consumed[item.behavior]-- <= 0);
  return queued.map(({ images, ...item }) => ({ ...item, imageCount: images?.length ?? 0 }));
}
function usage() {
  const context = session.getContextUsage();
  return { cacheWarming: created.cacheWarming?.status ?? { mode: session.settingsManager.getCacheWarmingMode(), ...session.cacheWarmingStatus },
    stats: session.getSessionStats(), context: context ? { ...context, windowKnown: created.contextWindowKnown } : null };
}
function state() {
  return { messages: session.messages, sessionFile: session.sessionFile,
    historyMessages: created.manager.getBranch().flatMap(entry => entry.type === 'message'
      ? [entry.message] : entry.type === 'compaction'
        ? [{role:'compactionSummary', summary:entry.summary, tokensBefore:entry.tokensBefore, timestamp:Date.parse(entry.timestamp)}] : []),
    entries: created.manager.getBranch().filter(entry => entry.type === 'message')
      .map(entry => ({ id: entry.id, parentId: entry.parentId, role: entry.message.role, timestamp: entry.message.timestamp })),
    userMessages: session.getUserMessagesForForking(), queue: queueState(),
    streaming: session.isStreaming, permissionMode: created.getPermissionMode(), ...usage(),
    extensions: created.extensions, skills: created.skills, commands: created.commands ?? [], mcpStatus };
}
function requireIdle() {
  if (session.isStreaming || !session.isIdle) throw new Error('Wait for the current run or stop it first');
}

async function executeTool(name, toolCallId, params, signal) {
  signal?.throwIfAborted();
  return new Promise((resolve, reject) => {
    const abort = () => {
      pending.delete(toolCallId);
      send({ type: 'tool_cancel', toolCallId });
      reject(new Error('Studio tool cancelled'));
    };
    pending.set(toolCallId, { resolve, reject, signal, abort });
    signal?.addEventListener('abort', abort, { once: true });
    send({ type: 'tool_request', toolCallId, name, params });
  });
}

async function handle(message) {
  const { id, type } = message;
  if (message.protocol !== 1) throw new Error('Unsupported protocol');
  if (closing) return;
  if (type === 'init') {
    if (session || initializing || !message.workspaceId) throw new Error('Invalid initialization');
    initializing = true;
    workspaceId = message.workspaceId;
    redact = mcpRedactor(message.config, message.mcp);
    requestLimit = Math.max(1, Math.min(200, message.config.maxRequestsPerRun ?? 32));
    const create = message.sessionKind === 'translation' ? createTranslationSession : createStudioSession;
    created = await create({ ...message, executeTool, acquireRequest, deferBinding: true,
      onSession: value => { session = value; },
      onCacheWarmingChange: () => queueMicrotask(() => {
        if (!closing) send({ type: 'usage', ...usage() });
      }),
      onExtensionUi: event => {
        if (readingMcpStatus && event.method === 'notify' &&
            (event.level ?? 'info') === 'info') {
          mcpStatus = redact({ text: event.message }).text;
          return;
        }
        send({ type: 'extension_ui', ...event });
      },
      onExtensionError: error => send({ type: 'extension_error', path: error.extensionPath, message: error.error }),
    });
    session = created.session;
    initializing = false;
    redact = created.redact;
    if (message.sessionKind !== 'translation') suggestions = new NextSuggestion({ session, send,
      enabled: message.config.nextSuggestion !== false,
      onUsage: () => { if (!closing) send({ type: 'usage', ...usage() }); },
    });
    session.subscribe(event => {
      send({ type: 'event', event });
      if (event.type === 'agent_settled' && !event.aborted) {
        const epoch = suggestions?.epoch;
        queueMicrotask(() => { if (!closing && epoch === suggestions?.epoch) void suggestions?.generate(); });
      }
      if (event.type === 'message_start' && event.message.role === 'user') {
        const consumed = activePromptId ? [activePromptId] : [];
        activePromptId = undefined;
        publishQueue(consumed);
      }
      if (['message_end', 'compaction_end', 'agent_settled'].includes(event.type)
          || (event.type === 'entry_appended' && event.entry.type === 'usage'))
        queueMicrotask(() => {
          if (!closing) send({ type: 'usage', ...usage() });
        });
    });
    send({ type: 'ready', id, model: publicModel(message.config), ...state() });
    extensionsReady = created.bind();
    void extensionsReady.catch(error => send({ type: 'extension_error', message: error.message }));
    return;
  }
  if (!session || message.workspaceId !== workspaceId || message.sessionId !== session.sessionId)
    throw new Error('Session identity mismatch');
  if (type === 'permit_result') {
    const permit = permits.get(message.requestId);
    if (!permit) { if (!message.error) send({ type: 'request_release', requestId: message.requestId }); return; }
    permits.delete(message.requestId);
    permit.signal?.removeEventListener('abort', permit.abort);
    if (message.error) permit.reject(new Error('Model request permit cancelled'));
    else permit.resolve();
    return;
  }
  if (type === 'tool_result') {
    const call = pending.get(message.toolCallId);
    if (!call) return; // Late cancelled replies cannot affect another tool call.
    pending.delete(message.toolCallId);
    call.signal?.removeEventListener('abort', call.abort);
    if (message.error) call.reject(new Error(message.error.code + ': ' + message.error.message));
    else if (!Array.isArray(message.result?.content)) call.reject(new Error('Invalid Studio result'));
    else call.resolve(message.result);
    return;
  }
  switch (type) {
    case 'suggestion_cancel':
      suggestions?.invalidate(true); send({ type: 'response', id, forTurn: suggestions?.epoch }); break;
    case 'settings':
      if (message.nextSuggestion !== undefined) {
        if (typeof message.nextSuggestion !== 'boolean') throw new Error('Invalid suggestion setting');
        suggestions?.setEnabled(message.nextSuggestion);
      }
      if (message.cacheWarming !== undefined) {
        if (!['off', 'streaming', 'idle'].includes(message.cacheWarming)) throw new Error('Invalid cache warming mode');
        session.setCacheWarmingMode(message.cacheWarming);
      }
      send({ type: 'response', id, ...usage() });
      break;
    case 'permission_mode':
      if (!['auto', 'ask', 'readonly', 'bypass'].includes(message.mode)) throw new Error('Invalid permission mode');
      created.setPermissionMode(message.mode);
      send({ type: 'response', id, permissionMode: created.getPermissionMode() });
      break;
    case 'mcp_command': {
      requireIdle();
      await extensionsReady;
      const action = message.action ?? 'status';
      if (!['status', 'reconnect', 'login', 'logout'].includes(action)) throw new Error('Invalid MCP action');
      if (action !== 'status' && !/^[A-Za-z0-9_-]+$/.test(message.name ?? '')) throw new Error('Invalid MCP name');
      // Action feedback remains a notice; only the following status read is private.
      if (action !== 'status') await session.prompt('/mcp ' + action + ' ' + message.name);
      readingMcpStatus = true;
      try {
        await session.prompt('/mcp');
      } finally { readingMcpStatus = false; }
      send({ type: 'response', id, ...state() });
      break;
    }
    case 'system_prompt_get':
      send({ type: 'response', id, text: session.systemPrompt }); break;
    case 'prompt': {
      suggestions?.invalidate();
      const epoch = stopEpoch;
      await extensionsReady;
      if (epoch !== stopEpoch || closing) throw new Error('Stopped while preparing extensions');
      if (!session.isStreaming) { requestCount = 0; activePromptId = message.queueId ?? id; }
      else {
        queueState();
        queued.push({ queueId: message.queueId ?? id, text: message.text, images: message.images,
          behavior: message.behavior === 'steer' ? 'steer' : 'followUp' });
      }
      await session.prompt(message.text, {
        images: message.images,
        streamingBehavior: message.behavior === 'steer' ? 'steer' : 'followUp',
        expandPromptTemplates: true,
      });
      send({ type: 'response', id, ...state() });
      break;
    }
    case 'commands': send({ type: 'response', id, commands: created.commands ?? [] }); break;
    case 'state': send({ type: 'response', id, ...state() }); break;
    case 'session_list': {
      const sessions = await SessionManager.list(created.manager.getCwd(), created.sessionDirectory);
      send({ type: 'response', id, sessions: sessions.map(({ allMessagesText, ...item }) => item) });
      break;
    }
    case 'system_prompt':
      created.setSystemPrompt(message.text); send({ type: 'response', id }); break;
    case 'rename':
      session.setSessionName(message.name); send({ type: 'response', id }); break;
    case 'queue_edit': {
      queueState();
      const index = queued.findIndex(item => item.queueId === message.queueId);
      if (index < 0) throw new Error('Queued message already consumed');
      session.clearQueue();
      if (message.remove) queued.splice(index, 1);
      else queued[index] = { ...queued[index],
        text: message.text ?? queued[index].text,
        behavior: message.behavior === 'steer' ? 'steer' : queued[index].behavior };
      for (const item of queued) {
        if (item.behavior === 'steer') await session.steer(item.text, item.images);
        else await session.followUp(item.text, item.images);
      }
      publishQueue();
      send({ type: 'response', id, queue: queueState() }); break;
    }
    case 'navigate': {
      suggestions?.invalidate();
      await extensionsReady;
      requireIdle();
      const entry = created.manager.getEntry(message.entryId);
      if (entry?.type !== 'message' || entry.message.role !== 'user'
        || !created.manager.getBranch().some(item => item.id === entry.id)) throw new Error('Select a user message on the current branch to edit');
      const editorImages = Array.isArray(entry.message.content)
        ? entry.message.content.filter(part => part.type === 'image') : [];
      const navigation = await session.navigateTree(message.entryId, { summarize: false });
      // Pi treats navigating to the existing leaf as a no-op. A failed prompt
      // can leave a user entry as the leaf: editing it must still fork at parent.
      if (!navigation.cancelled && created.manager.getLeafId() === entry.id) {
        if (entry.parentId === null) created.manager.resetLeaf();
        else created.manager.branch(entry.parentId);
        session.refreshContext();
        navigation.editorText = typeof entry.message.content === 'string' ? entry.message.content
          : entry.message.content.filter(part => part.type === 'text').map(part => part.text).join('');
      }
      send({ type: 'response', id, ...navigation, editorImages, ...state() });
      break; }
    case 'compact':
      suggestions?.invalidate();
      requireIdle(); requestCount = 0;
      await session.compact(message.instructions);
      send({ type: 'response', id, ...state() }); break;
    case 'abort':
      suggestions?.invalidate();
      stopEpoch++;
      session.clearQueue(); queued = [];
      created.cancelExtensionUi();
      await session.abort(); send({ type: 'response', id, ...state() }); break;
    case 'shutdown':
      suggestions?.invalidate();
      stopEpoch++;
      closing = true;
      session.clearQueue(); queued = [];
      await created.close();
      send({ type: 'response', id });
      process.exitCode = 0;
      input.close();
      process.stdin.destroy();
      break;
    default: throw new Error('Unsupported command');
  }
}
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
input.on('line', line => {
  let message;
  try { message = JSON.parse(line); }
  catch { fail(null, 'invalid_json', 'Invalid JSONL message'); return; }
  // Tool answers and abort must run while the official prompt promise is active.
  void handle(message).catch(error =>
    fail(message.id, 'host_error', error instanceof Error ? error.message : 'Runtime failure'));
});
input.on('close', () => {
  if (!closing && session) {
    closing = true;
    suggestions?.invalidate();
    void (created ? created.close() : session.abort().finally(() => session.dispose()))
      .finally(() => { process.exitCode = 0; });
  }
});
