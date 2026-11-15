# 图片、Vibe 与 PR 文件目录收敛

状态：有效源码 `codex/uiux-integration` 已完成，未构建／安装；桌面仍为 **2.3.4+103**。本次未启动 Studio、请求 NAI／模型接口、提交或推送 Git，也未修改真实用户路径设置或搬动素材。

## 当前行为

Windows 默认路径从 EXE 所在目录解析，复用现有 `user-data/`，与启动时的工作目录无关：

```text
<启动器目录>/user-data/
├── images/Uncategorized/  自动与手动保存的生成图片
├── vibes/                Vibe 文件
└── precise_refs/         PR 精准参考原图
```

macOS 沿用应用支持目录 `~/Library/Application Support/com.wof.naiStudio/` 下的同名子目录，不写入 `.app`。沙箱继续使用隔离的数据根目录。

- 「图片保存位置」改名为「生成图片保存目录」，补充实际写入的 `Uncategorized` 完整路径。选定的仍是保存根目录，浏览来源独立。
- 「Vibe 文件目录」显示真实解析路径，移除写死的 Documents 简写；新增同组件的「PR 文件目录」，支持选择、打开及恢复默认。
- 右侧目录入口、存储图例、容量扫描和设置搜索补齐 PR。PR 原图位于某个图库来源内部时优先归入 PR，只计一次。
- 参考库页面同时为 Vibe 与 PR 解析目录；“打开库目录”点击时读取最新设置，切换目录后不再打开旧缓存。显式打开尚未建立的素材目录时才创建它，普通路径读取不创建素材子目录。
- 五语言文案、指南同步，沿用现有路径框、图标、恢复默认和未保存蓝点规则。

## 已有数据

已有自定义保存路径不变。修改目录只改变后续写入位置，已有条目保留绝对文件路径，收藏、标签与 ID 保持；本次没有执行真实文件迁移。

未自定义时，旧 `Documents/NAI_Launcher/images` 保留为默认浏览覆盖与旧分类基准；已明确配置的来源（包括空列表）继续尊重原值。旧分类配置不跟随新的保存目录搬迁。

Vibe 同步兼容旧 Documents 默认目录；优先使用较新的 `NAI_Launcher/vibes`，否则回查更早的 `Documents/vibes`，避免把历史迁移保留的副本重复入库。尚未使用的新默认目录可以不存在；已使用目录或自定义目录不可读时仍报告失败并保留元数据，不能按空目录清掉条目。PR 启动核对兼容旧默认目录及原有条目路径，新的导入使用当前目录。

## 验证

SDK：Flutter 3.47.7／Dart 3.13.5。均使用临时目录、隔离 Hive、替身与真实字体，没有使用真实素材做写入测试。

| 检查 | 结果与证据 |
|---|---|
| 核心与相关回归 | 562 项通过，含设置 UI、路径、Vibe 同步／往返／失败、PR 存储、图库仓库、容量与生图接线；[日志](../.dart_tool/storage-asset-paths-20261114/regression.log) |
| 参考库及受影响界面 | 96 项通过，含 PR 初始化目录、切换后打开最新目录、导入导出、主题与标题栏；[日志](../.dart_tool/storage-asset-paths-20261114/library-verified-final.log) |
| 设置路径与语言 | 37 项通过，含五语言深浅色 900px／150% 布局、路径操作／搜索及语言一致性；[日志](../.dart_tool/storage-asset-paths-20261114/ui-verified-final.log) |
| 旧设置页兼容 | 30 项通过，含图片／Vibe 改路径与恢复默认、来源移除与取消操作；[日志](../.dart_tool/storage-asset-paths-20261114/legacy-verified-final.log) |
| 繁中生成检查 | 4 项通过；[日志](../.dart_tool/storage-asset-paths-20261114/l10n-zh-tw-final.log) |
| 代码与语言生成 | 代码生成 301 个输出成功；原先无未提交的 `.g.dart`／`.freezed.dart` 输出。`flutter gen-l10n` 成功 |
| 全仓静态分析 | 0 问题；[日志](../.dart_tool/storage-asset-paths-20261114/analyze-verified.log) |

各批存在重叠，不相加为独立测试总数。过程中修正了旧测试夹具调用真实图库服务、在假时钟中等待文件 IO，以及把取消操作后的来源误定为空的断言；最终旧设置页全文件已通过。

布局已查看[宽窗深色实绘](../.dart_tool/storage-asset-paths-20261114/captures/storage-paths-dark.png)及[窄窗浅色 150% 实绘](../.dart_tool/storage-asset-paths-20261114/captures/storage-paths-narrow.png)。三个路径框继续使用原有 380×30px 组件、同列对齐；[本次批量尺寸测量](../.dart_tool/storage-asset-paths-20261114/path-measurement.json)的 x／宽／高残差最大 **0px**。新增 PR 行、保存目标换行与旧素材说明是有意变化，分次滚动捕获的 y 坐标不做对齐依据。

现有 `tool/ui_shell/settings_prototype_capture_test.dart` 的存储页捕获已通过。历史 `settings_measure.py` 仍指向已移除的 `wt/ui-settings`，缺少可运行的旧 HTML，不能声称本次完成整页 HTML 叠对；上面的 0px 仅指组件尺寸与列对齐。既有七张设置 golden 差异此前已复现，本次保留原 PNG，未更新基准，也不将它们列为通过。

改前备份、全量差异及边界核对见本机 `.dart_tool/storage-asset-paths-20261114/`。旧模型记录、词库数据、其他未交付改动及安装目录保持。
