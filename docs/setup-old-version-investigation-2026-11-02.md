# Setup 更新后仍显示旧版本 · 调查

当前结论：写入失败误报与更新绿标误报已完成源码修复，尚未安装或重新发布 Setup；见 [三项修复与验证](import-update-fixes-2026-11-02.md)。以下保留调查阶段证据。

跨目录实例阻断也已完成源码修复，尚未安装；见 [按目录隔离与原生验证](native-instance-scope-2026-11-02.md)。

日期：2026-11-02。用户反馈下载 2.2.4 Setup 并重启后，关于页仍显示 `2.2.1 · build 61`，同时显示绿色“已是最新版本”。用户要求自行检查，不再等对方提供路径。本轮完成隔离安装／原生进程验证；未修改产品代码或当前安装，未启动真实 Studio。

## 已确认

1. **正式包里的主程序版本正确。** 当日经 GitHub API 核对，latest 仍为 [v2.2.4](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.2.4)。远端 Setup 摘要与本地正式包一致：`f278c65a49ae7e14bfdf19301a4132e52e0e59bdefc47ccbc685395a8075835e`。重新从该 Setup 单独解出 `nai_launcher.exe`，其 ProductVersion、FileVersion 均为 `2.2.4+75`，EXE SHA-256 为 `86d650c418afd34e22846f1f5827ffce24a56f1b9925f417484c4e9b4fb5c1c0`。未运行该正式分发安装器；上次完整载荷核验见 [发布报告](release-2.2.4-2026-10-31.md)。尚未拿到反馈用户实际下载的包。
2. **版本显示读取 EXE，不是用户设置里的旧缓存。** `AppVersion.initialize()` 调用 `PackageInfo.fromPlatform()`；本项目使用的 `package_info_plus 8.3.1` Windows 实现从 `Platform.resolvedExecutable` 的 ProductVersion 读取版本与构建号，再在当前进程内缓存。因此截图说明初始化时读到的程序版本仍为 `2.2.1+61`；仅凭截图还不能区分旧目录、旧进程或混合文件。
3. **绿色“已是最新版本”存在误报。** `settingsAboutData()` 把 `UpdateStatus.idle` 默认映射成 `SettingsUpdateState.upToDate`；关于页将它绘制成绿色“已是最新版本”。尚未检查、后台失败，以及自动检查跳过已忽略版本后都可能回到 idle。`checkedAt` 独立读取上一次成功时间，不证明本次检查成功。隔离测试已复现“合成网络失败 → idle → 绿色最新版”，不是只依据静态推断。此映射在 `v2.2.1` 与当前源码中一致。
4. **版本比较和更新源未发现这一差异。** `v2.2.1` 与当前均指向 `z15087716457-stack/W.O.F_NAI_Launcher`；比较器正确判断 `2.2.4 > 2.2.1`（含构建号也正确）。

## 自检确认的安装缺陷

**目标 EXE 被文件句柄占用时，Setup 可以返回成功，留下新旧混合载荷。** 使用原样产品 NSIS 脚本，仅把应用名、EXE、注册键、安装路径及小型载荷替换成独立夹具，重现：

- 旧 EXE 资源版本为 `2.2.1+61`，新载荷为 `2.2.4+75`；旧 EXE 没有运行，只被测试文件句柄以禁止写入的共享方式持有。
- 原安装器静默退出码为 **0**；EXE 仍是 **2.2.1+61**，`data/app.so` 的新载荷标记已写入，注册 DisplayVersion 却更新为 **2.2.4**。
- `EnsureAppClosed` 正常枚举不到目标进程时直接放行；文件锁探测只用于进程检查失败分支。`File /r` 后又没有检查写入错误，继续执行成功登记。这是可重现缺陷，足以解释“装完但版本没变”，但未断言就是反馈用户的原机原因。

