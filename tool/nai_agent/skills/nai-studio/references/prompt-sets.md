# Prompt cards

- `create` takes `kind`, `kind_icon`, `title`, `unit`, `ordered` and `items` (1–24 complete cards).
- `read` takes `set_id` and returns the cards and current `revision`.
- `update` takes `set_id`, `expected_revision` and either a complete replacement `card` with its existing `card_id`, or all the `create` fields to replace the set. Images follow `card_id` across edits and reordering.

Each card has its own cast. Importing `characters: []` clears the draft’s characters. Character negatives and positions align with `characters` by index. With `use_coords: true`, centers use 0–1 coordinates from the top left and entries may be null. With `false`, the model chooses placement.

Import with settings applies the keys present in `generation`. [AI TAG page metadata](gallery.md) uses the same format.
