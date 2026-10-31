import { listenFetchTestServer } from './fixture-http.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, writeFile, rename } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { createServer } from 'node:http';
import { createStudioSession } from '../lib/session.mjs';

async function fixture({ readPath } = {}) {
  await mkdir('.runs', { recursive: true });
  const root = resolve(await mkdtemp('.runs/workspaces-'));
  const requests = [];
  const server = createServer(async (request, response) => {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    const read = readPath && requests.at(-1).messages.at(-1)?.role === 'user';
    response.writeHead(200, { 'content-type': 'text/event-stream; charset=utf-8', connection: 'close' });
    response.end('data: ' + JSON.stringify({ id: 'synthetic', object: 'chat.completion.chunk',
      model: 'test', choices: [{ index: 0, delta: read
        ? {role:'assistant',tool_calls:[{index:0,id:'read-'+requests.length,type:'function',function:{name:'read',arguments:JSON.stringify({path:readPath})}}]}
        : { role: 'assistant', content: '完成' }, finish_reason: read ? 'tool_calls' : 'stop' }] })
      + '\n\ndata: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
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

test('moved sessions keep the project cwd and native read follows old output references', async () => {
  const f = await fixture({readPath:'outputs/report.md'});
  let opened;
  try {
    await mkdir(join(f.options.cwd,'outputs'),{recursive:true});
    await writeFile(join(f.options.cwd,'outputs/report.md'),'Original report');
    opened = await createStudioSession(f.options);
    await opened.session.prompt('Read the original report');
    const originalFile = opened.session.sessionFile;
    const original = await readFile(originalFile,'utf8');
    opened.session.dispose();opened = null;
    const data = join(f.options.cwd,'.W.O.F');
    await rename(f.options.agentDir,data);
    await rename(join(f.options.cwd,'outputs'),join(data,'outputs'));
    await rename(f.options.sessionDirectory,join(data,'sessions'));
    const file = join(data,'sessions',originalFile.split(/[\\/]/).at(-1));
    opened = await createStudioSession({...f.options,agentDir:data,sessionDirectory:join(data,'sessions'),sessionFile:file});
    assert.equal(opened.manager.getCwd(),f.options.cwd);
    assert.equal(await readFile(file,'utf8'),original);
    assert.equal(opened.session.getActiveToolNames().filter(name=>name==='read').length,1);
    await opened.session.prompt('Read the report after migration');
    let result = opened.session.messages.filter(message=>message.role==='toolResult').at(-1);
    assert.ok(!result.isError);
    assert.match(JSON.stringify(result.content),/Original report/);
    await mkdir(join(f.options.cwd,'outputs'));
    await writeFile(join(f.options.cwd,'outputs/report.md'),'Custom project output');
    await opened.session.prompt('Read my project output');
    result = opened.session.messages.filter(message=>message.role==='toolResult').at(-1);
    assert.ok(!result.isError);
    assert.match(JSON.stringify(result.content),/Custom project output/);
  } finally { opened?.session.dispose(); await f.close(); }
});
