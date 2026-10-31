import { createHash } from 'node:crypto';
import { dirname } from 'node:path';
import { DefaultPackageManager, SettingsManager, loadSkills } from '@earendil-works/pi-coding-agent';

// Studio persists source selections; Pi installs and resolves their resources.
export function studioPackageManager({ cwd, agentDir, globalDirectory, entries = [], scope }) {
  return new DefaultPackageManager({ cwd,
    agentDir: scope === 'global' ? globalDirectory : agentDir,
    settingsManager: SettingsManager.inMemory({ packages: entries
      .filter(p => p.enabled !== false && p.scope === scope).map(p => p.source) }),
  });
}

export async function resolveStudioPackages(input) {
  const resources = { extensions: [], skills: [], prompts: [], themes: [] };
  const packageSkills = [];
  for (const scope of ['workspace', 'global']) {
    if (!(input.entries ?? []).some(p => p.enabled !== false && p.scope === scope)) continue;
    const resolved = await studioPackageManager({ ...input, scope }).resolve(() => 'error');
    for (const kind of Object.keys(resources)) {
      const entries = resolved[kind].filter(r => r.enabled && r.metadata.origin === 'package');
      resources[kind].push(...entries.map(r => ({ ...r, studioScope: scope })));
      if (kind !== 'skills') continue;
      for (const resource of entries) {
        const loaded = loadSkills({ cwd: input.cwd, agentDir: input.agentDir,
          skillPaths: [resource.path], includeDefaults: false });
        if (loaded.diagnostics.some(d => d.type === 'error'))
          throw new Error(loaded.diagnostics.map(d => d.message).join('\n'));
        for (const skill of loaded.skills) {
          const identity = createHash('sha256').update(scope + '\0' +
            (scope === 'workspace' ? input.cwd : '') + '\0' + resource.metadata.source + '\0' + skill.filePath).digest('hex').slice(0, 12);
          packageSkills.push({ ...skill, key: scope + '/pkg_' + identity,
            source: scope, directory: dirname(skill.filePath), file: skill.filePath,
            packageSource: resource.metadata.source });
        }
      }
    }
  }
  return { ...resources, packageSkills };
}

export async function manageStudioPackage(input) {
  const manager = studioPackageManager({ ...input, entries: input.entries.map(p => ({ ...p, enabled: true })) });
  // Pi owns source identities and version replacement too. Its settings here
  // are in memory; Studio persists this canonical result once.
  if (input.action === 'install') await manager.installAndPersist(input.source);
  else if (input.action === 'uninstall') await manager.removeAndPersist(input.source);
  else if (input.action === 'update') await manager.update(input.source);
  else throw new Error('Unknown package action');
  return { source: input.source, scope: input.scope,
    path: manager.getInstalledPath(input.source, 'user'),
    sources: manager.listConfiguredPackages().map(p => p.source) };
}
