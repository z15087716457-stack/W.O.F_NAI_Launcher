# F11 · 清空撤销提示两秒消退

2026-10-15。用户反馈点击提示词框的清空按钮后，底部“清除／撤销”一直保留，要求显示两秒后消退。已本地修复，随 F07–F10 继续积攒，桌面仍为 r7，未构建 Release 或安装。

## 原因与修改

登记的 Flutter 3.47.7 在 `packages/flutter/lib/src/material/snack_bar.dart` 中将带 action 的 SnackBar 默认设为 `persist=true`；`scaffold.dart` 的超时处理会跳过它，因此此前“撤销”按钮使提示一直保留。

仅在 `GenerationOperations.clearPrompt` 的 SnackBar 显式设置 `duration: Duration(seconds: 2)` 与 `persist: false`，使用原有退场动画。主提示词、负面、角色正负面及探索的共用清空入口均沿用这条接线；期间仍可撤销。清空／撤销备份及新状态冲突保护的后端代码保持不变，其他提示条不受影响。

## 验证

证据目录：`.dart_tool/prompt-clear-notice-20261015/`。

- 修复前，通过真实清空按钮分别复现主正面、主负面、角色正面、角色负面提示超时后仍留存，4 项消退测试失败；原有撤销可用，见 `reproduce-before.log`。
- 修复后，四种提示在 1.9 秒仍可见，满两秒开始退场，动画结束后消失，内容继续保持清空；一秒内点击撤销能恢复原内容，并保留清空／撤销两次备份。
- 实际生图页面接线与六套规定的生图核心／桥接测试共 89 项通过，使用隔离存储、合成草稿与生成替身；界面测试加载真实字体，见 `regression.log`。全仓分析无诊断，见 `analyze.log`。
- 395 份受保护文件哈希均保持，包括全部 142 份锁定 UI、249 张现有测试 PNG、已有 DEVELOPMENT 修改、清空后端及桌面 r7 的 AOT／安装收据，见 `baseline.json`、`boundaries.json`。

原始截图保存在工作区 `04_工具/开发计划/反馈截图/2026-10-15-r7/11-*.png`。没有操作 Studio、改用户草稿或配置、请求模型或生图、重打便携包或推送 GitHub。
