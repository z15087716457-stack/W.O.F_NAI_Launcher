# Prompt blocks

Read `studio_context(scope=draft)` for prompt documents and markers, `block_query(id)` for one library entry, `block_query(kind=tree)` for folders, collections and `library_version`. For a one-off block use `instance_create`; do not create a library entry just to insert it.

## Instances

- Types: `temporary` (has `temp`), `translation`, otherwise a library reference. Library-free instances have `blockId:""`. Missing `needsReview` means false; missing `languageCode` means `zh`.
- Temporary: `title` 1..40 characters; `color` `#RRGGBB`/`#AARRGGBB`; `icon` from the list below; omitted color/icon use native defaults. Only temporary blocks carry content; translations carry `source` (sent to generation) and `zh` (reading only, any `language_code` of `zh`, `zh-TW`, `en`, `ja`, `ko`).
- Create/convert options: `enabled` only. Library-free blocks have no negative side: create a separate block in the negative scope.
- Convert segments need `title` (temporary) or `zh` (translation); the selected text becomes the content/source. A failing segment is reported by number and nothing is written.
- `instance_update`: content edits make that occurrence a temporary block; display fields only on library-free temps; translation edits cannot mix with content. A source-only change marks the reading for review.
- A library-free temp has nothing to revert to: unwrap or promote it. Promote defaults to the temp's title/color/icon.

## Merging and splitting

No dedicated actions; compose them. Each write returns the next `draft_version`, so chain calls without re-reading.

- Merge: update one library-free temp with the combined content/title/icon, then delete the others. If the kept block is a library reference, delete all and create one temp in its place.
- Split: update the block to its first part and create the rest next to it, or unwrap and convert with segments.
- Keep the generation text the same unless the user asked to change it.

## Positioning

`anchor.text` matches the prompt's handwritten text (markers stripped), not block contents; it may touch but not cross a marker. Several matches need zero-based `occurrence`. `offset` is a raw UTF-16 position (never inside an emoji pair); offset and anchor are exclusive.

```json
{"action":"instance_convert","scope":"main","expected_draft_version":"<fresh>","segments":[
  {"anchor":{"text":"rooftop, after rain","mode":"replace"},"kind":"temporary","instance":{"title":"Setting","icon":"city"}},
  {"anchor":{"text":"soft lighting","mode":"replace"},"kind":"translation","translation":{"zh":"柔和光照"}}
]}
```

## Library

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
