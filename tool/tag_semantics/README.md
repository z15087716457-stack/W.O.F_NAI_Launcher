# 中文标签语义补充数据

固定来源为 SuzumiyaAkizuki/DanbooruSearchOnline 的 `origin_database/tags_enhanced.csv`，提交、URL、GBK 编码、原始字节数、SHA-256 及 GPL-3.0 许可见 `source_lock.json`。`sources/tags_enhanced.csv` 保留上游原始字节，完整许可随包保存在 `assets/licenses/DanbooruSearchOnline-GPL-3.0.txt`。没有导入上游搜索实现。

此数据独立于完整英文 Wiki、现行翻译缓存和标签主库：

- `synonyms_zh`：从 `cn_name` 解析的中文同义词 JSON 数组。
- `core_zh`：首个非空中文同义词，按上游规则派生；不是 CSV 的额外原始字段。
- `summary_zh`：上游 `wiki` 的简短说明，不能冒充完整 Wiki 文章或逐篇核验的人工翻译。
- 类别、热度、敏感标记均为上游快照信息，不覆盖当前词库的类别和计数。
- 每条保留 CSV 记录号与内容摘要；数据库 metadata 记录原始版本、哈希、许可与清洗统计。

原始 53863 行中，重复且内容不同的 `7月22日` 两行及含空格的 `22/7 音乐的时间` 一行进入 `source_issues`，保留全部原始字段，等待确认 canonical 标签，不自动猜测改名。得到 53860 个资料条目；其中 1 个仅有同义词、缺少简释义，继续留空。

2026-11-14 按用户要求保留上述全部底座行，加入 `sources/additions_2026-10-30.csv` 的 547 个新条目，总计 54407 条。增补来自上游 10 月 30 日固定提交，只提取此前没有的名字；完整原料摘要与增补文件摘要分别登记在 `source_lock.json`。已有中文内容、类别、热度及来源行不被新版覆盖，上游改写的 3 个旧条目继续保留本地原文。构建器支持可追溯的只增不覆增补，数据版本同时包含底座与增补摘要。

运行标准库构建器：

```bash
PYTHONIOENCODING=utf-8 python tool/tag_semantics/build_profiles.py
python -m unittest discover -s tool/tag_semantics -p 'test_*.py' -v
```

构建前验证原始字节和预期数量；在独立临时文件中建库、完整性校验后发布 `assets/databases/tag_semantics.db`，更新资源 manifest。构建不联网，不调用模型，不打开用户数据库或向量索引。新资源通过现有资源安装器按需校验／安装，`TagSemanticsRepository.find/findAll` 提供精确标签只读访问。

现行中文名称检索及语义补充已消费这些资料，个人补充另存 `tag_semantics/supplements.db`。没有覆盖的标签返回缺失，不能将本资料条数当成主标签库条数或完整中文覆盖；资料更新不自动重建向量。
