# Source images and references

## reference_manage (current draft)

Manages the current source image, mask, inpaint area, Vibe and precise references. Call `list` first: it returns current indices, `draft_version` and `draft:*` image IDs for `image_read`. Writes need `expected_draft_version`, back up the full configuration and use native workflows. Configuration never generates or performs paid encoding.

## reference_library (reusable library)

`query` / `read` / `apply` / `import` / `save` / `export` / `update` / `delete`, plus Vibe categories. Read versions before changing entries or categories; `apply` also needs the current draft version. Import and export keep original files. Missing files, capacity limits and partial commits are reported in the result. Never issue paid encoding on your own.
