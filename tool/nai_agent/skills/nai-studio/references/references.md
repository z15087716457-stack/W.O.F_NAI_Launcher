# Source images and references

## reference_manage (current draft)

Manages the current source image, mask, inpaint area, Vibe and precise references. Call `list` first: it returns current indices, `draft_version` and `draft:*` image IDs for `image_read`. Writes need `expected_draft_version`, back up the full configuration and use native workflows. Vibe encoding is deferred until generation.

## reference_library (reusable library)

`query` / `read` / `apply` / `import` / `save` / `export` / `update` / `delete`, plus Vibe categories. `update`/`delete` need `expected_entry_version`; category writes need `expected_category_version`. `apply` needs `expected_entry_version` and `expected_draft_version`. Import and export keep original files. Missing files, capacity limits and partial commits are reported in the result.
