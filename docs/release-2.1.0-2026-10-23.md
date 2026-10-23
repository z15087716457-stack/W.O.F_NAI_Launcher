# W.O.F NAI Studio 2.1.0 · 正式发布

2026-10-23 发布 Windows x64 正式版，显示版本 `2.1.0`，构建版本 `2.1.0+43`。

- [GitHub Release v2.1.0](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.1.0)
- [发布构建记录](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/39905951113)
- [更新内容](../CHANGELOG.md#210---2026-10-23)
- [NAI Agent 教程](guide/zh-CN/nai-agent.md)

## 发布与来源

- 用户明确授权发布 2.1 版本；源码、五语言教程和截图已推到 `main`。
- 注解标签 `v2.1.0` 指向 `100c773518cec3de8d218da7e93f8ca9c7f45190`，与本机已安装 2.1.0 的功能源码一致。
- 沿用 `.github/workflows/release.yml`：校验 tag/pubspec → Windows 编译 → 安装包及便携包 → 更新元数据 → 发布。
- 三个 CI 作业全部成功；2026-10-23 05:52:59 UTC 正式发布，非 draft、非 prerelease，GitHub `/releases/latest` 已返回 v2.1.0。
- `main` 后续的 `626e49f82` 只修复版本测试：不再要求 pubspec 永远是 `2.0.0+42`，改为按当前 pubspec 验证显示版本与完整版本；保留旧版显示测试。没有修改发布包的功能代码，不移动既有发布标签。

## 正式文件

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_Windows_2.1.0_Setup.exe` | 199833265 | `ae82c3ecdb83d06710883a095ddbddedc34fb69b6c718f6ca2a05c5d2f4d0c8d` |
| `WOF_NAI_Studio_Windows_2.1.0_Portable.zip` | 322269715 | `f3acdc1c5ec21ea5b0010c9b77ea734923970bc3fd4f12b3813b4178e312da3a` |

另附 `checksums.txt`、`release_manifest.json`、`release_notes_v2.1.0.md` 和两个产物各自的 `.sha256`。

正式包由 GitHub CI 构建；没有用本机编译包替换线上文件。CI AOT SHA-256 为 `f3a676151dc5320240a9192925305b499404ca2918efe2560370100f8f812efb`。本机已安装包和 CI 包构建环境不同，不要求原生二进制哈希一致。

## 验证

证据保存在源码根 `.dart_tool/release-2.1.0/`，不随包分发。

| 检查 | 结果 |
|---|---|
| 推送前 | 工作树干净；正常快进推送；版本、标签、更新日志一致；LFS fsck 通过；本次文本扫描未发现凭据 |
| 本机既有交付 | 1779 项受影响回归、全仓分析、Windows Release、12 项安装/回退模拟、安装后文件核对通过 |
| 补跑全量 Flutter | 修正写死旧版本的测试后，**8439 通过、0 失败、5 跳过**；跳过项是既有真机/联网验证 |
| Node Agent | **88 通过、0 失败、0 跳过** |
| 官方产物下载 | 两个文件大小与 GitHub、更新清单相同；GitHub digest、checksums.txt 和单独 .sha256 均一致 |
| 便携 ZIP | CRC、路径和唯一条目核对通过；15301 个文件；15300 条内部 SHA-256 全部匹配 |
| 包身份 | `package-info.json` 的版本、sourceCommit、AOT、stable 渠道和数据目录正确；无用户数据目录 |
| 数据库 | 四个随包 SQLite 只读 quick_check 均为 ok |
| Agent | Node v24.18.0、Pi 1.3.0、两项内置 Skill；CodeMode/MCP/会话恢复合成冒烟通过，21 个业务工具 |
| 本次变动 | 随包 Agent 工具/权限/Skill 与 RAG Python 文件忽略 CRLF 差异后和源码相同；包含提示词组角色位置 schema |
| RAG | 官方包原生 stdio 宿主及 Python worker 在隔离开发环境 ready/shutdown 通过，不加载模型、不建库 |
| 官方 Setup | 只解包、不执行安装；全部载荷逐文件与便携包哈希一致；ProductVersion/FileVersion 为 `2.1.0+43`，NotSigned |
| 在线页面 | Release 页面、中文教程和新增提示词组截图均返回 200；Release 正文与附件一致 |
| 自动更新入口 | GitHub latest 返回 v2.1.0；Setup/Portable 文件名、版本、大小与 SHA-256 元数据符合现有识别规则 |

## 边界

- 未启动应用 GUI，未调用真实模型或 NovelAI 生图，未操作正式索引、账号或草稿。
- 本次没有再次安装 CI 包；用户桌面的 2.1.0 保持本机交付版本。
- 安装器源码与 2.0.0 相同；本次验证正式 Setup 解包载荷，未重复运行交互式向导或端到端自动更新。原安装/升级/卸载、1.x 就地升级测试证据仍见 [2.0.0 发布记录](release-2.0.0-2026-10-22.md)。
- 安装包仍未签名，Windows SmartScreen 可能提示。
- 真实生图、精准参考大于 1 的服务端效果以及用户索引上的状态显示仍以实际使用反馈为准。
