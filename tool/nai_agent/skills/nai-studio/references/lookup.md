# Tags and wiki

- `tag_query`: known English canonical names/aliases; `contains=true` for name fragments. Returns category, post count, aliases and cached short definitions from local indexes.
- `studio_search(source=tags)`: descriptions (actions, composition, mood), unknown tag names or unresolved literal lookup. Use when `studio_context.search.tags` is ready/partial; [search.md](search.md) covers results and availability.
- `tag_related`: complementary tags or variants around known tags/aliases, using local pairwise co-occurrence without RAG or network. Pick a few specific seeds, not the whole prompt; pass existing prompt tags in `exclude`. Default category is general. `sources/support` explain contributing inputs; scores are associations, not probabilities.
- Stop once the request is resolved; do not run all three searches by default. Use `wiki_query` to check unfamiliar meanings.
- `wiki_query` reads local original wiki text. Page long articles with `offset` / `limit`. `include_examples=true` for one tag discovers the explicit official illustrations; pass the returned `wiki:*` image_id to `image_read`.
- `session_history` is a native Pi tool discovered on demand for exact earlier conversation, including before compaction. Use outline/search before read/read_turn; follow next_offset for bounded continuation. It reads only the current branch, omits thinking/binary and does not restore old messages to model context.
- Network access only on demand. Do not download the whole wiki and do not replace broken illustrations with guessed images.
