---
name: nai-prompt
description: Write or revise NovelAI prompts in the Studio draft - main/negative prompts, characters, blocks and weights - following the rules of the current model (V4/V4.5 or V5). Read before changing prompt text.
---

# Writing NAI prompts

1. Call `studio_context(scope=draft)` and note the full model ID, workflow, raw editable fields, characters, block documents and `field_versions`.
2. Read the reference for the model family:
   - V4 / V4.5 and earlier: [models-v4.md](references/models-v4.md)
   - V5 / N5 (`nai-diffusion-5*`): [models-v5.md](references/models-v5.md)
3. Edit with `await tools.mcp__nai_studio__prompt_update({ changes, expected })` in codemode, sending the version of every affected field. Inspect the returned readback; it is the actual result.

## Rules for every model

- Edit only the raw fields from `scope=draft`. Translations, presets and expanded blocks produce an effective projection for generation; never write that projection back into the editor, or blocks and characters are lost.
- Keep existing blocks, original text of translations, enabled states and character positions unless the user asked to change them.
- A lane that contains blocks only accepts unchanged text through `prompt_update` (`pill_conflict` otherwise); edit, convert, merge or split its blocks with `block_manage` instance actions (nai-studio references/blocks.md).
- Check tag meanings with `tag_query` / `wiki_query` (see the `nai-studio` skill, references/lookup.md) and look at the user's images with `image_read` (same namespace) before suggesting composition changes.
- Do not fill unsupported parameters from old chats. Support for source images, masks and references comes from `reference_manage`; price and eligibility come from `generation_prepare`. Never assume a size or setup is free.
- If a model limit cannot be verified from tool results, user-provided workspace material or available network tools, say so instead of guessing.
