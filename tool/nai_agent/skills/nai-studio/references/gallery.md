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
- `folder_delete_empty` takes exactly one of legacy `folder_id` or 1..50 unique `folder_ids`, plus `expected_folder_version`. Selected parent/child folders are deleted deepest-first; every directory entry must be a selected child directory. Files (including hidden files) and unselected children reject the entire call before confirmation. Non-empty deletion is not supported.
- `move_file`/`copy_file` take exactly one form: legacy `image_id` + `expected_image_version`, or 1..50 unique library `image_ids` + `expected_image_versions` mapping EVERY ID to its version from `read`. Both need existing absolute `target_folder` (from `folders.file_path`); never mix forms. Moves preserve ID/tags/favorite/memberships. Copies retain sources but create new files/index IDs without custom tags/favorite. Name collisions use native safe renaming.
- Each call asks at most ONE Studio confirmation: external source/target moves always ask; protection also gates internal moves, copies and empty-folder deletion. Confirmation lists at most five items plus a remainder count. Move items already in the target are skipped (`unchanged_ids`); an entirely unchanged batch does not ask.

### Recommended reorganization workflow

Read folders and all affected image versions, group images by destination, then issue one batch `move_file` per target folder (split only at 50). Re-read folders after moving images out, then issue one `folder_delete_empty(folder_ids=[...], expected_folder_version=...)` for all emptied folders (including selected parents/children). Never loop single-image calls or attempt recursive/non-empty deletion.

## Backups and partial results

Native transfers use the scan lock per image and back up original pixels before transferring. Batch preflight checks all versions/files/targets before asking, retains no batch pixel buffers, then re-reads and checks each item before applying it. Batch results contain `count`, `image_ids` (moved IDs or known new copy IDs), `source_image_ids`, `source_paths`/`file_paths` keyed by source ID, `image_versions` (moves), `unchanged_ids`, `indexing_ids` (source IDs whose copies await indexing), `backups:[{image_id,path}]` and `applied_fields`. Legacy single results are unchanged.

Stop on the first failure; do not blindly retry. If nothing applied, the tool throws. After application, batch transfers return `ok:false`, `error/message`, `completed` (the aggregate fields for applied items, including a physically transferred item whose bookkeeping failed), `failed_image_id`, unattempted `remaining_image_ids` and all `backups`. Re-read actual sources/destinations before retrying. UI undo checks every moved version and original path first, then batches reverse moves by original folder; copies are not undoable.

Collection backups contain tree/members; `folder_sync` backs up the catalog. Batch folder deletion uses one backup containing `folders:[{id,old_path,entries}]`, categories and deletion pool, not image trees. It rechecks listings/catalog, deletes deepest-first and saves the catalog once even after partial deletion. Success returns `folder_ids` in deletion order, `count`, `backup`, `applied_fields`; partial results return `deleted_folder_ids`, `failed_folder_id`, `remaining_folder_ids`, `backup` and `applied_fields`. Re-read disk/catalog before retrying. Backups stay in workspace `outputs/`.
