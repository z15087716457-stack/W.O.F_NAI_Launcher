# W.O.F NAI Studio 2.3.0 · 发布核验

2026-11-06（Asia/Taipei）发布 Windows 正式版 **2.3.0+85**。[正式下载](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.3.0)、[发布构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/42206145076)与[完整更新](../CHANGELOG.md#230---2026-11-06)。

## 源码与验证

- `main` 与附注标签 `v2.3.0` 推送到提交 `b39fbf182e76ac369c6a3f5a35584ef6f5455b4a`。发布核验和说明模板修订另行提交。
- Windows Release 本机构建、全仓静态分析、158 项定向回归、发布清单夹具和打包脚本测试通过。四库 LFS 对象已核验。
- 安装说明区分了旧客户端发起的更新与 2.3.0 起显示安装进度的行为。发布页与附带说明一致。

## 正式包

Windows 发布三个作业通过，7 个资产齐全。Portable 共 15,554 个文件，内部 15,553 个 SHA-256 全部核验。Setup 解包载荷逐项与 Portable 一致。四库 SQLite quick_check、Agent 合成测试、RAG 启停与 8 项 checkpoint 检查通过。

| 文件 | 字节数 | SHA-256 |
| --- | ---: | --- |
| WOF_NAI_Studio_Windows_2.3.0_Portable.zip | 323,921,605 | 14a456a548e065db577346a6c46436ad6bf70d4cc2991cac6250cca9a3aaa711 |
| WOF_NAI_Studio_Windows_2.3.0_Setup.exe | 200,763,389 | 0db2f1e1e6f2c0be2acb322596c09478846c663a6c8ce8e31d20d3a161f5803a |

## macOS 通用测试包

macos-26 runner 从 v2.3.0 标签对应的源码构建了 **2.3.0+85**。支持 macOS 13.5 及以上的 Apple 芯片和 Intel Mac。平台测试、41 个 Mach-O 文件和解包后的签名在 CI 通过核验。下载后再次核对了 SHA-256、版本、源码和主程序及随包工具的双架构。

测试包使用临时签名，未经 Apple 公证，界面启动待实机验收。从 Release 下载并解压 Portable ZIP，再通过 Finder 打开应用。[下载测试包](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.0/WOF_NAI_Studio_macOS_2.3.0_Portable_Test.zip) · [SHA-256](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.0/WOF_NAI_Studio_macOS_2.3.0_Portable_Test.zip.sha256) · [构建记录](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/42223282567)

Portable ZIP 的 SHA-256 为 `4ca8346972e04ed4afe329d0d61552ac4488d57635596214bb82541d5979c798`。

## 桌面交付

原桌面快捷方式指向 **2.3.0+85**。安装后核对 15,553 个程序文件，本次替换 7 个。数据目录、索引与快捷方式已核对，2.2.6+84 回退已验证。界面由用户启动验收。

公开包与本机直装分别构建。发布核验在 `.dart_tool/release-2.3.0/`，安装与回退在 `.dart_tool/local-2.3.0-build85-20261106/`。
