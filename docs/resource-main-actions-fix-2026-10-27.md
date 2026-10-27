# 资源小窗动作注册修复 · 2026-10-27

用户在 +53 反馈：小窗能列出图片、显示「主窗口已连接」，但底部操作及双击大图提示「主窗口还没准备好 / not_ready」。

## 原因与修改

通信通道的 ready 握手与主界面动作注册是两条路径。`GlobalShortcuts` 在配置由 loading 变成 data、启停快捷键或改变绑定时会替换带 key 的外层 widget。Flutter 先挂载新的 `ResourceWindowBridge`，再销毁旧实例。旧实例原来无条件清空共享 `ResourceMainActions.perform`，因而把新实例刚注册的动作移除；后续 `ResourceLibraryBackend.action/open` 持续返回 not_ready。

本次只修改 bridge 的 dispose：回调仍属于自身时才撤销注册。保留现有动作、路由、前台激活与草稿保护链路。

## 可复现证据

新增回归使用生产 `GlobalShortcuts` 和 bridge：先以 loading 启动，再发布真实默认配置，随后启用／停用／重新启用快捷键。旧实现发布默认配置后回调即为空；原始动作调用也返回 `PlatformException(not_ready)`。

修复后每个状态均验证实际图库复制原 PNG 字节、安装大图 session、Vibe 添加受保护动作；最终卸载整个组件仍正确清空自身回调。此前仅以静态 `MaterialApp.router` 测试的路径未覆盖这个应用外层生命周期，不能据它排除动作注册问题。

原始失败、专项回归和 analyze 日志位于 `.dart_tool/resource-actions-fix-20261027/`；本机 +54 构建与安装材料位于 `.dart_tool/cumulative-2.1.2-r9-20261027/`。运行中沙盒验收与交付结果在该批次记录，不将组件测试表述为用户实例验收。
