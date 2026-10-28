# Prompt blocks

For a one-off prompt, use `instance_create`, not a library create followed by insert. Saving a library entry and inserting it are separate operations. Read `studio_context(scope=draft)` for documents and markers; `block_query(id)` for an entry/version; `block_query(kind=tree)` for folders, collections and library_version.

## Inline details

- Identify types using `temporary` / `translation`, not a kind field. A library-free instance has `blockId:""` plus temp or translation. Temp contains title/color/iconName. Missing translation needsReview means false; missing languageCode means `zh`.
- Temporary title: trim, 1..40 Unicode code points. Color: `#RRGGBB` or `#AARRGGBB`, stored uppercase ARGB. Omitted color/icon uses native defaults. Translation source is sent to generation; zh is only a reading, even for other languages. language_code supports `zh`, `zh-TW`, `en`, `ja`, `ko`; supplied translations set translationEdited=true.
- Creation/conversion instance options are only enabled (both kinds) and title/content/color/icon (temporary). Translations reject content/display fields. Library-free instances reject negative_content: create separately in positive/negative scopes. Existing library bundles retain paired behavior.
- Conversion uses `segments` even for one selection. Temporary segments need title; translation segments need zh. Optional content/source must exactly equal the selected text. Disabled conversion would change projection and is rejected. A failure identifies the one-based segment and writes nothing; success returns markers in input order, one backup and one lane write/undo. Projection mismatch rolls back.
- Update only a library-free temp's display fields. Translation updates cannot mix with content edits; source-only changes set needsReview, supplying zh clears it.
- Promote defaults title to temp.title (library-backed temps without it need changes.title), retaining temp color/icon or original library appearance. Translation promote is unsupported. A library-free temp has no original: revertTemp is a no-op; unwrap or promote instead.

## Merging and splitting

There are no merge/split/rename/icon actions: compose existing operations. Each mutation returns the next draft_version for chaining.

- Merge: update one library-free temp with combined content/title/icon, then delete the others. For library-backed blocks whose display cannot be edited, delete and create a replacement at the same position.
- Split: update the first part and create the rest alongside it; or unwrap and convert with segments.
- Keep generation text equivalent unless the user asked to change it.

## Positioning

Offsets are raw document UTF-16 positions, never inside an emoji surrogate pair. Create/insert accepts offset or `anchor:{text,occurrence?,mode:"before"|"after"}` (mutually exclusive); omit both to append with a comma separator. Every convert segment requires `anchor` with mode `replace`, not offset.

Anchors match stripMarkers(document.text), not expanded block contents. Ranges may touch but cannot include/cross a marker. Multiple matches require zero-based occurrence; missing/out-of-range gives anchor_missing, ambiguity gives anchor_ambiguous with matches count.

```json
{"action":"instance_convert","scope":"main","expected_draft_version":"<fresh>","segments":[
  {"anchor":{"text":"rooftop, after rain","mode":"replace"},"kind":"temporary","instance":{"title":"Setting","color":"#607D8B","icon":"city"}},
  {"anchor":{"text":"soft lighting","mode":"replace"},"kind":"translation","translation":{"zh":"柔和光照"}}
]}
```

## Library details

changes.generationSettings supports model, dimensions, steps, scale, sampler, noiseSchedule, cfgRescale, qualityPreset (`standard/light/none`), ucPreset (`0/1/2/3/7/8/9`), qualityCustomBlockId/ucCustomBlockId (existing library IDs replacing native presets).

Folder/collection create/update uses changes.name/parentId/sortOrder; collection_create also isFolder. parent_id=null means root. folder_delete requires an empty folder. collection_delete removes the subtree/memberships, not blocks. collection_add/remove uses explicit membership and native favorites.

## prompt_update safety

The native writer keeps pill documents only for exact projection no-ops; other text rebuilds plain text and drops instances, even if markers are retained. Thus prompt_update rejects changed text and removed/cleared character lanes containing instances. Character metadata with stable IDs and unchanged positive/UC projections, and unrelated fields, remain editable.

## Errors

- invalid_arguments / invalid_instance / invalid_translation: malformed fields or unsupported combinations.
- invalid_position / invalid_offset: wrong anchor mode, mixed positioning or broken UTF-16 boundary.
- anchor_missing / anchor_ambiguous / anchor_crosses_marker: choose another handwritten anchor or occurrence.
- overlapping_segments / projection_changed: conversion must preserve the exact generation text.
- unsupported_kind / unsupported_bundle: use a supported type or separate positive/negative scopes.
- draft_conflict / block_conflict / library_conflict: reread current state and its version; busy / closed: do not write.

## Temporary icon keys

Unknown keys return invalid_arguments:

`palette`, `brush`, `draw`, `color_lens`, `image`, `photo`, `filter`, `person`, `face`, `groups`, `heart`, `star`, `bolt`, `fire`, `sparkle`, `moon`, `sun`, `cloud`, `snow`, `landscape`, `city`, `home`, `park`, `beach`, `forest`, `dress`, `diamond`, `cake`, `food`, `game`, `music`, `pets`, `book`, `science`, `school`, `car`, `flight`, `shield`, `build`, `tag`.
