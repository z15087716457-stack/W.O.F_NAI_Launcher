# RAG 运行恢复与 GPU 标记对齐 · 2026-11-16

按用户反馈完成源码修复，并为本机实际 Python 环境补齐缺少的 `jieba==0.42.1`。**已按后续授权随本机 2.4.1+117 安装，包含右侧大图预览，未自动启动，待用户复测。** [桌面交付核验](local-2.4.1-build117-2026-11-16.md)。故障原因及修复前证据见[审查报告](rag-recovery-audit-2026-11-16.md)。

## 修复结果

- `Worker._unload_in()` 只检查现存 encoder，移除退役 scorer 字段。真实 Models 配置后能够继续处理状态查询、空闲卸载和挂起／恢复。
- 工作循环致命异常先完成原有拥有者关闭与检查点，再发送 `fatal`；Dart 客户端转入既有断开路径，结束挂起请求，后续刷新重新连接。正常请求排队／推理超时仍只取消对应请求，不因此重启整个宿主。
- 环境 probe 先核对固定依赖，再做导入检查；返回解释器缺失、依赖需更新、Python 版本不符、导入失败、检测超时等独立原因。设置页显示相应信息，保留检测入口；检测中不再沿用旧工作进程的 ready 标记。五种语言同步。
- GPU 绿色能力标记恢复卡片右对齐；窄窗保持右侧换行。没有改动能力判断或 GPU 选择。

旧测试替身已去掉虚构 scorer；新增真实 Python 进程链和客户端重连覆盖。扩展回归还修正了缓存统计测试：Wiki 结果与复用图片地址是两个实际缓存条目，清除后都必须归零。生产统计与清除逻辑无需改动。

## 本机环境与索引

已选 AppData 路径的父目录 `com.example/nai_launcher` 是指向当前 `user-data` 的 Junction，两种路径实际访问同一环境。使用本机已缓存的固定版本 jieba wheel 离线安装，只增加该包；其他已装包的版本保持。原联网安装停留在下载阶段后已停止，没有用全量升级替代定点补包。

实际执行生产 probe 代码：修复前约 0.3 秒返回 `dependencies: [jieba]`；补包后返回 `ready=true, cuda=true`。此结果验证依赖导入与 CUDA 构建可用，不代表已加载权重或验收推理性能。解释器选择、模型目录和用户参数保持。

旧 `tags` 638,857 条、`blocks` 726 条向量仍在。补包前后池 SQLite、ANN、ANN 元数据的大小及修改时间一致，没有删除、重建、迁移正式索引。新多视图标签集合原本为空，首次建立仍需用户明确操作；其他来源不因本次恢复要求重建。

## 验证与证据

1,006 项相关 Flutter 功能／布局回归、153 项 Python 检查全部通过；Python 使用补包后的实际环境，不再注入隔离安装目录。全仓分析 0 问题。材料目录：`.dart_tool/rag-recovery-fix-20261116/`。

旧设置 PNG 基线另外检查，16 项通过、11 项差异（overview、appearance、storage、dictionaries、rag、upscale、overview-dark、appearance-dark、upscale-dark、search、narrow）。临时恢复本轮修改前的 `settings_intel.dart` 再跑，同样 11 项失败；随后逐字恢复修复后的源码。未更新锁定 PNG 或扩大豁免区域。该组没有算入 1,006 项通过数，也不能宣称全套截图检查通过。新 GPU 对齐及环境状态另有几何断言和实绘核验。

- `worker-process-before.log`：同一真实进程链测试指向修复前 worker，configure 后复现 scorer AttributeError；不是只检查进程握手。
- `python-final.log`：实际本机环境运行 `tool/rag/test_*.py`；`test_worker_process.py` 以 `RAG_TEST_PYTHON` 显式启用 native 依赖进程检查，隔离目录内保留旧标签／积木向量。
- `regression-final.log`：RAG、补全、Wiki、图片预览、标签扩展、设置行为／布局与实际接线。
- `analyze.log`：全仓分析。
- `regression.log`、`goldens-before.log`、`probe_before_goldens.py`：旧 PNG 基线差异和改前复现；`triage.log` 保留缓存预期修正前的定位证据。一次广并发运行的 Windows 临时目录占用在串行及最终并发2回归未重现，没有因此修改 Agent 生产逻辑。
- `runtime-before.json`、`runtime-after.json`、`jieba-local-install.log`：依赖与正式索引文件状态。
- `ui-capture.log`、`captures/`：13项专项、真实字体隔离部件实绘，覆盖五语言、800／1600窗口及150%缩放。不是用户运行窗口截图。

没有请求真实 NAI／语言模型接口，也未执行权重推理、正式建库、写入用户草稿、提交或发布。
