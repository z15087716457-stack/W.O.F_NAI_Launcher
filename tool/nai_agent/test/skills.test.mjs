import { listenFetchTestServer } from './fixture-http.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, writeFile, readFile, readdir } from 'node:fs/promises';
import { createServer } from 'node:http';
import { resolve, join } from 'node:path';
import { createStudioSession } from '../lib/session.mjs';
import { resolveStudioSkills, builtinSkillsDirectory } from '../lib/skills.mjs';
import { domainTools } from '../lib/domain-tools.mjs';

async function root() {
  await mkdir('.runs', { recursive: true });
  return resolve(await mkdtemp('.runs/skills-'));
}
async function skill(dir, name, body = '', front = `name: ${name}\ndescription: ${name} test skill.`) {
  await mkdir(join(dir, name), { recursive: true });
  await writeFile(join(dir, name, 'SKILL.md'), `---\n${front}\n---\n${body}`);
}

test('built-in skills are valid, cover every business tool and link only existing references', async () => {
  const { report } = resolveStudioSkills({});
  assert.deepEqual(report.map(item => [item.key, item.state]),
    [['builtin/nai-prompt', 'active'], ['builtin/nai-studio', 'active']]);
  const studio = await readFile(join(builtinSkillsDirectory, 'nai-studio', 'SKILL.md'), 'utf8');
  for (const tool of domainTools) assert.ok(studio.includes('`' + tool.name + '`'), tool.name + ' missing from nai-studio');
  for (const name of ['nai-studio', 'nai-prompt']) {
    const dir = join(builtinSkillsDirectory, name);
    const text = await readFile(join(dir, 'SKILL.md'), 'utf8');
    const links = [...text.matchAll(/\]\((references\/[^)]+)\)/g)].map(match => match[1]);
    const files = (await readdir(join(dir, 'references'))).map(file => 'references/' + file);
    assert.deepEqual(links.toSorted(), [...new Set(links)].toSorted(), 'duplicate link in ' + name);
    assert.deepEqual([...new Set(links)].toSorted(), files.toSorted(), name + ' links and files differ');
  }
});

test('workspace beats global beats built-in; switches, modes and errors are reported per copy', async () => {
  const dir = await root(), global = join(dir, 'global'), workspace = join(dir, 'workspace');
  await skill(global, 'nai-studio', 'my studio copy');
  await skill(global, 'shared');
  await skill(workspace, 'shared');
  await skill(global, 'quiet', '', 'name: quiet\ndescription: Quiet.\ndisable-model-invocation: true');
  await skill(global, 'off');
  await skill(global, 'nodesc', '', 'name: nodesc');
  await skill(global, 'Bad_Name', '', 'name: Bad_Name\ndescription: Bad.');
  await skill(global, 'renamed', '', 'name: other\ndescription: Folder and name differ.');
  await mkdir(join(global, 'empty'), { recursive: true });
  const { active, report } = resolveStudioSkills({ globalDirectory: global, workspaceDirectory: workspace,
    disabled: ['global/off', 'builtin/nai-prompt'], modes: { 'workspace/shared': 'manual', 'global/quiet': 'auto' } });
  const state = Object.fromEntries(report.map(item => [item.key, item.state]));
  assert.equal(state['workspace/shared'], 'active');
  assert.equal(state['global/shared'], 'shadowed');
  assert.equal(report.find(item => item.key === 'global/shared').shadowedBy, 'workspace/shared');
  assert.equal(state['global/nai-studio'], 'active');
  assert.equal(state['builtin/nai-studio'], 'shadowed');
  assert.equal(state['builtin/nai-prompt'], 'active', 'built-ins cannot be switched off');
  assert.equal(state['global/off'], 'disabled');
  assert.equal(report.find(item => item.key === 'global/nodesc').error, 'description');
  assert.equal(report.find(item => item.key === 'global/Bad_Name').error, 'name');
  assert.equal(report.find(item => item.key === 'global/renamed').error, 'name');
  assert.equal(report.find(item => item.key === 'global/empty').error, 'missing');
  const byName = Object.fromEntries(active.map(item => [item.name, item]));
  assert.deepEqual(Object.keys(byName).toSorted(), ['nai-prompt', 'nai-studio', 'quiet', 'shared']);
  assert.equal(byName.shared.disableModelInvocation, true);
  assert.equal(byName.quiet.disableModelInvocation, false, 'explicit auto overrides the SKILL.md default');
  assert.ok(byName['nai-studio'].filePath.startsWith(global));
});

