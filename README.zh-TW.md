<p align="center">
  <img src="assets/images/wof_logo_full.png" alt="W.O.F NAI Studio" width="300">
</p>

<p align="center">
  <a href="README.md">简体中文</a> ·
  <strong>繁體中文</strong> ·
  <a href="README.en-US.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a>
</p>

<h3 align="center">讓 NovelAI 生圖成為一套能累積、能重複使用的創作工作台</h3>

<p align="center">
  <a href="https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/latest"><img src="https://img.shields.io/github/v/release/z15087716457-stack/W.O.F_NAI_Launcher?label=%E4%B8%8B%E8%BC%89&color=2f80ed" alt="下載"></a>
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011%20x64-0078D4?logo=windows11&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/%E4%BB%8B%E9%9D%A2%E8%AA%9E%E8%A8%80-%E7%AE%80%E4%B8%AD%20%2F%20%E7%B9%81%E4%B8%AD%20%2F%20EN%20%2F%20%E6%97%A5%E6%9C%AC%E8%AA%9E%20%2F%20%ED%95%9C%EA%B5%AD%EC%96%B4-555" alt="五種介面語言">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT"></a>
</p>

<p align="center">
  <img src="docs/images/readme/zh/hero.webp" alt="W.O.F NAI Studio 生圖頁" width="100%">
</p>

W.O.F NAI Studio 是 Windows 桌面上的 NovelAI 第三方用戶端。它不只是把官網搬到桌面：常用的提示詞可以存成**積木**重複使用，畫師組合可以交給**畫風遺傳**逐代篩選，看不懂的標籤有**翻譯、標籤百科和本機語義檢索**幫忙，生成、整理、修圖的雜事也可以交給內建的 **NAI Agent**。

> 這是非官方專案，與 NovelAI 無關。請使用你自己的 NovelAI 帳號，並遵守 NovelAI 的服務條款。

## 下載

到 [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/latest) 下載最新版本，二選一：

| 檔案 | 適合誰 |
| --- | --- |
| `WOF_NAI_Studio_Windows_<版本>_Setup.exe` | **大多數人選這個。** 安裝到目前使用者的目錄，不需要系統管理員權限，附開始功能表和桌面捷徑。 |
| `WOF_NAI_Studio_Windows_<版本>_Portable.zip` | 想放在自己指定的資料夾、隨身碟，或帶到不同電腦上使用。解壓縮後執行 `nai_launcher.exe`。 |

兩個版本都支援應用程式內更新。你的設定、圖庫資料庫和 Agent 資料都放在程式旁的 `user-data/` 和 `agent-data/`，升級和解除安裝都不會刪除。

> 安裝檔尚未進行程式碼簽章，第一次執行時 Windows 可能顯示「Windows 已保護您的電腦」。點選「其他資訊 → 仍要執行」即可。每個版本都附有 SHA-256 校驗值。

## 三步上手

1. **登入**：使用 NovelAI 的 API Token（建議）或帳號密碼登入；也可以先以訪客身分進入，體驗本機功能。
2. **生成**：在左側輸入提示詞，按 `Ctrl+Enter`。結果會分批鋪在中間的畫布上。
3. **累積**：把常用的畫師串、品質詞存成積木；滿意的圖片自動存入本地畫廊，隨時重複使用參數。

詳細說明請見 [快速上手](docs/guide/zh-TW/quick-start.md)。

## 能做什麼

### 積木：寫一次，重複用

<img src="docs/images/readme/zh/blocks-library.webp" alt="積木庫" width="100%">

把畫師池、品質詞、負面詞、服裝清單這些常用片段存成「積木」，拖進提示詞就能用。一個積木還能同時附帶負面詞和生圖參數，把喜歡的整套畫風存成「畫風塊」，插入後一鍵套用參數。每個積木可以設定三種方式：

- **固定**：每次原樣插入，適合品質詞和負面詞；
- **順序**：每次生成換到下一項，適合逐一試過一組服裝或場景，也可以把故事寫成幾幕，一幕接一幕推進；
- **隨機**：每次從池裡抽幾項，還能設定抽取數量、出現機率和隨機權重，適合批次測試畫師組合。

抽到滿意的結果就**鎖定**，再重新抽取其他積木。→ [積木教學](docs/guide/zh-TW/blocks.md)

### 畫風遺傳：讓好看的組合自己「進化」

<img src="docs/images/readme/zh/explore-evolution.webp" alt="畫風探索與遺傳" width="100%">

不知道哪幾位畫師混在一起好看？在畫風探索裡放一個隨機畫師池，一次抽出幾十張候選圖片。挑出喜歡的幾張，開始進化：程式會對它們的畫師串進行交叉、變異，並注入新畫師，生成下一代。你只管挑選，幾代之後畫風就會朝你想要的方向靠攏。滿意的組合可以一鍵存成積木。→ [畫風遺傳教學](docs/guide/zh-TW/style-explore.md)

### 翻譯塊、標籤擴展與標籤百科：看懂每一個標籤

