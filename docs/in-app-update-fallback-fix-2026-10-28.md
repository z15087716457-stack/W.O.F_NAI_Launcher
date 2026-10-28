# 应用内更新退回浏览器下载修复

用户反馈：本机 2.1.2+55 检查到正式版 2.2.0，点击更新后由浏览器直接下载 Portable ZIP，没有出现安装重启入口。

## 原因与证据

- 当前桌面运行包位于登记的 Glass 目录，没有匹配此 EXE 的卸载注册信息，因此选择 Portable 正常；该类型原本同样支持应用内下载、校验、原位替换、失败回滚和重启。
- GitHub 实际以 `application/octet-stream` 返回 `release_manifest.json` 附件。旧 `GitHubApiService` 直接请求 `Map<String, dynamic>`，Dio 没有按 JSON MIME 解码，类型转换失败后回退到 Release API 资产。旧 `ReleaseAssetInfo.fromGitHubAsset` 又忽略 API 的 `digest`，导致资产 `sha256=null`；`VersionInfo.supportsInAppInstall` 变为 false，弹窗走手动下载分支，并优先打开 ZIP 地址。
- 合成清单缺失／超时夹具在修复前稳定复现：安装版和便携版共四项自动安装能力断言失败，另有一项 digest 读取失败；6 项通过、5 项失败。随后用真实本地 HTTP 服务保留 Dio 解码过程，复现 JSON MIME 成功、octet-stream MIME 失败的差异（1 项通过、1 项失败）。未取得本次用户实例的网络日志，未将故障推定为具体代理或网络问题。
- 2026-10-28 重新读取公开 v2.2.0 API 和清单：两个包的 GitHub SHA-256、清单哈希及大小一致，发布包元数据正常；实际附件响应头确认 `Content-Type: application/octet-stream`。原始响应、响应头与测试日志保存在 `.dart_tool/update-flow-20261028/`。

## 修复

- 清单按文本读取，再在所属边界显式解析 JSON，不依赖附件 MIME；非对象、损坏或不可用清单仍走原有回退。
- 在 GitHub 资产解析边界保留有效的 `sha256:<64位十六进制>`，不再依赖单独清单下载成功才能自动更新；清单正常返回时继续合并原有元数据。无效／缺失 digest 不作为校验值。
- 真正需要手动下载时优先打开该版本发布页面，避免直接下载 ZIP 而没有说明或安装重启入口。
- 保持安装类型识别、用户确认“安装并重启”、任务忙碌限制、SHA-256 完整性检查及原有更新脚本；没有强行把便携运行目录改成 Setup 安装目录。

## 验证与交付

- 定向回归 18 项通过；包含真实 HTTP 的两种 MIME、清单正常／缺失／超时 × 两种包、digest 边界，以及实际弹窗点击下载后出现安装重启和手动入口打开发布页。
- 更新相关完整范围 68 项通过、0 失败：包括续传、取消、待安装状态恢复、安装脚本、Portable 替换／失败回滚、相邻数据保留和更新提示组件。
- 修改的六份 Dart 文件静态分析无问题，`git diff --check` 通过。
- Windows Release 构建通过（登记 Flutter 3.47.7，`--no-pub --no-tree-shake-icons`）；产物位于源码 `build/windows/x64/runner/Release/`，仍为未发布修复构建，不代表当前桌面已换装。
- 本次只修改源码并构建，未安装、未发布新版本，未启动或操作用户 Studio，也未调用真实生成或模型接口。
