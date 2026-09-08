# W.O.F NAI Launcher

<p align="center">
  <a href="README.md">简体中文</a> | English
</p>

<p align="center">
  <img src="assets/icons/Icon.png" alt="NAI Launcher Logo" width="120">
</p>

<p align="center">
  <strong>A third-party desktop client for NovelAI image generation</strong>
</p>

<p align="center">
  <a href="https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases"><img src="https://img.shields.io/badge/version-1.0.0-blue" alt="Version"></a>
  <img src="https://img.shields.io/badge/Flutter-3.44.2-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS-lightgrey" alt="Platforms">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

> **This repository is a personal fork (W.O.F edition) of [Aaalice233/Aaalice_NAI_Launcher](https://github.com/Aaalice233/Aaalice_NAI_Launcher) (MIT)**, based on upstream v1.5.3 with its own version numbering restarted at 1.0.0. It maintains extensions such as V5 model support, bridge parameter injection, and style-exploration genetics. It is not affiliated with the upstream author; please file issues in this repository.
>
> The genetic algorithm design of the style-exploration module is inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio) (GPL-3.0). The implementation here is a Dart rewrite that copies no source code; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

NAI Launcher is a third-party client for NovelAI built with Flutter. It integrates image generation, image-to-image, inpainting, Vibe / Precise Reference, local gallery, online gallery, generation queues, Krita integration, and statistical tools into a single desktop application, making it ideal for daily generation, batch processing, and long-term management of local artwork.

> This project is not an official NovelAI product. Please ensure you have your own NovelAI account and comply with NovelAI's Terms of Service before use.

## ✨ Features Overview

| Feature | Description |
| --- | --- |
| 🎨 Image Generation | Supports NovelAI Diffusion V1/V2/V3/V4/V4.5/V5 (Full / Curated), Furry series, common samplers, size presets, multi-character parameters, and Anlas estimation. |
| 🖼️ Image-to-Image & Editing | Supports img2img, inpainting, Focused Inpaint, Outpaint, virtual canvas expansion, hard-edge masks, and click-to-fill region selection. |
| 🌈 Reference & Style | Supports Vibe Transfer, Precise Reference, multi-image references, Vibe pack import/export, and PNG metadata embedding/export. |
| ✍️ Prompt Tools | Includes the complete offline merged Danbooru/e621 tag and alias catalog plus Danbooru co-occurrence recommendations. Press `Ctrl/⌘+Shift+Space` for tags related to the tag before the cursor, pin the source tag for continuous insertion, and optionally merge Danbooru online relations, Chinese translations, and AI translations for missing entries. Also includes NAI/SD weight syntax assistance, token counting, in-box prompt search, and pinned words — plus the app-wide pill prompt-block system described in the highlights below. |
| 📚 Local Gallery | Supports multi-source recursive scanning, default masonry layout, SQLite full-text search, categories/collections/trash pool, model-version filters, metadata parsing, batch operations, and large image previews. |
| 🌐 Online Gallery | Supports Danbooru / Safebooru / Gelbooru / AI TAG search, native rankings, multi-image details, metadata reuse, and batch downloads. |
| 📦 Generation Queue | Supports task sorting, batch generation, pause/resume, failure handling strategies, progress statistics, and queue import/export. |
| 🔌 External Integration | Supports full-parameter Krita bridging (AI takeover), local ComfyUI workflows, system proxy, cross-platform image copying, and file location. |

### Online Gallery Sources

- **Danbooru / Safebooru**: Support tag and date searches plus native daily, weekly, and monthly rankings for a selected date. Danbooru supports login and writable favorites; Safebooru uses anonymous, read-only access to `safebooru.donmai.us`.
- **Gelbooru**: Supports public search. Optional API credentials accelerate searches and enable read-only website favorites; no synthetic local ranking is presented.
- **AI TAG**: Supports combined work/author/title/tag/model queries and verbatim Prompt syntax searches such as `::artist:`, with time ranges loaded from the live source configuration. Native live monthly, historical monthly, and older archives are available. Multi-image details support navigation, prefetching, and per-image NAI / Stable Diffusion / ComfyUI metadata reuse, plus current-image and whole-work downloads. This fork adds a **local favorites system**: work favorites (with subsets) and author favorites live in a local standalone database and are browsable offline — no site account needed. From the detail view you can favorite an author and view that author's works filtered right in the app (no external links); the search bar keeps a return entry so you can jump back to your exact browsing position.

## 🚀 W.O.F Edition Highlights

