# 本地放大管理与高级组件 · 2026-10-05

功能提交 `d782e052ec88094907c39b266e203885e8bc1670`，有效源码为 `E:/A.I/NovelAI/.devin/wt/nai-launcher-src/`。上一批 `36f4d4f0` 已于 19:06 安装，用户随后确认“非常不错”。用户完整托盘退出后已于 2026-10-05 20:34（Asia/Taipei） 安装；当前安装文件和前版回退备份复验通过。

## 当前源码状态

2026-10-06 后续批次（`91cb9aed`，12:43 Asia/Taipei 已安装）：SeedVR2 支持 3B FP8 / 7B FP8 自选，两个权重按需下载、共用运行环境与 VAE，并保留原 venv 绝对路径。7B 固定为同一 Hugging Face revision `09ced710…` 的 `seedvr2_ema_7b_fp8_e4m3fn.safetensors`，8239729704 字节，SHA-256 `1fdbf3877b7d1eb266038d3a165a977f17dbb4daa4a0f0d334d5461476963037`；只读取发布元数据核对，没有下载权重。兼容上批 `7d72744f…` 的已安装 3B / RTX 收据，仍逐文件匹配当前要求；取消追加安装和删除一个型号不得破坏另一个。管理页列单个型号的权重大小，不重复计算共享组件。

放大面板保留简洁布局，新增默认收起的高级设置：LAB 色彩校正、种子 0、BlockSwap 0、VAE 编码 / 解码分块 1024 与重叠 128、输入 / 潜空间噪声 0 为默认；实验噪声单独折叠并说明不是画质强度。按型号独立记忆，恢复默认只重置当前型号，手动放大与自动增强共用配置，批次使用冻结参数；同帧编辑按最新值合并，旧型号控件不回写新型号。CUDA 显存不足明确提示可降低倍率 / 使用 3B / 调整显存策略，不静默换模型。没有开放依赖版本、分配器、编译或额外注意力组件，也没有更新锁定运行依赖。

用户已反馈现有 3B 可运行，截图显示已安装与超分完成；这是用户实机反馈，不冒充开发方独立推理审计。当前已安装 Studio 为 `91cb9aed`：仅本批 33 个业务 / 测试文件经授权本地提交，未推送，安装前冻结输入复验为 4490 通过 / 5 原有跳过 / 0 失败、analyze 无诊断，Release / Glass AOT 一致。1239 编译输入、542 测试输入、206 资源、31 原生与 241 托管文件核验通过，前版 `18d485a4` 独立备份和恢复只读预检通过；没有自动启动，已有模型 / 环境与用户数据保持。证据为有效源码 `.dart_tool/seedvr2-options-20261006/installed-verification.json`，当前收据为原运行目录登记的 `seedvr2-options-delivery.json`。7B 的完整下载、GPU 推理和新界面 Windows 验收仍未执行；按用户要求今天交付收尾。完整状态见工作区当前接手说明。以下两段是上批运行环境修复与安装的验证边界。

本轮经用户授权只复现独立 Python/CUDA 环境，已复现并修复两处启动故障：晚设置 CUDA 分配器导致检查异常 / Windows `0xC0000005`，以及 PEFT 0.17.1 与 Transformers 5.12.1 的 HybridCache 不兼容。现在安装 probe / 推理在启动 Python 前传入同一分配器与离线配置；兼容依赖固定为 Transformers 4.55.4、Tokenizers 0.21.4、Hugging Face Hub 0.36.0，其余锁定依赖保持，清单及哈希同步。旧 RTX receipt 的兼容仍逐文件匹配当前期望值。

真实独立环境的依赖安装、CUDA 张量与完整 SeedVR2 CLI 导入检查通过，在权重阶段主动取消，`.dart_tool/seedvr2-runtime-audit-20261006/result.json` 记录 `runtime_and_gpu_probe_passed=true`、`model_downloaded=false`、`installation_committed=false`。未下载约 3.9 GB 权重、未做完整模型推理。用户随后授权安装 Studio 更新与本地提交，修复已在 `18d485a4` 中于 2026-10-06 10:39（Asia/Taipei）安装，未自动启动；安装时没有额外模型或运行环境下载。最新交付 / 程序 / 回退核验见有效源码 `.dart_tool/feedback-fixes-20261006/installed-verification.json`，安装记录为原运行目录登记的 `.dart_tool/feedback-fixes-delivery.json`。以下为 2026-10-05 原交付历史，旧包与检查点保持封存。

## 已实现