test('the real session lists active auto skills, hides manual ones and expands /skill: through Pi', async () => {
  const dir = await root(), global = join(dir, 'global'), requests = [];
  await skill(global, 'auto-one', 'AUTO BODY');
  await skill(global, 'manual-one', 'MANUAL BODY');
  await skill(global, 'disabled-one', 'DISABLED BODY');
  const server = createServer(async (req, res) => {
    const chunks = []; for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    res.end('data: ' + JSON.stringify({ id: 't', object: 'chat.completion.chunk', model: 'test',
      choices: [{ index: 0, delta: { role: 'assistant', content: 'ok' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
  const created = await createStudioSession({ cwd: join(dir, 'ws'), agentDir: join(dir, 'agent'), systemPrompt: 'NAI.',
    config: { providerId: 'skills', modelId: 'test', protocol: 'openaiChatCompletions', tools: true,
      baseUrl: 'http://127.0.0.1:' + server.address().port },
    extraToolNames: ['ask_user', ...domainTools.map(tool => tool.name)], executeTool: async () => ({ content: [] }),
    skills: { globalDirectory: global, disabled: ['global/disabled-one'], modes: { 'global/manual-one': 'manual' } } });
  try {
    await created.session.prompt('hello');
    const system = JSON.stringify(requests[0].messages.find(message => ['system', 'developer'].includes(message.role)).content);
    assert.ok(system.includes('<name>auto-one</name>'));
    assert.ok(system.includes('<name>nai-studio</name>') && system.includes('<name>nai-prompt</name>'));
    assert.ok(!system.includes('manual-one') && !system.includes('disabled-one'));
    assert.ok(!system.includes('wiki_query'), 'detailed tool routes left the system prompt');
    assert.equal(requests[0].tools.length, 7);
    await created.session.prompt('/skill:manual-one do it');
    const user = JSON.stringify(requests[1].messages.at(-1).content);
    assert.ok(user.includes('MANUAL BODY') && user.includes('do it'));
    await created.session.prompt('/skill:disabled-one');
    assert.ok(!JSON.stringify(requests[2].messages.at(-1).content).includes('DISABLED BODY'));
    assert.deepEqual(created.skills.filter(item => item.source === 'global').map(item => [item.name, item.state, item.mode]),
      [['auto-one', 'active', 'auto'], ['disabled-one', 'disabled', 'auto'], ['manual-one', 'active', 'manual']]);
  } finally {
    await created.close(); server.closeAllConnections(); await new Promise(done => server.close(done));
  }
});

test('list-skills reports the same resolution settings show, without a session', async () => {
  const { spawn } = await import('node:child_process');
  const dir = await root(), global = join(dir, 'global');
  await skill(global, 'listed');
  const child = spawn(process.execPath, [new URL('../list-skills.mjs', import.meta.url).pathname.replace(/^\/(\w:)/, '$1')]);
  let out = '';
  child.stdout.on('data', chunk => { out += chunk; });
  child.stdin.end(JSON.stringify({ globalDirectory: global, modes: { 'global/listed': 'manual' } }) + '\n');
  await new Promise(done => child.on('close', done));
  const value = JSON.parse(out.trim());
  assert.deepEqual(value.skills.map(item => [item.key, item.state, item.mode]),
    [['global/listed', 'active', 'manual'], ['builtin/nai-prompt', 'active', 'auto'], ['builtin/nai-studio', 'active', 'auto']]);
  assert.ok(value.catalogChars > 0);
});
