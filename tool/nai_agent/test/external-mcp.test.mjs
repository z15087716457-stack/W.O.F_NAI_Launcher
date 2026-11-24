import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { once } from 'node:events';
import { studioTools } from '../lib/studio-tools.mjs';
import { domainTools } from '../lib/domain-tools.mjs';

async function fixture(run) {
  const child = spawn(process.execPath, ['external-mcp.mjs', '--discovery', '.runs/missing-external-discovery.json'], { stdio: ['pipe','pipe','pipe'] });
  const pending = [], queued = [];
  let stderr = '';
  child.stderr.setEncoding('utf8').on('data', value => { stderr += value; });
  const lines = createInterface({ input: child.stdout });
  lines.on('line', line => { const value = JSON.parse(line); if (pending.length) pending.shift()(value); else queued.push(value); });
  const next = () => queued.length ? Promise.resolve(queued.shift()) : new Promise(resolve => pending.push(resolve));
  const send = value => { child.stdin.write(JSON.stringify(value) + '\n'); return next(); };
  try { await run(send, child, next); }
  finally {
    child.stdin.end();
    const [code] = await once(child, 'exit');
    assert.equal(code, 0); assert.equal(stderr, ''); lines.close();
  }
}
test('stdio initialization and listing are offline and reuse exact internal schemas', async () => fixture(async send => {
  const init = await send({ jsonrpc:'2.0', id:1, method:'initialize', params:{ protocolVersion:'2025-11-25' } });
  assert.equal(init.result.protocolVersion, '2025-11-25');
  assert.deepEqual(init.result.capabilities, { tools:{}, resources:{} });
  assert.match(init.result.instructions, /^Use studio_session/);
  assert.doesNotMatch(init.result.instructions, /Enabled Studio skills/);
  const list = await send({ jsonrpc:'2.0', id:2, method:'tools/list' });
  const native = studioTools(() => {}, [...domainTools.map(t => t.name), 'ask_user']);
  const business = list.result.tools.filter(t => !['studio_session', 'studio_skills'].includes(t.name));
  assert.deepEqual(business, JSON.parse(JSON.stringify(native.map(t => ({ name:t.name,description:t.description,inputSchema:t.parameters })))));
  assert.equal(business.length, 25);
  assert.ok(business.some(tool => tool.name === 'online_gallery'));
  assert.ok(!business.some(t => ['read','write','edit','bash','agent_manage'].includes(t.name)));
}));
test('CLI help, list and schema run offline without entering MCP mode', async () => {
  const run = args => new Promise(resolve => {
    const child = spawn(process.execPath, ['external-mcp.mjs', ...args]);
    let out = '', err = '';
    child.stdout.setEncoding('utf8').on('data', value => { out += value; });
    child.stderr.setEncoding('utf8').on('data', value => { err += value; });
    child.on('exit', code => resolve({ code, out, err }));
    child.stdin.end();
  });
  const help = await run(['--help']);
  assert.equal(help.code, 0); assert.match(help.out, /--call TOOL/); assert.match(help.out, /builtin\/nai-studio/);
  const list = await run(['--list']);
  assert.equal(list.code, 0);
  const names = JSON.parse(list.out).map(t => t.name);
  assert.equal(names.length, 27); assert.ok(names.includes('prompt_set') && names.includes('studio_session'));
  const schema = JSON.parse((await run(['--schema', 'prompt_set'])).out);
  assert.equal(schema.name, 'prompt_set'); assert.equal(schema.inputSchema.type, 'object');
  assert.match(schema.description, /empty fields clear/);
  const missing = await run(['--schema', 'nope']);
  assert.equal(missing.code, 1); assert.match(missing.err, /--list/);
  const badTool = await run(['--session-file', 'nonexistent-session.json', '--call', 'nope']);
  assert.equal(badTool.code, 1); assert.match(badTool.err, /Unknown Studio tool/);
  const badArgs = await run(['--session-file', 'nonexistent-session.json', '--call', 'studio_skills', '--args', '{broken']);
  assert.equal(badArgs.code, 1); assert.ok(badArgs.err.trim().length > 0);
});
test('missing Studio connection is a visible tool error; unknown methods use JSON-RPC errors', async () => fixture(async send => {
  const value = await send({ jsonrpc:'2.0', id:3, method:'tools/call', params:{ name:'studio_context', arguments:{} } });
  assert.equal(value.result.isError,true); assert.match(value.result.content[0].text,/ENOENT/);
  const unknown = await send({ jsonrpc:'2.0', id:4, method:'not-a-method' });
  assert.equal(unknown.error.code,-32601);
}));
test('malformed input returns protocol errors and notifications do not corrupt stdout', async () => fixture(async (send, child, next) => {
  const invalid = await send(null); assert.equal(invalid.error.code,-32600);
  child.stdin.write('{broken\n'); assert.equal((await next()).error.code,-32700);
  child.stdin.write(JSON.stringify({jsonrpc:'2.0',method:'notifications/initialized'})+'\n');
  const pong = await send({jsonrpc:'2.0',id:5,method:'ping'}); assert.deepEqual(pong.result,{});
}));
test('session status and end work before a bridge connection exists', async () => fixture(async send => {
  for (const action of ['status','end']) {
    const response = await send({jsonrpc:'2.0',id:action,method:'tools/call',params:{name:'studio_session',arguments:{action}}});
    assert.deepEqual(JSON.parse(response.result.content[0].text),{connected:false});
  }
}));
