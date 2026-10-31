import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { hostFixture, finishReply } from './fixture-host.mjs';
import { NextSuggestion } from '../lib/next-suggestion.mjs';

test('cache warming defaults to streaming; init and live changes reach Pi', async () => {
  const f = await hostFixture();
  try {
    assert.equal(f.ready.cacheWarming.mode, 'streaming');
    assert.equal(f.ready.cacheWarming.state, 'inactive');
    for (const mode of ['off', 'idle', 'streaming']) {
      const result = await f.request('settings', { cacheWarming: mode });
      assert.equal(result.cacheWarming.mode, mode);
      if (mode === 'off') assert.match(result.cacheWarming.reason, /disabled/);
    }
    await assert.rejects(f.request('settings', { cacheWarming: 'bad' }), /Invalid/);
    const started = Date.now();
    const run = f.request('prompt', { text: 'stay streaming' });
    await f.wait(() => f.requests.length === 1);
    const running = await f.request('state');
    assert.equal(running.streaming, true);
    assert.equal(running.cacheWarming.state, 'scheduled');
    assert.equal(running.cacheWarming.ttlSeconds, 300);
    assert.ok(running.cacheWarming.nextWarmAt >= started + 270000);
    assert.ok(running.cacheWarming.nextWarmAt <= Date.now() + 270000);
    assert.equal((await f.request('settings', { cacheWarming: 'off' })).cacheWarming.mode, 'off');
    await f.request('abort'); await run;
  } finally { await f.close(); }
  const off = await hostFixture({ config: { cacheWarming: 'off' } });
  try { assert.match(off.ready.cacheWarming.reason, /disabled/); } finally { await off.close(); }
});

test('host lists only explicit templates, workspace overrides global, arguments expand before model', async () => {
  const f = await hostFixture({ config: { nextSuggestion: false }, respond: finishReply,
    setup: async (root, { mkdir, writeFile, join }) => {
      for (const path of ['agent/prompts', 'workspace/.W.O.F/prompts', 'workspace/.pi', 'other/prompts']) await mkdir(join(root, path), { recursive: true });
      await writeFile(join(root, 'agent/prompts/global.md'), '---\ndescription: Global\nargument-hint: "<subject>"\n---\nGlobal $1');
      await writeFile(join(root, 'agent/prompts/review.md'), 'Global shadowed');
      await writeFile(join(root, 'workspace/.W.O.F/prompts/review.md'), '---\ndescription: Review it\nargument-hint: "[focus]"\n---\nReview $@');
      await writeFile(join(root, 'other/prompts/ambient.md'), 'Do not load');
      await writeFile(join(root, 'workspace/.pi/settings.json'), JSON.stringify({ prompts: [join(root, 'other/prompts')] }));
    } });
  try {
    const { commands } = await f.request('commands');
    const listing = execFile(process.execPath, [fileURLToPath(new URL('../list-commands.mjs', import.meta.url))]);
    const listed = new Promise((resolve, reject) => {
      let output = ''; listing.stdout.on('data', chunk => { output += chunk; });
      listing.on('error', reject); listing.on('close', code => code === 0 ? resolve(JSON.parse(output).commands) : reject(new Error('inventory failed')));
    });
    listing.stdin.end(JSON.stringify({ cwd: f.root + '/workspace', agentDir: f.root + '/agent' }) + '\n');
    assert.deepEqual(await listed, commands);
    assert.deepEqual(commands.map(c => [c.name, c.source]).sort(), [['global', 'global'], ['review', 'workspace']]);
    assert.equal(commands.find(c => c.name === 'review').argumentHint, '[focus]');
    assert.equal(commands.find(c => c.name === 'review').description, 'Review it');
    const state = await f.request('prompt', { text: '/review "API compatibility"' });
    assert.ok(f.requests[0].messages.some(m => JSON.stringify(m.content).includes('Review API compatibility')));
    assert.ok(!JSON.stringify(state.messages).includes('/review'));
  } finally { await f.close(); }
});

