# Source images and references

## reference_manage (current draft)

Manages the current source image, mask, inpaint area, Vibe and precise references. Source image and mask work on every image model. Vibe Transfer works on V4 / V4.5 (not V5). Precise Reference works on V4.5 and V5 (Full / Curated); V5 adds `outfit` type (`costume` in API), optional `prefer_same_outfit` on `character` / `characterAndStyle`, strength up to `5.0`, and removes Fidelity (always 1.0). V5 inpainting does not yet support Precise Reference, and adding/enabling Precise Reference on V5 Turbo switches back to V5 Full. Unsupported actions return `reference_unsupported`. Call `list` first: it returns current indices, `draft_version`, capabilities, and `draft:*` image IDs for `image_read`. Writes need `expected_draft_version`, back up the full configuration and use native workflows. Vibe encoding is deferred until generation.

## reference_library (reusable library)

`query` / `read` / `apply` / `import` / `save` / `export` / `update` / `delete`, plus Vibe categories. `update`/`delete` need `expected_entry_version`; category writes need `expected_category_version`. `apply` needs `expected_entry_version` and `expected_draft_version`. Import and export keep original files. Missing files, capacity limits and partial commits are reported in the result.
