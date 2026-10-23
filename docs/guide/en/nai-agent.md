> [← Back to home](../../../README.md) · [Guide index](README.md)

# NAI Agent

NAI Agent is the AI assistant built into Studio. Tell it what you want in chat, and it uses Studio’s tools to do it: edit prompts, look up tags and wiki entries, organize blocks and gallery images, set reference images, prepare generation and more. Each action produces a corresponding **card** in the conversation, showing what changed. Most changes can be undone in one click.

<img src="../../images/readme/en/gen-agent.webp" alt="NAI Agent on the generation page" width="100%">

## Set up

1. Add a model provider in “Settings → Models & APIs” (OpenAI-compatible APIs, Responses, Anthropic, Gemini and Ollama are supported), then choose a model.
2. Click the “NAI Agent” button at the top of the generation or Style Explore page to open the sidebar on the right.
3. Choose a model at the bottom of the sidebar and start chatting.

Agent uses your own model service. Conversations are billed at that service’s rates.

## What you can ask it to do

A few examples:

- “Change the current prompt to a rainy-night street scene, keeping the character description.”
- “Look up `wet hair` in the wiki. Is there a more common way to write it?”
- “Move all artist blocks in the library to the ‘Styles’ folder.”
- “Set this image as a Vibe Transfer reference.” (You can paste or drag in an image.)
- “Find all night scenes I made last week in the gallery and move them to a new folder.”
- “Prepare 4 images with the current settings and give me a quote.”
- “Design an 8-scene short story set in a café on a rainy night.” “Give the same character 6 summer outfits. I want to try them one by one.”

Available Studio tools include: Read current draft, View image, Edit prompt, Prompt set, Draft snapshot, Search wiki, Look up tags, Find blocks, Edit blocks, Read settings / Change settings, Style explore, Prepare generation, Generate images, Cancel generation, Search gallery, Organize gallery, Semantic search, Set references, Reference library, Image tool, and Variations / enhance. It can also read and write workspace files, run commands and ask you questions when needed.

## Cards in the conversation

Agent does not make changes behind your back. Here are the kinds of cards you will see in the conversation.

### Progress: thinking and steps

<img src="../../images/readme/en/agent-card-thinking.webp" alt="Thinking and steps" width="460">

The model’s thinking is collapsed by default, showing only “Thought.” Each tool call appears as a step in order (for example, Read current draft → Search wiki → Edit prompt). Expand a step to see its parameters and results.

### Tag results

<img src="../../images/readme/en/agent-card-tags.webp" alt="Tag lookup results" width="460">

Results from Look up tags or Semantic search appear directly below that step: the canonical tag name, Chinese name and post count. Hover over a tag to see a Wiki summary.

### Prompt and parameter changes

<img src="../../images/readme/en/agent-card-diff.webp" alt="Prompt and parameter changes" width="460">

Each prompt field edited gets a diff card: green for additions, red for deletions. Changes to parameters such as steps, sampler and size get a separate card showing old value → new value. If several things change at once, a summary at the top shows “N changes.” Choose **Undo all**, or use “Undo” on just one card. If you have manually edited the draft since then, undo is locked to avoid overwriting your newer changes.

### Prompt set: stories, try-ons and storyboards

<img src="../../images/readme/en/agent-card-promptset.webp" alt="Prompt set card" width="460">

Ask it to write several prompts at once (a few story scenes, a set of outfits, several battle shots, a set of expressions, etc.), and a prompt set card appears in the conversation. Agent chooses the card’s name (Storyboard, Try-on, Battle scenes, etc.), as well as each item’s title, icon and description.

- **Switch items**: use the left and right arrows, the small icons below, or the keyboard ← → keys after selecting the card. The grid button at the top right shows all items at once.
- **Prompts**: collapsed by default. When expanded, gray text shows the settings shared by every item (style, character appearance and negative prompt), while highlighted text is specific to this item. Shared text farther away is abbreviated with “…”; click “Show all” to read the full original text.
- **Import to canvas**: writes only this item’s main prompt, characters and negative prompt into the draft. Parameters, seed, size and reference images stay unchanged. You can undo the import from the card. If Agent has placed the characters (for example, one on the left and one on the right), expanding the prompts shows a small position board, and importing writes those positions too. Prompt sets without positions don’t show the board.
- **Generate**: imports this item first, then opens the price card. After you confirm, it generates **1 image**. If you are not happy with it, click again for a fresh result. Generated images stay below that item, and its small icon gets a green dot.
- **⋯ menu**: “Save as block” (one entry per item; you can set it to sequential or random later), “Copy this item's prompt” or “Copy all,” and “Ask Agent to edit this item.”
- **Revisions**: ask Agent to “Make scene 5 daytime,” and it updates the same card directly. The card shows “v2 · 1 changed,” and edited items get a yellow dot. The card and its generated images are still there after a restart.

