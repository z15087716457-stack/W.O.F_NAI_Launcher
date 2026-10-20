# Local semantic search

`studio_search` reads existing local vectors for `source=gallery|blocks|wiki|tags`. Retrieval may run a local model when RAG is enabled.

## Inputs

- Supply a nonblank `query` (at most 500 characters), an image, or both. `limit`: 1–50, default 20.
- Gallery alone accepts image inputs, `mode` and filters. Use exactly one `image_id` or workspace-relative `path`, following `image_read`. Gallery IDs use original files; in-memory canvas images use a temporary workspace PNG.
- `mode=mixed|visual|parameters` defaults to `visual` with an image, otherwise `mixed`.
- `favorites=true` restricts to favorites; false/omitted is unrestricted. Inclusive `date_start`/`date_end` use `YYYY-MM-DD` modification dates. Filters narrow the configured, non-deleted library before ranking.

## Results

Results contain `source`, `status` and successful `items`:

- Gallery: `image_id=gallery:<ID>`, `path`, `channel`, 1-based `rank` and available metadata. IDs work with `image_read`/`reference_manage`.
- Blocks/Wiki: `id`, `title`, `snippet`, `section`. Fetch blocks with `block_query({id})`; Wiki IDs are canonical tags for `wiki_query({tags:[id]})`, including translated hits.
- Tags: `name`, `category`, `post_count`, `aliases`, optional cached `translation`, `score` and `origins`. Use returned canonical names.

`ok` with empty `items` means no matches. `partial=true` marks an incomplete index. `disabled`/`not_indexed` direct the user to Settings > Semantic Search to enable/index the source; `busy` means retry later; `error` carries `message`. Invalid inputs are tool errors.

Use `gallery_query(scope=library)` for deterministic text/tag/model/favorite/date filters and newest-first listing; `tag_query` for literal names/aliases without RAG.

## Examples

```javascript
text(await tools.mcp__nai_studio__studio_search({
  source: 'gallery', image_id: 'selected', mode: 'visual', favorites: true, limit: 10
}));
```

```javascript
text(await tools.mcp__nai_studio__studio_search({
  source: 'tags', query: 'running in sunlight', limit: 12
}));
```
