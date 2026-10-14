# W.O.F NAI Studio

<p align="center">
  <a href="README.md">简体中文</a> | English
</p>

<p align="center">
  <img src="assets/images/wof_logo_full.png" alt="W.O.F NAI Studio Logo" width="240">
</p>

<p align="center">
  <strong>A third-party desktop client for NovelAI image generation</strong>
</p>

<p align="center">
  <a href="https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases"><img src="https://img.shields.io/badge/version-2.0%20Preview-blue" alt="Version"></a>
  <img src="https://img.shields.io/badge/Flutter-3.47.7-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/platform-Windows-lightgrey" alt="Platforms">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

> **This repository is a personal fork (W.O.F edition) of [Aaalice233/Aaalice_NAI_Launcher](https://github.com/Aaalice233/Aaalice_NAI_Launcher) (MIT)**, based on upstream v1.5.3 with its own version numbering restarted at 1.0.0. It maintains extensions such as V5 model support, bridge parameter injection, and style-exploration genetics. It is not affiliated with the upstream author; please file issues in this repository.
>
> The genetic algorithm design of the style-exploration module is inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio) (GPL-3.0). The implementation here is a Dart rewrite that copies no source code; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

W.O.F NAI Studio is a third-party client for NovelAI built with Flutter. It integrates image generation, image-to-image, inpainting, Vibe / Precise Reference, local gallery, online gallery, generation queues, Krita integration, and statistical tools into a single desktop application, making it ideal for daily generation, batch processing, and long-term management of local artwork.

> This project is not an official NovelAI product. Please ensure you have your own NovelAI account and comply with NovelAI's Terms of Service before use.


> This README describes the current source tree. New Studio, translation, and gallery work remains under `[Unreleased]` in CHANGELOG; the feature set of a downloaded package is determined by its own release notes. Existing interface screenshots are retained as historical illustrations.

> The current version is **2.0 Preview**, a local Windows x64 portable preview with the nine-page UIUX integration, full NAI Agent, and subsequent canvas, icon, toolbar, Vibe encoding and OLD comparison fixes. Extract and run the package using your own account; settings continue to use the existing application data directory. See the [integration record](docs/uiux-integration-2026-10-13.md) and [2.0 Preview delivery record](docs/studio-2-preview-2026-10-14.md). Local delivery is separate from publishing a GitHub Release.

## ✨ Features Overview

| Feature | Description |
| --- | --- |
| 🎨 Image Generation | Supports NovelAI Diffusion V1/V2/V3/V4/V4.5/V5 (Full / Curated), Furry series, common samplers, size presets, multi-character parameters, and Anlas estimation. |
| 🖼️ Image-to-Image & Editing | Supports img2img, inpainting, Outpaint, virtual canvas expansion, hard-edge masks, and click-to-fill region selection. |
| 🌈 Reference & Style | Supports Vibe Transfer, Precise Reference, multi-image references, Vibe pack import/export, and PNG metadata embedding/export. |
| ✍️ Prompt Tools | Includes the complete offline merged Danbooru/e621 tag and alias catalog plus Danbooru co-occurrence recommendations. Press `Ctrl/⌘+Shift+Space` for tags related to the tag before the cursor, pin the source tag for continuous insertion, and optionally merge Danbooru online relations and AI tag translations. Also includes NAI/SD weight syntax assistance, token counting, in-box prompt search, and pinned words — plus the app-wide pill prompt-block system described in the highlights below. |
| 📚 Local Gallery | Supports multi-source recursive scanning, a sidebar / image wall / details three-pane layout, continuous day-grouped browsing with a timeline scrubber, SQLite full-text search, categories/collections/trash pool, model-version filters, one-click parameter reuse from the details panel, batch operations, and large image previews. |
| 🌐 Online Gallery | Supports Danbooru / Safebooru / Gelbooru / AI TAG search, native rankings, multi-image details, metadata reuse, and batch downloads. |
| 📦 Generation Queue | Supports task sorting, batch generation, pause/resume, failure handling strategies, progress statistics, and queue import/export. |
| 🔌 External Integration | Supports full-parameter Krita bridging (AI takeover), local ComfyUI workflows, system proxy, image copying, and file location. |

### Online Gallery Sources

- **Danbooru / Safebooru**: Support tag and date searches plus native daily, weekly, and monthly rankings for a selected date. Danbooru supports login and writable favorites; Safebooru uses anonymous, read-only access to `safebooru.donmai.us`.
- **Gelbooru**: Supports public search. Optional API credentials accelerate searches and enable read-only website favorites; no synthetic local ranking is presented.
- **AI TAG**: Supports combined work/author/title/tag/model queries and verbatim Prompt syntax searches such as `::artist:`, with time ranges loaded from the live source configuration. Native live monthly, historical monthly, and older archives are available. Multi-image details support navigation, prefetching, and per-image NAI / Stable Diffusion / ComfyUI metadata reuse, plus current-image and whole-work downloads. This fork adds a **local favorites system**: work favorites (with subsets) and author favorites live in a local standalone database and are browsable offline — no site account needed. From the detail view you can favorite an author and view that author's works filtered right in the app (no external links); the search bar keeps a return entry so you can jump back to your exact browsing position.

