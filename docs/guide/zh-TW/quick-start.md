> [← 返回首頁](../../../README.md) · [教學目錄](README.md)

# 快速上手

## 1. 安裝

到 [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/latest) 下載：

- **安裝版** `WOF_NAI_Studio_Windows_<版本>_Setup.exe`：按兩下安裝，預設安裝到 `%LOCALAPPDATA%\Programs\W.O.F NAI Studio`，不需要系統管理員權限。
- **可攜版** `WOF_NAI_Studio_Windows_<版本>_Portable.zip`：解壓縮到任意資料夾，執行其中的 `nai_launcher.exe`。

系統需求：Windows 10 或 11（64 位元）。

> 安裝檔尚未簽章。Windows 顯示「Windows 已保護您的電腦」時，點選「其他資訊 → 仍要執行」。如果擔心檔案遭到竄改，可以比對 Release 頁面附上的 SHA-256 校驗值。

## 2. 登入

- **API Token（建議）**：在 NovelAI 網站的帳戶設定裡產生一個以 `pst-` 開頭的 Persistent Token，貼上即可。
- **帳號密碼**：和官網相同。
- **訪客模式**：登入頁可以略過登入，先體驗畫廊、積木、標籤百科等本機功能；生成圖片需要登入。

Token 和密碼儲存在 Windows 系統安全儲存區，只在本機使用。

## 3. 第一次生成

<img src="../../images/readme/zh/hero.webp" alt="生圖頁" width="100%">

1. 在左側上方選擇模型（建議 V4.5 或 V5）。
2. 在提示詞框裡輸入英文標籤，例如：
   ```
   1girl, solo, silver hair, starry sky, glowing flowers, night, cinematic lighting, very aesthetic, masterpiece
   ```
3. 在下方設定尺寸、張數和步數；生成按鈕會即時顯示這次要花多少 Anlas。
4. 按 `Ctrl+Enter` 或點選生成。生成途中按 `Esc` 取消。

結果會出現在中間的畫布上，右側是歷史紀錄。畫布操作方式請見 [無限畫布](canvas.md)。

## 4. 幾個馬上能用的技巧

- **調整權重**：選取一段提示詞，按住 `Alt` 並捲動滾輪。
- **儲存積木**：選取一段提示詞，按右鍵選「存為塊」，以後在塊庫點一下就能重新插入。詳見 [積木](blocks.md)。
- **拖入圖片**：把一張圖片拖進視窗，可以選擇圖生圖、風格遷移、精準參考，或只讀取它的提示詞和參數。
- **快速鍵**：`F1` 查看全部快速鍵；`Ctrl+1/2/3` 切換生圖、本地畫廊、線上畫廊，`Ctrl+,` 開啟設定。
- **避免誤花 Anlas**：在設定裡開啟「Anlas 高消耗警告」，單次預估消耗超過設定值時會先詢問。

## 5. 資料在哪裡

| 位置 | 內容 |
| --- | --- |
| 程式目錄下的 `user-data/` | 設定、圖庫資料庫、快取、積木庫等 |
| 程式目錄下的 `agent-data/` | NAI Agent 的工作區、聊天紀錄和技能 |
| 你設定的圖庫資料夾 | 生成的圖片檔案本身 |

備份時一併複製 `user-data/`、`agent-data/` 和圖庫資料夾即可。升級和解除安裝都不會刪除這兩個資料目錄。

## 下一步

- 把常用提示詞整理成 [積木](blocks.md)
- 用 [畫風遺傳](style-explore.md) 找到喜歡的畫師組合
- 設定大型語言模型服務，開啟 [翻譯塊](translation.md) 和 [NAI Agent](nai-agent.md)
