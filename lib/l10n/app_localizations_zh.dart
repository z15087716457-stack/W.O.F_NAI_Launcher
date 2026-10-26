// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => 'W.O.F NAI Studio';

  @override
  String get settings_visualAssets => '界面字体与许可';

  @override
  String get brand_entryTagline => '给想象，一个发生的地方。';

  @override
  String get brand_switchToLight => '切换到浅色';

  @override
  String get brand_switchToDark => '切换到深色';

  @override
  String get app_subtitle => 'NovelAI 第三方客户端';

  @override
  String get common_cancel => '取消';

  @override
  String get common_confirm => '确定';

  @override
  String get common_continue => '继续';

  @override
  String get common_selectAll => '全选';

  @override
  String get common_deselectAll => '全不选';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_edit => '编辑';

  @override
  String get common_close => '关闭';

  @override
  String get common_clear => '清除';

  @override
  String get common_copy => '复制';

  @override
  String get common_copied => '已复制';

  @override
  String get common_export => '导出';

  @override
  String get common_import => '导入';

  @override
  String get common_loading => '加载中...';

  @override
  String get common_error => '错误';

  @override
  String get common_success => '成功';

  @override
  String get common_retry => '重试';

  @override
  String get common_select => '选择';

  @override
  String get common_reset => '重置';

  @override
  String get common_add => '添加';

  @override
  String get common_added => '已添加';

  @override
  String get common_confirmDelete => '确认删除';

  @override
  String get common_confirmClear => '确认清空';

  @override
  String get common_gotIt => '知道了';

  @override
  String common_deleteItemConfirm(Object itemName) {
    return '确定要删除「$itemName」吗？此操作不可撤销。';
  }

  @override
  String common_clearAllItemsConfirm(Object count, Object itemType) {
    return '确定要清空所有 $count 个$itemType吗？此操作不可撤销。';
  }

  @override
  String get common_clearInputConfirm => '确定要清空输入内容吗？';

  @override
  String common_daysAgo(Object days) {
    return '$days天前';
  }

  @override
  String get common_undo => '撤销';

  @override
  String get common_redo => '重做';

  @override
  String get common_refresh => '刷新';

  @override
  String get common_download => '下载';

  @override
  String get common_apply => '应用';

  @override
  String get common_favorite => '收藏';

  @override
  String get common_unfavorite => '取消收藏';

  @override
  String get common_ok => '确定';

  @override
  String get common_exit => '退出';

  @override
  String get common_grid => '网格';

  @override
  String get common_multiSelect => '多选';

  @override
  String get common_category => '分类';

  @override
  String get networkError_connectionTimeout => '连接超时，请检查网络连接。';

  @override
  String get networkError_sendTimeout => '发送超时，请重试。';

  @override
  String get networkError_receiveTimeout => '接收超时，图像生成可能需要更长时间。';

  @override
  String get networkError_requestCancelled => '请求已取消';

  @override
  String get networkError_connection => '网络连接错误，请检查网络连接。';

  @override
  String get networkError_unknown => '未知错误';

  @override
  String get networkError_noResponse => '服务器无响应';

  @override
  String get networkError_badRequest => '请求参数错误';

  @override
  String get networkError_authFailed => '认证失败，请重新登录。';

  @override
  String get networkError_insufficientAnlas => 'Anlas 不足';

  @override
  String get networkError_forbidden => '无权限访问该资源';

  @override
  String get networkError_notFound => '请求的资源不存在';

  @override
  String get networkError_conflict => '请求与当前状态冲突';

  @override
  String get networkError_rateLimited => '请求过于频繁，请稍后重试。';

  @override
  String get networkError_serverInternal => '服务器内部错误';

  @override
  String get networkError_badGateway => '服务器网关错误';

  @override
  String get networkError_unavailable => '服务暂时不可用';

  @override
  String networkError_requestFailed(int code) {
    return '请求失败（$code）';
  }

  @override
  String get auth_login => '登录';

  @override
  String get auth_logout => '退出登录';

  @override
  String get auth_email => '邮箱';

  @override
  String get auth_password => '密码';

  @override
  String get auth_loginButton => '登录';

  @override
  String get auth_loginFailed => '登录失败';

  @override
  String get auth_guestEntry => '跳过登录，以游客身份进入';

  @override
  String get auth_recommended => '推荐';

  @override
  String get auth_getToken => '获取 Token';

  @override
  String get auth_localOnlyNote => '账号与 Token 仅保存在本机';

  @override
  String get auth_back => '返回';

  @override
  String get auth_toggleVisibility => '显示 / 隐藏';

  @override
  String get auth_emailRequired => '请输入邮箱';

  @override
  String get auth_emailInvalid => '请输入有效的邮箱地址';

  @override
  String get auth_passwordRequired => '请输入密码';

  @override
  String get auth_tokenLoginRecommended => 'API Token 登录（推荐）';

  @override
  String get auth_credentialsLogin => '邮箱密码登录';

  @override
  String get auth_credentialsLoginUnavailable => '账号密码登录当前不可用，请使用 Token 登录';

  @override
  String get auth_tokenRequired => '请输入 Token';

  @override
  String get auth_tokenInvalid => 'Token 格式无效，应以 pst- 开头';

  @override
  String get auth_nicknameHint => '为此账号设置一个便于识别的名称';

  @override
  String get auth_thirdPartyLogin => '第三方站点';

  @override
  String get auth_thirdPartyApiSite => '第三方 API 站点';

  @override
  String get auth_imageApiSiteOptional => '图像 API 站点（可选）';

  @override
  String get auth_imageApiSiteHint => '留空则使用同一个第三方 API 站点';

  @override
  String get auth_thirdPartyNicknameHint => '例如：自建站点 / 镜像站点';

  @override
  String get auth_thirdPartyTokenHint => '请输入第三方站点提供的 API Token';

  @override
  String get auth_thirdPartyCompatibilityHint =>
      '第三方站点需兼容 NovelAI 的 /user/subscription 与图像生成相关 API；Token 将按 Bearer 方式发送。';

  @override
  String get auth_thirdPartyApiSiteRequired => '请输入第三方 API 站点地址';

  @override
  String get auth_validateAndLogin => '验证并登录';

  @override
  String get auth_tokenGuide => '从 NovelAI 账户设置获取 Token';

  @override
  String get auth_addAccount => '添加账号';

  @override
  String get auth_tokenNotFound => '未找到此账号的 Token';

  @override
  String get auth_switchAccount => '切换账号';

  @override
  String get auth_selectAccount => '选择账号';

  @override
  String get auth_deleteAccount => '删除账号';

  @override
  String auth_deleteAccountConfirm(Object name) {
    return '确定要删除账号 \"$name\" 吗？此操作不可撤销。';
  }

  @override
  String auth_deleteCurrentAccountConfirm(Object name) {
    return '将删除账号 \"$name\" 并退出登录，确定继续吗？';
  }

  @override
  String get auth_switchFailedDeletePrompt => '无法登录该账号（可能已失效）。是否从列表中删除？';

  @override
  String get auth_switchFailedDeletePromptMissingToken =>
      '未找到此账号的登录凭据（可能已失效）。是否从列表中删除？';

  @override
  String get auth_removeAvatar => '移除头像';

  @override
  String get auth_quickLogin => '一键登录';

  @override
  String get auth_nicknameRequired => '请输入昵称';

  @override
  String get auth_error_networkTimeout => '连接超时，请检查网络';

  @override
  String get auth_error_networkError => '网络连接错误';

  @override
  String get auth_error_authFailed => '认证失败';

  @override
  String get auth_error_credentialsLoginUnavailable => '账号密码登录当前不可用';

  @override
  String get auth_error_credentialsLoginUnavailable_hint =>
      'NovelAI 官网账号密码登录需要网页安全验证，客户端无法完成，请改用 Persistent API Token。';

  @override
  String get auth_error_serverError => '服务器错误';

  @override
  String get auth_error_unknown => '未知错误';

  @override
  String get auth_autoLogin => '自动登录';

  @override
  String get auth_forgotPassword => '忘记密码？';

  @override
  String get auth_passwordTooShort => '密码长度至少6位';

  @override
  String get auth_loggingIn => '登录中...';

  @override
  String get auth_viewTroubleshootingTips => '查看故障排除提示';

  @override
  String get auth_troubleshoot_checkConnection_title => '检查网络连接';

  @override
  String get auth_troubleshoot_checkConnection_desc => '确保您的设备已连接到互联网';

  @override
  String get auth_troubleshoot_retry_title => '重试';

  @override
  String get auth_troubleshoot_retry_desc => '网络问题可能是暂时的，请重试';

  @override
  String get auth_troubleshoot_proxy_title => '检查代理设置';

  @override
  String get auth_troubleshoot_proxy_desc => '如果使用代理，请确认配置正确';

  @override
  String get auth_troubleshoot_firewall_title => '检查防火墙设置';

  @override
  String get auth_troubleshoot_firewall_desc => '确保防火墙允许连接到 NovelAI 服务器';

  @override
  String get auth_troubleshoot_serverStatus_title => '检查服务器状态';

  @override
  String get auth_troubleshoot_serverStatus_desc =>
      '访问 NovelAI 状态页面或社区查看服务中断情况';

  @override
  String get common_paste => '粘贴';

  @override
  String get common_default => '默认';

  @override
  String get settings_title => '设置';

  @override
  String get settings_savedAccounts => '已保存账号';

  @override
  String get settings_style => '风格';

  @override
  String get settings_font => '字体';

  @override
  String get settings_language => '语言';

  @override
  String get settings_shortcuts => '快捷键';

  @override
  String get settings_generationInputSection => '输入';

  @override
  String get settings_generationFeedbackSection => '完成提醒';

  @override
  String get settings_selectFont => '选择字体';

  @override
  String get settings_selectLanguage => '选择语言';

  @override
  String settings_loadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get settings_imageSavePath => '图片保存位置';

  @override
  String get settings_autoSave => '自动保存';

  @override
  String get settings_autoSaveSubtitle => '生成后自动保存图片';

  @override
  String get settings_extraRootsTitle => '图库源管理';

  @override
  String get settings_extraRootsHint =>
      '额外图库源：可浏览可搜索，图片可移动/复制到分类；不参与自动保存。添加后会立即扫描。';

  @override
  String get settings_extraRootsEmpty => '尚未添加额外图库源';

  @override
  String get settings_extraRootsAdd => '添加文件夹';

  @override
  String get settings_extraRootsAddTitle => '选择要添加的图库源文件夹';

  @override
  String get settings_extraRootsRemove => '移除该图库源';

  @override
  String get settings_extraRootsRemoveConfirmTitle => '移除图库源？';

  @override
  String settings_extraRootsRemoveConfirmContent(String path) {
    return '将「$path」从画廊中移除（不会删除文件夹中的任何文件）。';
  }

  @override
  String get settings_extraRootsAdded => '图库源已添加并完成扫描';

  @override
  String get settings_extraRootsScanFailed => '文件夹已添加，但扫描未完成，请在画廊中重试刷新';

  @override
  String get settings_extraRootsWaitingScan => '当前图库正在扫描，完成后会继续导入此文件夹';

  @override
  String get settings_extraRootsRemoved => '图库源已移除';

  @override
  String get settings_extraRootsDuplicate => '该文件夹已在图库源中';

  @override
  String get settings_extraRootsSameAsMain => '该文件夹与图片保存位置相同';

  @override
  String get settings_extraRootsNested => '图库源之间不能互相包含，请选择其他文件夹';

  @override
  String get settings_extraRootsNotFound => '所选文件夹不存在';

  @override
  String get settings_importTagIndex => '导入标签索引…';

  @override
  String get settings_importTagIndexPickTitle => '选择标签索引文件 (.jsonl)';

  @override
  String settings_importTagIndexProgress(int processed, int total) {
    return '正在导入 $processed/$total 行…';
  }

  @override
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  ) {
    return '导入完成：新增 $imported，更新 $updated，跳过 $skipped，错误 $errors';
  }

  @override
  String get settings_importTagIndexFailed => '标签索引导入失败';

  @override
  String get settings_importTagIndexBlockedByScan => '画廊正在扫描中，请等待扫描完成后再导入标签索引';

  @override
  String get settings_extraRootsIndexImportTitle => '检测到标签索引';

  @override
  String settings_extraRootsIndexImportContent(String path) {
    return '在「$path」下检测到标签索引 index.jsonl。先导入标签索引可让之后的扫描直接快进（跳过元数据解析），是否现在导入？';
  }

  @override
  String get settings_extraRootsIndexImportConfirm => '现在导入';

  @override
  String settings_version(Object version) {
    return '版本 $version';
  }

  @override
  String get settings_openSource => '开源项目';

  @override
  String get settings_openSourceSubtitle => '查看源代码和文档';

  @override
  String get settings_fileLogging => '记录应用日志';

  @override
  String get settings_fileLoggingSubtitle =>
      '默认关闭；仅在排查问题时开启。开启后会写入 Documents/NAI_Launcher/logs，关闭后不再创建或写入日志文件。';

  @override
  String get settings_pathReset => '已重置为默认路径';

  @override
  String get settings_pathSaved => '保存路径已更新';

  @override
  String get settings_selectFolder => '选择保存文件夹';

  @override
  String get settings_vibeLibraryPath => 'Vibe库路径';

  @override
  String get settings_hiveStoragePath => '数据存储路径';

  @override
  String get settings_selectVibeLibraryFolder => '选择Vibe库文件夹';

  @override
  String get settings_selectHiveFolder => '选择数据存储文件夹';

  @override
  String get settings_pathSavedRestartRequired => '路径已更新，重启后生效';

  @override
  String get settings_accountType => '账号类型';

  @override
  String get settings_subscriptionExpiry => '订阅到期';

  @override
  String get settings_thirdPartyApiAccount => '第三方站点 API';

  @override
  String get settings_goToLogin => '去登录';

  @override
  String get settings_changeAvatar => '更换头像';

  @override
  String get settings_removeAvatar => '移除头像';

  @override
  String get settings_accountEmail => '账号邮箱';

  @override
  String get settings_emailAccount => '邮箱登录';

  @override
  String get settings_tokenAccount => 'Token登录';

  @override
  String get settings_setAsDefault => '设为默认';

  @override
  String get settings_defaultAccount => '默认';

  @override
  String get settings_nickname => '昵称';

  @override
  String get settings_nicknameUpdated => '昵称已更新';

  @override
  String get settings_avatarUpdated => '头像已更新';

  @override
  String get settings_avatarRemoved => '头像已移除';

  @override
  String get settings_setAsDefaultSuccess => '已设为默认账号';

  @override
  String generation_cooldownRemaining(Object seconds) {
    return '等待 $seconds 秒';
  }

  @override
  String get generation_generating => '生成中...';

  @override
  String get generation_cancelGeneration => '取消生成';

  @override
  String get generation_stopGeneration => '停止生成';

  @override
  String get generation_pleaseInputPrompt => '请输入提示词';

  @override
  String get generation_generationFailed => '生成失败';

  @override
  String generation_deleteSelectedImagesConfirm(int count) {
    return '将从记录中移除 $count 张图像（已保存到磁盘的文件保留）';
  }

  @override
  String generation_seedWrittenBack(int seed) {
    return '种子已写回: $seed';
  }

  @override
  String get generation_setAsReferenceImage => '已设为参考图';

  @override
  String get generation_canvasDisplaySettings => '画布显示';

  @override
  String get generation_canvasZoomToFill => '放大填充（允许 >100%）';

  @override
  String get generation_canvasEmpty => '画布为空';

  @override
  String get generation_canvasBackground => '透明区域底色';

  @override
  String get generation_canvasBackgroundChecker => '棋盘格';

  @override
  String get generation_canvasBackgroundCheckerLight => '浅色棋盘格';

  @override
  String get generation_canvasBackgroundCheckerDark => '深色棋盘格';

  @override
  String get generation_canvasBackgroundNone => '无底色';

  @override
  String get generation_canvasBackgroundBlack => '黑色';

  @override
  String get generation_canvasBackgroundWhite => '白色';

  @override
  String get generation_canvasBackgroundGray => '灰色';

  @override
  String get generation_canvasBackgroundRed => '红色';

  @override
  String get generation_canvasBackgroundGreen => '绿色';

  @override
  String get generation_canvasBackgroundBlue => '蓝色';

  @override
  String get generation_canvasBackgroundCustom => '自定义颜色';

  @override
  String get generation_canvasSetInitImage => '设为图生图底图';

  @override
  String get generation_canvasSendToTools => '发送至导演工具';

  @override
  String get generation_canvasPinImage => '固定图片';

  @override
  String get generation_canvasUnpinImage => '取消固定';

  @override
  String get generation_canvasUseSeed => '点击复用此种子';

  @override
  String get generation_history => '历史';

  @override
  String get generation_failedStreamSnapshot => '失败快照';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成未完成，仅保留最后一帧预览；不可保存、收藏或用于图生图';

  @override
  String get generation_model => '模型';

  @override
  String get generation_imageSize => '图像尺寸';

  @override
  String get generation_sampler => '采样器';

  @override
  String generation_steps(Object steps) {
    return '步数: $steps';
  }

  @override
  String get generation_stepsLabel => '步数';

  @override
  String get generation_guidance => '引导';

  @override
  String generation_cfgScale(Object scale) {
    return '提示词引导：$scale';
  }

  @override
  String get generation_seed => '种子';

  @override
  String get generation_seedRandom => '随机';

  @override
  String get generation_samplerRecommended => '推荐';

  @override
  String get generation_samplerOther => '其他';

  @override
  String get generation_advancedOptions => '高级选项';

  @override
  String get generation_smea => 'SMEA';

  @override
  String get generation_smeaSubtitle => '改善大图像的生成质量';

  @override
  String get generation_smeaDyn => 'SMEA DYN';

  @override
  String get generation_smeaDescription => '高分辨率采样器会在超过一定图像尺寸时自动使用';

  @override
  String generation_cfgRescale(Object value) {
    return '提示词引导重缩放：$value';
  }

  @override
  String get generation_noiseSchedule => '噪声调度';

  @override
  String get generation_modelGroupNew => '最新';

  @override
  String get generation_modelGroupLegacy => '旧版';

  @override
  String get generation_modelDesc_v5Curated =>
      'NovelAI 的最新模型，基于精选图像子集训练。推荐用于流式传输。';

  @override
  String get generation_modelDesc_v5Full => 'NovelAI 最新且最强的模型。';

  @override
  String get generation_modelDesc_v45Curated => '基于精选图像子集训练的 V4.5 模型。不再推荐使用。';

  @override
  String get generation_modelDesc_v45Full => 'NovelAI 的 V4.5 全量模型。';

  @override
  String get generation_modelDesc_v4Curated => '基于精选图像子集训练的 V4 模型。';

  @override
  String get generation_modelDesc_v4Full => 'NovelAI 的 V4 全量模型。';

  @override
  String get generation_sectionCharacters => '角色提示词';

  @override
  String get generation_sectionCharactersSub => '为场景中的角色创建独立提示词。';

  @override
  String get character_positionLabel => '定位';

  @override
  String get anlas_subscription => '订阅赠送';

  @override
  String get anlas_purchased => '付费购买';

  @override
  String get prompt_positive => '正面';

  @override
  String get prompt_baseTab => '基础提示词';

  @override
  String get prompt_negativeTab => '负面';

  @override
  String get prompt_transparentBg => '透明通道';

  @override
  String get prompt_chunksMenu => '模块与开关';

  @override
  String get qualityTags_presetChip => '质量词预设';

  @override
  String get ucPreset_presetChip => '负面词预设';

  @override
  String get prompt_positivePrompt => '正向提示词';

  @override
  String get prompt_negativePrompt => '负向提示词';

  @override
  String get prompt_mainPositive => '主提示词（正面）';

  @override
  String get prompt_mainNegative => '主提示词（负面）';

  @override
  String get prompt_characterPrompts => '多角色提示词';

  @override
  String get prompt_finalPrompt => '最终生效提示词';

  @override
  String get prompt_finalNegative => '最终生效负面词';

  @override
  String prompt_importedCharacters(int count) {
    return '已导入 $count 个角色';
  }

  @override
  String get prompt_characterPromptReplaced => '已替换角色提示词';

  @override
  String prompt_characterPromptAppended(Object count) {
    return '已追加角色提示词 ($count 个角色)';
  }

  @override
  String prompt_smartDecomposedWithCharacters(Object count) {
    return '已分解：主提示词 + $count 个角色';
  }

  @override
  String get prompt_appliedToMainPrompt => '已应用到主提示词';

  @override
  String get prompt_searchHint => '搜索提示词';

  @override
  String prompt_searchMatchCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get prompt_searchPrevious => '上一个命中';

  @override
  String get prompt_searchNext => '下一个命中';

  @override
  String get prompt_searchClose => '关闭搜索';

  @override
  String get prompt_replaceHint => '替换为';

  @override
  String get prompt_replaceToggle => '显示/隐藏替换';

  @override
  String get prompt_replaceCurrent => '替换当前命中（Enter）';

  @override
  String get prompt_replaceAll => '全部替换（Ctrl+Enter）';

  @override
  String prompt_replaceAllDone(Object count) {
    return '已替换 $count 处';
  }

  @override
  String get kritaBridge_busyGenerating => 'Krita Bridge 正在生成，请等待当前任务结束';

  @override
  String get prompt_unwantedContent => '不想出现在图像中的内容...';

  @override
  String get prompt_autoFormat => '自动格式化';

  @override
  String get prompt_autoFormatSubtitle => '规范逗号与空白，移除无效的 1 倍权重符号';

  @override
  String get prompt_highlightEmphasis => '高亮强调';

  @override
  String get prompt_highlightEmphasisSubtitle => '括号和权重语法高亮显示';

  @override
  String get prompt_sdSyntaxAutoConvert => 'SD语法自动转换';

  @override
  String get prompt_sdSyntaxAutoConvertSubtitle => '失焦或生成时将 SD 权重语法转换为 NAI 格式';

  @override
  String get prompt_cooccurrenceRecommendation => '标签扩展';

  @override
  String get prompt_cooccurrenceRecommendationSubtitle =>
      'Ctrl+单击搜索本地标签；Ctrl+拖选查看关联标签';

  @override
  String get prompt_formatted => '已格式化';

  @override
  String get image_save => '保存';

  @override
  String get image_copy => '复制';

  @override
  String get image_upscale => '放大';

  @override
  String image_imageSaved(Object path) {
    return '图片已保存到: $path';
  }

  @override
  String image_saveFailed(Object error) {
    return '保存失败: $error';
  }

  @override
  String get image_copiedToClipboard => '已复制到剪贴板';

  @override
  String image_copyFailed(Object error) {
    return '复制失败: $error';
  }

  @override
  String get img2img_title => '图生图';

  @override
  String get img2img_subtitle => '基于底图生成变体';

  @override
  String get img2img_enabled => '已启用';

  @override
  String get img2img_sourceImage => '源图像';

  @override
  String get img2img_strength => '变化强度';

  @override
  String get img2img_strengthHint => '值越高，生成的图像与原图差异越大';

  @override
  String get img2img_noise => '噪声量';

  @override
  String get img2img_noiseHint => '添加额外噪声以增加变化';

  @override
  String get img2img_clearSettings => '清除图生图设置';

  @override
  String get img2img_changeImage => '更换图片';

  @override
  String get img2img_removeImage => '移除图片';

  @override
  String img2img_selectFailed(Object error) {
    return '选择图片失败: $error';
  }

  @override
  String get img2img_editImage => '编辑图像';

  @override
  String get img2img_placeOnCanvas => '放入画布';

  @override
  String get img2img_editApplied => '已将编辑结果设为新的源图';

  @override
  String get img2img_uploadImage => '上传图片';

  @override
  String get img2img_dropToAdd => '松开以设为底图';

  @override
  String get img2img_moreActions => '更多操作';

  @override
  String get img2img_drawSketch => '绘制草图';

  @override
  String get img2img_inpaint => '局部重绘';

  @override
  String get img2img_inpaintStrength => '重绘强度';

  @override
  String get img2img_inpaintStrengthHint => '值越高，蒙版区域与当前源图差异越大';

  @override
  String get img2img_inpaintPendingHint =>
      '点击“局部重绘”进入画布，用画笔、橡皮或选区工具标出需要重绘的区域。返回这里后，点击主生成按钮即可只重绘蒙版区域。';

  @override
  String get img2img_inpaintReadyHint => '遮罩已载入。当前会按局部重绘方式提交，只有蒙版区域会被重新生成。';

  @override
  String get img2img_inpaintMaskReady => '局部重绘遮罩已准备好';

  @override
  String get generation_variationOriginal => '原图';

  @override
  String get generation_variationSizeUnsupported => '生成变体支持不超过 3 百万像素的原图。';

  @override
  String get img2img_generateVariations => '生成变体';

  @override
  String get img2img_directorTools => '导演工具';

  @override
  String get img2img_directorApplied => '已将导演工具结果设为新的源图';

  @override
  String get img2img_variationsStarted => '正在生成变体...';

  @override
  String get img2img_directorRemoveBackground => '背景移除';

  @override
  String get img2img_directorLineArt => '线稿提取';

  @override
  String get img2img_directorSketch => '草图化';

  @override
  String get img2img_directorColorize => '上色';

  @override
  String get img2img_directorEmotion => '表情修复';

  @override
  String get img2img_directorDeclutter => '杂线清理';

  @override
  String get img2img_enhance => '增强';

  @override
  String get img2img_enhanceMagnitude => '幅度';

  @override
  String get img2img_enhanceUpscaleAmount => '放大倍数';

  @override
  String get img2img_enhanceMax => 'Max✨';

  @override
  String get img2img_novelAiCloudUpscale => 'NovelAI 云端超分（固定 2x 放大）';

  @override
  String get img2img_novelAiCloudUpscaleTitle => 'NovelAI 云端超分';

  @override
  String get img2img_cloudUpscaleSizeLimit => 'NovelAI 云端放大支持不超过 3MP 的输入图片。';

  @override
  String get img2img_upscaleRegularModel => '普通模型';

  @override
  String get img2img_upscaleModel => '超分模型';

  @override
  String get img2img_startUpscale => '开始超分';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 超分完成';

  @override
  String get img2img_decodeSourceFailed => '无法解码源图像';

  @override
  String get editor_tolerance => '容差';

  @override
  String get editor_intensity => '强度';

  @override
  String get editor_sourcePoint => 'Alt+点击设置源点';

  @override
  String get editor_brushPresets => '笔刷预设';

  @override
  String get editor_size => '大小';

  @override
  String get editor_opacity => '不透明度';

  @override
  String get editor_hardness => '硬度';

  @override
  String get editor_undo => '撤销';

  @override
  String get editor_redo => '重做';

  @override
  String get editor_clearLayer => '清除图层';

  @override
  String get editor_toolBrush => '画笔';

  @override
  String get editor_toolEraser => '橡皮擦';

  @override
  String get editor_toolFill => '填充';

  @override
  String get editor_toolMagicWand => '魔棒';

  @override
  String get editor_magicWandMode => '选择方式';

  @override
  String get editor_magicWandSmartObject => '智能对象（EfficientViT）';

  @override
  String get editor_magicWandColorArea => '颜色区域（洪水填充）';

  @override
  String get editor_magicWandSmartHelp =>
      '点击要选择的对象。首次使用会从 MIT Han Lab 下载约 133 MiB 的 EfficientViT-SAM L0 模型（Apache-2.0），之后保存在本地。';

  @override
  String get editor_magicWandColorHelp => '点击颜色相近的连续区域。适合边界清晰的纯色图像，无需下载模型。';

  @override
  String get editor_magicWandInvert => '反选结果';

  @override
  String get editor_toolLine => '直线';

  @override
  String get editor_toolRectSelect => '矩形选框';

  @override
  String get editor_toolEllipseSelect => '椭圆选框';

  @override
  String get editor_toolLassoSelect => '套索选区';

  @override
  String get editor_toolColorPicker => '吸管取色';

  @override
  String get editor_toolCloneStamp => '仿制图章';

  @override
  String get editor_toolBlur => '模糊';

  @override
  String get editor_layers => '图层';

  @override
  String get editor_fillClosedRegion => '填充封闭区域';

  @override
  String get editor_resetMask => '重置蒙版';

  @override
  String get editor_zoomIn => '放大';

  @override
  String get editor_zoomOut => '缩小';

  @override
  String get editor_fitToWindow => '适应窗口';

  @override
  String get editor_effectBrightness => '亮度';

  @override
  String get editor_effectSaturation => '饱和度';

  @override
  String get editor_changeCanvasSize => '更改画布尺寸';

  @override
  String get editor_confirmExitTitle => '确认退出';

  @override
  String get editor_confirmExitContent => '有未保存的修改，确定要退出吗？';

  @override
  String get editor_exit => '退出';

  @override
  String get editor_saveAndExit => '保存并退出';

  @override
  String editor_exportFailed(Object error) {
    return '导出失败: $error';
  }

  @override
  String get editor_maskLayerName => '蒙版';

  @override
  String get editor_emptyImageFile => '文件为空，请选择有效的图像文件';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return '文件过大（$sizeMB MB），请选择小于 50MB 的图像';
  }

  @override
  String get editor_parseImageFailed => '无法解析图像文件\n请确保文件未损坏且格式受支持';

  @override
  String get editor_defaultTitle => '画板';

  @override
  String get editor_baseLayerName => '底图';

  @override
  String get editor_existingMaskLayerName => '已有蒙版';

  @override
  String get editor_defaultDrawingLayerName => '图层 1';

  @override
  String editor_layerName(Object count) {
    return '图层 $count';
  }

  @override
  String get editor_canvasSizeTitle => '画布尺寸';

  @override
  String get editor_presetSize => '预设尺寸';

  @override
  String get editor_customSize => '自定义';

  @override
  String get editor_contentHandling => '内容处理';

  @override
  String get editor_contentCrop => '裁剪';

  @override
  String get editor_contentPad => '填充';

  @override
  String get editor_contentStretch => '拉伸';

  @override
  String get editor_width => '宽度';

  @override
  String get editor_height => '高度';

  @override
  String get editor_lockAspectRatio => '锁定比例';

  @override
  String get editor_unlockAspectRatio => '取消锁定比例';

  @override
  String get editor_sizePreview => '尺寸预览';

  @override
  String get editor_originalSize => '原始';

  @override
  String get editor_newSize => '新尺寸';

  @override
  String get editor_cropModeDescription => '裁剪模式 - 保持比例裁剪';

  @override
  String get editor_padModeDescription => '填充模式 - 保持比例填充';

  @override
  String get editor_stretchModeDescription => '拉伸模式 - 拉伸至填满';

  @override
  String editor_canvasPresetSquare(Object size) {
    return '方形 $size';
  }

  @override
  String editor_canvasPresetLandscape(Object ratio) {
    return '横向 $ratio';
  }

  @override
  String editor_canvasPresetPortrait(Object ratio) {
    return '纵向 $ratio';
  }

  @override
  String get editor_canvasPresetNaiPortrait => 'NAI 纵向';

  @override
  String get editor_canvasPresetNaiLandscape => 'NAI 横向';

  @override
  String get editor_canvasPresetFullHd => '全高清 16:9';

  @override
  String get editor_colorPanelTitle => '颜色';

  @override
  String get editor_colorPickerTitle => '选择颜色';

  @override
  String get editor_brushSettings => '画笔设置';

  @override
  String get editor_eraserSettings => '橡皮擦设置';

  @override
  String get editor_lassoSelectionHelp => '按住鼠标拖动绘制自由形状选区，松开自动闭合';

  @override
  String get layer_empty => '无图层';

  @override
  String get layer_add => '添加图层';

  @override
  String get layer_mergeDown => '向下合并';

  @override
  String get layer_duplicate => '复制图层';

  @override
  String get layer_delete => '删除图层';

  @override
  String get layer_merge => '合并图层';

  @override
  String get layer_visibility => '显示/隐藏';

  @override
  String get layer_lock => '锁定';

  @override
  String get layer_rename => '重命名';

  @override
  String get layer_moveUp => '上移';

  @override
  String get layer_moveDown => '下移';

  @override
  String get vibe_title => '风格迁移';

  @override
  String get vibe_description => '改变图像，保留视觉风格';

  @override
  String get vibe_addFromFileTitle => '从文件添加';

  @override
  String get vibe_addFromFileSubtitle => 'PNG、JPG、Vibe 文件';

  @override
  String get vibe_addFromLibraryTitle => '从库导入';

  @override
  String get vibe_addFromLibrarySubtitle => '从 Vibe 库中选择';

  @override
  String get vibe_addReference => '添加参考图';

  @override
  String get vibe_clearAll => '清除全部';

  @override
  String vibe_cleared(int count) {
    return '已清除 $count 个 vibes';
  }

  @override
  String get vibe_referenceStrength => '参考强度';

  @override
  String get vibe_infoExtraction => '信息提取';

  @override
  String get vibe_remove => '移除';

  @override
  String get reference_enabled => '启用';

  @override
  String get reference_enable => '启用参考';

  @override
  String get reference_disable => '禁用参考';

  @override
  String get vibe_normalize => '标准化参考强度值';

  @override
  String get vibe_sourceType_png => 'PNG';

  @override
  String get vibe_sourceType_v4vibe => 'V4 Vibe';

  @override
  String get vibe_sourceType_bundle => '组合包';

  @override
  String get vibe_sourceType_image => '图片';

  @override
  String get vibe_sourceType => '数据源';

  @override
  String get vibe_info => 'Vibe 信息';

  @override
  String get vibe_name => '名称';

  @override
  String get character_buttonLabel => '角色/定位';

  @override
  String get character_addCharacter => '添加角色';

  @override
  String character_number(Object index) {
    return '角色 $index';
  }

  @override
  String get gallery_generationParams => '生成参数';

  @override
  String get gallery_metaModel => '模型';

  @override
  String get gallery_metaResolution => '分辨率';

  @override
  String get gallery_metaSteps => '步数';

  @override
  String get gallery_metaSampler => '采样器';

  @override
  String get gallery_metaCfgScale => '提示词引导';

  @override
  String get gallery_metaSeed => '种子';

  @override
  String get gallery_sendToKritaAction => '发送到 Krita';

  @override
  String get gallery_upscalePanelLoaded => '已载入图生图超分面板';

  @override
  String gallery_readImageFailed(Object error) {
    return '读取图像失败: $error';
  }

  @override
  String get gallery_fileMissing => '文件不存在';

  @override
  String get gallery_copiedToClipboard => '已复制到剪贴板';

  @override
  String gallery_copyFailed(Object error) {
    return '复制失败: $error';
  }

  @override
  String get gallery_upscale => '放大';

  @override
  String get gallery_sentToImg2Img => '图片已发送到图生图';

  @override
  String gallery_sendFailed(Object error) {
    return '发送失败: $error';
  }

  @override
  String get onlineGallery_login => '登录';

  @override
  String get onlineGallery_pleaseLogin => '请先登录';

  @override
  String get mediaType_video => '视频';

  @override
  String get mediaType_gif => '动图';

  @override
  String get onlineGallery_copied => '已复制';

  @override
  String get onlineGallery_copyTags => '复制标签';

  @override
  String get onlineGallery_sendToTextToImage => '发送到文生图';

  @override
  String get onlineGallery_sentToTextToImage => '已发送到文生图';

  @override
  String get onlineGallery_noTagInfo => '此图片没有标签信息';

  @override
  String get onlineGallery_chooseDownloadDirectory => '选择下载目录';

  @override
  String get onlineGallery_downloadStarted => '开始下载...';

  @override
  String onlineGallery_savedToPath(Object path) {
    return '已保存到: $path';
  }

  @override
  String onlineGallery_downloadFailed(Object error) {
    return '下载失败: $error';
  }

  @override
  String get onlineGallery_downloadOriginal => '下载原图';

  @override
  String get onlineGallery_ratingGeneral => '全年龄';

  @override
  String get onlineGallery_ratingSensitive => '敏感';

  @override
  String get onlineGallery_ratingQuestionable => '可疑';

  @override
  String get onlineGallery_ratingExplicit => '限制级';

  @override
  String get onlineGallery_blacklistTitle => '在线画廊黑名单';

  @override
  String get onlineGallery_blacklistSubtitle => '包含黑名单标签的图片会在在线画廊中直接隐藏。';

  @override
  String get onlineGallery_addBlacklistTagHint => '添加黑名单标签';

  @override
  String get onlineGallery_noLocalBlacklistTags => '暂无本地黑名单标签';

  @override
  String get onlineGallery_autoSyncOnStartup => '启动时自动同步';

  @override
  String get onlineGallery_autoSyncOnStartupSubtitle => '默认开启，可随时关闭';

  @override
  String onlineGallery_lastSyncFailed(Object error) {
    return '上次同步失败: $error';
  }

  @override
  String get onlineGallery_neverSyncedBlacklist => '尚未同步过 Danbooru 黑名单';

  @override
  String onlineGallery_lastSync(Object time) {
    return '上次同步: $time';
  }

  @override
  String get onlineGallery_blacklistSettingsTitle => '在线画廊黑名单设置';

  @override
  String get onlineGallery_blacklistLoginHint =>
      '未登录 Danbooru，仍可使用本地黑名单；同步需要先登录。';

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return '下载完成: 成功 $success, 失败 $failed';
  }

  @override
  String get onlineGallery_gelbooruCredentialsRequired =>
      '请先配置 Gelbooru User ID 和 API Key 以查看网站收藏。';

  @override
  String get onlineGallery_gelbooruCredentialsInvalid =>
      'Gelbooru 凭据已失效，请重新配置。';

  @override
  String get onlineGallery_gelbooruRateLimited => 'Gelbooru 请求过于频繁，请稍后再试。';

  @override
  String get onlineGallery_gelbooruTimeout => 'Gelbooru 请求超时，请检查网络连接。';

  @override
  String get onlineGallery_gelbooruServerError => 'Gelbooru 服务器暂时不可用，请稍后再试。';

  @override
  String get onlineGallery_gelbooruNetworkError =>
      '无法连接 Gelbooru，请检查网络设置或代理配置。';

  @override
  String get onlineGallery_gelbooruMalformedResponse => 'Gelbooru 返回了无法解析的数据。';

  @override
  String get onlineGallery_gelbooruRequestFailed => 'Gelbooru 请求失败，请稍后重试。';

  @override
  String get onlineGallery_aiTagRankingProcessing => '排行榜生成中，请稍后重试。';

  @override
  String get onlineGallery_sourceConfigUnavailable => '无法获取来源配置，请检查网络后重试。';

  @override
  String get onlineGallery_sourceRateLimited => '请求过于频繁，请稍后重试。';

  @override
  String get onlineGallery_sourceTimeout => '请求超时，请检查网络连接。';

  @override
  String get onlineGallery_sourceNetworkError => '无法连接当前画廊来源，请检查网络或代理。';

  @override
  String get onlineGallery_sourceMalformedResponse => '来源返回的数据结构已变化，暂时无法解析。';

  @override
  String get onlineGallery_detailNotFound => '作品不存在或已被删除。';

  @override
  String get onlineGallery_imageUnavailable => '图片当前不可用。';

  @override
  String get onlineGallery_gelbooruReadOnly => '只读收藏';

  @override
  String get tooltip_fullscreenEdit => '全屏编辑';

  @override
  String get tooltip_decreaseWeight => '减少权重 [-5%]';

  @override
  String get tooltip_increaseWeight => '增加权重 [+5%]';

  @override
  String get tooltip_resetWeight => '点击重置为100%';

  @override
  String get upscale_scale => '放大倍数';

  @override
  String get danbooru_loginTitle => '登录 Danbooru';

  @override
  String get danbooru_loginHint => '使用用户名和 API Key 登录以使用收藏夹功能';

  @override
  String get danbooru_username => '用户名';

  @override
  String get danbooru_usernameHint => '输入 Danbooru 用户名';

  @override
  String get danbooru_usernameRequired => '请输入用户名';

  @override
  String get danbooru_apiKeyHint => '输入 API Key';

  @override
  String get danbooru_apiKeyRequired => '请输入 API Key';

  @override
  String get danbooru_howToGetApiKey => '如何获取 API Key?';

  @override
  String get danbooru_loginSuccess => '登录成功';

  @override
  String get gelbooru_configureTitle => '配置 Gelbooru API';

  @override
  String get gelbooru_configureHint =>
      '输入 Gelbooru 账户设置页提供的 User ID 和 API Key。应用不会收集密码或浏览器 Cookie。';

  @override
  String get gelbooru_userId => 'User ID';

  @override
  String get gelbooru_userIdHint => '输入正整数 User ID';

  @override
  String get gelbooru_userIdRequired => '请输入有效的正整数 User ID';

  @override
  String get gelbooru_apiKeyHint => '输入 API Key';

  @override
  String get gelbooru_apiKeyRequired => '请输入 API Key';

  @override
  String get gelbooru_openAccountSettings => '打开 Gelbooru 账户设置';

  @override
  String get gelbooru_save => '验证并保存';

  @override
  String get gelbooru_saved => 'Gelbooru 凭据已保存';

  @override
  String get gelbooru_removeCredentials => '移除凭据';

  @override
  String get gelbooru_invalidInput => '请输入有效的 User ID 和 API Key。';

  @override
  String get gelbooru_invalidCredentials =>
      'Gelbooru 拒绝了这些凭据，请检查 User ID 和 API Key。';

  @override
  String get gelbooru_rateLimited => '请求过于频繁，请稍后再试。';

  @override
  String get gelbooru_timeout => '验证超时，请检查网络连接。';

  @override
  String get gelbooru_serverError => 'Gelbooru 服务器暂时不可用。';

  @override
  String get gelbooru_networkError => '无法连接 Gelbooru，请检查网络设置或代理配置。';

  @override
  String get gelbooru_malformedResponse => 'Gelbooru 返回了无法解析的数据。';

  @override
  String get gelbooru_storageError => '无法安全保存或读取 Gelbooru 凭据。';

  @override
  String get gelbooru_unknownError => 'Gelbooru 验证失败，请稍后重试。';

  @override
  String get tag_addTag => '添加标签';

  @override
  String get qualityTags_label => '质量词';

  @override
  String get transparentBackground_tooltip =>
      '向提示词追加 transparent background 标签，生成带 alpha 通道的图像（V5 专属）';

  @override
  String get qualityTags_positive => '质量词（正面）';

  @override
  String get qualityTags_negative => '质量词（负面）';

  @override
  String get qualityTags_disabled => '质量标签已关闭\n点击开启';

  @override
  String get qualityTags_addToEnd => '添加到提示词末尾:';

  @override
  String get qualityTags_addToStart => '添加到提示词开头:';

  @override
  String get qualityTags_naiDefault => 'NAI 默认';

  @override
  String get qualityTags_standard => '标准';

  @override
  String get qualityTags_light => '轻量';

  @override
  String get qualityTags_none => '无';

  @override
  String get ucPreset_label => '负面预设';

  @override
  String get ucPreset_heavy => '重度';

  @override
  String get ucPreset_light => '轻度';

  @override
  String get ucPreset_furryFocus => '兽人';

  @override
  String get ucPreset_humanFocus => '人物';

  @override
  String get ucPreset_lowQuality => '低质量';

  @override
  String get ucPreset_badAnatomy => '解剖错误';

  @override
  String get ucPreset_none => '无';

  @override
  String get ucPreset_disabled => '负面提示词预设已关闭';

  @override
  String get ucPreset_addToNegative => '添加到负面提示词开头:';

  @override
  String get ucPreset_nsfwHint =>
      '💡 如需生成成人内容，请在正面提示词中添加 nsfw，负面提示词中的 nsfw 将自动移除';

  @override
  String get generation_imageCount => '生成数量';

  @override
  String get generation_requestCountTooltip => '请求次数：每次点击发起 N 次生成请求';

  @override
  String generation_imageCountTotal(int requests, int perRequest, int total) {
    return '$requests 次 × $perRequest 张 = 共 $total 张';
  }

  @override
  String get warmup_networkCheck => '检测网络连接...';

  @override
  String get warmup_networkCheck_noProxy => '无法连接到 NovelAI，请开启VPN或启用代理设置';

  @override
  String get warmup_networkCheck_noSystemProxy => '已启用代理但未检测到系统代理，请开启VPN';

  @override
  String get warmup_networkCheck_manualIncomplete => '手动代理配置不完整，请检查设置';

  @override
  String get warmup_networkCheck_testing => '正在检测网络连接...';

  @override
  String get warmup_networkCheck_testingProxy => '正在通过代理检测网络...';

  @override
  String warmup_networkCheck_success(Object latency) {
    return '网络连接正常 (${latency}ms)';
  }

  @override
  String get warmup_networkCheck_timeout => '网络检测超时，继续离线启动';

  @override
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts) {
    return '正在检测网络连接... (尝试 $attempt/$maxAttempts)';
  }

  @override
  String get warmup_preparing => '准备中...';

  @override
  String get warmup_complete => '完成';

  @override
  String get warmup_danbooruAuth => '初始化 Danbooru 认证...';

  @override
  String get warmup_loadingTranslation => '加载翻译数据...';

  @override
  String get warmup_initUnifiedDatabase => '初始化标签数据库...';

  @override
  String get warmup_initTagSystem => '初始化标签系统...';

  @override
  String get warmup_imageEditor => '初始化图像编辑器...';

  @override
  String get warmup_database => '加载最近历史记录...';

  @override
  String get warmup_network => '检查网络连接...';

  @override
  String get warmup_fonts => '预加载字体...';

  @override
  String get warmup_imageCache => '预热图像缓存...';

  @override
  String get warmup_statistics => '加载统计数据...';

  @override
  String get warmup_artistsSync => '同步画师数据...';

  @override
  String get warmup_subscription => '加载订阅信息...';

  @override
  String get warmup_dataSourceCache => '初始化数据源缓存...';

  @override
  String get warmup_galleryFileCount => '扫描图库文件...';

  @override
  String get warmup_cooccurrenceData => '加载标签共现数据...';

  @override
  String get warmup_group_basicUI => '初始化基础 UI 服务...';

  @override
  String get warmup_group_basicUI_complete => '基础 UI 服务就绪';

  @override
  String get warmup_group_dataServices => '初始化数据服务...';

  @override
  String get warmup_group_dataServices_complete => '数据服务就绪';

  @override
  String get warmup_group_networkServices => '初始化网络服务...';

  @override
  String get warmup_group_networkServices_complete => '网络服务就绪';

  @override
  String get warmup_group_cacheServices => '初始化缓存服务...';

  @override
  String get warmup_group_cacheServices_complete => '缓存服务就绪';

  @override
  String get warmup_cooccurrenceInit => '初始化共现数据...';

  @override
  String get warmup_translationInit => '初始化翻译数据...';

  @override
  String get warmup_danbooruTagsInit => '初始化 Danbooru 标签...';

  @override
  String get warmup_dataMigration => '迁移 Hive / Vibe / 图片数据...';

  @override
  String get warmup_galleryDataSource => '初始化画廊索引...';

  @override
  String get warmup_checkAndRecoverData => '检查数据完整性...';

  @override
  String get warmup_group_dataSourceInitialization => '初始化数据源服务...';

  @override
  String get warmup_group_dataSourceInitialization_complete => '数据源服务就绪';

  @override
  String warmup_fetchingTags(Object message) {
    return '正在同步标签：$message';
  }

  @override
  String get warmup_fetchingTagDataFromServer => '正在从服务器拉取标签数据...';

  @override
  String get warmup_fetchingGeneralTags => '正在拉取通用标签...';

  @override
  String get warmup_fetchingCharacterTags => '正在拉取角色标签...';

  @override
  String get warmup_fetchingCopyrightTags => '正在拉取版权标签...';

  @override
  String get warmup_fetchingMetaTags => '正在拉取元标签...';

  @override
  String get resolution_groupNormal => '常规';

  @override
  String get resolution_groupLarge => '大尺寸';

  @override
  String get resolution_groupWallpaper => '壁纸';

  @override
  String get resolution_groupSmall => '小尺寸';

  @override
  String get resolution_groupCustom => '自定义';

  @override
  String get resolution_typePortrait => '竖屏';

  @override
  String get resolution_typeLandscape => '横屏';

  @override
  String get resolution_typeSquare => '方形';

  @override
  String get resolution_typeCustom => '自定义';

  @override
  String get resolution_width => '宽度';

  @override
  String get resolution_height => '高度';

  @override
  String get api_error_429 => '并发限制';

  @override
  String get api_error_429_hint => '请求过于频繁，请稍后重试（常见于合租账号）';

  @override
  String get api_error_401 => '认证失败';

  @override
  String get api_error_401_hint => 'Token 无效或已过期，请重新登录';

  @override
  String get api_error_402 => '余额不足';

  @override
  String get api_error_402_hint => 'Anlas 余额不足，请充值后重试';

  @override
  String get api_error_500 => '服务器错误';

  @override
  String get api_error_500_hint => 'NovelAI 服务器出现问题，请稍后重试';

  @override
  String get api_error_503 => '服务不可用';

  @override
  String get api_error_503_hint => '服务器正在维护或过载，请稍后重试';

  @override
  String get api_error_timeout => '请求超时';

  @override
  String get api_error_timeout_hint => '网络连接超时，请检查网络后重试';

  @override
  String get api_error_network => '网络错误';

  @override
  String get api_error_network_hint => '无法连接到服务器，请检查网络';

  @override
  String get drop_processing => '正在解析图片...';

  @override
  String get characterEditor_clearAll => '清空所有';

  @override
  String get characterEditor_clearAllTitle => '清空所有角色';

  @override
  String get characterEditor_clearAllConfirm => '确定要删除所有角色吗？此操作无法撤销。';

  @override
  String get characterEditor_nameHint => '输入角色名称';

  @override
  String get characterEditor_enabled => '启用';

  @override
  String get characterEditor_negativePromptHint => '输入角色的负面提示词...';

  @override
  String get characterCanvas_title => '角色位置';

  @override
  String get characterCanvas_finishEditing => '完成位置编辑';

  @override
  String get characterCanvas_aiChoice => 'AI 选择';

  @override
  String get characterCanvas_custom => '自定义';

  @override
  String get characterCanvas_aiHint => 'AI 将自动安排角色位置';

  @override
  String get characterCanvas_dragHint => '拖动锚点设置角色位置，松开即生效';

  @override
  String get characterEditor_genderFemale => '女性';

  @override
  String get characterEditor_genderMale => '男性';

  @override
  String get characterEditor_genderOther => '其他';

  @override
  String get characterEditor_addFemale => '女';

  @override
  String get characterEditor_addMale => '男';

  @override
  String get characterEditor_addOther => '其他';

  @override
  String get characterEditor_moveUp => '上移';

  @override
  String get characterEditor_moveDown => '下移';

  @override
  String get toolbar_fullscreenEdit => '全屏编辑';

  @override
  String get characterTooltip_noCharacters => '未配置角色';

  @override
  String get characterTooltip_clickToConfig => '点击按钮开始配置多人角色';

  @override
  String get characterTooltip_globalAiLabel => '全局 AI 位置:';

  @override
  String get characterTooltip_enabled => '启用';

  @override
  String get characterTooltip_disabled => '禁用';

  @override
  String get characterTooltip_positionAi => 'AI';

  @override
  String get characterTooltip_disabledLabel => '已禁用';

  @override
  String get characterTooltip_promptLabel => '正向';

  @override
  String get characterTooltip_negativeLabel => '负面';

  @override
  String get characterTooltip_notSet => '未设置';

  @override
  String characterTooltip_summary(Object total, Object enabled) {
    return '共 $total 个角色 ($enabled 个启用)';
  }

  @override
  String get characterTooltip_viewFullConfig => '点击查看完整配置';

  @override
  String get addGroup_displayNameLabel => '显示名称（可选）';

  @override
  String get addGroup_targetCategoryLabel => '目标分类';

  @override
  String globalSettings_saveFailed(Object error) {
    return '保存失败: $error';
  }

  @override
  String get nav_generate => '生成';

  @override
  String get nav_gallery => '画廊';

  @override
  String get nav_settings => '设置';

  @override
  String get sync_preparing => '准备同步...';

  @override
  String sync_fetching(Object category) {
    return '正在获取 $category...';
  }

  @override
  String get sync_processing => '正在处理数据...';

  @override
  String get sync_saving => '正在保存...';

  @override
  String sync_completed(Object count) {
    return '同步完成，共 $count 个标签';
  }

  @override
  String sync_failed(Object error) {
    return '同步失败: $error';
  }

  @override
  String sync_extracting(Object poolName) {
    return '正在提取 $poolName 标签...';
  }

  @override
  String get sync_merging => '正在合并标签...';

  @override
  String sync_fetching_tags(Object groupName) {
    return '正在获取 $groupName 标签热度...';
  }

  @override
  String get sync_filtering => '正在筛选标签...';

  @override
  String get sync_done => '同步完成';

  @override
  String get time_just_now => '刚刚';

  @override
  String time_minutes_ago(Object n) {
    return '$n分钟前';
  }

  @override
  String time_hours_ago(Object n) {
    return '$n小时前';
  }

  @override
  String time_days_ago(Object n) {
    return '$n天前';
  }

  @override
  String get time_never_synced => '从未同步';

  @override
  String get vibeParseFailed => '无法解析 Vibe 文件';

  @override
  String get localGallery_progressiveLoadError => '图片加载失败';

  @override
  String get localGallery_unknownError => '未知错误';

  @override
  String localGallery_loadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get localGallery_indexingLocalImages => '索引本地图片中...';

  @override
  String get localGallery_emptyTitle => '暂无本地图片';

  @override
  String get localGallery_emptySubtitle => '生成的图片将保存在此处';

  @override
  String get localGallery_noMatchingResults => '无匹配结果';

  @override
  String get localGallery_title => '本地画廊';

  @override
  String get localGallery_allImages => '全部图片';

  @override
  String get localGallery_selectAllResults => '选择全部';

  @override
  String get localGallery_deselectAllResults => '取消全部';

  @override
  String get localGallery_moveSelected => '移动';

  @override
  String get localGallery_packSelected => '打包';

  @override
  String get localGallery_editMetadata => '编辑';

  @override
  String get localGallery_addToCollection => '收藏';

  @override
  String get localGallery_sortButton => '排序';

  @override
  String get localGallery_sortFieldModified => '修改时间';

  @override
  String get localGallery_sortFieldCreated => '创建时间';

  @override
  String get localGallery_sortFieldName => '文件名';

  @override
  String get localGallery_sortFieldSize => '文件大小';

  @override
  String get localGallery_sortFieldDimensions => '图像尺寸';

  @override
  String localGallery_aboutColumns(Object count) {
    return '约 $count 列';
  }

  @override
  String get localGallery_columnWidth => '列宽';

  @override
  String get localGallery_thumbnailQualitySd => '标清';

  @override
  String get localGallery_thumbnailQualityHd => '高清';

  @override
  String get settings_galleryThumbnailQuality => '本地画廊清晰度';

  @override
  String get settings_galleryThumbnailQualitySubtitle => '缩略图显示质量，默认高清';

  @override
  String get localGallery_naiOnlyTooltip => '仅显示 NAI 生成的图片';

  @override
  String get localGallery_naiVersionFilterTooltip => '按 NAI 模型版本过滤';

  @override
  String get localGallery_masonryViewLabel => '瀑布流';

  @override
  String get localGallery_justifiedViewLabel => '火车流';

  @override
  String localGallery_dateRangeYearMonth(Object year, Object month) {
    return '$year年$month月';
  }

  @override
  String get localGallery_dateRangePrevMonth => '上个月';

  @override
  String get localGallery_dateRangeNextMonth => '下个月';

  @override
  String get localGallery_dateRangeClear => '清除';

  @override
  String localGallery_searchInScope(Object scope) {
    return '搜索：$scope';
  }

  @override
  String get localGallery_hideCategoryPanel => '隐藏分类面板';

  @override
  String get localGallery_showCategoryPanel => '显示分类面板';

  @override
  String get localGallery_refreshTooltip => '刷新画廊\n\n自动检测新增/修改的图片并更新索引';

  @override
  String get localGallery_tagIntersection => '标签交集';

  @override
  String get localGallery_createCategoryTitle => '新建分类';

  @override
  String get localGallery_newOrImport => '新建/导入';

  @override
  String get localGallery_importFolder => '导入文件夹';

  @override
  String get localGallery_createCategoryHint => '请输入分类名称';

  @override
  String get localGallery_createCategoryConfirm => '创建';

  @override
  String get localGallery_createSubCategoryTitle => '新建子分类';

  @override
  String get localGallery_showInFolder => '在文件夹中显示';

  @override
  String get localGallery_promptCopied => 'Prompt 已复制';

  @override
  String get localGallery_seedCopied => 'Seed 已复制';

  @override
  String get localGallery_createCollectionTitle => '新建收藏集';

  @override
  String get localGallery_createCollectionHint => '输入收藏集名称';

  @override
  String get localGallery_createCollectionConfirm => '创建';

  @override
  String get localGallery_createCollectionFolderTitle => '新建收藏文件夹';

  @override
  String get localGallery_createCollectionFolderHint => '输入收藏文件夹名称';

  @override
  String get localGallery_createCollectionFolderConfirm => '创建';

  @override
  String localGallery_deleteCollectionContent(Object name) {
    return '确定删除收藏集「$name」？仅移除收藏集条目，不会删除任何图片文件。';
  }

  @override
  String localGallery_deleteCollectionFolderContent(Object name) {
    return '确定删除收藏文件夹「$name」？文件夹内没有子项，仅移除文件夹本身。';
  }

  @override
  String get localGallery_deleteCollectionFolderNonEmptyTitle => '文件夹不为空';

  @override
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name) {
    return '收藏文件夹「$name」内还有收藏集或子文件夹，请先移出或删除其中的子项。';
  }

  @override
  String get localGallery_unfavorite => '取消收藏';

  @override
  String get localGallery_favoriteMenuEmptyCollections => '暂无收藏集，左侧 + 创建';

  @override
  String localGallery_confirmDeleteImageContent(Object name) {
    return '确定要删除图片「$name」吗？\n\n图片会立即从画廊消失，文件将在下次启动时彻底清理（本次会话内可撤销）。';
  }

  @override
  String get localGallery_moveTo => '移动到…';

  @override
  String get localGallery_copyTo => '复制到…';

  @override
  String get localGallery_externalSourceMoveConfirmTitle => '移动外部图库源文件';

  @override
  String localGallery_externalSourceMoveConfirmContent(Object count) {
    return '将移动 $count 张图片。文件将从源文件夹移走，原位置不再保留。是否继续？';
  }

  @override
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '将移动 $count 张图片到外部图库源分类「$targetName」。文件将写入外部源文件夹。是否继续？';
  }

  @override
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '将移动 $count 张图片到外部图库源分类「$targetName」。文件将从原文件夹移走（原位置不再保留），并写入外部源文件夹。是否继续？';
  }

  @override
  String get localGallery_uncategorizedRoot => '未分类（图库根）';

  @override
  String get localGallery_externalSourceChip => '外部';

  @override
  String get localGallery_categoryFilterHint => '搜索分类…';

  @override
  String localGallery_copySuccess(Object count) {
    return '已复制 $count 张图片';
  }

  @override
  String get localGallery_copyFailed => '复制图片失败';

  @override
  String get localGallery_confirmCopyContent => '将把图片复制到目标文件夹。请确认操作。';

  @override
  String get localGallery_categoryDeleteContent => '确定要删除此分类吗？文件夹及其内容将被保留。';

  @override
  String get localGallery_protectedDeleteCategoryTitle => '保护模式：确认删除分类';

  @override
  String get localGallery_protectedDeleteCategoryContent =>
      '将删除此分类记录，文件夹及内容会保留。请再次确认。';

  @override
  String get localGallery_confirmDelete => '确认删除';

  @override
  String get localGallery_confirmMoveImageTitle => '保护模式：确认移动图片';

  @override
  String get localGallery_confirmMoveImageContent => '将把图片移动到目标分类文件夹。请确认不是误拖拽。';

  @override
  String get localGallery_confirmMove => '确认移动';

  @override
  String get localGallery_imageMovedToCategory => '图片已移动到分类';

  @override
  String get localGallery_categoriesSynced => '分类已与文件夹同步';

  @override
  String get localGallery_saveDirectoryNotSet => '未设置保存目录';

  @override
  String get localGallery_folderNotFound => '文件夹不存在';

  @override
  String localGallery_openFolderFailed(Object error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get localGallery_protectedDeleteTitle => '保护模式：再次确认删除';

  @override
  String localGallery_protectedDeleteImagesContent(Object count) {
    return '将永久删除 $count 张本地图片文件。此操作无法撤销。';
  }

  @override
  String get localGallery_protectedBulkMoveTitle => '保护模式：确认批量移动';

  @override
  String localGallery_protectedBulkMoveContent(Object count) {
    return '将移动 $count 张本地图片文件到目标文件夹。请确认不是误操作。';
  }

  @override
  String localGallery_importParamsFailed(Object error) {
    return '导入参数失败: $error';
  }

  @override
  String localGallery_protectedDeleteImageContent(Object name) {
    return '将永久删除图片「$name」。此操作无法撤销。';
  }

  @override
  String get localGallery_saveZipArchive => '保存压缩包';

  @override
  String localGallery_packingImages(Object count) {
    return '正在打包 $count 张图片...';
  }

  @override
  String localGallery_packedImages(Object count) {
    return '已打包 $count 张图片';
  }

  @override
  String get localGallery_packFailed => '打包失败';

  @override
  String get localGallery_imageFileMissing => '图片文件不存在';

  @override
  String get localGallery_sentToImageToImage => '图片已发送到图生图';

  @override
  String localGallery_sendFailed(Object error) {
    return '发送失败: $error';
  }

  @override
  String localGallery_sendToKritaFailed(Object error) {
    return '发送到 Krita 失败: $error';
  }

  @override
  String get localGallery_sendToImg2Img => '发送到图生图';

  @override
  String get localGallery_sendToStyleTransfer => '发送到风格迁移';

  @override
  String get localGallery_sendToPreciseReference => '发送到精准参考';

  @override
  String get localGallery_sendToKrita => '发送到 Krita';

  @override
  String get localGallery_importImageMetadata => '导入图片元数据';

  @override
  String get localGallery_copyPrompt => '复制 Prompt';

  @override
  String get localGallery_dragToShare => '拖拽以分享';

  @override
  String galleryDragCount(int count) {
    return '$count 张';
  }

  @override
  String get localGallery_moveToRoot => '移至根目录';

  @override
  String get localGallery_withMetadata => '有元数据';

  @override
  String get localGallery_skipped => '跳过';

  @override
  String get localGallery_clearFilters => '清除筛选';

  @override
  String get slideshow_of => '/';

  @override
  String get slideshow_play => '播放';

  @override
  String get slideshow_pause => '暂停';

  @override
  String get slideshow_previous => '上一张';

  @override
  String get slideshow_next => '下一张';

  @override
  String get slideshow_exit => '退出 (Esc)';

  @override
  String get slideshow_noImages => '没有可显示的图片';

  @override
  String get slideshow_keyboardHint => '使用 ← → 导航，空格键播放/暂停，Esc 退出';

  @override
  String get comparison_noImages => '没有可显示的图片';

  @override
  String get comparison_tooManyImages => '图片数量过多';

  @override
  String get comparison_maxImages => '最多支持对比4张图片';

  @override
  String get comparison_close => '关闭对比';

  @override
  String get comparison_zoomHint => '捏合或滚动可独立缩放';

  @override
  String get comparison_loadError => '加载图片失败';

  @override
  String get localGallery_group_today => '今天';

  @override
  String get localGallery_group_yesterday => '昨天';

  @override
  String localGallery_groupImageCount(int count, String formatted) {
    return '$formatted 张';
  }

  @override
  String localGallery_imageCountLabel(int count, String formatted) {
    return '$formatted 张';
  }

  @override
  String get localGallery_selectGroup => '选择整组';

  @override
  String get localGallery_inspectorTitle => '详情';

  @override
  String localGallery_inspectorPosition(String index, String total) {
    return '$index / $total';
  }

  @override
  String get localGallery_inspectorEmpty => '选择一张图片查看详情';

  @override
  String get localGallery_inspectorEmptyHint => '双击或按空格键打开大图';

  @override
  String get localGallery_hideInspector => '收起详情面板';

  @override
  String get localGallery_showInspector => '显示详情面板';

  @override
  String get localGallery_reuseParams => '复用参数';

  @override
  String get localGallery_actionImg2Img => '图生图';

  @override
  String get localGallery_actionStyleTransfer => '风格迁移';

  @override
  String get localGallery_actionPreciseReference => '精准参考';

  @override
  String get localGallery_actionSaveReference => '存入参考库';

  @override
  String get localGallery_actionKrita => 'Krita';

  @override
  String localGallery_selectedImages(String count) {
    return '已选 $count 张';
  }

  @override
  String get localGallery_sortDescending => '降序';

  @override
  String get localGallery_sortAscending => '升序';

  @override
  String get localGallery_moreActions => '更多';

  @override
  String get localGallery_thumbnailSize => '缩略图大小';

  @override
  String get localGallery_naiOnlyChip => '仅 NAI 图片';

  @override
  String get localGallery_modelLabel => '模型';

  @override
  String get localGallery_allVersions => '全部';

  @override
  String get localGallery_allVariants => '全部变体';

  @override
  String get localGallery_dateRangeChip => '日期范围';

  @override
  String get localGallery_groupByDay => '按天分组';

  @override
  String get localGallery_groupByMonth => '按月分组';

  @override
  String get localGallery_groupNone => '不分组';

  @override
  String get localGallery_groupModeTooltip => '按时间分组';

  @override
  String get localGallery_sectionLibrary => '资料库';

  @override
  String get localGallery_sectionCollections => '收藏集';

  @override
  String get localGallery_sectionFolders => '文件夹';

  @override
  String get localGallery_uncategorizedFolder => '未分类文件夹';

  @override
  String localGallery_indexSynced(String count) {
    return '索引已同步 · $count';
  }

  @override
  String localGallery_cannotOpenFolder(Object error) {
    return '无法打开文件夹: $error';
  }

  @override
  String get localGallery_firstTimeTipTitle => '💡 使用提示';

  @override
  String get localGallery_firstTimeTipContent =>
      '右键点击（桌面端）或长按（移动端）图片可以：\n\n• 复制 Prompt\n• 复制 Seed\n• 查看完整元数据';

  @override
  String get localGallery_gotIt => '知道了';

  @override
  String get localGallery_undone => '已撤销';

  @override
  String get localGallery_redone => '已重做';

  @override
  String get localGallery_confirmBulkDelete => '确认批量删除';

  @override
  String localGallery_confirmBulkDeleteContent(Object count) {
    return '确定要删除选中的 $count 张图片吗？\n\n图片会立即从画廊消失，文件将在下次启动时彻底清理（本次会话内可撤销）。';
  }

  @override
  String localGallery_deletedToPool(Object count) {
    return '已删除 $count 张图片，下次启动时彻底清理。';
  }

  @override
  String get localGallery_trashTitle => '删除池';

  @override
  String get localGallery_trashEmpty => '删除池是空的';

  @override
  String get localGallery_trashHint => '池内文件仍在磁盘上，下次启动时彻底删除；恢复后立即回到图库。';

  @override
  String localGallery_trashCount(Object count) {
    return '$count 项';
  }

  @override
  String get localGallery_trashRestore => '恢复';

  @override
  String get localGallery_trashRestoreAll => '全部恢复';

  @override
  String get localGallery_trashRestoreFailed => '恢复失败';

  @override
  String localGallery_trashRestored(Object count) {
    return '已恢复 $count 张图片';
  }

  @override
  String get localGallery_trashDeleteAll => '彻底删除全部';

  @override
  String localGallery_trashDeleteAllConfirm(Object count) {
    return '将立即物理删除池内全部 $count 个文件，不可恢复。';
  }

  @override
  String localGallery_trashDeletedForever(Object count) {
    return '已彻底删除 $count 个文件';
  }

  @override
  String get localGallery_trashFileMissing => '文件已不在磁盘上';

  @override
  String localGallery_movedImages(Object count) {
    return '已移动 $count 张图片';
  }

  @override
  String get localGallery_moveImagesFailed => '移动图片失败';

  @override
  String localGallery_addedToCollection(Object count, Object name) {
    return '已添加 $count 张图片到集合「$name」';
  }

  @override
  String get localGallery_addToCollectionFailed => '添加图片到集合失败';

  @override
  String get localGallery_removeFromCollection => '移出集合';

  @override
  String localGallery_removedFromCollection(Object count, Object name) {
    return '已从集合「$name」移除 $count 张图片';
  }

  @override
  String get localGallery_notInCollection => '所选图片不在该集合中';

  @override
  String localGallery_removedFromFavorites(Object count) {
    return '已从「收藏」移除 $count 张图片';
  }

  @override
  String get localGallery_alreadyInCollection => '所选图片已在该集合中';

  @override
  String get brushPreset_selectHint => '双击选择此笔刷预设';

  @override
  String get brushPreset_pencil => '铅笔';

  @override
  String get brushPreset_fine => '细笔';

  @override
  String get brushPreset_standard => '标准笔刷';

  @override
  String get brushPreset_soft => '软笔刷';

  @override
  String get brushPreset_airbrush => '喷枪';

  @override
  String get brushPreset_marker => '马克笔';

  @override
  String get brushPreset_thick => '粗笔刷';

  @override
  String get brushPreset_smudge => '涂抹笔刷';

  @override
  String bulkProgress_progress(Object current, Object total) {
    return '正在处理 $current/$total';
  }

  @override
  String bulkProgress_success(Object count) {
    return '$count 项成功';
  }

  @override
  String bulkProgress_failed(Object count) {
    return '$count 项失败';
  }

  @override
  String get bulkProgress_errors => '错误：';

  @override
  String bulkProgress_moreErrors(Object count) {
    return '...还有 $count 个错误';
  }

  @override
  String bulkProgress_completed(Object count) {
    return '已完成 $count 项';
  }

  @override
  String bulkProgress_completedWithErrors(Object success, Object failed) {
    return '$success 项成功，$failed 项失败';
  }

  @override
  String get bulkProgress_title_delete => '删除图片中';

  @override
  String get bulkProgress_title_export => '导出元数据中';

  @override
  String get bulkProgress_title_metadataEdit => '编辑元数据中';

  @override
  String get bulkProgress_title_addToCollection => '添加到收集中';

  @override
  String get bulkProgress_title_removeFromCollection => '从集合中移除';

  @override
  String get bulkProgress_title_toggleFavorite => '更新收藏中';

  @override
  String get bulkProgress_title_default => '处理中';

  @override
  String bulkProgress_errorDeleteFailed(String error) {
    return '删除图片失败：$error';
  }

  @override
  String get bulkProgress_errorNoImagesToExport => '没有可导出的图片';

  @override
  String get bulkProgress_errorExportFailed => '导出失败';

  @override
  String bulkProgress_errorExportFailedWithDetails(String error) {
    return '导出失败：$error';
  }

  @override
  String get bulkProgress_errorNoMetadataChanges => '请至少输入一个要添加或移除的标签';

  @override
  String bulkProgress_errorMetadataEditFailed(String error) {
    return '编辑图片元数据失败：$error';
  }

  @override
  String bulkProgress_errorFavoriteFailed(String error) {
    return '更新收藏状态失败：$error';
  }

  @override
  String get bulkProgress_errorNoImagesForCollection => '没有可添加到集合的图片';

  @override
  String bulkProgress_errorAddToCollectionFailed(String error) {
    return '将图片添加到集合失败：$error';
  }

  @override
  String get bulkProgress_errorNothingToUndo => '没有可撤销的操作';

  @override
  String bulkProgress_errorUndoFailed(String error) {
    return '撤销失败：$error';
  }

  @override
  String get bulkProgress_errorNothingToRedo => '没有可重做的操作';

  @override
  String bulkProgress_errorRedoFailed(String error) {
    return '重做失败：$error';
  }

  @override
  String get collectionSelect_dialogTitle => '选择集合';

  @override
  String get collectionSelect_removeTitle => '从集合移除图片';

  @override
  String collectionSelect_memberCount(Object n) {
    return '选中 $n 张在此集合';
  }

  @override
  String get collectionSelect_noSelectedInCollection => '无选中图片在此集合';

  @override
  String collectionSelect_memberCountInFavorites(Object n) {
    return '选中 $n 张在此收藏';
  }

  @override
  String get collectionSelect_filterHint => '搜索集合...';

  @override
  String get collectionSelect_noCollections => '暂无集合';

  @override
  String get collectionSelect_createCollectionHint => '请先创建一个集合';

  @override
  String get collectionSelect_noFilterResults => '没有找到匹配的集合';

  @override
  String collectionSelect_imageCount(int count) {
    return '$count 张图片';
  }

  @override
  String get autocomplete_categoryCharacter => '角色';

  @override
  String get autocomplete_categoryCopyright => '版权';

  @override
  String get autocomplete_categoryArtist => '艺术家';

  @override
  String get autocomplete_categoryMeta => '元数据';

  @override
  String get autocomplete_categoryContributor => '贡献者';

  @override
  String get autocomplete_categorySpecies => '物种';

  @override
  String get autocomplete_categoryLore => '设定';

  @override
  String get autocomplete_categoryLibrary => '词库';

  @override
  String get autocomplete_categoryGeneral => '通用';

  @override
  String get promptToken_webCalibration => '网页端校准';

  @override
  String get promptToken_prompt => '提示词';

  @override
  String get promptToken_qualityPreset => '质量预设';

  @override
  String get promptToken_character => '角色';

  @override
  String get promptToken_negativePrompt => '负面提示词';

  @override
  String get promptToken_negativePreset => '负面预设';

  @override
  String get promptToken_characterNegative => '角色负面';

  @override
  String get common_rename => '重命名';

  @override
  String get tagLibrary_tags => '标签';

  @override
  String get settings_network => '网络';

  @override
  String get settings_enableProxy => '启用代理';

  @override
  String get settings_proxyEnabled => '已启用';

  @override
  String get settings_proxyDisabled => '直接连接网络';

  @override
  String get settings_proxyTrafficDisclosure =>
      '代理启用后，NovelAI API 流量（包括认证请求）会通过系统代理或手动代理发送。只使用你信任的代理。';

  @override
  String get settings_proxyMode => '代理模式';

  @override
  String get settings_proxyModeAuto => '自动检测系统代理';

  @override
  String get settings_proxyModeManual => '手动配置';

  @override
  String get settings_auto => '自动';

  @override
  String get settings_manual => '手动';

  @override
  String get settings_proxyHost => '代理地址';

  @override
  String get settings_proxyPort => '端口';

  @override
  String get settings_proxyNotDetected => '未检测到系统代理';

  @override
  String get settings_testConnection => '测试连接';

  @override
  String get settings_testConnectionHint => '点击测试代理是否可用';

  @override
  String settings_testSuccess(Object latency) {
    return '连接成功 (${latency}ms)';
  }

  @override
  String settings_testFailed(Object error) {
    return '连接失败: $error';
  }

  @override
  String get settings_proxyRestartHint => '代理设置已更改，建议重启应用';

  @override
  String get tagLibrary_addToLibrary => '收藏到词库';

  @override
  String get tagLibrary_uncategorized => '未分类';

  @override
  String get tagLibrary_contentPreview => '内容预览';

  @override
  String get settings_enablePromptWeightScroll => '滚轮调整提示词权重';

  @override
  String get settings_enablePromptWeightScrollSubtitle =>
      '选中提示词时，按住所选修饰键 + 滚轮调整权重；裸滚轮照常翻页';

  @override
  String get settings_weightScrollModifierAlt => 'Alt';

  @override
  String get settings_weightScrollModifierCtrl => 'Ctrl';

  @override
  String get settings_weightScrollModifierShift => 'Shift';

  @override
  String get settings_weightScrollModifierNone => '无（旧行为）';

  @override
  String get unit_seconds => '秒';

  @override
  String get settings_notificationSound => '完成音效';

  @override
  String get settings_notificationSoundSubtitle => '仅在窗口失焦时播放生成完成音效';

  @override
  String get settings_notificationCustomSound => '自定义音效';

  @override
  String get settings_notificationSelectSound => '选择音效';

  @override
  String get settings_notificationResetSound => '恢复默认';

  @override
  String get resetToDefault => '重置为默认';

  @override
  String get metadataImport_title => '选择要套用的参数';

  @override
  String get metadataImport_promptsSection => '提示词';

  @override
  String get metadataImport_generationSection => '生成参数';

  @override
  String get metadataImport_selectAll => '全选';

  @override
  String get metadataImport_promptsOnly => '仅提示词';

  @override
  String get metadataImport_generationOnly => '仅参数';

  @override
  String get metadataImport_clear => '清空';

  @override
  String get metadataImport_prompt => '正向提示词';

  @override
  String get metadataImport_mainPrompt => '主提示词';

  @override
  String metadataImport_qualityTagsCount(int count) {
    return '质量词 ($count个)';
  }

  @override
  String get metadataImport_negativePrompt => '负向提示词';

  @override
  String get metadataImport_characterPrompts => '多角色提示词';

  @override
  String metadataImport_characterPromptsCount(int count) {
    return '角色提示词 ($count个)';
  }

  @override
  String metadataImport_characterIndex(int index, Object text) {
    return '角色$index: $text';
  }

  @override
  String get metadataImport_referenceSection => '参考图';

  @override
  String metadataImport_countUnit(int count) {
    return '$count个';
  }

  @override
  String metadataImport_preciseReferenceCount(int count) {
    return '精准参考 ($count个)';
  }

  @override
  String metadataImport_vibeDetail(Object name, Object strength, Object info) {
    return '$name (强度 $strength%, 信息提取 $info%)';
  }

  @override
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  ) {
    return '参考$index: $type (强度 $strength%, 保真 $fidelity%)';
  }

  @override
  String get metadataImport_seed => '种子 (Seed)';

  @override
  String get metadataImport_steps => '步数 (Steps)';

  @override
  String get metadataImport_scale => '提示词引导';

  @override
  String get metadataImport_size => '尺寸 (Size)';

  @override
  String get metadataImport_sampler => '采样器 (Sampler)';

  @override
  String get metadataImport_model => '模型 (Model)';

  @override
  String get metadataImport_smea => 'SMEA';

  @override
  String get metadataImport_smeaDyn => 'SMEA Dyn';

  @override
  String get metadataImport_noiseSchedule => '噪声计划';

  @override
  String get metadataImport_cfgRescale => '提示词引导重缩放';

  @override
  String get metadataImport_qualityToggle => '质量标签';

  @override
  String get metadataImport_ucPreset => 'UC 预设';

  @override
  String get metadataImport_noData => '（无数据）';

  @override
  String metadataImport_selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get metadataImport_noDataFound => '未找到 NovelAI 元数据';

  @override
  String metadataImport_appliedCount(int count) {
    return '已应用 $count 项参数';
  }

  @override
  String get metadataImport_appliedTitle => '元数据已应用';

  @override
  String get metadataImport_appliedDescription => '以下参数已应用到当前设置：';

  @override
  String get metadataImport_charactersCount => '个角色';

  @override
  String get shortcut_context_global => '全局';

  @override
  String get shortcut_context_generation => '生成页面';

  @override
  String get shortcut_context_gallery => '画廊列表';

  @override
  String get shortcut_context_viewer => '图片查看器';

  @override
  String get shortcut_context_settings => '设置';

  @override
  String get shortcut_context_input => '输入框';

  @override
  String get shortcut_action_navigate_to_generation => '生成页面';

  @override
  String get shortcut_action_navigate_to_local_gallery => '本地画廊';

  @override
  String get shortcut_action_navigate_to_online_gallery => '在线画廊';

  @override
  String get shortcut_action_navigate_to_tag_library => '块库页面';

  @override
  String get shortcut_action_navigate_to_statistics => '统计页面';

  @override
  String get shortcut_action_navigate_to_settings => '设置页面';

  @override
  String get shortcut_action_generate_image => '生成图像';

  @override
  String get shortcut_action_cancel_generation => '取消生成';

  @override
  String get shortcut_action_clear_prompt => '清空提示词';

  @override
  String get shortcut_action_toggle_prompt_mode => '切换正/负面模式';

  @override
  String get shortcut_action_open_tag_library => '打开块库';

  @override
  String get shortcut_action_save_image => '保存图像';

  @override
  String get shortcut_action_upscale_image => '放大图像';

  @override
  String get shortcut_action_copy_image => '复制图像';

  @override
  String get shortcut_action_fullscreen_preview => '全屏预览';

  @override
  String get shortcut_action_open_params_panel => '打开参数面板';

  @override
  String get shortcut_action_open_history_panel => '打开历史面板';

  @override
  String get shortcut_action_reuse_params => '复用参数';

  @override
  String get shortcut_action_previous_image => '上一张';

  @override
  String get shortcut_action_next_image => '下一张';

  @override
  String get shortcut_action_zoom_in => '放大';

  @override
  String get shortcut_action_zoom_out => '缩小';

  @override
  String get shortcut_action_reset_zoom => '重置缩放';

  @override
  String get shortcut_action_toggle_fullscreen => '全屏切换';

  @override
  String get shortcut_action_close_viewer => '关闭查看器';

  @override
  String get shortcut_action_toggle_favorite => '收藏切换';

  @override
  String get shortcut_action_copy_prompt => '复制Prompt';

  @override
  String get shortcut_action_reuse_gallery_params => '复用参数';

  @override
  String get shortcut_action_delete_image => '删除图片';

  @override
  String get shortcut_action_previous_page => '向上翻一屏';

  @override
  String get shortcut_action_next_page => '向下翻一屏';

  @override
  String get shortcut_action_refresh_gallery => '刷新';

  @override
  String get shortcut_action_focus_search => '搜索聚焦';

  @override
  String get shortcut_action_enter_selection_mode => '全选';

  @override
  String get shortcut_action_clear_filter => '清除筛选';

  @override
  String get shortcut_action_toggle_category_panel => '切换分类面板';

  @override
  String get shortcut_action_jump_to_date => '跳转到日期';

  @override
  String get shortcut_action_open_folder => '打开文件夹';

  @override
  String get shortcut_action_minimize_to_tray => '最小化到托盘';

  @override
  String get shortcut_action_quit_app => '退出应用';

  @override
  String get shortcut_action_show_shortcut_help => '显示快捷键帮助';

  @override
  String get shortcut_action_toggle_theme => '切换主题';

  @override
  String get shortcut_settings_title => '键盘快捷键';

  @override
  String get shortcut_settings_enable => '启用快捷键';

  @override
  String get shortcut_settings_show_badges => '显示快捷键标识';

  @override
  String get shortcut_settings_show_in_tooltips => '在提示中显示';

  @override
  String get shortcut_settings_reset_all => '重置全部为默认';

  @override
  String get shortcut_settings_search => '搜索快捷键...';

  @override
  String get shortcut_settings_press_key => '按下按键组合...';

  @override
  String get shortcut_help_title => '快捷键帮助';

  @override
  String get shortcut_help_search => '搜索快捷键...';

  @override
  String get shortcut_help_all => '全部';

  @override
  String get shortcut_help_fabTooltip => '快捷键帮助 (F1)';

  @override
  String get shortcut_editor_recordingInline => '按快捷键...';

  @override
  String get shortcut_editor_pressEscToCancel => '按 Esc 取消';

  @override
  String get shortcut_editor_clickToRecord => '点击开始录制';

  @override
  String shortcut_editor_conflictWith(Object action) {
    return '此快捷键与 \"$action\" 冲突';
  }

  @override
  String get drop_hint => '拖拽图片到这里';

  @override
  String get drop_img2img => '图生图';

  @override
  String get drop_vibeTransfer => '风格迁移';

  @override
  String get drop_characterReference => '精准参考';

  @override
  String get drop_unsupportedFormat => '不支持的文件格式';

  @override
  String get drop_addedToImg2Img => '已添加到图生图';

  @override
  String get drop_addedToVibe => '已添加到风格迁移';

  @override
  String drop_addedMultipleToVibe(int count) {
    return '已添加 $count 个风格参考';
  }

  @override
  String get drop_addedToCharacterRef => '已添加到精准参考';

  @override
  String get drop_vibeDetected => '检测到预编码 Vibe（可节省 2 Anlas）';

  @override
  String get drop_reuseVibe => '复用 Vibe';

  @override
  String get drop_useAsRawImage => '作为原始图片';

  @override
  String get drop_dragToImg2ImgOrOther => '拖拽到图生图或其他区域';

  @override
  String get preciseRef_title => '精准参考';

  @override
  String get preciseRef_subtitle => '将生成绑定到角色或风格参考';

  @override
  String get preciseRef_description => '添加参考图并设置类型和参数，可同时使用多个参考。';

  @override
  String get preciseRef_addReference => '添加参考图';

  @override
  String get preciseRef_clearAll => '清空全部';

  @override
  String get preciseRef_remove => '移除';

  @override
  String get preciseRef_referenceType => '参考类型';

  @override
  String get preciseRef_strength => '参考强度';

  @override
  String get preciseRef_fidelity => '保真度';

  @override
  String get preciseRef_v4Only => '此功能需要 V4+ 模型';

  @override
  String get preciseRef_typeCharacter => '角色';

  @override
  String get preciseRef_typeStyle => '风格';

  @override
  String get preciseRef_typeCharacterAndStyle => '角色+风格';

  @override
  String get preciseRef_costHint => '使用精准参考会消耗额外点数';

  @override
  String get preciseRef_costBadge => '消耗点数';

  @override
  String get preciseRef_dropToAdd => '松开后添加精准参考';

  @override
  String get preciseRef_dropNoReadableImage => '拖入源未提供可读取的图片文件或图片链接';

  @override
  String preciseRef_addedCount(int count) {
    return '已添加 $count 个精准参考';
  }

  @override
  String preciseRef_removedCount(int count) {
    return '已删除 $count 个精准参考';
  }

  @override
  String get vibeLibrary_title => 'Vibe 库';

  @override
  String get vibeLibrary_uncategorized => '未分类';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '成功导入 $count 个 Vibe';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return '导入完成: $success 成功, $failed 失败';
  }

  @override
  String get vibeLibrary_save => '保存到库';

  @override
  String get vibeLibrary_import => '导入 Vibe';

  @override
  String get vibeLibrary_sendToGeneration => '发送到生成';

  @override
  String get vibeLibrary_maxVibesReached => '已达到最大数量 (16张)';

  @override
  String get vibeLibrary_bundleReadFailed => '读取 Bundle 文件失败，使用单文件模式';

  @override
  String categoryError_loadFailed(String error) {
    return '加载分类失败：$error';
  }

  @override
  String categoryError_syncFailed(String error) {
    return '同步分类失败：$error';
  }

  @override
  String get categoryError_nameEmpty => '分类名称不能为空';

  @override
  String get categoryError_parentNotFound => '父分类不存在';

  @override
  String categoryError_createFailed(String error) {
    return '创建分类失败：$error';
  }

  @override
  String get categoryError_notFound => '分类不存在';

  @override
  String categoryError_renameFailed(String error) {
    return '重命名分类失败：$error';
  }

  @override
  String get categoryError_invalidMove => '不能将分类移动到它的子孙分类下';

  @override
  String categoryError_moveFailed(String error) {
    return '移动分类失败：$error';
  }

  @override
  String get categoryError_hasSubcategories => '该分类包含子分类，请先删除子分类。';

  @override
  String categoryError_deleteFailed(String error) {
    return '删除分类失败：$error';
  }

  @override
  String categoryError_moveImageFailed(String error) {
    return '移动图片失败：$error';
  }

  @override
  String categoryError_moveImagesFailed(String error) {
    return '批量移动图片失败：$error';
  }

  @override
  String categoryError_reorderFailed(String error) {
    return '重新排序分类失败：$error';
  }

  @override
  String get vibe_export_title => '导出 Vibe';

  @override
  String get vibe_selector_recent => '最近使用';

  @override
  String vibe_export_dialogTitle(int count) {
    return '导出 $count 个 Vibes';
  }

  @override
  String get vibe_export_chooseMethod => '选择导出方式';

  @override
  String get vibe_export_asBundle => '打包导出';

  @override
  String get vibe_export_individually => '逐个导出';

  @override
  String get vibe_export_noData => '没有可导出的数据';

  @override
  String get vibe_export_success => '导出成功';

  @override
  String get vibe_export_failed => '导出失败';

  @override
  String vibe_export_skipped(int count) {
    return '跳过了 $count 个无数据 vibes';
  }

  @override
  String vibe_export_bundleSuccess(int count) {
    return '已导出 Bundle: $count 个 vibes';
  }

  @override
  String get vibe_export_selectToEmbed => '选择要嵌入的 vibes';

  @override
  String get vibe_export_pngRequired => '需要 PNG 文件';

  @override
  String get vibe_export_noEmbeddableData => '没有可嵌入的数据';

  @override
  String vibe_export_embedSuccess(int count) {
    return '已嵌入 $count 个 vibes 到图片';
  }

  @override
  String get vibe_export_embedFailed => '嵌入失败';

  @override
  String get vibe_embedToImage => '嵌入到图片';

  @override
  String get vibe_import_noEncodingData => '无编码数据';

  @override
  String get vibe_import_encodingCost => '编码将消耗 2 Anlas';

  @override
  String get vibe_import_confirmCost => '继续并消耗 Anlas？';

  @override
  String get vibe_import_encodeNow => '立即编码 (2 Anlas)';

  @override
  String get vibe_addImageOnly => '仅添加图片';

  @override
  String get vibe_import_autoSave => '自动保存到库';

  @override
  String get vibe_import_encodingFailed => '编码失败';

  @override
  String get vibe_import_encodingFailedMessage => 'Vibe 编码失败，是否继续添加未编码图片？';

  @override
  String get vibe_import_encodingInProgress => '编码中...';

  @override
  String get vibe_import_encodingComplete => '编码完成';

  @override
  String get vibe_import_partialFailed => '部分编码失败';

  @override
  String get vibe_import_timeout => '编码超时';

  @override
  String get vibe_import_fileParseFailed => '解析文件失败';

  @override
  String get vibe_import_fileSelectionFailed => '文件选择失败';

  @override
  String get vibe_import_importFailed => '导入失败';

  @override
  String get vibe_saveToLibrary_title => '保存到库';

  @override
  String get vibe_saveToLibrary_strength => '参考强度';

  @override
  String get vibe_saveToLibrary_infoExtracted => '信息提取';

  @override
  String vibe_saveToLibrary_saving(int count) {
    return '正在保存 $count 个 vibes';
  }

  @override
  String get vibe_saveToLibrary_saveFailed => '保存到库失败';

  @override
  String vibe_saveToLibrary_savingCount(int count) {
    return '正在保存 $count 个 vibes';
  }

  @override
  String get vibe_saveToLibrary_nameLabel => '名称';

  @override
  String get vibe_saveToLibrary_nameHint => '输入 vibe 名称';

  @override
  String vibe_saveToLibrary_mixed(int saved, int reused) {
    return '已保存 $saved 个，复用 $reused 个';
  }

  @override
  String vibe_saveToLibrary_saved(int count) {
    return '已保存 $count 个到库';
  }

  @override
  String vibe_saveToLibrary_reused(int count) {
    return '从库复用 $count 个';
  }

  @override
  String get vibe_saveToLibrary_saveAsBundle => '保存为 Bundle';

  @override
  String vibe_saveToLibrary_saveAsBundleDescription(int count) {
    return '将 $count 个 Vibe 保存为一个 Bundle';
  }

  @override
  String get vibe_saveToLibrary_tagHint => '输入标签后点击添加';

  @override
  String get vibe_maxReached => '已达到最大数量 (16张)';

  @override
  String vibe_addedCount(int count) {
    return '已添加 $count 个 vibes';
  }

  @override
  String get vibe_statusEncoded => '已编码';

  @override
  String get vibe_statusEncoding => '编码中...';

  @override
  String get vibe_statusPendingEncode => '待编码 (2 Anlas)';

  @override
  String get vibe_encodeDialogTitle => '确认编码 Vibe';

  @override
  String get vibe_encodeDialogMessage => '是否编码此图片以供生成使用？';

  @override
  String get vibe_encodeCostWarning => '此操作将消耗 2 Anlas（点数）';

  @override
  String get vibe_encodeButton => '编码';

  @override
  String get vibe_encodeSuccess => 'Vibe 编码成功！';

  @override
  String get vibe_encodeFailed => 'Vibe 编码失败，请重试';

  @override
  String vibe_encodeError(String error) {
    return '编码失败: $error';
  }

  @override
  String get shortcuts_customize => '自定义快捷键';

  @override
  String get selection_clear_selection => '清除选区';

  @override
  String get selection_invert_selection => '反转选区';

  @override
  String get selection_cut_to_layer => '剪切到新图层';

  @override
  String get selectAll => '全选';

  @override
  String get clearSelection => '清空';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 详情';

  @override
  String get shortcut_action_vibe_detail_rename => '重命名';

  @override
  String get tray_show => '显示窗口';

  @override
  String get tray_exit => '退出';

  @override
  String get settings_shortcutsSubtitle => '自定义键盘快捷键';

  @override
  String get settings_openFolder => '打开文件夹';

  @override
  String get settings_openFolderFailed => '打开文件夹失败';

  @override
  String get settings_vibePathSaved => 'Vibe 库路径已保存';

  @override
  String get settings_selectFolderFailed => '选择文件夹失败';

  @override
  String get settings_hivePathSaved => '数据存储路径已保存，重启后生效';

  @override
  String get settings_restartRequiredTitle => '需要重启应用';

  @override
  String get settings_changePathConfirm =>
      '更改数据存储路径后，需要重启应用才能生效。\\n\\n新路径将在下次启动时生效。是否继续？';

  @override
  String get settings_resetPathConfirm =>
      '重置数据存储路径后，需要重启应用才能生效。\\n\\n默认路径将在下次启动时生效。是否继续？';

  @override
  String get settings_kritaBridgeEnable => '启用本机桥接';

  @override
  String get settings_kritaBridgeDisabledText => '默认关闭；开启后只监听本机 127.0.0.1';

  @override
  String get settings_kritaBridgeStartingText => '正在启动本地桥接服务...';

  @override
  String get settings_kritaBridgeListeningText => '等待外部 Agent 或 Krita 连接';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita 插件已连接';

  @override
  String get settings_kritaBridgeErrorText => '启动失败，请查看错误信息';

  @override
  String get settings_kritaBridgeRegenerateSession => '重生成会话';

  @override
  String get settings_kritaBridgeDiscoveryFile => '发现文件';

  @override
  String get settings_kritaBridgeWaitingEndpoint => '等待本地 WebSocket 监听';

  @override
  String settings_kritaBridgeClient(Object client) {
    return '客户端：$client';
  }

  @override
  String get settings_fontScale => '字体大小';

  @override
  String get settings_fontScale_previewSmall => '光影落在画布上。';

  @override
  String get settings_fontScale_previewMedium => '色から物語が生まれる。';

  @override
  String get settings_fontScale_previewLarge => 'Let colors tell a story.';

  @override
  String get settings_fontScale_done => '完成';

  @override
  String get settings_historyClickBehavior => '历史记录点击行为';

  @override
  String get settings_historyClickBehavior_classic => '经典';

  @override
  String get settings_historyClickBehavior_classicDescription => '单击历史图片直接打开详情';

  @override
  String get settings_historyClickBehavior_linked => '官网式联动';

  @override
  String get settings_historyClickBehavior_linkedDescription =>
      '单击切换中央预览，双击或长按打开详情，并支持左右方向键浏览';

  @override
  String get settings_outputViewer => '输出查看器';

  @override
  String get settings_outputViewer_canvas => '自由画布';

  @override
  String get settings_outputViewer_canvasDescription =>
      'NAI5 官网式无限画布：全部生成图按批铺开，中键/Shift+左键平移、Ctrl+滚轮缩放、WASD/f/q 导航';

  @override
  String get settings_outputViewer_simple => '简单视图';

  @override
  String get settings_outputViewer_simpleDescription =>
      '经典居中/网格预览，适合低配置或习惯旧界面的场景';

  @override
  String get settings_canvasLockCamera => '锁定画布相机';

  @override
  String get settings_canvasLockCameraDescription =>
      '禁用滚轮缩放/平移、拖拽与 WASD 等手动相机输入；自动选中与跳转不受影响';

  @override
  String get settings_canvasReducedMotion => '减少画布动效';

  @override
  String get settings_canvasReducedMotionDescription => '飞行、缩放与惯性改为瞬时切换，降低动画负担';

  @override
  String get image_viewDetail => '查看详情';

  @override
  String get settings_defaultImagesPath =>
      '默认 (Documents/NAI_Launcher/images/)';

  @override
  String get settings_defaultHivePath => '默认 (./user-data/hive/)';

  @override
  String get settings_protectionFeatures => '保护功能';

  @override
  String get settings_stripMetadataTitle => '复制/拖拽时移除全部元数据';

  @override
  String get settings_stripMetadataSubtitle =>
      '生成净化副本，清除 PNG 文本块、EXIF 与 NAI 隐写水印，并避免拖拽暴露原始路径。';

  @override
  String get settings_confirmDangerousActionsTitle => '危险资产操作二次确认';

  @override
  String get settings_confirmDangerousActionsSubtitle =>
      '删除、移动、批量移动等本地资产操作会额外弹出保护确认。';

  @override
  String get settings_warnExternalImageSendTitle => '发送到外部服务前提示';

  @override
  String get settings_warnExternalImageSendSubtitle =>
      '把本地图片发送到 LLM、NovelAI、ComfyUI 等外部边界前进行确认。';

  @override
  String get settings_preventOverwriteTitle => '导出时避免覆盖已有文件';

  @override
  String get settings_preventOverwriteSubtitle => '导出/打包路径重名时自动编号，避免误覆盖原有资产。';

  @override
  String get settings_warnHighAnlasCostTitle => 'Anlas 高消耗警告';

  @override
  String settings_warnHighAnlasCostSubtitle(Object threshold) {
    return '单次生成预计消耗达到 $threshold Anlas 时，生成前弹出确认。';
  }

  @override
  String get settings_highAnlasCostThresholdTitle => 'Anlas 警告阈值';

  @override
  String get settings_setHighAnlasCostThresholdTitle => '设置 Anlas 警告阈值';

  @override
  String get settings_threshold => '阈值';

  @override
  String get settings_highAnlasCostThresholdHelper => '当单次生成预计消耗达到或超过该值时弹出确认。';

  @override
  String get settings_limitGenerationIntervalTitle => '限制生图频率';

  @override
  String get settings_limitGenerationIntervalSubtitle =>
      '开启后，两次生图开始时间必须至少间隔设定秒数；冷却期间生图按钮不可点击。';

  @override
  String get settings_generationIntervalTitle => '生图间隔';

  @override
  String settings_generationIntervalValue(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get settings_setGenerationIntervalTitle => '设置生图间隔';

  @override
  String get settings_generationIntervalHelper => '可设置 1–3600 秒，从开始执行生图时计时。';

  @override
  String get settings_generationIntervalJitterTitle => '间隔随机抖动';

  @override
  String settings_generationIntervalJitterValue(Object percent) {
    return '±$percent%';
  }

  @override
  String get settings_setGenerationIntervalJitterTitle => '设置间隔随机抖动';

  @override
  String get settings_generationIntervalJitterHelper =>
      '每次冷却在「基础间隔 ± 该百分比」内均匀随机取值，让生图节奏不那么机械。可设 0–50，0 为关闭。';

  @override
  String get settings_confirmExternalSendTitle => '保护模式：确认外部发送';

  @override
  String settings_confirmExternalSendContent(Object count, Object target) {
    return '即将把 $count 张本地图片发送到 $target。图片会离开本地应用边界，请确认这符合你的预期。';
  }

  @override
  String get settings_confirmExternalSend => '确认发送';

  @override
  String get settings_highAnlasCostTitle => 'Anlas 消耗提醒';

  @override
  String get settings_continueGeneration => '继续生成';

  @override
  String get dataSource_syncNow => '立即同步';

  @override
  String get settings_comfyUiEnable => '启用 ComfyUI 集成';

  @override
  String get settings_comfyUiDisabledSubtitle => '关闭后将隐藏本地超分等 ComfyUI 功能';

  @override
  String get settings_comfyUiServerUrl => '服务器地址';

  @override
  String get settings_comfyUiConnectionSuccess => '连接成功';

  @override
  String get settings_comfyUiConnectionSuccessFull => 'ComfyUI 连接成功';

  @override
  String settings_comfyUiConnectionFailed(Object error) {
    return '连接失败: $error';
  }

  @override
  String get settings_comfyUiConnected => '已连接';

  @override
  String get settings_comfyUiDisconnect => '断开';

  @override
  String get settings_comfyUiNoResponse => '服务器无响应';

  @override
  String get settings_comfyUiStatusDisconnected => '未连接';

  @override
  String get settings_comfyUiStatusConnecting => '正在连接...';

  @override
  String get settings_comfyUiStatusConnected => '已连接';

  @override
  String get settings_comfyUiStatusError => '连接异常';

  @override
  String get settings_comfyUiCategoryEnhance => '增强/超分';

  @override
  String get settings_comfyUiCategoryImg2Img => '图生图';

  @override
  String get settings_comfyUiCategoryInpaint => '重绘';

  @override
  String get settings_comfyUiCategoryTxt2Img => '文生图';

  @override
  String get settings_comfyUiCategoryCustom => '自定义';

  @override
  String get comfyWorkflow_seedvr2UpscaleName => 'SeedVR2 超分';

  @override
  String get comfyWorkflow_seedvr2UpscaleDescription =>
      '使用 SeedVR2 AI 模型进行超分辨率放大，效果优秀';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleName => 'SeedVR2 分块超分';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleDescription =>
      '使用 SeedVR2TilingUpscaler 分块放大，降低大图显存压力';

  @override
  String get comfyWorkflow_modelUpscaleName => 'ComfyUI 普通超分模型';

  @override
  String get comfyWorkflow_modelUpscaleDescription =>
      '使用 ComfyUI UpscaleModelLoader 加载普通超分模型，并用 Lanczos 修正最终倍率';

  @override
  String get comfyWorkflow_rtxUpscaleName => 'RTX 超分';

  @override
  String get comfyWorkflow_rtxUpscaleDescription =>
      '使用 Nvidia RTX Video Super Resolution 节点进行本地放大';

  @override
  String get comfyWorkflowSlot_inputImage => '输入图像';

  @override
  String get comfyWorkflowSlot_targetShortSide => '目标短边';

  @override
  String get comfyWorkflowSlot_targetLongSide => '目标长边';

  @override
  String get comfyWorkflowSlot_upscaleModel => '超分模型';

  @override
  String get comfyWorkflowSlot_randomSeed => '随机种子';

  @override
  String get comfyWorkflowSlot_outputImage => '输出图像';

  @override
  String get comfyWorkflowSlot_tileWidth => '图块宽度';

  @override
  String get comfyWorkflowSlot_tileHeight => '图块高度';

  @override
  String get comfyWorkflowSlot_tileUpscaleResolution => '图块超分分辨率';

  @override
  String get comfyWorkflowSlot_targetWidth => '目标宽度';

  @override
  String get comfyWorkflowSlot_targetHeight => '目标高度';

  @override
  String get comfyWorkflowSlot_scale => '放大倍数';

  @override
  String get comfyWorkflow_parameters => '参数设置';

  @override
  String get comfyWorkflow_selectImage => '点击选择图像';

  @override
  String comfyWorkflow_pickImageFailed(Object error) {
    return '选择图像失败: $error';
  }

  @override
  String get comfyWorkflow_useResult => '使用结果';

  @override
  String get comfyWorkflow_execute => '执行';

  @override
  String get comfyWorkflow_uploadingImage => '正在上传图像...';

  @override
  String get comfyWorkflow_queued => '排队中...';

  @override
  String comfyWorkflow_runningSteps(Object current, Object total) {
    return '处理中 $current/$total';
  }

  @override
  String get comfyWorkflow_processing => '处理中...';

  @override
  String get comfyWorkflow_complete => '执行完成';

  @override
  String comfyWorkflow_imageCount(Object count) {
    return '$count 张图像';
  }

  @override
  String get cacheStats_title => '缓存统计';

  @override
  String cacheStats_autoRefreshUpdated(Object time) {
    return '自动刷新 · 上次更新: $time';
  }

  @override
  String cacheStats_secondsAgo(Object seconds) {
    return '$seconds秒前';
  }

  @override
  String get cacheStats_resetStats => '重置统计';

  @override
  String get cacheStats_statsReset => '统计已重置';

  @override
  String get cacheStats_l1Memory => 'L1 内存缓存';

  @override
  String get cacheStats_l2Hive => 'L2 Hive 缓存';

  @override
  String get cacheStats_l3Sqlite => 'L3 SQLite 数据库';

  @override
  String get galleryCache_rescanTitle => '重新扫描画廊';

  @override
  String get galleryCache_rescanContent =>
      '这将执行以下操作：\n\n1. 检查数据一致性（标记不存在的文件）\n2. 扫描新文件和变更的文件\n3. 重新尝试历史上未提取成功的元数据（含失败记录）\n\n此操作不会清空已有数据，也不会删除图片文件。';

  @override
  String get galleryCache_startScan => '开始扫描';

  @override
  String get galleryCache_scanAlreadyRunning => '已有扫描任务在进行中，请等待完成后再试';

  @override
  String get galleryCache_preparing => '准备中...';

  @override
  String get galleryCache_noGalleryFolder => '未设置画廊目录';

  @override
  String galleryCache_scanningPhase(Object processed, Object total) {
    return '正在扫描 $processed/$total...';
  }

  @override
  String get galleryCache_scanComplete => '扫描完成';

  @override
  String galleryCache_scanFailed(Object error) {
    return '扫描失败: $error';
  }

  @override
  String get galleryCache_rescan => '重新扫描';

  @override
  String get galleryCache_rescanSubtitle => '检查数据一致性、查漏补缺、提取元数据';

  @override
  String get galleryCache_scanning => '正在扫描...';

  @override
  String get galleryCache_scanAction => '扫描';

  @override
  String get galleryCache_evictThumbnailsTitle => '清理缩略图缓存';

  @override
  String get galleryCache_evictThumbnailsSubtitle =>
      '按最近使用淘汰超限的 .thumbs 缩略图（不影响原图）';

  @override
  String get galleryCache_evictThumbnailsContent =>
      '将按最近使用时间淘汰超出上限的缩略图磁盘缓存。\n\n只删除 .thumbs 目录内的 .thumb.jpg 缩略图文件，不会删除或修改任何原图；被清理的缩略图会在下次浏览时按需重新生成。';

  @override
  String get galleryCache_evictThumbnailsStart => '开始清理';

  @override
  String get galleryCache_evictThumbnailsRunning => '正在清理缩略图缓存...';

  @override
  String galleryCache_evictThumbnailsDone(int count, String size) {
    return '已清理 $count 个缩略图，释放 $size MB';
  }

  @override
  String get galleryCache_evictThumbnailsNone => '缩略图缓存未超限，无需清理';

  @override
  String galleryCache_evictThumbnailsFailed(Object error) {
    return '清理缩略图缓存失败: $error';
  }

  @override
  String get workflowImport_title => '导入 ComfyUI 工作流';

  @override
  String workflowImport_step(Object current, Object title) {
    return '步骤 $current/4: $title';
  }

  @override
  String get workflowImport_stepFile => '选择工作流文件';

  @override
  String get workflowImport_stepInfo => '工作流信息';

  @override
  String get workflowImport_stepSlots => '确认槽位配置';

  @override
  String get workflowImport_stepDone => '完成导入';

  @override
  String get workflowImport_previous => '上一步';

  @override
  String get workflowImport_next => '下一步';

  @override
  String get workflowImport_finish => '完成导入';

  @override
  String get workflowImport_defaultName => '自定义工作流';

  @override
  String get workflowImport_fileInstructions =>
      '请选择 ComfyUI 导出的 workflow_api.json 文件。\n\n在 ComfyUI 中，点击菜单 → 导出 (API格式) 即可获得此文件。';

  @override
  String workflowImport_nodeCount(Object count) {
    return '$count 个节点';
  }

  @override
  String get workflowImport_reselect => '点击重新选择';

  @override
  String get workflowImport_selectWorkflowApi => '点击选择 workflow_api.json';

  @override
  String get workflowImport_invalidTopLevel => '文件格式无效：顶层应为 JSON 对象';

  @override
  String get workflowImport_noComfyNodes => '未检测到 ComfyUI 节点，请确认是 API 格式导出';

  @override
  String workflowImport_readFailed(Object error) {
    return '读取文件失败: $error';
  }

  @override
  String get workflowImport_analysisResult => '自动分析结果';

  @override
  String get workflowImport_inputImageNodes => '输入图像节点';

  @override
  String get workflowImport_adjustableParams => '可调参数';

  @override
  String get workflowImport_outputNodes => '输出节点';

  @override
  String get workflowImport_totalNodes => '总节点数';

  @override
  String workflowImport_countUnit(Object count) {
    return '$count 个';
  }

  @override
  String get workflowImport_workflowName => '工作流名称 *';

  @override
  String get workflowImport_description => '描述';

  @override
  String get workflowImport_category => '分类';

  @override
  String get workflowImport_slotsHint =>
      '勾选需要暴露给 UI 的槽位。输入/输出槽位建议保留；不需要用户调整的参数可以取消勾选。';

  @override
  String get workflowImport_inputSection => '输入';

  @override
  String get workflowImport_outputSection => '输出';

  @override
  String get workflowImport_parameterSection => '参数';

  @override
  String get workflowImport_noSlotsWarning =>
      '未检测到任何可用槽位。该工作流可能无法正常集成。\n请确认工作流中包含 LoadImage 和 SaveImage/SaveImageWebsocket 节点。';

  @override
  String workflowImport_nodeRef(Object node) {
    return '节点 $node';
  }

  @override
  String get workflowImport_confirmTitle => '即将导入以下工作流';

  @override
  String get workflowImport_name => '名称';

  @override
  String get workflowImport_inputSlots => '输入槽位';

  @override
  String get workflowImport_parameterSlots => '参数槽位';

  @override
  String get workflowImport_outputSlots => '输出槽位';

  @override
  String get workflowImport_afterImportHint => '导入后可在生成界面的 ComfyUI 工作流列表中使用。';

  @override
  String workflowImport_success(Object name) {
    return '工作流“$name”导入成功';
  }

  @override
  String get shortcut_settings_help => '查看快捷键帮助';

  @override
  String get shortcut_settings_show_in_menus => '在菜单中显示';

  @override
  String shortcut_settings_defaultShortcut(Object shortcut) {
    return '默认: $shortcut';
  }

  @override
  String get shortcut_settings_unassigned => '未设置';

  @override
  String get shortcut_settings_no_matches => '未找到匹配的快捷键';

  @override
  String get shortcut_settings_reset_all_title => '重置所有快捷键';

  @override
  String get shortcut_settings_reset_all_confirm =>
      '确定要将所有快捷键重置为默认设置吗？此操作不可撤销。';

  @override
  String get shortcut_settings_reset_to_default => '重置为默认';

  @override
  String get toast_previewUpdated => '预览图已更新';

  @override
  String toast_styleReferenceLimit(Object max) {
    return '风格参考已达上限 ($max 张)';
  }

  @override
  String get toast_noValidMaskIgnored => '没有检测到有效蒙版，保存结果已忽略。';

  @override
  String get toast_kritaBusy => 'Krita Bridge 正在生成，请等待当前任务结束';

  @override
  String get toast_kritaNotConnected => 'Krita 未连接，请先在设置中启用桥接并连接插件';

  @override
  String get toast_sentToKrita => '图片已发送到 Krita';

  @override
  String get toast_kritaUnsupportedImageFormat => '图片格式无法发送到 Krita，请换用常见图片格式';

  @override
  String get toast_dropNoReadableImageOrVibe => '拖入源未提供可读取的图片或 Vibe 文件';

  @override
  String get toast_contentCannotBeEmpty => '内容不能为空';

  @override
  String get toast_addedToLibrary => '已添加到词库';

  @override
  String toast_addFailed(Object error) {
    return '添加失败: $error';
  }

  @override
  String get toast_libraryNotLoaded => '词库未加载';

  @override
  String get toast_noValidTagContent => '没有有效的标签内容';

  @override
  String get toast_allTagsAlreadyExist => '所有标签已存在于词库中';

  @override
  String get toast_noAddableTags => '没有可添加的标签';

  @override
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped) {
    return '已添加 $added 个标签，跳过 $skipped 个重复标签';
  }

  @override
  String get toast_saveDirNotSet => '未设置保存目录';

  @override
  String toast_savedTo(Object path) {
    return '已保存到 $path';
  }

  @override
  String get toast_tagAlreadyExists => '标签已存在';

  @override
  String get toast_nameRequired => '请输入名称';

  @override
  String get toast_savedToVibeLibrary => '已保存到 Vibe 库';

  @override
  String get toast_saveBundleFailed => '保存组合失败';

  @override
  String get toast_saveEntryFailed => '保存条目失败';

  @override
  String get toast_imageDataUnavailable => '图像数据不可用，无法复制';

  @override
  String get toast_characterPromptCopied => '角色提示词已复制';

  @override
  String toast_copiedTitle(Object title) {
    return '$title已复制';
  }

  @override
  String get toast_unreadableDroppedImageSource => '拖入源未提供可读取的图片文件或图片链接';

  @override
  String toast_appendedStyleReferences(Object count) {
    return '已追加 $count 个风格参考';
  }

  @override
  String get toast_appendedPreencodedVibe => '已追加 1 个风格参考（复用预编码 Vibe）';

  @override
  String get toast_addedPreencodedVibe => '已添加风格参考（复用预编码 Vibe，节省 2 Anlas）';

  @override
  String toast_vibesMissingEncoding(Object count) {
    return '$count 个 Vibe 缺少编码数据，无法保存';
  }

  @override
  String toast_savedBundle(Object count) {
    return '已保存 Bundle ($count 个 Vibe)';
  }

  @override
  String toast_extractMetadataFailed(Object error) {
    return '提取元数据失败: $error';
  }

  @override
  String toast_processImageFailed(Object error) {
    return '处理图片失败: $error';
  }

  @override
  String get toast_savePreviewFailed => '保存预览图失败';

  @override
  String get common_justNow => '刚刚';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes分钟前';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours小时前';
  }

  @override
  String get common_saving => '保存中...';

  @override
  String get common_expand => '展开';

  @override
  String get common_collapse => '收起';

  @override
  String get detail_parsingMetadata => '正在解析元数据...';

  @override
  String get detail_noMetadata => '此图片无元数据';

  @override
  String get detail_metadata => '元数据';

  @override
  String get detail_modifiedTime => '修改时间';

  @override
  String get detail_fileSize => '文件大小';

  @override
  String get detail_noContent => '(无内容)';

  @override
  String get saveBlock_title => '保存为块';

  @override
  String get saveBlock_nameLabel => '块标题';

  @override
  String get saveBlock_nameHint => '输入块标题';

  @override
  String get saveBlock_nameRequired => '请输入块标题';

  @override
  String get saveBlock_selectContent => '请选择要保存的内容';

  @override
  String get saveBlock_negativeSuffix => '负向';

  @override
  String get saveBlock_saved => '已保存到块库';

  @override
  String detail_copyLabel(Object label) {
    return '复制$label';
  }

  @override
  String get comfyImport_detectedTitle => '检测到 ComfyUI 多角色提示词';

  @override
  String comfyImport_characterList(Object count) {
    return '角色列表 ($count)';
  }

  @override
  String get comfyImport_usePositionInfo => '使用位置信息';

  @override
  String get comfyImport_usePositionInfoSubtitle => '将 ComfyUI 区域映射为 NAI 角色位置';

  @override
  String comfyImport_convertCharacters(Object count) {
    return '转换 $count 个角色';
  }

  @override
  String get comfyImport_syntaxCouple => 'COUPLE 语法';

  @override
  String get comfyImport_syntaxAndMask => 'AND+MASK 语法';

  @override
  String get comfyImport_syntaxPipe => '竖线格式';

  @override
  String get comfyImport_syntaxUnknown => '未知语法';

  @override
  String get comfyImport_globalPrompt => '全局提示词';

  @override
  String get checkForUpdate => '检查更新';

  @override
  String get neverChecked => '从未检查';

  @override
  String lastCheckedAt(Object time) {
    return '上次检查: $time';
  }

  @override
  String get includePrereleaseUpdates => '包含预发布版本';

  @override
  String get includePrereleaseUpdatesDescription => '检查更新时包含 beta/alpha 版本';

  @override
  String get updateAvailable => '发现新版本';

  @override
  String get updateChecking => '正在检查更新...';

  @override
  String get updateDownloading => '正在下载更新...';

  @override
  String get updateInstalling => '正在启动安装器...';

  @override
  String get updateUpToDate => '已是最新版本';

  @override
  String get updateError => '检查更新失败';

  @override
  String get currentVersion => '当前版本';

  @override
  String get latestVersion => '最新版本';

  @override
  String get releaseNotes => '更新日志';

  @override
  String updateDownloadingProgress(Object percent) {
    return '正在下载更新包：$percent%';
  }

  @override
  String updateDownloadSizeSpeed(Object received, Object total, Object speed) {
    return '$received / $total · $speed';
  }

  @override
  String get updateDownloaded => '更新包已就绪';

  @override
  String updateDownloadedHint(Object version) {
    return '新版本 v$version 已下载并通过校验。安装将关闭应用，完成后会自动重启。';
  }

  @override
  String get updateInstallAndRestart => '安装并重启';

  @override
  String get updateInstallNow => '立即安装';

  @override
  String get updateInstallLater => '稍后安装';

  @override
  String get updateDownload => '下载更新';

  @override
  String get updateDownloadCancelled => '已取消下载，稍后可继续';

  @override
  String get updateDownloadFailed => '下载更新失败';

  @override
  String get updateInstallFailed => '安装更新失败';

  @override
  String get updateInstallingHint => '安装程序已启动，应用即将关闭并自动完成更新。';

  @override
  String get remindMeLater => '4 小时后提醒';

  @override
  String updateNoticeAvailable(Object version) {
    return '新版本 v$version 可用';
  }

  @override
  String get updateNoticeAvailableSubtitle => '可在应用内下载并自动完成更新';

  @override
  String get updateNoticeManualSubtitle => '当前平台需要前往 Release 页面手动更新';

  @override
  String updateNoticeReady(Object version) {
    return '新版本 v$version 已准备好';
  }

  @override
  String get updateNoticeReadySubtitle => '更新包已校验，重启即可安装';

  @override
  String get updateNoticeFailed => '上次更新没有完成';

  @override
  String get updateViewDetails => '查看更新';

  @override
  String updateSettingsAvailable(Object version) {
    return '发现 v$version，点击查看更新内容';
  }

  @override
  String updateSettingsReady(Object version) {
    return 'v$version 已下载，点击安装';
  }

  @override
  String get goToDownload => '前往下载';

  @override
  String get cannotOpenUrl => '无法打开链接';

  @override
  String get model3d_editorTitle => '3D 模型图层';

  @override
  String get model3d_modeTransform => '变换';

  @override
  String get model3d_modePose => '姿势';

  @override
  String get model3d_gizmoTranslate => '移动';

  @override
  String get model3d_gizmoRotate => '旋转';

  @override
  String get model3d_gizmoScale => '缩放';

  @override
  String get model3d_replaceConfirm => '替换当前模型？未应用的姿势将丢失。';

  @override
  String get model3d_discardConfirm => '放弃未应用的修改？';

  @override
  String get model3d_missingModel => '模型文件已丢失，可重新导入';

  @override
  String get model3d_loadError => '模型加载失败';

  @override
  String get model3d_light => '光照';

  @override
  String get model3d_addLayerTooltip => '添加 3D 模型图层';

  @override
  String get nav_preciseRefLibrary => '精准参考库';

  @override
  String preciseRefLib_saved(String name) {
    return '已存入精准参考库：$name';
  }

  @override
  String get preciseRefLib_savedHint => '可在精准参考库中编辑参数';

  @override
  String get preciseRefLib_imageMissing => '原图文件丢失';

  @override
  String get preciseRefLib_invalidImage => '无法识别图片格式，或图片文件已经损坏';

  @override
  String preciseRefLib_importedCount(int count) {
    return '已导入 $count 张图片';
  }

  @override
  String preciseRefLib_importFailed(String error) {
    return '保存到精准参考库失败：$error';
  }

  @override
  String preciseRefLib_importFailedCount(int count) {
    return '$count 张图片未能导入精准参考库';
  }

  @override
  String get preciseRefLib_fromLibrary => '从库导入';

  @override
  String get preciseRefLib_saveCurrentToLibrary => '保存到库';

  @override
  String preciseRefLib_saveCurrentCount(int count) {
    return '已保存 $count 张到精准参考库';
  }

  @override
  String get img2img_fromPreciseRefLibrary => '从精准参考库导入';

  @override
  String get localGallery_saveToPreciseRefLibrary => '保存到精准参考库';

  @override
  String get drop_saveToPreciseRefLibrary => '存入精准参考库';

  @override
  String get common_enabled => '已启用';

  @override
  String get common_disabled => '已禁用';

  @override
  String bulkAction_selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get comfyTask_errorConnectionFailed => '无法连接到 ComfyUI 服务器';

  @override
  String get comfyTask_errorConnectionUnavailable => 'ComfyUI 连接不可用';

  @override
  String get comfyTask_errorExecutionFailedGeneric => 'ComfyUI 执行失败';

  @override
  String comfyTask_errorExecutionFailed(String error) {
    return 'ComfyUI 执行失败：$error';
  }

  @override
  String get comfyTask_errorTimeout => 'ComfyUI 任务已在 10 分钟后超时';

  @override
  String comfyTask_errorWorkflowNotFound(String workflowId) {
    return '未找到工作流：$workflowId';
  }

  @override
  String get comfyWorkflowSlot_vaeEncodeTileSize => 'VAE 编码分块大小';

  @override
  String get comfyWorkflowSlot_vaeDecodeTileSize => 'VAE 解码分块大小';

  @override
  String get comfyWorkflowSlot_blocksToSwap => '换出块数量';

  @override
  String get comfyWorkflowSlot_swapIoComponents => '换出输入输出组件';

  @override
  String localGallery_firstIndexHint(int count) {
    return '检测到 $count 张图片。首次建立索引可能需要几分钟，期间仍可正常使用应用。';
  }

  @override
  String get localGallery_errorPermissionDenied => '无法访问图片文件夹，请检查文件夹权限。';

  @override
  String localGallery_errorScanFailed(String error) {
    return '扫描图片失败：$error';
  }

  @override
  String localGallery_errorInitializationFailed(String error) {
    return '初始化图库失败：$error';
  }

  @override
  String get localGallery_errorServiceInitializing => '图库服务正在初始化，请稍后重试。';

  @override
  String localGallery_errorDatabaseFailed(String error) {
    return '图库数据库错误：$error';
  }

  @override
  String localGallery_errorRefreshFailed(String error) {
    return '刷新图库失败：$error';
  }

  @override
  String localGallery_errorFilterFailed(String error) {
    return '应用图库筛选条件失败：$error';
  }

  @override
  String localGallery_errorFavoriteFailed(String error) {
    return '更新收藏状态失败：$error';
  }

  @override
  String localGallery_errorRebuildFailed(String error) {
    return '重建图库索引失败：$error';
  }

  @override
  String get common_optional => '可选';

  @override
  String get common_emptyValue => '（空）';

  @override
  String get common_clickToRetry => '点击重试';

  @override
  String get common_opening => '正在打开...';

  @override
  String get common_swap => '交换';

  @override
  String get addToLibrary_displayNameHint => '输入便于识别此条目的名称';

  @override
  String get addToLibrary_tagHint => '输入标签并按 Enter 添加';

  @override
  String get drop_saveVibeBundle => '保存 Vibe Bundle';

  @override
  String get vibe_import_overwriteOriginalParams => '直接替换原 Vibe 参数';

  @override
  String vibe_import_overwriteOriginalParamsHint(String name) {
    return '仅覆盖 $name 的库内参数，默认不勾选';
  }

  @override
  String vibe_import_reencodeFailed(String name) {
    return 'Vibe 重新编码失败: $name';
  }

  @override
  String galleryScan_failed(int count) {
    return '失败 $count';
  }

  @override
  String get galleryScan_organizingGallery => '正在整理图库';

  @override
  String get galleryScan_processing => '处理中';

  @override
  String imagePicker_dropReadFailed(String error) {
    return '读取拖入图片失败: $error';
  }

  @override
  String get imagePicker_dropNoReadableImage => '拖入源未提供可读取的图片文件或图片链接';

  @override
  String get imagePicker_fileDataUnavailable => '无法读取文件数据';

  @override
  String imagePicker_fileSelectionFailed(String error) {
    return '选择文件失败: $error';
  }

  @override
  String imagePicker_directorySelectionFailed(String error) {
    return '选择目录失败: $error';
  }

  @override
  String get editor_shiftEdges => '扩展边缘';

  @override
  String get editor_edgeLeft => '左';

  @override
  String get editor_edgeRight => '右';

  @override
  String get editor_edgeTop => '上';

  @override
  String get editor_edgeBottom => '下';

  @override
  String get editor_enterNumber => '请输入数字';

  @override
  String get onlineGallery_videoLoadFailed => '视频加载失败';

  @override
  String get vibe_releaseToAddStyleReference => '松开后添加风格参考';

  @override
  String router_pageNotFound(String error) {
    return '页面未找到: $error';
  }

  @override
  String get autocomplete_resultLimit => '结果数量';

  @override
  String get autocomplete_relatedTagsTitle => '标签扩展';

  @override
  String get autocomplete_relatedTagsSubtitle => 'Ctrl+单击搜索本地标签；Ctrl+拖选查看关联标签';

  @override
  String get tagExpansion_searchHint => '搜索标签或别名';

  @override
  String get tagExpansion_relatedTitle => '关联标签';

  @override
  String get tagExpansion_empty => '输入词语搜索本地标签';

  @override
  String get tagExpansion_noResults => '没有找到本地标签';

  @override
  String get tagExpansion_insert => '插入标签';

  @override
  String get tagExpansion_showRelated => '查看关联标签';

  @override
  String get tagExpansion_localOnly => '仅本地';

  @override
  String get tagExpansion_popularSource => '本地常用标签';

  @override
  String get tagExpansion_tabComplete => 'Tab 补全：';

  @override
  String get tagExpansion_wikiTitle => '标签小百科';

  @override
  String get tagExpansion_wikiUnavailable => '本地暂未收录这个标签的释义。';

  @override
  String get autocomplete_cooccurrence => '离线相关标签库';

  @override
  String autocomplete_entryCount(int count) {
    return '$count 条记录';
  }

  @override
  String get autocomplete_clearDanbooruCache => '清除 Danbooru 缓存';

  @override
  String get autocomplete_clearAiCache => '清除 AI 汉化缓存';

  @override
  String autocomplete_cacheCleared(int count) {
    return '已清除 $count 条缓存';
  }

  @override
  String get autocomplete_baseCatalog => '基础 Danbooru 词库';

  @override
  String autocomplete_catalogStatus(String count, String version) {
    return '$count 个标签 · 数据版本 $version';
  }

  @override
  String get promptBlockLibrary_allBlocks => '全部块';

  @override
  String get promptBlockLibrary_rootFolder => '根目录 / 未分类';

  @override
  String get promptBlockLibrary_unnamedBlock => '未命名块';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '使用 $count 次';
  }

  @override
  String get promptBlockPill_missing => '块已删除';

  @override
  String get promptBlockPill_unknown => '失效块';

  @override
  String get promptBlockLibrary_unnamedFolder => '未命名文件夹';

  @override
  String promptBlockLibrary_deleteCollectionConfirm(String name) {
    return '确定要删除收藏集「$name」吗？其中的块不会被删除，只会移出该收藏集。';
  }

  @override
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name) {
    return '确定要删除收藏文件夹「$name」吗？其中的收藏集与子文件夹会一并删除，块本体不受影响。';
  }

  @override
  String get promptBlockLibrary_blockTitle => '标题';

  @override
  String get promptBlockLibrary_titleHint => '块标题';

  @override
  String get promptBlockLibrary_folder => '文件夹';

  @override
  String get promptBlockLibrary_settingsApplied => '块设置已导入当前画面';

  @override
  String get promptBlockLibrary_settingsIncompatible => '块设置与目标模型不兼容，未导入任何参数。';

  @override
  String get promptBlockLibrary_deleted => '已删除';

  @override
  String get promptBlockLibrary_multiSelect => '多选';

  @override
  String get promptBlockLibrary_exitMultiSelect => '退出多选';

  @override
  String promptBlockLibrary_selectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get promptBlockLibrary_selectAllVisible => '全选';

  @override
  String get promptBlockLibrary_clearSelection => '清空选择';

  @override
  String get promptBlockLibrary_empty => '还没有提示词块';

  @override
  String get promptBlockLibrary_noSearchResults => '没有匹配的块';

  @override
  String promptBlockLibrary_deleteFolderTitle(Object name) {
    return '删除文件夹“$name”？';
  }

  @override
  String get promptBlockLibrary_deleteFolderDescription =>
      '请选择如何处理此文件夹及其子文件夹中的块。';

  @override
  String get promptBlockLibrary_moveContentsToRoot => '将内容移到根目录';

  @override
  String get promptBlockLibrary_moveContentsToFolder => '将内容移到其他文件夹';

  @override
  String get promptBlockLibrary_destinationFolder => '目标文件夹';

  @override
  String get promptBlockLibrary_deleteContents => '删除内容';

  @override
  String get promptBlockLibrary_deleteContentsWarning => '这会永久删除整个文件夹树中的所有块。';

  @override
  String get promptBlockLibrary_exportLibraryBackup => '导出库备份…';

  @override
  String get promptBlockLibrary_importTxtTitle => '选择 TXT 文件';

  @override
  String promptBlockLibrary_txtImportDone(int created, int skipped) {
    return '导入 $created 个块，跳过 $skipped 个已有来源';
  }

  @override
  String get promptBlockLibrary_curationTitle => '从文件夹导入';

  @override
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  ) {
    return '共 $total 个 TXT：新增 $created · 未变更 $skipped · 已变更 $changed';
  }

  @override
  String promptBlockLibrary_curationLocalModifiedHint(int count) {
    return '其中 $count 个块导入后手动修改过，更新会覆盖本地修改';
  }

  @override
  String get promptBlockLibrary_curationUpdateChanged => '用文件内容更新已变更的块';

  @override
  String get promptBlockLibrary_curationEmpty => '所选文件夹中没有 TXT 文件';

  @override
  String promptBlockLibrary_curationDone(
    int created,
    int updated,
    int skipped,
  ) {
    return '导入完成：新增 $created · 更新 $updated · 跳过 $skipped';
  }

  @override
  String get promptBlockLibrary_curationNew => '新增';

  @override
  String get promptBlockLibrary_curationUnchanged => '未变更';

  @override
  String get promptBlockLibrary_curationChanged => '已变更';

  @override
  String get promptBlockLibrary_curationLocalModified => '本地已修改';

  @override
  String get promptBlockLibrary_libraryImportTitle => '选择库备份文件';

  @override
  String promptBlockLibrary_importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => '来源文件';

  @override
  String get promptBlockLibrary_importedAt => '导入时间';

  @override
  String get promptBlockPalette_tooltip => '积木';

  @override
  String get promptBlockPalette_emptyHint =>
      '把常用的提示词块或翻译块拖进来收纳；用时点一下插到光标处，或直接拖进提示词框。';

  @override
  String get promptBlockPalette_remove => '从积木移除';

  @override
  String get promptBlockPalette_clearAll => '清空积木';

  @override
  String get promptBlockPalette_clearAllArmed => '再点一次确认清空';

  @override
  String promptBlockPalette_removeSelected(int count) {
    return '移除选中的 $count 个块';
  }

  @override
  String get nav_styleExplore => '画风探索';

  @override
  String get styleExplore_operationFailed => '操作失败';

  @override
  String get styleExplore_discardChangesTitle => '放弃未保存的修改？';

  @override
  String get styleExplore_discardChangesMessage => '当前工作区有未保存的修改，继续将丢弃这些修改。';

  @override
  String get styleExplore_discardChangesConfirm => '继续并丢弃';

  @override
  String styleExplore_manualRunName(String time) {
    return '手动候选 $time';
  }

  @override
  String get styleExplore_runBusy => '生成进行中，稍后再试';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已存为块「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所选候选没有可保存的画师串或正向提示词';

  @override
  String get promptBlockEditor_library => '块库';

  @override
  String get promptBlockPicker_title => '选择块';

  @override
  String get promptBlockLibrary_selectImage => '选择图片';

  @override
  String get promptBlockLibrary_adjustThumbnailTitle => '调整预览图显示范围';

  @override
  String get promptBlockLibrary_dragToMove => '拖拽移动，滚轮或双指缩放';

  @override
  String get promptBlockLibrary_addToLibrary => '收藏到块库';

  @override
  String get promptBlockLibrary_contentPreview => '内容预览';

  @override
  String get promptBlockLibrary_confirmAdd => '确认收藏';

  @override
  String get promptBlockLibrary_saveToLibrary => '保存到块库';

  @override
  String get promptBlockLibrary_droppedImage => '拖入图片';

  @override
  String get promptBlockLibrary_createBlockFromImage => '创建新块';

  @override
  String get promptBlockLibrary_createBlockFromImageSubtitle => '从图片创建新块';

  @override
  String promptBlockLibrary_promptExtracted(Object prompt) {
    return '提示词已提取: \"$prompt\"';
  }

  @override
  String get promptBlockLibrary_updateExistingThumbnail => '更新现有块预览图';

  @override
  String get promptBlockLibrary_updateExistingThumbnailSubtitle => '选择块并替换其预览图';

  @override
  String subscriptionExpiresOn(String date) {
    return '到期 $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '剩 $days 天';
  }

  @override
  String get subscriptionExpired => '已过期';

  @override
  String get subscriptionGracePeriod => '宽限期';

  @override
  String get subscriptionTierNone => '无订阅';

  @override
  String get settings_modelsAndInterfaces => '模型与接口';

  @override
  String get tips_kind_guide => '提示';

  @override
  String get tips_kind_trick => '过来人';

  @override
  String get tips_kind_wolf => '狼';

  @override
  String tips_hint(String label, String tip) {
    return '$label：$tip';
  }

  @override
  String get tips_studio_guide_1 =>
      '写好提示词，按 Ctrl+Enter 就能生成。生成的图会在这块画布上一批批铺开：中键或 Shift+左键拖动平移，Ctrl+滚轮缩放，WASD 也能用来导航。';

  @override
  String get tips_studio_guide_2 =>
      '常用的画师串、质量词和构图描述，写一次存成块，下次从块库直接拉进来。块不只是复制粘贴：它可以设成固定、顺序或随机抽取，每次生成换一种组合。';

  @override
  String get tips_studio_guide_3 =>
      '随机块抽到一组特别满意的结果？锁定它，再去重抽别的块。锁住的内容不会变，没锁的照常随机——适合「这个姿势留着，衣服再换几套」。';

  @override
  String get tips_studio_guide_4 =>
      '把一张图拖进窗口，会问你想怎么用：图生图、风格迁移、精准参考，或者只提取它的提示词和参数。带着 NovelAI 元数据的图，一拖就能看到当时是怎么写的。';

  @override
  String get tips_studio_guide_5 =>
      '角色框本质上是定位框。除了人物，你也可以放一只猫、一盏灯、一块招牌；把定位切到「自定义」，在预览图上拖动锚点，告诉模型它该出现在哪里。';

  @override
  String get tips_studio_guide_6 =>
      '选中一段提示词，按住 Alt 滚动滚轮就能调权重。不按 Alt 时滚轮只是正常翻页，不会误改权重。修饰键可以在设置里换成 Ctrl。';

  @override
  String get tips_studio_guide_7 =>
      '按 F1 随时打开快捷键帮助。Ctrl+1、Ctrl+2、Ctrl+3 在生成页、本地画廊和在线画廊之间切换，Ctrl+, 打开设置。所有快捷键都能在设置里改成你顺手的组合。';

  @override
  String get tips_studio_guide_8 =>
      '担心一不小心花掉一大笔 Anlas？在设置里打开「Anlas 高消耗警告」，单次预计消耗超过你设定的数值时，生成前会先问你一句。';

  @override
  String get tips_studio_trick_1 =>
      '种子决定了这张图「抽」到什么。参数和种子都不变，出来的就是同一张。所以想复现神图，记得把种子一起留下；想换运气，就别再盯着那个种子了。';

  @override
  String get tips_studio_trick_2 =>
      '复用预编码过的 Vibe 不用再花 2 Anlas。2 Anlas 听起来不多，但你一天会用几次 Vibe，自己心里有数。';

  @override
  String get tips_studio_trick_3 =>
      '负面提示词不是许愿池。写一百遍 bad hands，不如把正面里的手部动作写清楚。那排每次都要写的负面词，交给负面预设去管就好。';

  @override
  String get tips_studio_trick_4 =>
      '画师串不是越长越好。加到第十个以后，模型多半已经分不清你到底想要谁的笔触了。不如把它们拆成几个块，用随机抽取轮流上场。';

  @override
  String get tips_studio_trick_5 =>
      '一次点击发几次请求、每次出几张，是两个不同的数。按钮上显示的是总张数，Anlas 也按总张数算——看清楚再按，别问我是怎么知道的。';

  @override
  String get tips_studio_trick_6 =>
      '在翻译块上按一下鼠标中键，原文和译文来回切换。AI 翻得再好，偶尔也值得偷看一眼原文，确认它没把 cat ears 翻成什么奇怪的东西。';

  @override
  String get tips_studio_trick_7 =>
      '设置里的「限制生图频率」可以让两次生图之间强制冷却，再加一点随机抖动，节奏就没那么机械。适合挂着慢慢抽的夜晚，也适合管不住手的自己。';

  @override
  String get tips_studio_wolf_1 =>
      '这里是狼窝。你生成的图会被我叼回来，整整齐齐摆在本地画廊里——说真的，我的收纳能力比画技可靠得多。';

  @override
  String get tips_studio_wolf_2 =>
      '我们狼在夜里视力最好。所以如果你凌晨三点还在这里，我什么都不会说，只会默默陪你再抽一张。';

  @override
  String get tips_studio_wolf_3 =>
      '据说 AI 画手的成年礼，是第一次心平气和地数完一只手上的手指。我没有手指，所以我一直很平静。';

  @override
  String get tips_studio_wolf_4 =>
      '狼群的规矩：好种子要分享，好提示词要存成块，好图要先保存再欣赏。最后一条最重要，别问为什么。';

  @override
  String get tips_studio_wolf_5 => '我不会画画，但我很会等。看着流式预览一点点变清晰的那几秒，是我一天里最安静的时候。';

  @override
  String get tips_studio_wolf_6 => 'W.O.F 的意思是 WolF。至于中间为什么有点，那是我跑过雪地留下的脚印。';

  @override
  String get tips_studio_wolf_7 => '画布空着的时候，我就趴在这里打个盹。按下生成，我就醒了。';

  @override
  String get tips_studio_night_1 => '现在是深夜。友情提醒：这个时间段你的审美会悄悄上调 30%，明早起来记得再看一遍。';

  @override
  String get tips_studio_night_2 => '夜深了，远方机房里的显卡也打了个哈欠。抽完这一批就去睡吧，画廊我替你守着。';

  @override
  String get tips_lab_guide_1 =>
      '画风探索是一场选秀：先建一个探索任务，把提示词和参数固定下来，再批量生成候选图。你挑中的子代会成为下一代的父本，画风就这样一代代朝你想要的方向靠近。';

  @override
  String get tips_lab_guide_2 =>
      '红心和文件夹是给你自己整理用的，不会影响遗传。真正决定下一代的，是你用「多选建分支」挑进去的那几张。';

  @override
  String get tips_lab_guide_3 =>
      '拿不定主意时，用「A/B 组对照」：两张父本的图并排出现，你只需要回答哪张更接近想要的画风。排在前面的父本，下一轮更容易分到子代。';

  @override
  String get tips_lab_guide_4 =>
      '想生成下一轮候选，主提示词里得有一个启用了遗传的随机块。没有可变的基因，变异引擎也无从下手。';

  @override
  String get tips_lab_guide_5 =>
      '某张候选的提示词组合特别好？「收编为块」能把它存进块库，以后在生成页也能直接用；多选几张，还能合并收编成一个块。';

  @override
  String get tips_lab_guide_6 =>
      '删除探索任务只会删掉任务目录里的候选副本，本地画廊里的原图不受影响。放心清理，试验场本来就该乱一点。';

  @override
  String get tips_lab_trick_1 =>
      '每个父本至少会分到一张出图名额，所以父本越多，一轮需要的张数也越多。贪心的话，Anlas 会先替你喊停。';

  @override
  String get tips_lab_trick_2 => '只能从最新一代的候选堆建分支。回头路可以看，但不能从半路岔出去——进化论就是这么无情。';

  @override
  String get tips_lab_trick_3 =>
      '变异引擎偶尔会说「产不出足够不同的子代」。这不是它偷懒，是基因池太小了：给随机块多塞几个候选词，它马上就有活干。';

  @override
  String get tips_lab_trick_4 => '悬停候选堆里的缩略图就能看大图。别一张张点开，评委要有评委的效率。';

  @override
  String get tips_lab_trick_5 =>
      '看中了某张候选的整套参数？「导入元数据」会把它的提示词和参数原样搬回编辑区，你可以从这里接着改。';

  @override
  String get tips_lab_wolf_1 => '狼群里没有哪只狼一出生就是最强的。画风也一样，第一代丑一点很正常，到第三代再下结论。';

  @override
  String get tips_lab_wolf_2 => '这里的适者生存有个温柔的版本：没被选中的候选不会消失，只是这一轮没轮到它而已。';

  @override
  String get tips_lab_wolf_3 => '我对遗传学的全部理解是：好看的爸妈，大概率生出好看的崽。剩下的交给变异，和一点点运气。';

  @override
  String get tips_lab_wolf_4 => 'LAB 的灯通常亮到很晚。我在门口值班，顺便帮你记着这是第几代了。';

  @override
  String get tips_lab_wolf_5 =>
      '永远不要小看变异。有时候你挑了十代都没找到的东西，会在一次意外里冒出来。所以，看着不对劲的那张也别急着删。';

  @override
  String get tips_prompt_guide_1 => '写完按 Ctrl+Enter 就能生成，生成途中按 Esc 取消。';

  @override
  String get tips_prompt_guide_2 => '选中一段提示词，按住 Alt 滚动滚轮调权重；不按 Alt，滚轮只是翻页。';

  @override
  String get tips_prompt_guide_3 =>
      'Ctrl+单击提示词里的标签，直接在本地标签库里搜它；Ctrl+拖选一段，看看哪些标签常和它一起出现。';

  @override
  String get tips_prompt_guide_4 => '选中一段文字点右键，可以直接保存到块库。以后点一下或拖一下，它就回来了。';

  @override
  String get tips_prompt_guide_5 => '框底部的质量词预设会替你补上那排常用质量词；切到负面，同一个位置就是负面预设。';

  @override
  String get tips_prompt_guide_6 => '按 F1 查看全部快捷键。';

  @override
  String get tips_prompt_guide_7 =>
      '从 ComfyUI 复制来的多角色提示词，粘贴进来会被识别，并询问是否导入成角色框，不用一个个重填。';

  @override
  String get tips_prompt_guide_8 =>
      '打开「SD 语法自动转换」后，(tag:1.2) 这种写法会在失焦或生成时自动换成 NovelAI 的权重格式。';

  @override
  String get tips_prompt_guide_9 => '写 1.2::词:: 能精确调权重，写负数就反着来。';

  @override
  String get tips_prompt_trick_1 =>
      '花括号每套一层，权重乘 1.05；方括号每套一层，除以 1.05。套五层花括号的人，通常是在和模型吵架。';

  @override
  String get tips_prompt_trick_2 => '自动格式化会删掉没用的 1 倍权重。它不是嫌弃你，是在帮你省 token。';

  @override
  String get tips_prompt_trick_3 =>
      '框底下那条细线是 token 用量。写满之后，后面的内容模型基本就看不见了——想写长篇小说，请换个地方。';

  @override
  String get tips_prompt_trick_4 => '写不出来的时候，先写画面里最大的那个东西。';

  @override
  String get tips_prompt_trick_5 => '质量词写一次就够了。masterpiece 写三遍，模型也不会觉得你更真诚。';

  @override
  String get tips_prompt_trick_6 =>
      '想让一个元素「出现但别太抢戏」，写 0.8:: 比删掉它好使。删掉是没有，降权是低调。';

  @override
  String get tips_prompt_trick_7 => '同一套词改来改去？先存成块，再交给随机抽取。';

  @override
  String get tips_prompt_trick_8 =>
      '正面写「要什么」，负面写「不要什么」。在正面写 no hat，模型多半只听见了 hat。';

  @override
  String get tips_prompt_wolf_1 => '这个框见过上千张神图，和几张不太方便公开的黑历史。';

  @override
  String get tips_prompt_wolf_2 =>
      '先用一句人话描述你想要的画面，再把它拆成标签。顺序反过来的话，常常会得到一堆标签和一张不知所云的图。';

  @override
  String get tips_prompt_wolf_3 => '我在看你打字。别紧张，我看不懂英文。';

  @override
  String get tips_prompt_wolf_4 => '远方某张显卡，刚刚因为你的提示词叹了口气。';

  @override
  String get tips_prompt_wolf_5 => '抽卡的尽头是玄学，玄学的尽头是锁种子。';

  @override
  String get tips_prompt_wolf_6 => '画师串加到第十二个的时候，模型已经不知道自己在画谁了。你也是。';

  @override
  String get tips_explore_guide_1 => '这里写的是父本的提示词。想让某部分参与进化，就把它做成随机块，再在块上开启遗传。';

  @override
  String get tips_explore_guide_2 => '遗传开关要等块实例启用后才能打开。灰着的话，先把块启用。';

  @override
  String get tips_explore_guide_3 => '「生成候选图」旁边的数字，决定这一轮出几张。';

  @override
  String get tips_explore_guide_4 => '块实例可以「退回一幕」「前进一幕」，在抽过的组合之间来回翻。';

  @override
  String get tips_explore_guide_5 => '探索任务会固化提示词和参数快照。之后再改这里，不会影响已经跑完的那几轮。';

  @override
  String get tips_explore_guide_6 => '块的「随机设置」里能调抽取数量、触发概率和随机权重——基因的花样都藏在这里。';

  @override
  String get tips_explore_trick_1 =>
      '基因池越大，变异越有得挑。一个随机块里只放两个词，进化十代也只是在两个答案之间来回横跳。';

  @override
  String get tips_explore_trick_2 =>
      '确定要的部分写死，拿不准的做成随机块。全都随机等于没有方向，全都写死等于没有进化。';

  @override
  String get tips_explore_trick_3 => '锁住的块不会被重抽。想保住某个特征，就先锁上它，再让别的块去折腾。';

  @override
  String get tips_explore_trick_4 =>
      '触发概率设成 30%，这个块大约只在三成的组合里出现。适合那些「偶尔来一下才好看」的元素。';

  @override
  String get tips_explore_trick_5 => '第一代就想看到完美答案？那叫许愿，不叫探索。';

  @override
  String get tips_explore_wolf_1 => '狼群的血统是一代代挑出来的。你的画风也是。';

  @override
  String get tips_explore_wolf_2 => '每一轮生成都是一场海选，评委只有你一个。我负责鼓掌。';

  @override
  String get tips_explore_wolf_3 => '好基因来自好父本，好父本来自你那一下没手滑的点击。';

  @override
  String get tips_explore_wolf_4 => '我不太懂遗传学，但我知道：挑剔的评委，才养得出好看的狼崽。';

  @override
  String get tips_character_guide_1 => '角色框本质是定位框：猫、灯、招牌都能放，不一定是人。';

  @override
  String get tips_character_guide_2 => '上方「定位」切到「自定义」，在预览图上拖动锚点，松开就生效。';

  @override
  String get tips_character_guide_3 => '「AI 选择」把位置交给模型安排；切回「自定义」，之前拖好的位置还在。';

  @override
  String get tips_character_guide_4 => '每个角色框都有自己的负面，只管这一个角色。';

  @override
  String get tips_character_guide_5 => '右上角的勾可以临时停用这个角色，不用删掉重写。';

  @override
  String get tips_character_guide_6 => '点一下标题就能给角色改名，比编号好认多了。';

  @override
  String get tips_character_guide_7 => '右上角的 ⋯ 里可以把这个角色收藏到块库，以后接着复用这段描述。';

  @override
  String get tips_character_trick_1 =>
      '场景和画风写主提示词，这里只写这个角色。两边写同一件衣服，模型会以为你超爱它。';

  @override
  String get tips_character_trick_2 =>
      '两人挨太近容易「粘」在一起。把锚点拉开一点，比写十遍 separate 管用。';

  @override
  String get tips_character_trick_3 => '想让一棵树站在画面左边？给它一个角色框，拖到左边。树不会抱怨自己不是角色。';

  @override
  String get tips_character_trick_4 => '角色框里也能用块和权重语法，和主提示词一样。';

  @override
  String get tips_character_trick_5 => '角色太多就先停用几个。画面挤不下时，模型会自己挑人——通常不是你想留的那个。';

  @override
  String get tips_character_wolf_1 => '我也想要一个角色框，但我觉得自己更适合站在画面外面看着。';

  @override
  String get tips_character_wolf_2 => '一个框，一个位置，一件事。我觉得这是很好的人生哲学。';

  @override
  String get tips_character_wolf_3 => '你负责安排站位，我负责在旁边喊「再往左一点」。';

  @override
  String get tips_character_wolf_4 => '狼群出门也要排队形。角色多的时候，先想好谁站中间。';

  @override
  String get tips_gallery_guide_1 => '搜文件名或提示词正文';

  @override
  String get tips_gallery_guide_2 => '逗号分隔多个词，要全部命中才算';

  @override
  String get tips_gallery_guide_3 => '模型、采样器、来源也能搜到';

  @override
  String get tips_gallery_guide_4 => 'Ctrl+F 随时跳到搜索框';

  @override
  String get tips_gallery_guide_5 => '角色提示词里的内容也搜得到';

  @override
  String get tips_gallery_guide_6 => '右键图片，还有更多操作';

  @override
  String get tips_gallery_guide_7 => 'F5 刷新画廊';

  @override
  String get tips_gallery_trick_1 => '只搜正面，负面里的搜不到';

  @override
  String get tips_gallery_trick_2 => '重抽之前先搜，多半已经有了';

  @override
  String get tips_gallery_trick_3 => '你写过的提示词就是最好的搜索词';

  @override
  String get tips_gallery_trick_4 => '删除池的图，下次启动才真删';

  @override
  String get tips_gallery_trick_5 => '搜 masterpiece 约等于搜全部';

  @override
  String get tips_gallery_wolf_1 => '今晚的猎物大概在第三页';

  @override
  String get tips_gallery_wolf_2 => '我闻到了，神作就在这堆里';

  @override
  String get tips_gallery_wolf_3 => '滚动也算运动，我陪你跑';

  @override
  String get tips_gallery_wolf_4 => '窝很大，慢慢翻';

  @override
  String get tips_online_guide_1 => '空格分隔多个标签，回车搜索';

  @override
  String get tips_online_guide_2 => '开模糊匹配，*tag* 找相近标签';

  @override
  String get tips_online_guide_3 => '黑名单标签的图会直接隐藏';

  @override
  String get tips_online_guide_4 => '登录 Danbooru 后可以用收藏夹';

  @override
  String get tips_online_trick_1 => '多词标签用下划线：blue_eyes';

  @override
  String get tips_online_trick_2 => '看到好图，记下它的标签思路';

  @override
  String get tips_online_trick_3 => '标签越多结果越少，先少写几个';

  @override
  String get tips_online_wolf_1 => '外面的世界很大，我先去探路';

  @override
  String get tips_online_wolf_2 => '别人家的猎场，逛逛就好';

  @override
  String get tips_online_wolf_3 => '今天想去哪片林子打猎？';

  @override
  String get tips_blocks_guide_1 => '标题、提示词、标签都能搜';

  @override
  String get tips_blocks_guide_2 => '把块直接拖进提示词框';

  @override
  String get tips_blocks_guide_3 => '点 ★ 收藏，常用块集中放';

  @override
  String get tips_blocks_guide_4 => '块可以带缩略图，挑起来更快';

  @override
  String get tips_blocks_guide_5 => '选中文字右键，就能存成块';

  @override
  String get tips_blocks_trick_1 => '同一段写过三次，就该存成块了';

  @override
  String get tips_blocks_trick_2 => '犹豫要不要存？存。删比写快';

  @override
  String get tips_blocks_trick_3 => '名字起清楚，半年后会感谢自己';

  @override
  String get tips_blocks_trick_4 => '随机块候选越多，惊喜越多';

  @override
  String get tips_blocks_wolf_1 => '每个块都在等你点名';

  @override
  String get tips_blocks_wolf_2 => '这些块是你的狼群，常带出去溜';

  @override
  String get tips_blocks_wolf_3 => '我只认得一种块：肉块';

  @override
  String get tips_blocks_wolf_4 => '文件夹套文件夹，算是有条理了';

  @override
  String get tips_generating_wolf_1 => '正在和随机数讨价还价…';

  @override
  String get tips_generating_wolf_2 => '正在跟第六根手指好好谈谈…';

  @override
  String get tips_generating_wolf_3 => '正在劝像素们排好队…';

  @override
  String get tips_generating_wolf_4 => '正在把噪点一粒粒擦掉…';

  @override
  String get tips_generating_wolf_5 => '狼正在远处嚎叫助威…';

  @override
  String get tips_generating_wolf_6 => '正在向显卡解释你的审美…';

  @override
  String get tips_generating_wolf_7 => '正在把提示词翻译成梦…';

  @override
  String get tips_generating_wolf_8 => '正在确认眼睛的数量…';

  @override
  String get tips_generating_wolf_9 => '正在给光影找个好角度…';

  @override
  String get tips_generating_wolf_10 => '正在说服背景别抢戏…';

  @override
  String get tips_generating_wolf_11 => '正在从噪声里捞出你的图…';

  @override
  String get tips_generating_wolf_12 => '正在数手指：一、二、三…';

  @override
  String get tips_generating_wolf_13 => '正在等颜料晾干…';

  @override
  String get tips_generating_wolf_14 => '正在召唤今天的好运气…';

  @override
  String get tips_generating_trick_1 => '等不及了？按 Esc 可以取消';

  @override
  String get tips_generating_trick_2 => '预览会一帧帧变清晰';

  @override
  String get tips_generating_trick_3 => '生成好的图默认存进本地画廊';

  @override
  String get tips_generating_trick_4 => '每一步采样都在去掉一层噪点';

  @override
  String get tips_splash_guide_1 => '按 F1 可以随时查看全部快捷键。';

  @override
  String get tips_splash_guide_2 => 'Ctrl+Enter 生成，所有快捷键都能在设置里改。';

  @override
  String get tips_splash_guide_3 => '把图拖进窗口，可以读出它的提示词和参数。';

  @override
  String get tips_splash_guide_4 => '常用的提示词存成块，下次一键复用。';

  @override
  String get tips_splash_trick_1 => '上面那个 STEP /28，致敬的是默认的 28 步采样。';

  @override
  String get tips_splash_trick_2 => '预编码的 Vibe 可以免费复用，省下 2 Anlas。';

  @override
  String get tips_splash_trick_3 => '第一次建立图库索引会慢一点，期间照常使用就好。';

  @override
  String get tips_splash_wolf_1 => '再让我睡五分钟……好吧，起来了。';

  @override
  String get tips_splash_wolf_2 => '我先把窝收拾一下，马上就好。';

  @override
  String get tips_splash_wolf_3 => '显卡就位，月亮就位，就差你了。';

  @override
  String get tips_splash_wolf_4 => '闻到了吗？是新提示词的味道。';

  @override
  String get tips_splash_wolf_5 => '今天也要好好抽卡。';

  @override
  String genButton_normal(int count) {
    return '生成 $count 张图片';
  }

  @override
  String get genButton_one_1 => '就这一张，不改了';

  @override
  String get genButton_one_2 => '来张好的';

  @override
  String get genButton_one_3 => '单抽，信仰之跃';

  @override
  String get genButton_one_4 => '先来一张试试水';

  @override
  String get genButton_one_5 => '一张定胜负';

  @override
  String get genButton_one_6 => '这张必是神图';

  @override
  String get genButton_one_7 => '就一张，我发誓';

  @override
  String get genButton_one_8 => '新头像就靠它了';

  @override
  String get genButton_one_9 => '一发入魂';

  @override
  String get genButton_one_10 => '来张能当壁纸的';

  @override
  String get genButton_one_11 => '轻轻抽一张';

  @override
  String get genButton_one_12 => '叼一张回来';

  @override
  String genButton_few_1(int count) {
    return '$count 张，挑个最好的';
  }

  @override
  String genButton_few_2(int count) {
    return '来 $count 张比一比';
  }

  @override
  String genButton_few_3(int count) {
    return '$count 连抽';
  }

  @override
  String genButton_few_4(int count) {
    return '$count 张，总有一张行';
  }

  @override
  String genButton_few_5(int count) {
    return '$count 选一，评委就位';
  }

  @override
  String genButton_few_6(int count) {
    return '先来 $count 张热热身';
  }

  @override
  String genButton_few_7(int count) {
    return '$count 张，择优录取';
  }

  @override
  String genButton_few_8(int count) {
    return '$count 张小确幸';
  }

  @override
  String genButton_batch_1(int count) {
    return '$count 连发';
  }

  @override
  String genButton_batch_2(int count) {
    return '$count 张一起上';
  }

  @override
  String genButton_batch_3(int count) {
    return '$count 张，开始停不下来';
  }

  @override
  String genButton_batch_4(int count) {
    return '一次 $count 张，吃到饱';
  }

  @override
  String genButton_batch_5(int count) {
    return '$count 张，铺满屏幕';
  }

  @override
  String genButton_batch_6(int count) {
    return '$count 连，稳一手';
  }

  @override
  String genButton_batch_7(int count) {
    return '$count 张，狼群出动';
  }

  @override
  String genButton_batch_8(int count) {
    return '$count 张，开席';
  }

  @override
  String genButton_many_1(int count) {
    return '$count 张，上强度了';
  }

  @override
  String genButton_many_2(int count) {
    return '$count 张，显卡开始冒汗';
  }

  @override
  String genButton_many_3(int count) {
    return '$count 张，囤货模式';
  }

  @override
  String genButton_many_4(int count) {
    return '$count 张，流水线启动';
  }

  @override
  String genButton_many_5(int count) {
    return '$count 张，Anlas 在燃烧';
  }

  @override
  String genButton_many_6(int count) {
    return '$count 张，这是要日更';
  }

  @override
  String genButton_many_7(int count) {
    return '$count 张批量出击';
  }

  @override
  String genButton_many_8(int count) {
    return '$count 张，狼都看呆了';
  }

  @override
  String genButton_huge_1(int count) {
    return '$count 张？！开画展吗';
  }

  @override
  String genButton_huge_2(int count) {
    return '$count 张，硬盘瑟瑟发抖';
  }

  @override
  String genButton_huge_3(int count) {
    return '$count 张，工业革命了';
  }

  @override
  String genButton_huge_4(int count) {
    return '$count 张，先冷静一下';
  }

  @override
  String genButton_huge_5(int count) {
    return '$count 张，存得下吗';
  }

  @override
  String genButton_huge_6(int count) {
    return '$count 张，打印店开张';
  }

  @override
  String genButton_huge_7(int count) {
    return '批发 $count 张';
  }

  @override
  String genButton_huge_8(int count) {
    return '$count 张，狼去搬救兵了';
  }

  @override
  String get genButton_rare_1 => '这发必出 SSR';

  @override
  String get genButton_rare_2 => 'AI 说它今天手感不错';

  @override
  String get genButton_rare_3 => '今日运势：大吉';

  @override
  String get genButton_rare_4 => '据说这个按钮旺你';

  @override
  String get genButton_rare_5 => '狼对着月亮嚎了一声';

  @override
  String get genButton_rare_6 => '玄学加持中';

  @override
  String get genButton_rare_7 => '欧气已充值';

  @override
  String get genButton_rare_8 => '本次抽卡由狼赞助';

  @override
  String get genButton_rare_9 => '手气，来！';

  @override
  String get genButton_rare_10 => '按下即是信仰';

  @override
  String get genButton_night_1 => '夜深了，最后一抽';

  @override
  String get genButton_night_2 => '抽完这批就睡';

  @override
  String get genButton_night_3 => '凌晨的审美最野';

  @override
  String get genButton_night_4 => '狼陪你熬夜';

  @override
  String genButton_special_7(int count) {
    return '$count 张，幸运七';
  }

  @override
  String genButton_special_9(int count) {
    return '$count 张，九宫格集齐';
  }

  @override
  String genButton_special_42(int count) {
    return '$count，万物的答案';
  }

  @override
  String genButton_special_99(int count) {
    return '$count 张，差一张破百';
  }

  @override
  String genButton_special_100(int count) {
    return '整整 $count 张，强迫症舒服了';
  }

  @override
  String get titleBar_minimize => '最小化';

  @override
  String get titleBar_maximize => '最大化';

  @override
  String get titleBar_restore => '还原';

  @override
  String get titleBar_close => '关闭';

  @override
  String get img2img_pixelSnap => '像素对齐';

  @override
  String get img2img_masked => '透明抠图';

  @override
  String get img2img_generated => '生成结果';

  @override
  String get img2img_blend => '混合结果';

  @override
  String get img2img_enhanceAction => '增强！';

  @override
  String get img2img_showAdvanced => '显示高级设置';

  @override
  String get img2img_hideAdvanced => '收起高级设置';

  @override
  String promptToken_usage(int used, int limit) {
    return 'Token 用量：$used / $limit';
  }

  @override
  String promptToken_promptShare(int used, int total, int limit) {
    return '此提示词：$used Token；总用量：$total / $limit';
  }

  @override
  String get promptToken_blockReferenceHint => '单块进度仅供参考；插入后的总量取决于组合使用。';

  @override
  String get settings_geistDark => 'Geist 深色';

  @override
  String get settings_geistLight => 'Geist 浅色';

  @override
  String get settings_geistDescription => '全工作室统一外观：黑白灰底色，蓝色作为操作强调。';

  @override
  String get updateCapsuleLabel => '更新';

  @override
  String get updateWaitForTask => '任务进行中，结束后即可重启更新';

  @override
  String get updateLater => '稍后';

  @override
  String get nav_tagWiki => '标签百科';

  @override
  String get wiki_title => '标签百科';

  @override
  String get wiki_allTags => '全部词条';

  @override
  String get wiki_bookmarks => '书签';

  @override
  String get wiki_newCollection => '新建书签集';

  @override
  String get wiki_newChildCollection => '新建子书签集';

  @override
  String get wiki_renameCollection => '重命名';

  @override
  String get wiki_deleteCollection => '删除书签集';

  @override
  String get wiki_officialDirectory => '官方目录';

  @override
  String get wiki_searchHint => '搜索标签或别名';

  @override
  String get wiki_typeAllShort => '全部';

  @override
  String get wiki_coverageAll => '全部释义';

  @override
  String get wiki_withArticle => '有释义';

  @override
  String get wiki_withoutArticle => '暂无释义';

  @override
  String get wiki_sortPopular => '按热度';

  @override
  String get wiki_sortName => '按名称';

  @override
  String get wiki_dataStatus => '数据状态';

  @override
  String get wiki_scopeCurrent => '当前目录';

  @override
  String get wiki_scopeAll => '搜索全库';

  @override
  String get wiki_readingSettings => '阅读设置';

  @override
  String get wiki_textSize => '正文大小';

  @override
  String get wiki_readingWidth => '阅读宽度';

  @override
  String get wiki_small => '小';

  @override
  String get wiki_standard => '标准';

  @override
  String get wiki_large => '大';

  @override
  String get wiki_wide => '宽';

  @override
  String get wiki_articleMissing => '这条标签暂时没有本地 Wiki 释义。';

  @override
  String get wiki_source => '来源';

  @override
  String get wiki_addBookmark => '加入书签';

  @override
  String get wiki_removeBookmark => '移出书签';

  @override
  String get wiki_addToCollection => '加入书签集';

  @override
  String get wiki_loadMore => '加载更多';

  @override
  String get wiki_noResults => '没有匹配的词条';

  @override
  String get wiki_noSelection => '选择一个词条查看释义';

  @override
  String get wiki_collectionNameHint => '书签集名称';

  @override
  String get wiki_syncTags => '同步 Danbooru 标签';

  @override
  String get wiki_directorySource => '官方分组目录快照';

  @override
  String get wiki_openFull => '在标签百科中打开';

  @override
  String get shortcut_action_vibe_detail_prev_sub_vibe => '上一个子 Vibe';

  @override
  String get shortcut_action_vibe_detail_next_sub_vibe => '下一个子 Vibe';

  @override
  String get settings_addAccountsSwitchBetweenThem => '添加账号后，可以在这里快速切换。';

  @override
  String get settings_current => '当前';

  @override
  String get settings_emailLogin => '邮箱登录';

  @override
  String get settings_signedIn => '已登录';

  @override
  String get settings_switch => '切换';

  @override
  String get settings_accountActions => '账号操作';

  @override
  String get settings_editProfile => '编辑资料';

  @override
  String get settings_setDefault => '设为默认账号';

  @override
  String get settings_credentialsUpdated => '登录凭据已更新';

  @override
  String get settings_updateCredentials => '更新凭据';

  @override
  String get settings_accountDetails => '账号详情';

  @override
  String get settings_localAccountProfile => '本地账号资料';

  @override
  String get settings_setDefault2 => '设为默认';

  @override
  String get settings_credentialsWereNotUpdatedCheck => '凭据未更新，请检查令牌与连接后重试。';

  @override
  String get settings_updateCredentials2 => '更新登录凭据';

  @override
  String get settings_checking => '正在验证…';

  @override
  String get settings_enterNewSignInToken => '输入新的登录令牌，验证成功后更新此账号。';

  @override
  String get auth_notSignedIn => '尚未登录';

  @override
  String get settings_tagExpansion => '标签扩展';

  @override
  String get settings_tagDictionaries => '标签词库';

  @override
  String get settings_cacheMaintenance => '缓存维护';

  @override
  String get settings_clear => '清理';

  @override
  String get settings_autoRefresh => '自动刷新';

  @override
  String get settings_searchFonts => '搜索字体名称';

  @override
  String get settings_couldNotLoadFonts => '暂时无法读取字体';

  @override
  String get settings_recommended => '推荐';

  @override
  String get settings_included => '随应用提供';

  @override
  String get settings_systemFonts => '系统字体';

  @override
  String get settings_fontPreview => '字体预览';

  @override
  String get settings_onlineFontsLoadAfterApplying => '在线字体将在应用后加载，当前显示界面字体。';

  @override
  String get settings_saving => '保存设置';

  @override
  String get settings_howGeneratedImagesSaved => '生成图片的保存方式';

  @override
  String get settings_assetsDisplay => '素材与显示';

  @override
  String get settings_vibeLocationThumbnailQuality => 'Vibe 位置与缩略图质量';

  @override
  String get settings_applicationData => '应用数据';

  @override
  String get settings_gallerySources => '图库来源';

  @override
  String get settings_manageAdditionalGalleryFolders => '管理额外图库文件夹';

  @override
  String get settings_default => '默认';

  @override
  String get settings_keyboard => '键盘操作';

  @override
  String get settings_customizeFrequentlyUsedActions => '按习惯配置常用操作';

  @override
  String get settings_manageShortcuts => '管理快捷键';

  @override
  String get settings_costReminders => '消耗提醒';

  @override
  String get settings_requestPacing => '请求节奏';

  @override
  String get settings_notificationsSound => '完成提醒与声音';

  @override
  String get settings_lockCanvasCamera => '锁定画布相机';

  @override
  String get settings_dictionariesCache => '词库与缓存';

  @override
  String get settings_defaultAccount2 => '默认账号';

  @override
  String get settings_signInAutomatically => '启动时自动登录';

  @override
  String get settings_signInCredentials => '登录凭据';

  @override
  String get settings_translationInterfaces => '翻译功能接口';

  @override
  String get settings_presetsBuiltInRules => '预设与内置规则';

  @override
  String get settings_preferenceBackupRestore => '偏好备份与恢复';

  @override
  String get settings_searchSettingsFeatures => '搜索设置、功能或关键词';

  @override
  String get settings_noMatchingSettings => '没有找到匹配设置';

  @override
  String get settings_change => '更改';

  @override
  String get settings_couldNotPlaySoundCheck => '无法播放音效，请检查音频文件。';

  @override
  String get settings_useDefaultCompletionSound => '使用默认完成音效';

  @override
  String get settings_soundPreview => '音效预览';

  @override
  String get settings_listenCurrentCompletionSound => '试听当前完成音效';

  @override
  String get settings_playSound => '试听音效';

  @override
  String get settings_searchResults => '搜索结果';

  @override
  String get settings_promptInput => '提示词输入';

  @override
  String get settings_manageTranslationModelsRules => '管理翻译模型与规则';

  @override
  String get settings_browsing => '浏览方式';

  @override
  String get settings_chooseHowViewImages => '选择图片的查看习惯';

  @override
  String get settings_canvasControls => '画布操作';

  @override
  String get settings_keepViewSteady => '保持视角稳定';

  @override
  String get settings_appearance2 => '外观样式';

  @override
  String get settings_chooseLightDarkWorkspace => '选择工作台的明暗风格';

  @override
  String get settings_textLanguage => '文字与语言';

  @override
  String get settings_makeReadingComfortable => '统一阅读体验';

  @override
  String get settings_adjustSettingsPagesDialogsOnly => '仅调整设置页面与设置弹窗的字号';

  @override
  String get settings_motionNotifications => '动效与提醒';

  @override
  String get settings_reduceDistractionsKnowWorkFinishes => '减少打扰，及时获知完成';

  @override
  String get settings_notificationStyle => '通知样式';

  @override
  String get settings_notificationsAppearUpperRightWrap =>
      '通知会显示在右上角，长文本自动换行，进度任务完成后自动收起。';

  @override
  String get settings_preview => '预览';

  @override
  String get settings_versionUpdates => '版本与更新';

  @override
  String get settings_currentVersionUpdateOptions => '当前版本与更新选项';

  @override
  String get settings_diagnosticsResources => '诊断与资料';

  @override
  String get settings_logsFontsOpenSourceProject => '日志、字体与开源项目';

  @override
  String get settings_viewLicenses => '查看许可';

  @override
  String get settings_openProject => '打开项目';

  @override
  String get settings_actionIncomplete => '操作未完成';

  @override
  String get settings_exportPreferences => '导出偏好';

  @override
  String get settings_preferencesExported => '偏好已导出';

  @override
  String get settings_noAutomaticBackupYet => '尚无自动回退备份';

  @override
  String get settings_restorePreviousPreferences => '恢复上次偏好';

  @override
  String get settings_importPreferences => '导入偏好';

  @override
  String get settings_apply => '确认应用';

  @override
  String get settings_preferencesAppliedPreviousSettingsBacked =>
      '偏好已应用，旧设置已自动备份';

  @override
  String get settings_restoreDefaultPreferences => '恢复默认偏好';

  @override
  String get settings_choosePreferencesResetCurrentSettings =>
      '选择需要恢复的范围，当前偏好将自动备份。';

  @override
  String get settings_appearanceSoundControls => '外观、声音与操作';

  @override
  String get settings_inputAutocomplete => '输入与自动补全';

  @override
  String get settings_privacyGenerationProtection => '隐私与生成保护';

  @override
  String get settings_moveAppearanceControlsInputProtection =>
      '界面、操作、输入和保护偏好，可跨设备迁移。';

  @override
  String get settings_rollbackCopySavedBeforeImport => '导入或恢复默认前会自动保存回退副本。';

  @override
  String get settings_resetSelectedScopeWhileKeeping =>
      '按范围恢复，保留账号、模型、图库和创作内容。';

  @override
  String get settings_chooseScope => '选择范围';

  @override
  String get settings_preferenceManagement => '偏好管理';

  @override
  String get settings_backupMigrationRecovery => '备份、迁移与恢复';

  @override
  String get settings_generalAppearance => '常规与外观';

  @override
  String get settings_makeWorkspaceComfortableReadUse => '让工作台符合你的阅读与使用习惯。';

  @override
  String get settings_controlsShortcuts => '操作与快捷键';

  @override
  String get settings_chooseInteractionCanvasControlsKeyboard =>
      '设置交互方式、画布操作和键盘快捷键。';

  @override
  String get settings_generationPrompts => '生成与提示词';

  @override
  String get settings_managePromptInputGenerationReminders =>
      '管理提示词输入、生成提醒与请求节奏。';

  @override
  String get settings_galleryFiles => '图库与文件';

  @override
  String get settings_manageImageSavingGallerySources => '管理图片保存、图库来源与浏览显示。';

  @override
  String get settings_manageTagDictionariesIndexesCache => '管理标签词库、索引与缓存维护。';

  @override
  String get settings_novelaiAccounts => 'NovelAI 账号';

  @override
  String get settings_viewAccountManageSignIn => '查看当前账号，管理登录与默认账号。';

  @override
  String get settings_connectionsIntegrations => '连接与集成';

  @override
  String get settings_manageExternalToolsBridgesNetwork => '管理外部工具、桥接连接与网络设置。';

  @override
  String get settings_privacySharing2 => '隐私与分享';

  @override
  String get settings_controlSharedInformationConfirmationBefore =>
      '控制分享信息与需要确认的操作。';

  @override
  String get settings_aboutDiagnostics => '关于与诊断';

  @override
  String get settings_updatesLogsProjectInformation => '版本更新、日志与项目资料。';

  @override
  String get settings_searchSettings => '搜索设置';

  @override
  String get settings_preferences => '使用偏好';

  @override
  String get settings_creationResources => '创作与资源';

  @override
  String get settings_servicesConnections => '服务与连接';

  @override
  String get settings_safetyMaintenance => '安全与维护';

  @override
  String get settings_subscriptionActive => '订阅有效';

  @override
  String get settings_availableBalance => '可用余额';

  @override
  String get settings_subscriptionExpiry2 => '订阅有效期';

  @override
  String get settings_subscriptionDetailsUnavailable => '订阅信息暂不可用';

  @override
  String get settings_loadingSubscriptionDetails => '正在读取订阅信息…';

  @override
  String get settings_localDataStaysAvailableAfter => '账号到期后仍保留本地数据。';

  @override
  String get settings_records => '条记录';

  @override
  String get settings_hitRate => '命中率';

  @override
  String get settings_images => '张图片';

  @override
  String get settings_cacheOverview => '缓存概览';

  @override
  String get settings_loginPreferences => '登录偏好';

  @override
  String get settings_preselectedSignInPage => '在登录页优先选中此账号。';

  @override
  String get settings_noAccounts => '暂无账号';

  @override
  String get settings_useLastSessionOffNext => '使用上次的登录凭据；关闭后，下次启动进入登录页。';

  @override
  String get settings_couldNotSaveLoginPreference => '登录偏好未保存，请重试。';

  @override
  String get settings_loginPreferencesUnavailable => '无法读取登录偏好。';

  @override
  String settings_applyPreferencesConfirm(Object count) {
    return '将应用 $count 项偏好。当前偏好会自动备份，可从“恢复上次偏好”找回。账号、密钥、草稿、图库和模型配置保持独立。';
  }

  @override
  String get settings_restore => '恢复';

  @override
  String get wiki_translating => '正在翻译中';

  @override
  String get wiki_back => '返回上一次';

  @override
  String get wiki_readingTranslation => '译文';

  @override
  String get wiki_readingOriginal => '原文';

  @override
  String get wiki_readingBilingual => '对照';

  @override
  String get wiki_bilingualUnavailable => '这篇译文没有可逐段对照的原文，已显示译文';

  @override
  String get wiki_open => '打开';

  @override
  String get wiki_switchToOriginal => '切换到原文';

  @override
  String get wiki_switchToTranslation => '切换到译文';

  @override
  String get wiki_retranslate => '重新翻译';

  @override
  String get wiki_onThisPage => '本文目录';

  @override
  String get wiki_overview => '简介';

  @override
  String get wiki_untranslated => '暂未翻译';

  @override
  String get wiki_autoTranslateTagsArticles => '自动翻译标签与百科';

  @override
  String get wiki_readingContent => '阅读内容';

  @override
  String get wiki_categoryGeneral => '一般';

  @override
  String get wiki_categoryArtist => '画师';

  @override
  String get wiki_categoryCopyright => '作品';

  @override
  String get wiki_categoryCharacter => '角色';

  @override
  String get wiki_categoryMeta => '元标签';

  @override
  String get wiki_categoryContributor => '贡献者';

  @override
  String get wiki_categorySpecies => '物种';

  @override
  String get wiki_categoryLore => '设定';

  @override
  String get wiki_categoryLibrary => '本地';

  @override
  String get wiki_addToBlock => '添加到积木';

  @override
  String get wiki_forward => '前进';

  @override
  String get wiki_posts => '帖子';

  @override
  String get wiki_aliases => '别名';

  @override
  String get wiki_relatedTitle => '常一起出现';

  @override
  String get wiki_relatedHint => '点击查看 · Shift+点击添加到积木';

  @override
  String get wiki_inDirectory => '所属目录';

  @override
  String get wiki_noArticle => '无百科';

  @override
  String get wiki_moreCategories => '更多';

  @override
  String get wiki_shortcutsHint =>
      '/ 搜索 · ↑↓ 切换 · Enter 添加到积木 · B 收藏 · Alt+←/→ 历史';

  @override
  String get toast_titleSuccess => '已完成';

  @override
  String get toast_titleError => '操作失败';

  @override
  String get toast_titleWarning => '请留意';

  @override
  String get toast_titleInfo => '提示';

  @override
  String get toast_titleProgress => '正在处理';

  @override
  String get tagExpansion_autoTranslateVisible => '自动翻译可见标签';

  @override
  String get translationEditor_title => '翻译块';

  @override
  String get translationEditor_source => '原文';

  @override
  String get translationEditor_sourcePrefix => '原';

  @override
  String get translationEditor_generation => '生图使用';

  @override
  String get translationEditor_editable => '可改写';

  @override
  String get translationEditor_modified => '被修改';

  @override
  String get translationEditor_edited => '已编辑';

  @override
  String get translationEditor_close => '关闭';

  @override
  String get translationEditor_save => '保存';

  @override
  String get translationEditor_delete => '删除整块';

  @override
  String get translationEditor_restore => '还原为原文文本';

  @override
  String get translationEditor_configure => '配置翻译模型';

  @override
  String translationEditor_readingFieldTitle(Object language) {
    return '$language阅读文本';
  }

  @override
  String translationEditor_sourceWarning(Object language) {
    return '原文已修改，$language待同步';
  }

  @override
  String get translationEditor_editHint => '译文已手工编辑；这是编辑记录，不触发原文修改提醒';

  @override
  String get translationLanguage_chinese => '中文';

  @override
  String get translationLanguage_english => '英语';

  @override
  String get translationLanguage_japanese => '日语';

  @override
  String get translationLanguage_korean => '韩语';

  @override
  String get translationLanguage_traditionalChinese => '繁体中文';

  @override
  String get modelTask_translateTitle => '原文 → 阅读语言';

  @override
  String get modelTask_promptReverseTitle => '阅读语言 → 原文';

  @override
  String get modelTask_tagTranslateTitle => '标签翻译与语义补充';

  @override
  String get modelTask_wikiTranslateTitle => '百科正文翻译';

  @override
  String get modelTask_translateDescription => '翻译提示词与积木，保留权重、分组和标签语义。';

  @override
  String get modelTask_promptReverseDescription => '结合原文落实译文中的增删修改，结果填回原文供确认。';

  @override
  String get modelTask_tagTranslateDescription =>
      '翻译可见标签，补齐中文核心词、同义词和简释义；已有资料优先复用。';

  @override
  String get modelTask_wikiTranslateDescription => '翻译百科正文、整理排版，并按语境选择可点击标签。';

  @override
  String get modelTask_connectionTest => '模型连接测试';

  @override
  String get modelReasoning_serviceDefault => '服务默认';

  @override
  String get modelReasoning_off => 'Off';

  @override
  String get modelReasoning_on => 'On';

  @override
  String get modelReasoning_minimal => 'Minimal';

  @override
  String get modelReasoning_low => 'Low';

  @override
  String get modelReasoning_medium => 'Medium';

  @override
  String get modelReasoning_high => 'High';

  @override
  String get modelReasoning_xhigh => 'XHigh';

  @override
  String get modelReasoning_max => 'Max';

  @override
  String get modelProvider_custom => '自定义服务';

  @override
  String get modelProvider_qwen => '通义千问 · 百炼';

  @override
  String get modelProvider_moonshot => 'Kimi · 月之暗面';

  @override
  String get modelProvider_zhipu => '智谱 GLM';

  @override
  String get modelProvider_doubao => '豆包 · 火山方舟';

  @override
  String get modelProvider_hunyuan => '腾讯混元';

  @override
  String get modelProvider_qianfan => '百度千帆';

  @override
  String get modelProvider_siliconflow => '硅基流动';

  @override
  String get modelProvider_zai => 'Z.AI · 国际';

  @override
  String get modelProvider_zhipuCodingPlan => '智谱 Coding Plan';

  @override
  String get modelProvider_kimiCoding => 'Kimi 编程';

  @override
  String get modelProvider_moonshotInternational => 'Moonshot AI · 国际';

  @override
  String get modelProvider_minimaxChinaChat => 'MiniMax · 国内 OpenAI';

  @override
  String get modelProvider_minimaxChinaMessages => 'MiniMax · 国内 Anthropic';

  @override
  String get modelProvider_minimaxInternationalMessages =>
      'MiniMax · 国际 Anthropic';

  @override
  String get modelProvider_xiaomi => '小米 MiMo';

  @override
  String get modelProvider_antLing => '蚂蚁 Ling';

  @override
  String get modelProvider_stepfunPlan => '阶跃 Step Plan';

  @override
  String get modelProvider_qwenTokenPlanChina => '通义 Token 套餐 · 国内';

  @override
  String get modelProvider_hintHuggingFace =>
      '使用具有推理权限的 Hugging Face Token；可手动填写路由模型 ID。';

  @override
  String get modelProvider_hintPlanKey => '使用套餐专用 API Key；模型与可用范围以该套餐实际返回为准。';

  @override
  String get modelProvider_hintInternationalEndpoint =>
      '国际平台端点；使用国际平台的 API Key。';

  @override
  String get modelProvider_hintRegionOpenAi =>
      '使用对应地区的 API Key；当前预填 OpenAI Chat Completions 兼容地址。';

  @override
  String get modelProvider_hintRegionAnthropic =>
      '使用对应地区的 API Key；当前预填 Anthropic Messages 兼容地址。';

  @override
  String get modelProvider_hintQwen => '默认北京区域；其他区域请使用对应 Key 并修改接口地址。';

  @override
  String get modelProvider_hintMinimax => '默认国际按量接口；国内平台请使用对应区域的 Key 和接口地址。';

  @override
  String get modelProvider_hintMoonshot => '默认国内平台；国际平台请使用对应区域的 Key 和接口地址。';

  @override
  String get modelProvider_hintZhipu => '默认按量接口；Coding Plan 请使用套餐专用地址。';

  @override
  String get modelProvider_hintDoubao => '使用方舟 API Key；需先开通模型，也可添加推理接入点 ID。';

  @override
  String get modelProvider_hintCustom => '填写兼容服务的地址与 Key，并在连接信息中选择接口协议。';

  @override
  String get modelProvider_hintLocal => '先启动本地服务，再读取已加载的模型目录。';

  @override
  String get modelProvider_hintDefault => '地址与协议已预填；保存 Key 后即可选择模型使用。';

  @override
  String get modelParams_temperatureRange => 'Temperature 应在 0–2 之间。';

  @override
  String get modelParams_topPRange => 'Top P 应大于 0 且不超过 1。';

  @override
  String get modelParams_maxOutputPositive => '最大输出 token 必须大于 0。';

  @override
  String modelParams_thinkingBudgetTooSmall(Object minimum) {
    return '最大输出必须大于思考预算下限 $minimum。';
  }

  @override
  String get modelOverrides_invalidHeaderName => '请输入有效的请求头名称';

  @override
  String get modelOverrides_invalidHeaderValue => '请求头值不能包含换行或控制字符';

  @override
  String get modelOverrides_emptyBodyField => '请求体字段名不能为空';

  @override
  String get modelOverrides_modelFromList => '模型 ID 请通过模型列表设置';

  @override
  String get modelOverrides_streamMustBeFalse => '当前接口使用非流式请求，stream 应为 false';

  @override
  String get modelConfig_changedSaveAgain => '配置已变化，请重新保存。';

  @override
  String get modelConfig_presetChanged => '所选预设已变化，请重新选择。';

  @override
  String get modelConfig_serviceDisabled => '所选服务已停用，请重新选择。';

  @override
  String get modelConfig_modelChanged => '所选模型已变化，请重新选择。';

  @override
  String get modelConfig_reasoningChanged => '模型支持的思考档位已变化，请重新选择或跟随模型。';

  @override
  String get modelConfig_presetIdRequired => '预设 ID 不能为空。';

  @override
  String get modelConfig_saveBuiltinAsCustom => '请将内置方案另存为自定义预设。';

  @override
  String get modelConfig_namePromptRequired => '名称和提示词不能为空。';

  @override
  String get modelConfig_builtinNotDeletable => '内置规则不可删除。';

  @override
  String get modelConfig_pasteFullJson => '请粘贴完整的模型配置 JSON。';

  @override
  String get modelConfig_builtinNotOverwritable => '内置方案不可覆盖，请复制为自定义预设。';

  @override
  String get modelConfig_invalidProvider => '服务商 ID、名称或地址无效。';

  @override
  String get modelConfig_missingProvider => '模型对应的服务商不存在。';

  @override
  String get modelConfig_invalidCustomPreset => '自定义预设的 ID、名称或提示词无效。';

  @override
  String get modelConfig_changedImportAgain => '配置已变化，请重新导入。';

  @override
  String get modelHealth_unverified => '尚未验证连接；使用模型或点击“测试连接”后更新';

  @override
  String get modelHealth_healthy => '最近一次请求成功';

  @override
  String get modelHealth_limited => '接口可达，但最近请求被限流（HTTP 429）；请稍后重试或检查额度';

  @override
  String get modelHealth_authentication => '认证失败；请检查 API 密钥';

  @override
  String get modelHealth_permission => '访问被拒绝；请检查服务权限';

  @override
  String get modelHealth_timeout => '最近一次请求超时';

  @override
  String get modelHealth_network => '最近一次请求无法连接服务';

  @override
  String get modelHealth_invalidResponse => '最近一次响应异常；可在请求记录中查看详情';

  @override
  String get modelHealth_failed => '最近一次请求失败';

  @override
  String modelHealth_failedStatus(Object status) {
    return '最近一次请求失败（HTTP $status）';
  }

  @override
  String get modelRequest_statusPending => '等待中';

  @override
  String get modelRequest_statusRunning => '请求中';

  @override
  String get modelRequest_statusSuccess => '成功';

  @override
  String get modelRequest_statusFailed => '失败';

  @override
  String get modelRequest_statusCancelled => '已取消';

  @override
  String get modelRequest_fieldTime => '时间';

  @override
  String get modelRequest_fieldMethod => '方法';

  @override
  String get modelRequest_fieldUrl => '地址';

  @override
  String get modelRequest_fieldRequestHeaders => '请求头';

  @override
  String get modelRequest_fieldBody => '正文';

  @override
  String get modelRequest_fieldStatusCode => '状态码';

  @override
  String get modelRequest_fieldResponseHeaders => '响应头';

  @override
  String get modelRequest_fieldError => '错误';

  @override
  String get modelRequest_fieldInterface => '接口';

  @override
  String get modelRequest_fieldProvider => '服务商';

  @override
  String get modelRequest_fieldModel => '模型';

  @override
  String get modelRequest_fieldProtocol => '协议';

  @override
  String get modelRequest_fieldStatus => '状态';

  @override
  String get modelRequest_fieldElapsed => '耗时（毫秒）';

  @override
  String get modelRequest_fieldAttempts => '执行次数';

  @override
  String get modelRequest_fieldHttpRequests => 'HTTP 请求数';

  @override
  String get modelRequest_fieldParameters => '生效参数';

  @override
  String get modelRequest_redacted => '[已脱敏]';

  @override
  String get modelRequest_emptyResponse => '模型返回了空内容。';

  @override
  String get modelService_testFieldsIncomplete => '测试返回的字段不完整。';

  @override
  String get modelService_testFieldsInvalid => '测试返回的字段不正确。';

  @override
  String get modelService_testGroupsInvalid => '测试返回的分组不正确。';

  @override
  String get modelService_testSourceEmpty => '测试返回的原文为空。';

  @override
  String get modelService_conversionCancelled => '转换已取消';

  @override
  String get modelService_chooseInterfaceModel =>
      '请先在「设置 → 模型与接口 → 功能接口」选择服务商和模型。';

  @override
  String get modelService_enableServiceModel => '请先在设置中启用服务，并获取或手动添加后选中一个模型。';

  @override
  String get modelSettings_keepEditsTitle => '保留当前编辑？';

  @override
  String get modelSettings_keepEditsBody => '当前修改尚未保存。是否保存后切换？';

  @override
  String get modelSettings_discard => '放弃';

  @override
  String get modelSettings_saveAndSwitch => '保存并切换';

  @override
  String get modelSettings_addProvider => '添加服务商';

  @override
  String modelSettings_deleteProviderTitle(Object name) {
    return '删除 $name？';
  }

  @override
  String get modelSettings_deleteProviderBody => '此服务的连接、密钥和已选模型将被删除。';

  @override
  String modelSettings_deleteProviderBindings(Object count) {
    return '$count 个功能的模型绑定会被清除，预设保留。';
  }

  @override
  String modelSettings_deletePresetTitle(Object name) {
    return '删除“$name”？';
  }

  @override
  String get modelSettings_deletePresetBody => '使用此预设的功能将恢复内置方案。模型绑定保留。';

  @override
  String get modelSettings_configCopied => '配置已复制，不包含密钥、自定义请求头或请求体。';

  @override
  String get modelSettings_importConfig => '导入配置';

  @override
  String get modelSettings_importConfigHint => '粘贴导出的配置。导入前会备份当前配置；密钥继续独立保存。';

  @override
  String get modelSettings_configJson => '配置 JSON';

  @override
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  ) {
    return '将导入 $providers 个服务商、$models 个模型和 $presets 个自定义预设。';
  }

  @override
  String get modelSettings_importMissingProviders => '缺少服务商或模型配置。';

  @override
  String get modelSettings_checkConfig => '检查配置';

  @override
  String get modelSettings_importAndReplace => '导入并替换';

  @override
  String get modelSettings_configImported => '配置已导入';

  @override
  String get modelSettings_description => '管理服务连接与翻译偏好。';

  @override
  String get modelSettings_configMenu => '配置管理';

  @override
  String get modelSettings_copyConfig => '复制配置';

  @override
  String get modelSettings_tabProviders => '服务商';

  @override
  String get modelSettings_tabInterfaces => '功能接口';

  @override
  String get modelSettings_tabPresets => '预设与提示词';

  @override
  String get modelSettings_tabRequests => '请求记录';

  @override
  String modelSettings_providersCount(Object count) {
    return '服务商 · $count';
  }

  @override
  String modelSettings_providerModelCount(Object count) {
    return '$count 个模型';
  }

  @override
  String get modelSettings_providerDisabledSuffix => ' · 未启用';

  @override
  String get modelSettings_emptyTitle => '添加你的第一个模型服务';

  @override
  String get modelSettings_emptyBody => '选择常用服务，或连接自定义接口。';

  @override
  String get modelSettings_customService => '自定义服务';

  @override
  String get modelSettings_notConfigured => '待配置';

  @override
  String get modelSettings_preset => '预设';

  @override
  String get modelSettings_presetBuiltin => '内置';

  @override
  String get modelSettings_presetUser => '用户';

  @override
  String get modelSettings_deletePreset => '删除预设';

  @override
  String modelSettings_presetCopyName(Object title, Object number) {
    return '$title（$number）';
  }

  @override
  String get modelSettings_recentRequests => '最近请求';

  @override
  String get modelSettings_recentRequestsHint =>
      '本次会话最近 100 条 · 完整请求与响应，认证信息已脱敏';

  @override
  String get modelSettings_clearRequests => '清空';

  @override
  String get modelSettings_requestsEmpty => '翻译或测试模型后，请求记录会出现在这里。';

  @override
  String get modelSettings_interfaceChangedElsewhere => '功能配置已在别处修改，请重新打开后编辑。';

  @override
  String get modelSettings_configSaved => '配置已保存';

  @override
  String get modelSettings_viewBuiltinRules => '查看内置规则';

  @override
  String get modelSettings_viewEditPreset => '查看与编辑预设';

  @override
  String get modelSettings_restoreBuiltinPreset => '恢复内置预设';

  @override
  String get modelSettings_followUiLanguage => '跟随界面语言';

  @override
  String get modelSettings_providerAndModel => '服务商与模型';

  @override
  String get modelSettings_providerAndModelHelp => '仅列出启用服务中的已选模型';

  @override
  String get modelSettings_chooseProviderModel => '选择服务商与模型';

  @override
  String get modelSettings_reasoning => '思考';

  @override
  String get modelSettings_reasoningHelp =>
      '翻译通常不需要开启思考；考虑到接口使用结构化输出，建议选择该模型支持的最低思考档位。';

  @override
  String get modelSettings_reasoningHelpLabel => '思考档位建议';

  @override
  String get modelSettings_usePreset => '使用预设';

  @override
  String get modelSettings_outputLanguage => '输出语言';

  @override
  String get modelSettings_englishPrompt => '英文生成提示词';

  @override
  String get modelSettings_englishPromptHelp => '结合原文落实修改，输出英文生成提示词。';

  @override
  String get modelSettings_targetLanguage => '目标语言';

  @override
  String get modelSettings_effective => '当前生效';

  @override
  String get modelSettings_noModelSelected => '尚未选择可用模型';

  @override
  String modelSettings_reasoningSummaryInterface(Object level) {
    return '思考：$level（本接口）';
  }

  @override
  String modelSettings_reasoningSummaryModel(Object level) {
    return '思考：$level（跟随模型）';
  }

  @override
  String get modelSettings_promptBlocksHint => '无需翻译时，也可将提示词拆分为模块，通过积木功能自由拼装。';

  @override
  String get modelSettings_wikiFormatHint => '无需翻译时，也可整理排版并为相关标签添加链接。';

  @override
  String get modelSettings_unsavedChanges => '有未保存的修改';

  @override
  String get modelSettings_testPreset => '测试预设';

  @override
  String get modelSettings_tabModelPreset => '模型与预设';

  @override
  String get modelSettings_tabPromptOutput => '提示词与输出';

  @override
  String get modelSettings_translationStrategy => '翻译策略';

  @override
  String get modelSettings_editPreset => '编辑预设';

  @override
  String get modelSettings_outputContract => '应用输出约定';

  @override
  String get modelSettings_outputContractHint => '返回字段与校验规则由应用维护';

  @override
  String get modelSettings_testResult => '测试结果';

  @override
  String get modelRequest_detailsRequests => '请求';

  @override
  String get modelRequest_detailsIndex => '序号';

  @override
  String get modelRequest_detailsResponses => '响应';

  @override
  String get modelRequest_detailsOutput => '提取结果';

  @override
  String get modelRequest_detailsAction => '详情';

  @override
  String get modelRequest_detailsTitle => '请求记录';

  @override
  String get modelRequest_detailsCopied => '已复制';

  @override
  String get modelRequest_detailsCopyPage => '复制当前页';

  @override
  String get modelRequest_detailsOverview => '概览';

  @override
  String get modelRequest_detailsMissing => '此记录已清空或已超出最近 100 条。';

  @override
  String get modelPreset_changedElsewhere => '预设已在别处修改，请重新打开后编辑。';

  @override
  String get modelPreset_interfacePresetChanged => '接口使用的预设已在别处修改，请重新打开后新建。';

  @override
  String get modelPreset_builtinReadOnly => '内置 · 只读';

  @override
  String get modelPreset_newInterfacePreset => '新建接口预设';

  @override
  String get modelPreset_tabPrompt => '提示词';

  @override
  String get modelPreset_tabOutputContract => '输出约定';

  @override
  String get modelPreset_name => '预设名称';

  @override
  String get modelPreset_nameRequired => '请输入名称';

  @override
  String get modelPreset_behavior => '行为与翻译策略';

  @override
  String get modelPreset_builtinLocked => '内置规则已锁定。新建接口预设后可编辑自己的翻译偏好。';

  @override
  String get modelPreset_editHint => '此处修改翻译偏好；返回格式由应用单独维护。';

  @override
  String get modelPreset_strategyHint => '输入翻译策略';

  @override
  String get modelPreset_promptRequired => '提示词不能为空';

  @override
  String get modelPreset_restoreStrategy => '将策略恢复为内置内容';

  @override
  String get modelPreset_outputContractNote => '此部分保证翻译结果可以回填和显示，由应用维护。';

  @override
  String get modelPreset_save => '保存预设';

  @override
  String get modelReasoning_unsupported => '不支持';

  @override
  String get modelReasoning_followModel => '跟随模型';

  @override
  String modelReasoning_followModelLevel(Object level) {
    return '跟随模型（$level）';
  }

  @override
  String get modelReasoning_notAdjustable => '此模型不支持思考调节';

  @override
  String get modelReasoning_strength => '思考强度';

  @override
  String modelReasoning_modelDefault(Object level) {
    return '模型默认：$level';
  }

  @override
  String get modelReasoning_levelsUnknown => '可调档位尚未确认\n可在服务商的模型配置中设置';

  @override
  String modelReasoning_strengthValue(Object level) {
    return '思考强度：$level';
  }

  @override
  String get modelProvider_customEndpoint => '自定义端点';

  @override
  String get modelProvider_pickerTitle => '选择服务商';

  @override
  String get modelProvider_pickerSearch => '搜索厂商、平台或本地服务';

  @override
  String get modelProvider_pickerEmpty => '没有匹配的服务商';

  @override
  String get modelProvider_groupApiKey => 'API Key 连接';

  @override
  String get modelProvider_groupLocal => '本地服务';

  @override
  String get modelProvider_enterCompatibleAddress => '填写兼容接口地址';

  @override
  String get modelConnection_provider => '服务商';

  @override
  String get modelConnection_name => '名称';

  @override
  String get modelConnection_nameExample => '例如：自用中转';

  @override
  String get modelConnection_protocol => '接口协议';

  @override
  String get modelConnection_address => '接口地址';

  @override
  String get modelConnection_apiKey => 'API 密钥';

  @override
  String modelControls_decrease(Object label, Object step, Object unit) {
    return '减少$label（$step $unit）';
  }

  @override
  String modelControls_increase(Object label, Object step, Object unit) {
    return '增加$label（$step $unit）';
  }

  @override
  String get modelControls_retryOff => '关闭';

  @override
  String modelControls_retryTimes(Object count) {
    return '$count 次';
  }

  @override
  String get settings_positiveIntegerRequired => '请输入大于 0 的整数';

  @override
  String get modelSettings_testingPreset => '正在测试预设';

  @override
  String modelHealth_lastUpdated(Object time) {
    return '最近更新：$time';
  }

  @override
  String get modelSettings_backToEditing => '返回编辑';

  @override
  String modelService_loadOverridesFailed(Object error) {
    return '读取自定义请求设置失败：$error';
  }

  @override
  String get modelService_timeoutRange => '请求超时应在 10–600 秒之间。';

  @override
  String get modelService_concurrencyRange => '最大并发数量应在 1–20 个之间。';

  @override
  String get modelService_nameRequired => '请输入服务名称。';

  @override
  String get modelService_invalidUrl => '接口地址必须是完整的 http:// 或 https:// URL。';

  @override
  String get modelService_contextPositive => '上下文窗口必须大于 0。';

  @override
  String get modelService_readingCatalog => '正在读取模型目录…';

  @override
  String modelService_catalogReturned(Object count) {
    return '目录返回 $count 个模型。勾选需要使用的模型。';
  }

  @override
  String modelService_catalogUnavailable(Object error) {
    return '目录不可用：$error。可以手动添加模型 ID。';
  }

  @override
  String modelService_catalogCached(Object count) {
    return '已载入上次获取的 $count 个模型。点击“获取列表”可刷新。';
  }

  @override
  String get modelService_catalogCacheFailed => '模型列表已获取，但本地缓存保存失败，下次需重新获取。';

  @override
  String get modelService_selectModelFirst => '请先选中一个模型。';

  @override
  String get modelService_testingModel => '正在测试模型请求…';

  @override
  String modelService_testSucceeded(Object reply) {
    return '模型请求成功：$reply';
  }

  @override
  String modelService_testFailed(Object error) {
    return '模型请求失败：$error';
  }

  @override
  String modelService_tokensPositive(Object name) {
    return '模型“$name”的 token 数量必须大于 0。';
  }

  @override
  String get modelService_changedElsewhere => '服务配置已在别处修改，请重新打开后编辑。';

  @override
  String get modelService_overridesChangedElsewhere => '模型请求设置已在别处修改，请重新打开后编辑。';

  @override
  String modelService_saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get modelService_keyHintNew => '输入 Key；本地服务可留空';

  @override
  String get modelService_keyHintVendor => '输入此服务商的 Key';

  @override
  String get modelService_keyHintSaved => '已保存；留空保持原值';

  @override
  String modelService_enabledModels(Object count) {
    return '$count 个启用模型';
  }

  @override
  String get modelService_pendingSave => '待保存';

  @override
  String get modelService_saved => '已保存';

  @override
  String get modelService_enable => '启用';

  @override
  String get modelService_testConnection => '测试连接';

  @override
  String get modelService_delete => '删除服务';

  @override
  String get modelService_save => '保存服务';

  @override
  String get modelService_saving => '正在保存服务';

  @override
  String get modelService_notConfigured => '尚未配置';

  @override
  String get modelService_optional => '可留空';

  @override
  String get modelService_editConnection => '编辑';

  @override
  String get modelService_collapse => '收起';

  @override
  String get modelService_connectionSettings => '连接设置';

  @override
  String get modelService_dragToReorder => '拖拽调整模型排序';

  @override
  String get modelService_capacityTooltip => '上下文 / 最大输出；可在高级中调整';

  @override
  String get modelService_advanced => '高级';

  @override
  String modelService_removeModel(Object name) {
    return '删除模型 $name';
  }

  @override
  String get modelService_linkedInterfaces => '关联功能';

  @override
  String get modelService_noLinkedInterfaces => '尚未关联功能';

  @override
  String get modelService_advancedSettings => '高级设置';

  @override
  String get modelService_requestTimeout => '请求超时';

  @override
  String get modelService_requestTimeoutHelp => '单次请求最长等待时间';

  @override
  String get modelService_seconds => '秒';

  @override
  String get modelService_maxConcurrency => '最大并发数量';

  @override
  String get modelService_maxConcurrencyHelp => '此服务同时处理的请求数';

  @override
  String get modelService_countUnit => '个';

  @override
  String get modelService_retry => '失败重试';

  @override
  String get modelService_retryHelp => '连接失败或服务繁忙时重试';

  @override
  String get modelService_searchModelId => '搜索模型 ID…';

  @override
  String get modelService_serviceModels => '该服务的模型';

  @override
  String get modelService_fetchList => '获取列表';

  @override
  String get modelService_catalogEmpty => '点击“获取列表”读取此服务的模型，\n或在右侧手动添加模型 ID。';

  @override
  String get modelService_noMatchingModels => '没有匹配的模型';

  @override
  String get modelService_catalogLimitTooltip => '目录上限：上下文 / 最大输出';

  @override
  String get modelService_searchAddedModels => '搜索已添加模型…';

  @override
  String get modelService_modelSettings => '模型设置';

  @override
  String get modelService_addedEmpty => '从左侧勾选，或在下方添加模型';

  @override
  String get modelService_customModelId => '自定义模型 ID';

  @override
  String get modelService_customModelHelp => '添加模型目录无法拉取到的模型';

  @override
  String get modelService_addCustomModel => '添加自定义模型';

  @override
  String get modelCard_positiveInteger => '请输入正整数';

  @override
  String modelCard_catalogLimit(Object limit) {
    return '目录上限 $limit';
  }

  @override
  String get modelCard_outputExceedsContext => '输出不能超过上下文窗口';

  @override
  String get modelCard_contextWindow => '上下文窗口';

  @override
  String get modelCard_maxOutput => '最大输出';

  @override
  String get modelCard_unlabeled => '未标注';

  @override
  String get modelCard_protocolStandard => '标准';

  @override
  String get modelCard_protocolAdaptive => '自适应';

  @override
  String get modelCard_default => '默认';

  @override
  String get modelCard_thinkingLevels => '思考等级';

  @override
  String get modelCard_thinkingLevelsUnlisted => '目录未标注，可手动开启';

  @override
  String get modelCard_thinkingLevelsFromCatalog => '已按本地目录勾选支持的等级；可按实际接口调整。';

  @override
  String get modelCard_thinkingProtocol => '思考协议';

  @override
  String get modelCard_defaultThinkingLevel => '默认思考等级';

  @override
  String get modelCard_alias => '别名';

  @override
  String get modelCard_aliasHelp => '在显示模型名称的地方生效；请求仍使用模型 ID。';

  @override
  String get modelCard_aliasExample => '例如 fast';

  @override
  String get modelCard_capabilities => '能力';

  @override
  String get modelCard_images => '图片';

  @override
  String get modelCard_nativeSearch => '原生网络搜索';

  @override
  String get modelCard_nativeSearchHelp =>
      '应用尚未适配此连接的原生搜索；不代表厂商网站或其他 API 不支持搜索。';

  @override
  String get modelOverrides_duplicateHeader => '请求头名称重复';

  @override
  String get modelOverrides_fieldNameRequired => '请输入字段名';

  @override
  String get modelOverrides_duplicateField => '字段名重复';

  @override
  String get modelOverrides_invalidJson => '请输入有效的 JSON 值';

  @override
  String get modelOverrides_customBody => '自定义 Body';

  @override
  String get modelOverrides_customHeaders => '自定义 Headers';

  @override
  String get modelOverrides_fieldName => '字段名';

  @override
  String get modelOverrides_headerName => '请求头名称';

  @override
  String get modelOverrides_valueJson => '值（JSON）';

  @override
  String get modelOverrides_value => '值';

  @override
  String get modelOverrides_removeItem => '删除此项';

  @override
  String get modelOverrides_body => '请求体';

  @override
  String get modelOverrides_headers => '请求头';

  @override
  String modelOverrides_itemCount(Object count) {
    return '$count 项';
  }

  @override
  String get modelOverrides_valueTypes => '支持字符串、数字、布尔值、数组和对象';

  @override
  String get modelOverrides_addBodyField => '添加请求体字段';

  @override
  String get modelOverrides_addHeader => '添加请求头';

  @override
  String get promptTranslation_translating => '正在翻译';

  @override
  String get promptTranslation_needsModel => '翻译 · 先配置模型';

  @override
  String promptTranslation_withRoute(Object provider, Object model) {
    return '翻译 · $provider / $model';
  }

  @override
  String get promptTranslation_actions => '翻译操作';

  @override
  String get promptTranslation_promptChanged => '提示词已变化，未覆盖新编辑';

  @override
  String get promptTranslation_nothingToTranslate => '当前没有需要翻译的普通文字';

  @override
  String promptTranslation_failed(Object error) {
    return '翻译失败：$error';
  }

  @override
  String get promptTranslation_setupTitle => '先配置翻译模型';

  @override
  String get promptTranslation_setupBody =>
      '翻译需要明确选择服务商和模型。前往「设置 → 集成 → 模型与接口」，先添加服务商并取得模型列表，再在「提示词翻译」卡片中完成选择。';

  @override
  String get promptTranslation_later => '稍后';

  @override
  String get promptTranslation_openSettings => '前往设置';

  @override
  String get promptTranslation_toolTitle => '翻译';

  @override
  String get promptTranslation_noModel => '未配置模型';

  @override
  String get promptTranslation_configureModel => '配置翻译模型';

  @override
  String get promptTranslation_translateNew => '翻译新增内容';

  @override
  String get promptTranslation_undoRestore => '撤销原文还原，恢复翻译块';

  @override
  String get promptTranslation_restoreAll => '全部翻译块还原为原文文本';

  @override
  String get promptTranslation_tutorial => '操作教程';

  @override
  String get promptTranslation_guideBack => '返回操作';

  @override
  String get promptTranslation_guideMiddleTitle => '中键点块';

  @override
  String get promptTranslation_guideMiddleText => '切换原文与译文';

  @override
  String get promptTranslation_guideSourceTitle => '左键点原文';

  @override
  String get promptTranslation_guideSourceText => '定位光标，直接修改';

  @override
  String get promptTranslation_guideReadingTitle => '左键点译文';

  @override
  String get promptTranslation_guideReadingText => '打开块编辑窗';

  @override
  String get promptTranslation_guideCtrlTitle => 'Ctrl + 点击 / 拖选';

  @override
  String get promptTranslation_guideCtrlText => '编辑窗内搜索标签 / 查关联';

  @override
  String get promptTranslation_guideConvertTitle => '↑ 中文转原文';

  @override
  String get promptTranslation_guideConvertText => '↓ 原文转中文，检查后保存';

  @override
  String get promptTranslation_guideRestoreTitle => '切换整组显示';

  @override
  String get promptTranslation_guideRestoreText => '在翻译菜单中切换全部原文 / 译文';

  @override
  String get promptTranslation_middleButton => '鼠标中键';

  @override
  String get promptTranslation_leftButton => '鼠标左键';

  @override
  String get promptTranslation_blockShowingOriginal => '翻译块，显示原文';

  @override
  String get promptTranslation_blockShowingReading => '翻译块，显示译文';

  @override
  String get promptTranslation_blockNeedsReview => '原文已修改 · 译文待更新';

  @override
  String get promptTranslation_badgeTooltip => '原文已修改，中文待同步';

  @override
  String get promptTranslation_sourceChanged => '原文已变化，请重新打开翻译块';

  @override
  String promptTranslation_retranslateFailed(Object error) {
    return '重新翻译失败：$error';
  }

  @override
  String get promptTranslation_draftChanged => '内容已修改，请重新转换；新草稿已保留';

  @override
  String promptTranslation_convertFailed(Object error) {
    return '转换失败，草稿已保留：$error';
  }

  @override
  String get promptTranslation_invalidResultFormat => '转换结果格式不正确，草稿已保留';

  @override
  String get promptTranslation_noValidText => '模型没有返回有效文字，草稿已保留';

  @override
  String get promptTranslation_invalidResultContent => '转换结果包含无效格式，草稿已保留';

  @override
  String get promptTranslation_incompleteStructure => '转换结果的权重或分组不完整，草稿已保留';

  @override
  String get promptTranslation_inputRequired => '请先输入需要转换的内容';

  @override
  String get wiki_configureTagModel => '请先在「模型与接口」配置可用的标签翻译模型。';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '目标中已有 $count 个同源副本。替换后来源从块库隐藏；已插入提示词的实例仍可引用原块。';
  }

  @override
  String get blockLibrary_changedSelectAgain => '块库已变化，请重新选择后再试';

  @override
  String get blockLibrary_hiddenSource => '隐藏的块不能作为整理来源';

  @override
  String get blockLibrary_sameSourceSelected => '所选块包含同源副本，请分开整理';

  @override
  String get blockLibrary_sameSourceExists => '同源块已存在，请确认替换';

  @override
  String get blockLibrary_collectionMissing => '收藏集不存在';

  @override
  String get blockAppearance_classic => '经典';

  @override
  String get blockAppearance_stripes => '细条纹';

  @override
  String get blockAppearance_dots => '圆点';

  @override
  String get blockAppearance_solid => '实心';

  @override
  String get blockAppearance_gradient => '渐变';

  @override
  String get blockAppearance_translation => '翻译';

  @override
  String opusUsage_regularRemaining(Object percent) {
    return '常规免费额度：$percent%';
  }

  @override
  String opusUsage_reserveRemaining(Object percent) {
    return '备用电池额度（已激活）：$percent%';
  }

  @override
  String get opusUsage_usingRegular => '优先使用常规额度，用尽后使用备用额度';

  @override
  String get opusUsage_usingReserve => '常规额度已用尽，正在使用备用电池额度';

  @override
  String get opusUsage_regularEmpty => '常规额度已用尽，暂无可用备用额度';

  @override
  String get opusUsage_exhausted => '账号额度已用尽，V5 生成按 Anlas 计费';

  @override
  String opusUsage_recharging(Object time) {
    return '常规额度回充：下一 +1% 还需 $time';
  }

  @override
  String get opusUsage_notRecharging => '常规额度当前无回充倒计时';

  @override
  String get opusUsage_clickToRefresh => '点击刷新';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 小时 $minutes 分';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String opusUsage_seconds(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get metadataImport_noCharactersReplaceClears => '无角色数据；替换模式会清空当前角色';

  @override
  String get metadataImport_replaceCharacters => '替换角色';

  @override
  String get metadataImport_appendCharacters => '追加角色';

  @override
  String get drop_dragToShare => '拖拽以分享';

  @override
  String promptSyntax_weightTooLarge(Object value) {
    return '数值权重绝对值过大：$value::';
  }

  @override
  String promptSyntax_spaceBeforeColons(Object value) {
    return '权重数字与 :: 之间不能有空格：$value ::';
  }

  @override
  String promptSyntax_weightAfterColons(Object value) {
    return '数值权重应写在 :: 前：::$value';
  }

  @override
  String get update_errorInAppUnsupported => '当前版本不支持应用内自动安装更新';

  @override
  String get update_errorNoInstallablePackage => '未找到可自动安装的更新包';

  @override
  String get update_errorMissingSha256 => '更新包缺少 SHA256 校验信息';

  @override
  String get update_errorDiskFull => '磁盘空间不足，无法保存更新包';

  @override
  String get update_errorWriteFailed => '写入更新包失败';

  @override
  String get update_errorDownloadFailed => '下载更新包失败';

  @override
  String get update_errorSizeMismatch => '更新包大小校验失败';

  @override
  String get update_errorChecksumMismatch => '更新包校验失败';

  @override
  String get update_errorResumeRejected => '服务器拒绝了更新包续传请求';

  @override
  String get update_errorEmptyResponse => '更新服务器返回了空响应';

  @override
  String get update_errorPlatformUnsupported => '当前平台不支持应用内自动更新';

  @override
  String get update_errorPackageRemoved => '更新包已被清理，请重新下载';

  @override
  String get update_errorPackageCorrupted => '更新包已损坏，请重新下载';

  @override
  String get update_errorLaunchFailed => '启动更新程序失败';

  @override
  String get update_errorCheckFailed => '检查更新失败';

  @override
  String get update_errorCheckUnknown => '检查更新时发生未知错误';

  @override
  String update_errorLogPath(Object path) {
    return '日志：$path';
  }

  @override
  String get update_errorInstallFailed => '安装更新失败';

  @override
  String get update_errorInstallFailedSeeLog => '安装更新失败，请查看更新日志';

  @override
  String get auth_tokenEmpty => 'Token 为空，无法验证';

  @override
  String get auth_tokenFormatInvalid => 'Token 格式无效';

  @override
  String get auth_tokenInvalidOrExpired =>
      'Token无效或已过期，请检查Token是否正确。如果是Persistent Token，应以pst-开头。';

  @override
  String get auth_tokenMustStartPst => 'Token 格式无效，应以 pst- 开头';

  @override
  String get auth_tokenFormatDetail =>
      'Token 格式无效。Persistent Token 应以 pst- 开头，后跟至少10位字符。请检查输入的 Token 是否正确。';

  @override
  String get danbooru_credentialsExpired => '凭据已失效，请重新登录';

  @override
  String get danbooru_networkRetryLater => '网络连接失败，将在网络恢复后重试';

  @override
  String get danbooru_invalidCredentials => '无法验证凭据，请检查用户名和 API Key 是否正确';

  @override
  String danbooru_verifyFailed(Object error) {
    return '验证失败: $error';
  }

  @override
  String get danbooru_credentialsRequired => '用户名和 API Key 不能为空';

  @override
  String get danbooru_networkCheck => '网络连接失败，请检查网络连接';

  @override
  String get danbooru_loginFailedNetwork => '登录失败，请检查网络连接';

  @override
  String get danbooru_blacklistLoginRequired => '请先登录 Danbooru 账号';

  @override
  String get danbooru_blacklistPushFailed => '推送 Danbooru 黑名单失败';

  @override
  String danbooru_blacklistSyncFailed(Object error) {
    return '同步失败: $error';
  }

  @override
  String comfyui_submitFailed(Object detail) {
    return '提交工作流失败: $detail';
  }

  @override
  String comfyui_uploadFailed(Object detail) {
    return '上传图像失败: $detail';
  }

  @override
  String comfyui_fetchImageFailed(Object detail) {
    return '获取图像失败: $detail';
  }

  @override
  String comfyui_historyMissing(Object id) {
    return '未找到任务历史: $id';
  }

  @override
  String get comfyui_unknownError => '未知错误';

  @override
  String comfyui_cannotConnect(Object url) {
    return '无法连接到 ComfyUI 服务器 ($url)';
  }

  @override
  String get comfyui_noOutput => '任务无输出';

  @override
  String comfyui_nodesNoImage(Object nodes) {
    return '指定输出节点无图像输出: $nodes';
  }

  @override
  String get comfyui_noImageOutput => '任务无图像输出';

  @override
  String get comfyui_executionError => '执行出错';

  @override
  String comfyui_missingNodes(Object nodes) {
    return '缺少 ComfyUI 节点: $nodes。请在 ComfyUI 中安装或启用对应自定义节点后重启 ComfyUI。';
  }

  @override
  String get enhance_cannotReadSize => '无法解析图像尺寸';

  @override
  String enhance_upscaleFailed(Object error) {
    return '图像放大失败: $error';
  }

  @override
  String enhance_vibeEncodeFailed(Object error) {
    return 'Vibe编码失败: $error';
  }

  @override
  String enhance_enhanceFailed(Object error) {
    return '图像增强失败: $error';
  }

  @override
  String enhance_annotateFailed(Object error) {
    return '图像标注失败: $error';
  }

  @override
  String get enhance_timeout => '请求超时';

  @override
  String get enhance_networkError => '网络连接错误';

  @override
  String enhance_serverError(Object status) {
    return '服务器返回错误: $status';
  }

  @override
  String enhance_serverErrorDetail(Object status, Object detail) {
    return '服务器返回错误: $status ($detail)';
  }

  @override
  String get proxy_connectTimeout => '连接超时';

  @override
  String get proxy_cannotConnect => '无法连接到服务器';

  @override
  String get proxy_connectFailed => '连接失败';

  @override
  String get proxy_testServerUnreachable => '无法连接到测试服务器';

  @override
  String proxy_testFailed(Object error) {
    return '测试失败: $error';
  }

  @override
  String get avatar_noFilePath => '无法获取文件路径';

  @override
  String get avatar_sourceMissing => '源文件不存在或已被删除';

  @override
  String avatar_copyFailed(Object error) {
    return '无法复制文件：$error';
  }

  @override
  String avatar_saveFailed(Object error) {
    return '无法保存头像：$error';
  }

  @override
  String avatar_operationFailed(Object error) {
    return '操作失败：$error';
  }

  @override
  String get vibeExport_rawImage => '原始图片';

  @override
  String get vibeExport_vibePreview => 'Vibe 预览图';

  @override
  String get vibeExport_libraryThumbnail => '库缩略图';

  @override
  String get vibeExport_pngTitle => '导出 PNG Vibe 图片';

  @override
  String get vibeExport_pngDirectoryTitle => '选择 PNG 导出目录';

  @override
  String get vibeExport_fileTitle => '导出 Vibe 文件';

  @override
  String get vibeExport_bundleTitle => '导出 Vibe Bundle';

  @override
  String get vibeExport_zipTitle => '导出 Vibe ZIP';

  @override
  String get vibeExport_nothingToExport => '没有可导出的 Vibe 条目';

  @override
  String get vibeImport_fileParseFailed => '文件解析失败';

  @override
  String get vibeImport_importFiles => '导入文件';

  @override
  String get vibeImport_noVibeData => '图片不包含有效 Vibe 数据';

  @override
  String get vibeImport_importImages => '导入图片';

  @override
  String get vibeImport_encodingParseFailed => '编码解析失败';

  @override
  String get vibeImport_importEncodings => '导入编码';

  @override
  String vibeImport_namingCancelled(Object name) {
    return '用户取消命名，已跳过: $name';
  }

  @override
  String vibeImport_nameEmpty(Object name) {
    return '名称为空，已跳过: $name';
  }

  @override
  String vibeImport_nameConflict(Object name) {
    return '名称冲突，已跳过: $name';
  }

  @override
  String get vibeImport_saveFailed => '保存失败';

  @override
  String vibeFile_missingRawImage(Object file) {
    return '文件缺少可用的原图数据: $file (type=image). 此文件可能已损坏或不完整，建议删除后重新保存。';
  }

  @override
  String get generation_countMustBePositive => '生成数量必须大于0';

  @override
  String get generation_allTasksFailed => '所有生成任务失败';

  @override
  String get generation_failedShort => '生成失败';

  @override
  String generation_tasksFailedAfterRetry(Object count) {
    return '$count 个任务重试后仍失败';
  }

  @override
  String get generation_streamFallbackUnavailable => '流式生成不支持且无法自动回退（参数丢失）';

  @override
  String generation_streamFallbackFailed(Object error) {
    return '回退到非流式生成失败: $error';
  }

  @override
  String get generation_batchSizeMustBePositive => '批次数量和批次大小必须大于0';

  @override
  String get clipboard_unsupportedPlatform => '当前平台不支持系统剪贴板';

  @override
  String get clipboard_decodeFailed => '无法解码图片用于复制到剪贴板';

  @override
  String drop_remoteImageTooLarge(Object size) {
    return '远程图片原始下载超过 ${size}MB';
  }

  @override
  String get apiEndpoint_empty => 'API 地址不能为空';

  @override
  String get apiEndpoint_invalid => 'API 地址无效';

  @override
  String get apiEndpoint_httpOnly => '仅支持 http 或 https API 地址';

  @override
  String get apiEndpoint_noExtras => 'API 地址不能包含查询参数、片段或用户信息';

  @override
  String gallery_folderInaccessible(Object error) {
    return '无法访问图片文件夹: $error';
  }

  @override
  String gallery_scanFailed(Object error) {
    return '扫描图片失败: $error';
  }

  @override
  String gallery_galleryInitFailed(Object error) {
    return '画廊初始化失败: $error';
  }

  @override
  String get resolution_noAdjustment => '无需调整';

  @override
  String get dataRefresh_updating => '正在更新数据...';

  @override
  String dataRefresh_updatingService(Object service) {
    return '正在更新 $service...';
  }

  @override
  String get imageUse_title => '使用图片';

  @override
  String get imageUse_importContent => '导入内容';

  @override
  String get imageUse_characters => '多角色';

  @override
  String get imageUse_characterMode => '角色处理';

  @override
  String get imageMenu_details => '详情';

  @override
  String get imageMenu_creation => '创作与参考';

  @override
  String get imageMenu_editAndDerive => '编辑与派生';

  @override
  String get imageMenu_more => '更多操作';

  @override
  String get imageMenu_fileActions => '文件操作';

  @override
  String get imageMenu_saveToBlock => '存入积木';

  @override
  String get settings_highAnlasCostEstimate => '预计消耗';

  @override
  String get settings_highAnlasCostThresholdLabel => '提醒阈值';

  @override
  String get settings_highAnlasCostQuestion => '是否继续本次生成？';

  @override
  String get bridge_title => '本机桥接';

  @override
  String get bridge_agent => '外部 Agent';

  @override
  String get bridge_agentHint => '复制说明，交给能执行本机命令的 Agent。';

  @override
  String get bridge_synced => '当前内容已确认';

  @override
  String get bridge_changed => '内容已变化，等待重新确认';

  @override
  String get bridge_waiting => '等待连接';

  @override
  String get bridge_ready => '等待操作';

  @override
  String bridge_clients(int count) {
    return '$count 个 Agent 已连接';
  }

  @override
  String bridge_activity(Object client, Object action) {
    return '$client：$action';
  }

  @override
  String get bridge_read => '读取参数';

  @override
  String get bridge_write => '修改参数';

  @override
  String get bridge_quote => '预估消耗';

  @override
  String get bridge_generate => '生成图片';

  @override
  String get bridge_cancel => '停止生成';

  @override
  String get bridge_recent => '最近活动';

  @override
  String get bridge_empty => '尚无活动';

  @override
  String get bridge_copyGuide => '复制接管说明';

  @override
  String get bridge_showGuide => '查看说明';

  @override
  String get bridge_copied => '接管说明已复制';

  @override
  String get bridge_disconnect => '结束 Agent 连接';

  @override
  String get bridge_settings => '桥接设置';

  @override
  String get bridge_clientMissing => '随包客户端尚未就绪，请更新 Studio。';

  @override
  String get bridge_conflict => '内容已修改，请重新读取';

  @override
  String get bridge_busy => '另有操作正在进行';

  @override
  String get bridge_interrupted => '操作已中断';

  @override
  String get bridge_failed => '操作失败，请查看 Agent 返回的信息';

  @override
  String get bridge_timeout => '操作超时，请重试';

  @override
  String bridge_guide(Object clientPath) {
    return '请通过本机桥接协助操作 W.O.F NAI Studio。\n客户端：$clientPath\n\n1. 根据你的 shell 正确引用这个路径。先运行 status --name <你的名称>，确认连接成功；复制本说明不代表已连接。\n2. 运行 get --name <你的名称> --out current.json，读取当前状态。可编辑原文在 _draft.fields，field_versions 用于检查冲突；其余读数可能包含质量词等生效内容。不要把生效内容重复写回原文。\n3. 只修改用户授权的字段。将修改写入 changes.json，再运行 set-json changes.json --base current.json --name <你的名称>。应用会先备份，再核对这些字段；冲突时停止并重新读取，不能自动覆盖用户新修改。返回 readback 用于核对写入。characters 是整个列表替换，请保留无关角色的名称、启用状态、位置和 id。参考图目前只读，请保留 Studio 中的设置。\n4. 接入或填参不代表授权生图。只有用户明确要求生成时，先运行 quote --out quote.json --name <你的名称>，向用户报告预计 Anlas 单价和余额（余额来自当前已载入账号，实际计费以服务端为准）。授权与报告完成后运行 gen --quote quote.json --authorized --name <你的名称>。每次只生成一张；草稿改变会拒绝旧估价。\n5. 操作结束自动断开。Krita 可同时连接；busy 时等待当前操作结束，失败后不要无间隔重试。生成可在 Studio 中停止；客户端也支持 Ctrl+C，或用返回的 request_id 执行 cancel <request_id> --name <同一名称>。不要输出发现文件中的会话密钥。\n';
  }

  @override
  String get editor_drawMask => '绘制蒙版';

  @override
  String get editor_eraseMask => '擦除蒙版';

  @override
  String get editor_squareBrush => '方形画笔';

  @override
  String get editor_focusedArea => '聚焦区域';

  @override
  String get editor_minimumContext => '最小上下文边距';

  @override
  String get editor_maskAppearance => '蒙版外观';

  @override
  String get editor_maskColor => '蒙版颜色';

  @override
  String get editor_maskOpacity => '蒙版透明度';

  @override
  String get editor_maskBorder => '边框';

  @override
  String get editor_patternSolid => '纯色';

  @override
  String get editor_patternLines => '斜线';

  @override
  String get editor_patternCrosshatch => '交叉线';

  @override
  String get editor_patternDots => '圆点';

  @override
  String get editor_patternGrid => '网格';

  @override
  String get editor_patternChecker => '棋盘格';

  @override
  String get editor_patternHearts => '爱心';

  @override
  String get editor_resize => '调整尺寸';

  @override
  String get editor_penSize => '画笔大小';

  @override
  String get editor_sourceChanged => '源图已在编辑期间发生变化，请重新打开编辑器。';

  @override
  String get editor_draw => '绘制';

  @override
  String get editor_erase => '擦除';

  @override
  String get editor_select => '选择';

  @override
  String get editor_lasso => '套索';

  @override
  String get editor_roundTip => '圆形';

  @override
  String get editor_softRoundTip => '柔边圆形';

  @override
  String get editor_squareTip => '方形';

  @override
  String get editor_pressureSensitivity => '笔压感应';

  @override
  String get editor_hsvAdjustment => 'HSV 调整';

  @override
  String get editor_hue => '色相';

  @override
  String get editor_cloneSourceHint => 'Alt + 点击设置来源';

  @override
  String get editor_colorAlpha => '透明度';

  @override
  String get editor_colorHex => '颜色 HEX';

  @override
  String get editor_closestValidSize => '裁至最近的有效生成尺寸';

  @override
  String get model3d_projection => '投影';

  @override
  String get model3d_perspective => '透视投影';

  @override
  String get model3d_orthographic => '平行投影';

  @override
  String get model3d_fov => '视野角';

  @override
  String get model3d_ambient => '环境光';

  @override
  String get model3d_direct => '直接光';

  @override
  String get model3d_direction => '光线方向';

  @override
  String get model3d_front => '正面';

  @override
  String get model3d_frontTop => '正面上方';

  @override
  String get model3d_top => '顶部';

  @override
  String get model3d_left => '左侧';

  @override
  String get model3d_right => '右侧';

  @override
  String get model3d_back => '背面';

  @override
  String get model3d_shadows => '阴影';

  @override
  String get model3d_quality => '质量';

  @override
  String get model3d_veryLow => '极低';

  @override
  String get model3d_low => '低';

  @override
  String get model3d_medium => '中';

  @override
  String get model3d_high => '高';

  @override
  String get model3d_veryHigh => '极高';

  @override
  String get model3d_display => '显示';

  @override
  String get model3d_showBones => '显示骨骼';

  @override
  String get model3d_bones => '骨骼列表';

  @override
  String get model3d_noBones => '未找到骨骼';

  @override
  String get model3d_morphs => '表情形变';

  @override
  String get model3d_noMorphs => '未找到表情形变';

  @override
  String get model3d_settings => '3D 渲染设置';

  @override
  String get model3d_resetModel => '重置模型位置';

  @override
  String get model3d_removeModel => '移除模型';

  @override
  String get model3d_removeConfirm => '移除此模型？尚未保存的模型编辑将丢失。';

  @override
  String get model3d_toolTransform => '模型变换';

  @override
  String get model3d_toolPose => '模型姿势';

  @override
  String get localUpscale_local => '本地';

  @override
  String get localUpscale_manage => '管理模型';

  @override
  String get localUpscale_description => '在本机放大图片，不消耗 Anlas。';

  @override
  String get localUpscale_bundled => '内置';

  @override
  String get localUpscale_download => '下载';

  @override
  String get localUpscale_importHelp =>
      '导入配套的 4 倍 Real-ESRGAN NCNN 模型 .param 和 .bin 文件（data/output 节点）。不支持 PyTorch 或 safetensors 模型。';

  @override
  String get localUpscale_preparing => '正在准备图片…';

  @override
  String get localUpscale_inference => '正在超分…';

  @override
  String get localUpscale_resizing => '正在完成图片处理…';

  @override
  String get localUpscale_complete => '超分完成';

  @override
  String get localUpscale_cancelling => '正在取消…';

  @override
  String get localUpscale_unsupportedPlatform => '本地超分目前支持 Windows。';

  @override
  String get localUpscale_engineMissing => '本地引擎不可用，请重新安装完整 Studio 运行包。';

  @override
  String get localUpscale_integrity => '文件校验失败，请重新安装对应模型或 Studio 运行包。';

  @override
  String get localUpscale_modelMissing => '模型不可用，请选择已安装的模型，或检查模型目录路径是否过长。';

  @override
  String get localUpscale_invalidModel =>
      '模型不兼容，请导入配套的 4 倍 Real-ESRGAN NCNN 模型。';

  @override
  String get localUpscale_invalidImage => '无法读取图片，请尝试 PNG、JPEG 或 WebP 文件。';

  @override
  String get localUpscale_sizeLimit => '图片过大：模型原始输出不能超过 6400 万像素。';

  @override
  String get localUpscale_noVulkan => '未找到可用的 Vulkan 显卡，请更新显卡驱动后重试。';

  @override
  String get localUpscale_processFailed => '超分失败，请检查模型和显卡驱动。原图已保留。';

  @override
  String get localUpscale_timeout => '超分超时，请尝试较小的图片。';

  @override
  String get localUpscale_busy => '另一个超分或模型操作仍在运行。';

  @override
  String get localUpscale_cancelled => '已取消超分';

  @override
  String get localUpscale_anime => '动漫 · 画质';

  @override
  String get localUpscale_animeFast => '动漫 · 快速';

  @override
  String get localUpscale_general => '通用 · 摄影';

  @override
  String get localUpscale_downloadProgress => '正在下载模型…';

  @override
  String get localUpscale_importModel => '导入模型';

  @override
  String get localUpscale_modelOperationFailed => '模型操作失败，请检查网络、文件权限及可用空间后重试。';

  @override
  String get settings_localUpscale => '本地放大';

  @override
  String get settings_localUpscaleDescription => '管理本地放大模型与运行组件。';

  @override
  String get localUpscale_noCuda => '需要支持 CUDA 的 NVIDIA 显卡及兼容的驱动。';

  @override
  String get localUpscale_noRtx => 'RTX Video 不可用，请检查 NVIDIA RTX 显卡与驱动。';

  @override
  String get localUpscale_encoding => '正在编码图片…';

  @override
  String get localUpscale_decoding => '正在解码图片…';

  @override
  String get localUpscale_optionalComponents => '可选组件';

  @override
  String get localUpscale_noAutomaticDownload => '按需下载组件，已有的本地模型可直接使用。';

  @override
  String get localUpscale_notInstalledShort => '未安装';

  @override
  String get localUpscale_seedvr2ThreeSummary => '兼顾效果与资源占用，适合日常放大。';

  @override
  String get localUpscale_seedvr2SevenSummary => '更高画质潜力，需要更多显存与时间。';

  @override
  String get localUpscale_seedvr2SharpSummary => '偏向更锐利的细节，适合希望强化纹理的图片。';

  @override
  String get localUpscale_seedvr2SharpHelp =>
      '7B Sharp FP8 偏向更锐利的纹理与边缘。权重约 8.2 GB；与其他 SeedVR2 型号共用 VAE 和 Python/CUDA 环境。';

  @override
  String get localUpscale_seedvr2Int8Help =>
      'INT8 ConvRot（实验）：需要 NVIDIA Turing 或更新显卡。与 FP8 共用运行环境，速度与画质因图片和显卡而异。';

  @override
  String get localUpscale_noInt8 => '当前显卡或 CUDA 环境不支持原生 INT8，请选择 FP8。';

  @override
  String get localUpscale_seedvr2SharedHelp =>
      '型号共用 VAE（约 0.5 GB）和 Python/CUDA 环境，需要 NVIDIA 显卡。';

  @override
  String get localUpscale_seedvr2Help =>
      '3B FP8 兼顾效果与资源占用。权重约 3.4 GB，VAE 约 0.5 GB；与 7B 共用 VAE 和 Python/CUDA 环境，需要 NVIDIA 显卡。';

  @override
  String get localUpscale_seedvr2SevenHelp =>
      '7B FP8 有更高的画质潜力，但需要更多显存与时间。权重约 8.2 GB；与 3B 共用 VAE 和 Python/CUDA 环境。';

  @override
  String get localUpscale_outOfMemory =>
      '显存不足。可改用 3B、降低倍率，或在高级设置启用低显存和 VAE 分块。没有自动切换型号。';

  @override
  String get localUpscale_modelWeights => '权重';

  @override
  String get localUpscale_advancedSettings => '高级设置';

  @override
  String get localUpscale_seedvr2Color => '色彩校正';

  @override
  String get localUpscale_colorNone => '不校正';

  @override
  String get localUpscale_seedvr2Seed => '随机种子';

  @override
  String get localUpscale_seedvr2Memory => '显存策略';

  @override
  String get localUpscale_memoryRecommended => '推荐';

  @override
  String get localUpscale_memoryLow => '低显存';

  @override
  String get localUpscale_blocksToSwap => 'CPU 卸载层数';

  @override
  String get localUpscale_memoryHelp =>
      '卸载更多层可省显存，但会占用更多内存并变慢。低显存模式不保证任意输出尺寸都能运行。';

  @override
  String get localUpscale_vaeTiled => 'VAE 分块';

  @override
  String get localUpscale_vaeTileSize => '分块大小';

  @override
  String get localUpscale_vaeOverlap => '分块重叠';

  @override
  String get localUpscale_vaeHelp =>
      '小分块更省显存，重叠可减轻接缝。这是 VAE 编码／解码分块，不是整条超分流程分块。';

  @override
  String get localUpscale_experimental => '实验性变化';

  @override
  String get localUpscale_inputNoise => '输入噪声';

  @override
  String get localUpscale_latentNoise => '潜空间噪声';

  @override
  String get localUpscale_noiseHelp =>
      '两项保持 0 可沿用当前行为。增加噪声是增加变化，不保证细节或画质更好，也可能改变线条和脸部。';

  @override
  String get localUpscale_restoreDefaults => '恢复默认';

  @override
  String get localUpscale_rtxHelp =>
      '使用 NVIDIA RTX Video 快速放大。需下载约 64 MB 独立组件，需要兼容的 RTX 显卡。';

  @override
  String get localUpscale_installed => '已安装';

  @override
  String get localUpscale_notInstalled => '尚未安装，请到管理模型安装';

  @override
  String get localUpscale_license => '许可';

  @override
  String get localUpscale_installComponent => '安装';

  @override
  String get localUpscale_installingRuntime => '正在安装 Python/CUDA 运行环境…';

  @override
  String get localUpscale_installingPython => '正在准备独立 Python…';

  @override
  String localUpscale_installFailed(String stage) {
    return '安装失败阶段：$stage';
  }

  @override
  String get wiki_translationQueued => '等待翻译';

  @override
  String get wiki_translationFailedRetry => '翻译失败，点击重试';

  @override
  String get localUpscale_checkingComponent => '正在检查组件与显卡…';

  @override
  String get localUpscale_installingComponent => '正在下载组件…';

  @override
  String get upscale_settings => '放大设置';

  @override
  String upscale_cloudCost(int cost) {
    return '预计 $cost Anlas · 2×';
  }

  @override
  String get enhance_localAfterGeneration => '每张生成完成后自动在本机放大。';

  @override
  String get enhance_localAction => '生成并本地放大';

  @override
  String get localUpscale_stop => '停止超分';

  @override
  String get localUpscale_scrollDown => '向下滚动';

  @override
  String get wiki_exampleImages => '示例图片';

  @override
  String get wiki_exampleImagesUnavailable => '示例图片暂时无法加载';

  @override
  String get generation_perRequestLabel => '张数';

  @override
  String get generation_perRequestTooltip => '每次请求生成的张数（1–4）';

  @override
  String get generation_repeatLabel => '重复';

  @override
  String get generation_referenceUpload => '上传';

  @override
  String get generation_seedPinnedLabel => '种子 · 固定';

  @override
  String get generation_paramsDrawerTooltip => '更多参数';

  @override
  String get library_sizeSmall => '小';

  @override
  String get library_sizeMedium => '中';

  @override
  String get library_sizeLarge => '大';

  @override
  String get library_currentModel => '当前模型';

  @override
  String get library_available => '可用';

  @override
  String get library_unavailable => '不能用';

  @override
  String get library_inGeneration => '在生图页';

  @override
  String library_selectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get library_invertSelection => '反选';

  @override
  String get library_more => '更多';

  @override
  String get viewer_fit => '适应';

  @override
  String get viewer_showInfo => '显示信息栏（I）';

  @override
  String get viewer_hideInfo => '隐藏信息栏（I）';

  @override
  String get viewer_originalSize => '原始大小（1）';

  @override
  String get viewer_fullscreen => '全屏（F11）';

  @override
  String get shortcut_action_toggle_info_panel => '显示 / 隐藏信息栏';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_openBlockLibrary => '打开块库';

  @override
  String get styleExplore_drawCountLabel => '本次抽取';

  @override
  String get styleExplore_drawCountSuffix => '张 · 逐张生成';

  @override
  String get styleExplore_appliedToEditor => '已套用到编辑区';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '抽 $count 张候选';
  }

  @override
  String get stats_title => '统计';

  @override
  String get stats_subtitle => '本地图库 · 按文件时间';

  @override
  String stats_rangeDays(Object count) {
    return '$count 天';
  }

  @override
  String get stats_rangeThisYear => '今年';

  @override
  String get stats_rangeAll => '全部';

  @override
  String get stats_naiOnly => '仅 NAI 图片';

  @override
  String stats_updatedAt(Object time) {
    return '更新于 $time';
  }

  @override
  String get stats_updating => '更新中';

  @override
  String stats_counting(Object count) {
    return '正在统计 $count 张…';
  }

  @override
  String get stats_updateFailed => '更新失败';

  @override
  String get stats_refresh => '刷新';

  @override
  String stats_lastDays(Object count) {
    return '近 $count 天';
  }

  @override
  String stats_lastDaysShort(Object count) {
    return '近 $count 天';
  }

  @override
  String get stats_unitDays => '天';

  @override
  String stats_imagesCount(Object count) {
    return '$count 张';
  }

  @override
  String get stats_less => '少';

  @override
  String get stats_more => '多';

  @override
  String get stats_kpiImages => '图片';

  @override
  String get stats_kpiNewImages => '新增图片';

  @override
  String stats_kpiActiveDays(Object days, Object avg) {
    return '活跃 $days 天 · 日均 $avg';
  }

  @override
  String stats_kpiVsPrevious(Object count) {
    return '比前 $count 天';
  }

  @override
  String get stats_kpiVsLastYear => '比去年同期';

  @override
  String stats_kpiPreviousValue(Object value) {
    return '（$value）';
  }

  @override
  String get stats_kpiFavorites => '收藏';

  @override
  String stats_kpiFavoriteRate(Object rate) {
    return '收藏率 $rate';
  }

  @override
  String get stats_kpiAnlas90 => 'Anlas · 近 90 天';

  @override
  String get stats_kpiAnlasSpent => 'Anlas 消耗';

  @override
  String stats_kpiAnlasRecent(Object week, Object today) {
    return '近 7 天 $week · 今日 $today';
  }

  @override
  String stats_kpiAnlasDaily(Object avg, Object today) {
    return '日均 $avg · 今日 $today';
  }

  @override
  String get stats_kpiStreak => '连续创作';

  @override
  String stats_kpiLongest(Object days, Object unit) {
    return '最长 $days $unit';
  }

  @override
  String stats_kpiLongestRange(Object days, Object unit, Object range) {
    return '最长 $days $unit（$range）';
  }

  @override
  String get stats_kpiStorage => '占用';

  @override
  String stats_kpiStorageDetail(Object avg, Object pct) {
    return '平均 $avg · $pct 有元数据';
  }

  @override
  String get stats_calendarTitle => '创作日历';

  @override
  String get stats_calendarHint => '每格一天，颜色越深图越多';

  @override
  String get stats_calendarPastYear => '近一年';

  @override
  String stats_calendarYear(Object year) {
    return '$year 年';
  }

  @override
  String get stats_calendarImagesPastYear => '近一年图片';

  @override
  String stats_calendarImagesInYear(Object year) {
    return '$year 年图片';
  }

  @override
  String get stats_calendarActiveDays => '有创作的天数';

  @override
  String get stats_calendarBestDay => '最多的一天';

  @override
  String get stats_calendarLongestStreak => '最长连续';

  @override
  String get stats_calendarTipOpen => '点一下在本地画廊打开这一天';

  @override
  String get stats_productionTitle => '产量与模型';

  @override
  String stats_productionHintAll(Object unit) {
    return '按$unit，颜色是模型';
  }

  @override
  String stats_productionHintRange(Object range, Object unit) {
    return '$range，按$unit，颜色是模型';
  }

  @override
  String get stats_unitDay => '天';

  @override
  String get stats_unitWeek => '周';

  @override
  String get stats_unitMonth => '月';

  @override
  String get stats_granularityDay => '日';

  @override
  String get stats_granularityWeek => '周';

  @override
  String get stats_granularityMonth => '月';

  @override
  String stats_monthWithYear(Object year, Object month) {
    return '$year.$month';
  }

  @override
  String get stats_productionModelsHint => '模型 · 点一下只看这个模型的图';

  @override
  String stats_productionOtherModels(Object count) {
    return '其他 $count 个模型';
  }

  @override
  String stats_productionNoMetadata(Object count) {
    return '另有 $count 张没有元数据，图上是浅灰色';
  }

  @override
  String get stats_familyOther => '其他模型';

  @override
  String get stats_familyNoMetadata => '无元数据';

  @override
  String stats_productionTipTotal(Object period, Object count) {
    return '$period · $count 张';
  }

  @override
  String get stats_productionTipOpenDay => '点一下在本地画廊打开这一天';

  @override
  String get stats_productionTipOpenWeek => '点一下在本地画廊打开这一周';

  @override
  String get stats_productionTipOpenMonth => '点一下在本地画廊打开这个月';

  @override
  String get stats_punchTitle => '什么时候画';

  @override
  String get stats_punchHint => '星期 × 小时';

  @override
  String get stats_punchPeak => '最常在';

  @override
  String stats_punchPeakValue(Object weekday, Object from, Object to) {
    return '$weekday $from–$to 点';
  }

  @override
  String get stats_punchBusiest => '最忙';

  @override
  String get stats_punchLateNight => '深夜占';

  @override
  String get stats_punchNote => '圆越大图越多';

  @override
  String get stats_anlasTitle => 'Anlas 消耗';

  @override
  String get stats_anlasToday => '今天';

  @override
  String get stats_anlasDailyAvg => '日均';

  @override
  String stats_anlasActiveDays(Object count) {
    return '有消耗 $count 天';
  }

  @override
  String get stats_anlasPeak => '最多';

  @override
  String get stats_anlasNote => '按余额下降记录，含放大、Vibe 编码等；只保留最近 90 天';

  @override
  String get stats_aspectTitle => '画幅';

  @override
  String get stats_aspectHint => '按真实尺寸';

  @override
  String get stats_aspectOrientation => '方向';

  @override
  String get stats_orientationPortrait => '竖';

  @override
  String get stats_orientationLandscape => '横';

  @override
  String get stats_orientationSquare => '方';

  @override
  String stats_aspectShapeCount(Object orientation, Object count) {
    return '$orientation · $count';
  }

  @override
  String stats_aspectOthers(Object count, Object pct) {
    return '其他 $count 种 · $pct';
  }

  @override
  String get stats_aspectClickHint => '点一个尺寸或方向，在本地画廊只看这一类';

  @override
  String get stats_paramsTitle => '参数习惯';

  @override
  String get stats_paramsHint => '有元数据的图';

  @override
  String get stats_paramsCombo => '最常用的设置';

  @override
  String get stats_paramsSampler => '采样器';

  @override
  String get stats_paramsSteps => '步数';

  @override
  String stats_paramsStepsValue(Object count) {
    return '$count 步';
  }

  @override
  String get stats_paramsNoise => '噪声调度';

  @override
  String get stats_artistsTitle => '常用画师';

  @override
  String stats_artistsHint(Object count, Object pct) {
    return '$count 张图写了画师串（$pct）';
  }

  @override
  String get stats_artistsComputing => '正在统计画师…';

  @override
  String get stats_artistsNone => '提示词里还没有写过 artist:';

  @override
  String get stats_artistsNote => '按“出现在几张图里”排，一张图里写多次只算一次';

  @override
  String stats_artistsTipSearch(Object query) {
    return '在本地画廊搜 $query';
  }

  @override
  String get stats_artistsTipCopy => '右键：复制画师名';

  @override
  String stats_artistsCopied(Object name) {
    return '已复制 $name';
  }

  @override
  String get stats_storageTitle => '存储';

  @override
  String stats_storageFiles(Object count) {
    return '$count 个文件';
  }

  @override
  String get stats_storageMonthly => '近 12 个月每月新增';

  @override
  String stats_storageNoMetadata(Object count) {
    return '$count 张没有元数据';
  }

  @override
  String get stats_storageViewInGallery => '在本地画廊查看';

  @override
  String stats_storageLarge(Object count, Object size) {
    return '$count 张大于 10 MB · $size';
  }

  @override
  String get stats_storageView => '查看';

  @override
  String get stats_footer =>
      '每次进入统计页都检查图库有没有变化，变了就在后台重算 · 数字都可以点，点了跳到本地画廊并带上筛选';

  @override
  String get stats_emptyTitle => '本地图库里还没有图片';

  @override
  String get stats_emptyBody =>
      '生成的图会自动存进本地图库，或者把已有的图片文件夹加进来。之后这里会显示你的创作节奏、模型和参数习惯。';

  @override
  String get stats_emptyGenerate => '去生图';

  @override
  String get stats_emptyAddFolder => '添加图库文件夹';

  @override
  String get stats_errorTitle => '统计没有算出来';

  @override
  String get stats_errorRetry => '重试';

  @override
  String get navShell_page_generation => '生图';

  @override
  String get navShell_page_styleExplore => '画风探索';

  @override
  String get navShell_page_localGallery => '本地画廊';

  @override
  String get navShell_page_onlineGallery => '在线画廊';

  @override
  String get navShell_page_promptBlocks => '提示词块';

  @override
  String get navShell_page_vibeLibrary => 'Vibe 库';

  @override
  String get navShell_page_preciseRef => '精准参考库';

  @override
  String get navShell_page_tagWiki => '标签百科';

  @override
  String get navShell_page_statistics => '统计';

  @override
  String get navShell_page_settings => '设置';

  @override
  String get navShell_group_create => '创作';

  @override
  String get navShell_group_gallery => '图库';

  @override
  String get navShell_group_assets => '素材';

  @override
  String get navShell_group_tools => '工具';

  @override
  String get navShell_expand => '展开导航';

  @override
  String get navShell_collapse => '收起';

  @override
  String get navShell_pin => '钉住展开';

  @override
  String get navShell_genRunning => '生成中';

  @override
  String navShell_genRunningCount(Object current, Object total) {
    return '生成中 · 第 $current / $total 张';
  }

  @override
  String navShell_genPercent(Object percent) {
    return '$percent% · 流式预览';
  }

  @override
  String get navShell_genBack => '点一下回到生图页';

  @override
  String navShell_genDone(Object count) {
    return '已完成 $count 张，点一下查看';
  }

  @override
  String get navShell_genFailed => '生成失败';

  @override
  String get navShell_tasksTitle => '后台任务';

  @override
  String navShell_tasksRunning(Object count) {
    return '$count 个进行中';
  }

  @override
  String get navShell_tasksFooter => '全部结束 10 秒后这个图标自动消失';

  @override
  String get navShell_task_localUpscale => '本地放大';

  @override
  String get navShell_task_cloudUpscale => '云端放大';

  @override
  String get navShell_task_bulkDelete => '移到回收站';

  @override
  String get navShell_task_bulkExport => '批量导出';

  @override
  String get navShell_task_bulkMetadata => '批量编辑元数据';

  @override
  String get navShell_task_bulkAddToCollection => '加入收藏集';

  @override
  String get navShell_task_bulkRemoveFromCollection => '移出收藏集';

  @override
  String get navShell_task_bulkFavorite => '批量收藏';

  @override
  String navShell_taskImages(Object title, Object count) {
    return '$title $count 张';
  }

  @override
  String get navShell_taskJustDone => '刚刚完成';

  @override
  String get navShell_taskView => '查看';

  @override
  String get navShell_taskCancel => '取消';

  @override
  String get navShell_taskCancelling => '正在取消';

  @override
  String get navShell_taskUndo => '撤销';

  @override
  String get navShell_account => '账号';

  @override
  String get navShell_accountTitle => '登录与账号';

  @override
  String get navShell_accountCurrent => '当前';

  @override
  String get navShell_accountToken => 'API Token 登录';

  @override
  String get navShell_accountCredentials => '邮箱密码登录';

  @override
  String get navShell_accountNotSignedIn => '未登录';

  @override
  String get navShell_accountChoose => '选一个账号继续';

  @override
  String navShell_subExpires(Object date, Object days) {
    return '订阅 $date 到期 · 还剩 $days 天';
  }

  @override
  String get navShell_subExpired => '订阅已过期';

  @override
  String get navShell_anlas => 'Anlas 余额';

  @override
  String get navShell_switchAccount => '切换账号';

  @override
  String get navShell_addAccount => '添加账号';

  @override
  String get navShell_manageAccounts => '管理账号';

  @override
  String get navShell_logout => '退出登录';

  @override
  String get navShell_customize => '自定义导航栏';

  @override
  String get navShell_customizeMenu => '自定义导航栏…';

  @override
  String get navShell_customizeNote => '右键导航栏打开。隐藏的页面仍然可以用快捷键打开；生图不能隐藏';

  @override
  String get navShell_ctrlNumbers => '按住 Ctrl 显示页面编号';

  @override
  String get navShell_reset => '恢复默认';

  @override
  String get navShell_done => '完成';

  @override
  String get navShell_ctrlHint => '按住不放：显示页面编号，按数字直接跳转；松开就消失';

  @override
  String get online_title => '在线画廊';

  @override
  String get online_collapseSidebar => '收起左栏';

  @override
  String get online_expandSidebar => '展开左栏';

  @override
  String get online_sectionBrowse => '浏览';

  @override
  String get online_modeSearch => '搜索';

  @override
  String get online_modeMonthly => '月榜';

  @override
  String get online_modePopular => '热门';

  @override
  String get online_modeMyFavorites => '我的收藏';

  @override
  String get online_modeFavorites => '收藏';

  @override
  String get online_noRanking => '没有排行';

  @override
  String get online_noFavorites => '不支持收藏';

  @override
  String get online_readOnly => '只读';

  @override
  String get online_signedOut => '未登录';

  @override
  String get online_recentTitle => '最近搜索';

  @override
  String get online_recentClear => '清除';

  @override
  String get online_collections => '子集';

  @override
  String get online_newCollection => '新建子集';

  @override
  String get online_all => '全部';

  @override
  String get online_ungrouped => '未分组';

  @override
  String get online_favAuthors => '收藏的作者';

  @override
  String get online_blacklist => '黑名单';

  @override
  String online_blacklistCount(Object count) {
    return '屏蔽 $count 个标签';
  }

  @override
  String get online_srcSubAiTag => 'NAI 作品社区 · 带完整 Prompt';

  @override
  String online_srcSubSignedIn(Object name) {
    return '已登录 · $name';
  }

  @override
  String get online_srcSubSafebooru => '全年龄 · 不用登录';

  @override
  String get online_srcSubKeyOk => 'API Key 已配置';

  @override
  String get online_srcSubKeyInvalid => 'API Key 无效';

  @override
  String get online_srcSubKeyMissing => '未配置 API Key';

  @override
  String get online_switchSource => '换来源';

  @override
  String get online_capPromptSearch => '搜索作品 + Prompt';

  @override
  String get online_capTagSearch => '标签搜索';

  @override
  String get online_capMonthly => '月榜';

  @override
  String get online_capRankings => '日 / 周 / 月榜';

  @override
  String get online_capLocalFav => '本地收藏';

  @override
  String get online_capSiteFav => '网站收藏';

  @override
  String get online_capReadOnlyFav => '收藏（只读）';

  @override
  String get online_capMultiMedia => '多图作品';

  @override
  String get online_capParams => '生成参数';

  @override
  String get online_capRatings => '评级';

  @override
  String get online_capSfwOnly => '只有全年龄';

  @override
  String get online_acctNone => '不用登录';

  @override
  String get online_acctSignedIn => '已登录';

  @override
  String get online_acctKeyOk => 'Key 已配置';

  @override
  String get online_acctKeyInvalid => 'Key 无效';

  @override
  String get online_acctKeyMissing => '未配置 Key';

  @override
  String get online_sourceMemory => '每个来源记住自己的搜索词和滚动位置';

  @override
  String get online_searchWorkHint => '作品、作者、标题、标签或模型';

  @override
  String get online_searchPromptHint => 'Prompt 含有…（支持 ::artist: 原始语法）';

  @override
  String get online_searchTagHint => '加标签，空格分隔，前面加 - 是排除';

  @override
  String get online_searchFavHint => '在收藏里找：标题、作者、标签';

  @override
  String get online_fuzzy => '模糊匹配';

  @override
  String get online_clearSearch => '清空搜索';

  @override
  String get online_sizeSmall => '小卡片（不显示标题）';

  @override
  String get online_sizeMedium => '中';

  @override
  String get online_sizeLarge => '大';

  @override
  String get online_multiSelect => '多选';

  @override
  String get online_doneMultiSelect => '完成多选';

  @override
  String get online_refresh => '刷新';

  @override
  String get online_inspector => '检查器';

  @override
  String get online_naiOnly => '仅 NAI 图片';

  @override
  String get online_model => '模型';

  @override
  String get online_modelAll => '全部';

  @override
  String get online_timeAll => '全部时间';

  @override
  String online_timeYear(Object year) {
    return '$year 年';
  }

  @override
  String get online_timeOlder => '更早归档';

  @override
  String online_loaded(Object count, Object pages) {
    return '已加载 $count 张 · $pages 页';
  }

  @override
  String online_rankLoaded(Object count) {
    return '第 1–$count 名 · 已加载 $count 张';
  }

  @override
  String get online_jumpToPage => '跳转到页';

  @override
  String get online_jumpGo => '跳转';

  @override
  String get online_ratingLabel => '评级';

  @override
  String get online_ratingG => '全年龄';

  @override
  String get online_ratingS => '轻微';

  @override
  String get online_ratingQ => '敏感';

  @override
  String get online_ratingE => '露骨';

  @override
  String get online_dateRange => '日期范围';

  @override
  String get online_clearDateRange => '不限日期';

  @override
  String get online_rankCurrent => '实时月榜';

  @override
  String get online_rankDay => '日榜';

  @override
  String get online_rankWeek => '周榜';

  @override
  String get online_rankMonth => '月榜';

  @override
  String get online_today => '今天';

  @override
  String get online_previous => '上一个';

  @override
  String get online_next => '下一个';

  @override
  String get online_sort => '排序';

  @override
  String get online_sortFavTime => '收藏时间';

  @override
  String get online_favAll => '全部收藏';

  @override
  String online_countImages(Object count) {
    return '$count 张';
  }

  @override
  String online_authorSaved(Object count, Object date) {
    return '收藏了 $count 张 · 收藏作者于 $date';
  }

  @override
  String get online_authorAllWorks => '在 AI TAG 看 TA 的全部作品';

  @override
  String get online_unfavAuthor => '取消收藏作者';

  @override
  String get online_favAuthor => '收藏作者';

  @override
  String get online_dragHint => '把卡片拖到左边的子集就是移动；右键 → 移到子集 / 取消收藏';

  @override
  String get online_readOnlyNote => '只读：Gelbooru 收藏只能看，要在网站上改';

  @override
  String get online_returnPrev => '返回之前的结果';

  @override
  String get online_send => '发送到生图';

  @override
  String get online_sendTags => '发送标签到生图';

  @override
  String get online_sendModes => '选择发送方式';

  @override
  String get online_favorite => '收藏';

  @override
  String get online_favorited => '已收藏';

  @override
  String get online_copyPrompt => '复制 Prompt';

  @override
  String get online_copyTags => '复制标签';

  @override
  String get online_download => '下载';

  @override
  String online_downloadAll(Object count) {
    return '下载全部 $count 张';
  }

  @override
  String get online_downloadCurrent => '只下载这一张';

  @override
  String get online_more => '更多';

  @override
  String get online_openInBrowser => '在网站打开';

  @override
  String get online_onlyAuthor => '只看 TA';

  @override
  String get online_moveTo => '移到子集';

  @override
  String get online_unfavorite => '取消收藏';

  @override
  String get online_rename => '重命名';

  @override
  String get online_deleteCollection => '删除子集';

  @override
  String get online_inspWork => '作品';

  @override
  String get online_inspPost => '帖子';

  @override
  String online_youSaved(Object count) {
    return '你收藏了 TA $count 张';
  }

  @override
  String get online_params => '生成参数';

  @override
  String get online_pModel => '模型';

  @override
  String get online_pSize => '尺寸';

  @override
  String get online_pSeed => '种子';

  @override
  String get online_pSampler => '采样器';

  @override
  String get online_pStepsCfg => '步数 · 引导';

  @override
  String get online_prompt => '提示词';

  @override
  String get online_negative => '负面';

  @override
  String get online_tags => '标签';

  @override
  String get online_tagsHint => '点一下加入搜索';

  @override
  String get online_tagArtist => '画师';

  @override
  String get online_tagCopyright => '作品';

  @override
  String get online_tagCharacter => '角色';

  @override
  String get online_tagGeneral => '一般';

  @override
  String get online_tagMeta => '元标签';

  @override
  String get online_copy => '复制';

  @override
  String get online_noSelection => '单击一张卡片，在这里看 Prompt 和生成参数';

  @override
  String online_detailError(Object error) {
    return '详情没加载出来：$error';
  }

  @override
  String get online_retry => '重试';

  @override
  String get online_noPrompt => '这张图没有 Prompt';

  @override
  String online_selCount(Object count) {
    return '已选 $count 张';
  }

  @override
  String get online_selAll => '全选';

  @override
  String get online_selInvert => '反选';

  @override
  String get online_favoriteTo => '收藏到…';

  @override
  String get online_favoriteToTitle => '收藏到';

  @override
  String get online_favoriteToSite => '收藏到网站';

  @override
  String online_downloadN(Object count) {
    return '下载 · $count 张图';
  }

  @override
  String get online_newCollectionAndFav => '新建子集并收藏';

  @override
  String get online_collectionNameHint => '子集名称，回车确认';

  @override
  String get online_exitMulti => '退出多选';

  @override
  String get online_sendRemember => '记住这次的选择';

  @override
  String get online_sendReplace => '替换提示词，清空角色框';

  @override
  String online_sendReplaceDesc(Object count) {
    return '正向 + 负面换成这张图的；生图页现有的 $count 个角色框清空。和以前卡片上的发送按钮一样';
  }

  @override
  String get online_sendReplaceDescNone =>
      '正向 + 负面换成这张图的；生图页的角色框清空。和以前卡片上的发送按钮一样';

  @override
  String get online_sendPromptOnly => '只替换提示词，保留角色框';

  @override
  String get online_sendPromptOnlyDesc => '适合只想借画师串和画面描述';

  @override
  String get online_sendParams => '提示词 + 生成参数';

  @override
  String get online_sendParamsDesc =>
      '再套用尺寸、种子、采样器、步数、引导和图里的角色框，和本地图库“复用参数”同一条链';

  @override
  String get online_sendParamsUnavailable => '这张图没有生成参数，只能发送提示词';

  @override
  String online_sendNote(Object count) {
    return '生图页现在的正向有 $count 字，会被替换';
  }

  @override
  String get online_sendNoteEmpty => '生图页现在的正向是空的';

  @override
  String get online_cancel => '取消';

  @override
  String get online_sendGo => '发送并去生图页';

  @override
  String get online_blacklistDesc => '命中的作品直接不显示';

  @override
  String get online_blacklistAddHint => '加标签，回车确认';

  @override
  String online_blacklistSync(Object count) {
    return '同步 Danbooru 账号黑名单 · $count 个';
  }

  @override
  String get online_blacklistScope => '对四个来源都生效；AI TAG 按作品标签匹配';

  @override
  String get online_blacklistEmpty => '还没有屏蔽的标签';

  @override
  String get online_removeTag => '删除';

  @override
  String online_appendError(Object page, Object reason) {
    return '第 $page 页没加载出来：$reason';
  }

  @override
  String get online_retryPage => '重试这一页';

  @override
  String online_end(Object count) {
    return '已经到底了 · 共 $count 张';
  }

  @override
  String online_endBlocked(Object count, Object blocked) {
    return '已经到底了 · 共 $count 张 · 黑名单挡掉 $blocked 张';
  }

  @override
  String online_emptyTitle(Object query) {
    return '没有找到 “$query” 的作品';
  }

  @override
  String get online_emptyTitleNoQuery => '没有找到作品';

  @override
  String get online_emptyHint => '试试放宽下面这些条件';

  @override
  String get online_sugNaiOff => '去掉“仅 NAI 图片”';

  @override
  String get online_sugClearPrompt => '清空 Prompt 条件';

  @override
  String get online_sugAllTime => '换成全部时间';

  @override
  String get online_sugAllModels => '模型改成全部';

  @override
  String get online_sugAllRatings => '评级全选';

  @override
  String get online_sugNoDate => '去掉日期范围';

  @override
  String get online_favEmpty => '这里还没有收藏';

  @override
  String get online_favEmptyHint => '在卡片上点 ♡ 就能收藏';

  @override
  String online_loadError(Object error) {
    return '没加载出来：$error';
  }

  @override
  String get online_loginDbTitle => '登录 Danbooru 后才能看你的收藏';

  @override
  String get online_loginDbDesc =>
      '用用户名 + API Key 登录，收藏会和网站同步；\n在卡片上点 ♡ 也是直接收藏到网站';

  @override
  String get online_loginDb => '登录 Danbooru';

  @override
  String get online_loginGbTitle => '配置 Gelbooru API Key 后才能看收藏';

  @override
  String get online_loginGbDesc => 'Gelbooru 收藏只能看，不能在这里改';

  @override
  String get online_loginGb => '配置 API Key';

  @override
  String get online_apiKeyHelp => '去哪里拿 API Key';

  @override
  String get online_loginOther => '不想登录？AI TAG 的收藏存在本机，不要账号；Gelbooru 收藏只能看不能改';

  @override
  String online_viewerPosition(
    Object image,
    Object images,
    Object work,
    Object works,
  ) {
    return '图 $image / $images · 作品 $work / $works';
  }

  @override
  String online_viewerWorkPosition(Object work, Object works) {
    return '作品 $work / $works';
  }

  @override
  String get online_close => '关闭';

  @override
  String get online_keyImage => '这一组里切图';

  @override
  String get online_keyWork => '上一个 / 下一个作品';

  @override
  String get online_keyInfo => '收起信息栏';

  @override
  String get refs_vibeTitle => 'Vibe 库';

  @override
  String get refs_preciseTitle => '精准参考库';

  @override
  String get refs_collapseSidebar => '收起左栏';

  @override
  String get refs_expandSidebar => '展开左栏';

  @override
  String get refs_viewAll => '全部';

  @override
  String get refs_viewFavorites => '收藏';

  @override
  String get refs_viewRecent => '最近使用';

  @override
  String get refs_viewInGeneration => '在生图页';

  @override
  String get refs_categories => '分类';

  @override
  String get refs_newCategory => '新建分类';

  @override
  String get refs_newSubcategory => '新建子分类';

  @override
  String get refs_deleteCategory => '删除分类';

  @override
  String get refs_categoryNameHint => '分类名称';

  @override
  String get refs_noCategories => '还没有分类。导入时可以顺手建一个';

  @override
  String get refs_uncategorized => '未分类';

  @override
  String get refs_sources => '来源';

  @override
  String get refs_srcPng => 'PNG（内含 Vibe）';

  @override
  String get refs_srcVibeFile => 'Vibe 文件';

  @override
  String get refs_srcBundle => '组合包';

  @override
  String get refs_srcRaw => '待编码的图片';

  @override
  String get refs_srcImage => '图片';

  @override
  String get refs_open => '打开';

  @override
  String get refs_types => '参考类型';

  @override
  String refs_importTypeNoteAll(Object type) {
    return '导入的图片默认按 $type 存。选中左边某个类型再导入，就按那个类型存。';
  }

  @override
  String refs_importTypeNoteSelected(Object type) {
    return '导入的图片默认按 $type 存。跟着左边选中的类型。';
  }

  @override
  String get refs_preciseOnlyV45 => '只在 V4.5 可用';

  @override
  String refs_preciseCostNote(Object cost) {
    return '每张 $cost Anlas；和 Vibe 不能同时生效';
  }

  @override
  String get refs_searchVibe => '搜索名称、标签';

  @override
  String get refs_searchPrecise => '搜索名称';

  @override
  String get refs_sortLastUsed => '最近使用';

  @override
  String get refs_sortCreated => '加入时间';

  @override
  String get refs_sortUsed => '使用次数';

  @override
  String get refs_sortName => '名称';

  @override
  String get refs_sortAsc => '升序';

  @override
  String get refs_sortDesc => '降序';

  @override
  String get refs_sizeSmall => '小卡片';

  @override
  String get refs_sizeMedium => '中';

  @override
  String get refs_sizeLarge => '大';

  @override
  String get refs_currentModel => '当前模型';

  @override
  String get refs_usable => '可用';

  @override
  String get refs_unusable => '不能用';

  @override
  String get refs_multi => '多选';

  @override
  String get refs_multiDone => '完成多选';

  @override
  String get refs_import => '导入';

  @override
  String get refs_importFiles => '选择文件…';

  @override
  String get refs_importImages => '选择图片…';

  @override
  String get refs_importClipboard => '从剪贴板粘贴';

  @override
  String get refs_more => '更多';

  @override
  String get refs_exportAll => '导出全部…';

  @override
  String get refs_openLibraryFolder => '打开库文件夹';

  @override
  String get refs_rescan => '重新扫描文件夹';

  @override
  String get refs_reload => '重新载入';

  @override
  String get refs_hideInspector => '收起检查器';

  @override
  String get refs_showInspector => '展开检查器';

  @override
  String refs_bannerVibeLead(Object model) {
    return '$model 不支持 Vibe 迁移。';
  }

  @override
  String get refs_bannerVibeBody => '库里的 Vibe 照常整理、导出；切到 V4.5 或 V4 才能用于生成';

  @override
  String refs_bannerPreciseLead(Object model) {
    return '$model 不支持精准参考。';
  }

  @override
  String get refs_bannerPreciseBody => '库里的参考图照常整理；切到 V4.5 才能用于生成';

  @override
  String refs_switchTo(Object model) {
    return '切到 $model';
  }

  @override
  String get refs_quickAll => '全部';

  @override
  String get refs_quickFavorites => '收藏';

  @override
  String get refs_quickHasRaw => '有原图';

  @override
  String get refs_quickNeedsEncoding => '需要编码';

  @override
  String get refs_quickBundles => '组合包';

  @override
  String get refs_quickUnused => '没用过';

  @override
  String refs_countVibe(Object count, Object inGen) {
    return '$count 个 · $inGen 个在生图页';
  }

  @override
  String refs_countPrecise(Object count, Object inGen) {
    return '$count 张 · $inGen 张在生图页';
  }

  @override
  String get refs_noResults => '没有符合条件的条目';

  @override
  String refs_noResultsFor(Object query) {
    return '没有找到“$query”';
  }

  @override
  String get refs_clearFilters => '清除筛选';

  @override
  String get refs_addShort => '加入生图';

  @override
  String get refs_sendPrecise => '发送到精准参考';

  @override
  String get refs_openBundle => '打开组合包';

  @override
  String get refs_detail => '详情';

  @override
  String get refs_addToGeneration => '加入生图页';

  @override
  String get refs_replaceVibes => '替换生图页的 Vibe';

  @override
  String get refs_replacePrecise => '替换现有精准参考';

  @override
  String get refs_sendImg2Img => '发送到图生图';

  @override
  String get refs_saveAsVibe => '存进 Vibe 库';

  @override
  String get refs_favorite => '收藏';

  @override
  String get refs_unfavorite => '取消收藏';

  @override
  String get refs_replacePreview => '换预览图…';

  @override
  String get refs_exportEllipsis => '导出…';

  @override
  String get refs_showInFolder => '在文件夹中显示';

  @override
  String get refs_copyImage => '复制图片';

  @override
  String get refs_delete => '删除';

  @override
  String refs_selected(Object count) {
    return '已选 $count';
  }

  @override
  String get refs_moveTo => '移到';

  @override
  String get refs_export => '导出';

  @override
  String get refs_emptyVibeTitle => '把图片或 Vibe 文件拖到这里';

  @override
  String get refs_emptyPreciseTitle => '把参考图拖到这里';

  @override
  String get refs_emptyVibeDesc =>
      '支持 PNG（内含 Vibe）、.naiv4vibe、.naiv4vibebundle 和普通图片。\n普通图片先存原图，第一次用在生图时才编码';

  @override
  String get refs_emptyPreciseDesc =>
      '角色设定图、风格样张都行，一次可以拖很多张。\n存进来时记住类型、强度和保真度，发送时直接套用';

  @override
  String get refs_pickFiles => '选择文件';

  @override
  String get refs_pasteClipboard => '从剪贴板粘贴';

  @override
  String get refs_emptyFromResultVibe => '生图结果右键 → 存到 Vibe 库';

  @override
  String get refs_emptyFromResultPrecise => '生图结果右键 → 存到精准参考库';

  @override
  String get refs_emptyFromGallery => '本地图库也可以';

  @override
  String get refs_emptyHelpTitle => 'Vibe 和精准参考有什么区别？';

  @override
  String refs_emptyHelpBody(Object cost) {
    return 'Vibe：借整体氛围和画风，可以叠很多张（V4 / V4.5，V5 没有）。精准参考：照着一张图的人物或画风来画，更准，每张 $cost Anlas（只在 V4.5）。两者不能同时生效。';
  }

  @override
  String refs_dropTitle(Object count) {
    return '松开导入 $count 个文件';
  }

  @override
  String get refs_dropVibeDesc => '会先打开导入窗口确认，不会直接扣 Anlas';

  @override
  String get refs_dropPreciseDesc => '按左栏选中的类型存进精准参考库';

  @override
  String refs_dropVibePngs(Object count) {
    return '$count 个 PNG 含 Vibe';
  }

  @override
  String refs_dropVibeFiles(Object count) {
    return '$count 个 Vibe 文件';
  }

  @override
  String refs_dropBundles(Object count) {
    return '$count 个组合包';
  }

  @override
  String refs_dropImages(Object count) {
    return '$count 张普通图片';
  }

  @override
  String get refs_inGeneration => '在生图页';

  @override
  String get refs_tag => '标签';

  @override
  String get refs_strengthShort => '强度';

  @override
  String get refs_infoShort => '信息';

  @override
  String get refs_fidelityShort => '保真';

  @override
  String refs_encModelOff(Object model) {
    return '$model 不可用';
  }

  @override
  String refs_encModelOffDesc(Object model) {
    return '$model 不支持 Vibe 迁移，切到 V4.5 / V4 才能用';
  }

  @override
  String refs_encReady(Object model) {
    return '已编码 · $model';
  }

  @override
  String refs_encReadyShort(Object model) {
    return '$model 已编码';
  }

  @override
  String get refs_encReadyDesc => '当前模型直接能用，不再收编码费';

  @override
  String get refs_encOnUse => '用时编码';

  @override
  String refs_encOnUseDesc(Object cost) {
    return '还没编码。第一次用在生图时编码，$cost Anlas';
  }

  @override
  String get refs_encRe => '需重新编码';

  @override
  String refs_encReDesc(Object from, Object model, Object cost) {
    return '编码是给 $from 的，当前是 $model。用时按原图重新编码，$cost Anlas';
  }

  @override
  String refs_encUnusable(Object model) {
    return '不能用于 $model';
  }

  @override
  String refs_encUnusableDesc(Object from, Object model) {
    return '只有 $from 的编码，没有原图，没法给 $model 重新编码';
  }

  @override
  String get refs_trayVibe => '生图页的 Vibe';

  @override
  String get refs_trayPrecise => '生图页的精准参考';

  @override
  String refs_trayVibeCost(Object free, Object extra) {
    return '超过 $free 个每个多 $extra Anlas';
  }

  @override
  String refs_trayPreciseCost(Object cost, Object total) {
    return '每张 $cost Anlas · 本次 +$total';
  }

  @override
  String get refs_trayHint => '拖卡片到这里加入；Shift 拖入 = 替换全部。\n发送后不跳页，可以连续挑';

  @override
  String get refs_trayDropHere => '把卡片拖到这里加入生图页';

  @override
  String get refs_clear => '清空';

  @override
  String get refs_goGeneration => '去生图页';

  @override
  String refs_conflict(Object count) {
    return '生图页还有 **$count 个 Vibe**。有精准参考时 Vibe 不会发送（官方不兼容）';
  }

  @override
  String refs_conflictPaused(Object count) {
    return '生图页的 **$count 个 Vibe** 已暂停，发送时只带精准参考';
  }

  @override
  String get refs_pauseVibes => '暂停 Vibe';

  @override
  String get refs_resumeVibes => '恢复 Vibe';

  @override
  String get refs_inspector => '检查器';

  @override
  String refs_selectedN(Object count) {
    return '已选 $count 个';
  }

  @override
  String get refs_noSelectionVibe => '点一张卡片看它的参数和编码状态';

  @override
  String get refs_noSelectionPrecise => '点一张参考图看它的类型和参数';

  @override
  String get refs_rename => '改名';

  @override
  String get refs_replace => '替换';

  @override
  String get refs_replaceVibesTip => '替换生图页现有的全部 Vibe';

  @override
  String get refs_strength => '强度';

  @override
  String get refs_strengthDesc => '越高越像这张图的感觉';

  @override
  String get refs_infoExtracted => '信息提取';

  @override
  String refs_infoDesc(Object cost) {
    return '越高带进来的细节越多。改它要按原图重新编码，$cost Anlas';
  }

  @override
  String get refs_infoLocked => '这条只有编码数据、没有原图，信息提取改不了';

  @override
  String get refs_changedNote => '改动只用于这次发送';

  @override
  String get refs_saveDefault => '存为默认';

  @override
  String get refs_revert => '还原';

  @override
  String get refs_encOnUseBody => '还没编码。第一次用在生图时编码。';

  @override
  String refs_encReBody(String from, String model) {
    return '编码是给 $from 的，当前是 $model。用时按原图重新编码。';
  }

  @override
  String refs_encodeAction(String model) {
    return '为 $model 编码';
  }

  @override
  String refs_encodingPrice(int cost) {
    return '$cost Anlas';
  }

  @override
  String refs_encodeNow(Object model, Object cost) {
    return '现在为 $model 编码 · $cost Anlas';
  }

  @override
  String refs_bundleNote(Object count) {
    return '组合包里的 $count 个 Vibe 各有自己的强度和信息提取，打开组合包可以单独调。';
  }

  @override
  String refs_bundleOf(Object count) {
    return '组合包 · $count 个';
  }

  @override
  String get refs_organize => '整理';

  @override
  String get refs_category => '分类';

  @override
  String get refs_tags => '标签';

  @override
  String get refs_used => '用过';

  @override
  String get refs_neverUsed => '还没用过';

  @override
  String refs_usedTimes(Object count, Object last) {
    return '$count 次 · 上次 $last';
  }

  @override
  String get refs_added => '加入';

  @override
  String get refs_file => '文件';

  @override
  String get refs_original => '原图';

  @override
  String refs_plusAnlas(Object cost) {
    return '+$cost Anlas';
  }

  @override
  String get refs_alsoSaveVibe => '也存进 Vibe 库';

  @override
  String get refs_referenceWhat => '参考什么';

  @override
  String get refs_typeCharacter => '角色';

  @override
  String get refs_typeStyle => '风格';

  @override
  String get refs_typeBoth => '角色+风格';

  @override
  String get refs_typeCharacterDesc => '保留人物长相、发型和服装，画风跟提示词走';

  @override
  String get refs_typeStyleDesc => '只借画风、配色和笔触，不管画的是谁';

  @override
  String get refs_typeBothDesc => '人物和画风都参考';

  @override
  String get refs_preciseStrength => '参考强度';

  @override
  String get refs_preciseStrengthDesc => '越高越像参考图';

  @override
  String get refs_fidelity => '保真度';

  @override
  String get refs_fidelityDesc => '越高越贴原图细节，越低越自由';

  @override
  String get refs_preciseDefaultsNote => '这里改的是默认值，发送时直接带上；数字框可以填超过 0–1 的值';

  @override
  String get refs_showInFolderShort => '所在文件夹';

  @override
  String get refs_pickHint => '勾选卡片后在这里批量设置';

  @override
  String get refs_multiAddTitle => '一起加入生图页';

  @override
  String get refs_multiSendTitle => '一起发送到精准参考';

  @override
  String refs_multiFree(Object free) {
    return '不超过 $free 个，不额外收费。';
  }

  @override
  String refs_multiExtra(Object free, Object extra, Object total) {
    return '超过 $free 个，每多一个 +$extra Anlas：这次每张图多 $total Anlas。';
  }

  @override
  String refs_multiOverMax(Object max) {
    return '超过 $max 个上限，多出的不会加入。';
  }

  @override
  String refs_multiEncodes(Object count, Object names, Object cost) {
    return '其中 $count 个需要编码（$names，每个 $cost Anlas，只收一次）。';
  }

  @override
  String refs_multiAlready(Object count) {
    return '$count 个已经在生图页，不会重复加入。';
  }

  @override
  String refs_multiPreciseCost(Object cost, Object total) {
    return '每张 $cost Anlas，发送后每张图共 $total Anlas。';
  }

  @override
  String get refs_unify => '统一设置';

  @override
  String get refs_mixed => '混合';

  @override
  String refs_unifyVibeNote(Object count) {
    return '拖动后 $count 个一起改，写回各自的默认值；信息提取不统一改（要重新编码）';
  }

  @override
  String refs_unifyPreciseNote(Object count) {
    return '点一下把 $count 张都改成这个类型';
  }

  @override
  String get refs_moveToCategory => '移到分类';

  @override
  String get refs_addTag => '加标签';

  @override
  String get refs_packBundle => '打包成组合包';

  @override
  String get refs_close => '关闭';

  @override
  String get refs_cancel => '取消';

  @override
  String get refs_remove => '移除';

  @override
  String get refs_prev => '上一个';

  @override
  String get refs_next => '下一个';

  @override
  String get refs_switch => '切换';

  @override
  String get refs_dropReplacePreview => '把新图拖到这里 = 换掉预览图（不影响编码）';

  @override
  String refs_bundleOfVibes(Object count) {
    return '组合包 · $count 个 Vibe';
  }

  @override
  String refs_bundleAll(Object count) {
    return '全部 $count 个';
  }

  @override
  String refs_bundleOnlyChecked(Object count) {
    return '只用勾选的 $count 个';
  }

  @override
  String get refs_bundleScopeNote => '发送时按包里每个 Vibe 自己的强度和信息提取';

  @override
  String get refs_splitBundle => '拆成单独的 Vibe';

  @override
  String get refs_bundleNoteLong => '改了某一个的参数后，可以“保存到组合包”；不保存只影响这次发送。';

  @override
  String refs_bundleAllEncoded(Object count, Object model) {
    return '包里 $count 个都已为 $model 编码';
  }

  @override
  String get refs_saveToBundle => '保存到组合包';

  @override
  String get refs_cover => '封面';

  @override
  String get refs_setCover => '设为封面';

  @override
  String refs_exportTitle(Object count) {
    return '导出 $count 个 Vibe';
  }

  @override
  String get refs_exportListNote => '从库里多选后点“导出”进来；也能在这里移掉';

  @override
  String get refs_exportAs => '导出成';

  @override
  String get refs_fmtVibeFile => '单个 Vibe 文件';

  @override
  String get refs_fmtVibeFileDesc => '.naiv4vibe，每个一份。官网和其他客户端都能导入';

  @override
  String get refs_fmtBundle => '打包成组合包';

  @override
  String refs_fmtBundleDesc(Object count) {
    return '.naiv4vibebundle，$count 个合成一个文件';
  }

  @override
  String get refs_fmtPng => '嵌入到 PNG';

  @override
  String get refs_fmtPngDesc => '图片自带 Vibe，发给别人拖进来就能用。一次只能导出一个';

  @override
  String get refs_fmtEncoded => '编码文本';

  @override
  String get refs_fmtEncodedDesc => 'JSON / Base64，给脚本和高级用法';

  @override
  String get refs_options => '选项';

  @override
  String get refs_optThumbs => '带缩略图';

  @override
  String get refs_optThumbsDesc => '文件稍大，导入时能直接看到图';

  @override
  String get refs_optZip => '压缩成 ZIP';

  @override
  String refs_optZipDesc(Object count) {
    return '$count 个文件放进一个压缩包';
  }

  @override
  String get refs_saveTo => '保存到';

  @override
  String get refs_choose => '选择';

  @override
  String refs_exportSummary(Object count, Object ext) {
    return '将生成 $count 个 $ext 文件';
  }

  @override
  String refs_exportSummaryZip(Object count, Object ext) {
    return '将生成 1 个 ZIP（内含 $count 个 $ext 文件）';
  }

  @override
  String refs_deleteOne(Object name) {
    return '删除“$name”？';
  }

  @override
  String refs_deleteMany(Object count) {
    return '删除 $count 个条目？';
  }

  @override
  String get refs_deleteVibeDesc => '从 Vibe 库移除。生图页已经在用的不受影响。';

  @override
  String get refs_deletePreciseDesc => '从精准参考库移除。生图页已经在用的不受影响。';

  @override
  String refs_importTitle(Object count) {
    return '导入 $count 个文件';
  }

  @override
  String get refs_importSubtitle => '拖进来的、选的、粘贴的都走这一个窗口';

  @override
  String get refs_importMore => '再加文件';

  @override
  String get refs_importPutIn => '全部放进';

  @override
  String get refs_importAddTags => '加标签';

  @override
  String get refs_importTagsHint => '输入后回车';

  @override
  String get refs_importPlainImages => '普通图片';

  @override
  String get refs_importEncodeLater => '用到时再编码';

  @override
  String refs_importEncodeNow(Object cost) {
    return '现在编码 · $cost Anlas/张';
  }

  @override
  String get refs_importName => '名称';

  @override
  String get refs_importResult => '识别结果';

  @override
  String refs_recPng(Object model) {
    return 'PNG 内含 Vibe · $model 编码';
  }

  @override
  String refs_recVibeFile(Object model) {
    return 'Vibe 文件 · $model 编码';
  }

  @override
  String refs_recBundle(Object count) {
    return '组合包 · $count 个 Vibe';
  }

  @override
  String get refs_recImage => '普通图片 · 还没编码';

  @override
  String get refs_recImageDup => '普通图片 · 名称已存在';

  @override
  String get refs_recFree => '直接导入，免费';

  @override
  String refs_recReencode(Object model) {
    return '用在 $model 时要重新编码（文件里没有原图就不行）';
  }

  @override
  String refs_recBundleNote(Object count) {
    return '整个导入 = 库里一张卡；拆开 = $count 张卡';
  }

  @override
  String get refs_recEncodeLater => '先存原图，第一次用在生图时为当时的模型编码';

  @override
  String refs_recEncodeNow(Object cost) {
    return '导入时就编码，每张 $cost Anlas';
  }

  @override
  String get refs_bundleWhole => '整个导入';

  @override
  String refs_bundleSplit(Object count) {
    return '拆成 $count 个';
  }

  @override
  String get refs_bundlePick => '挑几个';

  @override
  String get refs_dupExists => '库里已有同名条目';

  @override
  String get refs_dupKeepBoth => '两个都留';

  @override
  String get refs_dupOverwrite => '覆盖';

  @override
  String get refs_dupSkip => '跳过';

  @override
  String refs_importSummary(Object files, Object cards) {
    return '$files 个文件 → 库里多 $cards 张卡';
  }

  @override
  String refs_importNow(Object cost) {
    return ' · 现在扣 $cost Anlas';
  }

  @override
  String refs_importLater(Object count, Object cost) {
    return ' · $count 张普通图片第一次用在生图时各编码一次（每张 $cost Anlas）';
  }

  @override
  String get refs_pickerVibeTitle => '从 Vibe 库添加';

  @override
  String get refs_pickerPreciseTitle => '从精准参考库添加';

  @override
  String get refs_openVibeLibrary => '打开 Vibe 库';

  @override
  String get refs_openPreciseLibrary => '打开精准参考库';

  @override
  String get refs_recentUsed => '最近用过';

  @override
  String get refs_inUse => '已在用';

  @override
  String refs_pickedN(Object count) {
    return '已选 $count';
  }

  @override
  String refs_pickerAfterVibe(Object count, Object max) {
    return ' · 加入后 $count/$max';
  }

  @override
  String refs_pickerAfterPrecise(Object count) {
    return ' · 加入后 $count 张';
  }

  @override
  String refs_pickerEncode(Object name, Object model, Object cost) {
    return '“$name”要为 $model 编码 · $cost Anlas';
  }

  @override
  String refs_pickerEncodeMore(Object count) {
    return '另有 $count 个也要编码';
  }

  @override
  String refs_pickerExtra(Object free, Object extra) {
    return '超过 $free 个多 $extra Anlas';
  }

  @override
  String refs_pickerPreciseCost(Object cost, Object total) {
    return '每张 $cost Anlas · 共 $total Anlas';
  }

  @override
  String get refs_replaceExisting => '替换现有';

  @override
  String refs_appendN(Object count) {
    return '追加 $count 个';
  }

  @override
  String get refs_timeNever => '没用过';

  @override
  String get refs_timeJustNow => '刚刚';

  @override
  String refs_timeMinutes(Object count) {
    return '$count 分钟前';
  }

  @override
  String refs_timeHours(Object count) {
    return '$count 小时前';
  }

  @override
  String get refs_timeYesterday => '昨天';

  @override
  String refs_timeDays(Object count) {
    return '$count 天前';
  }

  @override
  String refs_timeMonthDay(Object month, Object day) {
    return '$month 月 $day 日';
  }

  @override
  String get blocks_title => '块库';

  @override
  String get blocks_translationMark => '译';

  @override
  String get blocks_add => '添加';

  @override
  String get blocks_cancel => '取消';

  @override
  String get blocks_close => '关闭';

  @override
  String get blocks_delete => '删除';

  @override
  String get blocks_done => '完成';

  @override
  String get blocks_save => '保存';

  @override
  String get blocks_saveEnter => '保存 ⏎';

  @override
  String get blocks_more => '更多';

  @override
  String get blocks_back => '返回';

  @override
  String get blocks_rename => '重命名';

  @override
  String get blocks_edit => '编辑';

  @override
  String get blocks_copy => '复制';

  @override
  String get blocks_export => '导出';

  @override
  String get blocks_apply => '应用';

  @override
  String get blocks_off => '关';

  @override
  String get blocks_to => '到';

  @override
  String blocks_items(Object count) {
    return '$count 项';
  }

  @override
  String get blocks_itemUnit => '项';

  @override
  String blocks_usedTimes(Object count) {
    return '用过 $count 次';
  }

  @override
  String blocks_nBlocks(Object count) {
    return '$count 个';
  }

  @override
  String get blocks_untitled => '未命名';

  @override
  String get blocks_favorite => '收藏';

  @override
  String get blocks_unfavorite => '取消收藏';

  @override
  String get blocks_favorites => '收藏';

  @override
  String get blocks_recent => '最近使用';

  @override
  String get blocks_uncategorized => '未分类';

  @override
  String get blocks_positive => '正面';

  @override
  String get blocks_negative => '负面';

  @override
  String blocks_positiveN(Object count) {
    return '正面 $count';
  }

  @override
  String blocks_negativeN(Object count) {
    return '负面 $count';
  }

  @override
  String get blocks_content => '内容';

  @override
  String get blocks_name => '名称';

  @override
  String get blocks_folder => '文件夹';

  @override
  String get blocks_folders => '文件夹';

  @override
  String get blocks_tags => '标签';

  @override
  String get blocks_tag => '标签';

  @override
  String get blocks_icon => '图标';

  @override
  String get blocks_color => '颜色';

  @override
  String get blocks_look => '外观';

  @override
  String get blocks_appearance => '外观';

  @override
  String get blocks_thumb => '预览图';

  @override
  String get blocks_preview => '预览';

  @override
  String get blocks_params => '附带参数';

  @override
  String get blocks_classify => '归类';

  @override
  String get blocks_lookClassic => '经典';

  @override
  String get blocks_lookStripes => '细条纹';

  @override
  String get blocks_lookDots => '圆点';

  @override
  String get blocks_lookSolid => '实心';

  @override
  String get blocks_lookGradient => '渐变';

  @override
  String get blocks_lookTranslation => '翻译';

  @override
  String get blocks_hasParams => '附带参数';

  @override
  String get blocks_hasNegative => '含负面';

  @override
  String get blocks_hintClick => '点击插入';

  @override
  String get blocks_hintDrag => '拖到位置';

  @override
  String get blocks_hintRightClick => '右键更多';

  @override
  String get blocks_searchHint => '搜索块…';

  @override
  String get blocks_filterAll => '全部';

  @override
  String blocks_allN(Object count) {
    return '全部 $count';
  }

  @override
  String get blocks_searchResults => '搜索结果';

  @override
  String get blocks_noResults => '没有找到匹配的块';

  @override
  String get blocks_noFavorites => '还没有收藏的块。在块上右键 → 收藏。';

  @override
  String get blocks_dockEmpty => '块库还是空的。把常用的一串提示词存成块，点一下就能插进来。';

  @override
  String get blocks_dockHint => '点击插到光标处 · 拖进提示词放到指定位置';

  @override
  String get blocks_openLibrary => '在块库中打开';

  @override
  String get blocks_newBlock => '新建块';

  @override
  String get blocks_newBlockTip => '新建块（Ctrl+N）';

  @override
  String get blocks_insertAtCursor => '插到光标处';

  @override
  String get blocks_addToPalette => '放进积木';

  @override
  String get blocks_showInLibrary => '在块库中查看';

  @override
  String get blocks_missing => '块已删除';

  @override
  String get blocks_modeFixed => '固定';

  @override
  String get blocks_modeSequential => '顺序';

  @override
  String get blocks_modeRandom => '随机';

  @override
  String blocks_summaryRandom(Object range, Object pool) {
    return '随机抽取 · 每次 $range 项 · 池里 $pool 项';
  }

  @override
  String blocks_summarySequential(Object range) {
    return '顺序 · 每次 $range 项 · 生成一张往后走一步';
  }

  @override
  String get blocks_drawnThisTime => '本次抽到';

  @override
  String get blocks_lock => '锁定';

  @override
  String get blocks_unlock => '解锁';

  @override
  String get blocks_lockTip => '冻结这次的结果，生成时不再重抽';

  @override
  String get blocks_unlockTip => '解锁后生成时会重新抽取';

  @override
  String get blocks_reroll => '重抽';

  @override
  String get blocks_rerollLocked => '已锁定，先解锁才能重抽';

  @override
  String blocks_skipped(Object percent) {
    return '这次没出场（出现概率 $percent）';
  }

  @override
  String blocks_sendPrefix(Object text) {
    return '发送：$text';
  }

  @override
  String blocks_seqPosition(Object index, Object total) {
    return '第 $index / $total 项';
  }

  @override
  String get blocks_seqLocked => '已锁定，不会自动前进';

  @override
  String get blocks_prevItem => '上一项';

  @override
  String get blocks_nextItem => '下一项';

  @override
  String blocks_prevValue(Object value) {
    return '上一项 $value';
  }

  @override
  String blocks_nextValue(Object value) {
    return '下一项 $value';
  }

  @override
  String get blocks_paramsTitle => '这个块带了生图参数';

  @override
  String get blocks_drawMode => '抽取方式';

  @override
  String blocks_fixedExplain(Object count) {
    return '固定：每次都原样放入全部 $count 项。切到顺序或随机后，在这里设数量和权重。';
  }

  @override
  String get blocks_ruleCount => '数量';

  @override
  String get blocks_ruleWeight => '权重';

  @override
  String get blocks_ruleShow => '出现';

  @override
  String get blocks_ruleEach => '每次';

  @override
  String get blocks_ruleItemUnit => '项';

  @override
  String get blocks_ruleWrap => '走完从头开始';

  @override
  String get blocks_adjust => '调整';

  @override
  String get blocks_appliesTo => '作用于';

  @override
  String get blocks_disable => '停用';

  @override
  String get blocks_enable => '启用';

  @override
  String get blocks_editBlock => '改块';

  @override
  String get blocks_removeInstanceTip => '从提示词里移除';

  @override
  String get blocks_removeInstance => '从提示词里移除';

  @override
  String get blocks_copySend => '复制发送文本';

  @override
  String get blocks_evolutionOn => '设为遗传目标';

  @override
  String get blocks_evolutionOff => '取消遗传';

  @override
  String get blocks_evolutionModeHint => '启用的顺序或随机块可参与遗传，固定模式不可用。';

  @override
  String get blocks_rulesTitle => '抽取规则';

  @override
  String get blocks_rulesHint => '点完成后生效';

  @override
  String get blocks_rulesDirty => '有改动 · 点完成后生效';

  @override
  String get blocks_modeFixedDesc => '每次原样放入全部内容';

  @override
  String get blocks_modeSequentialDesc => '按顺序轮流，生成一张走一步';

  @override
  String get blocks_modeRandomDesc => '每次从池里随机抽几项';

  @override
  String get blocks_drawEach => '每次抽';

  @override
  String get blocks_takeEach => '每次取';

  @override
  String blocks_poolSize(Object count) {
    return '池里共 $count 项';
  }

  @override
  String get blocks_outputOrder => '输出顺序';

  @override
  String get blocks_orderDrawn => '按抽中顺序';

  @override
  String get blocks_orderOriginal => '按原顺序';

  @override
  String get blocks_seqExplain => '生成一张往后走一步；锁定后停在当前项。';

  @override
  String get blocks_randomWeight => '随机权重';

  @override
  String get blocks_randomWeightHint => '给每项套上 0.8::…:: 这样的权重';

  @override
  String get blocks_weightMin => '最小';

  @override
  String get blocks_weightAverage => '最常见';

  @override
  String get blocks_weightMax => '最大';

  @override
  String get blocks_distribution => '分布';

  @override
  String get blocks_distFocused => '集中';

  @override
  String get blocks_distBalanced => '均衡';

  @override
  String get blocks_distSpread => '发散';

  @override
  String get blocks_distCustom => '自定义';

  @override
  String get blocks_advanced => '高级';

  @override
  String get blocks_leftDispersion => '左侧离散';

  @override
  String get blocks_rightDispersion => '右侧离散';

  @override
  String get blocks_softBalance => '软平衡';

  @override
  String get blocks_softBalanceHint => '多项时把平均权重拉回最常见值';

  @override
  String get blocks_softBalanceStrength => '平衡强度';

  @override
  String get blocks_probability => '出现概率';

  @override
  String get blocks_probabilityHint => '低于 100% 时，有时整个块不出场';

  @override
  String get blocks_previewHint => '按当前规则抽 4 次';

  @override
  String get blocks_resample => '再抽';

  @override
  String get blocks_sampleSkipped => '（这次没出场）';

  @override
  String get blocks_resetDefault => '恢复默认';

  @override
  String get blocks_discard => '取消改动';

  @override
  String get blocks_allBlocks => '全部块';

  @override
  String get blocks_collections => '收藏集';

  @override
  String get blocks_newCollection => '新建收藏集';

  @override
  String get blocks_collectionName => '收藏集名称';

  @override
  String get blocks_noCollections => '把卡片拖到这里的收藏集，一个块可以进多个收藏集。';

  @override
  String get blocks_deleteCollection => '删除收藏集';

  @override
  String get blocks_newFolder => '新建文件夹';

  @override
  String get blocks_newSubfolder => '新建子文件夹';

  @override
  String get blocks_folderName => '文件夹名称';

  @override
  String get blocks_deleteFolder => '删除文件夹…';

  @override
  String get blocks_moveUp => '上移';

  @override
  String get blocks_moveDown => '下移';

  @override
  String get blocks_moveToTop => '移到顶层';

  @override
  String get blocks_tagName => '标签名';

  @override
  String get blocks_tagColor => '改颜色';

  @override
  String get blocks_deleteTag => '删除标签';

  @override
  String get blocks_collapseSidebar => '收起左栏';

  @override
  String get blocks_expandSidebar => '展开左栏';

  @override
  String get blocks_importExport => '导入 / 导出';

  @override
  String get blocks_importTxt => '导入 TXT…';

  @override
  String get blocks_importFolder => '导入文件夹…';

  @override
  String get blocks_importCuration => '整理导入…';

  @override
  String get blocks_exportBackup => '导出整库备份';

  @override
  String get blocks_importBackup => '导入整库备份…';

  @override
  String blocks_dropMoveTo(Object name) {
    return '移到「$name」';
  }

  @override
  String blocks_dropCopyTo(Object name) {
    return '复制到「$name」';
  }

  @override
  String blocks_dropAddTo(Object name) {
    return '加入「$name」';
  }

  @override
  String get blocks_searchLibrary => '搜索标题、内容或标签';

  @override
  String get blocks_sortCustom => '自定义顺序';

  @override
  String get blocks_sortUpdated => '最近修改';

  @override
  String get blocks_sortTitle => '名称';

  @override
  String get blocks_sortColor => '颜色';

  @override
  String get blocks_sortIcon => '图标';

  @override
  String get blocks_sortAsc => '升序';

  @override
  String get blocks_sortDesc => '降序';

  @override
  String get blocks_viewGrid => '网格';

  @override
  String get blocks_viewList => '列表';

  @override
  String get blocks_multiSelect => '多选';

  @override
  String get blocks_multiDone => '完成多选';

  @override
  String get blocks_hideInspector => '收起详情';

  @override
  String get blocks_showInspector => '展开详情';

  @override
  String get blocks_quickImage => '有预览图';

  @override
  String get blocks_quickNegative => '含负面';

  @override
  String get blocks_quickParams => '附带参数';

  @override
  String get blocks_cardSize => '卡片大小';

  @override
  String get blocks_noMatch => '没有符合条件的块';

  @override
  String get blocks_noMatchBody => '换个关键词，或者清除快速筛选。';

  @override
  String get blocks_clearFilters => '清除筛选';

  @override
  String get blocks_insert => '插入';

  @override
  String get blocks_insertToPrompt => '插入到提示词';

  @override
  String get blocks_miniNegative => '负面';

  @override
  String get blocks_miniParams => '参数';

  @override
  String get blocks_colName => '名称';

  @override
  String get blocks_colItems => '项数';

  @override
  String get blocks_colFolder => '文件夹';

  @override
  String get blocks_colUsed => '使用';

  @override
  String get blocks_colModified => '修改';

  @override
  String blocks_selectedN(Object count) {
    return '已选 $count 个';
  }

  @override
  String blocks_selectedBlocksN(Object count) {
    return '已选 $count 个块';
  }

  @override
  String get blocks_moveTo => '移到…';

  @override
  String get blocks_noTags => '还没有标签';

  @override
  String get blocks_emptyTitle => '块库还是空的';

  @override
  String get blocks_emptyBody =>
      '把常用的一串提示词存成块：画师池、角色、服装、质量词……插进提示词后可以固定、按顺序轮流或随机抽取。';

  @override
  String get blocks_duplicate => '复制一份';

  @override
  String get blocks_copyContent => '复制内容';

  @override
  String get blocks_applyParams => '应用附带参数';

  @override
  String get blocks_exportTxt => '导出为 TXT';

  @override
  String get blocks_removeFromCollection => '移出收藏集';

  @override
  String blocks_deleteOne(Object name) {
    return '删除「$name」？';
  }

  @override
  String blocks_deleteMany(Object count) {
    return '删除 $count 个块？';
  }

  @override
  String get blocks_deleteBody => '提示词里已经插入的实例会显示为“块已删除”，可以撤销。';

  @override
  String get blocks_details => '详情';

  @override
  String get blocks_noSelection => '点一张卡片查看详情。双击直接编辑，Enter 插入到提示词。';

  @override
  String get blocks_changeThumb => '更换 / 调整';

  @override
  String get blocks_reading => '翻译阅读';

  @override
  String get blocks_needsReview => '需复核';

  @override
  String get blocks_applyToCurrent => '应用到当前';

  @override
  String get blocks_noParams => '没有。插入时不会改动当前参数。';

  @override
  String get blocks_paramModel => '模型';

  @override
  String get blocks_paramSteps => '步数';

  @override
  String get blocks_paramGuidance => '引导';

  @override
  String get blocks_paramRescale => '重缩放';

  @override
  String get blocks_paramSampler => '采样器';

  @override
  String get blocks_paramNoise => '噪声';

  @override
  String blocks_steps(Object count) {
    return '$count 步';
  }

  @override
  String blocks_guidance(Object value) {
    return '引导 $value';
  }

  @override
  String blocks_rescale(Object value) {
    return '重缩放 $value';
  }

  @override
  String get blocks_newTagInEdit => '新标签…';

  @override
  String blocks_modifiedAt(Object time) {
    return '修改于 $time';
  }

  @override
  String blocks_createdAt(Object date) {
    return '创建于 $date';
  }

  @override
  String blocks_sourceFile(Object path) {
    return '来源文件 $path';
  }

  @override
  String get blocks_sourceSynced => '与文件一致';

  @override
  String get blocks_sourceChanged => '文件已改动';

  @override
  String get blocks_sourceMissing => '文件已不在';

  @override
  String blocks_importedAt(Object date) {
    return '导入于 $date';
  }

  @override
  String get blocks_total => '合计';

  @override
  String blocks_totalItems(Object count) {
    return '$count 项内容';
  }

  @override
  String get blocks_from => '来自';

  @override
  String get blocks_batch => '批量操作';

  @override
  String get blocks_insertInOrder => '依次插入到提示词';

  @override
  String get blocks_mergeNew => '合并成一个新块…';

  @override
  String get blocks_batchStyle => '统一改颜色 / 外观';

  @override
  String blocks_dragHint(Object count) {
    return '也可以直接把这 $count 张卡拖到左边的文件夹或收藏集，松开时选择移动还是复制。';
  }

  @override
  String get blocks_editBlockTitle => '编辑块';

  @override
  String get blocks_editHint => '保存后，提示词里固定模式的实例立即更新；随机 / 顺序在下次抽取时用新内容';

  @override
  String get blocks_newBlockHint => '块存进块库后，可以从生图页侧栏点一下插入';

  @override
  String get blocks_addThumb => '添加预览图';

  @override
  String get blocks_changeImage => '换图';

  @override
  String get blocks_clearThumb => '清除预览图';

  @override
  String get blocks_cropHint => '拖动 / 滚轮缩放';

  @override
  String get blocks_namePlaceholder => '不填就用第一项';

  @override
  String get blocks_plainText => '纯文本';

  @override
  String get blocks_plainTextHint => '原样保存这段文字，不拆成项';

  @override
  String get blocks_atomHint => '输入后按 Enter 或逗号成为一项；粘贴一段会自动拆分';

  @override
  String get blocks_existingTags => '已有标签';

  @override
  String get blocks_newTag => '新标签';

  @override
  String get blocks_paramsNotAuto => '插入时不自动应用';

  @override
  String get blocks_noParamsShort => '没有';

  @override
  String get blocks_editParams => '编辑参数';

  @override
  String get blocks_captureParams => '从当前读取';

  @override
  String get blocks_keepCurrent => '不改当前值';

  @override
  String get blocks_clearParams => '清除参数';

  @override
  String get blocks_deleteBlock => '删除块';

  @override
  String get blocks_deleteConfirmInline => '确定删除这个块？';

  @override
  String get blocks_saveShortcut => 'Ctrl+Enter 保存';

  @override
  String get blocks_saveAsBlock => '存为块';

  @override
  String get blocks_lookup => '查词条';

  @override
  String blocks_splitDone(Object count) {
    return '$count 项 · 已按逗号拆好';
  }

  @override
  String get blocks_replaceSelection => '保存后把选中的文字换成这个块';

  @override
  String get blocks_quickHint => '更多设置（预览图、负面、参数）稍后在块库里改';

  @override
  String get imageViewer_backGallery => '本地画廊';

  @override
  String get imageViewer_backGeneration => '生图';

  @override
  String get imageViewer_scopeAll => '全部图片';

  @override
  String get imageViewer_sortModified => '按修改时间';

  @override
  String get imageViewer_sortCreated => '按创建时间';

  @override
  String get imageViewer_sortFileName => '按文件名';

  @override
  String get imageViewer_sortFileSize => '按文件大小';

  @override
  String get imageViewer_sortDimensions => '按尺寸';

  @override
  String get imageViewer_unsaved => '未保存';

  @override
  String get imageViewer_saved => '已保存';

  @override
  String imageViewer_batch(Object count) {
    return '生成结果 · 本批 $count 张';
  }

  @override
  String imageViewer_zoomFit(Object percent) {
    return '适应 · $percent%';
  }

  @override
  String get imageViewer_zoomFitPending => '适应 · —';

  @override
  String get imageViewer_zoomFitShort => '适应';

  @override
  String get imageViewer_zoomIn => '放大';

  @override
  String get imageViewer_zoomOut => '缩小';

  @override
  String get imageViewer_actualSize => '原始大小';

  @override
  String get imageViewer_fullscreen => '全屏';

  @override
  String get imageViewer_exitFullscreen => '退出全屏';

  @override
  String get imageViewer_fullscreenHint => '鼠标移到底部显示胶片条，静止 2 秒后控件自动隐藏';

  @override
  String get imageViewer_infoPanel => '信息栏';

  @override
  String get imageViewer_infoShort => '信息';

  @override
  String get imageViewer_hideInfo => '收起信息栏';

  @override
  String get imageViewer_previous => '上一张';

  @override
  String get imageViewer_next => '下一张';

  @override
  String get imageViewer_loadingOriginal => '读取原图';

  @override
  String imageViewer_loadingOriginalSize(Object size) {
    return '读取原图 · $size';
  }

  @override
  String get imageViewer_missingTitle => '找不到这张图';

  @override
  String get imageViewer_missingHint => '可能已经在资源管理器里被移动、改名或删除';

  @override
  String get imageViewer_openFolder => '打开所在文件夹';

  @override
  String get imageViewer_nextImage => '下一张';

  @override
  String get imageViewer_hintPan => '拖动平移';

  @override
  String get imageViewer_hintWheel => '滚轮缩放';

  @override
  String get imageViewer_hintDouble => '双击 /';

  @override
  String get imageViewer_hintFit => '回到适应';

  @override
  String get imageViewer_hintActual => '原始大小';

  @override
  String get imageViewer_dragFrame => '拖框移动';

  @override
  String get imageViewer_movedToTrash => '已移到回收站';

  @override
  String get imageViewer_undo => '撤销';

  @override
  String get imageViewer_details => '详情';

  @override
  String get imageViewer_generationResult => '生成结果';

  @override
  String get imageViewer_favorite => '收藏';

  @override
  String get imageViewer_showInFolder => '在文件夹中显示';

  @override
  String imageViewer_deleteKey(Object key) {
    return '删除  $key';
  }

  @override
  String get imageViewer_more => '更多';

  @override
  String imageViewer_genIndex(Object index) {
    return '本次生成 · 第 $index 张';
  }

  @override
  String get imageViewer_notSaved => '还没保存到图库';

  @override
  String get imageViewer_savedToGallery => '已保存到图库';

  @override
  String get imageViewer_size => '尺寸';

  @override
  String get imageViewer_fileSize => '大小';

  @override
  String get imageViewer_modified => '修改时间';

  @override
  String get imageViewer_model => '模型';

  @override
  String get imageViewer_params => '生成参数';

  @override
  String get imageViewer_loadingMeta => '正在读取元数据…';

  @override
  String get imageViewer_seed => '种子';

  @override
  String get imageViewer_sampler => '采样器';

  @override
  String get imageViewer_steps => '步数';

  @override
  String get imageViewer_guidance => '提示词引导';

  @override
  String imageViewer_noise(Object value) {
    return '噪声 $value';
  }

  @override
  String imageViewer_rescale(Object value) {
    return '重缩放 $value';
  }

  @override
  String imageViewer_precise(Object count) {
    return '精准参考 ×$count';
  }

  @override
  String get imageViewer_qualityTags => '质量词';

  @override
  String get imageViewer_prompt => '提示词';

  @override
  String get imageViewer_translate => '翻译';

  @override
  String get imageViewer_showOriginal => '显示原文';

  @override
  String imageViewer_translateFailed(Object error) {
    return '翻译失败：$error';
  }

  @override
  String get imageViewer_copy => '复制';

  @override
  String get imageViewer_copySeed => '复制种子';

  @override
  String get imageViewer_expandAll => '展开全部';

  @override
  String get imageViewer_expand => '展开';

  @override
  String get imageViewer_collapse => '收起';

  @override
  String imageViewer_character(Object index) {
    return '角色 $index';
  }

  @override
  String imageViewer_position(Object cell) {
    return '位置 $cell';
  }

  @override
  String get imageViewer_characterNegative => '角色负面 · ';

  @override
  String get imageViewer_negative => '负面';

  @override
  String imageViewer_tagCount(Object count) {
    return '$count 项';
  }

  @override
  String get imageViewer_vibes => 'Vibe 参考';

  @override
  String imageViewer_vibeStrength(Object value) {
    return '强度 $value';
  }

  @override
  String imageViewer_vibeInfo(Object value) {
    return '信息 $value';
  }

  @override
  String get imageViewer_saveVibe => '存入 Vibe 库';

  @override
  String get imageViewer_noMetaTitle => '没有 NovelAI 生成信息';

  @override
  String get imageViewer_noMetaBody =>
      '这张图不是 NAI 生成的，或者元数据已经被去掉了（截图、转存、压缩过的图常见）。\n下面的图生图、风格迁移、精准参考、放大照样能用。';

  @override
  String get imageViewer_reuse => '复用参数';

  @override
  String get imageViewer_reuseNoMeta => '这张图没有生成信息';

  @override
  String get imageViewer_img2img => '图生图';

  @override
  String get imageViewer_styleTransfer => '风格迁移';

  @override
  String get imageViewer_preciseRef => '精准参考';

  @override
  String get imageViewer_saveRef => '存入参考库';

  @override
  String get imageViewer_krita => '发送到 Krita';

  @override
  String get imageViewer_kritaOff => 'Krita 没连接';

  @override
  String get imageViewer_upscale => '放大';

  @override
  String get imageViewer_copyImage => '复制图片';

  @override
  String get imageViewer_saveBlock => '存为块';

  @override
  String get imageViewer_save => '保存到图库';

  @override
  String get imageViewer_copyPath => '复制文件路径';

  @override
  String get imageViewer_copyAllPrompts => '复制全部提示词（含角色）';

  @override
  String get imageViewer_saveBlockEllipsis => '存为块…';

  @override
  String get imageViewer_addToCollection => '加入收藏集';

  @override
  String get imageViewer_moveTo => '移动到…';

  @override
  String get imageViewer_copyTo => '复制到…';

  @override
  String get imageViewer_moveToTrash => '移到回收站';

  @override
  String get imageViewer_collections => '收藏集';

  @override
  String get imageViewer_newCollection => '新建收藏集…';

  @override
  String get imageViewer_helpTitle => '大图快捷键';

  @override
  String get imageViewer_helpHint => '可以在设置 → 快捷键里改';

  @override
  String get imageViewer_helpClose => '再按一次关闭';

  @override
  String get imageViewer_helpBrowse => '浏览';

  @override
  String get imageViewer_helpZoom => '缩放';

  @override
  String get imageViewer_helpActions => '操作';

  @override
  String get imageViewer_helpPrevNext => '上一张 / 下一张';

  @override
  String get imageViewer_helpFirstLast => '第一张 / 最后一张';

  @override
  String get imageViewer_helpInfo => '显示 / 收起信息栏';

  @override
  String get imageViewer_helpClose2 => '关闭';

  @override
  String get imageViewer_helpZoomInOut => '放大 / 缩小';

  @override
  String get imageViewer_helpActual => '原始大小 100%';

  @override
  String get imageViewer_helpWheel => '以鼠标处为中心缩放';

  @override
  String get imageViewer_helpDouble => '适应 ↔ 放大';

  @override
  String get imageViewer_keyWheel => '滚轮';

  @override
  String get imageViewer_keyDouble => '双击';

  @override
  String get imageViewer_helpCopyPrompt => '复制提示词';

  @override
  String get imageViewer_helpUndo => '撤销删除';

  @override
  String get imageViewer_protectedTitle => '这张图受保护，移到回收站？';

  @override
  String get imageViewer_protectedBody => '移到回收站后可以在回收站里还原。';

  @override
  String get imageViewer_cancel => '取消';

  @override
  String get imageViewer_justNow => '刚刚';

  @override
  String imageViewer_minutesAgo(Object count) {
    return '$count 分钟前';
  }

  @override
  String imageViewer_hoursAgo(Object count) {
    return '$count 小时前';
  }

  @override
  String get imageViewer_yesterday => '昨天';

  @override
  String get explore_back => '画风探索';

  @override
  String get explore_close => '关闭';

  @override
  String get explore_cancel => '取消';

  @override
  String get explore_done => '完成';

  @override
  String get explore_more => '更多';

  @override
  String get explore_rename => '改名';

  @override
  String get explore_remove => '去掉';

  @override
  String get explore_copy => '复制';

  @override
  String get explore_undo => '撤销';

  @override
  String get explore_expand => '展开';

  @override
  String get explore_expandAll => '展开全部';

  @override
  String get explore_collapse => '收起';

  @override
  String get explore_previous => '上一张';

  @override
  String get explore_next => '下一张';

  @override
  String explore_today(Object time) {
    return '今天 $time';
  }

  @override
  String explore_yesterday(Object time) {
    return '昨天 $time';
  }

  @override
  String explore_monthDay(Object month, Object day, Object time) {
    return '$month月$day日 $time';
  }

  @override
  String explore_fullDate(Object year, Object month, Object day) {
    return '$year年$month月$day日';
  }

  @override
  String get explore_sectionToday => '今天';

  @override
  String get explore_thisWeek => '本周';

  @override
  String get explore_earlier => '更早';

  @override
  String get explore_variables => '随机变量';

  @override
  String get explore_variablesHint => '每张重新抽取';

  @override
  String get explore_variablesInfo =>
      '提示词中启用的顺序或随机块，按各自的抽取规则取值。标“遗传目标”的块会合并抽取结果，组成父本串参与遗传。';

  @override
  String get explore_variablesEmpty => '提示词里还没有随机块。插入块库里的随机块（比如画师池），每张图都会重新抽。';

  @override
  String get explore_openBlockLibrary => '打开块库';

  @override
  String get explore_variableMissing => '块已删除';

  @override
  String explore_poolSize(Object count) {
    return '池 $count 项';
  }

  @override
  String get explore_evolutionTarget => '遗传目标';

  @override
  String explore_draw(Object count) {
    return '抽 $count 张候选';
  }

  @override
  String get explore_stopGenerating => '停止生成';

  @override
  String get explore_busy => '生成中';

  @override
  String explore_cooldown(Object seconds) {
    return '冷却 $seconds 秒';
  }

  @override
  String get explore_insufficient => 'Anlas 不够';

  @override
  String explore_count(Object count) {
    return '$count 张';
  }

  @override
  String explore_favoritesCount(Object count) {
    return '收藏 $count';
  }

  @override
  String explore_roundsCount(Object count) {
    return '$count 轮';
  }

  @override
  String explore_linesCount(Object count) {
    return '$count 条进化线';
  }

  @override
  String explore_progressRound(Object round, Object done, Object total) {
    return '第 $round 轮 · $done / $total';
  }

  @override
  String explore_progressChildren(
    Object line,
    Object gen,
    Object done,
    Object total,
  ) {
    return '$line 第 $gen 代 · $done / $total';
  }

  @override
  String explore_paused(Object where) {
    return '已暂停 · $where';
  }

  @override
  String get explore_pause => '暂停';

  @override
  String get explore_resume => '继续';

  @override
  String get explore_stop => '停止';

  @override
  String get explore_sizeSmall => '小卡片';

  @override
  String get explore_sizeLarge => '大卡片';

  @override
  String get explore_inspector => '检查器';

  @override
  String get explore_hideInspector => '收起';

  @override
  String get explore_tabCandidates => '候选';

  @override
  String get explore_tabEvolution => '进化';

  @override
  String get explore_filterAll => '全部';

  @override
  String get explore_filterFavorites => '收藏';

  @override
  String get explore_filterUngrouped => '未分组';

  @override
  String get explore_addGroup => '分组';

  @override
  String get explore_groupName => '分组名称';

  @override
  String get explore_deleteGroup => '删除分组（成员回到未分组）';

  @override
  String get explore_newLine => '新进化线';

  @override
  String get explore_deleteLine => '删除进化线';

  @override
  String get explore_compareShort => '两两比较';

  @override
  String get explore_evoHelp => '怎么用';

  @override
  String get explore_evoHelpBody =>
      '1. 在候选里挑几张喜欢的，开始进化，它们的画师串就是第 1 代父本。\n2. 子代由父本交叉、变异、注入新画师得到。\n3. 勾选喜欢的子代培育下一代；两两比较能调整父本的偏好。';

  @override
  String get explore_select => '多选';

  @override
  String get explore_selectAll => '全选';

  @override
  String get explore_selectDone => '完成';

  @override
  String get explore_selectExit => '退出多选  Esc';

  @override
  String get explore_selectHint => '点卡片勾选';

  @override
  String explore_selectedN(Object count) {
    return '已选 $count 张';
  }

  @override
  String get explore_sortNewest => '新的轮在上（点一下改为旧的在上）';

  @override
  String get explore_sortOldest => '旧的轮在上（点一下改为新的在上）';

  @override
  String explore_round(Object number) {
    return '第 $number 轮';
  }

  @override
  String explore_generatingShort(Object done, Object total) {
    return '生成中 $done / $total';
  }

  @override
  String explore_failedRetry(Object count) {
    return '$count 张失败 · 重试';
  }

  @override
  String get explore_pick => '挑几张去进化';

  @override
  String get explore_pickTip => '进入多选，本轮收藏的已经勾上';

  @override
  String get explore_filterEmpty => '这个筛选下还没有候选';

  @override
  String get explore_showAll => '显示全部';

  @override
  String explore_queued(Object number) {
    return '排队 #$number';
  }

  @override
  String explore_generatingN(Object number) {
    return '生成中 #$number';
  }

  @override
  String get explore_failed => '生成失败';

  @override
  String get explore_failedHover => '悬停查看原因';

  @override
  String get explore_noArtists => '没有抽到画师';

  @override
  String get explore_parentTip => '已经是进化线的父本';

  @override
  String get explore_favorite => '收藏';

  @override
  String get explore_favorited => '已收藏';

  @override
  String get explore_unfavorite => '取消收藏';

  @override
  String get explore_addToEvolution => '加入进化';

  @override
  String get explore_startEvolution => '开始进化';

  @override
  String get explore_saveBlock => '存为块';

  @override
  String get explore_applyToEditor => '套用到编辑区';

  @override
  String get explore_copyArtists => '复制画师串';

  @override
  String get explore_openLarge => '看大图';

  @override
  String get explore_group => '分组';

  @override
  String get explore_groups => '分组';

  @override
  String get explore_groupsHint => '按 1–9 快速归组';

  @override
  String get explore_newGroup => '新分组';

  @override
  String get explore_ungroup => '移出分组';

  @override
  String get explore_delete => '删除';

  @override
  String explore_deleteN(Object count) {
    return '删除 $count 张';
  }

  @override
  String get explore_deleteThis => '删除这张';

  @override
  String explore_deleted(Object count) {
    return '已删除 $count 张';
  }

  @override
  String get explore_inspectorEmpty => '点一张候选，这里会写出它抽到了哪些画师';

  @override
  String explore_childN(Object number) {
    return '子代 #$number';
  }

  @override
  String explore_genOp(Object gen, Object op) {
    return '第 $gen 代 · $op';
  }

  @override
  String get explore_drawn => '本张抽到';

  @override
  String get explore_drawEmpty => '这次没有抽中（池里有空项）';

  @override
  String get explore_origin => '怎么来的';

  @override
  String get explore_seed => '种子';

  @override
  String get explore_elapsed => '耗时';

  @override
  String get explore_params => '参数';

  @override
  String get explore_sampler => '采样器';

  @override
  String get explore_model => '模型';

  @override
  String explore_steps(Object count) {
    return '$count 步';
  }

  @override
  String get explore_fullPrompt => '完整提示词';

  @override
  String get explore_negative => '负面';

  @override
  String get explore_failReason => '失败原因';

  @override
  String get explore_retryFailed => '重试失败的候选';

  @override
  String get explore_waitHint => '生成好以后这里会显示它抽到的画师';

  @override
  String explore_mergedArtists(Object count) {
    return '合在一起的画师 · $count';
  }

  @override
  String get explore_multiHint => '存为块会把这些画师合成一个块；开始进化时每张都是一个父本。';

  @override
  String get explore_evoEmptyTitle => '还没有进化线';

  @override
  String get explore_evoEmptyBody => '在候选里挑几张喜欢的，点“开始进化”，让好的画师组合继续杂交出新组合。';

  @override
  String get explore_evoGoPick => '去候选里挑';

  @override
  String explore_gen(Object number) {
    return '第 $number 代';
  }

  @override
  String get explore_current => '当前';

  @override
  String explore_genFirst(Object picked, Object children) {
    return '从候选里选了 $picked 张作为起点 · $children 张子代';
  }

  @override
  String explore_genFrom(
    Object parents,
    Object children,
    Object from,
    Object picked,
  ) {
    return '$parents 个父本 → $children 张子代 · 由第 $from 代挑 $picked 张';
  }

  @override
  String get explore_backcross => '第 1 代回交';

  @override
  String get explore_compare => '两两比较排序';

  @override
  String get explore_compareTip => '一次看两张父本，选更好的那张，偏好越高越常被选中';

  @override
  String explore_generateChildren(Object count) {
    return '再生成 $count 张子代';
  }

  @override
  String explore_children(Object count) {
    return '子代 · $count';
  }

  @override
  String explore_pickedN(Object count) {
    return '已选 $count';
  }

  @override
  String get explore_breedHint => '勾选喜欢的子代，培育下一代';

  @override
  String explore_breed(Object count, Object next) {
    return '用选中的 $count 张培育第 $next 代';
  }

  @override
  String get explore_noChildren => '还没有子代 · 点“再生成”出第一批';

  @override
  String explore_parentsByPref(Object count) {
    return '父本 · 按偏好排序 · $count';
  }

  @override
  String get explore_opMutation => '变异';

  @override
  String get explore_opCrossover => '交叉';

  @override
  String get explore_opInjection => '注入';

  @override
  String get explore_searchRuns => '搜索探索';

  @override
  String get explore_newRun => '新建探索';

  @override
  String get explore_newRunHint => '用当前提示词和参数开一个新的，名字可以之后改';

  @override
  String explore_runRunning(Object done, Object total) {
    return '生成中 $done/$total';
  }

  @override
  String explore_runPaused(Object done, Object total) {
    return '已暂停 $done/$total';
  }

  @override
  String explore_runFailed(Object count) {
    return '$count 张失败';
  }

  @override
  String get explore_noRunMatch => '没有匹配的探索';

  @override
  String get explore_runMenuHint => '自动命名：随机块名 + 日期 · 悬停一行点“⋯”改名或删除';

  @override
  String get explore_deleteRun => '删除探索';

  @override
  String explore_deleteRunTitle(Object name) {
    return '删除“$name”？';
  }

  @override
  String explore_deleteRunBody(Object count) {
    return '$count 张候选和所有进化线会一起删掉，不能撤销。图库里的图不受影响。';
  }

  @override
  String explore_deleteLineTitle(Object name) {
    return '删除进化线“$name”？';
  }

  @override
  String explore_deleteLineBody(Object count) {
    return '它生成的 $count 张子代会一起删掉，不能撤销。候选不受影响。';
  }

  @override
  String get explore_onboardingTitle => '用随机块批量试画风';

  @override
  String get explore_onboardingBody => '每张图从画师池里重新抽，挑出喜欢的组合，再让它们进化。';

  @override
  String get explore_step1 => '放一个随机块';

  @override
  String get explore_step1Body => '在提示词里插入块库里的随机块，比如画师池。';

  @override
  String get explore_step2 => '抽一批候选';

  @override
  String explore_step2Body(Object count) {
    return '点左下角“抽 $count 张候选”，每张都会重新抽画师。';
  }

  @override
  String get explore_step3 => '收藏、进化、存为块';

  @override
  String get explore_step3Body => '喜欢的收藏起来，拿去进化，满意的组合存成块。';

  @override
  String explore_detected(Object count) {
    return '已检测到 $count 个';
  }

  @override
  String get explore_noVariables => '还没有随机块';

  @override
  String get explore_openPrevious => '打开以前的探索';

  @override
  String explore_evoTitle(Object count) {
    return '用 $count 张候选开始进化';
  }

  @override
  String explore_evoJoinTitle(Object count, Object line, Object gen) {
    return '把 $count 张加入“$line”第 $gen 代';
  }

  @override
  String get explore_evoStep1 => '父本';

  @override
  String get explore_evoStep1Body => '每张候选的画师串是一个父本';

  @override
  String get explore_evoStep2 => '子代';

  @override
  String get explore_evoStep2Body => '交叉、变异、注入新画师';

  @override
  String get explore_evoStep3 => '挑选';

  @override
  String get explore_evoStep3Body => '勾选喜欢的，培育下一代';

  @override
  String get explore_evoNewLine => '新建进化线';

  @override
  String explore_evoJoin(Object line, Object gen) {
    return '加入“$line”第 $gen 代';
  }

  @override
  String get explore_lineName => '进化线名称';

  @override
  String explore_lineDefault(Object number) {
    return '进化线 $number';
  }

  @override
  String explore_lineGen(Object line, Object gen) {
    return '$line · 第 $gen 代';
  }

  @override
  String explore_evoParents(Object count) {
    return '第 1 代父本 · $count';
  }

  @override
  String explore_evoAddParents(Object count) {
    return '加入的父本 · $count';
  }

  @override
  String get explore_addCustom => '再加一段自定义画师串';

  @override
  String get explore_customHint =>
      '比如 0.8::artist:ciloranko::, artist:rella（回车添加）';

  @override
  String get explore_targetBefore => '遗传目标：';

  @override
  String get explore_targetAfter => '合并抽取结果，组成父本串';

  @override
  String get explore_noTarget => '还没有遗传目标。请在顺序或随机块上开启遗传。';

  @override
  String get explore_firstBatch => '第一批子代';

  @override
  String get explore_atLeast4 => '张（至少 4）';

  @override
  String get explore_createOnly => '只创建';

  @override
  String get explore_joinOnly => '只加入';

  @override
  String explore_createGenerate(Object count) {
    return '创建并生成 $count 张';
  }

  @override
  String get explore_saveBlockTitle => '存为提示词块';

  @override
  String get explore_untitled => '未命名';

  @override
  String explore_blockFromOne(Object number) {
    return '来自候选 #$number';
  }

  @override
  String explore_blockFromMany(Object count) {
    return '来自 $count 张候选，已合并去重';
  }

  @override
  String explore_blockNameMany(Object run, Object count) {
    return '$run · 精选 $count';
  }

  @override
  String get explore_blockContent => '内容';

  @override
  String get explore_blockArtists => '只要抽到的画师';

  @override
  String get explore_blockFull => '完整正向提示词';

  @override
  String get explore_blockFullSingle => '只有一张候选时可以存完整提示词';

  @override
  String get explore_blockRemoveHint => '点 × 去掉不要的画师';

  @override
  String explore_blockKept(Object kept, Object total) {
    return '保留 $kept / $total';
  }

  @override
  String get explore_blockName => '名称';

  @override
  String get explore_blockColor => '颜色';

  @override
  String get explore_blockFolder => '放到块库';

  @override
  String get explore_blockRoot => '块库（根目录）';

  @override
  String get explore_blockFooter => '存好后可以在块库里拖进提示词';

  @override
  String get explore_compareTitle => '两两比较 · 给父本排个序';

  @override
  String get explore_compareNote => '结果随时保存，可以中途关掉';

  @override
  String get explore_compareQuestion => '哪张更接近你想要的画风？';

  @override
  String explore_comparePairs(Object index, Object total) {
    return '$index / $total 对';
  }

  @override
  String get explore_leftBetter => '左边更好';

  @override
  String get explore_rightBetter => '右边更好';

  @override
  String get explore_neither => '两张都不行';

  @override
  String get explore_skip => '跳过';

  @override
  String get explore_keySpace => '空格';

  @override
  String get explore_ranking => '当前排名 · 实时';

  @override
  String get explore_rankingNote => '偏好越高，培育下一代时越常被选为父本。';

  @override
  String get explore_compareDone => '排好了';

  @override
  String get explore_compareDoneBody => '新的偏好已经保存，下次生成子代就会用上。';

  @override
  String get gen_cancel => '取消';

  @override
  String get gen_close => '关闭';

  @override
  String get gen_done => '完成';

  @override
  String get gen_more => '更多';

  @override
  String get gen_delete => '删除';

  @override
  String get gen_remove => '移除';

  @override
  String get gen_rename => '改名';

  @override
  String get gen_add => '添加';

  @override
  String get gen_clear => '清空';

  @override
  String get gen_clearAll => '全部清空';

  @override
  String get gen_clearConfirm => '清空';

  @override
  String get gen_removeConfirm => '移除';

  @override
  String get gen_expand => '展开';

  @override
  String get gen_collapse => '收起';

  @override
  String get gen_copied => '已复制';

  @override
  String get gen_random => '随机';

  @override
  String get gen_auto => '自动';

  @override
  String get gen_pin => '钉在头部';

  @override
  String get gen_unpin => '从头部取下';

  @override
  String get gen_yesterday => '昨天';

  @override
  String gen_monthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get gen_params => '生成参数';

  @override
  String get gen_generating => '生成中';

  @override
  String get gen_modelsNew => '新模型';

  @override
  String get gen_modelsLegacy => '旧模型';

  @override
  String get gen_turboEnable =>
      '开启 Turbo（Medium Effort）\n固定 14 步与 Euler Ancestral；自定义负面草稿保留，切回 Full 后恢复。';

  @override
  String get gen_turboDisable =>
      '正在使用 Turbo（Medium Effort）\n点击切回 V5 Full，恢复原来的参数与负面草稿。';

  @override
  String get gen_turboUnavailable => 'Turbo 仅适用于 V5 Full';

  @override
  String get gen_turboFixed => 'Turbo 固定 14 步、Euler Ancestral，不支持 CFG Rescale。';

  @override
  String get gen_turboNegative => 'Turbo 不使用自定义负面。原草稿已保留，切回 Full 可恢复。';

  @override
  String get generation_modelDesc_v5Turbo =>
      'V5 Full 的 Medium Effort 模式，固定 14 步、Euler Ancestral，降低 Anlas 与 Opus 额度消耗。';

  @override
  String get gen_modeTip => '点一下切换 Anime / Furry';

  @override
  String gen_anlasTip(Object value) {
    return 'Anlas 余额 $value';
  }

  @override
  String get gen_positive => '正面';

  @override
  String get gen_basePrompt => '基础提示词';

  @override
  String get gen_negative => '负面';

  @override
  String get gen_finalPositive => '最终发送的正面';

  @override
  String get gen_finalNegative => '最终发送的负面';

  @override
  String get gen_toolDock => '块库侧栏';

  @override
  String get gen_toolPalette => '积木板';

  @override
  String get gen_toolTranslate => '翻译';

  @override
  String get gen_toolsMenu => '模块与开关';

  @override
  String get gen_toolsPinned => '钉在头部的工具';

  @override
  String get gen_toolsSettings => '提示词设置';

  @override
  String get gen_fullscreen => '全屏编辑';

  @override
  String get gen_autoFormat => '自动格式化';

  @override
  String get gen_autoFormatSub => '失焦时整理逗号和空格';

  @override
  String get gen_highlight => '强调高亮';

  @override
  String get gen_highlightSub => '按权重给片段上色';

  @override
  String get gen_sdConvert => 'SD 语法自动转换';

  @override
  String get gen_sdConvertSub => '粘贴 (tag:1.2) 时转成 NAI 权重';

  @override
  String get gen_related => '共现推荐';

  @override
  String get gen_relatedSub => '补全时推荐常一起出现的标签';

  @override
  String get gen_translating => '正在翻译…';

  @override
  String get gen_translateNeedsModel => '还没配翻译模型，点一下去设置';

  @override
  String gen_translateWith(Object route) {
    return '翻译（$route）';
  }

  @override
  String get gen_translateNew => '翻译新增内容';

  @override
  String get gen_translateShowOriginal => '全部显示原文';

  @override
  String get gen_translateShowTranslated => '全部显示译文';

  @override
  String get gen_translateSettings => '翻译模型设置';

  @override
  String get gen_qualityPreset => '质量词预设';

  @override
  String get gen_ucPreset => '负面预设';

  @override
  String get gen_presetNone => '无';

  @override
  String get gen_transparentOn => '透明背景：开';

  @override
  String get gen_transparentOff => '透明背景：关';

  @override
  String get gen_characters => '角色提示词';

  @override
  String get gen_charactersTip => '给画面里每个角色单独写提示词，不会互相串。';

  @override
  String get gen_charactersEmpty => '还没有角色。点右上角 + 添加，每个角色单独写提示词。';

  @override
  String gen_charactersFull(Object max) {
    return '最多 $max 个角色';
  }

  @override
  String get gen_addCharacter => '添加角色';

  @override
  String gen_addAs(Object gender) {
    return '添加$gender';
  }

  @override
  String get gen_clearCharacters => '清空全部';

  @override
  String get gen_clearCharactersTitle => '清空全部角色？';

  @override
  String gen_clearCharactersBody(Object count) {
    return '$count 个角色和它们的提示词都会删掉。';
  }

  @override
  String gen_characterN(Object n) {
    return '角色 $n';
  }

  @override
  String get gen_genderFemale => '女性';

  @override
  String get gen_genderMale => '男性';

  @override
  String get gen_genderOther => '其他';

  @override
  String get gen_position => '定位';

  @override
  String get gen_positionAi => 'AI 选择';

  @override
  String get gen_positionCustom => '自定义';

  @override
  String get gen_positionBoard => '角色位置';

  @override
  String get gen_positionAiTip => '位置由 AI 决定';

  @override
  String gen_positionAt(Object at) {
    return '位置 $at，点一下调整';
  }

  @override
  String get gen_positionUnset => '还没放位置，点一下摆放';

  @override
  String get gen_positionAiHint => '现在由 AI 决定位置';

  @override
  String get gen_positionGridHint => '拖角色到格子里，松手吸附到格子中心';

  @override
  String get gen_positionFreeHint => '拖角色到画面里任意位置';

  @override
  String get gen_positionAiOverlay => '现在是 AI 选择位置。\n切到自定义才能手动摆放。';

  @override
  String get gen_positionToCustom => '切到自定义';

  @override
  String get gen_positionUnplaced => '还没放';

  @override
  String get gen_renameTip => '双击改名';

  @override
  String get gen_moveUp => '上移';

  @override
  String get gen_moveDown => '下移';

  @override
  String get gen_characterDisable => '这次不用这个角色';

  @override
  String get gen_characterEnable => '用这个角色';

  @override
  String get gen_charPositive => '正面';

  @override
  String get gen_charNegative => '负面';

  @override
  String get gen_saveAsBlock => '存为块';

  @override
  String get gen_refs => '参考图';

  @override
  String get gen_img2img => '图生图';

  @override
  String get gen_img2imgDesc => '基于原图生成变体';

  @override
  String gen_img2imgSummary(Object strength, Object noise) {
    return '强度 $strength · 噪声 $noise';
  }

  @override
  String get gen_img2imgDrop => '拖一张图进来，或者';

  @override
  String get gen_upload => '上传';

  @override
  String get gen_replace => '更换';

  @override
  String get gen_edit => '编辑';

  @override
  String get gen_inpaint => '局部重绘';

  @override
  String get gen_placeOnCanvas => '放到画布';

  @override
  String get gen_fromPreciseLibrary => '从精准参考库';

  @override
  String get gen_sketch => '画草图';

  @override
  String get gen_strength => '强度';

  @override
  String get gen_strengthTip => '越高越不像原图（默认 0.7）';

  @override
  String get gen_noise => '噪声';

  @override
  String get gen_noiseTip => '加噪让细节更多变化（默认 0）';

  @override
  String get gen_inpaintStrength => '重绘强度';

  @override
  String get gen_inpaintReady => '蒙版已画好，生成时只重绘涂过的区域。';

  @override
  String get gen_refPause => '这次不发送';

  @override
  String get gen_refResume => '恢复发送';

  @override
  String get gen_refPaused => '已暂停，这次不发送';

  @override
  String get gen_vibe => '风格迁移';

  @override
  String get gen_vibeDesc => '改变图像，保留视觉风格';

  @override
  String get gen_vibeSkipped => '有精准参考，这次不会发送';

  @override
  String get gen_vibeConflict => '生图页有精准参考时，风格迁移不会发送。';

  @override
  String get gen_vibeDrop => '拖图片或 .naiv4vibe 进来，或者';

  @override
  String get gen_addVibe => '添加 Vibe';

  @override
  String get gen_addFromFile => '从文件添加';

  @override
  String get gen_addFromVibeLibrary => '从 Vibe 库添加';

  @override
  String get gen_addFromPreciseLibrary => '从精准参考库添加';

  @override
  String gen_vibeFull(Object max) {
    return '最多 $max 个';
  }

  @override
  String get gen_saveToLibrary => '存入库';

  @override
  String get gen_normalize => '标准化';

  @override
  String get gen_normalizeTip => '按总和标准化各 Vibe 的强度';

  @override
  String gen_vibeExtraCost(Object free, Object each, Object total) {
    return '超过 $free 个后每个 +$each Anlas · 本次 +$total';
  }

  @override
  String get gen_recent => '最近';

  @override
  String get gen_encoded => '已编码';

  @override
  String get gen_encoding => '编码中';

  @override
  String get gen_encode => '编码';

  @override
  String gen_encodeTip(Object cost) {
    return '编码一次 $cost Anlas，编码后可重复使用';
  }

  @override
  String get gen_vibeStrength => '强度';

  @override
  String get gen_vibeInfo => '信息提取';

  @override
  String get gen_vibeInfoReencode => '已编码的 Vibe 改信息提取要重新编码';

  @override
  String get gen_precise => '精准参考';

  @override
  String get gen_preciseDesc => '将生成绑定到角色或风格参考';

  @override
  String get gen_preciseDrop => '拖角色或风格参考图进来，或者';

  @override
  String get gen_preciseCharacter => '角色';

  @override
  String get gen_preciseStyle => '风格';

  @override
  String get gen_preciseBoth => '角色 + 风格';

  @override
  String get gen_fidelity => '保真度';

  @override
  String gen_preciseCost(Object each, Object total) {
    return '每张 $each Anlas · 本次 +$total';
  }

  @override
  String get gen_preciseConflict => '有精准参考时，风格迁移这次不会发送。';

  @override
  String get gen_pauseVibes => '暂停 Vibe';

  @override
  String get gen_savePrecise => '存入精准参考库';

  @override
  String get gen_addPrecise => '添加精准参考';

  @override
  String get gen_image => '图像';

  @override
  String get gen_sizeNormal => '常规';

  @override
  String get gen_sizeLarge => '大图';

  @override
  String get gen_sizeWallpaper => '壁纸';

  @override
  String get gen_sizeSmall => '小图';

  @override
  String get gen_sizeCustom => '自定义';

  @override
  String get gen_portrait => '竖图';

  @override
  String get gen_landscape => '横图';

  @override
  String get gen_square => '方图';

  @override
  String get gen_width => '宽（按 64 取整）';

  @override
  String get gen_height => '高（按 64 取整）';

  @override
  String get gen_swapSize => '交换宽高';

  @override
  String get gen_count => '张数';

  @override
  String get gen_countTip => '一次请求出几张（1–4）';

  @override
  String get gen_repeat => '重复';

  @override
  String get gen_repeatTip => '连续发几次请求';

  @override
  String gen_repeatTotal(Object times, Object total) {
    return '重复 $times 次，共 $total 张 · 按住左右拖动调节';
  }

  @override
  String get gen_steps => '步数';

  @override
  String get gen_guidance => '引导';

  @override
  String get gen_guidanceTip => '越高越贴提示词，太高会发硬（默认 5）';

  @override
  String get gen_cfgRescale => '引导重缩放';

  @override
  String get gen_cfgRescaleTip => '压住高引导带来的过饱和（默认 0）';

  @override
  String get gen_seed => '种子';

  @override
  String get gen_seedPinned => '种子 · 固定';

  @override
  String get gen_seedPinTip => '点一下固定这个种子';

  @override
  String get gen_seedUnpinTip => '点一下改回随机';

  @override
  String get gen_seedRandomize => '改回随机';

  @override
  String get gen_sampler => '采样器';

  @override
  String get gen_samplerRecommended => '推荐';

  @override
  String get gen_samplerOther => '其他';

  @override
  String get gen_noiseSchedule => '噪声调度';

  @override
  String get gen_varietyTip => '前几步跳过引导，构图更多样';

  @override
  String get gen_decrispTip => '减轻高引导下的过度锐利';

  @override
  String get gen_smeaAutoTip => '按尺寸自动决定是否开 SMEA';

  @override
  String get gen_paramsTitle => '生成参数';

  @override
  String get gen_paramsOpen => '展开全部参数';

  @override
  String get gen_paramsClose => '收起参数';

  @override
  String get gen_stop => '停止生成';

  @override
  String gen_cooldown(Object seconds) {
    return '冷却中 $seconds 秒';
  }

  @override
  String get gen_insufficient => 'Anlas 不够';

  @override
  String get gen_free => '这次免费（Opus 额度内）';

  @override
  String get gen_emptyTitle => '写好提示词，开始第一张';

  @override
  String get gen_emptyPress => '按';

  @override
  String get gen_emptyOr => '或点左下角的生成';

  @override
  String get gen_tileFailed => '这张没出来';

  @override
  String get gen_enhance => '增强';

  @override
  String get gen_variations => '变体';

  @override
  String get gen_upscale => '放大';

  @override
  String get gen_upscaleStop => '停止放大';

  @override
  String get gen_upscaleOptions => '放大方案';

  @override
  String get gen_setInit => '设为图生图原图';

  @override
  String get gen_editImage => '编辑图片';

  @override
  String get gen_sendToTools => '发到画布工具';

  @override
  String get gen_display => '画布显示';

  @override
  String get gen_backdrop => '透明图垫底';

  @override
  String get gen_backdropSub => '只垫在透明像素下面，不会存进图片';

  @override
  String get gen_bdChecker => '棋盘格（跟随主题）';

  @override
  String get gen_bdCheckerLight => '浅棋盘格';

  @override
  String get gen_bdCheckerDark => '深棋盘格';

  @override
  String get gen_bdNone => '不垫';

  @override
  String get gen_bdBlack => '黑';

  @override
  String get gen_bdWhite => '白';

  @override
  String get gen_bdGray => '灰';

  @override
  String get gen_bdRed => '红';

  @override
  String get gen_bdGreen => '绿';

  @override
  String get gen_bdBlue => '蓝';

  @override
  String get gen_bdCustom => '自定义';

  @override
  String get gen_zoomToFill => '放大填满';

  @override
  String get gen_zoomToFillSub => '比画布小的图也放大到撑满';

  @override
  String get gen_useSeed => '用这个种子（并固定）';

  @override
  String get gen_copySeed => '复制种子';

  @override
  String get gen_pinImage => '钉在画布上';

  @override
  String get gen_unpinImage => '取消钉住';

  @override
  String get gen_copyImage => '复制图片';

  @override
  String get gen_saveImage => '保存到图库';

  @override
  String get gen_openViewer => '打开大图';

  @override
  String get gen_retry => '重试';

  @override
  String get gen_copyDetail => '复制详情';

  @override
  String get gen_history => '历史记录';

  @override
  String get gen_historyEmpty => '这次还没有生成';

  @override
  String get gen_historyEmptySub => '生成的图会按批次排在这里';

  @override
  String gen_batchCount(Object count) {
    return '$count 张';
  }

  @override
  String gen_batchPending(Object count) {
    return '还剩 $count 张';
  }

  @override
  String get gen_pinnedTip => '钉在画布上的图，点一下飞过去';

  @override
  String get gen_select => '多选';

  @override
  String get gen_selectDone => '完成多选';

  @override
  String gen_selectedCount(Object count) {
    return '已选 $count 张';
  }

  @override
  String get gen_pack => '打包成 zip';

  @override
  String get gen_saveSelected => '保存选中的图';

  @override
  String get gen_removeSelected => '从历史移除';

  @override
  String get gen_autoSaveOn => '自动保存到图库：开';

  @override
  String get gen_autoSaveOff => '自动保存到图库：关';

  @override
  String get gen_scrollLock => '锁定滚动（新图来了不跳到顶部）';

  @override
  String get gen_scrollUnlock => '解除锁定滚动';

  @override
  String get gen_saveAll => '全部保存到图库';

  @override
  String get gen_clearHistory => '清空历史';

  @override
  String get gen_clearHistoryTitle => '清空这次的历史？';

  @override
  String get gen_clearHistoryBody => '只从这里移除，已经保存到图库的文件不受影响。';

  @override
  String get gen_deleteImagesTitle => '从历史移除？';

  @override
  String gen_deleteImagesBody(Object count) {
    return '$count 张图会从这里移除，已经保存到图库的文件不受影响。';
  }

  @override
  String gen_saveBatch(Object count) {
    return '保存这批（$count 张）';
  }

  @override
  String gen_removeBatch(Object count) {
    return '移除这批（$count 张）';
  }

  @override
  String get gen_removeImage => '从历史移除';

  @override
  String get gen_favorite => '收藏';

  @override
  String get gen_unfavorite => '取消收藏';

  @override
  String get gen_sendImg2Img => '发送到图生图';

  @override
  String get gen_sendVibe => '加入风格迁移';

  @override
  String get gen_sendPrecise => '加入精准参考';

  @override
  String get gen_reveal => '在资源管理器中显示';

  @override
  String get gen_opUpscale => '放大过';

  @override
  String get gen_opEnhance => '增强过';

  @override
  String get gen_opVariation => '变体';

  @override
  String get gen_opInpaint => '局部重绘';

  @override
  String get gen_opImg2Img => '图生图';

  @override
  String get tools_free => '免费';

  @override
  String get tools_localFree => '本机 · 免费';

  @override
  String tools_anlasN(Object count) {
    return '$count Anlas';
  }

  @override
  String get tools_cancel => '取消';

  @override
  String get tools_close => '关闭';

  @override
  String get tools_done => '完成';

  @override
  String get tools_reset => '重置';

  @override
  String get tools_apply => '应用';

  @override
  String get tools_retry => '重试';

  @override
  String get tools_optional => '可选';

  @override
  String get tools_justNow => '刚刚';

  @override
  String tools_minutesAgo(Object count) {
    return '$count 分钟前';
  }

  @override
  String tools_hoursAgo(Object count) {
    return '$count 小时前';
  }

  @override
  String tools_monthDay(Object month, Object day) {
    return '$month 月 $day 日';
  }

  @override
  String get tools_useAsInit => '用作图生图底图';

  @override
  String get tools_upscale => '放大';

  @override
  String get tools_enhance => '增强';

  @override
  String get tools_strength => '强度';

  @override
  String get tools_noise => '噪声';

  @override
  String get tools_tipEnhance => '用当前提示词把这张图重画一遍，补细节；可以顺便放大';

  @override
  String get tools_tipVariations => '用这张图的参数直接再出 4 张相近的图，不改你的提示词和设置';

  @override
  String get tools_tipUpscale => '按记住的放大设置直接放大；结果作为新图出现在画布上';

  @override
  String get tools_tipUpscaleRunning => '正在放大，点一下取消';

  @override
  String get tools_tipUpscaleSettings => '换本机 / 云端、方法、模型和倍数';

  @override
  String get tools_tipSetInit => '把这张图放进图生图，作为下一次生成的底图';

  @override
  String get tools_tipEdit => '用画笔、选区、调色修改这张图，完成后替换图生图底图';

  @override
  String get tools_tipInpaint => '画蒙版圈出要重画的地方，其余保持原图';

  @override
  String get tools_tipDirector => '背景移除、线稿、上色、表情修复等后期工具';

  @override
  String get tools_upscaleRunHint => '完成后新图加入历史；没有切到别的图就自动选中它';

  @override
  String get tools_enhanceSub => '用当前提示词把这张图重画一遍，补细节；可以顺便放大';

  @override
  String get tools_enhanceScale => '放大';

  @override
  String get tools_enhanceLocal => '本地放大';

  @override
  String get tools_enhanceLocalRow => '本地';

  @override
  String tools_enhanceOutLocal(Object size, Object factor) {
    return '$size → 本机 $factor';
  }

  @override
  String get tools_enhanceMagnitude => '幅度';

  @override
  String get tools_magLight => '轻微';

  @override
  String get tools_magMedium => '适中';

  @override
  String get tools_magStrong => '强烈';

  @override
  String tools_enhanceValues(Object strength, Object noise) {
    return '强度 $strength · 噪声 $noise';
  }

  @override
  String get tools_enhanceCustomTag => '自定义';

  @override
  String get tools_enhanceCustom => '自定义强度和噪声';

  @override
  String get tools_enhanceCustomHint => '强度越高改得越多；噪声加细节但容易变脏';

  @override
  String get tools_localHint => '每张生成完成后自动在本机放大，不另外花 Anlas';

  @override
  String get tools_localNotSet => '还没选本机放大模型';

  @override
  String get tools_upscaleSettings => '放大设置';

  @override
  String tools_enhanceFooter(Object model, Object steps) {
    return '用当前提示词 · $model · $steps 步';
  }

  @override
  String get tools_enhanceRun => '增强';

  @override
  String get tools_enhanceRunLocal => '增强并本地放大';

  @override
  String get tools_upscaleSub => '放大结果作为新图出现在画布上，不动原图和图生图底图';

  @override
  String get tools_upscaleMethod => '方法';

  @override
  String get tools_upscaleModel => '模型';

  @override
  String get tools_upscaleManage => '管理模型';

  @override
  String get tools_upscaleScale => '倍数';

  @override
  String get tools_upscaleAdvanced => '高级设置';

  @override
  String get tools_upscaleFooter => '设置会记住；工具条上的“放大”直接按这套设置跑';

  @override
  String get tools_modelMissing => '未安装';

  @override
  String get tools_modelDownloading => '下载中';

  @override
  String get tools_modelNone => '未选择';

  @override
  String get tools_edit => '编辑图像';

  @override
  String get tools_editSub => '编辑后会替换图生图底图';

  @override
  String get tools_inpaint => '局部重绘';

  @override
  String get tools_inpaintSub => '只重画蒙版里的地方，其余保持原图';

  @override
  String get tools_backEsc => '返回（Esc）';

  @override
  String get tools_panel => '面板';

  @override
  String get tools_undo => '撤销';

  @override
  String get tools_redo => '重做';

  @override
  String get tools_download => '下载 PNG';

  @override
  String get tools_zoomIn => '放大';

  @override
  String get tools_zoomOut => '缩小';

  @override
  String get tools_zoomFit => '适应窗口';

  @override
  String get tools_applyMask => '应用蒙版';

  @override
  String get tools_applyMaskSub => '回到生图页，自己按生成';

  @override
  String get tools_applyGenerate => '应用并生成';

  @override
  String get tools_applyGenerateSub => '回到生图页并立刻开始重绘';

  @override
  String get tools_discardTitle => '放弃这次修改？';

  @override
  String get tools_discardBody => '还没应用的笔画、蒙版和图层改动都会丢掉。';

  @override
  String get tools_discard => '放弃';

  @override
  String get tools_keepEditing => '继续编辑';

  @override
  String get tools_toolBrush => '画笔';

  @override
  String get tools_toolEraser => '橡皮';

  @override
  String get tools_toolFill => '填充';

  @override
  String get tools_toolBlur => '模糊';

  @override
  String get tools_toolStamp => '仿制图章';

  @override
  String get tools_toolSelect => '矩形选区';

  @override
  String get tools_toolLasso => '套索';

  @override
  String get tools_toolPicker => '吸管';

  @override
  String get tools_toolMaskBrush => '画蒙版';

  @override
  String get tools_toolMaskEraser => '擦蒙版';

  @override
  String get tools_toolFocus => '聚焦区域';

  @override
  String get tools_clearMask => '清空蒙版';

  @override
  String get tools_expand => '扩展边缘';

  @override
  String get tools_adjust => '调整颜色';

  @override
  String get tools_resize => '画布尺寸';

  @override
  String get tools_size => '大小';

  @override
  String get tools_opacity => '不透明';

  @override
  String get tools_intensity => '强度';

  @override
  String get tools_tolerance => '容差';

  @override
  String get tools_tip => '笔尖';

  @override
  String get tools_tipHard => '硬';

  @override
  String get tools_tipSoft => '软';

  @override
  String get tools_tipSquare => '方';

  @override
  String get tools_pressure => '压感';

  @override
  String get tools_squareBrush => '方形笔刷';

  @override
  String get tools_hintStamp => 'Alt + 点击取样，再在别处涂抹';

  @override
  String get tools_hintSelect => '拖出选区；Alt+L 复制成新图层，Delete 清除选区内容';

  @override
  String get tools_hintPicker => '点画面取色；用画笔时按住 Alt 也能临时取色';

  @override
  String get tools_hintMaskFill => '点一下把相近颜色的一片填成蒙版';

  @override
  String get tools_focusContext => '最小上下文';

  @override
  String get tools_hintFocus => '框出要精修的地方，模型只看框内和四周一圈，小脸、手更清楚';

  @override
  String get tools_clearFocus => '清除聚焦';

  @override
  String get tools_edgeTop => '上';

  @override
  String get tools_edgeBottom => '下';

  @override
  String get tools_edgeLeft => '左';

  @override
  String get tools_edgeRight => '右';

  @override
  String tools_hintExpand(Object step) {
    return '拖画布四边也可以；每次 $step 像素';
  }

  @override
  String get tools_maskLook => '蒙版外观';

  @override
  String get tools_maskBorder => '描边';

  @override
  String get tools_patternSolid => '纯色';

  @override
  String get tools_patternLines => '斜线';

  @override
  String get tools_patternCrosshatch => '交叉线';

  @override
  String get tools_patternGrid => '网格';

  @override
  String get tools_patternDots => '圆点';

  @override
  String get tools_patternChecker => '棋盘格';

  @override
  String get tools_patternHearts => '爱心';

  @override
  String get tools_colorPrimary => '前景色';

  @override
  String get tools_colorSecondary => '背景色';

  @override
  String get tools_moreColors => '更多颜色…';

  @override
  String get tools_statusHint => '空格拖动 · 滚轮缩放 · Ctrl+0 适应窗口 · 1 原始大小';

  @override
  String get tools_statusGrid => '蒙版按 8 像素网格对齐';

  @override
  String get tools_statusMask => '蒙版';

  @override
  String get tools_inpaintSettings => '重绘设置';

  @override
  String get tools_inpaintStrength => '重绘强度';

  @override
  String get tools_inpaintStrengthHint => '越低越贴近原图';

  @override
  String get tools_mask => '蒙版';

  @override
  String tools_maskCoverage(Object count) {
    return '的画面 · $count 块';
  }

  @override
  String get tools_focusNone => '未设置（整张图）';

  @override
  String tools_focusContextShort(Object value) {
    return '· 上下文 $value';
  }

  @override
  String get tools_output => '输出';

  @override
  String get tools_expandTag => '扩展';

  @override
  String get tools_layers => '图层';

  @override
  String get tools_addLayer => '加图层';

  @override
  String get tools_add3dLayer => '加 3D 图层';

  @override
  String get tools_layerHint => 'Alt+L 把选区复制成新图层';

  @override
  String get tools_hideLayer => '隐藏图层';

  @override
  String get tools_showLayer => '显示图层';

  @override
  String get tools_layerUp => '上移';

  @override
  String get tools_layerDown => '下移';

  @override
  String get tools_layerDuplicate => '复制图层';

  @override
  String get tools_layerMerge => '向下合并';

  @override
  String get tools_layerDelete => '删除图层';

  @override
  String get tools_currentLayer => '当前图层';

  @override
  String get tools_hue => '色相';

  @override
  String get tools_saturation => '饱和度';

  @override
  String get tools_brightness => '亮度';

  @override
  String get tools_canvas => '画布';

  @override
  String get tools_resizeCanvas => '更改尺寸';

  @override
  String get tools_inpaintNote => '应用后回到生图页，侧栏切到“局部重绘”；也可以用右上角菜单“应用并生成”直接开跑';

  @override
  String get tools_director => '导演工具';

  @override
  String get tools_backGen => '生图';

  @override
  String get tools_dtGroupClean => '清理';

  @override
  String get tools_dtGroupLine => '线条';

  @override
  String get tools_dtGroupColor => '上色与表情';

  @override
  String get tools_dtGroupPixel => '像素';

  @override
  String get tools_dtRemoveBg => '背景移除';

  @override
  String get tools_dtRemoveBgDesc => '抠出人物，得到透明底、原背景、合成三张';

  @override
  String get tools_dtDeclutter => '杂线清理';

  @override
  String get tools_dtDeclutterDesc => '去掉多余的线和噪点，画面更干净';

  @override
  String get tools_dtLineArt => '线稿提取';

  @override
  String get tools_dtLineArtDesc => '提取干净的黑白线稿';

  @override
  String get tools_dtSketch => '草图化';

  @override
  String get tools_dtSketchDesc => '变成铅笔草图的感觉';

  @override
  String get tools_dtColorize => '上色';

  @override
  String get tools_dtColorizeDesc => '给线稿或草图上色，可写提示词';

  @override
  String get tools_dtEmotion => '表情修复';

  @override
  String get tools_dtEmotionDesc => '换表情，可调强度';

  @override
  String get tools_dtPixelSnap => '像素对齐';

  @override
  String get tools_dtPixelSnapDesc => '对齐像素网格、压缩调色板；本机处理';

  @override
  String get tools_dtOpusNote => 'Opus 订阅 1 MP 以内这几项不花 Anlas；背景移除始终计费';

  @override
  String get tools_input => '输入';

  @override
  String get tools_compareSide => '并排';

  @override
  String get tools_compareWipe => '滑动对比';

  @override
  String get tools_compareResult => '只看结果';

  @override
  String get tools_fit => '适应';

  @override
  String get tools_actualSize => '原始大小 100%';

  @override
  String get tools_original => '原图';

  @override
  String get tools_emptyRun => '按“运行”开始';

  @override
  String get tools_emptyEmotion => '选好表情后按“运行”';

  @override
  String get tools_emptyBody => '结果会出现在这里，和原图并排对比';

  @override
  String tools_running(Object tool) {
    return '正在运行$tool…';
  }

  @override
  String get tools_runningBody => '一般几秒就好；结果也会进生图页的历史';

  @override
  String get tools_runFailed => '运行失败';

  @override
  String get tools_noInput => '先放一张图进来';

  @override
  String get tools_noInputBody => '拖进来、Ctrl+V 粘贴，或者从生图历史里选';

  @override
  String get tools_noResult => '还没有结果';

  @override
  String get tools_continue => '继续处理';

  @override
  String get tools_copy => '复制';

  @override
  String get tools_saveGallery => '存到图库';

  @override
  String get tools_queue => '输入队列';

  @override
  String tools_queueCount(Object count) {
    return '$count 张';
  }

  @override
  String get tools_queueHint => '加号：导入文件 / 从生图历史选；也可以拖进来、Ctrl+V 粘贴';

  @override
  String get tools_importFiles => '导入文件';

  @override
  String get tools_fromHistory => '从生图历史选';

  @override
  String get tools_paste => '粘贴';

  @override
  String get tools_removeInput => '移出队列';

  @override
  String get tools_dtOptions => '选项';

  @override
  String get tools_dtNoOptionsBg => '背景移除没有可调的选项。会得到透明底、原背景、合成三张，在结果下面切换。';

  @override
  String get tools_dtNoOptionsDeclutter => '杂线清理没有可调的选项。想要线稿用“线稿提取”。';

  @override
  String get tools_dtNoOptionsLineArt => '线稿提取没有可调的选项。想要上色，把结果“继续处理”再选“上色”。';

  @override
  String get tools_dtNoOptionsSketch =>
      '草图化没有可调的选项。想要更干净的线条用“线稿提取”，想要上色把结果“继续处理”再选“上色”。';

  @override
  String get tools_dtEmotionLabel => '表情';

  @override
  String tools_dtEmotionMore(Object count) {
    return '更多 $count 个';
  }

  @override
  String get tools_dtEmotionLess => '收起';

  @override
  String get tools_dtStrength => '强度';

  @override
  String get tools_defry0 => '正常';

  @override
  String get tools_defry1 => '稍弱';

  @override
  String get tools_defry2 => '弱';

  @override
  String get tools_defry3 => '更弱';

  @override
  String get tools_defry4 => '很弱';

  @override
  String get tools_defry5 => '最弱';

  @override
  String get tools_dtEmotionStrengthHint => '越弱越接近原图的表情';

  @override
  String get tools_dtColorizeStrengthHint => '越弱越接近原图的线条';

  @override
  String get tools_dtPrompt => '补充提示词';

  @override
  String get tools_dtPromptHint => '英文标签，用逗号分开';

  @override
  String get tools_dtEmotionPromptHint => '选表情时会自动带上常用标签，可以改';

  @override
  String get tools_dtColorizePromptHint => '描述想要的配色，例如 blue dress, silver hair';

  @override
  String get tools_dtPalette => '调色板';

  @override
  String get tools_dtPaletteOff => '关闭';

  @override
  String get tools_dtPaletteAuto => '自动';

  @override
  String get tools_dtPaletteCustom => '自定义';

  @override
  String get tools_dtColors => '颜色数';

  @override
  String get tools_dtAvoidRefine => '避免过度细化';

  @override
  String get tools_dtAvoidRefineHint => '网格细节变化大时保持粗网格';

  @override
  String get tools_dtPixelUpscale => '放大回原尺寸';

  @override
  String get tools_dtPixelUpscaleHint => '关掉时输出每格一个像素的小图';

  @override
  String tools_runTool(Object tool) {
    return '运行$tool';
  }

  @override
  String get tools_runHint => '运行 · 处理当前输入';

  @override
  String get tools_runNeedInput => '先在下面放一张输入';

  @override
  String get tools_results => '结果';

  @override
  String get tools_resultsEmpty => '跑过的结果会列在这里';

  @override
  String get tools_resultsHint => '点一条结果再看；结果也会进生图页的历史，要长期留的先存到图库';

  @override
  String get tools_reuse => '沿用设置';

  @override
  String get tools_emoNeutral => '平静';

  @override
  String get tools_emoHappy => '开心';

  @override
  String get tools_emoSad => '难过';

  @override
  String get tools_emoAngry => '生气';

  @override
  String get tools_emoScared => '害怕';

  @override
  String get tools_emoSurprised => '惊讶';

  @override
  String get tools_emoTired => '疲惫';

  @override
  String get tools_emoExcited => '兴奋';

  @override
  String get tools_emoNervous => '紧张';

  @override
  String get tools_emoThinking => '思考';

  @override
  String get tools_emoConfused => '困惑';

  @override
  String get tools_emoShy => '害羞';

  @override
  String get tools_emoDisgusted => '嫌弃';

  @override
  String get tools_emoSmug => '得意';

  @override
  String get tools_emoBored => '无聊';

  @override
  String get tools_emoLaughing => '大笑';

  @override
  String get tools_emoIrritated => '烦躁';

  @override
  String get tools_emoAroused => '动情';

  @override
  String get tools_emoEmbarrassed => '尴尬';

  @override
  String get tools_emoWorried => '担心';

  @override
  String get tools_emoLove => '爱慕';

  @override
  String get tools_emoDetermined => '坚定';

  @override
  String get tools_emoHurt => '受伤';

  @override
  String get tools_emoPlayful => '俏皮';

  @override
  String get auth_logoutConfirm => '确定退出当前账号？';

  @override
  String get naiAgent_title => 'NAI Agent';

  @override
  String get naiAgent_permissionTitle => '需要审批';

  @override
  String get naiAgent_permissionOnce => '允许一次';

  @override
  String get naiAgent_permissionSession => '本会话允许相同调用';

  @override
  String get naiAgent_permissionDeny => '拒绝';

  @override
  String get naiAgent_defaultWorkspace => '工作区 1';

  @override
  String get naiAgent_newChat => '新聊天';

  @override
  String get naiAgent_settings => 'Agent 设置';

  @override
  String get naiAgent_chooseModel => '选择模型';

  @override
  String get naiAgent_interrupted => '上次任务已中断，未自动重发。';

  @override
  String get naiAgent_systemPrompt => '内置提示词';

  @override
  String get naiAgent_promptHelp =>
      '自定义内容替换默认提示词；工具地图由应用追加。已有聊天记录保持原样，后续请求使用新内容。';

  @override
  String get naiAgent_restoreDefault => '恢复默认';

  @override
  String get naiAgent_showEffective => '查看生效提示词';

  @override
  String get naiAgent_useGlobal => '使用全局提示词';

  @override
  String get naiAgent_save => '保存';

  @override
  String get naiAgent_runLimit => '每次运行的模型请求上限';

  @override
  String get naiAgent_enterSends => 'Enter 发送，Shift+Enter 换行';

  @override
  String get naiAgent_dataFolder => '工作区数据目录';

  @override
  String get naiAgent_openFolder => '打开文件夹';

  @override
  String get naiAgent_toolsManuals => '工具与 Skill';

  @override
  String get naiAgent_toolsHint =>
      '当前状态、图片、提示词和工作区文件按需调用；业务操作的详细用法写在 nai-studio、nai-prompt 等 Skill 里，用到时才读取。';

  @override
  String get naiAgent_unknownCost => '实际费用以服务商为准';

  @override
  String get naiAgent_error => '操作未完成，请检查模型设置或工作区文件。';

  @override
  String get naiAgent_visionCurrentProvider => '当前服务商';

  @override
  String naiAgent_visionModelUnsupported(String providerName) {
    return '服务商 $providerName 下的所选模型未声明支持图片输入。请在 设置 → 模型与接口 → $providerName → 模型 → 能力 → 图片输入 确认支持，或切换到支持图片输入的模型。';
  }

  @override
  String naiAgent_visionAttachmentsSkipped(int count, String reason) {
    return '本次有 $count 张图片附件没有发给模型，文字仍照常发送。$reason';
  }

  @override
  String get naiAgent_inputChanged => '准备期间输入已改变，请发送当前草稿。';

  @override
  String get naiAgent_imageLimit => '图片格式无效、文件过大或超出上传限制。';

  @override
  String get naiAgent_composerNotEmpty => '请先保存或发送当前输入，再恢复这条消息。';

  @override
  String get naiAgent_runtimeMissing => 'Agent 运行组件尚未安装，请使用完整更新包。';

  @override
  String get naiAgent_usage => '模型用量';

  @override
  String get naiAgent_globalScope => '全局默认';

  @override
  String get naiAgent_workspaceScope => '当前工作区';

  @override
  String naiAgent_generationLocalEnhance(Object model, Object scale) {
    return '生成后本地超分：$model ×$scale';
  }

  @override
  String naiAgent_galleryDeleteEmptyFolderConfirm(String path) {
    return '删除这个空文件夹及其图库分类？其他文件夹中的图片会保留。\n$path';
  }

  @override
  String naiAgent_galleryDeleteEmptyFoldersConfirm(int count, String paths) {
    return '删除这 $count 个空文件夹及其图库分类？其他文件夹中的图片会保留。\n$paths';
  }

  @override
  String naiAgent_galleryMoreItems(int count) {
    return '……另有 $count 项';
  }

  @override
  String get naiAgent_extensions => '扩展';

  @override
  String get naiAgent_interactionExtension => 'Studio 交互';

  @override
  String get naiAgent_extensionRequired => '内置 · 必需';

  @override
  String get naiAgent_interactionExtensionHint =>
      '按需读取当前 Studio 状态，并通过问题卡片收集用户回答。';

  @override
  String get naiAgent_extensionAddFile => '添加扩展文件';

  @override
  String get naiAgent_extensionAddFolder => '添加扩展目录';

  @override
  String get naiAgent_extensionsHint =>
      '扩展在各工作区独立加载。更改会在当前任务结束后的下一次发送生效。外部扩展能运行本地代码，请选择可信来源。';

  @override
  String get naiAgent_extensionError => '扩展运行失败';

  @override
  String get naiAgent_extensionCompatibility =>
      '支持本地 Pi 扩展及扩展包目录、工具、命令和标准提问对话框；终端专用自定义界面不在桌面渲染。';

  @override
  String get naiAgent_instructions => '指令';

  @override
  String get naiAgent_globalInstructions => '全局指令';

  @override
  String get naiAgent_globalInstructionsHelp =>
      '所有工作区都会使用，可填写语言、风格或任务偏好。留空即可停用这一部分。';

  @override
  String get naiAgent_systemPromptPrefix => '系统提示词前置内容';

  @override
  String get naiAgent_systemPromptPrefixHelp =>
      '插在 NAI Agent 基础提示词之前，保留基础提示词和工具地图。留空即可停用这一部分。';

  @override
  String get naiAgent_instructionOrder =>
      '生效顺序：前置内容 → 基础提示词 → 全局指令 → 工作区规则。仅影响后续请求。';

  @override
  String get naiAgent_saveInstructions => '保存指令';

  @override
  String get naiAgent_mcpBuiltin => 'NAI Studio · 内置工具组';

  @override
  String get naiAgent_mcpBuiltinHint =>
      '提示词、积木、百科、图片、历史、参考图、生图和设置工具。默认按需发现，原有备份、版本校验和真实确认继续生效。';

  @override
  String get naiAgent_mcpAdd => '添加 MCP 服务器';

  @override
  String get naiAgent_mcpName => '服务器名称';

  @override
  String get naiAgent_mcpConfig => '服务器配置（JSON）';

  @override
  String get naiAgent_mcpConfigHint =>
      '支持 stdio 和 Streamable HTTP。粘贴单个服务器配置对象；command 为可执行文件，args 为数组。可设置 env、cwd、url、headers、oauth 和 toolExposure。配置保存在加密存储中。';

  @override
  String get naiAgent_mcpStatus => '查看连接状态';

  @override
  String get naiAgent_mcpReconnect => '重新连接';

  @override
  String get naiAgent_mcpLogin => '登录';

  @override
  String get naiAgent_mcpLogout => '退出登录';

  @override
  String get naiAgent_mcpHint =>
      '默认使用 CodeMode 按需发现。codemode：沙盒调用；deferred：搜索后直接调用；direct：常驻；hidden：隐藏。配置变更在下一次空闲调用时生效。连接检查不会调用聊天模型。';

  @override
  String get promptBlockLibrary_title => '提示词块';

  @override
  String get gen_oldImageLabel => 'OLD';

  @override
  String get gen_compareOriginal => '按住查看原图与局部重绘范围';

  @override
  String get naiAgent_imageTooLarge => '图片超过 64 MiB 或 6400 万像素。';

  @override
  String get naiAgent_linkOnlyImage => '当前来源只提供链接，请保存图片文件后拖入。';

  @override
  String get naiAgent_invalidImage => '无法读取图片，请使用 PNG、JPEG、WebP、GIF 或 BMP 文件。';

  @override
  String naiAgent_importResult(int added, int failed) {
    return '已添加 $added 张图片，$failed 张失败。';
  }

  @override
  String get channel_themeCircuit => '像素电路';

  @override
  String get channel_themeStars => '星图';

  @override
  String get channel_themeHerb => '植物标本';

  @override
  String get channel_themeArcade => '回廊';

  @override
  String get channel_themeAbyss => '深海';

  @override
  String get channel_themeWave => '青海波';

  @override
  String get channel_descCircuit => '两侧各两条总线一路往下，分支、焊盘、芯片；空闲时有光点沿总线流动';

  @override
  String get channel_descStars => '星点、星座连线、刻度环和赤纬尺；亮星空闲时轻微闪烁';

  @override
  String get channel_descHerb => '墨线标本从两侧长出，叶片、花头、胶带和编号标签；空闲时随风轻摆';

  @override
  String get channel_descArcade => '俯视的教堂平面图：图片走在中殿里，两侧是立柱、肋拱、墙窗、轴号和尺寸线';

  @override
  String get channel_descAbyss => '越往下越深（越旧）：深度尺、等深线、上浮的气泡和飘落的海雪';

  @override
  String get channel_descWave => '和风波纹在两侧聚散，配一轮朱日和几道霞；空闲时有光沿波纹扫过';

  @override
  String get channel_themeCaliber => '机芯';

  @override
  String get channel_themeStrata => '地层';

  @override
  String get channel_themeMetro => '地铁';

  @override
  String get channel_themeScore => '乐谱';

  @override
  String get channel_themeLuna => '月相';

  @override
  String get channel_descCaliber =>
      '夹板、日内瓦纹和齿轮串；滚动时齿轮按真实传动比啮合转动，每段一组摆轮游丝，空闲时滴答走动';

  @override
  String get channel_descStrata => '越往下越古老：左侧地质年代柱，两侧岩层和对应年代的化石；钻头跟着视口一路钻下去';

  @override
  String get channel_descMetro =>
      '两侧是地铁线路图：45° 转弯、换乘站和站名；列车停在视口旁并点亮最近一站，另两条线空闲时自己跑';

  @override
  String get channel_descScore => '竖排五线谱一路往下，播放线停在视口中间，经过的音符会亮起；每段一张随滚动转动的唱片';

  @override
  String get channel_descLuna => '左侧一天一格的月相历，右侧潮汐曲线；一轮大月亮跟着视口走，滚动时盈亏随之变化';

  @override
  String get channel_title => '视觉通道';

  @override
  String get channel_subtitle => '滚动时两侧的装饰，只画在图片之外，不挡图';

  @override
  String get channel_paused => '生成中 · 动画已暂停';

  @override
  String get channel_modeOff => '关闭';

  @override
  String get channel_modeFixed => '固定一个';

  @override
  String get channel_modeRandom => '每次随机';

  @override
  String get channel_session => '本次';

  @override
  String get channel_reroll => '换一组';

  @override
  String get channel_offNote => '关闭后保留现在的像素底纹';

  @override
  String get channel_minTwo => '随机至少保留两个主题';

  @override
  String get channel_level => '浓淡';

  @override
  String get channel_levelSoft => '淡';

  @override
  String get channel_levelStandard => '标准';

  @override
  String get channel_levelStrong => '浓';

  @override
  String get channel_ruler => '时间刻度';

  @override
  String get channel_rulerSub => '批次时间、日期分隔和右侧刻度条';

  @override
  String get channel_motion => '空闲微动';

  @override
  String get channel_motionSub => '很轻的动效，生成时自动暂停';

  @override
  String get channel_toastTitle => '本次通道';

  @override
  String channel_batch(String time, int count) {
    return '$time · $count 张';
  }

  @override
  String channel_batchNewest(String time, int count) {
    return '$time · $count 张 · 最新';
  }

  @override
  String channel_batchPending(int count) {
    return '生成中 · $count 张';
  }

  @override
  String channel_dayToday(String date) {
    return '今天 · $date';
  }

  @override
  String channel_dayYesterday(String date) {
    return '昨天 · $date';
  }

  @override
  String channel_monthDayWeek(int month, int day, String weekday) {
    return '$month月$day日 $weekday';
  }

  @override
  String get channel_weekday1 => '周一';

  @override
  String get channel_weekday2 => '周二';

  @override
  String get channel_weekday3 => '周三';

  @override
  String get channel_weekday4 => '周四';

  @override
  String get channel_weekday5 => '周五';

  @override
  String get channel_weekday6 => '周六';

  @override
  String get channel_weekday7 => '周日';

  @override
  String channel_scrubWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get rag_title => 'RAG 向量系统';

  @override
  String get rag_description => '管理本地语义检索、模型与标签上下文推荐';

  @override
  String get rag_enabled => '启用 RAG';

  @override
  String get rag_enabledHint => '开启本地语义检索服务；首次建库需预览范围后手动开始。';

  @override
  String get rag_status => '统一向量池';

  @override
  String get rag_off => '未启用';

  @override
  String get rag_loading => '正在准备本地模型';

  @override
  String get rag_empty => '模型已连接，等待建立索引';

  @override
  String get rag_ready => '语义检索已就绪';

  @override
  String get rag_partial => '部分就绪，未覆盖内容保留普通搜索';

  @override
  String get rag_building => '正在建立索引';

  @override
  String get rag_paused => '建库已暂停，已有索引仍可查询';

  @override
  String get rag_unavailable => 'RAG 暂不可用，保留普通搜索';

  @override
  String get rag_operationFailed => '操作未完成，请检查模型路径与独立运行环境';

  @override
  String rag_indexCounts(int indexed, int total) {
    return '已索引 $indexed / $total 项';
  }

  @override
  String rag_storage(String size) {
    return '索引占用 $size MiB';
  }

  @override
  String get rag_refresh => '刷新状态';

  @override
  String get rag_embeddingPath => 'EmbeddingGemma 2 权重目录';

  @override
  String get rag_rerankerPath => 'Qwen3-Reranker-0.6B 权重目录';

  @override
  String get rag_notConfigured => '尚未配置';

  @override
  String get rag_choose => '选择';

  @override
  String get rag_modelMode => '模型能力';

  @override
  String get rag_modelModeHint => 'Gemma 用于文字与图片，音频关闭；Qwen 仅用于文字重排。';

  @override
  String get rag_discover => '检测本地权重';

  @override
  String get rag_modelsMissing => '未找到模型，请选择已下载的权重目录';

  @override
  String get rag_pythonPath => '独立 Python 运行环境';

  @override
  String get rag_runtime => '推理运行环境';

  @override
  String get rag_runtimeHint => '使用专用环境，不修改现有放大组件。模型权重需单独选择。';

  @override
  String get rag_installRuntime => '安装独立运行环境';

  @override
  String get rag_installHint =>
      '下载 Python 与推理依赖。CUDA 版本约需数 GB 下载空间，适用于兼容的 NVIDIA 显卡；CPU 版本下载较小。不会下载模型权重。';

  @override
  String get rag_installing => '正在安装运行环境';

  @override
  String get rag_device => '运行设备';

  @override
  String get rag_auto => '自动选择';

  @override
  String get rag_tagsEnabled => '标签上下文推荐';

  @override
  String get rag_tagsHint => '结合语义、共现与文字重排；各框、角色和正负面独立。';

  @override
  String get rag_context => '推荐上下文范围';

  @override
  String get rag_contextHint => '两种模式均最多 120 个 Gemma tokens，按完整标签取样；全文仅用于去重。';

  @override
  String get rag_contextBefore => '光标前 · 120 tokens';

  @override
  String get rag_contextAround => '插入点前后 · 120 tokens';

  @override
  String get rag_buildIndex => '预览并建立索引';

  @override
  String rag_plan(int total) {
    return '将收录当前标签目录的 $total 项标签、别名与已有本地释义。首次处理可能较久；可暂停，已完成部分可提前使用。';
  }

  @override
  String get rag_start => '开始建立';

  @override
  String get rag_pause => '暂停建库';

  @override
  String get rag_resume => '继续建库';

  @override
  String get rag_rebuild => '重建索引';

  @override
  String get rag_clear => '清除索引';

  @override
  String get rag_clearHint => '仅删除此来源的派生索引，保留原始内容与模型；重新建库后可继续使用。';

  @override
  String get rag_futureSources =>
      '已接入标签推荐、Wiki、提示词块与图库多模态检索；工作区与 Agent 检索后续接入。';

  @override
  String get rag_badgeHint => '本地语义检索已就绪';

  @override
  String get rag_wikiEnabled => 'Wiki 语义搜索';

  @override
  String get rag_wikiHint => '收录本地百科正文，名称精确匹配优先，语义结果补充。单独预览并开始首次建库。';

  @override
  String get rag_blocksEnabled => '提示词块语义搜索';

  @override
  String get rag_blocksHint => '仅收录已保存、未归档块的标题、标签与正负面文字；不收录图片或编辑草稿。';

  @override
  String rag_textPlan(int documents, int total) {
    return '将收录 $documents 份已保存资料，切分为 $total 个文字片段。首次建库需手动开始，之后增量更新；可暂停，已完成部分可检索。';
  }

  @override
  String rag_textCounts(int indexed, int total) {
    return '已索引 $indexed / $total 个文字片段';
  }

  @override
  String get rag_galleryEnabled => '图库多模态检索';

  @override
  String get rag_galleryHint =>
      '分析已登记图库中的图片画面；仅为 NAI 图的已有参数另建文字索引。原图不改写，普通图不解析其他软件元数据。';

  @override
  String rag_galleryPlan(int images, int parameters) {
    return '当前图库来源将收录 $images 张未删除图片及 $parameters 个 NAI 参数片段。首次需点击开始，之后增量更新；画面与参数分开索引，可随时暂停。';
  }

  @override
  String rag_galleryCounts(
    int indexed,
    int images,
    int parameters,
    int skipped,
  ) {
    return '画面 $indexed / $images 张；NAI 参数 $parameters 段；跳过 $skipped 张';
  }

  @override
  String get rag_galleryMixed => '综合检索';

  @override
  String get rag_galleryVisual => '仅画面';

  @override
  String get rag_galleryParameters => '仅 NAI 参数';

  @override
  String get rag_galleryChooseImage => '选择图片找相似';

  @override
  String get rag_galleryClearImage => '清除查询图片';

  @override
  String get rag_gallerySearchOptions => '图库 RAG 检索方式';

  @override
  String get rag_downloadModel => '下载模型';

  @override
  String get rag_modelDownloading => '正在下载模型';

  @override
  String get rag_modelVerifying => '正在校验模型';

  @override
  String rag_downloadProgress(String done, String total) {
    return '$done / $total MB';
  }

  @override
  String get rag_poolHint => '所有已启用来源共用一个向量池，新增资料与翻译自动增量更新。';

  @override
  String get rag_runtimeReady => '运行环境已就绪';

  @override
  String get rag_runtimeCheck => '检测运行环境';

  @override
  String get rag_runtimeExisting => '正在检测已有环境';

  @override
  String get rag_runtimeDownload => '正在下载环境安装工具';

  @override
  String get rag_runtimeCreate => '正在准备 Python 环境';

  @override
  String get rag_runtimeCuda => '正在安装 CUDA 推理组件';

  @override
  String get rag_runtimePackages => '正在安装推理依赖';

  @override
  String get rag_runtimeVerify => '正在校验环境兼容性';

  @override
  String rag_runtimeElapsed(int seconds) {
    return '此阶段已用 $seconds 秒';
  }

  @override
  String get rag_useRuntime => '使用已有环境';

  @override
  String get set_title => '设置';

  @override
  String get set_search => '搜索设置';

  @override
  String get set_searchResults => '搜索结果';

  @override
  String set_searchCount(Object count) {
    return '$count 项';
  }

  @override
  String get set_searchHint => '结果里的开关和数值可以直接改；点右侧箭头跳到所在页面并高亮这一行。';

  @override
  String get set_searchKeys => '选择';

  @override
  String get set_searchJump => '跳转';

  @override
  String set_searchEmpty(Object query) {
    return '没有找到“$query”';
  }

  @override
  String get set_searchEmptyHint => '试试“代理”“保存”“快捷键”或某个路径';

  @override
  String get set_goTo => '跳到设置';

  @override
  String get set_hasUpdate => '有更新';

  @override
  String get set_groupPersonal => '个人';

  @override
  String get set_groupCreate => '创作';

  @override
  String get set_groupIntelligence => '智能';

  @override
  String get set_groupConnect => '连接';

  @override
  String get set_groupSystem => '系统';

  @override
  String get set_pageOverview => '概览';

  @override
  String get set_pageAccount => '账号';

  @override
  String get set_pageAppearance => '外观';

  @override
  String get set_pageCanvas => '画布与浏览';

  @override
  String get set_pageShortcuts => '快捷键';

  @override
  String get set_pageGeneration => '生成与额度';

  @override
  String get set_pageStorage => '存储与图库';

  @override
  String get set_pageDictionaries => '词库与缓存';

  @override
  String get set_pageModels => '模型与接口';

  @override
  String get set_pageAgent => 'NAI Agent';

  @override
  String get set_pageRag => '语义检索';

  @override
  String get set_pageUpscale => '本地放大';

  @override
  String get set_pageBridges => '桥接与集成';

  @override
  String get set_pageNetwork => '网络与代理';

  @override
  String get set_pagePrivacy => '隐私与保护';

  @override
  String get set_pageBackup => '备份与重置';

  @override
  String get set_pageAbout => '关于';

  @override
  String get set_resetDefault => '恢复默认';

  @override
  String get set_resetPage => '恢复本页默认';

  @override
  String get set_needsRestart => '需重启';

  @override
  String get set_defaultTag => '默认';

  @override
  String get set_readOnly => '只读';

  @override
  String get set_cancel => '取消';

  @override
  String get set_save => '保存';

  @override
  String get set_discard => '放弃';

  @override
  String get set_later => '稍后';

  @override
  String get set_undo => '撤销';

  @override
  String get set_open => '打开';

  @override
  String get set_choose => '选择';

  @override
  String get set_change => '更改';

  @override
  String get set_clear => '清除';

  @override
  String get set_delete => '删除';

  @override
  String get set_copy => '复制';

  @override
  String get set_more => '更多';

  @override
  String get set_refresh => '刷新';

  @override
  String get set_retry => '重试';

  @override
  String get set_test => '测试连接';

  @override
  String get set_testing => '检测中…';

  @override
  String get set_importIt => '导入';

  @override
  String get set_exportIt => '导出';

  @override
  String get set_install => '安装';

  @override
  String get set_download => '下载';

  @override
  String get set_resume => '继续';

  @override
  String get set_pause => '暂停';

  @override
  String get set_rebuild => '重建';

  @override
  String get set_login => '登录';

  @override
  String get set_adjust => '调整';

  @override
  String get set_collapse => '收起';

  @override
  String get set_notSet => '未设置';

  @override
  String get set_defaultLocation => '默认位置';

  @override
  String get set_builtinSound => '内置音效';

  @override
  String get set_justNow => '刚刚';

  @override
  String set_minutesAgo(Object n) {
    return '$n 分钟前';
  }

  @override
  String set_todayAt(Object time) {
    return '今天 $time';
  }

  @override
  String get set_yesterday => '昨天';

  @override
  String set_secondsAgo(Object n) {
    return '$n 秒前';
  }

  @override
  String set_savedChange(Object title, Object from, Object to) {
    return '已保存 · $title $from → $to';
  }

  @override
  String get set_restartBanner => '设置已保存，重启 Studio 后生效。正在进行的生成不受影响。';

  @override
  String get set_restartNow => '立即重启';

  @override
  String get set_unsavedInstructions => '全局指令有未保存的修改';

  @override
  String get set_leaveTitle => '放弃未保存的修改？';

  @override
  String get set_leaveBody => 'Agent 指令还没保存，离开这一页会丢掉修改。';

  @override
  String set_resetPageTitle(Object page) {
    return '把“$page”恢复默认？';
  }

  @override
  String set_resetPageBody(Object count) {
    return '这一页改过的 $count 项会回到默认值，可以在概览里撤销。';
  }

  @override
  String get set_ovDesc => '账号、存储、连接和智能服务的状态都在这里。需要处理的事项排在最前，点卡片直接进入对应设置。';

  @override
  String get set_ovSwitchAccount => '切换账号';

  @override
  String get set_ovTodayUsed => '今天已用';

  @override
  String set_ovMonthly(Object n) {
    return '本月固定额度 $n';
  }

  @override
  String set_ovWarnAt(Object n) {
    return '高消耗提醒 ≥ $n Anlas';
  }

  @override
  String get set_ovWarnOff => '高消耗提醒已关闭';

  @override
  String set_ovRenews(Object date) {
    return '订阅续期 $date';
  }

  @override
  String get set_ovSignedOut => '未登录';

  @override
  String get set_ovAttention => '需要处理';

  @override
  String get set_ovAllClear => '一切正常';

  @override
  String set_attUpdate(Object version) {
    return '有新版本 $version';
  }

  @override
  String set_attRagPaused(Object source) {
    return '$source语义索引已暂停';
  }

  @override
  String set_attRagPausedSub(Object done, Object total) {
    return '已完成 $done / $total，已有部分可检索';
  }

  @override
  String set_attBridgeDown(Object name) {
    return '$name 地址无响应';
  }

  @override
  String set_attCheckedAt(Object detail, Object when) {
    return '$detail · $when检测';
  }

  @override
  String set_attCredential(Object name) {
    return '账号“$name”凭据已过期';
  }

  @override
  String get set_attCredentialSub => '更新后才能切换到这个账号';

  @override
  String set_attDiskLow(Object disk) {
    return '$disk 盘空间不足';
  }

  @override
  String set_attDiskLowSub(Object size) {
    return '剩余 $size，自动保存可能失败';
  }

  @override
  String set_attProvider(Object name) {
    return '$name 连接失败';
  }

  @override
  String get set_attProviderSub => '翻译和反推会回落到其他服务商';

  @override
  String get set_attView => '查看';

  @override
  String get set_attGo => '去看看';

  @override
  String get set_attUpdateCred => '更新凭据';

  @override
  String get set_tileStorage => '存储';

  @override
  String set_tileImages(Object n) {
    return '图库 $n 张';
  }

  @override
  String set_tileSaveTo(Object path) {
    return '保存到 $path';
  }

  @override
  String get set_tileConnect => '连接';

  @override
  String set_tileOnline(Object n) {
    return '$n 项在线';
  }

  @override
  String get set_tileKrita => 'Krita 已连接';

  @override
  String get set_tileKritaOff => 'Krita 未连接';

  @override
  String set_tileAgents(Object n) {
    return '外部 Agent $n 个';
  }

  @override
  String get set_tileComfyDown => 'ComfyUI 无响应';

  @override
  String get set_tileComfyOk => 'ComfyUI 正常';

  @override
  String get set_tileComfyOff => 'ComfyUI 未启用';

  @override
  String get set_tileModels => '模型与接口';

  @override
  String set_tileTranslateVia(Object ms) {
    return '提示词翻译 · $ms';
  }

  @override
  String set_tileAgentModel(Object model) {
    return 'Agent · $model';
  }

  @override
  String set_tileProviders(Object p, Object m) {
    return '$p 个服务商 · $m 个模型';
  }

  @override
  String get set_tileNoModel => '未配置';

  @override
  String get set_tileRag => '语义检索';

  @override
  String get set_tileReady => '就绪';

  @override
  String set_tileRagDone(Object names) {
    return '$names已完成';
  }

  @override
  String set_tileRagPaused(Object name, Object pct) {
    return '$name $pct · 已暂停';
  }

  @override
  String set_tileRagBuilding(Object name, Object pct) {
    return '$name $pct · 建库中';
  }

  @override
  String set_tileRagEmpty(Object name) {
    return '$name还没建库';
  }

  @override
  String set_tileRagError(Object name) {
    return '$name建库出错';
  }

  @override
  String get set_tileUpscale => '本地放大';

  @override
  String set_tileUpscaleModels(Object n) {
    return '$n 个模型可用';
  }

  @override
  String set_tileDefaultIs(Object name) {
    return '$name（默认）';
  }

  @override
  String get set_tileSeedMissing => 'SeedVR2 未安装';

  @override
  String get set_tileSeedReady => 'SeedVR2 已安装';

  @override
  String get set_tileProtect => '保护';

  @override
  String set_tileProtectOn(Object on, Object all) {
    return '$on / $all 已开启';
  }

  @override
  String set_tileInterval(Object s, Object p) {
    return '生成间隔 $s 秒 ± $p%';
  }

  @override
  String get set_tileIntervalOff => '不限制生成间隔';

  @override
  String get set_recent => '最近修改';

  @override
  String get set_recentSub => '自动保存 · 可撤销';

  @override
  String get set_recentEmpty => '还没有修改';

  @override
  String get set_quick => '常用开关';

  @override
  String get set_quickSub => '在这里直接改';

  @override
  String get set_quickDark => '深色模式';

  @override
  String get set_quickChannel => '画布视觉通道';

  @override
  String set_searchTip(Object keys) {
    return '按 $keys 搜索任何设置；结果里可以直接开关，不用跳页。';
  }

  @override
  String get set_accDesc => '管理 NovelAI 账号、默认登录和订阅额度。';

  @override
  String get set_accSaved => '已保存账号';

  @override
  String get set_accSavedSub => '添加后可以在这里一键切换；凭据保存在本机，不会出现在导出的偏好文件里。';

  @override
  String get set_accCurrent => '当前';

  @override
  String get set_accInUse => '使用中';

  @override
  String get set_accSwitch => '切换';

  @override
  String get set_accEmail => '邮箱登录';

  @override
  String get set_accToken => '令牌登录';

  @override
  String set_accRenews(Object date) {
    return '订阅续期 $date';
  }

  @override
  String set_accLastUsed(Object date) {
    return '上次使用 $date';
  }

  @override
  String get set_accNoSub => '无订阅';

  @override
  String get set_accExpired => '凭据已过期';

  @override
  String get set_accEdit => '编辑资料';

  @override
  String get set_accUpdate => '更新凭据';

  @override
  String get set_accMakeDefault => '设为默认账号';

  @override
  String get set_accDelete => '删除账号';

  @override
  String set_accDeleteTitle(Object name) {
    return '删除账号“$name”？';
  }

  @override
  String get set_accDeleteBody => '只删除本机保存的凭据，NovelAI 上的账号和图片不受影响。';

  @override
  String get set_accAdd => '添加账号';

  @override
  String get set_accAddHint => '支持邮箱密码或持久令牌';

  @override
  String get set_accLogin => '登录';

  @override
  String get set_accDefault => '默认账号';

  @override
  String get set_accDefaultSub => '登录页预先选中的账号';

  @override
  String get set_accAutoLogin => '启动时自动登录';

  @override
  String get set_accAutoLoginSub => '使用上次的会话；关掉后每次打开都停在登录页';

  @override
  String get set_accSub => '订阅';

  @override
  String set_accMonthly(Object n) {
    return '每月 $n Anlas';
  }

  @override
  String set_accRemaining(Object n) {
    return '剩余 $n';
  }

  @override
  String set_accResets(Object date) {
    return '$date 重置';
  }

  @override
  String get set_accPortal => '打开 NovelAI 账户页';

  @override
  String get set_accSwitchHint => '切换账号会保留当前草稿和画布；生成队列中的任务按原账号完成。';

  @override
  String get set_apDesc => '主题、文字和提醒方式。所有修改即时保存，可以撤销。';

  @override
  String get set_apTheme => '主题';

  @override
  String get set_apThemeSub => '启动页、登录页和所有工作页面使用同一套主题。';

  @override
  String get set_apLight => '浅色';

  @override
  String get set_apDark => '深色';

  @override
  String get set_apSystem => '跟随系统';

  @override
  String get set_apSystemSub => '按 Windows 设置自动切换';

  @override
  String get set_apText => '文字';

  @override
  String get set_apFont => '界面字体';

  @override
  String get set_apFontSub => '中文用 HarmonyOS Sans SC，数字与代码用 Geist Mono';

  @override
  String get set_apScale => '设置与对话框字号';

  @override
  String get set_apScaleSub => '只放大设置页和弹窗，不影响画布和图片';

  @override
  String get set_apSampleTitle => '标题 · 生成完成';

  @override
  String get set_apSampleBody => '正文 · 结果已保存到本地画廊，可以继续调整提示词。';

  @override
  String get set_apSampleNote => '说明 · 拖动上面的滑块，这里实时预览。';

  @override
  String get set_apLanguage => '语言';

  @override
  String get set_apLanguageSub => '切换后立即生效，无需重启';

  @override
  String get set_apMotion => '动效与声音';

  @override
  String get set_apReduceMotion => '减少动态效果';

  @override
  String get set_apReduceMotionSub => '关闭画布飞行、缩放和面板过渡动画；视觉通道也会停止微动';

  @override
  String get set_apSound => '生成完成音效';

  @override
  String get set_apSoundSub => '一批图片全部完成后播放';

  @override
  String get set_apSoundFile => '完成音效文件';

  @override
  String get set_apPreviewSound => '试听';

  @override
  String get set_apNotify => '通知样式';

  @override
  String get set_apNotifySub => '提示从窗口右上角出现，3 秒后自动消失';

  @override
  String get set_apNotifyPreview => '预览一条';

  @override
  String get set_apPreview => '预览';

  @override
  String get set_apCurrent => '当前';

  @override
  String set_apThemeTip(Object keys) {
    return '快捷键 $keys 可以随时切换深浅色。';
  }

  @override
  String get set_cvDesc => '历史、查看器和无限画布的行为。';

  @override
  String get set_cvBrowse => '浏览';

  @override
  String get set_cvHistoryClick => '点击历史缩略图时';

  @override
  String get set_cvOpenDetail => '打开详情';

  @override
  String get set_cvOpenDetailSub => '弹出大图查看器，适合逐张细看';

  @override
  String get set_cvLinked => '联动预览';

  @override
  String get set_cvLinkedSub => '画布跳到这张并选中，查看器不弹出';

  @override
  String get set_cvViewer => '生成结果显示在';

  @override
  String get set_cvCanvas => '无限画布';

  @override
  String get set_cvCanvasSub => '按批次排成一列，可以平移、缩放、钉住对比';

  @override
  String get set_cvSimple => '简洁查看器';

  @override
  String get set_cvSimpleSub => '只显示最新一张，最省资源';

  @override
  String get set_cvCanvasSec => '画布';

  @override
  String get set_cvLock => '锁定画布视角';

  @override
  String get set_cvLockSub => '新图出现时不自动飞过去，视角保持在你停下的位置';

  @override
  String get set_cvFill => '新图缩放到填满';

  @override
  String get set_cvFillSub => '聚焦单张时放大到可视区域，而不是按原始像素';

  @override
  String get set_cvChannel => '视觉通道';

  @override
  String get set_cvChannelSub => '画布中间留空的长廊，按主题绘制装饰，翻历史时会依次经过各个主题。';

  @override
  String get set_cvMode => '模式';

  @override
  String get set_cvMinTwo => '随机时至少保留两个主题。';

  @override
  String set_cvSession(Object order) {
    return '本次顺序：$order';
  }

  @override
  String get set_cvLevel => '浓淡';

  @override
  String get set_cvRuler => '时间刻度';

  @override
  String get set_cvRulerSub => '批次时间、日期分隔和右侧刻度条';

  @override
  String get set_cvMotion => '空闲微动';

  @override
  String get set_cvMotionSub => '生成中和开启“减少动态效果”时自动暂停';

  @override
  String get set_cvOps => '画布操作';

  @override
  String get set_cvOpScroll => '上下翻';

  @override
  String get set_cvOpPan => '左右平移';

  @override
  String get set_cvOpZoom => '缩放';

  @override
  String get set_cvOpMove => '移动视角';

  @override
  String get set_cvOpAll => '看全局';

  @override
  String get set_cvOpHome => '回到最新一批';

  @override
  String get set_cvWheel => '滚轮';

  @override
  String get set_cvChannelTip => '画布右下角的齿轮里也能改视觉通道，两处是同一份设置。';

  @override
  String get set_scDesc => '按页面分组。点快捷键直接录制新组合；同一页面里重复时会标红，并给出一键修复。';

  @override
  String get set_scSearch => '搜索动作或按键，例如 Ctrl+S';

  @override
  String get set_scAll => '全部';

  @override
  String get set_scKeyboard => '键盘布局';

  @override
  String get set_scKeyboardSub => '点按键筛选下面的列表；蓝色是已占用，红色是冲突。';

  @override
  String get set_scNoMod => '无修饰';

  @override
  String set_scLayer(Object context, Object mod) {
    return '$context · 按住 $mod 时';
  }

  @override
  String set_scLayerNone(Object context) {
    return '$context · 不按修饰键';
  }

  @override
  String get set_scAction => '动作';

  @override
  String get set_scKeys => '快捷键';

  @override
  String get set_scDefault => '默认';

  @override
  String set_scDefaultIs(Object keys) {
    return '默认 $keys';
  }

  @override
  String set_scConflict(Object name) {
    return '与“$name”冲突';
  }

  @override
  String get set_scRecording => '按下新的组合键…';

  @override
  String get set_scRecordHint => 'Esc 取消 · Backspace 清除';

  @override
  String get set_scRecord => '录制新组合';

  @override
  String get set_scClear => '清除快捷键';

  @override
  String get set_scDisplay => '显示';

  @override
  String get set_scEnabled => '启用快捷键';

  @override
  String get set_scInTooltips => '在悬停提示中显示';

  @override
  String get set_scInMenus => '在菜单中显示';

  @override
  String get set_scBadges => '导航上显示数字标识';

  @override
  String get set_scConflicts => '冲突';

  @override
  String set_scConflictCount(Object n) {
    return '$n 项';
  }

  @override
  String set_scConflictLine(Object keys) {
    return '$keys 被两个动作占用';
  }

  @override
  String set_scConflictSub(Object context, Object a, Object b) {
    return '$context：$a、$b。冲突时两个都不触发。';
  }

  @override
  String set_scFix(Object name, Object keys) {
    return '恢复$name为 $keys';
  }

  @override
  String get set_scNoConflict => '没有冲突';

  @override
  String get set_scConfig => '快捷键配置';

  @override
  String get set_scResetAll => '全部恢复默认';

  @override
  String get set_scResetAllTitle => '把全部快捷键恢复默认？';

  @override
  String set_scResetAllBody(Object n) {
    return '$n 个自定义的组合会被还原。';
  }

  @override
  String get set_scHelp => '快捷键帮助';

  @override
  String set_scHelpTip(Object key) {
    return '按 $key 在任何页面查看当前页可用的快捷键。';
  }

  @override
  String get set_scEmpty => '没有匹配的快捷键';

  @override
  String get set_gnDesc => '控制 Anlas 消耗和请求节奏，以及写提示词时的输入辅助。';

  @override
  String get set_gnCost => '额度保护';

  @override
  String get set_gnCostSub => '单次请求的消耗超过阈值时，先弹出确认再发送。';

  @override
  String get set_gnWarn => '高消耗提醒';

  @override
  String get set_gnWarnSub => '超过阈值时先确认';

  @override
  String get set_gnThreshold => '提醒阈值';

  @override
  String set_gnEstimate(
    Object model,
    Object w,
    Object h,
    Object steps,
    Object n,
  ) {
    return '当前生图参数：$model · $w×$h · $steps 步 · 每次 $n 张';
  }

  @override
  String get set_gnWillWarn => '会提醒';

  @override
  String get set_gnNoWarn => '不会提醒';

  @override
  String get set_gnFree => '免费';

  @override
  String get set_gnPace => '请求节奏';

  @override
  String get set_gnPaceSub => '连续生成时每次请求之间等一会儿，减轻服务器压力，也让队列更像手动操作。';

  @override
  String get set_gnLimit => '限制生成间隔';

  @override
  String get set_gnInterval => '间隔';

  @override
  String get set_gnJitter => '随机浮动';

  @override
  String get set_gnJitterSub => '在间隔上下随机增减';

  @override
  String get set_gnTimeline => '按当前设置，连续 10 次请求大约这样分布';

  @override
  String get set_gnInput => '提示词输入';

  @override
  String get set_gnWheel => '滚轮调整权重';

  @override
  String get set_gnWheelSub => '光标放在标签上滚动滚轮，直接加减权重';

  @override
  String get set_gnNoKey => '无需按键';

  @override
  String get set_gnRelated => '相关标签扩展';

  @override
  String get set_gnRelatedSub => '输入标签时附带推荐常一起出现的标签';

  @override
  String get set_gnRag => '语义标签推荐';

  @override
  String get set_gnRagSub => '结合上下文的智能推荐，由“语义检索”提供';

  @override
  String get set_gnReady => '已就绪';

  @override
  String get set_gnNotReady => '未就绪';

  @override
  String get set_gnGoSettings => '去设置';

  @override
  String get set_gnTranslate => '提示词翻译';

  @override
  String get set_gnTranslateSub => '在提示词框里中英互译使用的模型';

  @override
  String get set_gnToday => '今天';

  @override
  String get set_gnUsed => 'Anlas 已用';

  @override
  String get set_gnNow => '现在';

  @override
  String get set_gnWarned => '高消耗提醒触发';

  @override
  String set_gnTimes(Object n) {
    return '$n 次';
  }

  @override
  String get set_gnMaxSingle => '最大单次消耗';

  @override
  String get set_gnFreeTip =>
      '免费额度规则（Opus 小图不扣 Anlas）由生图页按当前参数计算，这里的阈值只看实际要扣的数。';

  @override
  String get set_stDesc => '图片保存在哪里、画廊读哪些文件夹，以及占用与清理。';

  @override
  String get set_stUsage => '占用';

  @override
  String set_stFree(Object disk, Object size) {
    return '$disk 盘剩余 $size';
  }

  @override
  String get set_stRecount => '重新统计';

  @override
  String get set_stCounting => '统计中…';

  @override
  String get set_stImages => '图片';

  @override
  String get set_stUpscaleModels => '放大模型';

  @override
  String get set_stVibes => 'Vibe 库';

  @override
  String get set_stThumbs => '缩略图缓存';

  @override
  String get set_stRag => '语义索引';

  @override
  String get set_stDict => '词库与缓存';

  @override
  String get set_stAgent => 'Agent';

  @override
  String get set_stSave => '保存';

  @override
  String get set_stSavePath => '图片保存位置';

  @override
  String get set_stAutoSave => '自动保存';

  @override
  String get set_stAutoSaveSub => '生成完成后立即写入保存位置；关掉后只留在画布和历史里';

  @override
  String get set_stAssets => '素材与显示';

  @override
  String get set_stVibePath => 'Vibe 库位置';

  @override
  String get set_stQuality => '本地画廊清晰度';

  @override
  String get set_stQualitySub => '缩略图的显示质量';

  @override
  String get set_stHigh => '高清';

  @override
  String get set_stStandard => '标清';

  @override
  String get set_stRoots => '图库来源';

  @override
  String get set_stRootsSub => '任何文件夹都可以加入本地画廊浏览和搜索，不参与自动保存。';

  @override
  String get set_stPrimary => '主目录';

  @override
  String set_stCount(Object n) {
    return '$n 张';
  }

  @override
  String get set_stAddFolder => '添加文件夹';

  @override
  String get set_stImportIndex => '导入标签索引 (.jsonl)';

  @override
  String set_stLastScan(Object when, Object n) {
    return '上次扫描 $when · $n 张';
  }

  @override
  String get set_stMaintain => '维护';

  @override
  String get set_stRescan => '重新扫描图库';

  @override
  String get set_stRescanSub => '检查缺失文件、补扫新文件、重试未读出的元数据';

  @override
  String get set_stScan => '扫描';

  @override
  String get set_stScanning => '扫描中…';

  @override
  String get set_stCleanThumbs => '清理缩略图缓存';

  @override
  String get set_stCleanThumbsSub => '按最近使用淘汰超出上限的缩略图，不碰原图';

  @override
  String get set_stClean => '清理';

  @override
  String get set_stCleanTitle => '清理缩略图缓存？';

  @override
  String get set_stCleanBody => '超出上限的缩略图会被删除，之后浏览时重新生成。原图不受影响。';

  @override
  String get set_stAppData => '应用数据位置';

  @override
  String get set_stAppDataSub => '账号、历史、块库等数据库所在目录；修改后需要重启';

  @override
  String get set_stOpenFolders => '打开文件夹';

  @override
  String get set_stLogs => '日志';

  @override
  String get set_stAppDataShort => '应用数据';

  @override
  String get set_stDeleteTip => '移动或删除单张图片仍在画廊里操作，并遵循“隐私与保护”里的确认规则。';

  @override
  String get set_stRemoveRoot => '移除这个文件夹';

  @override
  String get set_dcDesc => '标签数据和各级缓存。一般不用动，出现补全异常时可以在这里清理。';

  @override
  String get set_dcTags => '标签词库';

  @override
  String get set_dcTagsSub => '自动补全、标签翻译和相关推荐用到的本地数据。';

  @override
  String get set_dcBase => '基础数据库';

  @override
  String set_dcBaseValue(Object n, Object wiki) {
    return '标签 $n 条 · Wiki $wiki 篇';
  }

  @override
  String get set_dcSupplement => '数据补充';

  @override
  String get set_dcCheckUpdates => '检查更新';

  @override
  String get set_dcWikiRefreshAvailable => 'Wiki 正文可刷新';

  @override
  String get set_dcCheckingUpdates => '正在检查…';

  @override
  String get set_dcCheckFailed => '检查失败，原数据仍可用。请重试。';

  @override
  String get set_dcLatest => '已是最新';

  @override
  String get set_dcUpdatesAvailable => '有可用更新';

  @override
  String set_dcLastChecked(Object when) {
    return '上次检查 $when';
  }

  @override
  String get set_dcRefreshWiki => '刷新 Wiki';

  @override
  String get set_dcRefreshWikiTip => '下载当前 Wiki 数据，更新此前未同步的已有正文；保留个人译文。';

  @override
  String set_dcChanged(Object added, Object updated) {
    return '新增 $added 条，更新 $updated 条，已保存在本地';
  }

  @override
  String get set_dcRagSyncTip => '如已使用语义检索，请重启 Studio 后手动同步相应来源的索引。';

  @override
  String get set_dcUpdateTags => '更新 Tag';

  @override
  String get set_dcUpdateWiki => '更新 Wiki';

  @override
  String set_dcSources(Object tagDate, Object wikiDate) {
    return '可用数据：Tag $tagDate · Wiki $wikiDate';
  }

  @override
  String set_dcDownloading(Object received, Object total) {
    return '正在下载 $received / $total';
  }

  @override
  String get set_dcVerifying => '正在校验下载内容…';

  @override
  String set_dcImporting(Object n) {
    return '正在补充本地数据 · 已读取 $n 条';
  }

  @override
  String get set_dcPublishing => '正在切换数据版本…';

  @override
  String get set_dcUpdateFailed => '补充失败，已保留原数据。可重试。';

  @override
  String get set_dcUpdateCancelled => '已取消，原数据保持可用。';

  @override
  String get set_dcInstalled => '已补充';

  @override
  String get set_dcCancelling => '正在取消…';

  @override
  String get set_dcCooc => '共现数据';

  @override
  String get set_dcCoocSub => '用来推荐常一起出现的标签';

  @override
  String set_dcEntries(Object n) {
    return '$n 条';
  }

  @override
  String get set_dcSemantics => '个人语义资料';

  @override
  String get set_dcSemanticsSub => '保存补充的中文资料；清理翻译缓存时保留';

  @override
  String get set_dcTranslate => '标签翻译与语义补充';

  @override
  String get set_dcTranslateSub => '复用已有资料，按需补齐中文核心词、同义词和简释义';

  @override
  String get set_dcCaches => '缓存';

  @override
  String get set_dcCachesSub => '清除后会在使用时重新获取，不影响你的图片和设置。';

  @override
  String get set_dcDanbooru => 'Danbooru 缓存';

  @override
  String get set_dcDanbooruSub => '在线画廊与标签百科的请求结果';

  @override
  String get set_dcTranslation => 'AI 翻译缓存';

  @override
  String get set_dcTranslationSub => '已翻译过的标签和提示词';

  @override
  String set_dcCacheSize(Object n, Object size) {
    return '$n 条 · $size';
  }

  @override
  String set_dcClearTitle(Object name) {
    return '清除$name？';
  }

  @override
  String get set_dcClearBody => '下次用到时会重新获取。';

  @override
  String get set_dcStats => '缓存统计';

  @override
  String get set_dcL1 => 'L1 内存';

  @override
  String get set_dcL2 => 'L2 Hive';

  @override
  String get set_dcL3 => 'L3 SQLite';

  @override
  String set_dcImagesUnit(Object n) {
    return '$n 张图片';
  }

  @override
  String get set_dcAutoRefresh => '自动刷新';

  @override
  String set_dcUpdated(Object when) {
    return '上次更新 $when';
  }

  @override
  String get set_dcResetStats => '重置统计';

  @override
  String get set_dcTip =>
      '词库和缓存可以重新获取。个人语义资料请在本页单独导出；账号、历史和块库的备份位置见“存储与图库 → 应用数据位置”。';

  @override
  String get set_mdDesc =>
      '翻译、反推、标签翻译和 Agent 用到的大模型服务。先添加服务商，再在“功能分配”里给每个功能选模型。';

  @override
  String get set_mdProviders => '服务商';

  @override
  String get set_mdTasks => '功能分配';

  @override
  String get set_mdTaskHint => '即使不使用翻译，也可将模型用于语义分割、结构化排序等功能。';

  @override
  String get set_mdPresets => '提示词预设';

  @override
  String get set_mdRequests => '请求记录';

  @override
  String set_mdProviderCount(Object n) {
    return '$n 个服务商';
  }

  @override
  String set_mdModelCount(Object n) {
    return '$n 个模型';
  }

  @override
  String get set_mdDisabled => '已停用';

  @override
  String get set_mdUnreachable => '连接失败';

  @override
  String get set_mdBaseUrl => '接口地址';

  @override
  String get set_mdApiKey => 'API Key';

  @override
  String set_mdUsedFor(Object tasks) {
    return '用于 $tasks';
  }

  @override
  String get set_mdRetired => '服务商已下线';

  @override
  String get set_mdDelete => '删除服务商';

  @override
  String set_mdDeleteTitle(Object name) {
    return '删除服务商“$name”？';
  }

  @override
  String get set_mdDeleteBody => '用到它的功能会回落到其他可用服务商。';

  @override
  String get set_mdTaskPrompt => '提示词翻译';

  @override
  String get set_mdTaskReverse => '提示词反推';

  @override
  String get set_mdTaskTag => '标签翻译与语义补充';

  @override
  String get set_mdTaskWiki => '百科翻译';

  @override
  String get set_mdFeature => '功能';

  @override
  String get set_mdProvider => '服务商';

  @override
  String get set_mdModel => '模型';

  @override
  String get set_mdPreset => '预设';

  @override
  String get set_mdStatus => '状态';

  @override
  String get set_mdAvailable => '可用';

  @override
  String get set_mdFallback => '回落到第一个可用服务商';

  @override
  String get set_mdNotChosen => '未选择';

  @override
  String get set_mdBuiltin => '内置';

  @override
  String get set_mdNewPreset => '新建预设';

  @override
  String get set_mdEdit => '编辑';

  @override
  String get set_mdTime => '时间';

  @override
  String set_mdTokens(Object n) {
    return '$n tokens';
  }

  @override
  String get set_mdFailed => '失败';

  @override
  String get set_mdOk => '成功';

  @override
  String set_mdShowing(Object n, Object total) {
    return '显示最近 $n 条，共 $total 条';
  }

  @override
  String get set_mdImport => '导入配置';

  @override
  String get set_mdAddProvider => '添加服务商';

  @override
  String get set_mdEmpty => '还没有服务商';

  @override
  String get set_mdEmptySub => '添加一个服务商后，翻译和反推就能用了。';

  @override
  String get set_agDesc => '侧栏助手的模型、指令、Skill、扩展和 MCP 工具。';

  @override
  String get set_agModelSec => '模型';

  @override
  String get set_agModel => '默认模型';

  @override
  String get set_agModelSub => '思考强度在聊天框里按任务调整';

  @override
  String get set_agEnter => 'Enter 直接发送';

  @override
  String get set_agEnterSub => '关掉后用 Ctrl+Enter 发送，Enter 换行';

  @override
  String get set_agMax => '单次任务最多请求';

  @override
  String get set_agMaxSub => '防止 Agent 陷入循环';

  @override
  String get set_agTimesUnit => '次';

  @override
  String get set_agInstr => '指令';

  @override
  String get set_agInstrSub => '按下面的顺序拼成最终提示词；已有聊天保持原样，之后的请求使用新内容。';

  @override
  String get set_agOrderBuiltin => '内置系统提示词';

  @override
  String get set_agOrderPrefix => '内置提示词前';

  @override
  String get set_agOrderGlobal => '全局指令';

  @override
  String get set_agOrderWorkspace => '工作区规则';

  @override
  String get set_agGlobal => '全局指令';

  @override
  String get set_agGlobalHint => '相当于系统级 AGENTS.md，对所有工作区生效。';

  @override
  String get set_agPrefix => '内置提示词前';

  @override
  String get set_agPrefixHint => '在内置系统提示词之前加入的固定内容，例如身份或输出格式。';

  @override
  String get set_agBuiltin => '内置系统提示词';

  @override
  String get set_agFinal => '查看最终提示词';

  @override
  String get set_agExt => '扩展';

  @override
  String get set_agExtSub => '各工作区独立加载；外部扩展能运行本地代码，请只添加可信来源。';

  @override
  String get set_agStudioExt => 'Studio 交互';

  @override
  String get set_agStudioExtSub => '读取当前 Studio 状态，并通过问题卡片收集回答';

  @override
  String get set_agRequired => '内置 · 必需';

  @override
  String get set_agAddFile => '添加扩展文件';

  @override
  String get set_agAddDir => '添加扩展目录';

  @override
  String get set_agMcp => 'MCP 服务器';

  @override
  String get set_agMcpSub => '默认 CodeMode 按需发现，工具不会一次性塞进上下文。';

  @override
  String get set_agBuiltinTools => 'NAI Studio · 内置工具组';

  @override
  String get set_agBuiltinToolsSub => '提示词、块、百科、图片、历史、参考图、生图与设置工具';

  @override
  String set_agConnected(Object n) {
    return '已连接 · $n 个工具';
  }

  @override
  String get set_agConnecting => '连接中…';

  @override
  String get set_agNeedsLogin => '需要登录';

  @override
  String get set_agMcpError => '连接失败';

  @override
  String get set_agMcpOff => '已停用';

  @override
  String get set_agAddMcp => '添加 MCP 服务器';

  @override
  String get set_agTools => '工具';

  @override
  String set_agToolCount(Object n) {
    return '$n 个';
  }

  @override
  String get set_agToolsTip =>
      '业务工具经 codemode 按需发现，用法写在 nai-studio Skill。生图类工具始终先报价，等你确认后才执行。';

  @override
  String get set_agData => '数据目录';

  @override
  String get set_agWorkspaces => '工作区';

  @override
  String get set_agSessions => '会话';

  @override
  String get set_agCostTip => '费用由服务商计费，Studio 只显示 token 用量。';

  @override
  String get set_agOpen => '打开 Agent';

  @override
  String get set_agEditMcp => '编辑';

  @override
  String get set_agRemoveMcp => '移除服务器';

  @override
  String get set_agRemoveExt => '移除扩展';

  @override
  String get set_rgDesc => '本地运行的 RAG：给标签推荐、Wiki、提示词块和图库找相似提供语义能力，不上传任何内容。';

  @override
  String get set_rgReady => '语义检索已就绪';

  @override
  String get set_rgOff => '语义检索已关闭';

  @override
  String get set_rgPartial => '部分来源建库中';

  @override
  String get set_rgAllDone => '全部完成';

  @override
  String get set_rgPool => '所有来源共用一个本地向量池，新增内容自动增量更新。';

  @override
  String get set_rgStepRuntime => '运行环境';

  @override
  String get set_rgStepEmbed => '嵌入';

  @override
  String get set_rgStepRerank => '重排';

  @override
  String get set_rgStepDevice => '设备';

  @override
  String get set_rgSources => '来源';

  @override
  String get set_rgSourcesSub => '每个来源单独建库、单独开关；建库可以暂停，已完成的部分立即可用。';

  @override
  String get set_rgTags => '标签上下文推荐';

  @override
  String get set_rgTagsSub => '结合语义、共现与重排；各提示词框、角色和正负面分开计算';

  @override
  String get set_rgWiki => 'Wiki 语义搜索';

  @override
  String get set_rgWikiSub => '本地百科正文，名称精确匹配优先，语义结果补充';

  @override
  String get set_rgBlocks => '提示词块';

  @override
  String get set_rgBlocksSub => '已保存、未归档块的标题、标签与正负面文字';

  @override
  String get set_rgGallery => '图库多模态';

  @override
  String get set_rgGallerySub => '分析画面找相似图；NAI 图的参数另建文字索引，原图不改写';

  @override
  String set_rgCount(Object done, Object total) {
    return '$done / $total';
  }

  @override
  String set_rgSegments(Object done, Object total) {
    return '$done / $total 段';
  }

  @override
  String set_rgGalleryCount(Object done, Object total, Object n) {
    return '画面 $done / $total · 参数 $n 段';
  }

  @override
  String get set_rgPaused => '已暂停';

  @override
  String get set_rgBuilding => '建库中';

  @override
  String get set_rgError => '出错';

  @override
  String get set_rgClearIndex => '清除索引';

  @override
  String set_rgClearTitle(Object name) {
    return '清除“$name”的索引？';
  }

  @override
  String get set_rgClearBody => '只删除派生索引，原始内容和模型都保留。';

  @override
  String get set_rgContext => '推荐上下文';

  @override
  String get set_rgContextSub => '两种都最多取 120 个 Gemma token，按完整标签截取。';

  @override
  String get set_rgRange => '取样范围';

  @override
  String get set_rgBefore => '光标前';

  @override
  String get set_rgAround => '插入点前后';

  @override
  String get set_rgRuntime => '模型与运行环境';

  @override
  String get set_rgEmbedPath => '嵌入模型目录';

  @override
  String get set_rgRerankPath => '重排模型目录';

  @override
  String get set_rgDevice => '运行设备';

  @override
  String get set_rgAuto => '自动';

  @override
  String get set_rgEnv => '运行环境';

  @override
  String get set_rgEnvSub => '独立 Python 与推理依赖，不下载模型权重';

  @override
  String get set_rgCheck => '检测';

  @override
  String get set_rgReinstall => '重新安装';

  @override
  String get set_rgProgress => '建库进度';

  @override
  String get set_rgOverall => '总体';

  @override
  String get set_rgShortTags => '标签';

  @override
  String get set_rgShortWiki => 'Wiki';

  @override
  String get set_rgShortBlocks => '块';

  @override
  String get set_rgShortGallery => '图库';

  @override
  String get set_rgTip => '清除某个来源只删除它的派生索引，原始内容和模型都保留。';

  @override
  String get set_rgNotReady => '语义检索还不能用';

  @override
  String get set_rgNotReadySub => '先安装运行环境，再选好两个模型目录。';

  @override
  String get set_rgEmpty => '未建立';

  @override
  String get set_rgBuild => '建立索引';

  @override
  String get set_rgContinue => '继续建立';

  @override
  String set_rgSkipped(Object n) {
    return '跳过 $n 张';
  }

  @override
  String get set_rgStartupTitle => '准备本地索引';

  @override
  String get set_rgStartupBody => '首次建立或继续索引前，需要先准备本地运行环境、模型和已有数据。';

  @override
  String get set_rgStartupWaitTitle => '可能需要几分钟或更久';

  @override
  String get set_rgStartupWaitBody => '准备期间，进度数字可能暂时不变，请耐心等待。';

  @override
  String get set_rgStartupFrequency => '每次启动仅提示一次';

  @override
  String get set_rgLoading => '正在载入索引';

  @override
  String get set_rgOpening => '正在连接本地工作进程，读取已有索引。';

  @override
  String get set_rgLoadingSaved => '正在载入已保存的检索索引。';

  @override
  String set_rgRestoring(String done, String total) {
    return '正在恢复检索索引 $done / $total，已有向量会直接复用。';
  }

  @override
  String get set_rgSaving => '正在保存恢复后的检索索引。';

  @override
  String get set_rgReadingSources => '正在读取各来源的索引状态。';

  @override
  String get set_rgLoadingTimeout => '索引载入长时间没有进展或已达到时间上限，请重试。已有数据保留。';

  @override
  String get set_rgPreparing => '正在准备索引';

  @override
  String get set_rgPreparingHint => '正在准备或检查索引，数据较多时请耐心等待；进度数字可能暂时不变。';

  @override
  String get set_rgPlanLoading => '正在统计要收录的内容…';

  @override
  String set_rgPlanTags(Object n) {
    return '将收录 $n 项标签、别名与已有本地释义。';
  }

  @override
  String set_rgPlanText(Object docs, Object n) {
    return '将收录 $docs 份资料，切成 $n 个文字片段。';
  }

  @override
  String set_rgPlanGallery(Object images, Object n) {
    return '将收录 $images 张图片和 $n 段 NAI 参数，画面与参数分开索引。';
  }

  @override
  String get set_rgPlanNote => '首次处理可能较久，可以随时暂停，已完成的部分立即可用。';

  @override
  String get set_rgPlanRebuild => '重建会先清掉这个来源的现有索引。';

  @override
  String get set_rgStart => '开始';

  @override
  String get set_rgDownload => '下载';

  @override
  String set_rgDownloading(Object done, Object total) {
    return '正在下载 $done / $total';
  }

  @override
  String set_rgDownloadingUnknown(Object done) {
    return '正在下载 $done';
  }

  @override
  String get set_rgVerifying => '正在校验文件…';

  @override
  String get set_rgDiscover => '查找本地模型';

  @override
  String get set_rgDiscoverSub =>
      '在工作区 04_工具/models 里找 EmbeddingGemma 2 和 Qwen3-Reranker 0.6B，找到后自动填好上面两个目录。';

  @override
  String get set_rgFind => '查找';

  @override
  String get set_rgModelsMissing => '没找到。可以点“下载”，或手动选择已下载的权重目录。';

  @override
  String get set_rgPython => 'Python 解释器';

  @override
  String get set_rgPythonSub => '默认用自动安装的独立环境；也可以选一个已有的 python.exe。';

  @override
  String get set_rgPythonAuto => '自动';

  @override
  String get set_rgPythonNone => '未安装';

  @override
  String get set_rgPythonPending => '选的解释器还没启用，点“使用此解释器”会按它重新安装依赖。';

  @override
  String get set_rgUsePython => '使用此解释器';

  @override
  String get set_rgEnvReady => '已就绪';

  @override
  String get set_rgEnvMissing => '还没有安装';

  @override
  String get set_rgInstall => '安装';

  @override
  String get set_rgInstallHint =>
      '下载 Python 与推理依赖，不下载模型权重。NVIDIA 显卡选 CUDA（约需数 GB）；其他选 CPU，下载较小。';

  @override
  String get set_rgInstallCuda => 'CUDA · NVIDIA';

  @override
  String get set_rgInstallCpu => 'CPU';

  @override
  String get set_rgPhaseExisting => '正在检测已有环境';

  @override
  String get set_rgPhaseDownload => '正在下载安装工具';

  @override
  String get set_rgPhaseCreate => '正在准备 Python 环境';

  @override
  String get set_rgPhaseCuda => '正在安装 CUDA 推理组件';

  @override
  String get set_rgPhasePackages => '正在安装推理依赖';

  @override
  String get set_rgPhaseCheck => '正在校验环境';

  @override
  String set_rgElapsed(Object time) {
    return '此阶段已用 $time';
  }

  @override
  String get set_upDesc => '管理本机超分模型和组件。所有下载都需要你手动开始。';

  @override
  String set_upGpu(Object name, Object n) {
    return '$name · $n GB';
  }

  @override
  String get set_upNoGpu => '没有检测到独立显卡';

  @override
  String get set_upLocal => '在本机放大图片，不消耗 Anlas。';

  @override
  String get set_upEsrgan => '常规模型';

  @override
  String get set_upEsrganSub =>
      'Real-ESRGAN NCNN，4 倍放大，速度快，任何支持 Vulkan 的显卡都能用。';

  @override
  String get set_upAnimeQuality => '动漫 · 画质';

  @override
  String get set_upAnimeFast => '动漫 · 快速';

  @override
  String get set_upGeneral => '通用 · 摄影';

  @override
  String get set_upBuiltin => '内置';

  @override
  String get set_upInstalled => '已安装';

  @override
  String get set_upNotInstalled => '未安装';

  @override
  String get set_upFailed => '下载失败';

  @override
  String get set_upImport => '导入模型';

  @override
  String get set_upImportHint => '选择配套的 .param 和 .bin（4 倍 Real-ESRGAN NCNN）';

  @override
  String get set_upSeed => 'SeedVR2 扩散放大';

  @override
  String get set_upSeedSub =>
      '画质更好、更慢，需要 NVIDIA 显卡。型号共用 VAE（约 0.5 GB）和 Python/CUDA 环境。';

  @override
  String get set_upSeed3b => '3B · 均衡';

  @override
  String get set_upSeed3bSub => '兼顾效果与资源占用，适合日常放大';

  @override
  String get set_upSeed7b => '7B · 高画质';

  @override
  String get set_upSeed7bSub => '更高画质潜力，需要更多显存与时间';

  @override
  String get set_upSeed7bSharp => '7B · 锐利';

  @override
  String get set_upSeed7bSharpSub => '偏向更锐利的细节，适合强化纹理';

  @override
  String get set_upSeed3bInt8 => '3B · 均衡 INT8';

  @override
  String get set_upSeed3bInt8Sub => '3B 均衡型号的 INT8 量化版本';

  @override
  String get set_upSeed7bInt8 => '7B · 高画质 INT8';

  @override
  String get set_upSeed7bInt8Sub => '7B 高画质型号的 INT8 量化版本';

  @override
  String get set_upSeed7bSharpInt8 => '7B · 锐利 INT8';

  @override
  String get set_upSeed7bSharpInt8Sub => '7B 锐利型号的 INT8 量化版本';

  @override
  String set_upVram(Object n) {
    return '显存 ≥ $n GB';
  }

  @override
  String set_upProgress(Object done, Object total, Object speed) {
    return '$done / $total · $speed/s';
  }

  @override
  String get set_upVramMode => '显存模式';

  @override
  String get set_upRecommended => '推荐';

  @override
  String get set_upLowVram => '低显存';

  @override
  String get set_upOffload => 'CPU 卸载层数';

  @override
  String get set_upOffloadSub => '卸载越多越省显存，但更慢、占更多内存';

  @override
  String get set_upTiling => 'VAE 分块';

  @override
  String get set_upTilingSub => '小分块省显存，重叠可以减轻接缝';

  @override
  String get set_upNoise => '实验性噪声';

  @override
  String set_upNoiseSub(Object a, Object b) {
    return '输入噪声 $a · 潜空间噪声 $b；保持 0 即沿用当前效果';
  }

  @override
  String get set_upInputNoise => '输入噪声';

  @override
  String get set_upLatentNoise => '潜空间噪声';

  @override
  String get set_upExperimental => '实验';

  @override
  String get set_upRtx => 'RTX Video';

  @override
  String get set_upRtxSub => '使用 NVIDIA RTX Video 快速放大，约 64 MB 独立组件。';

  @override
  String get set_upRtxName => 'RTX Video Super Resolution';

  @override
  String get set_upRtxNeeds => '需要兼容的 RTX 显卡与驱动';

  @override
  String get set_upDefault => '默认放大方式';

  @override
  String get set_upDefaultTip => '生图页工具条上的“本地放大”默认用这个，菜单里随时可换。';

  @override
  String get set_upVramTip => '显存不足时不会自动换型号；可以改用 3B、降低倍率，或开启低显存与 VAE 分块。';

  @override
  String set_upRemoveTitle(Object name) {
    return '删除$name？';
  }

  @override
  String get set_upRemoveBody => '之后要用时需要重新下载。';

  @override
  String get set_brDesc => '和本机其他软件协作：Krita、外部 Agent 和 ComfyUI。';

  @override
  String get set_brKritaSub => '在 Krita 里直接调用 Studio 生图，结果回到 Krita 图层。';

  @override
  String get set_brKrita => 'Krita 桥接';

  @override
  String get set_brLoopback => '本机监听，只接受 127.0.0.1 的连接';

  @override
  String get set_brConnected => '已连接';

  @override
  String get set_brWaiting => '等待 Krita 连接';

  @override
  String get set_brRegenerate => '重新生成会话';

  @override
  String get set_brDiscovery => '发现文件';

  @override
  String get set_brAgents => '外部 Agent';

  @override
  String get set_brAgentsSub => '让 Claude Code、Codex 等能执行本机命令的 Agent 读写参数和生图。';

  @override
  String get set_brLocal => '本机桥接';

  @override
  String set_brClients(Object n) {
    return '$n 个 Agent 已连接';
  }

  @override
  String get set_brNoClients => '没有 Agent 连接';

  @override
  String get set_brTakeover => '复制接管说明';

  @override
  String get set_brEnd => '结束连接';

  @override
  String get set_brActivity => '最近活动';

  @override
  String get set_brComfySub => '导入 ComfyUI 工作流，在 Studio 里填参运行。';

  @override
  String get set_brComfyEnable => '启用 ComfyUI';

  @override
  String get set_brComfyUrl => '服务地址';

  @override
  String set_brComfyFailed(Object reason, Object when) {
    return '连接失败：$reason（$when）。确认 ComfyUI 已启动并允许本机访问。';
  }

  @override
  String set_brComfyOk(Object when) {
    return '连接正常（$when）';
  }

  @override
  String get set_brStatus => '状态';

  @override
  String set_brAgentsShort(Object n) {
    return '$n 个';
  }

  @override
  String get set_brOff => '未启用';

  @override
  String get set_brNoResponse => '无响应';

  @override
  String get set_brTip => '所有桥接只在本机回环地址上监听，不对局域网开放。代理设置不影响这些连接。';

  @override
  String get set_nwDesc => '代理和连接状态。';

  @override
  String get set_nwProxy => '代理';

  @override
  String get set_nwProxySub => '访问 NovelAI、Danbooru、GitHub 更新和第三方模型服务时使用。';

  @override
  String get set_nwUse => '使用代理';

  @override
  String get set_nwMode => '方式';

  @override
  String get set_nwSystem => '跟随系统';

  @override
  String get set_nwManual => '手动';

  @override
  String get set_nwAddress => '地址';

  @override
  String set_nwDetected(Object addr) {
    return '系统代理检测到 $addr。代理只转发上述外部请求，本机桥接和本地模型不经过代理。';
  }

  @override
  String get set_nwNoSystem => '没有检测到系统代理。代理只转发外部请求，本机桥接和本地模型不经过代理。';

  @override
  String get set_nwCheck => '连接检测';

  @override
  String get set_nwCheckSub => '一键检查各服务是否可达，出错时更容易判断是网络还是服务的问题。';

  @override
  String get set_nwNaiImage => 'NovelAI 生图';

  @override
  String get set_nwNaiApi => 'NovelAI 账户';

  @override
  String get set_nwDanbooru => 'Danbooru';

  @override
  String get set_nwUpdate => '应用更新';

  @override
  String get set_nwCheckAll => '全部检测';

  @override
  String set_nwChecked(Object when) {
    return '上次检测 $when';
  }

  @override
  String get set_nwViaProxy => '经过代理';

  @override
  String get set_nwDirect => '直连';

  @override
  String get set_nwNeverChecked => '还没检测过';

  @override
  String get set_nwFail => '失败';

  @override
  String get set_nwTip => '改代理后需要重启才会生效；Studio 会提醒，不会自动重启打断你的工作。';

  @override
  String get set_pvDesc => '分享图片时带出什么信息，以及哪些操作需要你确认。';

  @override
  String get set_pvProtect => '保护';

  @override
  String get set_pvStrip => '分享时去除元数据';

  @override
  String get set_pvStripSub => '复制或拖出图片时去掉提示词和参数，原文件不变';

  @override
  String get set_pvExternal => '发送到外部前提醒';

  @override
  String get set_pvExternalSub => '把图片发给其他软件或网页前先确认';

  @override
  String get set_pvDanger => '危险操作需确认';

  @override
  String get set_pvDangerSub => '删除、清空、覆盖等不可撤销的操作先弹确认';

  @override
  String get set_pvOverwrite => '保存时不覆盖';

  @override
  String get set_pvOverwriteSub => '目标位置有同名文件时自动改名';

  @override
  String get set_pvBlacklist => '在线画廊黑名单';

  @override
  String get set_pvBlacklistSub => '含有这些标签的图片在在线画廊里直接隐藏。';

  @override
  String get set_pvAddTag => '添加标签…';

  @override
  String get set_pvSync => '同步 Danbooru 黑名单';

  @override
  String set_pvSyncSub(Object user, Object when) {
    return '已登录 $user · 上次同步 $when';
  }

  @override
  String set_pvSyncNever(Object user) {
    return '已登录 $user · 还没同步过';
  }

  @override
  String get set_pvSyncSignedOut => '登录 Danbooru 后可以同步账号里的黑名单';

  @override
  String get set_pvSyncNow => '立即同步';

  @override
  String get set_pvSyncing => '同步中…';

  @override
  String get set_pvAutoSync => '启动时自动同步';

  @override
  String get set_pvExported => '导出时包含什么';

  @override
  String get set_pvIncPrefs => '外观、操作、输入偏好';

  @override
  String get set_pvIncRules => '保护规则与黑名单';

  @override
  String get set_pvIncCred => '账号凭据';

  @override
  String get set_pvIncPaths => '文件路径';

  @override
  String get set_pvIncDrafts => '草稿与模型绑定';

  @override
  String get set_pvTip => '元数据保护只作用于“复制”和“拖出”，保存到磁盘的原图始终保留完整参数，方便日后复用。';

  @override
  String get set_bkDesc => '在设备之间迁移偏好，或者回到默认状态。所有重置都会先备份。';

  @override
  String get set_bkPrefs => '偏好设置';

  @override
  String get set_bkPrefsSub => '外观、操作、输入与保护规则。账号凭据、路径、草稿和模型绑定不会写进文件。';

  @override
  String get set_bkExport => '导出';

  @override
  String get set_bkExportSub => '保存为 studio-preferences.json';

  @override
  String get set_bkExportBtn => '导出…';

  @override
  String get set_bkImport => '导入';

  @override
  String get set_bkImportSub => '应用前会显示将修改多少项，并自动备份当前设置';

  @override
  String get set_bkImportBtn => '选择文件…';

  @override
  String get set_bkUndoImport => '撤销上次导入';

  @override
  String set_bkUndoImportSub(Object when) {
    return '回到 $when 导入前的状态';
  }

  @override
  String get set_bkNoImport => '还没有导入过';

  @override
  String get set_bkRestore => '恢复';

  @override
  String get set_bkOther => '其他配置';

  @override
  String set_bkShortcutsSub(Object n, Object m) {
    return '$n 个动作，$m 个已自定义';
  }

  @override
  String get set_bkModelsSub => '服务商、功能分配和预设；API Key 默认不导出';

  @override
  String get set_bkCopyConfig => '复制配置';

  @override
  String get set_bkReset => '恢复默认';

  @override
  String get set_bkResetSub => '选择要重置的范围；其他设置保持不变。';

  @override
  String get set_bkScopeAppearance => '外观与操作';

  @override
  String get set_bkScopeAppearanceSub => '主题、字体、语言、画布、提醒';

  @override
  String get set_bkScopeInput => '输入与补全';

  @override
  String get set_bkScopeInputSub => '滚轮权重、标签扩展、自动补全';

  @override
  String get set_bkScopeProtect => '隐私与生成保护';

  @override
  String get set_bkScopeProtectSub => '元数据、确认、高消耗提醒、请求节奏';

  @override
  String get set_bkScopeShortcuts => '快捷键';

  @override
  String set_bkScopeShortcutsSub(Object n) {
    return '全部 $n 个动作';
  }

  @override
  String get set_bkResetBtn => '恢复所选为默认…';

  @override
  String get set_bkResetHint => '会先备份当前设置，可以撤销';

  @override
  String get set_bkResetTitle => '恢复所选设置为默认？';

  @override
  String set_bkResetBody(Object scopes) {
    return '$scopes 会回到默认值。当前设置会先自动备份。';
  }

  @override
  String get set_bkAuto => '自动备份';

  @override
  String get set_bkAutoSub => '保留最近 5 份';

  @override
  String get set_bkKindImport => '导入前';

  @override
  String get set_bkKindReset => '恢复默认前';

  @override
  String get set_bkKindUpgrade => '升级前';

  @override
  String get set_bkNoBackups => '还没有自动备份';

  @override
  String set_bkRestoreTitle(Object name) {
    return '恢复到“$name”的备份？';
  }

  @override
  String get set_bkRestoreBody => '当前设置会先备份，之后可以再换回来。';

  @override
  String get set_abDesc => '版本、更新和问题诊断。';

  @override
  String set_abNew(Object version) {
    return '有新版本 $version';
  }

  @override
  String get set_abLatest => '已是最新版本';

  @override
  String get set_abChecking => '正在检查更新…';

  @override
  String get set_abCheckFailed => '检查更新失败';

  @override
  String set_abDownloading(Object pct) {
    return '正在下载 $pct';
  }

  @override
  String set_abChecked(Object when) {
    return '上次检查 $when';
  }

  @override
  String set_abNotes(Object version) {
    return '$version 更新内容';
  }

  @override
  String get set_abInstall => '下载并安装';

  @override
  String get set_abChangelog => '完整更新日志';

  @override
  String get set_abPrerelease => '包含预发布版本';

  @override
  String get set_abCheck => '检查更新';

  @override
  String get set_abDiag => '诊断';

  @override
  String get set_abLog => '写入日志文件';

  @override
  String get set_abLogSub => '排查问题时打开；日志不含 API Key 和登录凭据';

  @override
  String get set_abLogDir => '日志目录';

  @override
  String get set_abCopyDiag => '复制诊断信息';

  @override
  String get set_abCopyDiagSub => '版本、系统、显卡、各服务状态，方便反馈问题';

  @override
  String get set_abProject => '项目';

  @override
  String get set_abRepo => '开源项目';

  @override
  String get set_abUpstream => '原项目';

  @override
  String get set_abUpstreamSub => '本项目基于 NAI Launcher 开发，保留原作者署名';

  @override
  String get set_abFonts => '字体与素材';

  @override
  String get set_abLicenses => '许可证';

  @override
  String get set_abView => '查看';

  @override
  String get set_abSystem => '系统';

  @override
  String set_srQuoted(Object query) {
    return '“$query”';
  }

  @override
  String get set_srBalance => 'Anlas 余额';

  @override
  String get set_srSubscription => '订阅与 Anlas 额度';

  @override
  String get set_agEnable => '启用';

  @override
  String get set_agDisable => '停用';

  @override
  String get set_listSep => '、';

  @override
  String get set_on => '开';

  @override
  String get set_off => '关';

  @override
  String get set_unitSeconds => '秒';

  @override
  String get set_unsavedAgent => 'Agent 指令有未保存的修改';

  @override
  String get set_accUnread => '未读取';

  @override
  String get set_accBalanceUnread => '余额未读取';

  @override
  String get set_agBase => '内置系统提示词';

  @override
  String set_agBaseGlobalState(Object state) {
    return '全局：$state';
  }

  @override
  String set_agBaseWsState(Object name, Object state) {
    return '工作区「$name」：$state';
  }

  @override
  String get set_agBaseBuiltin => '内置';

  @override
  String get set_agBaseCustom => '已自定义';

  @override
  String get set_agBaseInherit => '沿用全局';

  @override
  String get set_agBaseOwn => '单独设置';

  @override
  String get set_agBaseEdit => '编辑';

  @override
  String get set_agBaseCollapse => '收起';

  @override
  String get set_agScopeGlobal => '全局';

  @override
  String set_agScopeWorkspace(Object name) {
    return '工作区 · $name';
  }

  @override
  String get set_agBaseUseGlobalOn => '这个工作区沿用全局提示词；关掉才能单独编辑';

  @override
  String get set_agBaseUseGlobalOff => '这个工作区使用单独的提示词；打开则改回沿用全局';

  @override
  String get set_agBaseHint =>
      '可用自定义内容替换内置系统提示词，拼在“内置提示词前”的内容之后；工具地图由应用追加。全局和工作区分开保存，已有聊天保持原样。';

  @override
  String get set_agBaseRestore => '恢复内置';

  @override
  String get set_agBaseRestoreTitle => '恢复内置系统提示词？';

  @override
  String get set_agBaseRestoreBody =>
      '全局自定义内容会换回内置系统提示词，旧内容存入提示词历史。各工作区单独的提示词不受影响。';

  @override
  String get set_agBaseSwitchTitle => '放弃内置系统提示词的修改？';

  @override
  String get set_agBaseSwitchBody => '切换范围会丢掉还没保存的修改。';

  @override
  String get set_agBaseSaving => '正在保存…';

  @override
  String get set_agBaseFailed => '没有保存：工作区已切换或写入失败，修改还在。';

  @override
  String get set_agMcpUnchecked => '未检测';

  @override
  String get set_agInstructionsSaving => '正在保存指令…';

  @override
  String get set_agInstructionsFailed => '指令未保存：内容已变化或写入失败。草稿已保留，请重试。';

  @override
  String get set_agOrderSkills => 'Skill 目录';

  @override
  String get set_agQuick => '快捷信息';

  @override
  String get set_agQuickSub => '侧栏欢迎页的快捷卡片。点卡片把内容填进输入框，也可以设成直接发送。';

  @override
  String set_agQuickShown(int shown, int total) {
    return '欢迎页显示 $shown / $total';
  }

  @override
  String get set_agQuickEmpty => '还没有快捷信息，欢迎页不显示这一块。';

  @override
  String get set_agQuickSendBadge => '直接发送';

  @override
  String get set_agQuickHidden => '不显示';

  @override
  String get set_agQuickUp => '上移';

  @override
  String get set_agQuickDown => '下移';

  @override
  String get set_agQuickEditOne => '编辑';

  @override
  String get set_agQuickRemove => '删除';

  @override
  String get set_agQuickAdd => '新增快捷信息';

  @override
  String get set_agQuickRestore => '恢复默认';

  @override
  String get set_agQuickRestoreConfirm => '恢复成内置的 4 条快捷信息？你新增和改过的会被替换。';

  @override
  String set_agQuickRemoveConfirm(String title) {
    return '删除快捷信息「$title」？';
  }

  @override
  String get set_agQuickNew => '新增快捷信息';

  @override
  String get set_agQuickEditTitle => '编辑快捷信息';

  @override
  String get set_agQuickIcon => '图标';

  @override
  String get set_agQuickTitle => '标题';

  @override
  String get set_agQuickHint => '说明（可不填）';

  @override
  String get set_agQuickPrompt => '发给 Agent 的内容';

  @override
  String get set_agQuickSend => '点击后直接发送（不勾选则填进输入框）';

  @override
  String get set_agSkills => 'Skill';

  @override
  String get set_agSkillsSub => '平时只把名称和一句话描述放进提示词；任务对得上时 Agent 才读取完整说明。';

  @override
  String set_agSkillsLoaded(Object n) {
    return '$n 个已加载';
  }

  @override
  String get set_agSkillBuiltin => '内置';

  @override
  String get set_agSkillGlobal => '全局';

  @override
  String get set_agSkillWorkspace => '工作区';

  @override
  String get set_agSkillAuto => '自动调用';

  @override
  String get set_agSkillManual => '仅手动调用';

  @override
  String get set_agSkillAutoTip => '提示词里只放名称和一句话描述，任务对得上时 Agent 会自己读取完整说明。';

  @override
  String get set_agSkillManualTip => '不进提示词，Agent 不会自己用；在聊天框输入 /skill:名称 才会调用。';

  @override
  String get set_agWorkspaceRulesSub =>
      '只对当前工作区生效的补充要求，存为工作区里的 instructions.md，排在全局指令之后；点“编辑”用系统编辑器打开，留空就不加。';

  @override
  String get set_agSkillDescNaiPrompt =>
      '按当前模型（V4／V4.5 或 V5）的规则，撰写或修改草稿里的 NovelAI 提示词：主提示词、负面、角色、积木与权重。改提示词前先读。';

  @override
  String get set_agSkillDescNaiStudio =>
      '操作 NAI Studio：草稿、图片、生成、语义搜索、图库／历史、参考图、积木、画风探索、图像工具、快照与偏好设置。除读取当前状态外，其他 Studio 操作前先读。';

  @override
  String get set_agSkillView => '查看';

  @override
  String get set_agSkillAdd => '添加 Skill 文件夹';

  @override
  String get set_agSkillNew => '新建 Skill';

  @override
  String get set_agSkillSlashHint => '聊天框输入 /skill:名称 手动调用';

  @override
  String get set_agSkillTrust => 'Skill 能指挥 Agent 读写文件和执行命令，请只添加可信来源。';

  @override
  String get set_agSkillNotLoaded => '未加载';

  @override
  String get set_agSkillShadowed => '已被同名 Skill 替代';

  @override
  String get set_agSkillErrDescription => 'SKILL.md 缺少 description，不会加载';

  @override
  String get set_agSkillErrName => '名称只能用小写字母、数字和单个连字符，最长 64 个字符';

  @override
  String get set_agSkillErrMissing => '文件夹里没有 SKILL.md';

  @override
  String get set_agSkillErrParse => '无法读取 SKILL.md 头部信息';

  @override
  String get set_agSkillOpenFolder => '打开文件夹';

  @override
  String get set_agSkillRemove => '删除 Skill';

  @override
  String get set_agSkillCopy => '复制为我的 Skill';

  @override
  String get set_agSkillReadOnly => '内置 Skill 随版本更新，不能直接编辑；复制后，同名的全局副本会替代它。';

  @override
  String get set_agSkillAddTitle => '添加 Skill 文件夹';

  @override
  String get set_agSkillPlace => '放到';

  @override
  String set_agSkillPlaceWorkspace(Object name) {
    return '当前工作区「$name」';
  }

  @override
  String get set_agSkillMode => '调用方式';

  @override
  String get set_agSkillCopyNote => '会复制进 Agent 数据目录，原文件夹之后的修改不会自动同步。';

  @override
  String set_agSkillExists(Object name) {
    return '「$name」已存在，请先删除或改名。';
  }

  @override
  String get set_agSkillPlaces => 'Skill 位置';

  @override
  String get set_agSkillPlacesTip => '每个子文件夹放一个 SKILL.md。同名时工作区优先，其次全局，最后内置。';

  @override
  String get set_agContext => '常驻上下文';

  @override
  String get set_agContextPrompt => '系统提示词';

  @override
  String set_agContextSkills(Object n) {
    return 'Skill 目录 · $n 项';
  }

  @override
  String set_agContextTools(Object n) {
    return '默认工具 $n 个';
  }

  @override
  String get set_agContextTip => 'tokens · 按字符估算';

  @override
  String get set_agFinalPending =>
      '当前没有运行中的会话。以下是 Studio 组装的部分；会话启动时 Pi 还会追加 Skill 目录、工作目录和 MCP 服务列表。';

  @override
  String get ag_tabChat => '对话';

  @override
  String get ag_tabShelf => '产物';

  @override
  String get ag_tabMemory => '指令';

  @override
  String get ag_newChat => '新聊天';

  @override
  String get ag_more => '更多';

  @override
  String get ag_close => '收起';

  @override
  String get ag_chatsSearch => '搜索聊天和工作区';

  @override
  String get ag_chatsSwitchWorkspace => '切换工作区';

  @override
  String get ag_chatsNewWorkspace => '新建工作区';

  @override
  String get ag_chatsNoMatch => '没有匹配的聊天';

  @override
  String get ag_chatWaiting => '等确认';

  @override
  String get ag_chatRunning => '进行中';

  @override
  String get ag_menuRenameChat => '重命名聊天';

  @override
  String get ag_menuRenameWorkspace => '重命名工作区';

  @override
  String get ag_menuOpenFolder => '打开工作区文件夹';

  @override
  String get ag_menuCompact => '压缩上下文';

  @override
  String get ag_menuExport => '导出聊天';

  @override
  String get ag_menuSettings => 'Agent 设置';

  @override
  String get ag_name => '名称';

  @override
  String get ag_save => '保存';

  @override
  String get ag_cancel => '取消';

  @override
  String get ag_failed => '操作没有完成';

  @override
  String get ag_greetMorning => '上午好，今天画什么？';

  @override
  String get ag_greetAfternoon => '下午好，今天画什么？';

  @override
  String get ag_greetEvening => '晚上好，今天画什么？';

  @override
  String get ag_greetHint => 'Agent 会先看草稿再动手；花 Anlas 前一定先问你。';

  @override
  String get ag_draftEyebrow => '当前草稿';

  @override
  String ag_draftCounts(int characters, int blocks, int references) {
    return '角色 $characters · $blocks 个积木 · 参考图 $references';
  }

  @override
  String get ag_taskReview => '检查草稿';

  @override
  String get ag_taskReviewHint => '找冲突、冗余和模型不认的写法';

  @override
  String get ag_taskReviewPrompt => '检查当前草稿和参数，找出冲突、冗余和当前模型不认的写法，先不要修改。';

  @override
  String get ag_taskAnalyze => '分析参考图';

  @override
  String get ag_taskAnalyzeHint => '拆出画风、构图和可用标签';

  @override
  String get ag_taskAnalyzePrompt => '分析我附上的参考图：画风、构图、光影，以及能直接用的标签，先不要生成。';

  @override
  String get ag_taskVariants => '批量变体';

  @override
  String get ag_taskVariantsHint => '改一处，出几张对比';

  @override
  String get ag_taskVariantsPrompt =>
      '基于当前草稿，只改一个方向做几组变体对比。先告诉我打算怎么改和费用，等我确认再生成。';

  @override
  String get ag_taskBlocks => '整理积木';

  @override
  String get ag_taskBlocksHint => '把常用片段收进积木库';

  @override
  String get ag_taskBlocksPrompt => '看看当前草稿里哪些片段适合做成可复用的积木，列出建议，先不要修改。';

  @override
  String get ag_quickTitle => '快捷信息';

  @override
  String get ag_quickEdit => '编辑快捷信息';

  @override
  String get ag_quickSends => '点击直接发送';

  @override
  String get ag_modeBypass => '完全权限';

  @override
  String get ag_modeBypassHint => '不再询问，所有操作直接执行；花 Anlas 仍要确认';

  @override
  String get ag_bypassConfirmTitle => '切换到完全权限？';

  @override
  String get ag_bypassConfirmBody =>
      'Agent 将不再询问，直接修改文件、运行命令、调用未知工具，也能操作工作区以外的文件。花 Anlas 的操作仍会先请你确认。只在你信任当前任务时使用。';

  @override
  String get ag_bypassConfirmOk => '切换';

  @override
  String get ag_bypassConfirmSilence => '不再提醒';

  @override
  String get ag_menuDeleteChat => '删除对话';

  @override
  String get ag_menuDeleteWorkspace => '删除工作区';

  @override
  String get ag_delete => '删除';

  @override
  String get ag_deleteWorkspaceTitle => '删除工作区？';

  @override
  String ag_deleteWorkspaceBody(String name) {
    return '工作区「$name」和里面的全部对话会移进回收区，可以撤销。生成的图片仍保留在图库和历史中。';
  }

  @override
  String ag_chatDeleted(String title) {
    return '已删除「$title」';
  }

  @override
  String ag_workspaceDeleted(String name) {
    return '已删除工作区「$name」';
  }

  @override
  String get ag_chatsContent => '内容匹配';

  @override
  String get ag_chatsSearching => '正在搜索对话内容…';

  @override
  String get ag_imageVibe => '设为 Vibe';

  @override
  String get ag_imageReference => '设为精确参考';

  @override
  String get ag_imageParams => '载入参数';

  @override
  String get ag_imageFolder => '在文件夹中显示';

  @override
  String get ag_imageVibeDone => '已加入 Vibe 参考';

  @override
  String get ag_imageReferenceDone => '已设为精确参考';

  @override
  String get ag_imageParamsDone => '已载入生成参数';

  @override
  String get ag_usageAnlas => '生图花费（估算）';

  @override
  String get ag_deleteAgain => '再点一次删除';

  @override
  String get ag_sloganBase =>
      '研磨颜料中…\n翻翻画师册…\n数一数 tag…\n斟酌权重中…\n对一下构图…\n给角色摆个姿势…\n削铅笔中…\n调一调色温…\n挑一支合适的笔刷…\n往调色盘里挤颜料…\n退后两步看看整体…\n铺一层底色…\n把灵感捋一捋…\n找找参考…\n量一量比例…\n换个视角想想…\n把线条理顺…\n抿一口咖啡…\n和光影商量一下…\n在草稿纸上比划…';

  @override
  String get ag_sloganEgg =>
      '正在说服 AI 把手画对…\n偷偷多画了一根手指…又擦掉了\nAnlas 一分没花（暂时）\n在画布角落签了个名…不行，擦掉\n和 Krita 交换眼神中…\n给猫耳找个好角度…\n数到第六根手指时停了下来…\nmasterpiece, best quality, 拜托了…';

  @override
  String get ag_sloganThink => '琢磨中…\n先在脑子里画一遍…\n换个角度想想…\n理一理思路…';

  @override
  String get ag_sloganRead => '翻资料中…\n查一查 tag 词典…\n看看草稿写了什么…\n翻翻旧作…';

  @override
  String get ag_sloganRun => '敲命令中…\n让终端跑一会儿…\n等脚本跑完…';

  @override
  String get ag_sloganImage => '盯着图看…\n端详细节中…\n数数有几个角色…\n凑近看看笔触…';

  @override
  String get ag_sloganWrite => '落笔中…\n改提示词中…\n擦掉重写一笔…\n调一调权重…';

  @override
  String get ag_sloganGen => '上色中…\n等显卡吃饭…\n颜料还没干…\n烘干画布中…';

  @override
  String get ag_sloganExternal => '和外部工具对暗号…\n等外面回话…';

  @override
  String get ag_foldDone => '已处理';

  @override
  String ag_foldTimes(String label, int count) {
    return '$label $count 次';
  }

  @override
  String get ag_kindThink => '思考';

  @override
  String get ag_kindRead => '读取';

  @override
  String get ag_kindRun => '运行命令';

  @override
  String get ag_kindImage => '看图';

  @override
  String get ag_kindWrite => '修改';

  @override
  String get ag_kindGen => '生图';

  @override
  String get ag_kindExternal => '外部工具';

  @override
  String get ag_kindAsk => '问你';

  @override
  String ag_limitTitle(int count) {
    return '已达到单次任务步数上限（$count 步）';
  }

  @override
  String get ag_limitBody => '进度已保存，点“继续”接着做。上限可以在设置里调整。';

  @override
  String get ag_limitContinue => '继续';

  @override
  String get ag_limitAdjust => '调整上限';

  @override
  String get ag_continueMessage => '继续';

  @override
  String get ag_diffExpand => '展开全部';

  @override
  String get ag_diffCollapse => '收起';

  @override
  String ag_readImages(int count) {
    return '查看图片 · $count 张';
  }

  @override
  String ag_turnTook(String time) {
    return '用时 $time';
  }

  @override
  String ag_turnAnlas(String anlas) {
    return '$anlas Anlas';
  }

  @override
  String ag_turnChanges(int count) {
    return '改动 $count 处';
  }

  @override
  String ag_turnTools(int count) {
    return '工具 $count 次';
  }

  @override
  String ag_turnTokens(String input, String output) {
    return '输入 $input · 输出 $output token';
  }

  @override
  String get ag_settingsTitle => '应用设置';

  @override
  String get ag_settingsGo => '去设置';

  @override
  String ag_tagCopied(String tag) {
    return '已复制 $tag';
  }

  @override
  String ag_tagCount(String count) {
    return '$count 张作品';
  }

  @override
  String ag_galleryFavorite(int count) {
    return '已收藏 $count 张';
  }

  @override
  String ag_galleryUnfavorite(int count) {
    return '已取消收藏 $count 张';
  }

  @override
  String ag_galleryTags(int count) {
    return '已改标签 $count 张';
  }

  @override
  String ag_galleryMove(int count, String target) {
    return '已移动 $count 张到「$target」';
  }

  @override
  String ag_galleryCopy(int count, String target) {
    return '已复制 $count 张到「$target」';
  }

  @override
  String ag_galleryDelete(int count) {
    return '已移到回收区 $count 张';
  }

  @override
  String ag_galleryRestore(int count) {
    return '已恢复 $count 张';
  }

  @override
  String ag_galleryCollectionAdd(int count, String target) {
    return '已加入集合「$target」$count 张';
  }

  @override
  String ag_galleryCollectionRemove(int count, String target) {
    return '已移出集合「$target」$count 张';
  }

  @override
  String ag_galleryExport(int count) {
    return '已导出 $count 张';
  }

  @override
  String ag_galleryMore(int count) {
    return '+$count';
  }

  @override
  String get ag_compacted => '之前的对话已压缩';

  @override
  String get ag_compactedAuto => '上下文快满了，之前的对话已自动压缩';

  @override
  String ag_compactedTokens(String tokens) {
    return '原 $tokens token';
  }

  @override
  String get ag_compactedShow => '看摘要';

  @override
  String get ag_compactedHide => '收起摘要';

  @override
  String get ag_editResend => '发送';

  @override
  String get ag_editHint => '发送后，这条之后的对话会被替换';

  @override
  String get ag_editRemoveImage => '去掉这张图';

  @override
  String get set_agTrash => '回收区';

  @override
  String get set_agTrashSub => '删除的对话、工作区和 Skill 先放进回收区，可以恢复；彻底删除后不能找回。';

  @override
  String get set_agTrashManage => '管理';

  @override
  String set_agTrashSummary(int count, String size) {
    return '$count 项 · $size';
  }

  @override
  String get set_agTrashEmpty => '回收区是空的';

  @override
  String get set_agTrashAll => '全部';

  @override
  String get set_agTrashChats => '对话';

  @override
  String get set_agTrashWorkspaces => '工作区';

  @override
  String get set_agTrashSkills => 'Skill';

  @override
  String get set_agTrashRestore => '恢复';

  @override
  String get set_agTrashPurge => '彻底删除';

  @override
  String get set_agTrashPurgeAll => '清空回收区';

  @override
  String get set_agTrashPurgeTitle => '彻底删除？';

  @override
  String set_agTrashPurgeBody(String name) {
    return '「$name」会从磁盘上删除，不能找回。';
  }

  @override
  String set_agTrashPurgeAllBody(int count) {
    return '回收区里的 $count 项会从磁盘上删除，不能找回。';
  }

  @override
  String set_agTrashRestored(String name) {
    return '已恢复「$name」';
  }

  @override
  String set_agTrashPurged(String name) {
    return '已彻底删除「$name」';
  }

  @override
  String get set_agTrashNeedWorkspace => '所属工作区也在回收区里，先恢复工作区';

  @override
  String get set_agTrashRestoreFailed => '恢复失败：原位置已有同名内容';

  @override
  String get set_agTrashGoneWorkspace => '已删除的工作区';

  @override
  String set_agSkillRemoveBody(String name) {
    return '「$name」会移进回收区，之后可以在 Agent 设置的「回收区」里恢复或彻底删除。';
  }

  @override
  String get set_agSkillName => '名称';

  @override
  String get set_agSkillNewHelp =>
      '只用小写字母、数字和连字符，例如 watercolor-style。建好后会打开它的文件夹，编辑里面的 SKILL.md 即可。';

  @override
  String get set_agSkillCreate => '创建';

  @override
  String get set_agSkillAddConfirm => '添加';

  @override
  String set_agPromptStats(String chars, String tokens) {
    return '$chars 字符 · 约 $tokens token';
  }

  @override
  String get set_agFinalLive => '当前会话实际发给模型的完整系统提示词。';

  @override
  String get set_agBuiltinSub => 'Studio 内置的基础提示词，随版本更新。';

  @override
  String get set_agMcpEditTitle => '编辑 MCP 服务器';

  @override
  String get set_agTabGeneral => '常规';

  @override
  String get set_agTabTools => '工具与扩展';

  @override
  String get blocks_viewMasonry => '瀑布流';

  @override
  String get blocks_groupByFolder => '按文件夹分组';

  @override
  String get mp_bodyTag => '请求体';

  @override
  String get mp_headerTag => '请求头';

  @override
  String get ag_recent => '最近';

  @override
  String get ag_you => '你';

  @override
  String get ag_edit => '编辑';

  @override
  String get ag_copy => '复制';

  @override
  String get ag_copied => '已复制';

  @override
  String get ag_regenerate => '重新回答';

  @override
  String get ag_starting => '正在打开聊天';

  @override
  String get ag_waitingSlot => '等服务商额度';

  @override
  String get ag_waitingYou => '等你处理';

  @override
  String get ag_stepFailed => '失败';

  @override
  String get ag_stepArguments => '参数';

  @override
  String get ag_stepResult => '结果';

  @override
  String ag_stepsMore(int count) {
    return '还有 $count 步';
  }

  @override
  String get ag_tool_studio_context => '读取当前草稿';

  @override
  String get ag_tool_image_read => '查看图片';

  @override
  String get ag_tool_prompt_update => '改写提示词';

  @override
  String get ag_tool_snapshot => '草稿快照';

  @override
  String get ag_tool_wiki_query => '查百科';

  @override
  String get ag_tool_tag_query => '查标签';

  @override
  String get ag_tool_block_query => '查积木';

  @override
  String get ag_tool_block_manage => '整理积木';

  @override
  String get ag_tool_settings_read => '读取设置';

  @override
  String get ag_tool_settings_update => '修改设置';

  @override
  String get ag_tool_explore_manage => '画风探索';

  @override
  String get ag_tool_generation_prepare => '准备生成';

  @override
  String get ag_tool_generation_run => '生成图片';

  @override
  String get ag_tool_generation_cancel => '取消生成';

  @override
  String get ag_tool_gallery_query => '查图库';

  @override
  String get ag_tool_gallery_manage => '整理图库';

  @override
  String get ag_tool_reference_manage => '设置参考图';

  @override
  String get ag_tool_reference_library => '参考图库';

  @override
  String get ag_tool_image_tool => '图像工具';

  @override
  String get ag_tool_studio_search => '语义搜索';

  @override
  String get ag_tool_image_generate => '变体 / 增强';

  @override
  String get ag_tool_ask_user => '向你提问';

  @override
  String get ag_tool_read => '读文件';

  @override
  String get ag_tool_write => '写文件';

  @override
  String get ag_tool_edit => '改文件';

  @override
  String get ag_tool_bash => '运行命令';

  @override
  String get ag_field_prompt => '基础提示词';

  @override
  String get ag_field_negative => '负面提示词';

  @override
  String get ag_field_character => '角色提示词';

  @override
  String get ag_field_characterNegative => '角色负面';

  @override
  String get ag_diffApplied => '已写入';

  @override
  String get ag_diffUndone => '已撤销';

  @override
  String ag_changeSummary(int count) {
    return '本次改动 · $count 处';
  }

  @override
  String get ag_diffUndoAll => '全部撤销';

  @override
  String get ag_paramTitle => '生图参数';

  @override
  String ag_paramCount(int count) {
    return '$count 项';
  }

  @override
  String get ag_paramSize => '尺寸';

  @override
  String get ag_paramTransparent => '透明背景';

  @override
  String get ag_paramNone => '无';

  @override
  String get ag_positionTitle => '角色位置';

  @override
  String get ag_positionApplied => '已调整';

  @override
  String get ag_positionNone => '未定位';

  @override
  String get ag_positionAiHint => '当前为 AI 选择，坐标不生效，由模型自行安排位置。';

  @override
  String ag_positionRestSame(int count) {
    return '其余 $count 人位置未变';
  }

  @override
  String ag_positionAllSame(int count) {
    return '$count 人位置未变';
  }

  @override
  String get ag_posTopLeft => '左上';

  @override
  String get ag_posTop => '中上';

  @override
  String get ag_posTopRight => '右上';

  @override
  String get ag_posLeft => '左中';

  @override
  String get ag_posCenter => '正中';

  @override
  String get ag_posRight => '右中';

  @override
  String get ag_posBottomLeft => '左下';

  @override
  String get ag_posBottom => '中下';

  @override
  String get ag_posBottomRight => '右下';

  @override
  String get ag_positionNudge => '微调';

  @override
  String get ag_positionNew => '新增';

  @override
  String get ag_diffLocked => '草稿已再次修改';

  @override
  String get ag_diffUndo => '撤销';

  @override
  String ag_diffCounts(int added, int removed) {
    return '+$added −$removed';
  }

  @override
  String get ag_outputs => '本次产物';

  @override
  String ag_anlasSpent(String anlas) {
    return '已用 $anlas Anlas';
  }

  @override
  String get ag_imageReveal => '在历史中显示';

  @override
  String get ag_imageAttach => '附到输入框';

  @override
  String get ag_imageZoom => '放大查看';

  @override
  String ag_askHint(int count) {
    return '按 1–$count';
  }

  @override
  String get ag_askOther => '其他想法…';

  @override
  String get ag_askSubmit => '回答';

  @override
  String get ag_askSkip => '跳过';

  @override
  String ag_approvalTitle(String tool) {
    return '需要你允许 · $tool';
  }

  @override
  String ag_gateTitle(String action) {
    return '需要你确认 · $action';
  }

  @override
  String ag_gateText2img(int count) {
    return '生成 $count 张';
  }

  @override
  String ag_gateImg2img(int count) {
    return '图生图 $count 张';
  }

  @override
  String ag_gateInpaint(int count) {
    return '重绘 $count 张';
  }

  @override
  String ag_gateVariations(int count) {
    return '变体 $count 张';
  }

  @override
  String get ag_gateEnhance => '增强';

  @override
  String get ag_gateModelSize => '模型 · 尺寸';

  @override
  String get ag_gateRequests => '请求';

  @override
  String ag_gateRequestsValue(int requests, int batch) {
    return '$requests 次 × $batch 张';
  }

  @override
  String get ag_gateUnit => '单价';

  @override
  String get ag_gateEncoding => '参考图编码';

  @override
  String get ag_gateAccount => '账号';

  @override
  String ag_gateTotal(String balance) {
    return '合计 · 余额 $balance';
  }

  @override
  String get ag_gateTotalNoBalance => '合计';

  @override
  String get ag_gateConfirm => '确认并生成';

  @override
  String get ag_gateConfirmTool => '确认并执行';

  @override
  String get ag_gateChanged => '配置或报价已变化，请让 Agent 重新准备';

  @override
  String get ag_gateExpired => '报价已失效';

  @override
  String get ag_gateEstimate => '预估，以服务端扣费为准';

  @override
  String get ag_placeholder => '告诉 Agent 要做什么 · @ 引用 · / 技能';

  @override
  String get ag_dropHint => '松开以附加到这条消息';

  @override
  String ag_importing(int count) {
    return '正在添加 $count 张图片…';
  }

  @override
  String get ag_attach => '添加图片';

  @override
  String get ag_attachFile => '从文件选择…';

  @override
  String get ag_attachCanvas => '附上画布当前图片';

  @override
  String get ag_attachPaste => '粘贴剪贴板图片';

  @override
  String get ag_mention => '引用';

  @override
  String get ag_attachmentRemove => '移除';

  @override
  String get ag_attachmentBroken => '读取失败';

  @override
  String ag_imageInfoSteps(int count) {
    return '$count 步';
  }

  @override
  String ag_imageInfoRescale(String value) {
    return '重缩放 $value';
  }

  @override
  String ag_imageInfoSeed(String seed) {
    return '种子 $seed';
  }

  @override
  String ag_imageInfoCharacters(int count) {
    return '$count 个角色';
  }

  @override
  String get ag_send => '发送';

  @override
  String get ag_sendQueue => '排队发送';

  @override
  String get ag_sendSteer => '作为引导插入';

  @override
  String get ag_sendQueueHint => '等当前任务做完再处理';

  @override
  String get ag_sendSteerHint => '在下一次模型请求前插入';

  @override
  String get ag_stop => '停止';

  @override
  String get ag_noModel => '先选一个能用工具的模型';

  @override
  String get ag_queued => '排队';

  @override
  String get ag_steering => '引导';

  @override
  String get ag_recovered => '上次没发出';

  @override
  String get ag_queueSteer => '转引导';

  @override
  String get ag_queueEdit => '编辑';

  @override
  String get ag_queueWithdraw => '撤回';

  @override
  String get ag_queueRestore => '放回输入框';

  @override
  String get ag_newContent => '回到最新';

  @override
  String get ag_modeReadonly => '只读';

  @override
  String get ag_modeAsk => '询问';

  @override
  String get ag_modeAuto => '自动';

  @override
  String get ag_modeReadonlyHint => '只读取和讨论；不修改、不生成';

  @override
  String get ag_modeAskHint => '修改、命令和未知工具先问你';

  @override
  String get ag_modeAutoHint => '工作区内的常规修改直接执行；花钱仍要确认';

  @override
  String get ag_modelPicker => '选择模型';

  @override
  String get ag_modelSettings => '管理模型与接口…';

  @override
  String get ag_modelNone => '未选择模型';

  @override
  String get ag_thinkingTitle => '思考强度 · 下次任务生效';

  @override
  String get ag_thinkingFollow => '使用模型设置';

  @override
  String get ag_thinkingUnsupported => '这个模型没有可调的思考档位';

  @override
  String get ag_usageTitle => '上下文与用量';

  @override
  String get ag_usageContext => '当前上下文 · 估算';

  @override
  String get ag_usageUnknown => '等模型返回用量后显示';

  @override
  String ag_usageRemaining(String tokens) {
    return '剩余 $tokens';
  }

  @override
  String get ag_usageSession => '本聊天累计';

  @override
  String get ag_usageInput => '输入';

  @override
  String get ag_usageOutput => '输出';

  @override
  String get ag_usageCacheRead => '缓存读取';

  @override
  String get ag_usageCacheWrite => '缓存写入';

  @override
  String get ag_usageTotal => '累计 tokens';

  @override
  String get ag_usageMessages => '消息 · 工具调用';

  @override
  String get ag_usageCost => '费用以服务商账单为准';

  @override
  String get ag_usageCompact => '压缩上下文';

  @override
  String ag_shelfAll(int count) {
    return '全部 $count';
  }

  @override
  String ag_shelfGenerated(int count) {
    return '生成 $count';
  }

  @override
  String ag_shelfAttachments(int count) {
    return '附件 $count';
  }

  @override
  String ag_shelfFiles(int count) {
    return '文件 $count';
  }

  @override
  String get ag_shelfFilesTitle => '文件';

  @override
  String get ag_shelfHint => '点图放大 · 拖到画布';

  @override
  String get ag_shelfEmpty => '这个聊天还没有产物';

  @override
  String get ag_shelfEmptyHint => 'Agent 生成的图、你附上的图和它写的文件都会收在这里。';

  @override
  String get ag_memoryGlobal => '全局指令';

  @override
  String get ag_memoryWorkspace => '本工作区规则';

  @override
  String get ag_memorySkills => '生效的 Skill';

  @override
  String get ag_memoryEmpty => '还没写';

  @override
  String get ag_memoryEdit => '编辑';

  @override
  String get ag_memoryHint => '这些内容每次都会交给 Agent。改动从下一条消息开始生效。';

  @override
  String get ag_mentionAll => '全部';

  @override
  String get ag_mentionDraft => '草稿';

  @override
  String get ag_mentionImages => '图片';

  @override
  String get ag_mentionBlocks => '积木';

  @override
  String get ag_mentionTitle => '引用到这条消息';

  @override
  String get ag_mentionEmpty => '没有匹配的内容';

  @override
  String get ag_mentionSearchBlocks => '搜索积木';

  @override
  String get ag_keySelect => '选择';

  @override
  String get ag_keyInsert => '插入';

  @override
  String get ag_keyCategory => '切类别';

  @override
  String get ag_keyClose => '关闭';

  @override
  String get ag_dismiss => '知道了';

  @override
  String get ag_retry => '重试';

  @override
  String get ag_initFailed => 'Agent 没能启动';

  @override
  String get ag_toggle => 'NAI Agent';

  @override
  String get ag_yesterday => '昨天';

  @override
  String get ag_attachmentTag => '附件';

  @override
  String get ag_zoomClose => '关闭';

  @override
  String get ag_thought => '已思考';

  @override
  String get ag_thinkingLive => '思考中';

  @override
  String ag_thoughtChars(int count) {
    return '$count 字';
  }

  @override
  String get mp_protocol => '接口协议';

  @override
  String get mp_test => '测试';

  @override
  String get mp_testing => '测试中…';

  @override
  String get mp_notChecked => '未检测';

  @override
  String get mp_rename => '重命名';

  @override
  String get mp_request => '请求';

  @override
  String get mp_requestSub => '所有模型共用';

  @override
  String get mp_timeout => '请求超时';

  @override
  String get mp_timeoutHelp => '单次请求最长等待时间，10–600 秒';

  @override
  String get mp_concurrency => '最大并发';

  @override
  String get mp_concurrencyHelp => '此服务同时处理的请求数，1–20';

  @override
  String get mp_retry => '失败重试';

  @override
  String get mp_retryHelp => '连接失败或服务繁忙时重试';

  @override
  String get mp_retryOff => '关';

  @override
  String get mp_seconds => '秒';

  @override
  String get mp_countUnit => '个';

  @override
  String get mp_headers => '自定义请求头';

  @override
  String get mp_none => '无';

  @override
  String get mp_addHeader => '添加请求头';

  @override
  String get mp_headerName => '名称';

  @override
  String get mp_value => '值';

  @override
  String get mp_added => '已添加';

  @override
  String get mp_catalog => '服务商目录';

  @override
  String get mp_filter => '筛选';

  @override
  String get mp_manualAdd => '手动添加';

  @override
  String get mp_dragHint => '拖动排序决定功能分配里的默认顺序';

  @override
  String get mp_noModels => '还没有模型';

  @override
  String get mp_noModelsSub => '从服务商目录添加，或手动输入模型 ID';

  @override
  String get mp_manualHint => '输入模型 ID，回车添加';

  @override
  String get mp_model => '模型';

  @override
  String get mp_alias => '显示别名';

  @override
  String get mp_aliasHint => '例如 fast';

  @override
  String get mp_context => '上下文窗口';

  @override
  String get mp_maxOutput => '最大输出';

  @override
  String get mp_outputTooLarge => '输出不能超过上下文窗口';

  @override
  String get mp_thinking => '思考';

  @override
  String get mp_levels => '可调档位';

  @override
  String get mp_defaultLevel => '默认档位';

  @override
  String get mp_defaultBadge => '默认';

  @override
  String get mp_followService => '跟随服务';

  @override
  String get mp_reasoningProtocol => '思考协议';

  @override
  String get mp_standard => '标准';

  @override
  String get mp_adaptive => '自适应';

  @override
  String get mp_protocolNoReasoning => '此接口协议不支持思考调节';

  @override
  String get mp_unconfirmed => '未确认';

  @override
  String get mp_unsupported => '不支持';

  @override
  String get mp_capabilities => '能力';

  @override
  String get mp_capVision => '图片输入';

  @override
  String get mp_capTools => '工具调用';

  @override
  String get mp_capSearch => '原生联网搜索';

  @override
  String get mp_bodyHeaders => '请求体与请求头';

  @override
  String get mp_notAdded => '未添加';

  @override
  String get mp_field => '请求体';

  @override
  String get mp_header => '请求头';

  @override
  String get mp_testModel => '测试此模型';

  @override
  String get mp_copyId => '复制模型 ID';

  @override
  String get mp_removeModel => '移除模型';

  @override
  String mp_removeTitle(Object id) {
    return '移除模型“$id”？';
  }

  @override
  String get mp_removeBody => '用到它的功能会回落到其他可用模型。';

  @override
  String get mp_catalogId => '模型 ID';

  @override
  String get mp_catalogCtx => '上下文';

  @override
  String get mp_catalogPrice => '输入 / 输出 · 百万';

  @override
  String mp_catalogFooter(Object n, Object total, Object when) {
    return '匹配 $n 个 · 共 $total 个 · $when 获取';
  }

  @override
  String mp_catalogMore(Object n) {
    return '还有 $n 个，输入筛选缩小范围';
  }

  @override
  String get mp_catalogIdle => '还没读取过目录';

  @override
  String get mp_catalogIdleSub => '用已保存的地址和 Key 读取这个服务商提供的模型';

  @override
  String get mp_catalogLoading => '正在读取模型目录…';

  @override
  String mp_catalogFailed(Object error) {
    return '目录不可用：$error';
  }

  @override
  String get mp_fetch => '获取列表';

  @override
  String get mp_noMatch => '没有匹配的模型';

  @override
  String mp_picked(Object n) {
    return '已选 $n 个';
  }

  @override
  String get mp_pickEmpty => '在左边勾选要添加的模型';

  @override
  String get mp_pickHint => '能力、上下文和思考档位按本地目录预填，添加后可在右侧逐项调整。';

  @override
  String mp_addPicked(Object n) {
    return '添加 $n 个模型';
  }

  @override
  String get mp_new => '新';

  @override
  String mp_unsaved(Object name, Object n) {
    return '$name 有 $n 项修改未保存';
  }

  @override
  String get mp_saving => '正在保存…';

  @override
  String get mp_conflict => '配置已在别处修改：已合并最新值，确认后再保存';

  @override
  String get mp_saveFailed => '保存失败，修改已保留';

  @override
  String mp_invalid(Object n) {
    return '有 $n 处需要修正';
  }

  @override
  String get mp_leaveBody => '服务商配置还没保存，离开这一页会丢掉修改。';

  @override
  String get mp_show => '显示';

  @override
  String get mp_hide => '隐藏';

  @override
  String get mp_keyHintLocal => '本机服务可留空';

  @override
  String get mp_keyHint => '输入此服务商的 Key';

  @override
  String get mp_pickerTitle => '添加服务商';

  @override
  String get mp_pickerSearch => '搜索厂商、平台或本地服务';

  @override
  String get mp_groupAll => '全部';

  @override
  String get mp_groupDomestic => '国内';

  @override
  String get mp_groupInternational => '国际';

  @override
  String get mp_groupAggregator => '聚合';

  @override
  String get mp_groupLocal => '本地';

  @override
  String get mp_groupDomesticFull => '国内厂商';

  @override
  String get mp_groupInternationalFull => '国际厂商';

  @override
  String get mp_groupAggregatorFull => '聚合平台';

  @override
  String get mp_groupLocalFull => '本地与自定义';

  @override
  String get mp_pickerFoot => '地址与协议会按预设填好；同一厂商可以添加多次（例如国内 / 国际区域）。';

  @override
  String get mp_pickerNext => '下一步：填写 Key';

  @override
  String get mp_duplicateKey => '请求字段名称重复。';

  @override
  String get mp_retryRange => '失败重试次数必须为 0–3 次。';

  @override
  String get mp_catalogCacheFailed => '无法保存模型目录缓存。';

  @override
  String get mp_errorAuthentication => 'API Key 无效';

  @override
  String get mp_errorPermission => '无访问权限';

  @override
  String get mp_errorTimeout => '请求超时';

  @override
  String get mp_errorNetwork => '连接不可用';

  @override
  String get mp_errorResponse => '响应无效';

  @override
  String get mp_errorHttp => '请求失败';

  @override
  String get mp_errorRateLimit => '请求过于频繁';

  @override
  String get ag_tool_prompt_set => '提示词组';

  @override
  String ag_psCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String ag_psPosition(int index, int count, String unit) {
    return '第 $index $unit / 共 $count $unit';
  }

  @override
  String get ag_psOverview => '总览全部';

  @override
  String get ag_psSingle => '回到单项';

  @override
  String get ag_psPrompt => '提示词';

  @override
  String get ag_psShared => '共同设定';

  @override
  String ag_psThisItem(String unit) {
    return '这一$unit';
  }

  @override
  String get ag_psMain => '主提示词';

  @override
  String ag_psCharacter(int index) {
    return '角色 $index';
  }

  @override
  String get ag_psNegative => '负面';

  @override
  String get ag_psImport => '导入画布';

  @override
  String get ag_psImportTip => '写入主提示词、角色和负面；参数和参考图不变';

  @override
  String ag_psImported(String title) {
    return '已把「$title」写入提示词';
  }

  @override
  String get ag_psGenerate => '生成';

  @override
  String get ag_psGenerating => '生成中';

  @override
  String ag_psRevision(int revision, int count) {
    return 'v$revision · 已改 $count 项';
  }

  @override
  String get ag_psSaveBlock => '存成积木';

  @override
  String ag_psSavedBlock(String title, int count) {
    return '已存成积木「$title」· $count 项';
  }

  @override
  String ag_psCopyItem(String unit) {
    return '复制这一$unit的提示词';
  }

  @override
  String get ag_psCopyAll => '复制全部';

  @override
  String ag_psEditItem(String unit) {
    return '让 Agent 修改这一$unit';
  }

  @override
  String ag_psEditDraft(String title, int index, String unit, String item) {
    return '修改「$title」第 $index $unit（$item）：';
  }

  @override
  String ag_psTooManyCharacters(int count) {
    return '当前模型最多支持 $count 个角色';
  }

  @override
  String get ag_psNoCharacters => '当前模型不支持角色提示词';

  @override
  String get ag_psMissing => '这张卡的数据已不在';

  @override
  String get startup_dataTitle => '无法准备应用数据';

  @override
  String get startup_dataHelp =>
      '应用数据尚未准备完成，请保留现有文件。内容不同的文件不会合并或覆盖。请先备份并核对数据目录，检查磁盘空间和访问权限，再重试。';

  @override
  String get startup_dataCurrent => '当前数据目录';

  @override
  String get startup_dataLegacy => '旧数据目录';

  @override
  String get startup_dataOpenCurrent => '打开当前目录';

  @override
  String get startup_dataOpenLegacy => '打开旧目录';

  @override
  String get startup_dataDetails => '错误详情';

  @override
  String startup_dataActionFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get blocks_expandToText => '展开为文本';

  @override
  String get ag_answeredTitle => '向你提问 · 已回答';

  @override
  String get ag_historyButton => '历史';

  @override
  String get ag_historyTitle => '对话历史';

  @override
  String get ag_historySearch => '搜索发言和卡片…';

  @override
  String get ag_historyAll => '全部';

  @override
  String get ag_historyMine => '我的发言';

  @override
  String get ag_historyCards => '卡片';

  @override
  String get ag_historyQuestions => '问答';

  @override
  String get ag_historyEmpty => '没有匹配的条目';

  @override
  String get ag_historyBeforeCompaction => '这段在压缩之前，点看摘要';

  @override
  String get ag_historyAuto => '自动压缩';

  @override
  String get ag_historyManual => '手动压缩';

  @override
  String get ag_historyImageMessage => '图片消息';

  @override
  String ag_historyAnswer(String answer) {
    return '你选了：$answer';
  }

  @override
  String get ag_historyPromptSet => '提示词组';

  @override
  String ag_historyImages(int count) {
    return '生成卡 · $count 张';
  }

  @override
  String get ag_historyPromptChange => '提示词修改';

  @override
  String get ag_historyParams => '生成参数';

  @override
  String get ag_historyPositions => '角色位置';

  @override
  String get ag_historySettings => '设置修改';

  @override
  String get ag_historyGallery => '图库卡片';

  @override
  String get ag_historyChanges => '修改摘要';

  @override
  String get gen_translateTapOriginal => '点按：显示原文';

  @override
  String get gen_translateTapTranslated => '点按：显示译文';

  @override
  String get gen_translateClearRestore => '清除翻译块并还原';

  @override
  String get gen_translateClearRestoreSub => '全部变回普通原文，可撤销';

  @override
  String get gen_translateCleared => '已清除翻译块并还原原文';

  @override
  String get gen_translateAdjust => '追加翻译调整';

  @override
  String get gen_translateAdjustSub => '接着这次翻译聊，重切、重译、合并块';

  @override
  String get gen_translateAdjustTitle => '翻译调整';

  @override
  String gen_translateAdjustContext(int count) {
    return '续接本次翻译 · $count 块';
  }

  @override
  String gen_translateAdjustSelected(int count) {
    return '已选 $count 块';
  }

  @override
  String get gen_translateAdjustCollapse => '收起 / 展开';

  @override
  String get gen_translateAdjustIntro => '接着本次翻译调整。点击左侧翻译块添加引用，改块后可以撤销。';

  @override
  String get gen_translateAdjustSplit => '重新切块';

  @override
  String get gen_translateAdjustRetranslate => '重译选中';

  @override
  String get gen_translateAdjustMerge => '合并选中';

  @override
  String get gen_translateAdjustSplitTemplate => '读取当前块，按语义细分引用的块，保留精确原文。';

  @override
  String get gen_translateAdjustRetranslateTemplate => '读取当前块，重新翻译引用的块，不改原文。';

  @override
  String get gen_translateAdjustMergeTemplate => '读取当前块，按指定的原文顺序合并引用的块，无关块不动。';

  @override
  String get gen_translateAdjustMarkers =>
      '请使用 translation_blocks_read 返回的 marker 列表。';

  @override
  String get gen_translateAdjustHint => '接着说要怎么调整…';

  @override
  String get gen_translateAdjustStartFailed => '无法启动翻译调整，请检查模型与 Agent 运行时。';

  @override
  String get gen_translateAdjustRunFailed => '调整已中止或失败，重试前请重新读取当前块。';

  @override
  String gen_repeatDragTotal(int times, int total) {
    return '$times 次 · 共 $total 张';
  }

  @override
  String get set_cvGroupBatches => '批量结果按批次分组';

  @override
  String get set_cvGroupBatchesSub =>
      '关闭后每张图单独显示，点历史缩略图直接看那一张。只影响简洁查看器；无限画布始终按批次排列。';

  @override
  String get gen_groupBatches => '分组';

  @override
  String get gen_translateAdjustPickHint => '在左侧点块可引用';

  @override
  String get gen_translateAdjustClearRefs => '清除引用';

  @override
  String gen_translateAdjustSplitInto(String source, int count) {
    return '$source → $count 块';
  }

  @override
  String get gen_translateAdjustContextNote => '上下文：本次翻译的原文、切块和译文';

  @override
  String ag_historyStats(int messages, int cards) {
    return '$messages 条发言 · $cards 张卡片';
  }

  @override
  String get ag_historyKeySelect => '选择';

  @override
  String get ag_historyKeyJump => '跳到对话';

  @override
  String get ag_historyKeyClose => '关闭';

  @override
  String get blocks_tempLabel => '临时块';

  @override
  String blocks_tempEditedByAgent(String time) {
    return 'Agent$time 改过这里。';
  }

  @override
  String blocks_tempEditedByYou(String time) {
    return '你$time 改过这里。';
  }

  @override
  String blocks_tempExplain(String title) {
    return '它已和块库里的「$title」断开，改动只留在这个位置，块库和其他提示词里的同名块不受影响。';
  }

  @override
  String get blocks_tempEdit => '编辑';

  @override
  String get blocks_tempCompare => '对比原块';

  @override
  String get blocks_tempAdded => '新增';

  @override
  String blocks_tempAddedCount(int count) {
    return '新增 $count 个词';
  }

  @override
  String get blocks_tempAddedNone => '没有新增';

  @override
  String get blocks_tempRemoved => '删除';

  @override
  String blocks_tempRemovedHint(int count) {
    return '删了 $count 个词';
  }

  @override
  String get blocks_tempRemovedNone => '没有删除';

  @override
  String get blocks_tempRevert => '还原为原块';

  @override
  String get blocks_tempKeepEditing => '继续编辑';

  @override
  String get blocks_tempApply => '应用修改';

  @override
  String get blocks_tempSaveAs => '另存为新块';

  @override
  String get blocks_tempSaveAsHint => '另存为新块后，这里会换成新块，原块保持不变';

  @override
  String get blocks_tempSaveConfirm => '保存并转正';

  @override
  String get blocks_tempShowOriginal => '在块库中查看原块';

  @override
  String get gen_menuNew => '新';

  @override
  String get gen_repeatDragHint => '按住数字左右拖动调节 · 双击直接输入';

  @override
  String get gen_groupBatchesOn => '按批次分组 · 点击改为逐张显示';

  @override
  String get gen_groupBatchesOff => '逐张显示 · 点击按批次分组';

  @override
  String get blocks_presetCustom => '自定义';

  @override
  String get blocks_presetHint =>
      '应用附带参数时质量词和负面预设一并还原。换到别的模型时，档位按目标模型自动换算；Turbo 沿用现有处理。';

  @override
  String get gen_vibeInpaintUnsupported => 'Vibe 不支持局部重绘（Inpainting），本次不会生效。';

  @override
  String get set_stThumbnailCacheLimit => '缩略图缓存上限';

  @override
  String get set_stThumbnailCacheLimitSub =>
      '所有图库目录合计。启动或手动清理时，从最久没看的缩略图删到上限的 80%，不碰原图。';

  @override
  String get ag_slashGroupSkills => 'Skill';

  @override
  String get ag_slashGroupTemplates => '提示词模板';

  @override
  String get ag_slashGroupBuiltin => 'Studio 命令';

  @override
  String get ag_commandNew => '新建对话';

  @override
  String get ag_commandCompact => '压缩上下文';

  @override
  String get ag_commandModel => '选择模型';

  @override
  String get ag_commandThinking => '选择思考档位';

  @override
  String get ag_commandHistory => '打开会话历史';

  @override
  String get ag_commandRename => '重命名当前对话';

  @override
  String get ag_commandCopy => '复制最后一条回复';

  @override
  String get ag_commandExport => '导出当前会话';

  @override
  String get ag_commandCompactArgs => '[说明]';

  @override
  String get ag_commandRenameArgs => '<名称>';

  @override
  String get set_agNextSuggestion => '下一句建议';

  @override
  String get set_agNextSuggestionSub =>
      '使用当前对话模型预测你的下一句消息，会额外消耗 token；按 Tab 采纳。';

  @override
  String get set_agCacheWarming => '提示缓存预热';

  @override
  String get set_agCacheWarmingSub =>
      '在提示缓存快过期前用 1 token 的请求续上（按 5 分钟寿命，适配所有模型），下一步读缓存而不是重发整段上下文。';

  @override
  String get set_agCacheOff => '关闭';

  @override
  String get set_agCacheStreaming => '只在 Agent 运行时';

  @override
  String get set_agCacheIdle => '空闲时也预热';

  @override
  String get set_agCacheIdleCost => '空闲时也预热（最多 30 分钟）会产生额外模型费用。';

  @override
  String get ag_suggestionAccept => '按 Tab 填入这句建议';

  @override
  String get ag_cacheWarmTitle => '缓存预热';

  @override
  String get ag_cacheWarmOff => '已关闭';

  @override
  String get ag_cacheWarmRefreshing => '正在续期缓存…';

  @override
  String get ag_cacheWarmIdle => '待机，下次运行时开始';

  @override
  String ag_cacheWarmNext(String time) {
    return '$time 后续期';
  }

  @override
  String get set_stOther => '其他文件';

  @override
  String get set_stIncomplete => '部分目录读取失败，数字不完整；悬停分类可查看来源目录。';

  @override
  String get set_stSliceIncomplete => '未完整读取';

  @override
  String get localGallery_searchHistoryTitle => '最近搜索';

  @override
  String get localGallery_searchHistoryClear => '清空';

  @override
  String get localGallery_searchHistoryRemove => '从历史中删除';

  @override
  String ag_cacheWarmCount(int count) {
    return '已续期 $count 次';
  }

  @override
  String ag_cacheWarmLast(String time) {
    return '上次 $time';
  }

  @override
  String ag_cacheWarmTtl(int minutes) {
    return '缓存寿命 $minutes 分钟';
  }

  @override
  String get shortcut_action_open_resource_window => '打开资源小窗';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get app_title => 'W.O.F NAI Studio';

  @override
  String get settings_visualAssets => '介面字型與許可';

  @override
  String get brand_entryTagline => '給想像，一個發生的地方。';

  @override
  String get brand_switchToLight => '切換到淺色';

  @override
  String get brand_switchToDark => '切換到深色';

  @override
  String get app_subtitle => 'NovelAI 第三方客戶端';

  @override
  String get common_cancel => '取消';

  @override
  String get common_confirm => '確定';

  @override
  String get common_continue => '繼續';

  @override
  String get common_selectAll => '全選';

  @override
  String get common_deselectAll => '全不選';

  @override
  String get common_save => '儲存';

  @override
  String get common_delete => '刪除';

  @override
  String get common_edit => '編輯';

  @override
  String get common_close => '關閉';

  @override
  String get common_clear => '清除';

  @override
  String get common_copy => '複製';

  @override
  String get common_copied => '已複製';

  @override
  String get common_export => '匯出';

  @override
  String get common_import => '匯入';

  @override
  String get common_loading => '載入中...';

  @override
  String get common_error => '錯誤';

  @override
  String get common_success => '成功';

  @override
  String get common_retry => '重試';

  @override
  String get common_select => '選擇';

  @override
  String get common_reset => '重設';

  @override
  String get common_add => '新增';

  @override
  String get common_added => '已新增';

  @override
  String get common_confirmDelete => '確認刪除';

  @override
  String get common_confirmClear => '確認清空';

  @override
  String get common_gotIt => '知道了';

  @override
  String common_deleteItemConfirm(Object itemName) {
    return '確定要刪除「$itemName」嗎？此操作不可復原。';
  }

  @override
  String common_clearAllItemsConfirm(Object count, Object itemType) {
    return '確定要清空所有 $count 個$itemType嗎？此操作不可復原。';
  }

  @override
  String get common_clearInputConfirm => '確定要清空輸入內容嗎？';

  @override
  String common_daysAgo(Object days) {
    return '$days天前';
  }

  @override
  String get common_undo => '復原';

  @override
  String get common_redo => '重做';

  @override
  String get common_refresh => '重新整理';

  @override
  String get common_download => '下載';

  @override
  String get common_apply => '應用';

  @override
  String get common_favorite => '收藏';

  @override
  String get common_unfavorite => '取消收藏';

  @override
  String get common_ok => '確定';

  @override
  String get common_exit => '退出';

  @override
  String get common_grid => '網格';

  @override
  String get common_multiSelect => '多選';

  @override
  String get common_category => '分類';

  @override
  String get networkError_connectionTimeout => '連線逾時，請檢查網路連線。';

  @override
  String get networkError_sendTimeout => '傳送逾時，請重試。';

  @override
  String get networkError_receiveTimeout => '接收逾時，影像生成可能需要更長時間。';

  @override
  String get networkError_requestCancelled => '請求已取消';

  @override
  String get networkError_connection => '網路連線錯誤，請檢查網路連線。';

  @override
  String get networkError_unknown => '未知錯誤';

  @override
  String get networkError_noResponse => '伺服器無回應';

  @override
  String get networkError_badRequest => '請求參數錯誤';

  @override
  String get networkError_authFailed => '認證失敗，請重新登入。';

  @override
  String get networkError_insufficientAnlas => 'Anlas 不足';

  @override
  String get networkError_forbidden => '無權限存取該資源';

  @override
  String get networkError_notFound => '請求的資源不存在';

  @override
  String get networkError_conflict => '請求與當前狀態衝突';

  @override
  String get networkError_rateLimited => '請求過於頻繁，請稍後重試。';

  @override
  String get networkError_serverInternal => '伺服器內部錯誤';

  @override
  String get networkError_badGateway => '伺服器閘道錯誤';

  @override
  String get networkError_unavailable => '服務暫時不可用';

  @override
  String networkError_requestFailed(int code) {
    return '請求失敗（$code）';
  }

  @override
  String get auth_login => '登入';

  @override
  String get auth_logout => '登出';

  @override
  String get auth_email => '電子郵件';

  @override
  String get auth_password => '密碼';

  @override
  String get auth_loginButton => '登入';

  @override
  String get auth_loginFailed => '登入失敗';

  @override
  String get auth_guestEntry => '跳過登入，以遊客身份進入';

  @override
  String get auth_recommended => '推薦';

  @override
  String get auth_getToken => '取得 Token';

  @override
  String get auth_localOnlyNote => '帳號與 Token 僅儲存在本機';

  @override
  String get auth_back => '返回';

  @override
  String get auth_toggleVisibility => '顯示 / 隱藏';

  @override
  String get auth_emailRequired => '請輸入電子郵件';

  @override
  String get auth_emailInvalid => '請輸入有效的電子郵件地址';

  @override
  String get auth_passwordRequired => '請輸入密碼';

  @override
  String get auth_tokenLoginRecommended => 'API Token 登入（推薦）';

  @override
  String get auth_credentialsLogin => '電子郵件密碼登入';

  @override
  String get auth_credentialsLoginUnavailable => '帳號密碼登入當前不可用，請使用 Token 登入';

  @override
  String get auth_tokenRequired => '請輸入 Token';

  @override
  String get auth_tokenInvalid => 'Token 格式無效，應以 pst- 開頭';

  @override
  String get auth_nicknameHint => '為此帳號設定一個便於識別的名稱';

  @override
  String get auth_thirdPartyLogin => '第三方站點';

  @override
  String get auth_thirdPartyApiSite => '第三方 API 站點';

  @override
  String get auth_imageApiSiteOptional => '影像 API 站點（可選）';

  @override
  String get auth_imageApiSiteHint => '留空則使用同一個第三方 API 站點';

  @override
  String get auth_thirdPartyNicknameHint => '例如：自建站點 / 鏡像站點';

  @override
  String get auth_thirdPartyTokenHint => '請輸入第三方站點提供的 API Token';

  @override
  String get auth_thirdPartyCompatibilityHint =>
      '第三方站點需相容 NovelAI 的 /user/subscription 與影像生成相關 API；Token 將按 Bearer 方式傳送。';

  @override
  String get auth_thirdPartyApiSiteRequired => '請輸入第三方 API 站點地址';

  @override
  String get auth_validateAndLogin => '驗證並登入';

  @override
  String get auth_tokenGuide => '從 NovelAI 帳戶設定取得 Token';

  @override
  String get auth_addAccount => '新增帳號';

  @override
  String get auth_tokenNotFound => '未找到此帳號的 Token';

  @override
  String get auth_switchAccount => '切換帳號';

  @override
  String get auth_selectAccount => '選擇帳號';

  @override
  String get auth_deleteAccount => '刪除帳號';

  @override
  String auth_deleteAccountConfirm(Object name) {
    return '確定要刪除帳號 \"$name\" 嗎？此操作不可復原。';
  }

  @override
  String auth_deleteCurrentAccountConfirm(Object name) {
    return '將刪除帳號 \"$name\" 並登出，確定繼續嗎？';
  }

  @override
  String get auth_switchFailedDeletePrompt => '無法登入該帳號（可能已失效）。是否從列表中刪除？';

  @override
  String get auth_switchFailedDeletePromptMissingToken =>
      '未找到此帳號的登入憑據（可能已失效）。是否從列表中刪除？';

  @override
  String get auth_removeAvatar => '移除頭像';

  @override
  String get auth_quickLogin => '一鍵登入';

  @override
  String get auth_nicknameRequired => '請輸入暱稱';

  @override
  String get auth_error_networkTimeout => '連線逾時，請檢查網路';

  @override
  String get auth_error_networkError => '網路連線錯誤';

  @override
  String get auth_error_authFailed => '認證失敗';

  @override
  String get auth_error_credentialsLoginUnavailable => '帳號密碼登入當前不可用';

  @override
  String get auth_error_credentialsLoginUnavailable_hint =>
      'NovelAI 官網帳號密碼登入需要網頁安全驗證，客戶端無法完成，請改用 Persistent API Token。';

  @override
  String get auth_error_serverError => '伺服器錯誤';

  @override
  String get auth_error_unknown => '未知錯誤';

  @override
  String get auth_autoLogin => '自動登入';

  @override
  String get auth_forgotPassword => '忘記密碼？';

  @override
  String get auth_passwordTooShort => '密碼長度至少6位';

  @override
  String get auth_loggingIn => '登入中...';

  @override
  String get auth_viewTroubleshootingTips => '檢視故障排除提示';

  @override
  String get auth_troubleshoot_checkConnection_title => '檢查網路連線';

  @override
  String get auth_troubleshoot_checkConnection_desc => '確保您的裝置已連線到網際網路';

  @override
  String get auth_troubleshoot_retry_title => '重試';

  @override
  String get auth_troubleshoot_retry_desc => '網路問題可能是暫時的，請重試';

  @override
  String get auth_troubleshoot_proxy_title => '檢查代理設定';

  @override
  String get auth_troubleshoot_proxy_desc => '如果使用代理，請確認配置正確';

  @override
  String get auth_troubleshoot_firewall_title => '檢查防火牆設定';

  @override
  String get auth_troubleshoot_firewall_desc => '確保防火牆允許連線到 NovelAI 伺服器';

  @override
  String get auth_troubleshoot_serverStatus_title => '檢查伺服器狀態';

  @override
  String get auth_troubleshoot_serverStatus_desc =>
      '存取 NovelAI 狀態頁面或社群檢視服務中斷情況';

  @override
  String get common_paste => '貼上';

  @override
  String get common_default => '預設';

  @override
  String get settings_title => '設定';

  @override
  String get settings_savedAccounts => '已儲存帳號';

  @override
  String get settings_style => '風格';

  @override
  String get settings_font => '字型';

  @override
  String get settings_language => '語言';

  @override
  String get settings_shortcuts => '快速鍵';

  @override
  String get settings_generationInputSection => '輸入';

  @override
  String get settings_generationFeedbackSection => '完成提醒';

  @override
  String get settings_selectFont => '選擇字型';

  @override
  String get settings_selectLanguage => '選擇語言';

  @override
  String settings_loadFailed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get settings_imageSavePath => '圖片儲存位置';

  @override
  String get settings_autoSave => '自動儲存';

  @override
  String get settings_autoSaveSubtitle => '生成後自動儲存圖片';

  @override
  String get settings_extraRootsTitle => '圖庫源管理';

  @override
  String get settings_extraRootsHint =>
      '額外圖庫源：可瀏覽可搜尋，圖片可移動/複製到分類；不參與自動儲存。新增後會立即掃描。';

  @override
  String get settings_extraRootsEmpty => '尚未新增額外圖庫源';

  @override
  String get settings_extraRootsAdd => '新增資料夾';

  @override
  String get settings_extraRootsAddTitle => '選擇要新增的圖庫來源資料夾';

  @override
  String get settings_extraRootsRemove => '移除該圖庫源';

  @override
  String get settings_extraRootsRemoveConfirmTitle => '移除圖庫源？';

  @override
  String settings_extraRootsRemoveConfirmContent(String path) {
    return '將「$path」從畫廊中移除（不會刪除資料夾中的任何檔案）。';
  }

  @override
  String get settings_extraRootsAdded => '圖庫源已新增並完成掃描';

  @override
  String get settings_extraRootsScanFailed => '資料夾已新增，但掃描未完成，請在畫廊中重試重新整理';

  @override
  String get settings_extraRootsWaitingScan => '當前圖庫正在掃描，完成後會繼續匯入此資料夾';

  @override
  String get settings_extraRootsRemoved => '圖庫源已移除';

  @override
  String get settings_extraRootsDuplicate => '該資料夾已在圖庫源中';

  @override
  String get settings_extraRootsSameAsMain => '該資料夾與圖片儲存位置相同';

  @override
  String get settings_extraRootsNested => '圖庫源之間不能互相包含，請選擇其他資料夾';

  @override
  String get settings_extraRootsNotFound => '所選資料夾不存在';

  @override
  String get settings_importTagIndex => '匯入標籤索引…';

  @override
  String get settings_importTagIndexPickTitle => '選擇標籤索引檔案 (.jsonl)';

  @override
  String settings_importTagIndexProgress(int processed, int total) {
    return '正在匯入 $processed/$total 行…';
  }

  @override
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  ) {
    return '匯入完成：新增 $imported，更新 $updated，跳過 $skipped，錯誤 $errors';
  }

  @override
  String get settings_importTagIndexFailed => '標籤索引匯入失敗';

  @override
  String get settings_importTagIndexBlockedByScan => '畫廊正在掃描中，請等待掃描完成後再匯入標籤索引';

  @override
  String get settings_extraRootsIndexImportTitle => '檢測到標籤索引';

  @override
  String settings_extraRootsIndexImportContent(String path) {
    return '在「$path」下檢測到標籤索引 index.jsonl。先匯入標籤索引可讓之後的掃描直接快進（跳過後設資料解析），是否現在匯入？';
  }

  @override
  String get settings_extraRootsIndexImportConfirm => '現在匯入';

  @override
  String settings_version(Object version) {
    return '版本 $version';
  }

  @override
  String get settings_openSource => '開源專案';

  @override
  String get settings_openSourceSubtitle => '檢視原始碼和文件';

  @override
  String get settings_fileLogging => '記錄應用日誌';

  @override
  String get settings_fileLoggingSubtitle =>
      '預設關閉；僅在排查問題時開啟。開啟後會寫入 Documents/NAI_Launcher/logs，關閉後不再建立或寫入日誌檔案。';

  @override
  String get settings_pathReset => '已重設為預設路徑';

  @override
  String get settings_pathSaved => '儲存路徑已更新';

  @override
  String get settings_selectFolder => '選擇儲存資料夾';

  @override
  String get settings_vibeLibraryPath => 'Vibe庫路徑';

  @override
  String get settings_hiveStoragePath => '資料儲存路徑';

  @override
  String get settings_selectVibeLibraryFolder => '選擇Vibe庫資料夾';

  @override
  String get settings_selectHiveFolder => '選擇資料儲存資料夾';

  @override
  String get settings_pathSavedRestartRequired => '路徑已更新，重啟後生效';

  @override
  String get settings_accountType => '帳號類型';

  @override
  String get settings_subscriptionExpiry => '訂閱到期';

  @override
  String get settings_thirdPartyApiAccount => '第三方站點 API';

  @override
  String get settings_goToLogin => '去登入';

  @override
  String get settings_changeAvatar => '更換頭像';

  @override
  String get settings_removeAvatar => '移除頭像';

  @override
  String get settings_accountEmail => '帳號電子郵件';

  @override
  String get settings_emailAccount => '電子郵件登入';

  @override
  String get settings_tokenAccount => 'Token登入';

  @override
  String get settings_setAsDefault => '設為預設';

  @override
  String get settings_defaultAccount => '預設';

  @override
  String get settings_nickname => '暱稱';

  @override
  String get settings_nicknameUpdated => '暱稱已更新';

  @override
  String get settings_avatarUpdated => '頭像已更新';

  @override
  String get settings_avatarRemoved => '頭像已移除';

  @override
  String get settings_setAsDefaultSuccess => '已設為預設帳號';

  @override
  String generation_cooldownRemaining(Object seconds) {
    return '等待 $seconds 秒';
  }

  @override
  String get generation_generating => '生成中...';

  @override
  String get generation_cancelGeneration => '取消生成';

  @override
  String get generation_stopGeneration => '停止生成';

  @override
  String get generation_pleaseInputPrompt => '請輸入提示詞';

  @override
  String get generation_generationFailed => '生成失敗';

  @override
  String generation_deleteSelectedImagesConfirm(int count) {
    return '將從記錄中移除 $count 張影像（已儲存到磁碟的檔案保留）';
  }

  @override
  String generation_seedWrittenBack(int seed) {
    return '種子已寫回: $seed';
  }

  @override
  String get generation_setAsReferenceImage => '已設為參考圖';

  @override
  String get generation_canvasDisplaySettings => '畫布顯示';

  @override
  String get generation_canvasZoomToFill => '放大填充（允許 >100%）';

  @override
  String get generation_canvasEmpty => '畫布為空';

  @override
  String get generation_canvasBackground => '透明區域底色';

  @override
  String get generation_canvasBackgroundChecker => '棋盤格';

  @override
  String get generation_canvasBackgroundCheckerLight => '淺色棋盤格';

  @override
  String get generation_canvasBackgroundCheckerDark => '深色棋盤格';

  @override
  String get generation_canvasBackgroundNone => '無底色';

  @override
  String get generation_canvasBackgroundBlack => '黑色';

  @override
  String get generation_canvasBackgroundWhite => '白色';

  @override
  String get generation_canvasBackgroundGray => '灰色';

  @override
  String get generation_canvasBackgroundRed => '紅色';

  @override
  String get generation_canvasBackgroundGreen => '綠色';

  @override
  String get generation_canvasBackgroundBlue => '藍色';

  @override
  String get generation_canvasBackgroundCustom => '自訂顏色';

  @override
  String get generation_canvasSetInitImage => '設為圖生圖底圖';

  @override
  String get generation_canvasSendToTools => '傳送至導演工具';

  @override
  String get generation_canvasPinImage => '固定圖片';

  @override
  String get generation_canvasUnpinImage => '取消固定';

  @override
  String get generation_canvasUseSeed => '點選複用此種子';

  @override
  String get generation_history => '歷史';

  @override
  String get generation_failedStreamSnapshot => '失敗快照';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成未完成，僅保留最後一幀預覽；不可儲存、收藏或用於圖生圖';

  @override
  String get generation_model => '模型';

  @override
  String get generation_imageSize => '影像尺寸';

  @override
  String get generation_sampler => '取樣器';

  @override
  String generation_steps(Object steps) {
    return '步數: $steps';
  }

  @override
  String get generation_stepsLabel => '步數';

  @override
  String get generation_guidance => '引導';

  @override
  String generation_cfgScale(Object scale) {
    return '提示詞引導：$scale';
  }

  @override
  String get generation_seed => '種子';

  @override
  String get generation_seedRandom => '隨機';

  @override
  String get generation_samplerRecommended => '推薦';

  @override
  String get generation_samplerOther => '其他';

  @override
  String get generation_advancedOptions => '進階選項';

  @override
  String get generation_smea => 'SMEA';

  @override
  String get generation_smeaSubtitle => '改善大影像的生成品質';

  @override
  String get generation_smeaDyn => 'SMEA DYN';

  @override
  String get generation_smeaDescription => '高解析度取樣器會在超過一定影像尺寸時自動使用';

  @override
  String generation_cfgRescale(Object value) {
    return '提示詞引導重縮放：$value';
  }

  @override
  String get generation_noiseSchedule => '噪聲排程';

  @override
  String get generation_modelGroupNew => '最新';

  @override
  String get generation_modelGroupLegacy => '舊版';

  @override
  String get generation_modelDesc_v5Curated =>
      'NovelAI 的最新模型，基於精選影像子集訓練。推薦用於流式傳輸。';

  @override
  String get generation_modelDesc_v5Full => 'NovelAI 最新且最強的模型。';

  @override
  String get generation_modelDesc_v45Curated => '基於精選影像子集訓練的 V4.5 模型。不再推薦使用。';

  @override
  String get generation_modelDesc_v45Full => 'NovelAI 的 V4.5 全量模型。';

  @override
  String get generation_modelDesc_v4Curated => '基於精選影像子集訓練的 V4 模型。';

  @override
  String get generation_modelDesc_v4Full => 'NovelAI 的 V4 全量模型。';

  @override
  String get generation_sectionCharacters => '角色提示詞';

  @override
  String get generation_sectionCharactersSub => '為場景中的角色建立獨立提示詞。';

  @override
  String get character_positionLabel => '定位';

  @override
  String get anlas_subscription => '訂閱贈送';

  @override
  String get anlas_purchased => '付費購買';

  @override
  String get prompt_positive => '正面';

  @override
  String get prompt_baseTab => '基礎提示詞';

  @override
  String get prompt_negativeTab => '負面';

  @override
  String get prompt_transparentBg => '透明通道';

  @override
  String get prompt_chunksMenu => '模組與開關';

  @override
  String get qualityTags_presetChip => '品質詞預設';

  @override
  String get ucPreset_presetChip => '負面詞預設';

  @override
  String get prompt_positivePrompt => '正向提示詞';

  @override
  String get prompt_negativePrompt => '負向提示詞';

  @override
  String get prompt_mainPositive => '主提示詞（正面）';

  @override
  String get prompt_mainNegative => '主提示詞（負面）';

  @override
  String get prompt_characterPrompts => '多角色提示詞';

  @override
  String get prompt_finalPrompt => '最終生效提示詞';

  @override
  String get prompt_finalNegative => '最終生效負面詞';

  @override
  String prompt_importedCharacters(int count) {
    return '已匯入 $count 個角色';
  }

  @override
  String get prompt_characterPromptReplaced => '已替換角色提示詞';

  @override
  String prompt_characterPromptAppended(Object count) {
    return '已追加角色提示詞 ($count 個角色)';
  }

  @override
  String prompt_smartDecomposedWithCharacters(Object count) {
    return '已分解：主提示詞 + $count 個角色';
  }

  @override
  String get prompt_appliedToMainPrompt => '已應用到主提示詞';

  @override
  String get prompt_searchHint => '搜尋提示詞';

  @override
  String prompt_searchMatchCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get prompt_searchPrevious => '上一個命中';

  @override
  String get prompt_searchNext => '下一個命中';

  @override
  String get prompt_searchClose => '關閉搜尋';

  @override
  String get prompt_replaceHint => '替換為';

  @override
  String get prompt_replaceToggle => '顯示/隱藏替換';

  @override
  String get prompt_replaceCurrent => '替換當前命中（Enter）';

  @override
  String get prompt_replaceAll => '全部替換（Ctrl+Enter）';

  @override
  String prompt_replaceAllDone(Object count) {
    return '已替換 $count 處';
  }

  @override
  String get kritaBridge_busyGenerating => 'Krita Bridge 正在生成，請等待當前任務結束';

  @override
  String get prompt_unwantedContent => '不想出現在影像中的內容...';

  @override
  String get prompt_autoFormat => '自動格式化';

  @override
  String get prompt_autoFormatSubtitle => '規範逗號與空白，移除無效的 1 倍權重符號';

  @override
  String get prompt_highlightEmphasis => '高亮強調';

  @override
  String get prompt_highlightEmphasisSubtitle => '括號和權重語法高亮顯示';

  @override
  String get prompt_sdSyntaxAutoConvert => 'SD語法自動轉換';

  @override
  String get prompt_sdSyntaxAutoConvertSubtitle => '失焦或生成時將 SD 權重語法轉換為 NAI 格式';

  @override
  String get prompt_cooccurrenceRecommendation => '標籤擴展';

  @override
  String get prompt_cooccurrenceRecommendationSubtitle =>
      'Ctrl+單擊搜尋本地標籤；Ctrl+拖選檢視關聯標籤';

  @override
  String get prompt_formatted => '已格式化';

  @override
  String get image_save => '儲存';

  @override
  String get image_copy => '複製';

  @override
  String get image_upscale => '放大';

  @override
  String image_imageSaved(Object path) {
    return '圖片已儲存到: $path';
  }

  @override
  String image_saveFailed(Object error) {
    return '儲存失敗: $error';
  }

  @override
  String get image_copiedToClipboard => '已複製到剪貼簿';

  @override
  String image_copyFailed(Object error) {
    return '複製失敗: $error';
  }

  @override
  String get img2img_title => '圖生圖';

  @override
  String get img2img_subtitle => '基於底圖生成變體';

  @override
  String get img2img_enabled => '已啟用';

  @override
  String get img2img_sourceImage => '來源影像';

  @override
  String get img2img_strength => '變化強度';

  @override
  String get img2img_strengthHint => '值越高，生成的影像與原圖差異越大';

  @override
  String get img2img_noise => '噪聲量';

  @override
  String get img2img_noiseHint => '新增額外噪聲以增加變化';

  @override
  String get img2img_clearSettings => '清除圖生圖設定';

  @override
  String get img2img_changeImage => '更換圖片';

  @override
  String get img2img_removeImage => '移除圖片';

  @override
  String img2img_selectFailed(Object error) {
    return '選擇圖片失敗: $error';
  }

  @override
  String get img2img_editImage => '編輯影像';

  @override
  String get img2img_placeOnCanvas => '放入畫布';

  @override
  String get img2img_editApplied => '已將編輯結果設為新的來源圖';

  @override
  String get img2img_uploadImage => '上傳圖片';

  @override
  String get img2img_dropToAdd => '鬆開以設為底圖';

  @override
  String get img2img_moreActions => '更多操作';

  @override
  String get img2img_drawSketch => '繪製草圖';

  @override
  String get img2img_inpaint => '局部重繪';

  @override
  String get img2img_inpaintStrength => '重繪強度';

  @override
  String get img2img_inpaintStrengthHint => '值越高，遮罩區域與當前來源圖差異越大';

  @override
  String get img2img_inpaintPendingHint =>
      '點選“局部重繪”進入畫布，用畫筆、橡皮或選區工具標出需要重繪的區域。返回這裡後，點選主生成按鈕即可只重繪遮罩區域。';

  @override
  String get img2img_inpaintReadyHint => '遮罩已載入。當前會按局部重繪方式提交，只有遮罩區域會被重新生成。';

  @override
  String get img2img_inpaintMaskReady => '局部重繪遮罩已準備好';

  @override
  String get generation_variationOriginal => '原圖';

  @override
  String get generation_variationSizeUnsupported => '生成變體支援不超過 3 百萬像素的原圖。';

  @override
  String get img2img_generateVariations => '生成變體';

  @override
  String get img2img_directorTools => '導演工具';

  @override
  String get img2img_directorApplied => '已將導演工具結果設為新的來源圖';

  @override
  String get img2img_variationsStarted => '正在生成變體...';

  @override
  String get img2img_directorRemoveBackground => '背景移除';

  @override
  String get img2img_directorLineArt => '線稿提取';

  @override
  String get img2img_directorSketch => '草圖化';

  @override
  String get img2img_directorColorize => '上色';

  @override
  String get img2img_directorEmotion => '表情修復';

  @override
  String get img2img_directorDeclutter => '雜線清理';

  @override
  String get img2img_enhance => '增強';

  @override
  String get img2img_enhanceMagnitude => '幅度';

  @override
  String get img2img_enhanceUpscaleAmount => '放大倍數';

  @override
  String get img2img_enhanceMax => 'Max✨';

  @override
  String get img2img_novelAiCloudUpscale => 'NovelAI 雲端超分（固定 2x 放大）';

  @override
  String get img2img_novelAiCloudUpscaleTitle => 'NovelAI 雲端超分';

  @override
  String get img2img_cloudUpscaleSizeLimit => 'NovelAI 雲端放大支援不超過 3MP 的輸入圖片。';

  @override
  String get img2img_upscaleRegularModel => '普通模型';

  @override
  String get img2img_upscaleModel => '超分模型';

  @override
  String get img2img_startUpscale => '開始超分';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 超分完成';

  @override
  String get img2img_decodeSourceFailed => '無法解碼來源影像';

  @override
  String get editor_tolerance => '容差';

  @override
  String get editor_intensity => '強度';

  @override
  String get editor_sourcePoint => 'Alt+點選設定源點';

  @override
  String get editor_brushPresets => '筆刷預設';

  @override
  String get editor_size => '大小';

  @override
  String get editor_opacity => '不透明度';

  @override
  String get editor_hardness => '硬度';

  @override
  String get editor_undo => '復原';

  @override
  String get editor_redo => '重做';

  @override
  String get editor_clearLayer => '清除圖層';

  @override
  String get editor_toolBrush => '畫筆';

  @override
  String get editor_toolEraser => '橡皮擦';

  @override
  String get editor_toolFill => '填充';

  @override
  String get editor_toolMagicWand => '魔棒';

  @override
  String get editor_magicWandMode => '選擇方式';

  @override
  String get editor_magicWandSmartObject => '智慧物件（EfficientViT）';

  @override
  String get editor_magicWandColorArea => '顏色區域（洪水填充）';

  @override
  String get editor_magicWandSmartHelp =>
      '點選要選擇的物件。首次使用會從 MIT Han Lab 下載約 133 MiB 的 EfficientViT-SAM L0 模型（Apache-2.0），之後儲存在本地。';

  @override
  String get editor_magicWandColorHelp => '點選顏色相近的連續區域。適合邊界清晰的純色影像，無需下載模型。';

  @override
  String get editor_magicWandInvert => '反選結果';

  @override
  String get editor_toolLine => '直線';

  @override
  String get editor_toolRectSelect => '矩形選框';

  @override
  String get editor_toolEllipseSelect => '橢圓選框';

  @override
  String get editor_toolLassoSelect => '套索選區';

  @override
  String get editor_toolColorPicker => '吸管取色';

  @override
  String get editor_toolCloneStamp => '仿製圖章';

  @override
  String get editor_toolBlur => '模糊';

  @override
  String get editor_layers => '圖層';

  @override
  String get editor_fillClosedRegion => '填充封閉區域';

  @override
  String get editor_resetMask => '重設遮罩';

  @override
  String get editor_zoomIn => '放大';

  @override
  String get editor_zoomOut => '縮小';

  @override
  String get editor_fitToWindow => '適應視窗';

  @override
  String get editor_effectBrightness => '亮度';

  @override
  String get editor_effectSaturation => '飽和度';

  @override
  String get editor_changeCanvasSize => '更改畫布尺寸';

  @override
  String get editor_confirmExitTitle => '確認退出';

  @override
  String get editor_confirmExitContent => '有未儲存的修改，確定要退出嗎？';

  @override
  String get editor_exit => '退出';

  @override
  String get editor_saveAndExit => '儲存並退出';

  @override
  String editor_exportFailed(Object error) {
    return '匯出失敗: $error';
  }

  @override
  String get editor_maskLayerName => '遮罩';

  @override
  String get editor_emptyImageFile => '檔案為空，請選擇有效的影像檔案';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return '檔案過大（$sizeMB MB），請選擇小於 50MB 的影像';
  }

  @override
  String get editor_parseImageFailed => '無法解析影像檔案\n請確保檔案未損壞且格式受支援';

  @override
  String get editor_defaultTitle => '畫板';

  @override
  String get editor_baseLayerName => '底圖';

  @override
  String get editor_existingMaskLayerName => '已有遮罩';

  @override
  String get editor_defaultDrawingLayerName => '圖層 1';

  @override
  String editor_layerName(Object count) {
    return '圖層 $count';
  }

  @override
  String get editor_canvasSizeTitle => '畫布尺寸';

  @override
  String get editor_presetSize => '預設尺寸';

  @override
  String get editor_customSize => '自訂';

  @override
  String get editor_contentHandling => '內容處理';

  @override
  String get editor_contentCrop => '裁切';

  @override
  String get editor_contentPad => '填充';

  @override
  String get editor_contentStretch => '拉伸';

  @override
  String get editor_width => '寬度';

  @override
  String get editor_height => '高度';

  @override
  String get editor_lockAspectRatio => '鎖定比例';

  @override
  String get editor_unlockAspectRatio => '取消鎖定比例';

  @override
  String get editor_sizePreview => '尺寸預覽';

  @override
  String get editor_originalSize => '原始';

  @override
  String get editor_newSize => '新尺寸';

  @override
  String get editor_cropModeDescription => '裁切模式 - 保持比例裁切';

  @override
  String get editor_padModeDescription => '填充模式 - 保持比例填充';

  @override
  String get editor_stretchModeDescription => '拉伸模式 - 拉伸至填滿';

  @override
  String editor_canvasPresetSquare(Object size) {
    return '方形 $size';
  }

  @override
  String editor_canvasPresetLandscape(Object ratio) {
    return '橫向 $ratio';
  }

  @override
  String editor_canvasPresetPortrait(Object ratio) {
    return '縱向 $ratio';
  }

  @override
  String get editor_canvasPresetNaiPortrait => 'NAI 縱向';

  @override
  String get editor_canvasPresetNaiLandscape => 'NAI 橫向';

  @override
  String get editor_canvasPresetFullHd => '全高畫質 16:9';

  @override
  String get editor_colorPanelTitle => '顏色';

  @override
  String get editor_colorPickerTitle => '選擇顏色';

  @override
  String get editor_brushSettings => '畫筆設定';

  @override
  String get editor_eraserSettings => '橡皮擦設定';

  @override
  String get editor_lassoSelectionHelp => '按住滑鼠拖動繪製自由形狀選區，鬆開自動閉合';

  @override
  String get layer_empty => '無圖層';

  @override
  String get layer_add => '新增圖層';

  @override
  String get layer_mergeDown => '向下合併';

  @override
  String get layer_duplicate => '複製圖層';

  @override
  String get layer_delete => '刪除圖層';

  @override
  String get layer_merge => '合併圖層';

  @override
  String get layer_visibility => '顯示/隱藏';

  @override
  String get layer_lock => '鎖定';

  @override
  String get layer_rename => '重新命名';

  @override
  String get layer_moveUp => '上移';

  @override
  String get layer_moveDown => '下移';

  @override
  String get vibe_title => '風格遷移';

  @override
  String get vibe_description => '改變影像，保留視覺風格';

  @override
  String get vibe_addFromFileTitle => '從檔案新增';

  @override
  String get vibe_addFromFileSubtitle => 'PNG、JPG、Vibe 檔案';

  @override
  String get vibe_addFromLibraryTitle => '從庫匯入';

  @override
  String get vibe_addFromLibrarySubtitle => '從 Vibe 庫中選擇';

  @override
  String get vibe_addReference => '新增參考圖';

  @override
  String get vibe_clearAll => '清除全部';

  @override
  String vibe_cleared(int count) {
    return '已清除 $count 個 vibes';
  }

  @override
  String get vibe_referenceStrength => '參考強度';

  @override
  String get vibe_infoExtraction => '資訊提取';

  @override
  String get vibe_remove => '移除';

  @override
  String get reference_enabled => '啟用';

  @override
  String get reference_enable => '啟用參考';

  @override
  String get reference_disable => '停用參考';

  @override
  String get vibe_normalize => '標準化參考強度值';

  @override
  String get vibe_sourceType_png => 'PNG';

  @override
  String get vibe_sourceType_v4vibe => 'V4 Vibe';

  @override
  String get vibe_sourceType_bundle => '組合包';

  @override
  String get vibe_sourceType_image => '圖片';

  @override
  String get vibe_sourceType => '資料來源';

  @override
  String get vibe_info => 'Vibe 資訊';

  @override
  String get vibe_name => '名稱';

  @override
  String get character_buttonLabel => '角色/定位';

  @override
  String get character_addCharacter => '新增角色';

  @override
  String character_number(Object index) {
    return '角色 $index';
  }

  @override
  String get gallery_generationParams => '生成參數';

  @override
  String get gallery_metaModel => '模型';

  @override
  String get gallery_metaResolution => '解析度';

  @override
  String get gallery_metaSteps => '步數';

  @override
  String get gallery_metaSampler => '取樣器';

  @override
  String get gallery_metaCfgScale => '提示詞引導';

  @override
  String get gallery_metaSeed => '種子';

  @override
  String get gallery_sendToKritaAction => '傳送到 Krita';

  @override
  String get gallery_upscalePanelLoaded => '已載入圖生圖超分面板';

  @override
  String gallery_readImageFailed(Object error) {
    return '讀取影像失敗: $error';
  }

  @override
  String get gallery_fileMissing => '檔案不存在';

  @override
  String get gallery_copiedToClipboard => '已複製到剪貼簿';

  @override
  String gallery_copyFailed(Object error) {
    return '複製失敗: $error';
  }

  @override
  String get gallery_upscale => '放大';

  @override
  String get gallery_sentToImg2Img => '圖片已傳送到圖生圖';

  @override
  String gallery_sendFailed(Object error) {
    return '傳送失敗: $error';
  }

  @override
  String get onlineGallery_login => '登入';

  @override
  String get onlineGallery_pleaseLogin => '請先登入';

  @override
  String get mediaType_video => '影片';

  @override
  String get mediaType_gif => '動圖';

  @override
  String get onlineGallery_copied => '已複製';

  @override
  String get onlineGallery_copyTags => '複製標籤';

  @override
  String get onlineGallery_sendToTextToImage => '傳送到文生圖';

  @override
  String get onlineGallery_sentToTextToImage => '已傳送到文生圖';

  @override
  String get onlineGallery_noTagInfo => '此圖片沒有標籤資訊';

  @override
  String get onlineGallery_chooseDownloadDirectory => '選擇下載目錄';

  @override
  String get onlineGallery_downloadStarted => '開始下載...';

  @override
  String onlineGallery_savedToPath(Object path) {
    return '已儲存到: $path';
  }

  @override
  String onlineGallery_downloadFailed(Object error) {
    return '下載失敗: $error';
  }

  @override
  String get onlineGallery_downloadOriginal => '下載原圖';

  @override
  String get onlineGallery_ratingGeneral => '全年齡';

  @override
  String get onlineGallery_ratingSensitive => '敏感';

  @override
  String get onlineGallery_ratingQuestionable => '可疑';

  @override
  String get onlineGallery_ratingExplicit => '限制級';

  @override
  String get onlineGallery_blacklistTitle => '線上畫廊黑名單';

  @override
  String get onlineGallery_blacklistSubtitle => '包含黑名單標籤的圖片會在線上畫廊中直接隱藏。';

  @override
  String get onlineGallery_addBlacklistTagHint => '新增黑名單標籤';

  @override
  String get onlineGallery_noLocalBlacklistTags => '暫無本地黑名單標籤';

  @override
  String get onlineGallery_autoSyncOnStartup => '啟動時自動同步';

  @override
  String get onlineGallery_autoSyncOnStartupSubtitle => '預設開啟，可隨時關閉';

  @override
  String onlineGallery_lastSyncFailed(Object error) {
    return '上次同步失敗: $error';
  }

  @override
  String get onlineGallery_neverSyncedBlacklist => '尚未同步過 Danbooru 黑名單';

  @override
  String onlineGallery_lastSync(Object time) {
    return '上次同步: $time';
  }

  @override
  String get onlineGallery_blacklistSettingsTitle => '線上畫廊黑名單設定';

  @override
  String get onlineGallery_blacklistLoginHint =>
      '未登入 Danbooru，仍可使用本地黑名單；同步需要先登入。';

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return '下載完成: 成功 $success, 失敗 $failed';
  }

  @override
  String get onlineGallery_gelbooruCredentialsRequired =>
      '請先配置 Gelbooru User ID 和 API Key 以檢視網站收藏。';

  @override
  String get onlineGallery_gelbooruCredentialsInvalid =>
      'Gelbooru 憑據已失效，請重新配置。';

  @override
  String get onlineGallery_gelbooruRateLimited => 'Gelbooru 請求過於頻繁，請稍後再試。';

  @override
  String get onlineGallery_gelbooruTimeout => 'Gelbooru 請求逾時，請檢查網路連線。';

  @override
  String get onlineGallery_gelbooruServerError => 'Gelbooru 伺服器暫時不可用，請稍後再試。';

  @override
  String get onlineGallery_gelbooruNetworkError =>
      '無法連線 Gelbooru，請檢查網路設定或代理配置。';

  @override
  String get onlineGallery_gelbooruMalformedResponse => 'Gelbooru 返回了無法解析的資料。';

  @override
  String get onlineGallery_gelbooruRequestFailed => 'Gelbooru 請求失敗，請稍後重試。';

  @override
  String get onlineGallery_aiTagRankingProcessing => '排行榜生成中，請稍後重試。';

  @override
  String get onlineGallery_sourceConfigUnavailable => '無法取得來源配置，請檢查網路後重試。';

  @override
  String get onlineGallery_sourceRateLimited => '請求過於頻繁，請稍後重試。';

  @override
  String get onlineGallery_sourceTimeout => '請求逾時，請檢查網路連線。';

  @override
  String get onlineGallery_sourceNetworkError => '無法連線當前畫廊來源，請檢查網路或代理。';

  @override
  String get onlineGallery_sourceMalformedResponse => '來源返回的資料結構已變化，暫時無法解析。';

  @override
  String get onlineGallery_detailNotFound => '作品不存在或已被刪除。';

  @override
  String get onlineGallery_imageUnavailable => '圖片當前不可用。';

  @override
  String get onlineGallery_gelbooruReadOnly => '只讀收藏';

  @override
  String get tooltip_fullscreenEdit => '全屏編輯';

  @override
  String get tooltip_decreaseWeight => '減少權重 [-5%]';

  @override
  String get tooltip_increaseWeight => '增加權重 [+5%]';

  @override
  String get tooltip_resetWeight => '點選重設為100%';

  @override
  String get upscale_scale => '放大倍數';

  @override
  String get danbooru_loginTitle => '登入 Danbooru';

  @override
  String get danbooru_loginHint => '使用使用者名稱和 API Key 登入以使用收藏夾功能';

  @override
  String get danbooru_username => '使用者名稱';

  @override
  String get danbooru_usernameHint => '輸入 Danbooru 使用者名稱';

  @override
  String get danbooru_usernameRequired => '請輸入使用者名稱';

  @override
  String get danbooru_apiKeyHint => '輸入 API Key';

  @override
  String get danbooru_apiKeyRequired => '請輸入 API Key';

  @override
  String get danbooru_howToGetApiKey => '如何取得 API Key?';

  @override
  String get danbooru_loginSuccess => '登入成功';

  @override
  String get gelbooru_configureTitle => '配置 Gelbooru API';

  @override
  String get gelbooru_configureHint =>
      '輸入 Gelbooru 帳戶設定頁提供的 User ID 和 API Key。應用不會收集密碼或瀏覽器 Cookie。';

  @override
  String get gelbooru_userId => 'User ID';

  @override
  String get gelbooru_userIdHint => '輸入正整數 User ID';

  @override
  String get gelbooru_userIdRequired => '請輸入有效的正整數 User ID';

  @override
  String get gelbooru_apiKeyHint => '輸入 API Key';

  @override
  String get gelbooru_apiKeyRequired => '請輸入 API Key';

  @override
  String get gelbooru_openAccountSettings => '開啟 Gelbooru 帳戶設定';

  @override
  String get gelbooru_save => '驗證並儲存';

  @override
  String get gelbooru_saved => 'Gelbooru 憑據已儲存';

  @override
  String get gelbooru_removeCredentials => '移除憑據';

  @override
  String get gelbooru_invalidInput => '請輸入有效的 User ID 和 API Key。';

  @override
  String get gelbooru_invalidCredentials =>
      'Gelbooru 拒絕了這些憑據，請檢查 User ID 和 API Key。';

  @override
  String get gelbooru_rateLimited => '請求過於頻繁，請稍後再試。';

  @override
  String get gelbooru_timeout => '驗證逾時，請檢查網路連線。';

  @override
  String get gelbooru_serverError => 'Gelbooru 伺服器暫時不可用。';

  @override
  String get gelbooru_networkError => '無法連線 Gelbooru，請檢查網路設定或代理配置。';

  @override
  String get gelbooru_malformedResponse => 'Gelbooru 返回了無法解析的資料。';

  @override
  String get gelbooru_storageError => '無法安全儲存或讀取 Gelbooru 憑據。';

  @override
  String get gelbooru_unknownError => 'Gelbooru 驗證失敗，請稍後重試。';

  @override
  String get tag_addTag => '新增標籤';

  @override
  String get qualityTags_label => '品質詞';

  @override
  String get transparentBackground_tooltip =>
      '向提示詞追加 transparent background 標籤，生成帶 alpha 通道的影像（V5 專屬）';

  @override
  String get qualityTags_positive => '品質詞（正面）';

  @override
  String get qualityTags_negative => '品質詞（負面）';

  @override
  String get qualityTags_disabled => '品質標籤已關閉\n點選開啟';

  @override
  String get qualityTags_addToEnd => '新增到提示詞末尾:';

  @override
  String get qualityTags_addToStart => '新增到提示詞開頭:';

  @override
  String get qualityTags_naiDefault => 'NAI 預設';

  @override
  String get qualityTags_standard => '標準';

  @override
  String get qualityTags_light => '輕量';

  @override
  String get qualityTags_none => '無';

  @override
  String get ucPreset_label => '負面預設';

  @override
  String get ucPreset_heavy => '重度';

  @override
  String get ucPreset_light => '輕度';

  @override
  String get ucPreset_furryFocus => '獸人';

  @override
  String get ucPreset_humanFocus => '人物';

  @override
  String get ucPreset_lowQuality => '低品質';

  @override
  String get ucPreset_badAnatomy => '解剖錯誤';

  @override
  String get ucPreset_none => '無';

  @override
  String get ucPreset_disabled => '負面提示詞預設已關閉';

  @override
  String get ucPreset_addToNegative => '新增到負面提示詞開頭:';

  @override
  String get ucPreset_nsfwHint =>
      '💡 如需生成成人內容，請在正面提示詞中新增 nsfw，負面提示詞中的 nsfw 將自動移除';

  @override
  String get generation_imageCount => '生成數量';

  @override
  String get generation_requestCountTooltip => '請求次數：每次點擊發起 N 次生成請求';

  @override
  String generation_imageCountTotal(int requests, int perRequest, int total) {
    return '$requests 次 × $perRequest 張 = 共 $total 張';
  }

  @override
  String get warmup_networkCheck => '檢測網路連線...';

  @override
  String get warmup_networkCheck_noProxy => '無法連線到 NovelAI，請開啟VPN或啟用代理設定';

  @override
  String get warmup_networkCheck_noSystemProxy => '已啟用代理但未檢測到系統代理，請開啟VPN';

  @override
  String get warmup_networkCheck_manualIncomplete => '手動代理配置不完整，請檢查設定';

  @override
  String get warmup_networkCheck_testing => '正在檢測網路連線...';

  @override
  String get warmup_networkCheck_testingProxy => '正在通過代理檢測網路...';

  @override
  String warmup_networkCheck_success(Object latency) {
    return '網路連線正常 (${latency}ms)';
  }

  @override
  String get warmup_networkCheck_timeout => '網路檢測逾時，繼續離線啟動';

  @override
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts) {
    return '正在檢測網路連線... (嘗試 $attempt/$maxAttempts)';
  }

  @override
  String get warmup_preparing => '準備中...';

  @override
  String get warmup_complete => '完成';

  @override
  String get warmup_danbooruAuth => '初始化 Danbooru 認證...';

  @override
  String get warmup_loadingTranslation => '載入翻譯資料...';

  @override
  String get warmup_initUnifiedDatabase => '初始化標籤資料庫...';

  @override
  String get warmup_initTagSystem => '初始化標籤系統...';

  @override
  String get warmup_imageEditor => '初始化影像編輯器...';

  @override
  String get warmup_database => '載入最近歷史記錄...';

  @override
  String get warmup_network => '檢查網路連線...';

  @override
  String get warmup_fonts => '預載入字型...';

  @override
  String get warmup_imageCache => '預熱影像快取...';

  @override
  String get warmup_statistics => '載入統計資料...';

  @override
  String get warmup_artistsSync => '同步畫師資料...';

  @override
  String get warmup_subscription => '載入訂閱資訊...';

  @override
  String get warmup_dataSourceCache => '初始化資料來源快取...';

  @override
  String get warmup_galleryFileCount => '掃描圖庫檔案...';

  @override
  String get warmup_cooccurrenceData => '載入標籤共現資料...';

  @override
  String get warmup_group_basicUI => '初始化基礎 UI 服務...';

  @override
  String get warmup_group_basicUI_complete => '基礎 UI 服務就緒';

  @override
  String get warmup_group_dataServices => '初始化資料服務...';

  @override
  String get warmup_group_dataServices_complete => '資料服務就緒';

  @override
  String get warmup_group_networkServices => '初始化網路服務...';

  @override
  String get warmup_group_networkServices_complete => '網路服務就緒';

  @override
  String get warmup_group_cacheServices => '初始化快取服務...';

  @override
  String get warmup_group_cacheServices_complete => '快取服務就緒';

  @override
  String get warmup_cooccurrenceInit => '初始化共現資料...';

  @override
  String get warmup_translationInit => '初始化翻譯資料...';

  @override
  String get warmup_danbooruTagsInit => '初始化 Danbooru 標籤...';

  @override
  String get warmup_dataMigration => '遷移 Hive / Vibe / 圖片資料...';

  @override
  String get warmup_galleryDataSource => '初始化畫廊索引...';

  @override
  String get warmup_checkAndRecoverData => '檢查資料完整性...';

  @override
  String get warmup_group_dataSourceInitialization => '初始化資料來源服務...';

  @override
  String get warmup_group_dataSourceInitialization_complete => '資料來源服務就緒';

  @override
  String warmup_fetchingTags(Object message) {
    return '正在同步標籤：$message';
  }

  @override
  String get warmup_fetchingTagDataFromServer => '正在從伺服器拉取標籤資料...';

  @override
  String get warmup_fetchingGeneralTags => '正在拉取通用標籤...';

  @override
  String get warmup_fetchingCharacterTags => '正在拉取角色標籤...';

  @override
  String get warmup_fetchingCopyrightTags => '正在拉取版權標籤...';

  @override
  String get warmup_fetchingMetaTags => '正在拉取元標籤...';

  @override
  String get resolution_groupNormal => '常規';

  @override
  String get resolution_groupLarge => '大尺寸';

  @override
  String get resolution_groupWallpaper => '桌布';

  @override
  String get resolution_groupSmall => '小尺寸';

  @override
  String get resolution_groupCustom => '自訂';

  @override
  String get resolution_typePortrait => '豎屏';

  @override
  String get resolution_typeLandscape => '橫屏';

  @override
  String get resolution_typeSquare => '方形';

  @override
  String get resolution_typeCustom => '自訂';

  @override
  String get resolution_width => '寬度';

  @override
  String get resolution_height => '高度';

  @override
  String get api_error_429 => '併發限制';

  @override
  String get api_error_429_hint => '請求過於頻繁，請稍後重試（常見於合租帳號）';

  @override
  String get api_error_401 => '認證失敗';

  @override
  String get api_error_401_hint => 'Token 無效或已過期，請重新登入';

  @override
  String get api_error_402 => '餘額不足';

  @override
  String get api_error_402_hint => 'Anlas 餘額不足，請充值後重試';

  @override
  String get api_error_500 => '伺服器錯誤';

  @override
  String get api_error_500_hint => 'NovelAI 伺服器出現問題，請稍後重試';

  @override
  String get api_error_503 => '服務不可用';

  @override
  String get api_error_503_hint => '伺服器正在維護或過載，請稍後重試';

  @override
  String get api_error_timeout => '請求逾時';

  @override
  String get api_error_timeout_hint => '網路連線逾時，請檢查網路後重試';

  @override
  String get api_error_network => '網路錯誤';

  @override
  String get api_error_network_hint => '無法連線到伺服器，請檢查網路';

  @override
  String get drop_processing => '正在解析圖片...';

  @override
  String get characterEditor_clearAll => '清空所有';

  @override
  String get characterEditor_clearAllTitle => '清空所有角色';

  @override
  String get characterEditor_clearAllConfirm => '確定要刪除所有角色嗎？此操作無法復原。';

  @override
  String get characterEditor_nameHint => '輸入角色名稱';

  @override
  String get characterEditor_enabled => '啟用';

  @override
  String get characterEditor_negativePromptHint => '輸入角色的負面提示詞...';

  @override
  String get characterCanvas_title => '角色位置';

  @override
  String get characterCanvas_finishEditing => '完成位置編輯';

  @override
  String get characterCanvas_aiChoice => 'AI 選擇';

  @override
  String get characterCanvas_custom => '自訂';

  @override
  String get characterCanvas_aiHint => 'AI 將自動安排角色位置';

  @override
  String get characterCanvas_dragHint => '拖動錨點設定角色位置，鬆開即生效';

  @override
  String get characterEditor_genderFemale => '女性';

  @override
  String get characterEditor_genderMale => '男性';

  @override
  String get characterEditor_genderOther => '其他';

  @override
  String get characterEditor_addFemale => '女';

  @override
  String get characterEditor_addMale => '男';

  @override
  String get characterEditor_addOther => '其他';

  @override
  String get characterEditor_moveUp => '上移';

  @override
  String get characterEditor_moveDown => '下移';

  @override
  String get toolbar_fullscreenEdit => '全屏編輯';

  @override
  String get characterTooltip_noCharacters => '未配置角色';

  @override
  String get characterTooltip_clickToConfig => '點選按鈕開始配置多人角色';

  @override
  String get characterTooltip_globalAiLabel => '全域 AI 位置:';

  @override
  String get characterTooltip_enabled => '啟用';

  @override
  String get characterTooltip_disabled => '停用';

  @override
  String get characterTooltip_positionAi => 'AI';

  @override
  String get characterTooltip_disabledLabel => '已停用';

  @override
  String get characterTooltip_promptLabel => '正向';

  @override
  String get characterTooltip_negativeLabel => '負面';

  @override
  String get characterTooltip_notSet => '未設定';

  @override
  String characterTooltip_summary(Object total, Object enabled) {
    return '共 $total 個角色 ($enabled 個啟用)';
  }

  @override
  String get characterTooltip_viewFullConfig => '點選檢視完整配置';

  @override
  String get addGroup_displayNameLabel => '顯示名稱（可選）';

  @override
  String get addGroup_targetCategoryLabel => '目標分類';

  @override
  String globalSettings_saveFailed(Object error) {
    return '儲存失敗: $error';
  }

  @override
  String get nav_generate => '生成';

  @override
  String get nav_gallery => '畫廊';

  @override
  String get nav_settings => '設定';

  @override
  String get sync_preparing => '準備同步...';

  @override
  String sync_fetching(Object category) {
    return '正在取得 $category...';
  }

  @override
  String get sync_processing => '正在處理資料...';

  @override
  String get sync_saving => '正在儲存...';

  @override
  String sync_completed(Object count) {
    return '同步完成，共 $count 個標籤';
  }

  @override
  String sync_failed(Object error) {
    return '同步失敗: $error';
  }

  @override
  String sync_extracting(Object poolName) {
    return '正在提取 $poolName 標籤...';
  }

  @override
  String get sync_merging => '正在合併標籤...';

  @override
  String sync_fetching_tags(Object groupName) {
    return '正在取得 $groupName 標籤熱度...';
  }

  @override
  String get sync_filtering => '正在篩選標籤...';

  @override
  String get sync_done => '同步完成';

  @override
  String get time_just_now => '剛剛';

  @override
  String time_minutes_ago(Object n) {
    return '$n分鐘前';
  }

  @override
  String time_hours_ago(Object n) {
    return '$n小時前';
  }

  @override
  String time_days_ago(Object n) {
    return '$n天前';
  }

  @override
  String get time_never_synced => '從未同步';

  @override
  String get vibeParseFailed => '無法解析 Vibe 檔案';

  @override
  String get localGallery_progressiveLoadError => '圖片載入失敗';

  @override
  String get localGallery_unknownError => '未知錯誤';

  @override
  String localGallery_loadFailed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get localGallery_indexingLocalImages => '索引本地圖片中...';

  @override
  String get localGallery_emptyTitle => '暫無本地圖片';

  @override
  String get localGallery_emptySubtitle => '生成的圖片將儲存在此處';

  @override
  String get localGallery_noMatchingResults => '無匹配結果';

  @override
  String get localGallery_title => '本地畫廊';

  @override
  String get localGallery_allImages => '全部圖片';

  @override
  String get localGallery_selectAllResults => '選擇全部';

  @override
  String get localGallery_deselectAllResults => '取消全部';

  @override
  String get localGallery_moveSelected => '移動';

  @override
  String get localGallery_packSelected => '打包';

  @override
  String get localGallery_editMetadata => '編輯';

  @override
  String get localGallery_addToCollection => '收藏';

  @override
  String get localGallery_sortButton => '排序';

  @override
  String get localGallery_sortFieldModified => '修改時間';

  @override
  String get localGallery_sortFieldCreated => '建立時間';

  @override
  String get localGallery_sortFieldName => '檔名';

  @override
  String get localGallery_sortFieldSize => '檔案大小';

  @override
  String get localGallery_sortFieldDimensions => '影像尺寸';

  @override
  String localGallery_aboutColumns(Object count) {
    return '約 $count 列';
  }

  @override
  String get localGallery_columnWidth => '列寬';

  @override
  String get localGallery_thumbnailQualitySd => '標清';

  @override
  String get localGallery_thumbnailQualityHd => '高畫質';

  @override
  String get settings_galleryThumbnailQuality => '本地畫廊清晰度';

  @override
  String get settings_galleryThumbnailQualitySubtitle => '縮圖顯示品質，預設高畫質';

  @override
  String get localGallery_naiOnlyTooltip => '僅顯示 NAI 生成的圖片';

  @override
  String get localGallery_naiVersionFilterTooltip => '按 NAI 模型版本過濾';

  @override
  String get localGallery_masonryViewLabel => '瀑布流';

  @override
  String get localGallery_justifiedViewLabel => '火車流';

  @override
  String localGallery_dateRangeYearMonth(Object year, Object month) {
    return '$year年$month月';
  }

  @override
  String get localGallery_dateRangePrevMonth => '上個月';

  @override
  String get localGallery_dateRangeNextMonth => '下個月';

  @override
  String get localGallery_dateRangeClear => '清除';

  @override
  String localGallery_searchInScope(Object scope) {
    return '搜尋：$scope';
  }

  @override
  String get localGallery_hideCategoryPanel => '隱藏分類面板';

  @override
  String get localGallery_showCategoryPanel => '顯示分類面板';

  @override
  String get localGallery_refreshTooltip => '重新整理畫廊\n\n自動檢測新增/修改的圖片並更新索引';

  @override
  String get localGallery_tagIntersection => '標籤交集';

  @override
  String get localGallery_createCategoryTitle => '新增分類';

  @override
  String get localGallery_newOrImport => '新增/匯入';

  @override
  String get localGallery_importFolder => '匯入資料夾';

  @override
  String get localGallery_createCategoryHint => '請輸入分類名稱';

  @override
  String get localGallery_createCategoryConfirm => '建立';

  @override
  String get localGallery_createSubCategoryTitle => '新增子分類';

  @override
  String get localGallery_showInFolder => '在資料夾中顯示';

  @override
  String get localGallery_promptCopied => 'Prompt 已複製';

  @override
  String get localGallery_seedCopied => 'Seed 已複製';

  @override
  String get localGallery_createCollectionTitle => '新增收藏集';

  @override
  String get localGallery_createCollectionHint => '輸入收藏集名稱';

  @override
  String get localGallery_createCollectionConfirm => '建立';

  @override
  String get localGallery_createCollectionFolderTitle => '新增收藏資料夾';

  @override
  String get localGallery_createCollectionFolderHint => '輸入收藏資料夾名稱';

  @override
  String get localGallery_createCollectionFolderConfirm => '建立';

  @override
  String localGallery_deleteCollectionContent(Object name) {
    return '確定刪除收藏集「$name」？僅移除收藏集條目，不會刪除任何圖片檔案。';
  }

  @override
  String localGallery_deleteCollectionFolderContent(Object name) {
    return '確定刪除收藏資料夾「$name」？資料夾內沒有子項，僅移除資料夾本身。';
  }

  @override
  String get localGallery_deleteCollectionFolderNonEmptyTitle => '資料夾不為空';

  @override
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name) {
    return '收藏資料夾「$name」內還有收藏集或子資料夾，請先移出或刪除其中的子項。';
  }

  @override
  String get localGallery_unfavorite => '取消收藏';

  @override
  String get localGallery_favoriteMenuEmptyCollections => '暫無收藏集，左側 + 建立';

  @override
  String localGallery_confirmDeleteImageContent(Object name) {
    return '確定要刪除圖片「$name」嗎？\n\n圖片會立即從畫廊消失，檔案將在下次啟動時徹底清理（本次會話內可復原）。';
  }

  @override
  String get localGallery_moveTo => '移動到…';

  @override
  String get localGallery_copyTo => '複製到…';

  @override
  String get localGallery_externalSourceMoveConfirmTitle => '移動外部圖庫來源檔案';

  @override
  String localGallery_externalSourceMoveConfirmContent(Object count) {
    return '將移動 $count 張圖片。檔案將從來源資料夾移走，原位置不再保留。是否繼續？';
  }

  @override
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '將移動 $count 張圖片到外部圖庫源分類「$targetName」。檔案將寫入外部來源資料夾。是否繼續？';
  }

  @override
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '將移動 $count 張圖片到外部圖庫源分類「$targetName」。檔案將從原資料夾移走（原位置不再保留），並寫入外部來源資料夾。是否繼續？';
  }

  @override
  String get localGallery_uncategorizedRoot => '未分類（圖庫根）';

  @override
  String get localGallery_externalSourceChip => '外部';

  @override
  String get localGallery_categoryFilterHint => '搜尋分類…';

  @override
  String localGallery_copySuccess(Object count) {
    return '已複製 $count 張圖片';
  }

  @override
  String get localGallery_copyFailed => '複製圖片失敗';

  @override
  String get localGallery_confirmCopyContent => '將把圖片複製到目標資料夾。請確認操作。';

  @override
  String get localGallery_categoryDeleteContent => '確定要刪除此分類嗎？資料夾及其內容將被保留。';

  @override
  String get localGallery_protectedDeleteCategoryTitle => '保護模式：確認刪除分類';

  @override
  String get localGallery_protectedDeleteCategoryContent =>
      '將刪除此分類記錄，資料夾及內容會保留。請再次確認。';

  @override
  String get localGallery_confirmDelete => '確認刪除';

  @override
  String get localGallery_confirmMoveImageTitle => '保護模式：確認移動圖片';

  @override
  String get localGallery_confirmMoveImageContent => '將把圖片移動到目標分類資料夾。請確認不是誤拖曳。';

  @override
  String get localGallery_confirmMove => '確認移動';

  @override
  String get localGallery_imageMovedToCategory => '圖片已移動到分類';

  @override
  String get localGallery_categoriesSynced => '分類已與資料夾同步';

  @override
  String get localGallery_saveDirectoryNotSet => '未設定儲存目錄';

  @override
  String get localGallery_folderNotFound => '資料夾不存在';

  @override
  String localGallery_openFolderFailed(Object error) {
    return '開啟資料夾失敗: $error';
  }

  @override
  String get localGallery_protectedDeleteTitle => '保護模式：再次確認刪除';

  @override
  String localGallery_protectedDeleteImagesContent(Object count) {
    return '將永久刪除 $count 張本地圖片檔案。此操作無法復原。';
  }

  @override
  String get localGallery_protectedBulkMoveTitle => '保護模式：確認批次移動';

  @override
  String localGallery_protectedBulkMoveContent(Object count) {
    return '將移動 $count 張本地圖片檔案到目標資料夾。請確認不是誤操作。';
  }

  @override
  String localGallery_importParamsFailed(Object error) {
    return '匯入參數失敗: $error';
  }

  @override
  String localGallery_protectedDeleteImageContent(Object name) {
    return '將永久刪除圖片「$name」。此操作無法復原。';
  }

  @override
  String get localGallery_saveZipArchive => '儲存壓縮檔';

  @override
  String localGallery_packingImages(Object count) {
    return '正在打包 $count 張圖片...';
  }

  @override
  String localGallery_packedImages(Object count) {
    return '已打包 $count 張圖片';
  }

  @override
  String get localGallery_packFailed => '打包失敗';

  @override
  String get localGallery_imageFileMissing => '圖片檔案不存在';

  @override
  String get localGallery_sentToImageToImage => '圖片已傳送到圖生圖';

  @override
  String localGallery_sendFailed(Object error) {
    return '傳送失敗: $error';
  }

  @override
  String localGallery_sendToKritaFailed(Object error) {
    return '傳送到 Krita 失敗: $error';
  }

  @override
  String get localGallery_sendToImg2Img => '傳送到圖生圖';

  @override
  String get localGallery_sendToStyleTransfer => '傳送到風格遷移';

  @override
  String get localGallery_sendToPreciseReference => '傳送到精準參考';

  @override
  String get localGallery_sendToKrita => '傳送到 Krita';

  @override
  String get localGallery_importImageMetadata => '匯入圖片後設資料';

  @override
  String get localGallery_copyPrompt => '複製 Prompt';

  @override
  String get localGallery_dragToShare => '拖曳以分享';

  @override
  String galleryDragCount(int count) {
    return '$count 張';
  }

  @override
  String get localGallery_moveToRoot => '移至根目錄';

  @override
  String get localGallery_withMetadata => '有後設資料';

  @override
  String get localGallery_skipped => '跳過';

  @override
  String get localGallery_clearFilters => '清除篩選';

  @override
  String get slideshow_of => '/';

  @override
  String get slideshow_play => '播放';

  @override
  String get slideshow_pause => '暫停';

  @override
  String get slideshow_previous => '上一張';

  @override
  String get slideshow_next => '下一張';

  @override
  String get slideshow_exit => '退出 (Esc)';

  @override
  String get slideshow_noImages => '沒有可顯示的圖片';

  @override
  String get slideshow_keyboardHint => '使用 ← → 導航，空格鍵播放/暫停，Esc 退出';

  @override
  String get comparison_noImages => '沒有可顯示的圖片';

  @override
  String get comparison_tooManyImages => '圖片數量過多';

  @override
  String get comparison_maxImages => '最多支援對比4張圖片';

  @override
  String get comparison_close => '關閉對比';

  @override
  String get comparison_zoomHint => '捏合或滾動可獨立縮放';

  @override
  String get comparison_loadError => '載入圖片失敗';

  @override
  String get localGallery_group_today => '今天';

  @override
  String get localGallery_group_yesterday => '昨天';

  @override
  String localGallery_groupImageCount(int count, String formatted) {
    return '$formatted 張';
  }

  @override
  String localGallery_imageCountLabel(int count, String formatted) {
    return '$formatted 張';
  }

  @override
  String get localGallery_selectGroup => '選擇整組';

  @override
  String get localGallery_inspectorTitle => '詳情';

  @override
  String localGallery_inspectorPosition(String index, String total) {
    return '$index / $total';
  }

  @override
  String get localGallery_inspectorEmpty => '選擇一張圖片檢視詳情';

  @override
  String get localGallery_inspectorEmptyHint => '雙擊或按空格鍵開啟大圖';

  @override
  String get localGallery_hideInspector => '收起詳情面板';

  @override
  String get localGallery_showInspector => '顯示詳情面板';

  @override
  String get localGallery_reuseParams => '複用參數';

  @override
  String get localGallery_actionImg2Img => '圖生圖';

  @override
  String get localGallery_actionStyleTransfer => '風格遷移';

  @override
  String get localGallery_actionPreciseReference => '精準參考';

  @override
  String get localGallery_actionSaveReference => '存入參考庫';

  @override
  String get localGallery_actionKrita => 'Krita';

  @override
  String localGallery_selectedImages(String count) {
    return '已選 $count 張';
  }

  @override
  String get localGallery_sortDescending => '降序';

  @override
  String get localGallery_sortAscending => '升序';

  @override
  String get localGallery_moreActions => '更多';

  @override
  String get localGallery_thumbnailSize => '縮圖大小';

  @override
  String get localGallery_naiOnlyChip => '僅 NAI 圖片';

  @override
  String get localGallery_modelLabel => '模型';

  @override
  String get localGallery_allVersions => '全部';

  @override
  String get localGallery_allVariants => '全部變體';

  @override
  String get localGallery_dateRangeChip => '日期範圍';

  @override
  String get localGallery_groupByDay => '按天分組';

  @override
  String get localGallery_groupByMonth => '按月分組';

  @override
  String get localGallery_groupNone => '不分組';

  @override
  String get localGallery_groupModeTooltip => '按時間分組';

  @override
  String get localGallery_sectionLibrary => '資料庫';

  @override
  String get localGallery_sectionCollections => '收藏集';

  @override
  String get localGallery_sectionFolders => '資料夾';

  @override
  String get localGallery_uncategorizedFolder => '未分類資料夾';

  @override
  String localGallery_indexSynced(String count) {
    return '索引已同步 · $count';
  }

  @override
  String localGallery_cannotOpenFolder(Object error) {
    return '無法開啟資料夾: $error';
  }

  @override
  String get localGallery_firstTimeTipTitle => '💡 使用提示';

  @override
  String get localGallery_firstTimeTipContent =>
      '右鍵點選（桌面端）或長按（移動端）圖片可以：\n\n• 複製 Prompt\n• 複製 Seed\n• 檢視完整後設資料';

  @override
  String get localGallery_gotIt => '知道了';

  @override
  String get localGallery_undone => '已復原';

  @override
  String get localGallery_redone => '已重做';

  @override
  String get localGallery_confirmBulkDelete => '確認批次刪除';

  @override
  String localGallery_confirmBulkDeleteContent(Object count) {
    return '確定要刪除選中的 $count 張圖片嗎？\n\n圖片會立即從畫廊消失，檔案將在下次啟動時徹底清理（本次會話內可復原）。';
  }

  @override
  String localGallery_deletedToPool(Object count) {
    return '已刪除 $count 張圖片，下次啟動時徹底清理。';
  }

  @override
  String get localGallery_trashTitle => '刪除池';

  @override
  String get localGallery_trashEmpty => '刪除池是空的';

  @override
  String get localGallery_trashHint => '池內檔案仍在磁碟上，下次啟動時徹底刪除；恢復後立即回到圖庫。';

  @override
  String localGallery_trashCount(Object count) {
    return '$count 項';
  }

  @override
  String get localGallery_trashRestore => '恢復';

  @override
  String get localGallery_trashRestoreAll => '全部恢復';

  @override
  String get localGallery_trashRestoreFailed => '恢復失敗';

  @override
  String localGallery_trashRestored(Object count) {
    return '已恢復 $count 張圖片';
  }

  @override
  String get localGallery_trashDeleteAll => '徹底刪除全部';

  @override
  String localGallery_trashDeleteAllConfirm(Object count) {
    return '將立即物理刪除池內全部 $count 個檔案，不可恢復。';
  }

  @override
  String localGallery_trashDeletedForever(Object count) {
    return '已徹底刪除 $count 個檔案';
  }

  @override
  String get localGallery_trashFileMissing => '檔案已不在磁碟上';

  @override
  String localGallery_movedImages(Object count) {
    return '已移動 $count 張圖片';
  }

  @override
  String get localGallery_moveImagesFailed => '移動圖片失敗';

  @override
  String localGallery_addedToCollection(Object count, Object name) {
    return '已新增 $count 張圖片到集合「$name」';
  }

  @override
  String get localGallery_addToCollectionFailed => '新增圖片到集合失敗';

  @override
  String get localGallery_removeFromCollection => '移出集合';

  @override
  String localGallery_removedFromCollection(Object count, Object name) {
    return '已從集合「$name」移除 $count 張圖片';
  }

  @override
  String get localGallery_notInCollection => '所選圖片不在該集合中';

  @override
  String localGallery_removedFromFavorites(Object count) {
    return '已從「收藏」移除 $count 張圖片';
  }

  @override
  String get localGallery_alreadyInCollection => '所選圖片已在該集合中';

  @override
  String get brushPreset_selectHint => '雙擊選擇此筆刷預設';

  @override
  String get brushPreset_pencil => '鉛筆';

  @override
  String get brushPreset_fine => '細筆';

  @override
  String get brushPreset_standard => '標準筆刷';

  @override
  String get brushPreset_soft => '軟筆刷';

  @override
  String get brushPreset_airbrush => '噴槍';

  @override
  String get brushPreset_marker => '馬克筆';

  @override
  String get brushPreset_thick => '粗筆刷';

  @override
  String get brushPreset_smudge => '塗抹筆刷';

  @override
  String bulkProgress_progress(Object current, Object total) {
    return '正在處理 $current/$total';
  }

  @override
  String bulkProgress_success(Object count) {
    return '$count 項成功';
  }

  @override
  String bulkProgress_failed(Object count) {
    return '$count 項失敗';
  }

  @override
  String get bulkProgress_errors => '錯誤：';

  @override
  String bulkProgress_moreErrors(Object count) {
    return '...還有 $count 個錯誤';
  }

  @override
  String bulkProgress_completed(Object count) {
    return '已完成 $count 項';
  }

  @override
  String bulkProgress_completedWithErrors(Object success, Object failed) {
    return '$success 項成功，$failed 項失敗';
  }

  @override
  String get bulkProgress_title_delete => '刪除圖片中';

  @override
  String get bulkProgress_title_export => '匯出後設資料中';

  @override
  String get bulkProgress_title_metadataEdit => '編輯後設資料中';

  @override
  String get bulkProgress_title_addToCollection => '新增到收集中';

  @override
  String get bulkProgress_title_removeFromCollection => '從集合中移除';

  @override
  String get bulkProgress_title_toggleFavorite => '更新收藏中';

  @override
  String get bulkProgress_title_default => '處理中';

  @override
  String bulkProgress_errorDeleteFailed(String error) {
    return '刪除圖片失敗：$error';
  }

  @override
  String get bulkProgress_errorNoImagesToExport => '沒有可匯出的圖片';

  @override
  String get bulkProgress_errorExportFailed => '匯出失敗';

  @override
  String bulkProgress_errorExportFailedWithDetails(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get bulkProgress_errorNoMetadataChanges => '請至少輸入一個要新增或移除的標籤';

  @override
  String bulkProgress_errorMetadataEditFailed(String error) {
    return '編輯圖片後設資料失敗：$error';
  }

  @override
  String bulkProgress_errorFavoriteFailed(String error) {
    return '更新收藏狀態失敗：$error';
  }

  @override
  String get bulkProgress_errorNoImagesForCollection => '沒有可新增到集合的圖片';

  @override
  String bulkProgress_errorAddToCollectionFailed(String error) {
    return '將圖片新增到集合失敗：$error';
  }

  @override
  String get bulkProgress_errorNothingToUndo => '沒有可復原的操作';

  @override
  String bulkProgress_errorUndoFailed(String error) {
    return '復原失敗：$error';
  }

  @override
  String get bulkProgress_errorNothingToRedo => '沒有可重做的操作';

  @override
  String bulkProgress_errorRedoFailed(String error) {
    return '重做失敗：$error';
  }

  @override
  String get collectionSelect_dialogTitle => '選擇集合';

  @override
  String get collectionSelect_removeTitle => '從集合移除圖片';

  @override
  String collectionSelect_memberCount(Object n) {
    return '選中 $n 張在此集合';
  }

  @override
  String get collectionSelect_noSelectedInCollection => '無選中圖片在此集合';

  @override
  String collectionSelect_memberCountInFavorites(Object n) {
    return '選中 $n 張在此收藏';
  }

  @override
  String get collectionSelect_filterHint => '搜尋集合...';

  @override
  String get collectionSelect_noCollections => '暫無集合';

  @override
  String get collectionSelect_createCollectionHint => '請先建立一個集合';

  @override
  String get collectionSelect_noFilterResults => '沒有找到匹配的集合';

  @override
  String collectionSelect_imageCount(int count) {
    return '$count 張圖片';
  }

  @override
  String get autocomplete_categoryCharacter => '角色';

  @override
  String get autocomplete_categoryCopyright => '版權';

  @override
  String get autocomplete_categoryArtist => '藝術家';

  @override
  String get autocomplete_categoryMeta => '後設資料';

  @override
  String get autocomplete_categoryContributor => '貢獻者';

  @override
  String get autocomplete_categorySpecies => '物種';

  @override
  String get autocomplete_categoryLore => '設定';

  @override
  String get autocomplete_categoryLibrary => '詞庫';

  @override
  String get autocomplete_categoryGeneral => '通用';

  @override
  String get promptToken_webCalibration => '網頁端校準';

  @override
  String get promptToken_prompt => '提示詞';

  @override
  String get promptToken_qualityPreset => '品質預設';

  @override
  String get promptToken_character => '角色';

  @override
  String get promptToken_negativePrompt => '負面提示詞';

  @override
  String get promptToken_negativePreset => '負面預設';

  @override
  String get promptToken_characterNegative => '角色負面';

  @override
  String get common_rename => '重新命名';

  @override
  String get tagLibrary_tags => '標籤';

  @override
  String get settings_network => '網路';

  @override
  String get settings_enableProxy => '啟用代理';

  @override
  String get settings_proxyEnabled => '已啟用';

  @override
  String get settings_proxyDisabled => '直接連線網路';

  @override
  String get settings_proxyTrafficDisclosure =>
      '代理啟用後，NovelAI API 流量（包括認證請求）會通過系統代理或手動代理傳送。只使用你信任的代理。';

  @override
  String get settings_proxyMode => '代理模式';

  @override
  String get settings_proxyModeAuto => '自動檢測系統代理';

  @override
  String get settings_proxyModeManual => '手動配置';

  @override
  String get settings_auto => '自動';

  @override
  String get settings_manual => '手動';

  @override
  String get settings_proxyHost => '代理地址';

  @override
  String get settings_proxyPort => '連接埠';

  @override
  String get settings_proxyNotDetected => '未檢測到系統代理';

  @override
  String get settings_testConnection => '測試連線';

  @override
  String get settings_testConnectionHint => '點選測試代理是否可用';

  @override
  String settings_testSuccess(Object latency) {
    return '連線成功 (${latency}ms)';
  }

  @override
  String settings_testFailed(Object error) {
    return '連線失敗: $error';
  }

  @override
  String get settings_proxyRestartHint => '代理設定已更改，建議重啟應用';

  @override
  String get tagLibrary_addToLibrary => '收藏到詞庫';

  @override
  String get tagLibrary_uncategorized => '未分類';

  @override
  String get tagLibrary_contentPreview => '內容預覽';

  @override
  String get settings_enablePromptWeightScroll => '滾輪調整提示詞權重';

  @override
  String get settings_enablePromptWeightScrollSubtitle =>
      '選中提示詞時，按住所選修飾鍵 + 滾輪調整權重；裸滾輪照常翻頁';

  @override
  String get settings_weightScrollModifierAlt => 'Alt';

  @override
  String get settings_weightScrollModifierCtrl => 'Ctrl';

  @override
  String get settings_weightScrollModifierShift => 'Shift';

  @override
  String get settings_weightScrollModifierNone => '無（舊行為）';

  @override
  String get unit_seconds => '秒';

  @override
  String get settings_notificationSound => '完成音效';

  @override
  String get settings_notificationSoundSubtitle => '僅在視窗失焦時播放生成完成音效';

  @override
  String get settings_notificationCustomSound => '自訂音效';

  @override
  String get settings_notificationSelectSound => '選擇音效';

  @override
  String get settings_notificationResetSound => '恢復預設';

  @override
  String get resetToDefault => '重設為預設';

  @override
  String get metadataImport_title => '選擇要套用的參數';

  @override
  String get metadataImport_promptsSection => '提示詞';

  @override
  String get metadataImport_generationSection => '生成參數';

  @override
  String get metadataImport_selectAll => '全選';

  @override
  String get metadataImport_promptsOnly => '僅提示詞';

  @override
  String get metadataImport_generationOnly => '僅參數';

  @override
  String get metadataImport_clear => '清空';

  @override
  String get metadataImport_prompt => '正向提示詞';

  @override
  String get metadataImport_mainPrompt => '主提示詞';

  @override
  String metadataImport_qualityTagsCount(int count) {
    return '品質詞 ($count個)';
  }

  @override
  String get metadataImport_negativePrompt => '負向提示詞';

  @override
  String get metadataImport_characterPrompts => '多角色提示詞';

  @override
  String metadataImport_characterPromptsCount(int count) {
    return '角色提示詞 ($count個)';
  }

  @override
  String metadataImport_characterIndex(int index, Object text) {
    return '角色$index: $text';
  }

  @override
  String get metadataImport_referenceSection => '參考圖';

  @override
  String metadataImport_countUnit(int count) {
    return '$count個';
  }

  @override
  String metadataImport_preciseReferenceCount(int count) {
    return '精準參考 ($count個)';
  }

  @override
  String metadataImport_vibeDetail(Object name, Object strength, Object info) {
    return '$name (強度 $strength%, 資訊提取 $info%)';
  }

  @override
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  ) {
    return '參考$index: $type (強度 $strength%, 保真 $fidelity%)';
  }

  @override
  String get metadataImport_seed => '種子 (Seed)';

  @override
  String get metadataImport_steps => '步數 (Steps)';

  @override
  String get metadataImport_scale => '提示詞引導';

  @override
  String get metadataImport_size => '尺寸 (Size)';

  @override
  String get metadataImport_sampler => '取樣器 (Sampler)';

  @override
  String get metadataImport_model => '模型 (Model)';

  @override
  String get metadataImport_smea => 'SMEA';

  @override
  String get metadataImport_smeaDyn => 'SMEA Dyn';

  @override
  String get metadataImport_noiseSchedule => '噪聲計劃';

  @override
  String get metadataImport_cfgRescale => '提示詞引導重縮放';

  @override
  String get metadataImport_qualityToggle => '品質標籤';

  @override
  String get metadataImport_ucPreset => 'UC 預設';

  @override
  String get metadataImport_noData => '（無資料）';

  @override
  String metadataImport_selectedCount(int count) {
    return '已選擇 $count 項';
  }

  @override
  String get metadataImport_noDataFound => '未找到 NovelAI 後設資料';

  @override
  String metadataImport_appliedCount(int count) {
    return '已應用 $count 項參數';
  }

  @override
  String get metadataImport_appliedTitle => '後設資料已應用';

  @override
  String get metadataImport_appliedDescription => '以下參數已應用到當前設定：';

  @override
  String get metadataImport_charactersCount => '個角色';

  @override
  String get shortcut_context_global => '全域';

  @override
  String get shortcut_context_generation => '生成頁面';

  @override
  String get shortcut_context_gallery => '畫廊列表';

  @override
  String get shortcut_context_viewer => '圖片檢視器';

  @override
  String get shortcut_context_settings => '設定';

  @override
  String get shortcut_context_input => '輸入框';

  @override
  String get shortcut_action_navigate_to_generation => '生成頁面';

  @override
  String get shortcut_action_navigate_to_local_gallery => '本地畫廊';

  @override
  String get shortcut_action_navigate_to_online_gallery => '線上畫廊';

  @override
  String get shortcut_action_navigate_to_tag_library => '塊庫頁面';

  @override
  String get shortcut_action_navigate_to_statistics => '統計頁面';

  @override
  String get shortcut_action_navigate_to_settings => '設定頁面';

  @override
  String get shortcut_action_generate_image => '生成影像';

  @override
  String get shortcut_action_cancel_generation => '取消生成';

  @override
  String get shortcut_action_clear_prompt => '清空提示詞';

  @override
  String get shortcut_action_toggle_prompt_mode => '切換正/負面模式';

  @override
  String get shortcut_action_open_tag_library => '開啟塊庫';

  @override
  String get shortcut_action_save_image => '儲存影像';

  @override
  String get shortcut_action_upscale_image => '放大影像';

  @override
  String get shortcut_action_copy_image => '複製影像';

  @override
  String get shortcut_action_fullscreen_preview => '全屏預覽';

  @override
  String get shortcut_action_open_params_panel => '開啟參數面板';

  @override
  String get shortcut_action_open_history_panel => '開啟歷史面板';

  @override
  String get shortcut_action_reuse_params => '複用參數';

  @override
  String get shortcut_action_previous_image => '上一張';

  @override
  String get shortcut_action_next_image => '下一張';

  @override
  String get shortcut_action_zoom_in => '放大';

  @override
  String get shortcut_action_zoom_out => '縮小';

  @override
  String get shortcut_action_reset_zoom => '重設縮放';

  @override
  String get shortcut_action_toggle_fullscreen => '全屏切換';

  @override
  String get shortcut_action_close_viewer => '關閉檢視器';

  @override
  String get shortcut_action_toggle_favorite => '收藏切換';

  @override
  String get shortcut_action_copy_prompt => '複製Prompt';

  @override
  String get shortcut_action_reuse_gallery_params => '複用參數';

  @override
  String get shortcut_action_delete_image => '刪除圖片';

  @override
  String get shortcut_action_previous_page => '向上翻一屏';

  @override
  String get shortcut_action_next_page => '向下翻一屏';

  @override
  String get shortcut_action_refresh_gallery => '重新整理';

  @override
  String get shortcut_action_focus_search => '搜尋聚焦';

  @override
  String get shortcut_action_enter_selection_mode => '全選';

  @override
  String get shortcut_action_clear_filter => '清除篩選';

  @override
  String get shortcut_action_toggle_category_panel => '切換分類面板';

  @override
  String get shortcut_action_jump_to_date => '跳轉到日期';

  @override
  String get shortcut_action_open_folder => '開啟資料夾';

  @override
  String get shortcut_action_minimize_to_tray => '最小化到系統匣';

  @override
  String get shortcut_action_quit_app => '退出應用';

  @override
  String get shortcut_action_show_shortcut_help => '顯示快速鍵幫助';

  @override
  String get shortcut_action_toggle_theme => '切換主題';

  @override
  String get shortcut_settings_title => '鍵盤快速鍵';

  @override
  String get shortcut_settings_enable => '啟用快速鍵';

  @override
  String get shortcut_settings_show_badges => '顯示快速鍵標識';

  @override
  String get shortcut_settings_show_in_tooltips => '在提示中顯示';

  @override
  String get shortcut_settings_reset_all => '重設全部為預設';

  @override
  String get shortcut_settings_search => '搜尋快速鍵...';

  @override
  String get shortcut_settings_press_key => '按下按鍵組合...';

  @override
  String get shortcut_help_title => '快速鍵幫助';

  @override
  String get shortcut_help_search => '搜尋快速鍵...';

  @override
  String get shortcut_help_all => '全部';

  @override
  String get shortcut_help_fabTooltip => '快速鍵幫助 (F1)';

  @override
  String get shortcut_editor_recordingInline => '按快速鍵...';

  @override
  String get shortcut_editor_pressEscToCancel => '按 Esc 取消';

  @override
  String get shortcut_editor_clickToRecord => '點選開始錄製';

  @override
  String shortcut_editor_conflictWith(Object action) {
    return '此快速鍵與 \"$action\" 衝突';
  }

  @override
  String get drop_hint => '拖曳圖片到這裡';

  @override
  String get drop_img2img => '圖生圖';

  @override
  String get drop_vibeTransfer => '風格遷移';

  @override
  String get drop_characterReference => '精準參考';

  @override
  String get drop_unsupportedFormat => '不支援的檔案格式';

  @override
  String get drop_addedToImg2Img => '已新增到圖生圖';

  @override
  String get drop_addedToVibe => '已新增到風格遷移';

  @override
  String drop_addedMultipleToVibe(int count) {
    return '已新增 $count 個風格參考';
  }

  @override
  String get drop_addedToCharacterRef => '已新增到精準參考';

  @override
  String get drop_vibeDetected => '檢測到預編碼 Vibe（可節省 2 Anlas）';

  @override
  String get drop_reuseVibe => '複用 Vibe';

  @override
  String get drop_useAsRawImage => '作為原始圖片';

  @override
  String get drop_dragToImg2ImgOrOther => '拖曳到圖生圖或其他區域';

  @override
  String get preciseRef_title => '精準參考';

  @override
  String get preciseRef_subtitle => '將生成繫結到角色或風格參考';

  @override
  String get preciseRef_description => '新增參考圖並設定類型和參數，可同時使用多個參考。';

  @override
  String get preciseRef_addReference => '新增參考圖';

  @override
  String get preciseRef_clearAll => '清空全部';

  @override
  String get preciseRef_remove => '移除';

  @override
  String get preciseRef_referenceType => '參考類型';

  @override
  String get preciseRef_strength => '參考強度';

  @override
  String get preciseRef_fidelity => '保真度';

  @override
  String get preciseRef_v4Only => '此功能需要 V4+ 模型';

  @override
  String get preciseRef_typeCharacter => '角色';

  @override
  String get preciseRef_typeStyle => '風格';

  @override
  String get preciseRef_typeCharacterAndStyle => '角色+風格';

  @override
  String get preciseRef_costHint => '使用精準參考會消耗額外點數';

  @override
  String get preciseRef_costBadge => '消耗點數';

  @override
  String get preciseRef_dropToAdd => '鬆開後新增精準參考';

  @override
  String get preciseRef_dropNoReadableImage => '拖入源未提供可讀取的圖片檔案或圖片連結';

  @override
  String preciseRef_addedCount(int count) {
    return '已新增 $count 個精準參考';
  }

  @override
  String preciseRef_removedCount(int count) {
    return '已刪除 $count 個精準參考';
  }

  @override
  String get vibeLibrary_title => 'Vibe 庫';

  @override
  String get vibeLibrary_uncategorized => '未分類';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '成功匯入 $count 個 Vibe';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return '匯入完成: $success 成功, $failed 失敗';
  }

  @override
  String get vibeLibrary_save => '儲存到庫';

  @override
  String get vibeLibrary_import => '匯入 Vibe';

  @override
  String get vibeLibrary_sendToGeneration => '傳送到生成';

  @override
  String get vibeLibrary_maxVibesReached => '已達到最大數量 (16張)';

  @override
  String get vibeLibrary_bundleReadFailed => '讀取 Bundle 檔案失敗，使用單檔案模式';

  @override
  String categoryError_loadFailed(String error) {
    return '載入分類失敗：$error';
  }

  @override
  String categoryError_syncFailed(String error) {
    return '同步分類失敗：$error';
  }

  @override
  String get categoryError_nameEmpty => '分類名稱不能為空';

  @override
  String get categoryError_parentNotFound => '父分類不存在';

  @override
  String categoryError_createFailed(String error) {
    return '建立分類失敗：$error';
  }

  @override
  String get categoryError_notFound => '分類不存在';

  @override
  String categoryError_renameFailed(String error) {
    return '重新命名分類失敗：$error';
  }

  @override
  String get categoryError_invalidMove => '不能將分類移動到它的子孫分類下';

  @override
  String categoryError_moveFailed(String error) {
    return '移動分類失敗：$error';
  }

  @override
  String get categoryError_hasSubcategories => '該分類包含子分類，請先刪除子分類。';

  @override
  String categoryError_deleteFailed(String error) {
    return '刪除分類失敗：$error';
  }

  @override
  String categoryError_moveImageFailed(String error) {
    return '移動圖片失敗：$error';
  }

  @override
  String categoryError_moveImagesFailed(String error) {
    return '批次移動圖片失敗：$error';
  }

  @override
  String categoryError_reorderFailed(String error) {
    return '重新排序分類失敗：$error';
  }

  @override
  String get vibe_export_title => '匯出 Vibe';

  @override
  String get vibe_selector_recent => '最近使用';

  @override
  String vibe_export_dialogTitle(int count) {
    return '匯出 $count 個 Vibes';
  }

  @override
  String get vibe_export_chooseMethod => '選擇匯出方式';

  @override
  String get vibe_export_asBundle => '打包匯出';

  @override
  String get vibe_export_individually => '逐個匯出';

  @override
  String get vibe_export_noData => '沒有可匯出的資料';

  @override
  String get vibe_export_success => '匯出成功';

  @override
  String get vibe_export_failed => '匯出失敗';

  @override
  String vibe_export_skipped(int count) {
    return '跳過了 $count 個無資料 vibes';
  }

  @override
  String vibe_export_bundleSuccess(int count) {
    return '已匯出 Bundle: $count 個 vibes';
  }

  @override
  String get vibe_export_selectToEmbed => '選擇要嵌入的 vibes';

  @override
  String get vibe_export_pngRequired => '需要 PNG 檔案';

  @override
  String get vibe_export_noEmbeddableData => '沒有可嵌入的資料';

  @override
  String vibe_export_embedSuccess(int count) {
    return '已嵌入 $count 個 vibes 到圖片';
  }

  @override
  String get vibe_export_embedFailed => '嵌入失敗';

  @override
  String get vibe_embedToImage => '嵌入到圖片';

  @override
  String get vibe_import_noEncodingData => '無編碼資料';

  @override
  String get vibe_import_encodingCost => '編碼將消耗 2 Anlas';

  @override
  String get vibe_import_confirmCost => '繼續並消耗 Anlas？';

  @override
  String get vibe_import_encodeNow => '立即編碼 (2 Anlas)';

  @override
  String get vibe_addImageOnly => '僅新增圖片';

  @override
  String get vibe_import_autoSave => '自動儲存到庫';

  @override
  String get vibe_import_encodingFailed => '編碼失敗';

  @override
  String get vibe_import_encodingFailedMessage => 'Vibe 編碼失敗，是否繼續新增未編碼圖片？';

  @override
  String get vibe_import_encodingInProgress => '編碼中...';

  @override
  String get vibe_import_encodingComplete => '編碼完成';

  @override
  String get vibe_import_partialFailed => '部分編碼失敗';

  @override
  String get vibe_import_timeout => '編碼逾時';

  @override
  String get vibe_import_fileParseFailed => '解析檔案失敗';

  @override
  String get vibe_import_fileSelectionFailed => '檔案選擇失敗';

  @override
  String get vibe_import_importFailed => '匯入失敗';

  @override
  String get vibe_saveToLibrary_title => '儲存到庫';

  @override
  String get vibe_saveToLibrary_strength => '參考強度';

  @override
  String get vibe_saveToLibrary_infoExtracted => '資訊提取';

  @override
  String vibe_saveToLibrary_saving(int count) {
    return '正在儲存 $count 個 vibes';
  }

  @override
  String get vibe_saveToLibrary_saveFailed => '儲存到庫失敗';

  @override
  String vibe_saveToLibrary_savingCount(int count) {
    return '正在儲存 $count 個 vibes';
  }

  @override
  String get vibe_saveToLibrary_nameLabel => '名稱';

  @override
  String get vibe_saveToLibrary_nameHint => '輸入 vibe 名稱';

  @override
  String vibe_saveToLibrary_mixed(int saved, int reused) {
    return '已儲存 $saved 個，複用 $reused 個';
  }

  @override
  String vibe_saveToLibrary_saved(int count) {
    return '已儲存 $count 個到庫';
  }

  @override
  String vibe_saveToLibrary_reused(int count) {
    return '從庫複用 $count 個';
  }

  @override
  String get vibe_saveToLibrary_saveAsBundle => '儲存為 Bundle';

  @override
  String vibe_saveToLibrary_saveAsBundleDescription(int count) {
    return '將 $count 個 Vibe 儲存為一個 Bundle';
  }

  @override
  String get vibe_saveToLibrary_tagHint => '輸入標籤後點擊新增';

  @override
  String get vibe_maxReached => '已達到最大數量 (16張)';

  @override
  String vibe_addedCount(int count) {
    return '已新增 $count 個 vibes';
  }

  @override
  String get vibe_statusEncoded => '已編碼';

  @override
  String get vibe_statusEncoding => '編碼中...';

  @override
  String get vibe_statusPendingEncode => '待編碼 (2 Anlas)';

  @override
  String get vibe_encodeDialogTitle => '確認編碼 Vibe';

  @override
  String get vibe_encodeDialogMessage => '是否編碼此圖片以供生成使用？';

  @override
  String get vibe_encodeCostWarning => '此操作將消耗 2 Anlas（點數）';

  @override
  String get vibe_encodeButton => '編碼';

  @override
  String get vibe_encodeSuccess => 'Vibe 編碼成功！';

  @override
  String get vibe_encodeFailed => 'Vibe 編碼失敗，請重試';

  @override
  String vibe_encodeError(String error) {
    return '編碼失敗: $error';
  }

  @override
  String get shortcuts_customize => '自訂快速鍵';

  @override
  String get selection_clear_selection => '清除選區';

  @override
  String get selection_invert_selection => '反轉選區';

  @override
  String get selection_cut_to_layer => '剪下到新圖層';

  @override
  String get selectAll => '全選';

  @override
  String get clearSelection => '清空';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 詳情';

  @override
  String get shortcut_action_vibe_detail_rename => '重新命名';

  @override
  String get tray_show => '顯示視窗';

  @override
  String get tray_exit => '退出';

  @override
  String get settings_shortcutsSubtitle => '自訂鍵盤快速鍵';

  @override
  String get settings_openFolder => '開啟資料夾';

  @override
  String get settings_openFolderFailed => '開啟資料夾失敗';

  @override
  String get settings_vibePathSaved => 'Vibe 庫路徑已儲存';

  @override
  String get settings_selectFolderFailed => '選擇資料夾失敗';

  @override
  String get settings_hivePathSaved => '資料儲存路徑已儲存，重啟後生效';

  @override
  String get settings_restartRequiredTitle => '需要重啟應用';

  @override
  String get settings_changePathConfirm =>
      '更改資料儲存路徑後，需要重啟應用才能生效。\\n\\n新路徑將在下次啟動時生效。是否繼續？';

  @override
  String get settings_resetPathConfirm =>
      '重設資料儲存路徑後，需要重啟應用才能生效。\\n\\n預設路徑將在下次啟動時生效。是否繼續？';

  @override
  String get settings_kritaBridgeEnable => '啟用本機橋接';

  @override
  String get settings_kritaBridgeDisabledText => '預設關閉；開啟後只監聽本機 127.0.0.1';

  @override
  String get settings_kritaBridgeStartingText => '正在啟動本地橋接服務...';

  @override
  String get settings_kritaBridgeListeningText => '等待外部 Agent 或 Krita 連線';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita 外掛已連線';

  @override
  String get settings_kritaBridgeErrorText => '啟動失敗，請檢視錯誤資訊';

  @override
  String get settings_kritaBridgeRegenerateSession => '重生成會話';

  @override
  String get settings_kritaBridgeDiscoveryFile => '發現檔案';

  @override
  String get settings_kritaBridgeWaitingEndpoint => '等待本地 WebSocket 監聽';

  @override
  String settings_kritaBridgeClient(Object client) {
    return '客戶端：$client';
  }

  @override
  String get settings_fontScale => '字型大小';

  @override
  String get settings_fontScale_previewSmall => '光影落在畫布上。';

  @override
  String get settings_fontScale_previewMedium => '色から物語が生まれる。';

  @override
  String get settings_fontScale_previewLarge => 'Let colors tell a story.';

  @override
  String get settings_fontScale_done => '完成';

  @override
  String get settings_historyClickBehavior => '歷史記錄點選行為';

  @override
  String get settings_historyClickBehavior_classic => '經典';

  @override
  String get settings_historyClickBehavior_classicDescription => '單擊歷史圖片直接開啟詳情';

  @override
  String get settings_historyClickBehavior_linked => '官網式聯動';

  @override
  String get settings_historyClickBehavior_linkedDescription =>
      '單擊切換中央預覽，雙擊或長按開啟詳情，並支援左右方向鍵瀏覽';

  @override
  String get settings_outputViewer => '輸出檢視器';

  @override
  String get settings_outputViewer_canvas => '自由畫布';

  @override
  String get settings_outputViewer_canvasDescription =>
      'NAI5 官網式無限畫布：全部生成圖按批鋪開，中鍵/Shift+左鍵平移、Ctrl+滾輪縮放、WASD/f/q 導航';

  @override
  String get settings_outputViewer_simple => '簡單檢視';

  @override
  String get settings_outputViewer_simpleDescription =>
      '經典居中/網格預覽，適合低配置或習慣舊介面的場景';

  @override
  String get settings_canvasLockCamera => '鎖定畫布相機';

  @override
  String get settings_canvasLockCameraDescription =>
      '停用滾輪縮放/平移、拖曳與 WASD 等手動相機輸入；自動選中與跳轉不受影響';

  @override
  String get settings_canvasReducedMotion => '減少畫布動效';

  @override
  String get settings_canvasReducedMotionDescription => '飛行、縮放與慣性改為瞬時切換，降低動畫負擔';

  @override
  String get image_viewDetail => '檢視詳情';

  @override
  String get settings_defaultImagesPath =>
      '預設 (Documents/NAI_Launcher/images/)';

  @override
  String get settings_defaultHivePath => '預設 (./user-data/hive/)';

  @override
  String get settings_protectionFeatures => '保護功能';

  @override
  String get settings_stripMetadataTitle => '複製/拖曳時移除全部後設資料';

  @override
  String get settings_stripMetadataSubtitle =>
      '生成淨化副本，清除 PNG 文本塊、EXIF 與 NAI 隱寫水印，並避免拖曳暴露原始路徑。';

  @override
  String get settings_confirmDangerousActionsTitle => '危險資產操作二次確認';

  @override
  String get settings_confirmDangerousActionsSubtitle =>
      '刪除、移動、批次移動等本地資產操作會額外彈出保護確認。';

  @override
  String get settings_warnExternalImageSendTitle => '傳送到外部服務前提示';

  @override
  String get settings_warnExternalImageSendSubtitle =>
      '把本地圖片傳送到 LLM、NovelAI、ComfyUI 等外部邊界前進行確認。';

  @override
  String get settings_preventOverwriteTitle => '匯出時避免覆蓋已有檔案';

  @override
  String get settings_preventOverwriteSubtitle => '匯出/打包路徑重名時自動編號，避免誤覆蓋原有資產。';

  @override
  String get settings_warnHighAnlasCostTitle => 'Anlas 高消耗警告';

  @override
  String settings_warnHighAnlasCostSubtitle(Object threshold) {
    return '單次生成預計消耗達到 $threshold Anlas 時，生成前彈出確認。';
  }

  @override
  String get settings_highAnlasCostThresholdTitle => 'Anlas 警告閾值';

  @override
  String get settings_setHighAnlasCostThresholdTitle => '設定 Anlas 警告閾值';

  @override
  String get settings_threshold => '閾值';

  @override
  String get settings_highAnlasCostThresholdHelper => '當單次生成預計消耗達到或超過該值時彈出確認。';

  @override
  String get settings_limitGenerationIntervalTitle => '限制生圖頻率';

  @override
  String get settings_limitGenerationIntervalSubtitle =>
      '開啟後，兩次生圖開始時間必須至少間隔設定秒數；冷卻期間生圖按鈕不可點選。';

  @override
  String get settings_generationIntervalTitle => '生圖間隔';

  @override
  String settings_generationIntervalValue(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get settings_setGenerationIntervalTitle => '設定生圖間隔';

  @override
  String get settings_generationIntervalHelper => '可設定 1–3600 秒，從開始執行生圖時計時。';

  @override
  String get settings_generationIntervalJitterTitle => '間隔隨機抖動';

  @override
  String settings_generationIntervalJitterValue(Object percent) {
    return '±$percent%';
  }

  @override
  String get settings_setGenerationIntervalJitterTitle => '設定間隔隨機抖動';

  @override
  String get settings_generationIntervalJitterHelper =>
      '每次冷卻在「基礎間隔 ± 該百分比」內均勻隨機取值，讓生圖節奏不那麼機械。可設 0–50，0 為關閉。';

  @override
  String get settings_confirmExternalSendTitle => '保護模式：確認外部發送';

  @override
  String settings_confirmExternalSendContent(Object count, Object target) {
    return '即將把 $count 張本地圖片傳送到 $target。圖片會離開本地應用邊界，請確認這符合你的預期。';
  }

  @override
  String get settings_confirmExternalSend => '確認傳送';

  @override
  String get settings_highAnlasCostTitle => 'Anlas 消耗提醒';

  @override
  String get settings_continueGeneration => '繼續生成';

  @override
  String get dataSource_syncNow => '立即同步';

  @override
  String get settings_comfyUiEnable => '啟用 ComfyUI 整合';

  @override
  String get settings_comfyUiDisabledSubtitle => '關閉後將隱藏本地超分等 ComfyUI 功能';

  @override
  String get settings_comfyUiServerUrl => '伺服器地址';

  @override
  String get settings_comfyUiConnectionSuccess => '連線成功';

  @override
  String get settings_comfyUiConnectionSuccessFull => 'ComfyUI 連線成功';

  @override
  String settings_comfyUiConnectionFailed(Object error) {
    return '連線失敗: $error';
  }

  @override
  String get settings_comfyUiConnected => '已連線';

  @override
  String get settings_comfyUiDisconnect => '斷開';

  @override
  String get settings_comfyUiNoResponse => '伺服器無回應';

  @override
  String get settings_comfyUiStatusDisconnected => '未連線';

  @override
  String get settings_comfyUiStatusConnecting => '正在連線...';

  @override
  String get settings_comfyUiStatusConnected => '已連線';

  @override
  String get settings_comfyUiStatusError => '連線異常';

  @override
  String get settings_comfyUiCategoryEnhance => '增強/超分';

  @override
  String get settings_comfyUiCategoryImg2Img => '圖生圖';

  @override
  String get settings_comfyUiCategoryInpaint => '重繪';

  @override
  String get settings_comfyUiCategoryTxt2Img => '文生圖';

  @override
  String get settings_comfyUiCategoryCustom => '自訂';

  @override
  String get comfyWorkflow_seedvr2UpscaleName => 'SeedVR2 超分';

  @override
  String get comfyWorkflow_seedvr2UpscaleDescription =>
      '使用 SeedVR2 AI 模型進行超解析度放大，效果優秀';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleName => 'SeedVR2 分塊超分';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleDescription =>
      '使用 SeedVR2TilingUpscaler 分塊放大，降低大圖視訊記憶體壓力';

  @override
  String get comfyWorkflow_modelUpscaleName => 'ComfyUI 普通超分模型';

  @override
  String get comfyWorkflow_modelUpscaleDescription =>
      '使用 ComfyUI UpscaleModelLoader 載入普通超分模型，並用 Lanczos 修正最終倍率';

  @override
  String get comfyWorkflow_rtxUpscaleName => 'RTX 超分';

  @override
  String get comfyWorkflow_rtxUpscaleDescription =>
      '使用 Nvidia RTX Video Super Resolution 節點進行本地放大';

  @override
  String get comfyWorkflowSlot_inputImage => '輸入影像';

  @override
  String get comfyWorkflowSlot_targetShortSide => '目標短邊';

  @override
  String get comfyWorkflowSlot_targetLongSide => '目標長邊';

  @override
  String get comfyWorkflowSlot_upscaleModel => '超分模型';

  @override
  String get comfyWorkflowSlot_randomSeed => '隨機種子';

  @override
  String get comfyWorkflowSlot_outputImage => '輸出影像';

  @override
  String get comfyWorkflowSlot_tileWidth => '圖塊寬度';

  @override
  String get comfyWorkflowSlot_tileHeight => '圖塊高度';

  @override
  String get comfyWorkflowSlot_tileUpscaleResolution => '圖塊超分解析度';

  @override
  String get comfyWorkflowSlot_targetWidth => '目標寬度';

  @override
  String get comfyWorkflowSlot_targetHeight => '目標高度';

  @override
  String get comfyWorkflowSlot_scale => '放大倍數';

  @override
  String get comfyWorkflow_parameters => '參數設定';

  @override
  String get comfyWorkflow_selectImage => '點選選擇影像';

  @override
  String comfyWorkflow_pickImageFailed(Object error) {
    return '選擇影像失敗: $error';
  }

  @override
  String get comfyWorkflow_useResult => '使用結果';

  @override
  String get comfyWorkflow_execute => '執行';

  @override
  String get comfyWorkflow_uploadingImage => '正在上傳影像...';

  @override
  String get comfyWorkflow_queued => '排隊中...';

  @override
  String comfyWorkflow_runningSteps(Object current, Object total) {
    return '處理中 $current/$total';
  }

  @override
  String get comfyWorkflow_processing => '處理中...';

  @override
  String get comfyWorkflow_complete => '執行完成';

  @override
  String comfyWorkflow_imageCount(Object count) {
    return '$count 張影像';
  }

  @override
  String get cacheStats_title => '快取統計';

  @override
  String cacheStats_autoRefreshUpdated(Object time) {
    return '自動重新整理 · 上次更新: $time';
  }

  @override
  String cacheStats_secondsAgo(Object seconds) {
    return '$seconds秒前';
  }

  @override
  String get cacheStats_resetStats => '重設統計';

  @override
  String get cacheStats_statsReset => '統計已重設';

  @override
  String get cacheStats_l1Memory => 'L1 記憶體快取';

  @override
  String get cacheStats_l2Hive => 'L2 Hive 快取';

  @override
  String get cacheStats_l3Sqlite => 'L3 SQLite 資料庫';

  @override
  String get galleryCache_rescanTitle => '重新掃描畫廊';

  @override
  String get galleryCache_rescanContent =>
      '這將執行以下操作：\n\n1. 檢查資料一致性（標記不存在的檔案）\n2. 掃描新檔案和變更的檔案\n3. 重新嘗試歷史上未提取成功的後設資料（含失敗記錄）\n\n此操作不會清空已有資料，也不會刪除圖片檔案。';

  @override
  String get galleryCache_startScan => '開始掃描';

  @override
  String get galleryCache_scanAlreadyRunning => '已有掃描任務在進行中，請等待完成後再試';

  @override
  String get galleryCache_preparing => '準備中...';

  @override
  String get galleryCache_noGalleryFolder => '未設定畫廊目錄';

  @override
  String galleryCache_scanningPhase(Object processed, Object total) {
    return '正在掃描 $processed/$total...';
  }

  @override
  String get galleryCache_scanComplete => '掃描完成';

  @override
  String galleryCache_scanFailed(Object error) {
    return '掃描失敗: $error';
  }

  @override
  String get galleryCache_rescan => '重新掃描';

  @override
  String get galleryCache_rescanSubtitle => '檢查資料一致性、查漏補缺、提取後設資料';

  @override
  String get galleryCache_scanning => '正在掃描...';

  @override
  String get galleryCache_scanAction => '掃描';

  @override
  String get galleryCache_evictThumbnailsTitle => '清理縮圖快取';

  @override
  String get galleryCache_evictThumbnailsSubtitle =>
      '按最近使用淘汰超限的 .thumbs 縮圖（不影響原圖）';

  @override
  String get galleryCache_evictThumbnailsContent =>
      '將按最近使用時間淘汰超出上限的縮圖磁碟快取。\n\n只刪除 .thumbs 目錄內的 .thumb.jpg 縮圖檔案，不會刪除或修改任何原圖；被清理的縮圖會在下次瀏覽時按需重新生成。';

  @override
  String get galleryCache_evictThumbnailsStart => '開始清理';

  @override
  String get galleryCache_evictThumbnailsRunning => '正在清理縮圖快取...';

  @override
  String galleryCache_evictThumbnailsDone(int count, String size) {
    return '已清理 $count 個縮圖，釋放 $size MB';
  }

  @override
  String get galleryCache_evictThumbnailsNone => '縮圖快取未超限，無需清理';

  @override
  String galleryCache_evictThumbnailsFailed(Object error) {
    return '清理縮圖快取失敗: $error';
  }

  @override
  String get workflowImport_title => '匯入 ComfyUI 工作流';

  @override
  String workflowImport_step(Object current, Object title) {
    return '步驟 $current/4: $title';
  }

  @override
  String get workflowImport_stepFile => '選擇工作流檔案';

  @override
  String get workflowImport_stepInfo => '工作流資訊';

  @override
  String get workflowImport_stepSlots => '確認槽位配置';

  @override
  String get workflowImport_stepDone => '完成匯入';

  @override
  String get workflowImport_previous => '上一步';

  @override
  String get workflowImport_next => '下一步';

  @override
  String get workflowImport_finish => '完成匯入';

  @override
  String get workflowImport_defaultName => '自訂工作流';

  @override
  String get workflowImport_fileInstructions =>
      '請選擇 ComfyUI 匯出的 workflow_api.json 檔案。\n\n在 ComfyUI 中，點選選單 → 匯出 (API格式) 即可獲得此檔案。';

  @override
  String workflowImport_nodeCount(Object count) {
    return '$count 個節點';
  }

  @override
  String get workflowImport_reselect => '點選重新選擇';

  @override
  String get workflowImport_selectWorkflowApi => '點選選擇 workflow_api.json';

  @override
  String get workflowImport_invalidTopLevel => '檔案格式無效：頂層應為 JSON 物件';

  @override
  String get workflowImport_noComfyNodes => '未檢測到 ComfyUI 節點，請確認是 API 格式匯出';

  @override
  String workflowImport_readFailed(Object error) {
    return '讀取檔案失敗: $error';
  }

  @override
  String get workflowImport_analysisResult => '自動分析結果';

  @override
  String get workflowImport_inputImageNodes => '輸入影像節點';

  @override
  String get workflowImport_adjustableParams => '可調參數';

  @override
  String get workflowImport_outputNodes => '輸出節點';

  @override
  String get workflowImport_totalNodes => '總節點數';

  @override
  String workflowImport_countUnit(Object count) {
    return '$count 個';
  }

  @override
  String get workflowImport_workflowName => '工作流名稱 *';

  @override
  String get workflowImport_description => '描述';

  @override
  String get workflowImport_category => '分類';

  @override
  String get workflowImport_slotsHint =>
      '勾選需要暴露給 UI 的槽位。輸入/輸出槽位建議保留；不需要使用者調整的參數可以取消勾選。';

  @override
  String get workflowImport_inputSection => '輸入';

  @override
  String get workflowImport_outputSection => '輸出';

  @override
  String get workflowImport_parameterSection => '參數';

  @override
  String get workflowImport_noSlotsWarning =>
      '未檢測到任何可用槽位。該工作流可能無法正常整合。\n請確認工作流中包含 LoadImage 和 SaveImage/SaveImageWebsocket 節點。';

  @override
  String workflowImport_nodeRef(Object node) {
    return '節點 $node';
  }

  @override
  String get workflowImport_confirmTitle => '即將匯入以下工作流';

  @override
  String get workflowImport_name => '名稱';

  @override
  String get workflowImport_inputSlots => '輸入槽位';

  @override
  String get workflowImport_parameterSlots => '參數槽位';

  @override
  String get workflowImport_outputSlots => '輸出槽位';

  @override
  String get workflowImport_afterImportHint => '匯入後可在生成介面的 ComfyUI 工作流列表中使用。';

  @override
  String workflowImport_success(Object name) {
    return '工作流“$name”匯入成功';
  }

  @override
  String get shortcut_settings_help => '檢視快速鍵幫助';

  @override
  String get shortcut_settings_show_in_menus => '在選單中顯示';

  @override
  String shortcut_settings_defaultShortcut(Object shortcut) {
    return '預設: $shortcut';
  }

  @override
  String get shortcut_settings_unassigned => '未設定';

  @override
  String get shortcut_settings_no_matches => '未找到匹配的快速鍵';

  @override
  String get shortcut_settings_reset_all_title => '重設所有快速鍵';

  @override
  String get shortcut_settings_reset_all_confirm =>
      '確定要將所有快速鍵重設為預設設定嗎？此操作不可復原。';

  @override
  String get shortcut_settings_reset_to_default => '重設為預設';

  @override
  String get toast_previewUpdated => '預覽圖已更新';

  @override
  String toast_styleReferenceLimit(Object max) {
    return '風格參考已達上限 ($max 張)';
  }

  @override
  String get toast_noValidMaskIgnored => '沒有檢測到有效遮罩，儲存結果已忽略。';

  @override
  String get toast_kritaBusy => 'Krita Bridge 正在生成，請等待當前任務結束';

  @override
  String get toast_kritaNotConnected => 'Krita 未連線，請先在設定中啟用橋接並連線外掛';

  @override
  String get toast_sentToKrita => '圖片已傳送到 Krita';

  @override
  String get toast_kritaUnsupportedImageFormat => '圖片格式無法傳送到 Krita，請換用常見圖片格式';

  @override
  String get toast_dropNoReadableImageOrVibe => '拖入源未提供可讀取的圖片或 Vibe 檔案';

  @override
  String get toast_contentCannotBeEmpty => '內容不能為空';

  @override
  String get toast_addedToLibrary => '已新增到詞庫';

  @override
  String toast_addFailed(Object error) {
    return '新增失敗: $error';
  }

  @override
  String get toast_libraryNotLoaded => '詞庫未載入';

  @override
  String get toast_noValidTagContent => '沒有有效的標籤內容';

  @override
  String get toast_allTagsAlreadyExist => '所有標籤已存在於詞庫中';

  @override
  String get toast_noAddableTags => '沒有可新增的標籤';

  @override
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped) {
    return '已新增 $added 個標籤，跳過 $skipped 個重複標籤';
  }

  @override
  String get toast_saveDirNotSet => '未設定儲存目錄';

  @override
  String toast_savedTo(Object path) {
    return '已儲存到 $path';
  }

  @override
  String get toast_tagAlreadyExists => '標籤已存在';

  @override
  String get toast_nameRequired => '請輸入名稱';

  @override
  String get toast_savedToVibeLibrary => '已儲存到 Vibe 庫';

  @override
  String get toast_saveBundleFailed => '儲存組合失敗';

  @override
  String get toast_saveEntryFailed => '儲存條目失敗';

  @override
  String get toast_imageDataUnavailable => '影像資料不可用，無法複製';

  @override
  String get toast_characterPromptCopied => '角色提示詞已複製';

  @override
  String toast_copiedTitle(Object title) {
    return '$title已複製';
  }

  @override
  String get toast_unreadableDroppedImageSource => '拖入源未提供可讀取的圖片檔案或圖片連結';

  @override
  String toast_appendedStyleReferences(Object count) {
    return '已追加 $count 個風格參考';
  }

  @override
  String get toast_appendedPreencodedVibe => '已追加 1 個風格參考（複用預編碼 Vibe）';

  @override
  String get toast_addedPreencodedVibe => '已新增風格參考（複用預編碼 Vibe，節省 2 Anlas）';

  @override
  String toast_vibesMissingEncoding(Object count) {
    return '$count 個 Vibe 缺少編碼資料，無法儲存';
  }

  @override
  String toast_savedBundle(Object count) {
    return '已儲存 Bundle ($count 個 Vibe)';
  }

  @override
  String toast_extractMetadataFailed(Object error) {
    return '提取後設資料失敗: $error';
  }

  @override
  String toast_processImageFailed(Object error) {
    return '處理圖片失敗: $error';
  }

  @override
  String get toast_savePreviewFailed => '儲存預覽圖失敗';

  @override
  String get common_justNow => '剛剛';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes分鐘前';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours小時前';
  }

  @override
  String get common_saving => '儲存中...';

  @override
  String get common_expand => '展開';

  @override
  String get common_collapse => '收起';

  @override
  String get detail_parsingMetadata => '正在解析後設資料...';

  @override
  String get detail_noMetadata => '此圖片無後設資料';

  @override
  String get detail_metadata => '後設資料';

  @override
  String get detail_modifiedTime => '修改時間';

  @override
  String get detail_fileSize => '檔案大小';

  @override
  String get detail_noContent => '(無內容)';

  @override
  String get saveBlock_title => '儲存為塊';

  @override
  String get saveBlock_nameLabel => '塊標題';

  @override
  String get saveBlock_nameHint => '輸入塊標題';

  @override
  String get saveBlock_nameRequired => '請輸入塊標題';

  @override
  String get saveBlock_selectContent => '請選擇要儲存的內容';

  @override
  String get saveBlock_negativeSuffix => '負向';

  @override
  String get saveBlock_saved => '已儲存到塊庫';

  @override
  String detail_copyLabel(Object label) {
    return '複製$label';
  }

  @override
  String get comfyImport_detectedTitle => '檢測到 ComfyUI 多角色提示詞';

  @override
  String comfyImport_characterList(Object count) {
    return '角色列表 ($count)';
  }

  @override
  String get comfyImport_usePositionInfo => '使用位置資訊';

  @override
  String get comfyImport_usePositionInfoSubtitle => '將 ComfyUI 區域對應為 NAI 角色位置';

  @override
  String comfyImport_convertCharacters(Object count) {
    return '轉換 $count 個角色';
  }

  @override
  String get comfyImport_syntaxCouple => 'COUPLE 語法';

  @override
  String get comfyImport_syntaxAndMask => 'AND+MASK 語法';

  @override
  String get comfyImport_syntaxPipe => '豎線格式';

  @override
  String get comfyImport_syntaxUnknown => '未知語法';

  @override
  String get comfyImport_globalPrompt => '全域提示詞';

  @override
  String get checkForUpdate => '檢查更新';

  @override
  String get neverChecked => '從未檢查';

  @override
  String lastCheckedAt(Object time) {
    return '上次檢查: $time';
  }

  @override
  String get includePrereleaseUpdates => '包含預發行版本';

  @override
  String get includePrereleaseUpdatesDescription => '檢查更新時包含 beta/alpha 版本';

  @override
  String get updateAvailable => '發現新版本';

  @override
  String get updateChecking => '正在檢查更新...';

  @override
  String get updateDownloading => '正在下載更新...';

  @override
  String get updateInstalling => '正在啟動安裝器...';

  @override
  String get updateUpToDate => '已是最新版本';

  @override
  String get updateError => '檢查更新失敗';

  @override
  String get currentVersion => '當前版本';

  @override
  String get latestVersion => '最新版本';

  @override
  String get releaseNotes => '更新日誌';

  @override
  String updateDownloadingProgress(Object percent) {
    return '正在下載更新包：$percent%';
  }

  @override
  String updateDownloadSizeSpeed(Object received, Object total, Object speed) {
    return '$received / $total · $speed';
  }

  @override
  String get updateDownloaded => '更新包已就緒';

  @override
  String updateDownloadedHint(Object version) {
    return '新版本 v$version 已下載並通過校驗。安裝將關閉應用，完成後會自動重啟。';
  }

  @override
  String get updateInstallAndRestart => '安裝並重啟';

  @override
  String get updateInstallNow => '立即安裝';

  @override
  String get updateInstallLater => '稍後安裝';

  @override
  String get updateDownload => '下載更新';

  @override
  String get updateDownloadCancelled => '已取消下載，稍後可繼續';

  @override
  String get updateDownloadFailed => '下載更新失敗';

  @override
  String get updateInstallFailed => '安裝更新失敗';

  @override
  String get updateInstallingHint => '安裝程式已啟動，應用即將關閉並自動完成更新。';

  @override
  String get remindMeLater => '4 小時後提醒';

  @override
  String updateNoticeAvailable(Object version) {
    return '新版本 v$version 可用';
  }

  @override
  String get updateNoticeAvailableSubtitle => '可在應用內下載並自動完成更新';

  @override
  String get updateNoticeManualSubtitle => '當前平臺需要前往 Release 頁面手動更新';

  @override
  String updateNoticeReady(Object version) {
    return '新版本 v$version 已準備好';
  }

  @override
  String get updateNoticeReadySubtitle => '更新包已校驗，重啟即可安裝';

  @override
  String get updateNoticeFailed => '上次更新沒有完成';

  @override
  String get updateViewDetails => '檢視更新';

  @override
  String updateSettingsAvailable(Object version) {
    return '發現 v$version，點選檢視更新內容';
  }

  @override
  String updateSettingsReady(Object version) {
    return 'v$version 已下載，點選安裝';
  }

  @override
  String get goToDownload => '前往下載';

  @override
  String get cannotOpenUrl => '無法開啟連結';

  @override
  String get model3d_editorTitle => '3D 模型圖層';

  @override
  String get model3d_modeTransform => '變換';

  @override
  String get model3d_modePose => '姿勢';

  @override
  String get model3d_gizmoTranslate => '移動';

  @override
  String get model3d_gizmoRotate => '旋轉';

  @override
  String get model3d_gizmoScale => '縮放';

  @override
  String get model3d_replaceConfirm => '替換當前模型？未應用的姿勢將丟失。';

  @override
  String get model3d_discardConfirm => '放棄未應用的修改？';

  @override
  String get model3d_missingModel => '模型檔案已丟失，可重新匯入';

  @override
  String get model3d_loadError => '模型載入失敗';

  @override
  String get model3d_light => '光照';

  @override
  String get model3d_addLayerTooltip => '新增 3D 模型圖層';

  @override
  String get nav_preciseRefLibrary => '精準參考庫';

  @override
  String preciseRefLib_saved(String name) {
    return '已存入精準參考庫：$name';
  }

  @override
  String get preciseRefLib_savedHint => '可在精準參考庫中編輯參數';

  @override
  String get preciseRefLib_imageMissing => '原圖檔案丟失';

  @override
  String get preciseRefLib_invalidImage => '無法識別圖片格式，或圖片檔案已經損壞';

  @override
  String preciseRefLib_importedCount(int count) {
    return '已匯入 $count 張圖片';
  }

  @override
  String preciseRefLib_importFailed(String error) {
    return '儲存到精準參考庫失敗：$error';
  }

  @override
  String preciseRefLib_importFailedCount(int count) {
    return '$count 張圖片未能匯入精準參考庫';
  }

  @override
  String get preciseRefLib_fromLibrary => '從庫匯入';

  @override
  String get preciseRefLib_saveCurrentToLibrary => '儲存到庫';

  @override
  String preciseRefLib_saveCurrentCount(int count) {
    return '已儲存 $count 張到精準參考庫';
  }

  @override
  String get img2img_fromPreciseRefLibrary => '從精準參考庫匯入';

  @override
  String get localGallery_saveToPreciseRefLibrary => '儲存到精準參考庫';

  @override
  String get drop_saveToPreciseRefLibrary => '存入精準參考庫';

  @override
  String get common_enabled => '已啟用';

  @override
  String get common_disabled => '已停用';

  @override
  String bulkAction_selectedCount(int count) {
    return '已選擇 $count 項';
  }

  @override
  String get comfyTask_errorConnectionFailed => '無法連線到 ComfyUI 伺服器';

  @override
  String get comfyTask_errorConnectionUnavailable => 'ComfyUI 連線不可用';

  @override
  String get comfyTask_errorExecutionFailedGeneric => 'ComfyUI 執行失敗';

  @override
  String comfyTask_errorExecutionFailed(String error) {
    return 'ComfyUI 執行失敗：$error';
  }

  @override
  String get comfyTask_errorTimeout => 'ComfyUI 任務已在 10 分鐘後逾時';

  @override
  String comfyTask_errorWorkflowNotFound(String workflowId) {
    return '未找到工作流：$workflowId';
  }

  @override
  String get comfyWorkflowSlot_vaeEncodeTileSize => 'VAE 編碼分塊大小';

  @override
  String get comfyWorkflowSlot_vaeDecodeTileSize => 'VAE 解碼分塊大小';

  @override
  String get comfyWorkflowSlot_blocksToSwap => '換出塊數量';

  @override
  String get comfyWorkflowSlot_swapIoComponents => '換出輸入輸出元件';

  @override
  String localGallery_firstIndexHint(int count) {
    return '檢測到 $count 張圖片。首次建立索引可能需要幾分鐘，期間仍可正常使用應用。';
  }

  @override
  String get localGallery_errorPermissionDenied => '無法存取圖片資料夾，請檢查資料夾權限。';

  @override
  String localGallery_errorScanFailed(String error) {
    return '掃描圖片失敗：$error';
  }

  @override
  String localGallery_errorInitializationFailed(String error) {
    return '初始化圖庫失敗：$error';
  }

  @override
  String get localGallery_errorServiceInitializing => '圖庫服務正在初始化，請稍後重試。';

  @override
  String localGallery_errorDatabaseFailed(String error) {
    return '圖庫資料庫錯誤：$error';
  }

  @override
  String localGallery_errorRefreshFailed(String error) {
    return '重新整理圖庫失敗：$error';
  }

  @override
  String localGallery_errorFilterFailed(String error) {
    return '應用圖庫篩選條件失敗：$error';
  }

  @override
  String localGallery_errorFavoriteFailed(String error) {
    return '更新收藏狀態失敗：$error';
  }

  @override
  String localGallery_errorRebuildFailed(String error) {
    return '重建圖庫索引失敗：$error';
  }

  @override
  String get common_optional => '可選';

  @override
  String get common_emptyValue => '（空）';

  @override
  String get common_clickToRetry => '點選重試';

  @override
  String get common_opening => '正在開啟...';

  @override
  String get common_swap => '交換';

  @override
  String get addToLibrary_displayNameHint => '輸入便於識別此條目的名稱';

  @override
  String get addToLibrary_tagHint => '輸入標籤並按 Enter 新增';

  @override
  String get drop_saveVibeBundle => '儲存 Vibe Bundle';

  @override
  String get vibe_import_overwriteOriginalParams => '直接替換原 Vibe 參數';

  @override
  String vibe_import_overwriteOriginalParamsHint(String name) {
    return '僅覆蓋 $name 的庫內參數，預設不勾選';
  }

  @override
  String vibe_import_reencodeFailed(String name) {
    return 'Vibe 重新編碼失敗: $name';
  }

  @override
  String galleryScan_failed(int count) {
    return '失敗 $count';
  }

  @override
  String get galleryScan_organizingGallery => '正在整理圖庫';

  @override
  String get galleryScan_processing => '處理中';

  @override
  String imagePicker_dropReadFailed(String error) {
    return '讀取拖入圖片失敗: $error';
  }

  @override
  String get imagePicker_dropNoReadableImage => '拖入源未提供可讀取的圖片檔案或圖片連結';

  @override
  String get imagePicker_fileDataUnavailable => '無法讀取檔案資料';

  @override
  String imagePicker_fileSelectionFailed(String error) {
    return '選擇檔案失敗: $error';
  }

  @override
  String imagePicker_directorySelectionFailed(String error) {
    return '選擇目錄失敗: $error';
  }

  @override
  String get editor_shiftEdges => '擴展邊緣';

  @override
  String get editor_edgeLeft => '左';

  @override
  String get editor_edgeRight => '右';

  @override
  String get editor_edgeTop => '上';

  @override
  String get editor_edgeBottom => '下';

  @override
  String get editor_enterNumber => '請輸入數字';

  @override
  String get onlineGallery_videoLoadFailed => '影片載入失敗';

  @override
  String get vibe_releaseToAddStyleReference => '鬆開後新增風格參考';

  @override
  String router_pageNotFound(String error) {
    return '頁面未找到: $error';
  }

  @override
  String get autocomplete_resultLimit => '結果數量';

  @override
  String get autocomplete_relatedTagsTitle => '標籤擴展';

  @override
  String get autocomplete_relatedTagsSubtitle => 'Ctrl+單擊搜尋本地標籤；Ctrl+拖選檢視關聯標籤';

  @override
  String get tagExpansion_searchHint => '搜尋標籤或別名';

  @override
  String get tagExpansion_relatedTitle => '關聯標籤';

  @override
  String get tagExpansion_empty => '輸入詞語搜尋本地標籤';

  @override
  String get tagExpansion_noResults => '沒有找到本地標籤';

  @override
  String get tagExpansion_insert => '插入標籤';

  @override
  String get tagExpansion_showRelated => '檢視關聯標籤';

  @override
  String get tagExpansion_localOnly => '僅本地';

  @override
  String get tagExpansion_popularSource => '本地常用標籤';

  @override
  String get tagExpansion_tabComplete => 'Tab 補全：';

  @override
  String get tagExpansion_wikiTitle => '標籤小百科';

  @override
  String get tagExpansion_wikiUnavailable => '本地暫未收錄這個標籤的釋義。';

  @override
  String get autocomplete_cooccurrence => '離線相關標籤庫';

  @override
  String autocomplete_entryCount(int count) {
    return '$count 條記錄';
  }

  @override
  String get autocomplete_clearDanbooruCache => '清除 Danbooru 快取';

  @override
  String get autocomplete_clearAiCache => '清除 AI 漢化快取';

  @override
  String autocomplete_cacheCleared(int count) {
    return '已清除 $count 條快取';
  }

  @override
  String get autocomplete_baseCatalog => '基礎 Danbooru 詞庫';

  @override
  String autocomplete_catalogStatus(String count, String version) {
    return '$count 個標籤 · 資料版本 $version';
  }

  @override
  String get promptBlockLibrary_allBlocks => '全部塊';

  @override
  String get promptBlockLibrary_rootFolder => '根目錄 / 未分類';

  @override
  String get promptBlockLibrary_unnamedBlock => '未命名塊';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '使用 $count 次';
  }

  @override
  String get promptBlockPill_missing => '塊已刪除';

  @override
  String get promptBlockPill_unknown => '失效塊';

  @override
  String get promptBlockLibrary_unnamedFolder => '未命名資料夾';

  @override
  String promptBlockLibrary_deleteCollectionConfirm(String name) {
    return '確定要刪除收藏集「$name」嗎？其中的塊不會被刪除，只會移出該收藏集。';
  }

  @override
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name) {
    return '確定要刪除收藏資料夾「$name」嗎？其中的收藏集與子資料夾會一併刪除，塊本體不受影響。';
  }

  @override
  String get promptBlockLibrary_blockTitle => '標題';

  @override
  String get promptBlockLibrary_titleHint => '塊標題';

  @override
  String get promptBlockLibrary_folder => '資料夾';

  @override
  String get promptBlockLibrary_settingsApplied => '塊設定已匯入當前畫面';

  @override
  String get promptBlockLibrary_settingsIncompatible => '塊設定與目標模型不相容，未匯入任何參數。';

  @override
  String get promptBlockLibrary_deleted => '已刪除';

  @override
  String get promptBlockLibrary_multiSelect => '多選';

  @override
  String get promptBlockLibrary_exitMultiSelect => '退出多選';

  @override
  String promptBlockLibrary_selectedCount(int count) {
    return '已選 $count 項';
  }

  @override
  String get promptBlockLibrary_selectAllVisible => '全選';

  @override
  String get promptBlockLibrary_clearSelection => '清空選擇';

  @override
  String get promptBlockLibrary_empty => '還沒有提示詞塊';

  @override
  String get promptBlockLibrary_noSearchResults => '沒有匹配的塊';

  @override
  String promptBlockLibrary_deleteFolderTitle(Object name) {
    return '刪除資料夾“$name”？';
  }

  @override
  String get promptBlockLibrary_deleteFolderDescription =>
      '請選擇如何處理此資料夾及其子資料夾中的塊。';

  @override
  String get promptBlockLibrary_moveContentsToRoot => '將內容移到根目錄';

  @override
  String get promptBlockLibrary_moveContentsToFolder => '將內容移到其他資料夾';

  @override
  String get promptBlockLibrary_destinationFolder => '目標資料夾';

  @override
  String get promptBlockLibrary_deleteContents => '刪除內容';

  @override
  String get promptBlockLibrary_deleteContentsWarning => '這會永久刪除整個資料夾樹中的所有塊。';

  @override
  String get promptBlockLibrary_exportLibraryBackup => '匯出庫備份…';

  @override
  String get promptBlockLibrary_importTxtTitle => '選擇 TXT 檔案';

  @override
  String promptBlockLibrary_txtImportDone(int created, int skipped) {
    return '匯入 $created 個塊，跳過 $skipped 個已有來源';
  }

  @override
  String get promptBlockLibrary_curationTitle => '從資料夾匯入';

  @override
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  ) {
    return '共 $total 個 TXT：新增 $created · 未變更 $skipped · 已變更 $changed';
  }

  @override
  String promptBlockLibrary_curationLocalModifiedHint(int count) {
    return '其中 $count 個塊匯入後手動修改過，更新會覆蓋本地修改';
  }

  @override
  String get promptBlockLibrary_curationUpdateChanged => '用檔案內容更新已變更的塊';

  @override
  String get promptBlockLibrary_curationEmpty => '所選資料夾中沒有 TXT 檔案';

  @override
  String promptBlockLibrary_curationDone(
    int created,
    int updated,
    int skipped,
  ) {
    return '匯入完成：新增 $created · 更新 $updated · 跳過 $skipped';
  }

  @override
  String get promptBlockLibrary_curationNew => '新增';

  @override
  String get promptBlockLibrary_curationUnchanged => '未變更';

  @override
  String get promptBlockLibrary_curationChanged => '已變更';

  @override
  String get promptBlockLibrary_curationLocalModified => '本地已修改';

  @override
  String get promptBlockLibrary_libraryImportTitle => '選擇庫備份檔案';

  @override
  String promptBlockLibrary_importFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => '來源檔案';

  @override
  String get promptBlockLibrary_importedAt => '匯入時間';

  @override
  String get promptBlockPalette_tooltip => '積木';

  @override
  String get promptBlockPalette_emptyHint =>
      '把常用的提示詞塊或翻譯塊拖進來收納；用時點一下插到游標處，或直接拖進提示詞框。';

  @override
  String get promptBlockPalette_remove => '從積木移除';

  @override
  String get promptBlockPalette_clearAll => '清空積木';

  @override
  String get promptBlockPalette_clearAllArmed => '再點一次確認清空';

  @override
  String promptBlockPalette_removeSelected(int count) {
    return '移除選中的 $count 個塊';
  }

  @override
  String get nav_styleExplore => '畫風探索';

  @override
  String get styleExplore_operationFailed => '操作失敗';

  @override
  String get styleExplore_discardChangesTitle => '放棄未儲存的修改？';

  @override
  String get styleExplore_discardChangesMessage => '當前工作區有未儲存的修改，繼續將丟棄這些修改。';

  @override
  String get styleExplore_discardChangesConfirm => '繼續並丟棄';

  @override
  String styleExplore_manualRunName(String time) {
    return '手動候選 $time';
  }

  @override
  String get styleExplore_runBusy => '生成進行中，稍後再試';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已存為塊「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所選候選沒有可儲存的畫師串或正向提示詞';

  @override
  String get promptBlockEditor_library => '塊庫';

  @override
  String get promptBlockPicker_title => '選擇塊';

  @override
  String get promptBlockLibrary_selectImage => '選擇圖片';

  @override
  String get promptBlockLibrary_adjustThumbnailTitle => '調整預覽圖顯示範圍';

  @override
  String get promptBlockLibrary_dragToMove => '拖曳移動，滾輪或雙指縮放';

  @override
  String get promptBlockLibrary_addToLibrary => '收藏到塊庫';

  @override
  String get promptBlockLibrary_contentPreview => '內容預覽';

  @override
  String get promptBlockLibrary_confirmAdd => '確認收藏';

  @override
  String get promptBlockLibrary_saveToLibrary => '儲存到塊庫';

  @override
  String get promptBlockLibrary_droppedImage => '拖入圖片';

  @override
  String get promptBlockLibrary_createBlockFromImage => '建立新塊';

  @override
  String get promptBlockLibrary_createBlockFromImageSubtitle => '從圖片建立新塊';

  @override
  String promptBlockLibrary_promptExtracted(Object prompt) {
    return '提示詞已提取: \"$prompt\"';
  }

  @override
  String get promptBlockLibrary_updateExistingThumbnail => '更新現有塊預覽圖';

  @override
  String get promptBlockLibrary_updateExistingThumbnailSubtitle => '選擇塊並替換其預覽圖';

  @override
  String subscriptionExpiresOn(String date) {
    return '到期 $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '剩 $days 天';
  }

  @override
  String get subscriptionExpired => '已過期';

  @override
  String get subscriptionGracePeriod => '寬限期';

  @override
  String get subscriptionTierNone => '無訂閱';

  @override
  String get settings_modelsAndInterfaces => '模型與介面';

  @override
  String get tips_kind_guide => '提示';

  @override
  String get tips_kind_trick => '過來人';

  @override
  String get tips_kind_wolf => '狼';

  @override
  String tips_hint(String label, String tip) {
    return '$label：$tip';
  }

  @override
  String get tips_studio_guide_1 =>
      '寫好提示詞，按 Ctrl+Enter 就能生成。生成的圖會在這塊畫布上一批批鋪開：中鍵或 Shift+左鍵拖動平移，Ctrl+滾輪縮放，WASD 也能用來導航。';

  @override
  String get tips_studio_guide_2 =>
      '常用的畫師串、品質詞和構圖描述，寫一次存成塊，下次從塊庫直接拉進來。塊不只是複製貼上：它可以設成固定、順序或隨機抽取，每次生成換一種組合。';

  @override
  String get tips_studio_guide_3 =>
      '隨機塊抽到一組特別滿意的結果？鎖定它，再去重抽別的塊。鎖住的內容不會變，沒鎖的照常隨機——適合「這個姿勢留著，衣服再換幾套」。';

  @override
  String get tips_studio_guide_4 =>
      '把一張圖拖進視窗，會問你想怎麼用：圖生圖、風格遷移、精準參考，或者只提取它的提示詞和參數。帶著 NovelAI 後設資料的圖，一拖就能看到當時是怎麼寫的。';

  @override
  String get tips_studio_guide_5 =>
      '角色框本質上是定位框。除了人物，你也可以放一隻貓、一盞燈、一塊招牌；把定位切到「自訂」，在預覽圖上拖動錨點，告訴模型它該出現在哪裡。';

  @override
  String get tips_studio_guide_6 =>
      '選中一段提示詞，按住 Alt 滾動滾輪就能調權重。不按 Alt 時滾輪只是正常翻頁，不會誤改權重。修飾鍵可以在設定裡換成 Ctrl。';

  @override
  String get tips_studio_guide_7 =>
      '按 F1 隨時開啟快速鍵幫助。Ctrl+1、Ctrl+2、Ctrl+3 在生成頁、本地畫廊和線上畫廊之間切換，Ctrl+, 開啟設定。所有快速鍵都能在設定裡改成你順手的組合。';

  @override
  String get tips_studio_guide_8 =>
      '擔心一不小心花掉一大筆 Anlas？在設定裡開啟「Anlas 高消耗警告」，單次預計消耗超過你設定的數值時，生成前會先問你一句。';

  @override
  String get tips_studio_trick_1 =>
      '種子決定了這張圖「抽」到什麼。參數和種子都不變，出來的就是同一張。所以想復現神圖，記得把種子一起留下；想換運氣，就別再盯著那個種子了。';

  @override
  String get tips_studio_trick_2 =>
      '複用預編碼過的 Vibe 不用再花 2 Anlas。2 Anlas 聽起來不多，但你一天會用幾次 Vibe，自己心裡有數。';

  @override
  String get tips_studio_trick_3 =>
      '負面提示詞不是許願池。寫一百遍 bad hands，不如把正面裡的手部動作寫清楚。那排每次都要寫的負面詞，交給負面預設去管就好。';

  @override
  String get tips_studio_trick_4 =>
      '畫師串不是越長越好。加到第十個以後，模型多半已經分不清你到底想要誰的筆觸了。不如把它們拆成幾個塊，用隨機抽取輪流上場。';

  @override
  String get tips_studio_trick_5 =>
      '一次點擊發幾次請求、每次出幾張，是兩個不同的數。按鈕上顯示的是總張數，Anlas 也按總張數算——看清楚再按，別問我是怎麼知道的。';

  @override
  String get tips_studio_trick_6 =>
      '在翻譯塊上按一下滑鼠中鍵，原文和譯文來回切換。AI 翻得再好，偶爾也值得偷看一眼原文，確認它沒把 cat ears 翻成什麼奇怪的東西。';

  @override
  String get tips_studio_trick_7 =>
      '設定裡的「限制生圖頻率」可以讓兩次生圖之間強制冷卻，再加一點隨機抖動，節奏就沒那麼機械。適合掛著慢慢抽的夜晚，也適合管不住手的自己。';

  @override
  String get tips_studio_wolf_1 =>
      '這裡是狼窩。你生成的圖會被我叼回來，整整齊齊擺在本地畫廊裡——說真的，我的收納能力比畫技可靠得多。';

  @override
  String get tips_studio_wolf_2 =>
      '我們狼在夜裡視力最好。所以如果你凌晨三點還在這裡，我什麼都不會說，只會默默陪你再抽一張。';

  @override
  String get tips_studio_wolf_3 =>
      '據說 AI 畫手的成年禮，是第一次心平氣和地數完一隻手上的手指。我沒有手指，所以我一直很平靜。';

  @override
  String get tips_studio_wolf_4 =>
      '狼群的規矩：好種子要分享，好提示詞要存成塊，好圖要先儲存再欣賞。最後一條最重要，別問為什麼。';

  @override
  String get tips_studio_wolf_5 => '我不會畫畫，但我很會等。看著流式預覽一點點變清晰的那幾秒，是我一天裡最安靜的時候。';

  @override
  String get tips_studio_wolf_6 => 'W.O.F 的意思是 WolF。至於中間為什麼有點，那是我跑過雪地留下的腳印。';

  @override
  String get tips_studio_wolf_7 => '畫布空著的時候，我就趴在這裡打個盹。按下生成，我就醒了。';

  @override
  String get tips_studio_night_1 => '現在是深夜。友情提醒：這個時間段你的審美會悄悄上調 30%，明早起來記得再看一遍。';

  @override
  String get tips_studio_night_2 => '夜深了，遠方機房裡的顯示卡也打了個哈欠。抽完這一批就去睡吧，畫廊我替你守著。';

  @override
  String get tips_lab_guide_1 =>
      '畫風探索是一場選秀：先建一個探索任務，把提示詞和參數固定下來，再批次生成候選圖。你挑中的子代會成為下一代的父本，畫風就這樣一代代朝你想要的方向靠近。';

  @override
  String get tips_lab_guide_2 =>
      '紅心和資料夾是給你自己整理用的，不會影響遺傳。真正決定下一代的，是你用「多選建分支」挑進去的那幾張。';

  @override
  String get tips_lab_guide_3 =>
      '拿不定主意時，用「A/B 組對照」：兩張父本的圖並排出現，你只需要回答哪張更接近想要的畫風。排在前面的父本，下一輪更容易分到子代。';

  @override
  String get tips_lab_guide_4 =>
      '想生成下一輪候選，主提示詞裡得有一個啟用了遺傳的隨機塊。沒有可變的基因，變異引擎也無從下手。';

  @override
  String get tips_lab_guide_5 =>
      '某張候選的提示詞組合特別好？「收編為塊」能把它存進塊庫，以後在生成頁也能直接用；多選幾張，還能合併收編成一個塊。';

  @override
  String get tips_lab_guide_6 =>
      '刪除探索任務只會刪掉任務目錄裡的候選副本，本地畫廊裡的原圖不受影響。放心清理，試驗場本來就該亂一點。';

  @override
  String get tips_lab_trick_1 =>
      '每個父本至少會分到一張出圖名額，所以父本越多，一輪需要的張數也越多。貪心的話，Anlas 會先替你喊停。';

  @override
  String get tips_lab_trick_2 => '只能從最新一代的候選堆建分支。回頭路可以看，但不能從半路岔出去——進化論就是這麼無情。';

  @override
  String get tips_lab_trick_3 =>
      '變異引擎偶爾會說「產不出足夠不同的子代」。這不是它偷懶，是基因池太小了：給隨機塊多塞幾個候選詞，它馬上就有活幹。';

  @override
  String get tips_lab_trick_4 => '懸停候選堆裡的縮圖就能看大圖。別一張張點開，評委要有評委的效率。';

  @override
  String get tips_lab_trick_5 =>
      '看中了某張候選的整套參數？「匯入後設資料」會把它的提示詞和參數原樣搬回編輯區，你可以從這裡接著改。';

  @override
  String get tips_lab_wolf_1 => '狼群裡沒有哪隻狼一出生就是最強的。畫風也一樣，第一代醜一點很正常，到第三代再下結論。';

  @override
  String get tips_lab_wolf_2 => '這裡的適者生存有個溫柔的版本：沒被選中的候選不會消失，只是這一輪沒輪到它而已。';

  @override
  String get tips_lab_wolf_3 => '我對遺傳學的全部理解是：好看的爸媽，大機率生出好看的崽。剩下的交給變異，和一點點運氣。';

  @override
  String get tips_lab_wolf_4 => 'LAB 的燈通常亮到很晚。我在門口值班，順便幫你記著這是第幾代了。';

  @override
  String get tips_lab_wolf_5 =>
      '永遠不要小看變異。有時候你挑了十代都沒找到的東西，會在一次意外裡冒出來。所以，看著不對勁的那張也別急著刪。';

  @override
  String get tips_prompt_guide_1 => '寫完按 Ctrl+Enter 就能生成，生成途中按 Esc 取消。';

  @override
  String get tips_prompt_guide_2 => '選中一段提示詞，按住 Alt 滾動滾輪調權重；不按 Alt，滾輪只是翻頁。';

  @override
  String get tips_prompt_guide_3 =>
      'Ctrl+單擊提示詞裡的標籤，直接在本地標籤庫裡搜它；Ctrl+拖選一段，看看哪些標籤常和它一起出現。';

  @override
  String get tips_prompt_guide_4 => '選中一段文字點右鍵，可以直接儲存到塊庫。以後點一下或拖一下，它就回來了。';

  @override
  String get tips_prompt_guide_5 => '框底部的品質詞預設會替你補上那排常用品質詞；切到負面，同一個位置就是負面預設。';

  @override
  String get tips_prompt_guide_6 => '按 F1 檢視全部快速鍵。';

  @override
  String get tips_prompt_guide_7 =>
      '從 ComfyUI 複製來的多角色提示詞，貼上進來會被識別，並詢問是否匯入成角色框，不用一個個重填。';

  @override
  String get tips_prompt_guide_8 =>
      '開啟「SD 語法自動轉換」後，(tag:1.2) 這種寫法會在失焦或生成時自動換成 NovelAI 的權重格式。';

  @override
  String get tips_prompt_guide_9 => '寫 1.2::詞:: 能精確調權重，寫負數就反著來。';

  @override
  String get tips_prompt_trick_1 =>
      '花括號每套一層，權重乘 1.05；方括號每套一層，除以 1.05。套五層花括號的人，通常是在和模型吵架。';

  @override
  String get tips_prompt_trick_2 => '自動格式化會刪掉沒用的 1 倍權重。它不是嫌棄你，是在幫你省 token。';

  @override
  String get tips_prompt_trick_3 =>
      '框底下那條細線是 token 用量。寫滿之後，後面的內容模型基本就看不見了——想寫長篇小說，請換個地方。';

  @override
  String get tips_prompt_trick_4 => '寫不出來的時候，先寫畫面裡最大的那個東西。';

  @override
  String get tips_prompt_trick_5 => '品質詞寫一次就夠了。masterpiece 寫三遍，模型也不會覺得你更真誠。';

  @override
  String get tips_prompt_trick_6 =>
      '想讓一個元素「出現但別太搶戲」，寫 0.8:: 比刪掉它好使。刪掉是沒有，降權是低調。';

  @override
  String get tips_prompt_trick_7 => '同一套詞改來改去？先存成塊，再交給隨機抽取。';

  @override
  String get tips_prompt_trick_8 =>
      '正面寫「要什麼」，負面寫「不要什麼」。在正面寫 no hat，模型多半隻聽見了 hat。';

  @override
  String get tips_prompt_wolf_1 => '這個框見過上千張神圖，和幾張不太方便公開的黑歷史。';

  @override
  String get tips_prompt_wolf_2 =>
      '先用一句人話描述你想要的畫面，再把它拆成標籤。順序反過來的話，常常會得到一堆標籤和一張不知所云的圖。';

  @override
  String get tips_prompt_wolf_3 => '我在看你打字。別緊張，我看不懂英文。';

  @override
  String get tips_prompt_wolf_4 => '遠方某張顯示卡，剛剛因為你的提示詞嘆了口氣。';

  @override
  String get tips_prompt_wolf_5 => '抽卡的盡頭是玄學，玄學的盡頭是鎖種子。';

  @override
  String get tips_prompt_wolf_6 => '畫師串加到第十二個的時候，模型已經不知道自己在畫誰了。你也是。';

  @override
  String get tips_explore_guide_1 => '這裡寫的是父本的提示詞。想讓某部分參與進化，就把它做成隨機塊，再在塊上開啟遺傳。';

  @override
  String get tips_explore_guide_2 => '遺傳開關要等塊實例啟用後才能開啟。灰著的話，先把塊啟用。';

  @override
  String get tips_explore_guide_3 => '「生成候選圖」旁邊的數字，決定這一輪出幾張。';

  @override
  String get tips_explore_guide_4 => '塊實例可以「退回一幕」「前進一幕」，在抽過的組合之間來回翻。';

  @override
  String get tips_explore_guide_5 => '探索任務會固化提示詞和參數快照。之後再改這裡，不會影響已經跑完的那幾輪。';

  @override
  String get tips_explore_guide_6 => '塊的「隨機設定」裡能調抽取數量、觸發機率和隨機權重——基因的花樣都藏在這裡。';

  @override
  String get tips_explore_trick_1 =>
      '基因池越大，變異越有得挑。一個隨機塊裡只放兩個詞，進化十代也只是在兩個答案之間來回橫跳。';

  @override
  String get tips_explore_trick_2 =>
      '確定要的部分寫死，拿不準的做成隨機塊。全都隨機等於沒有方向，全都寫死等於沒有進化。';

  @override
  String get tips_explore_trick_3 => '鎖住的塊不會被重抽。想保住某個特徵，就先鎖上它，再讓別的塊去折騰。';

  @override
  String get tips_explore_trick_4 =>
      '觸發機率設成 30%，這個塊大約只在三成的組合裡出現。適合那些「偶爾來一下才好看」的元素。';

  @override
  String get tips_explore_trick_5 => '第一代就想看到完美答案？那叫許願，不叫探索。';

  @override
  String get tips_explore_wolf_1 => '狼群的血統是一代代挑出來的。你的畫風也是。';

  @override
  String get tips_explore_wolf_2 => '每一輪生成都是一場海選，評委只有你一個。我負責鼓掌。';

  @override
  String get tips_explore_wolf_3 => '好基因來自好父本，好父本來自你那一下沒手滑的點選。';

  @override
  String get tips_explore_wolf_4 => '我不太懂遺傳學，但我知道：挑剔的評委，才養得出好看的狼崽。';

  @override
  String get tips_character_guide_1 => '角色框本質是定位框：貓、燈、招牌都能放，不一定是人。';

  @override
  String get tips_character_guide_2 => '上方「定位」切到「自訂」，在預覽圖上拖動錨點，鬆開就生效。';

  @override
  String get tips_character_guide_3 => '「AI 選擇」把位置交給模型安排；切回「自訂」，之前拖好的位置還在。';

  @override
  String get tips_character_guide_4 => '每個角色框都有自己的負面，只管這一個角色。';

  @override
  String get tips_character_guide_5 => '右上角的勾可以臨時停用這個角色，不用刪掉重寫。';

  @override
  String get tips_character_guide_6 => '點一下標題就能給角色改名，比編號好認多了。';

  @override
  String get tips_character_guide_7 => '右上角的 ⋯ 裡可以把這個角色收藏到塊庫，以後接著複用這段描述。';

  @override
  String get tips_character_trick_1 =>
      '場景和畫風寫主提示詞，這裡只寫這個角色。兩邊寫同一件衣服，模型會以為你超愛它。';

  @override
  String get tips_character_trick_2 =>
      '兩人挨太近容易「粘」在一起。把錨點拉開一點，比寫十遍 separate 管用。';

  @override
  String get tips_character_trick_3 => '想讓一棵樹站在畫面左邊？給它一個角色框，拖到左邊。樹不會抱怨自己不是角色。';

  @override
  String get tips_character_trick_4 => '角色框裡也能用塊和權重語法，和主提示詞一樣。';

  @override
  String get tips_character_trick_5 => '角色太多就先停用幾個。畫面擠不下時，模型會自己挑人——通常不是你想留的那個。';

  @override
  String get tips_character_wolf_1 => '我也想要一個角色框，但我覺得自己更適合站在畫面外面看著。';

  @override
  String get tips_character_wolf_2 => '一個框，一個位置，一件事。我覺得這是很好的人生哲學。';

  @override
  String get tips_character_wolf_3 => '你負責安排站位，我負責在旁邊喊「再往左一點」。';

  @override
  String get tips_character_wolf_4 => '狼群出門也要排隊形。角色多的時候，先想好誰站中間。';

  @override
  String get tips_gallery_guide_1 => '搜檔名或提示詞正文';

  @override
  String get tips_gallery_guide_2 => '逗號分隔多個詞，要全部命中才算';

  @override
  String get tips_gallery_guide_3 => '模型、取樣器、來源也能搜到';

  @override
  String get tips_gallery_guide_4 => 'Ctrl+F 隨時跳到搜尋框';

  @override
  String get tips_gallery_guide_5 => '角色提示詞裡的內容也搜得到';

  @override
  String get tips_gallery_guide_6 => '右鍵圖片，還有更多操作';

  @override
  String get tips_gallery_guide_7 => 'F5 重新整理畫廊';

  @override
  String get tips_gallery_trick_1 => '只搜正面，負面裡的搜不到';

  @override
  String get tips_gallery_trick_2 => '重抽之前先搜，多半已經有了';

  @override
  String get tips_gallery_trick_3 => '你寫過的提示詞就是最好的搜尋詞';

  @override
  String get tips_gallery_trick_4 => '刪除池的圖，下次啟動才真刪';

  @override
  String get tips_gallery_trick_5 => '搜 masterpiece 約等於搜全部';

  @override
  String get tips_gallery_wolf_1 => '今晚的獵物大概在第三頁';

  @override
  String get tips_gallery_wolf_2 => '我聞到了，神作就在這堆裡';

  @override
  String get tips_gallery_wolf_3 => '滾動也算運動，我陪你跑';

  @override
  String get tips_gallery_wolf_4 => '窩很大，慢慢翻';

  @override
  String get tips_online_guide_1 => '空格分隔多個標籤，回車搜尋';

  @override
  String get tips_online_guide_2 => '開模糊匹配，*tag* 找相近標籤';

  @override
  String get tips_online_guide_3 => '黑名單標籤的圖會直接隱藏';

  @override
  String get tips_online_guide_4 => '登入 Danbooru 後可以用收藏夾';

  @override
  String get tips_online_trick_1 => '多詞標籤用下劃線：blue_eyes';

  @override
  String get tips_online_trick_2 => '看到好圖，記下它的標籤思路';

  @override
  String get tips_online_trick_3 => '標籤越多結果越少，先少寫幾個';

  @override
  String get tips_online_wolf_1 => '外面的世界很大，我先去探路';

  @override
  String get tips_online_wolf_2 => '別人家的獵場，逛逛就好';

  @override
  String get tips_online_wolf_3 => '今天想去哪片林子打獵？';

  @override
  String get tips_blocks_guide_1 => '標題、提示詞、標籤都能搜';

  @override
  String get tips_blocks_guide_2 => '把塊直接拖進提示詞框';

  @override
  String get tips_blocks_guide_3 => '點 ★ 收藏，常用塊集中放';

  @override
  String get tips_blocks_guide_4 => '塊可以帶縮圖，挑起來更快';

  @override
  String get tips_blocks_guide_5 => '選中文字右鍵，就能存成塊';

  @override
  String get tips_blocks_trick_1 => '同一段寫過三次，就該存成塊了';

  @override
  String get tips_blocks_trick_2 => '猶豫要不要存？存。刪比寫快';

  @override
  String get tips_blocks_trick_3 => '名字起清楚，半年後會感謝自己';

  @override
  String get tips_blocks_trick_4 => '隨機塊候選越多，驚喜越多';

  @override
  String get tips_blocks_wolf_1 => '每個塊都在等你點名';

  @override
  String get tips_blocks_wolf_2 => '這些塊是你的狼群，常帶出去溜';

  @override
  String get tips_blocks_wolf_3 => '我只認得一種塊：肉塊';

  @override
  String get tips_blocks_wolf_4 => '資料夾套資料夾，算是有條理了';

  @override
  String get tips_generating_wolf_1 => '正在和隨機數討價還價…';

  @override
  String get tips_generating_wolf_2 => '正在跟第六根手指好好談談…';

  @override
  String get tips_generating_wolf_3 => '正在勸像素們排好隊…';

  @override
  String get tips_generating_wolf_4 => '正在把噪點一粒粒擦掉…';

  @override
  String get tips_generating_wolf_5 => '狼正在遠處嚎叫助威…';

  @override
  String get tips_generating_wolf_6 => '正在向顯示卡解釋你的審美…';

  @override
  String get tips_generating_wolf_7 => '正在把提示詞翻譯成夢…';

  @override
  String get tips_generating_wolf_8 => '正在確認眼睛的數量…';

  @override
  String get tips_generating_wolf_9 => '正在給光影找個好角度…';

  @override
  String get tips_generating_wolf_10 => '正在說服背景別搶戲…';

  @override
  String get tips_generating_wolf_11 => '正在從噪聲裡撈出你的圖…';

  @override
  String get tips_generating_wolf_12 => '正在數手指：一、二、三…';

  @override
  String get tips_generating_wolf_13 => '正在等顏料晾乾…';

  @override
  String get tips_generating_wolf_14 => '正在召喚今天的好運氣…';

  @override
  String get tips_generating_trick_1 => '等不及了？按 Esc 可以取消';

  @override
  String get tips_generating_trick_2 => '預覽會一幀幀變清晰';

  @override
  String get tips_generating_trick_3 => '生成好的圖預設存進本地畫廊';

  @override
  String get tips_generating_trick_4 => '每一步取樣都在去掉一層噪點';

  @override
  String get tips_splash_guide_1 => '按 F1 可以隨時檢視全部快速鍵。';

  @override
  String get tips_splash_guide_2 => 'Ctrl+Enter 生成，所有快速鍵都能在設定裡改。';

  @override
  String get tips_splash_guide_3 => '把圖拖進視窗，可以讀出它的提示詞和參數。';

  @override
  String get tips_splash_guide_4 => '常用的提示詞存成塊，下次一鍵複用。';

  @override
  String get tips_splash_trick_1 => '上面那個 STEP /28，致敬的是預設的 28 步取樣。';

  @override
  String get tips_splash_trick_2 => '預編碼的 Vibe 可以免費複用，省下 2 Anlas。';

  @override
  String get tips_splash_trick_3 => '第一次建立圖庫索引會慢一點，期間照常使用就好。';

  @override
  String get tips_splash_wolf_1 => '再讓我睡五分鐘……好吧，起來了。';

  @override
  String get tips_splash_wolf_2 => '我先把窩收拾一下，馬上就好。';

  @override
  String get tips_splash_wolf_3 => '顯示卡就位，月亮就位，就差你了。';

  @override
  String get tips_splash_wolf_4 => '聞到了嗎？是新提示詞的味道。';

  @override
  String get tips_splash_wolf_5 => '今天也要好好抽卡。';

  @override
  String genButton_normal(int count) {
    return '生成 $count 張圖片';
  }

  @override
  String get genButton_one_1 => '就這一張，不改了';

  @override
  String get genButton_one_2 => '來張好的';

  @override
  String get genButton_one_3 => '單抽，信仰之躍';

  @override
  String get genButton_one_4 => '先來一張試試水';

  @override
  String get genButton_one_5 => '一張定勝負';

  @override
  String get genButton_one_6 => '這張必是神圖';

  @override
  String get genButton_one_7 => '就一張，我發誓';

  @override
  String get genButton_one_8 => '新頭像就靠它了';

  @override
  String get genButton_one_9 => '一發入魂';

  @override
  String get genButton_one_10 => '來張能當桌布的';

  @override
  String get genButton_one_11 => '輕輕抽一張';

  @override
  String get genButton_one_12 => '叼一張回來';

  @override
  String genButton_few_1(int count) {
    return '$count 張，挑個最好的';
  }

  @override
  String genButton_few_2(int count) {
    return '來 $count 張比一比';
  }

  @override
  String genButton_few_3(int count) {
    return '$count 連抽';
  }

  @override
  String genButton_few_4(int count) {
    return '$count 張，總有一張行';
  }

  @override
  String genButton_few_5(int count) {
    return '$count 選一，評委就位';
  }

  @override
  String genButton_few_6(int count) {
    return '先來 $count 張熱熱身';
  }

  @override
  String genButton_few_7(int count) {
    return '$count 張，擇優錄取';
  }

  @override
  String genButton_few_8(int count) {
    return '$count 張小確幸';
  }

  @override
  String genButton_batch_1(int count) {
    return '$count 連發';
  }

  @override
  String genButton_batch_2(int count) {
    return '$count 張一起上';
  }

  @override
  String genButton_batch_3(int count) {
    return '$count 張，開始停不下來';
  }

  @override
  String genButton_batch_4(int count) {
    return '一次 $count 張，吃到飽';
  }

  @override
  String genButton_batch_5(int count) {
    return '$count 張，鋪滿螢幕';
  }

  @override
  String genButton_batch_6(int count) {
    return '$count 連，穩一手';
  }

  @override
  String genButton_batch_7(int count) {
    return '$count 張，狼群出動';
  }

  @override
  String genButton_batch_8(int count) {
    return '$count 張，開席';
  }

  @override
  String genButton_many_1(int count) {
    return '$count 張，上強度了';
  }

  @override
  String genButton_many_2(int count) {
    return '$count 張，顯示卡開始冒汗';
  }

  @override
  String genButton_many_3(int count) {
    return '$count 張，囤貨模式';
  }

  @override
  String genButton_many_4(int count) {
    return '$count 張，流水線啟動';
  }

  @override
  String genButton_many_5(int count) {
    return '$count 張，Anlas 在燃燒';
  }

  @override
  String genButton_many_6(int count) {
    return '$count 張，這是要日更';
  }

  @override
  String genButton_many_7(int count) {
    return '$count 張批量出擊';
  }

  @override
  String genButton_many_8(int count) {
    return '$count 張，狼都看呆了';
  }

  @override
  String genButton_huge_1(int count) {
    return '$count 張？！開畫展嗎';
  }

  @override
  String genButton_huge_2(int count) {
    return '$count 張，硬碟瑟瑟發抖';
  }

  @override
  String genButton_huge_3(int count) {
    return '$count 張，工業革命了';
  }

  @override
  String genButton_huge_4(int count) {
    return '$count 張，先冷靜一下';
  }

  @override
  String genButton_huge_5(int count) {
    return '$count 張，存得下嗎';
  }

  @override
  String genButton_huge_6(int count) {
    return '$count 張，列印店開張';
  }

  @override
  String genButton_huge_7(int count) {
    return '批發 $count 張';
  }

  @override
  String genButton_huge_8(int count) {
    return '$count 張，狼去搬救兵了';
  }

  @override
  String get genButton_rare_1 => '這發必出 SSR';

  @override
  String get genButton_rare_2 => 'AI 說它今天手感不錯';

  @override
  String get genButton_rare_3 => '今日運勢：大吉';

  @override
  String get genButton_rare_4 => '據說這個按鈕旺你';

  @override
  String get genButton_rare_5 => '狼對著月亮嚎了一聲';

  @override
  String get genButton_rare_6 => '玄學加持中';

  @override
  String get genButton_rare_7 => '歐氣已充值';

  @override
  String get genButton_rare_8 => '本次抽卡由狼贊助';

  @override
  String get genButton_rare_9 => '手氣，來！';

  @override
  String get genButton_rare_10 => '按下即是信仰';

  @override
  String get genButton_night_1 => '夜深了，最後一抽';

  @override
  String get genButton_night_2 => '抽完這批就睡';

  @override
  String get genButton_night_3 => '凌晨的審美最野';

  @override
  String get genButton_night_4 => '狼陪你熬夜';

  @override
  String genButton_special_7(int count) {
    return '$count 張，幸運七';
  }

  @override
  String genButton_special_9(int count) {
    return '$count 張，九宮格集齊';
  }

  @override
  String genButton_special_42(int count) {
    return '$count，萬物的答案';
  }

  @override
  String genButton_special_99(int count) {
    return '$count 張，差一張破百';
  }

  @override
  String genButton_special_100(int count) {
    return '整整 $count 張，強迫症舒服了';
  }

  @override
  String get titleBar_minimize => '最小化';

  @override
  String get titleBar_maximize => '最大化';

  @override
  String get titleBar_restore => '還原';

  @override
  String get titleBar_close => '關閉';

  @override
  String get img2img_pixelSnap => '像素對齊';

  @override
  String get img2img_masked => '透明摳圖';

  @override
  String get img2img_generated => '生成結果';

  @override
  String get img2img_blend => '混合結果';

  @override
  String get img2img_enhanceAction => '增強！';

  @override
  String get img2img_showAdvanced => '顯示進階設定';

  @override
  String get img2img_hideAdvanced => '收起進階設定';

  @override
  String promptToken_usage(int used, int limit) {
    return 'Token 用量：$used / $limit';
  }

  @override
  String promptToken_promptShare(int used, int total, int limit) {
    return '此提示詞：$used Token；總用量：$total / $limit';
  }

  @override
  String get promptToken_blockReferenceHint => '單塊進度僅供參考；插入後的總量取決於組合使用。';

  @override
  String get settings_geistDark => 'Geist 深色';

  @override
  String get settings_geistLight => 'Geist 淺色';

  @override
  String get settings_geistDescription => '全工作室統一外觀：黑白灰底色，藍色作為操作強調。';

  @override
  String get updateCapsuleLabel => '更新';

  @override
  String get updateWaitForTask => '任務進行中，結束後即可重啟更新';

  @override
  String get updateLater => '稍後';

  @override
  String get nav_tagWiki => '標籤百科';

  @override
  String get wiki_title => '標籤百科';

  @override
  String get wiki_allTags => '全部詞條';

  @override
  String get wiki_bookmarks => '書籤';

  @override
  String get wiki_newCollection => '新增書籤集';

  @override
  String get wiki_newChildCollection => '新增子書籤集';

  @override
  String get wiki_renameCollection => '重新命名';

  @override
  String get wiki_deleteCollection => '刪除書籤集';

  @override
  String get wiki_officialDirectory => '官方目錄';

  @override
  String get wiki_searchHint => '搜尋標籤或別名';

  @override
  String get wiki_typeAllShort => '全部';

  @override
  String get wiki_coverageAll => '全部釋義';

  @override
  String get wiki_withArticle => '有釋義';

  @override
  String get wiki_withoutArticle => '暫無釋義';

  @override
  String get wiki_sortPopular => '按熱度';

  @override
  String get wiki_sortName => '按名稱';

  @override
  String get wiki_dataStatus => '資料狀態';

  @override
  String get wiki_scopeCurrent => '當前目錄';

  @override
  String get wiki_scopeAll => '搜尋全庫';

  @override
  String get wiki_readingSettings => '閱讀設定';

  @override
  String get wiki_textSize => '正文大小';

  @override
  String get wiki_readingWidth => '閱讀寬度';

  @override
  String get wiki_small => '小';

  @override
  String get wiki_standard => '標準';

  @override
  String get wiki_large => '大';

  @override
  String get wiki_wide => '寬';

  @override
  String get wiki_articleMissing => '這條標籤暫時沒有本地 Wiki 釋義。';

  @override
  String get wiki_source => '來源';

  @override
  String get wiki_addBookmark => '加入書籤';

  @override
  String get wiki_removeBookmark => '移出書籤';

  @override
  String get wiki_addToCollection => '加入書籤集';

  @override
  String get wiki_loadMore => '載入更多';

  @override
  String get wiki_noResults => '沒有匹配的詞條';

  @override
  String get wiki_noSelection => '選擇一個詞條檢視釋義';

  @override
  String get wiki_collectionNameHint => '書籤集名稱';

  @override
  String get wiki_syncTags => '同步 Danbooru 標籤';

  @override
  String get wiki_directorySource => '官方分組目錄快照';

  @override
  String get wiki_openFull => '在標籤百科中開啟';

  @override
  String get shortcut_action_vibe_detail_prev_sub_vibe => '上一個子 Vibe';

  @override
  String get shortcut_action_vibe_detail_next_sub_vibe => '下一個子 Vibe';

  @override
  String get settings_addAccountsSwitchBetweenThem => '新增帳號後，可以在這裡快速切換。';

  @override
  String get settings_current => '當前';

  @override
  String get settings_emailLogin => '電子郵件登入';

  @override
  String get settings_signedIn => '已登入';

  @override
  String get settings_switch => '切換';

  @override
  String get settings_accountActions => '帳號操作';

  @override
  String get settings_editProfile => '編輯資料';

  @override
  String get settings_setDefault => '設為預設帳號';

  @override
  String get settings_credentialsUpdated => '登入憑據已更新';

  @override
  String get settings_updateCredentials => '更新憑據';

  @override
  String get settings_accountDetails => '帳號詳情';

  @override
  String get settings_localAccountProfile => '本地帳號資料';

  @override
  String get settings_setDefault2 => '設為預設';

  @override
  String get settings_credentialsWereNotUpdatedCheck => '憑據未更新，請檢查令牌與連線後重試。';

  @override
  String get settings_updateCredentials2 => '更新登入憑據';

  @override
  String get settings_checking => '正在驗證…';

  @override
  String get settings_enterNewSignInToken => '輸入新的登入令牌，驗證成功後更新此帳號。';

  @override
  String get auth_notSignedIn => '尚未登入';

  @override
  String get settings_tagExpansion => '標籤擴展';

  @override
  String get settings_tagDictionaries => '標籤詞庫';

  @override
  String get settings_cacheMaintenance => '快取維護';

  @override
  String get settings_clear => '清理';

  @override
  String get settings_autoRefresh => '自動重新整理';

  @override
  String get settings_searchFonts => '搜尋字型名稱';

  @override
  String get settings_couldNotLoadFonts => '暫時無法讀取字型';

  @override
  String get settings_recommended => '推薦';

  @override
  String get settings_included => '隨應用提供';

  @override
  String get settings_systemFonts => '系統字型';

  @override
  String get settings_fontPreview => '字型預覽';

  @override
  String get settings_onlineFontsLoadAfterApplying => '線上字型將在應用後加載，當前顯示介面字型。';

  @override
  String get settings_saving => '儲存設定';

  @override
  String get settings_howGeneratedImagesSaved => '生成圖片的儲存方式';

  @override
  String get settings_assetsDisplay => '素材與顯示';

  @override
  String get settings_vibeLocationThumbnailQuality => 'Vibe 位置與縮圖品質';

  @override
  String get settings_applicationData => '應用資料';

  @override
  String get settings_gallerySources => '圖庫來源';

  @override
  String get settings_manageAdditionalGalleryFolders => '管理額外圖庫資料夾';

  @override
  String get settings_default => '預設';

  @override
  String get settings_keyboard => '鍵盤操作';

  @override
  String get settings_customizeFrequentlyUsedActions => '按習慣配置常用操作';

  @override
  String get settings_manageShortcuts => '管理快速鍵';

  @override
  String get settings_costReminders => '消耗提醒';

  @override
  String get settings_requestPacing => '請求節奏';

  @override
  String get settings_notificationsSound => '完成提醒與聲音';

  @override
  String get settings_lockCanvasCamera => '鎖定畫布相機';

  @override
  String get settings_dictionariesCache => '詞庫與快取';

  @override
  String get settings_defaultAccount2 => '預設帳號';

  @override
  String get settings_signInAutomatically => '啟動時自動登入';

  @override
  String get settings_signInCredentials => '登入憑據';

  @override
  String get settings_translationInterfaces => '翻譯功能介面';

  @override
  String get settings_presetsBuiltInRules => '預設與內建規則';

  @override
  String get settings_preferenceBackupRestore => '偏好備份與恢復';

  @override
  String get settings_searchSettingsFeatures => '搜尋設定、功能或關鍵詞';

  @override
  String get settings_noMatchingSettings => '沒有找到匹配設定';

  @override
  String get settings_change => '更改';

  @override
  String get settings_couldNotPlaySoundCheck => '無法播放音效，請檢查音訊檔案。';

  @override
  String get settings_useDefaultCompletionSound => '使用預設完成音效';

  @override
  String get settings_soundPreview => '音效預覽';

  @override
  String get settings_listenCurrentCompletionSound => '試聽當前完成音效';

  @override
  String get settings_playSound => '試聽音效';

  @override
  String get settings_searchResults => '搜尋結果';

  @override
  String get settings_promptInput => '提示詞輸入';

  @override
  String get settings_manageTranslationModelsRules => '管理翻譯模型與規則';

  @override
  String get settings_browsing => '瀏覽方式';

  @override
  String get settings_chooseHowViewImages => '選擇圖片的檢視習慣';

  @override
  String get settings_canvasControls => '畫布操作';

  @override
  String get settings_keepViewSteady => '保持視角穩定';

  @override
  String get settings_appearance2 => '外觀樣式';

  @override
  String get settings_chooseLightDarkWorkspace => '選擇工作臺的明暗風格';

  @override
  String get settings_textLanguage => '文字與語言';

  @override
  String get settings_makeReadingComfortable => '統一閱讀體驗';

  @override
  String get settings_adjustSettingsPagesDialogsOnly => '僅調整設定頁面與設定彈窗的字號';

  @override
  String get settings_motionNotifications => '動效與提醒';

  @override
  String get settings_reduceDistractionsKnowWorkFinishes => '減少打擾，及時獲知完成';

  @override
  String get settings_notificationStyle => '通知樣式';

  @override
  String get settings_notificationsAppearUpperRightWrap =>
      '通知會顯示在右上角，長文本自動換行，進度任務完成後自動收起。';

  @override
  String get settings_preview => '預覽';

  @override
  String get settings_versionUpdates => '版本與更新';

  @override
  String get settings_currentVersionUpdateOptions => '當前版本與更新選項';

  @override
  String get settings_diagnosticsResources => '診斷與資料';

  @override
  String get settings_logsFontsOpenSourceProject => '日誌、字型與開源專案';

  @override
  String get settings_viewLicenses => '檢視許可';

  @override
  String get settings_openProject => '開啟專案';

  @override
  String get settings_actionIncomplete => '操作未完成';

  @override
  String get settings_exportPreferences => '匯出偏好';

  @override
  String get settings_preferencesExported => '偏好已匯出';

  @override
  String get settings_noAutomaticBackupYet => '尚無自動回退備份';

  @override
  String get settings_restorePreviousPreferences => '恢復上次偏好';

  @override
  String get settings_importPreferences => '匯入偏好';

  @override
  String get settings_apply => '確認應用';

  @override
  String get settings_preferencesAppliedPreviousSettingsBacked =>
      '偏好已應用，舊設定已自動備份';

  @override
  String get settings_restoreDefaultPreferences => '恢復預設偏好';

  @override
  String get settings_choosePreferencesResetCurrentSettings =>
      '選擇需要恢復的範圍，當前偏好將自動備份。';

  @override
  String get settings_appearanceSoundControls => '外觀、聲音與操作';

  @override
  String get settings_inputAutocomplete => '輸入與自動補全';

  @override
  String get settings_privacyGenerationProtection => '隱私與生成保護';

  @override
  String get settings_moveAppearanceControlsInputProtection =>
      '介面、操作、輸入和保護偏好，可跨裝置遷移。';

  @override
  String get settings_rollbackCopySavedBeforeImport => '匯入或恢復預設前會自動儲存回退副本。';

  @override
  String get settings_resetSelectedScopeWhileKeeping =>
      '按範圍恢復，保留帳號、模型、圖庫和創作內容。';

  @override
  String get settings_chooseScope => '選擇範圍';

  @override
  String get settings_preferenceManagement => '偏好管理';

  @override
  String get settings_backupMigrationRecovery => '備份、遷移與恢復';

  @override
  String get settings_generalAppearance => '常規與外觀';

  @override
  String get settings_makeWorkspaceComfortableReadUse => '讓工作臺符合你的閱讀與使用習慣。';

  @override
  String get settings_controlsShortcuts => '操作與快速鍵';

  @override
  String get settings_chooseInteractionCanvasControlsKeyboard =>
      '設定互動方式、畫布操作和鍵盤快速鍵。';

  @override
  String get settings_generationPrompts => '生成與提示詞';

  @override
  String get settings_managePromptInputGenerationReminders =>
      '管理提示詞輸入、生成提醒與請求節奏。';

  @override
  String get settings_galleryFiles => '圖庫與檔案';

  @override
  String get settings_manageImageSavingGallerySources => '管理圖片儲存、圖庫來源與瀏覽顯示。';

  @override
  String get settings_manageTagDictionariesIndexesCache => '管理標籤詞庫、索引與快取維護。';

  @override
  String get settings_novelaiAccounts => 'NovelAI 帳號';

  @override
  String get settings_viewAccountManageSignIn => '檢視當前帳號，管理登入與預設帳號。';

  @override
  String get settings_connectionsIntegrations => '連線與整合';

  @override
  String get settings_manageExternalToolsBridgesNetwork => '管理外部工具、橋接連線與網路設定。';

  @override
  String get settings_privacySharing2 => '隱私與分享';

  @override
  String get settings_controlSharedInformationConfirmationBefore =>
      '控制分享資訊與需要確認的操作。';

  @override
  String get settings_aboutDiagnostics => '關於與診斷';

  @override
  String get settings_updatesLogsProjectInformation => '版本更新、日誌與專案資料。';

  @override
  String get settings_searchSettings => '搜尋設定';

  @override
  String get settings_preferences => '使用偏好';

  @override
  String get settings_creationResources => '創作與資源';

  @override
  String get settings_servicesConnections => '服務與連線';

  @override
  String get settings_safetyMaintenance => '安全與維護';

  @override
  String get settings_subscriptionActive => '訂閱有效';

  @override
  String get settings_availableBalance => '可用餘額';

  @override
  String get settings_subscriptionExpiry2 => '訂閱有效期';

  @override
  String get settings_subscriptionDetailsUnavailable => '訂閱資訊暫不可用';

  @override
  String get settings_loadingSubscriptionDetails => '正在讀取訂閱資訊…';

  @override
  String get settings_localDataStaysAvailableAfter => '帳號到期後仍保留本地資料。';

  @override
  String get settings_records => '條記錄';

  @override
  String get settings_hitRate => '命中率';

  @override
  String get settings_images => '張圖片';

  @override
  String get settings_cacheOverview => '快取概覽';

  @override
  String get settings_loginPreferences => '登入偏好';

  @override
  String get settings_preselectedSignInPage => '在登入頁優先選中此帳號。';

  @override
  String get settings_noAccounts => '暫無帳號';

  @override
  String get settings_useLastSessionOffNext => '使用上次的登入憑據；關閉後，下次啟動進入登入頁。';

  @override
  String get settings_couldNotSaveLoginPreference => '登入偏好未儲存，請重試。';

  @override
  String get settings_loginPreferencesUnavailable => '無法讀取登入偏好。';

  @override
  String settings_applyPreferencesConfirm(Object count) {
    return '將應用 $count 項偏好。當前偏好會自動備份，可從“恢復上次偏好”找回。帳號、金鑰、草稿、圖庫和模型配置保持獨立。';
  }

  @override
  String get settings_restore => '恢復';

  @override
  String get wiki_translating => '正在翻譯中';

  @override
  String get wiki_back => '返回上一次';

  @override
  String get wiki_readingTranslation => '譯文';

  @override
  String get wiki_readingOriginal => '原文';

  @override
  String get wiki_readingBilingual => '對照';

  @override
  String get wiki_bilingualUnavailable => '這篇譯文沒有可逐段對照的原文，已顯示譯文';

  @override
  String get wiki_open => '開啟';

  @override
  String get wiki_switchToOriginal => '切換到原文';

  @override
  String get wiki_switchToTranslation => '切換到譯文';

  @override
  String get wiki_retranslate => '重新翻譯';

  @override
  String get wiki_onThisPage => '本文目錄';

  @override
  String get wiki_overview => '簡介';

  @override
  String get wiki_untranslated => '暫未翻譯';

  @override
  String get wiki_autoTranslateTagsArticles => '自動翻譯標籤與百科';

  @override
  String get wiki_readingContent => '閱讀內容';

  @override
  String get wiki_categoryGeneral => '一般';

  @override
  String get wiki_categoryArtist => '畫師';

  @override
  String get wiki_categoryCopyright => '作品';

  @override
  String get wiki_categoryCharacter => '角色';

  @override
  String get wiki_categoryMeta => '元標籤';

  @override
  String get wiki_categoryContributor => '貢獻者';

  @override
  String get wiki_categorySpecies => '物種';

  @override
  String get wiki_categoryLore => '設定';

  @override
  String get wiki_categoryLibrary => '本地';

  @override
  String get wiki_addToBlock => '新增到積木';

  @override
  String get wiki_forward => '前進';

  @override
  String get wiki_posts => '帖子';

  @override
  String get wiki_aliases => '別名';

  @override
  String get wiki_relatedTitle => '常一起出現';

  @override
  String get wiki_relatedHint => '點選檢視 · Shift+點選新增到積木';

  @override
  String get wiki_inDirectory => '所屬目錄';

  @override
  String get wiki_noArticle => '無百科';

  @override
  String get wiki_moreCategories => '更多';

  @override
  String get wiki_shortcutsHint =>
      '/ 搜尋 · ↑↓ 切換 · Enter 新增到積木 · B 收藏 · Alt+←/→ 歷史';

  @override
  String get toast_titleSuccess => '已完成';

  @override
  String get toast_titleError => '操作失敗';

  @override
  String get toast_titleWarning => '請留意';

  @override
  String get toast_titleInfo => '提示';

  @override
  String get toast_titleProgress => '正在處理';

  @override
  String get tagExpansion_autoTranslateVisible => '自動翻譯可見標籤';

  @override
  String get translationEditor_title => '翻譯塊';

  @override
  String get translationEditor_source => '原文';

  @override
  String get translationEditor_sourcePrefix => '原';

  @override
  String get translationEditor_generation => '生圖使用';

  @override
  String get translationEditor_editable => '可改寫';

  @override
  String get translationEditor_modified => '被修改';

  @override
  String get translationEditor_edited => '已編輯';

  @override
  String get translationEditor_close => '關閉';

  @override
  String get translationEditor_save => '儲存';

  @override
  String get translationEditor_delete => '刪除整塊';

  @override
  String get translationEditor_restore => '還原為原文文本';

  @override
  String get translationEditor_configure => '配置翻譯模型';

  @override
  String translationEditor_readingFieldTitle(Object language) {
    return '$language閱讀文本';
  }

  @override
  String translationEditor_sourceWarning(Object language) {
    return '原文已修改，$language待同步';
  }

  @override
  String get translationEditor_editHint => '譯文已手工編輯；這是編輯記錄，不觸發原文修改提醒';

  @override
  String get translationLanguage_chinese => '中文';

  @override
  String get translationLanguage_english => '英語';

  @override
  String get translationLanguage_japanese => '日語';

  @override
  String get translationLanguage_korean => '韓語';

  @override
  String get translationLanguage_traditionalChinese => '繁體中文';

  @override
  String get modelTask_translateTitle => '原文 → 閱讀語言';

  @override
  String get modelTask_promptReverseTitle => '閱讀語言 → 原文';

  @override
  String get modelTask_tagTranslateTitle => '標籤翻譯與語義補充';

  @override
  String get modelTask_wikiTranslateTitle => '百科正文翻譯';

  @override
  String get modelTask_translateDescription => '翻譯提示詞與積木，保留權重、分組和標籤語義。';

  @override
  String get modelTask_promptReverseDescription => '結合原文落實譯文中的增刪修改，結果填回原文供確認。';

  @override
  String get modelTask_tagTranslateDescription =>
      '翻譯可見標籤，補齊中文核心詞、同義詞和簡釋義；已有資料優先複用。';

  @override
  String get modelTask_wikiTranslateDescription => '翻譯百科正文、整理排版，並按語境選擇可點選標籤。';

  @override
  String get modelTask_connectionTest => '模型連線測試';

  @override
  String get modelReasoning_serviceDefault => '服務預設';

  @override
  String get modelReasoning_off => 'Off';

  @override
  String get modelReasoning_on => 'On';

  @override
  String get modelReasoning_minimal => 'Minimal';

  @override
  String get modelReasoning_low => 'Low';

  @override
  String get modelReasoning_medium => 'Medium';

  @override
  String get modelReasoning_high => 'High';

  @override
  String get modelReasoning_xhigh => 'XHigh';

  @override
  String get modelReasoning_max => 'Max';

  @override
  String get modelProvider_custom => '自訂服務';

  @override
  String get modelProvider_qwen => '通義千問 · 百鍊';

  @override
  String get modelProvider_moonshot => 'Kimi · 月之暗面';

  @override
  String get modelProvider_zhipu => '智譜 GLM';

  @override
  String get modelProvider_doubao => '豆包 · 火山方舟';

  @override
  String get modelProvider_hunyuan => '騰訊混元';

  @override
  String get modelProvider_qianfan => '百度千帆';

  @override
  String get modelProvider_siliconflow => '矽基流動';

  @override
  String get modelProvider_zai => 'Z.AI · 國際';

  @override
  String get modelProvider_zhipuCodingPlan => '智譜 Coding Plan';

  @override
  String get modelProvider_kimiCoding => 'Kimi 程式設計';

  @override
  String get modelProvider_moonshotInternational => 'Moonshot AI · 國際';

  @override
  String get modelProvider_minimaxChinaChat => 'MiniMax · 國內 OpenAI';

  @override
  String get modelProvider_minimaxChinaMessages => 'MiniMax · 國內 Anthropic';

  @override
  String get modelProvider_minimaxInternationalMessages =>
      'MiniMax · 國際 Anthropic';

  @override
  String get modelProvider_xiaomi => '小米 MiMo';

  @override
  String get modelProvider_antLing => '螞蟻 Ling';

  @override
  String get modelProvider_stepfunPlan => '階躍 Step Plan';

  @override
  String get modelProvider_qwenTokenPlanChina => '通義 Token 套餐 · 國內';

  @override
  String get modelProvider_hintHuggingFace =>
      '使用具有推理權限的 Hugging Face Token；可手動填寫路由模型 ID。';

  @override
  String get modelProvider_hintPlanKey => '使用套餐專用 API Key；模型與可用範圍以該套餐實際返回為準。';

  @override
  String get modelProvider_hintInternationalEndpoint =>
      '國際平臺端點；使用國際平臺的 API Key。';

  @override
  String get modelProvider_hintRegionOpenAi =>
      '使用對應地區的 API Key；當前預填 OpenAI Chat Completions 相容地址。';

  @override
  String get modelProvider_hintRegionAnthropic =>
      '使用對應地區的 API Key；當前預填 Anthropic Messages 相容地址。';

  @override
  String get modelProvider_hintQwen => '預設北京區域；其他區域請使用對應 Key 並修改介面地址。';

  @override
  String get modelProvider_hintMinimax => '預設國際按量介面；國內平臺請使用對應區域的 Key 和介面地址。';

  @override
  String get modelProvider_hintMoonshot => '預設國內平臺；國際平臺請使用對應區域的 Key 和介面地址。';

  @override
  String get modelProvider_hintZhipu => '預設按量介面；Coding Plan 請使用套餐專用地址。';

  @override
  String get modelProvider_hintDoubao => '使用方舟 API Key；需先開通模型，也可新增推理接入點 ID。';

  @override
  String get modelProvider_hintCustom => '填寫相容服務的地址與 Key，並在連線資訊中選擇介面協定。';

  @override
  String get modelProvider_hintLocal => '先啟動本地服務，再讀取已載入的模型目錄。';

  @override
  String get modelProvider_hintDefault => '地址與協定已預填；儲存 Key 後即可選擇模型使用。';

  @override
  String get modelParams_temperatureRange => 'Temperature 應在 0–2 之間。';

  @override
  String get modelParams_topPRange => 'Top P 應大於 0 且不超過 1。';

  @override
  String get modelParams_maxOutputPositive => '最大輸出 token 必須大於 0。';

  @override
  String modelParams_thinkingBudgetTooSmall(Object minimum) {
    return '最大輸出必須大於思考預算下限 $minimum。';
  }

  @override
  String get modelOverrides_invalidHeaderName => '請輸入有效的請求標頭名稱';

  @override
  String get modelOverrides_invalidHeaderValue => '請求標頭值不能包含換行或控制字元';

  @override
  String get modelOverrides_emptyBodyField => '請求主體欄位名不能為空';

  @override
  String get modelOverrides_modelFromList => '模型 ID 請通過模型列表設定';

  @override
  String get modelOverrides_streamMustBeFalse => '當前介面使用非流式請求，stream 應為 false';

  @override
  String get modelConfig_changedSaveAgain => '配置已變化，請重新儲存。';

  @override
  String get modelConfig_presetChanged => '所選預設已變化，請重新選擇。';

  @override
  String get modelConfig_serviceDisabled => '所選服務已停用，請重新選擇。';

  @override
  String get modelConfig_modelChanged => '所選模型已變化，請重新選擇。';

  @override
  String get modelConfig_reasoningChanged => '模型支援的思考檔位已變化，請重新選擇或跟隨模型。';

  @override
  String get modelConfig_presetIdRequired => '預設 ID 不能為空。';

  @override
  String get modelConfig_saveBuiltinAsCustom => '請將內建方案另存為自訂預設。';

  @override
  String get modelConfig_namePromptRequired => '名稱和提示詞不能為空。';

  @override
  String get modelConfig_builtinNotDeletable => '內建規則不可刪除。';

  @override
  String get modelConfig_pasteFullJson => '請貼上完整的模型配置 JSON。';

  @override
  String get modelConfig_builtinNotOverwritable => '內建方案不可覆蓋，請複製為自訂預設。';

  @override
  String get modelConfig_invalidProvider => '服務商 ID、名稱或地址無效。';

  @override
  String get modelConfig_missingProvider => '模型對應的服務商不存在。';

  @override
  String get modelConfig_invalidCustomPreset => '自訂預設的 ID、名稱或提示詞無效。';

  @override
  String get modelConfig_changedImportAgain => '配置已變化，請重新匯入。';

  @override
  String get modelHealth_unverified => '尚未驗證連線；使用模型或點選“測試連線”後更新';

  @override
  String get modelHealth_healthy => '最近一次請求成功';

  @override
  String get modelHealth_limited => '介面可達，但最近請求被限流（HTTP 429）；請稍後重試或檢查額度';

  @override
  String get modelHealth_authentication => '認證失敗；請檢查 API 金鑰';

  @override
  String get modelHealth_permission => '存取被拒絕；請檢查服務權限';

  @override
  String get modelHealth_timeout => '最近一次請求逾時';

  @override
  String get modelHealth_network => '最近一次請求無法連線服務';

  @override
  String get modelHealth_invalidResponse => '最近一次回應異常；可在請求記錄中檢視詳情';

  @override
  String get modelHealth_failed => '最近一次請求失敗';

  @override
  String modelHealth_failedStatus(Object status) {
    return '最近一次請求失敗（HTTP $status）';
  }

  @override
  String get modelRequest_statusPending => '等待中';

  @override
  String get modelRequest_statusRunning => '請求中';

  @override
  String get modelRequest_statusSuccess => '成功';

  @override
  String get modelRequest_statusFailed => '失敗';

  @override
  String get modelRequest_statusCancelled => '已取消';

  @override
  String get modelRequest_fieldTime => '時間';

  @override
  String get modelRequest_fieldMethod => '方法';

  @override
  String get modelRequest_fieldUrl => '地址';

  @override
  String get modelRequest_fieldRequestHeaders => '請求標頭';

  @override
  String get modelRequest_fieldBody => '正文';

  @override
  String get modelRequest_fieldStatusCode => '狀態碼';

  @override
  String get modelRequest_fieldResponseHeaders => '回應標頭';

  @override
  String get modelRequest_fieldError => '錯誤';

  @override
  String get modelRequest_fieldInterface => '介面';

  @override
  String get modelRequest_fieldProvider => '服務商';

  @override
  String get modelRequest_fieldModel => '模型';

  @override
  String get modelRequest_fieldProtocol => '協定';

  @override
  String get modelRequest_fieldStatus => '狀態';

  @override
  String get modelRequest_fieldElapsed => '耗時（毫秒）';

  @override
  String get modelRequest_fieldAttempts => '執行次數';

  @override
  String get modelRequest_fieldHttpRequests => 'HTTP 請求數';

  @override
  String get modelRequest_fieldParameters => '生效參數';

  @override
  String get modelRequest_redacted => '[已脫敏]';

  @override
  String get modelRequest_emptyResponse => '模型返回了空內容。';

  @override
  String get modelService_testFieldsIncomplete => '測試返回的欄位不完整。';

  @override
  String get modelService_testFieldsInvalid => '測試返回的欄位不正確。';

  @override
  String get modelService_testGroupsInvalid => '測試返回的分組不正確。';

  @override
  String get modelService_testSourceEmpty => '測試返回的原文為空。';

  @override
  String get modelService_conversionCancelled => '轉換已取消';

  @override
  String get modelService_chooseInterfaceModel =>
      '請先在「設定 → 模型與介面 → 功能介面」選擇服務商和模型。';

  @override
  String get modelService_enableServiceModel => '請先在設定中啟用服務，並取得或手動新增後選中一個模型。';

  @override
  String get modelSettings_keepEditsTitle => '保留當前編輯？';

  @override
  String get modelSettings_keepEditsBody => '當前修改尚未儲存。是否儲存後切換？';

  @override
  String get modelSettings_discard => '放棄';

  @override
  String get modelSettings_saveAndSwitch => '儲存並切換';

  @override
  String get modelSettings_addProvider => '新增服務商';

  @override
  String modelSettings_deleteProviderTitle(Object name) {
    return '刪除 $name？';
  }

  @override
  String get modelSettings_deleteProviderBody => '此服務的連線、金鑰和已選模型將被刪除。';

  @override
  String modelSettings_deleteProviderBindings(Object count) {
    return '$count 個功能的模型繫結會被清除，預設保留。';
  }

  @override
  String modelSettings_deletePresetTitle(Object name) {
    return '刪除“$name”？';
  }

  @override
  String get modelSettings_deletePresetBody => '使用此預設的功能將恢復內建方案。模型繫結保留。';

  @override
  String get modelSettings_configCopied => '配置已複製，不包含金鑰、自訂請求標頭或請求主體。';

  @override
  String get modelSettings_importConfig => '匯入配置';

  @override
  String get modelSettings_importConfigHint => '貼上匯出的配置。匯入前會備份當前配置；金鑰繼續獨立儲存。';

  @override
  String get modelSettings_configJson => '配置 JSON';

  @override
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  ) {
    return '將匯入 $providers 個服務商、$models 個模型和 $presets 個自訂預設。';
  }

  @override
  String get modelSettings_importMissingProviders => '缺少服務商或模型配置。';

  @override
  String get modelSettings_checkConfig => '檢查配置';

  @override
  String get modelSettings_importAndReplace => '匯入並替換';

  @override
  String get modelSettings_configImported => '配置已匯入';

  @override
  String get modelSettings_description => '管理服務連線與翻譯偏好。';

  @override
  String get modelSettings_configMenu => '配置管理';

  @override
  String get modelSettings_copyConfig => '複製配置';

  @override
  String get modelSettings_tabProviders => '服務商';

  @override
  String get modelSettings_tabInterfaces => '功能介面';

  @override
  String get modelSettings_tabPresets => '預設與提示詞';

  @override
  String get modelSettings_tabRequests => '請求記錄';

  @override
  String modelSettings_providersCount(Object count) {
    return '服務商 · $count';
  }

  @override
  String modelSettings_providerModelCount(Object count) {
    return '$count 個模型';
  }

  @override
  String get modelSettings_providerDisabledSuffix => ' · 未啟用';

  @override
  String get modelSettings_emptyTitle => '新增你的第一個模型服務';

  @override
  String get modelSettings_emptyBody => '選擇常用服務，或連線自訂介面。';

  @override
  String get modelSettings_customService => '自訂服務';

  @override
  String get modelSettings_notConfigured => '待配置';

  @override
  String get modelSettings_preset => '預設';

  @override
  String get modelSettings_presetBuiltin => '內建';

  @override
  String get modelSettings_presetUser => '使用者';

  @override
  String get modelSettings_deletePreset => '刪除預設';

  @override
  String modelSettings_presetCopyName(Object title, Object number) {
    return '$title（$number）';
  }

  @override
  String get modelSettings_recentRequests => '最近請求';

  @override
  String get modelSettings_recentRequestsHint =>
      '本次會話最近 100 條 · 完整請求與回應，認證資訊已脫敏';

  @override
  String get modelSettings_clearRequests => '清空';

  @override
  String get modelSettings_requestsEmpty => '翻譯或測試模型後，請求記錄會出現在這裡。';

  @override
  String get modelSettings_interfaceChangedElsewhere => '功能配置已在別處修改，請重新開啟後編輯。';

  @override
  String get modelSettings_configSaved => '配置已儲存';

  @override
  String get modelSettings_viewBuiltinRules => '檢視內建規則';

  @override
  String get modelSettings_viewEditPreset => '檢視與編輯預設';

  @override
  String get modelSettings_restoreBuiltinPreset => '恢復內建預設';

  @override
  String get modelSettings_followUiLanguage => '跟隨介面語言';

  @override
  String get modelSettings_providerAndModel => '服務商與模型';

  @override
  String get modelSettings_providerAndModelHelp => '僅列出啟用服務中的已選模型';

  @override
  String get modelSettings_chooseProviderModel => '選擇服務商與模型';

  @override
  String get modelSettings_reasoning => '思考';

  @override
  String get modelSettings_reasoningHelp =>
      '翻譯通常不需要開啟思考；考慮到介面使用結構化輸出，建議選擇該模型支援的最低思考檔位。';

  @override
  String get modelSettings_reasoningHelpLabel => '思考檔位建議';

  @override
  String get modelSettings_usePreset => '使用預設';

  @override
  String get modelSettings_outputLanguage => '輸出語言';

  @override
  String get modelSettings_englishPrompt => '英文生成提示詞';

  @override
  String get modelSettings_englishPromptHelp => '結合原文落實修改，輸出英文生成提示詞。';

  @override
  String get modelSettings_targetLanguage => '目標語言';

  @override
  String get modelSettings_effective => '當前生效';

  @override
  String get modelSettings_noModelSelected => '尚未選擇可用模型';

  @override
  String modelSettings_reasoningSummaryInterface(Object level) {
    return '思考：$level（本介面）';
  }

  @override
  String modelSettings_reasoningSummaryModel(Object level) {
    return '思考：$level（跟隨模型）';
  }

  @override
  String get modelSettings_promptBlocksHint => '無需翻譯時，也可將提示詞拆分為模組，通過積木功能自由拼裝。';

  @override
  String get modelSettings_wikiFormatHint => '無需翻譯時，也可整理排版併為相關標籤新增連結。';

  @override
  String get modelSettings_unsavedChanges => '有未儲存的修改';

  @override
  String get modelSettings_testPreset => '測試預設';

  @override
  String get modelSettings_tabModelPreset => '模型與預設';

  @override
  String get modelSettings_tabPromptOutput => '提示詞與輸出';

  @override
  String get modelSettings_translationStrategy => '翻譯策略';

  @override
  String get modelSettings_editPreset => '編輯預設';

  @override
  String get modelSettings_outputContract => '應用輸出約定';

  @override
  String get modelSettings_outputContractHint => '返回欄位與校驗規則由應用維護';

  @override
  String get modelSettings_testResult => '測試結果';

  @override
  String get modelRequest_detailsRequests => '請求';

  @override
  String get modelRequest_detailsIndex => '序號';

  @override
  String get modelRequest_detailsResponses => '回應';

  @override
  String get modelRequest_detailsOutput => '提取結果';

  @override
  String get modelRequest_detailsAction => '詳情';

  @override
  String get modelRequest_detailsTitle => '請求記錄';

  @override
  String get modelRequest_detailsCopied => '已複製';

  @override
  String get modelRequest_detailsCopyPage => '複製當前頁';

  @override
  String get modelRequest_detailsOverview => '概覽';

  @override
  String get modelRequest_detailsMissing => '此記錄已清空或已超出最近 100 條。';

  @override
  String get modelPreset_changedElsewhere => '預設已在別處修改，請重新開啟後編輯。';

  @override
  String get modelPreset_interfacePresetChanged => '介面使用的預設已在別處修改，請重新開啟後新增。';

  @override
  String get modelPreset_builtinReadOnly => '內建 · 只讀';

  @override
  String get modelPreset_newInterfacePreset => '新增介面預設';

  @override
  String get modelPreset_tabPrompt => '提示詞';

  @override
  String get modelPreset_tabOutputContract => '輸出約定';

  @override
  String get modelPreset_name => '預設名稱';

  @override
  String get modelPreset_nameRequired => '請輸入名稱';

  @override
  String get modelPreset_behavior => '行為與翻譯策略';

  @override
  String get modelPreset_builtinLocked => '內建規則已鎖定。新增介面預設後可編輯自己的翻譯偏好。';

  @override
  String get modelPreset_editHint => '此處修改翻譯偏好；返回格式由應用單獨維護。';

  @override
  String get modelPreset_strategyHint => '輸入翻譯策略';

  @override
  String get modelPreset_promptRequired => '提示詞不能為空';

  @override
  String get modelPreset_restoreStrategy => '將策略恢復為內建內容';

  @override
  String get modelPreset_outputContractNote => '此部分保證翻譯結果可以回填和顯示，由應用維護。';

  @override
  String get modelPreset_save => '儲存預設';

  @override
  String get modelReasoning_unsupported => '不支援';

  @override
  String get modelReasoning_followModel => '跟隨模型';

  @override
  String modelReasoning_followModelLevel(Object level) {
    return '跟隨模型（$level）';
  }

  @override
  String get modelReasoning_notAdjustable => '此模型不支援思考調節';

  @override
  String get modelReasoning_strength => '思考強度';

  @override
  String modelReasoning_modelDefault(Object level) {
    return '模型預設：$level';
  }

  @override
  String get modelReasoning_levelsUnknown => '可調檔位尚未確認\n可在服務商的模型配置中設定';

  @override
  String modelReasoning_strengthValue(Object level) {
    return '思考強度：$level';
  }

  @override
  String get modelProvider_customEndpoint => '自訂端點';

  @override
  String get modelProvider_pickerTitle => '選擇服務商';

  @override
  String get modelProvider_pickerSearch => '搜尋廠商、平臺或本地服務';

  @override
  String get modelProvider_pickerEmpty => '沒有匹配的服務商';

  @override
  String get modelProvider_groupApiKey => 'API Key 連線';

  @override
  String get modelProvider_groupLocal => '本地服務';

  @override
  String get modelProvider_enterCompatibleAddress => '填寫相容介面地址';

  @override
  String get modelConnection_provider => '服務商';

  @override
  String get modelConnection_name => '名稱';

  @override
  String get modelConnection_nameExample => '例如：自用中轉';

  @override
  String get modelConnection_protocol => '介面協定';

  @override
  String get modelConnection_address => '介面地址';

  @override
  String get modelConnection_apiKey => 'API 金鑰';

  @override
  String modelControls_decrease(Object label, Object step, Object unit) {
    return '減少$label（$step $unit）';
  }

  @override
  String modelControls_increase(Object label, Object step, Object unit) {
    return '增加$label（$step $unit）';
  }

  @override
  String get modelControls_retryOff => '關閉';

  @override
  String modelControls_retryTimes(Object count) {
    return '$count 次';
  }

  @override
  String get settings_positiveIntegerRequired => '請輸入大於 0 的整數';

  @override
  String get modelSettings_testingPreset => '正在測試預設';

  @override
  String modelHealth_lastUpdated(Object time) {
    return '最近更新：$time';
  }

  @override
  String get modelSettings_backToEditing => '返回編輯';

  @override
  String modelService_loadOverridesFailed(Object error) {
    return '讀取自訂請求設定失敗：$error';
  }

  @override
  String get modelService_timeoutRange => '請求逾時應在 10–600 秒之間。';

  @override
  String get modelService_concurrencyRange => '最大併發數量應在 1–20 個之間。';

  @override
  String get modelService_nameRequired => '請輸入服務名稱。';

  @override
  String get modelService_invalidUrl => '介面地址必須是完整的 http:// 或 https:// URL。';

  @override
  String get modelService_contextPositive => '上下文視窗必須大於 0。';

  @override
  String get modelService_readingCatalog => '正在讀取模型目錄…';

  @override
  String modelService_catalogReturned(Object count) {
    return '目錄返回 $count 個模型。勾選需要使用的模型。';
  }

  @override
  String modelService_catalogUnavailable(Object error) {
    return '目錄不可用：$error。可以手動新增模型 ID。';
  }

  @override
  String modelService_catalogCached(Object count) {
    return '已載入上次取得的 $count 個模型。點選“取得列表”可重新整理。';
  }

  @override
  String get modelService_catalogCacheFailed => '模型列表已取得，但本地快取儲存失敗，下次需重新取得。';

  @override
  String get modelService_selectModelFirst => '請先選中一個模型。';

  @override
  String get modelService_testingModel => '正在測試模型請求…';

  @override
  String modelService_testSucceeded(Object reply) {
    return '模型請求成功：$reply';
  }

  @override
  String modelService_testFailed(Object error) {
    return '模型請求失敗：$error';
  }

  @override
  String modelService_tokensPositive(Object name) {
    return '模型“$name”的 token 數量必須大於 0。';
  }

  @override
  String get modelService_changedElsewhere => '服務配置已在別處修改，請重新開啟後編輯。';

  @override
  String get modelService_overridesChangedElsewhere => '模型請求設定已在別處修改，請重新開啟後編輯。';

  @override
  String modelService_saveFailed(Object error) {
    return '儲存失敗：$error';
  }

  @override
  String get modelService_keyHintNew => '輸入 Key；本地服務可留空';

  @override
  String get modelService_keyHintVendor => '輸入此服務商的 Key';

  @override
  String get modelService_keyHintSaved => '已儲存；留空保持原值';

  @override
  String modelService_enabledModels(Object count) {
    return '$count 個啟用模型';
  }

  @override
  String get modelService_pendingSave => '待儲存';

  @override
  String get modelService_saved => '已儲存';

  @override
  String get modelService_enable => '啟用';

  @override
  String get modelService_testConnection => '測試連線';

  @override
  String get modelService_delete => '刪除服務';

  @override
  String get modelService_save => '儲存服務';

  @override
  String get modelService_saving => '正在儲存服務';

  @override
  String get modelService_notConfigured => '尚未配置';

  @override
  String get modelService_optional => '可留空';

  @override
  String get modelService_editConnection => '編輯';

  @override
  String get modelService_collapse => '收起';

  @override
  String get modelService_connectionSettings => '連線設定';

  @override
  String get modelService_dragToReorder => '拖曳調整模型排序';

  @override
  String get modelService_capacityTooltip => '上下文 / 最大輸出；可在進階中調整';

  @override
  String get modelService_advanced => '進階';

  @override
  String modelService_removeModel(Object name) {
    return '刪除模型 $name';
  }

  @override
  String get modelService_linkedInterfaces => '關聯功能';

  @override
  String get modelService_noLinkedInterfaces => '尚未關聯功能';

  @override
  String get modelService_advancedSettings => '進階設定';

  @override
  String get modelService_requestTimeout => '請求逾時';

  @override
  String get modelService_requestTimeoutHelp => '單次請求最長等待時間';

  @override
  String get modelService_seconds => '秒';

  @override
  String get modelService_maxConcurrency => '最大併發數量';

  @override
  String get modelService_maxConcurrencyHelp => '此服務同時處理的請求數';

  @override
  String get modelService_countUnit => '個';

  @override
  String get modelService_retry => '失敗重試';

  @override
  String get modelService_retryHelp => '連線失敗或服務繁忙時重試';

  @override
  String get modelService_searchModelId => '搜尋模型 ID…';

  @override
  String get modelService_serviceModels => '該服務的模型';

  @override
  String get modelService_fetchList => '取得列表';

  @override
  String get modelService_catalogEmpty => '點選“取得列表”讀取此服務的模型，\n或在右側手動新增模型 ID。';

  @override
  String get modelService_noMatchingModels => '沒有匹配的模型';

  @override
  String get modelService_catalogLimitTooltip => '目錄上限：上下文 / 最大輸出';

  @override
  String get modelService_searchAddedModels => '搜尋已新增模型…';

  @override
  String get modelService_modelSettings => '模型設定';

  @override
  String get modelService_addedEmpty => '從左側勾選，或在下方新增模型';

  @override
  String get modelService_customModelId => '自訂模型 ID';

  @override
  String get modelService_customModelHelp => '新增模型目錄無法拉取到的模型';

  @override
  String get modelService_addCustomModel => '新增自訂模型';

  @override
  String get modelCard_positiveInteger => '請輸入正整數';

  @override
  String modelCard_catalogLimit(Object limit) {
    return '目錄上限 $limit';
  }

  @override
  String get modelCard_outputExceedsContext => '輸出不能超過上下文視窗';

  @override
  String get modelCard_contextWindow => '上下文視窗';

  @override
  String get modelCard_maxOutput => '最大輸出';

  @override
  String get modelCard_unlabeled => '未標註';

  @override
  String get modelCard_protocolStandard => '標準';

  @override
  String get modelCard_protocolAdaptive => '自適應';

  @override
  String get modelCard_default => '預設';

  @override
  String get modelCard_thinkingLevels => '思考等級';

  @override
  String get modelCard_thinkingLevelsUnlisted => '目錄未標註，可手動開啟';

  @override
  String get modelCard_thinkingLevelsFromCatalog => '已按本地目錄勾選支援的等級；可按實際介面調整。';

  @override
  String get modelCard_thinkingProtocol => '思考協定';

  @override
  String get modelCard_defaultThinkingLevel => '預設思考等級';

  @override
  String get modelCard_alias => '別名';

  @override
  String get modelCard_aliasHelp => '在顯示模型名稱的地方生效；請求仍使用模型 ID。';

  @override
  String get modelCard_aliasExample => '例如 fast';

  @override
  String get modelCard_capabilities => '能力';

  @override
  String get modelCard_images => '圖片';

  @override
  String get modelCard_nativeSearch => '原生網路搜尋';

  @override
  String get modelCard_nativeSearchHelp =>
      '應用尚未適配此連線的原生搜尋；不代表廠商網站或其他 API 不支援搜尋。';

  @override
  String get modelOverrides_duplicateHeader => '請求標頭名稱重複';

  @override
  String get modelOverrides_fieldNameRequired => '請輸入欄位名';

  @override
  String get modelOverrides_duplicateField => '欄位名重複';

  @override
  String get modelOverrides_invalidJson => '請輸入有效的 JSON 值';

  @override
  String get modelOverrides_customBody => '自訂 Body';

  @override
  String get modelOverrides_customHeaders => '自訂 Headers';

  @override
  String get modelOverrides_fieldName => '欄位名';

  @override
  String get modelOverrides_headerName => '請求標頭名稱';

  @override
  String get modelOverrides_valueJson => '值（JSON）';

  @override
  String get modelOverrides_value => '值';

  @override
  String get modelOverrides_removeItem => '刪除此項';

  @override
  String get modelOverrides_body => '請求主體';

  @override
  String get modelOverrides_headers => '請求標頭';

  @override
  String modelOverrides_itemCount(Object count) {
    return '$count 項';
  }

  @override
  String get modelOverrides_valueTypes => '支援字串、數字、布林值、陣列和物件';

  @override
  String get modelOverrides_addBodyField => '新增請求主體欄位';

  @override
  String get modelOverrides_addHeader => '新增請求標頭';

  @override
  String get promptTranslation_translating => '正在翻譯';

  @override
  String get promptTranslation_needsModel => '翻譯 · 先配置模型';

  @override
  String promptTranslation_withRoute(Object provider, Object model) {
    return '翻譯 · $provider / $model';
  }

  @override
  String get promptTranslation_actions => '翻譯操作';

  @override
  String get promptTranslation_promptChanged => '提示詞已變化，未覆蓋新編輯';

  @override
  String get promptTranslation_nothingToTranslate => '當前沒有需要翻譯的普通文字';

  @override
  String promptTranslation_failed(Object error) {
    return '翻譯失敗：$error';
  }

  @override
  String get promptTranslation_setupTitle => '先配置翻譯模型';

  @override
  String get promptTranslation_setupBody =>
      '翻譯需要明確選擇服務商和模型。前往「設定 → 整合 → 模型與介面」，先新增服務商並取得模型列表，再在「提示詞翻譯」卡片中完成選擇。';

  @override
  String get promptTranslation_later => '稍後';

  @override
  String get promptTranslation_openSettings => '前往設定';

  @override
  String get promptTranslation_toolTitle => '翻譯';

  @override
  String get promptTranslation_noModel => '未配置模型';

  @override
  String get promptTranslation_configureModel => '配置翻譯模型';

  @override
  String get promptTranslation_translateNew => '翻譯新增內容';

  @override
  String get promptTranslation_undoRestore => '復原原文還原，恢復翻譯塊';

  @override
  String get promptTranslation_restoreAll => '全部翻譯塊還原為原文文本';

  @override
  String get promptTranslation_tutorial => '操作教程';

  @override
  String get promptTranslation_guideBack => '返回操作';

  @override
  String get promptTranslation_guideMiddleTitle => '中鍵點塊';

  @override
  String get promptTranslation_guideMiddleText => '切換原文與譯文';

  @override
  String get promptTranslation_guideSourceTitle => '左鍵點原文';

  @override
  String get promptTranslation_guideSourceText => '定位游標，直接修改';

  @override
  String get promptTranslation_guideReadingTitle => '左鍵點譯文';

  @override
  String get promptTranslation_guideReadingText => '開啟塊編輯窗';

  @override
  String get promptTranslation_guideCtrlTitle => 'Ctrl + 點選 / 拖選';

  @override
  String get promptTranslation_guideCtrlText => '編輯窗內搜尋標籤 / 查關聯';

  @override
  String get promptTranslation_guideConvertTitle => '↑ 中文轉原文';

  @override
  String get promptTranslation_guideConvertText => '↓ 原文轉中文，檢查後儲存';

  @override
  String get promptTranslation_guideRestoreTitle => '切換整組顯示';

  @override
  String get promptTranslation_guideRestoreText => '在翻譯選單中切換全部原文 / 譯文';

  @override
  String get promptTranslation_middleButton => '滑鼠中鍵';

  @override
  String get promptTranslation_leftButton => '滑鼠左鍵';

  @override
  String get promptTranslation_blockShowingOriginal => '翻譯塊，顯示原文';

  @override
  String get promptTranslation_blockShowingReading => '翻譯塊，顯示譯文';

  @override
  String get promptTranslation_blockNeedsReview => '原文已修改 · 譯文待更新';

  @override
  String get promptTranslation_badgeTooltip => '原文已修改，中文待同步';

  @override
  String get promptTranslation_sourceChanged => '原文已變化，請重新開啟翻譯塊';

  @override
  String promptTranslation_retranslateFailed(Object error) {
    return '重新翻譯失敗：$error';
  }

  @override
  String get promptTranslation_draftChanged => '內容已修改，請重新轉換；新草稿已保留';

  @override
  String promptTranslation_convertFailed(Object error) {
    return '轉換失敗，草稿已保留：$error';
  }

  @override
  String get promptTranslation_invalidResultFormat => '轉換結果格式不正確，草稿已保留';

  @override
  String get promptTranslation_noValidText => '模型沒有返回有效文字，草稿已保留';

  @override
  String get promptTranslation_invalidResultContent => '轉換結果包含無效格式，草稿已保留';

  @override
  String get promptTranslation_incompleteStructure => '轉換結果的權重或分組不完整，草稿已保留';

  @override
  String get promptTranslation_inputRequired => '請先輸入需要轉換的內容';

  @override
  String get wiki_configureTagModel => '請先在「模型與介面」配置可用的標籤翻譯模型。';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '目標中已有 $count 個同源副本。替換後來源從塊庫隱藏；已插入提示詞的實例仍可引用原塊。';
  }

  @override
  String get blockLibrary_changedSelectAgain => '塊庫已變化，請重新選擇後再試';

  @override
  String get blockLibrary_hiddenSource => '隱藏的塊不能作為整理來源';

  @override
  String get blockLibrary_sameSourceSelected => '所選塊包含同源副本，請分開整理';

  @override
  String get blockLibrary_sameSourceExists => '同源塊已存在，請確認替換';

  @override
  String get blockLibrary_collectionMissing => '收藏集不存在';

  @override
  String get blockAppearance_classic => '經典';

  @override
  String get blockAppearance_stripes => '細條紋';

  @override
  String get blockAppearance_dots => '圓點';

  @override
  String get blockAppearance_solid => '實心';

  @override
  String get blockAppearance_gradient => '漸變';

  @override
  String get blockAppearance_translation => '翻譯';

  @override
  String opusUsage_regularRemaining(Object percent) {
    return '常規免費額度：$percent%';
  }

  @override
  String opusUsage_reserveRemaining(Object percent) {
    return '備用電池額度（已啟用）：$percent%';
  }

  @override
  String get opusUsage_usingRegular => '優先使用常規額度，用盡後使用備用額度';

  @override
  String get opusUsage_usingReserve => '常規額度已用盡，正在使用備用電池額度';

  @override
  String get opusUsage_regularEmpty => '常規額度已用盡，暫無可用備用額度';

  @override
  String get opusUsage_exhausted => '帳號額度已用盡，V5 生成按 Anlas 計費';

  @override
  String opusUsage_recharging(Object time) {
    return '常規額度回充：下一 +1% 還需 $time';
  }

  @override
  String get opusUsage_notRecharging => '常規額度當前無回充倒計時';

  @override
  String get opusUsage_clickToRefresh => '點選重新整理';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 小時 $minutes 分';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String opusUsage_seconds(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get metadataImport_noCharactersReplaceClears => '無角色資料；替換模式會清空當前角色';

  @override
  String get metadataImport_replaceCharacters => '替換角色';

  @override
  String get metadataImport_appendCharacters => '追加角色';

  @override
  String get drop_dragToShare => '拖曳以分享';

  @override
  String promptSyntax_weightTooLarge(Object value) {
    return '數值權重絕對值過大：$value::';
  }

  @override
  String promptSyntax_spaceBeforeColons(Object value) {
    return '權重數字與 :: 之間不能有空格：$value ::';
  }

  @override
  String promptSyntax_weightAfterColons(Object value) {
    return '數值權重應寫在 :: 前：::$value';
  }

  @override
  String get update_errorInAppUnsupported => '當前版本不支援應用內自動安裝更新';

  @override
  String get update_errorNoInstallablePackage => '未找到可自動安裝的更新包';

  @override
  String get update_errorMissingSha256 => '更新包缺少 SHA256 校驗資訊';

  @override
  String get update_errorDiskFull => '磁碟空間不足，無法儲存更新包';

  @override
  String get update_errorWriteFailed => '寫入更新包失敗';

  @override
  String get update_errorDownloadFailed => '下載更新包失敗';

  @override
  String get update_errorSizeMismatch => '更新包大小校驗失敗';

  @override
  String get update_errorChecksumMismatch => '更新包校驗失敗';

  @override
  String get update_errorResumeRejected => '伺服器拒絕了更新包續傳請求';

  @override
  String get update_errorEmptyResponse => '更新伺服器返回了空回應';

  @override
  String get update_errorPlatformUnsupported => '當前平臺不支援應用內自動更新';

  @override
  String get update_errorPackageRemoved => '更新包已被清理，請重新下載';

  @override
  String get update_errorPackageCorrupted => '更新包已損壞，請重新下載';

  @override
  String get update_errorLaunchFailed => '啟動更新程式失敗';

  @override
  String get update_errorCheckFailed => '檢查更新失敗';

  @override
  String get update_errorCheckUnknown => '檢查更新時發生未知錯誤';

  @override
  String update_errorLogPath(Object path) {
    return '日誌：$path';
  }

  @override
  String get update_errorInstallFailed => '安裝更新失敗';

  @override
  String get update_errorInstallFailedSeeLog => '安裝更新失敗，請檢視更新日誌';

  @override
  String get auth_tokenEmpty => 'Token 為空，無法驗證';

  @override
  String get auth_tokenFormatInvalid => 'Token 格式無效';

  @override
  String get auth_tokenInvalidOrExpired =>
      'Token無效或已過期，請檢查Token是否正確。如果是Persistent Token，應以pst-開頭。';

  @override
  String get auth_tokenMustStartPst => 'Token 格式無效，應以 pst- 開頭';

  @override
  String get auth_tokenFormatDetail =>
      'Token 格式無效。Persistent Token 應以 pst- 開頭，後跟至少10位字元。請檢查輸入的 Token 是否正確。';

  @override
  String get danbooru_credentialsExpired => '憑據已失效，請重新登入';

  @override
  String get danbooru_networkRetryLater => '網路連線失敗，將在網路恢復後重試';

  @override
  String get danbooru_invalidCredentials => '無法驗證憑據，請檢查使用者名稱和 API Key 是否正確';

  @override
  String danbooru_verifyFailed(Object error) {
    return '驗證失敗: $error';
  }

  @override
  String get danbooru_credentialsRequired => '使用者名稱和 API Key 不能為空';

  @override
  String get danbooru_networkCheck => '網路連線失敗，請檢查網路連線';

  @override
  String get danbooru_loginFailedNetwork => '登入失敗，請檢查網路連線';

  @override
  String get danbooru_blacklistLoginRequired => '請先登入 Danbooru 帳號';

  @override
  String get danbooru_blacklistPushFailed => '推送 Danbooru 黑名單失敗';

  @override
  String danbooru_blacklistSyncFailed(Object error) {
    return '同步失敗: $error';
  }

  @override
  String comfyui_submitFailed(Object detail) {
    return '提交工作流失敗: $detail';
  }

  @override
  String comfyui_uploadFailed(Object detail) {
    return '上傳影像失敗: $detail';
  }

  @override
  String comfyui_fetchImageFailed(Object detail) {
    return '取得影像失敗: $detail';
  }

  @override
  String comfyui_historyMissing(Object id) {
    return '未找到任務歷史: $id';
  }

  @override
  String get comfyui_unknownError => '未知錯誤';

  @override
  String comfyui_cannotConnect(Object url) {
    return '無法連線到 ComfyUI 伺服器 ($url)';
  }

  @override
  String get comfyui_noOutput => '任務無輸出';

  @override
  String comfyui_nodesNoImage(Object nodes) {
    return '指定輸出節點無影像輸出: $nodes';
  }

  @override
  String get comfyui_noImageOutput => '任務無影像輸出';

  @override
  String get comfyui_executionError => '執行出錯';

  @override
  String comfyui_missingNodes(Object nodes) {
    return '缺少 ComfyUI 節點: $nodes。請在 ComfyUI 中安裝或啟用對應自訂節點後重啟 ComfyUI。';
  }

  @override
  String get enhance_cannotReadSize => '無法解析影像尺寸';

  @override
  String enhance_upscaleFailed(Object error) {
    return '影像放大失敗: $error';
  }

  @override
  String enhance_vibeEncodeFailed(Object error) {
    return 'Vibe編碼失敗: $error';
  }

  @override
  String enhance_enhanceFailed(Object error) {
    return '影像增強失敗: $error';
  }

  @override
  String enhance_annotateFailed(Object error) {
    return '影像標註失敗: $error';
  }

  @override
  String get enhance_timeout => '請求逾時';

  @override
  String get enhance_networkError => '網路連線錯誤';

  @override
  String enhance_serverError(Object status) {
    return '伺服器返回錯誤: $status';
  }

  @override
  String enhance_serverErrorDetail(Object status, Object detail) {
    return '伺服器返回錯誤: $status ($detail)';
  }

  @override
  String get proxy_connectTimeout => '連線逾時';

  @override
  String get proxy_cannotConnect => '無法連線到伺服器';

  @override
  String get proxy_connectFailed => '連線失敗';

  @override
  String get proxy_testServerUnreachable => '無法連線到測試伺服器';

  @override
  String proxy_testFailed(Object error) {
    return '測試失敗: $error';
  }

  @override
  String get avatar_noFilePath => '無法取得檔案路徑';

  @override
  String get avatar_sourceMissing => '來源檔案不存在或已被刪除';

  @override
  String avatar_copyFailed(Object error) {
    return '無法複製檔案：$error';
  }

  @override
  String avatar_saveFailed(Object error) {
    return '無法儲存頭像：$error';
  }

  @override
  String avatar_operationFailed(Object error) {
    return '操作失敗：$error';
  }

  @override
  String get vibeExport_rawImage => '原始圖片';

  @override
  String get vibeExport_vibePreview => 'Vibe 預覽圖';

  @override
  String get vibeExport_libraryThumbnail => '庫縮圖';

  @override
  String get vibeExport_pngTitle => '匯出 PNG Vibe 圖片';

  @override
  String get vibeExport_pngDirectoryTitle => '選擇 PNG 匯出目錄';

  @override
  String get vibeExport_fileTitle => '匯出 Vibe 檔案';

  @override
  String get vibeExport_bundleTitle => '匯出 Vibe Bundle';

  @override
  String get vibeExport_zipTitle => '匯出 Vibe ZIP';

  @override
  String get vibeExport_nothingToExport => '沒有可匯出的 Vibe 條目';

  @override
  String get vibeImport_fileParseFailed => '檔案解析失敗';

  @override
  String get vibeImport_importFiles => '匯入檔案';

  @override
  String get vibeImport_noVibeData => '圖片不包含有效 Vibe 資料';

  @override
  String get vibeImport_importImages => '匯入圖片';

  @override
  String get vibeImport_encodingParseFailed => '編碼解析失敗';

  @override
  String get vibeImport_importEncodings => '匯入編碼';

  @override
  String vibeImport_namingCancelled(Object name) {
    return '使用者取消命名，已跳過: $name';
  }

  @override
  String vibeImport_nameEmpty(Object name) {
    return '名稱為空，已跳過: $name';
  }

  @override
  String vibeImport_nameConflict(Object name) {
    return '名稱衝突，已跳過: $name';
  }

  @override
  String get vibeImport_saveFailed => '儲存失敗';

  @override
  String vibeFile_missingRawImage(Object file) {
    return '檔案缺少可用的原圖資料: $file (type=image). 此檔案可能已損壞或不完整，建議刪除後重新儲存。';
  }

  @override
  String get generation_countMustBePositive => '生成數量必須大於0';

  @override
  String get generation_allTasksFailed => '所有生成任務失敗';

  @override
  String get generation_failedShort => '生成失敗';

  @override
  String generation_tasksFailedAfterRetry(Object count) {
    return '$count 個任務重試後仍失敗';
  }

  @override
  String get generation_streamFallbackUnavailable => '流式生成不支援且無法自動回退（參數丟失）';

  @override
  String generation_streamFallbackFailed(Object error) {
    return '回退到非流式生成失敗: $error';
  }

  @override
  String get generation_batchSizeMustBePositive => '批次數量和批次大小必須大於0';

  @override
  String get clipboard_unsupportedPlatform => '當前平臺不支援系統剪貼簿';

  @override
  String get clipboard_decodeFailed => '無法解碼圖片用於複製到剪貼簿';

  @override
  String drop_remoteImageTooLarge(Object size) {
    return '遠端圖片原始下載超過 ${size}MB';
  }

  @override
  String get apiEndpoint_empty => 'API 地址不能為空';

  @override
  String get apiEndpoint_invalid => 'API 地址無效';

  @override
  String get apiEndpoint_httpOnly => '僅支援 http 或 https API 地址';

  @override
  String get apiEndpoint_noExtras => 'API 地址不能包含查詢參數、片段或使用者資訊';

  @override
  String gallery_folderInaccessible(Object error) {
    return '無法存取圖片資料夾: $error';
  }

  @override
  String gallery_scanFailed(Object error) {
    return '掃描圖片失敗: $error';
  }

  @override
  String gallery_galleryInitFailed(Object error) {
    return '畫廊初始化失敗: $error';
  }

  @override
  String get resolution_noAdjustment => '無需調整';

  @override
  String get dataRefresh_updating => '正在更新資料...';

  @override
  String dataRefresh_updatingService(Object service) {
    return '正在更新 $service...';
  }

  @override
  String get imageUse_title => '使用圖片';

  @override
  String get imageUse_importContent => '匯入內容';

  @override
  String get imageUse_characters => '多角色';

  @override
  String get imageUse_characterMode => '角色處理';

  @override
  String get imageMenu_details => '詳情';

  @override
  String get imageMenu_creation => '創作與參考';

  @override
  String get imageMenu_editAndDerive => '編輯與派生';

  @override
  String get imageMenu_more => '更多操作';

  @override
  String get imageMenu_fileActions => '檔案操作';

  @override
  String get imageMenu_saveToBlock => '存入積木';

  @override
  String get settings_highAnlasCostEstimate => '預計消耗';

  @override
  String get settings_highAnlasCostThresholdLabel => '提醒閾值';

  @override
  String get settings_highAnlasCostQuestion => '是否繼續本次生成？';

  @override
  String get bridge_title => '本機橋接';

  @override
  String get bridge_agent => '外部 Agent';

  @override
  String get bridge_agentHint => '複製說明，交給能執行本機命令的 Agent。';

  @override
  String get bridge_synced => '當前內容已確認';

  @override
  String get bridge_changed => '內容已變化，等待重新確認';

  @override
  String get bridge_waiting => '等待連線';

  @override
  String get bridge_ready => '等待操作';

  @override
  String bridge_clients(int count) {
    return '$count 個 Agent 已連線';
  }

  @override
  String bridge_activity(Object client, Object action) {
    return '$client：$action';
  }

  @override
  String get bridge_read => '讀取參數';

  @override
  String get bridge_write => '修改參數';

  @override
  String get bridge_quote => '預估消耗';

  @override
  String get bridge_generate => '生成圖片';

  @override
  String get bridge_cancel => '停止生成';

  @override
  String get bridge_recent => '最近活動';

  @override
  String get bridge_empty => '尚無活動';

  @override
  String get bridge_copyGuide => '複製接管說明';

  @override
  String get bridge_showGuide => '檢視說明';

  @override
  String get bridge_copied => '接管說明已複製';

  @override
  String get bridge_disconnect => '結束 Agent 連線';

  @override
  String get bridge_settings => '橋接設定';

  @override
  String get bridge_clientMissing => '隨包客戶端尚未就緒，請更新 Studio。';

  @override
  String get bridge_conflict => '內容已修改，請重新讀取';

  @override
  String get bridge_busy => '另有操作正在進行';

  @override
  String get bridge_interrupted => '操作已中斷';

  @override
  String get bridge_failed => '操作失敗，請檢視 Agent 返回的資訊';

  @override
  String get bridge_timeout => '操作逾時，請重試';

  @override
  String bridge_guide(Object clientPath) {
    return '請通過本機橋接協助操作 W.O.F NAI Studio。\n客戶端：$clientPath\n\n1. 根據你的 shell 正確引用這個路徑。先執行 status --name <你的名稱>，確認連線成功；複製本說明不代表已連線。\n2. 執行 get --name <你的名稱> --out current.json，讀取當前狀態。可編輯原文在 _draft.fields，field_versions 用於檢查衝突；其餘讀數可能包含品質詞等生效內容。不要把生效內容重複寫回原文。\n3. 只修改使用者授權的欄位。將修改寫入 changes.json，再執行 set-json changes.json --base current.json --name <你的名稱>。應用會先備份，再核對這些欄位；衝突時停止並重新讀取，不能自動覆蓋使用者新修改。返回 readback 用於核對寫入。characters 是整個列表替換，請保留無關角色的名稱、啟用狀態、位置和 id。參考圖目前只讀，請保留 Studio 中的設定。\n4. 接入或填參不代表授權生圖。只有使用者明確要求生成時，先執行 quote --out quote.json --name <你的名稱>，向用戶報告預計 Anlas 單價和餘額（餘額來自當前已載入帳號，實際計費以服務端為準）。授權與報告完成後執行 gen --quote quote.json --authorized --name <你的名稱>。每次只生成一張；草稿改變會拒絕舊估價。\n5. 操作結束自動斷開。Krita 可同時連線；busy 時等待當前操作結束，失敗後不要無間隔重試。生成可在 Studio 中停止；客戶端也支援 Ctrl+C，或用返回的 request_id 執行 cancel <request_id> --name <同一名稱>。不要輸出發現檔案中的會話金鑰。\n';
  }

  @override
  String get editor_drawMask => '繪製遮罩';

  @override
  String get editor_eraseMask => '擦除遮罩';

  @override
  String get editor_squareBrush => '方形畫筆';

  @override
  String get editor_focusedArea => '聚焦區域';

  @override
  String get editor_minimumContext => '最小上下文邊距';

  @override
  String get editor_maskAppearance => '遮罩外觀';

  @override
  String get editor_maskColor => '遮罩顏色';

  @override
  String get editor_maskOpacity => '遮罩透明度';

  @override
  String get editor_maskBorder => '邊框';

  @override
  String get editor_patternSolid => '純色';

  @override
  String get editor_patternLines => '斜線';

  @override
  String get editor_patternCrosshatch => '交叉線';

  @override
  String get editor_patternDots => '圓點';

  @override
  String get editor_patternGrid => '網格';

  @override
  String get editor_patternChecker => '棋盤格';

  @override
  String get editor_patternHearts => '愛心';

  @override
  String get editor_resize => '調整尺寸';

  @override
  String get editor_penSize => '畫筆大小';

  @override
  String get editor_sourceChanged => '來源圖已在編輯期間發生變化，請重新開啟編輯器。';

  @override
  String get editor_draw => '繪製';

  @override
  String get editor_erase => '擦除';

  @override
  String get editor_select => '選擇';

  @override
  String get editor_lasso => '套索';

  @override
  String get editor_roundTip => '圓形';

  @override
  String get editor_softRoundTip => '柔邊圓形';

  @override
  String get editor_squareTip => '方形';

  @override
  String get editor_pressureSensitivity => '筆壓感應';

  @override
  String get editor_hsvAdjustment => 'HSV 調整';

  @override
  String get editor_hue => '色相';

  @override
  String get editor_cloneSourceHint => 'Alt + 點選設定來源';

  @override
  String get editor_colorAlpha => '透明度';

  @override
  String get editor_colorHex => '顏色 HEX';

  @override
  String get editor_closestValidSize => '裁至最近的有效生成尺寸';

  @override
  String get model3d_projection => '投影';

  @override
  String get model3d_perspective => '透視投影';

  @override
  String get model3d_orthographic => '平行投影';

  @override
  String get model3d_fov => '視野角';

  @override
  String get model3d_ambient => '環境光';

  @override
  String get model3d_direct => '直接光';

  @override
  String get model3d_direction => '光線方向';

  @override
  String get model3d_front => '正面';

  @override
  String get model3d_frontTop => '正面上方';

  @override
  String get model3d_top => '頂部';

  @override
  String get model3d_left => '左側';

  @override
  String get model3d_right => '右側';

  @override
  String get model3d_back => '背面';

  @override
  String get model3d_shadows => '陰影';

  @override
  String get model3d_quality => '品質';

  @override
  String get model3d_veryLow => '極低';

  @override
  String get model3d_low => '低';

  @override
  String get model3d_medium => '中';

  @override
  String get model3d_high => '高';

  @override
  String get model3d_veryHigh => '極高';

  @override
  String get model3d_display => '顯示';

  @override
  String get model3d_showBones => '顯示骨骼';

  @override
  String get model3d_bones => '骨骼列表';

  @override
  String get model3d_noBones => '未找到骨骼';

  @override
  String get model3d_morphs => '表情形變';

  @override
  String get model3d_noMorphs => '未找到表情形變';

  @override
  String get model3d_settings => '3D 渲染設定';

  @override
  String get model3d_resetModel => '重設模型位置';

  @override
  String get model3d_removeModel => '移除模型';

  @override
  String get model3d_removeConfirm => '移除此模型？尚未儲存的模型編輯將丟失。';

  @override
  String get model3d_toolTransform => '模型變換';

  @override
  String get model3d_toolPose => '模型姿勢';

  @override
  String get localUpscale_local => '本地';

  @override
  String get localUpscale_manage => '管理模型';

  @override
  String get localUpscale_description => '在本機放大圖片，不消耗 Anlas。';

  @override
  String get localUpscale_bundled => '內建';

  @override
  String get localUpscale_download => '下載';

  @override
  String get localUpscale_importHelp =>
      '匯入配套的 4 倍 Real-ESRGAN NCNN 模型 .param 和 .bin 檔案（data/output 節點）。不支援 PyTorch 或 safetensors 模型。';

  @override
  String get localUpscale_preparing => '正在準備圖片…';

  @override
  String get localUpscale_inference => '正在超分…';

  @override
  String get localUpscale_resizing => '正在完成圖片處理…';

  @override
  String get localUpscale_complete => '超分完成';

  @override
  String get localUpscale_cancelling => '正在取消…';

  @override
  String get localUpscale_unsupportedPlatform => '本地超分目前支援 Windows。';

  @override
  String get localUpscale_engineMissing => '本地引擎不可用，請重新安裝完整 Studio 執行包。';

  @override
  String get localUpscale_integrity => '檔案校驗失敗，請重新安裝對應模型或 Studio 執行包。';

  @override
  String get localUpscale_modelMissing => '模型不可用，請選擇已安裝的模型，或檢查模型目錄路徑是否過長。';

  @override
  String get localUpscale_invalidModel =>
      '模型不相容，請匯入配套的 4 倍 Real-ESRGAN NCNN 模型。';

  @override
  String get localUpscale_invalidImage => '無法讀取圖片，請嘗試 PNG、JPEG 或 WebP 檔案。';

  @override
  String get localUpscale_sizeLimit => '圖片過大：模型原始輸出不能超過 6400 萬像素。';

  @override
  String get localUpscale_noVulkan => '未找到可用的 Vulkan 顯示卡，請更新顯示卡驅動後重試。';

  @override
  String get localUpscale_processFailed => '超分失敗，請檢查模型和顯示卡驅動。原圖已保留。';

  @override
  String get localUpscale_timeout => '超分逾時，請嘗試較小的圖片。';

  @override
  String get localUpscale_busy => '另一個超分或模型操作仍在執行。';

  @override
  String get localUpscale_cancelled => '已取消超分';

  @override
  String get localUpscale_anime => '動漫 · 畫質';

  @override
  String get localUpscale_animeFast => '動漫 · 快速';

  @override
  String get localUpscale_general => '通用 · 攝影';

  @override
  String get localUpscale_downloadProgress => '正在下載模型…';

  @override
  String get localUpscale_importModel => '匯入模型';

  @override
  String get localUpscale_modelOperationFailed => '模型操作失敗，請檢查網路、檔案權限及可用空間後重試。';

  @override
  String get settings_localUpscale => '本地放大';

  @override
  String get settings_localUpscaleDescription => '管理本地放大模型與執行元件。';

  @override
  String get localUpscale_noCuda => '需要支援 CUDA 的 NVIDIA 顯示卡及相容的驅動。';

  @override
  String get localUpscale_noRtx => 'RTX Video 不可用，請檢查 NVIDIA RTX 顯示卡與驅動。';

  @override
  String get localUpscale_encoding => '正在編碼圖片…';

  @override
  String get localUpscale_decoding => '正在解碼圖片…';

  @override
  String get localUpscale_optionalComponents => '可選元件';

  @override
  String get localUpscale_noAutomaticDownload => '按需下載元件，已有的本地模型可直接使用。';

  @override
  String get localUpscale_notInstalledShort => '未安裝';

  @override
  String get localUpscale_seedvr2ThreeSummary => '兼顧效果與資源佔用，適合日常放大。';

  @override
  String get localUpscale_seedvr2SevenSummary => '更高畫質潛力，需要更多視訊記憶體與時間。';

  @override
  String get localUpscale_seedvr2SharpSummary => '偏向更銳利的細節，適合希望強化紋理的圖片。';

  @override
  String get localUpscale_seedvr2SharpHelp =>
      '7B Sharp FP8 偏向更銳利的紋理與邊緣。權重約 8.2 GB；與其他 SeedVR2 型號共用 VAE 和 Python/CUDA 環境。';

  @override
  String get localUpscale_seedvr2Int8Help =>
      'INT8 ConvRot（實驗）：需要 NVIDIA Turing 或更新顯示卡。與 FP8 共用執行環境，速度與畫質因圖片和顯示卡而異。';

  @override
  String get localUpscale_noInt8 => '當前顯示卡或 CUDA 環境不支援原生 INT8，請選擇 FP8。';

  @override
  String get localUpscale_seedvr2SharedHelp =>
      '型號共用 VAE（約 0.5 GB）和 Python/CUDA 環境，需要 NVIDIA 顯示卡。';

  @override
  String get localUpscale_seedvr2Help =>
      '3B FP8 兼顧效果與資源佔用。權重約 3.4 GB，VAE 約 0.5 GB；與 7B 共用 VAE 和 Python/CUDA 環境，需要 NVIDIA 顯示卡。';

  @override
  String get localUpscale_seedvr2SevenHelp =>
      '7B FP8 有更高的畫質潛力，但需要更多視訊記憶體與時間。權重約 8.2 GB；與 3B 共用 VAE 和 Python/CUDA 環境。';

  @override
  String get localUpscale_outOfMemory =>
      '視訊記憶體不足。可改用 3B、降低倍率，或在進階設定啟用低視訊記憶體和 VAE 分塊。沒有自動切換型號。';

  @override
  String get localUpscale_modelWeights => '權重';

  @override
  String get localUpscale_advancedSettings => '進階設定';

  @override
  String get localUpscale_seedvr2Color => '色彩校正';

  @override
  String get localUpscale_colorNone => '不校正';

  @override
  String get localUpscale_seedvr2Seed => '隨機種子';

  @override
  String get localUpscale_seedvr2Memory => '視訊記憶體策略';

  @override
  String get localUpscale_memoryRecommended => '推薦';

  @override
  String get localUpscale_memoryLow => '低視訊記憶體';

  @override
  String get localUpscale_blocksToSwap => 'CPU 卸載層數';

  @override
  String get localUpscale_memoryHelp =>
      '卸載更多層可省視訊記憶體，但會佔用更多記憶體並變慢。低視訊記憶體模式不保證任意輸出尺寸都能執行。';

  @override
  String get localUpscale_vaeTiled => 'VAE 分塊';

  @override
  String get localUpscale_vaeTileSize => '分塊大小';

  @override
  String get localUpscale_vaeOverlap => '分塊重疊';

  @override
  String get localUpscale_vaeHelp =>
      '小分塊更省視訊記憶體，重疊可減輕接縫。這是 VAE 編碼／解碼分塊，不是整條超分流程分塊。';

  @override
  String get localUpscale_experimental => '實驗性變化';

  @override
  String get localUpscale_inputNoise => '輸入噪聲';

  @override
  String get localUpscale_latentNoise => '潛空間噪聲';

  @override
  String get localUpscale_noiseHelp =>
      '兩項保持 0 可沿用當前行為。增加噪聲是增加變化，不保證細節或畫質更好，也可能改變線條和臉部。';

  @override
  String get localUpscale_restoreDefaults => '恢復預設';

  @override
  String get localUpscale_rtxHelp =>
      '使用 NVIDIA RTX Video 快速放大。需下載約 64 MB 獨立元件，需要相容的 RTX 顯示卡。';

  @override
  String get localUpscale_installed => '已安裝';

  @override
  String get localUpscale_notInstalled => '尚未安裝，請到管理模型安裝';

  @override
  String get localUpscale_license => '許可';

  @override
  String get localUpscale_installComponent => '安裝';

  @override
  String get localUpscale_installingRuntime => '正在安裝 Python/CUDA 執行環境…';

  @override
  String get localUpscale_installingPython => '正在準備獨立 Python…';

  @override
  String localUpscale_installFailed(String stage) {
    return '安裝失敗階段：$stage';
  }

  @override
  String get wiki_translationQueued => '等待翻譯';

  @override
  String get wiki_translationFailedRetry => '翻譯失敗，點選重試';

  @override
  String get localUpscale_checkingComponent => '正在檢查元件與顯示卡…';

  @override
  String get localUpscale_installingComponent => '正在下載元件…';

  @override
  String get upscale_settings => '放大設定';

  @override
  String upscale_cloudCost(int cost) {
    return '預計 $cost Anlas · 2×';
  }

  @override
  String get enhance_localAfterGeneration => '每張生成完成後自動在本機放大。';

  @override
  String get enhance_localAction => '生成並本地放大';

  @override
  String get localUpscale_stop => '停止超分';

  @override
  String get localUpscale_scrollDown => '向下滾動';

  @override
  String get wiki_exampleImages => '示例圖片';

  @override
  String get wiki_exampleImagesUnavailable => '示例圖片暫時無法載入';

  @override
  String get generation_perRequestLabel => '張數';

  @override
  String get generation_perRequestTooltip => '每次請求生成的張數（1–4）';

  @override
  String get generation_repeatLabel => '重複';

  @override
  String get generation_referenceUpload => '上傳';

  @override
  String get generation_seedPinnedLabel => '種子 · 固定';

  @override
  String get generation_paramsDrawerTooltip => '更多參數';

  @override
  String get library_sizeSmall => '小';

  @override
  String get library_sizeMedium => '中';

  @override
  String get library_sizeLarge => '大';

  @override
  String get library_currentModel => '當前模型';

  @override
  String get library_available => '可用';

  @override
  String get library_unavailable => '不能用';

  @override
  String get library_inGeneration => '在生圖頁';

  @override
  String library_selectedCount(int count) {
    return '已選 $count 個';
  }

  @override
  String get library_invertSelection => '反選';

  @override
  String get library_more => '更多';

  @override
  String get viewer_fit => '適應';

  @override
  String get viewer_showInfo => '顯示資訊欄（I）';

  @override
  String get viewer_hideInfo => '隱藏資訊欄（I）';

  @override
  String get viewer_originalSize => '原始大小（1）';

  @override
  String get viewer_fullscreen => '全螢幕（F11）';

  @override
  String get shortcut_action_toggle_info_panel => '顯示 / 隱藏資訊欄';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_openBlockLibrary => '開啟塊庫';

  @override
  String get styleExplore_drawCountLabel => '本次抽取';

  @override
  String get styleExplore_drawCountSuffix => '張 · 逐張生成';

  @override
  String get styleExplore_appliedToEditor => '已套用到編輯區';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '抽 $count 張候選';
  }

  @override
  String get stats_title => '統計';

  @override
  String get stats_subtitle => '本地圖庫 · 按檔案時間';

  @override
  String stats_rangeDays(Object count) {
    return '$count 天';
  }

  @override
  String get stats_rangeThisYear => '今年';

  @override
  String get stats_rangeAll => '全部';

  @override
  String get stats_naiOnly => '僅 NAI 圖片';

  @override
  String stats_updatedAt(Object time) {
    return '更新於 $time';
  }

  @override
  String get stats_updating => '更新中';

  @override
  String stats_counting(Object count) {
    return '正在統計 $count 張…';
  }

  @override
  String get stats_updateFailed => '更新失敗';

  @override
  String get stats_refresh => '重新整理';

  @override
  String stats_lastDays(Object count) {
    return '近 $count 天';
  }

  @override
  String stats_lastDaysShort(Object count) {
    return '近 $count 天';
  }

  @override
  String get stats_unitDays => '天';

  @override
  String stats_imagesCount(Object count) {
    return '$count 張';
  }

  @override
  String get stats_less => '少';

  @override
  String get stats_more => '多';

  @override
  String get stats_kpiImages => '圖片';

  @override
  String get stats_kpiNewImages => '新增圖片';

  @override
  String stats_kpiActiveDays(Object days, Object avg) {
    return '活躍 $days 天 · 日均 $avg';
  }

  @override
  String stats_kpiVsPrevious(Object count) {
    return '比前 $count 天';
  }

  @override
  String get stats_kpiVsLastYear => '比去年同期';

  @override
  String stats_kpiPreviousValue(Object value) {
    return '（$value）';
  }

  @override
  String get stats_kpiFavorites => '收藏';

  @override
  String stats_kpiFavoriteRate(Object rate) {
    return '收藏率 $rate';
  }

  @override
  String get stats_kpiAnlas90 => 'Anlas · 近 90 天';

  @override
  String get stats_kpiAnlasSpent => 'Anlas 消耗';

  @override
  String stats_kpiAnlasRecent(Object week, Object today) {
    return '近 7 天 $week · 今日 $today';
  }

  @override
  String stats_kpiAnlasDaily(Object avg, Object today) {
    return '日均 $avg · 今日 $today';
  }

  @override
  String get stats_kpiStreak => '連續創作';

  @override
  String stats_kpiLongest(Object days, Object unit) {
    return '最長 $days $unit';
  }

  @override
  String stats_kpiLongestRange(Object days, Object unit, Object range) {
    return '最長 $days $unit（$range）';
  }

  @override
  String get stats_kpiStorage => '佔用';

  @override
  String stats_kpiStorageDetail(Object avg, Object pct) {
    return '平均 $avg · $pct 有後設資料';
  }

  @override
  String get stats_calendarTitle => '創作日曆';

  @override
  String get stats_calendarHint => '每格一天，顏色越深圖越多';

  @override
  String get stats_calendarPastYear => '近一年';

  @override
  String stats_calendarYear(Object year) {
    return '$year 年';
  }

  @override
  String get stats_calendarImagesPastYear => '近一年圖片';

  @override
  String stats_calendarImagesInYear(Object year) {
    return '$year 年圖片';
  }

  @override
  String get stats_calendarActiveDays => '有創作的天數';

  @override
  String get stats_calendarBestDay => '最多的一天';

  @override
  String get stats_calendarLongestStreak => '最長連續';

  @override
  String get stats_calendarTipOpen => '點一下在本地畫廊開啟這一天';

  @override
  String get stats_productionTitle => '產量與模型';

  @override
  String stats_productionHintAll(Object unit) {
    return '按$unit，顏色是模型';
  }

  @override
  String stats_productionHintRange(Object range, Object unit) {
    return '$range，按$unit，顏色是模型';
  }

  @override
  String get stats_unitDay => '天';

  @override
  String get stats_unitWeek => '周';

  @override
  String get stats_unitMonth => '月';

  @override
  String get stats_granularityDay => '日';

  @override
  String get stats_granularityWeek => '周';

  @override
  String get stats_granularityMonth => '月';

  @override
  String stats_monthWithYear(Object year, Object month) {
    return '$year.$month';
  }

  @override
  String get stats_productionModelsHint => '模型 · 點一下只看這個模型的圖';

  @override
  String stats_productionOtherModels(Object count) {
    return '其他 $count 個模型';
  }

  @override
  String stats_productionNoMetadata(Object count) {
    return '另有 $count 張沒有後設資料，圖上是淺灰色';
  }

  @override
  String get stats_familyOther => '其他模型';

  @override
  String get stats_familyNoMetadata => '無後設資料';

  @override
  String stats_productionTipTotal(Object period, Object count) {
    return '$period · $count 張';
  }

  @override
  String get stats_productionTipOpenDay => '點一下在本地畫廊開啟這一天';

  @override
  String get stats_productionTipOpenWeek => '點一下在本地畫廊開啟這一週';

  @override
  String get stats_productionTipOpenMonth => '點一下在本地畫廊開啟這個月';

  @override
  String get stats_punchTitle => '什麼時候畫';

  @override
  String get stats_punchHint => '星期 × 小時';

  @override
  String get stats_punchPeak => '最常在';

  @override
  String stats_punchPeakValue(Object weekday, Object from, Object to) {
    return '$weekday $from–$to 點';
  }

  @override
  String get stats_punchBusiest => '最忙';

  @override
  String get stats_punchLateNight => '深夜佔';

  @override
  String get stats_punchNote => '圓越大圖越多';

  @override
  String get stats_anlasTitle => 'Anlas 消耗';

  @override
  String get stats_anlasToday => '今天';

  @override
  String get stats_anlasDailyAvg => '日均';

  @override
  String stats_anlasActiveDays(Object count) {
    return '有消耗 $count 天';
  }

  @override
  String get stats_anlasPeak => '最多';

  @override
  String get stats_anlasNote => '按餘額下降記錄，含放大、Vibe 編碼等；只保留最近 90 天';

  @override
  String get stats_aspectTitle => '畫幅';

  @override
  String get stats_aspectHint => '按真實尺寸';

  @override
  String get stats_aspectOrientation => '方向';

  @override
  String get stats_orientationPortrait => '豎';

  @override
  String get stats_orientationLandscape => '橫';

  @override
  String get stats_orientationSquare => '方';

  @override
  String stats_aspectShapeCount(Object orientation, Object count) {
    return '$orientation · $count';
  }

  @override
  String stats_aspectOthers(Object count, Object pct) {
    return '其他 $count 種 · $pct';
  }

  @override
  String get stats_aspectClickHint => '點一個尺寸或方向，在本地畫廊只看這一類';

  @override
  String get stats_paramsTitle => '參數習慣';

  @override
  String get stats_paramsHint => '有後設資料的圖';

  @override
  String get stats_paramsCombo => '最常用的設定';

  @override
  String get stats_paramsSampler => '取樣器';

  @override
  String get stats_paramsSteps => '步數';

  @override
  String stats_paramsStepsValue(Object count) {
    return '$count 步';
  }

  @override
  String get stats_paramsNoise => '噪聲排程';

  @override
  String get stats_artistsTitle => '常用畫師';

  @override
  String stats_artistsHint(Object count, Object pct) {
    return '$count 張圖寫了畫師串（$pct）';
  }

  @override
  String get stats_artistsComputing => '正在統計畫師…';

  @override
  String get stats_artistsNone => '提示詞裡還沒有寫過 artist:';

  @override
  String get stats_artistsNote => '按“出現在幾張圖裡”排，一張圖裡寫多次只算一次';

  @override
  String stats_artistsTipSearch(Object query) {
    return '在本地畫廊搜 $query';
  }

  @override
  String get stats_artistsTipCopy => '右鍵：複製畫師名';

  @override
  String stats_artistsCopied(Object name) {
    return '已複製 $name';
  }

  @override
  String get stats_storageTitle => '儲存';

  @override
  String stats_storageFiles(Object count) {
    return '$count 個檔案';
  }

  @override
  String get stats_storageMonthly => '近 12 個月每月新增';

  @override
  String stats_storageNoMetadata(Object count) {
    return '$count 張沒有後設資料';
  }

  @override
  String get stats_storageViewInGallery => '在本地畫廊檢視';

  @override
  String stats_storageLarge(Object count, Object size) {
    return '$count 張大於 10 MB · $size';
  }

  @override
  String get stats_storageView => '檢視';

  @override
  String get stats_footer =>
      '每次進入統計頁都檢查圖庫有沒有變化，變了就在後臺重算 · 數字都可以點，點了跳到本地畫廊並帶上篩選';

  @override
  String get stats_emptyTitle => '本地圖庫裡還沒有圖片';

  @override
  String get stats_emptyBody =>
      '生成的圖會自動存進本地圖庫，或者把已有的圖片資料夾加進來。之後這裡會顯示你的創作節奏、模型和參數習慣。';

  @override
  String get stats_emptyGenerate => '去生圖';

  @override
  String get stats_emptyAddFolder => '新增圖庫資料夾';

  @override
  String get stats_errorTitle => '統計沒有算出來';

  @override
  String get stats_errorRetry => '重試';

  @override
  String get navShell_page_generation => '生圖';

  @override
  String get navShell_page_styleExplore => '畫風探索';

  @override
  String get navShell_page_localGallery => '本地畫廊';

  @override
  String get navShell_page_onlineGallery => '線上畫廊';

  @override
  String get navShell_page_promptBlocks => '提示詞塊';

  @override
  String get navShell_page_vibeLibrary => 'Vibe 庫';

  @override
  String get navShell_page_preciseRef => '精準參考庫';

  @override
  String get navShell_page_tagWiki => '標籤百科';

  @override
  String get navShell_page_statistics => '統計';

  @override
  String get navShell_page_settings => '設定';

  @override
  String get navShell_group_create => '創作';

  @override
  String get navShell_group_gallery => '圖庫';

  @override
  String get navShell_group_assets => '素材';

  @override
  String get navShell_group_tools => '工具';

  @override
  String get navShell_expand => '展開導航';

  @override
  String get navShell_collapse => '收起';

  @override
  String get navShell_pin => '釘住展開';

  @override
  String get navShell_genRunning => '生成中';

  @override
  String navShell_genRunningCount(Object current, Object total) {
    return '生成中 · 第 $current / $total 張';
  }

  @override
  String navShell_genPercent(Object percent) {
    return '$percent% · 流式預覽';
  }

  @override
  String get navShell_genBack => '點一下回到生圖頁';

  @override
  String navShell_genDone(Object count) {
    return '已完成 $count 張，點一下檢視';
  }

  @override
  String get navShell_genFailed => '生成失敗';

  @override
  String get navShell_tasksTitle => '後臺任務';

  @override
  String navShell_tasksRunning(Object count) {
    return '$count 個進行中';
  }

  @override
  String get navShell_tasksFooter => '全部結束 10 秒後這個圖示自動消失';

  @override
  String get navShell_task_localUpscale => '本地放大';

  @override
  String get navShell_task_cloudUpscale => '雲端放大';

  @override
  String get navShell_task_bulkDelete => '移到回收站';

  @override
  String get navShell_task_bulkExport => '批次匯出';

  @override
  String get navShell_task_bulkMetadata => '批次編輯後設資料';

  @override
  String get navShell_task_bulkAddToCollection => '加入收藏集';

  @override
  String get navShell_task_bulkRemoveFromCollection => '移出收藏集';

  @override
  String get navShell_task_bulkFavorite => '批次收藏';

  @override
  String navShell_taskImages(Object title, Object count) {
    return '$title $count 張';
  }

  @override
  String get navShell_taskJustDone => '剛剛完成';

  @override
  String get navShell_taskView => '檢視';

  @override
  String get navShell_taskCancel => '取消';

  @override
  String get navShell_taskCancelling => '正在取消';

  @override
  String get navShell_taskUndo => '復原';

  @override
  String get navShell_account => '帳號';

  @override
  String get navShell_accountTitle => '登入與帳號';

  @override
  String get navShell_accountCurrent => '當前';

  @override
  String get navShell_accountToken => 'API Token 登入';

  @override
  String get navShell_accountCredentials => '電子郵件密碼登入';

  @override
  String get navShell_accountNotSignedIn => '未登入';

  @override
  String get navShell_accountChoose => '選一個帳號繼續';

  @override
  String navShell_subExpires(Object date, Object days) {
    return '訂閱 $date 到期 · 還剩 $days 天';
  }

  @override
  String get navShell_subExpired => '訂閱已過期';

  @override
  String get navShell_anlas => 'Anlas 餘額';

  @override
  String get navShell_switchAccount => '切換帳號';

  @override
  String get navShell_addAccount => '新增帳號';

  @override
  String get navShell_manageAccounts => '管理帳號';

  @override
  String get navShell_logout => '登出';

  @override
  String get navShell_customize => '自訂導航欄';

  @override
  String get navShell_customizeMenu => '自訂導航欄…';

  @override
  String get navShell_customizeNote => '右鍵導航欄開啟。隱藏的頁面仍然可以用快速鍵開啟；生圖不能隱藏';

  @override
  String get navShell_ctrlNumbers => '按住 Ctrl 顯示頁面編號';

  @override
  String get navShell_reset => '恢復預設';

  @override
  String get navShell_done => '完成';

  @override
  String get navShell_ctrlHint => '按住不放：顯示頁面編號，按數字直接跳轉；鬆開就消失';

  @override
  String get online_title => '線上畫廊';

  @override
  String get online_collapseSidebar => '收起左欄';

  @override
  String get online_expandSidebar => '展開左欄';

  @override
  String get online_sectionBrowse => '瀏覽';

  @override
  String get online_modeSearch => '搜尋';

  @override
  String get online_modeMonthly => '月榜';

  @override
  String get online_modePopular => '熱門';

  @override
  String get online_modeMyFavorites => '我的收藏';

  @override
  String get online_modeFavorites => '收藏';

  @override
  String get online_noRanking => '沒有排行';

  @override
  String get online_noFavorites => '不支援收藏';

  @override
  String get online_readOnly => '只讀';

  @override
  String get online_signedOut => '未登入';

  @override
  String get online_recentTitle => '最近搜尋';

  @override
  String get online_recentClear => '清除';

  @override
  String get online_collections => '子集';

  @override
  String get online_newCollection => '新增子集';

  @override
  String get online_all => '全部';

  @override
  String get online_ungrouped => '未分組';

  @override
  String get online_favAuthors => '收藏的作者';

  @override
  String get online_blacklist => '黑名單';

  @override
  String online_blacklistCount(Object count) {
    return '遮蔽 $count 個標籤';
  }

  @override
  String get online_srcSubAiTag => 'NAI 作品社群 · 帶完整 Prompt';

  @override
  String online_srcSubSignedIn(Object name) {
    return '已登入 · $name';
  }

  @override
  String get online_srcSubSafebooru => '全年齡 · 不用登入';

  @override
  String get online_srcSubKeyOk => 'API Key 已配置';

  @override
  String get online_srcSubKeyInvalid => 'API Key 無效';

  @override
  String get online_srcSubKeyMissing => '未配置 API Key';

  @override
  String get online_switchSource => '換來源';

  @override
  String get online_capPromptSearch => '搜尋作品 + Prompt';

  @override
  String get online_capTagSearch => '標籤搜尋';

  @override
  String get online_capMonthly => '月榜';

  @override
  String get online_capRankings => '日 / 周 / 月榜';

  @override
  String get online_capLocalFav => '本地收藏';

  @override
  String get online_capSiteFav => '網站收藏';

  @override
  String get online_capReadOnlyFav => '收藏（只讀）';

  @override
  String get online_capMultiMedia => '多圖作品';

  @override
  String get online_capParams => '生成參數';

  @override
  String get online_capRatings => '評級';

  @override
  String get online_capSfwOnly => '只有全年齡';

  @override
  String get online_acctNone => '不用登入';

  @override
  String get online_acctSignedIn => '已登入';

  @override
  String get online_acctKeyOk => 'Key 已配置';

  @override
  String get online_acctKeyInvalid => 'Key 無效';

  @override
  String get online_acctKeyMissing => '未配置 Key';

  @override
  String get online_sourceMemory => '每個來源記住自己的搜尋詞和滾動位置';

  @override
  String get online_searchWorkHint => '作品、作者、標題、標籤或模型';

  @override
  String get online_searchPromptHint => 'Prompt 含有…（支援 ::artist: 原始語法）';

  @override
  String get online_searchTagHint => '加標籤，空格分隔，前面加 - 是排除';

  @override
  String get online_searchFavHint => '在收藏裡找：標題、作者、標籤';

  @override
  String get online_fuzzy => '模糊匹配';

  @override
  String get online_clearSearch => '清空搜尋';

  @override
  String get online_sizeSmall => '小卡片（不顯示標題）';

  @override
  String get online_sizeMedium => '中';

  @override
  String get online_sizeLarge => '大';

  @override
  String get online_multiSelect => '多選';

  @override
  String get online_doneMultiSelect => '完成多選';

  @override
  String get online_refresh => '重新整理';

  @override
  String get online_inspector => '檢查器';

  @override
  String get online_naiOnly => '僅 NAI 圖片';

  @override
  String get online_model => '模型';

  @override
  String get online_modelAll => '全部';

  @override
  String get online_timeAll => '全部時間';

  @override
  String online_timeYear(Object year) {
    return '$year 年';
  }

  @override
  String get online_timeOlder => '更早歸檔';

  @override
  String online_loaded(Object count, Object pages) {
    return '已載入 $count 張 · $pages 頁';
  }

  @override
  String online_rankLoaded(Object count) {
    return '第 1–$count 名 · 已載入 $count 張';
  }

  @override
  String get online_jumpToPage => '跳轉到頁';

  @override
  String get online_jumpGo => '跳轉';

  @override
  String get online_ratingLabel => '評級';

  @override
  String get online_ratingG => '全年齡';

  @override
  String get online_ratingS => '輕微';

  @override
  String get online_ratingQ => '敏感';

  @override
  String get online_ratingE => '露骨';

  @override
  String get online_dateRange => '日期範圍';

  @override
  String get online_clearDateRange => '不限日期';

  @override
  String get online_rankCurrent => '即時月榜';

  @override
  String get online_rankDay => '日榜';

  @override
  String get online_rankWeek => '周榜';

  @override
  String get online_rankMonth => '月榜';

  @override
  String get online_today => '今天';

  @override
  String get online_previous => '上一個';

  @override
  String get online_next => '下一個';

  @override
  String get online_sort => '排序';

  @override
  String get online_sortFavTime => '收藏時間';

  @override
  String get online_favAll => '全部收藏';

  @override
  String online_countImages(Object count) {
    return '$count 張';
  }

  @override
  String online_authorSaved(Object count, Object date) {
    return '收藏了 $count 張 · 收藏作者於 $date';
  }

  @override
  String get online_authorAllWorks => '在 AI TAG 看 TA 的全部作品';

  @override
  String get online_unfavAuthor => '取消收藏作者';

  @override
  String get online_favAuthor => '收藏作者';

  @override
  String get online_dragHint => '把卡片拖到左邊的子集就是移動；右鍵 → 移到子集 / 取消收藏';

  @override
  String get online_readOnlyNote => '只讀：Gelbooru 收藏只能看，要在網站上改';

  @override
  String get online_returnPrev => '返回之前的結果';

  @override
  String get online_send => '傳送到生圖';

  @override
  String get online_sendTags => '傳送標籤到生圖';

  @override
  String get online_sendModes => '選擇傳送方式';

  @override
  String get online_favorite => '收藏';

  @override
  String get online_favorited => '已收藏';

  @override
  String get online_copyPrompt => '複製 Prompt';

  @override
  String get online_copyTags => '複製標籤';

  @override
  String get online_download => '下載';

  @override
  String online_downloadAll(Object count) {
    return '下載全部 $count 張';
  }

  @override
  String get online_downloadCurrent => '只下載這一張';

  @override
  String get online_more => '更多';

  @override
  String get online_openInBrowser => '在網站開啟';

  @override
  String get online_onlyAuthor => '只看 TA';

  @override
  String get online_moveTo => '移到子集';

  @override
  String get online_unfavorite => '取消收藏';

  @override
  String get online_rename => '重新命名';

  @override
  String get online_deleteCollection => '刪除子集';

  @override
  String get online_inspWork => '作品';

  @override
  String get online_inspPost => '帖子';

  @override
  String online_youSaved(Object count) {
    return '你收藏了 TA $count 張';
  }

  @override
  String get online_params => '生成參數';

  @override
  String get online_pModel => '模型';

  @override
  String get online_pSize => '尺寸';

  @override
  String get online_pSeed => '種子';

  @override
  String get online_pSampler => '取樣器';

  @override
  String get online_pStepsCfg => '步數 · 引導';

  @override
  String get online_prompt => '提示詞';

  @override
  String get online_negative => '負面';

  @override
  String get online_tags => '標籤';

  @override
  String get online_tagsHint => '點一下加入搜尋';

  @override
  String get online_tagArtist => '畫師';

  @override
  String get online_tagCopyright => '作品';

  @override
  String get online_tagCharacter => '角色';

  @override
  String get online_tagGeneral => '一般';

  @override
  String get online_tagMeta => '元標籤';

  @override
  String get online_copy => '複製';

  @override
  String get online_noSelection => '單擊一張卡片，在這裡看 Prompt 和生成參數';

  @override
  String online_detailError(Object error) {
    return '詳情沒加載出來：$error';
  }

  @override
  String get online_retry => '重試';

  @override
  String get online_noPrompt => '這張圖沒有 Prompt';

  @override
  String online_selCount(Object count) {
    return '已選 $count 張';
  }

  @override
  String get online_selAll => '全選';

  @override
  String get online_selInvert => '反選';

  @override
  String get online_favoriteTo => '收藏到…';

  @override
  String get online_favoriteToTitle => '收藏到';

  @override
  String get online_favoriteToSite => '收藏到網站';

  @override
  String online_downloadN(Object count) {
    return '下載 · $count 張圖';
  }

  @override
  String get online_newCollectionAndFav => '新增子集並收藏';

  @override
  String get online_collectionNameHint => '子集名稱，回車確認';

  @override
  String get online_exitMulti => '退出多選';

  @override
  String get online_sendRemember => '記住這次的選擇';

  @override
  String get online_sendReplace => '替換提示詞，清空角色框';

  @override
  String online_sendReplaceDesc(Object count) {
    return '正向 + 負面換成這張圖的；生圖頁現有的 $count 個角色框清空。和以前卡片上的傳送按鈕一樣';
  }

  @override
  String get online_sendReplaceDescNone =>
      '正向 + 負面換成這張圖的；生圖頁的角色框清空。和以前卡片上的傳送按鈕一樣';

  @override
  String get online_sendPromptOnly => '只替換提示詞，保留角色框';

  @override
  String get online_sendPromptOnlyDesc => '適合只想借畫師串和畫面描述';

  @override
  String get online_sendParams => '提示詞 + 生成參數';

  @override
  String get online_sendParamsDesc =>
      '再套用尺寸、種子、取樣器、步數、引導和圖裡的角色框，和本地圖庫“複用參數”同一條鏈';

  @override
  String get online_sendParamsUnavailable => '這張圖沒有生成參數，只能傳送提示詞';

  @override
  String online_sendNote(Object count) {
    return '生圖頁現在的正向有 $count 字，會被替換';
  }

  @override
  String get online_sendNoteEmpty => '生圖頁現在的正向是空的';

  @override
  String get online_cancel => '取消';

  @override
  String get online_sendGo => '傳送並去生圖頁';

  @override
  String get online_blacklistDesc => '命中的作品直接不顯示';

  @override
  String get online_blacklistAddHint => '加標籤，回車確認';

  @override
  String online_blacklistSync(Object count) {
    return '同步 Danbooru 帳號黑名單 · $count 個';
  }

  @override
  String get online_blacklistScope => '對四個來源都生效；AI TAG 按作品標籤匹配';

  @override
  String get online_blacklistEmpty => '還沒有遮蔽的標籤';

  @override
  String get online_removeTag => '刪除';

  @override
  String online_appendError(Object page, Object reason) {
    return '第 $page 頁沒加載出來：$reason';
  }

  @override
  String get online_retryPage => '重試這一頁';

  @override
  String online_end(Object count) {
    return '已經到底了 · 共 $count 張';
  }

  @override
  String online_endBlocked(Object count, Object blocked) {
    return '已經到底了 · 共 $count 張 · 黑名單擋掉 $blocked 張';
  }

  @override
  String online_emptyTitle(Object query) {
    return '沒有找到 “$query” 的作品';
  }

  @override
  String get online_emptyTitleNoQuery => '沒有找到作品';

  @override
  String get online_emptyHint => '試試放寬下面這些條件';

  @override
  String get online_sugNaiOff => '去掉“僅 NAI 圖片”';

  @override
  String get online_sugClearPrompt => '清空 Prompt 條件';

  @override
  String get online_sugAllTime => '換成全部時間';

  @override
  String get online_sugAllModels => '模型改成全部';

  @override
  String get online_sugAllRatings => '評級全選';

  @override
  String get online_sugNoDate => '去掉日期範圍';

  @override
  String get online_favEmpty => '這裡還沒有收藏';

  @override
  String get online_favEmptyHint => '在卡片上點 ♡ 就能收藏';

  @override
  String online_loadError(Object error) {
    return '沒加載出來：$error';
  }

  @override
  String get online_loginDbTitle => '登入 Danbooru 後才能看你的收藏';

  @override
  String get online_loginDbDesc =>
      '用使用者名稱 + API Key 登入，收藏會和網站同步；\n在卡片上點 ♡ 也是直接收藏到網站';

  @override
  String get online_loginDb => '登入 Danbooru';

  @override
  String get online_loginGbTitle => '配置 Gelbooru API Key 後才能看收藏';

  @override
  String get online_loginGbDesc => 'Gelbooru 收藏只能看，不能在這裡改';

  @override
  String get online_loginGb => '配置 API Key';

  @override
  String get online_apiKeyHelp => '去哪裡拿 API Key';

  @override
  String get online_loginOther => '不想登入？AI TAG 的收藏存在本機，不要帳號；Gelbooru 收藏只能看不能改';

  @override
  String online_viewerPosition(
    Object image,
    Object images,
    Object work,
    Object works,
  ) {
    return '圖 $image / $images · 作品 $work / $works';
  }

  @override
  String online_viewerWorkPosition(Object work, Object works) {
    return '作品 $work / $works';
  }

  @override
  String get online_close => '關閉';

  @override
  String get online_keyImage => '這一組裡切圖';

  @override
  String get online_keyWork => '上一個 / 下一個作品';

  @override
  String get online_keyInfo => '收起資訊欄';

  @override
  String get refs_vibeTitle => 'Vibe 庫';

  @override
  String get refs_preciseTitle => '精準參考庫';

  @override
  String get refs_collapseSidebar => '收起左欄';

  @override
  String get refs_expandSidebar => '展開左欄';

  @override
  String get refs_viewAll => '全部';

  @override
  String get refs_viewFavorites => '收藏';

  @override
  String get refs_viewRecent => '最近使用';

  @override
  String get refs_viewInGeneration => '在生圖頁';

  @override
  String get refs_categories => '分類';

  @override
  String get refs_newCategory => '新增分類';

  @override
  String get refs_newSubcategory => '新增子分類';

  @override
  String get refs_deleteCategory => '刪除分類';

  @override
  String get refs_categoryNameHint => '分類名稱';

  @override
  String get refs_noCategories => '還沒有分類。匯入時可以順手建一個';

  @override
  String get refs_uncategorized => '未分類';

  @override
  String get refs_sources => '來源';

  @override
  String get refs_srcPng => 'PNG（內含 Vibe）';

  @override
  String get refs_srcVibeFile => 'Vibe 檔案';

  @override
  String get refs_srcBundle => '組合包';

  @override
  String get refs_srcRaw => '待編碼的圖片';

  @override
  String get refs_srcImage => '圖片';

  @override
  String get refs_open => '開啟';

  @override
  String get refs_types => '參考類型';

  @override
  String refs_importTypeNoteAll(Object type) {
    return '匯入的圖片預設按 $type 存。選中左邊某個類型再匯入，就按那個類型存。';
  }

  @override
  String refs_importTypeNoteSelected(Object type) {
    return '匯入的圖片預設按 $type 存。跟著左邊選中的類型。';
  }

  @override
  String get refs_preciseOnlyV45 => '只在 V4.5 可用';

  @override
  String refs_preciseCostNote(Object cost) {
    return '每張 $cost Anlas；和 Vibe 不能同時生效';
  }

  @override
  String get refs_searchVibe => '搜尋名稱、標籤';

  @override
  String get refs_searchPrecise => '搜尋名稱';

  @override
  String get refs_sortLastUsed => '最近使用';

  @override
  String get refs_sortCreated => '加入時間';

  @override
  String get refs_sortUsed => '使用次數';

  @override
  String get refs_sortName => '名稱';

  @override
  String get refs_sortAsc => '升序';

  @override
  String get refs_sortDesc => '降序';

  @override
  String get refs_sizeSmall => '小卡片';

  @override
  String get refs_sizeMedium => '中';

  @override
  String get refs_sizeLarge => '大';

  @override
  String get refs_currentModel => '當前模型';

  @override
  String get refs_usable => '可用';

  @override
  String get refs_unusable => '不能用';

  @override
  String get refs_multi => '多選';

  @override
  String get refs_multiDone => '完成多選';

  @override
  String get refs_import => '匯入';

  @override
  String get refs_importFiles => '選擇檔案…';

  @override
  String get refs_importImages => '選擇圖片…';

  @override
  String get refs_importClipboard => '從剪貼簿貼上';

  @override
  String get refs_more => '更多';

  @override
  String get refs_exportAll => '匯出全部…';

  @override
  String get refs_openLibraryFolder => '開啟庫資料夾';

  @override
  String get refs_rescan => '重新掃描資料夾';

  @override
  String get refs_reload => '重新載入';

  @override
  String get refs_hideInspector => '收起檢查器';

  @override
  String get refs_showInspector => '展開檢查器';

  @override
  String refs_bannerVibeLead(Object model) {
    return '$model 不支援 Vibe 遷移。';
  }

  @override
  String get refs_bannerVibeBody => '庫裡的 Vibe 照常整理、匯出；切到 V4.5 或 V4 才能用於生成';

  @override
  String refs_bannerPreciseLead(Object model) {
    return '$model 不支援精準參考。';
  }

  @override
  String get refs_bannerPreciseBody => '庫裡的參考圖照常整理；切到 V4.5 才能用於生成';

  @override
  String refs_switchTo(Object model) {
    return '切到 $model';
  }

  @override
  String get refs_quickAll => '全部';

  @override
  String get refs_quickFavorites => '收藏';

  @override
  String get refs_quickHasRaw => '有原圖';

  @override
  String get refs_quickNeedsEncoding => '需要編碼';

  @override
  String get refs_quickBundles => '組合包';

  @override
  String get refs_quickUnused => '沒用過';

  @override
  String refs_countVibe(Object count, Object inGen) {
    return '$count 個 · $inGen 個在生圖頁';
  }

  @override
  String refs_countPrecise(Object count, Object inGen) {
    return '$count 張 · $inGen 張在生圖頁';
  }

  @override
  String get refs_noResults => '沒有符合條件的條目';

  @override
  String refs_noResultsFor(Object query) {
    return '沒有找到“$query”';
  }

  @override
  String get refs_clearFilters => '清除篩選';

  @override
  String get refs_addShort => '加入生圖';

  @override
  String get refs_sendPrecise => '傳送到精準參考';

  @override
  String get refs_openBundle => '開啟組合包';

  @override
  String get refs_detail => '詳情';

  @override
  String get refs_addToGeneration => '加入生圖頁';

  @override
  String get refs_replaceVibes => '替換生圖頁的 Vibe';

  @override
  String get refs_replacePrecise => '替換現有精準參考';

  @override
  String get refs_sendImg2Img => '傳送到圖生圖';

  @override
  String get refs_saveAsVibe => '存進 Vibe 庫';

  @override
  String get refs_favorite => '收藏';

  @override
  String get refs_unfavorite => '取消收藏';

  @override
  String get refs_replacePreview => '換預覽圖…';

  @override
  String get refs_exportEllipsis => '匯出…';

  @override
  String get refs_showInFolder => '在資料夾中顯示';

  @override
  String get refs_copyImage => '複製圖片';

  @override
  String get refs_delete => '刪除';

  @override
  String refs_selected(Object count) {
    return '已選 $count';
  }

  @override
  String get refs_moveTo => '移到';

  @override
  String get refs_export => '匯出';

  @override
  String get refs_emptyVibeTitle => '把圖片或 Vibe 檔案拖到這裡';

  @override
  String get refs_emptyPreciseTitle => '把參考圖拖到這裡';

  @override
  String get refs_emptyVibeDesc =>
      '支援 PNG（內含 Vibe）、.naiv4vibe、.naiv4vibebundle 和普通圖片。\n普通圖片先存原圖，第一次用在生圖時才編碼';

  @override
  String get refs_emptyPreciseDesc =>
      '角色設定圖、風格樣張都行，一次可以拖很多張。\n存進來時記住類型、強度和保真度，傳送時直接套用';

  @override
  String get refs_pickFiles => '選擇檔案';

  @override
  String get refs_pasteClipboard => '從剪貼簿貼上';

  @override
  String get refs_emptyFromResultVibe => '生圖結果右鍵 → 存到 Vibe 庫';

  @override
  String get refs_emptyFromResultPrecise => '生圖結果右鍵 → 存到精準參考庫';

  @override
  String get refs_emptyFromGallery => '本地圖庫也可以';

  @override
  String get refs_emptyHelpTitle => 'Vibe 和精準參考有什麼區別？';

  @override
  String refs_emptyHelpBody(Object cost) {
    return 'Vibe：借整體氛圍和畫風，可以疊很多張（V4 / V4.5，V5 沒有）。精準參考：照著一張圖的人物或畫風來畫，更準，每張 $cost Anlas（只在 V4.5）。兩者不能同時生效。';
  }

  @override
  String refs_dropTitle(Object count) {
    return '鬆開匯入 $count 個檔案';
  }

  @override
  String get refs_dropVibeDesc => '會先開啟匯入視窗確認，不會直接扣 Anlas';

  @override
  String get refs_dropPreciseDesc => '按左欄選中的類型存進精準參考庫';

  @override
  String refs_dropVibePngs(Object count) {
    return '$count 個 PNG 含 Vibe';
  }

  @override
  String refs_dropVibeFiles(Object count) {
    return '$count 個 Vibe 檔案';
  }

  @override
  String refs_dropBundles(Object count) {
    return '$count 個組合包';
  }

  @override
  String refs_dropImages(Object count) {
    return '$count 張普通圖片';
  }

  @override
  String get refs_inGeneration => '在生圖頁';

  @override
  String get refs_tag => '標籤';

  @override
  String get refs_strengthShort => '強度';

  @override
  String get refs_infoShort => '資訊';

  @override
  String get refs_fidelityShort => '保真';

  @override
  String refs_encModelOff(Object model) {
    return '$model 不可用';
  }

  @override
  String refs_encModelOffDesc(Object model) {
    return '$model 不支援 Vibe 遷移，切到 V4.5 / V4 才能用';
  }

  @override
  String refs_encReady(Object model) {
    return '已編碼 · $model';
  }

  @override
  String refs_encReadyShort(Object model) {
    return '$model 已編碼';
  }

  @override
  String get refs_encReadyDesc => '當前模型直接能用，不再收編碼費';

  @override
  String get refs_encOnUse => '用時編碼';

  @override
  String refs_encOnUseDesc(Object cost) {
    return '還沒編碼。第一次用在生圖時編碼，$cost Anlas';
  }

  @override
  String get refs_encRe => '需重新編碼';

  @override
  String refs_encReDesc(Object from, Object model, Object cost) {
    return '編碼是給 $from 的，當前是 $model。用時按原圖重新編碼，$cost Anlas';
  }

  @override
  String refs_encUnusable(Object model) {
    return '不能用於 $model';
  }

  @override
  String refs_encUnusableDesc(Object from, Object model) {
    return '只有 $from 的編碼，沒有原圖，沒法給 $model 重新編碼';
  }

  @override
  String get refs_trayVibe => '生圖頁的 Vibe';

  @override
  String get refs_trayPrecise => '生圖頁的精準參考';

  @override
  String refs_trayVibeCost(Object free, Object extra) {
    return '超過 $free 個每個多 $extra Anlas';
  }

  @override
  String refs_trayPreciseCost(Object cost, Object total) {
    return '每張 $cost Anlas · 本次 +$total';
  }

  @override
  String get refs_trayHint => '拖卡片到這裡加入；Shift 拖入 = 替換全部。\n傳送後不跳頁，可以連續挑';

  @override
  String get refs_trayDropHere => '把卡片拖到這裡加入生圖頁';

  @override
  String get refs_clear => '清空';

  @override
  String get refs_goGeneration => '去生圖頁';

  @override
  String refs_conflict(Object count) {
    return '生圖頁還有 **$count 個 Vibe**。有精準參考時 Vibe 不會發送（官方不相容）';
  }

  @override
  String refs_conflictPaused(Object count) {
    return '生圖頁的 **$count 個 Vibe** 已暫停，傳送時只帶精準參考';
  }

  @override
  String get refs_pauseVibes => '暫停 Vibe';

  @override
  String get refs_resumeVibes => '恢復 Vibe';

  @override
  String get refs_inspector => '檢查器';

  @override
  String refs_selectedN(Object count) {
    return '已選 $count 個';
  }

  @override
  String get refs_noSelectionVibe => '點一張卡片看它的參數和編碼狀態';

  @override
  String get refs_noSelectionPrecise => '點一張參考圖看它的類型和參數';

  @override
  String get refs_rename => '改名';

  @override
  String get refs_replace => '替換';

  @override
  String get refs_replaceVibesTip => '替換生圖頁現有的全部 Vibe';

  @override
  String get refs_strength => '強度';

  @override
  String get refs_strengthDesc => '越高越像這張圖的感覺';

  @override
  String get refs_infoExtracted => '資訊提取';

  @override
  String refs_infoDesc(Object cost) {
    return '越高帶進來的細節越多。改它要按原圖重新編碼，$cost Anlas';
  }

  @override
  String get refs_infoLocked => '這條只有編碼資料、沒有原圖，資訊提取改不了';

  @override
  String get refs_changedNote => '改動只用於這次傳送';

  @override
  String get refs_saveDefault => '存為預設';

  @override
  String get refs_revert => '還原';

  @override
  String get refs_encOnUseBody => '還沒編碼。第一次用在生圖時編碼。';

  @override
  String refs_encReBody(String from, String model) {
    return '編碼是給 $from 的，當前是 $model。用時按原圖重新編碼。';
  }

  @override
  String refs_encodeAction(String model) {
    return '為 $model 編碼';
  }

  @override
  String refs_encodingPrice(int cost) {
    return '$cost Anlas';
  }

  @override
  String refs_encodeNow(Object model, Object cost) {
    return '現在為 $model 編碼 · $cost Anlas';
  }

  @override
  String refs_bundleNote(Object count) {
    return '組合包裡的 $count 個 Vibe 各有自己的強度和資訊提取，開啟組合包可以單獨調。';
  }

  @override
  String refs_bundleOf(Object count) {
    return '組合包 · $count 個';
  }

  @override
  String get refs_organize => '整理';

  @override
  String get refs_category => '分類';

  @override
  String get refs_tags => '標籤';

  @override
  String get refs_used => '用過';

  @override
  String get refs_neverUsed => '還沒用過';

  @override
  String refs_usedTimes(Object count, Object last) {
    return '$count 次 · 上次 $last';
  }

  @override
  String get refs_added => '加入';

  @override
  String get refs_file => '檔案';

  @override
  String get refs_original => '原圖';

  @override
  String refs_plusAnlas(Object cost) {
    return '+$cost Anlas';
  }

  @override
  String get refs_alsoSaveVibe => '也存進 Vibe 庫';

  @override
  String get refs_referenceWhat => '參考什麼';

  @override
  String get refs_typeCharacter => '角色';

  @override
  String get refs_typeStyle => '風格';

  @override
  String get refs_typeBoth => '角色+風格';

  @override
  String get refs_typeCharacterDesc => '保留人物長相、髮型和服裝，畫風跟提示詞走';

  @override
  String get refs_typeStyleDesc => '只借畫風、配色和筆觸，不管畫的是誰';

  @override
  String get refs_typeBothDesc => '人物和畫風都參考';

  @override
  String get refs_preciseStrength => '參考強度';

  @override
  String get refs_preciseStrengthDesc => '越高越像參考圖';

  @override
  String get refs_fidelity => '保真度';

  @override
  String get refs_fidelityDesc => '越高越貼原圖細節，越低越自由';

  @override
  String get refs_preciseDefaultsNote => '這裡改的是預設值，傳送時直接帶上；數字框可以填超過 0–1 的值';

  @override
  String get refs_showInFolderShort => '所在資料夾';

  @override
  String get refs_pickHint => '勾選卡片後在這裡批次設定';

  @override
  String get refs_multiAddTitle => '一起加入生圖頁';

  @override
  String get refs_multiSendTitle => '一起傳送到精準參考';

  @override
  String refs_multiFree(Object free) {
    return '不超過 $free 個，不額外收費。';
  }

  @override
  String refs_multiExtra(Object free, Object extra, Object total) {
    return '超過 $free 個，每多一個 +$extra Anlas：這次每張圖多 $total Anlas。';
  }

  @override
  String refs_multiOverMax(Object max) {
    return '超過 $max 個上限，多出的不會加入。';
  }

  @override
  String refs_multiEncodes(Object count, Object names, Object cost) {
    return '其中 $count 個需要編碼（$names，每個 $cost Anlas，只收一次）。';
  }

  @override
  String refs_multiAlready(Object count) {
    return '$count 個已經在生圖頁，不會重複加入。';
  }

  @override
  String refs_multiPreciseCost(Object cost, Object total) {
    return '每張 $cost Anlas，傳送後每張圖共 $total Anlas。';
  }

  @override
  String get refs_unify => '統一設定';

  @override
  String get refs_mixed => '混合';

  @override
  String refs_unifyVibeNote(Object count) {
    return '拖動後 $count 個一起改，寫回各自的預設值；資訊提取不統一改（要重新編碼）';
  }

  @override
  String refs_unifyPreciseNote(Object count) {
    return '點一下把 $count 張都改成這個類型';
  }

  @override
  String get refs_moveToCategory => '移到分類';

  @override
  String get refs_addTag => '加標籤';

  @override
  String get refs_packBundle => '打包成組合包';

  @override
  String get refs_close => '關閉';

  @override
  String get refs_cancel => '取消';

  @override
  String get refs_remove => '移除';

  @override
  String get refs_prev => '上一個';

  @override
  String get refs_next => '下一個';

  @override
  String get refs_switch => '切換';

  @override
  String get refs_dropReplacePreview => '把新圖拖到這裡 = 換掉預覽圖（不影響編碼）';

  @override
  String refs_bundleOfVibes(Object count) {
    return '組合包 · $count 個 Vibe';
  }

  @override
  String refs_bundleAll(Object count) {
    return '全部 $count 個';
  }

  @override
  String refs_bundleOnlyChecked(Object count) {
    return '只用勾選的 $count 個';
  }

  @override
  String get refs_bundleScopeNote => '傳送時按包裡每個 Vibe 自己的強度和資訊提取';

  @override
  String get refs_splitBundle => '拆成單獨的 Vibe';

  @override
  String get refs_bundleNoteLong => '改了某一個的參數後，可以“儲存到組合包”；不儲存隻影響這次傳送。';

  @override
  String refs_bundleAllEncoded(Object count, Object model) {
    return '包裡 $count 個都已為 $model 編碼';
  }

  @override
  String get refs_saveToBundle => '儲存到組合包';

  @override
  String get refs_cover => '封面';

  @override
  String get refs_setCover => '設為封面';

  @override
  String refs_exportTitle(Object count) {
    return '匯出 $count 個 Vibe';
  }

  @override
  String get refs_exportListNote => '從庫裡多選後點“匯出”進來；也能在這裡移掉';

  @override
  String get refs_exportAs => '匯出成';

  @override
  String get refs_fmtVibeFile => '單個 Vibe 檔案';

  @override
  String get refs_fmtVibeFileDesc => '.naiv4vibe，每個一份。官網和其他客戶端都能匯入';

  @override
  String get refs_fmtBundle => '打包成組合包';

  @override
  String refs_fmtBundleDesc(Object count) {
    return '.naiv4vibebundle，$count 個合成一個檔案';
  }

  @override
  String get refs_fmtPng => '嵌入到 PNG';

  @override
  String get refs_fmtPngDesc => '圖片自帶 Vibe，發給別人拖進來就能用。一次只能匯出一個';

  @override
  String get refs_fmtEncoded => '編碼文本';

  @override
  String get refs_fmtEncodedDesc => 'JSON / Base64，給指令碼和進階用法';

  @override
  String get refs_options => '選項';

  @override
  String get refs_optThumbs => '帶縮圖';

  @override
  String get refs_optThumbsDesc => '檔案稍大，匯入時能直接看到圖';

  @override
  String get refs_optZip => '壓縮成 ZIP';

  @override
  String refs_optZipDesc(Object count) {
    return '$count 個檔案放進一個壓縮檔';
  }

  @override
  String get refs_saveTo => '儲存到';

  @override
  String get refs_choose => '選擇';

  @override
  String refs_exportSummary(Object count, Object ext) {
    return '將生成 $count 個 $ext 檔案';
  }

  @override
  String refs_exportSummaryZip(Object count, Object ext) {
    return '將生成 1 個 ZIP（內含 $count 個 $ext 檔案）';
  }

  @override
  String refs_deleteOne(Object name) {
    return '刪除“$name”？';
  }

  @override
  String refs_deleteMany(Object count) {
    return '刪除 $count 個條目？';
  }

  @override
  String get refs_deleteVibeDesc => '從 Vibe 庫移除。生圖頁已經在用的不受影響。';

  @override
  String get refs_deletePreciseDesc => '從精準參考庫移除。生圖頁已經在用的不受影響。';

  @override
  String refs_importTitle(Object count) {
    return '匯入 $count 個檔案';
  }

  @override
  String get refs_importSubtitle => '拖進來的、選的、貼上的都走這一個視窗';

  @override
  String get refs_importMore => '再加檔案';

  @override
  String get refs_importPutIn => '全部放進';

  @override
  String get refs_importAddTags => '加標籤';

  @override
  String get refs_importTagsHint => '輸入後回車';

  @override
  String get refs_importPlainImages => '普通圖片';

  @override
  String get refs_importEncodeLater => '用到時再編碼';

  @override
  String refs_importEncodeNow(Object cost) {
    return '現在編碼 · $cost Anlas/張';
  }

  @override
  String get refs_importName => '名稱';

  @override
  String get refs_importResult => '識別結果';

  @override
  String refs_recPng(Object model) {
    return 'PNG 內含 Vibe · $model 編碼';
  }

  @override
  String refs_recVibeFile(Object model) {
    return 'Vibe 檔案 · $model 編碼';
  }

  @override
  String refs_recBundle(Object count) {
    return '組合包 · $count 個 Vibe';
  }

  @override
  String get refs_recImage => '普通圖片 · 還沒編碼';

  @override
  String get refs_recImageDup => '普通圖片 · 名稱已存在';

  @override
  String get refs_recFree => '直接匯入，免費';

  @override
  String refs_recReencode(Object model) {
    return '用在 $model 時要重新編碼（檔案裡沒有原圖就不行）';
  }

  @override
  String refs_recBundleNote(Object count) {
    return '整個匯入 = 庫裡一張卡；拆開 = $count 張卡';
  }

  @override
  String get refs_recEncodeLater => '先存原圖，第一次用在生圖時為當時的模型編碼';

  @override
  String refs_recEncodeNow(Object cost) {
    return '匯入時就編碼，每張 $cost Anlas';
  }

  @override
  String get refs_bundleWhole => '整個匯入';

  @override
  String refs_bundleSplit(Object count) {
    return '拆成 $count 個';
  }

  @override
  String get refs_bundlePick => '挑幾個';

  @override
  String get refs_dupExists => '庫裡已有同名條目';

  @override
  String get refs_dupKeepBoth => '兩個都留';

  @override
  String get refs_dupOverwrite => '覆蓋';

  @override
  String get refs_dupSkip => '跳過';

  @override
  String refs_importSummary(Object files, Object cards) {
    return '$files 個檔案 → 庫裡多 $cards 張卡';
  }

  @override
  String refs_importNow(Object cost) {
    return ' · 現在扣 $cost Anlas';
  }

  @override
  String refs_importLater(Object count, Object cost) {
    return ' · $count 張普通圖片第一次用在生圖時各編碼一次（每張 $cost Anlas）';
  }

  @override
  String get refs_pickerVibeTitle => '從 Vibe 庫新增';

  @override
  String get refs_pickerPreciseTitle => '從精準參考庫新增';

  @override
  String get refs_openVibeLibrary => '開啟 Vibe 庫';

  @override
  String get refs_openPreciseLibrary => '開啟精準參考庫';

  @override
  String get refs_recentUsed => '最近用過';

  @override
  String get refs_inUse => '已在用';

  @override
  String refs_pickedN(Object count) {
    return '已選 $count';
  }

  @override
  String refs_pickerAfterVibe(Object count, Object max) {
    return ' · 加入後 $count/$max';
  }

  @override
  String refs_pickerAfterPrecise(Object count) {
    return ' · 加入後 $count 張';
  }

  @override
  String refs_pickerEncode(Object name, Object model, Object cost) {
    return '“$name”要為 $model 編碼 · $cost Anlas';
  }

  @override
  String refs_pickerEncodeMore(Object count) {
    return '另有 $count 個也要編碼';
  }

  @override
  String refs_pickerExtra(Object free, Object extra) {
    return '超過 $free 個多 $extra Anlas';
  }

  @override
  String refs_pickerPreciseCost(Object cost, Object total) {
    return '每張 $cost Anlas · 共 $total Anlas';
  }

  @override
  String get refs_replaceExisting => '替換現有';

  @override
  String refs_appendN(Object count) {
    return '追加 $count 個';
  }

  @override
  String get refs_timeNever => '沒用過';

  @override
  String get refs_timeJustNow => '剛剛';

  @override
  String refs_timeMinutes(Object count) {
    return '$count 分鐘前';
  }

  @override
  String refs_timeHours(Object count) {
    return '$count 小時前';
  }

  @override
  String get refs_timeYesterday => '昨天';

  @override
  String refs_timeDays(Object count) {
    return '$count 天前';
  }

  @override
  String refs_timeMonthDay(Object month, Object day) {
    return '$month 月 $day 日';
  }

  @override
  String get blocks_title => '塊庫';

  @override
  String get blocks_translationMark => '譯';

  @override
  String get blocks_add => '新增';

  @override
  String get blocks_cancel => '取消';

  @override
  String get blocks_close => '關閉';

  @override
  String get blocks_delete => '刪除';

  @override
  String get blocks_done => '完成';

  @override
  String get blocks_save => '儲存';

  @override
  String get blocks_saveEnter => '儲存 ⏎';

  @override
  String get blocks_more => '更多';

  @override
  String get blocks_back => '返回';

  @override
  String get blocks_rename => '重新命名';

  @override
  String get blocks_edit => '編輯';

  @override
  String get blocks_copy => '複製';

  @override
  String get blocks_export => '匯出';

  @override
  String get blocks_apply => '應用';

  @override
  String get blocks_off => '關';

  @override
  String get blocks_to => '到';

  @override
  String blocks_items(Object count) {
    return '$count 項';
  }

  @override
  String get blocks_itemUnit => '項';

  @override
  String blocks_usedTimes(Object count) {
    return '用過 $count 次';
  }

  @override
  String blocks_nBlocks(Object count) {
    return '$count 個';
  }

  @override
  String get blocks_untitled => '未命名';

  @override
  String get blocks_favorite => '收藏';

  @override
  String get blocks_unfavorite => '取消收藏';

  @override
  String get blocks_favorites => '收藏';

  @override
  String get blocks_recent => '最近使用';

  @override
  String get blocks_uncategorized => '未分類';

  @override
  String get blocks_positive => '正面';

  @override
  String get blocks_negative => '負面';

  @override
  String blocks_positiveN(Object count) {
    return '正面 $count';
  }

  @override
  String blocks_negativeN(Object count) {
    return '負面 $count';
  }

  @override
  String get blocks_content => '內容';

  @override
  String get blocks_name => '名稱';

  @override
  String get blocks_folder => '資料夾';

  @override
  String get blocks_folders => '資料夾';

  @override
  String get blocks_tags => '標籤';

  @override
  String get blocks_tag => '標籤';

  @override
  String get blocks_icon => '圖示';

  @override
  String get blocks_color => '顏色';

  @override
  String get blocks_look => '外觀';

  @override
  String get blocks_appearance => '外觀';

  @override
  String get blocks_thumb => '預覽圖';

  @override
  String get blocks_preview => '預覽';

  @override
  String get blocks_params => '附帶參數';

  @override
  String get blocks_classify => '歸類';

  @override
  String get blocks_lookClassic => '經典';

  @override
  String get blocks_lookStripes => '細條紋';

  @override
  String get blocks_lookDots => '圓點';

  @override
  String get blocks_lookSolid => '實心';

  @override
  String get blocks_lookGradient => '漸變';

  @override
  String get blocks_lookTranslation => '翻譯';

  @override
  String get blocks_hasParams => '附帶參數';

  @override
  String get blocks_hasNegative => '含負面';

  @override
  String get blocks_hintClick => '點選插入';

  @override
  String get blocks_hintDrag => '拖到位置';

  @override
  String get blocks_hintRightClick => '右鍵更多';

  @override
  String get blocks_searchHint => '搜尋塊…';

  @override
  String get blocks_filterAll => '全部';

  @override
  String blocks_allN(Object count) {
    return '全部 $count';
  }

  @override
  String get blocks_searchResults => '搜尋結果';

  @override
  String get blocks_noResults => '沒有找到匹配的塊';

  @override
  String get blocks_noFavorites => '還沒有收藏的塊。在塊上右鍵 → 收藏。';

  @override
  String get blocks_dockEmpty => '塊庫還是空的。把常用的一串提示詞存成塊，點一下就能插進來。';

  @override
  String get blocks_dockHint => '點選插到游標處 · 拖進提示詞放到指定位置';

  @override
  String get blocks_openLibrary => '在塊庫中開啟';

  @override
  String get blocks_newBlock => '新增塊';

  @override
  String get blocks_newBlockTip => '新增塊（Ctrl+N）';

  @override
  String get blocks_insertAtCursor => '插到游標處';

  @override
  String get blocks_addToPalette => '放進積木';

  @override
  String get blocks_showInLibrary => '在塊庫中檢視';

  @override
  String get blocks_missing => '塊已刪除';

  @override
  String get blocks_modeFixed => '固定';

  @override
  String get blocks_modeSequential => '順序';

  @override
  String get blocks_modeRandom => '隨機';

  @override
  String blocks_summaryRandom(Object range, Object pool) {
    return '隨機抽取 · 每次 $range 項 · 池裡 $pool 項';
  }

  @override
  String blocks_summarySequential(Object range) {
    return '順序 · 每次 $range 項 · 生成一張往後走一步';
  }

  @override
  String get blocks_drawnThisTime => '本次抽到';

  @override
  String get blocks_lock => '鎖定';

  @override
  String get blocks_unlock => '解鎖';

  @override
  String get blocks_lockTip => '凍結這次的結果，生成時不再重抽';

  @override
  String get blocks_unlockTip => '解鎖後生成時會重新抽取';

  @override
  String get blocks_reroll => '重抽';

  @override
  String get blocks_rerollLocked => '已鎖定，先解鎖才能重抽';

  @override
  String blocks_skipped(Object percent) {
    return '這次沒出場（出現機率 $percent）';
  }

  @override
  String blocks_sendPrefix(Object text) {
    return '傳送：$text';
  }

  @override
  String blocks_seqPosition(Object index, Object total) {
    return '第 $index / $total 項';
  }

  @override
  String get blocks_seqLocked => '已鎖定，不會自動前進';

  @override
  String get blocks_prevItem => '上一項';

  @override
  String get blocks_nextItem => '下一項';

  @override
  String blocks_prevValue(Object value) {
    return '上一項 $value';
  }

  @override
  String blocks_nextValue(Object value) {
    return '下一項 $value';
  }

  @override
  String get blocks_paramsTitle => '這個塊帶了生圖參數';

  @override
  String get blocks_drawMode => '抽取方式';

  @override
  String blocks_fixedExplain(Object count) {
    return '固定：每次都原樣放入全部 $count 項。切到順序或隨機後，在這裡設數量和權重。';
  }

  @override
  String get blocks_ruleCount => '數量';

  @override
  String get blocks_ruleWeight => '權重';

  @override
  String get blocks_ruleShow => '出現';

  @override
  String get blocks_ruleEach => '每次';

  @override
  String get blocks_ruleItemUnit => '項';

  @override
  String get blocks_ruleWrap => '走完從頭開始';

  @override
  String get blocks_adjust => '調整';

  @override
  String get blocks_appliesTo => '作用於';

  @override
  String get blocks_disable => '停用';

  @override
  String get blocks_enable => '啟用';

  @override
  String get blocks_editBlock => '改塊';

  @override
  String get blocks_removeInstanceTip => '從提示詞裡移除';

  @override
  String get blocks_removeInstance => '從提示詞裡移除';

  @override
  String get blocks_copySend => '複製傳送文本';

  @override
  String get blocks_evolutionOn => '設為遺傳目標';

  @override
  String get blocks_evolutionOff => '取消遺傳';

  @override
  String get blocks_evolutionModeHint => '啟用的順序或隨機塊可參與遺傳，固定模式不可用。';

  @override
  String get blocks_rulesTitle => '抽取規則';

  @override
  String get blocks_rulesHint => '點完成後生效';

  @override
  String get blocks_rulesDirty => '有改動 · 點完成後生效';

  @override
  String get blocks_modeFixedDesc => '每次原樣放入全部內容';

  @override
  String get blocks_modeSequentialDesc => '按順序輪流，生成一張走一步';

  @override
  String get blocks_modeRandomDesc => '每次從池裡隨機抽幾項';

  @override
  String get blocks_drawEach => '每次抽';

  @override
  String get blocks_takeEach => '每次取';

  @override
  String blocks_poolSize(Object count) {
    return '池裡共 $count 項';
  }

  @override
  String get blocks_outputOrder => '輸出順序';

  @override
  String get blocks_orderDrawn => '按抽中順序';

  @override
  String get blocks_orderOriginal => '按原順序';

  @override
  String get blocks_seqExplain => '生成一張往後走一步；鎖定後停在當前項。';

  @override
  String get blocks_randomWeight => '隨機權重';

  @override
  String get blocks_randomWeightHint => '給每項套上 0.8::…:: 這樣的權重';

  @override
  String get blocks_weightMin => '最小';

  @override
  String get blocks_weightAverage => '最常見';

  @override
  String get blocks_weightMax => '最大';

  @override
  String get blocks_distribution => '分佈';

  @override
  String get blocks_distFocused => '集中';

  @override
  String get blocks_distBalanced => '均衡';

  @override
  String get blocks_distSpread => '發散';

  @override
  String get blocks_distCustom => '自訂';

  @override
  String get blocks_advanced => '進階';

  @override
  String get blocks_leftDispersion => '左側離散';

  @override
  String get blocks_rightDispersion => '右側離散';

  @override
  String get blocks_softBalance => '軟平衡';

  @override
  String get blocks_softBalanceHint => '多項時把平均權重拉回最常見值';

  @override
  String get blocks_softBalanceStrength => '平衡強度';

  @override
  String get blocks_probability => '出現機率';

  @override
  String get blocks_probabilityHint => '低於 100% 時，有時整個塊不出場';

  @override
  String get blocks_previewHint => '按當前規則抽 4 次';

  @override
  String get blocks_resample => '再抽';

  @override
  String get blocks_sampleSkipped => '（這次沒出場）';

  @override
  String get blocks_resetDefault => '恢復預設';

  @override
  String get blocks_discard => '取消改動';

  @override
  String get blocks_allBlocks => '全部塊';

  @override
  String get blocks_collections => '收藏集';

  @override
  String get blocks_newCollection => '新增收藏集';

  @override
  String get blocks_collectionName => '收藏集名稱';

  @override
  String get blocks_noCollections => '把卡片拖到這裡的收藏集，一個塊可以進多個收藏集。';

  @override
  String get blocks_deleteCollection => '刪除收藏集';

  @override
  String get blocks_newFolder => '新增資料夾';

  @override
  String get blocks_newSubfolder => '新增子資料夾';

  @override
  String get blocks_folderName => '資料夾名稱';

  @override
  String get blocks_deleteFolder => '刪除資料夾…';

  @override
  String get blocks_moveUp => '上移';

  @override
  String get blocks_moveDown => '下移';

  @override
  String get blocks_moveToTop => '移到頂層';

  @override
  String get blocks_tagName => '標籤名';

  @override
  String get blocks_tagColor => '改顏色';

  @override
  String get blocks_deleteTag => '刪除標籤';

  @override
  String get blocks_collapseSidebar => '收起左欄';

  @override
  String get blocks_expandSidebar => '展開左欄';

  @override
  String get blocks_importExport => '匯入 / 匯出';

  @override
  String get blocks_importTxt => '匯入 TXT…';

  @override
  String get blocks_importFolder => '匯入資料夾…';

  @override
  String get blocks_importCuration => '整理匯入…';

  @override
  String get blocks_exportBackup => '匯出整庫備份';

  @override
  String get blocks_importBackup => '匯入整庫備份…';

  @override
  String blocks_dropMoveTo(Object name) {
    return '移到「$name」';
  }

  @override
  String blocks_dropCopyTo(Object name) {
    return '複製到「$name」';
  }

  @override
  String blocks_dropAddTo(Object name) {
    return '加入「$name」';
  }

  @override
  String get blocks_searchLibrary => '搜尋標題、內容或標籤';

  @override
  String get blocks_sortCustom => '自訂順序';

  @override
  String get blocks_sortUpdated => '最近修改';

  @override
  String get blocks_sortTitle => '名稱';

  @override
  String get blocks_sortColor => '顏色';

  @override
  String get blocks_sortIcon => '圖示';

  @override
  String get blocks_sortAsc => '升序';

  @override
  String get blocks_sortDesc => '降序';

  @override
  String get blocks_viewGrid => '網格';

  @override
  String get blocks_viewList => '列表';

  @override
  String get blocks_multiSelect => '多選';

  @override
  String get blocks_multiDone => '完成多選';

  @override
  String get blocks_hideInspector => '收起詳情';

  @override
  String get blocks_showInspector => '展開詳情';

  @override
  String get blocks_quickImage => '有預覽圖';

  @override
  String get blocks_quickNegative => '含負面';

  @override
  String get blocks_quickParams => '附帶參數';

  @override
  String get blocks_cardSize => '卡片大小';

  @override
  String get blocks_noMatch => '沒有符合條件的塊';

  @override
  String get blocks_noMatchBody => '換個關鍵詞，或者清除快速篩選。';

  @override
  String get blocks_clearFilters => '清除篩選';

  @override
  String get blocks_insert => '插入';

  @override
  String get blocks_insertToPrompt => '插入到提示詞';

  @override
  String get blocks_miniNegative => '負面';

  @override
  String get blocks_miniParams => '參數';

  @override
  String get blocks_colName => '名稱';

  @override
  String get blocks_colItems => '項數';

  @override
  String get blocks_colFolder => '資料夾';

  @override
  String get blocks_colUsed => '使用';

  @override
  String get blocks_colModified => '修改';

  @override
  String blocks_selectedN(Object count) {
    return '已選 $count 個';
  }

  @override
  String blocks_selectedBlocksN(Object count) {
    return '已選 $count 個塊';
  }

  @override
  String get blocks_moveTo => '移到…';

  @override
  String get blocks_noTags => '還沒有標籤';

  @override
  String get blocks_emptyTitle => '塊庫還是空的';

  @override
  String get blocks_emptyBody =>
      '把常用的一串提示詞存成塊：畫師池、角色、服裝、品質詞……插進提示詞後可以固定、按順序輪流或隨機抽取。';

  @override
  String get blocks_duplicate => '複製一份';

  @override
  String get blocks_copyContent => '複製內容';

  @override
  String get blocks_applyParams => '應用附帶參數';

  @override
  String get blocks_exportTxt => '匯出為 TXT';

  @override
  String get blocks_removeFromCollection => '移出收藏集';

  @override
  String blocks_deleteOne(Object name) {
    return '刪除「$name」？';
  }

  @override
  String blocks_deleteMany(Object count) {
    return '刪除 $count 個塊？';
  }

  @override
  String get blocks_deleteBody => '提示詞裡已經插入的實例會顯示為“塊已刪除”，可以復原。';

  @override
  String get blocks_details => '詳情';

  @override
  String get blocks_noSelection => '點一張卡片檢視詳情。雙擊直接編輯，Enter 插入到提示詞。';

  @override
  String get blocks_changeThumb => '更換 / 調整';

  @override
  String get blocks_reading => '翻譯閱讀';

  @override
  String get blocks_needsReview => '需複核';

  @override
  String get blocks_applyToCurrent => '應用到當前';

  @override
  String get blocks_noParams => '沒有。插入時不會改動當前參數。';

  @override
  String get blocks_paramModel => '模型';

  @override
  String get blocks_paramSteps => '步數';

  @override
  String get blocks_paramGuidance => '引導';

  @override
  String get blocks_paramRescale => '重縮放';

  @override
  String get blocks_paramSampler => '取樣器';

  @override
  String get blocks_paramNoise => '噪聲';

  @override
  String blocks_steps(Object count) {
    return '$count 步';
  }

  @override
  String blocks_guidance(Object value) {
    return '引導 $value';
  }

  @override
  String blocks_rescale(Object value) {
    return '重縮放 $value';
  }

  @override
  String get blocks_newTagInEdit => '新標籤…';

  @override
  String blocks_modifiedAt(Object time) {
    return '修改於 $time';
  }

  @override
  String blocks_createdAt(Object date) {
    return '創建於 $date';
  }

  @override
  String blocks_sourceFile(Object path) {
    return '來源檔案 $path';
  }

  @override
  String get blocks_sourceSynced => '與檔案一致';

  @override
  String get blocks_sourceChanged => '檔案已改動';

  @override
  String get blocks_sourceMissing => '檔案已不在';

  @override
  String blocks_importedAt(Object date) {
    return '匯入於 $date';
  }

  @override
  String get blocks_total => '合計';

  @override
  String blocks_totalItems(Object count) {
    return '$count 項內容';
  }

  @override
  String get blocks_from => '來自';

  @override
  String get blocks_batch => '批次操作';

  @override
  String get blocks_insertInOrder => '依次插入到提示詞';

  @override
  String get blocks_mergeNew => '合併成一個新塊…';

  @override
  String get blocks_batchStyle => '統一改顏色 / 外觀';

  @override
  String blocks_dragHint(Object count) {
    return '也可以直接把這 $count 張卡拖到左邊的資料夾或收藏集，鬆開時選擇移動還是複製。';
  }

  @override
  String get blocks_editBlockTitle => '編輯塊';

  @override
  String get blocks_editHint => '儲存後，提示詞裡固定模式的實例立即更新；隨機 / 順序在下次抽取時用新內容';

  @override
  String get blocks_newBlockHint => '塊存進塊庫後，可以從生圖頁側欄點一下插入';

  @override
  String get blocks_addThumb => '新增預覽圖';

  @override
  String get blocks_changeImage => '換圖';

  @override
  String get blocks_clearThumb => '清除預覽圖';

  @override
  String get blocks_cropHint => '拖動 / 滾輪縮放';

  @override
  String get blocks_namePlaceholder => '不填就用第一項';

  @override
  String get blocks_plainText => '純文本';

  @override
  String get blocks_plainTextHint => '原樣儲存這段文字，不拆成項';

  @override
  String get blocks_atomHint => '輸入後按 Enter 或逗號成為一項；貼上一段會自動拆分';

  @override
  String get blocks_existingTags => '已有標籤';

  @override
  String get blocks_newTag => '新標籤';

  @override
  String get blocks_paramsNotAuto => '插入時不自動應用';

  @override
  String get blocks_noParamsShort => '沒有';

  @override
  String get blocks_editParams => '編輯參數';

  @override
  String get blocks_captureParams => '從當前讀取';

  @override
  String get blocks_keepCurrent => '不改當前值';

  @override
  String get blocks_clearParams => '清除參數';

  @override
  String get blocks_deleteBlock => '刪除塊';

  @override
  String get blocks_deleteConfirmInline => '確定刪除這個塊？';

  @override
  String get blocks_saveShortcut => 'Ctrl+Enter 儲存';

  @override
  String get blocks_saveAsBlock => '存為塊';

  @override
  String get blocks_lookup => '查詞條';

  @override
  String blocks_splitDone(Object count) {
    return '$count 項 · 已按逗號拆好';
  }

  @override
  String get blocks_replaceSelection => '儲存後把選中的文字換成這個塊';

  @override
  String get blocks_quickHint => '更多設定（預覽圖、負面、參數）稍後在塊庫裡改';

  @override
  String get imageViewer_backGallery => '本地畫廊';

  @override
  String get imageViewer_backGeneration => '生圖';

  @override
  String get imageViewer_scopeAll => '全部圖片';

  @override
  String get imageViewer_sortModified => '按修改時間';

  @override
  String get imageViewer_sortCreated => '按建立時間';

  @override
  String get imageViewer_sortFileName => '按檔名';

  @override
  String get imageViewer_sortFileSize => '按檔案大小';

  @override
  String get imageViewer_sortDimensions => '按尺寸';

  @override
  String get imageViewer_unsaved => '未儲存';

  @override
  String get imageViewer_saved => '已儲存';

  @override
  String imageViewer_batch(Object count) {
    return '生成結果 · 本批 $count 張';
  }

  @override
  String imageViewer_zoomFit(Object percent) {
    return '適應 · $percent%';
  }

  @override
  String get imageViewer_zoomFitPending => '適應 · —';

  @override
  String get imageViewer_zoomFitShort => '適應';

  @override
  String get imageViewer_zoomIn => '放大';

  @override
  String get imageViewer_zoomOut => '縮小';

  @override
  String get imageViewer_actualSize => '原始大小';

  @override
  String get imageViewer_fullscreen => '全屏';

  @override
  String get imageViewer_exitFullscreen => '退出全屏';

  @override
  String get imageViewer_fullscreenHint => '滑鼠移到底部顯示膠片條，靜止 2 秒後控制元件自動隱藏';

  @override
  String get imageViewer_infoPanel => '資訊欄';

  @override
  String get imageViewer_infoShort => '資訊';

  @override
  String get imageViewer_hideInfo => '收起資訊欄';

  @override
  String get imageViewer_previous => '上一張';

  @override
  String get imageViewer_next => '下一張';

  @override
  String get imageViewer_loadingOriginal => '讀取原圖';

  @override
  String imageViewer_loadingOriginalSize(Object size) {
    return '讀取原圖 · $size';
  }

  @override
  String get imageViewer_missingTitle => '找不到這張圖';

  @override
  String get imageViewer_missingHint => '可能已經在資源管理器裡被移動、改名或刪除';

  @override
  String get imageViewer_openFolder => '開啟所在資料夾';

  @override
  String get imageViewer_nextImage => '下一張';

  @override
  String get imageViewer_hintPan => '拖動平移';

  @override
  String get imageViewer_hintWheel => '滾輪縮放';

  @override
  String get imageViewer_hintDouble => '雙擊 /';

  @override
  String get imageViewer_hintFit => '回到適應';

  @override
  String get imageViewer_hintActual => '原始大小';

  @override
  String get imageViewer_dragFrame => '拖框移動';

  @override
  String get imageViewer_movedToTrash => '已移到回收站';

  @override
  String get imageViewer_undo => '復原';

  @override
  String get imageViewer_details => '詳情';

  @override
  String get imageViewer_generationResult => '生成結果';

  @override
  String get imageViewer_favorite => '收藏';

  @override
  String get imageViewer_showInFolder => '在資料夾中顯示';

  @override
  String imageViewer_deleteKey(Object key) {
    return '刪除  $key';
  }

  @override
  String get imageViewer_more => '更多';

  @override
  String imageViewer_genIndex(Object index) {
    return '本次生成 · 第 $index 張';
  }

  @override
  String get imageViewer_notSaved => '還沒儲存到圖庫';

  @override
  String get imageViewer_savedToGallery => '已儲存到圖庫';

  @override
  String get imageViewer_size => '尺寸';

  @override
  String get imageViewer_fileSize => '大小';

  @override
  String get imageViewer_modified => '修改時間';

  @override
  String get imageViewer_model => '模型';

  @override
  String get imageViewer_params => '生成參數';

  @override
  String get imageViewer_loadingMeta => '正在讀取後設資料…';

  @override
  String get imageViewer_seed => '種子';

  @override
  String get imageViewer_sampler => '取樣器';

  @override
  String get imageViewer_steps => '步數';

  @override
  String get imageViewer_guidance => '提示詞引導';

  @override
  String imageViewer_noise(Object value) {
    return '噪聲 $value';
  }

  @override
  String imageViewer_rescale(Object value) {
    return '重縮放 $value';
  }

  @override
  String imageViewer_precise(Object count) {
    return '精準參考 ×$count';
  }

  @override
  String get imageViewer_qualityTags => '品質詞';

  @override
  String get imageViewer_prompt => '提示詞';

  @override
  String get imageViewer_translate => '翻譯';

  @override
  String get imageViewer_showOriginal => '顯示原文';

  @override
  String imageViewer_translateFailed(Object error) {
    return '翻譯失敗：$error';
  }

  @override
  String get imageViewer_copy => '複製';

  @override
  String get imageViewer_copySeed => '複製種子';

  @override
  String get imageViewer_expandAll => '展開全部';

  @override
  String get imageViewer_expand => '展開';

  @override
  String get imageViewer_collapse => '收起';

  @override
  String imageViewer_character(Object index) {
    return '角色 $index';
  }

  @override
  String imageViewer_position(Object cell) {
    return '位置 $cell';
  }

  @override
  String get imageViewer_characterNegative => '角色負面 · ';

  @override
  String get imageViewer_negative => '負面';

  @override
  String imageViewer_tagCount(Object count) {
    return '$count 項';
  }

  @override
  String get imageViewer_vibes => 'Vibe 參考';

  @override
  String imageViewer_vibeStrength(Object value) {
    return '強度 $value';
  }

  @override
  String imageViewer_vibeInfo(Object value) {
    return '資訊 $value';
  }

  @override
  String get imageViewer_saveVibe => '存入 Vibe 庫';

  @override
  String get imageViewer_noMetaTitle => '沒有 NovelAI 生成資訊';

  @override
  String get imageViewer_noMetaBody =>
      '這張圖不是 NAI 生成的，或者後設資料已經被去掉了（截圖、轉存、壓縮過的圖常見）。\n下面的圖生圖、風格遷移、精準參考、放大照樣能用。';

  @override
  String get imageViewer_reuse => '複用參數';

  @override
  String get imageViewer_reuseNoMeta => '這張圖沒有生成資訊';

  @override
  String get imageViewer_img2img => '圖生圖';

  @override
  String get imageViewer_styleTransfer => '風格遷移';

  @override
  String get imageViewer_preciseRef => '精準參考';

  @override
  String get imageViewer_saveRef => '存入參考庫';

  @override
  String get imageViewer_krita => '傳送到 Krita';

  @override
  String get imageViewer_kritaOff => 'Krita 沒連線';

  @override
  String get imageViewer_upscale => '放大';

  @override
  String get imageViewer_copyImage => '複製圖片';

  @override
  String get imageViewer_saveBlock => '存為塊';

  @override
  String get imageViewer_save => '儲存到圖庫';

  @override
  String get imageViewer_copyPath => '複製檔案路徑';

  @override
  String get imageViewer_copyAllPrompts => '複製全部提示詞（含角色）';

  @override
  String get imageViewer_saveBlockEllipsis => '存為塊…';

  @override
  String get imageViewer_addToCollection => '加入收藏集';

  @override
  String get imageViewer_moveTo => '移動到…';

  @override
  String get imageViewer_copyTo => '複製到…';

  @override
  String get imageViewer_moveToTrash => '移到回收站';

  @override
  String get imageViewer_collections => '收藏集';

  @override
  String get imageViewer_newCollection => '新增收藏集…';

  @override
  String get imageViewer_helpTitle => '大圖快速鍵';

  @override
  String get imageViewer_helpHint => '可以在設定 → 快速鍵裡改';

  @override
  String get imageViewer_helpClose => '再按一次關閉';

  @override
  String get imageViewer_helpBrowse => '瀏覽';

  @override
  String get imageViewer_helpZoom => '縮放';

  @override
  String get imageViewer_helpActions => '操作';

  @override
  String get imageViewer_helpPrevNext => '上一張 / 下一張';

  @override
  String get imageViewer_helpFirstLast => '第一張 / 最後一張';

  @override
  String get imageViewer_helpInfo => '顯示 / 收起資訊欄';

  @override
  String get imageViewer_helpClose2 => '關閉';

  @override
  String get imageViewer_helpZoomInOut => '放大 / 縮小';

  @override
  String get imageViewer_helpActual => '原始大小 100%';

  @override
  String get imageViewer_helpWheel => '以滑鼠處為中心縮放';

  @override
  String get imageViewer_helpDouble => '適應 ↔ 放大';

  @override
  String get imageViewer_keyWheel => '滾輪';

  @override
  String get imageViewer_keyDouble => '雙擊';

  @override
  String get imageViewer_helpCopyPrompt => '複製提示詞';

  @override
  String get imageViewer_helpUndo => '復原刪除';

  @override
  String get imageViewer_protectedTitle => '這張圖受保護，移到回收站？';

  @override
  String get imageViewer_protectedBody => '移到回收站後可以在回收站裡還原。';

  @override
  String get imageViewer_cancel => '取消';

  @override
  String get imageViewer_justNow => '剛剛';

  @override
  String imageViewer_minutesAgo(Object count) {
    return '$count 分鐘前';
  }

  @override
  String imageViewer_hoursAgo(Object count) {
    return '$count 小時前';
  }

  @override
  String get imageViewer_yesterday => '昨天';

  @override
  String get explore_back => '畫風探索';

  @override
  String get explore_close => '關閉';

  @override
  String get explore_cancel => '取消';

  @override
  String get explore_done => '完成';

  @override
  String get explore_more => '更多';

  @override
  String get explore_rename => '改名';

  @override
  String get explore_remove => '去掉';

  @override
  String get explore_copy => '複製';

  @override
  String get explore_undo => '復原';

  @override
  String get explore_expand => '展開';

  @override
  String get explore_expandAll => '展開全部';

  @override
  String get explore_collapse => '收起';

  @override
  String get explore_previous => '上一張';

  @override
  String get explore_next => '下一張';

  @override
  String explore_today(Object time) {
    return '今天 $time';
  }

  @override
  String explore_yesterday(Object time) {
    return '昨天 $time';
  }

  @override
  String explore_monthDay(Object month, Object day, Object time) {
    return '$month月$day日 $time';
  }

  @override
  String explore_fullDate(Object year, Object month, Object day) {
    return '$year年$month月$day日';
  }

  @override
  String get explore_sectionToday => '今天';

  @override
  String get explore_thisWeek => '本週';

  @override
  String get explore_earlier => '更早';

  @override
  String get explore_variables => '隨機變數';

  @override
  String get explore_variablesHint => '每張重新抽取';

  @override
  String get explore_variablesInfo =>
      '提示詞中啟用的順序或隨機塊，按各自的抽取規則取值。標“遺傳目標”的塊會合並抽取結果，組成父本串參與遺傳。';

  @override
  String get explore_variablesEmpty => '提示詞裡還沒有隨機塊。插入塊庫裡的隨機塊（比如畫師池），每張圖都會重新抽。';

  @override
  String get explore_openBlockLibrary => '開啟塊庫';

  @override
  String get explore_variableMissing => '塊已刪除';

  @override
  String explore_poolSize(Object count) {
    return '池 $count 項';
  }

  @override
  String get explore_evolutionTarget => '遺傳目標';

  @override
  String explore_draw(Object count) {
    return '抽 $count 張候選';
  }

  @override
  String get explore_stopGenerating => '停止生成';

  @override
  String get explore_busy => '生成中';

  @override
  String explore_cooldown(Object seconds) {
    return '冷卻 $seconds 秒';
  }

  @override
  String get explore_insufficient => 'Anlas 不夠';

  @override
  String explore_count(Object count) {
    return '$count 張';
  }

  @override
  String explore_favoritesCount(Object count) {
    return '收藏 $count';
  }

  @override
  String explore_roundsCount(Object count) {
    return '$count 輪';
  }

  @override
  String explore_linesCount(Object count) {
    return '$count 條進化線';
  }

  @override
  String explore_progressRound(Object round, Object done, Object total) {
    return '第 $round 輪 · $done / $total';
  }

  @override
  String explore_progressChildren(
    Object line,
    Object gen,
    Object done,
    Object total,
  ) {
    return '$line 第 $gen 代 · $done / $total';
  }

  @override
  String explore_paused(Object where) {
    return '已暫停 · $where';
  }

  @override
  String get explore_pause => '暫停';

  @override
  String get explore_resume => '繼續';

  @override
  String get explore_stop => '停止';

  @override
  String get explore_sizeSmall => '小卡片';

  @override
  String get explore_sizeLarge => '大卡片';

  @override
  String get explore_inspector => '檢查器';

  @override
  String get explore_hideInspector => '收起';

  @override
  String get explore_tabCandidates => '候選';

  @override
  String get explore_tabEvolution => '進化';

  @override
  String get explore_filterAll => '全部';

  @override
  String get explore_filterFavorites => '收藏';

  @override
  String get explore_filterUngrouped => '未分組';

  @override
  String get explore_addGroup => '分組';

  @override
  String get explore_groupName => '分組名稱';

  @override
  String get explore_deleteGroup => '刪除分組（成員回到未分組）';

  @override
  String get explore_newLine => '新進化線';

  @override
  String get explore_deleteLine => '刪除進化線';

  @override
  String get explore_compareShort => '兩兩比較';

  @override
  String get explore_evoHelp => '怎麼用';

  @override
  String get explore_evoHelpBody =>
      '1. 在候選裡挑幾張喜歡的，開始進化，它們的畫師串就是第 1 代父本。\n2. 子代由父本交叉、變異、注入新畫師得到。\n3. 勾選喜歡的子代培育下一代；兩兩比較能調整父本的偏好。';

  @override
  String get explore_select => '多選';

  @override
  String get explore_selectAll => '全選';

  @override
  String get explore_selectDone => '完成';

  @override
  String get explore_selectExit => '退出多選  Esc';

  @override
  String get explore_selectHint => '點卡片勾選';

  @override
  String explore_selectedN(Object count) {
    return '已選 $count 張';
  }

  @override
  String get explore_sortNewest => '新的輪在上（點一下改為舊的在上）';

  @override
  String get explore_sortOldest => '舊的輪在上（點一下改為新的在上）';

  @override
  String explore_round(Object number) {
    return '第 $number 輪';
  }

  @override
  String explore_generatingShort(Object done, Object total) {
    return '生成中 $done / $total';
  }

  @override
  String explore_failedRetry(Object count) {
    return '$count 張失敗 · 重試';
  }

  @override
  String get explore_pick => '挑幾張去進化';

  @override
  String get explore_pickTip => '進入多選，本輪收藏的已經勾上';

  @override
  String get explore_filterEmpty => '這個篩選下還沒有候選';

  @override
  String get explore_showAll => '顯示全部';

  @override
  String explore_queued(Object number) {
    return '排隊 #$number';
  }

  @override
  String explore_generatingN(Object number) {
    return '生成中 #$number';
  }

  @override
  String get explore_failed => '生成失敗';

  @override
  String get explore_failedHover => '懸停檢視原因';

  @override
  String get explore_noArtists => '沒有抽到畫師';

  @override
  String get explore_parentTip => '已經是進化線的父本';

  @override
  String get explore_favorite => '收藏';

  @override
  String get explore_favorited => '已收藏';

  @override
  String get explore_unfavorite => '取消收藏';

  @override
  String get explore_addToEvolution => '加入進化';

  @override
  String get explore_startEvolution => '開始進化';

  @override
  String get explore_saveBlock => '存為塊';

  @override
  String get explore_applyToEditor => '套用到編輯區';

  @override
  String get explore_copyArtists => '複製畫師串';

  @override
  String get explore_openLarge => '看大圖';

  @override
  String get explore_group => '分組';

  @override
  String get explore_groups => '分組';

  @override
  String get explore_groupsHint => '按 1–9 快速歸組';

  @override
  String get explore_newGroup => '新分組';

  @override
  String get explore_ungroup => '移出分組';

  @override
  String get explore_delete => '刪除';

  @override
  String explore_deleteN(Object count) {
    return '刪除 $count 張';
  }

  @override
  String get explore_deleteThis => '刪除這張';

  @override
  String explore_deleted(Object count) {
    return '已刪除 $count 張';
  }

  @override
  String get explore_inspectorEmpty => '點一張候選，這裡會寫出它抽到了哪些畫師';

  @override
  String explore_childN(Object number) {
    return '子代 #$number';
  }

  @override
  String explore_genOp(Object gen, Object op) {
    return '第 $gen 代 · $op';
  }

  @override
  String get explore_drawn => '本張抽到';

  @override
  String get explore_drawEmpty => '這次沒有抽中（池裡有空項）';

  @override
  String get explore_origin => '怎麼來的';

  @override
  String get explore_seed => '種子';

  @override
  String get explore_elapsed => '耗時';

  @override
  String get explore_params => '參數';

  @override
  String get explore_sampler => '取樣器';

  @override
  String get explore_model => '模型';

  @override
  String explore_steps(Object count) {
    return '$count 步';
  }

  @override
  String get explore_fullPrompt => '完整提示詞';

  @override
  String get explore_negative => '負面';

  @override
  String get explore_failReason => '失敗原因';

  @override
  String get explore_retryFailed => '重試失敗的候選';

  @override
  String get explore_waitHint => '生成好以後這裡會顯示它抽到的畫師';

  @override
  String explore_mergedArtists(Object count) {
    return '合在一起的畫師 · $count';
  }

  @override
  String get explore_multiHint => '存為塊會把這些畫師合成一個塊；開始進化時每張都是一個父本。';

  @override
  String get explore_evoEmptyTitle => '還沒有進化線';

  @override
  String get explore_evoEmptyBody => '在候選裡挑幾張喜歡的，點“開始進化”，讓好的畫師組合繼續雜交出新組合。';

  @override
  String get explore_evoGoPick => '去候選裡挑';

  @override
  String explore_gen(Object number) {
    return '第 $number 代';
  }

  @override
  String get explore_current => '當前';

  @override
  String explore_genFirst(Object picked, Object children) {
    return '從候選裡選了 $picked 張作為起點 · $children 張子代';
  }

  @override
  String explore_genFrom(
    Object parents,
    Object children,
    Object from,
    Object picked,
  ) {
    return '$parents 個父本 → $children 張子代 · 由第 $from 代挑 $picked 張';
  }

  @override
  String get explore_backcross => '第 1 代回交';

  @override
  String get explore_compare => '兩兩比較排序';

  @override
  String get explore_compareTip => '一次看兩張父本，選更好的那張，偏好越高越常被選中';

  @override
  String explore_generateChildren(Object count) {
    return '再生成 $count 張子代';
  }

  @override
  String explore_children(Object count) {
    return '子代 · $count';
  }

  @override
  String explore_pickedN(Object count) {
    return '已選 $count';
  }

  @override
  String get explore_breedHint => '勾選喜歡的子代，培育下一代';

  @override
  String explore_breed(Object count, Object next) {
    return '用選中的 $count 張培育第 $next 代';
  }

  @override
  String get explore_noChildren => '還沒有子代 · 點“再生成”出第一批';

  @override
  String explore_parentsByPref(Object count) {
    return '父本 · 按偏好排序 · $count';
  }

  @override
  String get explore_opMutation => '變異';

  @override
  String get explore_opCrossover => '交叉';

  @override
  String get explore_opInjection => '注入';

  @override
  String get explore_searchRuns => '搜尋探索';

  @override
  String get explore_newRun => '新增探索';

  @override
  String get explore_newRunHint => '用當前提示詞和參數開一個新的，名字可以之後改';

  @override
  String explore_runRunning(Object done, Object total) {
    return '生成中 $done/$total';
  }

  @override
  String explore_runPaused(Object done, Object total) {
    return '已暫停 $done/$total';
  }

  @override
  String explore_runFailed(Object count) {
    return '$count 張失敗';
  }

  @override
  String get explore_noRunMatch => '沒有匹配的探索';

  @override
  String get explore_runMenuHint => '自動命名：隨機塊名 + 日期 · 懸停一行點“⋯”改名或刪除';

  @override
  String get explore_deleteRun => '刪除探索';

  @override
  String explore_deleteRunTitle(Object name) {
    return '刪除“$name”？';
  }

  @override
  String explore_deleteRunBody(Object count) {
    return '$count 張候選和所有進化線會一起刪掉，不能復原。圖庫裡的圖不受影響。';
  }

  @override
  String explore_deleteLineTitle(Object name) {
    return '刪除進化線“$name”？';
  }

  @override
  String explore_deleteLineBody(Object count) {
    return '它生成的 $count 張子代會一起刪掉，不能復原。候選不受影響。';
  }

  @override
  String get explore_onboardingTitle => '用隨機塊批次試畫風';

  @override
  String get explore_onboardingBody => '每張圖從畫師池裡重新抽，挑出喜歡的組合，再讓它們進化。';

  @override
  String get explore_step1 => '放一個隨機塊';

  @override
  String get explore_step1Body => '在提示詞裡插入塊庫裡的隨機塊，比如畫師池。';

  @override
  String get explore_step2 => '抽一批候選';

  @override
  String explore_step2Body(Object count) {
    return '點左下角“抽 $count 張候選”，每張都會重新抽畫師。';
  }

  @override
  String get explore_step3 => '收藏、進化、存為塊';

  @override
  String get explore_step3Body => '喜歡的收藏起來，拿去進化，滿意的組合存成塊。';

  @override
  String explore_detected(Object count) {
    return '已檢測到 $count 個';
  }

  @override
  String get explore_noVariables => '還沒有隨機塊';

  @override
  String get explore_openPrevious => '開啟以前的探索';

  @override
  String explore_evoTitle(Object count) {
    return '用 $count 張候選開始進化';
  }

  @override
  String explore_evoJoinTitle(Object count, Object line, Object gen) {
    return '把 $count 張加入“$line”第 $gen 代';
  }

  @override
  String get explore_evoStep1 => '父本';

  @override
  String get explore_evoStep1Body => '每張候選的畫師串是一個父本';

  @override
  String get explore_evoStep2 => '子代';

  @override
  String get explore_evoStep2Body => '交叉、變異、注入新畫師';

  @override
  String get explore_evoStep3 => '挑選';

  @override
  String get explore_evoStep3Body => '勾選喜歡的，培育下一代';

  @override
  String get explore_evoNewLine => '新增進化線';

  @override
  String explore_evoJoin(Object line, Object gen) {
    return '加入“$line”第 $gen 代';
  }

  @override
  String get explore_lineName => '進化線名稱';

  @override
  String explore_lineDefault(Object number) {
    return '進化線 $number';
  }

  @override
  String explore_lineGen(Object line, Object gen) {
    return '$line · 第 $gen 代';
  }

  @override
  String explore_evoParents(Object count) {
    return '第 1 代父本 · $count';
  }

  @override
  String explore_evoAddParents(Object count) {
    return '加入的父本 · $count';
  }

  @override
  String get explore_addCustom => '再加一段自訂畫師串';

  @override
  String get explore_customHint =>
      '比如 0.8::artist:ciloranko::, artist:rella（回車新增）';

  @override
  String get explore_targetBefore => '遺傳目標：';

  @override
  String get explore_targetAfter => '合併抽取結果，組成父本串';

  @override
  String get explore_noTarget => '還沒有遺傳目標。請在順序或隨機塊上開啟遺傳。';

  @override
  String get explore_firstBatch => '第一批子代';

  @override
  String get explore_atLeast4 => '張（至少 4）';

  @override
  String get explore_createOnly => '只建立';

  @override
  String get explore_joinOnly => '只加入';

  @override
  String explore_createGenerate(Object count) {
    return '建立並生成 $count 張';
  }

  @override
  String get explore_saveBlockTitle => '存為提示詞塊';

  @override
  String get explore_untitled => '未命名';

  @override
  String explore_blockFromOne(Object number) {
    return '來自候選 #$number';
  }

  @override
  String explore_blockFromMany(Object count) {
    return '來自 $count 張候選，已合併去重';
  }

  @override
  String explore_blockNameMany(Object run, Object count) {
    return '$run · 精選 $count';
  }

  @override
  String get explore_blockContent => '內容';

  @override
  String get explore_blockArtists => '只要抽到的畫師';

  @override
  String get explore_blockFull => '完整正向提示詞';

  @override
  String get explore_blockFullSingle => '只有一張候選時可以存完整提示詞';

  @override
  String get explore_blockRemoveHint => '點 × 去掉不要的畫師';

  @override
  String explore_blockKept(Object kept, Object total) {
    return '保留 $kept / $total';
  }

  @override
  String get explore_blockName => '名稱';

  @override
  String get explore_blockColor => '顏色';

  @override
  String get explore_blockFolder => '放到塊庫';

  @override
  String get explore_blockRoot => '塊庫（根目錄）';

  @override
  String get explore_blockFooter => '存好後可以在塊庫裡拖進提示詞';

  @override
  String get explore_compareTitle => '兩兩比較 · 給父本排個序';

  @override
  String get explore_compareNote => '結果隨時儲存，可以中途關掉';

  @override
  String get explore_compareQuestion => '哪張更接近你想要的畫風？';

  @override
  String explore_comparePairs(Object index, Object total) {
    return '$index / $total 對';
  }

  @override
  String get explore_leftBetter => '左邊更好';

  @override
  String get explore_rightBetter => '右邊更好';

  @override
  String get explore_neither => '兩張都不行';

  @override
  String get explore_skip => '跳過';

  @override
  String get explore_keySpace => '空格';

  @override
  String get explore_ranking => '當前排名 · 即時';

  @override
  String get explore_rankingNote => '偏好越高，培育下一代時越常被選為父本。';

  @override
  String get explore_compareDone => '排好了';

  @override
  String get explore_compareDoneBody => '新的偏好已經儲存，下次生成子代就會用上。';

  @override
  String get gen_cancel => '取消';

  @override
  String get gen_close => '關閉';

  @override
  String get gen_done => '完成';

  @override
  String get gen_more => '更多';

  @override
  String get gen_delete => '刪除';

  @override
  String get gen_remove => '移除';

  @override
  String get gen_rename => '改名';

  @override
  String get gen_add => '新增';

  @override
  String get gen_clear => '清空';

  @override
  String get gen_clearAll => '全部清空';

  @override
  String get gen_clearConfirm => '清空';

  @override
  String get gen_removeConfirm => '移除';

  @override
  String get gen_expand => '展開';

  @override
  String get gen_collapse => '收起';

  @override
  String get gen_copied => '已複製';

  @override
  String get gen_random => '隨機';

  @override
  String get gen_auto => '自動';

  @override
  String get gen_pin => '釘在頭部';

  @override
  String get gen_unpin => '從頭部取下';

  @override
  String get gen_yesterday => '昨天';

  @override
  String gen_monthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get gen_params => '生成參數';

  @override
  String get gen_generating => '生成中';

  @override
  String get gen_modelsNew => '新模型';

  @override
  String get gen_modelsLegacy => '舊模型';

  @override
  String get gen_turboEnable =>
      '開啟 Turbo（Medium Effort）\n固定 14 步與 Euler Ancestral；自訂負面草稿保留，切回 Full 後恢復。';

  @override
  String get gen_turboDisable =>
      '正在使用 Turbo（Medium Effort）\n點選切回 V5 Full，恢復原來的參數與負面草稿。';

  @override
  String get gen_turboUnavailable => 'Turbo 僅適用於 V5 Full';

  @override
  String get gen_turboFixed => 'Turbo 固定 14 步、Euler Ancestral，不支援 CFG Rescale。';

  @override
  String get gen_turboNegative => 'Turbo 不使用自訂負面。原草稿已保留，切回 Full 可恢復。';

  @override
  String get generation_modelDesc_v5Turbo =>
      'V5 Full 的 Medium Effort 模式，固定 14 步、Euler Ancestral，降低 Anlas 與 Opus 額度消耗。';

  @override
  String get gen_modeTip => '點一下切換 Anime / Furry';

  @override
  String gen_anlasTip(Object value) {
    return 'Anlas 餘額 $value';
  }

  @override
  String get gen_positive => '正面';

  @override
  String get gen_basePrompt => '基礎提示詞';

  @override
  String get gen_negative => '負面';

  @override
  String get gen_finalPositive => '最終傳送的正面';

  @override
  String get gen_finalNegative => '最終傳送的負面';

  @override
  String get gen_toolDock => '塊庫側欄';

  @override
  String get gen_toolPalette => '積木板';

  @override
  String get gen_toolTranslate => '翻譯';

  @override
  String get gen_toolsMenu => '模組與開關';

  @override
  String get gen_toolsPinned => '釘在頭部的工具';

  @override
  String get gen_toolsSettings => '提示詞設定';

  @override
  String get gen_fullscreen => '全屏編輯';

  @override
  String get gen_autoFormat => '自動格式化';

  @override
  String get gen_autoFormatSub => '失焦時整理逗號和空格';

  @override
  String get gen_highlight => '強調高亮';

  @override
  String get gen_highlightSub => '按權重給片段上色';

  @override
  String get gen_sdConvert => 'SD 語法自動轉換';

  @override
  String get gen_sdConvertSub => '貼上 (tag:1.2) 時轉成 NAI 權重';

  @override
  String get gen_related => '共現推薦';

  @override
  String get gen_relatedSub => '補全時推薦常一起出現的標籤';

  @override
  String get gen_translating => '正在翻譯…';

  @override
  String get gen_translateNeedsModel => '還沒配翻譯模型，點一下去設定';

  @override
  String gen_translateWith(Object route) {
    return '翻譯（$route）';
  }

  @override
  String get gen_translateNew => '翻譯新增內容';

  @override
  String get gen_translateShowOriginal => '全部顯示原文';

  @override
  String get gen_translateShowTranslated => '全部顯示譯文';

  @override
  String get gen_translateSettings => '翻譯模型設定';

  @override
  String get gen_qualityPreset => '品質詞預設';

  @override
  String get gen_ucPreset => '負面預設';

  @override
  String get gen_presetNone => '無';

  @override
  String get gen_transparentOn => '透明背景：開';

  @override
  String get gen_transparentOff => '透明背景：關';

  @override
  String get gen_characters => '角色提示詞';

  @override
  String get gen_charactersTip => '給畫面裡每個角色單獨寫提示詞，不會互相串。';

  @override
  String get gen_charactersEmpty => '還沒有角色。點右上角 + 新增，每個角色單獨寫提示詞。';

  @override
  String gen_charactersFull(Object max) {
    return '最多 $max 個角色';
  }

  @override
  String get gen_addCharacter => '新增角色';

  @override
  String gen_addAs(Object gender) {
    return '新增$gender';
  }

  @override
  String get gen_clearCharacters => '清空全部';

  @override
  String get gen_clearCharactersTitle => '清空全部角色？';

  @override
  String gen_clearCharactersBody(Object count) {
    return '$count 個角色和它們的提示詞都會刪掉。';
  }

  @override
  String gen_characterN(Object n) {
    return '角色 $n';
  }

  @override
  String get gen_genderFemale => '女性';

  @override
  String get gen_genderMale => '男性';

  @override
  String get gen_genderOther => '其他';

  @override
  String get gen_position => '定位';

  @override
  String get gen_positionAi => 'AI 選擇';

  @override
  String get gen_positionCustom => '自訂';

  @override
  String get gen_positionBoard => '角色位置';

  @override
  String get gen_positionAiTip => '位置由 AI 決定';

  @override
  String gen_positionAt(Object at) {
    return '位置 $at，點一下調整';
  }

  @override
  String get gen_positionUnset => '還沒放位置，點一下襬放';

  @override
  String get gen_positionAiHint => '現在由 AI 決定位置';

  @override
  String get gen_positionGridHint => '拖角色到格子裡，鬆手吸附到格子中心';

  @override
  String get gen_positionFreeHint => '拖角色到畫面裡任意位置';

  @override
  String get gen_positionAiOverlay => '現在是 AI 選擇位置。\n切到自訂才能手動擺放。';

  @override
  String get gen_positionToCustom => '切到自訂';

  @override
  String get gen_positionUnplaced => '還沒放';

  @override
  String get gen_renameTip => '雙擊改名';

  @override
  String get gen_moveUp => '上移';

  @override
  String get gen_moveDown => '下移';

  @override
  String get gen_characterDisable => '這次不用這個角色';

  @override
  String get gen_characterEnable => '用這個角色';

  @override
  String get gen_charPositive => '正面';

  @override
  String get gen_charNegative => '負面';

  @override
  String get gen_saveAsBlock => '存為塊';

  @override
  String get gen_refs => '參考圖';

  @override
  String get gen_img2img => '圖生圖';

  @override
  String get gen_img2imgDesc => '基於原圖生成變體';

  @override
  String gen_img2imgSummary(Object strength, Object noise) {
    return '強度 $strength · 噪聲 $noise';
  }

  @override
  String get gen_img2imgDrop => '拖一張圖進來，或者';

  @override
  String get gen_upload => '上傳';

  @override
  String get gen_replace => '更換';

  @override
  String get gen_edit => '編輯';

  @override
  String get gen_inpaint => '局部重繪';

  @override
  String get gen_placeOnCanvas => '放到畫布';

  @override
  String get gen_fromPreciseLibrary => '從精準參考庫';

  @override
  String get gen_sketch => '畫草圖';

  @override
  String get gen_strength => '強度';

  @override
  String get gen_strengthTip => '越高越不像原圖（預設 0.7）';

  @override
  String get gen_noise => '噪聲';

  @override
  String get gen_noiseTip => '加噪讓細節更多變化（預設 0）';

  @override
  String get gen_inpaintStrength => '重繪強度';

  @override
  String get gen_inpaintReady => '遮罩已畫好，生成時只重繪塗過的區域。';

  @override
  String get gen_refPause => '這次不傳送';

  @override
  String get gen_refResume => '恢復傳送';

  @override
  String get gen_refPaused => '已暫停，這次不傳送';

  @override
  String get gen_vibe => '風格遷移';

  @override
  String get gen_vibeDesc => '改變影像，保留視覺風格';

  @override
  String get gen_vibeSkipped => '有精準參考，這次不會發送';

  @override
  String get gen_vibeConflict => '生圖頁有精準參考時，風格遷移不會發送。';

  @override
  String get gen_vibeDrop => '拖圖片或 .naiv4vibe 進來，或者';

  @override
  String get gen_addVibe => '新增 Vibe';

  @override
  String get gen_addFromFile => '從檔案新增';

  @override
  String get gen_addFromVibeLibrary => '從 Vibe 庫新增';

  @override
  String get gen_addFromPreciseLibrary => '從精準參考庫新增';

  @override
  String gen_vibeFull(Object max) {
    return '最多 $max 個';
  }

  @override
  String get gen_saveToLibrary => '存入庫';

  @override
  String get gen_normalize => '標準化';

  @override
  String get gen_normalizeTip => '按總和標準化各 Vibe 的強度';

  @override
  String gen_vibeExtraCost(Object free, Object each, Object total) {
    return '超過 $free 個後每個 +$each Anlas · 本次 +$total';
  }

  @override
  String get gen_recent => '最近';

  @override
  String get gen_encoded => '已編碼';

  @override
  String get gen_encoding => '編碼中';

  @override
  String get gen_encode => '編碼';

  @override
  String gen_encodeTip(Object cost) {
    return '編碼一次 $cost Anlas，編碼後可重複使用';
  }

  @override
  String get gen_vibeStrength => '強度';

  @override
  String get gen_vibeInfo => '資訊提取';

  @override
  String get gen_vibeInfoReencode => '已編碼的 Vibe 改資訊提取要重新編碼';

  @override
  String get gen_precise => '精準參考';

  @override
  String get gen_preciseDesc => '將生成繫結到角色或風格參考';

  @override
  String get gen_preciseDrop => '拖角色或風格參考圖進來，或者';

  @override
  String get gen_preciseCharacter => '角色';

  @override
  String get gen_preciseStyle => '風格';

  @override
  String get gen_preciseBoth => '角色 + 風格';

  @override
  String get gen_fidelity => '保真度';

  @override
  String gen_preciseCost(Object each, Object total) {
    return '每張 $each Anlas · 本次 +$total';
  }

  @override
  String get gen_preciseConflict => '有精準參考時，風格遷移這次不會發送。';

  @override
  String get gen_pauseVibes => '暫停 Vibe';

  @override
  String get gen_savePrecise => '存入精準參考庫';

  @override
  String get gen_addPrecise => '新增精準參考';

  @override
  String get gen_image => '影像';

  @override
  String get gen_sizeNormal => '常規';

  @override
  String get gen_sizeLarge => '大圖';

  @override
  String get gen_sizeWallpaper => '桌布';

  @override
  String get gen_sizeSmall => '小圖';

  @override
  String get gen_sizeCustom => '自訂';

  @override
  String get gen_portrait => '豎圖';

  @override
  String get gen_landscape => '橫圖';

  @override
  String get gen_square => '方圖';

  @override
  String get gen_width => '寬（按 64 取整）';

  @override
  String get gen_height => '高（按 64 取整）';

  @override
  String get gen_swapSize => '交換寬高';

  @override
  String get gen_count => '張數';

  @override
  String get gen_countTip => '一次請求出幾張（1–4）';

  @override
  String get gen_repeat => '重複';

  @override
  String get gen_repeatTip => '連續發幾次請求';

  @override
  String gen_repeatTotal(Object times, Object total) {
    return '重複 $times 次，共 $total 張 · 按住左右拖動調節';
  }

  @override
  String get gen_steps => '步數';

  @override
  String get gen_guidance => '引導';

  @override
  String get gen_guidanceTip => '越高越貼提示詞，太高會發硬（預設 5）';

  @override
  String get gen_cfgRescale => '引導重縮放';

  @override
  String get gen_cfgRescaleTip => '壓住高引導帶來的過飽和（預設 0）';

  @override
  String get gen_seed => '種子';

  @override
  String get gen_seedPinned => '種子 · 固定';

  @override
  String get gen_seedPinTip => '點一下固定這個種子';

  @override
  String get gen_seedUnpinTip => '點一下改回隨機';

  @override
  String get gen_seedRandomize => '改回隨機';

  @override
  String get gen_sampler => '取樣器';

  @override
  String get gen_samplerRecommended => '推薦';

  @override
  String get gen_samplerOther => '其他';

  @override
  String get gen_noiseSchedule => '噪聲排程';

  @override
  String get gen_varietyTip => '前幾步跳過引導，構圖更多樣';

  @override
  String get gen_decrispTip => '減輕高引導下的過度銳利';

  @override
  String get gen_smeaAutoTip => '按尺寸自動決定是否開 SMEA';

  @override
  String get gen_paramsTitle => '生成參數';

  @override
  String get gen_paramsOpen => '展開全部參數';

  @override
  String get gen_paramsClose => '收起參數';

  @override
  String get gen_stop => '停止生成';

  @override
  String gen_cooldown(Object seconds) {
    return '冷卻中 $seconds 秒';
  }

  @override
  String get gen_insufficient => 'Anlas 不夠';

  @override
  String get gen_free => '這次免費（Opus 額度內）';

  @override
  String get gen_emptyTitle => '寫好提示詞，開始第一張';

  @override
  String get gen_emptyPress => '按';

  @override
  String get gen_emptyOr => '或點左下角的生成';

  @override
  String get gen_tileFailed => '這張沒出來';

  @override
  String get gen_enhance => '增強';

  @override
  String get gen_variations => '變體';

  @override
  String get gen_upscale => '放大';

  @override
  String get gen_upscaleStop => '停止放大';

  @override
  String get gen_upscaleOptions => '放大方案';

  @override
  String get gen_setInit => '設為圖生圖原圖';

  @override
  String get gen_editImage => '編輯圖片';

  @override
  String get gen_sendToTools => '發到畫布工具';

  @override
  String get gen_display => '畫布顯示';

  @override
  String get gen_backdrop => '透明圖墊底';

  @override
  String get gen_backdropSub => '只墊在透明像素下面，不會存進圖片';

  @override
  String get gen_bdChecker => '棋盤格（跟隨主題）';

  @override
  String get gen_bdCheckerLight => '淺棋盤格';

  @override
  String get gen_bdCheckerDark => '深棋盤格';

  @override
  String get gen_bdNone => '不墊';

  @override
  String get gen_bdBlack => '黑';

  @override
  String get gen_bdWhite => '白';

  @override
  String get gen_bdGray => '灰';

  @override
  String get gen_bdRed => '紅';

  @override
  String get gen_bdGreen => '綠';

  @override
  String get gen_bdBlue => '藍';

  @override
  String get gen_bdCustom => '自訂';

  @override
  String get gen_zoomToFill => '放大填滿';

  @override
  String get gen_zoomToFillSub => '比畫布小的圖也放大到撐滿';

  @override
  String get gen_useSeed => '用這個種子（並固定）';

  @override
  String get gen_copySeed => '複製種子';

  @override
  String get gen_pinImage => '釘在畫布上';

  @override
  String get gen_unpinImage => '取消釘住';

  @override
  String get gen_copyImage => '複製圖片';

  @override
  String get gen_saveImage => '儲存到圖庫';

  @override
  String get gen_openViewer => '開啟大圖';

  @override
  String get gen_retry => '重試';

  @override
  String get gen_copyDetail => '複製詳情';

  @override
  String get gen_history => '歷史記錄';

  @override
  String get gen_historyEmpty => '這次還沒有生成';

  @override
  String get gen_historyEmptySub => '生成的圖會按批次排在這裡';

  @override
  String gen_batchCount(Object count) {
    return '$count 張';
  }

  @override
  String gen_batchPending(Object count) {
    return '還剩 $count 張';
  }

  @override
  String get gen_pinnedTip => '釘在畫布上的圖，點一下飛過去';

  @override
  String get gen_select => '多選';

  @override
  String get gen_selectDone => '完成多選';

  @override
  String gen_selectedCount(Object count) {
    return '已選 $count 張';
  }

  @override
  String get gen_pack => '打包成 zip';

  @override
  String get gen_saveSelected => '儲存選中的圖';

  @override
  String get gen_removeSelected => '從歷史移除';

  @override
  String get gen_autoSaveOn => '自動儲存到圖庫：開';

  @override
  String get gen_autoSaveOff => '自動儲存到圖庫：關';

  @override
  String get gen_scrollLock => '鎖定滾動（新圖來了不跳到頂部）';

  @override
  String get gen_scrollUnlock => '解除鎖定滾動';

  @override
  String get gen_saveAll => '全部儲存到圖庫';

  @override
  String get gen_clearHistory => '清空歷史';

  @override
  String get gen_clearHistoryTitle => '清空這次的歷史？';

  @override
  String get gen_clearHistoryBody => '只從這裡移除，已經儲存到圖庫的檔案不受影響。';

  @override
  String get gen_deleteImagesTitle => '從歷史移除？';

  @override
  String gen_deleteImagesBody(Object count) {
    return '$count 張圖會從這裡移除，已經儲存到圖庫的檔案不受影響。';
  }

  @override
  String gen_saveBatch(Object count) {
    return '儲存這批（$count 張）';
  }

  @override
  String gen_removeBatch(Object count) {
    return '移除這批（$count 張）';
  }

  @override
  String get gen_removeImage => '從歷史移除';

  @override
  String get gen_favorite => '收藏';

  @override
  String get gen_unfavorite => '取消收藏';

  @override
  String get gen_sendImg2Img => '傳送到圖生圖';

  @override
  String get gen_sendVibe => '加入風格遷移';

  @override
  String get gen_sendPrecise => '加入精準參考';

  @override
  String get gen_reveal => '在資源管理器中顯示';

  @override
  String get gen_opUpscale => '放大過';

  @override
  String get gen_opEnhance => '增強過';

  @override
  String get gen_opVariation => '變體';

  @override
  String get gen_opInpaint => '局部重繪';

  @override
  String get gen_opImg2Img => '圖生圖';

  @override
  String get tools_free => '免費';

  @override
  String get tools_localFree => '本機 · 免費';

  @override
  String tools_anlasN(Object count) {
    return '$count Anlas';
  }

  @override
  String get tools_cancel => '取消';

  @override
  String get tools_close => '關閉';

  @override
  String get tools_done => '完成';

  @override
  String get tools_reset => '重設';

  @override
  String get tools_apply => '應用';

  @override
  String get tools_retry => '重試';

  @override
  String get tools_optional => '可選';

  @override
  String get tools_justNow => '剛剛';

  @override
  String tools_minutesAgo(Object count) {
    return '$count 分鐘前';
  }

  @override
  String tools_hoursAgo(Object count) {
    return '$count 小時前';
  }

  @override
  String tools_monthDay(Object month, Object day) {
    return '$month 月 $day 日';
  }

  @override
  String get tools_useAsInit => '用作圖生圖底圖';

  @override
  String get tools_upscale => '放大';

  @override
  String get tools_enhance => '增強';

  @override
  String get tools_strength => '強度';

  @override
  String get tools_noise => '噪聲';

  @override
  String get tools_tipEnhance => '用當前提示詞把這張圖重畫一遍，補細節；可以順便放大';

  @override
  String get tools_tipVariations => '用這張圖的參數直接再出 4 張相近的圖，不改你的提示詞和設定';

  @override
  String get tools_tipUpscale => '按記住的放大設定直接放大；結果作為新圖出現在畫布上';

  @override
  String get tools_tipUpscaleRunning => '正在放大，點一下取消';

  @override
  String get tools_tipUpscaleSettings => '換本機 / 雲端、方法、模型和倍數';

  @override
  String get tools_tipSetInit => '把這張圖放進圖生圖，作為下一次生成的底圖';

  @override
  String get tools_tipEdit => '用畫筆、選區、調色修改這張圖，完成後替換圖生圖底圖';

  @override
  String get tools_tipInpaint => '畫遮罩圈出要重畫的地方，其餘保持原圖';

  @override
  String get tools_tipDirector => '背景移除、線稿、上色、表情修復等後期工具';

  @override
  String get tools_upscaleRunHint => '完成後新圖加入歷史；沒有切到別的圖就自動選中它';

  @override
  String get tools_enhanceSub => '用當前提示詞把這張圖重畫一遍，補細節；可以順便放大';

  @override
  String get tools_enhanceScale => '放大';

  @override
  String get tools_enhanceLocal => '本地放大';

  @override
  String get tools_enhanceLocalRow => '本地';

  @override
  String tools_enhanceOutLocal(Object size, Object factor) {
    return '$size → 本機 $factor';
  }

  @override
  String get tools_enhanceMagnitude => '幅度';

  @override
  String get tools_magLight => '輕微';

  @override
  String get tools_magMedium => '適中';

  @override
  String get tools_magStrong => '強烈';

  @override
  String tools_enhanceValues(Object strength, Object noise) {
    return '強度 $strength · 噪聲 $noise';
  }

  @override
  String get tools_enhanceCustomTag => '自訂';

  @override
  String get tools_enhanceCustom => '自訂強度和噪聲';

  @override
  String get tools_enhanceCustomHint => '強度越高改得越多；噪聲加細節但容易變髒';

  @override
  String get tools_localHint => '每張生成完成後自動在本機放大，不另外花 Anlas';

  @override
  String get tools_localNotSet => '還沒選本機放大模型';

  @override
  String get tools_upscaleSettings => '放大設定';

  @override
  String tools_enhanceFooter(Object model, Object steps) {
    return '用當前提示詞 · $model · $steps 步';
  }

  @override
  String get tools_enhanceRun => '增強';

  @override
  String get tools_enhanceRunLocal => '增強並本地放大';

  @override
  String get tools_upscaleSub => '放大結果作為新圖出現在畫布上，不動原圖和圖生圖底圖';

  @override
  String get tools_upscaleMethod => '方法';

  @override
  String get tools_upscaleModel => '模型';

  @override
  String get tools_upscaleManage => '管理模型';

  @override
  String get tools_upscaleScale => '倍數';

  @override
  String get tools_upscaleAdvanced => '進階設定';

  @override
  String get tools_upscaleFooter => '設定會記住；工具條上的“放大”直接按這套設定跑';

  @override
  String get tools_modelMissing => '未安裝';

  @override
  String get tools_modelDownloading => '下載中';

  @override
  String get tools_modelNone => '未選擇';

  @override
  String get tools_edit => '編輯影像';

  @override
  String get tools_editSub => '編輯後會替換圖生圖底圖';

  @override
  String get tools_inpaint => '局部重繪';

  @override
  String get tools_inpaintSub => '只重畫遮罩裡的地方，其餘保持原圖';

  @override
  String get tools_backEsc => '返回（Esc）';

  @override
  String get tools_panel => '面板';

  @override
  String get tools_undo => '復原';

  @override
  String get tools_redo => '重做';

  @override
  String get tools_download => '下載 PNG';

  @override
  String get tools_zoomIn => '放大';

  @override
  String get tools_zoomOut => '縮小';

  @override
  String get tools_zoomFit => '適應視窗';

  @override
  String get tools_applyMask => '應用遮罩';

  @override
  String get tools_applyMaskSub => '回到生圖頁，自己按生成';

  @override
  String get tools_applyGenerate => '應用並生成';

  @override
  String get tools_applyGenerateSub => '回到生圖頁並立刻開始重繪';

  @override
  String get tools_discardTitle => '放棄這次修改？';

  @override
  String get tools_discardBody => '還沒應用的筆畫、遮罩和圖層改動都會丟掉。';

  @override
  String get tools_discard => '放棄';

  @override
  String get tools_keepEditing => '繼續編輯';

  @override
  String get tools_toolBrush => '畫筆';

  @override
  String get tools_toolEraser => '橡皮';

  @override
  String get tools_toolFill => '填充';

  @override
  String get tools_toolBlur => '模糊';

  @override
  String get tools_toolStamp => '仿製圖章';

  @override
  String get tools_toolSelect => '矩形選區';

  @override
  String get tools_toolLasso => '套索';

  @override
  String get tools_toolPicker => '吸管';

  @override
  String get tools_toolMaskBrush => '畫遮罩';

  @override
  String get tools_toolMaskEraser => '擦遮罩';

  @override
  String get tools_toolFocus => '聚焦區域';

  @override
  String get tools_clearMask => '清空濛版';

  @override
  String get tools_expand => '擴展邊緣';

  @override
  String get tools_adjust => '調整顏色';

  @override
  String get tools_resize => '畫布尺寸';

  @override
  String get tools_size => '大小';

  @override
  String get tools_opacity => '不透明';

  @override
  String get tools_intensity => '強度';

  @override
  String get tools_tolerance => '容差';

  @override
  String get tools_tip => '筆尖';

  @override
  String get tools_tipHard => '硬';

  @override
  String get tools_tipSoft => '軟';

  @override
  String get tools_tipSquare => '方';

  @override
  String get tools_pressure => '壓感';

  @override
  String get tools_squareBrush => '方形筆刷';

  @override
  String get tools_hintStamp => 'Alt + 點選取樣，再在別處塗抹';

  @override
  String get tools_hintSelect => '拖出選區；Alt+L 複製成新圖層，Delete 清除選區內容';

  @override
  String get tools_hintPicker => '點畫面取色；用畫筆時按住 Alt 也能臨時取色';

  @override
  String get tools_hintMaskFill => '點一下把相近顏色的一片填成遮罩';

  @override
  String get tools_focusContext => '最小上下文';

  @override
  String get tools_hintFocus => '框出要精修的地方，模型只看框內和四周一圈，小臉、手更清楚';

  @override
  String get tools_clearFocus => '清除聚焦';

  @override
  String get tools_edgeTop => '上';

  @override
  String get tools_edgeBottom => '下';

  @override
  String get tools_edgeLeft => '左';

  @override
  String get tools_edgeRight => '右';

  @override
  String tools_hintExpand(Object step) {
    return '拖畫布四邊也可以；每次 $step 像素';
  }

  @override
  String get tools_maskLook => '遮罩外觀';

  @override
  String get tools_maskBorder => '描邊';

  @override
  String get tools_patternSolid => '純色';

  @override
  String get tools_patternLines => '斜線';

  @override
  String get tools_patternCrosshatch => '交叉線';

  @override
  String get tools_patternGrid => '網格';

  @override
  String get tools_patternDots => '圓點';

  @override
  String get tools_patternChecker => '棋盤格';

  @override
  String get tools_patternHearts => '愛心';

  @override
  String get tools_colorPrimary => '前景色';

  @override
  String get tools_colorSecondary => '背景色';

  @override
  String get tools_moreColors => '更多顏色…';

  @override
  String get tools_statusHint => '空格拖動 · 滾輪縮放 · Ctrl+0 適應視窗 · 1 原始大小';

  @override
  String get tools_statusGrid => '遮罩按 8 像素網格對齊';

  @override
  String get tools_statusMask => '遮罩';

  @override
  String get tools_inpaintSettings => '重繪設定';

  @override
  String get tools_inpaintStrength => '重繪強度';

  @override
  String get tools_inpaintStrengthHint => '越低越貼近原圖';

  @override
  String get tools_mask => '遮罩';

  @override
  String tools_maskCoverage(Object count) {
    return '的畫面 · $count 塊';
  }

  @override
  String get tools_focusNone => '未設定（整張圖）';

  @override
  String tools_focusContextShort(Object value) {
    return '· 上下文 $value';
  }

  @override
  String get tools_output => '輸出';

  @override
  String get tools_expandTag => '擴展';

  @override
  String get tools_layers => '圖層';

  @override
  String get tools_addLayer => '加圖層';

  @override
  String get tools_add3dLayer => '加 3D 圖層';

  @override
  String get tools_layerHint => 'Alt+L 把選區複製成新圖層';

  @override
  String get tools_hideLayer => '隱藏圖層';

  @override
  String get tools_showLayer => '顯示圖層';

  @override
  String get tools_layerUp => '上移';

  @override
  String get tools_layerDown => '下移';

  @override
  String get tools_layerDuplicate => '複製圖層';

  @override
  String get tools_layerMerge => '向下合併';

  @override
  String get tools_layerDelete => '刪除圖層';

  @override
  String get tools_currentLayer => '當前圖層';

  @override
  String get tools_hue => '色相';

  @override
  String get tools_saturation => '飽和度';

  @override
  String get tools_brightness => '亮度';

  @override
  String get tools_canvas => '畫布';

  @override
  String get tools_resizeCanvas => '更改尺寸';

  @override
  String get tools_inpaintNote => '應用後回到生圖頁，側欄切到“局部重繪”；也可以用右上角選單“應用並生成”直接開跑';

  @override
  String get tools_director => '導演工具';

  @override
  String get tools_backGen => '生圖';

  @override
  String get tools_dtGroupClean => '清理';

  @override
  String get tools_dtGroupLine => '線條';

  @override
  String get tools_dtGroupColor => '上色與表情';

  @override
  String get tools_dtGroupPixel => '像素';

  @override
  String get tools_dtRemoveBg => '背景移除';

  @override
  String get tools_dtRemoveBgDesc => '摳出人物，得到透明底、原背景、合成三張';

  @override
  String get tools_dtDeclutter => '雜線清理';

  @override
  String get tools_dtDeclutterDesc => '去掉多餘的線和噪點，畫面更乾淨';

  @override
  String get tools_dtLineArt => '線稿提取';

  @override
  String get tools_dtLineArtDesc => '提取乾淨的黑白線稿';

  @override
  String get tools_dtSketch => '草圖化';

  @override
  String get tools_dtSketchDesc => '變成鉛筆草圖的感覺';

  @override
  String get tools_dtColorize => '上色';

  @override
  String get tools_dtColorizeDesc => '給線稿或草圖上色，可寫提示詞';

  @override
  String get tools_dtEmotion => '表情修復';

  @override
  String get tools_dtEmotionDesc => '換表情，可調強度';

  @override
  String get tools_dtPixelSnap => '像素對齊';

  @override
  String get tools_dtPixelSnapDesc => '對齊像素網格、壓縮調色盤；本機處理';

  @override
  String get tools_dtOpusNote => 'Opus 訂閱 1 MP 以內這幾項不花 Anlas；背景移除始終計費';

  @override
  String get tools_input => '輸入';

  @override
  String get tools_compareSide => '並排';

  @override
  String get tools_compareWipe => '滑動對比';

  @override
  String get tools_compareResult => '只看結果';

  @override
  String get tools_fit => '適應';

  @override
  String get tools_actualSize => '原始大小 100%';

  @override
  String get tools_original => '原圖';

  @override
  String get tools_emptyRun => '按“執行”開始';

  @override
  String get tools_emptyEmotion => '選好表情後按“執行”';

  @override
  String get tools_emptyBody => '結果會出現在這裡，和原圖並排對比';

  @override
  String tools_running(Object tool) {
    return '正在執行$tool…';
  }

  @override
  String get tools_runningBody => '一般幾秒就好；結果也會進生圖頁的歷史';

  @override
  String get tools_runFailed => '執行失敗';

  @override
  String get tools_noInput => '先放一張圖進來';

  @override
  String get tools_noInputBody => '拖進來、Ctrl+V 貼上，或者從生圖歷史裡選';

  @override
  String get tools_noResult => '還沒有結果';

  @override
  String get tools_continue => '繼續處理';

  @override
  String get tools_copy => '複製';

  @override
  String get tools_saveGallery => '存到圖庫';

  @override
  String get tools_queue => '輸入佇列';

  @override
  String tools_queueCount(Object count) {
    return '$count 張';
  }

  @override
  String get tools_queueHint => '加號：匯入檔案 / 從生圖歷史選；也可以拖進來、Ctrl+V 貼上';

  @override
  String get tools_importFiles => '匯入檔案';

  @override
  String get tools_fromHistory => '從生圖歷史選';

  @override
  String get tools_paste => '貼上';

  @override
  String get tools_removeInput => '移出佇列';

  @override
  String get tools_dtOptions => '選項';

  @override
  String get tools_dtNoOptionsBg => '背景移除沒有可調的選項。會得到透明底、原背景、合成三張，在結果下面切換。';

  @override
  String get tools_dtNoOptionsDeclutter => '雜線清理沒有可調的選項。想要線稿用“線稿提取”。';

  @override
  String get tools_dtNoOptionsLineArt => '線稿提取沒有可調的選項。想要上色，把結果“繼續處理”再選“上色”。';

  @override
  String get tools_dtNoOptionsSketch =>
      '草圖化沒有可調的選項。想要更乾淨的線條用“線稿提取”，想要上色把結果“繼續處理”再選“上色”。';

  @override
  String get tools_dtEmotionLabel => '表情';

  @override
  String tools_dtEmotionMore(Object count) {
    return '更多 $count 個';
  }

  @override
  String get tools_dtEmotionLess => '收起';

  @override
  String get tools_dtStrength => '強度';

  @override
  String get tools_defry0 => '正常';

  @override
  String get tools_defry1 => '稍弱';

  @override
  String get tools_defry2 => '弱';

  @override
  String get tools_defry3 => '更弱';

  @override
  String get tools_defry4 => '很弱';

  @override
  String get tools_defry5 => '最弱';

  @override
  String get tools_dtEmotionStrengthHint => '越弱越接近原圖的表情';

  @override
  String get tools_dtColorizeStrengthHint => '越弱越接近原圖的線條';

  @override
  String get tools_dtPrompt => '補充提示詞';

  @override
  String get tools_dtPromptHint => '英文標籤，用逗號分開';

  @override
  String get tools_dtEmotionPromptHint => '選表情時會自動帶上常用標籤，可以改';

  @override
  String get tools_dtColorizePromptHint => '描述想要的配色，例如 blue dress, silver hair';

  @override
  String get tools_dtPalette => '調色盤';

  @override
  String get tools_dtPaletteOff => '關閉';

  @override
  String get tools_dtPaletteAuto => '自動';

  @override
  String get tools_dtPaletteCustom => '自訂';

  @override
  String get tools_dtColors => '顏色數';

  @override
  String get tools_dtAvoidRefine => '避免過度細化';

  @override
  String get tools_dtAvoidRefineHint => '網格細節變化大時保持粗網格';

  @override
  String get tools_dtPixelUpscale => '放大回原尺寸';

  @override
  String get tools_dtPixelUpscaleHint => '關掉時輸出每格一個像素的小圖';

  @override
  String tools_runTool(Object tool) {
    return '執行$tool';
  }

  @override
  String get tools_runHint => '執行 · 處理當前輸入';

  @override
  String get tools_runNeedInput => '先在下面放一張輸入';

  @override
  String get tools_results => '結果';

  @override
  String get tools_resultsEmpty => '跑過的結果會列在這裡';

  @override
  String get tools_resultsHint => '點一條結果再看；結果也會進生圖頁的歷史，要長期留的先存到圖庫';

  @override
  String get tools_reuse => '沿用設定';

  @override
  String get tools_emoNeutral => '平靜';

  @override
  String get tools_emoHappy => '開心';

  @override
  String get tools_emoSad => '難過';

  @override
  String get tools_emoAngry => '生氣';

  @override
  String get tools_emoScared => '害怕';

  @override
  String get tools_emoSurprised => '驚訝';

  @override
  String get tools_emoTired => '疲憊';

  @override
  String get tools_emoExcited => '興奮';

  @override
  String get tools_emoNervous => '緊張';

  @override
  String get tools_emoThinking => '思考';

  @override
  String get tools_emoConfused => '困惑';

  @override
  String get tools_emoShy => '害羞';

  @override
  String get tools_emoDisgusted => '嫌棄';

  @override
  String get tools_emoSmug => '得意';

  @override
  String get tools_emoBored => '無聊';

  @override
  String get tools_emoLaughing => '大笑';

  @override
  String get tools_emoIrritated => '煩躁';

  @override
  String get tools_emoAroused => '動情';

  @override
  String get tools_emoEmbarrassed => '尷尬';

  @override
  String get tools_emoWorried => '擔心';

  @override
  String get tools_emoLove => '愛慕';

  @override
  String get tools_emoDetermined => '堅定';

  @override
  String get tools_emoHurt => '受傷';

  @override
  String get tools_emoPlayful => '俏皮';

  @override
  String get auth_logoutConfirm => '確定退出當前帳號？';

  @override
  String get naiAgent_title => 'NAI Agent';

  @override
  String get naiAgent_permissionTitle => '需要審批';

  @override
  String get naiAgent_permissionOnce => '允許一次';

  @override
  String get naiAgent_permissionSession => '本會話允許相同呼叫';

  @override
  String get naiAgent_permissionDeny => '拒絕';

  @override
  String get naiAgent_defaultWorkspace => '工作區 1';

  @override
  String get naiAgent_newChat => '新聊天';

  @override
  String get naiAgent_settings => 'Agent 設定';

  @override
  String get naiAgent_chooseModel => '選擇模型';

  @override
  String get naiAgent_interrupted => '上次任務已中斷，未自動重發。';

  @override
  String get naiAgent_systemPrompt => '內建提示詞';

  @override
  String get naiAgent_promptHelp =>
      '自訂內容替換預設提示詞；工具地圖由應用追加。已有聊天記錄保持原樣，後續請求使用新內容。';

  @override
  String get naiAgent_restoreDefault => '恢復預設';

  @override
  String get naiAgent_showEffective => '檢視生效提示詞';

  @override
  String get naiAgent_useGlobal => '使用全域提示詞';

  @override
  String get naiAgent_save => '儲存';

  @override
  String get naiAgent_runLimit => '每次執行的模型請求上限';

  @override
  String get naiAgent_enterSends => 'Enter 傳送，Shift+Enter 換行';

  @override
  String get naiAgent_dataFolder => '工作區資料目錄';

  @override
  String get naiAgent_openFolder => '開啟資料夾';

  @override
  String get naiAgent_toolsManuals => '工具與 Skill';

  @override
  String get naiAgent_toolsHint =>
      '當前狀態、圖片、提示詞和工作區檔案按需呼叫；業務操作的詳細用法寫在 nai-studio、nai-prompt 等 Skill 裡，用到時才讀取。';

  @override
  String get naiAgent_unknownCost => '實際費用以服務商為準';

  @override
  String get naiAgent_error => '操作未完成，請檢查模型設定或工作區檔案。';

  @override
  String get naiAgent_visionCurrentProvider => '當前服務商';

  @override
  String naiAgent_visionModelUnsupported(String providerName) {
    return '服務商 $providerName 下的所選模型未宣告支援圖片輸入。請在 設定 → 模型與介面 → $providerName → 模型 → 能力 → 圖片輸入 確認支援，或切換到支援圖片輸入的模型。';
  }

  @override
  String naiAgent_visionAttachmentsSkipped(int count, String reason) {
    return '本次有 $count 張圖片附件沒有發給模型，文字仍照常傳送。$reason';
  }

  @override
  String get naiAgent_inputChanged => '準備期間輸入已改變，請傳送當前草稿。';

  @override
  String get naiAgent_imageLimit => '圖片格式無效、檔案過大或超出上傳限制。';

  @override
  String get naiAgent_composerNotEmpty => '請先儲存或傳送當前輸入，再恢復這條訊息。';

  @override
  String get naiAgent_runtimeMissing => 'Agent 執行元件尚未安裝，請使用完整更新包。';

  @override
  String get naiAgent_usage => '模型用量';

  @override
  String get naiAgent_globalScope => '全域預設';

  @override
  String get naiAgent_workspaceScope => '當前工作區';

  @override
  String naiAgent_generationLocalEnhance(Object model, Object scale) {
    return '生成後本地超分：$model ×$scale';
  }

  @override
  String naiAgent_galleryDeleteEmptyFolderConfirm(String path) {
    return '刪除這個空資料夾及其圖庫分類？其他資料夾中的圖片會保留。\n$path';
  }

  @override
  String naiAgent_galleryDeleteEmptyFoldersConfirm(int count, String paths) {
    return '刪除這 $count 個空資料夾及其圖庫分類？其他資料夾中的圖片會保留。\n$paths';
  }

  @override
  String naiAgent_galleryMoreItems(int count) {
    return '……另有 $count 項';
  }

  @override
  String get naiAgent_extensions => '擴展';

  @override
  String get naiAgent_interactionExtension => 'Studio 互動';

  @override
  String get naiAgent_extensionRequired => '內建 · 必需';

  @override
  String get naiAgent_interactionExtensionHint =>
      '按需讀取當前 Studio 狀態，並通過問題卡片收集使用者回答。';

  @override
  String get naiAgent_extensionAddFile => '新增擴展檔案';

  @override
  String get naiAgent_extensionAddFolder => '新增擴展目錄';

  @override
  String get naiAgent_extensionsHint =>
      '擴展在各工作區獨立載入。更改會在當前任務結束後的下一次傳送生效。外部擴展能執行原生代碼，請選擇可信來源。';

  @override
  String get naiAgent_extensionError => '擴展執行失敗';

  @override
  String get naiAgent_extensionCompatibility =>
      '支援本地 Pi 擴展及擴展包目錄、工具、命令和標準提問對話方塊；終端專用自訂介面不在桌面渲染。';

  @override
  String get naiAgent_instructions => '指令';

  @override
  String get naiAgent_globalInstructions => '全域指令';

  @override
  String get naiAgent_globalInstructionsHelp =>
      '所有工作區都會使用，可填寫語言、風格或任務偏好。留空即可停用這一部分。';

  @override
  String get naiAgent_systemPromptPrefix => '系統提示詞前置內容';

  @override
  String get naiAgent_systemPromptPrefixHelp =>
      '插在 NAI Agent 基礎提示詞之前，保留基礎提示詞和工具地圖。留空即可停用這一部分。';

  @override
  String get naiAgent_instructionOrder =>
      '生效順序：前置內容 → 基礎提示詞 → 全域指令 → 工作區規則。僅影響後續請求。';

  @override
  String get naiAgent_saveInstructions => '儲存指令';

  @override
  String get naiAgent_mcpBuiltin => 'NAI Studio · 內建工具組';

  @override
  String get naiAgent_mcpBuiltinHint =>
      '提示詞、積木、百科、圖片、歷史、參考圖、生圖和設定工具。預設按需發現，原有備份、版本校驗和真實確認繼續生效。';

  @override
  String get naiAgent_mcpAdd => '新增 MCP 伺服器';

  @override
  String get naiAgent_mcpName => '伺服器名稱';

  @override
  String get naiAgent_mcpConfig => '伺服器配置（JSON）';

  @override
  String get naiAgent_mcpConfigHint =>
      '支援 stdio 和 Streamable HTTP。貼上單個伺服器配置物件；command 為執行檔，args 為陣列。可設定 env、cwd、url、headers、oauth 和 toolExposure。配置儲存在加密儲存中。';

  @override
  String get naiAgent_mcpStatus => '檢視連線狀態';

  @override
  String get naiAgent_mcpReconnect => '重新連線';

  @override
  String get naiAgent_mcpLogin => '登入';

  @override
  String get naiAgent_mcpLogout => '登出';

  @override
  String get naiAgent_mcpHint =>
      '預設使用 CodeMode 按需發現。codemode：沙盒呼叫；deferred：搜尋後直接呼叫；direct：常駐；hidden：隱藏。配置變更在下一次空閒呼叫時生效。連線檢查不會呼叫聊天模型。';

  @override
  String get promptBlockLibrary_title => '提示詞塊';

  @override
  String get gen_oldImageLabel => 'OLD';

  @override
  String get gen_compareOriginal => '按住檢視原圖與局部重繪範圍';

  @override
  String get naiAgent_imageTooLarge => '圖片超過 64 MiB 或 6400 萬像素。';

  @override
  String get naiAgent_linkOnlyImage => '當前來源只提供連結，請儲存圖片檔案後拖入。';

  @override
  String get naiAgent_invalidImage => '無法讀取圖片，請使用 PNG、JPEG、WebP、GIF 或 BMP 檔案。';

  @override
  String naiAgent_importResult(int added, int failed) {
    return '已新增 $added 張圖片，$failed 張失敗。';
  }

  @override
  String get channel_themeCircuit => '像素電路';

  @override
  String get channel_themeStars => '星圖';

  @override
  String get channel_themeHerb => '植物標本';

  @override
  String get channel_themeArcade => '迴廊';

  @override
  String get channel_themeAbyss => '深海';

  @override
  String get channel_themeWave => '青海波';

  @override
  String get channel_descCircuit => '兩側各兩條匯流排一路往下，分支、焊盤、晶片；空閒時有光點沿匯流排流動';

  @override
  String get channel_descStars => '星點、星座連線、刻度環和赤緯尺；亮星空閒時輕微閃爍';

  @override
  String get channel_descHerb => '墨線標本從兩側長出，葉片、花頭、膠帶和編號標籤；空閒時隨風輕擺';

  @override
  String get channel_descArcade => '俯視的教堂平面圖：圖片走在中殿裡，兩側是立柱、肋拱、牆窗、軸號和尺寸線';

  @override
  String get channel_descAbyss => '越往下越深（越舊）：深度尺、等深線、上浮的氣泡和飄落的海雪';

  @override
  String get channel_descWave => '和風波紋在兩側聚散，配一輪朱日和幾道霞；空閒時有光沿波紋掃過';

  @override
  String get channel_themeCaliber => '機芯';

  @override
  String get channel_themeStrata => '地層';

  @override
  String get channel_themeMetro => '地鐵';

  @override
  String get channel_themeScore => '樂譜';

  @override
  String get channel_themeLuna => '月相';

  @override
  String get channel_descCaliber =>
      '夾板、日內瓦紋和齒輪串；滾動時齒輪按真實傳動比齧合轉動，每段一組擺輪遊絲，空閒時滴答走動';

  @override
  String get channel_descStrata => '越往下越古老：左側地質年代柱，兩側岩層和對應年代的化石；鑽頭跟著視口一路鑽下去';

  @override
  String get channel_descMetro =>
      '兩側是地鐵線路圖：45° 轉彎、換乘站和站名；列車停在視口旁並點亮最近一站，另兩條線空閒時自己跑';

  @override
  String get channel_descScore => '豎排五線譜一路往下，播放線停在視口中間，經過的音符會亮起；每段一張隨滾動轉動的唱片';

  @override
  String get channel_descLuna => '左側一天一格的月相歷，右側潮汐曲線；一輪大月亮跟著視口走，滾動時盈虧隨之變化';

  @override
  String get channel_title => '視覺通道';

  @override
  String get channel_subtitle => '滾動時兩側的裝飾，只畫在圖片之外，不擋圖';

  @override
  String get channel_paused => '生成中 · 動畫已暫停';

  @override
  String get channel_modeOff => '關閉';

  @override
  String get channel_modeFixed => '固定一個';

  @override
  String get channel_modeRandom => '每次隨機';

  @override
  String get channel_session => '本次';

  @override
  String get channel_reroll => '換一組';

  @override
  String get channel_offNote => '關閉後保留現在的像素底紋';

  @override
  String get channel_minTwo => '隨機至少保留兩個主題';

  @override
  String get channel_level => '濃淡';

  @override
  String get channel_levelSoft => '淡';

  @override
  String get channel_levelStandard => '標準';

  @override
  String get channel_levelStrong => '濃';

  @override
  String get channel_ruler => '時間刻度';

  @override
  String get channel_rulerSub => '批次時間、日期分隔和右側刻度條';

  @override
  String get channel_motion => '空閒微動';

  @override
  String get channel_motionSub => '很輕的動效，生成時自動暫停';

  @override
  String get channel_toastTitle => '本次通道';

  @override
  String channel_batch(String time, int count) {
    return '$time · $count 張';
  }

  @override
  String channel_batchNewest(String time, int count) {
    return '$time · $count 張 · 最新';
  }

  @override
  String channel_batchPending(int count) {
    return '生成中 · $count 張';
  }

  @override
  String channel_dayToday(String date) {
    return '今天 · $date';
  }

  @override
  String channel_dayYesterday(String date) {
    return '昨天 · $date';
  }

  @override
  String channel_monthDayWeek(int month, int day, String weekday) {
    return '$month月$day日 $weekday';
  }

  @override
  String get channel_weekday1 => '週一';

  @override
  String get channel_weekday2 => '週二';

  @override
  String get channel_weekday3 => '週三';

  @override
  String get channel_weekday4 => '週四';

  @override
  String get channel_weekday5 => '週五';

  @override
  String get channel_weekday6 => '週六';

  @override
  String get channel_weekday7 => '週日';

  @override
  String channel_scrubWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get rag_title => 'RAG 向量系統';

  @override
  String get rag_description => '管理本地語義檢索、模型與標籤上下文推薦';

  @override
  String get rag_enabled => '啟用 RAG';

  @override
  String get rag_enabledHint => '開啟本地語義檢索服務；首次建庫需預覽範圍後手動開始。';

  @override
  String get rag_status => '統一向量池';

  @override
  String get rag_off => '未啟用';

  @override
  String get rag_loading => '正在準備本地模型';

  @override
  String get rag_empty => '模型已連線，等待建立索引';

  @override
  String get rag_ready => '語義檢索已就緒';

  @override
  String get rag_partial => '部分就緒，未覆蓋內容保留普通搜尋';

  @override
  String get rag_building => '正在建立索引';

  @override
  String get rag_paused => '建庫已暫停，已有索引仍可查詢';

  @override
  String get rag_unavailable => 'RAG 暫不可用，保留普通搜尋';

  @override
  String get rag_operationFailed => '操作未完成，請檢查模型路徑與獨立執行環境';

  @override
  String rag_indexCounts(int indexed, int total) {
    return '已索引 $indexed / $total 項';
  }

  @override
  String rag_storage(String size) {
    return '索引佔用 $size MiB';
  }

  @override
  String get rag_refresh => '重新整理狀態';

  @override
  String get rag_embeddingPath => 'EmbeddingGemma 2 權重目錄';

  @override
  String get rag_rerankerPath => 'Qwen3-Reranker-0.6B 權重目錄';

  @override
  String get rag_notConfigured => '尚未配置';

  @override
  String get rag_choose => '選擇';

  @override
  String get rag_modelMode => '模型能力';

  @override
  String get rag_modelModeHint => 'Gemma 用於文字與圖片，音訊關閉；Qwen 僅用於文字重排。';

  @override
  String get rag_discover => '檢測本地權重';

  @override
  String get rag_modelsMissing => '未找到模型，請選擇已下載的權重目錄';

  @override
  String get rag_pythonPath => '獨立 Python 執行環境';

  @override
  String get rag_runtime => '推理執行環境';

  @override
  String get rag_runtimeHint => '使用專用環境，不修改現有放大元件。模型權重需單獨選擇。';

  @override
  String get rag_installRuntime => '安裝獨立執行環境';

  @override
  String get rag_installHint =>
      '下載 Python 與推理依賴。CUDA 版本約需數 GB 下載空間，適用於相容的 NVIDIA 顯示卡；CPU 版本下載較小。不會下載模型權重。';

  @override
  String get rag_installing => '正在安裝執行環境';

  @override
  String get rag_device => '執行裝置';

  @override
  String get rag_auto => '自動選擇';

  @override
  String get rag_tagsEnabled => '標籤上下文推薦';

  @override
  String get rag_tagsHint => '結合語義、共現與文字重排；各框、角色和正負面獨立。';

  @override
  String get rag_context => '推薦上下文範圍';

  @override
  String get rag_contextHint => '兩種模式均最多 120 個 Gemma tokens，按完整標籤取樣；全文僅用於去重。';

  @override
  String get rag_contextBefore => '游標前 · 120 tokens';

  @override
  String get rag_contextAround => '插入點前後 · 120 tokens';

  @override
  String get rag_buildIndex => '預覽並建立索引';

  @override
  String rag_plan(int total) {
    return '將收錄當前標籤目錄的 $total 項標籤、別名與已有本地釋義。首次處理可能較久；可暫停，已完成部分可提前使用。';
  }

  @override
  String get rag_start => '開始建立';

  @override
  String get rag_pause => '暫停建庫';

  @override
  String get rag_resume => '繼續建庫';

  @override
  String get rag_rebuild => '重建索引';

  @override
  String get rag_clear => '清除索引';

  @override
  String get rag_clearHint => '僅刪除此來源的派生索引，保留原始內容與模型；重新增庫後可繼續使用。';

  @override
  String get rag_futureSources =>
      '已接入標籤推薦、Wiki、提示詞塊與圖庫多模態檢索；工作區與 Agent 檢索後續接入。';

  @override
  String get rag_badgeHint => '本地語義檢索已就緒';

  @override
  String get rag_wikiEnabled => 'Wiki 語義搜尋';

  @override
  String get rag_wikiHint => '收錄本地百科正文，名稱精確匹配優先，語義結果補充。單獨預覽並開始首次建庫。';

  @override
  String get rag_blocksEnabled => '提示詞塊語義搜尋';

  @override
  String get rag_blocksHint => '僅收錄已儲存、未歸檔塊的標題、標籤與正負面文字；不收錄圖片或編輯草稿。';

  @override
  String rag_textPlan(int documents, int total) {
    return '將收錄 $documents 份已儲存資料，切分為 $total 個文字片段。首次建庫需手動開始，之後增量更新；可暫停，已完成部分可檢索。';
  }

  @override
  String rag_textCounts(int indexed, int total) {
    return '已索引 $indexed / $total 個文字片段';
  }

  @override
  String get rag_galleryEnabled => '圖庫多模態檢索';

  @override
  String get rag_galleryHint =>
      '分析已登記圖庫中的圖片畫面；僅為 NAI 圖的已有參數另建文字索引。原圖不改寫，普通圖不解析其他軟體後設資料。';

  @override
  String rag_galleryPlan(int images, int parameters) {
    return '當前圖庫來源將收錄 $images 張未刪除圖片及 $parameters 個 NAI 參數片段。首次需點選開始，之後增量更新；畫面與參數分開索引，可隨時暫停。';
  }

  @override
  String rag_galleryCounts(
    int indexed,
    int images,
    int parameters,
    int skipped,
  ) {
    return '畫面 $indexed / $images 張；NAI 參數 $parameters 段；跳過 $skipped 張';
  }

  @override
  String get rag_galleryMixed => '綜合檢索';

  @override
  String get rag_galleryVisual => '僅畫面';

  @override
  String get rag_galleryParameters => '僅 NAI 參數';

  @override
  String get rag_galleryChooseImage => '選擇圖片找相似';

  @override
  String get rag_galleryClearImage => '清除查詢圖片';

  @override
  String get rag_gallerySearchOptions => '圖庫 RAG 檢索方式';

  @override
  String get rag_downloadModel => '下載模型';

  @override
  String get rag_modelDownloading => '正在下載模型';

  @override
  String get rag_modelVerifying => '正在校驗模型';

  @override
  String rag_downloadProgress(String done, String total) {
    return '$done / $total MB';
  }

  @override
  String get rag_poolHint => '所有已啟用來源共用一個向量池，新增資料與翻譯自動增量更新。';

  @override
  String get rag_runtimeReady => '執行環境已就緒';

  @override
  String get rag_runtimeCheck => '檢測執行環境';

  @override
  String get rag_runtimeExisting => '正在檢測已有環境';

  @override
  String get rag_runtimeDownload => '正在下載環境安裝工具';

  @override
  String get rag_runtimeCreate => '正在準備 Python 環境';

  @override
  String get rag_runtimeCuda => '正在安裝 CUDA 推理元件';

  @override
  String get rag_runtimePackages => '正在安裝推理依賴';

  @override
  String get rag_runtimeVerify => '正在校驗環境相容性';

  @override
  String rag_runtimeElapsed(int seconds) {
    return '此階段已用 $seconds 秒';
  }

  @override
  String get rag_useRuntime => '使用已有環境';

  @override
  String get set_title => '設定';

  @override
  String get set_search => '搜尋設定';

  @override
  String get set_searchResults => '搜尋結果';

  @override
  String set_searchCount(Object count) {
    return '$count 項';
  }

  @override
  String get set_searchHint => '結果裡的開關和數值可以直接改；點右側箭頭跳到所在頁面並高亮這一行。';

  @override
  String get set_searchKeys => '選擇';

  @override
  String get set_searchJump => '跳轉';

  @override
  String set_searchEmpty(Object query) {
    return '沒有找到“$query”';
  }

  @override
  String get set_searchEmptyHint => '試試“代理”“儲存”“快速鍵”或某個路徑';

  @override
  String get set_goTo => '跳到設定';

  @override
  String get set_hasUpdate => '有更新';

  @override
  String get set_groupPersonal => '個人';

  @override
  String get set_groupCreate => '創作';

  @override
  String get set_groupIntelligence => '智慧';

  @override
  String get set_groupConnect => '連線';

  @override
  String get set_groupSystem => '系統';

  @override
  String get set_pageOverview => '概覽';

  @override
  String get set_pageAccount => '帳號';

  @override
  String get set_pageAppearance => '外觀';

  @override
  String get set_pageCanvas => '畫布與瀏覽';

  @override
  String get set_pageShortcuts => '快速鍵';

  @override
  String get set_pageGeneration => '生成與額度';

  @override
  String get set_pageStorage => '儲存與圖庫';

  @override
  String get set_pageDictionaries => '詞庫與快取';

  @override
  String get set_pageModels => '模型與介面';

  @override
  String get set_pageAgent => 'NAI Agent';

  @override
  String get set_pageRag => '語義檢索';

  @override
  String get set_pageUpscale => '本地放大';

  @override
  String get set_pageBridges => '橋接與整合';

  @override
  String get set_pageNetwork => '網路與代理';

  @override
  String get set_pagePrivacy => '隱私與保護';

  @override
  String get set_pageBackup => '備份與重設';

  @override
  String get set_pageAbout => '關於';

  @override
  String get set_resetDefault => '恢復預設';

  @override
  String get set_resetPage => '恢復本頁預設';

  @override
  String get set_needsRestart => '需重啟';

  @override
  String get set_defaultTag => '預設';

  @override
  String get set_readOnly => '只讀';

  @override
  String get set_cancel => '取消';

  @override
  String get set_save => '儲存';

  @override
  String get set_discard => '放棄';

  @override
  String get set_later => '稍後';

  @override
  String get set_undo => '復原';

  @override
  String get set_open => '開啟';

  @override
  String get set_choose => '選擇';

  @override
  String get set_change => '更改';

  @override
  String get set_clear => '清除';

  @override
  String get set_delete => '刪除';

  @override
  String get set_copy => '複製';

  @override
  String get set_more => '更多';

  @override
  String get set_refresh => '重新整理';

  @override
  String get set_retry => '重試';

  @override
  String get set_test => '測試連線';

  @override
  String get set_testing => '檢測中…';

  @override
  String get set_importIt => '匯入';

  @override
  String get set_exportIt => '匯出';

  @override
  String get set_install => '安裝';

  @override
  String get set_download => '下載';

  @override
  String get set_resume => '繼續';

  @override
  String get set_pause => '暫停';

  @override
  String get set_rebuild => '重建';

  @override
  String get set_login => '登入';

  @override
  String get set_adjust => '調整';

  @override
  String get set_collapse => '收起';

  @override
  String get set_notSet => '未設定';

  @override
  String get set_defaultLocation => '預設位置';

  @override
  String get set_builtinSound => '內建音效';

  @override
  String get set_justNow => '剛剛';

  @override
  String set_minutesAgo(Object n) {
    return '$n 分鐘前';
  }

  @override
  String set_todayAt(Object time) {
    return '今天 $time';
  }

  @override
  String get set_yesterday => '昨天';

  @override
  String set_secondsAgo(Object n) {
    return '$n 秒前';
  }

  @override
  String set_savedChange(Object title, Object from, Object to) {
    return '已儲存 · $title $from → $to';
  }

  @override
  String get set_restartBanner => '設定已儲存，重啟 Studio 後生效。正在進行的生成不受影響。';

  @override
  String get set_restartNow => '立即重啟';

  @override
  String get set_unsavedInstructions => '全域指令有未儲存的修改';

  @override
  String get set_leaveTitle => '放棄未儲存的修改？';

  @override
  String get set_leaveBody => 'Agent 指令還沒儲存，離開這一頁會丟掉修改。';

  @override
  String set_resetPageTitle(Object page) {
    return '把“$page”恢復預設？';
  }

  @override
  String set_resetPageBody(Object count) {
    return '這一頁改過的 $count 項會回到預設值，可以在概覽裡復原。';
  }

  @override
  String get set_ovDesc => '帳號、儲存、連線和智慧服務的狀態都在這裡。需要處理的事項排在最前，點卡片直接進入對應設定。';

  @override
  String get set_ovSwitchAccount => '切換帳號';

  @override
  String get set_ovTodayUsed => '今天已用';

  @override
  String set_ovMonthly(Object n) {
    return '本月固定額度 $n';
  }

  @override
  String set_ovWarnAt(Object n) {
    return '高消耗提醒 ≥ $n Anlas';
  }

  @override
  String get set_ovWarnOff => '高消耗提醒已關閉';

  @override
  String set_ovRenews(Object date) {
    return '訂閱續期 $date';
  }

  @override
  String get set_ovSignedOut => '未登入';

  @override
  String get set_ovAttention => '需要處理';

  @override
  String get set_ovAllClear => '一切正常';

  @override
  String set_attUpdate(Object version) {
    return '有新版本 $version';
  }

  @override
  String set_attRagPaused(Object source) {
    return '$source語義索引已暫停';
  }

  @override
  String set_attRagPausedSub(Object done, Object total) {
    return '已完成 $done / $total，已有部分可檢索';
  }

  @override
  String set_attBridgeDown(Object name) {
    return '$name 地址無回應';
  }

  @override
  String set_attCheckedAt(Object detail, Object when) {
    return '$detail · $when檢測';
  }

  @override
  String set_attCredential(Object name) {
    return '帳號“$name”憑據已過期';
  }

  @override
  String get set_attCredentialSub => '更新後才能切換到這個帳號';

  @override
  String set_attDiskLow(Object disk) {
    return '$disk 盤空間不足';
  }

  @override
  String set_attDiskLowSub(Object size) {
    return '剩餘 $size，自動儲存可能失敗';
  }

  @override
  String set_attProvider(Object name) {
    return '$name 連線失敗';
  }

  @override
  String get set_attProviderSub => '翻譯和反推會回落到其他服務商';

  @override
  String get set_attView => '檢視';

  @override
  String get set_attGo => '去看看';

  @override
  String get set_attUpdateCred => '更新憑據';

  @override
  String get set_tileStorage => '儲存';

  @override
  String set_tileImages(Object n) {
    return '圖庫 $n 張';
  }

  @override
  String set_tileSaveTo(Object path) {
    return '儲存到 $path';
  }

  @override
  String get set_tileConnect => '連線';

  @override
  String set_tileOnline(Object n) {
    return '$n 項線上';
  }

  @override
  String get set_tileKrita => 'Krita 已連線';

  @override
  String get set_tileKritaOff => 'Krita 未連線';

  @override
  String set_tileAgents(Object n) {
    return '外部 Agent $n 個';
  }

  @override
  String get set_tileComfyDown => 'ComfyUI 無回應';

  @override
  String get set_tileComfyOk => 'ComfyUI 正常';

  @override
  String get set_tileComfyOff => 'ComfyUI 未啟用';

  @override
  String get set_tileModels => '模型與介面';

  @override
  String set_tileTranslateVia(Object ms) {
    return '提示詞翻譯 · $ms';
  }

  @override
  String set_tileAgentModel(Object model) {
    return 'Agent · $model';
  }

  @override
  String set_tileProviders(Object p, Object m) {
    return '$p 個服務商 · $m 個模型';
  }

  @override
  String get set_tileNoModel => '未配置';

  @override
  String get set_tileRag => '語義檢索';

  @override
  String get set_tileReady => '就緒';

  @override
  String set_tileRagDone(Object names) {
    return '$names已完成';
  }

  @override
  String set_tileRagPaused(Object name, Object pct) {
    return '$name $pct · 已暫停';
  }

  @override
  String set_tileRagBuilding(Object name, Object pct) {
    return '$name $pct · 建庫中';
  }

  @override
  String set_tileRagEmpty(Object name) {
    return '$name還沒建庫';
  }

  @override
  String set_tileRagError(Object name) {
    return '$name建庫出錯';
  }

  @override
  String get set_tileUpscale => '本地放大';

  @override
  String set_tileUpscaleModels(Object n) {
    return '$n 個模型可用';
  }

  @override
  String set_tileDefaultIs(Object name) {
    return '$name（預設）';
  }

  @override
  String get set_tileSeedMissing => 'SeedVR2 未安裝';

  @override
  String get set_tileSeedReady => 'SeedVR2 已安裝';

  @override
  String get set_tileProtect => '保護';

  @override
  String set_tileProtectOn(Object on, Object all) {
    return '$on / $all 已開啟';
  }

  @override
  String set_tileInterval(Object s, Object p) {
    return '生成間隔 $s 秒 ± $p%';
  }

  @override
  String get set_tileIntervalOff => '不限制生成間隔';

  @override
  String get set_recent => '最近修改';

  @override
  String get set_recentSub => '自動儲存 · 可復原';

  @override
  String get set_recentEmpty => '還沒有修改';

  @override
  String get set_quick => '常用開關';

  @override
  String get set_quickSub => '在這裡直接改';

  @override
  String get set_quickDark => '深色模式';

  @override
  String get set_quickChannel => '畫布視覺通道';

  @override
  String set_searchTip(Object keys) {
    return '按 $keys 搜尋任何設定；結果裡可以直接開關，不用跳頁。';
  }

  @override
  String get set_accDesc => '管理 NovelAI 帳號、預設登入和訂閱額度。';

  @override
  String get set_accSaved => '已儲存帳號';

  @override
  String get set_accSavedSub => '新增後可以在這裡一鍵切換；憑據儲存在本機，不會出現在匯出的偏好檔案裡。';

  @override
  String get set_accCurrent => '當前';

  @override
  String get set_accInUse => '使用中';

  @override
  String get set_accSwitch => '切換';

  @override
  String get set_accEmail => '電子郵件登入';

  @override
  String get set_accToken => '令牌登入';

  @override
  String set_accRenews(Object date) {
    return '訂閱續期 $date';
  }

  @override
  String set_accLastUsed(Object date) {
    return '上次使用 $date';
  }

  @override
  String get set_accNoSub => '無訂閱';

  @override
  String get set_accExpired => '憑據已過期';

  @override
  String get set_accEdit => '編輯資料';

  @override
  String get set_accUpdate => '更新憑據';

  @override
  String get set_accMakeDefault => '設為預設帳號';

  @override
  String get set_accDelete => '刪除帳號';

  @override
  String set_accDeleteTitle(Object name) {
    return '刪除帳號“$name”？';
  }

  @override
  String get set_accDeleteBody => '只刪除本機儲存的憑據，NovelAI 上的帳號和圖片不受影響。';

  @override
  String get set_accAdd => '新增帳號';

  @override
  String get set_accAddHint => '支援電子郵件密碼或持久令牌';

  @override
  String get set_accLogin => '登入';

  @override
  String get set_accDefault => '預設帳號';

  @override
  String get set_accDefaultSub => '登入頁預先選中的帳號';

  @override
  String get set_accAutoLogin => '啟動時自動登入';

  @override
  String get set_accAutoLoginSub => '使用上次的會話；關掉後每次開啟都停在登入頁';

  @override
  String get set_accSub => '訂閱';

  @override
  String set_accMonthly(Object n) {
    return '每月 $n Anlas';
  }

  @override
  String set_accRemaining(Object n) {
    return '剩餘 $n';
  }

  @override
  String set_accResets(Object date) {
    return '$date 重設';
  }

  @override
  String get set_accPortal => '開啟 NovelAI 帳戶頁';

  @override
  String get set_accSwitchHint => '切換帳號會保留當前草稿和畫布；生成佇列中的任務按原帳號完成。';

  @override
  String get set_apDesc => '主題、文字和提醒方式。所有修改即時儲存，可以復原。';

  @override
  String get set_apTheme => '主題';

  @override
  String get set_apThemeSub => '啟動頁、登入頁和所有工作頁面使用同一套主題。';

  @override
  String get set_apLight => '淺色';

  @override
  String get set_apDark => '深色';

  @override
  String get set_apSystem => '跟隨系統';

  @override
  String get set_apSystemSub => '按 Windows 設定自動切換';

  @override
  String get set_apText => '文字';

  @override
  String get set_apFont => '介面字型';

  @override
  String get set_apFontSub => '中文用 HarmonyOS Sans SC，數字與程式碼用 Geist Mono';

  @override
  String get set_apScale => '設定與對話方塊字號';

  @override
  String get set_apScaleSub => '只放大設定頁和彈窗，不影響畫布和圖片';

  @override
  String get set_apSampleTitle => '標題 · 生成完成';

  @override
  String get set_apSampleBody => '正文 · 結果已儲存到本地畫廊，可以繼續調整提示詞。';

  @override
  String get set_apSampleNote => '說明 · 拖動上面的滑塊，這裡即時預覽。';

  @override
  String get set_apLanguage => '語言';

  @override
  String get set_apLanguageSub => '切換後立即生效，無需重啟';

  @override
  String get set_apMotion => '動效與聲音';

  @override
  String get set_apReduceMotion => '減少動態效果';

  @override
  String get set_apReduceMotionSub => '關閉畫布飛行、縮放和麵板過渡動畫；視覺通道也會停止微動';

  @override
  String get set_apSound => '生成完成音效';

  @override
  String get set_apSoundSub => '一批圖片全部完成後播放';

  @override
  String get set_apSoundFile => '完成音效檔案';

  @override
  String get set_apPreviewSound => '試聽';

  @override
  String get set_apNotify => '通知樣式';

  @override
  String get set_apNotifySub => '提示從視窗右上角出現，3 秒後自動消失';

  @override
  String get set_apNotifyPreview => '預覽一條';

  @override
  String get set_apPreview => '預覽';

  @override
  String get set_apCurrent => '當前';

  @override
  String set_apThemeTip(Object keys) {
    return '快速鍵 $keys 可以隨時切換深淺色。';
  }

  @override
  String get set_cvDesc => '歷史、檢視器和無限畫布的行為。';

  @override
  String get set_cvBrowse => '瀏覽';

  @override
  String get set_cvHistoryClick => '點選歷史縮圖時';

  @override
  String get set_cvOpenDetail => '開啟詳情';

  @override
  String get set_cvOpenDetailSub => '彈出大圖檢視器，適合逐張細看';

  @override
  String get set_cvLinked => '聯動預覽';

  @override
  String get set_cvLinkedSub => '畫布跳到這張並選中，檢視器不彈出';

  @override
  String get set_cvViewer => '生成結果顯示在';

  @override
  String get set_cvCanvas => '無限畫布';

  @override
  String get set_cvCanvasSub => '按批次排成一列，可以平移、縮放、釘住對比';

  @override
  String get set_cvSimple => '簡潔檢視器';

  @override
  String get set_cvSimpleSub => '只顯示最新一張，最省資源';

  @override
  String get set_cvCanvasSec => '畫布';

  @override
  String get set_cvLock => '鎖定畫布視角';

  @override
  String get set_cvLockSub => '新圖出現時不自動飛過去，視角保持在你停下的位置';

  @override
  String get set_cvFill => '新圖縮放到填滿';

  @override
  String get set_cvFillSub => '聚焦單張時放大到可視區域，而不是按原始像素';

  @override
  String get set_cvChannel => '視覺通道';

  @override
  String get set_cvChannelSub => '畫布中間留空的長廊，按主題繪製裝飾，翻歷史時會依次經過各個主題。';

  @override
  String get set_cvMode => '模式';

  @override
  String get set_cvMinTwo => '隨機時至少保留兩個主題。';

  @override
  String set_cvSession(Object order) {
    return '本次順序：$order';
  }

  @override
  String get set_cvLevel => '濃淡';

  @override
  String get set_cvRuler => '時間刻度';

  @override
  String get set_cvRulerSub => '批次時間、日期分隔和右側刻度條';

  @override
  String get set_cvMotion => '空閒微動';

  @override
  String get set_cvMotionSub => '生成中和開啟“減少動態效果”時自動暫停';

  @override
  String get set_cvOps => '畫布操作';

  @override
  String get set_cvOpScroll => '上下翻';

  @override
  String get set_cvOpPan => '左右平移';

  @override
  String get set_cvOpZoom => '縮放';

  @override
  String get set_cvOpMove => '移動視角';

  @override
  String get set_cvOpAll => '看全域';

  @override
  String get set_cvOpHome => '回到最新一批';

  @override
  String get set_cvWheel => '滾輪';

  @override
  String get set_cvChannelTip => '畫布右下角的齒輪裡也能改視覺通道，兩處是同一份設定。';

  @override
  String get set_scDesc => '按頁面分組。點快速鍵直接錄製新組合；同一頁面裡重複時會標紅，並給出一鍵修復。';

  @override
  String get set_scSearch => '搜尋動作或按鍵，例如 Ctrl+S';

  @override
  String get set_scAll => '全部';

  @override
  String get set_scKeyboard => '鍵盤佈局';

  @override
  String get set_scKeyboardSub => '點按鍵篩選下面的列表；藍色是已佔用，紅色是衝突。';

  @override
  String get set_scNoMod => '無修飾';

  @override
  String set_scLayer(Object context, Object mod) {
    return '$context · 按住 $mod 時';
  }

  @override
  String set_scLayerNone(Object context) {
    return '$context · 不按修飾鍵';
  }

  @override
  String get set_scAction => '動作';

  @override
  String get set_scKeys => '快速鍵';

  @override
  String get set_scDefault => '預設';

  @override
  String set_scDefaultIs(Object keys) {
    return '預設 $keys';
  }

  @override
  String set_scConflict(Object name) {
    return '與“$name”衝突';
  }

  @override
  String get set_scRecording => '按下新的組合鍵…';

  @override
  String get set_scRecordHint => 'Esc 取消 · Backspace 清除';

  @override
  String get set_scRecord => '錄製新組合';

  @override
  String get set_scClear => '清除快速鍵';

  @override
  String get set_scDisplay => '顯示';

  @override
  String get set_scEnabled => '啟用快速鍵';

  @override
  String get set_scInTooltips => '在懸停提示中顯示';

  @override
  String get set_scInMenus => '在選單中顯示';

  @override
  String get set_scBadges => '導航上顯示數字標識';

  @override
  String get set_scConflicts => '衝突';

  @override
  String set_scConflictCount(Object n) {
    return '$n 項';
  }

  @override
  String set_scConflictLine(Object keys) {
    return '$keys 被兩個動作佔用';
  }

  @override
  String set_scConflictSub(Object context, Object a, Object b) {
    return '$context：$a、$b。衝突時兩個都不觸發。';
  }

  @override
  String set_scFix(Object name, Object keys) {
    return '恢復$name為 $keys';
  }

  @override
  String get set_scNoConflict => '沒有衝突';

  @override
  String get set_scConfig => '快速鍵配置';

  @override
  String get set_scResetAll => '全部恢復預設';

  @override
  String get set_scResetAllTitle => '把全部快速鍵恢復預設？';

  @override
  String set_scResetAllBody(Object n) {
    return '$n 個自訂的組合會被還原。';
  }

  @override
  String get set_scHelp => '快速鍵幫助';

  @override
  String set_scHelpTip(Object key) {
    return '按 $key 在任何頁面檢視當前頁可用的快速鍵。';
  }

  @override
  String get set_scEmpty => '沒有匹配的快速鍵';

  @override
  String get set_gnDesc => '控制 Anlas 消耗和請求節奏，以及寫提示詞時的輸入輔助。';

  @override
  String get set_gnCost => '額度保護';

  @override
  String get set_gnCostSub => '單次請求的消耗超過閾值時，先彈出確認再發送。';

  @override
  String get set_gnWarn => '高消耗提醒';

  @override
  String get set_gnWarnSub => '超過閾值時先確認';

  @override
  String get set_gnThreshold => '提醒閾值';

  @override
  String set_gnEstimate(
    Object model,
    Object w,
    Object h,
    Object steps,
    Object n,
  ) {
    return '當前生圖參數：$model · $w×$h · $steps 步 · 每次 $n 張';
  }

  @override
  String get set_gnWillWarn => '會提醒';

  @override
  String get set_gnNoWarn => '不會提醒';

  @override
  String get set_gnFree => '免費';

  @override
  String get set_gnPace => '請求節奏';

  @override
  String get set_gnPaceSub => '連續生成時每次請求之間等一會兒，減輕伺服器壓力，也讓佇列更像手動操作。';

  @override
  String get set_gnLimit => '限制生成間隔';

  @override
  String get set_gnInterval => '間隔';

  @override
  String get set_gnJitter => '隨機浮動';

  @override
  String get set_gnJitterSub => '在間隔上下隨機增減';

  @override
  String get set_gnTimeline => '按當前設定，連續 10 次請求大約這樣分佈';

  @override
  String get set_gnInput => '提示詞輸入';

  @override
  String get set_gnWheel => '滾輪調整權重';

  @override
  String get set_gnWheelSub => '游標放在標籤上滾動滾輪，直接加減權重';

  @override
  String get set_gnNoKey => '無需按鍵';

  @override
  String get set_gnRelated => '相關標籤擴展';

  @override
  String get set_gnRelatedSub => '輸入標籤時附帶推薦常一起出現的標籤';

  @override
  String get set_gnRag => '語義標籤推薦';

  @override
  String get set_gnRagSub => '結合上下文的智慧推薦，由“語義檢索”提供';

  @override
  String get set_gnReady => '已就緒';

  @override
  String get set_gnNotReady => '未就緒';

  @override
  String get set_gnGoSettings => '去設定';

  @override
  String get set_gnTranslate => '提示詞翻譯';

  @override
  String get set_gnTranslateSub => '在提示詞框裡中英互譯使用的模型';

  @override
  String get set_gnToday => '今天';

  @override
  String get set_gnUsed => 'Anlas 已用';

  @override
  String get set_gnNow => '現在';

  @override
  String get set_gnWarned => '高消耗提醒觸發';

  @override
  String set_gnTimes(Object n) {
    return '$n 次';
  }

  @override
  String get set_gnMaxSingle => '最大單次消耗';

  @override
  String get set_gnFreeTip =>
      '免費額度規則（Opus 小圖不扣 Anlas）由生圖頁按當前參數計算，這裡的閾值只看實際要扣的數。';

  @override
  String get set_stDesc => '圖片儲存在哪裡、畫廊讀哪些資料夾，以及佔用與清理。';

  @override
  String get set_stUsage => '佔用';

  @override
  String set_stFree(Object disk, Object size) {
    return '$disk 盤剩餘 $size';
  }

  @override
  String get set_stRecount => '重新統計';

  @override
  String get set_stCounting => '統計中…';

  @override
  String get set_stImages => '圖片';

  @override
  String get set_stUpscaleModels => '放大模型';

  @override
  String get set_stVibes => 'Vibe 庫';

  @override
  String get set_stThumbs => '縮圖快取';

  @override
  String get set_stRag => '語義索引';

  @override
  String get set_stDict => '詞庫與快取';

  @override
  String get set_stAgent => 'Agent';

  @override
  String get set_stSave => '儲存';

  @override
  String get set_stSavePath => '圖片儲存位置';

  @override
  String get set_stAutoSave => '自動儲存';

  @override
  String get set_stAutoSaveSub => '生成完成後立即寫入儲存位置；關掉後只留在畫布和歷史裡';

  @override
  String get set_stAssets => '素材與顯示';

  @override
  String get set_stVibePath => 'Vibe 庫位置';

  @override
  String get set_stQuality => '本地畫廊清晰度';

  @override
  String get set_stQualitySub => '縮圖的顯示品質';

  @override
  String get set_stHigh => '高畫質';

  @override
  String get set_stStandard => '標清';

  @override
  String get set_stRoots => '圖庫來源';

  @override
  String get set_stRootsSub => '任何資料夾都可以加入本地畫廊瀏覽和搜尋，不參與自動儲存。';

  @override
  String get set_stPrimary => '主目錄';

  @override
  String set_stCount(Object n) {
    return '$n 張';
  }

  @override
  String get set_stAddFolder => '新增資料夾';

  @override
  String get set_stImportIndex => '匯入標籤索引 (.jsonl)';

  @override
  String set_stLastScan(Object when, Object n) {
    return '上次掃描 $when · $n 張';
  }

  @override
  String get set_stMaintain => '維護';

  @override
  String get set_stRescan => '重新掃描圖庫';

  @override
  String get set_stRescanSub => '檢查缺失檔案、補掃新檔案、重試未讀出的後設資料';

  @override
  String get set_stScan => '掃描';

  @override
  String get set_stScanning => '掃描中…';

  @override
  String get set_stCleanThumbs => '清理縮圖快取';

  @override
  String get set_stCleanThumbsSub => '按最近使用淘汰超出上限的縮圖，不碰原圖';

  @override
  String get set_stClean => '清理';

  @override
  String get set_stCleanTitle => '清理縮圖快取？';

  @override
  String get set_stCleanBody => '超出上限的縮圖會被刪除，之後瀏覽時重新生成。原圖不受影響。';

  @override
  String get set_stAppData => '應用資料位置';

  @override
  String get set_stAppDataSub => '帳號、歷史、塊庫等資料庫所在目錄；修改後需要重啟';

  @override
  String get set_stOpenFolders => '開啟資料夾';

  @override
  String get set_stLogs => '日誌';

  @override
  String get set_stAppDataShort => '應用資料';

  @override
  String get set_stDeleteTip => '移動或刪除單張圖片仍在畫廊裡操作，並遵循“隱私與保護”裡的確認規則。';

  @override
  String get set_stRemoveRoot => '移除這個資料夾';

  @override
  String get set_dcDesc => '標籤資料和各級快取。一般不用動，出現補全異常時可以在這裡清理。';

  @override
  String get set_dcTags => '標籤詞庫';

  @override
  String get set_dcTagsSub => '自動補全、標籤翻譯和相關推薦用到的本地資料。';

  @override
  String get set_dcBase => '基礎資料庫';

  @override
  String set_dcBaseValue(Object n, Object wiki) {
    return '標籤 $n 條 · Wiki $wiki 篇';
  }

  @override
  String get set_dcSupplement => '資料補充';

  @override
  String get set_dcCheckUpdates => '檢查更新';

  @override
  String get set_dcWikiRefreshAvailable => 'Wiki 正文可重新整理';

  @override
  String get set_dcCheckingUpdates => '正在檢查…';

  @override
  String get set_dcCheckFailed => '檢查失敗，原資料仍可用。請重試。';

  @override
  String get set_dcLatest => '已是最新';

  @override
  String get set_dcUpdatesAvailable => '有可用更新';

  @override
  String set_dcLastChecked(Object when) {
    return '上次檢查 $when';
  }

  @override
  String get set_dcRefreshWiki => '重新整理 Wiki';

  @override
  String get set_dcRefreshWikiTip => '下載當前 Wiki 資料，更新此前未同步的已有正文；保留個人譯文。';

  @override
  String set_dcChanged(Object added, Object updated) {
    return '新增 $added 條，更新 $updated 條，已儲存在本地';
  }

  @override
  String get set_dcRagSyncTip => '如已使用語義檢索，請重啟 Studio 後手動同步相應來源的索引。';

  @override
  String get set_dcUpdateTags => '更新 Tag';

  @override
  String get set_dcUpdateWiki => '更新 Wiki';

  @override
  String set_dcSources(Object tagDate, Object wikiDate) {
    return '可用資料：Tag $tagDate · Wiki $wikiDate';
  }

  @override
  String set_dcDownloading(Object received, Object total) {
    return '正在下載 $received / $total';
  }

  @override
  String get set_dcVerifying => '正在校驗下載內容…';

  @override
  String set_dcImporting(Object n) {
    return '正在補充本地資料 · 已讀取 $n 條';
  }

  @override
  String get set_dcPublishing => '正在切換資料版本…';

  @override
  String get set_dcUpdateFailed => '補充失敗，已保留原資料。可重試。';

  @override
  String get set_dcUpdateCancelled => '已取消，原資料保持可用。';

  @override
  String get set_dcInstalled => '已補充';

  @override
  String get set_dcCancelling => '正在取消…';

  @override
  String get set_dcCooc => '共現資料';

  @override
  String get set_dcCoocSub => '用來推薦常一起出現的標籤';

  @override
  String set_dcEntries(Object n) {
    return '$n 條';
  }

  @override
  String get set_dcSemantics => '個人語義資料';

  @override
  String get set_dcSemanticsSub => '儲存補充的中文資料；清理翻譯快取時保留';

  @override
  String get set_dcTranslate => '標籤翻譯與語義補充';

  @override
  String get set_dcTranslateSub => '複用已有資料，按需補齊中文核心詞、同義詞和簡釋義';

  @override
  String get set_dcCaches => '快取';

  @override
  String get set_dcCachesSub => '清除後會在使用時重新取得，不影響你的圖片和設定。';

  @override
  String get set_dcDanbooru => 'Danbooru 快取';

  @override
  String get set_dcDanbooruSub => '線上畫廊與標籤百科的請求結果';

  @override
  String get set_dcTranslation => 'AI 翻譯快取';

  @override
  String get set_dcTranslationSub => '已翻譯過的標籤和提示詞';

  @override
  String set_dcCacheSize(Object n, Object size) {
    return '$n 條 · $size';
  }

  @override
  String set_dcClearTitle(Object name) {
    return '清除$name？';
  }

  @override
  String get set_dcClearBody => '下次用到時會重新取得。';

  @override
  String get set_dcStats => '快取統計';

  @override
  String get set_dcL1 => 'L1 記憶體';

  @override
  String get set_dcL2 => 'L2 Hive';

  @override
  String get set_dcL3 => 'L3 SQLite';

  @override
  String set_dcImagesUnit(Object n) {
    return '$n 張圖片';
  }

  @override
  String get set_dcAutoRefresh => '自動重新整理';

  @override
  String set_dcUpdated(Object when) {
    return '上次更新 $when';
  }

  @override
  String get set_dcResetStats => '重設統計';

  @override
  String get set_dcTip =>
      '詞庫和快取可以重新取得。個人語義資料請在本頁單獨匯出；帳號、歷史和塊庫的備份位置見“儲存與圖庫 → 應用資料位置”。';

  @override
  String get set_mdDesc =>
      '翻譯、反推、標籤翻譯和 Agent 用到的大模型服務。先新增服務商，再在“功能分配”裡給每個功能選模型。';

  @override
  String get set_mdProviders => '服務商';

  @override
  String get set_mdTasks => '功能分配';

  @override
  String get set_mdTaskHint => '即使不使用翻譯，也可將模型用於語義分割、結構化排序等功能。';

  @override
  String get set_mdPresets => '提示詞預設';

  @override
  String get set_mdRequests => '請求記錄';

  @override
  String set_mdProviderCount(Object n) {
    return '$n 個服務商';
  }

  @override
  String set_mdModelCount(Object n) {
    return '$n 個模型';
  }

  @override
  String get set_mdDisabled => '已停用';

  @override
  String get set_mdUnreachable => '連線失敗';

  @override
  String get set_mdBaseUrl => '介面地址';

  @override
  String get set_mdApiKey => 'API Key';

  @override
  String set_mdUsedFor(Object tasks) {
    return '用於 $tasks';
  }

  @override
  String get set_mdRetired => '服務商已下線';

  @override
  String get set_mdDelete => '刪除服務商';

  @override
  String set_mdDeleteTitle(Object name) {
    return '刪除服務商“$name”？';
  }

  @override
  String get set_mdDeleteBody => '用到它的功能會回落到其他可用服務商。';

  @override
  String get set_mdTaskPrompt => '提示詞翻譯';

  @override
  String get set_mdTaskReverse => '提示詞反推';

  @override
  String get set_mdTaskTag => '標籤翻譯與語義補充';

  @override
  String get set_mdTaskWiki => '百科翻譯';

  @override
  String get set_mdFeature => '功能';

  @override
  String get set_mdProvider => '服務商';

  @override
  String get set_mdModel => '模型';

  @override
  String get set_mdPreset => '預設';

  @override
  String get set_mdStatus => '狀態';

  @override
  String get set_mdAvailable => '可用';

  @override
  String get set_mdFallback => '回落到第一個可用服務商';

  @override
  String get set_mdNotChosen => '未選擇';

  @override
  String get set_mdBuiltin => '內建';

  @override
  String get set_mdNewPreset => '新增預設';

  @override
  String get set_mdEdit => '編輯';

  @override
  String get set_mdTime => '時間';

  @override
  String set_mdTokens(Object n) {
    return '$n tokens';
  }

  @override
  String get set_mdFailed => '失敗';

  @override
  String get set_mdOk => '成功';

  @override
  String set_mdShowing(Object n, Object total) {
    return '顯示最近 $n 條，共 $total 條';
  }

  @override
  String get set_mdImport => '匯入配置';

  @override
  String get set_mdAddProvider => '新增服務商';

  @override
  String get set_mdEmpty => '還沒有服務商';

  @override
  String get set_mdEmptySub => '新增一個服務商後，翻譯和反推就能用了。';

  @override
  String get set_agDesc => '側欄助手的模型、指令、Skill、擴展和 MCP 工具。';

  @override
  String get set_agModelSec => '模型';

  @override
  String get set_agModel => '預設模型';

  @override
  String get set_agModelSub => '思考強度在聊天框裡按任務調整';

  @override
  String get set_agEnter => 'Enter 直接傳送';

  @override
  String get set_agEnterSub => '關掉後用 Ctrl+Enter 傳送，Enter 換行';

  @override
  String get set_agMax => '單次任務最多請求';

  @override
  String get set_agMaxSub => '防止 Agent 陷入迴圈';

  @override
  String get set_agTimesUnit => '次';

  @override
  String get set_agInstr => '指令';

  @override
  String get set_agInstrSub => '按下面的順序拼成最終提示詞；已有聊天保持原樣，之後的請求使用新內容。';

  @override
  String get set_agOrderBuiltin => '內建系統提示詞';

  @override
  String get set_agOrderPrefix => '內建提示詞前';

  @override
  String get set_agOrderGlobal => '全域指令';

  @override
  String get set_agOrderWorkspace => '工作區規則';

  @override
  String get set_agGlobal => '全域指令';

  @override
  String get set_agGlobalHint => '相當於系統級 AGENTS.md，對所有工作區生效。';

  @override
  String get set_agPrefix => '內建提示詞前';

  @override
  String get set_agPrefixHint => '在內建系統提示詞之前加入的固定內容，例如身份或輸出格式。';

  @override
  String get set_agBuiltin => '內建系統提示詞';

  @override
  String get set_agFinal => '檢視最終提示詞';

  @override
  String get set_agExt => '擴展';

  @override
  String get set_agExtSub => '各工作區獨立載入；外部擴展能執行原生代碼，請只新增可信來源。';

  @override
  String get set_agStudioExt => 'Studio 互動';

  @override
  String get set_agStudioExtSub => '讀取當前 Studio 狀態，並通過問題卡片收集回答';

  @override
  String get set_agRequired => '內建 · 必需';

  @override
  String get set_agAddFile => '新增擴展檔案';

  @override
  String get set_agAddDir => '新增擴展目錄';

  @override
  String get set_agMcp => 'MCP 伺服器';

  @override
  String get set_agMcpSub => '預設 CodeMode 按需發現，工具不會一次性塞進上下文。';

  @override
  String get set_agBuiltinTools => 'NAI Studio · 內建工具組';

  @override
  String get set_agBuiltinToolsSub => '提示詞、塊、百科、圖片、歷史、參考圖、生圖與設定工具';

  @override
  String set_agConnected(Object n) {
    return '已連線 · $n 個工具';
  }

  @override
  String get set_agConnecting => '連線中…';

  @override
  String get set_agNeedsLogin => '需要登入';

  @override
  String get set_agMcpError => '連線失敗';

  @override
  String get set_agMcpOff => '已停用';

  @override
  String get set_agAddMcp => '新增 MCP 伺服器';

  @override
  String get set_agTools => '工具';

  @override
  String set_agToolCount(Object n) {
    return '$n 個';
  }

  @override
  String get set_agToolsTip =>
      '業務工具經 codemode 按需發現，用法寫在 nai-studio Skill。生圖類工具始終先報價，等你確認後才執行。';

  @override
  String get set_agData => '資料目錄';

  @override
  String get set_agWorkspaces => '工作區';

  @override
  String get set_agSessions => '會話';

  @override
  String get set_agCostTip => '費用由服務商計費，Studio 只顯示 token 用量。';

  @override
  String get set_agOpen => '開啟 Agent';

  @override
  String get set_agEditMcp => '編輯';

  @override
  String get set_agRemoveMcp => '移除伺服器';

  @override
  String get set_agRemoveExt => '移除擴展';

  @override
  String get set_rgDesc => '本地執行的 RAG：給標籤推薦、Wiki、提示詞塊和圖庫找相似提供語義能力，不上傳任何內容。';

  @override
  String get set_rgReady => '語義檢索已就緒';

  @override
  String get set_rgOff => '語義檢索已關閉';

  @override
  String get set_rgPartial => '部分來源建庫中';

  @override
  String get set_rgAllDone => '全部完成';

  @override
  String get set_rgPool => '所有來源共用一個本地向量池，新增內容自動增量更新。';

  @override
  String get set_rgStepRuntime => '執行環境';

  @override
  String get set_rgStepEmbed => '嵌入';

  @override
  String get set_rgStepRerank => '重排';

  @override
  String get set_rgStepDevice => '裝置';

  @override
  String get set_rgSources => '來源';

  @override
  String get set_rgSourcesSub => '每個來源單獨建庫、單獨開關；建庫可以暫停，已完成的部分立即可用。';

  @override
  String get set_rgTags => '標籤上下文推薦';

  @override
  String get set_rgTagsSub => '結合語義、共現與重排；各提示詞框、角色和正負面分開計算';

  @override
  String get set_rgWiki => 'Wiki 語義搜尋';

  @override
  String get set_rgWikiSub => '本地百科正文，名稱精確匹配優先，語義結果補充';

  @override
  String get set_rgBlocks => '提示詞塊';

  @override
  String get set_rgBlocksSub => '已儲存、未歸檔塊的標題、標籤與正負面文字';

  @override
  String get set_rgGallery => '圖庫多模態';

  @override
  String get set_rgGallerySub => '分析畫面找相似圖；NAI 圖的參數另建文字索引，原圖不改寫';

  @override
  String set_rgCount(Object done, Object total) {
    return '$done / $total';
  }

  @override
  String set_rgSegments(Object done, Object total) {
    return '$done / $total 段';
  }

  @override
  String set_rgGalleryCount(Object done, Object total, Object n) {
    return '畫面 $done / $total · 參數 $n 段';
  }

  @override
  String get set_rgPaused => '已暫停';

  @override
  String get set_rgBuilding => '建庫中';

  @override
  String get set_rgError => '出錯';

  @override
  String get set_rgClearIndex => '清除索引';

  @override
  String set_rgClearTitle(Object name) {
    return '清除“$name”的索引？';
  }

  @override
  String get set_rgClearBody => '只刪除派生索引，原始內容和模型都保留。';

  @override
  String get set_rgContext => '推薦上下文';

  @override
  String get set_rgContextSub => '兩種都最多取 120 個 Gemma token，按完整標籤擷取。';

  @override
  String get set_rgRange => '取樣範圍';

  @override
  String get set_rgBefore => '游標前';

  @override
  String get set_rgAround => '插入點前後';

  @override
  String get set_rgRuntime => '模型與執行環境';

  @override
  String get set_rgEmbedPath => '嵌入模型目錄';

  @override
  String get set_rgRerankPath => '重排模型目錄';

  @override
  String get set_rgDevice => '執行裝置';

  @override
  String get set_rgAuto => '自動';

  @override
  String get set_rgEnv => '執行環境';

  @override
  String get set_rgEnvSub => '獨立 Python 與推理依賴，不下載模型權重';

  @override
  String get set_rgCheck => '檢測';

  @override
  String get set_rgReinstall => '重新安裝';

  @override
  String get set_rgProgress => '建庫進度';

  @override
  String get set_rgOverall => '總體';

  @override
  String get set_rgShortTags => '標籤';

  @override
  String get set_rgShortWiki => 'Wiki';

  @override
  String get set_rgShortBlocks => '塊';

  @override
  String get set_rgShortGallery => '圖庫';

  @override
  String get set_rgTip => '清除某個來源只刪除它的派生索引，原始內容和模型都保留。';

  @override
  String get set_rgNotReady => '語義檢索還不能用';

  @override
  String get set_rgNotReadySub => '先安裝執行環境，再選好兩個模型目錄。';

  @override
  String get set_rgEmpty => '未建立';

  @override
  String get set_rgBuild => '建立索引';

  @override
  String get set_rgContinue => '繼續建立';

  @override
  String set_rgSkipped(Object n) {
    return '跳過 $n 張';
  }

  @override
  String get set_rgStartupTitle => '準備本地索引';

  @override
  String get set_rgStartupBody => '首次建立或繼續索引前，需要先準備本地執行環境、模型和已有資料。';

  @override
  String get set_rgStartupWaitTitle => '可能需要幾分鐘或更久';

  @override
  String get set_rgStartupWaitBody => '準備期間，進度數字可能暫時不變，請耐心等待。';

  @override
  String get set_rgStartupFrequency => '每次啟動僅提示一次';

  @override
  String get set_rgLoading => '正在載入索引';

  @override
  String get set_rgOpening => '正在連線本地工作程序，讀取已有索引。';

  @override
  String get set_rgLoadingSaved => '正在載入已儲存的檢索索引。';

  @override
  String set_rgRestoring(String done, String total) {
    return '正在恢復檢索索引 $done / $total，已有向量會直接複用。';
  }

  @override
  String get set_rgSaving => '正在儲存恢復後的檢索索引。';

  @override
  String get set_rgReadingSources => '正在讀取各來源的索引狀態。';

  @override
  String get set_rgLoadingTimeout => '索引載入長時間沒有進展或已達到時間上限，請重試。已有資料保留。';

  @override
  String get set_rgPreparing => '正在準備索引';

  @override
  String get set_rgPreparingHint => '正在準備或檢查索引，資料較多時請耐心等待；進度數字可能暫時不變。';

  @override
  String get set_rgPlanLoading => '正在統計要收錄的內容…';

  @override
  String set_rgPlanTags(Object n) {
    return '將收錄 $n 項標籤、別名與已有本地釋義。';
  }

  @override
  String set_rgPlanText(Object docs, Object n) {
    return '將收錄 $docs 份資料，切成 $n 個文字片段。';
  }

  @override
  String set_rgPlanGallery(Object images, Object n) {
    return '將收錄 $images 張圖片和 $n 段 NAI 參數，畫面與參數分開索引。';
  }

  @override
  String get set_rgPlanNote => '首次處理可能較久，可以隨時暫停，已完成的部分立即可用。';

  @override
  String get set_rgPlanRebuild => '重建會先清掉這個來源的現有索引。';

  @override
  String get set_rgStart => '開始';

  @override
  String get set_rgDownload => '下載';

  @override
  String set_rgDownloading(Object done, Object total) {
    return '正在下載 $done / $total';
  }

  @override
  String set_rgDownloadingUnknown(Object done) {
    return '正在下載 $done';
  }

  @override
  String get set_rgVerifying => '正在校驗檔案…';

  @override
  String get set_rgDiscover => '查詢本地模型';

  @override
  String get set_rgDiscoverSub =>
      '在工作區 04_工具/models 裡找 EmbeddingGemma 2 和 Qwen3-Reranker 0.6B，找到後自動填好上面兩個目錄。';

  @override
  String get set_rgFind => '查詢';

  @override
  String get set_rgModelsMissing => '沒找到。可以點“下載”，或手動選擇已下載的權重目錄。';

  @override
  String get set_rgPython => 'Python 直譯器';

  @override
  String get set_rgPythonSub => '預設用自動安裝的獨立環境；也可以選一個已有的 python.exe。';

  @override
  String get set_rgPythonAuto => '自動';

  @override
  String get set_rgPythonNone => '未安裝';

  @override
  String get set_rgPythonPending => '選的直譯器還沒啟用，點“使用此直譯器”會按它重新安裝依賴。';

  @override
  String get set_rgUsePython => '使用此直譯器';

  @override
  String get set_rgEnvReady => '已就緒';

  @override
  String get set_rgEnvMissing => '還沒有安裝';

  @override
  String get set_rgInstall => '安裝';

  @override
  String get set_rgInstallHint =>
      '下載 Python 與推理依賴，不下載模型權重。NVIDIA 顯示卡選 CUDA（約需數 GB）；其他選 CPU，下載較小。';

  @override
  String get set_rgInstallCuda => 'CUDA · NVIDIA';

  @override
  String get set_rgInstallCpu => 'CPU';

  @override
  String get set_rgPhaseExisting => '正在檢測已有環境';

  @override
  String get set_rgPhaseDownload => '正在下載安裝工具';

  @override
  String get set_rgPhaseCreate => '正在準備 Python 環境';

  @override
  String get set_rgPhaseCuda => '正在安裝 CUDA 推理元件';

  @override
  String get set_rgPhasePackages => '正在安裝推理依賴';

  @override
  String get set_rgPhaseCheck => '正在校驗環境';

  @override
  String set_rgElapsed(Object time) {
    return '此階段已用 $time';
  }

  @override
  String get set_upDesc => '管理本機超分模型和元件。所有下載都需要你手動開始。';

  @override
  String set_upGpu(Object name, Object n) {
    return '$name · $n GB';
  }

  @override
  String get set_upNoGpu => '沒有檢測到獨立顯示卡';

  @override
  String get set_upLocal => '在本機放大圖片，不消耗 Anlas。';

  @override
  String get set_upEsrgan => '常規模型';

  @override
  String get set_upEsrganSub =>
      'Real-ESRGAN NCNN，4 倍放大，速度快，任何支援 Vulkan 的顯示卡都能用。';

  @override
  String get set_upAnimeQuality => '動漫 · 畫質';

  @override
  String get set_upAnimeFast => '動漫 · 快速';

  @override
  String get set_upGeneral => '通用 · 攝影';

  @override
  String get set_upBuiltin => '內建';

  @override
  String get set_upInstalled => '已安裝';

  @override
  String get set_upNotInstalled => '未安裝';

  @override
  String get set_upFailed => '下載失敗';

  @override
  String get set_upImport => '匯入模型';

  @override
  String get set_upImportHint => '選擇配套的 .param 和 .bin（4 倍 Real-ESRGAN NCNN）';

  @override
  String get set_upSeed => 'SeedVR2 擴散放大';

  @override
  String get set_upSeedSub =>
      '畫質更好、更慢，需要 NVIDIA 顯示卡。型號共用 VAE（約 0.5 GB）和 Python/CUDA 環境。';

  @override
  String get set_upSeed3b => '3B · 均衡';

  @override
  String get set_upSeed3bSub => '兼顧效果與資源佔用，適合日常放大';

  @override
  String get set_upSeed7b => '7B · 高畫質';

  @override
  String get set_upSeed7bSub => '更高畫質潛力，需要更多視訊記憶體與時間';

  @override
  String get set_upSeed7bSharp => '7B · 銳利';

  @override
  String get set_upSeed7bSharpSub => '偏向更銳利的細節，適合強化紋理';

  @override
  String get set_upSeed3bInt8 => '3B · 均衡 INT8';

  @override
  String get set_upSeed3bInt8Sub => '3B 均衡型號的 INT8 量化版本';

  @override
  String get set_upSeed7bInt8 => '7B · 高畫質 INT8';

  @override
  String get set_upSeed7bInt8Sub => '7B 高畫質型號的 INT8 量化版本';

  @override
  String get set_upSeed7bSharpInt8 => '7B · 銳利 INT8';

  @override
  String get set_upSeed7bSharpInt8Sub => '7B 銳利型號的 INT8 量化版本';

  @override
  String set_upVram(Object n) {
    return '視訊記憶體 ≥ $n GB';
  }

  @override
  String set_upProgress(Object done, Object total, Object speed) {
    return '$done / $total · $speed/s';
  }

  @override
  String get set_upVramMode => '視訊記憶體模式';

  @override
  String get set_upRecommended => '推薦';

  @override
  String get set_upLowVram => '低視訊記憶體';

  @override
  String get set_upOffload => 'CPU 卸載層數';

  @override
  String get set_upOffloadSub => '卸載越多越省視訊記憶體，但更慢、佔更多記憶體';

  @override
  String get set_upTiling => 'VAE 分塊';

  @override
  String get set_upTilingSub => '小分塊省視訊記憶體，重疊可以減輕接縫';

  @override
  String get set_upNoise => '實驗性噪聲';

  @override
  String set_upNoiseSub(Object a, Object b) {
    return '輸入噪聲 $a · 潛空間噪聲 $b；保持 0 即沿用當前效果';
  }

  @override
  String get set_upInputNoise => '輸入噪聲';

  @override
  String get set_upLatentNoise => '潛空間噪聲';

  @override
  String get set_upExperimental => '實驗';

  @override
  String get set_upRtx => 'RTX Video';

  @override
  String get set_upRtxSub => '使用 NVIDIA RTX Video 快速放大，約 64 MB 獨立元件。';

  @override
  String get set_upRtxName => 'RTX Video Super Resolution';

  @override
  String get set_upRtxNeeds => '需要相容的 RTX 顯示卡與驅動';

  @override
  String get set_upDefault => '預設放大方式';

  @override
  String get set_upDefaultTip => '生圖頁工具條上的“本地放大”預設用這個，選單裡隨時可換。';

  @override
  String get set_upVramTip => '視訊記憶體不足時不會自動換型號；可以改用 3B、降低倍率，或開啟低視訊記憶體與 VAE 分塊。';

  @override
  String set_upRemoveTitle(Object name) {
    return '刪除$name？';
  }

  @override
  String get set_upRemoveBody => '之後要用時需要重新下載。';

  @override
  String get set_brDesc => '和本機其他軟體協作：Krita、外部 Agent 和 ComfyUI。';

  @override
  String get set_brKritaSub => '在 Krita 裡直接呼叫 Studio 生圖，結果回到 Krita 圖層。';

  @override
  String get set_brKrita => 'Krita 橋接';

  @override
  String get set_brLoopback => '本機監聽，只接受 127.0.0.1 的連線';

  @override
  String get set_brConnected => '已連線';

  @override
  String get set_brWaiting => '等待 Krita 連線';

  @override
  String get set_brRegenerate => '重新生成會話';

  @override
  String get set_brDiscovery => '發現檔案';

  @override
  String get set_brAgents => '外部 Agent';

  @override
  String get set_brAgentsSub => '讓 Claude Code、Codex 等能執行本機命令的 Agent 讀寫參數和生圖。';

  @override
  String get set_brLocal => '本機橋接';

  @override
  String set_brClients(Object n) {
    return '$n 個 Agent 已連線';
  }

  @override
  String get set_brNoClients => '沒有 Agent 連線';

  @override
  String get set_brTakeover => '複製接管說明';

  @override
  String get set_brEnd => '結束連線';

  @override
  String get set_brActivity => '最近活動';

  @override
  String get set_brComfySub => '匯入 ComfyUI 工作流，在 Studio 裡填參執行。';

  @override
  String get set_brComfyEnable => '啟用 ComfyUI';

  @override
  String get set_brComfyUrl => '服務地址';

  @override
  String set_brComfyFailed(Object reason, Object when) {
    return '連線失敗：$reason（$when）。確認 ComfyUI 已啟動並允許本機存取。';
  }

  @override
  String set_brComfyOk(Object when) {
    return '連線正常（$when）';
  }

  @override
  String get set_brStatus => '狀態';

  @override
  String set_brAgentsShort(Object n) {
    return '$n 個';
  }

  @override
  String get set_brOff => '未啟用';

  @override
  String get set_brNoResponse => '無回應';

  @override
  String get set_brTip => '所有橋接只在本機迴環地址上監聽，不對區域網開放。代理設定不影響這些連線。';

  @override
  String get set_nwDesc => '代理和連線狀態。';

  @override
  String get set_nwProxy => '代理';

  @override
  String get set_nwProxySub => '存取 NovelAI、Danbooru、GitHub 更新和第三方模型服務時使用。';

  @override
  String get set_nwUse => '使用代理';

  @override
  String get set_nwMode => '方式';

  @override
  String get set_nwSystem => '跟隨系統';

  @override
  String get set_nwManual => '手動';

  @override
  String get set_nwAddress => '地址';

  @override
  String set_nwDetected(Object addr) {
    return '系統代理檢測到 $addr。代理只轉發上述外部請求，本機橋接和本地模型不經過代理。';
  }

  @override
  String get set_nwNoSystem => '沒有檢測到系統代理。代理只轉發外部請求，本機橋接和本地模型不經過代理。';

  @override
  String get set_nwCheck => '連線檢測';

  @override
  String get set_nwCheckSub => '一鍵檢查各服務是否可達，出錯時更容易判斷是網路還是服務的問題。';

  @override
  String get set_nwNaiImage => 'NovelAI 生圖';

  @override
  String get set_nwNaiApi => 'NovelAI 帳戶';

  @override
  String get set_nwDanbooru => 'Danbooru';

  @override
  String get set_nwUpdate => '應用更新';

  @override
  String get set_nwCheckAll => '全部檢測';

  @override
  String set_nwChecked(Object when) {
    return '上次檢測 $when';
  }

  @override
  String get set_nwViaProxy => '經過代理';

  @override
  String get set_nwDirect => '直連';

  @override
  String get set_nwNeverChecked => '還沒檢測過';

  @override
  String get set_nwFail => '失敗';

  @override
  String get set_nwTip => '改代理後需要重啟才會生效；Studio 會提醒，不會自動重啟打斷你的工作。';

  @override
  String get set_pvDesc => '分享圖片時帶出什麼資訊，以及哪些操作需要你確認。';

  @override
  String get set_pvProtect => '保護';

  @override
  String get set_pvStrip => '分享時去除後設資料';

  @override
  String get set_pvStripSub => '複製或拖出圖片時去掉提示詞和參數，原檔案不變';

  @override
  String get set_pvExternal => '傳送到外部前提醒';

  @override
  String get set_pvExternalSub => '把圖片發給其他軟體或網頁前先確認';

  @override
  String get set_pvDanger => '危險操作需確認';

  @override
  String get set_pvDangerSub => '刪除、清空、覆蓋等不可復原的操作先彈確認';

  @override
  String get set_pvOverwrite => '儲存時不覆蓋';

  @override
  String get set_pvOverwriteSub => '目標位置有同名檔案時自動改名';

  @override
  String get set_pvBlacklist => '線上畫廊黑名單';

  @override
  String get set_pvBlacklistSub => '含有這些標籤的圖片在線上畫廊裡直接隱藏。';

  @override
  String get set_pvAddTag => '新增標籤…';

  @override
  String get set_pvSync => '同步 Danbooru 黑名單';

  @override
  String set_pvSyncSub(Object user, Object when) {
    return '已登入 $user · 上次同步 $when';
  }

  @override
  String set_pvSyncNever(Object user) {
    return '已登入 $user · 還沒同步過';
  }

  @override
  String get set_pvSyncSignedOut => '登入 Danbooru 後可以同步帳號裡的黑名單';

  @override
  String get set_pvSyncNow => '立即同步';

  @override
  String get set_pvSyncing => '同步中…';

  @override
  String get set_pvAutoSync => '啟動時自動同步';

  @override
  String get set_pvExported => '匯出時包含什麼';

  @override
  String get set_pvIncPrefs => '外觀、操作、輸入偏好';

  @override
  String get set_pvIncRules => '保護規則與黑名單';

  @override
  String get set_pvIncCred => '帳號憑據';

  @override
  String get set_pvIncPaths => '檔案路徑';

  @override
  String get set_pvIncDrafts => '草稿與模型繫結';

  @override
  String get set_pvTip => '後設資料保護只作用於“複製”和“拖出”，儲存到磁碟的原圖始終保留完整參數，方便日後複用。';

  @override
  String get set_bkDesc => '在裝置之間遷移偏好，或者回到預設狀態。所有重設都會先備份。';

  @override
  String get set_bkPrefs => '偏好設定';

  @override
  String get set_bkPrefsSub => '外觀、操作、輸入與保護規則。帳號憑據、路徑、草稿和模型繫結不會寫進檔案。';

  @override
  String get set_bkExport => '匯出';

  @override
  String get set_bkExportSub => '儲存為 studio-preferences.json';

  @override
  String get set_bkExportBtn => '匯出…';

  @override
  String get set_bkImport => '匯入';

  @override
  String get set_bkImportSub => '應用前會顯示將修改多少項，並自動備份當前設定';

  @override
  String get set_bkImportBtn => '選擇檔案…';

  @override
  String get set_bkUndoImport => '復原上次匯入';

  @override
  String set_bkUndoImportSub(Object when) {
    return '回到 $when 匯入前的狀態';
  }

  @override
  String get set_bkNoImport => '還沒有匯入過';

  @override
  String get set_bkRestore => '恢復';

  @override
  String get set_bkOther => '其他配置';

  @override
  String set_bkShortcutsSub(Object n, Object m) {
    return '$n 個動作，$m 個已自訂';
  }

  @override
  String get set_bkModelsSub => '服務商、功能分配和預設；API Key 預設不匯出';

  @override
  String get set_bkCopyConfig => '複製配置';

  @override
  String get set_bkReset => '恢復預設';

  @override
  String get set_bkResetSub => '選擇要重設的範圍；其他設定保持不變。';

  @override
  String get set_bkScopeAppearance => '外觀與操作';

  @override
  String get set_bkScopeAppearanceSub => '主題、字型、語言、畫布、提醒';

  @override
  String get set_bkScopeInput => '輸入與補全';

  @override
  String get set_bkScopeInputSub => '滾輪權重、標籤擴展、自動補全';

  @override
  String get set_bkScopeProtect => '隱私與生成保護';

  @override
  String get set_bkScopeProtectSub => '後設資料、確認、高消耗提醒、請求節奏';

  @override
  String get set_bkScopeShortcuts => '快速鍵';

  @override
  String set_bkScopeShortcutsSub(Object n) {
    return '全部 $n 個動作';
  }

  @override
  String get set_bkResetBtn => '恢復所選為預設…';

  @override
  String get set_bkResetHint => '會先備份當前設定，可以復原';

  @override
  String get set_bkResetTitle => '恢復所選設定為預設？';

  @override
  String set_bkResetBody(Object scopes) {
    return '$scopes 會回到預設值。當前設定會先自動備份。';
  }

  @override
  String get set_bkAuto => '自動備份';

  @override
  String get set_bkAutoSub => '保留最近 5 份';

  @override
  String get set_bkKindImport => '匯入前';

  @override
  String get set_bkKindReset => '恢復預設前';

  @override
  String get set_bkKindUpgrade => '升級前';

  @override
  String get set_bkNoBackups => '還沒有自動備份';

  @override
  String set_bkRestoreTitle(Object name) {
    return '恢復到“$name”的備份？';
  }

  @override
  String get set_bkRestoreBody => '當前設定會先備份，之後可以再換回來。';

  @override
  String get set_abDesc => '版本、更新和問題診斷。';

  @override
  String set_abNew(Object version) {
    return '有新版本 $version';
  }

  @override
  String get set_abLatest => '已是最新版本';

  @override
  String get set_abChecking => '正在檢查更新…';

  @override
  String get set_abCheckFailed => '檢查更新失敗';

  @override
  String set_abDownloading(Object pct) {
    return '正在下載 $pct';
  }

  @override
  String set_abChecked(Object when) {
    return '上次檢查 $when';
  }

  @override
  String set_abNotes(Object version) {
    return '$version 更新內容';
  }

  @override
  String get set_abInstall => '下載並安裝';

  @override
  String get set_abChangelog => '完整更新日誌';

  @override
  String get set_abPrerelease => '包含預發行版本';

  @override
  String get set_abCheck => '檢查更新';

  @override
  String get set_abDiag => '診斷';

  @override
  String get set_abLog => '寫入日誌檔案';

  @override
  String get set_abLogSub => '排查問題時開啟；日誌不含 API Key 和登入憑據';

  @override
  String get set_abLogDir => '日誌目錄';

  @override
  String get set_abCopyDiag => '複製診斷資訊';

  @override
  String get set_abCopyDiagSub => '版本、系統、顯示卡、各服務狀態，方便反饋問題';

  @override
  String get set_abProject => '專案';

  @override
  String get set_abRepo => '開源專案';

  @override
  String get set_abUpstream => '原專案';

  @override
  String get set_abUpstreamSub => '本專案基於 NAI Launcher 開發，保留原作者署名';

  @override
  String get set_abFonts => '字型與素材';

  @override
  String get set_abLicenses => '許可證';

  @override
  String get set_abView => '檢視';

  @override
  String get set_abSystem => '系統';

  @override
  String set_srQuoted(Object query) {
    return '“$query”';
  }

  @override
  String get set_srBalance => 'Anlas 餘額';

  @override
  String get set_srSubscription => '訂閱與 Anlas 額度';

  @override
  String get set_agEnable => '啟用';

  @override
  String get set_agDisable => '停用';

  @override
  String get set_listSep => '、';

  @override
  String get set_on => '開';

  @override
  String get set_off => '關';

  @override
  String get set_unitSeconds => '秒';

  @override
  String get set_unsavedAgent => 'Agent 指令有未儲存的修改';

  @override
  String get set_accUnread => '未讀取';

  @override
  String get set_accBalanceUnread => '餘額未讀取';

  @override
  String get set_agBase => '內建系統提示詞';

  @override
  String set_agBaseGlobalState(Object state) {
    return '全域：$state';
  }

  @override
  String set_agBaseWsState(Object name, Object state) {
    return '工作區「$name」：$state';
  }

  @override
  String get set_agBaseBuiltin => '內建';

  @override
  String get set_agBaseCustom => '已自訂';

  @override
  String get set_agBaseInherit => '沿用全域';

  @override
  String get set_agBaseOwn => '單獨設定';

  @override
  String get set_agBaseEdit => '編輯';

  @override
  String get set_agBaseCollapse => '收起';

  @override
  String get set_agScopeGlobal => '全域';

  @override
  String set_agScopeWorkspace(Object name) {
    return '工作區 · $name';
  }

  @override
  String get set_agBaseUseGlobalOn => '這個工作區沿用全域提示詞；關掉才能單獨編輯';

  @override
  String get set_agBaseUseGlobalOff => '這個工作區使用單獨的提示詞；開啟則改回沿用全域';

  @override
  String get set_agBaseHint =>
      '可用自訂內容替換內建系統提示詞，拼在“內建提示詞前”的內容之後；工具地圖由應用追加。全域和工作區分開儲存，已有聊天保持原樣。';

  @override
  String get set_agBaseRestore => '恢復內建';

  @override
  String get set_agBaseRestoreTitle => '恢復內建系統提示詞？';

  @override
  String get set_agBaseRestoreBody =>
      '全域自訂內容會換回內建系統提示詞，舊內容存入提示詞歷史。各工作區單獨的提示詞不受影響。';

  @override
  String get set_agBaseSwitchTitle => '放棄內建系統提示詞的修改？';

  @override
  String get set_agBaseSwitchBody => '切換範圍會丟掉還沒儲存的修改。';

  @override
  String get set_agBaseSaving => '正在儲存…';

  @override
  String get set_agBaseFailed => '沒有儲存：工作區已切換或寫入失敗，修改還在。';

  @override
  String get set_agMcpUnchecked => '未檢測';

  @override
  String get set_agInstructionsSaving => '正在儲存指令…';

  @override
  String get set_agInstructionsFailed => '指令未儲存：內容已變化或寫入失敗。草稿已保留，請重試。';

  @override
  String get set_agOrderSkills => 'Skill 目錄';

  @override
  String get set_agQuick => '快捷資訊';

  @override
  String get set_agQuickSub => '側欄歡迎頁的快捷卡片。點卡片把內容填進輸入框，也可以設成直接傳送。';

  @override
  String set_agQuickShown(int shown, int total) {
    return '歡迎頁顯示 $shown / $total';
  }

  @override
  String get set_agQuickEmpty => '還沒有快捷資訊，歡迎頁不顯示這一塊。';

  @override
  String get set_agQuickSendBadge => '直接傳送';

  @override
  String get set_agQuickHidden => '不顯示';

  @override
  String get set_agQuickUp => '上移';

  @override
  String get set_agQuickDown => '下移';

  @override
  String get set_agQuickEditOne => '編輯';

  @override
  String get set_agQuickRemove => '刪除';

  @override
  String get set_agQuickAdd => '新增快捷資訊';

  @override
  String get set_agQuickRestore => '恢復預設';

  @override
  String get set_agQuickRestoreConfirm => '恢復成內建的 4 條快捷資訊？你新增和改過的會被替換。';

  @override
  String set_agQuickRemoveConfirm(String title) {
    return '刪除快捷資訊「$title」？';
  }

  @override
  String get set_agQuickNew => '新增快捷資訊';

  @override
  String get set_agQuickEditTitle => '編輯快捷資訊';

  @override
  String get set_agQuickIcon => '圖示';

  @override
  String get set_agQuickTitle => '標題';

  @override
  String get set_agQuickHint => '說明（可不填）';

  @override
  String get set_agQuickPrompt => '發給 Agent 的內容';

  @override
  String get set_agQuickSend => '點選後直接傳送（不勾選則填進輸入框）';

  @override
  String get set_agSkills => 'Skill';

  @override
  String get set_agSkillsSub => '平時只把名稱和一句話描述放進提示詞；任務對得上時 Agent 才讀取完整說明。';

  @override
  String set_agSkillsLoaded(Object n) {
    return '$n 個已載入';
  }

  @override
  String get set_agSkillBuiltin => '內建';

  @override
  String get set_agSkillGlobal => '全域';

  @override
  String get set_agSkillWorkspace => '工作區';

  @override
  String get set_agSkillAuto => '自動呼叫';

  @override
  String get set_agSkillManual => '僅手動呼叫';

  @override
  String get set_agSkillAutoTip => '提示詞裡只放名稱和一句話描述，任務對得上時 Agent 會自己讀取完整說明。';

  @override
  String get set_agSkillManualTip => '不進提示詞，Agent 不會自己用；在聊天框輸入 /skill:名稱 才會呼叫。';

  @override
  String get set_agWorkspaceRulesSub =>
      '只對當前工作區生效的補充要求，存為工作區裡的 instructions.md，排在全域指令之後；點“編輯”用系統編輯器開啟，留空就不加。';

  @override
  String get set_agSkillDescNaiPrompt =>
      '按當前模型（V4／V4.5 或 V5）的規則，撰寫或修改草稿裡的 NovelAI 提示詞：主提示詞、負面、角色、積木與權重。改提示詞前先讀。';

  @override
  String get set_agSkillDescNaiStudio =>
      '操作 NAI Studio：草稿、圖片、生成、語義搜尋、圖庫／歷史、參考圖、積木、畫風探索、影像工具、快照與偏好設定。除讀取當前狀態外，其他 Studio 操作前先讀。';

  @override
  String get set_agSkillView => '檢視';

  @override
  String get set_agSkillAdd => '新增 Skill 資料夾';

  @override
  String get set_agSkillNew => '新增 Skill';

  @override
  String get set_agSkillSlashHint => '聊天框輸入 /skill:名稱 手動呼叫';

  @override
  String get set_agSkillTrust => 'Skill 能指揮 Agent 讀寫檔案和執行命令，請只新增可信來源。';

  @override
  String get set_agSkillNotLoaded => '未載入';

  @override
  String get set_agSkillShadowed => '已被同名 Skill 替代';

  @override
  String get set_agSkillErrDescription => 'SKILL.md 缺少 description，不會載入';

  @override
  String get set_agSkillErrName => '名稱只能用小寫字母、數字和單個連字元，最長 64 個字元';

  @override
  String get set_agSkillErrMissing => '資料夾裡沒有 SKILL.md';

  @override
  String get set_agSkillErrParse => '無法讀取 SKILL.md 頭部資訊';

  @override
  String get set_agSkillOpenFolder => '開啟資料夾';

  @override
  String get set_agSkillRemove => '刪除 Skill';

  @override
  String get set_agSkillCopy => '複製為我的 Skill';

  @override
  String get set_agSkillReadOnly => '內建 Skill 隨版本更新，不能直接編輯；複製後，同名的全域副本會替代它。';

  @override
  String get set_agSkillAddTitle => '新增 Skill 資料夾';

  @override
  String get set_agSkillPlace => '放到';

  @override
  String set_agSkillPlaceWorkspace(Object name) {
    return '當前工作區「$name」';
  }

  @override
  String get set_agSkillMode => '呼叫方式';

  @override
  String get set_agSkillCopyNote => '會複製進 Agent 資料目錄，原資料夾之後的修改不會自動同步。';

  @override
  String set_agSkillExists(Object name) {
    return '「$name」已存在，請先刪除或改名。';
  }

  @override
  String get set_agSkillPlaces => 'Skill 位置';

  @override
  String get set_agSkillPlacesTip => '每個子資料夾放一個 SKILL.md。同名時工作區優先，其次全域，最後內建。';

  @override
  String get set_agContext => '常駐上下文';

  @override
  String get set_agContextPrompt => '系統提示詞';

  @override
  String set_agContextSkills(Object n) {
    return 'Skill 目錄 · $n 項';
  }

  @override
  String set_agContextTools(Object n) {
    return '預設工具 $n 個';
  }

  @override
  String get set_agContextTip => 'tokens · 按字元估算';

  @override
  String get set_agFinalPending =>
      '當前沒有執行中的會話。以下是 Studio 組裝的部分；會話啟動時 Pi 還會追加 Skill 目錄、工作目錄和 MCP 服務列表。';

  @override
  String get ag_tabChat => '對話';

  @override
  String get ag_tabShelf => '產物';

  @override
  String get ag_tabMemory => '指令';

  @override
  String get ag_newChat => '新聊天';

  @override
  String get ag_more => '更多';

  @override
  String get ag_close => '收起';

  @override
  String get ag_chatsSearch => '搜尋聊天和工作區';

  @override
  String get ag_chatsSwitchWorkspace => '切換工作區';

  @override
  String get ag_chatsNewWorkspace => '新增工作區';

  @override
  String get ag_chatsNoMatch => '沒有匹配的聊天';

  @override
  String get ag_chatWaiting => '等確認';

  @override
  String get ag_chatRunning => '進行中';

  @override
  String get ag_menuRenameChat => '重新命名聊天';

  @override
  String get ag_menuRenameWorkspace => '重新命名工作區';

  @override
  String get ag_menuOpenFolder => '開啟工作區資料夾';

  @override
  String get ag_menuCompact => '壓縮上下文';

  @override
  String get ag_menuExport => '匯出聊天';

  @override
  String get ag_menuSettings => 'Agent 設定';

  @override
  String get ag_name => '名稱';

  @override
  String get ag_save => '儲存';

  @override
  String get ag_cancel => '取消';

  @override
  String get ag_failed => '操作沒有完成';

  @override
  String get ag_greetMorning => '上午好，今天畫什麼？';

  @override
  String get ag_greetAfternoon => '下午好，今天畫什麼？';

  @override
  String get ag_greetEvening => '晚上好，今天畫什麼？';

  @override
  String get ag_greetHint => 'Agent 會先看草稿再動手；花 Anlas 前一定先問你。';

  @override
  String get ag_draftEyebrow => '當前草稿';

  @override
  String ag_draftCounts(int characters, int blocks, int references) {
    return '角色 $characters · $blocks 個積木 · 參考圖 $references';
  }

  @override
  String get ag_taskReview => '檢查草稿';

  @override
  String get ag_taskReviewHint => '找衝突、冗餘和模型不認的寫法';

  @override
  String get ag_taskReviewPrompt => '檢查當前草稿和參數，找出衝突、冗餘和當前模型不認的寫法，先不要修改。';

  @override
  String get ag_taskAnalyze => '分析參考圖';

  @override
  String get ag_taskAnalyzeHint => '拆出畫風、構圖和可用標籤';

  @override
  String get ag_taskAnalyzePrompt => '分析我附上的參考圖：畫風、構圖、光影，以及能直接用的標籤，先不要生成。';

  @override
  String get ag_taskVariants => '批次變體';

  @override
  String get ag_taskVariantsHint => '改一處，出幾張對比';

  @override
  String get ag_taskVariantsPrompt =>
      '基於當前草稿，只改一個方向做幾組變體對比。先告訴我打算怎麼改和費用，等我確認再生成。';

  @override
  String get ag_taskBlocks => '整理積木';

  @override
  String get ag_taskBlocksHint => '把常用片段收進積木庫';

  @override
  String get ag_taskBlocksPrompt => '看看當前草稿裡哪些片段適合做成可複用的積木，列出建議，先不要修改。';

  @override
  String get ag_quickTitle => '快捷資訊';

  @override
  String get ag_quickEdit => '編輯快捷資訊';

  @override
  String get ag_quickSends => '點選直接傳送';

  @override
  String get ag_modeBypass => '完全權限';

  @override
  String get ag_modeBypassHint => '不再詢問，所有操作直接執行；花 Anlas 仍要確認';

  @override
  String get ag_bypassConfirmTitle => '切換到完全權限？';

  @override
  String get ag_bypassConfirmBody =>
      'Agent 將不再詢問，直接修改檔案、執行命令、呼叫未知工具，也能操作工作區以外的檔案。花 Anlas 的操作仍會先請你確認。只在你信任當前任務時使用。';

  @override
  String get ag_bypassConfirmOk => '切換';

  @override
  String get ag_bypassConfirmSilence => '不再提醒';

  @override
  String get ag_menuDeleteChat => '刪除對話';

  @override
  String get ag_menuDeleteWorkspace => '刪除工作區';

  @override
  String get ag_delete => '刪除';

  @override
  String get ag_deleteWorkspaceTitle => '刪除工作區？';

  @override
  String ag_deleteWorkspaceBody(String name) {
    return '工作區「$name」和裡面的全部對話會移進回收區，可以復原。生成的圖片仍保留在圖庫和歷史中。';
  }

  @override
  String ag_chatDeleted(String title) {
    return '已刪除「$title」';
  }

  @override
  String ag_workspaceDeleted(String name) {
    return '已刪除工作區「$name」';
  }

  @override
  String get ag_chatsContent => '內容匹配';

  @override
  String get ag_chatsSearching => '正在搜尋對話內容…';

  @override
  String get ag_imageVibe => '設為 Vibe';

  @override
  String get ag_imageReference => '設為精確參考';

  @override
  String get ag_imageParams => '載入參數';

  @override
  String get ag_imageFolder => '在資料夾中顯示';

  @override
  String get ag_imageVibeDone => '已加入 Vibe 參考';

  @override
  String get ag_imageReferenceDone => '已設為精確參考';

  @override
  String get ag_imageParamsDone => '已載入生成參數';

  @override
  String get ag_usageAnlas => '生圖花費（估算）';

  @override
  String get ag_deleteAgain => '再點一次刪除';

  @override
  String get ag_sloganBase =>
      '研磨顏料中…\n翻翻畫師冊…\n數一數 tag…\n斟酌權重中…\n對一下構圖…\n給角色擺個姿勢…\n削鉛筆中…\n調一調色溫…\n挑一支合適的筆刷…\n往調色盤裡擠顏料…\n退後兩步看看整體…\n鋪一層底色…\n把靈感捋一捋…\n找找參考…\n量一量比例…\n換個視角想想…\n把線條理順…\n抿一口咖啡…\n和光影商量一下…\n在草稿紙上比劃…';

  @override
  String get ag_sloganEgg =>
      '正在說服 AI 把手畫對…\n偷偷多畫了一根手指…又擦掉了\nAnlas 一分沒花（暫時）\n在畫布角落簽了個名…不行，擦掉\n和 Krita 交換眼神中…\n給貓耳找個好角度…\n數到第六根手指時停了下來…\nmasterpiece, best quality, 拜託了…';

  @override
  String get ag_sloganThink => '琢磨中…\n先在腦子裡畫一遍…\n換個角度想想…\n理一理思路…';

  @override
  String get ag_sloganRead => '翻資料中…\n查一查 tag 詞典…\n看看草稿寫了什麼…\n翻翻舊作…';

  @override
  String get ag_sloganRun => '敲命令中…\n讓終端跑一會兒…\n等指令碼跑完…';

  @override
  String get ag_sloganImage => '盯著圖看…\n端詳細節中…\n數數有幾個角色…\n湊近看看筆觸…';

  @override
  String get ag_sloganWrite => '落筆中…\n改提示詞中…\n擦掉重寫一筆…\n調一調權重…';

  @override
  String get ag_sloganGen => '上色中…\n等顯示卡吃飯…\n顏料還沒幹…\n烘乾畫布中…';

  @override
  String get ag_sloganExternal => '和外部工具對暗號…\n等外面回話…';

  @override
  String get ag_foldDone => '已處理';

  @override
  String ag_foldTimes(String label, int count) {
    return '$label $count 次';
  }

  @override
  String get ag_kindThink => '思考';

  @override
  String get ag_kindRead => '讀取';

  @override
  String get ag_kindRun => '執行命令';

  @override
  String get ag_kindImage => '看圖';

  @override
  String get ag_kindWrite => '修改';

  @override
  String get ag_kindGen => '生圖';

  @override
  String get ag_kindExternal => '外部工具';

  @override
  String get ag_kindAsk => '問你';

  @override
  String ag_limitTitle(int count) {
    return '已達到單次任務步數上限（$count 步）';
  }

  @override
  String get ag_limitBody => '進度已儲存，點“繼續”接著做。上限可以在設定裡調整。';

  @override
  String get ag_limitContinue => '繼續';

  @override
  String get ag_limitAdjust => '調整上限';

  @override
  String get ag_continueMessage => '繼續';

  @override
  String get ag_diffExpand => '展開全部';

  @override
  String get ag_diffCollapse => '收起';

  @override
  String ag_readImages(int count) {
    return '檢視圖片 · $count 張';
  }

  @override
  String ag_turnTook(String time) {
    return '用時 $time';
  }

  @override
  String ag_turnAnlas(String anlas) {
    return '$anlas Anlas';
  }

  @override
  String ag_turnChanges(int count) {
    return '改動 $count 處';
  }

  @override
  String ag_turnTools(int count) {
    return '工具 $count 次';
  }

  @override
  String ag_turnTokens(String input, String output) {
    return '輸入 $input · 輸出 $output token';
  }

  @override
  String get ag_settingsTitle => '應用設定';

  @override
  String get ag_settingsGo => '去設定';

  @override
  String ag_tagCopied(String tag) {
    return '已複製 $tag';
  }

  @override
  String ag_tagCount(String count) {
    return '$count 張作品';
  }

  @override
  String ag_galleryFavorite(int count) {
    return '已收藏 $count 張';
  }

  @override
  String ag_galleryUnfavorite(int count) {
    return '已取消收藏 $count 張';
  }

  @override
  String ag_galleryTags(int count) {
    return '已改標籤 $count 張';
  }

  @override
  String ag_galleryMove(int count, String target) {
    return '已移動 $count 張到「$target」';
  }

  @override
  String ag_galleryCopy(int count, String target) {
    return '已複製 $count 張到「$target」';
  }

  @override
  String ag_galleryDelete(int count) {
    return '已移到回收區 $count 張';
  }

  @override
  String ag_galleryRestore(int count) {
    return '已恢復 $count 張';
  }

  @override
  String ag_galleryCollectionAdd(int count, String target) {
    return '已加入集合「$target」$count 張';
  }

  @override
  String ag_galleryCollectionRemove(int count, String target) {
    return '已移出集合「$target」$count 張';
  }

  @override
  String ag_galleryExport(int count) {
    return '已匯出 $count 張';
  }

  @override
  String ag_galleryMore(int count) {
    return '+$count';
  }

  @override
  String get ag_compacted => '之前的對話已壓縮';

  @override
  String get ag_compactedAuto => '上下文快滿了，之前的對話已自動壓縮';

  @override
  String ag_compactedTokens(String tokens) {
    return '原 $tokens token';
  }

  @override
  String get ag_compactedShow => '看摘要';

  @override
  String get ag_compactedHide => '收起摘要';

  @override
  String get ag_editResend => '傳送';

  @override
  String get ag_editHint => '傳送後，這條之後的對話會被替換';

  @override
  String get ag_editRemoveImage => '去掉這張圖';

  @override
  String get set_agTrash => '回收區';

  @override
  String get set_agTrashSub => '刪除的對話、工作區和 Skill 先放進回收區，可以恢復；徹底刪除後不能找回。';

  @override
  String get set_agTrashManage => '管理';

  @override
  String set_agTrashSummary(int count, String size) {
    return '$count 項 · $size';
  }

  @override
  String get set_agTrashEmpty => '回收區是空的';

  @override
  String get set_agTrashAll => '全部';

  @override
  String get set_agTrashChats => '對話';

  @override
  String get set_agTrashWorkspaces => '工作區';

  @override
  String get set_agTrashSkills => 'Skill';

  @override
  String get set_agTrashRestore => '恢復';

  @override
  String get set_agTrashPurge => '徹底刪除';

  @override
  String get set_agTrashPurgeAll => '清空回收區';

  @override
  String get set_agTrashPurgeTitle => '徹底刪除？';

  @override
  String set_agTrashPurgeBody(String name) {
    return '「$name」會從磁碟上刪除，不能找回。';
  }

  @override
  String set_agTrashPurgeAllBody(int count) {
    return '回收區裡的 $count 項會從磁碟上刪除，不能找回。';
  }

  @override
  String set_agTrashRestored(String name) {
    return '已恢復「$name」';
  }

  @override
  String set_agTrashPurged(String name) {
    return '已徹底刪除「$name」';
  }

  @override
  String get set_agTrashNeedWorkspace => '所屬工作區也在回收區裡，先恢復工作區';

  @override
  String get set_agTrashRestoreFailed => '恢復失敗：原位置已有同名內容';

  @override
  String get set_agTrashGoneWorkspace => '已刪除的工作區';

  @override
  String set_agSkillRemoveBody(String name) {
    return '「$name」會移進回收區，之後可以在 Agent 設定的「回收區」裡恢復或徹底刪除。';
  }

  @override
  String get set_agSkillName => '名稱';

  @override
  String get set_agSkillNewHelp =>
      '只用小寫字母、數字和連字元，例如 watercolor-style。建好後會開啟它的資料夾，編輯裡面的 SKILL.md 即可。';

  @override
  String get set_agSkillCreate => '建立';

  @override
  String get set_agSkillAddConfirm => '新增';

  @override
  String set_agPromptStats(String chars, String tokens) {
    return '$chars 字元 · 約 $tokens token';
  }

  @override
  String get set_agFinalLive => '當前會話實際發給模型的完整系統提示詞。';

  @override
  String get set_agBuiltinSub => 'Studio 內建的基礎提示詞，隨版本更新。';

  @override
  String get set_agMcpEditTitle => '編輯 MCP 伺服器';

  @override
  String get set_agTabGeneral => '常規';

  @override
  String get set_agTabTools => '工具與擴展';

  @override
  String get blocks_viewMasonry => '瀑布流';

  @override
  String get blocks_groupByFolder => '按資料夾分組';

  @override
  String get mp_bodyTag => '請求主體';

  @override
  String get mp_headerTag => '請求標頭';

  @override
  String get ag_recent => '最近';

  @override
  String get ag_you => '你';

  @override
  String get ag_edit => '編輯';

  @override
  String get ag_copy => '複製';

  @override
  String get ag_copied => '已複製';

  @override
  String get ag_regenerate => '重新回答';

  @override
  String get ag_starting => '正在開啟聊天';

  @override
  String get ag_waitingSlot => '等服務商額度';

  @override
  String get ag_waitingYou => '等你處理';

  @override
  String get ag_stepFailed => '失敗';

  @override
  String get ag_stepArguments => '參數';

  @override
  String get ag_stepResult => '結果';

  @override
  String ag_stepsMore(int count) {
    return '還有 $count 步';
  }

  @override
  String get ag_tool_studio_context => '讀取當前草稿';

  @override
  String get ag_tool_image_read => '檢視圖片';

  @override
  String get ag_tool_prompt_update => '改寫提示詞';

  @override
  String get ag_tool_snapshot => '草稿快照';

  @override
  String get ag_tool_wiki_query => '查百科';

  @override
  String get ag_tool_tag_query => '查標籤';

  @override
  String get ag_tool_block_query => '查積木';

  @override
  String get ag_tool_block_manage => '整理積木';

  @override
  String get ag_tool_settings_read => '讀取設定';

  @override
  String get ag_tool_settings_update => '修改設定';

  @override
  String get ag_tool_explore_manage => '畫風探索';

  @override
  String get ag_tool_generation_prepare => '準備生成';

  @override
  String get ag_tool_generation_run => '生成圖片';

  @override
  String get ag_tool_generation_cancel => '取消生成';

  @override
  String get ag_tool_gallery_query => '查圖庫';

  @override
  String get ag_tool_gallery_manage => '整理圖庫';

  @override
  String get ag_tool_reference_manage => '設定參考圖';

  @override
  String get ag_tool_reference_library => '參考圖庫';

  @override
  String get ag_tool_image_tool => '影像工具';

  @override
  String get ag_tool_studio_search => '語義搜尋';

  @override
  String get ag_tool_image_generate => '變體 / 增強';

  @override
  String get ag_tool_ask_user => '向你提問';

  @override
  String get ag_tool_read => '讀檔案';

  @override
  String get ag_tool_write => '寫檔案';

  @override
  String get ag_tool_edit => '改檔案';

  @override
  String get ag_tool_bash => '執行命令';

  @override
  String get ag_field_prompt => '基礎提示詞';

  @override
  String get ag_field_negative => '負面提示詞';

  @override
  String get ag_field_character => '角色提示詞';

  @override
  String get ag_field_characterNegative => '角色負面';

  @override
  String get ag_diffApplied => '已寫入';

  @override
  String get ag_diffUndone => '已復原';

  @override
  String ag_changeSummary(int count) {
    return '本次改動 · $count 處';
  }

  @override
  String get ag_diffUndoAll => '全部復原';

  @override
  String get ag_paramTitle => '生圖參數';

  @override
  String ag_paramCount(int count) {
    return '$count 項';
  }

  @override
  String get ag_paramSize => '尺寸';

  @override
  String get ag_paramTransparent => '透明背景';

  @override
  String get ag_paramNone => '無';

  @override
  String get ag_positionTitle => '角色位置';

  @override
  String get ag_positionApplied => '已調整';

  @override
  String get ag_positionNone => '未定位';

  @override
  String get ag_positionAiHint => '當前為 AI 選擇，座標不生效，由模型自行安排位置。';

  @override
  String ag_positionRestSame(int count) {
    return '其餘 $count 人位置未變';
  }

  @override
  String ag_positionAllSame(int count) {
    return '$count 人位置未變';
  }

  @override
  String get ag_posTopLeft => '左上';

  @override
  String get ag_posTop => '中上';

  @override
  String get ag_posTopRight => '右上';

  @override
  String get ag_posLeft => '左中';

  @override
  String get ag_posCenter => '正中';

  @override
  String get ag_posRight => '右中';

  @override
  String get ag_posBottomLeft => '左下';

  @override
  String get ag_posBottom => '中下';

  @override
  String get ag_posBottomRight => '右下';

  @override
  String get ag_positionNudge => '微調';

  @override
  String get ag_positionNew => '新增';

  @override
  String get ag_diffLocked => '草稿已再次修改';

  @override
  String get ag_diffUndo => '復原';

  @override
  String ag_diffCounts(int added, int removed) {
    return '+$added −$removed';
  }

  @override
  String get ag_outputs => '本次產物';

  @override
  String ag_anlasSpent(String anlas) {
    return '已用 $anlas Anlas';
  }

  @override
  String get ag_imageReveal => '在歷史中顯示';

  @override
  String get ag_imageAttach => '附到輸入框';

  @override
  String get ag_imageZoom => '放大檢視';

  @override
  String ag_askHint(int count) {
    return '按 1–$count';
  }

  @override
  String get ag_askOther => '其他想法…';

  @override
  String get ag_askSubmit => '回答';

  @override
  String get ag_askSkip => '跳過';

  @override
  String ag_approvalTitle(String tool) {
    return '需要你允許 · $tool';
  }

  @override
  String ag_gateTitle(String action) {
    return '需要你確認 · $action';
  }

  @override
  String ag_gateText2img(int count) {
    return '生成 $count 張';
  }

  @override
  String ag_gateImg2img(int count) {
    return '圖生圖 $count 張';
  }

  @override
  String ag_gateInpaint(int count) {
    return '重繪 $count 張';
  }

  @override
  String ag_gateVariations(int count) {
    return '變體 $count 張';
  }

  @override
  String get ag_gateEnhance => '增強';

  @override
  String get ag_gateModelSize => '模型 · 尺寸';

  @override
  String get ag_gateRequests => '請求';

  @override
  String ag_gateRequestsValue(int requests, int batch) {
    return '$requests 次 × $batch 張';
  }

  @override
  String get ag_gateUnit => '單價';

  @override
  String get ag_gateEncoding => '參考圖編碼';

  @override
  String get ag_gateAccount => '帳號';

  @override
  String ag_gateTotal(String balance) {
    return '合計 · 餘額 $balance';
  }

  @override
  String get ag_gateTotalNoBalance => '合計';

  @override
  String get ag_gateConfirm => '確認並生成';

  @override
  String get ag_gateConfirmTool => '確認並執行';

  @override
  String get ag_gateChanged => '配置或報價已變化，請讓 Agent 重新準備';

  @override
  String get ag_gateExpired => '報價已失效';

  @override
  String get ag_gateEstimate => '預估，以服務端扣費為準';

  @override
  String get ag_placeholder => '告訴 Agent 要做什麼 · @ 引用 · / 技能';

  @override
  String get ag_dropHint => '鬆開以附加到這條訊息';

  @override
  String ag_importing(int count) {
    return '正在新增 $count 張圖片…';
  }

  @override
  String get ag_attach => '新增圖片';

  @override
  String get ag_attachFile => '從檔案選擇…';

  @override
  String get ag_attachCanvas => '附上畫布當前圖片';

  @override
  String get ag_attachPaste => '貼上剪貼簿圖片';

  @override
  String get ag_mention => '引用';

  @override
  String get ag_attachmentRemove => '移除';

  @override
  String get ag_attachmentBroken => '讀取失敗';

  @override
  String ag_imageInfoSteps(int count) {
    return '$count 步';
  }

  @override
  String ag_imageInfoRescale(String value) {
    return '重縮放 $value';
  }

  @override
  String ag_imageInfoSeed(String seed) {
    return '種子 $seed';
  }

  @override
  String ag_imageInfoCharacters(int count) {
    return '$count 個角色';
  }

  @override
  String get ag_send => '傳送';

  @override
  String get ag_sendQueue => '排隊傳送';

  @override
  String get ag_sendSteer => '作為引導插入';

  @override
  String get ag_sendQueueHint => '等當前任務做完再處理';

  @override
  String get ag_sendSteerHint => '在下一次模型請求前插入';

  @override
  String get ag_stop => '停止';

  @override
  String get ag_noModel => '先選一個能用工具的模型';

  @override
  String get ag_queued => '排隊';

  @override
  String get ag_steering => '引導';

  @override
  String get ag_recovered => '上次沒發出';

  @override
  String get ag_queueSteer => '轉引導';

  @override
  String get ag_queueEdit => '編輯';

  @override
  String get ag_queueWithdraw => '撤回';

  @override
  String get ag_queueRestore => '放回輸入框';

  @override
  String get ag_newContent => '回到最新';

  @override
  String get ag_modeReadonly => '只讀';

  @override
  String get ag_modeAsk => '詢問';

  @override
  String get ag_modeAuto => '自動';

  @override
  String get ag_modeReadonlyHint => '只讀取和討論；不修改、不生成';

  @override
  String get ag_modeAskHint => '修改、命令和未知工具先問你';

  @override
  String get ag_modeAutoHint => '工作區內的常規修改直接執行；花錢仍要確認';

  @override
  String get ag_modelPicker => '選擇模型';

  @override
  String get ag_modelSettings => '管理模型與介面…';

  @override
  String get ag_modelNone => '未選擇模型';

  @override
  String get ag_thinkingTitle => '思考強度 · 下次任務生效';

  @override
  String get ag_thinkingFollow => '使用模型設定';

  @override
  String get ag_thinkingUnsupported => '這個模型沒有可調的思考檔位';

  @override
  String get ag_usageTitle => '上下文與用量';

  @override
  String get ag_usageContext => '當前上下文 · 估算';

  @override
  String get ag_usageUnknown => '等模型返回用量後顯示';

  @override
  String ag_usageRemaining(String tokens) {
    return '剩餘 $tokens';
  }

  @override
  String get ag_usageSession => '本聊天累計';

  @override
  String get ag_usageInput => '輸入';

  @override
  String get ag_usageOutput => '輸出';

  @override
  String get ag_usageCacheRead => '快取讀取';

  @override
  String get ag_usageCacheWrite => '快取寫入';

  @override
  String get ag_usageTotal => '累計 tokens';

  @override
  String get ag_usageMessages => '訊息 · 工具呼叫';

  @override
  String get ag_usageCost => '費用以服務商賬單為準';

  @override
  String get ag_usageCompact => '壓縮上下文';

  @override
  String ag_shelfAll(int count) {
    return '全部 $count';
  }

  @override
  String ag_shelfGenerated(int count) {
    return '生成 $count';
  }

  @override
  String ag_shelfAttachments(int count) {
    return '附件 $count';
  }

  @override
  String ag_shelfFiles(int count) {
    return '檔案 $count';
  }

  @override
  String get ag_shelfFilesTitle => '檔案';

  @override
  String get ag_shelfHint => '點圖放大 · 拖到畫布';

  @override
  String get ag_shelfEmpty => '這個聊天還沒有產物';

  @override
  String get ag_shelfEmptyHint => 'Agent 生成的圖、你附上的圖和它寫的檔案都會收在這裡。';

  @override
  String get ag_memoryGlobal => '全域指令';

  @override
  String get ag_memoryWorkspace => '本工作區規則';

  @override
  String get ag_memorySkills => '生效的 Skill';

  @override
  String get ag_memoryEmpty => '還沒寫';

  @override
  String get ag_memoryEdit => '編輯';

  @override
  String get ag_memoryHint => '這些內容每次都會交給 Agent。改動從下一條訊息開始生效。';

  @override
  String get ag_mentionAll => '全部';

  @override
  String get ag_mentionDraft => '草稿';

  @override
  String get ag_mentionImages => '圖片';

  @override
  String get ag_mentionBlocks => '積木';

  @override
  String get ag_mentionTitle => '引用到這條訊息';

  @override
  String get ag_mentionEmpty => '沒有匹配的內容';

  @override
  String get ag_mentionSearchBlocks => '搜尋積木';

  @override
  String get ag_keySelect => '選擇';

  @override
  String get ag_keyInsert => '插入';

  @override
  String get ag_keyCategory => '切類別';

  @override
  String get ag_keyClose => '關閉';

  @override
  String get ag_dismiss => '知道了';

  @override
  String get ag_retry => '重試';

  @override
  String get ag_initFailed => 'Agent 沒能啟動';

  @override
  String get ag_toggle => 'NAI Agent';

  @override
  String get ag_yesterday => '昨天';

  @override
  String get ag_attachmentTag => '附件';

  @override
  String get ag_zoomClose => '關閉';

  @override
  String get ag_thought => '已思考';

  @override
  String get ag_thinkingLive => '思考中';

  @override
  String ag_thoughtChars(int count) {
    return '$count 字';
  }

  @override
  String get mp_protocol => '介面協定';

  @override
  String get mp_test => '測試';

  @override
  String get mp_testing => '測試中…';

  @override
  String get mp_notChecked => '未檢測';

  @override
  String get mp_rename => '重新命名';

  @override
  String get mp_request => '請求';

  @override
  String get mp_requestSub => '所有模型共用';

  @override
  String get mp_timeout => '請求逾時';

  @override
  String get mp_timeoutHelp => '單次請求最長等待時間，10–600 秒';

  @override
  String get mp_concurrency => '最大併發';

  @override
  String get mp_concurrencyHelp => '此服務同時處理的請求數，1–20';

  @override
  String get mp_retry => '失敗重試';

  @override
  String get mp_retryHelp => '連線失敗或服務繁忙時重試';

  @override
  String get mp_retryOff => '關';

  @override
  String get mp_seconds => '秒';

  @override
  String get mp_countUnit => '個';

  @override
  String get mp_headers => '自訂請求標頭';

  @override
  String get mp_none => '無';

  @override
  String get mp_addHeader => '新增請求標頭';

  @override
  String get mp_headerName => '名稱';

  @override
  String get mp_value => '值';

  @override
  String get mp_added => '已新增';

  @override
  String get mp_catalog => '服務商目錄';

  @override
  String get mp_filter => '篩選';

  @override
  String get mp_manualAdd => '手動新增';

  @override
  String get mp_dragHint => '拖動排序決定功能分配裡的預設順序';

  @override
  String get mp_noModels => '還沒有模型';

  @override
  String get mp_noModelsSub => '從服務商目錄新增，或手動輸入模型 ID';

  @override
  String get mp_manualHint => '輸入模型 ID，回車新增';

  @override
  String get mp_model => '模型';

  @override
  String get mp_alias => '顯示別名';

  @override
  String get mp_aliasHint => '例如 fast';

  @override
  String get mp_context => '上下文視窗';

  @override
  String get mp_maxOutput => '最大輸出';

  @override
  String get mp_outputTooLarge => '輸出不能超過上下文視窗';

  @override
  String get mp_thinking => '思考';

  @override
  String get mp_levels => '可調檔位';

  @override
  String get mp_defaultLevel => '預設檔位';

  @override
  String get mp_defaultBadge => '預設';

  @override
  String get mp_followService => '跟隨服務';

  @override
  String get mp_reasoningProtocol => '思考協定';

  @override
  String get mp_standard => '標準';

  @override
  String get mp_adaptive => '自適應';

  @override
  String get mp_protocolNoReasoning => '此介面協定不支援思考調節';

  @override
  String get mp_unconfirmed => '未確認';

  @override
  String get mp_unsupported => '不支援';

  @override
  String get mp_capabilities => '能力';

  @override
  String get mp_capVision => '圖片輸入';

  @override
  String get mp_capTools => '工具呼叫';

  @override
  String get mp_capSearch => '原生聯網搜尋';

  @override
  String get mp_bodyHeaders => '請求主體與請求標頭';

  @override
  String get mp_notAdded => '未新增';

  @override
  String get mp_field => '請求主體';

  @override
  String get mp_header => '請求標頭';

  @override
  String get mp_testModel => '測試此模型';

  @override
  String get mp_copyId => '複製模型 ID';

  @override
  String get mp_removeModel => '移除模型';

  @override
  String mp_removeTitle(Object id) {
    return '移除模型“$id”？';
  }

  @override
  String get mp_removeBody => '用到它的功能會回落到其他可用模型。';

  @override
  String get mp_catalogId => '模型 ID';

  @override
  String get mp_catalogCtx => '上下文';

  @override
  String get mp_catalogPrice => '輸入 / 輸出 · 百萬';

  @override
  String mp_catalogFooter(Object n, Object total, Object when) {
    return '匹配 $n 個 · 共 $total 個 · $when 取得';
  }

  @override
  String mp_catalogMore(Object n) {
    return '還有 $n 個，輸入篩選縮小範圍';
  }

  @override
  String get mp_catalogIdle => '還沒讀取過目錄';

  @override
  String get mp_catalogIdleSub => '用已儲存的地址和 Key 讀取這個服務商提供的模型';

  @override
  String get mp_catalogLoading => '正在讀取模型目錄…';

  @override
  String mp_catalogFailed(Object error) {
    return '目錄不可用：$error';
  }

  @override
  String get mp_fetch => '取得列表';

  @override
  String get mp_noMatch => '沒有匹配的模型';

  @override
  String mp_picked(Object n) {
    return '已選 $n 個';
  }

  @override
  String get mp_pickEmpty => '在左邊勾選要新增的模型';

  @override
  String get mp_pickHint => '能力、上下文和思考檔位按本地目錄預填，新增後可在右側逐項調整。';

  @override
  String mp_addPicked(Object n) {
    return '新增 $n 個模型';
  }

  @override
  String get mp_new => '新';

  @override
  String mp_unsaved(Object name, Object n) {
    return '$name 有 $n 項修改未儲存';
  }

  @override
  String get mp_saving => '正在儲存…';

  @override
  String get mp_conflict => '配置已在別處修改：已合併最新值，確認後再儲存';

  @override
  String get mp_saveFailed => '儲存失敗，修改已保留';

  @override
  String mp_invalid(Object n) {
    return '有 $n 處需要修正';
  }

  @override
  String get mp_leaveBody => '服務商配置還沒儲存，離開這一頁會丟掉修改。';

  @override
  String get mp_show => '顯示';

  @override
  String get mp_hide => '隱藏';

  @override
  String get mp_keyHintLocal => '本機服務可留空';

  @override
  String get mp_keyHint => '輸入此服務商的 Key';

  @override
  String get mp_pickerTitle => '新增服務商';

  @override
  String get mp_pickerSearch => '搜尋廠商、平臺或本地服務';

  @override
  String get mp_groupAll => '全部';

  @override
  String get mp_groupDomestic => '國內';

  @override
  String get mp_groupInternational => '國際';

  @override
  String get mp_groupAggregator => '聚合';

  @override
  String get mp_groupLocal => '本地';

  @override
  String get mp_groupDomesticFull => '國內廠商';

  @override
  String get mp_groupInternationalFull => '國際廠商';

  @override
  String get mp_groupAggregatorFull => '聚合平臺';

  @override
  String get mp_groupLocalFull => '本地與自訂';

  @override
  String get mp_pickerFoot => '地址與協定會按預設填好；同一廠商可以新增多次（例如國內 / 國際區域）。';

  @override
  String get mp_pickerNext => '下一步：填寫 Key';

  @override
  String get mp_duplicateKey => '請求欄位名稱重複。';

  @override
  String get mp_retryRange => '失敗重試次數必須為 0–3 次。';

  @override
  String get mp_catalogCacheFailed => '無法儲存模型目錄快取。';

  @override
  String get mp_errorAuthentication => 'API Key 無效';

  @override
  String get mp_errorPermission => '無存取權限';

  @override
  String get mp_errorTimeout => '請求逾時';

  @override
  String get mp_errorNetwork => '連線不可用';

  @override
  String get mp_errorResponse => '回應無效';

  @override
  String get mp_errorHttp => '請求失敗';

  @override
  String get mp_errorRateLimit => '請求過於頻繁';

  @override
  String get ag_tool_prompt_set => '提示片語';

  @override
  String ag_psCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String ag_psPosition(int index, int count, String unit) {
    return '第 $index $unit / 共 $count $unit';
  }

  @override
  String get ag_psOverview => '總覽全部';

  @override
  String get ag_psSingle => '回到單項';

  @override
  String get ag_psPrompt => '提示詞';

  @override
  String get ag_psShared => '共同設定';

  @override
  String ag_psThisItem(String unit) {
    return '這一$unit';
  }

  @override
  String get ag_psMain => '主提示詞';

  @override
  String ag_psCharacter(int index) {
    return '角色 $index';
  }

  @override
  String get ag_psNegative => '負面';

  @override
  String get ag_psImport => '匯入畫布';

  @override
  String get ag_psImportTip => '寫入主提示詞、角色和負面；參數和參考圖不變';

  @override
  String ag_psImported(String title) {
    return '已把「$title」寫入提示詞';
  }

  @override
  String get ag_psGenerate => '生成';

  @override
  String get ag_psGenerating => '生成中';

  @override
  String ag_psRevision(int revision, int count) {
    return 'v$revision · 已改 $count 項';
  }

  @override
  String get ag_psSaveBlock => '存成積木';

  @override
  String ag_psSavedBlock(String title, int count) {
    return '已存成積木「$title」· $count 項';
  }

  @override
  String ag_psCopyItem(String unit) {
    return '複製這一$unit的提示詞';
  }

  @override
  String get ag_psCopyAll => '複製全部';

  @override
  String ag_psEditItem(String unit) {
    return '讓 Agent 修改這一$unit';
  }

  @override
  String ag_psEditDraft(String title, int index, String unit, String item) {
    return '修改「$title」第 $index $unit（$item）：';
  }

  @override
  String ag_psTooManyCharacters(int count) {
    return '當前模型最多支援 $count 個角色';
  }

  @override
  String get ag_psNoCharacters => '當前模型不支援角色提示詞';

  @override
  String get ag_psMissing => '這張卡的資料已不在';

  @override
  String get startup_dataTitle => '無法準備應用資料';

  @override
  String get startup_dataHelp =>
      '應用資料尚未準備完成，請保留現有檔案。內容不同的檔案不會合並或覆蓋。請先備份並核對資料目錄，檢查磁碟空間和存取權限，再重試。';

  @override
  String get startup_dataCurrent => '當前資料目錄';

  @override
  String get startup_dataLegacy => '舊資料目錄';

  @override
  String get startup_dataOpenCurrent => '開啟當前目錄';

  @override
  String get startup_dataOpenLegacy => '開啟舊目錄';

  @override
  String get startup_dataDetails => '錯誤詳情';

  @override
  String startup_dataActionFailed(String error) {
    return '操作失敗：$error';
  }

  @override
  String get blocks_expandToText => '展開為文本';

  @override
  String get ag_answeredTitle => '向你提問 · 已回答';

  @override
  String get ag_historyButton => '歷史';

  @override
  String get ag_historyTitle => '對話歷史';

  @override
  String get ag_historySearch => '搜尋發言和卡片…';

  @override
  String get ag_historyAll => '全部';

  @override
  String get ag_historyMine => '我的發言';

  @override
  String get ag_historyCards => '卡片';

  @override
  String get ag_historyQuestions => '問答';

  @override
  String get ag_historyEmpty => '沒有匹配的條目';

  @override
  String get ag_historyBeforeCompaction => '這段在壓縮之前，點看摘要';

  @override
  String get ag_historyAuto => '自動壓縮';

  @override
  String get ag_historyManual => '手動壓縮';

  @override
  String get ag_historyImageMessage => '圖片訊息';

  @override
  String ag_historyAnswer(String answer) {
    return '你選了：$answer';
  }

  @override
  String get ag_historyPromptSet => '提示片語';

  @override
  String ag_historyImages(int count) {
    return '生成卡 · $count 張';
  }

  @override
  String get ag_historyPromptChange => '提示詞修改';

  @override
  String get ag_historyParams => '生成參數';

  @override
  String get ag_historyPositions => '角色位置';

  @override
  String get ag_historySettings => '設定修改';

  @override
  String get ag_historyGallery => '圖庫卡片';

  @override
  String get ag_historyChanges => '修改摘要';

  @override
  String get gen_translateTapOriginal => '點按：顯示原文';

  @override
  String get gen_translateTapTranslated => '點按：顯示譯文';

  @override
  String get gen_translateClearRestore => '清除翻譯塊並還原';

  @override
  String get gen_translateClearRestoreSub => '全部變回普通原文，可復原';

  @override
  String get gen_translateCleared => '已清除翻譯塊並還原原文';

  @override
  String get gen_translateAdjust => '追加翻譯調整';

  @override
  String get gen_translateAdjustSub => '接著這次翻譯聊，重切、重譯、合併塊';

  @override
  String get gen_translateAdjustTitle => '翻譯調整';

  @override
  String gen_translateAdjustContext(int count) {
    return '續接本次翻譯 · $count 塊';
  }

  @override
  String gen_translateAdjustSelected(int count) {
    return '已選 $count 塊';
  }

  @override
  String get gen_translateAdjustCollapse => '收起 / 展開';

  @override
  String get gen_translateAdjustIntro => '接著本次翻譯調整。點選左側翻譯塊新增引用，改塊後可以復原。';

  @override
  String get gen_translateAdjustSplit => '重新切塊';

  @override
  String get gen_translateAdjustRetranslate => '重譯選中';

  @override
  String get gen_translateAdjustMerge => '合併選中';

  @override
  String get gen_translateAdjustSplitTemplate => '讀取當前塊，按語義細分引用的塊，保留精確原文。';

  @override
  String get gen_translateAdjustRetranslateTemplate => '讀取當前塊，重新翻譯引用的塊，不改原文。';

  @override
  String get gen_translateAdjustMergeTemplate => '讀取當前塊，按指定的原文順序合併引用的塊，無關塊不動。';

  @override
  String get gen_translateAdjustMarkers =>
      '請使用 translation_blocks_read 返回的 marker 列表。';

  @override
  String get gen_translateAdjustHint => '接著說要怎麼調整…';

  @override
  String get gen_translateAdjustStartFailed => '無法啟動翻譯調整，請檢查模型與 Agent 執行時。';

  @override
  String get gen_translateAdjustRunFailed => '調整已中止或失敗，重試前請重新讀取當前塊。';

  @override
  String gen_repeatDragTotal(int times, int total) {
    return '$times 次 · 共 $total 張';
  }

  @override
  String get set_cvGroupBatches => '批次結果按批次分組';

  @override
  String get set_cvGroupBatchesSub =>
      '關閉後每張圖單獨顯示，點歷史縮圖直接看那一張。隻影響簡潔檢視器；無限畫布始終按批次排列。';

  @override
  String get gen_groupBatches => '分組';

  @override
  String get gen_translateAdjustPickHint => '在左側點塊可引用';

  @override
  String get gen_translateAdjustClearRefs => '清除引用';

  @override
  String gen_translateAdjustSplitInto(String source, int count) {
    return '$source → $count 塊';
  }

  @override
  String get gen_translateAdjustContextNote => '上下文：本次翻譯的原文、切塊和譯文';

  @override
  String ag_historyStats(int messages, int cards) {
    return '$messages 條發言 · $cards 張卡片';
  }

  @override
  String get ag_historyKeySelect => '選擇';

  @override
  String get ag_historyKeyJump => '跳到對話';

  @override
  String get ag_historyKeyClose => '關閉';

  @override
  String get blocks_tempLabel => '臨時塊';

  @override
  String blocks_tempEditedByAgent(String time) {
    return 'Agent$time 改過這裡。';
  }

  @override
  String blocks_tempEditedByYou(String time) {
    return '你$time 改過這裡。';
  }

  @override
  String blocks_tempExplain(String title) {
    return '它已和塊庫裡的「$title」斷開，改動只留在這個位置，塊庫和其他提示詞裡的同名塊不受影響。';
  }

  @override
  String get blocks_tempEdit => '編輯';

  @override
  String get blocks_tempCompare => '對比原塊';

  @override
  String get blocks_tempAdded => '新增';

  @override
  String blocks_tempAddedCount(int count) {
    return '新增 $count 個詞';
  }

  @override
  String get blocks_tempAddedNone => '沒有新增';

  @override
  String get blocks_tempRemoved => '刪除';

  @override
  String blocks_tempRemovedHint(int count) {
    return '刪了 $count 個詞';
  }

  @override
  String get blocks_tempRemovedNone => '沒有刪除';

  @override
  String get blocks_tempRevert => '還原為原塊';

  @override
  String get blocks_tempKeepEditing => '繼續編輯';

  @override
  String get blocks_tempApply => '應用修改';

  @override
  String get blocks_tempSaveAs => '另存為新塊';

  @override
  String get blocks_tempSaveAsHint => '另存為新塊後，這裡會換成新塊，原塊保持不變';

  @override
  String get blocks_tempSaveConfirm => '儲存並轉正';

  @override
  String get blocks_tempShowOriginal => '在塊庫中檢視原塊';

  @override
  String get gen_menuNew => '新';

  @override
  String get gen_repeatDragHint => '按住數字左右拖動調節 · 雙擊直接輸入';

  @override
  String get gen_groupBatchesOn => '按批次分組 · 點選改為逐張顯示';

  @override
  String get gen_groupBatchesOff => '逐張顯示 · 點選按批次分組';

  @override
  String get blocks_presetCustom => '自訂';

  @override
  String get blocks_presetHint =>
      '應用附帶參數時品質詞和負面預設一併還原。換到別的模型時，檔位按目標模型自動換算；Turbo 沿用現有處理。';

  @override
  String get gen_vibeInpaintUnsupported => 'Vibe 不支援局部重繪（Inpainting），本次不會生效。';

  @override
  String get set_stThumbnailCacheLimit => '縮圖快取上限';

  @override
  String get set_stThumbnailCacheLimitSub =>
      '所有圖庫目錄合計。啟動或手動清理時，從最久沒看的縮圖刪到上限的 80%，不碰原圖。';

  @override
  String get ag_slashGroupSkills => 'Skill';

  @override
  String get ag_slashGroupTemplates => '提示詞範本';

  @override
  String get ag_slashGroupBuiltin => 'Studio 命令';

  @override
  String get ag_commandNew => '新增對話';

  @override
  String get ag_commandCompact => '壓縮上下文';

  @override
  String get ag_commandModel => '選擇模型';

  @override
  String get ag_commandThinking => '選擇思考檔位';

  @override
  String get ag_commandHistory => '開啟會話歷史';

  @override
  String get ag_commandRename => '重新命名當前對話';

  @override
  String get ag_commandCopy => '複製最後一條回覆';

  @override
  String get ag_commandExport => '匯出當前會話';

  @override
  String get ag_commandCompactArgs => '[說明]';

  @override
  String get ag_commandRenameArgs => '<名稱>';

  @override
  String get set_agNextSuggestion => '下一句建議';

  @override
  String get set_agNextSuggestionSub =>
      '使用當前對話模型預測你的下一句訊息，會額外消耗 token；按 Tab 採納。';

  @override
  String get set_agCacheWarming => '提示快取預熱';

  @override
  String get set_agCacheWarmingSub =>
      '在提示快取快過期前用 1 token 的請求續上（按 5 分鐘壽命，適配所有模型），下一步讀快取而不是重發整段上下文。';

  @override
  String get set_agCacheOff => '關閉';

  @override
  String get set_agCacheStreaming => '只在 Agent 執行時';

  @override
  String get set_agCacheIdle => '空閒時也預熱';

  @override
  String get set_agCacheIdleCost => '空閒時也預熱（最多 30 分鐘）會產生額外模型費用。';

  @override
  String get ag_suggestionAccept => '按 Tab 填入這句建議';

  @override
  String get ag_cacheWarmTitle => '快取預熱';

  @override
  String get ag_cacheWarmOff => '已關閉';

  @override
  String get ag_cacheWarmRefreshing => '正在續期快取…';

  @override
  String get ag_cacheWarmIdle => '待機，下次執行時開始';

  @override
  String ag_cacheWarmNext(String time) {
    return '$time 後續期';
  }

  @override
  String get set_stOther => '其他檔案';

  @override
  String get set_stIncomplete => '部分目錄讀取失敗，數字不完整；懸停分類可檢視來源目錄。';

  @override
  String get set_stSliceIncomplete => '未完整讀取';

  @override
  String get localGallery_searchHistoryTitle => '最近搜尋';

  @override
  String get localGallery_searchHistoryClear => '清空';

  @override
  String get localGallery_searchHistoryRemove => '從歷史中刪除';

  @override
  String ag_cacheWarmCount(int count) {
    return '已續期 $count 次';
  }

  @override
  String ag_cacheWarmLast(String time) {
    return '上次 $time';
  }

  @override
  String ag_cacheWarmTtl(int minutes) {
    return '快取壽命 $minutes 分鐘';
  }

  @override
  String get shortcut_action_open_resource_window => '開啟資源小窗';
}
