# V5 / N5

For the `nai-diffusion-5` family. Check the full model ID, current workflow and native capabilities with `studio_context` first. Do not apply V4/V4.5 rules or guess support from tag names.

- The user's current parameters are the basis of the task. Write raw main/negative prompts and characters only through the fields and versions returned by `scope=draft`; keep blocks, translation originals and enabled states. The effective preset projection never overwrites editor text.
- Source image, mask and reference support follows the current `reference_manage` configuration and model capabilities. Do not assume the old samplers, weight syntax, quality tags, character positions or Vibe encoding parameters are identical in V5. For specific rules, read user-provided V5 material or verify official docs with available network tools; state unverified limits.
- Generation and enhance costs come from native prepare; runs need visible confirmation. Model names and server capabilities may differ; do not substitute old model prices or inferred eligibility for the check.

## V5 Full Turbo

- Turbo (official Medium Effort) uses `nai-diffusion-5-full-medium`; inpainting uses `nai-diffusion-5-full-medium-inpainting`. Read `model_constraints` for current limits: fixed 14 steps, Euler Ancestral, Heavy negative preset; custom main/character negative prompts and CFG Rescale are not supported; guidance strength stays adjustable. The UI shows the Full family name together with the lightning toggle; do not judge by the capsule name alone.
- Turbo's fixed settings are projected only into quotes and requests. `scope=draft` / `draft_summary` may still hold the original steps, sampler and negative content kept for switching back to Full. Do not rewrite them to match the fixed values. Actual parameters, price and eligibility come from `generation_prepare`. 14 steps in an image alone does not prove Turbo.
