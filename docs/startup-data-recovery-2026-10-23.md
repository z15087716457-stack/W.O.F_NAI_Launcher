# 新装配置二次启动白屏修复

2026-10-23（Asia/Taipei）。基于 `927381455` 继续修正，版本保持 `2.1.0+43`；只交付源码，未安装或发布。

## 原因

旧版 `AdjacentAppDataMigration` 只在迁移旧配置时创建兼容联接。首次没有旧数据，或已有相邻配置但旧目录为空时，直接返回 `user-data/`。`flutter_secure_storage_windows` 和 `shared_preferences_windows` 独立解析旧 AppData 路径，运行后可能写出 `flutter_secure_storage.dat`、`*.secure`、`shared_preferences.json`。下次启动两边都有内容，保护代码拒绝合并；错误发生在 `runApp` 之前，窗口因此没有应用界面。

## 修复

- 新建配置、旧目录为空、仅已有相邻配置三条路径都在插件及数据库启动前建立并核验兼容联接。只非递归删除空旧目录；其他安装的联接仍拒绝改指向。
- 已发生的分叉仅允许恢复有明确首次新建标记的配置：`schema=1`、`layout=executable-adjacent`、`legacy` 路径匹配、显式 `backup=null`。旧目录必须全部为根级 `flutter_secure_storage.dat`、`shared_preferences.json`、非空文件名的 `*.secure` 普通文件。未知文件、子目录、链接、无效标记及真正的不同配置继续拒绝自动处理。
- 恢复先创建独立副本并校验 SHA-256，再复核源文件、目标文件和标记。目标同名内容必须相同；缺失文件使用独占创建、文件锁和空文件复查写入，任何既存文件都不覆盖。旧原件改名保留，建立联接并记录备份及旧原件路径。失败回退只清理仍与本次写入内容一致的文件；用户的新修改保留，旧目录尽可能恢复。
- 数据准备失败时显示独立恢复界面，不打开 Hive、SQLite 或业务 provider。提供当前／旧目录、脱敏错误详情、打开目录、复制诊断、重试和关闭。支持五语言及窄窗滚动。目录准备的失败 Future 不再被永久缓存。
- 重试成功后先移除恢复页的重试入口，再进入正常启动；后续业务初始化不会通过数据恢复页重复执行。

## 验证

登记 Flutter 3.47.7 / Dart 3.13.5，所有测试均 `--no-pub`；没有升级依赖、运行业务 codegen 或调用模型／生图。新增文案从四份源 ARB 生成台湾正体，再运行 `flutter gen-l10n`。

执行：

```text
flutter test --no-pub test/core/services test/core/utils test/l10n test/presentation/screens/splash
flutter analyze --no-pub
git diff --check
```

结果：**763 通过，0 失败；全仓 analyze 无问题；diff 检查通过。** 专项 46 项包含在这 763 项内，不重复相加。

关键回归：

- 首次新建后经旧路径写入插件数据，再准备目录：仍指向同一目录，无二次启动冲突。
- 已分叉的三类插件文件恢复、独立备份和旧原件保留、重复启动不重放。
- 同名相同内容保留目标时间戳；不同内容、未知文件／目录、错误或缺失标记、其他安装联接及外部链接拒绝处理。
- 备份期间源、目标和标记变化拒绝提交；联接失败回退，复制后发生的新编辑不删除。
- 同步／异步准备错误均可重试；准备失败不会启动数据库；准备后的业务错误不会被数据恢复控制器吞掉。
- 五语言在 480／1000 宽度实绘无布局异常；按钮回调、防重复重试和错误脱敏通过。简中实绘已人工检查。
- 既有更新数据保护、Hive 启动修复、窗口状态和国际化回归均通过。

本地审计目录：工作区 `.devin/runs/startup-data-recovery-1023/`，含 `regression-final.log`、`analyze.log`、`recovery-zh.png`。截图是隔离 widget 实绘，不代表已安装程序。未读取或修改真实账号、草稿、索引或运行实例，未打包、安装、推送远程或发布 GitHub。
