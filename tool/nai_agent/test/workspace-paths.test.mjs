import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, rm, realpath, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { resolveWorkspaceReadPath } from '../lib/workspace-paths.mjs';

test('missing legacy references resolve inside .W.O.F and existing project files win', async () => {
  const root = await mkdtemp(join(tmpdir(),'wof-paths-'));
  try {
    for (const relative of ['outputs/report.md','attachments/chat/image.png','draft-backups/draft.json','prompts/review.md']) {
      const path = join(root,'.W.O.F',relative);
      await mkdir(join(path,'..'),{recursive:true});await writeFile(path,'original');
    }
    assert.equal(await resolveWorkspaceReadPath(root,'outputs/report.md'),await realpath(join(root,'.W.O.F/outputs/report.md')));
    assert.equal(await resolveWorkspaceReadPath(root,join(root,'attachments/chat/image.png')),await realpath(join(root,'.W.O.F/attachments/chat/image.png')));
    assert.equal(await resolveWorkspaceReadPath(root,'.agent/draft-backups/draft.json'),await realpath(join(root,'.W.O.F/draft-backups/draft.json')));
    assert.equal(await resolveWorkspaceReadPath(root,'.pi/prompts/review.md'),await realpath(join(root,'.W.O.F/prompts/review.md')));
    await mkdir(join(root,'outputs'));await writeFile(join(root,'outputs/report.md'),'project');
    assert.equal(await resolveWorkspaceReadPath(root,'outputs/report.md'),'outputs/report.md');
    assert.equal(await resolveWorkspaceReadPath(root,'../outputs/report.md'),'../outputs/report.md');
    assert.equal(await resolveWorkspaceReadPath(root,'custom.py'),'custom.py');
  } finally { await rm(root,{recursive:true,force:true}); }
});

test('legacy fallback cannot follow a launcher directory outside the project', async () => {
  const root = await mkdtemp(join(tmpdir(),'wof-boundary-'));
  const outside = await mkdtemp(join(tmpdir(),'wof-outside-'));
  try {
    await mkdir(join(root,'.W.O.F'));
    await writeFile(join(outside,'report.md'),'external');
    await symlink(outside,join(root,'.W.O.F','outputs'),process.platform==='win32'?'junction':'dir');
    await assert.rejects(resolveWorkspaceReadPath(root,'outputs/report.md'),/leaves project/);
  } finally { await rm(root,{recursive:true,force:true});await rm(outside,{recursive:true,force:true}); }
});
