# 本机 2.4.2+118 交付核验

2026-11-17按用户要求，把六批待交付改动安装至原桌面运行目录，版本升级为 **2.4.2+118**。随后按追加指令备份并清空旧RAG索引。未自动启动应用，待用户实测；未提交、推送或发布GitHub，公开版仍为2.4.1+115。

## 包含内容

1. [DanbooruSearch规则对齐](danbooru-search-alignment-2026-11-16.md)：分词、四路召回配额、精确评分及额外本地标签接入，保留EmbeddingGemma 2；支持增量语料和Agent按次检索选项。
2. [维护清理](system-cleanup-2026-11-17.md)：退役旧RAG协议、孤立词库、旧设置／生图入口及对应旧测试，保留当前功能和用户原始资料。
3. [翻译与权重修复](translation-alignment-and-weight-fill-2026-11-17.md)：原文对齐、请求状态及行尾底色修复。
4. [图库提示词搜索](gallery-prompt-search-2026-11-17.md)：整段加权提示词检索、统一归一化与明确标签筛选；首次启动自动修正派生文字索引。
5. [第三方API兼容](third-party-api-compatibility-2026-11-17.md)：地址识别、连接JSON导入、超时、未知余额和虚拟Opus资格修正。
6. [轻量翻译自动补译](auto-inline-translation-2026-11-17.md)：分隔线下独立开关默认关闭，800ms防抖增量翻译，缓存／IME／取消及撤销保护。

## 构建与程序核验

| 项目 | 结果 |
|---|---|
| 源码 | `.devin/wt/ui-integration`，HEAD `517163c5455ac765158016aa9204f4a5bca57da0` 加未提交改动 |
| 输入 | 冻结2,018项；相对+117改变81项、退役161项输入；保护226项已有文件改动 |
| SDK | Flutter3.47.7／Dart3.13.5，Windows Release，`--no-pub --no-tree-shake-icons` |
| 实际运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本 | EXE ProductVersion `2.4.2+118`、FilePrivatePart118；包信息与清单一致 |
| 程序 | 15,561项核验，交付15项，其中新增4项；移除1项退役资源 |
| 原生及Agent | 原生DLL代码与依赖保持；Agent完整清单同步，仅更新检索schema及说明，Pi1.5.0保持 |
| 回退 | +117完整data、被替换／移除文件和旧收据已备份核验；未实际降级 |

AOT SHA-256：`9ce5a89bbdaca9b92c25d59058d0f87bc0c1889823eeeeedb3a80cd94a8d76f2`。构建约137秒，安装约44秒。没有用标准Release整目录覆盖Glass运行包。

## 用户数据与索引清理

安装前后44项关键文件哈希保持，覆盖账号、设置、提示词块库、编辑草稿、参考库和翻译／私人语义资料；图库数据库与扫描状态、数据根、AppData Junction、桌面快捷方式保持。

安装核验完成后，按用户「索引数据删了」的明确指令，只清理`user-data/rag/v1/indices/`内旧索引文件：3项、5,505,283字节，原集合数量为`{"blocks": 726}`。旧标签索引此前已清理，本次清除剩余提示词块向量；提示词块原文文件保持。当前索引目录无文件，未建立新索引。

删除前逐文件备份、校验、复核进程退出与目标路径；备份位于`.dart_tool/local-2.4.2-build118-20261117/index-backup/`，清理证据为`index-reset-before.json`和`index-reset.json`。程序回退与索引恢复独立，回退不会自动覆盖后来新建的索引。

重新打开后，按需要为标签、Wiki、提示词块和图库建立索引。自动补译默认关闭，需在翻译菜单自行开启；真实模型质量、Windows输入法体验和全库语义效果仍待实测。

## 验证与边界

复用各批已完成的相关回归：最新翻译／编辑器／接线1,018项、第三方API316项、图库768项及此前检索／清理验证，计数有重叠，不相加为独立总数；全仓分析0问题。交付新增真实原生worker与固定CSV检查1项、Agent schema8项、分发入口3项和安装／失败恢复／回退4项，全部通过。

随包真实worker使用隔离目录与模型指纹替身，不推理真实权重或操作正式索引。此次未请求语言模型或NAI，未执行正式图库的首次启动迁移，也未自动启动Studio。

收据为`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`；完整材料在`.dart_tool/local-2.4.2-build118-20261117/`。只读核对回退：`python .dart_tool/local-2.4.2-build118-20261117/update.py verify-backup`；实际恢复+117使用同脚本`rollback`，须完全退出Studio和托盘。
