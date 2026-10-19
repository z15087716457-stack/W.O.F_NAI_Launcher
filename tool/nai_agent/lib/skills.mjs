// Studio-owned skill sources. Pi's own loader parses SKILL.md; Studio only decides
// which folders count, which copy wins a name, and the user's on/off and mode choices.
import { existsSync, readdirSync, statSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadSkillsFromDir } from '@earendil-works/pi-coding-agent';

export const builtinSkillsDirectory = resolve(dirname(fileURLToPath(import.meta.url)), '..', 'skills');
// Highest priority first: a workspace copy replaces a global one, which replaces the built-in.
const order = ['workspace', 'global', 'builtin'];

export function skillErrorCode(message = '') {
  if (/description/i.test(message)) return 'description';
  if (/^name /i.test(message)) return 'name';
  return 'parse';
}

function scan(directory, source) {
  const entries = [];
  if (!directory || !existsSync(directory)) return entries;
  const { skills, diagnostics } = loadSkillsFromDir({ dir: directory, source: 'path' });
  const byFile = new Map(skills.map(skill => [resolve(skill.filePath), skill]));
  const errors = new Map();
  for (const diagnostic of diagnostics) {
    const file = resolve(diagnostic.path ?? '');
    if (!errors.has(file)) errors.set(file, skillErrorCode(diagnostic.message));
  }
  for (const item of readdirSync(directory, { withFileTypes: true })) {
    if (item.name.startsWith('.') || item.name === 'node_modules') continue;
    const folder = join(directory, item.name);
    let isDirectory = item.isDirectory();
    if (item.isSymbolicLink()) {
      try { isDirectory = statSync(folder).isDirectory(); } catch { continue; }
    }
    if (!isDirectory) continue;
    const file = resolve(folder, 'SKILL.md');
    const skill = byFile.get(file);
    if (!existsSync(file)) {
      entries.push({ name: item.name, source, directory: folder, file, error: 'missing' });
      continue;
    }
    // Studio is stricter than Pi on names so /skill:<name> and override keys stay unambiguous.
    const error = errors.get(file) ?? (skill && skill.name !== item.name ? 'name' : undefined);
    // The folder is the identity the user sees on disk and in settings keys.
    entries.push({ name: item.name, description: skill?.description ?? '', source,
      directory: folder, file, skill, manualDefault: skill?.disableModelInvocation === true,
      ...(error ? { error } : {}) });
  }
  return entries.sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * disabled: keys `<source>/<name>` the user switched off (built-ins included).
 * modes: `<source>/<name>` -> 'auto' | 'manual'; missing keys keep the SKILL.md default.
 */
export function resolveStudioSkills({ builtinDirectory = builtinSkillsDirectory, globalDirectory,
  workspaceDirectory, disabled = [], modes = {} } = {}) {
  const off = new Set(Array.isArray(disabled) ? disabled : []);
  const directories = { builtin: builtinDirectory, global: globalDirectory, workspace: workspaceDirectory };
  const winners = new Map(), report = [], active = [];
  for (const source of order) {
    for (const entry of scan(directories[source], source)) {
      const key = source + '/' + entry.name;
      const mode = modes?.[key] === 'manual' || modes?.[key] === 'auto' ? modes[key]
        : entry.manualDefault ? 'manual' : 'auto';
      const enabled = !off.has(key);
      let state = entry.error ? 'error' : !enabled ? 'disabled' : winners.has(entry.name) ? 'shadowed' : 'active';
      if (state === 'active') {
        winners.set(entry.name, key);
        active.push({ ...entry.skill, disableModelInvocation: mode === 'manual' });
      }
      report.push({ key, name: entry.name, description: entry.description, source,
        directory: entry.directory, file: entry.file, enabled, mode, state,
        ...(entry.error ? { error: entry.error } : {}),
        ...(state === 'shadowed' ? { shadowedBy: winners.get(entry.name) } : {}) });
    }
  }
  return { active, report };
}

export const skillDirectoryName = basename;
