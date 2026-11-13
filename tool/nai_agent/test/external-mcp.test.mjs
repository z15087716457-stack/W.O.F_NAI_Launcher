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
  const list = await send({ jsonrpc:'2.0', id:2, method:'tools/list' });
  const native = studioTools(() => {}, [...domainTools.map(t => t.name), 'ask_user']);
  const business = list.result.tools.filter(t => !['studio_session', 'studio_skills'].includes(t.name));
  assert.deepEqual(business, JSON.parse(JSON.stringify(native.map(t => ({ name:t.name,description:t.description,inputSchema:t.parameters })))));
  assert.equal(business.length, 24);
  assert.ok(!business.some(t => ['read','write','edit','bash','agent_manage'].includes(t.name)));
}));
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
