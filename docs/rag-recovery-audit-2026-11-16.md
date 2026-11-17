# RAG 重构后的运行故障审查 · 2026-11-16

本机 2.4.1+116 用户实测出现所有来源 `timeout`，环境先检测中、后显示未安装。本文保留修复前的只读审查证据。**后续源码修复与本机补包已完成，并随本机 +117 安装，待用户复测**，现行结果见[恢复修复](rag-recovery-fix-2026-11-16.md)及[交付核验](local-2.4.1-build117-2026-11-16.md)。不能用[重构报告](tag-search-refactor-2026-11-16.md)中的历史测试结论替代此次故障核验。

## 已确认问题

### P1：退役模型字段仍被工作循环读取

`tool/rag/models.py` 已删除 `scorer`，但 `worker.py:280–295` 的 `_unload_in()` 仍访问它。配置创建的实际 Models 尚未加载 encoder 时，下一轮工作循环立即抛 `AttributeError`，停止服务所有来源；不依赖索引大小、是否损坏或 jieba 是否已安装。

隔离进程使用实际已选 Python、当前 worker 和现有模型目录（仅计算指纹、不加载权重推理），索引根明确放在审计目录。JSON 握手和 configure 均成功，紧随其后的 status 在 3 秒观察期内无响应，stderr 记录上述工作线程异常。此过程没有连接正式 RAG 宿主。

### P1：工作线程终止没有传成连接失败，重试仍使用失效宿主

异常发生在单条请求的 try 边界之外；主线程继续等待 stdin，进程与管道仍存活。隔离复现中 `poll()` 仍为 None，发 shutdown 后退出码为 0。客户端只观察进程／管道终止，普通请求超时仅取消该请求、不将连接标为关闭；控制器 `_connect()` 又复用 `!client.isClosed` 的旧对象，设置页重试／刷新走的仍是同一连接。

这是当前已复现故障的恢复缺口。修复应将工作线程致命失败传入现有断开／重连路径；正常推理或建库排队超时已有独立处理，不能用测试通过数掩盖两者区别。

### P2：环境升级失败被压成“未安装”，检测与可用状态含混

已选 AppData 和相邻 user-data 管理路径均实际存在；后续确认 AppData 父目录通过 Junction 指向当前 user-data，二者实际为同一环境。审查时 Python 3.12.11、Torch／TorchVision CUDA、Transformers、Sentence Transformers、usearch、NumPy、Pillow 和 setuptools 均符合当前固定版本，**仅缺 `jieba==0.42.1`**。

新增依赖已写进安装器和重构说明，更新依赖这件事并非完全没有安排；遗漏在运行时承接：probe 把解释器不存在、缺依赖、版本不匹配、导入失败及检测超时都压成 `ready=false`，UI 随后统一显示“还没有安装”，没有提示本机实际需要补哪个依赖。检测期间还可沿用此前 configure 的 runtimeReady，形成“就绪／检测中／未安装”的切换。

### 验证缺口：已通过的测试没有覆盖实际运行契约

- `test_startup.py` 直接调用 `Worker.execute('configure')`，没有继续执行下一轮工作队列。
- `test_lifecycle.py:131` 的替身仍手工附加 `scorer=None`；`test_device.py` 也保留旧字段，掩盖真实 Models 的结构变化。
- `test_protocol_output.py` 将 `instance.run` 替换为打印函数，没有执行真实业务循环。
- 重构报告中的三项 Windows 宿主检查只验证参数转义和子进程回收，不代表“真实 worker 启动→配置→状态／查询→关闭”联通。

修复验收应直接覆盖真实 Models 结构、配置后继续处理请求、空闲卸载后的后续请求、致命失败后的明确断开与重连，以及旧环境缺新增依赖时的展示。使用隔离来源／索引，不以重复函数单测代替进程链验证。

## 索引与审查边界

- 当前共享池只读查询：旧 `tags` 638,857 条，`blocks` 726 条；二者的原建库同意及完成元数据仍在。新 `tag-views-v1` 没有向量；池中未查到 Wiki／图库向量。不是所有来源都有已经完成的向量可恢复。
- 主池 SQLite、ANN 及 ANN 元数据文件在本次检查前后大小和修改时间一致。没有做全库完整性校验，也没有把“文件仍在”宣称为完整性已验收。
- 新标签表示需要单独明确建立集合；Wiki、提示词块和图库的表示与模型指纹未因去掉 Qwen 改变。本次故障没有要求删除旧集合的依据。
- 本轮没有查到第二处生产 RAG `scorer` 引用或仍然实际调用 Qwen 的分支。候选一致性查询能使用已有 `pool_owner` 表达式索引，不将其误报为整库扫描。未重新声称百万级正式新标签库性能已通过。

证据：`.dart_tool/rag-recovery-audit-20261116/audit.py`、`findings.json`、`worker-stderr.log`。审计脚本启动的 worker 仅向同目录 `isolated-index/` 写入；对正式池使用 SQLite `mode=ro` 和 `query_only`。
