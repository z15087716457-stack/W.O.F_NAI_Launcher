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
  String get common_favorite => 'お気に入り';

  @override
  String get common_unfavorite => 'お気に入りから削除';

  @override
  String get common_ok => 'OK';

  @override
  String get common_exit => '終了';

  @override
  String get common_grid => 'グリッド';

  @override
  String get common_multiSelect => '複数選択';

  @override
  String get common_category => 'カテゴリ';

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
  String get generation_canvasSendToTools => 'ディレクターツールに送る';

  @override
  String get generation_canvasPinImage => '画像を固定';

  @override
  String get generation_canvasUnpinImage => '固定を解除';

  @override
  String get generation_canvasUseSeed => 'クリックしてこのシードを再利用';

  @override
  String get generation_history => '履歴';

  @override
  String get generation_failedStreamSnapshot => 'スナップショットが失敗しました';

  @override
  String get generation_failedStreamSnapshotHint =>
      '生成が完了しませんでした。最後のプレビュー フレームのみが保持されます。保存したり、お気に入りに登録したり、画像ワークフローに使用したりすることはできません。';

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
  String get img2img_placeOnCanvas => 'キャンバスに配置';

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
  String get generation_variationOriginal => '元画像';

  @override
  String get generation_variationSizeUnsupported =>
      'バリエーションは 300 万画素以下の元画像に対応しています。';

  @override
  String get img2img_generateVariations => 'バリエーションの生成';

  @override
  String get img2img_directorTools => 'ディレクターツール';

  @override
  String get img2img_directorApplied => 'ディレクターツールの結果を新しいソース イメージとして適用しました';

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
  String get img2img_novelAiCloudUpscaleTitle => 'NovelAI クラウド拡大';

  @override
  String get img2img_cloudUpscaleSizeLimit =>
      'NovelAI クラウド拡大は 3MP 以下の入力画像に対応しています。';

  @override
  String get img2img_upscaleRegularModel => 'レギュラーモデル';

  @override
  String get img2img_upscaleModel => '拡大モデル';

  @override
  String get img2img_startUpscale => '拡大を開始';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 拡大が完了しました';

  @override
  String get img2img_decodeSourceFailed => 'ソース画像のデコードに失敗しました';

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
  String get editor_layers => 'レイヤー';

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
  String get editor_effectBrightness => '明るさ';

  @override
  String get editor_effectSaturation => '彩度';

  @override
  String get editor_changeCanvasSize => 'キャンバス サイズの変更';

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
  String get editor_maskLayerName => 'マスク';

  @override
  String get editor_emptyImageFile => 'ファイルが空です。有効な画像ファイルを選択してください';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return 'ファイルが大きすぎます ($sizeMB MB)。 50 MB 未満の画像を選択してください';
  }

  @override
  String get editor_parseImageFailed =>
      '画像ファイルの解析に失敗しました\nファイルが破損しておらず、その形式がサポートされていることを確認してください';

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
  String get vibe_info => 'Vibe 情報';

  @override
  String get vibe_name => '名前';

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
  String get onlineGallery_login => 'ログイン';

  @override
  String get onlineGallery_pleaseLogin => 'まずログインしてください';

  @override
  String get mediaType_video => 'ビデオ';

  @override
  String get mediaType_gif => 'GIF';

  @override
  String get onlineGallery_copied => 'コピーされました';

  @override
  String get onlineGallery_copyTags => 'タグをコピー';

  @override
  String get onlineGallery_sendToTextToImage => 'テキストから画像へ送信';

  @override
  String get onlineGallery_sentToTextToImage => 'text-to-image に送信されました';

  @override
  String get onlineGallery_noTagInfo => 'この画像にはタグ情報がありません';

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
  String get onlineGallery_ratingGeneral => '一般';

  @override
  String get onlineGallery_ratingSensitive => 'センシティブ';

  @override
  String get onlineGallery_ratingQuestionable => '疑問あり';

  @override
  String get onlineGallery_ratingExplicit => '露骨';

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
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return 'ダウンロード完了: $success 成功、$failed 失敗';
  }

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
  String get onlineGallery_aiTagRankingProcessing =>
      'ランキングを生成中です。しばらくしてから再試行してください。';

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
  String get onlineGallery_gelbooruReadOnly => '読み取り専用のお気に入り';

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
  String get localGallery_group_today => '今日';

  @override
  String get localGallery_group_yesterday => '昨日';

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
  String get localGallery_uncategorizedFolder => '未分類フォルダー';

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
  String get vibeLibrary_uncategorized => '未分類';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return '$count 件の Vibe をインポートしました';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return 'インポート完了: $success 成功、$failed 失敗';
  }

  @override
  String get vibeLibrary_save => 'ライブラリに保存';

  @override
  String get vibeLibrary_import => 'Vibe をインポート';

  @override
  String get vibeLibrary_sendToGeneration => '生成に送信';

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
  String get vibe_export_title => 'Vibe をエクスポート';

  @override
  String get vibe_selector_recent => '最近の';

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
  String get vibe_import_fileParseFailed => 'ファイルの解析に失敗しました';

  @override
  String get vibe_import_fileSelectionFailed => 'ファイルの選択に失敗しました';

  @override
  String get vibe_import_importFailed => 'インポートに失敗しました';

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
  String get selectAll => 'すべて選択';

  @override
  String get clearSelection => 'クリア';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 詳細';

  @override
  String get shortcut_action_vibe_detail_rename => '名前の変更';

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
  String get settings_defaultHivePath => 'デフォルト (./user-data/hive/)';

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
  String get toast_imageDataUnavailable => '画像データが利用できないため、コピーできません';

  @override
  String get toast_characterPromptCopied => 'キャラクタープロンプトをコピーしました';

  @override
  String toast_copiedTitle(Object title) {
    return '$title がコピーされました';
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
  String get common_expand => '展開する';

  @override
  String get common_collapse => '折りたたむ';

  @override
  String get detail_parsingMetadata => 'メタデータを解析しています...';

  @override
  String get detail_noMetadata => 'この画像にはメタデータがありません';

  @override
  String get detail_metadata => 'メタデータ';

  @override
  String get detail_modifiedTime => '更新日時';

  @override
  String get detail_fileSize => 'ファイルサイズ';

  @override
  String get detail_noContent => '(コンテンツなし)';

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
  String get model3d_addLayerTooltip => '3Dモデルレイヤーを追加';

  @override
  String get nav_preciseRefLibrary => '精密参照ライブラリ';

  @override
  String preciseRefLib_saved(String name) {
    return '精密参照ライブラリに保存しました：$name';
  }

  @override
  String get preciseRefLib_savedHint => 'ライブラリでパラメータを編集できます';

  @override
  String get preciseRefLib_imageMissing => '元画像ファイルが見つかりません';

  @override
  String get preciseRefLib_invalidImage => '画像形式を認識できないか、ファイルが破損しています';

  @override
  String preciseRefLib_importedCount(int count) {
    return '$count 枚の画像をインポートしました';
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
  String get editor_shiftEdges => 'エッジをシフト';

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
  String get promptBlockLibrary_allBlocks => 'すべてのブロック';

  @override
  String get promptBlockLibrary_rootFolder => 'ルート / 未分類';

  @override
  String get promptBlockLibrary_unnamedBlock => '無題のブロック';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '$count 回使用されました';
  }

  @override
  String get promptBlockPill_missing => '削除されたブロック';

  @override
  String get promptBlockPill_unknown => '無効なブロック';

  @override
  String get promptBlockLibrary_unnamedFolder => '無題のフォルダー';

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
  String get promptBlockLibrary_folder => 'フォルダー';

  @override
  String get promptBlockLibrary_settingsApplied => 'ブロック設定を現在の画像に読み込みました';

  @override
  String get promptBlockLibrary_settingsIncompatible =>
      'ブロック設定は対象モデルに対応していません。パラメータは変更されませんでした。';

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
  String get promptBlockLibrary_empty => 'プロンプトブロックはまだありません';

  @override
  String get promptBlockLibrary_noSearchResults => '一致するブロックがありません';

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
  String get promptBlockLibrary_exportLibraryBackup => 'ライブラリをバックアップ…';

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
  String get promptBlockLibrary_libraryImportTitle => 'ライブラリバックアップを選択';

  @override
  String promptBlockLibrary_importFailed(String error) {
    return 'インポートに失敗しました：$error';
  }

  @override
  String get promptBlockLibrary_sourceFile => 'ソースファイル';

  @override
  String get promptBlockLibrary_importedAt => 'インポート日時';

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
  String get nav_styleExplore => 'スタイル探索';

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
  String styleExplore_manualRunName(String time) {
    return '手動キャプチャ $time';
  }

  @override
  String get styleExplore_runBusy => '生成中です。しばらくしてからお試しください';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return 'ブロック「$name」として保存しました';
  }

  @override
  String get styleExplore_adoptBlockEmpty => '保存できる絵師の組み合わせや正のプロンプトがありません';

  @override
  String get promptBlockEditor_library => 'ブロックライブラリ';

  @override
  String get promptBlockPicker_title => 'ブロックを選択';

  @override
  String get promptBlockLibrary_selectImage => '画像を選択';

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
  String get img2img_masked => '背景透過';

  @override
  String get img2img_generated => '生成結果';

  @override
  String get img2img_blend => '合成結果';

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
  String get wiki_typeAllShort => 'すべて';

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
  String get auth_notSignedIn => '未ログイン';

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
  String get wiki_readingBilingual => '対訳';

  @override
  String get wiki_bilingualUnavailable => 'この翻訳には段落ごとに対応する原文がありません。訳文を表示しています';

  @override
  String get wiki_open => '開く';

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
  String get wiki_addToBlock => 'ブロックに追加';

  @override
  String get wiki_forward => '次へ';

  @override
  String get wiki_posts => '件の投稿';

  @override
  String get wiki_aliases => '別名';

  @override
  String get wiki_relatedTitle => 'よく一緒に使われるタグ';

  @override
  String get wiki_relatedHint => 'クリックで開く · Shift+クリックでブロックに追加';

  @override
  String get wiki_inDirectory => '所属ディレクトリ';

  @override
  String get wiki_noArticle => 'Wiki なし';

  @override
  String get wiki_moreCategories => 'その他';

  @override
  String get wiki_shortcutsHint =>
      'ショートカット: / 検索 · ↑↓ 移動 · Enter ブロックに追加 · B ブックマーク · Alt+←/→ 履歴';

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
  String get modelTask_translateTitle => '原文 → 表示言語';

  @override
  String get modelTask_promptReverseTitle => '表示言語 → 原文';

  @override
  String get modelTask_tagTranslateTitle => 'タグ翻訳・意味情報';

  @override
  String get modelTask_wikiTranslateTitle => '百科本文の翻訳';

  @override
  String get modelTask_translateDescription =>
      'プロンプトとブロックを翻訳し、重み・グループ・タグの意味を保ちます。';

  @override
  String get modelTask_promptReverseDescription =>
      '訳文での追加・削除・変更を原文に反映し、確認用に原文へ戻します。';

  @override
  String get modelTask_tagTranslateDescription =>
      '表示中のタグを翻訳し、既存資料を再利用して中国語の基本名・同義語・短い説明を補います。';

  @override
  String get modelTask_wikiTranslateDescription =>
      '百科本文を翻訳してレイアウトを整え、文脈に応じてクリックできるタグを選びます。';

  @override
  String get modelTask_connectionTest => 'モデル接続テスト';

  @override
  String get modelReasoning_serviceDefault => 'サービス既定';

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
      '翻訳では通常、思考は不要です。これらの機能は構造化出力を使うため、モデルが対応する最も低い思考レベルをおすすめします。';

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
  String get modelRequest_detailsAction => '詳細';

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
  String get promptTranslation_guideRestoreTitle => 'グループ全体の表示切替';

  @override
  String get promptTranslation_guideRestoreText => '翻訳メニューで原文 / 訳文をまとめて切り替え';

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
  String blockOrganizer_replaceMoveBody(Object count) {
    return '移動先に同じ元のコピーが $count 件あります。置き換えると元のブロックはライブラリで非表示になりますが、プロンプトに挿入済みのインスタンスは引き続き元のブロックを参照できます。';
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
  String opusUsage_regularRemaining(Object percent) {
    return '通常の無料枠：$percent%';
  }

  @override
  String opusUsage_reserveRemaining(Object percent) {
    return '予備電池の追加枠（有効化済み）：$percent%';
  }

  @override
  String get opusUsage_usingRegular => '通常枠を優先し、使い切ると予備枠を消費します';

  @override
  String get opusUsage_usingReserve => '通常枠を使い切り、予備電池の枠を使用中';

  @override
  String get opusUsage_regularEmpty => '通常枠を使い切りました。利用可能な予備枠はありません';

  @override
  String get opusUsage_exhausted => 'アカウントの枠を使い切りました。V5 の生成は Anlas で課金されます';

  @override
  String opusUsage_recharging(Object time) {
    return '通常枠の回復中：次の +1% まで $time';
  }

  @override
  String get opusUsage_notRecharging => '通常枠の回復カウントダウンはありません';

  @override
  String get opusUsage_clickToRefresh => 'クリックして更新';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours 時間 $minutes 分';
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
  String get model3d_direction => '光の方向';

  @override
  String get model3d_front => '正面';

  @override
  String get model3d_frontTop => '正面上';

  @override
  String get model3d_top => '真上';

  @override
  String get model3d_left => '左';

  @override
  String get model3d_right => '右';

  @override
  String get model3d_back => '背面';

  @override
  String get model3d_shadows => '影';

  @override
  String get model3d_quality => '品質';

  @override
  String get model3d_veryLow => '非常に低い';

  @override
  String get model3d_low => '低';

  @override
  String get model3d_medium => '標準';

  @override
  String get model3d_high => '高';

  @override
  String get model3d_veryHigh => '非常に高い';

  @override
  String get model3d_display => '表示';

  @override
  String get model3d_showBones => 'ボーンを表示';

  @override
  String get model3d_bones => 'ボーンリスト';

  @override
  String get model3d_noBones => 'ボーンが見つかりません';

  @override
  String get model3d_morphs => 'モーフターゲット';

  @override
  String get model3d_noMorphs => 'モーフターゲットが見つかりません';

  @override
  String get model3d_settings => '3D レンダリング設定';

  @override
  String get model3d_resetModel => 'モデル位置をリセット';

  @override
  String get model3d_removeModel => 'モデルを削除';

  @override
  String get model3d_removeConfirm => 'このモデルを削除しますか？未保存のモデル編集は失われます。';

  @override
  String get model3d_toolTransform => 'モデル変形';

  @override
  String get model3d_toolPose => 'モデルポーズ';

  @override
  String get localUpscale_local => 'ローカル';

  @override
  String get localUpscale_manage => 'モデル管理';

  @override
  String get localUpscale_description => 'ローカルで画像を拡大します。Anlas は消費しません。';

  @override
  String get localUpscale_bundled => '内蔵';

  @override
  String get localUpscale_download => 'ダウンロード';

  @override
  String get localUpscale_importHelp =>
      '4倍 Real-ESRGAN NCNN モデルの .param と .bin の組をインポートします（data/output ノード）。PyTorch と safetensors は非対応です。';

  @override
  String get localUpscale_preparing => '画像を準備中…';

  @override
  String get localUpscale_inference => '超解像処理中…';

  @override
  String get localUpscale_resizing => '画像を仕上げ中…';

  @override
  String get localUpscale_complete => '超解像完了';

  @override
  String get localUpscale_cancelling => 'キャンセル中…';

  @override
  String get localUpscale_unsupportedPlatform => 'ローカル超解像は現在 Windows に対応しています。';

  @override
  String get localUpscale_engineMissing =>
      'ローカルエンジンを利用できません。Studio の完全なパッケージを再インストールしてください。';

  @override
  String get localUpscale_integrity =>
      'ファイル検証に失敗しました。モデルまたは Studio を再インストールしてください。';

  @override
  String get localUpscale_modelMissing =>
      'モデルを利用できません。インストール済みのモデルを選ぶか、フォルダーのパス長を確認してください。';

  @override
  String get localUpscale_invalidModel =>
      '非対応モデルです。4倍 Real-ESRGAN NCNN の組をインポートしてください。';

  @override
  String get localUpscale_invalidImage => '画像を読み込めません。PNG、JPEG、WebP をお試しください。';

  @override
  String get localUpscale_sizeLimit => '画像が大きすぎます。モデルの出力は6400万画素以下にしてください。';

  @override
  String get localUpscale_noVulkan =>
      '利用可能な Vulkan GPU がありません。グラフィックスドライバーを更新してください。';

  @override
  String get localUpscale_processFailed =>
      '超解像に失敗しました。モデルとドライバーを確認してください。元画像は保持されています。';

  @override
  String get localUpscale_timeout => '処理がタイムアウトしました。小さい画像をお試しください。';

  @override
  String get localUpscale_busy => '別の超解像またはモデル操作が実行中です。';

  @override
  String get localUpscale_cancelled => '超解像をキャンセルしました';

  @override
  String get localUpscale_anime => 'アニメ · 高画質';

  @override
  String get localUpscale_animeFast => 'アニメ · 高速';

  @override
  String get localUpscale_general => '汎用 · 写真';

  @override
  String get localUpscale_downloadProgress => 'モデルをダウンロード中…';

  @override
  String get localUpscale_importModel => 'モデルをインポート';

  @override
  String get localUpscale_modelOperationFailed =>
      'モデル操作に失敗しました。接続、ファイルの権限、空き容量を確認して再試行してください。';

  @override
  String get settings_localUpscale => 'ローカル拡大';

  @override
  String get settings_localUpscaleDescription => 'ローカル拡大モデルと実行コンポーネントを管理します。';

  @override
  String get localUpscale_noCuda => 'CUDA 対応 NVIDIA GPU と互換ドライバーが必要です。';

  @override
  String get localUpscale_noRtx =>
      'RTX Video を利用できません。NVIDIA RTX GPU とドライバーを確認してください。';

  @override
  String get localUpscale_encoding => '画像をエンコード中…';

  @override
  String get localUpscale_decoding => '画像をデコード中…';

  @override
  String get localUpscale_optionalComponents => '追加コンポーネント';

  @override
  String get localUpscale_noAutomaticDownload =>
      '必要に応じてコンポーネントをダウンロードします。既存のローカルモデルはそのまま使えます。';

  @override
  String get localUpscale_notInstalledShort => '未インストール';

  @override
  String get localUpscale_seedvr2ThreeSummary =>
      '画質とリソース使用量のバランスが良く、日常の拡大に適しています。';

  @override
  String get localUpscale_seedvr2SevenSummary =>
      'より高い画質が期待できますが、VRAM と処理時間が多く必要です。';

  @override
  String get localUpscale_seedvr2SharpSummary =>
      'より鮮明なディテールを重視し、質感を強調したい画像に適しています。';

  @override
  String get localUpscale_seedvr2SharpHelp =>
      '7B Sharp FP8 は質感と輪郭の鮮明さを重視します。重みは約 8.2 GB。ほかの SeedVR2 モデルと VAE および Python/CUDA 環境を共有します。';

  @override
  String get localUpscale_seedvr2Int8Help =>
      'INT8 ConvRot（実験的）：NVIDIA Turing 以降の GPU が必要です。FP8 と実行環境を共有します。速度と画質は画像や GPU によって異なります。';

  @override
  String get localUpscale_noInt8 =>
      'この GPU または CUDA 環境ではネイティブ INT8 を利用できません。FP8 を選択してください。';

  @override
  String get localUpscale_seedvr2SharedHelp =>
      'モデルは VAE（約 0.5 GB）と Python/CUDA 環境を共有します。NVIDIA GPU が必要です。';

  @override
  String get localUpscale_seedvr2Help =>
      '3B FP8 は画質とリソースのバランスを重視。重みは約 3.4 GB、VAE は約 0.5 GB。VAE と Python/CUDA 環境を 7B と共有します。NVIDIA GPU が必要です。';

  @override
  String get localUpscale_seedvr2SevenHelp =>
      '7B FP8 はより高い画質が期待できますが、VRAM と処理時間が増えます。重みは約 8.2 GB。VAE と Python/CUDA 環境を 3B と共有します。';

  @override
  String get localUpscale_outOfMemory =>
      'VRAM が不足しています。3B、低い倍率、または詳細設定の低 VRAM モードと VAE タイル処理をお試しください。モデルは自動で切り替えていません。';

  @override
  String get localUpscale_modelWeights => '重み';

  @override
  String get localUpscale_advancedSettings => '詳細設定';

  @override
  String get localUpscale_seedvr2Color => '色補正';

  @override
  String get localUpscale_colorNone => '補正なし';

  @override
  String get localUpscale_seedvr2Seed => '乱数シード';

  @override
  String get localUpscale_seedvr2Memory => 'VRAM 使用方針';

  @override
  String get localUpscale_memoryRecommended => '推奨';

  @override
  String get localUpscale_memoryLow => '低 VRAM';

  @override
  String get localUpscale_blocksToSwap => 'CPU に退避する層数';

  @override
  String get localUpscale_memoryHelp =>
      '退避する層を増やすと VRAM を節約できますが、RAM 使用量と処理時間が増えます。低 VRAM モードでも、すべての出力サイズで動作するとは限りません。';

  @override
  String get localUpscale_vaeTiled => 'VAE タイル処理';

  @override
  String get localUpscale_vaeTileSize => 'タイルサイズ';

  @override
  String get localUpscale_vaeOverlap => 'タイルの重なり';

  @override
  String get localUpscale_vaeHelp =>
      '小さいタイルは VRAM を節約し、重なりは継ぎ目を抑えます。VAE のエンコード／デコードの分割であり、超解像処理全体の分割ではありません。';

  @override
  String get localUpscale_experimental => '実験的な変化';

  @override
  String get localUpscale_inputNoise => '入力ノイズ';

  @override
  String get localUpscale_latentNoise => '潜在ノイズ';

  @override
  String get localUpscale_noiseHelp =>
      '両方を 0 にすると現在の動作を維持します。ノイズを増やしても画質や細部の向上は保証されず、線や顔が変化する場合があります。';

  @override
  String get localUpscale_restoreDefaults => '既定値に戻す';

  @override
  String get localUpscale_rtxHelp =>
      'NVIDIA RTX Video による高速拡大。約 64 MB の独立コンポーネントと対応 RTX GPU が必要です。';

  @override
  String get localUpscale_installed => 'インストール済み';

  @override
  String get localUpscale_notInstalled => '未インストール。「モデル管理」からインストールしてください';

  @override
  String get localUpscale_license => 'ライセンス';

  @override
  String get localUpscale_installComponent => 'インストール';

  @override
  String get localUpscale_installingRuntime => 'Python/CUDA 環境をインストール中…';

  @override
  String get localUpscale_installingPython => '独立した Python を準備中…';

  @override
  String localUpscale_installFailed(String stage) {
    return 'インストールの失敗段階：$stage';
  }

  @override
  String get wiki_translationQueued => '翻訳待ち';

  @override
  String get wiki_translationFailedRetry => '翻訳に失敗しました。クリックして再試行';

  @override
  String get localUpscale_checkingComponent => 'コンポーネントと GPU を確認中…';

  @override
  String get localUpscale_installingComponent => 'コンポーネントをダウンロード中…';

  @override
  String get upscale_settings => '拡大設定';

  @override
  String upscale_cloudCost(int cost) {
    return '目安 $cost Anlas · 2×';
  }

  @override
  String get enhance_localAfterGeneration => '生成した画像を毎回ローカルで自動拡大します。';

  @override
  String get enhance_localAction => '生成してローカルで拡大';

  @override
  String get localUpscale_stop => 'アップスケールを停止';

  @override
  String get localUpscale_scrollDown => '下へスクロール';

  @override
  String get wiki_exampleImages => '作例画像';

  @override
  String get wiki_exampleImagesUnavailable => '作例画像を読み込めませんでした';

  @override
  String get generation_perRequestLabel => '枚数';

  @override
  String get generation_perRequestTooltip => '1回のリクエストで生成する枚数（1〜4）';

  @override
  String get generation_repeatLabel => '繰り返し';

  @override
  String get generation_referenceUpload => 'アップロード';

  @override
  String get generation_seedPinnedLabel => 'シード・固定';

  @override
  String get generation_paramsDrawerTooltip => '詳細パラメータ';

  @override
  String get library_sizeSmall => '小';

  @override
  String get library_sizeMedium => '中';

  @override
  String get library_sizeLarge => '大';

  @override
  String get library_currentModel => '使用モデル';

  @override
  String get library_available => '利用可能';

  @override
  String get library_unavailable => '利用不可';

  @override
  String get library_inGeneration => '生成に使用中';

  @override
  String library_selectedCount(int count) {
    return '$count 件選択';
  }

  @override
  String get library_invertSelection => '選択を反転';

  @override
  String get library_more => 'その他';

  @override
  String get viewer_fit => 'フィット';

  @override
  String get viewer_showInfo => '情報パネルを表示 (I)';

  @override
  String get viewer_hideInfo => '情報パネルを隠す (I)';

  @override
  String get viewer_originalSize => '原寸 (1)';

  @override
  String get viewer_fullscreen => '全画面 (F11)';

  @override
  String get shortcut_action_toggle_info_panel => '情報パネルの切り替え';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_openBlockLibrary => 'ブロックライブラリを開く';

  @override
  String get styleExplore_drawCountLabel => '今回の抽選';

  @override
  String get styleExplore_drawCountSuffix => '枚 · 1枚ずつ生成';

  @override
  String get styleExplore_appliedToEditor => '編集欄に適用しました';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '候補を $count 枚生成';
  }

  @override
  String get stats_title => '統計';

  @override
  String get stats_subtitle => 'ローカルギャラリー · ファイル日時順';

  @override
  String stats_rangeDays(Object count) {
    return '$count 日';
  }

  @override
  String get stats_rangeThisYear => '今年';

  @override
  String get stats_rangeAll => 'すべて';

  @override
  String get stats_naiOnly => 'NAI 画像のみ';

  @override
  String stats_updatedAt(Object time) {
    return '$time に更新';
  }

  @override
  String get stats_updating => '更新中';

  @override
  String stats_counting(Object count) {
    return '$count 枚を集計中…';
  }

  @override
  String get stats_updateFailed => '更新に失敗しました';

  @override
  String get stats_refresh => '更新';

  @override
  String stats_lastDays(Object count) {
    return '直近 $count 日';
  }

  @override
  String stats_lastDaysShort(Object count) {
    return '$count 日';
  }

  @override
  String get stats_unitDays => '日';

  @override
  String stats_imagesCount(Object count) {
    return '$count 枚';
  }

  @override
  String get stats_less => '少';

  @override
  String get stats_more => '多';

  @override
  String get stats_kpiImages => '画像';

  @override
  String get stats_kpiNewImages => '新しい画像';

  @override
  String stats_kpiActiveDays(Object days, Object avg) {
    return '活動 $days 日 · 1 日平均 $avg';
  }

  @override
  String stats_kpiVsPrevious(Object count) {
    return '前の $count 日比';
  }

  @override
  String get stats_kpiVsLastYear => '前年同期比';

  @override
  String stats_kpiPreviousValue(Object value) {
    return '（$value）';
  }

  @override
  String get stats_kpiFavorites => 'お気に入り';

  @override
  String stats_kpiFavoriteRate(Object rate) {
    return 'お気に入り率 $rate';
  }

  @override
  String get stats_kpiAnlas90 => 'Anlas · 直近 90 日';

  @override
  String get stats_kpiAnlasSpent => 'Anlas 消費';

  @override
  String stats_kpiAnlasRecent(Object week, Object today) {
    return '7 日 $week · 今日 $today';
  }

  @override
  String stats_kpiAnlasDaily(Object avg, Object today) {
    return '1 日平均 $avg · 今日 $today';
  }

  @override
  String get stats_kpiStreak => '連続制作';

  @override
  String stats_kpiLongest(Object days, Object unit) {
    return '最長 $days $unit';
  }

  @override
  String stats_kpiLongestRange(Object days, Object unit, Object range) {
    return '最長 $days $unit（$range）';
  }

  @override
  String get stats_kpiStorage => '容量';

  @override
  String stats_kpiStorageDetail(Object avg, Object pct) {
    return '平均 $avg · メタデータあり $pct';
  }

  @override
  String get stats_calendarTitle => '制作カレンダー';

  @override
  String get stats_calendarHint => '1 マス 1 日、濃いほど多い';

  @override
  String get stats_calendarPastYear => '直近 1 年';

  @override
  String stats_calendarYear(Object year) {
    return '$year 年';
  }

  @override
  String get stats_calendarImagesPastYear => '直近 1 年の画像';

  @override
  String stats_calendarImagesInYear(Object year) {
    return '$year 年の画像';
  }

  @override
  String get stats_calendarActiveDays => '制作した日数';

  @override
  String get stats_calendarBestDay => '最も多い日';

  @override
  String get stats_calendarLongestStreak => '最長連続';

  @override
  String get stats_calendarTipOpen => 'クリックでこの日をローカルギャラリーで開く';

  @override
  String get stats_productionTitle => '生成量とモデル';

  @override
  String stats_productionHintAll(Object unit) {
    return '$unitごと、色はモデル';
  }

  @override
  String stats_productionHintRange(Object range, Object unit) {
    return '$range、$unitごと、色はモデル';
  }

  @override
  String get stats_unitDay => '日';

  @override
  String get stats_unitWeek => '週';

  @override
  String get stats_unitMonth => '月';

  @override
  String get stats_granularityDay => '日';

  @override
  String get stats_granularityWeek => '週';

  @override
  String get stats_granularityMonth => '月';

  @override
  String stats_monthWithYear(Object year, Object month) {
    return '$year.$month';
  }

  @override
  String get stats_productionModelsHint => 'モデル · クリックでそのモデルだけ表示';

  @override
  String stats_productionOtherModels(Object count) {
    return 'その他 $count モデル';
  }

  @override
  String stats_productionNoMetadata(Object count) {
    return 'ほかにメタデータなし $count 枚（薄いグレー）';
  }

  @override
  String get stats_familyOther => 'その他のモデル';

  @override
  String get stats_familyNoMetadata => 'メタデータなし';

  @override
  String stats_productionTipTotal(Object period, Object count) {
    return '$period · $count 枚';
  }

  @override
  String get stats_productionTipOpenDay => 'クリックでこの日をローカルギャラリーで開く';

  @override
  String get stats_productionTipOpenWeek => 'クリックでこの週をローカルギャラリーで開く';

  @override
  String get stats_productionTipOpenMonth => 'クリックでこの月をローカルギャラリーで開く';

  @override
  String get stats_punchTitle => 'いつ描くか';

  @override
  String get stats_punchHint => '曜日 × 時間';

  @override
  String get stats_punchPeak => '最も多い';

  @override
  String stats_punchPeakValue(Object weekday, Object from, Object to) {
    return '$weekday $from–$to 時';
  }

  @override
  String get stats_punchBusiest => '最も忙しい';

  @override
  String get stats_punchLateNight => '深夜';

  @override
  String get stats_punchNote => '円が大きいほど多い';

  @override
  String get stats_anlasTitle => 'Anlas 消費';

  @override
  String get stats_anlasToday => '今日';

  @override
  String get stats_anlasDailyAvg => '1 日平均';

  @override
  String stats_anlasActiveDays(Object count) {
    return '消費あり $count 日';
  }

  @override
  String get stats_anlasPeak => '最多';

  @override
  String get stats_anlasNote =>
      '残高が減ったときに記録（アップスケールや Vibe エンコードを含む）。直近 90 日のみ保持';

  @override
  String get stats_aspectTitle => '画面サイズ';

  @override
  String get stats_aspectHint => '実際のサイズ';

  @override
  String get stats_aspectOrientation => '向き';

  @override
  String get stats_orientationPortrait => '縦';

  @override
  String get stats_orientationLandscape => '横';

  @override
  String get stats_orientationSquare => '正方形';

  @override
  String stats_aspectShapeCount(Object orientation, Object count) {
    return '$orientation · $count';
  }

  @override
  String stats_aspectOthers(Object count, Object pct) {
    return 'その他 $count 種 · $pct';
  }

  @override
  String get stats_aspectClickHint => 'サイズや向きをクリックするとその画像だけ表示';

  @override
  String get stats_paramsTitle => 'パラメーターの傾向';

  @override
  String get stats_paramsHint => 'メタデータのある画像';

  @override
  String get stats_paramsCombo => 'よく使う設定';

  @override
  String get stats_paramsSampler => 'サンプラー';

  @override
  String get stats_paramsSteps => 'ステップ';

  @override
  String stats_paramsStepsValue(Object count) {
    return '$count ステップ';
  }

  @override
  String get stats_paramsNoise => 'ノイズスケジュール';

  @override
  String get stats_artistsTitle => 'よく使う絵師';

  @override
  String stats_artistsHint(Object count, Object pct) {
    return '絵師タグ入り $count 枚（$pct）';
  }

  @override
  String get stats_artistsComputing => '絵師を集計中…';

  @override
  String get stats_artistsNone => 'プロンプトに artist: がまだありません';

  @override
  String get stats_artistsNote => '登場した画像の枚数順。1 枚で何度書いても 1 回';

  @override
  String stats_artistsTipSearch(Object query) {
    return 'ローカルギャラリーで $query を検索';
  }

  @override
  String get stats_artistsTipCopy => '右クリック：絵師名をコピー';

  @override
  String stats_artistsCopied(Object name) {
    return '$name をコピーしました';
  }

  @override
  String get stats_storageTitle => 'ストレージ';

  @override
  String stats_storageFiles(Object count) {
    return '$count ファイル';
  }

  @override
  String get stats_storageMonthly => '直近 12 か月の月別追加';

  @override
  String stats_storageNoMetadata(Object count) {
    return 'メタデータなし $count 枚';
  }

  @override
  String get stats_storageViewInGallery => 'ローカルギャラリーで表示';

  @override
  String stats_storageLarge(Object count, Object size) {
    return '10 MB 超 $count 枚 · $size';
  }

  @override
  String get stats_storageView => '表示';

  @override
  String get stats_footer =>
      '統計を開くたびにギャラリーの変化を確認し、変わっていればバックグラウンドで再集計 · 数字をクリックするとそのフィルターでローカルギャラリーを開く';

  @override
  String get stats_emptyTitle => 'ローカルギャラリーにまだ画像がありません';

  @override
  String get stats_emptyBody =>
      '生成した画像は自動でローカルギャラリーに保存されます。既存の画像フォルダーを追加することもできます。その後、ここに制作のペース、モデル、パラメーターの傾向が表示されます。';

  @override
  String get stats_emptyGenerate => '生成へ';

  @override
  String get stats_emptyAddFolder => 'ギャラリーフォルダーを追加';

  @override
  String get stats_errorTitle => '統計を計算できませんでした';

  @override
  String get stats_errorRetry => '再試行';

  @override
  String get navShell_page_generation => '生成';

  @override
  String get navShell_page_styleExplore => '画風探索';

  @override
  String get navShell_page_localGallery => 'ローカルギャラリー';

  @override
  String get navShell_page_onlineGallery => 'オンラインギャラリー';

  @override
  String get navShell_page_promptBlocks => 'プロンプトブロック';

  @override
  String get navShell_page_vibeLibrary => 'Vibe ライブラリ';

  @override
  String get navShell_page_preciseRef => '精密参照ライブラリ';

  @override
  String get navShell_page_tagWiki => 'タグ百科';

  @override
  String get navShell_page_statistics => '統計';

  @override
  String get navShell_page_settings => '設定';

  @override
  String get navShell_group_create => '制作';

  @override
  String get navShell_group_gallery => 'ギャラリー';

  @override
  String get navShell_group_assets => '素材';

  @override
  String get navShell_group_tools => 'ツール';

  @override
  String get navShell_expand => 'ナビを展開';

  @override
  String get navShell_collapse => '折りたたむ';

  @override
  String get navShell_pin => '展開を固定';

  @override
  String get navShell_genRunning => '生成中';

  @override
  String navShell_genRunningCount(Object current, Object total) {
    return '生成中 · $current / $total 枚目';
  }

  @override
  String navShell_genPercent(Object percent) {
    return '$percent% · ライブプレビュー';
  }

  @override
  String get navShell_genBack => 'クリックで生成ページへ戻る';

  @override
  String navShell_genDone(Object count) {
    return '$count 枚完了、クリックで表示';
  }

  @override
  String get navShell_genFailed => '生成に失敗しました';

  @override
  String get navShell_tasksTitle => 'バックグラウンドタスク';

  @override
  String navShell_tasksRunning(Object count) {
    return '$count 件実行中';
  }

  @override
  String get navShell_tasksFooter => 'すべて終わると 10 秒後にこのアイコンは消えます';

  @override
  String get navShell_task_localUpscale => 'ローカル拡大';

  @override
  String get navShell_task_cloudUpscale => 'クラウド拡大';

  @override
  String get navShell_task_bulkDelete => 'ゴミ箱へ移動';

  @override
  String get navShell_task_bulkExport => '一括エクスポート';

  @override
  String get navShell_task_bulkMetadata => 'メタデータ一括編集';

  @override
  String get navShell_task_bulkAddToCollection => 'コレクションに追加';

  @override
  String get navShell_task_bulkRemoveFromCollection => 'コレクションから削除';

  @override
  String get navShell_task_bulkFavorite => '一括お気に入り';

  @override
  String navShell_taskImages(Object title, Object count) {
    return '$title $count 枚';
  }

  @override
  String get navShell_taskJustDone => '完了しました';

  @override
  String get navShell_taskView => '表示';

  @override
  String get navShell_taskCancel => 'キャンセル';

  @override
  String get navShell_taskCancelling => 'キャンセル中';

  @override
  String get navShell_taskUndo => '元に戻す';

  @override
  String get navShell_account => 'アカウント';

  @override
  String get navShell_accountTitle => 'ログインとアカウント';

  @override
  String get navShell_accountCurrent => '現在';

  @override
  String get navShell_accountToken => 'API トークンでログイン';

  @override
  String get navShell_accountCredentials => 'メールでログイン';

  @override
  String get navShell_accountNotSignedIn => '未ログイン';

  @override
  String get navShell_accountChoose => 'アカウントを選んで続行';

  @override
  String navShell_subExpires(Object date, Object days) {
    return 'サブスクは $date に終了 · 残り $days 日';
  }

  @override
  String get navShell_subExpired => 'サブスクの期限切れ';

  @override
  String get navShell_anlas => 'Anlas 残高';

  @override
  String get navShell_switchAccount => 'アカウント切替';

  @override
  String get navShell_addAccount => 'アカウントを追加';

  @override
  String get navShell_manageAccounts => 'アカウント管理';

  @override
  String get navShell_logout => 'ログアウト';

  @override
  String get navShell_customize => 'ナビをカスタマイズ';

  @override
  String get navShell_customizeMenu => 'ナビをカスタマイズ…';

  @override
  String get navShell_customizeNote =>
      'ナビバーを右クリックで開きます。非表示のページもショートカットで開けます。生成は非表示にできません';

  @override
  String get navShell_ctrlNumbers => 'Ctrl 長押しでページ番号を表示';

  @override
  String get navShell_reset => '初期設定に戻す';

  @override
  String get navShell_done => '完了';

  @override
  String get navShell_ctrlHint => '押し続けるとページ番号を表示、数字キーで移動、離すと消えます';

  @override
  String get online_title => 'オンラインギャラリー';

  @override
  String get online_collapseSidebar => 'サイドバーを閉じる';

  @override
  String get online_expandSidebar => 'サイドバーを開く';

  @override
  String get online_sectionBrowse => '閲覧';

  @override
  String get online_modeSearch => '検索';

  @override
  String get online_modeMonthly => '月間ランキング';

  @override
  String get online_modePopular => '人気';

  @override
  String get online_modeMyFavorites => 'お気に入り';

  @override
  String get online_modeFavorites => 'お気に入り';

  @override
  String get online_noRanking => 'ランキングなし';

  @override
  String get online_noFavorites => 'お気に入り非対応';

  @override
  String get online_readOnly => '閲覧のみ';

  @override
  String get online_signedOut => '未ログイン';

  @override
  String get online_recentTitle => '最近の検索';

  @override
  String get online_recentClear => 'クリア';

  @override
  String get online_collections => 'コレクション';

  @override
  String get online_newCollection => '新規コレクション';

  @override
  String get online_all => 'すべて';

  @override
  String get online_ungrouped => '未分類';

  @override
  String get online_favAuthors => '保存した作者';

  @override
  String get online_blacklist => 'ブロックリスト';

  @override
  String online_blacklistCount(Object count) {
    return '$count 件のタグを除外';
  }

  @override
  String get online_srcSubAiTag => 'NAI 作品コミュニティ · Prompt 付き';

  @override
  String online_srcSubSignedIn(Object name) {
    return 'ログイン中 · $name';
  }

  @override
  String get online_srcSubSafebooru => '全年齢 · ログイン不要';

  @override
  String get online_srcSubKeyOk => 'API Key 設定済み';

  @override
  String get online_srcSubKeyInvalid => 'API Key が無効';

  @override
  String get online_srcSubKeyMissing => 'API Key 未設定';

  @override
  String get online_switchSource => 'ソースを切り替え';

  @override
  String get online_capPromptSearch => '作品 + Prompt 検索';

  @override
  String get online_capTagSearch => 'タグ検索';

  @override
  String get online_capMonthly => '月間ランキング';

  @override
  String get online_capRankings => '日 / 週 / 月ランキング';

  @override
  String get online_capLocalFav => 'ローカルお気に入り';

  @override
  String get online_capSiteFav => 'サイトのお気に入り';

  @override
  String get online_capReadOnlyFav => 'お気に入り（閲覧のみ）';

  @override
  String get online_capMultiMedia => '複数枚作品';

  @override
  String get online_capParams => '生成パラメータ';

  @override
  String get online_capRatings => 'レーティング';

  @override
  String get online_capSfwOnly => '全年齢のみ';

  @override
  String get online_acctNone => 'ログイン不要';

  @override
  String get online_acctSignedIn => 'ログイン中';

  @override
  String get online_acctKeyOk => 'Key 設定済み';

  @override
  String get online_acctKeyInvalid => 'Key が無効';

  @override
  String get online_acctKeyMissing => 'Key 未設定';

  @override
  String get online_sourceMemory => 'ソースごとに検索語とスクロール位置を記憶します';

  @override
  String get online_searchWorkHint => '作品・作者・タイトル・タグ・モデル';

  @override
  String get online_searchPromptHint => 'Prompt に含む…（::artist: 構文可）';

  @override
  String get online_searchTagHint => 'タグを追加（スペース区切り、- で除外）';

  @override
  String get online_searchFavHint => 'お気に入りを検索：タイトル・作者・タグ';

  @override
  String get online_fuzzy => 'あいまい';

  @override
  String get online_clearSearch => '検索をクリア';

  @override
  String get online_sizeSmall => '小（タイトルなし）';

  @override
  String get online_sizeMedium => '中';

  @override
  String get online_sizeLarge => '大';

  @override
  String get online_multiSelect => '複数選択';

  @override
  String get online_doneMultiSelect => '選択を終了';

  @override
  String get online_refresh => '更新';

  @override
  String get online_inspector => 'インスペクター';

  @override
  String get online_naiOnly => 'NAI 画像のみ';

  @override
  String get online_model => 'モデル';

  @override
  String get online_modelAll => 'すべて';

  @override
  String get online_timeAll => '全期間';

  @override
  String online_timeYear(Object year) {
    return '$year 年';
  }

  @override
  String get online_timeOlder => 'それ以前';

  @override
  String online_loaded(Object count, Object pages) {
    return '$count 枚 · $pages ページ読込済み';
  }

  @override
  String online_rankLoaded(Object count) {
    return '1–$count 位 · $count 枚読込済み';
  }

  @override
  String get online_jumpToPage => 'ページへ移動';

  @override
  String get online_jumpGo => '移動';

  @override
  String get online_ratingLabel => 'レーティング';

  @override
  String get online_ratingG => '全年齢';

  @override
  String get online_ratingS => '軽度';

  @override
  String get online_ratingQ => '要注意';

  @override
  String get online_ratingE => '露骨';

  @override
  String get online_dateRange => '期間';

  @override
  String get online_clearDateRange => '期間指定なし';

  @override
  String get online_rankCurrent => 'リアルタイム月間';

  @override
  String get online_rankDay => '日間';

  @override
  String get online_rankWeek => '週間';

  @override
  String get online_rankMonth => '月間';

  @override
  String get online_today => '今日';

  @override
  String get online_previous => '前へ';

  @override
  String get online_next => '次へ';

  @override
  String get online_sort => '並び順';

  @override
  String get online_sortFavTime => '保存日時';

  @override
  String get online_favAll => 'すべてのお気に入り';

  @override
  String online_countImages(Object count) {
    return '$count 枚';
  }

  @override
  String online_authorSaved(Object count, Object date) {
    return '$count 枚保存 · $date に作者を保存';
  }

  @override
  String get online_authorAllWorks => 'AI TAG で全作品を見る';

  @override
  String get online_unfavAuthor => '作者の保存を解除';

  @override
  String get online_favAuthor => '作者を保存';

  @override
  String get online_dragHint => 'カードを左のコレクションへドラッグで移動。右クリック → 移動 / 解除';

  @override
  String get online_readOnlyNote => '閲覧のみ：Gelbooru のお気に入りはサイトで編集';

  @override
  String get online_returnPrev => '前の結果に戻る';

  @override
  String get online_send => '生成へ送る';

  @override
  String get online_sendTags => 'タグを生成へ送る';

  @override
  String get online_sendModes => '送り方を選ぶ';

  @override
  String get online_favorite => 'お気に入り';

  @override
  String get online_favorited => '保存済み';

  @override
  String get online_copyPrompt => 'Prompt をコピー';

  @override
  String get online_copyTags => 'タグをコピー';

  @override
  String get online_download => 'ダウンロード';

  @override
  String online_downloadAll(Object count) {
    return '全 $count 枚をダウンロード';
  }

  @override
  String get online_downloadCurrent => 'この 1 枚をダウンロード';

  @override
  String get online_more => 'その他';

  @override
  String get online_openInBrowser => 'サイトで開く';

  @override
  String get online_onlyAuthor => 'この作者だけ';

  @override
  String get online_moveTo => 'コレクションへ移動';

  @override
  String get online_unfavorite => 'お気に入り解除';

  @override
  String get online_rename => '名前を変更';

  @override
  String get online_deleteCollection => 'コレクションを削除';

  @override
  String get online_inspWork => '作品';

  @override
  String get online_inspPost => '投稿';

  @override
  String online_youSaved(Object count) {
    return 'この作者を $count 枚保存';
  }

  @override
  String get online_params => '生成パラメータ';

  @override
  String get online_pModel => 'モデル';

  @override
  String get online_pSize => 'サイズ';

  @override
  String get online_pSeed => 'シード';

  @override
  String get online_pSampler => 'サンプラー';

  @override
  String get online_pStepsCfg => 'ステップ · CFG';

  @override
  String get online_prompt => 'プロンプト';

  @override
  String get online_negative => 'ネガティブ';

  @override
  String get online_tags => 'タグ';

  @override
  String get online_tagsHint => 'クリックで検索に追加';

  @override
  String get online_tagArtist => '絵師';

  @override
  String get online_tagCopyright => '作品';

  @override
  String get online_tagCharacter => 'キャラクター';

  @override
  String get online_tagGeneral => '一般';

  @override
  String get online_tagMeta => 'メタ';

  @override
  String get online_copy => 'コピー';

  @override
  String get online_noSelection => 'カードをクリックすると Prompt とパラメータをここに表示';

  @override
  String online_detailError(Object error) {
    return '詳細を読み込めませんでした：$error';
  }

  @override
  String get online_retry => '再試行';

  @override
  String get online_noPrompt => 'この画像には Prompt がありません';

  @override
  String online_selCount(Object count) {
    return '$count 枚選択中';
  }

  @override
  String get online_selAll => 'すべて選択';

  @override
  String get online_selInvert => '選択を反転';

  @override
  String get online_favoriteTo => 'お気に入りに追加…';

  @override
  String get online_favoriteToTitle => '追加先';

  @override
  String get online_favoriteToSite => 'サイトのお気に入りへ';

  @override
  String online_downloadN(Object count) {
    return 'ダウンロード · $count 枚';
  }

  @override
  String get online_newCollectionAndFav => '新規コレクションに追加';

  @override
  String get online_collectionNameHint => 'コレクション名（Enter で確定）';

  @override
  String get online_exitMulti => '選択を終了';

  @override
  String get online_sendRemember => 'この選択を記憶';

  @override
  String get online_sendReplace => 'プロンプトを置換、キャラ枠をクリア';

  @override
  String online_sendReplaceDesc(Object count) {
    return 'ポジ + ネガをこの画像のものに置換し、生成ページのキャラ枠 $count 個をクリア。以前のカードのボタンと同じ';
  }

  @override
  String get online_sendReplaceDescNone =>
      'ポジ + ネガをこの画像のものに置換し、キャラ枠をクリア。以前のカードのボタンと同じ';

  @override
  String get online_sendPromptOnly => 'プロンプトだけ置換、キャラ枠は残す';

  @override
  String get online_sendPromptOnlyDesc => '絵師タグと情景描写だけ借りたいときに';

  @override
  String get online_sendParams => 'プロンプト + 生成パラメータ';

  @override
  String get online_sendParamsDesc =>
      'サイズ・シード・サンプラー・ステップ・CFG と画像内のキャラ枠も適用。ローカルギャラリーの「パラメータを再利用」と同じ';

  @override
  String get online_sendParamsUnavailable => 'この画像には生成パラメータがないため、プロンプトのみ送れます';

  @override
  String online_sendNote(Object count) {
    return '生成ページの現在のポジ（$count 文字）は置き換わります';
  }

  @override
  String get online_sendNoteEmpty => '生成ページのポジは空です';

  @override
  String get online_cancel => 'キャンセル';

  @override
  String get online_sendGo => '送って生成ページへ';

  @override
  String get online_blacklistDesc => '該当する作品は表示しません';

  @override
  String get online_blacklistAddHint => 'タグを追加（Enter で確定）';

  @override
  String online_blacklistSync(Object count) {
    return 'Danbooru のブロックリストを同期 · $count 件';
  }

  @override
  String get online_blacklistScope => '4 つのソースすべてに適用。AI TAG は作品タグで照合';

  @override
  String get online_blacklistEmpty => '除外タグはまだありません';

  @override
  String get online_removeTag => '削除';

  @override
  String online_appendError(Object page, Object reason) {
    return '$page ページ目を読み込めませんでした：$reason';
  }

  @override
  String get online_retryPage => 'このページを再試行';

  @override
  String online_end(Object count) {
    return 'これで全部です · 計 $count 枚';
  }

  @override
  String online_endBlocked(Object count, Object blocked) {
    return 'これで全部です · 計 $count 枚 · $blocked 枚を除外';
  }

  @override
  String online_emptyTitle(Object query) {
    return '「$query」の作品は見つかりませんでした';
  }

  @override
  String get online_emptyTitleNoQuery => '作品が見つかりませんでした';

  @override
  String get online_emptyHint => '条件をゆるめてみてください';

  @override
  String get online_sugNaiOff => '「NAI 画像のみ」を外す';

  @override
  String get online_sugClearPrompt => 'Prompt 条件をクリア';

  @override
  String get online_sugAllTime => '全期間にする';

  @override
  String get online_sugAllModels => 'モデルをすべてに';

  @override
  String get online_sugAllRatings => 'すべてのレーティング';

  @override
  String get online_sugNoDate => '期間指定を外す';

  @override
  String get online_favEmpty => 'まだお気に入りはありません';

  @override
  String get online_favEmptyHint => 'カードの ♡ で保存できます';

  @override
  String online_loadError(Object error) {
    return '読み込めませんでした：$error';
  }

  @override
  String get online_loginDbTitle => 'お気に入りを見るには Danbooru にログイン';

  @override
  String get online_loginDbDesc =>
      'ユーザー名 + API Key でログインするとサイトと同期します。\nカードの ♡ もサイトに直接保存します';

  @override
  String get online_loginDb => 'Danbooru にログイン';

  @override
  String get online_loginGbTitle => 'お気に入りを見るには Gelbooru の API Key を設定';

  @override
  String get online_loginGbDesc => 'Gelbooru のお気に入りはここでは閲覧のみです';

  @override
  String get online_loginGb => 'API Key を設定';

  @override
  String get online_apiKeyHelp => 'API Key の取得方法';

  @override
  String get online_loginOther =>
      'ログインしたくない場合：AI TAG のお気に入りは端末内に保存されアカウント不要。Gelbooru は閲覧のみ';

  @override
  String online_viewerPosition(
    Object image,
    Object images,
    Object work,
    Object works,
  ) {
    return '画像 $image / $images · 作品 $work / $works';
  }

  @override
  String online_viewerWorkPosition(Object work, Object works) {
    return '作品 $work / $works';
  }

  @override
  String get online_close => '閉じる';

  @override
  String get online_keyImage => '画像を切り替え';

  @override
  String get online_keyWork => '前 / 次の作品';

  @override
  String get online_keyInfo => '情報欄の表示切替';

  @override
  String get refs_vibeTitle => 'Vibe ライブラリ';

  @override
  String get refs_preciseTitle => '精密参照ライブラリ';

  @override
  String get refs_collapseSidebar => 'サイドバーを閉じる';

  @override
  String get refs_expandSidebar => 'サイドバーを開く';

  @override
  String get refs_viewAll => 'すべて';

  @override
  String get refs_viewFavorites => 'お気に入り';

  @override
  String get refs_viewRecent => '最近使用';

  @override
  String get refs_viewInGeneration => '生成ページで使用中';

  @override
  String get refs_categories => 'カテゴリ';

  @override
  String get refs_newCategory => '新規カテゴリ';

  @override
  String get refs_newSubcategory => 'サブカテゴリを作成';

  @override
  String get refs_deleteCategory => 'カテゴリを削除';

  @override
  String get refs_categoryNameHint => 'カテゴリ名';

  @override
  String get refs_noCategories => 'カテゴリはまだありません。インポート時に作成できます';

  @override
  String get refs_uncategorized => '未分類';

  @override
  String get refs_sources => 'ソース';

  @override
  String get refs_srcPng => 'PNG（Vibe 埋め込み）';

  @override
  String get refs_srcVibeFile => 'Vibe ファイル';

  @override
  String get refs_srcBundle => 'バンドル';

  @override
  String get refs_srcRaw => 'エンコード待ちの画像';

  @override
  String get refs_srcImage => '画像';

  @override
  String get refs_open => '開く';

  @override
  String get refs_types => '参照タイプ';

  @override
  String refs_importTypeNoteAll(Object type) {
    return 'インポートした画像は既定で $type として保存されます。左でタイプを選んでからインポートするとそのタイプで保存されます。';
  }

  @override
  String refs_importTypeNoteSelected(Object type) {
    return 'インポートした画像は $type として保存されます（左で選んだタイプ）。';
  }

  @override
  String get refs_preciseOnlyV45 => 'V4.5 のみ';

  @override
  String refs_preciseCostNote(Object cost) {
    return '1 枚 $cost Anlas。Vibe とは同時に使えません';
  }

  @override
  String get refs_searchVibe => '名前・タグを検索';

  @override
  String get refs_searchPrecise => '名前を検索';

  @override
  String get refs_sortLastUsed => '最近使用';

  @override
  String get refs_sortCreated => '追加日';

  @override
  String get refs_sortUsed => '使用回数';

  @override
  String get refs_sortName => '名前';

  @override
  String get refs_sortAsc => '昇順';

  @override
  String get refs_sortDesc => '降順';

  @override
  String get refs_sizeSmall => '小';

  @override
  String get refs_sizeMedium => '中';

  @override
  String get refs_sizeLarge => '大';

  @override
  String get refs_currentModel => '現在のモデル';

  @override
  String get refs_usable => '使用可';

  @override
  String get refs_unusable => '使用不可';

  @override
  String get refs_multi => '複数選択';

  @override
  String get refs_multiDone => '選択を終了';

  @override
  String get refs_import => 'インポート';

  @override
  String get refs_importFiles => 'ファイルを選択…';

  @override
  String get refs_importImages => '画像を選択…';

  @override
  String get refs_importClipboard => 'クリップボードから貼り付け';

  @override
  String get refs_more => 'その他';

  @override
  String get refs_exportAll => 'すべてエクスポート…';

  @override
  String get refs_openLibraryFolder => 'ライブラリフォルダを開く';

  @override
  String get refs_rescan => 'フォルダを再スキャン';

  @override
  String get refs_reload => '再読み込み';

  @override
  String get refs_hideInspector => 'インスペクターを閉じる';

  @override
  String get refs_showInspector => 'インスペクターを開く';

  @override
  String refs_bannerVibeLead(Object model) {
    return '$model は Vibe 転送に対応していません。';
  }

  @override
  String get refs_bannerVibeBody =>
      'Vibe の整理・エクスポートはできます。生成に使うには V4.5 か V4 に切り替えてください';

  @override
  String refs_bannerPreciseLead(Object model) {
    return '$model は精密参照に対応していません。';
  }

  @override
  String get refs_bannerPreciseBody => '参照画像の整理はできます。生成に使うには V4.5 に切り替えてください';

  @override
  String refs_switchTo(Object model) {
    return '$model に切り替え';
  }

  @override
  String get refs_quickAll => 'すべて';

  @override
  String get refs_quickFavorites => 'お気に入り';

  @override
  String get refs_quickHasRaw => '元画像あり';

  @override
  String get refs_quickNeedsEncoding => '要エンコード';

  @override
  String get refs_quickBundles => 'バンドル';

  @override
  String get refs_quickUnused => '未使用';

  @override
  String refs_countVibe(Object count, Object inGen) {
    return '$count 件 · 生成ページで $inGen 件';
  }

  @override
  String refs_countPrecise(Object count, Object inGen) {
    return '$count 枚 · 生成ページで $inGen 枚';
  }

  @override
  String get refs_noResults => '条件に合う項目はありません';

  @override
  String refs_noResultsFor(Object query) {
    return '「$query」は見つかりませんでした';
  }

  @override
  String get refs_clearFilters => 'フィルターをクリア';

  @override
  String get refs_addShort => '生成に追加';

  @override
  String get refs_sendPrecise => '精密参照に送る';

  @override
  String get refs_openBundle => 'バンドルを開く';

  @override
  String get refs_detail => '詳細';

  @override
  String get refs_addToGeneration => '生成ページに追加';

  @override
  String get refs_replaceVibes => '生成ページの Vibe を置き換え';

  @override
  String get refs_replacePrecise => '現在の精密参照を置き換え';

  @override
  String get refs_sendImg2Img => 'img2img に送る';

  @override
  String get refs_saveAsVibe => 'Vibe ライブラリに保存';

  @override
  String get refs_favorite => 'お気に入り';

  @override
  String get refs_unfavorite => 'お気に入り解除';

  @override
  String get refs_replacePreview => 'プレビューを差し替え…';

  @override
  String get refs_exportEllipsis => 'エクスポート…';

  @override
  String get refs_showInFolder => 'フォルダで表示';

  @override
  String get refs_copyImage => '画像をコピー';

  @override
  String get refs_delete => '削除';

  @override
  String refs_selected(Object count) {
    return '$count 件選択';
  }

  @override
  String get refs_moveTo => '移動';

  @override
  String get refs_export => 'エクスポート';

  @override
  String get refs_emptyVibeTitle => '画像や Vibe ファイルをここにドロップ';

  @override
  String get refs_emptyPreciseTitle => '参照画像をここにドロップ';

  @override
  String get refs_emptyVibeDesc =>
      'PNG（Vibe 埋め込み）、.naiv4vibe、.naiv4vibebundle、通常の画像に対応。\n通常の画像は元画像のまま保存し、初めて生成に使うときにエンコードします';

  @override
  String get refs_emptyPreciseDesc =>
      'キャラ設定画や画風サンプルなど、まとめてドロップできます。\nタイプ・強度・忠実度を保存し、送るときにそのまま使います';

  @override
  String get refs_pickFiles => 'ファイルを選択';

  @override
  String get refs_pasteClipboard => '貼り付け';

  @override
  String get refs_emptyFromResultVibe => '生成結果を右クリック → Vibe ライブラリに保存';

  @override
  String get refs_emptyFromResultPrecise => '生成結果を右クリック → 精密参照ライブラリに保存';

  @override
  String get refs_emptyFromGallery => 'ローカルギャラリーからも可';

  @override
  String get refs_emptyHelpTitle => 'Vibe と精密参照の違い';

  @override
  String refs_emptyHelpBody(Object cost) {
    return 'Vibe：全体の雰囲気や画風を借り、何枚も重ねられます（V4 / V4.5、V5 は非対応）。精密参照：1 枚の画像の人物や画風により忠実に描きます。1 枚 $cost Anlas（V4.5 のみ）。両者は同時に使えません。';
  }

  @override
  String refs_dropTitle(Object count) {
    return '離すと $count 件をインポート';
  }

  @override
  String get refs_dropVibeDesc => 'まずインポート画面で確認します。すぐに Anlas は消費しません';

  @override
  String get refs_dropPreciseDesc => '左で選んだタイプで保存します';

  @override
  String refs_dropVibePngs(Object count) {
    return 'Vibe 入り PNG $count 件';
  }

  @override
  String refs_dropVibeFiles(Object count) {
    return 'Vibe ファイル $count 件';
  }

  @override
  String refs_dropBundles(Object count) {
    return 'バンドル $count 件';
  }

  @override
  String refs_dropImages(Object count) {
    return '通常の画像 $count 枚';
  }

  @override
  String get refs_inGeneration => '使用中';

  @override
  String get refs_tag => 'タグ';

  @override
  String get refs_strengthShort => '強度';

  @override
  String get refs_infoShort => '情報';

  @override
  String get refs_fidelityShort => '忠実';

  @override
  String refs_encModelOff(Object model) {
    return '$model では使用不可';
  }

  @override
  String refs_encModelOffDesc(Object model) {
    return '$model は Vibe 転送非対応です。V4.5 / V4 に切り替えると使えます';
  }

  @override
  String refs_encReady(Object model) {
    return 'エンコード済み · $model';
  }

  @override
  String refs_encReadyShort(Object model) {
    return '$model エンコード済み';
  }

  @override
  String get refs_encReadyDesc => '現在のモデルでそのまま使えます。エンコード料金はかかりません';

  @override
  String get refs_encOnUse => '使用時にエンコード';

  @override
  String refs_encOnUseDesc(Object cost) {
    return 'まだエンコードしていません。初めて生成に使うときにエンコードします（$cost Anlas）';
  }

  @override
  String get refs_encRe => '再エンコードが必要';

  @override
  String refs_encReDesc(Object from, Object model, Object cost) {
    return '$from 用のエンコードです（現在は $model）。使用時に元画像から再エンコードします（$cost Anlas）';
  }

  @override
  String refs_encUnusable(Object model) {
    return '$model では使えません';
  }

  @override
  String refs_encUnusableDesc(Object from, Object model) {
    return '$from 用のエンコードのみで元画像がないため、$model 用に再エンコードできません';
  }

  @override
  String get refs_trayVibe => '生成ページの Vibe';

  @override
  String get refs_trayPrecise => '生成ページの精密参照';

  @override
  String refs_trayVibeCost(Object free, Object extra) {
    return '$free 件を超えると 1 件ごとに +$extra Anlas';
  }

  @override
  String refs_trayPreciseCost(Object cost, Object total) {
    return '1 枚 $cost Anlas · 今回 +$total';
  }

  @override
  String get refs_trayHint =>
      'カードをここにドラッグで追加、Shift でまとめて置き換え。\nページは移動しないので続けて選べます';

  @override
  String get refs_trayDropHere => 'カードをここにドロップして追加';

  @override
  String get refs_clear => 'クリア';

  @override
  String get refs_goGeneration => '生成ページへ';

  @override
  String refs_conflict(Object count) {
    return '生成ページに **Vibe が $count 件** あります。精密参照があると Vibe は送信されません（公式非対応）';
  }

  @override
  String refs_conflictPaused(Object count) {
    return '生成ページの **Vibe $count 件** は一時停止中。精密参照のみ送信します';
  }

  @override
  String get refs_pauseVibes => 'Vibe を一時停止';

  @override
  String get refs_resumeVibes => 'Vibe を再開';

  @override
  String get refs_inspector => 'インスペクター';

  @override
  String refs_selectedN(Object count) {
    return '$count 件選択中';
  }

  @override
  String get refs_noSelectionVibe => 'カードを選ぶとパラメータとエンコード状態を表示します';

  @override
  String get refs_noSelectionPrecise => '参照画像を選ぶとタイプとパラメータを表示します';

  @override
  String get refs_rename => '名前を変更';

  @override
  String get refs_replace => '置き換え';

  @override
  String get refs_replaceVibesTip => '生成ページの Vibe をすべて置き換え';

  @override
  String get refs_strength => '強度';

  @override
  String get refs_strengthDesc => '高いほどこの画像の雰囲気に近づきます';

  @override
  String get refs_infoExtracted => '情報抽出';

  @override
  String refs_infoDesc(Object cost) {
    return '高いほど細部を多く取り込みます。変更すると元画像から再エンコードします（$cost Anlas）';
  }

  @override
  String get refs_infoLocked => 'エンコードデータのみで元画像がないため、情報抽出は変更できません';

  @override
  String get refs_changedNote => '変更は今回の送信のみに使われます';

  @override
  String get refs_saveDefault => '既定値として保存';

  @override
  String get refs_revert => '元に戻す';

  @override
  String get refs_encOnUseBody => 'まだエンコードしていません。初めて生成に使うときにエンコードします。';

  @override
  String refs_encReBody(String from, String model) {
    return '$from 用のエンコードです（現在は $model）。使用時に元画像から再エンコードします。';
  }

  @override
  String refs_encodeAction(String model) {
    return '$model 用にエンコード';
  }

  @override
  String refs_encodingPrice(int cost) {
    return '$cost Anlas';
  }

  @override
  String refs_encodeNow(Object model, Object cost) {
    return '$model 用にエンコード · $cost Anlas';
  }

  @override
  String refs_bundleNote(Object count) {
    return 'このバンドルの $count 件の Vibe はそれぞれ強度と情報抽出を持ちます。バンドルを開くと個別に調整できます。';
  }

  @override
  String refs_bundleOf(Object count) {
    return 'バンドル · $count 件';
  }

  @override
  String get refs_organize => '整理';

  @override
  String get refs_category => 'カテゴリ';

  @override
  String get refs_tags => 'タグ';

  @override
  String get refs_used => '使用';

  @override
  String get refs_neverUsed => '未使用';

  @override
  String refs_usedTimes(Object count, Object last) {
    return '$count 回 · 最後 $last';
  }

  @override
  String get refs_added => '追加';

  @override
  String get refs_file => 'ファイル';

  @override
  String get refs_original => '元画像';

  @override
  String refs_plusAnlas(Object cost) {
    return '+$cost Anlas';
  }

  @override
  String get refs_alsoSaveVibe => 'Vibe にも保存';

  @override
  String get refs_referenceWhat => '参照するもの';

  @override
  String get refs_typeCharacter => 'キャラ';

  @override
  String get refs_typeStyle => '画風';

  @override
  String get refs_typeBoth => 'キャラ+画風';

  @override
  String get refs_typeCharacterDesc => '人物の顔・髪型・服装を保ち、画風はプロンプトに従います';

  @override
  String get refs_typeStyleDesc => '画風・配色・タッチのみを借ります（人物は問いません）';

  @override
  String get refs_typeBothDesc => '人物と画風の両方を参照します';

  @override
  String get refs_preciseStrength => '参照強度';

  @override
  String get refs_preciseStrengthDesc => '高いほど参照画像に近づきます';

  @override
  String get refs_fidelity => '忠実度';

  @override
  String get refs_fidelityDesc => '高いほど細部に忠実、低いほど自由になります';

  @override
  String get refs_preciseDefaultsNote =>
      'ここで変えるのは既定値で、送信時にそのまま使われます。数値欄には 0–1 以外も入力できます';

  @override
  String get refs_showInFolderShort => 'フォルダへ';

  @override
  String get refs_pickHint => 'カードにチェックを入れるとここでまとめて設定できます';

  @override
  String get refs_multiAddTitle => 'まとめて生成ページに追加';

  @override
  String get refs_multiSendTitle => 'まとめて精密参照に送る';

  @override
  String refs_multiFree(Object free) {
    return '$free 件までは追加料金なし。';
  }

  @override
  String refs_multiExtra(Object free, Object extra, Object total) {
    return '$free 件を超えると 1 件ごとに +$extra Anlas：1 枚あたり $total Anlas 増えます。';
  }

  @override
  String refs_multiOverMax(Object max) {
    return '上限 $max 件を超えた分は追加されません。';
  }

  @override
  String refs_multiEncodes(Object count, Object names, Object cost) {
    return 'うち $count 件はエンコードが必要です（$names、1 件 $cost Anlas、初回のみ）。';
  }

  @override
  String refs_multiAlready(Object count) {
    return '$count 件は既に生成ページにあるため重複しません。';
  }

  @override
  String refs_multiPreciseCost(Object cost, Object total) {
    return '1 枚 $cost Anlas、合計で 1 枚あたり $total Anlas。';
  }

  @override
  String get refs_unify => 'まとめて設定';

  @override
  String get refs_mixed => '混在';

  @override
  String refs_unifyVibeNote(Object count) {
    return 'ドラッグすると $count 件の既定値をまとめて変更します。情報抽出は再エンコードが必要なため変更しません';
  }

  @override
  String refs_unifyPreciseNote(Object count) {
    return 'クリックで $count 枚すべてをこのタイプに';
  }

  @override
  String get refs_moveToCategory => 'カテゴリへ移動';

  @override
  String get refs_addTag => 'タグを追加';

  @override
  String get refs_packBundle => 'バンドルにまとめる';

  @override
  String get refs_close => '閉じる';

  @override
  String get refs_cancel => 'キャンセル';

  @override
  String get refs_remove => '外す';

  @override
  String get refs_prev => '前へ';

  @override
  String get refs_next => '次へ';

  @override
  String get refs_switch => '切り替え';

  @override
  String get refs_dropReplacePreview => 'ここに画像をドロップするとプレビューを差し替え（エンコードは変わりません）';

  @override
  String refs_bundleOfVibes(Object count) {
    return 'バンドル · Vibe $count 件';
  }

  @override
  String refs_bundleAll(Object count) {
    return '全 $count 件';
  }

  @override
  String refs_bundleOnlyChecked(Object count) {
    return 'チェックした $count 件のみ';
  }

  @override
  String get refs_bundleScopeNote => '送信時は各 Vibe の強度と情報抽出を使います';

  @override
  String get refs_splitBundle => '個別の Vibe に分割';

  @override
  String get refs_bundleNoteLong =>
      'パラメータを変えたら「バンドルに保存」で保存できます。保存しなければ今回の送信のみに影響します。';

  @override
  String refs_bundleAllEncoded(Object count, Object model) {
    return '$count 件すべて $model 用にエンコード済み';
  }

  @override
  String get refs_saveToBundle => 'バンドルに保存';

  @override
  String get refs_cover => 'カバー';

  @override
  String get refs_setCover => 'カバーに設定';

  @override
  String refs_exportTitle(Object count) {
    return 'Vibe $count 件をエクスポート';
  }

  @override
  String get refs_exportListNote => 'ライブラリで複数選択して「エクスポート」。ここで外すこともできます';

  @override
  String get refs_exportAs => 'エクスポート形式';

  @override
  String get refs_fmtVibeFile => '個別の Vibe ファイル';

  @override
  String get refs_fmtVibeFileDesc => '.naiv4vibe を 1 件ずつ。公式サイトや他クライアントでも読み込めます';

  @override
  String get refs_fmtBundle => 'バンドルにまとめる';

  @override
  String refs_fmtBundleDesc(Object count) {
    return '.naiv4vibebundle、$count 件を 1 ファイルに';
  }

  @override
  String get refs_fmtPng => 'PNG に埋め込み';

  @override
  String get refs_fmtPngDesc => '画像に Vibe を埋め込み、ドロップするだけで使えます。1 件ずつのみ';

  @override
  String get refs_fmtEncoded => 'エンコードテキスト';

  @override
  String get refs_fmtEncodedDesc => 'JSON / Base64。スクリプトや上級者向け';

  @override
  String get refs_options => 'オプション';

  @override
  String get refs_optThumbs => 'サムネイルを含める';

  @override
  String get refs_optThumbsDesc => 'ファイルが少し大きくなりますが、インポート時に画像が見えます';

  @override
  String get refs_optZip => 'ZIP に圧縮';

  @override
  String refs_optZipDesc(Object count) {
    return '$count 個のファイルを 1 つにまとめます';
  }

  @override
  String get refs_saveTo => '保存先';

  @override
  String get refs_choose => '選択';

  @override
  String refs_exportSummary(Object count, Object ext) {
    return '$ext ファイルを $count 個作成します';
  }

  @override
  String refs_exportSummaryZip(Object count, Object ext) {
    return 'ZIP を 1 個作成（$ext ファイル $count 個）';
  }

  @override
  String refs_deleteOne(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String refs_deleteMany(Object count) {
    return '$count 件を削除しますか？';
  }

  @override
  String get refs_deleteVibeDesc => 'Vibe ライブラリから削除します。生成ページで使用中のものには影響しません。';

  @override
  String get refs_deletePreciseDesc => 'ライブラリから削除します。生成ページで使用中のものには影響しません。';

  @override
  String refs_importTitle(Object count) {
    return '$count 件をインポート';
  }

  @override
  String get refs_importSubtitle => 'ドロップ・選択・貼り付けはすべてこの画面で確認します';

  @override
  String get refs_importMore => 'ファイルを追加';

  @override
  String get refs_importPutIn => 'すべて入れる先';

  @override
  String get refs_importAddTags => 'タグを追加';

  @override
  String get refs_importTagsHint => '入力して Enter';

  @override
  String get refs_importPlainImages => '通常の画像';

  @override
  String get refs_importEncodeLater => '使用時にエンコード';

  @override
  String refs_importEncodeNow(Object cost) {
    return '今すぐエンコード · 1 枚 $cost Anlas';
  }

  @override
  String get refs_importName => '名前';

  @override
  String get refs_importResult => '判定結果';

  @override
  String refs_recPng(Object model) {
    return 'Vibe 入り PNG · $model エンコード';
  }

  @override
  String refs_recVibeFile(Object model) {
    return 'Vibe ファイル · $model エンコード';
  }

  @override
  String refs_recBundle(Object count) {
    return 'バンドル · Vibe $count 件';
  }

  @override
  String get refs_recImage => '通常の画像 · 未エンコード';

  @override
  String get refs_recImageDup => '通常の画像 · 同名あり';

  @override
  String get refs_recFree => 'そのままインポート（無料）';

  @override
  String refs_recReencode(Object model) {
    return '$model で使うには再エンコードが必要（元画像がなければ不可）';
  }

  @override
  String refs_recBundleNote(Object count) {
    return 'まとめて = カード 1 枚、分割 = $count 枚';
  }

  @override
  String get refs_recEncodeLater => '元画像を保存し、初めて生成に使うときにそのモデル用にエンコード';

  @override
  String refs_recEncodeNow(Object cost) {
    return 'インポート時にエンコード（1 枚 $cost Anlas）';
  }

  @override
  String get refs_bundleWhole => 'まとめて';

  @override
  String refs_bundleSplit(Object count) {
    return '$count 件に分割';
  }

  @override
  String get refs_bundlePick => '選んで';

  @override
  String get refs_dupExists => '同名の項目があります';

  @override
  String get refs_dupKeepBoth => '両方残す';

  @override
  String get refs_dupOverwrite => '上書き';

  @override
  String get refs_dupSkip => 'スキップ';

  @override
  String refs_importSummary(Object files, Object cards) {
    return '$files 件 → カード $cards 枚追加';
  }

  @override
  String refs_importNow(Object cost) {
    return ' · 今 $cost Anlas 消費';
  }

  @override
  String refs_importLater(Object count, Object cost) {
    return ' · 通常の画像 $count 枚は初回使用時にエンコード（1 枚 $cost Anlas）';
  }

  @override
  String get refs_pickerVibeTitle => 'Vibe ライブラリから追加';

  @override
  String get refs_pickerPreciseTitle => '精密参照ライブラリから追加';

  @override
  String get refs_openVibeLibrary => 'Vibe ライブラリを開く';

  @override
  String get refs_openPreciseLibrary => 'ライブラリを開く';

  @override
  String get refs_recentUsed => '最近使用';

  @override
  String get refs_inUse => '使用中';

  @override
  String refs_pickedN(Object count) {
    return '$count 件選択';
  }

  @override
  String refs_pickerAfterVibe(Object count, Object max) {
    return ' · 追加後 $count/$max';
  }

  @override
  String refs_pickerAfterPrecise(Object count) {
    return ' · 追加後 $count 枚';
  }

  @override
  String refs_pickerEncode(Object name, Object model, Object cost) {
    return '「$name」は $model 用のエンコードが必要 · $cost Anlas';
  }

  @override
  String refs_pickerEncodeMore(Object count) {
    return 'ほか $count 件もエンコードが必要';
  }

  @override
  String refs_pickerExtra(Object free, Object extra) {
    return '$free 件を超えると +$extra Anlas';
  }

  @override
  String refs_pickerPreciseCost(Object cost, Object total) {
    return '1 枚 $cost Anlas · 合計 $total Anlas';
  }

  @override
  String get refs_replaceExisting => '既存を置き換え';

  @override
  String refs_appendN(Object count) {
    return '$count 件追加';
  }

  @override
  String get refs_timeNever => '未使用';

  @override
  String get refs_timeJustNow => 'たった今';

  @override
  String refs_timeMinutes(Object count) {
    return '$count 分前';
  }

  @override
  String refs_timeHours(Object count) {
    return '$count 時間前';
  }

  @override
  String get refs_timeYesterday => '昨日';

  @override
  String refs_timeDays(Object count) {
    return '$count 日前';
  }

  @override
  String refs_timeMonthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get blocks_title => 'ブロックライブラリ';

  @override
  String get blocks_translationMark => '訳';

  @override
  String get blocks_add => '追加';

  @override
  String get blocks_cancel => 'キャンセル';

  @override
  String get blocks_close => '閉じる';

  @override
  String get blocks_delete => '削除';

  @override
  String get blocks_done => '完了';

  @override
  String get blocks_save => '保存';

  @override
  String get blocks_saveEnter => '保存 ⏎';

  @override
  String get blocks_more => 'その他';

  @override
  String get blocks_back => '戻る';

  @override
  String get blocks_rename => '名前を変更';

  @override
  String get blocks_edit => '編集';

  @override
  String get blocks_copy => 'コピー';

  @override
  String get blocks_export => 'エクスポート';

  @override
  String get blocks_apply => '適用';

  @override
  String get blocks_off => 'オフ';

  @override
  String get blocks_to => '〜';

  @override
  String blocks_items(Object count) {
    return '$count 項目';
  }

  @override
  String get blocks_itemUnit => '項目';

  @override
  String blocks_usedTimes(Object count) {
    return '$count 回使用';
  }

  @override
  String blocks_nBlocks(Object count) {
    return '$count 個';
  }

  @override
  String get blocks_untitled => '無題';

  @override
  String get blocks_favorite => 'お気に入り';

  @override
  String get blocks_unfavorite => 'お気に入り解除';

  @override
  String get blocks_favorites => 'お気に入り';

  @override
  String get blocks_recent => '最近使用';

  @override
  String get blocks_uncategorized => '未分類';

  @override
  String get blocks_positive => 'ポジティブ';

  @override
  String get blocks_negative => 'ネガティブ';

  @override
  String blocks_positiveN(Object count) {
    return 'ポジ $count';
  }

  @override
  String blocks_negativeN(Object count) {
    return 'ネガ $count';
  }

  @override
  String get blocks_content => '内容';

  @override
  String get blocks_name => '名前';

  @override
  String get blocks_folder => 'フォルダー';

  @override
  String get blocks_folders => 'フォルダー';

  @override
  String get blocks_tags => 'タグ';

  @override
  String get blocks_tag => 'タグ';

  @override
  String get blocks_icon => 'アイコン';

  @override
  String get blocks_color => '色';

  @override
  String get blocks_look => '外観';

  @override
  String get blocks_appearance => '外観';

  @override
  String get blocks_thumb => 'プレビュー';

  @override
  String get blocks_preview => 'プレビュー';

  @override
  String get blocks_params => '付属パラメーター';

  @override
  String get blocks_classify => '分類';

  @override
  String get blocks_lookClassic => 'クラシック';

  @override
  String get blocks_lookStripes => 'ストライプ';

  @override
  String get blocks_lookDots => 'ドット';

  @override
  String get blocks_lookSolid => 'ソリッド';

  @override
  String get blocks_lookGradient => 'グラデーション';

  @override
  String get blocks_lookTranslation => '翻訳';

  @override
  String get blocks_hasParams => 'パラメーター付き';

  @override
  String get blocks_hasNegative => 'ネガ含む';

  @override
  String get blocks_hintClick => 'クリックで挿入';

  @override
  String get blocks_hintDrag => 'ドラッグで配置';

  @override
  String get blocks_hintRightClick => '右クリックでその他';

  @override
  String get blocks_searchHint => 'ブロックを検索…';

  @override
  String get blocks_filterAll => 'すべて';

  @override
  String blocks_allN(Object count) {
    return 'すべて $count';
  }

  @override
  String get blocks_searchResults => '検索結果';

  @override
  String get blocks_noResults => '一致するブロックはありません';

  @override
  String get blocks_noFavorites => 'お気に入りはまだありません。ブロックを右クリック → お気に入り。';

  @override
  String get blocks_dockEmpty =>
      'ブロックライブラリは空です。よく使うプロンプトをブロックとして保存すると、クリックひとつで挿入できます。';

  @override
  String get blocks_dockHint => 'クリックでカーソル位置に挿入 · プロンプトへドラッグで配置';

  @override
  String get blocks_openLibrary => 'ブロックライブラリで開く';

  @override
  String get blocks_newBlock => '新規ブロック';

  @override
  String get blocks_newBlockTip => '新規ブロック（Ctrl+N）';

  @override
  String get blocks_insertAtCursor => 'カーソル位置に挿入';

  @override
  String get blocks_addToPalette => 'パレットに追加';

  @override
  String get blocks_showInLibrary => 'ライブラリで表示';

  @override
  String get blocks_missing => 'ブロックは削除済み';

  @override
  String get blocks_modeFixed => '固定';

  @override
  String get blocks_modeSequential => '順番';

  @override
  String get blocks_modeRandom => 'ランダム';

  @override
  String blocks_summaryRandom(Object range, Object pool) {
    return 'ランダム · 毎回 $range 項目 · プール $pool 項目';
  }

  @override
  String blocks_summarySequential(Object range) {
    return '順番 · 毎回 $range 項目 · 1 枚ごとに進む';
  }

  @override
  String get blocks_drawnThisTime => '今回の抽選';

  @override
  String get blocks_lock => 'ロック';

  @override
  String get blocks_unlock => 'ロック解除';

  @override
  String get blocks_lockTip => 'この結果を固定し、生成時に再抽選しない';

  @override
  String get blocks_unlockTip => '解除すると生成時に再抽選します';

  @override
  String get blocks_reroll => '再抽選';

  @override
  String get blocks_rerollLocked => 'ロック中。再抽選するには解除してください';

  @override
  String blocks_skipped(Object percent) {
    return '今回は出現なし（出現率 $percent）';
  }

  @override
  String blocks_sendPrefix(Object text) {
    return '送信：$text';
  }

  @override
  String blocks_seqPosition(Object index, Object total) {
    return '$index / $total 項目';
  }

  @override
  String get blocks_seqLocked => 'ロック中、自動で進みません';

  @override
  String get blocks_prevItem => '前の項目';

  @override
  String get blocks_nextItem => '次の項目';

  @override
  String blocks_prevValue(Object value) {
    return '前 $value';
  }

  @override
  String blocks_nextValue(Object value) {
    return '次 $value';
  }

  @override
  String get blocks_paramsTitle => 'このブロックには生成パラメーターがあります';

  @override
  String get blocks_drawMode => '抽選方式';

  @override
  String blocks_fixedExplain(Object count) {
    return '固定：毎回 $count 項目すべてをそのまま入れます。順番かランダムにすると、ここで数と重みを設定できます。';
  }

  @override
  String get blocks_ruleCount => '数';

  @override
  String get blocks_ruleWeight => '重み';

  @override
  String get blocks_ruleShow => '出現';

  @override
  String get blocks_ruleEach => '毎回';

  @override
  String get blocks_ruleItemUnit => '項目';

  @override
  String get blocks_ruleWrap => '最後まで行ったら最初から';

  @override
  String get blocks_adjust => '調整';

  @override
  String get blocks_appliesTo => '適用先';

  @override
  String get blocks_disable => '無効化';

  @override
  String get blocks_enable => '有効化';

  @override
  String get blocks_editBlock => 'ブロック編集';

  @override
  String get blocks_removeInstanceTip => 'プロンプトから削除';

  @override
  String get blocks_removeInstance => 'プロンプトから削除';

  @override
  String get blocks_copySend => '送信テキストをコピー';

  @override
  String get blocks_evolutionOn => '遺伝対象にする';

  @override
  String get blocks_evolutionOff => '遺伝を解除';

  @override
  String get blocks_evolutionModeHint => '有効なブロックを順番またはランダム抽選にすると遺伝に参加できます。';

  @override
  String get blocks_rulesTitle => '抽選ルール';

  @override
  String get blocks_rulesHint => '完了を押すと反映';

  @override
  String get blocks_rulesDirty => '変更あり · 完了で反映';

  @override
  String get blocks_modeFixedDesc => '毎回すべてをそのまま';

  @override
  String get blocks_modeSequentialDesc => '順に回し、1 枚ごとに進む';

  @override
  String get blocks_modeRandomDesc => '毎回プールからランダムに抽選';

  @override
  String get blocks_drawEach => '毎回';

  @override
  String get blocks_takeEach => '毎回';

  @override
  String blocks_poolSize(Object count) {
    return 'プール $count 項目';
  }

  @override
  String get blocks_outputOrder => '出力順';

  @override
  String get blocks_orderDrawn => '抽選順';

  @override
  String get blocks_orderOriginal => '元の順序';

  @override
  String get blocks_seqExplain => '1 枚ごとに 1 つ進み、ロックすると現在の項目で止まります。';

  @override
  String get blocks_randomWeight => 'ランダム重み';

  @override
  String get blocks_randomWeightHint => '各項目に 0.8::…:: の重みを付けます';

  @override
  String get blocks_weightMin => '最小';

  @override
  String get blocks_weightAverage => '最頻';

  @override
  String get blocks_weightMax => '最大';

  @override
  String get blocks_distribution => '分布';

  @override
  String get blocks_distFocused => '集中';

  @override
  String get blocks_distBalanced => '均衡';

  @override
  String get blocks_distSpread => '分散';

  @override
  String get blocks_distCustom => 'カスタム';

  @override
  String get blocks_advanced => '詳細';

  @override
  String get blocks_leftDispersion => '左側の分散';

  @override
  String get blocks_rightDispersion => '右側の分散';

  @override
  String get blocks_softBalance => 'ソフトバランス';

  @override
  String get blocks_softBalanceHint => '複数項目の平均を最頻値に寄せる';

  @override
  String get blocks_softBalanceStrength => '強さ';

  @override
  String get blocks_probability => '出現率';

  @override
  String get blocks_probabilityHint => '100% 未満だと、ブロック全体が出ないことがあります';

  @override
  String get blocks_previewHint => 'このルールで 4 回抽選';

  @override
  String get blocks_resample => 'もう一度';

  @override
  String get blocks_sampleSkipped => '（出現なし）';

  @override
  String get blocks_resetDefault => 'デフォルトに戻す';

  @override
  String get blocks_discard => '変更を破棄';

  @override
  String get blocks_allBlocks => 'すべてのブロック';

  @override
  String get blocks_collections => 'コレクション';

  @override
  String get blocks_newCollection => '新規コレクション';

  @override
  String get blocks_collectionName => 'コレクション名';

  @override
  String get blocks_noCollections => 'ここのコレクションへカードをドラッグ。1 つのブロックを複数に入れられます。';

  @override
  String get blocks_deleteCollection => 'コレクションを削除';

  @override
  String get blocks_newFolder => '新規フォルダー';

  @override
  String get blocks_newSubfolder => 'サブフォルダーを作成';

  @override
  String get blocks_folderName => 'フォルダー名';

  @override
  String get blocks_deleteFolder => 'フォルダーを削除…';

  @override
  String get blocks_moveUp => '上へ';

  @override
  String get blocks_moveDown => '下へ';

  @override
  String get blocks_moveToTop => '最上位へ移動';

  @override
  String get blocks_tagName => 'タグ名';

  @override
  String get blocks_tagColor => '色を変更';

  @override
  String get blocks_deleteTag => 'タグを削除';

  @override
  String get blocks_collapseSidebar => 'サイドバーを閉じる';

  @override
  String get blocks_expandSidebar => 'サイドバーを開く';

  @override
  String get blocks_importExport => 'インポート / エクスポート';

  @override
  String get blocks_importTxt => 'TXT をインポート…';

  @override
  String get blocks_importFolder => 'フォルダーをインポート…';

  @override
  String get blocks_importCuration => '整理してインポート…';

  @override
  String get blocks_exportBackup => 'ライブラリをバックアップ';

  @override
  String get blocks_importBackup => 'バックアップから復元…';

  @override
  String blocks_dropMoveTo(Object name) {
    return '「$name」へ移動';
  }

  @override
  String blocks_dropCopyTo(Object name) {
    return '「$name」へコピー';
  }

  @override
  String blocks_dropAddTo(Object name) {
    return '「$name」に追加';
  }

  @override
  String get blocks_searchLibrary => 'タイトル・内容・タグを検索';

  @override
  String get blocks_sortCustom => 'カスタム順';

  @override
  String get blocks_sortUpdated => '最近の変更';

  @override
  String get blocks_sortTitle => '名前';

  @override
  String get blocks_sortColor => '色';

  @override
  String get blocks_sortIcon => 'アイコン';

  @override
  String get blocks_sortAsc => '昇順';

  @override
  String get blocks_sortDesc => '降順';

  @override
  String get blocks_viewGrid => 'グリッド';

  @override
  String get blocks_viewList => 'リスト';

  @override
  String get blocks_multiSelect => '複数選択';

  @override
  String get blocks_multiDone => '選択を終了';

  @override
  String get blocks_hideInspector => '詳細を隠す';

  @override
  String get blocks_showInspector => '詳細を表示';

  @override
  String get blocks_quickImage => 'プレビューあり';

  @override
  String get blocks_quickNegative => 'ネガ含む';

  @override
  String get blocks_quickParams => 'パラメーター付き';

  @override
  String get blocks_cardSize => 'カード幅';

  @override
  String get blocks_noMatch => '条件に合うブロックはありません';

  @override
  String get blocks_noMatchBody => '別のキーワードを試すか、クイックフィルターを解除してください。';

  @override
  String get blocks_clearFilters => 'フィルターを解除';

  @override
  String get blocks_insert => '挿入';

  @override
  String get blocks_insertToPrompt => 'プロンプトに挿入';

  @override
  String get blocks_miniNegative => 'ネガ';

  @override
  String get blocks_miniParams => 'パラメ';

  @override
  String get blocks_colName => '名前';

  @override
  String get blocks_colItems => '項目数';

  @override
  String get blocks_colFolder => 'フォルダー';

  @override
  String get blocks_colUsed => '使用';

  @override
  String get blocks_colModified => '変更';

  @override
  String blocks_selectedN(Object count) {
    return '$count 件選択';
  }

  @override
  String blocks_selectedBlocksN(Object count) {
    return '$count 個のブロックを選択';
  }

  @override
  String get blocks_moveTo => '移動…';

  @override
  String get blocks_noTags => 'タグはまだありません';

  @override
  String get blocks_emptyTitle => 'ブロックライブラリは空です';

  @override
  String get blocks_emptyBody =>
      '画師プール、キャラクター、衣装、品質タグなど、よく使うプロンプトをブロックとして保存しましょう。挿入後は固定・順番・ランダムで使えます。';

  @override
  String get blocks_duplicate => '複製';

  @override
  String get blocks_copyContent => '内容をコピー';

  @override
  String get blocks_applyParams => '付属パラメーターを適用';

  @override
  String get blocks_exportTxt => 'TXT にエクスポート';

  @override
  String get blocks_removeFromCollection => 'コレクションから外す';

  @override
  String blocks_deleteOne(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String blocks_deleteMany(Object count) {
    return '$count 個のブロックを削除しますか？';
  }

  @override
  String get blocks_deleteBody =>
      'プロンプトに挿入済みのインスタンスは「ブロックは削除済み」と表示されます。元に戻せます。';

  @override
  String get blocks_details => '詳細';

  @override
  String get blocks_noSelection => 'カードをクリックで詳細。ダブルクリックで編集、Enter でプロンプトに挿入。';

  @override
  String get blocks_changeThumb => '変更 / 調整';

  @override
  String get blocks_reading => '翻訳（読み）';

  @override
  String get blocks_needsReview => '要確認';

  @override
  String get blocks_applyToCurrent => '現在に適用';

  @override
  String get blocks_noParams => 'なし。挿入しても現在のパラメーターは変わりません。';

  @override
  String get blocks_paramModel => 'モデル';

  @override
  String get blocks_paramSteps => 'ステップ';

  @override
  String get blocks_paramGuidance => 'ガイダンス';

  @override
  String get blocks_paramRescale => 'リスケール';

  @override
  String get blocks_paramSampler => 'サンプラー';

  @override
  String get blocks_paramNoise => 'ノイズ';

  @override
  String blocks_steps(Object count) {
    return '$count ステップ';
  }

  @override
  String blocks_guidance(Object value) {
    return 'ガイダンス $value';
  }

  @override
  String blocks_rescale(Object value) {
    return 'リスケール $value';
  }

  @override
  String get blocks_newTagInEdit => '新規タグ…';

  @override
  String blocks_modifiedAt(Object time) {
    return '$time に変更';
  }

  @override
  String blocks_createdAt(Object date) {
    return '$date に作成';
  }

  @override
  String blocks_sourceFile(Object path) {
    return 'ソースファイル $path';
  }

  @override
  String get blocks_sourceSynced => 'ファイルと一致';

  @override
  String get blocks_sourceChanged => 'ファイルが変更済み';

  @override
  String get blocks_sourceMissing => 'ファイルが見つかりません';

  @override
  String blocks_importedAt(Object date) {
    return '$date にインポート';
  }

  @override
  String get blocks_total => '合計';

  @override
  String blocks_totalItems(Object count) {
    return '$count 項目';
  }

  @override
  String get blocks_from => '出所';

  @override
  String get blocks_batch => '一括操作';

  @override
  String get blocks_insertInOrder => '順にプロンプトへ挿入';

  @override
  String get blocks_mergeNew => '新しいブロックに統合…';

  @override
  String get blocks_batchStyle => '色 / 外観をまとめて変更';

  @override
  String blocks_dragHint(Object count) {
    return 'この $count 枚のカードを左のフォルダーやコレクションにドラッグし、離すときに移動かコピーを選べます。';
  }

  @override
  String get blocks_editBlockTitle => 'ブロックを編集';

  @override
  String get blocks_editHint =>
      '保存後、プロンプト内の固定インスタンスはすぐ更新され、ランダム / 順番は次の抽選から新しい内容を使います';

  @override
  String get blocks_newBlockHint => '保存後、生成ページのサイドバーからワンクリックで挿入できます';

  @override
  String get blocks_addThumb => 'プレビューを追加';

  @override
  String get blocks_changeImage => '画像を変更';

  @override
  String get blocks_clearThumb => 'プレビューを削除';

  @override
  String get blocks_cropHint => 'ドラッグ / ホイールで拡大';

  @override
  String get blocks_namePlaceholder => '空欄なら最初の項目';

  @override
  String get blocks_plainText => 'テキスト';

  @override
  String get blocks_plainTextHint => '入力どおりに保存し、項目に分けません';

  @override
  String get blocks_atomHint => '入力して Enter かカンマで追加。貼り付けると自動で分割';

  @override
  String get blocks_existingTags => '既存のタグ';

  @override
  String get blocks_newTag => '新しいタグ';

  @override
  String get blocks_paramsNotAuto => '挿入時は自動適用しない';

  @override
  String get blocks_noParamsShort => 'なし';

  @override
  String get blocks_editParams => 'パラメーターを編集';

  @override
  String get blocks_captureParams => '現在の値を読む';

  @override
  String get blocks_keepCurrent => '現在の値のまま';

  @override
  String get blocks_clearParams => 'パラメーターをクリア';

  @override
  String get blocks_deleteBlock => 'ブロックを削除';

  @override
  String get blocks_deleteConfirmInline => 'このブロックを削除しますか？';

  @override
  String get blocks_saveShortcut => 'Ctrl+Enter で保存';

  @override
  String get blocks_saveAsBlock => 'ブロックとして保存';

  @override
  String get blocks_lookup => '用語を調べる';

  @override
  String blocks_splitDone(Object count) {
    return '$count 項目 · カンマで分割済み';
  }

  @override
  String get blocks_replaceSelection => '保存後、選択したテキストをこのブロックに置き換える';

  @override
  String get blocks_quickHint => 'プレビュー・ネガ・パラメーターは後でライブラリで設定';

  @override
  String get imageViewer_backGallery => 'ローカルギャラリー';

  @override
  String get imageViewer_backGeneration => '生成';

  @override
  String get imageViewer_scopeAll => 'すべての画像';

  @override
  String get imageViewer_sortModified => '更新日時順';

  @override
  String get imageViewer_sortCreated => '作成日時順';

  @override
  String get imageViewer_sortFileName => 'ファイル名順';

  @override
  String get imageViewer_sortFileSize => 'ファイルサイズ順';

  @override
  String get imageViewer_sortDimensions => 'サイズ順';

  @override
  String get imageViewer_unsaved => '未保存';

  @override
  String get imageViewer_saved => '保存済み';

  @override
  String imageViewer_batch(Object count) {
    return '生成結果 · 今回 $count 枚';
  }

  @override
  String imageViewer_zoomFit(Object percent) {
    return 'フィット · $percent%';
  }

  @override
  String get imageViewer_zoomFitPending => 'フィット · —';

  @override
  String get imageViewer_zoomFitShort => 'フィット';

  @override
  String get imageViewer_zoomIn => '拡大';

  @override
  String get imageViewer_zoomOut => '縮小';

  @override
  String get imageViewer_actualSize => '原寸';

  @override
  String get imageViewer_fullscreen => '全画面';

  @override
  String get imageViewer_exitFullscreen => '全画面を終了';

  @override
  String get imageViewer_fullscreenHint => '下端にマウスでフィルムストリップ · 2 秒静止で非表示';

  @override
  String get imageViewer_infoPanel => '情報パネル';

  @override
  String get imageViewer_infoShort => '情報';

  @override
  String get imageViewer_hideInfo => '情報を閉じる';

  @override
  String get imageViewer_previous => '前へ';

  @override
  String get imageViewer_next => '次へ';

  @override
  String get imageViewer_loadingOriginal => '元画像を読み込み中';

  @override
  String imageViewer_loadingOriginalSize(Object size) {
    return '元画像を読み込み中 · $size';
  }

  @override
  String get imageViewer_missingTitle => 'この画像が見つかりません';

  @override
  String get imageViewer_missingHint => 'エクスプローラーで移動・名前変更・削除された可能性があります';

  @override
  String get imageViewer_openFolder => 'フォルダーを開く';

  @override
  String get imageViewer_nextImage => '次の画像';

  @override
  String get imageViewer_hintPan => 'ドラッグで移動';

  @override
  String get imageViewer_hintWheel => 'ホイールでズーム';

  @override
  String get imageViewer_hintDouble => 'ダブルクリック /';

  @override
  String get imageViewer_hintFit => 'フィットに戻す';

  @override
  String get imageViewer_hintActual => '原寸';

  @override
  String get imageViewer_dragFrame => '枠をドラッグ';

  @override
  String get imageViewer_movedToTrash => 'ごみ箱に移動しました';

  @override
  String get imageViewer_undo => '元に戻す';

  @override
  String get imageViewer_details => '詳細';

  @override
  String get imageViewer_generationResult => '生成結果';

  @override
  String get imageViewer_favorite => 'お気に入り';

  @override
  String get imageViewer_showInFolder => 'フォルダーに表示';

  @override
  String imageViewer_deleteKey(Object key) {
    return '削除  $key';
  }

  @override
  String get imageViewer_more => 'その他';

  @override
  String imageViewer_genIndex(Object index) {
    return '今回の生成 · $index 枚目';
  }

  @override
  String get imageViewer_notSaved => 'ギャラリー未保存';

  @override
  String get imageViewer_savedToGallery => 'ギャラリーに保存済み';

  @override
  String get imageViewer_size => 'サイズ';

  @override
  String get imageViewer_fileSize => '容量';

  @override
  String get imageViewer_modified => '更新日時';

  @override
  String get imageViewer_model => 'モデル';

  @override
  String get imageViewer_params => '生成パラメーター';

  @override
  String get imageViewer_loadingMeta => 'メタデータを読み込み中…';

  @override
  String get imageViewer_seed => 'シード';

  @override
  String get imageViewer_sampler => 'サンプラー';

  @override
  String get imageViewer_steps => 'ステップ';

  @override
  String get imageViewer_guidance => 'ガイダンス';

  @override
  String imageViewer_noise(Object value) {
    return 'ノイズ $value';
  }

  @override
  String imageViewer_rescale(Object value) {
    return 'リスケール $value';
  }

  @override
  String imageViewer_precise(Object count) {
    return '精密参照 ×$count';
  }

  @override
  String get imageViewer_qualityTags => '品質タグ';

  @override
  String get imageViewer_prompt => 'プロンプト';

  @override
  String get imageViewer_translate => '翻訳';

  @override
  String get imageViewer_showOriginal => '原文を表示';

  @override
  String imageViewer_translateFailed(Object error) {
    return '翻訳に失敗しました：$error';
  }

  @override
  String get imageViewer_copy => 'コピー';

  @override
  String get imageViewer_copySeed => 'シードをコピー';

  @override
  String get imageViewer_expandAll => 'すべて表示';

  @override
  String get imageViewer_expand => '展開';

  @override
  String get imageViewer_collapse => '折りたたむ';

  @override
  String imageViewer_character(Object index) {
    return 'キャラクター $index';
  }

  @override
  String imageViewer_position(Object cell) {
    return '位置 $cell';
  }

  @override
  String get imageViewer_characterNegative => 'キャラ ネガティブ · ';

  @override
  String get imageViewer_negative => 'ネガティブ';

  @override
  String imageViewer_tagCount(Object count) {
    return '$count 項目';
  }

  @override
  String get imageViewer_vibes => 'Vibe 参照';

  @override
  String imageViewer_vibeStrength(Object value) {
    return '強度 $value';
  }

  @override
  String imageViewer_vibeInfo(Object value) {
    return '情報 $value';
  }

  @override
  String get imageViewer_saveVibe => 'Vibe ライブラリに保存';

  @override
  String get imageViewer_noMetaTitle => 'NovelAI の生成情報がありません';

  @override
  String get imageViewer_noMetaBody =>
      'NAI で生成された画像ではないか、メタデータが削除されています（スクリーンショット・再保存・圧縮画像によくあります）。\n下の画像から画像・スタイル転送・精密参照・拡大は使えます。';

  @override
  String get imageViewer_reuse => 'パラメーターを再利用';

  @override
  String get imageViewer_reuseNoMeta => '生成情報なし';

  @override
  String get imageViewer_img2img => '画像から画像';

  @override
  String get imageViewer_styleTransfer => 'スタイル転送';

  @override
  String get imageViewer_preciseRef => '精密参照';

  @override
  String get imageViewer_saveRef => '参照に保存';

  @override
  String get imageViewer_krita => 'Krita に送る';

  @override
  String get imageViewer_kritaOff => 'Krita に接続していません';

  @override
  String get imageViewer_upscale => '拡大';

  @override
  String get imageViewer_copyImage => '画像をコピー';

  @override
  String get imageViewer_saveBlock => 'ブロックに保存';

  @override
  String get imageViewer_save => 'ギャラリーに保存';

  @override
  String get imageViewer_copyPath => 'ファイルパスをコピー';

  @override
  String get imageViewer_copyAllPrompts => 'すべてのプロンプトをコピー（キャラ含む）';

  @override
  String get imageViewer_saveBlockEllipsis => 'ブロックに保存…';

  @override
  String get imageViewer_addToCollection => 'コレクションに追加';

  @override
  String get imageViewer_moveTo => '移動…';

  @override
  String get imageViewer_copyTo => 'コピー先…';

  @override
  String get imageViewer_moveToTrash => 'ごみ箱に移動';

  @override
  String get imageViewer_collections => 'コレクション';

  @override
  String get imageViewer_newCollection => '新しいコレクション…';

  @override
  String get imageViewer_helpTitle => 'ビューアーのショートカット';

  @override
  String get imageViewer_helpHint => '設定 → ショートカットで変更できます';

  @override
  String get imageViewer_helpClose => 'もう一度押すと閉じる';

  @override
  String get imageViewer_helpBrowse => '閲覧';

  @override
  String get imageViewer_helpZoom => 'ズーム';

  @override
  String get imageViewer_helpActions => '操作';

  @override
  String get imageViewer_helpPrevNext => '前へ / 次へ';

  @override
  String get imageViewer_helpFirstLast => '最初 / 最後';

  @override
  String get imageViewer_helpInfo => '情報の表示 / 非表示';

  @override
  String get imageViewer_helpClose2 => '閉じる';

  @override
  String get imageViewer_helpZoomInOut => '拡大 / 縮小';

  @override
  String get imageViewer_helpActual => '原寸 100%';

  @override
  String get imageViewer_helpWheel => 'カーソル位置を中心にズーム';

  @override
  String get imageViewer_helpDouble => 'フィット ↔ 拡大';

  @override
  String get imageViewer_keyWheel => 'ホイール';

  @override
  String get imageViewer_keyDouble => 'ダブルクリック';

  @override
  String get imageViewer_helpCopyPrompt => 'プロンプトをコピー';

  @override
  String get imageViewer_helpUndo => '削除を元に戻す';

  @override
  String get imageViewer_protectedTitle => 'この画像は保護されています。ごみ箱に移動しますか？';

  @override
  String get imageViewer_protectedBody => 'ごみ箱から元に戻せます。';

  @override
  String get imageViewer_cancel => 'キャンセル';

  @override
  String get imageViewer_justNow => 'たった今';

  @override
  String imageViewer_minutesAgo(Object count) {
    return '$count 分前';
  }

  @override
  String imageViewer_hoursAgo(Object count) {
    return '$count 時間前';
  }

  @override
  String get imageViewer_yesterday => '昨日';

  @override
  String get explore_back => '画風探索';

  @override
  String get explore_close => '閉じる';

  @override
  String get explore_cancel => 'キャンセル';

  @override
  String get explore_done => '完了';

  @override
  String get explore_more => 'その他';

  @override
  String get explore_rename => '名前を変更';

  @override
  String get explore_remove => '外す';

  @override
  String get explore_copy => 'コピー';

  @override
  String get explore_undo => '元に戻す';

  @override
  String get explore_expand => '展開';

  @override
  String get explore_expandAll => 'すべて表示';

  @override
  String get explore_collapse => '折りたたむ';

  @override
  String get explore_previous => '前へ';

  @override
  String get explore_next => '次へ';

  @override
  String explore_today(Object time) {
    return '今日 $time';
  }

  @override
  String explore_yesterday(Object time) {
    return '昨日 $time';
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
  String get explore_sectionToday => '今日';

  @override
  String get explore_thisWeek => '今週';

  @override
  String get explore_earlier => 'それ以前';

  @override
  String get explore_variables => 'ランダム変数';

  @override
  String get explore_variablesHint => '1 枚ごとに抽選';

  @override
  String get explore_variablesInfo =>
      '有効な順番・ランダムブロックを、それぞれの抽選ルールで使います。「遺伝対象」の抽選結果を結合し、親のプロンプトとして遺伝に使います。';

  @override
  String get explore_variablesEmpty =>
      'プロンプトにランダムブロックがありません。ブロックライブラリから（絵師プールなど）を挿入すると、毎回抽選されます。';

  @override
  String get explore_openBlockLibrary => 'ブロックライブラリを開く';

  @override
  String get explore_variableMissing => 'ブロック削除済み';

  @override
  String explore_poolSize(Object count) {
    return 'プール $count 件';
  }

  @override
  String get explore_evolutionTarget => '遺伝対象';

  @override
  String explore_draw(Object count) {
    return '候補を $count 枚引く';
  }

  @override
  String get explore_stopGenerating => '生成を停止';

  @override
  String get explore_busy => '生成中';

  @override
  String explore_cooldown(Object seconds) {
    return 'クールダウン $seconds 秒';
  }

  @override
  String get explore_insufficient => 'Anlas が足りません';

  @override
  String explore_count(Object count) {
    return '$count 枚';
  }

  @override
  String explore_favoritesCount(Object count) {
    return 'お気に入り $count';
  }

  @override
  String explore_roundsCount(Object count) {
    return '$count ラウンド';
  }

  @override
  String explore_linesCount(Object count) {
    return '進化ライン $count';
  }

  @override
  String explore_progressRound(Object round, Object done, Object total) {
    return 'ラウンド $round · $done / $total';
  }

  @override
  String explore_progressChildren(
    Object line,
    Object gen,
    Object done,
    Object total,
  ) {
    return '$line 第 $gen 世代 · $done / $total';
  }

  @override
  String explore_paused(Object where) {
    return '一時停止 · $where';
  }

  @override
  String get explore_pause => '一時停止';

  @override
  String get explore_resume => '再開';

  @override
  String get explore_stop => '停止';

  @override
  String get explore_sizeSmall => '小さいカード';

  @override
  String get explore_sizeLarge => '大きいカード';

  @override
  String get explore_inspector => 'インスペクター';

  @override
  String get explore_hideInspector => '閉じる';

  @override
  String get explore_tabCandidates => '候補';

  @override
  String get explore_tabEvolution => '進化';

  @override
  String get explore_filterAll => 'すべて';

  @override
  String get explore_filterFavorites => 'お気に入り';

  @override
  String get explore_filterUngrouped => '未分類';

  @override
  String get explore_addGroup => 'グループ';

  @override
  String get explore_groupName => 'グループ名';

  @override
  String get explore_deleteGroup => 'グループを削除（メンバーは未分類へ）';

  @override
  String get explore_newLine => '新しい進化ライン';

  @override
  String get explore_deleteLine => '進化ラインを削除';

  @override
  String get explore_compareShort => '比較';

  @override
  String get explore_evoHelp => '使い方';

  @override
  String get explore_evoHelpBody =>
      '1. 気に入った候補を選んで進化を開始すると、その絵師列が第 1 世代の親になります。\n2. 子は交叉・変異・新しい絵師の注入で作られます。\n3. 気に入った子を選んで次の世代を育てます。2 枚比較で親の優先度を調整できます。';

  @override
  String get explore_select => '複数選択';

  @override
  String get explore_selectAll => 'すべて選択';

  @override
  String get explore_selectDone => '完了';

  @override
  String get explore_selectExit => '選択を終了  Esc';

  @override
  String get explore_selectHint => 'カードをクリックで選択';

  @override
  String explore_selectedN(Object count) {
    return '$count 枚選択中';
  }

  @override
  String get explore_sortNewest => '新しいラウンドが上（クリックで古い順）';

  @override
  String get explore_sortOldest => '古いラウンドが上（クリックで新しい順）';

  @override
  String explore_round(Object number) {
    return 'ラウンド $number';
  }

  @override
  String explore_generatingShort(Object done, Object total) {
    return '生成中 $done / $total';
  }

  @override
  String explore_failedRetry(Object count) {
    return '$count 枚失敗 · 再試行';
  }

  @override
  String get explore_pick => '進化用に選ぶ';

  @override
  String get explore_pickTip => 'このラウンドのお気に入りを選択した状態で複数選択に入ります';

  @override
  String get explore_filterEmpty => 'このフィルターに一致する候補はありません';

  @override
  String get explore_showAll => 'すべて表示';

  @override
  String explore_queued(Object number) {
    return '待機 #$number';
  }

  @override
  String explore_generatingN(Object number) {
    return '生成中 #$number';
  }

  @override
  String get explore_failed => '生成失敗';

  @override
  String get explore_failedHover => 'ホバーで理由を表示';

  @override
  String get explore_noArtists => '絵師なし';

  @override
  String get explore_parentTip => '進化ラインの親です';

  @override
  String get explore_favorite => 'お気に入り';

  @override
  String get explore_favorited => 'お気に入り済み';

  @override
  String get explore_unfavorite => 'お気に入り解除';

  @override
  String get explore_addToEvolution => '進化に追加';

  @override
  String get explore_startEvolution => '進化を開始';

  @override
  String get explore_saveBlock => 'ブロックとして保存';

  @override
  String get explore_applyToEditor => 'エディターに適用';

  @override
  String get explore_copyArtists => '絵師列をコピー';

  @override
  String get explore_openLarge => '大きく表示';

  @override
  String get explore_group => 'グループ';

  @override
  String get explore_groups => 'グループ';

  @override
  String get explore_groupsHint => '1–9 キーで分類';

  @override
  String get explore_newGroup => '新しいグループ';

  @override
  String get explore_ungroup => 'グループから外す';

  @override
  String get explore_delete => '削除';

  @override
  String explore_deleteN(Object count) {
    return '$count 枚を削除';
  }

  @override
  String get explore_deleteThis => 'この画像を削除';

  @override
  String explore_deleted(Object count) {
    return '$count 枚を削除しました';
  }

  @override
  String get explore_inspectorEmpty => '候補をクリックすると、抽選された絵師がここに表示されます';

  @override
  String explore_childN(Object number) {
    return '子 #$number';
  }

  @override
  String explore_genOp(Object gen, Object op) {
    return '第 $gen 世代 · $op';
  }

  @override
  String get explore_drawn => 'この画像の抽選結果';

  @override
  String get explore_drawEmpty => '今回は空き枠が出ました';

  @override
  String get explore_origin => '生まれ方';

  @override
  String get explore_seed => 'シード';

  @override
  String get explore_elapsed => '所要時間';

  @override
  String get explore_params => 'パラメーター';

  @override
  String get explore_sampler => 'サンプラー';

  @override
  String get explore_model => 'モデル';

  @override
  String explore_steps(Object count) {
    return '$count ステップ';
  }

  @override
  String get explore_fullPrompt => '完全なプロンプト';

  @override
  String get explore_negative => 'ネガティブ';

  @override
  String get explore_failReason => '失敗の理由';

  @override
  String get explore_retryFailed => '失敗した候補を再試行';

  @override
  String get explore_waitHint => '生成されると抽選された絵師がここに表示されます';

  @override
  String explore_mergedArtists(Object count) {
    return 'まとめた絵師 · $count';
  }

  @override
  String get explore_multiHint =>
      'ブロック保存ではこれらの絵師を 1 つにまとめます。進化では 1 枚ずつが親になります。';

  @override
  String get explore_evoEmptyTitle => '進化ラインはまだありません';

  @override
  String get explore_evoEmptyBody =>
      '気に入った候補を選んで「進化を開始」を押すと、良い絵師の組み合わせから新しい組み合わせを育てます。';

  @override
  String get explore_evoGoPick => '候補から選ぶ';

  @override
  String explore_gen(Object number) {
    return '第 $number 世代';
  }

  @override
  String get explore_current => '現在';

  @override
  String explore_genFirst(Object picked, Object children) {
    return '候補から $picked 枚を起点に · 子 $children 枚';
  }

  @override
  String explore_genFrom(
    Object parents,
    Object children,
    Object from,
    Object picked,
  ) {
    return '親 $parents → 子 $children · 第 $from 世代から $picked 枚';
  }

  @override
  String get explore_backcross => '第 1 世代と戻し交配';

  @override
  String get explore_compare => '2 枚比較で並べ替え';

  @override
  String get explore_compareTip => '親を 2 枚ずつ見て良い方を選びます。優先度が高いほど選ばれやすくなります';

  @override
  String explore_generateChildren(Object count) {
    return '子を $count 枚生成';
  }

  @override
  String explore_children(Object count) {
    return '子 · $count';
  }

  @override
  String explore_pickedN(Object count) {
    return '$count 枚選択';
  }

  @override
  String get explore_breedHint => '気に入った子を選んで次の世代へ';

  @override
  String explore_breed(Object count, Object next) {
    return '選んだ $count 枚で第 $next 世代を育てる';
  }

  @override
  String get explore_noChildren => 'まだ子はありません · 「生成」で最初のバッチを作成';

  @override
  String explore_parentsByPref(Object count) {
    return '親 · 優先度順 · $count';
  }

  @override
  String get explore_opMutation => '変異';

  @override
  String get explore_opCrossover => '交叉';

  @override
  String get explore_opInjection => '注入';

  @override
  String get explore_searchRuns => '探索を検索';

  @override
  String get explore_newRun => '新しい探索';

  @override
  String get explore_newRunHint => '現在のプロンプトと設定で開始。名前は後で変更できます';

  @override
  String explore_runRunning(Object done, Object total) {
    return '生成中 $done/$total';
  }

  @override
  String explore_runPaused(Object done, Object total) {
    return '一時停止 $done/$total';
  }

  @override
  String explore_runFailed(Object count) {
    return '$count 枚失敗';
  }

  @override
  String get explore_noRunMatch => '一致する探索はありません';

  @override
  String get explore_runMenuHint => '自動命名：ランダムブロック名 + 日付 · 行の「⋯」で名前変更・削除';

  @override
  String get explore_deleteRun => '探索を削除';

  @override
  String explore_deleteRunTitle(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String explore_deleteRunBody(Object count) {
    return '候補 $count 枚とすべての進化ラインが削除され、元に戻せません。ギャラリーの画像には影響しません。';
  }

  @override
  String explore_deleteLineTitle(Object name) {
    return '進化ライン「$name」を削除しますか？';
  }

  @override
  String explore_deleteLineBody(Object count) {
    return 'このラインの子 $count 枚も削除され、元に戻せません。候補には影響しません。';
  }

  @override
  String get explore_onboardingTitle => 'ランダムブロックで画風をまとめて試す';

  @override
  String get explore_onboardingBody => '1 枚ごとに絵師プールから抽選。気に入った組み合わせを残して進化させます。';

  @override
  String get explore_step1 => 'ランダムブロックを入れる';

  @override
  String get explore_step1Body => 'ライブラリのランダムブロック（絵師プールなど）をプロンプトに挿入します。';

  @override
  String get explore_step2 => '候補をまとめて引く';

  @override
  String explore_step2Body(Object count) {
    return '左下の「候補を $count 枚引く」を押すと、1 枚ずつ絵師を抽選します。';
  }

  @override
  String get explore_step3 => 'お気に入り・進化・保存';

  @override
  String get explore_step3Body => '気に入ったものを保存して進化させ、満足した組み合わせをブロックにします。';

  @override
  String explore_detected(Object count) {
    return '$count 個検出';
  }

  @override
  String get explore_noVariables => 'ランダムブロックがありません';

  @override
  String get explore_openPrevious => '以前の探索を開く';

  @override
  String explore_evoTitle(Object count) {
    return '$count 枚の候補で進化を開始';
  }

  @override
  String explore_evoJoinTitle(Object count, Object line, Object gen) {
    return '$count 枚を「$line」第 $gen 世代に追加';
  }

  @override
  String get explore_evoStep1 => '親';

  @override
  String get explore_evoStep1Body => '各候補の絵師列が 1 つの親になります';

  @override
  String get explore_evoStep2 => '子';

  @override
  String get explore_evoStep2Body => '交叉・変異・新しい絵師の注入';

  @override
  String get explore_evoStep3 => '選ぶ';

  @override
  String get explore_evoStep3Body => '気に入った子で次の世代へ';

  @override
  String get explore_evoNewLine => '新しい進化ライン';

  @override
  String explore_evoJoin(Object line, Object gen) {
    return '「$line」第 $gen 世代に追加';
  }

  @override
  String get explore_lineName => '進化ライン名';

  @override
  String explore_lineDefault(Object number) {
    return '進化ライン $number';
  }

  @override
  String explore_lineGen(Object line, Object gen) {
    return '$line · 第 $gen 世代';
  }

  @override
  String explore_evoParents(Object count) {
    return '第 1 世代の親 · $count';
  }

  @override
  String explore_evoAddParents(Object count) {
    return '追加する親 · $count';
  }

  @override
  String get explore_addCustom => 'カスタム絵師列を追加';

  @override
  String get explore_customHint =>
      '例：0.8::artist:ciloranko::, artist:rella（Enter で追加）';

  @override
  String get explore_targetBefore => '遺伝対象：';

  @override
  String get explore_targetAfter => 'の抽選結果を結合して親のプロンプトにします';

  @override
  String get explore_noTarget => '遺伝対象がありません。順番またはランダムブロックで遺伝を有効にしてください。';

  @override
  String get explore_firstBatch => '最初の子';

  @override
  String get explore_atLeast4 => '枚（4 枚以上）';

  @override
  String get explore_createOnly => '作成のみ';

  @override
  String get explore_joinOnly => '追加のみ';

  @override
  String explore_createGenerate(Object count) {
    return '作成して $count 枚生成';
  }

  @override
  String get explore_saveBlockTitle => 'プロンプトブロックとして保存';

  @override
  String get explore_untitled => '無題';

  @override
  String explore_blockFromOne(Object number) {
    return '候補 #$number から';
  }

  @override
  String explore_blockFromMany(Object count) {
    return '$count 枚の候補から（重複なし）';
  }

  @override
  String explore_blockNameMany(Object run, Object count) {
    return '$run · 厳選 $count';
  }

  @override
  String get explore_blockContent => '内容';

  @override
  String get explore_blockArtists => '抽選された絵師のみ';

  @override
  String get explore_blockFull => 'ポジティブ全体';

  @override
  String get explore_blockFullSingle => '候補が 1 枚のときだけ使えます';

  @override
  String get explore_blockRemoveHint => '× で不要な絵師を外す';

  @override
  String explore_blockKept(Object kept, Object total) {
    return '$kept / $total を保持';
  }

  @override
  String get explore_blockName => '名前';

  @override
  String get explore_blockColor => '色';

  @override
  String get explore_blockFolder => '保存先';

  @override
  String get explore_blockRoot => 'ブロックライブラリ（ルート）';

  @override
  String get explore_blockFooter => '保存後、ブロックライブラリからプロンプトにドラッグできます';

  @override
  String get explore_compareTitle => '2 枚比較 · 親を並べ替え';

  @override
  String get explore_compareNote => '結果はその都度保存されます';

  @override
  String get explore_compareQuestion => 'どちらが求める画風に近いですか？';

  @override
  String explore_comparePairs(Object index, Object total) {
    return '$index / $total 組';
  }

  @override
  String get explore_leftBetter => '左が良い';

  @override
  String get explore_rightBetter => '右が良い';

  @override
  String get explore_neither => 'どちらも違う';

  @override
  String get explore_skip => 'スキップ';

  @override
  String get explore_keySpace => 'Space';

  @override
  String get explore_ranking => '現在の順位 · リアルタイム';

  @override
  String get explore_rankingNote => '優先度が高いほど、次の世代で親に選ばれやすくなります。';

  @override
  String get explore_compareDone => '並べ替え完了';

  @override
  String get explore_compareDoneBody => '新しい優先度は保存され、次の子の生成に使われます。';

  @override
  String get gen_cancel => 'キャンセル';

  @override
  String get gen_close => '閉じる';

  @override
  String get gen_done => '完了';

  @override
  String get gen_more => 'その他';

  @override
  String get gen_delete => '削除';

  @override
  String get gen_remove => '外す';

  @override
  String get gen_rename => '名前を変更';

  @override
  String get gen_add => '追加';

  @override
  String get gen_clear => 'クリア';

  @override
  String get gen_clearAll => 'すべてクリア';

  @override
  String get gen_clearConfirm => 'クリア';

  @override
  String get gen_removeConfirm => '外す';

  @override
  String get gen_expand => '展開';

  @override
  String get gen_collapse => '折りたたむ';

  @override
  String get gen_copied => 'コピーしました';

  @override
  String get gen_random => 'ランダム';

  @override
  String get gen_auto => '自動';

  @override
  String get gen_pin => 'ヘッダーに固定';

  @override
  String get gen_unpin => 'ヘッダーから外す';

  @override
  String get gen_yesterday => '昨日';

  @override
  String gen_monthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get gen_params => '生成設定';

  @override
  String get gen_generating => '生成中';

  @override
  String get gen_modelsNew => '新しいモデル';

  @override
  String get gen_modelsLegacy => '旧モデル';

  @override
  String get gen_turboEnable =>
      'Turbo（Medium Effort）を有効化\n14 ステップと Euler Ancestral に固定。カスタム UC は Full 用に保持されます。';

  @override
  String get gen_turboDisable =>
      'Turbo（Medium Effort）を使用中\nクリックで V5 Full に戻り、以前の設定と UC 下書きを復元します。';

  @override
  String get gen_turboUnavailable => 'Turbo は V5 Full のみ利用できます';

  @override
  String get gen_turboFixed =>
      'Turbo は 14 ステップ・Euler Ancestral 固定です。CFG Rescale は使えません。';

  @override
  String get gen_turboNegative =>
      'Turbo はカスタム UC を使用しません。下書きは保持され、Full に戻すと復元されます。';

  @override
  String get generation_modelDesc_v5Turbo =>
      'V5 Full の Medium Effort モード。14 ステップ・Euler Ancestral 固定で、Anlas と Opus 枠の消費を抑えます。';

  @override
  String get gen_modeTip => 'クリックで Anime / Furry を切り替え';

  @override
  String gen_anlasTip(Object value) {
    return 'Anlas 残高 $value';
  }

  @override
  String get gen_positive => 'プロンプト';

  @override
  String get gen_basePrompt => 'ベースプロンプト';

  @override
  String get gen_negative => '除外';

  @override
  String get gen_finalPositive => '送信される最終プロンプト';

  @override
  String get gen_finalNegative => '送信される最終除外内容';

  @override
  String get gen_toolDock => 'ブロックライブラリパネル';

  @override
  String get gen_toolPalette => 'ブロックパレット';

  @override
  String get gen_toolTranslate => '翻訳';

  @override
  String get gen_toolsMenu => 'ツールと設定';

  @override
  String get gen_toolsPinned => 'ヘッダーのツール';

  @override
  String get gen_toolsSettings => 'プロンプト設定';

  @override
  String get gen_fullscreen => '全画面で編集';

  @override
  String get gen_autoFormat => '自動整形';

  @override
  String get gen_autoFormatSub => 'フォーカスが外れたらカンマと空白を整える';

  @override
  String get gen_highlight => '強調ハイライト';

  @override
  String get gen_highlightSub => '重みに応じて色付け';

  @override
  String get gen_sdConvert => 'SD 構文を自動変換';

  @override
  String get gen_sdConvertSub => '(tag:1.2) を貼り付けると NAI の重みに変換';

  @override
  String get gen_related => '共起タグの提案';

  @override
  String get gen_relatedSub => '一緒に使われやすいタグを提案';

  @override
  String get gen_translating => '翻訳中…';

  @override
  String get gen_translateNeedsModel => '翻訳モデル未設定。クリックして設定';

  @override
  String gen_translateWith(Object route) {
    return '翻訳（$route）';
  }

  @override
  String get gen_translateNew => '追加分を翻訳';

  @override
  String get gen_translateShowOriginal => 'すべて原文に戻す';

  @override
  String get gen_translateShowTranslated => 'すべて訳文を表示';

  @override
  String get gen_translateSettings => '翻訳モデル設定';

  @override
  String get gen_qualityPreset => '品質タグ';

  @override
  String get gen_ucPreset => '除外プリセット';

  @override
  String get gen_presetNone => 'なし';

  @override
  String get gen_transparentOn => '透明背景：オン';

  @override
  String get gen_transparentOff => '透明背景：オフ';

  @override
  String get gen_characters => 'キャラクター';

  @override
  String get gen_charactersTip => 'キャラクターごとに別のプロンプトを書けます。特徴が混ざりません。';

  @override
  String get gen_charactersEmpty => 'キャラクターがいません。右上の + で追加できます。';

  @override
  String gen_charactersFull(Object max) {
    return '最大 $max 人まで';
  }

  @override
  String get gen_addCharacter => 'キャラクターを追加';

  @override
  String gen_addAs(Object gender) {
    return '$genderを追加';
  }

  @override
  String get gen_clearCharacters => 'すべて削除';

  @override
  String get gen_clearCharactersTitle => 'すべてのキャラクターを削除しますか？';

  @override
  String gen_clearCharactersBody(Object count) {
    return '$count 人のキャラクターとプロンプトが削除されます。';
  }

  @override
  String gen_characterN(Object n) {
    return 'キャラクター $n';
  }

  @override
  String get gen_genderFemale => '女性';

  @override
  String get gen_genderMale => '男性';

  @override
  String get gen_genderOther => 'その他';

  @override
  String get gen_position => '位置';

  @override
  String get gen_positionAi => 'AI 任せ';

  @override
  String get gen_positionCustom => 'カスタム';

  @override
  String get gen_positionBoard => 'キャラクター配置';

  @override
  String get gen_positionAiTip => '位置は AI が決めます';

  @override
  String gen_positionAt(Object at) {
    return '位置 $at（クリックで調整）';
  }

  @override
  String get gen_positionUnset => '未配置（クリックで配置）';

  @override
  String get gen_positionAiHint => '位置は AI が決めています';

  @override
  String get gen_positionGridHint => 'キャラクターをマスにドラッグ。中心に吸着します';

  @override
  String get gen_positionFreeHint => 'キャラクターを好きな位置へドラッグ';

  @override
  String get gen_positionAiOverlay => '現在は AI 任せです。\nカスタムに切り替えると手動で配置できます。';

  @override
  String get gen_positionToCustom => 'カスタムに切り替え';

  @override
  String get gen_positionUnplaced => '未配置';

  @override
  String get gen_renameTip => 'ダブルクリックで名前を変更';

  @override
  String get gen_moveUp => '上へ';

  @override
  String get gen_moveDown => '下へ';

  @override
  String get gen_characterDisable => 'このキャラクターを使わない';

  @override
  String get gen_characterEnable => 'このキャラクターを使う';

  @override
  String get gen_charPositive => 'プロンプト';

  @override
  String get gen_charNegative => '除外';

  @override
  String get gen_saveAsBlock => 'ブロックとして保存';

  @override
  String get gen_refs => '参照画像';

  @override
  String get gen_img2img => 'img2img';

  @override
  String get gen_img2imgDesc => '元画像からバリエーションを生成';

  @override
  String gen_img2imgSummary(Object strength, Object noise) {
    return '強度 $strength · ノイズ $noise';
  }

  @override
  String get gen_img2imgDrop => '画像をドロップ、または';

  @override
  String get gen_upload => 'アップロード';

  @override
  String get gen_replace => '差し替え';

  @override
  String get gen_edit => '編集';

  @override
  String get gen_inpaint => 'インペイント';

  @override
  String get gen_placeOnCanvas => 'キャンバスに表示';

  @override
  String get gen_fromPreciseLibrary => '精密参照ライブラリから';

  @override
  String get gen_sketch => 'スケッチ';

  @override
  String get gen_strength => '強度';

  @override
  String get gen_strengthTip => '高いほど元画像から離れます（既定 0.7）';

  @override
  String get gen_noise => 'ノイズ';

  @override
  String get gen_noiseTip => 'ノイズでディテールを変化させます（既定 0）';

  @override
  String get gen_inpaintStrength => 'インペイント強度';

  @override
  String get gen_inpaintReady => 'マスク作成済み。塗った部分だけを再生成します。';

  @override
  String get gen_refPause => '今回は送信しない';

  @override
  String get gen_refResume => '送信を再開';

  @override
  String get gen_refPaused => '一時停止中（今回は送信しません）';

  @override
  String get gen_vibe => 'Vibe Transfer';

  @override
  String get gen_vibeDesc => '画像を変えて雰囲気を保つ';

  @override
  String get gen_vibeSkipped => '精密参照があるため今回は送信されません';

  @override
  String get gen_vibeConflict => '精密参照があるとき Vibe は送信されません。';

  @override
  String get gen_vibeDrop => '画像や .naiv4vibe をドロップ、または';

  @override
  String get gen_addVibe => 'Vibe を追加';

  @override
  String get gen_addFromFile => 'ファイルから';

  @override
  String get gen_addFromVibeLibrary => 'Vibe ライブラリから';

  @override
  String get gen_addFromPreciseLibrary => '精密参照ライブラリから';

  @override
  String gen_vibeFull(Object max) {
    return '最大 $max 個';
  }

  @override
  String get gen_saveToLibrary => 'ライブラリに保存';

  @override
  String get gen_normalize => '正規化';

  @override
  String get gen_normalizeTip => 'Vibe 強度を合計で正規化';

  @override
  String gen_vibeExtraCost(Object free, Object each, Object total) {
    return '$free 個を超えると 1 個ごとに +$each Anlas · 今回 +$total';
  }

  @override
  String get gen_recent => '最近';

  @override
  String get gen_encoded => 'エンコード済み';

  @override
  String get gen_encoding => 'エンコード中';

  @override
  String get gen_encode => 'エンコード';

  @override
  String gen_encodeTip(Object cost) {
    return 'エンコードは 1 回 $cost Anlas。以後は再利用できます';
  }

  @override
  String get gen_vibeStrength => '強度';

  @override
  String get gen_vibeInfo => '情報抽出';

  @override
  String get gen_vibeInfoReencode => '情報抽出を変更すると、Vibe の再エンコードが必要です';

  @override
  String get gen_precise => '精密参照';

  @override
  String get gen_preciseDesc => '生成をキャラや画風の参照に固定';

  @override
  String get gen_preciseDrop => 'キャラや画風の参照画像をドロップ、または';

  @override
  String get gen_preciseCharacter => 'キャラ';

  @override
  String get gen_preciseStyle => '画風';

  @override
  String get gen_preciseBoth => '両方';

  @override
  String get gen_fidelity => '忠実度';

  @override
  String gen_preciseCost(Object each, Object total) {
    return '1 枚 $each Anlas · 今回 +$total';
  }

  @override
  String get gen_preciseConflict => '精密参照があるとき Vibe は送信されません。';

  @override
  String get gen_pauseVibes => 'Vibe を一時停止';

  @override
  String get gen_savePrecise => '精密参照ライブラリに保存';

  @override
  String get gen_addPrecise => '精密参照を追加';

  @override
  String get gen_image => '画像';

  @override
  String get gen_sizeNormal => '標準';

  @override
  String get gen_sizeLarge => '大';

  @override
  String get gen_sizeWallpaper => '壁紙';

  @override
  String get gen_sizeSmall => '小';

  @override
  String get gen_sizeCustom => 'カスタム';

  @override
  String get gen_portrait => '縦';

  @override
  String get gen_landscape => '横';

  @override
  String get gen_square => '正方形';

  @override
  String get gen_width => '幅（64 単位）';

  @override
  String get gen_height => '高さ（64 単位）';

  @override
  String get gen_swapSize => '幅と高さを入れ替え';

  @override
  String get gen_count => '枚数';

  @override
  String get gen_countTip => '1 回のリクエストの枚数（1–4）';

  @override
  String get gen_repeat => '繰り返し';

  @override
  String get gen_repeatTip => '連続で送るリクエスト数';

  @override
  String gen_repeatTotal(Object times, Object total) {
    return '$times 回、計 $total 枚 · 押したまま左右にドラッグして調整';
  }

  @override
  String get gen_steps => 'ステップ';

  @override
  String get gen_guidance => 'ガイダンス';

  @override
  String get gen_guidanceTip => '高いほどプロンプトに忠実。高すぎると硬くなります（既定 5）';

  @override
  String get gen_cfgRescale => 'ガイダンス再調整';

  @override
  String get gen_cfgRescaleTip => '高ガイダンスの彩度過多を抑えます（既定 0）';

  @override
  String get gen_seed => 'シード';

  @override
  String get gen_seedPinned => 'シード · 固定';

  @override
  String get gen_seedPinTip => 'クリックでこのシードを固定';

  @override
  String get gen_seedUnpinTip => 'クリックでランダムに戻す';

  @override
  String get gen_seedRandomize => 'ランダムに戻す';

  @override
  String get gen_sampler => 'サンプラー';

  @override
  String get gen_samplerRecommended => 'おすすめ';

  @override
  String get gen_samplerOther => 'その他';

  @override
  String get gen_noiseSchedule => 'ノイズスケジュール';

  @override
  String get gen_varietyTip => '序盤のガイダンスを省き構図に変化を出します';

  @override
  String get gen_decrispTip => '高ガイダンス時のシャープすぎを軽減';

  @override
  String get gen_smeaAutoTip => 'サイズに応じて SMEA を自動で切り替え';

  @override
  String get gen_paramsTitle => '生成設定';

  @override
  String get gen_paramsOpen => 'すべての設定を表示';

  @override
  String get gen_paramsClose => '設定を閉じる';

  @override
  String get gen_stop => '生成を停止';

  @override
  String gen_cooldown(Object seconds) {
    return 'クールダウン $seconds 秒';
  }

  @override
  String get gen_insufficient => 'Anlas が足りません';

  @override
  String get gen_free => '今回は無料（Opus 枠内）';

  @override
  String get gen_emptyTitle => 'プロンプトを書いて最初の 1 枚を';

  @override
  String get gen_emptyPress => '';

  @override
  String get gen_emptyOr => 'を押すか左下の生成ボタンで開始';

  @override
  String get gen_tileFailed => 'この 1 枚は失敗しました';

  @override
  String get gen_enhance => 'エンハンス';

  @override
  String get gen_variations => 'バリエーション';

  @override
  String get gen_upscale => 'アップスケール';

  @override
  String get gen_upscaleStop => 'アップスケールを停止';

  @override
  String get gen_upscaleOptions => 'アップスケール方式';

  @override
  String get gen_setInit => 'img2img の元画像にする';

  @override
  String get gen_editImage => '画像を編集';

  @override
  String get gen_sendToTools => 'キャンバスツールへ送る';

  @override
  String get gen_display => 'キャンバス表示';

  @override
  String get gen_backdrop => '透過画像の下地';

  @override
  String get gen_backdropSub => '透過ピクセルの下にだけ表示し、画像には保存しません';

  @override
  String get gen_bdChecker => '市松（テーマ連動）';

  @override
  String get gen_bdCheckerLight => '明るい市松';

  @override
  String get gen_bdCheckerDark => '暗い市松';

  @override
  String get gen_bdNone => 'なし';

  @override
  String get gen_bdBlack => '黒';

  @override
  String get gen_bdWhite => '白';

  @override
  String get gen_bdGray => 'グレー';

  @override
  String get gen_bdRed => '赤';

  @override
  String get gen_bdGreen => '緑';

  @override
  String get gen_bdBlue => '青';

  @override
  String get gen_bdCustom => 'カスタム';

  @override
  String get gen_zoomToFill => '拡大して埋める';

  @override
  String get gen_zoomToFillSub => '小さい画像も拡大して表示';

  @override
  String get gen_useSeed => 'このシードを使う（固定）';

  @override
  String get gen_copySeed => 'シードをコピー';

  @override
  String get gen_pinImage => 'キャンバスに固定';

  @override
  String get gen_unpinImage => '固定を解除';

  @override
  String get gen_copyImage => '画像をコピー';

  @override
  String get gen_saveImage => 'ギャラリーに保存';

  @override
  String get gen_openViewer => '大きく表示';

  @override
  String get gen_retry => '再試行';

  @override
  String get gen_copyDetail => '詳細をコピー';

  @override
  String get gen_history => '履歴';

  @override
  String get gen_historyEmpty => 'まだ生成していません';

  @override
  String get gen_historyEmptySub => '生成した画像がバッチごとに並びます';

  @override
  String gen_batchCount(Object count) {
    return '$count 枚';
  }

  @override
  String gen_batchPending(Object count) {
    return '残り $count 枚';
  }

  @override
  String get gen_pinnedTip => 'キャンバスに固定した画像（クリックで移動）';

  @override
  String get gen_select => '複数選択';

  @override
  String get gen_selectDone => '選択を終了';

  @override
  String gen_selectedCount(Object count) {
    return '$count 枚選択中';
  }

  @override
  String get gen_pack => 'zip にまとめる';

  @override
  String get gen_saveSelected => '選択した画像を保存';

  @override
  String get gen_removeSelected => '履歴から外す';

  @override
  String get gen_autoSaveOn => 'ギャラリーへ自動保存：オン';

  @override
  String get gen_autoSaveOff => 'ギャラリーへ自動保存：オフ';

  @override
  String get gen_scrollLock => 'スクロールを固定（新しい画像で先頭に戻らない）';

  @override
  String get gen_scrollUnlock => 'スクロール固定を解除';

  @override
  String get gen_saveAll => 'すべてギャラリーに保存';

  @override
  String get gen_clearHistory => '履歴をクリア';

  @override
  String get gen_clearHistoryTitle => 'このセッションの履歴をクリアしますか？';

  @override
  String get gen_clearHistoryBody => 'ここから外すだけで、ギャラリーに保存済みのファイルは残ります。';

  @override
  String get gen_deleteImagesTitle => '履歴から外しますか？';

  @override
  String gen_deleteImagesBody(Object count) {
    return '$count 枚をここから外します。保存済みのファイルは残ります。';
  }

  @override
  String gen_saveBatch(Object count) {
    return 'このバッチを保存（$count 枚）';
  }

  @override
  String gen_removeBatch(Object count) {
    return 'このバッチを外す（$count 枚）';
  }

  @override
  String get gen_removeImage => '履歴から外す';

  @override
  String get gen_favorite => 'お気に入り';

  @override
  String get gen_unfavorite => 'お気に入り解除';

  @override
  String get gen_sendImg2Img => 'img2img に送る';

  @override
  String get gen_sendVibe => 'Vibe Transfer に追加';

  @override
  String get gen_sendPrecise => '精密参照に追加';

  @override
  String get gen_reveal => 'エクスプローラーで表示';

  @override
  String get gen_opUpscale => 'アップスケール済み';

  @override
  String get gen_opEnhance => 'エンハンス済み';

  @override
  String get gen_opVariation => 'バリエーション';

  @override
  String get gen_opInpaint => 'インペイント済み';

  @override
  String get gen_opImg2Img => 'img2img';

  @override
  String get tools_free => '無料';

  @override
  String get tools_localFree => 'ローカル · 無料';

  @override
  String tools_anlasN(Object count) {
    return '$count Anlas';
  }

  @override
  String get tools_cancel => 'キャンセル';

  @override
  String get tools_close => '閉じる';

  @override
  String get tools_done => '完了';

  @override
  String get tools_reset => 'リセット';

  @override
  String get tools_apply => '適用';

  @override
  String get tools_retry => '再試行';

  @override
  String get tools_optional => '任意';

  @override
  String get tools_justNow => 'たった今';

  @override
  String tools_minutesAgo(Object count) {
    return '$count 分前';
  }

  @override
  String tools_hoursAgo(Object count) {
    return '$count 時間前';
  }

  @override
  String tools_monthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String get tools_useAsInit => 'img2img のベースにする';

  @override
  String get tools_upscale => 'アップスケール';

  @override
  String get tools_enhance => 'エンハンス';

  @override
  String get tools_strength => '強度';

  @override
  String get tools_noise => 'ノイズ';

  @override
  String get tools_tipEnhance => '現在のプロンプトでこの画像を描き直して細部を足します。拡大も可能';

  @override
  String get tools_tipVariations => 'この画像の設定で似た画像を 4 枚生成します。プロンプトと設定は変わりません';

  @override
  String get tools_tipUpscale => '保存した設定でアップスケール。結果は新しい画像として表示されます';

  @override
  String get tools_tipUpscaleRunning => 'アップスケール中。クリックでキャンセル';

  @override
  String get tools_tipUpscaleSettings => 'ローカル / クラウド、方式、モデル、倍率を選ぶ';

  @override
  String get tools_tipSetInit => 'この画像を img2img に入れて次の生成のベースにします';

  @override
  String get tools_tipEdit => 'ブラシ・選択・色調整で編集し、完了後 img2img のベースを置き換えます';

  @override
  String get tools_tipInpaint => '描き直す範囲をマスクで指定。それ以外はそのまま';

  @override
  String get tools_tipDirector => '背景除去・線画・着色・表情修正などの仕上げツール';

  @override
  String get tools_upscaleRunHint => '完了した画像は履歴に追加され、他を選んでいなければ自動で選択されます';

  @override
  String get tools_enhanceSub => '現在のプロンプトで描き直して細部を足します。拡大も可能';

  @override
  String get tools_enhanceScale => '拡大';

  @override
  String get tools_enhanceLocal => 'ローカル拡大';

  @override
  String get tools_enhanceLocalRow => 'ローカル';

  @override
  String tools_enhanceOutLocal(Object size, Object factor) {
    return '$size → ローカル $factor';
  }

  @override
  String get tools_enhanceMagnitude => '強さ';

  @override
  String get tools_magLight => '弱';

  @override
  String get tools_magMedium => '中';

  @override
  String get tools_magStrong => '強';

  @override
  String tools_enhanceValues(Object strength, Object noise) {
    return '強度 $strength · ノイズ $noise';
  }

  @override
  String get tools_enhanceCustomTag => 'カスタム';

  @override
  String get tools_enhanceCustom => '強度とノイズを指定';

  @override
  String get tools_enhanceCustomHint => '強度が高いほど大きく変わり、ノイズは細部を足しますが荒れやすくなります';

  @override
  String get tools_localHint => '生成後に各画像をローカルで拡大します。追加の Anlas は不要';

  @override
  String get tools_localNotSet => 'ローカル拡大モデル未選択';

  @override
  String get tools_upscaleSettings => 'アップスケール設定';

  @override
  String tools_enhanceFooter(Object model, Object steps) {
    return '現在のプロンプト · $model · $steps ステップ';
  }

  @override
  String get tools_enhanceRun => 'エンハンス';

  @override
  String get tools_enhanceRunLocal => 'エンハンス + ローカル拡大';

  @override
  String get tools_upscaleSub => '拡大結果は新しい画像として表示され、元画像と img2img のベースは変わりません';

  @override
  String get tools_upscaleMethod => '方式';

  @override
  String get tools_upscaleModel => 'モデル';

  @override
  String get tools_upscaleManage => 'モデル管理';

  @override
  String get tools_upscaleScale => '倍率';

  @override
  String get tools_upscaleAdvanced => '詳細設定';

  @override
  String get tools_upscaleFooter => '設定は保存され、ツールバーの「アップスケール」はこの設定で実行します';

  @override
  String get tools_modelMissing => '未インストール';

  @override
  String get tools_modelDownloading => 'ダウンロード中';

  @override
  String get tools_modelNone => '未選択';

  @override
  String get tools_edit => '画像を編集';

  @override
  String get tools_editSub => '完了すると img2img のベースを置き換えます';

  @override
  String get tools_inpaint => 'インペイント';

  @override
  String get tools_inpaintSub => 'マスクした部分だけ描き直します';

  @override
  String get tools_backEsc => '戻る（Esc）';

  @override
  String get tools_panel => 'パネル';

  @override
  String get tools_undo => '元に戻す';

  @override
  String get tools_redo => 'やり直す';

  @override
  String get tools_download => 'PNG をダウンロード';

  @override
  String get tools_zoomIn => 'ズームイン';

  @override
  String get tools_zoomOut => 'ズームアウト';

  @override
  String get tools_zoomFit => 'ウィンドウに合わせる';

  @override
  String get tools_applyMask => 'マスクを適用';

  @override
  String get tools_applyMaskSub => '生成ページに戻り、自分で生成';

  @override
  String get tools_applyGenerate => '適用して生成';

  @override
  String get tools_applyGenerateSub => '生成ページに戻ってすぐ描き直し開始';

  @override
  String get tools_discardTitle => '変更を破棄しますか？';

  @override
  String get tools_discardBody => '適用していないストローク・マスク・レイヤーの変更は失われます。';

  @override
  String get tools_discard => '破棄';

  @override
  String get tools_keepEditing => '編集を続ける';

  @override
  String get tools_toolBrush => 'ブラシ';

  @override
  String get tools_toolEraser => '消しゴム';

  @override
  String get tools_toolFill => '塗りつぶし';

  @override
  String get tools_toolBlur => 'ぼかし';

  @override
  String get tools_toolStamp => 'コピースタンプ';

  @override
  String get tools_toolSelect => '矩形選択';

  @override
  String get tools_toolLasso => '投げ縄';

  @override
  String get tools_toolPicker => 'スポイト';

  @override
  String get tools_toolMaskBrush => 'マスクを描く';

  @override
  String get tools_toolMaskEraser => 'マスクを消す';

  @override
  String get tools_toolFocus => 'フォーカス範囲';

  @override
  String get tools_clearMask => 'マスクをクリア';

  @override
  String get tools_expand => '端を拡張';

  @override
  String get tools_adjust => '色調整';

  @override
  String get tools_resize => 'キャンバスサイズ';

  @override
  String get tools_size => 'サイズ';

  @override
  String get tools_opacity => '不透明度';

  @override
  String get tools_intensity => '強さ';

  @override
  String get tools_tolerance => '許容値';

  @override
  String get tools_tip => '先端';

  @override
  String get tools_tipHard => '硬';

  @override
  String get tools_tipSoft => '軟';

  @override
  String get tools_tipSquare => '角';

  @override
  String get tools_pressure => '筆圧';

  @override
  String get tools_squareBrush => '四角ブラシ';

  @override
  String get tools_hintStamp => 'Alt + クリックで取得し、別の場所に塗ります';

  @override
  String get tools_hintSelect => 'ドラッグで選択。Alt+L で新規レイヤーにコピー、Delete で消去';

  @override
  String get tools_hintPicker => 'クリックで色を取得。ブラシ中も Alt で一時的に取得できます';

  @override
  String get tools_hintMaskFill => 'クリックで似た色の範囲をマスクで塗ります';

  @override
  String get tools_focusContext => '最小コンテキスト';

  @override
  String get tools_hintFocus => '仕上げたい部分を囲むと、モデルは枠内と周囲だけを見るので小さな顔や手がきれいになります';

  @override
  String get tools_clearFocus => 'フォーカス解除';

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
    return 'キャンバスの端をドラッグしても可。$step px 単位';
  }

  @override
  String get tools_maskLook => 'マスク表示';

  @override
  String get tools_maskBorder => '輪郭線';

  @override
  String get tools_patternSolid => '単色';

  @override
  String get tools_patternLines => '斜線';

  @override
  String get tools_patternCrosshatch => 'クロスハッチ';

  @override
  String get tools_patternGrid => 'グリッド';

  @override
  String get tools_patternDots => 'ドット';

  @override
  String get tools_patternChecker => '市松';

  @override
  String get tools_patternHearts => 'ハート';

  @override
  String get tools_colorPrimary => '描画色';

  @override
  String get tools_colorSecondary => '背景色';

  @override
  String get tools_moreColors => 'その他の色…';

  @override
  String get tools_statusHint => 'スペースで移動 · ホイールでズーム · Ctrl+0 全体 · 1 実寸';

  @override
  String get tools_statusGrid => 'マスクは 8 px グリッドに揃います';

  @override
  String get tools_statusMask => 'マスク';

  @override
  String get tools_inpaintSettings => 'インペイント設定';

  @override
  String get tools_inpaintStrength => '強度';

  @override
  String get tools_inpaintStrengthHint => '低いほど元画像に近くなります';

  @override
  String get tools_mask => 'マスク';

  @override
  String tools_maskCoverage(Object count) {
    return 'の範囲 · $count か所';
  }

  @override
  String get tools_focusNone => '未設定（画像全体）';

  @override
  String tools_focusContextShort(Object value) {
    return '· コンテキスト $value';
  }

  @override
  String get tools_output => '出力';

  @override
  String get tools_expandTag => '拡張';

  @override
  String get tools_layers => 'レイヤー';

  @override
  String get tools_addLayer => 'レイヤーを追加';

  @override
  String get tools_add3dLayer => '3D レイヤーを追加';

  @override
  String get tools_layerHint => 'Alt+L で選択範囲を新規レイヤーにコピー';

  @override
  String get tools_hideLayer => 'レイヤーを隠す';

  @override
  String get tools_showLayer => 'レイヤーを表示';

  @override
  String get tools_layerUp => '上へ';

  @override
  String get tools_layerDown => '下へ';

  @override
  String get tools_layerDuplicate => '複製';

  @override
  String get tools_layerMerge => '下と結合';

  @override
  String get tools_layerDelete => 'レイヤーを削除';

  @override
  String get tools_currentLayer => '現在のレイヤー';

  @override
  String get tools_hue => '色相';

  @override
  String get tools_saturation => '彩度';

  @override
  String get tools_brightness => '明るさ';

  @override
  String get tools_canvas => 'キャンバス';

  @override
  String get tools_resizeCanvas => 'サイズ変更';

  @override
  String get tools_inpaintNote =>
      '適用すると生成ページに戻り「インペイント」に切り替わります。右上メニューの「適用して生成」ですぐ実行もできます';

  @override
  String get tools_director => 'ディレクターツール';

  @override
  String get tools_backGen => '生成';

  @override
  String get tools_dtGroupClean => 'クリーンアップ';

  @override
  String get tools_dtGroupLine => '線';

  @override
  String get tools_dtGroupColor => '着色と表情';

  @override
  String get tools_dtGroupPixel => 'ピクセル';

  @override
  String get tools_dtRemoveBg => '背景除去';

  @override
  String get tools_dtRemoveBgDesc => '人物を切り抜き、透過・背景・合成の 3 枚を出力';

  @override
  String get tools_dtDeclutter => '線の整理';

  @override
  String get tools_dtDeclutterDesc => '余分な線やノイズを取り除きます';

  @override
  String get tools_dtLineArt => '線画抽出';

  @override
  String get tools_dtLineArtDesc => 'きれいな白黒の線画を抽出';

  @override
  String get tools_dtSketch => 'スケッチ化';

  @override
  String get tools_dtSketchDesc => '鉛筆スケッチ風にします';

  @override
  String get tools_dtColorize => '着色';

  @override
  String get tools_dtColorizeDesc => '線画やスケッチに着色。プロンプト指定可';

  @override
  String get tools_dtEmotion => '表情修正';

  @override
  String get tools_dtEmotionDesc => '表情を変更。強さ調整可';

  @override
  String get tools_dtPixelSnap => 'ピクセル整列';

  @override
  String get tools_dtPixelSnapDesc => 'ピクセルグリッドに揃えて減色。ローカル処理';

  @override
  String get tools_dtOpusNote => 'Opus なら 1 MP 以内は無料。背景除去は常に Anlas がかかります';

  @override
  String get tools_input => '入力';

  @override
  String get tools_compareSide => '並べる';

  @override
  String get tools_compareWipe => 'スライド比較';

  @override
  String get tools_compareResult => '結果のみ';

  @override
  String get tools_fit => '全体';

  @override
  String get tools_actualSize => '実寸 100%';

  @override
  String get tools_original => '元画像';

  @override
  String get tools_emptyRun => '「実行」で開始';

  @override
  String get tools_emptyEmotion => '表情を選んで「実行」';

  @override
  String get tools_emptyBody => '結果はここに元画像と並べて表示されます';

  @override
  String tools_running(Object tool) {
    return '$toolを実行中…';
  }

  @override
  String get tools_runningBody => '通常は数秒です。結果は生成ページの履歴にも入ります';

  @override
  String get tools_runFailed => '実行に失敗しました';

  @override
  String get tools_noInput => 'まず画像を追加してください';

  @override
  String get tools_noInputBody => 'ドラッグ、Ctrl+V で貼り付け、または生成履歴から選択';

  @override
  String get tools_noResult => 'まだ結果はありません';

  @override
  String get tools_continue => 'さらに処理';

  @override
  String get tools_copy => 'コピー';

  @override
  String get tools_saveGallery => 'ギャラリーに保存';

  @override
  String get tools_queue => '入力キュー';

  @override
  String tools_queueCount(Object count) {
    return '$count 枚';
  }

  @override
  String get tools_queueHint => '＋：ファイル読込 / 生成履歴から選択。ドラッグや Ctrl+V も可';

  @override
  String get tools_importFiles => 'ファイルを読み込む';

  @override
  String get tools_fromHistory => '生成履歴から選ぶ';

  @override
  String get tools_paste => '貼り付け';

  @override
  String get tools_removeInput => 'キューから外す';

  @override
  String get tools_dtOptions => 'オプション';

  @override
  String get tools_dtNoOptionsBg =>
      '背景除去に調整項目はありません。透過・背景・合成の 3 枚が出力され、結果の下で切り替えられます。';

  @override
  String get tools_dtNoOptionsDeclutter => '線の整理に調整項目はありません。線画が欲しいときは「線画抽出」を。';

  @override
  String get tools_dtNoOptionsLineArt =>
      '線画抽出に調整項目はありません。着色するなら結果を「さらに処理」して「着色」へ。';

  @override
  String get tools_dtNoOptionsSketch =>
      'スケッチ化に調整項目はありません。きれいな線なら「線画抽出」、着色なら「さらに処理」して「着色」へ。';

  @override
  String get tools_dtEmotionLabel => '表情';

  @override
  String tools_dtEmotionMore(Object count) {
    return 'さらに $count 個';
  }

  @override
  String get tools_dtEmotionLess => '閉じる';

  @override
  String get tools_dtStrength => '強さ';

  @override
  String get tools_defry0 => '標準';

  @override
  String get tools_defry1 => 'やや弱';

  @override
  String get tools_defry2 => '弱';

  @override
  String get tools_defry3 => 'より弱';

  @override
  String get tools_defry4 => 'かなり弱';

  @override
  String get tools_defry5 => '最弱';

  @override
  String get tools_dtEmotionStrengthHint => '弱いほど元の表情に近くなります';

  @override
  String get tools_dtColorizeStrengthHint => '弱いほど元の線に近くなります';

  @override
  String get tools_dtPrompt => '追加プロンプト';

  @override
  String get tools_dtPromptHint => '英語タグをカンマ区切りで';

  @override
  String get tools_dtEmotionPromptHint => '表情を選ぶとよく使うタグが入ります。編集できます';

  @override
  String get tools_dtColorizePromptHint => '配色を記述（例：blue dress, silver hair）';

  @override
  String get tools_dtPalette => 'パレット';

  @override
  String get tools_dtPaletteOff => 'オフ';

  @override
  String get tools_dtPaletteAuto => '自動';

  @override
  String get tools_dtPaletteCustom => 'カスタム';

  @override
  String get tools_dtColors => '色数';

  @override
  String get tools_dtAvoidRefine => '細分化しすぎない';

  @override
  String get tools_dtAvoidRefineHint => '細かいグリッドの効果が小さいときは粗いグリッドのまま';

  @override
  String get tools_dtPixelUpscale => '元のサイズに拡大';

  @override
  String get tools_dtPixelUpscaleHint => 'オフでは 1 マス 1 ピクセルの小さな画像を出力';

  @override
  String tools_runTool(Object tool) {
    return '$toolを実行';
  }

  @override
  String get tools_runHint => '実行 · 現在の入力を処理';

  @override
  String get tools_runNeedInput => '下に入力を追加してください';

  @override
  String get tools_results => '結果';

  @override
  String get tools_resultsEmpty => '実行した結果がここに並びます';

  @override
  String get tools_resultsHint => '結果をクリックで再表示。生成履歴にも入ります。残したいものはギャラリーへ';

  @override
  String get tools_reuse => '設定を使う';

  @override
  String get tools_emoNeutral => '平常';

  @override
  String get tools_emoHappy => '嬉しい';

  @override
  String get tools_emoSad => '悲しい';

  @override
  String get tools_emoAngry => '怒り';

  @override
  String get tools_emoScared => '怖い';

  @override
  String get tools_emoSurprised => '驚き';

  @override
  String get tools_emoTired => '疲れ';

  @override
  String get tools_emoExcited => 'ワクワク';

  @override
  String get tools_emoNervous => '緊張';

  @override
  String get tools_emoThinking => '考え中';

  @override
  String get tools_emoConfused => '困惑';

  @override
  String get tools_emoShy => '照れ';

  @override
  String get tools_emoDisgusted => '嫌悪';

  @override
  String get tools_emoSmug => 'ドヤ顔';

  @override
  String get tools_emoBored => '退屈';

  @override
  String get tools_emoLaughing => '大笑い';

  @override
  String get tools_emoIrritated => 'イライラ';

  @override
  String get tools_emoAroused => '興奮';

  @override
  String get tools_emoEmbarrassed => '恥ずかしい';

  @override
  String get tools_emoWorried => '心配';

  @override
  String get tools_emoLove => '恋';

  @override
  String get tools_emoDetermined => '決意';

  @override
  String get tools_emoHurt => '傷心';

  @override
  String get tools_emoPlayful => 'いたずら';

  @override
  String get auth_logoutConfirm => '現在のアカウントからログアウトしますか？';

  @override
  String get naiAgent_title => 'NAI Agent';

  @override
  String get naiAgent_permissionTitle => 'ツールの承認が必要です';

  @override
  String get naiAgent_permissionOnce => '今回のみ許可';

  @override
  String get naiAgent_permissionSession => 'このセッションで同一の呼び出しを許可';

  @override
  String get naiAgent_permissionDeny => '拒否';

  @override
  String get naiAgent_defaultWorkspace => 'ワークスペース 1';

  @override
  String get naiAgent_newChat => '新しいチャット';

  @override
  String get naiAgent_settings => 'Agent 設定';

  @override
  String get naiAgent_chooseModel => 'モデルを選択';

  @override
  String get naiAgent_interrupted => '前回の処理は中断され、自動再送はされません。';

  @override
  String get naiAgent_systemPrompt => 'システムプロンプト';

  @override
  String get naiAgent_promptHelp =>
      'カスタム内容は既定プロンプトを置き換えます。ツール一覧はアプリが追加し、以降のリクエストに適用されます。';

  @override
  String get naiAgent_restoreDefault => '既定に戻す';

  @override
  String get naiAgent_showEffective => '有効なプロンプトを表示';

  @override
  String get naiAgent_useGlobal => '全体のプロンプトを使用';

  @override
  String get naiAgent_save => '保存';

  @override
  String get naiAgent_runLimit => '処理ごとのリクエスト上限';

  @override
  String get naiAgent_enterSends => 'Enter で送信、Shift+Enter で改行';

  @override
  String get naiAgent_dataFolder => 'ワークスペース保存先';

  @override
  String get naiAgent_openFolder => 'フォルダーを開く';

  @override
  String get naiAgent_toolsManuals => 'ツールと Skill';

  @override
  String get naiAgent_toolsHint =>
      '状態・画像・プロンプト・ファイルを必要に応じて取得します。Studio 操作の詳しい使い方は nai-studio・nai-prompt などの Skill にあり、必要なときだけ読み込みます。';

  @override
  String get naiAgent_unknownCost => '実際の料金は提供元によります';

  @override
  String get naiAgent_error => '操作に失敗しました。モデル設定やファイルを確認してください。';

  @override
  String get naiAgent_visionCurrentProvider => '現在のプロバイダー';

  @override
  String naiAgent_visionModelUnsupported(String providerName) {
    return 'プロバイダー $providerName の選択中モデルは、画像入力への対応が確認されていません。「設定 → モデルとAPI → $providerName → モデル → 能力 → 画像入力」で対応を確認するか、画像対応モデルに切り替えてください。';
  }

  @override
  String naiAgent_visionAttachmentsSkipped(int count, String reason) {
    return '画像添付 $count 件はモデルに送信されませんでした。テキストは通常どおり送信されます。$reason';
  }

  @override
  String get naiAgent_inputChanged => '準備中に入力が変わりました。現在の下書きを送信してください。';

  @override
  String get naiAgent_imageLimit => '画像形式が無効、またはアップロード上限を超えています。';

  @override
  String get naiAgent_composerNotEmpty => '現在の入力を保存または送信してから戻してください。';

  @override
  String get naiAgent_runtimeMissing => 'Agent 実行環境がありません。完全な更新パッケージを使用してください。';

  @override
  String get naiAgent_usage => 'モデル使用量';

  @override
  String get naiAgent_globalScope => '全体の既定値';

  @override
  String get naiAgent_workspaceScope => '現在のワークスペース';

  @override
  String naiAgent_generationLocalEnhance(Object model, Object scale) {
    return '生成後にローカルで拡大：$model ×$scale';
  }

  @override
  String naiAgent_galleryDeleteEmptyFolderConfirm(String path) {
    return 'この空のフォルダーとギャラリー分類を削除しますか？他のフォルダー内の画像は保持されます。\n$path';
  }

  @override
  String naiAgent_galleryDeleteEmptyFoldersConfirm(int count, String paths) {
    return 'これら $count 個の空のフォルダーとギャラリー分類を削除しますか？他のフォルダー内の画像は保持されます。\n$paths';
  }

  @override
  String naiAgent_galleryMoreItems(int count) {
    return '…ほか $count 件';
  }

  @override
  String get naiAgent_extensions => '拡張機能';

  @override
  String get naiAgent_interactionExtension => 'Studio 連携';

  @override
  String get naiAgent_extensionRequired => '内蔵 · 必須';

  @override
  String get naiAgent_interactionExtensionHint =>
      '現在の Studio 状態を必要に応じて読み取り、質問カードで回答を収集します。';

  @override
  String get naiAgent_extensionAddFile => '拡張ファイルを追加';

  @override
  String get naiAgent_extensionAddFolder => '拡張フォルダーを追加';

  @override
  String get naiAgent_extensionsHint =>
      '拡張機能はワークスペースごとに読み込まれます。変更は現在のタスク終了後、次の送信時に適用されます。外部拡張はローカルコードを実行するため、信頼できる提供元を選んでください。';

  @override
  String get naiAgent_extensionError => '拡張機能の実行に失敗しました';

  @override
  String get naiAgent_extensionCompatibility =>
      'ローカルの Pi 拡張・パッケージフォルダー、ツール、コマンド、標準ダイアログに対応。ターミナル専用のカスタム UI はデスクトップに表示されません。';

  @override
  String get naiAgent_instructions => '指示';

  @override
  String get naiAgent_globalInstructions => '共通指示';

  @override
  String get naiAgent_globalInstructionsHelp =>
      'すべてのワークスペースで使用します。言語、文体、作業の好みなどを記入できます。空欄にするとこの部分を無効にします。';

  @override
  String get naiAgent_systemPromptPrefix => 'システムプロンプトの前置き';

  @override
  String get naiAgent_systemPromptPrefixHelp =>
      'NAI Agent の基本プロンプトの前に挿入します。基本プロンプトとツールマップは保持します。空欄にするとこの部分を無効にします。';

  @override
  String get naiAgent_instructionOrder =>
      '適用順：前置き → 基本プロンプト → 共通指示 → ワークスペースのルール。以後のリクエストに適用します。';

  @override
  String get naiAgent_saveInstructions => '指示を保存';

  @override
  String get naiAgent_mcpBuiltin => 'NAI Studio · 内蔵ツール';

  @override
  String get naiAgent_mcpBuiltinHint =>
      'プロンプト、ブロック、百科、画像、履歴、参照、生成、設定ツール。既定では必要時に検索します。バックアップ、バージョン確認、ユーザー確認は引き続き有効です。';

  @override
  String get naiAgent_mcpAdd => 'MCP サーバーを追加';

  @override
  String get naiAgent_mcpName => 'サーバー名';

  @override
  String get naiAgent_mcpConfig => 'サーバー設定（JSON）';

  @override
  String get naiAgent_mcpConfigHint =>
      'stdio と Streamable HTTP に対応。サーバー設定オブジェクトを貼り付けてください。command は実行ファイル、args は配列です。env、cwd、url、headers、oauth、toolExposure も使用できます。設定は暗号化して保存されます。';

  @override
  String get naiAgent_mcpStatus => '接続状態を確認';

  @override
  String get naiAgent_mcpReconnect => '再接続';

  @override
  String get naiAgent_mcpLogin => 'ログイン';

  @override
  String get naiAgent_mcpLogout => 'ログアウト';

  @override
  String get naiAgent_mcpHint =>
      '既定では CodeMode で必要時に検索します。codemode：サンドボックスから呼び出す。deferred：検索後に直接呼び出す。direct：常時公開。hidden：非公開。変更は次の待機中の呼び出しに反映されます。接続確認はチャットモデルを呼び出しません。';

  @override
  String get promptBlockLibrary_title => 'プロンプトブロック';

  @override
  String get gen_oldImageLabel => 'OLD';

  @override
  String get gen_compareOriginal => '押している間、元画像とインペイント範囲を比較';

  @override
  String get naiAgent_imageTooLarge => '画像が64 MiBまたは6400万画素を超えています。';

  @override
  String get naiAgent_linkOnlyImage =>
      'このソースにはリンクしかありません。画像ファイルを保存してここにドラッグしてください。';

  @override
  String get naiAgent_invalidImage =>
      '画像を読み込めません。PNG、JPEG、WebP、GIF、BMPファイルを使用してください。';

  @override
  String naiAgent_importResult(int added, int failed) {
    return '画像を$added枚追加、$failed枚失敗しました。';
  }

  @override
  String get channel_themeCircuit => '回路';

  @override
  String get channel_themeStars => '星図';

  @override
  String get channel_themeHerb => '植物標本';

  @override
  String get channel_themeArcade => '回廊';

  @override
  String get channel_themeAbyss => '深海';

  @override
  String get channel_themeWave => '青海波';

  @override
  String get channel_descCircuit =>
      '両側を 2 本ずつバスが下り、分岐・パッド・チップが並びます。待機中は光がバスを流れます';

  @override
  String get channel_descStars => '星、星座線、目盛りリング、赤緯スケール。待機中は明るい星がかすかに瞬きます';

  @override
  String get channel_descHerb => '墨線の標本が両側から伸び、葉・花・テープ・番号ラベル付き。待機中は風に揺れます';

  @override
  String get channel_descArcade => '大聖堂の平面図。画像は身廊を進み、両側に柱・リブヴォールト・窓・通り芯・寸法線';

  @override
  String get channel_descAbyss => '下るほど深く（古く）なります。深度計、等深線、昇る泡、降るマリンスノー';

  @override
  String get channel_descWave => '和柄の波が両側に集まり、朱の日輪と霞を添えます。待機中は光が波を渡ります';

  @override
  String get channel_themeCaliber => 'ムーブメント';

  @override
  String get channel_themeStrata => '地層';

  @override
  String get channel_themeMetro => '地下鉄';

  @override
  String get channel_themeScore => '楽譜';

  @override
  String get channel_themeLuna => '月相';

  @override
  String get channel_descCaliber =>
      '受け板、コート・ド・ジュネーブ、輪列。スクロールで歯車が実際の歯数比で噛み合い回ります。各区間のテンプは待機中に時を刻みます';

  @override
  String get channel_descStrata =>
      '下るほど古くなります。地質年代柱、地層、その時代の化石。ドリルが視点と一緒に掘り進みます';

  @override
  String get channel_descMetro =>
      '両側に路線図。45° の曲がり、乗換駅、駅名。列車が視点の横を走り、最寄り駅が点灯します';

  @override
  String get channel_descScore =>
      '縦書きの五線譜が下へ続き、再生線が画面中央で通過した音符を光らせます。各区間のレコードはスクロールで回ります';

  @override
  String get channel_descLuna =>
      '1 日 1 行の月齢カレンダーと潮汐曲線。大きな月が視点を追い、スクロールで満ち欠けします';

  @override
  String get channel_title => 'ビジュアルチャンネル';

  @override
  String get channel_subtitle => 'スクロールすると両側に現れる装飾。画像の外側だけに描かれます';

  @override
  String get channel_paused => '生成中 · アニメ一時停止';

  @override
  String get channel_modeOff => 'オフ';

  @override
  String get channel_modeFixed => '固定';

  @override
  String get channel_modeRandom => '毎回ランダム';

  @override
  String get channel_session => '今回';

  @override
  String get channel_reroll => '入れ替え';

  @override
  String get channel_offNote => 'オフにすると今のピクセル模様のままです';

  @override
  String get channel_minTwo => 'ランダムには 2 つ以上のテーマが必要です';

  @override
  String get channel_level => '濃さ';

  @override
  String get channel_levelSoft => '淡';

  @override
  String get channel_levelStandard => '標準';

  @override
  String get channel_levelStrong => '濃';

  @override
  String get channel_ruler => '時刻目盛り';

  @override
  String get channel_rulerSub => 'バッチ時刻、日付の区切り、右端のスクラバー';

  @override
  String get channel_motion => 'アイドル時の動き';

  @override
  String get channel_motionSub => 'ごく軽い動き。生成中は自動で止まります';

  @override
  String get channel_toastTitle => '今回のチャンネル';

  @override
  String channel_batch(String time, int count) {
    return '$time · $count 枚';
  }

  @override
  String channel_batchNewest(String time, int count) {
    return '$time · $count 枚 · 最新';
  }

  @override
  String channel_batchPending(int count) {
    return '生成中 · $count 枚';
  }

  @override
  String channel_dayToday(String date) {
    return '今日 · $date';
  }

  @override
  String channel_dayYesterday(String date) {
    return '昨日 · $date';
  }

  @override
  String channel_monthDayWeek(int month, int day, String weekday) {
    return '$month月$day日（$weekday）';
  }

  @override
  String get channel_weekday1 => '月';

  @override
  String get channel_weekday2 => '火';

  @override
  String get channel_weekday3 => '水';

  @override
  String get channel_weekday4 => '木';

  @override
  String get channel_weekday5 => '金';

  @override
  String get channel_weekday6 => '土';

  @override
  String get channel_weekday7 => '日';

  @override
  String channel_scrubWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get rag_title => 'RAG ベクトルシステム';

  @override
  String get rag_description => 'ローカル検索、モデル、文脈に沿ったタグ候補を管理';

  @override
  String get rag_enabled => 'RAG を有効にする';

  @override
  String get rag_enabledHint => 'ローカル意味検索を有効化。初回の索引作成は範囲を確認して開始します。';

  @override
  String get rag_status => '共通ベクトルプール';

  @override
  String get rag_off => '無効';

  @override
  String get rag_loading => 'ローカルモデルを準備中';

  @override
  String get rag_empty => 'モデル接続済み・索引未作成';

  @override
  String get rag_ready => '意味検索の準備完了';

  @override
  String get rag_partial => '一部利用可能・未索引の内容は通常検索';

  @override
  String get rag_building => '索引を作成中';

  @override
  String get rag_paused => '索引作成を一時停止・既存索引は検索可能';

  @override
  String get rag_unavailable => 'RAG 利用不可・通常検索は利用可能';

  @override
  String get rag_operationFailed => '操作に失敗しました。モデルの場所と専用環境を確認してください。';

  @override
  String rag_indexCounts(int indexed, int total) {
    return '索引済み $indexed / $total 件';
  }

  @override
  String rag_storage(String size) {
    return '索引容量：$size MiB';
  }

  @override
  String get rag_refresh => '状態を更新';

  @override
  String get rag_embeddingPath => 'EmbeddingGemma 2 のモデルフォルダー';

  @override
  String get rag_rerankerPath => 'Qwen3-Reranker-0.6B のモデルフォルダー';

  @override
  String get rag_notConfigured => '未設定';

  @override
  String get rag_choose => '選択';

  @override
  String get rag_modelMode => 'モデルの機能';

  @override
  String get rag_modelModeHint =>
      'Gemmaはテキストと画像に使用し、音声は無効です。Qwenはテキストの再ランキングに使用します。';

  @override
  String get rag_discover => 'ローカルモデルを検出';

  @override
  String get rag_modelsMissing => 'モデルが見つかりません。保存済みモデルのフォルダーを選択してください。';

  @override
  String get rag_pythonPath => '専用 Python 実行環境';

  @override
  String get rag_runtime => '推論実行環境';

  @override
  String get rag_runtimeHint => '専用環境を使用します。既存の拡大コンポーネントは変更せず、モデルは別途指定します。';

  @override
  String get rag_installRuntime => '専用環境をインストール';

  @override
  String get rag_installHint =>
      'Python と推論依存関係を取得します。CUDA 版は数 GB と対応 NVIDIA GPU が必要です。CPU 版は小さく、モデルは別途用意します。';

  @override
  String get rag_installing => '実行環境をインストール中';

  @override
  String get rag_device => '実行デバイス';

  @override
  String get rag_auto => '自動選択';

  @override
  String get rag_tagsEnabled => '文脈に沿ったタグ候補';

  @override
  String get rag_tagsHint => '意味・共起・再順位付けを組み合わせ、入力欄・キャラクター・正負を分離します。';

  @override
  String get rag_context => '候補の文脈範囲';

  @override
  String get rag_contextHint => '両モードともタグ単位で最大 120 Gemma トークン。全文は重複除外のみに使用。';

  @override
  String get rag_contextBefore => 'カーソル前 · 120 tokens';

  @override
  String get rag_contextAround => 'カーソル前後 · 120 tokens';

  @override
  String get rag_buildIndex => '確認して索引を作成';

  @override
  String rag_plan(int total) {
    return '現在の $total 件のタグ、別名、既存のローカル解説を索引化します。初回は時間がかかりますが一時停止・部分利用が可能です。';
  }

  @override
  String get rag_start => '作成を開始';

  @override
  String get rag_pause => '作成を一時停止';

  @override
  String get rag_resume => '作成を再開';

  @override
  String get rag_rebuild => '索引を再作成';

  @override
  String get rag_clear => '索引を削除';

  @override
  String get rag_clearHint =>
      '元のコンテンツとモデルを保持して、この派生インデックスのみを削除します。再構築後に利用できます。';

  @override
  String get rag_futureSources =>
      'タグ候補、Wiki、プロンプトブロック、ギャラリーのマルチモーダル検索に対応しました。ワークスペースと Agent の検索は今後追加します。';

  @override
  String get rag_badgeHint => 'ローカルの意味検索が利用できます';

  @override
  String get rag_wikiEnabled => 'Wiki の意味検索';

  @override
  String get rag_wikiHint =>
      'ローカル記事の本文を索引化します。名前の完全一致を優先し、意味検索で補います。初回は範囲を確認して開始します。';

  @override
  String get rag_blocksEnabled => 'プロンプトブロックの意味検索';

  @override
  String get rag_blocksHint =>
      '保存済みで未アーカイブのブロックの題名、タグ、正負の本文のみが対象です。画像や未保存の下書きは含みません。';

  @override
  String rag_textPlan(int documents, int total) {
    return '保存済み資料 $documents 件を $total 個の文章に分割して索引化します。初回は手動で開始し、以後は差分更新します。一時停止でき、処理済み部分を検索できます。';
  }

  @override
  String rag_textCounts(int indexed, int total) {
    return '索引済みの文章 $indexed / $total 個';
  }

  @override
  String get rag_galleryEnabled => 'ギャラリーのマルチモーダル検索';

  @override
  String get rag_galleryHint =>
      '登録済みフォルダーの画像内容と、既存の NAI パラメーターを別々に索引化します。原画像を変更せず、他のソフトのメタデータは解析しません。';

  @override
  String rag_galleryPlan(int images, int parameters) {
    return '未削除画像 $images 枚と NAI パラメーター $parameters 断片を索引化します。初回は手動で開始し、以降は差分更新します。画像とテキストの索引は別々に保存され、一時停止できます。';
  }

  @override
  String rag_galleryCounts(
    int indexed,
    int images,
    int parameters,
    int skipped,
  ) {
    return '画像 $indexed / $images 枚・NAI $parameters 断片・スキップ $skipped 枚';
  }

  @override
  String get rag_galleryMixed => '組み合わせて検索';

  @override
  String get rag_galleryVisual => '画像内容のみ';

  @override
  String get rag_galleryParameters => 'NAI パラメーターのみ';

  @override
  String get rag_galleryChooseImage => '画像を選んで類似検索';

  @override
  String get rag_galleryClearImage => '検索画像をクリア';

  @override
  String get rag_gallerySearchOptions => 'ギャラリー RAG 検索設定';

  @override
  String get rag_downloadModel => 'モデルをダウンロード';

  @override
  String get rag_modelDownloading => 'モデルをダウンロード中';

  @override
  String get rag_modelVerifying => 'モデルを検証中';

  @override
  String rag_downloadProgress(String done, String total) {
    return '$done / $total MB';
  }

  @override
  String get rag_poolHint => '有効なソースは1つのベクトルプールを共有します。新しい資料や保存した翻訳は差分更新されます。';

  @override
  String get rag_runtimeReady => '実行環境の準備完了';

  @override
  String get rag_runtimeCheck => '実行環境を確認';

  @override
  String get rag_runtimeExisting => '既存の実行環境を確認中';

  @override
  String get rag_runtimeDownload => 'セットアップツールをダウンロード中';

  @override
  String get rag_runtimeCreate => 'Python環境を準備中';

  @override
  String get rag_runtimeCuda => 'CUDA推論パッケージをインストール中';

  @override
  String get rag_runtimePackages => '推論用の依存パッケージをインストール中';

  @override
  String get rag_runtimeVerify => '実行環境の互換性を検証中';

  @override
  String rag_runtimeElapsed(int seconds) {
    return 'このステップの経過時間：$seconds秒';
  }

  @override
  String get rag_useRuntime => '既存の環境を使用';

  @override
  String get set_title => '設定';

  @override
  String get set_search => '設定を検索';

  @override
  String get set_searchResults => '検索結果';

  @override
  String set_searchCount(Object count) {
    return '$count 件';
  }

  @override
  String get set_searchHint => '結果の中で直接変更できます。矢印で設定の場所へ移動します。';

  @override
  String get set_searchKeys => '選択';

  @override
  String get set_searchJump => '移動';

  @override
  String set_searchEmpty(Object query) {
    return '「$query」は見つかりません';
  }

  @override
  String get set_searchEmptyHint => '「プロキシ」「保存」「ショートカット」やパスで試してください';

  @override
  String get set_goTo => '設定へ移動';

  @override
  String get set_hasUpdate => '更新あり';

  @override
  String get set_groupPersonal => '個人';

  @override
  String get set_groupCreate => '制作';

  @override
  String get set_groupIntelligence => 'インテリジェンス';

  @override
  String get set_groupConnect => '接続';

  @override
  String get set_groupSystem => 'システム';

  @override
  String get set_pageOverview => '概要';

  @override
  String get set_pageAccount => 'アカウント';

  @override
  String get set_pageAppearance => '外観';

  @override
  String get set_pageCanvas => 'キャンバスと閲覧';

  @override
  String get set_pageShortcuts => 'ショートカット';

  @override
  String get set_pageGeneration => '生成と Anlas';

  @override
  String get set_pageStorage => 'ストレージとギャラリー';

  @override
  String get set_pageDictionaries => '辞書とキャッシュ';

  @override
  String get set_pageModels => 'モデルと API';

  @override
  String get set_pageAgent => 'NAI Agent';

  @override
  String get set_pageRag => 'セマンティック検索';

  @override
  String get set_pageUpscale => 'ローカル拡大';

  @override
  String get set_pageBridges => 'ブリッジと連携';

  @override
  String get set_pageNetwork => 'ネットワークとプロキシ';

  @override
  String get set_pagePrivacy => 'プライバシーと保護';

  @override
  String get set_pageBackup => 'バックアップとリセット';

  @override
  String get set_pageAbout => 'について';

  @override
  String get set_resetDefault => '既定に戻す';

  @override
  String get set_resetPage => 'このページを既定に戻す';

  @override
  String get set_needsRestart => '要再起動';

  @override
  String get set_defaultTag => '既定';

  @override
  String get set_readOnly => '読み取り専用';

  @override
  String get set_cancel => 'キャンセル';

  @override
  String get set_save => '保存';

  @override
  String get set_discard => '破棄';

  @override
  String get set_later => '後で';

  @override
  String get set_undo => '元に戻す';

  @override
  String get set_open => '開く';

  @override
  String get set_choose => '選択';

  @override
  String get set_change => '変更';

  @override
  String get set_clear => '消去';

  @override
  String get set_delete => '削除';

  @override
  String get set_copy => 'コピー';

  @override
  String get set_more => 'その他';

  @override
  String get set_refresh => '更新';

  @override
  String get set_retry => '再試行';

  @override
  String get set_test => '接続テスト';

  @override
  String get set_testing => '確認中…';

  @override
  String get set_importIt => 'インポート';

  @override
  String get set_exportIt => 'エクスポート';

  @override
  String get set_install => 'インストール';

  @override
  String get set_download => 'ダウンロード';

  @override
  String get set_resume => '再開';

  @override
  String get set_pause => '一時停止';

  @override
  String get set_rebuild => '再構築';

  @override
  String get set_login => 'ログイン';

  @override
  String get set_adjust => '調整';

  @override
  String get set_collapse => '折りたたむ';

  @override
  String get set_notSet => '未設定';

  @override
  String get set_defaultLocation => '既定の場所';

  @override
  String get set_builtinSound => '内蔵サウンド';

  @override
  String get set_justNow => 'たった今';

  @override
  String set_minutesAgo(Object n) {
    return '$n 分前';
  }

  @override
  String set_todayAt(Object time) {
    return '今日 $time';
  }

  @override
  String get set_yesterday => '昨日';

  @override
  String set_secondsAgo(Object n) {
    return '$n 秒前';
  }

  @override
  String set_savedChange(Object title, Object from, Object to) {
    return '保存 · $title $from → $to';
  }

  @override
  String get set_restartBanner => '保存しました。Studio の再起動後に反映されます。実行中の生成には影響しません。';

  @override
  String get set_restartNow => '今すぐ再起動';

  @override
  String get set_unsavedInstructions => '指示に未保存の変更があります';

  @override
  String get set_leaveTitle => '未保存の変更を破棄しますか？';

  @override
  String get set_leaveBody => 'Agent の指示は保存されていません。移動すると変更は失われます。';

  @override
  String set_resetPageTitle(Object page) {
    return '「$page」を既定に戻しますか？';
  }

  @override
  String set_resetPageBody(Object count) {
    return 'このページで変更した $count 項目が既定に戻ります。概要から元に戻せます。';
  }

  @override
  String get set_ovDesc => 'アカウント、ストレージ、接続、AI サービスの状態をまとめています。対応が必要な項目が先頭です。';

  @override
  String get set_ovSwitchAccount => 'アカウント切替';

  @override
  String get set_ovTodayUsed => '今日の使用';

  @override
  String set_ovMonthly(Object n) {
    return '月間付与 $n';
  }

  @override
  String set_ovWarnAt(Object n) {
    return '高コスト警告 ≥ $n Anlas';
  }

  @override
  String get set_ovWarnOff => '高コスト警告オフ';

  @override
  String set_ovRenews(Object date) {
    return '更新日 $date';
  }

  @override
  String get set_ovSignedOut => '未ログイン';

  @override
  String get set_ovAttention => '要対応';

  @override
  String get set_ovAllClear => 'すべて正常';

  @override
  String set_attUpdate(Object version) {
    return '新しいバージョン $version';
  }

  @override
  String set_attRagPaused(Object source) {
    return '$sourceのインデックスが一時停止中';
  }

  @override
  String set_attRagPausedSub(Object done, Object total) {
    return '$done / $total、一部は検索可能';
  }

  @override
  String set_attBridgeDown(Object name) {
    return '$name が応答しません';
  }

  @override
  String set_attCheckedAt(Object detail, Object when) {
    return '$detail · $whenに確認';
  }

  @override
  String set_attCredential(Object name) {
    return '「$name」の認証情報が期限切れ';
  }

  @override
  String get set_attCredentialSub => '更新するとこのアカウントに切り替えられます';

  @override
  String set_attDiskLow(Object disk) {
    return '$disk の空き容量不足';
  }

  @override
  String set_attDiskLowSub(Object size) {
    return '残り $size、自動保存が失敗する可能性';
  }

  @override
  String set_attProvider(Object name) {
    return '$name に接続できません';
  }

  @override
  String get set_attProviderSub => '翻訳は別のプロバイダーに切り替わります';

  @override
  String get set_attView => '表示';

  @override
  String get set_attGo => '確認';

  @override
  String get set_attUpdateCred => '更新';

  @override
  String get set_tileStorage => 'ストレージ';

  @override
  String set_tileImages(Object n) {
    return '$n 枚';
  }

  @override
  String set_tileSaveTo(Object path) {
    return '保存先 $path';
  }

  @override
  String get set_tileConnect => '接続';

  @override
  String set_tileOnline(Object n) {
    return '$n 件オンライン';
  }

  @override
  String get set_tileKrita => 'Krita 接続済み';

  @override
  String get set_tileKritaOff => 'Krita 未接続';

  @override
  String set_tileAgents(Object n) {
    return '外部 Agent $n 件';
  }

  @override
  String get set_tileComfyDown => 'ComfyUI 応答なし';

  @override
  String get set_tileComfyOk => 'ComfyUI 正常';

  @override
  String get set_tileComfyOff => 'ComfyUI 無効';

  @override
  String get set_tileModels => 'モデルと API';

  @override
  String set_tileTranslateVia(Object ms) {
    return 'プロンプト翻訳 · $ms';
  }

  @override
  String set_tileAgentModel(Object model) {
    return 'Agent · $model';
  }

  @override
  String set_tileProviders(Object p, Object m) {
    return '$p プロバイダー · $m モデル';
  }

  @override
  String get set_tileNoModel => '未設定';

  @override
  String get set_tileRag => 'セマンティック検索';

  @override
  String get set_tileReady => '準備完了';

  @override
  String set_tileRagDone(Object names) {
    return '$names 完了';
  }

  @override
  String set_tileRagPaused(Object name, Object pct) {
    return '$name $pct · 一時停止';
  }

  @override
  String set_tileRagBuilding(Object name, Object pct) {
    return '$name $pct · 構築中';
  }

  @override
  String set_tileRagEmpty(Object name) {
    return '$name は未構築';
  }

  @override
  String set_tileRagError(Object name) {
    return '$name の構築に失敗';
  }

  @override
  String get set_tileUpscale => 'ローカル拡大';

  @override
  String set_tileUpscaleModels(Object n) {
    return '$n モデル利用可';
  }

  @override
  String set_tileDefaultIs(Object name) {
    return '$name（既定）';
  }

  @override
  String get set_tileSeedMissing => 'SeedVR2 未インストール';

  @override
  String get set_tileSeedReady => 'SeedVR2 インストール済み';

  @override
  String get set_tileProtect => '保護';

  @override
  String set_tileProtectOn(Object on, Object all) {
    return '$on / $all オン';
  }

  @override
  String set_tileInterval(Object s, Object p) {
    return '間隔 $s 秒 ± $p%';
  }

  @override
  String get set_tileIntervalOff => '生成間隔なし';

  @override
  String get set_recent => '最近の変更';

  @override
  String get set_recentSub => '自動保存 · 取り消し可';

  @override
  String get set_recentEmpty => '変更はまだありません';

  @override
  String get set_quick => 'よく使う切替';

  @override
  String get set_quickSub => 'ここで変更';

  @override
  String get set_quickDark => 'ダークモード';

  @override
  String get set_quickChannel => 'キャンバスのビジュアルチャネル';

  @override
  String set_searchTip(Object keys) {
    return '$keys で設定を検索し、結果の中で直接変更できます。';
  }

  @override
  String get set_accDesc => 'NovelAI アカウント、既定ログイン、サブスクリプションを管理します。';

  @override
  String get set_accSaved => '保存済みアカウント';

  @override
  String get set_accSavedSub => 'ワンクリックで切り替えられます。認証情報は端末内に保存され、エクスポートされません。';

  @override
  String get set_accCurrent => '使用中';

  @override
  String get set_accInUse => '使用中';

  @override
  String get set_accSwitch => '切替';

  @override
  String get set_accEmail => 'メール';

  @override
  String get set_accToken => 'トークン';

  @override
  String set_accRenews(Object date) {
    return '更新 $date';
  }

  @override
  String set_accLastUsed(Object date) {
    return '最終使用 $date';
  }

  @override
  String get set_accNoSub => 'サブスクなし';

  @override
  String get set_accExpired => '認証情報の期限切れ';

  @override
  String get set_accEdit => 'プロフィール編集';

  @override
  String get set_accUpdate => '認証情報を更新';

  @override
  String get set_accMakeDefault => '既定にする';

  @override
  String get set_accDelete => 'アカウントを削除';

  @override
  String set_accDeleteTitle(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get set_accDeleteBody => 'この端末の認証情報だけを削除します。NovelAI のアカウントには影響しません。';

  @override
  String get set_accAdd => 'アカウントを追加';

  @override
  String get set_accAddHint => 'メールとパスワード、または永続トークン';

  @override
  String get set_accLogin => 'ログイン';

  @override
  String get set_accDefault => '既定のアカウント';

  @override
  String get set_accDefaultSub => 'ログイン画面で最初に選ばれるアカウント';

  @override
  String get set_accAutoLogin => '起動時に自動ログイン';

  @override
  String get set_accAutoLoginSub => '前回のセッションを使います。オフにすると毎回ログイン画面から始まります';

  @override
  String get set_accSub => 'サブスクリプション';

  @override
  String set_accMonthly(Object n) {
    return '毎月 $n Anlas';
  }

  @override
  String set_accRemaining(Object n) {
    return '残り $n';
  }

  @override
  String set_accResets(Object date) {
    return '$date にリセット';
  }

  @override
  String get set_accPortal => 'NovelAI のアカウントページ';

  @override
  String get set_accSwitchHint => '切り替えても下書きとキャンバスは残ります。キュー内の生成は元のアカウントで完了します。';

  @override
  String get set_apDesc => 'テーマ、文字、通知。変更はすぐ保存され、元に戻せます。';

  @override
  String get set_apTheme => 'テーマ';

  @override
  String get set_apThemeSub => '起動画面、ログイン、すべてのページで共通です。';

  @override
  String get set_apLight => 'ライト';

  @override
  String get set_apDark => 'ダーク';

  @override
  String get set_apSystem => 'システム';

  @override
  String get set_apSystemSub => 'Windows の設定に合わせる';

  @override
  String get set_apText => '文字';

  @override
  String get set_apFont => 'UI フォント';

  @override
  String get set_apFontSub => '数字とコードは Geist Mono を使います';

  @override
  String get set_apScale => '設定とダイアログの文字サイズ';

  @override
  String get set_apScaleSub => '設定とダイアログだけを拡大します';

  @override
  String get set_apSampleTitle => '見出し · 生成完了';

  @override
  String get set_apSampleBody => '本文 · ローカルギャラリーに保存しました。';

  @override
  String get set_apSampleNote => '注記 · スライダーを動かすとここに反映されます。';

  @override
  String get set_apLanguage => '言語';

  @override
  String get set_apLanguageSub => 'すぐに反映されます';

  @override
  String get set_apMotion => 'モーションとサウンド';

  @override
  String get set_apReduceMotion => '動きを減らす';

  @override
  String get set_apReduceMotionSub => 'キャンバス移動、ズーム、パネルのアニメーションを止めます';

  @override
  String get set_apSound => '生成完了サウンド';

  @override
  String get set_apSoundSub => 'バッチ完了時に再生';

  @override
  String get set_apSoundFile => 'サウンドファイル';

  @override
  String get set_apPreviewSound => '試聴';

  @override
  String get set_apNotify => '通知';

  @override
  String get set_apNotifySub => '右上に表示され 3 秒で消えます';

  @override
  String get set_apNotifyPreview => 'プレビュー';

  @override
  String get set_apPreview => 'プレビュー';

  @override
  String get set_apCurrent => '現在';

  @override
  String set_apThemeTip(Object keys) {
    return '$keys でいつでもライト／ダークを切り替えられます。';
  }

  @override
  String get set_cvDesc => '履歴、ビューアー、無限キャンバスの動作。';

  @override
  String get set_cvBrowse => '閲覧';

  @override
  String get set_cvHistoryClick => '履歴サムネイルをクリックしたとき';

  @override
  String get set_cvOpenDetail => '詳細を開く';

  @override
  String get set_cvOpenDetailSub => 'ビューアーで 1 枚ずつ確認';

  @override
  String get set_cvLinked => '連動プレビュー';

  @override
  String get set_cvLinkedSub => 'キャンバスで選択し、ビューアーは開きません';

  @override
  String get set_cvViewer => '生成結果の表示先';

  @override
  String get set_cvCanvas => '無限キャンバス';

  @override
  String get set_cvCanvasSub => 'バッチを縦に並べ、移動・ズーム・ピン留め';

  @override
  String get set_cvSimple => 'シンプルビューアー';

  @override
  String get set_cvSimpleSub => '最新の 1 枚のみ。最も軽量';

  @override
  String get set_cvCanvasSec => 'キャンバス';

  @override
  String get set_cvLock => 'キャンバスの視点を固定';

  @override
  String get set_cvLockSub => '新しい画像が出ても視点を動かしません';

  @override
  String get set_cvFill => '新しい画像を全体表示';

  @override
  String get set_cvFillSub => '実ピクセルではなく表示領域に合わせます';

  @override
  String get set_cvChannel => 'ビジュアルチャネル';

  @override
  String get set_cvChannelSub => 'キャンバスの通路をテーマで装飾し、履歴をたどると順にテーマが変わります。';

  @override
  String get set_cvMode => 'モード';

  @override
  String get set_cvMinTwo => 'ランダムでは 2 つ以上のテーマが必要です。';

  @override
  String set_cvSession(Object order) {
    return '今回の順番：$order';
  }

  @override
  String get set_cvLevel => '濃さ';

  @override
  String get set_cvRuler => 'タイムスケール';

  @override
  String get set_cvRulerSub => 'バッチ時刻、日付区切り、右側の目盛り';

  @override
  String get set_cvMotion => 'アイドル時の動き';

  @override
  String get set_cvMotionSub => '生成中と「動きを減らす」オンのときは停止';

  @override
  String get set_cvOps => 'キャンバス操作';

  @override
  String get set_cvOpScroll => '上下移動';

  @override
  String get set_cvOpPan => '左右移動';

  @override
  String get set_cvOpZoom => 'ズーム';

  @override
  String get set_cvOpMove => '視点移動';

  @override
  String get set_cvOpAll => '全体表示';

  @override
  String get set_cvOpHome => '最新バッチへ';

  @override
  String get set_cvWheel => 'ホイール';

  @override
  String get set_cvChannelTip => 'キャンバスの歯車からも同じ設定を変更できます。';

  @override
  String get set_scDesc => 'ページごとに分類。クリックして新しい組み合わせを記録します。重複は赤く表示されます。';

  @override
  String get set_scSearch => '操作やキーを検索（例：Ctrl+S）';

  @override
  String get set_scAll => 'すべて';

  @override
  String get set_scKeyboard => 'キーボード配置';

  @override
  String get set_scKeyboardSub => 'キーをクリックで絞り込み。青は使用中、赤は重複。';

  @override
  String get set_scNoMod => '修飾なし';

  @override
  String set_scLayer(Object context, Object mod) {
    return '$context · $mod を押している間';
  }

  @override
  String set_scLayerNone(Object context) {
    return '$context · 修飾キーなし';
  }

  @override
  String get set_scAction => '操作';

  @override
  String get set_scKeys => 'ショートカット';

  @override
  String get set_scDefault => '既定';

  @override
  String set_scDefaultIs(Object keys) {
    return '既定 $keys';
  }

  @override
  String set_scConflict(Object name) {
    return '「$name」と重複';
  }

  @override
  String get set_scRecording => '新しい組み合わせを押してください…';

  @override
  String get set_scRecordHint => 'Esc 取消 · Backspace 消去';

  @override
  String get set_scRecord => '記録';

  @override
  String get set_scClear => '消去';

  @override
  String get set_scDisplay => '表示';

  @override
  String get set_scEnabled => 'ショートカットを有効にする';

  @override
  String get set_scInTooltips => 'ツールチップに表示';

  @override
  String get set_scInMenus => 'メニューに表示';

  @override
  String get set_scBadges => 'ナビに番号を表示';

  @override
  String get set_scConflicts => '重複';

  @override
  String set_scConflictCount(Object n) {
    return '$n 件';
  }

  @override
  String set_scConflictLine(Object keys) {
    return '$keys が 2 つの操作に割り当て';
  }

  @override
  String set_scConflictSub(Object context, Object a, Object b) {
    return '$context：$a、$b。重複中はどちらも動作しません。';
  }

  @override
  String set_scFix(Object name, Object keys) {
    return '$nameを $keys に戻す';
  }

  @override
  String get set_scNoConflict => '重複なし';

  @override
  String get set_scConfig => 'ショートカット設定';

  @override
  String get set_scResetAll => 'すべて既定に戻す';

  @override
  String get set_scResetAllTitle => 'すべてのショートカットを既定に戻しますか？';

  @override
  String set_scResetAllBody(Object n) {
    return 'カスタマイズした $n 件が元に戻ります。';
  }

  @override
  String get set_scHelp => 'ショートカットのヘルプ';

  @override
  String set_scHelpTip(Object key) {
    return '$key でそのページのショートカットを表示します。';
  }

  @override
  String get set_scEmpty => '一致するショートカットはありません';

  @override
  String get set_gnDesc => 'Anlas の消費、リクエスト間隔、プロンプト入力補助を設定します。';

  @override
  String get set_gnCost => 'Anlas 保護';

  @override
  String get set_gnCostSub => 'しきい値を超えるリクエストは送信前に確認します。';

  @override
  String get set_gnWarn => '高コスト警告';

  @override
  String get set_gnWarnSub => 'しきい値超過時に確認';

  @override
  String get set_gnThreshold => 'しきい値';

  @override
  String set_gnEstimate(
    Object model,
    Object w,
    Object h,
    Object steps,
    Object n,
  ) {
    return '現在：$model · $w×$h · $steps ステップ · $n 枚';
  }

  @override
  String get set_gnWillWarn => '警告あり';

  @override
  String get set_gnNoWarn => '警告なし';

  @override
  String get set_gnFree => '無料';

  @override
  String get set_gnPace => 'リクエスト間隔';

  @override
  String get set_gnPaceSub => '連続生成のリクエスト間に待機し、サーバー負荷を減らします。';

  @override
  String get set_gnLimit => '生成間隔を制限';

  @override
  String get set_gnInterval => '間隔';

  @override
  String get set_gnJitter => 'ランダム変動';

  @override
  String get set_gnJitterSub => '間隔をランダムに増減';

  @override
  String get set_gnTimeline => 'この設定では 10 回のリクエストはこのような間隔です';

  @override
  String get set_gnInput => 'プロンプト入力';

  @override
  String get set_gnWheel => 'ホイールで重み調整';

  @override
  String get set_gnWheelSub => 'タグ上でホイールを回して重みを変更';

  @override
  String get set_gnNoKey => 'キー不要';

  @override
  String get set_gnRelated => '関連タグの提案';

  @override
  String get set_gnRelatedSub => 'よく一緒に使われるタグを提案';

  @override
  String get set_gnRag => 'セマンティックなタグ提案';

  @override
  String get set_gnRagSub => 'セマンティック検索による文脈に応じた提案';

  @override
  String get set_gnReady => '準備完了';

  @override
  String get set_gnNotReady => '未準備';

  @override
  String get set_gnGoSettings => '設定へ';

  @override
  String get set_gnTranslate => 'プロンプト翻訳';

  @override
  String get set_gnTranslateSub => 'プロンプト翻訳に使うモデル';

  @override
  String get set_gnToday => '今日';

  @override
  String get set_gnUsed => 'Anlas 使用';

  @override
  String get set_gnNow => '現在';

  @override
  String get set_gnWarned => '高コスト警告';

  @override
  String set_gnTimes(Object n) {
    return '$n 回';
  }

  @override
  String get set_gnMaxSingle => '最大 1 回の消費';

  @override
  String get set_gnFreeTip => 'Opus の無料枠は計算済みです。しきい値は実際の消費だけを見ます。';

  @override
  String get set_stDesc => '画像の保存先、ギャラリーが読むフォルダー、容量と整理。';

  @override
  String get set_stUsage => '使用量';

  @override
  String set_stFree(Object disk, Object size) {
    return '$disk 空き $size';
  }

  @override
  String get set_stRecount => '再集計';

  @override
  String get set_stCounting => '集計中…';

  @override
  String get set_stImages => '画像';

  @override
  String get set_stUpscaleModels => '拡大モデル';

  @override
  String get set_stVibes => 'Vibe ライブラリ';

  @override
  String get set_stThumbs => 'サムネイルキャッシュ';

  @override
  String get set_stRag => 'セマンティック索引';

  @override
  String get set_stDict => '辞書とキャッシュ';

  @override
  String get set_stAgent => 'Agent';

  @override
  String get set_stSave => '保存';

  @override
  String get set_stSavePath => '画像の保存先';

  @override
  String get set_stAutoSave => '自動保存';

  @override
  String get set_stAutoSaveSub => '生成後すぐに保存します。オフではキャンバスと履歴にのみ残ります';

  @override
  String get set_stAssets => '素材と表示';

  @override
  String get set_stVibePath => 'Vibe ライブラリの場所';

  @override
  String get set_stQuality => 'ギャラリーの画質';

  @override
  String get set_stQualitySub => 'サムネイルの表示品質';

  @override
  String get set_stHigh => '高画質';

  @override
  String get set_stStandard => '標準';

  @override
  String get set_stRoots => 'ギャラリーのフォルダー';

  @override
  String get set_stRootsSub => '任意のフォルダーをギャラリーで閲覧・検索できます。自動保存の対象外です。';

  @override
  String get set_stPrimary => 'メイン';

  @override
  String set_stCount(Object n) {
    return '$n 枚';
  }

  @override
  String get set_stAddFolder => 'フォルダーを追加';

  @override
  String get set_stImportIndex => 'タグ索引をインポート (.jsonl)';

  @override
  String set_stLastScan(Object when, Object n) {
    return '最終スキャン $when · $n 枚';
  }

  @override
  String get set_stMaintain => 'メンテナンス';

  @override
  String get set_stRescan => 'ギャラリーを再スキャン';

  @override
  String get set_stRescanSub => '欠落ファイルの確認、新規ファイルの追加、メタデータの再読込';

  @override
  String get set_stScan => 'スキャン';

  @override
  String get set_stScanning => 'スキャン中…';

  @override
  String get set_stCleanThumbs => 'サムネイルキャッシュを整理';

  @override
  String get set_stCleanThumbsSub => '上限を超えたサムネイルを古い順に削除。元画像はそのまま';

  @override
  String get set_stClean => '整理';

  @override
  String get set_stCleanTitle => 'サムネイルキャッシュを整理しますか？';

  @override
  String get set_stCleanBody => '上限を超えたサムネイルを削除し、必要時に再生成します。';

  @override
  String get set_stAppData => 'アプリデータの場所';

  @override
  String get set_stAppDataSub => 'アカウント、履歴、ブロックなどのデータベース。変更後は再起動';

  @override
  String get set_stOpenFolders => 'フォルダーを開く';

  @override
  String get set_stLogs => 'ログ';

  @override
  String get set_stAppDataShort => 'アプリデータ';

  @override
  String get set_stDeleteTip => '画像の移動・削除はギャラリーで行い、「プライバシーと保護」の確認ルールに従います。';

  @override
  String get set_stRemoveRoot => 'このフォルダーを外す';

  @override
  String get set_dcDesc => 'タグデータとキャッシュ。補完がおかしいときにここで整理します。';

  @override
  String get set_dcTags => 'タグ辞書';

  @override
  String get set_dcTagsSub => '補完、タグ翻訳、提案に使うローカルデータ。';

  @override
  String get set_dcBase => '基本データベース';

  @override
  String set_dcBaseValue(Object n, Object wiki) {
    return 'タグ $n 件 · Wiki $wiki 件';
  }

  @override
  String get set_dcSupplement => 'データ補充';

  @override
  String get set_dcCheckUpdates => '更新を確認';

  @override
  String get set_dcWikiRefreshAvailable => 'Wiki 本文を再適用できます';

  @override
  String get set_dcCheckingUpdates => '確認中…';

  @override
  String get set_dcCheckFailed => '確認に失敗しました。ローカルデータは利用できます。再試行してください。';

  @override
  String get set_dcLatest => '最新です';

  @override
  String get set_dcUpdatesAvailable => '更新があります';

  @override
  String set_dcLastChecked(Object when) {
    return '最終確認 $when';
  }

  @override
  String get set_dcRefreshWiki => 'Wiki を再適用';

  @override
  String get set_dcRefreshWikiTip =>
      '現在の Wiki データをダウンロードし、既存の記事を更新します。個人の翻訳は保持されます。';

  @override
  String set_dcChanged(Object added, Object updated) {
    return '$added 件追加、$updated 件更新。ローカルに保存しました。';
  }

  @override
  String get set_dcRagSyncTip =>
      '意味検索を使用している場合は、Studio を再起動してから、該当ソースの索引を手動で同期してください。';

  @override
  String get set_dcUpdateTags => 'タグを更新';

  @override
  String get set_dcUpdateWiki => 'Wiki を更新';

  @override
  String set_dcSources(Object tagDate, Object wikiDate) {
    return '利用可能なデータ：Tag $tagDate · Wiki $wikiDate';
  }

  @override
  String set_dcDownloading(Object received, Object total) {
    return 'ダウンロード中 $received / $total';
  }

  @override
  String get set_dcVerifying => 'ダウンロードを検証中…';

  @override
  String set_dcImporting(Object n) {
    return 'ローカルデータを補充中 · $n 件読み込み済み';
  }

  @override
  String get set_dcPublishing => 'データのバージョンを切り替え中…';

  @override
  String get set_dcUpdateFailed => '補充できませんでした。既存データは保持されています。再試行できます。';

  @override
  String get set_dcUpdateCancelled => 'キャンセルしました。既存データは引き続き利用できます。';

  @override
  String get set_dcInstalled => '補充済み';

  @override
  String get set_dcCancelling => 'キャンセル中…';

  @override
  String get set_dcCooc => '共起データ';

  @override
  String get set_dcCoocSub => 'よく一緒に出るタグの提案に使います';

  @override
  String set_dcEntries(Object n) {
    return '$n 件';
  }

  @override
  String get set_dcSemantics => '個人の意味情報';

  @override
  String get set_dcSemanticsSub => '補足した中国語資料は翻訳キャッシュの削除後も保持';

  @override
  String get set_dcTranslate => 'タグ翻訳・意味情報';

  @override
  String get set_dcTranslateSub => '既存資料を再利用し、中国語の基本名・同義語・短い説明を補完';

  @override
  String get set_dcCaches => 'キャッシュ';

  @override
  String get set_dcCachesSub => '消去しても必要時に再取得します。画像と設定には影響しません。';

  @override
  String get set_dcDanbooru => 'Danbooru キャッシュ';

  @override
  String get set_dcDanbooruSub => 'オンラインギャラリーとタグ百科の応答';

  @override
  String get set_dcTranslation => 'AI 翻訳キャッシュ';

  @override
  String get set_dcTranslationSub => '翻訳済みのタグとプロンプト';

  @override
  String set_dcCacheSize(Object n, Object size) {
    return '$n 件 · $size';
  }

  @override
  String set_dcClearTitle(Object name) {
    return '$nameを消去しますか？';
  }

  @override
  String get set_dcClearBody => '次に使うときに再取得します。';

  @override
  String get set_dcStats => 'キャッシュ統計';

  @override
  String get set_dcL1 => 'L1 メモリ';

  @override
  String get set_dcL2 => 'L2 Hive';

  @override
  String get set_dcL3 => 'L3 SQLite';

  @override
  String set_dcImagesUnit(Object n) {
    return '$n 枚';
  }

  @override
  String get set_dcAutoRefresh => '自動更新';

  @override
  String set_dcUpdated(Object when) {
    return '最終更新 $when';
  }

  @override
  String get set_dcResetStats => '統計をリセット';

  @override
  String get set_dcTip =>
      '辞書とキャッシュは再取得できます。個人の意味情報はこのページから書き出してください。その他の個人データは「ストレージ → アプリデータの場所」にあります。';

  @override
  String get set_mdDesc =>
      '翻訳・逆推定・タグ翻訳・Agent が使う LLM サービス。プロバイダーを追加し、機能ごとにモデルを選びます。';

  @override
  String get set_mdProviders => 'プロバイダー';

  @override
  String get set_mdTasks => '機能の割り当て';

  @override
  String get set_mdTaskHint => '翻訳を使わなくても、意味単位への分割や構造化した並べ替えなどにモデルを利用できます。';

  @override
  String get set_mdPresets => 'プロンプトプリセット';

  @override
  String get set_mdRequests => 'リクエスト履歴';

  @override
  String set_mdProviderCount(Object n) {
    return '$n プロバイダー';
  }

  @override
  String set_mdModelCount(Object n) {
    return '$n モデル';
  }

  @override
  String get set_mdDisabled => '無効';

  @override
  String get set_mdUnreachable => '接続失敗';

  @override
  String get set_mdBaseUrl => 'ベース URL';

  @override
  String get set_mdApiKey => 'API キー';

  @override
  String set_mdUsedFor(Object tasks) {
    return '$tasks に使用';
  }

  @override
  String get set_mdRetired => '提供終了';

  @override
  String get set_mdDelete => 'プロバイダーを削除';

  @override
  String set_mdDeleteTitle(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get set_mdDeleteBody => '使用中の機能は別のプロバイダーに切り替わります。';

  @override
  String get set_mdTaskPrompt => 'プロンプト翻訳';

  @override
  String get set_mdTaskReverse => 'プロンプト逆推定';

  @override
  String get set_mdTaskTag => 'タグ翻訳・意味情報';

  @override
  String get set_mdTaskWiki => '百科翻訳';

  @override
  String get set_mdFeature => '機能';

  @override
  String get set_mdProvider => 'プロバイダー';

  @override
  String get set_mdModel => 'モデル';

  @override
  String get set_mdPreset => 'プリセット';

  @override
  String get set_mdStatus => '状態';

  @override
  String get set_mdAvailable => '利用可';

  @override
  String get set_mdFallback => '最初の利用可能なプロバイダーを使用';

  @override
  String get set_mdNotChosen => '未選択';

  @override
  String get set_mdBuiltin => '内蔵';

  @override
  String get set_mdNewPreset => 'プリセットを作成';

  @override
  String get set_mdEdit => '編集';

  @override
  String get set_mdTime => '時刻';

  @override
  String set_mdTokens(Object n) {
    return '$n トークン';
  }

  @override
  String get set_mdFailed => '失敗';

  @override
  String get set_mdOk => '成功';

  @override
  String set_mdShowing(Object n, Object total) {
    return '最新 $n 件 / 全 $total 件';
  }

  @override
  String get set_mdImport => '設定をインポート';

  @override
  String get set_mdAddProvider => 'プロバイダーを追加';

  @override
  String get set_mdEmpty => 'プロバイダーがありません';

  @override
  String get set_mdEmptySub => '追加すると翻訳と逆推定が使えます。';

  @override
  String get set_agDesc => 'サイドバーアシスタントのモデル、指示、スキル、拡張、MCP ツール。';

  @override
  String get set_agModelSec => 'モデル';

  @override
  String get set_agModel => 'デフォルトモデル';

  @override
  String get set_agModelSub => '思考の強さはチャット欄で調整します';

  @override
  String get set_agEnter => 'Enter で送信';

  @override
  String get set_agEnterSub => 'オフでは Ctrl+Enter で送信、Enter で改行';

  @override
  String get set_agMax => '1 タスクの最大リクエスト';

  @override
  String get set_agMaxSub => 'ループを防ぎます';

  @override
  String get set_agTimesUnit => '回';

  @override
  String get set_agInstr => '指示';

  @override
  String get set_agInstrSub => 'この順で最終プロンプトになります。既存のチャットはそのまま、以降のリクエストに反映。';

  @override
  String get set_agOrderBuiltin => '内蔵システムプロンプト';

  @override
  String get set_agOrderPrefix => '内蔵プロンプトの前';

  @override
  String get set_agOrderGlobal => '全体の指示';

  @override
  String get set_agOrderWorkspace => 'ワークスペースのルール';

  @override
  String get set_agGlobal => '全体の指示';

  @override
  String get set_agGlobalHint => 'システム全体の AGENTS.md に相当し、すべてのワークスペースに適用されます。';

  @override
  String get set_agPrefix => '内蔵プロンプトの前';

  @override
  String get set_agPrefixHint => '内蔵システムプロンプトの前に追加する固定内容。役割や出力形式などを指定できます。';

  @override
  String get set_agBuiltin => '内蔵システムプロンプト';

  @override
  String get set_agFinal => '最終プロンプトを表示';

  @override
  String get set_agExt => '拡張';

  @override
  String get set_agExtSub => 'ワークスペースごとに読み込み。外部拡張はローカルコードを実行します。';

  @override
  String get set_agStudioExt => 'Studio 連携';

  @override
  String get set_agStudioExtSub => 'Studio の状態を読み、質問カードで回答を集めます';

  @override
  String get set_agRequired => '内蔵 · 必須';

  @override
  String get set_agAddFile => '拡張ファイルを追加';

  @override
  String get set_agAddDir => '拡張フォルダーを追加';

  @override
  String get set_agMcp => 'MCP サーバー';

  @override
  String get set_agMcpSub => 'CodeMode は必要時にツールを探し、一度にコンテキストへ入れません。';

  @override
  String get set_agBuiltinTools => 'NAI Studio · 内蔵ツール';

  @override
  String get set_agBuiltinToolsSub => 'プロンプト、ブロック、百科、画像、履歴、参照、生成、設定';

  @override
  String set_agConnected(Object n) {
    return '接続済み · $n ツール';
  }

  @override
  String get set_agConnecting => '接続中…';

  @override
  String get set_agNeedsLogin => 'ログインが必要';

  @override
  String get set_agMcpError => '接続失敗';

  @override
  String get set_agMcpOff => '無効';

  @override
  String get set_agAddMcp => 'MCP サーバーを追加';

  @override
  String get set_agTools => 'ツール';

  @override
  String set_agToolCount(Object n) {
    return '$n 件';
  }

  @override
  String get set_agToolsTip =>
      '業務ツールは codemode 経由で必要時に検出され、使い方は nai-studio スキルにあります。生成系ツールは必ず見積もりを出し、確認後に実行します。';

  @override
  String get set_agData => 'データフォルダー';

  @override
  String get set_agWorkspaces => 'ワークスペース';

  @override
  String get set_agSessions => 'セッション';

  @override
  String get set_agCostTip => '料金はプロバイダーが請求し、Studio はトークン数のみ表示します。';

  @override
  String get set_agOpen => 'Agent を開く';

  @override
  String get set_agEditMcp => '編集';

  @override
  String get set_agRemoveMcp => 'サーバーを外す';

  @override
  String get set_agRemoveExt => '拡張を外す';

  @override
  String get set_rgDesc => 'ローカル RAG。タグ提案、百科、ブロック、類似画像検索に使い、何もアップロードしません。';

  @override
  String get set_rgReady => 'セマンティック検索の準備完了';

  @override
  String get set_rgOff => 'セマンティック検索オフ';

  @override
  String get set_rgPartial => '一部構築中';

  @override
  String get set_rgAllDone => 'すべて完了';

  @override
  String get set_rgPool => 'すべてのソースが 1 つのローカルベクトルストアを共有し、差分更新します。';

  @override
  String get set_rgStepRuntime => '実行環境';

  @override
  String get set_rgStepEmbed => '埋め込み';

  @override
  String get set_rgStepRerank => '再ランク';

  @override
  String get set_rgStepDevice => 'デバイス';

  @override
  String get set_rgSources => 'ソース';

  @override
  String get set_rgSourcesSub => 'ソースごとに構築・切替。一時停止でき、完了分はすぐ使えます。';

  @override
  String get set_rgTags => 'タグ提案';

  @override
  String get set_rgTagsSub => '意味・共起・再ランクを組み合わせ、各入力欄ごとに計算';

  @override
  String get set_rgWiki => '百科のセマンティック検索';

  @override
  String get set_rgWikiSub => 'ローカル百科。名前の完全一致を優先し、意味検索で補完';

  @override
  String get set_rgBlocks => 'プロンプトブロック';

  @override
  String get set_rgBlocksSub => '保存済み・未アーカイブのブロックの名前、タグ、本文';

  @override
  String get set_rgGallery => 'ギャラリー（マルチモーダル）';

  @override
  String get set_rgGallerySub => '画像内容で類似検索。NAI のパラメーターは別途テキスト索引。元画像は変更しません';

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
    return '画像 $done / $total · パラメーター $n 段';
  }

  @override
  String get set_rgPaused => '一時停止中';

  @override
  String get set_rgBuilding => '構築中';

  @override
  String get set_rgError => 'エラー';

  @override
  String get set_rgClearIndex => '索引を消去';

  @override
  String set_rgClearTitle(Object name) {
    return '「$name」の索引を消去しますか？';
  }

  @override
  String get set_rgClearBody => '派生索引だけを削除し、元の内容とモデルは残ります。';

  @override
  String get set_rgContext => '提案の文脈';

  @override
  String get set_rgContextSub => 'どちらも最大 120 Gemma トークン、タグ単位で切り取り。';

  @override
  String get set_rgRange => '取得範囲';

  @override
  String get set_rgBefore => 'カーソルの前';

  @override
  String get set_rgAround => 'カーソルの前後';

  @override
  String get set_rgRuntime => 'モデルと実行環境';

  @override
  String get set_rgEmbedPath => '埋め込みモデルのフォルダー';

  @override
  String get set_rgRerankPath => '再ランクモデルのフォルダー';

  @override
  String get set_rgDevice => '実行デバイス';

  @override
  String get set_rgAuto => '自動';

  @override
  String get set_rgEnv => '実行環境';

  @override
  String get set_rgEnvSub => '独立した Python と推論依存。モデルの重みは含みません';

  @override
  String get set_rgCheck => '確認';

  @override
  String get set_rgReinstall => '再インストール';

  @override
  String get set_rgProgress => '構築の進捗';

  @override
  String get set_rgOverall => '全体';

  @override
  String get set_rgShortTags => 'タグ';

  @override
  String get set_rgShortWiki => '百科';

  @override
  String get set_rgShortBlocks => 'ブロック';

  @override
  String get set_rgShortGallery => 'ギャラリー';

  @override
  String get set_rgTip => 'ソースを消去しても派生索引だけが消え、元の内容とモデルは残ります。';

  @override
  String get set_rgNotReady => 'セマンティック検索はまだ使えません';

  @override
  String get set_rgNotReadySub => '実行環境をインストールし、2 つのモデルフォルダーを設定してください。';

  @override
  String get set_rgEmpty => '未構築';

  @override
  String get set_rgBuild => '索引を構築';

  @override
  String get set_rgContinue => '続きを構築';

  @override
  String set_rgSkipped(Object n) {
    return '$n 枚スキップ';
  }

  @override
  String get set_rgStartupTitle => 'インデックスの準備';

  @override
  String get set_rgStartupBody => '初めて作成または再開する前に、ローカル実行環境、モデル、既存データを準備します。';

  @override
  String get set_rgStartupWaitTitle => '数分以上かかる場合があります';

  @override
  String get set_rgStartupWaitBody => '準備中は進捗の数値が変わらないことがあります。しばらくお待ちください。';

  @override
  String get set_rgStartupFrequency => 'Studio の起動ごとに一度だけ表示';

  @override
  String get set_rgLoading => 'インデックスを読み込み中';

  @override
  String get set_rgOpening => 'ローカルワーカーに接続し、既存のインデックスを確認しています。';

  @override
  String get set_rgLoadingSaved => '保存済みの検索インデックスを読み込んでいます。';

  @override
  String set_rgRestoring(String done, String total) {
    return '検索インデックスを復元中：$done / $total。既存のベクトルを再利用します。';
  }

  @override
  String get set_rgSaving => '復元した検索インデックスを保存しています。';

  @override
  String get set_rgReadingSources => '各ソースのインデックス状態を読み込んでいます。';

  @override
  String get set_rgLoadingTimeout =>
      '読み込みが長時間進まないか、制限時間に達しました。再試行してください。既存のデータは保持されています。';

  @override
  String get set_rgPreparing => 'インデックスを準備中';

  @override
  String get set_rgPreparingHint =>
      'インデックスを準備・確認しています。データが多い場合は時間がかかり、進捗の数値が変わらないことがあります。';

  @override
  String get set_rgPlanLoading => '対象を集計中…';

  @override
  String set_rgPlanTags(Object n) {
    return '$n 件のタグ、別名、ローカルの説明を収録します。';
  }

  @override
  String set_rgPlanText(Object docs, Object n) {
    return '$docs 件の資料を $n 個のテキスト片として収録します。';
  }

  @override
  String set_rgPlanGallery(Object images, Object n) {
    return '画像 $images 枚と NAI パラメーター $n 段を別々に収録します。';
  }

  @override
  String get set_rgPlanNote => '初回は時間がかかります。いつでも一時停止でき、完了分はすぐ使えます。';

  @override
  String get set_rgPlanRebuild => '再構築するとこのソースの既存の索引を先に消去します。';

  @override
  String get set_rgStart => '開始';

  @override
  String get set_rgDownload => 'ダウンロード';

  @override
  String set_rgDownloading(Object done, Object total) {
    return 'ダウンロード中 $done / $total';
  }

  @override
  String set_rgDownloadingUnknown(Object done) {
    return 'ダウンロード中 $done';
  }

  @override
  String get set_rgVerifying => 'ファイルを検証中…';

  @override
  String get set_rgDiscover => 'ローカルモデルを探す';

  @override
  String get set_rgDiscoverSub =>
      '04_工具/models で EmbeddingGemma 2 と Qwen3-Reranker 0.6B を探し、上の 2 つのフォルダーを埋めます。';

  @override
  String get set_rgFind => '探す';

  @override
  String get set_rgModelsMissing => '見つかりません。「ダウンロード」するか、重みのフォルダーを選んでください。';

  @override
  String get set_rgPython => 'Python インタープリター';

  @override
  String get set_rgPythonSub => '既定は自動インストールの独立環境。既存の python.exe も選べます。';

  @override
  String get set_rgPythonAuto => '自動';

  @override
  String get set_rgPythonNone => '未インストール';

  @override
  String get set_rgPythonPending => 'まだ使われていません。「このインタープリターを使う」で依存を入れ直します。';

  @override
  String get set_rgUsePython => 'このインタープリターを使う';

  @override
  String get set_rgEnvReady => '準備完了';

  @override
  String get set_rgEnvMissing => '未インストール';

  @override
  String get set_rgInstall => 'インストール';

  @override
  String get set_rgInstallHint =>
      'Python と推論依存をダウンロードします（モデルの重みは含みません）。NVIDIA なら CUDA（数 GB）、それ以外は小さい CPU 版。';

  @override
  String get set_rgInstallCuda => 'CUDA · NVIDIA';

  @override
  String get set_rgInstallCpu => 'CPU';

  @override
  String get set_rgPhaseExisting => '既存の環境を確認中';

  @override
  String get set_rgPhaseDownload => 'インストーラーをダウンロード中';

  @override
  String get set_rgPhaseCreate => 'Python を準備中';

  @override
  String get set_rgPhaseCuda => 'CUDA コンポーネントをインストール中';

  @override
  String get set_rgPhasePackages => '依存をインストール中';

  @override
  String get set_rgPhaseCheck => '環境を検証中';

  @override
  String set_rgElapsed(Object time) {
    return 'この段階 $time';
  }

  @override
  String get set_upDesc => 'ローカルの拡大モデルとコンポーネントを管理します。ダウンロードは手動で開始します。';

  @override
  String set_upGpu(Object name, Object n) {
    return '$name · $n GB';
  }

  @override
  String get set_upNoGpu => '独立 GPU が見つかりません';

  @override
  String get set_upLocal => 'この PC で拡大し、Anlas を消費しません。';

  @override
  String get set_upEsrgan => '標準モデル';

  @override
  String get set_upEsrganSub => 'Real-ESRGAN NCNN、4 倍、高速。Vulkan 対応 GPU で動作。';

  @override
  String get set_upAnimeQuality => 'アニメ · 画質';

  @override
  String get set_upAnimeFast => 'アニメ · 高速';

  @override
  String get set_upGeneral => '汎用 · 写真';

  @override
  String get set_upBuiltin => '内蔵';

  @override
  String get set_upInstalled => 'インストール済み';

  @override
  String get set_upNotInstalled => '未インストール';

  @override
  String get set_upFailed => 'ダウンロード失敗';

  @override
  String get set_upImport => 'モデルをインポート';

  @override
  String get set_upImportHint => '対応する .param と .bin（4 倍 Real-ESRGAN NCNN）を選択';

  @override
  String get set_upSeed => 'SeedVR2 拡散拡大';

  @override
  String get set_upSeedSub =>
      '高画質・低速、NVIDIA 必須。VAE（約 0.5 GB）と Python/CUDA 環境を共有。';

  @override
  String get set_upSeed3b => '3B · バランス';

  @override
  String get set_upSeed3bSub => '品質とリソースのバランス。普段使いに';

  @override
  String get set_upSeed7b => '7B · 高画質';

  @override
  String get set_upSeed7bSub => '高画質。VRAM と時間が多く必要';

  @override
  String get set_upSeed7bSharp => '7B · シャープ';

  @override
  String get set_upSeed7bSharpSub => 'よりシャープなディテール';

  @override
  String get set_upSeed3bInt8 => '3B · バランス INT8';

  @override
  String get set_upSeed3bInt8Sub => '3B バランスモデルの INT8 量子化版';

  @override
  String get set_upSeed7bInt8 => '7B · 高画質 INT8';

  @override
  String get set_upSeed7bInt8Sub => '7B 高画質モデルの INT8 量子化版';

  @override
  String get set_upSeed7bSharpInt8 => '7B · シャープ INT8';

  @override
  String get set_upSeed7bSharpInt8Sub => '7B シャープモデルの INT8 量子化版';

  @override
  String set_upVram(Object n) {
    return 'VRAM ≥ $n GB';
  }

  @override
  String set_upProgress(Object done, Object total, Object speed) {
    return '$done / $total · $speed/s';
  }

  @override
  String get set_upVramMode => 'VRAM モード';

  @override
  String get set_upRecommended => '推奨';

  @override
  String get set_upLowVram => '省 VRAM';

  @override
  String get set_upOffload => 'CPU オフロード層数';

  @override
  String get set_upOffloadSub => '多いほど VRAM を節約しますが遅くなります';

  @override
  String get set_upTiling => 'VAE タイル';

  @override
  String get set_upTilingSub => '小さいタイルは VRAM を節約。重なりで継ぎ目を軽減';

  @override
  String get set_upNoise => '実験的ノイズ';

  @override
  String set_upNoiseSub(Object a, Object b) {
    return '入力 $a · 潜在 $b。0 で現状維持';
  }

  @override
  String get set_upInputNoise => '入力ノイズ';

  @override
  String get set_upLatentNoise => '潜在ノイズ';

  @override
  String get set_upExperimental => '実験';

  @override
  String get set_upRtx => 'RTX Video';

  @override
  String get set_upRtxSub => 'NVIDIA RTX Video で高速拡大（約 64 MB）。';

  @override
  String get set_upRtxName => 'RTX Video Super Resolution';

  @override
  String get set_upRtxNeeds => '対応 RTX GPU とドライバーが必要';

  @override
  String get set_upDefault => '既定の拡大方法';

  @override
  String get set_upDefaultTip => '生成ページの「ローカル拡大」で使います。メニューでいつでも変更可。';

  @override
  String get set_upVramTip =>
      'VRAM 不足でもモデルは自動で切り替わりません。3B、倍率を下げる、省 VRAM、VAE タイルを試してください。';

  @override
  String set_upRemoveTitle(Object name) {
    return '$nameを削除しますか？';
  }

  @override
  String get set_upRemoveBody => '使うときは再ダウンロードが必要です。';

  @override
  String get set_brDesc => 'この PC の他のアプリと連携：Krita、外部 Agent、ComfyUI。';

  @override
  String get set_brKritaSub => 'Krita から生成し、結果をレイヤーに戻します。';

  @override
  String get set_brKrita => 'Krita ブリッジ';

  @override
  String get set_brLoopback => '127.0.0.1 からの接続のみ受け付けます';

  @override
  String get set_brConnected => '接続済み';

  @override
  String get set_brWaiting => 'Krita の接続待ち';

  @override
  String get set_brRegenerate => 'セッションを再生成';

  @override
  String get set_brDiscovery => '検出ファイル';

  @override
  String get set_brAgents => '外部 Agent';

  @override
  String get set_brAgentsSub => 'Claude Code や Codex などがパラメーターの読み書きと生成を行えます。';

  @override
  String get set_brLocal => 'ローカルブリッジ';

  @override
  String set_brClients(Object n) {
    return '$n 件の Agent が接続中';
  }

  @override
  String get set_brNoClients => '接続中の Agent なし';

  @override
  String get set_brTakeover => '接続手順をコピー';

  @override
  String get set_brEnd => '接続を終了';

  @override
  String get set_brActivity => '最近のアクティビティ';

  @override
  String get set_brComfySub => 'ComfyUI のワークフローを読み込み Studio から実行します。';

  @override
  String get set_brComfyEnable => 'ComfyUI を有効にする';

  @override
  String get set_brComfyUrl => 'サーバーアドレス';

  @override
  String set_brComfyFailed(Object reason, Object when) {
    return '接続失敗：$reason（$when）。ComfyUI が起動しているか確認してください。';
  }

  @override
  String set_brComfyOk(Object when) {
    return '接続正常（$when）';
  }

  @override
  String get set_brStatus => '状態';

  @override
  String set_brAgentsShort(Object n) {
    return '$n 件';
  }

  @override
  String get set_brOff => '無効';

  @override
  String get set_brNoResponse => '応答なし';

  @override
  String get set_brTip => 'ブリッジはループバックのみで待ち受け、LAN には公開しません。プロキシは適用されません。';

  @override
  String get set_nwDesc => 'プロキシと接続状態。';

  @override
  String get set_nwProxy => 'プロキシ';

  @override
  String get set_nwProxySub => 'NovelAI、Danbooru、GitHub 更新、モデルサービスへの接続に使います。';

  @override
  String get set_nwUse => 'プロキシを使う';

  @override
  String get set_nwMode => '方式';

  @override
  String get set_nwSystem => 'システム';

  @override
  String get set_nwManual => '手動';

  @override
  String get set_nwAddress => 'アドレス';

  @override
  String set_nwDetected(Object addr) {
    return 'システムプロキシ：$addr。外部リクエストのみ経由し、ローカルブリッジとモデルは経由しません。';
  }

  @override
  String get set_nwNoSystem => 'システムプロキシは見つかりません。外部リクエストのみ経由します。';

  @override
  String get set_nwCheck => '接続チェック';

  @override
  String get set_nwCheckSub => '各サービスへの到達性をまとめて確認します。';

  @override
  String get set_nwNaiImage => 'NovelAI 画像生成';

  @override
  String get set_nwNaiApi => 'NovelAI アカウント';

  @override
  String get set_nwDanbooru => 'Danbooru';

  @override
  String get set_nwUpdate => 'アプリ更新';

  @override
  String get set_nwCheckAll => 'すべて確認';

  @override
  String set_nwChecked(Object when) {
    return '最終確認 $when';
  }

  @override
  String get set_nwViaProxy => 'プロキシ経由';

  @override
  String get set_nwDirect => '直接接続';

  @override
  String get set_nwNeverChecked => '未確認';

  @override
  String get set_nwFail => '失敗';

  @override
  String get set_nwTip => 'プロキシの変更は再起動後に反映されます。自動で再起動はしません。';

  @override
  String get set_pvDesc => '共有時に含める情報と、確認が必要な操作。';

  @override
  String get set_pvProtect => '保護';

  @override
  String get set_pvStrip => '共有時にメタデータを除去';

  @override
  String get set_pvStripSub => 'コピーやドラッグ時にプロンプトとパラメーターを除去。元ファイルはそのまま';

  @override
  String get set_pvExternal => '外部送信前に確認';

  @override
  String get set_pvExternalSub => '他のアプリやサイトへ送る前に確認';

  @override
  String get set_pvDanger => '危険な操作を確認';

  @override
  String get set_pvDangerSub => '削除・消去・上書きの前に確認';

  @override
  String get set_pvOverwrite => '保存時に上書きしない';

  @override
  String get set_pvOverwriteSub => '同名ファイルがあれば自動で名前を変更';

  @override
  String get set_pvBlacklist => 'オンラインギャラリーのブロックリスト';

  @override
  String get set_pvBlacklistSub => 'これらのタグを含む画像を非表示にします。';

  @override
  String get set_pvAddTag => 'タグを追加…';

  @override
  String get set_pvSync => 'Danbooru のブロックリストを同期';

  @override
  String set_pvSyncSub(Object user, Object when) {
    return '$user でログイン中 · 最終同期 $when';
  }

  @override
  String set_pvSyncNever(Object user) {
    return '$user でログイン中 · 未同期';
  }

  @override
  String get set_pvSyncSignedOut => 'Danbooru にログインすると同期できます';

  @override
  String get set_pvSyncNow => '今すぐ同期';

  @override
  String get set_pvSyncing => '同期中…';

  @override
  String get set_pvAutoSync => '起動時に自動同期';

  @override
  String get set_pvExported => 'エクスポートに含まれるもの';

  @override
  String get set_pvIncPrefs => '外観・操作・入力の設定';

  @override
  String get set_pvIncRules => '保護ルールとブロックリスト';

  @override
  String get set_pvIncCred => 'アカウント認証情報';

  @override
  String get set_pvIncPaths => 'ファイルパス';

  @override
  String get set_pvIncDrafts => '下書きとモデル設定';

  @override
  String get set_pvTip => '除去はコピーとドラッグのみ。保存した元画像はパラメーターを保持します。';

  @override
  String get set_bkDesc => '設定を他の端末へ移す、または既定に戻します。リセット前に必ずバックアップします。';

  @override
  String get set_bkPrefs => '設定';

  @override
  String get set_bkPrefsSub => '外観・操作・入力・保護ルール。認証情報、パス、下書き、モデル設定は含みません。';

  @override
  String get set_bkExport => 'エクスポート';

  @override
  String get set_bkExportSub => 'studio-preferences.json として保存';

  @override
  String get set_bkExportBtn => 'エクスポート…';

  @override
  String get set_bkImport => 'インポート';

  @override
  String get set_bkImportSub => '適用前に変更件数を表示し、現在の設定をバックアップします';

  @override
  String get set_bkImportBtn => 'ファイルを選択…';

  @override
  String get set_bkUndoImport => '前回のインポートを取り消す';

  @override
  String set_bkUndoImportSub(Object when) {
    return '$when のインポート前に戻します';
  }

  @override
  String get set_bkNoImport => 'インポート履歴なし';

  @override
  String get set_bkRestore => '復元';

  @override
  String get set_bkOther => 'その他の設定';

  @override
  String set_bkShortcutsSub(Object n, Object m) {
    return '$n 件、$m 件をカスタマイズ';
  }

  @override
  String get set_bkModelsSub => 'プロバイダー、割り当て、プリセット。API キーは既定で含みません';

  @override
  String get set_bkCopyConfig => '設定をコピー';

  @override
  String get set_bkReset => '既定に戻す';

  @override
  String get set_bkResetSub => 'リセットする範囲を選びます。その他はそのままです。';

  @override
  String get set_bkScopeAppearance => '外観と操作';

  @override
  String get set_bkScopeAppearanceSub => 'テーマ、フォント、言語、キャンバス、通知';

  @override
  String get set_bkScopeInput => '入力と補完';

  @override
  String get set_bkScopeInputSub => 'ホイール重み、関連タグ、補完';

  @override
  String get set_bkScopeProtect => 'プライバシーと生成保護';

  @override
  String get set_bkScopeProtectSub => 'メタデータ、確認、高コスト警告、間隔';

  @override
  String get set_bkScopeShortcuts => 'ショートカット';

  @override
  String set_bkScopeShortcutsSub(Object n) {
    return '全 $n 件';
  }

  @override
  String get set_bkResetBtn => '選択した項目を既定に戻す…';

  @override
  String get set_bkResetHint => '先にバックアップし、元に戻せます';

  @override
  String get set_bkResetTitle => '選択した設定を既定に戻しますか？';

  @override
  String set_bkResetBody(Object scopes) {
    return '$scopes が既定に戻ります。現在の設定は先にバックアップされます。';
  }

  @override
  String get set_bkAuto => '自動バックアップ';

  @override
  String get set_bkAutoSub => '直近 5 件を保持';

  @override
  String get set_bkKindImport => 'インポート前';

  @override
  String get set_bkKindReset => 'リセット前';

  @override
  String get set_bkKindUpgrade => '更新前';

  @override
  String get set_bkNoBackups => 'バックアップはまだありません';

  @override
  String set_bkRestoreTitle(Object name) {
    return '「$name」のバックアップに戻しますか？';
  }

  @override
  String get set_bkRestoreBody => '現在の設定は先にバックアップされます。';

  @override
  String get set_abDesc => 'バージョン、更新、診断。';

  @override
  String set_abNew(Object version) {
    return '新しいバージョン $version';
  }

  @override
  String get set_abLatest => '最新です';

  @override
  String get set_abChecking => '更新を確認中…';

  @override
  String get set_abCheckFailed => '更新の確認に失敗';

  @override
  String set_abDownloading(Object pct) {
    return 'ダウンロード中 $pct';
  }

  @override
  String set_abChecked(Object when) {
    return '最終確認 $when';
  }

  @override
  String set_abNotes(Object version) {
    return '$version の更新内容';
  }

  @override
  String get set_abInstall => 'ダウンロードしてインストール';

  @override
  String get set_abChangelog => '更新履歴';

  @override
  String get set_abPrerelease => 'プレリリースを含める';

  @override
  String get set_abCheck => '更新を確認';

  @override
  String get set_abDiag => '診断';

  @override
  String get set_abLog => 'ログファイルに記録';

  @override
  String get set_abLogSub => '問題調査時にオン。API キーや認証情報は含みません';

  @override
  String get set_abLogDir => 'ログフォルダー';

  @override
  String get set_abCopyDiag => '診断情報をコピー';

  @override
  String get set_abCopyDiagSub => 'バージョン、システム、GPU、各サービスの状態';

  @override
  String get set_abProject => 'プロジェクト';

  @override
  String get set_abRepo => 'ソースコード';

  @override
  String get set_abUpstream => '元のプロジェクト';

  @override
  String get set_abUpstreamSub => 'NAI Launcher をもとに開発。原作者の表記を保持';

  @override
  String get set_abFonts => 'フォントと素材';

  @override
  String get set_abLicenses => 'ライセンス';

  @override
  String get set_abView => '表示';

  @override
  String get set_abSystem => 'システム';

  @override
  String set_srQuoted(Object query) {
    return '「$query」';
  }

  @override
  String get set_srBalance => 'Anlas 残高';

  @override
  String get set_srSubscription => 'サブスクリプションと Anlas';

  @override
  String get set_agEnable => '有効にする';

  @override
  String get set_agDisable => '無効にする';

  @override
  String get set_listSep => '、';

  @override
  String get set_on => 'オン';

  @override
  String get set_off => 'オフ';

  @override
  String get set_unitSeconds => '秒';

  @override
  String get set_unsavedAgent => 'Agent の指示に未保存の変更があります';

  @override
  String get set_accUnread => '未取得';

  @override
  String get set_accBalanceUnread => '残高は未取得';

  @override
  String get set_agBase => '内蔵システムプロンプト';

  @override
  String set_agBaseGlobalState(Object state) {
    return '全体：$state';
  }

  @override
  String set_agBaseWsState(Object name, Object state) {
    return 'ワークスペース「$name」：$state';
  }

  @override
  String get set_agBaseBuiltin => '内蔵';

  @override
  String get set_agBaseCustom => 'カスタム';

  @override
  String get set_agBaseInherit => '全体を使用';

  @override
  String get set_agBaseOwn => '個別設定';

  @override
  String get set_agBaseEdit => '編集';

  @override
  String get set_agBaseCollapse => '閉じる';

  @override
  String get set_agScopeGlobal => '全体';

  @override
  String set_agScopeWorkspace(Object name) {
    return 'ワークスペース · $name';
  }

  @override
  String get set_agBaseUseGlobalOn => 'このワークスペースは全体のプロンプトを使用。オフにすると個別に編集できます';

  @override
  String get set_agBaseUseGlobalOff => 'このワークスペースは個別のプロンプトを使用。オンにすると全体に戻ります';

  @override
  String get set_agBaseHint =>
      'カスタム内容で内蔵システムプロンプトを置き換え、「内蔵プロンプトの前」の内容に続けます。ツールマップはアプリが追加します。全体とワークスペースは別々に保存され、既存のチャットはそのままです。';

  @override
  String get set_agBaseRestore => '内蔵に戻す';

  @override
  String get set_agBaseRestoreTitle => '内蔵システムプロンプトに戻しますか？';

  @override
  String get set_agBaseRestoreBody =>
      '全体のカスタム内容を内蔵システムプロンプトに戻します。以前の内容はプロンプト履歴に残ります。ワークスペース個別のプロンプトは変わりません。';

  @override
  String get set_agBaseSwitchTitle => '内蔵システムプロンプトの変更を破棄しますか？';

  @override
  String get set_agBaseSwitchBody => '範囲を切り替えると未保存の変更は失われます。';

  @override
  String get set_agBaseSaving => '保存中…';

  @override
  String get set_agBaseFailed =>
      '保存できませんでした。ワークスペースが変わったか、書き込みに失敗しました。変更は残っています。';

  @override
  String get set_agMcpUnchecked => '未確認';

  @override
  String get set_agInstructionsSaving => '指示を保存中…';

  @override
  String get set_agInstructionsFailed =>
      '指示を保存できませんでした。保存済みの内容が変更されたか、書き込みに失敗しました。下書きは保持されています。再試行してください。';

  @override
  String get set_agOrderSkills => 'スキルカタログ';

  @override
  String get set_agQuick => 'クイックメッセージ';

  @override
  String get set_agQuickSub => 'サイドバーのウェルカム画面のカード。クリックで入力欄に入れるか、すぐ送信します。';

  @override
  String set_agQuickShown(int shown, int total) {
    return 'ウェルカム画面に $shown / $total 件';
  }

  @override
  String get set_agQuickEmpty => 'クイックメッセージがありません。ウェルカム画面には表示されません。';

  @override
  String get set_agQuickSendBadge => 'すぐ送信';

  @override
  String get set_agQuickHidden => '非表示';

  @override
  String get set_agQuickUp => '上へ';

  @override
  String get set_agQuickDown => '下へ';

  @override
  String get set_agQuickEditOne => '編集';

  @override
  String get set_agQuickRemove => '削除';

  @override
  String get set_agQuickAdd => 'クイックメッセージを追加';

  @override
  String get set_agQuickRestore => 'デフォルトに戻す';

  @override
  String get set_agQuickRestoreConfirm => '内蔵の 4 件に戻しますか？追加・編集した内容は置き換えられます。';

  @override
  String set_agQuickRemoveConfirm(String title) {
    return 'クイックメッセージ「$title」を削除しますか？';
  }

  @override
  String get set_agQuickNew => 'クイックメッセージを追加';

  @override
  String get set_agQuickEditTitle => 'クイックメッセージを編集';

  @override
  String get set_agQuickIcon => 'アイコン';

  @override
  String get set_agQuickTitle => 'タイトル';

  @override
  String get set_agQuickHint => '説明（任意）';

  @override
  String get set_agQuickPrompt => 'Agent に送る内容';

  @override
  String get set_agQuickSend => 'クリックですぐ送信（オフなら入力欄に入れる）';

  @override
  String get set_agSkills => 'スキル';

  @override
  String get set_agSkillsSub =>
      '通常は名前と一行の説明だけがプロンプトに入り、タスクに合うときだけ Agent が完全な説明を読み込みます。';

  @override
  String set_agSkillsLoaded(Object n) {
    return '$n 件読み込み済み';
  }

  @override
  String get set_agSkillBuiltin => '内蔵';

  @override
  String get set_agSkillGlobal => '全体';

  @override
  String get set_agSkillWorkspace => 'ワークスペース';

  @override
  String get set_agSkillAuto => '自動';

  @override
  String get set_agSkillManual => '手動のみ';

  @override
  String get set_agSkillAutoTip =>
      'プロンプトには名前と一行説明だけが入り、作業が合うと Agent が自分で全文を読みます。';

  @override
  String get set_agSkillManualTip =>
      'プロンプトに入らないため Agent は自分では使いません。チャット欄で /skill:名前 と入力すると呼び出します。';

  @override
  String get set_agWorkspaceRulesSub =>
      'このワークスペースだけに適用する追加ルールです。ワークスペース内の instructions.md に保存され、全体の指示の後に追加されます。「編集」でシステムのエディターが開きます。空なら何も追加しません。';

  @override
  String get set_agSkillDescNaiPrompt =>
      'Write or revise NovelAI prompts in the Studio draft - main/negative prompts, characters, blocks and weights - following the rules of the current model (V4/V4.5 or V5). Read before changing prompt text.';

  @override
  String get set_agSkillDescNaiStudio =>
      'Operate NAI Studio drafts, images, generation, semantic search, gallery/history, references, prompt blocks, style exploration, image tools, snapshots and preferences. Read before Studio operations beyond studio_context.';

  @override
  String get set_agSkillView => '表示';

  @override
  String get set_agSkillAdd => 'スキルフォルダーを追加';

  @override
  String get set_agSkillNew => '新規スキル';

  @override
  String get set_agSkillSlashHint => 'チャット欄で /skill:名前 を入力すると手動で呼び出せます';

  @override
  String get set_agSkillTrust =>
      'スキルは Agent にファイルの読み書きやコマンド実行を指示できます。信頼できるものだけを追加してください。';

  @override
  String get set_agSkillNotLoaded => '未読み込み';

  @override
  String get set_agSkillShadowed => '同じ名前のスキルに置き換えられました';

  @override
  String get set_agSkillErrDescription => 'SKILL.md に description がなく、読み込まれません';

  @override
  String get set_agSkillErrName => '名前に使えるのは小文字、数字、単一のハイフンのみで、最大 64 文字です';

  @override
  String get set_agSkillErrMissing => 'フォルダーに SKILL.md がありません';

  @override
  String get set_agSkillErrParse => 'SKILL.md のフロントマターを読み取れません';

  @override
  String get set_agSkillOpenFolder => 'フォルダーを開く';

  @override
  String get set_agSkillRemove => 'スキルを削除';

  @override
  String get set_agSkillCopy => '自分のスキルとしてコピー';

  @override
  String get set_agSkillReadOnly =>
      '内蔵スキルはアプリの更新に合わせて更新され、直接編集できません。コピーすると、同じ名前の全体スキルが代わりに使われます。';

  @override
  String get set_agSkillAddTitle => 'スキルフォルダーを追加';

  @override
  String get set_agSkillPlace => '場所';

  @override
  String set_agSkillPlaceWorkspace(Object name) {
    return '現在のワークスペース「$name」';
  }

  @override
  String get set_agSkillMode => '呼び出し方法';

  @override
  String get set_agSkillCopyNote =>
      'Agent データフォルダーにコピーされるため、元のフォルダーの以降の変更は自動で同期されません。';

  @override
  String set_agSkillExists(Object name) {
    return '「$name」はすでに存在します。先に削除するか名前を変更してください。';
  }

  @override
  String get set_agSkillPlaces => 'スキルの場所';

  @override
  String get set_agSkillPlacesTip =>
      '各サブフォルダーに SKILL.md を1つ置きます。名前が重複する場合はワークスペース、全体、内蔵の順に優先されます。';

  @override
  String get set_agContext => '常時コンテキスト';

  @override
  String get set_agContextPrompt => 'システムプロンプト';

  @override
  String set_agContextSkills(Object n) {
    return 'スキルカタログ · $n 件';
  }

  @override
  String set_agContextTools(Object n) {
    return 'デフォルトツール · $n 件';
  }

  @override
  String get set_agContextTip => 'トークン · 文字数から推定';

  @override
  String get set_agFinalPending =>
      '実行中のセッションはありません。以下は Studio が組み立てる部分です。セッション開始時には Pi がスキルカタログ、作業ディレクトリ、MCP サーバー一覧も追加します。';

  @override
  String get ag_tabChat => 'チャット';

  @override
  String get ag_tabShelf => '出力';

  @override
  String get ag_tabMemory => '指示';

  @override
  String get ag_newChat => '新しいチャット';

  @override
  String get ag_more => 'その他';

  @override
  String get ag_close => '折りたたむ';

  @override
  String get ag_chatsSearch => 'チャットとワークスペースを検索';

  @override
  String get ag_chatsSwitchWorkspace => 'ワークスペースを切り替え';

  @override
  String get ag_chatsNewWorkspace => '新規ワークスペース';

  @override
  String get ag_chatsNoMatch => '一致するチャットがありません';

  @override
  String get ag_chatWaiting => '確認待ち';

  @override
  String get ag_chatRunning => '実行中';

  @override
  String get ag_menuRenameChat => 'チャットの名前を変更';

  @override
  String get ag_menuRenameWorkspace => 'ワークスペースの名前を変更';

  @override
  String get ag_menuOpenFolder => 'ワークスペースのフォルダーを開く';

  @override
  String get ag_menuCompact => 'コンテキストを圧縮';

  @override
  String get ag_menuExport => 'チャットをエクスポート';

  @override
  String get ag_menuSettings => 'Agent 設定';

  @override
  String get ag_name => '名前';

  @override
  String get ag_save => '保存';

  @override
  String get ag_cancel => 'キャンセル';

  @override
  String get ag_failed => '操作に失敗しました';

  @override
  String get ag_greetMorning => 'おはようございます、今日は何を描きますか？';

  @override
  String get ag_greetAfternoon => 'こんにちは、今日は何を描きますか？';

  @override
  String get ag_greetEvening => 'こんばんは、今日は何を描きますか？';

  @override
  String get ag_greetHint => 'Agent はまず下書きを読み、Anlas を使う前には必ず確認します。';

  @override
  String get ag_draftEyebrow => '現在の下書き';

  @override
  String ag_draftCounts(int characters, int blocks, int references) {
    return 'キャラ $characters 体 · ブロック $blocks 個 · 参照画像 $references 枚';
  }

  @override
  String get ag_taskReview => '下書きを確認';

  @override
  String get ag_taskReviewHint => '競合・重複・モデルが無視する書き方を探します';

  @override
  String get ag_taskReviewPrompt =>
      '現在の下書きとパラメータを確認し、競合・重複・現在のモデルが無視する書き方を指摘してください。まだ変更はしないでください。';

  @override
  String get ag_taskAnalyze => '参照画像を分析';

  @override
  String get ag_taskAnalyzeHint => '画風・構図・使えるタグに分解します';

  @override
  String get ag_taskAnalyzePrompt =>
      '添付した参照画像を分析してください。画風、構図、光と影、そのまま使えるタグを挙げて、まだ生成はしないでください。';

  @override
  String get ag_taskVariants => 'バリエーション';

  @override
  String get ag_taskVariantsHint => '1 か所だけ変えて数枚比較します';

  @override
  String get ag_taskVariantsPrompt =>
      '現在の下書きをもとに、1 か所だけ変えたバリエーションを数組作ってください。変更内容と費用を先に伝えて、確認してから生成してください。';

  @override
  String get ag_taskBlocks => 'ブロックを整理';

  @override
  String get ag_taskBlocksHint => 'よく使う断片をブロックライブラリへ保存します';

  @override
  String get ag_taskBlocksPrompt =>
      '現在の下書きの中で、再利用できるブロックに向く断片を探して提案してください。まだ変更はしないでください。';

  @override
  String get ag_quickTitle => 'クイックメッセージ';

  @override
  String get ag_quickEdit => 'クイックメッセージを編集';

  @override
  String get ag_quickSends => 'クリックですぐ送信';

  @override
  String get ag_modeBypass => 'フルアクセス';

  @override
  String get ag_modeBypassHint => '確認せずすべて直接実行。Anlas を使う操作だけは確認します';

  @override
  String get ag_bypassConfirmTitle => 'フルアクセスに切り替えますか？';

  @override
  String get ag_bypassConfirmBody =>
      'Agent は確認せずにファイルの変更、コマンドの実行、未知のツールの呼び出しを行い、ワークスペース外のファイルも操作できます。Anlas を使う操作は引き続き確認します。信頼できる作業のときだけ使ってください。';

  @override
  String get ag_bypassConfirmOk => '切り替える';

  @override
  String get ag_bypassConfirmSilence => '今後表示しない';

  @override
  String get ag_menuDeleteChat => 'チャットを削除';

  @override
  String get ag_menuDeleteWorkspace => 'ワークスペースを削除';

  @override
  String get ag_delete => '削除';

  @override
  String get ag_deleteWorkspaceTitle => 'ワークスペースを削除しますか？';

  @override
  String ag_deleteWorkspaceBody(String name) {
    return 'ワークスペース「$name」とその中のチャットはすべてごみ箱に移動し、元に戻せます。生成した画像はギャラリーと履歴に残ります。';
  }

  @override
  String ag_chatDeleted(String title) {
    return '「$title」を削除しました';
  }

  @override
  String ag_workspaceDeleted(String name) {
    return 'ワークスペース「$name」を削除しました';
  }

  @override
  String get ag_chatsContent => 'メッセージ内';

  @override
  String get ag_chatsSearching => 'メッセージを検索中…';

  @override
  String get ag_imageVibe => 'Vibe に設定';

  @override
  String get ag_imageReference => '精密参照に設定';

  @override
  String get ag_imageParams => 'パラメータを読み込む';

  @override
  String get ag_imageFolder => 'フォルダーで表示';

  @override
  String get ag_imageVibeDone => 'Vibe 参照に追加しました';

  @override
  String get ag_imageReferenceDone => '精密参照に設定しました';

  @override
  String get ag_imageParamsDone => '生成パラメータを読み込みました';

  @override
  String get ag_usageAnlas => '画像生成の費用（概算）';

  @override
  String get ag_deleteAgain => 'もう一度クリックで削除';

  @override
  String get ag_sloganBase =>
      '顔料を練っています…\n画師帳をめくっています…\nタグを数えています…\n重みを調整中…\n構図を確認中…\nキャラにポーズを取らせています…\n鉛筆を削っています…\n色温度を整えています…\n筆を選んでいます…\nパレットに絵の具を出しています…\n一歩引いて全体を見ています…\n下塗り中…\nアイデアを整理中…\n資料を探しています…\n比率を測っています…\n別の角度から考えています…\n線を整えています…\nコーヒーをひと口…\n光と影に相談中…\n余白にスケッチ中…';

  @override
  String get ag_sloganEgg =>
      'AI に手を正しく描くよう説得中…\n指を一本多く描いて…消しました\nAnlas は使っていません（今のところ）\nキャンバスの隅にサイン…やっぱり消す\nKrita と目配せ中…\n猫耳のいい角度を探しています…\n六本目の指で数えるのをやめました…\nmasterpiece, best quality, お願い…';

  @override
  String get ag_sloganThink => '考え中…\n頭の中で一度描いています…\n別の角度から考えています…\n段取りを整理中…';

  @override
  String get ag_sloganRead =>
      '資料を読んでいます…\nタグ辞典を引いています…\n下書きを確認中…\n過去作をめくっています…';

  @override
  String get ag_sloganRun => 'コマンドを打っています…\nターミナルを走らせています…\nスクリプト待ち…';

  @override
  String get ag_sloganImage =>
      '絵をじっと見ています…\n細部を観察中…\nキャラの人数を数えています…\n筆致を近くで見ています…';

  @override
  String get ag_sloganWrite => '筆を入れています…\nプロンプトを書き換え中…\n一筆描き直しています…\n重みを調整中…';

  @override
  String get ag_sloganGen =>
      '色を塗っています…\nGPU に食事中…\n絵の具がまだ乾いていません…\nキャンバスを乾かしています…';

  @override
  String get ag_sloganExternal => '外部ツールと合言葉を交換中…\n返事待ち…';

  @override
  String get ag_foldDone => '処理済み';

  @override
  String ag_foldTimes(String label, int count) {
    return '$label $count 回';
  }

  @override
  String get ag_kindThink => '思考';

  @override
  String get ag_kindRead => '読み取り';

  @override
  String get ag_kindRun => 'コマンド';

  @override
  String get ag_kindImage => '画像確認';

  @override
  String get ag_kindWrite => '編集';

  @override
  String get ag_kindGen => '生成';

  @override
  String get ag_kindExternal => '外部ツール';

  @override
  String get ag_kindAsk => '確認';

  @override
  String ag_limitTitle(int count) {
    return '1 回のタスクのステップ上限（$count）に達しました';
  }

  @override
  String get ag_limitBody => '進捗は保存済みです。「続ける」で続きから再開できます。上限は設定で変更できます。';

  @override
  String get ag_limitContinue => '続ける';

  @override
  String get ag_limitAdjust => '上限を変更';

  @override
  String get ag_continueMessage => '続けて';

  @override
  String get ag_diffExpand => 'すべて表示';

  @override
  String get ag_diffCollapse => '折りたたむ';

  @override
  String ag_readImages(int count) {
    return '画像確認 · $count 枚';
  }

  @override
  String ag_turnTook(String time) {
    return '所要 $time';
  }

  @override
  String ag_turnAnlas(String anlas) {
    return '$anlas Anlas';
  }

  @override
  String ag_turnChanges(int count) {
    return '変更 $count 件';
  }

  @override
  String ag_turnTools(int count) {
    return 'ツール $count 回';
  }

  @override
  String ag_turnTokens(String input, String output) {
    return '入力 $input · 出力 $output トークン';
  }

  @override
  String get ag_settingsTitle => 'アプリ設定';

  @override
  String get ag_settingsGo => '設定を開く';

  @override
  String ag_tagCopied(String tag) {
    return '$tag をコピーしました';
  }

  @override
  String ag_tagCount(String count) {
    return '$count 件';
  }

  @override
  String ag_galleryFavorite(int count) {
    return '$count 枚をお気に入りにしました';
  }

  @override
  String ag_galleryUnfavorite(int count) {
    return '$count 枚のお気に入りを外しました';
  }

  @override
  String ag_galleryTags(int count) {
    return '$count 枚のタグを変更しました';
  }

  @override
  String ag_galleryMove(int count, String target) {
    return '$count 枚を「$target」へ移動しました';
  }

  @override
  String ag_galleryCopy(int count, String target) {
    return '$count 枚を「$target」へコピーしました';
  }

  @override
  String ag_galleryDelete(int count) {
    return '$count 枚をゴミ箱へ移しました';
  }

  @override
  String ag_galleryRestore(int count) {
    return '$count 枚を復元しました';
  }

  @override
  String ag_galleryCollectionAdd(int count, String target) {
    return '$count 枚をコレクション「$target」に追加しました';
  }

  @override
  String ag_galleryCollectionRemove(int count, String target) {
    return '$count 枚をコレクション「$target」から外しました';
  }

  @override
  String ag_galleryExport(int count) {
    return '$count 枚を書き出しました';
  }

  @override
  String ag_galleryMore(int count) {
    return '+$count';
  }

  @override
  String get ag_compacted => 'これまでの会話を圧縮しました';

  @override
  String get ag_compactedAuto => 'コンテキストがいっぱいに近いため、これまでの会話を自動で圧縮しました';

  @override
  String ag_compactedTokens(String tokens) {
    return '元 $tokens トークン';
  }

  @override
  String get ag_compactedShow => '要約を見る';

  @override
  String get ag_compactedHide => '要約を閉じる';

  @override
  String get ag_editResend => '送信';

  @override
  String get ag_editHint => '送信すると、このメッセージ以降の会話は置き換えられます';

  @override
  String get ag_editRemoveImage => 'この画像を外す';

  @override
  String get set_agTrash => 'ごみ箱';

  @override
  String get set_agTrashSub =>
      '削除したチャット、ワークスペース、Skill はここに入り、元に戻せます。完全に削除すると戻せません。';

  @override
  String get set_agTrashManage => '管理';

  @override
  String set_agTrashSummary(int count, String size) {
    return '$count 件 · $size';
  }

  @override
  String get set_agTrashEmpty => 'ごみ箱は空です';

  @override
  String get set_agTrashAll => 'すべて';

  @override
  String get set_agTrashChats => 'チャット';

  @override
  String get set_agTrashWorkspaces => 'ワークスペース';

  @override
  String get set_agTrashSkills => 'Skill';

  @override
  String get set_agTrashRestore => '元に戻す';

  @override
  String get set_agTrashPurge => '完全に削除';

  @override
  String get set_agTrashPurgeAll => 'ごみ箱を空にする';

  @override
  String get set_agTrashPurgeTitle => '完全に削除しますか？';

  @override
  String set_agTrashPurgeBody(String name) {
    return '「$name」はディスクから削除され、元に戻せません。';
  }

  @override
  String set_agTrashPurgeAllBody(int count) {
    return 'ごみ箱の $count 件はディスクから削除され、元に戻せません。';
  }

  @override
  String set_agTrashRestored(String name) {
    return '「$name」を元に戻しました';
  }

  @override
  String set_agTrashPurged(String name) {
    return '「$name」を完全に削除しました';
  }

  @override
  String get set_agTrashNeedWorkspace =>
      '所属するワークスペースもごみ箱にあります。先にワークスペースを元に戻してください。';

  @override
  String get set_agTrashRestoreFailed => '元に戻せません：同じ名前のものがすでにあります';

  @override
  String get set_agTrashGoneWorkspace => '削除済みワークスペース';

  @override
  String set_agSkillRemoveBody(String name) {
    return '「$name」はごみ箱に移動します。Agent 設定の「ごみ箱」から元に戻すか完全に削除できます。';
  }

  @override
  String get set_agSkillName => '名前';

  @override
  String get set_agSkillNewHelp =>
      '小文字・数字・ハイフンのみ（例：watercolor-style）。作成後にフォルダーが開くので、中の SKILL.md を編集してください。';

  @override
  String get set_agSkillCreate => '作成';

  @override
  String get set_agSkillAddConfirm => '追加';

  @override
  String set_agPromptStats(String chars, String tokens) {
    return '$chars 文字 · 約 $tokens トークン';
  }

  @override
  String get set_agFinalLive => '現在のチャットが実際にモデルへ送る完全なシステムプロンプトです。';

  @override
  String get set_agBuiltinSub => 'Studio 内蔵の基本プロンプト。バージョンとともに更新されます。';

  @override
  String get set_agMcpEditTitle => 'MCP サーバーを編集';

  @override
  String get set_agTabGeneral => '一般';

  @override
  String get set_agTabTools => 'ツールと拡張';

  @override
  String get blocks_viewMasonry => 'メイソンリー';

  @override
  String get blocks_groupByFolder => 'フォルダごとに表示';

  @override
  String get mp_bodyTag => 'ボディ';

  @override
  String get mp_headerTag => 'ヘッダー';

  @override
  String get ag_recent => '最近';

  @override
  String get ag_you => 'あなた';

  @override
  String get ag_edit => '編集';

  @override
  String get ag_copy => 'コピー';

  @override
  String get ag_copied => 'コピーしました';

  @override
  String get ag_regenerate => '回答を再生成';

  @override
  String get ag_starting => 'チャットを開いています';

  @override
  String get ag_waitingSlot => 'リクエスト枠を待機中';

  @override
  String get ag_waitingYou => '対応待ち';

  @override
  String get ag_stepFailed => '失敗';

  @override
  String get ag_stepArguments => '引数';

  @override
  String get ag_stepResult => '結果';

  @override
  String ag_stepsMore(int count) {
    return 'あと $count ステップ';
  }

  @override
  String get ag_tool_studio_context => '現在の下書きを読み取り';

  @override
  String get ag_tool_image_read => '画像を表示';

  @override
  String get ag_tool_prompt_update => 'プロンプトを書き換え';

  @override
  String get ag_tool_snapshot => '下書きスナップショット';

  @override
  String get ag_tool_wiki_query => '百科を検索';

  @override
  String get ag_tool_tag_query => 'タグを検索';

  @override
  String get ag_tool_block_query => 'ブロックを検索';

  @override
  String get ag_tool_block_manage => 'ブロックを整理';

  @override
  String get ag_tool_settings_read => '設定を読み取り';

  @override
  String get ag_tool_settings_update => '設定を変更';

  @override
  String get ag_tool_explore_manage => '画風探索';

  @override
  String get ag_tool_generation_prepare => '生成の準備';

  @override
  String get ag_tool_generation_run => '画像を生成';

  @override
  String get ag_tool_generation_cancel => '生成をキャンセル';

  @override
  String get ag_tool_gallery_query => 'ギャラリーを検索';

  @override
  String get ag_tool_gallery_manage => 'ギャラリーを整理';

  @override
  String get ag_tool_reference_manage => '参照画像を設定';

  @override
  String get ag_tool_reference_library => '参照画像ライブラリ';

  @override
  String get ag_tool_image_tool => '画像ツール';

  @override
  String get ag_tool_studio_search => 'セマンティック検索';

  @override
  String get ag_tool_image_generate => 'バリエーション / エンハンス';

  @override
  String get ag_tool_ask_user => 'あなたに質問';

  @override
  String get ag_tool_read => 'ファイルを読み取り';

  @override
  String get ag_tool_write => 'ファイルを書き込み';

  @override
  String get ag_tool_edit => 'ファイルを変更';

  @override
  String get ag_tool_bash => 'コマンドを実行';

  @override
  String get ag_field_prompt => 'ベースプロンプト';

  @override
  String get ag_field_negative => 'ネガティブプロンプト';

  @override
  String get ag_field_character => 'キャラクタープロンプト';

  @override
  String get ag_field_characterNegative => 'キャラ ネガティブ';

  @override
  String get ag_diffApplied => '書き込み済み';

  @override
  String get ag_diffUndone => '元に戻しました';

  @override
  String ag_changeSummary(int count) {
    return '今回の変更 · $count か所';
  }

  @override
  String get ag_diffUndoAll => 'すべて元に戻す';

  @override
  String get ag_paramTitle => '生成パラメータ';

  @override
  String ag_paramCount(int count) {
    return '$count 項目';
  }

  @override
  String get ag_paramSize => 'サイズ';

  @override
  String get ag_paramTransparent => '透過背景';

  @override
  String get ag_paramNone => 'なし';

  @override
  String get ag_positionTitle => 'キャラクター位置';

  @override
  String get ag_positionApplied => '調整済み';

  @override
  String get ag_positionNone => '未指定';

  @override
  String get ag_positionAiHint => 'AI おまかせ中：座標は使われず、モデルが配置します。';

  @override
  String ag_positionRestSame(int count) {
    return 'ほか $count 人は変更なし';
  }

  @override
  String ag_positionAllSame(int count) {
    return '$count 人とも変更なし';
  }

  @override
  String get ag_posTopLeft => '左上';

  @override
  String get ag_posTop => '上';

  @override
  String get ag_posTopRight => '右上';

  @override
  String get ag_posLeft => '左';

  @override
  String get ag_posCenter => '中央';

  @override
  String get ag_posRight => '右';

  @override
  String get ag_posBottomLeft => '左下';

  @override
  String get ag_posBottom => '下';

  @override
  String get ag_posBottomRight => '右下';

  @override
  String get ag_positionNudge => '微調整';

  @override
  String get ag_positionNew => '追加';

  @override
  String get ag_diffLocked => '下書きが再変更されました';

  @override
  String get ag_diffUndo => '元に戻す';

  @override
  String ag_diffCounts(int added, int removed) {
    return '+$added −$removed';
  }

  @override
  String get ag_outputs => '今回の出力';

  @override
  String ag_anlasSpent(String anlas) {
    return '$anlas Anlas 使用';
  }

  @override
  String get ag_imageReveal => '履歴で表示';

  @override
  String get ag_imageAttach => '入力欄に添付';

  @override
  String get ag_imageZoom => '拡大して表示';

  @override
  String ag_askHint(int count) {
    return '1–$count で選択';
  }

  @override
  String get ag_askOther => 'その他の案…';

  @override
  String get ag_askSubmit => '回答';

  @override
  String get ag_askSkip => 'スキップ';

  @override
  String ag_approvalTitle(String tool) {
    return '許可が必要 · $tool';
  }

  @override
  String ag_gateTitle(String action) {
    return '確認が必要 · $action';
  }

  @override
  String ag_gateText2img(int count) {
    return '$count 枚生成';
  }

  @override
  String ag_gateImg2img(int count) {
    return '画像から $count 枚';
  }

  @override
  String ag_gateInpaint(int count) {
    return 'インペイント $count 枚';
  }

  @override
  String ag_gateVariations(int count) {
    return 'バリエーション $count 枚';
  }

  @override
  String get ag_gateEnhance => 'エンハンス';

  @override
  String get ag_gateModelSize => 'モデル · サイズ';

  @override
  String get ag_gateRequests => 'リクエスト';

  @override
  String ag_gateRequestsValue(int requests, int batch) {
    return '$requests 回 × $batch 枚';
  }

  @override
  String get ag_gateUnit => '1 回あたり';

  @override
  String get ag_gateEncoding => '参照画像のエンコード';

  @override
  String get ag_gateAccount => 'アカウント';

  @override
  String ag_gateTotal(String balance) {
    return '合計 · 残高 $balance';
  }

  @override
  String get ag_gateTotalNoBalance => '合計';

  @override
  String get ag_gateConfirm => '確認して生成';

  @override
  String get ag_gateConfirmTool => '確認して実行';

  @override
  String get ag_gateChanged => '設定または見積もりが変わりました。Agent に再準備を依頼してください';

  @override
  String get ag_gateExpired => '見積もりが失効しました';

  @override
  String get ag_gateEstimate => '見積もりです。実際の請求額はサーバーで決まります';

  @override
  String get ag_placeholder => 'Agent への指示 · @ で参照 · / でスキル';

  @override
  String get ag_dropHint => 'ドロップしてこのメッセージに添付';

  @override
  String ag_importing(int count) {
    return '$count 枚の画像を追加中…';
  }

  @override
  String get ag_attach => '画像を追加';

  @override
  String get ag_attachFile => 'ファイルを選択…';

  @override
  String get ag_attachCanvas => 'キャンバスの現在の画像を添付';

  @override
  String get ag_attachPaste => 'クリップボードの画像を貼り付け';

  @override
  String get ag_mention => '参照';

  @override
  String get ag_attachmentRemove => '削除';

  @override
  String get ag_attachmentBroken => '読み込めません';

  @override
  String ag_imageInfoSteps(int count) {
    return '$count ステップ';
  }

  @override
  String ag_imageInfoRescale(String value) {
    return 'リスケール $value';
  }

  @override
  String ag_imageInfoSeed(String seed) {
    return 'シード $seed';
  }

  @override
  String ag_imageInfoCharacters(int count) {
    return 'キャラクター $count 人';
  }

  @override
  String get ag_send => '送信';

  @override
  String get ag_sendQueue => '待機列';

  @override
  String get ag_sendSteer => 'ガイドとして挿入';

  @override
  String get ag_sendQueueHint => '現在のタスクが終わってから処理します';

  @override
  String get ag_sendSteerHint => '次のモデルリクエストの前に挿入します';

  @override
  String get ag_stop => '停止';

  @override
  String get ag_noModel => 'ツール対応のモデルを選択してください';

  @override
  String get ag_queued => '待機';

  @override
  String get ag_steering => 'ガイド';

  @override
  String get ag_recovered => '前回未送信';

  @override
  String get ag_queueSteer => 'ガイドに変更';

  @override
  String get ag_queueEdit => '編集';

  @override
  String get ag_queueWithdraw => '取り消す';

  @override
  String get ag_queueRestore => '入力欄に戻す';

  @override
  String get ag_newContent => '最新メッセージへ';

  @override
  String get ag_modeReadonly => '閲覧のみ';

  @override
  String get ag_modeAsk => '確認';

  @override
  String get ag_modeAuto => '自動';

  @override
  String get ag_modeReadonlyHint => '閲覧と相談のみ。変更も生成もしません';

  @override
  String get ag_modeAskHint => '変更・コマンド・未知のツールは先に確認します';

  @override
  String get ag_modeAutoHint => 'ワークスペース内の通常の変更は自動実行。費用がかかる操作は確認します';

  @override
  String get ag_modelPicker => 'モデルを選択';

  @override
  String get ag_modelSettings => 'モデルと接続を管理…';

  @override
  String get ag_modelNone => 'モデル未選択';

  @override
  String get ag_thinkingTitle => '思考の強度 · 次の処理から適用';

  @override
  String get ag_thinkingFollow => 'モデル設定を使用';

  @override
  String get ag_thinkingUnsupported => 'このモデルには調整できる思考レベルがありません';

  @override
  String get ag_usageTitle => 'コンテキストと使用量';

  @override
  String get ag_usageContext => '現在のコンテキスト · 推定';

  @override
  String get ag_usageUnknown => 'モデルが使用量を返すと表示されます';

  @override
  String ag_usageRemaining(String tokens) {
    return '残り $tokens';
  }

  @override
  String get ag_usageSession => 'このチャットの累計';

  @override
  String get ag_usageInput => '入力';

  @override
  String get ag_usageOutput => '出力';

  @override
  String get ag_usageCacheRead => 'キャッシュ読み取り';

  @override
  String get ag_usageCacheWrite => 'キャッシュ書き込み';

  @override
  String get ag_usageTotal => '累計 tokens';

  @override
  String get ag_usageMessages => 'メッセージ · ツール呼び出し';

  @override
  String get ag_usageCost => '料金はプロバイダーの請求によります';

  @override
  String get ag_usageCompact => 'コンテキストを圧縮';

  @override
  String ag_shelfAll(int count) {
    return 'すべて $count';
  }

  @override
  String ag_shelfGenerated(int count) {
    return '生成 $count';
  }

  @override
  String ag_shelfAttachments(int count) {
    return '添付 $count';
  }

  @override
  String ag_shelfFiles(int count) {
    return 'ファイル $count';
  }

  @override
  String get ag_shelfFilesTitle => 'ファイル';

  @override
  String get ag_shelfHint => 'クリックで拡大 · キャンバスへドラッグ';

  @override
  String get ag_shelfEmpty => 'このチャットにはまだ出力がありません';

  @override
  String get ag_shelfEmptyHint => 'Agent が生成した画像、添付した画像、書き出したファイルがここにまとまります。';

  @override
  String get ag_memoryGlobal => '共通指示';

  @override
  String get ag_memoryWorkspace => 'ワークスペースのルール';

  @override
  String get ag_memorySkills => '有効なスキル';

  @override
  String get ag_memoryEmpty => '未設定';

  @override
  String get ag_memoryEdit => '編集';

  @override
  String get ag_memoryHint => 'この内容は毎回 Agent に渡されます。変更は次のメッセージから反映されます。';

  @override
  String get ag_mentionAll => 'すべて';

  @override
  String get ag_mentionDraft => '下書き';

  @override
  String get ag_mentionImages => '画像';

  @override
  String get ag_mentionBlocks => 'ブロック';

  @override
  String get ag_mentionTitle => 'このメッセージに参照';

  @override
  String get ag_mentionEmpty => '一致する内容がありません';

  @override
  String get ag_mentionSearchBlocks => 'ブロックを検索';

  @override
  String get ag_keySelect => '選択';

  @override
  String get ag_keyInsert => '挿入';

  @override
  String get ag_keyCategory => 'カテゴリ切替';

  @override
  String get ag_keyClose => '閉じる';

  @override
  String get ag_dismiss => '了解';

  @override
  String get ag_retry => '再試行';

  @override
  String get ag_initFailed => 'Agent を起動できませんでした';

  @override
  String get ag_toggle => 'NAI Agent';

  @override
  String get ag_yesterday => '昨日';

  @override
  String get ag_attachmentTag => '添付';

  @override
  String get ag_zoomClose => '閉じる';

  @override
  String get ag_thought => '思考済み';

  @override
  String get ag_thinkingLive => '思考中';

  @override
  String ag_thoughtChars(int count) {
    return '$count 文字';
  }

  @override
  String get mp_protocol => 'プロトコル';

  @override
  String get mp_test => 'テスト';

  @override
  String get mp_testing => 'テスト中…';

  @override
  String get mp_notChecked => '未確認';

  @override
  String get mp_rename => '名前を変更';

  @override
  String get mp_request => 'リクエスト';

  @override
  String get mp_requestSub => '全モデル共通';

  @override
  String get mp_timeout => 'タイムアウト';

  @override
  String get mp_timeoutHelp => '1 回のリクエストの最大待ち時間（10–600 秒）';

  @override
  String get mp_concurrency => '最大同時数';

  @override
  String get mp_concurrencyHelp => '同時に処理するリクエスト数（1–20）';

  @override
  String get mp_retry => '再試行';

  @override
  String get mp_retryHelp => '接続失敗や混雑時に再試行';

  @override
  String get mp_retryOff => 'オフ';

  @override
  String get mp_seconds => '秒';

  @override
  String get mp_countUnit => '件';

  @override
  String get mp_headers => 'カスタムヘッダー';

  @override
  String get mp_none => 'なし';

  @override
  String get mp_addHeader => 'ヘッダーを追加';

  @override
  String get mp_headerName => '名前';

  @override
  String get mp_value => '値';

  @override
  String get mp_added => '追加済み';

  @override
  String get mp_catalog => 'カタログ';

  @override
  String get mp_filter => '絞り込み';

  @override
  String get mp_manualAdd => '手動で追加';

  @override
  String get mp_dragHint => 'ドラッグで割り当ての既定順を変更';

  @override
  String get mp_noModels => 'モデルがありません';

  @override
  String get mp_noModelsSub => 'カタログから追加するか、モデル ID を入力';

  @override
  String get mp_manualHint => 'モデル ID を入力して Enter';

  @override
  String get mp_model => 'モデル';

  @override
  String get mp_alias => '表示名';

  @override
  String get mp_aliasHint => '例：fast';

  @override
  String get mp_context => 'コンテキスト';

  @override
  String get mp_maxOutput => '最大出力';

  @override
  String get mp_outputTooLarge => '出力はコンテキストを超えられません';

  @override
  String get mp_thinking => '思考';

  @override
  String get mp_levels => '調整可能な段階';

  @override
  String get mp_defaultLevel => '既定の段階';

  @override
  String get mp_defaultBadge => '既定';

  @override
  String get mp_followService => 'サービス既定';

  @override
  String get mp_reasoningProtocol => '思考プロトコル';

  @override
  String get mp_standard => '標準';

  @override
  String get mp_adaptive => '適応';

  @override
  String get mp_protocolNoReasoning => 'このプロトコルは思考調整に非対応';

  @override
  String get mp_unconfirmed => '未確認';

  @override
  String get mp_unsupported => '非対応';

  @override
  String get mp_capabilities => '機能';

  @override
  String get mp_capVision => '画像入力';

  @override
  String get mp_capTools => 'ツール呼び出し';

  @override
  String get mp_capSearch => 'ネイティブ検索';

  @override
  String get mp_bodyHeaders => 'ボディとヘッダー';

  @override
  String get mp_notAdded => '未追加';

  @override
  String get mp_field => 'ボディ';

  @override
  String get mp_header => 'ヘッダー';

  @override
  String get mp_testModel => 'このモデルをテスト';

  @override
  String get mp_copyId => 'モデル ID をコピー';

  @override
  String get mp_removeModel => 'モデルを削除';

  @override
  String mp_removeTitle(Object id) {
    return 'モデル「$id」を削除しますか？';
  }

  @override
  String get mp_removeBody => 'このモデルを使う機能は他のモデルに切り替わります。';

  @override
  String get mp_catalogId => 'モデル ID';

  @override
  String get mp_catalogCtx => 'コンテキスト';

  @override
  String get mp_catalogPrice => '入力 / 出力 · 100万';

  @override
  String mp_catalogFooter(Object n, Object total, Object when) {
    return '一致 $n 件 · 全 $total 件 · $when 取得';
  }

  @override
  String mp_catalogMore(Object n) {
    return '他に $n 件。絞り込みで探してください';
  }

  @override
  String get mp_catalogIdle => 'カタログ未取得';

  @override
  String get mp_catalogIdleSub => '保存済みの URL とキーでモデル一覧を取得';

  @override
  String get mp_catalogLoading => 'カタログを取得中…';

  @override
  String mp_catalogFailed(Object error) {
    return 'カタログを取得できません：$error';
  }

  @override
  String get mp_fetch => '一覧を取得';

  @override
  String get mp_noMatch => '一致するモデルがありません';

  @override
  String mp_picked(Object n) {
    return '$n 件選択';
  }

  @override
  String get mp_pickEmpty => '追加するモデルを選択';

  @override
  String get mp_pickHint => '機能・コンテキスト・思考段階はローカルカタログから入力され、追加後に調整できます。';

  @override
  String mp_addPicked(Object n) {
    return '$n 件のモデルを追加';
  }

  @override
  String get mp_new => '新規';

  @override
  String mp_unsaved(Object name, Object n) {
    return '$name に未保存の変更が $n 件';
  }

  @override
  String get mp_saving => '保存中…';

  @override
  String get mp_conflict => '他の場所で変更されました。最新値を統合しました。確認して保存してください';

  @override
  String get mp_saveFailed => '保存に失敗しました。変更は保持されています';

  @override
  String mp_invalid(Object n) {
    return '$n 件の修正が必要';
  }

  @override
  String get mp_leaveBody => 'サービス設定は保存されていません。移動すると変更は失われます。';

  @override
  String get mp_show => '表示';

  @override
  String get mp_hide => '隠す';

  @override
  String get mp_keyHintLocal => 'ローカルサービスは空欄可';

  @override
  String get mp_keyHint => 'このサービスのキーを入力';

  @override
  String get mp_pickerTitle => 'サービスを追加';

  @override
  String get mp_pickerSearch => 'ベンダー・プラットフォーム・ローカルを検索';

  @override
  String get mp_groupAll => 'すべて';

  @override
  String get mp_groupDomestic => '国内';

  @override
  String get mp_groupInternational => '海外';

  @override
  String get mp_groupAggregator => '集約';

  @override
  String get mp_groupLocal => 'ローカル';

  @override
  String get mp_groupDomesticFull => '中国のベンダー';

  @override
  String get mp_groupInternationalFull => '海外ベンダー';

  @override
  String get mp_groupAggregatorFull => '集約プラットフォーム';

  @override
  String get mp_groupLocalFull => 'ローカルとカスタム';

  @override
  String get mp_pickerFoot => 'URL とプロトコルはプリセットで入力されます。地域違いで同じベンダーを複数追加できます。';

  @override
  String get mp_pickerNext => '次へ：キーを入力';

  @override
  String get mp_duplicateKey => 'リクエストのフィールド名が重複しています。';

  @override
  String get mp_retryRange => '再試行回数は 0～3 回にしてください。';

  @override
  String get mp_catalogCacheFailed => 'モデル一覧のキャッシュを保存できませんでした。';

  @override
  String get mp_errorAuthentication => 'API キーが無効';

  @override
  String get mp_errorPermission => 'アクセスが拒否されました';

  @override
  String get mp_errorTimeout => 'リクエストがタイムアウト';

  @override
  String get mp_errorNetwork => '接続できません';

  @override
  String get mp_errorResponse => '無効なレスポンス';

  @override
  String get mp_errorHttp => 'リクエスト失敗';

  @override
  String get mp_errorRateLimit => 'レート制限を超過';

  @override
  String get ag_tool_prompt_set => 'プロンプトセット';

  @override
  String ag_psCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String ag_psPosition(int index, int count, String unit) {
    return '第$index$unit / 全$count$unit';
  }

  @override
  String get ag_psOverview => '一覧表示';

  @override
  String get ag_psSingle => '1件ずつ表示';

  @override
  String get ag_psPrompt => 'プロンプト';

  @override
  String get ag_psShared => '共通設定';

  @override
  String ag_psThisItem(String unit) {
    return 'この$unit';
  }

  @override
  String get ag_psMain => 'メインプロンプト';

  @override
  String ag_psCharacter(int index) {
    return 'キャラクター $index';
  }

  @override
  String get ag_psNegative => 'ネガティブ';

  @override
  String get ag_psImport => 'キャンバスに読み込む';

  @override
  String get ag_psImportTip => 'メインプロンプト・キャラクター・ネガティブを書き込みます。パラメータと参照画像は変わりません';

  @override
  String ag_psImported(String title) {
    return '「$title」をプロンプトに書き込みました';
  }

  @override
  String get ag_psGenerate => '生成';

  @override
  String get ag_psGenerating => '生成中';

  @override
  String ag_psRevision(int revision, int count) {
    return 'v$revision · $count件変更';
  }

  @override
  String get ag_psSaveBlock => 'ブロックとして保存';

  @override
  String ag_psSavedBlock(String title, int count) {
    return 'ブロック「$title」を保存しました · $count件';
  }

  @override
  String ag_psCopyItem(String unit) {
    return 'この$unitのプロンプトをコピー';
  }

  @override
  String get ag_psCopyAll => 'すべてコピー';

  @override
  String ag_psEditItem(String unit) {
    return 'この$unitの修正を Agent に頼む';
  }

  @override
  String ag_psEditDraft(String title, int index, String unit, String item) {
    return '「$title」の第$index$unit（$item）を修正：';
  }

  @override
  String ag_psTooManyCharacters(int count) {
    return '現在のモデルのキャラクターは最大 $count 人です';
  }

  @override
  String get ag_psNoCharacters => '現在のモデルはキャラクタープロンプトに対応していません';

  @override
  String get ag_psMissing => 'このカードのデータは見つかりません';

  @override
  String get startup_dataTitle => 'アプリのデータを準備できませんでした';

  @override
  String get startup_dataHelp =>
      'アプリのデータを準備できていません。既存のファイルを保持してください。内容の異なるファイルは統合も上書きもしません。データフォルダーをバックアップして確認し、ディスクの空き容量とアクセス権を確認してから再試行してください。';

  @override
  String get startup_dataCurrent => '現在のデータフォルダー';

  @override
  String get startup_dataLegacy => '以前のデータフォルダー';

  @override
  String get startup_dataOpenCurrent => '現在のフォルダーを開く';

  @override
  String get startup_dataOpenLegacy => '以前のフォルダーを開く';

  @override
  String get startup_dataDetails => 'エラーの詳細';

  @override
  String startup_dataActionFailed(String error) {
    return '操作に失敗しました：$error';
  }

  @override
  String get blocks_expandToText => 'テキストに展開';

  @override
  String get ag_answeredTitle => 'あなたへの質問 · 回答済み';

  @override
  String get ag_historyButton => '履歴';

  @override
  String get ag_historyTitle => '会話履歴';

  @override
  String get ag_historySearch => '発言とカードを検索…';

  @override
  String get ag_historyAll => 'すべて';

  @override
  String get ag_historyMine => '自分の発言';

  @override
  String get ag_historyCards => 'カード';

  @override
  String get ag_historyQuestions => '質問と回答';

  @override
  String get ag_historyEmpty => '一致する項目はありません';

  @override
  String get ag_historyBeforeCompaction => 'この部分は圧縮前です。クリックして要約を確認。';

  @override
  String get ag_historyAuto => '自動圧縮';

  @override
  String get ag_historyManual => '手動圧縮';

  @override
  String get ag_historyImageMessage => '画像メッセージ';

  @override
  String ag_historyAnswer(String answer) {
    return 'あなたの回答：$answer';
  }

  @override
  String get ag_historyPromptSet => 'プロンプトセット';

  @override
  String ag_historyImages(int count) {
    return '生成カード · $count 枚';
  }

  @override
  String get ag_historyPromptChange => 'プロンプトの変更';

  @override
  String get ag_historyParams => '生成設定';

  @override
  String get ag_historyPositions => 'キャラクター位置';

  @override
  String get ag_historySettings => '設定の変更';

  @override
  String get ag_historyGallery => 'ギャラリーカード';

  @override
  String get ag_historyChanges => '変更の要約';

  @override
  String get gen_translateTapOriginal => 'クリック：原文を表示';

  @override
  String get gen_translateTapTranslated => 'クリック：訳文を表示';

  @override
  String get gen_translateClearRestore => '翻訳ブロックを解除して原文に戻す';

  @override
  String get gen_translateClearRestoreSub => '通常の原文に戻します。元に戻せます';

  @override
  String get gen_translateCleared => '翻訳ブロックを原文に戻しました';

  @override
  String get gen_translateAdjust => '続けて翻訳を調整';

  @override
  String get gen_translateAdjustSub => 'この翻訳を続けて、分割・再翻訳・結合';

  @override
  String get gen_translateAdjustTitle => '翻訳の調整';

  @override
  String gen_translateAdjustContext(int count) {
    return 'この翻訳を継続 · $count ブロック';
  }

  @override
  String gen_translateAdjustSelected(int count) {
    return '$count ブロックを選択';
  }

  @override
  String get gen_translateAdjustCollapse => '折りたたむ / 展開';

  @override
  String get gen_translateAdjustIntro =>
      'この翻訳を続けます。左のブロックをクリックして参照できます。変更は元に戻せます。';

  @override
  String get gen_translateAdjustSplit => '再分割';

  @override
  String get gen_translateAdjustRetranslate => '選択を再翻訳';

  @override
  String get gen_translateAdjustMerge => '選択を結合';

  @override
  String get gen_translateAdjustSplitTemplate =>
      '現在のブロックを読み、参照ブロックを意味ごとに細分化し、原文を保持してください。';

  @override
  String get gen_translateAdjustRetranslateTemplate =>
      '現在のブロックを読み、原文を変えずに参照ブロックを再翻訳してください。';

  @override
  String get gen_translateAdjustMergeTemplate =>
      '現在のブロックを読み、参照ブロックを指定の原文順に結合し、無関係なブロックは保持してください。';

  @override
  String get gen_translateAdjustMarkers =>
      'translation_blocks_read の marker 一覧を使用してください。';

  @override
  String get gen_translateAdjustHint => 'ブロックの調整方法を入力…';

  @override
  String get gen_translateAdjustStartFailed =>
      '調整を開始できません。モデルと Agent ランタイムを確認してください。';

  @override
  String get gen_translateAdjustRunFailed =>
      '調整が中断または失敗しました。再試行前にブロックを読み直してください。';

  @override
  String gen_repeatDragTotal(int times, int total) {
    return '$times 回 · 計 $total 枚';
  }

  @override
  String get set_cvGroupBatches => '一括生成の結果をグループ化';

  @override
  String get set_cvGroupBatchesSub =>
      'オフの場合は画像を1枚ずつ表示し、履歴のサムネイルでその画像を選べます。シンプルビューアーのみに適用され、無限キャンバスでは常にバッチごとに配置します。';

  @override
  String get gen_groupBatches => 'グループ';

  @override
  String get gen_translateAdjustPickHint => '左のブロックをクリックで参照';

  @override
  String get gen_translateAdjustClearRefs => '参照をクリア';

  @override
  String gen_translateAdjustSplitInto(String source, int count) {
    return '$source → $count ブロック';
  }

  @override
  String get gen_translateAdjustContextNote => 'コンテキスト：今回の原文・ブロック・訳文';

  @override
  String ag_historyStats(int messages, int cards) {
    return '発言 $messages · カード $cards';
  }

  @override
  String get ag_historyKeySelect => '選択';

  @override
  String get ag_historyKeyJump => '会話へ移動';

  @override
  String get ag_historyKeyClose => '閉じる';

  @override
  String get blocks_tempLabel => '一時ブロック';

  @override
  String blocks_tempEditedByAgent(String time) {
    return 'Agent が$timeここを編集しました。';
  }

  @override
  String blocks_tempEditedByYou(String time) {
    return '$timeここを編集しました。';
  }

  @override
  String blocks_tempExplain(String title) {
    return 'ライブラリの「$title」から切り離され、変更はこの位置だけに残ります。ライブラリや他のプロンプトの同じブロックには影響しません。';
  }

  @override
  String get blocks_tempEdit => '編集';

  @override
  String get blocks_tempCompare => '元と比較';

  @override
  String get blocks_tempAdded => '追加';

  @override
  String blocks_tempAddedCount(int count) {
    return '$count 語を追加';
  }

  @override
  String get blocks_tempAddedNone => '追加なし';

  @override
  String get blocks_tempRemoved => '削除';

  @override
  String blocks_tempRemovedHint(int count) {
    return '$count 語を削除';
  }

  @override
  String get blocks_tempRemovedNone => '削除なし';

  @override
  String get blocks_tempRevert => '元に戻す';

  @override
  String get blocks_tempKeepEditing => '編集を続ける';

  @override
  String get blocks_tempApply => '適用';

  @override
  String get blocks_tempSaveAs => '新しいブロックとして保存';

  @override
  String get blocks_tempSaveAsHint => '保存後、この位置は新しいブロックに置き換わり、元のブロックは変わりません';

  @override
  String get blocks_tempSaveConfirm => '保存';

  @override
  String get blocks_tempShowOriginal => 'ライブラリで元を表示';

  @override
  String get gen_menuNew => '新';

  @override
  String get gen_repeatDragHint => '数字を左右にドラッグ · ダブルクリックで入力';

  @override
  String get gen_groupBatchesOn => 'バッチごとに表示中 · クリックで1枚ずつ';

  @override
  String get gen_groupBatchesOff => '1枚ずつ表示中 · クリックでバッチごと';

  @override
  String get blocks_presetCustom => 'カスタム';

  @override
  String get blocks_presetHint =>
      '付属パラメータの適用時に品質タグとネガティブプリセットも復元します。別モデルでは段階を自動換算し、Turbo は既存の処理に従います。';

  @override
  String get gen_vibeInpaintUnsupported =>
      'Vibe は部分再描画（Inpainting）に対応していないため、今回は適用されません。';

  @override
  String get set_stThumbnailCacheLimit => 'サムネイルキャッシュの上限';

  @override
  String get set_stThumbnailCacheLimitSub =>
      'すべてのギャラリーフォルダの合計。起動時や手動クリーンで、古いサムネイルから上限の 80% まで削除します。元画像には触れません。';

  @override
  String get ag_slashGroupSkills => 'スキル';

  @override
  String get ag_slashGroupTemplates => 'プロンプトテンプレート';

  @override
  String get ag_slashGroupBuiltin => 'Studio コマンド';

  @override
  String get ag_commandNew => '新しいチャットを開始';

  @override
  String get ag_commandCompact => 'コンテキストを圧縮';

  @override
  String get ag_commandModel => 'モデルを選択';

  @override
  String get ag_commandThinking => '思考レベルを選択';

  @override
  String get ag_commandHistory => 'セッション履歴を開く';

  @override
  String get ag_commandRename => 'チャット名を変更';

  @override
  String get ag_commandCopy => '最後の返信をコピー';

  @override
  String get ag_commandExport => 'セッションをエクスポート';

  @override
  String get ag_commandCompactArgs => '[指示]';

  @override
  String get ag_commandRenameArgs => '<名前>';

  @override
  String get set_agNextSuggestion => '次のメッセージ候補';

  @override
  String get set_agNextSuggestionSub =>
      '現在の会話モデルで次のメッセージを予測します。追加のトークンを使用します。Tab で採用。';

  @override
  String get set_agCacheWarming => 'プロンプトキャッシュの予熱';

  @override
  String get set_agCacheWarmingSub =>
      'プロンプトキャッシュが切れる直前に 1 トークンのリクエストで延長します（寿命 5 分、全モデル対象）。次のステップはコンテキスト全体を再送せずキャッシュを読みます。';

  @override
  String get set_agCacheOff => 'オフ';

  @override
  String get set_agCacheStreaming => 'Agent の実行中のみ';

  @override
  String get set_agCacheIdle => '待機中も予熱';

  @override
  String get set_agCacheIdleCost => '待機中のウォームアップ（最大 30 分）は追加のモデル料金がかかります。';

  @override
  String get ag_suggestionAccept => 'Tab でこの提案を入力';

  @override
  String get ag_cacheWarmTitle => 'キャッシュのウォームアップ';

  @override
  String get ag_cacheWarmOff => 'オフ';

  @override
  String get ag_cacheWarmRefreshing => 'キャッシュを延長中…';

  @override
  String get ag_cacheWarmIdle => '待機中 — 次の実行で開始';

  @override
  String ag_cacheWarmNext(String time) {
    return '$time 後に延長';
  }

  @override
  String get set_stOther => 'その他のファイル';

  @override
  String get set_stIncomplete =>
      '一部のフォルダを読み取れなかったため、合計は不完全です。カテゴリにカーソルを合わせると参照元を表示します。';

  @override
  String get set_stSliceIncomplete => '一部のみ読み取り';

  @override
  String get localGallery_searchHistoryTitle => '最近の検索';

  @override
  String get localGallery_searchHistoryClear => 'クリア';

  @override
  String get localGallery_searchHistoryRemove => '履歴から削除';

  @override
  String ag_cacheWarmCount(int count) {
    return '延長 $count 回';
  }

  @override
  String ag_cacheWarmLast(String time) {
    return '前回 $time';
  }

  @override
  String ag_cacheWarmTtl(int minutes) {
    return 'キャッシュ寿命 $minutes 分';
  }
}
