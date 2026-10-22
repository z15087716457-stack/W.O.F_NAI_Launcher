> [← Back to home](../../../README.md) · [Guide index](README.md)

# NAI Agent

NAI Agent is the AI assistant built into Studio. Tell it what you want in chat, and it uses Studio’s tools to do it: edit prompts, look up tags and wiki entries, organize blocks and images, set reference images, prepare generation and more.

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
- “Find all night scenes I made last week and move them to a new folder.”
- “Prepare 4 images with the current settings and give me a quote.”

Available Studio tools include reading the current draft, viewing images, rewriting prompts, draft snapshots, wiki lookup, tag lookup, finding and organizing blocks, reading / changing settings, Style Explore, preparing generation, generating images, canceling generation, finding and organizing gallery images, semantic search, setting reference images, reference libraries, image tools, and variations / enhance. It can also read and write workspace files, run commands and ask you questions when needed.

<img src="../../images/readme/en/agent-run.webp" alt="Agent running" width="50%">

## Permissions and confirmation

Choose a permission level at the bottom of the sidebar:

| Level | Behavior |
| --- | --- |
| **Read-only** | Reads and discusses only; no changes or generation |
| **Ask** | Asks before changes, commands and unknown tools |
| **Auto** | Makes routine changes within the workspace directly; spending still requires confirmation |
| **Full access** | Runs all actions without asking; spending Anlas still requires confirmation (a risk warning appears before switching) |

When confirmation is needed, a card offers “Allow once,” “Allow identical calls this session” or “Deny.” Actions such as deleting, moving and running commands fall under operations that require confirmation.

<img src="../../images/readme/en/agent-approval.webp" alt="Confirmation card" width="50%">

### Generating images always needs your confirmation

When Agent wants to generate images, it first uses “Prepare generation” and shows a price card in Studio: Anlas per request, estimated total and current balance. **Generation starts only after you confirm on the price card**, at every permission level. Quotes are valid for 5 minutes. Click stop during generation, or use stop in the main interface, to interrupt it.

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

## Tips

- Start with “Ask” to learn what it does before considering “Auto.”
- External Pi extensions and MCP servers can run local code. Install only from trusted sources.
- External AI tools and scripts can also control Studio through the “Local bridge” (included `studio-bridge.exe`). They also need a price quote and confirmation before generation.
