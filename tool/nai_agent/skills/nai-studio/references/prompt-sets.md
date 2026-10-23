# Prompt sets

Use `prompt_set` for 2–24 prompts at once (story scenes, outfits, battle shots, expressions). Choose the card kind/title/unit/icons. Use the user’s language for all card labels and descriptions, including kind, title, unit, item titles, and notes. Write generation prompts in English for models earlier than V5. For V5, prefer English, but use Chinese or another language when it expresses the intent more clearly or avoids ambiguity. Keep notes brief (1–2 sentences). Stable style/quality/appearance/negative belong in shared once, differences in items. Character additions align with shared characters by index and are positive only.

Optional positions (0–1, x right, y down) per character; use only when composition matters (e.g. two characters left/right). Omit to let the model choose.

`shared.positions` and `items[].positions` are arrays aligned with `shared.characters` (no longer than it): each entry is null or `{x, y}`. Effective position = item entry ?? shared entry ?? none.

```javascript
text(await tools.mcp__nai_studio__prompt_set({
  action: 'create', kind: 'Storyboard', kind_icon: 'film', title: 'After the rain', unit: 'scene', ordered: true,
  shared: {main: 'best quality, cinematic lighting, 1girl', characters: ['silver hair, blue eyes'], negative: 'lowres, text'},
  items: [
    {icon: 'rain', title: 'Rain', note: 'She runs for cover.', main: 'rain, street', characters: ['running']},
    {icon: 'coffee', title: 'Shelter', note: 'A warm cafe is still open.', main: 'cafe, warm light', characters: ['holding mug']}
  ]
}));
```

Keep the returned set_id/revision. To edit an existing set, use one CodeMode execution to read it, change only the requested fields, and update the same set_id using its current revision as expected_revision and full content reused from the read result; never regenerate or print the whole set or create a duplicate. Updates mark changed indexes and preserve generated images. The card imports one item per user click. A human click on the card’s Generate button directly authorizes ONE image of the current item: there is no second price gate. The per-item price pill and native price/balance/readiness checks remain. This authorization is only for that human UI action; model generation calls (generation_run, image_generate/image_tool/explore run) still require genuine native approval, including 0 Anlas and all permission modes. Do not also call prompt_update/generation unless asked.
