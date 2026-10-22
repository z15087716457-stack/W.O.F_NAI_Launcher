> [← Back to home](../../../README.md) · [Guide index](README.md)

# FAQ

### Windows says “Windows protected your PC” when I launch it

The installer and program are not code-signed yet. Click “More info → Run anyway.” To check that a file has not been tampered with, compare its SHA-256 checksum with the one on the Release page.

### What is the difference between installer and portable versions?

They have exactly the same features. The installer uses `%LOCALAPPDATA%\Programs\W.O.F NAI Studio` and adds a Start menu entry and uninstaller. The portable version runs wherever you extract it. Both support in-app updates.

### Where is my data, and how do I back it up?

- Settings, gallery database and block library: `user-data/` in the program directory
- NAI Agent: `agent-data/` in the program directory
- Images: your configured gallery folders

Copy all three locations for a complete backup. Updates and uninstallation do not delete `user-data/` or `agent-data/`.

### Upgrading from an older version (1.x)

Just install the new version. On first launch, data from the old AppData location is fully backed up, verified and migrated to `user-data/`. Older installed versions can also upgrade through in-app updates.

### How much Anlas does a generation actually cost?

The generate button shows the total cost live (image count × per-image price, including reference encoding and similar costs). Enable “High Anlas cost warning” in settings to confirm above your threshold. Generation through NAI Agent or an external bridge also requires your confirmation on the price card.

### Which features access the network?

- NovelAI APIs (generation, account, upscaling, Director Tools)
- Model services you configure (translation, image-to-prompt, NAI Agent)
- Online Gallery sources (Danbooru, Safebooru, Gelbooru, AI TAG)
- Update checks (this repository’s GitHub Releases)
- Optional components you explicitly choose to download (semantic search models and runtime, upscaling models, magic-wand model)

Semantic search, local upscaling and gallery organization all run locally. Danbooru’s online related-tag lookup sends only relevant tags, not your full prompt; disable it in “Settings → Dictionaries & cache.”

### Are my account and keys safe?

NovelAI tokens, passwords and API keys are kept in Windows secure storage and used only on your computer. MCP configuration is kept in encrypted storage.

### What GPU do I need?

Generation runs in NovelAI’s cloud and has no GPU requirement. Only optional local features need one: local upscaling requires a Vulkan-capable GPU; RTX upscaling requires NVIDIA RTX; SeedVR2 requires NVIDIA; semantic search is faster with NVIDIA, but can also run on CPU.

### How do I change the interface language?

In “Settings → Appearance,” choose Simplified Chinese, Traditional Chinese, English, Japanese or Korean, and a light, dark or system theme.

### How do I report a problem?

Open an [Issue](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/issues) in this repository with your version, steps to reproduce and screenshots. Keep tokens and keys out of your screenshots.
