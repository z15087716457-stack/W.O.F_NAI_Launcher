# 本地放大组件品牌标识（2026-10-05）

用户要求 RTX 使用 NVIDIA Logo，并询问 SeedVR2 是否有官方标识。本批源码 `4db2c780d026806385845376d51e104bed5bb71c`，已于 2026-10-05 20:55（Asia/Taipei）安装。

## 资源与界面

- RTX 卡片复用既有 `assets/icons/providers/nvidia.svg`，显示 NVIDIA 绿色；原 Lobe Icons 资源与 MIT 许可保留。
- SeedVR2 使用 ByteDance-Seed/SeedVR 官方仓库中的 SeedVR 系列标识。官方资源名称为 `seedvr_logo.png`，不声称存在单独的 SeedVR2 版本 Logo。固定来源为 `e4de8c24441a67e1b7df56abea10645059bb1185` 的 [官方图片](https://github.com/ByteDance-Seed/SeedVR/blob/e4de8c24441a67e1b7df56abea10645059bb1185/assets/seedvr_logo.png)，原文件 1280×342 / 167665 字节，SHA-256 `9a08170e6ce79f87ad524d4ad5c083c8f1766f245d9dfea6b54fde5dca00f4a2`。
- 原 PNG 字节完整保留；Flutter 在 22px 槽中显示胶片与幼苗图案，旁边继续显示 SeedVR2 标签。装饰图案排除重复无障碍朗读。来源与用法登记于 `tool/branding/upscale_logos.json`，上游 Apache-2.0 LICENSE 加入资源和应用许可列表。
- 只调整本地放大模型管理页的两个组件标题图标；没有模型或运行环境下载。约 3.9 GB 的 SeedVR2 模型继续按用户要求暂缓。

## 本轮核验

- 既有布局测试 40 项全部通过，五语言、明暗主题、320/560px 面板和模型管理实绘通过；受影响三份生产源码 analyze 无问题。没有新建重复实现的图标单测，也没有重复 GPU 推理。
- Windows Release 构建成功，Glass assemble 成功且 AOT 一致：`cb2f609a36866b55bab1b3497f10f598c67c72f1c62ddedf3af5ade21c79ef60`。
- 1234 个实际编译输入、206 项资源、31 个原生文件和 241 项托管文件逐项核验。既有资源只有生成的 AssetManifest/NOTICES 允许变化；两个新增资源为 SeedVR PNG 与许可证。原生 Glass、ICU 与桥接客户端字节保持原值。
- 本轮原始日志与 40 张实绘保存于 `.dart_tool/upscale-branding-20261005/`。既有测试脚本先写入前批捕获目录，本轮已完整复制到自己的审计目录；冻结的前批更新包与交付单没有变化。控件实绘不代替用户 Windows 界面反馈。
- 没有生成接口请求、Anlas 消耗、用户图库/草稿/账号写入、自动启动或热重载。

## 安装与回退

完整更新包 `build/nai-studio-upscale-branding-20261005.zip`，207336537 字节，SHA-256 `66a25f3de4e959a7df6026b6b3af83203771ff689409f8ad670e0db2156593cf`。冻结包中 `delivery.json` 保持 `installed=false` / `ready_to_install=true`，安装状态由运行目录交付记录维护。

安装前现场核对 Studio、桥接和关联超分进程为零，安装脚本只读预检通过。沿用用户已有安装授权，未重复询问。安装后 `.dart_tool/upscale-branding-delivery.json` 与 `glass-rollout-delivery.json` 完全一致，`installed=true`、`ready_to_install=false`、`installation_hold=false`；AOT、资源、原生身份、源码输入与托管文件再次逐项通过。

安装/回退脚本位于旧运行目录 `.dart_tool/install_upscale_branding.ps1` / `restore_upscale_branding.ps1`。`glass-before-upscale-branding/` 完整保存前版 `d782e052` 的 AOT、204 项资源、桥接客户端、托管清单和安装记录；备份复验与回退脚本只读预检通过。前批 ZIP SHA-256 仍为 `183dd2aa49ec38033c39d4c3b64c826bf33667de6a2fa8453848988e01d22869`，完整满意检查点继续固定为 `09ea804f`。
