# 词库页标签翻译配置状态修复

> 当前交付：已随 [r24 本机更新](cumulative-preview-r24-2026-10-17.md) 安装到原桌面入口，内部 `2.0.0-preview+28`。以下保留开发验证时的状态与边界。

用户截图中「模型与接口」的标签翻译分配已有模型且显示可用，「词库与缓存」同名行仍为未配置。根因为 `settingsViewData` 构造 `SettingsDictionaryData` 时遗漏 `translationModel`，其默认 null 被显示为未配置；此前只有生图设置的提示词翻译模型字段有赋值。

现补入 `LauncherInterface.tagTranslate` 对应模型，独立于提示词翻译的 `LauncherInterface.translate`。沿用已 watch 的配置状态，模型分配变化会重建投影，未分配仍显示未配置；不改设置存储、实际标签翻译路由、提示词翻译、Wiki 正文、请求重试、缓存、语义资料或索引。

证据 `.dart_tool/settings-tag-route-status-20261017/`：9 项现有词库／缓存界面、模型分配与推理设置检查通过，跳过 0；范围分析无诊断，格式检查无变化。字段接线经源码直接核对，没有新增投影测试或调用真实模型。生产变动仅 `lib/presentation/wiring/settings/settings_data.dart`，保留用户未提交的 DEVELOPMENT.md；r23 收据及安装程序未改，没有读取或重写用户模型配置、触碰正式索引、自动启动／热重载。

**源码修复完成，尚未安装到桌面**；当前本机仍 r23 / `2.0.0-preview+27`。现有分配无需重新填写，待下次本机更新纳入。
