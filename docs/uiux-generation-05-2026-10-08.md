# 生图05 · 参数条交付（2026-10-08）

摘要右端改为28×28透明边框按钮，原型chevU路径18px、半周旋转（0→0.5），沿用抽屉220ms动画。按钮外36px点击区，视觉按钮距右缘8px，键盘可聚焦并有悬停和“更多参数”提示。四列包进独立弹性区，避免原Flexible留下的空白把箭头推离右端；引导Flexible、采样器Expanded的分配保留。

固定种子标签“种子 · 固定”，数值前12px primary锁和4px间距；随机种子的SVG、pin/unpin、采样器分组菜单、步数/引导只读保留。标签和值采用HTML明确的HarmonyOS 11/12px、w500、1.4行高。抽屉内容、遮罩、生成按钮和探索summaryMinWidth未改。新增两个键均覆盖五语言，本地化提交仅含本任务键。

## 验证

- web_left_panel_summary_test：6项通过；实时值、种子切换、只读列、菜单与抽屉开关；新增真实host旋转0.5并在收起后卸载抽屉。
- 与test/l10n一起运行：33通过/1既有失败。失败仍是i18n_regression_test的7个未使用naiAgent键（与任务02前备份相同），无新UIUX键失败，保留其他会话工作。
- generation_summary_capture_test加上述测试：7通过；64张原字体widget实绘：随机/固定 ×开/关×352/420×四语言×浅/深，含原抽屉，rotation测量全部符合状态。
- 三路径flutter analyze：No issues found。gen-l10n成功。
- `.dart_tool/uiux-task05/comparison/index.html`：同值28/5.0/3274348526/DPM++ 2M SDE的浅/深原尺寸并排与叠加。完整截图、模型/theme和摘要边界记录在同目录原始PNG及JSON，HTML区块浏览器重新核对。

## 与 HTML 的有依据差异

任务05明确视觉按钮28px、箭头18px；Task07用浏览器重新测量，HTML ib同为28px，箭头15px。摘要高度45px，HTML45.1875px，为两套字体排版的亚像素取整差。随机、展开、其他语言和352宽度在选定A的静态HTML没有完整实例，按任务文字与原交互核验。

检查点②尚待审查与用户实机验收。未构建/安装/启动/重启/热重载Studio，未调用NovelAI。