## 🚀 W.O.F Edition Highlights

> This fork is based on upstream v1.5.3 and rebuilds several subsystems around "prompts as reusable assets + directed style exploration". Full changes in [CHANGELOG.md](CHANGELOG.md).

### 💊 Pill Prompt-Block System — the prompt hub across the app

Break prompts into reusable **blocks**: artist pools, quality tags, UC presets, and style strings are all blocks. A block library panel stays docked on the generation page — one tap inserts a block into the current prompt. Blocks render inline as highlighted pills, editable in place, and work identically in positive, negative, and character prompts.

- **Three instance modes**: fixed output; sequential rotation (→ badge, in-card ←→ scene stepping); random draw with count range, Split-Beta weight distribution, and trigger probability — re-rolled per image in batch generation.
- **Block manager**: dual-pane sidebar with folder tree + ⭐ favorite collections (draggable, persisted split), grid/list/masonry views grouped under sticky per-folder section headers, multi-select bulk operations, block thumbnails with crop framing, custom colors, tags, hover preview and paired positive/negative content; ships with official NovelAI preset blocks. The old per-block TXT export action is now tag management.
- **Floating palette + docked block-library panel**: drag favorite blocks onto the 🎨 palette for one-tap insertion; the generation-page panel filters by folder subtree and keeps a draggable, persisted split.
- **Per-instance locking and an "evolution target" DNA badge**: marks which blocks participate in mutation — the entry point for style exploration below.

<p align="center">
  <img src="screenshots/generation_pill_block_library.png" alt="Generation UI: pill editor and block library" width="80%">
  <br>
  <em>Earlier generation UI illustration. Current source uses refined module cards, compact parameter rows, and batch history; this revision has not been installed. See CHANGELOG.</em>
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

The launcher exposes a local bridge protocol that **any external agent tool, script, or workflow can plug into directly** — authenticate through the per-launch local port and secret. Available actions follow the bridge protocol:

- **Parameter control**: `set_params` updates supported fields such as prompts, dimensions, seeds, sampling parameters, and characters; `generate` returns image paths through the bridge. Complex reference-image data has separate read/write limits; check the current CLI and handlers before using it.
- **State readback**: `get_params` reports effective prompts, characters, model parameters, references, and token usage. Reading a field does not imply that it can be written back unchanged; character arrays replace the entire list.
- **Companion toolchain**: `tool/nai_bridge_client.py` CLI (get / set / set-json / gen / ui-gen / cancel), `tool/nai_fill.py` one-shot metadata fill, and `tool/bridge_selfcheck.py` for targeted self-checks — the CLI source doubles as a reference implementation for writing a client in any language.
- In-app auto-update is served from this repository's Releases (since v1.0.1), so bridge extensions are never clobbered by upstream updates.

### 🖼️ Gallery Overhaul

Local galleries use a library / collection / folder sidebar, a continuous image wall, and a details inspector. Grid, masonry, and justified rows share thumbnail sizing; justified rows are the default, preserve aspect ratios without cropping, and leave a short final row aligned left. There is no pagination: group by day or month, scrub the timeline, inspect a single image, multi-select, and reuse parameters. The responsive search toolbar and empty header areas support window dragging. Multi-source scanning, soft-delete trash, NAI/model/tag/date filters, HD/SD thumbnails, drag-out, and byte-level dedup remain. Online galleries keep their separate local favorites and AI TAG author browsing.

<p align="center">
  <img src="screenshots/local_gallery_masonry.png" alt="Local gallery masonry" width="80%">
  <br>
  <em>Historical gallery screenshot; the current layout is the three-pane timeline described above.</em>
</p>

### ➕ More Improvements

- Character prompt editor: official-site-style persistent layout, selection follows focus, fields auto-grow (3–12 lines).
- Opus free-quota chip: official `usage.percent` plus refill countdown; free-eligibility rules match observed official behavior — PR / img2img / inpainting no longer wrongly cancel free generation.
- Guest mode: skip login and use all offline features with a non-persistent in-memory session.
- Unified NAI lexer with numeric-weight tail guard; removed focus-loss space-to-underscore conversion; Magic Byte metadata parsing for PNG / WebP / JPEG; anti-hotlink headers for the AI TAG online gallery.

### 🌐 Translation, Models, and Languages

- Bilingual prompt blocks support whole-document or single-block toggling, editing, retranslation, source restoration, and undo. Reading the translation does not change the saved generation source.
- Models & APIs provides provider management, searchable catalog / selected-model columns, manual IDs, cached discovery results, and connection tests. Context, output limits, reasoning, and sampling belong to each model; task interfaces and prompt presets do not override them. Capability flags record configuration and do not create an embedded agent executor.
- The interface supports Simplified Chinese, Traditional Chinese (Taiwan), English, Japanese, and Korean. The main workspace stays at 100% typography; settings have their own shared scale for pages, menus, and dialogs.
- Drag/drop, paste, and gallery parameter reuse share a compact image-use dialog with explicit import choices; seed is not selected by default, and character data can replace or append.

