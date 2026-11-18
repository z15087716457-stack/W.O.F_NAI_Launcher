# Windows 本机 2.4.2+121 交付

桌面快捷方式指向原 Glass 运行目录。2026-11-18 已安装本次累计 Windows Release，Pi 1.5.2。GitHub 正式发布继续暂停，桌面界面待用户实测。

本批包含[生成中编辑提示词](generation-draft-editing-2026-11-18.md)、[资源小窗](resource-window-toggle-2026-11-18.md)、[图库详情尺寸](gallery-viewer-original-size-2026-11-18.md)、新生成图片「仅 NAI」筛选以及设置中的旧版目录迁移。Agent 的标签搜索、共现和 RAG 使用说明随包同步。

| 检查 | 结果 |
|---|---|
| 源码 | `aeca2ba78500b916d2aaca18070f8ddfad80d3e8` 加本机未提交修改，冻结 2,026 项输入 |
| 安装 | 15,724 项程序文件逐项核验，替换或新增 9 项，退役 0 项 |
| 入口 | EXE、桌面快捷方式、AOT、包信息及安装收据校验通过 |
| 用户数据 | 44 项关键文件和 3 项 RAG 索引内容哈希一致，图库数据库与 AppData 入口通过比对 |
| 相关回归 | 提示词 332、资源小窗 408、图库尺寸 222、「仅 NAI」326、迁移与设置 138 项分别通过，各组有重叠 |
| 交付检查 | 全仓静态分析通过，Windows 原生小窗检查、8 项 Agent 工具检查、安装后 Pi 宿主和隔离回退检查通过 |

AOT SHA-256 为 `c2644aca1754ada1de61d327be4b0de051e647e78986d766a75618f65ad71e3e`。安装后未启动 Studio。

本批材料位于 `.dart_tool/local-2.4.2-build121-20261118/`。只读检查备份可运行 `python .dart_tool/local-2.4.2-build121-20261118/update.py verify-backup`。从托盘完全退出 Studio 后，`python .dart_tool/local-2.4.2-build121-20261118/update.py rollback` 可恢复 2.4.2+120。
