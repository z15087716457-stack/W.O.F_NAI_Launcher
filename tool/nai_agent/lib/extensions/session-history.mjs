import { Type } from 'typebox';

// Native Pi history access, discovered on demand. No JSONL parsing or prompt hook.
export function createSessionHistoryExtension(redact) {
  return { name: 'nai-session-history', factory(pi) {
    pi.registerTool({
      name: 'session_history', label: 'Session history', exposure: 'deferred',
      description: 'Read exact earlier conversation on the current branch, including before compaction. outline lists user turns; search finds text; read reads an entry; read_turn reads a turn. Images/binary and thinking are omitted. Bounded results offer next_offset.',
      parameters: Type.Object({
        action: Type.Union(['outline','search','read','read_turn'].map(value => Type.Literal(value))),
        query: Type.Optional(Type.String({minLength:1,maxLength:200})),
        roles: Type.Optional(Type.Array(Type.Union(['user','assistant','tool'].map(value => Type.Literal(value))),{minItems:1,maxItems:3})),
        entry_id: Type.Optional(Type.String({minLength:1,maxLength:128})),
        turn: Type.Optional(Type.Integer({minimum:1})),
        before_compaction_only: Type.Optional(Type.Boolean()),
        offset: Type.Optional(Type.Integer({minimum:0})),
        limit: Type.Optional(Type.Integer({minimum:1,maximum:50})),
        max_chars: Type.Optional(Type.Integer({minimum:1,maximum:20000})),
      },{additionalProperties:false}),
      async execute(_id, args, signal, _update, ctx) {
        signal?.throwIfAborted();
        const branch = ctx.sessionManager.getBranch();
        const compact = branch.findLast(entry => entry.type === 'compaction');
        const cutoff = compact ? branch.findIndex(entry => entry.id === compact.firstKeptEntryId) : -1;
        let turn = 0;
        const rows = [];
        for (const [index,entry] of branch.entries()) {
          if (entry.type !== 'message') continue;
          const message = entry.message;
          if (message.role === 'user') turn++;
          const role = message.role === 'toolResult' ? 'tool' : message.role;
          if (!['user','assistant','tool'].includes(role)) continue;
          rows.push({entry,turn,role,compacted:cutoff >= 0 && index < cutoff});
        }
        function clean(value) {
          if (typeof value === 'string') return value
            .replace(/data:[^,\s]+;base64,[A-Za-z0-9+/=\s]+/g,'[image/binary omitted]')
            .replace(/[A-Za-z0-9+/]{512,}={0,2}/g,'[binary omitted]');
          if (Array.isArray(value)) return value.map(clean);
          if (value && typeof value === 'object') {
            if (value.type === 'image' || value.type === 'image_url') return '[image omitted]';
            if (value.type === 'thinking') return undefined;
            return Object.fromEntries(Object.entries(value)
              .filter(([key]) => !['thinking','thinkingSignature'].includes(key))
              .map(([key,item]) => [key,
                ['base64','image_base64','imageBytes','image_data'].includes(key) || (key === 'bytes' && Array.isArray(item))
                  ? '[binary omitted]' : clean(item)]));
          }
          return value;
        }
        function text(row) {
          const message = row.entry.message;
          if (typeof message.content === 'string') return redact(clean(message.content));
          return redact((message.content ?? []).filter(part => part.type !== 'thinking').map(part =>
            part.type === 'text' ? clean(part.text) : JSON.stringify(clean(part))).join('\n'));
        }
        const offset = args.offset ?? 0, limit = args.limit ?? 20;
        const budget = args.max_chars ?? 12000;
        const metadata = row => ({entry_id:row.entry.id,turn:row.turn,role:row.role,
          at:row.entry.timestamp,compacted:row.compacted,
          ...(row.role === 'tool' ? {tool_name:row.entry.message.toolName} : {})});
        const scope = args.before_compaction_only ? rows.filter(row => row.compacted) : rows;
        let payload;
        if (args.action === 'outline') {
          const users = scope.filter(row => row.role === 'user');
          const selected = users.slice(offset,offset+limit);
          payload = {items:selected.map(row => ({...metadata(row),user:text(row).slice(0,200),
            tool_calls:rows.filter(item => item.turn === row.turn && item.role === 'assistant')
              .reduce((count,item) => count + (Array.isArray(item.entry.message.content)
                ? item.entry.message.content.filter(part => part.type === 'toolCall').length : 0),0)})),
            ...(offset+selected.length < users.length ? {next_offset:offset+selected.length} : {})};
        } else if (args.action === 'search') {
          if (!args.query?.trim()) throw new Error('search requires a nonempty query');
          const query = args.query.toLowerCase();
          const matches = [];
          for (const row of scope) {
            if (args.roles && !args.roles.includes(row.role)) continue;
            const body = text(row), index = body.toLowerCase().indexOf(query);
            if (index >= 0) matches.push({...metadata(row),snippet:body.slice(Math.max(0,index-120),index+query.length+120)});
          }
          const selected = matches.slice(offset,offset+limit);
          payload = {items:selected,...(offset+selected.length < matches.length ? {next_offset:offset+selected.length} : {})};
        } else {
          const selected = args.action === 'read'
            ? scope.filter(row => row.entry.id === args.entry_id)
            : scope.filter(row => row.turn === args.turn);
          if (!selected.length) throw new Error('Entry or turn is not on the current branch');
          const body = selected.map(row => `[${row.entry.id} ${row.role}${row.role === 'tool' ? ':'+row.entry.message.toolName : ''}]\n${text(row)}`).join('\n\n');
          const page = body.slice(offset,offset+budget);
          payload = {entries:selected.slice(0,20).map(metadata),text:page,
            ...(offset+page.length < body.length ? {next_offset:offset+page.length} : {})};
        }
        signal?.throwIfAborted();
        let output = redact(JSON.stringify(payload));
        while (output.length > 20000) {
          if (payload.items?.length > 1) {
            payload.items.pop(); payload.next_offset = offset+payload.items.length;
          } else if (payload.text?.length > 1) {
            payload.text = payload.text.slice(0,Math.floor(payload.text.length*.75));
            payload.next_offset = offset+payload.text.length;
          } else break;
          output = redact(JSON.stringify(payload));
        }
        return {content:[{type:'text',text:output}]};
      },
    });
  }};
}
