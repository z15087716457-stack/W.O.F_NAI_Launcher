// One-shot skill inventory for Studio settings, using the same resolver as sessions.
// Input: one JSON line on stdin (the init `skills` object). Output: one JSON line.
import { createInterface } from 'node:readline';
import { resolveStudioSkills } from './lib/skills.mjs';
import { resolveStudioPackages } from './lib/packages.mjs';

const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  let config;
  try { config = JSON.parse(line); }
  catch { process.stdout.write(JSON.stringify({ error: 'invalid_json' }) + '\n'); break; }
  try {
    const { packageSkills } = await resolveStudioPackages({ ...(config.packages ?? {}), cwd: config.cwd, agentDir: config.agentDir });
    const { active, report } = resolveStudioSkills({ ...config, packageSkills });
    // Same estimate rule as the settings aside: about four characters per token.
    const catalog = active.filter(skill => !skill.disableModelInvocation)
      .reduce((sum, skill) => sum + skill.name.length + skill.description.length + skill.filePath.length + 60, 0);
    process.stdout.write(JSON.stringify({ skills: report, catalogChars: catalog }) + '\n');
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: String(error?.message ?? error) }) + '\n');
  }
  break;
}
input.close();