<table>
  <tr>
    <td width="50%"><img src="docs/images/readme/zh/translation.webp" alt="翻譯塊"></td>
    <td width="50%"><img src="docs/images/readme/zh/tag-expansion.webp" alt="標籤擴展"></td>
  </tr>
  <tr>
    <td>
      <b>翻譯塊</b>：把英文提示詞翻成中文，直接顯示在原本的位置。按一下滑鼠中鍵就能切換原文與譯文。生成時一律使用原文，翻譯只幫助閱讀。翻譯時會附上本機標籤庫和 Wiki 裡命中的術語表，避免模型把畫師、作品名稱當成一般詞語。→ <a href="docs/guide/zh-TW/translation.md">教學</a>
    </td>
    <td>
      <b>標籤擴展</b>：<code>Ctrl+點選</code>提示詞裡的標籤，搜尋本機標籤庫；<code>Ctrl+拖曳選取</code>一段文字，查看哪些標籤經常一起出現。→ <a href="docs/guide/zh-TW/tags-wiki.md">教學</a>
    </td>
  </tr>
</table>

<img src="docs/images/readme/zh/wiki.webp" alt="標籤百科" width="100%">

**標籤百科**隨軟體附有本機 Danbooru Wiki，離線也能查詢標籤的意思、經常搭配的標籤，並一鍵新增到積木。

### 本機語義檢索（RAG）：用意思找東西

<img src="docs/images/readme/zh/settings-rag.webp" alt="語義檢索設定" width="100%">

這是選用元件。啟用後，標籤推薦、標籤百科、積木庫和本地畫廊都能依「意思」搜尋：輸入「下雨的街道」也能找到相關的英文標籤、積木，以及你以前畫過的圖片，還能以圖找相似圖片。全部在你的電腦上執行，不會上傳任何內容。→ [語義檢索教學](docs/guide/zh-TW/rag.md)

### NAI Agent：把雜事交給 AI 助手

<table>
  <tr>
    <td width="62%"><img src="docs/images/readme/zh/gen-agent.webp" alt="生圖頁裡的 NAI Agent"></td>
    <td width="38%"><img src="docs/images/readme/zh/agent-approval.webp" alt="Agent 操作確認"></td>
  </tr>
</table>

在生圖頁或畫風探索頁開啟側欄，用聊天的方式讓 AI 幫你修改提示詞、查詢標籤和百科、整理積木和圖庫、設定參考圖，甚至準備一次生成。它使用你自己在「模型與介面」裡設定的大型語言模型服務。

- 修改、刪除、執行命令前會先詢問，權限分為只讀、詢問、自動、完全權限四種；
- **花費 Anlas 的生成，無論哪種權限都要你親自在價格卡上確認**；
- 一次寫好一組提示詞（幾幕故事、一組試穿服裝、幾個分鏡），在提示片語卡裡逐項切換、匯入畫布或單張生成；
- 支援技能（Skill）、MCP 伺服器和 CodeMode，可以依自己的工作流程擴充。

→ [NAI Agent 教學](docs/guide/zh-TW/nai-agent.md)

### 無限畫布與視覺通道

<img src="docs/images/readme/zh/channel.webp" alt="無限畫布與視覺通道" width="100%">

生成結果分批鋪在一張能無限拖曳的畫布上，使用滾輪平移、`Ctrl+滾輪`縮放、WASD 導覽，按住空白鍵查看局部重繪前的原圖。畫布兩側可以開啟「視覺通道」裝飾：星圖、像素電路、深海、地鐵等 11 種主題，只繪製在圖片之外，不遮擋圖片。→ [畫布教學](docs/guide/zh-TW/canvas.md)

### 本地畫廊與線上畫廊

<table>
  <tr>
    <td width="50%"><img src="docs/images/readme/zh/gallery.webp" alt="本地畫廊"></td>
    <td width="50%"><img src="docs/images/readme/zh/online.webp" alt="線上畫廊"></td>
  </tr>
</table>

- **本地畫廊**：統一瀏覽多個圖庫資料夾，依日或月分組的連續時間軸，依提示詞搜尋，支援收藏集、批次移動和刪除池；任何一張 NAI 圖都能一鍵重複使用參數。
- **線上畫廊**：Danbooru、Safebooru、Gelbooru、AI TAG 四個來源，支援排行榜、收藏和黑名單，看到喜歡的作品可以直接重複使用生成參數。

→ [畫廊教學](docs/guide/zh-TW/gallery.md)

### 參考圖、導演工具、局部重繪與放大

<table>
  <tr>
    <td width="50%"><img src="docs/images/readme/zh/tools-inpaint.webp" alt="局部重繪"></td>
    <td width="50%"><img src="docs/images/readme/zh/tools-upscale.webp" alt="放大"></td>
  </tr>
</table>

