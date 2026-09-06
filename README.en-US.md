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
| 🎨 Image Generation | Supports NovelAI Diffusion V1/V2/V3/V4/V4.5, Furry series, common samplers, size presets, multi-character parameters, and Anlas estimation. |
| 🖼️ Image-to-Image & Editing | Supports img2img, inpainting, Focused Inpaint, Outpaint, virtual canvas expansion, hard-edge masks, and click-to-fill region selection. |
| 🌈 Reference & Style | Supports Vibe Transfer, Precise Reference, multi-image references, Vibe pack import/export, and PNG metadata embedding/export. |
| ✍️ Prompt Tools | Includes the complete offline merged Danbooru/e621 tag and alias catalog plus Danbooru co-occurrence recommendations. Press `Ctrl/⌘+Shift+Space` for tags related to the tag before the cursor, pin the source tag for continuous insertion, and optionally merge Danbooru online relations, Chinese translations, and AI translations for missing entries. Also includes NAI/SD weight syntax assistance, token counting, in-box prompt search, and pinned words. |
| 📚 Local Gallery | Supports recursive scanning, SQLite full-text search, categories/collections/favorites, metadata parsing, batch operations, and large image previews. |
| 🌐 Online Gallery | Supports Danbooru / Safebooru / Gelbooru / AI TAG search, native rankings, multi-image details, metadata reuse, and batch downloads. |
| 📦 Generation Queue | Supports task sorting, batch generation, pause/resume, failure handling strategies, progress statistics, and queue import/export. |
| 🔌 External Integration | Supports local Krita integration, local ComfyUI workflows, system proxy, cross-platform image copying, and file location. |

### Online Gallery Sources

- **Danbooru / Safebooru**: Support tag and date searches plus native daily, weekly, and monthly rankings for a selected date. Danbooru supports login and writable favorites; Safebooru uses anonymous, read-only access to `safebooru.donmai.us`.
- **Gelbooru**: Supports public search. Optional API credentials accelerate searches and enable read-only website favorites; no synthetic local ranking is presented.
- **AI TAG**: Supports combined work/author/title/tag/model queries and verbatim Prompt syntax searches such as `::artist:`, with time ranges loaded from the live source configuration. Native live monthly, historical monthly, and older archives are available. Multi-image details support navigation, prefetching, and per-image NAI / Stable Diffusion / ComfyUI metadata reuse, plus current-image and whole-work downloads. AI TAG requires no account and is read-only.

## 🔀 Differences from Upstream

Compared to the upstream v1.5.3 baseline, this fork (W.O.F edition) reworked the prompt, exploration, gallery, and billing subsystems end to end:

- **Krita bridge extensions (AI takeover)**: full-parameter external writes via `set_params` / `generate` with silent generation (no UI changes); symmetric full-state readback via `get_params` (character prompts and coordinates, noise_schedule, cfg_rescale, PR/Vibe/img2img blind spots, actual token usage) for get→set round-trips; companion `tool/nai_bridge_client.py` CLI, `tool/nai_fill.py` one-shot metadata fill, and `tool/bridge_selfcheck.py` 11-point end-to-end self-check. In-app auto-update is disabled at the code level to protect bridge extensions.
- **NovelAI Diffusion V5 (N5)**: capability-flag registry driving V5 Full / Curated (no noise schedule, hidden Variety+, capability-driven PR/Vibe panels, up to 32 character prompts), 1471 token limit with official ×1.5 pricing, transparent-background toggle (straight_alpha), Enhance Max✨ tier (server-side e2e upscale), and V5 quality/UC presets.
- **Pill prompt-block system**: single-box inline pill editor with a page-level block library panel; per-instance fixed / sequential / random-draw modes (count range, Split-Beta weight distribution, trigger probability, per-image re-roll); multi-lane isolation for negative/character prompts; instance locking and an "evolution target" DNA badge; folder-tree aggregation; multi-select bulk operations in the block manager; built-in official NovelAI preset blocks.
- **Style-exploration module (multi-pool genetics)**: three-column explorer, run data layer with batch candidates, grid/deck dual views, full-screen formal review (keyboard labeling, template solidification, adopt-as-block, Reject deletion), deep-iteration engine (mutation/crossover/injection, families and branches, pairwise preference ranking, lineage panel), per-image snapshots in basic rounds and draft protection in deep rounds. Algorithm design inspired by [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio); reimplemented in Dart.
- **Gallery overhaul**: multi-source galleries, default masonry layout, advanced filters with precise local model-version filtering, collections (root/subset linking), trash pool (soft delete), three-channel NAI-only filtering, HD/SD thumbnail quality tiers, unified drag-out across all three views, tag-library masonry view, envelope-metadata backfill, and byte-level dedup on image save.
- **Character prompt editor**: official-site-style persistent layout, selection follows focus, fields auto-grow with content (3–12 lines).
- **Opus quota & billing**: an Opus free-quota chip in the pinned bar (official `usage.percent` plus refill countdown); free-eligibility rules aligned with observed official behavior, so PR / img2img / inpainting no longer wrongly cancel free generation.
- **Guest mode**: skip login from the login screen and use all offline features (local gallery, tag catalogs, prompt blocks) with an in-memory session that never persists.
- **Prompt-syntax & metadata toolchain**: unified NAI lexer with a numeric-weight tail guard (weight joins no longer misread by the server); removed the focus-loss space-to-underscore conversion; unified Magic Byte metadata parsing for PNG / WebP / JPEG; anti-hotlink header dispatch for the AI TAG online gallery.

See the `1.0.0` section of [CHANGELOG.md](CHANGELOG.md) for details.

## 🖥️ Interface Preview

<p align="center">
  <img src="screenshots/generation_pill_block_library.png" alt="Generation UI: pill editor and block library" width="80%">
  <br>
  <em>Generation UI: pill editor (block highlighting) with the block library panel (official presets and artist pools)</em>
</p>

<p align="center">
  <img src="screenshots/prompt_block_manager.png" alt="Prompt block manager" width="80%">
  <br>
  <em>Prompt block manager: folder tree, multi-select bulk operations, custom colors and icons</em>
</p>

<p align="center">
  <img src="screenshots/block_instance_settings.png" alt="Block instance settings" width="40%">
  <br>
  <em>Block instance settings: fixed / sequential / random-draw modes with count range, weight distribution, and trigger probability</em>
</p>

<p align="center">
  <img src="screenshots/local_gallery_masonry.png" alt="Local gallery masonry" width="80%">
  <br>
  <em>Local gallery: masonry layout, category tree, NAI-only and model-version filters</em>
</p>

## 🧩 Platform Support

| Platform | Status | Description |
| --- | --- | --- |
| Windows | Available | Primary development and release platform. Supports system tray, window state persistence, video playback, clipboard, and file location. |
| macOS | Minimal Support | Supports building, launching, login, local database, video playback, Keychain, system proxy, image copying, and file location. System tray support to be added later. |
| Linux | Unreleased | Desktop code branches exist, but official packages are not currently provided. |
| Android | Planned | Still in the adaptation/planning phase. |

## 📦 Download & Install

Download the latest version from [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases). In-app auto-update is disabled in this fork; please download new versions manually.

| Platform | Download File | Usage |
| --- | --- | --- |
| Windows | `NAI_Launcher_Windows_<version>_Setup.exe` | Installer version, recommended for general users; installs to the current user directory. Manual setup detects and closes an older version still running in the tray. |
| Windows | `NAI_Launcher_Windows_<version>_Portable.zip` | Portable version. Extract and run `nai_launcher.exe`; to upgrade, download the new archive and replace in place — user files stay in the program directory. |
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
