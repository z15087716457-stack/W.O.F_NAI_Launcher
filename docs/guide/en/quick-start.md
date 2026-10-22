> [← Back to home](../../../README.md) · [Guide index](README.md)

# Quick start

## 1. Install

Download from [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/latest):

- **Installer** `WOF_NAI_Studio_Windows_<version>_Setup.exe`: Double-click to install. The default location is `%LOCALAPPDATA%\Programs\W.O.F NAI Studio`; administrator rights are not required.
- **Portable** `WOF_NAI_Studio_Windows_<version>_Portable.zip`: Extract to any folder and run `nai_launcher.exe` inside.

System requirements: Windows 10 or 11 (64-bit).

> The installer is not signed yet. If Windows says “Windows protected your PC,” click “More info → Run anyway.” To check that the file has not been tampered with, compare its SHA-256 checksum with the one on the Release page.

## 2. Sign in

- **API Token (recommended)**: Create a Persistent Token starting with `pst-` in your account settings on the NovelAI website, then paste it here.
- **Account and password**: The same as on the website.
- **Guest mode**: Skip sign-in on the login page to try local features such as the gallery, blocks and Tag Wiki. Generating images requires signing in.

Tokens and passwords are kept in Windows secure storage and used only on your computer.

## 3. Your first generation

<img src="../../images/readme/en/hero.webp" alt="Generation page" width="100%">

1. Choose a model at the top left (V4.5 or V5 is recommended).
2. Enter English tags in the prompt field, for example:
   ```
   1girl, solo, silver hair, starry sky, glowing flowers, night, cinematic lighting, very aesthetic, masterpiece
   ```
3. Set the size, image count and steps below. The generate button shows the Anlas cost in real time.
4. Press `Ctrl+Enter` or click generate. Press `Esc` during generation to cancel.

Results appear on the canvas in the middle, with history on the right. See [Infinite canvas](canvas.md) for canvas controls.

## 4. A few tips you can use right away

- **Adjust weights**: Select part of a prompt, hold `Alt` and scroll the wheel.
- **Save blocks**: Select part of a prompt, right-click and choose “Save as block.” Later, click it in the block library to insert it again. See [Blocks](blocks.md).
- **Drop in an image**: Drag an image into the window to use it for image-to-image, Vibe Transfer or Precise Reference, or just read its prompt and settings.
- **Shortcuts**: `F1` shows all shortcuts; `Ctrl+1/2/3` switches between generation, Local Gallery and Online Gallery, and `Ctrl+,` opens settings.
- **Avoid accidental Anlas spending**: Enable “High Anlas cost warning” in settings. You will be asked to confirm if the estimated cost of a single generation exceeds your threshold.

## 5. Where your data lives

| Location | Contents |
| --- | --- |
| `user-data/` in the program directory | Settings, gallery database, caches, block library and more |
| `agent-data/` in the program directory | NAI Agent workspaces, chat history and skills |
| Your configured gallery folders | The generated image files themselves |

To back up, copy `user-data/`, `agent-data/` and your gallery folders together. Updates and uninstallation do not delete these two data directories.

## Next steps

- Organize common prompts into [blocks](blocks.md)
- Find artist combinations you like with [style evolution](style-explore.md)
- Set up a model service and enable [translation blocks](translation.md) and [NAI Agent](nai-agent.md)
