/// Actual production bindings. Node schemas are verified against these names
/// by the host integration test; candidates never appear in settings or maps.
const naiAgentToolNames = [
  'studio_context',
  'image_read',
  'prompt_update',
  'snapshot',
  'wiki_query',
  'tag_query',
  'block_query',
  'block_manage',
  'settings_read',
  'settings_update',
  'explore_manage',
  'generation_prepare',
  'generation_run',
  'generation_cancel',
  'gallery_query',
  'gallery_manage',
  'reference_manage',
  'reference_library',
  'image_tool',
  'image_generate',
  'ask_user',
  'read',
  'write',
  'edit',
  'bash',
];
const naiAgentDefaultToolNames = [
  'read',
  'write',
  'edit',
  'bash',
  'studio_context',
  'ask_user',
  'codemode',
];
const naiAgentToolMap = '''Tool map:
- Current draft/parameters/selected image: studio_context (scope=draft for raw fields and field_versions).
- See pixels or workspace images: image_read. For original attachment metadata only, use its message path with metadata_only=true; this returns no pixels and requires no vision.
- Change draft: prompt_update using the versions just read; inspect returned readback.
- Workspace files/manuals: read, write, edit, bash. Read NAI manuals only when needed.
- Generation configuration: snapshot (save/list/read/load). Explicit load requires current draft_version and backs up images, references, pills, presets and native image workflow settings.
- Local encyclopedia source text: wiki_query; page long articles with offset/limit. include_examples=true for one tag discovers official illustrations; pass returned wiki:* image_id to image_read.
- Find canonical tags, aliases, category/count and cached short definitions: tag_query (English tag query; local indexes only).
- Prompt block library: block_query (tree/search/id).
- Edit blocks/instances and organize their library: block_manage. Block edits use expected_version; folder_*/collection_* and block_reorder require library_version from block_query(kind=tree). Use draft documents for instance markers and raw offsets.
- Public application preferences: settings_read returns values, groups, allowed_keys and version; credentials, accounts, paths and model bindings are excluded.
- Change public preferences: settings_update(changes, expected_version from settings_read). Validates native values, saves a workspace backup and refreshes Settings providers.
- Style exploration: explore_manage (list/read/create/rename/complete/heart/folder_*/candidate_move; prepare/run/status/pause/cancel). Native runner rolls blocks; paid starts require visible price/balance confirmation. Only this chat owns pause/cancel; explore:* image IDs use image_read.
- Generation price/account/batch: generation_prepare. No network request or generation; defaults to current Studio configuration.
- Generate: generation_run (quote_id); waits for a real user button and then native completion. Model text/flags never authorize. Changed/expired quotes and replay are rejected.
- Stop this chat's admitted generation: generation_cancel (optional run_id); newer/manual runs are protected. Agent Stop also cancels its running generation tool.
- Find actual pictures: gallery_query (scope=history/library; image_id for detail). Library queries reuse local filters and return gallery:<ID> for image_read, without changing visible filters. Indexing may leave image_id null; retry after indexing.
- Manage pictures/collections/files: gallery_manage (read/update/delete/export; trash/restore; collections and collection_*; folders and folder_*; move_file/copy_file). Read current image/collection/folder versions before writes. File transfer uses a library image and folders.file_path as target_folder. Native external moves ask the user; backups stay in workspace outputs.
- Source/mask/Vibe/precise setup: reference_manage. list returns current indices, draft_version and draft:* image IDs for image_read. Writes require expected_draft_version, back up full configuration and use native workflows; no generation or paid encoding.
- Reusable references: reference_library (query/read/apply/import/save/export/update/delete; Vibe categories). Read versions before changing entries/categories; apply also needs draft_version. Changes back up native files/settings; no hidden encoding or generation.
- Image processing: image_tool. Local upscale uses list/upscale; pixel_snap is local. Cloud tools use prepare then run(quote_id), waiting for a real user confirmation with price/balance. Original image_id or workspace path; outputs/history preserve source metadata and current draft/display. status/cancel owns only this chat's job. No automatic downloads.
- Source generation: image_generate (prepare/run/status/cancel). Official variations make three images using source metadata when present; enhance freezes current prompts and native magnitude/scale/Max settings. Original image_id or workspace path; no draft import or block rerolls. Real price/balance confirmation, native canvas/history and workspace originals/results.
- Clarify missing inputs/preferences: ask_user; wait for its answer.''';
