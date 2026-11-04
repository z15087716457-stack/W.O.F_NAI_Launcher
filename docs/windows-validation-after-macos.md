# macOS 适配及桌面功能的 Windows 验证

以下检查需要 Windows 真机或 runner。Windows 的截图基准应在对应平台核对。

## 省电与统计

空闲微动从开关变为三档，并改了 `set_cvMotionSub`、`channel_motionSub` 与三个选项标签。还需核对：

- 设置画布页 `test/presentation/ui/settings/goldens/settings-canvas.png`，尤其滚动后微动行及窄窗长文案；默认截图是否包含该行以实际绘制结果为准。
- 显示弹层 `test/presentation/ui/channel/goldens/v2/popover.png`、`popover-dark.png`、`popover-fixed.png`。
- 旧 `channel/goldens/*.png` 对整个显示弹层已有排除区域，不能为此改写被锁定的旧基准；v2 是新弹层的完整基准。

先运行相关 golden 测试查看差异，再由维护者确认更新。统计页可用普通 `--update-goldens`；channel 只针对允许重录的 v2 弹层场景，不扩大旧图排除区域。

## 原生行为

验证托盘右键、退出开始后的再次显示、最小化、从任务栏还原、隐藏时暂停绘制和回到前台恢复。Windows 没有完全遮挡检测，这不是预期支持的场景。

## 既有问题

部分既有 Agent 测试默认使用固定的 Windows Node 安装路径。运行时可通过 `NAI_AGENT_NODE` 指向已安装的 Node。另需分别排查在线图库测试中的数据库工厂初始化。
