# Image tools and source generation

## image_tool

- Local `list` reads installed/bundled/custom models, methods, scales and SeedVR2 defaults. `upscale` takes `model_id`, `scale=1..4` and one `image_id` or workspace-relative `path`. Original pixels and native locks apply; outputs include source metadata, a workspace `outputs/` folder and history `image_id` when Studio is idle. Draft/display stay unchanged. `status`/`cancel(job_id)` target this chat's job.
- `pixel_snap` runs locally for zero Anlas using `pixel.paletteMode/colors/avoidOverRefining/upscale`.
- Cloud director tools and `cloud_upscale`: `prepare` freezes source, tool, prompt, defry/emotion, account and price; `run(quote_id)` returns all variants.

## image_generate

`prepare`/`run`/`status`/`cancel` use one original `image_id` or workspace-relative `path`. `operation=variations` makes three images, projecting source NAI metadata with current prompts as fallback. `operation=enhance` uses current composed prompts/references and native magnitude, scale and Max settings. Native canvas/history and workspace originals/results apply; the Studio draft stays unchanged.
