import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createStudioModelRuntime } from '../lib/model.mjs';
import { StudioCacheWarming } from '../lib/extensions/cache-warming.mjs';
import { hostFixture, finishReply } from './fixture-host.mjs';

const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const outputCap = request => request.max_tokens ?? request.max_completion_tokens;

test('all Studio protocols declare five-minute prompt caching without inventing prices', async () => {
  for (const protocol of ['openaiChatCompletions', 'ollamaChatCompletions', 'openaiResponses',
    'anthropicMessages', 'geminiGenerateContent']) {
    for (const seconds of [undefined, 11, 0, -1, 1.5, '11']) {
      const { model } = await createStudioModelRuntime({ protocol, providerId: 'test', modelId: 'test',
        baseUrl: 'http://127.0.0.1:1', promptCacheSeconds: seconds });
      assert.deepEqual(model.promptCache, { short: seconds === 11 ? 11 : 300 });
      assert.deepEqual(model.cost, { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 });
    }
  }
});

test('official decision hook honors user modes only for unknown Studio prices', () => {
  let mode = 'streaming';
  const model = { provider: 'studio/test', cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } };
  const warming = new StudioCacheWarming({ model, settingsManager: { getCacheWarmingMode: () => mode } });
  const handlers = new Map();
  warming.extension.factory({ on: (name, handler) => handlers.set(name, handler) });
  const decide = (action = 'stop') => handlers.get('cache_warming_decision')({ action }, { model });
  assert.deepEqual(decide(), { action: 'stop' });
  handlers.get('agent_start')();
  assert.deepEqual(decide(), { action: 'warm' });
  mode = 'off'; assert.deepEqual(decide('warm'), { action: 'stop' });
  mode = 'idle'; handlers.get('agent_settled')();
  assert.deepEqual(decide(), { action: 'warm' });
  model.cost.input = 1;
  assert.equal(decide(), undefined, 'leave Pi economics and its $0.05 threshold untouched');
  assert.equal(decide('warm'), undefined);
  model.cost.input = 0; model.cost.output = 1;
  assert.equal(decide(), undefined);
  model.cost.output = 0; model.provider = 'other/test';
  assert.equal(decide(), undefined);
});

test('status uses Pi delay and persisted warm usage, preserving every real stop and future known economics', () => {
  const model = { provider: 'studio/test', promptCache: { short: 300 },
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } };
  const settingsManager = { getCacheWarmingMode: () => 'idle' };
  const warming = new StudioCacheWarming({ model, settingsManager });
  const warm = { type: 'usage', kind: 'cache_warm', timestamp: '2026-10-26T00:00:00.000Z' };
  const session = { model, agent: { streamFunction() {} }, subscribe() {},
    sessionManager: { getEntries: () => [warm, { ...warm, kind: 'next_suggestion' }, warm] },
    cacheWarmingStatus: { state: 'inactive', reason: 'cache economics unavailable' } };
  warming.attach(session);
  assert.equal(warming.status.state, 'scheduled');
  assert.equal(warming.status.warmCount, 2);
  assert.equal(warming.status.ttlSeconds, 300);
  assert.equal(warming.status.nextWarmAt, Date.parse(warm.timestamp) + 270000);
  for (const reason of ['30-minute idle safety limit reached', 'one-hour safety limit reached',
    'cache refresh deadline missed', 'conversation context changed', 'request cannot be replayed safely']) {
    session.cacheWarmingStatus = { state: 'inactive', reason };
    assert.equal(warming.status.state, 'inactive');
    assert.equal(warming.status.reason, reason);
    assert.equal(warming.status.nextWarmAt, undefined);
  }
  // Pi attaches a decision to an actual stop, unlike its incorrect timer report.
  session.cacheWarmingStatus = { state: 'inactive', reason: 'cache economics unavailable',
    decision: { expectedSavings: 0, action: 'stop' } };
  assert.equal(warming.status.state, 'inactive');
  assert.equal(warming.status.decision, undefined);
  const decision = { expectedSavings: 0.1, economicsAvailable: true, action: 'warm' };
  model.cost.input = 1;
  session.cacheWarmingStatus = { state: 'scheduled', nextWarmAt: 123, decision };
  assert.deepEqual(warming.status.decision, decision);
  assert.equal(warming.status.nextWarmAt, 123);
});

