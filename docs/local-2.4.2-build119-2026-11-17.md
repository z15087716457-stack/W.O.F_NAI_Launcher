# 本机2.4.2+119交付核验

2026-11-17按用户「推送到桌面更新」指令，将[输入法重复输入与自动补译菜单修复](ime-and-auto-translation-menu-2026-11-17.md)安装至原桌面运行目录。**已安装2.4.2+119，未自动启动，待真实输入法复测。** 公开版仍为2.4.1+115，本次未提交或发布GitHub。

## 更新内容

- 输入法有效组合区期间保留原生显示缓冲、选区和方向，选字确认后刷新译文排版，避免Windows组词被框架回写重置；覆盖译文片段开头／中间／末尾，以及补译响应在组词期间完成。
- 自动补译等待有效空组合区结束；点击开关保持菜单，在原位置连续开关并即时更新勾选。Esc、点击外部和普通菜单操作正常收起。
- +118交付的六批更新继续保留。RAG资源、Agent、原生DLL和依赖均未变化，复用原验证；本批没有清理或重建索引。

## 构建与安装

| 项目 | 结果 |
|---|---|
| 有效源码 | `.devin/wt/ui-integration`，HEAD `517163c5455ac765158016aa9204f4a5bca57da0` 加未提交改动 |
| 输入 | 冻结2,018项，相对+118仅4个Dart文件、版本和CHANGELOG共6项输入改变；无新增／退役输入 |
| SDK | Flutter3.47.7／Dart3.13.5；Windows Release，`--no-pub --no-tree-shake-icons` |
| 实际运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本 | EXE ProductVersion `2.4.2+119`、FilePrivatePart119；包信息与程序清单一致 |
| 程序 | 15,561项核验，差量交付5项，新增0项、退役0项 |
| 原生与资源 | DLL代码、依赖和Flutter资源保持，Agent完整清单一致；Pi1.5.0 |
| 用户数据 | 44项关键文件哈希、图库／扫描状态、3项索引文件状态、AppData入口与桌面快捷方式保持 |
| 回退 | +118完整data、被替换文件和旧收据备份核验通过；未实际降级 |

AOT SHA-256：`88756acacf63f1cfa1bf4fcd785eee3e028f6523da8cd0580b40cc6bab6da2bd`。构建约93秒，安装约36秒。保留原Glass原生组件，没有整目录覆盖运行包。

## 验证与恢复

复用当前源码已通过的1,033项相关Flutter回归、真实Flutter C++输入模型和全仓分析0问题；交付另跑4项隔离安装／移除失败恢复／替换失败恢复及回退保护检查，全部通过。版本、程序／源文件哈希和数据保持均已核验；本批未请求真实模型或NAI，未操作用户草稿或自动启动应用。

材料位于`.dart_tool/local-2.4.2-build119-20261117/`；当前收据为`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。只读核对回退：`python .dart_tool/local-2.4.2-build119-20261117/update.py verify-backup`；实际恢复+118使用同脚本`rollback`，须从托盘完全退出Studio。+118清理旧索引的独立备份和其他历史回退继续保留。
