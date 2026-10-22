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

## Tips

- Middle-click whenever you want to check the original and make sure the model has not translated `cat ears` into something odd.
- Translation does not change the saved generation text or affect Anlas costs.
- Automatic tag and wiki translation is off by default. Enable it in [Tag Wiki](tags-wiki.md) and dictionary settings when needed.
