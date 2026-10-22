> [← Back to home](../../../README.md) · [Guide index](README.md)

# Translation blocks

Having trouble reading a long English prompt? Translation blocks translate it into Chinese and display it right where it was. **Generation always uses the original English text**; translations only help you read and edit.

<img src="../../images/readme/en/translation.webp" alt="Translation blocks" width="100%">

## Set up a translation model first

Translation requires your own model service (OpenAI-compatible APIs, Anthropic, Gemini, local Ollama and others are supported):

1. Open “Settings → Models & APIs,” click “Add provider,” enter the address and key, and choose a model.
2. In “Feature models,” assign a model to “Prompt translation.”

<img src="../../images/readme/en/settings-models.webp" alt="Models & APIs" width="100%">

You can assign models to three other features on the same page: image-to-prompt, tag translation and semantic enrichment, and wiki translation. Keys are kept in secure system storage. Translation requests go to your chosen service and are billed at that service’s rates.

## Use it

Click “Translate” on the prompt toolbar. When translation finishes, each English passage becomes a “Translation block”:

| Action | Result |
| --- | --- |
| **Middle-click a block** | Switch between original and translation |
| **Left-click the original** | Place the cursor and edit English directly |
| **Left-click the translation** | Open the translation block editor |
| “Show all original / Show all translations” in the translation menu | Switch the whole group |
| “Translate new text” in the translation menu | Translate only text added later |
| “Restore all translation blocks to original text” | Remove all translation blocks and return to plain text |

## Translation block editor

Left-click a translation to open the editor, which shows the original and the content under “Generation”:

- Edit the English original directly and save to apply.
- **↑ Translation to original**: Write Chinese and let the model turn it into English tags; review and save.
- **↓ Original to translation**: Translate again.
- After the original is edited, the block indicates that the translation needs syncing.

## Preventing mistranslations: a glossary of matched terms

Many Danbooru tags are easy to misread literally: a word may be an artist, work or character name, or simply a description of the image. To help the model translate accurately, Studio first performs a local lookup for each translation, builds a glossary of **tags matched in the prompt**, and sends it with the request as reference:

| Glossary content | Source |
| --- | --- |
| Canonical tag name | Local tag database (only complete tags found in the database are included) |
| Chinese translation | Previously translated and cached tag names |
| Short definition | Local Wiki: uses a Chinese definition when available; otherwise includes a short definition in the original language, marked as original text |
| Category | Local tag database (artist / work / character / general, etc.) |

There are also several safeguards:

- **The glossary is reference material only**: The model is explicitly told that prompts and glossaries are data to translate, not instructions, and that definitions must not be appended to prompts. It must not invent meanings or relationships for tags that cannot be found.
- **Only complete tags qualify**: Ordinary words within sentences are not forced into their Danbooru meanings.
- **Results are checked locally**: Artist, work and character tags marked in the translation must exist in the local tag database. Studio chooses category icons from local data, not the model’s claimed categories. Unmatched annotations are discarded, while the translated text is kept.
- **Names and definitions are cached separately**: When a Wiki source changes, the old Chinese definition is no longer used; the new original text is used instead so outdated explanations do not mislead the model.
- **All glossary lookups happen locally**: Looking up the glossary makes no extra model calls, and a failed lookup does not block translation.

The same glossary is also used for “↑ Translation to original,” tag translation and wiki translation. When you write Chinese in the editor, the model can refer to matching canonical tags to turn it back into accurate English tags. When translating tag names or Wiki articles, related tag definitions are included to distinguish artists, works and ordinary words with the same name.

## Tips

- Middle-click whenever you want to check the original and make sure the model has not translated `cat ears` into something odd.
- Translation does not change the saved generation text or affect Anlas costs.
- Automatic tag and wiki translation is off by default. Enable it in [Tag Wiki](tags-wiki.md) and dictionary settings when needed.
