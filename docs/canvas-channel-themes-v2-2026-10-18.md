# 画布视觉通道 · 新增五个主题（v2）

日期：2026-10-18。分支 `devin/ui-channel-more`（工作树 `.devin/wt/ui-channel-more`），基于 `codex/uiux-integration` `df4348913`；与其他窗口并行，待合并。原型：`.devin/mockups/canvas-channel-more/`（`python serve.py` → `http://127.0.0.1:8791/`）。

## 主题

五个主题沿用深海"水母 + 深度尺"的思路：每个都有一个跟着视口走的部件，滚动就是交互。

| 主题 | 代号 | 跟着视口的部件 | 空闲微动 |
|---|---|---|---|
| 机芯 | CALIBER | 齿轮串按真实传动比随滚动啮合（角速度 ∝ 1/半径，相邻齿轮反向） | 摆轮摆动、游丝收放、擒纵轮逐格跳 |
| 地层 | STRATA | 左侧地质年代柱的指针（Ma + 纪名），右侧钻头钻到视口中心 | 钻头旋转、碎屑飞溅 |
| 地铁 | METRO | G 线列车停在视口旁，最近一站亮起 NEXT | B / R 线列车自行运行，站点脉冲 |
| 乐谱 | SCORE | 播放线停在视口中间，经过的音符与左侧波形亮起；黑胶随滚动转动 | 音符泛开、唱片转动 |
| 月相 | LUNA | 当天月相格高亮（名称 + 照明度），右侧大月亮的盈亏随滚动变化 | 星点闪烁、偶尔流星 |

## 改动

- `ChannelTheme` 增加 5 项，并加入 `allThemes`；配色在 `channel_palette.dart`，绘制在 `channel_themes_d.dart`（机芯 / 地层 / 地铁）和 `channel_themes_e.dart`（乐谱 / 月相）。
- 显示设置弹层改为 4 列 11 张卡（宽度仍为 316），名称 11px。设置页主题卡是 `Wrap` 布局，会自动排入新卡。
- 存储版本 1 → 2：读取 v1 的随机池时自动并入新主题，避免老用户永远看不到新主题；v2 按保存值原样恢复。
- 文案：简中 / 英 / 日 / 韩手写，繁中由 `tool/l10n` 生成。

## 验证

- `flutter analyze` 无问题；通道组件、provider 和 l10n 测试通过；新增 v1→v2 随机池迁移测试。
- 原 24 张通道 PNG 未重录。为了让原图仍可用于比较：测试的默认随机池固定为原六个主题（`channelLegacyThemes`），原弹层图只排除弹层区域。`test/presentation/ui`、通道接线、provider 和 l10n 的失败列表与干净 `df4348913` 逐项一致：24 张通道图在左上 (149,4)–(226,32) 有 929/918 像素的旧差异，另有设置页 3 张旧失败。
- 新基准位于 `goldens/v2/`，共 16 张：5 个主题的浅色和深色、11 个主题随机、全局地图、弹层浅色 / 深色 / 固定。`flutter_test_config.dart` 只开放 `goldens/v2/` 录制，原 PNG 仍锁定。
- DeepSeek V4.1 Flash 按书面规范移植了 `channel_themes_e.dart`，已逐行审阅；它与原型的差异只有两处：唱臂旋转去掉了恒为 0 的项，绝对线宽按装饰单位换算。

## 合并注意

- 改动集中在 `ui/channel/`、四份 ARB、生成的 l10n 文件和 `canvas_channel_provider.dart`。合并时如果 ARB 冲突，在 `channel_descWave` 后面追加 10 个新键，然后重跑繁中生成和 `gen-l10n`。
- 未安装、未启动程序、未生图。
