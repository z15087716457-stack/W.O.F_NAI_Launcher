# RAG 首版：标签局部上下文推荐

后续交付：已随 [r6 累计更新](cumulative-preview-r6-2026-10-15.md) 安装；下文保留开发完成时的验证状态。

2026-10-15。首版已实现并完成本地验证，等待下一次累计更新；正式安装仍是 r5，本次没有安装、启动 Studio、推送或发布。产品范围以工作区 `04_工具/开发计划/待办清单.md` 的已确认需求为准。

## 已实现的行为

- 设置导航在 NAI Agent 下增加同级「RAG 向量系统」，可配置本地权重、独立 Python、CPU／CUDA、上下文模式，安装专用运行依赖。默认关闭，打开设置不会下载模型或自动首次建库。
- 首次建库先预览当前标签目录的数量与范围，再点击开始。标签／别名／已有 Wiki 释义作为文档；原始库只读。后台按 32 项提交，已完成部分可搜索；支持暂停、继续、清除和重建。之后只为新增／内容变化的文档计算向量，删除项不再返回；仅使用量变化不重嵌入。
- 主提示词、各角色及正负面分别从自己的编辑器取文本。两种模式只有「光标前 120 tokens」和「插入点前后合计 120 tokens」，默认后者；使用 Gemma 分词器、完整标签边界及 UTF-16 光标坐标。权重语法被清理，块实例私有字符不作为标签送入模型。全文仅用于已有标签去重；草稿不写入永久索引。
- Gemma 语义召回与已有共现／普通候选合并，Qwen 对最多 32 个文字候选重排。精确英文／别名／中文匹配优先。候选始终来自当前真实标签源；重排分数不解释为下一标签概率。
- 方向键、鼠标悬停或焦点选择后保持当前列表，插入后刷新下一次推荐。弹层关闭、编辑内容或角色／正负面切换、配置变化会取消或丢弃旧请求。普通检索不等待向量结果。
- 标签扩展头部显示 RAG 小字、真实可用／部分就绪提示与查询进度。暂停建库不禁止查询；关闭来源停止查询和更新、保留已建索引。
- 交互请求优先于下一轮后台建库；本地超分执行前让出模型显存，结束后恢复。暂停／空闲后卸载模型。推理进程和安装进程均由 Windows Job 管理，退出或异常终止回收本次子进程。

## 运行与数据

`lib/core/rag/` 提供配置、运行环境安装、JSONL 客户端和进程宿主；`rag_provider.dart` 管理状态与资源。`tool/rag/` 是随应用资源打包的本地 worker，脚本按内容 hash 提取；`assets/rag/windows/stdio_host.exe` 为自编译原生宿主，调用前核对 SHA-256。修改宿主后运行 `tool/rag/build_host.ps1`，同步 `rag_process.dart` 的 hash；脚本使用 Visual Studio C++ 工具，不依赖 NVIDIA SDK。

专用数据位于现有应用数据目录的 `rag/v1/`，包含 runtime、workers 和 indices。索引按嵌入模型配置／分词器内容、权重文件特征及管线版本区分；SQLite 向量是恢复依据，USearch ANN 为可重建派生数据。保存检查点 generation，启动时优先加载，损坏或不一致则从 SQLite 恢复。完整标签名排序每轮只做一次，不为每批重新全库排序，也不长期占用原库读事务。

原权重目录保持：

- `E:/A.I/NovelAI/04_工具/models/embeddinggemma-2/`
- `E:/A.I/NovelAI/04_工具/models/Qwen3-Reranker-0.6B/`

模型文件不随程序包复制。首版只加载 Gemma 的文字编码器，关闭音频和当前任务不用的视觉编码器，图片权重原样保留以供后续图片检索。推理强制本地文件／离线模式、不信任远程模型代码。CUDA 支持时采用 BF16，否则 FP32，不采用该模型不支持的 FP16。

专用依赖验证版本：Python 3.12.11、torch 2.10.0+cu128、torchvision 0.25.0+cu128、transformers 5.19.0、sentence-transformers 6.1.0、numpy 2.5.4、usearch 2.26.4、Pillow 12.2.0。应用也提供 CPU 安装配置，本次真实推理验证使用 RTX 4080／CUDA。安装只在用户点击后运行，从固定官方 uv 归档、PyTorch 索引及 PyPI 获取依赖，不修改已有超分环境，不下载权重。

