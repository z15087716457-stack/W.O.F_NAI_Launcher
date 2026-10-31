# Prompt blocks

Read documents/markers with `studio_context(scope=draft)`, library entries with `block_query(id)`, folders/collections with `block_query(kind=tree)`.

Scopes: `main`, `negative`, `char:<ID>:pos|neg`. Versions: `expected_version` from `block_query(id)` for update/delete/insert; `expected_library_version` from `block_query(kind=tree)` for folder/collection writes, block_reorder and instance_promote; `expected_draft_version` from `studio_context(scope=draft)` for insert and instance actions.

## Instances

- `instance_create`: `kind=temporary` with `instance.title/content`, or `kind=translation` with `translation.source/zh`. Place by `anchor` (before/after) or `offset`; default append. `instance_convert` uses 1..64 segments with replace anchors, preserving generation text in one undo.
- Types: `temporary` (has `temp`), `translation`, otherwise a library reference. Library-free instances have `blockId:""`. Missing `needsReview` means false; missing `languageCode` means `zh`.
- Temporary fields: `title`, `color`, `icon` (keys below); omitted color/icon use native defaults. Translations carry `source` (sent to generation) and `zh` (reading only), with `language_code` from the schema.
- Temporary blocks accept `instance.translations:[{source,zh,language_code?}]`, usually one whole-content translation. Sources match complete substrings in content order; empty arrays clear readings. Conversion preserves complete translation blocks, content edits retain matching readings, promotion preserves the combined reading.
- Create/convert options: `enabled` only. Library-free blocks have no negative side: create a separate block in the negative scope.
- Convert segments need `title` (temporary) or `zh` (translation); selected text fills content/source.
- `instance_update`: content edits change that occurrence into a temporary block, leaving the library entry intact. Display fields apply to library-free temps; translation and content edits are separate. Source-only changes mark readings for review.
- `instance_unwrap` expands the generation text; `instance_delete` removes the occurrence. `instance_promote` saves a temporary block to the library, defaulting to its title/color/icon.

## Merging and splitting

No dedicated actions; compose them. Each write returns the next `draft_version`, so chain calls without re-reading.

- Merge: update one library-free temp with the combined content/title/icon, then delete the others. If the kept block is a library reference, delete all and create one temp in its place.
- Split: update the block to its first part and create the rest next to it, or unwrap and convert with segments.
- Keep the generation text the same unless the user asked to change it.

## Positioning

`instance_convert` to temporary blocks also matches the source text of existing translation blocks and must include them completely. Otherwise `anchor.text` matches the prompt's handwritten text (markers stripped), not block contents; it may touch but not cross a marker. Several matches need zero-based `occurrence`. `offset` is a raw UTF-16 position (never inside an emoji pair); offset and anchor are exclusive.

```json
{"action":"instance_convert","scope":"main","expected_draft_version":"<fresh>","segments":[
  {"anchor":{"text":"rooftop, after rain","mode":"replace"},"kind":"temporary","instance":{"title":"Setting","icon":"city","translations":[{"source":"rooftop, after rain","zh":"雨后的屋顶"}]}},
  {"anchor":{"text":"soft lighting","mode":"replace"},"kind":"translation","translation":{"zh":"柔和光照"}}
]}
```

## Library

`create(changes.title/content)`, `update(id, changes)`, `delete(id)` and `insert(id)` manage entries and insert them into a prompt.

`changes.generationSettings`: model, width, height, steps, scale, sampler, noiseSchedule, cfgRescale, qualityPreset (`standard/light/none`), ucPreset (`0/1/2/3/7/8/9`), qualityCustomBlockId/ucCustomBlockId (library IDs replacing native presets). Content edits clear obsolete atom pools unless new atoms are given.

Folders/collections: create/update with `changes.name/parentId/sortOrder` (collection_create also `isFolder`); `parent_id` null = root; reorders take every sibling in `ordered_ids`; folder_delete needs an empty folder; collection_delete keeps the blocks; collection_add/remove take `id` + `block_id`.

## Errors

- `anchor_missing` / `anchor_ambiguous` / `anchor_crosses_marker`: pick another anchor or occurrence.
- `overlapping_segments` / `projection_changed`: conversion must keep the generation text identical.
- `unsupported_kind` / `unsupported_bundle`: wrong block type, or negative content on a library-free block.
- `*_conflict`: re-read and retry with the new version. `busy` / `closed`: do not write.
- `pill_conflict` from prompt_update: the lane contains blocks; edit it here instead.

## Temporary icon keys

`palette`, `brush`, `draw`, `color_lens`, `image`, `photo`, `filter`, `person`, `face`, `groups`, `heart`, `star`, `bolt`, `fire`, `sparkle`, `moon`, `sun`, `cloud`, `snow`, `landscape`, `city`, `home`, `park`, `beach`, `forest`, `dress`, `diamond`, `cake`, `food`, `game`, `music`, `pets`, `book`, `science`, `school`, `car`, `flight`, `shield`, `build`, `tag`.
