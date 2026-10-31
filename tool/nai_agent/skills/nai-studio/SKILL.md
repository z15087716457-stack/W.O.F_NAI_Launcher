---
name: nai-studio
description: Operate NAI Studio drafts, images, generation, semantic search, gallery/history, references, prompt blocks, style exploration, image tools, snapshots and preferences. Read before Studio operations beyond studio_context.
---

# NAI Studio operations

Use codemode namespace `mcp__nai_studio`. Discovery and tool calls are async:

```javascript
text(await searchTools('upscale', { namespace: 'mcp__nai_studio' }));
text(await describeTool('mcp__nai_studio__image_tool'));
```

Call `await tools.mcp__nai_studio__<name>({...})`. Serialize dependent writes; batch independent reads with `Promise.allSettled`. Ending a script cancels unfinished calls, not completed writes. Avoid short `timeout_ms` for confirmation or native jobs.

## Shared rules

- Check `isError`; results carry `content` and `structuredContent`. Display pixels with `image(result.content[i])`.
- `image_read` accepts an `image_id` (including `selected`) or workspace-relative image path; `metadata_only=true` reads original dimensions/metadata without vision.
- Writes use versions from the last read (`field_versions`, `expected_version`, `library_version` or `draft_version`); use the returned readback and next version. On conflict, read the affected state before retrying.
- Quoted generation/cloud actions: prepare -> report price and balance -> `run(quote_id)`, with user confirmation in Studio.
- `ask_user` is a direct tool, outside codemode. Report actual outputs, partial results and unresolved status.

## Tool index

| Task | Tool | Details |
|---|---|---|
| Story / outfit / variation prompt sets | `prompt_set` | [prompt-sets.md](references/prompt-sets.md) |
| Edit prompts | `prompt_update` | `nai-prompt` skill |
| Quote / generate / stop | `generation_prepare`, `generation_run`, `generation_cancel` | [generation.md](references/generation.md) |
| Variations, enhance, upscale, Pixel Snap, cloud tools | `image_generate`, `image_tool` | [image-tools.md](references/image-tools.md) |
| Style exploration | `explore_manage` | [explore.md](references/explore.md) |
| Semantic gallery / blocks / Wiki / tags search | `studio_search` | [search.md](references/search.md) |
| Pictures, collections, folders and files | `gallery_query`, `gallery_manage` | [gallery.md](references/gallery.md) |
| Source, mask, Vibe and precise references | `reference_manage`, `reference_library` | [references.md](references/references.md) |
| Prompt blocks and library | `block_query`, `block_manage` | [blocks.md](references/blocks.md) |
| Tags, related tags, Wiki text and examples | `tag_query`, `tag_related`, `wiki_query` | [lookup.md](references/lookup.md) |
| Snapshots and preferences | `snapshot`, `settings_read`, `settings_update` | [settings.md](references/settings.md) |
| Workspace, notes and external MCP servers | - | [workspace.md](references/workspace.md) |

Read the reference for the current task; use `nai-prompt` for prompt writing.
