// Local inventory only: no session/model/credential initialization.
// Studio keeps the answer until the files this reads change (stamped in
// lib/presentation/providers/nai_agent/nai_agent_inventory_cache.dart); read other files here, stamp them there.
import { createInterface } from 'node:readline';
import { resolveStudioPromptTemplates } from './lib/prompt-templates.mjs';
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  try {
    const { commands } = await resolveStudioPromptTemplates(JSON.parse(line));
    process.stdout.write(JSON.stringify({ commands }) + '\n');
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: String(error?.message ?? error) }) + '\n');
  }
  break;
}
input.close();
