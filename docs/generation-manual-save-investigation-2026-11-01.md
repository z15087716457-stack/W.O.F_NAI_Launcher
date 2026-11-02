# 主图区与历史栏手动保存卡顿调查

2026-11-01，已按用户授权完成源码，尚未安装；当前实现及验证见[合并完成记录](generation-history-polish-2026-11-01.md)。下文保留开工前调查，不再作为待办。调查时相关 11 个生产文件与已安装 **2.2.4+77** 的冻结输入一致。

## 已确认的重复工作

主图区右键 `onSaveImage` 与历史栏右键 `onSaveImages` 均进入 `GenerationOperations.saveImages` → `GeneratedImageActions.saveImage` → `GenerationSaveService.saveImageFromDetail`。

1. **保存后完整刷新图库。** 没有可复用保存路径时，共享服务在 `saveToDirectory` 返回后无条件调用 `localGalleryNotifier.refresh()`，默认 `scan: true`。底层会重新枚举主源和额外源、读取文件信息、排序、清空尺寸缓存、重新过滤并扫描索引；Notifier 再把记录缓存标旧、重读当前时间线。即使去重找到了已有相同文件，仍会执行这条刷新。
2. **重复保存仍重建图片列表。** 已知路径存在时跳过写盘和图库刷新，但依旧调用 `updateImageFilePath`；它没有同路径短路，重新创建图片及 current/history/display 三份列表。图片列表投影和画布几何按这些列表身份订阅，因此会再次计算。

之前的优化仍在：自动保存优先调用 `addNewlySavedImages`，文件监控走 `applyFileChanges` 按路径更新；10-23 已移除无事件获焦刷新。手动保存却继续使用完整刷新调用，Git 追溯该调用来自 09-21。前述额外工作可解释大图库／长图片历史下的卡顿风险，尚未采集用户窗口帧耗时，不把全部停顿归给单一阶段。

## 建议的最小修改

共享手动保存复用现有按文件路径更新入口，移除保存后的整库刷新；`updateImageFilePath` 在路径未变时直接返回。主图区、历史、详情保存及其他共用保存的入口一并受益，无需增加定时器、更新队列或新缓存系统。保存原字节、元数据、去重及原有提示保持。待用户确认开工。

## 验证

真实共享保存服务与图库 Notifier 配合内存图库计数器、临时 Hive／文件运行；首次保存完整刷新 1 次，第二张累计 2 次，缺失路径但字节相同的去重保存累计 3 次；已知路径重复保存没有新增图库刷新，但 history 列表被替换。针对性增量登记调用均为 0。新探针 1 项与既有保存回归 4 项共 **5 项通过**。

证据：`.dart_tool/generation-save-investigation-20261101/` 下的 `save_probe_test.dart`、`save-cases.json`、`save-probes-final.log`、`verification.json`。初版探针没有等保存服务主动发出的未等待刷新结束，退出夹具时记录一次已销毁容器；最终夹具观察并等待刷新 Future 后该日志消失，初版日志保留。元数据持久缓存未初始化的测试警告不读写正式缓存；没有正式图库、账号、模型或 NovelAI 请求。
