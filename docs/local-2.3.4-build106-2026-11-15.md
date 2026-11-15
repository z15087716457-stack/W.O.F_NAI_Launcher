# 本机更新 2.3.4+106

2026-11-15，按用户要求将逐逗号轻量翻译构建并安装到桌面，从2.3.4+105更新至**2.3.4+106**。原运行目录和快捷方式保持，未自动启动Studio，交由用户实测；未提交／推送Git或发布公开包。

## 本次交付

- [逐逗号轻量翻译](comma-translation-2026-11-15.md)：按逗号逐项翻译，译文去掉权重语法、与上方原文起点对齐，只读显示；删除原文段会移除对应译文。
- 点击原文进入同一个原生输入框，失焦恢复双行阅读；编辑器恢复原生行高、光标、选区和输入法。原文、生成投影、既有块翻译及块操作保持，拖入按可见原文定位。
- 旧整段译文会显示待更新，需通过原翻译入口重译一次。模型、术语表、请求／校验链共用；保留+105的全窗口居中拖入提示及此前累计功能。

## 构建、安装与核验

有效源码为`E:/A.I/NovelAI/.devin/wt/ui-integration`，基于`5cb759b3d5349de6305847f93e9b361c78ed1950`及累计未提交改动。冻结2,170个生产输入，相对+105改变22项（含10个业务Dart、五种ARB、五个国际化Dart、CHANGELOG和版本），无生产输入退役；303项既有工作区文件改动及11项删除状态保持。

登记Flutter3.47.7／Dart3.13.5，Release使用`--no-pub --no-tree-shake-icons --build-name=2.3.4 --build-number=106`构建成功，构建命令约92.58秒。EXE ProductVersion为2.3.4+106，FilePrivatePart为106，存储身份保持`com.example/nai_launcher`。CMake CMP0175开发警告保留，未阻止构建。

差量替换5项：`data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`app_files_manifest.json`、`package-info.json`。15,557个登记程序文件逐项核对，无新增／退役。原生库代码、依赖表、全部资源、15,280项Agent文件及RAG模块保持，沿用原生Glass包。

AOT SHA-256：`4dee3a28780bbfb6c6bf21d04196eec2bfb89a81bf4be15e1fd40c8bf151e5b9`。

- 复用本功能源码完成时的424项相关回归、133项生成接线、六项生产组件实绘及全仓分析0问题；构建前后冻结源码哈希保持。补测的非零窗口偏移拖入定位通过。视觉度量与边界见专项报告，未将组件实绘写成用户窗口验收。
- 本批安装器4项隔离检查通过，覆盖失败恢复、安装后回退及私有状态保护；真实+105完整回退备份已校验，未在真实桌面降级演练。未变的Agent、RAG、原生库、组包器和居中拖入模块复用+105验证。
- 安装约37.62秒；14项关键用户文件状态、用户数据入口、图库、当前3个索引文件和快捷方式保持。没有移动素材、修改草稿、重建索引或请求真实模型／NAI。

本批证据在`.dart_tool/local-2.3.4-build106-20261115/`：`final-verification.json`、`package-verification.json`、`user-data-preservation.json`、`documentation-verification.json`、冻结输入、构建／安装日志及`rollback/`。文档在安装后更新，编译输入和其他源码复验保持，原编译收据另存。

## 回退

完全退出Studio及托盘后，从有效源码执行，恢复本次更新前的**2.3.4+105**程序与收据：

```powershell
python .dart_tool/local-2.3.4-build106-20261115/update.py rollback
```

当前收据为`E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批及更早回退、已暂停清理的暂存材料均保留；公开发布登记仍为2.3.4+102。翻译实际质量和桌面交互由用户实测。
