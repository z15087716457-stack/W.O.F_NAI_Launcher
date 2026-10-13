# 放大控件排版与云端价签核验 · 2026-10-05

功能提交 `667fbe47f368cf0f0c888919b5d69011343ae9d5`，于 2026-10-05 22:46（Asia/Taipei）安装；此记录不代表 Windows 用户验收。

## 用户反馈与修复

模型字段原先继承过大的字体，增强的本地选项换行，选中表面较暗容易看成禁用；上一批把画布价签固定为 ∞，切到 NovelAI 时也未恢复费用。

- 提取仅供放大与本地增强使用的控件样式，字段和选项 12px，说明 11px；缩小模型框、数值框、滑轨，统一边框与间距。
- 选中表面较亮，未选项在较深底槽；增强模式同一行，面板固定最大宽度，宽窗左右分区，窄窗顺序堆叠。长英文方法标签可在两行内完整显示。
- 恢复画布放大价签的小内框：本地 ∞，云端所选图片费用 + Anlas SVG，后端切换即时更新；云端不支持的尺寸显示 —，不显示虚假费用。
- 主按钮直接执行 / 箭头打开单层设置，以及自动本地增强仅发布和保存最终成图的行为继续保留；没有改动请求、原图清理或失败回退管线。

## 本批证据

- 69 项针对性测试通过，零失败 / 跳过：五语言明暗宽窄布局、手动放大单击执行、本地 / 云端价签即时切换、配置不触发请求或下载、增强模式同一行、普通方法标签不截断及草稿保护；包括既有本地面板 / 管理、增强面板、画布工具条与云端工作流用例。所有接口均为模拟，没有真实 NAI 请求或 Anlas 消耗。
- 四个生产文件和一个既有测试文件 analyze 无问题；未新增界面文案，无新增本地化字符串。
- 60 张真实字体 / SVG 生产控件实绘：简中、台湾正体、英、日、韩，明暗主题，320 / 920px，覆盖本地浮层、云端浮层、自动增强设置。截图是合成数据下的生产控件，不是运行中 Studio；系统 emoji 字体以 Windows 实机为准。
- Windows Release 与 Glass AOT 一致，存储身份继续为 `com.example/nai_launcher`。1237 输入、206 资源、31 原生文件和 241 托管文件，以及 ICU / 客户端逐项复验通过。
- AOT：`73d2d9395b6ea3f8baf03a5a54eee16dad2231281ee2aca286d6cd069c55a5d0`。
- 更新包：`E:\A.I\NovelAI\.devin\wt\nai-launcher-src\build\nai-studio-upscale-controls-20261005.zip`，207345659 字节，SHA-256 `4b60ece026377890774c338fa69550bdb292708bfd11bc294692df7c3ac1d912`。
- 安装前现场进程为零，前版 `de24aed3` 完整保存在 `glass-before-upscale-controls/`，备份资源与安装记录匹配；`restore_upscale_controls.ps1 -ValidateOnly` 通过。没有自动启动 / 重启 / 热重载，没有账号、草稿或图库数据修改，没有模型 / 大运行环境下载。
- 冻结 ZIP / 交付单及前三批 ZIP 的 SHA-256 保持不变，满意检查点未改写。

## 当前状态

`upscale-controls-delivery.json` 与 `glass-rollout-delivery.json` 完全一致：installed=true、ready_to_install=false、installation_hold=false。有效源码仍为 `.devin/wt/nai-launcher-src` 的 `devin/gallery-redesign`；已有未提交文档、注释及生成文件行尾状态保留。实际 Windows 体验待用户反馈，SeedVR2 大模型及环境继续暂缓下载。

本机日志和实绘位于 `.dart_tool/upscale-controls-20261005/`。
