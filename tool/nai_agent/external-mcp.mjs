#!/usr/bin/env node
import { createInterface } from 'node:readline';
import { readFile, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { studioTools } from './lib/studio-tools.mjs';
import { domainTools } from './lib/domain-tools.mjs';
import { ExternalBridge } from './lib/external-bridge.mjs';

const argv = process.argv.slice(2);
const option = name => { const i = argv.indexOf(name); return i < 0 ? undefined : argv[i + 1]; };
const bridge = new ExternalBridge({ client: option('--client') ?? 'External Agent',
  discovery: option('--discovery'), workspace: option('--workspace') });
const definitions = studioTools(() => {}, [...domainTools.map(t => t.name), 'ask_user']);
const tools = [
  { name: 'studio_session', description: 'Start a logical Studio task (open), resume by session_id, inspect status, or end. Use summary for the user request, not hidden reasoning. The external host owns model inference. Start a new task after manually closing its panel if auto-reveal is wanted again.',
    inputSchema: { type: 'object', properties: { action: { type: 'string', enum: ['open','resume','status','end'] },
      session_id: { type: 'string' }, workspace_id: { type: 'string' }, summary: { type: 'string' } }, required: ['action'] } },
  { name: 'studio_skills', description: 'List enabled Studio skills with auto/manual mode, or read SKILL.md / a skill-relative reference. The host decides when to adopt each skill. Read the relevant skill before using Studio business tools.',
    inputSchema: { type: 'object', properties: { key: { type: 'string' }, path: { type: 'string' } } } },
  ...definitions.map(t => ({ name: t.name, description: t.description, inputSchema: t.parameters })),
];
const active = new Map();
const textResult = value => ({ content: [{ type: 'text', text: JSON.stringify(value) }] });
async function call(name, args, id, signal) {
  if (name === 'studio_session') {
    if (args.action === 'end') return textResult(await bridge.end());
    if (args.action === 'status') return textResult(bridge.session ?? { connected: false });
    if (!['open', 'resume'].includes(args.action) || args.action === 'resume' && !args.session_id) throw new Error('Invalid session action / missing session_id');
    if (active.size > 1) throw new Error('A Studio tool is still running');
    if (bridge.session) await bridge.end();
    return textResult(await bridge.open(args));
  }
  if (name === 'studio_skills') return textResult(await bridge.operation(args.key ? 'skill_read' : 'skills', args));
  if (!definitions.some(t => t.name === name)) throw new Error('Unknown Studio tool');
  return bridge.operation('call', { name, arguments: args }, id, signal);
}
async function dispatch(message) {
  const { id, method, params = {} } = message;
  if (method === 'notifications/cancelled') {
    const pending = active.get(params.requestId);
    if (pending) {
      pending.controller.abort();
      if (bridge.pending.has(pending.id)) await bridge.operation('cancel', { call_id: pending.id });
    }
    return;
  }
  if (id === undefined) return;
  const respond = result => process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result }) + '\n');
  try {
    switch (method) {
      case 'initialize':
        respond({ protocolVersion: '2025-11-25', capabilities: { tools: {}, resources: {} },
          serverInfo: { name: 'nai-studio', version: '1.0.0' },
          instructions: 'Use studio_session to label each logical task. List/read relevant studio_skills. Studio paid operations require the native user confirmation; never bypass it. Full conversation and inference remain in this external client.' }); return;
      case 'ping': respond({}); return;
      case 'tools/list': respond({ tools }); return;
      case 'tools/call': {
        const callId = randomUUID(), controller = new AbortController();
        active.set(id, { id: callId, controller });
        try { respond(await call(params.name, params.arguments ?? {}, callId, controller.signal)); }
        catch (error) { respond({ ...textResult({ error: error.message }), isError: true }); }
        finally { active.delete(id); }
        return;
      }
      case 'resources/list': {
        const { skills } = await bridge.operation('skills');
        respond({ resources: skills.map(s => ({ uri: `nai-skill:///${encodeURIComponent(s.key)}`,
          name: s.name, description: s.description, mimeType: 'text/markdown' })) }); return;
      }
      case 'resources/read': {
        const uri = new URL(params.uri);
        if (uri.protocol !== 'nai-skill:') throw new Error('Unsupported skill URI');
        const value = await bridge.operation('skill_read', { key: decodeURIComponent(uri.pathname.slice(1)),
          path: uri.searchParams.get('path') ?? undefined });
        respond({ contents: [{ uri: params.uri, mimeType: 'text/markdown', text: value.text }] }); return;
      }
      default: process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id,
        error: { code: -32601, message: 'Method not found' } }) + '\n');
    }
  } catch (error) {
    process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, error: { code: -32603, message: error.message } }) + '\n');
  }
}

if (option('--call')) {
  try {
    const sessionFile = option('--session-file');
    if (!sessionFile) throw new Error('--session-file is required for CLI calls');
    let session;
    try { session = JSON.parse(await readFile(sessionFile, 'utf8')); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    const opened = await bridge.open({ session_id: session?.session_id, workspace_id: session?.workspace_id,
      summary: option('--summary') });
    await writeFile(sessionFile, JSON.stringify({ session_id: opened.session_id,
      workspace_id: opened.workspace_id, client: opened.client }, null, 2) + '\n');
    const args = option('--args') ? JSON.parse(await readFile(option('--args'), 'utf8')) : {};
    process.stdout.write(JSON.stringify(await call(option('--call'), args, randomUUID())) + '\n');
  } catch (error) { process.stderr.write(error.message + '\n'); process.exitCode = 1; }
  finally { bridge.close(); }
} else {
  const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
  input.on('line', line => {
    let message;
    try { message = JSON.parse(line); }
    catch { process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null,
      error: { code: -32700, message: 'Parse error' } }) + '\n'); return; }
    if (message === null || typeof message !== 'object' || Array.isArray(message) ||
        message.jsonrpc !== '2.0' || typeof message.method !== 'string') {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: message?.id ?? null,
        error: { code: -32600, message: 'Invalid Request' } }) + '\n'); return;
    }
    void dispatch(message).catch(error => process.stderr.write(error.message + '\n'));
  });
  input.on('close', () => bridge.close());
}
