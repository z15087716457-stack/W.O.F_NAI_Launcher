# FEAT-68 本地超分 · 第一阶段核验

有效源码为 `E:/A.I/NovelAI/.devin/wt/nai-launcher-src/`，分支
`devin/gallery-redesign`。本批合入同分支已有的目录排序 `4d083dce`
与六页顶部拖拽 `a7698853`。已安装运行版为 `36f4d4f0`；
完整满意版本检查点 `2026-10-05-studio-verified` 保持固定。

## 实现范围

- 放大面板默认本地，顶层只有本地 / NovelAI。原有 ComfyUI 的启用、
  节点列表、模型列表和端口不参与本地执行；连接与工作流功能仍在集成设置。
  旧 ComfyUI 参数保留，原来选择 ComfyUI 的放大入口迁移到本地。
- 运行包内置独立 Real-ESRGAN NCNN/Vulkan v0.2.0 引擎、release OpenMP
  DLL 和 Real-ESRGAN x4plus Anime 模型，不需要 Python/PyTorch/CUDA。
  本阶段支持 Windows 的 Vulkan 显卡；SeedVR2 与 RTX SDK 为后续独立阶段。
- 设置的模型管理新增本地超分标签，放大面板也可直接打开模型管理。
  支持官方快速动漫 / 通用摄影模型下载、配套 4× NCNN `.param/.bin`
  导入与已下载/导入模型删除。自定义模型须使用 `data/output` 节点；
  不把 `.pth/.safetensors` 作为可用模型。
- 引擎与模型放在应用私有版本目录 `upscale/v020`，首次离线提取默认模型。
  清单与每次运行的引擎、权重逐项校验 SHA-256；官方 ZIP 整包校验后
  只提取所选文件，解包在独立 isolate 处理。推理和模型变更互斥。
- 倍率范围 1～4，先按模型支持的倍率推理，再使用已有 Pica Lanczos3
  调整为精确目标尺寸。透明度取自原图的同尺寸 Lanczos 结果；输出 PNG。
  模型原始输出上限为 6400 万像素，模型目录长度也受原生组件限制。
- 每个任务冻结源图、模型与倍率，准备/推理/收尾阶段与实际 tile 百分比
  分开显示，不使用估算速度/显存/质量评分或按时间伪造进度。
  取消终止 native 子进程和图片处理 isolate，等待子进程退出后才释放锁；
  成功/失败清理任务临时目录，10 分钟 native 超时终止工作进程。
  托盘退出先取消并等待本地任务清理，再关闭数据库与应用。
- 结果进入中央画布和历史，保留原图字节，仅继承原图实际元数据。
  正常完成会选中新结果并请求画布定位，方便直接编辑，不抢走提示词输入焦点。
  从未带元数据的图片放大，不补写当前草稿的提示词或种子。
  源图被改动（包括改动后再改回）时丢弃晚到结果；画布选择/焦点改变过
  时保留历史结果但不抢占显示。草稿和云端费用授权规则沿用现有保护。

## 可复现验证

本机 GPU 为 NVIDIA GeForce RTX 4080。以下均使用合成测试图片，
没有发送 NAI 生图/放大请求，也未启动 ComfyUI。

```bash
CAPTURE_STUDIO_UI=1 RUN_LOCAL_UPSCALE_AUDIT=1 \
  flutter test --no-pub test/data/services/local_upscale_service_test.dart \
  test/presentation/providers/generation/local_upscale_provider_test.dart \
  test/presentation/screens/generation/widgets/local_upscale_panel_test.dart
```

`RUN_LOCAL_UPSCALE_AUDIT=1` 启用依赖 Vulkan GPU 的实际进程检查和已下载
官方模型 ZIP 的审计。普通 CI 不要求 GPU，不会下载模型。其他模型的测试
ZIP 位于 `.dart_tool/local-upscale-20261005/official-models.zip`，未提交。

- 三个模型真实运行通过；48×32 合成图的 1.5× / 2× / 2.75× 输出
  分别核验为 72×48 / 96×64 / 132×88。
- RGB、RGBA、逐像素 alpha、输出非空、真实进度、进程结束与临时文件清理通过。
- 真实子进程创建与取消竞态验证通过；失败、超时、无 Vulkan 诊断、
  不可读图像、过大输入、引擎篡改、缺失模型、错误导入和模型互斥验证通过。
- 实际历史登记验证了源提示词/种子继承、无元数据源图不污染、草稿不变、
  来源变化、手动选择、变化后改回与取消保护。
- 五语言、明暗主题、320/560px 面板和设置共 40 张实绘，使用生产字体与
  MaterialIcons；设置内实际点击本地超分标签、原 NovelAI 流程和画布编辑
  联动也纳入回归。
- 247 项合并回归通过，包含真实 Flutter 资源提取、画布结果定位、
  “改回来源/选择”与托盘退出保护核验；最终清单与
  全部检查次数以 `.dart_tool/local-upscale-20261005/verification.json` 为准。
  受影响源码静态检查无问题。全库曾有既存的其他测试 lint，未为本批改写。

## 资源与交付

官方引擎 ZIP SHA-256：
`1bbbdb12d470af80b035c773682e144c6c2f6ece9210832a289af0a48ce3fa9a`。

官方模型 ZIP SHA-256：
`abc02804e17982a3be33675e4d471e91ea374e65b70167abc09e31acb412802d`。

版本、URL、每个文件哈希和大小见 `assets/local_upscale/manifest.json`；
该清单自身 SHA-256 固定于 `LocalUpscaleModelManager.manifestSha256`。
完整 MIT / BSD / glslang 许可及依赖说明随 Flutter 资源交付。
不分发官方 ZIP 中的 debug OpenMP DLL。

Windows Release 与 Glass AOT/资源包单独构建，安装使用现有核准 Glass 的
原生壳和插件，不替换原生文件。更新 ZIP：
`build/nai-studio-local-upscale-20261005.zip`；交付单
`E:/A.I/NovelAI/nai-launcher-src/.dart_tool/local-upscale-delivery.json`；
安装/回退为同目录 `install_local_upscale.ps1` / `restore_local_upscale.ps1`。

用户确认完整退出后，现场核对 Studio、桥接与超分进程为零，于
2026-10-05 19:06（Asia/Taipei）完成安装。当前安装记录与本批交付单完全一致：
`installed=true`、`ready_to_install=false`、`installation_hold=false`。
已安装 AOT、199 项资源、31 个原生文件与 233 项托管文件复验通过。

`glass-before-local-upscale/` 已保存前版 `09ea804f` 的程序 data、189 项资源、
客户端、文件清单及安装记录；备份逐项复验与
`restore_local_upscale.ps1 -ValidateOnly` 通过，未执行实际回退。
冻结候选交付单及 ZIP 保持原值，满意版本完整检查点、草稿、账号、图库、
桥接参数与原生 Glass 文件保持原值。未自动启动、重启或热重载应用，
Windows 安装后的实机体验待用户反馈。安装证据为本机审计目录中的
`pre-install-stopped.json`、`installation-result.json`、
`restore-preflight.json` 与 `post-install-verification.json`。

官方依据：
[Real-ESRGAN NCNN/Vulkan](https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan)、
[Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN)。
