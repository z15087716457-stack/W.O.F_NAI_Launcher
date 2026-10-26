import { createProvider, createModels, lazyStream } from '@earendil-works/pi-ai';
import { ModelRuntime } from '@earendil-works/pi-coding-agent';
import { createAssistantMessageEventStream } from '@earendil-works/pi-ai/utils/event-stream';

const adapters = {
  openaiChatCompletions: ['openai-completions', async () =>
    (await import('@earendil-works/pi-ai/api/openai-completions.lazy')).openAICompletionsApi()],
  ollamaChatCompletions: ['openai-completions', async () =>
    (await import('@earendil-works/pi-ai/api/openai-completions.lazy')).openAICompletionsApi()],
  openaiResponses: ['openai-responses', async () =>
    (await import('@earendil-works/pi-ai/api/openai-responses.lazy')).openAIResponsesApi()],
  anthropicMessages: ['anthropic-messages', async () =>
    (await import('@earendil-works/pi-ai/api/anthropic-messages.lazy')).anthropicMessagesApi()],
  geminiGenerateContent: ['google-generative-ai', async () =>
    (await import('@earendil-works/pi-ai/api/google-generative-ai.lazy')).googleGenerativeAIApi()],
};
const protectedFields = new Set(['messages', 'input', 'system', 'tools', 'tool_choice',
  'contents', 'systemInstruction', 'toolConfig', 'instructions', 'previous_response_id']);

export function endpointRoot(baseUrl, protocol) {
  const url = new URL(baseUrl);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password ||
      url.search || url.hash) throw new Error('Unsupported provider URL');
  let path = url.pathname.replace(/\/+$/, '');
  if (protocol === 'geminiGenerateContent') {
    if (!/\/v1(beta)?$/.test(path)) path += '/v1beta';
  } else {
    const suffix = protocol === 'openaiResponses' ? '/responses'
      : protocol === 'anthropicMessages' ? '/messages' : '/chat/completions';
    if (path.endsWith(suffix)) path = path.slice(0, -suffix.length);
    if (!path.endsWith('/v1')) path += '/v1';
    // Anthropic SDK itself adds /v1/messages.
    if (protocol === 'anthropicMessages') path = path.slice(0, -3);
  }
  return url.origin + path;
}

export function mergeObjects(base, patch) {
  const result = { ...base };
  for (const [key, value] of Object.entries(patch ?? {})) {
    if (['__proto__', 'constructor', 'prototype'].includes(key)) throw new Error('Invalid request field');
    result[key] = value && typeof value === 'object' && !Array.isArray(value) &&
      base[key] && typeof base[key] === 'object' && !Array.isArray(base[key])
      ? mergeObjects(base[key], value) : value;
  }
  return result;
}

export function requestPatch(config) {
  const body = { ...config.body };
  for (const key of Object.keys(body)) {
    if (protectedFields.has(key)) throw new Error('Agent protocol field cannot be overridden: ' + key);
  }
  if ('model' in body && body.model !== config.modelId) throw new Error('Model override does not match selection');
  delete body.model;
  // Existing Studio overrides are for non-streaming requests; Pi always streams.
  if ('stream' in body && body.stream !== false && body.stream !== true)
    throw new Error('Invalid stream override');
  delete body.stream;
  if (config.allowsSampling === false &&
      ('temperature' in body || 'top_p' in body ||
       body.generationConfig?.temperature !== undefined || body.generationConfig?.topP !== undefined)) {
    throw new Error('Sampling parameters are disabled for this model');
  }
  const patch = mergeObjects(config.payloadParameters ?? {}, body);
  if (config.protocol === 'geminiGenerateContent') {
    // Pi's Google adapter exposes the Google SDK payload (contents + config),
    // whereas Studio saves REST generationConfig/safetySettings fields.
    const allowed = new Set(['generationConfig', 'safetySettings', 'cachedContent']);
    for (const key of Object.keys(patch)) {
      if (!allowed.has(key)) throw new Error('Unsupported Gemini Agent override: ' + key);
    }
    for (const key of Object.keys(patch.generationConfig ?? {})) {
      if (protectedFields.has(key)) throw new Error('Agent protocol field cannot be overridden: ' + key);
    }
    return { config: { ...patch.generationConfig,
      ...('safetySettings' in patch ? { safetySettings: patch.safetySettings } : {}),
      ...('cachedContent' in patch ? { cachedContent: patch.cachedContent } : {}) } };
  }
  return patch;
}

