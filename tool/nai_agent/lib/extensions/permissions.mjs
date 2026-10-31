import { createHash } from 'node:crypto';
import { realpath } from 'node:fs/promises';
import { dirname, resolve, relative, isAbsolute } from 'node:path';

const modes = new Set(['auto', 'ask', 'readonly', 'bypass']);
const reads = new Set(['read', 'grep', 'find', 'ls', 'studio_context', 'studio_search', 'session_history', 'ask_user', 'image_read', 'wiki_query', 'tag_query', 'tag_related', 'block_query', 'settings_read', 'generation_prepare', 'gallery_query', 'generation_cancel', 'tool_search', 'codemode']);
const readActions = {
  prompt_set: new Set(['read']),
  snapshot: new Set(['list', 'read']),
  reference_manage: new Set(['list']),
  reference_library: new Set(['query', 'read', 'categories']),
  gallery_manage: new Set(['read', 'trash', 'collections', 'collection_members', 'folders']),
  image_tool: new Set(['list', 'status', 'cancel', 'prepare']),
  image_generate: new Set(['prepare', 'status', 'cancel']),
  explore_manage: new Set(['list', 'read', 'status', 'prepare', 'pause', 'cancel']),
};
const edits = new Set(['write', 'edit', 'prompt_update', 'prompt_set', 'snapshot', 'block_manage', 'settings_update', 'reference_manage', 'reference_library', 'gallery_manage', 'image_tool', 'image_generate', 'explore_manage']);
const destructive = /(?:^|_)(?:delete|delete_empty|move|move_file|remove)(?:$|_)/;

async function canonical(path) {
  try { return await realpath(path); }
  catch (error) {
    if (!['ENOENT', 'ENOTDIR'].includes(error.code)) throw error;
    const parent = dirname(path);
    if (parent === path) throw error;
    const root = await canonical(parent);
    return resolve(root, relative(parent, path));
  }
}

export function createNaiPermissions({ cwd, mode = 'auto', labels = {}, redact = value => value }) {
  if (!modes.has(mode)) throw new Error('Invalid permission mode');
  let current = mode, revision = 0;
  const approved = new Set(), pending = new Set();
  const text = { title: 'Tool approval required', once: 'Allow once', session: 'Allow identical calls in this session', deny: 'Deny', ...labels };
  const root = canonical(resolve(cwd));
  async function classify(event) {
    const studio = event.toolName.startsWith('mcp__nai_studio__');
    const name = studio ? event.toolName.slice('mcp__nai_studio__'.length) : event.toolName;
    const action = event.input?.action;
    if (name.startsWith('mcp__')) return 'unknown';
    if (['read', 'write', 'edit', 'grep', 'find', 'ls'].includes(name)) {
      const path = event.input?.path ?? (['grep', 'find', 'ls'].includes(name) ? '.' : null);
      if (typeof path !== 'string') return 'unknown';
      const target = await canonical(resolve(cwd, path)), base = await root;
      const outside = relative(base, target);
      if (outside.startsWith('..' + (process.platform === 'win32' ? '\\' : '/')) || outside === '..' || isAbsolute(outside)) return name === 'read' ? 'external-read' : 'unknown';
    }
    if (reads.has(name) || readActions[name]?.has(action)) return 'read';
    if (name === 'generation_run' || (['image_generate', 'image_tool', 'explore_manage'].includes(name) && action === 'run')) return 'native-confirmation';
    if (name === 'bash' || name === 'powershell' || destructive.test(action ?? '')) return 'danger';
    return edits.has(name) ? 'edit' : 'unknown';
  }
  const setMode = value => {
    if (!modes.has(value)) throw new Error('Invalid permission mode');
    if (value === current) return;
    current = value;
    revision++;
    approved.clear();
    for (const controller of pending) controller.abort();
  };
  return {
    setMode,
    getMode: () => current,
    extension: {
      name: 'nai-permissions',
      factory(pi) {
        pi.on('session_shutdown', () => {
          approved.clear();
          for (const controller of pending) controller.abort();
        });
        pi.on('tool_call', async (event, ctx) => {
          const startRevision = revision;
          let kind;
          try { kind = await classify(event); }
          catch { return { block: true, reason: 'Cannot verify the tool target. No operation was performed.' }; }
          if (revision !== startRevision) return { block: true, reason: 'Permissions changed; retry under the current mode.' };
          if (kind === 'read') return;
          if (current === 'readonly' && kind !== 'external-read') return { block: true, reason: 'Read-only mode blocks this operation. Ask the user to change the permission mode.' };
          // Native paid operations still reach Dart's independent confirmation gate.
          if (kind === 'native-confirmation' || current === 'bypass' || (current === 'auto' && kind === 'edit')) return;
          const key = createHash('sha256').update(JSON.stringify({ tool: event.toolName, input: event.input })).digest('hex');
          if (approved.has(key)) return;
          if (!ctx.hasUI) return { block: true, reason: 'Tool approval requires a real user interface.' };
          const cancellation = new AbortController();
          pending.add(cancellation);
          const parent = ctx.getSignal?.();
          const signal = parent ? AbortSignal.any([parent, cancellation.signal]) : cancellation.signal;
          const preview = JSON.stringify(redact(event.input), null, 2)
            .replace(/[\u202a-\u202e\u2066-\u2069]/g, value => '\\u' + value.charCodeAt(0).toString(16).padStart(4, '0'));
          if (preview.length > 64000) {
            pending.delete(cancellation);
            return { block: true, reason: 'Tool input is too large to review safely. Split the operation.' };
          }
          const reusable = kind === 'edit' || kind === 'external-read';
          let answer;
          try {
            answer = await ctx.ui.select(text.title + ': ' + event.toolName + '\n' + preview,
              reusable ? [text.once, text.session, text.deny] : [text.once, text.deny], { signal, kind: 'tool_approval' });
          } catch (error) {
            if (!signal.aborted) throw error;
          } finally { pending.delete(cancellation); }
          if (signal.aborted || revision !== startRevision) return { block: true, reason: 'Tool approval cancelled or permissions changed.' };
          if (answer !== text.once && !(reusable && answer === text.session)) return { block: true, reason: 'The user did not approve this tool call.' };
          if (reusable && answer === text.session) approved.add(key);
        });
      },
    },
  };
}
