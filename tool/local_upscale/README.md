# 原生本地放大组件

`studio_upscale_worker.cpp` 是 Studio 自己的 Windows 进程宿主与 RTX Video 适配器。`--run` 使用 Windows Job Object 管理唯一一次启动及其子进程；取消、超时与父进程退出会回收这次启动的进程，等待实际退出后释放任务锁。

构建需要 Visual Studio 2022 C++ 工具，以及自行从 NVIDIA 官方获取并解压的 RTX Video SDK 1.1.0。运行 `build_worker.ps1 -SdkDirectory <SDK目录>`，输出为 `assets/local_upscale/windows/studio_upscale_worker.exe`。编译后更新 `advanced_manifest.json` 中 worker 的 SHA-256，再同步 `AdvancedUpscaleComponentManager.manifestSha256`。不要把 SDK 开发头文件、库或整包加入仓库；适配器与其对象代码支持受 NVIDIA SDK 许可约束，不能宣称为独立开源 NVIDIA 实现。

macOS 不编也不带这个 worker：它的 `--run` 只给 SeedVR2 / RTX 组件的安装与推理管进程，`--rtx` 依赖 Direct3D 11 和 NVIDIA SDK，这两类组件都只支持 Windows；常规 Real-ESRGAN 在两个平台上都由 Dart 直接启动引擎。Mac 的引擎是官方 v0.2.0 Release 的通用二进制，由 `scripts/build_macos.sh` 下载校验后放进应用包；`macos/` 里是它静态链接的 MoltenVK（含 SPIRV-Cross）、cereal 和 LLVM OpenMP 的许可原文。

SeedVR2 固定使用独立 CLI 的指定源码提交、CPython 3.12.11、uv 0.12.17 及带哈希的依赖锁。它不连接 ComfyUI 服务。安装器只在用户点击安装后下载；推理时强制离线，既不拉模型也不调用 NovelAI。源图冻结、透明通道和精确输出尺寸由现有 Dart 图像服务处理。

2026-10-05 的用户指示：约 3.9 GB 的 SeedVR2 权重暂不下载，实际 SeedVR2 GPU 推理留待安装后验证。不能用接线测试代替实际推理验收。