### Character positions

<img src="../../images/readme/en/agent-card-position.webp" alt="Character positions" width="460">

When character positions change, a miniature scene marks each character’s location so you can see at a glance who is on the left and who is on the right.

### App settings

<img src="../../images/readme/en/agent-card-settings.webp" alt="Settings changes" width="460">

Ask it to change settings (such as switching to a dark theme or enabling visual channels), and it lists old value → new value for each item. You can undo the whole card or click “Open settings” to jump to the relevant setting.

### Organizing the gallery

<img src="../../images/readme/en/agent-card-gallery.webp" alt="Gallery actions" width="460">

After favoriting, moving, copying, deleting or adding images to a collection, a card shows thumbnails and the number of affected images. Deletions go to the recycle area, and most actions can be undone.

### Asking you a question

<img src="../../images/readme/en/agent-card-ask.webp" alt="A question for you" width="460">

When something is unclear, Agent pauses to ask you. It offers a few options, or you can type your own answer.

### Asking for permission

<img src="../../images/readme/en/agent-approval.webp" alt="Confirmation card" width="460">

In “Ask” mode, this card appears before changes, deletions, moves or commands. It shows the exact parameters of the planned action, and you can choose “Allow once,” “Allow identical calls this session” or “Deny.”

### Before spending Anlas: the price card

<img src="../../images/readme/en/agent-card-gate.webp" alt="Price confirmation card" width="460">

When Agent wants to generate images, make variations / enhance images or use cloud image tools, it first shows this price card: model and size, number of requests, unit price, reference image encoding cost, total and current balance. Studio calculates the price; the model cannot change it. **Anlas is spent only when you click “Confirm & generate”**, at every permission level. Quotes expire; if the configuration changes or the quote expires, ask Agent to prepare it again.

### Outputs and summary

<img src="../../images/readme/en/agent-card-images.webp" alt="Outputs from this run" width="460">

Generated images appear in the conversation (and on the “Outputs” page), along with the Anlas spent in this run. Each run ends with a one-line summary: elapsed time, Anlas, number of changes, tool calls and tokens used.

## Permission levels

Choose a permission level at the bottom of the sidebar:

| Level | Behavior |
| --- | --- |
| **Read-only** | Reads and discusses only; no changes or generation |
| **Ask** | Asks before changes, commands and unknown tools |
| **Auto** | Makes routine changes within the workspace directly; spending still requires confirmation |
| **Full access** | Runs all actions without asking; spending Anlas still requires confirmation (a risk warning appears before switching) |

During generation, click Agent’s stop button or the stop button in the main interface to interrupt a pending generation.

## Skills (Skill)

Skills are “instruction manuals” for Agent, read only when needed:

- Built-in **nai-studio** (how to use Studio tools and their rules) and **nai-prompt** (V4 / V4.5 / V5 prompt writing).
- Write your own skills in `agent-data/skills/` (global) or a workspace’s `skills/` folder. For matching names, workspace skills take priority, followed by global, then built-in.
- Enable or disable each skill, or set it to “Manual only” and invoke it with `/skill:name` in the input field.

Use `@` in the input field to reference files or images, and `/` to invoke skills.

## MCP and CodeMode

- **MCP**: Add external MCP servers in “Settings → NAI Agent” (stdio and Streamable HTTP are supported, with OAuth sign-in) to give Agent more external tools. Configuration is kept in encrypted storage.
- **CodeMode**: By default, Agent discovers and calls tools as needed through a secure script sandbox, completing several steps at once to reduce back-and-forth.

<img src="../../images/readme/en/settings-agent.webp" alt="Agent settings" width="100%">

## Workspaces and data

- Each workspace has its own chats, outputs and rules. Create, rename or delete workspaces (deletions can be undone from the recycle area).
- All data lives in `agent-data/` in the program directory.
- The “Instructions” page lets you write global instructions and workspace rules that affect later requests.
- Each run defaults to at most 32 model requests, adjustable in settings (1–200).
- Use “Edit” to resend a message you have sent (the conversation after it will be replaced), or “Regenerate” on the last reply.

## Tips

- Start with “Ask” to learn what it does before considering “Auto.”
- External Pi extensions and MCP servers can run local code. Install only from trusted sources.
- External AI tools and scripts can also control Studio through the “Local bridge” (included `studio-bridge.exe`). They also need a price quote and confirmation before generation.
