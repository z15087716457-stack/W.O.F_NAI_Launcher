# Local semantic search

Use `studio_search` for descriptive/semantic lookup, including image-to-image search. It reads existing local vectors only: no Anlas, network, automatic RAG enabling or index building. A local model may run for retrieval if RAG is already enabled and the requested source has vectors.

## Inputs and sources

- `source` (required): `gallery`, `blocks`, `wiki`, or `tags`.
- `query`: natural-language description, at most 500 characters. Supply a nonblank query or an image; both may be used for gallery search.
- `limit`: 1–50, default 20; fewer hits are possible.
- **Gallery**: results have `image_id: "gallery:<ID>"`, `path`, `channel`, 1-based `rank`, and available lightweight metadata. These IDs work directly with `image_read` and `reference_manage`.
- **Blocks**: results have `id`, `title`, `snippet`, `section`; fetch the full saved block with `block_query({id})`.
- **Wiki**: the same fields; `id` is the canonical tag, even when the title/snippet is translated. Pass the ID to `wiki_query({tags: [id]})`, not a translated title.
- **Tags**: descriptive lookup of real canonical tags, returning `name`, `category`, `post_count`, `aliases`, optional cached `translation`, `score` and retrieval `origins`. Use returned names, never invent tags from the description.

## Gallery image input and scope

Supply exactly one `image_id` or `path` when using an image. Image inputs and gallery filters/mode are invalid for other sources.

- `image_id` follows `image_read`: `gallery:<ID>`, `selected`, a canvas/history ID, `draft:source`, or another readable image ID. Gallery IDs use the original library file; memory images get a short-lived workspace PNG, removed after the call.
- `path` is a workspace-relative attachment path, e.g. `attachments/<chatId>/<uuid>.png`. Absolute paths, traversal and symlinks escaping the workspace are rejected, just as for `image_read`.
- `mode`: `mixed`, `visual`, or `parameters`; defaults to `visual` with an image, otherwise `mixed`.
- `favorites: true` restricts to favorites; false/omitted means no favorite restriction.
- `date_start` / `date_end`: inclusive `YYYY-MM-DD`, based on native library modification dates. Favorite/date filters narrow the configured, non-deleted local library **before** semantic ranking. Visible gallery filters/selection do not change.

## Results and status

The JSON result contains `source`, `status` and, on success, `items`.

- `ok`: successful lookup; an empty `items` really means no matches in the eligible scope.
- `partial: true`: usable vectors exist, but the source index is incomplete or still building; results are not exhaustive.
- `disabled`: global RAG is off. Tell the user where to enable it: Settings > Semantic Search; do not change settings yourself.
- `not_indexed`: the source is disabled or has no vectors. Ask the user to enable/index it in Settings > Semantic Search; do not build an index automatically.
- `busy`: local GPU/search resources are unavailable; retry later.
- `error`: local retrieval failed; read `message`, do not treat it as zero matches.

Invalid inputs are tool errors, not empty results. Search does not generate images or modify the draft. Follow normal fresh-version/backup rules if a later reference operation changes the draft.

## Choosing a tool

- `studio_search`: semantic descriptions, visual similarity, finding a concept across saved blocks/Wiki/tags.
- `gallery_query(scope="library")`: deterministic text/tag/model/favorite/date filters and newest-first listing; use it when semantic similarity is not wanted.
- `tag_query`: literal canonical-name/alias lookup, including substring matching, without RAG.

## Codemode examples

```javascript
text(await tools.mcp__nai_studio__studio_search({
  source: 'gallery', query: 'a rainy neon street at night',
  favorites: true, date_start: '2026-01-01', date_end: '2026-12-31', limit: 8
}));
```

```javascript
// Use the selected canvas image, or replace image_id with a workspace attachment path.
text(await tools.mcp__nai_studio__studio_search({
  source: 'gallery', image_id: 'selected', mode: 'visual', limit: 10
}));
// Alternative: {source: 'gallery', path: 'attachments/chat-id/photo.png'}
```

```javascript
const results = await Promise.allSettled([
  tools.mcp__nai_studio__studio_search({source: 'blocks', query: 'soft watercolor lighting'}),
  tools.mcp__nai_studio__studio_search({source: 'wiki', query: 'rim lighting'}),
  tools.mcp__nai_studio__studio_search({source: 'tags', query: 'running in sunlight', limit: 12})
]);
for (const result of results) text(result);
```
