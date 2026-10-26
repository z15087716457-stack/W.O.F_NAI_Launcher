import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtemp, rm, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { listenFetchTestServer } from './fixture-http.mjs';

export async function hostFixture({ config = {}, setup = async () => {}, respond } = {}) {
  const root = await mkdtemp(join(tmpdir(), 'studio-commands-'));
  const requests = [], responses = [], events = [], pending = new Map();
  const server = createServer(async (req, res) => {
    let body = ''; for await (const part of req) body += part;
    requests.push(JSON.parse(body)); responses.push(res);
    res.setHeader('Content-Type', 'text/event-stream');
    respond?.(res, requests.at(-1));
  });
  await listenFetchTestServer(server);
  const child = spawn(process.execPath, [fileURLToPath(new URL('../host.mjs', import.meta.url))],
    { stdio: ['pipe', 'pipe', 'pipe'] });
  let sessionId, seq = 0, diagnostic = '';
  child.stderr.on('data', data => { diagnostic += data; });
  const lines = createInterface({ input: child.stdout });
  const send = fields => child.stdin.write(JSON.stringify({ protocol: 1, workspaceId: 'fixture', sessionId, ...fields }) + '\n');
  lines.on('line', line => {
    const event = JSON.parse(line); events.push(event);
    if (event.type === 'ready') sessionId = event.sessionId;
    if (event.type === 'request_permit') send({ type: 'permit_result', requestId: event.requestId });
    if (['ready', 'response', 'error'].includes(event.type) && pending.has(event.id)) {
      const p = pending.get(event.id); pending.delete(event.id); clearTimeout(p.timer);
      event.type === 'error' ? p.reject(new Error(event.message)) : p.resolve(event);
    }
  });
  const request = (type, fields = {}) => new Promise((resolve, reject) => {
    const id = String(++seq);
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('Timeout: ' + type + '\n' + diagnostic)); }, 60000);
    pending.set(id, { resolve, reject, timer }); send({ id, type, ...fields });
  });
  const close = async () => {
    try { if (sessionId && child.exitCode === null) await request('shutdown'); }
    finally {
      child.kill(); lines.close(); for (const p of pending.values()) clearTimeout(p.timer);
      server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
      await rm(root, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    }
  };
  try {
    await setup(root, { mkdir, writeFile, join });
    const ready = await request('init', { cwd: join(root, 'workspace'), agentDir: join(root, 'agent'),
      systemPrompt: 'Synthetic Studio test; do not call real services.',
      config: { providerId: 'test', modelId: 'test', protocol: 'openaiChatCompletions', tools: true,
        baseUrl: 'http://127.0.0.1:' + server.address().port, ...config } });
    return { root, ready, requests, responses, events, request, close,
      async wait(predicate) {
        for (let i = 0; i < 1000; i++) { if (predicate()) return; await new Promise(resolve => setTimeout(resolve, 10)); }
        throw new Error('Timeout waiting for event: ' + diagnostic);
      },
    };
  } catch (error) { await close(); throw error; }
}

export function finishReply(res, text = 'done') {
  res.end('data: ' + JSON.stringify({ id: 'test', object: 'chat.completion.chunk', model: 'test',
    choices: [{ index: 0, delta: { role: 'assistant', content: text }, finish_reason: 'stop' }],
    usage: { prompt_tokens: 32, completion_tokens: 4, total_tokens: 36 },
  }) + '\n\ndata: [DONE]\n\n');
}
