import { access, realpath } from 'node:fs/promises';
import { resolve, relative, isAbsolute, join, sep } from 'node:path';
import { canonical } from './extensions/permissions.mjs';

const managed = new Set(['attachments','outputs','notes','skills','sessions',
  'snapshots','ui','instructions.md','workspace.json']);

// Only missing legacy reads fall back. Writes and existing project files keep
// their normal cwd semantics, and saved conversation text is never rewritten.
export async function resolveWorkspaceReadPath(cwd, path) {
  const root = await realpath(cwd), original = await canonical(resolve(root,path));
  try { await access(original); return path; }
  catch (error) { if (!['ENOENT','ENOTDIR'].includes(error.code)) throw error; }
  const rel = relative(root,original), parts = rel.split(sep);
  if (isAbsolute(rel) || parts[0] === '..') return path;
  let relocated;
  if (parts[0] === '.agent') relocated = parts.slice(1);
  else if (parts[0] === '.pi' && parts[1] === 'prompts') relocated = parts.slice(1);
  else if (managed.has(parts[0])) relocated = parts;
  else return path;
  let target;
  try { target = await realpath(join(root,'.W.O.F',...relocated)); }
  catch (error) { if (['ENOENT','ENOTDIR'].includes(error.code)) return path; throw error; }
  const inside = relative(root,target);
  if (isAbsolute(inside) || inside.split(sep)[0] === '..')
    throw new Error('Workspace reference leaves project');
  return target;
}
