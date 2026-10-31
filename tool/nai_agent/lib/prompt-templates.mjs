import { join, resolve, relative, isAbsolute } from 'node:path';
import { DefaultResourceLoader, SettingsManager } from '@earendil-works/pi-coding-agent';
import { resolveStudioPackages } from './packages.mjs';

// Like skills, Studio owns the source roots and precedence, not Pi's ambient config.
export async function resolveStudioPromptTemplates({ cwd, agentDir, globalDirectory, workspaceDirectory, packages = {}, packagePrompts }) {
  packagePrompts ??= (await resolveStudioPackages({ ...packages, cwd, agentDir })).prompts;
  const workspace = resolve(workspaceDirectory ?? join(cwd, '.W.O.F', 'prompts'));
  const global = resolve(globalDirectory ?? join(agentDir, 'prompts'));
  const loader = new DefaultResourceLoader({ cwd, agentDir, settingsManager: SettingsManager.inMemory(),
    noExtensions: true, noSkills: true, noPromptTemplates: true, noThemes: true, noContextFiles: true,
    additionalPromptTemplatePaths: [workspace, global, ...packagePrompts.map(p => p.path)],
  });
  await loader.reload();
  const { prompts, diagnostics } = loader.getPrompts();
  const commands = prompts.map(template => {
    const path = relative(workspace, template.filePath);
    const owned = packagePrompts.find(p => {
      const from = relative(p.path, template.filePath);
      return from === '' || (!from.startsWith('..') && !isAbsolute(from));
    });
    return { kind: 'template', name: template.name, description: template.description,
      argumentHint: template.argumentHint,
      source: owned?.studioScope ?? (path === '' || (!path.startsWith('..') && !isAbsolute(path)) ? 'workspace' : 'global') };
  });
  return { prompts, commands, diagnostics };
}
