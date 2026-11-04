# 设置目录打开卡住 · 调查与修复

日期：2026-11-03。已随本机 **2.2.5+81** 安装；公开仍为 2.2.5+80，本批未推 Git，未自动启动。[交付与回退](local-2.2.5-build81-2026-11-03.md)。

## 现场与调用链

点击 Skill 行子菜单的“打开文件夹”后，真实进程显示未响应。只读取进程和窗口信息，没有终止或操作用户窗口，也没有生成内存转储。Windows 等待链确认主窗口线程 5652 处于阻塞状态，但未返回具体内部调用栈，不能断言某个 Shell 扩展是根因。

入口依次经过 `onOpenSkillFolder`、`SettingsAgentBackend.skillFolder` 和 `openPath`；点击不会刷新或扫描 Skill。原路径通过 `launchUrl(Uri.directory(path))` 打开，已安装的 `url_launcher_windows 3.1.5` 原生插件同步调用 `ShellExecuteW`。这与窗口线程阻塞一致，是本次需要绕开的调用路径。

## 改动

- `SettingsAgentBackend.openPath` 保留创建缺失目录的原行为，随后复用现有 `FileExplorerUtils.openDirectory`。
- `SettingsStorageActions.open` 同样复用该入口，覆盖设置里的图库、缓存、日志、其他目录位置及 Skill 根目录，不再使用目录 file URL。
- 既有工具将本地路径作为单一参数异步启动 `explorer.exe`。没有新增 provider、服务、超时、重试或平台兜底；共用工具和文件定位逻辑没有改动。网页、文件编辑入口、Skill 扫描和 UI 保持。

## 验证与边界

- 37 项不同回归通过：Explorer 工具 5 项、设置接线／后端／Skill UI 共 32 项。新增目录路径测试覆盖中文、空格、加号、百分号与逗号；新增子菜单测试覆盖内置／用户 Skill 各自的打开动作和菜单收起。
- 工具测试使用原有进程启动注入，UI 使用动作记录器，没有启动真实 Explorer 或触碰用户 Skill。设置后端与接线运行于隔离数据。
- 原 Skill 调用模式测试仍有一次旧的文字命中警告，最终断言通过；该警告不在新增子菜单测试，未为此修改产品逻辑或隐藏警告。初次新增测试缺少组件 import 导致编译失败，补齐 import 后完整 Skill 文件重跑通过，原日志保留。
- 生产改动仅两个已有设置接线文件，没有修改共用组件或资源，无需代码生成。未强退、重启、热重载用户应用；本次验证不能声称旧进程已经恢复或真实点击问题已经实机复测。
- 两个生产文件、共用目录工具与两个相关测试文件共 5 文件分析无问题。

材料位于 `.dart_tool/skill-folder-hang-20261103/`：`wait-chain.json`／`wait-chain-com.json`、`explorer-tests.log`、`settings-regressions.log`、`skills-tests-final.log` 和 `analyze-final.log`。最后一份 Skill 回归包含新增用例，重复用例不累加计数。