test('idle suggestion uses same model/prefix, forbids tools, accounts usage without conversation messages', async () => {
  const f = await hostFixture({ config: { reasoning: true, payloadParameters: { reasoning_effort: 'high' } } });
  try {
    const run = f.request('prompt', { text: 'hello' });
    await f.wait(() => f.responses.length === 1); finishReply(f.responses[0]); await run;
    await f.wait(() => f.responses.length === 2);
    const main = f.requests[0], side = f.requests[1];
    assert.equal(side.model, main.model);
    assert.deepEqual(side.messages.slice(0, main.messages.length), main.messages);
    assert.deepEqual(side.tools, main.tools);
    assert.equal(side.tool_choice, 'none');
    assert.equal(side.reasoning_effort, 'low');
    assert.ok((side.max_tokens ?? side.max_completion_tokens) <= 128);
    finishReply(f.responses[1], '请继续');
    await f.wait(() => f.events.some(e => e.type === 'suggestion' && e.text === '请继续'));
    const state = await f.request('state');
    assert.equal(state.stats.userMessages, 1); assert.equal(state.stats.assistantMessages, 1);
    assert.ok(!JSON.stringify(state.messages).includes('请继续'));
    const history = await readFile(state.sessionFile, 'utf8');
    assert.match(history, /"kind":"next_suggestion"/);
    assert.ok(!history.includes('请继续'));
    assert.ok(state.stats.tokens.input >= 64);
  } finally { await f.close(); }
});

test('disabled and aborted runs do not request suggestions; new prompt cancels old side request', async () => {
  const f = await hostFixture({ config: { nextSuggestion: false } });
  try {
    const run = f.request('prompt', { text: 'hello' });
    await f.wait(() => f.responses.length === 1); finishReply(f.responses[0]); await run;
    await f.request('state'); assert.equal(f.requests.length, 1);
    await f.request('settings', { nextSuggestion: true });
    const second = f.request('prompt', { text: 'second' });
    await f.wait(() => f.responses.length === 2); finishReply(f.responses[1]); await second;
    await f.wait(() => f.responses.length === 3);
    const third = f.request('prompt', { text: 'new prompt' });
    await f.wait(() => f.responses.length === 4);
    finishReply(f.responses[2], 'late old suggestion');
    await f.request('abort'); await third;
    assert.ok(!f.events.some(e => e.type === 'suggestion' && e.text === 'late old suggestion'));
    assert.equal(f.requests.length, 4);
  } finally { await f.close(); }
});

test('typing cancels/suspends suggestions during a run; an error response never starts a side request', async () => {
  const f = await hostFixture();
  try {
    const run = f.request('prompt', { text: 'streaming' });
    await f.wait(() => f.responses.length === 1);
    const cancelled = await f.request('suggestion_cancel');
    assert.equal(typeof cancelled.forTurn, 'number');
    finishReply(f.responses[0]); await run; await f.request('state');
    assert.equal(f.requests.length, 1);
    const next = f.request('prompt', { text: 'provider error' });
    await f.wait(() => f.responses.length === 2);
    f.responses[1].end('data: ' + JSON.stringify({ error: { message: 'synthetic error' } }) + '\n\ndata: [DONE]\n\n');
    await next; await f.request('state');
    assert.equal(f.requests.length, 2);
    assert.ok(!f.events.some(e => e.type === 'suggestion' && e.text));
  } finally { await f.close(); }
});

test('epoch discards a late result even if runtime ignores cancellation; input suspends until next prompt', async () => {
  let resolve, calls = 0;
  const sent = [], usage = [];
  const session = { isIdle: true, messages: [{ role: 'assistant', stopReason: 'stop' }], model: {},
    agent: { convertToLlm: m => m }, modelRuntime: { completeSimple: async () => { calls++; return new Promise(r => { resolve = r; }); } },
    sessionManager: { appendUsage: (...args) => usage.push(args) } };
  const suggestions = new NextSuggestion({ session, send: e => sent.push(e) });
  const pending = suggestions.generate();
  await new Promise(r => setImmediate(r));
  suggestions.invalidate(true);
  resolve({ content: [{ type: 'text', text: 'late' }], usage: { totalTokens: 1 }, stopReason: 'stop' });
  await pending;
  assert.equal(sent.filter(e => e.text === 'late').length, 0);
  assert.equal(usage.length, 1);
  await suggestions.generate(); assert.equal(calls, 1);
  suggestions.invalidate(); suggestions.setEnabled(false);
  await suggestions.generate(); assert.equal(calls, 1);
});
