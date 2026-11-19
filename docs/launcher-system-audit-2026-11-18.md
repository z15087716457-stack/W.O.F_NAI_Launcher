# 启动器系统审查 · 2026-11-18

在 Windows 上用独立访客数据走过首次启动、生成工作台、本地画廊和设置。对账户、生成、图库、检索、Agent、工具、更新及数据迁移跑了功能回归。以下为本轮源码修改，桌面安装版为 2.4.5+123。前一轮的设置键盘导航、RAG 超时提示、空图库和资源小窗搜索位置也纳入了验证。

## 已复现并修复

| 流程 | 触发条件与修复结果 | 回归 |
|---|---|---|
| 批量生成与复用 | 模拟服务返回缺少生成元数据的 PNG，逐张读取落盘文件。现在使用各自请求的提示词和种子补写，已有元数据优先。启用自动保存时每批完成即保存，中途取消仍可找到已完成批次。 | [批量落盘测试](../test/presentation/providers/image_generation_provider_test.dart) |
| 重试批次 | 连续两批 503 耗尽自动重试，第三批成功，原先手动重试消失。现在按原顺序保留可重试的批次及尚未发送的批次，重试已发送失败项会使用原种子。部分回图的请求保持原处理方式，仅补后面未发的批次。 | [重试、部分回图和取消](../test/presentation/providers/generation/image_generation_cancel_test.dart) |
| Vibe 参考图 | 请求发出后，把同一位置的参考图 A 换成 B。A 的编码现在只归提交时的 A，B 可继续使用自己的编码。 | [参考图回包测试](../test/presentation/providers/image_generation_provider_test.dart) |
| 图库删除池 | 撤销时模拟索引恢复失败。属于删除池的图片会回到池里，可再次恢复。混入请求的其他路径维持原归属。 | [删除池测试](../test/data/services/gallery/gallery_delete_pool_store_test.dart) |
| 应用更新 | 连点两个入口原来会下载两次，重置后旧请求还能带回已清除的包。现在每次只有一个下载或安装任务，旧任务完成时会核对身份。已下载完成的文件仍可安装。 | [更新生命周期](../test/presentation/providers/update_check_lifecycle_test.dart) |
| 设置概览 | 有 RTX 4080 的 Windows 机器，概览曾持续显示没有独显，模型数也来自静态目录。概览与详情现在共用异步显卡探测、真实模型清单及其缓存。探测中显示检测状态，无法读取 NVIDIA 信息时给出对应提示。兼容本机 NVIDIA-SMI 621.14 的 CUDA UMD Version 表头及旧版表头，修复已检测到 RTX 却缺少 CUDA 版本的问题。 | [概览与详情接线](../test/presentation/wiring/settings_dictionary_refresh_test.dart) |

## 覆盖范围

| 检查方式 | 已验证的流程 |
|---|---|
| Windows Release 访客窗口 | 跳过登录进入工作台。开启「仅 NAI」的空图库可导入，空收藏显示自己的空状态。在测试目录放入普通 PNG 和带 NAI 元数据的 PNG 后，画廊自动同步，筛选开为 1 张、关为 2 张，图卡和详情均为 512 × 320，种子为 12345。另检查未启用检索的页面。修复后，首次进设置概览会先显示检测中，再显示 RTX 4080、16 GB；打开本地放大详情得到同一显卡，CUDA 13.5、INT8 与 RTX Video 均显示在右端。[最终实机截图](../.dart_tool/system-audit-20261118/native-upscale-gpu-fixed.png) |
| Flutter 页面、接线、服务与文件 | 覆盖启动、路由、账户切换、编辑器与翻译、生成和取消、Krita 调用、图库和参考库、在线浏览、资源小窗、设置、更新和备份迁移。针对测试中点击被弹层挡住或还在视口外的问题，修正了 Agent 工具回图、Skill 菜单和服务商目录切换的点按与断言；在线查看器用标题文字所在坐标验证拖窗。 |
| 检索与 Agent | 离线临时库上执行 169 项 Python 测试，包括真实 worker 启停和 5 项对固定版本 DanbooruSearch 的同向量差分。Node 端 160 项通过，外部模型调用使用测试服务。 |
| 本地放大 | 真实运行随包的 Vulkan 程序，验证分数倍率、透明通道、取消和清理子进程。两项另需历史可选模型包或 NVIDIA SDK 压缩包的硬件测试本轮缺少本地缓存。 |

### 本机复查

工作树的 `.dart_tool/system-audit-20261118/` 保存日志与访客窗口截图。各批次有交集，不将计数相加。主要记录为 `ui.log`（2,713 项页面回归）、`cross-features.log`（579 项）、`scenarios.log`（293 项针对性回归）、`storage-updates.log`（122 项）、`gpu-native.log`（2 项）、`settings-final.log`（68 项）、`rag-python-final.log` 和 `agent-node-final.log`。首轮接线测试有 6 项被统一沙箱路径干扰，使用这些测试自身的临时目录后通过，见 `fixed.log`。首次并发运行 Node 有 1 项等待本地测试服务超时，单文件 9 项及限制并发后的完整 160 项均通过。

全仓静态分析、Windows Release 构建和更改文件的空白检查通过。

本轮在线支付、生图服务端、第三方账号登录、正式图库的全量索引以及 macOS 桌面属于未实测范围。生成回归使用本地替身；测试未产生线上生成费用。变更已在工作树构建，桌面更新和 Git 发布未执行。
