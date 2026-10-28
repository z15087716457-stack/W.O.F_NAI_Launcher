# 权重着色区域光标不可见修复

2026-10-28，本项已随本机 **2.2.0+60** 原位安装，编译 `bc745f5af`，安装校验与回退通过。当前无待安装增量；下文保留源码实现阶段的原因与验证。完整交付见[+60 安装记录](local-2.2.0-build60-2026-10-28.md)。

## 原因与修复

Windows 的 Material `TextField` 默认把原生光标画在文字下方。权重高亮使用不透明的 `TextSpan.backgroundColor`，会覆盖已经定位正确的光标。合成编辑器复现中，点击色块内各字符、平台输入及左右键定位均正常；普通文字有 36 个光标色像素，着色文字仅在底色外露出 2–4 个像素，主体被遮住。

`NaiSyntaxController.buildTextSpan` 在实际 `EditableText` 的渲染更新后，使用公开的 `EditableTextState.renderEditable.paintCursorAboveText` 把原生光标放到文字前景。Material 在每次重建时都会恢复平台默认值，因此每次构建后应用；回调在状态销毁后跳过。普通 `Text.rich` 与 `TextPainter` 测量路径不触发此操作。

修改覆盖统一提示词编辑器（主提示词、负向及角色等复用路径）和翻译块原文输入。保留原生光标的颜色、大小、闪烁、点击定位和输入处理；权重颜色、背景、文字、选区缓存及块逻辑不变。未修改 SDK，也未更改平台主题。

## 验证

- 修复前的正式回归测试稳定复现：所有点击位置和输入断言通过，着色区域的光标像素断言失败。
- 新增 8 组 widget 实绘检查：Windows × 深浅主题 × 240/500px × 统一输入/翻译块原文；逐个点击普通文字及六类权重文字，检查选区位置与光标像素，并模拟平台插入和方向键移动。
- 相关回归 **305 通过、0 失败**（含上述 8 组）：`test/presentation/widgets/prompt`、生图页普通/紧凑输入、权重工具栏。覆盖既有选区可见性、撤销、搜索替换、药丸、内部翻译和拖放。
- 全仓 `flutter analyze --no-pub`：**No issues found**。
- 同条件实绘前后比较：八张合成输入截图仅光标附近 2–3px 宽区域变化，文字位置和着色不变。使用真实字体；这些是合成 widget 截图，不是用户运行窗口。

证据位于有效源码 `.dart_tool/syntax-caret-20261028/`：`before.log`、`before/`、`caret.log`、`after/`、`regression.log`、`analyze.log`、`pixel-comparison.json`、`verification.json`。验证 SDK 为登记的 Flutter 3.47.7 / Dart 3.13.5；未重跑全量回归或 Node 测试，未改其代码。

源码实现阶段未启动、重启、热重载或操作 Studio，未读取或改写用户提示词、草稿、桥接或正式索引，未生图、调用模型、发布或制作分发包。
