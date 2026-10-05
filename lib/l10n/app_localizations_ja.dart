// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get app_title => 'W.O.F NAI Studio';

  @override
  String get settings_visualAssets => 'UI のフォントとライセンス';

  @override
  String get brand_entryTagline => '想像が、かたちになる場所。';

  @override
  String get brand_switchToLight => 'ライトモードに切り替え';

  @override
  String get brand_switchToDark => 'ダークモードに切り替え';

  @override
  String get app_subtitle => 'NovelAI サードパーティ クライアント';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get onlineFav_all => 'すべて';

  @override
  String get onlineFav_rootCollection => 'ルート';

  @override
  String get onlineFav_newCollection => '新しいコレクション';

  @override
  String get onlineFav_renameCollection => '名前を変更';

  @override
  String get onlineFav_deleteCollection => 'コレクションを削除';

  @override
  String get onlineFav_empty => 'お気に入りの作品はまだありません';

  @override
  String onlineFav_authorWorkCount(Object n) {
    return '$n 作品';
  }

  @override
  String get onlineFav_moveHere => 'ここに移動';

  @override
  String get onlineFav_removeFavorite => 'お気に入り解除';

  @override
  String get onlineFav_favoriteAuthor => '作者をお気に入り';

  @override
  String get onlineFav_unfavoriteAuthor => '作者のお気に入りを解除';

  @override
  String get onlineFav_authorFavorited => '作者をお気に入りに追加しました';

  @override
  String get onlineFav_authorUnfavorited => '作者のお気に入りを解除しました';

  @override
  String get common_confirm => '確認';

  @override
  String get common_continue => '続行';

  @override
  String get common_selectAll => 'すべて選択';

  @override
  String get common_deselectAll => 'すべての選択を解除';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '削除';

  @override
  String get common_edit => '編集';

  @override
  String get common_close => '閉じる';

  @override
  String get common_clear => 'クリア';

  @override
  String get common_copy => 'コピー';

  @override
  String get common_copied => 'コピーしました';

  @override
  String get common_export => 'エクスポート';

  @override
  String get common_import => 'インポート';

  @override
  String get common_loading => '読み込み中...';

  @override
  String get common_error => 'エラー';

  @override
  String get common_success => '成功';

  @override
  String get common_retry => '再試行';

  @override
  String get common_select => '選択してください';

  @override
  String get common_reset => 'リセット';

  @override
  String get common_add => '追加';

  @override
  String get common_added => '追加しました';

  @override
  String get common_new => '新規';

  @override
  String get common_confirmDelete => '削除の確認';

  @override
  String get common_confirmClear => 'クリアの確認';

  @override
  String get common_gotIt => 'わかりました';

  @override
  String common_deleteItemConfirm(Object itemName) {
    return '「$itemName」を削除しますか?この操作は元に戻すことができません。';
  }

  @override
  String common_clearAllItemsConfirm(Object count, Object itemType) {
    return '$count $itemType をすべてクリアしますか?この操作は元に戻すことができません。';
  }

  @override
  String get common_clearInputConfirm => '入力内容をクリアしますか?';

  @override
  String get common_yesterday => '昨日';

  @override
  String common_daysAgo(Object days) {
    return '$days 日前';
  }

  @override
  String get common_undo => '元に戻す';

  @override
  String get common_redo => 'やり直し';

  @override
  String get common_refresh => '更新';

  @override
  String get common_download => 'ダウンロード';

  @override
  String get common_apply => '適用する';

  @override
  String get common_move => '移動';

  @override
  String get common_favorite => 'お気に入り';

  @override
  String get common_unfavorite => 'お気に入りから削除';

  @override
  String get common_ok => 'OK';

  @override
  String get common_exit => '終了';

  @override
  String get common_folder => 'フォルダー';

  @override
  String get common_grid => 'グリッド';

  @override
  String get common_pack => 'パック';

  @override
  String get common_multiSelect => '複数選択';

  @override
  String get common_category => 'カテゴリ';

  @override
  String get common_categories => 'カテゴリ';

  @override
  String get networkError_connectionTimeout =>
      '接続がタイムアウトしました。ネットワーク接続を確認してください。';

  @override
  String get networkError_sendTimeout => '送信がタイムアウトしました。もう一度お試しください。';

  @override
  String get networkError_receiveTimeout =>
      '受信がタイムアウトしました。画像生成には時間がかかる場合があります。';

  @override
  String get networkError_requestCancelled => 'リクエストはキャンセルされました';

  @override
  String get networkError_connection => 'ネットワーク接続エラーです。接続を確認してください。';

  @override
  String get networkError_unknown => '不明なエラー';

  @override
  String get networkError_noResponse => 'サーバーから応答がありません';

  @override
  String get networkError_badRequest => 'リクエストパラメーターが無効です';

  @override
  String get networkError_authFailed => '認証に失敗しました。再度ログインしてください。';

  @override
  String get networkError_insufficientAnlas => 'Anlas が不足しています';

  @override
  String get networkError_forbidden => 'このリソースにアクセスする権限がありません';

  @override
  String get networkError_notFound => 'リクエストされたリソースが存在しません';

  @override
  String get networkError_conflict => 'リクエストが現在の状態と競合しています';

  @override
  String get networkError_rateLimited => 'リクエストが多すぎます。しばらくしてからもう一度お試しください。';

  @override
  String get networkError_serverInternal => 'サーバー内部エラー';

  @override
  String get networkError_badGateway => 'サーバーゲートウェイエラー';

  @override
  String get networkError_unavailable => 'サービスは一時的に利用できません';

  @override
  String networkError_requestFailed(int code) {
    return 'リクエストに失敗しました ($code)';
  }

  @override
  String get nav_canvas => 'キャンバス';

  @override
  String get nav_onlineGallery => 'オンライン ギャラリー';

  @override
  String get nav_expandSidebar => 'サイドバーを展開';

  @override
  String get nav_collapseSidebar => 'サイドバーを折りたたむ';

  @override
  String get auth_login => 'ログイン';

  @override
  String get auth_logout => 'ログアウト';

  @override
  String get auth_email => '電子メール';

  @override
  String get auth_password => 'パスワード';

  @override
  String get auth_loginButton => 'サインイン';

  @override
  String get auth_loginFailed => 'ログインに失敗しました';

  @override
  String get auth_guestEntry => 'ログインをスキップしてゲストとして続行';

  @override
  String get auth_recommended => '推奨';

  @override
  String get auth_getToken => 'トークンを取得';

  @override
  String get auth_localOnlyNote => 'アカウントとトークンはこの端末にのみ保存されます';

  @override
  String get auth_back => '戻る';

  @override
  String get auth_toggleVisibility => '表示 / 非表示';

  @override
  String get auth_emailRequired => 'メールアドレスを入力してください';

  @override
  String get auth_emailInvalid => '有効な電子メール アドレスを入力してください';

  @override
  String get auth_passwordRequired => 'パスワードを入力してください';

  @override
  String get auth_tokenLogin => 'API トークンのログイン';

  @override
  String get auth_tokenLoginRecommended => 'API トークンのログイン（推奨）';

  @override
  String get auth_credentialsLogin => '電子メールとパスワード';

  @override
  String get auth_credentialsLoginUnavailable =>
      'メールアドレス/パスワードでのログインは現在利用できません。Token ログインを使用してください。';

  @override
  String get auth_tokenRequired => 'トークンを入力してください';

  @override
  String get auth_tokenInvalid => '無効なトークン形式です。pst- で始まる必要があります。';

  @override
  String get auth_nicknameHint => 'このアカウントに認識可能な名前を設定します';

  @override
  String get auth_thirdPartyLogin => 'サードパーティサイト';

  @override
  String get auth_thirdPartyApiSite => 'サードパーティ API サイト';

  @override
  String get auth_imageApiSiteOptional => '画像 API サイト (オプション)';

  @override
  String get auth_imageApiSiteHint => '同じサードパーティ API サイトを使用する場合は空のままにしてください';

  @override
  String get auth_thirdPartyNicknameHint => '例: 自己ホスト型サイト / ミラー サイト';

  @override
  String get auth_thirdPartyTokenHint => 'サードパーティ サイトから API トークンを入力してください';

  @override
  String get auth_thirdPartyCompatibilityHint =>
      'サードパーティ サイトは、NovelAI サブスクリプション API およびイメージ生成 API と互換性がある必要があります。トークンはベアラー トークンとして送信されます。';

  @override
  String get auth_thirdPartyApiSiteRequired => 'サードパーティ API サイトの URL を入力してください';

  @override
  String get auth_validateAndLogin => '検証してログイン';

  @override
  String get auth_tokenGuide => 'NovelAI 設定からトークンを取得します';

  @override
  String get auth_addAccount => 'アカウントを追加';

  @override
  String get auth_tokenNotFound => 'このアカウントのトークンが見つかりません';

  @override
  String get auth_switchAccount => 'アカウントを切り替える';

  @override
  String get auth_currentAccount => '現在のアカウント';

  @override
  String get auth_selectAccount => 'アカウントを選択してください';

  @override
  String get auth_deleteAccount => 'アカウントを削除';

  @override
  String auth_deleteAccountConfirm(Object name) {
    return '「$name」を削除してもよろしいですか?これを元に戻すことはできません。';
  }

  @override
  String auth_deleteCurrentAccountConfirm(Object name) {
    return '「$name」を削除してログアウトしますか?';
  }

  @override
  String get auth_switchFailedDeletePrompt =>
      'このアカウントにログインできませんでした（無効の可能性）。一覧から削除しますか?';

  @override
  String get auth_switchFailedDeletePromptMissingToken =>
      'このアカウントのログイン情報が見つかりません。一覧から削除しますか?';

  @override
  String get auth_removeAvatar => 'アバターを削除';

  @override
  String get auth_quickLogin => 'クイックログイン';

  @override
  String get auth_nicknameRequired => 'ニックネームを入力してください';

  @override
  String get auth_error_networkTimeout => '接続タイムアウト';

  @override
  String get auth_error_networkError => 'ネットワークエラー';

  @override
  String get auth_error_authFailed => '認証に失敗しました';

  @override
  String get auth_error_credentialsLoginUnavailable =>
      'メールアドレス/パスワードでのログインは現在利用できません';

  @override
  String get auth_error_credentialsLoginUnavailable_hint =>
      'NovelAI ではメールアドレス/パスワードログインに Web の安全確認が必要になりました。代わりに Persistent API Token を使用してください。';

  @override
  String get auth_error_serverError => 'サーバーエラー';

  @override
  String get auth_error_unknown => '不明なエラー';

  @override
  String get auth_autoLogin => '自動ログイン';

  @override
  String get auth_forgotPassword => 'パスワードをお忘れですか?';

  @override
  String get auth_passwordTooShort => 'パスワードは 6 文字以上である必要があります';

  @override
  String get auth_loggingIn => 'ログイン中...';

  @override
  String get auth_viewTroubleshootingTips => 'トラブルシューティングのヒントを表示';

  @override
  String get auth_troubleshoot_checkConnection_title => 'ネットワーク接続を確認してください';

  @override
  String get auth_troubleshoot_checkConnection_desc =>
      'デバイスがインターネットに接続されていることを確認してください';

  @override
  String get auth_troubleshoot_retry_title => 'もう一度試してください';

  @override
  String get auth_troubleshoot_retry_desc =>
      'ネットワークの問題は一時的なものである可能性があります。再試行してください。';

  @override
  String get auth_troubleshoot_proxy_title => 'プロキシ設定を確認してください';

  @override
  String get auth_troubleshoot_proxy_desc =>
      'プロキシを使用している場合は、正しく構成されていることを確認してください';

  @override
  String get auth_troubleshoot_firewall_title => 'ファイアウォール設定を確認してください';

  @override
  String get auth_troubleshoot_firewall_desc =>
      'ファイアウォールで NovelAI サーバーへの接続が許可されていることを確認してください';

  @override
  String get auth_troubleshoot_serverStatus_title => 'サーバーのステータスを確認してください';

  @override
  String get auth_troubleshoot_serverStatus_desc =>
      'NovelAI ステータス ページまたはコミュニティにアクセスして、停止を確認してください';

  @override
  String get common_paste => '貼り付け';

  @override
  String get common_default => 'デフォルト';

  @override
  String get settings_title => '設定';

  @override
  String get settings_account => 'アカウント';

  @override
  String get settings_savedAccounts => '保存済みアカウント';

  @override
  String get settings_style => 'スタイル';

  @override
  String get settings_font => 'フォント';

  @override
  String get settings_language => '言語';

  @override
  String get settings_shortcuts => 'ショートカット';

  @override
  String get settings_generationInputSection => '入力';

  @override
  String get settings_generationFeedbackSection => '完了通知';

  @override
  String get settings_selectFont => 'フォントの選択';

  @override
  String get settings_selectLanguage => '言語の選択';

  @override
  String settings_loadFailed(Object error) {
    return 'ロードに失敗しました: $error';
  }

  @override
  String get settings_imageSavePath => '画像の保存場所';

  @override
  String get settings_autoSave => '自動保存';

  @override
  String get settings_autoSaveSubtitle => '生成後に画像を自動的に保存します';

  @override
  String get settings_extraRootsTitle => 'ギャラリーソース';

  @override
  String get settings_extraRootsHint =>
      '追加のギャラリーソースは閲覧・検索でき、画像をカテゴリへ移動/コピーできます（自動保存の対象外）。追加後すぐにスキャンします。';

  @override
  String get settings_extraRootsEmpty => '追加のギャラリーソースはありません';

  @override
  String get settings_extraRootsAdd => 'フォルダを追加';

  @override
  String get settings_extraRootsAddTitle => 'ギャラリーソースとして追加するフォルダを選択';

  @override
  String get settings_extraRootsRemove => 'このギャラリーソースを削除';

  @override
  String get settings_extraRootsRemoveConfirmTitle => 'ギャラリーソースを削除しますか？';

  @override
  String settings_extraRootsRemoveConfirmContent(String path) {
    return '「$path」をギャラリーから削除します（フォルダ内のファイルは削除されません）。';
  }

  @override
  String get settings_extraRootsAdded => 'ギャラリーソースを追加してスキャンしました';

  @override
  String get settings_extraRootsScanFailed =>
      'フォルダを追加しましたが、スキャンが完了しませんでした。ギャラリーを更新して再試行してください';

  @override
  String get settings_extraRootsWaitingScan =>
      'ギャラリーをスキャン中です。完了後にこのフォルダをインポートします';

  @override
  String get settings_extraRootsRemoved => 'ギャラリーソースを削除しました';

  @override
  String get settings_extraRootsDuplicate => 'このフォルダはすでにギャラリーソースです';

  @override
  String get settings_extraRootsSameAsMain => 'このフォルダは画像保存先と同じです';

  @override
  String get settings_extraRootsNested =>
      'ギャラリーソース同士を互いに含めることはできません。別のフォルダを選択してください';

  @override
  String get settings_extraRootsNotFound => '選択したフォルダが存在しません';

  @override
  String get settings_importTagIndex => 'タグ索引をインポート…';

  @override
  String get settings_importTagIndexPickTitle => 'タグ索引ファイルを選択 (.jsonl)';

  @override
  String settings_importTagIndexProgress(int processed, int total) {
    return '$processed/$total 行をインポート中…';
  }

  @override
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  ) {
    return 'インポート完了: 新規 $imported、更新 $updated、スキップ $skipped、エラー $errors';
  }

  @override
  String get settings_importTagIndexFailed => 'タグ索引のインポートに失敗しました';

  @override
  String get settings_importTagIndexBlockedByScan =>
      'ギャラリーのスキャン中です。スキャン完了後にタグインデックスをインポートしてください';

  @override
  String get settings_extraRootsIndexImportTitle => 'タグ索引を検出';

  @override
  String settings_extraRootsIndexImportContent(String path) {
    return '「$path」にタグ索引 index.jsonl を検出しました。先にインポートすると、以降のスキャンがメタデータ解析をスキップして高速化されます。今すぐインポートしますか？';
  }

  @override
  String get settings_extraRootsIndexImportConfirm => '今すぐインポート';

  @override
  String settings_version(Object version) {
    return 'バージョン $version';
  }

  @override
  String get settings_openSource => 'オープンソース';

  @override
  String get settings_openSourceSubtitle => 'ソース コードとドキュメントを表示する';

  @override
  String get settings_fileLogging => 'アプリケーション ログを記録する';

  @override
  String get settings_fileLoggingSubtitle =>
      'デフォルトではオフ。トラブルシューティングの場合にのみ有効にします。有効にすると、ログはDocuments/NAI_Launcher/logsに書き込まれます。無効にすると、ログ ファイルは作成または書き込まれなくなります。';

  @override
  String get settings_pathReset => 'デフォルトの場所にリセット';

  @override
  String get settings_pathSaved => '保存場所が更新されました';

  @override
  String get settings_selectFolder => '保存フォルダーを選択してください';

  @override
  String get settings_vibeLibraryPath => 'バイブライブラリパス';

  @override
  String get settings_hiveStoragePath => 'データ ストレージ パス';

  @override
  String get settings_selectVibeLibraryFolder => 'バイブライブラリフォルダーを選択してください';

  @override
  String get settings_selectHiveFolder => 'データ保存フォルダーの選択';

  @override
  String get settings_pathSavedRestartRequired =>
      'パスが更新されました。変更を適用するには再起動してください';

  @override
  String get settings_accountType => 'アカウントの種類';

  @override
  String get settings_subscriptionExpiry => 'サブスク期限';

  @override
  String get settings_thirdPartyApiAccount => 'サードパーティのサイト API';

  @override
  String get settings_goToLogin => 'ログインに移動';

  @override
  String get settings_changeAvatar => 'アバターの変更';

  @override
  String get settings_removeAvatar => 'アバターを削除';

  @override
  String get settings_accountEmail => 'アカウントのメールアドレス';

  @override
  String get settings_emailAccount => '電子メール アカウント';

  @override
  String get settings_tokenAccount => 'トークンアカウント';

  @override
  String get settings_setAsDefault => 'デフォルトとして設定';

  @override
  String get settings_defaultAccount => 'デフォルト';

  @override
  String get settings_nickname => 'ニックネーム';

  @override
  String get settings_nicknameUpdated => 'ニックネームが更新されました';

  @override
  String get settings_avatarUpdated => 'アバターが更新されました';

  @override
  String get settings_avatarRemoved => 'アバターが削除されました';

  @override
  String get settings_setAsDefaultSuccess => 'デフォルトのアカウントとして設定';

  @override
  String get generation_title => '生成';

  @override
  String get generation_generate => '生成';

  @override
  String generation_cooldownRemaining(Object seconds) {
    return 'あと$seconds秒';
  }

  @override
  String get generation_generating => '生成中...';

  @override
  String get generation_cancelGeneration => '生成のキャンセル';

  @override
  String get generation_stopGeneration => '生成を停止';

  @override
  String get generation_pleaseInputPrompt => 'プロンプトを入力してください';

  @override
  String get generation_generationFailed => '生成に失敗しました';

  @override
  String generation_progress(Object progress) {
    return '生成中...$progress%';
  }

  @override
  String get generation_lockHistoryScroll => '履歴スクロールをロック';

  @override
  String get generation_unlockHistoryScroll => '履歴スクロールのロックを解除';

  @override
  String get generation_downloadAllImages => 'すべての画像をダウンロード';

  @override
  String get generation_selectMultiple => '複数選択';

  @override
  String get generation_deselectAll => '選択を解除';

  @override
  String generation_deleteSelectedImages(int count) {
    return '選択した画像を削除 ($count)';
  }

  @override
  String get generation_deleteSelectedImagesTitle => '選択した画像を削除';

  @override
  String generation_deleteSelectedImagesConfirm(int count) {
    return 'レコードから $count 枚の画像を削除します（ディスクに保存されたファイルは保持されます）';
  }

  @override
  String generation_seedWrittenBack(int seed) {
    return 'シードを書き戻しました: $seed';
  }

  @override
  String get generation_setAsReferenceImage => '参照画像に設定しました';

  @override
  String get generation_canvasDisplaySettings => 'キャンバス表示';

  @override
  String get generation_canvasZoomToFill => 'ズームしてフィル（100%超を許可）';

  @override
  String get generation_canvasEmpty => 'キャンバスは空です';

  @override
  String get generation_canvasBackground => '透明部分の背景';

  @override
  String get generation_canvasBackgroundChecker => '市松模様';

  @override
  String get generation_canvasBackgroundCheckerLight => '明るい市松模様';

  @override
  String get generation_canvasBackgroundCheckerDark => '暗い市松模様';

  @override
  String get generation_canvasBackgroundNone => '背景なし';

  @override
  String get generation_canvasBackgroundBlack => '黒';

  @override
  String get generation_canvasBackgroundWhite => '白';

  @override
  String get generation_canvasBackgroundGray => 'グレー';

  @override
  String get generation_canvasBackgroundRed => '赤';

  @override
  String get generation_canvasBackgroundGreen => '緑';

  @override
  String get generation_canvasBackgroundBlue => '青';

  @override
  String get generation_canvasBackgroundCustom => 'カスタムカラー';

  @override
  String get generation_canvasSetInitImage => '画像から生成の元画像に設定';

  @override
  String get generation_canvasSendToTools => '画像ツールに送る';

  @override
  String get generation_canvasPinImage => '画像を固定';

  @override
  String get generation_canvasUnpinImage => '固定を解除';

  @override
  String get generation_canvasUseSeed => 'クリックしてこのシードを再利用';

  @override
  String generation_canvasPinnedCount(int count) {
    return '固定 $count';
  }

  @override
  String get generation_params => 'パラメータ';

  @override
  String get generation_paramsSettings => 'パラメータ設定';

  @override
  String get generation_history => '履歴';

  @override
  String get generation_historyRecord => '履歴レコード';

  @override
  String get generation_failedStreamSnapshot => 'スナップショットが失敗しました';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成が完了しませんでした。最後のプレビュー フレームのみが保持されます。保存したり、お気に入りに登録したり、画像ワークフローに使用したりすることはできません。';

  @override
  String get generation_noHistory => '履歴レコードがありません';

  @override
  String get generation_clearHistory => '履歴をクリア';

  @override
  String get generation_clearHistoryConfirm =>
      'すべての履歴レコードをクリアしてもよろしいですか?この操作は元に戻すことができません。';

  @override
  String get generation_model => 'モデル';

  @override
  String get generation_imageSize => '画像サイズ';

  @override
  String get generation_sampler => 'サンプラー';

  @override
  String generation_steps(Object steps) {
    return 'ステップ: $steps';
  }

  @override
  String get generation_stepsLabel => 'ステップ';

  @override
  String get generation_guidance => 'ガイダンス';

  @override
  String generation_cfgScale(Object scale) {
    return 'プロンプトガイダンス: $scale';
  }

  @override
  String get generation_seed => 'シード';

  @override
  String get generation_seedRandom => 'ランダム';

  @override
  String get generation_samplerRecommended => 'おすすめ';

  @override
  String get generation_samplerOther => 'その他';

  @override
  String get generation_advancedOptions => '詳細オプション';

  @override
  String get generation_smea => 'SMEA';

  @override
  String get generation_smeaSubtitle => '大きな画像の生成品質を向上させます';

  @override
  String get generation_smeaDyn => 'SMEA DYN';

  @override
  String get generation_smeaDescription =>
      '特定の画像サイズを超えると、高解像度サンプラーが自動的に使用されます。';

  @override
  String generation_cfgRescale(Object value) {
    return 'プロンプトガイダンスリスケール: $value';
  }

  @override
  String get generation_noiseSchedule => 'ノイズスケジュール';

  @override
  String get generation_modelGroupNew => '新着';

  @override
  String get generation_modelGroupLegacy => 'レガシー';

  @override
  String get generation_modelDesc_v5Curated =>
      '画像の厳選サブセットで学習した最新モデル。ストリーミングにおすすめです。';

  @override
  String get generation_modelDesc_v5Full => '最新かつ最高のモデルです。';

  @override
  String get generation_modelDesc_v45Curated =>
      '厳選画像サブセットで学習した V4.5 モデル。現在は非推奨です。';

  @override
  String get generation_modelDesc_v45Full => 'V4.5 フルモデルです。';

  @override
  String get generation_modelDesc_v4Curated => '厳選画像サブセットで学習した V4 モデルです。';

  @override
  String get generation_modelDesc_v4Full => 'V4 フルモデルです。';

  @override
  String get generation_sectionCharacters => 'キャラクタープロンプト';

  @override
  String get generation_sectionCharactersSub => 'シーン内のキャラクターに個別のプロンプトを作成します。';

  @override
  String get character_positionLabel => '位置';

  @override
  String get generation_sectionReferenceImages => '参照画像';

  @override
  String get generation_sectionImageSettings => '画像設定';

  @override
  String get anlas_subscription => 'サブスク';

  @override
  String get anlas_purchased => '購入済み';

  @override
  String get prompt_positive => 'プロンプト';

  @override
  String get prompt_baseTab => 'ベースプロンプト';

  @override
  String get prompt_negativeTab => '除外したい要素';

  @override
  String get prompt_transparentBg => '透明背景';

  @override
  String get prompt_chunksMenu => 'ツールとスイッチ';

  @override
  String get qualityTags_presetChip => '品質タグ';

  @override
  String get ucPreset_presetChip => '除外したい要素プリセット';

  @override
  String get prompt_positivePrompt => 'プロンプト';

  @override
  String get prompt_negativePrompt => '除外したい要素';

  @override
  String get prompt_mainPositive => 'メイン プロンプト (正)';

  @override
  String get prompt_mainNegative => 'メインプロンプト (除外したい要素)';

  @override
  String get prompt_characterPrompts => '複数キャラクターのプロンプト';

  @override
  String get prompt_finalPrompt => '最終的な有効なプロンプト';

  @override
  String get prompt_finalNegative => '最終有効な除外したい要素';

  @override
  String prompt_importedCharacters(int count) {
    return '$count キャラクターをインポートしました';
  }

  @override
  String get prompt_characterPromptReplaced => 'キャラクタープロンプトを置き換えました';

  @override
  String prompt_characterPromptAppended(Object count) {
    return 'キャラクタープロンプトを追加しました ($count キャラクター)';
  }

  @override
  String prompt_smartDecomposedWithCharacters(Object count) {
    return 'メインプロンプト + $count キャラクターに分解';
  }

  @override
  String get prompt_appliedToMainPrompt => 'メイン プロンプトに適用されます';

  @override
  String get prompt_searchHint => '検索プロンプト';

  @override
  String prompt_searchMatchCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get prompt_searchPrevious => '前の一致';

  @override
  String get prompt_searchNext => '次の一致';

  @override
  String get prompt_searchClose => '検索を閉じる';

  @override
  String get prompt_replaceHint => '置換後の文字列';

  @override
  String get prompt_replaceToggle => '置換欄の表示切り替え';

  @override
  String get prompt_replaceCurrent => '現在の一致を置換（Enter）';

  @override
  String get prompt_replaceAll => 'すべて置換（Ctrl+Enter）';

  @override
  String prompt_replaceAllDone(Object count) {
    return '$count 件を置換しました';
  }

  @override
  String get kritaBridge_busyGenerating =>
      'Krita Bridge で生成中です。現在のタスクが完了するまで待ってください。';

  @override
  String get prompt_unwantedContent => '画像に含めたくないコンテンツ...';

  @override
  String get prompt_autoFormat => '自動フォーマット';

  @override
  String get prompt_autoFormatSubtitle => 'カンマと空白を整え、不要な1倍の重み記号を削除します';

  @override
  String get prompt_highlightEmphasis => 'ハイライトの強調';

  @override
  String get prompt_highlightEmphasisSubtitle => '括弧と重みの構文を強調表示します';

  @override
  String get prompt_sdSyntaxAutoConvert => 'SD 構文自動変換';

  @override
  String get prompt_sdSyntaxAutoConvertSubtitle =>
      'フォーカスが外れたとき、または生成時に SD の重み構文を NAI 形式に変換します';

  @override
  String get prompt_cooccurrenceRecommendation => 'タグ拡張';

  @override
  String get prompt_cooccurrenceRecommendationSubtitle =>
      'Ctrl+クリックでローカル検索、Ctrl+ドラッグで関連タグを表示';

  @override
  String get prompt_formatted => 'フォーマット済み';

  @override
  String get image_save => '保存';

  @override
  String get image_copy => 'コピー';

  @override
  String get image_upscale => '拡大';

  @override
  String get image_saveToLibrary => 'ライブラリに保存';

  @override
  String image_imageSaved(Object path) {
    return '画像は次の場所に保存されました: $path';
  }

  @override
  String image_saveFailed(Object error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get image_copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String image_copyFailed(Object error) {
    return 'コピーに失敗しました: $error';
  }

  @override
  String get img2img_title => 'Image2Image';

  @override
  String get img2img_subtitle => '元画像からバリエーションを生成';

  @override
  String get img2img_enabled => '有効';

  @override
  String get img2img_sourceImage => 'ソース画像';

  @override
  String get img2img_strength => '強度';

  @override
  String get img2img_strengthHint => '値が高いほど、元画像との差が大きくなります';

  @override
  String get img2img_noise => 'ノイズ';

  @override
  String get img2img_noiseHint => 'ノイズを追加してバリエーションを増やします';

  @override
  String get img2img_clearSettings => 'Image2Image 設定をクリア';

  @override
  String get img2img_changeImage => '画像の変更';

  @override
  String get img2img_removeImage => '画像を削除';

  @override
  String img2img_selectFailed(Object error) {
    return '画像の選択に失敗しました: $error';
  }

  @override
  String get img2img_editImage => '画像を編集';

  @override
  String get img2img_editApplied => '編集された画像が新しいソース画像になりました';

  @override
  String get img2img_uploadImage => '画像をアップロード';

  @override
  String get img2img_dropToAdd => 'ドロップして元画像に設定';

  @override
  String get img2img_moreActions => 'その他の操作';

  @override
  String get img2img_drawSketch => 'スケッチを描く';

  @override
  String get img2img_inpaint => 'インペイント';

  @override
  String get img2img_inpaintStrength => 'インペイント強度';

  @override
  String get img2img_inpaintStrengthHint =>
      '値を高くすると、マスクされた領域が現在のソース イメージからさらに離れます。';

  @override
  String get img2img_inpaintPendingHint =>
      '「インペイント」をクリックしてキャンバスを開き、ブラシ、消しゴム、選択ツールで再描画したい領域を指定します。その後ここに戻り、メインの生成ボタンを使用します。';

  @override
  String get img2img_inpaintReadyHint =>
      'マスクを読み込みました。次回の生成では、マスクされた領域のみを再描画します。';

  @override
  String get img2img_inpaintMaskReady => 'インペイントマスクの準備ができました';

  @override
  String get img2img_generateVariations => 'バリエーションの生成';

  @override
  String get img2img_directorTools => 'ディレクターツール';

  @override
  String get img2img_directorPrompt => '追加のプロンプト';

  @override
  String get img2img_directorPromptHint => 'ターゲットの感情や色の方向など、必要に応じてガイダンスを追加します';

  @override
  String get img2img_directorRunning => '処理中...';

  @override
  String get img2img_directorResult => '結果';

  @override
  String get img2img_directorApplied => 'ディレクターツールの結果を新しいソース イメージとして適用しました';

  @override
  String get img2img_directorDefry => 'デフライ';

  @override
  String get img2img_directorEmotionLevel => '感情レベル';

  @override
  String get img2img_directorApplyAsSource => 'ソースとして使用';

  @override
  String get img2img_directorSourceImage => 'ソース画像';

  @override
  String get img2img_variationsStarted => 'バリエーションを生成しています...';

  @override
  String get img2img_directorRemoveBackground => '背景の除去';

  @override
  String get img2img_directorLineArt => '線画';

  @override
  String get img2img_directorSketch => 'スケッチ';

  @override
  String get img2img_directorColorize => 'カラー化';

  @override
  String get img2img_directorEmotion => '感情';

  @override
  String get img2img_directorDeclutter => 'デクラッター';

  @override
  String get img2img_enhance => '品質向上';

  @override
  String get img2img_enhanceMagnitude => '大きさ';

  @override
  String get img2img_enhanceUpscaleAmount => '画像の拡大率';

  @override
  String get img2img_enhanceMax => 'Max✨';

  @override
  String get img2img_novelAiCloudUpscale => 'NovelAI クラウド拡大（2x 固定）';

  @override
  String get img2img_cloudUpscaleSizeLimit =>
      'NovelAI クラウド拡大は 3MP 以下の入力画像に対応しています。';

  @override
  String get img2img_comfyuiEnableHint =>
      'まず、[設定] > [ComfyUI] で ComfyUI を有効にして接続します。';

  @override
  String get img2img_upscaleMode => '拡大モード';

  @override
  String get img2img_upscaleRegularModel => 'レギュラーモデル';

  @override
  String get img2img_upscaleModel => '拡大モデル';

  @override
  String get img2img_noSeedvr2Models =>
      'SeedVR2 モデルが見つかりません。モデル リストを更新するか、SeedVR2 ノード/モデル ファイルを確認してください。';

  @override
  String get img2img_noRegularUpscaleModels =>
      '通常の拡大モデルが見つかりません。モデルリストを更新するか、models/upscale_models を確認してください。';

  @override
  String get img2img_useSeedvr2TiledWorkflow =>
      'SeedVR2TilingUpscaler のタイル状の拡大ワークフローを使用します。';

  @override
  String get img2img_useSeedvr2Workflow => 'SeedVR2VideoUpscaler ワークフローの使用。';

  @override
  String get img2img_useRegularUpscaleWorkflow =>
      'UpscaleModelLoader + ImageUpscaleWithModel を使用し、Lanczos でターゲット スケールに修正します。';

  @override
  String get img2img_useRtxUpscaleWorkflow =>
      'RTX ビデオ超解像度を使用します。モデルの選択は必要ありません。';

  @override
  String get img2img_refreshModelList => 'モデルリストを更新';

  @override
  String get img2img_startUpscale => '拡大を開始';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 拡大が完了しました';

  @override
  String img2img_upscaleComplete(Object width, Object height) {
    return '拡大が完了しました (${width}x$height)';
  }

  @override
  String img2img_regularUpscaleComplete(Object width, Object height) {
    return '通常モデルの拡大が完了しました (${width}x$height)';
  }

  @override
  String img2img_rtxUpscaleComplete(Object width, Object height) {
    return 'RTX 拡大が完了しました (${width}x$height)';
  }

  @override
  String get img2img_noAvailableSeedvr2Model => '利用可能な SeedVR2 モデルが選択されていません';

  @override
  String get img2img_noAvailableRegularUpscaleModel =>
      '利用可能な通常の拡大モデルが選択されていません';

  @override
  String get img2img_decodeSourceFailed => 'ソース画像のデコードに失敗しました';

  @override
  String get img2img_metricSpeed => '速度';

  @override
  String get img2img_metricVram => 'VRAM';

  @override
  String get img2img_metricQuality => '品質';

  @override
  String get img2img_seedvr2VaeTileHint =>
      'SeedVR2 VAE MODEL のエンコード/デコード タイル サイズも書き込みます。';

  @override
  String get img2img_seedvr2UseTiledUpscale => 'タイル状の拡大を使用する';

  @override
  String get img2img_seedvr2UseTiledUpscaleHint =>
      '有効にすると、SeedVR2TilingUpscaler が使用されます。大きな画像や VRAM 負荷が高い場合に推奨します。';

  @override
  String get img2img_seedvr2TileSize => 'タイルのサイズ';

  @override
  String get img2img_seedvr2TileSizeHint =>
      'SeedVR2TilingUpscaler tile_width / tile_height も制御します。';

  @override
  String get img2img_seedvr2BlocksToSwap => 'メモリへ退避するブロック数';

  @override
  String get img2img_seedvr2BlocksToSwapHint =>
      'DiT ブロックのうち何個をシステムメモリに置き、推論時に VRAM へ順次転送するかを指定します。大きいほど VRAM を節約できますがメモリを消費し遅くなります。VRAM に余裕がある場合は 0 まで下げられます。メモリ不足エラーが出る場合は上げてください。';

  @override
  String get img2img_upscalePanelOpened => 'Image2Image の拡大パネルを開きました';

  @override
  String get editor_done => '完了';

  @override
  String get editor_tolerance => '許容差';

  @override
  String get editor_intensity => '強度';

  @override
  String get editor_sourcePoint => 'Alt+クリックしてソースポイントを設定します';

  @override
  String get editor_brushPresets => 'ブラシ プリセット';

  @override
  String get editor_size => 'サイズ';

  @override
  String get editor_opacity => '不透明度';

  @override
  String get editor_hardness => '硬度';

  @override
  String get editor_undo => '元に戻す';

  @override
  String get editor_redo => 'やり直し';

  @override
  String get editor_clearLayer => 'クリアレイヤー';

  @override
  String get editor_resetView => 'ビューをリセット';

  @override
  String get editor_zoom => 'ズーム';

  @override
  String get editor_toolBrush => 'ブラシ';

  @override
  String get editor_toolEraser => '消しゴム';

  @override
  String get editor_toolFill => '塗りつぶし';

  @override
  String get editor_toolMagicWand => 'マジックワンド';

  @override
  String get editor_magicWandMode => '選択方法';

  @override
  String get editor_magicWandSmartObject => 'スマートオブジェクト（EfficientViT）';

  @override
  String get editor_magicWandColorArea => '色領域（塗りつぶし）';

  @override
  String get editor_magicWandSmartHelp =>
      '選択するオブジェクトをクリックします。初回使用時に MIT Han Lab から約 133 MiB の EfficientViT-SAM L0 モデル（Apache-2.0）をダウンロードし、以後はローカルに保存します。';

  @override
  String get editor_magicWandColorHelp =>
      '近い色の連続領域をクリックします。境界が明瞭なフラット画像に適し、モデルのダウンロードは不要です。';

  @override
  String get editor_magicWandInvert => '結果を反転';

  @override
  String get editor_toolLine => '直線';

  @override
  String get editor_toolRectSelect => '長方形';

  @override
  String get editor_toolEllipseSelect => '楕円';

  @override
  String get editor_toolLassoSelect => 'なげなわ';

  @override
  String get editor_toolColorPicker => 'カラーピッカー';

  @override
  String get editor_toolCloneStamp => 'クローンスタンプ';

  @override
  String get editor_toolBlur => 'ぼかし';

  @override
  String get editor_back => '戻る';

  @override
  String get editor_layers => 'レイヤー';

  @override
  String get editor_loadMask => 'ロードマスク';

  @override
  String get editor_togglePanels => 'パネルの切り替え';

  @override
  String get editor_fillClosedRegion => '閉じた領域を埋める';

  @override
  String get editor_resetMask => 'マスクをリセット';

  @override
  String get editor_zoomIn => 'ズームイン';

  @override
  String get editor_zoomOut => 'ズームアウト';

  @override
  String get editor_fitToWindow => '窓に合わせる';

  @override
  String get editor_shortcutHelpTitle => 'ショートカット ヘルプ';

  @override
  String get editor_shortcutPaintTools => 'ペイント ツール';

  @override
  String get editor_shortcutSelectionTools => '選択ツール';

  @override
  String get editor_shortcutCanvasView => 'キャンバス ビュー';

  @override
  String get editor_shortcutBrushAdjust => 'ブラシの調整';

  @override
  String get editor_shortcutColors => 'カラー';

  @override
  String get editor_shortcutCanvasActions => 'キャンバスアクション';

  @override
  String get editor_shortcutHistoryActions => '履歴アクション';

  @override
  String get editor_shortcutSelectionActions => '選択アクション';

  @override
  String get editor_shortcutTemporaryColorPicker => '一時的なカラーピッカー';

  @override
  String get editor_shortcutRectSelection => '長方形の選択';

  @override
  String get editor_shortcutEllipseSelection => '楕円の選択';

  @override
  String get editor_shortcutLassoSelection => 'なげなわ選択';

  @override
  String get editor_shortcut100Zoom => '100% ズーム';

  @override
  String get editor_shortcutFitHeight => '高さに合わせる';

  @override
  String get editor_shortcutFitWidth => '幅に合わせる';

  @override
  String get editor_shortcutRotateLeft15 => '左に 15 度回転';

  @override
  String get editor_shortcutResetRotation => '回転をリセット';

  @override
  String get editor_shortcutRotateRight15 => '右に 15 度回転';

  @override
  String get editor_shortcutFlipHorizontal => '水平方向に反転';

  @override
  String get editor_shortcutWheel => 'マウス ホイール';

  @override
  String get editor_shortcutBrushSmaller => 'ブラシ サイズを小さくします';

  @override
  String get editor_shortcutBrushLarger => 'ブラシ サイズを大きくする';

  @override
  String get editor_shortcutOpacityLower => '不透明度を下げる';

  @override
  String get editor_shortcutOpacityHigher => '不透明度を増やす';

  @override
  String get editor_shortcutDragBrushSize => 'ブラシ サイズを調整する';

  @override
  String get editor_shortcutSwapColors => '前景色と背景色の交換';

  @override
  String get editor_shortcutPanCanvas => 'パン キャンバス';

  @override
  String get editor_shortcutClearSelectionContent => '選択内容をクリア';

  @override
  String get editor_shortcutCancelCurrentAction => '現在のアクションをキャンセルします';

  @override
  String get editor_selectUnlockedLayerWithContent =>
      'コンテンツを含むロック解除されたレイヤーを選択してください';

  @override
  String get editor_readCurrentLayerFailed => '現在のレイヤーの読み取りに失敗しました';

  @override
  String get editor_localEffects => 'ローカル後処理 / エフェクト';

  @override
  String get editor_basicAdjustments => '基本的な調整';

  @override
  String get editor_styleAndRepair => 'スタイルと修復';

  @override
  String get editor_transformCrop => '回転/反転/切り抜き';

  @override
  String get editor_transformCropDescription =>
      'ジオメトリ操作は別のものです。最初にプレビューを生成し、確認後にのみ書き戻します。';

  @override
  String get editor_effectPreviewHint =>
      'プレビューは元の画像を変更しません。「適用」をクリックすると、結果をアクティブなレイヤーに書き込み、アンドゥ履歴に追加します。';

  @override
  String get editor_applyToCurrentLayer => '現在のレイヤーに適用';

  @override
  String editor_oneShotEffectHint(Object effect) {
    return '$effect はワンショット操作であり、強度スライダーはありません。';
  }

  @override
  String editor_effectIntensity(Object effect) {
    return '$effect 強度';
  }

  @override
  String get editor_original => 'オリジナル';

  @override
  String get editor_effectPreview => 'エフェクトのプレビュー';

  @override
  String get editor_effectBrightness => '明るさ';

  @override
  String get editor_effectContrast => 'コントラスト';

  @override
  String get editor_effectSaturation => '彩度';

  @override
  String get editor_effectTemperature => '温度';

  @override
  String get editor_effectGamma => 'ガンマ';

  @override
  String get editor_effectGrayscale => 'グレースケール';

  @override
  String get editor_effectInvert => '反転';

  @override
  String get editor_effectSepia => 'セピア';

  @override
  String get editor_effectDenoise => 'ノイズ除去';

  @override
  String get editor_effectBlur => 'ガウスぼかし';

  @override
  String get editor_effectSharpen => 'シャープにする';

  @override
  String get editor_effectCropToSelection => '選択範囲まで切り抜き';

  @override
  String get editor_effectRotateLeft => '左に 90 度回転';

  @override
  String get editor_effectRotateRight => '右に 90 度回転';

  @override
  String get editor_effectFlipHorizontal => '水平方向に反転';

  @override
  String get editor_effectFlipVertical => '垂直方向に反転';

  @override
  String editor_effectApplied(Object effect) {
    return '適用済み $effect';
  }

  @override
  String editor_applyEffectFailed(Object error) {
    return '効果の適用に失敗しました: $error';
  }

  @override
  String get editor_changeCanvasSize => 'キャンバス サイズの変更';

  @override
  String editor_canvasTooSmall(Object width, Object height) {
    return 'キャンバスのサイズが小さすぎます。最小サイズは $width × $height ピクセルです';
  }

  @override
  String editor_canvasTooLarge(Object width, Object height) {
    return 'キャンバスのサイズが大きすぎます。最大サイズは $width × $height ピクセルです';
  }

  @override
  String editor_canvasResized(Object width, Object height) {
    return 'キャンバスのサイズを $width × $height に変更しました';
  }

  @override
  String editor_canvasResizeFailed(Object error) {
    return 'キャンバスのサイズ変更に失敗しました: $error';
  }

  @override
  String get editor_confirmExitTitle => '終了の確認';

  @override
  String get editor_confirmExitContent => '未保存の変更があります。終了してもよろしいですか?';

  @override
  String get editor_exit => '終了';

  @override
  String get editor_saveAndExit => '保存して終了';

  @override
  String editor_exportFailed(Object error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get editor_clickInsideClosedRegion => '閉じた領域内をクリックして塗りつぶします。';

  @override
  String get editor_drawClosedMaskOutlineFirst => '最初に閉じたマスクの輪郭を描画します。';

  @override
  String get editor_noClosedRegionAtPosition => 'この位置には充填可能な閉じた領域がありません。';

  @override
  String get editor_generateMaskOverlayFailed => 'マスク オーバーレイの生成に失敗しました';

  @override
  String get editor_maskLayerName => 'マスク';

  @override
  String get editor_updateMaskLayerFailed => 'マスクレイヤーの更新に失敗しました';

  @override
  String get editor_closedRegionFilled => '閉じた領域がマスクとして埋められました。';

  @override
  String editor_fillMaskFailed(Object error) {
    return 'マスクの塗りつぶしに失敗しました: $error';
  }

  @override
  String get editor_magicWandNoSource => 'サンプリング可能な画像レイヤーがありません。';

  @override
  String get editor_magicWandNothingChanged => '選択した領域はすでに透明、またはマスク済みです。';

  @override
  String get editor_magicWandModelPreparing => 'EfficientViT-SAM モデルを確認しています…';

  @override
  String editor_magicWandModelDownloading(int percent) {
    return 'EfficientViT-SAM モデルをダウンロード中：$percent%';
  }

  @override
  String get editor_magicWandModelLoading => 'EfficientViT-SAM モデルを読み込んでいます…';

  @override
  String get editor_magicWandEncoding => '画像内のオブジェクトを解析しています…';

  @override
  String get editor_magicWandSegmenting => 'クリック位置のオブジェクトを分割しています…';

  @override
  String get editor_magicWandPostprocessing => '選択範囲を生成しています…';

  @override
  String editor_magicWandFailed(Object error) {
    return 'マジックワンドに失敗しました: $error';
  }

  @override
  String get editor_compressionTitle => '出力解像度';

  @override
  String get editor_compressionTooltip => '出力解像度を選択';

  @override
  String get editor_compressionUncompressed => '編集作業サイズを維持し、圧縮は行いません。';

  @override
  String get editor_compressionApplyOnDone =>
      '作業キャンバスは変更されません。「完了」を押したときに Pica Lanczos3 で 1 回だけ圧縮します。';

  @override
  String editor_compressionSizeSummary(
    int workWidth,
    int workHeight,
    int targetWidth,
    int targetHeight,
  ) {
    return '作業サイズ $workWidth×$workHeight → 出力サイズ $targetWidth×$targetHeight';
  }

  @override
  String editor_compressionNormalSummary(
    int normalWidth,
    int normalHeight,
    int minimumWidth,
    int minimumHeight,
  ) {
    return 'Normal（約 1 MP）: $normalWidth×$normalHeight。最低: $minimumWidth×$minimumHeight。';
  }

  @override
  String get editor_compressionUnavailable =>
      '作業キャンバスはすでに最低圧縮段階より小さいため、解像度を下げられません。';

  @override
  String editor_unsupportedImageFormat(Object extension) {
    return 'サポートされていないファイル形式: .$extension\n画像ファイル(PNG、JPG、WEBPなど)を選択してください。';
  }

  @override
  String editor_readFileFailed(Object error) {
    return 'ファイルの読み取りに失敗しました: $error';
  }

  @override
  String get editor_noFileData => 'ファイルデータの取得に失敗しました';

  @override
  String get editor_emptyImageFile => 'ファイルが空です。有効な画像ファイルを選択してください';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return 'ファイルが大きすぎます ($sizeMB MB)。 50 MB 未満の画像を選択してください';
  }

  @override
  String get editor_maskLayerAdded => 'マスクレイヤーを追加しました';

  @override
  String get editor_parseImageFailed =>
      '画像ファイルの解析に失敗しました\nファイルが破損しておらず、その形式がサポートされていることを確認してください';

  @override
  String editor_loadMaskFailed(Object error) {
    return 'マスクのロードに失敗しました: $error';
  }

  @override
  String get editor_defaultTitle => 'キャンバス';

  @override
  String get editor_baseLayerName => '基本イメージ';

  @override
  String get editor_existingMaskLayerName => '既存のマスク';

  @override
  String get editor_defaultDrawingLayerName => 'レイヤ 1';

  @override
  String editor_layerName(Object count) {
    return 'レイヤー $count';
  }

  @override
  String get editor_canvasSizeTitle => 'キャンバスのサイズ';

  @override
  String get editor_presetSize => 'プリセット サイズ';

  @override
  String get editor_customSize => 'カスタム';

  @override
  String get editor_contentHandling => 'コンテンツの処理';

  @override
  String get editor_contentCrop => '切り抜き';

  @override
  String get editor_contentPad => 'パッド';

  @override
  String get editor_contentStretch => 'ストレッチ';

  @override
  String get editor_width => '幅';

  @override
  String get editor_height => '高さ';

  @override
  String get editor_lockAspectRatio => 'アスペクト比をロックする';

  @override
  String get editor_unlockAspectRatio => 'アスペクト比のロックを解除します';

  @override
  String get editor_sizePreview => 'サイズのプレビュー';

  @override
  String get editor_originalSize => 'オリジナル';

  @override
  String get editor_newSize => '新しいサイズ';

  @override
  String get editor_cropModeDescription => 'トリミング モード - アスペクト比を維持してトリミングします';

  @override
  String get editor_padModeDescription => 'パッドモード - アスペクト比を維持して余白を追加します';

  @override
  String get editor_stretchModeDescription => 'ストレッチ モード - いっぱいまでストレッチします';

  @override
  String editor_canvasPresetSquare(Object size) {
    return '正方形 $size';
  }

  @override
  String editor_canvasPresetLandscape(Object ratio) {
    return '横長 $ratio';
  }

  @override
  String editor_canvasPresetPortrait(Object ratio) {
    return 'ポートレート $ratio';
  }

  @override
  String get editor_canvasPresetNaiPortrait => 'NAI 縦長';

  @override
  String get editor_canvasPresetNaiLandscape => 'NAI 横長';

  @override
  String get editor_canvasPresetFullHd => 'フル HD 16:9';

  @override
  String get editor_colorPanelTitle => 'カラー';

  @override
  String get editor_colorPickerTitle => '色を選択してください';

  @override
  String get editor_brushSettings => 'ブラシ設定';

  @override
  String get editor_eraserSettings => '消しゴムの設定';

  @override
  String get editor_colorPickerHint =>
      'キャンバス上の任意の場所をクリックして色を選択します。放すと前のツールに戻ります。';

  @override
  String get editor_sample => 'サンプル';

  @override
  String get editor_samplePoint => 'ポイント';

  @override
  String get editor_sampleArea => 'エリア';

  @override
  String get editor_source => 'ソース';

  @override
  String get editor_sourceCurrentLayer => '現在のレイヤー';

  @override
  String get editor_sourceAllLayers => 'すべてのレイヤー';

  @override
  String get editor_lassoSelectionHelp =>
      '押したままドラッグして、自由形式の選択範囲を描画します。放すと自動的に閉まります。';

  @override
  String get layer_empty => 'レイヤーがありません';

  @override
  String get layer_add => 'レイヤーを追加';

  @override
  String get layer_mergeDown => '下へマージ';

  @override
  String get layer_duplicate => '重複';

  @override
  String get layer_delete => '削除';

  @override
  String get layer_merge => '下へマージ';

  @override
  String get layer_visibility => '表示/非表示の切り替え';

  @override
  String get layer_lock => 'ロックの切り替え';

  @override
  String get layer_rename => '名前の変更';

  @override
  String get layer_moveUp => '上に移動';

  @override
  String get layer_moveDown => '下に移動';

  @override
  String get vibe_title => 'バイブストランスファー';

  @override
  String get vibe_description => 'イメージを変えて、ビジョンを維持します。';

  @override
  String get vibe_addFromFileTitle => 'ファイルから追加';

  @override
  String get vibe_addFromFileSubtitle => 'PNG、JPG、Vibe ファイル';

  @override
  String get vibe_addFromLibraryTitle => 'ライブラリからインポート';

  @override
  String get vibe_addFromLibrarySubtitle => 'バイブライブラリから選択';

  @override
  String get vibe_addReference => '参照の追加';

  @override
  String get vibe_clearAll => 'すべてクリア';

  @override
  String vibe_cleared(int count) {
    return '$count 件の Vibe をクリアしました';
  }

  @override
  String get vibe_referenceStrength => '参照強度';

  @override
  String get vibe_infoExtraction => '抽出情報';

  @override
  String get vibe_remove => '削除';

  @override
  String get reference_enabled => '有効';

  @override
  String get reference_enable => '参照を有効化';

  @override
  String get reference_disable => '参照を無効化';

  @override
  String get vibe_normalize => '基準強度値の正規化';

  @override
  String get vibe_sourceType_png => 'PNG';

  @override
  String get vibe_sourceType_v4vibe => 'V4 Vibe';

  @override
  String get vibe_sourceType_bundle => 'バンドル';

  @override
  String get vibe_sourceType_image => '画像';

  @override
  String get vibe_sourceType => 'ソース';

  @override
  String get vibe_reuseButton => '再利用';

  @override
  String get vibe_info => 'Vibe 情報';

  @override
  String get vibe_name => '名前';

  @override
  String get vibe_strength => '強度';

  @override
  String get vibe_infoExtracted => '抽出情報';

  @override
  String get vibe_shiftReplaceHint => 'Shift+クリックして置換';

  @override
  String get character_buttonLabel => 'キャラ/位置';

  @override
  String get character_addCharacter => 'キャラクターを追加';

  @override
  String character_number(Object index) {
    return 'キャラクター $index';
  }

  @override
  String get gallery_generationParams => '生成パラメータ';

  @override
  String get gallery_metaModel => 'モデル';

  @override
  String get gallery_metaResolution => '解像度';

  @override
  String get gallery_metaSteps => 'ステップ';

  @override
  String get gallery_metaSampler => 'サンプラー';

  @override
  String get gallery_metaCfgScale => 'プロンプトガイダンス';

  @override
  String get gallery_metaSeed => 'シード';

  @override
  String get gallery_metaSmea => 'SMEA';

  @override
  String get gallery_promptCopied => 'プロンプトがコピーされました';

  @override
  String get gallery_seedCopied => 'シードがコピーされました';

  @override
  String get gallery_sendToKritaAction => 'Krita に送信';

  @override
  String get gallery_upscalePanelLoaded => 'Image2Image の拡大パネルを読み込みました';

  @override
  String gallery_readImageFailed(Object error) {
    return '画像の読み取りに失敗しました: $error';
  }

  @override
  String get gallery_fileMissing => 'ファイルが存在しません';

  @override
  String get gallery_copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String gallery_copyFailed(Object error) {
    return 'コピーに失敗しました: $error';
  }

  @override
  String get gallery_upscale => '拡大';

  @override
  String get gallery_sentToImg2Img => '画像を Image2Image に送信しました';

  @override
  String gallery_sendFailed(Object error) {
    return '送信失敗: $error';
  }

  @override
  String get onlineGallery_search => '検索';

  @override
  String get onlineGallery_popular => '人気';

  @override
  String get onlineGallery_favorites => 'お気に入り';

  @override
  String get onlineGallery_refresh => '更新';

  @override
  String get onlineGallery_login => 'ログイン';

  @override
  String get onlineGallery_logout => 'ログアウト';

  @override
  String get onlineGallery_dayRank => '日';

  @override
  String get onlineGallery_weekRank => '週';

  @override
  String get onlineGallery_monthRank => '月';

  @override
  String get onlineGallery_today => '今日';

  @override
  String onlineGallery_imageCount(Object count) {
    return '$count 画像';
  }

  @override
  String get onlineGallery_loadFailed => 'ロードに失敗しました';

  @override
  String get onlineGallery_favoritesEmpty => 'お気に入りが空です';

  @override
  String get onlineGallery_noResults => '画像が見つかりませんでした';

  @override
  String get onlineGallery_pleaseLogin => 'まずログインしてください';

  @override
  String get onlineGallery_size => 'サイズ';

  @override
  String get onlineGallery_score => 'スコア';

  @override
  String get onlineGallery_favCount => 'お気に入り';

  @override
  String get onlineGallery_type => 'タイプ';

  @override
  String get mediaType_video => 'ビデオ';

  @override
  String get mediaType_gif => 'GIF';

  @override
  String get onlineGallery_tags => 'タグ';

  @override
  String get onlineGallery_artists => 'アーティスト';

  @override
  String get onlineGallery_characters => 'キャラクター';

  @override
  String get onlineGallery_copyrights => '著作権';

  @override
  String get onlineGallery_general => '一般';

  @override
  String get onlineGallery_copied => 'コピーされました';

  @override
  String get onlineGallery_copyTags => 'タグをコピー';

  @override
  String get onlineGallery_open => '開く';

  @override
  String get onlineGallery_send => '送信';

  @override
  String get onlineGallery_sendToTextToImage => 'テキストから画像へ送信';

  @override
  String get onlineGallery_sentToTextToImage => 'text-to-image に送信されました';

  @override
  String get onlineGallery_noTagInfo => 'この画像にはタグ情報がありません';

  @override
  String get onlineGallery_promptSentToGeneration => 'プロンプトが生成ページに送信されました';

  @override
  String get onlineGallery_gifLoadFailed => 'GIFのロードに失敗しました';

  @override
  String get onlineGallery_pinchToZoom => 'ピンチしてズーム';

  @override
  String get onlineGallery_metadata => 'メタデータ';

  @override
  String get onlineGallery_chooseDownloadDirectory => 'ダウンロード ディレクトリを選択してください';

  @override
  String get onlineGallery_downloadStarted => 'ダウンロードが開始されました...';

  @override
  String onlineGallery_savedToPath(Object path) {
    return '保存先: $path';
  }

  @override
  String onlineGallery_downloadFailed(Object error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get onlineGallery_downloadOriginal => '元の画像をダウンロード';

  @override
  String get onlineGallery_all => 'すべて';

  @override
  String get onlineGallery_ratingGeneral => '一般';

  @override
  String get onlineGallery_ratingSensitive => 'センシティブ';

  @override
  String get onlineGallery_ratingQuestionable => '疑問あり';

  @override
  String get onlineGallery_ratingExplicit => '露骨';

  @override
  String get onlineGallery_clear => 'クリア';

  @override
  String get onlineGallery_previousPage => '前のページ';

  @override
  String get onlineGallery_nextPage => '次のページ';

  @override
  String onlineGallery_pageN(Object page) {
    return 'ページ $page';
  }

  @override
  String get onlineGallery_dateRange => '日付範囲';

  @override
  String get onlineGallery_fuzzySearch => 'ファジーマッチ';

  @override
  String get onlineGallery_fuzzySearchTooltip =>
      '有効な場合は、関連タグに *tag* マッチングを使用します。無効になっている場合は、正確な Danbooru タグを検索します';

  @override
  String get onlineGallery_blacklistTags => 'ブラックリスト タグ';

  @override
  String get onlineGallery_blacklistTitle => 'オンライン ギャラリー ブラックリスト';

  @override
  String get onlineGallery_blacklistSubtitle =>
      'ブラックリストに登録されたタグを含む画像は、オンライン ギャラリーで直接非表示になります。';

  @override
  String get onlineGallery_addBlacklistTagHint => 'ブラックリスト タグを追加';

  @override
  String get onlineGallery_noLocalBlacklistTags => 'ローカル ブラックリスト タグがありません';

  @override
  String get onlineGallery_autoSyncOnStartup => '起動時に自動同期';

  @override
  String get onlineGallery_autoSyncOnStartupSubtitle =>
      'デフォルトで有効になります。いつでもオフにできます';

  @override
  String onlineGallery_lastSyncFailed(Object error) {
    return '最後の同期に失敗しました: $error';
  }

  @override
  String get onlineGallery_neverSyncedBlacklist =>
      'Danbooru ブラックリストはまだ同期されていません';

  @override
  String onlineGallery_lastSync(Object time) {
    return '最終同期: $time';
  }

  @override
  String get onlineGallery_blacklistSettingsTitle => 'オンライン ギャラリーのブラックリスト設定';

  @override
  String get onlineGallery_blacklistLoginHint =>
      'Danbooru にログインしていません。ローカルのブラックリストは引き続き機能しますが、同期にはログインが必要です。';

  @override
  String get onlineGallery_bulkFavorite => '選択項目をお気に入りに追加';

  @override
  String get onlineGallery_bulkDownload => '選択項目をダウンロード';

  @override
  String get onlineGallery_unfavorited => 'お気に入りから削除しました';

  @override
  String get onlineGallery_favorited => 'お気に入りに登録しました';

  @override
  String onlineGallery_favoritedImages(Object count) {
    return '$count 件の画像をお気に入りに追加しました';
  }

  @override
  String onlineGallery_selectDownloadDirectoryFailed(Object error) {
    return 'ダウンロード ディレクトリの選択に失敗しました: $error';
  }

  @override
  String onlineGallery_downloadSelectedStarted(Object count) {
    return '$count 画像をダウンロードしています...';
  }

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return 'ダウンロード完了: $success 成功、$failed 失敗';
  }

  @override
  String get onlineGallery_startDate => '開始日';

  @override
  String get onlineGallery_endDate => '終了日';

  @override
  String get onlineGallery_invalidDateFormat => '無効な日付形式です';

  @override
  String get onlineGallery_dateOutOfRange => '日付が範囲外です';

  @override
  String get onlineGallery_last30Days => '過去 30 日間';

  @override
  String get onlineGallery_configureGelbooruApi => 'Gelbooru API を設定';

  @override
  String get onlineGallery_gelbooruApiReady => 'Gelbooru API は検証済みです';

  @override
  String get onlineGallery_gelbooruApiInvalid => 'Gelbooru 認証情報が無効です';

  @override
  String get onlineGallery_gelbooruCredentialsRequired =>
      'ウェブサイトのお気に入りを表示するには、Gelbooru の User ID と API Key を設定してください。';

  @override
  String get onlineGallery_gelbooruCredentialsInvalid =>
      'Gelbooru 認証情報が無効になりました。再設定してください。';

  @override
  String get onlineGallery_gelbooruRateLimited =>
      'Gelbooru のリクエスト回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get onlineGallery_gelbooruTimeout =>
      'Gelbooru リクエストがタイムアウトしました。ネットワーク接続を確認してください。';

  @override
  String get onlineGallery_gelbooruServerError => 'Gelbooru サーバーは一時的に利用できません。';

  @override
  String get onlineGallery_gelbooruNetworkError =>
      'Gelbooru に接続できません。ネットワークまたはプロキシ設定を確認してください。';

  @override
  String get onlineGallery_gelbooruMalformedResponse =>
      'Gelbooru から解析できないデータが返されました。';

  @override
  String get onlineGallery_gelbooruRequestFailed =>
      'Gelbooru リクエストに失敗しました。しばらくしてから再試行してください。';

  @override
  String get onlineGallery_aiTagQuery => '作品、作者、タイトル、タグ、モデルを検索';

  @override
  String get onlineGallery_aiTagPromptQuery =>
      'AI Prompt 検索（::artist: などの原文構文に対応）';

  @override
  String get onlineGallery_aiTagTimeRange => '期間';

  @override
  String get onlineGallery_aiTagAllTime => 'すべて';

  @override
  String get onlineGallery_aiTagCurrentMonthly => 'リアルタイム月間ランキング';

  @override
  String get onlineGallery_aiTagOlderMonthly => '過去のアーカイブ';

  @override
  String get onlineGallery_aiTagRankingProcessing =>
      'ランキングを生成中です。しばらくしてから再試行してください。';

  @override
  String get onlineGallery_aiTagNaiOnly => 'NAIのみ';

  @override
  String get onlineGallery_aiTagModelVersion => 'モデルバージョン';

  @override
  String get onlineGallery_viewAuthor => 'この作者を見る';

  @override
  String get onlineGallery_returnFromAuthor => '前の閲覧位置に戻る';

  @override
  String get onlineGallery_generationParams => '生成パラメータ';

  @override
  String get onlineGallery_sourceConfigUnavailable =>
      'ソース設定を取得できません。接続を確認して再試行してください。';

  @override
  String get onlineGallery_sourceRateLimited =>
      'リクエストが多すぎます。しばらくしてから再試行してください。';

  @override
  String get onlineGallery_sourceTimeout => 'リクエストがタイムアウトしました。接続を確認してください。';

  @override
  String get onlineGallery_sourceNetworkError =>
      'ギャラリーソースに接続できません。ネットワークまたはプロキシを確認してください。';

  @override
  String get onlineGallery_sourceMalformedResponse =>
      'ソースのレスポンス形式が変更され、解析できません。';

  @override
  String get onlineGallery_detailNotFound => '作品が存在しないか、削除されています。';

  @override
  String get onlineGallery_imageUnavailable => '画像は現在利用できません。';

  @override
  String get onlineGallery_loadedAll => 'すべて読み込み済み';

  @override
  String get onlineGallery_retryAppend => '読み込みに失敗しました。クリックして再試行';

  @override
  String onlineGallery_rankNumber(Object rank) {
    return '第 $rank 位';
  }

  @override
  String onlineGallery_multipleImages(Object count) {
    return '$count 枚の画像';
  }

  @override
  String get onlineGallery_views => '閲覧数';

  @override
  String get onlineGallery_downloadAllMedia => '作品の全画像をダウンロード';

  @override
  String get onlineGallery_copyFullMetadata => '完全なメタデータをコピー';

  @override
  String get onlineGallery_metadataParseFailed =>
      'メタデータの解析に失敗しました。元の内容は保持され、コピーできます。';

  @override
  String get onlineGallery_gelbooruReadOnly => '読み取り専用のお気に入り';

  @override
  String get onlineGallery_gelbooruFavoritesSortHint =>
      '投稿 ID の新しい順です。ウェブサイトのお気に入り登録時刻順とは異なる場合があります。';

  @override
  String get tooltip_fullscreenEdit => 'フルスクリーン編集';

  @override
  String get tooltip_decreaseWeight => 'ウェイトを下げる [-5%]';

  @override
  String get tooltip_increaseWeight => 'ウェイトを上げる [+5%]';

  @override
  String get tooltip_resetWeight => 'クリックして 100% にリセットします';

  @override
  String get upscale_scale => 'スケール係数';

  @override
  String get danbooru_loginTitle => 'ログイン Danbooru';

  @override
  String get danbooru_loginHint => 'お気に入りを使用するには、ユーザー名と API キーを使用してログインしてください';

  @override
  String get danbooru_username => 'ユーザー名';

  @override
  String get danbooru_usernameHint => 'Danbooru ユーザー名を入力してください';

  @override
  String get danbooru_usernameRequired => 'ユーザー名を入力してください';

  @override
  String get danbooru_apiKeyHint => 'API キーを入力してください';

  @override
  String get danbooru_apiKeyRequired => 'API キーを入力してください';

  @override
  String get danbooru_howToGetApiKey => 'API キーを取得するにはどうすればよいですか?';

  @override
  String get danbooru_loginSuccess => 'ログインに成功しました';

  @override
  String get gelbooru_configureTitle => 'Gelbooru API を設定';

  @override
  String get gelbooru_configureHint =>
      'Gelbooru のアカウント設定に表示される User ID と API Key を入力してください。パスワードやブラウザー Cookie は収集しません。';

  @override
  String get gelbooru_userId => 'ユーザー ID';

  @override
  String get gelbooru_userIdHint => '正の整数の User ID を入力';

  @override
  String get gelbooru_userIdRequired => '有効な正の整数の User ID を入力してください';

  @override
  String get gelbooru_apiKeyHint => 'API Key を入力';

  @override
  String get gelbooru_apiKeyRequired => 'API Key を入力してください';

  @override
  String get gelbooru_openAccountSettings => 'Gelbooru のアカウント設定を開く';

  @override
  String get gelbooru_save => '検証して保存';

  @override
  String get gelbooru_saved => 'Gelbooru 認証情報を保存しました';

  @override
  String get gelbooru_removeCredentials => '認証情報を削除';

  @override
  String get gelbooru_invalidInput => '有効な User ID と API Key を入力してください。';

  @override
  String get gelbooru_invalidCredentials =>
      'Gelbooru に認証情報を拒否されました。User ID と API Key を確認してください。';

  @override
  String get gelbooru_rateLimited => 'リクエスト回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get gelbooru_timeout => '検証がタイムアウトしました。ネットワーク接続を確認してください。';

  @override
  String get gelbooru_serverError => 'Gelbooru サーバーは一時的に利用できません。';

  @override
  String get gelbooru_networkError =>
      'Gelbooru に接続できません。ネットワークまたはプロキシ設定を確認してください。';

  @override
  String get gelbooru_malformedResponse => 'Gelbooru から解析できないデータが返されました。';

  @override
  String get gelbooru_storageError => 'Gelbooru 認証情報を安全に保存または読み取れませんでした。';

  @override
  String get gelbooru_unknownError => 'Gelbooru の検証に失敗しました。しばらくしてから再試行してください。';

  @override
  String get tag_addTag => 'タグを追加';

  @override
  String get qualityTags_label => '品質';

  @override
  String get transparentBackground_tooltip =>
      'プロンプトに「transparent background」を追加し、アルファチャンネル付きの画像を生成します（V5 専用）';

  @override
  String get qualityTags_positive => '品質 (プロンプト)';

  @override
  String get qualityTags_negative => '品質 (除外したい要素)';

  @override
  String get qualityTags_disabled => '品質タグが無効です\nクリックして有効にします';

  @override
  String get qualityTags_addToEnd => 'プロンプトの最後に追加:';

  @override
  String get qualityTags_addToStart => 'プロンプトの先頭に追加:';

  @override
  String get qualityTags_naiDefault => 'NAI のデフォルト';

  @override
  String get qualityTags_standard => '標準';

  @override
  String get qualityTags_light => 'ライト';

  @override
  String get qualityTags_none => 'なし';

  @override
  String get ucPreset_label => '除外したい要素プリセット';

  @override
  String get ucPreset_heavy => '重い';

  @override
  String get ucPreset_light => 'ライト';

  @override
  String get ucPreset_furryFocus => '毛皮で覆われた';

  @override
  String get ucPreset_humanFocus => '人間';

  @override
  String get ucPreset_lowQuality => '低品質';

  @override
  String get ucPreset_badAnatomy => '不正確な体の構造';

  @override
  String get ucPreset_none => 'なし';

  @override
  String get ucPreset_disabled => '除外したい要素プリセットが無効です';

  @override
  String get ucPreset_addToNegative => '除外したい要素に追加:';

  @override
  String get ucPreset_nsfwHint =>
      '💡 アダルト コンテンツを生成するには、プロンプトに nsfw を追加します。nsfw タグは除外したい要素から自動的に削除されます';

  @override
  String get generation_imageCount => '生成枚数';

  @override
  String get generation_requestCountTooltip =>
      'リクエスト回数：1 回のクリックで N 回の生成リクエストを送信';

  @override
  String generation_imageCountTotal(int requests, int perRequest, int total) {
    return '$requests 回 × $perRequest 枚 = 合計 $total 枚';
  }

  @override
  String get warmup_networkCheck => 'ネットワーク接続を確認しています...';

  @override
  String get warmup_networkCheck_noProxy =>
      'NovelAI に接続できません。VPN またはプロキシ設定を有効にしてください';

  @override
  String get warmup_networkCheck_noSystemProxy =>
      'プロキシは有効ですが、システム プロキシが検出されませんでした。VPN を有効にしてください。';

  @override
  String get warmup_networkCheck_manualIncomplete =>
      '手動プロキシ構成が不完全です。設定を確認してください。';

  @override
  String get warmup_networkCheck_testing => 'ネットワーク接続をテストしています...';

  @override
  String get warmup_networkCheck_testingProxy => 'プロキシ経由でネットワークをテストしています...';

  @override
  String warmup_networkCheck_success(Object latency) {
    return 'ネットワーク接続は OK (${latency}ms)';
  }

  @override
  String get warmup_networkCheck_timeout =>
      'ネットワーク チェックがタイムアウトしました。オフラインを継続します';

  @override
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts) {
    return 'ネットワークをチェックしています... ($attempt/$maxAttempts を試行)';
  }

  @override
  String get warmup_preparing => '準備中...';

  @override
  String get warmup_complete => '完了';

  @override
  String get warmup_danbooruAuth => 'Danbooru 認証を初期化しています...';

  @override
  String get warmup_loadingTranslation => '翻訳データをロードしています...';

  @override
  String get warmup_initUnifiedDatabase => 'タグ データベースを初期化しています...';

  @override
  String get warmup_initTagSystem => 'タグ システムを初期化しています...';

  @override
  String get warmup_imageEditor => '画像エディタを初期化しています...';

  @override
  String get warmup_database => '最近の履歴を読み込んでいます...';

  @override
  String get warmup_network => 'ネットワーク接続を確認しています...';

  @override
  String get warmup_fonts => 'フォントをプリロードしています...';

  @override
  String get warmup_imageCache => '画像キャッシュをウォームアップしています...';

  @override
  String get warmup_statistics => '統計を読み込んでいます...';

  @override
  String get warmup_artistsSync => 'アーティスト データを同期しています...';

  @override
  String get warmup_subscription => 'サブスクリプション情報を読み込み中...';

  @override
  String get warmup_dataSourceCache => 'データ ソース キャッシュを初期化しています...';

  @override
  String get warmup_galleryFileCount => 'ギャラリー ファイルをスキャンしています...';

  @override
  String get warmup_cooccurrenceData => 'タグ共起データをロードしています...';

  @override
  String get warmup_group_basicUI => '基本的な UI サービスを初期化しています...';

  @override
  String get warmup_group_basicUI_complete => '基本的な UI サービスの準備が完了しました';

  @override
  String get warmup_group_dataServices => 'データ サービスを初期化しています...';

  @override
  String get warmup_group_dataServices_complete => 'データ サービスの準備が完了しました';

  @override
  String get warmup_group_networkServices => 'ネットワーク サービスを初期化しています...';

  @override
  String get warmup_group_networkServices_complete => 'ネットワーク サービスの準備が完了しました';

  @override
  String get warmup_group_cacheServices => 'キャッシュ サービスを初期化しています...';

  @override
  String get warmup_group_cacheServices_complete => 'キャッシュ サービスの準備が完了しました';

  @override
  String get warmup_cooccurrenceInit => '共起データを初期化しています...';

  @override
  String get warmup_translationInit => '翻訳データを初期化しています...';

  @override
  String get warmup_danbooruTagsInit => 'Danbooru タグを初期化しています...';

  @override
  String get warmup_dataMigration => 'Hive / Vibe / 画像データを移行しています...';

  @override
  String get warmup_galleryDataSource => 'ギャラリー インデックスを初期化しています...';

  @override
  String get warmup_checkAndRecoverData => 'データの整合性をチェックしています...';

  @override
  String get warmup_group_dataSourceInitialization =>
      'データ ソース サービスを初期化しています...';

  @override
  String get warmup_group_dataSourceInitialization_complete =>
      'データ ソース サービスの準備が完了しました';

  @override
  String warmup_fetchingTags(Object message) {
    return 'タグを同期しています: $message';
  }

  @override
  String get warmup_fetchingTagDataFromServer => 'サーバーからタグデータを取得しています...';

  @override
  String get warmup_fetchingGeneralTags => '一般タグを取得しています...';

  @override
  String get warmup_fetchingCharacterTags => 'キャラクタータグを取得しています...';

  @override
  String get warmup_fetchingCopyrightTags => '作品タグを取得しています...';

  @override
  String get warmup_fetchingMetaTags => 'メタタグを取得しています...';

  @override
  String get resolution_groupNormal => '正常';

  @override
  String get resolution_groupLarge => 'ラージ';

  @override
  String get resolution_groupWallpaper => '壁紙';

  @override
  String get resolution_groupSmall => '小';

  @override
  String get resolution_groupCustom => 'カスタム';

  @override
  String get resolution_typePortrait => '縦長';

  @override
  String get resolution_typeLandscape => '横長';

  @override
  String get resolution_typeSquare => 'スクエア';

  @override
  String get resolution_typeCustom => 'カスタム';

  @override
  String get resolution_width => '幅';

  @override
  String get resolution_height => '高さ';

  @override
  String get api_error_429 => '同時実行制限に達しました';

  @override
  String get api_error_429_hint =>
      'リクエストが多すぎます。しばらく待ってからもう一度お試しください (共有アカウントの場合に共通)';

  @override
  String get api_error_401 => '認証に失敗しました';

  @override
  String get api_error_401_hint => 'トークンが無効か、期限切れです。再度ログインしてください';

  @override
  String get api_error_402 => '残高が不足しています';

  @override
  String get api_error_402_hint => 'Anlas が不足しています。補充してもう一度お試しください';

  @override
  String get api_error_500 => 'サーバーエラー';

  @override
  String get api_error_500_hint => 'NovelAI サーバー エラー。後でもう一度試してください';

  @override
  String get api_error_503 => 'サービスが利用できません';

  @override
  String get api_error_503_hint => 'サーバーはメンテナンス中か過負荷状態です。後でもう一度試してください';

  @override
  String get api_error_timeout => 'リクエストのタイムアウト';

  @override
  String get api_error_timeout_hint => 'ネットワークタイムアウト。接続を確認してもう一度お試しください';

  @override
  String get api_error_network => 'ネットワークエラー';

  @override
  String get api_error_network_hint => 'サーバーに接続できません。ネットワークを確認してください';

  @override
  String get drop_processing => '画像を処理しています...';

  @override
  String get characterEditor_clearAll => 'すべてクリア';

  @override
  String get characterEditor_clearAllTitle => 'すべてのキャラクターをクリア';

  @override
  String get characterEditor_clearAllConfirm =>
      'すべてのキャラクターを削除しますか？この操作は元に戻せません。';

  @override
  String get characterEditor_nameHint => 'キャラクター名を入力してください';

  @override
  String get characterEditor_enabled => '有効';

  @override
  String get characterEditor_negativePromptHint =>
      'このキャラクターの除外したい要素を入力してください...';

  @override
  String get characterCanvas_title => 'キャラクター位置';

  @override
  String get characterCanvas_finishEditing => '位置の編集を完了';

  @override
  String get characterCanvas_aiChoice => 'AIにおまかせ';

  @override
  String get characterCanvas_custom => 'カスタム';

  @override
  String get characterCanvas_aiHint => 'AIがすべてのキャラクターの位置を自動で決めます';

  @override
  String get characterCanvas_dragHint => 'アンカーをドラッグして位置を設定し、離すと反映されます';

  @override
  String get characterEditor_genderFemale => '女性';

  @override
  String get characterEditor_genderMale => '男性';

  @override
  String get characterEditor_genderOther => 'その他';

  @override
  String get characterEditor_addFemale => 'F';

  @override
  String get characterEditor_addMale => 'M';

  @override
  String get characterEditor_addOther => 'その他';

  @override
  String get characterEditor_moveUp => '上に移動';

  @override
  String get characterEditor_moveDown => '下に移動';

  @override
  String get toolbar_fullscreenEdit => 'フルスクリーン編集';

  @override
  String get characterTooltip_noCharacters => 'キャラクターが設定されていません';

  @override
  String get characterTooltip_clickToConfig => 'クリックして複数キャラクタープロンプトを設定します';

  @override
  String get characterTooltip_globalAiLabel => 'グローバル AI のポジション:';

  @override
  String get characterTooltip_enabled => '有効';

  @override
  String get characterTooltip_disabled => '無効';

  @override
  String get characterTooltip_positionAi => 'AI';

  @override
  String get characterTooltip_disabledLabel => '無効';

  @override
  String get characterTooltip_promptLabel => 'プロンプト';

  @override
  String get characterTooltip_negativeLabel => '除外したい要素';

  @override
  String get characterTooltip_notSet => '未設定';

  @override
  String characterTooltip_summary(Object total, Object enabled) {
    return '$total キャラクター ($enabled 有効)';
  }

  @override
  String get characterTooltip_viewFullConfig => 'クリックすると完全な構成が表示されます';

  @override
  String get addGroup_displayNameLabel => '表示名 (オプション)';

  @override
  String get addGroup_targetCategoryLabel => '対象カテゴリ';

  @override
  String globalSettings_saveFailed(Object error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get nav_generate => '生成';

  @override
  String get nav_gallery => 'ギャラリー';

  @override
  String get nav_settings => '設定';

  @override
  String get sync_preparing => '同期の準備中...';

  @override
  String sync_fetching(Object category) {
    return '$category を取得しています...';
  }

  @override
  String get sync_processing => 'データを処理しています...';

  @override
  String get sync_saving => '保存中...';

  @override
  String sync_completed(Object count) {
    return '同期が完了しました。$count タグ';
  }

  @override
  String sync_failed(Object error) {
    return '同期に失敗しました: $error';
  }

  @override
  String sync_extracting(Object poolName) {
    return '$poolName タグを抽出しています...';
  }

  @override
  String get sync_merging => 'タグを結合しています...';

  @override
  String sync_fetching_tags(Object groupName) {
    return '$groupName タグの人気度を取得しています...';
  }

  @override
  String get sync_filtering => 'タグをフィルタリングしています...';

  @override
  String get sync_done => '同期が完了しました';

  @override
  String get time_just_now => 'ただいま';

  @override
  String time_minutes_ago(Object n) {
    return '$n 分前';
  }

  @override
  String time_hours_ago(Object n) {
    return '$n 時間前';
  }

  @override
  String time_days_ago(Object n) {
    return '$n 日前';
  }

  @override
  String get time_never_synced => '同期されていません';

  @override
  String get vibeParseFailed => 'Vibe ファイルの解析に失敗しました';

  @override
  String get localGallery_progressiveLoadError => '画像のロードに失敗しました';

  @override
  String get localGallery_unknownError => '不明なエラー';

  @override
  String localGallery_loadFailed(Object error) {
    return 'ロードに失敗しました: $error';
  }

  @override
  String get localGallery_indexingLocalImages => 'ローカル画像のインデックスを作成しています...';

  @override
  String get localGallery_emptyTitle => 'ローカル イメージがありません';

  @override
  String get localGallery_emptySubtitle => '生成された画像はここに保存されます';

  @override
  String get localGallery_noMatchingResults => '一致する結果はありません';

  @override
  String get localGallery_title => 'ローカル ギャラリー';

  @override
  String get localGallery_allImages => 'すべての画像';

  @override
  String get localGallery_selectAllResults => 'すべて選択';

  @override
  String get localGallery_deselectAllResults => 'すべての選択を解除';

  @override
  String get localGallery_moveSelected => '移動';

  @override
  String get localGallery_packSelected => 'パック';

  @override
  String get localGallery_editMetadata => '編集';

  @override
  String get localGallery_addToCollection => 'コレクションに追加';

  @override
  String get localGallery_sortButton => '並べ替え';

  @override
  String get localGallery_sortFieldModified => '更新日時';

  @override
  String get localGallery_sortFieldCreated => '作成日時';

  @override
  String get localGallery_sortFieldName => 'ファイル名';

  @override
  String get localGallery_sortFieldSize => 'ファイルサイズ';

  @override
  String get localGallery_sortFieldDimensions => '画像サイズ';

  @override
  String localGallery_aboutColumns(Object count) {
    return '約 $count 列';
  }

  @override
  String get localGallery_columnWidth => '列の幅';

  @override
  String get localGallery_thumbnailQualitySd => '標準';

  @override
  String get localGallery_thumbnailQualityHd => '高画質';

  @override
  String get settings_galleryThumbnailQuality => 'ローカルギャラリーの画質';

  @override
  String get settings_galleryThumbnailQualitySubtitle => 'サムネイルの表示画質。初期設定は高画質';

  @override
  String get localGallery_naiOnlyTooltip => 'NAI 生成画像のみ表示';

  @override
  String get localGallery_naiVersionFilterTooltip => 'NAI モデルのバージョンで絞り込み';

  @override
  String get localGallery_masonryViewLabel => 'ウォーターフォール';

  @override
  String get localGallery_justifiedViewLabel => 'ジャスティファイ';

  @override
  String localGallery_dateRangeYearMonth(Object year, Object month) {
    return '$year年$month月';
  }

  @override
  String get localGallery_dateRangePrevMonth => '前の月';

  @override
  String get localGallery_dateRangeNextMonth => '次の月';

  @override
  String get localGallery_dateRangeClear => 'クリア';

  @override
  String localGallery_searchInScope(Object scope) {
    return '検索：$scope';
  }

  @override
  String get localGallery_hideCategoryPanel => 'カテゴリ パネルを非表示にする';

  @override
  String get localGallery_showCategoryPanel => 'カテゴリ パネルを表示';

  @override
  String get localGallery_refreshTooltip =>
      'ギャラリーを更新\n\n新しい画像または変更された画像を自動的に検出し、インデックスを更新します';

  @override
  String get localGallery_tagIntersection => 'タグの交差';

  @override
  String get localGallery_createCategoryTitle => '新しいカテゴリ';

  @override
  String get localGallery_newOrImport => '新規/インポート';

  @override
  String get localGallery_importFolder => 'フォルダをインポート';

  @override
  String get localGallery_createCategoryHint => 'カテゴリ名を入力してください';

  @override
  String get localGallery_createCategoryConfirm => '作成';

  @override
  String get localGallery_createSubCategoryTitle => '新しいサブカテゴリ';

  @override
  String get localGallery_showInFolder => 'フォルダー内に表示';

  @override
  String get localGallery_promptCopied => 'プロンプトがコピーされました';

  @override
  String get localGallery_seedCopied => 'シードがコピーされました';

  @override
  String get localGallery_createCollectionTitle => '新しいコレクション';

  @override
  String get localGallery_createCollectionHint => 'コレクション名を入力';

  @override
  String get localGallery_createCollectionConfirm => '作成';

  @override
  String get localGallery_createCollectionFolderTitle => '新しいコレクションフォルダ';

  @override
  String get localGallery_createCollectionFolderHint => 'フォルダ名を入力';

  @override
  String get localGallery_createCollectionFolderConfirm => '作成';

  @override
  String localGallery_deleteCollectionContent(Object name) {
    return 'コレクション「$name」を削除しますか？コレクションのエントリのみ削除され、画像ファイルは削除されません。';
  }

  @override
  String localGallery_deleteCollectionFolderContent(Object name) {
    return 'コレクションフォルダ「$name」を削除しますか？フォルダ内は空のため、フォルダ自体のみ削除されます。';
  }

  @override
  String get localGallery_deleteCollectionFolderNonEmptyTitle =>
      'フォルダが空ではありません';

  @override
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name) {
    return 'コレクションフォルダ「$name」にはコレクションまたはサブフォルダが残っています。先に移動または削除してください。';
  }

  @override
  String get localGallery_unfavorite => 'お気に入り解除';

  @override
  String get localGallery_favoriteMenuEmptyCollections =>
      'コレクションがありません。左の + で作成';

  @override
  String localGallery_confirmDeleteImageContent(Object name) {
    return '画像「$name」を削除しますか?\n\n画像はすぐにギャラリーから消え、ファイルは次回起動時に完全に削除されます（このセッション内では元に戻せます）。';
  }

  @override
  String get localGallery_moveTo => '移動先…';

  @override
  String get localGallery_copyTo => 'コピー先…';

  @override
  String get localGallery_externalSourceMoveConfirmTitle => '外部ギャラリーソースファイルの移動';

  @override
  String localGallery_externalSourceMoveConfirmContent(Object count) {
    return '画像 $count 枚を移動します。ファイルは元のフォルダーから移動され、元の場所には残りません。続行しますか？';
  }

  @override
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '画像 $count 枚を外部ギャラリーソースカテゴリー「$targetName」に移動します。ファイルは外部ソースフォルダーに書き込まれます。続行しますか？';
  }

  @override
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '画像 $count 枚を外部ギャラリーソースカテゴリー「$targetName」に移動します。ファイルは元の外部ソースフォルダーから移動され（元の場所には残りません）、外部ソースフォルダーに書き込まれます。続行しますか？';
  }

  @override
  String get localGallery_uncategorizedRoot => '未分類（ギャラリールート）';

  @override
  String get localGallery_externalSourceChip => '外部';

  @override
  String get localGallery_categoryFilterHint => 'カテゴリーを検索…';

  @override
  String localGallery_copySuccess(Object count) {
    return '$count 枚の画像をコピーしました';
  }

  @override
  String get localGallery_copyFailed => '画像のコピーに失敗しました';

  @override
  String get localGallery_confirmCopyContent =>
      '画像をターゲットフォルダーにコピーします。確認してください。';

  @override
  String get localGallery_categoryDeleteContent =>
      'このカテゴリを削除しますか?フォルダーとその内容は保持されます。';

  @override
  String get localGallery_protectedDeleteCategoryTitle => '保護モード: カテゴリの削除の確認';

  @override
  String get localGallery_protectedDeleteCategoryContent =>
      'これにより、カテゴリ レコードが削除されます。フォルダーとその内容は保持されます。もう一度確認してください。';

  @override
  String get localGallery_confirmDelete => '削除の確認';

  @override
  String get localGallery_confirmMoveImageTitle => '保護モード: 画像の移動を確認';

  @override
  String get localGallery_confirmMoveImageContent =>
      'これにより、画像がターゲット カテゴリ フォルダーに移動されます。これが誤ってドラッグされたものではないことを確認します。';

  @override
  String get localGallery_confirmMove => '移動の確認';

  @override
  String get localGallery_imageMovedToCategory => '画像がカテゴリに移動されました';

  @override
  String get localGallery_categoriesSynced => 'カテゴリとフォルダーが同期されました';

  @override
  String get localGallery_saveDirectoryNotSet => '保存ディレクトリが設定されていません';

  @override
  String get localGallery_folderNotFound => 'フォルダーが見つかりません';

  @override
  String localGallery_openFolderFailed(Object error) {
    return 'フォルダーを開けませんでした: $error';
  }

  @override
  String get localGallery_protectedDeleteTitle => '保護モード: 削除を再度確認してください';

  @override
  String localGallery_protectedDeleteImagesContent(Object count) {
    return 'これにより、$count 個のローカル イメージ ファイルが完全に削除されます。これを元に戻すことはできません。';
  }

  @override
  String get localGallery_protectedBulkMoveTitle => '保護モード: 一括移動の確認';

  @override
  String localGallery_protectedBulkMoveContent(Object count) {
    return 'これにより、$count ローカル画像ファイルがターゲット フォルダに移動されます。これが間違いではないことを確認してください。';
  }

  @override
  String localGallery_importParamsFailed(Object error) {
    return 'パラメータのインポートに失敗しました: $error';
  }

  @override
  String localGallery_protectedDeleteImageContent(Object name) {
    return 'これにより、イメージ「$name」が完全に削除されます。これを元に戻すことはできません。';
  }

  @override
  String get localGallery_saveZipArchive => 'ZIP アーカイブを保存';

  @override
  String localGallery_packingImages(Object count) {
    return '$count 個の画像をパッキングしています...';
  }

  @override
  String localGallery_packedImages(Object count) {
    return '$count 個の画像をパックしました';
  }

  @override
  String get localGallery_packFailed => '画像のパックに失敗しました';

  @override
  String get localGallery_imageFileMissing => '画像ファイルが存在しません';

  @override
  String get localGallery_sentToImageToImage => '画像を Image2Image に送信しました';

  @override
  String localGallery_sendFailed(Object error) {
    return '送信失敗: $error';
  }

  @override
  String localGallery_sendToKritaFailed(Object error) {
    return 'Krita への送信に失敗しました: $error';
  }

  @override
  String get localGallery_sendToImg2Img => 'Image2Image に送信';

  @override
  String get localGallery_sendToStyleTransfer => 'バイブストランスファーに送信';

  @override
  String get localGallery_sendToPreciseReference => '精密参照に送信';

  @override
  String get localGallery_sendToKrita => 'Krita に送信';

  @override
  String get localGallery_importImageMetadata => '画像メタデータをインポート';

  @override
  String get localGallery_copyPrompt => 'プロンプトのコピー';

  @override
  String get localGallery_copySeed => 'シードをコピー';

  @override
  String get localGallery_dragToShare => 'ドラッグして共有';

  @override
  String galleryDragCount(int count) {
    return '$count 枚';
  }

  @override
  String get localGallery_moveToRoot => 'ルートに移動';

  @override
  String get localGallery_withMetadata => 'メタデータあり';

  @override
  String get localGallery_skipped => 'スキップされました';

  @override
  String get localGallery_clearFilters => 'フィルターをクリア';

  @override
  String get slideshow_of => '件中';

  @override
  String get slideshow_play => 'プレイ';

  @override
  String get slideshow_pause => '一時停止';

  @override
  String get slideshow_previous => '前へ';

  @override
  String get slideshow_next => '次へ';

  @override
  String get slideshow_exit => '終了 (Esc)';

  @override
  String get slideshow_noImages => '表示する画像がありません';

  @override
  String get slideshow_keyboardHint =>
      '← → を使用して移動し、Space を使用して再生/一時停止し、Esc を使用して終了します';

  @override
  String get comparison_noImages => '表示する画像がありません';

  @override
  String get comparison_tooManyImages => '画像が多すぎます';

  @override
  String get comparison_maxImages => '比較できる画像は最大 4 つです';

  @override
  String get comparison_close => '詳細比較';

  @override
  String get comparison_zoomHint => 'ピンチまたはスクロールして個別にズームします';

  @override
  String get comparison_loadError => '画像のロードに失敗しました';

  @override
  String get statistics_title => '統計';

  @override
  String get statistics_noData => '利用可能な統計はありません';

  @override
  String get statistics_noTagData => 'タグデータがありません';

  @override
  String get statistics_generateFirst => '最初にいくつかの画像を生成します';

  @override
  String get statistics_totalImages => '合計画像数';

  @override
  String get statistics_totalSize => '合計サイズ';

  @override
  String get statistics_favorites => 'お気に入り';

  @override
  String get statistics_samplerDistribution => 'サンプラー分布';

  @override
  String get statistics_additionalStats => '追加の統計';

  @override
  String get statistics_averageFileSize => '平均ファイルサイズ';

  @override
  String get statistics_withMetadata => 'メタデータ付きの画像';

  @override
  String get statistics_justNow => 'たった今';

  @override
  String statistics_minutesAgo(Object count) {
    return '$count 分前';
  }

  @override
  String statistics_hoursAgo(Object count) {
    return '$count 時間前';
  }

  @override
  String statistics_daysAgo(Object count) {
    return '$count 日前';
  }

  @override
  String get statistics_anlasCost => 'Anlas コスト';

  @override
  String get statistics_totalAnlasCost => '総コスト';

  @override
  String get statistics_avgDailyCost => '1 日の平均';

  @override
  String get statistics_noAnlasData => 'Anlas 消費データがありません';

  @override
  String get statistics_peakActivity => 'ピークアクティビティ';

  @override
  String get statistics_timeMorning => '朝';

  @override
  String get statistics_timeAfternoon => '午後';

  @override
  String get statistics_timeEvening => '夕方';

  @override
  String get statistics_timeNight => '夜';

  @override
  String get localGallery_group_today => '今日';

  @override
  String get localGallery_group_yesterday => '昨日';

  @override
  String get localGallery_sendTo => '送信先…';

  @override
  String localGallery_groupImageCount(int count, String formatted) {
    return '$formatted 枚';
  }

  @override
  String localGallery_imageCountLabel(int count, String formatted) {
    return '$formatted 枚';
  }

  @override
  String get localGallery_selectGroup => 'グループを選択';

  @override
  String get localGallery_inspectorTitle => '詳細';

  @override
  String localGallery_inspectorPosition(String index, String total) {
    return '$index / $total';
  }

  @override
  String get localGallery_inspectorEmpty => '画像を選ぶと詳細が表示されます';

  @override
  String get localGallery_inspectorEmptyHint => 'ダブルクリックまたは Space キーで大きく表示';

  @override
  String get localGallery_hideInspector => '詳細パネルを隠す';

  @override
  String get localGallery_showInspector => '詳細パネルを表示';

  @override
  String get localGallery_reuseParams => 'パラメータを再利用';

  @override
  String get localGallery_actionImg2Img => 'Image2Image';

  @override
  String get localGallery_actionStyleTransfer => 'Vibe 転送';

  @override
  String get localGallery_actionPreciseReference => '精密参照';

  @override
  String get localGallery_actionSaveReference => 'ライブラリ保存';

  @override
  String get localGallery_actionKrita => 'Krita';

  @override
  String localGallery_selectedImages(String count) {
    return '$count 枚選択中';
  }

  @override
  String get localGallery_sortDescending => '降順';

  @override
  String get localGallery_sortAscending => '昇順';

  @override
  String get localGallery_moreActions => 'その他';

  @override
  String get localGallery_thumbnailSize => 'サムネイルの大きさ';

  @override
  String get localGallery_naiOnlyChip => 'NAI 画像のみ';

  @override
  String get localGallery_modelLabel => 'モデル';

  @override
  String get localGallery_allVersions => 'すべて';

  @override
  String get localGallery_allVariants => 'すべてのバリアント';

  @override
  String get localGallery_dateRangeChip => '期間';

  @override
  String get localGallery_groupByDay => '日ごとにまとめる';

  @override
  String get localGallery_groupByMonth => '月ごとにまとめる';

  @override
  String get localGallery_groupNone => 'まとめない';

  @override
  String get localGallery_groupModeTooltip => '時間でまとめる';

  @override
  String get localGallery_sectionLibrary => 'ライブラリ';

  @override
  String get localGallery_sectionCollections => 'コレクション';

  @override
  String get localGallery_sectionFolders => 'フォルダー';

  @override
  String get localGallery_dateFolders => '日付フォルダー';

  @override
  String localGallery_indexSynced(String count) {
    return 'インデックス同期済み · $count';
  }

  @override
  String localGallery_cannotOpenFolder(Object error) {
    return 'フォルダーを開けません: $error';
  }

  @override
  String get localGallery_firstTimeTipTitle => '💡 ヒント';

  @override
  String get localGallery_firstTimeTipContent =>
      '画像を右クリック (デスクトップ) または長押し (モバイル) すると、次のことができます。\n\n• プロンプトのコピー\n• コピーシード\n• 完全なメタデータの表示';

  @override
  String get localGallery_gotIt => 'わかりました';

  @override
  String get localGallery_undone => '元に戻しました';

  @override
  String get localGallery_redone => 'やり直し';

  @override
  String get localGallery_confirmBulkDelete => '一括削除の確認';

  @override
  String localGallery_confirmBulkDeleteContent(Object count) {
    return '$count 個の選択した画像を削除してもよろしいですか?\n\n画像はすぐにギャラリーから消え、ファイルは次回起動時に完全に削除されます（このセッション内では元に戻せます）。';
  }

  @override
  String localGallery_deletedToPool(Object count) {
    return '$count 個の画像を削除しました。次回起動時に完全に削除されます。';
  }

  @override
  String get localGallery_trashTitle => 'ゴミ箱';

  @override
  String get localGallery_trashEmpty => 'ゴミ箱は空です';

  @override
  String get localGallery_trashHint =>
      'ゴミ箱内のファイルはディスクに残っており、次回起動時に完全に削除されます。復元するとすぐにギャラリーへ戻ります。';

  @override
  String localGallery_trashCount(Object count) {
    return '$count 件';
  }

  @override
  String get localGallery_trashRestore => '復元';

  @override
  String get localGallery_trashRestoreAll => 'すべて復元';

  @override
  String get localGallery_trashRestoreFailed => '復元に失敗しました';

  @override
  String localGallery_trashRestored(Object count) {
    return '$count 枚の画像を復元しました';
  }

  @override
  String get localGallery_trashDeleteAll => '完全に削除';

  @override
  String localGallery_trashDeleteAllConfirm(Object count) {
    return 'ゴミ箱内の $count 個のファイルを今すぐ完全に削除します。元に戻せません。';
  }

  @override
  String localGallery_trashDeletedForever(Object count) {
    return '$count 個のファイルを完全に削除しました';
  }

  @override
  String get localGallery_trashFileMissing => 'ファイルはディスク上にありません';

  @override
  String localGallery_movedImages(Object count) {
    return '$count 個の画像を移動しました';
  }

  @override
  String get localGallery_moveImagesFailed => '画像の移動に失敗しました';

  @override
  String localGallery_addedToCollection(Object count, Object name) {
    return '$count 画像をコレクション「$name」に追加しました';
  }

  @override
  String get localGallery_addToCollectionFailed => '画像をコレクションに追加できませんでした';

  @override
  String get localGallery_removeFromCollection => 'コレクションから削除';

  @override
  String localGallery_removedFromCollection(Object count, Object name) {
    return 'コレクション「$name」から$count枚の画像を削除しました';
  }

  @override
  String get localGallery_notInCollection => '選択した画像はこのコレクションにありません';

  @override
  String localGallery_removedFromFavorites(Object count) {
    return 'お気に入りから$count枚を削除しました';
  }

  @override
  String get localGallery_alreadyInCollection => '画像は既にこのコレクションに含まれています';

  @override
  String get brushPreset_selectHint => 'ダブルタップしてこのブラシ プリセットを選択します';

  @override
  String get brushPreset_pencil => '鉛筆';

  @override
  String get brushPreset_fine => '細筆';

  @override
  String get brushPreset_standard => '標準ブラシ';

  @override
  String get brushPreset_soft => 'ソフトブラシ';

  @override
  String get brushPreset_airbrush => 'エアブラシ';

  @override
  String get brushPreset_marker => 'マーカー';

  @override
  String get brushPreset_thick => '太いブラシ';

  @override
  String get brushPreset_smudge => 'スマッジ ブラシ';

  @override
  String bulkProgress_progress(Object current, Object total) {
    return '$total の $current を処理しています';
  }

  @override
  String bulkProgress_success(Object count) {
    return '$count は成功しました';
  }

  @override
  String bulkProgress_failed(Object count) {
    return '$count が失敗しました';
  }

  @override
  String get bulkProgress_errors => 'エラー:';

  @override
  String bulkProgress_moreErrors(Object count) {
    return '...さらに $count 個のエラー';
  }

  @override
  String bulkProgress_completed(Object count) {
    return '$count 個のアイテムが完了しました';
  }

  @override
  String bulkProgress_completedWithErrors(Object success, Object failed) {
    return '$success は成功しました、$failed は失敗しました';
  }

  @override
  String get bulkProgress_title_delete => '画像の削除';

  @override
  String get bulkProgress_title_export => 'メタデータのエクスポート';

  @override
  String get bulkProgress_title_metadataEdit => 'メタデータの編集';

  @override
  String get bulkProgress_title_addToCollection => 'コレクションに追加';

  @override
  String get bulkProgress_title_removeFromCollection => 'コレクションから削除しています';

  @override
  String get bulkProgress_title_toggleFavorite => 'お気に入りを更新しています';

  @override
  String get bulkProgress_title_default => '処理中';

  @override
  String bulkProgress_errorDeleteFailed(String error) {
    return '画像の削除に失敗しました: $error';
  }

  @override
  String get bulkProgress_errorNoImagesToExport => 'エクスポートする画像がありません';

  @override
  String get bulkProgress_errorExportFailed => 'エクスポートに失敗しました';

  @override
  String bulkProgress_errorExportFailedWithDetails(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get bulkProgress_errorNoMetadataChanges => '追加または削除するタグを入力してください';

  @override
  String bulkProgress_errorMetadataEditFailed(String error) {
    return '画像メタデータの編集に失敗しました: $error';
  }

  @override
  String bulkProgress_errorFavoriteFailed(String error) {
    return 'お気に入りの更新に失敗しました: $error';
  }

  @override
  String get bulkProgress_errorNoImagesForCollection => 'コレクションに追加する画像がありません';

  @override
  String bulkProgress_errorAddToCollectionFailed(String error) {
    return 'コレクションへの画像追加に失敗しました: $error';
  }

  @override
  String get bulkProgress_errorNothingToUndo => '元に戻す操作がありません';

  @override
  String bulkProgress_errorUndoFailed(String error) {
    return '元に戻せませんでした: $error';
  }

  @override
  String get bulkProgress_errorNothingToRedo => 'やり直す操作がありません';

  @override
  String bulkProgress_errorRedoFailed(String error) {
    return 'やり直せませんでした: $error';
  }

  @override
  String get collectionSelect_dialogTitle => 'コレクションを選択してください';

  @override
  String get collectionSelect_removeTitle => 'コレクションから削除';

  @override
  String collectionSelect_memberCount(Object n) {
    return '選択中の$n枚が含まれます';
  }

  @override
  String get collectionSelect_noSelectedInCollection => '選択中の画像は含まれません';

  @override
  String collectionSelect_memberCountInFavorites(Object n) {
    return 'お気に入り内に選択中の$n枚が含まれます';
  }

  @override
  String get collectionSelect_filterHint => 'コレクションを検索...';

  @override
  String get collectionSelect_noCollections => 'コレクションはありません';

  @override
  String get collectionSelect_createCollectionHint => '最初にコレクションを作成してください';

  @override
  String get collectionSelect_noFilterResults => '一致するコレクションが見つかりませんでした';

  @override
  String collectionSelect_imageCount(int count) {
    return '$count 画像';
  }

  @override
  String get statistics_chartAspectRatio => 'アスペクト比の分布';

  @override
  String get statistics_chartActivityHeatmap => 'アクティビティ ヒートマップ';

  @override
  String get statistics_chartHourlyDistribution => '時間別分布';

  @override
  String get statistics_chartWeekdayDistribution => '曜日別分布';

  @override
  String get statistics_aspectSquare => 'スクエア';

  @override
  String get statistics_aspectLandscape => '横長';

  @override
  String get statistics_aspectPortrait => '縦長';

  @override
  String get statistics_aspectOther => 'その他';

  @override
  String get statistics_refresh => '更新';

  @override
  String get statistics_retry => '再試行';

  @override
  String statistics_error(Object error) {
    return 'エラー: $error';
  }

  @override
  String get statistics_mostActiveDay => '最もアクティブな日';

  @override
  String get statistics_leastActiveDay => '最も活動的でない日';

  @override
  String get statistics_sunday => '日';

  @override
  String get statistics_monday => '月';

  @override
  String get statistics_tuesday => '火';

  @override
  String get statistics_wednesday => '水';

  @override
  String get statistics_thursday => '木';

  @override
  String get statistics_friday => '金';

  @override
  String get statistics_saturday => '土';

  @override
  String get fixedTags_negativeTitle => '除外したい要素固定タグ';

  @override
  String get autocomplete_categoryCharacter => 'キャラクター';

  @override
  String get autocomplete_categoryCopyright => '著作権';

  @override
  String get autocomplete_categoryArtist => 'アーティスト';

  @override
  String get autocomplete_categoryMeta => 'メタ';

  @override
  String get autocomplete_categoryContributor => '投稿者';

  @override
  String get autocomplete_categorySpecies => '種族';

  @override
  String get autocomplete_categoryLore => '設定';

  @override
  String get autocomplete_categoryLibrary => 'ライブラリ';

  @override
  String get autocomplete_categoryGeneral => '一般';

  @override
  String get promptToken_webCalibration => 'Web キャリブレーション';

  @override
  String get promptToken_prompt => 'プロンプト';

  @override
  String get promptToken_qualityPreset => '品質プリセット';

  @override
  String get promptToken_character => 'キャラクター';

  @override
  String get promptToken_negativePrompt => '除外したい要素';

  @override
  String get promptToken_negativePreset => '除外したい要素プリセット';

  @override
  String get promptToken_characterNegative => 'キャラクター除外要素';

  @override
  String get common_rename => '名前の変更';

  @override
  String get tagLibrary_newCategory => '新しいカテゴリ';

  @override
  String get tagLibrary_tags => 'タグ';

  @override
  String get settings_network => 'ネットワーク';

  @override
  String get settings_enableProxy => 'プロキシを有効にする';

  @override
  String get settings_proxyEnabled => '有効';

  @override
  String get settings_proxyDisabled => '直接接続';

  @override
  String get settings_proxyTrafficDisclosure =>
      'プロキシを有効にすると、認証リクエストを含む NovelAI API トラフィックはシステムまたは手動プロキシ経由で送信されます。信頼できるプロキシのみを使用してください。';

  @override
  String get settings_proxyMode => 'プロキシ モード';

  @override
  String get settings_proxyModeAuto => 'システム プロキシの自動検出';

  @override
  String get settings_proxyModeManual => '手動構成';

  @override
  String get settings_auto => '自動';

  @override
  String get settings_manual => '手動';

  @override
  String get settings_proxyHost => 'プロキシ ホスト';

  @override
  String get settings_proxyPort => 'ポート';

  @override
  String get settings_proxyNotDetected => 'システム プロキシが検出されませんでした';

  @override
  String get settings_testConnection => 'テスト接続';

  @override
  String get settings_testConnectionHint => 'クリックしてプロキシが機能しているかどうかをテストします';

  @override
  String settings_testSuccess(Object latency) {
    return '接続成功 ($latencyミリ秒)';
  }

  @override
  String settings_testFailed(Object error) {
    return '接続に失敗しました: $error';
  }

  @override
  String get settings_proxyRestartHint => 'プロキシ設定が変更されました。再起動をお勧めします';

  @override
  String get tagLibrary_addToLibrary => 'ライブラリに追加';

  @override
  String get tagLibrary_uncategorized => '未分類';

  @override
  String get tagLibrary_contentPreview => 'コンテンツのプレビュー';

  @override
  String get settings_enablePromptWeightScroll => 'マウスホイールでプロンプトの重みを調整';

  @override
  String get settings_enablePromptWeightScrollSubtitle =>
      'プロンプトを選択している間、選択した修飾キー＋ホイールで重みを調整します。修飾キーを押さないホイールは通常どおりスクロールします。';

  @override
  String get settings_weightScrollModifierAlt => 'Alt';

  @override
  String get settings_weightScrollModifierCtrl => 'Ctrl';

  @override
  String get settings_weightScrollModifierShift => 'Shift';

  @override
  String get settings_weightScrollModifierNone => 'なし（従来動作）';

  @override
  String get unit_seconds => '秒';

  @override
  String get settings_notificationSound => '完了音';

  @override
  String get settings_notificationSoundSubtitle =>
      'ウィンドウが非アクティブのときだけ生成完了音を再生する';

  @override
  String get settings_notificationCustomSound => 'カスタムサウンド';

  @override
  String get settings_notificationSelectSound => 'サウンドの選択';

  @override
  String get settings_notificationResetSound => 'デフォルトにリセット';

  @override
  String get resetToDefault => 'デフォルトにリセット';

  @override
  String get statistics_heatmapLess => '少ない';

  @override
  String get statistics_heatmapMore => '多い';

  @override
  String statistics_heatmapActivities(Object count) {
    return '$count アクティビティ';
  }

  @override
  String get statistics_heatmapNoActivity => 'アクティビティはありません';

  @override
  String get metadataImport_title => 'インポートするパラメータを選択してください';

  @override
  String get metadataImport_promptsSection => 'プロンプト';

  @override
  String get metadataImport_generationSection => '生成パラメータ';

  @override
  String get metadataImport_selectAll => 'すべて選択';

  @override
  String get metadataImport_promptsOnly => 'プロンプトのみ';

  @override
  String get metadataImport_generationOnly => 'パラメータのみ';

  @override
  String get metadataImport_clear => 'クリア';

  @override
  String get metadataImport_prompt => 'プロンプト';

  @override
  String get metadataImport_mainPrompt => 'メイン プロンプト';

  @override
  String get metadataImport_fixedTags => '固定タグ';

  @override
  String metadataImport_qualityTagsCount(int count) {
    return '品質タグ ($count)';
  }

  @override
  String get metadataImport_negativePrompt => '除外したい要素';

  @override
  String get metadataImport_characterPrompts => 'キャラクタープロンプト';

  @override
  String metadataImport_characterPromptsCount(int count) {
    return 'キャラクタープロンプト ($count)';
  }

  @override
  String metadataImport_characterIndex(int index, Object text) {
    return 'キャラクター $index: $text';
  }

  @override
  String get metadataImport_referenceSection => '参照';

  @override
  String metadataImport_countUnit(int count) {
    return '$count';
  }

  @override
  String metadataImport_preciseReferenceCount(int count) {
    return '精密参照 ($count)';
  }

  @override
  String metadataImport_vibeDetail(Object name, Object strength, Object info) {
    return '$name (参照強度 $strength%、抽出情報 $info%)';
  }

  @override
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  ) {
    return '参照 $index: $type (強度 $strength%、忠実度 $fidelity%)';
  }

  @override
  String get metadataImport_seed => 'シード';

  @override
  String get metadataImport_steps => 'ステップ数';

  @override
  String get metadataImport_scale => 'プロンプトガイダンス';

  @override
  String get metadataImport_size => 'サイズ';

  @override
  String get metadataImport_sampler => 'サンプラー';

  @override
  String get metadataImport_model => 'モデル';

  @override
  String get metadataImport_smea => 'SMEA';

  @override
  String get metadataImport_smeaDyn => 'SMEA Dyn';

  @override
  String get metadataImport_noiseSchedule => 'ノイズスケジュール';

  @override
  String get metadataImport_cfgRescale => 'プロンプトガイダンスリスケール';

  @override
  String get metadataImport_qualityToggle => '品質切り替え';

  @override
  String get metadataImport_ucPreset => '除外したい要素プリセット';

  @override
  String get metadataImport_noData => '(データなし)';

  @override
  String metadataImport_selectedCount(int count) {
    return '$count が選択されました';
  }

  @override
  String get metadataImport_noDataFound => 'NovelAI メタデータが見つかりませんでした';

  @override
  String metadataImport_appliedCount(int count) {
    return '適用された $count パラメータ';
  }

  @override
  String get metadataImport_appliedTitle => 'メタデータが適用されました';

  @override
  String get metadataImport_appliedDescription => '次のパラメータが適用されました:';

  @override
  String get metadataImport_charactersCount => 'キャラクター';

  @override
  String get shortcut_context_global => 'グローバル';

  @override
  String get shortcut_context_generation => '生成';

  @override
  String get shortcut_context_gallery => 'ギャラリーリスト';

  @override
  String get shortcut_context_viewer => '画像ビューア';

  @override
  String get shortcut_context_settings => '設定';

  @override
  String get shortcut_context_input => '入力フィールド';

  @override
  String get shortcut_action_navigate_to_generation => '生成ページ';

  @override
  String get shortcut_action_navigate_to_local_gallery => 'ローカル ギャラリー';

  @override
  String get shortcut_action_navigate_to_online_gallery => 'オンライン ギャラリー';

  @override
  String get shortcut_action_navigate_to_tag_library => 'プロンプトブロック';

  @override
  String get shortcut_action_navigate_to_statistics => '統計';

  @override
  String get shortcut_action_navigate_to_settings => '設定';

  @override
  String get shortcut_action_generate_image => '画像の生成';

  @override
  String get shortcut_action_generation_prev_image => '前のプレビュー（履歴連動）';

  @override
  String get shortcut_action_generation_next_image => '次のプレビュー（履歴連動）';

  @override
  String get shortcut_action_cancel_generation => '生成のキャンセル';

  @override
  String get shortcut_action_clear_prompt => 'プロンプトをクリア';

  @override
  String get shortcut_action_toggle_prompt_mode => 'プロンプトモードの切り替え';

  @override
  String get shortcut_action_open_tag_library => 'ブロックライブラリを開く';

  @override
  String get shortcut_action_save_image => '画像を保存';

  @override
  String get shortcut_action_upscale_image => '画像を拡大';

  @override
  String get shortcut_action_copy_image => '画像をコピー';

  @override
  String get shortcut_action_fullscreen_preview => '全画面プレビュー';

  @override
  String get shortcut_action_open_params_panel => 'パラメータパネルを開く';

  @override
  String get shortcut_action_open_history_panel => '履歴パネルを開く';

  @override
  String get shortcut_action_reuse_params => 'パラメータの再利用';

  @override
  String get shortcut_action_previous_image => '前の画像';

  @override
  String get shortcut_action_next_image => '次の画像';

  @override
  String get shortcut_action_zoom_in => 'ズームイン';

  @override
  String get shortcut_action_zoom_out => 'ズームアウト';

  @override
  String get shortcut_action_reset_zoom => 'ズームをリセット';

  @override
  String get shortcut_action_toggle_fullscreen => '全画面表示の切り替え';

  @override
  String get shortcut_action_close_viewer => 'ビューアを閉じる';

  @override
  String get shortcut_action_toggle_favorite => 'お気に入りの切り替え';

  @override
  String get shortcut_action_copy_prompt => 'プロンプトのコピー';

  @override
  String get shortcut_action_reuse_gallery_params => 'パラメータの再利用';

  @override
  String get shortcut_action_delete_image => '画像を削除';

  @override
  String get shortcut_action_previous_page => '1 画面上へ';

  @override
  String get shortcut_action_next_page => '1 画面下へ';

  @override
  String get shortcut_action_refresh_gallery => 'ギャラリーを更新';

  @override
  String get shortcut_action_focus_search => '検索にフォーカス';

  @override
  String get shortcut_action_enter_selection_mode => 'すべて選択';

  @override
  String get shortcut_action_clear_filter => 'フィルターをクリア';

  @override
  String get shortcut_action_toggle_category_panel => 'カテゴリ パネルの切り替え';

  @override
  String get shortcut_action_jump_to_date => '日付に移動';

  @override
  String get shortcut_action_open_folder => 'フォルダーを開く';

  @override
  String get shortcut_action_minimize_to_tray => 'トレイに最小化';

  @override
  String get shortcut_action_quit_app => 'アプリケーションを終了します';

  @override
  String get shortcut_action_show_shortcut_help => 'ショートカット ヘルプを表示';

  @override
  String get shortcut_action_toggle_theme => 'テーマの切り替え';

  @override
  String get shortcut_settings_title => 'キーボード ショートカット';

  @override
  String get shortcut_settings_enable => 'ショートカットを有効にする';

  @override
  String get shortcut_settings_show_badges => 'ショートカット バッジを表示';

  @override
  String get shortcut_settings_show_in_tooltips => 'ツールチップに表示';

  @override
  String get shortcut_settings_reset_all => 'すべてをデフォルトにリセット';

  @override
  String get shortcut_settings_search => 'ショートカットを検索...';

  @override
  String get shortcut_settings_press_key => 'キーの組み合わせを押してください...';

  @override
  String get shortcut_help_title => 'キーボード ショートカットのヘルプ';

  @override
  String get shortcut_help_search => 'ショートカットを検索...';

  @override
  String get shortcut_help_all => 'すべて';

  @override
  String get shortcut_help_fabTooltip => 'キーボード ショートカット ヘルプ (F1)';

  @override
  String get shortcut_editor_recordingInline => 'ショートカットを押してください...';

  @override
  String get shortcut_editor_pressEscToCancel => 'キャンセルするには Esc キーを押してください';

  @override
  String get shortcut_editor_clickToRecord => 'クリックして記録を開始します';

  @override
  String shortcut_editor_conflictWith(Object action) {
    return 'このショートカットは「$action」と競合します';
  }

  @override
  String get drop_hint => 'ここに画像をドロップしてください';

  @override
  String get drop_img2img => 'Image2Image';

  @override
  String get drop_vibeTransfer => 'バイブストランスファー';

  @override
  String get drop_characterReference => '精密参照';

  @override
  String get drop_unsupportedFormat => 'サポートされていないファイル形式です';

  @override
  String get drop_addedToImg2Img => 'Image2Image に追加しました';

  @override
  String get drop_addedToVibe => 'バイブストランスファーに追加しました';

  @override
  String drop_addedMultipleToVibe(int count) {
    return '$count 件のバイブストランスファー参照を追加しました';
  }

  @override
  String get drop_addedToCharacterRef => '精密参照に追加しました';

  @override
  String get drop_vibeDetected => '事前にエンコードされた Vibe を検出しました (2 Anlas を節約)';

  @override
  String get drop_reuseVibe => 'バイブを再利用';

  @override
  String get drop_useAsRawImage => 'Raw 画像として使用';

  @override
  String get drop_dragToImg2ImgOrOther => 'Image2Image または別のターゲットにドラッグします';

  @override
  String get preciseRef_title => '精密参照';

  @override
  String get preciseRef_subtitle => 'キャラクターやスタイル参照に生成を結び付ける';

  @override
  String get preciseRef_description =>
      '参照画像を追加し、タイプとパラメータを設定します。複数の参照を同時に使用できます。';

  @override
  String get preciseRef_addReference => '参照の追加';

  @override
  String get preciseRef_clearAll => 'すべてクリア';

  @override
  String get preciseRef_remove => '削除';

  @override
  String get preciseRef_referenceType => '参照タイプ';

  @override
  String get preciseRef_strength => '強度';

  @override
  String get preciseRef_fidelity => '忠実度';

  @override
  String get preciseRef_v4Only => 'この機能には V4 以降のモデルが必要です';

  @override
  String get preciseRef_typeCharacter => 'キャラ参照';

  @override
  String get preciseRef_typeStyle => '絵柄参照';

  @override
  String get preciseRef_typeCharacterAndStyle => 'キャラ＆絵柄参照';

  @override
  String get preciseRef_costHint => '精密参照を使用すると追加の Anlas を消費します';

  @override
  String get preciseRef_costBadge => 'Anlas を使用します';

  @override
  String get preciseRef_dropToAdd => '精密参照を追加するにはリリースしてください';

  @override
  String get preciseRef_dropNoReadableImage =>
      'ドロップ ソースは読み取り可能な画像ファイルまたは画像リンクを提供しませんでした';

  @override
  String preciseRef_addedCount(int count) {
    return '$count 件の精密参照を追加しました';
  }

  @override
  String preciseRef_removedCount(int count) {
    return '$count 件の精密参照を削除しました';
  }

  @override
  String get vibeLibrary_title => 'バイブライブラリ';

  @override
  String get vibeLibrary_categories => 'カテゴリ';

  @override
  String get vibeLibrary_createCategoryTitle => '新しいカテゴリ';

  @override
  String get vibeLibrary_createSubCategoryTitle => '新しいサブカテゴリ';

  @override
  String get vibeLibrary_categoryNameHint => 'カテゴリ名を入力してください';

  @override
  String get vibeLibrary_createCategoryConfirm => '作成';

  @override
  String get vibeLibrary_deleteCategoryTitle => '削除の確認';

  @override
  String get vibeLibrary_deleteCategoryContent =>
      'このカテゴリを削除しますか？中の Vibe は未分類に移動されます。';

  @override
  String get vibeLibrary_sortTooltip => '並べ替え基準';

  @override
  String get vibeLibrary_hideCategoryPanel => 'カテゴリ パネルを非表示にする';

  @override
  String get vibeLibrary_showCategoryPanel => 'カテゴリ パネルを表示';

  @override
  String get vibeLibrary_enterSelectionMode => '選択モードに入ります';

  @override
  String get vibeLibrary_importTooltip =>
      'Vibe ファイルまたは PNG/JPG/JPEG/WEBP 画像をインポートします (右クリックしてその他のオプションを表示します)';

  @override
  String get vibeLibrary_exportTooltip => 'Vibe をファイルにエクスポート';

  @override
  String get vibeLibrary_openFolderTooltip => 'バイブライブラリフォルダーを開く';

  @override
  String get vibeLibrary_refresh => '更新';

  @override
  String get vibeLibrary_loading => '読み込み中...';

  @override
  String vibeLibrary_totalCount(Object count) {
    return '$count 件の Vibe';
  }

  @override
  String get vibeLibrary_noCategoriesAvailable => '使用可能なカテゴリがありません';

  @override
  String get vibeLibrary_moveToCategory => 'カテゴリに移動';

  @override
  String get vibeLibrary_uncategorized => '未分類';

  @override
  String vibeLibrary_movedToCategory(Object count) {
    return '$count 件の Vibe を移動しました';
  }

  @override
  String get vibeLibrary_favoriteStatusUpdated => 'お気に入りのステータスが更新されました';

  @override
  String get vibeLibrary_importFromFile => 'ファイルからインポート';

  @override
  String get vibeLibrary_importFromImage => '画像からインポート';

  @override
  String get vibeLibrary_importFromClipboard => 'クリップボードからエンコードされたデータをインポート';

  @override
  String vibeLibrary_openFolderFailed(Object error) {
    return 'フォルダーを開けませんでした: $error';
  }

  @override
  String get vibeLibrary_importFileDialogTitle => 'インポートする Vibe ファイルを選択してください';

  @override
  String get vibeLibrary_preparingImport => 'インポートを準備しています...';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '$count 件の Vibe をインポートしました';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return 'インポート完了: $success 成功、$failed 失敗';
  }

  @override
  String get vibeLibrary_dropImportHint =>
      '.naiv4vibe/.naiv4vibebundle/.png/.jpg/.jpeg/.webp ファイルまたはフォルダーをここにドロップしてインポートします';

  @override
  String get vibeLibrary_importing => 'インポート中...';

  @override
  String vibeLibrary_pageIndicator(Object current, Object total) {
    return '$current / $total ページ';
  }

  @override
  String get vibeLibrary_itemsPerPage => 'ページごと:';

  @override
  String get vibeLibrary_tooManyTitle => 'Vibe が多すぎます';

  @override
  String vibeLibrary_tooManySelectedContent(Object count) {
    return '$count 件の Vibe が選択されています。一度に使用できるのは最大 16 件です。\n\n選択数を減らして再試行してください。';
  }

  @override
  String vibeLibrary_tooManyExistingContent(Object current, Object remaining) {
    return '生成ページにはすでに $current 件の Vibe があります。さらに $remaining 件まで追加できます。\n\n選択数を減らして再試行してください。';
  }

  @override
  String vibeLibrary_sentToGenerationCount(Object count) {
    return '$count 件の Vibe を生成に送信しました';
  }

  @override
  String vibeLibrary_deleteSelectedContent(Object count) {
    return '選択した $count 件の Vibe を削除しますか？この操作は元に戻せません。';
  }

  @override
  String vibeLibrary_deletedCount(Object count) {
    return '$count 件の Vibe を削除しました';
  }

  @override
  String get vibeLibrary_importImageDialogTitle => 'Vibe データを含む画像を選択してください';

  @override
  String get vibeLibrary_clipboardEmpty => 'クリップボードが空です';

  @override
  String get vibeLibrary_encodeTimeout => 'エンコードがタイムアウトしました。ネットワーク接続を確認してください。';

  @override
  String get vibeLibrary_unknownError => '不明なエラー';

  @override
  String get vibeLibrary_save => 'ライブラリに保存';

  @override
  String get vibeLibrary_import => 'Vibe をインポート';

  @override
  String get vibeLibrary_searchHint => '名前、タグを検索...';

  @override
  String get vibeLibrary_empty => 'バイブライブラリは空です';

  @override
  String get vibeLibrary_emptyHint => 'まずバイブライブラリにエントリを追加してください';

  @override
  String get vibeLibrary_allVibes => 'すべての Vibe';

  @override
  String get vibeLibrary_favorites => 'お気に入り';

  @override
  String get vibeLibrary_sendToGeneration => '生成に送信';

  @override
  String get vibeLibrary_export => 'エクスポート';

  @override
  String get vibeLibrary_edit => '編集';

  @override
  String get vibeLibrary_delete => '削除';

  @override
  String get vibeLibrary_addToFavorites => 'お気に入りに追加';

  @override
  String get vibeLibrary_removeFromFavorites => 'お気に入りから削除';

  @override
  String get vibeLibrary_newSubCategory => '新しいサブカテゴリ';

  @override
  String get vibeLibrary_maxVibesReached => '最大制限に達しました (16 件の Vibe)';

  @override
  String get vibeLibrary_bundleReadFailed =>
      'バンドルファイルの読み取りに失敗したため、単一ファイルモードを使用します';

  @override
  String categoryError_loadFailed(String error) {
    return 'カテゴリの読み込みに失敗しました: $error';
  }

  @override
  String categoryError_syncFailed(String error) {
    return 'カテゴリの同期に失敗しました: $error';
  }

  @override
  String get categoryError_nameEmpty => 'カテゴリ名を入力してください';

  @override
  String get categoryError_parentNotFound => '親カテゴリが存在しません';

  @override
  String categoryError_createFailed(String error) {
    return 'カテゴリの作成に失敗しました: $error';
  }

  @override
  String get categoryError_notFound => 'カテゴリが存在しません';

  @override
  String categoryError_renameFailed(String error) {
    return 'カテゴリ名の変更に失敗しました: $error';
  }

  @override
  String get categoryError_invalidMove => '子孫カテゴリの下には移動できません';

  @override
  String categoryError_moveFailed(String error) {
    return 'カテゴリの移動に失敗しました: $error';
  }

  @override
  String get categoryError_hasSubcategories =>
      'このカテゴリにはサブカテゴリがあります。先に削除してください。';

  @override
  String categoryError_deleteFailed(String error) {
    return 'カテゴリの削除に失敗しました: $error';
  }

  @override
  String categoryError_moveImageFailed(String error) {
    return '画像の移動に失敗しました: $error';
  }

  @override
  String categoryError_moveImagesFailed(String error) {
    return '画像の一括移動に失敗しました: $error';
  }

  @override
  String categoryError_reorderFailed(String error) {
    return 'カテゴリの並べ替えに失敗しました: $error';
  }

  @override
  String get vibeBulkTag_actionPreview => '変更内容';

  @override
  String get vibeDetail_strengthDescription => 'この Vibe が生成結果に与える影響の強さを調整します';

  @override
  String get vibeDetail_infoExtractedDescription =>
      '元画像から抽出する情報量を調整します（2 Anlas を消費）';

  @override
  String get vibeDetail_statistics => '統計情報';

  @override
  String get vibeDetail_usageCount => '使用回数';

  @override
  String vibeDetail_timesUsed(int count) {
    return '$count 回';
  }

  @override
  String get vibeDetail_lastUsed => '最終使用';

  @override
  String get vibeDetail_neverUsed => '未使用';

  @override
  String get vibeDetail_createdAt => '作成日時';

  @override
  String get vibeDetail_saveParameters => 'パラメーターを保存';

  @override
  String get vibe_export_title => 'Vibe をエクスポート';

  @override
  String get vibe_export_format => 'エクスポート形式';

  @override
  String get vibe_selector_title => 'Vibe を選択してください';

  @override
  String get vibe_selector_recent => '最近の';

  @override
  String get vibe_export_include_thumbnails => 'サムネイルを含める';

  @override
  String get vibe_export_include_thumbnails_subtitle =>
      'エクスポート ファイルにサムネイル プレビューを含めます';

  @override
  String get vibe_export_singleFile => '単一ファイル (.naiv4vibe)';

  @override
  String get vibe_export_singleFileDescription =>
      '各 Vibe を個別のファイルとしてエクスポートし、1 つの Vibe を共有するのに適しています';

  @override
  String get vibe_export_bundleFile => 'バンドル ファイル (.naiv4vibebundle)';

  @override
  String get vibe_export_bundleFileDescription =>
      '複数の Vibe を 1 つのファイルにまとめ、バッチバックアップに適しています';

  @override
  String get vibe_export_embedIntoPng => 'PNG に埋め込む';

  @override
  String get vibe_export_embedIntoPngDescription =>
      'データを PNG メタデータに埋め込んで単一の Vibe をエクスポートします';

  @override
  String get vibe_export_exportable => 'エクスポート可能';

  @override
  String get vibe_export_notExportable => 'エクスポートできません';

  @override
  String get vibe_export_selectVibesToExport => 'エクスポートする Vibe を選択してください';

  @override
  String vibe_export_exportSelected(int count) {
    return 'エクスポート ($count)';
  }

  @override
  String vibe_export_strengthPercent(int percent) {
    return '強度: $percent%';
  }

  @override
  String get vibe_export_pngCarrierImage => 'PNG キャリア画像';

  @override
  String get vibe_export_noUsablePngCarrier =>
      'この Vibe には、直接使用できる PNG キャリア画像がありません。外部 PNG 画像をキャリアとして選択できます。';

  @override
  String get vibe_export_selectExternalPngImage => '外部 PNG 画像を選択してください...';

  @override
  String get vibe_export_changeExternalPngImage => '外部 PNG 画像を変更します...';

  @override
  String get vibe_export_useVibeImageInstead => '代わりに Vibe 画像を使用してください';

  @override
  String vibe_export_usingExternalPng(String fileName) {
    return '外部 PNG の使用: $fileName';
  }

  @override
  String get vibe_export_selectPngImage => 'PNG 画像を選択してください';

  @override
  String get vibe_export_invalidPngImage => '選択したファイルは有効な PNG 画像ではありません';

  @override
  String vibe_export_selectPngImageFailed(String error) {
    return 'PNG 画像の選択に失敗しました: $error';
  }

  @override
  String vibe_export_embeddingPng(String name) {
    return 'PNG の埋め込み: $name';
  }

  @override
  String vibe_export_exportCompleteCounts(int successCount, int failCount) {
    return 'エクスポート完了: $successCount 成功、$failCount 失敗';
  }

  @override
  String vibe_export_exportCompletePath(String path) {
    return 'エクスポートが完了しました: $path';
  }

  @override
  String vibe_export_packingVibes(int count) {
    return '$count 件の Vibe をパックしています...';
  }

  @override
  String vibe_export_exportingName(String name) {
    return 'エクスポート中: $name';
  }

  @override
  String get vibe_export_selectExportFolder => 'エクスポートフォルダーを選択してください';

  @override
  String get vibe_export_generatingBundleFile => 'バンドル ファイルを生成しています...';

  @override
  String vibe_export_bundleTitle(String name) {
    return 'バンドルのエクスポート: $name';
  }

  @override
  String vibe_export_vibesTitle(int count) {
    return 'Vibe をエクスポート ($count 件選択中)';
  }

  @override
  String get vibe_export_method => 'エクスポート方法';

  @override
  String get vibe_export_wholeBundle => 'バンドル全体';

  @override
  String get vibe_export_internalVibe => '内部 Vibe';

  @override
  String vibe_export_wholeBundleDescription(int count) {
    return '全 $count 件の Vibe を含む .naiv4vibebundle ファイルとしてエクスポートします';
  }

  @override
  String vibe_export_internalVibeDescription(int count) {
    return '.naiv4vibe ファイルとして個別にエクスポートする内部バンドル Vibe を選択してください (合計 $count)';
  }

  @override
  String get vibe_export_exportBundle => 'エクスポート バンドル';

  @override
  String get vibe_export_exportAsFiles => 'ファイルとしてエクスポート';

  @override
  String get vibe_export_exportBundleDescription =>
      '.naiv4vibebundle ファイルとしてエクスポート';

  @override
  String get vibe_export_exportAsFilesDescription =>
      '.naiv4vibe または .naiv4vibebundle ファイルとしてエクスポート';

  @override
  String get vibe_export_exportAsZip => 'ZIP としてエクスポート';

  @override
  String get vibe_export_exportAsZipDescription =>
      '選択したバイブライブラリエントリを個別のファイルとして .zip にパックします';

  @override
  String get vibe_export_compressData => 'データを圧縮します';

  @override
  String get vibe_export_compressDataDescription =>
      '圧縮を使用してファイル サイズを削減します (バッチ エクスポートに推奨)';

  @override
  String get vibe_export_zipCompressDescription => 'ZIP 内のファイルを圧縮してサイズを削減します';

  @override
  String get vibe_export_exportAsPng => 'PNG としてエクスポート';

  @override
  String get vibe_export_pngInternalBundleUnsupported =>
      '単一の内部バンドル Vibe をエクスポートする場合、画像への埋め込みはサポートされていません';

  @override
  String get vibe_export_embedVibeDataIntoPng => 'Vibe データを PNG メタデータに埋め込む';

  @override
  String get vibe_export_batchPngUsesFirstImage =>
      'バッチ エクスポートでは、各 Vibe の最初に使用可能な画像が使用されます。画像のないエントリは自動的にスキップされます。';

  @override
  String get vibe_export_exportCarrierImage => 'キャリアイメージのエクスポート';

  @override
  String get vibe_export_usingExternalCarrierImage =>
      'エクスポートキャリア画像として外部 PNG を使用する';

  @override
  String get vibe_export_exportAsEncodings => 'エンコーディングとしてエクスポート';

  @override
  String get vibe_export_exportAsEncodingsDescription =>
      'データをエンコーディング (JSON または Base64) としてエクスポートします。';

  @override
  String get vibe_export_jsonDescription =>
      '読み取りと編集を容易にするために、フォーマットされた JSON ファイルとしてエクスポートします。';

  @override
  String get vibe_export_base64Description =>
      'コピーと共有のためにプレーン Base64 としてエクスポートします';

  @override
  String get vibe_export_selectAtLeastOneMethod =>
      '少なくとも 1 つのエクスポート方法を選択してください';

  @override
  String get vibe_export_batchPngUnsupported =>
      'バッチ Vibe エクスポートは、PNG への埋め込みをサポートしていません。単一の Vibe エクスポート画面を使用します。';

  @override
  String get vibe_export_selectPngCarrier => 'エクスポートする PNG キャリア画像を選択してください';

  @override
  String get vibe_export_selectAtLeastOneInternalVibe =>
      'エクスポートする内部 Vibe を少なくとも 1 つ選択してください';

  @override
  String get vibe_export_selectVibeExportFolder => 'Vibe エクスポート フォルダーを選択してください';

  @override
  String get vibe_export_saveEncodingFile => 'エンコードファイルを保存';

  @override
  String get vibe_export_preparingExport => 'エクスポートを準備しています...';

  @override
  String vibe_export_preparingVibeProgress(int current, int total) {
    return 'Vibe $current/$total を読み取り中...';
  }

  @override
  String get vibe_export_exportingBundle => 'バンドルをエクスポートしています...';

  @override
  String get vibe_export_exportingZip => 'ZIP をエクスポートしています...';

  @override
  String get vibe_export_embeddingImage => '画像を埋め込んでいます...';

  @override
  String get vibe_export_exportingEncoding => 'エンコーディングをエクスポートしています...';

  @override
  String vibe_export_exportFailedWithError(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get vibe_export_noExportableEntries => 'エクスポート可能な Vibe エントリがありません';

  @override
  String get vibe_export_bundleFilePathEmpty => 'バンドル ファイルのパスが空です';

  @override
  String vibe_export_invalidImageFormatWithError(String error) {
    return '無効な画像形式: $error';
  }

  @override
  String vibe_export_embedFailedWithError(String error) {
    return '埋め込みに失敗しました: $error';
  }

  @override
  String vibe_export_embedImageFailedWithError(String error) {
    return '画像の埋め込みに失敗しました: $error';
  }

  @override
  String vibe_export_extractingVibeProgress(int current, int total) {
    return 'Vibe $current/$total を抽出しています...';
  }

  @override
  String vibe_export_selectImageFailed(String error) {
    return '画像の選択に失敗しました: $error';
  }

  @override
  String vibe_export_dialogTitle(int count) {
    return '$count 件の Vibe をエクスポート';
  }

  @override
  String get vibe_export_chooseMethod => 'Vibe のエクスポート方法を選択してください';

  @override
  String get vibe_export_asBundle => 'バンドルとして';

  @override
  String get vibe_export_individually => '個別';

  @override
  String get vibe_export_noData => 'エクスポートするデータがありません';

  @override
  String get vibe_export_success => 'エクスポートが成功しました';

  @override
  String get vibe_export_failed => 'エクスポートに失敗しました';

  @override
  String vibe_export_skipped(int count) {
    return 'データのない $count 件の Vibe をスキップしました';
  }

  @override
  String vibe_export_bundleSuccess(int count) {
    return 'バンドルをエクスポートしました: $count 件の Vibe';
  }

  @override
  String get vibe_export_selectToEmbed => '埋め込む Vibe を選択してください';

  @override
  String get vibe_export_pngRequired => 'PNG ファイルが必要です';

  @override
  String get vibe_export_noEmbeddableData => '埋め込み可能なデータがありません';

  @override
  String vibe_export_embedSuccess(int count) {
    return '$count 件の Vibe を画像に埋め込みました';
  }

  @override
  String get vibe_export_embedFailed => '埋め込みに失敗しました';

  @override
  String get vibe_embedToImage => '画像に埋め込む';

  @override
  String get vibe_import_skip => 'スキップ';

  @override
  String get vibe_import_confirm => '確認';

  @override
  String get vibe_import_noEncodingData => 'エンコード データがありません';

  @override
  String get vibe_import_encodingCost => 'エンコードには 2 Anlas を消費します';

  @override
  String get vibe_import_confirmCost => '続けて Anlas を消費しますか?';

  @override
  String get vibe_import_encodeNow => 'すぐにエンコードします (2 Anlas)';

  @override
  String get vibe_addImageOnly => '画像のみを追加';

  @override
  String get vibe_import_autoSave => 'ライブラリに自動保存';

  @override
  String get vibe_import_encodingFailed => 'エンコードに失敗しました';

  @override
  String get vibe_import_encodingFailedMessage =>
      'Vibe のエンコードに失敗しました。未エンコードの画像を追加し続けますか？';

  @override
  String get vibe_import_encodingInProgress => 'エンコード中...';

  @override
  String get vibe_import_encodingComplete => 'エンコードが完了しました';

  @override
  String get vibe_import_partialFailed => '部分的なエンコードに失敗しました';

  @override
  String get vibe_import_timeout => 'エンコードのタイムアウト';

  @override
  String get vibe_import_title => 'ライブラリからインポート';

  @override
  String vibe_import_result(int count) {
    return '$count 件の Vibe をインポートしました';
  }

  @override
  String get vibe_import_fileParseFailed => 'ファイルの解析に失敗しました';

  @override
  String get vibe_import_fileSelectionFailed => 'ファイルの選択に失敗しました';

  @override
  String get vibe_import_importFailed => 'インポートに失敗しました';

  @override
  String get vibe_import_bundleTitle => 'Vibe バンドルをインポート';

  @override
  String get vibe_import_bundleChooseMethod => 'インポート方法を選択してください';

  @override
  String get vibe_import_bundleAsWhole => '全体としてインポート';

  @override
  String get vibe_import_bundleAsWholeDescription =>
      'バンドル構造を保持し、1 つのライブラリ エントリとしてインポートします';

  @override
  String get vibe_import_bundleSplitEntries => '個別のエントリに分割';

  @override
  String get vibe_import_bundleSplitEntriesDescription =>
      '各 Vibe を個別のライブラリエントリとしてインポートします';

  @override
  String get vibe_import_bundleSelectVibes => 'インポートする Vibe を選択してください';

  @override
  String get vibe_import_bundleSelectVibesDescription =>
      '選択した Vibe のみをインポートします';

  @override
  String get vibe_import_bundleConfigureEachVibe => '各 Vibe のパラメータを設定します';

  @override
  String get vibe_import_bundleSelectAndConfigureEachVibe =>
      '各 Vibe のパラメータを選択して設定します';

  @override
  String vibe_import_bundleSelectedCount(int selected, int total) {
    return '$selected/$total が選択されました';
  }

  @override
  String get vibe_saveToLibrary_title => 'ライブラリに保存';

  @override
  String get vibe_saveToLibrary_strength => '強度';

  @override
  String get vibe_saveToLibrary_infoExtracted => '抽出情報';

  @override
  String vibe_saveToLibrary_saving(int count) {
    return '$count 件の Vibe を保存しています';
  }

  @override
  String get vibe_saveToLibrary_saveFailed => 'ライブラリへの保存に失敗しました';

  @override
  String vibe_saveToLibrary_savingCount(int count) {
    return '$count 件の Vibe を保存しています';
  }

  @override
  String get vibe_saveToLibrary_nameLabel => '名前';

  @override
  String get vibe_saveToLibrary_nameHint => 'Vibe 名を入力してください';

  @override
  String vibe_saveToLibrary_mixed(int saved, int reused) {
    return '保存 $saved、再利用 $reused';
  }

  @override
  String vibe_saveToLibrary_saved(int count) {
    return '$count をライブラリに保存しました';
  }

  @override
  String vibe_saveToLibrary_reused(int count) {
    return 'ライブラリから $count を再利用しました';
  }

  @override
  String get vibe_saveToLibrary_saveAsBundle => 'バンドルとして保存';

  @override
  String vibe_saveToLibrary_saveAsBundleDescription(int count) {
    return '$count 件の Vibe を 1 つのバンドルとして保存';
  }

  @override
  String get vibe_saveToLibrary_tagHint => 'タグを入力して、[追加] を押します';

  @override
  String get vibe_maxReached => '最大 16 件の Vibe に達しました';

  @override
  String vibe_addedCount(int count) {
    return '$count 件の Vibe を追加しました';
  }

  @override
  String get vibe_statusEncoded => 'エンコード済み';

  @override
  String get vibe_statusEncoding => 'エンコード中...';

  @override
  String get vibe_statusPendingEncode => 'エンコード (2 Anlas)';

  @override
  String get vibe_encodeDialogTitle => 'Vibe エンコーディングを確認する';

  @override
  String get vibe_encodeDialogMessage => 'この画像を生成のためにエンコードしますか?';

  @override
  String get vibe_encodeCostWarning => 'これには 2 Anlas (クレジット) かかります';

  @override
  String get vibe_encodeButton => 'エンコード';

  @override
  String get vibe_encodeSuccess => 'Vibe は正常にエンコードされました。';

  @override
  String get vibe_encodeFailed => 'Vibe エンコードに失敗しました。再試行してください。';

  @override
  String vibe_encodeError(String error) {
    return 'エンコードに失敗しました: $error';
  }

  @override
  String get shortcuts_customize => 'ショートカットをカスタマイズする';

  @override
  String get selection_clear_selection => '選択をクリア';

  @override
  String get selection_invert_selection => '選択範囲を反転';

  @override
  String get selection_cut_to_layer => 'レイヤーにカット';

  @override
  String get search_results => '検索結果';

  @override
  String get search_noResults => '一致する結果はありません';

  @override
  String get addToCurrent => '現在に追加';

  @override
  String get replaceExisting => '既存のものを置き換えます';

  @override
  String get confirmSelection => '選択を確認';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get clearSelection => 'クリア';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 詳細';

  @override
  String get shortcut_action_vibe_detail_rename => '名前の変更';

  @override
  String get vibeSelectorFilterFavorites => 'お気に入り';

  @override
  String get vibeSelectorFilterSourceAll => 'すべてのタイプ';

  @override
  String get vibeSelectorSortCreated => '作成されました';

  @override
  String get vibeSelectorSortLastUsed => '最後に使用したもの';

  @override
  String get vibeSelectorSortUsedCount => '使用回数';

  @override
  String get vibeSelectorSortName => '名前';

  @override
  String vibeSelectorItemsCount(int count) {
    return '$count アイテム';
  }

  @override
  String get tray_show => 'ウィンドウを表示';

  @override
  String get tray_exit => '終了';

  @override
  String get settings_shortcutsSubtitle => 'キーボード ショートカットをカスタマイズする';

  @override
  String get settings_openFolder => 'フォルダーを開く';

  @override
  String get settings_openFolderFailed => 'フォルダーを開けませんでした';

  @override
  String get settings_vibePathSaved => 'バイブライブラリのパスを保存しました';

  @override
  String get settings_selectFolderFailed => 'フォルダーの選択に失敗しました';

  @override
  String get settings_hivePathSaved => 'データ ストレージ パスが保存され、再起動後に有効になります';

  @override
  String get settings_restartRequiredTitle => '再起動が必要です';

  @override
  String get settings_changePathConfirm =>
      'データ ストレージ パスを変更した後、反映するにはアプリの再起動が必要です。\\n\\n新しいパスは次回起動時に有効になります。続行しますか？';

  @override
  String get settings_resetPathConfirm =>
      'データ ストレージ パスをリセットした後、反映するにはアプリの再起動が必要です。\\n\\nデフォルトのパスは次回起動時に有効になります。続行しますか？';

  @override
  String get settings_kritaBridgeEnable => 'ローカル接続を有効にする';

  @override
  String get settings_kritaBridgeDisabledText =>
      'デフォルトではオフ。有効にするとローカル 127.0.0.1 でのみリッスンします';

  @override
  String get settings_kritaBridgeStartingText => 'ローカル ブリッジ サービスを開始しています...';

  @override
  String get settings_kritaBridgeListeningText => '外部 Agent または Krita の接続待ち';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita プラグインが接続されました';

  @override
  String get settings_kritaBridgeErrorText => '起動に失敗しました。エラー メッセージを確認してください。';

  @override
  String get settings_kritaBridgeDisabled => '無効';

  @override
  String get settings_kritaBridgeStarting => '開始中';

  @override
  String get settings_kritaBridgeListening => 'リスニング';

  @override
  String get settings_kritaBridgeConnected => '接続されました';

  @override
  String get settings_kritaBridgeError => 'エラー';

  @override
  String get settings_kritaBridgeRegenerateSession => 'セッションを再生成';

  @override
  String get settings_kritaBridgeDiscoveryFile => '検出ファイル';

  @override
  String get settings_kritaBridgeWaitingEndpoint =>
      'ローカル WebSocket リスナーを待機しています';

  @override
  String settings_kritaBridgeClient(Object client) {
    return 'クライアント: $client';
  }

  @override
  String get settings_fontScale => 'フォント サイズ';

  @override
  String get settings_fontScale_previewSmall => '光影落在画布上。';

  @override
  String get settings_fontScale_previewMedium => '色から物語が生まれる。';

  @override
  String get settings_fontScale_previewLarge => 'Let colors tell a story.';

  @override
  String get settings_fontScale_done => '完了';

  @override
  String get settings_historyClickBehavior => '履歴クリックの動作';

  @override
  String get settings_historyClickBehavior_classic => 'クラシック';

  @override
  String get settings_historyClickBehavior_classicDescription =>
      '履歴画像をクリックして詳細を開きます';

  @override
  String get settings_historyClickBehavior_linked => 'プレビュー連動';

  @override
  String get settings_historyClickBehavior_linkedDescription =>
      'クリックで中央プレビューを切り替え、ダブルクリックまたは長押しで詳細を開き、左右キーで移動します';

  @override
  String get settings_outputViewer => '出力ビューア';

  @override
  String get settings_outputViewer_canvas => 'フリーキャンバス';

  @override
  String get settings_outputViewer_canvasDescription =>
      'NAI5 風の無限キャンバス：生成画像をバッチごとに配置、中ボタン/Shift+左ドラッグでパン、Ctrl+ホイールでズーム、WASD/f/q で移動';

  @override
  String get settings_outputViewer_simple => 'シンプルビュー';

  @override
  String get settings_outputViewer_simpleDescription =>
      '従来の中央/グリッドプレビュー。低スペックや慣れたレイアウト向け';

  @override
  String get settings_canvasLockCamera => 'キャンバスカメラをロック';

  @override
  String get settings_canvasLockCameraDescription =>
      'ホイールズーム/パン、ドラッグ、WASD など手動カメラ入力を無効化。自動選択とジャンプは有効';

  @override
  String get settings_canvasReducedMotion => 'キャンバスモーションを削減';

  @override
  String get settings_canvasReducedMotionDescription =>
      '飛行・ズーム・慣性を瞬時切替にし、アニメーションを抑える';

  @override
  String get image_viewDetail => '詳細を表示';

  @override
  String get settings_defaultImagesPath =>
      'デフォルト (Documents/NAI_Launcher/images/)';

  @override
  String get settings_defaultHivePath => 'デフォルト (%APPDATA%/NAI_Launcher/hive/)';

  @override
  String get settings_protectionFeatures => '保護機能';

  @override
  String get settings_stripMetadataTitle => 'コピーまたはドラッグするときにすべてのメタデータを削除します';

  @override
  String get settings_stripMetadataSubtitle =>
      'サニタイズされたコピーを作成し、PNG テキスト チャンク、EXIF、および NAI ステガノグラフィック透かしデータを削除し、ドラッグ中に元のパスが露出しないようにします。';

  @override
  String get settings_confirmDangerousActionsTitle => '危険な資産のアクションを再確認する';

  @override
  String get settings_confirmDangerousActionsSubtitle =>
      'ローカル アセットを削除、移動、またはバッチ移動すると、追加の保護の確認が表示されます。';

  @override
  String get settings_warnExternalImageSendTitle => '外部サービスに送信する前に確認してください';

  @override
  String get settings_warnExternalImageSendSubtitle =>
      'ローカル画像がアプリの境界を越えて LLM、NovelAI、ComfyUI、または同様のサービスに到達する前に確認してください。';

  @override
  String get settings_preventOverwriteTitle => 'エクスポート時に既存のファイルを上書きしないようにします';

  @override
  String get settings_preventOverwriteSubtitle =>
      '既存のアセットを誤って置き換えることを避けるために、重複するエクスポートまたはパッケージのパスに自動的に番号を付けます。';

  @override
  String get settings_warnHighAnlasCostTitle => 'Anlas コストが高いという警告';

  @override
  String settings_warnHighAnlasCostSubtitle(Object threshold) {
    return '単一リクエストの推定コストが $threshold Anlas に達したときに、生成前に確認を表示します。';
  }

  @override
  String get settings_highAnlasCostThresholdTitle => 'Anlas 警告しきい値';

  @override
  String get settings_setHighAnlasCostThresholdTitle => 'Anlas 警告しきい値を設定';

  @override
  String get settings_threshold => 'しきい値';

  @override
  String get settings_highAnlasCostThresholdHelper =>
      '1 回の生成にかかる推定コストがこの値以上になった場合に確認を表示します。';

  @override
  String get settings_limitGenerationIntervalTitle => '画像生成の頻度を制限';

  @override
  String get settings_limitGenerationIntervalSubtitle =>
      '画像生成の開始間隔を設定値以上に制限します。クールダウン中は生成ボタンを使用できません。';

  @override
  String get settings_generationIntervalTitle => '画像生成の間隔';

  @override
  String settings_generationIntervalValue(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get settings_setGenerationIntervalTitle => '画像生成の間隔を設定';

  @override
  String get settings_generationIntervalHelper =>
      '1～3600 秒で設定できます。画像生成の開始時から計測します。';

  @override
  String get settings_generationIntervalJitterTitle => '間隔ランダムジッター';

  @override
  String settings_generationIntervalJitterValue(Object percent) {
    return '±$percent%';
  }

  @override
  String get settings_setGenerationIntervalJitterTitle => '間隔ジッターを設定';

  @override
  String get settings_generationIntervalJitterHelper =>
      '各クールダウンは「基準間隔 ± この割合」の範囲でランダムに決まり、生成ペースが機械的になりにくくなります。0～50 で設定、0 で無効になります。';

  @override
  String get settings_confirmExternalSendTitle => '保護モード: 外部送信の確認';

  @override
  String settings_confirmExternalSendContent(Object count, Object target) {
    return '$count 枚のローカル画像を $target に送信しようとしています。画像データはローカル アプリの外部に送信されます。これが想定どおりであることを確認してください。';
  }

  @override
  String get settings_confirmExternalSend => '送信';

  @override
  String get settings_highAnlasCostTitle => 'Anlas 消費の確認';

  @override
  String settings_highAnlasCostContent(Object cost, Object threshold) {
    return 'このリクエストには $cost Anlas の費用がかかると推定されており、$threshold Anlas の警告しきい値に達するか超えています。生成を継続しますか?';
  }

  @override
  String get settings_continueGeneration => '生成を続行';

  @override
  String get dataSource_syncNow => '今すぐ同期';

  @override
  String get settings_comfyUiEnable => 'ComfyUI 統合を有効にする';

  @override
  String get settings_comfyUiDisabledSubtitle =>
      '無効にすると、ローカル拡大およびその他の ComfyUI 機能が非表示になります';

  @override
  String get settings_comfyUiServerUrl => 'サーバー URL';

  @override
  String get settings_comfyUiConnectionSuccess => '接続に成功しました';

  @override
  String get settings_comfyUiConnectionSuccessFull => 'ComfyUI への接続に成功しました';

  @override
  String settings_comfyUiConnectionFailed(Object error) {
    return '接続に失敗しました: $error';
  }

  @override
  String get settings_comfyUiConnected => '接続されました';

  @override
  String get settings_comfyUiDisconnect => '切断';

  @override
  String get settings_comfyUiWorkflowManagement => 'ワークフロー管理';

  @override
  String get settings_comfyUiBuiltinWorkflows => '組み込みワークフロー';

  @override
  String get settings_comfyUiCustomWorkflows => 'カスタム ワークフロー';

  @override
  String get settings_comfyUiNoCustomWorkflows =>
      'カスタム ワークフローはまだありません。 「インポート」をクリックして ComfyUI ワークフローを追加します。';

  @override
  String settings_comfyUiSlotCount(Object count) {
    return '$count スロット';
  }

  @override
  String get settings_comfyUiBuiltin => '内蔵';

  @override
  String get settings_comfyUiDeleteWorkflowTitle => 'ワークフローの削除';

  @override
  String settings_comfyUiDeleteWorkflowContent(Object name) {
    return 'ワークフロー「$name」を削除しますか?これを元に戻すことはできません。';
  }

  @override
  String settings_comfyUiDeleted(Object name) {
    return '削除されました: $name';
  }

  @override
  String get settings_comfyUiNoResponse => 'サーバーが応答しませんでした';

  @override
  String get settings_comfyUiStatusDisconnected => '切断されました';

  @override
  String get settings_comfyUiStatusConnecting => '接続中...';

  @override
  String get settings_comfyUiStatusConnected => '接続されました';

  @override
  String get settings_comfyUiStatusError => '接続エラー';

  @override
  String get settings_comfyUiCategoryEnhance => '品質向上/拡大';

  @override
  String get settings_comfyUiCategoryImg2Img => 'Image2Image';

  @override
  String get settings_comfyUiCategoryInpaint => 'インペイント';

  @override
  String get settings_comfyUiCategoryTxt2Img => 'テキストから画像へ';

  @override
  String get settings_comfyUiCategoryCustom => 'カスタム';

  @override
  String get comfyWorkflow_seedvr2UpscaleName => 'SeedVR2 拡大';

  @override
  String get comfyWorkflow_seedvr2UpscaleDescription =>
      'SeedVR2 AI モデルで拡大します。高品質な結果を生成します。';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleName => 'SeedVR2 タイル拡大';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleDescription =>
      '大きな画像の VRAM 負荷を軽減するため、タイル状の拡大に SeedVR2TilingUpscaler を使用します。';

  @override
  String get comfyWorkflow_modelUpscaleName => 'ComfyUI 標準拡大モデル';

  @override
  String get comfyWorkflow_modelUpscaleDescription =>
      'ComfyUI UpscaleModelLoader で標準の拡大モデルをロードし、Lanczos で最終スケールを修正します。';

  @override
  String get comfyWorkflow_rtxUpscaleName => 'RTX 拡大';

  @override
  String get comfyWorkflow_rtxUpscaleDescription =>
      'ローカル拡大には Nvidia RTX ビデオ超解像度ノードを使用します。';

  @override
  String get comfyWorkflowSlot_inputImage => '入力画像';

  @override
  String get comfyWorkflowSlot_targetShortSide => 'ターゲット短辺';

  @override
  String get comfyWorkflowSlot_targetLongSide => 'ターゲット長辺';

  @override
  String get comfyWorkflowSlot_upscaleModel => '拡大モデル';

  @override
  String get comfyWorkflowSlot_randomSeed => 'ランダムシード';

  @override
  String get comfyWorkflowSlot_outputImage => '出力画像';

  @override
  String get comfyWorkflowSlot_tileWidth => 'タイルの幅';

  @override
  String get comfyWorkflowSlot_tileHeight => 'タイルの高さ';

  @override
  String get comfyWorkflowSlot_tileUpscaleResolution => 'タイル拡大解像度';

  @override
  String get comfyWorkflowSlot_targetWidth => 'ターゲット幅';

  @override
  String get comfyWorkflowSlot_targetHeight => '目標高さ';

  @override
  String get comfyWorkflowSlot_scale => 'スケール';

  @override
  String get comfyWorkflow_parameters => 'パラメータ';

  @override
  String get comfyWorkflow_selectImage => 'クリックして画像を選択してください';

  @override
  String comfyWorkflow_pickImageFailed(Object error) {
    return '画像の選択に失敗しました: $error';
  }

  @override
  String get comfyWorkflow_useResult => '結果を使用';

  @override
  String get comfyWorkflow_execute => '実行';

  @override
  String get comfyWorkflow_uploadingImage => '画像をアップロードしています...';

  @override
  String get comfyWorkflow_queued => 'キューに入れられました...';

  @override
  String comfyWorkflow_runningSteps(Object current, Object total) {
    return '$current/$total を処理しています';
  }

  @override
  String get comfyWorkflow_processing => '処理中...';

  @override
  String get comfyWorkflow_complete => '完了';

  @override
  String comfyWorkflow_imageCount(Object count) {
    return '$count 画像';
  }

  @override
  String get cacheStats_title => 'キャッシュ統計';

  @override
  String cacheStats_autoRefreshUpdated(Object time) {
    return '自動更新 · 最終更新日: $time';
  }

  @override
  String cacheStats_secondsAgo(Object seconds) {
    return '$seconds 秒前';
  }

  @override
  String get cacheStats_resetStats => '統計をリセット';

  @override
  String get cacheStats_statsReset => '統計をリセットしました';

  @override
  String get cacheStats_l1Memory => 'L1 メモリ キャッシュ';

  @override
  String get cacheStats_l2Hive => 'L2 Hive キャッシュ';

  @override
  String get cacheStats_l3Sqlite => 'L3 SQLite データベース';

  @override
  String get galleryCache_rescanTitle => 'ギャラリーを再スキャン';

  @override
  String get galleryCache_rescanContent =>
      'これにより、次のことが行われます。\n\n1. データの整合性をチェックし、不足しているファイルにマークを付ける\n2. 新しいファイルと変更されたファイルをスキャンします\n3. 失敗したレコードを含め、以前に失敗したメタデータ抽出を再試行します。\n\nこれにより、既存のデータが消去されたり、画像ファイルが削除されたりすることはありません。';

  @override
  String get galleryCache_startScan => 'スキャンの開始';

  @override
  String get galleryCache_scanAlreadyRunning =>
      'スキャン タスクはすでに実行中です。完了するまでお待ちください。';

  @override
  String get galleryCache_preparing => '準備中...';

  @override
  String get galleryCache_noGalleryFolder => 'ギャラリーフォルダーが設定されていません';

  @override
  String galleryCache_scanningPhase(Object processed, Object total) {
    return '$processed/$total をスキャンしています...';
  }

  @override
  String get galleryCache_scanComplete => 'スキャンが完了しました';

  @override
  String galleryCache_scanFailed(Object error) {
    return 'スキャンに失敗しました: $error';
  }

  @override
  String get galleryCache_rescan => '再スキャン';

  @override
  String get galleryCache_rescanSubtitle =>
      'データの整合性をチェックし、欠落しているファイルを見つけて、メタデータを抽出します';

  @override
  String get galleryCache_scanning => 'スキャン中...';

  @override
  String get galleryCache_scanAction => 'スキャン';

  @override
  String get galleryCache_evictThumbnailsTitle => 'サムネイルキャッシュを整理';

  @override
  String get galleryCache_evictThumbnailsSubtitle =>
      '上限を超えた .thumbs を最終使用順に削除（元画像は対象外）';

  @override
  String get galleryCache_evictThumbnailsContent =>
      '上限を超えたディスク上のサムネイルキャッシュを、最後に使用された順に削除します。\n\n削除するのは .thumbs ディレクトリ内の .thumb.jpg のみで、元画像には一切触れません。削除されたサムネイルは次回閲覧時に再生成されます。';

  @override
  String get galleryCache_evictThumbnailsStart => '整理を開始';

  @override
  String get galleryCache_evictThumbnailsRunning => 'サムネイルキャッシュを整理しています...';

  @override
  String galleryCache_evictThumbnailsDone(int count, String size) {
    return '$count 件のサムネイルを削除し、$size MB を解放しました';
  }

  @override
  String get galleryCache_evictThumbnailsNone => 'サムネイルキャッシュは上限以内です。整理は不要です';

  @override
  String galleryCache_evictThumbnailsFailed(Object error) {
    return 'サムネイルキャッシュの整理に失敗しました: $error';
  }

  @override
  String get workflowImport_title => 'ComfyUI ワークフローのインポート';

  @override
  String workflowImport_step(Object current, Object title) {
    return 'ステップ $current/4: $title';
  }

  @override
  String get workflowImport_stepFile => 'ワークフロー ファイルの選択';

  @override
  String get workflowImport_stepInfo => 'ワークフロー情報';

  @override
  String get workflowImport_stepSlots => 'スロット構成の確認';

  @override
  String get workflowImport_stepDone => 'インポート完了';

  @override
  String get workflowImport_previous => '前へ';

  @override
  String get workflowImport_next => '次へ';

  @override
  String get workflowImport_finish => 'インポートを完了する';

  @override
  String get workflowImport_defaultName => 'カスタム ワークフロー';

  @override
  String get workflowImport_fileInstructions =>
      'ComfyUI からエクスポートされた workflow_api.json ファイルを選択します。\n\nComfyUI でメニューを開き、[エクスポート (API 形式)] を選択してこのファイルを取得します。';

  @override
  String workflowImport_nodeCount(Object count) {
    return '$count ノード';
  }

  @override
  String get workflowImport_reselect => 'クリックして別のファイルを選択してください';

  @override
  String get workflowImport_selectWorkflowApi =>
      'クリックして workflow_api.json を選択します';

  @override
  String get workflowImport_invalidTopLevel =>
      '無効なファイル形式: 最上位は JSON オブジェクトである必要があります';

  @override
  String get workflowImport_noComfyNodes =>
      'ComfyUI ノードが検出されませんでした。これが API 形式のエクスポートであることを確認してください。';

  @override
  String workflowImport_readFailed(Object error) {
    return 'ファイルの読み取りに失敗しました: $error';
  }

  @override
  String get workflowImport_analysisResult => '自動解析結果';

  @override
  String get workflowImport_inputImageNodes => '入力画像ノード';

  @override
  String get workflowImport_adjustableParams => '調整可能なパラメータ';

  @override
  String get workflowImport_outputNodes => '出力ノード';

  @override
  String get workflowImport_totalNodes => '合計ノード数';

  @override
  String workflowImport_countUnit(Object count) {
    return '$count';
  }

  @override
  String get workflowImport_workflowName => 'ワークフロー名 *';

  @override
  String get workflowImport_description => '説明';

  @override
  String get workflowImport_category => 'カテゴリ';

  @override
  String get workflowImport_slotsHint =>
      'UI で公開するスロットを選択します。通常、入力スロットと出力スロットは有効のままにしておく必要があります。ユーザーが調整する必要のないパラメータは無効にすることができます。';

  @override
  String get workflowImport_inputSection => '入力';

  @override
  String get workflowImport_outputSection => '出力';

  @override
  String get workflowImport_parameterSection => 'パラメータ';

  @override
  String get workflowImport_noSlotsWarning =>
      '使用可能なスロットが検出されませんでした。このワークフローは正しく統合されない可能性があります。\nワークフローに LoadImage ノードと SaveImage/SaveImageWebsocket ノードが含まれていることを確認してください。';

  @override
  String workflowImport_nodeRef(Object node) {
    return 'ノード $node';
  }

  @override
  String get workflowImport_confirmTitle => 'このワークフローをインポートしようとしています';

  @override
  String get workflowImport_name => '名前';

  @override
  String get workflowImport_inputSlots => '入力スロット';

  @override
  String get workflowImport_parameterSlots => 'パラメータスロット';

  @override
  String get workflowImport_outputSlots => '出力スロット';

  @override
  String get workflowImport_afterImportHint =>
      'インポート後、生成画面のComfyUIワークフロー一覧から利用可能になります。';

  @override
  String workflowImport_success(Object name) {
    return 'ワークフロー「$name」がインポートされました';
  }

  @override
  String get shortcut_settings_help => 'ショートカットのヘルプを表示';

  @override
  String get shortcut_settings_show_in_menus => 'メニューに表示';

  @override
  String shortcut_settings_defaultShortcut(Object shortcut) {
    return 'デフォルト: $shortcut';
  }

  @override
  String get shortcut_settings_unassigned => '未設定';

  @override
  String get shortcut_settings_no_matches => '一致するショートカットが見つかりません';

  @override
  String get shortcut_settings_reset_all_title => 'すべてのショートカットをリセット';

  @override
  String get shortcut_settings_reset_all_confirm =>
      'すべてのショートカットをデフォルト設定にリセットしますか?これを元に戻すことはできません。';

  @override
  String get shortcut_settings_reset_to_default => 'デフォルトにリセット';

  @override
  String get toast_previewUpdated => 'プレビュー画像が更新されました';

  @override
  String toast_styleReferenceLimit(Object max) {
    return '絵柄参照が上限に達しました ($max 画像)';
  }

  @override
  String get toast_noValidMaskIgnored => '有効なマスクが検出されませんでした。保存結果は無視されました。';

  @override
  String get toast_kritaBusy => 'Krita Bridge が生成されています。現在のタスクが完了するまで待ちます。';

  @override
  String get toast_kritaNotConnected =>
      'Krita が接続されていません。設定でブリッジを有効にし、最初にプラグインを接続します。';

  @override
  String get toast_sentToKrita => '画像が Krita に送信されました';

  @override
  String get toast_kritaUnsupportedImageFormat =>
      'この画像形式は Krita に送信できません。一般的な画像形式を使用します。';

  @override
  String toast_deletedNamed(Object name) {
    return '削除されました: $name';
  }

  @override
  String get toast_vibeParamSaveReencodeFailed =>
      'Vibe の再エンコードに失敗したため、パラメーターを保存できませんでした';

  @override
  String get toast_exportSuccess => 'エクスポートが成功しました';

  @override
  String toast_exportFailed(Object error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get toast_selectVibeToExport => '先にエクスポートする Vibe を選択してください';

  @override
  String get toast_embedPngSingleVibeOnly =>
      'PNG への埋め込みでは、1 つの Vibe のエクスポートのみがサポートされます';

  @override
  String get toast_selectPngCarrier => 'エクスポートする PNG キャリア画像を選択してください';

  @override
  String get toast_renameSuccess => '名前が正常に変更されました';

  @override
  String get toast_paramsSaved => 'パラメータが保存されました';

  @override
  String get toast_paramsSaveFailed => 'パラメータの保存に失敗しました';

  @override
  String get toast_dropNoReadableImageOrVibe =>
      'ドロップ ソースは読み取り可能な画像または Vibe ファイルを提供しませんでした';

  @override
  String get toast_contentCannotBeEmpty => 'コンテンツを空にすることはできません';

  @override
  String get toast_addedToLibrary => 'ライブラリに追加されました';

  @override
  String toast_addFailed(Object error) {
    return '追加に失敗しました: $error';
  }

  @override
  String get toast_libraryNotLoaded => 'ライブラリがロードされていません';

  @override
  String get toast_noValidTagContent => '有効なタグの内容がありません';

  @override
  String get toast_allTagsAlreadyExist => 'すべてのタグはすでにライブラリに存在します';

  @override
  String get toast_noAddableTags => 'タグは追加できません';

  @override
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped) {
    return '$added タグを追加し、$skipped 重複タグをスキップしました';
  }

  @override
  String get toast_favorited => 'お気に入りに登録しました';

  @override
  String get toast_unfavorited => 'お気に入りから削除しました';

  @override
  String toast_favoriteUpdateFailed(Object error) {
    return 'お気に入りの状態を更新できませんでした: $error';
  }

  @override
  String toast_packingImages(Object count) {
    return '$count 個の画像をパッキングしています...';
  }

  @override
  String toast_packedImages(Object count) {
    return '$count 個の画像をパックしました';
  }

  @override
  String get toast_packFailed => 'パックに失敗しました';

  @override
  String toast_packFailedWithError(Object error) {
    return 'パックに失敗しました: $error';
  }

  @override
  String get toast_saveDirNotSet => '保存ディレクトリが設定されていません';

  @override
  String toast_savedTo(Object path) {
    return '$path に保存されました';
  }

  @override
  String get toast_tagAlreadyExists => 'タグはすでに存在します';

  @override
  String get toast_nameRequired => '名前を入力してください';

  @override
  String get toast_savedToVibeLibrary => 'バイブライブラリに保存しました';

  @override
  String get toast_saveBundleFailed => 'バンドルの保存に失敗しました';

  @override
  String get toast_saveEntryFailed => 'エントリの保存に失敗しました';

  @override
  String get toast_imagePromptCopied => 'プロンプトがコピーされました';

  @override
  String get toast_imageHasNoPrompt => 'この画像にはプロンプトがありません';

  @override
  String get toast_useDeleteButton => 'UI の削除ボタンを使用します。';

  @override
  String get toast_imageDataUnavailable => '画像データが利用できないため、コピーできません';

  @override
  String get toast_vibeDataCopied => 'Vibe データをコピーしました';

  @override
  String get toast_tagCopied => 'タグがコピーされました';

  @override
  String get toast_characterPromptCopied => 'キャラクタープロンプトをコピーしました';

  @override
  String toast_copiedTitle(Object title) {
    return '$title がコピーされました';
  }

  @override
  String toast_replacedVibesCount(Object count, Object name) {
    return '$count 件の Vibe を置換しました: $name';
  }

  @override
  String toast_sentVibesCount(Object count, Object name) {
    return '$count 件の Vibe を生成に送信しました: $name';
  }

  @override
  String toast_replacedVibe(Object name) {
    return '$name に置き換えました';
  }

  @override
  String toast_sentVibeToGeneration(Object name) {
    return '生成に送信しました: $name';
  }

  @override
  String get toast_unreadableDroppedImageSource =>
      'ドロップ ソースは読み取り可能な画像ファイルまたは画像 URL を提供しませんでした';

  @override
  String toast_appendedStyleReferences(Object count) {
    return '$count 件の絵柄参照を追加しました';
  }

  @override
  String get toast_appendedPreencodedVibe => '1 つの絵柄参照を追加 (事前にエンコード済みのバイブを再利用)';

  @override
  String get toast_addedPreencodedVibe =>
      '絵柄参照を追加しました (事前にエンコード済みのバイブを再利用し、2 Anlas を節約)';

  @override
  String toast_vibesMissingEncoding(Object count) {
    return '$count 件の Vibe にはエンコード済みデータがないため保存できません';
  }

  @override
  String toast_savedBundle(Object count) {
    return 'バンドルを保存しました ($count 件の Vibe)';
  }

  @override
  String toast_extractMetadataFailed(Object error) {
    return 'メタデータの抽出に失敗しました: $error';
  }

  @override
  String get toast_renameNameRequired => '名前は必須です';

  @override
  String get toast_renameNameConflict => '名前はすでに存在します。別の名前を使用してください。';

  @override
  String get toast_renameEntryNotFound => 'エントリはもう存在しないため、削除された可能性があります';

  @override
  String get toast_renameFilePathMissing => 'このエントリにはファイル パスがないため、名前を変更できません';

  @override
  String get toast_renameFileFailed => 'ファイル名の変更に失敗しました。後でもう一度試してください。';

  @override
  String get toast_renameFailed => '名前の変更に失敗しました。後でもう一度試してください。';

  @override
  String toast_processImageFailed(Object error) {
    return '画像の処理に失敗しました: $error';
  }

  @override
  String get toast_savePreviewFailed => 'プレビュー画像の保存に失敗しました';

  @override
  String get common_justNow => 'たった今';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes 分前';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours 時間前';
  }

  @override
  String get common_saving => '保存中...';

  @override
  String get common_pleaseWait => 'お待ちください';

  @override
  String get common_change => '変更';

  @override
  String get common_expand => '展開する';

  @override
  String get common_collapse => '折りたたむ';

  @override
  String get vibeLibrary_emptySearchTitle => '一致する Vibe がありません';

  @override
  String get vibeLibrary_emptySearchSubtitle => '別のキーワードを試してください';

  @override
  String get vibeLibrary_emptyFavoritesTitle => 'お気に入りの Vibe はまだありません';

  @override
  String get vibeLibrary_emptyFavoritesSubtitle =>
      'ハートのアイコンをクリックして Vibe をお気に入りに追加します';

  @override
  String get vibeLibrary_emptyCategoryTitle => 'このカテゴリには Vibe がありません';

  @override
  String get vibeLibrary_emptyCategorySubtitle =>
      'すべてのエントリを表示するには「すべての Vibe」に切り替えてください';

  @override
  String get vibeLibrary_emptyNoMatchesTitle => '一致する結果はありません';

  @override
  String get vibeLibrary_emptySaveFromGenerationHint =>
      '生成ページから Vibe を保存してライブラリに追加します';

  @override
  String get vibe_nameRequired => '名前は必須です';

  @override
  String get vibe_import_namingTitle => 'Vibe に名前を付ける';

  @override
  String get vibe_import_nameConflictOverwrite => 'この名前はすでに存在するため上書きされます';

  @override
  String get vibe_previewLoadFailed => 'プレビューのロードに失敗しました';

  @override
  String get vibe_import_applyToRemainingFiles => '残りのすべてのファイルに適用します';

  @override
  String get vibe_import_applyNamingToRemainingFiles => '残りのファイルにはこの命名規則を使用します';

  @override
  String get vibe_encodeImageTitle => '画像を Vibe としてエンコード';

  @override
  String get vibe_imagePreview => '画像プレビュー';

  @override
  String get vibe_encodeStartButton => 'エンコードの開始';

  @override
  String get vibe_encodeImageInProgress => '画像をエンコード中...';

  @override
  String vibe_encodeErrorImage(Object fileName) {
    return '画像: $fileName';
  }

  @override
  String vibe_encodeErrorMessage(Object error) {
    return 'エラー: $error';
  }

  @override
  String get vibe_encodeSkipImage => 'この画像をスキップ';

  @override
  String get detail_sendToImg2Img => 'Image2Image に送信';

  @override
  String get detail_loadingImage => '画像を読み込み中...';

  @override
  String get detail_imageLoadFailed => '画像のロードに失敗しました';

  @override
  String get detail_noImage => '画像がありません';

  @override
  String get detail_parsingMetadata => 'メタデータを解析しています...';

  @override
  String get detail_noMetadata => 'この画像にはメタデータがありません';

  @override
  String get detail_metadata => 'メタデータ';

  @override
  String get detail_imageDetails => '画像の詳細';

  @override
  String get detail_basicInfo => '基本情報';

  @override
  String get detail_fileName => 'ファイル名';

  @override
  String get detail_modifiedTime => '更新日時';

  @override
  String get detail_fileSize => 'ファイルサイズ';

  @override
  String get detail_noContent => '(コンテンツなし)';

  @override
  String get detail_saveBlock => 'ブロックとして保存';

  @override
  String get saveBlock_title => 'ブロックとして保存';

  @override
  String get saveBlock_nameLabel => 'ブロック名';

  @override
  String get saveBlock_nameHint => 'ブロック名を入力';

  @override
  String get saveBlock_nameRequired => 'ブロック名を入力してください';

  @override
  String get saveBlock_selectContent => '保存する内容を選択してください';

  @override
  String get saveBlock_negativeSuffix => 'ネガティブ';

  @override
  String get saveBlock_saved => 'ブロックライブラリに保存しました';

  @override
  String detail_copyLabel(Object label) {
    return '$label をコピーします';
  }

  @override
  String get detail_copyCharacterPrompt => 'キャラクタープロンプトをコピー';

  @override
  String get detail_copyAllVibeData => 'すべての Vibe データをコピーします';

  @override
  String get detail_saveToVibeLibrary => 'バイブライブラリに保存';

  @override
  String get comfyImport_detectedTitle => 'ComfyUI の複数キャラクタープロンプトを検出しました';

  @override
  String comfyImport_characterList(Object count) {
    return 'キャラクター一覧 ($count)';
  }

  @override
  String get comfyImport_usePositionInfo => '位置情報を利用する';

  @override
  String get comfyImport_usePositionInfoSubtitle =>
      'ComfyUI の領域を NAI のキャラクター位置にマップします';

  @override
  String comfyImport_convertCharacters(Object count) {
    return '$count 件のキャラクターを変換';
  }

  @override
  String get comfyImport_syntaxCouple => 'COUPLE 構文';

  @override
  String get comfyImport_syntaxAndMask => 'AND+MASK 構文';

  @override
  String get comfyImport_syntaxPipe => 'パイプ形式';

  @override
  String get comfyImport_syntaxUnknown => '不明な構文です';

  @override
  String get comfyImport_globalPrompt => 'グローバル プロンプト';

  @override
  String get checkForUpdate => 'アップデートを確認してください';

  @override
  String get neverChecked => 'チェックされていません';

  @override
  String lastCheckedAt(Object time) {
    return '最終チェック日: $time';
  }

  @override
  String get includePrereleaseUpdates => 'プレリリース バージョンを含む';

  @override
  String get includePrereleaseUpdatesDescription =>
      '更新をチェックするときにベータ/アルファ バージョンを含めます';

  @override
  String get updateAvailable => 'アップデートが利用可能です';

  @override
  String get updateChecking => 'アップデートをチェックしています...';

  @override
  String get updateDownloading => 'アップデートをダウンロードしています...';

  @override
  String get updateInstalling => 'インストーラーを起動しています...';

  @override
  String get updateUpToDate => 'すでに最新です';

  @override
  String get updateError => '更新の確認に失敗しました';

  @override
  String get currentVersion => '現在のバージョン';

  @override
  String get latestVersion => '最新バージョン';

  @override
  String get releaseNotes => 'リリースノート';

  @override
  String updateDownloadingProgress(Object percent) {
    return '更新パッケージをダウンロードしています: $percent%';
  }

  @override
  String updateDownloadSizeSpeed(Object received, Object total, Object speed) {
    return '$received / $total · $speed';
  }

  @override
  String get updateDownloaded => '更新パッケージの準備ができました';

  @override
  String updateDownloadedHint(Object version) {
    return 'v$version をダウンロードし、検証が完了しました。インストールするとアプリが終了し、自動的に再起動します。';
  }

  @override
  String get updateInstallAndRestart => 'インストールして再起動';

  @override
  String get updateInstallNow => '今すぐインストール';

  @override
  String get updateInstallLater => '後でインストール';

  @override
  String get updateDownload => '更新をダウンロード';

  @override
  String get updateDownloadCancelled => 'ダウンロードをキャンセルしました。後で再開できます';

  @override
  String get updateDownloadFailed => '更新のダウンロードに失敗しました';

  @override
  String get updateInstallFailed => '更新のインストールに失敗しました';

  @override
  String get updateInstallingHint => 'インストーラーが起動しました。アプリは終了し、自動的に更新が完了します。';

  @override
  String get remindMeLater => '4時間後に通知';

  @override
  String updateNoticeAvailable(Object version) {
    return '新しいバージョン v$version があります';
  }

  @override
  String get updateNoticeAvailableSubtitle => 'アプリ内でダウンロードして自動的に更新できます';

  @override
  String get updateNoticeManualSubtitle =>
      'このプラットフォームでは Release ページから手動で更新してください';

  @override
  String updateNoticeReady(Object version) {
    return 'バージョン v$version の準備ができました';
  }

  @override
  String get updateNoticeReadySubtitle => 'パッケージは検証済みです。再起動してインストールできます';

  @override
  String get updateNoticeFailed => '前回の更新は完了しませんでした';

  @override
  String get updateViewDetails => '更新を表示';

  @override
  String updateSettingsAvailable(Object version) {
    return 'v$version が利用可能です。選択して詳細を表示';
  }

  @override
  String updateSettingsReady(Object version) {
    return 'v$version はダウンロード済みです。選択してインストール';
  }

  @override
  String get goToDownload => 'ダウンロードに移動';

  @override
  String get cannotOpenUrl => 'リンクを開けません';

  @override
  String get model3d_editorTitle => '3Dモデルレイヤー';

  @override
  String get model3d_addMannequin => '内蔵マネキンを追加';

  @override
  String get model3d_importModel => 'モデルをインポート (.glb/.gltf)';

  @override
  String get model3d_emptyHint => 'シーンは空です。マネキンを追加するかモデルをインポートしてください';

  @override
  String get model3d_apply => 'レイヤーに適用';

  @override
  String get model3d_modeTransform => '変換';

  @override
  String get model3d_modePose => 'ポーズ';

  @override
  String get model3d_gizmoTranslate => '移動';

  @override
  String get model3d_gizmoRotate => '回転';

  @override
  String get model3d_gizmoScale => '拡縮';

  @override
  String get model3d_undo => '元に戻す';

  @override
  String get model3d_resetPose => 'ポーズをリセット';

  @override
  String get model3d_replaceConfirm => '現在のモデルを置き換えますか？未適用のポーズは失われます。';

  @override
  String get model3d_discardConfirm => '未適用の変更を破棄しますか？';

  @override
  String get model3d_missingModel => 'モデルファイルが見つかりません。再インポートできます';

  @override
  String get model3d_loadError => 'モデルの読み込みに失敗しました';

  @override
  String get model3d_light => 'ライティング';

  @override
  String get model3d_lightIntensity => '強度';

  @override
  String get model3d_lightAzimuth => '方位角';

  @override
  String get model3d_lightElevation => '仰角';

  @override
  String get model3d_addLayerTooltip => '3Dモデルレイヤーを追加';

  @override
  String get model3d_webview2Missing =>
      '3DエディタにはMicrosoft Edge WebView2ランタイムが必要です。Windows 10/11には通常同梱されています。無い場合はMicrosoftからEvergreen版をインストールして再試行してください。';

  @override
  String get nav_preciseRefLibrary => '精密参照ライブラリ';

  @override
  String get preciseRefLib_title => '精密参照ライブラリ';

  @override
  String get preciseRefLib_searchHint => '参照画像を検索...';

  @override
  String get preciseRefLib_empty => 'ここに画像をドロップまたは貼り付けてライブラリを作成';

  @override
  String get preciseRefLib_emptyHint => 'プレビュー・履歴・ギャラリーで右クリックして保存もできます';

  @override
  String get preciseRefLib_import => '画像をインポート';

  @override
  String preciseRefLib_entryCount(int count) {
    return '$count 件';
  }

  @override
  String get preciseRefLib_sendToPreciseRef => '精密参照へ送る';

  @override
  String get preciseRefLib_sendToImg2Img => '画像から画像へ送る';

  @override
  String get preciseRefLib_editEntry => 'パラメータを編集';

  @override
  String get preciseRefLib_deleteEntry => '削除';

  @override
  String get preciseRefLib_confirmDeleteTitle => 'エントリを削除';

  @override
  String preciseRefLib_confirmDelete(String name) {
    return '「$name」を削除しますか？画像ファイルも削除されます。';
  }

  @override
  String preciseRefLib_saved(String name) {
    return '精密参照ライブラリに保存しました：$name';
  }

  @override
  String get preciseRefLib_savedHint => 'ライブラリでパラメータを編集できます';

  @override
  String preciseRefLib_sent(String name) {
    return '精密参照へ送信しました：$name';
  }

  @override
  String preciseRefLib_sentToImg2Img(String name) {
    return '画像から画像へ送信しました：$name';
  }

  @override
  String get preciseRefLib_imageMissing => '元画像ファイルが見つかりません';

  @override
  String get preciseRefLib_invalidImage => '画像形式を認識できないか、ファイルが破損しています';

  @override
  String get preciseRefLib_deleteFailed =>
      '削除に失敗しました。項目と元画像は保持されています。後でもう一度お試しください';

  @override
  String get preciseRefLib_favoritesOnly => 'お気に入りのみ';

  @override
  String get preciseRefLib_sortBy => '並び替え';

  @override
  String get preciseRefLib_sortCreatedAt => '作成日時';

  @override
  String get preciseRefLib_sortLastUsed => '最終使用';

  @override
  String get preciseRefLib_sortUsedCount => '使用回数';

  @override
  String get preciseRefLib_sortName => '名前';

  @override
  String preciseRefLib_importedCount(int count) {
    return '$count 枚の画像をインポートしました';
  }

  @override
  String preciseRefLib_loadFailed(String error) {
    return '精密参照ライブラリを読み込めませんでした：$error';
  }

  @override
  String preciseRefLib_importFailed(String error) {
    return '精密参照ライブラリへの保存に失敗しました：$error';
  }

  @override
  String preciseRefLib_importFailedCount(int count) {
    return '$count 枚の画像を精密参照ライブラリにインポートできませんでした';
  }

  @override
  String get preciseRefLib_fromLibrary => 'ライブラリから';

  @override
  String get preciseRefLib_saveCurrentToLibrary => 'ライブラリへ保存';

  @override
  String preciseRefLib_saveCurrentCount(int count) {
    return '$count 件をライブラリへ保存しました';
  }

  @override
  String get preciseRefLib_selectorTitle => '精密参照ライブラリから選択';

  @override
  String preciseRefLib_selectorConfirm(int count) {
    return '選択を追加 ($count)';
  }

  @override
  String get preciseRefLib_nameLabel => '名前';

  @override
  String get preciseRefLib_typeFilterAll => 'すべて';

  @override
  String get img2img_fromPreciseRefLibrary => '精密参照ライブラリから';

  @override
  String get localGallery_saveToPreciseRefLibrary => '精密参照ライブラリへ保存';

  @override
  String get drop_saveToPreciseRefLibrary => '精密参照ライブラリへ保存';

  @override
  String get common_enabled => '有効';

  @override
  String get common_disabled => '無効';

  @override
  String bulkAction_selectedCount(int count) {
    return '$count 件を選択中';
  }

  @override
  String get comfyTask_errorConnectionFailed => 'ComfyUI サーバーに接続できません';

  @override
  String get comfyTask_errorConnectionUnavailable => 'ComfyUI 接続を利用できません';

  @override
  String get comfyTask_errorExecutionFailedGeneric => 'ComfyUI の実行に失敗しました';

  @override
  String comfyTask_errorExecutionFailed(String error) {
    return 'ComfyUI の実行に失敗しました: $error';
  }

  @override
  String get comfyTask_errorTimeout => 'ComfyUI タスクが 10 分でタイムアウトしました';

  @override
  String comfyTask_errorWorkflowNotFound(String workflowId) {
    return 'ワークフローが見つかりません: $workflowId';
  }

  @override
  String get comfyWorkflowSlot_vaeEncodeTileSize => 'VAE エンコードのタイルサイズ';

  @override
  String get comfyWorkflowSlot_vaeDecodeTileSize => 'VAE デコードのタイルサイズ';

  @override
  String get comfyWorkflowSlot_blocksToSwap => 'スワップするブロック数';

  @override
  String get comfyWorkflowSlot_swapIoComponents => 'I/O コンポーネントをスワップ';

  @override
  String localGallery_firstIndexHint(int count) {
    return '$count 枚の画像を検出しました。初回のインデックス作成には数分かかる場合がありますが、アプリはそのまま使用できます。';
  }

  @override
  String get localGallery_errorPermissionDenied =>
      '画像フォルダーにアクセスできません。フォルダーの権限を確認してください。';

  @override
  String localGallery_errorScanFailed(String error) {
    return '画像のスキャンに失敗しました: $error';
  }

  @override
  String localGallery_errorInitializationFailed(String error) {
    return 'ギャラリーの初期化に失敗しました: $error';
  }

  @override
  String get localGallery_errorServiceInitializing =>
      'ギャラリーサービスを初期化しています。しばらくしてから再試行してください。';

  @override
  String localGallery_errorDatabaseFailed(String error) {
    return 'ギャラリーデータベースエラー: $error';
  }

  @override
  String localGallery_errorRefreshFailed(String error) {
    return 'ギャラリーの更新に失敗しました: $error';
  }

  @override
  String localGallery_errorFilterFailed(String error) {
    return 'ギャラリーフィルターの適用に失敗しました: $error';
  }

  @override
  String localGallery_errorFavoriteFailed(String error) {
    return 'お気に入り状態の更新に失敗しました: $error';
  }

  @override
  String localGallery_errorRebuildFailed(String error) {
    return 'ギャラリーインデックスの再構築に失敗しました: $error';
  }

  @override
  String get common_optional => '任意';

  @override
  String get common_emptyValue => '（空）';

  @override
  String get common_clickToRetry => 'クリックして再試行';

  @override
  String get common_opening => '開いています...';

  @override
  String get common_swap => '入れ替え';

  @override
  String get addToLibrary_displayNameHint => 'この項目を識別する名前を入力';

  @override
  String get addToLibrary_tagHint => 'タグを入力して Enter キーで追加';

  @override
  String get drop_saveVibeBundle => 'Vibe Bundleを保存';

  @override
  String get history_dragFilePreparationFailed =>
      'ドラッグ用ファイルの準備に失敗しました。後でもう一度お試しください。';

  @override
  String get history_dragFilePreparing => 'ドラッグ用ファイルを準備しています...';

  @override
  String get history_dragFileNotReady => 'ドラッグ用ファイルはまだ準備できていません';

  @override
  String get vibe_import_overwriteOriginalParams => '元のVibeパラメータを置換';

  @override
  String vibe_import_overwriteOriginalParamsHint(String name) {
    return '$name のライブラリ内パラメータのみ置換します。初期状態では無効です';
  }

  @override
  String vibe_import_reencodeFailed(String name) {
    return 'Vibeの再エンコードに失敗しました: $name';
  }

  @override
  String galleryScan_failed(int count) {
    return '失敗 $count';
  }

  @override
  String get galleryScan_organizingGallery => 'ギャラリーを整理中';

  @override
  String get galleryScan_processing => '処理中';

  @override
  String get vibeDetail_useAll => 'すべて使用';

  @override
  String get vibeDetail_longPressSetCover => '長押ししてカバーに設定';

  @override
  String get vibeDetail_noPreviewImage => 'プレビュー画像がありません';

  @override
  String get vibeDetail_dropPreviewImage => 'ここに画像をドロップしてプレビューを設定';

  @override
  String get vibeDetail_releasePreviewImage => '離すとプレビュー画像を設定';

  @override
  String imagePicker_dropReadFailed(String error) {
    return 'ドロップした画像を読み込めませんでした: $error';
  }

  @override
  String get imagePicker_dropNoReadableImage =>
      'ドロップされたデータに読み取り可能な画像ファイルまたは画像URLがありません';

  @override
  String get imagePicker_fileDataUnavailable => 'ファイルデータを読み込めません';

  @override
  String imagePicker_fileSelectionFailed(String error) {
    return 'ファイルの選択に失敗しました: $error';
  }

  @override
  String imagePicker_directorySelectionFailed(String error) {
    return 'フォルダーの選択に失敗しました: $error';
  }

  @override
  String get editor_effects => 'エフェクト';

  @override
  String get editor_shiftEdges => 'エッジをシフト';

  @override
  String editor_currentSize(int width, int height) {
    return '現在: $width x $height';
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
  String get editor_enterNumber => '数値を入力してください';

  @override
  String get editor_nonNegativeNumber => '0以上の値を入力してください';

  @override
  String editor_requestedSize(int width, int height) {
    return '指定: $width x $height';
  }

  @override
  String get editor_requestedSizeInvalid => '指定: 無効';

  @override
  String editor_appliedSize(int width, int height) {
    return '適用: $width x $height';
  }

  @override
  String get editor_appliedSizeInvalid => '適用: 無効';

  @override
  String editor_appliedEdges(int left, int top, int right, int bottom) {
    return '適用エッジ: 左 $left、上 $top、右 $right、下 $bottom';
  }

  @override
  String get editor_appliedEdgesInvalid => '適用エッジ: 無効';

  @override
  String editor_appliedDimensionLimit(int max) {
    return '適用後の寸法は $max 以下である必要があります。';
  }

  @override
  String get onlineGallery_videoLoadFailed => '動画を読み込めませんでした';

  @override
  String get vibe_releaseToAddStyleReference => '離すとスタイル参照を追加';

  @override
  String router_pageNotFound(String error) {
    return 'ページが見つかりません: $error';
  }

  @override
  String get autocomplete_resultLimit => '結果数';

  @override
  String get autocomplete_relatedTagsTitle => 'タグ拡張';

  @override
  String get autocomplete_relatedTagsSubtitle =>
      'Ctrl+クリックでローカル検索、Ctrl+ドラッグで関連タグを表示';

  @override
  String get tagExpansion_searchHint => 'タグや別名を検索';

  @override
  String get tagExpansion_relatedTitle => '関連タグ';

  @override
  String get tagExpansion_empty => '入力してローカルタグを検索';

  @override
  String get tagExpansion_noResults => 'ローカルタグが見つかりません';

  @override
  String get tagExpansion_insert => 'タグを挿入';

  @override
  String get tagExpansion_showRelated => '関連タグを表示';

  @override
  String get tagExpansion_localOnly => 'ローカルのみ';

  @override
  String get tagExpansion_popularSource => 'よく使われるローカルタグ';

  @override
  String get tagExpansion_tabComplete => 'Tab で補完：';

  @override
  String get tagExpansion_wikiTitle => 'タグ百科';

  @override
  String get tagExpansion_wikiUnavailable => 'このタグの説明はまだローカルにありません。';

  @override
  String get autocomplete_cooccurrence => 'オフライン関連タグデータベース';

  @override
  String autocomplete_entryCount(int count) {
    return '$count 件';
  }

  @override
  String get autocomplete_clearDanbooruCache => 'Danbooru キャッシュを消去';

  @override
  String get autocomplete_clearAiCache => 'AI 翻訳キャッシュを消去';

  @override
  String autocomplete_cacheCleared(int count) {
    return 'キャッシュを $count 件消去しました';
  }

  @override
  String get autocomplete_baseCatalog => '基本 Danbooru カタログ';

  @override
  String autocomplete_catalogStatus(String count, String version) {
    return '$count タグ · データ版 $version';
  }

  @override
  String get nav_promptBlockLibrary => 'プロンプトブロック';

  @override
  String get promptBlockLibrary_title => 'プロンプトブロック';

  @override
  String get promptBlockLibrary_folders => 'フォルダー';

  @override
  String get promptBlockLibrary_allBlocks => 'すべてのブロック';

  @override
  String get promptBlockLibrary_rootFolder => 'ルート / 未分類';

  @override
  String get promptBlockLibrary_unnamedBlock => '無題のブロック';

  @override
  String get promptBlockLibrary_noBlockSelected => 'ブロックが選択されていません';

  @override
  String get promptBlockLibrary_details => '詳細';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '$count 回使用されました';
  }

  @override
  String get promptBlockPill_missing => '削除されたブロック';

  @override
  String get promptBlockPill_unknown => '無効なブロック';

  @override
  String get pillCardReroll => '再抽選';

  @override
  String get pillCardRerollLocked => 'ロック中のため再抽選できません';

  @override
  String get pillCardLock => '現在の抽選結果をロック';

  @override
  String get pillCardUnlock => 'ロックを解除';

  @override
  String get pillCardSettings => 'ランダム設定';

  @override
  String get pillCardEnable => '有効化';

  @override
  String get pillCardDisable => '無効化';

  @override
  String get pillCardDeleteInstance => 'インスタンス削除';

  @override
  String get pillCardEmptyRoll => '（今回は空）';

  @override
  String get pillCardEvolutionEnable => '遺伝を有効化';

  @override
  String get pillCardEvolutionDisable => '遺伝を無効化';

  @override
  String get pillCardEvolutionRequiresEnabled => '先にインスタンスを有効化してください';

  @override
  String get pillCardStepBack => '一幕戻る';

  @override
  String get pillCardStepForward => '一幕進む';

  @override
  String get pillSettingsTitle => 'ブロックインスタンス設定';

  @override
  String get pillSettingsModeFixed => '固定';

  @override
  String get pillSettingsModeSequential => '順番';

  @override
  String get pillSettingsModeRandom => 'ランダム抽出';

  @override
  String get pillSettingsCount => '抽出数';

  @override
  String get pillSettingsOrder => '出力順';

  @override
  String get pillSettingsOrderDrawn => '抽選順';

  @override
  String get pillSettingsOrderOriginal => '元の順序';

  @override
  String get pillSettingsWeight => 'ランダム重み';

  @override
  String get pillSettingsWeightMin => '最小';

  @override
  String get pillSettingsWeightMax => '最大';

  @override
  String get pillSettingsWeightAverage => '平均';

  @override
  String get pillSettingsDispersion => '分散';

  @override
  String get pillSettingsDispersionFocused => '集中';

  @override
  String get pillSettingsDispersionBalanced => '均衡';

  @override
  String get pillSettingsDispersionSpread => '拡散';

  @override
  String get pillSettingsAdvanced => '詳細';

  @override
  String get pillSettingsLeftDispersion => '左分散';

  @override
  String get pillSettingsRightDispersion => '右分散';

  @override
  String get pillSettingsSoftBalance => 'ソフトバランス';

  @override
  String get pillSettingsSoftBalanceStrength => '強度';

  @override
  String get pillSettingsTriggerProbability => '発動確率';

  @override
  String get pillSettingsCancel => 'キャンセル';

  @override
  String get pillSettingsApply => '適用';

  @override
  String get promptBlockLibrary_unnamedFolder => '無題のフォルダー';

  @override
  String get promptBlockLibrary_scope => '表示範囲';

  @override
  String get promptBlockLibrary_newBlock => '新しいブロック';

  @override
  String get promptBlockLibrary_editBlock => 'ブロックを編集';

  @override
  String get promptBlockLibrary_newFolder => '新しいフォルダー';

  @override
  String get promptBlockLibrary_newSubfolder => '新しいサブフォルダー';

  @override
  String get promptBlockLibrary_renameFolder => 'フォルダー名を変更';

  @override
  String get promptBlockLibrary_moveToRoot => 'ルートへ移動';

  @override
  String get promptBlockLibrary_moveToFolder => 'フォルダーへ移動';

  @override
  String get promptBlockLibrary_favorites => 'お気に入り';

  @override
  String get promptBlockLibrary_unclassified => '未分類';

  @override
  String get promptBlockLibrary_newCollection => 'コレクションを作成';

  @override
  String get promptBlockLibrary_newSubcollection => 'サブコレクションを作成';

  @override
  String get promptBlockLibrary_newCollectionFolder => 'コレクションフォルダーを作成';

  @override
  String get promptBlockLibrary_renameCollection => 'コレクション名を変更';

  @override
  String get promptBlockLibrary_renameCollectionFolder => 'コレクションフォルダー名を変更';

  @override
  String get promptBlockLibrary_moveToFavoritesRoot => 'コレクションのルートへ移動';

  @override
  String get promptBlockLibrary_unnamedCollection => '無題のコレクション';

  @override
  String get promptBlockLibrary_unnamedCollectionFolder => '無題のコレクションフォルダー';

  @override
  String get promptBlockLibrary_collectionName => 'コレクション名';

  @override
  String get promptBlockLibrary_collectionNameHint => 'コレクション名';

  @override
  String get promptBlockLibrary_noCollections =>
      'コレクションはまだありません —「お気に入り」行の + から作成するか、ブロックをコレクションへドラッグしてください';

  @override
  String get promptBlockLibrary_noFolders => 'フォルダーはまだありません';

  @override
  String get promptBlockLibrary_emptyFavorites =>
      'お気に入りのブロックはまだありません。ブロックの ★ で登録できます';

  @override
  String get promptBlockLibrary_emptyCollection => 'このコレクションは空です';

  @override
  String promptBlockLibrary_deleteCollectionConfirm(String name) {
    return 'コレクション「$name」を削除しますか？中のブロックは削除されず、コレクションから外れるだけです。';
  }

  @override
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name) {
    return 'コレクションフォルダー「$name」を削除しますか？中のコレクションとサブフォルダーも削除されますが、ブロック本体には影響しません。';
  }

  @override
  String get promptBlockLibrary_blockTitle => 'タイトル';

  @override
  String get promptBlockLibrary_titleHint => 'ブロックのタイトル';

  @override
  String get promptBlockLibrary_searchHint => 'タイトル、プロンプト、タグを検索';

  @override
  String get promptBlockLibrary_folder => 'フォルダー';

  @override
  String get promptBlockLibrary_folderName => 'フォルダー名';

  @override
  String get promptBlockLibrary_folderNameHint => 'フォルダー名';

  @override
  String get promptBlockLibrary_basicPrompt => '基本プロンプト';

  @override
  String get promptBlockLibrary_generationSettings => '設定';

  @override
  String get promptBlockLibrary_settingsOptionalHint =>
      '入力した項目のみ保存します。ブロック挿入後に設定を手動で適用できます。';

  @override
  String get promptBlockLibrary_notSpecified => '指定しない';

  @override
  String get promptBlockLibrary_stepsLabel => 'ステップ数';

  @override
  String get promptBlockLibrary_noiseScheduleLabel => 'ノイズスケジュール';

  @override
  String get promptBlockLibrary_invalidGenerationSettings =>
      '設定を確認してください：ステップ数 1～50、プロンプトガイダンス 1～20、プロンプトガイダンスリスケール 0～1、モデルとの互換性。';

  @override
  String get promptBlockLibrary_applySettings => '設定を読み込む';

  @override
  String get promptBlockLibrary_settingsApplied => 'ブロック設定を現在の画像に読み込みました';

  @override
  String get promptBlockLibrary_settingsIncompatible =>
      'ブロック設定は対象モデルに対応していません。パラメータは変更されませんでした。';

  @override
  String get promptBlockLibrary_noSettings => '生成設定は保存されていません';

  @override
  String get promptBlockLibrary_tags => 'タグ';

  @override
  String get promptBlockLibrary_addTag => 'タグを追加';

  @override
  String get promptBlockLibrary_tagName => 'タグ名';

  @override
  String get promptBlockLibrary_tagColor => 'タグの色（16進数）';

  @override
  String get promptBlockLibrary_duplicateTag => '同じ名前のタグが既にあります';

  @override
  String get promptBlockLibrary_invalidTagColor => '有効な16進数の色を入力してください';

  @override
  String get pillCard_rollScope => '変化範囲';

  @override
  String get pillCard_positiveScope => 'ポジティブ';

  @override
  String get pillCard_negativeScope => 'ネガティブ';

  @override
  String get promptBlockLibrary_modelResetNotice => 'モデル変更後、非対応の値を消去しました。';

  @override
  String get promptBlockLibrary_atomInputHint => 'テキストを入力し、Enterで原子ブロック化';

  @override
  String get promptBlockLibrary_atomRestoreHint => 'クリックでテキストに戻して再編集';

  @override
  String get promptBlockLibrary_atomOrphan => '不明なマーカー';

  @override
  String get promptBlockLibrary_atomEditorTutorial =>
      'Enterでブロック化、クリックでテキストに戻す。未ブロックのテキストは保存時に自動で原子化。';

  @override
  String get promptBlockLibrary_color => '色';

  @override
  String get promptBlockLibrary_icon => 'アイコン';

  @override
  String get promptBlockLibrary_saved => '保存しました';

  @override
  String get promptBlockLibrary_copied => '内容をコピーしました';

  @override
  String get promptBlockLibrary_deleted => '削除しました';

  @override
  String get promptBlockLibrary_multiSelect => '複数選択';

  @override
  String get promptBlockLibrary_exitMultiSelect => '複数選択を終了';

  @override
  String promptBlockLibrary_selectedCount(int count) {
    return '$count 件選択中';
  }

  @override
  String get promptBlockLibrary_selectAllVisible => 'すべて選択';

  @override
  String get promptBlockLibrary_clearSelection => '選択をクリア';

  @override
  String get promptBlockLibrary_moveTo => '移動先…';

  @override
  String get promptBlockLibrary_moveToFolderTitle => 'フォルダーへ移動';

  @override
  String promptBlockLibrary_deleteBlocksConfirm(int count) {
    return '選択した $count 個のブロックを削除しますか？この操作は取り消せません。';
  }

  @override
  String promptBlockLibrary_deleteSelected(int count) {
    return '選択した $count 個のブロックを削除';
  }

  @override
  String get promptBlockLibrary_empty => 'プロンプトブロックはまだありません';

  @override
  String get promptBlockLibrary_emptyFolder => 'このフォルダーは空です';

  @override
  String get promptBlockLibrary_noSearchResults => '一致するブロックがありません';

  @override
  String get promptBlockLibrary_tryDifferentSearch => '別のキーワードを試してください';

  @override
  String get promptBlockLibrary_emptyHint => 'ブロックを作成して再利用可能なテキストを整理します';

  @override
  String promptBlockLibrary_loadFailed(String error) {
    return 'プロンプトブロックの読み込みに失敗しました: $error';
  }

  @override
  String promptBlockLibrary_deleteFolderTitle(Object name) {
    return 'フォルダー「$name」を削除しますか？';
  }

  @override
  String get promptBlockLibrary_deleteFolderDescription =>
      'このフォルダーとサブフォルダー内のブロックをどうするか選択してください。';

  @override
  String get promptBlockLibrary_moveContentsToRoot => '内容をルートへ移動';

  @override
  String get promptBlockLibrary_moveContentsToFolder => '内容を別のフォルダーへ移動';

  @override
  String get promptBlockLibrary_destinationFolder => '移動先フォルダー';

  @override
  String get promptBlockLibrary_deleteContents => '内容を削除';

  @override
  String get promptBlockLibrary_deleteContentsWarning =>
      'フォルダー内のすべてのブロックも完全に削除されます。';

  @override
  String get promptBlockLibrary_importExport => 'インポート / エクスポート';

  @override
  String get promptBlockLibrary_importTxtFiles => 'TXT ファイルをインポート';

  @override
  String get promptBlockLibrary_importFromFolder => 'フォルダからインポート…';

  @override
  String get promptBlockLibrary_exportLibraryBackup => 'ライブラリをバックアップ…';

  @override
  String get promptBlockLibrary_importLibraryBackup => 'ライブラリバックアップをインポート…';

  @override
  String get promptBlockLibrary_importTxtTitle => 'TXT ファイルを選択';

  @override
  String promptBlockLibrary_txtImportDone(int created, int skipped) {
    return '$created 個のブロックをインポート、$skipped 個の既存ソースをスキップ';
  }

  @override
  String get promptBlockLibrary_curationTitle => 'フォルダからインポート';

  @override
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  ) {
    return 'TXT $total 件：新規 $created · 変更なし $skipped · 変更あり $changed';
  }

  @override
  String promptBlockLibrary_curationLocalModifiedHint(int count) {
    return 'うち $count 件はインポート後に手動編集されています。更新するとローカル編集が上書きされます';
  }

  @override
  String get promptBlockLibrary_curationUpdateChanged => '変更されたブロックをファイル内容で更新';

  @override
  String get promptBlockLibrary_curationEmpty => '選択したフォルダに TXT ファイルがありません';

  @override
  String promptBlockLibrary_curationDone(
    int created,
    int updated,
    int skipped,
  ) {
    return '完了：新規 $created · 更新 $updated · スキップ $skipped';
  }

  @override
  String get promptBlockLibrary_curationNew => '新規';

  @override
  String get promptBlockLibrary_curationUnchanged => '変更なし';

  @override
  String get promptBlockLibrary_curationChanged => '変更あり';

  @override
  String get promptBlockLibrary_curationLocalModified => 'ローカル編集済み';

  @override
  String promptBlockLibrary_libraryBackupDone(int count) {
    return '$count 個のブロックのバックアップをエクスポートしました';
  }

  @override
  String get promptBlockLibrary_libraryImportTitle => 'ライブラリバックアップを選択';

  @override
  String get promptBlockLibrary_libraryBackupInvalid =>
      '有効なブロックライブラリのバックアップではありません';

  @override
  String promptBlockLibrary_libraryImportDone(
    int blocks,
    int folders,
    int skipped,
  ) {
    return 'ブロック $blocks 個・フォルダ $folders 個をインポート、$skipped 個の既存をスキップ';
  }

  @override
  String promptBlockLibrary_importFailed(String error) {
    return 'インポートに失敗しました：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => 'ソースファイル';

  @override
  String get promptBlockLibrary_importedAt => 'インポート日時';

  @override
  String get promptBlockLibrary_listView => 'リスト表示';

  @override
  String get promptBlockLibrary_gridView => 'グリッド表示';

  @override
  String get promptBlockLibrary_waterfallView => 'ウォーターフォール表示';

  @override
  String get promptBlockPalette_tooltip => 'ブロック';

  @override
  String get promptBlockPalette_emptyHint =>
      'よく使うプロンプトブロックや翻訳ブロックをここに収納。クリックでカーソル位置に挿入するか、プロンプト欄へドラッグできます。';

  @override
  String get promptBlockPalette_remove => 'ブロックから削除';

  @override
  String get promptBlockPalette_clearAll => 'ブロックをすべて削除';

  @override
  String get promptBlockPalette_clearAllArmed => 'もう一度押してすべて削除';

  @override
  String promptBlockPalette_removeSelected(int count) {
    return '選択した $count 個を削除';
  }

  @override
  String get promptBlockLibrary_sortBy => '並べ替え';

  @override
  String get promptBlockLibrary_sortCustom => '既定（手動順）';

  @override
  String get promptBlockLibrary_sortUpdated => '更新日時';

  @override
  String get promptBlockLibrary_sortTitle => '名前';

  @override
  String get promptBlockLibrary_sortColor => '色';

  @override
  String get promptBlockLibrary_sortIcon => 'アイコン';

  @override
  String get promptBlockLibrary_sortAscending => '昇順';

  @override
  String get promptBlockLibrary_sortDescending => '降順';

  @override
  String get promptBlockLibrary_cardSize => 'カードサイズ';

  @override
  String get promptBlockLibrary_reorderFolders => 'フォルダーの順序を変更';

  @override
  String get nav_styleExplore => 'スタイル探索';

  @override
  String get styleExplore_rename => '名前変更';

  @override
  String get styleExplore_nameRequired => '名前を入力してください';

  @override
  String get styleExplore_operationFailed => '操作に失敗しました';

  @override
  String get styleExplore_discardChangesTitle => '未保存の変更を破棄しますか？';

  @override
  String get styleExplore_discardChangesMessage =>
      'ワークスペースに未保存の変更があります。続行すると破棄されます。';

  @override
  String get styleExplore_discardChangesConfirm => '続行して破棄';

  @override
  String get styleExplore_previewEmpty => '（空）';

  @override
  String get styleExplore_copiedToClipboard => 'コピーしました';

  @override
  String get styleExplore_runSectionTitle => '探索ラン';

  @override
  String get styleExplore_runEmptyHint =>
      '探索ランはプロンプトとパラメータのスナップショットを固定し、候補を一括生成して選別します。';

  @override
  String get styleExplore_newRun => '新規ラン';

  @override
  String get styleExplore_galleryTitle => '候補ギャラリー';

  @override
  String get styleExplore_galleryEmptyHint =>
      '候補はまだありません。探索ランを作成または選択して一括生成を開始してください。';

  @override
  String get styleExplore_runNameLabel => 'ラン名';

  @override
  String get styleExplore_runNameHint => '例：柔らかい光 ×30';

  @override
  String styleExplore_runCreated(String name) {
    return '「$name」を作成しました';
  }

  @override
  String styleExplore_runDeleted(String name) {
    return '「$name」を削除しました';
  }

  @override
  String styleExplore_runTotalCount(int total) {
    return '全 $total 枚';
  }

  @override
  String styleExplore_runGeneratingProgress(int current, int total) {
    return '$current/$total 枚目';
  }

  @override
  String get styleExplore_runStatusDraft => '下書き';

  @override
  String get styleExplore_runStatusGenerating => '生成中';

  @override
  String get styleExplore_runStatusPaused => '一時停止';

  @override
  String get styleExplore_runStatusGenerated => '生成済み';

  @override
  String get styleExplore_runStatusCompleted => '完了';

  @override
  String get styleExplore_runStatusCancelled => 'キャンセル';

  @override
  String get styleExplore_pauseRun => '一時停止';

  @override
  String get styleExplore_cancelRun => 'ランをキャンセル';

  @override
  String styleExplore_retryFailed(int count) {
    return '失敗を再試行（$count）';
  }

  @override
  String get styleExplore_targetCountLabel => '生成枚数';

  @override
  String styleExplore_manualRunName(String time) {
    return '手動キャプチャ $time';
  }

  @override
  String get styleExplore_runBusy => '生成中です。しばらくしてからお試しください';

  @override
  String get styleExplore_deleteRunTitle => '探索ランを削除';

  @override
  String styleExplore_deleteRunMessage(String name) {
    return '「$name」とその候補画像コピーを削除します。ギャラリーの元画像には影響しません。';
  }

  @override
  String get styleExplore_cancelRunTitle => '探索ランをキャンセル';

  @override
  String get styleExplore_cancelRunMessage =>
      'キャンセル後は再開できません。残りの未生成候補はキャンセル済みとしてマークされます。';

  @override
  String get styleExplore_filterAll => 'すべて';

  @override
  String get styleExplore_filterHearted => 'お気に入り';

  @override
  String get styleExplore_newFolder => '新しいフォルダ';

  @override
  String get styleExplore_renameFolder => 'フォルダ名を変更';

  @override
  String get styleExplore_deleteFolder => 'フォルダを削除';

  @override
  String styleExplore_deleteFolderMessage(String name) {
    return 'フォルダ「$name」を削除します。中の候補は未分類に戻り、画像は削除されません。';
  }

  @override
  String get styleExplore_folderNameLabel => 'フォルダ名';

  @override
  String get styleExplore_deleteFamily => '系統を削除';

  @override
  String styleExplore_deleteFamilyMessage(String name, int count) {
    return '系統「$name」とその全父本セット・候補レコード（$count 枚）を削除します。画像ファイルは削除されません。';
  }

  @override
  String get styleExplore_familyBusy => 'この系統には生成中の候補があります。先にタスクをキャンセルしてください';

  @override
  String get styleExplore_folderUncategorized => '未分類';

  @override
  String styleExplore_folderCreated(String name) {
    return 'フォルダ「$name」を作成しました';
  }

  @override
  String get styleExplore_assignToFolder => '分類先';

  @override
  String get styleExplore_candidateMissing => '画像ファイルがありません';

  @override
  String get styleExplore_candidateDetailTitle => '候補詳細';

  @override
  String styleExplore_candidatePosition(int current, int total) {
    return '$current/$total 枚目';
  }

  @override
  String get styleExplore_prevCandidate => '前へ';

  @override
  String get styleExplore_nextCandidate => '次へ';

  @override
  String get styleExplore_rollSnapshot => 'Roll スナップショット';

  @override
  String styleExplore_seedLabel(String seed) {
    return 'シード $seed';
  }

  @override
  String styleExplore_roundNumber(int number) {
    return 'ラウンド $number';
  }

  @override
  String get styleExplore_adoptAsBlock => 'ブロックに収録';

  @override
  String get styleExplore_adoptBlockNameLabel => 'ブロック名';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return 'ブロック「$name」に収録しました';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '選択した候補に Roll 文字列がありません';

  @override
  String get styleExplore_fixateAsTemplate => 'メタデータを導入';

  @override
  String get styleExplore_fixateDone => 'メタデータをエディタに導入しました';

  @override
  String get styleExplore_deleteImage => '画像を削除';

  @override
  String get styleExplore_deleteImageTitle => '候補画像を削除';

  @override
  String get styleExplore_deleteImageMessage =>
      'ラン ディレクトリ内の候補画像コピーと候補レコードを削除します。ギャラリーの元画像には影響しません。';

  @override
  String get styleExplore_deleteImageDone => '候補画像とレコードを削除しました';

  @override
  String get styleExplore_selectCandidates => '複数選択';

  @override
  String styleExplore_selectedCount(int count) {
    return '$count 枚選択中';
  }

  @override
  String get styleExplore_mergeAdopt => 'まとめて収録';

  @override
  String get styleExplore_noRunsYet => '探索ランはまだありません';

  @override
  String get promptBlockEditor_library => 'ブロックライブラリ';

  @override
  String get promptBlockPicker_title => 'ブロックを選択';

  @override
  String get promptBlockLibrary_thumbnail => 'サムネイル';

  @override
  String get promptBlockLibrary_selectNewImage => '新しい画像を選択';

  @override
  String get promptBlockLibrary_selectImage => '画像を選択';

  @override
  String get promptBlockLibrary_adjustDisplayRange => '表示範囲を調整';

  @override
  String get promptBlockLibrary_adjustThumbnailTitle => 'サムネイル表示範囲の調整';

  @override
  String get promptBlockLibrary_dragToMove => 'ドラッグして移動、スクロールまたはピンチしてズームします';

  @override
  String get promptBlockLibrary_addToLibrary => 'ブロックライブラリに追加';

  @override
  String get promptBlockLibrary_contentPreview => '内容プレビュー';

  @override
  String get promptBlockLibrary_confirmAdd => '確認';

  @override
  String get promptBlockLibrary_saveToLibrary => 'ブロックライブラリに保存';

  @override
  String get promptBlockLibrary_droppedImage => 'ドロップされた画像';

  @override
  String get promptBlockLibrary_createBlockFromImage => '新しいブロックを作成';

  @override
  String get promptBlockLibrary_createBlockFromImageSubtitle =>
      'この画像から新しいブロックを作成します';

  @override
  String promptBlockLibrary_promptExtracted(Object prompt) {
    return '抽出されたプロンプト: \"$prompt\"';
  }

  @override
  String get promptBlockLibrary_updateExistingThumbnail => '既存ブロックのサムネイルを更新';

  @override
  String get promptBlockLibrary_updateExistingThumbnailSubtitle =>
      'ブロックを選択し、そのサムネイルを置き換えます';

  @override
  String get styleExplore_lineageTitle => '系譜';

  @override
  String get styleExplore_createFamily => 'ファミリー作成';

  @override
  String styleExplore_familyCreated(String name) {
    return 'ファミリー「$name」を作成しました';
  }

  @override
  String get styleExplore_familyNameLabel => 'ファミリー名';

  @override
  String get styleExplore_familyNameHint => '例：柔らかい光の本線';

  @override
  String styleExplore_familyParentsTitle(int count) {
    return '親（$count）';
  }

  @override
  String get styleExplore_customParentLabel => 'カスタム親文字列';

  @override
  String get styleExplore_customParentHint => 'プロンプト文字列を親として入力';

  @override
  String get styleExplore_addCustomParent => 'カスタム文字列を追加';

  @override
  String get styleExplore_createFamilyEmpty => '有効な親文字列を少なくとも 1 つ残してください';

  @override
  String styleExplore_parentSetTitle(int generation) {
    return '第 $generation 世代の親セット';
  }

  @override
  String styleExplore_candidatePileTitle(int generation, int count) {
    return '第 $generation 世代の候補パイル · $count 枚';
  }

  @override
  String get styleExplore_parentSetActive => 'アクティブ';

  @override
  String get styleExplore_parentSetUsed => 'バッククロス済み';

  @override
  String styleExplore_branchLabel(String name) {
    return 'ブランチ：$name';
  }

  @override
  String get styleExplore_createDeepRound => '候補を生成';

  @override
  String styleExplore_deepRoundCountHint(int min) {
    return '枚数は最低 $min（各親につき 1 枚保証）';
  }

  @override
  String get styleExplore_deepRoundNoInstance =>
      'メインプロンプトに有効なランダム遺伝ブロックがないため、深層ラウンドを開始できません';

  @override
  String get styleExplore_deepRoundEmpty => '変異エンジンが十分に異なる子代を生成できませんでした';

  @override
  String get styleExplore_sortParents => 'A/B比較';

  @override
  String get styleExplore_sortTitle => '親のA/B比較';

  @override
  String get styleExplore_sortPrompt => 'どちらの画像が狙いの画風に近いですか？';

  @override
  String get styleExplore_sortLeft => '左が良い';

  @override
  String get styleExplore_sortRight => '右が良い';

  @override
  String get styleExplore_sortNeither => 'どちらも良くない';

  @override
  String get styleExplore_sortSkip => 'スキップ';

  @override
  String styleExplore_sortProgress(int current, int total) {
    return '$current/$total 組目';
  }

  @override
  String get styleExplore_sortDone => 'ランク付け完了';

  @override
  String get styleExplore_branchSelect => '複数選択でブランチ';

  @override
  String get styleExplore_createBranch => 'ブランチ作成';

  @override
  String get styleExplore_branchNameLabel => 'ブランチ名（任意）';

  @override
  String styleExplore_branchCreated(int count) {
    return 'ブランチを作成しました（$count 親）';
  }

  @override
  String get styleExplore_branchNeedLatest => 'ブランチは最新世代の候補パイルからのみ作成できます';

  @override
  String get styleExplore_branchRoundsIncomplete => '現世代に未完了のラウンドがあります';

  @override
  String get styleExplore_branchDuplicate => '選択した子代が第一世代の親文字列と完全に重複しています';

  @override
  String get styleExplore_branchEmpty => '子代候補を少なくとも 1 枚選択してください';

  @override
  String styleExplore_preferenceValue(String value) {
    return '選好 $value';
  }

  @override
  String styleExplore_roundsSummary(int count) {
    return '$count ラウンド';
  }

  @override
  String get styleExplore_pileEmpty => '候補はまだありません。上の「候補を生成」から始めてください';

  @override
  String get styleExplore_managePile => '管理';

  @override
  String get styleExplore_pileManageDeleteTitle => '選択した候補画像を削除';

  @override
  String styleExplore_pileManageDeleteMessage(int count) {
    return '$count 件の候補の Run ディレクトリ内コピーとレコードを削除します。ギャラリーの元画像には影響しません。';
  }

  @override
  String styleExplore_pileManageDeleteDone(int count) {
    return '$count 件の候補と画像コピーを削除しました';
  }

  @override
  String subscriptionExpiresOn(String date) {
    return '期限 $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '残り $days 日';
  }

  @override
  String get subscriptionExpired => '期限切れ';

  @override
  String get subscriptionGracePeriod => '猶予期間';

  @override
  String get subscriptionTierNone => '未契約';

  @override
  String get settings_modelsAndInterfaces => 'モデルとAPI';

  @override
  String get tips_kind_guide => 'ヒント';

  @override
  String get tips_kind_trick => '先輩';

  @override
  String get tips_kind_wolf => 'オオカミ';

  @override
  String tips_hint(String label, String tip) {
    return '$label：$tip';
  }

  @override
  String get tips_studio_guide_1 =>
      'プロンプトを書いたら Ctrl+Enter で生成できます。結果はこのキャンバスにバッチごとに並びます。中ボタンか Shift+左ドラッグで移動、Ctrl+ホイールで拡大縮小、WASD でも移動できます。';

  @override
  String get tips_studio_guide_2 =>
      'よく使う絵師タグ、品質タグ、構図の指定は一度ブロックにしておけば、次からはブロックライブラリから呼び出すだけ。ブロックは単なるコピペではありません。固定・順番・ランダム抽出を選べるので、生成のたびに組み合わせが変わります。';

  @override
  String get tips_studio_guide_3 =>
      'ランダムブロックで当たりを引いたら、ロックしてから他のブロックを再抽選しましょう。ロックした内容は変わらず、それ以外はランダムのまま。「このポーズのまま、服だけあと何パターンか」にぴったりです。';

  @override
  String get tips_studio_guide_4 =>
      '画像をウィンドウにドラッグすると、使い方を選べます。Image2Image、バイブストランスファー、精密参照、またはプロンプトとパラメーターの抽出だけ。NovelAI のメタデータが残っている画像なら、どう書かれていたかがすぐ分かります。';

  @override
  String get tips_studio_guide_5 =>
      'キャラクター枠の正体は「配置枠」です。人物だけでなく、猫やランプ、看板を入れてもかまいません。位置を「カスタム」に切り替えてプレビュー上のアンカーをドラッグすれば、どこに出すかをモデルに伝えられます。';

  @override
  String get tips_studio_guide_6 =>
      'プロンプトの一部を選択し、Alt を押しながらホイールを回すと重みを調整できます。Alt なしなら普通にスクロールするだけなので、うっかり変わることはありません。修飾キーは設定で Ctrl に変更できます。';

  @override
  String get tips_studio_guide_7 =>
      'F1 でいつでもショートカット一覧を開けます。Ctrl+1・Ctrl+2・Ctrl+3 で生成、ギャラリー、オンライン ギャラリーを切り替え、Ctrl+, で設定を開けます。ショートカットはすべて設定で変更できます。';

  @override
  String get tips_studio_guide_8 =>
      'うっかり Anlas を大量に使うのが心配なら、設定で Anlas の高コスト警告をオンに。1 回の見積もりが設定値を超えると、生成前に確認が入ります。';

  @override
  String get tips_studio_trick_1 =>
      'シードが「何を引くか」を決めます。パラメーターとシードが同じなら、出てくるのも同じ一枚。神絵を再現したいならシードも控えておくこと。運を変えたいなら、そのシードはもう見つめないこと。';

  @override
  String get tips_studio_trick_2 =>
      'エンコード済みの Vibe を使い回せば、2 Anlas のエンコード代がかかりません。2 Anlas なんて大したことない？ 1 日に何回 Vibe を使っているか、数えてみてください。';

  @override
  String get tips_studio_trick_3 =>
      '除外したい要素は願いごとの泉ではありません。bad hands を百回書くより、プロンプト側で手の動きをはっきり書くほうが効きます。毎回のお決まりの言葉は除外したい要素プリセットに任せましょう。';

  @override
  String get tips_studio_trick_4 =>
      '絵師タグは長ければいいわけではありません。10 人を超えたあたりで、モデルはたぶん誰のタッチが欲しいのか分からなくなっています。いくつかのブロックに分けて、ランダム抽出で順番に登場させましょう。';

  @override
  String get tips_studio_trick_5 =>
      '1 回のクリックで何回リクエストするかと、1 回で何枚出すかは別の数字です。ボタンに出ているのは合計枚数で、Anlas も合計で計算されます。押す前に確認を。なぜ知っているかは聞かないで。';

  @override
  String get tips_studio_trick_6 =>
      '翻訳ブロックを中クリックすると、原文と訳文を切り替えられます。AI の翻訳がどれだけ優秀でも、たまには原文をのぞいて cat ears が変なものになっていないか確かめましょう。';

  @override
  String get tips_studio_trick_7 =>
      '設定の「画像生成の頻度を制限」を使うと、生成と生成のあいだに強制クールダウンを入れられます。少しランダムな揺らぎも足せば、リズムが機械っぽくなりません。のんびり回す夜にも、手が止まらない自分にも。';

  @override
  String get tips_studio_wolf_1 =>
      'ここはオオカミの巣。君が生成した画像は、ぼくがくわえて持ち帰って、ギャラリーにきちんと並べておく。正直、絵を描くより片付けのほうがずっと得意なんだ。';

  @override
  String get tips_studio_wolf_2 =>
      'オオカミは夜目がきく。だから君が午前 3 時にまだここにいても、ぼくは何も言わない。黙ってもう一枚付き合うだけさ。';

  @override
  String get tips_studio_wolf_3 =>
      'AI 絵師の通過儀礼は、片手の指を落ち着いて数えきることらしい。ぼくには指がないから、ずっと落ち着いている。';

  @override
  String get tips_studio_wolf_4 =>
      '群れのおきて。いいシードは分け合う。いいプロンプトはブロックにする。いい絵は眺める前に保存する。最後のが一番大事。理由は聞かないで。';

  @override
  String get tips_studio_wolf_5 =>
      'ぼくは絵を描けないけど、待つのは得意。プレビューが少しずつはっきりしていく数秒間が、一日でいちばん静かな時間なんだ。';

  @override
  String get tips_studio_wolf_6 =>
      'W.O.F は WolF の意味。間の点は何かって？ 雪の上を走ったぼくの足あとだよ。';

  @override
  String get tips_studio_wolf_7 =>
      'キャンバスが空っぽのあいだは、ここで丸くなって昼寝してる。生成を押せば、すぐ起きるよ。';

  @override
  String get tips_studio_night_1 =>
      'いまは真夜中。念のため言っておくと、この時間帯の審美眼はこっそり 3 割増しになっている。朝起きたらもう一度見直してね。';

  @override
  String get tips_studio_night_2 =>
      '夜もふけて、遠くのサーバールームの GPU もあくびをした。このバッチが終わったら寝よう。ギャラリーはぼくが見張っておく。';

  @override
  String get tips_lab_guide_1 =>
      'スタイル探索はオーディションです。まず探索ランを作ってプロンプトとパラメーターを固定し、候補をまとめて生成します。選んだ子世代が次の世代の親になり、画風は世代ごとに理想へ近づいていきます。';

  @override
  String get tips_lab_guide_2 =>
      'ハートとフォルダーは自分用の整理で、遺伝には影響しません。次の世代を決めるのは「複数選択でブランチ」で選んだ候補です。';

  @override
  String get tips_lab_guide_3 =>
      '迷ったら「A/B比較」へ。親の画像が 2 枚並ぶので、どちらが理想の画風に近いかだけ答えれば OK。上位の親ほど、次のラウンドで子を持ちやすくなります。';

  @override
  String get tips_lab_guide_4 =>
      '次のラウンドを生成するには、メインプロンプトに遺伝を有効化したランダムブロックが必要です。変わる遺伝子がなければ、変異エンジンも手が出せません。';

  @override
  String get tips_lab_guide_5 =>
      '候補の組み合わせが気に入ったら「ブロックに収録」でブロックライブラリに保存できます。生成ページでもそのまま使えます。複数選べば「まとめて収録」で一つのブロックにすることも。';

  @override
  String get tips_lab_guide_6 =>
      '探索ランを削除しても、消えるのはランフォルダー内の候補コピーだけ。ギャラリーの元画像は残ります。安心して片付けて。実験場は少し散らかっているくらいでいい。';

  @override
  String get tips_lab_trick_1 =>
      '親には必ず 1 枚以上の枠が割り当てられるので、親が多いほど 1 ラウンドに必要な枚数も増えます。欲張ると、先に Anlas がストップをかけてくれます。';

  @override
  String get tips_lab_trick_2 =>
      'ブランチを作れるのは最新世代の候補の山からだけ。振り返るのは自由でも、途中から枝分かれはできません。進化とはそういう非情なものです。';

  @override
  String get tips_lab_trick_3 =>
      '変異エンジンが「十分に異なる子を作れない」と言うことがあります。サボっているのではなく、遺伝子プールが小さすぎるだけ。ランダムブロックに候補を少し足せば、すぐ仕事に戻ります。';

  @override
  String get tips_lab_trick_4 =>
      '候補の山のサムネイルにカーソルを合わせれば大きく表示されます。一枚ずつ開かなくて大丈夫。審査員には審査員の効率がある。';

  @override
  String get tips_lab_trick_5 =>
      '候補のパラメーター一式が気に入ったら「メタデータを導入」で、プロンプトとパラメーターをそのまま編集エリアに戻せます。そこから続きをどうぞ。';

  @override
  String get tips_lab_wolf_1 =>
      '生まれたときから群れでいちばん強いオオカミなんていない。画風も同じで、第 1 世代が少しイマイチなのは普通。判断は第 3 世代まで待とう。';

  @override
  String get tips_lab_wolf_2 =>
      'ここの適者生存はやさしい版。選ばれなかった候補も消えない。今回は出番じゃなかった、それだけ。';

  @override
  String get tips_lab_wolf_3 =>
      'ぼくの遺伝学の知識はこれだけ。見た目のいい親からは、たぶん見た目のいい子が生まれる。あとは変異と、ちょっとの運。';

  @override
  String get tips_lab_wolf_4 =>
      'LAB の明かりはたいてい遅くまでついている。ぼくは入口で当番をしながら、いま何世代目かを数えておくよ。';

  @override
  String get tips_lab_wolf_5 =>
      '変異をなめちゃいけない。10 世代かけても見つからなかったものが、偶然ひょっこり出てくることがある。だから、ちょっと変な一枚もすぐには消さないで。';

  @override
  String get tips_prompt_guide_1 => 'Ctrl+Enter で生成、生成中は Esc でキャンセル。';

  @override
  String get tips_prompt_guide_2 =>
      'テキストを選択して Alt を押しながらホイールを回すと重みを調整できます。Alt なしなら普通にスクロールします。';

  @override
  String get tips_prompt_guide_3 =>
      'タグを Ctrl+クリックするとローカルのタグで検索、Ctrl+ドラッグで選ぶと一緒によく使われるタグが見られます。';

  @override
  String get tips_prompt_guide_4 =>
      '文字を選択して右クリックすれば、そのままブロックライブラリに保存できます。次からはクリックかドラッグで呼び戻せます。';

  @override
  String get tips_prompt_guide_5 =>
      '枠の下にある品質タグのプリセットが、いつもの品質タグを代わりに足してくれます。除外したい要素に切り替えると、同じ場所がそのプリセットになります。';

  @override
  String get tips_prompt_guide_6 => 'F1 でショートカット一覧を表示。';

  @override
  String get tips_prompt_guide_7 =>
      'ComfyUI からコピーした複数キャラのプロンプトを貼り付けると自動で認識され、キャラクター枠として取り込むか確認されます。一つずつ入れ直す必要はありません。';

  @override
  String get tips_prompt_guide_8 =>
      '「SD 構文自動変換」をオンにすると、(tag:1.2) のような書き方がフォーカスを外したときや生成時に NovelAI の形式へ変換されます。';

  @override
  String get tips_prompt_guide_9 => '1.2::タグ:: で重みをぴったり指定。マイナスにすると逆向きに効きます。';

  @override
  String get tips_prompt_trick_1 =>
      '波かっこを一重かけるごとに重みは 1.05 倍、角かっこは 1.05 で割ります。波かっこを五重にしている人は、たいていモデルと口論中です。';

  @override
  String get tips_prompt_trick_2 =>
      '自動フォーマットは意味のない 1 倍の重みを消します。嫌がらせではなく、トークンの節約です。';

  @override
  String get tips_prompt_trick_3 =>
      '枠の下の細いバーはトークン使用量です。満タンになると、それ以降の内容はモデルにほとんど届きません。長編小説を書くなら別の場所でどうぞ。';

  @override
  String get tips_prompt_trick_4 => '書けないときは、画面でいちばん大きいものから。';

  @override
  String get tips_prompt_trick_5 =>
      '品質タグは一度で十分。masterpiece を三回書いても、モデルは誠意を感じてくれません。';

  @override
  String get tips_prompt_trick_6 =>
      '「出てほしいけど目立ちすぎないで」なら、消すより 0.8:: が効きます。消せばゼロ、下げれば控えめ。';

  @override
  String get tips_prompt_trick_7 => '同じ言葉を何度も差し替えているなら、ブロックにしてランダムに任せましょう。';

  @override
  String get tips_prompt_trick_8 =>
      'プロンプトには「欲しいもの」、除外したい要素には「いらないもの」。プロンプトに no hat と書いても、モデルの耳には hat しか届きません。';

  @override
  String get tips_prompt_wolf_1 => 'この枠は何千枚もの神絵を見てきた。人には見せられない黒歴史も少々。';

  @override
  String get tips_prompt_wolf_2 =>
      'まず一文で欲しい絵を言葉にして、それからタグに分ける。逆にすると、タグの山と意味不明な絵ができがちなんだ。';

  @override
  String get tips_prompt_wolf_3 => '打ってるところ、見てるよ。大丈夫、英語は読めないから。';

  @override
  String get tips_prompt_wolf_4 => 'どこか遠くの GPU が、君のプロンプトにため息をついた。';

  @override
  String get tips_prompt_wolf_5 => 'ガチャの果てはオカルト、オカルトの果てはシード固定。';

  @override
  String get tips_prompt_wolf_6 =>
      '絵師タグが 12 人目になるころ、モデルはもう誰の絵を描いているのか分かっていない。君もね。';

  @override
  String get tips_explore_guide_1 =>
      'ここに書くのは親のプロンプトです。一部を進化させたいなら、その部分をランダムブロックにして遺伝を有効化しましょう。';

  @override
  String get tips_explore_guide_2 =>
      '遺伝は、ブロックインスタンスを有効にしてから使えます。グレーなら、まずブロックを有効に。';

  @override
  String get tips_explore_guide_3 => '「候補を生成」の横の数字で、このラウンドの枚数が決まります。';

  @override
  String get tips_explore_guide_4 =>
      'ブロックインスタンスは「一幕戻る」「一幕進む」で、これまで引いた組み合わせを行き来できます。';

  @override
  String get tips_explore_guide_5 =>
      '探索ランはプロンプトとパラメーターのスナップショットを固定します。あとからここを変えても、終わったラウンドには影響しません。';

  @override
  String get tips_explore_guide_6 =>
      'ブロックの「ランダム設定」では抽出数、発動確率、ランダム重みを調整できます。遺伝子のバリエーションはここに詰まっています。';

  @override
  String get tips_explore_trick_1 =>
      '遺伝子プールが大きいほど、変異の選択肢も増えます。ランダムブロックに 2 語しかなければ、10 世代進化しても 2 つの答えを行ったり来たりするだけ。';

  @override
  String get tips_explore_trick_2 =>
      '確定している部分は固定し、迷っている部分をランダムブロックに。全部ランダムなら方向がなく、全部固定なら進化がありません。';

  @override
  String get tips_explore_trick_3 =>
      'ロックしたブロックは再抽選されません。残したい特徴はまずロックして、ほかのブロックに暴れてもらいましょう。';

  @override
  String get tips_explore_trick_4 =>
      '発動確率を 30% にすると、そのブロックはだいたい 3 割の組み合わせにだけ現れます。「たまに出るくらいがちょうどいい」要素に。';

  @override
  String get tips_explore_trick_5 => '第 1 世代で完璧を期待するのは、探索じゃなくてお願いごとです。';

  @override
  String get tips_explore_wolf_1 => '群れの血筋は、一世代ずつ選ばれてきた。君の画風もね。';

  @override
  String get tips_explore_wolf_2 => '毎ラウンドがオーディションで、審査員は君ひとり。ぼくは拍手係。';

  @override
  String get tips_explore_wolf_3 => 'いい遺伝子はいい親から。いい親は、手がすべらなかったあの一回のクリックから。';

  @override
  String get tips_explore_wolf_4 =>
      '遺伝学はよく知らないけど、これだけは分かる。うるさい審査員ほど、きれいな子オオカミを育てる。';

  @override
  String get tips_character_guide_1 =>
      'キャラクター枠の正体は配置枠。猫でもランプでも看板でも、人である必要はありません。';

  @override
  String get tips_character_guide_2 =>
      '上の「位置」を「カスタム」にして、プレビュー上のアンカーをドラッグ。離せば反映されます。';

  @override
  String get tips_character_guide_3 =>
      '「AIにおまかせ」なら配置はモデル任せ。「カスタム」に戻せば、前に決めた位置はそのまま残っています。';

  @override
  String get tips_character_guide_4 => 'キャラクター枠ごとに除外したい要素があり、その枠のキャラにだけ効きます。';

  @override
  String get tips_character_guide_5 => '右上のチェックで一時的に無効化できます。消して書き直す必要はありません。';

  @override
  String get tips_character_guide_6 => 'タイトルをクリックすれば名前を変えられます。番号より見分けやすいですよ。';

  @override
  String get tips_character_guide_7 =>
      '右上の ⋯ から、このキャラクターをブロックライブラリに追加できます。あとでこの描写を使い回せます。';

  @override
  String get tips_character_trick_1 =>
      '場面と画風はメインへ、この枠にはこのキャラだけ。両方に同じ服を書くと、よほど好きなんだと思われます。';

  @override
  String get tips_character_trick_2 =>
      '二人が近すぎるとくっつきがち。separate を十回書くより、アンカーを少し離すほうが効きます。';

  @override
  String get tips_character_trick_3 =>
      '左に木を立てたい？ キャラクター枠をあげて左へドラッグ。木は自分がキャラじゃないなんて文句を言いません。';

  @override
  String get tips_character_trick_4 =>
      'キャラクター枠でもブロックと重みの構文が使えます。メインプロンプトと同じです。';

  @override
  String get tips_character_trick_5 =>
      'キャラが多すぎたら数人を無効に。窮屈だとモデルが勝手に人を選び、たいてい残したかった子が外れます。';

  @override
  String get tips_character_wolf_1 => 'ぼくもキャラクター枠がほしいけど、画面の外から見ているほうが性に合ってる。';

  @override
  String get tips_character_wolf_2 => '一つの枠に、一つの場所、一つの役目。いい人生哲学だと思う。';

  @override
  String get tips_character_wolf_3 => '立ち位置を決めるのは君、ぼくは横で「もうちょい左」って言う係。';

  @override
  String get tips_character_wolf_4 =>
      'オオカミの群れだって隊形を組んで歩く。キャラが多いときは、まず誰を真ん中にするか決めよう。';

  @override
  String get tips_gallery_guide_1 => 'ファイル名やプロンプト本文で検索';

  @override
  String get tips_gallery_guide_2 => 'カンマ区切りは全部一致';

  @override
  String get tips_gallery_guide_3 => 'モデルやサンプラーでも検索';

  @override
  String get tips_gallery_guide_4 => 'Ctrl+F でいつでもここへ';

  @override
  String get tips_gallery_guide_5 => 'キャラプロンプトも対象';

  @override
  String get tips_gallery_guide_6 => '画像を右クリックでメニュー';

  @override
  String get tips_gallery_guide_7 => 'F5 でギャラリーを更新';

  @override
  String get tips_gallery_trick_1 => '除外要素は検索されない';

  @override
  String get tips_gallery_trick_2 => '描き直す前に検索';

  @override
  String get tips_gallery_trick_3 => '自分のプロンプトが最強の検索語';

  @override
  String get tips_gallery_trick_4 => 'ゴミ箱は次の起動で空に';

  @override
  String get tips_gallery_trick_5 => 'masterpiece はほぼ全件';

  @override
  String get tips_gallery_wolf_1 => '今夜の獲物は 3 ページ目';

  @override
  String get tips_gallery_wolf_2 => 'におうぞ、神絵はこの中';

  @override
  String get tips_gallery_wolf_3 => 'スクロールも運動だよ';

  @override
  String get tips_gallery_wolf_4 => '巣は広い。ゆっくり探して';

  @override
  String get tips_online_guide_1 => 'スペース区切りで Enter';

  @override
  String get tips_online_guide_2 => 'ファジーマッチで *tag* も';

  @override
  String get tips_online_guide_3 => 'ブラックリストのタグは非表示';

  @override
  String get tips_online_guide_4 => 'ログインでお気に入りが使えます';

  @override
  String get tips_online_trick_1 => '複数語は下線で：blue_eyes';

  @override
  String get tips_online_trick_2 => 'いい絵のタグは参考に';

  @override
  String get tips_online_trick_3 => 'タグが多いほど結果は減る';

  @override
  String get tips_online_wolf_1 => '外の世界は広い。偵察してくる';

  @override
  String get tips_online_wolf_2 => 'よその縄張り、見るだけね';

  @override
  String get tips_online_wolf_3 => '今日はどの森で狩りをする？';

  @override
  String get tips_blocks_guide_1 => 'タイトルやタグで検索';

  @override
  String get tips_blocks_guide_2 => 'ブロックは枠へドラッグ';

  @override
  String get tips_blocks_guide_3 => '★ でお気に入りにまとめる';

  @override
  String get tips_blocks_guide_4 => 'サムネイルで選びやすく';

  @override
  String get tips_blocks_guide_5 => '選択して右クリックで保存';

  @override
  String get tips_blocks_trick_1 => '三回書いたらブロックに';

  @override
  String get tips_blocks_trick_2 => '迷ったら保存。消すのは一瞬';

  @override
  String get tips_blocks_trick_3 => '名前は丁寧に。未来の自分のため';

  @override
  String get tips_blocks_trick_4 => '候補が多いほど驚きも増える';

  @override
  String get tips_blocks_wolf_1 => 'どのブロックも出番待ち';

  @override
  String get tips_blocks_wolf_2 => 'ブロックは君の群れだよ';

  @override
  String get tips_blocks_wolf_3 => '知ってるのはブロック肉だけ';

  @override
  String get tips_blocks_wolf_4 => 'フォルダーの中にフォルダー';

  @override
  String get tips_generating_wolf_1 => '乱数と値段交渉中…';

  @override
  String get tips_generating_wolf_2 => '6 本目の指を説得中…';

  @override
  String get tips_generating_wolf_3 => 'ピクセルを整列させています…';

  @override
  String get tips_generating_wolf_4 => 'ノイズを一粒ずつ拭き取り中…';

  @override
  String get tips_generating_wolf_5 => 'オオカミが遠くで応援の遠吠え中…';

  @override
  String get tips_generating_wolf_6 => 'GPU に君の好みを説明中…';

  @override
  String get tips_generating_wolf_7 => 'プロンプトを夢に翻訳中…';

  @override
  String get tips_generating_wolf_8 => '目の数を確認中…';

  @override
  String get tips_generating_wolf_9 => '光と影のいい角度を探しています…';

  @override
  String get tips_generating_wolf_10 => '背景に目立ちすぎないよう説得中…';

  @override
  String get tips_generating_wolf_11 => 'ノイズの海から絵をすくい上げ中…';

  @override
  String get tips_generating_wolf_12 => '指を数えています。いち、に、さん…';

  @override
  String get tips_generating_wolf_13 => '絵の具が乾くのを待っています…';

  @override
  String get tips_generating_wolf_14 => '今日の運を召喚中…';

  @override
  String get tips_generating_trick_1 => '待てない？ Esc でキャンセル';

  @override
  String get tips_generating_trick_2 => 'プレビューは少しずつ鮮明に';

  @override
  String get tips_generating_trick_3 => '完成した画像は標準でギャラリーに保存';

  @override
  String get tips_generating_trick_4 => 'サンプリングの一歩ごとにノイズが減る';

  @override
  String get tips_splash_guide_1 => 'F1 でいつでもショートカット一覧を表示できます。';

  @override
  String get tips_splash_guide_2 => 'Ctrl+Enter で生成。ショートカットはすべて設定で変更できます。';

  @override
  String get tips_splash_guide_3 => '画像をウィンドウにドロップすると、プロンプトとパラメーターを読み取れます。';

  @override
  String get tips_splash_guide_4 => 'よく使うプロンプトはブロックにすれば、次はワンクリックで再利用できます。';

  @override
  String get tips_splash_trick_1 => '上の STEP /28 は、標準の 28 ステップへのオマージュです。';

  @override
  String get tips_splash_trick_2 => 'エンコード済みの Vibe は無料で再利用でき、2 Anlas の節約に。';

  @override
  String get tips_splash_trick_3 => '初回のギャラリー索引づくりは少し時間がかかりますが、その間も普通に使えます。';

  @override
  String get tips_splash_wolf_1 => 'あと五分だけ……わかった、起きるよ。';

  @override
  String get tips_splash_wolf_2 => '巣をちょっと片付けてる。すぐ終わるよ。';

  @override
  String get tips_splash_wolf_3 => 'GPU よし、月よし。あとは君だけ。';

  @override
  String get tips_splash_wolf_4 => 'におわない？ 新しいプロンプトのにおいがする。';

  @override
  String get tips_splash_wolf_5 => '今日もいいガチャを。';

  @override
  String genButton_normal(int count) {
    return '$count 枚生成';
  }

  @override
  String get genButton_one_1 => 'この一枚で決める';

  @override
  String get genButton_one_2 => 'いい一枚をください';

  @override
  String get genButton_one_3 => '単発、信じて飛べ';

  @override
  String get genButton_one_4 => 'まずは一枚お試し';

  @override
  String get genButton_one_5 => '一枚で勝負';

  @override
  String get genButton_one_6 => 'これは神絵の予感';

  @override
  String get genButton_one_7 => '一枚だけ、ほんとに';

  @override
  String get genButton_one_8 => '新アイコンはこれで';

  @override
  String get genButton_one_9 => '一発入魂';

  @override
  String get genButton_one_10 => '壁紙にできるやつを';

  @override
  String get genButton_one_11 => 'そっと一枚';

  @override
  String get genButton_one_12 => '一枚くわえてくる';

  @override
  String genButton_few_1(int count) {
    return '$count 枚から一番を';
  }

  @override
  String genButton_few_2(int count) {
    return '$count 枚で見比べ';
  }

  @override
  String genButton_few_3(int count) {
    return '$count 連ガチャ';
  }

  @override
  String genButton_few_4(int count) {
    return '$count 枚、どれか当たる';
  }

  @override
  String genButton_few_5(int count) {
    return '$count 択、審査開始';
  }

  @override
  String genButton_few_6(int count) {
    return 'まず $count 枚で準備運動';
  }

  @override
  String genButton_few_7(int count) {
    return '$count 枚から選抜';
  }

  @override
  String genButton_few_8(int count) {
    return '$count 枚の小さな幸せ';
  }

  @override
  String genButton_batch_1(int count) {
    return '$count 連発';
  }

  @override
  String genButton_batch_2(int count) {
    return '$count 枚まとめて';
  }

  @override
  String genButton_batch_3(int count) {
    return '$count 枚、ハマってきた';
  }

  @override
  String genButton_batch_4(int count) {
    return '一度に $count 枚、たっぷり';
  }

  @override
  String genButton_batch_5(int count) {
    return '$count 枚で画面を埋める';
  }

  @override
  String genButton_batch_6(int count) {
    return '$count 連、手堅く';
  }

  @override
  String genButton_batch_7(int count) {
    return '$count 枚、群れで出撃';
  }

  @override
  String genButton_batch_8(int count) {
    return '$count 枚、宴の始まり';
  }

  @override
  String genButton_many_1(int count) {
    return '$count 枚、本気モード';
  }

  @override
  String genButton_many_2(int count) {
    return '$count 枚、GPU が汗だく';
  }

  @override
  String genButton_many_3(int count) {
    return '$count 枚、買いだめモード';
  }

  @override
  String genButton_many_4(int count) {
    return '$count 枚、ライン稼働';
  }

  @override
  String genButton_many_5(int count) {
    return '$count 枚、Anlas が燃える';
  }

  @override
  String genButton_many_6(int count) {
    return '$count 枚、毎日更新する気？';
  }

  @override
  String genButton_many_7(int count) {
    return '$count 枚まとめて出撃';
  }

  @override
  String genButton_many_8(int count) {
    return '$count 枚、オオカミもあ然';
  }

  @override
  String genButton_huge_1(int count) {
    return '$count 枚？！個展でも開く？';
  }

  @override
  String genButton_huge_2(int count) {
    return '$count 枚、ディスクが震える';
  }

  @override
  String genButton_huge_3(int count) {
    return '$count 枚、産業革命';
  }

  @override
  String genButton_huge_4(int count) {
    return '$count 枚、まず深呼吸';
  }

  @override
  String genButton_huge_5(int count) {
    return '$count 枚、容量足りる？';
  }

  @override
  String genButton_huge_6(int count) {
    return '$count 枚、印刷所開店';
  }

  @override
  String genButton_huge_7(int count) {
    return '$count 枚、卸売りで';
  }

  @override
  String genButton_huge_8(int count) {
    return '$count 枚、オオカミが応援を呼びに';
  }

  @override
  String get genButton_rare_1 => 'SSR 確定演出';

  @override
  String get genButton_rare_2 => 'AI の調子が良いらしい';

  @override
  String get genButton_rare_3 => '今日の運勢：大吉';

  @override
  String get genButton_rare_4 => 'このボタン、君と相性がいい';

  @override
  String get genButton_rare_5 => 'オオカミが月に吠えた';

  @override
  String get genButton_rare_6 => '運気上昇中';

  @override
  String get genButton_rare_7 => '運気チャージ完了';

  @override
  String get genButton_rare_8 => 'このガチャはオオカミの提供です';

  @override
  String get genButton_rare_9 => '来い、神引き！';

  @override
  String get genButton_rare_10 => '押す者は救われる';

  @override
  String get genButton_night_1 => '夜も更けた、ラスト一回';

  @override
  String get genButton_night_2 => 'これ引いたら寝る';

  @override
  String get genButton_night_3 => '深夜の美意識は大胆';

  @override
  String get genButton_night_4 => 'オオカミも夜ふかし中';

  @override
  String genButton_special_7(int count) {
    return 'ラッキー $count';
  }

  @override
  String genButton_special_9(int count) {
    return '$count 枚で 3×3 完成';
  }

  @override
  String genButton_special_42(int count) {
    return '$count：すべての答え';
  }

  @override
  String genButton_special_99(int count) {
    return '$count 枚、あと 1 枚で 100';
  }

  @override
  String genButton_special_100(int count) {
    return 'ぴったり $count 枚、気持ちいい';
  }

  @override
  String get titleBar_minimize => '最小化';

  @override
  String get titleBar_maximize => '最大化';

  @override
  String get titleBar_restore => '元に戻す';

  @override
  String get titleBar_close => '閉じる';

  @override
  String get img2img_pixelSnap => 'ピクセルスナップ';

  @override
  String get img2img_original => '元画像';

  @override
  String get img2img_directorAddToQueue => '結果を入力キューに追加';

  @override
  String get img2img_transform => '変換';

  @override
  String get img2img_palette => 'パレット化';

  @override
  String get img2img_paletteOff => 'オフ';

  @override
  String get img2img_paletteAuto => '自動';

  @override
  String get img2img_paletteCustom => 'カスタム';

  @override
  String get img2img_avoidOverRefining => '過剰な細分化を抑制';

  @override
  String get img2img_keepGridHint => '検出されたピクセル格子を維持します。';

  @override
  String get img2img_refineGridHint => '画像に合う場合は、より細かいピクセルサイズを使います。';

  @override
  String get img2img_pixelUpscaleHint => 'ニアレストネイバーでピクセルを鮮明に拡大します。';

  @override
  String get img2img_pixelNativeHint => 'スナップ後のピクセルサイズを維持します。';

  @override
  String get img2img_masked => '背景透過';

  @override
  String get img2img_generated => '生成結果';

  @override
  String get img2img_blend => '合成結果';

  @override
  String get img2img_emotionHappy => '喜び';

  @override
  String get img2img_emotionLaugh => '笑い';

  @override
  String get img2img_emotionSad => '悲しみ';

  @override
  String get img2img_emotionAngry => '怒り';

  @override
  String get img2img_emotionSurprised => '驚き';

  @override
  String get img2img_emotionShy => '照れ';

  @override
  String get img2img_emotionExcited => '興奮';

  @override
  String get img2img_emotionDisgusted => '嫌悪';

  @override
  String get img2img_emotionSmug => '得意顔';

  @override
  String get img2img_emotionWorried => '心配';

  @override
  String get img2img_emotionLove => '愛情';

  @override
  String get img2img_emotionPlayful => 'お茶目';

  @override
  String get img2img_emotionTired => '疲れ';

  @override
  String get img2img_emotionNeutral => '無表情';

  @override
  String get img2img_enhanceAction => '強化！';

  @override
  String get img2img_showAdvanced => '詳細設定を表示';

  @override
  String get img2img_hideAdvanced => '詳細設定を隠す';

  @override
  String promptToken_usage(int used, int limit) {
    return 'トークン使用量：$used / $limit';
  }

  @override
  String promptToken_promptShare(int used, int total, int limit) {
    return 'このプロンプト：$used トークン；合計：$total / $limit';
  }

  @override
  String get promptToken_blockReferenceHint =>
      'このブロックの進捗は目安です。合計はブロックの組み合わせによって変わります。';

  @override
  String get settings_geistDark => 'Geist ダーク';

  @override
  String get settings_geistLight => 'Geist ライト';

  @override
  String get settings_geistDescription => 'スタジオ全体で共通の外観。白黒の背景にブルーのアクセント。';

  @override
  String get styleExplore_collapseGallery => '候補ギャラリーを折りたたむ';

  @override
  String get updateCapsuleLabel => '更新';

  @override
  String get updateWaitForTask => 'タスク完了後に再起動して更新できます';

  @override
  String get updateLater => '後で';

  @override
  String get nav_tagWiki => 'タグ百科';

  @override
  String get wiki_title => 'タグ百科';

  @override
  String get wiki_allTags => 'すべてのタグ';

  @override
  String get wiki_bookmarks => 'ブックマーク';

  @override
  String get wiki_newCollection => 'コレクションを作成';

  @override
  String get wiki_newChildCollection => '子コレクションを作成';

  @override
  String get wiki_renameCollection => '名前を変更';

  @override
  String get wiki_deleteCollection => 'コレクションを削除';

  @override
  String get wiki_officialDirectory => '公式ディレクトリ';

  @override
  String get wiki_searchHint => 'タグや別名を検索';

  @override
  String get wiki_typeAll => 'すべての種類';

  @override
  String get wiki_coverageAll => 'すべての説明';

  @override
  String get wiki_withArticle => '説明あり';

  @override
  String get wiki_withoutArticle => '説明なし';

  @override
  String get wiki_sortPopular => '人気順';

  @override
  String get wiki_sortName => '名前順';

  @override
  String get wiki_dataStatus => 'データの状態';

  @override
  String get wiki_scopeCurrent => '現在の項目';

  @override
  String get wiki_scopeAll => '全体を検索';

  @override
  String get wiki_readingSettings => '表示設定';

  @override
  String get wiki_textSize => '本文の大きさ';

  @override
  String get wiki_readingWidth => '本文の幅';

  @override
  String get wiki_small => '小';

  @override
  String get wiki_standard => '標準';

  @override
  String get wiki_large => '大';

  @override
  String get wiki_wide => '広い';

  @override
  String get wiki_hide => '隠す';

  @override
  String get wiki_articleMissing => 'このタグにはローカル Wiki の説明がありません。';

  @override
  String get wiki_source => '出典';

  @override
  String get wiki_addBookmark => 'ブックマークに追加';

  @override
  String get wiki_removeBookmark => 'ブックマークを解除';

  @override
  String get wiki_addToCollection => 'コレクションに追加';

  @override
  String get wiki_loadMore => 'さらに読み込む';

  @override
  String get wiki_noResults => '一致するタグがありません';

  @override
  String get wiki_noSelection => 'タグを選択して説明を表示';

  @override
  String get wiki_collectionNameHint => 'コレクション名';

  @override
  String get wiki_syncTags => 'Danbooru タグを同期';

  @override
  String get wiki_directorySource => '公式グループ一覧のスナップショット';

  @override
  String get wiki_openFull => 'タグ百科で開く';

  @override
  String get shortcut_action_vibe_detail_prev_sub_vibe => '前のサブ Vibe';

  @override
  String get shortcut_action_vibe_detail_next_sub_vibe => '次のサブ Vibe';

  @override
  String get settings_addAccountsSwitchBetweenThem => '追加したアカウントをここで切り替えられます。';

  @override
  String get settings_current => '現在';

  @override
  String get settings_emailLogin => 'メールログイン';

  @override
  String get settings_signedIn => 'ログイン済み';

  @override
  String get settings_switch => '切替';

  @override
  String get settings_accountActions => 'アカウント操作';

  @override
  String get settings_editProfile => '情報を編集';

  @override
  String get settings_setDefault => '既定に設定';

  @override
  String get settings_credentialsUpdated => '認証情報を更新しました';

  @override
  String get settings_updateCredentials => '認証情報を更新';

  @override
  String get settings_accountDetails => 'アカウントの詳細';

  @override
  String get settings_localAccountProfile => 'ローカル情報';

  @override
  String get settings_setDefault2 => '既定にする';

  @override
  String get settings_credentialsWereNotUpdatedCheck =>
      '認証情報を更新できませんでした。トークンと接続を確認してください。';

  @override
  String get settings_updateCredentials2 => '認証情報を更新';

  @override
  String get settings_checking => '確認中…';

  @override
  String get settings_enterNewSignInToken => '新しいログイントークンを入力してください。確認後に更新します。';

  @override
  String get auth_signInAccounts => 'ログインとアカウント';

  @override
  String get auth_notSignedIn => '未ログイン';

  @override
  String get auth_chooseAccountContinue => 'アカウントを選択して続ける';

  @override
  String get auth_manageAccounts2 => 'アカウント管理';

  @override
  String get auth_subscriptionExpired => 'サブスクリプションの期限切れ';

  @override
  String get settings_tagExpansion => 'タグ検索';

  @override
  String get settings_tagDictionaries => 'タグ辞書';

  @override
  String get settings_cacheMaintenance => 'キャッシュの管理';

  @override
  String get settings_clear => '消去';

  @override
  String get settings_autoRefresh => '自動更新';

  @override
  String get settings_searchFonts => 'フォントを検索';

  @override
  String get settings_couldNotLoadFonts => 'フォントを読み込めません';

  @override
  String get settings_recommended => 'おすすめ';

  @override
  String get settings_included => '内蔵';

  @override
  String get settings_systemFonts => 'システム';

  @override
  String get settings_fontPreview => 'プレビュー';

  @override
  String get settings_onlineFontsLoadAfterApplying => 'オンラインフォントは適用後に読み込まれます。';

  @override
  String get settings_saving => '保存設定';

  @override
  String get settings_howGeneratedImagesSaved => '生成画像の保存方法';

  @override
  String get settings_assetsDisplay => '素材と表示';

  @override
  String get settings_vibeLocationThumbnailQuality => 'Vibe の保存先とサムネイル品質';

  @override
  String get settings_applicationData => 'アプリデータ';

  @override
  String get settings_gallerySources => 'ギャラリーのソース';

  @override
  String get settings_manageAdditionalGalleryFolders => '追加のギャラリーフォルダーを管理';

  @override
  String get settings_default => '既定';

  @override
  String get settings_keyboard => 'キーボード操作';

  @override
  String get settings_customizeFrequentlyUsedActions => 'よく使う操作をカスタマイズ';

  @override
  String get settings_manageShortcuts => 'ショートカット管理';

  @override
  String get settings_costReminders => '消費の通知';

  @override
  String get settings_requestPacing => 'リクエスト間隔';

  @override
  String get settings_notificationsSound => '通知とサウンド';

  @override
  String get settings_lockCanvasCamera => 'キャンバスのカメラを固定';

  @override
  String get settings_dictionariesCache => '辞書とキャッシュ';

  @override
  String get settings_defaultAccount2 => '既定のアカウント';

  @override
  String get settings_signInAutomatically => '起動時に自動ログイン';

  @override
  String get settings_signInCredentials => 'ログイン認証';

  @override
  String get settings_translationInterfaces => '翻訳機能';

  @override
  String get settings_presetsBuiltInRules => 'プリセットと内蔵ルール';

  @override
  String get settings_preferenceBackupRestore => '設定のバックアップと復元';

  @override
  String get settings_searchSettingsFeatures => '設定や機能を検索';

  @override
  String get settings_noMatchingSettings => '該当する設定はありません';

  @override
  String get settings_change => '変更';

  @override
  String get settings_couldNotPlaySoundCheck => '音声ファイルを確認してください。';

  @override
  String get settings_useDefaultCompletionSound => '既定の完了音を使用';

  @override
  String get settings_soundPreview => '音声プレビュー';

  @override
  String get settings_listenCurrentCompletionSound => '現在の完了音を試聴';

  @override
  String get settings_playSound => '試聴';

  @override
  String get settings_searchResults => '検索結果';

  @override
  String get settings_promptInput => 'プロンプト入力';

  @override
  String get settings_manageTranslationModelsRules => '翻訳モデルとルールを管理';

  @override
  String get settings_browsing => '閲覧方法';

  @override
  String get settings_chooseHowViewImages => '画像の閲覧方法を選択';

  @override
  String get settings_canvasControls => 'キャンバス操作';

  @override
  String get settings_keepViewSteady => '視点を固定';

  @override
  String get settings_appearance2 => '外観スタイル';

  @override
  String get settings_chooseLightDarkWorkspace => '明るい・暗いスタイルを選択';

  @override
  String get settings_textLanguage => '文字と言語';

  @override
  String get settings_makeReadingComfortable => '読みやすさを統一';

  @override
  String get settings_adjustSettingsPagesDialogsOnly => '設定画面と設定ダイアログの文字サイズ';

  @override
  String get settings_motionNotifications => '動きと通知';

  @override
  String get settings_reduceDistractionsKnowWorkFinishes => '邪魔を減らし、完了をお知らせ';

  @override
  String get settings_notificationStyle => '通知スタイル';

  @override
  String get settings_notificationsAppearUpperRightWrap =>
      '通知は右上に表示され、長い文章は折り返し、進行中のタスクは完了後に閉じます。';

  @override
  String get settings_preview => 'プレビュー';

  @override
  String get settings_versionUpdates => 'バージョンと更新';

  @override
  String get settings_currentVersionUpdateOptions => '現在のバージョンと更新設定';

  @override
  String get settings_diagnosticsResources => '診断と資料';

  @override
  String get settings_logsFontsOpenSourceProject => 'ログ・フォント・オープンソース';

  @override
  String get settings_viewLicenses => 'ライセンスを見る';

  @override
  String get settings_openProject => 'プロジェクトを開く';

  @override
  String get settings_actionIncomplete => '操作は完了しませんでした';

  @override
  String get settings_exportPreferences => '設定をエクスポート';

  @override
  String get settings_preferencesExported => '設定をエクスポートしました';

  @override
  String get settings_noAutomaticBackupYet => '自動バックアップはまだありません';

  @override
  String get settings_restorePreviousPreferences => '前の設定に復元';

  @override
  String get settings_importPreferences => '設定をインポート';

  @override
  String get settings_apply => '適用';

  @override
  String get settings_preferencesAppliedPreviousSettingsBacked =>
      '設定を適用し、以前の設定を保存しました';

  @override
  String get settings_restoreDefaultPreferences => '既定の設定に戻す';

  @override
  String get settings_choosePreferencesResetCurrentSettings =>
      'リセットする項目を選択します。現在の設定は保存されます。';

  @override
  String get settings_appearanceSoundControls => '外観・サウンド・操作';

  @override
  String get settings_inputAutocomplete => '入力と自動補完';

  @override
  String get settings_privacyGenerationProtection => 'プライバシーと生成の保護';

  @override
  String get settings_moveAppearanceControlsInputProtection =>
      '外観・操作・入力・保護の設定を他の端末へ移行できます。';

  @override
  String get settings_rollbackCopySavedBeforeImport =>
      'インポートやリセットの前に元の設定を自動保存します。';

  @override
  String get settings_resetSelectedScopeWhileKeeping =>
      '範囲を選んでリセットし、アカウント・モデル・ライブラリ・創作内容を保持します。';

  @override
  String get settings_chooseScope => '範囲を選択';

  @override
  String get settings_preferenceManagement => '設定の管理';

  @override
  String get settings_backupMigrationRecovery => 'バックアップ・移行・復元';

  @override
  String get settings_generalAppearance => '一般と外観';

  @override
  String get settings_makeWorkspaceComfortableReadUse => '使いやすく読みやすいワークスペースに。';

  @override
  String get settings_controlsShortcuts => '操作とショートカット';

  @override
  String get settings_chooseInteractionCanvasControlsKeyboard =>
      '操作方法とキーボードショートカットを設定。';

  @override
  String get settings_generationPrompts => '生成とプロンプト';

  @override
  String get settings_managePromptInputGenerationReminders =>
      'プロンプト入力と生成の動作を管理。';

  @override
  String get settings_galleryFiles => 'ギャラリーとファイル';

  @override
  String get settings_manageImageSavingGallerySources =>
      '画像の保存、ギャラリーのソースと表示を管理。';

  @override
  String get settings_manageTagDictionariesIndexesCache => 'タグ辞書、索引とキャッシュを管理。';

  @override
  String get settings_novelaiAccounts => 'NovelAI アカウント';

  @override
  String get settings_viewAccountManageSignIn => 'アカウントとログインを管理。';

  @override
  String get settings_connectionsIntegrations => '接続と連携';

  @override
  String get settings_manageExternalToolsBridgesNetwork => '外部ツール、ブリッジとネットワーク。';

  @override
  String get settings_privacySharing2 => 'プライバシーと共有';

  @override
  String get settings_controlSharedInformationConfirmationBefore =>
      '共有する情報と確認が必要な操作。';

  @override
  String get settings_aboutDiagnostics => '情報と診断';

  @override
  String get settings_updatesLogsProjectInformation => '更新、ログとプロジェクト情報。';

  @override
  String get settings_searchSettings => '設定を検索';

  @override
  String get settings_preferences => '使い方';

  @override
  String get settings_creationResources => '制作とリソース';

  @override
  String get settings_servicesConnections => 'サービスと接続';

  @override
  String get settings_safetyMaintenance => '安全とメンテナンス';

  @override
  String get settings_subscriptionActive => 'サブスクリプション有効';

  @override
  String get settings_availableBalance => '利用可能な残高';

  @override
  String get settings_subscriptionExpiry2 => 'サブスクリプション有効期限';

  @override
  String get settings_subscriptionDetailsUnavailable => 'サブスクリプション情報を取得できません';

  @override
  String get settings_loadingSubscriptionDetails => 'サブスクリプション情報を読み込み中…';

  @override
  String get settings_localDataStaysAvailableAfter => '有効期限後もローカルデータは保持されます。';

  @override
  String get settings_records => '件';

  @override
  String get settings_hitRate => 'ヒット率';

  @override
  String get settings_images => '画像';

  @override
  String get settings_cacheOverview => 'キャッシュの概要';

  @override
  String get settings_loginPreferences => 'ログイン設定';

  @override
  String get settings_preselectedSignInPage => 'ログイン画面で優先的に選択します。';

  @override
  String get settings_noAccounts => 'アカウントなし';

  @override
  String get settings_useLastSessionOffNext =>
      '前回の認証情報を使用します。オフにすると次回はログイン画面を開きます。';

  @override
  String get settings_couldNotSaveLoginPreference => 'ログイン設定を保存できませんでした。';

  @override
  String get settings_loginPreferencesUnavailable => 'ログイン設定を読み込めません。';

  @override
  String settings_applyPreferencesConfirm(Object count) {
    return '$count 件の設定を適用します。現在の設定は自動保存され、「前の設定に復元」から戻せます。アカウント、認証情報、下書き、ライブラリ、モデル設定は個別に保持されます。';
  }

  @override
  String get settings_restore => '復元';

  @override
  String get wiki_translating => '翻訳中';

  @override
  String get wiki_back => '前に戻る';

  @override
  String get wiki_readingTranslation => '訳文';

  @override
  String get wiki_readingOriginal => '原文';

  @override
  String get wiki_switchToOriginal => '原文に切り替え';

  @override
  String get wiki_switchToTranslation => '訳文に切り替え';

  @override
  String get wiki_retranslate => '再翻訳';

  @override
  String get wiki_onThisPage => '目次';

  @override
  String get wiki_overview => '概要';

  @override
  String get wiki_untranslated => 'まだ翻訳されていません';

  @override
  String get wiki_autoTranslateTagsArticles => 'タグと百科を自動翻訳';

  @override
  String get wiki_readingContent => '表示内容';

  @override
  String get wiki_categoryGeneral => '一般';

  @override
  String get wiki_categoryArtist => '絵師';

  @override
  String get wiki_categoryCopyright => '作品';

  @override
  String get wiki_categoryCharacter => 'キャラクター';

  @override
  String get wiki_categoryMeta => 'メタ';

  @override
  String get wiki_categoryContributor => '投稿者';

  @override
  String get wiki_categorySpecies => '種族';

  @override
  String get wiki_categoryLore => '設定';

  @override
  String get wiki_categoryLibrary => 'ローカル';

  @override
  String get toast_titleSuccess => '完了';

  @override
  String get toast_titleError => '操作失敗';

  @override
  String get toast_titleWarning => 'ご注意';

  @override
  String get toast_titleInfo => 'お知らせ';

  @override
  String get toast_titleProgress => '処理中';

  @override
  String get tagExpansion_autoTranslateVisible => '表示中のタグを自動翻訳';

  @override
  String get translationEditor_title => '翻訳ブロック';

  @override
  String get translationEditor_source => '原文';

  @override
  String get translationEditor_sourcePrefix => '原';

  @override
  String get translationEditor_generation => '画像生成用';

  @override
  String get translationEditor_editable => '編集可能';

  @override
  String get translationEditor_modified => '変更済み';

  @override
  String get translationEditor_edited => '編集済み';

  @override
  String get translationEditor_close => '閉じる';

  @override
  String get translationEditor_save => '保存';

  @override
  String get translationEditor_delete => 'ブロックを削除';

  @override
  String get translationEditor_restore => '原文テキストに戻す';

  @override
  String get translationEditor_configure => '翻訳モデルを設定';

  @override
  String translationEditor_readingFieldTitle(Object language) {
    return '$languageの表示テキスト';
  }

  @override
  String translationEditor_sourceWarning(Object language) {
    return '原文が変更されました。$languageとの同期が必要です';
  }

  @override
  String get translationEditor_editHint => '訳文の手動編集履歴です。原文の確認状態は変わりません';

  @override
  String get translationLanguage_chinese => '中国語';

  @override
  String get translationLanguage_english => '英語';

  @override
  String get translationLanguage_japanese => '日本語';

  @override
  String get translationLanguage_korean => '韓国語';

  @override
  String get translationLanguage_traditionalChinese => '繁体字中国語';

  @override
  String get promptBlockEditor_translationNeedsReview =>
      '原文が変更されました。訳文の更新が必要です';

  @override
  String get promptBlockEditor_translationReviewHint =>
      '原文を編集したら、この訳文も確認してください';

  @override
  String get modelTask_translateTitle => '原文 → 表示言語';

  @override
  String get modelTask_promptReverseTitle => '表示言語 → 原文';

  @override
  String get modelTask_tagTranslateTitle => 'タグ名の翻訳';

  @override
  String get modelTask_wikiTranslateTitle => '百科本文の翻訳';

  @override
  String get modelTask_translateDescription =>
      'プロンプトとブロックを翻訳し、重み・グループ・タグの意味を保ちます。';

  @override
  String get modelTask_promptReverseDescription =>
      '訳文での追加・削除・変更を原文に反映し、確認用に原文へ戻します。';

  @override
  String get modelTask_tagTranslateDescription => '表示中のタグに簡潔で正確な名前を付けます。';

  @override
  String get modelTask_wikiTranslateDescription =>
      '百科本文を翻訳してレイアウトを整え、文脈に応じてクリックできるタグを選びます。';

  @override
  String get modelTask_connectionTest => 'モデル接続テスト';

  @override
  String get modelReasoning_serviceDefault => 'サービス既定';

  @override
  String get modelReasoning_off => 'オフ';

  @override
  String get modelReasoning_on => 'オン';

  @override
  String get modelReasoning_minimal => '最小';

  @override
  String get modelReasoning_low => '低';

  @override
  String get modelReasoning_medium => '中';

  @override
  String get modelReasoning_high => '高';

  @override
  String get modelReasoning_xhigh => '非常に高い';

  @override
  String get modelReasoning_max => '最大';

  @override
  String get modelProvider_custom => 'カスタムサービス';

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
  String get modelProvider_zai => 'Z.AI · 国際';

  @override
  String get modelProvider_zhipuCodingPlan => 'Zhipu Coding Plan';

  @override
  String get modelProvider_kimiCoding => 'Kimi Coding';

  @override
  String get modelProvider_moonshotInternational => 'Moonshot AI · 国際';

  @override
  String get modelProvider_minimaxChinaChat => 'MiniMax · 中国 OpenAI';

  @override
  String get modelProvider_minimaxChinaMessages => 'MiniMax · 中国 Anthropic';

  @override
  String get modelProvider_minimaxInternationalMessages =>
      'MiniMax · 国際 Anthropic';

  @override
  String get modelProvider_xiaomi => 'Xiaomi MiMo';

  @override
  String get modelProvider_antLing => 'Ant Ling';

  @override
  String get modelProvider_stepfunPlan => 'StepFun Step Plan';

  @override
  String get modelProvider_qwenTokenPlanChina => 'Qwen Token Plan · 中国';

  @override
  String get modelProvider_hintHuggingFace =>
      '推論権限のある Hugging Face トークンを使用します。ルーターのモデル ID は手動で追加できます。';

  @override
  String get modelProvider_hintPlanKey =>
      'プラン専用の API キーを使用します。利用できるモデルと範囲はプランの応答に従います。';

  @override
  String get modelProvider_hintInternationalEndpoint =>
      '国際版のエンドポイントです。国際版プラットフォームの API キーを使用します。';

  @override
  String get modelProvider_hintRegionOpenAi =>
      '対応する地域の API キーを使用します。OpenAI Chat Completions 互換のアドレスが入力済みです。';

  @override
  String get modelProvider_hintRegionAnthropic =>
      '対応する地域の API キーを使用します。Anthropic Messages 互換のアドレスが入力済みです。';

  @override
  String get modelProvider_hintQwen =>
      '既定は北京リージョンです。他のリージョンでは対応するキーを使い、エンドポイントを変更してください。';

  @override
  String get modelProvider_hintMinimax =>
      '既定は国際版の従量課金エンドポイントです。中国版ではそのキーとエンドポイントを使用してください。';

  @override
  String get modelProvider_hintMoonshot =>
      '既定は中国版です。国際版ではそのキーとエンドポイントを使用してください。';

  @override
  String get modelProvider_hintZhipu =>
      '既定は従量課金のエンドポイントです。Coding Plan では専用アドレスを使用してください。';

  @override
  String get modelProvider_hintDoubao =>
      'Ark の API キーを使用します。先にモデルを有効化するか、推論エンドポイント ID を追加してください。';

  @override
  String get modelProvider_hintCustom =>
      '互換サービスのアドレスとキーを入力し、接続情報でプロトコルを選択してください。';

  @override
  String get modelProvider_hintLocal =>
      '先にローカルサービスを起動してから、読み込まれたモデル一覧を取得してください。';

  @override
  String get modelProvider_hintDefault =>
      'アドレスとプロトコルは入力済みです。キーを保存するとモデルを選択できます。';

  @override
  String get modelParams_temperatureRange => 'Temperature は 0〜2 の範囲で指定してください。';

  @override
  String get modelParams_topPRange => 'Top P は 0 より大きく 1 以下で指定してください。';

  @override
  String get modelParams_maxOutputPositive => '最大出力トークンは 0 より大きくしてください。';

  @override
  String get modelParams_anthropicTemperatureRange =>
      'Anthropic の Temperature は 0〜1 の範囲で指定してください。';

  @override
  String get modelParams_anthropicSamplingConflict =>
      'Anthropic では Temperature と Top P のどちらか一方を指定してください。モデルのパラメーターを確認してください。';

  @override
  String modelParams_thinkingBudgetTooSmall(Object minimum) {
    return '最大出力は思考予算の下限 $minimum より大きくしてください。';
  }

  @override
  String get modelOverrides_invalidHeaderName => '有効なヘッダー名を入力してください';

  @override
  String get modelOverrides_invalidHeaderValue => 'ヘッダーの値に改行や制御文字は使えません';

  @override
  String get modelOverrides_emptyBodyField => 'ボディのフィールド名は空にできません';

  @override
  String get modelOverrides_modelFromList => 'モデル ID はモデル一覧から設定してください';

  @override
  String get modelOverrides_streamMustBeFalse =>
      'この接続は非ストリーミングのため、stream は false にしてください';

  @override
  String get modelConfig_changedSaveAgain => '設定が変更されました。もう一度保存してください。';

  @override
  String get modelConfig_presetChanged => '選択したプリセットが変更されました。選び直してください。';

  @override
  String get modelConfig_serviceDisabled => '選択したサービスが無効になりました。選び直してください。';

  @override
  String get modelConfig_modelChanged => '選択したモデルが変更されました。選び直してください。';

  @override
  String get modelConfig_reasoningChanged =>
      'モデルの思考レベルが変更されました。選び直すか、モデルに従ってください。';

  @override
  String get modelConfig_presetIdRequired => 'プリセット ID は空にできません。';

  @override
  String get modelConfig_saveBuiltinAsCustom => '内蔵プリセットはカスタムプリセットとして保存してください。';

  @override
  String get modelConfig_namePromptRequired => '名前とプロンプトは空にできません。';

  @override
  String get modelConfig_builtinNotDeletable => '内蔵ルールは削除できません。';

  @override
  String get modelConfig_pasteFullJson => 'モデル設定の JSON を丸ごと貼り付けてください。';

  @override
  String get modelConfig_builtinNotOverwritable =>
      '内蔵プリセットは上書きできません。カスタムプリセットとして複製してください。';

  @override
  String get modelConfig_invalidProvider => 'サービスの ID・名前・アドレスが無効です。';

  @override
  String get modelConfig_missingProvider => 'モデルに対応するサービスが存在しません。';

  @override
  String get modelConfig_invalidCustomPreset => 'カスタムプリセットの ID・名前・プロンプトが無効です。';

  @override
  String get modelConfig_changedImportAgain => '設定が変更されました。もう一度インポートしてください。';

  @override
  String get modelHealth_unverified =>
      '接続はまだ確認されていません。モデルを使うか「接続をテスト」すると更新されます';

  @override
  String get modelHealth_healthy => '直近のリクエストは成功しました';

  @override
  String get modelHealth_limited =>
      '接続できますが、直近のリクエストはレート制限されました（HTTP 429）。後で再試行するか、利用枠を確認してください';

  @override
  String get modelHealth_authentication => '認証に失敗しました。API キーを確認してください';

  @override
  String get modelHealth_permission => 'アクセスが拒否されました。サービスの権限を確認してください';

  @override
  String get modelHealth_timeout => '直近のリクエストはタイムアウトしました';

  @override
  String get modelHealth_network => '直近のリクエストはサービスに接続できませんでした';

  @override
  String get modelHealth_invalidResponse => '直近の応答が不正でした。詳細はリクエスト記録で確認できます';

  @override
  String get modelHealth_failed => '直近のリクエストは失敗しました';

  @override
  String modelHealth_failedStatus(Object status) {
    return '直近のリクエストは失敗しました（HTTP $status）';
  }

  @override
  String get modelRequest_statusPending => '待機中';

  @override
  String get modelRequest_statusRunning => 'リクエスト中';

  @override
  String get modelRequest_statusSuccess => '成功';

  @override
  String get modelRequest_statusFailed => '失敗';

  @override
  String get modelRequest_statusCancelled => 'キャンセル済み';

  @override
  String get modelRequest_fieldTime => '時刻';

  @override
  String get modelRequest_fieldMethod => 'メソッド';

  @override
  String get modelRequest_fieldUrl => 'URL';

  @override
  String get modelRequest_fieldRequestHeaders => 'リクエストヘッダー';

  @override
  String get modelRequest_fieldBody => '本文';

  @override
  String get modelRequest_fieldStatusCode => 'ステータスコード';

  @override
  String get modelRequest_fieldResponseHeaders => 'レスポンスヘッダー';

  @override
  String get modelRequest_fieldError => 'エラー';

  @override
  String get modelRequest_fieldInterface => 'インターフェース';

  @override
  String get modelRequest_fieldProvider => 'サービス';

  @override
  String get modelRequest_fieldModel => 'モデル';

  @override
  String get modelRequest_fieldProtocol => 'プロトコル';

  @override
  String get modelRequest_fieldStatus => '状態';

  @override
  String get modelRequest_fieldElapsed => '所要時間（ミリ秒）';

  @override
  String get modelRequest_fieldAttempts => '実行回数';

  @override
  String get modelRequest_fieldHttpRequests => 'HTTP リクエスト数';

  @override
  String get modelRequest_fieldParameters => '適用パラメーター';

  @override
  String get modelRequest_redacted => '[マスク済み]';

  @override
  String get modelRequest_emptyResponse => 'モデルが空の内容を返しました。';

  @override
  String get modelService_testFieldsIncomplete => 'テストの応答にフィールドが不足しています。';

  @override
  String get modelService_testFieldsInvalid => 'テストの応答のフィールドが正しくありません。';

  @override
  String get modelService_testGroupsInvalid => 'テストの応答のグループが正しくありません。';

  @override
  String get modelService_testSourceEmpty => 'テストの応答の原文が空です。';

  @override
  String get modelService_conversionCancelled => '変換をキャンセルしました';

  @override
  String get modelService_chooseInterfaceModel =>
      '先に「設定 → モデルとAPI → 機能インターフェース」でサービスとモデルを選択してください。';

  @override
  String get modelService_enableServiceModel =>
      '先に設定でサービスを有効にし、モデルを取得または手動で追加して選択してください。';

  @override
  String get modelSettings_keepEditsTitle => '現在の編集を保持しますか？';

  @override
  String get modelSettings_keepEditsBody => '変更はまだ保存されていません。保存してから切り替えますか？';

  @override
  String get modelSettings_discard => '破棄';

  @override
  String get modelSettings_saveAndSwitch => '保存して切り替え';

  @override
  String get modelSettings_addProvider => 'サービスを追加';

  @override
  String modelSettings_deleteProviderTitle(Object name) {
    return '$name を削除しますか？';
  }

  @override
  String get modelSettings_deleteProviderBody => 'このサービスの接続、キー、選択したモデルが削除されます。';

  @override
  String modelSettings_deleteProviderBindings(Object count) {
    return '$count 件の機能のモデル割り当てが解除されます。プリセットは保持されます。';
  }

  @override
  String modelSettings_deletePresetTitle(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get modelSettings_deletePresetBody =>
      'このプリセットを使う機能は内蔵プリセットに戻ります。モデルの割り当ては保持されます。';

  @override
  String get modelSettings_configCopied => '設定をコピーしました。キー、カスタムヘッダー、ボディは含まれません。';

  @override
  String get modelSettings_importConfig => '設定をインポート';

  @override
  String get modelSettings_importConfigHint =>
      'エクスポートした設定を貼り付けます。現在の設定は先にバックアップされ、キーは別に保存されたままです。';

  @override
  String get modelSettings_configJson => '設定 JSON';

  @override
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  ) {
    return '$providers 件のサービス、$models 件のモデル、$presets 件のカスタムプリセットをインポートします。';
  }

  @override
  String get modelSettings_importMissingProviders => 'サービスまたはモデルの設定がありません。';

  @override
  String get modelSettings_checkConfig => '設定を確認';

  @override
  String get modelSettings_importAndReplace => 'インポートして置き換え';

  @override
  String get modelSettings_configImported => '設定をインポートしました';

  @override
  String get modelSettings_description => 'サービスの接続と翻訳設定を管理します。';

  @override
  String get modelSettings_configMenu => '設定の管理';

  @override
  String get modelSettings_copyConfig => '設定をコピー';

  @override
  String get modelSettings_tabProviders => 'サービス';

  @override
  String get modelSettings_tabInterfaces => '機能インターフェース';

  @override
  String get modelSettings_tabPresets => 'プリセットとプロンプト';

  @override
  String get modelSettings_tabRequests => 'リクエスト記録';

  @override
  String modelSettings_providersCount(Object count) {
    return 'サービス · $count';
  }

  @override
  String modelSettings_providerModelCount(Object count) {
    return '$count 件のモデル';
  }

  @override
  String get modelSettings_providerDisabledSuffix => ' · 無効';

  @override
  String get modelSettings_emptyTitle => '最初のモデルサービスを追加';

  @override
  String get modelSettings_emptyBody => 'よく使うサービスを選ぶか、カスタムエンドポイントに接続します。';

  @override
  String get modelSettings_customService => 'カスタムサービス';

  @override
  String get modelSettings_notConfigured => '未設定';

  @override
  String get modelSettings_preset => 'プリセット';

  @override
  String get modelSettings_presetBuiltin => '内蔵';

  @override
  String get modelSettings_presetUser => 'ユーザー';

  @override
  String get modelSettings_deletePreset => 'プリセットを削除';

  @override
  String modelSettings_presetCopyName(Object title, Object number) {
    return '$title（$number）';
  }

  @override
  String get modelSettings_recentRequests => '最近のリクエスト';

  @override
  String get modelSettings_recentRequestsHint =>
      'このセッションの直近 100 件 · リクエストと応答の全文（認証情報はマスク済み）';

  @override
  String get modelSettings_clearRequests => 'クリア';

  @override
  String get modelSettings_requestsEmpty => '翻訳やモデルのテストを行うと、ここにリクエストが表示されます。';

  @override
  String get modelSettings_interfaceChangedElsewhere =>
      '機能の設定が別の場所で変更されました。開き直してから編集してください。';

  @override
  String get modelSettings_configSaved => '設定を保存しました';

  @override
  String get modelSettings_viewBuiltinRules => '内蔵ルールを表示';

  @override
  String get modelSettings_viewEditPreset => 'プリセットを表示・編集';

  @override
  String get modelSettings_restoreBuiltinPreset => '内蔵プリセットに戻す';

  @override
  String get modelSettings_followUiLanguage => 'UI の言語に合わせる';

  @override
  String get modelSettings_providerAndModel => 'サービスとモデル';

  @override
  String get modelSettings_providerAndModelHelp => '有効なサービスで選択したモデルのみ表示されます';

  @override
  String get modelSettings_chooseProviderModel => 'サービスとモデルを選択';

  @override
  String get modelSettings_reasoning => '思考';

  @override
  String get modelSettings_reasoningHelp =>
      '単純な翻訳では通常、思考は不要です。タグ付けや意味による分類なども行う場合は、モデルが対応する最も低い思考レベルをおすすめします。';

  @override
  String get modelSettings_reasoningHelpLabel => '思考レベルのヒント';

  @override
  String get modelSettings_usePreset => '使用するプリセット';

  @override
  String get modelSettings_outputLanguage => '出力言語';

  @override
  String get modelSettings_englishPrompt => '英語の生成プロンプト';

  @override
  String get modelSettings_englishPromptHelp => '原文に変更を反映し、英語の生成プロンプトを出力します。';

  @override
  String get modelSettings_targetLanguage => '翻訳先の言語';

  @override
  String get modelSettings_effective => '現在の設定';

  @override
  String get modelSettings_noModelSelected => '利用できるモデルが選択されていません';

  @override
  String modelSettings_reasoningSummaryInterface(Object level) {
    return '思考：$level（この機能）';
  }

  @override
  String modelSettings_reasoningSummaryModel(Object level) {
    return '思考：$level（モデルに従う）';
  }

  @override
  String get modelSettings_promptBlocksHint =>
      '翻訳が不要なときは、プロンプトをモジュールに分け、ブロック機能で自由に組み立てることもできます。';

  @override
  String get modelSettings_wikiFormatHint =>
      '翻訳が不要なときも、レイアウトを整えて関連タグにリンクを付けられます。';

  @override
  String get modelSettings_unsavedChanges => '未保存の変更があります';

  @override
  String get modelSettings_testPreset => 'プリセットをテスト';

  @override
  String get modelSettings_tabModelPreset => 'モデルとプリセット';

  @override
  String get modelSettings_tabPromptOutput => 'プロンプトと出力';

  @override
  String get modelSettings_translationStrategy => '翻訳方針';

  @override
  String get modelSettings_editPreset => 'プリセットを編集';

  @override
  String get modelSettings_outputContract => 'アプリの出力仕様';

  @override
  String get modelSettings_outputContractHint => '返却フィールドと検証ルールはアプリが管理します';

  @override
  String get modelSettings_testResult => 'テスト結果';

  @override
  String get modelRequest_detailsRequests => 'リクエスト';

  @override
  String get modelRequest_detailsIndex => '番号';

  @override
  String get modelRequest_detailsResponses => 'レスポンス';

  @override
  String get modelRequest_detailsOutput => '抽出結果';

  @override
  String get modelRequest_detailsTitle => 'リクエスト記録';

  @override
  String get modelRequest_detailsCopied => 'コピーしました';

  @override
  String get modelRequest_detailsCopyPage => 'このページをコピー';

  @override
  String get modelRequest_detailsOverview => '概要';

  @override
  String get modelRequest_detailsMissing => 'この記録はクリアされたか、直近 100 件を超えました。';

  @override
  String get modelPreset_changedElsewhere =>
      'プリセットが別の場所で変更されました。開き直してから編集してください。';

  @override
  String get modelPreset_interfacePresetChanged =>
      '機能で使うプリセットが別の場所で変更されました。開き直してから新規作成してください。';

  @override
  String get modelPreset_builtinReadOnly => '内蔵 · 読み取り専用';

  @override
  String get modelPreset_newInterfacePreset => '新しい機能プリセット';

  @override
  String get modelPreset_tabPrompt => 'プロンプト';

  @override
  String get modelPreset_tabOutputContract => '出力仕様';

  @override
  String get modelPreset_name => 'プリセット名';

  @override
  String get modelPreset_nameRequired => '名前を入力してください';

  @override
  String get modelPreset_behavior => '動作と翻訳方針';

  @override
  String get modelPreset_builtinLocked =>
      '内蔵ルールはロックされています。機能プリセットを新規作成すると、独自の翻訳設定を編集できます。';

  @override
  String get modelPreset_editHint => 'ここで翻訳設定を編集します。返却形式はアプリが別に管理します。';

  @override
  String get modelPreset_strategyHint => '翻訳方針を入力';

  @override
  String get modelPreset_promptRequired => 'プロンプトは空にできません';

  @override
  String get modelPreset_restoreStrategy => '方針を内蔵の内容に戻す';

  @override
  String get modelPreset_outputContractNote =>
      'この部分は翻訳結果を書き戻して表示できるようにするもので、アプリが管理します。';

  @override
  String get modelPreset_save => 'プリセットを保存';

  @override
  String get modelReasoning_unsupported => '非対応';

  @override
  String get modelReasoning_followModel => 'モデルに従う';

  @override
  String modelReasoning_followModelLevel(Object level) {
    return 'モデルに従う（$level）';
  }

  @override
  String get modelReasoning_notAdjustable => 'このモデルは思考の調整に対応していません';

  @override
  String get modelReasoning_strength => '思考の強さ';

  @override
  String modelReasoning_modelDefault(Object level) {
    return 'モデル既定：$level';
  }

  @override
  String get modelReasoning_levelsUnknown =>
      '調整できるレベルはまだ確認されていません\nサービスのモデル設定で設定できます';

  @override
  String modelReasoning_strengthValue(Object level) {
    return '思考の強さ：$level';
  }

  @override
  String get modelProvider_customEndpoint => 'カスタムエンドポイント';

  @override
  String get modelProvider_pickerTitle => 'サービスを選択';

  @override
  String get modelProvider_pickerSearch => 'ベンダー、プラットフォーム、ローカルサービスを検索';

  @override
  String get modelProvider_pickerEmpty => '一致するサービスはありません';

  @override
  String get modelProvider_groupApiKey => 'API キー接続';

  @override
  String get modelProvider_groupLocal => 'ローカルサービス';

  @override
  String get modelProvider_enterCompatibleAddress => '互換エンドポイントのアドレスを入力';

  @override
  String get modelConnection_provider => 'サービス';

  @override
  String get modelConnection_name => '名前';

  @override
  String get modelConnection_nameExample => '例：自分用のリレー';

  @override
  String get modelConnection_protocol => 'プロトコル';

  @override
  String get modelConnection_address => 'エンドポイント';

  @override
  String get modelConnection_apiKey => 'API キー';

  @override
  String modelControls_decrease(Object label, Object step, Object unit) {
    return '$labelを減らす（$step $unit）';
  }

  @override
  String modelControls_increase(Object label, Object step, Object unit) {
    return '$labelを増やす（$step $unit）';
  }

  @override
  String get modelControls_retryOff => 'オフ';

  @override
  String modelControls_retryTimes(Object count) {
    return '$count 回';
  }

  @override
  String get settings_positiveIntegerRequired => '0 より大きい整数を入力してください';

  @override
  String get modelSettings_testingPreset => 'プリセットをテスト中';

  @override
  String modelHealth_lastUpdated(Object time) {
    return '最終更新：$time';
  }

  @override
  String get modelSettings_backToEditing => '編集に戻る';

  @override
  String modelService_loadOverridesFailed(Object error) {
    return 'カスタムリクエスト設定を読み込めませんでした：$error';
  }

  @override
  String get modelService_timeoutRange => 'リクエストのタイムアウトは 10〜600 秒にしてください。';

  @override
  String get modelService_concurrencyRange => '最大同時実行数は 1〜20 にしてください。';

  @override
  String get modelService_nameRequired => 'サービス名を入力してください。';

  @override
  String get modelService_invalidUrl =>
      'エンドポイントは http:// または https:// から始まる完全な URL にしてください。';

  @override
  String get modelService_contextPositive => 'コンテキストウィンドウは 0 より大きくしてください。';

  @override
  String get modelService_readingCatalog => 'モデル一覧を読み込み中…';

  @override
  String modelService_catalogReturned(Object count) {
    return '$count 件のモデルが返されました。使用するモデルにチェックを入れてください。';
  }

  @override
  String modelService_catalogUnavailable(Object error) {
    return 'モデル一覧を取得できません：$error。モデル ID は手動で追加できます。';
  }

  @override
  String modelService_catalogCached(Object count) {
    return '前回取得した $count 件のモデルを読み込みました。「一覧を取得」で更新できます。';
  }

  @override
  String get modelService_catalogCacheFailed =>
      'モデル一覧は取得しましたが、ローカルキャッシュを保存できませんでした。次回は再取得が必要です。';

  @override
  String get modelService_selectModelFirst => '先にモデルを選択してください。';

  @override
  String get modelService_testingModel => 'モデルへのリクエストをテスト中…';

  @override
  String modelService_testSucceeded(Object reply) {
    return 'モデルへのリクエストに成功しました：$reply';
  }

  @override
  String modelService_testFailed(Object error) {
    return 'モデルへのリクエストに失敗しました：$error';
  }

  @override
  String modelService_tokensPositive(Object name) {
    return 'モデル「$name」のトークン数は 0 より大きくしてください。';
  }

  @override
  String get modelService_changedElsewhere =>
      'サービスの設定が別の場所で変更されました。開き直してから編集してください。';

  @override
  String get modelService_overridesChangedElsewhere =>
      'モデルのリクエスト設定が別の場所で変更されました。開き直してから編集してください。';

  @override
  String modelService_saveFailed(Object error) {
    return '保存に失敗しました：$error';
  }

  @override
  String get modelService_keyHintNew => 'キーを入力（ローカルサービスは空欄可）';

  @override
  String get modelService_keyHintVendor => 'このサービスのキーを入力';

  @override
  String get modelService_keyHintSaved => '保存済み。空欄のままなら変更しません';

  @override
  String modelService_enabledModels(Object count) {
    return '有効なモデル $count 件';
  }

  @override
  String get modelService_pendingSave => '未保存';

  @override
  String get modelService_saved => '保存済み';

  @override
  String get modelService_enable => '有効';

  @override
  String get modelService_testConnection => '接続をテスト';

  @override
  String get modelService_delete => 'サービスを削除';

  @override
  String get modelService_save => 'サービスを保存';

  @override
  String get modelService_saving => 'サービスを保存中';

  @override
  String get modelService_notConfigured => '未設定';

  @override
  String get modelService_optional => '空欄可';

  @override
  String get modelService_editConnection => '編集';

  @override
  String get modelService_collapse => '閉じる';

  @override
  String get modelService_connectionSettings => '接続設定';

  @override
  String get modelService_dragToReorder => 'ドラッグしてモデルを並べ替え';

  @override
  String get modelService_capacityTooltip => 'コンテキスト / 最大出力（詳細で調整できます）';

  @override
  String get modelService_advanced => '詳細';

  @override
  String modelService_removeModel(Object name) {
    return 'モデル $name を削除';
  }

  @override
  String get modelService_linkedInterfaces => '関連する機能';

  @override
  String get modelService_noLinkedInterfaces => 'まだ機能に関連付けられていません';

  @override
  String get modelService_advancedSettings => '詳細設定';

  @override
  String get modelService_requestTimeout => 'リクエストのタイムアウト';

  @override
  String get modelService_requestTimeoutHelp => '1 回のリクエストの最大待ち時間';

  @override
  String get modelService_seconds => '秒';

  @override
  String get modelService_maxConcurrency => '最大同時実行数';

  @override
  String get modelService_maxConcurrencyHelp => 'このサービスで同時に処理するリクエスト数';

  @override
  String get modelService_countUnit => '';

  @override
  String get modelService_retry => '失敗時の再試行';

  @override
  String get modelService_retryHelp => '接続の失敗時やサービスの混雑時に再試行します';

  @override
  String get modelService_searchModelId => 'モデル ID を検索…';

  @override
  String get modelService_serviceModels => 'サービスのモデル';

  @override
  String get modelService_fetchList => '一覧を取得';

  @override
  String get modelService_catalogEmpty =>
      '「一覧を取得」でこのサービスのモデルを読み込むか、\n右側でモデル ID を手動で追加します。';

  @override
  String get modelService_noMatchingModels => '一致するモデルはありません';

  @override
  String get modelService_catalogLimitTooltip => 'カタログ上限：コンテキスト / 最大出力';

  @override
  String get modelService_searchAddedModels => '追加したモデルを検索…';

  @override
  String get modelService_modelSettings => 'モデル設定';

  @override
  String get modelService_addedEmpty => '左側でチェックするか、下でモデルを追加してください';

  @override
  String get modelService_customModelId => 'カスタムモデル ID';

  @override
  String get modelService_customModelHelp => '一覧に出てこないモデルを追加します';

  @override
  String get modelService_addCustomModel => 'カスタムモデルを追加';

  @override
  String get modelCard_positiveInteger => '正の整数を入力してください';

  @override
  String modelCard_catalogLimit(Object limit) {
    return 'カタログ上限 $limit';
  }

  @override
  String get modelCard_outputExceedsContext => '出力はコンテキストウィンドウを超えられません';

  @override
  String get modelCard_contextWindow => 'コンテキストウィンドウ';

  @override
  String get modelCard_maxOutput => '最大出力';

  @override
  String get modelCard_unlabeled => '未記載';

  @override
  String get modelCard_protocolStandard => '標準';

  @override
  String get modelCard_protocolAdaptive => '自動調整';

  @override
  String get modelCard_default => '既定';

  @override
  String get modelCard_thinkingLevels => '思考レベル';

  @override
  String get modelCard_thinkingLevelsUnlisted => 'カタログに記載がありません。手動で有効にできます';

  @override
  String get modelCard_thinkingLevelsFromCatalog =>
      'ローカルカタログに基づき対応レベルにチェックしています。実際の API に合わせて調整できます。';

  @override
  String get modelCard_thinkingProtocol => '思考プロトコル';

  @override
  String get modelCard_defaultThinkingLevel => '既定の思考レベル';

  @override
  String get modelCard_alias => '別名';

  @override
  String get modelCard_aliasHelp =>
      'モデル名を表示する場所で使われます。リクエストには引き続きモデル ID を使います。';

  @override
  String get modelCard_aliasExample => '例：fast';

  @override
  String get modelCard_capabilities => '機能';

  @override
  String get modelCard_images => '画像';

  @override
  String get modelCard_nativeSearch => 'ネイティブ Web 検索';

  @override
  String get modelCard_nativeSearchHelp =>
      'アプリはまだこの接続のネイティブ検索に対応していません。ベンダーや他の API が検索に非対応という意味ではありません。';

  @override
  String get modelOverrides_duplicateHeader => 'ヘッダー名が重複しています';

  @override
  String get modelOverrides_fieldNameRequired => 'フィールド名を入力してください';

  @override
  String get modelOverrides_duplicateField => 'フィールド名が重複しています';

  @override
  String get modelOverrides_invalidJson => '有効な JSON 値を入力してください';

  @override
  String get modelOverrides_customBody => 'カスタム Body';

  @override
  String get modelOverrides_customHeaders => 'カスタム Headers';

  @override
  String get modelOverrides_fieldName => 'フィールド名';

  @override
  String get modelOverrides_headerName => 'ヘッダー名';

  @override
  String get modelOverrides_valueJson => '値（JSON）';

  @override
  String get modelOverrides_value => '値';

  @override
  String get modelOverrides_removeItem => 'この項目を削除';

  @override
  String get modelOverrides_body => 'リクエストボディ';

  @override
  String get modelOverrides_headers => 'リクエストヘッダー';

  @override
  String modelOverrides_itemCount(Object count) {
    return '$count 件';
  }

  @override
  String get modelOverrides_valueTypes => '文字列・数値・真偽値・配列・オブジェクトに対応';

  @override
  String get modelOverrides_addBodyField => 'ボディのフィールドを追加';

  @override
  String get modelOverrides_addHeader => 'ヘッダーを追加';

  @override
  String get promptTranslation_translating => '翻訳中';

  @override
  String get promptTranslation_needsModel => '翻訳 · 先にモデルを設定';

  @override
  String promptTranslation_withRoute(Object provider, Object model) {
    return '翻訳 · $provider / $model';
  }

  @override
  String get promptTranslation_actions => '翻訳の操作';

  @override
  String get promptTranslation_promptChanged =>
      'プロンプトが変更されたため、新しい編集は上書きしませんでした';

  @override
  String get promptTranslation_nothingToTranslate => '翻訳する通常のテキストはありません';

  @override
  String promptTranslation_failed(Object error) {
    return '翻訳に失敗しました：$error';
  }

  @override
  String get promptTranslation_setupTitle => '先に翻訳モデルを設定してください';

  @override
  String get promptTranslation_setupBody =>
      '翻訳にはサービスとモデルを明示的に選ぶ必要があります。「設定 → 連携 → モデルとAPI」でサービスを追加してモデル一覧を取得し、プロンプト翻訳のモデルを選択してください。';

  @override
  String get promptTranslation_later => '後で';

  @override
  String get promptTranslation_openSettings => '設定を開く';

  @override
  String get promptTranslation_toolTitle => '翻訳';

  @override
  String get promptTranslation_noModel => 'モデル未設定';

  @override
  String get promptTranslation_configureModel => '翻訳モデルを設定';

  @override
  String get promptTranslation_translateNew => '追加した内容を翻訳';

  @override
  String get promptTranslation_undoRestore => '原文への復元を取り消し、翻訳ブロックに戻す';

  @override
  String get promptTranslation_restoreAll => 'すべての翻訳ブロックを原文テキストに戻す';

  @override
  String get promptTranslation_tutorial => '使い方';

  @override
  String get promptTranslation_guideBack => '操作に戻る';

  @override
  String get promptTranslation_guideMiddleTitle => 'ブロックを中クリック';

  @override
  String get promptTranslation_guideMiddleText => '原文と訳文を切り替え';

  @override
  String get promptTranslation_guideSourceTitle => '原文を左クリック';

  @override
  String get promptTranslation_guideSourceText => 'カーソルを置いて直接編集';

  @override
  String get promptTranslation_guideReadingTitle => '訳文を左クリック';

  @override
  String get promptTranslation_guideReadingText => 'ブロック編集を開く';

  @override
  String get promptTranslation_guideCtrlTitle => 'Ctrl + クリック / ドラッグ選択';

  @override
  String get promptTranslation_guideCtrlText => '編集画面でタグ検索 / 関連タグ';

  @override
  String get promptTranslation_guideConvertTitle => '↑ 訳文から原文へ';

  @override
  String get promptTranslation_guideConvertText => '↓ 原文から訳文へ。確認してから保存';

  @override
  String get promptTranslation_guideRestoreTitle => 'A / 復元';

  @override
  String get promptTranslation_guideRestoreText => 'グループ全体を原文に戻す / 翻訳ブロックに戻す';

  @override
  String get promptTranslation_middleButton => 'マウス中ボタン';

  @override
  String get promptTranslation_leftButton => 'マウス左ボタン';

  @override
  String get promptTranslation_blockShowingOriginal => '翻訳ブロック（原文を表示）';

  @override
  String get promptTranslation_blockShowingReading => '翻訳ブロック（訳文を表示）';

  @override
  String get promptTranslation_blockNeedsReview => '原文が変更されました · 訳文の更新が必要です';

  @override
  String get promptTranslation_badgeTooltip => '原文が変更されました。訳文の同期が必要です';

  @override
  String get promptTranslation_sourceChanged => '原文が変更されました。翻訳ブロックを開き直してください';

  @override
  String promptTranslation_retranslateFailed(Object error) {
    return '再翻訳に失敗しました：$error';
  }

  @override
  String get promptTranslation_draftChanged =>
      '内容が変更されました。もう一度変換してください。新しい下書きは保持されています';

  @override
  String promptTranslation_convertFailed(Object error) {
    return '変換に失敗しました。下書きは保持されています：$error';
  }

  @override
  String get promptTranslation_invalidResultFormat =>
      '変換結果の形式が正しくありません。下書きは保持されています';

  @override
  String get promptTranslation_noValidText =>
      'モデルが有効なテキストを返しませんでした。下書きは保持されています';

  @override
  String get promptTranslation_invalidResultContent =>
      '変換結果に無効な書式が含まれています。下書きは保持されています';

  @override
  String get promptTranslation_incompleteStructure =>
      '変換結果の重みまたはグループが不完全です。下書きは保持されています';

  @override
  String get promptTranslation_inputRequired => '先に変換する内容を入力してください';

  @override
  String get wiki_configureTagModel => '先に「モデルとAPI」で利用できるタグ翻訳モデルを設定してください。';

  @override
  String get blockOrganizer_barrierLabel => 'ブロックの整理';

  @override
  String get blockOrganizer_replaceTitle => '同じ元のブロックを置き換えますか？';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '移動先に同じ元のコピーが $count 件あります。置き換えると元のブロックはライブラリで非表示になりますが、プロンプトに挿入済みのインスタンスは引き続き元のブロックを参照できます。';
  }

  @override
  String blockOrganizer_replaceCopyBody(Object count) {
    return '移動先に同じ元のコピーが $count 件あります。置き換えると移動先のコピーの内容が更新され、元のブロックは残ります。';
  }

  @override
  String get blockOrganizer_replace => '置き換え';

  @override
  String get blockOrganizer_customTagColor => 'タグの色をカスタマイズ';

  @override
  String get blockOrganizer_colorHint => '#RRGGBB または #AARRGGBB';

  @override
  String get blockOrganizer_invalidColor => '6 桁または 8 桁の 16 進数カラーを入力してください';

  @override
  String blockOrganizer_deleteFolderConfirm(Object name) {
    return '「$name」を削除しますか？中のブロックはルートに移動します。';
  }

  @override
  String blockOrganizer_deleteCollectionConfirm(Object name) {
    return '「$name」を削除しますか？ブロック自体は残ります。';
  }

  @override
  String get blockOrganizer_titleFavorites => 'お気に入りとコレクション';

  @override
  String get blockOrganizer_titleFolders => 'フォルダーを選択';

  @override
  String blockOrganizer_itemCount(Object count) {
    return '$count 件';
  }

  @override
  String get blockOrganizer_search => '検索';

  @override
  String get blockOrganizer_name => '名前';

  @override
  String get blockOrganizer_customColor => 'カスタムカラー…';

  @override
  String get blockOrganizer_newCollection => '新しいコレクション';

  @override
  String get blockOrganizer_newCollectionFolder => '新しいコレクションフォルダー';

  @override
  String get blockOrganizer_newTag => '新しいタグ';

  @override
  String get blockOrganizer_newFolder => '新しいフォルダー';

  @override
  String get blockOrganizer_rootUncategorized => 'ルート / 未分類';

  @override
  String get blockOrganizer_manageDrag => '管理（ドラッグで並べ替え）';

  @override
  String get blockLibrary_dragSelectedHint =>
      '選択したブロックを左側のお気に入りやフォルダーにドラッグし、離したらコピーか移動を選びます。';

  @override
  String blockLibrary_blockCount(Object count) {
    return '$count 件のブロック';
  }

  @override
  String get blockLibrary_changedSelectAgain =>
      'ブロックライブラリが変更されました。選び直してから再試行してください';

  @override
  String get blockLibrary_hiddenSource => '非表示のブロックは整理の対象にできません';

  @override
  String get blockLibrary_sameSourceSelected =>
      '選択に同じ元のコピーが含まれています。別々に整理してください';

  @override
  String get blockLibrary_sameSourceExists => '同じ元のブロックが既にあります。置き換えを確認してください';

  @override
  String get blockLibrary_collectionMissing => 'コレクションが存在しません';

  @override
  String get promptBlockEditor_appearance => 'ブロックの外観';

  @override
  String get promptBlockEditor_imageUnreadable => '選択した画像を読み込めません';

  @override
  String get blockAppearance_classic => 'クラシック';

  @override
  String get blockAppearance_stripes => '細いストライプ';

  @override
  String get blockAppearance_dots => 'ドット';

  @override
  String get blockAppearance_solid => 'ベタ塗り';

  @override
  String get blockAppearance_gradient => 'グラデーション';

  @override
  String get blockAppearance_translation => '翻訳';

  @override
  String get opusUsage_exhausted => 'アカウントの無料枠を使い切りました。V5 の生成は Anlas で課金されます';

  @override
  String opusUsage_remaining(Object percent) {
    return 'アカウントの無料枠の残り $percent%';
  }

  @override
  String opusUsage_recharging(Object time) {
    return '回復中：次の +1% まで $time';
  }

  @override
  String get opusUsage_notRecharging => '現在は回復しません（回復しきい値を超えているか、使い切っています）';

  @override
  String get opusUsage_clickToRefresh => 'クリックして更新';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 時間 $minutes 分';
  }

  @override
  String opusUsage_hours(Object hours) {
    return '$hours 時間';
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
  String get metadataImport_noCharactersReplaceClears =>
      'キャラクターデータがありません。置き換えモードでは現在のキャラクターが消去されます';

  @override
  String get metadataImport_replaceCharacters => 'キャラクターを置き換え';

  @override
  String get metadataImport_appendCharacters => 'キャラクターを追加';

  @override
  String get drop_dragToShare => 'ドラッグして共有';

  @override
  String promptSyntax_weightTooLarge(Object value) {
    return '数値の重みが大きすぎます：$value::';
  }

  @override
  String promptSyntax_spaceBeforeColons(Object value) {
    return '重みの数値と :: の間に空白は入れられません：$value ::';
  }

  @override
  String promptSyntax_weightAfterColons(Object value) {
    return '数値の重みは :: の前に書いてください：::$value';
  }

  @override
  String get update_errorInAppUnsupported => 'このバージョンはアプリ内の自動更新に対応していません';

  @override
  String get update_errorNoInstallablePackage => '自動インストールできる更新パッケージが見つかりません';

  @override
  String get update_errorMissingSha256 => '更新パッケージに SHA256 チェックサムがありません';

  @override
  String get update_errorDiskFull => 'ディスクの空き容量が不足しているため、更新パッケージを保存できません';

  @override
  String get update_errorWriteFailed => '更新パッケージの書き込みに失敗しました';

  @override
  String get update_errorDownloadFailed => '更新パッケージのダウンロードに失敗しました';

  @override
  String get update_errorSizeMismatch => '更新パッケージのサイズ確認に失敗しました';

  @override
  String get update_errorChecksumMismatch => '更新パッケージの検証に失敗しました';

  @override
  String get update_errorResumeRejected => 'サーバーが更新パッケージの再開要求を拒否しました';

  @override
  String get update_errorEmptyResponse => '更新サーバーが空の応答を返しました';

  @override
  String get update_errorPlatformUnsupported => 'このプラットフォームはアプリ内の自動更新に対応していません';

  @override
  String get update_errorPackageRemoved => '更新パッケージが削除されました。もう一度ダウンロードしてください';

  @override
  String get update_errorPackageCorrupted => '更新パッケージが破損しています。もう一度ダウンロードしてください';

  @override
  String get update_errorLaunchFailed => '更新プログラムの起動に失敗しました';

  @override
  String get update_errorCheckFailed => '更新の確認に失敗しました';

  @override
  String get update_errorCheckUnknown => '更新の確認中に不明なエラーが発生しました';

  @override
  String update_errorLogPath(Object path) {
    return 'ログ：$path';
  }

  @override
  String get update_errorInstallFailed => '更新のインストールに失敗しました';

  @override
  String get update_errorInstallFailedSeeLog =>
      '更新のインストールに失敗しました。更新ログを確認してください';

  @override
  String get auth_tokenEmpty => 'トークンが空のため確認できません';

  @override
  String get auth_tokenFormatInvalid => 'トークンの形式が無効です';

  @override
  String get auth_tokenInvalidOrExpired =>
      'トークンが無効か期限切れです。正しいか確認してください。Persistent Token は pst- で始まります。';

  @override
  String get auth_tokenMustStartPst => 'トークンの形式が無効です。pst- で始まる必要があります';

  @override
  String get auth_tokenFormatDetail =>
      'トークンの形式が無効です。Persistent Token は pst- に続けて 10 文字以上が必要です。入力したトークンを確認してください。';

  @override
  String get danbooru_credentialsExpired => '認証情報が無効になりました。もう一度ログインしてください';

  @override
  String get danbooru_networkRetryLater => 'ネットワーク接続に失敗しました。回復後に再試行します';

  @override
  String get danbooru_invalidCredentials =>
      '認証情報を確認できません。ユーザー名と API キーを確認してください';

  @override
  String danbooru_verifyFailed(Object error) {
    return '確認に失敗しました：$error';
  }

  @override
  String get danbooru_credentialsRequired => 'ユーザー名と API キーは空にできません';

  @override
  String get danbooru_networkCheck => 'ネットワーク接続に失敗しました。接続を確認してください';

  @override
  String get danbooru_loginFailedNetwork => 'ログインに失敗しました。ネットワーク接続を確認してください';

  @override
  String get danbooru_blacklistLoginRequired => '先に Danbooru アカウントにログインしてください';

  @override
  String get danbooru_blacklistPushFailed => 'Danbooru のブラックリストを送信できませんでした';

  @override
  String danbooru_blacklistSyncFailed(Object error) {
    return '同期に失敗しました：$error';
  }

  @override
  String comfyui_submitFailed(Object detail) {
    return 'ワークフローの送信に失敗しました：$detail';
  }

  @override
  String comfyui_uploadFailed(Object detail) {
    return '画像のアップロードに失敗しました：$detail';
  }

  @override
  String comfyui_fetchImageFailed(Object detail) {
    return '画像の取得に失敗しました：$detail';
  }

  @override
  String comfyui_historyMissing(Object id) {
    return 'タスク履歴が見つかりません：$id';
  }

  @override
  String get comfyui_unknownError => '不明なエラー';

  @override
  String comfyui_cannotConnect(Object url) {
    return 'ComfyUI サーバー（$url）に接続できません';
  }

  @override
  String get comfyui_noOutput => 'タスクの出力がありません';

  @override
  String comfyui_nodesNoImage(Object nodes) {
    return '指定した出力ノードに画像がありません：$nodes';
  }

  @override
  String get comfyui_noImageOutput => 'タスクの画像出力がありません';

  @override
  String get comfyui_executionError => '実行エラー';

  @override
  String comfyui_missingNodes(Object nodes) {
    return 'ComfyUI のノードが不足しています：$nodes。ComfyUI で該当するカスタムノードをインストールまたは有効化し、ComfyUI を再起動してください。';
  }

  @override
  String get enhance_cannotReadSize => '画像サイズを読み取れません';

  @override
  String enhance_upscaleFailed(Object error) {
    return 'アップスケールに失敗しました：$error';
  }

  @override
  String enhance_vibeEncodeFailed(Object error) {
    return 'Vibe のエンコードに失敗しました：$error';
  }

  @override
  String enhance_enhanceFailed(Object error) {
    return '画像の補正に失敗しました：$error';
  }

  @override
  String enhance_annotateFailed(Object error) {
    return '画像の注釈付けに失敗しました：$error';
  }

  @override
  String get enhance_timeout => 'リクエストがタイムアウトしました';

  @override
  String get enhance_networkError => 'ネットワーク接続エラー';

  @override
  String enhance_serverError(Object status) {
    return 'サーバーがエラーを返しました：$status';
  }

  @override
  String enhance_serverErrorDetail(Object status, Object detail) {
    return 'サーバーがエラーを返しました：$status（$detail）';
  }

  @override
  String get proxy_connectTimeout => '接続がタイムアウトしました';

  @override
  String get proxy_cannotConnect => 'サーバーに接続できません';

  @override
  String get proxy_connectFailed => '接続に失敗しました';

  @override
  String get proxy_testServerUnreachable => 'テストサーバーに接続できません';

  @override
  String proxy_testFailed(Object error) {
    return 'テストに失敗しました：$error';
  }

  @override
  String get avatar_noFilePath => 'ファイルパスを取得できません';

  @override
  String get avatar_sourceMissing => '元のファイルが存在しないか、削除されました';

  @override
  String avatar_copyFailed(Object error) {
    return 'ファイルをコピーできません：$error';
  }

  @override
  String avatar_saveFailed(Object error) {
    return 'アバターを保存できません：$error';
  }

  @override
  String avatar_operationFailed(Object error) {
    return '操作に失敗しました：$error';
  }

  @override
  String get vibeExport_rawImage => '元の画像';

  @override
  String get vibeExport_vibePreview => 'Vibe プレビュー';

  @override
  String get vibeExport_libraryThumbnail => 'ライブラリのサムネイル';

  @override
  String get vibeExport_pngTitle => 'PNG Vibe 画像をエクスポート';

  @override
  String get vibeExport_pngDirectoryTitle => 'PNG の書き出し先フォルダーを選択';

  @override
  String get vibeExport_fileTitle => 'Vibe ファイルをエクスポート';

  @override
  String get vibeExport_bundleTitle => 'Vibe バンドルをエクスポート';

  @override
  String get vibeExport_zipTitle => 'Vibe ZIP をエクスポート';

  @override
  String get vibeExport_nothingToExport => 'エクスポートできる Vibe 項目がありません';

  @override
  String get vibeImport_fileParseFailed => 'ファイルの解析に失敗しました';

  @override
  String get vibeImport_importFiles => 'ファイルをインポート';

  @override
  String get vibeImport_noVibeData => '画像に有効な Vibe データが含まれていません';

  @override
  String get vibeImport_importImages => '画像をインポート';

  @override
  String get vibeImport_encodingParseFailed => 'エンコードの解析に失敗しました';

  @override
  String get vibeImport_importEncodings => 'エンコードをインポート';

  @override
  String vibeImport_namingCancelled(Object name) {
    return '名前の入力がキャンセルされたためスキップしました：$name';
  }

  @override
  String vibeImport_nameEmpty(Object name) {
    return '名前が空のためスキップしました：$name';
  }

  @override
  String vibeImport_nameConflict(Object name) {
    return '名前が重複しているためスキップしました：$name';
  }

  @override
  String get vibeImport_saveFailed => '保存に失敗しました';

  @override
  String vibeFile_missingRawImage(Object file) {
    return 'ファイルに使用できる元画像データがありません：$file（type=image）。破損または不完全な可能性があるため、削除して保存し直してください。';
  }

  @override
  String get generation_countMustBePositive => '生成数は 0 より大きくしてください';

  @override
  String get generation_allTasksFailed => 'すべての生成タスクが失敗しました';

  @override
  String get generation_failedShort => '生成に失敗しました';

  @override
  String generation_tasksFailedAfterRetry(Object count) {
    return '$count 件のタスクが再試行後も失敗しました';
  }

  @override
  String get generation_streamFallbackUnavailable =>
      'ストリーミング生成に対応しておらず、自動で切り替えられません（パラメーターが失われました）';

  @override
  String generation_streamFallbackFailed(Object error) {
    return '非ストリーミング生成への切り替えに失敗しました：$error';
  }

  @override
  String get generation_batchSizeMustBePositive => 'バッチ数とバッチサイズは 0 より大きくしてください';

  @override
  String get clipboard_unsupportedPlatform =>
      'このプラットフォームはシステムのクリップボードに対応していません';

  @override
  String get clipboard_decodeFailed => 'クリップボードにコピーする画像をデコードできません';

  @override
  String drop_remoteImageTooLarge(Object size) {
    return 'リモート画像のダウンロードが $size MB を超えています';
  }

  @override
  String get apiEndpoint_empty => 'API アドレスは空にできません';

  @override
  String get apiEndpoint_invalid => 'API アドレスが無効です';

  @override
  String get apiEndpoint_httpOnly => 'http または https の API アドレスのみ対応しています';

  @override
  String get apiEndpoint_noExtras => 'API アドレスにクエリパラメーター・フラグメント・ユーザー情報は含められません';

  @override
  String gallery_folderInaccessible(Object error) {
    return '画像フォルダーにアクセスできません：$error';
  }

  @override
  String gallery_scanFailed(Object error) {
    return '画像のスキャンに失敗しました：$error';
  }

  @override
  String gallery_galleryInitFailed(Object error) {
    return 'ギャラリーの初期化に失敗しました：$error';
  }

  @override
  String vibeImport_imageProgress(Object current, Object total, Object source) {
    return '画像をインポート中（$current/$total）：$source';
  }

  @override
  String get vibeImport_clipboardSource => 'クリップボード';

  @override
  String get resolution_noAdjustment => '調整不要';

  @override
  String get dataRefresh_updating => 'データを更新中...';

  @override
  String dataRefresh_updatingService(Object service) {
    return '$service を更新中...';
  }

  @override
  String get imageUse_title => '画像を使用';

  @override
  String get imageUse_importContent => '取り込む内容';

  @override
  String get imageUse_characters => 'キャラクター';

  @override
  String get imageUse_characterMode => 'キャラクターの処理';

  @override
  String get imageMenu_details => '詳細';

  @override
  String get imageMenu_creation => '生成・参照';

  @override
  String get imageMenu_editAndDerive => '編集・派生';

  @override
  String get imageMenu_more => 'その他の操作';

  @override
  String get imageMenu_fileActions => 'ファイル操作';

  @override
  String get imageMenu_saveToBlock => 'ブロックに保存';

  @override
  String get settings_highAnlasCostEstimate => '推定消費量';

  @override
  String get settings_highAnlasCostThresholdLabel => '通知のしきい値';

  @override
  String get settings_highAnlasCostQuestion => 'このまま生成しますか？';

  @override
  String get bridge_title => 'ローカル接続';

  @override
  String get bridge_agent => '外部 Agent';

  @override
  String get bridge_agentHint => 'ローカルコマンドを実行できる Agent に手順を渡します。';

  @override
  String get bridge_synced => '現在の内容を確認済み';

  @override
  String get bridge_changed => '内容が変わりました。再確認待ち';

  @override
  String get bridge_waiting => '接続待ち';

  @override
  String get bridge_ready => '操作待ち';

  @override
  String bridge_clients(int count) {
    return '$count 個の Agent が接続中';
  }

  @override
  String bridge_activity(Object client, Object action) {
    return '$client：$action';
  }

  @override
  String get bridge_read => '設定を読み取り';

  @override
  String get bridge_write => '設定を更新';

  @override
  String get bridge_quote => '消費量を見積もり';

  @override
  String get bridge_generate => '画像を生成';

  @override
  String get bridge_cancel => '生成を停止';

  @override
  String get bridge_recent => '最近の操作';

  @override
  String get bridge_empty => '操作履歴はありません';

  @override
  String get bridge_copyGuide => '接続手順をコピー';

  @override
  String get bridge_showGuide => '手順を表示';

  @override
  String get bridge_copied => '手順をコピーしました';

  @override
  String get bridge_disconnect => 'Agent の接続を終了';

  @override
  String get bridge_settings => '接続設定';

  @override
  String get bridge_clientMissing => '同梱クライアントがありません。Studio を更新してください。';

  @override
  String get bridge_conflict => '内容が変更されました。再度読み取ってください。';

  @override
  String get bridge_busy => '別の操作が進行中です';

  @override
  String get bridge_interrupted => '操作が中断されました';

  @override
  String get bridge_failed => '操作に失敗しました。Agent の応答を確認してください。';

  @override
  String get bridge_timeout => '操作がタイムアウトしました。再試行してください。';

  @override
  String bridge_guide(Object clientPath) {
    return 'ローカル接続で W.O.F NAI Studio の操作を支援してください。\nクライアント：$clientPath\n\n1. シェルに合わせてパスを引用し、status --name <名前> で接続を確認してください。手順のコピーだけでは接続されません。\n2. get --name <名前> --out current.json で現在の状態を読み取ります。編集可能な原文は _draft.fields、競合確認用の値は field_versions にあります。他の値に含まれる品質タグを原文へ重複して書き戻さないでください。\n3. ユーザーが許可した項目だけを changes.json に保存し、set-json changes.json --base current.json --name <名前> を実行します。Studio はバックアップ後に対象項目を再確認します。競合時は中止して再読込し、新しい編集を上書きしないでください。readback を確認します。characters はリスト全体の置換です。無関係な名前、有効状態、位置、id を保持してください。参照画像は現在読み取り専用です。\n4. 接続や設定編集は生成の許可を意味しません。明示的な生成指示がある場合、quote --out quote.json --name <名前> を実行し、推定 Anlas 単価と読込済みの残高を報告します。最終請求はサーバーによります。許可と報告の後に gen --quote quote.json --authorized --name <名前> を実行します。1 回 1 枚、設定変更後は再見積もりが必要です。\n5. 操作完了後は切断します。Krita と同時接続できます。busy は処理完了を待ち、エラー後に即座の再試行を繰り返さないでください。Studio の停止、Ctrl+C、または返された request_id を使った cancel <request_id> --name <同じ名前> で生成を停止できます。発見ファイルのセッション秘密鍵を出力しないでください。\n';
  }

  @override
  String get editor_drawMask => 'マスクを描画';

  @override
  String get editor_eraseMask => 'マスクを消去';

  @override
  String get editor_squareBrush => '四角形ブラシ';

  @override
  String get editor_focusedArea => '注目範囲';

  @override
  String get editor_minimumContext => '最小参照範囲';

  @override
  String get editor_maskAppearance => 'マスクの表示';

  @override
  String get editor_maskColor => 'マスクの色';

  @override
  String get editor_maskOpacity => 'マスクの不透明度';

  @override
  String get editor_maskBorder => '境界線';

  @override
  String get editor_patternSolid => '単色';

  @override
  String get editor_patternLines => '斜線';

  @override
  String get editor_patternCrosshatch => 'クロスハッチ';

  @override
  String get editor_patternDots => 'ドット';

  @override
  String get editor_patternGrid => 'グリッド';

  @override
  String get editor_patternChecker => '市松模様';

  @override
  String get editor_patternHearts => 'ハート';

  @override
  String get editor_resize => 'サイズ変更';

  @override
  String get editor_penSize => 'ペンのサイズ';

  @override
  String get editor_sourceChanged => '編集中に元画像が変更されました。エディターを開き直してください。';

  @override
  String get editor_draw => '描画';

  @override
  String get editor_erase => '消去';

  @override
  String get editor_select => '選択';

  @override
  String get editor_lasso => '投げ縄';

  @override
  String get editor_roundTip => '円形';

  @override
  String get editor_softRoundTip => 'ソフト円形';

  @override
  String get editor_squareTip => '四角';

  @override
  String get editor_pressureSensitivity => '筆圧感知';

  @override
  String get editor_hsvAdjustment => 'HSV 調整';

  @override
  String get editor_hue => '色相';

  @override
  String get editor_cloneSourceHint => 'Alt+クリックでコピー元を設定';

  @override
  String get editor_colorAlpha => '透明度';

  @override
  String get editor_colorHex => 'カラー HEX';

  @override
  String get editor_closestValidSize => '最も近い有効な生成サイズに切り抜く';
}