> This fork is based on upstream v1.5.3 and rebuilds several subsystems around "prompts as reusable assets + directed style exploration". Full changes in [CHANGELOG.md](CHANGELOG.md).

### 💊 Pill Prompt-Block System — the prompt hub across the app

Break prompts into reusable **blocks**: artist pools, quality tags, UC presets, and style strings are all blocks. A block library panel stays docked on the generation page — one tap inserts a block into the current prompt. Blocks render inline as highlighted pills, editable in place, and work identically in positive, negative, and character prompts.

- **Three instance modes**: fixed output; sequential rotation; random draw with count range, Split-Beta weight distribution, and trigger probability — re-rolled per image in batch generation.
- **Block manager**: folder-tree aggregation, multi-select bulk operations, custom colors and icons, TXT export; ships with 12 official NovelAI preset blocks.
- **Per-instance locking and an "evolution target" DNA badge**: marks which blocks participate in mutation — the entry point for style exploration below.

<p align="center">
  <img src="screenshots/generation_pill_block_library.png" alt="Generation UI: pill editor and block library" width="80%">
  <br>
  <em>Generation UI: pill editor (block highlighting) with the block library panel (official presets and artist pools)</em>
</p>

<table align="center">
  <tr>
    <td width="62%"><img src="screenshots/prompt_block_manager.png" alt="Prompt block manager"></td>
    <td width="38%"><img src="screenshots/block_instance_settings.png" alt="Block instance settings"></td>
  </tr>
  <tr>
    <td align="center"><em>Block manager: folder tree and bulk operations</em></td>
    <td align="center"><em>Instance settings: three modes and weight spread</em></td>
  </tr>
</table>

### 🧬 Style Exploration · Multi-Pool Genetics

Generate candidates toward a style direction, then converge generation by generation with a genetic loop: every basic-round candidate gets its own snapshot; pick favorites as parents, and deep rounds mutate / crossover / inject to produce the next generation. Pairwise comparisons build preference scores, and the lineage panel traces any candidate's full ancestry. A winning style string can be adopted as a block with one tap, flowing back into the pill system.

- Three-column explorer with grid / deck dual views; panels are drag-resizable.
- Full-screen formal review: T/S/R keyboard labeling, template solidification, Reject batch deletion.
- Per-image snapshots in basic rounds; deep rounds never touch your current draft.
- Algorithm design inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio) (GPL-3.0); reimplemented in Dart without copying its code.

> 📖 New here? Read the illustrated tutorial: [docs/style-exploration.en-US.md](docs/style-exploration.en-US.md) — from enabling genetics to families, deep iterations, and adopting blocks.

### 🎨 Full NovelAI Diffusion V5 (N5) Support

Driven by a capability-flag registry: V5 Full / Curated (with inpainting mapping), up to 32 character prompts, 1471 token limit, official ×1.5 pricing, transparent-background toggle (straight_alpha), Enhance Max✨ server-side e2e upscale, and V5 quality/UC presets.

### 🔌 Open Bridge · Any Agent Can Take the Wheel

The launcher exposes a local bridge protocol that **any external agent tool, script, or workflow can plug into directly** — no whitelist, no caller restrictions. Get the bridge endpoint and you get full control of the launcher:

- **Full-parameter writes**: `set_params` writes any generation parameter in batch; `generate` produces images silently (no UI changes, returns gallery paths) — external tools can drive the entire generation pipeline without touching the interface.
- **Full-state readback**: `get_params` symmetrically reads back everything (character prompts and coordinates, noise_schedule, cfg_rescale, PR/Vibe/img2img, actual token usage) for lossless get→set round-trips.
- **Companion toolchain**: `tool/nai_bridge_client.py` CLI (get / set / set-json / gen / ui-gen / cancel), `tool/nai_fill.py` one-shot metadata fill, and `tool/bridge_selfcheck.py` 11-point end-to-end self-check — the CLI source doubles as a reference implementation for writing a client in any language.
- In-app auto-update is served from this repository's Releases (since v1.0.1), so bridge extensions are never clobbered by upstream updates.

### 🖼️ Gallery Overhaul

Multi-source galleries, default masonry layout, collections (root/subset linking), soft-delete trash pool, three-channel NAI-only filtering, precise local model-version filters, HD/SD thumbnail quality tiers, unified drag-out across all three views, envelope-metadata backfill, and byte-level dedup on image save — plus local favorites (works + subsets + authors) for the online gallery, with in-app author-work browsing on AI TAG.

