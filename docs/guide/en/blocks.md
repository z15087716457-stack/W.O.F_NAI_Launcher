> [← Back to home](../../../README.md) · [Guide index](README.md)

# Blocks

Blocks (labeled “Blocks” in the interface) let you save and reuse common prompt snippets. Artist pools, quality tags, negative tags, clothing lists, composition descriptions—write them once, save them as blocks, then click or drag to put them back into a prompt.

<img src="../../images/readme/en/blocks-library.webp" alt="Block library" width="100%">

## Where to find blocks

- **Block library page**: “Prompt Blocks” in the left navigation. Create and edit blocks, sort them into folders and collections, and change their colors and preview images here.
- **Block library sidebar on the generation page**: On the right of the generation page. Click to insert at the cursor, or drag into a prompt to place it where you want.
- **Block palette**: A small floating panel for your most-used blocks.

<img src="../../images/readme/en/blocks-dock.webp" alt="Block library sidebar" width="70%">

## Create a block

- Press `Ctrl+N` in the block library to create one.
- Or select some prompt text, right-click and choose “Save as block.”

A block can contain multiple items (for example, an artist pool with 30 artists), along with both **negative content** and **generation settings**. See [Style blocks](#style-blocks-positive-negative-and-settings-in-one-package) below.

Pressing Enter or a comma while entering content creates an item; pasted text is automatically split at commas and line breaks. To keep a passage containing commas as **one item**, wrap it in `1::…::`, for example `1::sunrise, on a hill, wind::` (a weight of 1 leaves the strength unchanged). Write one item per line, then paste them all at once.

## Three modes: Fixed, Sequential and Random

An inserted block appears as a “pill” in your prompt. Click it to open its settings and choose how to get its content this time:

| Mode | Behavior | Good for |
| --- | --- | --- |
| **Fixed** | Inserts all content unchanged each time | Quality tags, negative tags, fixed character descriptions |
| **Sequential** | Cycles through items in order, advancing one step per generation and looping at the end | Trying outfits, scenes or poses one by one |
| **Random** | Randomly draws a few items from the pool each time | Trying artist combinations in batches, random backgrounds |

You can set different modes for separate insertions of the same block.

### Sequential

<img src="../../images/readme/en/blocks-sequential.webp" alt="Sequential mode" width="60%">

- Advances one step each time you start a generation. If one request produces multiple images, that batch uses the same item; the next request advances.
- Use ← → on the card to switch items manually.
- Locking stops automatic advancement.

**Example**: Save `school uniform`, `hoodie`, `kimono` and `maid outfit` as a sequential block. Generate four times in a row to get the same character in four outfits.

#### Advance a story with a sequential block

Sequential blocks are not just for changing outfits: they work for **anything that needs to follow an order**. Split a story into scenes, write each scene as one item, and name the block after the story. Each generation advances one scene:

```text
Block name: Homeward on a Rainy Night (Sequential)
1::train station, night, rain, holding umbrella, waiting::
1::walking, wet street, neon lights, reflection::
1::convenience store, warm light, buying drink::
1::apartment door, looking back, smile, rain stopped::
```

- Wrap a scene with multiple tags in `1::…::` so the whole scene counts as one item instead of being split at commas.
- Use ← → on the card to jump to any scene and generate it again. If you are not satisfied, lock that scene and keep trying.
- **Pair it with different characters**: Add a character block. Set it to Random for “the same story, a different character in each scene.” Lock the story block and reroll only the character for “the same scene, played by several characters.” Run two sequential blocks together to advance through scenes with fixed character-and-setting pairings.

The same idea works for expression sequences, times of day (dawn → noon → dusk → late night), framing (full body → upper body → close-up), seasons, and more.

### Random

<img src="../../images/readme/en/blocks-random.webp" alt="Random mode" width="60%">

Random mode has a set of “Draw rules.” Click “Done” after editing to apply them:

- **Count**: How many items to draw each time; can be a range such as 2–3.
- **Chance**: The chance that this block appears. Below 100%, the whole block may sometimes be omitted.
- **Weight**: Automatically wraps each drawn item in a weight such as `0.8::…::`. Weights vary randomly between “Min ~ Max,” centered on “Most likely.”
- **Output order**: Use the order drawn or the original order in the block.
- Preview with “4 rolls with these rules” in the rules section; click “Roll again” if you want another preview.

<img src="../../images/readme/en/blocks-rules.webp" alt="Weight distribution" width="60%">

Expand “Advanced” to adjust the shape of the weight distribution:

- **Focused / Balanced / Wide**: Pull weights toward the center or spread them toward the ends.
- **Left spread / Right spread**: Fine-tune the shape on either side of the center.
- **Soft balance**: Pulls back the overall weight when several drawn artists have unusually high or low weights. This keeps the overall style strength steady without changing the relative differences between them.

### Lock, reroll and disable

<img src="../../images/readme/en/blocks-locked.webp" alt="Locked" width="60%">

- **Lock**: Freezes the current draw so later generations do not reroll it. Useful for “keep this pose, but try a few more outfits.”
- **Reroll**: Draw again manually (unlock first if locked).
- **Disable**: Temporarily excludes this block from generation without removing it from your prompt.

## Style blocks: positive, negative and settings in one package

A block can carry **negative content** and **generation settings** as well as positive content. Save a whole style you like—artist strings, quality tags, matching negative tags and the settings that work best—as a “style block,” ready to reuse in one click.

- **Negative content**: When you insert the block, the positive part goes at the cursor and the negative part is automatically placed in the matching negative field (main prompt to main negative, character prompt to that character’s negative). Both parts are managed as a pair.
- **Generation settings**: Attach the model, steps, guidance, rescale, sampler and noise schedule. While editing the block, click “Use current” to save the current settings from the generation page.
- **Apply settings in one click**: Inserting a block does **not** change your settings automatically, to avoid accidental changes. When needed, click “Apply attached settings” in the block library’s context menu or details, or open the block’s card in your prompt and apply them there. Your current settings are replaced with those saved in the block. The button is unavailable if the settings are incompatible with the current model.

**Example workflow**: Once you get an image you like, select the artist string and quality tags and save them as a block. In the editor, add the negative tags, click “Use current” to save the settings, and name it “Watercolor · Clarity.” Later, insert this block into any new prompt and click “Apply attached settings” to return to the same style setup.

## Organize the block library

- Folders and collections are on the left; view blocks in a grid, list or masonry layout.
- Select multiple blocks to insert them in order, merge them into a new block, or change their colors and appearance together.
- Import TXT files (one item per line) or folders, and export the entire library as a backup.
- If you delete a block already used in a prompt, its pill shows “Block deleted.” You can undo the deletion.

## Common uses

1. **Artist pool**: Random, draw 2–3 items, weights 0.6–1.2, chance 100%. Works well with [style evolution](style-explore.md).
2. **Quality + negative tags**: One fixed block for each, placed at the end of every prompt.
3. **Outfit / scene rotation**: A sequential block to try the whole set in one run.
4. **Occasional details**: Random, draw 1 item, chance 30%, to add a little variety to some images.
5. **A great combination**: Lock the artist pool and reroll only clothing and backgrounds.
6. **Storyboards**: Write several story scenes in a sequential block, pair it with a character block, and generate one scene at a time.
7. **Style blocks**: Package artist strings + negative tags + settings into one block. Insert it and apply its settings to switch styles.

## Working with other features

- In Style Explore, sequential and random blocks can be set as a “Genetic target” for style evolution (fixed blocks cannot).
- Enable [local semantic search](rag.md) to search the block library by meaning.
- Add useful tags from [Tag Wiki](tags-wiki.md) to a block in one click.
- [NAI Agent](nai-agent.md) can help you find and organize blocks.
