# 原生画布帧时间探针

只用于开发采样，不安装 Studio，不读账号、草稿、图库或模型，不调用生成接口。合成 1664×2432 PNG 与内存设置，使用生产 `GenerationPage`、`GenerationCanvasWiring`、两侧背景和三个工具条。窗口逻辑大小 1600×1000，实际视图大小／DPR／刷新率随结果记录。

登记 SDK：`E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7`。在有效源码根运行：

```bash
python tool/canvas_frame_benchmark/prepare.py
```

随后在 `.dart_tool/canvas-frames-20261016/app/` 运行 `flutter pub get --offline` 和 `flutter build windows --profile --no-pub --no-tree-shake-icons`。源码探针更新后先复制 `main.dart` 到独立工程的 `lib/main.dart`，等构建结束后再采样。

```bash
python tool/canvas_frame_benchmark/run.py before --rounds 3
python tool/canvas_frame_benchmark/run.py after --variants full --rounds 3
python tool/canvas_frame_benchmark/run.py after-one --variants full --count 1 --rounds 1
```

结果文件不覆盖。`full` 保留完整效果，`no-sides` 仅停用两侧背景，`off` 使用已有通道关闭设置；三种状态都保留原图与三个工具条。拖动／滚轮注入生产指针入口，缩放使用生产平滑缩放相机操作。路径按时间定义；每段 6 秒，记录引擎 `FrameTiming` 的 build、raster、total、vsync 时间戳，不能把它们称为屏幕实际呈现 FPS。滚轮刻意为 24 次／秒，空闲帧间隔不能直接计作丢帧。

探针从当前 Windows runner 复制，使用独立互斥体，只注册自身需要的窗口插件；未启动完整 Studio 的浏览器／视频／托盘服务。驱动隔离 APPDATA、LOCALAPPDATA，结果及固定画面 PNG 完整写出后才结束自己创建的进程。早期测试壳退出阶段异常的试跑不纳入正式对比。原生帧采样期间不并发构建／测试。

`cpu.py <探针日志> --enable` 通过该进程的本地 VM service 启用 CPU 采样；之后不带 `--enable` 保存采样。启用 CPU profiler 的运行只用于找热点，单列于无 profiler 的前后对比之外。

交替复测先运行 `prepare_paired.py`：把当前 `lib/` 复制到隔离包，只将四个通道文件换成基线 `370ce2153` 的内容；资产与工具资源是只读使用的目录联接。编译旧包前保存当前 Profile AOT。旧包编译结束后，将其 `data/app.so` 保存为审计目录 `before-profile-app.so`，并用 `original-probe-package-config.json` 恢复独立工程的包配置。随后 `run.py paired --paired --rounds 3` 会在每个独立进程之间切换两份 AOT，先等自己创建的进程结束再覆盖测试包。该操作不修改有效源码或桌面安装。不要递归处理联接目标。

参考渲染对比：先 `python tool/canvas_frame_benchmark/prepare_visual_reference.py <优化前提交>`，再运行 `flutter test --no-pub .dart_tool/canvas-frames-20261016/equivalence_test.dart`。独立保存原渲染器，比较明暗、种子、缩放、运动相位及缓存复用后的 RGBA，不替换已有黄金 PNG。

外部向量任务会干扰测量；先由用户确认已暂停或结束，不自动停止用户任务。可用 `python tool/canvas_frame_benchmark/load.py .dart_tool/canvas-frames-20261016/<新标签>-baseline --seconds 12` 记录开测前负载，再用 `run.py <新标签> --paired --rounds 3 --monitor-load` 为每轮附加 CPU JSON 与 GPU CSV。采样每 2 秒一次，只读进程名、PID、CPU 时间及 NVIDIA 计数，不读取进程参数、提示词或账号。GPU 查询子进程由驱动创建并在该轮结束时关闭；两侧使用相同监测开销。

已有 `verification.json` 的生产源码／测试／构建证据时，`python tool/canvas_frame_benchmark/summarize_retest.py <新标签>` 核对相同 AOT、四个生产文件、其余保护文件、原生画面及安装哈希，生成新的 `<新标签>-verification.json`，拒绝覆盖旧结果。新数据与旧测量分开；低频负载计数只提供背景，不代表屏幕呈现 FPS 或 GPU 调度跟踪。此次用户确认暂停后的正式复测标签为 `idle-retest`，此前 `paired` 数据保留为向量任务可能并发的历史记录。
