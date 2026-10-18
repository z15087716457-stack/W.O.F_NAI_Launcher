# Prompt blocks

- `block_query(kind=tree|search|id)` reads folders, collections and entries.
- `block_manage` edits blocks and instances and organizes the library. Entry edits use `expected_version`; `folder_*`, `collection_*` and `block_reorder` need the `library_version` from the latest `block_query(kind=tree)`.
- Saving to the library and inserting into the current prompt are different actions; pick the one the user asked for.
- Instance markers and raw offsets come from the current draft document returned by `studio_context(scope=draft)`.
