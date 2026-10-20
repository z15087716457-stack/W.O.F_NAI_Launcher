# 2.0 Preview r32 · NAI Agent 对话流第二轮累计更新

用户 2026-10-20 说“ok，推送一下更新”，按 2026-10-15 的本地交付约定安装到原桌面入口，没有推送 GitHub。内部版本 `2.0.0-preview+36`，编译提交 `7b2ab932874187aeb1eadbf1ecad9592b770450e`；之后的文档提交不代表重新编译。

## 内容（r31 之后）

| 提交 | 内容 |
|---|---|
| `5a34b9ca6` | **编辑历史消息**：悬停铅笔或双击，原地编辑（改字、去图），发送后由新 `resendFrom` 先 `navigate` 到该用户条目的父节点、再发新提示，之后的对话被替换；取消不调后端；底部草稿和队列不动。修复铅笔／重新回答在实际运行中缺失的根因（mapper 按嵌套 `message` 查 `userEntries`，宿主实际给扁平的当前分支 `entries`）。重新回答改走同一路径。宿主 `navigate` 在叶子正好是该用户条目时也会退回父节点。**提示词改动卡窗口**：按 tag 切分，只留改动前后各 3 个，长段换成可点的“…”，“展开全部”看全文。**看图合并**：连续完成的 `image_read` 合成一组，放大层支持组内左右切换和方向键。**新卡片**：设置改动（`settings_update` 返回 `before`，24 键映射显示名与设置页定位，撤销复用设置绑定的备份和刷新）、画廊操作（update／delete／restore／move／集合等，结果补 `before` 与版本，撤销前核验版本，缩略图经图库加载器异步缓存）、压缩分隔线（`compactionSummary` 投影，`compaction_end` 后刷新状态）、一轮小结；标签／Wiki 查询结果显示成可复制的小标签。**悬停全文** `AgentOverflowText`；**进场动画** `AgentAppear`（按 id 记住已出现、第一帧不动、折叠交叉淡化）。后端部分由 GPT 子代理实现，主窗口验收 |

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- 回归范围同 r31：**4445 通过／31 失败**，失败集合与 `merged-fails.txt` 逐项相同（`fails14.txt`）。
- `tool/nai_agent` 内置 Node 24.18.0：70／70（含新增 `resend.test.mjs`、`compaction-event.test.mjs`）。

## 构建与安装

- 固定 1996 项生产输入后构建 Windows Release。改了 4 个程序文件：`tools/nai-agent/host.mjs`、`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`；没有新增或删除文件，原生依赖不变。
- 开始准备时 Studio 还在运行。快照记录了运行中的进程，构建只写入暂存区；安装前用户已关闭 Studio，覆盖时没有运行中的进程。
- 安装前通过：打包 Agent 合成冒烟、`list-skills`、RAG 宿主 ready／shutdown、12 项安装回退夹具。安装后逐文件哈希、收据和单步回退备份核对通过；桌面入口、`user-data`、`agent-data` 和 3 个索引文件保持不变。

AOT SHA-256：`13c2d7a2fb519141576727592472e3d9cbe5c912782c4a945d966b51cdef233e`。证据在 `.dart_tool/cumulative-r32-20261020/`，单步回退材料在其 `rollback/`。没有自动启动、生图、建库、打便携包或推送 GitHub。编辑重发、撤销画廊／设置、压缩分隔只在测试中验证过，需要用户在真实运行中确认。
