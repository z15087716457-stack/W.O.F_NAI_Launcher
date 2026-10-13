# NAI Agent E4A: gallery/history lookup and original image loading

The production binding adds `gallery_query` (17 actual tools total). History lookup includes deduplicated current/history/display-only images without starting gallery UI services. Library queries use a separate native filter service over configured tracked roots, keep visible filter/sort/timeline state, and provide paged database IDs for `image_read`.

Original loading checks tracked membership, the deleted pool, current roots and resolved paths; it returns frozen original bytes and never writes draft metadata to imported images. `StudioTools.loadImage` is distinct from model upload optimization and remains usable by non-vision domain tools. A missing file consumes its page slot and advances the cursor; total describes the tracked snapshot, not a fresh filesystem scan.

309 distinct Flutter checks and 14 Node checks pass (136 regression + 195 latest scope - 22 overlapping checks). Native temporary Hive/SQLite/PNG tests cover query independence and image boundaries. Official Pi with a real child process and local synthetic SSE executes history lookup followed by image read through the production factory. Existing four-language real-font UI and Traditional resources pass. Targeted analyze and CRLF-aware diff check pass; no generated input or localized label changed.

The first broader command used an absent Traditional test filename; the corrected complete run has 195 passes and zero failures. Existing gallery sort fixtures retain ScanStateManager closed-Hive warnings. No real provider/NAI requests, Anlas use, runtime installation/build/launch or commits. Installed receipt and app.so hashes remain unchanged. Reference management, gallery mutations and the remaining E/F scope are still in progress.
