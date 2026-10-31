// Pi owns discovery, MCP connections and CodeMode. This adapter only serves
// Studio's existing executors over Pi's official in-process MCP transport.
import { randomUUID } from 'node:crypto';
import { join } from 'node:path';
import { createMcpExtension } from '@earendil-works/pi-coding-agent';
import { createInMemoryTransportPair } from '@earendil-works/pi-mcp/testing';
import { redactor } from './model.mjs';

// These adapter helpers are not re-exported at the SDK root (checked through 1.3.0).
// Keep this version-specific surface here; never copy Pi's connector or OAuth.
const sdkRoot = new URL('.', import.meta.resolve('@earendil-works/pi-coding-agent'));
const { validateMcpServerConfig } = await import(new URL('core/mcp-servers.js', sdkRoot));
const { createDefaultTransport, McpOAuthCredentialStore, McpServerConnection, signInMcpServer } =
  await import(new URL('extensions/mcp/runtime.js', sdkRoot));
const { FileAuthStorageBackend } = await import(new URL('core/auth-storage.js', sdkRoot));

// On-demand handshake/OAuth for the form and agent_manage; no Agent session.
export async function inspectStudioMcp({ name, config, cwd, agentDir, action = 'test', emit = () => {} }) {
  const { entries: [entry] } = validateStudioMcp({ mcpServers: { [name]: config } });
  const credentials = new McpOAuthCredentialStore(new FileAuthStorageBackend(join(agentDir, 'mcp-auth.json')), agentDir);
  const redact = mcpRedactor({}, { mcpServers: { [name]: config } });
  const connection = new McpServerConnection({ entry, cwd, createTransport: createDefaultTransport,
    credentials, onTools() {} });
  try {
    if (action === 'logout') {
      if (connection.oauthUrl) credentials.remove(name, connection.oauthUrl);
      return { name, state: 'disconnected', tools: 0 };
    }
    // The official connection owns discovery, auth challenges and timeouts.
    try { await connection.getClient(); }
    catch (error) { if (connection.state !== 'needs-auth') throw error; }
    if (action === 'login' && connection.state === 'needs-auth') {
      if (!connection.oauthUrl) throw new Error('This server does not support OAuth');
      await signInMcpServer({ serverUrl: connection.oauthUrl,
        store: credentials.forServer(name, connection.oauthUrl),
        settings: connection.oauthSettings(), challenge: connection.challenge,
        prompt: {
          showAuthorizationUrl(url) { emit({ event: 'oauth', url: url.href }); },
          promptForRedirectUrl(signal) { return new Promise(resolve =>
            signal.addEventListener('abort', () => resolve(undefined), { once: true })); },
        },
      });
      await connection.reconnect();
    }
    return { name, state: connection.state, tools: connection.tools.length,
      toolNames: connection.tools.map(t => t.name), error: connection.error };
  } catch (error) {
    return redact({ name, state: 'failed', tools: 0, error: error.message });
  } finally { await connection.close(); }
}

export function validateStudioMcp(raw = {}) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('Invalid MCP configuration');
  const servers = raw.mcpServers ?? {};
  if (!servers || typeof servers !== 'object' || Array.isArray(servers)) throw new Error('Invalid MCP servers');
  const seen = new Set(['nai_studio']);
  const entries = Object.entries(servers).map(([name, value]) => {
    const canonical = name.replaceAll('-', '_');
    if (seen.has(canonical)) throw new Error('Duplicate or reserved MCP server name: ' + name);
    seen.add(canonical);
    const config = validateMcpServerConfig(name, value);
    if (typeof config === 'string') throw new Error('MCP ' + name + ': ' + config);
    // Studio's provider credentials must not be selected by an MCP server.
    if (config.auth) throw new Error('MCP auth.provider is not available in Studio; use headers or OAuth');
    return { name, config, source: '<nai-mcp-settings>', scope: 'global' };
  });
  return { entries, builtinEnabled: raw.builtinEnabled !== false,
    builtinExposure: ['codemode', 'deferred', 'direct', 'hidden'].includes(raw.builtinExposure)
      ? raw.builtinExposure : 'codemode' };
}

export function mcpRedactor(config, mcp = {}) {
  const values = [];
  for (const server of Object.values(mcp.mcpServers ?? {})) {
    for (const value of [...Object.values(server.headers ?? {}),
      ...Object.entries(server.env ?? {}).filter(([key]) => /key|token|secret|password|cookie|auth/i.test(key)).map(([, v]) => v),
      server.oauth?.clientSecret]) {
      if (typeof value !== 'string' || !value) continue;
      values.push(value);
      if (/^Bearer\s+\S+/i.test(value)) values.push(value.replace(/^Bearer\s+/i, ''));
      const resolved = value.replace(/\$\{([^}]+)\}/g, (_, key) => process.env[key] ?? '');
      if (resolved) values.push(resolved);
    }
  }
  const secrets = new Set(values);
  let clean = redactor({ ...config, extraSecrets: [...secrets] });
  const redact = value => clean(value);
  redact.addSecrets = (...values) => {
    for (const value of values) if (typeof value === 'string' && value) {
      secrets.add(value);
      if (/^Bearer\s+\S+/i.test(value)) secrets.add(value.replace(/^Bearer\s+/i, ''));
    }
    clean = redactor({ ...config, extraSecrets: [...secrets] });
  };
  return redact;
}

