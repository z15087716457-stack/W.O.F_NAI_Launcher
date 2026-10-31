import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from 'node:http';
import { resolveStudioPackages, manageStudioPackage, studioPackageManager } from '../lib/packages.mjs';
import { resolveStudioSkills } from '../lib/skills.mjs';
import { resolveStudioPromptTemplates } from '../lib/prompt-templates.mjs';
import { inspectStudioMcp } from '../lib/mcp.mjs';
import { listenFetchTestServer } from './fixture-http.mjs';

test('Pi canonical package identity replaces pinned versions without a second registry', async () => {
  const root = await mkdtemp(join(tmpdir(),'studio-package-identity-'));
  try {
    const manager = studioPackageManager({cwd:root,agentDir:join(root,'.W.O.F'),scope:'workspace',
      entries:[{scope:'workspace',source:'npm:@fixture/tools@1.0.0',enabled:true}]});
    manager.addSourceToSettings('npm:@fixture/tools@2.0.0');
    assert.deepEqual(manager.listConfiguredPackages().map(p => p.source),['npm:@fixture/tools@2.0.0']);
  } finally { await rm(root,{recursive:true,force:true}); }
});

test('local Pi packages resolve their original resources and unlink without deleting source', async () => {
  const root = await mkdtemp(join(tmpdir(), 'studio-packages-'));
  try {
    const source = join(root, 'a package');
    await mkdir(join(source, 'skills', 'local-skill'), { recursive: true });
    await mkdir(join(source, 'extensions'));
    await mkdir(join(source, 'prompts'));
    await writeFile(join(source, 'package.json'), JSON.stringify({name:'local-package',version:'1.0.0',pi:{
      extensions:['./extensions/test.mjs'],skills:['./skills'],prompts:['./prompts'],
    }}));
    await writeFile(join(source, 'extensions', 'test.mjs'), 'export default pi => {};');
    const file = join(source, 'skills', 'local-skill', 'SKILL.md');
    await writeFile(file, '---\nname: local-skill\ndescription: Local package skill\n---\nUse local files.\n');
    await writeFile(join(source, 'prompts', 'hello.md'), '---\ndescription: A package prompt\n---\nHello $@');
    const input = { cwd:root,agentDir:join(root,'.W.O.F'),globalDirectory:join(root,'global'),
      scope:'workspace',source,entries:[{source,scope:'workspace',enabled:true}] };
    await manageStudioPackage({...input,action:'install'});
    const resources = await resolveStudioPackages(input);
    assert.equal(resources.extensions.length, 1);
    assert.equal(resources.packageSkills.length, 1);
    assert.equal(resources.packageSkills[0].filePath, file);
    const skills = resolveStudioSkills({builtinDirectory:join(root,'none'),packageSkills:resources.packageSkills});
    assert.equal(skills.report[0].packageSource, source);
    assert.equal(skills.active[0].name,'local-skill');
    assert.match(skills.report[0].key,/^workspace\/pkg_/);
    const templates = await resolveStudioPromptTemplates({cwd:root,agentDir:input.agentDir,packages:input});
    assert.equal(templates.commands.find(c => c.name === 'hello')?.source, 'workspace');
    assert.equal((await resolveStudioPackages({...input,entries:[]})).skills.length,0);
    await manageStudioPackage({...input,action:'uninstall'});
    assert.match(await readFile(file,'utf8'),/Local package skill/);
    const off = await resolveStudioPackages({...input,entries:[{source,scope:'workspace',enabled:false}]});
    assert.equal(off.extensions.length,0);
  } finally { await rm(root,{recursive:true,force:true}); }
});

test('MCP connection inspection uses a real local handshake and no tool execution', async () => {
  const root = await mkdtemp(join(tmpdir(),'studio-mcp-inspect-'));
  const methods = [];
  const server = createServer(async (req,res) => {
    if (req.method !== 'POST') { res.writeHead(405).end(); return; }
    let body = ''; for await (const chunk of req) body += chunk;
    const message = JSON.parse(body); methods.push(message.method);
    if (message.id === undefined) { res.writeHead(202).end(); return; }
    const result = message.method === 'initialize'
      ? {protocolVersion:message.params.protocolVersion,capabilities:{tools:{}},serverInfo:{name:'local-test',version:'1'}}
      : message.method === 'tools/list' ? {tools:[{name:'local_read',description:'Fixture',inputSchema:{type:'object'}}]} : {};
    res.setHeader('content-type','application/json');
    res.end(JSON.stringify({jsonrpc:'2.0',id:message.id,result}));
  });
  await listenFetchTestServer(server);
  try {
    const result = await inspectStudioMcp({name:'local',config:{url:'http://127.0.0.1:'+server.address().port,timeout:5},
      cwd:root,agentDir:join(root,'.W.O.F')});
    assert.equal(result.state,'connected');
    assert.equal(result.tools,1);
    assert.deepEqual(result.toolNames,['local_read']);
    assert.ok(methods.includes('initialize') && methods.includes('tools/list'));
    assert.ok(!methods.includes('tools/call'));
  } finally { server.closeAllConnections(); await new Promise(r => server.close(r)); await rm(root,{recursive:true,force:true}); }
});