- **風格遷移與精準參考**：參考圖庫統一管理 Vibe 和精準參考，編碼過的 Vibe 可以重複使用；
- **導演工具**：背景移除、線稿擷取、上色、表情修復、像素對齊等；
- **局部重繪**：具備畫筆、選取範圍、魔術棒和圖層的全螢幕編輯器，畫完直接選擇「應用並生成」；
- **放大**：NovelAI 雲端放大，或在本機使用 Real-ESRGAN、NVIDIA RTX Video、SeedVR2 放大，不花 Anlas。

→ [影像工具教學](docs/guide/zh-TW/image-tools.md)

### 還有這些

- **NovelAI 全模型**：V1 到 V4.5、V5（Full / Curated）、多角色輸入框和角色定位、透明背景、Anlas 即時估算和高消耗提醒；
- **統計**：創作日曆、模型與產量、Anlas 消耗，點選圖表直接跳到當天的圖片；
- **本機橋接**：外部指令碼或 AI 工具可以透過隨附的 `studio-bridge.exe` 讀寫參數，生圖前同樣要報價確認；也支援 Krita 外掛連動；
- **快速鍵**：按 `F1` 查看全部快速鍵，都能自訂；
- **五種介面語言、淺色和深色主題**。

## 隱私與網路

- 帳號 Token 和各家的 API 金鑰儲存在 Windows 系統安全儲存區，只在本機使用。
- 只有下列情況會連網：呼叫 NovelAI API；使用你自己設定的翻譯或 Agent 模型服務；瀏覽線上畫廊；檢查更新；以及你主動點選下載的選用元件（語義檢索模型、放大模型等）。
- 語義檢索、本機放大、圖庫整理都在本機完成。
- 自動翻譯預設關閉；Danbooru 線上關聯標籤只傳送相關標籤，不傳送完整提示詞。

其他問題請見 [常見問題](docs/guide/zh-TW/faq.md)。

## 教學目錄

| 教學 | 內容 |
| --- | --- |
| [快速上手](docs/guide/zh-TW/quick-start.md) | 安裝、登入、第一次生成、資料位置 |
| [積木](docs/guide/zh-TW/blocks.md) | 固定 / 順序 / 隨機、鎖定、權重規則、典型用法 |
| [畫風遺傳](docs/guide/zh-TW/style-explore.md) | 抽取候選、開始進化、兩兩比較、存為積木 |
| [翻譯塊](docs/guide/zh-TW/translation.md) | 設定翻譯模型、雙語閱讀、切換與還原 |
| [標籤擴展與標籤百科](docs/guide/zh-TW/tags-wiki.md) | 本機標籤搜尋、關聯標籤、離線百科 |
| [本機語義檢索](docs/guide/zh-TW/rag.md) | 安裝、建立索引、可使用的地方 |
| [NAI Agent](docs/guide/zh-TW/nai-agent.md) | 設定模型、權限、生圖確認、技能與 MCP |
| [無限畫布與視覺通道](docs/guide/zh-TW/canvas.md) | 畫布操作、原圖比較、裝飾主題 |
| [畫廊](docs/guide/zh-TW/gallery.md) | 本地畫廊整理、線上畫廊瀏覽與參數重複使用 |
| [影像工具](docs/guide/zh-TW/image-tools.md) | 參考圖、導演工具、局部重繪、放大 |
| [常見問題](docs/guide/zh-TW/faq.md) | 安裝提示、資料備份、舊版移轉、隱私 |

<details>
<summary><b>從原始碼建置</b></summary>

需要 Windows 10/11 x64、Flutter 3.47.7（見 `tool/flutter-sdk.json`）、Visual Studio 2022 的「使用 C++ 的桌面開發」、Git LFS 和 NuGet CLI。

```bash
git clone https://github.com/z15087716457-stack/W.O.F_NAI_Launcher.git
cd W.O.F_NAI_Launcher
git lfs install && git lfs pull
flutter pub get
dart run tool/generate.dart
flutter gen-l10n
flutter build windows --release --no-tree-shake-icons
```

使用 `scripts/package_windows_release.ps1` 製作安裝版與可攜版。開發約定請見 [DEVELOPMENT.md](DEVELOPMENT.md)，版本紀錄請見 [CHANGELOG.md](CHANGELOG.md)。

</details>

## 致謝與授權

- 本專案分支自 [Aaalice233/Aaalice_NAI_Launcher](https://github.com/Aaalice233/Aaalice_NAI_Launcher)（MIT），感謝原作者的開源工作。本分支與上游作者無關，問題請回報至本儲存庫的 Issues。
- 畫風遺傳的演算法構想參考 [monineko/PromptCard-Studio](https://github.com/monineko/PromptCard-Studio)（GPL-3.0），本專案採獨立的 Dart 實作，未複製其原始碼。
- NAI Agent 以 [Pi](https://github.com/earendil-works/pi)（MIT）為基礎。
- 本專案以 [MIT License](LICENSE) 開源；隨附的資料、字型和元件遵循各自的授權，詳見 [第三方聲明](THIRD_PARTY_NOTICES.md)。

README 中的介面截圖使用示範資料繪製，範例提示詞與畫師名稱皆為虛構。