- 设置左侧新增「本地放大」，集中常规模型、SeedVR2 与 RTX 的管理；模型与接口中的重复标签已移除。放大面板的「管理模型」打开同一页面，`/settings?section=local-upscale` 深链固定为新增旧索引 10，原有索引不变。
- ComfyUI 页保留启用、地址、状态、测试和断开连接，移除内置/自定义工作流列表与导入/删除入口；已有工作流及连接设置没有被清空。
- 放大面板提供普通模型 / SeedVR2 / RTX，未安装组件明确显示状态并禁止开始。模型与运行环境只在点击安装后下载；推理强制离线，不自动获取缺失组件。
- SeedVR2 固定独立 CLI 源码、CPython 3.12.11、uv 0.12.17 和带哈希的依赖锁；私有环境安装、CUDA 检查、模型安装、单进程执行与阶段进度入口已接好。它不共享用户的全局 Python 环境。
- RTX 固定 NVIDIA RTX Video SDK 1.1.0 官方组件，安装验证 DLL、许可与显卡能力，执行直接走 SDK。随包提供自己编写的宿主和 SDK 许可，不分发 SDK 开发头文件或整包。
- 下载支持续传、分段响应和最终文件大小/SHA-256 校验，未完成安装不进入可用列表。进程由 Windows Job Object 管理，取消/超时/托盘退出等待所属子进程清理，推理与安装互斥。
- 沿用冻结源图、精确目标尺寸、透明通道、元数据来源与晚到结果保护。按用户新反馈，五语言删除“无需连接 ComfyUI”的界面描述。

## 下载约束与验证边界（2026-10-05 原交付）

用户要求约 3.9 GB 的 SeedVR2 模型暂不下载。开发审查过程中已经停止该模型下载与批量运行环境安装，没有恢复或自动续传；约 135 MB 的未完成文件留在忽略的开发审查目录，不是已安装模型，也不会在打开设置时自动下载。SeedVR2 的真实 CUDA 推理尚未验证，须等用户主动安装完整模型和运行环境后再验证。

RTX 的开发 SDK 已在该指示前取得，本批后续验证复用同一份本地缓存，没有再次访问模型下载服务。RTX 4080 上实际 SDK 推理完成 256×192 → 512×384，输出与 Lanczos 插值不同；完整应用服务另验证 1.75 倍得到 448×336 与透明通道保护。质量评价没有用测试接线代替实际画面对比。

## 验证证据

- `final-tests.log`：107 项通过；`install-shutdown-tests.log`：1 项通过，共 108 项，均无失败、跳过。本机普通模型及 RTX 实际执行使用已缓存资源。
- `analyze.log`：本次影响范围无问题；五语言繁体同步和资源生成通过。
- `captures/`：40 张五语言、明暗、320/560px 真实字体面板与管理实绘；完整设置各页面另验证桌面、紧凑窗口和放大文字。
- `seed-contract-verification.json`：直接验证固定版本的 CLI 参数解析、单进程接线、禁止推理下载、阶段回调及无 CUDA 错误；明确 `real_seed_gpu_inference=false`。
- `owned-process-verification.json`：实际 Windows 子进程正常退出、带空格/Unicode 参数及取消后全部后代退出，取消返回 130。
- `rtx-real-verification.json` 与组件测试：真实 GPU 输出和完整 Dart 服务尺寸/透明度检查。
- Release / Glass AOT 一致 `7ab3f2a38492a9cc351f6400a919b1291e340657950503f470434c0b5b3c5948`，1231 个生产源码输入、204 项资源、31 个原生文件和 239 个托管文件固定哈希。可选组件清单和 adapter/lock/worker 的组包哈希复验通过；包内没有 SeedVR2 权重或 Python 环境。
- 没有 NovelAI API 请求，Anlas 消耗为 0；没有修改账号、用户草稿或图库。

## 交付

完整更新包：`E:/A.I/NovelAI/.devin/wt/nai-launcher-src/build/nai-studio-advanced-upscale-20261005.zip`，207163695 字节，SHA-256 `183dd2aa49ec38033c39d4c3b64c826bf33667de6a2fa8453848988e01d22869`。

新交付记录为安装目录登记的 `.dart_tool/advanced-upscale-delivery.json`；安装/回退脚本为 `install_advanced_upscale.ps1` / `restore_advanced_upscale.ps1`，预检通过。回退目录 `glass-before-advanced-upscale/` 已完整保留前版 `36f4d4f0`；回退脚本只读预检通过。源码侧冻结交付单和 ZIP 不在安装后改写。

已更新登记的运行包；没有自动启动、重启或热重载应用，新界面实际体验待用户反馈。原完整检查点 `nai-launcher-checkpoints/2026-10-05-studio-verified/` 保持封存。

## 官方来源

- [SeedVR2 固定源码](https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler/tree/4490bd1f482e026674543386bb2a4d176da245b9)
- [NVIDIA RTX Video SDK](https://developer.nvidia.com/rtx-video-sdk)
- [uv 固定版本](https://github.com/astral-sh/uv/releases/tag/0.12.17)

安装后 204 项资源、31 个原生文件、239 个托管文件、AOT/ICU/客户端/清单复验通过；两份当前安装记录完全一致。冻结交付单与 ZIP 原值保持不变，详细结果为 `post-install-verification.json`。