Windows worker 先在主线程加载 NumPy／Torch／ST 原生依赖，再启动执行线程并读取 JSON 管道；实测后台首次导入 NumPy 与主线程阻塞读管道会卡在 DLL 初始化，这一顺序不可退回。

协议包含 `configure/status/preview/start/pause/resume/search/suspend/release/clear/unload`，请求逐一编号，`cancel` 只撤销对应请求；索引进度为事件，错误仅返回受控代码。`start` 需要未过期且来源未变的预览 plan；持久化暂停与首次确认状态，重启不跳过用户的首次确认。全量模型加载、建库、查询均在独立进程中进行。

## 验证与证据

本机证据目录：`.dart_tool/rag-20261015/`，不提交用户数据、运行环境、测试索引或产物。

| 验证 | 结果／证据 |
|---|---|
| 实际权重 + CUDA worker | 96 项隔离标签，部分建库后查询、正／负面、两种窗口、暂停／恢复、让出／恢复显存、关闭／重新加载索引通过；`real-worker-smoke.json`、`real-worker.log` |
| 真实查询耗时 | 小样本首次约 2.69s、热查询约 0.19s；两种长输入均取到 119 tokens。仅为这组夹具的观测，不代表全库性能 |
| Python / ANN / 原生宿主 | 27 项通过；包含增量复用、别名去重、源变化、查询不入库、检查点损坏／删除提交后崩溃恢复、持久暂停、Windows 引号与 Unicode、宿主／父进程退出回收子孙进程；`python-tests.log` |
| Flutter 范围回归 | 设置、标签扩展、提示词、生成接线六项及本地超分 provider 共 657 项通过；`regression-final.log` |
| 收尾进程与资源回归 | 32 项通过、3 项既有可选 GPU 实测跳过；含真实子进程 IPC 6 项和超分让出／释放顺序；`process-tests-final.log` |
| 新设置页 | 5 语言 × 深浅 × 280／760 内容宽度，20 项通过、40 张有背景实绘；`settings-captures.log`、`captures/` |
| 静态与构建 | 全仓分析无诊断，Windows Release 通过；`analyze-final.log`、`windows-build.log`、`build-receipt.json` |
| 新进程恢复 | 新建 worker 进程复用之前 96 项索引，返回 5 个候选；`worker-restart-smoke.json` |
| 完整源库只读探测 | 内置 221787 项标签名排序约 0.13s，首／中／末批各 32 项元数据约 0.002–0.003s；没有建立全库向量，见 `catalogue-source-probe.json` |
| 界面与安装边界 | 141 份锁定 UI 文件及已有 DEVELOPMENT 修改逐字节未变，r5 安装收据不变；`boundaries.json` |

复跑核心验证（Bash，使用登记的 Flutter SDK）：

```bash
RAG_TEST_PYTHON=/absolute/path/to/python.exe PYTHONIOENCODING=utf-8 \
  /absolute/path/to/python.exe -m unittest discover -s tool/rag -v
RAG_TEST_PYTHON=/absolute/path/to/python.exe flutter test --no-pub \
  test/core/rag test/data/services/local_upscale_service_test.dart \
  test/presentation/widgets/tag_expansion/tag_expansion_rag_test.dart \
  test/presentation/providers/generation/local_upscale_provider_test.dart
flutter analyze --no-pub
flutter build windows --release --no-pub --no-tree-shake-icons
```

## 后续范围与限制

未自动为用户的完整标签库或工作区建立向量；首次全库建库的时间、磁盘和内存峰值需要用户确认范围后实测。模型冷加载仍有等待，交互界面保持普通搜索可用。独立运行环境安装器已接线和校验固定资源，本次使用隔离测试环境完成实际推理，未在正式应用数据目录执行安装。

Wiki／提示词块独立搜索、工作区目录索引、图库图片及 NAI 参数索引、Agent 检索工具与动态卡片是后续批次；本次不提前点亮这些入口，也不把图片送给文字重排器。没有运行整库离线翻译，没有调用 NAI 生成或任何付费接口。
