# macOS 适配及桌面功能的 Windows 验证

以下检查需要 Windows 真机或 runner。Windows 的截图基准应在对应平台核对。

## 省电与统计

`stats_anlasNote` 由余额差记账说明改为按请求报价，实际由 `statistics_cards.dart` 的 Anlas 卡绘制。`statistics_golden_test.dart` 的以下 9 张场景使用完整数据：main、main-dark、r30、narrow、narrow-dark、narrow-en、narrow-ja、narrow-ko、min-window。loading、empty-dark、error 不作为确定受影响的完整统计卡场景。

空闲微动从开关变为三档，并改了 `set_cvMotionSub`、`channel_motionSub` 与三个选项标签。还需核对：

- 设置画布页 `test/presentation/ui/settings/goldens/settings-canvas.png`，尤其滚动后微动行及窄窗长文案；默认截图是否包含该行以实际绘制结果为准。
- 显示弹层 `test/presentation/ui/channel/goldens/v2/popover.png`、`popover-dark.png`、`popover-fixed.png`。
- 旧 `channel/goldens/*.png` 对整个显示弹层已有排除区域，不能为此改写被锁定的旧基准；v2 是新弹层的完整基准。

先运行相关 golden 测试查看差异，再由维护者确认更新。统计页可用普通 `--update-goldens`；channel 只针对允许重录的 v2 弹层场景，不扩大旧图排除区域。

## 生成错误

新增文案的调用链是 `generation_error_view.dart` → 画布接线 / 探索映射 / Agent 提示词组卡。现有生成页 failed golden 使用 `GenFixture.failed()` 的固定标题和说明，探索 failed golden 使用 `ExploreFixture` 的固定错误文本，未走新错误映射；它们不能证明新的服务端详情与处理指引已被截图覆盖，也没有据此判定需要自动重录的额外旧 PNG。

请人工检查：429 停止卡、400 参数错误、随机/顺序块跳过次数且无重试、窄窗长英文、深浅色、探索的“重试失败的候选”、组卡提示通过 Agent 修改词。组件回归和本地假接口验证不等于运行中用户窗口截图。

## 原生行为

验证托盘右键、退出开始后的再次显示、最小化、从任务栏还原、隐藏时暂停绘制和回到前台恢复。Windows 没有完全遮挡检测，这不是预期支持的场景。

## 既有问题

部分既有 Agent 测试默认使用固定的 Windows Node 安装路径。运行时可通过 `NAI_AGENT_NODE` 指向已安装的 Node。另需分别排查在线图库测试中的数据库工厂初始化。
