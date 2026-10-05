// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'W.O.F NAI Studio';

  @override
  String get settings_visualAssets => 'Interface fonts & licenses';

  @override
  String get brand_entryTagline => 'A place for your imagination.';

  @override
  String get brand_switchToLight => 'Switch to light mode';

  @override
  String get brand_switchToDark => 'Switch to dark mode';

  @override
  String get app_subtitle => 'NovelAI Third-party Client';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get onlineFav_all => 'All';

  @override
  String get onlineFav_rootCollection => 'Root';

  @override
  String get onlineFav_newCollection => 'New Collection';

  @override
  String get onlineFav_renameCollection => 'Rename';

  @override
  String get onlineFav_deleteCollection => 'Delete Collection';

  @override
  String get onlineFav_empty => 'No favorited works yet';

  @override
  String onlineFav_authorWorkCount(Object n) {
    return '$n works';
  }

  @override
  String get onlineFav_moveHere => 'Move here';

  @override
  String get onlineFav_removeFavorite => 'Unfavorite';

  @override
  String get onlineFav_favoriteAuthor => 'Favorite Author';

  @override
  String get onlineFav_unfavoriteAuthor => 'Unfavorite author';

  @override
  String get onlineFav_authorFavorited => 'Author favorited';

  @override
  String get onlineFav_authorUnfavorited => 'Author unfavorited';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_selectAll => 'Select All';

  @override
  String get common_deselectAll => 'Deselect All';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_close => 'Close';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_copied => 'Copied';

  @override
  String get common_export => 'Export';

  @override
  String get common_import => 'Import';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_select => 'Select';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_add => 'Add';

  @override
  String get common_added => 'Added';

  @override
  String get common_new => 'New';

  @override
  String get common_confirmDelete => 'Confirm Delete';

  @override
  String get common_confirmClear => 'Confirm Clear';

  @override
  String get common_gotIt => 'Got it';

  @override
  String common_deleteItemConfirm(Object itemName) {
    return 'Delete \"$itemName\"? This action cannot be undone.';
  }

  @override
  String common_clearAllItemsConfirm(Object count, Object itemType) {
    return 'Clear all $count $itemType? This action cannot be undone.';
  }

  @override
  String get common_clearInputConfirm => 'Clear the input content?';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String common_daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get common_undo => 'Undo';

  @override
  String get common_redo => 'Redo';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get common_download => 'Download';

  @override
  String get common_apply => 'Apply';

  @override
  String get common_move => 'Move';

  @override
  String get common_favorite => 'Favorite';

  @override
  String get common_unfavorite => 'Unfavorite';

  @override
  String get common_ok => 'OK';

  @override
  String get common_exit => 'Exit';

  @override
  String get common_folder => 'Folder';

  @override
  String get common_grid => 'Grid';

  @override
  String get common_pack => 'Pack';

  @override
  String get common_multiSelect => 'Multi-select';

  @override
  String get common_category => 'Category';

  @override
  String get common_categories => 'Categories';

  @override
  String get networkError_connectionTimeout =>
      'Connection timed out. Check your network connection.';

  @override
  String get networkError_sendTimeout => 'Sending timed out. Try again.';

  @override
  String get networkError_receiveTimeout =>
      'Receiving timed out. Image generation may take longer than expected.';

  @override
  String get networkError_requestCancelled => 'The request was cancelled';

  @override
  String get networkError_connection =>
      'Network connection error. Check your network connection.';

  @override
  String get networkError_unknown => 'Unknown error';

  @override
  String get networkError_noResponse => 'The server did not respond';

  @override
  String get networkError_badRequest => 'The request parameters are invalid';

  @override
  String get networkError_authFailed => 'Authentication failed. Sign in again.';

  @override
  String get networkError_insufficientAnlas => 'Insufficient Anlas';

  @override
  String get networkError_forbidden =>
      'You do not have permission to access this resource';

  @override
  String get networkError_notFound => 'The requested resource does not exist';

  @override
  String get networkError_conflict =>
      'The request conflicts with the current state';

  @override
  String get networkError_rateLimited => 'Too many requests. Try again later.';

  @override
  String get networkError_serverInternal => 'Internal server error';

  @override
  String get networkError_badGateway => 'Server gateway error';

  @override
  String get networkError_unavailable =>
      'The service is temporarily unavailable';

  @override
  String networkError_requestFailed(int code) {
    return 'Request failed ($code)';
  }

  @override
  String get nav_canvas => 'Canvas';

  @override
  String get nav_onlineGallery => 'Online Gallery';

  @override
  String get nav_expandSidebar => 'Expand sidebar';

  @override
  String get nav_collapseSidebar => 'Collapse sidebar';

  @override
  String get auth_login => 'Login';

  @override
  String get auth_logout => 'Logout';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_loginButton => 'Sign In';

  @override
  String get auth_loginFailed => 'Login failed';

  @override
  String get auth_guestEntry => 'Skip login and continue as guest';

  @override
  String get auth_recommended => 'Best';

  @override
  String get auth_getToken => 'Get token';

  @override
  String get auth_localOnlyNote => 'Accounts and tokens stay on this device';

  @override
  String get auth_back => 'Back';

  @override
  String get auth_toggleVisibility => 'Show / hide';

  @override
  String get auth_emailRequired => 'Please enter email';

  @override
  String get auth_emailInvalid => 'Please enter a valid email address';

  @override
  String get auth_passwordRequired => 'Please enter password';

  @override
  String get auth_tokenLogin => 'API Token Login';

  @override
  String get auth_tokenLoginRecommended => 'API Token Login (Recommended)';

  @override
  String get auth_credentialsLogin => 'Email & Password';

  @override
  String get auth_credentialsLoginUnavailable =>
      'Email/password login is currently unavailable. Please use Token login.';

  @override
  String get auth_tokenRequired => 'Please enter token';

  @override
  String get auth_tokenInvalid =>
      'Invalid token format, should start with pst-';

  @override
  String get auth_nicknameHint => 'Set a recognizable name for this account';

  @override
  String get auth_thirdPartyLogin => 'Third-party Site';

  @override
  String get auth_thirdPartyApiSite => 'Third-party API Site';

  @override
  String get auth_imageApiSiteOptional => 'Image API Site (optional)';

  @override
  String get auth_imageApiSiteHint =>
      'Leave empty to use the same third-party API site';

  @override
  String get auth_thirdPartyNicknameHint =>
      'For example: self-hosted site / mirror site';

  @override
  String get auth_thirdPartyTokenHint =>
      'Enter the API token from the third-party site';

  @override
  String get auth_thirdPartyCompatibilityHint =>
      'The third-party site must be compatible with NovelAI subscription and image-generation APIs. The token will be sent as a Bearer token.';

  @override
  String get auth_thirdPartyApiSiteRequired => 'Enter third-party API site URL';

  @override
  String get auth_validateAndLogin => 'Validate & Login';

  @override
  String get auth_tokenGuide => 'Get Token from NovelAI settings';

  @override
  String get auth_addAccount => 'Add Account';

  @override
  String get auth_tokenNotFound => 'Token not found for this account';

  @override
  String get auth_switchAccount => 'Switch Account';

  @override
  String get auth_currentAccount => 'Current Account';

  @override
  String get auth_selectAccount => 'Select Account';

  @override
  String get auth_deleteAccount => 'Delete Account';

  @override
  String auth_deleteAccountConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String auth_deleteCurrentAccountConfirm(Object name) {
    return 'Delete \"$name\" and sign out?';
  }

  @override
  String get auth_switchFailedDeletePrompt =>
      'Couldn\'t sign in to this account (it may be invalid). Remove it from the list?';

  @override
  String get auth_switchFailedDeletePromptMissingToken =>
      'No saved credentials for this account. Remove it from the list?';

  @override
  String get auth_removeAvatar => 'Remove Avatar';

  @override
  String get auth_quickLogin => 'Quick Login';

  @override
  String get auth_nicknameRequired => 'Please enter nickname';

  @override
  String get auth_error_networkTimeout => 'Connection timeout';

  @override
  String get auth_error_networkError => 'Network error';

  @override
  String get auth_error_authFailed => 'Authentication failed';

  @override
  String get auth_error_credentialsLoginUnavailable =>
      'Email/password login is currently unavailable';

  @override
  String get auth_error_credentialsLoginUnavailable_hint =>
      'NovelAI now requires a web safety check for email/password login. Please use a Persistent API Token instead.';

  @override
  String get auth_error_serverError => 'Server error';

  @override
  String get auth_error_unknown => 'Unknown error';

  @override
  String get auth_autoLogin => 'Auto login';

  @override
  String get auth_forgotPassword => 'Forgot password?';

  @override
  String get auth_passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get auth_loggingIn => 'Logging in...';

  @override
  String get auth_viewTroubleshootingTips => 'View Troubleshooting Tips';

  @override
  String get auth_troubleshoot_checkConnection_title =>
      'Check Network Connection';

  @override
  String get auth_troubleshoot_checkConnection_desc =>
      'Ensure your device is connected to the internet';

  @override
  String get auth_troubleshoot_retry_title => 'Try Again';

  @override
  String get auth_troubleshoot_retry_desc =>
      'Network issues may be temporary, please retry';

  @override
  String get auth_troubleshoot_proxy_title => 'Check Proxy Settings';

  @override
  String get auth_troubleshoot_proxy_desc =>
      'If using a proxy, verify it\'s configured correctly';

  @override
  String get auth_troubleshoot_firewall_title => 'Check Firewall Settings';

  @override
  String get auth_troubleshoot_firewall_desc =>
      'Ensure your firewall allows connections to NovelAI servers';

  @override
  String get auth_troubleshoot_serverStatus_title => 'Check Server Status';

  @override
  String get auth_troubleshoot_serverStatus_desc =>
      'Visit NovelAI status page or community to check for outages';

  @override
  String get common_paste => 'Paste';

  @override
  String get common_default => 'Default';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_savedAccounts => 'Saved Accounts';

  @override
  String get settings_style => 'Style';

  @override
  String get settings_font => 'Font';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_shortcuts => 'Shortcuts';

  @override
  String get settings_generationInputSection => 'Input';

  @override
  String get settings_generationFeedbackSection => 'Completion Alert';

  @override
  String get settings_selectFont => 'Select Font';

  @override
  String get settings_selectLanguage => 'Select Language';

  @override
  String settings_loadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get settings_imageSavePath => 'Image Save Location';

  @override
  String get settings_autoSave => 'Auto Save';

  @override
  String get settings_autoSaveSubtitle =>
      'Automatically save images after generation';

  @override
  String get settings_extraRootsTitle => 'Gallery Sources';

  @override
  String get settings_extraRootsHint =>
      'Extra gallery sources can be browsed and searched, and their images can be moved or copied to categories. They are not used for auto-save. New sources are scanned immediately.';

  @override
  String get settings_extraRootsEmpty => 'No extra gallery sources added';

  @override
  String get settings_extraRootsAdd => 'Add Folder';

  @override
  String get settings_extraRootsAddTitle =>
      'Select a folder to add as a gallery source';

  @override
  String get settings_extraRootsRemove => 'Remove this gallery source';

  @override
  String get settings_extraRootsRemoveConfirmTitle => 'Remove gallery source?';

  @override
  String settings_extraRootsRemoveConfirmContent(String path) {
    return 'Remove \"$path\" from the gallery (no files in the folder will be deleted).';
  }

  @override
  String get settings_extraRootsAdded => 'Gallery source added and scanned';

  @override
  String get settings_extraRootsScanFailed =>
      'Folder added, but scanning did not finish. Refresh the gallery to retry';

  @override
  String get settings_extraRootsWaitingScan =>
      'The gallery is scanning. This folder will be imported when it finishes';

  @override
  String get settings_extraRootsRemoved => 'Gallery source removed';

  @override
  String get settings_extraRootsDuplicate =>
      'This folder is already a gallery source';

  @override
  String get settings_extraRootsSameAsMain =>
      'This folder is the same as the image save location';

  @override
  String get settings_extraRootsNested =>
      'Gallery sources cannot contain each other; choose another folder';

  @override
  String get settings_extraRootsNotFound =>
      'The selected folder does not exist';

  @override
  String get settings_importTagIndex => 'Import Tag Index…';

  @override
  String get settings_importTagIndexPickTitle =>
      'Select tag index file (.jsonl)';

  @override
  String settings_importTagIndexProgress(int processed, int total) {
    return 'Importing $processed/$total lines…';
  }

  @override
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  ) {
    return 'Import complete: $imported new, $updated updated, $skipped skipped, $errors errors';
  }

  @override
  String get settings_importTagIndexFailed => 'Tag index import failed';

  @override
  String get settings_importTagIndexBlockedByScan =>
      'Gallery scan is in progress. Wait for it to finish before importing the tag index.';

  @override
  String get settings_extraRootsIndexImportTitle => 'Tag Index Found';

  @override
  String settings_extraRootsIndexImportContent(String path) {
    return 'Found tag index index.jsonl under \"$path\". Importing it first lets the upcoming scan fast-forward (skip metadata parsing). Import now?';
  }

  @override
  String get settings_extraRootsIndexImportConfirm => 'Import Now';

  @override
  String settings_version(Object version) {
    return 'Version $version';
  }

  @override
  String get settings_openSource => 'Open Source';

  @override
  String get settings_openSourceSubtitle =>
      'View source code and documentation';

  @override
  String get settings_fileLogging => 'Record application logs';

  @override
  String get settings_fileLoggingSubtitle =>
      'Off by default; enable only for troubleshooting. When enabled, logs are written to Documents/NAI_Launcher/logs. When disabled, log files are no longer created or written.';

  @override
  String get settings_pathReset => 'Reset to default location';

  @override
  String get settings_pathSaved => 'Save location updated';

  @override
  String get settings_selectFolder => 'Select Save Folder';

  @override
  String get settings_vibeLibraryPath => 'Vibe Library Path';

  @override
  String get settings_hiveStoragePath => 'Data Storage Path';

  @override
  String get settings_selectVibeLibraryFolder => 'Select Vibe Library Folder';

  @override
  String get settings_selectHiveFolder => 'Select Data Storage Folder';

  @override
  String get settings_pathSavedRestartRequired =>
      'Path updated, restart to apply changes';

  @override
  String get settings_accountType => 'Account Type';

  @override
  String get settings_subscriptionExpiry => 'Subscription Expires';

  @override
  String get settings_thirdPartyApiAccount => 'Third-party Site API';

  @override
  String get settings_goToLogin => 'Go to Login';

  @override
  String get settings_changeAvatar => 'Change Avatar';

  @override
  String get settings_removeAvatar => 'Remove Avatar';

  @override
  String get settings_accountEmail => 'Account Email';

  @override
  String get settings_emailAccount => 'Email Account';

  @override
  String get settings_tokenAccount => 'Token Account';

  @override
  String get settings_setAsDefault => 'Set as Default';

  @override
  String get settings_defaultAccount => 'Default';

  @override
  String get settings_nickname => 'Nickname';

  @override
  String get settings_nicknameUpdated => 'Nickname updated';

  @override
  String get settings_avatarUpdated => 'Avatar updated';

  @override
  String get settings_avatarRemoved => 'Avatar removed';

  @override
  String get settings_setAsDefaultSuccess => 'Set as default account';

  @override
  String get generation_title => 'Generate';

  @override
  String get generation_generate => 'Generate';

  @override
  String generation_cooldownRemaining(Object seconds) {
    return 'Wait ${seconds}s';
  }

  @override
  String get generation_generating => 'Generating...';

  @override
  String get generation_cancelGeneration => 'Cancel Generation';

  @override
  String get generation_stopGeneration => 'Stop Generation';

  @override
  String get generation_pleaseInputPrompt => 'Please enter prompt';

  @override
  String get generation_generationFailed => 'Generation failed';

  @override
  String generation_progress(Object progress) {
    return 'Generating... $progress%';
  }

  @override
  String get generation_lockHistoryScroll => 'Lock history scrolling';

  @override
  String get generation_unlockHistoryScroll => 'Unlock history scrolling';

  @override
  String get generation_downloadAllImages => 'Download all images';

  @override
  String get generation_selectMultiple => 'Select multiple';

  @override
  String get generation_deselectAll => 'Exit multi-select';

  @override
  String generation_deleteSelectedImages(int count) {
    return 'Delete selected images ($count)';
  }

  @override
  String get generation_deleteSelectedImagesTitle => 'Delete Selected Images';

  @override
  String generation_deleteSelectedImagesConfirm(int count) {
    return '$count image(s) will be removed from records (files saved to disk are kept)';
  }

  @override
  String generation_seedWrittenBack(int seed) {
    return 'Seed written back: $seed';
  }

  @override
  String get generation_setAsReferenceImage => 'Set as reference image';

  @override
  String get generation_canvasDisplaySettings => 'Canvas Display';

  @override
  String get generation_canvasZoomToFill => 'Zoom to fill (allows >100%)';

  @override
  String get generation_canvasEmpty => 'Canvas is empty';

  @override
  String get generation_canvasBackground => 'Transparency background';

  @override
  String get generation_canvasBackgroundChecker => 'Checkerboard';

  @override
  String get generation_canvasBackgroundCheckerLight => 'Light checkerboard';

  @override
  String get generation_canvasBackgroundCheckerDark => 'Dark checkerboard';

  @override
  String get generation_canvasBackgroundNone => 'No background';

  @override
  String get generation_canvasBackgroundBlack => 'Black';

  @override
  String get generation_canvasBackgroundWhite => 'White';

  @override
  String get generation_canvasBackgroundGray => 'Gray';

  @override
  String get generation_canvasBackgroundRed => 'Red';

  @override
  String get generation_canvasBackgroundGreen => 'Green';

  @override
  String get generation_canvasBackgroundBlue => 'Blue';

  @override
  String get generation_canvasBackgroundCustom => 'Custom color';

  @override
  String get generation_canvasSetInitImage => 'Use as img2img source';

  @override
  String get generation_canvasSendToTools => 'Send to Director Tools';

  @override
  String get generation_canvasPinImage => 'Pin image';

  @override
  String get generation_canvasUnpinImage => 'Unpin image';

  @override
  String get generation_canvasUseSeed => 'Click to use this seed';

  @override
  String generation_canvasPinnedCount(int count) {
    return 'Pins $count';
  }

  @override
  String get generation_params => 'Parameters';

  @override
  String get generation_paramsSettings => 'Parameter Settings';

  @override
  String get generation_history => 'History';

  @override
  String get generation_historyRecord => 'History Records';

  @override
  String get generation_failedStreamSnapshot => 'Failed snapshot';

  @override
  String get generation_failedStreamSnapshotHint =>
      'Generation did not finish; only the last preview frame is kept. It cannot be saved, favorited, or used for image workflows.';

  @override
  String get generation_noHistory => 'No history records';

  @override
  String get generation_clearHistory => 'Clear History';

  @override
  String get generation_clearHistoryConfirm =>
      'Are you sure you want to clear all history records? This action cannot be undone.';

  @override
  String get generation_model => 'Model';

  @override
  String get generation_imageSize => 'Image Size';

  @override
  String get generation_sampler => 'Sampler';

  @override
  String generation_steps(Object steps) {
    return 'Steps: $steps';
  }

  @override
  String get generation_stepsLabel => 'Steps';

  @override
  String get generation_guidance => 'Guidance';

  @override
  String generation_cfgScale(Object scale) {
    return 'Prompt Guidance: $scale';
  }

  @override
  String get generation_seed => 'Seed';

  @override
  String get generation_seedRandom => 'Random';

  @override
  String get generation_samplerRecommended => 'RECOMMENDED';

  @override
  String get generation_samplerOther => 'OTHER';

  @override
  String get generation_advancedOptions => 'Advanced Options';

  @override
  String get generation_smea => 'SMEA';

  @override
  String get generation_smeaSubtitle =>
      'Improve generation quality for large images';

  @override
  String get generation_smeaDyn => 'SMEA DYN';

  @override
  String get generation_smeaDescription =>
      'High resolution samplers will automatically be used above a certain image size';

  @override
  String generation_cfgRescale(Object value) {
    return 'Prompt Guidance Rescale: $value';
  }

  @override
  String get generation_noiseSchedule => 'Noise Schedule';

  @override
  String get generation_modelGroupNew => 'NEW';

  @override
  String get generation_modelGroupLegacy => 'LEGACY';

  @override
  String get generation_modelDesc_v5Curated =>
      'NovelAI\'s newest model, trained on a curated subset of images. Recommended for streaming.';

  @override
  String get generation_modelDesc_v5Full => 'NovelAI\'s newest and best model.';

  @override
  String get generation_modelDesc_v45Curated =>
      'NovelAI\'s V4.5 model trained on a curated subset of images. No longer recommended for use.';

  @override
  String get generation_modelDesc_v45Full => 'NovelAI\'s V4.5 full model.';

  @override
  String get generation_modelDesc_v4Curated =>
      'NovelAI\'s V4 model trained on a curated subset of images.';

  @override
  String get generation_modelDesc_v4Full => 'NovelAI\'s V4 full model.';

  @override
  String get generation_sectionCharacters => 'Character Prompts';

  @override
  String get generation_sectionCharactersSub =>
      'Create a separate prompt for characters in your scene.';

  @override
  String get character_positionLabel => 'Position';

  @override
  String get generation_sectionReferenceImages => 'Reference Images';

  @override
  String get generation_sectionImageSettings => 'Image Settings';

  @override
  String get anlas_subscription => 'Subscription';

  @override
  String get anlas_purchased => 'Purchased';

  @override
  String get prompt_positive => 'Prompt';

  @override
  String get prompt_baseTab => 'Base Prompt';

  @override
  String get prompt_negativeTab => 'Undesired Content';

  @override
  String get prompt_transparentBg => 'Transparent BG';

  @override
  String get prompt_chunksMenu => 'Tools & toggles';

  @override
  String get qualityTags_presetChip => 'Quality Tags';

  @override
  String get ucPreset_presetChip => 'Undesired Content Preset';

  @override
  String get prompt_positivePrompt => 'Prompt';

  @override
  String get prompt_negativePrompt => 'Undesired Content';

  @override
  String get prompt_mainPositive => 'Main Prompt';

  @override
  String get prompt_mainNegative => 'Main Prompt (Undesired Content)';

  @override
  String get prompt_characterPrompts => 'Multi-Character Prompts';

  @override
  String get prompt_finalPrompt => 'Final Effective Prompt';

  @override
  String get prompt_finalNegative => 'Final Effective Undesired Content';

  @override
  String prompt_importedCharacters(int count) {
    return 'Imported $count character(s)';
  }

  @override
  String get prompt_characterPromptReplaced => 'Replaced character prompts';

  @override
  String prompt_characterPromptAppended(Object count) {
    return 'Appended character prompts ($count character(s))';
  }

  @override
  String prompt_smartDecomposedWithCharacters(Object count) {
    return 'Decomposed into main prompt + $count character(s)';
  }

  @override
  String get prompt_appliedToMainPrompt => 'Applied to main prompt';

  @override
  String get prompt_searchHint => 'Search prompt';

  @override
  String prompt_searchMatchCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get prompt_searchPrevious => 'Previous match';

  @override
  String get prompt_searchNext => 'Next match';

  @override
  String get prompt_searchClose => 'Close search';

  @override
  String get prompt_replaceHint => 'Replace with';

  @override
  String get prompt_replaceToggle => 'Toggle replace';

  @override
  String get prompt_replaceCurrent => 'Replace current match (Enter)';

  @override
  String get prompt_replaceAll => 'Replace all (Ctrl+Enter)';

  @override
  String prompt_replaceAllDone(Object count) {
    return 'Replaced $count matches';
  }

  @override
  String get kritaBridge_busyGenerating =>
      'Krita Bridge is generating. Wait for the current task to finish.';

  @override
  String get prompt_unwantedContent =>
      'Content you don\'t want in the image...';

  @override
  String get prompt_autoFormat => 'Auto Format';

  @override
  String get prompt_autoFormatSubtitle =>
      'Normalize commas and whitespace; remove redundant 1x weight markers';

  @override
  String get prompt_highlightEmphasis => 'Highlight Emphasis';

  @override
  String get prompt_highlightEmphasisSubtitle =>
      'Highlight brackets and weight syntax';

  @override
  String get prompt_sdSyntaxAutoConvert => 'SD Syntax Auto Convert';

  @override
  String get prompt_sdSyntaxAutoConvertSubtitle =>
      'Convert SD weights to NAI syntax on blur or generation';

  @override
  String get prompt_cooccurrenceRecommendation => 'Tag Expansion';

  @override
  String get prompt_cooccurrenceRecommendationSubtitle =>
      'Ctrl+click to search local tags; Ctrl+drag to explore related tags';

  @override
  String get prompt_formatted => 'Formatted';

  @override
  String get image_save => 'Save';

  @override
  String get image_copy => 'Copy';

  @override
  String get image_upscale => 'Upscale';

  @override
  String get image_saveToLibrary => 'Save to Library';

  @override
  String image_imageSaved(Object path) {
    return 'Image saved to: $path';
  }

  @override
  String image_saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get image_copiedToClipboard => 'Copied to clipboard';

  @override
  String image_copyFailed(Object error) {
    return 'Copy failed: $error';
  }

  @override
  String get img2img_title => 'Image2Image';

  @override
  String get img2img_subtitle => 'Generate variations from a source image';

  @override
  String get img2img_enabled => 'Enabled';

  @override
  String get img2img_sourceImage => 'Source Image';

  @override
  String get img2img_strength => 'Strength';

  @override
  String get img2img_strengthHint =>
      'Higher values create greater difference from original';

  @override
  String get img2img_noise => 'Noise';

  @override
  String get img2img_noiseHint => 'Add extra noise for more variation';

  @override
  String get img2img_clearSettings => 'Clear Image2Image Settings';

  @override
  String get img2img_changeImage => 'Change Image';

  @override
  String get img2img_removeImage => 'Remove Image';

  @override
  String img2img_selectFailed(Object error) {
    return 'Failed to select image: $error';
  }

  @override
  String get img2img_editImage => 'Edit Image';

  @override
  String get img2img_placeOnCanvas => 'Place on canvas';

  @override
  String get img2img_editApplied =>
      'The edited image is now the new source image';

  @override
  String get img2img_uploadImage => 'Upload Image';

  @override
  String get img2img_dropToAdd => 'Release to set as source image';

  @override
  String get img2img_moreActions => 'More actions';

  @override
  String get img2img_drawSketch => 'Draw Sketch';

  @override
  String get img2img_inpaint => 'Inpaint';

  @override
  String get img2img_inpaintStrength => 'Inpaint Strength';

  @override
  String get img2img_inpaintStrengthHint =>
      'Higher values make the masked area diverge more from the current source image';

  @override
  String get img2img_inpaintPendingHint =>
      'Click Inpaint to open the canvas, mark the region you want to repaint with brush, eraser, or selection tools, then return here and use the main generate button.';

  @override
  String get img2img_inpaintReadyHint =>
      'Mask loaded. The next generation will repaint only the masked area.';

  @override
  String get img2img_inpaintMaskReady => 'Inpaint mask is ready';

  @override
  String get img2img_generateVariations => 'Generate Variations';

  @override
  String get img2img_directorTools => 'Director Tools';

  @override
  String get img2img_directorPrompt => 'Prompt (Optional)';

  @override
  String get img2img_directorPromptHint =>
      'Add guidance when needed, such as target emotion or color direction';

  @override
  String get img2img_directorRunning => 'Processing...';

  @override
  String get img2img_directorResult => 'Result';

  @override
  String get img2img_directorApplied =>
      'Applied the Director Tool result as the new source image';

  @override
  String get img2img_directorDefry => 'Defry';

  @override
  String get img2img_directorEmotionLevel => 'Emotion Level';

  @override
  String get img2img_directorApplyAsSource => 'Use as Source';

  @override
  String get img2img_directorSourceImage => 'Source Image';

  @override
  String get img2img_variationsStarted => 'Generating variations...';

  @override
  String get img2img_directorRemoveBackground => 'Remove Background';

  @override
  String get img2img_directorLineArt => 'Line Art';

  @override
  String get img2img_directorSketch => 'Sketch';

  @override
  String get img2img_directorColorize => 'Colorize';

  @override
  String get img2img_directorEmotion => 'Fix Emotion';

  @override
  String get img2img_directorDeclutter => 'Declutter';

  @override
  String get img2img_enhance => 'Enhance';

  @override
  String get img2img_enhanceMagnitude => 'Magnitude';

  @override
  String get img2img_enhanceUpscaleAmount => 'Upscale Amount';

  @override
  String get img2img_enhanceMax => 'Max✨';

  @override
  String get img2img_novelAiCloudUpscale => 'NovelAI cloud upscale (fixed 2x)';

  @override
  String get img2img_cloudUpscaleSizeLimit =>
      'NovelAI cloud upscale supports input images up to 3MP.';

  @override
  String get img2img_comfyuiEnableHint =>
      'Enable and connect ComfyUI in Settings > ComfyUI first.';

  @override
  String get img2img_upscaleMode => 'Upscale Mode';

  @override
  String get img2img_upscaleRegularModel => 'Regular Model';

  @override
  String get img2img_upscaleModel => 'Upscale Model';

  @override
  String get img2img_noSeedvr2Models =>
      'No SeedVR2 model found. Refresh the model list or check the SeedVR2 node/model files.';

  @override
  String get img2img_noRegularUpscaleModels =>
      'No regular upscale model found. Refresh the model list or check models/upscale_models.';

  @override
  String get img2img_useSeedvr2TiledWorkflow =>
      'Using the SeedVR2TilingUpscaler tiled upscale workflow.';

  @override
  String get img2img_useSeedvr2Workflow =>
      'Using the SeedVR2VideoUpscaler workflow.';

  @override
  String get img2img_useRegularUpscaleWorkflow =>
      'Using UpscaleModelLoader + ImageUpscaleWithModel, then correcting to the target scale with Lanczos.';

  @override
  String get img2img_useRtxUpscaleWorkflow =>
      'Using RTX Video Super Resolution. No model selection is required.';

  @override
  String get img2img_refreshModelList => 'Refresh model list';

  @override
  String get img2img_startUpscale => 'Start Upscale';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI upscale complete';

  @override
  String img2img_upscaleComplete(Object width, Object height) {
    return 'Upscale complete (${width}x$height)';
  }

  @override
  String img2img_regularUpscaleComplete(Object width, Object height) {
    return 'Regular model upscale complete (${width}x$height)';
  }

  @override
  String img2img_rtxUpscaleComplete(Object width, Object height) {
    return 'RTX upscale complete (${width}x$height)';
  }

  @override
  String get img2img_noAvailableSeedvr2Model =>
      'No available SeedVR2 model selected';

  @override
  String get img2img_noAvailableRegularUpscaleModel =>
      'No available regular upscale model selected';

  @override
  String get img2img_decodeSourceFailed => 'Failed to decode source image';

  @override
  String get img2img_metricSpeed => 'Speed';

  @override
  String get img2img_metricVram => 'VRAM';

  @override
  String get img2img_metricQuality => 'Quality';

  @override
  String get img2img_seedvr2VaeTileHint =>
      'Also writes the SeedVR2 VAE MODEL encode/decode tile size.';

  @override
  String get img2img_seedvr2UseTiledUpscale => 'Use tiled upscale';

  @override
  String get img2img_seedvr2UseTiledUpscaleHint =>
      'When enabled, uses SeedVR2TilingUpscaler. Recommended for large images or high VRAM pressure.';

  @override
  String get img2img_seedvr2TileSize => 'Tile Size';

  @override
  String get img2img_seedvr2TileSizeHint =>
      'Also controls SeedVR2TilingUpscaler tile_width / tile_height.';

  @override
  String get img2img_seedvr2BlocksToSwap => 'Blocks Offloaded To RAM';

  @override
  String get img2img_seedvr2BlocksToSwapHint =>
      'How many DiT blocks stay in system RAM and are streamed to VRAM during inference. Higher saves VRAM but uses more RAM and runs slower; lower it (even to 0) when VRAM is plentiful. Raise it if you hit out-of-memory errors.';

  @override
  String get img2img_upscalePanelOpened =>
      'Opened the Image2Image Upscale panel';

  @override
  String get editor_done => 'Done';

  @override
  String get editor_tolerance => 'Tolerance';

  @override
  String get editor_intensity => 'Intensity';

  @override
  String get editor_sourcePoint => 'Alt+Click to set source point';

  @override
  String get editor_brushPresets => 'Brush Presets';

  @override
  String get editor_size => 'Size';

  @override
  String get editor_opacity => 'Opacity';

  @override
  String get editor_hardness => 'Hardness';

  @override
  String get editor_undo => 'Undo';

  @override
  String get editor_redo => 'Redo';

  @override
  String get editor_clearLayer => 'Clear Layer';

  @override
  String get editor_resetView => 'Reset View';

  @override
  String get editor_zoom => 'Zoom';

  @override
  String get editor_toolBrush => 'Brush';

  @override
  String get editor_toolEraser => 'Eraser';

  @override
  String get editor_toolFill => 'Fill';

  @override
  String get editor_toolMagicWand => 'Magic Wand';

  @override
  String get editor_magicWandMode => 'Selection method';

  @override
  String get editor_magicWandSmartObject => 'Smart object (EfficientViT)';

  @override
  String get editor_magicWandColorArea => 'Color area (flood fill)';

  @override
  String get editor_magicWandSmartHelp =>
      'Click the object to select. The first use downloads the approximately 133 MiB EfficientViT-SAM L0 model from MIT Han Lab (Apache-2.0), then keeps it locally.';

  @override
  String get editor_magicWandColorHelp =>
      'Click a contiguous region of similar color. This works best on flat, clean boundaries and requires no model download.';

  @override
  String get editor_magicWandInvert => 'Invert result';

  @override
  String get editor_toolLine => 'Line';

  @override
  String get editor_toolRectSelect => 'Rectangle';

  @override
  String get editor_toolEllipseSelect => 'Ellipse';

  @override
  String get editor_toolLassoSelect => 'Lasso';

  @override
  String get editor_toolColorPicker => 'Color Picker';

  @override
  String get editor_toolCloneStamp => 'Clone Stamp';

  @override
  String get editor_toolBlur => 'Blur';

  @override
  String get editor_back => 'Back';

  @override
  String get editor_layers => 'Layers';

  @override
  String get editor_loadMask => 'Load Mask';

  @override
  String get editor_togglePanels => 'Toggle Panels';

  @override
  String get editor_fillClosedRegion => 'Fill Closed Region';

  @override
  String get editor_resetMask => 'Reset Mask';

  @override
  String get editor_zoomIn => 'Zoom In';

  @override
  String get editor_zoomOut => 'Zoom Out';

  @override
  String get editor_fitToWindow => 'Fit to Window';

  @override
  String get editor_shortcutHelpTitle => 'Shortcut Help';

  @override
  String get editor_shortcutPaintTools => 'Paint Tools';

  @override
  String get editor_shortcutSelectionTools => 'Selection Tools';

  @override
  String get editor_shortcutCanvasView => 'Canvas View';

  @override
  String get editor_shortcutBrushAdjust => 'Brush Adjustments';

  @override
  String get editor_shortcutColors => 'Colors';

  @override
  String get editor_shortcutCanvasActions => 'Canvas Actions';

  @override
  String get editor_shortcutHistoryActions => 'History Actions';

  @override
  String get editor_shortcutSelectionActions => 'Selection Actions';

  @override
  String get editor_shortcutTemporaryColorPicker => 'Temporary Color Picker';

  @override
  String get editor_shortcutRectSelection => 'Rectangle Selection';

  @override
  String get editor_shortcutEllipseSelection => 'Ellipse Selection';

  @override
  String get editor_shortcutLassoSelection => 'Lasso Selection';

  @override
  String get editor_shortcut100Zoom => '100% Zoom';

  @override
  String get editor_shortcutFitHeight => 'Fit Height';

  @override
  String get editor_shortcutFitWidth => 'Fit Width';

  @override
  String get editor_shortcutRotateLeft15 => 'Rotate Left 15°';

  @override
  String get editor_shortcutResetRotation => 'Reset Rotation';

  @override
  String get editor_shortcutRotateRight15 => 'Rotate Right 15°';

  @override
  String get editor_shortcutFlipHorizontal => 'Flip Horizontal';

  @override
  String get editor_shortcutWheel => 'Mouse Wheel';

  @override
  String get editor_shortcutBrushSmaller => 'Decrease Brush Size';

  @override
  String get editor_shortcutBrushLarger => 'Increase Brush Size';

  @override
  String get editor_shortcutOpacityLower => 'Decrease Opacity';

  @override
  String get editor_shortcutOpacityHigher => 'Increase Opacity';

  @override
  String get editor_shortcutDragBrushSize => 'Adjust Brush Size';

  @override
  String get editor_shortcutSwapColors => 'Swap Foreground/Background Colors';

  @override
  String get editor_shortcutPanCanvas => 'Pan Canvas';

  @override
  String get editor_shortcutClearSelectionContent => 'Clear Selection Content';

  @override
  String get editor_shortcutCancelCurrentAction => 'Cancel Current Action';

  @override
  String get editor_selectUnlockedLayerWithContent =>
      'Select an unlocked layer with content';

  @override
  String get editor_readCurrentLayerFailed =>
      'Failed to read the current layer';

  @override
  String get editor_localEffects => 'Local Post-processing / Effects';

  @override
  String get editor_basicAdjustments => 'Basic Adjustments';

  @override
  String get editor_styleAndRepair => 'Style & Repair';

  @override
  String get editor_transformCrop => 'Rotate / Flip / Crop';

  @override
  String get editor_transformCropDescription =>
      'Geometry operations are separate. They generate a preview first and write back only after confirmation.';

  @override
  String get editor_effectPreviewHint =>
      'Preview does not modify the original image. Click Apply to write the result to the active layer and undo history.';

  @override
  String get editor_applyToCurrentLayer => 'Apply to Current Layer';

  @override
  String editor_oneShotEffectHint(Object effect) {
    return '$effect is a one-shot operation and has no intensity slider.';
  }

  @override
  String editor_effectIntensity(Object effect) {
    return '$effect Intensity';
  }

  @override
  String get editor_original => 'Original';

  @override
  String get editor_effectPreview => 'Effect Preview';

  @override
  String get editor_effectBrightness => 'Brightness';

  @override
  String get editor_effectContrast => 'Contrast';

  @override
  String get editor_effectSaturation => 'Saturation';

  @override
  String get editor_effectTemperature => 'Temperature';

  @override
  String get editor_effectGamma => 'Gamma';

  @override
  String get editor_effectGrayscale => 'Grayscale';

  @override
  String get editor_effectInvert => 'Invert';

  @override
  String get editor_effectSepia => 'Sepia';

  @override
  String get editor_effectDenoise => 'Denoise';

  @override
  String get editor_effectBlur => 'Gaussian Blur';

  @override
  String get editor_effectSharpen => 'Sharpen';

  @override
  String get editor_effectCropToSelection => 'Crop to Selection';

  @override
  String get editor_effectRotateLeft => 'Rotate Left 90°';

  @override
  String get editor_effectRotateRight => 'Rotate Right 90°';

  @override
  String get editor_effectFlipHorizontal => 'Flip Horizontal';

  @override
  String get editor_effectFlipVertical => 'Flip Vertical';

  @override
  String editor_effectApplied(Object effect) {
    return 'Applied $effect';
  }

  @override
  String editor_applyEffectFailed(Object error) {
    return 'Failed to apply effect: $error';
  }

  @override
  String get editor_changeCanvasSize => 'Change Canvas Size';

  @override
  String editor_canvasTooSmall(Object width, Object height) {
    return 'Canvas size is too small. Minimum size is $width x $height pixels';
  }

  @override
  String editor_canvasTooLarge(Object width, Object height) {
    return 'Canvas size is too large. Maximum size is $width x $height pixels';
  }

  @override
  String editor_canvasResized(Object width, Object height) {
    return 'Canvas resized to $width x $height';
  }

  @override
  String editor_canvasResizeFailed(Object error) {
    return 'Failed to resize canvas: $error';
  }

  @override
  String get editor_confirmExitTitle => 'Confirm Exit';

  @override
  String get editor_confirmExitContent =>
      'There are unsaved changes. Are you sure you want to exit?';

  @override
  String get editor_exit => 'Exit';

  @override
  String get editor_saveAndExit => 'Save and Exit';

  @override
  String editor_exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get editor_clickInsideClosedRegion =>
      'Click inside a closed region to fill it.';

  @override
  String get editor_drawClosedMaskOutlineFirst =>
      'Draw a closed mask outline first.';

  @override
  String get editor_noClosedRegionAtPosition =>
      'No fillable closed region at this position.';

  @override
  String get editor_generateMaskOverlayFailed =>
      'Failed to generate mask overlay';

  @override
  String get editor_maskLayerName => 'Mask';

  @override
  String get editor_updateMaskLayerFailed => 'Failed to update mask layer';

  @override
  String get editor_closedRegionFilled => 'Closed region filled as mask.';

  @override
  String editor_fillMaskFailed(Object error) {
    return 'Failed to fill mask: $error';
  }

  @override
  String get editor_magicWandNoSource =>
      'No editable image layer is available for sampling.';

  @override
  String get editor_magicWandNothingChanged =>
      'The selected region is already transparent or masked.';

  @override
  String get editor_magicWandModelPreparing =>
      'Checking the EfficientViT-SAM model…';

  @override
  String editor_magicWandModelDownloading(int percent) {
    return 'Downloading the EfficientViT-SAM model: $percent%';
  }

  @override
  String get editor_magicWandModelLoading =>
      'Loading the EfficientViT-SAM model…';

  @override
  String get editor_magicWandEncoding => 'Analyzing image objects…';

  @override
  String get editor_magicWandSegmenting =>
      'Segmenting the object at the clicked point…';

  @override
  String get editor_magicWandPostprocessing => 'Building the selection…';

  @override
  String editor_magicWandFailed(Object error) {
    return 'Magic Wand failed: $error';
  }

  @override
  String get editor_compressionTitle => 'Output resolution';

  @override
  String get editor_compressionTooltip => 'Choose output resolution';

  @override
  String get editor_compressionUncompressed =>
      'Original work resolution; no compression will be applied.';

  @override
  String get editor_compressionApplyOnDone =>
      'Pica Lanczos3 compression runs once when you press Done. The work canvas stays unchanged.';

  @override
  String editor_compressionSizeSummary(
    int workWidth,
    int workHeight,
    int targetWidth,
    int targetHeight,
  ) {
    return 'Work $workWidth×$workHeight → output $targetWidth×$targetHeight';
  }

  @override
  String editor_compressionNormalSummary(
    int normalWidth,
    int normalHeight,
    int minimumWidth,
    int minimumHeight,
  ) {
    return 'Normal (about 1 MP): $normalWidth×$normalHeight. Lowest: $minimumWidth×$minimumHeight.';
  }

  @override
  String get editor_compressionUnavailable =>
      'This work canvas is already below the lowest compression step.';

  @override
  String editor_unsupportedImageFormat(Object extension) {
    return 'Unsupported file format: .$extension\nPlease choose an image file (PNG, JPG, WEBP, etc.)';
  }

  @override
  String editor_readFileFailed(Object error) {
    return 'Failed to read file: $error';
  }

  @override
  String get editor_noFileData => 'Failed to get file data';

  @override
  String get editor_emptyImageFile =>
      'File is empty. Choose a valid image file';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return 'File is too large ($sizeMB MB). Choose an image under 50 MB';
  }

  @override
  String get editor_maskLayerAdded => 'Mask layer added';

  @override
  String get editor_parseImageFailed =>
      'Failed to parse image file\nMake sure the file is not corrupted and the format is supported';

  @override
  String editor_loadMaskFailed(Object error) {
    return 'Failed to load mask: $error';
  }

  @override
  String get editor_defaultTitle => 'Canvas';

  @override
  String get editor_baseLayerName => 'Base Image';

  @override
  String get editor_existingMaskLayerName => 'Existing Mask';

  @override
  String get editor_defaultDrawingLayerName => 'Layer 1';

  @override
  String editor_layerName(Object count) {
    return 'Layer $count';
  }

  @override
  String get editor_canvasSizeTitle => 'Canvas Size';

  @override
  String get editor_presetSize => 'Preset Size';

  @override
  String get editor_customSize => 'Custom';

  @override
  String get editor_contentHandling => 'Content Handling';

  @override
  String get editor_contentCrop => 'Crop';

  @override
  String get editor_contentPad => 'Pad';

  @override
  String get editor_contentStretch => 'Stretch';

  @override
  String get editor_width => 'Width';

  @override
  String get editor_height => 'Height';

  @override
  String get editor_lockAspectRatio => 'Lock aspect ratio';

  @override
  String get editor_unlockAspectRatio => 'Unlock aspect ratio';

  @override
  String get editor_sizePreview => 'Size Preview';

  @override
  String get editor_originalSize => 'Original';

  @override
  String get editor_newSize => 'New Size';

  @override
  String get editor_cropModeDescription =>
      'Crop mode - keep aspect ratio and crop';

  @override
  String get editor_padModeDescription =>
      'Pad mode - keep aspect ratio and pad';

  @override
  String get editor_stretchModeDescription => 'Stretch mode - stretch to fill';

  @override
  String editor_canvasPresetSquare(Object size) {
    return 'Square $size';
  }

  @override
  String editor_canvasPresetLandscape(Object ratio) {
    return 'Landscape $ratio';
  }

  @override
  String editor_canvasPresetPortrait(Object ratio) {
    return 'Portrait $ratio';
  }

  @override
  String get editor_canvasPresetNaiPortrait => 'NAI Portrait';

  @override
  String get editor_canvasPresetNaiLandscape => 'NAI Landscape';

  @override
  String get editor_canvasPresetFullHd => 'Full HD 16:9';

  @override
  String get editor_colorPanelTitle => 'Color';

  @override
  String get editor_colorPickerTitle => 'Choose Color';

  @override
  String get editor_brushSettings => 'Brush Settings';

  @override
  String get editor_eraserSettings => 'Eraser Settings';

  @override
  String get editor_colorPickerHint =>
      'Click anywhere on the canvas to pick a color. Release to switch back to the previous tool.';

  @override
  String get editor_sample => 'Sample';

  @override
  String get editor_samplePoint => 'Point';

  @override
  String get editor_sampleArea => 'Area';

  @override
  String get editor_source => 'Source';

  @override
  String get editor_sourceCurrentLayer => 'Current Layer';

  @override
  String get editor_sourceAllLayers => 'All Layers';

  @override
  String get editor_lassoSelectionHelp =>
      'Hold and drag to draw a freeform selection. Release to close it automatically.';

  @override
  String get layer_empty => 'No layers';

  @override
  String get layer_add => 'Add Layer';

  @override
  String get layer_mergeDown => 'Merge Down';

  @override
  String get layer_duplicate => 'Duplicate';

  @override
  String get layer_delete => 'Delete';

  @override
  String get layer_merge => 'Merge Down';

  @override
  String get layer_visibility => 'Toggle Visibility';

  @override
  String get layer_lock => 'Toggle Lock';

  @override
  String get layer_rename => 'Rename';

  @override
  String get layer_moveUp => 'Move Up';

  @override
  String get layer_moveDown => 'Move Down';

  @override
  String get vibe_title => 'Vibe Transfer';

  @override
  String get vibe_description => 'Change the image, keep the vision.';

  @override
  String get vibe_addFromFileTitle => 'Add from File';

  @override
  String get vibe_addFromFileSubtitle => 'PNG, JPG, Vibe files';

  @override
  String get vibe_addFromLibraryTitle => 'Import from Library';

  @override
  String get vibe_addFromLibrarySubtitle => 'Select from Vibe Library';

  @override
  String get vibe_addReference => 'Add Reference';

  @override
  String get vibe_clearAll => 'Clear All';

  @override
  String vibe_cleared(int count) {
    return 'Cleared $count vibes';
  }

  @override
  String get vibe_referenceStrength => 'Ref Strength';

  @override
  String get vibe_infoExtraction => 'Information Extracted';

  @override
  String get vibe_remove => 'Remove';

  @override
  String get reference_enabled => 'Enabled';

  @override
  String get reference_enable => 'Enable reference';

  @override
  String get reference_disable => 'Disable reference';

  @override
  String get vibe_normalize => 'Normalize Reference Strength Values';

  @override
  String get vibe_sourceType_png => 'PNG';

  @override
  String get vibe_sourceType_v4vibe => 'V4 Vibe';

  @override
  String get vibe_sourceType_bundle => 'Bundle';

  @override
  String get vibe_sourceType_image => 'Image';

  @override
  String get vibe_sourceType => 'Source';

  @override
  String get vibe_reuseButton => 'Reuse';

  @override
  String get vibe_info => 'Vibe Info';

  @override
  String get vibe_name => 'Name';

  @override
  String get vibe_strength => 'Strength';

  @override
  String get vibe_infoExtracted => 'Information Extracted';

  @override
  String get vibe_shiftReplaceHint => 'Shift+Click to Replace';

  @override
  String get character_buttonLabel => 'Char/Position';

  @override
  String get character_addCharacter => 'Add Character';

  @override
  String character_number(Object index) {
    return 'Character $index';
  }

  @override
  String get gallery_generationParams => 'Generation Parameters';

  @override
  String get gallery_metaModel => 'Model';

  @override
  String get gallery_metaResolution => 'Resolution';

  @override
  String get gallery_metaSteps => 'Steps';

  @override
  String get gallery_metaSampler => 'Sampler';

  @override
  String get gallery_metaCfgScale => 'Prompt Guidance';

  @override
  String get gallery_metaSeed => 'Seed';

  @override
  String get gallery_metaSmea => 'SMEA';

  @override
  String get gallery_promptCopied => 'Prompt copied';

  @override
  String get gallery_seedCopied => 'Seed copied';

  @override
  String get gallery_sendToKritaAction => 'Send to Krita';

  @override
  String get gallery_upscalePanelLoaded =>
      'Loaded the Image2Image Upscale panel';

  @override
  String gallery_readImageFailed(Object error) {
    return 'Failed to read image: $error';
  }

  @override
  String get gallery_fileMissing => 'File does not exist';

  @override
  String get gallery_copiedToClipboard => 'Copied to clipboard';

  @override
  String gallery_copyFailed(Object error) {
    return 'Copy failed: $error';
  }

  @override
  String get gallery_upscale => 'Upscale';

  @override
  String get gallery_sentToImg2Img => 'Image sent to Image2Image';

  @override
  String gallery_sendFailed(Object error) {
    return 'Send failed: $error';
  }

  @override
  String get onlineGallery_search => 'Search';

  @override
  String get onlineGallery_popular => 'Popular';

  @override
  String get onlineGallery_favorites => 'Favorites';

  @override
  String get onlineGallery_refresh => 'Refresh';

  @override
  String get onlineGallery_login => 'Login';

  @override
  String get onlineGallery_logout => 'Logout';

  @override
  String get onlineGallery_dayRank => 'Day';

  @override
  String get onlineGallery_weekRank => 'Week';

  @override
  String get onlineGallery_monthRank => 'Month';

  @override
  String get onlineGallery_today => 'Today';

  @override
  String onlineGallery_imageCount(Object count) {
    return '$count images';
  }

  @override
  String get onlineGallery_loadFailed => 'Load failed';

  @override
  String get onlineGallery_favoritesEmpty => 'Favorites is empty';

  @override
  String get onlineGallery_noResults => 'No images found';

  @override
  String get onlineGallery_pleaseLogin => 'Please login first';

  @override
  String get onlineGallery_size => 'Size';

  @override
  String get onlineGallery_score => 'Score';

  @override
  String get onlineGallery_favCount => 'Favorites';

  @override
  String get onlineGallery_type => 'Type';

  @override
  String get mediaType_video => 'Video';

  @override
  String get mediaType_gif => 'GIF';

  @override
  String get onlineGallery_tags => 'Tags';

  @override
  String get onlineGallery_artists => 'Artists';

  @override
  String get onlineGallery_characters => 'Characters';

  @override
  String get onlineGallery_copyrights => 'Copyrights';

  @override
  String get onlineGallery_general => 'General';

  @override
  String get onlineGallery_copied => 'Copied';

  @override
  String get onlineGallery_copyTags => 'Copy Tags';

  @override
  String get onlineGallery_open => 'Open';

  @override
  String get onlineGallery_send => 'Send';

  @override
  String get onlineGallery_sendToTextToImage => 'Send to Text to Image';

  @override
  String get onlineGallery_sentToTextToImage => 'Sent to text-to-image';

  @override
  String get onlineGallery_noTagInfo => 'This image has no tag information';

  @override
  String get onlineGallery_promptSentToGeneration =>
      'Prompt sent to generation page';

  @override
  String get onlineGallery_gifLoadFailed => 'Failed to load GIF';

  @override
  String get onlineGallery_pinchToZoom => 'Pinch to zoom';

  @override
  String get onlineGallery_metadata => 'Metadata';

  @override
  String get onlineGallery_chooseDownloadDirectory =>
      'Choose Download Directory';

  @override
  String get onlineGallery_downloadStarted => 'Download started...';

  @override
  String onlineGallery_savedToPath(Object path) {
    return 'Saved to: $path';
  }

  @override
  String onlineGallery_downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get onlineGallery_downloadOriginal => 'Download original image';

  @override
  String get onlineGallery_all => 'All';

  @override
  String get onlineGallery_ratingGeneral => 'General';

  @override
  String get onlineGallery_ratingSensitive => 'Sensitive';

  @override
  String get onlineGallery_ratingQuestionable => 'Questionable';

  @override
  String get onlineGallery_ratingExplicit => 'Explicit';

  @override
  String get onlineGallery_clear => 'Clear';

  @override
  String get onlineGallery_previousPage => 'Previous Page';

  @override
  String get onlineGallery_nextPage => 'Next Page';

  @override
  String onlineGallery_pageN(Object page) {
    return 'Page $page';
  }

  @override
  String get onlineGallery_dateRange => 'Date Range';

  @override
  String get onlineGallery_fuzzySearch => 'Fuzzy Match';

  @override
  String get onlineGallery_fuzzySearchTooltip =>
      'Use *tag* matching for related tags when enabled; search exact Danbooru tags when disabled';

  @override
  String get onlineGallery_blacklistTags => 'Blacklist Tags';

  @override
  String get onlineGallery_blacklistTitle => 'Online Gallery Blacklist';

  @override
  String get onlineGallery_blacklistSubtitle =>
      'Images containing blacklisted tags will be hidden directly in the online gallery.';

  @override
  String get onlineGallery_addBlacklistTagHint => 'Add blacklist tag';

  @override
  String get onlineGallery_noLocalBlacklistTags => 'No local blacklist tags';

  @override
  String get onlineGallery_autoSyncOnStartup => 'Auto-sync on startup';

  @override
  String get onlineGallery_autoSyncOnStartupSubtitle =>
      'Enabled by default; you can turn it off at any time';

  @override
  String onlineGallery_lastSyncFailed(Object error) {
    return 'Last sync failed: $error';
  }

  @override
  String get onlineGallery_neverSyncedBlacklist =>
      'Danbooru blacklist has not been synced yet';

  @override
  String onlineGallery_lastSync(Object time) {
    return 'Last sync: $time';
  }

  @override
  String get onlineGallery_blacklistSettingsTitle =>
      'Online Gallery Blacklist Settings';

  @override
  String get onlineGallery_blacklistLoginHint =>
      'You are not logged in to Danbooru. The local blacklist still works, but syncing requires login.';

  @override
  String get onlineGallery_bulkFavorite => 'Favorite Selected';

  @override
  String get onlineGallery_bulkDownload => 'Download Selected';

  @override
  String get onlineGallery_unfavorited => 'Unfavorited';

  @override
  String get onlineGallery_favorited => 'Favorited';

  @override
  String onlineGallery_favoritedImages(Object count) {
    return 'Favorited $count images';
  }

  @override
  String onlineGallery_selectDownloadDirectoryFailed(Object error) {
    return 'Failed to choose download directory: $error';
  }

  @override
  String onlineGallery_downloadSelectedStarted(Object count) {
    return 'Downloading $count images...';
  }

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return 'Download complete: $success succeeded, $failed failed';
  }

  @override
  String get onlineGallery_startDate => 'Start Date';

  @override
  String get onlineGallery_endDate => 'End Date';

  @override
  String get onlineGallery_invalidDateFormat => 'Invalid date format';

  @override
  String get onlineGallery_dateOutOfRange => 'Date out of range';

  @override
  String get onlineGallery_last30Days => 'Last 30 Days';

  @override
  String get onlineGallery_configureGelbooruApi => 'Configure Gelbooru API';

  @override
  String get onlineGallery_gelbooruApiReady => 'Gelbooru API verified';

  @override
  String get onlineGallery_gelbooruApiInvalid => 'Gelbooru credentials expired';

  @override
  String get onlineGallery_gelbooruCredentialsRequired =>
      'Configure your Gelbooru User ID and API Key to view website favorites.';

  @override
  String get onlineGallery_gelbooruCredentialsInvalid =>
      'Your Gelbooru credentials are no longer valid. Configure them again.';

  @override
  String get onlineGallery_gelbooruRateLimited =>
      'Gelbooru is rate limiting requests. Try again later.';

  @override
  String get onlineGallery_gelbooruTimeout =>
      'The Gelbooru request timed out. Check your network connection.';

  @override
  String get onlineGallery_gelbooruServerError =>
      'Gelbooru is temporarily unavailable. Try again later.';

  @override
  String get onlineGallery_gelbooruNetworkError =>
      'Could not connect to Gelbooru. Check your network or proxy settings.';

  @override
  String get onlineGallery_gelbooruMalformedResponse =>
      'Gelbooru returned data that could not be parsed.';

  @override
  String get onlineGallery_gelbooruRequestFailed =>
      'The Gelbooru request failed. Try again later.';

  @override
  String get onlineGallery_aiTagQuery =>
      'Search works, artists, titles, tags, or models';

  @override
  String get onlineGallery_aiTagPromptQuery =>
      'AI Prompt search (raw syntax such as ::artist: is supported)';

  @override
  String get onlineGallery_aiTagTimeRange => 'Time range';

  @override
  String get onlineGallery_aiTagAllTime => 'All';

  @override
  String get onlineGallery_aiTagCurrentMonthly => 'Live monthly ranking';

  @override
  String get onlineGallery_aiTagOlderMonthly => 'Older archive';

  @override
  String get onlineGallery_aiTagRankingProcessing =>
      'The ranking is being generated. Please try again shortly.';

  @override
  String get onlineGallery_aiTagNaiOnly => 'NAI only';

  @override
  String get onlineGallery_aiTagModelVersion => 'Model version';

  @override
  String get onlineGallery_viewAuthor => 'View this author';

  @override
  String get onlineGallery_returnFromAuthor =>
      'Return to previous gallery position';

  @override
  String get onlineGallery_generationParams => 'Generation parameters';

  @override
  String get onlineGallery_sourceConfigUnavailable =>
      'Could not load source configuration. Check your connection and retry.';

  @override
  String get onlineGallery_sourceRateLimited =>
      'Too many requests. Please try again later.';

  @override
  String get onlineGallery_sourceTimeout =>
      'The request timed out. Check your connection.';

  @override
  String get onlineGallery_sourceNetworkError =>
      'Could not connect to this gallery source. Check your network or proxy.';

  @override
  String get onlineGallery_sourceMalformedResponse =>
      'The source response format has changed and cannot be parsed.';

  @override
  String get onlineGallery_detailNotFound =>
      'This work does not exist or has been removed.';

  @override
  String get onlineGallery_imageUnavailable =>
      'This image is currently unavailable.';

  @override
  String get onlineGallery_loadedAll => 'All items loaded';

  @override
  String get onlineGallery_retryAppend => 'Load failed. Click to retry';

  @override
  String onlineGallery_rankNumber(Object rank) {
    return 'Rank #$rank';
  }

  @override
  String onlineGallery_multipleImages(Object count) {
    return '$count images';
  }

  @override
  String get onlineGallery_views => 'Views';

  @override
  String get onlineGallery_downloadAllMedia =>
      'Download all images in this work';

  @override
  String get onlineGallery_copyFullMetadata => 'Copy full metadata';

  @override
  String get onlineGallery_metadataParseFailed =>
      'Metadata parsing failed. The original content is preserved and can be copied.';

  @override
  String get onlineGallery_gelbooruReadOnly => 'Read-only favorites';

  @override
  String get onlineGallery_gelbooruFavoritesSortHint =>
      'Sorted by post ID, newest first. This may differ from website favorite-time order.';

  @override
  String get tooltip_fullscreenEdit => 'Fullscreen Edit';

  @override
  String get tooltip_decreaseWeight => 'Decrease Weight [-5%]';

  @override
  String get tooltip_increaseWeight => 'Increase Weight [+5%]';

  @override
  String get tooltip_resetWeight => 'Click to reset to 100%';

  @override
  String get upscale_scale => 'Scale Factor';

  @override
  String get danbooru_loginTitle => 'Login Danbooru';

  @override
  String get danbooru_loginHint =>
      'Login with username and API Key to use favorites';

  @override
  String get danbooru_username => 'Username';

  @override
  String get danbooru_usernameHint => 'Enter Danbooru username';

  @override
  String get danbooru_usernameRequired => 'Please enter username';

  @override
  String get danbooru_apiKeyHint => 'Enter API Key';

  @override
  String get danbooru_apiKeyRequired => 'Please enter API Key';

  @override
  String get danbooru_howToGetApiKey => 'How to get API Key?';

  @override
  String get danbooru_loginSuccess => 'Login successful';

  @override
  String get gelbooru_configureTitle => 'Configure Gelbooru API';

  @override
  String get gelbooru_configureHint =>
      'Enter the User ID and API Key shown in your Gelbooru account settings. The app does not collect your password or browser cookies.';

  @override
  String get gelbooru_userId => 'User ID';

  @override
  String get gelbooru_userIdHint => 'Enter a positive numeric User ID';

  @override
  String get gelbooru_userIdRequired =>
      'Enter a valid positive numeric User ID';

  @override
  String get gelbooru_apiKeyHint => 'Enter API Key';

  @override
  String get gelbooru_apiKeyRequired => 'Enter an API Key';

  @override
  String get gelbooru_openAccountSettings => 'Open Gelbooru account settings';

  @override
  String get gelbooru_save => 'Verify and Save';

  @override
  String get gelbooru_saved => 'Gelbooru credentials saved';

  @override
  String get gelbooru_removeCredentials => 'Remove Credentials';

  @override
  String get gelbooru_invalidInput => 'Enter a valid User ID and API Key.';

  @override
  String get gelbooru_invalidCredentials =>
      'Gelbooru rejected these credentials. Check the User ID and API Key.';

  @override
  String get gelbooru_rateLimited => 'Too many requests. Try again later.';

  @override
  String get gelbooru_timeout =>
      'Verification timed out. Check your network connection.';

  @override
  String get gelbooru_serverError => 'Gelbooru is temporarily unavailable.';

  @override
  String get gelbooru_networkError =>
      'Could not connect to Gelbooru. Check your network or proxy settings.';

  @override
  String get gelbooru_malformedResponse =>
      'Gelbooru returned data that could not be parsed.';

  @override
  String get gelbooru_storageError =>
      'Gelbooru credentials could not be stored or read securely.';

  @override
  String get gelbooru_unknownError =>
      'Gelbooru verification failed. Try again later.';

  @override
  String get tag_addTag => 'Add Tag';

  @override
  String get qualityTags_label => 'Quality';

  @override
  String get transparentBackground_tooltip =>
      'Adds \"transparent background\" to the prompt and generates images with an alpha channel (V5 only)';

  @override
  String get qualityTags_positive => 'Quality (Prompt)';

  @override
  String get qualityTags_negative => 'Quality (Undesired Content)';

  @override
  String get qualityTags_disabled => 'Quality tags disabled\nClick to enable';

  @override
  String get qualityTags_addToEnd => 'Add to prompt end:';

  @override
  String get qualityTags_addToStart => 'Add to prompt start:';

  @override
  String get qualityTags_naiDefault => 'NAI Default';

  @override
  String get qualityTags_standard => 'Standard';

  @override
  String get qualityTags_light => 'Light';

  @override
  String get qualityTags_none => 'None';

  @override
  String get ucPreset_label => 'Undesired Content Preset';

  @override
  String get ucPreset_heavy => 'Heavy';

  @override
  String get ucPreset_light => 'Light';

  @override
  String get ucPreset_furryFocus => 'Furry';

  @override
  String get ucPreset_humanFocus => 'Human';

  @override
  String get ucPreset_lowQuality => 'Low Quality';

  @override
  String get ucPreset_badAnatomy => 'Bad Anatomy';

  @override
  String get ucPreset_none => 'None';

  @override
  String get ucPreset_disabled => 'Undesired content preset disabled';

  @override
  String get ucPreset_addToNegative => 'Add to Undesired Content:';

  @override
  String get ucPreset_nsfwHint =>
      '💡 To generate adult content, add nsfw to your prompt. The nsfw tag will be auto-removed from Undesired Content';

  @override
  String get generation_imageCount => 'Number of Images';

  @override
  String get generation_requestCountTooltip =>
      'Requests: each click sends N generation requests';

  @override
  String generation_imageCountTotal(int requests, int perRequest, int total) {
    return '$requests requests × $perRequest images = $total total';
  }

  @override
  String get warmup_networkCheck => 'Checking network connection...';

  @override
  String get warmup_networkCheck_noProxy =>
      'Cannot connect to NovelAI, please enable VPN or proxy settings';

  @override
  String get warmup_networkCheck_noSystemProxy =>
      'Proxy enabled but no system proxy detected, please enable VPN';

  @override
  String get warmup_networkCheck_manualIncomplete =>
      'Manual proxy config incomplete, please check settings';

  @override
  String get warmup_networkCheck_testing => 'Testing network connection...';

  @override
  String get warmup_networkCheck_testingProxy => 'Testing network via proxy...';

  @override
  String warmup_networkCheck_success(Object latency) {
    return 'Network connection OK (${latency}ms)';
  }

  @override
  String get warmup_networkCheck_timeout =>
      'Network check timeout, continuing offline';

  @override
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts) {
    return 'Checking network... (attempt $attempt/$maxAttempts)';
  }

  @override
  String get warmup_preparing => 'Preparing...';

  @override
  String get warmup_complete => 'Complete';

  @override
  String get warmup_danbooruAuth => 'Initializing Danbooru authentication...';

  @override
  String get warmup_loadingTranslation => 'Loading translation data...';

  @override
  String get warmup_initUnifiedDatabase => 'Initializing tag database...';

  @override
  String get warmup_initTagSystem => 'Initializing tag system...';

  @override
  String get warmup_imageEditor => 'Initializing image editor...';

  @override
  String get warmup_database => 'Loading recent history...';

  @override
  String get warmup_network => 'Checking network connection...';

  @override
  String get warmup_fonts => 'Preloading fonts...';

  @override
  String get warmup_imageCache => 'Warming up image cache...';

  @override
  String get warmup_statistics => 'Loading statistics...';

  @override
  String get warmup_artistsSync => 'Syncing artists data...';

  @override
  String get warmup_subscription => 'Loading subscription info...';

  @override
  String get warmup_dataSourceCache => 'Initializing data source cache...';

  @override
  String get warmup_galleryFileCount => 'Scanning gallery files...';

  @override
  String get warmup_cooccurrenceData => 'Loading tag cooccurrence data...';

  @override
  String get warmup_group_basicUI => 'Initializing basic UI services...';

  @override
  String get warmup_group_basicUI_complete => 'Basic UI services ready';

  @override
  String get warmup_group_dataServices => 'Initializing data services...';

  @override
  String get warmup_group_dataServices_complete => 'Data services ready';

  @override
  String get warmup_group_networkServices => 'Initializing network services...';

  @override
  String get warmup_group_networkServices_complete => 'Network services ready';

  @override
  String get warmup_group_cacheServices => 'Initializing cache services...';

  @override
  String get warmup_group_cacheServices_complete => 'Cache services ready';

  @override
  String get warmup_cooccurrenceInit => 'Initializing cooccurrence data...';

  @override
  String get warmup_translationInit => 'Initializing translation data...';

  @override
  String get warmup_danbooruTagsInit => 'Initializing Danbooru tags...';

  @override
  String get warmup_dataMigration => 'Migrating Hive / Vibe / image data...';

  @override
  String get warmup_galleryDataSource => 'Initializing gallery index...';

  @override
  String get warmup_checkAndRecoverData => 'Checking data integrity...';

  @override
  String get warmup_group_dataSourceInitialization =>
      'Initializing data source services...';

  @override
  String get warmup_group_dataSourceInitialization_complete =>
      'Data source services ready';

  @override
  String warmup_fetchingTags(Object message) {
    return 'Syncing tags: $message';
  }

  @override
  String get warmup_fetchingTagDataFromServer =>
      'Fetching tag data from server...';

  @override
  String get warmup_fetchingGeneralTags => 'Fetching general tags...';

  @override
  String get warmup_fetchingCharacterTags => 'Fetching character tags...';

  @override
  String get warmup_fetchingCopyrightTags => 'Fetching copyright tags...';

  @override
  String get warmup_fetchingMetaTags => 'Fetching meta tags...';

  @override
  String get resolution_groupNormal => 'NORMAL';

  @override
  String get resolution_groupLarge => 'LARGE';

  @override
  String get resolution_groupWallpaper => 'WALLPAPER';

  @override
  String get resolution_groupSmall => 'SMALL';

  @override
  String get resolution_groupCustom => 'CUSTOM';

  @override
  String get resolution_typePortrait => 'Portrait';

  @override
  String get resolution_typeLandscape => 'Landscape';

  @override
  String get resolution_typeSquare => 'Square';

  @override
  String get resolution_typeCustom => 'Custom';

  @override
  String get resolution_width => 'Width';

  @override
  String get resolution_height => 'Height';

  @override
  String get api_error_429 => 'Concurrency limit reached';

  @override
  String get api_error_429_hint =>
      'Too many requests. Please wait and try again (common with shared accounts)';

  @override
  String get api_error_401 => 'Authentication failed';

  @override
  String get api_error_401_hint =>
      'Token invalid or expired. Please login again';

  @override
  String get api_error_402 => 'Insufficient balance';

  @override
  String get api_error_402_hint =>
      'Insufficient Anlas. Please top up and try again';

  @override
  String get api_error_500 => 'Server error';

  @override
  String get api_error_500_hint =>
      'NovelAI server error. Please try again later';

  @override
  String get api_error_503 => 'Service unavailable';

  @override
  String get api_error_503_hint =>
      'Server is under maintenance or overloaded. Please try again later';

  @override
  String get api_error_timeout => 'Request timeout';

  @override
  String get api_error_timeout_hint =>
      'Network timeout. Please check your connection and try again';

  @override
  String get api_error_network => 'Network error';

  @override
  String get api_error_network_hint =>
      'Cannot connect to server. Please check your network';

  @override
  String get drop_processing => 'Processing image...';

  @override
  String get characterEditor_clearAll => 'Clear All';

  @override
  String get characterEditor_clearAllTitle => 'Clear All Characters';

  @override
  String get characterEditor_clearAllConfirm =>
      'Are you sure you want to delete all characters? This action cannot be undone.';

  @override
  String get characterEditor_nameHint => 'Enter character name';

  @override
  String get characterEditor_enabled => 'Enabled';

  @override
  String get characterEditor_negativePromptHint =>
      'Enter Undesired Content for this character...';

  @override
  String get characterCanvas_title => 'Character Positions';

  @override
  String get characterCanvas_finishEditing => 'Finish Editing Positions';

  @override
  String get characterCanvas_aiChoice => 'AI\'s Choice';

  @override
  String get characterCanvas_custom => 'Custom';

  @override
  String get characterCanvas_aiHint =>
      'AI will place all characters automatically';

  @override
  String get characterCanvas_dragHint =>
      'Drag anchors to position characters; release to apply';

  @override
  String get characterEditor_genderFemale => 'Female';

  @override
  String get characterEditor_genderMale => 'Male';

  @override
  String get characterEditor_genderOther => 'Other';

  @override
  String get characterEditor_addFemale => 'F';

  @override
  String get characterEditor_addMale => 'M';

  @override
  String get characterEditor_addOther => 'Other';

  @override
  String get characterEditor_moveUp => 'Move Up';

  @override
  String get characterEditor_moveDown => 'Move Down';

  @override
  String get toolbar_fullscreenEdit => 'Fullscreen Edit';

  @override
  String get characterTooltip_noCharacters => 'No characters configured';

  @override
  String get characterTooltip_clickToConfig =>
      'Click to configure multi-character prompts';

  @override
  String get characterTooltip_globalAiLabel => 'Global AI Position:';

  @override
  String get characterTooltip_enabled => 'Enabled';

  @override
  String get characterTooltip_disabled => 'Disabled';

  @override
  String get characterTooltip_positionAi => 'AI';

  @override
  String get characterTooltip_disabledLabel => 'Disabled';

  @override
  String get characterTooltip_promptLabel => 'Prompt';

  @override
  String get characterTooltip_negativeLabel => 'Undesired Content';

  @override
  String get characterTooltip_notSet => 'Not set';

  @override
  String characterTooltip_summary(Object total, Object enabled) {
    return '$total characters ($enabled enabled)';
  }

  @override
  String get characterTooltip_viewFullConfig => 'Click for full configuration';

  @override
  String get addGroup_displayNameLabel => 'Display Name (Optional)';

  @override
  String get addGroup_targetCategoryLabel => 'Target Category';

  @override
  String globalSettings_saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get nav_generate => 'Generate';

  @override
  String get nav_gallery => 'Gallery';

  @override
  String get nav_settings => 'Settings';

  @override
  String get sync_preparing => 'Preparing to sync...';

  @override
  String sync_fetching(Object category) {
    return 'Fetching $category...';
  }

  @override
  String get sync_processing => 'Processing data...';

  @override
  String get sync_saving => 'Saving...';

  @override
  String sync_completed(Object count) {
    return 'Sync completed, $count tags';
  }

  @override
  String sync_failed(Object error) {
    return 'Sync failed: $error';
  }

  @override
  String sync_extracting(Object poolName) {
    return 'Extracting $poolName tags...';
  }

  @override
  String get sync_merging => 'Merging tags...';

  @override
  String sync_fetching_tags(Object groupName) {
    return 'Fetching $groupName tag popularity...';
  }

  @override
  String get sync_filtering => 'Filtering tags...';

  @override
  String get sync_done => 'Sync completed';

  @override
  String get time_just_now => 'Just now';

  @override
  String time_minutes_ago(Object n) {
    return '$n minutes ago';
  }

  @override
  String time_hours_ago(Object n) {
    return '$n hours ago';
  }

  @override
  String time_days_ago(Object n) {
    return '$n days ago';
  }

  @override
  String get time_never_synced => 'Never synced';

  @override
  String get vibeParseFailed => 'Failed to parse Vibe file';

  @override
  String get localGallery_progressiveLoadError => 'Failed to load image';

  @override
  String get localGallery_unknownError => 'Unknown error';

  @override
  String localGallery_loadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get localGallery_indexingLocalImages => 'Indexing local images...';

  @override
  String get localGallery_emptyTitle => 'No local images';

  @override
  String get localGallery_emptySubtitle =>
      'Generated images will be saved here';

  @override
  String get localGallery_noMatchingResults => 'No matching results';

  @override
  String get localGallery_title => 'Local Gallery';

  @override
  String get localGallery_allImages => 'All Images';

  @override
  String get localGallery_selectAllResults => 'Select All';

  @override
  String get localGallery_deselectAllResults => 'Deselect All';

  @override
  String get localGallery_moveSelected => 'Move';

  @override
  String get localGallery_packSelected => 'Pack';

  @override
  String get localGallery_editMetadata => 'Edit';

  @override
  String get localGallery_addToCollection => 'Collect';

  @override
  String get localGallery_sortButton => 'Sort';

  @override
  String get localGallery_sortFieldModified => 'Modified time';

  @override
  String get localGallery_sortFieldCreated => 'Created time';

  @override
  String get localGallery_sortFieldName => 'File name';

  @override
  String get localGallery_sortFieldSize => 'File size';

  @override
  String get localGallery_sortFieldDimensions => 'Image size';

  @override
  String localGallery_aboutColumns(Object count) {
    return '≈ $count columns';
  }

  @override
  String get localGallery_columnWidth => 'Column width';

  @override
  String get localGallery_thumbnailQualitySd => 'Standard';

  @override
  String get localGallery_thumbnailQualityHd => 'High';

  @override
  String get settings_galleryThumbnailQuality => 'Local gallery quality';

  @override
  String get settings_galleryThumbnailQualitySubtitle =>
      'Thumbnail display quality; defaults to High';

  @override
  String get localGallery_naiOnlyTooltip => 'Only show NAI-generated images';

  @override
  String get localGallery_naiVersionFilterTooltip =>
      'Filter by NAI model version';

  @override
  String get localGallery_masonryViewLabel => 'Waterfall';

  @override
  String get localGallery_justifiedViewLabel => 'Justified';

  @override
  String localGallery_dateRangeYearMonth(Object year, Object month) {
    return '$year/$month';
  }

  @override
  String get localGallery_dateRangePrevMonth => 'Previous month';

  @override
  String get localGallery_dateRangeNextMonth => 'Next month';

  @override
  String get localGallery_dateRangeClear => 'Clear';

  @override
  String localGallery_searchInScope(Object scope) {
    return 'Search: $scope';
  }

  @override
  String get localGallery_hideCategoryPanel => 'Hide category panel';

  @override
  String get localGallery_showCategoryPanel => 'Show category panel';

  @override
  String get localGallery_refreshTooltip =>
      'Refresh gallery\n\nAutomatically detects new or changed images and updates the index';

  @override
  String get localGallery_tagIntersection => 'Tag Intersection';

  @override
  String get localGallery_createCategoryTitle => 'New Category';

  @override
  String get localGallery_newOrImport => 'New / Import';

  @override
  String get localGallery_importFolder => 'Import Folder';

  @override
  String get localGallery_createCategoryHint => 'Enter category name';

  @override
  String get localGallery_createCategoryConfirm => 'Create';

  @override
  String get localGallery_createSubCategoryTitle => 'New Subcategory';

  @override
  String get localGallery_showInFolder => 'Show in Folder';

  @override
  String get localGallery_promptCopied => 'Prompt copied';

  @override
  String get localGallery_seedCopied => 'Seed copied';

  @override
  String get localGallery_createCollectionTitle => 'New Collection';

  @override
  String get localGallery_createCollectionHint => 'Enter collection name';

  @override
  String get localGallery_createCollectionConfirm => 'Create';

  @override
  String get localGallery_createCollectionFolderTitle =>
      'New Collection Folder';

  @override
  String get localGallery_createCollectionFolderHint => 'Enter folder name';

  @override
  String get localGallery_createCollectionFolderConfirm => 'Create';

  @override
  String localGallery_deleteCollectionContent(Object name) {
    return 'Delete collection \"$name\"? Only the collection entry is removed; no image files are deleted.';
  }

  @override
  String localGallery_deleteCollectionFolderContent(Object name) {
    return 'Delete collection folder \"$name\"? The folder is empty; only the folder itself is removed.';
  }

  @override
  String get localGallery_deleteCollectionFolderNonEmptyTitle =>
      'Folder Not Empty';

  @override
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name) {
    return 'Collection folder \"$name\" still contains collections or subfolders. Move or delete its children first.';
  }

  @override
  String get localGallery_unfavorite => 'Remove Favorite';

  @override
  String get localGallery_favoriteMenuEmptyCollections =>
      'No collections yet — create one with + on the left';

  @override
  String localGallery_confirmDeleteImageContent(Object name) {
    return 'Delete image \"$name\"?\n\nThe image will disappear from the gallery immediately; the file will be removed permanently on the next launch (can be undone in this session).';
  }

  @override
  String get localGallery_moveTo => 'Move to…';

  @override
  String get localGallery_copyTo => 'Copy to…';

  @override
  String get localGallery_externalSourceMoveConfirmTitle =>
      'Move External Gallery File';

  @override
  String localGallery_externalSourceMoveConfirmContent(Object count) {
    return 'This will move $count image(s). Files will be removed from their source folder and will no longer remain in their original location. Continue?';
  }

  @override
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return 'This will move $count image(s) to the external gallery source category \"$targetName\". Files will be written to the external source folder. Continue?';
  }

  @override
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return 'This will move $count image(s) to the external gallery source category \"$targetName\". Files will be removed from the original external source folder (will not remain in the original location) and written to the external source folder. Continue?';
  }

  @override
  String get localGallery_uncategorizedRoot => 'Uncategorized (Gallery Root)';

  @override
  String get localGallery_externalSourceChip => 'External';

  @override
  String get localGallery_categoryFilterHint => 'Search categories…';

  @override
  String localGallery_copySuccess(Object count) {
    return 'Copied $count image(s)';
  }

  @override
  String get localGallery_copyFailed => 'Failed to copy image';

  @override
  String get localGallery_confirmCopyContent =>
      'This will copy the image(s) to the target folder. Please confirm.';

  @override
  String get localGallery_categoryDeleteContent =>
      'Delete this category? The folder and its contents will be kept.';

  @override
  String get localGallery_protectedDeleteCategoryTitle =>
      'Protected Mode: Confirm Category Deletion';

  @override
  String get localGallery_protectedDeleteCategoryContent =>
      'This will delete the category record. The folder and its contents will be kept. Confirm again.';

  @override
  String get localGallery_confirmDelete => 'Confirm Delete';

  @override
  String get localGallery_confirmMoveImageTitle =>
      'Protected Mode: Confirm Image Move';

  @override
  String get localGallery_confirmMoveImageContent =>
      'This will move the image to the target category folder. Confirm this was not an accidental drag.';

  @override
  String get localGallery_confirmMove => 'Confirm Move';

  @override
  String get localGallery_imageMovedToCategory => 'Image moved to category';

  @override
  String get localGallery_categoriesSynced => 'Categories synced with folders';

  @override
  String get localGallery_saveDirectoryNotSet => 'Save directory is not set';

  @override
  String get localGallery_folderNotFound => 'Folder not found';

  @override
  String localGallery_openFolderFailed(Object error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get localGallery_protectedDeleteTitle =>
      'Protected Mode: Confirm Delete Again';

  @override
  String localGallery_protectedDeleteImagesContent(Object count) {
    return 'This will permanently delete $count local image files. This cannot be undone.';
  }

  @override
  String get localGallery_protectedBulkMoveTitle =>
      'Protected Mode: Confirm Bulk Move';

  @override
  String localGallery_protectedBulkMoveContent(Object count) {
    return 'This will move $count local image files to the target folder. Confirm this is not a mistake.';
  }

  @override
  String localGallery_importParamsFailed(Object error) {
    return 'Failed to import parameters: $error';
  }

  @override
  String localGallery_protectedDeleteImageContent(Object name) {
    return 'This will permanently delete image \"$name\". This cannot be undone.';
  }

  @override
  String get localGallery_saveZipArchive => 'Save ZIP Archive';

  @override
  String localGallery_packingImages(Object count) {
    return 'Packing $count images...';
  }

  @override
  String localGallery_packedImages(Object count) {
    return 'Packed $count images';
  }

  @override
  String get localGallery_packFailed => 'Failed to pack images';

  @override
  String get localGallery_imageFileMissing => 'Image file does not exist';

  @override
  String get localGallery_sentToImageToImage => 'Image sent to Image2Image';

  @override
  String localGallery_sendFailed(Object error) {
    return 'Send failed: $error';
  }

  @override
  String localGallery_sendToKritaFailed(Object error) {
    return 'Failed to send to Krita: $error';
  }

  @override
  String get localGallery_sendToImg2Img => 'Send to Image2Image';

  @override
  String get localGallery_sendToStyleTransfer => 'Send to Vibe Transfer';

  @override
  String get localGallery_sendToPreciseReference => 'Send to Precise Reference';

  @override
  String get localGallery_sendToKrita => 'Send to Krita';

  @override
  String get localGallery_importImageMetadata => 'Import Image Metadata';

  @override
  String get localGallery_copyPrompt => 'Copy Prompt';

  @override
  String get localGallery_copySeed => 'Copy Seed';

  @override
  String get localGallery_dragToShare => 'Drag to share';

  @override
  String galleryDragCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get localGallery_moveToRoot => 'Move to Root';

  @override
  String get localGallery_withMetadata => 'With Metadata';

  @override
  String get localGallery_skipped => 'Skipped';

  @override
  String get localGallery_clearFilters => 'Clear filters';

  @override
  String get slideshow_of => 'of';

  @override
  String get slideshow_play => 'Play';

  @override
  String get slideshow_pause => 'Pause';

  @override
  String get slideshow_previous => 'Previous';

  @override
  String get slideshow_next => 'Next';

  @override
  String get slideshow_exit => 'Exit (Esc)';

  @override
  String get slideshow_noImages => 'No images to display';

  @override
  String get slideshow_keyboardHint =>
      'Use ← → to navigate, Space to play/pause, Esc to exit';

  @override
  String get comparison_noImages => 'No images to display';

  @override
  String get comparison_tooManyImages => 'Too many images';

  @override
  String get comparison_maxImages => 'Maximum 4 images allowed for comparison';

  @override
  String get comparison_close => 'Close comparison';

  @override
  String get comparison_zoomHint => 'Pinch or scroll to zoom independently';

  @override
  String get comparison_loadError => 'Failed to load image';

  @override
  String get statistics_title => 'Statistics';

  @override
  String get statistics_noData => 'No statistics available';

  @override
  String get statistics_noTagData => 'No tag data';

  @override
  String get statistics_generateFirst => 'Generate some images first';

  @override
  String get statistics_totalImages => 'Total Images';

  @override
  String get statistics_totalSize => 'Total Size';

  @override
  String get statistics_favorites => 'Favorites';

  @override
  String get statistics_samplerDistribution => 'Sampler Distribution';

  @override
  String get statistics_additionalStats => 'Additional Statistics';

  @override
  String get statistics_averageFileSize => 'Average File Size';

  @override
  String get statistics_withMetadata => 'Images with Metadata';

  @override
  String get statistics_justNow => 'Just now';

  @override
  String statistics_minutesAgo(Object count) {
    return '$count minutes ago';
  }

  @override
  String statistics_hoursAgo(Object count) {
    return '$count hours ago';
  }

  @override
  String statistics_daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get statistics_anlasCost => 'Anlas Cost';

  @override
  String get statistics_totalAnlasCost => 'Total Cost';

  @override
  String get statistics_avgDailyCost => 'Daily Average';

  @override
  String get statistics_noAnlasData => 'No Anlas consumption data';

  @override
  String get statistics_peakActivity => 'Peak Activity';

  @override
  String get statistics_timeMorning => 'Morning';

  @override
  String get statistics_timeAfternoon => 'Afternoon';

  @override
  String get statistics_timeEvening => 'Evening';

  @override
  String get statistics_timeNight => 'Night';

  @override
  String get localGallery_group_today => 'Today';

  @override
  String get localGallery_group_yesterday => 'Yesterday';

  @override
  String get localGallery_sendTo => 'Send to…';

  @override
  String localGallery_groupImageCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted images',
      one: '$formatted image',
    );
    return '$_temp0';
  }

  @override
  String localGallery_imageCountLabel(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted images',
      one: '$formatted image',
    );
    return '$_temp0';
  }

  @override
  String get localGallery_selectGroup => 'Select group';

  @override
  String get localGallery_inspectorTitle => 'Details';

  @override
  String localGallery_inspectorPosition(String index, String total) {
    return '$index / $total';
  }

  @override
  String get localGallery_inspectorEmpty =>
      'Select an image to see its details';

  @override
  String get localGallery_inspectorEmptyHint =>
      'Double-click or press Space to view it full size';

  @override
  String get localGallery_hideInspector => 'Hide details panel';

  @override
  String get localGallery_showInspector => 'Show details panel';

  @override
  String get localGallery_reuseParams => 'Reuse parameters';

  @override
  String get localGallery_actionImg2Img => 'Image2Image';

  @override
  String get localGallery_actionStyleTransfer => 'Vibe Transfer';

  @override
  String get localGallery_actionPreciseReference => 'Precise Ref.';

  @override
  String get localGallery_actionSaveReference => 'Save to Library';

  @override
  String get localGallery_actionKrita => 'Krita';

  @override
  String localGallery_selectedImages(String count) {
    return '$count selected';
  }

  @override
  String get localGallery_sortDescending => 'Descending';

  @override
  String get localGallery_sortAscending => 'Ascending';

  @override
  String get localGallery_moreActions => 'More';

  @override
  String get localGallery_thumbnailSize => 'Thumbnail size';

  @override
  String get localGallery_naiOnlyChip => 'NAI images only';

  @override
  String get localGallery_modelLabel => 'Model';

  @override
  String get localGallery_allVersions => 'All';

  @override
  String get localGallery_allVariants => 'All variants';

  @override
  String get localGallery_dateRangeChip => 'Date range';

  @override
  String get localGallery_groupByDay => 'Group by day';

  @override
  String get localGallery_groupByMonth => 'Group by month';

  @override
  String get localGallery_groupNone => 'No grouping';

  @override
  String get localGallery_groupModeTooltip => 'Group by time';

  @override
  String get localGallery_sectionLibrary => 'Library';

  @override
  String get localGallery_sectionCollections => 'Collections';

  @override
  String get localGallery_sectionFolders => 'Folders';

  @override
  String get localGallery_dateFolders => 'Dated folders';

  @override
  String localGallery_indexSynced(String count) {
    return 'Index up to date · $count';
  }

  @override
  String localGallery_cannotOpenFolder(Object error) {
    return 'Cannot open folder: $error';
  }

  @override
  String get localGallery_firstTimeTipTitle => '💡 Tips';

  @override
  String get localGallery_firstTimeTipContent =>
      'Right-click (desktop) or long-press (mobile) on images to:\n\n• Copy Prompt\n• Copy Seed\n• View full metadata';

  @override
  String get localGallery_gotIt => 'Got it';

  @override
  String get localGallery_undone => 'Undone';

  @override
  String get localGallery_redone => 'Redone';

  @override
  String get localGallery_confirmBulkDelete => 'Confirm Bulk Delete';

  @override
  String localGallery_confirmBulkDeleteContent(Object count) {
    return 'Are you sure you want to delete $count selected images?\n\nThey will disappear from the gallery immediately; the files will be removed permanently on the next launch (can be undone in this session).';
  }

  @override
  String localGallery_deletedToPool(Object count) {
    return 'Deleted $count images. They will be removed permanently on the next launch.';
  }

  @override
  String get localGallery_trashTitle => 'Trash';

  @override
  String get localGallery_trashEmpty => 'Trash is empty';

  @override
  String get localGallery_trashHint =>
      'Files in the trash are still on disk and will be removed permanently on the next launch. Restored files return to the gallery immediately.';

  @override
  String localGallery_trashCount(Object count) {
    return '$count items';
  }

  @override
  String get localGallery_trashRestore => 'Restore';

  @override
  String get localGallery_trashRestoreAll => 'Restore all';

  @override
  String get localGallery_trashRestoreFailed => 'Failed to restore';

  @override
  String localGallery_trashRestored(Object count) {
    return 'Restored $count images';
  }

  @override
  String get localGallery_trashDeleteAll => 'Delete permanently';

  @override
  String localGallery_trashDeleteAllConfirm(Object count) {
    return 'This will permanently delete all $count files in the trash immediately. This cannot be undone.';
  }

  @override
  String localGallery_trashDeletedForever(Object count) {
    return 'Permanently deleted $count files';
  }

  @override
  String get localGallery_trashFileMissing => 'File no longer on disk';

  @override
  String localGallery_movedImages(Object count) {
    return 'Moved $count images';
  }

  @override
  String get localGallery_moveImagesFailed => 'Failed to move images';

  @override
  String localGallery_addedToCollection(Object count, Object name) {
    return 'Added $count images to collection \"$name\"';
  }

  @override
  String get localGallery_addToCollectionFailed =>
      'Failed to add images to collection';

  @override
  String get localGallery_removeFromCollection => 'Remove from Collection';

  @override
  String localGallery_removedFromCollection(Object count, Object name) {
    return 'Removed $count images from collection \"$name\"';
  }

  @override
  String get localGallery_notInCollection =>
      'Selected images are not in this collection';

  @override
  String localGallery_removedFromFavorites(Object count) {
    return 'Removed $count images from Favorites';
  }

  @override
  String get localGallery_alreadyInCollection =>
      'Images already in this collection';

  @override
  String get brushPreset_selectHint => 'Double tap to select this brush preset';

  @override
  String get brushPreset_pencil => 'Pencil';

  @override
  String get brushPreset_fine => 'Fine Brush';

  @override
  String get brushPreset_standard => 'Standard Brush';

  @override
  String get brushPreset_soft => 'Soft Brush';

  @override
  String get brushPreset_airbrush => 'Airbrush';

  @override
  String get brushPreset_marker => 'Marker';

  @override
  String get brushPreset_thick => 'Thick Brush';

  @override
  String get brushPreset_smudge => 'Smudge Brush';

  @override
  String bulkProgress_progress(Object current, Object total) {
    return 'Processing $current of $total';
  }

  @override
  String bulkProgress_success(Object count) {
    return '$count succeeded';
  }

  @override
  String bulkProgress_failed(Object count) {
    return '$count failed';
  }

  @override
  String get bulkProgress_errors => 'Errors:';

  @override
  String bulkProgress_moreErrors(Object count) {
    return '...and $count more errors';
  }

  @override
  String bulkProgress_completed(Object count) {
    return '$count items completed';
  }

  @override
  String bulkProgress_completedWithErrors(Object success, Object failed) {
    return '$success succeeded, $failed failed';
  }

  @override
  String get bulkProgress_title_delete => 'Deleting Images';

  @override
  String get bulkProgress_title_export => 'Exporting Metadata';

  @override
  String get bulkProgress_title_metadataEdit => 'Editing Metadata';

  @override
  String get bulkProgress_title_addToCollection => 'Adding to Collection';

  @override
  String get bulkProgress_title_removeFromCollection =>
      'Removing from Collection';

  @override
  String get bulkProgress_title_toggleFavorite => 'Updating Favorites';

  @override
  String get bulkProgress_title_default => 'Processing';

  @override
  String bulkProgress_errorDeleteFailed(String error) {
    return 'Failed to delete images: $error';
  }

  @override
  String get bulkProgress_errorNoImagesToExport => 'No images to export';

  @override
  String get bulkProgress_errorExportFailed => 'Export failed';

  @override
  String bulkProgress_errorExportFailedWithDetails(String error) {
    return 'Export failed: $error';
  }

  @override
  String get bulkProgress_errorNoMetadataChanges =>
      'Enter at least one tag to add or remove';

  @override
  String bulkProgress_errorMetadataEditFailed(String error) {
    return 'Failed to edit image metadata: $error';
  }

  @override
  String bulkProgress_errorFavoriteFailed(String error) {
    return 'Failed to update favorites: $error';
  }

  @override
  String get bulkProgress_errorNoImagesForCollection =>
      'No images to add to the collection';

  @override
  String bulkProgress_errorAddToCollectionFailed(String error) {
    return 'Failed to add images to the collection: $error';
  }

  @override
  String get bulkProgress_errorNothingToUndo => 'There is no operation to undo';

  @override
  String bulkProgress_errorUndoFailed(String error) {
    return 'Undo failed: $error';
  }

  @override
  String get bulkProgress_errorNothingToRedo => 'There is no operation to redo';

  @override
  String bulkProgress_errorRedoFailed(String error) {
    return 'Redo failed: $error';
  }

  @override
  String get collectionSelect_dialogTitle => 'Select Collection';

  @override
  String get collectionSelect_removeTitle => 'Remove from Collection';

  @override
  String collectionSelect_memberCount(Object n) {
    return '$n selected in this collection';
  }

  @override
  String get collectionSelect_noSelectedInCollection =>
      'No selected images in this collection';

  @override
  String collectionSelect_memberCountInFavorites(Object n) {
    return '$n selected in favorites';
  }

  @override
  String get collectionSelect_filterHint => 'Search collections...';

  @override
  String get collectionSelect_noCollections => 'No collections';

  @override
  String get collectionSelect_createCollectionHint =>
      'Create a collection first';

  @override
  String get collectionSelect_noFilterResults =>
      'No matching collections found';

  @override
  String collectionSelect_imageCount(int count) {
    return '$count images';
  }

  @override
  String get statistics_chartAspectRatio => 'Aspect Ratio Distribution';

  @override
  String get statistics_chartActivityHeatmap => 'Activity Heatmap';

  @override
  String get statistics_chartHourlyDistribution => 'Hourly Distribution';

  @override
  String get statistics_chartWeekdayDistribution => 'Weekday Distribution';

  @override
  String get statistics_aspectSquare => 'Square';

  @override
  String get statistics_aspectLandscape => 'Landscape';

  @override
  String get statistics_aspectPortrait => 'Portrait';

  @override
  String get statistics_aspectOther => 'Other';

  @override
  String get statistics_refresh => 'Refresh';

  @override
  String get statistics_retry => 'Retry';

  @override
  String statistics_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get statistics_mostActiveDay => 'Most Active Day';

  @override
  String get statistics_leastActiveDay => 'Least Active Day';

  @override
  String get statistics_sunday => 'Sun';

  @override
  String get statistics_monday => 'Mon';

  @override
  String get statistics_tuesday => 'Tue';

  @override
  String get statistics_wednesday => 'Wed';

  @override
  String get statistics_thursday => 'Thu';

  @override
  String get statistics_friday => 'Fri';

  @override
  String get statistics_saturday => 'Sat';

  @override
  String get fixedTags_negativeTitle => 'Undesired Content Fixed Tags';

  @override
  String get autocomplete_categoryCharacter => 'Character';

  @override
  String get autocomplete_categoryCopyright => 'Copyright';

  @override
  String get autocomplete_categoryArtist => 'Artist';

  @override
  String get autocomplete_categoryMeta => 'Meta';

  @override
  String get autocomplete_categoryContributor => 'Contributor';

  @override
  String get autocomplete_categorySpecies => 'Species';

  @override
  String get autocomplete_categoryLore => 'Lore';

  @override
  String get autocomplete_categoryLibrary => 'Library';

  @override
  String get autocomplete_categoryGeneral => 'General';

  @override
  String get promptToken_webCalibration => 'Web calibration';

  @override
  String get promptToken_prompt => 'Prompt';

  @override
  String get promptToken_qualityPreset => 'Quality Preset';

  @override
  String get promptToken_character => 'Character';

  @override
  String get promptToken_negativePrompt => 'Undesired Content';

  @override
  String get promptToken_negativePreset => 'Undesired Content Preset';

  @override
  String get promptToken_characterNegative => 'Character Undesired Content';

  @override
  String get common_rename => 'Rename';

  @override
  String get tagLibrary_newCategory => 'New Category';

  @override
  String get tagLibrary_tags => 'Tags';

  @override
  String get settings_network => 'Network';

  @override
  String get settings_enableProxy => 'Enable Proxy';

  @override
  String get settings_proxyEnabled => 'Enabled';

  @override
  String get settings_proxyDisabled => 'Direct connection';

  @override
  String get settings_proxyTrafficDisclosure =>
      'When proxy is enabled, NovelAI API traffic, including authentication requests, is sent through the system or manual proxy. Use only proxies you trust.';

  @override
  String get settings_proxyMode => 'Proxy Mode';

  @override
  String get settings_proxyModeAuto => 'Auto-detect system proxy';

  @override
  String get settings_proxyModeManual => 'Manual configuration';

  @override
  String get settings_auto => 'Auto';

  @override
  String get settings_manual => 'Manual';

  @override
  String get settings_proxyHost => 'Proxy Host';

  @override
  String get settings_proxyPort => 'Port';

  @override
  String get settings_proxyNotDetected => 'No system proxy detected';

  @override
  String get settings_testConnection => 'Test Connection';

  @override
  String get settings_testConnectionHint => 'Click to test if proxy is working';

  @override
  String settings_testSuccess(Object latency) {
    return 'Connection successful (${latency}ms)';
  }

  @override
  String settings_testFailed(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String get settings_proxyRestartHint =>
      'Proxy settings changed, restart recommended';

  @override
  String get tagLibrary_addToLibrary => 'Add to Library';

  @override
  String get tagLibrary_uncategorized => 'Uncategorized';

  @override
  String get tagLibrary_contentPreview => 'Content Preview';

  @override
  String get settings_enablePromptWeightScroll =>
      'Adjust prompt weight with mouse wheel';

  @override
  String get settings_enablePromptWeightScrollSubtitle =>
      'When prompt text is selected, hold the chosen modifier + wheel to adjust weight; a bare wheel scrolls the page as usual.';

  @override
  String get settings_weightScrollModifierAlt => 'Alt';

  @override
  String get settings_weightScrollModifierCtrl => 'Ctrl';

  @override
  String get settings_weightScrollModifierShift => 'Shift';

  @override
  String get settings_weightScrollModifierNone => 'None (legacy)';

  @override
  String get unit_seconds => 'seconds';

  @override
  String get settings_notificationSound => 'Completion Sound';

  @override
  String get settings_notificationSoundSubtitle =>
      'Play the completion sound only while the window is unfocused';

  @override
  String get settings_notificationCustomSound => 'Custom Sound';

  @override
  String get settings_notificationSelectSound => 'Select Sound';

  @override
  String get settings_notificationResetSound => 'Reset to Default';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get statistics_heatmapLess => 'Less';

  @override
  String get statistics_heatmapMore => 'More';

  @override
  String statistics_heatmapActivities(Object count) {
    return '$count activities';
  }

  @override
  String get statistics_heatmapNoActivity => 'No activity';

  @override
  String get metadataImport_title => 'Select Parameters to Import';

  @override
  String get metadataImport_promptsSection => 'Prompts';

  @override
  String get metadataImport_generationSection => 'Generation Parameters';

  @override
  String get metadataImport_selectAll => 'Select All';

  @override
  String get metadataImport_promptsOnly => 'Prompts Only';

  @override
  String get metadataImport_generationOnly => 'Parameters Only';

  @override
  String get metadataImport_clear => 'Clear';

  @override
  String get metadataImport_prompt => 'Prompt';

  @override
  String get metadataImport_mainPrompt => 'Main Prompt';

  @override
  String get metadataImport_fixedTags => 'Fixed Tags';

  @override
  String metadataImport_qualityTagsCount(int count) {
    return 'Quality Tags ($count)';
  }

  @override
  String get metadataImport_negativePrompt => 'Undesired Content';

  @override
  String get metadataImport_characterPrompts => 'Character Prompts';

  @override
  String metadataImport_characterPromptsCount(int count) {
    return 'Character Prompts ($count)';
  }

  @override
  String metadataImport_characterIndex(int index, Object text) {
    return 'Character $index: $text';
  }

  @override
  String get metadataImport_referenceSection => 'References';

  @override
  String metadataImport_countUnit(int count) {
    return '$count';
  }

  @override
  String metadataImport_preciseReferenceCount(int count) {
    return 'Precise Reference ($count)';
  }

  @override
  String metadataImport_vibeDetail(Object name, Object strength, Object info) {
    return '$name (Reference Strength $strength%, Information Extracted $info%)';
  }

  @override
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  ) {
    return 'Reference $index: $type (strength $strength%, fidelity $fidelity%)';
  }

  @override
  String get metadataImport_seed => 'Seed';

  @override
  String get metadataImport_steps => 'Steps';

  @override
  String get metadataImport_scale => 'Prompt Guidance';

  @override
  String get metadataImport_size => 'Size';

  @override
  String get metadataImport_sampler => 'Sampler';

  @override
  String get metadataImport_model => 'Model';

  @override
  String get metadataImport_smea => 'SMEA';

  @override
  String get metadataImport_smeaDyn => 'SMEA Dyn';

  @override
  String get metadataImport_noiseSchedule => 'Noise Schedule';

  @override
  String get metadataImport_cfgRescale => 'Prompt Guidance Rescale';

  @override
  String get metadataImport_qualityToggle => 'Quality Toggle';

  @override
  String get metadataImport_ucPreset => 'Undesired Content Preset';

  @override
  String get metadataImport_noData => '(no data)';

  @override
  String metadataImport_selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get metadataImport_noDataFound => 'No NovelAI metadata found';

  @override
  String metadataImport_appliedCount(int count) {
    return 'Applied $count parameters';
  }

  @override
  String get metadataImport_appliedTitle => 'Metadata Applied';

  @override
  String get metadataImport_appliedDescription =>
      'The following parameters have been applied:';

  @override
  String get metadataImport_charactersCount => 'characters';

  @override
  String get shortcut_context_global => 'Global';

  @override
  String get shortcut_context_generation => 'Generation';

  @override
  String get shortcut_context_gallery => 'Gallery List';

  @override
  String get shortcut_context_viewer => 'Image Viewer';

  @override
  String get shortcut_context_settings => 'Settings';

  @override
  String get shortcut_context_input => 'Input Field';

  @override
  String get shortcut_action_navigate_to_generation => 'Generation Page';

  @override
  String get shortcut_action_navigate_to_local_gallery => 'Local Gallery';

  @override
  String get shortcut_action_navigate_to_online_gallery => 'Online Gallery';

  @override
  String get shortcut_action_navigate_to_tag_library => 'Prompt Block Library';

  @override
  String get shortcut_action_navigate_to_statistics => 'Statistics';

  @override
  String get shortcut_action_navigate_to_settings => 'Settings';

  @override
  String get shortcut_action_generate_image => 'Generate Image';

  @override
  String get shortcut_action_generation_prev_image =>
      'Previous preview (linked history)';

  @override
  String get shortcut_action_generation_next_image =>
      'Next preview (linked history)';

  @override
  String get shortcut_action_cancel_generation => 'Cancel Generation';

  @override
  String get shortcut_action_clear_prompt => 'Clear Prompt';

  @override
  String get shortcut_action_toggle_prompt_mode => 'Toggle Prompt Mode';

  @override
  String get shortcut_action_open_tag_library => 'Open Prompt Block Library';

  @override
  String get shortcut_action_save_image => 'Save Image';

  @override
  String get shortcut_action_upscale_image => 'Upscale Image';

  @override
  String get shortcut_action_copy_image => 'Copy Image';

  @override
  String get shortcut_action_fullscreen_preview => 'Fullscreen Preview';

  @override
  String get shortcut_action_open_params_panel => 'Open Params Panel';

  @override
  String get shortcut_action_open_history_panel => 'Open History Panel';

  @override
  String get shortcut_action_reuse_params => 'Reuse Parameters';

  @override
  String get shortcut_action_previous_image => 'Previous Image';

  @override
  String get shortcut_action_next_image => 'Next Image';

  @override
  String get shortcut_action_zoom_in => 'Zoom In';

  @override
  String get shortcut_action_zoom_out => 'Zoom Out';

  @override
  String get shortcut_action_reset_zoom => 'Reset Zoom';

  @override
  String get shortcut_action_toggle_fullscreen => 'Toggle Fullscreen';

  @override
  String get shortcut_action_close_viewer => 'Close Viewer';

  @override
  String get shortcut_action_toggle_favorite => 'Toggle Favorite';

  @override
  String get shortcut_action_copy_prompt => 'Copy Prompt';

  @override
  String get shortcut_action_reuse_gallery_params => 'Reuse Parameters';

  @override
  String get shortcut_action_delete_image => 'Delete Image';

  @override
  String get shortcut_action_previous_page => 'Scroll Up One Screen';

  @override
  String get shortcut_action_next_page => 'Scroll Down One Screen';

  @override
  String get shortcut_action_refresh_gallery => 'Refresh Gallery';

  @override
  String get shortcut_action_focus_search => 'Focus Search';

  @override
  String get shortcut_action_enter_selection_mode => 'Select All';

  @override
  String get shortcut_action_clear_filter => 'Clear Filter';

  @override
  String get shortcut_action_toggle_category_panel => 'Toggle Category Panel';

  @override
  String get shortcut_action_jump_to_date => 'Jump to Date';

  @override
  String get shortcut_action_open_folder => 'Open Folder';

  @override
  String get shortcut_action_minimize_to_tray => 'Minimize to Tray';

  @override
  String get shortcut_action_quit_app => 'Quit Application';

  @override
  String get shortcut_action_show_shortcut_help => 'Show Shortcut Help';

  @override
  String get shortcut_action_toggle_theme => 'Toggle Theme';

  @override
  String get shortcut_settings_title => 'Keyboard Shortcuts';

  @override
  String get shortcut_settings_enable => 'Enable Shortcuts';

  @override
  String get shortcut_settings_show_badges => 'Show Shortcut Badges';

  @override
  String get shortcut_settings_show_in_tooltips => 'Show in Tooltips';

  @override
  String get shortcut_settings_reset_all => 'Reset All to Default';

  @override
  String get shortcut_settings_search => 'Search shortcuts...';

  @override
  String get shortcut_settings_press_key => 'Press key combination...';

  @override
  String get shortcut_help_title => 'Keyboard Shortcuts Help';

  @override
  String get shortcut_help_search => 'Search shortcuts...';

  @override
  String get shortcut_help_all => 'All';

  @override
  String get shortcut_help_fabTooltip => 'Keyboard Shortcuts Help (F1)';

  @override
  String get shortcut_editor_recordingInline => 'Press shortcut...';

  @override
  String get shortcut_editor_pressEscToCancel => 'Press Esc to cancel';

  @override
  String get shortcut_editor_clickToRecord => 'Click to start recording';

  @override
  String shortcut_editor_conflictWith(Object action) {
    return 'This shortcut conflicts with \"$action\"';
  }

  @override
  String get drop_hint => 'Drop image here';

  @override
  String get drop_img2img => 'Image2Image';

  @override
  String get drop_vibeTransfer => 'Vibe Transfer';

  @override
  String get drop_characterReference => 'Precise Reference';

  @override
  String get drop_unsupportedFormat => 'Unsupported file format';

  @override
  String get drop_addedToImg2Img => 'Added to Image2Image';

  @override
  String get drop_addedToVibe => 'Added to Vibe Transfer';

  @override
  String drop_addedMultipleToVibe(int count) {
    return 'Added $count vibe references';
  }

  @override
  String get drop_addedToCharacterRef => 'Added to Precise Reference';

  @override
  String get drop_vibeDetected => 'Pre-encoded Vibe detected (saves 2 Anlas)';

  @override
  String get drop_reuseVibe => 'Reuse Vibe';

  @override
  String get drop_useAsRawImage => 'Use as Raw Image';

  @override
  String get drop_dragToImg2ImgOrOther =>
      'Drag to Image2Image or another target';

  @override
  String get preciseRef_title => 'Precise Reference';

  @override
  String get preciseRef_subtitle =>
      'Tie generation to a character or style reference';

  @override
  String get preciseRef_description =>
      'Add reference images and set type and parameters. Multiple references can be used simultaneously.';

  @override
  String get preciseRef_addReference => 'Add Reference';

  @override
  String get preciseRef_clearAll => 'Clear All';

  @override
  String get preciseRef_remove => 'Remove';

  @override
  String get preciseRef_referenceType => 'Reference Type';

  @override
  String get preciseRef_strength => 'Strength';

  @override
  String get preciseRef_fidelity => 'Fidelity';

  @override
  String get preciseRef_v4Only => 'This feature requires V4+ models';

  @override
  String get preciseRef_typeCharacter => 'Character';

  @override
  String get preciseRef_typeStyle => 'Style';

  @override
  String get preciseRef_typeCharacterAndStyle => 'Character + Style';

  @override
  String get preciseRef_costHint =>
      'Using Precise Reference consumes extra Anlas';

  @override
  String get preciseRef_costBadge => 'Uses Anlas';

  @override
  String get preciseRef_dropToAdd => 'Release to add precise reference';

  @override
  String get preciseRef_dropNoReadableImage =>
      'The drop source did not provide a readable image file or image link';

  @override
  String preciseRef_addedCount(int count) {
    return 'Added $count precise references';
  }

  @override
  String preciseRef_removedCount(int count) {
    return 'Removed $count precise references';
  }

  @override
  String get vibeLibrary_title => 'Vibe Library';

  @override
  String get vibeLibrary_categories => 'Categories';

  @override
  String get vibeLibrary_createCategoryTitle => 'New Category';

  @override
  String get vibeLibrary_createSubCategoryTitle => 'New Subcategory';

  @override
  String get vibeLibrary_categoryNameHint => 'Enter category name';

  @override
  String get vibeLibrary_createCategoryConfirm => 'Create';

  @override
  String get vibeLibrary_deleteCategoryTitle => 'Confirm Delete';

  @override
  String get vibeLibrary_deleteCategoryContent =>
      'Delete this category? Vibes in it will be moved to Uncategorized.';

  @override
  String get vibeLibrary_sortTooltip => 'Sort by';

  @override
  String get vibeLibrary_hideCategoryPanel => 'Hide category panel';

  @override
  String get vibeLibrary_showCategoryPanel => 'Show category panel';

  @override
  String get vibeLibrary_enterSelectionMode => 'Enter selection mode';

  @override
  String get vibeLibrary_importTooltip =>
      'Import Vibe files or PNG/JPG/JPEG/WEBP images (right-click for more options)';

  @override
  String get vibeLibrary_exportTooltip => 'Export Vibe to file';

  @override
  String get vibeLibrary_openFolderTooltip => 'Open Vibe library folder';

  @override
  String get vibeLibrary_refresh => 'Refresh';

  @override
  String get vibeLibrary_loading => 'Loading...';

  @override
  String vibeLibrary_totalCount(Object count) {
    return '$count Vibes';
  }

  @override
  String get vibeLibrary_noCategoriesAvailable => 'No categories available';

  @override
  String get vibeLibrary_moveToCategory => 'Move to Category';

  @override
  String get vibeLibrary_uncategorized => 'Uncategorized';

  @override
  String vibeLibrary_movedToCategory(Object count) {
    return 'Moved $count Vibes';
  }

  @override
  String get vibeLibrary_favoriteStatusUpdated => 'Favorite status updated';

  @override
  String get vibeLibrary_importFromFile => 'Import from File';

  @override
  String get vibeLibrary_importFromImage => 'Import from Image';

  @override
  String get vibeLibrary_importFromClipboard =>
      'Import Encoded Data from Clipboard';

  @override
  String vibeLibrary_openFolderFailed(Object error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get vibeLibrary_importFileDialogTitle => 'Select Vibe files to import';

  @override
  String get vibeLibrary_preparingImport => 'Preparing import...';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return 'Imported $count Vibes';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return 'Import complete: $success succeeded, $failed failed';
  }

  @override
  String get vibeLibrary_dropImportHint =>
      'Drop .naiv4vibe/.naiv4vibebundle/.png/.jpg/.jpeg/.webp files or folders here to import';

  @override
  String get vibeLibrary_importing => 'Importing...';

  @override
  String vibeLibrary_pageIndicator(Object current, Object total) {
    return '$current / $total pages';
  }

  @override
  String get vibeLibrary_itemsPerPage => 'Per page:';

  @override
  String get vibeLibrary_tooManyTitle => 'Too Many Vibes';

  @override
  String vibeLibrary_tooManySelectedContent(Object count) {
    return 'Selected $count Vibes, but at most 16 can be used at once.\n\nPlease reduce the selection and try again.';
  }

  @override
  String vibeLibrary_tooManyExistingContent(Object current, Object remaining) {
    return 'The generation page already has $current Vibes. You can add $remaining more.\n\nPlease reduce the selection and try again.';
  }

  @override
  String vibeLibrary_sentToGenerationCount(Object count) {
    return 'Sent $count Vibes to generation';
  }

  @override
  String vibeLibrary_deleteSelectedContent(Object count) {
    return 'Delete $count selected Vibes? This action cannot be undone.';
  }

  @override
  String vibeLibrary_deletedCount(Object count) {
    return 'Deleted $count Vibes';
  }

  @override
  String get vibeLibrary_importImageDialogTitle =>
      'Select images containing Vibe data';

  @override
  String get vibeLibrary_clipboardEmpty => 'Clipboard is empty';

  @override
  String get vibeLibrary_encodeTimeout =>
      'Encoding timed out. Please check your network connection.';

  @override
  String get vibeLibrary_unknownError => 'Unknown error';

  @override
  String get vibeLibrary_save => 'Save to Library';

  @override
  String get vibeLibrary_import => 'Import Vibe';

  @override
  String get vibeLibrary_searchHint => 'Search name, tags...';

  @override
  String get vibeLibrary_empty => 'Vibe Library is empty';

  @override
  String get vibeLibrary_emptyHint => 'Add some entries to Vibe Library first';

  @override
  String get vibeLibrary_allVibes => 'All Vibes';

  @override
  String get vibeLibrary_favorites => 'Favorites';

  @override
  String get vibeLibrary_sendToGeneration => 'Send to Generation';

  @override
  String get vibeLibrary_export => 'Export';

  @override
  String get vibeLibrary_edit => 'Edit';

  @override
  String get vibeLibrary_delete => 'Delete';

  @override
  String get vibeLibrary_addToFavorites => 'Add to Favorites';

  @override
  String get vibeLibrary_removeFromFavorites => 'Remove from Favorites';

  @override
  String get vibeLibrary_newSubCategory => 'New Subcategory';

  @override
  String get vibeLibrary_maxVibesReached => 'Maximum limit reached (16 vibes)';

  @override
  String get vibeLibrary_bundleReadFailed =>
      'Failed to read bundle file, using single file mode';

  @override
  String categoryError_loadFailed(String error) {
    return 'Failed to load categories: $error';
  }

  @override
  String categoryError_syncFailed(String error) {
    return 'Failed to sync categories: $error';
  }

  @override
  String get categoryError_nameEmpty => 'Category name cannot be empty';

  @override
  String get categoryError_parentNotFound => 'Parent category does not exist';

  @override
  String categoryError_createFailed(String error) {
    return 'Failed to create category: $error';
  }

  @override
  String get categoryError_notFound => 'Category does not exist';

  @override
  String categoryError_renameFailed(String error) {
    return 'Failed to rename category: $error';
  }

  @override
  String get categoryError_invalidMove =>
      'A category cannot be moved under one of its descendants';

  @override
  String categoryError_moveFailed(String error) {
    return 'Failed to move category: $error';
  }

  @override
  String get categoryError_hasSubcategories =>
      'This category contains subcategories. Delete them first.';

  @override
  String categoryError_deleteFailed(String error) {
    return 'Failed to delete category: $error';
  }

  @override
  String categoryError_moveImageFailed(String error) {
    return 'Failed to move image: $error';
  }

  @override
  String categoryError_moveImagesFailed(String error) {
    return 'Failed to move images: $error';
  }

  @override
  String categoryError_reorderFailed(String error) {
    return 'Failed to reorder categories: $error';
  }

  @override
  String get vibeBulkTag_actionPreview => 'Change preview';

  @override
  String get vibeDetail_strengthDescription =>
      'Controls how strongly this Vibe influences generated results';

  @override
  String get vibeDetail_infoExtractedDescription =>
      'Controls how much information is extracted from the source image (costs 2 Anlas)';

  @override
  String get vibeDetail_statistics => 'Statistics';

  @override
  String get vibeDetail_usageCount => 'Times used';

  @override
  String vibeDetail_timesUsed(int count) {
    return '$count times';
  }

  @override
  String get vibeDetail_lastUsed => 'Last used';

  @override
  String get vibeDetail_neverUsed => 'Never used';

  @override
  String get vibeDetail_createdAt => 'Created';

  @override
  String get vibeDetail_saveParameters => 'Save Parameters';

  @override
  String get vibe_export_title => 'Export Vibe';

  @override
  String get vibe_export_format => 'Export Format';

  @override
  String get vibe_selector_title => 'Select Vibe';

  @override
  String get vibe_selector_recent => 'Recent';

  @override
  String get vibe_export_include_thumbnails => 'Include Thumbnails';

  @override
  String get vibe_export_include_thumbnails_subtitle =>
      'Include thumbnail preview in export file';

  @override
  String get vibe_export_singleFile => 'Single file (.naiv4vibe)';

  @override
  String get vibe_export_singleFileDescription =>
      'Export each Vibe as a separate file, suitable for sharing one Vibe';

  @override
  String get vibe_export_bundleFile => 'Bundle file (.naiv4vibebundle)';

  @override
  String get vibe_export_bundleFileDescription =>
      'Pack multiple Vibes into one file, suitable for batch backup';

  @override
  String get vibe_export_embedIntoPng => 'Embed into PNG';

  @override
  String get vibe_export_embedIntoPngDescription =>
      'Export a single Vibe by embedding its data into PNG metadata';

  @override
  String get vibe_export_exportable => 'Exportable';

  @override
  String get vibe_export_notExportable => 'Not exportable';

  @override
  String get vibe_export_selectVibesToExport => 'Select Vibes to export';

  @override
  String vibe_export_exportSelected(int count) {
    return 'Export ($count)';
  }

  @override
  String vibe_export_strengthPercent(int percent) {
    return 'Strength: $percent%';
  }

  @override
  String get vibe_export_pngCarrierImage => 'PNG carrier image';

  @override
  String get vibe_export_noUsablePngCarrier =>
      'This Vibe has no directly usable PNG carrier image. You can choose an external PNG image as the carrier.';

  @override
  String get vibe_export_selectExternalPngImage =>
      'Select external PNG image...';

  @override
  String get vibe_export_changeExternalPngImage =>
      'Change external PNG image...';

  @override
  String get vibe_export_useVibeImageInstead => 'Use Vibe image instead';

  @override
  String vibe_export_usingExternalPng(String fileName) {
    return 'Using external PNG: $fileName';
  }

  @override
  String get vibe_export_selectPngImage => 'Select PNG image';

  @override
  String get vibe_export_invalidPngImage =>
      'The selected file is not a valid PNG image';

  @override
  String vibe_export_selectPngImageFailed(String error) {
    return 'Failed to select PNG image: $error';
  }

  @override
  String vibe_export_embeddingPng(String name) {
    return 'Embedding PNG: $name';
  }

  @override
  String vibe_export_exportCompleteCounts(int successCount, int failCount) {
    return 'Export complete: $successCount succeeded, $failCount failed';
  }

  @override
  String vibe_export_exportCompletePath(String path) {
    return 'Export complete: $path';
  }

  @override
  String vibe_export_packingVibes(int count) {
    return 'Packing $count Vibes...';
  }

  @override
  String vibe_export_exportingName(String name) {
    return 'Exporting: $name';
  }

  @override
  String get vibe_export_selectExportFolder => 'Select export folder';

  @override
  String get vibe_export_generatingBundleFile => 'Generating bundle file...';

  @override
  String vibe_export_bundleTitle(String name) {
    return 'Export Bundle: $name';
  }

  @override
  String vibe_export_vibesTitle(int count) {
    return 'Export Vibes ($count selected)';
  }

  @override
  String get vibe_export_method => 'Export Method';

  @override
  String get vibe_export_wholeBundle => 'Whole Bundle';

  @override
  String get vibe_export_internalVibe => 'Internal Vibe';

  @override
  String vibe_export_wholeBundleDescription(int count) {
    return 'Export as a .naiv4vibebundle file containing all $count vibes';
  }

  @override
  String vibe_export_internalVibeDescription(int count) {
    return 'Select internal bundle vibes to export separately as .naiv4vibe files ($count total)';
  }

  @override
  String get vibe_export_exportBundle => 'Export Bundle';

  @override
  String get vibe_export_exportAsFiles => 'Export as Files';

  @override
  String get vibe_export_exportBundleDescription =>
      'Export as a .naiv4vibebundle file';

  @override
  String get vibe_export_exportAsFilesDescription =>
      'Export as .naiv4vibe or .naiv4vibebundle files';

  @override
  String get vibe_export_exportAsZip => 'Export as ZIP';

  @override
  String get vibe_export_exportAsZipDescription =>
      'Pack the selected Vibe library entries into a .zip as separate files';

  @override
  String get vibe_export_compressData => 'Compress data';

  @override
  String get vibe_export_compressDataDescription =>
      'Use compression to reduce file size (recommended for batch export)';

  @override
  String get vibe_export_zipCompressDescription =>
      'Compress files inside the ZIP to reduce size';

  @override
  String get vibe_export_exportAsPng => 'Export as PNG';

  @override
  String get vibe_export_pngInternalBundleUnsupported =>
      'Embedding into an image is not supported when exporting a single internal bundle vibe';

  @override
  String get vibe_export_embedVibeDataIntoPng =>
      'Embed Vibe data into PNG metadata';

  @override
  String get vibe_export_batchPngUsesFirstImage =>
      'Batch export uses each Vibe\'s first available image. Entries without images are skipped automatically.';

  @override
  String get vibe_export_exportCarrierImage => 'Export carrier image';

  @override
  String get vibe_export_usingExternalCarrierImage =>
      'Using an external PNG as the export carrier image';

  @override
  String get vibe_export_exportAsEncodings => 'Export as Encodings';

  @override
  String get vibe_export_exportAsEncodingsDescription =>
      'Export data as encodings (JSON or Base64)';

  @override
  String get vibe_export_jsonDescription =>
      'Export as a formatted JSON file for easier reading and editing';

  @override
  String get vibe_export_base64Description =>
      'Export as plain Base64 for copying and sharing';

  @override
  String get vibe_export_selectAtLeastOneMethod =>
      'Select at least one export method';

  @override
  String get vibe_export_batchPngUnsupported =>
      'Batch Vibe export does not support embedding into PNG. Use the single Vibe export screen.';

  @override
  String get vibe_export_selectPngCarrier =>
      'Select a PNG carrier image for export';

  @override
  String get vibe_export_selectAtLeastOneInternalVibe =>
      'Select at least one internal vibe to export';

  @override
  String get vibe_export_selectVibeExportFolder => 'Select Vibe export folder';

  @override
  String get vibe_export_saveEncodingFile => 'Save encoding file';

  @override
  String get vibe_export_preparingExport => 'Preparing export...';

  @override
  String vibe_export_preparingVibeProgress(int current, int total) {
    return 'Reading Vibe $current/$total...';
  }

  @override
  String get vibe_export_exportingBundle => 'Exporting Bundle...';

  @override
  String get vibe_export_exportingZip => 'Exporting ZIP...';

  @override
  String get vibe_export_embeddingImage => 'Embedding image...';

  @override
  String get vibe_export_exportingEncoding => 'Exporting encoding...';

  @override
  String vibe_export_exportFailedWithError(String error) {
    return 'Export failed: $error';
  }

  @override
  String get vibe_export_noExportableEntries => 'No exportable Vibe entries';

  @override
  String get vibe_export_bundleFilePathEmpty => 'Bundle file path is empty';

  @override
  String vibe_export_invalidImageFormatWithError(String error) {
    return 'Invalid image format: $error';
  }

  @override
  String vibe_export_embedFailedWithError(String error) {
    return 'Embed failed: $error';
  }

  @override
  String vibe_export_embedImageFailedWithError(String error) {
    return 'Failed to embed image: $error';
  }

  @override
  String vibe_export_extractingVibeProgress(int current, int total) {
    return 'Extracting vibe $current/$total...';
  }

  @override
  String vibe_export_selectImageFailed(String error) {
    return 'Failed to select image: $error';
  }

  @override
  String vibe_export_dialogTitle(int count) {
    return 'Export $count Vibes';
  }

  @override
  String get vibe_export_chooseMethod => 'Choose how to export the vibes';

  @override
  String get vibe_export_asBundle => 'As Bundle';

  @override
  String get vibe_export_individually => 'Individually';

  @override
  String get vibe_export_noData => 'No data to export';

  @override
  String get vibe_export_success => 'Export successful';

  @override
  String get vibe_export_failed => 'Export failed';

  @override
  String vibe_export_skipped(int count) {
    return 'Skipped $count vibes without data';
  }

  @override
  String vibe_export_bundleSuccess(int count) {
    return 'Bundle exported: $count vibes';
  }

  @override
  String get vibe_export_selectToEmbed => 'Select vibes to embed';

  @override
  String get vibe_export_pngRequired => 'PNG file required';

  @override
  String get vibe_export_noEmbeddableData => 'No embeddable data';

  @override
  String vibe_export_embedSuccess(int count) {
    return 'Embedded $count vibes into image';
  }

  @override
  String get vibe_export_embedFailed => 'Embed failed';

  @override
  String get vibe_embedToImage => 'Embed to Image';

  @override
  String get vibe_import_skip => 'Skip';

  @override
  String get vibe_import_confirm => 'Confirm';

  @override
  String get vibe_import_noEncodingData => 'No encoding data';

  @override
  String get vibe_import_encodingCost => 'Encoding will cost 2 Anlas';

  @override
  String get vibe_import_confirmCost => 'Continue and consume Anlas?';

  @override
  String get vibe_import_encodeNow => 'Encode immediately (2 Anlas)';

  @override
  String get vibe_addImageOnly => 'Add image only';

  @override
  String get vibe_import_autoSave => 'Auto-save to library';

  @override
  String get vibe_import_encodingFailed => 'Encoding failed';

  @override
  String get vibe_import_encodingFailedMessage =>
      'Failed to encode vibe. Continue adding unencoded image?';

  @override
  String get vibe_import_encodingInProgress => 'Encoding...';

  @override
  String get vibe_import_encodingComplete => 'Encoding complete';

  @override
  String get vibe_import_partialFailed => 'Partial encoding failed';

  @override
  String get vibe_import_timeout => 'Encoding timeout';

  @override
  String get vibe_import_title => 'Import from Library';

  @override
  String vibe_import_result(int count) {
    return 'Imported $count vibes';
  }

  @override
  String get vibe_import_fileParseFailed => 'Failed to parse file';

  @override
  String get vibe_import_fileSelectionFailed => 'File selection failed';

  @override
  String get vibe_import_importFailed => 'Import failed';

  @override
  String get vibe_import_bundleTitle => 'Import Vibe Bundle';

  @override
  String get vibe_import_bundleChooseMethod => 'Choose import method';

  @override
  String get vibe_import_bundleAsWhole => 'Import as whole';

  @override
  String get vibe_import_bundleAsWholeDescription =>
      'Keep the bundle structure and import it as one library entry';

  @override
  String get vibe_import_bundleSplitEntries => 'Split into separate entries';

  @override
  String get vibe_import_bundleSplitEntriesDescription =>
      'Import each vibe as a separate library entry';

  @override
  String get vibe_import_bundleSelectVibes => 'Select vibes to import';

  @override
  String get vibe_import_bundleSelectVibesDescription =>
      'Import only the selected vibes';

  @override
  String get vibe_import_bundleConfigureEachVibe =>
      'Configure each Vibe\'s parameters';

  @override
  String get vibe_import_bundleSelectAndConfigureEachVibe =>
      'Select and configure each Vibe\'s parameters';

  @override
  String vibe_import_bundleSelectedCount(int selected, int total) {
    return '$selected/$total selected';
  }

  @override
  String get vibe_saveToLibrary_title => 'Save to Library';

  @override
  String get vibe_saveToLibrary_strength => 'Strength';

  @override
  String get vibe_saveToLibrary_infoExtracted => 'Information Extracted';

  @override
  String vibe_saveToLibrary_saving(int count) {
    return 'Saving $count vibes';
  }

  @override
  String get vibe_saveToLibrary_saveFailed => 'Failed to save to library';

  @override
  String vibe_saveToLibrary_savingCount(int count) {
    return 'Saving $count vibes';
  }

  @override
  String get vibe_saveToLibrary_nameLabel => 'Name';

  @override
  String get vibe_saveToLibrary_nameHint => 'Enter vibe name';

  @override
  String vibe_saveToLibrary_mixed(int saved, int reused) {
    return 'Saved $saved, reused $reused';
  }

  @override
  String vibe_saveToLibrary_saved(int count) {
    return 'Saved $count to library';
  }

  @override
  String vibe_saveToLibrary_reused(int count) {
    return 'Reused $count from library';
  }

  @override
  String get vibe_saveToLibrary_saveAsBundle => 'Save as bundle';

  @override
  String vibe_saveToLibrary_saveAsBundleDescription(int count) {
    return 'Save $count Vibes as one bundle';
  }

  @override
  String get vibe_saveToLibrary_tagHint => 'Enter a tag, then press Add';

  @override
  String get vibe_maxReached => 'Maximum 16 vibes reached';

  @override
  String vibe_addedCount(int count) {
    return 'Added $count vibes';
  }

  @override
  String get vibe_statusEncoded => 'Encoded';

  @override
  String get vibe_statusEncoding => 'Encoding...';

  @override
  String get vibe_statusPendingEncode => 'Encode (2 Anlas)';

  @override
  String get vibe_encodeDialogTitle => 'Confirm Vibe Encoding';

  @override
  String get vibe_encodeDialogMessage => 'Encode this image for generation?';

  @override
  String get vibe_encodeCostWarning => 'This will cost 2 Anlas (credits)';

  @override
  String get vibe_encodeButton => 'Encode';

  @override
  String get vibe_encodeSuccess => 'Vibe encoded successfully!';

  @override
  String get vibe_encodeFailed => 'Vibe encoding failed, please retry';

  @override
  String vibe_encodeError(String error) {
    return 'Encoding failed: $error';
  }

  @override
  String get shortcuts_customize => 'Customize Shortcuts';

  @override
  String get selection_clear_selection => 'Clear Selection';

  @override
  String get selection_invert_selection => 'Invert Selection';

  @override
  String get selection_cut_to_layer => 'Cut to Layer';

  @override
  String get search_results => 'Search Results';

  @override
  String get search_noResults => 'No matching results';

  @override
  String get addToCurrent => 'Add to Current';

  @override
  String get replaceExisting => 'Replace Existing';

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get selectAll => 'Select All';

  @override
  String get clearSelection => 'Clear';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get shortcut_context_vibe_detail => 'Vibe Detail';

  @override
  String get shortcut_action_vibe_detail_rename => 'Rename';

  @override
  String get vibeSelectorFilterFavorites => 'Favorites';

  @override
  String get vibeSelectorFilterSourceAll => 'All Types';

  @override
  String get vibeSelectorSortCreated => 'Created';

  @override
  String get vibeSelectorSortLastUsed => 'Last Used';

  @override
  String get vibeSelectorSortUsedCount => 'Usage Count';

  @override
  String get vibeSelectorSortName => 'Name';

  @override
  String vibeSelectorItemsCount(int count) {
    return '$count items';
  }

  @override
  String get tray_show => 'Show Window';

  @override
  String get tray_exit => 'Exit';

  @override
  String get settings_shortcutsSubtitle => 'Customize keyboard shortcuts';

  @override
  String get settings_openFolder => 'Open folder';

  @override
  String get settings_openFolderFailed => 'Failed to open folder';

  @override
  String get settings_vibePathSaved => 'Vibe library path saved';

  @override
  String get settings_selectFolderFailed => 'Failed to select folder';

  @override
  String get settings_hivePathSaved =>
      'Data storage path saved, effective after restart';

  @override
  String get settings_restartRequiredTitle => 'Restart Required';

  @override
  String get settings_changePathConfirm =>
      'After changing the data storage path, the app needs to restart to take effect.\\n\\nThe new path will take effect on the next startup. Continue?';

  @override
  String get settings_resetPathConfirm =>
      'After resetting the data storage path, the app needs to restart to take effect.\\n\\nThe default path will take effect on the next startup. Continue?';

  @override
  String get settings_kritaBridgeEnable => 'Enable local bridge';

  @override
  String get settings_kritaBridgeDisabledText =>
      'Off by default; listens only on local 127.0.0.1 when enabled';

  @override
  String get settings_kritaBridgeStartingText =>
      'Starting local bridge service...';

  @override
  String get settings_kritaBridgeListeningText =>
      'Waiting for an external Agent or Krita';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita plugin connected';

  @override
  String get settings_kritaBridgeErrorText =>
      'Startup failed, check the error message';

  @override
  String get settings_kritaBridgeDisabled => 'Disabled';

  @override
  String get settings_kritaBridgeStarting => 'Starting';

  @override
  String get settings_kritaBridgeListening => 'Listening';

  @override
  String get settings_kritaBridgeConnected => 'Connected';

  @override
  String get settings_kritaBridgeError => 'Error';

  @override
  String get settings_kritaBridgeRegenerateSession => 'Regenerate Session';

  @override
  String get settings_kritaBridgeDiscoveryFile => 'Discovery File';

  @override
  String get settings_kritaBridgeWaitingEndpoint =>
      'Waiting for local WebSocket listener';

  @override
  String settings_kritaBridgeClient(Object client) {
    return 'Client: $client';
  }

  @override
  String get settings_fontScale => 'Font Size';

  @override
  String get settings_fontScale_previewSmall => '光影落在画布上。';

  @override
  String get settings_fontScale_previewMedium => '色から物語が生まれる。';

  @override
  String get settings_fontScale_previewLarge => 'Let colors tell a story.';

  @override
  String get settings_fontScale_done => 'Done';

  @override
  String get settings_historyClickBehavior => 'History click behavior';

  @override
  String get settings_historyClickBehavior_classic => 'Classic';

  @override
  String get settings_historyClickBehavior_classicDescription =>
      'Click a history image to open its details';

  @override
  String get settings_historyClickBehavior_linked => 'Linked preview';

  @override
  String get settings_historyClickBehavior_linkedDescription =>
      'Click to switch the central preview, double-click or hold for details, and browse with Left/Right';

  @override
  String get settings_outputViewer => 'Output viewer';

  @override
  String get settings_outputViewer_canvas => 'Free canvas';

  @override
  String get settings_outputViewer_canvasDescription =>
      'NAI5-style infinite canvas: all generated images laid out by batch, middle/Shift+left drag to pan, Ctrl+wheel to zoom, WASD/f/q to navigate';

  @override
  String get settings_outputViewer_simple => 'Simple view';

  @override
  String get settings_outputViewer_simpleDescription =>
      'Classic centered/grid preview for low-spec machines or the familiar layout';

  @override
  String get settings_canvasLockCamera => 'Lock canvas camera';

  @override
  String get settings_canvasLockCameraDescription =>
      'Disables wheel zoom/pan, drag panning, WASD and other manual camera input; auto-select and navigation jumps still work';

  @override
  String get settings_canvasReducedMotion => 'Reduce canvas motion';

  @override
  String get settings_canvasReducedMotionDescription =>
      'Camera flights, zooms and inertia become instant, reducing animation';

  @override
  String get image_viewDetail => 'View details';

  @override
  String get settings_defaultImagesPath =>
      'Default (Documents/NAI_Launcher/images/)';

  @override
  String get settings_defaultHivePath =>
      'Default (%APPDATA%/NAI_Launcher/hive/)';

  @override
  String get settings_protectionFeatures => 'Protection Features';

  @override
  String get settings_stripMetadataTitle =>
      'Remove all metadata when copying or dragging';

  @override
  String get settings_stripMetadataSubtitle =>
      'Create a sanitized copy, remove PNG text chunks, EXIF, and NAI steganographic watermark data, and avoid exposing the original path while dragging.';

  @override
  String get settings_confirmDangerousActionsTitle =>
      'Double-confirm dangerous asset actions';

  @override
  String get settings_confirmDangerousActionsSubtitle =>
      'Deleting, moving, or batch-moving local assets will show an additional protection confirmation.';

  @override
  String get settings_warnExternalImageSendTitle =>
      'Confirm before sending to external services';

  @override
  String get settings_warnExternalImageSendSubtitle =>
      'Confirm before local images cross the app boundary to LLMs, NovelAI, ComfyUI, or similar services.';

  @override
  String get settings_preventOverwriteTitle =>
      'Avoid overwriting existing files on export';

  @override
  String get settings_preventOverwriteSubtitle =>
      'Automatically number duplicate export or package paths to avoid replacing existing assets by mistake.';

  @override
  String get settings_warnHighAnlasCostTitle => 'High Anlas cost warning';

  @override
  String settings_warnHighAnlasCostSubtitle(Object threshold) {
    return 'Show a confirmation before generation when the estimated single request cost reaches $threshold Anlas.';
  }

  @override
  String get settings_highAnlasCostThresholdTitle => 'Anlas Warning Threshold';

  @override
  String get settings_setHighAnlasCostThresholdTitle =>
      'Set Anlas Warning Threshold';

  @override
  String get settings_threshold => 'Threshold';

  @override
  String get settings_highAnlasCostThresholdHelper =>
      'Show a confirmation when the estimated single generation cost reaches or exceeds this value.';

  @override
  String get settings_limitGenerationIntervalTitle =>
      'Limit generation frequency';

  @override
  String get settings_limitGenerationIntervalSubtitle =>
      'Require the configured minimum time between generation starts. The Generate button is disabled during the cooldown.';

  @override
  String get settings_generationIntervalTitle => 'Generation interval';

  @override
  String settings_generationIntervalValue(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String get settings_setGenerationIntervalTitle => 'Set Generation Interval';

  @override
  String get settings_generationIntervalHelper =>
      'Enter 1–3600 seconds. The cooldown starts when generation begins.';

  @override
  String get settings_generationIntervalJitterTitle => 'Interval jitter';

  @override
  String settings_generationIntervalJitterValue(Object percent) {
    return '±$percent%';
  }

  @override
  String get settings_setGenerationIntervalJitterTitle => 'Set Interval Jitter';

  @override
  String get settings_generationIntervalJitterHelper =>
      'Each cooldown is drawn at random from base interval ± this percentage, so the pacing is less mechanical. Enter 0–50; 0 disables jitter.';

  @override
  String get settings_confirmExternalSendTitle =>
      'Protection Mode: Confirm External Send';

  @override
  String settings_confirmExternalSendContent(Object count, Object target) {
    return 'About to send $count local image(s) to $target. The image data will leave the local app boundary. Confirm this is expected.';
  }

  @override
  String get settings_confirmExternalSend => 'Send';

  @override
  String get settings_highAnlasCostTitle => 'Anlas usage reminder';

  @override
  String settings_highAnlasCostContent(Object cost, Object threshold) {
    return 'This request is estimated to cost $cost Anlas, which reaches or exceeds your $threshold Anlas warning threshold. Continue generation?';
  }

  @override
  String get settings_continueGeneration => 'Continue Generation';

  @override
  String get dataSource_syncNow => 'Sync Now';

  @override
  String get settings_comfyUiEnable => 'Enable ComfyUI Integration';

  @override
  String get settings_comfyUiDisabledSubtitle =>
      'When disabled, local upscale and other ComfyUI features are hidden';

  @override
  String get settings_comfyUiServerUrl => 'Server URL';

  @override
  String get settings_comfyUiConnectionSuccess => 'Connection successful';

  @override
  String get settings_comfyUiConnectionSuccessFull =>
      'ComfyUI connection successful';

  @override
  String settings_comfyUiConnectionFailed(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String get settings_comfyUiConnected => 'Connected';

  @override
  String get settings_comfyUiDisconnect => 'Disconnect';

  @override
  String get settings_comfyUiWorkflowManagement => 'Workflow Management';

  @override
  String get settings_comfyUiBuiltinWorkflows => 'Built-in Workflows';

  @override
  String get settings_comfyUiCustomWorkflows => 'Custom Workflows';

  @override
  String get settings_comfyUiNoCustomWorkflows =>
      'No custom workflows yet. Click \"Import\" to add a ComfyUI workflow.';

  @override
  String settings_comfyUiSlotCount(Object count) {
    return '$count slots';
  }

  @override
  String get settings_comfyUiBuiltin => 'Built-in';

  @override
  String get settings_comfyUiDeleteWorkflowTitle => 'Delete Workflow';

  @override
  String settings_comfyUiDeleteWorkflowContent(Object name) {
    return 'Delete workflow \"$name\"? This cannot be undone.';
  }

  @override
  String settings_comfyUiDeleted(Object name) {
    return 'Deleted: $name';
  }

  @override
  String get settings_comfyUiNoResponse => 'Server did not respond';

  @override
  String get settings_comfyUiStatusDisconnected => 'Disconnected';

  @override
  String get settings_comfyUiStatusConnecting => 'Connecting...';

  @override
  String get settings_comfyUiStatusConnected => 'Connected';

  @override
  String get settings_comfyUiStatusError => 'Connection error';

  @override
  String get settings_comfyUiCategoryEnhance => 'Enhance/Upscale';

  @override
  String get settings_comfyUiCategoryImg2Img => 'Image2Image';

  @override
  String get settings_comfyUiCategoryInpaint => 'Inpaint';

  @override
  String get settings_comfyUiCategoryTxt2Img => 'Text-to-Image';

  @override
  String get settings_comfyUiCategoryCustom => 'Custom';

  @override
  String get comfyWorkflow_seedvr2UpscaleName => 'SeedVR2 Upscale';

  @override
  String get comfyWorkflow_seedvr2UpscaleDescription =>
      'Upscale with the SeedVR2 AI model. Produces high-quality results.';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleName => 'SeedVR2 Tiled Upscale';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleDescription =>
      'Use SeedVR2TilingUpscaler for tiled upscale to reduce VRAM pressure on large images.';

  @override
  String get comfyWorkflow_modelUpscaleName => 'ComfyUI Standard Upscale Model';

  @override
  String get comfyWorkflow_modelUpscaleDescription =>
      'Load a standard upscale model with ComfyUI UpscaleModelLoader, then correct the final scale with Lanczos.';

  @override
  String get comfyWorkflow_rtxUpscaleName => 'RTX Upscale';

  @override
  String get comfyWorkflow_rtxUpscaleDescription =>
      'Use the Nvidia RTX Video Super Resolution node for local upscaling.';

  @override
  String get comfyWorkflowSlot_inputImage => 'Input Image';

  @override
  String get comfyWorkflowSlot_targetShortSide => 'Target Short Side';

  @override
  String get comfyWorkflowSlot_targetLongSide => 'Target Long Side';

  @override
  String get comfyWorkflowSlot_upscaleModel => 'Upscale Model';

  @override
  String get comfyWorkflowSlot_randomSeed => 'Random Seed';

  @override
  String get comfyWorkflowSlot_outputImage => 'Output Image';

  @override
  String get comfyWorkflowSlot_tileWidth => 'Tile Width';

  @override
  String get comfyWorkflowSlot_tileHeight => 'Tile Height';

  @override
  String get comfyWorkflowSlot_tileUpscaleResolution =>
      'Tile Upscale Resolution';

  @override
  String get comfyWorkflowSlot_targetWidth => 'Target Width';

  @override
  String get comfyWorkflowSlot_targetHeight => 'Target Height';

  @override
  String get comfyWorkflowSlot_scale => 'Scale';

  @override
  String get comfyWorkflow_parameters => 'Parameters';

  @override
  String get comfyWorkflow_selectImage => 'Click to select image';

  @override
  String comfyWorkflow_pickImageFailed(Object error) {
    return 'Failed to select image: $error';
  }

  @override
  String get comfyWorkflow_useResult => 'Use Result';

  @override
  String get comfyWorkflow_execute => 'Run';

  @override
  String get comfyWorkflow_uploadingImage => 'Uploading image...';

  @override
  String get comfyWorkflow_queued => 'Queued...';

  @override
  String comfyWorkflow_runningSteps(Object current, Object total) {
    return 'Processing $current/$total';
  }

  @override
  String get comfyWorkflow_processing => 'Processing...';

  @override
  String get comfyWorkflow_complete => 'Complete';

  @override
  String comfyWorkflow_imageCount(Object count) {
    return '$count images';
  }

  @override
  String get cacheStats_title => 'Cache Statistics';

  @override
  String cacheStats_autoRefreshUpdated(Object time) {
    return 'Auto refresh · Last updated: $time';
  }

  @override
  String cacheStats_secondsAgo(Object seconds) {
    return '$seconds seconds ago';
  }

  @override
  String get cacheStats_resetStats => 'Reset statistics';

  @override
  String get cacheStats_statsReset => 'Statistics reset';

  @override
  String get cacheStats_l1Memory => 'L1 Memory Cache';

  @override
  String get cacheStats_l2Hive => 'L2 Hive Cache';

  @override
  String get cacheStats_l3Sqlite => 'L3 SQLite Database';

  @override
  String get galleryCache_rescanTitle => 'Rescan Gallery';

  @override
  String get galleryCache_rescanContent =>
      'This will:\n\n1. Check data consistency and mark missing files\n2. Scan new and changed files\n3. Retry metadata extraction that failed before, including failed records\n\nThis will not clear existing data or delete image files.';

  @override
  String get galleryCache_startScan => 'Start Scan';

  @override
  String get galleryCache_scanAlreadyRunning =>
      'A scan task is already running. Please wait for it to finish.';

  @override
  String get galleryCache_preparing => 'Preparing...';

  @override
  String get galleryCache_noGalleryFolder => 'Gallery folder is not set';

  @override
  String galleryCache_scanningPhase(Object processed, Object total) {
    return 'Scanning $processed/$total...';
  }

  @override
  String get galleryCache_scanComplete => 'Scan complete';

  @override
  String galleryCache_scanFailed(Object error) {
    return 'Scan failed: $error';
  }

  @override
  String get galleryCache_rescan => 'Rescan';

  @override
  String get galleryCache_rescanSubtitle =>
      'Check data consistency, find missing files, and extract metadata';

  @override
  String get galleryCache_scanning => 'Scanning...';

  @override
  String get galleryCache_scanAction => 'Scan';

  @override
  String get galleryCache_evictThumbnailsTitle => 'Clean Thumbnail Cache';

  @override
  String get galleryCache_evictThumbnailsSubtitle =>
      'Evict least-recently-used .thumbs files over the limit (originals untouched)';

  @override
  String get galleryCache_evictThumbnailsContent =>
      'Evicts the on-disk thumbnail cache over its limit, least recently used first.\n\nOnly .thumb.jpg files inside .thumbs directories are deleted; original images are never removed or modified. Removed thumbnails will be regenerated on demand the next time you browse.';

  @override
  String get galleryCache_evictThumbnailsStart => 'Clean Now';

  @override
  String get galleryCache_evictThumbnailsRunning =>
      'Cleaning thumbnail cache...';

  @override
  String galleryCache_evictThumbnailsDone(int count, String size) {
    return 'Removed $count thumbnails, freed $size MB';
  }

  @override
  String get galleryCache_evictThumbnailsNone =>
      'Thumbnail cache is under the limit; nothing to clean';

  @override
  String galleryCache_evictThumbnailsFailed(Object error) {
    return 'Failed to clean thumbnail cache: $error';
  }

  @override
  String get workflowImport_title => 'Import ComfyUI Workflow';

  @override
  String workflowImport_step(Object current, Object title) {
    return 'Step $current/4: $title';
  }

  @override
  String get workflowImport_stepFile => 'Select Workflow File';

  @override
  String get workflowImport_stepInfo => 'Workflow Info';

  @override
  String get workflowImport_stepSlots => 'Confirm Slot Config';

  @override
  String get workflowImport_stepDone => 'Complete Import';

  @override
  String get workflowImport_previous => 'Previous';

  @override
  String get workflowImport_next => 'Next';

  @override
  String get workflowImport_finish => 'Finish Import';

  @override
  String get workflowImport_defaultName => 'Custom Workflow';

  @override
  String get workflowImport_fileInstructions =>
      'Select a workflow_api.json file exported from ComfyUI.\n\nIn ComfyUI, open the menu and choose Export (API format) to get this file.';

  @override
  String workflowImport_nodeCount(Object count) {
    return '$count nodes';
  }

  @override
  String get workflowImport_reselect => 'Click to choose another file';

  @override
  String get workflowImport_selectWorkflowApi =>
      'Click to select workflow_api.json';

  @override
  String get workflowImport_invalidTopLevel =>
      'Invalid file format: top level should be a JSON object';

  @override
  String get workflowImport_noComfyNodes =>
      'No ComfyUI nodes detected. Make sure this is an API-format export.';

  @override
  String workflowImport_readFailed(Object error) {
    return 'Failed to read file: $error';
  }

  @override
  String get workflowImport_analysisResult => 'Automatic Analysis Result';

  @override
  String get workflowImport_inputImageNodes => 'Input image nodes';

  @override
  String get workflowImport_adjustableParams => 'Adjustable parameters';

  @override
  String get workflowImport_outputNodes => 'Output nodes';

  @override
  String get workflowImport_totalNodes => 'Total nodes';

  @override
  String workflowImport_countUnit(Object count) {
    return '$count';
  }

  @override
  String get workflowImport_workflowName => 'Workflow Name *';

  @override
  String get workflowImport_description => 'Description';

  @override
  String get workflowImport_category => 'Category';

  @override
  String get workflowImport_slotsHint =>
      'Select the slots to expose in the UI. Input and output slots should usually stay enabled; parameters that users do not need to adjust can be disabled.';

  @override
  String get workflowImport_inputSection => 'Input';

  @override
  String get workflowImport_outputSection => 'Output';

  @override
  String get workflowImport_parameterSection => 'Parameters';

  @override
  String get workflowImport_noSlotsWarning =>
      'No usable slots were detected. This workflow may not integrate correctly.\nMake sure the workflow includes LoadImage and SaveImage/SaveImageWebsocket nodes.';

  @override
  String workflowImport_nodeRef(Object node) {
    return 'Node $node';
  }

  @override
  String get workflowImport_confirmTitle => 'About to import this workflow';

  @override
  String get workflowImport_name => 'Name';

  @override
  String get workflowImport_inputSlots => 'Input Slots';

  @override
  String get workflowImport_parameterSlots => 'Parameter Slots';

  @override
  String get workflowImport_outputSlots => 'Output Slots';

  @override
  String get workflowImport_afterImportHint =>
      'After import, it can be used from the ComfyUI workflow list on the generation screen.';

  @override
  String workflowImport_success(Object name) {
    return 'Workflow \"$name\" imported';
  }

  @override
  String get shortcut_settings_help => 'View shortcut help';

  @override
  String get shortcut_settings_show_in_menus => 'Show in menus';

  @override
  String shortcut_settings_defaultShortcut(Object shortcut) {
    return 'Default: $shortcut';
  }

  @override
  String get shortcut_settings_unassigned => 'Not set';

  @override
  String get shortcut_settings_no_matches => 'No matching shortcuts found';

  @override
  String get shortcut_settings_reset_all_title => 'Reset All Shortcuts';

  @override
  String get shortcut_settings_reset_all_confirm =>
      'Reset all shortcuts to their default settings? This cannot be undone.';

  @override
  String get shortcut_settings_reset_to_default => 'Reset to default';

  @override
  String get toast_previewUpdated => 'Preview image updated';

  @override
  String toast_styleReferenceLimit(Object max) {
    return 'Style References reached the limit ($max images)';
  }

  @override
  String get toast_noValidMaskIgnored =>
      'No valid mask detected; save result was ignored.';

  @override
  String get toast_kritaBusy =>
      'Krita Bridge is generating. Wait for the current task to finish.';

  @override
  String get toast_kritaNotConnected =>
      'Krita is not connected. Enable the bridge in Settings and connect the plugin first.';

  @override
  String get toast_sentToKrita => 'Image sent to Krita';

  @override
  String get toast_kritaUnsupportedImageFormat =>
      'This image format cannot be sent to Krita. Use a common image format.';

  @override
  String toast_deletedNamed(Object name) {
    return 'Deleted: $name';
  }

  @override
  String get toast_vibeParamSaveReencodeFailed =>
      'Failed to save parameters because Vibe re-encoding failed';

  @override
  String get toast_exportSuccess => 'Export successful';

  @override
  String toast_exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get toast_selectVibeToExport => 'Select a Vibe to export first';

  @override
  String get toast_embedPngSingleVibeOnly =>
      'Embedding into PNG only supports exporting one Vibe';

  @override
  String get toast_selectPngCarrier => 'Select a PNG carrier image for export';

  @override
  String get toast_renameSuccess => 'Renamed successfully';

  @override
  String get toast_paramsSaved => 'Parameters saved';

  @override
  String get toast_paramsSaveFailed => 'Failed to save parameters';

  @override
  String get toast_dropNoReadableImageOrVibe =>
      'The drop source did not provide a readable image or Vibe file';

  @override
  String get toast_contentCannotBeEmpty => 'Content cannot be empty';

  @override
  String get toast_addedToLibrary => 'Added to library';

  @override
  String toast_addFailed(Object error) {
    return 'Add failed: $error';
  }

  @override
  String get toast_libraryNotLoaded => 'Library is not loaded';

  @override
  String get toast_noValidTagContent => 'No valid tag content';

  @override
  String get toast_allTagsAlreadyExist =>
      'All tags already exist in the library';

  @override
  String get toast_noAddableTags => 'No tags can be added';

  @override
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped) {
    return 'Added $added tags, skipped $skipped duplicate tags';
  }

  @override
  String get toast_favorited => 'Favorited';

  @override
  String get toast_unfavorited => 'Unfavorited';

  @override
  String toast_favoriteUpdateFailed(Object error) {
    return 'Failed to update favorite state: $error';
  }

  @override
  String toast_packingImages(Object count) {
    return 'Packing $count images...';
  }

  @override
  String toast_packedImages(Object count) {
    return 'Packed $count images';
  }

  @override
  String get toast_packFailed => 'Pack failed';

  @override
  String toast_packFailedWithError(Object error) {
    return 'Pack failed: $error';
  }

  @override
  String get toast_saveDirNotSet => 'Save directory is not set';

  @override
  String toast_savedTo(Object path) {
    return 'Saved to $path';
  }

  @override
  String get toast_tagAlreadyExists => 'Tag already exists';

  @override
  String get toast_nameRequired => 'Enter a name';

  @override
  String get toast_savedToVibeLibrary => 'Saved to Vibe Library';

  @override
  String get toast_saveBundleFailed => 'Failed to save bundle';

  @override
  String get toast_saveEntryFailed => 'Failed to save entry';

  @override
  String get toast_imagePromptCopied => 'Prompt copied';

  @override
  String get toast_imageHasNoPrompt => 'This image has no Prompt';

  @override
  String get toast_useDeleteButton => 'Use the delete button in the UI';

  @override
  String get toast_imageDataUnavailable =>
      'Image data is unavailable and cannot be copied';

  @override
  String get toast_vibeDataCopied => 'Vibe data copied';

  @override
  String get toast_tagCopied => 'Tags copied';

  @override
  String get toast_characterPromptCopied => 'Character prompt copied';

  @override
  String toast_copiedTitle(Object title) {
    return '$title copied';
  }

  @override
  String toast_replacedVibesCount(Object count, Object name) {
    return 'Replaced with $count Vibes: $name';
  }

  @override
  String toast_sentVibesCount(Object count, Object name) {
    return 'Sent $count Vibes to generation: $name';
  }

  @override
  String toast_replacedVibe(Object name) {
    return 'Replaced with: $name';
  }

  @override
  String toast_sentVibeToGeneration(Object name) {
    return 'Sent to generation: $name';
  }

  @override
  String get toast_unreadableDroppedImageSource =>
      'The drop source did not provide a readable image file or image URL';

  @override
  String toast_appendedStyleReferences(Object count) {
    return 'Appended $count Style References';
  }

  @override
  String get toast_appendedPreencodedVibe =>
      'Appended 1 Style Reference (reused pre-encoded Vibe)';

  @override
  String get toast_addedPreencodedVibe =>
      'Added Style Reference (reused pre-encoded Vibe, saved 2 Anlas)';

  @override
  String toast_vibesMissingEncoding(Object count) {
    return '$count Vibes are missing encoded data and cannot be saved';
  }

  @override
  String toast_savedBundle(Object count) {
    return 'Saved Bundle ($count Vibes)';
  }

  @override
  String toast_extractMetadataFailed(Object error) {
    return 'Failed to extract metadata: $error';
  }

  @override
  String get toast_renameNameRequired => 'Name is required';

  @override
  String get toast_renameNameConflict =>
      'Name already exists. Use another name.';

  @override
  String get toast_renameEntryNotFound =>
      'The entry no longer exists and may have been deleted';

  @override
  String get toast_renameFilePathMissing =>
      'This entry has no file path and cannot be renamed';

  @override
  String get toast_renameFileFailed =>
      'Failed to rename file. Try again later.';

  @override
  String get toast_renameFailed => 'Rename failed. Try again later.';

  @override
  String toast_processImageFailed(Object error) {
    return 'Failed to process image: $error';
  }

  @override
  String get toast_savePreviewFailed => 'Failed to save preview image';

  @override
  String get common_justNow => 'Just now';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String get common_saving => 'Saving...';

  @override
  String get common_pleaseWait => 'Please wait';

  @override
  String get common_change => 'Change';

  @override
  String get common_expand => 'Expand';

  @override
  String get common_collapse => 'Collapse';

  @override
  String get vibeLibrary_emptySearchTitle => 'No matching Vibes';

  @override
  String get vibeLibrary_emptySearchSubtitle => 'Try a different keyword';

  @override
  String get vibeLibrary_emptyFavoritesTitle => 'No favorite Vibes yet';

  @override
  String get vibeLibrary_emptyFavoritesSubtitle =>
      'Click the heart icon to favorite a Vibe';

  @override
  String get vibeLibrary_emptyCategoryTitle => 'No Vibes in this category';

  @override
  String get vibeLibrary_emptyCategorySubtitle =>
      'Switch to \"All Vibes\" to see all entries';

  @override
  String get vibeLibrary_emptyNoMatchesTitle => 'No matching results';

  @override
  String get vibeLibrary_emptySaveFromGenerationHint =>
      'Save Vibes from the generation page to add them to the library';

  @override
  String get vibe_nameRequired => 'Name is required';

  @override
  String get vibe_import_namingTitle => 'Name Vibe';

  @override
  String get vibe_import_nameConflictOverwrite =>
      'This name already exists and will be overwritten';

  @override
  String get vibe_previewLoadFailed => 'Failed to load preview';

  @override
  String get vibe_import_applyToRemainingFiles =>
      'Apply to all remaining files';

  @override
  String get vibe_import_applyNamingToRemainingFiles =>
      'Use this naming rule for the remaining files';

  @override
  String get vibe_encodeImageTitle => 'Encode Image as Vibe';

  @override
  String get vibe_imagePreview => 'Image preview';

  @override
  String get vibe_encodeStartButton => 'Start Encoding';

  @override
  String get vibe_encodeImageInProgress => 'Encoding image...';

  @override
  String vibe_encodeErrorImage(Object fileName) {
    return 'Image: $fileName';
  }

  @override
  String vibe_encodeErrorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get vibe_encodeSkipImage => 'Skip this image';

  @override
  String get detail_sendToImg2Img => 'Send to Image2Image';

  @override
  String get detail_loadingImage => 'Loading image...';

  @override
  String get detail_imageLoadFailed => 'Failed to load image';

  @override
  String get detail_noImage => 'No image';

  @override
  String get detail_parsingMetadata => 'Parsing metadata...';

  @override
  String get detail_noMetadata => 'This image has no metadata';

  @override
  String get detail_metadata => 'Metadata';

  @override
  String get detail_imageDetails => 'Image Details';

  @override
  String get detail_basicInfo => 'Basic Info';

  @override
  String get detail_fileName => 'File Name';

  @override
  String get detail_modifiedTime => 'Modified';

  @override
  String get detail_fileSize => 'File Size';

  @override
  String get detail_noContent => '(No content)';

  @override
  String get detail_saveBlock => 'Save as Block';

  @override
  String get saveBlock_title => 'Save as Block';

  @override
  String get saveBlock_nameLabel => 'Block title';

  @override
  String get saveBlock_nameHint => 'Enter block title';

  @override
  String get saveBlock_nameRequired => 'Please enter a block title';

  @override
  String get saveBlock_selectContent => 'Select content to save';

  @override
  String get saveBlock_negativeSuffix => 'Negative';

  @override
  String get saveBlock_saved => 'Saved to block library';

  @override
  String detail_copyLabel(Object label) {
    return 'Copy $label';
  }

  @override
  String get detail_copyCharacterPrompt => 'Copy Character Prompt';

  @override
  String get detail_copyAllVibeData => 'Copy all Vibe data';

  @override
  String get detail_saveToVibeLibrary => 'Save to Vibe Library';

  @override
  String get comfyImport_detectedTitle =>
      'Detected ComfyUI multi-character prompt';

  @override
  String comfyImport_characterList(Object count) {
    return 'Character List ($count)';
  }

  @override
  String get comfyImport_usePositionInfo => 'Use position information';

  @override
  String get comfyImport_usePositionInfoSubtitle =>
      'Map ComfyUI regions to NAI character positions';

  @override
  String comfyImport_convertCharacters(Object count) {
    return 'Convert $count characters';
  }

  @override
  String get comfyImport_syntaxCouple => 'COUPLE syntax';

  @override
  String get comfyImport_syntaxAndMask => 'AND+MASK syntax';

  @override
  String get comfyImport_syntaxPipe => 'Pipe format';

  @override
  String get comfyImport_syntaxUnknown => 'Unknown syntax';

  @override
  String get comfyImport_globalPrompt => 'Global Prompt';

  @override
  String get checkForUpdate => 'Check for Updates';

  @override
  String get neverChecked => 'Never checked';

  @override
  String lastCheckedAt(Object time) {
    return 'Last checked: $time';
  }

  @override
  String get includePrereleaseUpdates => 'Include Prerelease Versions';

  @override
  String get includePrereleaseUpdatesDescription =>
      'Include beta/alpha versions when checking for updates';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateChecking => 'Checking for updates...';

  @override
  String get updateDownloading => 'Downloading update...';

  @override
  String get updateInstalling => 'Starting installer...';

  @override
  String get updateUpToDate => 'Already up to date';

  @override
  String get updateError => 'Failed to check for updates';

  @override
  String get currentVersion => 'Current Version';

  @override
  String get latestVersion => 'Latest Version';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String updateDownloadingProgress(Object percent) {
    return 'Downloading update package: $percent%';
  }

  @override
  String updateDownloadSizeSpeed(Object received, Object total, Object speed) {
    return '$received / $total · $speed';
  }

  @override
  String get updateDownloaded => 'Update Package Ready';

  @override
  String updateDownloadedHint(Object version) {
    return 'v$version has been downloaded and verified. Installing will close the app and restart it automatically.';
  }

  @override
  String get updateInstallAndRestart => 'Install and Restart';

  @override
  String get updateInstallNow => 'Install Now';

  @override
  String get updateInstallLater => 'Install Later';

  @override
  String get updateDownload => 'Download Update';

  @override
  String get updateDownloadCancelled =>
      'Download cancelled; you can resume later';

  @override
  String get updateDownloadFailed => 'Failed to download the update';

  @override
  String get updateInstallFailed => 'Failed to install the update';

  @override
  String get updateInstallingHint =>
      'The installer has started. The app will close and finish updating automatically.';

  @override
  String get remindMeLater => 'Remind Me in 4 Hours';

  @override
  String updateNoticeAvailable(Object version) {
    return 'Version v$version is available';
  }

  @override
  String get updateNoticeAvailableSubtitle =>
      'Download and finish the update automatically in the app';

  @override
  String get updateNoticeManualSubtitle =>
      'This platform must be updated manually from the Release page';

  @override
  String updateNoticeReady(Object version) {
    return 'Version v$version is ready';
  }

  @override
  String get updateNoticeReadySubtitle =>
      'The package is verified and ready to install on restart';

  @override
  String get updateNoticeFailed => 'The previous update did not finish';

  @override
  String get updateViewDetails => 'View Update';

  @override
  String updateSettingsAvailable(Object version) {
    return 'v$version is available; select to view details';
  }

  @override
  String updateSettingsReady(Object version) {
    return 'v$version is downloaded; select to install';
  }

  @override
  String get goToDownload => 'Go to Download';

  @override
  String get cannotOpenUrl => 'Cannot open link';

  @override
  String get model3d_editorTitle => '3D Model Layer';

  @override
  String get model3d_addMannequin => 'Add Built-in Mannequin';

  @override
  String get model3d_importModel => 'Import Model (.glb/.gltf)';

  @override
  String get model3d_emptyHint =>
      'Scene is empty. Add a mannequin or import a model.';

  @override
  String get model3d_apply => 'Apply to Layer';

  @override
  String get model3d_modeTransform => 'Transform';

  @override
  String get model3d_modePose => 'Pose';

  @override
  String get model3d_gizmoTranslate => 'Move';

  @override
  String get model3d_gizmoRotate => 'Rotate';

  @override
  String get model3d_gizmoScale => 'Scale';

  @override
  String get model3d_undo => 'Undo';

  @override
  String get model3d_resetPose => 'Reset Pose';

  @override
  String get model3d_replaceConfirm =>
      'Replace the current model? Unapplied pose will be lost.';

  @override
  String get model3d_discardConfirm => 'Discard unapplied changes?';

  @override
  String get model3d_missingModel =>
      'Model file is missing. You can re-import it.';

  @override
  String get model3d_loadError => 'Failed to load model';

  @override
  String get model3d_light => 'Lighting';

  @override
  String get model3d_lightIntensity => 'Intensity';

  @override
  String get model3d_lightAzimuth => 'Azimuth';

  @override
  String get model3d_lightElevation => 'Elevation';

  @override
  String get model3d_addLayerTooltip => 'Add 3D Model Layer';

  @override
  String get model3d_webview2Missing =>
      'The 3D editor requires the Microsoft Edge WebView2 Runtime. It ships with Windows 10/11; if missing, install the Evergreen runtime from Microsoft and retry.';

  @override
  String get nav_preciseRefLibrary => 'Precise Ref Library';

  @override
  String get preciseRefLib_title => 'Precise Reference Library';

  @override
  String get preciseRefLib_searchHint => 'Search references...';

  @override
  String get preciseRefLib_empty =>
      'Drop or paste images here to build your library';

  @override
  String get preciseRefLib_emptyHint =>
      'You can also right-click images in preview, history, or gallery to save them here';

  @override
  String get preciseRefLib_import => 'Import Images';

  @override
  String preciseRefLib_entryCount(int count) {
    return '$count items';
  }

  @override
  String get preciseRefLib_sendToPreciseRef => 'Send to Precise Reference';

  @override
  String get preciseRefLib_sendToImg2Img => 'Send to Image to Image';

  @override
  String get preciseRefLib_editEntry => 'Edit Parameters';

  @override
  String get preciseRefLib_deleteEntry => 'Delete';

  @override
  String get preciseRefLib_confirmDeleteTitle => 'Delete Entry';

  @override
  String preciseRefLib_confirmDelete(String name) {
    return 'Delete \"$name\"? The image file will also be removed.';
  }

  @override
  String preciseRefLib_saved(String name) {
    return 'Saved \"$name\" to Precise Ref Library';
  }

  @override
  String get preciseRefLib_savedHint =>
      'You can edit parameters in the library';

  @override
  String preciseRefLib_sent(String name) {
    return 'Sent \"$name\" to Precise Reference';
  }

  @override
  String preciseRefLib_sentToImg2Img(String name) {
    return 'Sent \"$name\" to Image to Image';
  }

  @override
  String get preciseRefLib_imageMissing => 'Image file is missing';

  @override
  String get preciseRefLib_invalidImage =>
      'The image format is unsupported or the file is corrupt';

  @override
  String get preciseRefLib_deleteFailed =>
      'Delete failed. The entry and original image were kept; try again later';

  @override
  String get preciseRefLib_favoritesOnly => 'Favorites only';

  @override
  String get preciseRefLib_sortBy => 'Sort by';

  @override
  String get preciseRefLib_sortCreatedAt => 'Created';

  @override
  String get preciseRefLib_sortLastUsed => 'Last used';

  @override
  String get preciseRefLib_sortUsedCount => 'Most used';

  @override
  String get preciseRefLib_sortName => 'Name';

  @override
  String preciseRefLib_importedCount(int count) {
    return 'Imported $count images';
  }

  @override
  String preciseRefLib_loadFailed(String error) {
    return 'Failed to load the Precise Reference Library: $error';
  }

  @override
  String preciseRefLib_importFailed(String error) {
    return 'Failed to save to the Precise Reference Library: $error';
  }

  @override
  String preciseRefLib_importFailedCount(int count) {
    return '$count images could not be imported into the Precise Reference Library';
  }

  @override
  String get preciseRefLib_fromLibrary => 'From Library';

  @override
  String get preciseRefLib_saveCurrentToLibrary => 'Save to Library';

  @override
  String preciseRefLib_saveCurrentCount(int count) {
    return 'Saved $count references to library';
  }

  @override
  String get preciseRefLib_selectorTitle => 'Select from Precise Ref Library';

  @override
  String preciseRefLib_selectorConfirm(int count) {
    return 'Add Selected ($count)';
  }

  @override
  String get preciseRefLib_nameLabel => 'Name';

  @override
  String get preciseRefLib_typeFilterAll => 'All';

  @override
  String get img2img_fromPreciseRefLibrary => 'From Precise Ref Library';

  @override
  String get localGallery_saveToPreciseRefLibrary =>
      'Save to Precise Ref Library';

  @override
  String get drop_saveToPreciseRefLibrary => 'Save to Precise Ref Library';

  @override
  String get common_enabled => 'Enabled';

  @override
  String get common_disabled => 'Disabled';

  @override
  String bulkAction_selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get comfyTask_errorConnectionFailed =>
      'Unable to connect to the ComfyUI server';

  @override
  String get comfyTask_errorConnectionUnavailable =>
      'The ComfyUI connection is unavailable';

  @override
  String get comfyTask_errorExecutionFailedGeneric =>
      'ComfyUI execution failed';

  @override
  String comfyTask_errorExecutionFailed(String error) {
    return 'ComfyUI execution failed: $error';
  }

  @override
  String get comfyTask_errorTimeout =>
      'The ComfyUI task timed out after 10 minutes';

  @override
  String comfyTask_errorWorkflowNotFound(String workflowId) {
    return 'Workflow not found: $workflowId';
  }

  @override
  String get comfyWorkflowSlot_vaeEncodeTileSize => 'VAE encode tile size';

  @override
  String get comfyWorkflowSlot_vaeDecodeTileSize => 'VAE decode tile size';

  @override
  String get comfyWorkflowSlot_blocksToSwap => 'Blocks to swap';

  @override
  String get comfyWorkflowSlot_swapIoComponents => 'Swap I/O components';

  @override
  String localGallery_firstIndexHint(int count) {
    return 'Detected $count images. The initial index may take a few minutes; you can continue using the app.';
  }

  @override
  String get localGallery_errorPermissionDenied =>
      'Unable to access the image folder. Check the folder permissions.';

  @override
  String localGallery_errorScanFailed(String error) {
    return 'Failed to scan images: $error';
  }

  @override
  String localGallery_errorInitializationFailed(String error) {
    return 'Failed to initialize the gallery: $error';
  }

  @override
  String get localGallery_errorServiceInitializing =>
      'The gallery service is still initializing. Try again shortly.';

  @override
  String localGallery_errorDatabaseFailed(String error) {
    return 'Gallery database error: $error';
  }

  @override
  String localGallery_errorRefreshFailed(String error) {
    return 'Failed to refresh the gallery: $error';
  }

  @override
  String localGallery_errorFilterFailed(String error) {
    return 'Failed to apply gallery filters: $error';
  }

  @override
  String localGallery_errorFavoriteFailed(String error) {
    return 'Failed to update the favorite status: $error';
  }

  @override
  String localGallery_errorRebuildFailed(String error) {
    return 'Failed to rebuild the gallery index: $error';
  }

  @override
  String get common_optional => 'Optional';

  @override
  String get common_emptyValue => '(Empty)';

  @override
  String get common_clickToRetry => 'Click to retry';

  @override
  String get common_opening => 'Opening...';

  @override
  String get common_swap => 'Swap';

  @override
  String get addToLibrary_displayNameHint =>
      'Enter a name to identify this entry';

  @override
  String get addToLibrary_tagHint => 'Enter a tag and press Enter to add it';

  @override
  String get drop_saveVibeBundle => 'Save Vibe Bundle';

  @override
  String get history_dragFilePreparationFailed =>
      'Failed to prepare the drag file. Try again later.';

  @override
  String get history_dragFilePreparing => 'Preparing the drag file...';

  @override
  String get history_dragFileNotReady => 'The drag file is not ready yet';

  @override
  String get vibe_import_overwriteOriginalParams =>
      'Replace Original Vibe Parameters';

  @override
  String vibe_import_overwriteOriginalParamsHint(String name) {
    return 'Only replace the library parameters for $name; disabled by default';
  }

  @override
  String vibe_import_reencodeFailed(String name) {
    return 'Failed to re-encode Vibe: $name';
  }

  @override
  String galleryScan_failed(int count) {
    return 'Failed $count';
  }

  @override
  String get galleryScan_organizingGallery => 'Organizing gallery';

  @override
  String get galleryScan_processing => 'Processing';

  @override
  String get vibeDetail_useAll => 'Use All';

  @override
  String get vibeDetail_longPressSetCover => 'Long-press to set as cover';

  @override
  String get vibeDetail_noPreviewImage => 'No preview image';

  @override
  String get vibeDetail_dropPreviewImage =>
      'Drop an image here to set the preview';

  @override
  String get vibeDetail_releasePreviewImage =>
      'Release to set the preview image';

  @override
  String imagePicker_dropReadFailed(String error) {
    return 'Failed to read the dropped image: $error';
  }

  @override
  String get imagePicker_dropNoReadableImage =>
      'The dropped data does not contain a readable image file or image URL';

  @override
  String get imagePicker_fileDataUnavailable => 'Unable to read file data';

  @override
  String imagePicker_fileSelectionFailed(String error) {
    return 'Failed to select file: $error';
  }

  @override
  String imagePicker_directorySelectionFailed(String error) {
    return 'Failed to select directory: $error';
  }

  @override
  String get editor_effects => 'Effects';

  @override
  String get editor_shiftEdges => 'Shift Edges';

  @override
  String editor_currentSize(int width, int height) {
    return 'Current: $width x $height';
  }

  @override
  String get editor_edgeLeft => 'Left';

  @override
  String get editor_edgeRight => 'Right';

  @override
  String get editor_edgeTop => 'Top';

  @override
  String get editor_edgeBottom => 'Bottom';

  @override
  String get editor_enterNumber => 'Enter a number';

  @override
  String get editor_nonNegativeNumber => 'Must be 0 or more';

  @override
  String editor_requestedSize(int width, int height) {
    return 'Requested: $width x $height';
  }

  @override
  String get editor_requestedSizeInvalid => 'Requested: invalid';

  @override
  String editor_appliedSize(int width, int height) {
    return 'Applied: $width x $height';
  }

  @override
  String get editor_appliedSizeInvalid => 'Applied: invalid';

  @override
  String editor_appliedEdges(int left, int top, int right, int bottom) {
    return 'Applied edges: L $left, T $top, R $right, B $bottom';
  }

  @override
  String get editor_appliedEdgesInvalid => 'Applied edges: invalid';

  @override
  String editor_appliedDimensionLimit(int max) {
    return 'Applied dimensions must not exceed $max.';
  }

  @override
  String get onlineGallery_videoLoadFailed => 'Failed to load video';

  @override
  String get vibe_releaseToAddStyleReference =>
      'Release to add style reference';

  @override
  String router_pageNotFound(String error) {
    return 'Page not found: $error';
  }

  @override
  String get autocomplete_resultLimit => 'Result count';

  @override
  String get autocomplete_relatedTagsTitle => 'Tag Expansion';

  @override
  String get autocomplete_relatedTagsSubtitle =>
      'Ctrl+click to search local tags; Ctrl+drag to explore related tags';

  @override
  String get tagExpansion_searchHint => 'Search tags or aliases';

  @override
  String get tagExpansion_relatedTitle => 'Related tags';

  @override
  String get tagExpansion_empty => 'Type to search local tags';

  @override
  String get tagExpansion_noResults => 'No local tags found';

  @override
  String get tagExpansion_insert => 'Insert tag';

  @override
  String get tagExpansion_showRelated => 'Show related tags';

  @override
  String get tagExpansion_localOnly => 'Local only';

  @override
  String get tagExpansion_popularSource => 'Popular local tags';

  @override
  String get tagExpansion_tabComplete => 'Tab to complete:';

  @override
  String get tagExpansion_wikiTitle => 'Tag wiki';

  @override
  String get tagExpansion_wikiUnavailable =>
      'No local article for this tag yet.';

  @override
  String get autocomplete_cooccurrence => 'Offline related-tag database';

  @override
  String autocomplete_entryCount(int count) {
    return '$count entries';
  }

  @override
  String get autocomplete_clearDanbooruCache => 'Clear Danbooru cache';

  @override
  String get autocomplete_clearAiCache => 'Clear AI translation cache';

  @override
  String autocomplete_cacheCleared(int count) {
    return 'Cleared $count cached entries';
  }

  @override
  String get autocomplete_baseCatalog => 'Base Danbooru catalog';

  @override
  String autocomplete_catalogStatus(String count, String version) {
    return '$count tags · data version $version';
  }

  @override
  String get nav_promptBlockLibrary => 'Prompt Blocks';

  @override
  String get promptBlockLibrary_title => 'Prompt Blocks';

  @override
  String get promptBlockLibrary_folders => 'Folders';

  @override
  String get promptBlockLibrary_allBlocks => 'All blocks';

  @override
  String get promptBlockLibrary_rootFolder => 'Root / Unfiled';

  @override
  String get promptBlockLibrary_unnamedBlock => 'Untitled block';

  @override
  String get promptBlockLibrary_noBlockSelected => 'No block selected';

  @override
  String get promptBlockLibrary_details => 'Details';

  @override
  String promptBlockLibrary_useCount(int count) {
    return 'Used $count times';
  }

  @override
  String get promptBlockPill_missing => 'Block deleted';

  @override
  String get promptBlockPill_unknown => 'Invalid block';

  @override
  String get pillCardReroll => 'Re-roll';

  @override
  String get pillCardRerollLocked => 'Locked; re-roll unavailable';

  @override
  String get pillCardLock => 'Lock current roll';

  @override
  String get pillCardUnlock => 'Unlock';

  @override
  String get pillCardSettings => 'Random settings';

  @override
  String get pillCardEnable => 'Enable';

  @override
  String get pillCardDisable => 'Disable';

  @override
  String get pillCardDeleteInstance => 'Remove instance';

  @override
  String get pillCardEmptyRoll => '(empty roll this time)';

  @override
  String get pillCardEvolutionEnable => 'Enable evolution';

  @override
  String get pillCardEvolutionDisable => 'Disable evolution';

  @override
  String get pillCardEvolutionRequiresEnabled => 'Enable the instance first';

  @override
  String get pillCardStepBack => 'Step back one scene';

  @override
  String get pillCardStepForward => 'Step forward one scene';

  @override
  String get pillSettingsTitle => 'Block instance settings';

  @override
  String get pillSettingsModeFixed => 'Fixed';

  @override
  String get pillSettingsModeSequential => 'Sequential';

  @override
  String get pillSettingsModeRandom => 'Random draw';

  @override
  String get pillSettingsCount => 'Draw count';

  @override
  String get pillSettingsOrder => 'Output order';

  @override
  String get pillSettingsOrderDrawn => 'As drawn';

  @override
  String get pillSettingsOrderOriginal => 'Original order';

  @override
  String get pillSettingsWeight => 'Random weight';

  @override
  String get pillSettingsWeightMin => 'Min';

  @override
  String get pillSettingsWeightMax => 'Max';

  @override
  String get pillSettingsWeightAverage => 'Average';

  @override
  String get pillSettingsDispersion => 'Dispersion';

  @override
  String get pillSettingsDispersionFocused => 'Focused';

  @override
  String get pillSettingsDispersionBalanced => 'Balanced';

  @override
  String get pillSettingsDispersionSpread => 'Spread';

  @override
  String get pillSettingsAdvanced => 'Advanced';

  @override
  String get pillSettingsLeftDispersion => 'Left';

  @override
  String get pillSettingsRightDispersion => 'Right';

  @override
  String get pillSettingsSoftBalance => 'Soft balance';

  @override
  String get pillSettingsSoftBalanceStrength => 'Strength';

  @override
  String get pillSettingsTriggerProbability => 'Trigger chance';

  @override
  String get pillSettingsCancel => 'Cancel';

  @override
  String get pillSettingsApply => 'Apply';

  @override
  String get promptBlockLibrary_unnamedFolder => 'Untitled folder';

  @override
  String get promptBlockLibrary_scope => 'Browse';

  @override
  String get promptBlockLibrary_newBlock => 'New block';

  @override
  String get promptBlockLibrary_editBlock => 'Edit block';

  @override
  String get promptBlockLibrary_newFolder => 'New folder';

  @override
  String get promptBlockLibrary_newSubfolder => 'New subfolder';

  @override
  String get promptBlockLibrary_renameFolder => 'Rename folder';

  @override
  String get promptBlockLibrary_moveToRoot => 'Move to root';

  @override
  String get promptBlockLibrary_moveToFolder => 'Move to folder';

  @override
  String get promptBlockLibrary_favorites => 'Favorites';

  @override
  String get promptBlockLibrary_unclassified => 'Unclassified';

  @override
  String get promptBlockLibrary_newCollection => 'New collection';

  @override
  String get promptBlockLibrary_newSubcollection => 'New sub-collection';

  @override
  String get promptBlockLibrary_newCollectionFolder => 'New collection folder';

  @override
  String get promptBlockLibrary_renameCollection => 'Rename collection';

  @override
  String get promptBlockLibrary_renameCollectionFolder =>
      'Rename collection folder';

  @override
  String get promptBlockLibrary_moveToFavoritesRoot => 'Move to favorites root';

  @override
  String get promptBlockLibrary_unnamedCollection => 'Unnamed collection';

  @override
  String get promptBlockLibrary_unnamedCollectionFolder =>
      'Unnamed collection folder';

  @override
  String get promptBlockLibrary_collectionName => 'Collection name';

  @override
  String get promptBlockLibrary_collectionNameHint => 'Collection name';

  @override
  String get promptBlockLibrary_noCollections =>
      'No collections yet — use the + next to Favorites, or drag a block onto a collection';

  @override
  String get promptBlockLibrary_noFolders => 'No folders yet';

  @override
  String get promptBlockLibrary_emptyFavorites =>
      'No favorite blocks yet — tap the ★ on a block to favorite it';

  @override
  String get promptBlockLibrary_emptyCollection => 'This collection is empty';

  @override
  String promptBlockLibrary_deleteCollectionConfirm(String name) {
    return 'Delete collection \"$name\"? Blocks inside are not deleted, only unlinked from the collection.';
  }

  @override
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name) {
    return 'Delete collection folder \"$name\"? Its collections and sub-folders are deleted too; the blocks themselves are unaffected.';
  }

  @override
  String get promptBlockLibrary_blockTitle => 'Title';

  @override
  String get promptBlockLibrary_titleHint => 'Block title';

  @override
  String get promptBlockLibrary_searchHint => 'Search title, prompt, or tag';

  @override
  String get promptBlockLibrary_folder => 'Folder';

  @override
  String get promptBlockLibrary_folderName => 'Folder name';

  @override
  String get promptBlockLibrary_folderNameHint => 'Folder name';

  @override
  String get promptBlockLibrary_basicPrompt => 'Base Prompt';

  @override
  String get promptBlockLibrary_generationSettings => 'Settings';

  @override
  String get promptBlockLibrary_settingsOptionalHint =>
      'Only filled parameters are saved. Apply settings manually after inserting the block.';

  @override
  String get promptBlockLibrary_notSpecified => 'Not specified';

  @override
  String get promptBlockLibrary_stepsLabel => 'Steps';

  @override
  String get promptBlockLibrary_noiseScheduleLabel => 'Noise Schedule';

  @override
  String get promptBlockLibrary_invalidGenerationSettings =>
      'Check settings: steps 1–50, Prompt Guidance 1–20, Prompt Guidance Rescale 0–1, and model compatibility.';

  @override
  String get promptBlockLibrary_applySettings => 'Import settings';

  @override
  String get promptBlockLibrary_settingsApplied =>
      'Block settings imported to the current image';

  @override
  String get promptBlockLibrary_settingsIncompatible =>
      'Block settings are incompatible with the target model. No parameters were imported.';

  @override
  String get promptBlockLibrary_noSettings => 'No generation settings saved';

  @override
  String get promptBlockLibrary_tags => 'Tags';

  @override
  String get promptBlockLibrary_addTag => 'Add tag';

  @override
  String get promptBlockLibrary_tagName => 'Tag name';

  @override
  String get promptBlockLibrary_tagColor => 'Tag color (hex)';

  @override
  String get promptBlockLibrary_duplicateTag =>
      'This block already has a tag with that name';

  @override
  String get promptBlockLibrary_invalidTagColor => 'Enter a valid hex color';

  @override
  String get pillCard_rollScope => 'Variation scope';

  @override
  String get pillCard_positiveScope => 'Positive';

  @override
  String get pillCard_negativeScope => 'Negative';

  @override
  String get promptBlockLibrary_modelResetNotice =>
      'Unsupported values were cleared after changing the model.';

  @override
  String get promptBlockLibrary_atomInputHint =>
      'Type text, press Enter to make an atom';

  @override
  String get promptBlockLibrary_atomRestoreHint =>
      'Click to restore as editable text';

  @override
  String get promptBlockLibrary_atomOrphan => 'Unknown marker';

  @override
  String get promptBlockLibrary_atomEditorTutorial =>
      'Enter makes a block, click a block to restore text; unblocked text becomes atoms on save.';

  @override
  String get promptBlockLibrary_color => 'Color';

  @override
  String get promptBlockLibrary_icon => 'Icon';

  @override
  String get promptBlockLibrary_saved => 'Saved';

  @override
  String get promptBlockLibrary_copied => 'Content copied';

  @override
  String get promptBlockLibrary_deleted => 'Deleted';

  @override
  String get promptBlockLibrary_multiSelect => 'Multi-select';

  @override
  String get promptBlockLibrary_exitMultiSelect => 'Exit multi-select';

  @override
  String promptBlockLibrary_selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get promptBlockLibrary_selectAllVisible => 'Select all';

  @override
  String get promptBlockLibrary_clearSelection => 'Clear selection';

  @override
  String get promptBlockLibrary_moveTo => 'Move to…';

  @override
  String get promptBlockLibrary_moveToFolderTitle => 'Move to folder';

  @override
  String promptBlockLibrary_deleteBlocksConfirm(int count) {
    return 'Delete $count selected blocks? This cannot be undone.';
  }

  @override
  String promptBlockLibrary_deleteSelected(int count) {
    return 'Delete $count selected blocks';
  }

  @override
  String get promptBlockLibrary_empty => 'No prompt blocks yet';

  @override
  String get promptBlockLibrary_emptyFolder => 'This folder is empty';

  @override
  String get promptBlockLibrary_noSearchResults => 'No matching blocks';

  @override
  String get promptBlockLibrary_tryDifferentSearch => 'Try a different search';

  @override
  String get promptBlockLibrary_emptyHint =>
      'Create a block to start organizing reusable text';

  @override
  String promptBlockLibrary_loadFailed(String error) {
    return 'Failed to load prompt blocks: $error';
  }

  @override
  String promptBlockLibrary_deleteFolderTitle(Object name) {
    return 'Delete folder \"$name\"?';
  }

  @override
  String get promptBlockLibrary_deleteFolderDescription =>
      'Choose what to do with blocks inside this folder and its subfolders.';

  @override
  String get promptBlockLibrary_moveContentsToRoot => 'Move contents to root';

  @override
  String get promptBlockLibrary_moveContentsToFolder =>
      'Move contents to another folder';

  @override
  String get promptBlockLibrary_destinationFolder => 'Destination folder';

  @override
  String get promptBlockLibrary_deleteContents => 'Delete contents';

  @override
  String get promptBlockLibrary_deleteContentsWarning =>
      'This also permanently deletes all blocks in the folder tree.';

  @override
  String get promptBlockLibrary_importExport => 'Import / Export';

  @override
  String get promptBlockLibrary_importTxtFiles => 'Import TXT files';

  @override
  String get promptBlockLibrary_importFromFolder => 'Import from folder…';

  @override
  String get promptBlockLibrary_exportLibraryBackup => 'Export library backup…';

  @override
  String get promptBlockLibrary_importLibraryBackup => 'Import library backup…';

  @override
  String get promptBlockLibrary_importTxtTitle => 'Select TXT files';

  @override
  String promptBlockLibrary_txtImportDone(int created, int skipped) {
    return 'Imported $created blocks, skipped $skipped existing sources';
  }

  @override
  String get promptBlockLibrary_curationTitle => 'Import from folder';

  @override
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  ) {
    return '$total TXT files: $created new · $skipped unchanged · $changed changed';
  }

  @override
  String promptBlockLibrary_curationLocalModifiedHint(int count) {
    return '$count blocks were manually edited after import; updating overwrites local edits';
  }

  @override
  String get promptBlockLibrary_curationUpdateChanged =>
      'Update changed blocks with file content';

  @override
  String get promptBlockLibrary_curationEmpty =>
      'No TXT files in the selected folder';

  @override
  String promptBlockLibrary_curationDone(
    int created,
    int updated,
    int skipped,
  ) {
    return 'Done: $created created · $updated updated · $skipped skipped';
  }

  @override
  String get promptBlockLibrary_curationNew => 'New';

  @override
  String get promptBlockLibrary_curationUnchanged => 'Unchanged';

  @override
  String get promptBlockLibrary_curationChanged => 'Changed';

  @override
  String get promptBlockLibrary_curationLocalModified => 'Locally modified';

  @override
  String promptBlockLibrary_libraryBackupDone(int count) {
    return 'Exported backup with $count blocks';
  }

  @override
  String get promptBlockLibrary_libraryImportTitle => 'Select library backup';

  @override
  String get promptBlockLibrary_libraryBackupInvalid =>
      'Not a valid block library backup';

  @override
  String promptBlockLibrary_libraryImportDone(
    int blocks,
    int folders,
    int skipped,
  ) {
    return 'Imported $blocks blocks and $folders folders, skipped $skipped existing';
  }

  @override
  String promptBlockLibrary_importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get promptBlockLibrary_sourceFile => 'Source file';

  @override
  String get promptBlockLibrary_importedAt => 'Imported at';

  @override
  String get promptBlockLibrary_listView => 'List view';

  @override
  String get promptBlockLibrary_gridView => 'Grid view';

  @override
  String get promptBlockLibrary_waterfallView => 'Waterfall view';

  @override
  String get promptBlockPalette_tooltip => 'Blocks';

  @override
  String get promptBlockPalette_emptyHint =>
      'Keep prompt blocks or translation blocks here; click to insert at the caret, or drag them into the prompt box.';

  @override
  String get promptBlockPalette_remove => 'Remove from blocks';

  @override
  String get promptBlockPalette_clearAll => 'Clear blocks';

  @override
  String get promptBlockPalette_clearAllArmed => 'Tap again to clear all';

  @override
  String promptBlockPalette_removeSelected(int count) {
    return 'Remove $count selected';
  }

  @override
  String get promptBlockLibrary_sortBy => 'Sort by';

  @override
  String get promptBlockLibrary_sortCustom => 'Default (manual order)';

  @override
  String get promptBlockLibrary_sortUpdated => 'Last modified';

  @override
  String get promptBlockLibrary_sortTitle => 'Title';

  @override
  String get promptBlockLibrary_sortColor => 'Color';

  @override
  String get promptBlockLibrary_sortIcon => 'Icon';

  @override
  String get promptBlockLibrary_sortAscending => 'Ascending';

  @override
  String get promptBlockLibrary_sortDescending => 'Descending';

  @override
  String get promptBlockLibrary_cardSize => 'Card size';

  @override
  String get promptBlockLibrary_reorderFolders => 'Reorder folders';

  @override
  String get nav_styleExplore => 'Style Explore';

  @override
  String get styleExplore_rename => 'Rename';

  @override
  String get styleExplore_nameRequired => 'Name cannot be empty';

  @override
  String get styleExplore_operationFailed => 'Operation failed';

  @override
  String get styleExplore_discardChangesTitle => 'Discard unsaved changes?';

  @override
  String get styleExplore_discardChangesMessage =>
      'The workspace has unsaved changes. Continuing will discard them.';

  @override
  String get styleExplore_discardChangesConfirm => 'Continue and discard';

  @override
  String get styleExplore_previewEmpty => '(empty)';

  @override
  String get styleExplore_copiedToClipboard => 'Copied';

  @override
  String get styleExplore_runSectionTitle => 'Explore runs';

  @override
  String get styleExplore_runEmptyHint =>
      'An explore run captures prompt and parameter snapshots, generates candidates in batch, then reviews them.';

  @override
  String get styleExplore_newRun => 'New run';

  @override
  String get styleExplore_galleryTitle => 'Candidate gallery';

  @override
  String get styleExplore_galleryEmptyHint =>
      'No candidates yet. Create or select an explore run to start batch generation.';

  @override
  String get styleExplore_runNameLabel => 'Run name';

  @override
  String get styleExplore_runNameHint => 'e.g. Soft light ×30';

  @override
  String styleExplore_runCreated(String name) {
    return 'Created \"$name\"';
  }

  @override
  String styleExplore_runDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String styleExplore_runTotalCount(int total) {
    return 'Total $total images';
  }

  @override
  String styleExplore_runGeneratingProgress(int current, int total) {
    return 'Image $current/$total';
  }

  @override
  String get styleExplore_runStatusDraft => 'Draft';

  @override
  String get styleExplore_runStatusGenerating => 'Generating';

  @override
  String get styleExplore_runStatusPaused => 'Paused';

  @override
  String get styleExplore_runStatusGenerated => 'Generated';

  @override
  String get styleExplore_runStatusCompleted => 'Completed';

  @override
  String get styleExplore_runStatusCancelled => 'Cancelled';

  @override
  String get styleExplore_pauseRun => 'Pause';

  @override
  String get styleExplore_cancelRun => 'Cancel run';

  @override
  String styleExplore_retryFailed(int count) {
    return 'Retry failed ($count)';
  }

  @override
  String get styleExplore_targetCountLabel => 'Images';

  @override
  String styleExplore_manualRunName(String time) {
    return 'Manual capture $time';
  }

  @override
  String get styleExplore_runBusy => 'Generation busy, try again later';

  @override
  String get styleExplore_deleteRunTitle => 'Delete explore run';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return 'Deletes \"$name\" and its candidate image copies; source images in the gallery are not affected.';
  }

  @override
  String get styleExplore_cancelRunTitle => 'Cancel explore run';

  @override
  String get styleExplore_cancelRunMessage =>
      'A cancelled run cannot be restarted; remaining pending candidates will be marked as cancelled.';

  @override
  String get styleExplore_filterAll => 'All';

  @override
  String get styleExplore_filterHearted => 'Favorites';

  @override
  String get styleExplore_newFolder => 'New folder';

  @override
  String get styleExplore_renameFolder => 'Rename folder';

  @override
  String get styleExplore_deleteFolder => 'Delete folder';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return 'Deletes the folder \"$name\". Its candidates go back to Uncategorized; images are kept.';
  }

  @override
  String get styleExplore_folderNameLabel => 'Folder name';

  @override
  String get styleExplore_deleteFamily => 'Delete lineage';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return 'Deletes the lineage \"$name\" with all its parent sets and candidate records ($count images). Image files are kept.';
  }

  @override
  String get styleExplore_familyBusy =>
      'This lineage still has candidates being generated. Cancel the task first';

  @override
  String get styleExplore_folderUncategorized => 'Uncategorized';

  @override
  String styleExplore_folderCreated(String name) {
    return 'Folder \"$name\" created';
  }

  @override
  String get styleExplore_assignToFolder => 'Move to';

  @override
  String get styleExplore_candidateMissing => 'Image file missing';

  @override
  String get styleExplore_candidateDetailTitle => 'Candidate detail';

  @override
  String styleExplore_candidatePosition(int current, int total) {
    return 'Image $current/$total';
  }

  @override
  String get styleExplore_prevCandidate => 'Previous';

  @override
  String get styleExplore_nextCandidate => 'Next';

  @override
  String get styleExplore_rollSnapshot => 'Roll snapshot';

  @override
  String styleExplore_seedLabel(String seed) {
    return 'Seed $seed';
  }

  @override
  String styleExplore_roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String get styleExplore_adoptAsBlock => 'Adopt as block';

  @override
  String get styleExplore_adoptBlockNameLabel => 'Block name';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return 'Adopted as block \"$name\"';
  }

  @override
  String get styleExplore_adoptBlockEmpty =>
      'Selected candidates have no roll text';

  @override
  String get styleExplore_fixateAsTemplate => 'Import metadata';

  @override
  String get styleExplore_fixateDone => 'Metadata imported to editor';

  @override
  String get styleExplore_deleteImage => 'Delete image';

  @override
  String get styleExplore_deleteImageTitle => 'Delete candidate image';

  @override
  String get styleExplore_deleteImageMessage =>
      'Deletes this candidate\'s image copy in the run directory and removes its record. The gallery source image is untouched.';

  @override
  String get styleExplore_deleteImageDone =>
      'Candidate image and record deleted';

  @override
  String get styleExplore_selectCandidates => 'Select';

  @override
  String styleExplore_selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get styleExplore_mergeAdopt => 'Merge & adopt';

  @override
  String get styleExplore_noRunsYet => 'No explore runs yet';

  @override
  String get promptBlockEditor_library => 'Block library';

  @override
  String get promptBlockPicker_title => 'Select Block';

  @override
  String get promptBlockLibrary_thumbnail => 'Thumbnail';

  @override
  String get promptBlockLibrary_selectNewImage => 'Select New Image';

  @override
  String get promptBlockLibrary_selectImage => 'Select Image';

  @override
  String get promptBlockLibrary_adjustDisplayRange => 'Adjust Display Range';

  @override
  String get promptBlockLibrary_adjustThumbnailTitle =>
      'Adjust Thumbnail Display Range';

  @override
  String get promptBlockLibrary_dragToMove =>
      'Drag to move, scroll or pinch to zoom';

  @override
  String get promptBlockLibrary_addToLibrary => 'Add to Block Library';

  @override
  String get promptBlockLibrary_contentPreview => 'Content Preview';

  @override
  String get promptBlockLibrary_confirmAdd => 'Confirm';

  @override
  String get promptBlockLibrary_saveToLibrary => 'Save to Block Library';

  @override
  String get promptBlockLibrary_droppedImage => 'Dropped Image';

  @override
  String get promptBlockLibrary_createBlockFromImage => 'Create New Block';

  @override
  String get promptBlockLibrary_createBlockFromImageSubtitle =>
      'Create a new block from this image';

  @override
  String promptBlockLibrary_promptExtracted(Object prompt) {
    return 'Prompt extracted: \"$prompt\"';
  }

  @override
  String get promptBlockLibrary_updateExistingThumbnail =>
      'Update Existing Block Thumbnail';

  @override
  String get promptBlockLibrary_updateExistingThumbnailSubtitle =>
      'Select a block and replace its thumbnail';

  @override
  String get styleExplore_lineageTitle => 'Lineage';

  @override
  String get styleExplore_createFamily => 'Create family';

  @override
  String styleExplore_familyCreated(String name) {
    return 'Family \"$name\" created';
  }

  @override
  String get styleExplore_familyNameLabel => 'Family name';

  @override
  String get styleExplore_familyNameHint => 'e.g. Soft light main line';

  @override
  String styleExplore_familyParentsTitle(int count) {
    return 'Parents ($count)';
  }

  @override
  String get styleExplore_customParentLabel => 'Custom parent string';

  @override
  String get styleExplore_customParentHint =>
      'Enter a prompt string as a parent';

  @override
  String get styleExplore_addCustomParent => 'Add custom string';

  @override
  String get styleExplore_createFamilyEmpty =>
      'Keep at least one valid parent string';

  @override
  String styleExplore_parentSetTitle(int generation) {
    return 'Gen $generation parent set';
  }

  @override
  String styleExplore_candidatePileTitle(int generation, int count) {
    return 'Gen $generation pile · $count';
  }

  @override
  String get styleExplore_parentSetActive => 'Active';

  @override
  String get styleExplore_parentSetUsed => 'Backcrossed';

  @override
  String styleExplore_branchLabel(String name) {
    return 'Branch: $name';
  }

  @override
  String get styleExplore_createDeepRound => 'Generate candidates';

  @override
  String styleExplore_deepRoundCountHint(int min) {
    return 'Count must be at least $min (one per parent)';
  }

  @override
  String get styleExplore_deepRoundNoInstance =>
      'No enabled random evolution block in the main prompt; deep round unavailable';

  @override
  String get styleExplore_deepRoundEmpty =>
      'Mutation engine could not produce enough distinct children';

  @override
  String get styleExplore_sortParents => 'A/B comparison';

  @override
  String get styleExplore_sortTitle => 'Parent A/B comparison';

  @override
  String get styleExplore_sortPrompt =>
      'Which image is closer to the style you want?';

  @override
  String get styleExplore_sortLeft => 'Left is better';

  @override
  String get styleExplore_sortRight => 'Right is better';

  @override
  String get styleExplore_sortNeither => 'Neither';

  @override
  String get styleExplore_sortSkip => 'Skip';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return 'Pair $current/$total';
  }

  @override
  String get styleExplore_sortDone => 'Ranking finished';

  @override
  String get styleExplore_branchSelect => 'Select for branch';

  @override
  String get styleExplore_createBranch => 'Create branch';

  @override
  String get styleExplore_branchNameLabel => 'Branch name (optional)';

  @override
  String styleExplore_branchCreated(int count) {
    return 'Branch created ($count parents)';
  }

  @override
  String get styleExplore_branchNeedLatest =>
      'Branches can only be created from the latest generation pile';

  @override
  String get styleExplore_branchRoundsIncomplete =>
      'The current generation still has unfinished rounds';

  @override
  String get styleExplore_branchDuplicate =>
      'A selected child duplicates a first-generation parent string';

  @override
  String get styleExplore_branchEmpty => 'Select at least one child candidate';

  @override
  String styleExplore_preferenceValue(String value) {
    return 'Pref $value';
  }

  @override
  String styleExplore_roundsSummary(int count) {
    return '$count rounds';
  }

  @override
  String get styleExplore_pileEmpty =>
      'No candidates yet — start with \"Generate candidates\" above';

  @override
  String get styleExplore_managePile => 'Manage';

  @override
  String get styleExplore_pileManageDeleteTitle =>
      'Delete selected candidate images';

  @override
  String styleExplore_pileManageDeleteMessage(int count) {
    return 'Deletes the run-directory image copies and records of $count candidates; gallery source images are not affected.';
  }

  @override
  String styleExplore_pileManageDeleteDone(int count) {
    return 'Deleted $count candidates and their image copies';
  }

  @override
  String subscriptionExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get subscriptionExpired => 'Expired';

  @override
  String get subscriptionGracePeriod => 'Grace period';

  @override
  String get subscriptionTierNone => 'No subscription';

  @override
  String get settings_modelsAndInterfaces => 'Models & APIs';

  @override
  String get tips_kind_guide => 'Tip';

  @override
  String get tips_kind_trick => 'Pro tip';

  @override
  String get tips_kind_wolf => 'Wolf';

  @override
  String tips_hint(String label, String tip) {
    return '$label: $tip';
  }

  @override
  String get tips_studio_guide_1 =>
      'Press Ctrl+Enter to generate once your prompt is ready. Results spread across this canvas batch by batch: middle-drag or Shift+left-drag to pan, Ctrl+scroll to zoom, and WASD to move around.';

  @override
  String get tips_studio_guide_2 =>
      'Write your go-to artist strings, quality tags and composition notes once, save them as blocks, and pull them from the block library next time. Blocks are more than copy-paste: set them to Fixed, Sequential or Random draw and every generation gets a new combination.';

  @override
  String get tips_studio_guide_3 =>
      'Got a random roll you love? Lock it, then re-roll the other blocks. Locked blocks stay put while the rest keeps shuffling — perfect for \"keep this pose, try a few more outfits.\"';

  @override
  String get tips_studio_guide_4 =>
      'Drag an image into the window and you\'ll be asked how to use it: Image2Image, Vibe Transfer, Precise Reference, or just extracting its prompt and settings. If it carries NovelAI metadata, one drag shows exactly how it was made.';

  @override
  String get tips_studio_guide_5 =>
      'A character box is really a placement box. Besides people, you can put a cat, a lamp or a shop sign in one. Switch Position to Custom and drag its anchor on the preview to tell the model where it belongs.';

  @override
  String get tips_studio_guide_6 =>
      'Select part of a prompt and hold Alt while scrolling to adjust its weight. Without Alt the wheel just scrolls, so weights never change by accident. You can switch the modifier to Ctrl in Settings.';

  @override
  String get tips_studio_guide_7 =>
      'Press F1 any time for the shortcut list. Ctrl+1, Ctrl+2 and Ctrl+3 jump between Generate, Gallery and Online Gallery, and Ctrl+, opens Settings. Every shortcut can be remapped in Settings.';

  @override
  String get tips_studio_guide_8 =>
      'Worried about burning a pile of Anlas by accident? Turn on the High Anlas cost warning in Settings, and any generation estimated above your threshold will ask before it runs.';

  @override
  String get tips_studio_trick_1 =>
      'The seed decides which image you pull. Same settings plus the same seed means the same picture. Want to recreate a masterpiece? Keep the seed. Want new luck? Stop staring at that seed.';

  @override
  String get tips_studio_trick_2 =>
      'Reusing a pre-encoded Vibe skips the 2 Anlas encoding fee. Two Anlas doesn\'t sound like much — until you count how many Vibes you use in a day.';

  @override
  String get tips_studio_trick_3 =>
      'Undesired Content isn\'t a wishing well. Writing \"bad hands\" a hundred times does less than describing the hands clearly in the prompt. Leave the usual boilerplate to the Undesired Content preset.';

  @override
  String get tips_studio_trick_4 =>
      'Longer artist strings aren\'t always better. Past ten names, the model probably can\'t tell whose brushwork you actually want. Split them into a few blocks and let random draws rotate them in.';

  @override
  String get tips_studio_trick_5 =>
      'Requests per click and images per request are two different numbers. The button shows the total, and Anlas is charged on the total too. Check before you click. Don\'t ask how I know.';

  @override
  String get tips_studio_trick_6 =>
      'Middle-click a translation block to flip between the original and the translation. However good the AI is, peek at the original now and then to make sure \"cat ears\" didn\'t become something strange.';

  @override
  String get tips_studio_trick_7 =>
      'Limit generation frequency in Settings forces a cooldown between runs, and a little random jitter keeps the rhythm from feeling mechanical. Good for slow late-night sessions — and for anyone whose finger won\'t leave the button.';

  @override
  String get tips_studio_wolf_1 =>
      'Welcome to the den. I carry the images you make back here and stack them neatly in the gallery. Honestly, I\'m far better at tidying than at drawing.';

  @override
  String get tips_studio_wolf_2 =>
      'Wolves see best at night. So if you\'re still here at 3 a.m., I won\'t say a word. I\'ll just keep you company for one more pull.';

  @override
  String get tips_studio_wolf_3 =>
      'They say an AI artist comes of age the first time they count the fingers on one hand without panicking. I don\'t have fingers, so I\'ve always been calm.';

  @override
  String get tips_studio_wolf_4 =>
      'Pack rules: share good seeds, save good prompts as blocks, and save good images before you admire them. The last one matters most. Don\'t ask why.';

  @override
  String get tips_studio_wolf_5 =>
      'I can\'t draw, but I\'m very good at waiting. Those few seconds when the live preview slowly sharpens are the quietest part of my day.';

  @override
  String get tips_studio_wolf_6 =>
      'W.O.F stands for WolF. As for the dots in between? Those are my paw prints in the snow.';

  @override
  String get tips_studio_wolf_7 =>
      'When the canvas is empty, I curl up here for a nap. Hit Generate and I\'m awake.';

  @override
  String get tips_studio_night_1 =>
      'It\'s the middle of the night. Friendly reminder: your taste runs about 30% bolder at this hour. Take another look in the morning.';

  @override
  String get tips_studio_night_2 =>
      'It\'s late, and somewhere in a server room a GPU just yawned. Finish this batch and get some sleep. I\'ll guard the gallery.';

  @override
  String get tips_lab_guide_1 =>
      'Style Explore is an audition. Start an explore run to lock in the prompt and settings, then generate a batch of candidates. The children you pick become the next generation\'s parents, and the style moves toward what you want one generation at a time.';

  @override
  String get tips_lab_guide_2 =>
      'Hearts and folders are for your own organizing; they don\'t affect inheritance. What decides the next generation is the set you pick with \"Select for branch.\"';

  @override
  String get tips_lab_guide_3 =>
      'Cannot decide? Use the A/B comparison: two parent images appear side by side and you only answer which is closer to the style you want. Parents ranked higher are more likely to get children next round.';

  @override
  String get tips_lab_guide_4 =>
      'To generate the next round, the main prompt needs at least one random block with evolution enabled. No variable genes, nothing for the mutation engine to work with.';

  @override
  String get tips_lab_guide_5 =>
      'Found a candidate with a great combination? Adopt as block saves it to the block library so you can use it on the Generate page too. Select several and Merge & adopt combines them into one block.';

  @override
  String get tips_lab_guide_6 =>
      'Deleting an explore run only removes the candidate copies in its run folder; originals in the gallery stay untouched. Clean up freely — a lab is supposed to be a bit messy.';

  @override
  String get tips_lab_trick_1 =>
      'Every parent is guaranteed at least one child per round, so more parents means more images per round. Get greedy and your Anlas will call time for you.';

  @override
  String get tips_lab_trick_2 =>
      'You can only branch from the latest generation\'s pile. You can look back, but you can\'t fork from halfway. Evolution is ruthless like that.';

  @override
  String get tips_lab_trick_3 =>
      'Sometimes the mutation engine says it can\'t produce enough distinct children. It isn\'t slacking — the gene pool is just too small. Add a few more options to the random block and it gets right back to work.';

  @override
  String get tips_lab_trick_4 =>
      'Hover a thumbnail in the candidate pile to see it large. No need to open them one by one; a judge has to be efficient.';

  @override
  String get tips_lab_trick_5 =>
      'Like a candidate\'s whole setup? Import metadata moves its prompt and settings straight back into the editor so you can keep tweaking from there.';

  @override
  String get tips_lab_wolf_1 =>
      'No wolf is born the strongest in the pack. Styles are the same: a rough first generation is normal. Judge it at the third.';

  @override
  String get tips_lab_wolf_2 =>
      'Survival of the fittest has a gentle version here: candidates you don\'t pick don\'t disappear. It just wasn\'t their turn this round.';

  @override
  String get tips_lab_wolf_3 =>
      'My entire understanding of genetics: good-looking parents usually have good-looking pups. The rest is mutation and a little luck.';

  @override
  String get tips_lab_wolf_4 =>
      'The lights in the LAB usually stay on late. I\'m on duty at the door, keeping count of which generation we\'re on.';

  @override
  String get tips_lab_wolf_5 =>
      'Never underestimate mutation. Sometimes the thing you couldn\'t find in ten generations shows up by accident. So don\'t rush to delete the one that looks off.';

  @override
  String get tips_prompt_guide_1 =>
      'Ctrl+Enter generates; Esc cancels a run in progress.';

  @override
  String get tips_prompt_guide_2 =>
      'Select some text and hold Alt while scrolling to change its weight. Without Alt, the wheel just scrolls.';

  @override
  String get tips_prompt_guide_3 =>
      'Ctrl+click a tag to look it up in the local tag library; Ctrl+drag across a phrase to see tags that often appear with it.';

  @override
  String get tips_prompt_guide_4 =>
      'Right-click selected text to save it straight to the block library. Next time, one click or drag brings it back.';

  @override
  String get tips_prompt_guide_5 =>
      'The quality tag preset at the bottom of this box adds the usual quality tags for you; switch to Undesired Content and the same spot holds its preset.';

  @override
  String get tips_prompt_guide_6 => 'Press F1 to see every shortcut.';

  @override
  String get tips_prompt_guide_7 =>
      'Paste a multi-character prompt copied from ComfyUI and it\'s recognized, with an offer to import it as character boxes — no retyping one by one.';

  @override
  String get tips_prompt_guide_8 =>
      'With SD Syntax Auto Convert on, weights like (tag:1.2) are converted to the NovelAI format when you leave the box or generate.';

  @override
  String get tips_prompt_guide_9 =>
      '1.2::tag:: sets an exact weight; a negative number pushes the other way.';

  @override
  String get tips_prompt_trick_1 =>
      'Each layer of curly braces multiplies the weight by 1.05; each layer of square brackets divides it by 1.05. Anyone wrapping five layers of braces is usually arguing with the model.';

  @override
  String get tips_prompt_trick_2 =>
      'Auto Format strips useless 1.0 weights. It isn\'t judging you; it\'s saving tokens.';

  @override
  String get tips_prompt_trick_3 =>
      'The thin bar at the bottom shows token usage. Once it\'s full, the model barely sees anything past it. If you\'re writing a novel, this isn\'t the place.';

  @override
  String get tips_prompt_trick_4 =>
      'Stuck? Start with the biggest thing in the picture.';

  @override
  String get tips_prompt_trick_5 =>
      'One set of quality tags is enough. Typing masterpiece three times doesn\'t make you look more sincere to the model.';

  @override
  String get tips_prompt_trick_6 =>
      'Want something present but not stealing the show? 0.8:: works better than deleting it. Deleting means gone; lowering the weight means low-key.';

  @override
  String get tips_prompt_trick_7 =>
      'Swapping the same few words over and over? Make a block and let random draws do it.';

  @override
  String get tips_prompt_trick_8 =>
      'Put what you want in the prompt and what you don\'t want in Undesired Content. Write \"no hat\" in the prompt and the model mostly just hears \"hat.\"';

  @override
  String get tips_prompt_wolf_1 =>
      'This box has seen thousands of masterpieces, and a few things best left unshared.';

  @override
  String get tips_prompt_wolf_2 =>
      'Describe the picture in one plain sentence first, then break it into tags. Do it the other way around and you often get a pile of tags and a picture nobody understands.';

  @override
  String get tips_prompt_wolf_3 =>
      'I\'m watching you type. Relax, I can\'t read.';

  @override
  String get tips_prompt_wolf_4 =>
      'Somewhere far away, a GPU just sighed at your prompt.';

  @override
  String get tips_prompt_wolf_5 =>
      'Gacha ends in superstition. Superstition ends in a fixed seed.';

  @override
  String get tips_prompt_wolf_6 =>
      'By the twelfth artist tag, the model no longer knows whose style it\'s drawing. Neither do you.';

  @override
  String get tips_explore_guide_1 =>
      'This is the parent prompt. To let part of it evolve, turn that part into a random block and enable evolution on the block.';

  @override
  String get tips_explore_guide_2 =>
      'Evolution can only be enabled once the block instance is enabled. If it\'s greyed out, enable the block first.';

  @override
  String get tips_explore_guide_3 =>
      'The number next to Generate candidates sets how many images this round makes.';

  @override
  String get tips_explore_guide_4 =>
      'Block instances can step back and forward one scene at a time through the combinations they have already rolled.';

  @override
  String get tips_explore_guide_5 =>
      'An explore run keeps a snapshot of the prompt and settings. Editing here afterwards won\'t change rounds that already finished.';

  @override
  String get tips_explore_guide_6 =>
      'A block\'s random settings control draw count, trigger chance and random weight — that\'s where all the genetic variety lives.';

  @override
  String get tips_explore_trick_1 =>
      'The bigger the gene pool, the more mutation has to work with. Put only two words in a random block and ten generations will just bounce between two answers.';

  @override
  String get tips_explore_trick_2 =>
      'Hard-code what you\'re sure about and make the uncertain parts random. All random means no direction; all fixed means no evolution.';

  @override
  String get tips_explore_trick_3 =>
      'Locked blocks don\'t get re-rolled. To keep a trait, lock it first and let the other blocks do the experimenting.';

  @override
  String get tips_explore_trick_4 =>
      'Set a trigger chance of 30% and the block shows up in roughly three out of ten combinations — great for touches that only look good once in a while.';

  @override
  String get tips_explore_trick_5 =>
      'Expecting perfection in the first generation? That\'s called wishing, not exploring.';

  @override
  String get tips_explore_wolf_1 =>
      'A pack\'s bloodline is chosen one generation at a time. So is your style.';

  @override
  String get tips_explore_wolf_2 =>
      'Every round is an open audition with exactly one judge: you. I\'m in charge of applause.';

  @override
  String get tips_explore_wolf_3 =>
      'Good genes come from good parents. Good parents come from that one click where your hand didn\'t slip.';

  @override
  String get tips_explore_wolf_4 =>
      'I don\'t know much genetics, but I know this: picky judges raise the best-looking pups.';

  @override
  String get tips_character_guide_1 =>
      'A character box is really a placement box: cats, lamps, signs — it doesn\'t have to be a person.';

  @override
  String get tips_character_guide_2 =>
      'Switch Position above to Custom, then drag the anchor on the preview. It applies when you let go.';

  @override
  String get tips_character_guide_3 =>
      'AI\'s Choice lets the model handle placement. Switch back to Custom and your earlier positions are still there.';

  @override
  String get tips_character_guide_4 =>
      'Every character box has its own Undesired Content tab that only applies to that character.';

  @override
  String get tips_character_guide_5 =>
      'The check mark at the top right disables this character for now — no need to delete and retype.';

  @override
  String get tips_character_guide_6 =>
      'Click the title to rename this character. Much easier to tell apart than numbers.';

  @override
  String get tips_character_guide_7 =>
      'Use the ⋯ menu at the top right to add this character to the block library and reuse its description later.';

  @override
  String get tips_character_trick_1 =>
      'Keep scene and style in the main prompt and only this character here. Write an outfit twice and the model assumes you love it.';

  @override
  String get tips_character_trick_2 =>
      'Two people placed too close tend to merge. Pulling their anchors apart works better than writing \"separate\" ten times.';

  @override
  String get tips_character_trick_3 =>
      'Want a tree on the left? Give it a character box and drag it there. The tree won\'t complain about not being a character.';

  @override
  String get tips_character_trick_4 =>
      'Blocks and weight syntax work in character boxes too, just like the main prompt.';

  @override
  String get tips_character_trick_5 =>
      'Too many characters? Disable a few. In a crowded frame the model picks who stays — usually not the one you wanted.';

  @override
  String get tips_character_wolf_1 =>
      'I\'d like a character box too, but I think I\'m better off watching from outside the frame.';

  @override
  String get tips_character_wolf_2 =>
      'One box, one place, one job. Sounds like a good philosophy for life.';

  @override
  String get tips_character_wolf_3 =>
      'You handle the blocking; I\'ll stand on the side yelling \"a little more to the left.\"';

  @override
  String get tips_character_wolf_4 =>
      'Even a wolf pack moves in formation. With lots of characters, decide who stands in the middle first.';

  @override
  String get tips_gallery_guide_1 => 'Search filenames or prompt text';

  @override
  String get tips_gallery_guide_2 => 'Commas mean all terms must match';

  @override
  String get tips_gallery_guide_3 => 'Model, sampler and source match too';

  @override
  String get tips_gallery_guide_4 => 'Ctrl+F jumps here any time';

  @override
  String get tips_gallery_guide_5 => 'Character prompts count too';

  @override
  String get tips_gallery_guide_6 => 'Right-click an image for more';

  @override
  String get tips_gallery_guide_7 => 'F5 refreshes the gallery';

  @override
  String get tips_gallery_trick_1 => 'Negatives never match';

  @override
  String get tips_gallery_trick_2 => 'Search first. It\'s probably here';

  @override
  String get tips_gallery_trick_3 => 'Your prompts are the best keywords';

  @override
  String get tips_gallery_trick_4 => 'Trash empties at next launch';

  @override
  String get tips_gallery_trick_5 => 'masterpiece matches everything';

  @override
  String get tips_gallery_wolf_1 => 'Tonight\'s prey is on page three';

  @override
  String get tips_gallery_wolf_2 => 'I smell a masterpiece in here';

  @override
  String get tips_gallery_wolf_3 => 'Scrolling is cardio. I\'ll run too';

  @override
  String get tips_gallery_wolf_4 => 'Big den. Take your time';

  @override
  String get tips_online_guide_1 => 'Space between tags, then Enter';

  @override
  String get tips_online_guide_2 => 'Fuzzy Match: *tag* finds similar tags';

  @override
  String get tips_online_guide_3 => 'Blacklisted tags stay hidden';

  @override
  String get tips_online_guide_4 => 'Sign in to Danbooru for favorites';

  @override
  String get tips_online_trick_1 => 'Multi-word tags: blue_eyes';

  @override
  String get tips_online_trick_2 => 'Great post? Borrow its tags';

  @override
  String get tips_online_trick_3 => 'More tags, fewer results';

  @override
  String get tips_online_wolf_1 => 'Big world out there. I\'ll scout';

  @override
  String get tips_online_wolf_2 => 'Other packs\' turf. Just looking';

  @override
  String get tips_online_wolf_3 => 'Which forest are we hunting in?';

  @override
  String get tips_blocks_guide_1 => 'Search titles, prompts or tags';

  @override
  String get tips_blocks_guide_2 => 'Drag a block into the prompt';

  @override
  String get tips_blocks_guide_3 => 'Star the ones you use most';

  @override
  String get tips_blocks_guide_4 => 'Thumbnails make picking faster';

  @override
  String get tips_blocks_guide_5 => 'Right-click text to save a block';

  @override
  String get tips_blocks_trick_1 => 'Typed it thrice? Make it a block';

  @override
  String get tips_blocks_trick_2 => 'Unsure? Save it. Deleting is fast';

  @override
  String get tips_blocks_trick_3 => 'Future you loves clear names';

  @override
  String get tips_blocks_trick_4 => 'More options, more surprises';

  @override
  String get tips_blocks_wolf_1 => 'Every block wants to be picked';

  @override
  String get tips_blocks_wolf_2 => 'These blocks are your pack';

  @override
  String get tips_blocks_wolf_3 => 'The only block I know is meat';

  @override
  String get tips_blocks_wolf_4 => 'Folders in folders. So organized';

  @override
  String get tips_generating_wolf_1 => 'Haggling with the random numbers…';

  @override
  String get tips_generating_wolf_2 => 'Having a word with the sixth finger…';

  @override
  String get tips_generating_wolf_3 => 'Asking the pixels to line up…';

  @override
  String get tips_generating_wolf_4 => 'Wiping away the noise, grain by grain…';

  @override
  String get tips_generating_wolf_5 => 'A wolf is howling encouragement…';

  @override
  String get tips_generating_wolf_6 => 'Explaining your taste to the GPU…';

  @override
  String get tips_generating_wolf_7 => 'Translating your prompt into a dream…';

  @override
  String get tips_generating_wolf_8 => 'Double-checking the eye count…';

  @override
  String get tips_generating_wolf_9 => 'Finding a flattering light…';

  @override
  String get tips_generating_wolf_10 =>
      'Convincing the background not to steal the show…';

  @override
  String get tips_generating_wolf_11 => 'Fishing your image out of the noise…';

  @override
  String get tips_generating_wolf_12 => 'Counting fingers: one, two, three…';

  @override
  String get tips_generating_wolf_13 => 'Waiting for the paint to dry…';

  @override
  String get tips_generating_wolf_14 => 'Summoning today\'s luck…';

  @override
  String get tips_generating_trick_1 => 'Changed your mind? Esc cancels';

  @override
  String get tips_generating_trick_2 => 'The preview sharpens frame by frame';

  @override
  String get tips_generating_trick_3 =>
      'Finished images save to the gallery by default';

  @override
  String get tips_generating_trick_4 =>
      'Each sampling step removes a little more noise';

  @override
  String get tips_splash_guide_1 => 'Press F1 any time to see every shortcut.';

  @override
  String get tips_splash_guide_2 =>
      'Ctrl+Enter generates, and every shortcut can be remapped in Settings.';

  @override
  String get tips_splash_guide_3 =>
      'Drop an image into the window to read its prompt and settings.';

  @override
  String get tips_splash_guide_4 =>
      'Save prompts you use often as blocks and reuse them in one click.';

  @override
  String get tips_splash_trick_1 =>
      'That STEP /28 up there is a nod to the default 28 sampling steps.';

  @override
  String get tips_splash_trick_2 =>
      'Pre-encoded Vibes can be reused for free — that\'s 2 Anlas saved.';

  @override
  String get tips_splash_trick_3 =>
      'Building the gallery index takes a while the first time; keep working meanwhile.';

  @override
  String get tips_splash_wolf_1 => 'Five more minutes… fine, I\'m up.';

  @override
  String get tips_splash_wolf_2 => 'Tidying up the den. Almost ready.';

  @override
  String get tips_splash_wolf_3 =>
      'GPU ready. Moon ready. Just waiting on you.';

  @override
  String get tips_splash_wolf_4 => 'Smell that? Fresh prompts.';

  @override
  String get tips_splash_wolf_5 => 'Let\'s have some good pulls today.';

  @override
  String genButton_normal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generate $count Images',
      one: 'Generate 1 Image',
    );
    return '$_temp0';
  }

  @override
  String get genButton_one_1 => 'Just this one';

  @override
  String get genButton_one_2 => 'One good one, please';

  @override
  String get genButton_one_3 => 'Single pull, leap of faith';

  @override
  String get genButton_one_4 => 'Testing the waters';

  @override
  String get genButton_one_5 => 'One shot, one verdict';

  @override
  String get genButton_one_6 => 'This one is a masterpiece';

  @override
  String get genButton_one_7 => 'Just one, I swear';

  @override
  String get genButton_one_8 => 'New avatar incoming';

  @override
  String get genButton_one_9 => 'One and done';

  @override
  String get genButton_one_10 => 'Wallpaper material, please';

  @override
  String get genButton_one_11 => 'A gentle single pull';

  @override
  String get genButton_one_12 => 'Fetch me one';

  @override
  String genButton_few_1(int count) {
    return '$count images, pick the best';
  }

  @override
  String genButton_few_2(int count) {
    return '$count to compare';
  }

  @override
  String genButton_few_3(int count) {
    return '$count-pull';
  }

  @override
  String genButton_few_4(int count) {
    return '$count tries, one will land';
  }

  @override
  String genButton_few_5(int count) {
    return 'Pick 1 of $count';
  }

  @override
  String genButton_few_6(int count) {
    return '$count to warm up';
  }

  @override
  String genButton_few_7(int count) {
    return '$count auditions';
  }

  @override
  String genButton_few_8(int count) {
    return '$count little wins';
  }

  @override
  String genButton_batch_1(int count) {
    return '$count-shot burst';
  }

  @override
  String genButton_batch_2(int count) {
    return '$count at once';
  }

  @override
  String genButton_batch_3(int count) {
    return '$count images, getting hooked';
  }

  @override
  String genButton_batch_4(int count) {
    return '$count in one go';
  }

  @override
  String genButton_batch_5(int count) {
    return '$count to fill the screen';
  }

  @override
  String genButton_batch_6(int count) {
    return '$count-pull, playing it safe';
  }

  @override
  String genButton_batch_7(int count) {
    return '$count images, the pack is out';
  }

  @override
  String genButton_batch_8(int count) {
    return '$count servings coming up';
  }

  @override
  String genButton_many_1(int count) {
    return '$count images, turning it up';
  }

  @override
  String genButton_many_2(int count) {
    return '$count images, GPU sweating';
  }

  @override
  String genButton_many_3(int count) {
    return '$count images, stockpiling';
  }

  @override
  String genButton_many_4(int count) {
    return '$count images, assembly line on';
  }

  @override
  String genButton_many_5(int count) {
    return '$count images, Anlas burning';
  }

  @override
  String genButton_many_6(int count) {
    return '$count images, daily upload mode';
  }

  @override
  String genButton_many_7(int count) {
    return '$count-image batch run';
  }

  @override
  String genButton_many_8(int count) {
    return '$count images, the wolf is stunned';
  }

  @override
  String genButton_huge_1(int count) {
    return '$count?! Opening a gallery?';
  }

  @override
  String genButton_huge_2(int count) {
    return '$count images, the drive is shaking';
  }

  @override
  String genButton_huge_3(int count) {
    return '$count images, industrial revolution';
  }

  @override
  String genButton_huge_4(int count) {
    return '$count images, deep breath first';
  }

  @override
  String genButton_huge_5(int count) {
    return '$count images, got the space?';
  }

  @override
  String genButton_huge_6(int count) {
    return '$count images, print shop open';
  }

  @override
  String genButton_huge_7(int count) {
    return '$count images, wholesale';
  }

  @override
  String genButton_huge_8(int count) {
    return '$count images, the wolf went for backup';
  }

  @override
  String get genButton_rare_1 => 'SSR guaranteed';

  @override
  String get genButton_rare_2 => 'The AI feels lucky today';

  @override
  String get genButton_rare_3 => 'Today\'s fortune: excellent';

  @override
  String get genButton_rare_4 => 'They say this button likes you';

  @override
  String get genButton_rare_5 => 'The wolf howled at the moon';

  @override
  String get genButton_rare_6 => 'Luck buff active';

  @override
  String get genButton_rare_7 => 'Luck recharged';

  @override
  String get genButton_rare_8 => 'This pull is sponsored by the wolf';

  @override
  String get genButton_rare_9 => 'Come on, luck!';

  @override
  String get genButton_rare_10 => 'Press to believe';

  @override
  String get genButton_night_1 => 'Late night, last pull';

  @override
  String get genButton_night_2 => 'One more batch, then bed';

  @override
  String get genButton_night_3 => '3 a.m. taste is wild';

  @override
  String get genButton_night_4 => 'The wolf is up with you';

  @override
  String genButton_special_7(int count) {
    return 'Lucky $count';
  }

  @override
  String genButton_special_9(int count) {
    return '$count for a full 3×3 grid';
  }

  @override
  String genButton_special_42(int count) {
    return '$count: the answer to everything';
  }

  @override
  String genButton_special_99(int count) {
    return '$count, one short of a hundred';
  }

  @override
  String genButton_special_100(int count) {
    return 'A clean $count. Satisfying';
  }

  @override
  String get titleBar_minimize => 'Minimize';

  @override
  String get titleBar_maximize => 'Maximize';

  @override
  String get titleBar_restore => 'Restore';

  @override
  String get titleBar_close => 'Close';

  @override
  String get img2img_pixelSnap => 'Pixel Snap';

  @override
  String get img2img_original => 'Original';

  @override
  String get img2img_directorAddToQueue => 'Use result as next input';

  @override
  String get img2img_transform => 'Transform';

  @override
  String get img2img_palette => 'Palettize';

  @override
  String get img2img_paletteOff => 'Off';

  @override
  String get img2img_paletteAuto => 'Auto';

  @override
  String get img2img_paletteCustom => 'Custom';

  @override
  String get img2img_avoidOverRefining => 'Avoid Over-Refining';

  @override
  String get img2img_keepGridHint => 'Preserve the detected pixel grid.';

  @override
  String get img2img_refineGridHint =>
      'A finer pixel size may be used when it matches the image better.';

  @override
  String get img2img_pixelUpscaleHint =>
      'Enlarge the result with crisp, nearest-neighbor pixels.';

  @override
  String get img2img_pixelNativeHint =>
      'Keep the result at its snapped pixel size.';

  @override
  String get img2img_masked => 'Masked';

  @override
  String get img2img_generated => 'Generated';

  @override
  String get img2img_blend => 'Blend';

  @override
  String get img2img_emotionHappy => 'Happy';

  @override
  String get img2img_emotionLaugh => 'Laughing';

  @override
  String get img2img_emotionSad => 'Sad';

  @override
  String get img2img_emotionAngry => 'Angry';

  @override
  String get img2img_emotionSurprised => 'Surprised';

  @override
  String get img2img_emotionShy => 'Shy';

  @override
  String get img2img_emotionExcited => 'Excited';

  @override
  String get img2img_emotionDisgusted => 'Disgusted';

  @override
  String get img2img_emotionSmug => 'Smug';

  @override
  String get img2img_emotionWorried => 'Worried';

  @override
  String get img2img_emotionLove => 'Loving';

  @override
  String get img2img_emotionPlayful => 'Playful';

  @override
  String get img2img_emotionTired => 'Tired';

  @override
  String get img2img_emotionNeutral => 'Neutral';

  @override
  String get img2img_enhanceAction => 'Enhance!';

  @override
  String get img2img_showAdvanced => 'Show Advanced';

  @override
  String get img2img_hideAdvanced => 'Hide Advanced';

  @override
  String promptToken_usage(int used, int limit) {
    return 'Token usage: $used / $limit';
  }

  @override
  String promptToken_promptShare(int used, int total, int limit) {
    return 'This prompt: $used tokens; total usage: $total / $limit';
  }

  @override
  String get promptToken_blockReferenceHint =>
      'This block\'s progress is a guide; the total depends on how blocks are combined.';

  @override
  String get settings_geistDark => 'Geist Dark';

  @override
  String get settings_geistLight => 'Geist Light';

  @override
  String get settings_geistDescription =>
      'One appearance across your studio. Black or white surfaces, with blue accents.';

  @override
  String get styleExplore_collapseGallery => 'Collapse candidate gallery';

  @override
  String get updateCapsuleLabel => 'Update';

  @override
  String get updateWaitForTask =>
      'Wait for the current task to finish before restarting';

  @override
  String get updateLater => 'Later';

  @override
  String get nav_tagWiki => 'Tag Wiki';

  @override
  String get wiki_title => 'Tag Wiki';

  @override
  String get wiki_allTags => 'All tags';

  @override
  String get wiki_bookmarks => 'Bookmarks';

  @override
  String get wiki_newCollection => 'New bookmark collection';

  @override
  String get wiki_newChildCollection => 'New child collection';

  @override
  String get wiki_renameCollection => 'Rename';

  @override
  String get wiki_deleteCollection => 'Delete collection';

  @override
  String get wiki_officialDirectory => 'Official directory';

  @override
  String get wiki_searchHint => 'Search tags or aliases';

  @override
  String get wiki_typeAll => 'All types';

  @override
  String get wiki_coverageAll => 'All descriptions';

  @override
  String get wiki_withArticle => 'Has description';

  @override
  String get wiki_withoutArticle => 'No description yet';

  @override
  String get wiki_sortPopular => 'Popularity';

  @override
  String get wiki_sortName => 'Name';

  @override
  String get wiki_dataStatus => 'Data status';

  @override
  String get wiki_scopeCurrent => 'Current section';

  @override
  String get wiki_scopeAll => 'Search all tags';

  @override
  String get wiki_readingSettings => 'Reading settings';

  @override
  String get wiki_textSize => 'Article text';

  @override
  String get wiki_readingWidth => 'Reading width';

  @override
  String get wiki_small => 'Small';

  @override
  String get wiki_standard => 'Standard';

  @override
  String get wiki_large => 'Large';

  @override
  String get wiki_wide => 'Wide';

  @override
  String get wiki_hide => 'Hide';

  @override
  String get wiki_articleMissing =>
      'This tag has no local Wiki description yet.';

  @override
  String get wiki_source => 'Source';

  @override
  String get wiki_addBookmark => 'Bookmark';

  @override
  String get wiki_removeBookmark => 'Remove bookmark';

  @override
  String get wiki_addToCollection => 'Add to collection';

  @override
  String get wiki_loadMore => 'Load more';

  @override
  String get wiki_noResults => 'No matching tags';

  @override
  String get wiki_noSelection => 'Select a tag to read its description';

  @override
  String get wiki_collectionNameHint => 'Collection name';

  @override
  String get wiki_syncTags => 'Sync Danbooru tags';

  @override
  String get wiki_directorySource => 'Official group directory snapshot';

  @override
  String get wiki_openFull => 'Open in Tag Wiki';

  @override
  String get shortcut_action_vibe_detail_prev_sub_vibe => 'Previous sub-Vibe';

  @override
  String get shortcut_action_vibe_detail_next_sub_vibe => 'Next sub-Vibe';

  @override
  String get settings_addAccountsSwitchBetweenThem =>
      'Add accounts to switch between them here.';

  @override
  String get settings_current => 'Current';

  @override
  String get settings_emailLogin => 'Email login';

  @override
  String get settings_signedIn => 'Signed in';

  @override
  String get settings_switch => 'Switch';

  @override
  String get settings_accountActions => 'Account actions';

  @override
  String get settings_editProfile => 'Edit profile';

  @override
  String get settings_setDefault => 'Set as default';

  @override
  String get settings_credentialsUpdated => 'Credentials updated';

  @override
  String get settings_updateCredentials => 'Update credentials';

  @override
  String get settings_accountDetails => 'Account details';

  @override
  String get settings_localAccountProfile => 'Local account profile';

  @override
  String get settings_setDefault2 => 'Set default';

  @override
  String get settings_credentialsWereNotUpdatedCheck =>
      'Credentials were not updated. Check the token and connection.';

  @override
  String get settings_updateCredentials2 => 'Update credentials';

  @override
  String get settings_checking => 'Checking…';

  @override
  String get settings_enterNewSignInToken =>
      'Enter a new sign-in token. This account updates after validation.';

  @override
  String get auth_signInAccounts => 'Sign-in & accounts';

  @override
  String get auth_notSignedIn => 'Not signed in';

  @override
  String get auth_chooseAccountContinue => 'Choose an account to continue';

  @override
  String get auth_manageAccounts2 => 'Manage accounts';

  @override
  String get auth_subscriptionExpired => 'Subscription expired';

  @override
  String get settings_tagExpansion => 'Tag expansion';

  @override
  String get settings_tagDictionaries => 'Tag dictionaries';

  @override
  String get settings_cacheMaintenance => 'Cache maintenance';

  @override
  String get settings_clear => 'Clear';

  @override
  String get settings_autoRefresh => 'Auto refresh';

  @override
  String get settings_searchFonts => 'Search fonts';

  @override
  String get settings_couldNotLoadFonts => 'Could not load fonts';

  @override
  String get settings_recommended => 'Recommended';

  @override
  String get settings_included => 'Included';

  @override
  String get settings_systemFonts => 'System fonts';

  @override
  String get settings_fontPreview => 'Font preview';

  @override
  String get settings_onlineFontsLoadAfterApplying =>
      'Online fonts load after applying; preview uses the interface font.';

  @override
  String get settings_saving => 'Saving';

  @override
  String get settings_howGeneratedImagesSaved =>
      'How generated images are saved';

  @override
  String get settings_assetsDisplay => 'Assets & display';

  @override
  String get settings_vibeLocationThumbnailQuality =>
      'Vibe location and thumbnail quality';

  @override
  String get settings_applicationData => 'Application data';

  @override
  String get settings_gallerySources => 'Gallery sources';

  @override
  String get settings_manageAdditionalGalleryFolders =>
      'Manage additional gallery folders';

  @override
  String get settings_default => 'Default';

  @override
  String get settings_keyboard => 'Keyboard';

  @override
  String get settings_customizeFrequentlyUsedActions =>
      'Customize frequently used actions';

  @override
  String get settings_manageShortcuts => 'Manage shortcuts';

  @override
  String get settings_costReminders => 'Cost reminders';

  @override
  String get settings_requestPacing => 'Request pacing';

  @override
  String get settings_notificationsSound => 'Notifications & sound';

  @override
  String get settings_lockCanvasCamera => 'Lock canvas camera';

  @override
  String get settings_dictionariesCache => 'Dictionaries & cache';

  @override
  String get settings_defaultAccount2 => 'Default account';

  @override
  String get settings_signInAutomatically => 'Sign in automatically';

  @override
  String get settings_signInCredentials => 'Sign-in credentials';

  @override
  String get settings_translationInterfaces => 'Translation interfaces';

  @override
  String get settings_presetsBuiltInRules => 'Presets & built-in rules';

  @override
  String get settings_preferenceBackupRestore => 'Preference backup & restore';

  @override
  String get settings_searchSettingsFeatures => 'Search settings and features';

  @override
  String get settings_noMatchingSettings => 'No matching settings';

  @override
  String get settings_change => 'Change';

  @override
  String get settings_couldNotPlaySoundCheck =>
      'Could not play the sound. Check the audio file.';

  @override
  String get settings_useDefaultCompletionSound =>
      'Use the default completion sound';

  @override
  String get settings_soundPreview => 'Sound preview';

  @override
  String get settings_listenCurrentCompletionSound =>
      'Listen to the current completion sound';

  @override
  String get settings_playSound => 'Play sound';

  @override
  String get settings_searchResults => 'Search results';

  @override
  String get settings_promptInput => 'Prompt input';

  @override
  String get settings_manageTranslationModelsRules =>
      'Manage translation models & rules';

  @override
  String get settings_browsing => 'Browsing';

  @override
  String get settings_chooseHowViewImages => 'Choose how to view images';

  @override
  String get settings_canvasControls => 'Canvas controls';

  @override
  String get settings_keepViewSteady => 'Keep the view steady';

  @override
  String get settings_appearance2 => 'Appearance';

  @override
  String get settings_chooseLightDarkWorkspace =>
      'Choose a light or dark workspace';

  @override
  String get settings_textLanguage => 'Text & language';

  @override
  String get settings_makeReadingComfortable => 'Make reading comfortable';

  @override
  String get settings_adjustSettingsPagesDialogsOnly =>
      'Adjust settings pages and dialogs only';

  @override
  String get settings_motionNotifications => 'Motion & notifications';

  @override
  String get settings_reduceDistractionsKnowWorkFinishes =>
      'Reduce distractions, know when work finishes';

  @override
  String get settings_notificationStyle => 'Notification style';

  @override
  String get settings_notificationsAppearUpperRightWrap =>
      'Notifications appear at the upper right, wrap long messages, and close when progress tasks finish.';

  @override
  String get settings_preview => 'Preview';

  @override
  String get settings_versionUpdates => 'Version & updates';

  @override
  String get settings_currentVersionUpdateOptions =>
      'Current version and update options';

  @override
  String get settings_diagnosticsResources => 'Diagnostics & resources';

  @override
  String get settings_logsFontsOpenSourceProject =>
      'Logs, fonts and the open-source project';

  @override
  String get settings_viewLicenses => 'View licenses';

  @override
  String get settings_openProject => 'Open project';

  @override
  String get settings_actionIncomplete => 'Action incomplete';

  @override
  String get settings_exportPreferences => 'Export preferences';

  @override
  String get settings_preferencesExported => 'Preferences exported';

  @override
  String get settings_noAutomaticBackupYet => 'No automatic backup yet';

  @override
  String get settings_restorePreviousPreferences =>
      'Restore previous preferences';

  @override
  String get settings_importPreferences => 'Import preferences';

  @override
  String get settings_apply => 'Apply';

  @override
  String get settings_preferencesAppliedPreviousSettingsBacked =>
      'Preferences applied; previous settings backed up';

  @override
  String get settings_restoreDefaultPreferences =>
      'Restore default preferences';

  @override
  String get settings_choosePreferencesResetCurrentSettings =>
      'Choose the preferences to reset. Current settings will be backed up.';

  @override
  String get settings_appearanceSoundControls => 'Appearance, sound & controls';

  @override
  String get settings_inputAutocomplete => 'Input & autocomplete';

  @override
  String get settings_privacyGenerationProtection =>
      'Privacy & generation protection';

  @override
  String get settings_moveAppearanceControlsInputProtection =>
      'Move appearance, controls, input and protection preferences between devices.';

  @override
  String get settings_rollbackCopySavedBeforeImport =>
      'A rollback copy is saved before an import or reset.';

  @override
  String get settings_resetSelectedScopeWhileKeeping =>
      'Reset a selected scope while keeping accounts, models, libraries and creative work.';

  @override
  String get settings_chooseScope => 'Choose scope';

  @override
  String get settings_preferenceManagement => 'Preference management';

  @override
  String get settings_backupMigrationRecovery =>
      'Backup, migration and recovery';

  @override
  String get settings_generalAppearance => 'General & appearance';

  @override
  String get settings_makeWorkspaceComfortableReadUse =>
      'Make the workspace comfortable to read and use.';

  @override
  String get settings_controlsShortcuts => 'Controls & shortcuts';

  @override
  String get settings_chooseInteractionCanvasControlsKeyboard =>
      'Choose interaction, canvas controls and keyboard shortcuts.';

  @override
  String get settings_generationPrompts => 'Generation & prompts';

  @override
  String get settings_managePromptInputGenerationReminders =>
      'Manage prompt input, generation reminders and request pacing.';

  @override
  String get settings_galleryFiles => 'Gallery & files';

  @override
  String get settings_manageImageSavingGallerySources =>
      'Manage image saving, gallery sources and display.';

  @override
  String get settings_manageTagDictionariesIndexesCache =>
      'Manage tag dictionaries, indexes and cache maintenance.';

  @override
  String get settings_novelaiAccounts => 'NovelAI accounts';

  @override
  String get settings_viewAccountManageSignIn =>
      'View your account and manage sign-in and the default account.';

  @override
  String get settings_connectionsIntegrations => 'Connections & integrations';

  @override
  String get settings_manageExternalToolsBridgesNetwork =>
      'Manage external tools, bridges and network settings.';

  @override
  String get settings_privacySharing2 => 'Privacy & sharing';

  @override
  String get settings_controlSharedInformationConfirmationBefore =>
      'Control shared information and confirmation before sensitive actions.';

  @override
  String get settings_aboutDiagnostics => 'About & diagnostics';

  @override
  String get settings_updatesLogsProjectInformation =>
      'Updates, logs and project information.';

  @override
  String get settings_searchSettings => 'Search settings';

  @override
  String get settings_preferences => 'Preferences';

  @override
  String get settings_creationResources => 'Creation & resources';

  @override
  String get settings_servicesConnections => 'Services & connections';

  @override
  String get settings_safetyMaintenance => 'Safety & maintenance';

  @override
  String get settings_subscriptionActive => 'Subscription active';

  @override
  String get settings_availableBalance => 'Available balance';

  @override
  String get settings_subscriptionExpiry2 => 'Subscription expiry';

  @override
  String get settings_subscriptionDetailsUnavailable =>
      'Subscription details are unavailable';

  @override
  String get settings_loadingSubscriptionDetails =>
      'Loading subscription details…';

  @override
  String get settings_localDataStaysAvailableAfter =>
      'Local data stays available after expiry.';

  @override
  String get settings_records => 'records';

  @override
  String get settings_hitRate => 'Hit rate';

  @override
  String get settings_images => 'images';

  @override
  String get settings_cacheOverview => 'Cache overview';

  @override
  String get settings_loginPreferences => 'Login preferences';

  @override
  String get settings_preselectedSignInPage =>
      'Preselected on the sign-in page.';

  @override
  String get settings_noAccounts => 'No accounts';

  @override
  String get settings_useLastSessionOffNext =>
      'Use the last session. When off, the next launch opens sign-in.';

  @override
  String get settings_couldNotSaveLoginPreference =>
      'Could not save the login preference.';

  @override
  String get settings_loginPreferencesUnavailable =>
      'Login preferences are unavailable.';

  @override
  String settings_applyPreferencesConfirm(Object count) {
    return 'Apply $count preferences. Current preferences are backed up automatically and can be recovered from “Restore previous preferences”. Accounts, secrets, drafts, libraries and model configurations are kept separately.';
  }

  @override
  String get settings_restore => 'Restore';

  @override
  String get wiki_translating => 'Translating';

  @override
  String get wiki_back => 'Back';

  @override
  String get wiki_readingTranslation => 'Translation';

  @override
  String get wiki_readingOriginal => 'Original';

  @override
  String get wiki_switchToOriginal => 'Show original';

  @override
  String get wiki_switchToTranslation => 'Show translation';

  @override
  String get wiki_retranslate => 'Retranslate';

  @override
  String get wiki_onThisPage => 'On this page';

  @override
  String get wiki_overview => 'Overview';

  @override
  String get wiki_untranslated => 'Not translated yet';

  @override
  String get wiki_autoTranslateTagsArticles =>
      'Auto-translate tags and articles';

  @override
  String get wiki_readingContent => 'Content';

  @override
  String get wiki_categoryGeneral => 'General';

  @override
  String get wiki_categoryArtist => 'Artist';

  @override
  String get wiki_categoryCopyright => 'Copyright';

  @override
  String get wiki_categoryCharacter => 'Character';

  @override
  String get wiki_categoryMeta => 'Meta';

  @override
  String get wiki_categoryContributor => 'Contributor';

  @override
  String get wiki_categorySpecies => 'Species';

  @override
  String get wiki_categoryLore => 'Lore';

  @override
  String get wiki_categoryLibrary => 'Library';

  @override
  String get toast_titleSuccess => 'Completed';

  @override
  String get toast_titleError => 'Action failed';

  @override
  String get toast_titleWarning => 'Please note';

  @override
  String get toast_titleInfo => 'Notice';

  @override
  String get toast_titleProgress => 'In progress';

  @override
  String get tagExpansion_autoTranslateVisible => 'Auto-translate visible tags';

  @override
  String get translationEditor_title => 'Translation block';

  @override
  String get translationEditor_source => 'Original';

  @override
  String get translationEditor_sourcePrefix => 'Src';

  @override
  String get translationEditor_generation => 'Generation';

  @override
  String get translationEditor_editable => 'Editable';

  @override
  String get translationEditor_modified => 'Modified';

  @override
  String get translationEditor_edited => 'Edited';

  @override
  String get translationEditor_close => 'Close';

  @override
  String get translationEditor_save => 'Save';

  @override
  String get translationEditor_delete => 'Delete block';

  @override
  String get translationEditor_restore => 'Restore original text';

  @override
  String get translationEditor_configure => 'Configure translation model';

  @override
  String translationEditor_readingFieldTitle(Object language) {
    return '$language reading text';
  }

  @override
  String translationEditor_sourceWarning(Object language) {
    return 'Original modified; $language needs syncing';
  }

  @override
  String get translationEditor_editHint =>
      'Translation edited manually; original review status is unchanged';

  @override
  String get translationLanguage_chinese => 'Chinese';

  @override
  String get translationLanguage_english => 'English';

  @override
  String get translationLanguage_japanese => 'Japanese';

  @override
  String get translationLanguage_korean => 'Korean';

  @override
  String get translationLanguage_traditionalChinese => 'Traditional Chinese';

  @override
  String get promptBlockEditor_translationNeedsReview =>
      'Original changed; translation needs updating';

  @override
  String get promptBlockEditor_translationReviewHint =>
      'After editing the original, review this translation as well';

  @override
  String get modelTask_translateTitle => 'Original → reading language';

  @override
  String get modelTask_promptReverseTitle => 'Reading language → original';

  @override
  String get modelTask_tagTranslateTitle => 'Tag name translation';

  @override
  String get modelTask_wikiTranslateTitle => 'Wiki article translation';

  @override
  String get modelTask_translateDescription =>
      'Translate prompts and blocks while preserving weights, groups and tag meaning.';

  @override
  String get modelTask_promptReverseDescription =>
      'Apply additions, deletions and edits from the translation to the original, then return it for review.';

  @override
  String get modelTask_tagTranslateDescription =>
      'Give visible tags concise, accurate names.';

  @override
  String get modelTask_wikiTranslateDescription =>
      'Translate wiki articles, tidy the layout and choose clickable tags from context.';

  @override
  String get modelTask_connectionTest => 'Model connection test';

  @override
  String get modelReasoning_serviceDefault => 'Service default';

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
  String get modelReasoning_xhigh => 'Extra high';

  @override
  String get modelReasoning_max => 'Max';

  @override
  String get modelProvider_custom => 'Custom service';

  @override
  String get modelProvider_qwen => 'Qwen · Alibaba Model Studio';

  @override
  String get modelProvider_moonshot => 'Kimi · Moonshot AI';

  @override
  String get modelProvider_zhipu => 'Zhipu GLM';

  @override
  String get modelProvider_doubao => 'Doubao · Volcano Ark';

  @override
  String get modelProvider_hunyuan => 'Tencent Hunyuan';

  @override
  String get modelProvider_qianfan => 'Baidu Qianfan';

  @override
  String get modelProvider_siliconflow => 'SiliconFlow';

  @override
  String get modelProvider_zai => 'Z.AI · International';

  @override
  String get modelProvider_zhipuCodingPlan => 'Zhipu Coding Plan';

  @override
  String get modelProvider_kimiCoding => 'Kimi Coding';

  @override
  String get modelProvider_moonshotInternational =>
      'Moonshot AI · International';

  @override
  String get modelProvider_minimaxChinaChat => 'MiniMax · China OpenAI';

  @override
  String get modelProvider_minimaxChinaMessages => 'MiniMax · China Anthropic';

  @override
  String get modelProvider_minimaxInternationalMessages =>
      'MiniMax · International Anthropic';

  @override
  String get modelProvider_xiaomi => 'Xiaomi MiMo';

  @override
  String get modelProvider_antLing => 'Ant Ling';

  @override
  String get modelProvider_stepfunPlan => 'StepFun Step Plan';

  @override
  String get modelProvider_qwenTokenPlanChina => 'Qwen Token Plan · China';

  @override
  String get modelProvider_hintHuggingFace =>
      'Use a Hugging Face token with inference permission; router model IDs can be added manually.';

  @override
  String get modelProvider_hintPlanKey =>
      'Use the API key for this plan; available models and scope follow what the plan returns.';

  @override
  String get modelProvider_hintInternationalEndpoint =>
      'International endpoint; use an API key from the international platform.';

  @override
  String get modelProvider_hintRegionOpenAi =>
      'Use the API key for the matching region; the OpenAI Chat Completions compatible address is prefilled.';

  @override
  String get modelProvider_hintRegionAnthropic =>
      'Use the API key for the matching region; the Anthropic Messages compatible address is prefilled.';

  @override
  String get modelProvider_hintQwen =>
      'Defaults to the Beijing region; for other regions use the matching key and change the endpoint.';

  @override
  String get modelProvider_hintMinimax =>
      'Defaults to the international pay-as-you-go endpoint; for the China platform use its key and endpoint.';

  @override
  String get modelProvider_hintMoonshot =>
      'Defaults to the China platform; for the international platform use its key and endpoint.';

  @override
  String get modelProvider_hintZhipu =>
      'Defaults to the pay-as-you-go endpoint; Coding Plan uses its own address.';

  @override
  String get modelProvider_hintDoubao =>
      'Use an Ark API key; enable the model first, or add an inference endpoint ID.';

  @override
  String get modelProvider_hintCustom =>
      'Enter the compatible service address and key, then choose the protocol in the connection details.';

  @override
  String get modelProvider_hintLocal =>
      'Start the local service first, then read the loaded model list.';

  @override
  String get modelProvider_hintDefault =>
      'Address and protocol are prefilled; save a key to start choosing models.';

  @override
  String get modelParams_temperatureRange =>
      'Temperature must be between 0 and 2.';

  @override
  String get modelParams_topPRange =>
      'Top P must be greater than 0 and at most 1.';

  @override
  String get modelParams_maxOutputPositive =>
      'Max output tokens must be greater than 0.';

  @override
  String get modelParams_anthropicTemperatureRange =>
      'Anthropic temperature must be between 0 and 1.';

  @override
  String get modelParams_anthropicSamplingConflict =>
      'Anthropic accepts either temperature or Top P; check the model parameters.';

  @override
  String modelParams_thinkingBudgetTooSmall(Object minimum) {
    return 'Max output must be larger than the minimum thinking budget of $minimum.';
  }

  @override
  String get modelOverrides_invalidHeaderName => 'Enter a valid header name';

  @override
  String get modelOverrides_invalidHeaderValue =>
      'Header values cannot contain line breaks or control characters';

  @override
  String get modelOverrides_emptyBodyField =>
      'Body field names cannot be empty';

  @override
  String get modelOverrides_modelFromList =>
      'Set the model ID from the model list';

  @override
  String get modelOverrides_streamMustBeFalse =>
      'This connection uses non-streaming requests; stream must be false';

  @override
  String get modelConfig_changedSaveAgain =>
      'The configuration changed. Save again.';

  @override
  String get modelConfig_presetChanged =>
      'The selected preset changed. Choose again.';

  @override
  String get modelConfig_serviceDisabled =>
      'The selected service was disabled. Choose again.';

  @override
  String get modelConfig_modelChanged =>
      'The selected model changed. Choose again.';

  @override
  String get modelConfig_reasoningChanged =>
      'The model’s reasoning levels changed. Choose again or follow the model.';

  @override
  String get modelConfig_presetIdRequired => 'Preset ID cannot be empty.';

  @override
  String get modelConfig_saveBuiltinAsCustom =>
      'Save the built-in preset as a custom preset.';

  @override
  String get modelConfig_namePromptRequired =>
      'Name and prompt cannot be empty.';

  @override
  String get modelConfig_builtinNotDeletable =>
      'Built-in rules cannot be deleted.';

  @override
  String get modelConfig_pasteFullJson =>
      'Paste the complete model configuration JSON.';

  @override
  String get modelConfig_builtinNotOverwritable =>
      'Built-in presets cannot be overwritten; copy them as custom presets.';

  @override
  String get modelConfig_invalidProvider =>
      'Invalid service ID, name or address.';

  @override
  String get modelConfig_missingProvider =>
      'The model’s service does not exist.';

  @override
  String get modelConfig_invalidCustomPreset =>
      'Invalid custom preset ID, name or prompt.';

  @override
  String get modelConfig_changedImportAgain =>
      'The configuration changed. Import again.';

  @override
  String get modelHealth_unverified =>
      'Connection not verified yet; it updates after using a model or “Test connection”.';

  @override
  String get modelHealth_healthy => 'The last request succeeded';

  @override
  String get modelHealth_limited =>
      'Reachable, but the last request was rate limited (HTTP 429); try later or check your quota';

  @override
  String get modelHealth_authentication =>
      'Authentication failed; check the API key';

  @override
  String get modelHealth_permission =>
      'Access denied; check the service permissions';

  @override
  String get modelHealth_timeout => 'The last request timed out';

  @override
  String get modelHealth_network =>
      'The last request could not reach the service';

  @override
  String get modelHealth_invalidResponse =>
      'The last response was invalid; see the request log for details';

  @override
  String get modelHealth_failed => 'The last request failed';

  @override
  String modelHealth_failedStatus(Object status) {
    return 'The last request failed (HTTP $status)';
  }

  @override
  String get modelRequest_statusPending => 'Waiting';

  @override
  String get modelRequest_statusRunning => 'Requesting';

  @override
  String get modelRequest_statusSuccess => 'Succeeded';

  @override
  String get modelRequest_statusFailed => 'Failed';

  @override
  String get modelRequest_statusCancelled => 'Cancelled';

  @override
  String get modelRequest_fieldTime => 'Time';

  @override
  String get modelRequest_fieldMethod => 'Method';

  @override
  String get modelRequest_fieldUrl => 'URL';

  @override
  String get modelRequest_fieldRequestHeaders => 'Request headers';

  @override
  String get modelRequest_fieldBody => 'Body';

  @override
  String get modelRequest_fieldStatusCode => 'Status code';

  @override
  String get modelRequest_fieldResponseHeaders => 'Response headers';

  @override
  String get modelRequest_fieldError => 'Error';

  @override
  String get modelRequest_fieldInterface => 'Interface';

  @override
  String get modelRequest_fieldProvider => 'Service';

  @override
  String get modelRequest_fieldModel => 'Model';

  @override
  String get modelRequest_fieldProtocol => 'Protocol';

  @override
  String get modelRequest_fieldStatus => 'Status';

  @override
  String get modelRequest_fieldElapsed => 'Elapsed (ms)';

  @override
  String get modelRequest_fieldAttempts => 'Attempts';

  @override
  String get modelRequest_fieldHttpRequests => 'HTTP requests';

  @override
  String get modelRequest_fieldParameters => 'Effective parameters';

  @override
  String get modelRequest_redacted => '[redacted]';

  @override
  String get modelRequest_emptyResponse => 'The model returned empty content.';

  @override
  String get modelService_testFieldsIncomplete =>
      'The test response is missing fields.';

  @override
  String get modelService_testFieldsInvalid =>
      'The test response has invalid fields.';

  @override
  String get modelService_testGroupsInvalid =>
      'The test response has invalid groups.';

  @override
  String get modelService_testSourceEmpty =>
      'The test response returned an empty original.';

  @override
  String get modelService_conversionCancelled => 'Conversion cancelled';

  @override
  String get modelService_chooseInterfaceModel =>
      'Choose a service and model in Settings → Models & APIs → Interfaces first.';

  @override
  String get modelService_enableServiceModel =>
      'Enable a service in Settings, then fetch or add a model and select it.';

  @override
  String get modelSettings_keepEditsTitle => 'Keep current edits?';

  @override
  String get modelSettings_keepEditsBody =>
      'Your changes are not saved yet. Save before switching?';

  @override
  String get modelSettings_discard => 'Discard';

  @override
  String get modelSettings_saveAndSwitch => 'Save and switch';

  @override
  String get modelSettings_addProvider => 'Add service';

  @override
  String modelSettings_deleteProviderTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String get modelSettings_deleteProviderBody =>
      'This service’s connection, key and selected models will be deleted.';

  @override
  String modelSettings_deleteProviderBindings(Object count) {
    return '$count interface model bindings will be cleared; presets are kept.';
  }

  @override
  String modelSettings_deletePresetTitle(Object name) {
    return 'Delete “$name”?';
  }

  @override
  String get modelSettings_deletePresetBody =>
      'Interfaces using this preset return to the built-in preset. Model bindings are kept.';

  @override
  String get modelSettings_configCopied =>
      'Configuration copied, without keys, custom headers or bodies.';

  @override
  String get modelSettings_importConfig => 'Import configuration';

  @override
  String get modelSettings_importConfigHint =>
      'Paste an exported configuration. The current configuration is backed up first; keys stay stored separately.';

  @override
  String get modelSettings_configJson => 'Configuration JSON';

  @override
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  ) {
    return 'Imports $providers services, $models models and $presets custom presets.';
  }

  @override
  String get modelSettings_importMissingProviders =>
      'Service or model configuration is missing.';

  @override
  String get modelSettings_checkConfig => 'Check configuration';

  @override
  String get modelSettings_importAndReplace => 'Import and replace';

  @override
  String get modelSettings_configImported => 'Configuration imported';

  @override
  String get modelSettings_description =>
      'Manage service connections and translation preferences.';

  @override
  String get modelSettings_configMenu => 'Configuration';

  @override
  String get modelSettings_copyConfig => 'Copy configuration';

  @override
  String get modelSettings_tabProviders => 'Services';

  @override
  String get modelSettings_tabInterfaces => 'Interfaces';

  @override
  String get modelSettings_tabPresets => 'Presets & prompts';

  @override
  String get modelSettings_tabRequests => 'Request log';

  @override
  String modelSettings_providersCount(Object count) {
    return 'Services · $count';
  }

  @override
  String modelSettings_providerModelCount(Object count) {
    return '$count models';
  }

  @override
  String get modelSettings_providerDisabledSuffix => ' · Disabled';

  @override
  String get modelSettings_emptyTitle => 'Add your first model service';

  @override
  String get modelSettings_emptyBody =>
      'Choose a common service or connect a custom endpoint.';

  @override
  String get modelSettings_customService => 'Custom service';

  @override
  String get modelSettings_notConfigured => 'Not configured';

  @override
  String get modelSettings_preset => 'Preset';

  @override
  String get modelSettings_presetBuiltin => 'Built-in';

  @override
  String get modelSettings_presetUser => 'User';

  @override
  String get modelSettings_deletePreset => 'Delete preset';

  @override
  String modelSettings_presetCopyName(Object title, Object number) {
    return '$title ($number)';
  }

  @override
  String get modelSettings_recentRequests => 'Recent requests';

  @override
  String get modelSettings_recentRequestsHint =>
      'Last 100 in this session · full requests and responses, with authentication redacted';

  @override
  String get modelSettings_clearRequests => 'Clear';

  @override
  String get modelSettings_requestsEmpty =>
      'Requests appear here after you translate or test a model.';

  @override
  String get modelSettings_interfaceChangedElsewhere =>
      'The interface configuration changed elsewhere. Reopen it to edit.';

  @override
  String get modelSettings_configSaved => 'Configuration saved';

  @override
  String get modelSettings_viewBuiltinRules => 'View built-in rules';

  @override
  String get modelSettings_viewEditPreset => 'View and edit preset';

  @override
  String get modelSettings_restoreBuiltinPreset => 'Restore built-in preset';

  @override
  String get modelSettings_followUiLanguage => 'Follow interface language';

  @override
  String get modelSettings_providerAndModel => 'Service and model';

  @override
  String get modelSettings_providerAndModelHelp =>
      'Only selected models from enabled services are listed';

  @override
  String get modelSettings_chooseProviderModel => 'Choose a service and model';

  @override
  String get modelSettings_reasoning => 'Thinking';

  @override
  String get modelSettings_reasoningHelp =>
      'Plain translation usually needs no thinking. For tagging, semantic grouping and similar work, use the lowest thinking level the model supports.';

  @override
  String get modelSettings_reasoningHelpLabel => 'Thinking level advice';

  @override
  String get modelSettings_usePreset => 'Preset';

  @override
  String get modelSettings_outputLanguage => 'Output language';

  @override
  String get modelSettings_englishPrompt => 'English generation prompt';

  @override
  String get modelSettings_englishPromptHelp =>
      'Applies the edits against the original and outputs an English generation prompt.';

  @override
  String get modelSettings_targetLanguage => 'Target language';

  @override
  String get modelSettings_effective => 'Effective';

  @override
  String get modelSettings_noModelSelected => 'No available model selected';

  @override
  String modelSettings_reasoningSummaryInterface(Object level) {
    return 'Thinking: $level (this interface)';
  }

  @override
  String modelSettings_reasoningSummaryModel(Object level) {
    return 'Thinking: $level (follows model)';
  }

  @override
  String get modelSettings_promptBlocksHint =>
      'When translation isn’t needed, you can also split prompts into blocks and arrange them freely with the block feature.';

  @override
  String get modelSettings_wikiFormatHint =>
      'When translation isn’t needed, it can still tidy the layout and link related tags.';

  @override
  String get modelSettings_unsavedChanges => 'Unsaved changes';

  @override
  String get modelSettings_testPreset => 'Test preset';

  @override
  String get modelSettings_tabModelPreset => 'Model & preset';

  @override
  String get modelSettings_tabPromptOutput => 'Prompt & output';

  @override
  String get modelSettings_translationStrategy => 'Translation strategy';

  @override
  String get modelSettings_editPreset => 'Edit preset';

  @override
  String get modelSettings_outputContract => 'App output contract';

  @override
  String get modelSettings_outputContractHint =>
      'Returned fields and validation rules are maintained by the app';

  @override
  String get modelSettings_testResult => 'Test result';

  @override
  String get modelRequest_detailsRequests => 'Requests';

  @override
  String get modelRequest_detailsIndex => 'No.';

  @override
  String get modelRequest_detailsResponses => 'Responses';

  @override
  String get modelRequest_detailsOutput => 'Extracted result';

  @override
  String get modelRequest_detailsTitle => 'Request log';

  @override
  String get modelRequest_detailsCopied => 'Copied';

  @override
  String get modelRequest_detailsCopyPage => 'Copy this page';

  @override
  String get modelRequest_detailsOverview => 'Overview';

  @override
  String get modelRequest_detailsMissing =>
      'This record was cleared or is older than the last 100.';

  @override
  String get modelPreset_changedElsewhere =>
      'The preset changed elsewhere. Reopen it to edit.';

  @override
  String get modelPreset_interfacePresetChanged =>
      'The interface’s preset changed elsewhere. Reopen it to create a new one.';

  @override
  String get modelPreset_builtinReadOnly => 'Built-in · Read only';

  @override
  String get modelPreset_newInterfacePreset => 'New interface preset';

  @override
  String get modelPreset_tabPrompt => 'Prompt';

  @override
  String get modelPreset_tabOutputContract => 'Output contract';

  @override
  String get modelPreset_name => 'Preset name';

  @override
  String get modelPreset_nameRequired => 'Enter a name';

  @override
  String get modelPreset_behavior => 'Behavior & translation strategy';

  @override
  String get modelPreset_builtinLocked =>
      'Built-in rules are locked. Create an interface preset to edit your own translation preferences.';

  @override
  String get modelPreset_editHint =>
      'Edit translation preferences here; the response format is maintained by the app.';

  @override
  String get modelPreset_strategyHint => 'Enter a translation strategy';

  @override
  String get modelPreset_promptRequired => 'Prompt cannot be empty';

  @override
  String get modelPreset_restoreStrategy => 'Restore built-in strategy';

  @override
  String get modelPreset_outputContractNote =>
      'This section keeps translation results writable back and displayable; the app maintains it.';

  @override
  String get modelPreset_save => 'Save preset';

  @override
  String get modelReasoning_unsupported => 'Not supported';

  @override
  String get modelReasoning_followModel => 'Follow model';

  @override
  String modelReasoning_followModelLevel(Object level) {
    return 'Follow model ($level)';
  }

  @override
  String get modelReasoning_notAdjustable =>
      'This model does not support thinking adjustment';

  @override
  String get modelReasoning_strength => 'Thinking strength';

  @override
  String modelReasoning_modelDefault(Object level) {
    return 'Model default: $level';
  }

  @override
  String get modelReasoning_levelsUnknown =>
      'Available levels are not confirmed yet\nSet them in the service’s model settings';

  @override
  String modelReasoning_strengthValue(Object level) {
    return 'Thinking strength: $level';
  }

  @override
  String get modelProvider_customEndpoint => 'Custom endpoint';

  @override
  String get modelProvider_pickerTitle => 'Choose a service';

  @override
  String get modelProvider_pickerSearch =>
      'Search vendors, platforms or local services';

  @override
  String get modelProvider_pickerEmpty => 'No matching services';

  @override
  String get modelProvider_groupApiKey => 'API key connections';

  @override
  String get modelProvider_groupLocal => 'Local services';

  @override
  String get modelProvider_enterCompatibleAddress =>
      'Enter a compatible endpoint address';

  @override
  String get modelConnection_provider => 'Service';

  @override
  String get modelConnection_name => 'Name';

  @override
  String get modelConnection_nameExample => 'e.g. my relay';

  @override
  String get modelConnection_protocol => 'Protocol';

  @override
  String get modelConnection_address => 'Endpoint address';

  @override
  String get modelConnection_apiKey => 'API key';

  @override
  String modelControls_decrease(Object label, Object step, Object unit) {
    return 'Decrease $label ($step $unit)';
  }

  @override
  String modelControls_increase(Object label, Object step, Object unit) {
    return 'Increase $label ($step $unit)';
  }

  @override
  String get modelControls_retryOff => 'Off';

  @override
  String modelControls_retryTimes(Object count) {
    return '$count×';
  }

  @override
  String get settings_positiveIntegerRequired =>
      'Enter an integer greater than 0';

  @override
  String get modelSettings_testingPreset => 'Testing preset';

  @override
  String modelHealth_lastUpdated(Object time) {
    return 'Last updated: $time';
  }

  @override
  String get modelSettings_backToEditing => 'Back to editing';

  @override
  String modelService_loadOverridesFailed(Object error) {
    return 'Could not read custom request settings: $error';
  }

  @override
  String get modelService_timeoutRange =>
      'Request timeout must be between 10 and 600 seconds.';

  @override
  String get modelService_concurrencyRange =>
      'Max concurrency must be between 1 and 20.';

  @override
  String get modelService_nameRequired => 'Enter a service name.';

  @override
  String get modelService_invalidUrl =>
      'The endpoint must be a complete http:// or https:// URL.';

  @override
  String get modelService_contextPositive =>
      'Context window must be greater than 0.';

  @override
  String get modelService_readingCatalog => 'Reading the model list…';

  @override
  String modelService_catalogReturned(Object count) {
    return 'The service returned $count models. Check the ones you want to use.';
  }

  @override
  String modelService_catalogUnavailable(Object error) {
    return 'Model list unavailable: $error. You can add model IDs manually.';
  }

  @override
  String modelService_catalogCached(Object count) {
    return 'Loaded $count models fetched last time. Click “Fetch list” to refresh.';
  }

  @override
  String get modelService_catalogCacheFailed =>
      'Model list fetched, but saving the local cache failed; fetch again next time.';

  @override
  String get modelService_selectModelFirst => 'Select a model first.';

  @override
  String get modelService_testingModel => 'Testing a model request…';

  @override
  String modelService_testSucceeded(Object reply) {
    return 'Model request succeeded: $reply';
  }

  @override
  String modelService_testFailed(Object error) {
    return 'Model request failed: $error';
  }

  @override
  String modelService_tokensPositive(Object name) {
    return 'Token counts for model “$name” must be greater than 0.';
  }

  @override
  String get modelService_changedElsewhere =>
      'The service configuration changed elsewhere. Reopen it to edit.';

  @override
  String get modelService_overridesChangedElsewhere =>
      'Model request settings changed elsewhere. Reopen them to edit.';

  @override
  String modelService_saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get modelService_keyHintNew =>
      'Enter a key; local services can leave it empty';

  @override
  String get modelService_keyHintVendor => 'Enter the key for this service';

  @override
  String get modelService_keyHintSaved => 'Saved; leave empty to keep it';

  @override
  String modelService_enabledModels(Object count) {
    return '$count enabled models';
  }

  @override
  String get modelService_pendingSave => 'Not saved';

  @override
  String get modelService_saved => 'Saved';

  @override
  String get modelService_enable => 'Enable';

  @override
  String get modelService_testConnection => 'Test connection';

  @override
  String get modelService_delete => 'Delete service';

  @override
  String get modelService_save => 'Save service';

  @override
  String get modelService_saving => 'Saving service';

  @override
  String get modelService_notConfigured => 'Not configured';

  @override
  String get modelService_optional => 'Optional';

  @override
  String get modelService_editConnection => 'Edit';

  @override
  String get modelService_collapse => 'Collapse';

  @override
  String get modelService_connectionSettings => 'Connection settings';

  @override
  String get modelService_dragToReorder => 'Drag to reorder models';

  @override
  String get modelService_capacityTooltip =>
      'Context / max output; adjust in Advanced';

  @override
  String get modelService_advanced => 'Advanced';

  @override
  String modelService_removeModel(Object name) {
    return 'Remove model $name';
  }

  @override
  String get modelService_linkedInterfaces => 'Linked interfaces';

  @override
  String get modelService_noLinkedInterfaces => 'No linked interfaces yet';

  @override
  String get modelService_advancedSettings => 'Advanced settings';

  @override
  String get modelService_requestTimeout => 'Request timeout';

  @override
  String get modelService_requestTimeoutHelp =>
      'Longest wait for a single request';

  @override
  String get modelService_seconds => 's';

  @override
  String get modelService_maxConcurrency => 'Max concurrency';

  @override
  String get modelService_maxConcurrencyHelp =>
      'Requests this service handles at once';

  @override
  String get modelService_countUnit => '';

  @override
  String get modelService_retry => 'Retry on failure';

  @override
  String get modelService_retryHelp =>
      'Retry when the connection fails or the service is busy';

  @override
  String get modelService_searchModelId => 'Search model IDs…';

  @override
  String get modelService_serviceModels => 'Available models';

  @override
  String get modelService_fetchList => 'Fetch list';

  @override
  String get modelService_catalogEmpty =>
      'Click “Fetch list” to read this service’s models,\nor add model IDs on the right.';

  @override
  String get modelService_noMatchingModels => 'No matching models';

  @override
  String get modelService_catalogLimitTooltip =>
      'Catalog limits: context / max output';

  @override
  String get modelService_searchAddedModels => 'Search added models…';

  @override
  String get modelService_modelSettings => 'Model settings';

  @override
  String get modelService_addedEmpty =>
      'Check models on the left, or add one below';

  @override
  String get modelService_customModelId => 'Custom model ID';

  @override
  String get modelService_customModelHelp =>
      'Add models the catalog cannot list';

  @override
  String get modelService_addCustomModel => 'Add custom model';

  @override
  String get modelCard_positiveInteger => 'Enter a positive integer';

  @override
  String modelCard_catalogLimit(Object limit) {
    return 'Catalog limit $limit';
  }

  @override
  String get modelCard_outputExceedsContext =>
      'Output cannot exceed the context window';

  @override
  String get modelCard_contextWindow => 'Context window';

  @override
  String get modelCard_maxOutput => 'Max output';

  @override
  String get modelCard_unlabeled => 'Not listed';

  @override
  String get modelCard_protocolStandard => 'Standard';

  @override
  String get modelCard_protocolAdaptive => 'Adaptive';

  @override
  String get modelCard_default => 'Default';

  @override
  String get modelCard_thinkingLevels => 'Thinking levels';

  @override
  String get modelCard_thinkingLevelsUnlisted =>
      'Not listed in the catalog; you can enable them manually';

  @override
  String get modelCard_thinkingLevelsFromCatalog =>
      'Supported levels are checked from the local catalog; adjust them to match the actual API.';

  @override
  String get modelCard_thinkingProtocol => 'Thinking protocol';

  @override
  String get modelCard_defaultThinkingLevel => 'Default level';

  @override
  String get modelCard_alias => 'Alias';

  @override
  String get modelCard_aliasHelp =>
      'Shown wherever the model name appears; requests still use the model ID.';

  @override
  String get modelCard_aliasExample => 'e.g. fast';

  @override
  String get modelCard_capabilities => 'Capabilities';

  @override
  String get modelCard_images => 'Images';

  @override
  String get modelCard_nativeSearch => 'Native web search';

  @override
  String get modelCard_nativeSearchHelp =>
      'The app does not use native search on this connection yet; this does not mean the vendor or other APIs lack search.';

  @override
  String get modelOverrides_duplicateHeader => 'Duplicate header name';

  @override
  String get modelOverrides_fieldNameRequired => 'Enter a field name';

  @override
  String get modelOverrides_duplicateField => 'Duplicate field name';

  @override
  String get modelOverrides_invalidJson => 'Enter a valid JSON value';

  @override
  String get modelOverrides_customBody => 'Custom body';

  @override
  String get modelOverrides_customHeaders => 'Custom headers';

  @override
  String get modelOverrides_fieldName => 'Field name';

  @override
  String get modelOverrides_headerName => 'Header name';

  @override
  String get modelOverrides_valueJson => 'Value (JSON)';

  @override
  String get modelOverrides_value => 'Value';

  @override
  String get modelOverrides_removeItem => 'Remove item';

  @override
  String get modelOverrides_body => 'Request body';

  @override
  String get modelOverrides_headers => 'Request headers';

  @override
  String modelOverrides_itemCount(Object count) {
    return '$count items';
  }

  @override
  String get modelOverrides_valueTypes =>
      'Supports strings, numbers, booleans, arrays and objects';

  @override
  String get modelOverrides_addBodyField => 'Add body field';

  @override
  String get modelOverrides_addHeader => 'Add header';

  @override
  String get promptTranslation_translating => 'Translating';

  @override
  String get promptTranslation_needsModel =>
      'Translate · configure a model first';

  @override
  String promptTranslation_withRoute(Object provider, Object model) {
    return 'Translate · $provider / $model';
  }

  @override
  String get promptTranslation_actions => 'Translation actions';

  @override
  String get promptTranslation_promptChanged =>
      'The prompt changed; new edits were not overwritten';

  @override
  String get promptTranslation_nothingToTranslate =>
      'There is no plain text to translate';

  @override
  String promptTranslation_failed(Object error) {
    return 'Translation failed: $error';
  }

  @override
  String get promptTranslation_setupTitle =>
      'Configure a translation model first';

  @override
  String get promptTranslation_setupBody =>
      'Translation needs an explicitly selected service and model. Go to Settings → Integrations → Models & APIs, add a service and fetch its model list, then choose a model for prompt translation.';

  @override
  String get promptTranslation_later => 'Later';

  @override
  String get promptTranslation_openSettings => 'Open settings';

  @override
  String get promptTranslation_toolTitle => 'Translate';

  @override
  String get promptTranslation_noModel => 'No model configured';

  @override
  String get promptTranslation_configureModel => 'Configure translation model';

  @override
  String get promptTranslation_translateNew => 'Translate new content';

  @override
  String get promptTranslation_undoRestore =>
      'Undo the restore and bring translation blocks back';

  @override
  String get promptTranslation_restoreAll =>
      'Restore all translation blocks to original text';

  @override
  String get promptTranslation_tutorial => 'How it works';

  @override
  String get promptTranslation_guideBack => 'Back to actions';

  @override
  String get promptTranslation_guideMiddleTitle => 'Middle-click a block';

  @override
  String get promptTranslation_guideMiddleText =>
      'Switch original and translation';

  @override
  String get promptTranslation_guideSourceTitle => 'Left-click the original';

  @override
  String get promptTranslation_guideSourceText =>
      'Place the cursor and edit directly';

  @override
  String get promptTranslation_guideReadingTitle =>
      'Left-click the translation';

  @override
  String get promptTranslation_guideReadingText => 'Open the block editor';

  @override
  String get promptTranslation_guideCtrlTitle => 'Ctrl + click / drag-select';

  @override
  String get promptTranslation_guideCtrlText =>
      'Search tags / find related tags in the editor';

  @override
  String get promptTranslation_guideConvertTitle => '↑ Translation to original';

  @override
  String get promptTranslation_guideConvertText =>
      '↓ Original to translation; review before saving';

  @override
  String get promptTranslation_guideRestoreTitle => 'A / Restore';

  @override
  String get promptTranslation_guideRestoreText =>
      'Restore the whole group / bring blocks back';

  @override
  String get promptTranslation_middleButton => 'Middle mouse button';

  @override
  String get promptTranslation_leftButton => 'Left mouse button';

  @override
  String get promptTranslation_blockShowingOriginal =>
      'Translation block, showing original';

  @override
  String get promptTranslation_blockShowingReading =>
      'Translation block, showing translation';

  @override
  String get promptTranslation_blockNeedsReview =>
      'Original changed · translation needs updating';

  @override
  String get promptTranslation_badgeTooltip =>
      'Original changed; translation needs syncing';

  @override
  String get promptTranslation_sourceChanged =>
      'The original changed; reopen the translation block';

  @override
  String promptTranslation_retranslateFailed(Object error) {
    return 'Retranslation failed: $error';
  }

  @override
  String get promptTranslation_draftChanged =>
      'Content changed; convert again. The new draft is kept.';

  @override
  String promptTranslation_convertFailed(Object error) {
    return 'Conversion failed; the draft is kept: $error';
  }

  @override
  String get promptTranslation_invalidResultFormat =>
      'The conversion result format is invalid; the draft is kept';

  @override
  String get promptTranslation_noValidText =>
      'The model returned no valid text; the draft is kept';

  @override
  String get promptTranslation_invalidResultContent =>
      'The conversion result contains invalid formatting; the draft is kept';

  @override
  String get promptTranslation_incompleteStructure =>
      'The conversion result has incomplete weights or groups; the draft is kept';

  @override
  String get promptTranslation_inputRequired =>
      'Enter the content to convert first';

  @override
  String get wiki_configureTagModel =>
      'Configure an available tag translation model in Models & APIs first.';

  @override
  String get blockOrganizer_barrierLabel => 'Block organizer';

  @override
  String get blockOrganizer_replaceTitle =>
      'Replace copies from the same source?';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return 'The target already has $count copies from the same source. After replacing, the source is hidden from the library; instances already inserted in prompts can still reference the original block.';
  }

  @override
  String blockOrganizer_replaceCopyBody(Object count) {
    return 'The target already has $count copies from the same source. Replacing updates the target copies; the source is kept.';
  }

  @override
  String get blockOrganizer_replace => 'Replace';

  @override
  String get blockOrganizer_customTagColor => 'Custom tag color';

  @override
  String get blockOrganizer_colorHint => '#RRGGBB or #AARRGGBB';

  @override
  String get blockOrganizer_invalidColor =>
      'Enter a 6- or 8-digit hexadecimal color';

  @override
  String blockOrganizer_deleteFolderConfirm(Object name) {
    return 'Delete “$name”? Its blocks will move to the root folder.';
  }

  @override
  String blockOrganizer_deleteCollectionConfirm(Object name) {
    return 'Delete “$name”? The blocks themselves are kept.';
  }

  @override
  String get blockOrganizer_titleFavorites => 'Favorites & collections';

  @override
  String get blockOrganizer_titleFolders => 'Choose a folder';

  @override
  String blockOrganizer_itemCount(Object count) {
    return '$count items';
  }

  @override
  String get blockOrganizer_search => 'Search';

  @override
  String get blockOrganizer_name => 'Name';

  @override
  String get blockOrganizer_customColor => 'Custom color…';

  @override
  String get blockOrganizer_newCollection => 'New collection';

  @override
  String get blockOrganizer_newCollectionFolder => 'New collection folder';

  @override
  String get blockOrganizer_newTag => 'New tag';

  @override
  String get blockOrganizer_newFolder => 'New folder';

  @override
  String get blockOrganizer_rootUncategorized => 'Root / Uncategorized';

  @override
  String get blockOrganizer_manageDrag => 'Manage; drag to reorder';

  @override
  String get blockLibrary_dragSelectedHint =>
      'Drag the selected blocks onto a favorite or folder on the left, then choose copy or move when you release.';

  @override
  String blockLibrary_blockCount(Object count) {
    return '$count blocks';
  }

  @override
  String get blockLibrary_changedSelectAgain =>
      'The block library changed. Select again and retry.';

  @override
  String get blockLibrary_hiddenSource => 'Hidden blocks cannot be organized';

  @override
  String get blockLibrary_sameSourceSelected =>
      'The selection contains copies from the same source; organize them separately';

  @override
  String get blockLibrary_sameSourceExists =>
      'Copies from the same source already exist; confirm replacement';

  @override
  String get blockLibrary_collectionMissing => 'The collection does not exist';

  @override
  String get promptBlockEditor_appearance => 'Block appearance';

  @override
  String get promptBlockEditor_imageUnreadable =>
      'Could not read the selected image';

  @override
  String get blockAppearance_classic => 'Classic';

  @override
  String get blockAppearance_stripes => 'Fine stripes';

  @override
  String get blockAppearance_dots => 'Dots';

  @override
  String get blockAppearance_solid => 'Solid';

  @override
  String get blockAppearance_gradient => 'Gradient';

  @override
  String get blockAppearance_translation => 'Translation';

  @override
  String get opusUsage_exhausted =>
      'Free account quota used up; V5 generation is billed in Anlas';

  @override
  String opusUsage_remaining(Object percent) {
    return 'Free account quota remaining: $percent%';
  }

  @override
  String opusUsage_recharging(Object time) {
    return 'Recharging: next +1% in $time';
  }

  @override
  String get opusUsage_notRecharging =>
      'Not recharging (the pool is above the threshold or used up)';

  @override
  String get opusUsage_clickToRefresh => 'Click to refresh';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes min';
  }

  @override
  String opusUsage_hours(Object hours) {
    return '$hours h';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String opusUsage_minutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String opusUsage_seconds(Object seconds) {
    return '$seconds s';
  }

  @override
  String get metadataImport_noCharactersReplaceClears =>
      'No character data; replace clears current characters';

  @override
  String get metadataImport_replaceCharacters => 'Replace characters';

  @override
  String get metadataImport_appendCharacters => 'Append characters';

  @override
  String get drop_dragToShare => 'Drag to share';

  @override
  String promptSyntax_weightTooLarge(Object value) {
    return 'Numeric weight is too large: $value::';
  }

  @override
  String promptSyntax_spaceBeforeColons(Object value) {
    return 'No space allowed between the weight and :: : $value ::';
  }

  @override
  String promptSyntax_weightAfterColons(Object value) {
    return 'Numeric weights go before :: : ::$value';
  }

  @override
  String get update_errorInAppUnsupported =>
      'This version does not support automatic in-app updates';

  @override
  String get update_errorNoInstallablePackage =>
      'No automatically installable update package was found';

  @override
  String get update_errorMissingSha256 =>
      'The update package is missing its SHA256 checksum';

  @override
  String get update_errorDiskFull =>
      'Not enough disk space to save the update package';

  @override
  String get update_errorWriteFailed => 'Failed to write the update package';

  @override
  String get update_errorDownloadFailed =>
      'Failed to download the update package';

  @override
  String get update_errorSizeMismatch => 'The update package size check failed';

  @override
  String get update_errorChecksumMismatch =>
      'The update package checksum failed';

  @override
  String get update_errorResumeRejected =>
      'The server rejected resuming the update download';

  @override
  String get update_errorEmptyResponse =>
      'The update server returned an empty response';

  @override
  String get update_errorPlatformUnsupported =>
      'In-app updates are not supported on this platform';

  @override
  String get update_errorPackageRemoved =>
      'The update package was cleaned up; download it again';

  @override
  String get update_errorPackageCorrupted =>
      'The update package is corrupted; download it again';

  @override
  String get update_errorLaunchFailed => 'Failed to start the updater';

  @override
  String get update_errorCheckFailed => 'Failed to check for updates';

  @override
  String get update_errorCheckUnknown =>
      'An unknown error occurred while checking for updates';

  @override
  String update_errorLogPath(Object path) {
    return 'Log: $path';
  }

  @override
  String get update_errorInstallFailed => 'Failed to install the update';

  @override
  String get update_errorInstallFailedSeeLog =>
      'Failed to install the update; see the update log';

  @override
  String get auth_tokenEmpty => 'The token is empty and cannot be verified';

  @override
  String get auth_tokenFormatInvalid => 'Invalid token format';

  @override
  String get auth_tokenInvalidOrExpired =>
      'The token is invalid or expired; check that it is correct. A persistent token starts with pst-.';

  @override
  String get auth_tokenMustStartPst =>
      'Invalid token format; it should start with pst-';

  @override
  String get auth_tokenFormatDetail =>
      'Invalid token format. A persistent token starts with pst- followed by at least 10 characters. Check the token you entered.';

  @override
  String get danbooru_credentialsExpired =>
      'Credentials expired; sign in again';

  @override
  String get danbooru_networkRetryLater =>
      'Network connection failed; it will retry when the network is back';

  @override
  String get danbooru_invalidCredentials =>
      'Could not verify the credentials; check the username and API key';

  @override
  String danbooru_verifyFailed(Object error) {
    return 'Verification failed: $error';
  }

  @override
  String get danbooru_credentialsRequired =>
      'Username and API key cannot be empty';

  @override
  String get danbooru_networkCheck =>
      'Network connection failed; check your connection';

  @override
  String get danbooru_loginFailedNetwork =>
      'Sign-in failed; check your network connection';

  @override
  String get danbooru_blacklistLoginRequired =>
      'Sign in to a Danbooru account first';

  @override
  String get danbooru_blacklistPushFailed =>
      'Failed to push the Danbooru blacklist';

  @override
  String danbooru_blacklistSyncFailed(Object error) {
    return 'Sync failed: $error';
  }

  @override
  String comfyui_submitFailed(Object detail) {
    return 'Failed to submit the workflow: $detail';
  }

  @override
  String comfyui_uploadFailed(Object detail) {
    return 'Failed to upload the image: $detail';
  }

  @override
  String comfyui_fetchImageFailed(Object detail) {
    return 'Failed to fetch the image: $detail';
  }

  @override
  String comfyui_historyMissing(Object id) {
    return 'Task history not found: $id';
  }

  @override
  String get comfyui_unknownError => 'Unknown error';

  @override
  String comfyui_cannotConnect(Object url) {
    return 'Cannot connect to the ComfyUI server ($url)';
  }

  @override
  String get comfyui_noOutput => 'The task produced no output';

  @override
  String comfyui_nodesNoImage(Object nodes) {
    return 'The specified output nodes produced no image: $nodes';
  }

  @override
  String get comfyui_noImageOutput => 'The task produced no image';

  @override
  String get comfyui_executionError => 'Execution error';

  @override
  String comfyui_missingNodes(Object nodes) {
    return 'Missing ComfyUI nodes: $nodes. Install or enable the custom nodes in ComfyUI, then restart ComfyUI.';
  }

  @override
  String get enhance_cannotReadSize => 'Could not read the image size';

  @override
  String enhance_upscaleFailed(Object error) {
    return 'Upscale failed: $error';
  }

  @override
  String enhance_vibeEncodeFailed(Object error) {
    return 'Vibe encoding failed: $error';
  }

  @override
  String enhance_enhanceFailed(Object error) {
    return 'Image enhancement failed: $error';
  }

  @override
  String enhance_annotateFailed(Object error) {
    return 'Image annotation failed: $error';
  }

  @override
  String get enhance_timeout => 'Request timed out';

  @override
  String get enhance_networkError => 'Network connection error';

  @override
  String enhance_serverError(Object status) {
    return 'Server returned an error: $status';
  }

  @override
  String enhance_serverErrorDetail(Object status, Object detail) {
    return 'Server returned an error: $status ($detail)';
  }

  @override
  String get proxy_connectTimeout => 'Connection timed out';

  @override
  String get proxy_cannotConnect => 'Cannot connect to the server';

  @override
  String get proxy_connectFailed => 'Connection failed';

  @override
  String get proxy_testServerUnreachable => 'Cannot connect to the test server';

  @override
  String proxy_testFailed(Object error) {
    return 'Test failed: $error';
  }

  @override
  String get avatar_noFilePath => 'Could not get the file path';

  @override
  String get avatar_sourceMissing =>
      'The source file does not exist or was deleted';

  @override
  String avatar_copyFailed(Object error) {
    return 'Could not copy the file: $error';
  }

  @override
  String avatar_saveFailed(Object error) {
    return 'Could not save the avatar: $error';
  }

  @override
  String avatar_operationFailed(Object error) {
    return 'Operation failed: $error';
  }

  @override
  String get vibeExport_rawImage => 'Original image';

  @override
  String get vibeExport_vibePreview => 'Vibe preview';

  @override
  String get vibeExport_libraryThumbnail => 'Library thumbnail';

  @override
  String get vibeExport_pngTitle => 'Export PNG Vibe image';

  @override
  String get vibeExport_pngDirectoryTitle => 'Choose a PNG export folder';

  @override
  String get vibeExport_fileTitle => 'Export Vibe file';

  @override
  String get vibeExport_bundleTitle => 'Export Vibe bundle';

  @override
  String get vibeExport_zipTitle => 'Export Vibe ZIP';

  @override
  String get vibeExport_nothingToExport => 'No Vibe entries to export';

  @override
  String get vibeImport_fileParseFailed => 'Failed to parse the file';

  @override
  String get vibeImport_importFiles => 'Importing files';

  @override
  String get vibeImport_noVibeData => 'The image contains no valid Vibe data';

  @override
  String get vibeImport_importImages => 'Importing images';

  @override
  String get vibeImport_encodingParseFailed => 'Failed to parse the encoding';

  @override
  String get vibeImport_importEncodings => 'Importing encodings';

  @override
  String vibeImport_namingCancelled(Object name) {
    return 'Naming cancelled; skipped: $name';
  }

  @override
  String vibeImport_nameEmpty(Object name) {
    return 'Name is empty; skipped: $name';
  }

  @override
  String vibeImport_nameConflict(Object name) {
    return 'Name conflict; skipped: $name';
  }

  @override
  String get vibeImport_saveFailed => 'Save failed';

  @override
  String vibeFile_missingRawImage(Object file) {
    return 'The file has no usable original image data: $file (type=image). It may be damaged or incomplete; delete it and save again.';
  }

  @override
  String get generation_countMustBePositive =>
      'Generation count must be greater than 0';

  @override
  String get generation_allTasksFailed => 'All generation tasks failed';

  @override
  String get generation_failedShort => 'Generation failed';

  @override
  String generation_tasksFailedAfterRetry(Object count) {
    return '$count tasks still failed after retrying';
  }

  @override
  String get generation_streamFallbackUnavailable =>
      'Streaming generation is unsupported and cannot fall back automatically (parameters were lost)';

  @override
  String generation_streamFallbackFailed(Object error) {
    return 'Falling back to non-streaming generation failed: $error';
  }

  @override
  String get generation_batchSizeMustBePositive =>
      'Batch count and batch size must be greater than 0';

  @override
  String get clipboard_unsupportedPlatform =>
      'The system clipboard is not supported on this platform';

  @override
  String get clipboard_decodeFailed =>
      'Could not decode the image to copy it to the clipboard';

  @override
  String drop_remoteImageTooLarge(Object size) {
    return 'The remote image download exceeds $size MB';
  }

  @override
  String get apiEndpoint_empty => 'API address cannot be empty';

  @override
  String get apiEndpoint_invalid => 'Invalid API address';

  @override
  String get apiEndpoint_httpOnly =>
      'Only http or https API addresses are supported';

  @override
  String get apiEndpoint_noExtras =>
      'The API address cannot contain query parameters, fragments or user info';

  @override
  String gallery_folderInaccessible(Object error) {
    return 'Cannot access the image folder: $error';
  }

  @override
  String gallery_scanFailed(Object error) {
    return 'Image scan failed: $error';
  }

  @override
  String gallery_galleryInitFailed(Object error) {
    return 'Gallery initialization failed: $error';
  }

  @override
  String vibeImport_imageProgress(Object current, Object total, Object source) {
    return 'Importing image ($current/$total): $source';
  }

  @override
  String get vibeImport_clipboardSource => 'Clipboard';

  @override
  String get resolution_noAdjustment => 'No adjustment needed';

  @override
  String get dataRefresh_updating => 'Updating data...';

  @override
  String dataRefresh_updatingService(Object service) {
    return 'Updating $service...';
  }

  @override
  String get imageUse_title => 'Use image';

  @override
  String get imageUse_importContent => 'Import content';

  @override
  String get imageUse_characters => 'Characters';

  @override
  String get imageUse_characterMode => 'Character handling';

  @override
  String get imageMenu_details => 'Details';

  @override
  String get imageMenu_creation => 'Create & reference';

  @override
  String get imageMenu_editAndDerive => 'Edit & derive';

  @override
  String get imageMenu_more => 'More actions';

  @override
  String get imageMenu_fileActions => 'File actions';

  @override
  String get imageMenu_saveToBlock => 'Save to blocks';

  @override
  String get settings_highAnlasCostEstimate => 'Estimated usage';

  @override
  String get settings_highAnlasCostThresholdLabel => 'Reminder threshold';

  @override
  String get settings_highAnlasCostQuestion => 'Continue with this generation?';

  @override
  String get bridge_title => 'Local bridge';

  @override
  String get bridge_agent => 'External Agent';

  @override
  String get bridge_agentHint =>
      'Copy the instructions to an Agent that can run local commands.';

  @override
  String get bridge_synced => 'Current content confirmed';

  @override
  String get bridge_changed => 'Content changed. Awaiting confirmation';

  @override
  String get bridge_waiting => 'Waiting for connection';

  @override
  String get bridge_ready => 'Waiting for activity';

  @override
  String bridge_clients(int count) {
    return '$count Agent(s) connected';
  }

  @override
  String bridge_activity(Object client, Object action) {
    return '$client: $action';
  }

  @override
  String get bridge_read => 'Reading parameters';

  @override
  String get bridge_write => 'Updating parameters';

  @override
  String get bridge_quote => 'Estimating cost';

  @override
  String get bridge_generate => 'Generating an image';

  @override
  String get bridge_cancel => 'Stopping generation';

  @override
  String get bridge_recent => 'Recent activity';

  @override
  String get bridge_empty => 'No activity yet';

  @override
  String get bridge_copyGuide => 'Copy connection instructions';

  @override
  String get bridge_showGuide => 'View instructions';

  @override
  String get bridge_copied => 'Instructions copied';

  @override
  String get bridge_disconnect => 'End Agent connections';

  @override
  String get bridge_settings => 'Bridge settings';

  @override
  String get bridge_clientMissing =>
      'The bundled client is unavailable. Update Studio.';

  @override
  String get bridge_conflict => 'Content changed. Read it again.';

  @override
  String get bridge_busy => 'Another operation is in progress';

  @override
  String get bridge_interrupted => 'Operation interrupted';

  @override
  String get bridge_failed => 'Operation failed. Check the Agent response.';

  @override
  String get bridge_timeout => 'Operation timed out. Retry.';

  @override
  String bridge_guide(Object clientPath) {
    return 'Use the local bridge to assist with W.O.F NAI Studio.\nClient: $clientPath\n\n1. Quote the path correctly for your shell. Run status --name <your-name> and verify success; copying these instructions does not connect.\n2. Run get --name <your-name> --out current.json. Editable original text is in _draft.fields; field_versions protect against concurrent edits. Other fields may include effective quality tags. Do not duplicate them into the original text.\n3. Change only user-authorized fields. Save a patch to changes.json, then run set-json changes.json --base current.json --name <your-name>. Studio backs up and rechecks the edited fields. On conflict, stop and read again; never automatically overwrite newer user edits. Verify readback. characters replaces the entire list: preserve unrelated names, enabled flags, positions, and IDs. Reference images are currently read-only.\n4. Connecting or editing does not authorize generation. Only after an explicit generation request, run quote --out quote.json --name <your-name> and report the estimated Anlas price and cached account balance; server billing is authoritative. After authorization and reporting, run gen --quote quote.json --authorized --name <your-name>. One image per request; a changed draft invalidates the quote.\n5. Each command disconnects when done. Krita can remain connected. Wait on busy and avoid immediate retry loops after errors. Stop generation in Studio, use Ctrl+C, or cancel <request_id> --name <same-name> using the returned request ID. Never print the discovery-file session secret.\n';
  }

  @override
  String get editor_drawMask => 'Draw Mask';

  @override
  String get editor_eraseMask => 'Erase Mask';

  @override
  String get editor_squareBrush => 'Square Brush';

  @override
  String get editor_focusedArea => 'Focused Area';

  @override
  String get editor_minimumContext => 'Minimum Context Area';

  @override
  String get editor_maskAppearance => 'Mask Appearance';

  @override
  String get editor_maskColor => 'Mask Color';

  @override
  String get editor_maskOpacity => 'Mask Opacity';

  @override
  String get editor_maskBorder => 'Border';

  @override
  String get editor_patternSolid => 'Solid';

  @override
  String get editor_patternLines => 'Lines';

  @override
  String get editor_patternCrosshatch => 'Crosshatch';

  @override
  String get editor_patternDots => 'Dots';

  @override
  String get editor_patternGrid => 'Grid';

  @override
  String get editor_patternChecker => 'Checker';

  @override
  String get editor_patternHearts => 'Hearts';

  @override
  String get editor_resize => 'Resize';

  @override
  String get editor_penSize => 'Pen Size';

  @override
  String get editor_sourceChanged =>
      'The source image changed while editing. Please reopen the editor.';

  @override
  String get editor_draw => 'Draw';

  @override
  String get editor_erase => 'Erase';

  @override
  String get editor_select => 'Select';

  @override
  String get editor_lasso => 'Lasso';

  @override
  String get editor_roundTip => 'Round';

  @override
  String get editor_softRoundTip => 'Soft Round';

  @override
  String get editor_squareTip => 'Square';

  @override
  String get editor_pressureSensitivity => 'Pressure Sensitivity';

  @override
  String get editor_hsvAdjustment => 'HSV Adjustment';

  @override
  String get editor_hue => 'Hue';

  @override
  String get editor_cloneSourceHint => 'Alt+Click to set source';

  @override
  String get editor_colorAlpha => 'Alpha';

  @override
  String get editor_colorHex => 'Color HEX';

  @override
  String get editor_closestValidSize => 'Crop to closest valid generation size';

  @override
  String get model3d_projection => 'Projection';

  @override
  String get model3d_perspective => 'Perspective';

  @override
  String get model3d_orthographic => 'Orthographic';

  @override
  String get model3d_fov => 'FOV';

  @override
  String get model3d_ambient => 'Ambient';

  @override
  String get model3d_direct => 'Direct';

  @override
  String get model3d_direction => 'Light Direction';

  @override
  String get model3d_front => 'Front';

  @override
  String get model3d_frontTop => 'Front-Top';

  @override
  String get model3d_top => 'Top';

  @override
  String get model3d_left => 'Left';

  @override
  String get model3d_right => 'Right';

  @override
  String get model3d_back => 'Back';

  @override
  String get model3d_shadows => 'Shadows';

  @override
  String get model3d_quality => 'Quality';

  @override
  String get model3d_veryLow => 'Very Low';

  @override
  String get model3d_low => 'Low';

  @override
  String get model3d_medium => 'Medium';

  @override
  String get model3d_high => 'High';

  @override
  String get model3d_veryHigh => 'Very High';

  @override
  String get model3d_display => 'Display';

  @override
  String get model3d_showBones => 'Show Bones';

  @override
  String get model3d_bones => 'Bone List';

  @override
  String get model3d_noBones => 'No bones found';

  @override
  String get model3d_morphs => 'Morph Targets';

  @override
  String get model3d_noMorphs => 'No morph targets found';

  @override
  String get model3d_settings => '3D Render Settings';

  @override
  String get model3d_resetModel => 'Reset model position';

  @override
  String get model3d_removeModel => 'Remove model';

  @override
  String get model3d_removeConfirm =>
      'Remove this model? Unsaved model edits will be lost.';

  @override
  String get model3d_toolTransform => 'Model\nTransform';

  @override
  String get model3d_toolPose => 'Model Pose';

  @override
  String get img2img_directorEmotionHint =>
      'Anime only. Start with a neutral emotion image.';

  @override
  String get img2img_emotionStrengthNormal => 'Normal';

  @override
  String get img2img_emotionStrengthSlightlyWeak => 'Slightly Weak';

  @override
  String get img2img_emotionStrengthWeak => 'Weak';

  @override
  String get img2img_emotionStrengthWeaker => 'Even Weaker';

  @override
  String get img2img_emotionStrengthVeryWeak => 'Very Weak';

  @override
  String get img2img_emotionStrengthWeakest => 'Weakest';

  @override
  String get img2img_directorWeaken => 'Weaken emotion';

  @override
  String get img2img_directorStrengthen => 'Strengthen emotion';

  @override
  String get img2img_emotionScared => 'Scared';

  @override
  String get img2img_emotionNervous => 'Nervous';

  @override
  String get img2img_emotionThinking => 'Thinking';

  @override
  String get img2img_emotionConfused => 'Confused';

  @override
  String get img2img_emotionBored => 'Bored';

  @override
  String get img2img_emotionIrritated => 'Irritated';

  @override
  String get img2img_emotionAroused => 'Aroused';

  @override
  String get img2img_emotionEmbarrassed => 'Embarrassed';

  @override
  String get img2img_emotionDetermined => 'Determined';

  @override
  String get img2img_emotionHurt => 'Hurt';
}
