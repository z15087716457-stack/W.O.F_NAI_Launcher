---
name: nai-prompt
description: Write or revise NovelAI prompts in the Studio draft - main/negative prompts, characters, blocks and weights - following the rules of the current model (V4/V4.5 or V5). Read before changing prompt text.
---

# Writing NAI prompts

1. Call `studio_context(scope=draft)` and note the full model ID, workflow, raw editable fields, characters, block documents and `field_versions`.
2. Read the reference for the model family:
   - V4 / V4.5 and earlier: [models-v4.md](references/models-v4.md)
   - V5 / N5 (`nai-diffusion-5*`): [models-v5.md](references/models-v5.md)
3. Edit with `await tools.mcp__nai_studio__prompt_update({ changes, expected })` in codemode, using each affected field's version. Use the returned readback as the result.

## Rules for every model

- Write raw draft fields; translations, presets and expanded blocks are generation projections. Preserve existing blocks, translation originals, enabled states and character positions unless asked to change them.
- Lanes containing blocks accept only unchanged text through `prompt_update` (`pill_conflict` otherwise). Edit their blocks with `block_manage` instance actions; see nai-studio references/blocks.md.
- Use `tag_query` / `wiki_query` for tag meanings and `image_read` for the user's images; see nai-studio references/lookup.md.
- Read image/mask/reference support from `reference_manage`, price and eligibility from `generation_prepare`. For model-specific rules beyond tool results, use workspace material or official documentation and identify unverified limits.
