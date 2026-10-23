# V4 / V4.5 and earlier

Confirm the full model ID and workflow with `studio_context` first. This is the V4 family entry; do not carry V5 prompt or API rules over here.

- For V4/V4.5, favor tag-based prompts.
- Edit main/negative prompts, characters, size, seed, sampler and reference settings through the current native fields. Character positions, enabled items, prompt text and block source come from the actual `scope=draft` structure.
- Do not write translated text or the effective preset projection back as the raw draft. Do not fill parameters the current service does not support from old chats.
- Composition and tag suggestions can be checked with `tag_query` / `wiki_query`; look at the user's source with `image_read`.
- Img2img, Vibe and precise reference support follows the current `reference_manage` state; cost and eligibility follow `generation_prepare`.
- For detailed creative rules, read material the user explicitly provided in the workspace, or verify against official docs with available network tools. This package does not import the developer's private creative handbook. State limits you cannot verify.
