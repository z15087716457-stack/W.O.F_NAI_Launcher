# 官网生成变体与画布追加反馈 · 2026-10-06

有效源码：`E:/A.I/NovelAI/.devin/wt/nai-launcher-src`，分支 `devin/gallery-redesign`。
本批功能本地提交 `b5187d10`、`e940b311`、`26612e95`，未推送。包括此前尚未安装的四项超分 / 画布修复；准备阶段用户选择先不安装；随后用户确认关闭，已于 2026-10-06 16:34（Asia/Taipei）安装为 `26612e95`。

## 官网依据与行为

使用内置浏览器打开已登录的 https://novelai.net/image，保留现场已有的中性测试提示词。先生成一张 V5 Full、512×768、23 步、CFG 7 的基图，再点击生成变体。两次真实请求按按钮报价分别扣除 11 与 27 Anlas，测试获得原图加三张变体的一组四图，原图仍保留在前一组，左侧生成数量没有被改成三张。

当日页面脚本：

- `https://novelai.net/_next/static/chunks/5285-7b0d0ccd5ad58950.js`：从所选图复制参数并删除 upscale，生成组 imageCount=3，insertedImages 插入标记为 isVariationOriginal 的原图。
- `https://novelai.net/_next/static/chunks/2952-12a04300b81268d4.js`：generateVariations 使用原图模型、提示词、角色与采样参数；固定 strength=0.8、noise=0.1、最多三张；当前启用参考参与请求，不执行左侧导入。图像种子与额外噪声种子相差 1，color_correct=false；普通图生图归一化关闭 SMEA，宽高按最近的 64 倍数取整，正中间向上。
- 当次观察请求：img2img、n_samples=3、512×768、seed=597282670、extra_noise_seed=597282669；随后返回三个连续种子的变体。截图与脱敏请求 / 相关代码片段保存在本地审计目录，不提交网络头、登录状态或图像缓存密钥。

## 实现

`OfficialImageVariations` 为纯请求投影，同时供动作与价签复用。PNG 元数据优先、对象元数据兜底；已记录预设剥离生成后缀再按原档位追加一次，缺失预设不借用无关草稿；角色与位置来自原图。缺少可恢复参数的外部图继续使用最新草稿的只读投影，明确拒绝超出 3MP 上限的源图。

一次发送三图请求，不读取主生成的重复次数或每次图片数，不走元数据导入、随机块重抽或本地增强。Vibe 编码使用独立请求快照，不回写草稿。生成 / Krita / 冷却门禁先检查，异步读取后再次复核，生成 provider 保留重入与取消防护。

原图采用本次组独立身份和 batchIndex=-1，带 isVariationOriginal 标记；不占生成槽位，不作为新图重复自动保存。占位、预览与完成保持原图加三个槽位的稳定布局，固定角标标识原图，钉图恢复与文件路径副本保留标记。

左下画布设置收起时按两个按钮的实际宽度包裹，展开透明底色后保留调色板宽度。两侧边距实测一致，移除右边额外空白。

此前四项修复继续包含在这份完整包中：高级内容的底部 V 形滚动提示、黑黄条纹居中的“停止超分”、按三条浮动工具条实测安全区聚焦、增强选项按后续生成尺寸保留。额外补齐超大尺寸聚焦可低于 10% 并连续缩放，以及 Max 按后续生成尺寸估价。

## SeedVR2 Sharp 与量化核验

新增 `seedvr2-7b-sharp` / SeedVR2 7B Sharp FP8，仅登记按需下载；两个管理 / 放大下拉均能选择，不修改生成草稿。权重来自 `numz/SeedVR2_comfyUI` 的固定修订 `09ced71023636e9bc8cdf9cdecfb2625d1e691e8`，文件 `seedvr2_ema_7b_sharp_fp8_e4m3fn.safetensors`，8239729704 字节，SHA-256 `4261d18fd9c331f4c8f14b475c9148bd8c3f1512240ace55fe31a179e0a960b0`。元数据由 Hugging Face blobs API 核对，未下载大权重。保留 36 层卸载上限，复用现有 VAE / venv；兼容旧清单 `0de0f816…` 仍逐项匹配所需文件大小与哈希，不放宽损坏文件检测。