<p align="center">
  <img src="screenshots/local_gallery_masonry.png" alt="Local gallery masonry" width="80%">
  <br>
  <em>Local gallery: masonry layout, category tree, NAI-only and model-version filters</em>
</p>

### ➕ More Improvements

- Character prompt editor: official-site-style persistent layout, selection follows focus, fields auto-grow (3–12 lines).
- Opus free-quota chip: official `usage.percent` plus refill countdown; free-eligibility rules match observed official behavior — PR / img2img / inpainting no longer wrongly cancel free generation.
- Guest mode: skip login and use all offline features with a non-persistent in-memory session.
- Unified NAI lexer with numeric-weight tail guard; removed focus-loss space-to-underscore conversion; Magic Byte metadata parsing for PNG / WebP / JPEG; anti-hotlink headers for the AI TAG online gallery.

## 🧩 Platform Support

| Platform | Status | Description |
| --- | --- | --- |
| Windows | Available | Primary development and release platform. Supports system tray, window state persistence, video playback, clipboard, and file location. |
| macOS | Minimal Support | Supports building, launching, login, local database, video playback, Keychain, system proxy, image copying, and file location. System tray support to be added later. |
| Linux | Unreleased | Desktop code branches exist, but official packages are not currently provided. |
| Android | Planned | Still in the adaptation/planning phase. |

## 📦 Download & Install

Download the latest version from [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases). The app persistently surfaces available updates before and after login (served from this repository) and fully renders GitHub Flavored Markdown release notes, including headings, lists, tables, quotes, code, links, and images.

| Platform | Download File | Usage |
| --- | --- | --- |
| Windows | `NAI_Launcher_Windows_<version>_Setup.exe` | Installer version, recommended for general users. Supports resumable in-app downloads, verification, automatic installation, and restart. Manual setup also detects and closes an older version still running in the tray. |
| Windows | `NAI_Launcher_Windows_<version>_Portable.zip` | Portable version. In-app updates stage the new version, preserve user files, atomically swap directories, and automatically roll back and restart the previous version on failure. |
| macOS | `NAI_Launcher_macOS_<version>_Portable.zip` | Portable version. Extract and open `Aaalice NAI Launcher.app`. If an unnotarized build is blocked, you can allow it to open in System Settings > Privacy & Security. |

You can log in for the first time using your NovelAI account credentials or an API Token. Account data is stored locally on the device only. The desktop app uses the system's secure storage for sensitive information.

### Autocomplete Data & Privacy