test('default streaming warms a running request with one token, pushes usage, then stops on settle', async () => {
  const f = await hostFixture({ config: { nextSuggestion: false, promptCacheSeconds: 11,
    body: { max_tokens: 256 } } });
  try {
    assert.equal(f.ready.cacheWarming.mode, 'streaming');
    assert.equal(f.ready.cacheWarming.ttlSeconds, 11);
    assert.equal(f.ready.cacheWarming.warmCount, 0);
    const started = Date.now();
    const run = f.request('prompt', { text: 'keep the real request running' });
    await f.wait(() => f.responses.length === 1);
    const scheduled = (await f.request('state')).cacheWarming;
    assert.equal(scheduled.state, 'scheduled');
    assert.ok(scheduled.nextWarmAt >= started + 1000);
    assert.ok(scheduled.nextWarmAt <= Date.now() + 1000);
    assert.equal(scheduled.lastWarmAt, undefined);
    assert.equal(scheduled.decision?.expectedSavings, undefined);
    assert.doesNotMatch(scheduled.reason, /economics unavailable/);
    await f.wait(() => f.responses.length === 2);
    assert.equal(outputCap(f.requests[1]), 1);
    assert.deepEqual(f.requests[1].messages, f.requests[0].messages);
    assert.deepEqual(f.requests[1].tools, f.requests[0].tools);
    assert.equal((await f.request('state')).cacheWarming.state, 'refreshing');
    assert.ok(f.events.some(e => e.type === 'usage' && e.cacheWarming.state === 'refreshing'));
    finishReply(f.responses[1]);
    await f.wait(() => f.events.some(e => e.type === 'usage' && e.cacheWarming.warmCount === 1));
    const pushed = f.events.findLast(e => e.type === 'usage' && e.cacheWarming.warmCount === 1);
    assert.equal(pushed.cacheWarming.state, 'scheduled');
    assert.equal(pushed.cacheWarming.nextWarmAt, pushed.cacheWarming.lastWarmAt + 1000);
    assert.ok(pushed.stats.tokens.input >= 32);
    assert.equal(pushed.cacheWarming.decision?.expectedSavings, undefined);
    const entry = f.events.find(e => e.event?.type === 'entry_appended' && e.event.entry.kind === 'cache_warm').event.entry;
    assert.equal(pushed.cacheWarming.lastWarmAt, Date.parse(entry.timestamp));
    assert.match(await readFile((await f.request('state')).sessionFile, 'utf8'), /"kind":"cache_warm"/);
    finishReply(f.responses[0]);
    const settled = await run;
    assert.equal(settled.cacheWarming.state, 'inactive');
    assert.match(settled.cacheWarming.reason, /settled/);
    assert.equal(settled.cacheWarming.warmCount, 1);
    assert.equal(settled.cacheWarming.nextWarmAt, undefined);
    await pause(1200);
    assert.equal(f.requests.length, 2);
  } finally { await f.close(); }
});

test('idle keeps warming after settle; live streaming and off stop it without restarting stale requests', async () => {
  const f = await hostFixture({ config: { cacheWarming: 'idle', nextSuggestion: false, promptCacheSeconds: 11 } });
  try {
    const run = f.request('prompt', { text: 'finish, then keep the cache warm' });
    await f.wait(() => f.responses.length === 1);
    finishReply(f.responses[0]);
    assert.equal((await run).cacheWarming.state, 'scheduled');
    for (let count = 1; count <= 2; count++) {
      await f.wait(() => f.responses.length === count + 1);
      assert.equal(outputCap(f.requests[count]), 1);
      finishReply(f.responses[count]);
      await f.wait(() => f.events.some(e => e.type === 'usage' && e.cacheWarming.warmCount === count));
      const status = (await f.request('state')).cacheWarming;
      assert.equal(status.state, 'scheduled');
      assert.equal(status.nextWarmAt, status.lastWarmAt + 1000);
      assert.equal(status.warmCount, count);
    }
    const streaming = await f.request('settings', { cacheWarming: 'streaming' });
    assert.equal(streaming.cacheWarming.state, 'inactive');
    assert.match(streaming.cacheWarming.reason, /settled/);
    const idleAgain = await f.request('settings', { cacheWarming: 'idle' });
    assert.equal(idleAgain.cacheWarming.state, 'inactive');
    await pause(1200);
    assert.equal(f.requests.length, 3);
    const next = f.request('prompt', { text: 'new real request' });
    await f.wait(() => f.responses.length === 4);
    assert.equal((await f.request('state')).cacheWarming.state, 'scheduled');
    const off = await f.request('settings', { cacheWarming: 'off' });
    assert.equal(off.cacheWarming.state, 'inactive');
    assert.match(off.cacheWarming.reason, /disabled/);
    finishReply(f.responses[3]); await next;
    await pause(1200);
    assert.equal(f.requests.length, 4);
    assert.equal((await f.request('state')).cacheWarming.warmCount, 2);
  } finally { await f.close(); }
});

test('off never warms and short non-replayable lifetimes stay inactive', async () => {
  for (const config of [{ cacheWarming: 'off', promptCacheSeconds: 11 }, { promptCacheSeconds: 10 }]) {
    const f = await hostFixture({ config: { ...config, nextSuggestion: false } });
    try {
      const run = f.request('prompt', { text: 'do not warm' });
      await f.wait(() => f.responses.length === 1);
      const status = (await f.request('state')).cacheWarming;
      assert.equal(status.state, 'inactive');
      assert.match(status.reason, config.cacheWarming === 'off' ? /disabled/ : /lifetime unavailable/);
      await pause(1200);
      assert.equal(f.requests.length, 1);
      finishReply(f.responses[0]); await run;
      assert.equal((await f.request('state')).cacheWarming.warmCount, 0);
    } finally { await f.close(); }
  }
});
