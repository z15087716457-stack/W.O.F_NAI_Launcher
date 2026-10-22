> [← Back to home](../../../README.md) · [Guide index](README.md)

# Tag expansion and Tag Wiki

The app includes a complete offline tag database, tag co-occurrence data and the Danbooru Wiki, so you can look up tags without going online.

## Tag expansion

<img src="../../images/readme/en/tag-expansion.webp" alt="Tag expansion" width="100%">

In a prompt field:

- **Ctrl+click** a tag to open local tag search. Search tags and aliases in Chinese or English, press `Tab` to complete, and click to insert.
- **Ctrl+drag-select** a passage to see “Related tags”—tags that often appear with it.
- The popover also has a “Tag wiki” view to explain the tag right there.

Normal typing does not trigger autocomplete, so it stays out of your way. The same tag search is also available in Local Gallery search, Online Gallery search, the blacklist and the block library.

**Data sources**:

- An offline merged database of Danbooru / e621 tags and aliases.
- Offline co-occurrence data (which tags often appear together).
- Chinese semantic enrichment data (synonyms and short definitions for about 54,000 tags).
- Optional Danbooru online related tags: sends only relevant tags, not your full prompt. Disable it in “Settings → Dictionaries & cache.”

With [local semantic search](rag.md) enabled, tag suggestions also use the prompt near your cursor to recommend tags that better fit the context.

## Tag Wiki

<img src="../../images/readme/en/wiki.webp" alt="Tag Wiki" width="100%">

Open “Tag Wiki” in the left navigation.

- Browse the official category tree or search tags and aliases. Filter by “Has description / No description yet” and sort by popularity or name.
- Switch the article between translation, original and side-by-side views (requires a “Wiki translation” model; automatic translation is off by default).
- “Often used with” lists related tags: click to view, or `Shift+click` to add to a block.
- Add bookmarks and create bookmark collections.
- “Add to blocks” opens the block save dialog with the tag already filled in.
- Example images load only when needed.

Shortcuts: `/` search · `↑↓` switch · `Enter` add to blocks · `B` favorite · `Alt+←/→` back/forward.

## Update data

In “Settings → Dictionaries & cache,” check and update tag and wiki data, inspect cache levels and clear them. Updates run only when you click; nothing downloads automatically. Your own translations are preserved when refreshing.