function studioTransport(definitions, execute, redact, instructions) {
  const { client, server } = createInMemoryTransportPair();
  const calls = new Map(), prefix = randomUUID();
  const tools = new Map(definitions.map(tool => [tool.name, tool]));
  server.onClose(() => { for (const abort of calls.values()) abort.abort(); calls.clear(); });
  server.onMessage(message => {
    if (message.method === 'notifications/cancelled') {
      calls.get(message.params?.requestId)?.abort();
      return;
    }
    if (message.id === undefined) return;
    const abort = new AbortController();
    calls.set(message.id, abort);
    void (async () => {
      let result;
      switch (message.method) {
        case 'initialize':
          result = { protocolVersion: message.params.protocolVersion,
            capabilities: { tools: {} }, serverInfo: { name: 'NAI Studio', version: '1.0.0' }, instructions };
          break;
        case 'ping': result = {}; break;
        case 'tools/list':
          result = { tools: definitions.map(tool => ({ name: tool.name,
            description: tool.description, inputSchema: tool.parameters,
            outputSchema: { type: 'object', additionalProperties: true } })) };
          break;
        case 'tools/call': {
          const name = message.params?.name;
          if (!tools.has(name)) throw new Error('Unknown NAI Studio tool');
          try {
            const reply = await execute(name, prefix + '/' + message.id, message.params.arguments ?? {}, abort.signal);
            const structuredContent = reply.structuredContent ?? reply.details ?? {};
            result = { content: reply.content, structuredContent,
              ...(reply.isError || structuredContent.ok === false ? { isError: true } : {}) };
          } catch (error) {
            result = { content: [{ type: 'text', text: String(error) }],
              structuredContent: { error: String(error) }, isError: true };
          }
          break;
        }
        default:
          await server.send({ jsonrpc: '2.0', id: message.id,
            error: { code: -32601, message: 'Method not found' } });
          return;
      }
      await server.send(redact({ jsonrpc: '2.0', id: message.id, result }));
    })().catch(async error => {
      await server.send(redact({ jsonrpc: '2.0', id: message.id,
        error: { code: -32603, message: String(error) } })).catch(() => {});
    }).finally(() => calls.delete(message.id));
  });
  // start() sets its flag synchronously. No server process or listening port.
  void server.start();
  return client;
}

export function createStudioMcp({ mcp, definitions, execute, agentDir, instructions, redact, restoredMcpTools = [] }) {
  const { entries, builtinEnabled, builtinExposure } = validateStudioMcp(mcp);
  const builtin = { name: 'nai_studio', source: '<nai-studio>', scope: 'global', config: {
    url: 'http://nai-studio.invalid/mcp', enabled: builtinEnabled, exposure: builtinExposure, timeout: 86400,
    description: 'NAI Studio: prompts, blocks, wiki, images, history, references, generation and preferences.',
  } };
  const factory = createMcpExtension({
    loadConfig: () => ({ servers: [builtin, ...entries], errors: [], autoEnableCodemode: true }),
    credentials: new McpOAuthCredentialStore(new FileAuthStorageBackend(join(agentDir, 'mcp-auth.json')), agentDir),
    logPath: join(agentDir, 'mcp.log'),
    createTransport(entry, cwd, auth) {
      if (entry.name === 'nai_studio') return studioTransport(definitions, execute, redact, instructions);
      const authProvider = auth ? {
        token: async () => { const token = await auth.token(); redact.addSecrets(token); return token; },
        onUnauthorized: auth.onUnauthorized?.bind(auth),
      } : undefined;
      const transport = createDefaultTransport(entry, cwd, authProvider);
      redact.addSecrets(...Object.values(transport.options.headers ?? {}),
        ...Object.entries(transport.options.env ?? {})
          .filter(([key]) => /key|token|secret|password|cookie|auth/i.test(key)).map(([,value]) => value));
      const onMessage = transport.onMessage.bind(transport);
      transport.onMessage = listener => onMessage(message => listener(redact(message)));
      const sanitizeError = error => {
        if (error instanceof Error) error.message = redact({ text: error.message }).text;
        return error;
      };
      const onError = transport.onError.bind(transport);
      transport.onError = listener => onError(error => listener(sanitizeError(error)));
      if ('stderr' in transport) {
        const getter = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(transport), 'stderr')?.get;
        if (getter) Object.defineProperty(transport, 'stderr', {
          get: () => redact({ text: getter.call(transport) }).text,
        });
      }
      for (const method of ['start', 'send', 'close']) {
        const original = transport[method].bind(transport);
        transport[method] = async (...args) => {
          try { return await original(...args); }
          catch (error) { throw sanitizeError(error); }
        };
      }
      return transport;
    },
    // Settings are persisted by Studio, not a second mcp.json registry.
    updateConfig: () => { throw new Error('Use agent_manage to persist MCP changes in Studio settings'); },
  });
  // SDK createAgentSession starts with defaultTools, unlike the CLI's restored
  // loadout. Reapply names from Pi's canonical transcript when MCP registers
  // them; disabled/hidden tools stay unavailable and a later unload is respected.
  return pi => {
    const remaining = new Set(restoredMcpTools);
    return factory({ ...pi, registerTool(definition) {
      pi.registerTool(definition);
      if (remaining.delete(definition.name) && ['codemode', 'deferred'].includes(definition.exposure))
        pi.setActiveTools([...pi.getActiveTools(), definition.name]);
    } });
  };
}
