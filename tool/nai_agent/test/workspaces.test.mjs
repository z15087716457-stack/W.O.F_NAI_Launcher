import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { createServer } from 'node:http';
import { createStudioSession } from '../lib/session.mjs';

async function fixture() {
  await mkdir('.runs', { recursive: true });
  const root = resolve(await mkdtemp('.runs/workspaces-'));
  const requests = [];
  const server = createServer(async (request, response) => {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    response.writeHead(200, { 'content-type': 'text/event-stream; charset=utf-8', connection: 'close' });
    response.end('data: ' + JSON.stringify({ id: 'synthetic', object: 'chat.completion.chunk',
      model: 'test', choices: [{ index: 0, delta: { role: 'assistant', content: '完成' }, finish_reason: 'stop' }] })
      + '\n\ndata: [DONE]\n\n');
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const options = {
    cwd: join(root, 'workspace'), agentDir: join(root, 'workspace', '.agent'),
    sessionDirectory: join(root, 'workspace', 'sessions'),
    systemPrompt: '初始提示词', executeTool: async () => ({ content: [] }),
    config: { providerId: 'test', modelId: 'test', protocol: 'openaiChatCompletions',
      baseUrl: 'http://127.0.0.1:' + server.address().port, apiKey: 'synthetic', tools: true },
  };
  return { options, requests, close: async () => {
    server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
  } };
}

test('official persistence resumes without a model request; another workspace cannot claim it', async () => {
  const f = await fixture();
  let opened;
  try {
    const first = await createStudioSession(f.options);
    await first.session.prompt('第一次');
    const id = first.session.sessionId, sessionFile = first.session.sessionFile;
    const history = await readFile(sessionFile, 'utf8');
    first.session.dispose();
    opened = await createStudioSession({ ...f.options, sessionFile });
    assert.equal(opened.session.sessionId, id);
    assert.equal(opened.session.messages.filter(message => ['user', 'assistant'].includes(message.role)).length, 2);
    assert.equal(f.requests.length, 1);
    assert.equal(await readFile(sessionFile, 'utf8'), history);
    await assert.rejects(createStudioSession({ ...f.options,
      cwd: join(f.options.cwd, '../other'), sessionFile }), /another workspace/);
    await assert.rejects(createStudioSession({ ...f.options,
      sessionDirectory: join(f.options.cwd, '../other/sessions'), sessionFile }), /leaves workspace/);
  } finally { opened?.session.dispose(); await f.close(); }
});

test('prompt refresh and user edit use public Pi APIs and preserve abandoned history', async () => {
  const f = await fixture();
  const created = await createStudioSession(f.options);
  try {
    await created.session.prompt('原问题');
    created.setSystemPrompt('更新提示词');
    const user = created.session.getUserMessagesForForking()[0];
    const navigation = await created.session.navigateTree(user.entryId, { summarize: false });
    assert.equal(navigation.editorText, '原问题');
    assert.equal(created.session.messages.filter(message => ['user', 'assistant'].includes(message.role)).length, 0);
    assert.equal(f.requests.length, 1);
    await created.session.prompt('修订问题');
    assert.match(f.requests[1].messages[0].content, /更新提示词/);
    assert.ok(!JSON.stringify(f.requests[1]).includes('原问题'));
    const history = await readFile(created.session.sessionFile, 'utf8');
    assert.ok(history.includes('原问题') && history.includes('修订问题'));
  } finally { created.session.dispose(); await f.close(); }
});
