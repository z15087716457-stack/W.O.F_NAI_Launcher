import { join, resolve, relative, isAbsolute } from 'node:path';
import { DefaultResourceLoader, SettingsManager } from '@earendil-works/pi-coding-agent';

// Like skills, Studio owns the source roots and precedence, not Pi's ambient config.
export async function resolveStudioPromptTemplates({ cwd, agentDir, globalDirectory, workspaceDirectory }) {
  const workspace = resolve(workspaceDirectory ?? join(cwd, '.W.O.F', 'prompts'));
  const global = resolve(globalDirectory ?? join(agentDir, 'prompts'));
  const loader = new DefaultResourceLoader({ cwd, agentDir, settingsManager: SettingsManager.inMemory(),
    noExtensions: true, noSkills: true, noPromptTemplates: true, noThemes: true, noContextFiles: true,
    additionalPromptTemplatePaths: [workspace, global],
  });
  await loader.reload();
  const { prompts, diagnostics } = loader.getPrompts();
  const commands = prompts.map(template => {
    const path = relative(workspace, template.filePath);
    return { kind: 'template', name: template.name, description: template.description,
      argumentHint: template.argumentHint,
      source: path === '' || (!path.startsWith('..') && !isAbsolute(path)) ? 'workspace' : 'global' };
  });
  return { prompts, commands, diagnostics };
}
