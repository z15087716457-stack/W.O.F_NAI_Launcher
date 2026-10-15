// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get app_title => 'W.O.F NAI Studio';

  @override
  String get settings_visualAssets => '인터페이스 글꼴 및 라이선스';

  @override
  String get brand_entryTagline => '상상이 현실이 되는 곳.';

  @override
  String get brand_switchToLight => '라이트 모드로 전환';

  @override
  String get brand_switchToDark => '다크 모드로 전환';

  @override
  String get app_subtitle => 'NovelAI 서드파티 클라이언트';

  @override
  String get common_cancel => '취소';

  @override
  String get common_confirm => '확인';

  @override
  String get common_continue => '계속';

  @override
  String get common_selectAll => '모두 선택';

  @override
  String get common_deselectAll => '모두 선택 해제';

  @override
  String get common_save => '저장';

  @override
  String get common_delete => '삭제';

  @override
  String get common_edit => '편집';

  @override
  String get common_close => '닫기';

  @override
  String get common_clear => '지우기';

  @override
  String get common_copy => '복사';

  @override
  String get common_copied => '복사했습니다';

  @override
  String get common_export => '내보내기';

  @override
  String get common_import => '가져오기';

  @override
  String get common_loading => '불러오는 중...';

  @override
  String get common_error => '오류';

  @override
  String get common_success => '성공';

  @override
  String get common_retry => '다시 시도';

  @override
  String get common_select => '선택';

  @override
  String get common_reset => '초기화';

  @override
  String get common_add => '추가';

  @override
  String get common_added => '추가했습니다';

  @override
  String get common_confirmDelete => '삭제 확인';

  @override
  String get common_confirmClear => '비우기 확인';

  @override
  String get common_gotIt => '확인했습니다';

  @override
  String common_deleteItemConfirm(Object itemName) {
    return '\"$itemName\"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String common_clearAllItemsConfirm(Object count, Object itemType) {
    return '$itemType $count개를 모두 비우시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get common_clearInputConfirm => '입력한 내용을 지우시겠습니까?';

  @override
  String common_daysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String get common_undo => '실행 취소';

  @override
  String get common_redo => '다시 실행';

  @override
  String get common_refresh => '새로 고침';

  @override
  String get common_download => '다운로드';

  @override
  String get common_apply => '적용';

  @override
  String get common_favorite => '즐겨찾기';

  @override
  String get common_unfavorite => '즐겨찾기 해제';

  @override
  String get common_ok => '확인';

  @override
  String get common_exit => '종료';

  @override
  String get common_grid => '그리드';

  @override
  String get common_multiSelect => '다중 선택';

  @override
  String get common_category => '분류';

  @override
  String get networkError_connectionTimeout =>
      '연결 시간이 초과되었습니다. 네트워크 연결을 확인하세요.';

  @override
  String get networkError_sendTimeout => '전송 시간이 초과되었습니다. 다시 시도하세요.';

  @override
  String get networkError_receiveTimeout =>
      '수신 시간이 초과되었습니다. 이미지 생성에 예상보다 시간이 더 걸릴 수 있습니다.';

  @override
  String get networkError_requestCancelled => '요청이 취소되었습니다';

  @override
  String get networkError_connection => '네트워크 연결 오류입니다. 네트워크 연결을 확인하세요.';

  @override
  String get networkError_unknown => '알 수 없는 오류';

  @override
  String get networkError_noResponse => '서버가 응답하지 않습니다';

  @override
  String get networkError_badRequest => '요청 매개변수가 올바르지 않습니다';

  @override
  String get networkError_authFailed => '인증에 실패했습니다. 다시 로그인하세요.';

  @override
  String get networkError_insufficientAnlas => 'Anlas가 부족합니다';

  @override
  String get networkError_forbidden => '이 리소스에 접근할 권한이 없습니다';

  @override
  String get networkError_notFound => '요청한 리소스가 존재하지 않습니다';

  @override
  String get networkError_conflict => '요청이 현재 상태와 충돌합니다';

  @override
  String get networkError_rateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도하세요.';

  @override
  String get networkError_serverInternal => '서버 내부 오류';

  @override
  String get networkError_badGateway => '서버 게이트웨이 오류';

  @override
  String get networkError_unavailable => '서비스를 일시적으로 사용할 수 없습니다';

  @override
  String networkError_requestFailed(int code) {
    return '요청 실패($code)';
  }

  @override
  String get auth_login => '로그인';

  @override
  String get auth_logout => '로그아웃';

  @override
  String get auth_email => '이메일';

  @override
  String get auth_password => '비밀번호';

  @override
  String get auth_loginButton => '로그인';

  @override
  String get auth_loginFailed => '로그인에 실패했습니다';

  @override
  String get auth_guestEntry => '로그인하지 않고 게스트로 계속';

  @override
  String get auth_recommended => '추천';

  @override
  String get auth_getToken => '토큰 받기';

  @override
  String get auth_localOnlyNote => '계정과 토큰은 이 기기에만 저장됩니다';

  @override
  String get auth_back => '뒤로';

  @override
  String get auth_toggleVisibility => '표시 / 숨기기';

  @override
  String get auth_emailRequired => '이메일을 입력하세요';

  @override
  String get auth_emailInvalid => '올바른 이메일 주소를 입력하세요';

  @override
  String get auth_passwordRequired => '비밀번호를 입력하세요';

  @override
  String get auth_tokenLoginRecommended => 'API 토큰 로그인(추천)';

  @override
  String get auth_credentialsLogin => '이메일 및 비밀번호';

  @override
  String get auth_credentialsLoginUnavailable =>
      '이메일/비밀번호 로그인은 현재 사용할 수 없습니다. 토큰으로 로그인하세요.';

  @override
  String get auth_tokenRequired => '토큰을 입력하세요';

  @override
  String get auth_tokenInvalid => '토큰 형식이 올바르지 않습니다. pst-로 시작해야 합니다';

  @override
  String get auth_nicknameHint => '이 계정을 알아보기 쉬운 이름을 설정하세요';

  @override
  String get auth_thirdPartyLogin => '서드파티 사이트';

  @override
  String get auth_thirdPartyApiSite => '서드파티 API 사이트';

  @override
  String get auth_imageApiSiteOptional => '이미지 API 사이트(선택)';

  @override
  String get auth_imageApiSiteHint => '비워 두면 같은 서드파티 API 사이트를 사용합니다';

  @override
  String get auth_thirdPartyNicknameHint => '예: 자체 호스팅 사이트 / 미러 사이트';

  @override
  String get auth_thirdPartyTokenHint => '서드파티 사이트에서 발급한 API 토큰을 입력하세요';

  @override
  String get auth_thirdPartyCompatibilityHint =>
      '서드파티 사이트는 NovelAI 구독 및 이미지 생성 API와 호환되어야 합니다. 토큰은 Bearer 토큰으로 전송됩니다.';

  @override
  String get auth_thirdPartyApiSiteRequired => '서드파티 API 사이트 주소를 입력하세요';

  @override
  String get auth_validateAndLogin => '확인 후 로그인';

  @override
  String get auth_tokenGuide => 'NovelAI 설정에서 토큰 받기';

  @override
  String get auth_addAccount => '계정 추가';

  @override
  String get auth_tokenNotFound => '이 계정의 토큰을 찾을 수 없습니다';

  @override
  String get auth_switchAccount => '계정 전환';

  @override
  String get auth_selectAccount => '계정 선택';

  @override
  String get auth_deleteAccount => '계정 삭제';

  @override
  String auth_deleteAccountConfirm(Object name) {
    return '\"$name\" 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String auth_deleteCurrentAccountConfirm(Object name) {
    return '\"$name\" 계정을 삭제하고 로그아웃하시겠습니까?';
  }

  @override
  String get auth_switchFailedDeletePrompt =>
      '이 계정에 로그인할 수 없습니다(만료되었을 수 있습니다). 목록에서 삭제하시겠습니까?';

  @override
  String get auth_switchFailedDeletePromptMissingToken =>
      '이 계정에 저장된 로그인 정보가 없습니다. 목록에서 삭제하시겠습니까?';

  @override
  String get auth_removeAvatar => '아바타 제거';

  @override
  String get auth_quickLogin => '빠른 로그인';

  @override
  String get auth_nicknameRequired => '닉네임을 입력하세요';

  @override
  String get auth_error_networkTimeout => '연결 시간 초과';

  @override
  String get auth_error_networkError => '네트워크 오류';

  @override
  String get auth_error_authFailed => '인증 실패';

  @override
  String get auth_error_credentialsLoginUnavailable =>
      '이메일/비밀번호 로그인은 현재 사용할 수 없습니다';

  @override
  String get auth_error_credentialsLoginUnavailable_hint =>
      'NovelAI의 이메일/비밀번호 로그인에는 웹 보안 확인이 필요합니다. Persistent API Token을 사용하세요.';

  @override
  String get auth_error_serverError => '서버 오류';

  @override
  String get auth_error_unknown => '알 수 없는 오류';

  @override
  String get auth_autoLogin => '자동 로그인';

  @override
  String get auth_forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get auth_passwordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get auth_loggingIn => '로그인하는 중...';

  @override
  String get auth_viewTroubleshootingTips => '문제 해결 도움말 보기';

  @override
  String get auth_troubleshoot_checkConnection_title => '네트워크 연결 확인';

  @override
  String get auth_troubleshoot_checkConnection_desc =>
      '기기가 인터넷에 연결되어 있는지 확인하세요';

  @override
  String get auth_troubleshoot_retry_title => '다시 시도';

  @override
  String get auth_troubleshoot_retry_desc => '네트워크 문제는 일시적일 수 있습니다. 다시 시도하세요';

  @override
  String get auth_troubleshoot_proxy_title => '프록시 설정 확인';

  @override
  String get auth_troubleshoot_proxy_desc => '프록시를 사용 중이라면 올바르게 설정되었는지 확인하세요';

  @override
  String get auth_troubleshoot_firewall_title => '방화벽 설정 확인';

  @override
  String get auth_troubleshoot_firewall_desc =>
      '방화벽이 NovelAI 서버 연결을 허용하는지 확인하세요';

  @override
  String get auth_troubleshoot_serverStatus_title => '서버 상태 확인';

  @override
  String get auth_troubleshoot_serverStatus_desc =>
      'NovelAI 상태 페이지나 커뮤니티에서 장애 여부를 확인하세요';

  @override
  String get common_paste => '붙여넣기';

  @override
  String get common_default => '기본값';

  @override
  String get settings_title => '설정';

  @override
  String get settings_savedAccounts => '저장된 계정';

  @override
  String get settings_style => '스타일';

  @override
  String get settings_font => '글꼴';

  @override
  String get settings_language => '언어';

  @override
  String get settings_shortcuts => '단축키';

  @override
  String get settings_generationInputSection => '입력';

  @override
  String get settings_generationFeedbackSection => '완료 알림';

  @override
  String get settings_selectFont => '글꼴 선택';

  @override
  String get settings_selectLanguage => '언어 선택';

  @override
  String settings_loadFailed(Object error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get settings_imageSavePath => '이미지 저장 위치';

  @override
  String get settings_autoSave => '자동 저장';

  @override
  String get settings_autoSaveSubtitle => '생성 후 이미지를 자동으로 저장합니다';

  @override
  String get settings_extraRootsTitle => '갤러리 소스';

  @override
  String get settings_extraRootsHint =>
      '추가 갤러리 소스는 탐색하고 검색할 수 있으며, 이미지를 분류로 이동하거나 복사할 수 있습니다. 자동 저장에는 사용되지 않습니다. 새 소스는 추가하는 즉시 스캔합니다.';

  @override
  String get settings_extraRootsEmpty => '추가한 갤러리 소스가 없습니다';

  @override
  String get settings_extraRootsAdd => '폴더 추가';

  @override
  String get settings_extraRootsAddTitle => '갤러리 소스로 추가할 폴더 선택';

  @override
  String get settings_extraRootsRemove => '이 갤러리 소스 제거';

  @override
  String get settings_extraRootsRemoveConfirmTitle => '갤러리 소스를 제거하시겠습니까?';

  @override
  String settings_extraRootsRemoveConfirmContent(String path) {
    return '\"$path\"을(를) 갤러리에서 제거합니다(폴더 안의 파일은 삭제되지 않습니다).';
  }

  @override
  String get settings_extraRootsAdded => '갤러리 소스를 추가하고 스캔했습니다';

  @override
  String get settings_extraRootsScanFailed =>
      '폴더를 추가했지만 스캔을 마치지 못했습니다. 갤러리를 새로 고쳐 다시 시도하세요';

  @override
  String get settings_extraRootsWaitingScan =>
      '갤러리를 스캔하는 중입니다. 스캔이 끝나면 이 폴더를 가져옵니다';

  @override
  String get settings_extraRootsRemoved => '갤러리 소스를 제거했습니다';

  @override
  String get settings_extraRootsDuplicate => '이미 갤러리 소스로 추가된 폴더입니다';

  @override
  String get settings_extraRootsSameAsMain => '이미지 저장 위치와 같은 폴더입니다';

  @override
  String get settings_extraRootsNested =>
      '갤러리 소스끼리는 서로 포함할 수 없습니다. 다른 폴더를 선택하세요';

  @override
  String get settings_extraRootsNotFound => '선택한 폴더가 존재하지 않습니다';

  @override
  String get settings_importTagIndex => '태그 인덱스 가져오기…';

  @override
  String get settings_importTagIndexPickTitle => '태그 인덱스 파일 선택(.jsonl)';

  @override
  String settings_importTagIndexProgress(int processed, int total) {
    return '$processed/$total줄 가져오는 중…';
  }

  @override
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  ) {
    return '가져오기 완료: 새로 추가 $imported, 업데이트 $updated, 건너뜀 $skipped, 오류 $errors';
  }

  @override
  String get settings_importTagIndexFailed => '태그 인덱스를 가져오지 못했습니다';

  @override
  String get settings_importTagIndexBlockedByScan =>
      '갤러리를 스캔하는 중입니다. 스캔이 끝난 뒤 태그 인덱스를 가져오세요.';

  @override
  String get settings_extraRootsIndexImportTitle => '태그 인덱스 발견';

  @override
  String settings_extraRootsIndexImportContent(String path) {
    return '\"$path\"에서 태그 인덱스 index.jsonl을 찾았습니다. 먼저 가져오면 이어지는 스캔에서 메타데이터 분석을 건너뛰어 빠르게 진행됩니다. 지금 가져오시겠습니까?';
  }

  @override
  String get settings_extraRootsIndexImportConfirm => '지금 가져오기';

  @override
  String settings_version(Object version) {
    return '버전 $version';
  }

  @override
  String get settings_openSource => '오픈 소스';

  @override
  String get settings_openSourceSubtitle => '소스 코드와 문서 보기';

  @override
  String get settings_fileLogging => '앱 로그 기록';

  @override
  String get settings_fileLoggingSubtitle =>
      '기본값은 꺼짐이며 문제를 해결할 때만 켜세요. 켜면 로그가 Documents/NAI_Launcher/logs에 기록되고, 끄면 로그 파일을 더 이상 만들거나 기록하지 않습니다.';

  @override
  String get settings_pathReset => '기본 위치로 초기화했습니다';

  @override
  String get settings_pathSaved => '저장 위치를 변경했습니다';

  @override
  String get settings_selectFolder => '저장 폴더 선택';

  @override
  String get settings_vibeLibraryPath => 'Vibe 라이브러리 경로';

  @override
  String get settings_hiveStoragePath => '데이터 저장 경로';

  @override
  String get settings_selectVibeLibraryFolder => 'Vibe 라이브러리 폴더 선택';

  @override
  String get settings_selectHiveFolder => '데이터 저장 폴더 선택';

  @override
  String get settings_pathSavedRestartRequired => '경로를 변경했습니다. 다시 시작하면 적용됩니다';

  @override
  String get settings_accountType => '계정 유형';

  @override
  String get settings_subscriptionExpiry => '구독 만료일';

  @override
  String get settings_thirdPartyApiAccount => '서드파티 사이트 API';

  @override
  String get settings_goToLogin => '로그인하러 가기';

  @override
  String get settings_changeAvatar => '아바타 변경';

  @override
  String get settings_removeAvatar => '아바타 제거';

  @override
  String get settings_accountEmail => '계정 이메일';

  @override
  String get settings_emailAccount => '이메일 계정';

  @override
  String get settings_tokenAccount => '토큰 계정';

  @override
  String get settings_setAsDefault => '기본값으로 설정';

  @override
  String get settings_defaultAccount => '기본';

  @override
  String get settings_nickname => '닉네임';

  @override
  String get settings_nicknameUpdated => '닉네임을 변경했습니다';

  @override
  String get settings_avatarUpdated => '아바타를 변경했습니다';

  @override
  String get settings_avatarRemoved => '아바타를 제거했습니다';

  @override
  String get settings_setAsDefaultSuccess => '기본 계정으로 설정했습니다';

  @override
  String generation_cooldownRemaining(Object seconds) {
    return '$seconds초 대기';
  }

  @override
  String get generation_generating => '생성하는 중...';

  @override
  String get generation_cancelGeneration => '생성 취소';

  @override
  String get generation_stopGeneration => '생성 중지';

  @override
  String get generation_pleaseInputPrompt => '프롬프트를 입력하세요';

  @override
  String get generation_generationFailed => '생성에 실패했습니다';

  @override
  String generation_deleteSelectedImagesConfirm(int count) {
    return '이미지 $count장을 기록에서 제거합니다(디스크에 저장된 파일은 유지됩니다)';
  }

  @override
  String generation_seedWrittenBack(int seed) {
    return '시드를 되돌려 적용했습니다: $seed';
  }

  @override
  String get generation_setAsReferenceImage => '참조 이미지로 설정했습니다';

  @override
  String get generation_canvasDisplaySettings => '캔버스 표시';

  @override
  String get generation_canvasZoomToFill => '채우도록 확대(100% 초과 허용)';

  @override
  String get generation_canvasEmpty => '캔버스가 비어 있습니다';

  @override
  String get generation_canvasBackground => '투명 영역 배경';

  @override
  String get generation_canvasBackgroundChecker => '체크무늬';

  @override
  String get generation_canvasBackgroundCheckerLight => '밝은 체크무늬';

  @override
  String get generation_canvasBackgroundCheckerDark => '어두운 체크무늬';

  @override
  String get generation_canvasBackgroundNone => '배경 없음';

  @override
  String get generation_canvasBackgroundBlack => '검정';

  @override
  String get generation_canvasBackgroundWhite => '흰색';

  @override
  String get generation_canvasBackgroundGray => '회색';

  @override
  String get generation_canvasBackgroundRed => '빨강';

  @override
  String get generation_canvasBackgroundGreen => '초록';

  @override
  String get generation_canvasBackgroundBlue => '파랑';

  @override
  String get generation_canvasBackgroundCustom => '사용자 지정 색';

  @override
  String get generation_canvasSetInitImage => 'Image2Image 원본으로 사용';

  @override
  String get generation_canvasSendToTools => '디렉터 도구로 보내기';

  @override
  String get generation_canvasPinImage => '이미지 고정';

  @override
  String get generation_canvasUnpinImage => '고정 해제';

  @override
  String get generation_canvasUseSeed => '클릭하여 이 시드 사용';

  @override
  String get generation_history => '기록';

  @override
  String get generation_failedStreamSnapshot => '실패한 스냅숏';

  @override
  String get generation_failedStreamSnapshotHint =>
      '생성이 끝나지 않아 마지막 미리 보기 프레임만 남았습니다. 저장, 즐겨찾기, 이미지 작업에 사용할 수 없습니다.';

  @override
  String get generation_model => '모델';

  @override
  String get generation_imageSize => '이미지 크기';

  @override
  String get generation_sampler => '샘플러';

  @override
  String generation_steps(Object steps) {
    return '스텝: $steps';
  }

  @override
  String get generation_stepsLabel => '스텝';

  @override
  String get generation_guidance => '가이던스';

  @override
  String generation_cfgScale(Object scale) {
    return '프롬프트 가이던스: $scale';
  }

  @override
  String get generation_seed => '시드';

  @override
  String get generation_seedRandom => '무작위';

  @override
  String get generation_samplerRecommended => '추천';

  @override
  String get generation_samplerOther => '기타';

  @override
  String get generation_advancedOptions => '고급 옵션';

  @override
  String get generation_smea => 'SMEA';

  @override
  String get generation_smeaSubtitle => '큰 이미지의 생성 품질을 개선합니다';

  @override
  String get generation_smeaDyn => 'SMEA DYN';

  @override
  String get generation_smeaDescription =>
      '이미지가 일정 크기를 넘으면 고해상도 샘플러를 자동으로 사용합니다';

  @override
  String generation_cfgRescale(Object value) {
    return '프롬프트 가이던스 리스케일: $value';
  }

  @override
  String get generation_noiseSchedule => '노이즈 스케줄';

  @override
  String get generation_modelGroupNew => '최신';

  @override
  String get generation_modelGroupLegacy => '레거시';

  @override
  String get generation_modelDesc_v5Curated =>
      '선별된 이미지 하위 집합으로 학습한 NovelAI의 최신 모델입니다. 스트리밍에 추천합니다.';

  @override
  String get generation_modelDesc_v5Full => 'NovelAI의 최신이자 최고 성능 모델입니다.';

  @override
  String get generation_modelDesc_v45Curated =>
      '선별된 이미지 하위 집합으로 학습한 NovelAI V4.5 모델입니다. 더 이상 사용을 권장하지 않습니다.';

  @override
  String get generation_modelDesc_v45Full => 'NovelAI V4.5 전체 모델입니다.';

  @override
  String get generation_modelDesc_v4Curated =>
      '선별된 이미지 하위 집합으로 학습한 NovelAI V4 모델입니다.';

  @override
  String get generation_modelDesc_v4Full => 'NovelAI V4 전체 모델입니다.';

  @override
  String get generation_sectionCharacters => '캐릭터 프롬프트';

  @override
  String get generation_sectionCharactersSub => '장면 속 캐릭터마다 별도의 프롬프트를 만듭니다.';

  @override
  String get character_positionLabel => '위치';

  @override
  String get anlas_subscription => '구독';

  @override
  String get anlas_purchased => '구매';

  @override
  String get prompt_positive => '프롬프트';

  @override
  String get prompt_baseTab => '기본 프롬프트';

  @override
  String get prompt_negativeTab => '네거티브';

  @override
  String get prompt_transparentBg => '투명 배경';

  @override
  String get prompt_chunksMenu => '도구 및 전환';

  @override
  String get qualityTags_presetChip => '품질 태그';

  @override
  String get ucPreset_presetChip => '네거티브 프리셋';

  @override
  String get prompt_positivePrompt => '프롬프트';

  @override
  String get prompt_negativePrompt => '네거티브 프롬프트';

  @override
  String get prompt_mainPositive => '메인 프롬프트';

  @override
  String get prompt_mainNegative => '메인 프롬프트(네거티브)';

  @override
  String get prompt_characterPrompts => '다중 캐릭터 프롬프트';

  @override
  String get prompt_finalPrompt => '최종 적용 프롬프트';

  @override
  String get prompt_finalNegative => '최종 적용 네거티브';

  @override
  String prompt_importedCharacters(int count) {
    return '캐릭터 $count명을 가져왔습니다';
  }

  @override
  String get prompt_characterPromptReplaced => '캐릭터 프롬프트를 교체했습니다';

  @override
  String prompt_characterPromptAppended(Object count) {
    return '캐릭터 프롬프트를 추가했습니다(캐릭터 $count명)';
  }

  @override
  String prompt_smartDecomposedWithCharacters(Object count) {
    return '메인 프롬프트 + 캐릭터 $count명으로 분해했습니다';
  }

  @override
  String get prompt_appliedToMainPrompt => '메인 프롬프트에 적용했습니다';

  @override
  String get prompt_searchHint => '프롬프트 검색';

  @override
  String prompt_searchMatchCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get prompt_searchPrevious => '이전 항목';

  @override
  String get prompt_searchNext => '다음 항목';

  @override
  String get prompt_searchClose => '검색 닫기';

  @override
  String get prompt_replaceHint => '바꿀 내용';

  @override
  String get prompt_replaceToggle => '바꾸기 표시/숨기기';

  @override
  String get prompt_replaceCurrent => '현재 항목 바꾸기(Enter)';

  @override
  String get prompt_replaceAll => '모두 바꾸기(Ctrl+Enter)';

  @override
  String prompt_replaceAllDone(Object count) {
    return '$count곳을 바꿨습니다';
  }

  @override
  String get kritaBridge_busyGenerating =>
      'Krita Bridge에서 생성하는 중입니다. 현재 작업이 끝날 때까지 기다리세요.';

  @override
  String get prompt_unwantedContent => '이미지에 나오지 않았으면 하는 내용...';

  @override
  String get prompt_autoFormat => '자동 서식';

  @override
  String get prompt_autoFormatSubtitle => '쉼표와 공백을 정리하고 불필요한 1배 가중치 기호를 제거합니다';

  @override
  String get prompt_highlightEmphasis => '강조 구문 강조 표시';

  @override
  String get prompt_highlightEmphasisSubtitle => '괄호와 가중치 구문을 강조 표시합니다';

  @override
  String get prompt_sdSyntaxAutoConvert => 'SD 구문 자동 변환';

  @override
  String get prompt_sdSyntaxAutoConvertSubtitle =>
      '포커스를 잃거나 생성할 때 SD 가중치 구문을 NAI 형식으로 변환합니다';

  @override
  String get prompt_cooccurrenceRecommendation => '태그 확장';

  @override
  String get prompt_cooccurrenceRecommendationSubtitle =>
      'Ctrl+클릭으로 로컬 태그 검색, Ctrl+드래그로 관련 태그 탐색';

  @override
  String get prompt_formatted => '서식을 정리했습니다';

  @override
  String get image_save => '저장';

  @override
  String get image_copy => '복사';

  @override
  String get image_upscale => '업스케일';

  @override
  String image_imageSaved(Object path) {
    return '이미지를 저장했습니다: $path';
  }

  @override
  String image_saveFailed(Object error) {
    return '저장하지 못했습니다: $error';
  }

  @override
  String get image_copiedToClipboard => '클립보드에 복사했습니다';

  @override
  String image_copyFailed(Object error) {
    return '복사하지 못했습니다: $error';
  }

  @override
  String get img2img_title => 'Image2Image';

  @override
  String get img2img_subtitle => '원본 이미지로 베리에이션을 생성합니다';

  @override
  String get img2img_enabled => '사용';

  @override
  String get img2img_sourceImage => '원본 이미지';

  @override
  String get img2img_strength => '강도';

  @override
  String get img2img_strengthHint => '값이 높을수록 원본과 차이가 커집니다';

  @override
  String get img2img_noise => '노이즈';

  @override
  String get img2img_noiseHint => '노이즈를 추가해 변화를 키웁니다';

  @override
  String get img2img_clearSettings => 'Image2Image 설정 지우기';

  @override
  String get img2img_changeImage => '이미지 변경';

  @override
  String get img2img_removeImage => '이미지 제거';

  @override
  String img2img_selectFailed(Object error) {
    return '이미지를 선택하지 못했습니다: $error';
  }

  @override
  String get img2img_editImage => '이미지 편집';

  @override
  String get img2img_placeOnCanvas => '캔버스에 배치';

  @override
  String get img2img_editApplied => '편집한 이미지를 새 원본 이미지로 설정했습니다';

  @override
  String get img2img_uploadImage => '이미지 업로드';

  @override
  String get img2img_dropToAdd => '놓으면 원본 이미지로 설정합니다';

  @override
  String get img2img_moreActions => '추가 작업';

  @override
  String get img2img_drawSketch => '스케치 그리기';

  @override
  String get img2img_inpaint => '인페인트';

  @override
  String get img2img_inpaintStrength => '인페인트 강도';

  @override
  String get img2img_inpaintStrengthHint =>
      '값이 높을수록 마스크 영역이 현재 원본 이미지와 더 많이 달라집니다';

  @override
  String get img2img_inpaintPendingHint =>
      '인페인트를 클릭해 캔버스를 열고 브러시, 지우개, 선택 도구로 다시 그릴 영역을 표시한 뒤, 여기로 돌아와 메인 생성 버튼을 누르세요.';

  @override
  String get img2img_inpaintReadyHint =>
      '마스크를 불러왔습니다. 다음 생성에서는 마스크 영역만 다시 그립니다.';

  @override
  String get img2img_inpaintMaskReady => '인페인트 마스크가 준비되었습니다';

  @override
  String get generation_variationOriginal => '원본';

  @override
  String get generation_variationSizeUnsupported =>
      '변형은 300만 화소 이하의 원본 이미지를 지원합니다.';

  @override
  String get img2img_generateVariations => '베리에이션 생성';

  @override
  String get img2img_directorTools => '디렉터 도구';

  @override
  String get img2img_directorApplied => '디렉터 도구 결과를 새 원본 이미지로 설정했습니다';

  @override
  String get img2img_variationsStarted => '베리에이션을 생성하는 중...';

  @override
  String get img2img_directorRemoveBackground => '배경 제거';

  @override
  String get img2img_directorLineArt => '선화 추출';

  @override
  String get img2img_directorSketch => '스케치화';

  @override
  String get img2img_directorColorize => '채색';

  @override
  String get img2img_directorEmotion => '표정 수정';

  @override
  String get img2img_directorDeclutter => '잡선 정리';

  @override
  String get img2img_enhance => '향상';

  @override
  String get img2img_enhanceMagnitude => '강도';

  @override
  String get img2img_enhanceUpscaleAmount => '업스케일 배율';

  @override
  String get img2img_enhanceMax => '최대✨';

  @override
  String get img2img_novelAiCloudUpscale => 'NovelAI 클라우드 업스케일(2배 고정)';

  @override
  String get img2img_novelAiCloudUpscaleTitle => 'NovelAI 클라우드 업스케일';

  @override
  String get img2img_cloudUpscaleSizeLimit =>
      'NovelAI 클라우드 업스케일은 최대 3MP 입력 이미지를 지원합니다.';

  @override
  String get img2img_upscaleRegularModel => '일반 모델';

  @override
  String get img2img_upscaleModel => '업스케일 모델';

  @override
  String get img2img_startUpscale => '업스케일 시작';

  @override
  String get img2img_novelAiUpscaleComplete => 'NovelAI 업스케일 완료';

  @override
  String get img2img_decodeSourceFailed => '원본 이미지를 디코딩하지 못했습니다';

  @override
  String get editor_tolerance => '허용 범위';

  @override
  String get editor_intensity => '강도';

  @override
  String get editor_sourcePoint => 'Alt+클릭으로 원본 지점 설정';

  @override
  String get editor_brushPresets => '브러시 프리셋';

  @override
  String get editor_size => '크기';

  @override
  String get editor_opacity => '불투명도';

  @override
  String get editor_hardness => '경도';

  @override
  String get editor_undo => '실행 취소';

  @override
  String get editor_redo => '다시 실행';

  @override
  String get editor_clearLayer => '레이어 지우기';

  @override
  String get editor_toolBrush => '브러시';

  @override
  String get editor_toolEraser => '지우개';

  @override
  String get editor_toolFill => '채우기';

  @override
  String get editor_toolMagicWand => '자동 선택';

  @override
  String get editor_magicWandMode => '선택 방식';

  @override
  String get editor_magicWandSmartObject => '스마트 개체(EfficientViT)';

  @override
  String get editor_magicWandColorArea => '색상 영역(플러드 필)';

  @override
  String get editor_magicWandSmartHelp =>
      '선택할 개체를 클릭하세요. 처음 사용할 때 MIT Han Lab의 약 133 MiB EfficientViT-SAM L0 모델(Apache-2.0)을 다운로드한 뒤 로컬에 보관합니다.';

  @override
  String get editor_magicWandColorHelp =>
      '비슷한 색이 이어진 영역을 클릭하세요. 경계가 깔끔한 단색 이미지에 적합하며 모델을 다운로드하지 않습니다.';

  @override
  String get editor_magicWandInvert => '결과 반전';

  @override
  String get editor_toolLine => '직선';

  @override
  String get editor_toolRectSelect => '사각형';

  @override
  String get editor_toolEllipseSelect => '타원';

  @override
  String get editor_toolLassoSelect => '올가미';

  @override
  String get editor_toolColorPicker => '스포이트';

  @override
  String get editor_toolCloneStamp => '복제 도장';

  @override
  String get editor_toolBlur => '흐림';

  @override
  String get editor_layers => '레이어';

  @override
  String get editor_fillClosedRegion => '닫힌 영역 채우기';

  @override
  String get editor_resetMask => '마스크 초기화';

  @override
  String get editor_zoomIn => '확대';

  @override
  String get editor_zoomOut => '축소';

  @override
  String get editor_fitToWindow => '창에 맞추기';

  @override
  String get editor_effectBrightness => '밝기';

  @override
  String get editor_effectSaturation => '채도';

  @override
  String get editor_changeCanvasSize => '캔버스 크기 변경';

  @override
  String get editor_confirmExitTitle => '종료 확인';

  @override
  String get editor_confirmExitContent => '저장하지 않은 변경 사항이 있습니다. 종료하시겠습니까?';

  @override
  String get editor_exit => '종료';

  @override
  String get editor_saveAndExit => '저장 후 종료';

  @override
  String editor_exportFailed(Object error) {
    return '내보내지 못했습니다: $error';
  }

  @override
  String get editor_maskLayerName => '마스크';

  @override
  String get editor_emptyImageFile => '파일이 비어 있습니다. 올바른 이미지 파일을 선택하세요';

  @override
  String editor_fileTooLarge(Object sizeMB) {
    return '파일이 너무 큽니다($sizeMB MB). 50 MB 미만의 이미지를 선택하세요';
  }

  @override
  String get editor_parseImageFailed =>
      '이미지 파일을 분석하지 못했습니다\n파일이 손상되지 않았고 지원하는 형식인지 확인하세요';

  @override
  String get editor_defaultTitle => '캔버스';

  @override
  String get editor_baseLayerName => '기본 이미지';

  @override
  String get editor_existingMaskLayerName => '기존 마스크';

  @override
  String get editor_defaultDrawingLayerName => '레이어 1';

  @override
  String editor_layerName(Object count) {
    return '레이어 $count';
  }

  @override
  String get editor_canvasSizeTitle => '캔버스 크기';

  @override
  String get editor_presetSize => '프리셋 크기';

  @override
  String get editor_customSize => '사용자 지정';

  @override
  String get editor_contentHandling => '내용 처리';

  @override
  String get editor_contentCrop => '자르기';

  @override
  String get editor_contentPad => '여백 채우기';

  @override
  String get editor_contentStretch => '늘이기';

  @override
  String get editor_width => '너비';

  @override
  String get editor_height => '높이';

  @override
  String get editor_lockAspectRatio => '가로세로 비율 고정';

  @override
  String get editor_unlockAspectRatio => '가로세로 비율 고정 해제';

  @override
  String get editor_sizePreview => '크기 미리 보기';

  @override
  String get editor_originalSize => '원본';

  @override
  String get editor_newSize => '새 크기';

  @override
  String get editor_cropModeDescription => '자르기 모드 - 비율을 유지하고 자릅니다';

  @override
  String get editor_padModeDescription => '여백 모드 - 비율을 유지하고 여백을 채웁니다';

  @override
  String get editor_stretchModeDescription => '늘이기 모드 - 꽉 차게 늘입니다';

  @override
  String editor_canvasPresetSquare(Object size) {
    return '정사각형 $size';
  }

  @override
  String editor_canvasPresetLandscape(Object ratio) {
    return '가로 $ratio';
  }

  @override
  String editor_canvasPresetPortrait(Object ratio) {
    return '세로 $ratio';
  }

  @override
  String get editor_canvasPresetNaiPortrait => 'NAI 세로';

  @override
  String get editor_canvasPresetNaiLandscape => 'NAI 가로';

  @override
  String get editor_canvasPresetFullHd => 'Full HD 16:9';

  @override
  String get editor_colorPanelTitle => '색상';

  @override
  String get editor_colorPickerTitle => '색상 선택';

  @override
  String get editor_brushSettings => '브러시 설정';

  @override
  String get editor_eraserSettings => '지우개 설정';

  @override
  String get editor_lassoSelectionHelp =>
      '누른 채로 끌어 자유형 선택 영역을 그리세요. 놓으면 자동으로 닫힙니다.';

  @override
  String get layer_empty => '레이어 없음';

  @override
  String get layer_add => '레이어 추가';

  @override
  String get layer_mergeDown => '아래로 병합';

  @override
  String get layer_duplicate => '복제';

  @override
  String get layer_delete => '삭제';

  @override
  String get layer_merge => '아래로 병합';

  @override
  String get layer_visibility => '표시 전환';

  @override
  String get layer_lock => '잠금 전환';

  @override
  String get layer_rename => '이름 변경';

  @override
  String get layer_moveUp => '위로 이동';

  @override
  String get layer_moveDown => '아래로 이동';

  @override
  String get vibe_title => 'Vibe 트랜스퍼';

  @override
  String get vibe_description => '이미지는 바꾸고, 분위기는 그대로.';

  @override
  String get vibe_addFromFileTitle => '파일에서 추가';

  @override
  String get vibe_addFromFileSubtitle => 'PNG, JPG, Vibe 파일';

  @override
  String get vibe_addFromLibraryTitle => '라이브러리에서 가져오기';

  @override
  String get vibe_addFromLibrarySubtitle => 'Vibe 라이브러리에서 선택';

  @override
  String get vibe_addReference => '참조 추가';

  @override
  String get vibe_clearAll => '모두 지우기';

  @override
  String vibe_cleared(int count) {
    return 'Vibe $count개를 지웠습니다';
  }

  @override
  String get vibe_referenceStrength => '참조 강도';

  @override
  String get vibe_infoExtraction => '정보 추출량';

  @override
  String get vibe_remove => '제거';

  @override
  String get reference_enabled => '사용';

  @override
  String get reference_enable => '참조 사용';

  @override
  String get reference_disable => '참조 사용 안 함';

  @override
  String get vibe_normalize => '참조 강도 값 정규화';

  @override
  String get vibe_sourceType_png => 'PNG';

  @override
  String get vibe_sourceType_v4vibe => 'V4 Vibe';

  @override
  String get vibe_sourceType_bundle => '번들';

  @override
  String get vibe_sourceType_image => '이미지';

  @override
  String get vibe_sourceType => '소스';

  @override
  String get vibe_info => 'Vibe 정보';

  @override
  String get vibe_name => '이름';

  @override
  String get character_buttonLabel => '캐릭터/위치';

  @override
  String get character_addCharacter => '캐릭터 추가';

  @override
  String character_number(Object index) {
    return '캐릭터 $index';
  }

  @override
  String get gallery_generationParams => '생성 매개변수';

  @override
  String get gallery_metaModel => '모델';

  @override
  String get gallery_metaResolution => '해상도';

  @override
  String get gallery_metaSteps => '스텝';

  @override
  String get gallery_metaSampler => '샘플러';

  @override
  String get gallery_metaCfgScale => '프롬프트 가이던스';

  @override
  String get gallery_metaSeed => '시드';

  @override
  String get gallery_sendToKritaAction => 'Krita로 보내기';

  @override
  String get gallery_upscalePanelLoaded => 'Image2Image 업스케일 패널을 불러왔습니다';

  @override
  String gallery_readImageFailed(Object error) {
    return '이미지를 읽지 못했습니다: $error';
  }

  @override
  String get gallery_fileMissing => '파일이 존재하지 않습니다';

  @override
  String get gallery_copiedToClipboard => '클립보드에 복사했습니다';

  @override
  String gallery_copyFailed(Object error) {
    return '복사하지 못했습니다: $error';
  }

  @override
  String get gallery_upscale => '업스케일';

  @override
  String get gallery_sentToImg2Img => '이미지를 Image2Image로 보냈습니다';

  @override
  String gallery_sendFailed(Object error) {
    return '보내지 못했습니다: $error';
  }

  @override
  String get onlineGallery_login => '로그인';

  @override
  String get onlineGallery_pleaseLogin => '먼저 로그인하세요';

  @override
  String get mediaType_video => '동영상';

  @override
  String get mediaType_gif => 'GIF';

  @override
  String get onlineGallery_copied => '복사했습니다';

  @override
  String get onlineGallery_copyTags => '태그 복사';

  @override
  String get onlineGallery_sendToTextToImage => '텍스트로 이미지 생성으로 보내기';

  @override
  String get onlineGallery_sentToTextToImage => '텍스트로 이미지 생성으로 보냈습니다';

  @override
  String get onlineGallery_noTagInfo => '이 이미지에는 태그 정보가 없습니다';

  @override
  String get onlineGallery_chooseDownloadDirectory => '다운로드 폴더 선택';

  @override
  String get onlineGallery_downloadStarted => '다운로드를 시작했습니다...';

  @override
  String onlineGallery_savedToPath(Object path) {
    return '저장 위치: $path';
  }

  @override
  String onlineGallery_downloadFailed(Object error) {
    return '다운로드하지 못했습니다: $error';
  }

  @override
  String get onlineGallery_downloadOriginal => '원본 이미지 다운로드';

  @override
  String get onlineGallery_ratingGeneral => '전체 연령';

  @override
  String get onlineGallery_ratingSensitive => '민감';

  @override
  String get onlineGallery_ratingQuestionable => '의심';

  @override
  String get onlineGallery_ratingExplicit => '성인';

  @override
  String get onlineGallery_blacklistTitle => '온라인 갤러리 차단 목록';

  @override
  String get onlineGallery_blacklistSubtitle =>
      '차단 태그가 포함된 이미지는 온라인 갤러리에서 바로 숨겨집니다.';

  @override
  String get onlineGallery_addBlacklistTagHint => '차단 태그 추가';

  @override
  String get onlineGallery_noLocalBlacklistTags => '로컬 차단 태그가 없습니다';

  @override
  String get onlineGallery_autoSyncOnStartup => '시작할 때 자동 동기화';

  @override
  String get onlineGallery_autoSyncOnStartupSubtitle =>
      '기본으로 켜져 있으며 언제든 끌 수 있습니다';

  @override
  String onlineGallery_lastSyncFailed(Object error) {
    return '마지막 동기화 실패: $error';
  }

  @override
  String get onlineGallery_neverSyncedBlacklist =>
      'Danbooru 차단 목록을 아직 동기화하지 않았습니다';

  @override
  String onlineGallery_lastSync(Object time) {
    return '마지막 동기화: $time';
  }

  @override
  String get onlineGallery_blacklistSettingsTitle => '온라인 갤러리 차단 목록 설정';

  @override
  String get onlineGallery_blacklistLoginHint =>
      'Danbooru에 로그인하지 않았습니다. 로컬 차단 목록은 사용할 수 있지만 동기화하려면 로그인해야 합니다.';

  @override
  String onlineGallery_downloadSelectedCompleted(
    Object success,
    Object failed,
  ) {
    return '다운로드 완료: 성공 $success, 실패 $failed';
  }

  @override
  String get onlineGallery_gelbooruCredentialsRequired =>
      '웹사이트 즐겨찾기를 보려면 Gelbooru User ID와 API Key를 설정하세요.';

  @override
  String get onlineGallery_gelbooruCredentialsInvalid =>
      'Gelbooru 자격 증명이 더 이상 유효하지 않습니다. 다시 설정하세요.';

  @override
  String get onlineGallery_gelbooruRateLimited =>
      'Gelbooru에서 요청을 제한하고 있습니다. 잠시 후 다시 시도하세요.';

  @override
  String get onlineGallery_gelbooruTimeout =>
      'Gelbooru 요청 시간이 초과되었습니다. 네트워크 연결을 확인하세요.';

  @override
  String get onlineGallery_gelbooruServerError =>
      'Gelbooru를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도하세요.';

  @override
  String get onlineGallery_gelbooruNetworkError =>
      'Gelbooru에 연결할 수 없습니다. 네트워크나 프록시 설정을 확인하세요.';

  @override
  String get onlineGallery_gelbooruMalformedResponse =>
      'Gelbooru가 분석할 수 없는 데이터를 반환했습니다.';

  @override
  String get onlineGallery_gelbooruRequestFailed =>
      'Gelbooru 요청에 실패했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get onlineGallery_aiTagRankingProcessing =>
      '순위를 생성하는 중입니다. 잠시 후 다시 시도하세요.';

  @override
  String get onlineGallery_sourceConfigUnavailable =>
      '소스 설정을 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get onlineGallery_sourceRateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도하세요.';

  @override
  String get onlineGallery_sourceTimeout => '요청 시간이 초과되었습니다. 연결을 확인하세요.';

  @override
  String get onlineGallery_sourceNetworkError =>
      '이 갤러리 소스에 연결할 수 없습니다. 네트워크나 프록시를 확인하세요.';

  @override
  String get onlineGallery_sourceMalformedResponse =>
      '소스 응답 형식이 바뀌어 분석할 수 없습니다.';

  @override
  String get onlineGallery_detailNotFound => '작품이 존재하지 않거나 삭제되었습니다.';

  @override
  String get onlineGallery_imageUnavailable => '지금은 이 이미지를 사용할 수 없습니다.';

  @override
  String get onlineGallery_gelbooruReadOnly => '읽기 전용 즐겨찾기';

  @override
  String get tooltip_fullscreenEdit => '전체 화면 편집';

  @override
  String get tooltip_decreaseWeight => '가중치 낮추기 [-5%]';

  @override
  String get tooltip_increaseWeight => '가중치 높이기 [+5%]';

  @override
  String get tooltip_resetWeight => '클릭하면 100%로 초기화';

  @override
  String get upscale_scale => '배율';

  @override
  String get danbooru_loginTitle => 'Danbooru 로그인';

  @override
  String get danbooru_loginHint => '즐겨찾기를 사용하려면 사용자 이름과 API Key로 로그인하세요';

  @override
  String get danbooru_username => '사용자 이름';

  @override
  String get danbooru_usernameHint => 'Danbooru 사용자 이름 입력';

  @override
  String get danbooru_usernameRequired => '사용자 이름을 입력하세요';

  @override
  String get danbooru_apiKeyHint => 'API Key 입력';

  @override
  String get danbooru_apiKeyRequired => 'API Key를 입력하세요';

  @override
  String get danbooru_howToGetApiKey => 'API Key는 어떻게 받나요?';

  @override
  String get danbooru_loginSuccess => '로그인했습니다';

  @override
  String get gelbooru_configureTitle => 'Gelbooru API 설정';

  @override
  String get gelbooru_configureHint =>
      'Gelbooru 계정 설정에 표시된 User ID와 API Key를 입력하세요. 앱은 비밀번호나 브라우저 쿠키를 수집하지 않습니다.';

  @override
  String get gelbooru_userId => 'User ID';

  @override
  String get gelbooru_userIdHint => '양의 정수 User ID 입력';

  @override
  String get gelbooru_userIdRequired => '올바른 양의 정수 User ID를 입력하세요';

  @override
  String get gelbooru_apiKeyHint => 'API Key 입력';

  @override
  String get gelbooru_apiKeyRequired => 'API Key를 입력하세요';

  @override
  String get gelbooru_openAccountSettings => 'Gelbooru 계정 설정 열기';

  @override
  String get gelbooru_save => '확인 후 저장';

  @override
  String get gelbooru_saved => 'Gelbooru 자격 증명을 저장했습니다';

  @override
  String get gelbooru_removeCredentials => '자격 증명 제거';

  @override
  String get gelbooru_invalidInput => '올바른 User ID와 API Key를 입력하세요.';

  @override
  String get gelbooru_invalidCredentials =>
      'Gelbooru가 이 자격 증명을 거부했습니다. User ID와 API Key를 확인하세요.';

  @override
  String get gelbooru_rateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도하세요.';

  @override
  String get gelbooru_timeout => '확인 시간이 초과되었습니다. 네트워크 연결을 확인하세요.';

  @override
  String get gelbooru_serverError => 'Gelbooru를 일시적으로 사용할 수 없습니다.';

  @override
  String get gelbooru_networkError =>
      'Gelbooru에 연결할 수 없습니다. 네트워크나 프록시 설정을 확인하세요.';

  @override
  String get gelbooru_malformedResponse => 'Gelbooru가 분석할 수 없는 데이터를 반환했습니다.';

  @override
  String get gelbooru_storageError => 'Gelbooru 자격 증명을 안전하게 저장하거나 읽지 못했습니다.';

  @override
  String get gelbooru_unknownError => 'Gelbooru 확인에 실패했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get tag_addTag => '태그 추가';

  @override
  String get qualityTags_label => '품질';

  @override
  String get transparentBackground_tooltip =>
      '프롬프트에 \"transparent background\"를 추가하고 알파 채널이 있는 이미지를 생성합니다(V5 전용)';

  @override
  String get qualityTags_positive => '품질(프롬프트)';

  @override
  String get qualityTags_negative => '품질(네거티브)';

  @override
  String get qualityTags_disabled => '품질 태그가 꺼져 있습니다\n클릭하여 켜기';

  @override
  String get qualityTags_addToEnd => '프롬프트 끝에 추가:';

  @override
  String get qualityTags_addToStart => '프롬프트 앞에 추가:';

  @override
  String get qualityTags_naiDefault => 'NAI 기본값';

  @override
  String get qualityTags_standard => '표준';

  @override
  String get qualityTags_light => '가볍게';

  @override
  String get qualityTags_none => '없음';

  @override
  String get ucPreset_label => '네거티브 프리셋';

  @override
  String get ucPreset_heavy => '강하게';

  @override
  String get ucPreset_light => '가볍게';

  @override
  String get ucPreset_furryFocus => '퍼리';

  @override
  String get ucPreset_humanFocus => '인물';

  @override
  String get ucPreset_lowQuality => '저품질';

  @override
  String get ucPreset_badAnatomy => '잘못된 해부학';

  @override
  String get ucPreset_none => '없음';

  @override
  String get ucPreset_disabled => '네거티브 프리셋이 꺼져 있습니다';

  @override
  String get ucPreset_addToNegative => '네거티브에 추가:';

  @override
  String get ucPreset_nsfwHint =>
      '💡 성인 콘텐츠를 생성하려면 프롬프트에 nsfw를 추가하세요. 네거티브의 nsfw 태그는 자동으로 제거됩니다';

  @override
  String get generation_imageCount => '이미지 수';

  @override
  String get generation_requestCountTooltip => '요청 횟수: 클릭할 때마다 생성 요청을 N번 보냅니다';

  @override
  String generation_imageCountTotal(int requests, int perRequest, int total) {
    return '요청 $requests회 × $perRequest장 = 총 $total장';
  }

  @override
  String get warmup_networkCheck => '네트워크 연결 확인 중...';

  @override
  String get warmup_networkCheck_noProxy =>
      'NovelAI에 연결할 수 없습니다. VPN을 켜거나 프록시를 설정하세요';

  @override
  String get warmup_networkCheck_noSystemProxy =>
      '프록시를 사용하도록 설정했지만 시스템 프록시가 감지되지 않았습니다. VPN을 켜세요';

  @override
  String get warmup_networkCheck_manualIncomplete =>
      '수동 프록시 설정이 완전하지 않습니다. 설정을 확인하세요';

  @override
  String get warmup_networkCheck_testing => '네트워크 연결 테스트 중...';

  @override
  String get warmup_networkCheck_testingProxy => '프록시를 통해 네트워크 테스트 중...';

  @override
  String warmup_networkCheck_success(Object latency) {
    return '네트워크 연결 정상(${latency}ms)';
  }

  @override
  String get warmup_networkCheck_timeout => '네트워크 확인 시간 초과, 오프라인으로 계속합니다';

  @override
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts) {
    return '네트워크 확인 중... (시도 $attempt/$maxAttempts)';
  }

  @override
  String get warmup_preparing => '준비하는 중...';

  @override
  String get warmup_complete => '완료';

  @override
  String get warmup_danbooruAuth => 'Danbooru 인증 초기화 중...';

  @override
  String get warmup_loadingTranslation => '번역 데이터 불러오는 중...';

  @override
  String get warmup_initUnifiedDatabase => '태그 데이터베이스 초기화 중...';

  @override
  String get warmup_initTagSystem => '태그 시스템 초기화 중...';

  @override
  String get warmup_imageEditor => '이미지 편집기 초기화 중...';

  @override
  String get warmup_database => '최근 기록 불러오는 중...';

  @override
  String get warmup_network => '네트워크 연결 확인 중...';

  @override
  String get warmup_fonts => '글꼴 미리 불러오는 중...';

  @override
  String get warmup_imageCache => '이미지 캐시 준비 중...';

  @override
  String get warmup_statistics => '통계 불러오는 중...';

  @override
  String get warmup_artistsSync => '작가 데이터 동기화 중...';

  @override
  String get warmup_subscription => '구독 정보 불러오는 중...';

  @override
  String get warmup_dataSourceCache => '데이터 소스 캐시 초기화 중...';

  @override
  String get warmup_galleryFileCount => '갤러리 파일 스캔 중...';

  @override
  String get warmup_cooccurrenceData => '태그 동시 출현 데이터 불러오는 중...';

  @override
  String get warmup_group_basicUI => '기본 UI 서비스 초기화 중...';

  @override
  String get warmup_group_basicUI_complete => '기본 UI 서비스 준비 완료';

  @override
  String get warmup_group_dataServices => '데이터 서비스 초기화 중...';

  @override
  String get warmup_group_dataServices_complete => '데이터 서비스 준비 완료';

  @override
  String get warmup_group_networkServices => '네트워크 서비스 초기화 중...';

  @override
  String get warmup_group_networkServices_complete => '네트워크 서비스 준비 완료';

  @override
  String get warmup_group_cacheServices => '캐시 서비스 초기화 중...';

  @override
  String get warmup_group_cacheServices_complete => '캐시 서비스 준비 완료';

  @override
  String get warmup_cooccurrenceInit => '동시 출현 데이터 초기화 중...';

  @override
  String get warmup_translationInit => '번역 데이터 초기화 중...';

  @override
  String get warmup_danbooruTagsInit => 'Danbooru 태그 초기화 중...';

  @override
  String get warmup_dataMigration => 'Hive / Vibe / 이미지 데이터 이전 중...';

  @override
  String get warmup_galleryDataSource => '갤러리 인덱스 초기화 중...';

  @override
  String get warmup_checkAndRecoverData => '데이터 무결성 확인 중...';

  @override
  String get warmup_group_dataSourceInitialization => '데이터 소스 서비스 초기화 중...';

  @override
  String get warmup_group_dataSourceInitialization_complete =>
      '데이터 소스 서비스 준비 완료';

  @override
  String warmup_fetchingTags(Object message) {
    return '태그 동기화 중: $message';
  }

  @override
  String get warmup_fetchingTagDataFromServer => '서버에서 태그 데이터 가져오는 중...';

  @override
  String get warmup_fetchingGeneralTags => '일반 태그 가져오는 중...';

  @override
  String get warmup_fetchingCharacterTags => '캐릭터 태그 가져오는 중...';

  @override
  String get warmup_fetchingCopyrightTags => '저작권 태그 가져오는 중...';

  @override
  String get warmup_fetchingMetaTags => '메타 태그 가져오는 중...';

  @override
  String get resolution_groupNormal => '일반';

  @override
  String get resolution_groupLarge => '크게';

  @override
  String get resolution_groupWallpaper => '배경화면';

  @override
  String get resolution_groupSmall => '작게';

  @override
  String get resolution_groupCustom => '사용자 지정';

  @override
  String get resolution_typePortrait => '세로';

  @override
  String get resolution_typeLandscape => '가로';

  @override
  String get resolution_typeSquare => '정사각형';

  @override
  String get resolution_typeCustom => '사용자 지정';

  @override
  String get resolution_width => '너비';

  @override
  String get resolution_height => '높이';

  @override
  String get api_error_429 => '동시 요청 한도 도달';

  @override
  String get api_error_429_hint =>
      '요청이 너무 많습니다. 잠시 기다린 후 다시 시도하세요(공유 계정에서 자주 발생합니다)';

  @override
  String get api_error_401 => '인증 실패';

  @override
  String get api_error_401_hint => '토큰이 유효하지 않거나 만료되었습니다. 다시 로그인하세요';

  @override
  String get api_error_402 => '잔액 부족';

  @override
  String get api_error_402_hint => 'Anlas가 부족합니다. 충전한 뒤 다시 시도하세요';

  @override
  String get api_error_500 => '서버 오류';

  @override
  String get api_error_500_hint => 'NovelAI 서버 오류입니다. 잠시 후 다시 시도하세요';

  @override
  String get api_error_503 => '서비스 사용 불가';

  @override
  String get api_error_503_hint => '서버가 점검 중이거나 과부하 상태입니다. 잠시 후 다시 시도하세요';

  @override
  String get api_error_timeout => '요청 시간 초과';

  @override
  String get api_error_timeout_hint => '네트워크 시간이 초과되었습니다. 연결을 확인하고 다시 시도하세요';

  @override
  String get api_error_network => '네트워크 오류';

  @override
  String get api_error_network_hint => '서버에 연결할 수 없습니다. 네트워크를 확인하세요';

  @override
  String get drop_processing => '이미지 처리 중...';

  @override
  String get characterEditor_clearAll => '모두 지우기';

  @override
  String get characterEditor_clearAllTitle => '모든 캐릭터 지우기';

  @override
  String get characterEditor_clearAllConfirm =>
      '모든 캐릭터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get characterEditor_nameHint => '캐릭터 이름 입력';

  @override
  String get characterEditor_enabled => '사용';

  @override
  String get characterEditor_negativePromptHint => '이 캐릭터의 네거티브 입력...';

  @override
  String get characterCanvas_title => '캐릭터 위치';

  @override
  String get characterCanvas_finishEditing => '위치 편집 완료';

  @override
  String get characterCanvas_aiChoice => 'AI 선택';

  @override
  String get characterCanvas_custom => '사용자 지정';

  @override
  String get characterCanvas_aiHint => 'AI가 모든 캐릭터를 자동으로 배치합니다';

  @override
  String get characterCanvas_dragHint => '앵커를 끌어 캐릭터 위치를 정하고, 놓으면 적용됩니다';

  @override
  String get characterEditor_genderFemale => '여성';

  @override
  String get characterEditor_genderMale => '남성';

  @override
  String get characterEditor_genderOther => '기타';

  @override
  String get characterEditor_addFemale => '여';

  @override
  String get characterEditor_addMale => '남';

  @override
  String get characterEditor_addOther => '기타';

  @override
  String get characterEditor_moveUp => '위로 이동';

  @override
  String get characterEditor_moveDown => '아래로 이동';

  @override
  String get toolbar_fullscreenEdit => '전체 화면 편집';

  @override
  String get characterTooltip_noCharacters => '설정된 캐릭터가 없습니다';

  @override
  String get characterTooltip_clickToConfig => '클릭하여 다중 캐릭터 프롬프트 설정';

  @override
  String get characterTooltip_globalAiLabel => '전체 AI 위치:';

  @override
  String get characterTooltip_enabled => '사용';

  @override
  String get characterTooltip_disabled => '사용 안 함';

  @override
  String get characterTooltip_positionAi => 'AI';

  @override
  String get characterTooltip_disabledLabel => '사용 안 함';

  @override
  String get characterTooltip_promptLabel => '프롬프트';

  @override
  String get characterTooltip_negativeLabel => '네거티브';

  @override
  String get characterTooltip_notSet => '설정 안 됨';

  @override
  String characterTooltip_summary(Object total, Object enabled) {
    return '캐릭터 $total명(사용 $enabled명)';
  }

  @override
  String get characterTooltip_viewFullConfig => '클릭하여 전체 설정 보기';

  @override
  String get addGroup_displayNameLabel => '표시 이름(선택)';

  @override
  String get addGroup_targetCategoryLabel => '대상 분류';

  @override
  String globalSettings_saveFailed(Object error) {
    return '저장하지 못했습니다: $error';
  }

  @override
  String get nav_generate => '생성';

  @override
  String get nav_gallery => '갤러리';

  @override
  String get nav_settings => '설정';

  @override
  String get sync_preparing => '동기화 준비 중...';

  @override
  String sync_fetching(Object category) {
    return '$category 가져오는 중...';
  }

  @override
  String get sync_processing => '데이터 처리 중...';

  @override
  String get sync_saving => '저장하는 중...';

  @override
  String sync_completed(Object count) {
    return '동기화 완료, 태그 $count개';
  }

  @override
  String sync_failed(Object error) {
    return '동기화하지 못했습니다: $error';
  }

  @override
  String sync_extracting(Object poolName) {
    return '$poolName 태그 추출 중...';
  }

  @override
  String get sync_merging => '태그 병합 중...';

  @override
  String sync_fetching_tags(Object groupName) {
    return '$groupName 태그 인기도 가져오는 중...';
  }

  @override
  String get sync_filtering => '태그 필터링 중...';

  @override
  String get sync_done => '동기화 완료';

  @override
  String get time_just_now => '방금';

  @override
  String time_minutes_ago(Object n) {
    return '$n분 전';
  }

  @override
  String time_hours_ago(Object n) {
    return '$n시간 전';
  }

  @override
  String time_days_ago(Object n) {
    return '$n일 전';
  }

  @override
  String get time_never_synced => '동기화한 적 없음';

  @override
  String get vibeParseFailed => 'Vibe 파일을 분석하지 못했습니다';

  @override
  String get localGallery_progressiveLoadError => '이미지를 불러오지 못했습니다';

  @override
  String get localGallery_unknownError => '알 수 없는 오류';

  @override
  String localGallery_loadFailed(Object error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get localGallery_indexingLocalImages => '로컬 이미지 색인 중...';

  @override
  String get localGallery_emptyTitle => '로컬 이미지가 없습니다';

  @override
  String get localGallery_emptySubtitle => '생성한 이미지가 여기에 저장됩니다';

  @override
  String get localGallery_noMatchingResults => '일치하는 결과가 없습니다';

  @override
  String get localGallery_title => '로컬 갤러리';

  @override
  String get localGallery_allImages => '모든 이미지';

  @override
  String get localGallery_selectAllResults => '모두 선택';

  @override
  String get localGallery_deselectAllResults => '모두 선택 해제';

  @override
  String get localGallery_moveSelected => '이동';

  @override
  String get localGallery_packSelected => '묶기';

  @override
  String get localGallery_editMetadata => '편집';

  @override
  String get localGallery_addToCollection => '컬렉션';

  @override
  String get localGallery_sortButton => '정렬';

  @override
  String get localGallery_sortFieldModified => '수정한 시간';

  @override
  String get localGallery_sortFieldCreated => '만든 시간';

  @override
  String get localGallery_sortFieldName => '파일 이름';

  @override
  String get localGallery_sortFieldSize => '파일 크기';

  @override
  String get localGallery_sortFieldDimensions => '이미지 크기';

  @override
  String localGallery_aboutColumns(Object count) {
    return '약 $count열';
  }

  @override
  String get localGallery_columnWidth => '열 너비';

  @override
  String get localGallery_thumbnailQualitySd => '표준';

  @override
  String get localGallery_thumbnailQualityHd => '높음';

  @override
  String get settings_galleryThumbnailQuality => '로컬 갤러리 화질';

  @override
  String get settings_galleryThumbnailQualitySubtitle =>
      '썸네일 표시 화질이며 기본값은 높음입니다';

  @override
  String get localGallery_naiOnlyTooltip => 'NAI로 생성한 이미지만 표시';

  @override
  String get localGallery_naiVersionFilterTooltip => 'NAI 모델 버전으로 필터';

  @override
  String get localGallery_masonryViewLabel => '폭포형';

  @override
  String get localGallery_justifiedViewLabel => '양쪽 맞춤';

  @override
  String localGallery_dateRangeYearMonth(Object year, Object month) {
    return '$year/$month';
  }

  @override
  String get localGallery_dateRangePrevMonth => '이전 달';

  @override
  String get localGallery_dateRangeNextMonth => '다음 달';

  @override
  String get localGallery_dateRangeClear => '지우기';

  @override
  String localGallery_searchInScope(Object scope) {
    return '검색: $scope';
  }

  @override
  String get localGallery_hideCategoryPanel => '분류 패널 숨기기';

  @override
  String get localGallery_showCategoryPanel => '분류 패널 표시';

  @override
  String get localGallery_refreshTooltip =>
      '갤러리 새로 고침\n\n새로 추가되거나 바뀐 이미지를 자동으로 찾아 인덱스를 업데이트합니다';

  @override
  String get localGallery_tagIntersection => '태그 교집합';

  @override
  String get localGallery_createCategoryTitle => '새 분류';

  @override
  String get localGallery_newOrImport => '새로 만들기 / 가져오기';

  @override
  String get localGallery_importFolder => '폴더 가져오기';

  @override
  String get localGallery_createCategoryHint => '분류 이름을 입력하세요';

  @override
  String get localGallery_createCategoryConfirm => '만들기';

  @override
  String get localGallery_createSubCategoryTitle => '새 하위 분류';

  @override
  String get localGallery_showInFolder => '폴더에서 보기';

  @override
  String get localGallery_promptCopied => '프롬프트를 복사했습니다';

  @override
  String get localGallery_seedCopied => '시드를 복사했습니다';

  @override
  String get localGallery_createCollectionTitle => '새 컬렉션';

  @override
  String get localGallery_createCollectionHint => '컬렉션 이름 입력';

  @override
  String get localGallery_createCollectionConfirm => '만들기';

  @override
  String get localGallery_createCollectionFolderTitle => '새 컬렉션 폴더';

  @override
  String get localGallery_createCollectionFolderHint => '폴더 이름 입력';

  @override
  String get localGallery_createCollectionFolderConfirm => '만들기';

  @override
  String localGallery_deleteCollectionContent(Object name) {
    return '\"$name\" 컬렉션을 삭제하시겠습니까? 컬렉션 항목만 제거되며 이미지 파일은 삭제되지 않습니다.';
  }

  @override
  String localGallery_deleteCollectionFolderContent(Object name) {
    return '\"$name\" 컬렉션 폴더를 삭제하시겠습니까? 비어 있는 폴더이므로 폴더만 제거됩니다.';
  }

  @override
  String get localGallery_deleteCollectionFolderNonEmptyTitle => '폴더가 비어 있지 않음';

  @override
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name) {
    return '\"$name\" 컬렉션 폴더에 아직 컬렉션이나 하위 폴더가 있습니다. 먼저 하위 항목을 옮기거나 삭제하세요.';
  }

  @override
  String get localGallery_unfavorite => '즐겨찾기 해제';

  @override
  String get localGallery_favoriteMenuEmptyCollections =>
      '아직 컬렉션이 없습니다. 왼쪽의 +로 만드세요';

  @override
  String localGallery_confirmDeleteImageContent(Object name) {
    return '\"$name\" 이미지를 삭제하시겠습니까?\n\n이미지는 갤러리에서 즉시 사라지고, 파일은 다음 실행 때 완전히 삭제됩니다(이번 세션에서는 되돌릴 수 있습니다).';
  }

  @override
  String get localGallery_moveTo => '이동…';

  @override
  String get localGallery_copyTo => '복사…';

  @override
  String get localGallery_externalSourceMoveConfirmTitle => '외부 갤러리 파일 이동';

  @override
  String localGallery_externalSourceMoveConfirmContent(Object count) {
    return '이미지 $count장을 이동합니다. 파일이 원래 폴더에서 빠져나가 원래 위치에는 남지 않습니다. 계속하시겠습니까?';
  }

  @override
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '이미지 $count장을 외부 갤러리 소스 분류 \"$targetName\"(으)로 이동합니다. 파일은 외부 소스 폴더에 기록됩니다. 계속하시겠습니까?';
  }

  @override
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  ) {
    return '이미지 $count장을 외부 갤러리 소스 분류 \"$targetName\"(으)로 이동합니다. 파일은 원래 외부 소스 폴더에서 빠져나가(원래 위치에는 남지 않음) 외부 소스 폴더에 기록됩니다. 계속하시겠습니까?';
  }

  @override
  String get localGallery_uncategorizedRoot => '분류 안 됨(갤러리 루트)';

  @override
  String get localGallery_externalSourceChip => '외부';

  @override
  String get localGallery_categoryFilterHint => '분류 검색…';

  @override
  String localGallery_copySuccess(Object count) {
    return '이미지 $count장을 복사했습니다';
  }

  @override
  String get localGallery_copyFailed => '이미지를 복사하지 못했습니다';

  @override
  String get localGallery_confirmCopyContent => '이미지를 대상 폴더로 복사합니다. 확인하세요.';

  @override
  String get localGallery_categoryDeleteContent =>
      '이 분류를 삭제하시겠습니까? 폴더와 그 안의 내용은 유지됩니다.';

  @override
  String get localGallery_protectedDeleteCategoryTitle => '보호 모드: 분류 삭제 확인';

  @override
  String get localGallery_protectedDeleteCategoryContent =>
      '분류 기록을 삭제합니다. 폴더와 그 안의 내용은 유지됩니다. 다시 한번 확인하세요.';

  @override
  String get localGallery_confirmDelete => '삭제 확인';

  @override
  String get localGallery_confirmMoveImageTitle => '보호 모드: 이미지 이동 확인';

  @override
  String get localGallery_confirmMoveImageContent =>
      '이미지를 대상 분류 폴더로 이동합니다. 실수로 끈 것이 아닌지 확인하세요.';

  @override
  String get localGallery_confirmMove => '이동 확인';

  @override
  String get localGallery_imageMovedToCategory => '이미지를 분류로 이동했습니다';

  @override
  String get localGallery_categoriesSynced => '분류를 폴더와 동기화했습니다';

  @override
  String get localGallery_saveDirectoryNotSet => '저장 폴더가 설정되지 않았습니다';

  @override
  String get localGallery_folderNotFound => '폴더를 찾을 수 없습니다';

  @override
  String localGallery_openFolderFailed(Object error) {
    return '폴더를 열지 못했습니다: $error';
  }

  @override
  String get localGallery_protectedDeleteTitle => '보호 모드: 삭제 재확인';

  @override
  String localGallery_protectedDeleteImagesContent(Object count) {
    return '로컬 이미지 파일 $count개를 영구 삭제합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get localGallery_protectedBulkMoveTitle => '보호 모드: 일괄 이동 확인';

  @override
  String localGallery_protectedBulkMoveContent(Object count) {
    return '로컬 이미지 파일 $count개를 대상 폴더로 이동합니다. 실수가 아닌지 확인하세요.';
  }

  @override
  String localGallery_importParamsFailed(Object error) {
    return '매개변수를 가져오지 못했습니다: $error';
  }

  @override
  String localGallery_protectedDeleteImageContent(Object name) {
    return '\"$name\" 이미지를 영구 삭제합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get localGallery_saveZipArchive => 'ZIP 압축 파일 저장';

  @override
  String localGallery_packingImages(Object count) {
    return '이미지 $count장 묶는 중...';
  }

  @override
  String localGallery_packedImages(Object count) {
    return '이미지 $count장을 묶었습니다';
  }

  @override
  String get localGallery_packFailed => '이미지를 묶지 못했습니다';

  @override
  String get localGallery_imageFileMissing => '이미지 파일이 존재하지 않습니다';

  @override
  String get localGallery_sentToImageToImage => '이미지를 Image2Image로 보냈습니다';

  @override
  String localGallery_sendFailed(Object error) {
    return '보내지 못했습니다: $error';
  }

  @override
  String localGallery_sendToKritaFailed(Object error) {
    return 'Krita로 보내지 못했습니다: $error';
  }

  @override
  String get localGallery_sendToImg2Img => 'Image2Image로 보내기';

  @override
  String get localGallery_sendToStyleTransfer => 'Vibe 트랜스퍼로 보내기';

  @override
  String get localGallery_sendToPreciseReference => '정밀 참조로 보내기';

  @override
  String get localGallery_sendToKrita => 'Krita로 보내기';

  @override
  String get localGallery_importImageMetadata => '이미지 메타데이터 가져오기';

  @override
  String get localGallery_copyPrompt => '프롬프트 복사';

  @override
  String get localGallery_copySeed => '시드 복사';

  @override
  String get localGallery_dragToShare => '끌어서 공유';

  @override
  String galleryDragCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이미지 $count장',
      one: '이미지 1장',
    );
    return '$_temp0';
  }

  @override
  String get localGallery_moveToRoot => '루트로 이동';

  @override
  String get localGallery_withMetadata => '메타데이터 있음';

  @override
  String get localGallery_skipped => '건너뜀';

  @override
  String get localGallery_clearFilters => '필터 지우기';

  @override
  String get slideshow_of => '/';

  @override
  String get slideshow_play => '재생';

  @override
  String get slideshow_pause => '일시 정지';

  @override
  String get slideshow_previous => '이전';

  @override
  String get slideshow_next => '다음';

  @override
  String get slideshow_exit => '종료(Esc)';

  @override
  String get slideshow_noImages => '표시할 이미지가 없습니다';

  @override
  String get slideshow_keyboardHint => '← →로 이동, Space로 재생/일시 정지, Esc로 종료';

  @override
  String get comparison_noImages => '표시할 이미지가 없습니다';

  @override
  String get comparison_tooManyImages => '이미지가 너무 많습니다';

  @override
  String get comparison_maxImages => '최대 4장까지 비교할 수 있습니다';

  @override
  String get comparison_close => '비교 닫기';

  @override
  String get comparison_zoomHint => '손가락을 오므리거나 스크롤해 각각 확대/축소';

  @override
  String get comparison_loadError => '이미지를 불러오지 못했습니다';

  @override
  String get localGallery_group_today => '오늘';

  @override
  String get localGallery_group_yesterday => '어제';

  @override
  String localGallery_groupImageCount(int count, String formatted) {
    return '$formatted장';
  }

  @override
  String localGallery_imageCountLabel(int count, String formatted) {
    return '$formatted장';
  }

  @override
  String get localGallery_selectGroup => '그룹 선택';

  @override
  String get localGallery_inspectorTitle => '상세 정보';

  @override
  String localGallery_inspectorPosition(String index, String total) {
    return '$index / $total';
  }

  @override
  String get localGallery_inspectorEmpty => '이미지를 선택하면 상세 정보가 표시됩니다';

  @override
  String get localGallery_inspectorEmptyHint => '더블클릭하거나 Space 키를 눌러 크게 보기';

  @override
  String get localGallery_hideInspector => '상세 패널 숨기기';

  @override
  String get localGallery_showInspector => '상세 패널 표시';

  @override
  String get localGallery_reuseParams => '파라미터 재사용';

  @override
  String get localGallery_actionImg2Img => 'Image2Image';

  @override
  String get localGallery_actionStyleTransfer => 'Vibe 트랜스퍼';

  @override
  String get localGallery_actionPreciseReference => '정밀 참조';

  @override
  String get localGallery_actionSaveReference => '라이브러리 저장';

  @override
  String get localGallery_actionKrita => 'Krita';

  @override
  String localGallery_selectedImages(String count) {
    return '$count장 선택됨';
  }

  @override
  String get localGallery_sortDescending => '내림차순';

  @override
  String get localGallery_sortAscending => '오름차순';

  @override
  String get localGallery_moreActions => '더 보기';

  @override
  String get localGallery_thumbnailSize => '썸네일 크기';

  @override
  String get localGallery_naiOnlyChip => 'NAI 이미지만';

  @override
  String get localGallery_modelLabel => '모델';

  @override
  String get localGallery_allVersions => '전체';

  @override
  String get localGallery_allVariants => '모든 변형';

  @override
  String get localGallery_dateRangeChip => '기간';

  @override
  String get localGallery_groupByDay => '일별 묶기';

  @override
  String get localGallery_groupByMonth => '월별 묶기';

  @override
  String get localGallery_groupNone => '묶지 않음';

  @override
  String get localGallery_groupModeTooltip => '시간별 묶기';

  @override
  String get localGallery_sectionLibrary => '라이브러리';

  @override
  String get localGallery_sectionCollections => '컬렉션';

  @override
  String get localGallery_sectionFolders => '폴더';

  @override
  String get localGallery_dateFolders => '날짜 폴더';

  @override
  String localGallery_indexSynced(String count) {
    return '색인 동기화됨 · $count';
  }

  @override
  String localGallery_cannotOpenFolder(Object error) {
    return '폴더를 열 수 없습니다: $error';
  }

  @override
  String get localGallery_firstTimeTipTitle => '💡 도움말';

  @override
  String get localGallery_firstTimeTipContent =>
      '이미지를 마우스 오른쪽 버튼으로 클릭(데스크톱)하거나 길게 눌러(모바일) 다음 작업을 할 수 있습니다:\n\n• 프롬프트 복사\n• 시드 복사\n• 전체 메타데이터 보기';

  @override
  String get localGallery_gotIt => '확인했습니다';

  @override
  String get localGallery_undone => '실행 취소했습니다';

  @override
  String get localGallery_redone => '다시 실행했습니다';

  @override
  String get localGallery_confirmBulkDelete => '일괄 삭제 확인';

  @override
  String localGallery_confirmBulkDeleteContent(Object count) {
    return '선택한 이미지 $count장을 삭제하시겠습니까?\n\n이미지는 갤러리에서 즉시 사라지고, 파일은 다음 실행 때 완전히 삭제됩니다(이번 세션에서는 되돌릴 수 있습니다).';
  }

  @override
  String localGallery_deletedToPool(Object count) {
    return '이미지 $count장을 삭제했습니다. 다음 실행 때 완전히 삭제됩니다.';
  }

  @override
  String get localGallery_trashTitle => '휴지통';

  @override
  String get localGallery_trashEmpty => '휴지통이 비어 있습니다';

  @override
  String get localGallery_trashHint =>
      '휴지통의 파일은 아직 디스크에 있으며 다음 실행 때 완전히 삭제됩니다. 복원한 파일은 즉시 갤러리로 돌아갑니다.';

  @override
  String localGallery_trashCount(Object count) {
    return '$count개 항목';
  }

  @override
  String get localGallery_trashRestore => '복원';

  @override
  String get localGallery_trashRestoreAll => '모두 복원';

  @override
  String get localGallery_trashRestoreFailed => '복원하지 못했습니다';

  @override
  String localGallery_trashRestored(Object count) {
    return '이미지 $count장을 복원했습니다';
  }

  @override
  String get localGallery_trashDeleteAll => '영구 삭제';

  @override
  String localGallery_trashDeleteAllConfirm(Object count) {
    return '휴지통의 파일 $count개를 모두 즉시 영구 삭제합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String localGallery_trashDeletedForever(Object count) {
    return '파일 $count개를 영구 삭제했습니다';
  }

  @override
  String get localGallery_trashFileMissing => '파일이 더 이상 디스크에 없습니다';

  @override
  String localGallery_movedImages(Object count) {
    return '이미지 $count장을 이동했습니다';
  }

  @override
  String get localGallery_moveImagesFailed => '이미지를 이동하지 못했습니다';

  @override
  String localGallery_addedToCollection(Object count, Object name) {
    return '이미지 $count장을 \"$name\" 컬렉션에 추가했습니다';
  }

  @override
  String get localGallery_addToCollectionFailed => '이미지를 컬렉션에 추가하지 못했습니다';

  @override
  String get localGallery_removeFromCollection => '컬렉션에서 제거';

  @override
  String localGallery_removedFromCollection(Object count, Object name) {
    return '\"$name\" 컬렉션에서 이미지 $count장을 제거했습니다';
  }

  @override
  String get localGallery_notInCollection => '선택한 이미지가 이 컬렉션에 없습니다';

  @override
  String localGallery_removedFromFavorites(Object count) {
    return '즐겨찾기에서 이미지 $count장을 제거했습니다';
  }

  @override
  String get localGallery_alreadyInCollection => '이미 이 컬렉션에 있는 이미지입니다';

  @override
  String get brushPreset_selectHint => '두 번 탭하여 이 브러시 프리셋 선택';

  @override
  String get brushPreset_pencil => '연필';

  @override
  String get brushPreset_fine => '가는 브러시';

  @override
  String get brushPreset_standard => '표준 브러시';

  @override
  String get brushPreset_soft => '부드러운 브러시';

  @override
  String get brushPreset_airbrush => '에어브러시';

  @override
  String get brushPreset_marker => '마커';

  @override
  String get brushPreset_thick => '굵은 브러시';

  @override
  String get brushPreset_smudge => '문지르기 브러시';

  @override
  String bulkProgress_progress(Object current, Object total) {
    return '$total개 중 $current번째 처리 중';
  }

  @override
  String bulkProgress_success(Object count) {
    return '성공 $count개';
  }

  @override
  String bulkProgress_failed(Object count) {
    return '실패 $count개';
  }

  @override
  String get bulkProgress_errors => '오류:';

  @override
  String bulkProgress_moreErrors(Object count) {
    return '...외 오류 $count개';
  }

  @override
  String bulkProgress_completed(Object count) {
    return '$count개 항목 완료';
  }

  @override
  String bulkProgress_completedWithErrors(Object success, Object failed) {
    return '성공 $success개, 실패 $failed개';
  }

  @override
  String get bulkProgress_title_delete => '이미지 삭제 중';

  @override
  String get bulkProgress_title_export => '메타데이터 내보내는 중';

  @override
  String get bulkProgress_title_metadataEdit => '메타데이터 편집 중';

  @override
  String get bulkProgress_title_addToCollection => '컬렉션에 추가하는 중';

  @override
  String get bulkProgress_title_removeFromCollection => '컬렉션에서 제거하는 중';

  @override
  String get bulkProgress_title_toggleFavorite => '즐겨찾기 업데이트 중';

  @override
  String get bulkProgress_title_default => '처리 중';

  @override
  String bulkProgress_errorDeleteFailed(String error) {
    return '이미지를 삭제하지 못했습니다: $error';
  }

  @override
  String get bulkProgress_errorNoImagesToExport => '내보낼 이미지가 없습니다';

  @override
  String get bulkProgress_errorExportFailed => '내보내지 못했습니다';

  @override
  String bulkProgress_errorExportFailedWithDetails(String error) {
    return '내보내지 못했습니다: $error';
  }

  @override
  String get bulkProgress_errorNoMetadataChanges => '추가하거나 제거할 태그를 하나 이상 입력하세요';

  @override
  String bulkProgress_errorMetadataEditFailed(String error) {
    return '이미지 메타데이터를 편집하지 못했습니다: $error';
  }

  @override
  String bulkProgress_errorFavoriteFailed(String error) {
    return '즐겨찾기를 업데이트하지 못했습니다: $error';
  }

  @override
  String get bulkProgress_errorNoImagesForCollection => '컬렉션에 추가할 이미지가 없습니다';

  @override
  String bulkProgress_errorAddToCollectionFailed(String error) {
    return '이미지를 컬렉션에 추가하지 못했습니다: $error';
  }

  @override
  String get bulkProgress_errorNothingToUndo => '실행 취소할 작업이 없습니다';

  @override
  String bulkProgress_errorUndoFailed(String error) {
    return '실행 취소하지 못했습니다: $error';
  }

  @override
  String get bulkProgress_errorNothingToRedo => '다시 실행할 작업이 없습니다';

  @override
  String bulkProgress_errorRedoFailed(String error) {
    return '다시 실행하지 못했습니다: $error';
  }

  @override
  String get collectionSelect_dialogTitle => '컬렉션 선택';

  @override
  String get collectionSelect_removeTitle => '컬렉션에서 제거';

  @override
  String collectionSelect_memberCount(Object n) {
    return '이 컬렉션에 선택 항목 $n개';
  }

  @override
  String get collectionSelect_noSelectedInCollection => '이 컬렉션에 선택한 이미지가 없습니다';

  @override
  String collectionSelect_memberCountInFavorites(Object n) {
    return '즐겨찾기에 선택 항목 $n개';
  }

  @override
  String get collectionSelect_filterHint => '컬렉션 검색...';

  @override
  String get collectionSelect_noCollections => '컬렉션이 없습니다';

  @override
  String get collectionSelect_createCollectionHint => '먼저 컬렉션을 만드세요';

  @override
  String get collectionSelect_noFilterResults => '일치하는 컬렉션이 없습니다';

  @override
  String collectionSelect_imageCount(int count) {
    return '이미지 $count장';
  }

  @override
  String get autocomplete_categoryCharacter => '캐릭터';

  @override
  String get autocomplete_categoryCopyright => '저작권';

  @override
  String get autocomplete_categoryArtist => '작가';

  @override
  String get autocomplete_categoryMeta => '메타';

  @override
  String get autocomplete_categoryContributor => '기여자';

  @override
  String get autocomplete_categorySpecies => '종족';

  @override
  String get autocomplete_categoryLore => '설정';

  @override
  String get autocomplete_categoryLibrary => '라이브러리';

  @override
  String get autocomplete_categoryGeneral => '일반';

  @override
  String get promptToken_webCalibration => '웹 보정';

  @override
  String get promptToken_prompt => '프롬프트';

  @override
  String get promptToken_qualityPreset => '품질 프리셋';

  @override
  String get promptToken_character => '캐릭터';

  @override
  String get promptToken_negativePrompt => '네거티브';

  @override
  String get promptToken_negativePreset => '네거티브 프리셋';

  @override
  String get promptToken_characterNegative => '캐릭터 네거티브';

  @override
  String get common_rename => '이름 변경';

  @override
  String get tagLibrary_tags => '태그';

  @override
  String get settings_network => '네트워크';

  @override
  String get settings_enableProxy => '프록시 사용';

  @override
  String get settings_proxyEnabled => '사용';

  @override
  String get settings_proxyDisabled => '직접 연결';

  @override
  String get settings_proxyTrafficDisclosure =>
      '프록시를 사용하면 인증 요청을 포함한 NovelAI API 트래픽이 시스템 프록시나 수동 프록시를 거쳐 전송됩니다. 신뢰할 수 있는 프록시만 사용하세요.';

  @override
  String get settings_proxyMode => '프록시 모드';

  @override
  String get settings_proxyModeAuto => '시스템 프록시 자동 감지';

  @override
  String get settings_proxyModeManual => '수동 설정';

  @override
  String get settings_auto => '자동';

  @override
  String get settings_manual => '수동';

  @override
  String get settings_proxyHost => '프록시 호스트';

  @override
  String get settings_proxyPort => '포트';

  @override
  String get settings_proxyNotDetected => '시스템 프록시가 감지되지 않았습니다';

  @override
  String get settings_testConnection => '연결 테스트';

  @override
  String get settings_testConnectionHint => '클릭하여 프록시가 작동하는지 테스트';

  @override
  String settings_testSuccess(Object latency) {
    return '연결 성공(${latency}ms)';
  }

  @override
  String settings_testFailed(Object error) {
    return '연결하지 못했습니다: $error';
  }

  @override
  String get settings_proxyRestartHint => '프록시 설정이 바뀌었습니다. 다시 시작하는 것이 좋습니다';

  @override
  String get tagLibrary_addToLibrary => '라이브러리에 추가';

  @override
  String get tagLibrary_uncategorized => '분류 안 됨';

  @override
  String get tagLibrary_contentPreview => '내용 미리 보기';

  @override
  String get settings_enablePromptWeightScroll => '마우스 휠로 프롬프트 가중치 조정';

  @override
  String get settings_enablePromptWeightScrollSubtitle =>
      '프롬프트 텍스트를 선택한 상태에서 지정한 보조 키를 누른 채 휠을 돌리면 가중치가 조정됩니다. 보조 키 없이 휠을 돌리면 평소처럼 페이지가 스크롤됩니다.';

  @override
  String get settings_weightScrollModifierAlt => 'Alt';

  @override
  String get settings_weightScrollModifierCtrl => 'Ctrl';

  @override
  String get settings_weightScrollModifierShift => 'Shift';

  @override
  String get settings_weightScrollModifierNone => '없음(이전 방식)';

  @override
  String get unit_seconds => '초';

  @override
  String get settings_notificationSound => '완료 효과음';

  @override
  String get settings_notificationSoundSubtitle =>
      '창이 포커스를 잃었을 때만 완료 효과음을 재생합니다';

  @override
  String get settings_notificationCustomSound => '사용자 지정 효과음';

  @override
  String get settings_notificationSelectSound => '효과음 선택';

  @override
  String get settings_notificationResetSound => '기본값으로 초기화';

  @override
  String get resetToDefault => '기본값으로 초기화';

  @override
  String get metadataImport_title => '가져올 매개변수 선택';

  @override
  String get metadataImport_promptsSection => '프롬프트';

  @override
  String get metadataImport_generationSection => '생성 매개변수';

  @override
  String get metadataImport_selectAll => '모두 선택';

  @override
  String get metadataImport_promptsOnly => '프롬프트만';

  @override
  String get metadataImport_generationOnly => '매개변수만';

  @override
  String get metadataImport_clear => '지우기';

  @override
  String get metadataImport_prompt => '프롬프트';

  @override
  String get metadataImport_mainPrompt => '메인 프롬프트';

  @override
  String metadataImport_qualityTagsCount(int count) {
    return '품질 태그($count)';
  }

  @override
  String get metadataImport_negativePrompt => '네거티브 프롬프트';

  @override
  String get metadataImport_characterPrompts => '캐릭터 프롬프트';

  @override
  String metadataImport_characterPromptsCount(int count) {
    return '캐릭터 프롬프트($count)';
  }

  @override
  String metadataImport_characterIndex(int index, Object text) {
    return '캐릭터 $index: $text';
  }

  @override
  String get metadataImport_referenceSection => '참조';

  @override
  String metadataImport_countUnit(int count) {
    return '$count개';
  }

  @override
  String metadataImport_preciseReferenceCount(int count) {
    return '정밀 참조($count)';
  }

  @override
  String metadataImport_vibeDetail(Object name, Object strength, Object info) {
    return '$name(참조 강도 $strength%, 정보 추출량 $info%)';
  }

  @override
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  ) {
    return '참조 $index: $type(강도 $strength%, 충실도 $fidelity%)';
  }

  @override
  String get metadataImport_seed => '시드';

  @override
  String get metadataImport_steps => '스텝';

  @override
  String get metadataImport_scale => '프롬프트 가이던스';

  @override
  String get metadataImport_size => '크기';

  @override
  String get metadataImport_sampler => '샘플러';

  @override
  String get metadataImport_model => '모델';

  @override
  String get metadataImport_smea => 'SMEA';

  @override
  String get metadataImport_smeaDyn => 'SMEA Dyn';

  @override
  String get metadataImport_noiseSchedule => '노이즈 스케줄';

  @override
  String get metadataImport_cfgRescale => '프롬프트 가이던스 리스케일';

  @override
  String get metadataImport_qualityToggle => '품질 전환';

  @override
  String get metadataImport_ucPreset => '네거티브 프리셋';

  @override
  String get metadataImport_noData => '(데이터 없음)';

  @override
  String metadataImport_selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get metadataImport_noDataFound => 'NovelAI 메타데이터를 찾을 수 없습니다';

  @override
  String metadataImport_appliedCount(int count) {
    return '매개변수 $count개를 적용했습니다';
  }

  @override
  String get metadataImport_appliedTitle => '메타데이터 적용됨';

  @override
  String get metadataImport_appliedDescription => '다음 매개변수를 적용했습니다:';

  @override
  String get metadataImport_charactersCount => '명';

  @override
  String get shortcut_context_global => '전역';

  @override
  String get shortcut_context_generation => '생성';

  @override
  String get shortcut_context_gallery => '갤러리 목록';

  @override
  String get shortcut_context_viewer => '이미지 뷰어';

  @override
  String get shortcut_context_settings => '설정';

  @override
  String get shortcut_context_input => '입력란';

  @override
  String get shortcut_action_navigate_to_generation => '생성 페이지';

  @override
  String get shortcut_action_navigate_to_local_gallery => '로컬 갤러리';

  @override
  String get shortcut_action_navigate_to_online_gallery => '온라인 갤러리';

  @override
  String get shortcut_action_navigate_to_tag_library => '프롬프트 블록 라이브러리';

  @override
  String get shortcut_action_navigate_to_statistics => '통계';

  @override
  String get shortcut_action_navigate_to_settings => '설정';

  @override
  String get shortcut_action_generate_image => '이미지 생성';

  @override
  String get shortcut_action_generation_prev_image => '이전 미리 보기(기록 연동)';

  @override
  String get shortcut_action_generation_next_image => '다음 미리 보기(기록 연동)';

  @override
  String get shortcut_action_cancel_generation => '생성 취소';

  @override
  String get shortcut_action_clear_prompt => '프롬프트 지우기';

  @override
  String get shortcut_action_toggle_prompt_mode => '프롬프트 모드 전환';

  @override
  String get shortcut_action_open_tag_library => '프롬프트 블록 라이브러리 열기';

  @override
  String get shortcut_action_save_image => '이미지 저장';

  @override
  String get shortcut_action_upscale_image => '이미지 업스케일';

  @override
  String get shortcut_action_copy_image => '이미지 복사';

  @override
  String get shortcut_action_fullscreen_preview => '전체 화면 미리 보기';

  @override
  String get shortcut_action_open_params_panel => '매개변수 패널 열기';

  @override
  String get shortcut_action_open_history_panel => '기록 패널 열기';

  @override
  String get shortcut_action_reuse_params => '매개변수 재사용';

  @override
  String get shortcut_action_previous_image => '이전 이미지';

  @override
  String get shortcut_action_next_image => '다음 이미지';

  @override
  String get shortcut_action_zoom_in => '확대';

  @override
  String get shortcut_action_zoom_out => '축소';

  @override
  String get shortcut_action_reset_zoom => '확대/축소 초기화';

  @override
  String get shortcut_action_toggle_fullscreen => '전체 화면 전환';

  @override
  String get shortcut_action_close_viewer => '뷰어 닫기';

  @override
  String get shortcut_action_toggle_favorite => '즐겨찾기 전환';

  @override
  String get shortcut_action_copy_prompt => '프롬프트 복사';

  @override
  String get shortcut_action_reuse_gallery_params => '매개변수 재사용';

  @override
  String get shortcut_action_delete_image => '이미지 삭제';

  @override
  String get shortcut_action_previous_page => '한 화면 위로';

  @override
  String get shortcut_action_next_page => '한 화면 아래로';

  @override
  String get shortcut_action_refresh_gallery => '갤러리 새로 고침';

  @override
  String get shortcut_action_focus_search => '검색으로 이동';

  @override
  String get shortcut_action_enter_selection_mode => '모두 선택';

  @override
  String get shortcut_action_clear_filter => '필터 지우기';

  @override
  String get shortcut_action_toggle_category_panel => '분류 패널 전환';

  @override
  String get shortcut_action_jump_to_date => '날짜로 이동';

  @override
  String get shortcut_action_open_folder => '폴더 열기';

  @override
  String get shortcut_action_minimize_to_tray => '트레이로 최소화';

  @override
  String get shortcut_action_quit_app => '앱 종료';

  @override
  String get shortcut_action_show_shortcut_help => '단축키 도움말 표시';

  @override
  String get shortcut_action_toggle_theme => '테마 전환';

  @override
  String get shortcut_settings_title => '키보드 단축키';

  @override
  String get shortcut_settings_enable => '단축키 사용';

  @override
  String get shortcut_settings_show_badges => '단축키 배지 표시';

  @override
  String get shortcut_settings_show_in_tooltips => '도구 설명에 표시';

  @override
  String get shortcut_settings_reset_all => '모두 기본값으로 초기화';

  @override
  String get shortcut_settings_search => '단축키 검색...';

  @override
  String get shortcut_settings_press_key => '키 조합을 누르세요...';

  @override
  String get shortcut_help_title => '키보드 단축키 도움말';

  @override
  String get shortcut_help_search => '단축키 검색...';

  @override
  String get shortcut_help_all => '전체';

  @override
  String get shortcut_help_fabTooltip => '키보드 단축키 도움말(F1)';

  @override
  String get shortcut_editor_recordingInline => '단축키를 누르세요...';

  @override
  String get shortcut_editor_pressEscToCancel => 'Esc를 눌러 취소';

  @override
  String get shortcut_editor_clickToRecord => '클릭하여 녹화 시작';

  @override
  String shortcut_editor_conflictWith(Object action) {
    return '이 단축키는 \"$action\"과(와) 충돌합니다';
  }

  @override
  String get drop_hint => '여기에 이미지를 놓으세요';

  @override
  String get drop_img2img => 'Image2Image';

  @override
  String get drop_vibeTransfer => 'Vibe 트랜스퍼';

  @override
  String get drop_characterReference => '정밀 참조';

  @override
  String get drop_unsupportedFormat => '지원하지 않는 파일 형식입니다';

  @override
  String get drop_addedToImg2Img => 'Image2Image에 추가했습니다';

  @override
  String get drop_addedToVibe => 'Vibe 트랜스퍼에 추가했습니다';

  @override
  String drop_addedMultipleToVibe(int count) {
    return 'Vibe 참조 $count개를 추가했습니다';
  }

  @override
  String get drop_addedToCharacterRef => '정밀 참조에 추가했습니다';

  @override
  String get drop_vibeDetected => '미리 인코딩된 Vibe를 감지했습니다(2 Anlas 절약)';

  @override
  String get drop_reuseVibe => 'Vibe 재사용';

  @override
  String get drop_useAsRawImage => '원본 이미지로 사용';

  @override
  String get drop_dragToImg2ImgOrOther => 'Image2Image나 다른 대상으로 끌어 놓으세요';

  @override
  String get preciseRef_title => '정밀 참조';

  @override
  String get preciseRef_subtitle => '캐릭터나 스타일 참조에 맞춰 생성합니다';

  @override
  String get preciseRef_description =>
      '참조 이미지를 추가하고 유형과 매개변수를 설정하세요. 여러 참조를 동시에 사용할 수 있습니다.';

  @override
  String get preciseRef_addReference => '참조 추가';

  @override
  String get preciseRef_clearAll => '모두 지우기';

  @override
  String get preciseRef_remove => '제거';

  @override
  String get preciseRef_referenceType => '참조 유형';

  @override
  String get preciseRef_strength => '강도';

  @override
  String get preciseRef_fidelity => '충실도';

  @override
  String get preciseRef_v4Only => '이 기능은 V4 이상 모델이 필요합니다';

  @override
  String get preciseRef_typeCharacter => '캐릭터';

  @override
  String get preciseRef_typeStyle => '스타일';

  @override
  String get preciseRef_typeCharacterAndStyle => '캐릭터 + 스타일';

  @override
  String get preciseRef_costHint => '정밀 참조를 사용하면 Anlas가 추가로 소비됩니다';

  @override
  String get preciseRef_costBadge => 'Anlas 사용';

  @override
  String get preciseRef_dropToAdd => '놓으면 정밀 참조를 추가합니다';

  @override
  String get preciseRef_dropNoReadableImage =>
      '놓은 항목에서 읽을 수 있는 이미지 파일이나 이미지 링크를 찾지 못했습니다';

  @override
  String preciseRef_addedCount(int count) {
    return '정밀 참조 $count개를 추가했습니다';
  }

  @override
  String preciseRef_removedCount(int count) {
    return '정밀 참조 $count개를 제거했습니다';
  }

  @override
  String get vibeLibrary_title => 'Vibe 라이브러리';

  @override
  String get vibeLibrary_uncategorized => '분류 안 됨';

  @override
  String vibeLibrary_importSuccessCount(Object count) {
    return 'Vibe $count개를 가져왔습니다';
  }

  @override
  String vibeLibrary_importSummary(Object success, Object failed) {
    return '가져오기 완료: 성공 $success, 실패 $failed';
  }

  @override
  String get vibeLibrary_save => '라이브러리에 저장';

  @override
  String get vibeLibrary_import => 'Vibe 가져오기';

  @override
  String get vibeLibrary_sendToGeneration => '생성으로 보내기';

  @override
  String get vibeLibrary_maxVibesReached => '최대 개수에 도달했습니다(Vibe 16개)';

  @override
  String get vibeLibrary_bundleReadFailed => '번들 파일을 읽지 못해 단일 파일 모드를 사용합니다';

  @override
  String categoryError_loadFailed(String error) {
    return '분류를 불러오지 못했습니다: $error';
  }

  @override
  String categoryError_syncFailed(String error) {
    return '분류를 동기화하지 못했습니다: $error';
  }

  @override
  String get categoryError_nameEmpty => '분류 이름은 비워 둘 수 없습니다';

  @override
  String get categoryError_parentNotFound => '상위 분류가 존재하지 않습니다';

  @override
  String categoryError_createFailed(String error) {
    return '분류를 만들지 못했습니다: $error';
  }

  @override
  String get categoryError_notFound => '분류가 존재하지 않습니다';

  @override
  String categoryError_renameFailed(String error) {
    return '분류 이름을 변경하지 못했습니다: $error';
  }

  @override
  String get categoryError_invalidMove => '분류를 자신의 하위 분류 아래로 옮길 수 없습니다';

  @override
  String categoryError_moveFailed(String error) {
    return '분류를 이동하지 못했습니다: $error';
  }

  @override
  String get categoryError_hasSubcategories =>
      '이 분류에 하위 분류가 있습니다. 먼저 하위 분류를 삭제하세요.';

  @override
  String categoryError_deleteFailed(String error) {
    return '분류를 삭제하지 못했습니다: $error';
  }

  @override
  String categoryError_moveImageFailed(String error) {
    return '이미지를 이동하지 못했습니다: $error';
  }

  @override
  String categoryError_moveImagesFailed(String error) {
    return '이미지를 이동하지 못했습니다: $error';
  }

  @override
  String categoryError_reorderFailed(String error) {
    return '분류 순서를 바꾸지 못했습니다: $error';
  }

  @override
  String get vibe_export_title => 'Vibe 내보내기';

  @override
  String get vibe_selector_recent => '최근';

  @override
  String vibe_export_dialogTitle(int count) {
    return 'Vibe $count개 내보내기';
  }

  @override
  String get vibe_export_chooseMethod => 'Vibe 내보내기 방식 선택';

  @override
  String get vibe_export_asBundle => '번들로';

  @override
  String get vibe_export_individually => '개별로';

  @override
  String get vibe_export_noData => '내보낼 데이터가 없습니다';

  @override
  String get vibe_export_success => '내보냈습니다';

  @override
  String get vibe_export_failed => '내보내지 못했습니다';

  @override
  String vibe_export_skipped(int count) {
    return '데이터가 없는 Vibe $count개를 건너뛰었습니다';
  }

  @override
  String vibe_export_bundleSuccess(int count) {
    return '번들을 내보냈습니다: Vibe $count개';
  }

  @override
  String get vibe_export_selectToEmbed => '포함할 Vibe 선택';

  @override
  String get vibe_export_pngRequired => 'PNG 파일이 필요합니다';

  @override
  String get vibe_export_noEmbeddableData => '포함할 수 있는 데이터가 없습니다';

  @override
  String vibe_export_embedSuccess(int count) {
    return 'Vibe $count개를 이미지에 포함했습니다';
  }

  @override
  String get vibe_export_embedFailed => '포함하지 못했습니다';

  @override
  String get vibe_embedToImage => '이미지에 포함';

  @override
  String get vibe_import_noEncodingData => '인코딩 데이터 없음';

  @override
  String get vibe_import_encodingCost => '인코딩에 2 Anlas가 소비됩니다';

  @override
  String get vibe_import_confirmCost => '계속하고 Anlas를 소비하시겠습니까?';

  @override
  String get vibe_import_encodeNow => '지금 인코딩(2 Anlas)';

  @override
  String get vibe_addImageOnly => '이미지만 추가';

  @override
  String get vibe_import_autoSave => '라이브러리에 자동 저장';

  @override
  String get vibe_import_encodingFailed => '인코딩 실패';

  @override
  String get vibe_import_encodingFailedMessage =>
      'Vibe를 인코딩하지 못했습니다. 인코딩하지 않은 이미지로 계속 추가하시겠습니까?';

  @override
  String get vibe_import_encodingInProgress => '인코딩 중...';

  @override
  String get vibe_import_encodingComplete => '인코딩 완료';

  @override
  String get vibe_import_partialFailed => '일부 인코딩 실패';

  @override
  String get vibe_import_timeout => '인코딩 시간 초과';

  @override
  String get vibe_import_fileParseFailed => '파일을 분석하지 못했습니다';

  @override
  String get vibe_import_fileSelectionFailed => '파일을 선택하지 못했습니다';

  @override
  String get vibe_import_importFailed => '가져오지 못했습니다';

  @override
  String get vibe_saveToLibrary_title => '라이브러리에 저장';

  @override
  String get vibe_saveToLibrary_strength => '강도';

  @override
  String get vibe_saveToLibrary_infoExtracted => '정보 추출량';

  @override
  String vibe_saveToLibrary_saving(int count) {
    return 'Vibe $count개 저장 중';
  }

  @override
  String get vibe_saveToLibrary_saveFailed => '라이브러리에 저장하지 못했습니다';

  @override
  String vibe_saveToLibrary_savingCount(int count) {
    return 'Vibe $count개 저장 중';
  }

  @override
  String get vibe_saveToLibrary_nameLabel => '이름';

  @override
  String get vibe_saveToLibrary_nameHint => 'Vibe 이름 입력';

  @override
  String vibe_saveToLibrary_mixed(int saved, int reused) {
    return '$saved개 저장, $reused개 재사용';
  }

  @override
  String vibe_saveToLibrary_saved(int count) {
    return '라이브러리에 $count개를 저장했습니다';
  }

  @override
  String vibe_saveToLibrary_reused(int count) {
    return '라이브러리에서 $count개를 재사용했습니다';
  }

  @override
  String get vibe_saveToLibrary_saveAsBundle => '번들로 저장';

  @override
  String vibe_saveToLibrary_saveAsBundleDescription(int count) {
    return 'Vibe $count개를 번들 하나로 저장합니다';
  }

  @override
  String get vibe_saveToLibrary_tagHint => '태그를 입력한 뒤 추가를 누르세요';

  @override
  String get vibe_maxReached => '최대 16개의 Vibe에 도달했습니다';

  @override
  String vibe_addedCount(int count) {
    return 'Vibe $count개를 추가했습니다';
  }

  @override
  String get vibe_statusEncoded => '인코딩됨';

  @override
  String get vibe_statusEncoding => '인코딩 중...';

  @override
  String get vibe_statusPendingEncode => '인코딩(2 Anlas)';

  @override
  String get vibe_encodeDialogTitle => 'Vibe 인코딩 확인';

  @override
  String get vibe_encodeDialogMessage => '생성에 사용하도록 이 이미지를 인코딩하시겠습니까?';

  @override
  String get vibe_encodeCostWarning => '2 Anlas(크레딧)가 소비됩니다';

  @override
  String get vibe_encodeButton => '인코딩';

  @override
  String get vibe_encodeSuccess => 'Vibe를 인코딩했습니다!';

  @override
  String get vibe_encodeFailed => 'Vibe를 인코딩하지 못했습니다. 다시 시도하세요';

  @override
  String vibe_encodeError(String error) {
    return '인코딩하지 못했습니다: $error';
  }

  @override
  String get shortcuts_customize => '단축키 사용자 지정';

  @override
  String get selection_clear_selection => '선택 해제';

  @override
  String get selection_invert_selection => '선택 반전';

  @override
  String get selection_cut_to_layer => '레이어로 잘라내기';

  @override
  String get selectAll => '모두 선택';

  @override
  String get clearSelection => '지우기';

  @override
  String get shortcut_context_vibe_detail => 'Vibe 상세';

  @override
  String get shortcut_action_vibe_detail_rename => '이름 변경';

  @override
  String get tray_show => '창 표시';

  @override
  String get tray_exit => '종료';

  @override
  String get settings_shortcutsSubtitle => '키보드 단축키를 사용자 지정합니다';

  @override
  String get settings_openFolder => '폴더 열기';

  @override
  String get settings_openFolderFailed => '폴더를 열지 못했습니다';

  @override
  String get settings_vibePathSaved => 'Vibe 라이브러리 경로를 저장했습니다';

  @override
  String get settings_selectFolderFailed => '폴더를 선택하지 못했습니다';

  @override
  String get settings_hivePathSaved => '데이터 저장 경로를 저장했습니다. 다시 시작하면 적용됩니다';

  @override
  String get settings_restartRequiredTitle => '다시 시작 필요';

  @override
  String get settings_changePathConfirm =>
      '데이터 저장 경로를 변경하면 앱을 다시 시작해야 적용됩니다.\\n\\n새 경로는 다음 실행 때 적용됩니다. 계속하시겠습니까?';

  @override
  String get settings_resetPathConfirm =>
      '데이터 저장 경로를 초기화하면 앱을 다시 시작해야 적용됩니다.\\n\\n기본 경로는 다음 실행 때 적용됩니다. 계속하시겠습니까?';

  @override
  String get settings_kritaBridgeEnable => '로컬 연결 활성화';

  @override
  String get settings_kritaBridgeDisabledText =>
      '기본값은 꺼짐이며, 켜면 로컬 127.0.0.1에서만 수신합니다';

  @override
  String get settings_kritaBridgeStartingText => '로컬 브리지 서비스 시작 중...';

  @override
  String get settings_kritaBridgeListeningText => '외부 Agent 또는 Krita 연결 대기 중';

  @override
  String get settings_kritaBridgeConnectedText => 'Krita 플러그인 연결됨';

  @override
  String get settings_kritaBridgeErrorText => '시작하지 못했습니다. 오류 메시지를 확인하세요';

  @override
  String get settings_kritaBridgeRegenerateSession => '세션 다시 만들기';

  @override
  String get settings_kritaBridgeDiscoveryFile => '검색 파일';

  @override
  String get settings_kritaBridgeWaitingEndpoint => '로컬 WebSocket 수신 대기 중';

  @override
  String settings_kritaBridgeClient(Object client) {
    return '클라이언트: $client';
  }

  @override
  String get settings_fontScale => '글꼴 크기';

  @override
  String get settings_fontScale_previewSmall => '빛과 그림자가 캔버스에 내려앉는다.';

  @override
  String get settings_fontScale_previewMedium => '色から物語が生まれる。';

  @override
  String get settings_fontScale_previewLarge => 'Let colors tell a story.';

  @override
  String get settings_fontScale_done => '완료';

  @override
  String get settings_historyClickBehavior => '기록 클릭 동작';

  @override
  String get settings_historyClickBehavior_classic => '기본';

  @override
  String get settings_historyClickBehavior_classicDescription =>
      '기록 이미지를 클릭하면 상세 정보를 엽니다';

  @override
  String get settings_historyClickBehavior_linked => '연동 미리 보기';

  @override
  String get settings_historyClickBehavior_linkedDescription =>
      '클릭하면 가운데 미리 보기가 바뀌고, 두 번 클릭하거나 길게 누르면 상세 정보를 열며, 왼쪽/오른쪽 키로 둘러볼 수 있습니다';

  @override
  String get settings_outputViewer => '출력 뷰어';

  @override
  String get settings_outputViewer_canvas => '자유 캔버스';

  @override
  String get settings_outputViewer_canvasDescription =>
      'NAI5 방식 무한 캔버스: 생성한 이미지를 모두 배치별로 펼쳐 놓고, 가운데 버튼/Shift+왼쪽 드래그로 이동, Ctrl+휠로 확대/축소, WASD/f/q로 탐색합니다';

  @override
  String get settings_outputViewer_simple => '간단한 보기';

  @override
  String get settings_outputViewer_simpleDescription =>
      '저사양 PC나 익숙한 배치를 위한 기본 가운데/그리드 미리 보기';

  @override
  String get settings_canvasLockCamera => '캔버스 카메라 잠금';

  @override
  String get settings_canvasLockCameraDescription =>
      '휠 확대/축소·이동, 드래그 이동, WASD 등 수동 카메라 입력을 끕니다. 자동 선택과 탐색 이동은 계속 작동합니다';

  @override
  String get settings_canvasReducedMotion => '캔버스 움직임 줄이기';

  @override
  String get settings_canvasReducedMotionDescription =>
      '카메라 이동, 확대/축소, 관성이 즉시 전환되어 애니메이션이 줄어듭니다';

  @override
  String get image_viewDetail => '상세 정보 보기';

  @override
  String get settings_defaultImagesPath =>
      '기본값(Documents/NAI_Launcher/images/)';

  @override
  String get settings_defaultHivePath => '기본값(%APPDATA%/NAI_Launcher/hive/)';

  @override
  String get settings_protectionFeatures => '보호 기능';

  @override
  String get settings_stripMetadataTitle => '복사하거나 끌 때 메타데이터 모두 제거';

  @override
  String get settings_stripMetadataSubtitle =>
      '정리된 사본을 만들어 PNG 텍스트 청크, EXIF, NAI 스테가노그래피 워터마크 데이터를 제거하고, 끌 때 원본 경로가 노출되지 않게 합니다.';

  @override
  String get settings_confirmDangerousActionsTitle => '위험한 자산 작업 이중 확인';

  @override
  String get settings_confirmDangerousActionsSubtitle =>
      '로컬 자산을 삭제, 이동, 일괄 이동할 때 보호 확인을 한 번 더 표시합니다.';

  @override
  String get settings_warnExternalImageSendTitle => '외부 서비스로 보내기 전 확인';

  @override
  String get settings_warnExternalImageSendSubtitle =>
      '로컬 이미지가 LLM, NovelAI, ComfyUI 같은 외부 서비스로 나가기 전에 확인합니다.';

  @override
  String get settings_preventOverwriteTitle => '내보낼 때 기존 파일 덮어쓰지 않기';

  @override
  String get settings_preventOverwriteSubtitle =>
      '내보내기나 묶기 경로가 겹치면 자동으로 번호를 붙여 기존 자산을 실수로 바꾸지 않게 합니다.';

  @override
  String get settings_warnHighAnlasCostTitle => '높은 Anlas 비용 경고';

  @override
  String settings_warnHighAnlasCostSubtitle(Object threshold) {
    return '요청 한 번의 예상 비용이 $threshold Anlas에 도달하면 생성 전에 확인을 표시합니다.';
  }

  @override
  String get settings_highAnlasCostThresholdTitle => 'Anlas 경고 기준값';

  @override
  String get settings_setHighAnlasCostThresholdTitle => 'Anlas 경고 기준값 설정';

  @override
  String get settings_threshold => '기준값';

  @override
  String get settings_highAnlasCostThresholdHelper =>
      '생성 한 번의 예상 비용이 이 값 이상이면 확인을 표시합니다.';

  @override
  String get settings_limitGenerationIntervalTitle => '생성 빈도 제한';

  @override
  String get settings_limitGenerationIntervalSubtitle =>
      '생성 시작 사이에 설정한 최소 간격을 둡니다. 대기 시간 동안 생성 버튼을 사용할 수 없습니다.';

  @override
  String get settings_generationIntervalTitle => '생성 간격';

  @override
  String settings_generationIntervalValue(Object seconds) {
    return '$seconds초';
  }

  @override
  String get settings_setGenerationIntervalTitle => '생성 간격 설정';

  @override
  String get settings_generationIntervalHelper =>
      '1~3600초를 입력하세요. 대기 시간은 생성을 시작할 때부터 계산합니다.';

  @override
  String get settings_generationIntervalJitterTitle => '간격 무작위 변동';

  @override
  String settings_generationIntervalJitterValue(Object percent) {
    return '±$percent%';
  }

  @override
  String get settings_setGenerationIntervalJitterTitle => '간격 무작위 변동 설정';

  @override
  String get settings_generationIntervalJitterHelper =>
      '대기 시간마다 기본 간격 ± 이 비율 안에서 무작위로 정해져 생성 리듬이 덜 기계적으로 됩니다. 0~50을 입력하세요. 0이면 끕니다.';

  @override
  String get settings_confirmExternalSendTitle => '보호 모드: 외부 전송 확인';

  @override
  String settings_confirmExternalSendContent(Object count, Object target) {
    return '로컬 이미지 $count장을 $target(으)로 보내려고 합니다. 이미지 데이터가 로컬 앱 밖으로 나갑니다. 의도한 작업인지 확인하세요.';
  }

  @override
  String get settings_confirmExternalSend => '보내기';

  @override
  String get settings_highAnlasCostTitle => 'Anlas 사용량 확인';

  @override
  String get settings_continueGeneration => '생성 계속';

  @override
  String get dataSource_syncNow => '지금 동기화';

  @override
  String get settings_comfyUiEnable => 'ComfyUI 연동 사용';

  @override
  String get settings_comfyUiDisabledSubtitle =>
      '끄면 로컬 업스케일 등 ComfyUI 기능이 숨겨집니다';

  @override
  String get settings_comfyUiServerUrl => '서버 URL';

  @override
  String get settings_comfyUiConnectionSuccess => '연결 성공';

  @override
  String get settings_comfyUiConnectionSuccessFull => 'ComfyUI 연결 성공';

  @override
  String settings_comfyUiConnectionFailed(Object error) {
    return '연결하지 못했습니다: $error';
  }

  @override
  String get settings_comfyUiConnected => '연결됨';

  @override
  String get settings_comfyUiDisconnect => '연결 끊기';

  @override
  String get settings_comfyUiNoResponse => '서버가 응답하지 않습니다';

  @override
  String get settings_comfyUiStatusDisconnected => '연결 안 됨';

  @override
  String get settings_comfyUiStatusConnecting => '연결하는 중...';

  @override
  String get settings_comfyUiStatusConnected => '연결됨';

  @override
  String get settings_comfyUiStatusError => '연결 오류';

  @override
  String get settings_comfyUiCategoryEnhance => '향상/업스케일';

  @override
  String get settings_comfyUiCategoryImg2Img => 'Image2Image';

  @override
  String get settings_comfyUiCategoryInpaint => '인페인트';

  @override
  String get settings_comfyUiCategoryTxt2Img => '텍스트로 이미지 생성';

  @override
  String get settings_comfyUiCategoryCustom => '사용자 지정';

  @override
  String get comfyWorkflow_seedvr2UpscaleName => 'SeedVR2 업스케일';

  @override
  String get comfyWorkflow_seedvr2UpscaleDescription =>
      'SeedVR2 AI 모델로 업스케일합니다. 고품질 결과를 얻을 수 있습니다.';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleName => 'SeedVR2 타일 업스케일';

  @override
  String get comfyWorkflow_seedvr2TiledUpscaleDescription =>
      'SeedVR2TilingUpscaler로 타일 업스케일해 큰 이미지의 VRAM 부담을 줄입니다.';

  @override
  String get comfyWorkflow_modelUpscaleName => 'ComfyUI 표준 업스케일 모델';

  @override
  String get comfyWorkflow_modelUpscaleDescription =>
      'ComfyUI UpscaleModelLoader로 표준 업스케일 모델을 불러온 뒤 Lanczos로 최종 배율을 맞춥니다.';

  @override
  String get comfyWorkflow_rtxUpscaleName => 'RTX 업스케일';

  @override
  String get comfyWorkflow_rtxUpscaleDescription =>
      'Nvidia RTX Video Super Resolution 노드로 로컬 업스케일합니다.';

  @override
  String get comfyWorkflowSlot_inputImage => '입력 이미지';

  @override
  String get comfyWorkflowSlot_targetShortSide => '목표 짧은 변';

  @override
  String get comfyWorkflowSlot_targetLongSide => '목표 긴 변';

  @override
  String get comfyWorkflowSlot_upscaleModel => '업스케일 모델';

  @override
  String get comfyWorkflowSlot_randomSeed => '무작위 시드';

  @override
  String get comfyWorkflowSlot_outputImage => '출력 이미지';

  @override
  String get comfyWorkflowSlot_tileWidth => '타일 너비';

  @override
  String get comfyWorkflowSlot_tileHeight => '타일 높이';

  @override
  String get comfyWorkflowSlot_tileUpscaleResolution => '타일 업스케일 해상도';

  @override
  String get comfyWorkflowSlot_targetWidth => '목표 너비';

  @override
  String get comfyWorkflowSlot_targetHeight => '목표 높이';

  @override
  String get comfyWorkflowSlot_scale => '배율';

  @override
  String get comfyWorkflow_parameters => '매개변수';

  @override
  String get comfyWorkflow_selectImage => '클릭하여 이미지 선택';

  @override
  String comfyWorkflow_pickImageFailed(Object error) {
    return '이미지를 선택하지 못했습니다: $error';
  }

  @override
  String get comfyWorkflow_useResult => '결과 사용';

  @override
  String get comfyWorkflow_execute => '실행';

  @override
  String get comfyWorkflow_uploadingImage => '이미지 업로드 중...';

  @override
  String get comfyWorkflow_queued => '대기열에 추가됨...';

  @override
  String comfyWorkflow_runningSteps(Object current, Object total) {
    return '처리 중 $current/$total';
  }

  @override
  String get comfyWorkflow_processing => '처리하는 중...';

  @override
  String get comfyWorkflow_complete => '완료';

  @override
  String comfyWorkflow_imageCount(Object count) {
    return '이미지 $count장';
  }

  @override
  String get cacheStats_title => '캐시 통계';

  @override
  String cacheStats_autoRefreshUpdated(Object time) {
    return '자동 새로 고침 · 마지막 업데이트: $time';
  }

  @override
  String cacheStats_secondsAgo(Object seconds) {
    return '$seconds초 전';
  }

  @override
  String get cacheStats_resetStats => '통계 초기화';

  @override
  String get cacheStats_statsReset => '통계를 초기화했습니다';

  @override
  String get cacheStats_l1Memory => 'L1 메모리 캐시';

  @override
  String get cacheStats_l2Hive => 'L2 Hive 캐시';

  @override
  String get cacheStats_l3Sqlite => 'L3 SQLite 데이터베이스';

  @override
  String get galleryCache_rescanTitle => '갤러리 다시 스캔';

  @override
  String get galleryCache_rescanContent =>
      '다음 작업을 실행합니다:\n\n1. 데이터 일관성을 확인하고 없는 파일을 표시합니다\n2. 새 파일과 바뀐 파일을 스캔합니다\n3. 이전에 실패한 기록을 포함해 메타데이터 추출을 다시 시도합니다\n\n기존 데이터를 지우거나 이미지 파일을 삭제하지 않습니다.';

  @override
  String get galleryCache_startScan => '스캔 시작';

  @override
  String get galleryCache_scanAlreadyRunning =>
      '이미 스캔 작업이 진행 중입니다. 끝날 때까지 기다리세요.';

  @override
  String get galleryCache_preparing => '준비하는 중...';

  @override
  String get galleryCache_noGalleryFolder => '갤러리 폴더가 설정되지 않았습니다';

  @override
  String galleryCache_scanningPhase(Object processed, Object total) {
    return '스캔 중 $processed/$total...';
  }

  @override
  String get galleryCache_scanComplete => '스캔 완료';

  @override
  String galleryCache_scanFailed(Object error) {
    return '스캔하지 못했습니다: $error';
  }

  @override
  String get galleryCache_rescan => '다시 스캔';

  @override
  String get galleryCache_rescanSubtitle => '데이터 일관성 확인, 누락 파일 찾기, 메타데이터 추출';

  @override
  String get galleryCache_scanning => '스캔하는 중...';

  @override
  String get galleryCache_scanAction => '스캔';

  @override
  String get galleryCache_evictThumbnailsTitle => '썸네일 캐시 정리';

  @override
  String get galleryCache_evictThumbnailsSubtitle =>
      '한도를 넘은 .thumbs 파일을 오래 사용하지 않은 순서로 정리합니다(원본은 그대로)';

  @override
  String get galleryCache_evictThumbnailsContent =>
      '한도를 넘은 디스크 썸네일 캐시를 오래 사용하지 않은 것부터 정리합니다.\n\n.thumbs 폴더 안의 .thumb.jpg 파일만 삭제하며 원본 이미지는 절대 삭제하거나 수정하지 않습니다. 정리한 썸네일은 다음에 둘러볼 때 필요에 따라 다시 만들어집니다.';

  @override
  String get galleryCache_evictThumbnailsStart => '지금 정리';

  @override
  String get galleryCache_evictThumbnailsRunning => '썸네일 캐시 정리 중...';

  @override
  String galleryCache_evictThumbnailsDone(int count, String size) {
    return '썸네일 $count개를 정리해 $size MB를 확보했습니다';
  }

  @override
  String get galleryCache_evictThumbnailsNone =>
      '썸네일 캐시가 한도 아래입니다. 정리할 항목이 없습니다';

  @override
  String galleryCache_evictThumbnailsFailed(Object error) {
    return '썸네일 캐시를 정리하지 못했습니다: $error';
  }

  @override
  String get workflowImport_title => 'ComfyUI 워크플로 가져오기';

  @override
  String workflowImport_step(Object current, Object title) {
    return '$current/4단계: $title';
  }

  @override
  String get workflowImport_stepFile => '워크플로 파일 선택';

  @override
  String get workflowImport_stepInfo => '워크플로 정보';

  @override
  String get workflowImport_stepSlots => '슬롯 설정 확인';

  @override
  String get workflowImport_stepDone => '가져오기 완료';

  @override
  String get workflowImport_previous => '이전';

  @override
  String get workflowImport_next => '다음';

  @override
  String get workflowImport_finish => '가져오기 완료';

  @override
  String get workflowImport_defaultName => '사용자 지정 워크플로';

  @override
  String get workflowImport_fileInstructions =>
      'ComfyUI에서 내보낸 workflow_api.json 파일을 선택하세요.\n\nComfyUI 메뉴에서 내보내기(API 형식)를 선택하면 이 파일을 얻을 수 있습니다.';

  @override
  String workflowImport_nodeCount(Object count) {
    return '노드 $count개';
  }

  @override
  String get workflowImport_reselect => '클릭하여 다른 파일 선택';

  @override
  String get workflowImport_selectWorkflowApi => '클릭하여 workflow_api.json 선택';

  @override
  String get workflowImport_invalidTopLevel =>
      '파일 형식이 올바르지 않습니다. 최상위는 JSON 객체여야 합니다';

  @override
  String get workflowImport_noComfyNodes =>
      'ComfyUI 노드를 찾지 못했습니다. API 형식으로 내보낸 파일인지 확인하세요.';

  @override
  String workflowImport_readFailed(Object error) {
    return '파일을 읽지 못했습니다: $error';
  }

  @override
  String get workflowImport_analysisResult => '자동 분석 결과';

  @override
  String get workflowImport_inputImageNodes => '입력 이미지 노드';

  @override
  String get workflowImport_adjustableParams => '조정 가능한 매개변수';

  @override
  String get workflowImport_outputNodes => '출력 노드';

  @override
  String get workflowImport_totalNodes => '전체 노드';

  @override
  String workflowImport_countUnit(Object count) {
    return '$count개';
  }

  @override
  String get workflowImport_workflowName => '워크플로 이름 *';

  @override
  String get workflowImport_description => '설명';

  @override
  String get workflowImport_category => '분류';

  @override
  String get workflowImport_slotsHint =>
      'UI에 노출할 슬롯을 선택하세요. 입력·출력 슬롯은 보통 켜 두고, 사용자가 조정할 필요가 없는 매개변수는 끌 수 있습니다.';

  @override
  String get workflowImport_inputSection => '입력';

  @override
  String get workflowImport_outputSection => '출력';

  @override
  String get workflowImport_parameterSection => '매개변수';

  @override
  String get workflowImport_noSlotsWarning =>
      '사용할 수 있는 슬롯을 찾지 못했습니다. 이 워크플로가 제대로 연동되지 않을 수 있습니다.\n워크플로에 LoadImage와 SaveImage/SaveImageWebsocket 노드가 있는지 확인하세요.';

  @override
  String workflowImport_nodeRef(Object node) {
    return '노드 $node';
  }

  @override
  String get workflowImport_confirmTitle => '이 워크플로를 가져오려고 합니다';

  @override
  String get workflowImport_name => '이름';

  @override
  String get workflowImport_inputSlots => '입력 슬롯';

  @override
  String get workflowImport_parameterSlots => '매개변수 슬롯';

  @override
  String get workflowImport_outputSlots => '출력 슬롯';

  @override
  String get workflowImport_afterImportHint =>
      '가져온 뒤 생성 화면의 ComfyUI 워크플로 목록에서 사용할 수 있습니다.';

  @override
  String workflowImport_success(Object name) {
    return '\"$name\" 워크플로를 가져왔습니다';
  }

  @override
  String get shortcut_settings_help => '단축키 도움말 보기';

  @override
  String get shortcut_settings_show_in_menus => '메뉴에 표시';

  @override
  String shortcut_settings_defaultShortcut(Object shortcut) {
    return '기본값: $shortcut';
  }

  @override
  String get shortcut_settings_unassigned => '설정 안 됨';

  @override
  String get shortcut_settings_no_matches => '일치하는 단축키가 없습니다';

  @override
  String get shortcut_settings_reset_all_title => '모든 단축키 초기화';

  @override
  String get shortcut_settings_reset_all_confirm =>
      '모든 단축키를 기본 설정으로 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get shortcut_settings_reset_to_default => '기본값으로 초기화';

  @override
  String get toast_previewUpdated => '미리 보기 이미지를 업데이트했습니다';

  @override
  String toast_styleReferenceLimit(Object max) {
    return '스타일 참조가 한도($max장)에 도달했습니다';
  }

  @override
  String get toast_noValidMaskIgnored => '유효한 마스크가 감지되지 않아 저장 결과를 무시했습니다.';

  @override
  String get toast_kritaBusy =>
      'Krita Bridge에서 생성하는 중입니다. 현재 작업이 끝날 때까지 기다리세요.';

  @override
  String get toast_kritaNotConnected =>
      'Krita가 연결되지 않았습니다. 먼저 설정에서 브리지를 켜고 플러그인을 연결하세요.';

  @override
  String get toast_sentToKrita => '이미지를 Krita로 보냈습니다';

  @override
  String get toast_kritaUnsupportedImageFormat =>
      '이 이미지 형식은 Krita로 보낼 수 없습니다. 일반적인 이미지 형식을 사용하세요.';

  @override
  String get toast_dropNoReadableImageOrVibe =>
      '놓은 항목에서 읽을 수 있는 이미지나 Vibe 파일을 찾지 못했습니다';

  @override
  String get toast_contentCannotBeEmpty => '내용은 비워 둘 수 없습니다';

  @override
  String get toast_addedToLibrary => '라이브러리에 추가했습니다';

  @override
  String toast_addFailed(Object error) {
    return '추가하지 못했습니다: $error';
  }

  @override
  String get toast_libraryNotLoaded => '라이브러리를 불러오지 않았습니다';

  @override
  String get toast_noValidTagContent => '유효한 태그 내용이 없습니다';

  @override
  String get toast_allTagsAlreadyExist => '모든 태그가 이미 라이브러리에 있습니다';

  @override
  String get toast_noAddableTags => '추가할 수 있는 태그가 없습니다';

  @override
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped) {
    return '태그 $added개를 추가하고 중복 태그 $skipped개를 건너뛰었습니다';
  }

  @override
  String get toast_saveDirNotSet => '저장 폴더가 설정되지 않았습니다';

  @override
  String toast_savedTo(Object path) {
    return '$path에 저장했습니다';
  }

  @override
  String get toast_tagAlreadyExists => '이미 있는 태그입니다';

  @override
  String get toast_nameRequired => '이름을 입력하세요';

  @override
  String get toast_savedToVibeLibrary => 'Vibe 라이브러리에 저장했습니다';

  @override
  String get toast_saveBundleFailed => '번들을 저장하지 못했습니다';

  @override
  String get toast_saveEntryFailed => '항목을 저장하지 못했습니다';

  @override
  String get toast_imageDataUnavailable => '이미지 데이터를 사용할 수 없어 복사할 수 없습니다';

  @override
  String get toast_characterPromptCopied => '캐릭터 프롬프트를 복사했습니다';

  @override
  String toast_copiedTitle(Object title) {
    return '$title을(를) 복사했습니다';
  }

  @override
  String get toast_unreadableDroppedImageSource =>
      '놓은 항목에서 읽을 수 있는 이미지 파일이나 이미지 URL을 찾지 못했습니다';

  @override
  String toast_appendedStyleReferences(Object count) {
    return '스타일 참조 $count개를 추가했습니다';
  }

  @override
  String get toast_appendedPreencodedVibe =>
      '스타일 참조 1개를 추가했습니다(미리 인코딩된 Vibe 재사용)';

  @override
  String get toast_addedPreencodedVibe =>
      '스타일 참조를 추가했습니다(미리 인코딩된 Vibe 재사용, 2 Anlas 절약)';

  @override
  String toast_vibesMissingEncoding(Object count) {
    return 'Vibe $count개에 인코딩 데이터가 없어 저장할 수 없습니다';
  }

  @override
  String toast_savedBundle(Object count) {
    return '번들을 저장했습니다(Vibe $count개)';
  }

  @override
  String toast_extractMetadataFailed(Object error) {
    return '메타데이터를 추출하지 못했습니다: $error';
  }

  @override
  String toast_processImageFailed(Object error) {
    return '이미지를 처리하지 못했습니다: $error';
  }

  @override
  String get toast_savePreviewFailed => '미리 보기 이미지를 저장하지 못했습니다';

  @override
  String get common_justNow => '방금';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes분 전';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours시간 전';
  }

  @override
  String get common_saving => '저장하는 중...';

  @override
  String get common_expand => '펼치기';

  @override
  String get common_collapse => '접기';

  @override
  String get detail_parsingMetadata => '메타데이터 분석 중...';

  @override
  String get detail_noMetadata => '이 이미지에는 메타데이터가 없습니다';

  @override
  String get detail_metadata => '메타데이터';

  @override
  String get detail_modifiedTime => '수정한 날짜';

  @override
  String get detail_fileSize => '파일 크기';

  @override
  String get detail_noContent => '(내용 없음)';

  @override
  String get saveBlock_title => '블록으로 저장';

  @override
  String get saveBlock_nameLabel => '블록 제목';

  @override
  String get saveBlock_nameHint => '블록 제목 입력';

  @override
  String get saveBlock_nameRequired => '블록 제목을 입력하세요';

  @override
  String get saveBlock_selectContent => '저장할 내용을 선택하세요';

  @override
  String get saveBlock_negativeSuffix => '네거티브';

  @override
  String get saveBlock_saved => '블록 라이브러리에 저장했습니다';

  @override
  String detail_copyLabel(Object label) {
    return '$label 복사';
  }

  @override
  String get comfyImport_detectedTitle => 'ComfyUI 다중 캐릭터 프롬프트를 감지했습니다';

  @override
  String comfyImport_characterList(Object count) {
    return '캐릭터 목록($count)';
  }

  @override
  String get comfyImport_usePositionInfo => '위치 정보 사용';

  @override
  String get comfyImport_usePositionInfoSubtitle =>
      'ComfyUI 영역을 NAI 캐릭터 위치로 변환합니다';

  @override
  String comfyImport_convertCharacters(Object count) {
    return '캐릭터 $count명 변환';
  }

  @override
  String get comfyImport_syntaxCouple => 'COUPLE 구문';

  @override
  String get comfyImport_syntaxAndMask => 'AND+MASK 구문';

  @override
  String get comfyImport_syntaxPipe => '파이프 형식';

  @override
  String get comfyImport_syntaxUnknown => '알 수 없는 구문';

  @override
  String get comfyImport_globalPrompt => '전역 프롬프트';

  @override
  String get checkForUpdate => '업데이트 확인';

  @override
  String get neverChecked => '확인한 적 없음';

  @override
  String lastCheckedAt(Object time) {
    return '마지막 확인: $time';
  }

  @override
  String get includePrereleaseUpdates => '시험판 버전 포함';

  @override
  String get includePrereleaseUpdatesDescription =>
      '업데이트를 확인할 때 beta/alpha 버전을 포함합니다';

  @override
  String get updateAvailable => '업데이트 있음';

  @override
  String get updateChecking => '업데이트 확인 중...';

  @override
  String get updateDownloading => '업데이트 다운로드 중...';

  @override
  String get updateInstalling => '설치 프로그램 시작 중...';

  @override
  String get updateUpToDate => '최신 버전입니다';

  @override
  String get updateError => '업데이트를 확인하지 못했습니다';

  @override
  String get currentVersion => '현재 버전';

  @override
  String get latestVersion => '최신 버전';

  @override
  String get releaseNotes => '릴리스 노트';

  @override
  String updateDownloadingProgress(Object percent) {
    return '업데이트 패키지 다운로드 중: $percent%';
  }

  @override
  String updateDownloadSizeSpeed(Object received, Object total, Object speed) {
    return '$received / $total · $speed';
  }

  @override
  String get updateDownloaded => '업데이트 패키지 준비 완료';

  @override
  String updateDownloadedHint(Object version) {
    return 'v$version을(를) 다운로드하고 확인했습니다. 설치하면 앱이 닫히고 자동으로 다시 시작됩니다.';
  }

  @override
  String get updateInstallAndRestart => '설치 후 다시 시작';

  @override
  String get updateInstallNow => '지금 설치';

  @override
  String get updateInstallLater => '나중에 설치';

  @override
  String get updateDownload => '업데이트 다운로드';

  @override
  String get updateDownloadCancelled => '다운로드를 취소했습니다. 나중에 이어서 받을 수 있습니다';

  @override
  String get updateDownloadFailed => '업데이트를 다운로드하지 못했습니다';

  @override
  String get updateInstallFailed => '업데이트를 설치하지 못했습니다';

  @override
  String get updateInstallingHint =>
      '설치 프로그램이 시작되었습니다. 앱이 닫히고 업데이트가 자동으로 완료됩니다.';

  @override
  String get remindMeLater => '4시간 후에 알림';

  @override
  String updateNoticeAvailable(Object version) {
    return 'v$version 버전을 사용할 수 있습니다';
  }

  @override
  String get updateNoticeAvailableSubtitle => '앱에서 다운로드하고 업데이트를 자동으로 마칩니다';

  @override
  String get updateNoticeManualSubtitle => '이 플랫폼은 Release 페이지에서 직접 업데이트해야 합니다';

  @override
  String updateNoticeReady(Object version) {
    return 'v$version 버전이 준비되었습니다';
  }

  @override
  String get updateNoticeReadySubtitle => '패키지를 확인했으며 다시 시작하면 설치할 수 있습니다';

  @override
  String get updateNoticeFailed => '이전 업데이트가 끝나지 않았습니다';

  @override
  String get updateViewDetails => '업데이트 보기';

  @override
  String updateSettingsAvailable(Object version) {
    return 'v$version을(를) 사용할 수 있습니다. 선택하면 자세히 볼 수 있습니다';
  }

  @override
  String updateSettingsReady(Object version) {
    return 'v$version을(를) 다운로드했습니다. 선택하면 설치합니다';
  }

  @override
  String get goToDownload => '다운로드하러 가기';

  @override
  String get cannotOpenUrl => '링크를 열 수 없습니다';

  @override
  String get model3d_editorTitle => '3D 모델 레이어';

  @override
  String get model3d_modeTransform => '변형';

  @override
  String get model3d_modePose => '포즈';

  @override
  String get model3d_gizmoTranslate => '이동';

  @override
  String get model3d_gizmoRotate => '회전';

  @override
  String get model3d_gizmoScale => '크기 조절';

  @override
  String get model3d_replaceConfirm => '현재 모델을 교체하시겠습니까? 적용하지 않은 포즈는 사라집니다.';

  @override
  String get model3d_discardConfirm => '적용하지 않은 변경 사항을 버리시겠습니까?';

  @override
  String get model3d_missingModel => '모델 파일이 없습니다. 다시 가져올 수 있습니다.';

  @override
  String get model3d_loadError => '모델을 불러오지 못했습니다';

  @override
  String get model3d_light => '조명';

  @override
  String get model3d_addLayerTooltip => '3D 모델 레이어 추가';

  @override
  String get nav_preciseRefLibrary => '정밀 참조 라이브러리';

  @override
  String preciseRefLib_saved(String name) {
    return '\"$name\"을(를) 정밀 참조 라이브러리에 저장했습니다';
  }

  @override
  String get preciseRefLib_savedHint => '라이브러리에서 매개변수를 편집할 수 있습니다';

  @override
  String get preciseRefLib_imageMissing => '이미지 파일이 없습니다';

  @override
  String get preciseRefLib_invalidImage => '지원하지 않는 이미지 형식이거나 파일이 손상되었습니다';

  @override
  String preciseRefLib_importedCount(int count) {
    return '이미지 $count장을 가져왔습니다';
  }

  @override
  String preciseRefLib_importFailed(String error) {
    return '정밀 참조 라이브러리에 저장하지 못했습니다: $error';
  }

  @override
  String preciseRefLib_importFailedCount(int count) {
    return '이미지 $count장을 정밀 참조 라이브러리로 가져오지 못했습니다';
  }

  @override
  String get preciseRefLib_fromLibrary => '라이브러리에서';

  @override
  String get preciseRefLib_saveCurrentToLibrary => '라이브러리에 저장';

  @override
  String preciseRefLib_saveCurrentCount(int count) {
    return '참조 $count개를 라이브러리에 저장했습니다';
  }

  @override
  String get img2img_fromPreciseRefLibrary => '정밀 참조 라이브러리에서';

  @override
  String get localGallery_saveToPreciseRefLibrary => '정밀 참조 라이브러리에 저장';

  @override
  String get drop_saveToPreciseRefLibrary => '정밀 참조 라이브러리에 저장';

  @override
  String get common_enabled => '사용';

  @override
  String get common_disabled => '사용 안 함';

  @override
  String bulkAction_selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get comfyTask_errorConnectionFailed => 'ComfyUI 서버에 연결할 수 없습니다';

  @override
  String get comfyTask_errorConnectionUnavailable => 'ComfyUI 연결을 사용할 수 없습니다';

  @override
  String get comfyTask_errorExecutionFailedGeneric => 'ComfyUI 실행에 실패했습니다';

  @override
  String comfyTask_errorExecutionFailed(String error) {
    return 'ComfyUI 실행에 실패했습니다: $error';
  }

  @override
  String get comfyTask_errorTimeout => 'ComfyUI 작업이 10분이 지나 시간 초과되었습니다';

  @override
  String comfyTask_errorWorkflowNotFound(String workflowId) {
    return '워크플로를 찾을 수 없습니다: $workflowId';
  }

  @override
  String get comfyWorkflowSlot_vaeEncodeTileSize => 'VAE 인코딩 타일 크기';

  @override
  String get comfyWorkflowSlot_vaeDecodeTileSize => 'VAE 디코딩 타일 크기';

  @override
  String get comfyWorkflowSlot_blocksToSwap => '스왑할 블록 수';

  @override
  String get comfyWorkflowSlot_swapIoComponents => '입출력 구성 요소 스왑';

  @override
  String localGallery_firstIndexHint(int count) {
    return '이미지 $count장을 찾았습니다. 처음 색인을 만드는 데 몇 분이 걸릴 수 있으며, 그동안에도 앱을 계속 사용할 수 있습니다.';
  }

  @override
  String get localGallery_errorPermissionDenied =>
      '이미지 폴더에 접근할 수 없습니다. 폴더 권한을 확인하세요.';

  @override
  String localGallery_errorScanFailed(String error) {
    return '이미지를 스캔하지 못했습니다: $error';
  }

  @override
  String localGallery_errorInitializationFailed(String error) {
    return '갤러리를 초기화하지 못했습니다: $error';
  }

  @override
  String get localGallery_errorServiceInitializing =>
      '갤러리 서비스를 아직 초기화하는 중입니다. 잠시 후 다시 시도하세요.';

  @override
  String localGallery_errorDatabaseFailed(String error) {
    return '갤러리 데이터베이스 오류: $error';
  }

  @override
  String localGallery_errorRefreshFailed(String error) {
    return '갤러리를 새로 고치지 못했습니다: $error';
  }

  @override
  String localGallery_errorFilterFailed(String error) {
    return '갤러리 필터를 적용하지 못했습니다: $error';
  }

  @override
  String localGallery_errorFavoriteFailed(String error) {
    return '즐겨찾기 상태를 업데이트하지 못했습니다: $error';
  }

  @override
  String localGallery_errorRebuildFailed(String error) {
    return '갤러리 인덱스를 다시 만들지 못했습니다: $error';
  }

  @override
  String get common_optional => '선택 사항';

  @override
  String get common_emptyValue => '(비어 있음)';

  @override
  String get common_clickToRetry => '클릭하여 다시 시도';

  @override
  String get common_opening => '여는 중...';

  @override
  String get common_swap => '바꾸기';

  @override
  String get addToLibrary_displayNameHint => '이 항목을 알아보기 쉬운 이름을 입력하세요';

  @override
  String get addToLibrary_tagHint => '태그를 입력하고 Enter를 눌러 추가하세요';

  @override
  String get drop_saveVibeBundle => 'Vibe 번들 저장';

  @override
  String get vibe_import_overwriteOriginalParams => '원래 Vibe 매개변수 교체';

  @override
  String vibe_import_overwriteOriginalParamsHint(String name) {
    return '$name의 라이브러리 매개변수만 교체합니다. 기본값은 꺼짐입니다';
  }

  @override
  String vibe_import_reencodeFailed(String name) {
    return 'Vibe를 다시 인코딩하지 못했습니다: $name';
  }

  @override
  String galleryScan_failed(int count) {
    return '실패 $count';
  }

  @override
  String get galleryScan_organizingGallery => '갤러리 정리 중';

  @override
  String get galleryScan_processing => '처리 중';

  @override
  String imagePicker_dropReadFailed(String error) {
    return '놓은 이미지를 읽지 못했습니다: $error';
  }

  @override
  String get imagePicker_dropNoReadableImage =>
      '놓은 데이터에 읽을 수 있는 이미지 파일이나 이미지 URL이 없습니다';

  @override
  String get imagePicker_fileDataUnavailable => '파일 데이터를 읽을 수 없습니다';

  @override
  String imagePicker_fileSelectionFailed(String error) {
    return '파일을 선택하지 못했습니다: $error';
  }

  @override
  String imagePicker_directorySelectionFailed(String error) {
    return '폴더를 선택하지 못했습니다: $error';
  }

  @override
  String get editor_shiftEdges => '가장자리 확장';

  @override
  String get editor_edgeLeft => '왼쪽';

  @override
  String get editor_edgeRight => '오른쪽';

  @override
  String get editor_edgeTop => '위';

  @override
  String get editor_edgeBottom => '아래';

  @override
  String get editor_enterNumber => '숫자를 입력하세요';

  @override
  String get onlineGallery_videoLoadFailed => '동영상을 불러오지 못했습니다';

  @override
  String get vibe_releaseToAddStyleReference => '놓으면 스타일 참조를 추가합니다';

  @override
  String router_pageNotFound(String error) {
    return '페이지를 찾을 수 없습니다: $error';
  }

  @override
  String get autocomplete_resultLimit => '결과 수';

  @override
  String get autocomplete_relatedTagsTitle => '태그 확장';

  @override
  String get autocomplete_relatedTagsSubtitle =>
      'Ctrl+클릭으로 로컬 태그 검색, Ctrl+드래그로 관련 태그 탐색';

  @override
  String get tagExpansion_searchHint => '태그나 별칭 검색';

  @override
  String get tagExpansion_relatedTitle => '관련 태그';

  @override
  String get tagExpansion_empty => '입력하여 로컬 태그 검색';

  @override
  String get tagExpansion_noResults => '로컬 태그를 찾을 수 없습니다';

  @override
  String get tagExpansion_insert => '태그 삽입';

  @override
  String get tagExpansion_showRelated => '관련 태그 보기';

  @override
  String get tagExpansion_localOnly => '로컬만';

  @override
  String get tagExpansion_popularSource => '자주 쓰는 로컬 태그';

  @override
  String get tagExpansion_tabComplete => 'Tab으로 완성:';

  @override
  String get tagExpansion_wikiTitle => '태그 미니 백과';

  @override
  String get tagExpansion_wikiUnavailable => '이 태그에 대한 로컬 문서가 아직 없습니다.';

  @override
  String get autocomplete_cooccurrence => '오프라인 관련 태그 데이터베이스';

  @override
  String autocomplete_entryCount(int count) {
    return '항목 $count개';
  }

  @override
  String get autocomplete_clearDanbooruCache => 'Danbooru 캐시 지우기';

  @override
  String get autocomplete_clearAiCache => 'AI 번역 캐시 지우기';

  @override
  String autocomplete_cacheCleared(int count) {
    return '캐시 항목 $count개를 지웠습니다';
  }

  @override
  String get autocomplete_baseCatalog => '기본 Danbooru 카탈로그';

  @override
  String autocomplete_catalogStatus(String count, String version) {
    return '태그 $count개 · 데이터 버전 $version';
  }

  @override
  String get promptBlockLibrary_allBlocks => '모든 블록';

  @override
  String get promptBlockLibrary_rootFolder => '루트 / 미분류';

  @override
  String get promptBlockLibrary_unnamedBlock => '제목 없는 블록';

  @override
  String promptBlockLibrary_useCount(int count) {
    return '$count회 사용';
  }

  @override
  String get promptBlockPill_missing => '삭제된 블록';

  @override
  String get promptBlockPill_unknown => '잘못된 블록';

  @override
  String get promptBlockLibrary_unnamedFolder => '제목 없는 폴더';

  @override
  String promptBlockLibrary_deleteCollectionConfirm(String name) {
    return '\"$name\" 컬렉션을 삭제하시겠습니까? 안의 블록은 삭제되지 않고 컬렉션에서만 빠집니다.';
  }

  @override
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name) {
    return '\"$name\" 컬렉션 폴더를 삭제하시겠습니까? 안의 컬렉션과 하위 폴더도 함께 삭제되지만 블록 자체는 영향을 받지 않습니다.';
  }

  @override
  String get promptBlockLibrary_blockTitle => '제목';

  @override
  String get promptBlockLibrary_titleHint => '블록 제목';

  @override
  String get promptBlockLibrary_folder => '폴더';

  @override
  String get promptBlockLibrary_settingsApplied => '블록 설정을 현재 이미지로 가져왔습니다';

  @override
  String get promptBlockLibrary_settingsIncompatible =>
      '블록 설정이 대상 모델과 호환되지 않아 매개변수를 가져오지 않았습니다.';

  @override
  String get promptBlockLibrary_deleted => '삭제했습니다';

  @override
  String get promptBlockLibrary_multiSelect => '다중 선택';

  @override
  String get promptBlockLibrary_exitMultiSelect => '다중 선택 종료';

  @override
  String promptBlockLibrary_selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get promptBlockLibrary_selectAllVisible => '모두 선택';

  @override
  String get promptBlockLibrary_clearSelection => '선택 해제';

  @override
  String get promptBlockLibrary_empty => '아직 프롬프트 블록이 없습니다';

  @override
  String get promptBlockLibrary_noSearchResults => '일치하는 블록이 없습니다';

  @override
  String promptBlockLibrary_deleteFolderTitle(Object name) {
    return '\"$name\" 폴더를 삭제하시겠습니까?';
  }

  @override
  String get promptBlockLibrary_deleteFolderDescription =>
      '이 폴더와 하위 폴더에 있는 블록을 어떻게 처리할지 선택하세요.';

  @override
  String get promptBlockLibrary_moveContentsToRoot => '내용을 루트로 이동';

  @override
  String get promptBlockLibrary_moveContentsToFolder => '내용을 다른 폴더로 이동';

  @override
  String get promptBlockLibrary_destinationFolder => '대상 폴더';

  @override
  String get promptBlockLibrary_deleteContents => '내용 삭제';

  @override
  String get promptBlockLibrary_deleteContentsWarning =>
      '폴더 트리 안의 모든 블록도 영구 삭제됩니다.';

  @override
  String get promptBlockLibrary_exportLibraryBackup => '라이브러리 백업 내보내기…';

  @override
  String get promptBlockLibrary_importTxtTitle => 'TXT 파일 선택';

  @override
  String promptBlockLibrary_txtImportDone(int created, int skipped) {
    return '블록 $created개를 가져오고 기존 소스 $skipped개를 건너뛰었습니다';
  }

  @override
  String get promptBlockLibrary_curationTitle => '폴더에서 가져오기';

  @override
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  ) {
    return 'TXT 파일 $total개: 새로 추가 $created · 변경 없음 $skipped · 변경됨 $changed';
  }

  @override
  String promptBlockLibrary_curationLocalModifiedHint(int count) {
    return '블록 $count개는 가져온 뒤 직접 수정했습니다. 업데이트하면 로컬 수정 내용을 덮어씁니다';
  }

  @override
  String get promptBlockLibrary_curationUpdateChanged => '변경된 블록을 파일 내용으로 업데이트';

  @override
  String get promptBlockLibrary_curationEmpty => '선택한 폴더에 TXT 파일이 없습니다';

  @override
  String promptBlockLibrary_curationDone(
    int created,
    int updated,
    int skipped,
  ) {
    return '완료: 새로 추가 $created · 업데이트 $updated · 건너뜀 $skipped';
  }

  @override
  String get promptBlockLibrary_curationNew => '새 항목';

  @override
  String get promptBlockLibrary_curationUnchanged => '변경 없음';

  @override
  String get promptBlockLibrary_curationChanged => '변경됨';

  @override
  String get promptBlockLibrary_curationLocalModified => '로컬에서 수정됨';

  @override
  String get promptBlockLibrary_libraryImportTitle => '라이브러리 백업 선택';

  @override
  String promptBlockLibrary_importFailed(String error) {
    return '가져오지 못했습니다: $error';
  }

  @override
  String get promptBlockLibrary_sourceFile => '소스 파일';

  @override
  String get promptBlockLibrary_importedAt => '가져온 시간';

  @override
  String get promptBlockPalette_tooltip => '블록';

  @override
  String get promptBlockPalette_emptyHint =>
      '자주 쓰는 프롬프트 블록이나 번역 블록을 여기에 보관하세요. 클릭하면 커서 위치에 삽입되고, 프롬프트 입력란으로 끌어 놓을 수도 있습니다.';

  @override
  String get promptBlockPalette_remove => '블록에서 제거';

  @override
  String get promptBlockPalette_clearAll => '블록 비우기';

  @override
  String get promptBlockPalette_clearAllArmed => '한 번 더 누르면 모두 비웁니다';

  @override
  String promptBlockPalette_removeSelected(int count) {
    return '선택한 $count개 제거';
  }

  @override
  String get nav_styleExplore => '스타일 탐색';

  @override
  String get styleExplore_operationFailed => '작업에 실패했습니다';

  @override
  String get styleExplore_discardChangesTitle => '저장하지 않은 변경 사항을 버리시겠습니까?';

  @override
  String get styleExplore_discardChangesMessage =>
      '작업 공간에 저장하지 않은 변경 사항이 있습니다. 계속하면 버려집니다.';

  @override
  String get styleExplore_discardChangesConfirm => '계속하고 버리기';

  @override
  String styleExplore_manualRunName(String time) {
    return '수동 수집 $time';
  }

  @override
  String get styleExplore_runBusy => '생성 중입니다. 잠시 후 다시 시도하세요';

  @override
  String styleExplore_adoptBlockSaved(String name) {
    return '“$name” 블록으로 저장됨';
  }

  @override
  String get styleExplore_adoptBlockEmpty =>
      '선택한 후보에 저장할 작가 조합이나 긍정 프롬프트가 없습니다';

  @override
  String get promptBlockEditor_library => '블록 라이브러리';

  @override
  String get promptBlockPicker_title => '블록 선택';

  @override
  String get promptBlockLibrary_selectImage => '이미지 선택';

  @override
  String get promptBlockLibrary_adjustThumbnailTitle => '썸네일 표시 범위 조정';

  @override
  String get promptBlockLibrary_dragToMove => '끌어서 이동, 스크롤하거나 손가락을 오므려 확대/축소';

  @override
  String get promptBlockLibrary_addToLibrary => '블록 라이브러리에 추가';

  @override
  String get promptBlockLibrary_contentPreview => '내용 미리 보기';

  @override
  String get promptBlockLibrary_confirmAdd => '확인';

  @override
  String get promptBlockLibrary_saveToLibrary => '블록 라이브러리에 저장';

  @override
  String get promptBlockLibrary_droppedImage => '놓은 이미지';

  @override
  String get promptBlockLibrary_createBlockFromImage => '새 블록 만들기';

  @override
  String get promptBlockLibrary_createBlockFromImageSubtitle =>
      '이 이미지로 새 블록을 만듭니다';

  @override
  String promptBlockLibrary_promptExtracted(Object prompt) {
    return '프롬프트를 추출했습니다: \"$prompt\"';
  }

  @override
  String get promptBlockLibrary_updateExistingThumbnail => '기존 블록 썸네일 업데이트';

  @override
  String get promptBlockLibrary_updateExistingThumbnailSubtitle =>
      '블록을 골라 썸네일을 교체합니다';

  @override
  String subscriptionExpiresOn(String date) {
    return '$date 만료';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '$days일 남음';
  }

  @override
  String get subscriptionExpired => '만료됨';

  @override
  String get subscriptionGracePeriod => '유예 기간';

  @override
  String get subscriptionTierNone => '구독 없음';

  @override
  String get settings_modelsAndInterfaces => '모델 및 API';

  @override
  String get tips_kind_guide => '팁';

  @override
  String get tips_kind_trick => '고수';

  @override
  String get tips_kind_wolf => '늑대';

  @override
  String tips_hint(String label, String tip) {
    return '$label: $tip';
  }

  @override
  String get tips_studio_guide_1 =>
      '프롬프트를 다 썼다면 Ctrl+Enter로 바로 생성할 수 있습니다. 결과는 이 캔버스에 묶음별로 펼쳐집니다. 가운데 버튼이나 Shift+왼쪽 드래그로 이동하고, Ctrl+휠로 확대·축소하며, WASD로도 둘러볼 수 있습니다.';

  @override
  String get tips_studio_guide_2 =>
      '자주 쓰는 작가 태그, 품질 태그, 구도 설명은 한 번 블록으로 저장해 두고 다음부터 블록 라이브러리에서 불러오면 됩니다. 블록은 단순한 복사·붙여넣기가 아닙니다. 고정, 순차, 무작위 뽑기 중에서 고를 수 있어 생성할 때마다 조합이 바뀝니다.';

  @override
  String get tips_studio_guide_3 =>
      '무작위 블록에서 마음에 드는 결과가 나왔다면 잠근 다음 나머지만 다시 뽑아 보세요. 잠근 내용은 그대로 두고 나머지만 계속 무작위로 바뀝니다. \"이 포즈는 그대로, 옷만 몇 벌 더\"에 딱 맞습니다.';

  @override
  String get tips_studio_guide_4 =>
      '이미지를 창으로 끌어다 놓으면 어떻게 쓸지 묻습니다. Image2Image, Vibe 트랜스퍼, 정밀 참조, 또는 프롬프트와 파라미터만 추출하기 중에서 고르면 됩니다. NovelAI 메타데이터가 남아 있는 이미지라면 어떻게 만들었는지 한 번에 확인할 수 있습니다.';

  @override
  String get tips_studio_guide_5 =>
      '캐릭터 칸의 정체는 사실 위치를 정하는 칸입니다. 사람뿐 아니라 고양이, 램프, 간판도 넣을 수 있습니다. 위치를 사용자 지정으로 바꾸고 미리보기에서 앵커를 끌어 어디에 둘지 모델에게 알려 주세요.';

  @override
  String get tips_studio_guide_6 =>
      '프롬프트 일부를 선택하고 Alt를 누른 채 휠을 굴리면 가중치를 조절할 수 있습니다. Alt 없이 굴리면 그냥 스크롤만 되니 실수로 바뀔 일이 없습니다. 보조 키는 설정에서 Ctrl로 바꿀 수 있습니다.';

  @override
  String get tips_studio_guide_7 =>
      'F1을 누르면 언제든 단축키 도움말이 열립니다. Ctrl+1, Ctrl+2, Ctrl+3으로 생성, 갤러리, 온라인 갤러리를 오가고, Ctrl+,로 설정을 엽니다. 모든 단축키는 설정에서 원하는 조합으로 바꿀 수 있습니다.';

  @override
  String get tips_studio_guide_8 =>
      'Anlas를 실수로 왕창 쓸까 걱정된다면 설정에서 높은 Anlas 비용 경고를 켜 두세요. 한 번에 드는 예상 비용이 정한 값을 넘으면 생성 전에 한 번 더 묻습니다.';

  @override
  String get tips_studio_trick_1 =>
      '시드가 이번에 무엇을 뽑을지 정해요. 파라미터와 시드가 같으면 같은 그림이 나와요. 명작을 다시 뽑고 싶다면 시드도 같이 챙기고, 운을 바꾸고 싶다면 그 시드는 그만 쳐다보세요.';

  @override
  String get tips_studio_trick_2 =>
      '미리 인코딩된 Vibe를 다시 쓰면 2 Anlas가 들지 않아요. 2 Anlas쯤이야 싶겠지만, 하루에 Vibe를 몇 번 쓰는지 세어 보면 생각이 달라질걸요.';

  @override
  String get tips_studio_trick_3 =>
      '네거티브 프롬프트는 소원 비는 우물이 아니에요. bad hands를 백 번 쓰는 것보다 프롬프트 쪽에 손동작을 분명하게 쓰는 편이 나아요. 매번 쓰는 네거티브 문구는 네거티브 프리셋에 맡기세요.';

  @override
  String get tips_studio_trick_4 =>
      '작가 태그는 길수록 좋은 게 아니에요. 열 명을 넘기면 모델은 아마 누구 화풍을 원하는지 헷갈리기 시작할 거예요. 몇 개의 블록으로 나눠서 무작위 뽑기로 돌아가며 나오게 해 보세요.';

  @override
  String get tips_studio_trick_5 =>
      '한 번 클릭할 때 보내는 요청 수와 요청마다 나오는 장수는 서로 다른 숫자예요. 버튼에 보이는 건 총 장수이고 Anlas도 총 장수로 계산돼요. 누르기 전에 꼭 확인하세요. 제가 어떻게 아는지는 묻지 마시고요.';

  @override
  String get tips_studio_trick_6 =>
      '번역 블록을 가운데 버튼으로 누르면 원문과 번역문이 번갈아 바뀌어요. AI 번역이 아무리 좋아도 가끔은 원문을 슬쩍 보고 cat ears가 이상한 말로 바뀌지 않았는지 확인해 보세요.';

  @override
  String get tips_studio_trick_7 =>
      '설정의 생성 빈도 제한을 켜면 생성 사이에 강제로 쉬는 시간을 둘 수 있어요. 간격 무작위 변동까지 더하면 리듬이 덜 기계적이에요. 느긋하게 돌리는 밤에도, 손이 멈추지 않는 나에게도 좋아요.';

  @override
  String get tips_studio_wolf_1 =>
      '여기는 늑대 굴이야. 네가 만든 그림은 내가 물어 와서 갤러리에 가지런히 쌓아 둬. 솔직히 그림 실력보다 정리 실력이 훨씬 믿을 만하지.';

  @override
  String get tips_studio_wolf_2 =>
      '늑대는 밤눈이 제일 밝아. 그러니까 네가 새벽 세 시에 아직 여기 있어도 아무 말 안 할게. 그냥 한 장 더 같이 뽑아 줄 뿐이야.';

  @override
  String get tips_studio_wolf_3 =>
      'AI 그림쟁이의 성인식은 한 손의 손가락을 침착하게 끝까지 세는 거래. 나는 손가락이 없어서 늘 침착해.';

  @override
  String get tips_studio_wolf_4 =>
      '늑대 무리의 규칙: 좋은 시드는 나누고, 좋은 프롬프트는 블록으로 저장하고, 좋은 그림은 감상하기 전에 먼저 저장할 것. 마지막이 제일 중요해. 이유는 묻지 마.';

  @override
  String get tips_studio_wolf_5 =>
      '나는 그림은 못 그려도 기다리는 건 잘해. 미리보기가 조금씩 선명해지는 그 몇 초가 하루 중 제일 조용한 시간이야.';

  @override
  String get tips_studio_wolf_6 =>
      'W.O.F는 WolF라는 뜻이야. 가운데 점이 뭐냐고? 내가 눈밭을 달리다 남긴 발자국이지.';

  @override
  String get tips_studio_wolf_7 =>
      '캔버스가 비어 있을 땐 여기서 웅크리고 낮잠을 자. 생성을 누르면 바로 일어날게.';

  @override
  String get tips_studio_night_1 =>
      '지금은 한밤중이야. 미리 말해 두는데, 이 시간대엔 네 안목이 몰래 30% 정도 과감해져. 아침에 일어나서 한 번 더 봐.';

  @override
  String get tips_studio_night_2 =>
      '밤이 깊었어. 저 멀리 서버실의 GPU도 하품을 했어. 이번 묶음만 끝내고 자러 가. 갤러리는 내가 지킬게.';

  @override
  String get tips_lab_guide_1 =>
      '스타일 탐색은 일종의 오디션입니다. 먼저 탐색 작업을 만들어 프롬프트와 파라미터를 고정하고, 후보를 한꺼번에 생성합니다. 고른 자손이 다음 세대의 부모가 되면서 화풍이 세대마다 원하는 방향으로 다가갑니다.';

  @override
  String get tips_lab_guide_2 =>
      '하트와 폴더는 정리용일 뿐 유전에는 영향을 주지 않습니다. 다음 세대를 정하는 건 \'분기용으로 선택\'으로 고른 후보들입니다.';

  @override
  String get tips_lab_guide_3 =>
      '고민될 땐 A/B 비교를 써 보세요. 부모 이미지 두 장이 나란히 나오면 어느 쪽이 원하는 화풍에 더 가까운지만 고르면 됩니다. 순위가 높은 부모일수록 다음 라운드에서 자손을 얻기 쉽습니다.';

  @override
  String get tips_lab_guide_4 =>
      '다음 라운드를 생성하려면 메인 프롬프트에 유전을 켠 무작위 블록이 하나는 있어야 합니다. 바뀔 유전자가 없으면 변이 엔진도 손쓸 방법이 없습니다.';

  @override
  String get tips_lab_guide_5 =>
      '마음에 드는 조합의 후보가 있다면 \'블록으로 저장\'으로 블록 라이브러리에 넣어 두세요. 생성 화면에서도 바로 쓸 수 있습니다. 여러 장을 고르면 \'병합해 저장\'으로 하나의 블록으로 합칠 수도 있습니다.';

  @override
  String get tips_lab_guide_6 =>
      '탐색 작업을 삭제해도 작업 폴더의 후보 사본만 지워지고, 갤러리의 원본은 그대로입니다. 마음 놓고 정리하세요. 실험실은 원래 좀 어수선해야 합니다.';

  @override
  String get tips_lab_trick_1 =>
      '부모마다 최소 한 장은 배정되니까 부모가 많을수록 한 라운드에 필요한 장수도 늘어요. 욕심부리면 Anlas가 먼저 그만하라고 할 거예요.';

  @override
  String get tips_lab_trick_2 =>
      '분기는 최신 세대 후보 더미에서만 만들 수 있어요. 지난 세대를 돌아볼 순 있어도 중간에서 갈라질 순 없어요. 진화란 원래 그렇게 냉정하죠.';

  @override
  String get tips_lab_trick_3 =>
      '변이 엔진이 가끔 충분히 다른 자손을 만들 수 없다고 할 때가 있어요. 게으른 게 아니라 유전자 풀이 너무 작은 거예요. 무작위 블록에 후보를 몇 개 더 넣어 주면 바로 다시 일해요.';

  @override
  String get tips_lab_trick_4 =>
      '후보 더미의 썸네일에 마우스를 올리면 크게 볼 수 있어요. 하나씩 열 필요 없어요. 심사위원에겐 심사위원다운 효율이 필요하니까요.';

  @override
  String get tips_lab_trick_5 =>
      '어떤 후보의 설정 전체가 마음에 든다면 \'메타데이터 가져오기\'로 프롬프트와 파라미터를 그대로 편집 영역에 가져올 수 있어요. 거기서 이어서 다듬으면 돼요.';

  @override
  String get tips_lab_wolf_1 =>
      '태어날 때부터 무리에서 제일 센 늑대는 없어. 화풍도 마찬가지야. 첫 세대가 좀 별로인 건 당연해. 판단은 3세대쯤에 하자.';

  @override
  String get tips_lab_wolf_2 =>
      '여기 적자생존은 다정한 버전이야. 뽑히지 않은 후보도 사라지지 않아. 이번엔 차례가 아니었을 뿐이야.';

  @override
  String get tips_lab_wolf_3 =>
      '내가 아는 유전학은 이게 전부야. 잘생긴 부모한테선 아마 잘생긴 새끼가 나온다. 나머지는 변이랑 약간의 운이지.';

  @override
  String get tips_lab_wolf_4 =>
      'LAB 불은 보통 늦게까지 켜져 있어. 나는 입구에서 당번을 서면서 지금 몇 세대째인지 세어 둘게.';

  @override
  String get tips_lab_wolf_5 =>
      '변이를 얕보면 안 돼. 열 세대를 골라도 못 찾던 게 우연히 툭 튀어나올 때가 있거든. 그러니까 좀 이상해 보이는 한 장도 서둘러 지우지 마.';

  @override
  String get tips_prompt_guide_1 => 'Ctrl+Enter로 생성하고, 생성 중에는 Esc로 취소합니다.';

  @override
  String get tips_prompt_guide_2 =>
      '텍스트를 선택하고 Alt를 누른 채 휠을 굴리면 가중치가 바뀝니다. Alt 없이 굴리면 그냥 스크롤됩니다.';

  @override
  String get tips_prompt_guide_3 =>
      '태그를 Ctrl+클릭하면 로컬 태그에서 찾고, Ctrl+드래그로 고르면 함께 자주 쓰이는 태그를 볼 수 있습니다.';

  @override
  String get tips_prompt_guide_4 =>
      '텍스트를 선택하고 오른쪽 클릭하면 바로 블록 라이브러리에 저장할 수 있습니다. 다음부터는 클릭이나 드래그 한 번이면 다시 넣을 수 있습니다.';

  @override
  String get tips_prompt_guide_5 =>
      '칸 아래쪽의 품질 태그 프리셋이 자주 쓰는 품질 태그를 대신 붙여 줍니다. 네거티브로 바꾸면 같은 자리에 네거티브 프리셋이 있습니다.';

  @override
  String get tips_prompt_guide_6 => 'F1을 누르면 모든 단축키를 볼 수 있습니다.';

  @override
  String get tips_prompt_guide_7 =>
      'ComfyUI에서 복사한 다중 캐릭터 프롬프트를 붙여 넣으면 자동으로 인식해 캐릭터 칸으로 가져올지 묻습니다. 하나씩 다시 입력할 필요가 없습니다.';

  @override
  String get tips_prompt_guide_8 =>
      'SD 구문 자동 변환을 켜면 (tag:1.2) 같은 표기가 입력란을 벗어나거나 생성할 때 NovelAI 가중치 형식으로 바뀝니다.';

  @override
  String get tips_prompt_guide_9 =>
      '1.2::태그::로 가중치를 정확히 지정합니다. 음수를 쓰면 반대로 작용합니다.';

  @override
  String get tips_prompt_trick_1 =>
      '중괄호를 한 겹 씌울 때마다 가중치는 1.05배, 대괄호는 1.05로 나눠요. 중괄호를 다섯 겹씩 씌우는 사람은 대개 모델이랑 말다툼 중이에요.';

  @override
  String get tips_prompt_trick_2 =>
      '자동 서식은 쓸모없는 1배 가중치를 지워요. 미워서가 아니라 토큰을 아껴 주는 거예요.';

  @override
  String get tips_prompt_trick_3 =>
      '칸 아래의 가는 막대는 토큰 사용량이에요. 꽉 차면 그 뒤 내용은 모델이 거의 못 봐요. 장편 소설을 쓰려면 다른 곳을 찾아 주세요.';

  @override
  String get tips_prompt_trick_4 => '막힐 땐 화면에서 제일 큰 것부터 써 보세요.';

  @override
  String get tips_prompt_trick_5 =>
      '품질 태그는 한 번이면 충분해요. masterpiece를 세 번 써도 모델은 진심을 더 느끼지 않아요.';

  @override
  String get tips_prompt_trick_6 =>
      '나오긴 하되 너무 튀지 않게 하고 싶다면 지우는 것보다 0.8::이 나아요. 지우면 없는 거고, 낮추면 은은한 거예요.';

  @override
  String get tips_prompt_trick_7 => '같은 단어만 계속 바꾸고 있다면 블록으로 만들어 무작위에 맡겨 보세요.';

  @override
  String get tips_prompt_trick_8 =>
      '프롬프트에는 원하는 것, 네거티브에는 원하지 않는 것. 프롬프트에 no hat이라고 써도 모델 귀에는 hat만 들려요.';

  @override
  String get tips_prompt_wolf_1 => '이 칸은 수천 장의 명작을 봤어. 남한테 보여 주기 곤란한 흑역사도 몇 장.';

  @override
  String get tips_prompt_wolf_2 =>
      '먼저 원하는 그림을 한 문장으로 말해 보고, 그다음에 태그로 쪼개. 순서를 거꾸로 하면 태그 더미랑 뭔지 모를 그림만 남기 쉬워.';

  @override
  String get tips_prompt_wolf_3 => '너 타자 치는 거 보고 있어. 걱정 마, 나 영어 못 읽어.';

  @override
  String get tips_prompt_wolf_4 => '저 멀리 어떤 GPU가 방금 네 프롬프트를 보고 한숨을 쉬었어.';

  @override
  String get tips_prompt_wolf_5 => '가챠의 끝은 미신, 미신의 끝은 시드 고정.';

  @override
  String get tips_prompt_wolf_6 =>
      '작가 태그가 열두 번째쯤 되면 모델은 누구 그림을 그리는지 모르게 돼. 너도 그렇고.';

  @override
  String get tips_explore_guide_1 =>
      '여기에는 부모 프롬프트를 씁니다. 일부를 진화시키고 싶다면 그 부분을 무작위 블록으로 만들고 블록에서 유전을 켜세요.';

  @override
  String get tips_explore_guide_2 =>
      '유전은 블록 인스턴스를 켠 뒤에야 켤 수 있습니다. 회색이라면 블록부터 켜세요.';

  @override
  String get tips_explore_guide_3 => '\'후보 생성\' 옆의 숫자가 이번 라운드에 몇 장을 만들지 정합니다.';

  @override
  String get tips_explore_guide_4 =>
      '블록 인스턴스는 \'한 장면 뒤로\', \'한 장면 앞으로\'로 이미 뽑았던 조합 사이를 오갈 수 있습니다.';

  @override
  String get tips_explore_guide_5 =>
      '탐색 작업은 프롬프트와 파라미터의 스냅숏을 고정합니다. 나중에 여기를 고쳐도 이미 끝난 라운드에는 영향이 없습니다.';

  @override
  String get tips_explore_guide_6 =>
      '블록의 무작위 설정에서 뽑을 개수, 발동 확률, 무작위 가중치를 조절할 수 있습니다. 유전자의 다양성은 전부 여기에 있습니다.';

  @override
  String get tips_explore_trick_1 =>
      '유전자 풀이 클수록 변이가 고를 게 많아져요. 무작위 블록에 단어가 두 개뿐이면 열 세대를 진화해도 두 답 사이를 오갈 뿐이에요.';

  @override
  String get tips_explore_trick_2 =>
      '확실한 부분은 고정하고, 애매한 부분만 무작위 블록으로 만드세요. 전부 무작위면 방향이 없고, 전부 고정이면 진화가 없어요.';

  @override
  String get tips_explore_trick_3 =>
      '잠근 블록은 다시 뽑히지 않아요. 지키고 싶은 특징은 먼저 잠그고 나머지 블록이 마음껏 바뀌게 두세요.';

  @override
  String get tips_explore_trick_4 =>
      '발동 확률을 30%로 두면 그 블록은 대략 열에 셋 정도의 조합에만 나와요. 가끔 나와야 예쁜 요소에 딱이에요.';

  @override
  String get tips_explore_trick_5 => '첫 세대에서 완벽한 답을 바란다면, 그건 탐색이 아니라 소원이에요.';

  @override
  String get tips_explore_wolf_1 => '늑대 무리의 혈통은 한 세대씩 골라 온 거야. 네 화풍도 그래.';

  @override
  String get tips_explore_wolf_2 => '매 라운드가 오디션이고 심사위원은 너 하나야. 나는 박수 담당.';

  @override
  String get tips_explore_wolf_3 =>
      '좋은 유전자는 좋은 부모한테서, 좋은 부모는 손이 미끄러지지 않은 그 한 번의 클릭에서 나와.';

  @override
  String get tips_explore_wolf_4 =>
      '유전학은 잘 몰라도 이건 알아. 깐깐한 심사위원이 제일 멋진 새끼 늑대를 키워.';

  @override
  String get tips_character_guide_1 =>
      '캐릭터 칸의 정체는 위치를 정하는 칸입니다. 고양이, 램프, 간판 무엇이든 넣을 수 있습니다.';

  @override
  String get tips_character_guide_2 =>
      '위쪽 위치를 사용자 지정으로 바꾸고 미리보기에서 앵커를 끄세요. 놓는 순간 적용됩니다.';

  @override
  String get tips_character_guide_3 =>
      'AI 선택은 위치를 모델에게 맡깁니다. 사용자 지정으로 돌아가면 전에 정한 위치가 그대로 있습니다.';

  @override
  String get tips_character_guide_4 => '캐릭터 칸마다 자기 네거티브가 있고, 그 캐릭터에만 적용됩니다.';

  @override
  String get tips_character_guide_5 =>
      '오른쪽 위 체크 표시로 이 캐릭터를 잠시 끌 수 있습니다. 지우고 다시 쓸 필요가 없습니다.';

  @override
  String get tips_character_guide_6 =>
      '제목을 누르면 이름을 바꿀 수 있습니다. 번호보다 훨씬 알아보기 쉽습니다.';

  @override
  String get tips_character_guide_7 =>
      '오른쪽 위 ⋯ 메뉴에서 이 캐릭터를 블록 라이브러리에 추가해 두면 나중에 이 묘사를 다시 쓸 수 있습니다.';

  @override
  String get tips_character_trick_1 =>
      '장면과 화풍은 메인 프롬프트에, 여기엔 이 캐릭터만 쓰세요. 같은 옷을 두 번 쓰면 모델은 엄청 좋아하는 줄 알아요.';

  @override
  String get tips_character_trick_2 =>
      '두 사람이 너무 가까우면 붙어 버리기 쉬워요. separate를 열 번 쓰기보다 앵커를 조금 떨어뜨리세요.';

  @override
  String get tips_character_trick_3 =>
      '왼쪽에 나무를 세우고 싶다면 캐릭터 칸을 주고 왼쪽으로 끌어 두세요. 나무는 캐릭터가 아니라고 불평 안 해요.';

  @override
  String get tips_character_trick_4 =>
      '캐릭터 칸에서도 블록과 가중치 문법을 쓸 수 있어요. 메인 프롬프트와 똑같아요.';

  @override
  String get tips_character_trick_5 =>
      '캐릭터가 너무 많다면 몇 명을 꺼 보세요. 비좁으면 모델이 알아서 고르는데, 대개 남기고 싶던 사람이 빠져요.';

  @override
  String get tips_character_wolf_1 =>
      '나도 캐릭터 칸 하나 갖고 싶지만, 화면 밖에서 지켜보는 게 더 어울리는 것 같아.';

  @override
  String get tips_character_wolf_2 => '칸 하나, 자리 하나, 할 일 하나. 꽤 괜찮은 인생 철학 같아.';

  @override
  String get tips_character_wolf_3 =>
      '자리 배치는 네가 하고, 나는 옆에서 \"조금만 더 왼쪽\" 하고 외칠게.';

  @override
  String get tips_character_wolf_4 =>
      '늑대 무리도 대형을 짜서 다녀. 캐릭터가 많을 땐 누가 가운데 설지부터 정하자.';

  @override
  String get tips_gallery_guide_1 => '파일 이름이나 프롬프트 본문으로 검색';

  @override
  String get tips_gallery_guide_2 => '쉼표로 나누면 모두 일치';

  @override
  String get tips_gallery_guide_3 => '모델, 샘플러, 출처도 검색';

  @override
  String get tips_gallery_guide_4 => 'Ctrl+F로 언제든 여기로 이동';

  @override
  String get tips_gallery_guide_5 => '캐릭터 프롬프트도 검색';

  @override
  String get tips_gallery_guide_6 => '이미지 오른쪽 클릭으로 더 보기';

  @override
  String get tips_gallery_guide_7 => 'F5로 갤러리 새로고침';

  @override
  String get tips_gallery_trick_1 => '네거티브는 검색 안 돼요';

  @override
  String get tips_gallery_trick_2 => '다시 뽑기 전에 검색부터';

  @override
  String get tips_gallery_trick_3 => '내 프롬프트가 최고의 검색어';

  @override
  String get tips_gallery_trick_4 => '휴지통은 다음 실행 때 비워져요';

  @override
  String get tips_gallery_trick_5 => 'masterpiece는 거의 전부 나와요';

  @override
  String get tips_gallery_wolf_1 => '오늘 밤 사냥감은 세 번째 페이지';

  @override
  String get tips_gallery_wolf_2 => '냄새가 나, 명작이 여기 있어';

  @override
  String get tips_gallery_wolf_3 => '스크롤도 운동이야';

  @override
  String get tips_gallery_wolf_4 => '굴은 넓어, 천천히 찾아봐';

  @override
  String get tips_online_guide_1 => '공백으로 나누고 Enter';

  @override
  String get tips_online_guide_2 => '유사 일치: *tag*로 비슷한 태그';

  @override
  String get tips_online_guide_3 => '차단 목록 태그는 숨겨져요';

  @override
  String get tips_online_guide_4 => 'Danbooru 로그인 후 즐겨찾기';

  @override
  String get tips_online_trick_1 => '여러 단어는 밑줄로: blue_eyes';

  @override
  String get tips_online_trick_2 => '좋은 그림의 태그는 참고하세요';

  @override
  String get tips_online_trick_3 => '태그가 많을수록 결과는 줄어요';

  @override
  String get tips_online_wolf_1 => '바깥세상은 넓어, 정찰하고 올게';

  @override
  String get tips_online_wolf_2 => '남의 영역이야, 구경만 하자';

  @override
  String get tips_online_wolf_3 => '오늘은 어느 숲에서 사냥할까?';

  @override
  String get tips_blocks_guide_1 => '제목, 프롬프트, 태그로 검색';

  @override
  String get tips_blocks_guide_2 => '블록을 프롬프트로 끌어오기';

  @override
  String get tips_blocks_guide_3 => '★로 즐겨찾기에 모으기';

  @override
  String get tips_blocks_guide_4 => '썸네일이 있으면 고르기 쉬워요';

  @override
  String get tips_blocks_guide_5 => '선택 후 오른쪽 클릭으로 저장';

  @override
  String get tips_blocks_trick_1 => '세 번 썼다면 블록으로';

  @override
  String get tips_blocks_trick_2 => '고민되면 저장. 지우긴 쉬워요';

  @override
  String get tips_blocks_trick_3 => '이름은 분명하게, 미래의 나를 위해';

  @override
  String get tips_blocks_trick_4 => '후보가 많을수록 놀라움도 커요';

  @override
  String get tips_blocks_wolf_1 => '블록들이 다 출전을 기다려';

  @override
  String get tips_blocks_wolf_2 => '이 블록들이 네 무리야';

  @override
  String get tips_blocks_wolf_3 => '내가 아는 블록은 고기뿐';

  @override
  String get tips_blocks_wolf_4 => '폴더 안에 폴더, 정리 끝';

  @override
  String get tips_generating_wolf_1 => '난수와 흥정하는 중…';

  @override
  String get tips_generating_wolf_2 => '여섯 번째 손가락을 설득하는 중…';

  @override
  String get tips_generating_wolf_3 => '픽셀들을 줄 세우는 중…';

  @override
  String get tips_generating_wolf_4 => '노이즈를 한 알씩 닦아 내는 중…';

  @override
  String get tips_generating_wolf_5 => '늑대가 멀리서 응원하며 우는 중…';

  @override
  String get tips_generating_wolf_6 => 'GPU에게 네 취향을 설명하는 중…';

  @override
  String get tips_generating_wolf_7 => '프롬프트를 꿈으로 번역하는 중…';

  @override
  String get tips_generating_wolf_8 => '눈 개수를 확인하는 중…';

  @override
  String get tips_generating_wolf_9 => '빛과 그림자의 좋은 각도를 찾는 중…';

  @override
  String get tips_generating_wolf_10 => '배경이 튀지 않게 설득하는 중…';

  @override
  String get tips_generating_wolf_11 => '노이즈 속에서 그림을 건져 내는 중…';

  @override
  String get tips_generating_wolf_12 => '손가락 세는 중: 하나, 둘, 셋…';

  @override
  String get tips_generating_wolf_13 => '물감이 마르길 기다리는 중…';

  @override
  String get tips_generating_wolf_14 => '오늘의 운을 소환하는 중…';

  @override
  String get tips_generating_trick_1 => '못 기다리겠다면 Esc로 취소';

  @override
  String get tips_generating_trick_2 => '미리보기는 조금씩 선명해져요';

  @override
  String get tips_generating_trick_3 => '완성된 그림은 기본으로 갤러리에 저장돼요';

  @override
  String get tips_generating_trick_4 => '샘플링 한 단계마다 노이즈가 걷혀요';

  @override
  String get tips_splash_guide_1 => 'F1을 누르면 언제든 모든 단축키를 볼 수 있습니다.';

  @override
  String get tips_splash_guide_2 =>
      'Ctrl+Enter로 생성합니다. 모든 단축키는 설정에서 바꿀 수 있습니다.';

  @override
  String get tips_splash_guide_3 => '이미지를 창에 끌어다 놓으면 프롬프트와 파라미터를 읽을 수 있습니다.';

  @override
  String get tips_splash_guide_4 =>
      '자주 쓰는 프롬프트는 블록으로 저장해 두면 다음엔 한 번에 다시 쓸 수 있습니다.';

  @override
  String get tips_splash_trick_1 => '위의 STEP /28은 기본 28스텝 샘플링에 바치는 오마주예요.';

  @override
  String get tips_splash_trick_2 =>
      '미리 인코딩된 Vibe는 무료로 다시 쓸 수 있어서 2 Anlas가 절약돼요.';

  @override
  String get tips_splash_trick_3 =>
      '처음 갤러리 색인을 만들 땐 조금 걸리지만 그동안에도 평소처럼 쓸 수 있어요.';

  @override
  String get tips_splash_wolf_1 => '오 분만 더… 알았어, 일어날게.';

  @override
  String get tips_splash_wolf_2 => '굴 좀 치우는 중이야. 금방 끝나.';

  @override
  String get tips_splash_wolf_3 => 'GPU 준비 완료, 달 준비 완료. 이제 너만 오면 돼.';

  @override
  String get tips_splash_wolf_4 => '냄새 나지? 새 프롬프트 냄새야.';

  @override
  String get tips_splash_wolf_5 => '오늘도 좋은 뽑기 하자.';

  @override
  String genButton_normal(int count) {
    return '이미지 $count장 생성';
  }

  @override
  String get genButton_one_1 => '이 한 장으로 끝';

  @override
  String get genButton_one_2 => '좋은 걸로 한 장';

  @override
  String get genButton_one_3 => '단챠, 믿음의 도약';

  @override
  String get genButton_one_4 => '일단 한 장 맛보기';

  @override
  String get genButton_one_5 => '한 장으로 승부';

  @override
  String get genButton_one_6 => '이건 명작 각';

  @override
  String get genButton_one_7 => '딱 한 장만, 진짜로';

  @override
  String get genButton_one_8 => '새 프사는 이걸로';

  @override
  String get genButton_one_9 => '한 방에 끝내기';

  @override
  String get genButton_one_10 => '배경화면감으로 한 장';

  @override
  String get genButton_one_11 => '살포시 한 장';

  @override
  String get genButton_one_12 => '한 장 물어 올게';

  @override
  String genButton_few_1(int count) {
    return '$count장 중 최고를';
  }

  @override
  String genButton_few_2(int count) {
    return '$count장 비교하기';
  }

  @override
  String genButton_few_3(int count) {
    return '$count연차';
  }

  @override
  String genButton_few_4(int count) {
    return '$count장, 하나는 걸린다';
  }

  @override
  String genButton_few_5(int count) {
    return '$count개 중 하나, 심사 시작';
  }

  @override
  String genButton_few_6(int count) {
    return '$count장으로 몸풀기';
  }

  @override
  String genButton_few_7(int count) {
    return '$count장 중 선발';
  }

  @override
  String genButton_few_8(int count) {
    return '$count장의 소확행';
  }

  @override
  String genButton_batch_1(int count) {
    return '$count연발';
  }

  @override
  String genButton_batch_2(int count) {
    return '$count장 한꺼번에';
  }

  @override
  String genButton_batch_3(int count) {
    return '$count장, 빠져들기 시작';
  }

  @override
  String genButton_batch_4(int count) {
    return '한 번에 $count장, 넉넉하게';
  }

  @override
  String genButton_batch_5(int count) {
    return '$count장으로 화면 채우기';
  }

  @override
  String genButton_batch_6(int count) {
    return '$count연차, 안전하게';
  }

  @override
  String genButton_batch_7(int count) {
    return '$count장, 늑대 무리 출동';
  }

  @override
  String genButton_batch_8(int count) {
    return '$count장, 잔치 시작';
  }

  @override
  String genButton_many_1(int count) {
    return '$count장, 강도 올린다';
  }

  @override
  String genButton_many_2(int count) {
    return '$count장, GPU가 땀 흘린다';
  }

  @override
  String genButton_many_3(int count) {
    return '$count장, 사재기 모드';
  }

  @override
  String genButton_many_4(int count) {
    return '$count장, 생산 라인 가동';
  }

  @override
  String genButton_many_5(int count) {
    return '$count장, Anlas가 탄다';
  }

  @override
  String genButton_many_6(int count) {
    return '$count장, 매일 연재각';
  }

  @override
  String genButton_many_7(int count) {
    return '$count장 일괄 출격';
  }

  @override
  String genButton_many_8(int count) {
    return '$count장, 늑대도 멍해짐';
  }

  @override
  String genButton_huge_1(int count) {
    return '$count장?! 전시회라도 여나요';
  }

  @override
  String genButton_huge_2(int count) {
    return '$count장, 하드가 떤다';
  }

  @override
  String genButton_huge_3(int count) {
    return '$count장, 산업 혁명';
  }

  @override
  String genButton_huge_4(int count) {
    return '$count장, 일단 심호흡';
  }

  @override
  String genButton_huge_5(int count) {
    return '$count장, 용량은 괜찮나요';
  }

  @override
  String genButton_huge_6(int count) {
    return '$count장, 인쇄소 개업';
  }

  @override
  String genButton_huge_7(int count) {
    return '$count장, 도매로';
  }

  @override
  String genButton_huge_8(int count) {
    return '$count장, 늑대가 지원군 부르러 감';
  }

  @override
  String get genButton_rare_1 => 'SSR 확정 연출';

  @override
  String get genButton_rare_2 => 'AI가 오늘 컨디션 최고래요';

  @override
  String get genButton_rare_3 => '오늘의 운세: 대길';

  @override
  String get genButton_rare_4 => '이 버튼이 당신과 궁합이 좋대요';

  @override
  String get genButton_rare_5 => '늑대가 달을 보고 울었다';

  @override
  String get genButton_rare_6 => '행운 버프 적용 중';

  @override
  String get genButton_rare_7 => '운 충전 완료';

  @override
  String get genButton_rare_8 => '이번 뽑기는 늑대가 후원합니다';

  @override
  String get genButton_rare_9 => '와라, 신의 한 수!';

  @override
  String get genButton_rare_10 => '누르면 믿음이 된다';

  @override
  String get genButton_night_1 => '밤이 깊었다, 마지막 한 번';

  @override
  String get genButton_night_2 => '이번만 뽑고 잘게';

  @override
  String get genButton_night_3 => '새벽 감성은 과감하다';

  @override
  String get genButton_night_4 => '늑대도 같이 밤샘 중';

  @override
  String genButton_special_7(int count) {
    return '럭키 $count';
  }

  @override
  String genButton_special_9(int count) {
    return '$count장, 3×3 그리드 완성';
  }

  @override
  String genButton_special_42(int count) {
    return '$count: 모든 것의 답';
  }

  @override
  String genButton_special_99(int count) {
    return '$count장, 100까지 한 장';
  }

  @override
  String genButton_special_100(int count) {
    return '딱 $count장, 속이 시원';
  }

  @override
  String get titleBar_minimize => '최소화';

  @override
  String get titleBar_maximize => '최대화';

  @override
  String get titleBar_restore => '이전 크기로';

  @override
  String get titleBar_close => '닫기';

  @override
  String get img2img_pixelSnap => '픽셀 스냅';

  @override
  String get img2img_masked => '누끼';

  @override
  String get img2img_generated => '생성 결과';

  @override
  String get img2img_blend => '혼합';

  @override
  String get img2img_enhanceAction => '향상!';

  @override
  String get img2img_showAdvanced => '고급 설정 표시';

  @override
  String get img2img_hideAdvanced => '고급 설정 숨기기';

  @override
  String promptToken_usage(int used, int limit) {
    return '토큰 사용량: $used / $limit';
  }

  @override
  String promptToken_promptShare(int used, int total, int limit) {
    return '이 프롬프트: $used토큰, 전체 사용량: $total / $limit';
  }

  @override
  String get promptToken_blockReferenceHint =>
      '블록별 진행률은 참고용이며, 전체 사용량은 블록을 조합하는 방식에 따라 달라집니다.';

  @override
  String get settings_geistDark => 'Geist 다크';

  @override
  String get settings_geistLight => 'Geist 라이트';

  @override
  String get settings_geistDescription =>
      '스튜디오 전체에 하나의 외관. 검정 또는 흰색 바탕에 파란색 강조.';

  @override
  String get updateCapsuleLabel => '업데이트';

  @override
  String get updateWaitForTask => '현재 작업이 끝난 뒤 다시 시작하세요';

  @override
  String get updateLater => '나중에';

  @override
  String get nav_tagWiki => '태그 백과';

  @override
  String get wiki_title => '태그 백과';

  @override
  String get wiki_allTags => '모든 태그';

  @override
  String get wiki_bookmarks => '북마크';

  @override
  String get wiki_newCollection => '새 북마크 컬렉션';

  @override
  String get wiki_newChildCollection => '새 하위 컬렉션';

  @override
  String get wiki_renameCollection => '이름 변경';

  @override
  String get wiki_deleteCollection => '컬렉션 삭제';

  @override
  String get wiki_officialDirectory => '공식 목차';

  @override
  String get wiki_searchHint => '태그나 별칭 검색';

  @override
  String get wiki_typeAllShort => '전체';

  @override
  String get wiki_coverageAll => '모든 설명';

  @override
  String get wiki_withArticle => '설명 있음';

  @override
  String get wiki_withoutArticle => '아직 설명 없음';

  @override
  String get wiki_sortPopular => '인기순';

  @override
  String get wiki_sortName => '이름순';

  @override
  String get wiki_dataStatus => '데이터 상태';

  @override
  String get wiki_scopeCurrent => '현재 섹션';

  @override
  String get wiki_scopeAll => '모든 태그 검색';

  @override
  String get wiki_readingSettings => '읽기 설정';

  @override
  String get wiki_textSize => '본문 크기';

  @override
  String get wiki_readingWidth => '읽기 너비';

  @override
  String get wiki_small => '작게';

  @override
  String get wiki_standard => '표준';

  @override
  String get wiki_large => '크게';

  @override
  String get wiki_wide => '넓게';

  @override
  String get wiki_articleMissing => '이 태그에는 아직 로컬 백과 설명이 없습니다.';

  @override
  String get wiki_source => '출처';

  @override
  String get wiki_addBookmark => '북마크';

  @override
  String get wiki_removeBookmark => '북마크 제거';

  @override
  String get wiki_addToCollection => '컬렉션에 추가';

  @override
  String get wiki_loadMore => '더 불러오기';

  @override
  String get wiki_noResults => '일치하는 태그가 없습니다';

  @override
  String get wiki_noSelection => '태그를 선택하면 설명을 읽을 수 있습니다';

  @override
  String get wiki_collectionNameHint => '컬렉션 이름';

  @override
  String get wiki_syncTags => 'Danbooru 태그 동기화';

  @override
  String get wiki_directorySource => '공식 그룹 목차 스냅숏';

  @override
  String get wiki_openFull => '태그 백과에서 열기';

  @override
  String get shortcut_action_vibe_detail_prev_sub_vibe => '이전 하위 Vibe';

  @override
  String get shortcut_action_vibe_detail_next_sub_vibe => '다음 하위 Vibe';

  @override
  String get settings_addAccountsSwitchBetweenThem =>
      '계정을 추가하면 여기서 바로 전환할 수 있습니다.';

  @override
  String get settings_current => '현재';

  @override
  String get settings_emailLogin => '이메일 로그인';

  @override
  String get settings_signedIn => '로그인됨';

  @override
  String get settings_switch => '전환';

  @override
  String get settings_accountActions => '계정 작업';

  @override
  String get settings_editProfile => '프로필 편집';

  @override
  String get settings_setDefault => '기본 계정으로 설정';

  @override
  String get settings_credentialsUpdated => '로그인 정보를 업데이트했습니다';

  @override
  String get settings_updateCredentials => '로그인 정보 업데이트';

  @override
  String get settings_accountDetails => '계정 상세 정보';

  @override
  String get settings_localAccountProfile => '로컬 계정 프로필';

  @override
  String get settings_setDefault2 => '기본값으로 설정';

  @override
  String get settings_credentialsWereNotUpdatedCheck =>
      '로그인 정보를 업데이트하지 못했습니다. 토큰과 연결을 확인하세요.';

  @override
  String get settings_updateCredentials2 => '로그인 정보 업데이트';

  @override
  String get settings_checking => '확인하는 중…';

  @override
  String get settings_enterNewSignInToken =>
      '새 로그인 토큰을 입력하세요. 확인되면 이 계정이 업데이트됩니다.';

  @override
  String get auth_notSignedIn => '로그인하지 않음';

  @override
  String get settings_tagExpansion => '태그 확장';

  @override
  String get settings_tagDictionaries => '태그 사전';

  @override
  String get settings_cacheMaintenance => '캐시 관리';

  @override
  String get settings_clear => '정리';

  @override
  String get settings_autoRefresh => '자동 새로 고침';

  @override
  String get settings_searchFonts => '글꼴 검색';

  @override
  String get settings_couldNotLoadFonts => '글꼴을 불러올 수 없습니다';

  @override
  String get settings_recommended => '추천';

  @override
  String get settings_included => '기본 포함';

  @override
  String get settings_systemFonts => '시스템 글꼴';

  @override
  String get settings_fontPreview => '글꼴 미리 보기';

  @override
  String get settings_onlineFontsLoadAfterApplying =>
      '온라인 글꼴은 적용한 뒤 불러오며, 미리 보기에는 인터페이스 글꼴이 쓰입니다.';

  @override
  String get settings_saving => '저장';

  @override
  String get settings_howGeneratedImagesSaved => '생성한 이미지 저장 방식';

  @override
  String get settings_assetsDisplay => '자산 및 표시';

  @override
  String get settings_vibeLocationThumbnailQuality => 'Vibe 위치와 썸네일 화질';

  @override
  String get settings_applicationData => '앱 데이터';

  @override
  String get settings_gallerySources => '갤러리 소스';

  @override
  String get settings_manageAdditionalGalleryFolders => '추가 갤러리 폴더 관리';

  @override
  String get settings_default => '기본값';

  @override
  String get settings_keyboard => '키보드';

  @override
  String get settings_customizeFrequentlyUsedActions => '자주 쓰는 작업을 원하는 대로 설정';

  @override
  String get settings_manageShortcuts => '단축키 관리';

  @override
  String get settings_costReminders => '비용 알림';

  @override
  String get settings_requestPacing => '요청 간격';

  @override
  String get settings_notificationsSound => '알림 및 소리';

  @override
  String get settings_lockCanvasCamera => '캔버스 카메라 잠금';

  @override
  String get settings_dictionariesCache => '사전 및 캐시';

  @override
  String get settings_defaultAccount2 => '기본 계정';

  @override
  String get settings_signInAutomatically => '자동 로그인';

  @override
  String get settings_signInCredentials => '로그인 정보';

  @override
  String get settings_translationInterfaces => '번역 인터페이스';

  @override
  String get settings_presetsBuiltInRules => '프리셋 및 기본 제공 규칙';

  @override
  String get settings_preferenceBackupRestore => '환경 설정 백업 및 복원';

  @override
  String get settings_searchSettingsFeatures => '설정과 기능 검색';

  @override
  String get settings_noMatchingSettings => '일치하는 설정이 없습니다';

  @override
  String get settings_change => '변경';

  @override
  String get settings_couldNotPlaySoundCheck =>
      '소리를 재생할 수 없습니다. 오디오 파일을 확인하세요.';

  @override
  String get settings_useDefaultCompletionSound => '기본 완료 효과음 사용';

  @override
  String get settings_soundPreview => '효과음 미리 듣기';

  @override
  String get settings_listenCurrentCompletionSound => '현재 완료 효과음 듣기';

  @override
  String get settings_playSound => '소리 재생';

  @override
  String get settings_searchResults => '검색 결과';

  @override
  String get settings_promptInput => '프롬프트 입력';

  @override
  String get settings_manageTranslationModelsRules => '번역 모델 및 규칙 관리';

  @override
  String get settings_browsing => '보기 방식';

  @override
  String get settings_chooseHowViewImages => '이미지를 보는 방식 선택';

  @override
  String get settings_canvasControls => '캔버스 조작';

  @override
  String get settings_keepViewSteady => '시점을 안정적으로 유지';

  @override
  String get settings_appearance2 => '외관';

  @override
  String get settings_chooseLightDarkWorkspace => '밝거나 어두운 작업 공간 선택';

  @override
  String get settings_textLanguage => '텍스트 및 언어';

  @override
  String get settings_makeReadingComfortable => '읽기 편하게 만들기';

  @override
  String get settings_adjustSettingsPagesDialogsOnly => '설정 페이지와 대화 상자에만 적용';

  @override
  String get settings_motionNotifications => '움직임 및 알림';

  @override
  String get settings_reduceDistractionsKnowWorkFinishes =>
      '방해는 줄이고 작업이 끝나면 알기';

  @override
  String get settings_notificationStyle => '알림 스타일';

  @override
  String get settings_notificationsAppearUpperRightWrap =>
      '알림은 오른쪽 위에 나타나며, 긴 메시지는 줄바꿈되고 진행 작업이 끝나면 닫힙니다.';

  @override
  String get settings_preview => '미리 보기';

  @override
  String get settings_versionUpdates => '버전 및 업데이트';

  @override
  String get settings_currentVersionUpdateOptions => '현재 버전과 업데이트 옵션';

  @override
  String get settings_diagnosticsResources => '진단 및 자료';

  @override
  String get settings_logsFontsOpenSourceProject => '로그, 글꼴, 오픈 소스 프로젝트';

  @override
  String get settings_viewLicenses => '라이선스 보기';

  @override
  String get settings_openProject => '프로젝트 열기';

  @override
  String get settings_actionIncomplete => '작업 미완료';

  @override
  String get settings_exportPreferences => '환경 설정 내보내기';

  @override
  String get settings_preferencesExported => '환경 설정을 내보냈습니다';

  @override
  String get settings_noAutomaticBackupYet => '아직 자동 백업이 없습니다';

  @override
  String get settings_restorePreviousPreferences => '이전 환경 설정 복원';

  @override
  String get settings_importPreferences => '환경 설정 가져오기';

  @override
  String get settings_apply => '적용';

  @override
  String get settings_preferencesAppliedPreviousSettingsBacked =>
      '환경 설정을 적용하고 이전 설정을 백업했습니다';

  @override
  String get settings_restoreDefaultPreferences => '기본 환경 설정 복원';

  @override
  String get settings_choosePreferencesResetCurrentSettings =>
      '초기화할 환경 설정을 선택하세요. 현재 설정은 백업됩니다.';

  @override
  String get settings_appearanceSoundControls => '외관, 소리 및 조작';

  @override
  String get settings_inputAutocomplete => '입력 및 자동 완성';

  @override
  String get settings_privacyGenerationProtection => '개인정보 및 생성 보호';

  @override
  String get settings_moveAppearanceControlsInputProtection =>
      '외관, 조작, 입력, 보호 환경 설정을 기기 간에 옮깁니다.';

  @override
  String get settings_rollbackCopySavedBeforeImport =>
      '가져오거나 초기화하기 전에 되돌리기용 사본을 저장합니다.';

  @override
  String get settings_resetSelectedScopeWhileKeeping =>
      '계정, 모델, 라이브러리, 창작물은 유지한 채 선택한 범위만 초기화합니다.';

  @override
  String get settings_chooseScope => '범위 선택';

  @override
  String get settings_preferenceManagement => '환경 설정 관리';

  @override
  String get settings_backupMigrationRecovery => '백업, 이전 및 복구';

  @override
  String get settings_generalAppearance => '일반 및 외관';

  @override
  String get settings_makeWorkspaceComfortableReadUse =>
      '작업 공간을 읽고 쓰기 편하게 만듭니다.';

  @override
  String get settings_controlsShortcuts => '조작 및 단축키';

  @override
  String get settings_chooseInteractionCanvasControlsKeyboard =>
      '상호작용, 캔버스 조작, 키보드 단축키를 설정합니다.';

  @override
  String get settings_generationPrompts => '생성 및 프롬프트';

  @override
  String get settings_managePromptInputGenerationReminders =>
      '프롬프트 입력, 생성 알림, 요청 간격을 관리합니다.';

  @override
  String get settings_galleryFiles => '갤러리 및 파일';

  @override
  String get settings_manageImageSavingGallerySources =>
      '이미지 저장, 갤러리 소스, 표시 방식을 관리합니다.';

  @override
  String get settings_manageTagDictionariesIndexesCache =>
      '태그 사전, 인덱스, 캐시를 관리합니다.';

  @override
  String get settings_novelaiAccounts => 'NovelAI 계정';

  @override
  String get settings_viewAccountManageSignIn => '계정을 확인하고 로그인과 기본 계정을 관리합니다.';

  @override
  String get settings_connectionsIntegrations => '연결 및 연동';

  @override
  String get settings_manageExternalToolsBridgesNetwork =>
      '외부 도구, 브리지, 네트워크 설정을 관리합니다.';

  @override
  String get settings_privacySharing2 => '개인정보 및 공유';

  @override
  String get settings_controlSharedInformationConfirmationBefore =>
      '공유되는 정보와 민감한 작업 전 확인을 관리합니다.';

  @override
  String get settings_aboutDiagnostics => '정보 및 진단';

  @override
  String get settings_updatesLogsProjectInformation => '업데이트, 로그, 프로젝트 정보.';

  @override
  String get settings_searchSettings => '설정 검색';

  @override
  String get settings_preferences => '환경 설정';

  @override
  String get settings_creationResources => '창작 및 리소스';

  @override
  String get settings_servicesConnections => '서비스 및 연결';

  @override
  String get settings_safetyMaintenance => '보안 및 관리';

  @override
  String get settings_subscriptionActive => '구독 활성';

  @override
  String get settings_availableBalance => '사용 가능 잔액';

  @override
  String get settings_subscriptionExpiry2 => '구독 만료일';

  @override
  String get settings_subscriptionDetailsUnavailable => '구독 정보를 확인할 수 없습니다';

  @override
  String get settings_loadingSubscriptionDetails => '구독 정보 불러오는 중…';

  @override
  String get settings_localDataStaysAvailableAfter =>
      '만료된 뒤에도 로컬 데이터는 그대로 사용할 수 있습니다.';

  @override
  String get settings_records => '건';

  @override
  String get settings_hitRate => '적중률';

  @override
  String get settings_images => '장';

  @override
  String get settings_cacheOverview => '캐시 개요';

  @override
  String get settings_loginPreferences => '로그인 환경 설정';

  @override
  String get settings_preselectedSignInPage => '로그인 페이지에서 미리 선택됩니다.';

  @override
  String get settings_noAccounts => '계정 없음';

  @override
  String get settings_useLastSessionOffNext =>
      '마지막 세션을 사용합니다. 끄면 다음 실행 때 로그인 화면이 열립니다.';

  @override
  String get settings_couldNotSaveLoginPreference => '로그인 환경 설정을 저장하지 못했습니다.';

  @override
  String get settings_loginPreferencesUnavailable => '로그인 환경 설정을 확인할 수 없습니다.';

  @override
  String settings_applyPreferencesConfirm(Object count) {
    return '환경 설정 $count개를 적용합니다. 현재 환경 설정은 자동으로 백업되며 \"이전 환경 설정 복원\"에서 되돌릴 수 있습니다. 계정, 비밀 키, 초안, 라이브러리, 모델 설정은 따로 유지됩니다.';
  }

  @override
  String get settings_restore => '복원';

  @override
  String get wiki_translating => '번역 중';

  @override
  String get wiki_back => '이전으로';

  @override
  String get wiki_readingTranslation => '번역문';

  @override
  String get wiki_readingOriginal => '원문';

  @override
  String get wiki_readingBilingual => '대역';

  @override
  String get wiki_bilingualUnavailable => '이 번역문에 대응되는 원문이 없어 번역문을 표시합니다';

  @override
  String get wiki_open => '열기';

  @override
  String get wiki_switchToOriginal => '원문으로 전환';

  @override
  String get wiki_switchToTranslation => '번역문으로 전환';

  @override
  String get wiki_retranslate => '다시 번역';

  @override
  String get wiki_onThisPage => '목차';

  @override
  String get wiki_overview => '개요';

  @override
  String get wiki_untranslated => '아직 번역되지 않음';

  @override
  String get wiki_autoTranslateTagsArticles => '태그 및 백과 자동 번역';

  @override
  String get wiki_readingContent => '읽기 내용';

  @override
  String get wiki_categoryGeneral => '일반';

  @override
  String get wiki_categoryArtist => '작가';

  @override
  String get wiki_categoryCopyright => '작품';

  @override
  String get wiki_categoryCharacter => '캐릭터';

  @override
  String get wiki_categoryMeta => '메타';

  @override
  String get wiki_categoryContributor => '기여자';

  @override
  String get wiki_categorySpecies => '종족';

  @override
  String get wiki_categoryLore => '설정';

  @override
  String get wiki_categoryLibrary => '로컬';

  @override
  String get wiki_addToBlock => '블록에 추가';

  @override
  String get wiki_forward => '앞으로';

  @override
  String get wiki_posts => '개 게시물';

  @override
  String get wiki_aliases => '별칭';

  @override
  String get wiki_relatedTitle => '함께 자주 쓰는 태그';

  @override
  String get wiki_relatedHint => '클릭하여 열기 · Shift+클릭으로 블록에 추가';

  @override
  String get wiki_inDirectory => '소속 디렉터리';

  @override
  String get wiki_noArticle => '위키 없음';

  @override
  String get wiki_moreCategories => '더 보기';

  @override
  String get wiki_shortcutsHint =>
      '단축키: / 검색 · ↑↓ 이동 · Enter 블록에 추가 · B 북마크 · Alt+←/→ 기록';

  @override
  String get toast_titleSuccess => '완료';

  @override
  String get toast_titleError => '작업 실패';

  @override
  String get toast_titleWarning => '참고하세요';

  @override
  String get toast_titleInfo => '알림';

  @override
  String get toast_titleProgress => '진행 중';

  @override
  String get tagExpansion_autoTranslateVisible => '보이는 태그 자동 번역';

  @override
  String get translationEditor_title => '번역 블록';

  @override
  String get translationEditor_source => '원문';

  @override
  String get translationEditor_sourcePrefix => '원';

  @override
  String get translationEditor_generation => '이미지 생성용';

  @override
  String get translationEditor_editable => '편집 가능';

  @override
  String get translationEditor_modified => '수정됨';

  @override
  String get translationEditor_edited => '편집됨';

  @override
  String get translationEditor_close => '닫기';

  @override
  String get translationEditor_save => '저장';

  @override
  String get translationEditor_delete => '블록 삭제';

  @override
  String get translationEditor_restore => '원문 텍스트로 복원';

  @override
  String get translationEditor_configure => '번역 모델 설정';

  @override
  String translationEditor_readingFieldTitle(Object language) {
    return '$language 읽기 텍스트';
  }

  @override
  String translationEditor_sourceWarning(Object language) {
    return '원문이 수정되었습니다. $language 동기화가 필요합니다';
  }

  @override
  String get translationEditor_editHint => '번역을 직접 편집했습니다. 원문 검토 상태는 유지됩니다';

  @override
  String get translationLanguage_chinese => '중국어';

  @override
  String get translationLanguage_english => '영어';

  @override
  String get translationLanguage_japanese => '일본어';

  @override
  String get translationLanguage_korean => '한국어';

  @override
  String get translationLanguage_traditionalChinese => '중국어 번체';

  @override
  String get modelTask_translateTitle => '원문 → 읽기 언어';

  @override
  String get modelTask_promptReverseTitle => '읽기 언어 → 원문';

  @override
  String get modelTask_tagTranslateTitle => '태그 이름 번역';

  @override
  String get modelTask_wikiTranslateTitle => '백과 문서 번역';

  @override
  String get modelTask_translateDescription =>
      '가중치, 그룹, 태그 의미를 유지하며 프롬프트와 블록을 번역합니다.';

  @override
  String get modelTask_promptReverseDescription =>
      '번역문에서 추가, 삭제, 수정한 내용을 원문에 반영한 뒤 검토할 수 있도록 돌려줍니다.';

  @override
  String get modelTask_tagTranslateDescription => '보이는 태그에 간결하고 정확한 이름을 붙입니다.';

  @override
  String get modelTask_wikiTranslateDescription =>
      '백과 문서를 번역하고 서식을 정리하며, 문맥에 맞춰 클릭할 태그를 고릅니다.';

  @override
  String get modelTask_connectionTest => '모델 연결 테스트';

  @override
  String get modelReasoning_serviceDefault => '서비스 기본값';

  @override
  String get modelReasoning_off => '끄기';

  @override
  String get modelReasoning_on => '켜기';

  @override
  String get modelReasoning_minimal => '최소';

  @override
  String get modelReasoning_low => '낮음';

  @override
  String get modelReasoning_medium => '보통';

  @override
  String get modelReasoning_high => '높음';

  @override
  String get modelReasoning_xhigh => '매우 높음';

  @override
  String get modelReasoning_max => '최대';

  @override
  String get modelProvider_custom => '사용자 지정 서비스';

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
  String get modelProvider_zai => 'Z.AI · 국제';

  @override
  String get modelProvider_zhipuCodingPlan => 'Zhipu Coding Plan';

  @override
  String get modelProvider_kimiCoding => 'Kimi Coding';

  @override
  String get modelProvider_moonshotInternational => 'Moonshot AI · 국제';

  @override
  String get modelProvider_minimaxChinaChat => 'MiniMax · 중국 OpenAI';

  @override
  String get modelProvider_minimaxChinaMessages => 'MiniMax · 중국 Anthropic';

  @override
  String get modelProvider_minimaxInternationalMessages =>
      'MiniMax · 국제 Anthropic';

  @override
  String get modelProvider_xiaomi => 'Xiaomi MiMo';

  @override
  String get modelProvider_antLing => 'Ant Ling';

  @override
  String get modelProvider_stepfunPlan => 'StepFun Step Plan';

  @override
  String get modelProvider_qwenTokenPlanChina => 'Qwen Token Plan · 중국';

  @override
  String get modelProvider_hintHuggingFace =>
      '추론 권한이 있는 Hugging Face 토큰을 사용하세요. 라우터 모델 ID는 직접 추가할 수 있습니다.';

  @override
  String get modelProvider_hintPlanKey =>
      '이 요금제의 API 키를 사용하세요. 사용 가능한 모델과 범위는 요금제가 반환하는 내용을 따릅니다.';

  @override
  String get modelProvider_hintInternationalEndpoint =>
      '국제 엔드포인트입니다. 국제 플랫폼의 API 키를 사용하세요.';

  @override
  String get modelProvider_hintRegionOpenAi =>
      '해당 지역의 API 키를 사용하세요. OpenAI Chat Completions 호환 주소가 미리 입력되어 있습니다.';

  @override
  String get modelProvider_hintRegionAnthropic =>
      '해당 지역의 API 키를 사용하세요. Anthropic Messages 호환 주소가 미리 입력되어 있습니다.';

  @override
  String get modelProvider_hintQwen =>
      '기본값은 베이징 리전입니다. 다른 리전은 해당 키를 사용하고 엔드포인트를 바꾸세요.';

  @override
  String get modelProvider_hintMinimax =>
      '기본값은 국제 종량제 엔드포인트입니다. 중국 플랫폼은 해당 키와 엔드포인트를 사용하세요.';

  @override
  String get modelProvider_hintMoonshot =>
      '기본값은 중국 플랫폼입니다. 국제 플랫폼은 해당 키와 엔드포인트를 사용하세요.';

  @override
  String get modelProvider_hintZhipu =>
      '기본값은 종량제 엔드포인트입니다. Coding Plan은 전용 주소를 사용합니다.';

  @override
  String get modelProvider_hintDoubao =>
      'Ark API 키를 사용하세요. 먼저 모델을 활성화하거나 추론 엔드포인트 ID를 추가하세요.';

  @override
  String get modelProvider_hintCustom =>
      '호환 서비스 주소와 키를 입력한 뒤 연결 정보에서 프로토콜을 선택하세요.';

  @override
  String get modelProvider_hintLocal => '먼저 로컬 서비스를 시작한 뒤 불러온 모델 목록을 읽으세요.';

  @override
  String get modelProvider_hintDefault =>
      '주소와 프로토콜이 미리 입력되어 있습니다. 키를 저장하면 모델을 고를 수 있습니다.';

  @override
  String get modelParams_temperatureRange => 'Temperature는 0에서 2 사이여야 합니다.';

  @override
  String get modelParams_topPRange => 'Top P는 0보다 크고 1 이하여야 합니다.';

  @override
  String get modelParams_maxOutputPositive => '최대 출력 토큰은 0보다 커야 합니다.';

  @override
  String get modelParams_anthropicTemperatureRange =>
      'Anthropic Temperature는 0에서 1 사이여야 합니다.';

  @override
  String get modelParams_anthropicSamplingConflict =>
      'Anthropic은 Temperature와 Top P 중 하나만 받습니다. 모델 매개변수를 확인하세요.';

  @override
  String modelParams_thinkingBudgetTooSmall(Object minimum) {
    return '최대 출력은 최소 사고 예산 $minimum보다 커야 합니다.';
  }

  @override
  String get modelOverrides_invalidHeaderName => '올바른 헤더 이름을 입력하세요';

  @override
  String get modelOverrides_invalidHeaderValue =>
      '헤더 값에는 줄바꿈이나 제어 문자를 넣을 수 없습니다';

  @override
  String get modelOverrides_emptyBodyField => '본문 필드 이름은 비워 둘 수 없습니다';

  @override
  String get modelOverrides_modelFromList => '모델 ID는 모델 목록에서 설정하세요';

  @override
  String get modelOverrides_streamMustBeFalse =>
      '이 연결은 비스트리밍 요청을 사용하므로 stream은 false여야 합니다';

  @override
  String get modelConfig_changedSaveAgain => '설정이 바뀌었습니다. 다시 저장하세요.';

  @override
  String get modelConfig_presetChanged => '선택한 프리셋이 바뀌었습니다. 다시 선택하세요.';

  @override
  String get modelConfig_serviceDisabled => '선택한 서비스가 꺼졌습니다. 다시 선택하세요.';

  @override
  String get modelConfig_modelChanged => '선택한 모델이 바뀌었습니다. 다시 선택하세요.';

  @override
  String get modelConfig_reasoningChanged =>
      '모델의 사고 단계가 바뀌었습니다. 다시 선택하거나 모델을 따르세요.';

  @override
  String get modelConfig_presetIdRequired => '프리셋 ID는 비워 둘 수 없습니다.';

  @override
  String get modelConfig_saveBuiltinAsCustom =>
      '기본 제공 프리셋을 사용자 지정 프리셋으로 저장하세요.';

  @override
  String get modelConfig_namePromptRequired => '이름과 프롬프트는 비워 둘 수 없습니다.';

  @override
  String get modelConfig_builtinNotDeletable => '기본 제공 규칙은 삭제할 수 없습니다.';

  @override
  String get modelConfig_pasteFullJson => '전체 모델 설정 JSON을 붙여넣으세요.';

  @override
  String get modelConfig_builtinNotOverwritable =>
      '기본 제공 프리셋은 덮어쓸 수 없습니다. 사용자 지정 프리셋으로 복사하세요.';

  @override
  String get modelConfig_invalidProvider => '서비스 ID, 이름 또는 주소가 올바르지 않습니다.';

  @override
  String get modelConfig_missingProvider => '모델의 서비스가 존재하지 않습니다.';

  @override
  String get modelConfig_invalidCustomPreset =>
      '사용자 지정 프리셋의 ID, 이름 또는 프롬프트가 올바르지 않습니다.';

  @override
  String get modelConfig_changedImportAgain => '설정이 바뀌었습니다. 다시 가져오세요.';

  @override
  String get modelHealth_unverified =>
      '아직 연결을 확인하지 않았습니다. 모델을 사용하거나 \"연결 테스트\"를 하면 업데이트됩니다.';

  @override
  String get modelHealth_healthy => '마지막 요청이 성공했습니다';

  @override
  String get modelHealth_limited =>
      '연결은 되지만 마지막 요청이 속도 제한(HTTP 429)에 걸렸습니다. 나중에 다시 시도하거나 할당량을 확인하세요';

  @override
  String get modelHealth_authentication => '인증에 실패했습니다. API 키를 확인하세요';

  @override
  String get modelHealth_permission => '접근이 거부되었습니다. 서비스 권한을 확인하세요';

  @override
  String get modelHealth_timeout => '마지막 요청 시간이 초과되었습니다';

  @override
  String get modelHealth_network => '마지막 요청이 서비스에 연결하지 못했습니다';

  @override
  String get modelHealth_invalidResponse =>
      '마지막 응답이 올바르지 않습니다. 자세한 내용은 요청 기록을 확인하세요';

  @override
  String get modelHealth_failed => '마지막 요청이 실패했습니다';

  @override
  String modelHealth_failedStatus(Object status) {
    return '마지막 요청이 실패했습니다(HTTP $status)';
  }

  @override
  String get modelRequest_statusPending => '대기 중';

  @override
  String get modelRequest_statusRunning => '요청 중';

  @override
  String get modelRequest_statusSuccess => '성공';

  @override
  String get modelRequest_statusFailed => '실패';

  @override
  String get modelRequest_statusCancelled => '취소됨';

  @override
  String get modelRequest_fieldTime => '시간';

  @override
  String get modelRequest_fieldMethod => '메서드';

  @override
  String get modelRequest_fieldUrl => 'URL';

  @override
  String get modelRequest_fieldRequestHeaders => '요청 헤더';

  @override
  String get modelRequest_fieldBody => '본문';

  @override
  String get modelRequest_fieldStatusCode => '상태 코드';

  @override
  String get modelRequest_fieldResponseHeaders => '응답 헤더';

  @override
  String get modelRequest_fieldError => '오류';

  @override
  String get modelRequest_fieldInterface => '인터페이스';

  @override
  String get modelRequest_fieldProvider => '서비스';

  @override
  String get modelRequest_fieldModel => '모델';

  @override
  String get modelRequest_fieldProtocol => '프로토콜';

  @override
  String get modelRequest_fieldStatus => '상태';

  @override
  String get modelRequest_fieldElapsed => '소요 시간(ms)';

  @override
  String get modelRequest_fieldAttempts => '시도 횟수';

  @override
  String get modelRequest_fieldHttpRequests => 'HTTP 요청 수';

  @override
  String get modelRequest_fieldParameters => '적용된 매개변수';

  @override
  String get modelRequest_redacted => '[가림 처리됨]';

  @override
  String get modelRequest_emptyResponse => '모델이 빈 내용을 반환했습니다.';

  @override
  String get modelService_testFieldsIncomplete => '테스트 응답에 필드가 빠져 있습니다.';

  @override
  String get modelService_testFieldsInvalid => '테스트 응답의 필드가 올바르지 않습니다.';

  @override
  String get modelService_testGroupsInvalid => '테스트 응답의 그룹이 올바르지 않습니다.';

  @override
  String get modelService_testSourceEmpty => '테스트 응답의 원문이 비어 있습니다.';

  @override
  String get modelService_conversionCancelled => '변환을 취소했습니다';

  @override
  String get modelService_chooseInterfaceModel =>
      '먼저 설정 → 모델 및 API → 인터페이스에서 서비스와 모델을 선택하세요.';

  @override
  String get modelService_enableServiceModel =>
      '설정에서 서비스를 켠 다음 모델을 가져오거나 추가해 선택하세요.';

  @override
  String get modelSettings_keepEditsTitle => '현재 편집 내용을 유지하시겠습니까?';

  @override
  String get modelSettings_keepEditsBody =>
      '변경 사항을 아직 저장하지 않았습니다. 전환하기 전에 저장하시겠습니까?';

  @override
  String get modelSettings_discard => '버리기';

  @override
  String get modelSettings_saveAndSwitch => '저장 후 전환';

  @override
  String get modelSettings_addProvider => '서비스 추가';

  @override
  String modelSettings_deleteProviderTitle(Object name) {
    return '$name을(를) 삭제하시겠습니까?';
  }

  @override
  String get modelSettings_deleteProviderBody => '이 서비스의 연결, 키, 선택한 모델이 삭제됩니다.';

  @override
  String modelSettings_deleteProviderBindings(Object count) {
    return '인터페이스 모델 연결 $count개가 해제되며, 프리셋은 유지됩니다.';
  }

  @override
  String modelSettings_deletePresetTitle(Object name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get modelSettings_deletePresetBody =>
      '이 프리셋을 사용하는 인터페이스는 기본 제공 프리셋으로 돌아갑니다. 모델 연결은 유지됩니다.';

  @override
  String get modelSettings_configCopied => '키, 사용자 지정 헤더, 본문을 제외하고 설정을 복사했습니다.';

  @override
  String get modelSettings_importConfig => '설정 가져오기';

  @override
  String get modelSettings_importConfigHint =>
      '내보낸 설정을 붙여넣으세요. 현재 설정은 먼저 백업되며, 키는 계속 따로 저장됩니다.';

  @override
  String get modelSettings_configJson => '설정 JSON';

  @override
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  ) {
    return '서비스 $providers개, 모델 $models개, 사용자 지정 프리셋 $presets개를 가져옵니다.';
  }

  @override
  String get modelSettings_importMissingProviders => '서비스 또는 모델 설정이 없습니다.';

  @override
  String get modelSettings_checkConfig => '설정 확인';

  @override
  String get modelSettings_importAndReplace => '가져와서 교체';

  @override
  String get modelSettings_configImported => '설정을 가져왔습니다';

  @override
  String get modelSettings_description => '서비스 연결과 번역 환경 설정을 관리합니다.';

  @override
  String get modelSettings_configMenu => '설정';

  @override
  String get modelSettings_copyConfig => '설정 복사';

  @override
  String get modelSettings_tabProviders => '서비스';

  @override
  String get modelSettings_tabInterfaces => '인터페이스';

  @override
  String get modelSettings_tabPresets => '프리셋 및 프롬프트';

  @override
  String get modelSettings_tabRequests => '요청 기록';

  @override
  String modelSettings_providersCount(Object count) {
    return '서비스 · $count';
  }

  @override
  String modelSettings_providerModelCount(Object count) {
    return '모델 $count개';
  }

  @override
  String get modelSettings_providerDisabledSuffix => ' · 꺼짐';

  @override
  String get modelSettings_emptyTitle => '첫 번째 모델 서비스를 추가하세요';

  @override
  String get modelSettings_emptyBody => '자주 쓰는 서비스를 고르거나 사용자 지정 엔드포인트를 연결하세요.';

  @override
  String get modelSettings_customService => '사용자 지정 서비스';

  @override
  String get modelSettings_notConfigured => '설정 안 됨';

  @override
  String get modelSettings_preset => '프리셋';

  @override
  String get modelSettings_presetBuiltin => '기본 제공';

  @override
  String get modelSettings_presetUser => '사용자';

  @override
  String get modelSettings_deletePreset => '프리셋 삭제';

  @override
  String modelSettings_presetCopyName(Object title, Object number) {
    return '$title($number)';
  }

  @override
  String get modelSettings_recentRequests => '최근 요청';

  @override
  String get modelSettings_recentRequestsHint =>
      '이번 세션의 최근 100건 · 인증 정보를 가린 전체 요청과 응답';

  @override
  String get modelSettings_clearRequests => '지우기';

  @override
  String get modelSettings_requestsEmpty => '번역하거나 모델을 테스트하면 요청이 여기에 표시됩니다.';

  @override
  String get modelSettings_interfaceChangedElsewhere =>
      '인터페이스 설정이 다른 곳에서 바뀌었습니다. 다시 열어 편집하세요.';

  @override
  String get modelSettings_configSaved => '설정을 저장했습니다';

  @override
  String get modelSettings_viewBuiltinRules => '기본 제공 규칙 보기';

  @override
  String get modelSettings_viewEditPreset => '프리셋 보기 및 편집';

  @override
  String get modelSettings_restoreBuiltinPreset => '기본 제공 프리셋 복원';

  @override
  String get modelSettings_followUiLanguage => '인터페이스 언어 따르기';

  @override
  String get modelSettings_providerAndModel => '서비스 및 모델';

  @override
  String get modelSettings_providerAndModelHelp => '켜져 있는 서비스에서 선택한 모델만 표시됩니다';

  @override
  String get modelSettings_chooseProviderModel => '서비스와 모델 선택';

  @override
  String get modelSettings_reasoning => '사고';

  @override
  String get modelSettings_reasoningHelp =>
      '단순 번역에는 보통 사고가 필요 없습니다. 태그 지정, 의미 분류 같은 작업에는 모델이 지원하는 가장 낮은 사고 단계를 사용하세요.';

  @override
  String get modelSettings_reasoningHelpLabel => '사고 단계 안내';

  @override
  String get modelSettings_usePreset => '프리셋';

  @override
  String get modelSettings_outputLanguage => '출력 언어';

  @override
  String get modelSettings_englishPrompt => '영어 생성 프롬프트';

  @override
  String get modelSettings_englishPromptHelp =>
      '원문을 기준으로 수정 내용을 반영해 영어 생성 프롬프트를 출력합니다.';

  @override
  String get modelSettings_targetLanguage => '대상 언어';

  @override
  String get modelSettings_effective => '적용 중';

  @override
  String get modelSettings_noModelSelected => '선택한 사용 가능 모델이 없습니다';

  @override
  String modelSettings_reasoningSummaryInterface(Object level) {
    return '사고: $level(이 인터페이스)';
  }

  @override
  String modelSettings_reasoningSummaryModel(Object level) {
    return '사고: $level(모델 따름)';
  }

  @override
  String get modelSettings_promptBlocksHint =>
      '번역이 필요 없을 때는 프롬프트를 블록으로 나눠 블록 기능으로 자유롭게 배치할 수도 있습니다.';

  @override
  String get modelSettings_wikiFormatHint =>
      '번역이 필요 없을 때도 서식을 정리하고 관련 태그를 연결할 수 있습니다.';

  @override
  String get modelSettings_unsavedChanges => '저장하지 않은 변경 사항';

  @override
  String get modelSettings_testPreset => '프리셋 테스트';

  @override
  String get modelSettings_tabModelPreset => '모델 및 프리셋';

  @override
  String get modelSettings_tabPromptOutput => '프롬프트 및 출력';

  @override
  String get modelSettings_translationStrategy => '번역 전략';

  @override
  String get modelSettings_editPreset => '프리셋 편집';

  @override
  String get modelSettings_outputContract => '앱 출력 규약';

  @override
  String get modelSettings_outputContractHint => '반환 필드와 검증 규칙은 앱에서 관리합니다';

  @override
  String get modelSettings_testResult => '테스트 결과';

  @override
  String get modelRequest_detailsRequests => '요청';

  @override
  String get modelRequest_detailsIndex => '번호';

  @override
  String get modelRequest_detailsResponses => '응답';

  @override
  String get modelRequest_detailsOutput => '추출 결과';

  @override
  String get modelRequest_detailsTitle => '요청 기록';

  @override
  String get modelRequest_detailsCopied => '복사했습니다';

  @override
  String get modelRequest_detailsCopyPage => '이 페이지 복사';

  @override
  String get modelRequest_detailsOverview => '개요';

  @override
  String get modelRequest_detailsMissing => '이 기록은 지워졌거나 최근 100건보다 오래되었습니다.';

  @override
  String get modelPreset_changedElsewhere => '프리셋이 다른 곳에서 바뀌었습니다. 다시 열어 편집하세요.';

  @override
  String get modelPreset_interfacePresetChanged =>
      '인터페이스의 프리셋이 다른 곳에서 바뀌었습니다. 다시 열어 새로 만드세요.';

  @override
  String get modelPreset_builtinReadOnly => '기본 제공 · 읽기 전용';

  @override
  String get modelPreset_newInterfacePreset => '새 인터페이스 프리셋';

  @override
  String get modelPreset_tabPrompt => '프롬프트';

  @override
  String get modelPreset_tabOutputContract => '출력 규약';

  @override
  String get modelPreset_name => '프리셋 이름';

  @override
  String get modelPreset_nameRequired => '이름을 입력하세요';

  @override
  String get modelPreset_behavior => '동작 및 번역 전략';

  @override
  String get modelPreset_builtinLocked =>
      '기본 제공 규칙은 잠겨 있습니다. 인터페이스 프리셋을 만들어 나만의 번역 환경 설정을 편집하세요.';

  @override
  String get modelPreset_editHint => '여기서 번역 환경 설정을 편집하세요. 응답 형식은 앱에서 관리합니다.';

  @override
  String get modelPreset_strategyHint => '번역 전략 입력';

  @override
  String get modelPreset_promptRequired => '프롬프트는 비워 둘 수 없습니다';

  @override
  String get modelPreset_restoreStrategy => '기본 제공 전략 복원';

  @override
  String get modelPreset_outputContractNote =>
      '이 부분은 번역 결과를 다시 반영하고 표시할 수 있게 해 주며, 앱에서 관리합니다.';

  @override
  String get modelPreset_save => '프리셋 저장';

  @override
  String get modelReasoning_unsupported => '지원 안 함';

  @override
  String get modelReasoning_followModel => '모델 따르기';

  @override
  String modelReasoning_followModelLevel(Object level) {
    return '모델 따르기($level)';
  }

  @override
  String get modelReasoning_notAdjustable => '이 모델은 사고 조절을 지원하지 않습니다';

  @override
  String get modelReasoning_strength => '사고 강도';

  @override
  String modelReasoning_modelDefault(Object level) {
    return '모델 기본값: $level';
  }

  @override
  String get modelReasoning_levelsUnknown =>
      '사용 가능한 단계가 아직 확인되지 않았습니다\n서비스의 모델 설정에서 지정하세요';

  @override
  String modelReasoning_strengthValue(Object level) {
    return '사고 강도: $level';
  }

  @override
  String get modelProvider_customEndpoint => '사용자 지정 엔드포인트';

  @override
  String get modelProvider_pickerTitle => '서비스 선택';

  @override
  String get modelProvider_pickerSearch => '업체, 플랫폼, 로컬 서비스 검색';

  @override
  String get modelProvider_pickerEmpty => '일치하는 서비스가 없습니다';

  @override
  String get modelProvider_groupApiKey => 'API 키 연결';

  @override
  String get modelProvider_groupLocal => '로컬 서비스';

  @override
  String get modelProvider_enterCompatibleAddress => '호환 엔드포인트 주소를 입력하세요';

  @override
  String get modelConnection_provider => '서비스';

  @override
  String get modelConnection_name => '이름';

  @override
  String get modelConnection_nameExample => '예: 내 중계 서버';

  @override
  String get modelConnection_protocol => '프로토콜';

  @override
  String get modelConnection_address => '엔드포인트 주소';

  @override
  String get modelConnection_apiKey => 'API 키';

  @override
  String modelControls_decrease(Object label, Object step, Object unit) {
    return '$label 줄이기($step $unit)';
  }

  @override
  String modelControls_increase(Object label, Object step, Object unit) {
    return '$label 늘리기($step $unit)';
  }

  @override
  String get modelControls_retryOff => '끄기';

  @override
  String modelControls_retryTimes(Object count) {
    return '$count회';
  }

  @override
  String get settings_positiveIntegerRequired => '0보다 큰 정수를 입력하세요';

  @override
  String get modelSettings_testingPreset => '프리셋 테스트 중';

  @override
  String modelHealth_lastUpdated(Object time) {
    return '마지막 업데이트: $time';
  }

  @override
  String get modelSettings_backToEditing => '편집으로 돌아가기';

  @override
  String modelService_loadOverridesFailed(Object error) {
    return '사용자 지정 요청 설정을 읽지 못했습니다: $error';
  }

  @override
  String get modelService_timeoutRange => '요청 시간 제한은 10~600초 사이여야 합니다.';

  @override
  String get modelService_concurrencyRange => '최대 동시 요청 수는 1~20 사이여야 합니다.';

  @override
  String get modelService_nameRequired => '서비스 이름을 입력하세요.';

  @override
  String get modelService_invalidUrl =>
      '엔드포인트는 완전한 http:// 또는 https:// URL이어야 합니다.';

  @override
  String get modelService_contextPositive => '컨텍스트 창은 0보다 커야 합니다.';

  @override
  String get modelService_readingCatalog => '모델 목록 읽는 중…';

  @override
  String modelService_catalogReturned(Object count) {
    return '서비스가 모델 $count개를 반환했습니다. 사용할 모델을 선택하세요.';
  }

  @override
  String modelService_catalogUnavailable(Object error) {
    return '모델 목록을 사용할 수 없습니다: $error. 모델 ID를 직접 추가할 수 있습니다.';
  }

  @override
  String modelService_catalogCached(Object count) {
    return '지난번에 가져온 모델 $count개를 불러왔습니다. \"목록 가져오기\"를 클릭하면 새로 고칩니다.';
  }

  @override
  String get modelService_catalogCacheFailed =>
      '모델 목록을 가져왔지만 로컬 캐시를 저장하지 못했습니다. 다음에 다시 가져오세요.';

  @override
  String get modelService_selectModelFirst => '먼저 모델을 선택하세요.';

  @override
  String get modelService_testingModel => '모델 요청 테스트 중…';

  @override
  String modelService_testSucceeded(Object reply) {
    return '모델 요청 성공: $reply';
  }

  @override
  String modelService_testFailed(Object error) {
    return '모델 요청 실패: $error';
  }

  @override
  String modelService_tokensPositive(Object name) {
    return '\"$name\" 모델의 토큰 수는 0보다 커야 합니다.';
  }

  @override
  String get modelService_changedElsewhere =>
      '서비스 설정이 다른 곳에서 바뀌었습니다. 다시 열어 편집하세요.';

  @override
  String get modelService_overridesChangedElsewhere =>
      '모델 요청 설정이 다른 곳에서 바뀌었습니다. 다시 열어 편집하세요.';

  @override
  String modelService_saveFailed(Object error) {
    return '저장하지 못했습니다: $error';
  }

  @override
  String get modelService_keyHintNew => '키를 입력하세요. 로컬 서비스는 비워 둘 수 있습니다';

  @override
  String get modelService_keyHintVendor => '이 서비스의 키를 입력하세요';

  @override
  String get modelService_keyHintSaved => '저장됨. 비워 두면 그대로 유지됩니다';

  @override
  String modelService_enabledModels(Object count) {
    return '켜진 모델 $count개';
  }

  @override
  String get modelService_pendingSave => '저장 안 됨';

  @override
  String get modelService_saved => '저장됨';

  @override
  String get modelService_enable => '사용';

  @override
  String get modelService_testConnection => '연결 테스트';

  @override
  String get modelService_delete => '서비스 삭제';

  @override
  String get modelService_save => '서비스 저장';

  @override
  String get modelService_saving => '서비스 저장 중';

  @override
  String get modelService_notConfigured => '설정 안 됨';

  @override
  String get modelService_optional => '선택 사항';

  @override
  String get modelService_editConnection => '편집';

  @override
  String get modelService_collapse => '접기';

  @override
  String get modelService_connectionSettings => '연결 설정';

  @override
  String get modelService_dragToReorder => '끌어서 모델 순서 변경';

  @override
  String get modelService_capacityTooltip => '컨텍스트 / 최대 출력. 고급에서 조정하세요';

  @override
  String get modelService_advanced => '고급';

  @override
  String modelService_removeModel(Object name) {
    return '$name 모델 제거';
  }

  @override
  String get modelService_linkedInterfaces => '연결된 인터페이스';

  @override
  String get modelService_noLinkedInterfaces => '아직 연결된 인터페이스가 없습니다';

  @override
  String get modelService_advancedSettings => '고급 설정';

  @override
  String get modelService_requestTimeout => '요청 시간 제한';

  @override
  String get modelService_requestTimeoutHelp => '요청 한 번의 최대 대기 시간';

  @override
  String get modelService_seconds => '초';

  @override
  String get modelService_maxConcurrency => '최대 동시 요청 수';

  @override
  String get modelService_maxConcurrencyHelp => '이 서비스가 한 번에 처리하는 요청 수';

  @override
  String get modelService_countUnit => '개';

  @override
  String get modelService_retry => '실패 시 다시 시도';

  @override
  String get modelService_retryHelp => '연결에 실패하거나 서비스가 바쁠 때 다시 시도합니다';

  @override
  String get modelService_searchModelId => '모델 ID 검색…';

  @override
  String get modelService_serviceModels => '사용 가능한 모델';

  @override
  String get modelService_fetchList => '목록 가져오기';

  @override
  String get modelService_catalogEmpty =>
      '\"목록 가져오기\"를 클릭해 이 서비스의 모델을 읽거나,\n오른쪽에서 모델 ID를 추가하세요.';

  @override
  String get modelService_noMatchingModels => '일치하는 모델이 없습니다';

  @override
  String get modelService_catalogLimitTooltip => '카탈로그 한도: 컨텍스트 / 최대 출력';

  @override
  String get modelService_searchAddedModels => '추가한 모델 검색…';

  @override
  String get modelService_modelSettings => '모델 설정';

  @override
  String get modelService_addedEmpty => '왼쪽에서 모델을 선택하거나 아래에서 추가하세요';

  @override
  String get modelService_customModelId => '사용자 지정 모델 ID';

  @override
  String get modelService_customModelHelp => '카탈로그에 없는 모델을 추가합니다';

  @override
  String get modelService_addCustomModel => '사용자 지정 모델 추가';

  @override
  String get modelCard_positiveInteger => '양의 정수를 입력하세요';

  @override
  String modelCard_catalogLimit(Object limit) {
    return '카탈로그 한도 $limit';
  }

  @override
  String get modelCard_outputExceedsContext => '출력은 컨텍스트 창을 넘을 수 없습니다';

  @override
  String get modelCard_contextWindow => '컨텍스트 창';

  @override
  String get modelCard_maxOutput => '최대 출력';

  @override
  String get modelCard_unlabeled => '표기 없음';

  @override
  String get modelCard_protocolStandard => '표준';

  @override
  String get modelCard_protocolAdaptive => '적응형';

  @override
  String get modelCard_default => '기본값';

  @override
  String get modelCard_thinkingLevels => '사고 단계';

  @override
  String get modelCard_thinkingLevelsUnlisted =>
      '카탈로그에 표기되지 않았습니다. 직접 켤 수 있습니다';

  @override
  String get modelCard_thinkingLevelsFromCatalog =>
      '지원 단계는 로컬 카탈로그 기준으로 선택했습니다. 실제 API에 맞게 조정하세요.';

  @override
  String get modelCard_thinkingProtocol => '사고 프로토콜';

  @override
  String get modelCard_defaultThinkingLevel => '기본 단계';

  @override
  String get modelCard_alias => '별칭';

  @override
  String get modelCard_aliasHelp => '모델 이름이 표시되는 곳에 쓰이며, 요청에는 계속 모델 ID를 사용합니다.';

  @override
  String get modelCard_aliasExample => '예: fast';

  @override
  String get modelCard_capabilities => '기능';

  @override
  String get modelCard_images => '이미지';

  @override
  String get modelCard_nativeSearch => '네이티브 웹 검색';

  @override
  String get modelCard_nativeSearchHelp =>
      '앱은 이 연결에서 아직 네이티브 검색을 사용하지 않습니다. 업체나 다른 API에 검색 기능이 없다는 뜻은 아닙니다.';

  @override
  String get modelOverrides_duplicateHeader => '중복된 헤더 이름';

  @override
  String get modelOverrides_fieldNameRequired => '필드 이름을 입력하세요';

  @override
  String get modelOverrides_duplicateField => '중복된 필드 이름';

  @override
  String get modelOverrides_invalidJson => '올바른 JSON 값을 입력하세요';

  @override
  String get modelOverrides_customBody => '사용자 지정 본문';

  @override
  String get modelOverrides_customHeaders => '사용자 지정 헤더';

  @override
  String get modelOverrides_fieldName => '필드 이름';

  @override
  String get modelOverrides_headerName => '헤더 이름';

  @override
  String get modelOverrides_valueJson => '값(JSON)';

  @override
  String get modelOverrides_value => '값';

  @override
  String get modelOverrides_removeItem => '항목 제거';

  @override
  String get modelOverrides_body => '요청 본문';

  @override
  String get modelOverrides_headers => '요청 헤더';

  @override
  String modelOverrides_itemCount(Object count) {
    return '$count개 항목';
  }

  @override
  String get modelOverrides_valueTypes => '문자열, 숫자, 불리언, 배열, 객체를 지원합니다';

  @override
  String get modelOverrides_addBodyField => '본문 필드 추가';

  @override
  String get modelOverrides_addHeader => '헤더 추가';

  @override
  String get promptTranslation_translating => '번역 중';

  @override
  String get promptTranslation_needsModel => '번역 · 먼저 모델을 설정하세요';

  @override
  String promptTranslation_withRoute(Object provider, Object model) {
    return '번역 · $provider / $model';
  }

  @override
  String get promptTranslation_actions => '번역 작업';

  @override
  String get promptTranslation_promptChanged => '프롬프트가 바뀌어 새 편집 내용을 덮어쓰지 않았습니다';

  @override
  String get promptTranslation_nothingToTranslate => '번역할 일반 텍스트가 없습니다';

  @override
  String promptTranslation_failed(Object error) {
    return '번역하지 못했습니다: $error';
  }

  @override
  String get promptTranslation_setupTitle => '먼저 번역 모델을 설정하세요';

  @override
  String get promptTranslation_setupBody =>
      '번역하려면 서비스와 모델을 명시적으로 선택해야 합니다. 설정 → 연동 → 모델 및 API에서 서비스를 추가하고 모델 목록을 가져온 뒤, 프롬프트 번역에 쓸 모델을 고르세요.';

  @override
  String get promptTranslation_later => '나중에';

  @override
  String get promptTranslation_openSettings => '설정 열기';

  @override
  String get promptTranslation_toolTitle => '번역';

  @override
  String get promptTranslation_noModel => '설정된 모델 없음';

  @override
  String get promptTranslation_configureModel => '번역 모델 설정';

  @override
  String get promptTranslation_translateNew => '새 내용 번역';

  @override
  String get promptTranslation_undoRestore => '복원을 취소하고 번역 블록 되돌리기';

  @override
  String get promptTranslation_restoreAll => '모든 번역 블록을 원문 텍스트로 복원';

  @override
  String get promptTranslation_tutorial => '사용 방법';

  @override
  String get promptTranslation_guideBack => '작업으로 돌아가기';

  @override
  String get promptTranslation_guideMiddleTitle => '블록 가운데 버튼 클릭';

  @override
  String get promptTranslation_guideMiddleText => '원문과 번역문 전환';

  @override
  String get promptTranslation_guideSourceTitle => '원문 왼쪽 클릭';

  @override
  String get promptTranslation_guideSourceText => '커서를 놓고 바로 편집';

  @override
  String get promptTranslation_guideReadingTitle => '번역문 왼쪽 클릭';

  @override
  String get promptTranslation_guideReadingText => '블록 편집기 열기';

  @override
  String get promptTranslation_guideCtrlTitle => 'Ctrl + 클릭 / 드래그 선택';

  @override
  String get promptTranslation_guideCtrlText => '편집기에서 태그 검색 / 관련 태그 찾기';

  @override
  String get promptTranslation_guideConvertTitle => '↑ 번역문을 원문으로';

  @override
  String get promptTranslation_guideConvertText => '↓ 원문을 번역문으로, 저장 전에 검토';

  @override
  String get promptTranslation_guideRestoreTitle => '그룹 전체 표시 전환';

  @override
  String get promptTranslation_guideRestoreText => '번역 메뉴에서 원문 / 번역을 모두 전환';

  @override
  String get promptTranslation_middleButton => '마우스 가운데 버튼';

  @override
  String get promptTranslation_leftButton => '마우스 왼쪽 버튼';

  @override
  String get promptTranslation_blockShowingOriginal => '번역 블록, 원문 표시 중';

  @override
  String get promptTranslation_blockShowingReading => '번역 블록, 번역문 표시 중';

  @override
  String get promptTranslation_blockNeedsReview => '원문 변경됨 · 번역 업데이트 필요';

  @override
  String get promptTranslation_badgeTooltip => '원문이 바뀌었습니다. 번역을 동기화해야 합니다';

  @override
  String get promptTranslation_sourceChanged => '원문이 바뀌었습니다. 번역 블록을 다시 여세요';

  @override
  String promptTranslation_retranslateFailed(Object error) {
    return '다시 번역하지 못했습니다: $error';
  }

  @override
  String get promptTranslation_draftChanged =>
      '내용이 바뀌었습니다. 다시 변환하세요. 새 초안은 유지됩니다.';

  @override
  String promptTranslation_convertFailed(Object error) {
    return '변환하지 못했습니다. 초안은 유지됩니다: $error';
  }

  @override
  String get promptTranslation_invalidResultFormat =>
      '변환 결과 형식이 올바르지 않습니다. 초안은 유지됩니다';

  @override
  String get promptTranslation_noValidText =>
      '모델이 유효한 텍스트를 반환하지 않았습니다. 초안은 유지됩니다';

  @override
  String get promptTranslation_invalidResultContent =>
      '변환 결과에 잘못된 서식이 있습니다. 초안은 유지됩니다';

  @override
  String get promptTranslation_incompleteStructure =>
      '변환 결과의 가중치나 그룹이 완전하지 않습니다. 초안은 유지됩니다';

  @override
  String get promptTranslation_inputRequired => '먼저 변환할 내용을 입력하세요';

  @override
  String get wiki_configureTagModel => '먼저 모델 및 API에서 사용할 태그 번역 모델을 설정하세요.';

  @override
  String blockOrganizer_replaceMoveBody(Object count) {
    return '대상에 같은 소스의 사본이 이미 $count개 있습니다. 교체하면 소스는 라이브러리에서 숨겨지며, 프롬프트에 이미 삽입된 인스턴스는 원래 블록을 계속 참조할 수 있습니다.';
  }

  @override
  String get blockLibrary_changedSelectAgain =>
      '블록 라이브러리가 바뀌었습니다. 다시 선택한 뒤 시도하세요.';

  @override
  String get blockLibrary_hiddenSource => '숨겨진 블록은 정리할 수 없습니다';

  @override
  String get blockLibrary_sameSourceSelected =>
      '선택 항목에 같은 소스의 사본이 있습니다. 따로 정리하세요';

  @override
  String get blockLibrary_sameSourceExists => '같은 소스의 사본이 이미 있습니다. 교체를 확인하세요';

  @override
  String get blockLibrary_collectionMissing => '컬렉션이 존재하지 않습니다';

  @override
  String get blockAppearance_classic => '기본';

  @override
  String get blockAppearance_stripes => '가는 줄무늬';

  @override
  String get blockAppearance_dots => '물방울';

  @override
  String get blockAppearance_solid => '단색';

  @override
  String get blockAppearance_gradient => '그라데이션';

  @override
  String get blockAppearance_translation => '번역';

  @override
  String get opusUsage_exhausted => '무료 계정 할당량을 모두 사용했습니다. V5 생성은 Anlas로 과금됩니다';

  @override
  String opusUsage_remaining(Object percent) {
    return '무료 계정 할당량 남음: $percent%';
  }

  @override
  String opusUsage_recharging(Object time) {
    return '충전 중: 다음 +1%까지 $time';
  }

  @override
  String get opusUsage_notRecharging => '충전하지 않음(할당량이 기준값보다 많거나 모두 사용함)';

  @override
  String get opusUsage_clickToRefresh => '클릭하여 새로 고침';

  @override
  String opusUsage_hoursMinutes(Object hours, Object minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String opusUsage_hours(Object hours) {
    return '$hours시간';
  }

  @override
  String opusUsage_minutesSeconds(Object minutes, Object seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String opusUsage_minutes(Object minutes) {
    return '$minutes분';
  }

  @override
  String opusUsage_seconds(Object seconds) {
    return '$seconds초';
  }

  @override
  String get metadataImport_noCharactersReplaceClears =>
      '캐릭터 데이터가 없습니다. 교체하면 현재 캐릭터가 지워집니다';

  @override
  String get metadataImport_replaceCharacters => '캐릭터 교체';

  @override
  String get metadataImport_appendCharacters => '캐릭터 추가';

  @override
  String get drop_dragToShare => '끌어서 공유';

  @override
  String promptSyntax_weightTooLarge(Object value) {
    return '숫자 가중치가 너무 큽니다: $value::';
  }

  @override
  String promptSyntax_spaceBeforeColons(Object value) {
    return '가중치와 :: 사이에는 공백을 넣을 수 없습니다: $value ::';
  }

  @override
  String promptSyntax_weightAfterColons(Object value) {
    return '숫자 가중치는 :: 앞에 써야 합니다: ::$value';
  }

  @override
  String get update_errorInAppUnsupported => '이 버전은 앱 내 자동 업데이트를 지원하지 않습니다';

  @override
  String get update_errorNoInstallablePackage =>
      '자동으로 설치할 수 있는 업데이트 패키지를 찾지 못했습니다';

  @override
  String get update_errorMissingSha256 => '업데이트 패키지에 SHA256 체크섬이 없습니다';

  @override
  String get update_errorDiskFull => '업데이트 패키지를 저장할 디스크 공간이 부족합니다';

  @override
  String get update_errorWriteFailed => '업데이트 패키지를 쓰지 못했습니다';

  @override
  String get update_errorDownloadFailed => '업데이트 패키지를 다운로드하지 못했습니다';

  @override
  String get update_errorSizeMismatch => '업데이트 패키지 크기 확인에 실패했습니다';

  @override
  String get update_errorChecksumMismatch => '업데이트 패키지 체크섬 확인에 실패했습니다';

  @override
  String get update_errorResumeRejected => '서버가 업데이트 다운로드 이어받기를 거부했습니다';

  @override
  String get update_errorEmptyResponse => '업데이트 서버가 빈 응답을 반환했습니다';

  @override
  String get update_errorPlatformUnsupported => '이 플랫폼에서는 앱 내 업데이트를 지원하지 않습니다';

  @override
  String get update_errorPackageRemoved => '업데이트 패키지가 정리되었습니다. 다시 다운로드하세요';

  @override
  String get update_errorPackageCorrupted => '업데이트 패키지가 손상되었습니다. 다시 다운로드하세요';

  @override
  String get update_errorLaunchFailed => '업데이트 프로그램을 시작하지 못했습니다';

  @override
  String get update_errorCheckFailed => '업데이트를 확인하지 못했습니다';

  @override
  String get update_errorCheckUnknown => '업데이트를 확인하는 중 알 수 없는 오류가 발생했습니다';

  @override
  String update_errorLogPath(Object path) {
    return '로그: $path';
  }

  @override
  String get update_errorInstallFailed => '업데이트를 설치하지 못했습니다';

  @override
  String get update_errorInstallFailedSeeLog =>
      '업데이트를 설치하지 못했습니다. 업데이트 로그를 확인하세요';

  @override
  String get auth_tokenEmpty => '토큰이 비어 있어 확인할 수 없습니다';

  @override
  String get auth_tokenFormatInvalid => '토큰 형식이 올바르지 않습니다';

  @override
  String get auth_tokenInvalidOrExpired =>
      '토큰이 유효하지 않거나 만료되었습니다. 올바른지 확인하세요. Persistent 토큰은 pst-로 시작합니다.';

  @override
  String get auth_tokenMustStartPst => '토큰 형식이 올바르지 않습니다. pst-로 시작해야 합니다';

  @override
  String get auth_tokenFormatDetail =>
      '토큰 형식이 올바르지 않습니다. Persistent 토큰은 pst- 뒤에 10자 이상이 이어집니다. 입력한 토큰을 확인하세요.';

  @override
  String get danbooru_credentialsExpired => '자격 증명이 만료되었습니다. 다시 로그인하세요';

  @override
  String get danbooru_networkRetryLater =>
      '네트워크 연결에 실패했습니다. 네트워크가 돌아오면 다시 시도합니다';

  @override
  String get danbooru_invalidCredentials =>
      '자격 증명을 확인할 수 없습니다. 사용자 이름과 API Key를 확인하세요';

  @override
  String danbooru_verifyFailed(Object error) {
    return '확인하지 못했습니다: $error';
  }

  @override
  String get danbooru_credentialsRequired => '사용자 이름과 API Key는 비워 둘 수 없습니다';

  @override
  String get danbooru_networkCheck => '네트워크 연결에 실패했습니다. 연결을 확인하세요';

  @override
  String get danbooru_loginFailedNetwork => '로그인하지 못했습니다. 네트워크 연결을 확인하세요';

  @override
  String get danbooru_blacklistLoginRequired => '먼저 Danbooru 계정에 로그인하세요';

  @override
  String get danbooru_blacklistPushFailed => 'Danbooru 차단 목록을 올리지 못했습니다';

  @override
  String danbooru_blacklistSyncFailed(Object error) {
    return '동기화하지 못했습니다: $error';
  }

  @override
  String comfyui_submitFailed(Object detail) {
    return '워크플로를 제출하지 못했습니다: $detail';
  }

  @override
  String comfyui_uploadFailed(Object detail) {
    return '이미지를 업로드하지 못했습니다: $detail';
  }

  @override
  String comfyui_fetchImageFailed(Object detail) {
    return '이미지를 가져오지 못했습니다: $detail';
  }

  @override
  String comfyui_historyMissing(Object id) {
    return '작업 기록을 찾을 수 없습니다: $id';
  }

  @override
  String get comfyui_unknownError => '알 수 없는 오류';

  @override
  String comfyui_cannotConnect(Object url) {
    return 'ComfyUI 서버($url)에 연결할 수 없습니다';
  }

  @override
  String get comfyui_noOutput => '작업 출력이 없습니다';

  @override
  String comfyui_nodesNoImage(Object nodes) {
    return '지정한 출력 노드에서 이미지가 나오지 않았습니다: $nodes';
  }

  @override
  String get comfyui_noImageOutput => '작업에서 이미지가 나오지 않았습니다';

  @override
  String get comfyui_executionError => '실행 오류';

  @override
  String comfyui_missingNodes(Object nodes) {
    return 'ComfyUI 노드가 없습니다: $nodes. ComfyUI에서 해당 사용자 지정 노드를 설치하거나 켠 뒤 ComfyUI를 다시 시작하세요.';
  }

  @override
  String get enhance_cannotReadSize => '이미지 크기를 읽을 수 없습니다';

  @override
  String enhance_upscaleFailed(Object error) {
    return '업스케일하지 못했습니다: $error';
  }

  @override
  String enhance_vibeEncodeFailed(Object error) {
    return 'Vibe를 인코딩하지 못했습니다: $error';
  }

  @override
  String enhance_enhanceFailed(Object error) {
    return '이미지를 향상하지 못했습니다: $error';
  }

  @override
  String enhance_annotateFailed(Object error) {
    return '이미지 주석을 만들지 못했습니다: $error';
  }

  @override
  String get enhance_timeout => '요청 시간이 초과되었습니다';

  @override
  String get enhance_networkError => '네트워크 연결 오류';

  @override
  String enhance_serverError(Object status) {
    return '서버가 오류를 반환했습니다: $status';
  }

  @override
  String enhance_serverErrorDetail(Object status, Object detail) {
    return '서버가 오류를 반환했습니다: $status($detail)';
  }

  @override
  String get proxy_connectTimeout => '연결 시간 초과';

  @override
  String get proxy_cannotConnect => '서버에 연결할 수 없습니다';

  @override
  String get proxy_connectFailed => '연결 실패';

  @override
  String get proxy_testServerUnreachable => '테스트 서버에 연결할 수 없습니다';

  @override
  String proxy_testFailed(Object error) {
    return '테스트 실패: $error';
  }

  @override
  String get avatar_noFilePath => '파일 경로를 가져올 수 없습니다';

  @override
  String get avatar_sourceMissing => '원본 파일이 없거나 삭제되었습니다';

  @override
  String avatar_copyFailed(Object error) {
    return '파일을 복사할 수 없습니다: $error';
  }

  @override
  String avatar_saveFailed(Object error) {
    return '아바타를 저장할 수 없습니다: $error';
  }

  @override
  String avatar_operationFailed(Object error) {
    return '작업에 실패했습니다: $error';
  }

  @override
  String get vibeExport_rawImage => '원본 이미지';

  @override
  String get vibeExport_vibePreview => 'Vibe 미리 보기';

  @override
  String get vibeExport_libraryThumbnail => '라이브러리 썸네일';

  @override
  String get vibeExport_pngTitle => 'PNG Vibe 이미지 내보내기';

  @override
  String get vibeExport_pngDirectoryTitle => 'PNG 내보낼 폴더 선택';

  @override
  String get vibeExport_fileTitle => 'Vibe 파일 내보내기';

  @override
  String get vibeExport_bundleTitle => 'Vibe 번들 내보내기';

  @override
  String get vibeExport_zipTitle => 'Vibe ZIP 내보내기';

  @override
  String get vibeExport_nothingToExport => '내보낼 Vibe 항목이 없습니다';

  @override
  String get vibeImport_fileParseFailed => '파일을 분석하지 못했습니다';

  @override
  String get vibeImport_importFiles => '파일 가져오는 중';

  @override
  String get vibeImport_noVibeData => '이미지에 유효한 Vibe 데이터가 없습니다';

  @override
  String get vibeImport_importImages => '이미지 가져오는 중';

  @override
  String get vibeImport_encodingParseFailed => '인코딩을 분석하지 못했습니다';

  @override
  String get vibeImport_importEncodings => '인코딩 가져오는 중';

  @override
  String vibeImport_namingCancelled(Object name) {
    return '이름 지정을 취소해 건너뛰었습니다: $name';
  }

  @override
  String vibeImport_nameEmpty(Object name) {
    return '이름이 비어 있어 건너뛰었습니다: $name';
  }

  @override
  String vibeImport_nameConflict(Object name) {
    return '이름이 겹쳐 건너뛰었습니다: $name';
  }

  @override
  String get vibeImport_saveFailed => '저장하지 못했습니다';

  @override
  String vibeFile_missingRawImage(Object file) {
    return '파일에 사용할 수 있는 원본 이미지 데이터가 없습니다: $file(type=image). 손상되었거나 불완전할 수 있으니 삭제한 뒤 다시 저장하세요.';
  }

  @override
  String get generation_countMustBePositive => '생성 수는 0보다 커야 합니다';

  @override
  String get generation_allTasksFailed => '모든 생성 작업이 실패했습니다';

  @override
  String get generation_failedShort => '생성 실패';

  @override
  String generation_tasksFailedAfterRetry(Object count) {
    return '다시 시도한 뒤에도 작업 $count개가 실패했습니다';
  }

  @override
  String get generation_streamFallbackUnavailable =>
      '스트리밍 생성을 지원하지 않으며 자동으로 대체할 수 없습니다(매개변수 손실)';

  @override
  String generation_streamFallbackFailed(Object error) {
    return '비스트리밍 생성으로 대체하지 못했습니다: $error';
  }

  @override
  String get generation_batchSizeMustBePositive => '배치 수와 배치 크기는 0보다 커야 합니다';

  @override
  String get clipboard_unsupportedPlatform => '이 플랫폼에서는 시스템 클립보드를 지원하지 않습니다';

  @override
  String get clipboard_decodeFailed => '클립보드로 복사할 이미지를 디코딩하지 못했습니다';

  @override
  String drop_remoteImageTooLarge(Object size) {
    return '원격 이미지 다운로드가 $size MB를 넘습니다';
  }

  @override
  String get apiEndpoint_empty => 'API 주소는 비워 둘 수 없습니다';

  @override
  String get apiEndpoint_invalid => 'API 주소가 올바르지 않습니다';

  @override
  String get apiEndpoint_httpOnly => 'http 또는 https API 주소만 지원합니다';

  @override
  String get apiEndpoint_noExtras =>
      'API 주소에는 쿼리 매개변수, 프래그먼트, 사용자 정보를 넣을 수 없습니다';

  @override
  String gallery_folderInaccessible(Object error) {
    return '이미지 폴더에 접근할 수 없습니다: $error';
  }

  @override
  String gallery_scanFailed(Object error) {
    return '이미지를 스캔하지 못했습니다: $error';
  }

  @override
  String gallery_galleryInitFailed(Object error) {
    return '갤러리를 초기화하지 못했습니다: $error';
  }

  @override
  String get resolution_noAdjustment => '조정할 필요 없음';

  @override
  String get dataRefresh_updating => '데이터 업데이트 중...';

  @override
  String dataRefresh_updatingService(Object service) {
    return '$service 업데이트 중...';
  }

  @override
  String get imageUse_title => '이미지 사용';

  @override
  String get imageUse_importContent => '가져올 항목';

  @override
  String get imageUse_characters => '캐릭터';

  @override
  String get imageUse_characterMode => '캐릭터 처리';

  @override
  String get imageMenu_details => '상세 정보';

  @override
  String get imageMenu_creation => '생성 및 참조';

  @override
  String get imageMenu_editAndDerive => '편집 및 파생';

  @override
  String get imageMenu_more => '추가 작업';

  @override
  String get imageMenu_fileActions => '파일 작업';

  @override
  String get imageMenu_saveToBlock => '블록에 저장';

  @override
  String get settings_highAnlasCostEstimate => '예상 사용량';

  @override
  String get settings_highAnlasCostThresholdLabel => '알림 기준';

  @override
  String get settings_highAnlasCostQuestion => '이번 생성을 계속할까요?';

  @override
  String get bridge_title => '로컬 연결';

  @override
  String get bridge_agent => '외부 Agent';

  @override
  String get bridge_agentHint => '로컬 명령을 실행할 수 있는 Agent에게 안내를 전달하세요.';

  @override
  String get bridge_synced => '현재 내용 확인됨';

  @override
  String get bridge_changed => '내용이 변경되었습니다. 다시 확인 대기 중';

  @override
  String get bridge_waiting => '연결 대기 중';

  @override
  String get bridge_ready => '작업 대기 중';

  @override
  String bridge_clients(int count) {
    return 'Agent $count개 연결됨';
  }

  @override
  String bridge_activity(Object client, Object action) {
    return '$client: $action';
  }

  @override
  String get bridge_read => '매개변수 읽기';

  @override
  String get bridge_write => '매개변수 수정';

  @override
  String get bridge_quote => '소모량 계산';

  @override
  String get bridge_generate => '이미지 생성';

  @override
  String get bridge_cancel => '생성 중지';

  @override
  String get bridge_recent => '최근 활동';

  @override
  String get bridge_empty => '아직 활동 없음';

  @override
  String get bridge_copyGuide => '연결 안내 복사';

  @override
  String get bridge_showGuide => '안내 보기';

  @override
  String get bridge_copied => '안내를 복사했습니다';

  @override
  String get bridge_disconnect => 'Agent 연결 종료';

  @override
  String get bridge_settings => '연결 설정';

  @override
  String get bridge_clientMissing => '번들 클라이언트가 없습니다. Studio를 업데이트하세요.';

  @override
  String get bridge_conflict => '내용이 변경되었습니다. 다시 읽어주세요.';

  @override
  String get bridge_busy => '다른 작업이 진행 중입니다';

  @override
  String get bridge_interrupted => '작업 중단됨';

  @override
  String get bridge_failed => '작업에 실패했습니다. Agent 응답을 확인하세요.';

  @override
  String get bridge_timeout => '작업 시간이 초과되었습니다. 다시 시도하세요.';

  @override
  String bridge_guide(Object clientPath) {
    return '로컬 연결로 W.O.F NAI Studio 작업을 도와주세요.\n클라이언트: $clientPath\n\n1. 셸에 맞게 경로를 인용하고 status --name <이름>으로 연결 성공을 확인하세요. 안내 복사만으로 연결되지는 않습니다.\n2. get --name <이름> --out current.json으로 현재 상태를 읽으세요. 편집할 원문은 _draft.fields, 충돌 확인 값은 field_versions입니다. 다른 값에 포함된 품질 태그를 원문에 중복해서 쓰지 마세요.\n3. 사용자가 허용한 필드만 changes.json에 저장하고 set-json changes.json --base current.json --name <이름>을 실행하세요. Studio는 백업 후 해당 필드를 다시 확인합니다. 충돌 시 중단하고 다시 읽으며 최신 사용자 편집을 덮어쓰지 마세요. readback을 확인하세요. characters는 목록 전체를 교체하므로 무관한 이름, 활성 상태, 위치와 id를 보존하세요. 참조 이미지는 현재 읽기 전용입니다.\n4. 연결이나 매개변수 편집은 생성 허가가 아닙니다. 명시적인 생성 요청이 있으면 quote --out quote.json --name <이름>을 실행해 예상 Anlas 단가와 로드된 계정 잔액을 알리세요. 실제 요금은 서버 기준입니다. 허가와 안내 후 gen --quote quote.json --authorized --name <이름>을 실행하세요. 요청당 한 장이며 초안이 바뀌면 다시 계산해야 합니다.\n5. 각 작업이 끝나면 연결이 종료됩니다. Krita와 동시에 연결할 수 있습니다. busy에서는 진행 중인 작업이 끝날 때까지 기다리고 오류 직후 재시도를 반복하지 마세요. Studio의 중지, Ctrl+C 또는 반환된 request_id로 cancel <request_id> --name <같은 이름>을 실행해 생성을 중지할 수 있습니다. 검색 파일의 세션 비밀 키를 출력하지 마세요.\n';
  }

  @override
  String get editor_drawMask => '마스크 그리기';

  @override
  String get editor_eraseMask => '마스크 지우기';

  @override
  String get editor_squareBrush => '사각형 브러시';

  @override
  String get editor_focusedArea => '집중 영역';

  @override
  String get editor_minimumContext => '최소 문맥 영역';

  @override
  String get editor_maskAppearance => '마스크 표시';

  @override
  String get editor_maskColor => '마스크 색상';

  @override
  String get editor_maskOpacity => '마스크 불투명도';

  @override
  String get editor_maskBorder => '테두리';

  @override
  String get editor_patternSolid => '단색';

  @override
  String get editor_patternLines => '선';

  @override
  String get editor_patternCrosshatch => '교차선';

  @override
  String get editor_patternDots => '점';

  @override
  String get editor_patternGrid => '격자';

  @override
  String get editor_patternChecker => '체커';

  @override
  String get editor_patternHearts => '하트';

  @override
  String get editor_resize => '크기 조정';

  @override
  String get editor_penSize => '펜 크기';

  @override
  String get editor_sourceChanged => '편집 중 원본 이미지가 변경되었습니다. 편집기를 다시 열어 주세요.';

  @override
  String get editor_draw => '그리기';

  @override
  String get editor_erase => '지우기';

  @override
  String get editor_select => '선택';

  @override
  String get editor_lasso => '올가미';

  @override
  String get editor_roundTip => '원형';

  @override
  String get editor_softRoundTip => '부드러운 원형';

  @override
  String get editor_squareTip => '사각형';

  @override
  String get editor_pressureSensitivity => '필압 감지';

  @override
  String get editor_hsvAdjustment => 'HSV 조정';

  @override
  String get editor_hue => '색조';

  @override
  String get editor_cloneSourceHint => 'Alt+클릭으로 원본 설정';

  @override
  String get editor_colorAlpha => '투명도';

  @override
  String get editor_colorHex => '색상 HEX';

  @override
  String get editor_closestValidSize => '가장 가까운 유효 생성 크기로 자르기';

  @override
  String get model3d_projection => '투영';

  @override
  String get model3d_perspective => '원근 투영';

  @override
  String get model3d_orthographic => '직교 투영';

  @override
  String get model3d_fov => '시야각';

  @override
  String get model3d_ambient => '주변광';

  @override
  String get model3d_direct => '직접광';

  @override
  String get model3d_direction => '광원 방향';

  @override
  String get model3d_front => '정면';

  @override
  String get model3d_frontTop => '정면 위';

  @override
  String get model3d_top => '위';

  @override
  String get model3d_left => '왼쪽';

  @override
  String get model3d_right => '오른쪽';

  @override
  String get model3d_back => '후면';

  @override
  String get model3d_shadows => '그림자';

  @override
  String get model3d_quality => '품질';

  @override
  String get model3d_veryLow => '매우 낮음';

  @override
  String get model3d_low => '낮음';

  @override
  String get model3d_medium => '중간';

  @override
  String get model3d_high => '높음';

  @override
  String get model3d_veryHigh => '매우 높음';

  @override
  String get model3d_display => '표시';

  @override
  String get model3d_showBones => '본 표시';

  @override
  String get model3d_bones => '본 목록';

  @override
  String get model3d_noBones => '본이 없습니다';

  @override
  String get model3d_morphs => '모프 타깃';

  @override
  String get model3d_noMorphs => '모프 타깃이 없습니다';

  @override
  String get model3d_settings => '3D 렌더 설정';

  @override
  String get model3d_resetModel => '모델 위치 초기화';

  @override
  String get model3d_removeModel => '모델 제거';

  @override
  String get model3d_removeConfirm => '이 모델을 제거할까요? 저장하지 않은 모델 편집 내용이 사라집니다.';

  @override
  String get model3d_toolTransform => '모델 변환';

  @override
  String get model3d_toolPose => '모델 포즈';

  @override
  String get localUpscale_local => '로컬';

  @override
  String get localUpscale_manage => '모델 관리';

  @override
  String get localUpscale_description => '로컬에서 이미지를 확대하며 Anlas를 사용하지 않습니다.';

  @override
  String get localUpscale_bundled => '내장';

  @override
  String get localUpscale_download => '다운로드';

  @override
  String get localUpscale_importHelp =>
      '4배 Real-ESRGAN NCNN 모델의 .param 및 .bin 파일 쌍을 가져옵니다(data/output 노드). PyTorch 및 safetensors는 지원하지 않습니다.';

  @override
  String get localUpscale_preparing => '이미지 준비 중…';

  @override
  String get localUpscale_inference => '업스케일 중…';

  @override
  String get localUpscale_resizing => '이미지 마무리 중…';

  @override
  String get localUpscale_complete => '업스케일 완료';

  @override
  String get localUpscale_cancelling => '취소 중…';

  @override
  String get localUpscale_unsupportedPlatform => '로컬 업스케일은 현재 Windows를 지원합니다.';

  @override
  String get localUpscale_engineMissing =>
      '로컬 엔진을 사용할 수 없습니다. 전체 Studio 패키지를 다시 설치하세요.';

  @override
  String get localUpscale_integrity => '파일 검증에 실패했습니다. 모델 또는 Studio를 다시 설치하세요.';

  @override
  String get localUpscale_modelMissing =>
      '모델을 사용할 수 없습니다. 설치된 모델을 선택하거나 모델 경로 길이를 확인하세요.';

  @override
  String get localUpscale_invalidModel =>
      '호환되지 않는 모델입니다. 4배 Real-ESRGAN NCNN 파일 쌍을 가져오세요.';

  @override
  String get localUpscale_invalidImage =>
      '이미지를 읽을 수 없습니다. PNG, JPEG 또는 WebP를 시도하세요.';

  @override
  String get localUpscale_sizeLimit =>
      '이미지가 너무 큽니다. 모델 출력은 6,400만 픽셀 이하여야 합니다.';

  @override
  String get localUpscale_noVulkan =>
      '사용 가능한 Vulkan GPU가 없습니다. 그래픽 드라이버를 업데이트하세요.';

  @override
  String get localUpscale_processFailed =>
      '업스케일에 실패했습니다. 모델과 그래픽 드라이버를 확인하세요. 원본은 유지됩니다.';

  @override
  String get localUpscale_timeout => '시간이 초과되었습니다. 더 작은 이미지를 시도하세요.';

  @override
  String get localUpscale_busy => '다른 업스케일 또는 모델 작업이 실행 중입니다.';

  @override
  String get localUpscale_cancelled => '업스케일 취소됨';

  @override
  String get localUpscale_anime => '애니메이션 · 품질';

  @override
  String get localUpscale_animeFast => '애니메이션 · 빠름';

  @override
  String get localUpscale_general => '범용 · 사진';

  @override
  String get localUpscale_downloadProgress => '모델 다운로드 중…';

  @override
  String get localUpscale_importModel => '모델 가져오기';

  @override
  String get localUpscale_modelOperationFailed =>
      '모델 작업에 실패했습니다. 연결, 파일 권한 및 여유 공간을 확인한 후 다시 시도하세요.';

  @override
  String get settings_localUpscale => '로컬 확대';

  @override
  String get settings_localUpscaleDescription => '로컬 확대 모델과 실행 구성 요소를 관리합니다.';

  @override
  String get localUpscale_noCuda => 'CUDA 지원 NVIDIA GPU와 호환 드라이버가 필요합니다.';

  @override
  String get localUpscale_noRtx =>
      'RTX Video를 사용할 수 없습니다. NVIDIA RTX GPU와 드라이버를 확인하세요.';

  @override
  String get localUpscale_encoding => '이미지 인코딩 중…';

  @override
  String get localUpscale_decoding => '이미지 디코딩 중…';

  @override
  String get localUpscale_optionalComponents => '선택 구성 요소';

  @override
  String get localUpscale_noAutomaticDownload =>
      '필요한 구성 요소를 다운로드하세요. 기존 로컬 모델은 바로 사용할 수 있습니다.';

  @override
  String get localUpscale_notInstalledShort => '미설치';

  @override
  String get localUpscale_seedvr2ThreeSummary =>
      '화질과 리소스 사용량의 균형이 좋아 일상적인 확대에 적합합니다.';

  @override
  String get localUpscale_seedvr2SevenSummary =>
      '더 높은 화질을 기대할 수 있지만 VRAM과 처리 시간이 더 필요합니다.';

  @override
  String get localUpscale_seedvr2SharpSummary =>
      '더 선명한 디테일을 강조하며, 질감을 강화하려는 이미지에 적합합니다.';

  @override
  String get localUpscale_seedvr2SharpHelp =>
      '7B Sharp FP8은 더 선명한 질감과 윤곽을 강조합니다. 가중치는 약 8.2 GB이며, 다른 SeedVR2 모델과 VAE 및 Python/CUDA 환경을 공유합니다.';

  @override
  String get localUpscale_seedvr2Int8Help =>
      'INT8 ConvRot(실험적): NVIDIA Turing 이상의 GPU가 필요합니다. FP8과 실행 환경을 공유하며, 속도와 화질은 이미지와 GPU에 따라 달라집니다.';

  @override
  String get localUpscale_noInt8 =>
      '이 GPU 또는 CUDA 환경에서는 네이티브 INT8을 사용할 수 없습니다. FP8을 선택하세요.';

  @override
  String get localUpscale_seedvr2SharedHelp =>
      '모델은 VAE(약 0.5 GB)와 Python/CUDA 환경을 공유합니다. NVIDIA GPU가 필요합니다.';

  @override
  String get localUpscale_seedvr2Help =>
      '3B FP8은 화질과 자원 사용의 균형을 제공합니다. 가중치 약 3.4 GB와 VAE 약 0.5 GB가 필요하며, VAE 및 Python/CUDA 환경을 7B와 공유합니다. NVIDIA GPU가 필요합니다.';

  @override
  String get localUpscale_seedvr2SevenHelp =>
      '7B FP8은 더 높은 화질을 기대할 수 있지만 VRAM과 처리 시간이 더 필요합니다. 가중치는 약 8.2 GB이며 VAE 및 Python/CUDA 환경을 3B와 공유합니다.';

  @override
  String get localUpscale_outOfMemory =>
      'VRAM이 부족합니다. 3B, 낮은 배율 또는 고급 설정의 낮은 VRAM 모드와 VAE 타일 처리를 사용해 보세요. 모델은 자동으로 변경되지 않았습니다.';

  @override
  String get localUpscale_modelWeights => '가중치';

  @override
  String get localUpscale_advancedSettings => '고급 설정';

  @override
  String get localUpscale_seedvr2Color => '색상 보정';

  @override
  String get localUpscale_colorNone => '보정 안 함';

  @override
  String get localUpscale_seedvr2Seed => '무작위 시드';

  @override
  String get localUpscale_seedvr2Memory => 'VRAM 사용 방식';

  @override
  String get localUpscale_memoryRecommended => '권장';

  @override
  String get localUpscale_memoryLow => '낮은 VRAM';

  @override
  String get localUpscale_blocksToSwap => 'CPU로 옮길 블록 수';

  @override
  String get localUpscale_memoryHelp =>
      '더 많은 블록을 옮기면 VRAM을 절약하지만 RAM 사용량이 늘고 느려집니다. 낮은 VRAM 모드에서도 모든 출력 크기를 처리할 수 있는 것은 아닙니다.';

  @override
  String get localUpscale_vaeTiled => 'VAE 타일 처리';

  @override
  String get localUpscale_vaeTileSize => '타일 크기';

  @override
  String get localUpscale_vaeOverlap => '타일 겹침';

  @override
  String get localUpscale_vaeHelp =>
      '작은 타일은 VRAM을 절약하고 겹침은 경계를 완화합니다. 전체 업스케일링이 아닌 VAE 인코딩 및 디코딩만 나눕니다.';

  @override
  String get localUpscale_experimental => '실험적 변화';

  @override
  String get localUpscale_inputNoise => '입력 노이즈';

  @override
  String get localUpscale_latentNoise => '잠재 노이즈';

  @override
  String get localUpscale_noiseHelp =>
      '두 값을 0으로 유지하면 현재 동작을 그대로 사용합니다. 노이즈를 늘려도 화질이나 세부 개선이 보장되지 않으며 선과 얼굴이 달라질 수 있습니다.';

  @override
  String get localUpscale_restoreDefaults => '기본값 복원';

  @override
  String get localUpscale_rtxHelp =>
      'NVIDIA RTX Video로 빠르게 확대합니다. 약 64 MB의 별도 구성 요소와 호환 RTX GPU가 필요합니다.';

  @override
  String get localUpscale_installed => '설치됨';

  @override
  String get localUpscale_notInstalled => '미설치 — 모델 관리에서 설치하세요';

  @override
  String get localUpscale_license => '라이선스';

  @override
  String get localUpscale_installComponent => '설치';

  @override
  String get localUpscale_installingRuntime => 'Python/CUDA 환경 설치 중…';

  @override
  String get localUpscale_installingPython => '독립 Python 준비 중…';

  @override
  String localUpscale_installFailed(String stage) {
    return '설치 실패 단계: $stage';
  }

  @override
  String get wiki_translationQueued => '번역 대기 중';

  @override
  String get wiki_translationFailedRetry => '번역 실패 — 클릭하여 다시 시도';

  @override
  String get localUpscale_checkingComponent => '구성 요소와 GPU 확인 중…';

  @override
  String get localUpscale_installingComponent => '구성 요소 다운로드 중…';

  @override
  String get upscale_settings => '확대 설정';

  @override
  String upscale_cloudCost(int cost) {
    return '예상 $cost Anlas · 2×';
  }

  @override
  String get enhance_localAfterGeneration => '생성된 각 이미지를 로컬에서 자동으로 확대합니다.';

  @override
  String get enhance_localAction => '생성 후 로컬 확대';

  @override
  String get localUpscale_stop => '업스케일 중지';

  @override
  String get localUpscale_scrollDown => '아래로 스크롤';

  @override
  String get wiki_exampleImages => '예시 이미지';

  @override
  String get wiki_exampleImagesUnavailable => '예시 이미지를 불러올 수 없습니다';

  @override
  String get generation_perRequestLabel => '장 수';

  @override
  String get generation_perRequestTooltip => '요청당 생성할 이미지 수 (1–4)';

  @override
  String get generation_repeatLabel => '반복';

  @override
  String get generation_referenceUpload => '업로드';

  @override
  String get generation_seedPinnedLabel => '시드 · 고정';

  @override
  String get generation_paramsDrawerTooltip => '추가 매개변수';

  @override
  String get library_sizeSmall => '작게';

  @override
  String get library_sizeMedium => '보통';

  @override
  String get library_sizeLarge => '크게';

  @override
  String get library_currentModel => '현재 모델';

  @override
  String get library_available => '사용 가능';

  @override
  String get library_unavailable => '사용 불가';

  @override
  String get library_inGeneration => '생성에 사용 중';

  @override
  String library_selectedCount(int count) {
    return '$count개 선택';
  }

  @override
  String get library_invertSelection => '선택 반전';

  @override
  String get library_more => '더 보기';

  @override
  String get viewer_fit => '맞춤';

  @override
  String get viewer_showInfo => '정보 패널 표시 (I)';

  @override
  String get viewer_hideInfo => '정보 패널 숨기기 (I)';

  @override
  String get viewer_originalSize => '원본 크기 (1)';

  @override
  String get viewer_fullscreen => '전체 화면 (F11)';

  @override
  String get shortcut_action_toggle_info_panel => '정보 패널 전환';

  @override
  String styleExplore_autoRunName(String blocks, String time) {
    return '$blocks · $time';
  }

  @override
  String get styleExplore_openBlockLibrary => '블록 라이브러리 열기';

  @override
  String get styleExplore_drawCountLabel => '이번 추출';

  @override
  String get styleExplore_drawCountSuffix => '장 · 한 장씩 생성';

  @override
  String get styleExplore_appliedToEditor => '편집기에 적용됨';

  @override
  String styleExplore_onboardingDraw(int count) {
    return '후보 $count장 추출';
  }

  @override
  String get stats_title => '통계';

  @override
  String get stats_subtitle => '로컬 갤러리 · 파일 시간 기준';

  @override
  String stats_rangeDays(Object count) {
    return '$count일';
  }

  @override
  String get stats_rangeThisYear => '올해';

  @override
  String get stats_rangeAll => '전체';

  @override
  String get stats_naiOnly => 'NAI 이미지만';

  @override
  String stats_updatedAt(Object time) {
    return '$time 업데이트';
  }

  @override
  String get stats_updating => '업데이트 중';

  @override
  String stats_counting(Object count) {
    return '$count장 집계 중…';
  }

  @override
  String get stats_updateFailed => '업데이트 실패';

  @override
  String get stats_refresh => '새로 고침';

  @override
  String stats_lastDays(Object count) {
    return '최근 $count일';
  }

  @override
  String stats_lastDaysShort(Object count) {
    return '$count일';
  }

  @override
  String get stats_unitDays => '일';

  @override
  String stats_imagesCount(Object count) {
    return '$count장';
  }

  @override
  String get stats_less => '적음';

  @override
  String get stats_more => '많음';

  @override
  String get stats_kpiImages => '이미지';

  @override
  String get stats_kpiNewImages => '새 이미지';

  @override
  String stats_kpiActiveDays(Object days, Object avg) {
    return '활동 $days일 · 일평균 $avg';
  }

  @override
  String stats_kpiVsPrevious(Object count) {
    return '이전 $count일 대비';
  }

  @override
  String get stats_kpiVsLastYear => '작년 같은 기간 대비';

  @override
  String stats_kpiPreviousValue(Object value) {
    return ' ($value)';
  }

  @override
  String get stats_kpiFavorites => '즐겨찾기';

  @override
  String stats_kpiFavoriteRate(Object rate) {
    return '즐겨찾기 비율 $rate';
  }

  @override
  String get stats_kpiAnlas90 => 'Anlas · 최근 90일';

  @override
  String get stats_kpiAnlasSpent => 'Anlas 사용';

  @override
  String stats_kpiAnlasRecent(Object week, Object today) {
    return '7일 $week · 오늘 $today';
  }

  @override
  String stats_kpiAnlasDaily(Object avg, Object today) {
    return '일평균 $avg · 오늘 $today';
  }

  @override
  String get stats_kpiStreak => '연속 창작';

  @override
  String stats_kpiLongest(Object days, Object unit) {
    return '최장 $days$unit';
  }

  @override
  String stats_kpiLongestRange(Object days, Object unit, Object range) {
    return '최장 $days$unit ($range)';
  }

  @override
  String get stats_kpiStorage => '용량';

  @override
  String stats_kpiStorageDetail(Object avg, Object pct) {
    return '평균 $avg · 메타데이터 $pct';
  }

  @override
  String get stats_calendarTitle => '창작 캘린더';

  @override
  String get stats_calendarHint => '한 칸이 하루, 진할수록 많음';

  @override
  String get stats_calendarPastYear => '최근 1년';

  @override
  String stats_calendarYear(Object year) {
    return '$year년';
  }

  @override
  String get stats_calendarImagesPastYear => '최근 1년 이미지';

  @override
  String stats_calendarImagesInYear(Object year) {
    return '$year년 이미지';
  }

  @override
  String get stats_calendarActiveDays => '창작한 날';

  @override
  String get stats_calendarBestDay => '가장 많은 날';

  @override
  String get stats_calendarLongestStreak => '최장 연속';

  @override
  String get stats_calendarTipOpen => '클릭하면 로컬 갤러리에서 이 날을 엽니다';

  @override
  String get stats_productionTitle => '생성량과 모델';

  @override
  String stats_productionHintAll(Object unit) {
    return '$unit별, 색은 모델';
  }

  @override
  String stats_productionHintRange(Object range, Object unit) {
    return '$range, $unit별, 색은 모델';
  }

  @override
  String get stats_unitDay => '일';

  @override
  String get stats_unitWeek => '주';

  @override
  String get stats_unitMonth => '월';

  @override
  String get stats_granularityDay => '일';

  @override
  String get stats_granularityWeek => '주';

  @override
  String get stats_granularityMonth => '월';

  @override
  String stats_monthWithYear(Object year, Object month) {
    return '$year.$month';
  }

  @override
  String get stats_productionModelsHint => '모델 · 클릭하면 해당 모델만 보기';

  @override
  String stats_productionOtherModels(Object count) {
    return '기타 모델 $count개';
  }

  @override
  String stats_productionNoMetadata(Object count) {
    return '메타데이터 없는 이미지 $count장 (연회색)';
  }

  @override
  String get stats_familyOther => '기타 모델';

  @override
  String get stats_familyNoMetadata => '메타데이터 없음';

  @override
  String stats_productionTipTotal(Object period, Object count) {
    return '$period · $count장';
  }

  @override
  String get stats_productionTipOpenDay => '클릭하면 로컬 갤러리에서 이 날을 엽니다';

  @override
  String get stats_productionTipOpenWeek => '클릭하면 로컬 갤러리에서 이 주를 엽니다';

  @override
  String get stats_productionTipOpenMonth => '클릭하면 로컬 갤러리에서 이 달을 엽니다';

  @override
  String get stats_punchTitle => '언제 그리나';

  @override
  String get stats_punchHint => '요일 × 시간';

  @override
  String get stats_punchPeak => '가장 많음';

  @override
  String stats_punchPeakValue(Object weekday, Object from, Object to) {
    return '$weekday $from–$to시';
  }

  @override
  String get stats_punchBusiest => '가장 바쁨';

  @override
  String get stats_punchLateNight => '심야';

  @override
  String get stats_punchNote => '원이 클수록 많음';

  @override
  String get stats_anlasTitle => 'Anlas 사용';

  @override
  String get stats_anlasToday => '오늘';

  @override
  String get stats_anlasDailyAvg => '일평균';

  @override
  String stats_anlasActiveDays(Object count) {
    return '사용한 날 $count일';
  }

  @override
  String get stats_anlasPeak => '최다';

  @override
  String get stats_anlasNote => '잔액이 줄 때 기록하며 업스케일·Vibe 인코딩 포함, 최근 90일만 보관';

  @override
  String get stats_aspectTitle => '캔버스 크기';

  @override
  String get stats_aspectHint => '실제 크기';

  @override
  String get stats_aspectOrientation => '방향';

  @override
  String get stats_orientationPortrait => '세로';

  @override
  String get stats_orientationLandscape => '가로';

  @override
  String get stats_orientationSquare => '정사각';

  @override
  String stats_aspectShapeCount(Object orientation, Object count) {
    return '$orientation · $count';
  }

  @override
  String stats_aspectOthers(Object count, Object pct) {
    return '기타 $count종 · $pct';
  }

  @override
  String get stats_aspectClickHint => '크기나 방향을 클릭하면 해당 이미지만 보기';

  @override
  String get stats_paramsTitle => '파라미터 습관';

  @override
  String get stats_paramsHint => '메타데이터 있는 이미지';

  @override
  String get stats_paramsCombo => '가장 많이 쓰는 설정';

  @override
  String get stats_paramsSampler => '샘플러';

  @override
  String get stats_paramsSteps => '스텝';

  @override
  String stats_paramsStepsValue(Object count) {
    return '$count스텝';
  }

  @override
  String get stats_paramsNoise => '노이즈 스케줄';

  @override
  String get stats_artistsTitle => '자주 쓰는 작가';

  @override
  String stats_artistsHint(Object count, Object pct) {
    return '작가 태그 사용 $count장 ($pct)';
  }

  @override
  String get stats_artistsComputing => '작가 집계 중…';

  @override
  String get stats_artistsNone => '프롬프트에 artist: 태그가 없습니다';

  @override
  String get stats_artistsNote => '등장한 이미지 수 기준, 한 이미지에서 여러 번 써도 1회';

  @override
  String stats_artistsTipSearch(Object query) {
    return '로컬 갤러리에서 $query 검색';
  }

  @override
  String get stats_artistsTipCopy => '우클릭: 작가 이름 복사';

  @override
  String stats_artistsCopied(Object name) {
    return '$name 복사됨';
  }

  @override
  String get stats_storageTitle => '저장 공간';

  @override
  String stats_storageFiles(Object count) {
    return '파일 $count개';
  }

  @override
  String get stats_storageMonthly => '최근 12개월 월별 추가';

  @override
  String stats_storageNoMetadata(Object count) {
    return '메타데이터 없음 $count장';
  }

  @override
  String get stats_storageViewInGallery => '로컬 갤러리에서 보기';

  @override
  String stats_storageLarge(Object count, Object size) {
    return '10MB 초과 $count장 · $size';
  }

  @override
  String get stats_storageView => '보기';

  @override
  String get stats_footer =>
      '통계를 열 때마다 갤러리 변경을 확인해 백그라운드에서 다시 집계 · 숫자를 클릭하면 해당 필터로 로컬 갤러리를 엽니다';

  @override
  String get stats_emptyTitle => '로컬 갤러리에 아직 이미지가 없습니다';

  @override
  String get stats_emptyBody =>
      '생성한 이미지는 로컬 갤러리에 자동으로 저장되며, 기존 이미지 폴더를 추가할 수도 있습니다. 이후 이곳에 창작 리듬, 모델, 파라미터 습관이 표시됩니다.';

  @override
  String get stats_emptyGenerate => '생성하러 가기';

  @override
  String get stats_emptyAddFolder => '갤러리 폴더 추가';

  @override
  String get stats_errorTitle => '통계를 계산하지 못했습니다';

  @override
  String get stats_errorRetry => '다시 시도';

  @override
  String get navShell_page_generation => '생성';

  @override
  String get navShell_page_styleExplore => '화풍 탐색';

  @override
  String get navShell_page_localGallery => '로컬 갤러리';

  @override
  String get navShell_page_onlineGallery => '온라인 갤러리';

  @override
  String get navShell_page_promptBlocks => '프롬프트 블록';

  @override
  String get navShell_page_vibeLibrary => 'Vibe 라이브러리';

  @override
  String get navShell_page_preciseRef => '정밀 참조 라이브러리';

  @override
  String get navShell_page_tagWiki => '태그 백과';

  @override
  String get navShell_page_statistics => '통계';

  @override
  String get navShell_page_settings => '설정';

  @override
  String get navShell_group_create => '창작';

  @override
  String get navShell_group_gallery => '갤러리';

  @override
  String get navShell_group_assets => '소재';

  @override
  String get navShell_group_tools => '도구';

  @override
  String get navShell_expand => '내비게이션 펼치기';

  @override
  String get navShell_collapse => '접기';

  @override
  String get navShell_pin => '펼친 상태 고정';

  @override
  String get navShell_genRunning => '생성 중';

  @override
  String navShell_genRunningCount(Object current, Object total) {
    return '생성 중 · $current / $total장';
  }

  @override
  String navShell_genPercent(Object percent) {
    return '$percent% · 실시간 미리보기';
  }

  @override
  String get navShell_genBack => '클릭하면 생성 페이지로 돌아갑니다';

  @override
  String navShell_genDone(Object count) {
    return '$count장 완료, 클릭하여 보기';
  }

  @override
  String get navShell_genFailed => '생성 실패';

  @override
  String get navShell_tasksTitle => '백그라운드 작업';

  @override
  String navShell_tasksRunning(Object count) {
    return '$count개 진행 중';
  }

  @override
  String get navShell_tasksFooter => '모두 끝나면 10초 후 이 아이콘이 사라집니다';

  @override
  String get navShell_task_localUpscale => '로컬 업스케일';

  @override
  String get navShell_task_cloudUpscale => '클라우드 업스케일';

  @override
  String get navShell_task_bulkDelete => '휴지통으로 이동';

  @override
  String get navShell_task_bulkExport => '일괄 내보내기';

  @override
  String get navShell_task_bulkMetadata => '메타데이터 일괄 편집';

  @override
  String get navShell_task_bulkAddToCollection => '컬렉션에 추가';

  @override
  String get navShell_task_bulkRemoveFromCollection => '컬렉션에서 제거';

  @override
  String get navShell_task_bulkFavorite => '일괄 즐겨찾기';

  @override
  String navShell_taskImages(Object title, Object count) {
    return '$title $count장';
  }

  @override
  String get navShell_taskJustDone => '방금 완료';

  @override
  String get navShell_taskView => '보기';

  @override
  String get navShell_taskCancel => '취소';

  @override
  String get navShell_taskCancelling => '취소 중';

  @override
  String get navShell_taskUndo => '실행 취소';

  @override
  String get navShell_account => '계정';

  @override
  String get navShell_accountTitle => '로그인 및 계정';

  @override
  String get navShell_accountCurrent => '현재';

  @override
  String get navShell_accountToken => 'API 토큰 로그인';

  @override
  String get navShell_accountCredentials => '이메일 로그인';

  @override
  String get navShell_accountNotSignedIn => '로그인 안 됨';

  @override
  String get navShell_accountChoose => '계속할 계정을 선택하세요';

  @override
  String navShell_subExpires(Object date, Object days) {
    return '구독 $date 만료 · $days일 남음';
  }

  @override
  String get navShell_subExpired => '구독 만료됨';

  @override
  String get navShell_anlas => 'Anlas 잔액';

  @override
  String get navShell_switchAccount => '계정 전환';

  @override
  String get navShell_addAccount => '계정 추가';

  @override
  String get navShell_manageAccounts => '계정 관리';

  @override
  String get navShell_logout => '로그아웃';

  @override
  String get navShell_customize => '내비게이션 사용자 지정';

  @override
  String get navShell_customizeMenu => '내비게이션 사용자 지정…';

  @override
  String get navShell_customizeNote =>
      '내비게이션 바를 우클릭하면 열립니다. 숨긴 페이지도 단축키로 열 수 있습니다. 생성은 숨길 수 없습니다';

  @override
  String get navShell_ctrlNumbers => 'Ctrl을 누르고 있으면 페이지 번호 표시';

  @override
  String get navShell_reset => '기본값 복원';

  @override
  String get navShell_done => '완료';

  @override
  String get navShell_ctrlHint => '누르고 있으면 페이지 번호 표시, 숫자로 바로 이동, 놓으면 사라집니다';

  @override
  String get online_title => '온라인 갤러리';

  @override
  String get online_collapseSidebar => '사이드바 접기';

  @override
  String get online_expandSidebar => '사이드바 펼치기';

  @override
  String get online_sectionBrowse => '탐색';

  @override
  String get online_modeSearch => '검색';

  @override
  String get online_modeMonthly => '월간 순위';

  @override
  String get online_modePopular => '인기';

  @override
  String get online_modeMyFavorites => '내 즐겨찾기';

  @override
  String get online_modeFavorites => '즐겨찾기';

  @override
  String get online_noRanking => '순위 없음';

  @override
  String get online_noFavorites => '즐겨찾기 미지원';

  @override
  String get online_readOnly => '읽기 전용';

  @override
  String get online_signedOut => '로그인 안 됨';

  @override
  String get online_recentTitle => '최근 검색';

  @override
  String get online_recentClear => '지우기';

  @override
  String get online_collections => '컬렉션';

  @override
  String get online_newCollection => '새 컬렉션';

  @override
  String get online_all => '전체';

  @override
  String get online_ungrouped => '미분류';

  @override
  String get online_favAuthors => '저장한 작가';

  @override
  String get online_blacklist => '차단 목록';

  @override
  String online_blacklistCount(Object count) {
    return '태그 $count개 차단';
  }

  @override
  String get online_srcSubAiTag => 'NAI 작품 커뮤니티 · 전체 Prompt';

  @override
  String online_srcSubSignedIn(Object name) {
    return '로그인됨 · $name';
  }

  @override
  String get online_srcSubSafebooru => '전연령 · 로그인 불필요';

  @override
  String get online_srcSubKeyOk => 'API Key 설정됨';

  @override
  String get online_srcSubKeyInvalid => 'API Key 무효';

  @override
  String get online_srcSubKeyMissing => 'API Key 미설정';

  @override
  String get online_switchSource => '소스 변경';

  @override
  String get online_capPromptSearch => '작품 + Prompt 검색';

  @override
  String get online_capTagSearch => '태그 검색';

  @override
  String get online_capMonthly => '월간 순위';

  @override
  String get online_capRankings => '일 / 주 / 월 순위';

  @override
  String get online_capLocalFav => '로컬 즐겨찾기';

  @override
  String get online_capSiteFav => '사이트 즐겨찾기';

  @override
  String get online_capReadOnlyFav => '즐겨찾기(읽기 전용)';

  @override
  String get online_capMultiMedia => '여러 장 작품';

  @override
  String get online_capParams => '생성 파라미터';

  @override
  String get online_capRatings => '등급';

  @override
  String get online_capSfwOnly => '전연령만';

  @override
  String get online_acctNone => '로그인 불필요';

  @override
  String get online_acctSignedIn => '로그인됨';

  @override
  String get online_acctKeyOk => 'Key 설정됨';

  @override
  String get online_acctKeyInvalid => 'Key 무효';

  @override
  String get online_acctKeyMissing => 'Key 미설정';

  @override
  String get online_sourceMemory => '소스마다 검색어와 스크롤 위치를 기억합니다';

  @override
  String get online_searchWorkHint => '작품, 작가, 제목, 태그 또는 모델';

  @override
  String get online_searchPromptHint => 'Prompt 포함…(::artist: 원문 문법 지원)';

  @override
  String get online_searchTagHint => '태그 추가, 공백 구분, 앞에 - 는 제외';

  @override
  String get online_searchFavHint => '즐겨찾기에서 찾기: 제목, 작가, 태그';

  @override
  String get online_fuzzy => '유사 검색';

  @override
  String get online_clearSearch => '검색 지우기';

  @override
  String get online_sizeSmall => '작게(제목 없음)';

  @override
  String get online_sizeMedium => '중';

  @override
  String get online_sizeLarge => '대';

  @override
  String get online_multiSelect => '다중 선택';

  @override
  String get online_doneMultiSelect => '선택 완료';

  @override
  String get online_refresh => '새로고침';

  @override
  String get online_inspector => '인스펙터';

  @override
  String get online_naiOnly => 'NAI 이미지만';

  @override
  String get online_model => '모델';

  @override
  String get online_modelAll => '전체';

  @override
  String get online_timeAll => '전체 기간';

  @override
  String online_timeYear(Object year) {
    return '$year년';
  }

  @override
  String get online_timeOlder => '이전 기록';

  @override
  String online_loaded(Object count, Object pages) {
    return '$count장 · $pages페이지 불러옴';
  }

  @override
  String online_rankLoaded(Object count) {
    return '1–$count위 · $count장 불러옴';
  }

  @override
  String get online_jumpToPage => '페이지 이동…';

  @override
  String get online_jumpGo => '이동';

  @override
  String get online_ratingLabel => '등급';

  @override
  String get online_ratingG => '전연령';

  @override
  String get online_ratingS => '경미';

  @override
  String get online_ratingQ => '민감';

  @override
  String get online_ratingE => '노골적';

  @override
  String get online_dateRange => '기간';

  @override
  String get online_clearDateRange => '기간 제한 없음';

  @override
  String get online_rankCurrent => '실시간 월간';

  @override
  String get online_rankDay => '일간';

  @override
  String get online_rankWeek => '주간';

  @override
  String get online_rankMonth => '월간';

  @override
  String get online_today => '오늘';

  @override
  String get online_previous => '이전';

  @override
  String get online_next => '다음';

  @override
  String get online_sort => '정렬';

  @override
  String get online_sortFavTime => '저장 시간';

  @override
  String get online_favAll => '모든 즐겨찾기';

  @override
  String online_countImages(Object count) {
    return '$count장';
  }

  @override
  String online_authorSaved(Object count, Object date) {
    return '$count장 저장 · $date 작가 저장';
  }

  @override
  String get online_authorAllWorks => 'AI TAG에서 모든 작품 보기';

  @override
  String get online_unfavAuthor => '작가 저장 해제';

  @override
  String get online_favAuthor => '작가 저장';

  @override
  String get online_dragHint => '카드를 왼쪽 컬렉션으로 끌면 이동; 우클릭 → 이동 / 해제';

  @override
  String get online_readOnlyNote => '읽기 전용: Gelbooru 즐겨찾기는 사이트에서 수정';

  @override
  String get online_returnPrev => '이전 결과로';

  @override
  String get online_send => '생성으로 보내기';

  @override
  String get online_sendTags => '태그를 생성으로 보내기';

  @override
  String get online_sendModes => '보내는 방식 선택';

  @override
  String get online_favorite => '즐겨찾기';

  @override
  String get online_favorited => '저장됨';

  @override
  String get online_copyPrompt => 'Prompt 복사';

  @override
  String get online_copyTags => '태그 복사';

  @override
  String get online_download => '다운로드';

  @override
  String online_downloadAll(Object count) {
    return '$count장 모두 다운로드';
  }

  @override
  String get online_downloadCurrent => '이 이미지만 다운로드';

  @override
  String get online_more => '더보기';

  @override
  String get online_openInBrowser => '사이트에서 열기';

  @override
  String get online_onlyAuthor => '이 작가만';

  @override
  String get online_moveTo => '컬렉션으로 이동';

  @override
  String get online_unfavorite => '즐겨찾기 해제';

  @override
  String get online_rename => '이름 변경';

  @override
  String get online_deleteCollection => '컬렉션 삭제';

  @override
  String get online_inspWork => '작품';

  @override
  String get online_inspPost => '게시물';

  @override
  String online_youSaved(Object count) {
    return '이 작가 작품 $count장 저장';
  }

  @override
  String get online_params => '생성 파라미터';

  @override
  String get online_pModel => '모델';

  @override
  String get online_pSize => '크기';

  @override
  String get online_pSeed => '시드';

  @override
  String get online_pSampler => '샘플러';

  @override
  String get online_pStepsCfg => '스텝 · CFG';

  @override
  String get online_prompt => '프롬프트';

  @override
  String get online_negative => '네거티브';

  @override
  String get online_tags => '태그';

  @override
  String get online_tagsHint => '클릭하면 검색에 추가';

  @override
  String get online_tagArtist => '작가';

  @override
  String get online_tagCopyright => '작품';

  @override
  String get online_tagCharacter => '캐릭터';

  @override
  String get online_tagGeneral => '일반';

  @override
  String get online_tagMeta => '메타';

  @override
  String get online_copy => '복사';

  @override
  String get online_noSelection => '카드를 클릭하면 여기에서 Prompt와 파라미터를 봅니다';

  @override
  String online_detailError(Object error) {
    return '상세 정보를 불러오지 못했습니다: $error';
  }

  @override
  String get online_retry => '다시 시도';

  @override
  String get online_noPrompt => '이 이미지에는 Prompt가 없습니다';

  @override
  String online_selCount(Object count) {
    return '$count장 선택됨';
  }

  @override
  String get online_selAll => '전체 선택';

  @override
  String get online_selInvert => '선택 반전';

  @override
  String get online_favoriteTo => '즐겨찾기에 추가…';

  @override
  String get online_favoriteToTitle => '추가 위치';

  @override
  String get online_favoriteToSite => '사이트 즐겨찾기에 추가';

  @override
  String online_downloadN(Object count) {
    return '다운로드 · $count장';
  }

  @override
  String get online_newCollectionAndFav => '새 컬렉션에 추가';

  @override
  String get online_collectionNameHint => '컬렉션 이름, Enter로 확인';

  @override
  String get online_exitMulti => '선택 종료';

  @override
  String get online_sendRemember => '이 선택 기억';

  @override
  String get online_sendReplace => '프롬프트 교체, 캐릭터 칸 비우기';

  @override
  String online_sendReplaceDesc(Object count) {
    return '긍정 + 부정을 이 이미지 것으로 바꾸고 생성 페이지의 캐릭터 칸 $count개를 비웁니다. 예전 카드 버튼과 같습니다';
  }

  @override
  String get online_sendReplaceDescNone =>
      '긍정 + 부정을 이 이미지 것으로 바꾸고 캐릭터 칸을 비웁니다. 예전 카드 버튼과 같습니다';

  @override
  String get online_sendPromptOnly => '프롬프트만 교체, 캐릭터 칸 유지';

  @override
  String get online_sendPromptOnlyDesc => '작가 조합과 장면 묘사만 빌릴 때';

  @override
  String get online_sendParams => '프롬프트 + 생성 파라미터';

  @override
  String get online_sendParamsDesc =>
      '크기, 시드, 샘플러, 스텝, CFG와 이미지의 캐릭터 칸도 적용. 로컬 갤러리 “파라미터 재사용”과 같습니다';

  @override
  String get online_sendParamsUnavailable =>
      '이 이미지에는 생성 파라미터가 없어 프롬프트만 보낼 수 있습니다';

  @override
  String online_sendNote(Object count) {
    return '생성 페이지의 현재 긍정 프롬프트($count자)가 교체됩니다';
  }

  @override
  String get online_sendNoteEmpty => '생성 페이지의 긍정 프롬프트가 비어 있습니다';

  @override
  String get online_cancel => '취소';

  @override
  String get online_sendGo => '보내고 생성 페이지로';

  @override
  String get online_blacklistDesc => '해당 작품은 표시하지 않습니다';

  @override
  String get online_blacklistAddHint => '태그 추가, Enter로 확인';

  @override
  String online_blacklistSync(Object count) {
    return 'Danbooru 차단 목록 동기화 · $count개';
  }

  @override
  String get online_blacklistScope => '네 소스 모두에 적용; AI TAG는 작품 태그로 매칭';

  @override
  String get online_blacklistEmpty => '차단한 태그가 아직 없습니다';

  @override
  String get online_removeTag => '삭제';

  @override
  String online_appendError(Object page, Object reason) {
    return '$page페이지를 불러오지 못했습니다: $reason';
  }

  @override
  String get online_retryPage => '이 페이지 다시 시도';

  @override
  String online_end(Object count) {
    return '마지막입니다 · 총 $count장';
  }

  @override
  String online_endBlocked(Object count, Object blocked) {
    return '마지막입니다 · 총 $count장 · $blocked장 차단됨';
  }

  @override
  String online_emptyTitle(Object query) {
    return '“$query” 작품을 찾지 못했습니다';
  }

  @override
  String get online_emptyTitleNoQuery => '작품을 찾지 못했습니다';

  @override
  String get online_emptyHint => '아래 조건을 완화해 보세요';

  @override
  String get online_sugNaiOff => '“NAI 이미지만” 해제';

  @override
  String get online_sugClearPrompt => 'Prompt 조건 지우기';

  @override
  String get online_sugAllTime => '전체 기간으로';

  @override
  String get online_sugAllModels => '모든 모델';

  @override
  String get online_sugAllRatings => '모든 등급';

  @override
  String get online_sugNoDate => '기간 제한 해제';

  @override
  String get online_favEmpty => '아직 즐겨찾기가 없습니다';

  @override
  String get online_favEmptyHint => '카드의 ♡ 를 눌러 저장하세요';

  @override
  String online_loadError(Object error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get online_loginDbTitle => 'Danbooru에 로그인해야 즐겨찾기를 볼 수 있습니다';

  @override
  String get online_loginDbDesc =>
      '사용자 이름 + API Key로 로그인하면 사이트와 동기화됩니다.\n카드의 ♡ 도 사이트에 바로 저장됩니다';

  @override
  String get online_loginDb => 'Danbooru 로그인';

  @override
  String get online_loginGbTitle => 'Gelbooru API Key를 설정해야 즐겨찾기를 볼 수 있습니다';

  @override
  String get online_loginGbDesc => 'Gelbooru 즐겨찾기는 여기서 읽기만 가능합니다';

  @override
  String get online_loginGb => 'API Key 설정';

  @override
  String get online_apiKeyHelp => 'API Key 받는 곳';

  @override
  String get online_loginOther =>
      '로그인하기 싫다면? AI TAG 즐겨찾기는 이 기기에 저장되어 계정이 필요 없고, Gelbooru 즐겨찾기는 읽기 전용입니다';

  @override
  String online_viewerPosition(
    Object image,
    Object images,
    Object work,
    Object works,
  ) {
    return '이미지 $image / $images · 작품 $work / $works';
  }

  @override
  String online_viewerWorkPosition(Object work, Object works) {
    return '작품 $work / $works';
  }

  @override
  String get online_close => '닫기';

  @override
  String get online_keyImage => '이미지 전환';

  @override
  String get online_keyWork => '이전 / 다음 작품';

  @override
  String get online_keyInfo => '정보 패널 접기';

  @override
  String get refs_vibeTitle => 'Vibe 라이브러리';

  @override
  String get refs_preciseTitle => '정밀 참조 라이브러리';

  @override
  String get refs_collapseSidebar => '사이드바 접기';

  @override
  String get refs_expandSidebar => '사이드바 펼치기';

  @override
  String get refs_viewAll => '전체';

  @override
  String get refs_viewFavorites => '즐겨찾기';

  @override
  String get refs_viewRecent => '최근 사용';

  @override
  String get refs_viewInGeneration => '생성 페이지에서 사용 중';

  @override
  String get refs_categories => '카테고리';

  @override
  String get refs_newCategory => '새 카테고리';

  @override
  String get refs_newSubcategory => '하위 카테고리 만들기';

  @override
  String get refs_deleteCategory => '카테고리 삭제';

  @override
  String get refs_categoryNameHint => '카테고리 이름';

  @override
  String get refs_noCategories => '아직 카테고리가 없습니다. 가져올 때 만들 수 있습니다';

  @override
  String get refs_uncategorized => '미분류';

  @override
  String get refs_sources => '출처';

  @override
  String get refs_srcPng => 'PNG(Vibe 포함)';

  @override
  String get refs_srcVibeFile => 'Vibe 파일';

  @override
  String get refs_srcBundle => '번들';

  @override
  String get refs_srcRaw => '인코딩 대기 이미지';

  @override
  String get refs_srcImage => '이미지';

  @override
  String get refs_open => '열기';

  @override
  String get refs_types => '참조 유형';

  @override
  String refs_importTypeNoteAll(Object type) {
    return '가져온 이미지는 기본적으로 $type(으)로 저장됩니다. 왼쪽에서 유형을 먼저 고르면 그 유형으로 저장됩니다.';
  }

  @override
  String refs_importTypeNoteSelected(Object type) {
    return '가져온 이미지는 $type(으)로 저장됩니다. 왼쪽에서 고른 유형을 따릅니다.';
  }

  @override
  String get refs_preciseOnlyV45 => 'V4.5 전용';

  @override
  String refs_preciseCostNote(Object cost) {
    return '장당 $cost Anlas, Vibe와 동시에 쓸 수 없습니다';
  }

  @override
  String get refs_searchVibe => '이름, 태그 검색';

  @override
  String get refs_searchPrecise => '이름 검색';

  @override
  String get refs_sortLastUsed => '최근 사용';

  @override
  String get refs_sortCreated => '추가한 날짜';

  @override
  String get refs_sortUsed => '사용 횟수';

  @override
  String get refs_sortName => '이름';

  @override
  String get refs_sortAsc => '오름차순';

  @override
  String get refs_sortDesc => '내림차순';

  @override
  String get refs_sizeSmall => '작게';

  @override
  String get refs_sizeMedium => '중';

  @override
  String get refs_sizeLarge => '대';

  @override
  String get refs_currentModel => '현재 모델';

  @override
  String get refs_usable => '사용 가능';

  @override
  String get refs_unusable => '사용 불가';

  @override
  String get refs_multi => '여러 개 선택';

  @override
  String get refs_multiDone => '선택 완료';

  @override
  String get refs_import => '가져오기';

  @override
  String get refs_importFiles => '파일 선택…';

  @override
  String get refs_importImages => '이미지 선택…';

  @override
  String get refs_importClipboard => '클립보드에서 붙여넣기';

  @override
  String get refs_more => '더 보기';

  @override
  String get refs_exportAll => '모두 내보내기…';

  @override
  String get refs_openLibraryFolder => '라이브러리 폴더 열기';

  @override
  String get refs_rescan => '폴더 다시 검색';

  @override
  String get refs_reload => '다시 불러오기';

  @override
  String get refs_hideInspector => '검사기 접기';

  @override
  String get refs_showInspector => '검사기 펼치기';

  @override
  String refs_bannerVibeLead(Object model) {
    return '$model은(는) Vibe 전송을 지원하지 않습니다. ';
  }

  @override
  String get refs_bannerVibeBody =>
      'Vibe 정리와 내보내기는 그대로 됩니다. 생성에 쓰려면 V4.5 또는 V4로 바꾸세요';

  @override
  String refs_bannerPreciseLead(Object model) {
    return '$model은(는) 정밀 참조를 지원하지 않습니다. ';
  }

  @override
  String get refs_bannerPreciseBody => '참조 이미지 정리는 그대로 됩니다. 생성에 쓰려면 V4.5로 바꾸세요';

  @override
  String refs_switchTo(Object model) {
    return '$model(으)로 전환';
  }

  @override
  String get refs_quickAll => '전체';

  @override
  String get refs_quickFavorites => '즐겨찾기';

  @override
  String get refs_quickHasRaw => '원본 있음';

  @override
  String get refs_quickNeedsEncoding => '인코딩 필요';

  @override
  String get refs_quickBundles => '번들';

  @override
  String get refs_quickUnused => '사용 안 함';

  @override
  String refs_countVibe(Object count, Object inGen) {
    return '$count개 · 생성 페이지 $inGen개';
  }

  @override
  String refs_countPrecise(Object count, Object inGen) {
    return '$count장 · 생성 페이지 $inGen장';
  }

  @override
  String get refs_noResults => '조건에 맞는 항목이 없습니다';

  @override
  String refs_noResultsFor(Object query) {
    return '“$query”에 대한 결과가 없습니다';
  }

  @override
  String get refs_clearFilters => '필터 지우기';

  @override
  String get refs_addShort => '생성에 추가';

  @override
  String get refs_sendPrecise => '정밀 참조로 보내기';

  @override
  String get refs_openBundle => '번들 열기';

  @override
  String get refs_detail => '자세히';

  @override
  String get refs_addToGeneration => '생성 페이지에 추가';

  @override
  String get refs_replaceVibes => '생성 페이지의 Vibe 교체';

  @override
  String get refs_replacePrecise => '현재 정밀 참조 교체';

  @override
  String get refs_sendImg2Img => 'img2img로 보내기';

  @override
  String get refs_saveAsVibe => 'Vibe 라이브러리에 저장';

  @override
  String get refs_favorite => '즐겨찾기';

  @override
  String get refs_unfavorite => '즐겨찾기 해제';

  @override
  String get refs_replacePreview => '미리보기 바꾸기…';

  @override
  String get refs_exportEllipsis => '내보내기…';

  @override
  String get refs_showInFolder => '폴더에서 보기';

  @override
  String get refs_copyImage => '이미지 복사';

  @override
  String get refs_delete => '삭제';

  @override
  String refs_selected(Object count) {
    return '$count개 선택';
  }

  @override
  String get refs_moveTo => '이동';

  @override
  String get refs_export => '내보내기';

  @override
  String get refs_emptyVibeTitle => '이미지나 Vibe 파일을 여기에 놓으세요';

  @override
  String get refs_emptyPreciseTitle => '참조 이미지를 여기에 놓으세요';

  @override
  String get refs_emptyVibeDesc =>
      'PNG(Vibe 포함), .naiv4vibe, .naiv4vibebundle, 일반 이미지를 지원합니다.\n일반 이미지는 원본으로 저장하고 처음 생성에 쓸 때 인코딩합니다';

  @override
  String get refs_emptyPreciseDesc =>
      '캐릭터 설정화나 화풍 샘플 등 여러 장을 한 번에 놓을 수 있습니다.\n유형, 강도, 충실도를 저장해 보낼 때 그대로 씁니다';

  @override
  String get refs_pickFiles => '파일 선택';

  @override
  String get refs_pasteClipboard => '붙여넣기';

  @override
  String get refs_emptyFromResultVibe => '생성 결과 우클릭 → Vibe 라이브러리에 저장';

  @override
  String get refs_emptyFromResultPrecise => '생성 결과 우클릭 → 정밀 참조 라이브러리에 저장';

  @override
  String get refs_emptyFromGallery => '로컬 갤러리에서도 가능';

  @override
  String get refs_emptyHelpTitle => 'Vibe와 정밀 참조의 차이';

  @override
  String refs_emptyHelpBody(Object cost) {
    return 'Vibe: 전체 분위기와 화풍을 빌리며 여러 장을 겹칠 수 있습니다(V4 / V4.5, V5 제외). 정밀 참조: 한 이미지의 인물이나 화풍을 더 정확히 따르며 장당 $cost Anlas(V4.5 전용). 둘은 동시에 쓸 수 없습니다.';
  }

  @override
  String refs_dropTitle(Object count) {
    return '놓으면 파일 $count개 가져오기';
  }

  @override
  String get refs_dropVibeDesc => '먼저 가져오기 창에서 확인합니다. 바로 Anlas가 차감되지 않습니다';

  @override
  String get refs_dropPreciseDesc => '왼쪽에서 고른 유형으로 저장합니다';

  @override
  String refs_dropVibePngs(Object count) {
    return 'Vibe 포함 PNG $count개';
  }

  @override
  String refs_dropVibeFiles(Object count) {
    return 'Vibe 파일 $count개';
  }

  @override
  String refs_dropBundles(Object count) {
    return '번들 $count개';
  }

  @override
  String refs_dropImages(Object count) {
    return '일반 이미지 $count장';
  }

  @override
  String get refs_inGeneration => '사용 중';

  @override
  String get refs_tag => '태그';

  @override
  String get refs_strengthShort => '강도';

  @override
  String get refs_infoShort => '정보';

  @override
  String get refs_fidelityShort => '충실';

  @override
  String refs_encModelOff(Object model) {
    return '$model 사용 불가';
  }

  @override
  String refs_encModelOffDesc(Object model) {
    return '$model은(는) Vibe 전송을 지원하지 않습니다. V4.5 / V4로 바꾸면 쓸 수 있습니다';
  }

  @override
  String refs_encReady(Object model) {
    return '인코딩됨 · $model';
  }

  @override
  String refs_encReadyShort(Object model) {
    return '$model 인코딩됨';
  }

  @override
  String get refs_encReadyDesc => '현재 모델에서 바로 쓸 수 있고 인코딩 비용이 없습니다';

  @override
  String get refs_encOnUse => '사용 시 인코딩';

  @override
  String refs_encOnUseDesc(Object cost) {
    return '아직 인코딩되지 않았습니다. 처음 생성에 쓸 때 인코딩합니다($cost Anlas)';
  }

  @override
  String get refs_encRe => '다시 인코딩 필요';

  @override
  String refs_encReDesc(Object from, Object model, Object cost) {
    return '$from용 인코딩입니다(현재 $model). 사용할 때 원본으로 다시 인코딩합니다($cost Anlas)';
  }

  @override
  String refs_encUnusable(Object model) {
    return '$model에서 사용 불가';
  }

  @override
  String refs_encUnusableDesc(Object from, Object model) {
    return '$from 인코딩만 있고 원본이 없어 $model용으로 다시 인코딩할 수 없습니다';
  }

  @override
  String get refs_trayVibe => '생성 페이지의 Vibe';

  @override
  String get refs_trayPrecise => '생성 페이지의 정밀 참조';

  @override
  String refs_trayVibeCost(Object free, Object extra) {
    return '$free개 초과 시 개당 +$extra Anlas';
  }

  @override
  String refs_trayPreciseCost(Object cost, Object total) {
    return '장당 $cost Anlas · 이번 +$total';
  }

  @override
  String get refs_trayHint =>
      '카드를 여기로 끌어 추가, Shift는 전체 교체.\n페이지가 바뀌지 않아 계속 고를 수 있습니다';

  @override
  String get refs_trayDropHere => '카드를 여기에 놓아 추가';

  @override
  String get refs_clear => '비우기';

  @override
  String get refs_goGeneration => '생성 페이지로';

  @override
  String refs_conflict(Object count) {
    return '생성 페이지에 **Vibe $count개**가 있습니다. 정밀 참조가 있으면 Vibe는 전송되지 않습니다(공식 비호환)';
  }

  @override
  String refs_conflictPaused(Object count) {
    return '생성 페이지의 **Vibe $count개**는 일시 중지됨. 정밀 참조만 보냅니다';
  }

  @override
  String get refs_pauseVibes => 'Vibe 일시 중지';

  @override
  String get refs_resumeVibes => 'Vibe 재개';

  @override
  String get refs_inspector => '검사기';

  @override
  String refs_selectedN(Object count) {
    return '$count개 선택됨';
  }

  @override
  String get refs_noSelectionVibe => '카드를 선택하면 파라미터와 인코딩 상태가 보입니다';

  @override
  String get refs_noSelectionPrecise => '참조 이미지를 선택하면 유형과 파라미터가 보입니다';

  @override
  String get refs_rename => '이름 바꾸기';

  @override
  String get refs_replace => '교체';

  @override
  String get refs_replaceVibesTip => '생성 페이지의 Vibe를 모두 교체';

  @override
  String get refs_strength => '강도';

  @override
  String get refs_strengthDesc => '높을수록 이 이미지 느낌에 가까워집니다';

  @override
  String get refs_infoExtracted => '정보 추출';

  @override
  String refs_infoDesc(Object cost) {
    return '높을수록 디테일을 더 가져옵니다. 바꾸면 원본으로 다시 인코딩합니다($cost Anlas)';
  }

  @override
  String get refs_infoLocked => '인코딩 데이터만 있고 원본이 없어 정보 추출을 바꿀 수 없습니다';

  @override
  String get refs_changedNote => '변경은 이번 전송에만 적용됩니다';

  @override
  String get refs_saveDefault => '기본값으로 저장';

  @override
  String get refs_revert => '되돌리기';

  @override
  String get refs_encOnUseBody => '아직 인코딩되지 않았습니다. 처음 생성에 쓸 때 인코딩합니다.';

  @override
  String refs_encReBody(String from, String model) {
    return '$from용 인코딩입니다(현재 $model). 사용할 때 원본으로 다시 인코딩합니다.';
  }

  @override
  String refs_encodeAction(String model) {
    return '$model용으로 인코딩';
  }

  @override
  String refs_encodingPrice(int cost) {
    return '$cost Anlas';
  }

  @override
  String refs_encodeNow(Object model, Object cost) {
    return '지금 $model용으로 인코딩 · $cost Anlas';
  }

  @override
  String refs_bundleNote(Object count) {
    return '이 번들의 Vibe $count개는 각각 강도와 정보 추출 값을 가집니다. 번들을 열어 따로 조정하세요.';
  }

  @override
  String refs_bundleOf(Object count) {
    return '번들 · $count개';
  }

  @override
  String get refs_organize => '정리';

  @override
  String get refs_category => '카테고리';

  @override
  String get refs_tags => '태그';

  @override
  String get refs_used => '사용';

  @override
  String get refs_neverUsed => '사용한 적 없음';

  @override
  String refs_usedTimes(Object count, Object last) {
    return '$count회 · 마지막 $last';
  }

  @override
  String get refs_added => '추가';

  @override
  String get refs_file => '파일';

  @override
  String get refs_original => '원본';

  @override
  String refs_plusAnlas(Object cost) {
    return '+$cost Anlas';
  }

  @override
  String get refs_alsoSaveVibe => 'Vibe로도 저장';

  @override
  String get refs_referenceWhat => '참조 대상';

  @override
  String get refs_typeCharacter => '캐릭터';

  @override
  String get refs_typeStyle => '화풍';

  @override
  String get refs_typeBoth => '캐릭터+화풍';

  @override
  String get refs_typeCharacterDesc => '인물의 얼굴, 머리, 옷을 유지하고 화풍은 프롬프트를 따릅니다';

  @override
  String get refs_typeStyleDesc => '화풍, 배색, 붓질만 빌리고 인물은 따지지 않습니다';

  @override
  String get refs_typeBothDesc => '인물과 화풍을 모두 참조합니다';

  @override
  String get refs_preciseStrength => '참조 강도';

  @override
  String get refs_preciseStrengthDesc => '높을수록 참조 이미지와 비슷해집니다';

  @override
  String get refs_fidelity => '충실도';

  @override
  String get refs_fidelityDesc => '높을수록 디테일에 충실하고 낮을수록 자유롭습니다';

  @override
  String get refs_preciseDefaultsNote =>
      '여기서 바꾸는 값은 기본값이며 보낼 때 그대로 씁니다. 숫자 칸에는 0–1 밖의 값도 넣을 수 있습니다';

  @override
  String get refs_showInFolderShort => '폴더 열기';

  @override
  String get refs_pickHint => '카드를 체크하면 여기서 한꺼번에 설정할 수 있습니다';

  @override
  String get refs_multiAddTitle => '함께 생성 페이지에 추가';

  @override
  String get refs_multiSendTitle => '함께 정밀 참조로 보내기';

  @override
  String refs_multiFree(Object free) {
    return '$free개까지는 추가 비용이 없습니다. ';
  }

  @override
  String refs_multiExtra(Object free, Object extra, Object total) {
    return '$free개 초과 시 개당 +$extra Anlas: 이미지당 $total Anlas 추가. ';
  }

  @override
  String refs_multiOverMax(Object max) {
    return '상한 $max개를 넘는 것은 추가되지 않습니다. ';
  }

  @override
  String refs_multiEncodes(Object count, Object names, Object cost) {
    return '그중 $count개는 인코딩이 필요합니다($names, 개당 $cost Anlas, 한 번만). ';
  }

  @override
  String refs_multiAlready(Object count) {
    return '$count개는 이미 생성 페이지에 있어 중복 추가되지 않습니다.';
  }

  @override
  String refs_multiPreciseCost(Object cost, Object total) {
    return '장당 $cost Anlas, 이미지당 총 $total Anlas.';
  }

  @override
  String get refs_unify => '일괄 설정';

  @override
  String get refs_mixed => '혼합';

  @override
  String refs_unifyVibeNote(Object count) {
    return '끌면 $count개의 기본값을 함께 바꿉니다. 정보 추출은 다시 인코딩해야 해서 바꾸지 않습니다';
  }

  @override
  String refs_unifyPreciseNote(Object count) {
    return '클릭하면 $count장 모두 이 유형으로 바뀝니다';
  }

  @override
  String get refs_moveToCategory => '카테고리로 이동';

  @override
  String get refs_addTag => '태그 추가';

  @override
  String get refs_packBundle => '번들로 묶기';

  @override
  String get refs_close => '닫기';

  @override
  String get refs_cancel => '취소';

  @override
  String get refs_remove => '제거';

  @override
  String get refs_prev => '이전';

  @override
  String get refs_next => '다음';

  @override
  String get refs_switch => '전환';

  @override
  String get refs_dropReplacePreview => '여기에 이미지를 놓으면 미리보기를 바꿉니다(인코딩은 그대로)';

  @override
  String refs_bundleOfVibes(Object count) {
    return '번들 · Vibe $count개';
  }

  @override
  String refs_bundleAll(Object count) {
    return '전체 $count개';
  }

  @override
  String refs_bundleOnlyChecked(Object count) {
    return '체크한 $count개만';
  }

  @override
  String get refs_bundleScopeNote => '보낼 때 각 Vibe의 강도와 정보 추출 값을 씁니다';

  @override
  String get refs_splitBundle => '개별 Vibe로 나누기';

  @override
  String get refs_bundleNoteLong =>
      '파라미터를 바꾼 뒤 “번들에 저장”으로 보관할 수 있습니다. 저장하지 않으면 이번 전송에만 적용됩니다. ';

  @override
  String refs_bundleAllEncoded(Object count, Object model) {
    return '$count개 모두 $model용으로 인코딩됨';
  }

  @override
  String get refs_saveToBundle => '번들에 저장';

  @override
  String get refs_cover => '표지';

  @override
  String get refs_setCover => '표지로 설정';

  @override
  String refs_exportTitle(Object count) {
    return 'Vibe $count개 내보내기';
  }

  @override
  String get refs_exportListNote =>
      '라이브러리에서 여러 개를 골라 “내보내기”를 누르세요. 여기서 뺄 수도 있습니다';

  @override
  String get refs_exportAs => '내보낼 형식';

  @override
  String get refs_fmtVibeFile => '개별 Vibe 파일';

  @override
  String get refs_fmtVibeFileDesc =>
      '.naiv4vibe, 하나씩. 공식 사이트와 다른 클라이언트에서도 가져올 수 있습니다';

  @override
  String get refs_fmtBundle => '번들 하나로';

  @override
  String refs_fmtBundleDesc(Object count) {
    return '.naiv4vibebundle, $count개를 한 파일로';
  }

  @override
  String get refs_fmtPng => 'PNG에 포함';

  @override
  String get refs_fmtPngDesc => '이미지에 Vibe가 들어 있어 끌어다 놓으면 됩니다. 한 번에 하나만';

  @override
  String get refs_fmtEncoded => '인코딩 텍스트';

  @override
  String get refs_fmtEncodedDesc => 'JSON / Base64, 스크립트와 고급 용도';

  @override
  String get refs_options => '옵션';

  @override
  String get refs_optThumbs => '썸네일 포함';

  @override
  String get refs_optThumbsDesc => '파일이 조금 커지지만 가져올 때 바로 보입니다';

  @override
  String get refs_optZip => 'ZIP으로 압축';

  @override
  String refs_optZipDesc(Object count) {
    return '파일 $count개를 압축 파일 하나로';
  }

  @override
  String get refs_saveTo => '저장 위치';

  @override
  String get refs_choose => '선택';

  @override
  String refs_exportSummary(Object count, Object ext) {
    return '$ext 파일 $count개를 만듭니다';
  }

  @override
  String refs_exportSummaryZip(Object count, Object ext) {
    return 'ZIP 1개를 만듭니다($ext 파일 $count개)';
  }

  @override
  String refs_deleteOne(Object name) {
    return '“$name”을(를) 삭제할까요?';
  }

  @override
  String refs_deleteMany(Object count) {
    return '$count개 항목을 삭제할까요?';
  }

  @override
  String get refs_deleteVibeDesc =>
      'Vibe 라이브러리에서 제거합니다. 생성 페이지에서 쓰는 것은 영향을 받지 않습니다.';

  @override
  String get refs_deletePreciseDesc =>
      '라이브러리에서 제거합니다. 생성 페이지에서 쓰는 것은 영향을 받지 않습니다.';

  @override
  String refs_importTitle(Object count) {
    return '파일 $count개 가져오기';
  }

  @override
  String get refs_importSubtitle => '끌어 놓기, 선택, 붙여넣기 모두 이 창에서 확인합니다';

  @override
  String get refs_importMore => '파일 추가';

  @override
  String get refs_importPutIn => '모두 넣을 곳';

  @override
  String get refs_importAddTags => '태그 추가';

  @override
  String get refs_importTagsHint => '입력 후 Enter';

  @override
  String get refs_importPlainImages => '일반 이미지';

  @override
  String get refs_importEncodeLater => '사용할 때 인코딩';

  @override
  String refs_importEncodeNow(Object cost) {
    return '지금 인코딩 · 장당 $cost Anlas';
  }

  @override
  String get refs_importName => '이름';

  @override
  String get refs_importResult => '인식 결과';

  @override
  String refs_recPng(Object model) {
    return 'Vibe 포함 PNG · $model 인코딩';
  }

  @override
  String refs_recVibeFile(Object model) {
    return 'Vibe 파일 · $model 인코딩';
  }

  @override
  String refs_recBundle(Object count) {
    return '번들 · Vibe $count개';
  }

  @override
  String get refs_recImage => '일반 이미지 · 인코딩 전';

  @override
  String get refs_recImageDup => '일반 이미지 · 같은 이름 있음';

  @override
  String get refs_recFree => '그대로 가져오기, 무료';

  @override
  String refs_recReencode(Object model) {
    return '$model에서 쓰려면 다시 인코딩해야 합니다(원본이 없으면 불가)';
  }

  @override
  String refs_recBundleNote(Object count) {
    return '통째로 = 카드 1장, 나누기 = $count장';
  }

  @override
  String get refs_recEncodeLater => '원본을 저장하고 처음 생성에 쓸 때 그 모델용으로 인코딩';

  @override
  String refs_recEncodeNow(Object cost) {
    return '가져올 때 인코딩, 장당 $cost Anlas';
  }

  @override
  String get refs_bundleWhole => '통째로';

  @override
  String refs_bundleSplit(Object count) {
    return '$count개로 나누기';
  }

  @override
  String get refs_bundlePick => '골라서';

  @override
  String get refs_dupExists => '같은 이름이 이미 있습니다';

  @override
  String get refs_dupKeepBoth => '둘 다 유지';

  @override
  String get refs_dupOverwrite => '덮어쓰기';

  @override
  String get refs_dupSkip => '건너뛰기';

  @override
  String refs_importSummary(Object files, Object cards) {
    return '파일 $files개 → 카드 $cards장 추가';
  }

  @override
  String refs_importNow(Object cost) {
    return ' · 지금 $cost Anlas 차감';
  }

  @override
  String refs_importLater(Object count, Object cost) {
    return ' · 일반 이미지 $count장은 처음 쓸 때 인코딩(장당 $cost Anlas)';
  }

  @override
  String get refs_pickerVibeTitle => 'Vibe 라이브러리에서 추가';

  @override
  String get refs_pickerPreciseTitle => '정밀 참조 라이브러리에서 추가';

  @override
  String get refs_openVibeLibrary => 'Vibe 라이브러리 열기';

  @override
  String get refs_openPreciseLibrary => '라이브러리 열기';

  @override
  String get refs_recentUsed => '최근 사용';

  @override
  String get refs_inUse => '사용 중';

  @override
  String refs_pickedN(Object count) {
    return '$count개 선택';
  }

  @override
  String refs_pickerAfterVibe(Object count, Object max) {
    return ' · 추가 후 $count/$max';
  }

  @override
  String refs_pickerAfterPrecise(Object count) {
    return ' · 추가 후 $count장';
  }

  @override
  String refs_pickerEncode(Object name, Object model, Object cost) {
    return '“$name”은(는) $model용 인코딩 필요 · $cost Anlas';
  }

  @override
  String refs_pickerEncodeMore(Object count) {
    return '그 밖에 $count개도 인코딩 필요';
  }

  @override
  String refs_pickerExtra(Object free, Object extra) {
    return '$free개 초과 시 +$extra Anlas';
  }

  @override
  String refs_pickerPreciseCost(Object cost, Object total) {
    return '장당 $cost Anlas · 총 $total Anlas';
  }

  @override
  String get refs_replaceExisting => '기존 교체';

  @override
  String refs_appendN(Object count) {
    return '$count개 추가';
  }

  @override
  String get refs_timeNever => '사용 안 함';

  @override
  String get refs_timeJustNow => '방금';

  @override
  String refs_timeMinutes(Object count) {
    return '$count분 전';
  }

  @override
  String refs_timeHours(Object count) {
    return '$count시간 전';
  }

  @override
  String get refs_timeYesterday => '어제';

  @override
  String refs_timeDays(Object count) {
    return '$count일 전';
  }

  @override
  String refs_timeMonthDay(Object month, Object day) {
    return '$month월 $day일';
  }

  @override
  String get blocks_title => '블록 라이브러리';

  @override
  String get blocks_translationMark => '번';

  @override
  String get blocks_add => '추가';

  @override
  String get blocks_cancel => '취소';

  @override
  String get blocks_close => '닫기';

  @override
  String get blocks_delete => '삭제';

  @override
  String get blocks_done => '완료';

  @override
  String get blocks_save => '저장';

  @override
  String get blocks_saveEnter => '저장 ⏎';

  @override
  String get blocks_more => '더 보기';

  @override
  String get blocks_back => '뒤로';

  @override
  String get blocks_rename => '이름 바꾸기';

  @override
  String get blocks_edit => '편집';

  @override
  String get blocks_copy => '복사';

  @override
  String get blocks_export => '내보내기';

  @override
  String get blocks_apply => '적용';

  @override
  String get blocks_off => '끔';

  @override
  String get blocks_to => '~';

  @override
  String blocks_items(Object count) {
    return '$count개 항목';
  }

  @override
  String get blocks_itemUnit => '개';

  @override
  String blocks_usedTimes(Object count) {
    return '$count회 사용';
  }

  @override
  String blocks_nBlocks(Object count) {
    return '$count개';
  }

  @override
  String get blocks_untitled => '제목 없음';

  @override
  String get blocks_favorite => '즐겨찾기';

  @override
  String get blocks_unfavorite => '즐겨찾기 해제';

  @override
  String get blocks_favorites => '즐겨찾기';

  @override
  String get blocks_recent => '최근 사용';

  @override
  String get blocks_uncategorized => '미분류';

  @override
  String get blocks_positive => '긍정';

  @override
  String get blocks_negative => '부정';

  @override
  String blocks_positiveN(Object count) {
    return '긍정 $count';
  }

  @override
  String blocks_negativeN(Object count) {
    return '부정 $count';
  }

  @override
  String get blocks_content => '내용';

  @override
  String get blocks_name => '이름';

  @override
  String get blocks_folder => '폴더';

  @override
  String get blocks_folders => '폴더';

  @override
  String get blocks_tags => '태그';

  @override
  String get blocks_tag => '태그';

  @override
  String get blocks_icon => '아이콘';

  @override
  String get blocks_color => '색상';

  @override
  String get blocks_look => '스타일';

  @override
  String get blocks_appearance => '모양';

  @override
  String get blocks_thumb => '미리보기';

  @override
  String get blocks_preview => '미리보기';

  @override
  String get blocks_params => '첨부 설정';

  @override
  String get blocks_classify => '분류';

  @override
  String get blocks_lookClassic => '클래식';

  @override
  String get blocks_lookStripes => '줄무늬';

  @override
  String get blocks_lookDots => '도트';

  @override
  String get blocks_lookSolid => '단색';

  @override
  String get blocks_lookGradient => '그라데이션';

  @override
  String get blocks_lookTranslation => '번역';

  @override
  String get blocks_hasParams => '설정 포함';

  @override
  String get blocks_hasNegative => '부정 포함';

  @override
  String get blocks_hintClick => '클릭해 삽입';

  @override
  String get blocks_hintDrag => '드래그해 배치';

  @override
  String get blocks_hintRightClick => '우클릭으로 더 보기';

  @override
  String get blocks_searchHint => '블록 검색…';

  @override
  String get blocks_filterAll => '전체';

  @override
  String blocks_allN(Object count) {
    return '전체 $count';
  }

  @override
  String get blocks_searchResults => '검색 결과';

  @override
  String get blocks_noResults => '일치하는 블록이 없습니다';

  @override
  String get blocks_noFavorites => '아직 즐겨찾기가 없습니다. 블록을 우클릭 → 즐겨찾기.';

  @override
  String get blocks_dockEmpty =>
      '블록 라이브러리가 비어 있습니다. 자주 쓰는 프롬프트를 블록으로 저장하면 클릭 한 번으로 넣을 수 있습니다.';

  @override
  String get blocks_dockHint => '클릭하면 커서 위치에 삽입 · 프롬프트로 드래그해 배치';

  @override
  String get blocks_openLibrary => '블록 라이브러리에서 열기';

  @override
  String get blocks_newBlock => '새 블록';

  @override
  String get blocks_newBlockTip => '새 블록 (Ctrl+N)';

  @override
  String get blocks_insertAtCursor => '커서 위치에 삽입';

  @override
  String get blocks_addToPalette => '팔레트에 추가';

  @override
  String get blocks_showInLibrary => '라이브러리에서 보기';

  @override
  String get blocks_missing => '삭제된 블록';

  @override
  String get blocks_modeFixed => '고정';

  @override
  String get blocks_modeSequential => '순서';

  @override
  String get blocks_modeRandom => '무작위';

  @override
  String blocks_summaryRandom(Object range, Object pool) {
    return '무작위 · 매번 $range개 · 풀 $pool개';
  }

  @override
  String blocks_summarySequential(Object range) {
    return '순서 · 매번 $range개 · 한 장마다 한 칸씩';
  }

  @override
  String get blocks_drawnThisTime => '이번 결과';

  @override
  String get blocks_lock => '잠금';

  @override
  String get blocks_unlock => '잠금 해제';

  @override
  String get blocks_lockTip => '이 결과를 고정하고 생성 시 다시 뽑지 않음';

  @override
  String get blocks_unlockTip => '해제하면 생성 시 다시 뽑습니다';

  @override
  String get blocks_reroll => '다시 뽑기';

  @override
  String get blocks_rerollLocked => '잠김 — 다시 뽑으려면 잠금 해제';

  @override
  String blocks_skipped(Object percent) {
    return '이번엔 등장 안 함 (확률 $percent)';
  }

  @override
  String blocks_sendPrefix(Object text) {
    return '전송: $text';
  }

  @override
  String blocks_seqPosition(Object index, Object total) {
    return '$index / $total번째';
  }

  @override
  String get blocks_seqLocked => '잠김, 자동으로 넘어가지 않음';

  @override
  String get blocks_prevItem => '이전 항목';

  @override
  String get blocks_nextItem => '다음 항목';

  @override
  String blocks_prevValue(Object value) {
    return '이전 $value';
  }

  @override
  String blocks_nextValue(Object value) {
    return '다음 $value';
  }

  @override
  String get blocks_paramsTitle => '이 블록에는 생성 설정이 있습니다';

  @override
  String get blocks_drawMode => '뽑기 방식';

  @override
  String blocks_fixedExplain(Object count) {
    return '고정: 매번 $count개 항목을 그대로 넣습니다. 순서나 무작위로 바꾸면 여기서 개수와 가중치를 설정합니다.';
  }

  @override
  String get blocks_ruleCount => '개수';

  @override
  String get blocks_ruleWeight => '가중치';

  @override
  String get blocks_ruleShow => '확률';

  @override
  String get blocks_ruleEach => '매번';

  @override
  String get blocks_ruleItemUnit => '개';

  @override
  String get blocks_ruleWrap => '끝나면 처음부터';

  @override
  String get blocks_adjust => '조정';

  @override
  String get blocks_appliesTo => '적용 대상';

  @override
  String get blocks_disable => '비활성화';

  @override
  String get blocks_enable => '활성화';

  @override
  String get blocks_editBlock => '블록 편집';

  @override
  String get blocks_removeInstanceTip => '프롬프트에서 제거';

  @override
  String get blocks_removeInstance => '프롬프트에서 제거';

  @override
  String get blocks_copySend => '전송 텍스트 복사';

  @override
  String get blocks_evolutionOn => '유전 블록으로 지정';

  @override
  String get blocks_evolutionOff => '유전 해제';

  @override
  String get blocks_rulesTitle => '뽑기 규칙';

  @override
  String get blocks_rulesHint => '완료를 누르면 적용';

  @override
  String get blocks_rulesDirty => '변경됨 · 완료 시 적용';

  @override
  String get blocks_modeFixedDesc => '매번 전체를 그대로';

  @override
  String get blocks_modeSequentialDesc => '순서대로, 한 장마다 한 칸';

  @override
  String get blocks_modeRandomDesc => '매번 풀에서 무작위로 몇 개';

  @override
  String get blocks_drawEach => '매번';

  @override
  String get blocks_takeEach => '매번';

  @override
  String blocks_poolSize(Object count) {
    return '풀 $count개';
  }

  @override
  String get blocks_outputOrder => '출력 순서';

  @override
  String get blocks_orderDrawn => '뽑힌 순서';

  @override
  String get blocks_orderOriginal => '원래 순서';

  @override
  String get blocks_seqExplain => '한 장마다 한 칸 이동, 잠그면 현재 항목에 머뭅니다.';

  @override
  String get blocks_randomWeight => '무작위 가중치';

  @override
  String get blocks_randomWeightHint => '각 항목에 0.8::…:: 가중치 적용';

  @override
  String get blocks_weightMin => '최소';

  @override
  String get blocks_weightAverage => '최빈';

  @override
  String get blocks_weightMax => '최대';

  @override
  String get blocks_distribution => '분포';

  @override
  String get blocks_distFocused => '집중';

  @override
  String get blocks_distBalanced => '균형';

  @override
  String get blocks_distSpread => '분산';

  @override
  String get blocks_distCustom => '사용자 지정';

  @override
  String get blocks_advanced => '고급';

  @override
  String get blocks_leftDispersion => '왼쪽 분산';

  @override
  String get blocks_rightDispersion => '오른쪽 분산';

  @override
  String get blocks_softBalance => '소프트 밸런스';

  @override
  String get blocks_softBalanceHint => '여러 항목의 평균을 최빈값으로 당김';

  @override
  String get blocks_softBalanceStrength => '강도';

  @override
  String get blocks_probability => '등장 확률';

  @override
  String get blocks_probabilityHint => '100% 미만이면 블록 전체가 빠질 때가 있습니다';

  @override
  String get blocks_previewHint => '이 규칙으로 4번 뽑기';

  @override
  String get blocks_resample => '다시';

  @override
  String get blocks_sampleSkipped => '(등장 안 함)';

  @override
  String get blocks_resetDefault => '기본값으로';

  @override
  String get blocks_discard => '변경 취소';

  @override
  String get blocks_allBlocks => '모든 블록';

  @override
  String get blocks_collections => '컬렉션';

  @override
  String get blocks_newCollection => '새 컬렉션';

  @override
  String get blocks_collectionName => '컬렉션 이름';

  @override
  String get blocks_noCollections =>
      '카드를 여기 컬렉션으로 드래그하세요. 한 블록이 여러 컬렉션에 들어갈 수 있습니다.';

  @override
  String get blocks_deleteCollection => '컬렉션 삭제';

  @override
  String get blocks_newFolder => '새 폴더';

  @override
  String get blocks_newSubfolder => '하위 폴더 만들기';

  @override
  String get blocks_folderName => '폴더 이름';

  @override
  String get blocks_deleteFolder => '폴더 삭제…';

  @override
  String get blocks_moveUp => '위로';

  @override
  String get blocks_moveDown => '아래로';

  @override
  String get blocks_moveToTop => '최상위로 이동';

  @override
  String get blocks_tagName => '태그 이름';

  @override
  String get blocks_tagColor => '색 바꾸기';

  @override
  String get blocks_deleteTag => '태그 삭제';

  @override
  String get blocks_collapseSidebar => '사이드바 접기';

  @override
  String get blocks_expandSidebar => '사이드바 펼치기';

  @override
  String get blocks_importExport => '가져오기 / 내보내기';

  @override
  String get blocks_importTxt => 'TXT 가져오기…';

  @override
  String get blocks_importFolder => '폴더 가져오기…';

  @override
  String get blocks_importCuration => '정리해서 가져오기…';

  @override
  String get blocks_exportBackup => '라이브러리 백업 내보내기';

  @override
  String get blocks_importBackup => '라이브러리 백업 가져오기…';

  @override
  String blocks_dropMoveTo(Object name) {
    return '“$name”(으)로 이동';
  }

  @override
  String blocks_dropCopyTo(Object name) {
    return '“$name”(으)로 복사';
  }

  @override
  String blocks_dropAddTo(Object name) {
    return '“$name”에 추가';
  }

  @override
  String get blocks_searchLibrary => '제목, 내용, 태그 검색';

  @override
  String get blocks_sortCustom => '사용자 순서';

  @override
  String get blocks_sortUpdated => '최근 수정';

  @override
  String get blocks_sortTitle => '이름';

  @override
  String get blocks_sortColor => '색상';

  @override
  String get blocks_sortIcon => '아이콘';

  @override
  String get blocks_sortAsc => '오름차순';

  @override
  String get blocks_sortDesc => '내림차순';

  @override
  String get blocks_viewGrid => '그리드';

  @override
  String get blocks_viewList => '목록';

  @override
  String get blocks_multiSelect => '여러 개 선택';

  @override
  String get blocks_multiDone => '선택 완료';

  @override
  String get blocks_hideInspector => '세부 정보 숨기기';

  @override
  String get blocks_showInspector => '세부 정보 표시';

  @override
  String get blocks_quickImage => '미리보기 있음';

  @override
  String get blocks_quickNegative => '부정 포함';

  @override
  String get blocks_quickParams => '설정 포함';

  @override
  String get blocks_cardSize => '카드 크기';

  @override
  String get blocks_noMatch => '조건에 맞는 블록이 없습니다';

  @override
  String get blocks_noMatchBody => '다른 키워드를 쓰거나 빠른 필터를 지우세요.';

  @override
  String get blocks_clearFilters => '필터 지우기';

  @override
  String get blocks_insert => '삽입';

  @override
  String get blocks_insertToPrompt => '프롬프트에 삽입';

  @override
  String get blocks_miniNegative => '부정';

  @override
  String get blocks_miniParams => '설정';

  @override
  String get blocks_colName => '이름';

  @override
  String get blocks_colItems => '항목';

  @override
  String get blocks_colFolder => '폴더';

  @override
  String get blocks_colUsed => '사용';

  @override
  String get blocks_colModified => '수정';

  @override
  String blocks_selectedN(Object count) {
    return '$count개 선택';
  }

  @override
  String blocks_selectedBlocksN(Object count) {
    return '블록 $count개 선택';
  }

  @override
  String get blocks_moveTo => '이동…';

  @override
  String get blocks_noTags => '아직 태그가 없습니다';

  @override
  String get blocks_emptyTitle => '블록 라이브러리가 비어 있습니다';

  @override
  String get blocks_emptyBody =>
      '화가 풀, 캐릭터, 의상, 품질 태그처럼 자주 쓰는 프롬프트를 블록으로 저장하세요. 넣은 뒤 고정, 순서, 무작위로 쓸 수 있습니다.';

  @override
  String get blocks_duplicate => '복제';

  @override
  String get blocks_copyContent => '내용 복사';

  @override
  String get blocks_applyParams => '첨부 설정 적용';

  @override
  String get blocks_exportTxt => 'TXT로 내보내기';

  @override
  String get blocks_removeFromCollection => '컬렉션에서 빼기';

  @override
  String blocks_deleteOne(Object name) {
    return '“$name”을(를) 삭제할까요?';
  }

  @override
  String blocks_deleteMany(Object count) {
    return '블록 $count개를 삭제할까요?';
  }

  @override
  String get blocks_deleteBody =>
      '프롬프트에 이미 넣은 인스턴스는 “삭제된 블록”으로 표시됩니다. 실행 취소할 수 있습니다.';

  @override
  String get blocks_details => '세부 정보';

  @override
  String get blocks_noSelection =>
      '카드를 클릭해 세부 정보 보기. 더블클릭으로 편집, Enter로 프롬프트에 삽입.';

  @override
  String get blocks_changeThumb => '변경 / 조정';

  @override
  String get blocks_reading => '번역 읽기';

  @override
  String get blocks_needsReview => '검토 필요';

  @override
  String get blocks_applyToCurrent => '지금 적용';

  @override
  String get blocks_noParams => '없음. 넣어도 현재 설정은 바뀌지 않습니다.';

  @override
  String get blocks_paramModel => '모델';

  @override
  String get blocks_paramSteps => '스텝';

  @override
  String get blocks_paramGuidance => '가이던스';

  @override
  String get blocks_paramRescale => '리스케일';

  @override
  String get blocks_paramSampler => '샘플러';

  @override
  String get blocks_paramNoise => '노이즈';

  @override
  String blocks_steps(Object count) {
    return '$count 스텝';
  }

  @override
  String blocks_guidance(Object value) {
    return '가이던스 $value';
  }

  @override
  String blocks_rescale(Object value) {
    return '리스케일 $value';
  }

  @override
  String get blocks_newTagInEdit => '새 태그…';

  @override
  String blocks_modifiedAt(Object time) {
    return '$time 수정';
  }

  @override
  String blocks_createdAt(Object date) {
    return '$date 생성';
  }

  @override
  String blocks_sourceFile(Object path) {
    return '원본 파일 $path';
  }

  @override
  String get blocks_sourceSynced => '파일과 일치';

  @override
  String get blocks_sourceChanged => '파일이 변경됨';

  @override
  String get blocks_sourceMissing => '파일 없음';

  @override
  String blocks_importedAt(Object date) {
    return '$date 가져옴';
  }

  @override
  String get blocks_total => '합계';

  @override
  String blocks_totalItems(Object count) {
    return '항목 $count개';
  }

  @override
  String get blocks_from => '출처';

  @override
  String get blocks_batch => '일괄 작업';

  @override
  String get blocks_insertInOrder => '프롬프트에 순서대로 삽입';

  @override
  String get blocks_mergeNew => '새 블록으로 합치기…';

  @override
  String get blocks_batchStyle => '색 / 스타일 일괄 변경';

  @override
  String blocks_dragHint(Object count) {
    return '이 카드 $count장을 왼쪽 폴더나 컬렉션으로 드래그하고, 놓을 때 이동 또는 복사를 고를 수도 있습니다.';
  }

  @override
  String get blocks_editBlockTitle => '블록 편집';

  @override
  String get blocks_editHint =>
      '저장하면 프롬프트의 고정 인스턴스는 바로 바뀌고, 무작위 / 순서는 다음 뽑기부터 새 내용을 씁니다';

  @override
  String get blocks_newBlockHint => '저장 후 생성 페이지 사이드바에서 클릭 한 번으로 넣을 수 있습니다';

  @override
  String get blocks_addThumb => '미리보기 추가';

  @override
  String get blocks_changeImage => '이미지 변경';

  @override
  String get blocks_clearThumb => '미리보기 삭제';

  @override
  String get blocks_cropHint => '드래그 / 휠로 확대';

  @override
  String get blocks_namePlaceholder => '비우면 첫 항목 사용';

  @override
  String get blocks_plainText => '일반 텍스트';

  @override
  String get blocks_plainTextHint => '입력한 그대로 저장하고 항목으로 나누지 않습니다';

  @override
  String get blocks_atomHint => '입력 후 Enter나 쉼표로 추가, 붙여넣으면 자동으로 나눕니다';

  @override
  String get blocks_existingTags => '기존 태그';

  @override
  String get blocks_newTag => '새 태그';

  @override
  String get blocks_paramsNotAuto => '삽입 시 자동 적용 안 함';

  @override
  String get blocks_noParamsShort => '없음';

  @override
  String get blocks_editParams => '설정 편집';

  @override
  String get blocks_captureParams => '현재 값 가져오기';

  @override
  String get blocks_keepCurrent => '현재 값 유지';

  @override
  String get blocks_clearParams => '설정 지우기';

  @override
  String get blocks_deleteBlock => '블록 삭제';

  @override
  String get blocks_deleteConfirmInline => '이 블록을 삭제할까요?';

  @override
  String get blocks_saveShortcut => 'Ctrl+Enter로 저장';

  @override
  String get blocks_saveAsBlock => '블록으로 저장';

  @override
  String get blocks_lookup => '용어 찾기';

  @override
  String blocks_splitDone(Object count) {
    return '$count개 · 쉼표로 나눔';
  }

  @override
  String get blocks_replaceSelection => '저장 후 선택한 텍스트를 이 블록으로 바꾸기';

  @override
  String get blocks_quickHint => '미리보기, 부정, 설정은 나중에 라이브러리에서';

  @override
  String get imageViewer_backGallery => '로컬 갤러리';

  @override
  String get imageViewer_backGeneration => '생성';

  @override
  String get imageViewer_scopeAll => '모든 이미지';

  @override
  String get imageViewer_sortModified => '수정한 날짜순';

  @override
  String get imageViewer_sortCreated => '만든 날짜순';

  @override
  String get imageViewer_sortFileName => '파일 이름순';

  @override
  String get imageViewer_sortFileSize => '파일 크기순';

  @override
  String get imageViewer_sortDimensions => '크기순';

  @override
  String get imageViewer_unsaved => '저장 안 됨';

  @override
  String get imageViewer_saved => '저장됨';

  @override
  String imageViewer_batch(Object count) {
    return '생성 결과 · 이번 $count장';
  }

  @override
  String imageViewer_zoomFit(Object percent) {
    return '맞춤 · $percent%';
  }

  @override
  String get imageViewer_zoomFitPending => '맞춤 · —';

  @override
  String get imageViewer_zoomFitShort => '맞춤';

  @override
  String get imageViewer_zoomIn => '확대';

  @override
  String get imageViewer_zoomOut => '축소';

  @override
  String get imageViewer_actualSize => '원본 크기';

  @override
  String get imageViewer_fullscreen => '전체 화면';

  @override
  String get imageViewer_exitFullscreen => '전체 화면 종료';

  @override
  String get imageViewer_fullscreenHint => '아래로 이동하면 필름 스트립 · 2초 뒤 컨트롤 숨김';

  @override
  String get imageViewer_infoPanel => '정보 패널';

  @override
  String get imageViewer_infoShort => '정보';

  @override
  String get imageViewer_hideInfo => '정보 닫기';

  @override
  String get imageViewer_previous => '이전';

  @override
  String get imageViewer_next => '다음';

  @override
  String get imageViewer_loadingOriginal => '원본 불러오는 중';

  @override
  String imageViewer_loadingOriginalSize(Object size) {
    return '원본 불러오는 중 · $size';
  }

  @override
  String get imageViewer_missingTitle => '이미지를 찾을 수 없음';

  @override
  String get imageViewer_missingHint => '탐색기에서 이동, 이름 변경 또는 삭제되었을 수 있습니다';

  @override
  String get imageViewer_openFolder => '폴더 열기';

  @override
  String get imageViewer_nextImage => '다음 이미지';

  @override
  String get imageViewer_hintPan => '드래그해 이동';

  @override
  String get imageViewer_hintWheel => '휠로 확대/축소';

  @override
  String get imageViewer_hintDouble => '더블클릭 /';

  @override
  String get imageViewer_hintFit => '맞춤으로';

  @override
  String get imageViewer_hintActual => '원본 크기';

  @override
  String get imageViewer_dragFrame => '틀을 드래그';

  @override
  String get imageViewer_movedToTrash => '휴지통으로 이동함';

  @override
  String get imageViewer_undo => '실행 취소';

  @override
  String get imageViewer_details => '정보';

  @override
  String get imageViewer_generationResult => '생성 결과';

  @override
  String get imageViewer_favorite => '즐겨찾기';

  @override
  String get imageViewer_showInFolder => '폴더에서 보기';

  @override
  String imageViewer_deleteKey(Object key) {
    return '삭제  $key';
  }

  @override
  String get imageViewer_more => '더 보기';

  @override
  String imageViewer_genIndex(Object index) {
    return '이번 생성 · $index번째';
  }

  @override
  String get imageViewer_notSaved => '갤러리에 저장 안 됨';

  @override
  String get imageViewer_savedToGallery => '갤러리에 저장됨';

  @override
  String get imageViewer_size => '크기';

  @override
  String get imageViewer_fileSize => '파일 크기';

  @override
  String get imageViewer_modified => '수정한 날짜';

  @override
  String get imageViewer_model => '모델';

  @override
  String get imageViewer_params => '생성 설정';

  @override
  String get imageViewer_loadingMeta => '메타데이터 읽는 중…';

  @override
  String get imageViewer_seed => '시드';

  @override
  String get imageViewer_sampler => '샘플러';

  @override
  String get imageViewer_steps => '스텝';

  @override
  String get imageViewer_guidance => '프롬프트 가이던스';

  @override
  String imageViewer_noise(Object value) {
    return '노이즈 $value';
  }

  @override
  String imageViewer_rescale(Object value) {
    return '리스케일 $value';
  }

  @override
  String imageViewer_precise(Object count) {
    return '정밀 참조 ×$count';
  }

  @override
  String get imageViewer_qualityTags => '품질 태그';

  @override
  String get imageViewer_prompt => '프롬프트';

  @override
  String get imageViewer_translate => '번역';

  @override
  String get imageViewer_showOriginal => '원문 보기';

  @override
  String imageViewer_translateFailed(Object error) {
    return '번역 실패: $error';
  }

  @override
  String get imageViewer_copy => '복사';

  @override
  String get imageViewer_copySeed => '시드 복사';

  @override
  String get imageViewer_expandAll => '모두 보기';

  @override
  String get imageViewer_expand => '펼치기';

  @override
  String get imageViewer_collapse => '접기';

  @override
  String imageViewer_character(Object index) {
    return '캐릭터 $index';
  }

  @override
  String imageViewer_position(Object cell) {
    return '위치 $cell';
  }

  @override
  String get imageViewer_characterNegative => '캐릭터 부정 · ';

  @override
  String get imageViewer_negative => '부정';

  @override
  String imageViewer_tagCount(Object count) {
    return '$count개';
  }

  @override
  String get imageViewer_vibes => 'Vibe 참조';

  @override
  String imageViewer_vibeStrength(Object value) {
    return '강도 $value';
  }

  @override
  String imageViewer_vibeInfo(Object value) {
    return '정보 $value';
  }

  @override
  String get imageViewer_saveVibe => 'Vibe 라이브러리에 저장';

  @override
  String get imageViewer_noMetaTitle => 'NovelAI 생성 정보 없음';

  @override
  String get imageViewer_noMetaBody =>
      'NAI로 생성한 이미지가 아니거나 메타데이터가 제거되었습니다(스크린샷, 다시 저장, 압축한 이미지에 흔함).\n아래의 이미지 투 이미지, 스타일 전송, 정밀 참조, 업스케일은 사용할 수 있습니다.';

  @override
  String get imageViewer_reuse => '설정 재사용';

  @override
  String get imageViewer_reuseNoMeta => '생성 정보 없음';

  @override
  String get imageViewer_img2img => '이미지 투 이미지';

  @override
  String get imageViewer_styleTransfer => '스타일 전송';

  @override
  String get imageViewer_preciseRef => '정밀 참조';

  @override
  String get imageViewer_saveRef => '참조로 저장';

  @override
  String get imageViewer_krita => 'Krita로 보내기';

  @override
  String get imageViewer_kritaOff => 'Krita가 연결되지 않음';

  @override
  String get imageViewer_upscale => '업스케일';

  @override
  String get imageViewer_copyImage => '이미지 복사';

  @override
  String get imageViewer_saveBlock => '블록으로 저장';

  @override
  String get imageViewer_save => '갤러리에 저장';

  @override
  String get imageViewer_copyPath => '파일 경로 복사';

  @override
  String get imageViewer_copyAllPrompts => '모든 프롬프트 복사(캐릭터 포함)';

  @override
  String get imageViewer_saveBlockEllipsis => '블록으로 저장…';

  @override
  String get imageViewer_addToCollection => '컬렉션에 추가';

  @override
  String get imageViewer_moveTo => '이동…';

  @override
  String get imageViewer_copyTo => '복사…';

  @override
  String get imageViewer_moveToTrash => '휴지통으로 이동';

  @override
  String get imageViewer_collections => '컬렉션';

  @override
  String get imageViewer_newCollection => '새 컬렉션…';

  @override
  String get imageViewer_helpTitle => '뷰어 단축키';

  @override
  String get imageViewer_helpHint => '설정 → 단축키에서 바꿀 수 있습니다';

  @override
  String get imageViewer_helpClose => '한 번 더 누르면 닫기';

  @override
  String get imageViewer_helpBrowse => '보기';

  @override
  String get imageViewer_helpZoom => '확대/축소';

  @override
  String get imageViewer_helpActions => '작업';

  @override
  String get imageViewer_helpPrevNext => '이전 / 다음';

  @override
  String get imageViewer_helpFirstLast => '처음 / 마지막';

  @override
  String get imageViewer_helpInfo => '정보 표시 / 숨기기';

  @override
  String get imageViewer_helpClose2 => '닫기';

  @override
  String get imageViewer_helpZoomInOut => '확대 / 축소';

  @override
  String get imageViewer_helpActual => '원본 크기 100%';

  @override
  String get imageViewer_helpWheel => '포인터 위치 기준 확대/축소';

  @override
  String get imageViewer_helpDouble => '맞춤 ↔ 확대';

  @override
  String get imageViewer_keyWheel => '휠';

  @override
  String get imageViewer_keyDouble => '더블클릭';

  @override
  String get imageViewer_helpCopyPrompt => '프롬프트 복사';

  @override
  String get imageViewer_helpUndo => '삭제 취소';

  @override
  String get imageViewer_protectedTitle => '보호된 이미지입니다. 휴지통으로 이동할까요?';

  @override
  String get imageViewer_protectedBody => '휴지통에서 복원할 수 있습니다.';

  @override
  String get imageViewer_cancel => '취소';

  @override
  String get imageViewer_justNow => '방금';

  @override
  String imageViewer_minutesAgo(Object count) {
    return '$count분 전';
  }

  @override
  String imageViewer_hoursAgo(Object count) {
    return '$count시간 전';
  }

  @override
  String get imageViewer_yesterday => '어제';

  @override
  String get explore_back => '화풍 탐색';

  @override
  String get explore_close => '닫기';

  @override
  String get explore_cancel => '취소';

  @override
  String get explore_done => '완료';

  @override
  String get explore_more => '더 보기';

  @override
  String get explore_rename => '이름 바꾸기';

  @override
  String get explore_remove => '빼기';

  @override
  String get explore_copy => '복사';

  @override
  String get explore_undo => '실행 취소';

  @override
  String get explore_expand => '펼치기';

  @override
  String get explore_expandAll => '모두 보기';

  @override
  String get explore_collapse => '접기';

  @override
  String get explore_previous => '이전';

  @override
  String get explore_next => '다음';

  @override
  String explore_today(Object time) {
    return '오늘 $time';
  }

  @override
  String explore_yesterday(Object time) {
    return '어제 $time';
  }

  @override
  String explore_monthDay(Object month, Object day, Object time) {
    return '$month월 $day일 $time';
  }

  @override
  String explore_fullDate(Object year, Object month, Object day) {
    return '$year년 $month월 $day일';
  }

  @override
  String get explore_sectionToday => '오늘';

  @override
  String get explore_thisWeek => '이번 주';

  @override
  String get explore_earlier => '이전';

  @override
  String get explore_variables => '랜덤 변수';

  @override
  String get explore_variablesHint => '이미지마다 다시 뽑기';

  @override
  String get explore_variablesInfo =>
      '프롬프트의 랜덤 블록입니다. 후보마다 풀에서 다시 뽑고 결과를 후보 아래에 표시합니다. \"진화 대상\" 블록은 자손이 바뀌는 위치입니다.';

  @override
  String get explore_variablesEmpty =>
      '프롬프트에 랜덤 블록이 없습니다. 블록 라이브러리에서 (예: 작가 풀) 넣으면 이미지마다 다시 뽑습니다.';

  @override
  String get explore_openBlockLibrary => '블록 라이브러리 열기';

  @override
  String get explore_variableMissing => '블록 삭제됨';

  @override
  String explore_poolSize(Object count) {
    return '풀 $count개';
  }

  @override
  String get explore_evolutionTarget => '진화 대상';

  @override
  String explore_draw(Object count) {
    return '후보 $count장 뽑기';
  }

  @override
  String get explore_stopGenerating => '생성 중지';

  @override
  String get explore_busy => '생성 중';

  @override
  String explore_cooldown(Object seconds) {
    return '쿨다운 $seconds초';
  }

  @override
  String get explore_insufficient => 'Anlas 부족';

  @override
  String explore_count(Object count) {
    return '$count장';
  }

  @override
  String explore_favoritesCount(Object count) {
    return '즐겨찾기 $count';
  }

  @override
  String explore_roundsCount(Object count) {
    return '$count라운드';
  }

  @override
  String explore_linesCount(Object count) {
    return '진화 라인 $count개';
  }

  @override
  String explore_progressRound(Object round, Object done, Object total) {
    return '$round라운드 · $done / $total';
  }

  @override
  String explore_progressChildren(
    Object line,
    Object gen,
    Object done,
    Object total,
  ) {
    return '$line $gen세대 · $done / $total';
  }

  @override
  String explore_paused(Object where) {
    return '일시 정지 · $where';
  }

  @override
  String get explore_pause => '일시 정지';

  @override
  String get explore_resume => '계속';

  @override
  String get explore_stop => '중지';

  @override
  String get explore_sizeSmall => '작은 카드';

  @override
  String get explore_sizeLarge => '큰 카드';

  @override
  String get explore_inspector => '인스펙터';

  @override
  String get explore_hideInspector => '숨기기';

  @override
  String get explore_tabCandidates => '후보';

  @override
  String get explore_tabEvolution => '진화';

  @override
  String get explore_filterAll => '전체';

  @override
  String get explore_filterFavorites => '즐겨찾기';

  @override
  String get explore_filterUngrouped => '그룹 없음';

  @override
  String get explore_addGroup => '그룹';

  @override
  String get explore_groupName => '그룹 이름';

  @override
  String get explore_deleteGroup => '그룹 삭제 (구성원은 그룹 없음으로)';

  @override
  String get explore_newLine => '새 진화 라인';

  @override
  String get explore_deleteLine => '진화 라인 삭제';

  @override
  String get explore_compareShort => '비교';

  @override
  String get explore_evoHelp => '사용법';

  @override
  String get explore_evoHelpBody =>
      '1. 마음에 드는 후보를 골라 진화를 시작하면 작가 문자열이 1세대 부모가 됩니다.\n2. 자손은 교차, 변이, 새 작가 주입으로 만들어집니다.\n3. 마음에 드는 자손을 골라 다음 세대를 키웁니다. 둘씩 비교하면 부모 선호도를 조정합니다.';

  @override
  String get explore_select => '여러 개 선택';

  @override
  String get explore_selectAll => '모두 선택';

  @override
  String get explore_selectDone => '완료';

  @override
  String get explore_selectExit => '선택 종료  Esc';

  @override
  String get explore_selectHint => '카드를 눌러 선택';

  @override
  String explore_selectedN(Object count) {
    return '$count장 선택됨';
  }

  @override
  String get explore_sortNewest => '새 라운드가 위 (누르면 오래된 순)';

  @override
  String get explore_sortOldest => '오래된 라운드가 위 (누르면 새로운 순)';

  @override
  String explore_round(Object number) {
    return '$number라운드';
  }

  @override
  String explore_generatingShort(Object done, Object total) {
    return '생성 중 $done / $total';
  }

  @override
  String explore_failedRetry(Object count) {
    return '$count장 실패 · 다시 시도';
  }

  @override
  String get explore_pick => '진화할 이미지 고르기';

  @override
  String get explore_pickTip => '이 라운드의 즐겨찾기가 선택된 상태로 여러 개 선택을 시작합니다';

  @override
  String get explore_filterEmpty => '이 필터에 맞는 후보가 없습니다';

  @override
  String get explore_showAll => '모두 보기';

  @override
  String explore_queued(Object number) {
    return '대기 #$number';
  }

  @override
  String explore_generatingN(Object number) {
    return '생성 중 #$number';
  }

  @override
  String get explore_failed => '생성 실패';

  @override
  String get explore_failedHover => '마우스를 올려 이유 보기';

  @override
  String get explore_noArtists => '뽑힌 작가 없음';

  @override
  String get explore_parentTip => '진화 라인의 부모입니다';

  @override
  String get explore_favorite => '즐겨찾기';

  @override
  String get explore_favorited => '즐겨찾기됨';

  @override
  String get explore_unfavorite => '즐겨찾기 해제';

  @override
  String get explore_addToEvolution => '진화에 추가';

  @override
  String get explore_startEvolution => '진화 시작';

  @override
  String get explore_saveBlock => '블록으로 저장';

  @override
  String get explore_applyToEditor => '편집기에 적용';

  @override
  String get explore_copyArtists => '작가 문자열 복사';

  @override
  String get explore_openLarge => '크게 보기';

  @override
  String get explore_group => '그룹';

  @override
  String get explore_groups => '그룹';

  @override
  String get explore_groupsHint => '1–9로 빠르게 분류';

  @override
  String get explore_newGroup => '새 그룹';

  @override
  String get explore_ungroup => '그룹에서 빼기';

  @override
  String get explore_delete => '삭제';

  @override
  String explore_deleteN(Object count) {
    return '$count장 삭제';
  }

  @override
  String get explore_deleteThis => '이 이미지 삭제';

  @override
  String explore_deleted(Object count) {
    return '$count장 삭제함';
  }

  @override
  String get explore_inspectorEmpty => '후보를 누르면 뽑힌 작가가 여기에 표시됩니다';

  @override
  String explore_childN(Object number) {
    return '자손 #$number';
  }

  @override
  String explore_genOp(Object gen, Object op) {
    return '$gen세대 · $op';
  }

  @override
  String get explore_drawn => '이 이미지에서 뽑힌 것';

  @override
  String get explore_drawEmpty => '이번에는 빈 항목이 뽑혔습니다';

  @override
  String get explore_origin => '만들어진 방식';

  @override
  String get explore_seed => '시드';

  @override
  String get explore_elapsed => '소요 시간';

  @override
  String get explore_params => '설정';

  @override
  String get explore_sampler => '샘플러';

  @override
  String get explore_model => '모델';

  @override
  String explore_steps(Object count) {
    return '$count스텝';
  }

  @override
  String get explore_fullPrompt => '전체 프롬프트';

  @override
  String get explore_negative => '네거티브';

  @override
  String get explore_failReason => '실패 이유';

  @override
  String get explore_retryFailed => '실패한 후보 다시 시도';

  @override
  String get explore_waitHint => '생성되면 뽑힌 작가가 여기에 표시됩니다';

  @override
  String explore_mergedArtists(Object count) {
    return '합친 작가 · $count';
  }

  @override
  String get explore_multiHint =>
      '블록으로 저장하면 이 작가들을 하나로 합칩니다. 진화에서는 이미지마다 부모가 됩니다.';

  @override
  String get explore_evoEmptyTitle => '아직 진화 라인이 없습니다';

  @override
  String get explore_evoEmptyBody =>
      '마음에 드는 후보를 골라 \"진화 시작\"을 누르면 좋은 작가 조합에서 새 조합을 키웁니다.';

  @override
  String get explore_evoGoPick => '후보에서 고르기';

  @override
  String explore_gen(Object number) {
    return '$number세대';
  }

  @override
  String get explore_current => '현재';

  @override
  String explore_genFirst(Object picked, Object children) {
    return '후보 $picked장에서 시작 · 자손 $children장';
  }

  @override
  String explore_genFrom(
    Object parents,
    Object children,
    Object from,
    Object picked,
  ) {
    return '부모 $parents → 자손 $children · $from세대에서 $picked장';
  }

  @override
  String get explore_backcross => '1세대 역교배';

  @override
  String get explore_compare => '둘씩 비교해 순위';

  @override
  String get explore_compareTip => '부모를 둘씩 보고 더 좋은 쪽을 고릅니다. 선호도가 높을수록 자주 선택됩니다';

  @override
  String explore_generateChildren(Object count) {
    return '자손 $count장 생성';
  }

  @override
  String explore_children(Object count) {
    return '자손 · $count';
  }

  @override
  String explore_pickedN(Object count) {
    return '$count장 선택';
  }

  @override
  String get explore_breedHint => '마음에 드는 자손을 골라 다음 세대로';

  @override
  String explore_breed(Object count, Object next) {
    return '선택한 $count장으로 $next세대 키우기';
  }

  @override
  String get explore_noChildren => '아직 자손이 없습니다 · \"생성\"으로 첫 배치 만들기';

  @override
  String explore_parentsByPref(Object count) {
    return '부모 · 선호도순 · $count';
  }

  @override
  String get explore_opMutation => '변이';

  @override
  String get explore_opCrossover => '교차';

  @override
  String get explore_opInjection => '주입';

  @override
  String get explore_searchRuns => '탐색 검색';

  @override
  String get explore_newRun => '새 탐색';

  @override
  String get explore_newRunHint => '현재 프롬프트와 설정으로 시작합니다. 이름은 나중에 바꿀 수 있습니다';

  @override
  String explore_runRunning(Object done, Object total) {
    return '생성 중 $done/$total';
  }

  @override
  String explore_runPaused(Object done, Object total) {
    return '일시 정지 $done/$total';
  }

  @override
  String explore_runFailed(Object count) {
    return '$count장 실패';
  }

  @override
  String get explore_noRunMatch => '일치하는 탐색이 없습니다';

  @override
  String get explore_runMenuHint => '자동 이름: 랜덤 블록 이름 + 날짜 · 행의 ⋯로 이름 변경·삭제';

  @override
  String get explore_deleteRun => '탐색 삭제';

  @override
  String explore_deleteRunTitle(Object name) {
    return '\"$name\"을(를) 삭제할까요?';
  }

  @override
  String explore_deleteRunBody(Object count) {
    return '후보 $count장과 모든 진화 라인이 삭제되며 되돌릴 수 없습니다. 갤러리 이미지는 영향을 받지 않습니다.';
  }

  @override
  String explore_deleteLineTitle(Object name) {
    return '진화 라인 \"$name\"을(를) 삭제할까요?';
  }

  @override
  String explore_deleteLineBody(Object count) {
    return '이 라인의 자손 $count장도 삭제되며 되돌릴 수 없습니다. 후보는 영향을 받지 않습니다.';
  }

  @override
  String get explore_onboardingTitle => '랜덤 블록으로 화풍을 한꺼번에 시험하기';

  @override
  String get explore_onboardingBody =>
      '이미지마다 작가 풀에서 다시 뽑습니다. 마음에 드는 조합을 남겨 진화시키세요.';

  @override
  String get explore_step1 => '랜덤 블록 넣기';

  @override
  String get explore_step1Body => '라이브러리의 랜덤 블록(예: 작가 풀)을 프롬프트에 넣습니다.';

  @override
  String get explore_step2 => '후보 한 묶음 뽑기';

  @override
  String explore_step2Body(Object count) {
    return '왼쪽 아래 \"후보 $count장 뽑기\"를 누르면 이미지마다 작가를 다시 뽑습니다.';
  }

  @override
  String get explore_step3 => '즐겨찾기, 진화, 저장';

  @override
  String get explore_step3Body =>
      '마음에 드는 것을 즐겨찾기하고 진화시킨 뒤, 만족한 조합을 블록으로 저장합니다.';

  @override
  String explore_detected(Object count) {
    return '$count개 감지됨';
  }

  @override
  String get explore_noVariables => '랜덤 블록 없음';

  @override
  String get explore_openPrevious => '이전 탐색 열기';

  @override
  String explore_evoTitle(Object count) {
    return '후보 $count장으로 진화 시작';
  }

  @override
  String explore_evoJoinTitle(Object count, Object line, Object gen) {
    return '$count장을 \"$line\" $gen세대에 추가';
  }

  @override
  String get explore_evoStep1 => '부모';

  @override
  String get explore_evoStep1Body => '후보마다 작가 문자열이 부모가 됩니다';

  @override
  String get explore_evoStep2 => '자손';

  @override
  String get explore_evoStep2Body => '교차, 변이, 새 작가 주입';

  @override
  String get explore_evoStep3 => '고르기';

  @override
  String get explore_evoStep3Body => '마음에 드는 자손으로 다음 세대';

  @override
  String get explore_evoNewLine => '새 진화 라인';

  @override
  String explore_evoJoin(Object line, Object gen) {
    return '\"$line\" $gen세대에 추가';
  }

  @override
  String get explore_lineName => '진화 라인 이름';

  @override
  String explore_lineDefault(Object number) {
    return '진화 라인 $number';
  }

  @override
  String explore_lineGen(Object line, Object gen) {
    return '$line · $gen세대';
  }

  @override
  String explore_evoParents(Object count) {
    return '1세대 부모 · $count';
  }

  @override
  String explore_evoAddParents(Object count) {
    return '추가할 부모 · $count';
  }

  @override
  String get explore_addCustom => '사용자 작가 문자열 추가';

  @override
  String get explore_customHint =>
      '예: 0.8::artist:ciloranko::, artist:rella (Enter로 추가)';

  @override
  String get explore_targetBefore => '자손은 프롬프트의';

  @override
  String get explore_targetAfter => '위치를 바꾸고 나머지는 그대로 둡니다';

  @override
  String get explore_noTarget => '프롬프트에 랜덤 블록이 없어 자손을 바꿀 곳이 없습니다. 먼저 넣어 주세요.';

  @override
  String get explore_firstBatch => '첫 자손';

  @override
  String get explore_atLeast4 => '장 (최소 4)';

  @override
  String get explore_createOnly => '만들기만';

  @override
  String get explore_joinOnly => '추가만';

  @override
  String explore_createGenerate(Object count) {
    return '만들고 $count장 생성';
  }

  @override
  String get explore_saveBlockTitle => '프롬프트 블록으로 저장';

  @override
  String get explore_untitled => '제목 없음';

  @override
  String explore_blockFromOne(Object number) {
    return '후보 #$number에서';
  }

  @override
  String explore_blockFromMany(Object count) {
    return '후보 $count장에서 합치고 중복 제거';
  }

  @override
  String explore_blockNameMany(Object run, Object count) {
    return '$run · 엄선 $count';
  }

  @override
  String get explore_blockContent => '내용';

  @override
  String get explore_blockArtists => '뽑힌 작가만';

  @override
  String get explore_blockFull => '전체 포지티브';

  @override
  String get explore_blockFullSingle => '후보가 1장일 때만 사용할 수 있습니다';

  @override
  String get explore_blockRemoveHint => '×로 필요 없는 작가 빼기';

  @override
  String explore_blockKept(Object kept, Object total) {
    return '$kept / $total 유지';
  }

  @override
  String get explore_blockName => '이름';

  @override
  String get explore_blockColor => '색';

  @override
  String get explore_blockFolder => '저장 위치';

  @override
  String get explore_blockRoot => '블록 라이브러리 (루트)';

  @override
  String get explore_blockFooter => '저장 후 블록 라이브러리에서 프롬프트로 끌어올 수 있습니다';

  @override
  String get explore_compareTitle => '둘씩 비교 · 부모 순위 정하기';

  @override
  String get explore_compareNote => '결과는 바로 저장됩니다';

  @override
  String get explore_compareQuestion => '어느 쪽이 원하는 화풍에 더 가깝나요?';

  @override
  String explore_comparePairs(Object index, Object total) {
    return '$index / $total쌍';
  }

  @override
  String get explore_leftBetter => '왼쪽이 더 좋음';

  @override
  String get explore_rightBetter => '오른쪽이 더 좋음';

  @override
  String get explore_neither => '둘 다 아님';

  @override
  String get explore_skip => '건너뛰기';

  @override
  String get explore_keySpace => 'Space';

  @override
  String get explore_ranking => '현재 순위 · 실시간';

  @override
  String get explore_rankingNote => '선호도가 높을수록 다음 세대에서 부모로 자주 선택됩니다.';

  @override
  String get explore_compareDone => '순위 정리 완료';

  @override
  String get explore_compareDoneBody => '새 선호도가 저장되어 다음 자손 생성에 사용됩니다.';

  @override
  String get gen_cancel => '취소';

  @override
  String get gen_close => '닫기';

  @override
  String get gen_done => '완료';

  @override
  String get gen_more => '더 보기';

  @override
  String get gen_delete => '삭제';

  @override
  String get gen_remove => '제거';

  @override
  String get gen_rename => '이름 바꾸기';

  @override
  String get gen_add => '추가';

  @override
  String get gen_clear => '지우기';

  @override
  String get gen_clearAll => '모두 지우기';

  @override
  String get gen_clearConfirm => '지우기';

  @override
  String get gen_removeConfirm => '제거';

  @override
  String get gen_expand => '펼치기';

  @override
  String get gen_collapse => '접기';

  @override
  String get gen_copied => '복사됨';

  @override
  String get gen_random => '랜덤';

  @override
  String get gen_auto => '자동';

  @override
  String get gen_pin => '헤더에 고정';

  @override
  String get gen_unpin => '헤더에서 해제';

  @override
  String get gen_yesterday => '어제';

  @override
  String gen_monthDay(Object month, Object day) {
    return '$month월 $day일';
  }

  @override
  String get gen_params => '생성 설정';

  @override
  String get gen_generating => '생성 중';

  @override
  String get gen_modelsNew => '최신 모델';

  @override
  String get gen_modelsLegacy => '이전 모델';

  @override
  String get gen_modeTip => '클릭하여 Anime / Furry 전환';

  @override
  String gen_anlasTip(Object value) {
    return 'Anlas 잔액 $value';
  }

  @override
  String get gen_positive => '프롬프트';

  @override
  String get gen_basePrompt => '기본 프롬프트';

  @override
  String get gen_negative => '제외';

  @override
  String get gen_finalPositive => '최종 전송 프롬프트';

  @override
  String get gen_finalNegative => '최종 전송 제외 내용';

  @override
  String get gen_toolDock => '블록 라이브러리 패널';

  @override
  String get gen_toolPalette => '블록 팔레트';

  @override
  String get gen_toolTranslate => '번역';

  @override
  String get gen_toolsMenu => '도구와 설정';

  @override
  String get gen_toolsPinned => '헤더 도구';

  @override
  String get gen_toolsSettings => '프롬프트 설정';

  @override
  String get gen_fullscreen => '전체 화면 편집';

  @override
  String get gen_autoFormat => '자동 서식';

  @override
  String get gen_autoFormatSub => '편집기를 벗어나면 쉼표와 공백 정리';

  @override
  String get gen_highlight => '강조 하이라이트';

  @override
  String get gen_highlightSub => '가중치에 따라 색 표시';

  @override
  String get gen_sdConvert => 'SD 문법 자동 변환';

  @override
  String get gen_sdConvertSub => '(tag:1.2) 붙여넣기를 NAI 가중치로 변환';

  @override
  String get gen_related => '연관 태그 추천';

  @override
  String get gen_relatedSub => '자주 함께 쓰는 태그 추천';

  @override
  String get gen_translating => '번역 중…';

  @override
  String get gen_translateNeedsModel => '번역 모델이 없습니다. 클릭하여 설정';

  @override
  String get gen_translateRestore => '원문 보기';

  @override
  String gen_translateWith(Object route) {
    return '번역 ($route)';
  }

  @override
  String get gen_translateNew => '새 내용 번역';

  @override
  String get gen_translateShowOriginal => '모두 원문 보기';

  @override
  String get gen_translateShowTranslated => '모두 번역문 보기';

  @override
  String get gen_translateSettings => '번역 모델 설정';

  @override
  String get gen_qualityPreset => '품질 태그';

  @override
  String get gen_ucPreset => '제외 프리셋';

  @override
  String get gen_presetNone => '없음';

  @override
  String get gen_transparentOn => '투명 배경: 켜짐';

  @override
  String get gen_transparentOff => '투명 배경: 꺼짐';

  @override
  String get gen_characters => '캐릭터';

  @override
  String get gen_charactersTip => '캐릭터마다 프롬프트를 따로 써서 특징이 섞이지 않게 합니다.';

  @override
  String get gen_charactersEmpty => '캐릭터가 없습니다. 오른쪽 위 + 로 추가하세요.';

  @override
  String gen_charactersFull(Object max) {
    return '최대 $max명';
  }

  @override
  String get gen_addCharacter => '캐릭터 추가';

  @override
  String gen_addAs(Object gender) {
    return '$gender 캐릭터 추가';
  }

  @override
  String get gen_clearCharacters => '모든 캐릭터 삭제';

  @override
  String get gen_clearCharactersTitle => '모든 캐릭터를 삭제할까요?';

  @override
  String gen_clearCharactersBody(Object count) {
    return '캐릭터 $count명과 프롬프트가 모두 삭제됩니다.';
  }

  @override
  String gen_characterN(Object n) {
    return '캐릭터 $n';
  }

  @override
  String get gen_genderFemale => '여성';

  @override
  String get gen_genderMale => '남성';

  @override
  String get gen_genderOther => '기타';

  @override
  String get gen_position => '위치';

  @override
  String get gen_positionAi => 'AI 선택';

  @override
  String get gen_positionCustom => '직접 지정';

  @override
  String get gen_positionBoard => '캐릭터 위치';

  @override
  String get gen_positionAiTip => 'AI가 위치를 정합니다';

  @override
  String gen_positionAt(Object at) {
    return '위치 $at — 클릭하여 조정';
  }

  @override
  String get gen_positionUnset => '아직 배치 안 됨 — 클릭하여 배치';

  @override
  String get gen_positionAiHint => '위치를 AI가 정하고 있습니다';

  @override
  String get gen_positionGridHint => '캐릭터를 칸으로 끌면 칸 중앙에 맞춰집니다';

  @override
  String get gen_positionFreeHint => '캐릭터를 원하는 위치로 끌어 놓으세요';

  @override
  String get gen_positionAiOverlay => '지금은 AI 선택입니다.\n직접 지정으로 바꾸면 배치할 수 있습니다.';

  @override
  String get gen_positionToCustom => '직접 지정으로 전환';

  @override
  String get gen_positionUnplaced => '미배치';

  @override
  String get gen_renameTip => '더블클릭하여 이름 바꾸기';

  @override
  String get gen_moveUp => '위로';

  @override
  String get gen_moveDown => '아래로';

  @override
  String get gen_characterDisable => '이 캐릭터 제외';

  @override
  String get gen_characterEnable => '이 캐릭터 사용';

  @override
  String get gen_charPositive => '프롬프트';

  @override
  String get gen_charNegative => '제외';

  @override
  String get gen_saveAsBlock => '블록으로 저장';

  @override
  String get gen_refs => '참조 이미지';

  @override
  String get gen_img2img => '이미지 투 이미지';

  @override
  String get gen_img2imgDesc => '원본 이미지로 변형 생성';

  @override
  String gen_img2imgSummary(Object strength, Object noise) {
    return '강도 $strength · 노이즈 $noise';
  }

  @override
  String get gen_img2imgDrop => '이미지를 끌어 놓거나';

  @override
  String get gen_upload => '업로드';

  @override
  String get gen_replace => '교체';

  @override
  String get gen_edit => '편집';

  @override
  String get gen_inpaint => '인페인트';

  @override
  String get gen_placeOnCanvas => '캔버스에 표시';

  @override
  String get gen_fromPreciseLibrary => '정밀 참조 라이브러리에서';

  @override
  String get gen_sketch => '스케치';

  @override
  String get gen_strength => '강도';

  @override
  String get gen_strengthTip => '높을수록 원본과 달라집니다 (기본 0.7)';

  @override
  String get gen_noise => '노이즈';

  @override
  String get gen_noiseTip => '노이즈로 디테일 변화를 줍니다 (기본 0)';

  @override
  String get gen_inpaintStrength => '인페인트 강도';

  @override
  String get gen_inpaintReady => '마스크 준비 완료 — 칠한 영역만 다시 생성합니다.';

  @override
  String get gen_refPause => '이번엔 보내지 않기';

  @override
  String get gen_refResume => '다시 보내기';

  @override
  String get gen_refPaused => '일시 중지 — 이번엔 보내지 않음';

  @override
  String get gen_vibe => '바이브 트랜스퍼';

  @override
  String get gen_vibeDesc => '이미지는 바꾸고 분위기는 유지';

  @override
  String get gen_vibeSkipped => '정밀 참조가 있어 이번엔 보내지 않음';

  @override
  String get gen_vibeConflict => '정밀 참조가 있으면 바이브는 보내지 않습니다.';

  @override
  String get gen_vibeDrop => '이미지나 .naiv4vibe 를 끌어 놓거나';

  @override
  String get gen_addVibe => '바이브 추가';

  @override
  String get gen_addFromFile => '파일에서';

  @override
  String get gen_addFromVibeLibrary => '바이브 라이브러리에서';

  @override
  String get gen_addFromPreciseLibrary => '정밀 참조 라이브러리에서';

  @override
  String gen_vibeFull(Object max) {
    return '최대 $max개';
  }

  @override
  String get gen_saveToLibrary => '라이브러리에 저장';

  @override
  String get gen_normalize => '정규화';

  @override
  String get gen_normalizeTip => '바이브 강도를 합계 기준으로 정규화';

  @override
  String gen_vibeExtraCost(Object free, Object each, Object total) {
    return '$free개 초과 시 개당 +$each Anlas · 이번 +$total';
  }

  @override
  String get gen_recent => '최근';

  @override
  String get gen_encoded => '인코딩됨';

  @override
  String get gen_encoding => '인코딩 중';

  @override
  String get gen_encode => '인코딩';

  @override
  String gen_encodeTip(Object cost) {
    return '인코딩 1회 $cost Anlas, 이후 재사용 가능';
  }

  @override
  String get gen_vibeStrength => '강도';

  @override
  String get gen_vibeInfo => '정보 추출';

  @override
  String get gen_vibeInfoReencode => '정보 추출 값을 바꾸면 바이브를 다시 인코딩해야 합니다';

  @override
  String get gen_precise => '정밀 참조';

  @override
  String get gen_preciseDesc => '캐릭터나 화풍 참조에 고정';

  @override
  String get gen_preciseDrop => '캐릭터나 화풍 참조 이미지를 끌어 놓거나';

  @override
  String get gen_preciseCharacter => '캐릭터';

  @override
  String get gen_preciseStyle => '화풍';

  @override
  String get gen_preciseBoth => '둘 다';

  @override
  String get gen_fidelity => '충실도';

  @override
  String gen_preciseCost(Object each, Object total) {
    return '장당 $each Anlas · 이번 +$total';
  }

  @override
  String get gen_preciseConflict => '정밀 참조가 있으면 바이브는 보내지 않습니다.';

  @override
  String get gen_pauseVibes => '바이브 일시 중지';

  @override
  String get gen_savePrecise => '정밀 참조 라이브러리에 저장';

  @override
  String get gen_addPrecise => '정밀 참조 추가';

  @override
  String get gen_image => '이미지';

  @override
  String get gen_sizeNormal => '일반';

  @override
  String get gen_sizeLarge => '크게';

  @override
  String get gen_sizeWallpaper => '배경화면';

  @override
  String get gen_sizeSmall => '작게';

  @override
  String get gen_sizeCustom => '직접 입력';

  @override
  String get gen_portrait => '세로';

  @override
  String get gen_landscape => '가로';

  @override
  String get gen_square => '정사각형';

  @override
  String get gen_width => '너비 (64 단위)';

  @override
  String get gen_height => '높이 (64 단위)';

  @override
  String get gen_swapSize => '너비와 높이 바꾸기';

  @override
  String get gen_count => '장수';

  @override
  String get gen_countTip => '요청 1회당 장수 (1–4)';

  @override
  String get gen_repeat => '반복';

  @override
  String get gen_repeatTip => '연속으로 보낼 요청 수';

  @override
  String gen_repeatTotal(Object times, Object total) {
    return '$times회, 총 $total장 (휠로도 조절)';
  }

  @override
  String get gen_steps => '스텝';

  @override
  String get gen_guidance => '가이던스';

  @override
  String get gen_guidanceTip => '높을수록 프롬프트를 따르지만 너무 높으면 딱딱해집니다 (기본 5)';

  @override
  String get gen_cfgRescale => '가이던스 리스케일';

  @override
  String get gen_cfgRescaleTip => '높은 가이던스의 과포화를 줄입니다 (기본 0)';

  @override
  String get gen_seed => '시드';

  @override
  String get gen_seedPinned => '시드 · 고정';

  @override
  String get gen_seedPinTip => '클릭하여 이 시드 고정';

  @override
  String get gen_seedUnpinTip => '클릭하여 랜덤으로 되돌리기';

  @override
  String get gen_seedRandomize => '랜덤으로';

  @override
  String get gen_sampler => '샘플러';

  @override
  String get gen_samplerRecommended => '추천';

  @override
  String get gen_samplerOther => '기타';

  @override
  String get gen_noiseSchedule => '노이즈 스케줄';

  @override
  String get gen_varietyTip => '초반 가이던스를 건너뛰어 구도를 다양하게';

  @override
  String get gen_decrispTip => '높은 가이던스의 과도한 선명함 완화';

  @override
  String get gen_smeaAutoTip => '크기에 따라 SMEA 자동 사용';

  @override
  String get gen_paramsTitle => '생성 설정';

  @override
  String get gen_paramsOpen => '모든 설정 보기';

  @override
  String get gen_paramsClose => '설정 닫기';

  @override
  String get gen_stop => '생성 중지';

  @override
  String gen_cooldown(Object seconds) {
    return '쿨다운 $seconds초';
  }

  @override
  String get gen_insufficient => 'Anlas 부족';

  @override
  String get gen_free => '이번엔 무료 (Opus 한도 내)';

  @override
  String get gen_emptyTitle => '프롬프트를 쓰고 첫 이미지를 만드세요';

  @override
  String get gen_emptyPress => '';

  @override
  String get gen_emptyOr => '키를 누르거나 왼쪽 아래 생성을 클릭';

  @override
  String get gen_tileFailed => '이 이미지는 실패했습니다';

  @override
  String get gen_enhance => '향상';

  @override
  String get gen_variations => '변형';

  @override
  String get gen_upscale => '업스케일';

  @override
  String get gen_upscaleStop => '업스케일 중지';

  @override
  String get gen_upscaleOptions => '업스케일 방식';

  @override
  String get gen_setInit => 'img2img 원본으로 사용';

  @override
  String get gen_editImage => '이미지 편집';

  @override
  String get gen_sendToTools => '캔버스 도구로 보내기';

  @override
  String get gen_display => '캔버스 표시';

  @override
  String get gen_backdrop => '투명 이미지 바탕';

  @override
  String get gen_backdropSub => '투명 픽셀 아래에만 표시하며 이미지에 저장하지 않습니다';

  @override
  String get gen_bdChecker => '체크 (테마)';

  @override
  String get gen_bdCheckerLight => '밝은 체크';

  @override
  String get gen_bdCheckerDark => '어두운 체크';

  @override
  String get gen_bdNone => '없음';

  @override
  String get gen_bdBlack => '검정';

  @override
  String get gen_bdWhite => '흰색';

  @override
  String get gen_bdGray => '회색';

  @override
  String get gen_bdRed => '빨강';

  @override
  String get gen_bdGreen => '초록';

  @override
  String get gen_bdBlue => '파랑';

  @override
  String get gen_bdCustom => '직접 지정';

  @override
  String get gen_zoomToFill => '채우도록 확대';

  @override
  String get gen_zoomToFillSub => '작은 이미지도 캔버스에 맞게 확대';

  @override
  String get gen_useSeed => '이 시드 사용 (고정)';

  @override
  String get gen_copySeed => '시드 복사';

  @override
  String get gen_pinImage => '캔버스에 고정';

  @override
  String get gen_unpinImage => '고정 해제';

  @override
  String get gen_copyImage => '이미지 복사';

  @override
  String get gen_saveImage => '갤러리에 저장';

  @override
  String get gen_openViewer => '크게 보기';

  @override
  String get gen_retry => '다시 시도';

  @override
  String get gen_copyDetail => '자세히 복사';

  @override
  String get gen_history => '기록';

  @override
  String get gen_historyEmpty => '아직 생성한 이미지가 없습니다';

  @override
  String get gen_historyEmptySub => '생성한 이미지가 묶음별로 표시됩니다';

  @override
  String gen_batchCount(Object count) {
    return '$count장';
  }

  @override
  String gen_batchPending(Object count) {
    return '$count장 남음';
  }

  @override
  String get gen_pinnedTip => '고정한 이미지 — 클릭하여 이동';

  @override
  String get gen_select => '여러 개 선택';

  @override
  String get gen_selectDone => '선택 완료';

  @override
  String gen_selectedCount(Object count) {
    return '$count장 선택됨';
  }

  @override
  String get gen_pack => 'zip으로 묶기';

  @override
  String get gen_saveSelected => '선택한 이미지 저장';

  @override
  String get gen_removeSelected => '기록에서 제거';

  @override
  String get gen_autoSaveOn => '갤러리 자동 저장: 켜짐';

  @override
  String get gen_autoSaveOff => '갤러리 자동 저장: 꺼짐';

  @override
  String get gen_scrollLock => '스크롤 고정 (새 이미지가 와도 그대로)';

  @override
  String get gen_scrollUnlock => '스크롤 고정 해제';

  @override
  String get gen_saveAll => '모두 갤러리에 저장';

  @override
  String get gen_clearHistory => '기록 지우기';

  @override
  String get gen_clearHistoryTitle => '이번 기록을 지울까요?';

  @override
  String get gen_clearHistoryBody => '목록에서만 제거하며 갤러리에 저장된 파일은 그대로입니다.';

  @override
  String get gen_deleteImagesTitle => '기록에서 제거할까요?';

  @override
  String gen_deleteImagesBody(Object count) {
    return '$count장을 목록에서 제거합니다. 저장된 파일은 그대로입니다.';
  }

  @override
  String gen_saveBatch(Object count) {
    return '이 묶음 저장 ($count장)';
  }

  @override
  String gen_removeBatch(Object count) {
    return '이 묶음 제거 ($count장)';
  }

  @override
  String get gen_removeImage => '기록에서 제거';

  @override
  String get gen_favorite => '즐겨찾기';

  @override
  String get gen_unfavorite => '즐겨찾기 해제';

  @override
  String get gen_sendImg2Img => 'img2img로 보내기';

  @override
  String get gen_sendVibe => '바이브 트랜스퍼에 추가';

  @override
  String get gen_sendPrecise => '정밀 참조로 추가';

  @override
  String get gen_reveal => '탐색기에서 보기';

  @override
  String get gen_opUpscale => '업스케일됨';

  @override
  String get gen_opEnhance => '향상됨';

  @override
  String get gen_opVariation => '변형';

  @override
  String get gen_opInpaint => '인페인트됨';

  @override
  String get gen_opImg2Img => '이미지 투 이미지';

  @override
  String get tools_free => '무료';

  @override
  String get tools_localFree => '로컬 · 무료';

  @override
  String tools_anlasN(Object count) {
    return '$count Anlas';
  }

  @override
  String get tools_cancel => '취소';

  @override
  String get tools_close => '닫기';

  @override
  String get tools_done => '완료';

  @override
  String get tools_reset => '초기화';

  @override
  String get tools_apply => '적용';

  @override
  String get tools_retry => '다시 시도';

  @override
  String get tools_optional => '선택';

  @override
  String get tools_justNow => '방금';

  @override
  String tools_minutesAgo(Object count) {
    return '$count분 전';
  }

  @override
  String tools_hoursAgo(Object count) {
    return '$count시간 전';
  }

  @override
  String tools_monthDay(Object month, Object day) {
    return '$month월 $day일';
  }

  @override
  String get tools_useAsInit => 'img2img 원본으로 사용';

  @override
  String get tools_upscale => '업스케일';

  @override
  String get tools_enhance => '향상';

  @override
  String get tools_strength => '강도';

  @override
  String get tools_noise => '노이즈';

  @override
  String get tools_tipEnhance => '현재 프롬프트로 이 이미지를 다시 그려 디테일을 더합니다. 확대도 가능';

  @override
  String get tools_tipVariations =>
      '이 이미지 설정으로 비슷한 이미지 4장을 만듭니다. 프롬프트와 설정은 그대로';

  @override
  String get tools_tipUpscale => '저장된 설정으로 업스케일합니다. 결과는 새 이미지로 표시됩니다';

  @override
  String get tools_tipUpscaleRunning => '업스케일 중 — 클릭하면 취소';

  @override
  String get tools_tipUpscaleSettings => '로컬 / 클라우드, 방식, 모델, 배율 선택';

  @override
  String get tools_tipSetInit => '이 이미지를 img2img에 넣어 다음 생성의 원본으로 씁니다';

  @override
  String get tools_tipEdit => '브러시·선택·색 보정으로 편집하고 완료하면 img2img 원본을 교체합니다';

  @override
  String get tools_tipInpaint => '다시 그릴 영역을 마스크로 지정합니다. 나머지는 그대로';

  @override
  String get tools_tipDirector => '배경 제거, 선화, 채색, 표정 수정 등 후처리 도구';

  @override
  String get tools_upscaleRunHint => '완료되면 기록에 추가되고 다른 이미지를 보고 있지 않으면 자동 선택됩니다';

  @override
  String get tools_enhanceSub => '현재 프롬프트로 다시 그려 디테일을 더합니다. 확대도 가능';

  @override
  String get tools_enhanceScale => '확대';

  @override
  String get tools_enhanceLocal => '로컬 확대';

  @override
  String get tools_enhanceLocalRow => '로컬';

  @override
  String tools_enhanceOutLocal(Object size, Object factor) {
    return '$size → 로컬 $factor';
  }

  @override
  String get tools_enhanceMagnitude => '정도';

  @override
  String get tools_magLight => '약';

  @override
  String get tools_magMedium => '중';

  @override
  String get tools_magStrong => '강';

  @override
  String tools_enhanceValues(Object strength, Object noise) {
    return '강도 $strength · 노이즈 $noise';
  }

  @override
  String get tools_enhanceCustomTag => '사용자 지정';

  @override
  String get tools_enhanceCustom => '강도와 노이즈 직접 지정';

  @override
  String get tools_enhanceCustomHint =>
      '강도가 높을수록 많이 바뀌고, 노이즈는 디테일을 더하지만 지저분해지기 쉽습니다';

  @override
  String get tools_localHint => '생성 후 각 이미지를 로컬에서 확대합니다. 추가 Anlas 없음';

  @override
  String get tools_localNotSet => '로컬 확대 모델 미선택';

  @override
  String get tools_upscaleSettings => '업스케일 설정';

  @override
  String tools_enhanceFooter(Object model, Object steps) {
    return '현재 프롬프트 · $model · $steps스텝';
  }

  @override
  String get tools_enhanceRun => '향상';

  @override
  String get tools_enhanceRunLocal => '향상 + 로컬 확대';

  @override
  String get tools_upscaleSub => '확대 결과는 새 이미지로 표시되며 원본과 img2img 원본은 그대로입니다';

  @override
  String get tools_upscaleMethod => '방식';

  @override
  String get tools_upscaleModel => '모델';

  @override
  String get tools_upscaleManage => '모델 관리';

  @override
  String get tools_upscaleScale => '배율';

  @override
  String get tools_upscaleAdvanced => '고급 설정';

  @override
  String get tools_upscaleFooter => '설정은 저장되며 툴바의 업스케일 버튼이 이 설정을 씁니다';

  @override
  String get tools_modelMissing => '미설치';

  @override
  String get tools_modelDownloading => '다운로드 중';

  @override
  String get tools_modelNone => '선택 안 함';

  @override
  String get tools_edit => '이미지 편집';

  @override
  String get tools_editSub => '완료하면 img2img 원본을 교체합니다';

  @override
  String get tools_inpaint => '인페인트';

  @override
  String get tools_inpaintSub => '마스크한 부분만 다시 그립니다';

  @override
  String get tools_backEsc => '뒤로 (Esc)';

  @override
  String get tools_panel => '패널';

  @override
  String get tools_undo => '실행 취소';

  @override
  String get tools_redo => '다시 실행';

  @override
  String get tools_download => 'PNG 다운로드';

  @override
  String get tools_zoomIn => '확대';

  @override
  String get tools_zoomOut => '축소';

  @override
  String get tools_zoomFit => '창에 맞추기';

  @override
  String get tools_applyMask => '마스크 적용';

  @override
  String get tools_applyMaskSub => '생성 페이지로 돌아가 직접 생성';

  @override
  String get tools_applyGenerate => '적용 후 생성';

  @override
  String get tools_applyGenerateSub => '생성 페이지로 돌아가 바로 인페인트 시작';

  @override
  String get tools_discardTitle => '변경 사항을 버릴까요?';

  @override
  String get tools_discardBody => '적용하지 않은 획, 마스크, 레이어 변경이 사라집니다.';

  @override
  String get tools_discard => '버리기';

  @override
  String get tools_keepEditing => '계속 편집';

  @override
  String get tools_toolBrush => '브러시';

  @override
  String get tools_toolEraser => '지우개';

  @override
  String get tools_toolFill => '채우기';

  @override
  String get tools_toolBlur => '흐림';

  @override
  String get tools_toolStamp => '복제 도장';

  @override
  String get tools_toolSelect => '사각형 선택';

  @override
  String get tools_toolLasso => '올가미';

  @override
  String get tools_toolPicker => '스포이트';

  @override
  String get tools_toolMaskBrush => '마스크 그리기';

  @override
  String get tools_toolMaskEraser => '마스크 지우기';

  @override
  String get tools_toolFocus => '집중 영역';

  @override
  String get tools_clearMask => '마스크 지우기';

  @override
  String get tools_expand => '가장자리 확장';

  @override
  String get tools_adjust => '색 보정';

  @override
  String get tools_resize => '캔버스 크기';

  @override
  String get tools_size => '크기';

  @override
  String get tools_opacity => '불투명도';

  @override
  String get tools_intensity => '강도';

  @override
  String get tools_tolerance => '허용치';

  @override
  String get tools_tip => '팁';

  @override
  String get tools_tipHard => '단단';

  @override
  String get tools_tipSoft => '부드';

  @override
  String get tools_tipSquare => '사각';

  @override
  String get tools_pressure => '필압';

  @override
  String get tools_squareBrush => '사각 브러시';

  @override
  String get tools_hintStamp => 'Alt + 클릭으로 샘플링한 뒤 다른 곳에 칠합니다';

  @override
  String get tools_hintSelect => '드래그로 선택. Alt+L 새 레이어로 복사, Delete 지우기';

  @override
  String get tools_hintPicker => '클릭해서 색을 고릅니다. 브러시 중에도 Alt로 임시 선택';

  @override
  String get tools_hintMaskFill => '클릭하면 비슷한 색 영역을 마스크로 채웁니다';

  @override
  String get tools_focusContext => '최소 컨텍스트';

  @override
  String get tools_hintFocus =>
      '다듬을 부분을 지정하면 모델이 그 영역과 주변만 보므로 작은 얼굴과 손이 더 선명해집니다';

  @override
  String get tools_clearFocus => '집중 해제';

  @override
  String get tools_edgeTop => '위';

  @override
  String get tools_edgeBottom => '아래';

  @override
  String get tools_edgeLeft => '왼쪽';

  @override
  String get tools_edgeRight => '오른쪽';

  @override
  String tools_hintExpand(Object step) {
    return '캔버스 가장자리를 끌어도 됩니다. ${step}px 단위';
  }

  @override
  String get tools_maskLook => '마스크 표시';

  @override
  String get tools_maskBorder => '윤곽선';

  @override
  String get tools_patternSolid => '단색';

  @override
  String get tools_patternLines => '사선';

  @override
  String get tools_patternCrosshatch => '교차선';

  @override
  String get tools_patternGrid => '격자';

  @override
  String get tools_patternDots => '점';

  @override
  String get tools_patternChecker => '체커';

  @override
  String get tools_patternHearts => '하트';

  @override
  String get tools_colorPrimary => '전경색';

  @override
  String get tools_colorSecondary => '배경색';

  @override
  String get tools_moreColors => '더 많은 색…';

  @override
  String get tools_statusHint => '스페이스 이동 · 휠 확대 · Ctrl+0 맞춤 · 1 원본 크기';

  @override
  String get tools_statusGrid => '마스크가 8px 격자에 맞춰집니다';

  @override
  String get tools_statusMask => '마스크';

  @override
  String get tools_inpaintSettings => '인페인트 설정';

  @override
  String get tools_inpaintStrength => '강도';

  @override
  String get tools_inpaintStrengthHint => '낮을수록 원본에 가깝습니다';

  @override
  String get tools_mask => '마스크';

  @override
  String tools_maskCoverage(Object count) {
    return '영역 · $count곳';
  }

  @override
  String get tools_focusNone => '미설정 (전체 이미지)';

  @override
  String tools_focusContextShort(Object value) {
    return '· 컨텍스트 $value';
  }

  @override
  String get tools_output => '출력';

  @override
  String get tools_expandTag => '확장';

  @override
  String get tools_layers => '레이어';

  @override
  String get tools_addLayer => '레이어 추가';

  @override
  String get tools_add3dLayer => '3D 레이어 추가';

  @override
  String get tools_layerHint => 'Alt+L 선택 영역을 새 레이어로 복사';

  @override
  String get tools_hideLayer => '레이어 숨기기';

  @override
  String get tools_showLayer => '레이어 표시';

  @override
  String get tools_layerUp => '위로';

  @override
  String get tools_layerDown => '아래로';

  @override
  String get tools_layerDuplicate => '복제';

  @override
  String get tools_layerMerge => '아래와 병합';

  @override
  String get tools_layerDelete => '레이어 삭제';

  @override
  String get tools_currentLayer => '현재 레이어';

  @override
  String get tools_hue => '색조';

  @override
  String get tools_saturation => '채도';

  @override
  String get tools_brightness => '밝기';

  @override
  String get tools_canvas => '캔버스';

  @override
  String get tools_resizeCanvas => '크기 변경';

  @override
  String get tools_inpaintNote =>
      '적용하면 생성 페이지로 돌아가 인페인트로 전환됩니다. 오른쪽 위 메뉴의 “적용 후 생성”으로 바로 실행할 수도 있습니다';

  @override
  String get tools_director => '디렉터 도구';

  @override
  String get tools_backGen => '생성';

  @override
  String get tools_dtGroupClean => '정리';

  @override
  String get tools_dtGroupLine => '선';

  @override
  String get tools_dtGroupColor => '채색과 표정';

  @override
  String get tools_dtGroupPixel => '픽셀';

  @override
  String get tools_dtRemoveBg => '배경 제거';

  @override
  String get tools_dtRemoveBgDesc => '인물을 잘라내 투명 배경·배경·합성 3장을 만듭니다';

  @override
  String get tools_dtDeclutter => '잡선 정리';

  @override
  String get tools_dtDeclutterDesc => '불필요한 선과 노이즈를 지웁니다';

  @override
  String get tools_dtLineArt => '선화 추출';

  @override
  String get tools_dtLineArtDesc => '깔끔한 흑백 선화를 추출';

  @override
  String get tools_dtSketch => '스케치화';

  @override
  String get tools_dtSketchDesc => '연필 스케치 느낌으로 바꿉니다';

  @override
  String get tools_dtColorize => '채색';

  @override
  String get tools_dtColorizeDesc => '선화나 스케치에 채색. 프롬프트 선택';

  @override
  String get tools_dtEmotion => '표정 수정';

  @override
  String get tools_dtEmotionDesc => '표정을 바꿉니다. 강도 조절 가능';

  @override
  String get tools_dtPixelSnap => '픽셀 정렬';

  @override
  String get tools_dtPixelSnapDesc => '픽셀 격자에 맞추고 팔레트를 줄입니다. 로컬 처리';

  @override
  String get tools_dtOpusNote => 'Opus는 1MP 이하 무료이며 배경 제거는 항상 Anlas가 듭니다';

  @override
  String get tools_input => '입력';

  @override
  String get tools_compareSide => '나란히';

  @override
  String get tools_compareWipe => '슬라이드 비교';

  @override
  String get tools_compareResult => '결과만';

  @override
  String get tools_fit => '맞춤';

  @override
  String get tools_actualSize => '원본 크기 100%';

  @override
  String get tools_original => '원본';

  @override
  String get tools_emptyRun => '“실행”을 눌러 시작';

  @override
  String get tools_emptyEmotion => '표정을 고른 뒤 “실행”';

  @override
  String get tools_emptyBody => '결과가 여기에 원본과 나란히 표시됩니다';

  @override
  String tools_running(Object tool) {
    return '$tool 실행 중…';
  }

  @override
  String get tools_runningBody => '보통 몇 초면 끝나며 결과는 생성 페이지 기록에도 들어갑니다';

  @override
  String get tools_runFailed => '실행 실패';

  @override
  String get tools_noInput => '먼저 이미지를 추가하세요';

  @override
  String get tools_noInputBody => '끌어 놓거나 Ctrl+V로 붙여넣거나 생성 기록에서 고르세요';

  @override
  String get tools_noResult => '아직 결과가 없습니다';

  @override
  String get tools_continue => '계속 처리';

  @override
  String get tools_copy => '복사';

  @override
  String get tools_saveGallery => '갤러리에 저장';

  @override
  String get tools_queue => '입력 대기열';

  @override
  String tools_queueCount(Object count) {
    return '$count장';
  }

  @override
  String get tools_queueHint => '＋: 파일 가져오기 / 생성 기록에서 선택. 끌어 놓기나 Ctrl+V도 가능';

  @override
  String get tools_importFiles => '파일 가져오기';

  @override
  String get tools_fromHistory => '생성 기록에서 선택';

  @override
  String get tools_paste => '붙여넣기';

  @override
  String get tools_removeInput => '대기열에서 제거';

  @override
  String get tools_dtOptions => '옵션';

  @override
  String get tools_dtNoOptionsBg =>
      '배경 제거는 조절할 옵션이 없습니다. 투명 배경·배경·합성 3장이 나오며 결과 아래에서 전환합니다.';

  @override
  String get tools_dtNoOptionsDeclutter => '잡선 정리는 옵션이 없습니다. 선화는 “선화 추출”을 쓰세요.';

  @override
  String get tools_dtNoOptionsLineArt =>
      '선화 추출은 옵션이 없습니다. 채색하려면 결과를 “계속 처리”한 뒤 “채색”을 고르세요.';

  @override
  String get tools_dtNoOptionsSketch =>
      '스케치화는 옵션이 없습니다. 깔끔한 선은 “선화 추출”, 채색은 “계속 처리” 후 “채색”을 쓰세요.';

  @override
  String get tools_dtEmotionLabel => '표정';

  @override
  String tools_dtEmotionMore(Object count) {
    return '$count개 더';
  }

  @override
  String get tools_dtEmotionLess => '접기';

  @override
  String get tools_dtStrength => '강도';

  @override
  String get tools_defry0 => '보통';

  @override
  String get tools_defry1 => '약간 약';

  @override
  String get tools_defry2 => '약';

  @override
  String get tools_defry3 => '더 약';

  @override
  String get tools_defry4 => '매우 약';

  @override
  String get tools_defry5 => '최약';

  @override
  String get tools_dtEmotionStrengthHint => '약할수록 원래 표정에 가깝습니다';

  @override
  String get tools_dtColorizeStrengthHint => '약할수록 원래 선에 가깝습니다';

  @override
  String get tools_dtPrompt => '추가 프롬프트';

  @override
  String get tools_dtPromptHint => '영어 태그를 쉼표로 구분';

  @override
  String get tools_dtEmotionPromptHint => '표정을 고르면 자주 쓰는 태그가 들어갑니다. 수정 가능';

  @override
  String get tools_dtColorizePromptHint =>
      '원하는 색을 적으세요. 예: blue dress, silver hair';

  @override
  String get tools_dtPalette => '팔레트';

  @override
  String get tools_dtPaletteOff => '끔';

  @override
  String get tools_dtPaletteAuto => '자동';

  @override
  String get tools_dtPaletteCustom => '사용자 지정';

  @override
  String get tools_dtColors => '색 수';

  @override
  String get tools_dtAvoidRefine => '과도한 세분화 방지';

  @override
  String get tools_dtAvoidRefineHint => '세밀한 격자의 효과가 작으면 거친 격자 유지';

  @override
  String get tools_dtPixelUpscale => '원래 크기로 확대';

  @override
  String get tools_dtPixelUpscaleHint => '끄면 칸마다 1픽셀인 작은 이미지를 출력';

  @override
  String tools_runTool(Object tool) {
    return '$tool 실행';
  }

  @override
  String get tools_runHint => '실행 · 현재 입력 처리';

  @override
  String get tools_runNeedInput => '아래에 입력을 먼저 추가하세요';

  @override
  String get tools_results => '결과';

  @override
  String get tools_resultsEmpty => '실행한 결과가 여기에 표시됩니다';

  @override
  String get tools_resultsHint =>
      '결과를 눌러 다시 봅니다. 생성 기록에도 들어가니 남길 것은 갤러리에 저장하세요';

  @override
  String get tools_reuse => '설정 재사용';

  @override
  String get tools_emoNeutral => '평온';

  @override
  String get tools_emoHappy => '행복';

  @override
  String get tools_emoSad => '슬픔';

  @override
  String get tools_emoAngry => '화남';

  @override
  String get tools_emoScared => '두려움';

  @override
  String get tools_emoSurprised => '놀람';

  @override
  String get tools_emoTired => '피곤';

  @override
  String get tools_emoExcited => '신남';

  @override
  String get tools_emoNervous => '긴장';

  @override
  String get tools_emoThinking => '생각';

  @override
  String get tools_emoConfused => '혼란';

  @override
  String get tools_emoShy => '수줍음';

  @override
  String get tools_emoDisgusted => '혐오';

  @override
  String get tools_emoSmug => '의기양양';

  @override
  String get tools_emoBored => '지루함';

  @override
  String get tools_emoLaughing => '폭소';

  @override
  String get tools_emoIrritated => '짜증';

  @override
  String get tools_emoAroused => '흥분';

  @override
  String get tools_emoEmbarrassed => '당황';

  @override
  String get tools_emoWorried => '걱정';

  @override
  String get tools_emoLove => '사랑';

  @override
  String get tools_emoDetermined => '결연';

  @override
  String get tools_emoHurt => '상처';

  @override
  String get tools_emoPlayful => '장난';

  @override
  String get auth_logoutConfirm => '현재 계정에서 로그아웃하시겠습니까?';

  @override
  String get naiAgent_title => 'NAI Agent';

  @override
  String get naiAgent_local => '로컬';

  @override
  String get naiAgent_permissionMode => '승인 모드';

  @override
  String get naiAgent_permissionAuto => '자동';

  @override
  String get naiAgent_permissionAsk => '확인';

  @override
  String get naiAgent_permissionReadOnly => '읽기 전용';

  @override
  String get naiAgent_permissionAutoHint =>
      '일반 작업 공간 편집은 자동 실행합니다. 명령, 삭제 및 알 수 없는 도구는 승인이 필요하며 이미지 생성 확인도 유지합니다.';

  @override
  String get naiAgent_permissionAskHint =>
      '작업 공간 읽기는 바로 실행합니다. 편집, 명령 및 알 수 없는 도구는 매번 승인하며 이미지 생성은 비용 확인을 거칩니다.';

  @override
  String get naiAgent_permissionReadOnlyHint =>
      '읽기와 대화만 가능하며 편집, 이미지 생성 및 알 수 없는 도구는 차단합니다. 전환 시 Agent 작업만 중지하고 수동 생성은 유지합니다.';

  @override
  String get naiAgent_useModelSetting => '모델 설정 사용';

  @override
  String get naiAgent_permissionTitle => '도구 승인이 필요합니다';

  @override
  String get naiAgent_permissionOnce => '한 번 허용';

  @override
  String get naiAgent_permissionSession => '이 세션에서 동일한 호출 허용';

  @override
  String get naiAgent_permissionDeny => '거부';

  @override
  String get naiAgent_thinking => '사고 강도 · 다음 작업부터 적용';

  @override
  String get naiAgent_thinkingUnsupported =>
      '조절 가능한 사고 수준이 확인되지 않았습니다. 먼저 모델 설정을 확인하세요.';

  @override
  String get naiAgent_pasteImage => '클립보드 이미지 붙여넣기';

  @override
  String get naiAgent_contextUnknown =>
      '모델 컨텍스트 한도와 실제 사용량이 확인될 때까지 표시할 수 없습니다.';

  @override
  String naiAgent_contextTooltip(
    String percent,
    String remaining,
    String window,
  ) {
    return '사용 가능한 컨텍스트 $percent%\n남은 토큰 $remaining / $window\n클릭하여 상세 통계 보기';
  }

  @override
  String get naiAgent_statistics => '컨텍스트 및 대화 통계';

  @override
  String get naiAgent_contextUsage => '현재 컨텍스트 사용량 · 추정';

  @override
  String get naiAgent_contextRemaining => '남은 컨텍스트';

  @override
  String get naiAgent_contextWindow => '모델 컨텍스트 한도';

  @override
  String get naiAgent_sessionUsage => '세션 누적 사용량';

  @override
  String get naiAgent_tokensInput => '입력';

  @override
  String get naiAgent_tokensOutput => '출력';

  @override
  String get naiAgent_tokensCacheRead => '캐시 읽기';

  @override
  String get naiAgent_tokensCacheWrite => '캐시 쓰기';

  @override
  String get naiAgent_tokensTotal => '누적 토큰';

  @override
  String get naiAgent_cumulativeUsageHint =>
      '누적 사용량에는 이전 요청이 포함되며 현재 컨텍스트 크기와 다릅니다.';

  @override
  String get naiAgent_messageCounts => '대화 기록';

  @override
  String get naiAgent_userAssistantMessages => '사용자 / 어시스턴트';

  @override
  String get naiAgent_toolCalls => '도구 호출';

  @override
  String get naiAgent_cost => '비용';

  @override
  String get naiAgent_defaultWorkspace => '작업 공간 1';

  @override
  String get naiAgent_newChat => '새 채팅';

  @override
  String get naiAgent_settings => 'Agent 설정';

  @override
  String get naiAgent_workspace => '작업 공간';

  @override
  String get naiAgent_createWorkspace => '새 작업 공간';

  @override
  String get naiAgent_rename => '이름 변경';

  @override
  String get naiAgent_name => '이름';

  @override
  String get naiAgent_placeholder => '아이디어나 질문을 입력하세요…';

  @override
  String get naiAgent_welcome => '하나의 아이디어에서 시작';

  @override
  String get naiAgent_welcomeHint =>
      '프롬프트를 논의하고 이미지를 분석하며 작업 공간을 정리하세요.\n먼저 이야기를 나눈 뒤 작업을 시작하세요.';

  @override
  String get naiAgent_suggestCurrent => '현재 초안 확인';

  @override
  String get naiAgent_suggestImage => '참조 이미지 분석';

  @override
  String get naiAgent_suggestWorkspace => '작업 공간 정리';

  @override
  String get naiAgent_brandEyebrow => 'YOUR CREATIVE CO-PILOT';

  @override
  String get naiAgent_promptCurrent => '현재 초안과 매개변수를 확인해 주세요. 아직 변경하지 마세요.';

  @override
  String get naiAgent_promptImage => '현재 이미지의 구도와 화풍을 분석해 주세요. 아직 생성하지 마세요.';

  @override
  String get naiAgent_promptWorkspace =>
      '현재 작업 공간을 살펴보고 정리 방법을 제안해 주세요. 아직 변경하지 마세요.';

  @override
  String get naiAgent_tipTitle => 'TIPS / 도움말';

  @override
  String get naiAgent_tipNext => '다음 도움말';

  @override
  String get naiAgent_tipReadOnly => '먼저 \'읽기 전용\' 모드로 살펴본 뒤 변경할 내용을 정하세요.';

  @override
  String get naiAgent_tipAttachments =>
      '참조 이미지를 드래그하거나 + 로 첨부해 더 구체적으로 이야기하세요.';

  @override
  String get naiAgent_tipGeneration => '이미지 생성은 비용을 표시하고 확인을 받은 뒤 실행합니다.';

  @override
  String get naiAgent_welcomeFootnote => '모든 작업은 현재 승인 모드를 따릅니다';

  @override
  String get naiAgent_chooseModel => '모델 선택';

  @override
  String get naiAgent_modelSettings => '모델 및 인터페이스 관리';

  @override
  String get naiAgent_attach => '이미지 첨부';

  @override
  String get naiAgent_removeAttachment => '첨부 제거';

  @override
  String get naiAgent_selectedImage => '선택한 이미지 첨부';

  @override
  String get naiAgent_send => '보내기';

  @override
  String get naiAgent_stop => '작업 중지';

  @override
  String get naiAgent_queue => '대기열';

  @override
  String get naiAgent_steer => '지시 추가';

  @override
  String get naiAgent_promote => '지시로 전환';

  @override
  String get naiAgent_waiting => '답변을 기다리는 중';

  @override
  String get naiAgent_working => '처리 중';

  @override
  String get naiAgent_waitingSlot => '서비스 요청 슬롯 대기 중';

  @override
  String get naiAgent_starting => '채팅 여는 중';

  @override
  String get naiAgent_interrupted => '이전 작업이 중단되었으며 자동으로 다시 보내지 않았습니다.';

  @override
  String get naiAgent_restorePending => '입력창으로 복원';

  @override
  String get naiAgent_withdraw => '회수';

  @override
  String get naiAgent_newContent => '최신 메시지로 이동';

  @override
  String get naiAgent_toolRunning => '실행 중';

  @override
  String get naiAgent_toolDone => '완료';

  @override
  String get naiAgent_toolFailed => '실패';

  @override
  String get naiAgent_arguments => '인수';

  @override
  String get naiAgent_result => '결과';

  @override
  String get naiAgent_systemPrompt => '시스템 프롬프트';

  @override
  String get naiAgent_promptHelp =>
      '사용자 지정 내용은 기본 프롬프트를 대체합니다. 도구 지도는 앱이 추가하며 이후 요청에 적용됩니다.';

  @override
  String get naiAgent_restoreDefault => '기본값 복원';

  @override
  String get naiAgent_showEffective => '적용되는 프롬프트 보기';

  @override
  String get naiAgent_useGlobal => '전역 프롬프트 사용';

  @override
  String get naiAgent_save => '저장';

  @override
  String get naiAgent_runLimit => '작업당 모델 요청 한도';

  @override
  String get naiAgent_enterSends => 'Enter로 전송, Shift+Enter로 줄바꿈';

  @override
  String get naiAgent_dataFolder => '작업 공간 데이터 폴더';

  @override
  String get naiAgent_openFolder => '폴더 열기';

  @override
  String get naiAgent_toolsManuals => '도구 및 매뉴얼';

  @override
  String get naiAgent_toolsHint =>
      '현재 상태, 이미지, 프롬프트 및 작업 공간 파일을 필요할 때 호출하며 모델별 NAI 매뉴얼을 읽습니다.';

  @override
  String get naiAgent_unknownCost => '실제 비용은 서비스 제공자 기준';

  @override
  String get naiAgent_error => '작업에 실패했습니다. 모델 설정이나 파일을 확인하세요.';

  @override
  String get naiAgent_visionDisabled =>
      '이 모델의 이미지 입력이 활성화되지 않았습니다. 모델 설정에서 지원 여부를 확인하세요.';

  @override
  String get naiAgent_inputChanged => '준비 중 입력이 변경되었습니다. 현재 초안을 보내세요.';

  @override
  String get naiAgent_imageLimit => '잘못된 이미지 형식이거나 업로드 한도를 초과했습니다.';

  @override
  String get naiAgent_composerNotEmpty => '현재 입력을 저장하거나 보낸 후 이 메시지를 복원하세요.';

  @override
  String get naiAgent_compact => '채팅 컨텍스트 압축';

  @override
  String get naiAgent_export => '채팅 내보내기';

  @override
  String get naiAgent_copyMessage => '메시지 복사';

  @override
  String get naiAgent_editMessage => '메시지 편집';

  @override
  String get naiAgent_regenerate => '답변 다시 생성';

  @override
  String get naiAgent_submitAnswer => '답변 제출';

  @override
  String get naiAgent_customAnswer => '직접 답변을 입력할 수도 있습니다';

  @override
  String get naiAgent_close => '패널 접기';

  @override
  String get naiAgent_showChats => '채팅 목록';

  @override
  String get naiAgent_runtimeMissing => 'Agent 런타임이 없습니다. 전체 업데이트 패키지를 사용하세요.';

  @override
  String get naiAgent_usage => '모델 사용량';

  @override
  String get naiAgent_cancel => '취소';

  @override
  String get naiAgent_dropHint => '놓아서 이 채팅에 첨부';

  @override
  String get naiAgent_emptyAttachment => '이미지를 읽을 수 없음';

  @override
  String get naiAgent_globalScope => '전역 기본값';

  @override
  String get naiAgent_workspaceScope => '현재 작업 공간';

  @override
  String get naiAgent_generationTitle => '생성 승인';

  @override
  String get naiAgent_generationWaiting => '생성 승인 대기 중';

  @override
  String naiAgent_generationAccount(Object name) {
    return '계정: $name';
  }

  @override
  String naiAgent_generationBatch(Object requests, Object size, Object total) {
    return '요청 $requests회 × $size장 · 총 $total장';
  }

  @override
  String naiAgent_generationUnit(Object cost) {
    return '요청당 $cost Anlas';
  }

  @override
  String naiAgent_generationEncoding(Object cost) {
    return '참조 이미지 인코딩: $cost Anlas';
  }

  @override
  String naiAgent_generationTotal(Object cost) {
    return '예상 $cost Anlas';
  }

  @override
  String naiAgent_generationBalance(Object balance) {
    return '현재 잔액 $balance Anlas';
  }

  @override
  String get naiAgent_generationEstimateNote => '비용은 예상치이며 실제 차감액은 서버에서 결정합니다.';

  @override
  String get naiAgent_generationChanged => '설정 또는 견적이 변경되었습니다. 다시 준비해 주세요.';

  @override
  String naiAgent_generationLocalEnhance(Object model, Object scale) {
    return '생성 후 로컬 업스케일: $model ×$scale';
  }

  @override
  String get naiAgent_generationText => '텍스트로 이미지 생성';

  @override
  String get naiAgent_generationImage => '이미지로 이미지 생성';

  @override
  String get naiAgent_generationInpaint => '인페인트';

  @override
  String naiAgent_galleryDeleteEmptyFolderConfirm(String path) {
    return '이 빈 폴더와 갤러리 분류를 삭제할까요? 다른 폴더의 이미지는 유지됩니다.\n$path';
  }

  @override
  String get naiAgent_extensions => '확장';

  @override
  String get naiAgent_interactionExtension => 'Studio 연동';

  @override
  String get naiAgent_extensionRequired => '내장 · 필수';

  @override
  String get naiAgent_interactionExtensionHint =>
      '필요할 때 현재 Studio 상태를 읽고 질문 카드로 답변을 받습니다.';

  @override
  String get naiAgent_extensionAddFile => '확장 파일 추가';

  @override
  String get naiAgent_extensionAddFolder => '확장 폴더 추가';

  @override
  String get naiAgent_extensionsHint =>
      '확장은 작업 공간별로 로드됩니다. 변경 사항은 현재 작업이 끝난 뒤 다음 전송에 적용됩니다. 외부 확장은 로컬 코드를 실행하므로 신뢰할 수 있는 출처를 선택하세요.';

  @override
  String get naiAgent_extensionError => '확장 실행 실패';

  @override
  String get naiAgent_extensionCompatibility =>
      '로컬 Pi 확장과 패키지 폴더, 도구, 명령 및 표준 대화 상자를 지원합니다. 터미널 전용 사용자 지정 UI는 데스크톱에 표시되지 않습니다.';

  @override
  String get naiAgent_instructions => '지침';

  @override
  String get naiAgent_globalInstructions => '전역 지침';

  @override
  String get naiAgent_globalInstructionsHelp =>
      '모든 작업 공간에서 사용합니다. 언어, 문체 또는 작업 선호도를 입력할 수 있습니다. 비워 두면 이 부분이 비활성화됩니다.';

  @override
  String get naiAgent_systemPromptPrefix => '시스템 프롬프트 앞부분';

  @override
  String get naiAgent_systemPromptPrefixHelp =>
      'NAI Agent 기본 프롬프트 앞에 삽입하며 기본 프롬프트와 도구 맵을 유지합니다. 비워 두면 이 부분이 비활성화됩니다.';

  @override
  String get naiAgent_instructionOrder =>
      '적용 순서: 앞부분 → 기본 프롬프트 → 전역 지침 → 작업 공간 규칙. 이후 요청부터 적용됩니다.';

  @override
  String get naiAgent_saveInstructions => '지침 저장';

  @override
  String get naiAgent_mcpBuiltin => 'NAI Studio · 내장 도구';

  @override
  String get naiAgent_mcpBuiltinHint =>
      '프롬프트, 블록, 위키, 이미지, 기록, 참조, 생성 및 설정 도구입니다. 기본적으로 필요할 때 검색하며 기존 백업, 버전 확인 및 사용자 확인이 유지됩니다.';

  @override
  String get naiAgent_mcpAdd => 'MCP 서버 추가';

  @override
  String get naiAgent_mcpName => '서버 이름';

  @override
  String get naiAgent_mcpConfig => '서버 설정 (JSON)';

  @override
  String get naiAgent_mcpConfigHint =>
      'stdio 및 Streamable HTTP를 지원합니다. 서버 설정 객체 하나를 붙여 넣으세요. command는 실행 파일이고 args는 배열입니다. env, cwd, url, headers, oauth, toolExposure도 지원합니다. 설정은 암호화하여 저장됩니다.';

  @override
  String get naiAgent_mcpStatus => '연결 상태 확인';

  @override
  String get naiAgent_mcpReconnect => '다시 연결';

  @override
  String get naiAgent_mcpLogin => '로그인';

  @override
  String get naiAgent_mcpLogout => '로그아웃';

  @override
  String get naiAgent_mcpHint =>
      '기본적으로 CodeMode가 필요할 때 도구를 검색합니다. codemode: 샌드박스 호출; deferred: 검색 후 직접 호출; direct: 항상 공개; hidden: 숨김. 변경은 다음 유휴 호출에 적용됩니다. 연결 확인은 채팅 모델을 호출하지 않습니다.';

  @override
  String get generation_generate => '생성';

  @override
  String get detail_imageDetails => '이미지 상세 정보';

  @override
  String get promptBlockLibrary_title => '프롬프트 블록';

  @override
  String get gen_oldImageLabel => 'OLD';

  @override
  String get gen_compareOriginal => '누르고 있는 동안 원본 이미지와 인페인트 영역 비교';

  @override
  String get naiAgent_importingImages => '이미지 읽는 중…';

  @override
  String get naiAgent_imageTooLarge => '이미지가 64 MiB 또는 6,400만 픽셀을 초과합니다.';

  @override
  String get naiAgent_linkOnlyImage =>
      '이 소스에는 링크만 있습니다. 이미지 파일을 저장한 뒤 여기로 드래그하세요.';

  @override
  String get naiAgent_invalidImage =>
      '이미지를 읽을 수 없습니다. PNG, JPEG, WebP, GIF 또는 BMP 파일을 사용하세요.';

  @override
  String naiAgent_importResult(int added, int failed) {
    return '이미지 $added개 추가, $failed개 실패했습니다.';
  }

  @override
  String get naiAgent_attachmentMetadata => '원본 이미지 메타데이터';

  @override
  String get channel_themeCircuit => '회로';

  @override
  String get channel_themeStars => '성도';

  @override
  String get channel_themeHerb => '식물 표본';

  @override
  String get channel_themeArcade => '회랑';

  @override
  String get channel_themeAbyss => '심해';

  @override
  String get channel_themeWave => '청해파';

  @override
  String get channel_descCircuit =>
      '양쪽에 버스가 두 줄씩 내려가며 분기·패드·칩이 붙습니다. 대기 중에는 빛이 버스를 따라 흐릅니다';

  @override
  String get channel_descStars =>
      '별, 별자리 선, 눈금 고리와 적위 눈금. 대기 중에는 밝은 별이 살짝 반짝입니다';

  @override
  String get channel_descHerb =>
      '먹선 표본이 양쪽에서 자라며 잎·꽃·테이프·번호 라벨이 붙습니다. 대기 중에는 바람에 흔들립니다';

  @override
  String get channel_descArcade =>
      '성당 평면도. 이미지는 신랑을 따라가고 양쪽에 기둥·리브 볼트·창·축 번호·치수선';

  @override
  String get channel_descAbyss =>
      '내려갈수록 깊어집니다(오래될수록). 수심계, 등심선, 떠오르는 거품과 내리는 바다눈';

  @override
  String get channel_descWave =>
      '일본풍 물결이 양쪽에 모이고 붉은 해와 안개 띠가 있습니다. 대기 중에는 빛이 물결을 훑습니다';

  @override
  String get channel_title => '비주얼 채널';

  @override
  String get channel_new => 'NEW';

  @override
  String get channel_subtitle => '스크롤할 때 양쪽에 보이는 장식. 이미지 바깥에만 그려집니다';

  @override
  String get channel_paused => '생성 중 · 애니메이션 일시정지';

  @override
  String get channel_modeOff => '끄기';

  @override
  String get channel_modeFixed => '고정';

  @override
  String get channel_modeRandom => '매번 무작위';

  @override
  String get channel_session => '이번';

  @override
  String get channel_reroll => '다시 섞기';

  @override
  String get channel_offNote => '끄면 지금의 픽셀 무늬가 유지됩니다';

  @override
  String get channel_minTwo => '무작위에는 테마가 두 개 이상 필요합니다';

  @override
  String get channel_level => '농도';

  @override
  String get channel_levelSoft => '연하게';

  @override
  String get channel_levelStandard => '보통';

  @override
  String get channel_levelStrong => '진하게';

  @override
  String get channel_ruler => '시간 눈금';

  @override
  String get channel_rulerSub => '배치 시간, 날짜 구분선과 오른쪽 스크러버';

  @override
  String get channel_motion => '대기 중 움직임';

  @override
  String get channel_motionSub => '아주 가벼운 움직임. 생성 중에는 자동으로 멈춥니다';

  @override
  String get channel_toastTitle => '이번 채널';

  @override
  String channel_batch(String time, int count) {
    return '$time · $count장';
  }

  @override
  String channel_batchNewest(String time, int count) {
    return '$time · $count장 · 최신';
  }

  @override
  String channel_batchPending(int count) {
    return '생성 중 · $count장';
  }

  @override
  String channel_dayToday(String date) {
    return '오늘 · $date';
  }

  @override
  String channel_dayYesterday(String date) {
    return '어제 · $date';
  }

  @override
  String channel_monthDayWeek(int month, int day, String weekday) {
    return '$month월 $day일 $weekday';
  }

  @override
  String get channel_weekday1 => '월';

  @override
  String get channel_weekday2 => '화';

  @override
  String get channel_weekday3 => '수';

  @override
  String get channel_weekday4 => '목';

  @override
  String get channel_weekday5 => '금';

  @override
  String get channel_weekday6 => '토';

  @override
  String get channel_weekday7 => '일';

  @override
  String channel_scrubWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get rag_title => 'RAG 벡터 시스템';

  @override
  String get rag_description => '로컬 검색, 모델 및 문맥 태그 추천 관리';

  @override
  String get rag_enabled => 'RAG 사용';

  @override
  String get rag_enabledHint => '로컬 의미 검색을 켭니다. 최초 색인은 범위를 확인한 후 시작합니다.';

  @override
  String get rag_status => '실행 및 색인 상태';

  @override
  String get rag_off => '꺼짐';

  @override
  String get rag_loading => '로컬 모델 준비 중';

  @override
  String get rag_empty => '모델 연결됨 · 색인 대기';

  @override
  String get rag_ready => '의미 검색 준비 완료';

  @override
  String get rag_partial => '일부 준비됨 · 나머지는 일반 검색';

  @override
  String get rag_building => '색인 생성 중';

  @override
  String get rag_paused => '색인 생성 일시 정지 · 기존 색인은 검색 가능';

  @override
  String get rag_unavailable => 'RAG 사용 불가 · 일반 검색 가능';

  @override
  String get rag_operationFailed => '작업에 실패했습니다. 모델 경로와 전용 환경을 확인하세요.';

  @override
  String rag_indexCounts(int indexed, int total) {
    return '색인 완료 $indexed / $total개';
  }

  @override
  String rag_storage(String size) {
    return '색인 용량: $size MiB';
  }

  @override
  String get rag_refresh => '상태 새로 고침';

  @override
  String get rag_embeddingPath => 'EmbeddingGemma 2 모델 폴더';

  @override
  String get rag_rerankerPath => 'Qwen3-Reranker-0.6B 모델 폴더';

  @override
  String get rag_notConfigured => '설정되지 않음';

  @override
  String get rag_choose => '선택';

  @override
  String get rag_modelMode => '모델 기능';

  @override
  String get rag_modelModeHint =>
      'Gemma는 텍스트·이미지를 지원하며 오디오는 끕니다. 태그 작업은 텍스트만 로드하고 Qwen으로 재정렬합니다.';

  @override
  String get rag_discover => '로컬 모델 찾기';

  @override
  String get rag_modelsMissing => '모델을 찾지 못했습니다. 다운로드한 모델 폴더를 선택하세요.';

  @override
  String get rag_pythonPath => '전용 Python 실행 환경';

  @override
  String get rag_runtime => '추론 실행 환경';

  @override
  String get rag_runtimeHint => '전용 환경을 사용합니다. 기존 업스케일 환경은 유지되며 모델은 별도로 선택합니다.';

  @override
  String get rag_installRuntime => '전용 실행 환경 설치';

  @override
  String get rag_installHint =>
      'Python과 추론 패키지를 다운로드합니다. CUDA는 수 GB와 호환 NVIDIA GPU가 필요하며 CPU 버전은 더 작습니다. 모델 파일은 별도입니다.';

  @override
  String get rag_installing => '실행 환경 설치 중';

  @override
  String get rag_device => '실행 장치';

  @override
  String get rag_auto => '자동 선택';

  @override
  String get rag_tagsEnabled => '문맥 기반 태그 추천';

  @override
  String get rag_tagsHint => '의미·공기 관계·재정렬을 결합하며 입력란, 캐릭터, 정·부정을 분리합니다.';

  @override
  String get rag_context => '추천 문맥 범위';

  @override
  String get rag_contextHint =>
      '두 모드 모두 태그 경계 기준 최대 120 Gemma 토큰입니다. 전체 입력은 중복 제거에만 사용합니다.';

  @override
  String get rag_contextBefore => '커서 앞 · 120 tokens';

  @override
  String get rag_contextAround => '커서 주변 · 120 tokens';

  @override
  String get rag_buildIndex => '미리 보기 및 색인 생성';

  @override
  String rag_plan(int total) {
    return '현재 태그 $total개와 별칭, 기존 로컬 설명을 색인합니다. 최초 작업은 시간이 걸리며 일시 정지와 부분 사용이 가능합니다.';
  }

  @override
  String get rag_start => '색인 시작';

  @override
  String get rag_pause => '색인 일시 정지';

  @override
  String get rag_resume => '색인 계속';

  @override
  String get rag_rebuild => '색인 다시 생성';

  @override
  String get rag_clear => '색인 삭제';

  @override
  String get rag_clearHint =>
      '원본 콘텐츠와 모델을 유지하고 이 파생 색인만 삭제합니다. 다시 구축하면 사용할 수 있습니다.';

  @override
  String get rag_futureSources =>
      '태그 추천, Wiki 및 프롬프트 블록 검색이 연결되었습니다. 작업 공간, 갤러리, Agent 검색은 단계적으로 연결됩니다.';

  @override
  String get rag_badgeHint => '로컬 의미 검색을 사용할 수 있습니다';

  @override
  String get rag_wikiEnabled => 'Wiki 의미 검색';

  @override
  String get rag_wikiHint =>
      '로컬 문서 본문을 색인합니다. 정확한 이름 일치를 우선하고 의미 검색 결과로 보완합니다. 첫 색인은 범위를 확인한 뒤 시작하세요.';

  @override
  String get rag_blocksEnabled => '프롬프트 블록 의미 검색';

  @override
  String get rag_blocksHint =>
      '저장된 활성 블록의 제목, 태그, 긍정·부정 텍스트만 색인합니다. 이미지와 저장하지 않은 초안은 제외합니다.';

  @override
  String rag_textPlan(int documents, int total) {
    return '저장된 자료 $documents개를 텍스트 조각 $total개로 색인합니다. 첫 작업은 직접 시작하고 이후에는 변경분만 갱신합니다. 일시 중지하거나 완료된 부분을 검색할 수 있습니다.';
  }

  @override
  String rag_textCounts(int indexed, int total) {
    return '색인된 텍스트 조각 $indexed / $total개';
  }
}
