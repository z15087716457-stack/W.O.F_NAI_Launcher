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
  String get common_folder => '文件夹';

  @override
  String get common_filter => '筛选';

  @override
  String get common_grid => '网格';

  @override
  String get common_date => '日期';

  @override
  String get common_pack => '打包';

  @override
  String get common_multiSelect => '多选';

  @override
  String get common_category => '分类';

  @override
  String get common_categories => '分类';

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
  String get auth_loggedIn => '已登录';

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
  String get auth_savedAccounts => '已保存的账号';

  @override
  String get auth_addAccount => '添加账号';

  @override
  String get auth_manageAccounts => '管理';

  @override
  String auth_moreAccounts(Object count) {
    return '还有 $count 个账号';
  }

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
  String get settings_editNickname => '编辑昵称';

  @override
  String get settings_nickname => '昵称';

  @override
  String get settings_nicknameHint => '输入2-32个字符';

  @override
  String get settings_nicknameEmpty => '请输入昵称';

  @override
  String settings_nicknameTooLong(int maxLength) {
    return '昵称不能超过$maxLength个字符';
  }

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
  String get generation_canvasSendToTools => '发送到图像工具';

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
  String get generation_guidance => 'PG';

  @override
  String generation_cfgScale(Object scale) {
    return 'PG：$scale';
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
    return 'PGR：$value';
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
  String get generation_sectionImageSettings => '图像设置';

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
  String get img2img_generateVariations => '生成变体';

  @override
  String get img2img_directorTools => '导演工具';

  @override
  String get img2img_directorPrompt => '附加提示词';

  @override
  String get img2img_directorPromptHint => '需要时补充描述，例如目标情绪或上色方向';

  @override
  String get img2img_directorRunning => '正在处理...';

  @override
  String get img2img_directorResult => '处理结果';

  @override
  String get img2img_directorApplied => '已将导演工具结果设为新的源图';

  @override
  String get img2img_directorDefry => 'Defry';

  @override
  String get img2img_directorEmotionLevel => '表情强度';

  @override
  String get img2img_directorApplyAsSource => '设为源图';

  @override
  String get img2img_directorSourceImage => '源图';

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
  String get img2img_novelAiCloudUpscale => 'NovelAI 云端超分 (固定 4x 放大)';

  @override
  String get img2img_comfyuiEnableHint => '请先在「设置 > ComfyUI」中启用并连接服务器。';

  @override
  String get img2img_upscaleMode => '放大方式';

  @override
  String get img2img_upscaleRegularModel => '普通模型';

  @override
  String get img2img_upscaleModel => '超分模型';

  @override
  String get img2img_noSeedvr2Models =>
      '未发现 SeedVR2 模型，请刷新模型列表或检查 SeedVR2 节点/模型文件。';

  @override
  String get img2img_noRegularUpscaleModels =>
      '未发现普通超分模型，请刷新模型列表或检查 models/upscale_models。';

  @override
  String get img2img_useSeedvr2TiledWorkflow =>
      '将使用 SeedVR2TilingUpscaler 分块超分流程。';

  @override
  String get img2img_useSeedvr2Workflow => '将使用 SeedVR2VideoUpscaler 流程。';

  @override
  String get img2img_useRegularUpscaleWorkflow =>
      '将使用 UpscaleModelLoader + ImageUpscaleWithModel 流程，并用 Lanczos 修正到目标倍率。';

  @override
  String get img2img_useRtxUpscaleWorkflow =>
      '将使用 RTX Video Super Resolution 流程，无需选择模型。';

  @override
  String get img2img_refreshModelList => '刷新模型列表';

  @override
  String get img2img_startUpscale => '开始超分';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 超分完成';

  @override
  String img2img_upscaleComplete(Object width, Object height) {
    return '超分完成 (${width}x$height)';
  }

  @override
  String img2img_regularUpscaleComplete(Object width, Object height) {
    return '普通模型超分完成 (${width}x$height)';
  }

  @override
  String img2img_rtxUpscaleComplete(Object width, Object height) {
    return 'RTX 超分完成 (${width}x$height)';
  }

  @override
  String get img2img_noAvailableSeedvr2Model => '未选择可用的 SeedVR2 模型';

  @override
  String get img2img_noAvailableRegularUpscaleModel => '未选择可用的普通超分模型';

  @override
  String get img2img_decodeSourceFailed => '无法解码源图像';

  @override
  String get img2img_metricSpeed => '速度';

  @override
  String get img2img_metricVram => '显存';

  @override
  String get img2img_metricQuality => '效果';

  @override
  String get img2img_seedvr2VaeTileHint =>
      '同时写入 SeedVR2 VAE MODEL 的 encode/decode tile size。';

  @override
  String get img2img_seedvr2UseTiledUpscale => '使用分块放大';

  @override
  String get img2img_seedvr2UseTiledUpscaleHint =>
      '启用后改用 SeedVR2TilingUpscaler，适合大图或显存压力较高的场景。';

  @override
  String get img2img_seedvr2TileSize => '分块图块大小';

  @override
  String get img2img_seedvr2TileSizeHint =>
      '同时控制 SeedVR2TilingUpscaler 的 tile_width / tile_height。';

  @override
  String get img2img_seedvr2BlocksToSwap => '内存卸载层数';

  @override
  String get img2img_seedvr2BlocksToSwapHint =>
      '把多少 DiT 层放在内存里、推理时再逐层送入显存。调高更省显存但更吃内存也更慢；显存充裕可调低甚至设为 0。显存不足报错时请调高。';

  @override
  String get img2img_upscalePanelOpened => '已打开图生图超分面板';

  @override
  String get editor_done => '完成';

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
  String get editor_resetView => '重置视图';

  @override
  String get editor_zoom => '缩放';

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
  String get editor_shortcutUndo => '撤销 (Ctrl+Z)';

  @override
  String get editor_shortcutRedo => '重做 (Ctrl+Y)';

  @override
  String get editor_back => '返回';

  @override
  String get editor_layers => '图层';

  @override
  String get editor_loadMask => '加载蒙版';

  @override
  String get editor_togglePanels => '切换面板';

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
  String get editor_tempColorPickerShortcut => 'Alt+点击: 临时取色';

  @override
  String get editor_shortcutHelpTitle => '快捷键帮助';

  @override
  String get editor_shortcutPaintTools => '绘画工具';

  @override
  String get editor_shortcutSelectionTools => '选区工具';

  @override
  String get editor_shortcutCanvasView => '画布视图';

  @override
  String get editor_shortcutBrushAdjust => '笔刷调整';

  @override
  String get editor_shortcutColors => '颜色';

  @override
  String get editor_shortcutCanvasActions => '画布操作';

  @override
  String get editor_shortcutHistoryActions => '历史操作';

  @override
  String get editor_shortcutSelectionActions => '选区操作';

  @override
  String get editor_shortcutTemporaryColorPicker => '临时拾色器';

  @override
  String get editor_shortcutRectSelection => '矩形选区';

  @override
  String get editor_shortcutEllipseSelection => '椭圆选区';

  @override
  String get editor_shortcutLassoSelection => '套索选区';

  @override
  String get editor_shortcut100Zoom => '100% 缩放';

  @override
  String get editor_shortcutFitHeight => '适应高度';

  @override
  String get editor_shortcutFitWidth => '适应宽度';

  @override
  String get editor_shortcutRotateLeft15 => '向左旋转 15°';

  @override
  String get editor_shortcutResetRotation => '重置旋转';

  @override
  String get editor_shortcutRotateRight15 => '向右旋转 15°';

  @override
  String get editor_shortcutFlipHorizontal => '水平镜像';

  @override
  String get editor_shortcutWheel => '滚轮';

  @override
  String get editor_shortcutBrushSmaller => '减小笔刷';

  @override
  String get editor_shortcutBrushLarger => '增大笔刷';

  @override
  String get editor_shortcutOpacityLower => '降低透明度';

  @override
  String get editor_shortcutOpacityHigher => '提高透明度';

  @override
  String get editor_shortcutDragBrushSize => '调整笔刷大小';

  @override
  String get editor_shortcutSwapColors => '交换前景/背景色';

  @override
  String get editor_shortcutPanCanvas => '平移画布';

  @override
  String get editor_shortcutClearSelectionContent => '清除选区内容';

  @override
  String get editor_shortcutCancelCurrentAction => '取消当前操作';

  @override
  String get editor_selectUnlockedLayerWithContent => '请选择一个非锁定且有内容的图层';

  @override
  String get editor_readCurrentLayerFailed => '无法读取当前图层';

  @override
  String get editor_localEffects => '本地后处理 / Effects';

  @override
  String get editor_basicAdjustments => '基础调整';

  @override
  String get editor_styleAndRepair => '风格与修复';

  @override
  String get editor_transformCrop => '旋转 / 翻转 / 裁剪';

  @override
  String get editor_transformCropDescription =>
      '几何操作已经独立出来，点击后会先生成预览，确认应用后才写回图层。';

  @override
  String get editor_effectPreviewHint => '预览不会修改原图；点击应用后才会把结果写入当前活动图层和撤销历史。';

  @override
  String get editor_applyToCurrentLayer => '应用到当前图层';

  @override
  String editor_oneShotEffectHint(Object effect) {
    return '$effect 是一次性操作，没有强度滑条。';
  }

  @override
  String editor_effectIntensity(Object effect) {
    return '$effect 强度';
  }

  @override
  String get editor_original => '原图';

  @override
  String get editor_effectPreview => '效果预览';

  @override
  String get editor_effectBrightness => '亮度';

  @override
  String get editor_effectContrast => '对比度';

  @override
  String get editor_effectSaturation => '饱和度';

  @override
  String get editor_effectTemperature => '色温';

  @override
  String get editor_effectGamma => '伽马';

  @override
  String get editor_effectGrayscale => '灰度';

  @override
  String get editor_effectInvert => '反相';

  @override
  String get editor_effectSepia => '复古棕褐';

  @override
  String get editor_effectDenoise => '降噪';

  @override
  String get editor_effectBlur => '高斯模糊';

  @override
  String get editor_effectSharpen => '锐化';

  @override
  String get editor_effectCropToSelection => '裁剪到选区';

  @override
  String get editor_effectRotateLeft => '向左旋转 90°';

  @override
  String get editor_effectRotateRight => '向右旋转 90°';

  @override
  String get editor_effectFlipHorizontal => '水平翻转';

  @override
  String get editor_effectFlipVertical => '垂直翻转';

  @override
  String editor_effectApplied(Object effect) {
    return '已应用 $effect';
  }

  @override
  String editor_applyEffectFailed(Object error) {
    return '应用效果失败: $error';
  }

  @override
  String get editor_changeCanvasSize => '更改画布尺寸';

  @override
  String editor_canvasTooSmall(Object width, Object height) {
    return '画布尺寸太小，最小尺寸为 $width x $height 像素';
  }

  @override
  String editor_canvasTooLarge(Object width, Object height) {
    return '画布尺寸太大，最大尺寸为 $width x $height 像素';
  }

  @override
  String editor_canvasResized(Object width, Object height) {
    return '画布已调整为 $width x $height';
  }

  @override
  String editor_canvasResizeFailed(Object error) {
    return '调整画布尺寸失败: $error';
  }

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
  String get editor_clickInsideClosedRegion => '请点击封闭区域内部进行填充。';

  @override
  String get editor_drawClosedMaskOutlineFirst => '请先绘制封闭的蒙版轮廓。';

  @override
  String get editor_noClosedRegionAtPosition => '该位置没有可填充的封闭区域。';

  @override
  String get editor_generateMaskOverlayFailed => '无法生成蒙版覆盖层';

  @override
  String get editor_maskLayerName => '蒙版';

  @override
  String get editor_updateMaskLayerFailed => '无法更新蒙版图层';

  @override
  String get editor_closedRegionFilled => '封闭区域已填充为蒙版。';

  @override
  String editor_fillMaskFailed(Object error) {
    return '填充蒙版失败: $error';
  }

  @override
  String get editor_magicWandNoSource => '没有可供魔棒取样的图像图层。';

  @override
  String get editor_magicWandNothingChanged => '选中的区域已经透明或已在蒙版中。';

  @override
  String get editor_magicWandModelPreparing => '正在检查 EfficientViT-SAM 模型…';

  @override
  String editor_magicWandModelDownloading(int percent) {
    return '正在下载 EfficientViT-SAM 模型：$percent%';
  }

  @override
  String get editor_magicWandModelLoading => '正在加载 EfficientViT-SAM 模型…';

  @override
  String get editor_magicWandEncoding => '正在分析图像对象…';

  @override
  String get editor_magicWandSegmenting => '正在根据点击位置分割对象…';

  @override
  String get editor_magicWandPostprocessing => '正在生成选区…';

  @override
  String editor_magicWandFailed(Object error) {
    return '魔棒处理失败: $error';
  }

  @override
  String get editor_compressionTitle => '输出分辨率';

  @override
  String get editor_compressionTooltip => '选择输出分辨率';

  @override
  String get editor_compressionUncompressed => '保持编辑工作尺寸，不执行压缩。';

  @override
  String get editor_compressionApplyOnDone =>
      '工作画布保持原样；点击“完成”时使用 Pica Lanczos3 执行一次压缩。';

  @override
  String editor_compressionSizeSummary(
    int workWidth,
    int workHeight,
    int targetWidth,
    int targetHeight,
  ) {
    return '工作尺寸 $workWidth×$workHeight → 输出尺寸 $targetWidth×$targetHeight';
  }

  @override
  String editor_compressionNormalSummary(
    int normalWidth,
    int normalHeight,
    int minimumWidth,
    int minimumHeight,
  ) {
    return 'Normal（约 1MP）为 $normalWidth×$normalHeight；最低档为 $minimumWidth×$minimumHeight。';
  }

  @override
  String get editor_compressionUnavailable => '当前工作画布已经低于最低压缩档，不能继续降低分辨率。';

  @override
  String editor_unsupportedImageFormat(Object extension) {
    return '不支持的文件格式: .$extension\n请选择图像文件（PNG、JPG、WEBP 等）';
  }

  @override
  String editor_readFileFailed(Object error) {
    return '无法读取文件: $error';
  }

  @override
  String get editor_noFileData => '无法获取文件数据';

  @override
  String get editor_emptyImageFile => '文件为空，请选择有效的图像文件';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return '文件过大（$sizeMB MB），请选择小于 50MB 的图像';
  }

  @override
  String get editor_maskLayerAdded => '蒙版图层已添加';

  @override
  String get editor_parseImageFailed => '无法解析图像文件\n请确保文件未损坏且格式受支持';

  @override
  String editor_loadMaskFailed(Object error) {
    return '加载蒙版时发生错误: $error';
  }

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
  String get editor_colorPickerHint => '点击画布任意位置取色，松开后自动切回上一工具';

  @override
  String get editor_sample => '取样';

  @override
  String get editor_samplePoint => '单点';

  @override
  String get editor_sampleArea => '区域';

  @override
  String get editor_source => '来源';

  @override
  String get editor_sourceCurrentLayer => '当前图层';

  @override
  String get editor_sourceAllLayers => '所有图层';

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
  String get gallery_metaCfgScale => 'PG';

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
  String get tooltip_edit => '编辑';

  @override
  String get tooltip_copy => '复制';

  @override
  String get tooltip_delete => '删除';

  @override
  String get tooltip_enable => '启用';

  @override
  String get tooltip_disable => '禁用';

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
  String get weight_title => '权重';

  @override
  String get weight_reset => '重置';

  @override
  String get weight_done => '完成';

  @override
  String get weight_noBrackets => '无括号';

  @override
  String get weight_editTag => '编辑标签';

  @override
  String get weight_tagName => '标签名称';

  @override
  String get weight_tagNameHint => '输入标签名称...';

  @override
  String tag_selected(Object count) {
    return '已选 $count';
  }

  @override
  String get tag_enable => '启用';

  @override
  String get tag_disable => '禁用';

  @override
  String get tag_delete => '删除';

  @override
  String get tag_addTag => '添加标签';

  @override
  String get tag_add => '添加';

  @override
  String get tag_inputHint => '输入标签...';

  @override
  String get tag_copiedToClipboard => '已复制到剪贴板';

  @override
  String get tag_emptyHint => '添加标签来描述你想要的画面';

  @override
  String get tag_emptyHintSub => '你可以浏览、搜索或手动添加标签';

  @override
  String get tagCategory_artist => '艺术家';

  @override
  String get tagCategory_copyright => '版权';

  @override
  String get tagCategory_character => '角色';

  @override
  String get tagCategory_meta => '元数据';

  @override
  String get tagCategory_general => '通用';

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
  String get characterEditor_promptHint => '输入角色的正向提示词...';

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
  String get toolbar_clear => '清空';

  @override
  String get toolbar_confirmClear => '确认清空';

  @override
  String get toolbar_settings => '设置';

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
  String download_completed(Object name) {
    return '$name下载完成';
  }

  @override
  String download_failed(Object name) {
    return '$name下载失败';
  }

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
  String get download_tags_data => '正在下载标签数据...';

  @override
  String get download_cooccurrence_data => '正在下载共现标签数据...';

  @override
  String get download_parsing_data => '正在解析数据...';

  @override
  String get download_readingFile => '正在读取文件...';

  @override
  String get download_mergingData => '正在合并数据...';

  @override
  String get download_loadComplete => '加载完成';

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
  String get category_selectEmoji => '选择 Emoji';

  @override
  String get category_noRecentEmoji => '暂无最近使用的 Emoji';

  @override
  String get category_searchEmoji => '搜索 Emoji';

  @override
  String get vibeNoEncodingWarning => '此图片没有预编码数据';

  @override
  String vibeWillCostAnlas(int count) {
    return '编码将消耗 $count Anlas';
  }

  @override
  String get vibeEncodeConfirm => '是否继续添加并消耗点数？';

  @override
  String get vibeCancel => '取消';

  @override
  String get vibeConfirmEncode => '确认编码';

  @override
  String get vibeParseFailed => '无法解析 Vibe 文件';

  @override
  String get tagGroupBrowser_searchHint => '搜索标签...';

  @override
  String tagGroupBrowser_tagCount(Object count) {
    return '$count个标签';
  }

  @override
  String tagGroupBrowser_filteredTagCount(Object filtered, Object total) {
    return '显示 $filtered 个，共 $total 个标签';
  }

  @override
  String get tagGroupBrowser_noTags => '暂无标签';

  @override
  String get tagGroupBrowser_noLibrary => '词库未加载';

  @override
  String get tagGroupBrowser_importLibraryHint => '请先导入标签词库';

  @override
  String get tagGroupBrowser_noCategories => '没有启用的标签分类';

  @override
  String get tagGroupBrowser_enableCategoriesHint => '请在设置中启用标签分类';

  @override
  String get tagGroupBrowser_danbooruSuggestions => 'Danbooru 建议';

  @override
  String get tag_favoritesTitle => '收藏标签';

  @override
  String get tag_favoritesEmpty => '暂无收藏标签';

  @override
  String get tag_favoritesEmptyHint => '长按标签即可添加到收藏';

  @override
  String get tag_alreadyAdded => '该标签已在当前提示词中';

  @override
  String get tag_removeFavoriteTitle => '移除收藏';

  @override
  String tag_removeFavoriteMessage(Object tag) {
    return '确定要移除收藏的标签「$tag」吗？';
  }

  @override
  String get tag_templatesTitle => '标签模板';

  @override
  String get tag_templatesEmpty => '暂无标签模板';

  @override
  String get tag_templatesEmptyHint => '选择标签后点击右上角的 + 按钮创建模板';

  @override
  String get tag_templateCreate => '创建模板';

  @override
  String get tag_templateNameLabel => '模板名称';

  @override
  String get tag_templateNameHint => '输入模板名称';

  @override
  String get tag_templateNameRequired => '请输入模板名称';

  @override
  String get tag_templateDescLabel => '模板描述（可选）';

  @override
  String get tag_templateDescHint => '输入模板描述';

  @override
  String get tag_templatePreview => '标签预览';

  @override
  String tag_templateTagCount(Object count) {
    return '$count 个标签';
  }

  @override
  String tag_templateMoreTags(Object count) {
    return '还有 $count 个标签...';
  }

  @override
  String tag_templateInserted(Object name) {
    return '已插入模板「$name」';
  }

  @override
  String get tag_templateNoTags => '没有可保存的标签';

  @override
  String get tag_templateSaved => '模板已保存';

  @override
  String get tag_templateNameExists => '模板名称已存在';

  @override
  String get tag_templateDeleteTitle => '删除模板';

  @override
  String tag_templateDeleteMessage(Object name) {
    return '确定要删除模板「$name」吗？';
  }

  @override
  String get tag_categoryGeneral => '通用';

  @override
  String get tag_categoryArtist => '画师';

  @override
  String get tag_categoryCopyright => '版权';

  @override
  String get tag_categoryCharacter => '角色';

  @override
  String get tag_categoryMeta => '元数据';

  @override
  String get tag_countBadgeBreakdown => '标签分类统计';

  @override
  String get localGallery_progressiveLoadError => '图片加载失败';

  @override
  String get localGallery_noImagesFound => '未找到图片';

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
  String get localGallery_loadingGroupedImages => '加载分组图片中...';

  @override
  String get localGallery_title => '本地画廊';

  @override
  String get localGallery_allImages => '全部图片';

  @override
  String get localGallery_categoryPanelTitle => '分类';

  @override
  String get localGallery_selectCurrentPage => '选择本页';

  @override
  String get localGallery_deselectCurrentPage => '取消本页';

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
  String get localGallery_sortToggleDirection => '切换排序方向';

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
  String get localGallery_naiOnly => 'NAI';

  @override
  String get localGallery_naiOnlyTooltip => '仅显示 NAI 生成的图片';

  @override
  String get localGallery_naiVersionFilterLabel => 'Ver';

  @override
  String get localGallery_naiVersionFilterTooltip => '按 NAI 模型版本过滤';

  @override
  String get localGallery_masonryViewLabel => '瀑布流';

  @override
  String get localGallery_switchToMasonryView => '切换到瀑布流视图';

  @override
  String get localGallery_switchToGridLayout => '切换到网格视图';

  @override
  String get localGallery_justifiedViewLabel => '火车流';

  @override
  String get localGallery_switchToJustifiedView => '切换到火车流视图';

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
  String get localGallery_openFilterPanel => '打开筛选面板';

  @override
  String get localGallery_hideCategoryPanel => '隐藏分类面板';

  @override
  String get localGallery_showCategoryPanel => '显示分类面板';

  @override
  String get localGallery_enterSelectionMode => '进入选择模式';

  @override
  String get localGallery_refreshTooltip => '刷新画廊\n\n自动检测新增/修改的图片并更新索引';

  @override
  String get localGallery_tagIntersection => '标签交集';

  @override
  String get localGallery_filterByTags => '按标签筛选';

  @override
  String get localGallery_tagInputHint => '输入标签，回车添加';

  @override
  String get localGallery_addTag => '添加';

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
  String get localGallery_folderName => '文件夹名称';

  @override
  String get localGallery_newFolderName => '新名称';

  @override
  String get localGallery_folderNameHint => '输入文件夹名称';

  @override
  String get localGallery_folderCreated => '文件夹创建成功';

  @override
  String get localGallery_folderCreateFailed => '文件夹创建失败';

  @override
  String get localGallery_renameFolderTitle => '重命名文件夹';

  @override
  String get localGallery_renameSuccess => '重命名成功';

  @override
  String get localGallery_renameFailed => '重命名失败';

  @override
  String get localGallery_deleteFolderTitle => '删除文件夹';

  @override
  String localGallery_deleteFolderWithImagesContent(Object name, Object count) {
    return '文件夹「$name」包含 $count 张图片，确定要删除吗？\n\n注意：此操作会删除文件夹及其中的所有图片，无法恢复。';
  }

  @override
  String localGallery_deleteEmptyFolderContent(Object name) {
    return '确定要删除空文件夹「$name」吗？';
  }

  @override
  String get localGallery_folderDeleted => '文件夹已删除';

  @override
  String get localGallery_folderDeleteFailed => '删除文件夹失败';

  @override
  String get localGallery_withMetadata => '有元数据';

  @override
  String get localGallery_skipped => '跳过';

  @override
  String get localGallery_cacheMonitor => '缓存监控';

  @override
  String get localGallery_threeLayerCacheStats => '三层缓存统计';

  @override
  String localGallery_updatedAt(Object time) {
    return '更新: $time';
  }

  @override
  String get localGallery_memoryCache => '内存缓存';

  @override
  String get localGallery_hiveCache => 'Hive 缓存';

  @override
  String get localGallery_sqliteDatabase => 'SQLite 数据库';

  @override
  String get localGallery_imageUnit => '图片';

  @override
  String get localGallery_metadataUnit => '元数据';

  @override
  String get localGallery_entriesUnit => '条目';

  @override
  String get localGallery_hitRate => '命中率';

  @override
  String get localGallery_performanceStats => '性能监控统计';

  @override
  String get localGallery_cacheHit => '命中';

  @override
  String get localGallery_cacheMiss => '未命中';

  @override
  String get localGallery_clearL1 => '清除 L1';

  @override
  String get localGallery_clearL2 => '清除 L2';

  @override
  String get localGallery_clearAll => '清除全部';

  @override
  String get localGallery_resetStats => '重置统计';

  @override
  String get localGallery_confirmClearCache => '确认清除';

  @override
  String get localGallery_confirmClearCacheContent => '确定要清除所有缓存吗？这将重新扫描所有图片。';

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
  String get statistics_noData => '暂无统计数据';

  @override
  String get statistics_generatedCount => '生成数量';

  @override
  String get statistics_favoriteCount => '收藏数';

  @override
  String statistics_tooltipGenerated(Object count) {
    return '生成数量: $count';
  }

  @override
  String statistics_tooltipFavorite(Object count) {
    return '收藏数: $count';
  }

  @override
  String get statistics_noTagData => '暂无标签数据';

  @override
  String get statistics_generateFirst => '先生成一些图片吧';

  @override
  String get statistics_totalImages => '总图片数';

  @override
  String get statistics_totalSize => '总大小';

  @override
  String get statistics_favorites => '收藏';

  @override
  String get statistics_samplerDistribution => '采样器分布';

  @override
  String get statistics_additionalStats => '其他统计';

  @override
  String get statistics_averageFileSize => '平均文件大小';

  @override
  String get statistics_withMetadata => '有元数据的图片';

  @override
  String get statistics_justNow => '刚刚';

  @override
  String statistics_minutesAgo(Object count) {
    return '$count 分钟前';
  }

  @override
  String statistics_hoursAgo(Object count) {
    return '$count 小时前';
  }

  @override
  String statistics_daysAgo(Object count) {
    return '$count 天前';
  }

  @override
  String get statistics_anlasCost => '点数消耗';

  @override
  String get statistics_totalAnlasCost => '总消耗';

  @override
  String get statistics_avgDailyCost => '日均消耗';

  @override
  String get statistics_noAnlasData => '暂无点数消耗数据';

  @override
  String get statistics_peakActivity => '活跃高峰';

  @override
  String get statistics_timeMorning => '上午';

  @override
  String get statistics_timeAfternoon => '下午';

  @override
  String get statistics_timeEvening => '傍晚';

  @override
  String get statistics_timeNight => '深夜';

  @override
  String get localGallery_advancedFilters => '高级筛选';

  @override
  String get localGallery_filterByModel => '按模型筛选';

  @override
  String get localGallery_filterBySampler => '按采样器筛选';

  @override
  String get localGallery_filterBySteps => '按步数筛选';

  @override
  String get localGallery_filterByCfg => '按 PG 筛选';

  @override
  String get localGallery_filterByResolution => '按分辨率筛选';

  @override
  String get localGallery_filterSubtitle => '精确筛选您的图片集合';

  @override
  String get localGallery_filterOrientation => '画面方向';

  @override
  String get localGallery_orientationAny => '全部';

  @override
  String get localGallery_orientationLandscape => '横版';

  @override
  String get localGallery_orientationPortrait => '竖版';

  @override
  String get localGallery_orientationSquare => '方图';

  @override
  String get localGallery_filterNsfw => '内容分级';

  @override
  String get localGallery_nsfwAny => '全部';

  @override
  String get localGallery_nsfwSfw => '全年龄';

  @override
  String get localGallery_nsfwOnly => '仅 NSFW';

  @override
  String get localGallery_noModelCandidates => '暂无模型元数据，导入标签索引或扫描后可用';

  @override
  String get localGallery_noSamplerCandidates => '暂无采样器元数据，导入标签索引或扫描后可用';

  @override
  String get localGallery_noResolutionCandidates => '暂无分辨率元数据';

  @override
  String get localGallery_candidatesLoadFailed => '候选加载失败';

  @override
  String get localGallery_noTagSuggestions => '无匹配标签';

  @override
  String get localGallery_activeFiltersSet => '已设置筛选';

  @override
  String get localGallery_applyFilters => '应用筛选';

  @override
  String get localGallery_resetAdvancedFilters => '重置高级筛选';

  @override
  String get localGallery_exportFailed => '导出失败';

  @override
  String get bulkExport_format => '导出格式';

  @override
  String get bulkExport_jsonFormat => 'JSON';

  @override
  String get bulkExport_csvFormat => 'CSV';

  @override
  String get bulkExport_includeMetadataHint => '导出生成参数等信息';

  @override
  String get localGallery_group_today => '今天';

  @override
  String get localGallery_group_yesterday => '昨天';

  @override
  String get localGallery_group_thisWeek => '本周';

  @override
  String get localGallery_group_earlier => '更早';

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
  String get statistics_chartAspectRatio => '宽高比分布';

  @override
  String get statistics_chartActivityHeatmap => '活动热力图';

  @override
  String get statistics_chartHourlyDistribution => '小时分布';

  @override
  String get statistics_chartWeekdayDistribution => '星期分布';

  @override
  String get statistics_aspectSquare => '方形';

  @override
  String get statistics_aspectLandscape => '横屏';

  @override
  String get statistics_aspectPortrait => '竖屏';

  @override
  String get statistics_aspectOther => '其他';

  @override
  String get statistics_refresh => '刷新';

  @override
  String get statistics_retry => '重试';

  @override
  String statistics_error(Object error) {
    return '错误: $error';
  }

  @override
  String get statistics_mostActiveDay => '最活跃日';

  @override
  String get statistics_leastActiveDay => '最不活跃日';

  @override
  String get statistics_sunday => '周日';

  @override
  String get statistics_monday => '周一';

  @override
  String get statistics_tuesday => '周二';

  @override
  String get statistics_wednesday => '周三';

  @override
  String get statistics_thursday => '周四';

  @override
  String get statistics_friday => '周五';

  @override
  String get statistics_saturday => '周六';

  @override
  String get fixedTags_negativeTitle => '负向固定词';

  @override
  String autocomplete_resultsCount(Object count) {
    return '$count 个结果';
  }

  @override
  String get autocomplete_actionSelect => '选择';

  @override
  String get autocomplete_actionConfirm => '确认';

  @override
  String get autocomplete_actionClose => '关闭';

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
  String get common_create => '创建';

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
  String get statistics_heatmapLess => '少';

  @override
  String get statistics_heatmapMore => '多';

  @override
  String statistics_heatmapActivities(Object count) {
    return '$count 次活动';
  }

  @override
  String get statistics_heatmapNoActivity => '无活动';

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
  String get metadataImport_fixedTags => '固定词';

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
  String get metadataImport_scale => 'PG';

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
  String get metadataImport_cfgRescale => 'PGR';

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
  String get shortcut_action_previous_page => '上一页';

  @override
  String get shortcut_action_next_page => '下一页';

  @override
  String get shortcut_action_refresh_gallery => '刷新';

  @override
  String get shortcut_action_focus_search => '搜索聚焦';

  @override
  String get shortcut_action_enter_selection_mode => '进入选择模式';

  @override
  String get shortcut_action_open_filter_panel => '打开筛选面板';

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
  String get shortcut_help_tip => '提示：按 F1 或 ? 键可随时打开此帮助对话框';

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
  String get drop_dialogTitle => '如何使用这张图片？';

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
  String get drop_extractMetadata => '提取元数据';

  @override
  String get drop_extractMetadataSubtitle => '读取图片中的 Prompt、Seed 等参数';

  @override
  String get drop_vibeDetected => '检测到预编码 Vibe（可节省 2 Anlas）';

  @override
  String drop_vibeStrength(Object value) {
    return '强度: $value%';
  }

  @override
  String drop_vibeInfoExtracted(Object value) {
    return '信息提取: $value%';
  }

  @override
  String get drop_reuseVibe => '复用 Vibe';

  @override
  String get drop_reuseVibeSubtitle => '直接使用预编码数据（免费）';

  @override
  String get drop_useAsRawImage => '作为原始图片';

  @override
  String get drop_useAsRawImageSubtitle => '重新编码（消耗 2 Anlas）';

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
  String get vibeLibrary_hideCategoryPanel => '隐藏分类面板';

  @override
  String get vibeLibrary_showCategoryPanel => '显示分类面板';

  @override
  String get vibeLibrary_enterSelectionMode => '进入选择模式';

  @override
  String get vibeLibrary_importTooltip =>
      '导入 Vibe 文件或 PNG/JPG/JPEG/WEBP 图片（右键查看更多选项）';

  @override
  String get vibeLibrary_exportTooltip => '导出 Vibe 到文件';

  @override
  String get vibeLibrary_openFolderTooltip => '打开 Vibe 库文件夹';

  @override
  String get vibeLibrary_refresh => '刷新';

  @override
  String get vibeLibrary_loading => '加载中...';

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
  String get vibeBulk_titleDelete => '批量删除';

  @override
  String get vibeBulk_titleMove => '批量移动';

  @override
  String get vibeBulk_titleToggleFavorite => '批量更新收藏';

  @override
  String get vibeBulk_titleAddTags => '批量添加标签';

  @override
  String get vibeBulk_titleRemoveTags => '批量移除标签';

  @override
  String get vibeBulk_titleExport => '批量导出';

  @override
  String get vibeBulk_titleImport => '批量导入';

  @override
  String vibeBulk_processingProgress(int current, int total) {
    return '正在处理：$current / $total';
  }

  @override
  String get vibeBulk_completed => '操作完成';

  @override
  String get vibeBulk_completedWithFailures => '操作完成（部分失败）';

  @override
  String get vibeBulk_successful => '成功';

  @override
  String get vibeBulk_failed => '失败';

  @override
  String get vibeBulk_errorDetails => '错误详情：';

  @override
  String vibeBulk_moreErrors(int count) {
    return '……另有 $count 个错误';
  }

  @override
  String get vibeBulk_operationFailed => '操作失败';

  @override
  String get vibeBulk_operationFailedHint => '请检查操作设置后重试。';

  @override
  String vibeBulk_errorEntryNotFoundOrDeleteFailed(String item) {
    return '未找到 $item 或删除失败';
  }

  @override
  String vibeBulk_errorDeleteFailed(String item, String error) {
    return '删除 $item 失败：$error';
  }

  @override
  String vibeBulk_errorEntryNotFound(String item) {
    return '未找到条目：$item';
  }

  @override
  String vibeBulk_errorMoveFailed(String item, String error) {
    return '移动 $item 失败：$error';
  }

  @override
  String vibeBulk_errorFavoriteFailed(String item) {
    return '更新收藏状态失败：$item';
  }

  @override
  String vibeBulk_errorFavoriteFailedWithDetails(String item, String error) {
    return '更新 $item 的收藏状态失败：$error';
  }

  @override
  String vibeBulk_errorAddTagsFailed(String item) {
    return '添加标签失败：$item';
  }

  @override
  String vibeBulk_errorAddTagsFailedWithDetails(String item, String error) {
    return '为 $item 添加标签失败：$error';
  }

  @override
  String vibeBulk_errorRemoveTagsFailed(String item) {
    return '移除标签失败：$item';
  }

  @override
  String vibeBulk_errorRemoveTagsFailedWithDetails(String item, String error) {
    return '从 $item 移除标签失败：$error';
  }

  @override
  String get vibeBulk_errorExportNoFile => '导出失败：未创建文件';

  @override
  String vibeBulk_errorExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String vibeBulk_errorFileNotFound(String item) {
    return '未找到文件：$item';
  }

  @override
  String vibeBulk_errorNoVibeData(String item) {
    return '$item 中没有有效的 Vibe 数据';
  }

  @override
  String vibeBulk_errorImportFailed(String item, String error) {
    return '从 $item 导入 Vibe 失败：$error';
  }

  @override
  String vibeBulk_errorProcessFileFailed(String item, String error) {
    return '处理 $item 失败：$error';
  }

  @override
  String get vibeBulkTag_title => '批量编辑标签';

  @override
  String vibeBulkTag_selectedCount(int count) {
    return '已选中 $count 个 Vibe';
  }

  @override
  String get vibeBulkTag_inputHint => '输入新标签……';

  @override
  String get vibeBulkTag_noTags => '暂无标签';

  @override
  String get vibeBulkTag_noTagsHint => '添加标签以方便筛选和管理';

  @override
  String vibeBulkTag_currentTags(int count) {
    return '当前标签（$count）';
  }

  @override
  String vibeBulkTag_pendingRemoval(int count) {
    return '待移除标签（$count）';
  }

  @override
  String get vibeBulkTag_removeTag => '移除标签';

  @override
  String get vibeBulkTag_actionPreview => '操作预览';

  @override
  String vibeBulkTag_addTagsSummary(String tags) {
    return '添加标签：$tags';
  }

  @override
  String vibeBulkTag_removeTagsSummary(String tags) {
    return '移除标签：$tags';
  }

  @override
  String get vibeBulkTag_noChanges => '没有要应用的更改';

  @override
  String get vibeBulkCategory_title => '选择目标分类';

  @override
  String vibeBulkCategory_moveCount(int count) {
    return '将 $count 个 Vibe 移动到：';
  }

  @override
  String get vibeBulkCategory_cannotMoveToCurrent => '不能移动到当前所在分类';

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
  String vibe_import_failedWithError(String error) {
    return '导入失败: $error';
  }

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
  String get vibe_maxReachedRemoveSome => '已达到最大数量 (16张)，请先移除一些 Vibe';

  @override
  String vibe_addedNamed(String name) {
    return '已添加 Vibe: $name';
  }

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
  String get settings_kritaBridgeEnable => '启用 Krita 本地桥接';

  @override
  String get settings_kritaBridgeDisabledText => '默认关闭；开启后只监听本机 127.0.0.1';

  @override
  String get settings_kritaBridgeStartingText => '正在启动本地桥接服务...';

  @override
  String get settings_kritaBridgeListeningText => '等待 Krita 插件连接';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita 插件已连接';

  @override
  String get settings_kritaBridgeErrorText => '启动失败，请查看错误信息';

  @override
  String get settings_kritaBridgeDisabled => '已关闭';

  @override
  String get settings_kritaBridgeStarting => '启动中';

  @override
  String get settings_kritaBridgeListening => '监听中';

  @override
  String get settings_kritaBridgeConnected => '已连接';

  @override
  String get settings_kritaBridgeError => '错误';

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
  String get settings_highAnlasCostTitle => '保护模式：Anlas 消耗较高';

  @override
  String settings_highAnlasCostContent(Object cost, Object threshold) {
    return '本次预计消耗 $cost Anlas，已达到或超过你设置的 $threshold Anlas 警告阈值。请确认是否继续生成。';
  }

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
  String get settings_comfyUiWorkflowManagement => '工作流管理';

  @override
  String get settings_comfyUiBuiltinWorkflows => '内置工作流';

  @override
  String get settings_comfyUiCustomWorkflows => '自定义工作流';

  @override
  String get settings_comfyUiNoCustomWorkflows =>
      '暂无自定义工作流，点击“导入”添加 ComfyUI 工作流';

  @override
  String settings_comfyUiSlotCount(Object count) {
    return '$count 个槽位';
  }

  @override
  String get settings_comfyUiBuiltin => '内置';

  @override
  String get settings_comfyUiDeleteWorkflowTitle => '删除工作流';

  @override
  String settings_comfyUiDeleteWorkflowContent(Object name) {
    return '确定要删除工作流“$name”吗？此操作不可撤销。';
  }

  @override
  String settings_comfyUiDeleted(Object name) {
    return '已删除: $name';
  }

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
  String get toast_tagCopied => '标签已复制';

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
  String get pagination_firstPage => '首页';

  @override
  String get pagination_previousPage => '上一页';

  @override
  String get pagination_nextPage => '下一页';

  @override
  String get pagination_lastPage => '末页';

  @override
  String get pagination_jumpToPage => '跳转到页面';

  @override
  String get pagination_jump => '跳转';

  @override
  String get pagination_itemsPerPage => '每页';

  @override
  String get pagination_itemUnit => '项';

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
  String get model3d_addMannequin => '添加内置人偶';

  @override
  String get model3d_importModel => '导入模型 (.glb/.gltf)';

  @override
  String get model3d_emptyHint => '场景为空，先添加人偶或导入模型';

  @override
  String get model3d_apply => '应用到图层';

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
  String get model3d_undo => '撤销';

  @override
  String get model3d_resetPose => '重置姿势';

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
  String get model3d_lightIntensity => '强度';

  @override
  String get model3d_lightAzimuth => '方位角';

  @override
  String get model3d_lightElevation => '仰角';

  @override
  String get model3d_addLayerTooltip => '添加 3D 模型图层';

  @override
  String get model3d_webview2Missing =>
      '3D 编辑器需要 Microsoft Edge WebView2 运行时。Windows 10/11 通常已自带;若缺失请从微软官网安装 Evergreen 版本后重试。';

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
  String get preciseRefLib_deleteEntry => '删除';

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
  String get common_previewLoadFailed => '无法加载预览';

  @override
  String get common_clickToRefresh => '点击刷新';

  @override
  String get common_clickToRetry => '点击重试';

  @override
  String get common_opening => '正在打开...';

  @override
  String get common_swap => '交换';

  @override
  String get common_minimum => '最小值';

  @override
  String get common_maximum => '最大值';

  @override
  String get addToLibrary_displayNameHint => '输入便于识别此条目的名称';

  @override
  String get addToLibrary_tagHint => '输入标签并按 Enter 添加';

  @override
  String get drop_saveVibeBundle => '保存 Vibe Bundle';

  @override
  String drop_saveVibeBundleSubtitle(String name) {
    return '将 $name 等 Vibe 保存到库中';
  }

  @override
  String get drop_saveEncodedVibeSubtitle => '将预编码 Vibe 数据保存到库中';

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
  String get localGallery_createFolder => '创建文件夹';

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
  String get editor_effects => '效果';

  @override
  String get editor_shiftEdges => '扩展边缘';

  @override
  String editor_currentSize(int width, int height) {
    return '当前: $width x $height';
  }

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
  String get editor_nonNegativeNumber => '必须大于或等于 0';

  @override
  String editor_requestedSize(int width, int height) {
    return '请求尺寸: $width x $height';
  }

  @override
  String get editor_requestedSizeInvalid => '请求尺寸: 无效';

  @override
  String editor_appliedSize(int width, int height) {
    return '应用尺寸: $width x $height';
  }

  @override
  String get editor_appliedSizeInvalid => '应用尺寸: 无效';

  @override
  String editor_appliedEdges(int left, int top, int right, int bottom) {
    return '应用边缘: 左 $left、上 $top、右 $right、下 $bottom';
  }

  @override
  String get editor_appliedEdgesInvalid => '应用边缘: 无效';

  @override
  String editor_appliedDimensionLimit(int max) {
    return '应用后的尺寸不能超过 $max。';
  }

  @override
  String get onlineGallery_videoLoadFailed => '视频加载失败';

  @override
  String get vibe_releaseToAddStyleReference => '松开后添加风格参考';

  @override
  String router_pageNotFound(String error) {
    return '页面未找到: $error';
  }

  @override
  String get autocomplete_translating => '翻译中…';

  @override
  String get autocomplete_missingTranslation => '未汉化';

  @override
  String autocomplete_aliasMatch(String alias) {
    return '别名：$alias';
  }

  @override
  String get autocomplete_resultLimit => '结果数量';

  @override
  String get autocomplete_relatedTagsTitle => '标签扩展';

  @override
  String get autocomplete_relatedTagsSubtitle => 'Ctrl+单击搜索本地标签；Ctrl+拖选查看关联标签';

  @override
  String get tagExpansion_searchHint => '搜索标签、别名或汉化名';

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
  String get autocomplete_danbooruPrivacy => '仅发送当前英文标签，不会上传完整提示词';

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
  String get autocomplete_sourceBase => '随应用提供的基础词库';

  @override
  String get autocomplete_sourceApi => 'Danbooru API';

  @override
  String get autocomplete_sourceRelated => '离线相关标签';

  @override
  String get autocomplete_sourceAi => 'Prompt Assistant 汉化';

  @override
  String get autocomplete_headerTitle => '标签补全';

  @override
  String get autocomplete_relatedHeaderTitle => '相关标签';

  @override
  String get autocomplete_relatedLoading => '正在查询本地共现库与在线相关标签…';

  @override
  String get autocomplete_relatedEmpty => '没有找到可用的相关标签';

  @override
  String autocomplete_relatedMetric(int count, String score) {
    return '共现 $count 次 · Jaccard $score';
  }

  @override
  String get autocomplete_relatedPin => '固定当前标签，可连续插入相关标签';

  @override
  String get autocomplete_relatedUnpin => '取消固定并继续链式推荐';

  @override
  String get autocomplete_statusBase => '本地';

  @override
  String get autocomplete_statusRelated => '共现';

  @override
  String get autocomplete_statusOnline => '在线';

  @override
  String get autocomplete_statusAi => 'AI';

  @override
  String get autocomplete_statusReady => '就绪';

  @override
  String get autocomplete_statusError => '异常';

  @override
  String get autocomplete_statusDisabled => '已关闭';

  @override
  String get autocomplete_statusSearching => '查询中';

  @override
  String get autocomplete_statusTranslating => '翻译中';

  @override
  String get autocomplete_openSettings => '打开补全与数据源设置';

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
      '请检查设置：步数 1–50、PG 1–20、PGR 0–1，并确认参数受所选模型支持。';

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
  String get styleExplore_previewEmpty => '（空）';

  @override
  String get styleExplore_copiedToClipboard => '已复制';

  @override
  String get styleExplore_runSectionTitle => '探索任务';

  @override
  String get styleExplore_runEmptyHint => '探索任务（Run）固化提示词与参数快照，批量生成候选并筛选。';

  @override
  String get styleExplore_newRun => '新建任务';

  @override
  String get styleExplore_galleryTitle => '候选画廊';

  @override
  String get styleExplore_galleryEmptyHint => '暂无候选。新建或选择一个探索任务，开始批量生成。';

  @override
  String get styleExplore_labTip => '选择喜欢的候选，让画风逐代进化。';

  @override
  String get styleExplore_runNameLabel => '任务名称';

  @override
  String get styleExplore_runNameHint => '例如：柔光画风 ×30';

  @override
  String styleExplore_runCreated(String name) {
    return '已创建任务「$name」';
  }

  @override
  String styleExplore_runDeleted(String name) {
    return '已删除任务「$name」';
  }

  @override
  String styleExplore_runTotalCount(int total) {
    return '共 $total 张';
  }

  @override
  String styleExplore_runGeneratingProgress(int current, int total) {
    return '第 $current/$total 张';
  }

  @override
  String get styleExplore_runStatusDraft => '草稿';

  @override
  String get styleExplore_runStatusGenerating => '生成中';

  @override
  String get styleExplore_runStatusPaused => '已暂停';

  @override
  String get styleExplore_runStatusGenerated => '已生成';

  @override
  String get styleExplore_runStatusCompleted => '已完成';

  @override
  String get styleExplore_runStatusCancelled => '已取消';

  @override
  String get styleExplore_pauseRun => '暂停';

  @override
  String get styleExplore_cancelRun => '取消任务';

  @override
  String styleExplore_retryFailed(int count) {
    return '重试失败（$count）';
  }

  @override
  String get styleExplore_targetCountLabel => '出图数';

  @override
  String styleExplore_manualRunName(String time) {
    return '手动候选 $time';
  }

  @override
  String get styleExplore_runBusy => '生成进行中，稍后再试';

  @override
  String get styleExplore_deleteRunTitle => '删除探索任务';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return '将删除「$name」及其候选图副本；图库中的源图不受影响。';
  }

  @override
  String get styleExplore_cancelRunTitle => '取消探索任务';

  @override
  String get styleExplore_cancelRunMessage => '取消后不可再启动；剩余待生成候选将标记为已取消。';

  @override
  String get styleExplore_filterAll => '全部';

  @override
  String get styleExplore_filterHearted => '收藏';

  @override
  String get styleExplore_newFolder => '新建文件夹';

  @override
  String get styleExplore_renameFolder => '重命名文件夹';

  @override
  String get styleExplore_deleteFolder => '删除文件夹';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return '将删除文件夹「$name」；其中的候选回到未分类，图片不会被删除。';
  }

  @override
  String get styleExplore_folderNameLabel => '文件夹名称';

  @override
  String get styleExplore_deleteFamily => '删除谱系';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return '将删除谱系「$name」及其全部父本集与候选记录（$count 张）；候选图片文件不会删除。';
  }

  @override
  String get styleExplore_familyBusy => '谱系内还有生成中的候选，请先取消任务';

  @override
  String get styleExplore_folderUncategorized => '未分类';

  @override
  String styleExplore_folderCreated(String name) {
    return '已创建文件夹「$name」';
  }

  @override
  String get styleExplore_assignToFolder => '归类到';

  @override
  String get styleExplore_candidateMissing => '图片文件缺失';

  @override
  String get styleExplore_candidateDetailTitle => '候选详情';

  @override
  String styleExplore_candidatePosition(int current, int total) {
    return '第 $current/$total 张';
  }

  @override
  String get styleExplore_prevCandidate => '上一张';

  @override
  String get styleExplore_nextCandidate => '下一张';

  @override
  String get styleExplore_rollSnapshot => 'Roll 快照';

  @override
  String styleExplore_seedLabel(String seed) {
    return 'Seed $seed';
  }

  @override
  String styleExplore_roundNumber(int number) {
    return '第 $number 轮';
  }

  @override
  String get styleExplore_adoptAsBlock => '收编为块';

  @override
  String get styleExplore_adoptBlockNameLabel => '块名称';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已收编为块「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所选候选没有可用的 Roll 串';

  @override
  String get styleExplore_fixateAsTemplate => '导入元数据';

  @override
  String get styleExplore_fixateDone => '已导入元数据到编辑区';

  @override
  String get styleExplore_deleteImage => '删除图片';

  @override
  String get styleExplore_deleteImageTitle => '删除候选图';

  @override
  String get styleExplore_deleteImageMessage =>
      '将删除该候选在 Run 目录中的图片副本与候选记录；图库源图不受影响。';

  @override
  String get styleExplore_deleteImageDone => '已删除候选图与记录';

  @override
  String get styleExplore_selectCandidates => '多选';

  @override
  String styleExplore_selectedCount(int count) {
    return '已选 $count 张';
  }

  @override
  String get styleExplore_mergeAdopt => '合并收编';

  @override
  String get styleExplore_noRunsYet => '还没有探索任务';

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
  String get styleExplore_lineageTitle => '谱系';

  @override
  String get styleExplore_createFamily => '建家族';

  @override
  String styleExplore_familyCreated(String name) {
    return '已创建家族「$name」';
  }

  @override
  String get styleExplore_familyNameLabel => '家族名称';

  @override
  String get styleExplore_familyNameHint => '例如：柔光主线';

  @override
  String styleExplore_familyParentsTitle(int count) {
    return '父本（$count）';
  }

  @override
  String get styleExplore_customParentLabel => '自定义父本串';

  @override
  String get styleExplore_customParentHint => '输入一段提示词串作为父本';

  @override
  String get styleExplore_addCustomParent => '添加自定义串';

  @override
  String get styleExplore_createFamilyEmpty => '请至少保留一个有效父本串';

  @override
  String styleExplore_parentSetTitle(int generation) {
    return '第 $generation 代父本集';
  }

  @override
  String styleExplore_candidatePileTitle(int generation, int count) {
    return '第 $generation 代候选堆 · $count 张';
  }

  @override
  String get styleExplore_parentSetActive => '活跃';

  @override
  String get styleExplore_parentSetUsed => '已回交';

  @override
  String styleExplore_branchLabel(String name) {
    return '分支：$name';
  }

  @override
  String get styleExplore_createDeepRound => '生成候选图';

  @override
  String styleExplore_deepRoundCountHint(int min) {
    return '出图数至少 $min（每个父本保底一张）';
  }

  @override
  String get styleExplore_deepRoundNoInstance => '主提示词中没有启用的随机遗传块，无法进行深度轮';

  @override
  String get styleExplore_deepRoundEmpty => '变异引擎无法产出足够不同的子代串';

  @override
  String get styleExplore_sortParents => 'A/B 组对照';

  @override
  String get styleExplore_sortTitle => '父本A/B组对照';

  @override
  String get styleExplore_sortPrompt => '哪张图更接近你想要的画风效果？';

  @override
  String get styleExplore_sortLeft => '左边好';

  @override
  String get styleExplore_sortRight => '右边好';

  @override
  String get styleExplore_sortNeither => '都不好';

  @override
  String get styleExplore_sortSkip => '跳过';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return '第 $current/$total 对';
  }

  @override
  String get styleExplore_sortDone => '排序完成';

  @override
  String get styleExplore_branchSelect => '多选建分支';

  @override
  String get styleExplore_createBranch => '建分支';

  @override
  String get styleExplore_branchNameLabel => '分支名称（可选）';

  @override
  String styleExplore_branchCreated(int count) {
    return '已创建分支（$count 个父本）';
  }

  @override
  String get styleExplore_branchNeedLatest => '只能从最新代候选堆建分支';

  @override
  String get styleExplore_branchRoundsIncomplete => '当前代还有未完成的候选轮';

  @override
  String get styleExplore_branchDuplicate => '所选子代与第一代父本串完全重复';

  @override
  String get styleExplore_branchEmpty => '请至少选择一张子代候选';

  @override
  String styleExplore_preferenceValue(String value) {
    return '偏好 $value';
  }

  @override
  String styleExplore_roundsSummary(int count) {
    return '$count 轮';
  }

  @override
  String get styleExplore_pileEmpty => '尚无候选图，点上方「生成候选图」开始';

  @override
  String get styleExplore_managePile => '管理';

  @override
  String get styleExplore_pileManageDeleteTitle => '删除所选候选图';

  @override
  String styleExplore_pileManageDeleteMessage(int count) {
    return '将删除 $count 张候选在 Run 目录中的图片副本与候选记录；图库源图不受影响。';
  }

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
  String get tips_gen_teach_1 => '在提示词框输入 < 可以拉进块库里的块';

  @override
  String get tips_gen_teach_2 => '摘要条点 Seed 可锁定/重抽，点 Sampler 可直接换采样器';

  @override
  String get tips_gen_teach_3 => '生成键旁边的数字小框定本批张数，右端深色框是 Anlas 消耗';

  @override
  String get tips_gen_teach_4 => '右上角 chunks 菜单里收纳了块库、预设和正则规则';

  @override
  String get tips_gen_teach_5 => '透明通道导出 Alpha 通道；启用角色参考时不可用';

  @override
  String get tips_gen_fun_1 => '正在给 AI 喂电子小鱼干…';

  @override
  String get tips_gen_fun_2 => '每张图都是一次小型抽卡——抽吧';

  @override
  String get tips_gen_fun_3 => 'Anlas 余额和模型名都在头顶上——烧钱前瞄一眼';

  @override
  String get tips_gen_fun_4 => '提示词框长高了，方便野心摊开写';

  @override
  String get tips_gen_fun_5 => '种子 -1 交给命运；据说命运喜欢整数';

  @override
  String get tips_explore_teach_1 => '点红心+归文件夹，就是给下一代投票';

  @override
  String get tips_explore_teach_2 => 'A/B 对照组看的是父本原图——选出胜者就翻篇';

  @override
  String get tips_explore_teach_3 => '「生成候选图」旁边的数字框定本轮批量';

  @override
  String get tips_explore_teach_4 => '悬停候选堆缩略图能看大图';

  @override
  String get tips_explore_teach_5 => '拖分隔条可以拉宽画廊栏';

  @override
  String get tips_explore_fun_1 => '适者生存，画也一样';

  @override
  String get tips_explore_fun_2 => '每一轮生图都是海选现场';

  @override
  String get tips_explore_fun_3 => '好基因来自好父本';

  @override
  String get tips_explore_fun_4 => '永远不要小看变异';

  @override
  String get tips_explore_fun_5 => '自然选择，加速版';

  @override
  String get tips_gallerySearch_teach_1 => '逗号分隔 = 交集搜索';

  @override
  String get tips_gallerySearch_teach_2 => '文字搜索已排除负面提示词——结果更干净';

  @override
  String get tips_gallerySearch_teach_3 => '搜索会命中模型、采样器、来源、版本字段';

  @override
  String get tips_gallerySearch_teach_4 => '按钮放不下时会横向滚动';

  @override
  String get tips_gallerySearch_teach_5 => '每页最多 500 张——给一口气翻到底的人';

  @override
  String get tips_gallerySearch_fun_1 => '下面看上去有不少好东西呢~~~打算找点什么吗？';

  @override
  String get tips_gallerySearch_fun_2 => '收藏在长，文件夹在假装跟得上';

  @override
  String get tips_gallerySearch_fun_3 => '专业建议：自己的提示词就是最好的搜索词';

  @override
  String get tips_gallerySearch_fun_4 => '滚动也算运动';

  @override
  String get tips_gallerySearch_fun_5 => '这堆里某个角落藏着今晚的神作';

  @override
  String get tips_gallerySearch_start_1 => '搜文件名或提示词正文——回车或点补全项都行';

  @override
  String get tips_gallerySearch_start_2 => '多个词用逗号分隔 = 全部命中才算数';

  @override
  String get tips_gallerySearch_start_3 => '搜索只看正向提示词，负面词不会误中';

  @override
  String get tips_gallerySearch_start_4 => '模型、采样器、来源、版本字段也能被搜到';

  @override
  String get tips_gallerySearch_start_5 => '输入标签（比如 masterpiece）或文件名片段即可';

  @override
  String get tips_gallerySearch_start_6 => '找到了点卡片看详情，右键有更多操作';

  @override
  String get tips_gallerySearch_start_7 => '配合右侧版本 chip 可以进一步收窄范围';

  @override
  String get tips_gallerySearch_start_8 => '空着就是浏览全部；输入即筛不用等';

  @override
  String get tips_gallerySearch_start_9 => '边输边搜，不用按回车';

  @override
  String get tips_gallerySearch_start_10 => '先搜一搜再考虑重新生成——多半已经有了';

  @override
  String get tips_blocklib_teach_1 => '块可以带缩略图——编辑弹窗里设置';

  @override
  String get tips_blocklib_teach_2 => '点击块开详情，悬停先看大图';

  @override
  String get tips_blocklib_teach_3 => '⭐ 收进收藏集，常用块置顶集中';

  @override
  String get tips_blocklib_teach_4 => '瀑布流视图能看清图块';

  @override
  String get tips_blocklib_teach_5 => '拖分割条可以调整块区/文件夹区比例';

  @override
  String get tips_blocklib_fun_1 => '每个块都梦想着被点名';

  @override
  String get tips_blocklib_fun_2 => '文件夹里套文件夹——现在算是有条理了';

  @override
  String get tips_blocklib_fun_3 => '使用次数就是块的履历表';

  @override
  String get tips_blocklib_fun_4 => '积木留给钉子户';

  @override
  String get tips_blocklib_fun_5 => '犹豫就做成块';

  @override
  String get tips_gen_1 => '文本框里 Ctrl+Z 管用——错别字不可怕';

  @override
  String get tips_gen_2 => '设置→提示词的 chunks 菜单里藏着不少开关';

  @override
  String get tips_gen_3 => '看见细分隔条就拖拖看——多数面板能调宽';

  @override
  String get tips_gen_4 => '历史栏可以调回旧图和当时的参数';

  @override
  String get tips_gen_5 => '右键出菜单，悬停出预览';

  @override
  String get tips_fun_1 => '正在加载今日份的玄学…';

  @override
  String get tips_fun_2 => '种子是随机的，品味不是';

  @override
  String get tips_fun_3 => '某处有一块显卡正在摩拳擦掌';

  @override
  String get tips_fun_4 => '这里最贵的按钮是生成——它吃 Anlas';

  @override
  String get tips_fun_5 => '这个框见证过上千张神作（和几张黑历史）';

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
  String get img2img_original => '原图';

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
  String get generation_tipReuseBlocks => '把常用提示词保存为块，下一次直接复用。';

  @override
  String get generation_tipBlockModes => '顺序与随机模式，可以让提示词块产生不同组合。';

  @override
  String get generation_tipLockBlocks => '锁定想保留的块，再随机调整其他部分。';

  @override
  String get styleExplore_collapseGallery => '收起候选画廊';

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
  String get wiki_searchHint => '搜索标签、别名或中文译名';

  @override
  String get wiki_typeAll => '全部类型';

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
  String get wiki_hide => '隐藏';

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
  String get progress_cancelled => '已取消';

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
  String gallery_initFailed(Object error) {
    return '初始化失败: $error';
  }

  @override
  String gallery_loadFoldersFailed(Object error) {
    return '加载文件夹失败: $error';
  }

  @override
  String gallery_refreshFailed(Object error) {
    return '刷新失败: $error';
  }

  @override
  String gallery_clearCacheFailed(Object error) {
    return '清除缓存失败: $error';
  }

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
  String get cache_clearInProgress => '清除操作正在进行中';

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
  String get common_folder => '資料夾';

  @override
  String get common_filter => '篩選';

  @override
  String get common_grid => '網格';

  @override
  String get common_date => '日期';

  @override
  String get common_pack => '打包';

  @override
  String get common_multiSelect => '多選';

  @override
  String get common_category => '分類';

  @override
  String get common_categories => '分類';

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
  String get auth_loggedIn => '已登入';

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
  String get auth_savedAccounts => '已儲存的帳號';

  @override
  String get auth_addAccount => '新增帳號';

  @override
  String get auth_manageAccounts => '管理';

  @override
  String auth_moreAccounts(Object count) {
    return '還有 $count 個帳號';
  }

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
  String get settings_editNickname => '編輯暱稱';

  @override
  String get settings_nickname => '暱稱';

  @override
  String get settings_nicknameHint => '輸入2-32個字元';

  @override
  String get settings_nicknameEmpty => '請輸入暱稱';

  @override
  String settings_nicknameTooLong(int maxLength) {
    return '暱稱不能超過$maxLength個字元';
  }

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
  String get generation_canvasSendToTools => '傳送到影像工具';

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
  String get generation_guidance => 'PG';

  @override
  String generation_cfgScale(Object scale) {
    return 'PG：$scale';
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
    return 'PGR：$value';
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
  String get generation_sectionImageSettings => '影像設定';

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
  String get img2img_generateVariations => '生成變體';

  @override
  String get img2img_directorTools => '導演工具';

  @override
  String get img2img_directorPrompt => '附加提示詞';

  @override
  String get img2img_directorPromptHint => '需要時補充描述，例如目標情緒或上色方向';

  @override
  String get img2img_directorRunning => '正在處理...';

  @override
  String get img2img_directorResult => '處理結果';

  @override
  String get img2img_directorApplied => '已將導演工具結果設為新的來源圖';

  @override
  String get img2img_directorDefry => 'Defry';

  @override
  String get img2img_directorEmotionLevel => '表情強度';

  @override
  String get img2img_directorApplyAsSource => '設為來源圖';

  @override
  String get img2img_directorSourceImage => '來源圖';

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
  String get img2img_novelAiCloudUpscale => 'NovelAI 雲端超分 (固定 4x 放大)';

  @override
  String get img2img_comfyuiEnableHint => '請先在「設定 > ComfyUI」中啟用並連線伺服器。';

  @override
  String get img2img_upscaleMode => '放大方式';

  @override
  String get img2img_upscaleRegularModel => '普通模型';

  @override
  String get img2img_upscaleModel => '超分模型';

  @override
  String get img2img_noSeedvr2Models =>
      '未發現 SeedVR2 模型，請重新整理模型列表或檢查 SeedVR2 節點/模型檔案。';

  @override
  String get img2img_noRegularUpscaleModels =>
      '未發現普通超分模型，請重新整理模型列表或檢查 models/upscale_models。';

  @override
  String get img2img_useSeedvr2TiledWorkflow =>
      '將使用 SeedVR2TilingUpscaler 分塊超分流程。';

  @override
  String get img2img_useSeedvr2Workflow => '將使用 SeedVR2VideoUpscaler 流程。';

  @override
  String get img2img_useRegularUpscaleWorkflow =>
      '將使用 UpscaleModelLoader + ImageUpscaleWithModel 流程，並用 Lanczos 修正到目標倍率。';

  @override
  String get img2img_useRtxUpscaleWorkflow =>
      '將使用 RTX Video Super Resolution 流程，無需選擇模型。';

  @override
  String get img2img_refreshModelList => '重新整理模型列表';

  @override
  String get img2img_startUpscale => '開始超分';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 超分完成';

  @override
  String img2img_upscaleComplete(Object width, Object height) {
    return '超分完成 (${width}x$height)';
  }

  @override
  String img2img_regularUpscaleComplete(Object width, Object height) {
    return '普通模型超分完成 (${width}x$height)';
  }

  @override
  String img2img_rtxUpscaleComplete(Object width, Object height) {
    return 'RTX 超分完成 (${width}x$height)';
  }

  @override
  String get img2img_noAvailableSeedvr2Model => '未選擇可用的 SeedVR2 模型';

  @override
  String get img2img_noAvailableRegularUpscaleModel => '未選擇可用的普通超分模型';

  @override
  String get img2img_decodeSourceFailed => '無法解碼來源影像';

  @override
  String get img2img_metricSpeed => '速度';

  @override
  String get img2img_metricVram => '視訊記憶體';

  @override
  String get img2img_metricQuality => '效果';

  @override
  String get img2img_seedvr2VaeTileHint =>
      '同時寫入 SeedVR2 VAE MODEL 的 encode/decode tile size。';

  @override
  String get img2img_seedvr2UseTiledUpscale => '使用分塊放大';

  @override
  String get img2img_seedvr2UseTiledUpscaleHint =>
      '啟用後改用 SeedVR2TilingUpscaler，適合大圖或視訊記憶體壓力較高的場景。';

  @override
  String get img2img_seedvr2TileSize => '分塊圖塊大小';

  @override
  String get img2img_seedvr2TileSizeHint =>
      '同時控制 SeedVR2TilingUpscaler 的 tile_width / tile_height。';

  @override
  String get img2img_seedvr2BlocksToSwap => '記憶體卸載層數';

  @override
  String get img2img_seedvr2BlocksToSwapHint =>
      '把多少 DiT 層放在記憶體裡、推理時再逐層送入視訊記憶體。調高更省視訊記憶體但更吃記憶體也更慢；視訊記憶體充裕可調低甚至設為 0。視訊記憶體不足報錯時請調高。';

  @override
  String get img2img_upscalePanelOpened => '已開啟圖生圖超分面板';

  @override
  String get editor_done => '完成';

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
  String get editor_resetView => '重設檢視';

  @override
  String get editor_zoom => '縮放';

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
  String get editor_shortcutUndo => '復原 (Ctrl+Z)';

  @override
  String get editor_shortcutRedo => '重做 (Ctrl+Y)';

  @override
  String get editor_back => '返回';

  @override
  String get editor_layers => '圖層';

  @override
  String get editor_loadMask => '載入遮罩';

  @override
  String get editor_togglePanels => '切換面板';

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
  String get editor_tempColorPickerShortcut => 'Alt+點選: 臨時取色';

  @override
  String get editor_shortcutHelpTitle => '快速鍵幫助';

  @override
  String get editor_shortcutPaintTools => '繪畫工具';

  @override
  String get editor_shortcutSelectionTools => '選區工具';

  @override
  String get editor_shortcutCanvasView => '畫布檢視';

  @override
  String get editor_shortcutBrushAdjust => '筆刷調整';

  @override
  String get editor_shortcutColors => '顏色';

  @override
  String get editor_shortcutCanvasActions => '畫布操作';

  @override
  String get editor_shortcutHistoryActions => '歷史操作';

  @override
  String get editor_shortcutSelectionActions => '選區操作';

  @override
  String get editor_shortcutTemporaryColorPicker => '臨時拾色器';

  @override
  String get editor_shortcutRectSelection => '矩形選區';

  @override
  String get editor_shortcutEllipseSelection => '橢圓選區';

  @override
  String get editor_shortcutLassoSelection => '套索選區';

  @override
  String get editor_shortcut100Zoom => '100% 縮放';

  @override
  String get editor_shortcutFitHeight => '適應高度';

  @override
  String get editor_shortcutFitWidth => '適應寬度';

  @override
  String get editor_shortcutRotateLeft15 => '向左旋轉 15°';

  @override
  String get editor_shortcutResetRotation => '重設旋轉';

  @override
  String get editor_shortcutRotateRight15 => '向右旋轉 15°';

  @override
  String get editor_shortcutFlipHorizontal => '水平鏡像';

  @override
  String get editor_shortcutWheel => '滾輪';

  @override
  String get editor_shortcutBrushSmaller => '減小筆刷';

  @override
  String get editor_shortcutBrushLarger => '增大筆刷';

  @override
  String get editor_shortcutOpacityLower => '降低透明度';

  @override
  String get editor_shortcutOpacityHigher => '提高透明度';

  @override
  String get editor_shortcutDragBrushSize => '調整筆刷大小';

  @override
  String get editor_shortcutSwapColors => '交換前景/背景色';

  @override
  String get editor_shortcutPanCanvas => '平移畫布';

  @override
  String get editor_shortcutClearSelectionContent => '清除選區內容';

  @override
  String get editor_shortcutCancelCurrentAction => '取消當前操作';

  @override
  String get editor_selectUnlockedLayerWithContent => '請選擇一個非鎖定且有內容的圖層';

  @override
  String get editor_readCurrentLayerFailed => '無法讀取當前圖層';

  @override
  String get editor_localEffects => '本地後處理 / Effects';

  @override
  String get editor_basicAdjustments => '基礎調整';

  @override
  String get editor_styleAndRepair => '風格與修復';

  @override
  String get editor_transformCrop => '旋轉 / 翻轉 / 裁切';

  @override
  String get editor_transformCropDescription =>
      '幾何操作已經獨立出來，點選後會先生成預覽，確認應用後才寫回圖層。';

  @override
  String get editor_effectPreviewHint => '預覽不會修改原圖；點選應用後才會把結果寫入當前活動圖層和復原歷史。';

  @override
  String get editor_applyToCurrentLayer => '應用到當前圖層';

  @override
  String editor_oneShotEffectHint(Object effect) {
    return '$effect 是一次性操作，沒有強度滑條。';
  }

  @override
  String editor_effectIntensity(Object effect) {
    return '$effect 強度';
  }

  @override
  String get editor_original => '原圖';

  @override
  String get editor_effectPreview => '效果預覽';

  @override
  String get editor_effectBrightness => '亮度';

  @override
  String get editor_effectContrast => '對比度';

  @override
  String get editor_effectSaturation => '飽和度';

  @override
  String get editor_effectTemperature => '色溫';

  @override
  String get editor_effectGamma => '伽馬';

  @override
  String get editor_effectGrayscale => '灰度';

  @override
  String get editor_effectInvert => '反相';

  @override
  String get editor_effectSepia => '復古棕褐';

  @override
  String get editor_effectDenoise => '降噪';

  @override
  String get editor_effectBlur => '高斯模糊';

  @override
  String get editor_effectSharpen => '銳化';

  @override
  String get editor_effectCropToSelection => '裁切到選區';

  @override
  String get editor_effectRotateLeft => '向左旋轉 90°';

  @override
  String get editor_effectRotateRight => '向右旋轉 90°';

  @override
  String get editor_effectFlipHorizontal => '水平翻轉';

  @override
  String get editor_effectFlipVertical => '垂直翻轉';

  @override
  String editor_effectApplied(Object effect) {
    return '已應用 $effect';
  }

  @override
  String editor_applyEffectFailed(Object error) {
    return '應用效果失敗: $error';
  }

  @override
  String get editor_changeCanvasSize => '更改畫布尺寸';

  @override
  String editor_canvasTooSmall(Object width, Object height) {
    return '畫布尺寸太小，最小尺寸為 $width x $height 像素';
  }

  @override
  String editor_canvasTooLarge(Object width, Object height) {
    return '畫布尺寸太大，最大尺寸為 $width x $height 像素';
  }

  @override
  String editor_canvasResized(Object width, Object height) {
    return '畫布已調整為 $width x $height';
  }

  @override
  String editor_canvasResizeFailed(Object error) {
    return '調整畫布尺寸失敗: $error';
  }

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
  String get editor_clickInsideClosedRegion => '請點選封閉區域內部進行填充。';

  @override
  String get editor_drawClosedMaskOutlineFirst => '請先繪製封閉的遮罩輪廓。';

  @override
  String get editor_noClosedRegionAtPosition => '該位置沒有可填充的封閉區域。';

  @override
  String get editor_generateMaskOverlayFailed => '無法生成遮罩覆蓋層';

  @override
  String get editor_maskLayerName => '遮罩';

  @override
  String get editor_updateMaskLayerFailed => '無法更新遮罩圖層';

  @override
  String get editor_closedRegionFilled => '封閉區域已填充為遮罩。';

  @override
  String editor_fillMaskFailed(Object error) {
    return '填充遮罩失敗: $error';
  }

  @override
  String get editor_magicWandNoSource => '沒有可供魔棒取樣的影像圖層。';

  @override
  String get editor_magicWandNothingChanged => '選中的區域已經透明或已在遮罩中。';

  @override
  String get editor_magicWandModelPreparing => '正在檢查 EfficientViT-SAM 模型…';

  @override
  String editor_magicWandModelDownloading(int percent) {
    return '正在下載 EfficientViT-SAM 模型：$percent%';
  }

  @override
  String get editor_magicWandModelLoading => '正在載入 EfficientViT-SAM 模型…';

  @override
  String get editor_magicWandEncoding => '正在分析影像物件…';

  @override
  String get editor_magicWandSegmenting => '正在根據點選位置分割物件…';

  @override
  String get editor_magicWandPostprocessing => '正在生成選區…';

  @override
  String editor_magicWandFailed(Object error) {
    return '魔棒處理失敗: $error';
  }

  @override
  String get editor_compressionTitle => '輸出解析度';

  @override
  String get editor_compressionTooltip => '選擇輸出解析度';

  @override
  String get editor_compressionUncompressed => '保持編輯工作尺寸，不執行壓縮。';

  @override
  String get editor_compressionApplyOnDone =>
      '工作畫布保持原樣；點選“完成”時使用 Pica Lanczos3 執行一次壓縮。';

  @override
  String editor_compressionSizeSummary(
    int workWidth,
    int workHeight,
    int targetWidth,
    int targetHeight,
  ) {
    return '工作尺寸 $workWidth×$workHeight → 輸出尺寸 $targetWidth×$targetHeight';
  }

  @override
  String editor_compressionNormalSummary(
    int normalWidth,
    int normalHeight,
    int minimumWidth,
    int minimumHeight,
  ) {
    return 'Normal（約 1MP）為 $normalWidth×$normalHeight；最低檔為 $minimumWidth×$minimumHeight。';
  }

  @override
  String get editor_compressionUnavailable => '當前工作畫布已經低於最低壓縮檔，不能繼續降低解析度。';

  @override
  String editor_unsupportedImageFormat(Object extension) {
    return '不支援的檔案格式: .$extension\n請選擇影像檔案（PNG、JPG、WEBP 等）';
  }

  @override
  String editor_readFileFailed(Object error) {
    return '無法讀取檔案: $error';
  }

  @override
  String get editor_noFileData => '無法取得檔案資料';

  @override
  String get editor_emptyImageFile => '檔案為空，請選擇有效的影像檔案';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return '檔案過大（$sizeMB MB），請選擇小於 50MB 的影像';
  }

  @override
  String get editor_maskLayerAdded => '遮罩圖層已新增';

  @override
  String get editor_parseImageFailed => '無法解析影像檔案\n請確保檔案未損壞且格式受支援';

  @override
  String editor_loadMaskFailed(Object error) {
    return '載入遮罩時發生錯誤: $error';
  }

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
  String get editor_colorPickerHint => '點選畫布任意位置取色，鬆開後自動切回上一工具';

  @override
  String get editor_sample => '取樣';

  @override
  String get editor_samplePoint => '單點';

  @override
  String get editor_sampleArea => '區域';

  @override
  String get editor_source => '來源';

  @override
  String get editor_sourceCurrentLayer => '當前圖層';

  @override
  String get editor_sourceAllLayers => '所有圖層';

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
  String get gallery_metaCfgScale => 'PG';

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
  String get tooltip_edit => '編輯';

  @override
  String get tooltip_copy => '複製';

  @override
  String get tooltip_delete => '刪除';

  @override
  String get tooltip_enable => '啟用';

  @override
  String get tooltip_disable => '停用';

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
  String get weight_title => '權重';

  @override
  String get weight_reset => '重設';

  @override
  String get weight_done => '完成';

  @override
  String get weight_noBrackets => '無括號';

  @override
  String get weight_editTag => '編輯標籤';

  @override
  String get weight_tagName => '標籤名稱';

  @override
  String get weight_tagNameHint => '輸入標籤名稱...';

  @override
  String tag_selected(Object count) {
    return '已選 $count';
  }

  @override
  String get tag_enable => '啟用';

  @override
  String get tag_disable => '停用';

  @override
  String get tag_delete => '刪除';

  @override
  String get tag_addTag => '新增標籤';

  @override
  String get tag_add => '新增';

  @override
  String get tag_inputHint => '輸入標籤...';

  @override
  String get tag_copiedToClipboard => '已複製到剪貼簿';

  @override
  String get tag_emptyHint => '新增標籤來描述你想要的畫面';

  @override
  String get tag_emptyHintSub => '你可以瀏覽、搜尋或手動新增標籤';

  @override
  String get tagCategory_artist => '藝術家';

  @override
  String get tagCategory_copyright => '版權';

  @override
  String get tagCategory_character => '角色';

  @override
  String get tagCategory_meta => '後設資料';

  @override
  String get tagCategory_general => '通用';

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
  String get characterEditor_promptHint => '輸入角色的正向提示詞...';

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
  String get toolbar_clear => '清空';

  @override
  String get toolbar_confirmClear => '確認清空';

  @override
  String get toolbar_settings => '設定';

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
  String download_completed(Object name) {
    return '$name下載完成';
  }

  @override
  String download_failed(Object name) {
    return '$name下載失敗';
  }

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
  String get download_tags_data => '正在下載標籤資料...';

  @override
  String get download_cooccurrence_data => '正在下載共現標籤資料...';

  @override
  String get download_parsing_data => '正在解析資料...';

  @override
  String get download_readingFile => '正在讀取檔案...';

  @override
  String get download_mergingData => '正在合併資料...';

  @override
  String get download_loadComplete => '載入完成';

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
  String get category_selectEmoji => '選擇 Emoji';

  @override
  String get category_noRecentEmoji => '暫無最近使用的 Emoji';

  @override
  String get category_searchEmoji => '搜尋 Emoji';

  @override
  String get vibeNoEncodingWarning => '此圖片沒有預編碼資料';

  @override
  String vibeWillCostAnlas(int count) {
    return '編碼將消耗 $count Anlas';
  }

  @override
  String get vibeEncodeConfirm => '是否繼續新增並消耗點數？';

  @override
  String get vibeCancel => '取消';

  @override
  String get vibeConfirmEncode => '確認編碼';

  @override
  String get vibeParseFailed => '無法解析 Vibe 檔案';

  @override
  String get tagGroupBrowser_searchHint => '搜尋標籤...';

  @override
  String tagGroupBrowser_tagCount(Object count) {
    return '$count個標籤';
  }

  @override
  String tagGroupBrowser_filteredTagCount(Object filtered, Object total) {
    return '顯示 $filtered 個，共 $total 個標籤';
  }

  @override
  String get tagGroupBrowser_noTags => '暫無標籤';

  @override
  String get tagGroupBrowser_noLibrary => '詞庫未載入';

  @override
  String get tagGroupBrowser_importLibraryHint => '請先匯入標籤詞庫';

  @override
  String get tagGroupBrowser_noCategories => '沒有啟用的標籤分類';

  @override
  String get tagGroupBrowser_enableCategoriesHint => '請在設定中啟用標籤分類';

  @override
  String get tagGroupBrowser_danbooruSuggestions => 'Danbooru 建議';

  @override
  String get tag_favoritesTitle => '收藏標籤';

  @override
  String get tag_favoritesEmpty => '暫無收藏標籤';

  @override
  String get tag_favoritesEmptyHint => '長按標籤即可新增到收藏';

  @override
  String get tag_alreadyAdded => '該標籤已在當前提示詞中';

  @override
  String get tag_removeFavoriteTitle => '移除收藏';

  @override
  String tag_removeFavoriteMessage(Object tag) {
    return '確定要移除收藏的標籤「$tag」嗎？';
  }

  @override
  String get tag_templatesTitle => '標籤範本';

  @override
  String get tag_templatesEmpty => '暫無標籤範本';

  @override
  String get tag_templatesEmptyHint => '選擇標籤後點擊右上角的 + 按鈕建立範本';

  @override
  String get tag_templateCreate => '建立範本';

  @override
  String get tag_templateNameLabel => '範本名稱';

  @override
  String get tag_templateNameHint => '輸入範本名稱';

  @override
  String get tag_templateNameRequired => '請輸入範本名稱';

  @override
  String get tag_templateDescLabel => '範本描述（可選）';

  @override
  String get tag_templateDescHint => '輸入範本描述';

  @override
  String get tag_templatePreview => '標籤預覽';

  @override
  String tag_templateTagCount(Object count) {
    return '$count 個標籤';
  }

  @override
  String tag_templateMoreTags(Object count) {
    return '還有 $count 個標籤...';
  }

  @override
  String tag_templateInserted(Object name) {
    return '已插入範本「$name」';
  }

  @override
  String get tag_templateNoTags => '沒有可儲存的標籤';

  @override
  String get tag_templateSaved => '範本已儲存';

  @override
  String get tag_templateNameExists => '範本名稱已存在';

  @override
  String get tag_templateDeleteTitle => '刪除範本';

  @override
  String tag_templateDeleteMessage(Object name) {
    return '確定要刪除範本「$name」嗎？';
  }

  @override
  String get tag_categoryGeneral => '通用';

  @override
  String get tag_categoryArtist => '畫師';

  @override
  String get tag_categoryCopyright => '版權';

  @override
  String get tag_categoryCharacter => '角色';

  @override
  String get tag_categoryMeta => '後設資料';

  @override
  String get tag_countBadgeBreakdown => '標籤分類統計';

  @override
  String get localGallery_progressiveLoadError => '圖片載入失敗';

  @override
  String get localGallery_noImagesFound => '未找到圖片';

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
  String get localGallery_loadingGroupedImages => '載入分組圖片中...';

  @override
  String get localGallery_title => '本地畫廊';

  @override
  String get localGallery_allImages => '全部圖片';

  @override
  String get localGallery_categoryPanelTitle => '分類';

  @override
  String get localGallery_selectCurrentPage => '選擇本頁';

  @override
  String get localGallery_deselectCurrentPage => '取消本頁';

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
  String get localGallery_sortToggleDirection => '切換排序方向';

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
  String get localGallery_naiOnly => 'NAI';

  @override
  String get localGallery_naiOnlyTooltip => '僅顯示 NAI 生成的圖片';

  @override
  String get localGallery_naiVersionFilterLabel => 'Ver';

  @override
  String get localGallery_naiVersionFilterTooltip => '按 NAI 模型版本過濾';

  @override
  String get localGallery_masonryViewLabel => '瀑布流';

  @override
  String get localGallery_switchToMasonryView => '切換到瀑布流檢視';

  @override
  String get localGallery_switchToGridLayout => '切換到網格檢視';

  @override
  String get localGallery_justifiedViewLabel => '火車流';

  @override
  String get localGallery_switchToJustifiedView => '切換到火車流檢視';

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
  String get localGallery_openFilterPanel => '開啟篩選面板';

  @override
  String get localGallery_hideCategoryPanel => '隱藏分類面板';

  @override
  String get localGallery_showCategoryPanel => '顯示分類面板';

  @override
  String get localGallery_enterSelectionMode => '進入選擇模式';

  @override
  String get localGallery_refreshTooltip => '重新整理畫廊\n\n自動檢測新增/修改的圖片並更新索引';

  @override
  String get localGallery_tagIntersection => '標籤交集';

  @override
  String get localGallery_filterByTags => '按標籤篩選';

  @override
  String get localGallery_tagInputHint => '輸入標籤，回車新增';

  @override
  String get localGallery_addTag => '新增';

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
  String get localGallery_folderName => '資料夾名稱';

  @override
  String get localGallery_newFolderName => '新名稱';

  @override
  String get localGallery_folderNameHint => '輸入資料夾名稱';

  @override
  String get localGallery_folderCreated => '資料夾建立成功';

  @override
  String get localGallery_folderCreateFailed => '資料夾建立失敗';

  @override
  String get localGallery_renameFolderTitle => '重新命名資料夾';

  @override
  String get localGallery_renameSuccess => '重新命名成功';

  @override
  String get localGallery_renameFailed => '重新命名失敗';

  @override
  String get localGallery_deleteFolderTitle => '刪除資料夾';

  @override
  String localGallery_deleteFolderWithImagesContent(Object name, Object count) {
    return '資料夾「$name」包含 $count 張圖片，確定要刪除嗎？\n\n注意：此操作會刪除資料夾及其中的所有圖片，無法恢復。';
  }

  @override
  String localGallery_deleteEmptyFolderContent(Object name) {
    return '確定要刪除空資料夾「$name」嗎？';
  }

  @override
  String get localGallery_folderDeleted => '資料夾已刪除';

  @override
  String get localGallery_folderDeleteFailed => '刪除資料夾失敗';

  @override
  String get localGallery_withMetadata => '有後設資料';

  @override
  String get localGallery_skipped => '跳過';

  @override
  String get localGallery_cacheMonitor => '快取監控';

  @override
  String get localGallery_threeLayerCacheStats => '三層快取統計';

  @override
  String localGallery_updatedAt(Object time) {
    return '更新: $time';
  }

  @override
  String get localGallery_memoryCache => '記憶體快取';

  @override
  String get localGallery_hiveCache => 'Hive 快取';

  @override
  String get localGallery_sqliteDatabase => 'SQLite 資料庫';

  @override
  String get localGallery_imageUnit => '圖片';

  @override
  String get localGallery_metadataUnit => '後設資料';

  @override
  String get localGallery_entriesUnit => '條目';

  @override
  String get localGallery_hitRate => '命中率';

  @override
  String get localGallery_performanceStats => '效能監控統計';

  @override
  String get localGallery_cacheHit => '命中';

  @override
  String get localGallery_cacheMiss => '未命中';

  @override
  String get localGallery_clearL1 => '清除 L1';

  @override
  String get localGallery_clearL2 => '清除 L2';

  @override
  String get localGallery_clearAll => '清除全部';

  @override
  String get localGallery_resetStats => '重設統計';

  @override
  String get localGallery_confirmClearCache => '確認清除';

  @override
  String get localGallery_confirmClearCacheContent => '確定要清除所有快取嗎？這將重新掃描所有圖片。';

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
  String get statistics_noData => '暫無統計資料';

  @override
  String get statistics_generatedCount => '生成數量';

  @override
  String get statistics_favoriteCount => '收藏數';

  @override
  String statistics_tooltipGenerated(Object count) {
    return '生成數量: $count';
  }

  @override
  String statistics_tooltipFavorite(Object count) {
    return '收藏數: $count';
  }

  @override
  String get statistics_noTagData => '暫無標籤資料';

  @override
  String get statistics_generateFirst => '先生成一些圖片吧';

  @override
  String get statistics_totalImages => '總圖片數';

  @override
  String get statistics_totalSize => '總大小';

  @override
  String get statistics_favorites => '收藏';

  @override
  String get statistics_samplerDistribution => '取樣器分佈';

  @override
  String get statistics_additionalStats => '其他統計';

  @override
  String get statistics_averageFileSize => '平均檔案大小';

  @override
  String get statistics_withMetadata => '有後設資料的圖片';

  @override
  String get statistics_justNow => '剛剛';

  @override
  String statistics_minutesAgo(Object count) {
    return '$count 分鐘前';
  }

  @override
  String statistics_hoursAgo(Object count) {
    return '$count 小時前';
  }

  @override
  String statistics_daysAgo(Object count) {
    return '$count 天前';
  }

  @override
  String get statistics_anlasCost => '點數消耗';

  @override
  String get statistics_totalAnlasCost => '總消耗';

  @override
  String get statistics_avgDailyCost => '日均消耗';

  @override
  String get statistics_noAnlasData => '暫無點數消耗資料';

  @override
  String get statistics_peakActivity => '活躍高峰';

  @override
  String get statistics_timeMorning => '上午';

  @override
  String get statistics_timeAfternoon => '下午';

  @override
  String get statistics_timeEvening => '傍晚';

  @override
  String get statistics_timeNight => '深夜';

  @override
  String get localGallery_advancedFilters => '進階篩選';

  @override
  String get localGallery_filterByModel => '按模型篩選';

  @override
  String get localGallery_filterBySampler => '按取樣器篩選';

  @override
  String get localGallery_filterBySteps => '按步數篩選';

  @override
  String get localGallery_filterByCfg => '按 PG 篩選';

  @override
  String get localGallery_filterByResolution => '按解析度篩選';

  @override
  String get localGallery_filterSubtitle => '精確篩選您的圖片集合';

  @override
  String get localGallery_filterOrientation => '畫面方向';

  @override
  String get localGallery_orientationAny => '全部';

  @override
  String get localGallery_orientationLandscape => '橫版';

  @override
  String get localGallery_orientationPortrait => '豎版';

  @override
  String get localGallery_orientationSquare => '方圖';

  @override
  String get localGallery_filterNsfw => '內容分級';

  @override
  String get localGallery_nsfwAny => '全部';

  @override
  String get localGallery_nsfwSfw => '全年齡';

  @override
  String get localGallery_nsfwOnly => '僅 NSFW';

  @override
  String get localGallery_noModelCandidates => '暫無模型後設資料，匯入標籤索引或掃描後可用';

  @override
  String get localGallery_noSamplerCandidates => '暫無取樣器後設資料，匯入標籤索引或掃描後可用';

  @override
  String get localGallery_noResolutionCandidates => '暫無解析度後設資料';

  @override
  String get localGallery_candidatesLoadFailed => '候選載入失敗';

  @override
  String get localGallery_noTagSuggestions => '無匹配標籤';

  @override
  String get localGallery_activeFiltersSet => '已設定篩選';

  @override
  String get localGallery_applyFilters => '應用篩選';

  @override
  String get localGallery_resetAdvancedFilters => '重設進階篩選';

  @override
  String get localGallery_exportFailed => '匯出失敗';

  @override
  String get bulkExport_format => '匯出格式';

  @override
  String get bulkExport_jsonFormat => 'JSON';

  @override
  String get bulkExport_csvFormat => 'CSV';

  @override
  String get bulkExport_includeMetadataHint => '匯出生成參數等資訊';

  @override
  String get localGallery_group_today => '今天';

  @override
  String get localGallery_group_yesterday => '昨天';

  @override
  String get localGallery_group_thisWeek => '本週';

  @override
  String get localGallery_group_earlier => '更早';

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
  String get statistics_chartAspectRatio => '寬高比分佈';

  @override
  String get statistics_chartActivityHeatmap => '活動熱力圖';

  @override
  String get statistics_chartHourlyDistribution => '小時分佈';

  @override
  String get statistics_chartWeekdayDistribution => '星期分佈';

  @override
  String get statistics_aspectSquare => '方形';

  @override
  String get statistics_aspectLandscape => '橫屏';

  @override
  String get statistics_aspectPortrait => '豎屏';

  @override
  String get statistics_aspectOther => '其他';

  @override
  String get statistics_refresh => '重新整理';

  @override
  String get statistics_retry => '重試';

  @override
  String statistics_error(Object error) {
    return '錯誤: $error';
  }

  @override
  String get statistics_mostActiveDay => '最活躍日';

  @override
  String get statistics_leastActiveDay => '最不活躍日';

  @override
  String get statistics_sunday => '週日';

  @override
  String get statistics_monday => '週一';

  @override
  String get statistics_tuesday => '週二';

  @override
  String get statistics_wednesday => '週三';

  @override
  String get statistics_thursday => '週四';

  @override
  String get statistics_friday => '週五';

  @override
  String get statistics_saturday => '週六';

  @override
  String get fixedTags_negativeTitle => '負向固定詞';

  @override
  String autocomplete_resultsCount(Object count) {
    return '$count 個結果';
  }

  @override
  String get autocomplete_actionSelect => '選擇';

  @override
  String get autocomplete_actionConfirm => '確認';

  @override
  String get autocomplete_actionClose => '關閉';

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
  String get common_create => '建立';

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
  String get statistics_heatmapLess => '少';

  @override
  String get statistics_heatmapMore => '多';

  @override
  String statistics_heatmapActivities(Object count) {
    return '$count 次活動';
  }

  @override
  String get statistics_heatmapNoActivity => '無活動';

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
  String get metadataImport_fixedTags => '固定詞';

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
  String get metadataImport_scale => 'PG';

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
  String get metadataImport_cfgRescale => 'PGR';

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
  String get shortcut_action_previous_page => '上一頁';

  @override
  String get shortcut_action_next_page => '下一頁';

  @override
  String get shortcut_action_refresh_gallery => '重新整理';

  @override
  String get shortcut_action_focus_search => '搜尋聚焦';

  @override
  String get shortcut_action_enter_selection_mode => '進入選擇模式';

  @override
  String get shortcut_action_open_filter_panel => '開啟篩選面板';

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
  String get shortcut_help_tip => '提示：按 F1 或 ? 鍵可隨時開啟此幫助對話方塊';

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
  String get drop_dialogTitle => '如何使用這張圖片？';

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
  String get drop_extractMetadata => '提取後設資料';

  @override
  String get drop_extractMetadataSubtitle => '讀取圖片中的 Prompt、Seed 等參數';

  @override
  String get drop_vibeDetected => '檢測到預編碼 Vibe（可節省 2 Anlas）';

  @override
  String drop_vibeStrength(Object value) {
    return '強度: $value%';
  }

  @override
  String drop_vibeInfoExtracted(Object value) {
    return '資訊提取: $value%';
  }

  @override
  String get drop_reuseVibe => '複用 Vibe';

  @override
  String get drop_reuseVibeSubtitle => '直接使用預編碼資料（免費）';

  @override
  String get drop_useAsRawImage => '作為原始圖片';

  @override
  String get drop_useAsRawImageSubtitle => '重新編碼（消耗 2 Anlas）';

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
  String get vibeLibrary_hideCategoryPanel => '隱藏分類面板';

  @override
  String get vibeLibrary_showCategoryPanel => '顯示分類面板';

  @override
  String get vibeLibrary_enterSelectionMode => '進入選擇模式';

  @override
  String get vibeLibrary_importTooltip =>
      '匯入 Vibe 檔案或 PNG/JPG/JPEG/WEBP 圖片（右鍵檢視更多選項）';

  @override
  String get vibeLibrary_exportTooltip => '匯出 Vibe 到檔案';

  @override
  String get vibeLibrary_openFolderTooltip => '開啟 Vibe 庫資料夾';

  @override
  String get vibeLibrary_refresh => '重新整理';

  @override
  String get vibeLibrary_loading => '載入中...';

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
  String get vibeBulk_titleDelete => '批次刪除';

  @override
  String get vibeBulk_titleMove => '批次移動';

  @override
  String get vibeBulk_titleToggleFavorite => '批次更新收藏';

  @override
  String get vibeBulk_titleAddTags => '批次新增標籤';

  @override
  String get vibeBulk_titleRemoveTags => '批次移除標籤';

  @override
  String get vibeBulk_titleExport => '批次匯出';

  @override
  String get vibeBulk_titleImport => '批次匯入';

  @override
  String vibeBulk_processingProgress(int current, int total) {
    return '正在處理：$current / $total';
  }

  @override
  String get vibeBulk_completed => '操作完成';

  @override
  String get vibeBulk_completedWithFailures => '操作完成（部分失敗）';

  @override
  String get vibeBulk_successful => '成功';

  @override
  String get vibeBulk_failed => '失敗';

  @override
  String get vibeBulk_errorDetails => '錯誤詳情：';

  @override
  String vibeBulk_moreErrors(int count) {
    return '……另有 $count 個錯誤';
  }

  @override
  String get vibeBulk_operationFailed => '操作失敗';

  @override
  String get vibeBulk_operationFailedHint => '請檢查操作設定後重試。';

  @override
  String vibeBulk_errorEntryNotFoundOrDeleteFailed(String item) {
    return '未找到 $item 或刪除失敗';
  }

  @override
  String vibeBulk_errorDeleteFailed(String item, String error) {
    return '刪除 $item 失敗：$error';
  }

  @override
  String vibeBulk_errorEntryNotFound(String item) {
    return '未找到條目：$item';
  }

  @override
  String vibeBulk_errorMoveFailed(String item, String error) {
    return '移動 $item 失敗：$error';
  }

  @override
  String vibeBulk_errorFavoriteFailed(String item) {
    return '更新收藏狀態失敗：$item';
  }

  @override
  String vibeBulk_errorFavoriteFailedWithDetails(String item, String error) {
    return '更新 $item 的收藏狀態失敗：$error';
  }

  @override
  String vibeBulk_errorAddTagsFailed(String item) {
    return '新增標籤失敗：$item';
  }

  @override
  String vibeBulk_errorAddTagsFailedWithDetails(String item, String error) {
    return '為 $item 新增標籤失敗：$error';
  }

  @override
  String vibeBulk_errorRemoveTagsFailed(String item) {
    return '移除標籤失敗：$item';
  }

  @override
  String vibeBulk_errorRemoveTagsFailedWithDetails(String item, String error) {
    return '從 $item 移除標籤失敗：$error';
  }

  @override
  String get vibeBulk_errorExportNoFile => '匯出失敗：未建立檔案';

  @override
  String vibeBulk_errorExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String vibeBulk_errorFileNotFound(String item) {
    return '未找到檔案：$item';
  }

  @override
  String vibeBulk_errorNoVibeData(String item) {
    return '$item 中沒有有效的 Vibe 資料';
  }

  @override
  String vibeBulk_errorImportFailed(String item, String error) {
    return '從 $item 匯入 Vibe 失敗：$error';
  }

  @override
  String vibeBulk_errorProcessFileFailed(String item, String error) {
    return '處理 $item 失敗：$error';
  }

  @override
  String get vibeBulkTag_title => '批次編輯標籤';

  @override
  String vibeBulkTag_selectedCount(int count) {
    return '已選中 $count 個 Vibe';
  }

  @override
  String get vibeBulkTag_inputHint => '輸入新標籤……';

  @override
  String get vibeBulkTag_noTags => '暫無標籤';

  @override
  String get vibeBulkTag_noTagsHint => '新增標籤以方便篩選和管理';

  @override
  String vibeBulkTag_currentTags(int count) {
    return '當前標籤（$count）';
  }

  @override
  String vibeBulkTag_pendingRemoval(int count) {
    return '待移除標籤（$count）';
  }

  @override
  String get vibeBulkTag_removeTag => '移除標籤';

  @override
  String get vibeBulkTag_actionPreview => '操作預覽';

  @override
  String vibeBulkTag_addTagsSummary(String tags) {
    return '新增標籤：$tags';
  }

  @override
  String vibeBulkTag_removeTagsSummary(String tags) {
    return '移除標籤：$tags';
  }

  @override
  String get vibeBulkTag_noChanges => '沒有要應用的更改';

  @override
  String get vibeBulkCategory_title => '選擇目標分類';

  @override
  String vibeBulkCategory_moveCount(int count) {
    return '將 $count 個 Vibe 移動到：';
  }

  @override
  String get vibeBulkCategory_cannotMoveToCurrent => '不能移動到當前所在分類';

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
  String vibe_import_failedWithError(String error) {
    return '匯入失敗: $error';
  }

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
  String get vibe_maxReachedRemoveSome => '已達到最大數量 (16張)，請先移除一些 Vibe';

  @override
  String vibe_addedNamed(String name) {
    return '已新增 Vibe: $name';
  }

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
  String get settings_kritaBridgeEnable => '啟用 Krita 本地橋接';

  @override
  String get settings_kritaBridgeDisabledText => '預設關閉；開啟後只監聽本機 127.0.0.1';

  @override
  String get settings_kritaBridgeStartingText => '正在啟動本地橋接服務...';

  @override
  String get settings_kritaBridgeListeningText => '等待 Krita 外掛連線';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita 外掛已連線';

  @override
  String get settings_kritaBridgeErrorText => '啟動失敗，請檢視錯誤資訊';

  @override
  String get settings_kritaBridgeDisabled => '已關閉';

  @override
  String get settings_kritaBridgeStarting => '啟動中';

  @override
  String get settings_kritaBridgeListening => '監聽中';

  @override
  String get settings_kritaBridgeConnected => '已連線';

  @override
  String get settings_kritaBridgeError => '錯誤';

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
  String get settings_highAnlasCostTitle => '保護模式：Anlas 消耗較高';

  @override
  String settings_highAnlasCostContent(Object cost, Object threshold) {
    return '本次預計消耗 $cost Anlas，已達到或超過你設定的 $threshold Anlas 警告閾值。請確認是否繼續生成。';
  }

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
  String get settings_comfyUiWorkflowManagement => '工作流管理';

  @override
  String get settings_comfyUiBuiltinWorkflows => '內建工作流';

  @override
  String get settings_comfyUiCustomWorkflows => '自訂工作流';

  @override
  String get settings_comfyUiNoCustomWorkflows =>
      '暫無自訂工作流，點選“匯入”新增 ComfyUI 工作流';

  @override
  String settings_comfyUiSlotCount(Object count) {
    return '$count 個槽位';
  }

  @override
  String get settings_comfyUiBuiltin => '內建';

  @override
  String get settings_comfyUiDeleteWorkflowTitle => '刪除工作流';

  @override
  String settings_comfyUiDeleteWorkflowContent(Object name) {
    return '確定要刪除工作流“$name”嗎？此操作不可復原。';
  }

  @override
  String settings_comfyUiDeleted(Object name) {
    return '已刪除: $name';
  }

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
  String get toast_tagCopied => '標籤已複製';

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
  String get pagination_firstPage => '首頁';

  @override
  String get pagination_previousPage => '上一頁';

  @override
  String get pagination_nextPage => '下一頁';

  @override
  String get pagination_lastPage => '末頁';

  @override
  String get pagination_jumpToPage => '跳轉到頁面';

  @override
  String get pagination_jump => '跳轉';

  @override
  String get pagination_itemsPerPage => '每頁';

  @override
  String get pagination_itemUnit => '項';

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
  String get model3d_addMannequin => '新增內建人偶';

  @override
  String get model3d_importModel => '匯入模型 (.glb/.gltf)';

  @override
  String get model3d_emptyHint => '場景為空，先新增人偶或匯入模型';

  @override
  String get model3d_apply => '應用到圖層';

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
  String get model3d_undo => '復原';

  @override
  String get model3d_resetPose => '重設姿勢';

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
  String get model3d_lightIntensity => '強度';

  @override
  String get model3d_lightAzimuth => '方位角';

  @override
  String get model3d_lightElevation => '仰角';

  @override
  String get model3d_addLayerTooltip => '新增 3D 模型圖層';

  @override
  String get model3d_webview2Missing =>
      '3D 編輯器需要 Microsoft Edge WebView2 執行時。Windows 10/11 通常已自帶;若缺失請從微軟官網安裝 Evergreen 版本後重試。';

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
  String get preciseRefLib_deleteEntry => '刪除';

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
  String get common_previewLoadFailed => '無法載入預覽';

  @override
  String get common_clickToRefresh => '點選重新整理';

  @override
  String get common_clickToRetry => '點選重試';

  @override
  String get common_opening => '正在開啟...';

  @override
  String get common_swap => '交換';

  @override
  String get common_minimum => '最小值';

  @override
  String get common_maximum => '最大值';

  @override
  String get addToLibrary_displayNameHint => '輸入便於識別此條目的名稱';

  @override
  String get addToLibrary_tagHint => '輸入標籤並按 Enter 新增';

  @override
  String get drop_saveVibeBundle => '儲存 Vibe Bundle';

  @override
  String drop_saveVibeBundleSubtitle(String name) {
    return '將 $name 等 Vibe 儲存到庫中';
  }

  @override
  String get drop_saveEncodedVibeSubtitle => '將預編碼 Vibe 資料儲存到庫中';

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
  String get localGallery_createFolder => '建立資料夾';

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
  String get editor_effects => '效果';

  @override
  String get editor_shiftEdges => '擴展邊緣';

  @override
  String editor_currentSize(int width, int height) {
    return '當前: $width x $height';
  }

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
  String get editor_nonNegativeNumber => '必須大於或等於 0';

  @override
  String editor_requestedSize(int width, int height) {
    return '請求尺寸: $width x $height';
  }

  @override
  String get editor_requestedSizeInvalid => '請求尺寸: 無效';

  @override
  String editor_appliedSize(int width, int height) {
    return '應用尺寸: $width x $height';
  }

  @override
  String get editor_appliedSizeInvalid => '應用尺寸: 無效';

  @override
  String editor_appliedEdges(int left, int top, int right, int bottom) {
    return '應用邊緣: 左 $left、上 $top、右 $right、下 $bottom';
  }

  @override
  String get editor_appliedEdgesInvalid => '應用邊緣: 無效';

  @override
  String editor_appliedDimensionLimit(int max) {
    return '應用後的尺寸不能超過 $max。';
  }

  @override
  String get onlineGallery_videoLoadFailed => '影片載入失敗';

  @override
  String get vibe_releaseToAddStyleReference => '鬆開後新增風格參考';

  @override
  String router_pageNotFound(String error) {
    return '頁面未找到: $error';
  }

  @override
  String get autocomplete_translating => '翻譯中…';

  @override
  String get autocomplete_missingTranslation => '未漢化';

  @override
  String autocomplete_aliasMatch(String alias) {
    return '別名：$alias';
  }

  @override
  String get autocomplete_resultLimit => '結果數量';

  @override
  String get autocomplete_relatedTagsTitle => '標籤擴展';

  @override
  String get autocomplete_relatedTagsSubtitle => 'Ctrl+單擊搜尋本地標籤；Ctrl+拖選檢視關聯標籤';

  @override
  String get tagExpansion_searchHint => '搜尋標籤、別名或漢化名';

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
  String get autocomplete_danbooruPrivacy => '僅傳送當前英文標籤，不會上傳完整提示詞';

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
  String get autocomplete_sourceBase => '隨應用提供的基礎詞庫';

  @override
  String get autocomplete_sourceApi => 'Danbooru API';

  @override
  String get autocomplete_sourceRelated => '離線相關標籤';

  @override
  String get autocomplete_sourceAi => 'Prompt Assistant 漢化';

  @override
  String get autocomplete_headerTitle => '標籤補全';

  @override
  String get autocomplete_relatedHeaderTitle => '相關標籤';

  @override
  String get autocomplete_relatedLoading => '正在查詢本地共現庫與線上相關標籤…';

  @override
  String get autocomplete_relatedEmpty => '沒有找到可用的相關標籤';

  @override
  String autocomplete_relatedMetric(int count, String score) {
    return '共現 $count 次 · Jaccard $score';
  }

  @override
  String get autocomplete_relatedPin => '固定當前標籤，可連續插入相關標籤';

  @override
  String get autocomplete_relatedUnpin => '取消固定並繼續鏈式推薦';

  @override
  String get autocomplete_statusBase => '本地';

  @override
  String get autocomplete_statusRelated => '共現';

  @override
  String get autocomplete_statusOnline => '線上';

  @override
  String get autocomplete_statusAi => 'AI';

  @override
  String get autocomplete_statusReady => '就緒';

  @override
  String get autocomplete_statusError => '異常';

  @override
  String get autocomplete_statusDisabled => '已關閉';

  @override
  String get autocomplete_statusSearching => '查詢中';

  @override
  String get autocomplete_statusTranslating => '翻譯中';

  @override
  String get autocomplete_openSettings => '開啟補全與資料來源設定';

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
      '請檢查設定：步數 1–50、PG 1–20、PGR 0–1，並確認參數受所選模型支援。';

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
  String get styleExplore_previewEmpty => '（空）';

  @override
  String get styleExplore_copiedToClipboard => '已複製';

  @override
  String get styleExplore_runSectionTitle => '探索任務';

  @override
  String get styleExplore_runEmptyHint => '探索任務（Run）固化提示詞與參數快照，批次生成候選並篩選。';

  @override
  String get styleExplore_newRun => '新增任務';

  @override
  String get styleExplore_galleryTitle => '候選畫廊';

  @override
  String get styleExplore_galleryEmptyHint => '暫無候選。新增或選擇一個探索任務，開始批次生成。';

  @override
  String get styleExplore_labTip => '選擇喜歡的候選，讓畫風逐代進化。';

  @override
  String get styleExplore_runNameLabel => '任務名稱';

  @override
  String get styleExplore_runNameHint => '例如：柔光畫風 ×30';

  @override
  String styleExplore_runCreated(String name) {
    return '已建立任務「$name」';
  }

  @override
  String styleExplore_runDeleted(String name) {
    return '已刪除任務「$name」';
  }

  @override
  String styleExplore_runTotalCount(int total) {
    return '共 $total 張';
  }

  @override
  String styleExplore_runGeneratingProgress(int current, int total) {
    return '第 $current/$total 張';
  }

  @override
  String get styleExplore_runStatusDraft => '草稿';

  @override
  String get styleExplore_runStatusGenerating => '生成中';

  @override
  String get styleExplore_runStatusPaused => '已暫停';

  @override
  String get styleExplore_runStatusGenerated => '已生成';

  @override
  String get styleExplore_runStatusCompleted => '已完成';

  @override
  String get styleExplore_runStatusCancelled => '已取消';

  @override
  String get styleExplore_pauseRun => '暫停';

  @override
  String get styleExplore_cancelRun => '取消任務';

  @override
  String styleExplore_retryFailed(int count) {
    return '重試失敗（$count）';
  }

  @override
  String get styleExplore_targetCountLabel => '出圖數';

  @override
  String styleExplore_manualRunName(String time) {
    return '手動候選 $time';
  }

  @override
  String get styleExplore_runBusy => '生成進行中，稍後再試';

  @override
  String get styleExplore_deleteRunTitle => '刪除探索任務';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return '將刪除「$name」及其候選圖副本；圖庫中的來源圖不受影響。';
  }

  @override
  String get styleExplore_cancelRunTitle => '取消探索任務';

  @override
  String get styleExplore_cancelRunMessage => '取消後不可再啟動；剩餘待生成候選將標記為已取消。';

  @override
  String get styleExplore_filterAll => '全部';

  @override
  String get styleExplore_filterHearted => '收藏';

  @override
  String get styleExplore_newFolder => '新增資料夾';

  @override
  String get styleExplore_renameFolder => '重新命名資料夾';

  @override
  String get styleExplore_deleteFolder => '刪除資料夾';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return '將刪除資料夾「$name」；其中的候選回到未分類，圖片不會被刪除。';
  }

  @override
  String get styleExplore_folderNameLabel => '資料夾名稱';

  @override
  String get styleExplore_deleteFamily => '刪除譜系';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return '將刪除譜系「$name」及其全部父本集與候選記錄（$count 張）；候選圖片檔案不會刪除。';
  }

  @override
  String get styleExplore_familyBusy => '譜系內還有生成中的候選，請先取消任務';

  @override
  String get styleExplore_folderUncategorized => '未分類';

  @override
  String styleExplore_folderCreated(String name) {
    return '已建立資料夾「$name」';
  }

  @override
  String get styleExplore_assignToFolder => '歸類到';

  @override
  String get styleExplore_candidateMissing => '圖片檔案缺失';

  @override
  String get styleExplore_candidateDetailTitle => '候選詳情';

  @override
  String styleExplore_candidatePosition(int current, int total) {
    return '第 $current/$total 張';
  }

  @override
  String get styleExplore_prevCandidate => '上一張';

  @override
  String get styleExplore_nextCandidate => '下一張';

  @override
  String get styleExplore_rollSnapshot => 'Roll 快照';

  @override
  String styleExplore_seedLabel(String seed) {
    return 'Seed $seed';
  }

  @override
  String styleExplore_roundNumber(int number) {
    return '第 $number 輪';
  }

  @override
  String get styleExplore_adoptAsBlock => '收編為塊';

  @override
  String get styleExplore_adoptBlockNameLabel => '塊名稱';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '已收編為塊「$name」';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '所選候選沒有可用的 Roll 串';

  @override
  String get styleExplore_fixateAsTemplate => '匯入後設資料';

  @override
  String get styleExplore_fixateDone => '已匯入後設資料到編輯區';

  @override
  String get styleExplore_deleteImage => '刪除圖片';

  @override
  String get styleExplore_deleteImageTitle => '刪除候選圖';

  @override
  String get styleExplore_deleteImageMessage =>
      '將刪除該候選在 Run 目錄中的圖片副本與候選記錄；圖庫來源圖不受影響。';

  @override
  String get styleExplore_deleteImageDone => '已刪除候選圖與記錄';

  @override
  String get styleExplore_selectCandidates => '多選';

  @override
  String styleExplore_selectedCount(int count) {
    return '已選 $count 張';
  }

  @override
  String get styleExplore_mergeAdopt => '合併收編';

  @override
  String get styleExplore_noRunsYet => '還沒有探索任務';

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
  String get styleExplore_lineageTitle => '譜系';

  @override
  String get styleExplore_createFamily => '建家族';

  @override
  String styleExplore_familyCreated(String name) {
    return '已建立家族「$name」';
  }

  @override
  String get styleExplore_familyNameLabel => '家族名稱';

  @override
  String get styleExplore_familyNameHint => '例如：柔光主線';

  @override
  String styleExplore_familyParentsTitle(int count) {
    return '父本（$count）';
  }

  @override
  String get styleExplore_customParentLabel => '自訂父本串';

  @override
  String get styleExplore_customParentHint => '輸入一段提示詞串作為父本';

  @override
  String get styleExplore_addCustomParent => '新增自訂串';

  @override
  String get styleExplore_createFamilyEmpty => '請至少保留一個有效父本串';

  @override
  String styleExplore_parentSetTitle(int generation) {
    return '第 $generation 代父本集';
  }

  @override
  String styleExplore_candidatePileTitle(int generation, int count) {
    return '第 $generation 代候選堆 · $count 張';
  }

  @override
  String get styleExplore_parentSetActive => '活躍';

  @override
  String get styleExplore_parentSetUsed => '已回交';

  @override
  String styleExplore_branchLabel(String name) {
    return '分支：$name';
  }

  @override
  String get styleExplore_createDeepRound => '生成候選圖';

  @override
  String styleExplore_deepRoundCountHint(int min) {
    return '出圖數至少 $min（每個父本保底一張）';
  }

  @override
  String get styleExplore_deepRoundNoInstance => '主提示詞中沒有啟用的隨機遺傳塊，無法進行深度輪';

  @override
  String get styleExplore_deepRoundEmpty => '變異引擎無法產出足夠不同的子代串';

  @override
  String get styleExplore_sortParents => 'A/B 組對照';

  @override
  String get styleExplore_sortTitle => '父本A/B組對照';

  @override
  String get styleExplore_sortPrompt => '哪張圖更接近你想要的畫風效果？';

  @override
  String get styleExplore_sortLeft => '左邊好';

  @override
  String get styleExplore_sortRight => '右邊好';

  @override
  String get styleExplore_sortNeither => '都不好';

  @override
  String get styleExplore_sortSkip => '跳過';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return '第 $current/$total 對';
  }

  @override
  String get styleExplore_sortDone => '排序完成';

  @override
  String get styleExplore_branchSelect => '多選建分支';

  @override
  String get styleExplore_createBranch => '建分支';

  @override
  String get styleExplore_branchNameLabel => '分支名稱（可選）';

  @override
  String styleExplore_branchCreated(int count) {
    return '已建立分支（$count 個父本）';
  }

  @override
  String get styleExplore_branchNeedLatest => '只能從最新代候選堆建分支';

  @override
  String get styleExplore_branchRoundsIncomplete => '當前代還有未完成的候選輪';

  @override
  String get styleExplore_branchDuplicate => '所選子代與第一代父本串完全重複';

  @override
  String get styleExplore_branchEmpty => '請至少選擇一張子代候選';

  @override
  String styleExplore_preferenceValue(String value) {
    return '偏好 $value';
  }

  @override
  String styleExplore_roundsSummary(int count) {
    return '$count 輪';
  }

  @override
  String get styleExplore_pileEmpty => '尚無候選圖，點上方「生成候選圖」開始';

  @override
  String get styleExplore_managePile => '管理';

  @override
  String get styleExplore_pileManageDeleteTitle => '刪除所選候選圖';

  @override
  String styleExplore_pileManageDeleteMessage(int count) {
    return '將刪除 $count 張候選在 Run 目錄中的圖片副本與候選記錄；圖庫來源圖不受影響。';
  }

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
  String get tips_gen_teach_1 => '在提示詞框輸入 < 可以拉進塊庫裡的塊';

  @override
  String get tips_gen_teach_2 => '摘要條點 Seed 可鎖定/重抽，點 Sampler 可直接換取樣器';

  @override
  String get tips_gen_teach_3 => '生成鍵旁邊的數字小框定本批張數，右端深色框是 Anlas 消耗';

  @override
  String get tips_gen_teach_4 => '右上角 chunks 選單裡收納了塊庫、預設和正則規則';

  @override
  String get tips_gen_teach_5 => '透明通道匯出 Alpha 通道；啟用角色參考時不可用';

  @override
  String get tips_gen_fun_1 => '正在給 AI 喂電子小魚乾…';

  @override
  String get tips_gen_fun_2 => '每張圖都是一次小型抽卡——抽吧';

  @override
  String get tips_gen_fun_3 => 'Anlas 餘額和模型名都在頭頂上——燒錢前瞄一眼';

  @override
  String get tips_gen_fun_4 => '提示詞框長高了，方便野心攤開寫';

  @override
  String get tips_gen_fun_5 => '種子 -1 交給命運；據說命運喜歡整數';

  @override
  String get tips_explore_teach_1 => '點紅心+歸資料夾，就是給下一代投票';

  @override
  String get tips_explore_teach_2 => 'A/B 對照組看的是父本原圖——選出勝者就翻篇';

  @override
  String get tips_explore_teach_3 => '「生成候選圖」旁邊的數字框定本輪批次';

  @override
  String get tips_explore_teach_4 => '懸停候選堆縮圖能看大圖';

  @override
  String get tips_explore_teach_5 => '拖分隔條可以拉寬畫廊欄';

  @override
  String get tips_explore_fun_1 => '適者生存，畫也一樣';

  @override
  String get tips_explore_fun_2 => '每一輪生圖都是海選現場';

  @override
  String get tips_explore_fun_3 => '好基因來自好父本';

  @override
  String get tips_explore_fun_4 => '永遠不要小看變異';

  @override
  String get tips_explore_fun_5 => '自然選擇，加速版';

  @override
  String get tips_gallerySearch_teach_1 => '逗號分隔 = 交集搜尋';

  @override
  String get tips_gallerySearch_teach_2 => '文字搜尋已排除負面提示詞——結果更乾淨';

  @override
  String get tips_gallerySearch_teach_3 => '搜尋會命中模型、取樣器、來源、版本欄位';

  @override
  String get tips_gallerySearch_teach_4 => '按鈕放不下時會橫向滾動';

  @override
  String get tips_gallerySearch_teach_5 => '每頁最多 500 張——給一口氣翻到底的人';

  @override
  String get tips_gallerySearch_fun_1 => '下面看上去有不少好東西呢~~~打算找點什麼嗎？';

  @override
  String get tips_gallerySearch_fun_2 => '收藏在長，資料夾在假裝跟得上';

  @override
  String get tips_gallerySearch_fun_3 => '專業建議：自己的提示詞就是最好的搜尋詞';

  @override
  String get tips_gallerySearch_fun_4 => '滾動也算運動';

  @override
  String get tips_gallerySearch_fun_5 => '這堆裡某個角落藏著今晚的神作';

  @override
  String get tips_gallerySearch_start_1 => '搜檔名或提示詞正文——回車或點補全項都行';

  @override
  String get tips_gallerySearch_start_2 => '多個詞用逗號分隔 = 全部命中才算數';

  @override
  String get tips_gallerySearch_start_3 => '搜尋只看正向提示詞，負面詞不會誤中';

  @override
  String get tips_gallerySearch_start_4 => '模型、取樣器、來源、版本欄位也能被搜到';

  @override
  String get tips_gallerySearch_start_5 => '輸入標籤（比如 masterpiece）或檔名片段即可';

  @override
  String get tips_gallerySearch_start_6 => '找到了點卡片看詳情，右鍵有更多操作';

  @override
  String get tips_gallerySearch_start_7 => '配合右側版本 chip 可以進一步收窄範圍';

  @override
  String get tips_gallerySearch_start_8 => '空著就是瀏覽全部；輸入即篩不用等';

  @override
  String get tips_gallerySearch_start_9 => '邊輸邊搜，不用按回車';

  @override
  String get tips_gallerySearch_start_10 => '先搜一搜再考慮重新生成——多半已經有了';

  @override
  String get tips_blocklib_teach_1 => '塊可以帶縮圖——編輯彈窗裡設定';

  @override
  String get tips_blocklib_teach_2 => '點選塊開詳情，懸停先看大圖';

  @override
  String get tips_blocklib_teach_3 => '⭐ 收進收藏集，常用塊置頂集中';

  @override
  String get tips_blocklib_teach_4 => '瀑布流檢視能看清圖塊';

  @override
  String get tips_blocklib_teach_5 => '拖分割條可以調整塊區/資料夾區比例';

  @override
  String get tips_blocklib_fun_1 => '每個塊都夢想著被點名';

  @override
  String get tips_blocklib_fun_2 => '資料夾裡套資料夾——現在算是有條理了';

  @override
  String get tips_blocklib_fun_3 => '使用次數就是塊的履歷表';

  @override
  String get tips_blocklib_fun_4 => '積木留給釘子戶';

  @override
  String get tips_blocklib_fun_5 => '猶豫就做成塊';

  @override
  String get tips_gen_1 => '文本框裡 Ctrl+Z 管用——錯別字不可怕';

  @override
  String get tips_gen_2 => '設定→提示詞的 chunks 選單裡藏著不少開關';

  @override
  String get tips_gen_3 => '看見細分隔條就拖拖看——多數面板能調寬';

  @override
  String get tips_gen_4 => '歷史欄可以調回舊圖和當時的參數';

  @override
  String get tips_gen_5 => '右鍵出選單，懸停出預覽';

  @override
  String get tips_fun_1 => '正在載入今日份的玄學…';

  @override
  String get tips_fun_2 => '種子是隨機的，品味不是';

  @override
  String get tips_fun_3 => '某處有一塊顯示卡正在摩拳擦掌';

  @override
  String get tips_fun_4 => '這裡最貴的按鈕是生成——它吃 Anlas';

  @override
  String get tips_fun_5 => '這個框見證過上千張神作（和幾張黑歷史）';

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
  String get img2img_original => '原圖';

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
  String get generation_tipReuseBlocks => '把常用提示詞儲存為塊，下一次直接複用。';

  @override
  String get generation_tipBlockModes => '順序與隨機模式，可以讓提示詞塊產生不同組合。';

  @override
  String get generation_tipLockBlocks => '鎖定想保留的塊，再隨機調整其他部分。';

  @override
  String get styleExplore_collapseGallery => '收起候選畫廊';

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
  String get wiki_searchHint => '搜尋標籤、別名或中文譯名';

  @override
  String get wiki_typeAll => '全部類型';

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
  String get wiki_hide => '隱藏';

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
  String get progress_cancelled => '已取消';

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
  String gallery_initFailed(Object error) {
    return '初始化失敗: $error';
  }

  @override
  String gallery_loadFoldersFailed(Object error) {
    return '載入資料夾失敗: $error';
  }

  @override
  String gallery_refreshFailed(Object error) {
    return '重新整理失敗: $error';
  }

  @override
  String gallery_clearCacheFailed(Object error) {
    return '清除快取失敗: $error';
  }

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
  String get cache_clearInProgress => '清除操作正在進行中';

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
}