- The base Danbooru tag and alias catalog ships with the app and is queried locally without a network connection.
- The Simplified Chinese translation dictionary is optional. It is downloaded directly from the [ffdkj/ComfyUI_Danbooru_Tag_Assistant](https://github.com/ffdkj/ComfyUI_Danbooru_Tag_Assistant) upstream only after user confirmation; this project does not redistribute that database.
- The Danbooru online supplement is enabled by default. It sends only the current English token under the cursor, never the complete prompt; it can be disabled and its cache cleared separately under Settings → Data Sources & Cache.
- AI translation for missing entries is disabled by default. When enabled, it reuses the Prompt Assistant `Translate` route and sends at most 8 untranslated tags to the model service selected by the user, which may incur API charges. Its cache can be cleared separately.

## 🛠️ Build from Source

### Environment Requirements

- Flutter `3.44.2` (project minimum requirement is Flutter `3.35.0` / Dart `3.10.7`)
- Git LFS, required for pulling `assets/databases/*.db`
- Windows Build: Visual Studio 2022 with Desktop development with C++
- Windows Build: [NuGet CLI](https://learn.microsoft.com/nuget/install-nuget-client-tools), the directory containing `nuget.exe` must be added to `PATH`
- macOS Build: Full Xcode, CocoaPods, Git LFS

### General Steps

```bash
git clone https://github.com/z15087716457-stack/W.O.F_NAI_Launcher.git
cd W.O.F_NAI_Launcher

git lfs install
git lfs pull --include="assets/databases/*.db"

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

### Windows

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify_nuget.ps1
flutter build windows --release
```

The Windows implementation of `flutter_inappwebview` fetches native dependencies like the WebView2 SDK via NuGet during compilation. If `verify_nuget.ps1` fails, please install the NuGet CLI first and ensure `nuget help` runs directly in a new PowerShell window.

Output directory:

```text
build/windows/x64/runner/Release/
```

For Windows desktop development, start a dedicated hot-reload session:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/dev_hot_reload_window.ps1
```

After editing code, safely trigger that existing session from any terminal without starting a second `flutter attach`:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/trigger_hot_reload.ps1
# To reset application state:
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/trigger_hot_reload.ps1 -Restart
```

To inspect the real desktop window, capture it directly into the project temp directory. Direct rendering also works when the window is covered:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/capture_dev_window.ps1
# Custom output path or capture without activating the window:
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/capture_dev_window.ps1 -OutputPath tool/.tmp/ui.png -NoActivate
```

### macOS

```bash
flutter build macos --release
```

Output path:

```text
build/macos/Build/Products/Release/Aaalice NAI Launcher.app
```

During local development, if the Keychain repeatedly prompts for authorization, you can first create a stable local signing certificate and then run the signed launch script:

```bash
scripts/create_macos_dev_cert.sh
scripts/dev_run_macos_signed.sh debug
```

## 🚀 Release Process

Releases are handled by the `Release` workflow in GitHub Actions. After pushing a `v*` tag, the workflow builds the Windows installer, Windows portable, and macOS portable versions, then generates `release_manifest.json`, `checksums.txt`, and Release notes. The Release page groups direct Setup / Portable download badges by operating system and includes platform icons.

```bash
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

Before releasing, please ensure:

- The version number in `pubspec.yaml` has been updated; the tag must match the version without the `+build` suffix, e.g., `1.0.0+17` corresponds to `v1.0.0`.
- `CHANGELOG.md` has been updated under `✨ Added`, `🛠 Improved`, and `🐛 Fixed`; do not add a release-file table because the release script generates it automatically.
- `assets/databases/tag_catalog.db` and `assets/databases/cooccurrence.db` are actual SQLite files rather than Git LFS pointers and pass `dart run tool/tag_catalog/verify_bundled_databases.dart`.
- The Windows installer depends on NSIS; for local packaging, you can run `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/package_windows_release.ps1`.
- For Authenticode signing, configure the GitHub Secrets `WINDOWS_SIGNING_CERT_BASE64` (Base64-encoded PFX) and `WINDOWS_SIGNING_CERT_PASSWORD`. The workflow signs the portable executable before packaging, signs the installer afterward, and requires `signtool verify` to pass. Builds remain unsigned when no certificate is configured.
- Use `scripts/sign_windows_binary.ps1` for local signing, for example: `pwsh -File scripts/sign_windows_binary.ps1 -Path dist/setup.exe -CertificatePath cert.pfx -CertificatePassword '<password>'`.

## 🗂️ Project Structure

```text
nai_launcher/
├── assets/                 # Icons, screenshots, sound effects, tag data, preset databases
├── installer/              # Installer scripts
├── krita_plugin/           # Krita plugin and packaging/validation scripts
├── lib/
│   ├── core/               # Core features: networking, database, caching, encryption, file I/O, shortcuts, etc.
│   ├── data/               # API clients, models, repositories, and business data services
│   ├── l10n/               # Chinese, English, and Japanese UI strings and generated files
│   └── presentation/       # Pages, components, state management, themes, and routing
├── macos/                  # macOS runner
├── scripts/                # Build, signing, database, and testing helper scripts
├── test/                   # Unit tests and widget tests
├── tool/                   # Dev tools, data processing, icon generation, and diagnostic scripts
└── windows/                # Windows runner
```

## 💻 Development Conventions

Common commands:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

Commit messages should follow the format:

```text
type(scope): 中文描述
```

Descriptions are written in Chinese, consistent with the repository history. Common types: `feat`, `fix`, `refactor`, `perf`, `style`, `docs`, `test`, `chore`.

## 🤝 Contributing

Contributions via Issues and Pull Requests are welcome. Before submitting a PR, please describe the goal of the changes, the scope of impact, and how to verify them. For UI or cross-platform behavior changes, please attach screenshots or recordings where possible.

## 🙏 Acknowledgments

- Thanks to [Aaalice233](https://github.com/Aaalice233/Aaalice_NAI_Launcher) for creating and open-sourcing the upstream project (MIT), on whose v1.5.3 baseline this fork is built.
- The genetic algorithm design of the style-exploration module is inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio) (GPL-3.0), reimplemented in Dart; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- [NovelAI](https://novelai.net/) for providing the image generation service.
- [Flutter](https://flutter.dev/) for cross-platform UI capabilities.
- [Riverpod](https://riverpod.dev/) for state management capabilities.
- Thanks to all contributors and testers.

## 📄 License

This project is open-source under the MIT License. See [LICENSE](LICENSE) for details. Original copyright belongs to the upstream NAI Launcher Contributors; new work in this fork is copyrighted by W.O.F (z15087716457-stack).
