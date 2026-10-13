import { randomUUID } from 'node:crypto';

// Public Pi ExtensionUIContext -> existing native question cards. No TUI emulation.
export function createStudioExtensionUi(execute, emit = () => {}) {
  const pending = new Set();
  let closed = false;
  async function dialog(method, params, options = {}) {
    if (closed || options.signal?.aborted) return undefined;
    const cancellation = new AbortController();
    pending.add(cancellation);
    const signal = options.signal
      ? AbortSignal.any([cancellation.signal, options.signal]) : cancellation.signal;
    let timer;
    if (Number.isFinite(options.timeout) && options.timeout >= 0)
      timer = setTimeout(() => cancellation.abort(), options.timeout);
    try {
      const result = await execute('_nai_extension_ui', 'ui-' + randomUUID(), { method, ...params }, signal);
      const value = JSON.parse(result.content.find(part => part.type === 'text')?.text ?? '{}');
      return value.status === 'answered' ? value.value : undefined;
    } catch (error) {
      if (!signal.aborted) throw error;
      return undefined;
    } finally {
      clearTimeout(timer);
      pending.delete(cancellation);
    }
  }
  const noop = () => {};
  // Standard dialog labels are plain text; Flutter owns their colors and style.
  const text = value => value;
  const theme = {
    name: 'Studio', fg: (_color, value) => value, bg: (_color, value) => value,
    style: text, bold: text, italic: text, underline: text, inverse: text, strikethrough: text,
    getFgAnsi: () => '', getBgAnsi: () => '',
    getThinkingBorderColor: () => text, getBashModeBorderColor: () => text,
  };
  return {
    context: {
      theme,
      select: (title, options, opts) => options.length === 0 ? Promise.resolve(undefined)
        : dialog('select', { title, options, ...(opts?.kind === 'tool_approval' ? { kind: opts.kind } : {}) }, opts),
      confirm: async (title, message, opts) => (await dialog('confirm', { title, message }, opts)) === true,
      input: (title, placeholder, opts) => dialog('input', { title, placeholder }, opts),
      editor: (title, prefill) => dialog('editor', { title, prefill }),
      notify: (message, level = 'info') => emit({ method: 'notify', message, level }),
      setStatus: (key, text) => emit({ method: 'setStatus', key, text }),
      setWidget: (key, lines) => {
        if (lines === undefined || (Array.isArray(lines) && lines.every(line => typeof line === 'string')))
          emit({ method: 'setWidget', key, lines });
      },
      custom: async () => undefined,
      onTerminalInput: () => noop,
      setWorkingMessage: noop, setWorkingVisible: noop, setWorkingIndicator: noop,
      setHiddenThinkingLabel: noop, setFooter: noop, setHeader: noop,
      setTitle: noop, setEditorText: noop, pasteToEditor: noop,
      getEditorText: () => '', setEditorComponent: noop, getEditorComponent: () => undefined,
      addAutocompleteProvider: noop, setToolsExpanded: noop, getToolsExpanded: () => false,
      getAllThemes: () => [], getTheme: () => undefined,
      setTheme: () => ({ success: false, error: 'Desktop theme is managed by Studio' }),
    },
    cancel(close = false) {
      if (close) closed = true;
      for (const cancellation of pending) cancellation.abort();
    },
  };
}
