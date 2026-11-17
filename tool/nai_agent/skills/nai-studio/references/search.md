# Local semantic search

`studio_search` reads existing local vectors for `source=gallery|blocks|wiki|tags`. Retrieval may run a local model when RAG is enabled.

## Inputs

- Supply a nonblank `query` (at most 500 characters), an image, or both. `limit`: 1–50, default 20.
- Gallery alone accepts image inputs, `mode` and filters. Use exactly one `image_id` or workspace-relative `path`, following `image_read`. Gallery IDs use original files; in-memory canvas images use a temporary workspace PNG.
- `mode=mixed|visual|parameters` defaults to `visual` with an image, otherwise `mixed`.
- `favorites=true` restricts to favorites; false/omitted is unrestricted. Inclusive `date_start`/`date_end` use `YYYY-MM-DD` modification dates. Filters narrow the configured, non-deleted library before ranking.

For `source=tags`, optional `tag_options` changes only this call:

- `top_k` (1–80) is the candidate budget per query, divided among selected layers by query intent. It defaults to `limit`. Segments can recall more candidates; deduplication, score thresholds and the final `limit` may return fewer items.
- `target_layers`: any of `name` (English name), `synonyms` (Chinese names/synonyms), `meaning` (Wiki/summary), `core` (main Chinese name). Defaults to all four. Untranslated local tags use the fields they have.
- `target_categories`: any of `General`, `Character`, `Copyright`, `Artist`, `Meta`, `Other`. Defaults to General/Character/Copyright. Set Artist explicitly when searching for artists.
- `use_segmentation`: default true. Disable for a whole phrase; keep enabled for descriptions containing several concepts.
- `popularity_weight`: 0–1, default 0.15. Lower it for rare tags. At 1 the final relevance threshold still applies.

Start with defaults. If results miss the intended concept, refine the query or increase `top_k`; do not repeatedly fetch large overlapping lists. Exact names and prefixes still belong to `tag_query`. These controls do not change settings or build/clear indexes.

## Results

Results contain `source`, `status` and successful `items`:

- Gallery: `image_id=gallery:<ID>`, `path`, `channel`, 1-based `rank` and available metadata. IDs work with `image_read`/`reference_manage`.
- Blocks/Wiki: `id`, `title`, `snippet`, `section`. Fetch blocks with `block_query({id})`; Wiki IDs are canonical tags for `wiki_query({tags:[id]})`, including translated hits.
- Tags: `name`, `category`, `post_count`, `aliases`, optional cached `translation`, `score` and `origins`. Use returned canonical names.

`ok` with empty `items` means no matches. `partial=true` marks an incomplete but searchable index; results cover only the indexed content.

- `disabled`: the global semantic-search switch is off. Direct the user to Settings > Semantic Search if they want to enable it. Sources have no separate switches.
- `not_indexed`: this source has no usable vectors. The user must explicitly build its index in Settings > Semantic Search. Building, upgrading and clearing indexes are user actions, not retrieval operations.
- `busy`: retry later. `reason=warming` means the saved index is loading; GPU reservations also make retrieval temporarily busy.
- `error`: report the returned `message`. Existing progress can be continued or retried in Settings; do not recommend clearing or rebuilding the index as the first recovery step.

Invalid inputs are tool errors. `tag_query` and `tag_related` remain available without RAG; use them when their lookup or co-occurrence behavior fits the request.

Use `gallery_query(scope=library)` for deterministic text/tag/model/favorite/date filters and newest-first listing. For tag tool selection, see [lookup.md](lookup.md).

## Examples

```javascript
text(await tools.mcp__nai_studio__studio_search({
  source: 'gallery', image_id: 'selected', mode: 'visual', favorites: true, limit: 10
}));
```

```javascript
text(await tools.mcp__nai_studio__studio_search({
  source: 'tags', query: 'running in sunlight', limit: 12,
  tag_options: {top_k: 40, popularity_weight: 0.1, target_categories: ['General']}
}));
```
