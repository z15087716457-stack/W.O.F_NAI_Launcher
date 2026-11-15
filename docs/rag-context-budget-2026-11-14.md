# 推荐上下文取样长度

2026-11-14，按用户确认的本地组件预览实现。仅修改源码，未构建／安装／启动桌面程序，未提交Git；本机安装仍为2.3.4+103。

## 行为与接线

- 设置页「推荐上下文」取消方向分段，固定取光标前。「取样长度」复用SettingsSlider，范围32–512个Gemma token，整数步长1，默认120；保留现有已修改标记、单项／整页恢复默认、撤销与设置搜索。五种语言同步更新；旧设置页入口也改为长度滑条。
- 共用滑条由按下提交改为点击松手提交，拖动中只更新读数，松手保存一次，避免开始拖动先触发推荐。缩略图缓存／显存卸载等既有滑条回归通过。
- RagSettings沿用version=1的现有存储键，新增tokenBudget；旧mode字段忽略，缺少预算时取120，模型路径、来源和设备等既有字段保留。存储边界只接收整数预算，越界夹到32–512，类型不符回到120。
- 推荐JSON请求固定mode=before，附带当前budget。Worker与Engine将预算传到实际Gemma计数的context_window；Python保留旧around参数兼容能力，当前应用不再发送该方向。
- 继续按完整标签、UTF-16光标位置截取，不拆开或跳过相邻超长标签，不把块别名／实例标记发给模型。手动输入查询不受预算影响，完整提示词仍只用于已有标签／别名去重。
- 预算不进入模型连接身份。调整后取消旧推荐并重新查询，迟到结果丢弃；不重连模型、不修改向量格式或索引身份、不触发重建。

## 验证

登记Flutter 3.47.7 / Dart 3.13.5；所有请求均使用隔离数据与替身，无真实模型或NAI调用。

- Flutter主回归145项通过：test/core/rag，以及推荐IPC、模型下载、标签扩展、设置后端、新控件交互／五语言深浅色宽窄布局、设置页／搜索和UI依赖边界。日志：`.dart_tool/rag-context-20261114/rag-regression.log`。
- Flutter补充62项通过：既有滑条边界、缩略图缓存、旧RAG设置页五语言布局、设置激活／撤销、繁体资源生成验证及实际页面实绘。日志：`.dart_tool/rag-context-20261114/ui-regression.log`。
- Python `python -m unittest discover -s tool/rag -p 'test_*.py'`：152项，首次149项通过、3项Windows宿主因未指定RAG_TEST_PYTHON跳过；显式指定开发venv后单独补跑test_host.py的3项，全部通过。新增检查覆盖32／120／121／512预算、连续完整标签、非法预算、Worker传递、手动查询独立和索引不变。
- 全仓 `flutter analyze --no-pub`：0问题。日志：`.dart_tool/rag-context-20261114/analyze.log`。`git diff --check`通过。
- 已查看真实字体页面实绘：`.dart_tool/rag-context-20261114/actual-zh-dark.png`与`actual-en-light.png`，使用生产设置页和本地组件；无新增PNG基准或基准排除区域。

旧配置迁移仅在测试夹具验证；本次没有改写用户实际设置、草稿、词库或索引，也没有更改版本号或安装收据。