export function publicModel(config) {
  return {
    providerId: config.providerId, modelId: config.modelId, protocol: config.protocol,
    vision: config.vision ?? null, tools: config.tools ?? null,
    contextWindow: config.contextWindow ?? null, maxTokens: config.maxTokens ?? null,
    costKnown: false,
  };
}

export function redactor(config) {
  const secrets = [config.apiKey, ...(config.extraSecrets ?? []), ...Object.entries(config.headers ?? {})
    .filter(([key]) => /authorization|api.?key|token|cookie|secret/i.test(key))
    .map(([, value]) => value)].filter(value => typeof value === 'string' && value.length);
  return value => {
    let json = JSON.stringify(value);
    for (const secret of secrets) json = json.split(JSON.stringify(secret).slice(1, -1)).join('[redacted]');
    return JSON.parse(json);
  };
}

export async function createStudioModelRuntime(config, { acquireRequest, transformContext } = {}) {
  const spec = adapters[config.protocol];
  if (!spec || !config.modelId?.trim() || !config.providerId?.trim())
    throw new Error('Missing model or unsupported protocol');
  if (config.tools === false) throw new Error('Selected model does not support tools');
  const patch = requestPatch(config);
  const sanitize = redactor(config);
  const id = 'studio/' + config.providerId;
  const model = {
    id: config.modelId, name: config.displayName ?? config.modelId, provider: id,
    api: spec[0], baseUrl: endpointRoot(config.baseUrl, config.protocol),
    input: config.vision === true ? ['text', 'image'] : ['text'],
    reasoning: config.reasoning === true,
    // Explicit, visible fallbacks when the saved model/catalog has no limits.
    contextWindow: config.contextWindow ?? 32768, maxTokens: config.maxTokens ?? 4096,
    // CPA/custom-provider billing is not established by the upstream model catalog.
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    promptCache: { short: Number.isInteger(config.promptCacheSeconds) && config.promptCacheSeconds > 0
      ? config.promptCacheSeconds : 300 },
    headers: config.headers ?? {},
  };
  const wrap = method => (current, context, options = {}) => lazyStream(current, async () => {
    if (config.vision !== true && context.messages.some(message =>
      Array.isArray(message.content) && message.content.some(part => part.type === 'image'))) {
      throw new Error('Image input is not enabled for this model');
    }
    const adapter = await spec[1]();
    const { studioSuggestion = false, ...providerOptions } = options;
    options = providerOptions;
    options.signal?.throwIfAborted();
    // The host shares Studio's provider gate. Waiting for a slot is cancellable
    // and does not consume the HTTP timeout or start a provider request.
    const release = await acquireRequest?.(options.signal);
    const timeout = new AbortController();
    const timer = setTimeout(() => timeout.abort(new Error('Provider request timed out')),
      (config.timeoutSeconds ?? 120) * 1000);
    const signal = options.signal ? AbortSignal.any([options.signal, timeout.signal]) : timeout.signal;
    try {
      const stream = adapter[method](current, transformContext ? transformContext(context) : context, {
        ...options, apiKey: config.apiKey || 'studio-header-auth', signal,
        maxTokens: Math.min(options.maxTokens ?? model.maxTokens, model.maxTokens),
        ...(config.allowsSampling === false ? { temperature: undefined }
          : config.temperature == null ? {} : { temperature: config.temperature }),
        headers: { ...options.headers, ...config.headers },
        onPayload: async payload => {
          const previous = await options.onPayload?.(payload, current) ?? payload;
          const result = mergeObjects(previous, patch);
          if (spec[0].startsWith('openai') || spec[0] === 'anthropic-messages') result.stream = true;
          // Explicit compaction budgets must survive saved general output overrides.
          if (options.maxTokens != null) {
            for (const key of ['max_tokens', 'max_completion_tokens', 'max_output_tokens']) {
              if (typeof result[key] === 'number') result[key] = Math.min(result[key], options.maxTokens);
            }
            if (typeof result.config?.maxOutputTokens === 'number')
              result.config.maxOutputTokens = Math.min(result.config.maxOutputTokens, options.maxTokens);
          }
          if (studioSuggestion) {
            // Keep the cached tool declarations in the prefix, but forbid calling them.
            if (spec[0] === 'google-generative-ai') {
              result.config ??= {};
              result.config.toolConfig = { functionCallingConfig: { mode: 'NONE' } };
              if (result.config.thinkingConfig) result.config.thinkingConfig = 'thinkingLevel' in result.config.thinkingConfig
                ? { thinkingLevel: 'MINIMAL' } : { thinkingBudget: 0 };
            } else {
              result.tool_choice = spec[0] === 'anthropic-messages' ? { type: 'none' } : 'none';
              if (spec[0] === 'anthropic-messages' || 'thinking' in result) result.thinking = { type: 'disabled' };
              if (result.output_config?.effort) result.output_config = { ...result.output_config, effort: 'low' };
              if ('reasoning_effort' in result) result.reasoning_effort = 'low';
              if (result.reasoning?.effort) result.reasoning = { ...result.reasoning, effort: 'low' };
              if ('enable_thinking' in result) result.enable_thinking = false;
            }
          }
          return result;
        },
      });
      // Provider error bodies can echo credentials. Sanitize terminal errors
      // before Pi persists them, not just after they reach the UI transport.
      const output = createAssistantMessageEventStream();
      void (async () => {
        try {
          for await (const event of stream) output.push(event.type === 'error' ? sanitize(event) : event);
          output.end();
        } finally { clearTimeout(timer); release?.(); }
      })().catch(error => {
        const message = {
          role: 'assistant', content: [], api: current.api, provider: current.provider,
          model: current.id, stopReason: 'error', timestamp: Date.now(),
          errorMessage: sanitize({ text: String(error) }).text,
          usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0,
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
        };
        output.push({ type: 'error', reason: 'error', error: message }); output.end();
      });
      return output;
    } catch (error) {
      clearTimeout(timer);
      release?.();
      throw error;
    }
  });
  const native = createProvider({
    id, models: [model],
    auth: { apiKey: { name: 'Studio', resolve: async () => ({
      // Pi requires an auth record even for a header-auth/local endpoint.
      // The adapter's explicit Studio headers still take precedence.
      auth: { apiKey: config.apiKey || 'studio-header-auth' },
    }) } },
    api: { stream: wrap('stream'), streamSimple: wrap('streamSimple') },
  });
  const credentials = {
    read: async providerId => providerId === id && config.apiKey
      ? { type: 'api_key', key: config.apiKey } : undefined,
    list: async () => [], modify: async () => { throw new Error('Studio owns credentials'); },
    delete: async () => { throw new Error('Studio owns credentials'); },
  };
  const runtime = await ModelRuntime.create({ credentials, modelsPath: null,
    refreshOnCreate: false, allowModelNetwork: false });
  // Deliberate production isolation: Studio is the sole configuration/credential
  // owner. Do not discover Pi's user files, environment keys or network catalogs.
  runtime.models = createModels({ credentials: runtime.credentials,
    authContext: { env: async () => undefined, fileExists: async () => false } });
  runtime.registerNativeProvider(native);
  await runtime.refresh({ providers: [id], allowNetwork: false });
  return { runtime, model, redact: redactor(config) };
}
