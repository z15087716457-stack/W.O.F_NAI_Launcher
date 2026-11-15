# 本机2.4.0+108交付

2026-11-15，按用户要求修正2.4.0的轻量翻译并重新更新桌面。有效源码为本工作树，构建提交`3999baffedd34d26fbbe52ae1411275df7c8a423`；安装目录仍为`nai-launcher-src/build/windows-glass-preview/runner/Release/`，原快捷方式保持，未启动或重启Studio。

## 结果与核验

- 原文直接编辑，译文只读并持续显示。部分修改用现有12px线性扳手与「待更新」，整段删除后对应注释消失；原生光标／选区／输入法、复制与生成投影保持。见[实现与回归](inline-translation-edit-2026-11-15.md)。
- 冻结2170个生产输入，较+107仅18项有变化；源码提交时工作树干净。Windows Release编译完成，AOT SHA-256为`ecf0f86b33c6902dd08a64d0b3c1a4ee445a93bc1aba9da525ba2c2e1de2f122`。
- 差量替换5个文件：CHANGELOG.md、package-info.json、data/app.so、nai_launcher.exe、app_files_manifest.json。15557个程序文件逐项核验通过；无新增／移除文件，资源、原生DLL及15280个Agent文件保持，Node24.18.0／Pi1.5.0不变。
- 396项相关Flutter回归、179项最终布局／语法／生成接线检查、全仓分析0问题，3项打包与4项隔离安装器检查通过。Node／RAG代码未变，复用+107验证；未请求真实模型或生成接口。
- 14项关键用户文件、用户根目录元数据、图库数据库、3个RAG索引文件、旧数据入口及快捷方式保持。未清理历史payload、回退或缓存。

## 回退与本轮纠正记录

原本只应核验回退材料，但执行时误用了实际rollback命令，程序曾回到+107。随后使用同一份已冻结的+108差量载荷重新应用，并重新核验所有程序文件、当前收据及关键用户数据；**最终安装为2.4.0+108**。没有重新编译另一份源码或改写用户数据。

原回退备份、首次安装记录、实际回退记录及重新应用材料均保留在`.dart_tool/local-2.4.0-build108-20261115/`；`reapply-after-rollback/result.json`、`final-verification.json`、`user-data-preservation.json`记录最终结果。

只校验备份：`python .dart_tool/local-2.4.0-build108-20261115/update.py verify-backup`。

需要真正降级时，先完全退出Studio及托盘，再运行`python .dart_tool/local-2.4.0-build108-20261115/update.py rollback`，它会恢复+107程序与旧收据；此命令会实际执行回退，不是只读检查。

同源码Windows／Mac正式包已发布且实际下载核验；公开发布证据见[2.4.0发布核验](release-2.4.0-2026-11-15.md)。本机安装不代表公开成品或Mac实机验收。
