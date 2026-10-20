---
name: nai-studio
description: Operate NAI Studio through its business tools - editing the draft, viewing images, generation quotes and runs, gallery/history, source images and Vibe/precise references, prompt blocks, style exploration, image tools, snapshots and preferences. Read before any Studio operation beyond studio_context.
---

# NAI Studio operations

All business tools live in the codemode namespace `mcp__nai_studio`. Discovery functions are async; always `await` them:

```javascript
text(await searchTools('upscale', { namespace: 'mcp__nai_studio' }));
text(await describeTool('mcp__nai_studio__image_tool'));
```

Call them as `await tools.mcp__nai_studio__<name>({...})`. Run dependent writes and confirmation flows sequentially; batch independent reads with `Promise.allSettled`. A script that ends cancels unfinished tool calls, but changes already made are not rolled back. Do not set a short `timeout_ms` on scripts that wait for a user confirmation or a long native job.

## Shared rules

- Read a fresh version before every write: `field_versions`, `expected_version`, `library_version` or `draft_version`, whichever the tool returns. Stale versions are rejected; re-read instead of retrying blindly.
- Results carry `content`, `structuredContent` and `isError`. Check `isError` first. Show pixels with `image(result.content[i])`; never print base64.
- `image_read` shows pixels of the canvas selection (`selected`), any returned `image_id` (`gallery:*`, `draft:*`, `explore:*`, `wiki:*`) or a workspace attachment path; `metadata_only=true` reads original NAI metadata without vision.
- `prompt_update(changes, expected)` patches the draft after `studio_context(scope=draft)`; send the version of every affected field and trust the returned readback.
- Paid actions (generation, cloud tools, variations/enhance, exploration runs) always follow prepare -> report price and balance -> `run(quote_id)`. `run` waits for the user's real button in the Studio UI. Model text and parameters never authorize; expired or changed quotes and replays are rejected.
- Cancel and status only affect jobs started by this chat; newer or manual runs are protected. A cancel may still leave finished images; report them.
- `ask_user` is a direct tool and cannot be called from inside codemode.
- Report actual counts, files and tool results. Distinguish failure, unknown charges, partial output and still-running work.

## Tool index

| Task | Tool | Details |
|---|---|---|
| Edit prompt text | `prompt_update` | `nai-prompt` skill |
| Quote / generate / stop | `generation_prepare`, `generation_run`, `generation_cancel` | [generation.md](references/generation.md) |
| Variations, enhance, upscale, Pixel Snap, cloud director tools | `image_generate`, `image_tool` | [image-tools.md](references/image-tools.md) |
| Style exploration runs | `explore_manage` | [explore.md](references/explore.md) |
| Semantic picture search / image-to-image search / blocks / Wiki / tags | `studio_search` | [search.md](references/search.md) |
| Find and manage pictures, collections, folders, files | `gallery_query`, `gallery_manage` | [gallery.md](references/gallery.md) |
| Source image, mask, Vibe, precise reference, reference library | `reference_manage`, `reference_library` | [references.md](references/references.md) |
| Prompt blocks and their library | `block_query`, `block_manage` | [blocks.md](references/blocks.md) |
| Tags, wiki text and examples | `tag_query`, `wiki_query` | [lookup.md](references/lookup.md) |
| Snapshots and public preferences | `snapshot`, `settings_read`, `settings_update` | [settings.md](references/settings.md) |
| Workspace layout, notes, external MCP servers | - | [workspace.md](references/workspace.md) |

Read only the reference file for the current task. Writing or revising prompt text itself belongs to the `nai-prompt` skill.