Comfy-Org 当前另有 INT8 ConvRot 转换权重，包括 3B、7B、7B Sharp。它们不应与字节跳动原始发布或 NumZ / GGUF 版本混淆：来源见 [Comfy-Org 模型说明](https://huggingface.co/Comfy-Org/SeedVR2)。当前固定 NumZ 后端普通 safetensors 直接加载，没有该格式的旋转 / 量化反解支持；[上游 INT8 支持 PR 613](https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler/pull/613) 经 GitHub API 现场核对仍未合入，提交中的实现也包含解量化到 FP16 的路线。不能直接换文件或保证显存更省，也不能仅凭 INT / FP 位数宣称画质更优。本批保留 FP8，仅接入 Sharp 可选项，不宣称完成 Sharp / INT8 图像效果对照。固定后端相关源码哈希与发布元数据保存在 `seedvr2-research/`。

## 核验与交付

- 93 项动作 / 请求 / 价签 / 保存 / 画布相关回归通过，随后补充非标准尺寸取整与低比例缩放回归。
- Sharp 定向回归 161 通过、1 项原有 RTX 审计跳过，新增旧记录兼容 / 身份核验、共享安装与单型号删除回归。管理页增加 60 张五语言、两主题、两宽度实绘，原有截图另存不覆盖。
- 12 张新真实控件实绘：中英、明暗，紧凑设置、原图与三张分组、模拟超大世界尺寸的聚焦几何；图片使用合成色块。原先 140 张五语言宽窄与 150% 字号实绘继续保留。实绘不等于已安装的 Windows 实机验收。
- 最终全量测试、全仓分析、Windows Release 与 Glass AOT 同一性、206 资源、原生文件、托管清单与五份旧 ZIP 的结果由本次 delivery 收据记录。

本批审计：`.dart_tool/official-variations-feedback-20261006/`。最终运行包另行组包，暂不覆盖 Studio、不热重载、不自动重启，也不下载超分权重或 Python/CUDA 环境。

最终冻结源码 `26612e957e32077dbee8eb993991200a52eb0cba`：全量 4558 通过 / 5 原有实机审计跳过 / 0 失败，全仓 analyze 无诊断；Windows Release / Glass 构建成功，AOT `4168fa2a23e6bb93e9af8371ac0107630e5695873bf676f2f7766940149a70eb` 一致。1416 编译输入、547 测试输入、206 资源、31 原生文件、241 托管文件复验；资源变化仅高级组件清单。完整 ZIP 242502180 字节，SHA-256 `3d086beeae0bae13187ff3d76162d355852cb88131d55cf07dc9966137762be9`，所有条目与交付目录逐字节一致。只读安装预检通过，ProgramFilesModified=false；保持 installation_hold=true / installed=false，未覆盖 PID 24324 正在运行的 Studio。旧四项反馈外部待安装记录仅标为被新包替代，原 ZIP / 内嵌收据 / 满意检查点保持封存。

## 安装完成 · 2026-10-06 16:34 Asia/Taipei

用户确认“ok，已关闭”后现场进程为零，解除外部收据等待并安装。新收据与当前安装记录字节一致，installed=true / ready_to_install=false / installation_hold=false。安装后的 1416 源码输入、547 测试输入、206 资源、31 原生文件、241 托管文件与冻结 ZIP 复验通过；前版 `1329ddf2` 的 data / 客户端 / 清单 / 收据保存在原运行包根 `.dart_tool/glass-before-official-variations-feedback/`，206 备份资源和只读回退预检通过，没有实际回退。安装后相关进程仍为零，未自动启动；用户草稿、账号、图库、桥接参数、既有模型与运行环境未修改。本段为当前安装状态，前述待安装记录保留为准备阶段证据。
