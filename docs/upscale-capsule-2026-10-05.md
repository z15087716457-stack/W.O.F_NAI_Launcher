# 放大胶囊与自动本地增强核验 · 2026-10-05

功能提交 `de24aed3609b399f89394b422344dbb08b02a0dc`，于 2026-10-05 22:05（Asia/Taipei）安装；此记录不代表 Windows 用户验收。

## 交互和成图

- 放大胶囊主按钮执行记住的方案，右侧箭头向下打开设置。设置为单层浮面，复用模型、倍率与本地 / NovelAI 选择；主按钮不再打开底部弹窗。∞ 替换胶囊数字 / Anlas 图标；云端实际费用在设置内展示。
- 增强在 Max 右侧新增本地，右侧换为本地配置。后续每次正常生成使用当前草稿请求，按冻结的模型 / 倍率处理每张图片。变体和探索保留原行为。
- 成功只发布并保存放大成图，不把原图放入历史，也不附加 originalBytes；原图仅处理期间临时持有，既有服务清理本次输入 / 输出目录。失败或取消保留已生成原图，批量部分完成时保留已放大成图与未完成原图；不重发 NAI 请求。
- 手动本地 / 云端放大直接读取选中画布图片，不接管图生图草稿；保护较新的图片选择及草稿，支持取消 / 托盘清理，缺模型在生成前拒绝。打开设置或切方案不会执行推理 / 下载。

## 本次证据

- 202 项针对性回归通过，零失败 / 跳过：生成 / 429 回退 / 取消、自动本地增强 14 场景、直接云端 4 场景、手动本地源图保护、工具控制 / 费用 / 布局等。所有 NAI 接口均为模拟，没有真实生成或 Anlas 消耗。
- 13 个生产文件与 3 个新测试文件 analyze 清洁；四份手写 ARB 同步，台湾正体经资源测试生成，Flutter 本地化生成通过。
- 40 张生产控件实绘，五语言、明暗主题和 320 / 920px，使用真实字体与 SVG。验证箭头浮层位置、单击执行、切换设置零请求、草稿不变和窄窗布局。实绘为合成数据控件截图，不能当运行中 Studio 截图；截图中的系统 emoji 字体不代表 Windows 实机显示。
- Windows Release 和 Glass AOT 一致，原生数据身份保持 `com.example/nai_launcher`。1236 输入、206 资源、31 原生文件、241 托管文件及 ICU / 独立客户端复验通过。
- AOT：`79f4e1f40197b51ae0c1ed24fbfe2238d32aa6f539b4c87dd8bb40aa28441003`。
- 完整包：`E:\A.I\NovelAI\.devin\wt\nai-launcher-src\build\nai-studio-upscale-capsule-20261005.zip`，207346742 字节，SHA-256 `c5ec4d0dbf864a067e580e32662ccc324cc884c565dcc766532c14256de73ff7`。
- 安装前现场进程为零，完整备份前版 `4db2c780` 到 `glass-before-upscale-capsule/`，206 备份资源逐项复验和 `restore_upscale_capsule.ps1 -ValidateOnly` 通过。未自动启动 / 热重载。冻结交付单、ZIP、前批 ZIP 与完整满意检查点保留。

## 状态

当前安装记录为 `upscale-capsule-delivery.json`，与 `glass-rollout-delivery.json` 一致：installed=true、ready_to_install=false、installation_hold=false。有效源码仍是 `.devin/wt/nai-launcher-src` 的 `devin/gallery-redesign` 分支，既有文档整理 / 注释 / 生成行尾状态保留。模型与大环境未下载；SeedVR2 真实 GPU 推理继续待用户安装，实际界面体验待反馈。

本机详细日志及捕获：`.dart_tool/upscale-capsule-20261005/`。
