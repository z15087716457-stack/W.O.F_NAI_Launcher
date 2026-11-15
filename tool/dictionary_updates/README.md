# 固定 Tag／Wiki 补充快照

`source_lock.json` 记录原始上游、原料摘要和可直接供现有导入器读取的文件摘要。源文件是公开数据，不含用户词条、翻译、个人资料或索引；不随 Flutter 应用打包。

- Tag：DraconicDragon 月度工作流 41648330147、附件 13236079143 中的 `danbooru_2026-11-03_pt20-ia-dd.csv`，原始 CSV 字节不变。原料归属及 Unlicense 沿 [上游仓库](https://github.com/DraconicDragon/dbr-e621-lists-archive) 保留。
- Wiki：[dartags/danbooru-wiki-2609](https://huggingface.co/datasets/dartags/danbooru-wiki-2609)，固定 `fcf861cf9c75954f4fba9d7c254724c3d9051a1c` 的 Parquet。按 id 排序，逐条保留 title、body、updated_at、is_deleted 转为 UTF-8 JSONL，不改正文；导入时才沿现有规则过滤空正文、删除记录和无效标题。原站为 Danbooru，每篇数据库记录保留原文 URL；数据集未另标许可，不能将格式转换视为取得新的授权。

Tag 保留既有标签、类别及别名；Wiki 保留不在候选中的文章和帮助页，同名正文沿既有刷新规则。中文语义底座和个人补充不在此工具的修改范围。

登记 SDK 下从源码根目录显式维护：

```text
dart run tool/dictionary_updates/import.dart <user-data> <隔离工作目录> stage
dart run tool/dictionary_updates/import.dart <user-data> <同一工作目录> publish
```

先备份活动版本及个人资料，完全退出 Studio。`stage` 验证输入大小／SHA-256，在副本上调用原有导入器，生成候选库和 plan；核验后 `publish` 重新比对活动基线及候选摘要，再调用原有不可变提交机制。失败不替换活动库。不联网、不启动应用、不调用模型、不自动同步 RAG。

应用默认源登记为项目仓库中按日期命名的固定快照，内容以 SHA-256 锁定；Wiki JSONL 由 Git LFS 管理，下载用 media 地址，避免取得指针文本。检查器保留现有上游发现能力，但较旧的季度／六月结果不覆盖已登记的新快照；缓存仅接受完全匹配内置摘要的项目镜像，其他来源继续要求原有不可变修订。公开下载需先将快照随 Git 发布，本次本机更新直接使用已验证的本地源文件。