## 🧩 Platform Support

| Platform | Status | Description |
| --- | --- | --- |
| Windows | Available | The only development and release platform. Supports system tray, window state persistence, video playback, clipboard, and file location. |

## 📦 Download & Install

Download the latest version from [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases). The app persistently surfaces available updates before and after login (served from this repository) and fully renders GitHub Flavored Markdown release notes, including headings, lists, tables, quotes, code, links, and images.

| Platform | Download File | Usage |
| --- | --- | --- |
| Windows | `NAI_Launcher_Windows_<version>_Setup.exe` | Installer version, recommended for general users. Supports resumable in-app downloads, verification, automatic installation, and restart. Manual setup also detects and closes an older version still running in the tray. |
| Windows | `NAI_Launcher_Windows_<version>_Portable.zip` | Portable version. In-app updates stage the new version, preserve user files, atomically swap directories, and automatically roll back and restart the previous version on failure. |

You can log in for the first time using your NovelAI account credentials or an API Token. Account data is stored locally on the device only. The desktop app uses the system's secure storage for sensitive information.

### Tags, Translation & Privacy

- The app includes an offline tag/alias catalog and local English wiki data. It neither bundles nor downloads the retired ffdkj Chinese dictionary; Chinese text is not used for local tag search.
- Optional automatic tag/wiki translation is off by default. When enabled, it uses the configured Tag translation and Wiki translation interfaces, prioritizes the latest visible tags, and allows up to five concurrent requests. Tag-name requests include the full available local wiki as context; full article translation is requested only when opened.
- Prompt translation sends the selected plain-text segments and matched terminology to the configured service. Bilingual blocks retain a separate source projection for generation. Shared terminology can include a Chinese name, a brief definition, and its language; missing/expired Chinese definitions fall back to labeled source text without making extra requests.
- Translations live in a separate local cache. They do not overwrite the tag/wiki databases, and existing results remain readable. Provider requests may incur API charges; use the selected service's terms and settings.
- Optional Danbooru online relations send the relevant tag rather than the full prompt. Their controls and cache management are under Settings → Lexicon & Cache.

## 🛠️ Build from Source

### Environment Requirements

- Flutter `3.44.2` (project minimum requirement is Flutter `3.35.0` / Dart `3.10.7`)
- Git LFS, required for pulling `assets/databases/*.db`
- Visual Studio 2022 with Desktop development with C++
- [NuGet CLI](https://learn.microsoft.com/nuget/install-nuget-client-tools), the directory containing `nuget.exe` must be added to `PATH`

### General Steps

```bash
git clone https://github.com/z15087716457-stack/W.O.F_NAI_Launcher.git
cd W.O.F_NAI_Launcher

git lfs install
git lfs pull --include="assets/databases/*.db"

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
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

## 🚀 Release Process

Releases are handled by the `Release` workflow in GitHub Actions. After pushing a `v*` tag, the workflow builds the Windows installer and portable versions, then generates `release_manifest.json`, `checksums.txt`, and Release notes. The Release page provides direct Setup / Portable download badges with platform icons.

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
│   ├── l10n/               # Simplified/Traditional Chinese, English, Japanese, and Korean UI strings and generated files
│   └── presentation/       # Pages, components, state management, themes, and routing
├── scripts/                # Build, packaging, signing, hot reload, and validation scripts
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

Contributions via Issues and Pull Requests are welcome. Before submitting a PR, please describe the goal of the changes, the scope of impact, and how to verify them. For UI behavior changes, please attach screenshots or recordings where possible.

## 🙏 Acknowledgments

- Thanks to [Aaalice233](https://github.com/Aaalice233/Aaalice_NAI_Launcher) for creating and open-sourcing the upstream project (MIT), on whose v1.5.3 baseline this fork is built.
- The genetic algorithm design of the style-exploration module is inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio) (GPL-3.0), reimplemented in Dart; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- [NovelAI](https://novelai.net/) for providing the image generation service.
- [Flutter](https://flutter.dev/) for cross-platform UI capabilities.
- [Riverpod](https://riverpod.dev/) for state management capabilities.
- Thanks to all contributors and testers.

## 📄 License

This project is open-source under the MIT License. See [LICENSE](LICENSE) for details. Original copyright belongs to the upstream NAI Launcher Contributors; new work in this fork is copyrighted by W.O.F (z15087716457-stack).

The interface bundles Geist Sans / Mono / Pixel Line, HarmonyOS Sans SC, and Pretendard (Korean) fonts, alongside the original interface icons. Fonts retain their own licenses; see the [asset guide](tool/branding/README.md) and [license files](assets/licenses/), also available from the app’s About page.
