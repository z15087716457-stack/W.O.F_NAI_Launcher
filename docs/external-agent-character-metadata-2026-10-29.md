# 外部 Agent 生图角色元数据丢失 · 2026-10-29

丢失点已在有效源码复现：外部 Agent 经 Studio/Krita 桥接生成的原始 PNG 带有角色信息，进入 `registerExternalImage` 后被重写 `Comment`；重建调用未传 `charCaptions`／`charNegCaptions`，于是 V4/V4.5/V5 的 `char_captions` 变成空数组。当前草稿的原文也覆盖响应里的实际生效提示词，独立 `Description` 却保留原值，造成“主提示词还在，导入显示无角色”的现象。

**源码已修复，尚未编译、安装或发布。当前本机仍为 2.2.1+62。** 本轮未生成图片、调用真实模型／NAI、操作用户窗口或改写用户草稿／旧图库。

## 原因与影响范围

- 外部桥接 `_generate` 收到实际图片后，把原字节与冻结的请求参数交给 `registerExternalImage`。原实现为修正实际宽高，无条件调用 `rebuildImageBytesWithMetadata`，引入了上述覆盖。
- `registerExternalImage` 只改结果与历史，不写角色草稿；两个回归分别覆盖只进入历史和立即自动保存，修复前均得到角色 `[]`，修复后保留两名角色。图片导入恢复角色依赖这些元数据，因此错误会延续到保存和后续导入。
- 内置 Agent 的原生生成入口、普通界面生成与外部桥接不是同一调用路径；本轮按当前源码追踪定位，不把截图聊天中的其他路径判断直接当结论。

## 修复

- 新增 `ImageSaveUtils.alignEmbeddedResolution`：已有可读 NAI 元数据且尺寸正确时，返回原 PNG 对象；仅尺寸不一致时修改参数层的 width/height，保留原提示词、种子、角色正负词、坐标、参考数据、未知字段及信封结构。
- 与 `inheritSourceMetadata` 复用完整元数据写入逻辑。独立 PNG 的 Description／Software／Source 优先保留，避免带信封的 Comment 把独立头字段也改掉。
- 缺少可读 NAI 元数据时，从本次显式参数构建完整角色正负词与坐标；使用已有 `_buildCharacterCaptions`，不读取后来被用户修改的角色栏。派生图继续按原图继承元数据，缺失源元数据时保持既有工具边界。
- 不改变已保存图片、导入选择语义、生成参数和付费授权流程。

## 验证

- 修复前，两种真实登记／保存路径的隔离复现均失败：输入两名角色，输出角色列表为空。单独头字段回归也验证了旧尺寸对齐逻辑会覆盖独立 Description，现已修复。
- 最终 **9 个相关套件 150 项全部通过**：图片生成 provider、保存工具、PNG roundtrip、完整元数据继承、桥接服务、导入协调、本地增强、本地与云端超分。4 个变更 Dart 文件定向 analyze 无问题。
- 覆盖已有元数据原字节不变、自动保存内容一致、缺失元数据时角色正负词／AI 或自定义坐标补齐、参数草稿不变，以及经典 Comment／params 信封（Map/String）、stealth、Unicode、独立头字段、未知字段与像素保持。WebP/JPEG 用作来源元数据夹具，对齐写入目标为 PNG。
- 最初扩充夹具的非 PNG 目标错误及信封预构建展开问题已修正，失败日志保留；最终 150 项来自独立的一次全通过相关套件运行，不称为全仓回归。
- 证据：有效源码 `.dart_tool/agent-character-metadata-20261029/` 的 before-fix.log、header-before-fix.log、regression-complete.log、analyze-final.log 和 verification.json。

旧图若已经保存了空角色字段，本次修复不会自动恢复；可恢复性需要另查保留的原始响应、Agent 本地副本或当时快照。本轮未扫描或批量修补正式图库。
