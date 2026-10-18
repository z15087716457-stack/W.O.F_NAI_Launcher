# Image tools and source generation

## image_tool

- Local: `list` reads installed, bundled and custom models, methods, scales and SeedVR2 defaults; it never downloads. `upscale(model_id, scale=1..4, image_id | path)` uses original pixels and native locks; output goes to a fresh workspace `outputs/` folder with source metadata and a history image_id when Studio is idle. It never changes the draft or current display. `status` / `cancel(job_id)` only for this chat's job.
- `pixel_snap` runs locally for zero Anlas using native `paletteMode`, `colors`, `avoidOverRefining` and upscale options.
- Cloud director tools and cloud 2x upscale: `prepare` freezes source, tool, prompt, defry/emotion, account and native price without requests; `run(quote_id)` waits for a visible user button and rechecks account, price and balance. Results include all variants.
- Never install models or switch the user's chosen method automatically.

## image_generate

`prepare` / `run` / `status` / `cancel`. Official variations make three images from the source, using its NAI metadata when present. Enhance freezes current prompts and native magnitude, scale and Max settings. Takes an original `image_id` or workspace path. It does not import the source into the draft and does not reroll user blocks. Price confirmation, native canvas/history and workspace originals/results apply.
