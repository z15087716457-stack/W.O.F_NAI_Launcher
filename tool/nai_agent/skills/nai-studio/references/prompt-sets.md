# Prompt cards

- `create` takes `kind`, `kind_icon`, `title`, `unit`, `ordered` and `items` (1–24 complete cards).
- `read` takes `set_id` and returns the cards and current `revision`.
- `update` takes `set_id`, `expected_revision` and either a complete replacement `card` with its existing `card_id`, or all the `create` fields to replace the set. Images follow `card_id` across edits and reordering.

Importing a card replaces the draft’s main prompt, negative prompt and character list as a whole: an empty or missing `main`, `negative` or `characters` clears that part of the draft. When a card should only vary part of the draft (for example outfits), copy the current main and negative text into every card and change only what differs.

Each card has its own cast. Character negatives and positions align with `characters` by index. With `use_coords: true`, centers use 0–1 coordinates from the top left and entries may be null. With `false`, the model chooses placement.

Import with settings applies the keys present in `generation`. [AI TAG page metadata](gallery.md) uses the same format.
