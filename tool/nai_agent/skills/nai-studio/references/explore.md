# Style exploration (explore_manage)

- `list` / `read` are paged; `read` includes roll snapshots and candidate image IDs (`explore:*`, viewable with `image_read`).
- `create(name, count, expected_draft_version)` freezes the current recipe and parameters for documentation; execution follows the native current Studio recipe.
- Edits need `id` and a fresh `expected_version`: `rename`, `complete`, `heart(candidate_id, heart)`, `folder_create` / `folder_rename` / `folder_delete(folder_id)` (candidates become unfiled), `candidate_move(candidate_id, folder_id | null)`.
- `prepare(id, expected_version, mode=basic|retry|deep)` returns a five-minute quote covering all candidates; `deep` also needs an existing `family_id`, `parent_set_id` and `count`. `run(quote_id)` waits for the user's button. Native progress, partial results and recovery are kept.
- `pause` / `cancel` only affect this chat's run and protect newer manual runs. Actual charges may remain unknown; say so.
