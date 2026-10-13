# 标签百科改版 · 2026-10-06

功能提交 `0df9b6bd`（方案 A 三栏重构）与 `015f9c28`（对照阅读 / 示例卡片 / 悬停预览），于 2026-10-06 08:04（Asia/Taipei）安装，实际 Windows 体验待用户反馈。

方案 A：左侧官方目录 / 书签导航、中间标签结果列表、右侧文章阅读区，宽屏正文右侧挂 168px 本文目录；文章头部含分类、标签名、译名、统计与操作，`Aa` 弹层承载阅读设置。新增加入提示词（含已存在提示与安全撤销）、常一起出现网格、所属目录路径、纯链接列表标签云、浏览器式前进 / 后退历史与鼠标侧键、快捷键。对照批：`Aa` 弹层三态阅读模式（原文 / 译文 / 对照），`alignWikiBlocks` 块 / 章节两级对齐，示例章节卡片与正文链接 / chip / 同现格子统一的悬停预览卡。

148 项相关测试通过，零失败 / 跳过；7 个受影响文件 analyze 无问题。47 张生产字体实绘覆盖五语言、明暗主题、1440 / 1100 / 680 宽度及对照、示例卡片与悬停卡片状态。实绘是合成数据控件截图，不是运行中 Studio 截图。

Release / Glass AOT 一致 `6043c9efbb7b0b2bc7b1b59574b30064bd11648635d11469bcd58abfa3d173ac`；数据身份仍为 `com.example/nai_launcher`。1239 个源码输入、206 项资源、31 原生文件、241 托管文件及 ICU / 桥接客户端复验通过；本批没有新增资源。

完整包 `E:/A.I/NovelAI/.devin/wt/nai-launcher-src/build/nai-studio-wiki-redesign-20261006.zip`，207404727 字节，SHA-256 `3fda387ebdf2c80eb56a60841d06094ce462d2feaacb2f49940714c18e92428e`。完整退出 Studio 且现场进程为零后安装，前版 `26919dbb` 完整保存在 `glass-before-wiki-redesign/`，备份逐项匹配，回退只读预检通过。冻结交付与 ZIP 及前六批 ZIP 校验保持原值；满意检查点未改写。

当前 `wiki-redesign-delivery.json` 与 `glass-rollout-delivery.json` 一致：installed=true、ready_to_install=false、installation_hold=false。没有自动启动、重载或修改账号 / 草稿 / 图库，没有真实 NAI 请求或 Anlas 消耗，没有模型及大环境下载。有效源码仍为 `.devin/wt/nai-launcher-src` 的 `devin/gallery-redesign`；既有文档、注释和生成行尾状态保留。2026-10-03 旧 codex 批次同名材料已归档为 `*-20261003`。

本机核验日志在 `.dart_tool/wiki-redesign-20261006/`；实绘在 `.dart_tool/wiki-redesign-captures/`。
