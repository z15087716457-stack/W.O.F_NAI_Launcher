# Gallery and history

- `gallery_query(scope=history|library)` finds real pictures. Library queries reuse local filters and return `gallery:<ID>` for `image_read`, without changing the user's visible filters or scroll position. During indexing `image_id` may be null; retry later and never invent images.
- `gallery_manage`: `read` / `update` / `delete` / `export`; `trash` / `restore`; collections and `collection_*`; folders and `folder_*`; `move_file` / `copy_file`. Read the current image, collection or folder version before any write.
- Deleting history removes the record but keeps saved originals. Library deletion goes through the native trash and cleanup flow.
- Collections are logical. Physical folder moves and copies go through the scan lock and native file operations and may partially commit; a file transfer uses a library image and `folders.file_path` as `target_folder`. External moves ask the user for real confirmation. Backups stay in workspace `outputs/`.
- Never move the picture library with bash to bypass the gallery service.
