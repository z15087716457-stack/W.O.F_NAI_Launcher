# Gallery and history

`gallery_query(scope=history|library)` finds real pictures (default `limit=30`). Library queries reuse local filters and return `gallery:<ID>` for `image_read`. Unindexed items may have a null `image_id`.

## Images and collections

- `gallery_manage(action=read)` returns `image_version`; image writes/export need `expected_image_version`. Library `update` sets desired `changes.favorite`/replacement `changes.tags`; unfavorite removes all memberships. History `delete` removes pin/preview/history but keeps saved files. Library `delete` schedules startup cleanup; `trash`/`restore` use the native pool, and restore needs existing pixels.
- Collections default to `scope=library`. `collections` pages the tree and returns `collection_version`; `collection_members` pages leaf/folder descendant image IDs. Writes need `expected_collection_version`.
- `collection_create` uses `changes.name/parent_id/is_folder`; `collection_update` uses `changes.name/parent_id`. `collection_delete` accepts a leaf or empty folder. `collection_reorder` needs `parent_id` and every sibling once in `ordered_collection_ids`. Collection type is fixed; folders are logical favorite groups.
- `collection_add`/`collection_remove` take a leaf `collection_id` and 1..20 `image_ids`. Adding sets favorite; removing/deleting membership keeps favorite and originals.

## Physical folders and files

- `folders` pages the native catalog, returning `root_path`, `folder_version` and each folder's `file_path`. Writes use `scope=library` and `expected_folder_version`. `folder_sync` synchronizes the catalog with disk; re-read `folders` afterward.
- `folder_create`: `changes.name` and `parent_id`; `folder_rename`: `folder_id/changes.name`; `folder_move`: `folder_id/parent_id` (null=root). Relocation preserves index IDs, favorites, tags, memberships and pending deletion paths. Root/external category trees are read-only.
- `folder_delete_empty` takes one `folder_id` or 1..50 unique `folder_ids`, plus `expected_folder_version`. It accepts empty directories or selected parent/child trees containing only selected directories, processed deepest-first.
- `move_file`/`copy_file` take exactly one form: legacy `image_id` + `expected_image_version`, or 1..50 unique library `image_ids` + `expected_image_versions` mapping EVERY ID to its version from `read`. Both need existing absolute `target_folder` (from `folders.file_path`); never mix forms. Moves preserve ID/tags/favorite/memberships. Copies retain sources but create new files/index IDs without custom tags/favorite. Name collisions use native safe renaming.
- Each call asks at most ONE Studio confirmation: external moves always ask; protection also gates internal moves, copies and empty-folder deletion. Items already at the target return in `unchanged_ids`; a wholly unchanged batch needs no confirmation.

### Recommended reorganization workflow

Read folders and affected image versions, group by destination, then issue one batch `move_file` per target folder (up to 50 images). Re-read folders afterward and call `folder_delete_empty(folder_ids=[...], expected_folder_version=...)` once for the emptied folders.

## Backups and partial results

Transfers back up originals and return source/destination paths, image IDs, updated versions and `backups`. `indexing_ids` identifies source images whose copies still await indexing.

Transfers stop at the first failure. If nothing applied, the tool throws; otherwise `ok:false` includes `completed`, `failed_image_id`, `remaining_image_ids` and `backups`. Completed items can include physical transfers whose indexing failed. Read actual source/destination state before retrying. Moves support UI undo; copies do not.

Collection backups contain the tree/members; `folder_sync` backs up the catalog. Folder deletion returns `folder_ids`, `count`, `backup` and `applied_fields`; partial results use `deleted_folder_ids`, `failed_folder_id` and `remaining_folder_ids`. Read the current disk/catalog before continuing. Backups stay in `.W.O.F/outputs/`.
