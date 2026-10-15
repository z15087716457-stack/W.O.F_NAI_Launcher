# 2.0 Preview r8 · 七项反馈累计本机更新

2026-10-15（Asia/Taipei）。用户要求推送本波更新；按已确认的本地交付约定，安装到原桌面入口。覆盖前现场确认 Studio／内置 Agent 已退出，保留单步回退；没有自动启动 Studio、制作便携包或推送 GitHub。

## 已安装

- 内部版本 `2.0.0-preview+12`，编译提交 `2d2e652b399a078e259428301b7039a3cb67ebf4`；后续文档提交不代表重新编译。
- F07：空态 Logo／提示对齐背景中央预留区域，首批图片平顺接续当前视图。
- F08：“本次通道”提示每轮应用启动仅出现一次，切页／模式不重弹。
- F09：探索共用主生图的 NAI Agent 工具入口、固定偏好、会话及右侧宿主。
- F10：普通顺序／随机块列入变量列表，每个参与遗传的块标“遗传目标”；DNA 开关移至抽取方式旁，顺序／随机可用、固定置灰。
- F11：清空提示两秒后自动消退，期间仍可撤销。
- F12：顶部空白拖窗区下延 8px，工具条两侧空白恢复可拖，保留按钮和窄工具条滚动。
- F13：恢复主提示框随宽度与字号变化的最低高度及五语言内部轮换 TIP，保留文档与光标。
- 运行目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`，原桌面快捷方式及 `com.example/nai_launcher` 数据／单实例身份保持。
- AOT SHA-256：`ca71b104a77af76e262d2ccbe57fa5cbf5a107f8b810fa8515335b585e63265d`；安装时间 `2026-10-15T19:42:28.836781+08:00`。

## 验证与回退

- 本轮 Windows Release 构建 83.9 秒，1872 生产输入与构建前快照一致；相对最后功能提交仅改变版本及 CHANGELOG。已有 DEVELOPMENT 修改保留。
- 沿用各功能完成时的回归：遗传交互 611 项、顶部拖窗 453 项、最新主提示框及共用生图／画布／探索／核心桥接 604 项；计数重叠，不作累加，不声称本轮重跑全仓。源码分析无诊断，原 PNG 不重录；各项报告见下方。
- 本轮安装器 9 项隔离检查通过，覆盖回退、部分替换失败恢复、占用、基线漂移、新文件冲突、损坏备份和安装 hold。
- 候选逐文件核对 15355 个登记程序文件、224 项 Flutter 资源及全部字体／SQLite；实际更新 3 项。保留 Glass 原生依赖及 15095 项 Agent 文件。
- 原生数据身份与 EXE 依赖核验、隔离的内置 Node／Pi／CodeMode／会话恢复及打包后 RAG 宿主／worker 启停检查通过。没有真实生成、远程模型请求或用户整库建向量。
- 安装前备份 r7 被替换程序、完整登记程序 data 和旧收据；安装后逐文件核对程序、收据及回退材料。回退目录 `E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/cumulative-r8-20261015/rollback`；`update.py verify-backup` 只读核验，明确恢复使用 `update.py rollback`，须完全退出 Studio；本次未实际回退。
- 原桌面快捷方式字节不变；没有写用户草稿、账号、图库、RAG 设置或模型环境。r6 历史便携包保持原样。

放大字体的极窄角色／参考标题及 160px 通道提示溢出仍属既有局部前端问题；具体范围见 F13／通道报告。运行中的窗口手感由用户后续使用确认，组件实绘和安装完整性不代替实机体验验收。

功能证据：[F07](canvas-welcome-alignment-2026-10-15.md)、[F08](channel-entry-notice-2026-10-15.md)、[F09](explore-agent-entry-2026-10-15.md)、[F10](explore-genetic-controls-2026-10-15.md)、[F11](prompt-clear-notice-2026-10-15.md)、[F12](generation-window-drag-2026-10-15.md)、[F13](prompt-height-tip-2026-10-15.md)。本轮材料 `.dart_tool/cumulative-r8-20261015/`；构建产物、本地日志与私有材料不提交。
