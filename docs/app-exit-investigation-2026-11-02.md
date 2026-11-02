# 桌面退出耗时调查

日期：2026-11-02。本报告记录改动前调查及隔离验证；用户确认后已完成[退出流程优化源码](app-exit-polish-2026-11-02.md)，尚未安装。桌面仍为 2.2.4+77。

## 已确认

1. **后台收尾串行执行。** `DesktopAppShutdownService.prepareBackgroundShutdown()` 逐个调用并等待回调。许多回调在开头才取消任务，因此前一项等待期间，后一项仍可能继续工作。资源小窗的 `closeAll` 最先注册；它等待创建结束及临时导出清理，随后才轮到其他已注册任务。
2. **前台隐藏晚于收尾，托盘又早于窗口退出消失。** 完整退出不先隐藏主窗口；清理数据库和 Hive 后先销毁托盘，再调用 `windowManager.destroy()`。当前 window_manager 0.3.9 的 Windows 实现只是 `PostQuitMessage(0)`，并不立即销毁 HWND。runner 离开消息循环后才销毁 Flutter 控制器，`Win32Window::Destroy()` 又先 `OnDestroy()`、后 `DestroyWindow()`。引擎销毁期间主窗口可能仍可见，符合“托盘没了、前台还在”的反馈。
3. **存在真实的长等待预算。** RAG 正常关闭默认允许 60 秒完成最终检查点；本地超分取消后最多等 20 秒再结束其自有宿主。这些是上限，不表示每次退出都耗时这么久。RAG pool 已会跳过未变化的检查点，不能把它描述成每次退出都重写全索引。
4. **Agent 没有接入统一退出等待。** 工作区控制器已有 `close()`，负责逐个持久化会话及关闭 Pi；provider dispose 使用 `unawaited(close())`。托盘退出没有显式等待它；不能将 Agent 的 5 秒请求／5 秒进程预算算作当前统一退出链的已测耗时，但此处应复用现有注册机制补齐，而非再建退出系统。
5. **窗口右上角关闭也有延迟来源。** `AppWindowListener.onWindowClose()` 先等待资源小窗关闭，再隐藏主窗口。它是“隐藏到托盘”，与真正退出应继续区分，但主窗口隐藏无需等临时导出清理。

另外，统一退出在 `windowManager.destroy()` 后才记完成日志、flush 并 `exit(code)`。原生消息循环已被要求结束，此时继续依赖 Dart 回调完成不合理；最终退出应收束为一个入口。窗口生命周期保存也应在存储关闭前完成，不依赖关窗后的回调补写。

## 建议的最小改法

- 复用 `DesktopAppShutdownService`，明确退出时先隐藏窗口，防止清理期间仍能继续操作；普通关窗隐藏同样前移。
- 独立任务同时开始取消和收尾，全部完成后再关数据库、Hive；保留真实的数据依赖顺序，不把数据库关闭一起并行。
- Agent 复用已有 `close()` 和 cleanup 注册，不另建生命周期管理器。
- 收好数据及日志后只走一次最终退出，移除 `windowManager.destroy() → 再等待 Dart → exit()` 的重复链路。
- 保留 RAG 正常检查点与已有任务自己的超时。现有测试证明合法保存可超过 3 秒，不为表面提速统一缩短成 2–3 秒强杀。实现时用现有日志记录各收尾耗时，定位剩余慢项即可。

## 隔离验证

材料：源码根 `.dart_tool/exit-investigation-20261102/`。

- `exit_probe_test.dart` **2 项通过**：实际调用当前生产服务，受控 Future 证明后一项取消被前一项阻塞；mock Windows method channel 证明托盘销毁时未调用隐藏，最终退出仍在等待 native destroy。数据库未初始化、Hive 未打开，测试未访问用户存储；阻塞 mock 保证真实 `exit()` 不会执行。
- 现有 RAG／资源小窗 **4 项通过**：真实微型 Python IPC 宿主允许 3.2 秒检查点保存完成并排空输出；卡死关闭受已有期限约束；资源小窗等在途创建而不等待 ready，以及独立控制／closeAll 行为保持。仅夹具，不载入真实模型、不打开用户索引、不联网。
- 先单跑的卡死关闭用例与上述四项重复，不额外累计；本轮合计 **6 项不同检查**。
- 日志：`exit-probe.log`、`cleanup-regressions.log`。native 时序来自当前插件和 runner 源码，未进行真实 Studio 退出计时；没有证据把用户每一次长退出都归因于某一个后台组件。

## 源码入口

- `lib/core/services/desktop_app_shutdown_service.dart`
- `lib/main.dart`：托盘、普通关窗、窗口状态保存、资源窗 cleanup 注册。
- `lib/presentation/providers/rag_provider.dart`、`lib/core/rag/rag_client.dart`、`tool/rag/worker.py`、`tool/rag/pool.py`
- `lib/presentation/providers/nai_agent/nai_agent_workspace_provider.dart`、`nai_agent_workspace_controller.dart`、`lib/core/nai_agent/pi_host_client.dart`
- `lib/core/services/resource_window_service.dart`、`lib/presentation/wiring/resource_window_backend.dart`
- `windows/runner/main.cpp`、`flutter_window.cpp`、`win32_window.cpp`
- Pub cache `window_manager-0.3.9/windows/window_manager.cpp` 的 `WindowManager::Destroy()`。
