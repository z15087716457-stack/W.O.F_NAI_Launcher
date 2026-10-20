# 2.0 Preview r30 · NAI Agent 侧栏与生图页修正累计更新

用户 2026-10-20 说“推送一下更新”，按 2026-10-15 的本地交付约定安装到原桌面入口，没有推送 GitHub。内部版本 `2.0.0-preview+34`，编译提交 `856543f75d4625594e94f524b4871e8b146a6232`；之后的文档提交不代表重新编译。

## 内容（r29 之后）

| 提交 | 内容 |
|---|---|
| `405cd5207` | 删掉主生图页遗留的“预览上一张／下一张（历史联动）”快捷键。它挂在整页，和输入框抢 ← →；Windows 上 NumLock 关闭时连小键盘 4／6 也被截走，所以只有主生图页“只能上下不能左右”。新画布一组通常只有一张，按左右只会把镜头拉回当前图。旧配置里的这两项读取时由 `ShortcutConfig.fromJson` 剪掉 |
| `f7fe998f2` | 聊天列表行内删除确认（取消／删除；Esc、取消、点别的行退出，移开不取消）；“⋯”菜单删对话两步（“再点一次删除”），删工作区仍弹确认框。`UiModal.contained`：确认框和改名框只盖侧栏、在侧栏里居中（原来落在画布左下角），看大图仍铺满窗口。权限按钮去掉重复的下拉箭头。设置“Agent 使用的模型”改名“默认模型”，下拉项和按钮用厂商图标，自定义／OpenAI 兼容端点才用字母块（`providerUsesMark` 统一规则），侧栏模型弹层分组标题同样加图标。草稿 `use_coords` 改读角色面板 `!globalAiChoice`，写入时先切面板开关再替换角色，位置卡在自定义定位下正常出迷你定位板（GPT 子代理实现，主窗口验收）。“查看图片”步骤在行下显示缩略图，CodeMode 脚本里看的图挂到成功的 `image_read` 子步骤上 |

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- 回归范围在 r29 基础上加入 `test/presentation/providers/krita`、`test/core/shortcuts`、`test/presentation/screens/generation`：**4361 通过／31 失败**，失败集合与 `merged-fails.txt` 逐项相同（`.dart_tool/agent-fixes-20261019/fails12.txt`）。
- `tool/nai_agent` 内置 Node 24.18.0：65／65。
- 设置页 agent golden 只新增两处遮罩：改名的标题行（到下拉按钮左边为止）和下拉按钮里的图标格。

## 构建与安装

- 固定 1989 项生产输入后构建 Windows Release。只改 3 个程序文件：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`；Agent 宿主和 Skill 不变，没有新增或删除文件，原生依赖不变。
- 安装前通过：打包 Agent 合成冒烟、`list-skills`、RAG 宿主 ready／shutdown、12 项安装回退夹具。
- 覆盖前确认没有运行中的进程。安装后逐文件哈希、收据和单步回退备份核对通过；桌面入口、`user-data`、`agent-data` 和 3 个索引文件保持不变。

AOT SHA-256：`d477804e1eedf4bd9b51efea18f6adca263ef5774dda35ed9744fedbbf75e24c`。证据在 `.dart_tool/cumulative-r30-20261020/`，单步回退材料在其 `rollback/`。没有自动启动、生图、建库、打便携包或推送 GitHub。小键盘左右只做了模拟测试，需要用户在实体键盘上确认。
