# 资源小窗动作注册修复 · 2026-10-27

用户在 +53 反馈：小窗能列出图片、显示「主窗口已连接」，但底部操作及双击大图提示「主窗口还没准备好 / not_ready」。

## 原因与修改

通信通道的 ready 握手与主界面动作注册是两条路径。`GlobalShortcuts` 在配置由 loading 变成 data、启停快捷键或改变绑定时会替换带 key 的外层 widget。Flutter 先挂载新的 `ResourceWindowBridge`，再销毁旧实例。旧实例原来无条件清空共享 `ResourceMainActions.perform`，因而把新实例刚注册的动作移除；后续 `ResourceLibraryBackend.action/open` 持续返回 not_ready。

本次只修改 bridge 的 dispose：回调仍属于自身时才撤销注册。保留现有动作、路由、前台激活与草稿保护链路。

## 可复现证据

新增回归使用生产 `GlobalShortcuts` 和 bridge：先以 loading 启动，再发布真实默认配置，随后启用／停用／重新启用快捷键。旧实现发布默认配置后回调即为空；原始动作调用也返回 `PlatformException(not_ready)`。

修复后每个状态均验证实际图库复制原 PNG 字节、安装大图 session、Vibe 添加受保护动作；最终卸载整个组件仍正确清空自身回调。此前仅以静态 `MaterialApp.router` 测试的路径未覆盖这个应用外层生命周期，不能据它排除动作注册问题。

## 小窗内部的大图

资源小窗双击图库卡片直接复用 `ImageViewerPage` 与 `ImageViewerBackend`，在原窗口内部覆盖列表区。保留顶部原生窗口控制；返回或 Esc 移除查看器，保留列表滚动、筛选、选中项，并恢复列表键盘焦点。隐藏列表不响应看图时的 Enter 或方向键。

看图以 `gallery.viewer` 通道读取主程序已索引的记录和当前图片元数据，不依赖视觉动作注册，不创建主窗口大图 session，也不跳转主窗口路由。原图由小窗直接读取，限制解码尺寸；胶片条与列表使用相同 `ResourceWindowImage` 键，主程序继续通过同一个 `ThumbnailCacheService` 提供磁盘缩略图。独立 Flutter 引擎的解码内存仍各自持有。

收藏、收藏集、删除／撤销复用主程序的 `ImageViewerGallery`；删除确认使用当前共享设置。翻译走现有翻译服务，仅翻译当前张，旧请求不覆盖新张。显式复用参数／图生图等操作仍由主程序的受保护动作处理；复制图片沿用共享脱敏策略，并不前台激活主窗口。分页删除导致末页收缩时，会补入当前范围的剩余记录。

原始失败、组件与适配器回归日志位于 `.dart_tool/resource-actions-fix-20261027/`。r9 的早期 +54 候选仅含注册修复，用户补充窗内大图要求后已设为禁止安装；最终 +54 材料位于 `.dart_tool/cumulative-2.1.2-r10-20261027/`。本轮由用户自行实机验收，不将组件测试表述为用户实例验收。
