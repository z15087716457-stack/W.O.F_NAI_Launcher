# F09 · 画风探索接入共享 NAI Agent

2026-10-15。按用户要求逐项修复、本地积攒，尚未构建 Release 或安装；桌面继续使用 r7 `2.0.0-preview+11`，F07／F08 保留。

主生图与探索原本共用 `GenerationWiring`、`GenPromptModule` 和同一份固定偏好。入口缺失来自接线：`agentAvailable` 明确排除了 `widget.explore`，使 `GenSlots.agentToggle` 为空，菜单与头部均不显示 Agent；探索外层也未接入面板宿主。不是两套提示词组件版本不同。

本次移除探索排除条件，在探索页面外复用 `NaiAgentGenerationHost`。头部及工具菜单使用现有 Agent 按钮和固定设置，继续共享工作区、聊天、窗口控制、展开动画、拖动及贯穿分隔线。没有新增独立 Agent 或重置用户固定偏好。

联调同时修正了展开时的空间归属：

- 探索按原有编辑列最小 352px＋舞台最小 480px 预留页面宽度，再限制 Agent 宽度；1280px 可用宽度下 Agent 为 440px，避免默认 520px 挤压舞台。主生图原有 400px 页面预算保持。
- Agent 停靠时由其承接最右侧窗口按钮，页面不再重复预留同一块区域；探索使用常规窗口按钮高度和主题，关闭后恢复原 61px 舞台头部配置。宿主子树位置保持稳定。

验证使用 Flutter 3.47.7 / Dart 3.13.5、真实字体和隔离存储，不连接模型或生成接口：

- 修复前入口回归稳定复现缺失；修复后 11 项专项通过，包含真实编辑列与窗口外壳、探索／主生图互相固定同步、面板开关、拖动后编辑器保留、跨页复用及草稿／参数／探索记录不变。
- 中、繁、英、日、韩的深浅色、1280／1800px 窗口检查通过；22 张菜单／展开实绘保存于 `.dart_tool/explore-agent-entry-20261015/captures/`，为合成测试数据，不是用户运行窗口。
- 494 项探索接线／原 UI 基准、主生图 UI 与接线、Agent 面板、宽度预算、生图核心和桥接回归全部通过。主生图路由测试宿主补上“减少动态效果”，避免持续背景动画使 `pumpAndSettle` 超时，业务断言保留。
- 全仓分析无诊断。142 份锁定 UI、242 张原基准 PNG、3 张图标参考 PNG、已有 DEVELOPMENT 修改、已安装 r7 AOT／收据均未改变。

详细证据：`.dart_tool/explore-agent-entry-20261015/` 的 `baseline.json`、`reproduce-before.log`、`entry-final.log`、`regression.log`、`analyze.log`、`boundaries.json`。原始反馈截图保存在工作区 `04_工具/开发计划/反馈截图/2026-10-15-r7/09-explore-agent-tool-missing.png`。

没有操作 Studio、覆盖用户草稿／配置、调用生图、构建／安装运行包、重打便携包或推送 GitHub。新功能随下一批用户明确要求的桌面更新交付。
