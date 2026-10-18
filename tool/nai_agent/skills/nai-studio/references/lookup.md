# Tags and wiki

- `tag_query` finds canonical tags, aliases, category, post count and cached short definitions. Query in English; local indexes only.
- `wiki_query` reads local original wiki text. Page long articles with `offset` / `limit`. `include_examples=true` for one tag discovers the explicit official illustrations; pass the returned `wiki:*` image_id to `image_read`.
- Network access only on demand. Do not download the whole wiki and do not replace broken illustrations with guessed images.
