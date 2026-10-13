# 本地放大零 Anlas 价签 · 2026-10-05

功能提交 `26919dbbdf60c4877148ff4e17fd3fb37ef3e123`，于 2026-10-05 23:13（Asia/Taipei）安装，实际 Windows 体验待用户反馈。

用户确认紧凑箭头完美，随后反馈 ∞ 不协调，希望统一成普通数字与 Anlas 图标。本批本地显示 0 + Anlas SVG，字号 12px，和云端使用同一内框；NovelAI 保留按当前选中图片尺寸计算的实际费用，不支持的源图仍为 —。已确认的 18px 箭头槽、单层设置浮层及自动本地增强行为保持。

25 项既有相关测试通过，零失败 / 跳过；3 文件 analyze 无问题。60 张生产字体 / SVG 实绘覆盖五语言、明暗主题、320 / 920px 的本地 / 云端设置及增强面板。实绘是合成数据控件，不是运行中 Studio 截图；更新既有价签断言：本地 0 / 云端费用双向切换、数字位于 Anlas 图标前，模型缺失时仍显示零费用但执行禁用。没有新增测试用例，既有截图单独输出，前批实绘保留。

Release / Glass AOT 一致 `8bb0d92c0e937799172e6316ea61033e0d13441d7f1b3235b7bb01e81f2f0ee9`；数据身份仍为 `com.example/nai_launcher`。1237 个源码输入、206 项资源、31 原生文件、241 托管文件及 ICU / 桥接客户端复验通过。

完整包 `E:/A.I/NovelAI/.devin/wt/nai-launcher-src/build/nai-studio-upscale-price-20261005.zip`，207347131 字节，SHA-256 `d9e54df897a0379f2d4e12b156d42999e85197359e1820493067712fba23c20e`。完整退出 Studio 且现场进程为零后安装，前版 `316d5798` 完整保存在 `glass-before-upscale-price/`，备份逐项匹配，回退只读预检通过。冻结交付与 ZIP 及前五批 ZIP 校验保持原值；满意检查点未改写。

当前 `upscale-price-delivery.json` 与 `glass-rollout-delivery.json` 一致：installed=true、ready_to_install=false、installation_hold=false。没有自动启动、重载或修改账号 / 草稿 / 图库，没有真实 NAI 请求或 Anlas 消耗，没有模型及大环境下载。有效源码仍为 `.devin/wt/nai-launcher-src` 的 `devin/gallery-redesign`；既有文档、注释和生成行尾状态保留。

本机核验日志和实绘：`.dart_tool/upscale-price-20261005/`。
