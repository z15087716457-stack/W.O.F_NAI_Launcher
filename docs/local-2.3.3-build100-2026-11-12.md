# 本机安装 2.3.3+100

2026-11-12：按用户「推送到桌面更新」指令交付Windows本机运行目录。未提交Git、发布GitHub或构建Mac新包；公开版本仍为2.3.3+99。未自动启动Studio。

## 本批内容

- 精准参考导入弹窗按批准样板接入，大图、图库及Agent共用，支持五语言、深浅色、键盘与短窗滚动。[实现记录](precise-reference-type-dialog-2026-11-12.md)
- 在线画廊大图56px顶栏补齐拖窗区域，操作按钮保留原交互。[组件](../lib/presentation/ui/online/online_viewer.dart)
- 普通增强按64像素对齐，1216×832的1.5倍使用1856×1280；面板、报价和上传一致。1X保持原有行为，真实NAI生成验收仍待用户验证。[修复记录](enhance-request-grid-2026-11-12.md)
- V4.5等非V5质量词标准选项统一命名为「标准」，与「无」并列，仅改显示名称。

## 构建与安装

有效源码`E:/A.I/NovelAI/.devin/wt/ui-integration`，基于`eeca563f198763085e0f593dba2bd53b60213590`及27个未提交文件。冻结2147个生产输入，与+99基线相比16个改变、0个移除；原有改动在构建与安装后哈希保持。使用登记Flutter3.47.7／Dart3.13.5，指定`--build-name=2.3.3 --build-number=100 --no-pub --no-tree-shake-icons`，Windows Release构建成功，存储身份仍为`com.example/nai_launcher`。

安装前确认Studio与捆绑进程完全退出，逐项核验+99安装基线。保留原生库、资源、Agent和RAG运行资源，仅差量替换5个文件：`CHANGELOG.md`、`package-info.json`、`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`。原始data目录完整备份及+99程序／收据回退均已核验；未执行已暂停的暂存清理。

运行目录保持`E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`；桌面快捷方式保持。安装后15553个程序文件逐项通过，用户数据目录入口、图库数据库、3个RAG索引文件元数据及历史数据联接保持。

## 验证与恢复

25个相关Flutter测试文件共460项通过、0失败、0跳过；全仓Dart分析0问题；打包入口3项Python测试通过，`git diff --check`通过。均使用既有合成数据和替身，未调用真实模型或NAI接口；应用窗口与真实导入／增强由用户启动验收。

完整证据位于`.dart_tool/local-2.3.3-build100-20261112/`，最终结果为`final-verification.json`；当前收据位于`E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。新AOT SHA-256：`1c7b1741d67a84420f3a2762fb9200bd91fba7885a0930111735d37b541e11e4`。

需要回退时，完全退出Studio后，从有效源码运行：

```powershell
python .dart_tool/local-2.3.3-build100-20261112/update.py rollback
```

该入口只恢复+99程序与收据，不改用户数据；更早回退材料继续保留。
