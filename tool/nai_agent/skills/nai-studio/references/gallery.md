# Gallery and history

`gallery_query(scope=history|library)` finds real pictures (default `limit=30`). Library queries reuse local filters and return `gallery:<ID>` for `image_read`. Unindexed items may have a null `image_id`.

## Images and collections

- `gallery_manage(action=read)` returns `image_version`; image writes/export need `expected_image_version`. Library `update` sets desired `changes.favorite`/replacement `changes.tags`; unfavorite removes all memberships. History `delete` removes pin/preview/history but keeps saved files. Library `delete` schedules startup cleanup; `trash`/`restore` use the native pool, and restore needs existing pixels.
- Collections default to `scope=library`. `collections` pages the tree and returns `collection_version`; `collection_members` pages leaf/folder descendant image IDs. Writes need `expected_collection_version`.
- `collection_create` uses `changes.name/parent_id/is_folder`; `collection_update` uses `changes.name/parent_id`. `collection_delete` accepts a leaf or empty folder. `collection_reorder` needs `parent_id` and every sibling once in `ordered_collection_ids`. Collection type is fixed; folders are logical favorite groups.
- `collection_add`/`collection_remove` take a leaf `collection_id` and 1..20 `image_ids`. Adding sets favorite; removing/deleting membership keeps favorite and originals.

## Physical folders and files

- `folders` pages the native catalog, returning `root_path`, `folder_version` and each folder's `file_path`. Writes use `scope=library` and `expected_folder_version`. `folder_sync` synchronizes the catalog with disk; re-read `folders` afterward.
- `folder_create`: `changes.name` and `parent_id`; `folder_rename`: `folder_id/changes.name`; `folder_move`: `folder_id/parent_id` (null=root); `folder_delete_empty`: `folder_id`. Root/external trees are read-only; deletion requires an empty folder. Relocation preserves index IDs, favorites, tags, memberships and pending deletion paths.
- `move_file`/`copy_file` require a library `image_id`, `expected_image_version` and existing absolute `target_folder` (from `folders.file_path`). Moves keep the image ID; copies create a file/index without custom tags/favorite. Results report collision filenames; indexing may leave `image_id=null`. External source/target moves require user confirmation; native protection settings may also prompt.

## Backups and partial results

Native file operations use the scan lock. Transfers back up original pixels first. Collection backups contain tree/members; `folder_sync` backs up the catalog, while other folder writes snapshot catalog/entries/deletion pool rather than the image tree. Backups stay in workspace `outputs/`. Partial commits return `ok=false`, `applied_fields` and `backup`; inspect these and re-read affected state before retrying.
