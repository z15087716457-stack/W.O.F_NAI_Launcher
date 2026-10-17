# 中文标签语义补充数据

固定来源为 SuzumiyaAkizuki/DanbooruSearchOnline 的 `origin_database/tags_enhanced.csv`，提交、URL、GBK 编码、原始字节数、SHA-256 及 GPL-3.0 许可见 `source_lock.json`。`sources/tags_enhanced.csv` 保留上游原始字节，完整许可随包保存在 `assets/licenses/DanbooruSearchOnline-GPL-3.0.txt`。没有导入上游搜索实现。

此数据独立于完整英文 Wiki、现行翻译缓存和标签主库：

- `synonyms_zh`：从 `cn_name` 解析的中文同义词 JSON 数组。
- `core_zh`：首个非空中文同义词，按上游规则派生；不是 CSV 的额外原始字段。
- `summary_zh`：上游 `wiki` 的简短说明，不能冒充完整 Wiki 文章或逐篇核验的人工翻译。
- 类别、热度、敏感标记均为上游快照信息，不覆盖当前词库的类别和计数。
- 每条保留 CSV 记录号与内容摘要；数据库 metadata 记录原始版本、哈希、许可与清洗统计。

原始 53863 行中，重复且内容不同的 `7月22日` 两行及含空格的 `22/7 音乐的时间` 一行进入 `source_issues`，保留全部原始字段，等待确认 canonical 标签，不自动猜测改名。得到 53860 个资料条目；其中 1 个仅有同义词、缺少简释义，继续留空。

运行标准库构建器：

```bash
PYTHONIOENCODING=utf-8 python tool/tag_semantics/build_profiles.py
python -m unittest discover -s tool/tag_semantics -p 'test_*.py' -v
```

构建前验证原始字节和预期数量；在独立临时文件中建库、完整性校验后发布 `assets/databases/tag_semantics.db`，更新资源 manifest。构建不联网，不调用模型，不打开用户数据库或向量索引。新资源通过现有资源安装器按需校验／安装，`TagSemanticsRepository.find/findAll` 提供精确标签只读访问。

本批只补齐这份现成语义资料和读取入口，尚未接入当前弹窗查询、重建标签向量或实施检索重构。没有覆盖的标签返回缺失，后续须继续补数据；不得宣称整个 64 万词库已有中文语义覆盖。