**目录继承的正常路径通过验证。** 已登记的中文／空格自定义路径、显式 `/D=` 覆盖、旧产品注册目录，都正确安装为 2.2.4+75；目标目录旧进程运行时会被正常结束并覆盖，用户数据哨兵保留。

## 原生启动结论更正

此前初查遗漏了 `IsLauncherWindow()` 末尾的 EXE 路径比较，“新版会唤起另一目录旧版”的说法不准确，现已更正。

实际行为为：正常模式的互斥锁跨目录共享，但窗口查找要求 EXE 路径一致。另一目录旧版运行时，新进程能遇到共享锁，却找不到同路径窗口，等待后提示“already starting”并退出；不会唤起那个旧窗口。同路径重启才能正常发唤醒消息。

隔离夹具直接编译产品 `main.cpp` 的窗口识别／唤醒函数与 `studio_sandbox.h`，使用独立 sandbox 身份、真实 Windows 互斥锁、隐藏窗口和消息收发；只替换显示窗口／抢前台 API，避免干扰桌面。不同目录得到 `mutexExists=true, matchingWindow=false, woke=false`，同路径对照三项均为 true。未启动完整 Flutter／Studio 或运行旧安装版。

## 最小处理方向

- 更新状态继续归现有 provider：区分未检查、检查失败、忽略更新和成功确认最新；后台保持安静，关于页显示真实状态，复用现有通知控制，不另建检查系统。
- 安装部分在原文件写入边界检查错误，失败时停止并返回非零退出码，避免继续登记成功；不另建安装系统。已在 NSIS 副本加入 `ClearErrors` 与写入后的 `IfErrors → SetErrorLevel 4 / Quit`：同一占用场景返回 4、登记仍保留旧版；释放锁后重试返回 0，EXE 为 2.2.4+75。副本保存在审计目录，**尚未应用到产品源码**。该验证覆盖失败可见与重试，不是整包事务回滚。
- 跨目录单实例是独立行为，未据此改实例身份或强制结束其他目录程序。版本来源、同路径更新及文件写入结果已能在本机自检，无需继续要求反馈用户提供路径。

## 验证与范围

材料位于 `.dart_tool/setup-version-investigation-20261102/`。

- 5 项隔离探针：未检查的映射、明确失败的映射、EXE 版本投影与比较器、后台失败后的真实 provider→设置投影、自动返回空结果的投影。
- 15 项既有更新生命周期／检查服务回归通过；共 **20 项不同检查**。首轮日志包含其中 3 项探针，未重复计数。
- 探针增加日志隔离时曾错误 await 返回 void 的测试 helper，编译失败；去掉这一 await 后 5 项通过，首次编译日志保留。未改产品代码解决夹具问题。
- 另完成 **9 个安装／原生进程场景**，日志 `selfcheck-run6.log`、结果 `selfcheck/verification.json`，最小候选修正见 `selfcheck/candidate.nsi`。场景覆盖目录继承、显式目标、旧注册、跨／同目录实例、同目录运行中升级、EXE 占用误报、副本阻断及解除占用后重试。
- 夹具准备阶段修正 Python 字符串／RC 转义、NSIS `/D=` 无引号尾参、与产品一致的 Unicode 编译标志；初始失败日志保留，未计入通过。新旧资源版号来自小型 EXE 的真实版本资源，AOT 使用标记文件，不代表完整 Flutter 安装验收。
- 所有夹具进程已结束、专用测试注册键已移除。真实安装注册键、当前 EXE／AOT／包信息／直装收据和所查生产源码前后哈希保持；未执行正式分发 Setup，桌面仍为此前登记的 +77。

主要源码：`lib/presentation/wiring/settings/settings_system.dart`、`lib/presentation/ui/settings/settings_system.dart`、`lib/presentation/providers/update_provider.dart`、`lib/core/constants/app_version.dart`、`installer/windows/nai_launcher.nsi`、`windows/runner/main.cpp`。
