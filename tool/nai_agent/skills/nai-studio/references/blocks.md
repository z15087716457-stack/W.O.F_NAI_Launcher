# Prompt blocks

- `block_query`: `kind=tree` reads folders, collections and `library_version`; `id` reads one complete block and its `version`; otherwise `query` searches with paging.
- `block_manage` library actions: `create`, `update`, `delete`, `insert`; organization: `folder_create/update/move/delete/reorder`, `block_reorder`, `collection_create/update/move/delete/reorder/add/remove`. Entry edits/insert require `expected_version`; organization and `instance_promote` require fresh `expected_library_version` from `block_query(kind=tree)`.
- Saving to the library and inserting into the current prompt are different actions. For one-off needs, **do not create a library block just to insert it**. Use `instance_create` directly.
- Every `insert` / `instance_*` mutation needs `expected_draft_version` from fresh `studio_context(scope=draft)`. All mutations back up before writing and refuse busy/closed/stale state. Scopes: `main`, `negative`, `char:<current ID>:pos/neg`.
- Draft `documents.*.instances` expose read-only `kind=library/temporary/translation`. Temporary instances include `temporary:true`, full `temp` (including title/color/iconName); translations expose source/zh/needsReview/languageCode. A library-free instance has `blockId:""` and temp or translation, never neither.

## Inline actions

- `instance_create(kind=temporary)`: `instance:{title,content}`. Title is trimmed, nonempty, at most 40 Unicode code points. Optional `color` is `#RRGGBB` or `#AARRGGBB`, normalized to uppercase `#AARRGGBB`; optional `icon` is an allowlisted key below. Defaults omit color/iconName (native UI default).
- `instance_create(kind=translation)`: `translation:{source,zh,language_code?,marks?}`. **source is generation text; zh is only the reading**, even for non-Chinese reading languages. language_code defaults `zh`; supported: `zh`, `zh-TW`, `en`, `ja`, `ko`. Supplied translations set `translationEdited=true`. Translation instances reject instance content/title/color/icon.
- `marks` are `{start,end,tag,icon_id}`, UTF-16 offsets into zh. Invalid, out-of-range, surrogate-splitting or overlapping ranges reject the whole operation with `invalid_translation`.
- Both kinds accept optional instance `enabled`, `locked`, `evolutionEnabled`, `settings`. Native roll/toggle constraints still apply to later updates; temporary content always projects as fixed text, regardless of random settings.
- `instance_convert`: replace an existing nonempty plain-text anchor with a temporary or translation block, without changing projection. Temporary requires title; content comes from the selection. Translation requires zh; source comes from the selection. If content/source is also supplied, it must exactly equal the selected text.
- Bulk structural decomposition: `instance_convert` with `segments:[{anchor,kind,instance?,translation?}, ...]`, 1..64 segments, same scope, exclusive with top-level kind/anchor/offset/instance/translation. Resolve all anchors against the **original** document, validate every segment before backup/write; no overlap, no marker crossing. Failure returns the underlying error plus one-based segment number; nothing is written. Success returns `markers` in input order, one backup, one lane write/undo step; exact generation projection equality is checked after applying and failure rolls back as `projection_changed`. Disabled conversion is rejected because it would change projection.
- `instance_update(marker,occurrence=0)`: content/negative_content makes only that occurrence temporary; never edits the library. `instance.title/color/icon` can change only a library-free temporary block, not a library-backed temp (`unsupported_kind`). `translation:{source?,zh?,marks?,language_code?}` updates a non-temp translation; source-only change sets needsReview; supplying a new reading clears needsReview and discards old marks unless new marks are given. Do not mix translation updates with content edits.
- `instance_unwrap(marker,occurrence=0)`: expand one occurrence into its current enabled/temp/source/roll projection; native bundle peers follow. Translation reading is never sent as text.
- `instance_delete(marker)`: remove instance and all occurrences, including bundle peer; add occurrence to remove only that occurrence (shared markers are isolated first).
- `instance_promote(marker,changes?)`: temporary blocks only; translations return `unsupported_kind`. Writes library and replaces temp with the new reference. `changes` accepts title/folderId/color/iconName; missing title uses temp.title (library-backed temps without it need changes.title). New block defaults keep temp color/iconName, or original library appearance metadata. Returns new id, version and lanes. There is no original to revert for a library-free temp: revertTemp is a no-op; promote or unwrap it instead.
- Inline create/convert, and updates of library-free instances, **reject negative_content with unsupported_bundle**. Create separate instances in positive/negative scopes. Existing library bundle insert/update/unwrap/delete keep native paired behavior.

## Merging and splitting

There is no merge/split action; decide the grouping yourself and compose existing actions. Each mutation returns the next `draft_version`, so chain calls without re-reading.

- Merge: `instance_update` one library-free temp with the combined content (and new title/icon), then `instance_delete` the others. If the kept block is library-backed (title/icon locked to the library), `instance_delete` them all and `instance_create` one new temp at the same spot.
- Split: `instance_update` the block down to its first part, then `instance_create` the rest with `anchor` or `offset` next to it; or `instance_unwrap` and re-`instance_convert` with `segments`.
- Keep the generation text equivalent unless the user asked to change it.

## Positioning

- Create/insert: omit offset/anchor to append with the native comma separator; or pass raw document UTF-16 offset; or `anchor:{text,occurrence?,mode:"before"|"after"}`. offset and anchor are mutually exclusive. Never split an emoji surrogate pair.
- Convert: `anchor:{text,occurrence?,mode:"replace"}` is required, offset is not accepted.
- Anchor matching uses stripMarkers(document.text), not expanded projection: choose handwritten text, not a block's contents. Ranges may touch but must not cross/include a marker. Missing/out-of-range occurrence returns `anchor_missing`; multiple matches without occurrence return `anchor_ambiguous` with matches count. Occurrences are zero-based.

```json
{"action":"instance_convert","scope":"main","expected_draft_version":"<fresh>","segments":[
  {"anchor":{"text":"rooftop, after rain","mode":"replace"},"kind":"temporary","instance":{"title":"Setting","color":"#607D8B","icon":"city"}},
  {"anchor":{"text":"soft lighting","mode":"replace"},"kind":"translation","translation":{"zh":"柔和光照"}}
]}
```

## prompt_update safety

The native writer preserves a pill document only when new text exactly equals its current projection. Other text changes rebuild plain text and would drop instances, even if marker characters were retained. Therefore prompt_update rejects those edits with `pill_conflict` before backup, including removed/cleared character lanes with instances. Exact projection no-ops, character metadata edits retaining IDs and unchanged positive/UC projections, and unrelated parameter edits remain allowed. Use block_manage instance_* for structural/content edits; do not attempt to preserve blocks by sending raw marker text to prompt_update.

## Temporary icon keys

From `prompt_block_icons.dart` (unknown keys reject invalid_arguments):

`palette`, `brush`, `draw`, `color_lens`, `image`, `photo`, `filter`, `person`, `face`, `groups`, `heart`, `star`, `bolt`, `fire`, `sparkle`, `moon`, `sun`, `cloud`, `snow`, `landscape`, `city`, `home`, `park`, `beach`, `forest`, `dress`, `diamond`, `cake`, `food`, `game`, `music`, `pets`, `book`, `science`, `school`, `car`, `flight`, `shield`, `build`, `tag`.
