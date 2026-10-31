# Prompt sets

Use `prompt_set` for one 2–24-item card (story scenes, outfits, variations). Labels and notes use the user's language; notes stay within 1–2 sentences. Prompts use English before V5; V5 can use another language for clarity. Icons may repeat. Set `ordered=true` for sequences. Put stable style/quality/appearance/negative in `shared`, differences in `items`; positive character additions align with shared characters by index.

Optional character positions use 0–1 (x right, y down); omit when placement is unspecified.

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

Keep the returned `set_id/revision`. Edit in one CodeMode execution: read, patch the requested fields and update the same ID with `expected_revision` and full content. Summarize the changes; generated images remain attached to their items.

Each Import click applies one item. A human Generate click authorizes one image of that item without another confirmation; native price/balance/readiness checks remain. Model-initiated generation uses Studio quote confirmation. Creating or updating a card only changes the card.
