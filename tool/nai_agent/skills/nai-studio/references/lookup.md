# Tags and wiki

- `tag_query` finds canonical tags, aliases, category, post count and cached short definitions. Query in English; local indexes only.
- `tag_related` finds complementary tags for an existing set using local pairwise co-occurrence, without RAG or network. Pass `exclude` for tags already in the prompt; default category is general. `sources/support` explain contributing inputs; scores are associations, not probabilities. Use `studio_search(source=tags)` to find tags from natural language, then `wiki_query` for unfamiliar meanings.
- `wiki_query` reads local original wiki text. Page long articles with `offset` / `limit`. `include_examples=true` for one tag discovers the explicit official illustrations; pass the returned `wiki:*` image_id to `image_read`.
- `session_history` is a native Pi tool discovered on demand for exact earlier conversation, including before compaction. Use outline/search before read/read_turn; follow next_offset for bounded continuation. It reads only the current branch, omits thinking/binary and does not restore old messages to model context.
- Network access only on demand. Do not download the whole wiki and do not replace broken illustrations with guessed images.
