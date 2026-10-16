# 启动器目录数据存储与本机迁移

核准日期：2026-10-16（Asia/Taipei）。用户确认内部数据应直接放启动器目录，并已从托盘完全退出后授权迁移。

## 当前结论

本机主数据已经位于运行包旁的 `user-data/`：

- 主数据：`E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/user-data`
- 独立完整备份：`E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/.studio-data-backup-b633375b`
- 旧入口：`C:/Users/PieDriver/AppData/Roaming/com.example/nai_launcher`，现为指向主数据的 NTFS 目录联接。

迁移保留 81,743 个文件、目录结构、两个 Python 内部目录联接及原目录内硬链接关系。逻辑累计约 21.84 GiB，文件 ID 去重约 17.30 GiB。备份与主数据不共用文件硬链接。C 盘可用空间实测从 4.73 增至 22.18 GiB，净增加 **17.44 GiB**。

当前桌面仍为 r9；程序 AOT SHA-256 仍为 `d80769c16ca8a8f82ccfc7cb55ed50e65ca1b0e5d1677862ec254eacd5963409`，安装收据未修改，未安装／启动新版程序。原快捷方式继续使用；旧版本通过兼容联接访问 E 盘同一份数据。默认路径源码与更新／卸载保护已完成，等待下一次统一编译交付。

## 已完成的代码

Windows 的内部支持目录统一经 `lib/core/utils/app_support_directory.dart` 解析到 EXE 旁 `user-data/`，应用自身临时文件位于其 `temp/`。其他平台与测试注入保持原接口；外部图库、用户选定的图片目录和工作区 `临时存图/` 不迁移。Agent 数据原本已位于 EXE 旁，保持现行目录。

`AdjacentAppDataMigration` 在 Hive／SQLite 打开前处理旧目录：独立完整备份、逐文件 SHA-256 校验、核对最新原状态，再发布新根目录；重定向内部 Python 目录联接，旧根目录保留兼容入口。两端有不同数据、外部联接、源数据发生变化或发布失败时拒绝合并并保留／恢复原数据。大模型校验采用 Windows CNG，避免一次载入完整模型。

便携更新即使缺少旧清单也保护 `user-data/`、Agent／WebView 状态和迁移备份；失败回退保留新写入的数据。打包拒绝含私有数据的运行目录，NSIS 排除私有目录，卸载保留这些目录。设置页默认 Hive 路径与五语言资源同步更新。

## 本机数据与验证

本机维护使用受限 8 路并行的 `parallel_migration.py`；所有路径先做边界检查。源、独立备份和最终副本完整枚举／校验，切换前再核对原状态，移除 C 盘副本前再次校验；只移除已知内部联接本身，避免跟随联接删除 E 盘目标。该维护工具 5 个合成夹具覆盖正常迁移、迁移中修改、外部联接拒绝、切换失败回退、目标冲突。

- 最新相关回归：**162 项通过、1 项既有跳过**；覆盖迁移／SHA-256、更新成功／失败／私有包拒绝、RAG、放大组件、Pins、图库存储、Vibe、词库和翻译缓存。
- 台湾正体资源生成测试：4 项通过；五语言代码已生成。
- 全仓 `flutter analyze --no-pub`：无诊断；新增代码格式检查与 diff 空白检查通过。
- NSIS 使用合成载荷编译通过，未运行安装器。
- 真实 RAG 与 SeedVR2 的旧路径 Python 解释器均能启动、导入 Torch，基解释器真实位置均在 E 盘主数据下；Torch 分别为 2.10.0+cu128、2.7.1+cu128。未下载模型、未执行图像推理或调用生图接口。

完整证据在 `.dart_tool/adjacent-data-20261016/`：`migration-result.json`、`parallel-live-migration.log`、`regression-final.log`、`analyze.log`、`installer-check/compile.log`。维护脚本及本次备份属于本机私有材料，不打入便携包或提交用户内容。

## 后续交付约束

下一次本机更新仍只替换登记的程序文件，保留运行目录 `user-data/`、`agent-data/` 与 `.studio-data-backup-*`。已有累计安装器按登记程序清单覆盖，不会枚举替换主数据目录。原生 `CompanyName=com.example`、`ProductName=nai_launcher` 与单实例身份继续保留，用于旧目录识别及兼容；不得把旧空目录或旧备份覆盖回当前主数据。

完整备份先保留在 E 盘，用户完成实际使用验收后再另行决定清理。当前主数据不得与备份合并；旧 C 盘路径是兼容联接，目录逻辑大小不代表其继续占用 C 盘空间。
