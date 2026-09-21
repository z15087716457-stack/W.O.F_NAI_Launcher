# 自由画布验收检查点

本版本已获用户确认，保存为本地恢复基线。

- Git 标签：`checkpoint/canvas-verified-2026-09-21`，以此标签解析出的提交为准。
- 基础分支：`bridge-takeover`。
- 范围：生成立即占位与对焦、画布点击/相机/输入、视口固定工具条、历史多选、流式局部预览、动作门控、原图元数据保存与固定图区。
- 已运行全量测试：3051 通过、6 个原有跳过、0 失败；build_runner 成功；本次修改无静态诊断，原有实验测试文件仍有 9 条提示。
- Windows Debug 已构建并由用户核验。包内 kernel SHA-256：`86835fc1ef0ae4339a0286bc2d99647aa230631e55cd57be917722a99051e596`。
- 工作区独立备份：`nai-launcher-checkpoints/2026-09-21-canvas-verified/`，包含完整程序压缩包、源码归档和恢复说明；位于本仓库外，不随后续 `flutter clean` 删除。
- 本检查点不包含个人账号、提示词草稿、图库或应用数据的快照。

## 恢复方式

仅恢复程序时，将备份中的 `windows-debug.zip` 完整解压到新目录，退出正在运行的实例后打开其中的 `nai_launcher.exe`；保留同目录的 DLL 和 data 资源。

需要检视或重新构建本版源码时，在当前仓库执行以下命令创建独立副本，避免覆盖后续未提交工作：

```bash
git worktree add ../nai-launcher-canvas-checkpoint checkpoint/canvas-verified-2026-09-21
```

这是本地检查点，不是新版本发布。完整 moodboard 编辑器、便签/箭头、探索货架及无限历史不包含在本版。
