> [← 返回首页](../../../README.md) · [教程目录](README.md)

# 快速上手

## 1. 安装

到 [Releases](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/latest) 下载：

- **安装版** `WOF_NAI_Studio_Windows_<版本>_Setup.exe`：双击安装，默认装到 `%LOCALAPPDATA%\Programs\W.O.F NAI Studio`，不需要管理员权限。
- **便携版** `WOF_NAI_Studio_Windows_<版本>_Portable.zip`：解压到任意文件夹，运行里面的 `nai_launcher.exe`。

系统要求：Windows 10 或 11（64 位）。

> 安装包暂未签名。Windows 弹出“已保护你的电脑”时，点“更多信息 → 仍要运行”。担心文件被篡改的话，可以对照 Release 页面附带的 SHA-256 校验值。

## 2. 登录

- **API Token（推荐）**：在 NovelAI 网站的账户设置里生成一个以 `pst-` 开头的 Persistent Token，粘贴进来即可。
- **账号密码**：和官网一样。
- **游客模式**：登录页可以跳过登录，先体验画廊、积木、标签百科这些本地功能；生成图片需要登录。

Token 和密码保存在 Windows 的系统安全存储中，只在本机使用。

## 3. 第一次生成

<img src="../../images/readme/zh/hero.webp" alt="生图页" width="100%">

1. 左侧上方选模型（推荐 V4.5 或 V5）。
2. 在提示词框里写英文标签，例如：
   ```
   1girl, solo, silver hair, starry sky, glowing flowers, night, cinematic lighting, very aesthetic, masterpiece
   ```
3. 下面设置尺寸、张数和步数；生成按钮上会实时显示这次要花多少 Anlas。
4. 按 `Ctrl+Enter` 或点生成。生成途中按 `Esc` 取消。

结果会出现在中间的画布上，右侧是历史记录。画布怎么操作见 [无限画布](canvas.md)。

## 4. 几个马上就能用的技巧

- **调权重**：选中一段提示词，按住 `Alt` 滚动滚轮。
- **存积木**：选中一段提示词，右键“存为块”，以后从块库点一下就能插回来。详见 [积木](blocks.md)。
- **拖图进来**：把一张图拖进窗口，可以选择图生图、风格迁移、精准参考，或者只读取它的提示词和参数。
- **快捷键**：`F1` 查看全部快捷键；`Ctrl+1/2/3` 在生图、本地画廊、在线画廊之间切换，`Ctrl+,` 打开设置。
- **防止误花 Anlas**：在设置里打开“Anlas 高消耗警告”，单次预计消耗超过设定值时会先问你。

## 5. 数据在哪里

| 位置 | 内容 |
| --- | --- |
| 程序目录下的 `user-data/` | 设置、图库数据库、缓存、积木库等 |
| 程序目录下的 `agent-data/` | NAI Agent 的工作区、聊天记录和技能 |
| 你设置的图库文件夹 | 生成的图片本身 |

备份时把 `user-data/`、`agent-data/` 和图库文件夹一起复制即可。升级和卸载都不会删除这两个数据目录。

## 下一步

- 把常用提示词整理成 [积木](blocks.md)
- 用 [画风遗传](style-explore.md) 找到喜欢的画师组合
- 配一个大模型服务，打开 [翻译块](translation.md) 和 [NAI Agent](nai-agent.md)
