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
  String get onlineFav_all => '全部';

  @override
  String get onlineFav_rootCollection => '根收藏';

  @override
  String get onlineFav_newCollection => '新建子集';

  @override
  String get onlineFav_renameCollection => '重命名子集';

  @override
  String get onlineFav_deleteCollection => '删除子集';

  @override
  String get onlineFav_empty => '还没有收藏的作品';

  @override
  String onlineFav_authorWorkCount(Object n) {
    return '$n 张作品';
  }

  @override
  String get onlineFav_moveHere => '移到这里';

  @override
  String get onlineFav_removeFavorite => '取消收藏';

  @override
  String get onlineFav_favoriteAuthor => '收藏作者';

  @override
  String get onlineFav_unfavoriteAuthor => '取消收藏作者';

  @override
  String get onlineFav_authorFavorited => '已收藏作者';

  @override
  String get onlineFav_authorUnfavorited => '已取消收藏作者';

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
  String get common_new => '新建';

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
  String get common_yesterday => '昨天';

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
  String get common_move => '移动';

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
  String get common_pack => '打包';

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
  String get nav_canvas => '画布';

  @override
  String get nav_onlineGallery => '画廊';

  @override
  String get nav_expandSidebar => '展开侧边栏';

  @override
  String get nav_collapseSidebar => '收起侧边栏';

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
  String get auth_tokenLogin => 'API Token 登录';

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
  String get auth_currentAccount => '当前账号';

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
  String get settings_account => '账户';

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
  String get generation_title => '生成';

  @override
  String get generation_generate => '生成';

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
  String generation_progress(Object progress) {
    return '生成中... $progress%';
  }

  @override
  String get generation_lockHistoryScroll => '锁定历史滚动';

  @override
  String get generation_unlockHistoryScroll => '解锁历史滚动';

  @override
  String get generation_downloadAllImages => '下载全部图像';

  @override
  String get generation_selectMultiple => '多选';

  @override
  String get generation_deselectAll => '退出多选';

  @override
  String generation_deleteSelectedImages(int count) {
    return '删除选中图像 ($count)';
  }

  @override
  String get generation_deleteSelectedImagesTitle => '删除选中图像';

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
  String generation_canvasPinnedCount(int count) {
    return '固定 $count';
  }

  @override
  String get generation_params => '参数';

  @override
  String get generation_paramsSettings => '生成参数';

  @override
  String get generation_history => '历史';

  @override
  String get generation_historyRecord => '历史记录';

  @override
  String get generation_failedStreamSnapshot => '失败快照';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成未完成，仅保留最后一帧预览；不可保存、收藏或用于图生图';

  @override
  String get generation_noHistory => '暂无历史记录';

  @override
  String get generation_clearHistory => '清除历史记录';

  @override
  String get generation_clearHistoryConfirm => '确定要清除所有历史记录吗？此操作不可撤销。';

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
  String get generation_sectionReferenceImages => '参考图';

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
  String get image_saveToLibrary => '保存到词库';

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
  String get img2img_directorPrompt => '提示词（可选）';

  @override
  String get img2img_directorRunning => '正在处理...';

  @override
  String get img2img_directorResult => '处理结果';

  @override
  String get img2img_directorApplied => '已将导演工具结果设为新的源图';

  @override
  String get img2img_directorDefry => 'Defry';

  @override
  String get img2img_directorApplyAsSource => '设为源图';

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
  String get img2img_upscalePanelOpened => '已打开图生图超分面板';

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
  String get editor_back => '返回';

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
  String get editor_shortcut100Zoom => '100% 缩放';

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
  String get vibe_reuseButton => '一键复用';

  @override
  String get vibe_info => 'Vibe 信息';

  @override
  String get vibe_name => '名称';

  @override
  String get vibe_strength => '强度';

  @override
  String get vibe_infoExtracted => '信息提取';

  @override
  String get vibe_shiftReplaceHint => 'Shift+点击 替换';

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
  String get gallery_metaSmea => 'SMEA';

  @override
  String get gallery_promptCopied => '已复制提示词';

  @override
  String get gallery_seedCopied => '已复制 Seed';

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
  String get onlineGallery_search => '搜索';

  @override
  String get onlineGallery_popular => '热门';

  @override
  String get onlineGallery_favorites => '收藏';

  @override
  String get onlineGallery_refresh => '刷新';

  @override
  String get onlineGallery_login => '登录';

  @override
  String get onlineGallery_logout => '退出登录';

  @override
  String get onlineGallery_dayRank => '日榜';

  @override
  String get onlineGallery_weekRank => '周榜';

  @override
  String get onlineGallery_monthRank => '月榜';

  @override
  String get onlineGallery_today => '今天';

  @override
  String onlineGallery_imageCount(Object count) {
    return '$count 张';
  }

  @override
  String get onlineGallery_loadFailed => '加载失败';

  @override
  String get onlineGallery_favoritesEmpty => '收藏夹为空';

  @override
  String get onlineGallery_noResults => '没有找到图片';

  @override
  String get onlineGallery_pleaseLogin => '请先登录';

  @override
  String get onlineGallery_size => '尺寸';

  @override
  String get onlineGallery_score => '评分';

  @override
  String get onlineGallery_favCount => '收藏';

  @override
  String get onlineGallery_type => '类型';

  @override
  String get mediaType_video => '视频';

  @override
  String get mediaType_gif => '动图';

  @override
  String get onlineGallery_tags => '标签';

  @override
  String get onlineGallery_artists => '艺术家';

  @override
  String get onlineGallery_characters => '角色';

  @override
  String get onlineGallery_copyrights => '作品';

  @override
  String get onlineGallery_general => '通用';

  @override
  String get onlineGallery_copied => '已复制';

  @override
  String get onlineGallery_copyTags => '复制标签';

  @override
  String get onlineGallery_open => '打开';

  @override
  String get onlineGallery_send => '发送';

  @override
  String get onlineGallery_sendToTextToImage => '发送到文生图';

  @override
  String get onlineGallery_sentToTextToImage => '已发送到文生图';

  @override
  String get onlineGallery_noTagInfo => '此图片没有标签信息';

  @override
  String get onlineGallery_promptSentToGeneration => '提示词已发送到生成页面';

  @override
  String get onlineGallery_gifLoadFailed => 'GIF加载失败';

  @override
  String get onlineGallery_pinchToZoom => '双指缩放';

  @override
  String get onlineGallery_metadata => '元数据';

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
  String get onlineGallery_all => '全部';

  @override
  String get onlineGallery_ratingGeneral => '全年龄';

  @override
  String get onlineGallery_ratingSensitive => '敏感';

  @override
  String get onlineGallery_ratingQuestionable => '可疑';

  @override
  String get onlineGallery_ratingExplicit => '限制级';

  @override
  String get onlineGallery_clear => '清除';

  @override
  String get onlineGallery_previousPage => '上一页';

  @override
  String get onlineGallery_nextPage => '下一页';

  @override
  String onlineGallery_pageN(Object page) {
    return '第 $page 页';
  }

  @override
  String get onlineGallery_dateRange => '日期范围';

  @override
  String get onlineGallery_fuzzySearch => '模糊匹配';

  @override
  String get onlineGallery_fuzzySearchTooltip =>
      '开启后使用 *tag* 匹配相近标签；关闭时按 Danbooru 精确标签搜索';

  @override
  String get onlineGallery_blacklistTags => '黑名单标签';

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
  String get onlineGallery_bulkFavorite => '批量收藏';

  @override
  String get onlineGallery_bulkDownload => '批量下载';

  @override
  String get onlineGallery_unfavorited => '已取消收藏';

  @override
  String get onlineGallery_favorited => '已收藏';

  @override
  String onlineGallery_favoritedImages(Object count) {
    return '已收藏 $count 张图片';
  }

  @override
  String onlineGallery_selectDownloadDirectoryFailed(Object error) {
    return '选择下载目录失败: $error';
  }

  @override
  String onlineGallery_downloadSelectedStarted(Object count) {
    return '开始下载 $count 张图片...';
  }

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return '下载完成: 成功 $success, 失败 $failed';
  }

  @override
  String get onlineGallery_startDate => '开始日期';

  @override
  String get onlineGallery_endDate => '结束日期';

  @override
  String get onlineGallery_invalidDateFormat => '日期格式无效';

  @override
  String get onlineGallery_dateOutOfRange => '日期超出范围';

  @override
  String get onlineGallery_last30Days => '最近30天';

  @override
  String get onlineGallery_configureGelbooruApi => '配置 Gelbooru API';

  @override
  String get onlineGallery_gelbooruApiReady => 'Gelbooru API 已验证';

  @override
  String get onlineGallery_gelbooruApiInvalid => 'Gelbooru 凭据已失效';

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
  String get onlineGallery_aiTagQuery => '搜索作品、作者、标题、标签或模型';

  @override
  String get onlineGallery_aiTagPromptQuery =>
      'AI Prompt 搜索（支持 ::artist: 等原始语法）';

  @override
  String get onlineGallery_aiTagTimeRange => '时间范围';

  @override
  String get onlineGallery_aiTagAllTime => '全部';

  @override
  String get onlineGallery_aiTagCurrentMonthly => '实时月榜';

  @override
  String get onlineGallery_aiTagOlderMonthly => '更早归档';

  @override
  String get onlineGallery_aiTagRankingProcessing => '排行榜生成中，请稍后重试。';

  @override
  String get onlineGallery_aiTagNaiOnly => '仅 NAI';

  @override
  String get onlineGallery_aiTagModelVersion => '模型版本';

  @override
  String get onlineGallery_viewAuthor => '查看此作者';

  @override
  String get onlineGallery_returnFromAuthor => '返回之前的浏览位置';

  @override
  String get onlineGallery_generationParams => '生成参数';

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
  String get onlineGallery_loadedAll => '已加载全部';

  @override
  String get onlineGallery_retryAppend => '加载失败，点击重试';

  @override
  String onlineGallery_rankNumber(Object rank) {
    return '第 $rank 名';
  }

  @override
  String onlineGallery_multipleImages(Object count) {
    return '$count 张图片';
  }

  @override
  String get onlineGallery_views => '浏览';

  @override
  String get onlineGallery_downloadAllMedia => '下载作品全部图片';

  @override
  String get onlineGallery_copyFullMetadata => '复制完整元数据';

  @override
  String get onlineGallery_metadataParseFailed => '元数据解析失败，原始内容已保留，可直接复制。';

  @override
  String get onlineGallery_gelbooruReadOnly => '只读收藏';

  @override
  String get onlineGallery_gelbooruFavoritesSortHint =>
      '按帖子 ID 从新到旧排列，不保证与网站收藏时间顺序一致。';

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
  String get localGallery_copySeed => '复制 Seed';

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
  String get statistics_title => '统计仪表盘';

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
  String get localGallery_dateFolders => '日期文件夹';

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
  String get tagLibrary_newCategory => '新建分类';

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
  String get shortcut_action_generation_prev_image => '预览上一张（历史联动）';

  @override
  String get shortcut_action_generation_next_image => '预览下一张（历史联动）';

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
  String get vibeLibrary_categories => '分类';

  @override
  String get vibeLibrary_createCategoryTitle => '新建分类';

  @override
  String get vibeLibrary_createSubCategoryTitle => '新建子分类';

  @override
  String get vibeLibrary_categoryNameHint => '请输入分类名称';

  @override
  String get vibeLibrary_createCategoryConfirm => '创建';

  @override
  String get vibeLibrary_deleteCategoryTitle => '确认删除';

  @override
  String get vibeLibrary_deleteCategoryContent =>
      '确定要删除此分类吗？分类下的 Vibe 将被移动到未分类。';

  @override
  String get vibeLibrary_sortTooltip => '排序方式';

  @override
  String get vibeLibrary_openFolderTooltip => '打开 Vibe 库文件夹';

  @override
  String vibeLibrary_totalCount(Object count) {
    return '共 $count 个 Vibe';
  }

  @override
  String get vibeLibrary_noCategoriesAvailable => '没有可用的分类';

  @override
  String get vibeLibrary_moveToCategory => '移动到分类';

  @override
  String get vibeLibrary_uncategorized => '未分类';

  @override
  String vibeLibrary_movedToCategory(Object count) {
    return '已移动 $count 个 Vibe';
  }

  @override
  String get vibeLibrary_favoriteStatusUpdated => '收藏状态已更新';

  @override
  String get vibeLibrary_importFromFile => '从文件导入';

  @override
  String get vibeLibrary_importFromImage => '从图片导入';

  @override
  String get vibeLibrary_importFromClipboard => '从剪贴板导入编码';

  @override
  String vibeLibrary_openFolderFailed(Object error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get vibeLibrary_importFileDialogTitle => '选择要导入的 Vibe 文件';

  @override
  String get vibeLibrary_preparingImport => '准备导入...';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '成功导入 $count 个 Vibe';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return '导入完成: $success 成功, $failed 失败';
  }

  @override
  String get vibeLibrary_dropImportHint =>
      '拖拽 .naiv4vibe/.naiv4vibebundle/.png/.jpg/.jpeg/.webp 文件或文件夹到此处导入';

  @override
  String get vibeLibrary_importing => '正在导入...';

  @override
  String vibeLibrary_pageIndicator(Object current, Object total) {
    return '$current / $total 页';
  }

  @override
  String get vibeLibrary_itemsPerPage => '每页:';

  @override
  String get vibeLibrary_tooManyTitle => 'Vibe数量过多';

  @override
  String vibeLibrary_tooManySelectedContent(Object count) {
    return '选中了 $count 个Vibe，但最多只能同时使用16个。\n\n请减少选择数量后再试。';
  }

  @override
  String vibeLibrary_tooManyExistingContent(Object current, Object remaining) {
    return '当前生成页面已有 $current 个Vibe，还可以添加 $remaining 个。\n\n请减少选择数量后再试。';
  }

  @override
  String vibeLibrary_sentToGenerationCount(Object count) {
    return '已发送 $count 个Vibe到生成页面';
  }

  @override
  String vibeLibrary_deleteSelectedContent(Object count) {
    return '确定要删除选中的 $count 个Vibe吗？此操作无法撤销。';
  }

  @override
  String vibeLibrary_deletedCount(Object count) {
    return '已删除 $count 个Vibe';
  }

  @override
  String get vibeLibrary_importImageDialogTitle => '选择包含 Vibe 的图片';

  @override
  String get vibeLibrary_clipboardEmpty => '剪贴板为空';

  @override
  String get vibeLibrary_encodeTimeout => '编码超时，请检查网络连接';

  @override
  String get vibeLibrary_unknownError => '未知错误';

  @override
  String get vibeLibrary_save => '保存到库';

  @override
  String get vibeLibrary_import => '导入 Vibe';

  @override
  String get vibeLibrary_searchHint => '搜索名称、标签...';

  @override
  String get vibeLibrary_empty => 'Vibe 库为空';

  @override
  String get vibeLibrary_emptyHint => '先去 Vibe 库添加一些条目吧';

  @override
  String get vibeLibrary_allVibes => '全部 Vibe';

  @override
  String get vibeLibrary_favorites => '收藏';

  @override
  String get vibeLibrary_sendToGeneration => '发送到生成';

  @override
  String get vibeLibrary_export => '导出';

  @override
  String get vibeLibrary_edit => '编辑';

  @override
  String get vibeLibrary_delete => '删除';

  @override
  String get vibeLibrary_addToFavorites => '收藏';

  @override
  String get vibeLibrary_removeFromFavorites => '取消收藏';

  @override
  String get vibeLibrary_newSubCategory => '新建子分类';

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
  String get vibeBulkTag_actionPreview => '操作预览';

  @override
  String get vibeDetail_strengthDescription => '控制 Vibe 对生成结果的影响强度';

  @override
  String get vibeDetail_infoExtractedDescription => '控制从原图提取的信息量（消耗 2 Anlas）';

  @override
  String get vibeDetail_statistics => '统计信息';

  @override
  String get vibeDetail_usageCount => '使用次数';

  @override
  String vibeDetail_timesUsed(int count) {
    return '$count 次';
  }

  @override
  String get vibeDetail_lastUsed => '最后使用';

  @override
  String get vibeDetail_neverUsed => '从未使用';

  @override
  String get vibeDetail_createdAt => '创建时间';

  @override
  String get vibeDetail_saveParameters => '保存参数';

  @override
  String get vibe_export_title => '导出 Vibe';

  @override
  String get vibe_export_format => '导出格式';

  @override
  String get vibe_selector_title => '选择 Vibe';

  @override
  String get vibe_selector_recent => '最近使用';

  @override
  String get vibe_export_include_thumbnails => '包含缩略图';

  @override
  String get vibe_export_include_thumbnails_subtitle => '导出文件中包含缩略图预览';

  @override
  String get vibe_export_singleFile => '单文件 (.naiv4vibe)';

  @override
  String get vibe_export_singleFileDescription =>
      '将每个 Vibe 导出为单独文件，适合分享单个 Vibe';

  @override
  String get vibe_export_bundleFile => '打包文件 (.naiv4vibebundle)';

  @override
  String get vibe_export_bundleFileDescription => '将多个 Vibe 打包到一个文件中，适合批量备份';

  @override
  String get vibe_export_embedIntoPng => '嵌入到 PNG';

  @override
  String get vibe_export_embedIntoPngDescription => '通过写入 PNG 元数据导出单个 Vibe';

  @override
  String get vibe_export_exportable => '可导出';

  @override
  String get vibe_export_notExportable => '不可导出';

  @override
  String get vibe_export_selectVibesToExport => '选择要导出的 Vibe';

  @override
  String vibe_export_exportSelected(int count) {
    return '导出 ($count)';
  }

  @override
  String vibe_export_strengthPercent(int percent) {
    return '强度: $percent%';
  }

  @override
  String get vibe_export_pngCarrierImage => 'PNG 载体图片';

  @override
  String get vibe_export_noUsablePngCarrier =>
      '这个 Vibe 没有可直接使用的 PNG 载体图片。你可以选择外部 PNG 图片作为载体。';

  @override
  String get vibe_export_selectExternalPngImage => '选择外部 PNG 图片...';

  @override
  String get vibe_export_changeExternalPngImage => '更换外部 PNG 图片...';

  @override
  String get vibe_export_useVibeImageInstead => '改用 Vibe 图片';

  @override
  String vibe_export_usingExternalPng(String fileName) {
    return '正在使用外部 PNG: $fileName';
  }

  @override
  String get vibe_export_selectPngImage => '选择 PNG 图片';

  @override
  String get vibe_export_invalidPngImage => '所选文件不是有效的 PNG 图片';

  @override
  String vibe_export_selectPngImageFailed(String error) {
    return '选择 PNG 图片失败: $error';
  }

  @override
  String vibe_export_embeddingPng(String name) {
    return '正在嵌入 PNG: $name';
  }

  @override
  String vibe_export_exportCompleteCounts(int successCount, int failCount) {
    return '导出完成: 成功 $successCount 个，失败 $failCount 个';
  }

  @override
  String vibe_export_exportCompletePath(String path) {
    return '导出完成: $path';
  }

  @override
  String vibe_export_packingVibes(int count) {
    return '正在打包 $count 个 Vibe...';
  }

  @override
  String vibe_export_exportingName(String name) {
    return '正在导出: $name';
  }

  @override
  String get vibe_export_selectExportFolder => '选择导出文件夹';

  @override
  String get vibe_export_generatingBundleFile => '正在生成打包文件...';

  @override
  String vibe_export_bundleTitle(String name) {
    return '导出 Bundle: $name';
  }

  @override
  String vibe_export_vibesTitle(int count) {
    return '导出 Vibe ($count 个已选)';
  }

  @override
  String get vibe_export_method => '导出方式';

  @override
  String get vibe_export_wholeBundle => '整个 Bundle';

  @override
  String get vibe_export_internalVibe => '内部 Vibe';

  @override
  String vibe_export_wholeBundleDescription(int count) {
    return '导出包含全部 $count 个 Vibe 的 .naiv4vibebundle 文件';
  }

  @override
  String vibe_export_internalVibeDescription(int count) {
    return '选择 Bundle 内部 Vibe，分别导出为 .naiv4vibe 文件 (共 $count 个)';
  }

  @override
  String get vibe_export_exportBundle => '导出 Bundle';

  @override
  String get vibe_export_exportAsFiles => '导出为文件';

  @override
  String get vibe_export_exportBundleDescription => '导出为 .naiv4vibebundle 文件';

  @override
  String get vibe_export_exportAsFilesDescription =>
      '导出为 .naiv4vibe 或 .naiv4vibebundle 文件';

  @override
  String get vibe_export_exportAsZip => '导出为 ZIP';

  @override
  String get vibe_export_exportAsZipDescription =>
      '将选中的 Vibe 库条目作为独立文件打包为 .zip';

  @override
  String get vibe_export_compressData => '压缩数据';

  @override
  String get vibe_export_compressDataDescription => '使用压缩以减小文件大小 (推荐用于批量导出)';

  @override
  String get vibe_export_zipCompressDescription => '压缩 ZIP 内的文件以减小体积';

  @override
  String get vibe_export_exportAsPng => '导出为 PNG';

  @override
  String get vibe_export_pngInternalBundleUnsupported =>
      '导出单个 Bundle 内部 Vibe 时不支持嵌入图片';

  @override
  String get vibe_export_embedVibeDataIntoPng => '将 Vibe 数据写入 PNG 元数据';

  @override
  String get vibe_export_batchPngUsesFirstImage =>
      '批量导出会使用每个 Vibe 的第一张可用图片，没有图片的条目会自动跳过。';

  @override
  String get vibe_export_exportCarrierImage => '导出载体图片';

  @override
  String get vibe_export_usingExternalCarrierImage => '正在使用外部 PNG 作为导出载体图片';

  @override
  String get vibe_export_exportAsEncodings => '导出为编码';

  @override
  String get vibe_export_exportAsEncodingsDescription =>
      '将数据导出为编码 (JSON 或 Base64)';

  @override
  String get vibe_export_jsonDescription => '导出为格式化 JSON 文件，便于阅读和编辑';

  @override
  String get vibe_export_base64Description => '导出为纯 Base64，便于复制和分享';

  @override
  String get vibe_export_selectAtLeastOneMethod => '请选择至少一种导出方式';

  @override
  String get vibe_export_batchPngUnsupported =>
      '批量 Vibe 导出不支持嵌入 PNG。请使用单个 Vibe 导出界面。';

  @override
  String get vibe_export_selectPngCarrier => '请选择用于导出的 PNG 载体图片';

  @override
  String get vibe_export_selectAtLeastOneInternalVibe => '请选择至少一个内部 Vibe';

  @override
  String get vibe_export_selectVibeExportFolder => '选择 Vibe 导出文件夹';

  @override
  String get vibe_export_saveEncodingFile => '保存编码文件';

  @override
  String get vibe_export_preparingExport => '正在准备导出...';

  @override
  String vibe_export_preparingVibeProgress(int current, int total) {
    return '正在读取 Vibe $current/$total...';
  }

  @override
  String get vibe_export_exportingBundle => '正在导出 Bundle...';

  @override
  String get vibe_export_exportingZip => '正在导出 ZIP...';

  @override
  String get vibe_export_embeddingImage => '正在嵌入图片...';

  @override
  String get vibe_export_exportingEncoding => '正在导出编码...';

  @override
  String vibe_export_exportFailedWithError(String error) {
    return '导出失败: $error';
  }

  @override
  String get vibe_export_noExportableEntries => '没有可导出的 Vibe 条目';

  @override
  String get vibe_export_bundleFilePathEmpty => 'Bundle 文件路径为空';

  @override
  String vibe_export_invalidImageFormatWithError(String error) {
    return '无效的图片格式: $error';
  }

  @override
  String vibe_export_embedFailedWithError(String error) {
    return '嵌入失败: $error';
  }

  @override
  String vibe_export_embedImageFailedWithError(String error) {
    return '嵌入图片失败: $error';
  }

  @override
  String vibe_export_extractingVibeProgress(int current, int total) {
    return '正在提取 Vibe $current/$total...';
  }

  @override
  String vibe_export_selectImageFailed(String error) {
    return '选择图片失败: $error';
  }

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
  String get vibe_import_skip => '跳过';

  @override
  String get vibe_import_confirm => '确认';

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
  String get vibe_import_title => '从库导入';

  @override
  String vibe_import_result(int count) {
    return '已导入 $count 个 vibes';
  }

  @override
  String get vibe_import_fileParseFailed => '解析文件失败';

  @override
  String get vibe_import_fileSelectionFailed => '文件选择失败';

  @override
  String get vibe_import_importFailed => '导入失败';

  @override
  String get vibe_import_bundleTitle => '导入 Vibe Bundle';

  @override
  String get vibe_import_bundleChooseMethod => '选择导入方式';

  @override
  String get vibe_import_bundleAsWhole => '作为整体导入';

  @override
  String get vibe_import_bundleAsWholeDescription => '保留 Bundle 结构，并作为一个库条目导入';

  @override
  String get vibe_import_bundleSplitEntries => '拆分为独立条目';

  @override
  String get vibe_import_bundleSplitEntriesDescription => '将每个 Vibe 作为独立库条目导入';

  @override
  String get vibe_import_bundleSelectVibes => '选择要导入的 Vibe';

  @override
  String get vibe_import_bundleSelectVibesDescription => '仅导入选中的 Vibe';

  @override
  String get vibe_import_bundleConfigureEachVibe => '配置每个 Vibe 的参数';

  @override
  String get vibe_import_bundleSelectAndConfigureEachVibe => '选择并配置每个 Vibe 的参数';

  @override
  String vibe_import_bundleSelectedCount(int selected, int total) {
    return '已选择 $selected/$total';
  }

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
  String get search_results => '搜索结果';

  @override
  String get search_noResults => '未找到匹配结果';

  @override
  String get addToCurrent => '添加到当前';

  @override
  String get replaceExisting => '替换现有';

  @override
  String get confirmSelection => '确认选择';

  @override
  String get selectAll => '全选';

  @override
  String get clearSelection => '清空';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 详情';

  @override
  String get shortcut_action_vibe_detail_rename => '重命名';

  @override
  String get vibeSelectorFilterFavorites => '收藏';

  @override
  String get vibeSelectorFilterSourceAll => '全部类型';

  @override
  String get vibeSelectorSortCreated => '创建时间';

  @override
  String get vibeSelectorSortLastUsed => '最近使用';

  @override
  String get vibeSelectorSortUsedCount => '使用次数';

  @override
  String get vibeSelectorSortName => '名称';

  @override
  String vibeSelectorItemsCount(int count) {
    return '$count 项';
  }

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
  String get settings_defaultHivePath => '默认 (%APPDATA%/NAI_Launcher/hive/)';

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
  String toast_deletedNamed(Object name) {
    return '已删除: $name';
  }

  @override
  String get toast_vibeParamSaveReencodeFailed => '保存参数失败，Vibe 重新编码失败';

  @override
  String get toast_exportSuccess => '导出成功';

  @override
  String toast_exportFailed(Object error) {
    return '导出失败: $error';
  }

  @override
  String get toast_selectVibeToExport => '请先选择要导出的 Vibe';

  @override
  String get toast_embedPngSingleVibeOnly => '嵌入 PNG 仅支持单个 Vibe 导出';

  @override
  String get toast_selectPngCarrier => '请选择一个 PNG 载体图用于导出';

  @override
  String get toast_renameSuccess => '重命名成功';

  @override
  String get toast_paramsSaved => '参数已保存';

  @override
  String get toast_paramsSaveFailed => '保存参数失败';

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
  String get toast_favorited => '已收藏';

  @override
  String get toast_unfavorited => '已取消收藏';

  @override
  String toast_favoriteUpdateFailed(Object error) {
    return '收藏状态更新失败: $error';
  }

  @override
  String toast_packingImages(Object count) {
    return '正在打包 $count 张图片...';
  }

  @override
  String toast_packedImages(Object count) {
    return '已打包 $count 张图片';
  }

  @override
  String get toast_packFailed => '打包失败';

  @override
  String toast_packFailedWithError(Object error) {
    return '打包失败: $error';
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
  String get toast_imagePromptCopied => '已复制 Prompt';

  @override
  String get toast_imageHasNoPrompt => '此图片没有 Prompt';

  @override
  String get toast_useDeleteButton => '请使用界面删除按钮';

  @override
  String get toast_imageDataUnavailable => '图像数据不可用，无法复制';

  @override
  String get toast_vibeDataCopied => 'Vibe 数据已复制';

  @override
  String get toast_characterPromptCopied => '角色提示词已复制';

  @override
  String toast_copiedTitle(Object title) {
    return '$title已复制';
  }

  @override
  String toast_replacedVibesCount(Object count, Object name) {
    return '已替换为 $count 个 Vibe: $name';
  }

  @override
  String toast_sentVibesCount(Object count, Object name) {
    return '已发送 $count 个 Vibe 到生成页面: $name';
  }

  @override
  String toast_replacedVibe(Object name) {
    return '已替换为: $name';
  }

  @override
  String toast_sentVibeToGeneration(Object name) {
    return '已发送到生成页面: $name';
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
  String get toast_renameNameRequired => '名称不能为空';

  @override
  String get toast_renameNameConflict => '名称已存在，请使用其他名称';

  @override
  String get toast_renameEntryNotFound => '条目不存在，可能已被删除';

  @override
  String get toast_renameFilePathMissing => '该条目缺少文件路径，无法重命名';

  @override
  String get toast_renameFileFailed => '重命名文件失败，请稍后重试';

  @override
  String get toast_renameFailed => '重命名失败，请稍后重试';

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
  String get common_pleaseWait => '请稍候';

  @override
  String get common_change => '更换';

  @override
  String get common_expand => '展开';

  @override
  String get common_collapse => '收起';

  @override
  String get vibeLibrary_emptySearchTitle => '未找到匹配的 Vibe';

  @override
  String get vibeLibrary_emptySearchSubtitle => '尝试其他关键词';

  @override
  String get vibeLibrary_emptyFavoritesTitle => '暂无收藏的 Vibe';

  @override
  String get vibeLibrary_emptyFavoritesSubtitle => '点击心形图标收藏 Vibe';

  @override
  String get vibeLibrary_emptyCategoryTitle => '该分类下暂无 Vibe';

  @override
  String get vibeLibrary_emptyCategorySubtitle => '尝试切换到\"全部 Vibe\"查看所有内容';

  @override
  String get vibeLibrary_emptyNoMatchesTitle => '无匹配结果';

  @override
  String get vibeLibrary_emptySaveFromGenerationHint => '从生成页面保存Vibe到库中';

  @override
  String get vibe_nameRequired => '名称不能为空';

  @override
  String get vibe_import_namingTitle => '命名 Vibe';

  @override
  String get vibe_import_nameConflictOverwrite => '该名称已存在，将被覆盖';

  @override
  String get vibe_previewLoadFailed => '预览加载失败';

  @override
  String get vibe_import_applyToRemainingFiles => '应用到后续所有文件';

  @override
  String get vibe_import_applyNamingToRemainingFiles => '使用此命名规则处理剩余文件';

  @override
  String get vibe_encodeImageTitle => '编码图片为 Vibe';

  @override
  String get vibe_imagePreview => '图片预览';

  @override
  String get vibe_encodeStartButton => '开始编码';

  @override
  String get vibe_encodeImageInProgress => '正在编码图片...';

  @override
  String vibe_encodeErrorImage(Object fileName) {
    return '图片: $fileName';
  }

  @override
  String vibe_encodeErrorMessage(Object error) {
    return '错误: $error';
  }

  @override
  String get vibe_encodeSkipImage => '跳过此图';

  @override
  String get detail_sendToImg2Img => '发送到图生图';

  @override
  String get detail_loadingImage => '加载图片中...';

  @override
  String get detail_imageLoadFailed => '无法加载图片';

  @override
  String get detail_noImage => '无图片';

  @override
  String get detail_parsingMetadata => '正在解析元数据...';

  @override
  String get detail_noMetadata => '此图片无元数据';

  @override
  String get detail_metadata => '元数据';

  @override
  String get detail_imageDetails => '图片详情';

  @override
  String get detail_basicInfo => '基本信息';

  @override
  String get detail_fileName => '文件名';

  @override
  String get detail_modifiedTime => '修改时间';

  @override
  String get detail_fileSize => '文件大小';

  @override
  String get detail_noContent => '(无内容)';

  @override
  String get detail_saveBlock => '保存为块';

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
  String get detail_copyCharacterPrompt => '复制角色提示词';

  @override
  String get detail_copyAllVibeData => '复制全部 Vibe 数据';

  @override
  String get detail_saveToVibeLibrary => '保存到 Vibe 库';

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
  String get preciseRefLib_title => '精准参考库';

  @override
  String get preciseRefLib_searchHint => '搜索参考图...';

  @override
  String get preciseRefLib_empty => '拖拽或粘贴图片到此处建立库';

  @override
  String get preciseRefLib_emptyHint => '也可以在生成结果、历史记录或本地图库中右键保存';

  @override
  String get preciseRefLib_import => '导入图片';

  @override
  String preciseRefLib_entryCount(int count) {
    return '$count 个条目';
  }

  @override
  String get preciseRefLib_sendToPreciseRef => '发送到精准参考';

  @override
  String get preciseRefLib_sendToImg2Img => '发送到图生图';

  @override
  String get preciseRefLib_editEntry => '编辑参数';

  @override
  String get preciseRefLib_confirmDeleteTitle => '删除条目';

  @override
  String preciseRefLib_confirmDelete(String name) {
    return '确定删除“$name”？图片文件将一并删除。';
  }

  @override
  String preciseRefLib_saved(String name) {
    return '已存入精准参考库：$name';
  }

  @override
  String get preciseRefLib_savedHint => '可在精准参考库中编辑参数';

  @override
  String preciseRefLib_sent(String name) {
    return '已发送到精准参考：$name';
  }

  @override
  String preciseRefLib_sentToImg2Img(String name) {
    return '已发送到图生图：$name';
  }

  @override
  String get preciseRefLib_imageMissing => '原图文件丢失';

  @override
  String get preciseRefLib_invalidImage => '无法识别图片格式，或图片文件已经损坏';

  @override
  String get preciseRefLib_deleteFailed => '删除失败，条目与原图已保留，请稍后重试';

  @override
  String get preciseRefLib_favoritesOnly => '只看收藏';

  @override
  String get preciseRefLib_sortBy => '排序方式';

  @override
  String get preciseRefLib_sortCreatedAt => '创建时间';

  @override
  String get preciseRefLib_sortLastUsed => '最近使用';

  @override
  String get preciseRefLib_sortUsedCount => '使用次数';

  @override
  String get preciseRefLib_sortName => '名称';

  @override
  String preciseRefLib_importedCount(int count) {
    return '已导入 $count 张图片';
  }

  @override
  String preciseRefLib_loadFailed(String error) {
    return '加载精准参考库失败：$error';
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
  String get preciseRefLib_selectorTitle => '从精准参考库选择';

  @override
  String preciseRefLib_selectorConfirm(int count) {
    return '添加所选 ($count)';
  }

  @override
  String get preciseRefLib_nameLabel => '名称';

  @override
  String get preciseRefLib_typeFilterAll => '全部';

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
  String get history_dragFilePreparationFailed => '拖拽文件准备失败，请稍后重试';

  @override
  String get history_dragFilePreparing => '正在准备拖拽文件...';

  @override
  String get history_dragFileNotReady => '拖拽文件尚未准备完成';

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
  String get vibeDetail_useAll => '使用全部';

  @override
  String get vibeDetail_longPressSetCover => '长按设为封面';

  @override
  String get vibeDetail_noPreviewImage => '无预览图像';

  @override
  String get vibeDetail_dropPreviewImage => '拖拽图片到此处设置预览图';

  @override
  String get vibeDetail_releasePreviewImage => '释放以设置预览图';

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
  String get nav_promptBlockLibrary => '提示词块';

  @override
  String get promptBlockLibrary_title => '提示词块';

  @override
  String get promptBlockLibrary_folders => '文件夹';

  @override
  String get promptBlockLibrary_allBlocks => '全部块';

  @override
  String get promptBlockLibrary_rootFolder => '根目录 / 未分类';

  @override
  String get promptBlockLibrary_unnamedBlock => '未命名块';

  @override
  String get promptBlockLibrary_noBlockSelected => '未选择块';

  @override
  String get promptBlockLibrary_details => '详情';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '使用 $count 次';
  }

  @override
  String get promptBlockPill_missing => '块已删除';

  @override
  String get promptBlockPill_unknown => '失效块';

  @override
  String get pillCardReroll => '重抽';

  @override
  String get pillCardRerollLocked => '已锁定，无法重抽';

  @override
  String get pillCardLock => '锁定当前内容';

  @override
  String get pillCardUnlock => '解除锁定';

  @override
  String get pillCardSettings => '随机设置';

  @override
  String get pillCardEnable => '启用';

  @override
  String get pillCardDisable => '禁用';

  @override
  String get pillCardDeleteInstance => '删除实例';

  @override
  String get pillCardEmptyRoll => '（本次为空）';

  @override
  String get pillCardEvolutionEnable => '开启遗传';

  @override
  String get pillCardEvolutionDisable => '关闭遗传';

  @override
  String get pillCardEvolutionRequiresEnabled => '需先启用实例';

  @override
  String get pillCardStepBack => '退回一幕';

  @override
  String get pillCardStepForward => '前进一幕';

  @override
  String get pillSettingsTitle => '块实例设置';

  @override
  String get pillSettingsModeFixed => '固定';

  @override
  String get pillSettingsModeSequential => '顺序';

  @override
  String get pillSettingsModeRandom => '随机抽取';

  @override
  String get pillSettingsCount => '抽取数量';

  @override
  String get pillSettingsOrder => '输出顺序';

  @override
  String get pillSettingsOrderDrawn => '按抽中顺序';

  @override
  String get pillSettingsOrderOriginal => '按池原序';

  @override
  String get pillSettingsWeight => '随机权重';

  @override
  String get pillSettingsWeightMin => '最小';

  @override
  String get pillSettingsWeightMax => '最大';

  @override
  String get pillSettingsWeightAverage => '平均';

  @override
  String get pillSettingsDispersion => '离散';

  @override
  String get pillSettingsDispersionFocused => '集中';

  @override
  String get pillSettingsDispersionBalanced => '均衡';

  @override
  String get pillSettingsDispersionSpread => '发散';

  @override
  String get pillSettingsAdvanced => '高级';

  @override
  String get pillSettingsLeftDispersion => '左离散';

  @override
  String get pillSettingsRightDispersion => '右离散';

  @override
  String get pillSettingsSoftBalance => '软平衡';

  @override
  String get pillSettingsSoftBalanceStrength => '回拉强度';

  @override
  String get pillSettingsTriggerProbability => '触发概率';

  @override
  String get pillSettingsCancel => '取消';

  @override
  String get pillSettingsApply => '确定';

  @override
  String get promptBlockLibrary_unnamedFolder => '未命名文件夹';

  @override
  String get promptBlockLibrary_scope => '浏览范围';

  @override
  String get promptBlockLibrary_newBlock => '新建块';

  @override
  String get promptBlockLibrary_editBlock => '编辑块';

  @override
  String get promptBlockLibrary_newFolder => '新建文件夹';

  @override
  String get promptBlockLibrary_newSubfolder => '新建子文件夹';

  @override
  String get promptBlockLibrary_renameFolder => '重命名文件夹';

  @override
  String get promptBlockLibrary_moveToRoot => '移到根目录';

  @override
  String get promptBlockLibrary_moveToFolder => '移动到文件夹';

  @override
  String get promptBlockLibrary_favorites => '收藏';

  @override
  String get promptBlockLibrary_unclassified => '未分类';

  @override
  String get promptBlockLibrary_newCollection => '新建收藏集';

  @override
  String get promptBlockLibrary_newSubcollection => '新建子收藏集';

  @override
  String get promptBlockLibrary_newCollectionFolder => '新建收藏文件夹';

  @override
  String get promptBlockLibrary_renameCollection => '重命名收藏集';

  @override
  String get promptBlockLibrary_renameCollectionFolder => '重命名收藏文件夹';

  @override
  String get promptBlockLibrary_moveToFavoritesRoot => '移到收藏区根级';

  @override
  String get promptBlockLibrary_unnamedCollection => '未命名收藏集';

  @override
  String get promptBlockLibrary_unnamedCollectionFolder => '未命名收藏文件夹';

  @override
  String get promptBlockLibrary_collectionName => '收藏集名称';

  @override
  String get promptBlockLibrary_collectionNameHint => '收藏集名称';

  @override
  String get promptBlockLibrary_noCollections =>
      '还没有收藏集 —— 点「收藏」行旁的 + 新建，或把块拖到收藏集上';

  @override
  String get promptBlockLibrary_noFolders => '还没有文件夹';

  @override
  String get promptBlockLibrary_emptyFavorites => '还没有收藏的块，点块上的 ★ 即可收藏';

  @override
  String get promptBlockLibrary_emptyCollection => '该收藏集为空';

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
  String get promptBlockLibrary_searchHint => '搜索标题、提示词或标签';

  @override
  String get promptBlockLibrary_folder => '文件夹';

  @override
  String get promptBlockLibrary_folderName => '文件夹名称';

  @override
  String get promptBlockLibrary_folderNameHint => '文件夹名称';

  @override
  String get promptBlockLibrary_basicPrompt => '基础提示词';

  @override
  String get promptBlockLibrary_generationSettings => '设置';

  @override
  String get promptBlockLibrary_settingsOptionalHint => '仅保存填写的参数；插入块后可手动应用设置。';

  @override
  String get promptBlockLibrary_notSpecified => '不指定';

  @override
  String get promptBlockLibrary_stepsLabel => '步数';

  @override
  String get promptBlockLibrary_noiseScheduleLabel => '噪声调度';

  @override
  String get promptBlockLibrary_invalidGenerationSettings =>
      '请检查设置：步数 1–50、提示词引导 1–20、提示词引导重缩放 0–1，并确认参数受所选模型支持。';

  @override
  String get promptBlockLibrary_applySettings => '导入设置';

  @override
  String get promptBlockLibrary_settingsApplied => '块设置已导入当前画面';

  @override
  String get promptBlockLibrary_settingsIncompatible => '块设置与目标模型不兼容，未导入任何参数。';

  @override
  String get promptBlockLibrary_noSettings => '此块未保存生图参数';

  @override
  String get promptBlockLibrary_tags => '标签';

  @override
  String get promptBlockLibrary_addTag => '添加标签';

  @override
  String get promptBlockLibrary_tagName => '标签名称';

  @override
  String get promptBlockLibrary_tagColor => '标签颜色（十六进制）';

  @override
  String get promptBlockLibrary_duplicateTag => '这个块已有同名标签';

  @override
  String get promptBlockLibrary_invalidTagColor => '请输入有效的十六进制颜色';

  @override
  String get pillCard_rollScope => '变化范围';

  @override
  String get pillCard_positiveScope => '正面';

  @override
  String get pillCard_negativeScope => '负面';

  @override
  String get promptBlockLibrary_modelResetNotice => '切换模型后，不支持的参数已清除。';

  @override
  String get promptBlockLibrary_atomInputHint => '输入文本，回车变成原子块';

  @override
  String get promptBlockLibrary_atomRestoreHint => '点击还原成文本再编辑';

  @override
  String get promptBlockLibrary_atomOrphan => '未知标记';

  @override
  String get promptBlockLibrary_atomEditorTutorial =>
      '输入后回车成块，点击还原为文本，保存时所有未成块文本自动转化。';

  @override
  String get promptBlockLibrary_color => '颜色';

  @override
  String get promptBlockLibrary_icon => '图标';

  @override
  String get promptBlockLibrary_saved => '已保存';

  @override
  String get promptBlockLibrary_copied => '正文已复制';

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
  String get promptBlockLibrary_moveTo => '移动到…';

  @override
  String get promptBlockLibrary_moveToFolderTitle => '移动到文件夹';

  @override
  String promptBlockLibrary_deleteBlocksConfirm(int count) {
    return '确定要删除选中的 $count 个块吗？此操作无法撤销。';
  }

  @override
  String promptBlockLibrary_deleteSelected(int count) {
    return '删除选中的 $count 个块';
  }

  @override
  String get promptBlockLibrary_empty => '还没有提示词块';

  @override
  String get promptBlockLibrary_emptyFolder => '此文件夹为空';

  @override
  String get promptBlockLibrary_noSearchResults => '没有匹配的块';

  @override
  String get promptBlockLibrary_tryDifferentSearch => '请尝试其他搜索词';

  @override
  String get promptBlockLibrary_emptyHint => '新建一个块，开始整理可复用的文本';

  @override
  String promptBlockLibrary_loadFailed(String error) {
    return '加载提示词块失败：$error';
  }

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
  String get promptBlockLibrary_importExport => '导入 / 导出';

  @override
  String get promptBlockLibrary_importTxtFiles => '导入 TXT 文件';

  @override
  String get promptBlockLibrary_importFromFolder => '从文件夹导入…';

  @override
  String get promptBlockLibrary_exportLibraryBackup => '导出库备份…';

  @override
  String get promptBlockLibrary_importLibraryBackup => '导入库备份…';

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
  String promptBlockLibrary_libraryBackupDone(int count) {
    return '已导出 $count 个块的库备份';
  }

  @override
  String get promptBlockLibrary_libraryImportTitle => '选择库备份文件';

  @override
  String get promptBlockLibrary_libraryBackupInvalid => '不是有效的块库备份文件';

  @override
  String promptBlockLibrary_libraryImportDone(
    int blocks,
    int folders,
    int skipped,
  ) {
    return '导入 $blocks 个块、$folders 个文件夹，跳过 $skipped 个已存在';
  }

  @override
  String promptBlockLibrary_importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => '来源文件';

  @override
  String get promptBlockLibrary_importedAt => '导入时间';

  @override
  String get promptBlockLibrary_listView => '列表视图';

  @override
  String get promptBlockLibrary_gridView => '网格视图';

  @override
  String get promptBlockLibrary_waterfallView => '瀑布流视图';

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
  String get promptBlockLibrary_sortBy => '排序方式';

  @override
  String get promptBlockLibrary_sortCustom => '默认（手动顺序）';

  @override
  String get promptBlockLibrary_sortUpdated => '修改时间';

  @override
  String get promptBlockLibrary_sortTitle => '名称';

  @override
  String get promptBlockLibrary_sortColor => '颜色';

  @override
  String get promptBlockLibrary_sortIcon => '图标';

  @override
  String get promptBlockLibrary_sortAscending => '升序';

  @override
  String get promptBlockLibrary_sortDescending => '降序';

  @override
  String get promptBlockLibrary_cardSize => '卡片大小';

  @override
  String get promptBlockLibrary_reorderFolders => '调整文件夹顺序';

  @override
  String get nav_styleExplore => '画风探索';

  @override
  String get styleExplore_rename => '重命名';

  @override
  String get styleExplore_nameRequired => '名称不能为空';

  @override
  String get styleExplore_operationFailed => '操作失败';

  @override
  String get styleExplore_discardChangesTitle => '放弃未保存的修改？';

  @override
  String get styleExplore_discardChangesMessage => '当前工作区有未保存的修改，继续将丢弃这些修改。';

  @override
  String get styleExplore_discardChangesConfirm => '继续并丢弃';

  @override
  String get styleExplore_newRun => '新建探索';

  @override
  String styleExplore_runDeleted(String name) {
    return '已删除探索「$name」';
  }

  @override
  String get styleExplore_runStatusGenerating => '生成中';

  @override
  String get styleExplore_runStatusPaused => '已暂停';

  @override
  String get styleExplore_runStatusCancelled => '已取消';

  @override
  String get styleExplore_pauseRun => '暂停';

  @override
  String get styleExplore_cancelRun => '取消探索';

  @override
  String styleExplore_retryFailed(int count) {
    return '重试失败（$count）';
  }

  @override
  String styleExplore_manualRunName(String time) {
    return '手动候选 $time';
  }

  @override
  String get styleExplore_runBusy => '生成进行中，稍后再试';

  @override
  String get styleExplore_deleteRunTitle => '删除探索';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return '将删除「$name」及其候选图副本；图库中的源图不受影响。';
  }

  @override
  String get styleExplore_cancelRunTitle => '取消探索';

  @override
  String get styleExplore_cancelRunMessage => '取消后不可再启动；剩余待生成候选将标记为已取消。';

  @override
  String get styleExplore_filterAll => '全部';

  @override
  String get styleExplore_filterHearted => '收藏';

  @override
  String get styleExplore_renameFolder => '重命名分组';

  @override
  String get styleExplore_deleteFolder => '删除分组';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return '将删除分组「$name」；其中的候选回到未分组，图片不会被删除。';
  }

  @override
  String get styleExplore_folderNameLabel => '分组名称';

  @override
  String get styleExplore_deleteFamily => '删除进化线';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return '将删除进化线「$name」及其全部父本与子代记录（$count 张）；候选图片文件不会删除。';
  }

  @override
  String get styleExplore_familyBusy => '这条进化线还有生成中的候选，请先停止生成';

  @override
  String get styleExplore_folderUncategorized => '未分组';

  @override
  String styleExplore_folderCreated(String name) {
    return '已创建分组「$name」';
  }

  @override
  String get styleExplore_candidateMissing => '图片文件缺失';

  @override
  String get styleExplore_candidateDetailTitle => '候选详情';

  @override
  String get styleExplore_prevCandidate => '上一张';

  @override
  String get styleExplore_nextCandidate => '下一张';

  @override
  String styleExplore_roundNumber(int number) {
    return '第 $number 轮';
  }

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已存为块「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所选候选没有可保存的画师串或正向提示词';

  @override
  String get styleExplore_deleteImage => '删除图片';

  @override
  String get styleExplore_deleteImageTitle => '删除候选图';

  @override
  String get styleExplore_deleteImageMessage =>
      '将删除该候选在探索目录中的图片副本与候选记录；图库源图不受影响。';

  @override
  String get styleExplore_deleteImageDone => '已删除候选图与记录';

  @override
  String get styleExplore_selectCandidates => '多选';

  @override
  String styleExplore_selectedCount(int count) {
    return '已选 $count 张';
  }

  @override
  String get promptBlockEditor_library => '块库';

  @override
  String get promptBlockPicker_title => '选择块';

  @override
  String get promptBlockLibrary_thumbnail => '预览图';

  @override
  String get promptBlockLibrary_selectNewImage => '选择新图片';

  @override
  String get promptBlockLibrary_selectImage => '选择图片';

  @override
  String get promptBlockLibrary_adjustDisplayRange => '调整显示范围';

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
  String styleExplore_deepRoundCountHint(int min) {
    return '张数至少 $min（每个父本保底一张）';
  }

  @override
  String get styleExplore_deepRoundNoInstance => '主提示词中没有启用的随机遗传块，无法生成子代';

  @override
  String get styleExplore_deepRoundEmpty => '无法产生足够不同的子代画师组合';

  @override
  String get styleExplore_sortLeft => '左边更好';

  @override
  String get styleExplore_sortRight => '右边更好';

  @override
  String get styleExplore_sortNeither => '两张都不行';

  @override
  String get styleExplore_sortSkip => '跳过';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return '第 $current / 共 $total 对';
  }

  @override
  String get styleExplore_sortDone => '两两比较完成';

  @override
  String styleExplore_branchCreated(int count) {
    return '已培育下一代（$count 个父本）';
  }

  @override
  String get styleExplore_branchNeedLatest => '只能从最新代的子代培育下一代';

  @override
  String get styleExplore_branchRoundsIncomplete => '当前代还有未完成的子代，请等待或停止生成';

  @override
  String get styleExplore_branchDuplicate => '所选子代与第一代父本串完全重复';

  @override
  String get styleExplore_branchEmpty => '请至少选择一张子代候选';

  @override
  String styleExplore_pileManageDeleteDone(int count) {
    return '已删除 $count 张候选图与记录';
  }

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
  String get img2img_directorAddToQueue => '将结果加入输入队列';

  @override
  String get img2img_transform => '转换';

  @override
  String get img2img_palette => '调色板';

  @override
  String get img2img_paletteOff => '关闭';

  @override
  String get img2img_paletteAuto => '自动';

  @override
  String get img2img_paletteCustom => '自定义';

  @override
  String get img2img_avoidOverRefining => '避免过度细化';

  @override
  String get img2img_keepGridHint => '保留检测到的像素网格。';

  @override
  String get img2img_refineGridHint => '更细的像素尺寸更合适时，允许细化网格。';

  @override
  String get img2img_pixelUpscaleHint => '使用邻近像素放大，保持清晰的像素边缘。';

  @override
  String get img2img_pixelNativeHint => '保留对齐后的原生像素尺寸。';

  @override
  String get img2img_masked => '透明抠图';

  @override
  String get img2img_generated => '生成结果';

  @override
  String get img2img_blend => '混合结果';

  @override
  String get img2img_emotionHappy => '开心';

  @override
  String get img2img_emotionLaugh => '大笑';

  @override
  String get img2img_emotionSad => '伤心';

  @override
  String get img2img_emotionAngry => '生气';

  @override
  String get img2img_emotionSurprised => '惊讶';

  @override
  String get img2img_emotionShy => '害羞';

  @override
  String get img2img_emotionExcited => '兴奋';

  @override
  String get img2img_emotionDisgusted => '嫌弃';

  @override
  String get img2img_emotionSmug => '得意';

  @override
  String get img2img_emotionWorried => '担忧';

  @override
  String get img2img_emotionLove => '爱慕';

  @override
  String get img2img_emotionPlayful => '俏皮';

  @override
  String get img2img_emotionTired => '疲惫';

  @override
  String get img2img_emotionNeutral => '平静';

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
  String get auth_signInAccounts => '登录与账号';

  @override
  String get auth_notSignedIn => '尚未登录';

  @override
  String get auth_chooseAccountContinue => '选择账号，继续创作';

  @override
  String get auth_manageAccounts2 => '管理账号';

  @override
  String get auth_subscriptionExpired => '订阅已到期';

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
  String get promptBlockEditor_translationNeedsReview => '原文已修改，译文待更新';

  @override
  String get promptBlockEditor_translationReviewHint => '修改原文后请同步校对这里的译文';

  @override
  String get modelTask_translateTitle => '原文 → 阅读语言';

  @override
  String get modelTask_promptReverseTitle => '阅读语言 → 原文';

  @override
  String get modelTask_tagTranslateTitle => '标签名称翻译';

  @override
  String get modelTask_wikiTranslateTitle => '百科正文翻译';

  @override
  String get modelTask_translateDescription => '翻译提示词与积木，保留权重、分组和标签语义。';

  @override
  String get modelTask_promptReverseDescription => '结合原文落实译文中的增删修改，结果填回原文供确认。';

  @override
  String get modelTask_tagTranslateDescription => '为可见标签提供简洁、准确的名称释义。';

  @override
  String get modelTask_wikiTranslateDescription => '翻译百科正文、整理排版，并按语境选择可点击标签。';

  @override
  String get modelTask_connectionTest => '模型连接测试';

  @override
  String get modelReasoning_serviceDefault => '服务默认';

  @override
  String get modelReasoning_off => '关闭';

  @override
  String get modelReasoning_on => '开启';

  @override
  String get modelReasoning_minimal => '极低';

  @override
  String get modelReasoning_low => '低';

  @override
  String get modelReasoning_medium => '中';

  @override
  String get modelReasoning_high => '高';

  @override
  String get modelReasoning_xhigh => '极高';

  @override
  String get modelReasoning_max => '最高';

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
  String get modelParams_anthropicTemperatureRange =>
      'Anthropic 的 Temperature 应在 0–1 之间。';

  @override
  String get modelParams_anthropicSamplingConflict =>
      'Anthropic 的 Temperature 与 Top P 请选择一项；请检查模型参数。';

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
      '纯翻译通常无需开启思考；为兼顾打标、语义分类等处理，建议开启该模型支持的最低思考档位。';

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
  String get promptTranslation_guideRestoreTitle => 'A / 恢复';

  @override
  String get promptTranslation_guideRestoreText => '整组还原原文 / 恢复翻译块';

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
  String get blockOrganizer_barrierLabel => '块分类';

  @override
  String get blockOrganizer_replaceTitle => '替换同源块？';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '目标中已有 $count 个同源副本。替换后来源从块库隐藏；已插入提示词的实例仍可引用原块。';
  }

  @override
  String blockOrganizer_replaceCopyBody(Object count) {
    return '目标中已有 $count 个同源副本。替换会更新目标副本的内容，来源保留。';
  }

  @override
  String get blockOrganizer_replace => '替换';

  @override
  String get blockOrganizer_customTagColor => '自定义标签颜色';

  @override
  String get blockOrganizer_colorHint => '#RRGGBB 或 #AARRGGBB';

  @override
  String get blockOrganizer_invalidColor => '请输入六位或八位十六进制颜色';

  @override
  String blockOrganizer_deleteFolderConfirm(Object name) {
    return '删除「$name」？其中的块会移至根目录。';
  }

  @override
  String blockOrganizer_deleteCollectionConfirm(Object name) {
    return '删除「$name」？块本体会保留。';
  }

  @override
  String get blockOrganizer_titleFavorites => '收藏与收藏集';

  @override
  String get blockOrganizer_titleFolders => '选择文件夹';

  @override
  String blockOrganizer_itemCount(Object count) {
    return '$count 项';
  }

  @override
  String get blockOrganizer_search => '搜索';

  @override
  String get blockOrganizer_name => '名称';

  @override
  String get blockOrganizer_customColor => '自定义颜色…';

  @override
  String get blockOrganizer_newCollection => '新建收藏集';

  @override
  String get blockOrganizer_newCollectionFolder => '新建收藏文件夹';

  @override
  String get blockOrganizer_newTag => '新标签';

  @override
  String get blockOrganizer_newFolder => '新建文件夹';

  @override
  String get blockOrganizer_rootUncategorized => '根目录 / 未分类';

  @override
  String get blockOrganizer_manageDrag => '管理；拖动排序';

  @override
  String get blockLibrary_dragSelectedHint => '拖动已选块到左侧的收藏或文件夹，松开后选择复制或移动。';

  @override
  String blockLibrary_blockCount(Object count) {
    return '$count 个块';
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
  String get promptBlockEditor_appearance => '块外观';

  @override
  String get promptBlockEditor_imageUnreadable => '无法读取所选图像';

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
  String get opusUsage_exhausted => '账号免费额度已用尽，V5 生成按 Anlas 计费';

  @override
  String opusUsage_remaining(Object percent) {
    return '账号免费额度剩余 $percent%';
  }

  @override
  String opusUsage_recharging(Object time) {
    return '回充中：下一 +1% 还需 $time';
  }

  @override
  String get opusUsage_notRecharging => '当前不回充（池子在回充阈值之上或已用尽）';

  @override
  String get opusUsage_clickToRefresh => '点击刷新';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 小时 $minutes 分';
  }

  @override
  String opusUsage_hours(Object hours) {
    return '$hours 小时';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String opusUsage_minutes(Object minutes) {
    return '$minutes 分';
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
  String vibeImport_imageProgress(Object current, Object total, Object source) {
    return '导入图片($current/$total): $source';
  }

  @override
  String get vibeImport_clipboardSource => '剪贴板';

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
  String get img2img_directorEmotionHint => '仅适用于动漫图像，请从表情中性的图像开始。';

  @override
  String get img2img_emotionStrengthNormal => '正常';

  @override
  String get img2img_emotionStrengthSlightlyWeak => '稍弱';

  @override
  String get img2img_emotionStrengthWeak => '弱';

  @override
  String get img2img_emotionStrengthWeaker => '更弱';

  @override
  String get img2img_emotionStrengthVeryWeak => '很弱';

  @override
  String get img2img_emotionStrengthWeakest => '最弱';

  @override
  String get img2img_directorWeaken => '减弱表情';

  @override
  String get img2img_directorStrengthen => '增强表情';

  @override
  String get img2img_emotionScared => '害怕';

  @override
  String get img2img_emotionNervous => '紧张';

  @override
  String get img2img_emotionThinking => '思考';

  @override
  String get img2img_emotionConfused => '困惑';

  @override
  String get img2img_emotionBored => '无聊';

  @override
  String get img2img_emotionIrritated => '恼火';

  @override
  String get img2img_emotionAroused => '情欲';

  @override
  String get img2img_emotionEmbarrassed => '尴尬';

  @override
  String get img2img_emotionDetermined => '坚定';

  @override
  String get img2img_emotionHurt => '受伤';

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
  String get generation_moduleImage => '图像';

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
  String generation_historyBatchCount(int count) {
    return '$count 张';
  }

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
  String get library_addToGeneration => '加入生图';

  @override
  String get library_strength => '强度';

  @override
  String get library_information => '信息';

  @override
  String get library_fidelity => '保真';

  @override
  String get library_encodeOnUse => '用时编码';

  @override
  String get library_reencode => '需重新编码';

  @override
  String library_unusableModel(String model) {
    return '不能用于 $model';
  }

  @override
  String get library_exportAll => '导出全部';

  @override
  String get library_rescanFolders => '重新扫描文件夹';

  @override
  String get library_preview => '预览';

  @override
  String get viewer_backLocalGallery => '本地画廊';

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
  String get styleExplore_runNamingHint => '自动命名：随机块名 + 日期，双击名称即可改名';

  @override
  String styleExplore_roundGenerating(int round) {
    return '第 $round 轮 · 生成中';
  }

  @override
  String get styleExplore_inspectorTitle => '详情';

  @override
  String styleExplore_failedBadge(int count) {
    return '失败 $count';
  }

  @override
  String get styleExplore_showInspector => '展开检查器';

  @override
  String styleExplore_roundProgress(int round, int current, int total) {
    return '第 $round 轮 · $current / $total';
  }

  @override
  String get styleExplore_earlier => '更早';

  @override
  String get styleExplore_noMatchingRuns => '没有匹配的探索';

  @override
  String styleExplore_lineCount(int count) {
    return '$count 条进化线';
  }

  @override
  String get styleExplore_newRunDescription => '用当前提示词和参数开一个新的，名字可以之后改';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_largeCandidates => '大候选图';

  @override
  String get styleExplore_hideInspector => '收起检查器';

  @override
  String get styleExplore_searchRuns => '搜索探索名称或画师';

  @override
  String styleExplore_favoriteCount(int count) {
    return '收藏 $count';
  }

  @override
  String styleExplore_generatingBadge(int current, int total) {
    return '生成中 $current/$total';
  }

  @override
  String styleExplore_roundCount(int count) {
    return '$count 轮';
  }

  @override
  String styleExplore_pausedRemaining(int count) {
    return '已暂停 · 剩 $count 张';
  }

  @override
  String get styleExplore_stopRun => '停止生成';

  @override
  String get styleExplore_thisWeek => '本周';

  @override
  String get styleExplore_today => '今天';

  @override
  String get styleExplore_smallCandidates => '小候选图';

  @override
  String styleExplore_imageCount(int count) {
    return '$count 张';
  }

  @override
  String get styleExplore_variablesTitle => '随机变量';

  @override
  String get styleExplore_variablesHint => '每张重新抽取';

  @override
  String get styleExplore_variablesExplanation => '每张候选会记录启用的随机或顺序遗传块抽到了哪些内容。';

  @override
  String styleExplore_variablePoolSize(int count) {
    return '池 $count 项';
  }

  @override
  String get styleExplore_variableEvolutionTarget => '进化目标';

  @override
  String get styleExplore_variableNegative => '负面';

  @override
  String get styleExplore_variablesEmpty => '提示词里还没有随机块，抽出来的图会很像';

  @override
  String get styleExplore_openBlockLibrary => '打开块库';

  @override
  String get styleExplore_drawCountLabel => '本次抽取';

  @override
  String get styleExplore_drawCountSuffix => '张 · 逐张生成';

  @override
  String get styleExplore_candidatesTab => '候选';

  @override
  String get styleExplore_evolutionTab => '进化';

  @override
  String styleExplore_deepRoundTitle(String name, int generation) {
    return '进化 · $name 第 $generation 代';
  }

  @override
  String styleExplore_wallRoundCount(int count) {
    return '$count 张';
  }

  @override
  String get styleExplore_wallGenerating => '正在生成';

  @override
  String styleExplore_roundFailures(int count) {
    return '失败 $count';
  }

  @override
  String styleExplore_queued(int number) {
    return '排队 #$number';
  }

  @override
  String styleExplore_generatingCandidate(int number) {
    return '生成中 #$number';
  }

  @override
  String get styleExplore_generationFailed => '生成失败';

  @override
  String get styleExplore_failureHint => '悬停查看原因';

  @override
  String get styleExplore_imageDeleted => '图片已删除';

  @override
  String get styleExplore_parentBadge => '父本';

  @override
  String get styleExplore_opMutation => '变异';

  @override
  String get styleExplore_opCrossover => '交叉';

  @override
  String get styleExplore_opInjection => '注入';

  @override
  String get styleExplore_copyArtists => '复制画师串';

  @override
  String get styleExplore_interrupted => '已中断';

  @override
  String get styleExplore_emptyFilter => '没有符合筛选的候选';

  @override
  String get styleExplore_emptyRound => '本轮还没有候选';

  @override
  String get styleExplore_unfavorite => '取消收藏';

  @override
  String get styleExplore_groupLabel => '分组';

  @override
  String get styleExplore_newGroup => '新建分组…';

  @override
  String get styleExplore_saveBlock => '存为块';

  @override
  String get styleExplore_startEvolution => '开始进化';

  @override
  String get styleExplore_newestFirst => '最新轮在前';

  @override
  String get styleExplore_oldestFirst => '最早轮在前';

  @override
  String get styleExplore_pickEvolution => '挑几张去进化';

  @override
  String get styleExplore_deleteCandidatesTitle => '删除候选';

  @override
  String styleExplore_deleteCandidatesMessage(int count) {
    return '将删除 $count 张候选及其图片副本，图库源图保留。';
  }

  @override
  String get styleExplore_inspectorEmpty => '选一张候选查看详情';

  @override
  String get styleExplore_drawsTitle => '本张抽到';

  @override
  String get styleExplore_drawsAfterGeneration => '生成完成后显示';

  @override
  String get styleExplore_emptyDraw => '这次没有抽中（池里有空项）';

  @override
  String get styleExplore_hearted => '已收藏';

  @override
  String get styleExplore_joinEvolution => '加入进化';

  @override
  String get styleExplore_applyToEditor => '套用到编辑区';

  @override
  String get styleExplore_seedName => '种子';

  @override
  String get styleExplore_elapsedName => '耗时';

  @override
  String get styleExplore_parameters => '参数';

  @override
  String get styleExplore_modelName => '模型';

  @override
  String get styleExplore_fullPrompt => '完整提示词';

  @override
  String get styleExplore_mergedArtists => '合在一起的画师（去重）';

  @override
  String get styleExplore_selectionExplanation =>
      '存为块会把这些合成一个块；开始进化会把每张图的画师串作为一个父本。';

  @override
  String get styleExplore_quickGroupHint => '按 1–9 快速归组';

  @override
  String get styleExplore_newGroupChip => '新分组';

  @override
  String styleExplore_parameterSummary(
    int width,
    int height,
    int steps,
    String scale,
  ) {
    return '$width×$height · $steps 步 · $scale';
  }

  @override
  String get styleExplore_viewerBack => '画风探索';

  @override
  String styleExplore_viewerPosition(int index, int total) {
    return '第 $index 张 / 共 $total 张';
  }

  @override
  String get styleExplore_viewerGroupsShortcut => '按 1–9 归组，0 移回未分组';

  @override
  String get styleExplore_seedClickCopy => '种子（点击复制）';

  @override
  String get styleExplore_appliedToEditor => '已套用到编辑区';

  @override
  String styleExplore_generationNumber(int index) {
    return '第 $index 代';
  }

  @override
  String get styleExplore_currentGeneration => '当前';

  @override
  String styleExplore_generationStart(int count) {
    return '从候选里选了 $count 张作为起点';
  }

  @override
  String styleExplore_generationSource(int index, int count, int roots) {
    return '由第 $index 代挑 $count 张 + 第 1 代回交 $roots 张';
  }

  @override
  String get styleExplore_parentsByPreference => '父本 · 按偏好排序';

  @override
  String get styleExplore_backcross => '回交';

  @override
  String styleExplore_childrenCount(int count) {
    return '子代 · $count';
  }

  @override
  String styleExplore_breedSelected(int count, int index) {
    return '用选中的 $count 张培育第 $index 代';
  }

  @override
  String get styleExplore_generationBusy => '这一代还在生成';

  @override
  String get styleExplore_regeneratePrefix => '再生成';

  @override
  String get styleExplore_regenerateSuffix => '张子代';

  @override
  String get styleExplore_pairCompare => '两两比较排序';

  @override
  String get styleExplore_howToUse => '怎么用';

  @override
  String get styleExplore_helpParents => '父本是你选中的画师组合，偏好越高，越容易参与组合。';

  @override
  String get styleExplore_helpChildren => '子代由父本交叉、变异或从画师池注入新画师产生。';

  @override
  String get styleExplore_helpCompare => '两两比较会更新父本偏好，影响后续子代组合。';

  @override
  String get styleExplore_helpBackcross => '培育下一代时，会自动带上第 1 代父本做回交。';

  @override
  String get styleExplore_originTitle => '怎么来的';

  @override
  String get styleExplore_originCross => '由这几张父本的画师交叉组合';

  @override
  String get styleExplore_originMutation => '在父本基础上替换了部分画师';

  @override
  String get styleExplore_originInjection => '从池里注入了新画师';

  @override
  String get styleExplore_newArtist => '新';

  @override
  String get styleExplore_evolutionEmpty => '从候选里挑几张喜欢的，开始一条进化线';

  @override
  String get styleExplore_pickFromCandidates => '去候选里挑';

  @override
  String styleExplore_generationSummary(
    int parents,
    int children,
    int selected,
  ) {
    return '$parents 个父本 → $children 张子代 · 选了 $selected 张';
  }

  @override
  String get styleExplore_breedNext => '培育下一代';

  @override
  String get styleExplore_optionalName => '名称（可不填）';

  @override
  String get styleExplore_childrenEmpty => '还没有子代，在上面生成一批';

  @override
  String get styleExplore_evolutionStepOne => '父本的画师串互相变异、交叉';

  @override
  String get styleExplore_evolutionStepTwo => '可以两两比较帮你排序';

  @override
  String get styleExplore_evolutionStepThree => '选中的子代成为新父本';

  @override
  String get styleExplore_evolutionNewLine => '新建进化线';

  @override
  String styleExplore_evolutionJoinLine(String name) {
    return '加入「$name」当前代';
  }

  @override
  String get styleExplore_evolutionName => '进化线名称';

  @override
  String styleExplore_defaultEvolutionName(int n) {
    return '进化线 $n';
  }

  @override
  String get styleExplore_evolutionAddCustom => '再加一段自定义画师串';

  @override
  String get styleExplore_evolutionCustomHint => '输入画师串';

  @override
  String get styleExplore_evolutionParentEmpty => '没有可用的画师串';

  @override
  String get styleExplore_evolutionTarget => '子代会替换提示词里';

  @override
  String get styleExplore_evolutionOnlyCreate => '只创建';

  @override
  String get styleExplore_evolutionOnlyJoin => '只加入';

  @override
  String styleExplore_evolutionCreateGenerate(int count) {
    return '创建并生成 $count 张';
  }

  @override
  String styleExplore_evolutionJoinGenerate(int count) {
    return '加入并生成 $count 张';
  }

  @override
  String get styleExplore_evolutionFirstBatch => '第一批子代';

  @override
  String styleExplore_evolutionMinimum(int count) {
    return '张（至少 $count）';
  }

  @override
  String styleExplore_evolutionCreated(String name) {
    return '已创建进化线「$name」';
  }

  @override
  String styleExplore_evolutionJoined(String name) {
    return '已加入进化线「$name」';
  }

  @override
  String get styleExplore_sortLiveSave => '结果实时保存，可以随时关闭';

  @override
  String get styleExplore_sortRanking => '当前排名 · 实时';

  @override
  String get styleExplore_sortRankingHint => '排名会影响下一批子代里各父本被选中的概率';

  @override
  String get styleExplore_sortSpace => '空格';

  @override
  String styleExplore_saveSingleSubtitle(int n) {
    return '#$n 的画师存成一个块';
  }

  @override
  String styleExplore_saveManySubtitle(int count) {
    return '来自 $count 张候选，已合并去重';
  }

  @override
  String get styleExplore_saveArtistsOnly => '只要抽到的画师';

  @override
  String get styleExplore_saveFullPositive => '完整正向提示词';

  @override
  String get styleExplore_saveNoDraws => '这些候选没有正向遗传实例记录，请保存完整正向提示词';

  @override
  String get styleExplore_saveContent => '内容';

  @override
  String get styleExplore_saveRemoveAtoms => '点 × 去掉不要的画师';

  @override
  String styleExplore_saveRemoved(int count) {
    return '已去掉 $count 个';
  }

  @override
  String get styleExplore_saveRestore => '恢复';

  @override
  String get styleExplore_saveName => '名称';

  @override
  String get styleExplore_saveColor => '颜色';

  @override
  String get styleExplore_saveIcon => '图标';

  @override
  String get styleExplore_saveFolder => '放到块库';

  @override
  String get styleExplore_saveRoot => '根目录';

  @override
  String get styleExplore_saveHint => '存好后可以在块库里拖进提示词';

  @override
  String get styleExplore_onboardingTitle => '用随机块批量试画风';

  @override
  String get styleExplore_onboardingRandomTitle => '放入随机块';

  @override
  String get styleExplore_onboardingDrawTitle => '抽一批候选';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '抽 $count 张候选';
  }

  @override
  String get styleExplore_onboardingReviewTitle => '收藏、比较、进化';

  @override
  String get styleExplore_onboardingOpenPrevious => '打开以前的探索';

  @override
  String get styleExplore_onboardingSubtitle => '每张图都会从随机块里重新抽画师，你只管挑喜欢的';

  @override
  String get styleExplore_onboardingRandomDescription =>
      '在提示词里插入画师池，例如 400 精选画师池。左边会列出检测到的随机变量。';

  @override
  String styleExplore_onboardingDrawDescription(int count) {
    return '点左下角“抽 $count 张候选”。每张图下方会写出它抽到了哪些画师。';
  }

  @override
  String get styleExplore_onboardingReviewDescription =>
      '喜欢的按 F 收藏；挑几张开始进化，让好的画师组合继续杂交出新组合。';

  @override
  String styleExplore_onboardingDetected(int count) {
    return '已检测到 $count 个';
  }

  @override
  String get styleExplore_compareTitle => '两两比较 · 给父本排个序';

  @override
  String get styleExplore_compareQuestion => '哪张更接近你想要的画风？';

  @override
  String styleExplore_childLabel(int index) {
    return '子代 #$index';
  }

  @override
  String styleExplore_generationCounts(int parents, int children) {
    return '$parents 个父本 → $children 张子代';
  }

  @override
  String get styleExplore_viewLarge => '看大图';

  @override
  String get styleExplore_saveDialogTitle => '存为提示词块';

  @override
  String styleExplore_startDialogTitle(int count) {
    return '用 $count 张候选开始进化';
  }

  @override
  String get styleExplore_stepGenerate => '生成子代';

  @override
  String get styleExplore_stepPick => '挑出好的';

  @override
  String get styleExplore_stepBreed => '培育下一代';

  @override
  String styleExplore_firstGenerationParents(int count) {
    return '第 1 代父本 · $count';
  }

  @override
  String get styleExplore_evolutionTargetAfter => '的位置，其他内容不变';

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
  String get online_jumpToPage => '跳到页…';

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
  String get onlineFav_all => '全部';

  @override
  String get onlineFav_rootCollection => '根收藏';

  @override
  String get onlineFav_newCollection => '新增子集';

  @override
  String get onlineFav_renameCollection => '重新命名子集';

  @override
  String get onlineFav_deleteCollection => '刪除子集';

  @override
  String get onlineFav_empty => '還沒有收藏的作品';

  @override
  String onlineFav_authorWorkCount(Object n) {
    return '$n 張作品';
  }

  @override
  String get onlineFav_moveHere => '移到這裡';

  @override
  String get onlineFav_removeFavorite => '取消收藏';

  @override
  String get onlineFav_favoriteAuthor => '收藏作者';

  @override
  String get onlineFav_unfavoriteAuthor => '取消收藏作者';

  @override
  String get onlineFav_authorFavorited => '已收藏作者';

  @override
  String get onlineFav_authorUnfavorited => '已取消收藏作者';

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
  String get common_new => '新增';

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
  String get common_yesterday => '昨天';

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
  String get common_move => '移動';

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
  String get common_pack => '打包';

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
  String get nav_canvas => '畫布';

  @override
  String get nav_onlineGallery => '畫廊';

  @override
  String get nav_expandSidebar => '展開側邊欄';

  @override
  String get nav_collapseSidebar => '收起側邊欄';

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
  String get auth_tokenLogin => 'API Token 登入';

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
  String get auth_currentAccount => '當前帳號';

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
  String get settings_account => '帳戶';

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
  String get generation_title => '生成';

  @override
  String get generation_generate => '生成';

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
  String generation_progress(Object progress) {
    return '生成中... $progress%';
  }

  @override
  String get generation_lockHistoryScroll => '鎖定歷史滾動';

  @override
  String get generation_unlockHistoryScroll => '解鎖歷史滾動';

  @override
  String get generation_downloadAllImages => '下載全部影像';

  @override
  String get generation_selectMultiple => '多選';

  @override
  String get generation_deselectAll => '退出多選';

  @override
  String generation_deleteSelectedImages(int count) {
    return '刪除選中影像 ($count)';
  }

  @override
  String get generation_deleteSelectedImagesTitle => '刪除選中影像';

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
  String generation_canvasPinnedCount(int count) {
    return '固定 $count';
  }

  @override
  String get generation_params => '參數';

  @override
  String get generation_paramsSettings => '生成參數';

  @override
  String get generation_history => '歷史';

  @override
  String get generation_historyRecord => '歷史記錄';

  @override
  String get generation_failedStreamSnapshot => '失敗快照';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成未完成，僅保留最後一幀預覽；不可儲存、收藏或用於圖生圖';

  @override
  String get generation_noHistory => '暫無歷史記錄';

  @override
  String get generation_clearHistory => '清除歷史記錄';

  @override
  String get generation_clearHistoryConfirm => '確定要清除所有歷史記錄嗎？此操作不可復原。';

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
  String get generation_sectionReferenceImages => '參考圖';

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
  String get image_saveToLibrary => '儲存到詞庫';

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
  String get img2img_directorPrompt => '提示詞（可選）';

  @override
  String get img2img_directorRunning => '正在處理...';

  @override
  String get img2img_directorResult => '處理結果';

  @override
  String get img2img_directorApplied => '已將導演工具結果設為新的來源圖';

  @override
  String get img2img_directorDefry => 'Defry';

  @override
  String get img2img_directorApplyAsSource => '設為來源圖';

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
  String get img2img_upscalePanelOpened => '已開啟圖生圖超分面板';

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
  String get editor_back => '返回';

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
  String get editor_shortcut100Zoom => '100% 縮放';

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
  String get vibe_reuseButton => '一鍵複用';

  @override
  String get vibe_info => 'Vibe 資訊';

  @override
  String get vibe_name => '名稱';

  @override
  String get vibe_strength => '強度';

  @override
  String get vibe_infoExtracted => '資訊提取';

  @override
  String get vibe_shiftReplaceHint => 'Shift+點選 替換';

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
  String get gallery_metaSmea => 'SMEA';

  @override
  String get gallery_promptCopied => '已複製提示詞';

  @override
  String get gallery_seedCopied => '已複製 Seed';

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
  String get onlineGallery_search => '搜尋';

  @override
  String get onlineGallery_popular => '熱門';

  @override
  String get onlineGallery_favorites => '收藏';

  @override
  String get onlineGallery_refresh => '重新整理';

  @override
  String get onlineGallery_login => '登入';

  @override
  String get onlineGallery_logout => '登出';

  @override
  String get onlineGallery_dayRank => '日榜';

  @override
  String get onlineGallery_weekRank => '周榜';

  @override
  String get onlineGallery_monthRank => '月榜';

  @override
  String get onlineGallery_today => '今天';

  @override
  String onlineGallery_imageCount(Object count) {
    return '$count 張';
  }

  @override
  String get onlineGallery_loadFailed => '載入失敗';

  @override
  String get onlineGallery_favoritesEmpty => '收藏夾為空';

  @override
  String get onlineGallery_noResults => '沒有找到圖片';

  @override
  String get onlineGallery_pleaseLogin => '請先登入';

  @override
  String get onlineGallery_size => '尺寸';

  @override
  String get onlineGallery_score => '評分';

  @override
  String get onlineGallery_favCount => '收藏';

  @override
  String get onlineGallery_type => '類型';

  @override
  String get mediaType_video => '影片';

  @override
  String get mediaType_gif => '動圖';

  @override
  String get onlineGallery_tags => '標籤';

  @override
  String get onlineGallery_artists => '藝術家';

  @override
  String get onlineGallery_characters => '角色';

  @override
  String get onlineGallery_copyrights => '作品';

  @override
  String get onlineGallery_general => '通用';

  @override
  String get onlineGallery_copied => '已複製';

  @override
  String get onlineGallery_copyTags => '複製標籤';

  @override
  String get onlineGallery_open => '開啟';

  @override
  String get onlineGallery_send => '傳送';

  @override
  String get onlineGallery_sendToTextToImage => '傳送到文生圖';

  @override
  String get onlineGallery_sentToTextToImage => '已傳送到文生圖';

  @override
  String get onlineGallery_noTagInfo => '此圖片沒有標籤資訊';

  @override
  String get onlineGallery_promptSentToGeneration => '提示詞已傳送到生成頁面';

  @override
  String get onlineGallery_gifLoadFailed => 'GIF載入失敗';

  @override
  String get onlineGallery_pinchToZoom => '雙指縮放';

  @override
  String get onlineGallery_metadata => '後設資料';

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
  String get onlineGallery_all => '全部';

  @override
  String get onlineGallery_ratingGeneral => '全年齡';

  @override
  String get onlineGallery_ratingSensitive => '敏感';

  @override
  String get onlineGallery_ratingQuestionable => '可疑';

  @override
  String get onlineGallery_ratingExplicit => '限制級';

  @override
  String get onlineGallery_clear => '清除';

  @override
  String get onlineGallery_previousPage => '上一頁';

  @override
  String get onlineGallery_nextPage => '下一頁';

  @override
  String onlineGallery_pageN(Object page) {
    return '第 $page 頁';
  }

  @override
  String get onlineGallery_dateRange => '日期範圍';

  @override
  String get onlineGallery_fuzzySearch => '模糊匹配';

  @override
  String get onlineGallery_fuzzySearchTooltip =>
      '開啟後使用 *tag* 匹配相近標籤；關閉時按 Danbooru 精確標籤搜尋';

  @override
  String get onlineGallery_blacklistTags => '黑名單標籤';

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
  String get onlineGallery_bulkFavorite => '批次收藏';

  @override
  String get onlineGallery_bulkDownload => '批次下載';

  @override
  String get onlineGallery_unfavorited => '已取消收藏';

  @override
  String get onlineGallery_favorited => '已收藏';

  @override
  String onlineGallery_favoritedImages(Object count) {
    return '已收藏 $count 張圖片';
  }

  @override
  String onlineGallery_selectDownloadDirectoryFailed(Object error) {
    return '選擇下載目錄失敗: $error';
  }

  @override
  String onlineGallery_downloadSelectedStarted(Object count) {
    return '開始下載 $count 張圖片...';
  }

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return '下載完成: 成功 $success, 失敗 $failed';
  }

  @override
  String get onlineGallery_startDate => '開始日期';

  @override
  String get onlineGallery_endDate => '結束日期';

  @override
  String get onlineGallery_invalidDateFormat => '日期格式無效';

  @override
  String get onlineGallery_dateOutOfRange => '日期超出範圍';

  @override
  String get onlineGallery_last30Days => '最近30天';

  @override
  String get onlineGallery_configureGelbooruApi => '配置 Gelbooru API';

  @override
  String get onlineGallery_gelbooruApiReady => 'Gelbooru API 已驗證';

  @override
  String get onlineGallery_gelbooruApiInvalid => 'Gelbooru 憑據已失效';

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
  String get onlineGallery_aiTagQuery => '搜尋作品、作者、標題、標籤或模型';

  @override
  String get onlineGallery_aiTagPromptQuery =>
      'AI Prompt 搜尋（支援 ::artist: 等原始語法）';

  @override
  String get onlineGallery_aiTagTimeRange => '時間範圍';

  @override
  String get onlineGallery_aiTagAllTime => '全部';

  @override
  String get onlineGallery_aiTagCurrentMonthly => '即時月榜';

  @override
  String get onlineGallery_aiTagOlderMonthly => '更早歸檔';

  @override
  String get onlineGallery_aiTagRankingProcessing => '排行榜生成中，請稍後重試。';

  @override
  String get onlineGallery_aiTagNaiOnly => '僅 NAI';

  @override
  String get onlineGallery_aiTagModelVersion => '模型版本';

  @override
  String get onlineGallery_viewAuthor => '檢視此作者';

  @override
  String get onlineGallery_returnFromAuthor => '返回之前的瀏覽位置';

  @override
  String get onlineGallery_generationParams => '生成參數';

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
  String get onlineGallery_loadedAll => '已載入全部';

  @override
  String get onlineGallery_retryAppend => '載入失敗，點選重試';

  @override
  String onlineGallery_rankNumber(Object rank) {
    return '第 $rank 名';
  }

  @override
  String onlineGallery_multipleImages(Object count) {
    return '$count 張圖片';
  }

  @override
  String get onlineGallery_views => '瀏覽';

  @override
  String get onlineGallery_downloadAllMedia => '下載作品全部圖片';

  @override
  String get onlineGallery_copyFullMetadata => '複製完整後設資料';

  @override
  String get onlineGallery_metadataParseFailed => '後設資料解析失敗，原始內容已保留，可直接複製。';

  @override
  String get onlineGallery_gelbooruReadOnly => '只讀收藏';

  @override
  String get onlineGallery_gelbooruFavoritesSortHint =>
      '按帖子 ID 從新到舊排列，不保證與網站收藏時間順序一致。';

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
  String get localGallery_copySeed => '複製 Seed';

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
  String get statistics_title => '統計儀表盤';

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
  String get localGallery_dateFolders => '日期資料夾';

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
  String get tagLibrary_newCategory => '新增分類';

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
  String get shortcut_action_generation_prev_image => '預覽上一張（歷史聯動）';

  @override
  String get shortcut_action_generation_next_image => '預覽下一張（歷史聯動）';

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
  String get vibeLibrary_categories => '分類';

  @override
  String get vibeLibrary_createCategoryTitle => '新增分類';

  @override
  String get vibeLibrary_createSubCategoryTitle => '新增子分類';

  @override
  String get vibeLibrary_categoryNameHint => '請輸入分類名稱';

  @override
  String get vibeLibrary_createCategoryConfirm => '建立';

  @override
  String get vibeLibrary_deleteCategoryTitle => '確認刪除';

  @override
  String get vibeLibrary_deleteCategoryContent =>
      '確定要刪除此分類嗎？分類下的 Vibe 將被移動到未分類。';

  @override
  String get vibeLibrary_sortTooltip => '排序方式';

  @override
  String get vibeLibrary_openFolderTooltip => '開啟 Vibe 庫資料夾';

  @override
  String vibeLibrary_totalCount(Object count) {
    return '共 $count 個 Vibe';
  }

  @override
  String get vibeLibrary_noCategoriesAvailable => '沒有可用的分類';

  @override
  String get vibeLibrary_moveToCategory => '移動到分類';

  @override
  String get vibeLibrary_uncategorized => '未分類';

  @override
  String vibeLibrary_movedToCategory(Object count) {
    return '已移動 $count 個 Vibe';
  }

  @override
  String get vibeLibrary_favoriteStatusUpdated => '收藏狀態已更新';

  @override
  String get vibeLibrary_importFromFile => '從檔案匯入';

  @override
  String get vibeLibrary_importFromImage => '從圖片匯入';

  @override
  String get vibeLibrary_importFromClipboard => '從剪貼簿匯入編碼';

  @override
  String vibeLibrary_openFolderFailed(Object error) {
    return '開啟資料夾失敗: $error';
  }

  @override
  String get vibeLibrary_importFileDialogTitle => '選擇要匯入的 Vibe 檔案';

  @override
  String get vibeLibrary_preparingImport => '準備匯入...';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '成功匯入 $count 個 Vibe';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return '匯入完成: $success 成功, $failed 失敗';
  }

  @override
  String get vibeLibrary_dropImportHint =>
      '拖曳 .naiv4vibe/.naiv4vibebundle/.png/.jpg/.jpeg/.webp 檔案或資料夾到此處匯入';

  @override
  String get vibeLibrary_importing => '正在匯入...';

  @override
  String vibeLibrary_pageIndicator(Object current, Object total) {
    return '$current / $total 頁';
  }

  @override
  String get vibeLibrary_itemsPerPage => '每頁:';

  @override
  String get vibeLibrary_tooManyTitle => 'Vibe數量過多';

  @override
  String vibeLibrary_tooManySelectedContent(Object count) {
    return '選中了 $count 個Vibe，但最多隻能同時使用16個。\n\n請減少選擇數量後再試。';
  }

  @override
  String vibeLibrary_tooManyExistingContent(Object current, Object remaining) {
    return '當前生成頁面已有 $current 個Vibe，還可以新增 $remaining 個。\n\n請減少選擇數量後再試。';
  }

  @override
  String vibeLibrary_sentToGenerationCount(Object count) {
    return '已傳送 $count 個Vibe到生成頁面';
  }

  @override
  String vibeLibrary_deleteSelectedContent(Object count) {
    return '確定要刪除選中的 $count 個Vibe嗎？此操作無法復原。';
  }

  @override
  String vibeLibrary_deletedCount(Object count) {
    return '已刪除 $count 個Vibe';
  }

  @override
  String get vibeLibrary_importImageDialogTitle => '選擇包含 Vibe 的圖片';

  @override
  String get vibeLibrary_clipboardEmpty => '剪貼簿為空';

  @override
  String get vibeLibrary_encodeTimeout => '編碼逾時，請檢查網路連線';

  @override
  String get vibeLibrary_unknownError => '未知錯誤';

  @override
  String get vibeLibrary_save => '儲存到庫';

  @override
  String get vibeLibrary_import => '匯入 Vibe';

  @override
  String get vibeLibrary_searchHint => '搜尋名稱、標籤...';

  @override
  String get vibeLibrary_empty => 'Vibe 庫為空';

  @override
  String get vibeLibrary_emptyHint => '先去 Vibe 庫新增一些條目吧';

  @override
  String get vibeLibrary_allVibes => '全部 Vibe';

  @override
  String get vibeLibrary_favorites => '收藏';

  @override
  String get vibeLibrary_sendToGeneration => '傳送到生成';

  @override
  String get vibeLibrary_export => '匯出';

  @override
  String get vibeLibrary_edit => '編輯';

  @override
  String get vibeLibrary_delete => '刪除';

  @override
  String get vibeLibrary_addToFavorites => '收藏';

  @override
  String get vibeLibrary_removeFromFavorites => '取消收藏';

  @override
  String get vibeLibrary_newSubCategory => '新增子分類';

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
  String get vibeBulkTag_actionPreview => '操作預覽';

  @override
  String get vibeDetail_strengthDescription => '控制 Vibe 對生成結果的影響強度';

  @override
  String get vibeDetail_infoExtractedDescription => '控制從原圖提取的資訊量（消耗 2 Anlas）';

  @override
  String get vibeDetail_statistics => '統計資訊';

  @override
  String get vibeDetail_usageCount => '使用次數';

  @override
  String vibeDetail_timesUsed(int count) {
    return '$count 次';
  }

  @override
  String get vibeDetail_lastUsed => '最後使用';

  @override
  String get vibeDetail_neverUsed => '從未使用';

  @override
  String get vibeDetail_createdAt => '建立時間';

  @override
  String get vibeDetail_saveParameters => '儲存參數';

  @override
  String get vibe_export_title => '匯出 Vibe';

  @override
  String get vibe_export_format => '匯出格式';

  @override
  String get vibe_selector_title => '選擇 Vibe';

  @override
  String get vibe_selector_recent => '最近使用';

  @override
  String get vibe_export_include_thumbnails => '包含縮圖';

  @override
  String get vibe_export_include_thumbnails_subtitle => '匯出檔案中包含縮圖預覽';

  @override
  String get vibe_export_singleFile => '單檔案 (.naiv4vibe)';

  @override
  String get vibe_export_singleFileDescription =>
      '將每個 Vibe 匯出為單獨檔案，適合分享單個 Vibe';

  @override
  String get vibe_export_bundleFile => '打包檔案 (.naiv4vibebundle)';

  @override
  String get vibe_export_bundleFileDescription => '將多個 Vibe 打包到一個檔案中，適合批次備份';

  @override
  String get vibe_export_embedIntoPng => '嵌入到 PNG';

  @override
  String get vibe_export_embedIntoPngDescription => '通過寫入 PNG 後設資料匯出單個 Vibe';

  @override
  String get vibe_export_exportable => '可匯出';

  @override
  String get vibe_export_notExportable => '不可匯出';

  @override
  String get vibe_export_selectVibesToExport => '選擇要匯出的 Vibe';

  @override
  String vibe_export_exportSelected(int count) {
    return '匯出 ($count)';
  }

  @override
  String vibe_export_strengthPercent(int percent) {
    return '強度: $percent%';
  }

  @override
  String get vibe_export_pngCarrierImage => 'PNG 載體圖片';

  @override
  String get vibe_export_noUsablePngCarrier =>
      '這個 Vibe 沒有可直接使用的 PNG 載體圖片。你可以選擇外部 PNG 圖片作為載體。';

  @override
  String get vibe_export_selectExternalPngImage => '選擇外部 PNG 圖片...';

  @override
  String get vibe_export_changeExternalPngImage => '更換外部 PNG 圖片...';

  @override
  String get vibe_export_useVibeImageInstead => '改用 Vibe 圖片';

  @override
  String vibe_export_usingExternalPng(String fileName) {
    return '正在使用外部 PNG: $fileName';
  }

  @override
  String get vibe_export_selectPngImage => '選擇 PNG 圖片';

  @override
  String get vibe_export_invalidPngImage => '所選檔案不是有效的 PNG 圖片';

  @override
  String vibe_export_selectPngImageFailed(String error) {
    return '選擇 PNG 圖片失敗: $error';
  }

  @override
  String vibe_export_embeddingPng(String name) {
    return '正在嵌入 PNG: $name';
  }

  @override
  String vibe_export_exportCompleteCounts(int successCount, int failCount) {
    return '匯出完成: 成功 $successCount 個，失敗 $failCount 個';
  }

  @override
  String vibe_export_exportCompletePath(String path) {
    return '匯出完成: $path';
  }

  @override
  String vibe_export_packingVibes(int count) {
    return '正在打包 $count 個 Vibe...';
  }

  @override
  String vibe_export_exportingName(String name) {
    return '正在匯出: $name';
  }

  @override
  String get vibe_export_selectExportFolder => '選擇匯出資料夾';

  @override
  String get vibe_export_generatingBundleFile => '正在生成打包檔案...';

  @override
  String vibe_export_bundleTitle(String name) {
    return '匯出 Bundle: $name';
  }

  @override
  String vibe_export_vibesTitle(int count) {
    return '匯出 Vibe ($count 個已選)';
  }

  @override
  String get vibe_export_method => '匯出方式';

  @override
  String get vibe_export_wholeBundle => '整個 Bundle';

  @override
  String get vibe_export_internalVibe => '內部 Vibe';

  @override
  String vibe_export_wholeBundleDescription(int count) {
    return '匯出包含全部 $count 個 Vibe 的 .naiv4vibebundle 檔案';
  }

  @override
  String vibe_export_internalVibeDescription(int count) {
    return '選擇 Bundle 內部 Vibe，分別匯出為 .naiv4vibe 檔案 (共 $count 個)';
  }

  @override
  String get vibe_export_exportBundle => '匯出 Bundle';

  @override
  String get vibe_export_exportAsFiles => '匯出為檔案';

  @override
  String get vibe_export_exportBundleDescription => '匯出為 .naiv4vibebundle 檔案';

  @override
  String get vibe_export_exportAsFilesDescription =>
      '匯出為 .naiv4vibe 或 .naiv4vibebundle 檔案';

  @override
  String get vibe_export_exportAsZip => '匯出為 ZIP';

  @override
  String get vibe_export_exportAsZipDescription =>
      '將選中的 Vibe 庫條目作為獨立檔案打包為 .zip';

  @override
  String get vibe_export_compressData => '壓縮資料';

  @override
  String get vibe_export_compressDataDescription => '使用壓縮以減小檔案大小 (推薦用於批次匯出)';

  @override
  String get vibe_export_zipCompressDescription => '壓縮 ZIP 內的檔案以減小體積';

  @override
  String get vibe_export_exportAsPng => '匯出為 PNG';

  @override
  String get vibe_export_pngInternalBundleUnsupported =>
      '匯出單個 Bundle 內部 Vibe 時不支援嵌入圖片';

  @override
  String get vibe_export_embedVibeDataIntoPng => '將 Vibe 資料寫入 PNG 後設資料';

  @override
  String get vibe_export_batchPngUsesFirstImage =>
      '批次匯出會使用每個 Vibe 的第一張可用圖片，沒有圖片的條目會自動跳過。';

  @override
  String get vibe_export_exportCarrierImage => '匯出載體圖片';

  @override
  String get vibe_export_usingExternalCarrierImage => '正在使用外部 PNG 作為匯出載體圖片';

  @override
  String get vibe_export_exportAsEncodings => '匯出為編碼';

  @override
  String get vibe_export_exportAsEncodingsDescription =>
      '將資料匯出為編碼 (JSON 或 Base64)';

  @override
  String get vibe_export_jsonDescription => '匯出為格式化 JSON 檔案，便於閱讀和編輯';

  @override
  String get vibe_export_base64Description => '匯出為純 Base64，便於複製和分享';

  @override
  String get vibe_export_selectAtLeastOneMethod => '請選擇至少一種匯出方式';

  @override
  String get vibe_export_batchPngUnsupported =>
      '批次 Vibe 匯出不支援嵌入 PNG。請使用單個 Vibe 匯出介面。';

  @override
  String get vibe_export_selectPngCarrier => '請選擇用於匯出的 PNG 載體圖片';

  @override
  String get vibe_export_selectAtLeastOneInternalVibe => '請選擇至少一個內部 Vibe';

  @override
  String get vibe_export_selectVibeExportFolder => '選擇 Vibe 匯出資料夾';

  @override
  String get vibe_export_saveEncodingFile => '儲存編碼檔案';

  @override
  String get vibe_export_preparingExport => '正在準備匯出...';

  @override
  String vibe_export_preparingVibeProgress(int current, int total) {
    return '正在讀取 Vibe $current/$total...';
  }

  @override
  String get vibe_export_exportingBundle => '正在匯出 Bundle...';

  @override
  String get vibe_export_exportingZip => '正在匯出 ZIP...';

  @override
  String get vibe_export_embeddingImage => '正在嵌入圖片...';

  @override
  String get vibe_export_exportingEncoding => '正在匯出編碼...';

  @override
  String vibe_export_exportFailedWithError(String error) {
    return '匯出失敗: $error';
  }

  @override
  String get vibe_export_noExportableEntries => '沒有可匯出的 Vibe 條目';

  @override
  String get vibe_export_bundleFilePathEmpty => 'Bundle 檔案路徑為空';

  @override
  String vibe_export_invalidImageFormatWithError(String error) {
    return '無效的圖片格式: $error';
  }

  @override
  String vibe_export_embedFailedWithError(String error) {
    return '嵌入失敗: $error';
  }

  @override
  String vibe_export_embedImageFailedWithError(String error) {
    return '嵌入圖片失敗: $error';
  }

  @override
  String vibe_export_extractingVibeProgress(int current, int total) {
    return '正在提取 Vibe $current/$total...';
  }

  @override
  String vibe_export_selectImageFailed(String error) {
    return '選擇圖片失敗: $error';
  }

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
  String get vibe_import_skip => '跳過';

  @override
  String get vibe_import_confirm => '確認';

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
  String get vibe_import_title => '從庫匯入';

  @override
  String vibe_import_result(int count) {
    return '已匯入 $count 個 vibes';
  }

  @override
  String get vibe_import_fileParseFailed => '解析檔案失敗';

  @override
  String get vibe_import_fileSelectionFailed => '檔案選擇失敗';

  @override
  String get vibe_import_importFailed => '匯入失敗';

  @override
  String get vibe_import_bundleTitle => '匯入 Vibe Bundle';

  @override
  String get vibe_import_bundleChooseMethod => '選擇匯入方式';

  @override
  String get vibe_import_bundleAsWhole => '作為整體匯入';

  @override
  String get vibe_import_bundleAsWholeDescription => '保留 Bundle 結構，並作為一個庫條目匯入';

  @override
  String get vibe_import_bundleSplitEntries => '拆分為獨立條目';

  @override
  String get vibe_import_bundleSplitEntriesDescription => '將每個 Vibe 作為獨立庫條目匯入';

  @override
  String get vibe_import_bundleSelectVibes => '選擇要匯入的 Vibe';

  @override
  String get vibe_import_bundleSelectVibesDescription => '僅匯入選中的 Vibe';

  @override
  String get vibe_import_bundleConfigureEachVibe => '配置每個 Vibe 的參數';

  @override
  String get vibe_import_bundleSelectAndConfigureEachVibe => '選擇並配置每個 Vibe 的參數';

  @override
  String vibe_import_bundleSelectedCount(int selected, int total) {
    return '已選擇 $selected/$total';
  }

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
  String get search_results => '搜尋結果';

  @override
  String get search_noResults => '未找到匹配結果';

  @override
  String get addToCurrent => '新增到當前';

  @override
  String get replaceExisting => '替換現有';

  @override
  String get confirmSelection => '確認選擇';

  @override
  String get selectAll => '全選';

  @override
  String get clearSelection => '清空';

  @override
  String get clearFilters => '清除篩選';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 詳情';

  @override
  String get shortcut_action_vibe_detail_rename => '重新命名';

  @override
  String get vibeSelectorFilterFavorites => '收藏';

  @override
  String get vibeSelectorFilterSourceAll => '全部類型';

  @override
  String get vibeSelectorSortCreated => '建立時間';

  @override
  String get vibeSelectorSortLastUsed => '最近使用';

  @override
  String get vibeSelectorSortUsedCount => '使用次數';

  @override
  String get vibeSelectorSortName => '名稱';

  @override
  String vibeSelectorItemsCount(int count) {
    return '$count 項';
  }

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
  String get settings_defaultHivePath => '預設 (%APPDATA%/NAI_Launcher/hive/)';

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
  String toast_deletedNamed(Object name) {
    return '已刪除: $name';
  }

  @override
  String get toast_vibeParamSaveReencodeFailed => '儲存參數失敗，Vibe 重新編碼失敗';

  @override
  String get toast_exportSuccess => '匯出成功';

  @override
  String toast_exportFailed(Object error) {
    return '匯出失敗: $error';
  }

  @override
  String get toast_selectVibeToExport => '請先選擇要匯出的 Vibe';

  @override
  String get toast_embedPngSingleVibeOnly => '嵌入 PNG 僅支援單個 Vibe 匯出';

  @override
  String get toast_selectPngCarrier => '請選擇一個 PNG 載體圖用於匯出';

  @override
  String get toast_renameSuccess => '重新命名成功';

  @override
  String get toast_paramsSaved => '參數已儲存';

  @override
  String get toast_paramsSaveFailed => '儲存參數失敗';

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
  String get toast_favorited => '已收藏';

  @override
  String get toast_unfavorited => '已取消收藏';

  @override
  String toast_favoriteUpdateFailed(Object error) {
    return '收藏狀態更新失敗: $error';
  }

  @override
  String toast_packingImages(Object count) {
    return '正在打包 $count 張圖片...';
  }

  @override
  String toast_packedImages(Object count) {
    return '已打包 $count 張圖片';
  }

  @override
  String get toast_packFailed => '打包失敗';

  @override
  String toast_packFailedWithError(Object error) {
    return '打包失敗: $error';
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
  String get toast_imagePromptCopied => '已複製 Prompt';

  @override
  String get toast_imageHasNoPrompt => '此圖片沒有 Prompt';

  @override
  String get toast_useDeleteButton => '請使用介面刪除按鈕';

  @override
  String get toast_imageDataUnavailable => '影像資料不可用，無法複製';

  @override
  String get toast_vibeDataCopied => 'Vibe 資料已複製';

  @override
  String get toast_characterPromptCopied => '角色提示詞已複製';

  @override
  String toast_copiedTitle(Object title) {
    return '$title已複製';
  }

  @override
  String toast_replacedVibesCount(Object count, Object name) {
    return '已替換為 $count 個 Vibe: $name';
  }

  @override
  String toast_sentVibesCount(Object count, Object name) {
    return '已傳送 $count 個 Vibe 到生成頁面: $name';
  }

  @override
  String toast_replacedVibe(Object name) {
    return '已替換為: $name';
  }

  @override
  String toast_sentVibeToGeneration(Object name) {
    return '已傳送到生成頁面: $name';
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
  String get toast_renameNameRequired => '名稱不能為空';

  @override
  String get toast_renameNameConflict => '名稱已存在，請使用其他名稱';

  @override
  String get toast_renameEntryNotFound => '條目不存在，可能已被刪除';

  @override
  String get toast_renameFilePathMissing => '該條目缺少檔案路徑，無法重新命名';

  @override
  String get toast_renameFileFailed => '重新命名檔案失敗，請稍後重試';

  @override
  String get toast_renameFailed => '重新命名失敗，請稍後重試';

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
  String get common_pleaseWait => '請稍候';

  @override
  String get common_change => '更換';

  @override
  String get common_expand => '展開';

  @override
  String get common_collapse => '收起';

  @override
  String get vibeLibrary_emptySearchTitle => '未找到匹配的 Vibe';

  @override
  String get vibeLibrary_emptySearchSubtitle => '嘗試其他關鍵詞';

  @override
  String get vibeLibrary_emptyFavoritesTitle => '暫無收藏的 Vibe';

  @override
  String get vibeLibrary_emptyFavoritesSubtitle => '點選心形圖示收藏 Vibe';

  @override
  String get vibeLibrary_emptyCategoryTitle => '該分類下暫無 Vibe';

  @override
  String get vibeLibrary_emptyCategorySubtitle => '嘗試切換到\"全部 Vibe\"檢視所有內容';

  @override
  String get vibeLibrary_emptyNoMatchesTitle => '無匹配結果';

  @override
  String get vibeLibrary_emptySaveFromGenerationHint => '從生成頁面儲存Vibe到庫中';

  @override
  String get vibe_nameRequired => '名稱不能為空';

  @override
  String get vibe_import_namingTitle => '命名 Vibe';

  @override
  String get vibe_import_nameConflictOverwrite => '該名稱已存在，將被覆蓋';

  @override
  String get vibe_previewLoadFailed => '預覽載入失敗';

  @override
  String get vibe_import_applyToRemainingFiles => '應用到後續所有檔案';

  @override
  String get vibe_import_applyNamingToRemainingFiles => '使用此命名規則處理剩餘檔案';

  @override
  String get vibe_encodeImageTitle => '編碼圖片為 Vibe';

  @override
  String get vibe_imagePreview => '圖片預覽';

  @override
  String get vibe_encodeStartButton => '開始編碼';

  @override
  String get vibe_encodeImageInProgress => '正在編碼圖片...';

  @override
  String vibe_encodeErrorImage(Object fileName) {
    return '圖片: $fileName';
  }

  @override
  String vibe_encodeErrorMessage(Object error) {
    return '錯誤: $error';
  }

  @override
  String get vibe_encodeSkipImage => '跳過此圖';

  @override
  String get detail_sendToImg2Img => '傳送到圖生圖';

  @override
  String get detail_loadingImage => '載入圖片中...';

  @override
  String get detail_imageLoadFailed => '無法載入圖片';

  @override
  String get detail_noImage => '無圖片';

  @override
  String get detail_parsingMetadata => '正在解析後設資料...';

  @override
  String get detail_noMetadata => '此圖片無後設資料';

  @override
  String get detail_metadata => '後設資料';

  @override
  String get detail_imageDetails => '圖片詳情';

  @override
  String get detail_basicInfo => '基本資訊';

  @override
  String get detail_fileName => '檔名';

  @override
  String get detail_modifiedTime => '修改時間';

  @override
  String get detail_fileSize => '檔案大小';

  @override
  String get detail_noContent => '(無內容)';

  @override
  String get detail_saveBlock => '儲存為塊';

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
  String get detail_copyCharacterPrompt => '複製角色提示詞';

  @override
  String get detail_copyAllVibeData => '複製全部 Vibe 資料';

  @override
  String get detail_saveToVibeLibrary => '儲存到 Vibe 庫';

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
  String get preciseRefLib_title => '精準參考庫';

  @override
  String get preciseRefLib_searchHint => '搜尋參考圖...';

  @override
  String get preciseRefLib_empty => '拖曳或貼上圖片到此處建立庫';

  @override
  String get preciseRefLib_emptyHint => '也可以在生成結果、歷史記錄或本地圖庫中右鍵儲存';

  @override
  String get preciseRefLib_import => '匯入圖片';

  @override
  String preciseRefLib_entryCount(int count) {
    return '$count 個條目';
  }

  @override
  String get preciseRefLib_sendToPreciseRef => '傳送到精準參考';

  @override
  String get preciseRefLib_sendToImg2Img => '傳送到圖生圖';

  @override
  String get preciseRefLib_editEntry => '編輯參數';

  @override
  String get preciseRefLib_confirmDeleteTitle => '刪除條目';

  @override
  String preciseRefLib_confirmDelete(String name) {
    return '確定刪除“$name”？圖片檔案將一併刪除。';
  }

  @override
  String preciseRefLib_saved(String name) {
    return '已存入精準參考庫：$name';
  }

  @override
  String get preciseRefLib_savedHint => '可在精準參考庫中編輯參數';

  @override
  String preciseRefLib_sent(String name) {
    return '已傳送到精準參考：$name';
  }

  @override
  String preciseRefLib_sentToImg2Img(String name) {
    return '已傳送到圖生圖：$name';
  }

  @override
  String get preciseRefLib_imageMissing => '原圖檔案丟失';

  @override
  String get preciseRefLib_invalidImage => '無法識別圖片格式，或圖片檔案已經損壞';

  @override
  String get preciseRefLib_deleteFailed => '刪除失敗，條目與原圖已保留，請稍後重試';

  @override
  String get preciseRefLib_favoritesOnly => '只看收藏';

  @override
  String get preciseRefLib_sortBy => '排序方式';

  @override
  String get preciseRefLib_sortCreatedAt => '建立時間';

  @override
  String get preciseRefLib_sortLastUsed => '最近使用';

  @override
  String get preciseRefLib_sortUsedCount => '使用次數';

  @override
  String get preciseRefLib_sortName => '名稱';

  @override
  String preciseRefLib_importedCount(int count) {
    return '已匯入 $count 張圖片';
  }

  @override
  String preciseRefLib_loadFailed(String error) {
    return '載入精準參考庫失敗：$error';
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
  String get preciseRefLib_selectorTitle => '從精準參考庫選擇';

  @override
  String preciseRefLib_selectorConfirm(int count) {
    return '新增所選 ($count)';
  }

  @override
  String get preciseRefLib_nameLabel => '名稱';

  @override
  String get preciseRefLib_typeFilterAll => '全部';

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
  String get history_dragFilePreparationFailed => '拖曳檔案準備失敗，請稍後重試';

  @override
  String get history_dragFilePreparing => '正在準備拖曳檔案...';

  @override
  String get history_dragFileNotReady => '拖曳檔案尚未準備完成';

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
  String get vibeDetail_useAll => '使用全部';

  @override
  String get vibeDetail_longPressSetCover => '長按設為封面';

  @override
  String get vibeDetail_noPreviewImage => '無預覽影像';

  @override
  String get vibeDetail_dropPreviewImage => '拖曳圖片到此處設定預覽圖';

  @override
  String get vibeDetail_releasePreviewImage => '釋放以設定預覽圖';

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
  String get nav_promptBlockLibrary => '提示詞塊';

  @override
  String get promptBlockLibrary_title => '提示詞塊';

  @override
  String get promptBlockLibrary_folders => '資料夾';

  @override
  String get promptBlockLibrary_allBlocks => '全部塊';

  @override
  String get promptBlockLibrary_rootFolder => '根目錄 / 未分類';

  @override
  String get promptBlockLibrary_unnamedBlock => '未命名塊';

  @override
  String get promptBlockLibrary_noBlockSelected => '未選擇塊';

  @override
  String get promptBlockLibrary_details => '詳情';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '使用 $count 次';
  }

  @override
  String get promptBlockPill_missing => '塊已刪除';

  @override
  String get promptBlockPill_unknown => '失效塊';

  @override
  String get pillCardReroll => '重抽';

  @override
  String get pillCardRerollLocked => '已鎖定，無法重抽';

  @override
  String get pillCardLock => '鎖定當前內容';

  @override
  String get pillCardUnlock => '解除鎖定';

  @override
  String get pillCardSettings => '隨機設定';

  @override
  String get pillCardEnable => '啟用';

  @override
  String get pillCardDisable => '停用';

  @override
  String get pillCardDeleteInstance => '刪除實例';

  @override
  String get pillCardEmptyRoll => '（本次為空）';

  @override
  String get pillCardEvolutionEnable => '開啟遺傳';

  @override
  String get pillCardEvolutionDisable => '關閉遺傳';

  @override
  String get pillCardEvolutionRequiresEnabled => '需先啟用實例';

  @override
  String get pillCardStepBack => '退回一幕';

  @override
  String get pillCardStepForward => '前進一幕';

  @override
  String get pillSettingsTitle => '塊實例設定';

  @override
  String get pillSettingsModeFixed => '固定';

  @override
  String get pillSettingsModeSequential => '順序';

  @override
  String get pillSettingsModeRandom => '隨機抽取';

  @override
  String get pillSettingsCount => '抽取數量';

  @override
  String get pillSettingsOrder => '輸出順序';

  @override
  String get pillSettingsOrderDrawn => '按抽中順序';

  @override
  String get pillSettingsOrderOriginal => '按池原序';

  @override
  String get pillSettingsWeight => '隨機權重';

  @override
  String get pillSettingsWeightMin => '最小';

  @override
  String get pillSettingsWeightMax => '最大';

  @override
  String get pillSettingsWeightAverage => '平均';

  @override
  String get pillSettingsDispersion => '離散';

  @override
  String get pillSettingsDispersionFocused => '集中';

  @override
  String get pillSettingsDispersionBalanced => '均衡';

  @override
  String get pillSettingsDispersionSpread => '發散';

  @override
  String get pillSettingsAdvanced => '進階';

  @override
  String get pillSettingsLeftDispersion => '左離散';

  @override
  String get pillSettingsRightDispersion => '右離散';

  @override
  String get pillSettingsSoftBalance => '軟平衡';

  @override
  String get pillSettingsSoftBalanceStrength => '回拉強度';

  @override
  String get pillSettingsTriggerProbability => '觸發機率';

  @override
  String get pillSettingsCancel => '取消';

  @override
  String get pillSettingsApply => '確定';

  @override
  String get promptBlockLibrary_unnamedFolder => '未命名資料夾';

  @override
  String get promptBlockLibrary_scope => '瀏覽範圍';

  @override
  String get promptBlockLibrary_newBlock => '新增塊';

  @override
  String get promptBlockLibrary_editBlock => '編輯塊';

  @override
  String get promptBlockLibrary_newFolder => '新增資料夾';

  @override
  String get promptBlockLibrary_newSubfolder => '新增子資料夾';

  @override
  String get promptBlockLibrary_renameFolder => '重新命名資料夾';

  @override
  String get promptBlockLibrary_moveToRoot => '移到根目錄';

  @override
  String get promptBlockLibrary_moveToFolder => '移動到資料夾';

  @override
  String get promptBlockLibrary_favorites => '收藏';

  @override
  String get promptBlockLibrary_unclassified => '未分類';

  @override
  String get promptBlockLibrary_newCollection => '新增收藏集';

  @override
  String get promptBlockLibrary_newSubcollection => '新增子收藏集';

  @override
  String get promptBlockLibrary_newCollectionFolder => '新增收藏資料夾';

  @override
  String get promptBlockLibrary_renameCollection => '重新命名收藏集';

  @override
  String get promptBlockLibrary_renameCollectionFolder => '重新命名收藏資料夾';

  @override
  String get promptBlockLibrary_moveToFavoritesRoot => '移到收藏區根級';

  @override
  String get promptBlockLibrary_unnamedCollection => '未命名收藏集';

  @override
  String get promptBlockLibrary_unnamedCollectionFolder => '未命名收藏資料夾';

  @override
  String get promptBlockLibrary_collectionName => '收藏集名稱';

  @override
  String get promptBlockLibrary_collectionNameHint => '收藏集名稱';

  @override
  String get promptBlockLibrary_noCollections =>
      '還沒有收藏集 —— 點「收藏」行旁的 + 新增，或把塊拖到收藏集上';

  @override
  String get promptBlockLibrary_noFolders => '還沒有資料夾';

  @override
  String get promptBlockLibrary_emptyFavorites => '還沒有收藏的塊，點塊上的 ★ 即可收藏';

  @override
  String get promptBlockLibrary_emptyCollection => '該收藏集為空';

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
  String get promptBlockLibrary_searchHint => '搜尋標題、提示詞或標籤';

  @override
  String get promptBlockLibrary_folder => '資料夾';

  @override
  String get promptBlockLibrary_folderName => '資料夾名稱';

  @override
  String get promptBlockLibrary_folderNameHint => '資料夾名稱';

  @override
  String get promptBlockLibrary_basicPrompt => '基礎提示詞';

  @override
  String get promptBlockLibrary_generationSettings => '設定';

  @override
  String get promptBlockLibrary_settingsOptionalHint => '僅儲存填寫的參數；插入塊後可手動應用設定。';

  @override
  String get promptBlockLibrary_notSpecified => '不指定';

  @override
  String get promptBlockLibrary_stepsLabel => '步數';

  @override
  String get promptBlockLibrary_noiseScheduleLabel => '噪聲排程';

  @override
  String get promptBlockLibrary_invalidGenerationSettings =>
      '請檢查設定：步數 1–50、提示詞引導 1–20、提示詞引導重縮放 0–1，並確認參數受所選模型支援。';

  @override
  String get promptBlockLibrary_applySettings => '匯入設定';

  @override
  String get promptBlockLibrary_settingsApplied => '塊設定已匯入當前畫面';

  @override
  String get promptBlockLibrary_settingsIncompatible => '塊設定與目標模型不相容，未匯入任何參數。';

  @override
  String get promptBlockLibrary_noSettings => '此塊未儲存生圖參數';

  @override
  String get promptBlockLibrary_tags => '標籤';

  @override
  String get promptBlockLibrary_addTag => '新增標籤';

  @override
  String get promptBlockLibrary_tagName => '標籤名稱';

  @override
  String get promptBlockLibrary_tagColor => '標籤顏色（十六進位）';

  @override
  String get promptBlockLibrary_duplicateTag => '這個塊已有同名標籤';

  @override
  String get promptBlockLibrary_invalidTagColor => '請輸入有效的十六進位顏色';

  @override
  String get pillCard_rollScope => '變化範圍';

  @override
  String get pillCard_positiveScope => '正面';

  @override
  String get pillCard_negativeScope => '負面';

  @override
  String get promptBlockLibrary_modelResetNotice => '切換模型後，不支援的參數已清除。';

  @override
  String get promptBlockLibrary_atomInputHint => '輸入文本，回車變成原子塊';

  @override
  String get promptBlockLibrary_atomRestoreHint => '點選還原成文本再編輯';

  @override
  String get promptBlockLibrary_atomOrphan => '未知標記';

  @override
  String get promptBlockLibrary_atomEditorTutorial =>
      '輸入後回車成塊，點選還原為文本，儲存時所有未成塊文本自動轉化。';

  @override
  String get promptBlockLibrary_color => '顏色';

  @override
  String get promptBlockLibrary_icon => '圖示';

  @override
  String get promptBlockLibrary_saved => '已儲存';

  @override
  String get promptBlockLibrary_copied => '正文已複製';

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
  String get promptBlockLibrary_moveTo => '移動到…';

  @override
  String get promptBlockLibrary_moveToFolderTitle => '移動到資料夾';

  @override
  String promptBlockLibrary_deleteBlocksConfirm(int count) {
    return '確定要刪除選中的 $count 個塊嗎？此操作無法復原。';
  }

  @override
  String promptBlockLibrary_deleteSelected(int count) {
    return '刪除選中的 $count 個塊';
  }

  @override
  String get promptBlockLibrary_empty => '還沒有提示詞塊';

  @override
  String get promptBlockLibrary_emptyFolder => '此資料夾為空';

  @override
  String get promptBlockLibrary_noSearchResults => '沒有匹配的塊';

  @override
  String get promptBlockLibrary_tryDifferentSearch => '請嘗試其他搜尋詞';

  @override
  String get promptBlockLibrary_emptyHint => '新增一個塊，開始整理可複用的文本';

  @override
  String promptBlockLibrary_loadFailed(String error) {
    return '載入提示詞塊失敗：$error';
  }

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
  String get promptBlockLibrary_importExport => '匯入 / 匯出';

  @override
  String get promptBlockLibrary_importTxtFiles => '匯入 TXT 檔案';

  @override
  String get promptBlockLibrary_importFromFolder => '從資料夾匯入…';

  @override
  String get promptBlockLibrary_exportLibraryBackup => '匯出庫備份…';

  @override
  String get promptBlockLibrary_importLibraryBackup => '匯入庫備份…';

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
  String promptBlockLibrary_libraryBackupDone(int count) {
    return '已匯出 $count 個塊的庫備份';
  }

  @override
  String get promptBlockLibrary_libraryImportTitle => '選擇庫備份檔案';

  @override
  String get promptBlockLibrary_libraryBackupInvalid => '不是有效的塊庫備份檔案';

  @override
  String promptBlockLibrary_libraryImportDone(
    int blocks,
    int folders,
    int skipped,
  ) {
    return '匯入 $blocks 個塊、$folders 個資料夾，跳過 $skipped 個已存在';
  }

  @override
  String promptBlockLibrary_importFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => '來源檔案';

  @override
  String get promptBlockLibrary_importedAt => '匯入時間';

  @override
  String get promptBlockLibrary_listView => '列表檢視';

  @override
  String get promptBlockLibrary_gridView => '網格檢視';

  @override
  String get promptBlockLibrary_waterfallView => '瀑布流檢視';

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
  String get promptBlockLibrary_sortBy => '排序方式';

  @override
  String get promptBlockLibrary_sortCustom => '預設（手動順序）';

  @override
  String get promptBlockLibrary_sortUpdated => '修改時間';

  @override
  String get promptBlockLibrary_sortTitle => '名稱';

  @override
  String get promptBlockLibrary_sortColor => '顏色';

  @override
  String get promptBlockLibrary_sortIcon => '圖示';

  @override
  String get promptBlockLibrary_sortAscending => '升序';

  @override
  String get promptBlockLibrary_sortDescending => '降序';

  @override
  String get promptBlockLibrary_cardSize => '卡片大小';

  @override
  String get promptBlockLibrary_reorderFolders => '調整資料夾順序';

  @override
  String get nav_styleExplore => '畫風探索';

  @override
  String get styleExplore_rename => '重新命名';

  @override
  String get styleExplore_nameRequired => '名稱不能為空';

  @override
  String get styleExplore_operationFailed => '操作失敗';

  @override
  String get styleExplore_discardChangesTitle => '放棄未儲存的修改？';

  @override
  String get styleExplore_discardChangesMessage => '當前工作區有未儲存的修改，繼續將丟棄這些修改。';

  @override
  String get styleExplore_discardChangesConfirm => '繼續並丟棄';

  @override
  String get styleExplore_newRun => '新增探索';

  @override
  String styleExplore_runDeleted(String name) {
    return '已刪除探索「$name」';
  }

  @override
  String get styleExplore_runStatusGenerating => '生成中';

  @override
  String get styleExplore_runStatusPaused => '已暫停';

  @override
  String get styleExplore_runStatusCancelled => '已取消';

  @override
  String get styleExplore_pauseRun => '暫停';

  @override
  String get styleExplore_cancelRun => '取消探索';

  @override
  String styleExplore_retryFailed(int count) {
    return '重試失敗（$count）';
  }

  @override
  String styleExplore_manualRunName(String time) {
    return '手動候選 $time';
  }

  @override
  String get styleExplore_runBusy => '生成進行中，稍後再試';

  @override
  String get styleExplore_deleteRunTitle => '刪除探索';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return '將刪除「$name」及其候選圖副本；圖庫中的來源圖不受影響。';
  }

  @override
  String get styleExplore_cancelRunTitle => '取消探索';

  @override
  String get styleExplore_cancelRunMessage => '取消後不可再啟動；剩餘待生成候選將標記為已取消。';

  @override
  String get styleExplore_filterAll => '全部';

  @override
  String get styleExplore_filterHearted => '收藏';

  @override
  String get styleExplore_renameFolder => '重新命名分組';

  @override
  String get styleExplore_deleteFolder => '刪除分組';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return '將刪除分組「$name」；其中的候選回到未分組，圖片不會被刪除。';
  }

  @override
  String get styleExplore_folderNameLabel => '分組名稱';

  @override
  String get styleExplore_deleteFamily => '刪除進化線';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return '將刪除進化線「$name」及其全部父本與子代記錄（$count 張）；候選圖片檔案不會刪除。';
  }

  @override
  String get styleExplore_familyBusy => '這條進化線還有生成中的候選，請先停止生成';

  @override
  String get styleExplore_folderUncategorized => '未分組';

  @override
  String styleExplore_folderCreated(String name) {
    return '已建立分組「$name」';
  }

  @override
  String get styleExplore_candidateMissing => '圖片檔案缺失';

  @override
  String get styleExplore_candidateDetailTitle => '候選詳情';

  @override
  String get styleExplore_prevCandidate => '上一張';

  @override
  String get styleExplore_nextCandidate => '下一張';

  @override
  String styleExplore_roundNumber(int number) {
    return '第 $number 輪';
  }

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已存為塊「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所選候選沒有可儲存的畫師串或正向提示詞';

  @override
  String get styleExplore_deleteImage => '刪除圖片';

  @override
  String get styleExplore_deleteImageTitle => '刪除候選圖';

  @override
  String get styleExplore_deleteImageMessage =>
      '將刪除該候選在探索目錄中的圖片副本與候選記錄；圖庫來源圖不受影響。';

  @override
  String get styleExplore_deleteImageDone => '已刪除候選圖與記錄';

  @override
  String get styleExplore_selectCandidates => '多選';

  @override
  String styleExplore_selectedCount(int count) {
    return '已選 $count 張';
  }

  @override
  String get promptBlockEditor_library => '塊庫';

  @override
  String get promptBlockPicker_title => '選擇塊';

  @override
  String get promptBlockLibrary_thumbnail => '預覽圖';

  @override
  String get promptBlockLibrary_selectNewImage => '選擇新圖片';

  @override
  String get promptBlockLibrary_selectImage => '選擇圖片';

  @override
  String get promptBlockLibrary_adjustDisplayRange => '調整顯示範圍';

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
  String styleExplore_deepRoundCountHint(int min) {
    return '張數至少 $min（每個父本保底一張）';
  }

  @override
  String get styleExplore_deepRoundNoInstance => '主提示詞中沒有啟用的隨機遺傳塊，無法生成子代';

  @override
  String get styleExplore_deepRoundEmpty => '無法產生足夠不同的子代畫師組合';

  @override
  String get styleExplore_sortLeft => '左邊更好';

  @override
  String get styleExplore_sortRight => '右邊更好';

  @override
  String get styleExplore_sortNeither => '兩張都不行';

  @override
  String get styleExplore_sortSkip => '跳過';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return '第 $current / 共 $total 對';
  }

  @override
  String get styleExplore_sortDone => '兩兩比較完成';

  @override
  String styleExplore_branchCreated(int count) {
    return '已培育下一代（$count 個父本）';
  }

  @override
  String get styleExplore_branchNeedLatest => '只能從最新代的子代培育下一代';

  @override
  String get styleExplore_branchRoundsIncomplete => '當前代還有未完成的子代，請等待或停止生成';

  @override
  String get styleExplore_branchDuplicate => '所選子代與第一代父本串完全重複';

  @override
  String get styleExplore_branchEmpty => '請至少選擇一張子代候選';

  @override
  String styleExplore_pileManageDeleteDone(int count) {
    return '已刪除 $count 張候選圖與記錄';
  }

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
  String get img2img_directorAddToQueue => '將結果加入輸入佇列';

  @override
  String get img2img_transform => '轉換';

  @override
  String get img2img_palette => '調色盤';

  @override
  String get img2img_paletteOff => '關閉';

  @override
  String get img2img_paletteAuto => '自動';

  @override
  String get img2img_paletteCustom => '自訂';

  @override
  String get img2img_avoidOverRefining => '避免過度細化';

  @override
  String get img2img_keepGridHint => '保留檢測到的像素網格。';

  @override
  String get img2img_refineGridHint => '更細的像素尺寸更合適時，允許細化網格。';

  @override
  String get img2img_pixelUpscaleHint => '使用鄰近像素放大，保持清晰的像素邊緣。';

  @override
  String get img2img_pixelNativeHint => '保留對齊後的原生像素尺寸。';

  @override
  String get img2img_masked => '透明摳圖';

  @override
  String get img2img_generated => '生成結果';

  @override
  String get img2img_blend => '混合結果';

  @override
  String get img2img_emotionHappy => '開心';

  @override
  String get img2img_emotionLaugh => '大笑';

  @override
  String get img2img_emotionSad => '傷心';

  @override
  String get img2img_emotionAngry => '生氣';

  @override
  String get img2img_emotionSurprised => '驚訝';

  @override
  String get img2img_emotionShy => '害羞';

  @override
  String get img2img_emotionExcited => '興奮';

  @override
  String get img2img_emotionDisgusted => '嫌棄';

  @override
  String get img2img_emotionSmug => '得意';

  @override
  String get img2img_emotionWorried => '擔憂';

  @override
  String get img2img_emotionLove => '愛慕';

  @override
  String get img2img_emotionPlayful => '俏皮';

  @override
  String get img2img_emotionTired => '疲憊';

  @override
  String get img2img_emotionNeutral => '平靜';

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
  String get auth_signInAccounts => '登入與帳號';

  @override
  String get auth_notSignedIn => '尚未登入';

  @override
  String get auth_chooseAccountContinue => '選擇帳號，繼續創作';

  @override
  String get auth_manageAccounts2 => '管理帳號';

  @override
  String get auth_subscriptionExpired => '訂閱已到期';

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
  String get promptBlockEditor_translationNeedsReview => '原文已修改，譯文待更新';

  @override
  String get promptBlockEditor_translationReviewHint => '修改原文後請同步校對這裡的譯文';

  @override
  String get modelTask_translateTitle => '原文 → 閱讀語言';

  @override
  String get modelTask_promptReverseTitle => '閱讀語言 → 原文';

  @override
  String get modelTask_tagTranslateTitle => '標籤名稱翻譯';

  @override
  String get modelTask_wikiTranslateTitle => '百科正文翻譯';

  @override
  String get modelTask_translateDescription => '翻譯提示詞與積木，保留權重、分組和標籤語義。';

  @override
  String get modelTask_promptReverseDescription => '結合原文落實譯文中的增刪修改，結果填回原文供確認。';

  @override
  String get modelTask_tagTranslateDescription => '為可見標籤提供簡潔、準確的名稱釋義。';

  @override
  String get modelTask_wikiTranslateDescription => '翻譯百科正文、整理排版，並按語境選擇可點選標籤。';

  @override
  String get modelTask_connectionTest => '模型連線測試';

  @override
  String get modelReasoning_serviceDefault => '服務預設';

  @override
  String get modelReasoning_off => '關閉';

  @override
  String get modelReasoning_on => '開啟';

  @override
  String get modelReasoning_minimal => '極低';

  @override
  String get modelReasoning_low => '低';

  @override
  String get modelReasoning_medium => '中';

  @override
  String get modelReasoning_high => '高';

  @override
  String get modelReasoning_xhigh => '極高';

  @override
  String get modelReasoning_max => '最高';

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
  String get modelParams_anthropicTemperatureRange =>
      'Anthropic 的 Temperature 應在 0–1 之間。';

  @override
  String get modelParams_anthropicSamplingConflict =>
      'Anthropic 的 Temperature 與 Top P 請選擇一項；請檢查模型參數。';

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
      '純翻譯通常無需開啟思考；為兼顧打標、語義分類等處理，建議開啟該模型支援的最低思考檔位。';

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
  String get promptTranslation_guideRestoreTitle => 'A / 恢復';

  @override
  String get promptTranslation_guideRestoreText => '整組還原原文 / 恢復翻譯塊';

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
  String get blockOrganizer_barrierLabel => '塊分類';

  @override
  String get blockOrganizer_replaceTitle => '替換同源塊？';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '目標中已有 $count 個同源副本。替換後來源從塊庫隱藏；已插入提示詞的實例仍可引用原塊。';
  }

  @override
  String blockOrganizer_replaceCopyBody(Object count) {
    return '目標中已有 $count 個同源副本。替換會更新目標副本的內容，來源保留。';
  }

  @override
  String get blockOrganizer_replace => '替換';

  @override
  String get blockOrganizer_customTagColor => '自訂標籤顏色';

  @override
  String get blockOrganizer_colorHint => '#RRGGBB 或 #AARRGGBB';

  @override
  String get blockOrganizer_invalidColor => '請輸入六位或八位十六進位顏色';

  @override
  String blockOrganizer_deleteFolderConfirm(Object name) {
    return '刪除「$name」？其中的塊會移至根目錄。';
  }

  @override
  String blockOrganizer_deleteCollectionConfirm(Object name) {
    return '刪除「$name」？塊本體會保留。';
  }

  @override
  String get blockOrganizer_titleFavorites => '收藏與收藏集';

  @override
  String get blockOrganizer_titleFolders => '選擇資料夾';

  @override
  String blockOrganizer_itemCount(Object count) {
    return '$count 項';
  }

  @override
  String get blockOrganizer_search => '搜尋';

  @override
  String get blockOrganizer_name => '名稱';

  @override
  String get blockOrganizer_customColor => '自訂顏色…';

  @override
  String get blockOrganizer_newCollection => '新增收藏集';

  @override
  String get blockOrganizer_newCollectionFolder => '新增收藏資料夾';

  @override
  String get blockOrganizer_newTag => '新標籤';

  @override
  String get blockOrganizer_newFolder => '新增資料夾';

  @override
  String get blockOrganizer_rootUncategorized => '根目錄 / 未分類';

  @override
  String get blockOrganizer_manageDrag => '管理；拖動排序';

  @override
  String get blockLibrary_dragSelectedHint => '拖動已選塊到左側的收藏或資料夾，鬆開後選擇複製或移動。';

  @override
  String blockLibrary_blockCount(Object count) {
    return '$count 個塊';
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
  String get promptBlockEditor_appearance => '塊外觀';

  @override
  String get promptBlockEditor_imageUnreadable => '無法讀取所選影像';

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
  String get opusUsage_exhausted => '帳號免費額度已用盡，V5 生成按 Anlas 計費';

  @override
  String opusUsage_remaining(Object percent) {
    return '帳號免費額度剩餘 $percent%';
  }

  @override
  String opusUsage_recharging(Object time) {
    return '回充中：下一 +1% 還需 $time';
  }

  @override
  String get opusUsage_notRecharging => '當前不回充（池子在回充閾值之上或已用盡）';

  @override
  String get opusUsage_clickToRefresh => '點選重新整理';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 小時 $minutes 分';
  }

  @override
  String opusUsage_hours(Object hours) {
    return '$hours 小時';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String opusUsage_minutes(Object minutes) {
    return '$minutes 分';
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
  String vibeImport_imageProgress(Object current, Object total, Object source) {
    return '匯入圖片($current/$total): $source';
  }

  @override
  String get vibeImport_clipboardSource => '剪貼簿';

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
  String get img2img_directorEmotionHint => '僅適用於動漫影像，請從表情中性的影像開始。';

  @override
  String get img2img_emotionStrengthNormal => '正常';

  @override
  String get img2img_emotionStrengthSlightlyWeak => '稍弱';

  @override
  String get img2img_emotionStrengthWeak => '弱';

  @override
  String get img2img_emotionStrengthWeaker => '更弱';

  @override
  String get img2img_emotionStrengthVeryWeak => '很弱';

  @override
  String get img2img_emotionStrengthWeakest => '最弱';

  @override
  String get img2img_directorWeaken => '減弱表情';

  @override
  String get img2img_directorStrengthen => '增強表情';

  @override
  String get img2img_emotionScared => '害怕';

  @override
  String get img2img_emotionNervous => '緊張';

  @override
  String get img2img_emotionThinking => '思考';

  @override
  String get img2img_emotionConfused => '困惑';

  @override
  String get img2img_emotionBored => '無聊';

  @override
  String get img2img_emotionIrritated => '惱火';

  @override
  String get img2img_emotionAroused => '情慾';

  @override
  String get img2img_emotionEmbarrassed => '尷尬';

  @override
  String get img2img_emotionDetermined => '堅定';

  @override
  String get img2img_emotionHurt => '受傷';

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
  String get generation_moduleImage => '影像';

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
  String generation_historyBatchCount(int count) {
    return '$count 張';
  }

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
  String get library_addToGeneration => '加入生圖';

  @override
  String get library_strength => '強度';

  @override
  String get library_information => '資訊';

  @override
  String get library_fidelity => '保真';

  @override
  String get library_encodeOnUse => '用時編碼';

  @override
  String get library_reencode => '需重新編碼';

  @override
  String library_unusableModel(String model) {
    return '不能用於 $model';
  }

  @override
  String get library_exportAll => '匯出全部';

  @override
  String get library_rescanFolders => '重新掃描資料夾';

  @override
  String get library_preview => '預覽';

  @override
  String get viewer_backLocalGallery => '本機圖庫';

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
  String get styleExplore_runNamingHint => '自動命名：隨機塊名 + 日期，雙擊名稱即可改名';

  @override
  String styleExplore_roundGenerating(int round) {
    return '第 $round 輪 · 生成中';
  }

  @override
  String get styleExplore_inspectorTitle => '詳情';

  @override
  String styleExplore_failedBadge(int count) {
    return '失敗 $count';
  }

  @override
  String get styleExplore_showInspector => '展開檢查器';

  @override
  String styleExplore_roundProgress(int round, int current, int total) {
    return '第 $round 輪 · $current / $total';
  }

  @override
  String get styleExplore_earlier => '更早';

  @override
  String get styleExplore_noMatchingRuns => '沒有匹配的探索';

  @override
  String styleExplore_lineCount(int count) {
    return '$count 條進化線';
  }

  @override
  String get styleExplore_newRunDescription => '用當前提示詞和參數開一個新的，名字可以之後改';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_largeCandidates => '大候選圖';

  @override
  String get styleExplore_hideInspector => '收起檢查器';

  @override
  String get styleExplore_searchRuns => '搜尋探索名稱或畫師';

  @override
  String styleExplore_favoriteCount(int count) {
    return '收藏 $count';
  }

  @override
  String styleExplore_generatingBadge(int current, int total) {
    return '生成中 $current/$total';
  }

  @override
  String styleExplore_roundCount(int count) {
    return '$count 輪';
  }

  @override
  String styleExplore_pausedRemaining(int count) {
    return '已暫停 · 剩 $count 張';
  }

  @override
  String get styleExplore_stopRun => '停止生成';

  @override
  String get styleExplore_thisWeek => '本週';

  @override
  String get styleExplore_today => '今天';

  @override
  String get styleExplore_smallCandidates => '小候選圖';

  @override
  String styleExplore_imageCount(int count) {
    return '$count 張';
  }

  @override
  String get styleExplore_variablesTitle => '隨機變數';

  @override
  String get styleExplore_variablesHint => '每張重新抽取';

  @override
  String get styleExplore_variablesExplanation => '每張候選會記錄啟用的隨機或順序遺傳塊抽到了哪些內容。';

  @override
  String styleExplore_variablePoolSize(int count) {
    return '池 $count 項';
  }

  @override
  String get styleExplore_variableEvolutionTarget => '進化目標';

  @override
  String get styleExplore_variableNegative => '負面';

  @override
  String get styleExplore_variablesEmpty => '提示詞裡還沒有隨機塊，抽出來的圖會很像';

  @override
  String get styleExplore_openBlockLibrary => '開啟塊庫';

  @override
  String get styleExplore_drawCountLabel => '本次抽取';

  @override
  String get styleExplore_drawCountSuffix => '張 · 逐張生成';

  @override
  String get styleExplore_candidatesTab => '候選';

  @override
  String get styleExplore_evolutionTab => '進化';

  @override
  String styleExplore_deepRoundTitle(String name, int generation) {
    return '進化 · $name 第 $generation 代';
  }

  @override
  String styleExplore_wallRoundCount(int count) {
    return '$count 張';
  }

  @override
  String get styleExplore_wallGenerating => '正在生成';

  @override
  String styleExplore_roundFailures(int count) {
    return '失敗 $count';
  }

  @override
  String styleExplore_queued(int number) {
    return '排隊 #$number';
  }

  @override
  String styleExplore_generatingCandidate(int number) {
    return '生成中 #$number';
  }

  @override
  String get styleExplore_generationFailed => '生成失敗';

  @override
  String get styleExplore_failureHint => '懸停檢視原因';

  @override
  String get styleExplore_imageDeleted => '圖片已刪除';

  @override
  String get styleExplore_parentBadge => '父本';

  @override
  String get styleExplore_opMutation => '變異';

  @override
  String get styleExplore_opCrossover => '交叉';

  @override
  String get styleExplore_opInjection => '注入';

  @override
  String get styleExplore_copyArtists => '複製畫師串';

  @override
  String get styleExplore_interrupted => '已中斷';

  @override
  String get styleExplore_emptyFilter => '沒有符合篩選的候選';

  @override
  String get styleExplore_emptyRound => '本輪還沒有候選';

  @override
  String get styleExplore_unfavorite => '取消收藏';

  @override
  String get styleExplore_groupLabel => '分組';

  @override
  String get styleExplore_newGroup => '新增分組…';

  @override
  String get styleExplore_saveBlock => '存為塊';

  @override
  String get styleExplore_startEvolution => '開始進化';

  @override
  String get styleExplore_newestFirst => '最新輪在前';

  @override
  String get styleExplore_oldestFirst => '最早輪在前';

  @override
  String get styleExplore_pickEvolution => '挑幾張去進化';

  @override
  String get styleExplore_deleteCandidatesTitle => '刪除候選';

  @override
  String styleExplore_deleteCandidatesMessage(int count) {
    return '將刪除 $count 張候選及其圖片副本，圖庫來源圖保留。';
  }

  @override
  String get styleExplore_inspectorEmpty => '選一張候選檢視詳情';

  @override
  String get styleExplore_drawsTitle => '本張抽到';

  @override
  String get styleExplore_drawsAfterGeneration => '生成完成後顯示';

  @override
  String get styleExplore_emptyDraw => '這次沒有抽中（池裡有空項）';

  @override
  String get styleExplore_hearted => '已收藏';

  @override
  String get styleExplore_joinEvolution => '加入進化';

  @override
  String get styleExplore_applyToEditor => '套用到編輯區';

  @override
  String get styleExplore_seedName => '種子';

  @override
  String get styleExplore_elapsedName => '耗時';

  @override
  String get styleExplore_parameters => '參數';

  @override
  String get styleExplore_modelName => '模型';

  @override
  String get styleExplore_fullPrompt => '完整提示詞';

  @override
  String get styleExplore_mergedArtists => '合在一起的畫師（去重）';

  @override
  String get styleExplore_selectionExplanation =>
      '存為塊會把這些合成一個塊；開始進化會把每張圖的畫師串作為一個父本。';

  @override
  String get styleExplore_quickGroupHint => '按 1–9 快速歸組';

  @override
  String get styleExplore_newGroupChip => '新分組';

  @override
  String styleExplore_parameterSummary(
    int width,
    int height,
    int steps,
    String scale,
  ) {
    return '$width×$height · $steps 步 · $scale';
  }

  @override
  String get styleExplore_viewerBack => '畫風探索';

  @override
  String styleExplore_viewerPosition(int index, int total) {
    return '第 $index 張 / 共 $total 張';
  }

  @override
  String get styleExplore_viewerGroupsShortcut => '按 1–9 歸組，0 移回未分組';

  @override
  String get styleExplore_seedClickCopy => '種子（點選複製）';

  @override
  String get styleExplore_appliedToEditor => '已套用到編輯區';

  @override
  String styleExplore_generationNumber(int index) {
    return '第 $index 代';
  }

  @override
  String get styleExplore_currentGeneration => '當前';

  @override
  String styleExplore_generationStart(int count) {
    return '從候選裡選了 $count 張作為起點';
  }

  @override
  String styleExplore_generationSource(int index, int count, int roots) {
    return '由第 $index 代挑 $count 張 + 第 1 代回交 $roots 張';
  }

  @override
  String get styleExplore_parentsByPreference => '父本 · 按偏好排序';

  @override
  String get styleExplore_backcross => '回交';

  @override
  String styleExplore_childrenCount(int count) {
    return '子代 · $count';
  }

  @override
  String styleExplore_breedSelected(int count, int index) {
    return '用選中的 $count 張培育第 $index 代';
  }

  @override
  String get styleExplore_generationBusy => '這一代還在生成';

  @override
  String get styleExplore_regeneratePrefix => '再生成';

  @override
  String get styleExplore_regenerateSuffix => '張子代';

  @override
  String get styleExplore_pairCompare => '兩兩比較排序';

  @override
  String get styleExplore_howToUse => '怎麼用';

  @override
  String get styleExplore_helpParents => '父本是你選中的畫師組合，偏好越高，越容易參與組合。';

  @override
  String get styleExplore_helpChildren => '子代由父本交叉、變異或從畫師池注入新畫師產生。';

  @override
  String get styleExplore_helpCompare => '兩兩比較會更新父本偏好，影響後續子代組合。';

  @override
  String get styleExplore_helpBackcross => '培育下一代時，會自動帶上第 1 代父本做回交。';

  @override
  String get styleExplore_originTitle => '怎麼來的';

  @override
  String get styleExplore_originCross => '由這幾張父本的畫師交叉組合';

  @override
  String get styleExplore_originMutation => '在父本基礎上替換了部分畫師';

  @override
  String get styleExplore_originInjection => '從池裡注入了新畫師';

  @override
  String get styleExplore_newArtist => '新';

  @override
  String get styleExplore_evolutionEmpty => '從候選裡挑幾張喜歡的，開始一條進化線';

  @override
  String get styleExplore_pickFromCandidates => '去候選裡挑';

  @override
  String styleExplore_generationSummary(
    int parents,
    int children,
    int selected,
  ) {
    return '$parents 個父本 → $children 張子代 · 選了 $selected 張';
  }

  @override
  String get styleExplore_breedNext => '培育下一代';

  @override
  String get styleExplore_optionalName => '名稱（可不填）';

  @override
  String get styleExplore_childrenEmpty => '還沒有子代，在上面生成一批';

  @override
  String get styleExplore_evolutionStepOne => '父本的畫師串互相變異、交叉';

  @override
  String get styleExplore_evolutionStepTwo => '可以兩兩比較幫你排序';

  @override
  String get styleExplore_evolutionStepThree => '選中的子代成為新父本';

  @override
  String get styleExplore_evolutionNewLine => '新增進化線';

  @override
  String styleExplore_evolutionJoinLine(String name) {
    return '加入「$name」當前代';
  }

  @override
  String get styleExplore_evolutionName => '進化線名稱';

  @override
  String styleExplore_defaultEvolutionName(int n) {
    return '進化線 $n';
  }

  @override
  String get styleExplore_evolutionAddCustom => '再加一段自訂畫師串';

  @override
  String get styleExplore_evolutionCustomHint => '輸入畫師串';

  @override
  String get styleExplore_evolutionParentEmpty => '沒有可用的畫師串';

  @override
  String get styleExplore_evolutionTarget => '子代會替換提示詞裡';

  @override
  String get styleExplore_evolutionOnlyCreate => '只建立';

  @override
  String get styleExplore_evolutionOnlyJoin => '只加入';

  @override
  String styleExplore_evolutionCreateGenerate(int count) {
    return '建立並生成 $count 張';
  }

  @override
  String styleExplore_evolutionJoinGenerate(int count) {
    return '加入並生成 $count 張';
  }

  @override
  String get styleExplore_evolutionFirstBatch => '第一批子代';

  @override
  String styleExplore_evolutionMinimum(int count) {
    return '張（至少 $count）';
  }

  @override
  String styleExplore_evolutionCreated(String name) {
    return '已建立進化線「$name」';
  }

  @override
  String styleExplore_evolutionJoined(String name) {
    return '已加入進化線「$name」';
  }

  @override
  String get styleExplore_sortLiveSave => '結果即時儲存，可以隨時關閉';

  @override
  String get styleExplore_sortRanking => '當前排名 · 即時';

  @override
  String get styleExplore_sortRankingHint => '排名會影響下一批子代裡各父本被選中的機率';

  @override
  String get styleExplore_sortSpace => '空格';

  @override
  String styleExplore_saveSingleSubtitle(int n) {
    return '#$n 的畫師存成一個塊';
  }

  @override
  String styleExplore_saveManySubtitle(int count) {
    return '來自 $count 張候選，已合併去重';
  }

  @override
  String get styleExplore_saveArtistsOnly => '只要抽到的畫師';

  @override
  String get styleExplore_saveFullPositive => '完整正向提示詞';

  @override
  String get styleExplore_saveNoDraws => '這些候選沒有正向遺傳實例記錄，請儲存完整正向提示詞';

  @override
  String get styleExplore_saveContent => '內容';

  @override
  String get styleExplore_saveRemoveAtoms => '點 × 去掉不要的畫師';

  @override
  String styleExplore_saveRemoved(int count) {
    return '已去掉 $count 個';
  }

  @override
  String get styleExplore_saveRestore => '恢復';

  @override
  String get styleExplore_saveName => '名稱';

  @override
  String get styleExplore_saveColor => '顏色';

  @override
  String get styleExplore_saveIcon => '圖示';

  @override
  String get styleExplore_saveFolder => '放到塊庫';

  @override
  String get styleExplore_saveRoot => '根目錄';

  @override
  String get styleExplore_saveHint => '存好後可以在塊庫裡拖進提示詞';

  @override
  String get styleExplore_onboardingTitle => '用隨機塊批次試畫風';

  @override
  String get styleExplore_onboardingRandomTitle => '放入隨機塊';

  @override
  String get styleExplore_onboardingDrawTitle => '抽一批候選';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '抽 $count 張候選';
  }

  @override
  String get styleExplore_onboardingReviewTitle => '收藏、比較、進化';

  @override
  String get styleExplore_onboardingOpenPrevious => '開啟以前的探索';

  @override
  String get styleExplore_onboardingSubtitle => '每張圖都會從隨機塊裡重新抽畫師，你只管挑喜歡的';

  @override
  String get styleExplore_onboardingRandomDescription =>
      '在提示詞裡插入畫師池，例如 400 精選畫師池。左邊會列出檢測到的隨機變數。';

  @override
  String styleExplore_onboardingDrawDescription(int count) {
    return '點左下角“抽 $count 張候選”。每張圖下方會寫出它抽到了哪些畫師。';
  }

  @override
  String get styleExplore_onboardingReviewDescription =>
      '喜歡的按 F 收藏；挑幾張開始進化，讓好的畫師組合繼續雜交出新組合。';

  @override
  String styleExplore_onboardingDetected(int count) {
    return '已檢測到 $count 個';
  }

  @override
  String get styleExplore_compareTitle => '兩兩比較 · 給父本排個序';

  @override
  String get styleExplore_compareQuestion => '哪張更接近你想要的畫風？';

  @override
  String styleExplore_childLabel(int index) {
    return '子代 #$index';
  }

  @override
  String styleExplore_generationCounts(int parents, int children) {
    return '$parents 個父本 → $children 張子代';
  }

  @override
  String get styleExplore_viewLarge => '看大圖';

  @override
  String get styleExplore_saveDialogTitle => '存為提示詞塊';

  @override
  String styleExplore_startDialogTitle(int count) {
    return '用 $count 張候選開始進化';
  }

  @override
  String get styleExplore_stepGenerate => '生成子代';

  @override
  String get styleExplore_stepPick => '挑出好的';

  @override
  String get styleExplore_stepBreed => '培育下一代';

  @override
  String styleExplore_firstGenerationParents(int count) {
    return '第 1 代父本 · $count';
  }

  @override
  String get styleExplore_evolutionTargetAfter => '的位置，其他內容不變';

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
  String get online_jumpToPage => '跳到頁…';

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
}
