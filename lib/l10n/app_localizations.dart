import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'W.O.F NAI Studio'**
  String get app_title;

  /// No description provided for @settings_visualAssets.
  ///
  /// In en, this message translates to:
  /// **'Interface fonts & licenses'**
  String get settings_visualAssets;

  /// No description provided for @brand_entryTagline.
  ///
  /// In en, this message translates to:
  /// **'A place for your imagination.'**
  String get brand_entryTagline;

  /// No description provided for @brand_switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get brand_switchToLight;

  /// No description provided for @brand_switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get brand_switchToDark;

  /// No description provided for @app_subtitle.
  ///
  /// In en, this message translates to:
  /// **'NovelAI Third-party Client'**
  String get app_subtitle;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @onlineFav_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get onlineFav_all;

  /// No description provided for @onlineFav_rootCollection.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get onlineFav_rootCollection;

  /// No description provided for @onlineFav_newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get onlineFav_newCollection;

  /// No description provided for @onlineFav_renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get onlineFav_renameCollection;

  /// No description provided for @onlineFav_deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get onlineFav_deleteCollection;

  /// No description provided for @onlineFav_empty.
  ///
  /// In en, this message translates to:
  /// **'No favorited works yet'**
  String get onlineFav_empty;

  /// No description provided for @onlineFav_authorWorkCount.
  ///
  /// In en, this message translates to:
  /// **'{n} works'**
  String onlineFav_authorWorkCount(Object n);

  /// No description provided for @onlineFav_moveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get onlineFav_moveHere;

  /// No description provided for @onlineFav_removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get onlineFav_removeFavorite;

  /// No description provided for @onlineFav_favoriteAuthor.
  ///
  /// In en, this message translates to:
  /// **'Favorite Author'**
  String get onlineFav_favoriteAuthor;

  /// No description provided for @onlineFav_unfavoriteAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite author'**
  String get onlineFav_unfavoriteAuthor;

  /// No description provided for @onlineFav_authorFavorited.
  ///
  /// In en, this message translates to:
  /// **'Author favorited'**
  String get onlineFav_authorFavorited;

  /// No description provided for @onlineFav_authorUnfavorited.
  ///
  /// In en, this message translates to:
  /// **'Author unfavorited'**
  String get onlineFav_authorUnfavorited;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get common_selectAll;

  /// No description provided for @common_deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get common_deselectAll;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// No description provided for @common_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get common_copy;

  /// No description provided for @common_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get common_copied;

  /// No description provided for @common_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get common_export;

  /// No description provided for @common_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get common_import;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get common_select;

  /// No description provided for @common_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get common_added;

  /// No description provided for @common_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get common_new;

  /// No description provided for @common_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get common_confirmDelete;

  /// No description provided for @common_confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get common_confirmClear;

  /// No description provided for @common_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get common_gotIt;

  /// No description provided for @common_deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{itemName}\"? This action cannot be undone.'**
  String common_deleteItemConfirm(Object itemName);

  /// No description provided for @common_clearAllItemsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all {count} {itemType}? This action cannot be undone.'**
  String common_clearAllItemsConfirm(Object count, Object itemType);

  /// No description provided for @common_clearInputConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the input content?'**
  String get common_clearInputConfirm;

  /// No description provided for @common_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get common_yesterday;

  /// No description provided for @common_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String common_daysAgo(Object days);

  /// No description provided for @common_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get common_undo;

  /// No description provided for @common_redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get common_redo;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @common_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get common_download;

  /// No description provided for @common_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply;

  /// No description provided for @common_move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get common_move;

  /// No description provided for @common_favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get common_favorite;

  /// No description provided for @common_unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get common_unfavorite;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get common_exit;

  /// No description provided for @common_grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get common_grid;

  /// No description provided for @common_pack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get common_pack;

  /// No description provided for @common_multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get common_multiSelect;

  /// No description provided for @common_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get common_category;

  /// No description provided for @networkError_connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check your network connection.'**
  String get networkError_connectionTimeout;

  /// No description provided for @networkError_sendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Sending timed out. Try again.'**
  String get networkError_sendTimeout;

  /// No description provided for @networkError_receiveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receiving timed out. Image generation may take longer than expected.'**
  String get networkError_receiveTimeout;

  /// No description provided for @networkError_requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled'**
  String get networkError_requestCancelled;

  /// No description provided for @networkError_connection.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Check your network connection.'**
  String get networkError_connection;

  /// No description provided for @networkError_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get networkError_unknown;

  /// No description provided for @networkError_noResponse.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond'**
  String get networkError_noResponse;

  /// No description provided for @networkError_badRequest.
  ///
  /// In en, this message translates to:
  /// **'The request parameters are invalid'**
  String get networkError_badRequest;

  /// No description provided for @networkError_authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Sign in again.'**
  String get networkError_authFailed;

  /// No description provided for @networkError_insufficientAnlas.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Anlas'**
  String get networkError_insufficientAnlas;

  /// No description provided for @networkError_forbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this resource'**
  String get networkError_forbidden;

  /// No description provided for @networkError_notFound.
  ///
  /// In en, this message translates to:
  /// **'The requested resource does not exist'**
  String get networkError_notFound;

  /// No description provided for @networkError_conflict.
  ///
  /// In en, this message translates to:
  /// **'The request conflicts with the current state'**
  String get networkError_conflict;

  /// No description provided for @networkError_rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again later.'**
  String get networkError_rateLimited;

  /// No description provided for @networkError_serverInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal server error'**
  String get networkError_serverInternal;

  /// No description provided for @networkError_badGateway.
  ///
  /// In en, this message translates to:
  /// **'Server gateway error'**
  String get networkError_badGateway;

  /// No description provided for @networkError_unavailable.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable'**
  String get networkError_unavailable;

  /// No description provided for @networkError_requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({code})'**
  String networkError_requestFailed(int code);

  /// No description provided for @nav_canvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get nav_canvas;

  /// No description provided for @nav_onlineGallery.
  ///
  /// In en, this message translates to:
  /// **'Online Gallery'**
  String get nav_onlineGallery;

  /// No description provided for @nav_expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get nav_expandSidebar;

  /// No description provided for @nav_collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get nav_collapseSidebar;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login;

  /// No description provided for @auth_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get auth_logout;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_loginButton;

  /// No description provided for @auth_loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get auth_loginFailed;

  /// No description provided for @auth_guestEntry.
  ///
  /// In en, this message translates to:
  /// **'Skip login and continue as guest'**
  String get auth_guestEntry;

  /// No description provided for @auth_recommended.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get auth_recommended;

  /// No description provided for @auth_getToken.
  ///
  /// In en, this message translates to:
  /// **'Get token'**
  String get auth_getToken;

  /// No description provided for @auth_localOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Accounts and tokens stay on this device'**
  String get auth_localOnlyNote;

  /// No description provided for @auth_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get auth_back;

  /// No description provided for @auth_toggleVisibility.
  ///
  /// In en, this message translates to:
  /// **'Show / hide'**
  String get auth_toggleVisibility;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get auth_emailRequired;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get auth_emailInvalid;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get auth_passwordRequired;

  /// No description provided for @auth_tokenLogin.
  ///
  /// In en, this message translates to:
  /// **'API Token Login'**
  String get auth_tokenLogin;

  /// No description provided for @auth_tokenLoginRecommended.
  ///
  /// In en, this message translates to:
  /// **'API Token Login (Recommended)'**
  String get auth_tokenLoginRecommended;

  /// No description provided for @auth_credentialsLogin.
  ///
  /// In en, this message translates to:
  /// **'Email & Password'**
  String get auth_credentialsLogin;

  /// No description provided for @auth_credentialsLoginUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email/password login is currently unavailable. Please use Token login.'**
  String get auth_credentialsLoginUnavailable;

  /// No description provided for @auth_tokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter token'**
  String get auth_tokenRequired;

  /// No description provided for @auth_tokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid token format, should start with pst-'**
  String get auth_tokenInvalid;

  /// No description provided for @auth_nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Set a recognizable name for this account'**
  String get auth_nicknameHint;

  /// No description provided for @auth_thirdPartyLogin.
  ///
  /// In en, this message translates to:
  /// **'Third-party Site'**
  String get auth_thirdPartyLogin;

  /// No description provided for @auth_thirdPartyApiSite.
  ///
  /// In en, this message translates to:
  /// **'Third-party API Site'**
  String get auth_thirdPartyApiSite;

  /// No description provided for @auth_imageApiSiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Image API Site (optional)'**
  String get auth_imageApiSiteOptional;

  /// No description provided for @auth_imageApiSiteHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the same third-party API site'**
  String get auth_imageApiSiteHint;

  /// No description provided for @auth_thirdPartyNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: self-hosted site / mirror site'**
  String get auth_thirdPartyNicknameHint;

  /// No description provided for @auth_thirdPartyTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the API token from the third-party site'**
  String get auth_thirdPartyTokenHint;

  /// No description provided for @auth_thirdPartyCompatibilityHint.
  ///
  /// In en, this message translates to:
  /// **'The third-party site must be compatible with NovelAI subscription and image-generation APIs. The token will be sent as a Bearer token.'**
  String get auth_thirdPartyCompatibilityHint;

  /// No description provided for @auth_thirdPartyApiSiteRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter third-party API site URL'**
  String get auth_thirdPartyApiSiteRequired;

  /// No description provided for @auth_validateAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Validate & Login'**
  String get auth_validateAndLogin;

  /// No description provided for @auth_tokenGuide.
  ///
  /// In en, this message translates to:
  /// **'Get Token from NovelAI settings'**
  String get auth_tokenGuide;

  /// No description provided for @auth_addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get auth_addAccount;

  /// No description provided for @auth_tokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Token not found for this account'**
  String get auth_tokenNotFound;

  /// No description provided for @auth_switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get auth_switchAccount;

  /// No description provided for @auth_currentAccount.
  ///
  /// In en, this message translates to:
  /// **'Current Account'**
  String get auth_currentAccount;

  /// No description provided for @auth_selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get auth_selectAccount;

  /// No description provided for @auth_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get auth_deleteAccount;

  /// No description provided for @auth_deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String auth_deleteAccountConfirm(Object name);

  /// No description provided for @auth_deleteCurrentAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and sign out?'**
  String auth_deleteCurrentAccountConfirm(Object name);

  /// No description provided for @auth_switchFailedDeletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in to this account (it may be invalid). Remove it from the list?'**
  String get auth_switchFailedDeletePrompt;

  /// No description provided for @auth_switchFailedDeletePromptMissingToken.
  ///
  /// In en, this message translates to:
  /// **'No saved credentials for this account. Remove it from the list?'**
  String get auth_switchFailedDeletePromptMissingToken;

  /// No description provided for @auth_removeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Avatar'**
  String get auth_removeAvatar;

  /// No description provided for @auth_quickLogin.
  ///
  /// In en, this message translates to:
  /// **'Quick Login'**
  String get auth_quickLogin;

  /// No description provided for @auth_nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter nickname'**
  String get auth_nicknameRequired;

  /// No description provided for @auth_error_networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get auth_error_networkTimeout;

  /// No description provided for @auth_error_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get auth_error_networkError;

  /// No description provided for @auth_error_authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get auth_error_authFailed;

  /// No description provided for @auth_error_credentialsLoginUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email/password login is currently unavailable'**
  String get auth_error_credentialsLoginUnavailable;

  /// No description provided for @auth_error_credentialsLoginUnavailable_hint.
  ///
  /// In en, this message translates to:
  /// **'NovelAI now requires a web safety check for email/password login. Please use a Persistent API Token instead.'**
  String get auth_error_credentialsLoginUnavailable_hint;

  /// No description provided for @auth_error_serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get auth_error_serverError;

  /// No description provided for @auth_error_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get auth_error_unknown;

  /// No description provided for @auth_autoLogin.
  ///
  /// In en, this message translates to:
  /// **'Auto login'**
  String get auth_autoLogin;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_passwordTooShort;

  /// No description provided for @auth_loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get auth_loggingIn;

  /// No description provided for @auth_viewTroubleshootingTips.
  ///
  /// In en, this message translates to:
  /// **'View Troubleshooting Tips'**
  String get auth_viewTroubleshootingTips;

  /// No description provided for @auth_troubleshoot_checkConnection_title.
  ///
  /// In en, this message translates to:
  /// **'Check Network Connection'**
  String get auth_troubleshoot_checkConnection_title;

  /// No description provided for @auth_troubleshoot_checkConnection_desc.
  ///
  /// In en, this message translates to:
  /// **'Ensure your device is connected to the internet'**
  String get auth_troubleshoot_checkConnection_desc;

  /// No description provided for @auth_troubleshoot_retry_title.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get auth_troubleshoot_retry_title;

  /// No description provided for @auth_troubleshoot_retry_desc.
  ///
  /// In en, this message translates to:
  /// **'Network issues may be temporary, please retry'**
  String get auth_troubleshoot_retry_desc;

  /// No description provided for @auth_troubleshoot_proxy_title.
  ///
  /// In en, this message translates to:
  /// **'Check Proxy Settings'**
  String get auth_troubleshoot_proxy_title;

  /// No description provided for @auth_troubleshoot_proxy_desc.
  ///
  /// In en, this message translates to:
  /// **'If using a proxy, verify it\'s configured correctly'**
  String get auth_troubleshoot_proxy_desc;

  /// No description provided for @auth_troubleshoot_firewall_title.
  ///
  /// In en, this message translates to:
  /// **'Check Firewall Settings'**
  String get auth_troubleshoot_firewall_title;

  /// No description provided for @auth_troubleshoot_firewall_desc.
  ///
  /// In en, this message translates to:
  /// **'Ensure your firewall allows connections to NovelAI servers'**
  String get auth_troubleshoot_firewall_desc;

  /// No description provided for @auth_troubleshoot_serverStatus_title.
  ///
  /// In en, this message translates to:
  /// **'Check Server Status'**
  String get auth_troubleshoot_serverStatus_title;

  /// No description provided for @auth_troubleshoot_serverStatus_desc.
  ///
  /// In en, this message translates to:
  /// **'Visit NovelAI status page or community to check for outages'**
  String get auth_troubleshoot_serverStatus_desc;

  /// No description provided for @common_paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get common_paste;

  /// No description provided for @common_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get common_default;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_savedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Saved Accounts'**
  String get settings_savedAccounts;

  /// No description provided for @settings_style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settings_style;

  /// No description provided for @settings_font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settings_font;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get settings_shortcuts;

  /// No description provided for @settings_generationInputSection.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get settings_generationInputSection;

  /// No description provided for @settings_generationFeedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Completion Alert'**
  String get settings_generationFeedbackSection;

  /// No description provided for @settings_selectFont.
  ///
  /// In en, this message translates to:
  /// **'Select Font'**
  String get settings_selectFont;

  /// No description provided for @settings_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settings_selectLanguage;

  /// No description provided for @settings_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String settings_loadFailed(Object error);

  /// No description provided for @settings_imageSavePath.
  ///
  /// In en, this message translates to:
  /// **'Image Save Location'**
  String get settings_imageSavePath;

  /// No description provided for @settings_autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get settings_autoSave;

  /// No description provided for @settings_autoSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically save images after generation'**
  String get settings_autoSaveSubtitle;

  /// No description provided for @settings_extraRootsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery Sources'**
  String get settings_extraRootsTitle;

  /// No description provided for @settings_extraRootsHint.
  ///
  /// In en, this message translates to:
  /// **'Extra gallery sources can be browsed and searched, and their images can be moved or copied to categories. They are not used for auto-save. New sources are scanned immediately.'**
  String get settings_extraRootsHint;

  /// No description provided for @settings_extraRootsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No extra gallery sources added'**
  String get settings_extraRootsEmpty;

  /// No description provided for @settings_extraRootsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get settings_extraRootsAdd;

  /// No description provided for @settings_extraRootsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to add as a gallery source'**
  String get settings_extraRootsAddTitle;

  /// No description provided for @settings_extraRootsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this gallery source'**
  String get settings_extraRootsRemove;

  /// No description provided for @settings_extraRootsRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove gallery source?'**
  String get settings_extraRootsRemoveConfirmTitle;

  /// No description provided for @settings_extraRootsRemoveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{path}\" from the gallery (no files in the folder will be deleted).'**
  String settings_extraRootsRemoveConfirmContent(String path);

  /// No description provided for @settings_extraRootsAdded.
  ///
  /// In en, this message translates to:
  /// **'Gallery source added and scanned'**
  String get settings_extraRootsAdded;

  /// No description provided for @settings_extraRootsScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Folder added, but scanning did not finish. Refresh the gallery to retry'**
  String get settings_extraRootsScanFailed;

  /// No description provided for @settings_extraRootsWaitingScan.
  ///
  /// In en, this message translates to:
  /// **'The gallery is scanning. This folder will be imported when it finishes'**
  String get settings_extraRootsWaitingScan;

  /// No description provided for @settings_extraRootsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Gallery source removed'**
  String get settings_extraRootsRemoved;

  /// No description provided for @settings_extraRootsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This folder is already a gallery source'**
  String get settings_extraRootsDuplicate;

  /// No description provided for @settings_extraRootsSameAsMain.
  ///
  /// In en, this message translates to:
  /// **'This folder is the same as the image save location'**
  String get settings_extraRootsSameAsMain;

  /// No description provided for @settings_extraRootsNested.
  ///
  /// In en, this message translates to:
  /// **'Gallery sources cannot contain each other; choose another folder'**
  String get settings_extraRootsNested;

  /// No description provided for @settings_extraRootsNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected folder does not exist'**
  String get settings_extraRootsNotFound;

  /// No description provided for @settings_importTagIndex.
  ///
  /// In en, this message translates to:
  /// **'Import Tag Index…'**
  String get settings_importTagIndex;

  /// No description provided for @settings_importTagIndexPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Select tag index file (.jsonl)'**
  String get settings_importTagIndexPickTitle;

  /// No description provided for @settings_importTagIndexProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {processed}/{total} lines…'**
  String settings_importTagIndexProgress(int processed, int total);

  /// No description provided for @settings_importTagIndexDone.
  ///
  /// In en, this message translates to:
  /// **'Import complete: {imported} new, {updated} updated, {skipped} skipped, {errors} errors'**
  String settings_importTagIndexDone(
    int imported,
    int updated,
    int skipped,
    int errors,
  );

  /// No description provided for @settings_importTagIndexFailed.
  ///
  /// In en, this message translates to:
  /// **'Tag index import failed'**
  String get settings_importTagIndexFailed;

  /// No description provided for @settings_importTagIndexBlockedByScan.
  ///
  /// In en, this message translates to:
  /// **'Gallery scan is in progress. Wait for it to finish before importing the tag index.'**
  String get settings_importTagIndexBlockedByScan;

  /// No description provided for @settings_extraRootsIndexImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Index Found'**
  String get settings_extraRootsIndexImportTitle;

  /// No description provided for @settings_extraRootsIndexImportContent.
  ///
  /// In en, this message translates to:
  /// **'Found tag index index.jsonl under \"{path}\". Importing it first lets the upcoming scan fast-forward (skip metadata parsing). Import now?'**
  String settings_extraRootsIndexImportContent(String path);

  /// No description provided for @settings_extraRootsIndexImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import Now'**
  String get settings_extraRootsIndexImportConfirm;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settings_version(Object version);

  /// No description provided for @settings_openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get settings_openSource;

  /// No description provided for @settings_openSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View source code and documentation'**
  String get settings_openSourceSubtitle;

  /// No description provided for @settings_fileLogging.
  ///
  /// In en, this message translates to:
  /// **'Record application logs'**
  String get settings_fileLogging;

  /// No description provided for @settings_fileLoggingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off by default; enable only for troubleshooting. When enabled, logs are written to Documents/NAI_Launcher/logs. When disabled, log files are no longer created or written.'**
  String get settings_fileLoggingSubtitle;

  /// No description provided for @settings_pathReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default location'**
  String get settings_pathReset;

  /// No description provided for @settings_pathSaved.
  ///
  /// In en, this message translates to:
  /// **'Save location updated'**
  String get settings_pathSaved;

  /// No description provided for @settings_selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Save Folder'**
  String get settings_selectFolder;

  /// No description provided for @settings_vibeLibraryPath.
  ///
  /// In en, this message translates to:
  /// **'Vibe Library Path'**
  String get settings_vibeLibraryPath;

  /// No description provided for @settings_hiveStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Data Storage Path'**
  String get settings_hiveStoragePath;

  /// No description provided for @settings_selectVibeLibraryFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Vibe Library Folder'**
  String get settings_selectVibeLibraryFolder;

  /// No description provided for @settings_selectHiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Data Storage Folder'**
  String get settings_selectHiveFolder;

  /// No description provided for @settings_pathSavedRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Path updated, restart to apply changes'**
  String get settings_pathSavedRestartRequired;

  /// No description provided for @settings_accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get settings_accountType;

  /// No description provided for @settings_subscriptionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expires'**
  String get settings_subscriptionExpiry;

  /// No description provided for @settings_thirdPartyApiAccount.
  ///
  /// In en, this message translates to:
  /// **'Third-party Site API'**
  String get settings_thirdPartyApiAccount;

  /// No description provided for @settings_goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get settings_goToLogin;

  /// No description provided for @settings_changeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get settings_changeAvatar;

  /// No description provided for @settings_removeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Avatar'**
  String get settings_removeAvatar;

  /// No description provided for @settings_accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Account Email'**
  String get settings_accountEmail;

  /// No description provided for @settings_emailAccount.
  ///
  /// In en, this message translates to:
  /// **'Email Account'**
  String get settings_emailAccount;

  /// No description provided for @settings_tokenAccount.
  ///
  /// In en, this message translates to:
  /// **'Token Account'**
  String get settings_tokenAccount;

  /// No description provided for @settings_setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get settings_setAsDefault;

  /// No description provided for @settings_defaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settings_defaultAccount;

  /// No description provided for @settings_nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get settings_nickname;

  /// No description provided for @settings_nicknameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated'**
  String get settings_nicknameUpdated;

  /// No description provided for @settings_avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get settings_avatarUpdated;

  /// No description provided for @settings_avatarRemoved.
  ///
  /// In en, this message translates to:
  /// **'Avatar removed'**
  String get settings_avatarRemoved;

  /// No description provided for @settings_setAsDefaultSuccess.
  ///
  /// In en, this message translates to:
  /// **'Set as default account'**
  String get settings_setAsDefaultSuccess;

  /// No description provided for @generation_title.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generation_title;

  /// No description provided for @generation_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generation_generate;

  /// No description provided for @generation_cooldownRemaining.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds}s'**
  String generation_cooldownRemaining(Object seconds);

  /// No description provided for @generation_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generation_generating;

  /// No description provided for @generation_cancelGeneration.
  ///
  /// In en, this message translates to:
  /// **'Cancel Generation'**
  String get generation_cancelGeneration;

  /// No description provided for @generation_stopGeneration.
  ///
  /// In en, this message translates to:
  /// **'Stop Generation'**
  String get generation_stopGeneration;

  /// No description provided for @generation_pleaseInputPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter prompt'**
  String get generation_pleaseInputPrompt;

  /// No description provided for @generation_generationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get generation_generationFailed;

  /// No description provided for @generation_progress.
  ///
  /// In en, this message translates to:
  /// **'Generating... {progress}%'**
  String generation_progress(Object progress);

  /// No description provided for @generation_lockHistoryScroll.
  ///
  /// In en, this message translates to:
  /// **'Lock history scrolling'**
  String get generation_lockHistoryScroll;

  /// No description provided for @generation_unlockHistoryScroll.
  ///
  /// In en, this message translates to:
  /// **'Unlock history scrolling'**
  String get generation_unlockHistoryScroll;

  /// No description provided for @generation_downloadAllImages.
  ///
  /// In en, this message translates to:
  /// **'Download all images'**
  String get generation_downloadAllImages;

  /// No description provided for @generation_selectMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select multiple'**
  String get generation_selectMultiple;

  /// No description provided for @generation_deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Exit multi-select'**
  String get generation_deselectAll;

  /// No description provided for @generation_deleteSelectedImages.
  ///
  /// In en, this message translates to:
  /// **'Delete selected images ({count})'**
  String generation_deleteSelectedImages(int count);

  /// No description provided for @generation_deleteSelectedImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Images'**
  String get generation_deleteSelectedImagesTitle;

  /// No description provided for @generation_deleteSelectedImagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s) will be removed from records (files saved to disk are kept)'**
  String generation_deleteSelectedImagesConfirm(int count);

  /// No description provided for @generation_seedWrittenBack.
  ///
  /// In en, this message translates to:
  /// **'Seed written back: {seed}'**
  String generation_seedWrittenBack(int seed);

  /// No description provided for @generation_setAsReferenceImage.
  ///
  /// In en, this message translates to:
  /// **'Set as reference image'**
  String get generation_setAsReferenceImage;

  /// No description provided for @generation_canvasDisplaySettings.
  ///
  /// In en, this message translates to:
  /// **'Canvas Display'**
  String get generation_canvasDisplaySettings;

  /// No description provided for @generation_canvasZoomToFill.
  ///
  /// In en, this message translates to:
  /// **'Zoom to fill (allows >100%)'**
  String get generation_canvasZoomToFill;

  /// No description provided for @generation_canvasEmpty.
  ///
  /// In en, this message translates to:
  /// **'Canvas is empty'**
  String get generation_canvasEmpty;

  /// No description provided for @generation_canvasBackground.
  ///
  /// In en, this message translates to:
  /// **'Transparency background'**
  String get generation_canvasBackground;

  /// No description provided for @generation_canvasBackgroundChecker.
  ///
  /// In en, this message translates to:
  /// **'Checkerboard'**
  String get generation_canvasBackgroundChecker;

  /// No description provided for @generation_canvasBackgroundCheckerLight.
  ///
  /// In en, this message translates to:
  /// **'Light checkerboard'**
  String get generation_canvasBackgroundCheckerLight;

  /// No description provided for @generation_canvasBackgroundCheckerDark.
  ///
  /// In en, this message translates to:
  /// **'Dark checkerboard'**
  String get generation_canvasBackgroundCheckerDark;

  /// No description provided for @generation_canvasBackgroundNone.
  ///
  /// In en, this message translates to:
  /// **'No background'**
  String get generation_canvasBackgroundNone;

  /// No description provided for @generation_canvasBackgroundBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get generation_canvasBackgroundBlack;

  /// No description provided for @generation_canvasBackgroundWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get generation_canvasBackgroundWhite;

  /// No description provided for @generation_canvasBackgroundGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get generation_canvasBackgroundGray;

  /// No description provided for @generation_canvasBackgroundRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get generation_canvasBackgroundRed;

  /// No description provided for @generation_canvasBackgroundGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get generation_canvasBackgroundGreen;

  /// No description provided for @generation_canvasBackgroundBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get generation_canvasBackgroundBlue;

  /// No description provided for @generation_canvasBackgroundCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get generation_canvasBackgroundCustom;

  /// No description provided for @generation_canvasSetInitImage.
  ///
  /// In en, this message translates to:
  /// **'Use as img2img source'**
  String get generation_canvasSetInitImage;

  /// No description provided for @generation_canvasSendToTools.
  ///
  /// In en, this message translates to:
  /// **'Send to Director Tools'**
  String get generation_canvasSendToTools;

  /// No description provided for @generation_canvasPinImage.
  ///
  /// In en, this message translates to:
  /// **'Pin image'**
  String get generation_canvasPinImage;

  /// No description provided for @generation_canvasUnpinImage.
  ///
  /// In en, this message translates to:
  /// **'Unpin image'**
  String get generation_canvasUnpinImage;

  /// No description provided for @generation_canvasUseSeed.
  ///
  /// In en, this message translates to:
  /// **'Click to use this seed'**
  String get generation_canvasUseSeed;

  /// No description provided for @generation_canvasPinnedCount.
  ///
  /// In en, this message translates to:
  /// **'Pins {count}'**
  String generation_canvasPinnedCount(int count);

  /// No description provided for @generation_params.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get generation_params;

  /// No description provided for @generation_paramsSettings.
  ///
  /// In en, this message translates to:
  /// **'Parameter Settings'**
  String get generation_paramsSettings;

  /// No description provided for @generation_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get generation_history;

  /// No description provided for @generation_historyRecord.
  ///
  /// In en, this message translates to:
  /// **'History Records'**
  String get generation_historyRecord;

  /// No description provided for @generation_failedStreamSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Failed snapshot'**
  String get generation_failedStreamSnapshot;

  /// No description provided for @generation_failedStreamSnapshotHint.
  ///
  /// In en, this message translates to:
  /// **'Generation did not finish; only the last preview frame is kept. It cannot be saved, favorited, or used for image workflows.'**
  String get generation_failedStreamSnapshotHint;

  /// No description provided for @generation_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history records'**
  String get generation_noHistory;

  /// No description provided for @generation_clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get generation_clearHistory;

  /// No description provided for @generation_clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all history records? This action cannot be undone.'**
  String get generation_clearHistoryConfirm;

  /// No description provided for @generation_model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get generation_model;

  /// No description provided for @generation_imageSize.
  ///
  /// In en, this message translates to:
  /// **'Image Size'**
  String get generation_imageSize;

  /// No description provided for @generation_sampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get generation_sampler;

  /// No description provided for @generation_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps: {steps}'**
  String generation_steps(Object steps);

  /// No description provided for @generation_stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get generation_stepsLabel;

  /// No description provided for @generation_guidance.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get generation_guidance;

  /// No description provided for @generation_cfgScale.
  ///
  /// In en, this message translates to:
  /// **'Prompt Guidance: {scale}'**
  String generation_cfgScale(Object scale);

  /// No description provided for @generation_seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get generation_seed;

  /// No description provided for @generation_seedRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get generation_seedRandom;

  /// No description provided for @generation_samplerRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get generation_samplerRecommended;

  /// No description provided for @generation_samplerOther.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get generation_samplerOther;

  /// No description provided for @generation_advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get generation_advancedOptions;

  /// No description provided for @generation_smea.
  ///
  /// In en, this message translates to:
  /// **'SMEA'**
  String get generation_smea;

  /// No description provided for @generation_smeaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve generation quality for large images'**
  String get generation_smeaSubtitle;

  /// No description provided for @generation_smeaDyn.
  ///
  /// In en, this message translates to:
  /// **'SMEA DYN'**
  String get generation_smeaDyn;

  /// No description provided for @generation_smeaDescription.
  ///
  /// In en, this message translates to:
  /// **'High resolution samplers will automatically be used above a certain image size'**
  String get generation_smeaDescription;

  /// No description provided for @generation_cfgRescale.
  ///
  /// In en, this message translates to:
  /// **'Prompt Guidance Rescale: {value}'**
  String generation_cfgRescale(Object value);

  /// No description provided for @generation_noiseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Noise Schedule'**
  String get generation_noiseSchedule;

  /// No description provided for @generation_modelGroupNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get generation_modelGroupNew;

  /// No description provided for @generation_modelGroupLegacy.
  ///
  /// In en, this message translates to:
  /// **'LEGACY'**
  String get generation_modelGroupLegacy;

  /// No description provided for @generation_modelDesc_v5Curated.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s newest model, trained on a curated subset of images. Recommended for streaming.'**
  String get generation_modelDesc_v5Curated;

  /// No description provided for @generation_modelDesc_v5Full.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s newest and best model.'**
  String get generation_modelDesc_v5Full;

  /// No description provided for @generation_modelDesc_v45Curated.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s V4.5 model trained on a curated subset of images. No longer recommended for use.'**
  String get generation_modelDesc_v45Curated;

  /// No description provided for @generation_modelDesc_v45Full.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s V4.5 full model.'**
  String get generation_modelDesc_v45Full;

  /// No description provided for @generation_modelDesc_v4Curated.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s V4 model trained on a curated subset of images.'**
  String get generation_modelDesc_v4Curated;

  /// No description provided for @generation_modelDesc_v4Full.
  ///
  /// In en, this message translates to:
  /// **'NovelAI\'s V4 full model.'**
  String get generation_modelDesc_v4Full;

  /// No description provided for @generation_sectionCharacters.
  ///
  /// In en, this message translates to:
  /// **'Character Prompts'**
  String get generation_sectionCharacters;

  /// No description provided for @generation_sectionCharactersSub.
  ///
  /// In en, this message translates to:
  /// **'Create a separate prompt for characters in your scene.'**
  String get generation_sectionCharactersSub;

  /// No description provided for @character_positionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get character_positionLabel;

  /// No description provided for @generation_sectionReferenceImages.
  ///
  /// In en, this message translates to:
  /// **'Reference Images'**
  String get generation_sectionReferenceImages;

  /// No description provided for @anlas_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get anlas_subscription;

  /// No description provided for @anlas_purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get anlas_purchased;

  /// No description provided for @prompt_positive.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get prompt_positive;

  /// No description provided for @prompt_baseTab.
  ///
  /// In en, this message translates to:
  /// **'Base Prompt'**
  String get prompt_baseTab;

  /// No description provided for @prompt_negativeTab.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get prompt_negativeTab;

  /// No description provided for @prompt_transparentBg.
  ///
  /// In en, this message translates to:
  /// **'Transparent BG'**
  String get prompt_transparentBg;

  /// No description provided for @prompt_chunksMenu.
  ///
  /// In en, this message translates to:
  /// **'Tools & toggles'**
  String get prompt_chunksMenu;

  /// No description provided for @qualityTags_presetChip.
  ///
  /// In en, this message translates to:
  /// **'Quality Tags'**
  String get qualityTags_presetChip;

  /// No description provided for @ucPreset_presetChip.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Preset'**
  String get ucPreset_presetChip;

  /// No description provided for @prompt_positivePrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get prompt_positivePrompt;

  /// No description provided for @prompt_negativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get prompt_negativePrompt;

  /// No description provided for @prompt_mainPositive.
  ///
  /// In en, this message translates to:
  /// **'Main Prompt'**
  String get prompt_mainPositive;

  /// No description provided for @prompt_mainNegative.
  ///
  /// In en, this message translates to:
  /// **'Main Prompt (Undesired Content)'**
  String get prompt_mainNegative;

  /// No description provided for @prompt_characterPrompts.
  ///
  /// In en, this message translates to:
  /// **'Multi-Character Prompts'**
  String get prompt_characterPrompts;

  /// No description provided for @prompt_finalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Final Effective Prompt'**
  String get prompt_finalPrompt;

  /// No description provided for @prompt_finalNegative.
  ///
  /// In en, this message translates to:
  /// **'Final Effective Undesired Content'**
  String get prompt_finalNegative;

  /// No description provided for @prompt_importedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} character(s)'**
  String prompt_importedCharacters(int count);

  /// No description provided for @prompt_characterPromptReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced character prompts'**
  String get prompt_characterPromptReplaced;

  /// No description provided for @prompt_characterPromptAppended.
  ///
  /// In en, this message translates to:
  /// **'Appended character prompts ({count} character(s))'**
  String prompt_characterPromptAppended(Object count);

  /// No description provided for @prompt_smartDecomposedWithCharacters.
  ///
  /// In en, this message translates to:
  /// **'Decomposed into main prompt + {count} character(s)'**
  String prompt_smartDecomposedWithCharacters(Object count);

  /// No description provided for @prompt_appliedToMainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Applied to main prompt'**
  String get prompt_appliedToMainPrompt;

  /// No description provided for @prompt_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search prompt'**
  String get prompt_searchHint;

  /// No description provided for @prompt_searchMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String prompt_searchMatchCount(Object current, Object total);

  /// No description provided for @prompt_searchPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get prompt_searchPrevious;

  /// No description provided for @prompt_searchNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get prompt_searchNext;

  /// No description provided for @prompt_searchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get prompt_searchClose;

  /// No description provided for @prompt_replaceHint.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get prompt_replaceHint;

  /// No description provided for @prompt_replaceToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle replace'**
  String get prompt_replaceToggle;

  /// No description provided for @prompt_replaceCurrent.
  ///
  /// In en, this message translates to:
  /// **'Replace current match (Enter)'**
  String get prompt_replaceCurrent;

  /// No description provided for @prompt_replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all (Ctrl+Enter)'**
  String get prompt_replaceAll;

  /// No description provided for @prompt_replaceAllDone.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} matches'**
  String prompt_replaceAllDone(Object count);

  /// No description provided for @kritaBridge_busyGenerating.
  ///
  /// In en, this message translates to:
  /// **'Krita Bridge is generating. Wait for the current task to finish.'**
  String get kritaBridge_busyGenerating;

  /// No description provided for @prompt_unwantedContent.
  ///
  /// In en, this message translates to:
  /// **'Content you don\'t want in the image...'**
  String get prompt_unwantedContent;

  /// No description provided for @prompt_autoFormat.
  ///
  /// In en, this message translates to:
  /// **'Auto Format'**
  String get prompt_autoFormat;

  /// No description provided for @prompt_autoFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Normalize commas and whitespace; remove redundant 1x weight markers'**
  String get prompt_autoFormatSubtitle;

  /// No description provided for @prompt_highlightEmphasis.
  ///
  /// In en, this message translates to:
  /// **'Highlight Emphasis'**
  String get prompt_highlightEmphasis;

  /// No description provided for @prompt_highlightEmphasisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highlight brackets and weight syntax'**
  String get prompt_highlightEmphasisSubtitle;

  /// No description provided for @prompt_sdSyntaxAutoConvert.
  ///
  /// In en, this message translates to:
  /// **'SD Syntax Auto Convert'**
  String get prompt_sdSyntaxAutoConvert;

  /// No description provided for @prompt_sdSyntaxAutoConvertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert SD weights to NAI syntax on blur or generation'**
  String get prompt_sdSyntaxAutoConvertSubtitle;

  /// No description provided for @prompt_cooccurrenceRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Tag Expansion'**
  String get prompt_cooccurrenceRecommendation;

  /// No description provided for @prompt_cooccurrenceRecommendationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+click to search local tags; Ctrl+drag to explore related tags'**
  String get prompt_cooccurrenceRecommendationSubtitle;

  /// No description provided for @prompt_formatted.
  ///
  /// In en, this message translates to:
  /// **'Formatted'**
  String get prompt_formatted;

  /// No description provided for @image_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get image_save;

  /// No description provided for @image_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get image_copy;

  /// No description provided for @image_upscale.
  ///
  /// In en, this message translates to:
  /// **'Upscale'**
  String get image_upscale;

  /// No description provided for @image_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get image_saveToLibrary;

  /// No description provided for @image_imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to: {path}'**
  String image_imageSaved(Object path);

  /// No description provided for @image_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String image_saveFailed(Object error);

  /// No description provided for @image_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get image_copiedToClipboard;

  /// No description provided for @image_copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String image_copyFailed(Object error);

  /// No description provided for @img2img_title.
  ///
  /// In en, this message translates to:
  /// **'Image2Image'**
  String get img2img_title;

  /// No description provided for @img2img_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate variations from a source image'**
  String get img2img_subtitle;

  /// No description provided for @img2img_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get img2img_enabled;

  /// No description provided for @img2img_sourceImage.
  ///
  /// In en, this message translates to:
  /// **'Source Image'**
  String get img2img_sourceImage;

  /// No description provided for @img2img_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get img2img_strength;

  /// No description provided for @img2img_strengthHint.
  ///
  /// In en, this message translates to:
  /// **'Higher values create greater difference from original'**
  String get img2img_strengthHint;

  /// No description provided for @img2img_noise.
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get img2img_noise;

  /// No description provided for @img2img_noiseHint.
  ///
  /// In en, this message translates to:
  /// **'Add extra noise for more variation'**
  String get img2img_noiseHint;

  /// No description provided for @img2img_clearSettings.
  ///
  /// In en, this message translates to:
  /// **'Clear Image2Image Settings'**
  String get img2img_clearSettings;

  /// No description provided for @img2img_changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get img2img_changeImage;

  /// No description provided for @img2img_removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get img2img_removeImage;

  /// No description provided for @img2img_selectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image: {error}'**
  String img2img_selectFailed(Object error);

  /// No description provided for @img2img_editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get img2img_editImage;

  /// No description provided for @img2img_placeOnCanvas.
  ///
  /// In en, this message translates to:
  /// **'Place on canvas'**
  String get img2img_placeOnCanvas;

  /// No description provided for @img2img_editApplied.
  ///
  /// In en, this message translates to:
  /// **'The edited image is now the new source image'**
  String get img2img_editApplied;

  /// No description provided for @img2img_uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get img2img_uploadImage;

  /// No description provided for @img2img_dropToAdd.
  ///
  /// In en, this message translates to:
  /// **'Release to set as source image'**
  String get img2img_dropToAdd;

  /// No description provided for @img2img_moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get img2img_moreActions;

  /// No description provided for @img2img_drawSketch.
  ///
  /// In en, this message translates to:
  /// **'Draw Sketch'**
  String get img2img_drawSketch;

  /// No description provided for @img2img_inpaint.
  ///
  /// In en, this message translates to:
  /// **'Inpaint'**
  String get img2img_inpaint;

  /// No description provided for @img2img_inpaintStrength.
  ///
  /// In en, this message translates to:
  /// **'Inpaint Strength'**
  String get img2img_inpaintStrength;

  /// No description provided for @img2img_inpaintStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Higher values make the masked area diverge more from the current source image'**
  String get img2img_inpaintStrengthHint;

  /// No description provided for @img2img_inpaintPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Click Inpaint to open the canvas, mark the region you want to repaint with brush, eraser, or selection tools, then return here and use the main generate button.'**
  String get img2img_inpaintPendingHint;

  /// No description provided for @img2img_inpaintReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Mask loaded. The next generation will repaint only the masked area.'**
  String get img2img_inpaintReadyHint;

  /// No description provided for @img2img_inpaintMaskReady.
  ///
  /// In en, this message translates to:
  /// **'Inpaint mask is ready'**
  String get img2img_inpaintMaskReady;

  /// No description provided for @generation_variationOriginal.
  ///
  /// In en, this message translates to:
  /// **'ORIGINAL'**
  String get generation_variationOriginal;

  /// No description provided for @generation_variationSizeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Variations support source images up to 3 megapixels.'**
  String get generation_variationSizeUnsupported;

  /// No description provided for @img2img_generateVariations.
  ///
  /// In en, this message translates to:
  /// **'Generate Variations'**
  String get img2img_generateVariations;

  /// No description provided for @img2img_directorTools.
  ///
  /// In en, this message translates to:
  /// **'Director Tools'**
  String get img2img_directorTools;

  /// No description provided for @img2img_directorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt (Optional)'**
  String get img2img_directorPrompt;

  /// No description provided for @img2img_directorRunning.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get img2img_directorRunning;

  /// No description provided for @img2img_directorResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get img2img_directorResult;

  /// No description provided for @img2img_directorApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied the Director Tool result as the new source image'**
  String get img2img_directorApplied;

  /// No description provided for @img2img_directorDefry.
  ///
  /// In en, this message translates to:
  /// **'Defry'**
  String get img2img_directorDefry;

  /// No description provided for @img2img_directorApplyAsSource.
  ///
  /// In en, this message translates to:
  /// **'Use as Source'**
  String get img2img_directorApplyAsSource;

  /// No description provided for @img2img_variationsStarted.
  ///
  /// In en, this message translates to:
  /// **'Generating variations...'**
  String get img2img_variationsStarted;

  /// No description provided for @img2img_directorRemoveBackground.
  ///
  /// In en, this message translates to:
  /// **'Remove Background'**
  String get img2img_directorRemoveBackground;

  /// No description provided for @img2img_directorLineArt.
  ///
  /// In en, this message translates to:
  /// **'Line Art'**
  String get img2img_directorLineArt;

  /// No description provided for @img2img_directorSketch.
  ///
  /// In en, this message translates to:
  /// **'Sketch'**
  String get img2img_directorSketch;

  /// No description provided for @img2img_directorColorize.
  ///
  /// In en, this message translates to:
  /// **'Colorize'**
  String get img2img_directorColorize;

  /// No description provided for @img2img_directorEmotion.
  ///
  /// In en, this message translates to:
  /// **'Fix Emotion'**
  String get img2img_directorEmotion;

  /// No description provided for @img2img_directorDeclutter.
  ///
  /// In en, this message translates to:
  /// **'Declutter'**
  String get img2img_directorDeclutter;

  /// No description provided for @img2img_enhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get img2img_enhance;

  /// No description provided for @img2img_enhanceMagnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get img2img_enhanceMagnitude;

  /// No description provided for @img2img_enhanceUpscaleAmount.
  ///
  /// In en, this message translates to:
  /// **'Upscale Amount'**
  String get img2img_enhanceUpscaleAmount;

  /// No description provided for @img2img_enhanceMax.
  ///
  /// In en, this message translates to:
  /// **'Max✨'**
  String get img2img_enhanceMax;

  /// No description provided for @img2img_novelAiCloudUpscale.
  ///
  /// In en, this message translates to:
  /// **'NovelAI cloud upscale (fixed 2x)'**
  String get img2img_novelAiCloudUpscale;

  /// No description provided for @img2img_cloudUpscaleSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'NovelAI cloud upscale supports input images up to 3MP.'**
  String get img2img_cloudUpscaleSizeLimit;

  /// No description provided for @img2img_upscaleRegularModel.
  ///
  /// In en, this message translates to:
  /// **'Regular Model'**
  String get img2img_upscaleRegularModel;

  /// No description provided for @img2img_upscaleModel.
  ///
  /// In en, this message translates to:
  /// **'Upscale Model'**
  String get img2img_upscaleModel;

  /// No description provided for @img2img_startUpscale.
  ///
  /// In en, this message translates to:
  /// **'Start Upscale'**
  String get img2img_startUpscale;

  /// No description provided for @img2img_novelAiUpscaleComplete.
  ///
  /// In en, this message translates to:
  /// **'NovelAI upscale complete'**
  String get img2img_novelAiUpscaleComplete;

  /// No description provided for @img2img_decodeSourceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode source image'**
  String get img2img_decodeSourceFailed;

  /// No description provided for @img2img_upscalePanelOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened the Image2Image Upscale panel'**
  String get img2img_upscalePanelOpened;

  /// No description provided for @editor_tolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get editor_tolerance;

  /// No description provided for @editor_intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get editor_intensity;

  /// No description provided for @editor_sourcePoint.
  ///
  /// In en, this message translates to:
  /// **'Alt+Click to set source point'**
  String get editor_sourcePoint;

  /// No description provided for @editor_brushPresets.
  ///
  /// In en, this message translates to:
  /// **'Brush Presets'**
  String get editor_brushPresets;

  /// No description provided for @editor_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get editor_size;

  /// No description provided for @editor_opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get editor_opacity;

  /// No description provided for @editor_hardness.
  ///
  /// In en, this message translates to:
  /// **'Hardness'**
  String get editor_hardness;

  /// No description provided for @editor_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editor_undo;

  /// No description provided for @editor_redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editor_redo;

  /// No description provided for @editor_clearLayer.
  ///
  /// In en, this message translates to:
  /// **'Clear Layer'**
  String get editor_clearLayer;

  /// No description provided for @editor_toolBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get editor_toolBrush;

  /// No description provided for @editor_toolEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get editor_toolEraser;

  /// No description provided for @editor_toolFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get editor_toolFill;

  /// No description provided for @editor_toolMagicWand.
  ///
  /// In en, this message translates to:
  /// **'Magic Wand'**
  String get editor_toolMagicWand;

  /// No description provided for @editor_magicWandMode.
  ///
  /// In en, this message translates to:
  /// **'Selection method'**
  String get editor_magicWandMode;

  /// No description provided for @editor_magicWandSmartObject.
  ///
  /// In en, this message translates to:
  /// **'Smart object (EfficientViT)'**
  String get editor_magicWandSmartObject;

  /// No description provided for @editor_magicWandColorArea.
  ///
  /// In en, this message translates to:
  /// **'Color area (flood fill)'**
  String get editor_magicWandColorArea;

  /// No description provided for @editor_magicWandSmartHelp.
  ///
  /// In en, this message translates to:
  /// **'Click the object to select. The first use downloads the approximately 133 MiB EfficientViT-SAM L0 model from MIT Han Lab (Apache-2.0), then keeps it locally.'**
  String get editor_magicWandSmartHelp;

  /// No description provided for @editor_magicWandColorHelp.
  ///
  /// In en, this message translates to:
  /// **'Click a contiguous region of similar color. This works best on flat, clean boundaries and requires no model download.'**
  String get editor_magicWandColorHelp;

  /// No description provided for @editor_magicWandInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert result'**
  String get editor_magicWandInvert;

  /// No description provided for @editor_toolLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get editor_toolLine;

  /// No description provided for @editor_toolRectSelect.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get editor_toolRectSelect;

  /// No description provided for @editor_toolEllipseSelect.
  ///
  /// In en, this message translates to:
  /// **'Ellipse'**
  String get editor_toolEllipseSelect;

  /// No description provided for @editor_toolLassoSelect.
  ///
  /// In en, this message translates to:
  /// **'Lasso'**
  String get editor_toolLassoSelect;

  /// No description provided for @editor_toolColorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get editor_toolColorPicker;

  /// No description provided for @editor_toolCloneStamp.
  ///
  /// In en, this message translates to:
  /// **'Clone Stamp'**
  String get editor_toolCloneStamp;

  /// No description provided for @editor_toolBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get editor_toolBlur;

  /// No description provided for @editor_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get editor_back;

  /// No description provided for @editor_layers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get editor_layers;

  /// No description provided for @editor_fillClosedRegion.
  ///
  /// In en, this message translates to:
  /// **'Fill Closed Region'**
  String get editor_fillClosedRegion;

  /// No description provided for @editor_resetMask.
  ///
  /// In en, this message translates to:
  /// **'Reset Mask'**
  String get editor_resetMask;

  /// No description provided for @editor_zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get editor_zoomIn;

  /// No description provided for @editor_zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get editor_zoomOut;

  /// No description provided for @editor_fitToWindow.
  ///
  /// In en, this message translates to:
  /// **'Fit to Window'**
  String get editor_fitToWindow;

  /// No description provided for @editor_shortcut100Zoom.
  ///
  /// In en, this message translates to:
  /// **'100% Zoom'**
  String get editor_shortcut100Zoom;

  /// No description provided for @editor_effectBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get editor_effectBrightness;

  /// No description provided for @editor_effectSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get editor_effectSaturation;

  /// No description provided for @editor_changeCanvasSize.
  ///
  /// In en, this message translates to:
  /// **'Change Canvas Size'**
  String get editor_changeCanvasSize;

  /// No description provided for @editor_confirmExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Exit'**
  String get editor_confirmExitTitle;

  /// No description provided for @editor_confirmExitContent.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes. Are you sure you want to exit?'**
  String get editor_confirmExitContent;

  /// No description provided for @editor_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get editor_exit;

  /// No description provided for @editor_saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and Exit'**
  String get editor_saveAndExit;

  /// No description provided for @editor_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String editor_exportFailed(Object error);

  /// No description provided for @editor_maskLayerName.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get editor_maskLayerName;

  /// No description provided for @editor_emptyImageFile.
  ///
  /// In en, this message translates to:
  /// **'File is empty. Choose a valid image file'**
  String get editor_emptyImageFile;

  /// No description provided for @editor_fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large ({sizeMB} MB). Choose an image under 50 MB'**
  String editor_fileTooLarge(Object sizeMB);

  /// No description provided for @editor_parseImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse image file\nMake sure the file is not corrupted and the format is supported'**
  String get editor_parseImageFailed;

  /// No description provided for @editor_defaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get editor_defaultTitle;

  /// No description provided for @editor_baseLayerName.
  ///
  /// In en, this message translates to:
  /// **'Base Image'**
  String get editor_baseLayerName;

  /// No description provided for @editor_existingMaskLayerName.
  ///
  /// In en, this message translates to:
  /// **'Existing Mask'**
  String get editor_existingMaskLayerName;

  /// No description provided for @editor_defaultDrawingLayerName.
  ///
  /// In en, this message translates to:
  /// **'Layer 1'**
  String get editor_defaultDrawingLayerName;

  /// No description provided for @editor_layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {count}'**
  String editor_layerName(Object count);

  /// No description provided for @editor_canvasSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas Size'**
  String get editor_canvasSizeTitle;

  /// No description provided for @editor_presetSize.
  ///
  /// In en, this message translates to:
  /// **'Preset Size'**
  String get editor_presetSize;

  /// No description provided for @editor_customSize.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get editor_customSize;

  /// No description provided for @editor_contentHandling.
  ///
  /// In en, this message translates to:
  /// **'Content Handling'**
  String get editor_contentHandling;

  /// No description provided for @editor_contentCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get editor_contentCrop;

  /// No description provided for @editor_contentPad.
  ///
  /// In en, this message translates to:
  /// **'Pad'**
  String get editor_contentPad;

  /// No description provided for @editor_contentStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get editor_contentStretch;

  /// No description provided for @editor_width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get editor_width;

  /// No description provided for @editor_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get editor_height;

  /// No description provided for @editor_lockAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Lock aspect ratio'**
  String get editor_lockAspectRatio;

  /// No description provided for @editor_unlockAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Unlock aspect ratio'**
  String get editor_unlockAspectRatio;

  /// No description provided for @editor_sizePreview.
  ///
  /// In en, this message translates to:
  /// **'Size Preview'**
  String get editor_sizePreview;

  /// No description provided for @editor_originalSize.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get editor_originalSize;

  /// No description provided for @editor_newSize.
  ///
  /// In en, this message translates to:
  /// **'New Size'**
  String get editor_newSize;

  /// No description provided for @editor_cropModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Crop mode - keep aspect ratio and crop'**
  String get editor_cropModeDescription;

  /// No description provided for @editor_padModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Pad mode - keep aspect ratio and pad'**
  String get editor_padModeDescription;

  /// No description provided for @editor_stretchModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Stretch mode - stretch to fill'**
  String get editor_stretchModeDescription;

  /// No description provided for @editor_canvasPresetSquare.
  ///
  /// In en, this message translates to:
  /// **'Square {size}'**
  String editor_canvasPresetSquare(Object size);

  /// No description provided for @editor_canvasPresetLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape {ratio}'**
  String editor_canvasPresetLandscape(Object ratio);

  /// No description provided for @editor_canvasPresetPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait {ratio}'**
  String editor_canvasPresetPortrait(Object ratio);

  /// No description provided for @editor_canvasPresetNaiPortrait.
  ///
  /// In en, this message translates to:
  /// **'NAI Portrait'**
  String get editor_canvasPresetNaiPortrait;

  /// No description provided for @editor_canvasPresetNaiLandscape.
  ///
  /// In en, this message translates to:
  /// **'NAI Landscape'**
  String get editor_canvasPresetNaiLandscape;

  /// No description provided for @editor_canvasPresetFullHd.
  ///
  /// In en, this message translates to:
  /// **'Full HD 16:9'**
  String get editor_canvasPresetFullHd;

  /// No description provided for @editor_colorPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get editor_colorPanelTitle;

  /// No description provided for @editor_colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get editor_colorPickerTitle;

  /// No description provided for @editor_brushSettings.
  ///
  /// In en, this message translates to:
  /// **'Brush Settings'**
  String get editor_brushSettings;

  /// No description provided for @editor_eraserSettings.
  ///
  /// In en, this message translates to:
  /// **'Eraser Settings'**
  String get editor_eraserSettings;

  /// No description provided for @editor_lassoSelectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag to draw a freeform selection. Release to close it automatically.'**
  String get editor_lassoSelectionHelp;

  /// No description provided for @layer_empty.
  ///
  /// In en, this message translates to:
  /// **'No layers'**
  String get layer_empty;

  /// No description provided for @layer_add.
  ///
  /// In en, this message translates to:
  /// **'Add Layer'**
  String get layer_add;

  /// No description provided for @layer_mergeDown.
  ///
  /// In en, this message translates to:
  /// **'Merge Down'**
  String get layer_mergeDown;

  /// No description provided for @layer_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get layer_duplicate;

  /// No description provided for @layer_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get layer_delete;

  /// No description provided for @layer_merge.
  ///
  /// In en, this message translates to:
  /// **'Merge Down'**
  String get layer_merge;

  /// No description provided for @layer_visibility.
  ///
  /// In en, this message translates to:
  /// **'Toggle Visibility'**
  String get layer_visibility;

  /// No description provided for @layer_lock.
  ///
  /// In en, this message translates to:
  /// **'Toggle Lock'**
  String get layer_lock;

  /// No description provided for @layer_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get layer_rename;

  /// No description provided for @layer_moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get layer_moveUp;

  /// No description provided for @layer_moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get layer_moveDown;

  /// No description provided for @vibe_title.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer'**
  String get vibe_title;

  /// No description provided for @vibe_description.
  ///
  /// In en, this message translates to:
  /// **'Change the image, keep the vision.'**
  String get vibe_description;

  /// No description provided for @vibe_addFromFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Add from File'**
  String get vibe_addFromFileTitle;

  /// No description provided for @vibe_addFromFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG, Vibe files'**
  String get vibe_addFromFileSubtitle;

  /// No description provided for @vibe_addFromLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Library'**
  String get vibe_addFromLibraryTitle;

  /// No description provided for @vibe_addFromLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select from Vibe Library'**
  String get vibe_addFromLibrarySubtitle;

  /// No description provided for @vibe_addReference.
  ///
  /// In en, this message translates to:
  /// **'Add Reference'**
  String get vibe_addReference;

  /// No description provided for @vibe_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get vibe_clearAll;

  /// No description provided for @vibe_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} vibes'**
  String vibe_cleared(int count);

  /// No description provided for @vibe_referenceStrength.
  ///
  /// In en, this message translates to:
  /// **'Ref Strength'**
  String get vibe_referenceStrength;

  /// No description provided for @vibe_infoExtraction.
  ///
  /// In en, this message translates to:
  /// **'Information Extracted'**
  String get vibe_infoExtraction;

  /// No description provided for @vibe_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get vibe_remove;

  /// No description provided for @reference_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get reference_enabled;

  /// No description provided for @reference_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable reference'**
  String get reference_enable;

  /// No description provided for @reference_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable reference'**
  String get reference_disable;

  /// No description provided for @vibe_normalize.
  ///
  /// In en, this message translates to:
  /// **'Normalize Reference Strength Values'**
  String get vibe_normalize;

  /// No description provided for @vibe_sourceType_png.
  ///
  /// In en, this message translates to:
  /// **'PNG'**
  String get vibe_sourceType_png;

  /// No description provided for @vibe_sourceType_v4vibe.
  ///
  /// In en, this message translates to:
  /// **'V4 Vibe'**
  String get vibe_sourceType_v4vibe;

  /// No description provided for @vibe_sourceType_bundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get vibe_sourceType_bundle;

  /// No description provided for @vibe_sourceType_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get vibe_sourceType_image;

  /// No description provided for @vibe_sourceType.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get vibe_sourceType;

  /// No description provided for @vibe_reuseButton.
  ///
  /// In en, this message translates to:
  /// **'Reuse'**
  String get vibe_reuseButton;

  /// No description provided for @vibe_info.
  ///
  /// In en, this message translates to:
  /// **'Vibe Info'**
  String get vibe_info;

  /// No description provided for @vibe_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vibe_name;

  /// No description provided for @vibe_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get vibe_strength;

  /// No description provided for @vibe_infoExtracted.
  ///
  /// In en, this message translates to:
  /// **'Information Extracted'**
  String get vibe_infoExtracted;

  /// No description provided for @vibe_shiftReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Shift+Click to Replace'**
  String get vibe_shiftReplaceHint;

  /// No description provided for @character_buttonLabel.
  ///
  /// In en, this message translates to:
  /// **'Char/Position'**
  String get character_buttonLabel;

  /// No description provided for @character_addCharacter.
  ///
  /// In en, this message translates to:
  /// **'Add Character'**
  String get character_addCharacter;

  /// No description provided for @character_number.
  ///
  /// In en, this message translates to:
  /// **'Character {index}'**
  String character_number(Object index);

  /// No description provided for @gallery_generationParams.
  ///
  /// In en, this message translates to:
  /// **'Generation Parameters'**
  String get gallery_generationParams;

  /// No description provided for @gallery_metaModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get gallery_metaModel;

  /// No description provided for @gallery_metaResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get gallery_metaResolution;

  /// No description provided for @gallery_metaSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get gallery_metaSteps;

  /// No description provided for @gallery_metaSampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get gallery_metaSampler;

  /// No description provided for @gallery_metaCfgScale.
  ///
  /// In en, this message translates to:
  /// **'Prompt Guidance'**
  String get gallery_metaCfgScale;

  /// No description provided for @gallery_metaSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get gallery_metaSeed;

  /// No description provided for @gallery_metaSmea.
  ///
  /// In en, this message translates to:
  /// **'SMEA'**
  String get gallery_metaSmea;

  /// No description provided for @gallery_promptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied'**
  String get gallery_promptCopied;

  /// No description provided for @gallery_seedCopied.
  ///
  /// In en, this message translates to:
  /// **'Seed copied'**
  String get gallery_seedCopied;

  /// No description provided for @gallery_sendToKritaAction.
  ///
  /// In en, this message translates to:
  /// **'Send to Krita'**
  String get gallery_sendToKritaAction;

  /// No description provided for @gallery_upscalePanelLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded the Image2Image Upscale panel'**
  String get gallery_upscalePanelLoaded;

  /// No description provided for @gallery_readImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read image: {error}'**
  String gallery_readImageFailed(Object error);

  /// No description provided for @gallery_fileMissing.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get gallery_fileMissing;

  /// No description provided for @gallery_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get gallery_copiedToClipboard;

  /// No description provided for @gallery_copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String gallery_copyFailed(Object error);

  /// No description provided for @gallery_upscale.
  ///
  /// In en, this message translates to:
  /// **'Upscale'**
  String get gallery_upscale;

  /// No description provided for @gallery_sentToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Image sent to Image2Image'**
  String get gallery_sentToImg2Img;

  /// No description provided for @gallery_sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String gallery_sendFailed(Object error);

  /// No description provided for @onlineGallery_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get onlineGallery_search;

  /// No description provided for @onlineGallery_popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get onlineGallery_popular;

  /// No description provided for @onlineGallery_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get onlineGallery_favorites;

  /// No description provided for @onlineGallery_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get onlineGallery_refresh;

  /// No description provided for @onlineGallery_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get onlineGallery_login;

  /// No description provided for @onlineGallery_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get onlineGallery_logout;

  /// No description provided for @onlineGallery_dayRank.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get onlineGallery_dayRank;

  /// No description provided for @onlineGallery_weekRank.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get onlineGallery_weekRank;

  /// No description provided for @onlineGallery_monthRank.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get onlineGallery_monthRank;

  /// No description provided for @onlineGallery_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get onlineGallery_today;

  /// No description provided for @onlineGallery_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String onlineGallery_imageCount(Object count);

  /// No description provided for @onlineGallery_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get onlineGallery_loadFailed;

  /// No description provided for @onlineGallery_favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Favorites is empty'**
  String get onlineGallery_favoritesEmpty;

  /// No description provided for @onlineGallery_noResults.
  ///
  /// In en, this message translates to:
  /// **'No images found'**
  String get onlineGallery_noResults;

  /// No description provided for @onlineGallery_pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get onlineGallery_pleaseLogin;

  /// No description provided for @onlineGallery_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get onlineGallery_size;

  /// No description provided for @onlineGallery_score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get onlineGallery_score;

  /// No description provided for @onlineGallery_favCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get onlineGallery_favCount;

  /// No description provided for @onlineGallery_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get onlineGallery_type;

  /// No description provided for @mediaType_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaType_video;

  /// No description provided for @mediaType_gif.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get mediaType_gif;

  /// No description provided for @onlineGallery_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get onlineGallery_tags;

  /// No description provided for @onlineGallery_artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get onlineGallery_artists;

  /// No description provided for @onlineGallery_characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get onlineGallery_characters;

  /// No description provided for @onlineGallery_copyrights.
  ///
  /// In en, this message translates to:
  /// **'Copyrights'**
  String get onlineGallery_copyrights;

  /// No description provided for @onlineGallery_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get onlineGallery_general;

  /// No description provided for @onlineGallery_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get onlineGallery_copied;

  /// No description provided for @onlineGallery_copyTags.
  ///
  /// In en, this message translates to:
  /// **'Copy Tags'**
  String get onlineGallery_copyTags;

  /// No description provided for @onlineGallery_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get onlineGallery_open;

  /// No description provided for @onlineGallery_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get onlineGallery_send;

  /// No description provided for @onlineGallery_sendToTextToImage.
  ///
  /// In en, this message translates to:
  /// **'Send to Text to Image'**
  String get onlineGallery_sendToTextToImage;

  /// No description provided for @onlineGallery_sentToTextToImage.
  ///
  /// In en, this message translates to:
  /// **'Sent to text-to-image'**
  String get onlineGallery_sentToTextToImage;

  /// No description provided for @onlineGallery_noTagInfo.
  ///
  /// In en, this message translates to:
  /// **'This image has no tag information'**
  String get onlineGallery_noTagInfo;

  /// No description provided for @onlineGallery_promptSentToGeneration.
  ///
  /// In en, this message translates to:
  /// **'Prompt sent to generation page'**
  String get onlineGallery_promptSentToGeneration;

  /// No description provided for @onlineGallery_gifLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load GIF'**
  String get onlineGallery_gifLoadFailed;

  /// No description provided for @onlineGallery_pinchToZoom.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom'**
  String get onlineGallery_pinchToZoom;

  /// No description provided for @onlineGallery_metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get onlineGallery_metadata;

  /// No description provided for @onlineGallery_chooseDownloadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose Download Directory'**
  String get onlineGallery_chooseDownloadDirectory;

  /// No description provided for @onlineGallery_downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started...'**
  String get onlineGallery_downloadStarted;

  /// No description provided for @onlineGallery_savedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String onlineGallery_savedToPath(Object path);

  /// No description provided for @onlineGallery_downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String onlineGallery_downloadFailed(Object error);

  /// No description provided for @onlineGallery_downloadOriginal.
  ///
  /// In en, this message translates to:
  /// **'Download original image'**
  String get onlineGallery_downloadOriginal;

  /// No description provided for @onlineGallery_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get onlineGallery_all;

  /// No description provided for @onlineGallery_ratingGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get onlineGallery_ratingGeneral;

  /// No description provided for @onlineGallery_ratingSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get onlineGallery_ratingSensitive;

  /// No description provided for @onlineGallery_ratingQuestionable.
  ///
  /// In en, this message translates to:
  /// **'Questionable'**
  String get onlineGallery_ratingQuestionable;

  /// No description provided for @onlineGallery_ratingExplicit.
  ///
  /// In en, this message translates to:
  /// **'Explicit'**
  String get onlineGallery_ratingExplicit;

  /// No description provided for @onlineGallery_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get onlineGallery_clear;

  /// No description provided for @onlineGallery_previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get onlineGallery_previousPage;

  /// No description provided for @onlineGallery_nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get onlineGallery_nextPage;

  /// No description provided for @onlineGallery_pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String onlineGallery_pageN(Object page);

  /// No description provided for @onlineGallery_dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get onlineGallery_dateRange;

  /// No description provided for @onlineGallery_fuzzySearch.
  ///
  /// In en, this message translates to:
  /// **'Fuzzy Match'**
  String get onlineGallery_fuzzySearch;

  /// No description provided for @onlineGallery_fuzzySearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use *tag* matching for related tags when enabled; search exact Danbooru tags when disabled'**
  String get onlineGallery_fuzzySearchTooltip;

  /// No description provided for @onlineGallery_blacklistTags.
  ///
  /// In en, this message translates to:
  /// **'Blacklist Tags'**
  String get onlineGallery_blacklistTags;

  /// No description provided for @onlineGallery_blacklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Gallery Blacklist'**
  String get onlineGallery_blacklistTitle;

  /// No description provided for @onlineGallery_blacklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Images containing blacklisted tags will be hidden directly in the online gallery.'**
  String get onlineGallery_blacklistSubtitle;

  /// No description provided for @onlineGallery_addBlacklistTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add blacklist tag'**
  String get onlineGallery_addBlacklistTagHint;

  /// No description provided for @onlineGallery_noLocalBlacklistTags.
  ///
  /// In en, this message translates to:
  /// **'No local blacklist tags'**
  String get onlineGallery_noLocalBlacklistTags;

  /// No description provided for @onlineGallery_autoSyncOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync on startup'**
  String get onlineGallery_autoSyncOnStartup;

  /// No description provided for @onlineGallery_autoSyncOnStartupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled by default; you can turn it off at any time'**
  String get onlineGallery_autoSyncOnStartupSubtitle;

  /// No description provided for @onlineGallery_lastSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Last sync failed: {error}'**
  String onlineGallery_lastSyncFailed(Object error);

  /// No description provided for @onlineGallery_neverSyncedBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Danbooru blacklist has not been synced yet'**
  String get onlineGallery_neverSyncedBlacklist;

  /// No description provided for @onlineGallery_lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String onlineGallery_lastSync(Object time);

  /// No description provided for @onlineGallery_blacklistSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Gallery Blacklist Settings'**
  String get onlineGallery_blacklistSettingsTitle;

  /// No description provided for @onlineGallery_blacklistLoginHint.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in to Danbooru. The local blacklist still works, but syncing requires login.'**
  String get onlineGallery_blacklistLoginHint;

  /// No description provided for @onlineGallery_bulkFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite Selected'**
  String get onlineGallery_bulkFavorite;

  /// No description provided for @onlineGallery_bulkDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Selected'**
  String get onlineGallery_bulkDownload;

  /// No description provided for @onlineGallery_unfavorited.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited'**
  String get onlineGallery_unfavorited;

  /// No description provided for @onlineGallery_favorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get onlineGallery_favorited;

  /// No description provided for @onlineGallery_favoritedImages.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count} images'**
  String onlineGallery_favoritedImages(Object count);

  /// No description provided for @onlineGallery_selectDownloadDirectoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to choose download directory: {error}'**
  String onlineGallery_selectDownloadDirectoryFailed(Object error);

  /// No description provided for @onlineGallery_downloadSelectedStarted.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count} images...'**
  String onlineGallery_downloadSelectedStarted(Object count);

  /// No description provided for @onlineGallery_downloadSelectedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Download complete: {success} succeeded, {failed} failed'**
  String onlineGallery_downloadSelectedCompleted(Object success, Object failed);

  /// No description provided for @onlineGallery_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get onlineGallery_startDate;

  /// No description provided for @onlineGallery_endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get onlineGallery_endDate;

  /// No description provided for @onlineGallery_invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get onlineGallery_invalidDateFormat;

  /// No description provided for @onlineGallery_dateOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Date out of range'**
  String get onlineGallery_dateOutOfRange;

  /// No description provided for @onlineGallery_last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get onlineGallery_last30Days;

  /// No description provided for @onlineGallery_configureGelbooruApi.
  ///
  /// In en, this message translates to:
  /// **'Configure Gelbooru API'**
  String get onlineGallery_configureGelbooruApi;

  /// No description provided for @onlineGallery_gelbooruApiReady.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru API verified'**
  String get onlineGallery_gelbooruApiReady;

  /// No description provided for @onlineGallery_gelbooruApiInvalid.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru credentials expired'**
  String get onlineGallery_gelbooruApiInvalid;

  /// No description provided for @onlineGallery_gelbooruCredentialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Configure your Gelbooru User ID and API Key to view website favorites.'**
  String get onlineGallery_gelbooruCredentialsRequired;

  /// No description provided for @onlineGallery_gelbooruCredentialsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Your Gelbooru credentials are no longer valid. Configure them again.'**
  String get onlineGallery_gelbooruCredentialsInvalid;

  /// No description provided for @onlineGallery_gelbooruRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru is rate limiting requests. Try again later.'**
  String get onlineGallery_gelbooruRateLimited;

  /// No description provided for @onlineGallery_gelbooruTimeout.
  ///
  /// In en, this message translates to:
  /// **'The Gelbooru request timed out. Check your network connection.'**
  String get onlineGallery_gelbooruTimeout;

  /// No description provided for @onlineGallery_gelbooruServerError.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru is temporarily unavailable. Try again later.'**
  String get onlineGallery_gelbooruServerError;

  /// No description provided for @onlineGallery_gelbooruNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Gelbooru. Check your network or proxy settings.'**
  String get onlineGallery_gelbooruNetworkError;

  /// No description provided for @onlineGallery_gelbooruMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru returned data that could not be parsed.'**
  String get onlineGallery_gelbooruMalformedResponse;

  /// No description provided for @onlineGallery_gelbooruRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The Gelbooru request failed. Try again later.'**
  String get onlineGallery_gelbooruRequestFailed;

  /// No description provided for @onlineGallery_aiTagQuery.
  ///
  /// In en, this message translates to:
  /// **'Search works, artists, titles, tags, or models'**
  String get onlineGallery_aiTagQuery;

  /// No description provided for @onlineGallery_aiTagPromptQuery.
  ///
  /// In en, this message translates to:
  /// **'AI Prompt search (raw syntax such as ::artist: is supported)'**
  String get onlineGallery_aiTagPromptQuery;

  /// No description provided for @onlineGallery_aiTagTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get onlineGallery_aiTagTimeRange;

  /// No description provided for @onlineGallery_aiTagAllTime.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get onlineGallery_aiTagAllTime;

  /// No description provided for @onlineGallery_aiTagCurrentMonthly.
  ///
  /// In en, this message translates to:
  /// **'Live monthly ranking'**
  String get onlineGallery_aiTagCurrentMonthly;

  /// No description provided for @onlineGallery_aiTagOlderMonthly.
  ///
  /// In en, this message translates to:
  /// **'Older archive'**
  String get onlineGallery_aiTagOlderMonthly;

  /// No description provided for @onlineGallery_aiTagRankingProcessing.
  ///
  /// In en, this message translates to:
  /// **'The ranking is being generated. Please try again shortly.'**
  String get onlineGallery_aiTagRankingProcessing;

  /// No description provided for @onlineGallery_aiTagNaiOnly.
  ///
  /// In en, this message translates to:
  /// **'NAI only'**
  String get onlineGallery_aiTagNaiOnly;

  /// No description provided for @onlineGallery_aiTagModelVersion.
  ///
  /// In en, this message translates to:
  /// **'Model version'**
  String get onlineGallery_aiTagModelVersion;

  /// No description provided for @onlineGallery_viewAuthor.
  ///
  /// In en, this message translates to:
  /// **'View this author'**
  String get onlineGallery_viewAuthor;

  /// No description provided for @onlineGallery_returnFromAuthor.
  ///
  /// In en, this message translates to:
  /// **'Return to previous gallery position'**
  String get onlineGallery_returnFromAuthor;

  /// No description provided for @onlineGallery_generationParams.
  ///
  /// In en, this message translates to:
  /// **'Generation parameters'**
  String get onlineGallery_generationParams;

  /// No description provided for @onlineGallery_sourceConfigUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load source configuration. Check your connection and retry.'**
  String get onlineGallery_sourceConfigUnavailable;

  /// No description provided for @onlineGallery_sourceRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get onlineGallery_sourceRateLimited;

  /// No description provided for @onlineGallery_sourceTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Check your connection.'**
  String get onlineGallery_sourceTimeout;

  /// No description provided for @onlineGallery_sourceNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to this gallery source. Check your network or proxy.'**
  String get onlineGallery_sourceNetworkError;

  /// No description provided for @onlineGallery_sourceMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'The source response format has changed and cannot be parsed.'**
  String get onlineGallery_sourceMalformedResponse;

  /// No description provided for @onlineGallery_detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This work does not exist or has been removed.'**
  String get onlineGallery_detailNotFound;

  /// No description provided for @onlineGallery_imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This image is currently unavailable.'**
  String get onlineGallery_imageUnavailable;

  /// No description provided for @onlineGallery_loadedAll.
  ///
  /// In en, this message translates to:
  /// **'All items loaded'**
  String get onlineGallery_loadedAll;

  /// No description provided for @onlineGallery_retryAppend.
  ///
  /// In en, this message translates to:
  /// **'Load failed. Click to retry'**
  String get onlineGallery_retryAppend;

  /// No description provided for @onlineGallery_rankNumber.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String onlineGallery_rankNumber(Object rank);

  /// No description provided for @onlineGallery_multipleImages.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String onlineGallery_multipleImages(Object count);

  /// No description provided for @onlineGallery_views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get onlineGallery_views;

  /// No description provided for @onlineGallery_downloadAllMedia.
  ///
  /// In en, this message translates to:
  /// **'Download all images in this work'**
  String get onlineGallery_downloadAllMedia;

  /// No description provided for @onlineGallery_copyFullMetadata.
  ///
  /// In en, this message translates to:
  /// **'Copy full metadata'**
  String get onlineGallery_copyFullMetadata;

  /// No description provided for @onlineGallery_metadataParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Metadata parsing failed. The original content is preserved and can be copied.'**
  String get onlineGallery_metadataParseFailed;

  /// No description provided for @onlineGallery_gelbooruReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only favorites'**
  String get onlineGallery_gelbooruReadOnly;

  /// No description provided for @onlineGallery_gelbooruFavoritesSortHint.
  ///
  /// In en, this message translates to:
  /// **'Sorted by post ID, newest first. This may differ from website favorite-time order.'**
  String get onlineGallery_gelbooruFavoritesSortHint;

  /// No description provided for @tooltip_fullscreenEdit.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Edit'**
  String get tooltip_fullscreenEdit;

  /// No description provided for @tooltip_decreaseWeight.
  ///
  /// In en, this message translates to:
  /// **'Decrease Weight [-5%]'**
  String get tooltip_decreaseWeight;

  /// No description provided for @tooltip_increaseWeight.
  ///
  /// In en, this message translates to:
  /// **'Increase Weight [+5%]'**
  String get tooltip_increaseWeight;

  /// No description provided for @tooltip_resetWeight.
  ///
  /// In en, this message translates to:
  /// **'Click to reset to 100%'**
  String get tooltip_resetWeight;

  /// No description provided for @upscale_scale.
  ///
  /// In en, this message translates to:
  /// **'Scale Factor'**
  String get upscale_scale;

  /// No description provided for @danbooru_loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Danbooru'**
  String get danbooru_loginTitle;

  /// No description provided for @danbooru_loginHint.
  ///
  /// In en, this message translates to:
  /// **'Login with username and API Key to use favorites'**
  String get danbooru_loginHint;

  /// No description provided for @danbooru_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get danbooru_username;

  /// No description provided for @danbooru_usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Danbooru username'**
  String get danbooru_usernameHint;

  /// No description provided for @danbooru_usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get danbooru_usernameRequired;

  /// No description provided for @danbooru_apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get danbooru_apiKeyHint;

  /// No description provided for @danbooru_apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter API Key'**
  String get danbooru_apiKeyRequired;

  /// No description provided for @danbooru_howToGetApiKey.
  ///
  /// In en, this message translates to:
  /// **'How to get API Key?'**
  String get danbooru_howToGetApiKey;

  /// No description provided for @danbooru_loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get danbooru_loginSuccess;

  /// No description provided for @gelbooru_configureTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Gelbooru API'**
  String get gelbooru_configureTitle;

  /// No description provided for @gelbooru_configureHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the User ID and API Key shown in your Gelbooru account settings. The app does not collect your password or browser cookies.'**
  String get gelbooru_configureHint;

  /// No description provided for @gelbooru_userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get gelbooru_userId;

  /// No description provided for @gelbooru_userIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive numeric User ID'**
  String get gelbooru_userIdHint;

  /// No description provided for @gelbooru_userIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive numeric User ID'**
  String get gelbooru_userIdRequired;

  /// No description provided for @gelbooru_apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get gelbooru_apiKeyHint;

  /// No description provided for @gelbooru_apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an API Key'**
  String get gelbooru_apiKeyRequired;

  /// No description provided for @gelbooru_openAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Gelbooru account settings'**
  String get gelbooru_openAccountSettings;

  /// No description provided for @gelbooru_save.
  ///
  /// In en, this message translates to:
  /// **'Verify and Save'**
  String get gelbooru_save;

  /// No description provided for @gelbooru_saved.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru credentials saved'**
  String get gelbooru_saved;

  /// No description provided for @gelbooru_removeCredentials.
  ///
  /// In en, this message translates to:
  /// **'Remove Credentials'**
  String get gelbooru_removeCredentials;

  /// No description provided for @gelbooru_invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid User ID and API Key.'**
  String get gelbooru_invalidInput;

  /// No description provided for @gelbooru_invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru rejected these credentials. Check the User ID and API Key.'**
  String get gelbooru_invalidCredentials;

  /// No description provided for @gelbooru_rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again later.'**
  String get gelbooru_rateLimited;

  /// No description provided for @gelbooru_timeout.
  ///
  /// In en, this message translates to:
  /// **'Verification timed out. Check your network connection.'**
  String get gelbooru_timeout;

  /// No description provided for @gelbooru_serverError.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru is temporarily unavailable.'**
  String get gelbooru_serverError;

  /// No description provided for @gelbooru_networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Gelbooru. Check your network or proxy settings.'**
  String get gelbooru_networkError;

  /// No description provided for @gelbooru_malformedResponse.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru returned data that could not be parsed.'**
  String get gelbooru_malformedResponse;

  /// No description provided for @gelbooru_storageError.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru credentials could not be stored or read securely.'**
  String get gelbooru_storageError;

  /// No description provided for @gelbooru_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Gelbooru verification failed. Try again later.'**
  String get gelbooru_unknownError;

  /// No description provided for @tag_addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get tag_addTag;

  /// No description provided for @qualityTags_label.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualityTags_label;

  /// No description provided for @transparentBackground_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Adds \"transparent background\" to the prompt and generates images with an alpha channel (V5 only)'**
  String get transparentBackground_tooltip;

  /// No description provided for @qualityTags_positive.
  ///
  /// In en, this message translates to:
  /// **'Quality (Prompt)'**
  String get qualityTags_positive;

  /// No description provided for @qualityTags_negative.
  ///
  /// In en, this message translates to:
  /// **'Quality (Undesired Content)'**
  String get qualityTags_negative;

  /// No description provided for @qualityTags_disabled.
  ///
  /// In en, this message translates to:
  /// **'Quality tags disabled\nClick to enable'**
  String get qualityTags_disabled;

  /// No description provided for @qualityTags_addToEnd.
  ///
  /// In en, this message translates to:
  /// **'Add to prompt end:'**
  String get qualityTags_addToEnd;

  /// No description provided for @qualityTags_addToStart.
  ///
  /// In en, this message translates to:
  /// **'Add to prompt start:'**
  String get qualityTags_addToStart;

  /// No description provided for @qualityTags_naiDefault.
  ///
  /// In en, this message translates to:
  /// **'NAI Default'**
  String get qualityTags_naiDefault;

  /// No description provided for @qualityTags_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get qualityTags_standard;

  /// No description provided for @qualityTags_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get qualityTags_light;

  /// No description provided for @qualityTags_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get qualityTags_none;

  /// No description provided for @ucPreset_label.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Preset'**
  String get ucPreset_label;

  /// No description provided for @ucPreset_heavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get ucPreset_heavy;

  /// No description provided for @ucPreset_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get ucPreset_light;

  /// No description provided for @ucPreset_furryFocus.
  ///
  /// In en, this message translates to:
  /// **'Furry'**
  String get ucPreset_furryFocus;

  /// No description provided for @ucPreset_humanFocus.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get ucPreset_humanFocus;

  /// No description provided for @ucPreset_lowQuality.
  ///
  /// In en, this message translates to:
  /// **'Low Quality'**
  String get ucPreset_lowQuality;

  /// No description provided for @ucPreset_badAnatomy.
  ///
  /// In en, this message translates to:
  /// **'Bad Anatomy'**
  String get ucPreset_badAnatomy;

  /// No description provided for @ucPreset_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get ucPreset_none;

  /// No description provided for @ucPreset_disabled.
  ///
  /// In en, this message translates to:
  /// **'Undesired content preset disabled'**
  String get ucPreset_disabled;

  /// No description provided for @ucPreset_addToNegative.
  ///
  /// In en, this message translates to:
  /// **'Add to Undesired Content:'**
  String get ucPreset_addToNegative;

  /// No description provided for @ucPreset_nsfwHint.
  ///
  /// In en, this message translates to:
  /// **'💡 To generate adult content, add nsfw to your prompt. The nsfw tag will be auto-removed from Undesired Content'**
  String get ucPreset_nsfwHint;

  /// No description provided for @generation_imageCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Images'**
  String get generation_imageCount;

  /// No description provided for @generation_requestCountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Requests: each click sends N generation requests'**
  String get generation_requestCountTooltip;

  /// No description provided for @generation_imageCountTotal.
  ///
  /// In en, this message translates to:
  /// **'{requests} requests × {perRequest} images = {total} total'**
  String generation_imageCountTotal(int requests, int perRequest, int total);

  /// No description provided for @warmup_networkCheck.
  ///
  /// In en, this message translates to:
  /// **'Checking network connection...'**
  String get warmup_networkCheck;

  /// No description provided for @warmup_networkCheck_noProxy.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to NovelAI, please enable VPN or proxy settings'**
  String get warmup_networkCheck_noProxy;

  /// No description provided for @warmup_networkCheck_noSystemProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy enabled but no system proxy detected, please enable VPN'**
  String get warmup_networkCheck_noSystemProxy;

  /// No description provided for @warmup_networkCheck_manualIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Manual proxy config incomplete, please check settings'**
  String get warmup_networkCheck_manualIncomplete;

  /// No description provided for @warmup_networkCheck_testing.
  ///
  /// In en, this message translates to:
  /// **'Testing network connection...'**
  String get warmup_networkCheck_testing;

  /// No description provided for @warmup_networkCheck_testingProxy.
  ///
  /// In en, this message translates to:
  /// **'Testing network via proxy...'**
  String get warmup_networkCheck_testingProxy;

  /// No description provided for @warmup_networkCheck_success.
  ///
  /// In en, this message translates to:
  /// **'Network connection OK ({latency}ms)'**
  String warmup_networkCheck_success(Object latency);

  /// No description provided for @warmup_networkCheck_timeout.
  ///
  /// In en, this message translates to:
  /// **'Network check timeout, continuing offline'**
  String get warmup_networkCheck_timeout;

  /// No description provided for @warmup_networkCheck_attempt.
  ///
  /// In en, this message translates to:
  /// **'Checking network... (attempt {attempt}/{maxAttempts})'**
  String warmup_networkCheck_attempt(Object attempt, Object maxAttempts);

  /// No description provided for @warmup_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get warmup_preparing;

  /// No description provided for @warmup_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get warmup_complete;

  /// No description provided for @warmup_danbooruAuth.
  ///
  /// In en, this message translates to:
  /// **'Initializing Danbooru authentication...'**
  String get warmup_danbooruAuth;

  /// No description provided for @warmup_loadingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Loading translation data...'**
  String get warmup_loadingTranslation;

  /// No description provided for @warmup_initUnifiedDatabase.
  ///
  /// In en, this message translates to:
  /// **'Initializing tag database...'**
  String get warmup_initUnifiedDatabase;

  /// No description provided for @warmup_initTagSystem.
  ///
  /// In en, this message translates to:
  /// **'Initializing tag system...'**
  String get warmup_initTagSystem;

  /// No description provided for @warmup_imageEditor.
  ///
  /// In en, this message translates to:
  /// **'Initializing image editor...'**
  String get warmup_imageEditor;

  /// No description provided for @warmup_database.
  ///
  /// In en, this message translates to:
  /// **'Loading recent history...'**
  String get warmup_database;

  /// No description provided for @warmup_network.
  ///
  /// In en, this message translates to:
  /// **'Checking network connection...'**
  String get warmup_network;

  /// No description provided for @warmup_fonts.
  ///
  /// In en, this message translates to:
  /// **'Preloading fonts...'**
  String get warmup_fonts;

  /// No description provided for @warmup_imageCache.
  ///
  /// In en, this message translates to:
  /// **'Warming up image cache...'**
  String get warmup_imageCache;

  /// No description provided for @warmup_statistics.
  ///
  /// In en, this message translates to:
  /// **'Loading statistics...'**
  String get warmup_statistics;

  /// No description provided for @warmup_artistsSync.
  ///
  /// In en, this message translates to:
  /// **'Syncing artists data...'**
  String get warmup_artistsSync;

  /// No description provided for @warmup_subscription.
  ///
  /// In en, this message translates to:
  /// **'Loading subscription info...'**
  String get warmup_subscription;

  /// No description provided for @warmup_dataSourceCache.
  ///
  /// In en, this message translates to:
  /// **'Initializing data source cache...'**
  String get warmup_dataSourceCache;

  /// No description provided for @warmup_galleryFileCount.
  ///
  /// In en, this message translates to:
  /// **'Scanning gallery files...'**
  String get warmup_galleryFileCount;

  /// No description provided for @warmup_cooccurrenceData.
  ///
  /// In en, this message translates to:
  /// **'Loading tag cooccurrence data...'**
  String get warmup_cooccurrenceData;

  /// No description provided for @warmup_group_basicUI.
  ///
  /// In en, this message translates to:
  /// **'Initializing basic UI services...'**
  String get warmup_group_basicUI;

  /// No description provided for @warmup_group_basicUI_complete.
  ///
  /// In en, this message translates to:
  /// **'Basic UI services ready'**
  String get warmup_group_basicUI_complete;

  /// No description provided for @warmup_group_dataServices.
  ///
  /// In en, this message translates to:
  /// **'Initializing data services...'**
  String get warmup_group_dataServices;

  /// No description provided for @warmup_group_dataServices_complete.
  ///
  /// In en, this message translates to:
  /// **'Data services ready'**
  String get warmup_group_dataServices_complete;

  /// No description provided for @warmup_group_networkServices.
  ///
  /// In en, this message translates to:
  /// **'Initializing network services...'**
  String get warmup_group_networkServices;

  /// No description provided for @warmup_group_networkServices_complete.
  ///
  /// In en, this message translates to:
  /// **'Network services ready'**
  String get warmup_group_networkServices_complete;

  /// No description provided for @warmup_group_cacheServices.
  ///
  /// In en, this message translates to:
  /// **'Initializing cache services...'**
  String get warmup_group_cacheServices;

  /// No description provided for @warmup_group_cacheServices_complete.
  ///
  /// In en, this message translates to:
  /// **'Cache services ready'**
  String get warmup_group_cacheServices_complete;

  /// No description provided for @warmup_cooccurrenceInit.
  ///
  /// In en, this message translates to:
  /// **'Initializing cooccurrence data...'**
  String get warmup_cooccurrenceInit;

  /// No description provided for @warmup_translationInit.
  ///
  /// In en, this message translates to:
  /// **'Initializing translation data...'**
  String get warmup_translationInit;

  /// No description provided for @warmup_danbooruTagsInit.
  ///
  /// In en, this message translates to:
  /// **'Initializing Danbooru tags...'**
  String get warmup_danbooruTagsInit;

  /// No description provided for @warmup_dataMigration.
  ///
  /// In en, this message translates to:
  /// **'Migrating Hive / Vibe / image data...'**
  String get warmup_dataMigration;

  /// No description provided for @warmup_galleryDataSource.
  ///
  /// In en, this message translates to:
  /// **'Initializing gallery index...'**
  String get warmup_galleryDataSource;

  /// No description provided for @warmup_checkAndRecoverData.
  ///
  /// In en, this message translates to:
  /// **'Checking data integrity...'**
  String get warmup_checkAndRecoverData;

  /// No description provided for @warmup_group_dataSourceInitialization.
  ///
  /// In en, this message translates to:
  /// **'Initializing data source services...'**
  String get warmup_group_dataSourceInitialization;

  /// No description provided for @warmup_group_dataSourceInitialization_complete.
  ///
  /// In en, this message translates to:
  /// **'Data source services ready'**
  String get warmup_group_dataSourceInitialization_complete;

  /// No description provided for @warmup_fetchingTags.
  ///
  /// In en, this message translates to:
  /// **'Syncing tags: {message}'**
  String warmup_fetchingTags(Object message);

  /// No description provided for @warmup_fetchingTagDataFromServer.
  ///
  /// In en, this message translates to:
  /// **'Fetching tag data from server...'**
  String get warmup_fetchingTagDataFromServer;

  /// No description provided for @warmup_fetchingGeneralTags.
  ///
  /// In en, this message translates to:
  /// **'Fetching general tags...'**
  String get warmup_fetchingGeneralTags;

  /// No description provided for @warmup_fetchingCharacterTags.
  ///
  /// In en, this message translates to:
  /// **'Fetching character tags...'**
  String get warmup_fetchingCharacterTags;

  /// No description provided for @warmup_fetchingCopyrightTags.
  ///
  /// In en, this message translates to:
  /// **'Fetching copyright tags...'**
  String get warmup_fetchingCopyrightTags;

  /// No description provided for @warmup_fetchingMetaTags.
  ///
  /// In en, this message translates to:
  /// **'Fetching meta tags...'**
  String get warmup_fetchingMetaTags;

  /// No description provided for @resolution_groupNormal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get resolution_groupNormal;

  /// No description provided for @resolution_groupLarge.
  ///
  /// In en, this message translates to:
  /// **'LARGE'**
  String get resolution_groupLarge;

  /// No description provided for @resolution_groupWallpaper.
  ///
  /// In en, this message translates to:
  /// **'WALLPAPER'**
  String get resolution_groupWallpaper;

  /// No description provided for @resolution_groupSmall.
  ///
  /// In en, this message translates to:
  /// **'SMALL'**
  String get resolution_groupSmall;

  /// No description provided for @resolution_groupCustom.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get resolution_groupCustom;

  /// No description provided for @resolution_typePortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get resolution_typePortrait;

  /// No description provided for @resolution_typeLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get resolution_typeLandscape;

  /// No description provided for @resolution_typeSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get resolution_typeSquare;

  /// No description provided for @resolution_typeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get resolution_typeCustom;

  /// No description provided for @resolution_width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get resolution_width;

  /// No description provided for @resolution_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get resolution_height;

  /// No description provided for @api_error_429.
  ///
  /// In en, this message translates to:
  /// **'Concurrency limit reached'**
  String get api_error_429;

  /// No description provided for @api_error_429_hint.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again (common with shared accounts)'**
  String get api_error_429_hint;

  /// No description provided for @api_error_401.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get api_error_401;

  /// No description provided for @api_error_401_hint.
  ///
  /// In en, this message translates to:
  /// **'Token invalid or expired. Please login again'**
  String get api_error_401_hint;

  /// No description provided for @api_error_402.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get api_error_402;

  /// No description provided for @api_error_402_hint.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Anlas. Please top up and try again'**
  String get api_error_402_hint;

  /// No description provided for @api_error_500.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get api_error_500;

  /// No description provided for @api_error_500_hint.
  ///
  /// In en, this message translates to:
  /// **'NovelAI server error. Please try again later'**
  String get api_error_500_hint;

  /// No description provided for @api_error_503.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable'**
  String get api_error_503;

  /// No description provided for @api_error_503_hint.
  ///
  /// In en, this message translates to:
  /// **'Server is under maintenance or overloaded. Please try again later'**
  String get api_error_503_hint;

  /// No description provided for @api_error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get api_error_timeout;

  /// No description provided for @api_error_timeout_hint.
  ///
  /// In en, this message translates to:
  /// **'Network timeout. Please check your connection and try again'**
  String get api_error_timeout_hint;

  /// No description provided for @api_error_network.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get api_error_network;

  /// No description provided for @api_error_network_hint.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your network'**
  String get api_error_network_hint;

  /// No description provided for @drop_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get drop_processing;

  /// No description provided for @characterEditor_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get characterEditor_clearAll;

  /// No description provided for @characterEditor_clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Characters'**
  String get characterEditor_clearAllTitle;

  /// No description provided for @characterEditor_clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all characters? This action cannot be undone.'**
  String get characterEditor_clearAllConfirm;

  /// No description provided for @characterEditor_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter character name'**
  String get characterEditor_nameHint;

  /// No description provided for @characterEditor_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get characterEditor_enabled;

  /// No description provided for @characterEditor_negativePromptHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Undesired Content for this character...'**
  String get characterEditor_negativePromptHint;

  /// No description provided for @characterCanvas_title.
  ///
  /// In en, this message translates to:
  /// **'Character Positions'**
  String get characterCanvas_title;

  /// Button that exits character position editing
  ///
  /// In en, this message translates to:
  /// **'Finish Editing Positions'**
  String get characterCanvas_finishEditing;

  /// No description provided for @characterCanvas_aiChoice.
  ///
  /// In en, this message translates to:
  /// **'AI\'s Choice'**
  String get characterCanvas_aiChoice;

  /// No description provided for @characterCanvas_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get characterCanvas_custom;

  /// No description provided for @characterCanvas_aiHint.
  ///
  /// In en, this message translates to:
  /// **'AI will place all characters automatically'**
  String get characterCanvas_aiHint;

  /// No description provided for @characterCanvas_dragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag anchors to position characters; release to apply'**
  String get characterCanvas_dragHint;

  /// No description provided for @characterEditor_genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get characterEditor_genderFemale;

  /// No description provided for @characterEditor_genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get characterEditor_genderMale;

  /// No description provided for @characterEditor_genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get characterEditor_genderOther;

  /// No description provided for @characterEditor_addFemale.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get characterEditor_addFemale;

  /// No description provided for @characterEditor_addMale.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get characterEditor_addMale;

  /// No description provided for @characterEditor_addOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get characterEditor_addOther;

  /// No description provided for @characterEditor_moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get characterEditor_moveUp;

  /// No description provided for @characterEditor_moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get characterEditor_moveDown;

  /// No description provided for @toolbar_fullscreenEdit.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Edit'**
  String get toolbar_fullscreenEdit;

  /// No description provided for @characterTooltip_noCharacters.
  ///
  /// In en, this message translates to:
  /// **'No characters configured'**
  String get characterTooltip_noCharacters;

  /// No description provided for @characterTooltip_clickToConfig.
  ///
  /// In en, this message translates to:
  /// **'Click to configure multi-character prompts'**
  String get characterTooltip_clickToConfig;

  /// No description provided for @characterTooltip_globalAiLabel.
  ///
  /// In en, this message translates to:
  /// **'Global AI Position:'**
  String get characterTooltip_globalAiLabel;

  /// No description provided for @characterTooltip_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get characterTooltip_enabled;

  /// No description provided for @characterTooltip_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get characterTooltip_disabled;

  /// No description provided for @characterTooltip_positionAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get characterTooltip_positionAi;

  /// No description provided for @characterTooltip_disabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get characterTooltip_disabledLabel;

  /// No description provided for @characterTooltip_promptLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get characterTooltip_promptLabel;

  /// No description provided for @characterTooltip_negativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get characterTooltip_negativeLabel;

  /// No description provided for @characterTooltip_notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get characterTooltip_notSet;

  /// No description provided for @characterTooltip_summary.
  ///
  /// In en, this message translates to:
  /// **'{total} characters ({enabled} enabled)'**
  String characterTooltip_summary(Object total, Object enabled);

  /// No description provided for @characterTooltip_viewFullConfig.
  ///
  /// In en, this message translates to:
  /// **'Click for full configuration'**
  String get characterTooltip_viewFullConfig;

  /// No description provided for @addGroup_displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Optional)'**
  String get addGroup_displayNameLabel;

  /// No description provided for @addGroup_targetCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Category'**
  String get addGroup_targetCategoryLabel;

  /// No description provided for @globalSettings_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String globalSettings_saveFailed(Object error);

  /// No description provided for @nav_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get nav_generate;

  /// No description provided for @nav_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get nav_gallery;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @sync_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing to sync...'**
  String get sync_preparing;

  /// No description provided for @sync_fetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching {category}...'**
  String sync_fetching(Object category);

  /// No description provided for @sync_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing data...'**
  String get sync_processing;

  /// No description provided for @sync_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get sync_saving;

  /// No description provided for @sync_completed.
  ///
  /// In en, this message translates to:
  /// **'Sync completed, {count} tags'**
  String sync_completed(Object count);

  /// No description provided for @sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String sync_failed(Object error);

  /// No description provided for @sync_extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting {poolName} tags...'**
  String sync_extracting(Object poolName);

  /// No description provided for @sync_merging.
  ///
  /// In en, this message translates to:
  /// **'Merging tags...'**
  String get sync_merging;

  /// No description provided for @sync_fetching_tags.
  ///
  /// In en, this message translates to:
  /// **'Fetching {groupName} tag popularity...'**
  String sync_fetching_tags(Object groupName);

  /// No description provided for @sync_filtering.
  ///
  /// In en, this message translates to:
  /// **'Filtering tags...'**
  String get sync_filtering;

  /// No description provided for @sync_done.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get sync_done;

  /// No description provided for @time_just_now.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get time_just_now;

  /// No description provided for @time_minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes ago'**
  String time_minutes_ago(Object n);

  /// No description provided for @time_hours_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} hours ago'**
  String time_hours_ago(Object n);

  /// No description provided for @time_days_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String time_days_ago(Object n);

  /// No description provided for @time_never_synced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get time_never_synced;

  /// No description provided for @vibeParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse Vibe file'**
  String get vibeParseFailed;

  /// No description provided for @localGallery_progressiveLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get localGallery_progressiveLoadError;

  /// No description provided for @localGallery_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get localGallery_unknownError;

  /// No description provided for @localGallery_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String localGallery_loadFailed(Object error);

  /// No description provided for @localGallery_indexingLocalImages.
  ///
  /// In en, this message translates to:
  /// **'Indexing local images...'**
  String get localGallery_indexingLocalImages;

  /// No description provided for @localGallery_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No local images'**
  String get localGallery_emptyTitle;

  /// No description provided for @localGallery_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generated images will be saved here'**
  String get localGallery_emptySubtitle;

  /// No description provided for @localGallery_noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get localGallery_noMatchingResults;

  /// No description provided for @localGallery_title.
  ///
  /// In en, this message translates to:
  /// **'Local Gallery'**
  String get localGallery_title;

  /// No description provided for @localGallery_allImages.
  ///
  /// In en, this message translates to:
  /// **'All Images'**
  String get localGallery_allImages;

  /// No description provided for @localGallery_selectAllResults.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get localGallery_selectAllResults;

  /// No description provided for @localGallery_deselectAllResults.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get localGallery_deselectAllResults;

  /// No description provided for @localGallery_moveSelected.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get localGallery_moveSelected;

  /// No description provided for @localGallery_packSelected.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get localGallery_packSelected;

  /// No description provided for @localGallery_editMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get localGallery_editMetadata;

  /// No description provided for @localGallery_addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get localGallery_addToCollection;

  /// No description provided for @localGallery_sortButton.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get localGallery_sortButton;

  /// No description provided for @localGallery_sortFieldModified.
  ///
  /// In en, this message translates to:
  /// **'Modified time'**
  String get localGallery_sortFieldModified;

  /// No description provided for @localGallery_sortFieldCreated.
  ///
  /// In en, this message translates to:
  /// **'Created time'**
  String get localGallery_sortFieldCreated;

  /// No description provided for @localGallery_sortFieldName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get localGallery_sortFieldName;

  /// No description provided for @localGallery_sortFieldSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get localGallery_sortFieldSize;

  /// No description provided for @localGallery_sortFieldDimensions.
  ///
  /// In en, this message translates to:
  /// **'Image size'**
  String get localGallery_sortFieldDimensions;

  /// No description provided for @localGallery_aboutColumns.
  ///
  /// In en, this message translates to:
  /// **'≈ {count} columns'**
  String localGallery_aboutColumns(Object count);

  /// No description provided for @localGallery_columnWidth.
  ///
  /// In en, this message translates to:
  /// **'Column width'**
  String get localGallery_columnWidth;

  /// No description provided for @localGallery_thumbnailQualitySd.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get localGallery_thumbnailQualitySd;

  /// No description provided for @localGallery_thumbnailQualityHd.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get localGallery_thumbnailQualityHd;

  /// No description provided for @settings_galleryThumbnailQuality.
  ///
  /// In en, this message translates to:
  /// **'Local gallery quality'**
  String get settings_galleryThumbnailQuality;

  /// No description provided for @settings_galleryThumbnailQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail display quality; defaults to High'**
  String get settings_galleryThumbnailQualitySubtitle;

  /// No description provided for @localGallery_naiOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only show NAI-generated images'**
  String get localGallery_naiOnlyTooltip;

  /// No description provided for @localGallery_naiVersionFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by NAI model version'**
  String get localGallery_naiVersionFilterTooltip;

  /// No description provided for @localGallery_masonryViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Waterfall'**
  String get localGallery_masonryViewLabel;

  /// No description provided for @localGallery_justifiedViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Justified'**
  String get localGallery_justifiedViewLabel;

  /// No description provided for @localGallery_dateRangeYearMonth.
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}'**
  String localGallery_dateRangeYearMonth(Object year, Object month);

  /// No description provided for @localGallery_dateRangePrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get localGallery_dateRangePrevMonth;

  /// No description provided for @localGallery_dateRangeNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get localGallery_dateRangeNextMonth;

  /// No description provided for @localGallery_dateRangeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get localGallery_dateRangeClear;

  /// No description provided for @localGallery_searchInScope.
  ///
  /// In en, this message translates to:
  /// **'Search: {scope}'**
  String localGallery_searchInScope(Object scope);

  /// No description provided for @localGallery_hideCategoryPanel.
  ///
  /// In en, this message translates to:
  /// **'Hide category panel'**
  String get localGallery_hideCategoryPanel;

  /// No description provided for @localGallery_showCategoryPanel.
  ///
  /// In en, this message translates to:
  /// **'Show category panel'**
  String get localGallery_showCategoryPanel;

  /// No description provided for @localGallery_refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh gallery\n\nAutomatically detects new or changed images and updates the index'**
  String get localGallery_refreshTooltip;

  /// No description provided for @localGallery_tagIntersection.
  ///
  /// In en, this message translates to:
  /// **'Tag Intersection'**
  String get localGallery_tagIntersection;

  /// No description provided for @localGallery_createCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get localGallery_createCategoryTitle;

  /// No description provided for @localGallery_newOrImport.
  ///
  /// In en, this message translates to:
  /// **'New / Import'**
  String get localGallery_newOrImport;

  /// No description provided for @localGallery_importFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Folder'**
  String get localGallery_importFolder;

  /// No description provided for @localGallery_createCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get localGallery_createCategoryHint;

  /// No description provided for @localGallery_createCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get localGallery_createCategoryConfirm;

  /// No description provided for @localGallery_createSubCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Subcategory'**
  String get localGallery_createSubCategoryTitle;

  /// No description provided for @localGallery_showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in Folder'**
  String get localGallery_showInFolder;

  /// No description provided for @localGallery_promptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied'**
  String get localGallery_promptCopied;

  /// No description provided for @localGallery_seedCopied.
  ///
  /// In en, this message translates to:
  /// **'Seed copied'**
  String get localGallery_seedCopied;

  /// No description provided for @localGallery_createCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get localGallery_createCollectionTitle;

  /// No description provided for @localGallery_createCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter collection name'**
  String get localGallery_createCollectionHint;

  /// No description provided for @localGallery_createCollectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get localGallery_createCollectionConfirm;

  /// No description provided for @localGallery_createCollectionFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Collection Folder'**
  String get localGallery_createCollectionFolderTitle;

  /// No description provided for @localGallery_createCollectionFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get localGallery_createCollectionFolderHint;

  /// No description provided for @localGallery_createCollectionFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get localGallery_createCollectionFolderConfirm;

  /// No description provided for @localGallery_deleteCollectionContent.
  ///
  /// In en, this message translates to:
  /// **'Delete collection \"{name}\"? Only the collection entry is removed; no image files are deleted.'**
  String localGallery_deleteCollectionContent(Object name);

  /// No description provided for @localGallery_deleteCollectionFolderContent.
  ///
  /// In en, this message translates to:
  /// **'Delete collection folder \"{name}\"? The folder is empty; only the folder itself is removed.'**
  String localGallery_deleteCollectionFolderContent(Object name);

  /// No description provided for @localGallery_deleteCollectionFolderNonEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder Not Empty'**
  String get localGallery_deleteCollectionFolderNonEmptyTitle;

  /// No description provided for @localGallery_deleteCollectionFolderNonEmptyContent.
  ///
  /// In en, this message translates to:
  /// **'Collection folder \"{name}\" still contains collections or subfolders. Move or delete its children first.'**
  String localGallery_deleteCollectionFolderNonEmptyContent(Object name);

  /// No description provided for @localGallery_unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get localGallery_unfavorite;

  /// No description provided for @localGallery_favoriteMenuEmptyCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections yet — create one with + on the left'**
  String get localGallery_favoriteMenuEmptyCollections;

  /// No description provided for @localGallery_confirmDeleteImageContent.
  ///
  /// In en, this message translates to:
  /// **'Delete image \"{name}\"?\n\nThe image will disappear from the gallery immediately; the file will be removed permanently on the next launch (can be undone in this session).'**
  String localGallery_confirmDeleteImageContent(Object name);

  /// No description provided for @localGallery_moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get localGallery_moveTo;

  /// No description provided for @localGallery_copyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get localGallery_copyTo;

  /// No description provided for @localGallery_externalSourceMoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Move External Gallery File'**
  String get localGallery_externalSourceMoveConfirmTitle;

  /// No description provided for @localGallery_externalSourceMoveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will move {count} image(s). Files will be removed from their source folder and will no longer remain in their original location. Continue?'**
  String localGallery_externalSourceMoveConfirmContent(Object count);

  /// No description provided for @localGallery_externalTargetMoveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will move {count} image(s) to the external gallery source category \"{targetName}\". Files will be written to the external source folder. Continue?'**
  String localGallery_externalTargetMoveConfirmContent(
    Object count,
    Object targetName,
  );

  /// No description provided for @localGallery_externalBothMoveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will move {count} image(s) to the external gallery source category \"{targetName}\". Files will be removed from the original external source folder (will not remain in the original location) and written to the external source folder. Continue?'**
  String localGallery_externalBothMoveConfirmContent(
    Object count,
    Object targetName,
  );

  /// No description provided for @localGallery_uncategorizedRoot.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized (Gallery Root)'**
  String get localGallery_uncategorizedRoot;

  /// No description provided for @localGallery_externalSourceChip.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get localGallery_externalSourceChip;

  /// No description provided for @localGallery_categoryFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories…'**
  String get localGallery_categoryFilterHint;

  /// No description provided for @localGallery_copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} image(s)'**
  String localGallery_copySuccess(Object count);

  /// No description provided for @localGallery_copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy image'**
  String get localGallery_copyFailed;

  /// No description provided for @localGallery_confirmCopyContent.
  ///
  /// In en, this message translates to:
  /// **'This will copy the image(s) to the target folder. Please confirm.'**
  String get localGallery_confirmCopyContent;

  /// No description provided for @localGallery_categoryDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Delete this category? The folder and its contents will be kept.'**
  String get localGallery_categoryDeleteContent;

  /// No description provided for @localGallery_protectedDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected Mode: Confirm Category Deletion'**
  String get localGallery_protectedDeleteCategoryTitle;

  /// No description provided for @localGallery_protectedDeleteCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete the category record. The folder and its contents will be kept. Confirm again.'**
  String get localGallery_protectedDeleteCategoryContent;

  /// No description provided for @localGallery_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get localGallery_confirmDelete;

  /// No description provided for @localGallery_confirmMoveImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected Mode: Confirm Image Move'**
  String get localGallery_confirmMoveImageTitle;

  /// No description provided for @localGallery_confirmMoveImageContent.
  ///
  /// In en, this message translates to:
  /// **'This will move the image to the target category folder. Confirm this was not an accidental drag.'**
  String get localGallery_confirmMoveImageContent;

  /// No description provided for @localGallery_confirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm Move'**
  String get localGallery_confirmMove;

  /// No description provided for @localGallery_imageMovedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Image moved to category'**
  String get localGallery_imageMovedToCategory;

  /// No description provided for @localGallery_categoriesSynced.
  ///
  /// In en, this message translates to:
  /// **'Categories synced with folders'**
  String get localGallery_categoriesSynced;

  /// No description provided for @localGallery_saveDirectoryNotSet.
  ///
  /// In en, this message translates to:
  /// **'Save directory is not set'**
  String get localGallery_saveDirectoryNotSet;

  /// No description provided for @localGallery_folderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get localGallery_folderNotFound;

  /// No description provided for @localGallery_openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String localGallery_openFolderFailed(Object error);

  /// No description provided for @localGallery_protectedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected Mode: Confirm Delete Again'**
  String get localGallery_protectedDeleteTitle;

  /// No description provided for @localGallery_protectedDeleteImagesContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {count} local image files. This cannot be undone.'**
  String localGallery_protectedDeleteImagesContent(Object count);

  /// No description provided for @localGallery_protectedBulkMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected Mode: Confirm Bulk Move'**
  String get localGallery_protectedBulkMoveTitle;

  /// No description provided for @localGallery_protectedBulkMoveContent.
  ///
  /// In en, this message translates to:
  /// **'This will move {count} local image files to the target folder. Confirm this is not a mistake.'**
  String localGallery_protectedBulkMoveContent(Object count);

  /// No description provided for @localGallery_importParamsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import parameters: {error}'**
  String localGallery_importParamsFailed(Object error);

  /// No description provided for @localGallery_protectedDeleteImageContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete image \"{name}\". This cannot be undone.'**
  String localGallery_protectedDeleteImageContent(Object name);

  /// No description provided for @localGallery_saveZipArchive.
  ///
  /// In en, this message translates to:
  /// **'Save ZIP Archive'**
  String get localGallery_saveZipArchive;

  /// No description provided for @localGallery_packingImages.
  ///
  /// In en, this message translates to:
  /// **'Packing {count} images...'**
  String localGallery_packingImages(Object count);

  /// No description provided for @localGallery_packedImages.
  ///
  /// In en, this message translates to:
  /// **'Packed {count} images'**
  String localGallery_packedImages(Object count);

  /// No description provided for @localGallery_packFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pack images'**
  String get localGallery_packFailed;

  /// No description provided for @localGallery_imageFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Image file does not exist'**
  String get localGallery_imageFileMissing;

  /// No description provided for @localGallery_sentToImageToImage.
  ///
  /// In en, this message translates to:
  /// **'Image sent to Image2Image'**
  String get localGallery_sentToImageToImage;

  /// No description provided for @localGallery_sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String localGallery_sendFailed(Object error);

  /// No description provided for @localGallery_sendToKritaFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send to Krita: {error}'**
  String localGallery_sendToKritaFailed(Object error);

  /// No description provided for @localGallery_sendToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Send to Image2Image'**
  String get localGallery_sendToImg2Img;

  /// No description provided for @localGallery_sendToStyleTransfer.
  ///
  /// In en, this message translates to:
  /// **'Send to Vibe Transfer'**
  String get localGallery_sendToStyleTransfer;

  /// No description provided for @localGallery_sendToPreciseReference.
  ///
  /// In en, this message translates to:
  /// **'Send to Precise Reference'**
  String get localGallery_sendToPreciseReference;

  /// No description provided for @localGallery_sendToKrita.
  ///
  /// In en, this message translates to:
  /// **'Send to Krita'**
  String get localGallery_sendToKrita;

  /// No description provided for @localGallery_importImageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Import Image Metadata'**
  String get localGallery_importImageMetadata;

  /// No description provided for @localGallery_copyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get localGallery_copyPrompt;

  /// No description provided for @localGallery_copySeed.
  ///
  /// In en, this message translates to:
  /// **'Copy Seed'**
  String get localGallery_copySeed;

  /// No description provided for @localGallery_dragToShare.
  ///
  /// In en, this message translates to:
  /// **'Drag to share'**
  String get localGallery_dragToShare;

  /// No description provided for @galleryDragCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String galleryDragCount(int count);

  /// No description provided for @localGallery_moveToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to Root'**
  String get localGallery_moveToRoot;

  /// No description provided for @localGallery_withMetadata.
  ///
  /// In en, this message translates to:
  /// **'With Metadata'**
  String get localGallery_withMetadata;

  /// No description provided for @localGallery_skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get localGallery_skipped;

  /// No description provided for @localGallery_clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get localGallery_clearFilters;

  /// No description provided for @slideshow_of.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get slideshow_of;

  /// No description provided for @slideshow_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get slideshow_play;

  /// No description provided for @slideshow_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get slideshow_pause;

  /// No description provided for @slideshow_previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get slideshow_previous;

  /// No description provided for @slideshow_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get slideshow_next;

  /// No description provided for @slideshow_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit (Esc)'**
  String get slideshow_exit;

  /// No description provided for @slideshow_noImages.
  ///
  /// In en, this message translates to:
  /// **'No images to display'**
  String get slideshow_noImages;

  /// No description provided for @slideshow_keyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Use ← → to navigate, Space to play/pause, Esc to exit'**
  String get slideshow_keyboardHint;

  /// No description provided for @comparison_noImages.
  ///
  /// In en, this message translates to:
  /// **'No images to display'**
  String get comparison_noImages;

  /// No description provided for @comparison_tooManyImages.
  ///
  /// In en, this message translates to:
  /// **'Too many images'**
  String get comparison_tooManyImages;

  /// No description provided for @comparison_maxImages.
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 images allowed for comparison'**
  String get comparison_maxImages;

  /// No description provided for @comparison_close.
  ///
  /// In en, this message translates to:
  /// **'Close comparison'**
  String get comparison_close;

  /// No description provided for @comparison_zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch or scroll to zoom independently'**
  String get comparison_zoomHint;

  /// No description provided for @comparison_loadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get comparison_loadError;

  /// No description provided for @statistics_title.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics_title;

  /// No description provided for @statistics_noData.
  ///
  /// In en, this message translates to:
  /// **'No statistics available'**
  String get statistics_noData;

  /// No description provided for @statistics_noTagData.
  ///
  /// In en, this message translates to:
  /// **'No tag data'**
  String get statistics_noTagData;

  /// No description provided for @statistics_generateFirst.
  ///
  /// In en, this message translates to:
  /// **'Generate some images first'**
  String get statistics_generateFirst;

  /// No description provided for @statistics_totalImages.
  ///
  /// In en, this message translates to:
  /// **'Total Images'**
  String get statistics_totalImages;

  /// No description provided for @statistics_totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get statistics_totalSize;

  /// No description provided for @statistics_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get statistics_favorites;

  /// No description provided for @statistics_samplerDistribution.
  ///
  /// In en, this message translates to:
  /// **'Sampler Distribution'**
  String get statistics_samplerDistribution;

  /// No description provided for @statistics_additionalStats.
  ///
  /// In en, this message translates to:
  /// **'Additional Statistics'**
  String get statistics_additionalStats;

  /// No description provided for @statistics_averageFileSize.
  ///
  /// In en, this message translates to:
  /// **'Average File Size'**
  String get statistics_averageFileSize;

  /// No description provided for @statistics_withMetadata.
  ///
  /// In en, this message translates to:
  /// **'Images with Metadata'**
  String get statistics_withMetadata;

  /// No description provided for @statistics_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get statistics_justNow;

  /// No description provided for @statistics_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String statistics_minutesAgo(Object count);

  /// No description provided for @statistics_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String statistics_hoursAgo(Object count);

  /// No description provided for @statistics_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String statistics_daysAgo(Object count);

  /// No description provided for @statistics_anlasCost.
  ///
  /// In en, this message translates to:
  /// **'Anlas Cost'**
  String get statistics_anlasCost;

  /// No description provided for @statistics_totalAnlasCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get statistics_totalAnlasCost;

  /// No description provided for @statistics_avgDailyCost.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get statistics_avgDailyCost;

  /// No description provided for @statistics_noAnlasData.
  ///
  /// In en, this message translates to:
  /// **'No Anlas consumption data'**
  String get statistics_noAnlasData;

  /// No description provided for @statistics_peakActivity.
  ///
  /// In en, this message translates to:
  /// **'Peak Activity'**
  String get statistics_peakActivity;

  /// No description provided for @statistics_timeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get statistics_timeMorning;

  /// No description provided for @statistics_timeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get statistics_timeAfternoon;

  /// No description provided for @statistics_timeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get statistics_timeEvening;

  /// No description provided for @statistics_timeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get statistics_timeNight;

  /// No description provided for @localGallery_group_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get localGallery_group_today;

  /// No description provided for @localGallery_group_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get localGallery_group_yesterday;

  /// No description provided for @localGallery_groupImageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{formatted} image} other{{formatted} images}}'**
  String localGallery_groupImageCount(int count, String formatted);

  /// No description provided for @localGallery_imageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{formatted} image} other{{formatted} images}}'**
  String localGallery_imageCountLabel(int count, String formatted);

  /// No description provided for @localGallery_selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get localGallery_selectGroup;

  /// No description provided for @localGallery_inspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get localGallery_inspectorTitle;

  /// No description provided for @localGallery_inspectorPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String localGallery_inspectorPosition(String index, String total);

  /// No description provided for @localGallery_inspectorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select an image to see its details'**
  String get localGallery_inspectorEmpty;

  /// No description provided for @localGallery_inspectorEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click or press Space to view it full size'**
  String get localGallery_inspectorEmptyHint;

  /// No description provided for @localGallery_hideInspector.
  ///
  /// In en, this message translates to:
  /// **'Hide details panel'**
  String get localGallery_hideInspector;

  /// No description provided for @localGallery_showInspector.
  ///
  /// In en, this message translates to:
  /// **'Show details panel'**
  String get localGallery_showInspector;

  /// No description provided for @localGallery_reuseParams.
  ///
  /// In en, this message translates to:
  /// **'Reuse parameters'**
  String get localGallery_reuseParams;

  /// No description provided for @localGallery_actionImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Image2Image'**
  String get localGallery_actionImg2Img;

  /// No description provided for @localGallery_actionStyleTransfer.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer'**
  String get localGallery_actionStyleTransfer;

  /// No description provided for @localGallery_actionPreciseReference.
  ///
  /// In en, this message translates to:
  /// **'Precise Ref.'**
  String get localGallery_actionPreciseReference;

  /// No description provided for @localGallery_actionSaveReference.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get localGallery_actionSaveReference;

  /// No description provided for @localGallery_actionKrita.
  ///
  /// In en, this message translates to:
  /// **'Krita'**
  String get localGallery_actionKrita;

  /// No description provided for @localGallery_selectedImages.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String localGallery_selectedImages(String count);

  /// No description provided for @localGallery_sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get localGallery_sortDescending;

  /// No description provided for @localGallery_sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get localGallery_sortAscending;

  /// No description provided for @localGallery_moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get localGallery_moreActions;

  /// No description provided for @localGallery_thumbnailSize.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail size'**
  String get localGallery_thumbnailSize;

  /// No description provided for @localGallery_naiOnlyChip.
  ///
  /// In en, this message translates to:
  /// **'NAI images only'**
  String get localGallery_naiOnlyChip;

  /// No description provided for @localGallery_modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get localGallery_modelLabel;

  /// No description provided for @localGallery_allVersions.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get localGallery_allVersions;

  /// No description provided for @localGallery_allVariants.
  ///
  /// In en, this message translates to:
  /// **'All variants'**
  String get localGallery_allVariants;

  /// No description provided for @localGallery_dateRangeChip.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get localGallery_dateRangeChip;

  /// No description provided for @localGallery_groupByDay.
  ///
  /// In en, this message translates to:
  /// **'Group by day'**
  String get localGallery_groupByDay;

  /// No description provided for @localGallery_groupByMonth.
  ///
  /// In en, this message translates to:
  /// **'Group by month'**
  String get localGallery_groupByMonth;

  /// No description provided for @localGallery_groupNone.
  ///
  /// In en, this message translates to:
  /// **'No grouping'**
  String get localGallery_groupNone;

  /// No description provided for @localGallery_groupModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Group by time'**
  String get localGallery_groupModeTooltip;

  /// No description provided for @localGallery_sectionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get localGallery_sectionLibrary;

  /// No description provided for @localGallery_sectionCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get localGallery_sectionCollections;

  /// No description provided for @localGallery_sectionFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get localGallery_sectionFolders;

  /// No description provided for @localGallery_dateFolders.
  ///
  /// In en, this message translates to:
  /// **'Dated folders'**
  String get localGallery_dateFolders;

  /// No description provided for @localGallery_indexSynced.
  ///
  /// In en, this message translates to:
  /// **'Index up to date · {count}'**
  String localGallery_indexSynced(String count);

  /// No description provided for @localGallery_cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open folder: {error}'**
  String localGallery_cannotOpenFolder(Object error);

  /// No description provided for @localGallery_firstTimeTipTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips'**
  String get localGallery_firstTimeTipTitle;

  /// No description provided for @localGallery_firstTimeTipContent.
  ///
  /// In en, this message translates to:
  /// **'Right-click (desktop) or long-press (mobile) on images to:\n\n• Copy Prompt\n• Copy Seed\n• View full metadata'**
  String get localGallery_firstTimeTipContent;

  /// No description provided for @localGallery_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get localGallery_gotIt;

  /// No description provided for @localGallery_undone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get localGallery_undone;

  /// No description provided for @localGallery_redone.
  ///
  /// In en, this message translates to:
  /// **'Redone'**
  String get localGallery_redone;

  /// No description provided for @localGallery_confirmBulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Bulk Delete'**
  String get localGallery_confirmBulkDelete;

  /// No description provided for @localGallery_confirmBulkDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected images?\n\nThey will disappear from the gallery immediately; the files will be removed permanently on the next launch (can be undone in this session).'**
  String localGallery_confirmBulkDeleteContent(Object count);

  /// No description provided for @localGallery_deletedToPool.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} images. They will be removed permanently on the next launch.'**
  String localGallery_deletedToPool(Object count);

  /// No description provided for @localGallery_trashTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get localGallery_trashTitle;

  /// No description provided for @localGallery_trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get localGallery_trashEmpty;

  /// No description provided for @localGallery_trashHint.
  ///
  /// In en, this message translates to:
  /// **'Files in the trash are still on disk and will be removed permanently on the next launch. Restored files return to the gallery immediately.'**
  String get localGallery_trashHint;

  /// No description provided for @localGallery_trashCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String localGallery_trashCount(Object count);

  /// No description provided for @localGallery_trashRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get localGallery_trashRestore;

  /// No description provided for @localGallery_trashRestoreAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get localGallery_trashRestoreAll;

  /// No description provided for @localGallery_trashRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore'**
  String get localGallery_trashRestoreFailed;

  /// No description provided for @localGallery_trashRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} images'**
  String localGallery_trashRestored(Object count);

  /// No description provided for @localGallery_trashDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get localGallery_trashDeleteAll;

  /// No description provided for @localGallery_trashDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} files in the trash immediately. This cannot be undone.'**
  String localGallery_trashDeleteAllConfirm(Object count);

  /// No description provided for @localGallery_trashDeletedForever.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted {count} files'**
  String localGallery_trashDeletedForever(Object count);

  /// No description provided for @localGallery_trashFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File no longer on disk'**
  String get localGallery_trashFileMissing;

  /// No description provided for @localGallery_movedImages.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} images'**
  String localGallery_movedImages(Object count);

  /// No description provided for @localGallery_moveImagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move images'**
  String get localGallery_moveImagesFailed;

  /// No description provided for @localGallery_addedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Added {count} images to collection \"{name}\"'**
  String localGallery_addedToCollection(Object count, Object name);

  /// No description provided for @localGallery_addToCollectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add images to collection'**
  String get localGallery_addToCollectionFailed;

  /// No description provided for @localGallery_removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from Collection'**
  String get localGallery_removeFromCollection;

  /// No description provided for @localGallery_removedFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} images from collection \"{name}\"'**
  String localGallery_removedFromCollection(Object count, Object name);

  /// No description provided for @localGallery_notInCollection.
  ///
  /// In en, this message translates to:
  /// **'Selected images are not in this collection'**
  String get localGallery_notInCollection;

  /// No description provided for @localGallery_removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} images from Favorites'**
  String localGallery_removedFromFavorites(Object count);

  /// No description provided for @localGallery_alreadyInCollection.
  ///
  /// In en, this message translates to:
  /// **'Images already in this collection'**
  String get localGallery_alreadyInCollection;

  /// No description provided for @brushPreset_selectHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to select this brush preset'**
  String get brushPreset_selectHint;

  /// No description provided for @brushPreset_pencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get brushPreset_pencil;

  /// No description provided for @brushPreset_fine.
  ///
  /// In en, this message translates to:
  /// **'Fine Brush'**
  String get brushPreset_fine;

  /// No description provided for @brushPreset_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard Brush'**
  String get brushPreset_standard;

  /// No description provided for @brushPreset_soft.
  ///
  /// In en, this message translates to:
  /// **'Soft Brush'**
  String get brushPreset_soft;

  /// No description provided for @brushPreset_airbrush.
  ///
  /// In en, this message translates to:
  /// **'Airbrush'**
  String get brushPreset_airbrush;

  /// No description provided for @brushPreset_marker.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get brushPreset_marker;

  /// No description provided for @brushPreset_thick.
  ///
  /// In en, this message translates to:
  /// **'Thick Brush'**
  String get brushPreset_thick;

  /// No description provided for @brushPreset_smudge.
  ///
  /// In en, this message translates to:
  /// **'Smudge Brush'**
  String get brushPreset_smudge;

  /// No description provided for @bulkProgress_progress.
  ///
  /// In en, this message translates to:
  /// **'Processing {current} of {total}'**
  String bulkProgress_progress(Object current, Object total);

  /// No description provided for @bulkProgress_success.
  ///
  /// In en, this message translates to:
  /// **'{count} succeeded'**
  String bulkProgress_success(Object count);

  /// No description provided for @bulkProgress_failed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String bulkProgress_failed(Object count);

  /// No description provided for @bulkProgress_errors.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get bulkProgress_errors;

  /// No description provided for @bulkProgress_moreErrors.
  ///
  /// In en, this message translates to:
  /// **'...and {count} more errors'**
  String bulkProgress_moreErrors(Object count);

  /// No description provided for @bulkProgress_completed.
  ///
  /// In en, this message translates to:
  /// **'{count} items completed'**
  String bulkProgress_completed(Object count);

  /// No description provided for @bulkProgress_completedWithErrors.
  ///
  /// In en, this message translates to:
  /// **'{success} succeeded, {failed} failed'**
  String bulkProgress_completedWithErrors(Object success, Object failed);

  /// No description provided for @bulkProgress_title_delete.
  ///
  /// In en, this message translates to:
  /// **'Deleting Images'**
  String get bulkProgress_title_delete;

  /// No description provided for @bulkProgress_title_export.
  ///
  /// In en, this message translates to:
  /// **'Exporting Metadata'**
  String get bulkProgress_title_export;

  /// No description provided for @bulkProgress_title_metadataEdit.
  ///
  /// In en, this message translates to:
  /// **'Editing Metadata'**
  String get bulkProgress_title_metadataEdit;

  /// No description provided for @bulkProgress_title_addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Adding to Collection'**
  String get bulkProgress_title_addToCollection;

  /// No description provided for @bulkProgress_title_removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Removing from Collection'**
  String get bulkProgress_title_removeFromCollection;

  /// No description provided for @bulkProgress_title_toggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Updating Favorites'**
  String get bulkProgress_title_toggleFavorite;

  /// No description provided for @bulkProgress_title_default.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get bulkProgress_title_default;

  /// No description provided for @bulkProgress_errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete images: {error}'**
  String bulkProgress_errorDeleteFailed(String error);

  /// No description provided for @bulkProgress_errorNoImagesToExport.
  ///
  /// In en, this message translates to:
  /// **'No images to export'**
  String get bulkProgress_errorNoImagesToExport;

  /// No description provided for @bulkProgress_errorExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get bulkProgress_errorExportFailed;

  /// No description provided for @bulkProgress_errorExportFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String bulkProgress_errorExportFailedWithDetails(String error);

  /// No description provided for @bulkProgress_errorNoMetadataChanges.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one tag to add or remove'**
  String get bulkProgress_errorNoMetadataChanges;

  /// No description provided for @bulkProgress_errorMetadataEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit image metadata: {error}'**
  String bulkProgress_errorMetadataEditFailed(String error);

  /// No description provided for @bulkProgress_errorFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorites: {error}'**
  String bulkProgress_errorFavoriteFailed(String error);

  /// No description provided for @bulkProgress_errorNoImagesForCollection.
  ///
  /// In en, this message translates to:
  /// **'No images to add to the collection'**
  String get bulkProgress_errorNoImagesForCollection;

  /// No description provided for @bulkProgress_errorAddToCollectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add images to the collection: {error}'**
  String bulkProgress_errorAddToCollectionFailed(String error);

  /// No description provided for @bulkProgress_errorNothingToUndo.
  ///
  /// In en, this message translates to:
  /// **'There is no operation to undo'**
  String get bulkProgress_errorNothingToUndo;

  /// No description provided for @bulkProgress_errorUndoFailed.
  ///
  /// In en, this message translates to:
  /// **'Undo failed: {error}'**
  String bulkProgress_errorUndoFailed(String error);

  /// No description provided for @bulkProgress_errorNothingToRedo.
  ///
  /// In en, this message translates to:
  /// **'There is no operation to redo'**
  String get bulkProgress_errorNothingToRedo;

  /// No description provided for @bulkProgress_errorRedoFailed.
  ///
  /// In en, this message translates to:
  /// **'Redo failed: {error}'**
  String bulkProgress_errorRedoFailed(String error);

  /// No description provided for @collectionSelect_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Collection'**
  String get collectionSelect_dialogTitle;

  /// No description provided for @collectionSelect_removeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Collection'**
  String get collectionSelect_removeTitle;

  /// No description provided for @collectionSelect_memberCount.
  ///
  /// In en, this message translates to:
  /// **'{n} selected in this collection'**
  String collectionSelect_memberCount(Object n);

  /// No description provided for @collectionSelect_noSelectedInCollection.
  ///
  /// In en, this message translates to:
  /// **'No selected images in this collection'**
  String get collectionSelect_noSelectedInCollection;

  /// No description provided for @collectionSelect_memberCountInFavorites.
  ///
  /// In en, this message translates to:
  /// **'{n} selected in favorites'**
  String collectionSelect_memberCountInFavorites(Object n);

  /// No description provided for @collectionSelect_filterHint.
  ///
  /// In en, this message translates to:
  /// **'Search collections...'**
  String get collectionSelect_filterHint;

  /// No description provided for @collectionSelect_noCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections'**
  String get collectionSelect_noCollections;

  /// No description provided for @collectionSelect_createCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'Create a collection first'**
  String get collectionSelect_createCollectionHint;

  /// No description provided for @collectionSelect_noFilterResults.
  ///
  /// In en, this message translates to:
  /// **'No matching collections found'**
  String get collectionSelect_noFilterResults;

  /// No description provided for @collectionSelect_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String collectionSelect_imageCount(int count);

  /// No description provided for @statistics_chartAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio Distribution'**
  String get statistics_chartAspectRatio;

  /// No description provided for @statistics_chartActivityHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get statistics_chartActivityHeatmap;

  /// No description provided for @statistics_chartHourlyDistribution.
  ///
  /// In en, this message translates to:
  /// **'Hourly Distribution'**
  String get statistics_chartHourlyDistribution;

  /// No description provided for @statistics_chartWeekdayDistribution.
  ///
  /// In en, this message translates to:
  /// **'Weekday Distribution'**
  String get statistics_chartWeekdayDistribution;

  /// No description provided for @statistics_aspectSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get statistics_aspectSquare;

  /// No description provided for @statistics_aspectLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get statistics_aspectLandscape;

  /// No description provided for @statistics_aspectPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get statistics_aspectPortrait;

  /// No description provided for @statistics_aspectOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get statistics_aspectOther;

  /// No description provided for @statistics_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get statistics_refresh;

  /// No description provided for @statistics_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get statistics_retry;

  /// No description provided for @statistics_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String statistics_error(Object error);

  /// No description provided for @statistics_mostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Most Active Day'**
  String get statistics_mostActiveDay;

  /// No description provided for @statistics_leastActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Least Active Day'**
  String get statistics_leastActiveDay;

  /// No description provided for @statistics_sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get statistics_sunday;

  /// No description provided for @statistics_monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get statistics_monday;

  /// No description provided for @statistics_tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get statistics_tuesday;

  /// No description provided for @statistics_wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get statistics_wednesday;

  /// No description provided for @statistics_thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get statistics_thursday;

  /// No description provided for @statistics_friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get statistics_friday;

  /// No description provided for @statistics_saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get statistics_saturday;

  /// No description provided for @autocomplete_categoryCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get autocomplete_categoryCharacter;

  /// No description provided for @autocomplete_categoryCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get autocomplete_categoryCopyright;

  /// No description provided for @autocomplete_categoryArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get autocomplete_categoryArtist;

  /// No description provided for @autocomplete_categoryMeta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get autocomplete_categoryMeta;

  /// No description provided for @autocomplete_categoryContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get autocomplete_categoryContributor;

  /// No description provided for @autocomplete_categorySpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get autocomplete_categorySpecies;

  /// No description provided for @autocomplete_categoryLore.
  ///
  /// In en, this message translates to:
  /// **'Lore'**
  String get autocomplete_categoryLore;

  /// No description provided for @autocomplete_categoryLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get autocomplete_categoryLibrary;

  /// No description provided for @autocomplete_categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get autocomplete_categoryGeneral;

  /// No description provided for @promptToken_webCalibration.
  ///
  /// In en, this message translates to:
  /// **'Web calibration'**
  String get promptToken_webCalibration;

  /// No description provided for @promptToken_prompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get promptToken_prompt;

  /// No description provided for @promptToken_qualityPreset.
  ///
  /// In en, this message translates to:
  /// **'Quality Preset'**
  String get promptToken_qualityPreset;

  /// No description provided for @promptToken_character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get promptToken_character;

  /// No description provided for @promptToken_negativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get promptToken_negativePrompt;

  /// No description provided for @promptToken_negativePreset.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Preset'**
  String get promptToken_negativePreset;

  /// No description provided for @promptToken_characterNegative.
  ///
  /// In en, this message translates to:
  /// **'Character Undesired Content'**
  String get promptToken_characterNegative;

  /// No description provided for @common_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get common_rename;

  /// No description provided for @tagLibrary_newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get tagLibrary_newCategory;

  /// No description provided for @tagLibrary_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagLibrary_tags;

  /// No description provided for @settings_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settings_network;

  /// No description provided for @settings_enableProxy.
  ///
  /// In en, this message translates to:
  /// **'Enable Proxy'**
  String get settings_enableProxy;

  /// No description provided for @settings_proxyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settings_proxyEnabled;

  /// No description provided for @settings_proxyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Direct connection'**
  String get settings_proxyDisabled;

  /// No description provided for @settings_proxyTrafficDisclosure.
  ///
  /// In en, this message translates to:
  /// **'When proxy is enabled, NovelAI API traffic, including authentication requests, is sent through the system or manual proxy. Use only proxies you trust.'**
  String get settings_proxyTrafficDisclosure;

  /// No description provided for @settings_proxyMode.
  ///
  /// In en, this message translates to:
  /// **'Proxy Mode'**
  String get settings_proxyMode;

  /// No description provided for @settings_proxyModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect system proxy'**
  String get settings_proxyModeAuto;

  /// No description provided for @settings_proxyModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual configuration'**
  String get settings_proxyModeManual;

  /// No description provided for @settings_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settings_auto;

  /// No description provided for @settings_manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get settings_manual;

  /// No description provided for @settings_proxyHost.
  ///
  /// In en, this message translates to:
  /// **'Proxy Host'**
  String get settings_proxyHost;

  /// No description provided for @settings_proxyPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get settings_proxyPort;

  /// No description provided for @settings_proxyNotDetected.
  ///
  /// In en, this message translates to:
  /// **'No system proxy detected'**
  String get settings_proxyNotDetected;

  /// No description provided for @settings_testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settings_testConnection;

  /// No description provided for @settings_testConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Click to test if proxy is working'**
  String get settings_testConnectionHint;

  /// No description provided for @settings_testSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful ({latency}ms)'**
  String settings_testSuccess(Object latency);

  /// No description provided for @settings_testFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String settings_testFailed(Object error);

  /// No description provided for @settings_proxyRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Proxy settings changed, restart recommended'**
  String get settings_proxyRestartHint;

  /// No description provided for @tagLibrary_addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get tagLibrary_addToLibrary;

  /// No description provided for @tagLibrary_uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get tagLibrary_uncategorized;

  /// No description provided for @tagLibrary_contentPreview.
  ///
  /// In en, this message translates to:
  /// **'Content Preview'**
  String get tagLibrary_contentPreview;

  /// No description provided for @settings_enablePromptWeightScroll.
  ///
  /// In en, this message translates to:
  /// **'Adjust prompt weight with mouse wheel'**
  String get settings_enablePromptWeightScroll;

  /// No description provided for @settings_enablePromptWeightScrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When prompt text is selected, hold the chosen modifier + wheel to adjust weight; a bare wheel scrolls the page as usual.'**
  String get settings_enablePromptWeightScrollSubtitle;

  /// No description provided for @settings_weightScrollModifierAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get settings_weightScrollModifierAlt;

  /// No description provided for @settings_weightScrollModifierCtrl.
  ///
  /// In en, this message translates to:
  /// **'Ctrl'**
  String get settings_weightScrollModifierCtrl;

  /// No description provided for @settings_weightScrollModifierShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get settings_weightScrollModifierShift;

  /// No description provided for @settings_weightScrollModifierNone.
  ///
  /// In en, this message translates to:
  /// **'None (legacy)'**
  String get settings_weightScrollModifierNone;

  /// No description provided for @unit_seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get unit_seconds;

  /// No description provided for @settings_notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Completion Sound'**
  String get settings_notificationSound;

  /// No description provided for @settings_notificationSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play the completion sound only while the window is unfocused'**
  String get settings_notificationSoundSubtitle;

  /// No description provided for @settings_notificationCustomSound.
  ///
  /// In en, this message translates to:
  /// **'Custom Sound'**
  String get settings_notificationCustomSound;

  /// No description provided for @settings_notificationSelectSound.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get settings_notificationSelectSound;

  /// No description provided for @settings_notificationResetSound.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get settings_notificationResetSound;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @statistics_heatmapLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get statistics_heatmapLess;

  /// No description provided for @statistics_heatmapMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get statistics_heatmapMore;

  /// No description provided for @statistics_heatmapActivities.
  ///
  /// In en, this message translates to:
  /// **'{count} activities'**
  String statistics_heatmapActivities(Object count);

  /// No description provided for @statistics_heatmapNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get statistics_heatmapNoActivity;

  /// No description provided for @metadataImport_title.
  ///
  /// In en, this message translates to:
  /// **'Select Parameters to Import'**
  String get metadataImport_title;

  /// No description provided for @metadataImport_promptsSection.
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get metadataImport_promptsSection;

  /// No description provided for @metadataImport_generationSection.
  ///
  /// In en, this message translates to:
  /// **'Generation Parameters'**
  String get metadataImport_generationSection;

  /// No description provided for @metadataImport_selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get metadataImport_selectAll;

  /// No description provided for @metadataImport_promptsOnly.
  ///
  /// In en, this message translates to:
  /// **'Prompts Only'**
  String get metadataImport_promptsOnly;

  /// No description provided for @metadataImport_generationOnly.
  ///
  /// In en, this message translates to:
  /// **'Parameters Only'**
  String get metadataImport_generationOnly;

  /// No description provided for @metadataImport_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get metadataImport_clear;

  /// No description provided for @metadataImport_prompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get metadataImport_prompt;

  /// No description provided for @metadataImport_mainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Main Prompt'**
  String get metadataImport_mainPrompt;

  /// No description provided for @metadataImport_qualityTagsCount.
  ///
  /// In en, this message translates to:
  /// **'Quality Tags ({count})'**
  String metadataImport_qualityTagsCount(int count);

  /// No description provided for @metadataImport_negativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get metadataImport_negativePrompt;

  /// No description provided for @metadataImport_characterPrompts.
  ///
  /// In en, this message translates to:
  /// **'Character Prompts'**
  String get metadataImport_characterPrompts;

  /// No description provided for @metadataImport_characterPromptsCount.
  ///
  /// In en, this message translates to:
  /// **'Character Prompts ({count})'**
  String metadataImport_characterPromptsCount(int count);

  /// No description provided for @metadataImport_characterIndex.
  ///
  /// In en, this message translates to:
  /// **'Character {index}: {text}'**
  String metadataImport_characterIndex(int index, Object text);

  /// No description provided for @metadataImport_referenceSection.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get metadataImport_referenceSection;

  /// No description provided for @metadataImport_countUnit.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String metadataImport_countUnit(int count);

  /// No description provided for @metadataImport_preciseReferenceCount.
  ///
  /// In en, this message translates to:
  /// **'Precise Reference ({count})'**
  String metadataImport_preciseReferenceCount(int count);

  /// No description provided for @metadataImport_vibeDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} (Reference Strength {strength}%, Information Extracted {info}%)'**
  String metadataImport_vibeDetail(Object name, Object strength, Object info);

  /// No description provided for @metadataImport_preciseReferenceDetail.
  ///
  /// In en, this message translates to:
  /// **'Reference {index}: {type} (strength {strength}%, fidelity {fidelity}%)'**
  String metadataImport_preciseReferenceDetail(
    int index,
    Object type,
    Object strength,
    Object fidelity,
  );

  /// No description provided for @metadataImport_seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get metadataImport_seed;

  /// No description provided for @metadataImport_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get metadataImport_steps;

  /// No description provided for @metadataImport_scale.
  ///
  /// In en, this message translates to:
  /// **'Prompt Guidance'**
  String get metadataImport_scale;

  /// No description provided for @metadataImport_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get metadataImport_size;

  /// No description provided for @metadataImport_sampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get metadataImport_sampler;

  /// No description provided for @metadataImport_model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get metadataImport_model;

  /// No description provided for @metadataImport_smea.
  ///
  /// In en, this message translates to:
  /// **'SMEA'**
  String get metadataImport_smea;

  /// No description provided for @metadataImport_smeaDyn.
  ///
  /// In en, this message translates to:
  /// **'SMEA Dyn'**
  String get metadataImport_smeaDyn;

  /// No description provided for @metadataImport_noiseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Noise Schedule'**
  String get metadataImport_noiseSchedule;

  /// No description provided for @metadataImport_cfgRescale.
  ///
  /// In en, this message translates to:
  /// **'Prompt Guidance Rescale'**
  String get metadataImport_cfgRescale;

  /// No description provided for @metadataImport_qualityToggle.
  ///
  /// In en, this message translates to:
  /// **'Quality Toggle'**
  String get metadataImport_qualityToggle;

  /// No description provided for @metadataImport_ucPreset.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Preset'**
  String get metadataImport_ucPreset;

  /// No description provided for @metadataImport_noData.
  ///
  /// In en, this message translates to:
  /// **'(no data)'**
  String get metadataImport_noData;

  /// No description provided for @metadataImport_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String metadataImport_selectedCount(int count);

  /// No description provided for @metadataImport_noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No NovelAI metadata found'**
  String get metadataImport_noDataFound;

  /// No description provided for @metadataImport_appliedCount.
  ///
  /// In en, this message translates to:
  /// **'Applied {count} parameters'**
  String metadataImport_appliedCount(int count);

  /// No description provided for @metadataImport_appliedTitle.
  ///
  /// In en, this message translates to:
  /// **'Metadata Applied'**
  String get metadataImport_appliedTitle;

  /// No description provided for @metadataImport_appliedDescription.
  ///
  /// In en, this message translates to:
  /// **'The following parameters have been applied:'**
  String get metadataImport_appliedDescription;

  /// No description provided for @metadataImport_charactersCount.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get metadataImport_charactersCount;

  /// No description provided for @shortcut_context_global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get shortcut_context_global;

  /// No description provided for @shortcut_context_generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get shortcut_context_generation;

  /// No description provided for @shortcut_context_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery List'**
  String get shortcut_context_gallery;

  /// No description provided for @shortcut_context_viewer.
  ///
  /// In en, this message translates to:
  /// **'Image Viewer'**
  String get shortcut_context_viewer;

  /// No description provided for @shortcut_context_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shortcut_context_settings;

  /// No description provided for @shortcut_context_input.
  ///
  /// In en, this message translates to:
  /// **'Input Field'**
  String get shortcut_context_input;

  /// No description provided for @shortcut_action_navigate_to_generation.
  ///
  /// In en, this message translates to:
  /// **'Generation Page'**
  String get shortcut_action_navigate_to_generation;

  /// No description provided for @shortcut_action_navigate_to_local_gallery.
  ///
  /// In en, this message translates to:
  /// **'Local Gallery'**
  String get shortcut_action_navigate_to_local_gallery;

  /// No description provided for @shortcut_action_navigate_to_online_gallery.
  ///
  /// In en, this message translates to:
  /// **'Online Gallery'**
  String get shortcut_action_navigate_to_online_gallery;

  /// No description provided for @shortcut_action_navigate_to_tag_library.
  ///
  /// In en, this message translates to:
  /// **'Prompt Block Library'**
  String get shortcut_action_navigate_to_tag_library;

  /// No description provided for @shortcut_action_navigate_to_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get shortcut_action_navigate_to_statistics;

  /// No description provided for @shortcut_action_navigate_to_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shortcut_action_navigate_to_settings;

  /// No description provided for @shortcut_action_generate_image.
  ///
  /// In en, this message translates to:
  /// **'Generate Image'**
  String get shortcut_action_generate_image;

  /// No description provided for @shortcut_action_generation_prev_image.
  ///
  /// In en, this message translates to:
  /// **'Previous preview (linked history)'**
  String get shortcut_action_generation_prev_image;

  /// No description provided for @shortcut_action_generation_next_image.
  ///
  /// In en, this message translates to:
  /// **'Next preview (linked history)'**
  String get shortcut_action_generation_next_image;

  /// No description provided for @shortcut_action_cancel_generation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Generation'**
  String get shortcut_action_cancel_generation;

  /// No description provided for @shortcut_action_clear_prompt.
  ///
  /// In en, this message translates to:
  /// **'Clear Prompt'**
  String get shortcut_action_clear_prompt;

  /// No description provided for @shortcut_action_toggle_prompt_mode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Prompt Mode'**
  String get shortcut_action_toggle_prompt_mode;

  /// No description provided for @shortcut_action_open_tag_library.
  ///
  /// In en, this message translates to:
  /// **'Open Prompt Block Library'**
  String get shortcut_action_open_tag_library;

  /// No description provided for @shortcut_action_save_image.
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get shortcut_action_save_image;

  /// No description provided for @shortcut_action_upscale_image.
  ///
  /// In en, this message translates to:
  /// **'Upscale Image'**
  String get shortcut_action_upscale_image;

  /// No description provided for @shortcut_action_copy_image.
  ///
  /// In en, this message translates to:
  /// **'Copy Image'**
  String get shortcut_action_copy_image;

  /// No description provided for @shortcut_action_fullscreen_preview.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Preview'**
  String get shortcut_action_fullscreen_preview;

  /// No description provided for @shortcut_action_open_params_panel.
  ///
  /// In en, this message translates to:
  /// **'Open Params Panel'**
  String get shortcut_action_open_params_panel;

  /// No description provided for @shortcut_action_open_history_panel.
  ///
  /// In en, this message translates to:
  /// **'Open History Panel'**
  String get shortcut_action_open_history_panel;

  /// No description provided for @shortcut_action_reuse_params.
  ///
  /// In en, this message translates to:
  /// **'Reuse Parameters'**
  String get shortcut_action_reuse_params;

  /// No description provided for @shortcut_action_previous_image.
  ///
  /// In en, this message translates to:
  /// **'Previous Image'**
  String get shortcut_action_previous_image;

  /// No description provided for @shortcut_action_next_image.
  ///
  /// In en, this message translates to:
  /// **'Next Image'**
  String get shortcut_action_next_image;

  /// No description provided for @shortcut_action_zoom_in.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get shortcut_action_zoom_in;

  /// No description provided for @shortcut_action_zoom_out.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get shortcut_action_zoom_out;

  /// No description provided for @shortcut_action_reset_zoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get shortcut_action_reset_zoom;

  /// No description provided for @shortcut_action_toggle_fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle Fullscreen'**
  String get shortcut_action_toggle_fullscreen;

  /// No description provided for @shortcut_action_close_viewer.
  ///
  /// In en, this message translates to:
  /// **'Close Viewer'**
  String get shortcut_action_close_viewer;

  /// No description provided for @shortcut_action_toggle_favorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle Favorite'**
  String get shortcut_action_toggle_favorite;

  /// No description provided for @shortcut_action_copy_prompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get shortcut_action_copy_prompt;

  /// No description provided for @shortcut_action_reuse_gallery_params.
  ///
  /// In en, this message translates to:
  /// **'Reuse Parameters'**
  String get shortcut_action_reuse_gallery_params;

  /// No description provided for @shortcut_action_delete_image.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get shortcut_action_delete_image;

  /// No description provided for @shortcut_action_previous_page.
  ///
  /// In en, this message translates to:
  /// **'Scroll Up One Screen'**
  String get shortcut_action_previous_page;

  /// No description provided for @shortcut_action_next_page.
  ///
  /// In en, this message translates to:
  /// **'Scroll Down One Screen'**
  String get shortcut_action_next_page;

  /// No description provided for @shortcut_action_refresh_gallery.
  ///
  /// In en, this message translates to:
  /// **'Refresh Gallery'**
  String get shortcut_action_refresh_gallery;

  /// No description provided for @shortcut_action_focus_search.
  ///
  /// In en, this message translates to:
  /// **'Focus Search'**
  String get shortcut_action_focus_search;

  /// No description provided for @shortcut_action_enter_selection_mode.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get shortcut_action_enter_selection_mode;

  /// No description provided for @shortcut_action_clear_filter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get shortcut_action_clear_filter;

  /// No description provided for @shortcut_action_toggle_category_panel.
  ///
  /// In en, this message translates to:
  /// **'Toggle Category Panel'**
  String get shortcut_action_toggle_category_panel;

  /// No description provided for @shortcut_action_jump_to_date.
  ///
  /// In en, this message translates to:
  /// **'Jump to Date'**
  String get shortcut_action_jump_to_date;

  /// No description provided for @shortcut_action_open_folder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get shortcut_action_open_folder;

  /// No description provided for @shortcut_action_minimize_to_tray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get shortcut_action_minimize_to_tray;

  /// No description provided for @shortcut_action_quit_app.
  ///
  /// In en, this message translates to:
  /// **'Quit Application'**
  String get shortcut_action_quit_app;

  /// No description provided for @shortcut_action_show_shortcut_help.
  ///
  /// In en, this message translates to:
  /// **'Show Shortcut Help'**
  String get shortcut_action_show_shortcut_help;

  /// No description provided for @shortcut_action_toggle_theme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get shortcut_action_toggle_theme;

  /// No description provided for @shortcut_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcut_settings_title;

  /// No description provided for @shortcut_settings_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable Shortcuts'**
  String get shortcut_settings_enable;

  /// No description provided for @shortcut_settings_show_badges.
  ///
  /// In en, this message translates to:
  /// **'Show Shortcut Badges'**
  String get shortcut_settings_show_badges;

  /// No description provided for @shortcut_settings_show_in_tooltips.
  ///
  /// In en, this message translates to:
  /// **'Show in Tooltips'**
  String get shortcut_settings_show_in_tooltips;

  /// No description provided for @shortcut_settings_reset_all.
  ///
  /// In en, this message translates to:
  /// **'Reset All to Default'**
  String get shortcut_settings_reset_all;

  /// No description provided for @shortcut_settings_search.
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts...'**
  String get shortcut_settings_search;

  /// No description provided for @shortcut_settings_press_key.
  ///
  /// In en, this message translates to:
  /// **'Press key combination...'**
  String get shortcut_settings_press_key;

  /// No description provided for @shortcut_help_title.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts Help'**
  String get shortcut_help_title;

  /// No description provided for @shortcut_help_search.
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts...'**
  String get shortcut_help_search;

  /// No description provided for @shortcut_help_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shortcut_help_all;

  /// No description provided for @shortcut_help_fabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts Help (F1)'**
  String get shortcut_help_fabTooltip;

  /// No description provided for @shortcut_editor_recordingInline.
  ///
  /// In en, this message translates to:
  /// **'Press shortcut...'**
  String get shortcut_editor_recordingInline;

  /// No description provided for @shortcut_editor_pressEscToCancel.
  ///
  /// In en, this message translates to:
  /// **'Press Esc to cancel'**
  String get shortcut_editor_pressEscToCancel;

  /// No description provided for @shortcut_editor_clickToRecord.
  ///
  /// In en, this message translates to:
  /// **'Click to start recording'**
  String get shortcut_editor_clickToRecord;

  /// No description provided for @shortcut_editor_conflictWith.
  ///
  /// In en, this message translates to:
  /// **'This shortcut conflicts with \"{action}\"'**
  String shortcut_editor_conflictWith(Object action);

  /// No description provided for @drop_hint.
  ///
  /// In en, this message translates to:
  /// **'Drop image here'**
  String get drop_hint;

  /// No description provided for @drop_img2img.
  ///
  /// In en, this message translates to:
  /// **'Image2Image'**
  String get drop_img2img;

  /// No description provided for @drop_vibeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Vibe Transfer'**
  String get drop_vibeTransfer;

  /// No description provided for @drop_characterReference.
  ///
  /// In en, this message translates to:
  /// **'Precise Reference'**
  String get drop_characterReference;

  /// No description provided for @drop_unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format'**
  String get drop_unsupportedFormat;

  /// No description provided for @drop_addedToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Added to Image2Image'**
  String get drop_addedToImg2Img;

  /// No description provided for @drop_addedToVibe.
  ///
  /// In en, this message translates to:
  /// **'Added to Vibe Transfer'**
  String get drop_addedToVibe;

  /// No description provided for @drop_addedMultipleToVibe.
  ///
  /// In en, this message translates to:
  /// **'Added {count} vibe references'**
  String drop_addedMultipleToVibe(int count);

  /// No description provided for @drop_addedToCharacterRef.
  ///
  /// In en, this message translates to:
  /// **'Added to Precise Reference'**
  String get drop_addedToCharacterRef;

  /// No description provided for @drop_vibeDetected.
  ///
  /// In en, this message translates to:
  /// **'Pre-encoded Vibe detected (saves 2 Anlas)'**
  String get drop_vibeDetected;

  /// No description provided for @drop_reuseVibe.
  ///
  /// In en, this message translates to:
  /// **'Reuse Vibe'**
  String get drop_reuseVibe;

  /// No description provided for @drop_useAsRawImage.
  ///
  /// In en, this message translates to:
  /// **'Use as Raw Image'**
  String get drop_useAsRawImage;

  /// No description provided for @drop_dragToImg2ImgOrOther.
  ///
  /// In en, this message translates to:
  /// **'Drag to Image2Image or another target'**
  String get drop_dragToImg2ImgOrOther;

  /// No description provided for @preciseRef_title.
  ///
  /// In en, this message translates to:
  /// **'Precise Reference'**
  String get preciseRef_title;

  /// No description provided for @preciseRef_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tie generation to a character or style reference'**
  String get preciseRef_subtitle;

  /// No description provided for @preciseRef_description.
  ///
  /// In en, this message translates to:
  /// **'Add reference images and set type and parameters. Multiple references can be used simultaneously.'**
  String get preciseRef_description;

  /// No description provided for @preciseRef_addReference.
  ///
  /// In en, this message translates to:
  /// **'Add Reference'**
  String get preciseRef_addReference;

  /// No description provided for @preciseRef_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get preciseRef_clearAll;

  /// No description provided for @preciseRef_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get preciseRef_remove;

  /// No description provided for @preciseRef_referenceType.
  ///
  /// In en, this message translates to:
  /// **'Reference Type'**
  String get preciseRef_referenceType;

  /// No description provided for @preciseRef_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get preciseRef_strength;

  /// No description provided for @preciseRef_fidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get preciseRef_fidelity;

  /// No description provided for @preciseRef_v4Only.
  ///
  /// In en, this message translates to:
  /// **'This feature requires V4+ models'**
  String get preciseRef_v4Only;

  /// No description provided for @preciseRef_typeCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get preciseRef_typeCharacter;

  /// No description provided for @preciseRef_typeStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get preciseRef_typeStyle;

  /// No description provided for @preciseRef_typeCharacterAndStyle.
  ///
  /// In en, this message translates to:
  /// **'Character + Style'**
  String get preciseRef_typeCharacterAndStyle;

  /// No description provided for @preciseRef_costHint.
  ///
  /// In en, this message translates to:
  /// **'Using Precise Reference consumes extra Anlas'**
  String get preciseRef_costHint;

  /// No description provided for @preciseRef_costBadge.
  ///
  /// In en, this message translates to:
  /// **'Uses Anlas'**
  String get preciseRef_costBadge;

  /// No description provided for @preciseRef_dropToAdd.
  ///
  /// In en, this message translates to:
  /// **'Release to add precise reference'**
  String get preciseRef_dropToAdd;

  /// No description provided for @preciseRef_dropNoReadableImage.
  ///
  /// In en, this message translates to:
  /// **'The drop source did not provide a readable image file or image link'**
  String get preciseRef_dropNoReadableImage;

  /// No description provided for @preciseRef_addedCount.
  ///
  /// In en, this message translates to:
  /// **'Added {count} precise references'**
  String preciseRef_addedCount(int count);

  /// No description provided for @preciseRef_removedCount.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} precise references'**
  String preciseRef_removedCount(int count);

  /// No description provided for @vibeLibrary_title.
  ///
  /// In en, this message translates to:
  /// **'Vibe Library'**
  String get vibeLibrary_title;

  /// No description provided for @vibeLibrary_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get vibeLibrary_categories;

  /// No description provided for @vibeLibrary_createCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get vibeLibrary_createCategoryTitle;

  /// No description provided for @vibeLibrary_createSubCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Subcategory'**
  String get vibeLibrary_createSubCategoryTitle;

  /// No description provided for @vibeLibrary_categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get vibeLibrary_categoryNameHint;

  /// No description provided for @vibeLibrary_createCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get vibeLibrary_createCategoryConfirm;

  /// No description provided for @vibeLibrary_deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get vibeLibrary_deleteCategoryTitle;

  /// No description provided for @vibeLibrary_deleteCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'Delete this category? Vibes in it will be moved to Uncategorized.'**
  String get vibeLibrary_deleteCategoryContent;

  /// No description provided for @vibeLibrary_sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get vibeLibrary_sortTooltip;

  /// No description provided for @vibeLibrary_openFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Vibe library folder'**
  String get vibeLibrary_openFolderTooltip;

  /// No description provided for @vibeLibrary_totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Vibes'**
  String vibeLibrary_totalCount(Object count);

  /// No description provided for @vibeLibrary_noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get vibeLibrary_noCategoriesAvailable;

  /// No description provided for @vibeLibrary_moveToCategory.
  ///
  /// In en, this message translates to:
  /// **'Move to Category'**
  String get vibeLibrary_moveToCategory;

  /// No description provided for @vibeLibrary_uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get vibeLibrary_uncategorized;

  /// No description provided for @vibeLibrary_movedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} Vibes'**
  String vibeLibrary_movedToCategory(Object count);

  /// No description provided for @vibeLibrary_favoriteStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Favorite status updated'**
  String get vibeLibrary_favoriteStatusUpdated;

  /// No description provided for @vibeLibrary_importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get vibeLibrary_importFromFile;

  /// No description provided for @vibeLibrary_importFromImage.
  ///
  /// In en, this message translates to:
  /// **'Import from Image'**
  String get vibeLibrary_importFromImage;

  /// No description provided for @vibeLibrary_importFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Import Encoded Data from Clipboard'**
  String get vibeLibrary_importFromClipboard;

  /// No description provided for @vibeLibrary_openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String vibeLibrary_openFolderFailed(Object error);

  /// No description provided for @vibeLibrary_importFileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Vibe files to import'**
  String get vibeLibrary_importFileDialogTitle;

  /// No description provided for @vibeLibrary_preparingImport.
  ///
  /// In en, this message translates to:
  /// **'Preparing import...'**
  String get vibeLibrary_preparingImport;

  /// No description provided for @vibeLibrary_importSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} Vibes'**
  String vibeLibrary_importSuccessCount(Object count);

  /// No description provided for @vibeLibrary_importSummary.
  ///
  /// In en, this message translates to:
  /// **'Import complete: {success} succeeded, {failed} failed'**
  String vibeLibrary_importSummary(Object success, Object failed);

  /// No description provided for @vibeLibrary_dropImportHint.
  ///
  /// In en, this message translates to:
  /// **'Drop .naiv4vibe/.naiv4vibebundle/.png/.jpg/.jpeg/.webp files or folders here to import'**
  String get vibeLibrary_dropImportHint;

  /// No description provided for @vibeLibrary_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get vibeLibrary_importing;

  /// No description provided for @vibeLibrary_pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} pages'**
  String vibeLibrary_pageIndicator(Object current, Object total);

  /// No description provided for @vibeLibrary_itemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Per page:'**
  String get vibeLibrary_itemsPerPage;

  /// No description provided for @vibeLibrary_tooManyTitle.
  ///
  /// In en, this message translates to:
  /// **'Too Many Vibes'**
  String get vibeLibrary_tooManyTitle;

  /// No description provided for @vibeLibrary_tooManySelectedContent.
  ///
  /// In en, this message translates to:
  /// **'Selected {count} Vibes, but at most 16 can be used at once.\n\nPlease reduce the selection and try again.'**
  String vibeLibrary_tooManySelectedContent(Object count);

  /// No description provided for @vibeLibrary_tooManyExistingContent.
  ///
  /// In en, this message translates to:
  /// **'The generation page already has {current} Vibes. You can add {remaining} more.\n\nPlease reduce the selection and try again.'**
  String vibeLibrary_tooManyExistingContent(Object current, Object remaining);

  /// No description provided for @vibeLibrary_sentToGenerationCount.
  ///
  /// In en, this message translates to:
  /// **'Sent {count} Vibes to generation'**
  String vibeLibrary_sentToGenerationCount(Object count);

  /// No description provided for @vibeLibrary_deleteSelectedContent.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected Vibes? This action cannot be undone.'**
  String vibeLibrary_deleteSelectedContent(Object count);

  /// No description provided for @vibeLibrary_deletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} Vibes'**
  String vibeLibrary_deletedCount(Object count);

  /// No description provided for @vibeLibrary_importImageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select images containing Vibe data'**
  String get vibeLibrary_importImageDialogTitle;

  /// No description provided for @vibeLibrary_clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get vibeLibrary_clipboardEmpty;

  /// No description provided for @vibeLibrary_encodeTimeout.
  ///
  /// In en, this message translates to:
  /// **'Encoding timed out. Please check your network connection.'**
  String get vibeLibrary_encodeTimeout;

  /// No description provided for @vibeLibrary_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get vibeLibrary_unknownError;

  /// No description provided for @vibeLibrary_save.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get vibeLibrary_save;

  /// No description provided for @vibeLibrary_import.
  ///
  /// In en, this message translates to:
  /// **'Import Vibe'**
  String get vibeLibrary_import;

  /// No description provided for @vibeLibrary_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, tags...'**
  String get vibeLibrary_searchHint;

  /// No description provided for @vibeLibrary_empty.
  ///
  /// In en, this message translates to:
  /// **'Vibe Library is empty'**
  String get vibeLibrary_empty;

  /// No description provided for @vibeLibrary_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add some entries to Vibe Library first'**
  String get vibeLibrary_emptyHint;

  /// No description provided for @vibeLibrary_allVibes.
  ///
  /// In en, this message translates to:
  /// **'All Vibes'**
  String get vibeLibrary_allVibes;

  /// No description provided for @vibeLibrary_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get vibeLibrary_favorites;

  /// No description provided for @vibeLibrary_sendToGeneration.
  ///
  /// In en, this message translates to:
  /// **'Send to Generation'**
  String get vibeLibrary_sendToGeneration;

  /// No description provided for @vibeLibrary_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get vibeLibrary_export;

  /// No description provided for @vibeLibrary_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get vibeLibrary_edit;

  /// No description provided for @vibeLibrary_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vibeLibrary_delete;

  /// No description provided for @vibeLibrary_addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get vibeLibrary_addToFavorites;

  /// No description provided for @vibeLibrary_removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get vibeLibrary_removeFromFavorites;

  /// No description provided for @vibeLibrary_newSubCategory.
  ///
  /// In en, this message translates to:
  /// **'New Subcategory'**
  String get vibeLibrary_newSubCategory;

  /// No description provided for @vibeLibrary_maxVibesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum limit reached (16 vibes)'**
  String get vibeLibrary_maxVibesReached;

  /// No description provided for @vibeLibrary_bundleReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read bundle file, using single file mode'**
  String get vibeLibrary_bundleReadFailed;

  /// No description provided for @categoryError_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories: {error}'**
  String categoryError_loadFailed(String error);

  /// No description provided for @categoryError_syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync categories: {error}'**
  String categoryError_syncFailed(String error);

  /// No description provided for @categoryError_nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryError_nameEmpty;

  /// No description provided for @categoryError_parentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Parent category does not exist'**
  String get categoryError_parentNotFound;

  /// No description provided for @categoryError_createFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create category: {error}'**
  String categoryError_createFailed(String error);

  /// No description provided for @categoryError_notFound.
  ///
  /// In en, this message translates to:
  /// **'Category does not exist'**
  String get categoryError_notFound;

  /// No description provided for @categoryError_renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename category: {error}'**
  String categoryError_renameFailed(String error);

  /// No description provided for @categoryError_invalidMove.
  ///
  /// In en, this message translates to:
  /// **'A category cannot be moved under one of its descendants'**
  String get categoryError_invalidMove;

  /// No description provided for @categoryError_moveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move category: {error}'**
  String categoryError_moveFailed(String error);

  /// No description provided for @categoryError_hasSubcategories.
  ///
  /// In en, this message translates to:
  /// **'This category contains subcategories. Delete them first.'**
  String get categoryError_hasSubcategories;

  /// No description provided for @categoryError_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category: {error}'**
  String categoryError_deleteFailed(String error);

  /// No description provided for @categoryError_moveImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move image: {error}'**
  String categoryError_moveImageFailed(String error);

  /// No description provided for @categoryError_moveImagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move images: {error}'**
  String categoryError_moveImagesFailed(String error);

  /// No description provided for @categoryError_reorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder categories: {error}'**
  String categoryError_reorderFailed(String error);

  /// No description provided for @vibeBulkTag_actionPreview.
  ///
  /// In en, this message translates to:
  /// **'Change preview'**
  String get vibeBulkTag_actionPreview;

  /// No description provided for @vibeDetail_strengthDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls how strongly this Vibe influences generated results'**
  String get vibeDetail_strengthDescription;

  /// No description provided for @vibeDetail_infoExtractedDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls how much information is extracted from the source image (costs 2 Anlas)'**
  String get vibeDetail_infoExtractedDescription;

  /// No description provided for @vibeDetail_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get vibeDetail_statistics;

  /// No description provided for @vibeDetail_usageCount.
  ///
  /// In en, this message translates to:
  /// **'Times used'**
  String get vibeDetail_usageCount;

  /// No description provided for @vibeDetail_timesUsed.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String vibeDetail_timesUsed(int count);

  /// No description provided for @vibeDetail_lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get vibeDetail_lastUsed;

  /// No description provided for @vibeDetail_neverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never used'**
  String get vibeDetail_neverUsed;

  /// No description provided for @vibeDetail_createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get vibeDetail_createdAt;

  /// No description provided for @vibeDetail_saveParameters.
  ///
  /// In en, this message translates to:
  /// **'Save Parameters'**
  String get vibeDetail_saveParameters;

  /// No description provided for @vibe_export_title.
  ///
  /// In en, this message translates to:
  /// **'Export Vibe'**
  String get vibe_export_title;

  /// No description provided for @vibe_export_format.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get vibe_export_format;

  /// No description provided for @vibe_selector_title.
  ///
  /// In en, this message translates to:
  /// **'Select Vibe'**
  String get vibe_selector_title;

  /// No description provided for @vibe_selector_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get vibe_selector_recent;

  /// No description provided for @vibe_export_include_thumbnails.
  ///
  /// In en, this message translates to:
  /// **'Include Thumbnails'**
  String get vibe_export_include_thumbnails;

  /// No description provided for @vibe_export_include_thumbnails_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Include thumbnail preview in export file'**
  String get vibe_export_include_thumbnails_subtitle;

  /// No description provided for @vibe_export_singleFile.
  ///
  /// In en, this message translates to:
  /// **'Single file (.naiv4vibe)'**
  String get vibe_export_singleFile;

  /// No description provided for @vibe_export_singleFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Export each Vibe as a separate file, suitable for sharing one Vibe'**
  String get vibe_export_singleFileDescription;

  /// No description provided for @vibe_export_bundleFile.
  ///
  /// In en, this message translates to:
  /// **'Bundle file (.naiv4vibebundle)'**
  String get vibe_export_bundleFile;

  /// No description provided for @vibe_export_bundleFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Pack multiple Vibes into one file, suitable for batch backup'**
  String get vibe_export_bundleFileDescription;

  /// No description provided for @vibe_export_embedIntoPng.
  ///
  /// In en, this message translates to:
  /// **'Embed into PNG'**
  String get vibe_export_embedIntoPng;

  /// No description provided for @vibe_export_embedIntoPngDescription.
  ///
  /// In en, this message translates to:
  /// **'Export a single Vibe by embedding its data into PNG metadata'**
  String get vibe_export_embedIntoPngDescription;

  /// No description provided for @vibe_export_exportable.
  ///
  /// In en, this message translates to:
  /// **'Exportable'**
  String get vibe_export_exportable;

  /// No description provided for @vibe_export_notExportable.
  ///
  /// In en, this message translates to:
  /// **'Not exportable'**
  String get vibe_export_notExportable;

  /// No description provided for @vibe_export_selectVibesToExport.
  ///
  /// In en, this message translates to:
  /// **'Select Vibes to export'**
  String get vibe_export_selectVibesToExport;

  /// No description provided for @vibe_export_exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export ({count})'**
  String vibe_export_exportSelected(int count);

  /// No description provided for @vibe_export_strengthPercent.
  ///
  /// In en, this message translates to:
  /// **'Strength: {percent}%'**
  String vibe_export_strengthPercent(int percent);

  /// No description provided for @vibe_export_pngCarrierImage.
  ///
  /// In en, this message translates to:
  /// **'PNG carrier image'**
  String get vibe_export_pngCarrierImage;

  /// No description provided for @vibe_export_noUsablePngCarrier.
  ///
  /// In en, this message translates to:
  /// **'This Vibe has no directly usable PNG carrier image. You can choose an external PNG image as the carrier.'**
  String get vibe_export_noUsablePngCarrier;

  /// No description provided for @vibe_export_selectExternalPngImage.
  ///
  /// In en, this message translates to:
  /// **'Select external PNG image...'**
  String get vibe_export_selectExternalPngImage;

  /// No description provided for @vibe_export_changeExternalPngImage.
  ///
  /// In en, this message translates to:
  /// **'Change external PNG image...'**
  String get vibe_export_changeExternalPngImage;

  /// No description provided for @vibe_export_useVibeImageInstead.
  ///
  /// In en, this message translates to:
  /// **'Use Vibe image instead'**
  String get vibe_export_useVibeImageInstead;

  /// No description provided for @vibe_export_usingExternalPng.
  ///
  /// In en, this message translates to:
  /// **'Using external PNG: {fileName}'**
  String vibe_export_usingExternalPng(String fileName);

  /// No description provided for @vibe_export_selectPngImage.
  ///
  /// In en, this message translates to:
  /// **'Select PNG image'**
  String get vibe_export_selectPngImage;

  /// No description provided for @vibe_export_invalidPngImage.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid PNG image'**
  String get vibe_export_invalidPngImage;

  /// No description provided for @vibe_export_selectPngImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select PNG image: {error}'**
  String vibe_export_selectPngImageFailed(String error);

  /// No description provided for @vibe_export_embeddingPng.
  ///
  /// In en, this message translates to:
  /// **'Embedding PNG: {name}'**
  String vibe_export_embeddingPng(String name);

  /// No description provided for @vibe_export_exportCompleteCounts.
  ///
  /// In en, this message translates to:
  /// **'Export complete: {successCount} succeeded, {failCount} failed'**
  String vibe_export_exportCompleteCounts(int successCount, int failCount);

  /// No description provided for @vibe_export_exportCompletePath.
  ///
  /// In en, this message translates to:
  /// **'Export complete: {path}'**
  String vibe_export_exportCompletePath(String path);

  /// No description provided for @vibe_export_packingVibes.
  ///
  /// In en, this message translates to:
  /// **'Packing {count} Vibes...'**
  String vibe_export_packingVibes(int count);

  /// No description provided for @vibe_export_exportingName.
  ///
  /// In en, this message translates to:
  /// **'Exporting: {name}'**
  String vibe_export_exportingName(String name);

  /// No description provided for @vibe_export_selectExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Select export folder'**
  String get vibe_export_selectExportFolder;

  /// No description provided for @vibe_export_generatingBundleFile.
  ///
  /// In en, this message translates to:
  /// **'Generating bundle file...'**
  String get vibe_export_generatingBundleFile;

  /// No description provided for @vibe_export_bundleTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Bundle: {name}'**
  String vibe_export_bundleTitle(String name);

  /// No description provided for @vibe_export_vibesTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Vibes ({count} selected)'**
  String vibe_export_vibesTitle(int count);

  /// No description provided for @vibe_export_method.
  ///
  /// In en, this message translates to:
  /// **'Export Method'**
  String get vibe_export_method;

  /// No description provided for @vibe_export_wholeBundle.
  ///
  /// In en, this message translates to:
  /// **'Whole Bundle'**
  String get vibe_export_wholeBundle;

  /// No description provided for @vibe_export_internalVibe.
  ///
  /// In en, this message translates to:
  /// **'Internal Vibe'**
  String get vibe_export_internalVibe;

  /// No description provided for @vibe_export_wholeBundleDescription.
  ///
  /// In en, this message translates to:
  /// **'Export as a .naiv4vibebundle file containing all {count} vibes'**
  String vibe_export_wholeBundleDescription(int count);

  /// No description provided for @vibe_export_internalVibeDescription.
  ///
  /// In en, this message translates to:
  /// **'Select internal bundle vibes to export separately as .naiv4vibe files ({count} total)'**
  String vibe_export_internalVibeDescription(int count);

  /// No description provided for @vibe_export_exportBundle.
  ///
  /// In en, this message translates to:
  /// **'Export Bundle'**
  String get vibe_export_exportBundle;

  /// No description provided for @vibe_export_exportAsFiles.
  ///
  /// In en, this message translates to:
  /// **'Export as Files'**
  String get vibe_export_exportAsFiles;

  /// No description provided for @vibe_export_exportBundleDescription.
  ///
  /// In en, this message translates to:
  /// **'Export as a .naiv4vibebundle file'**
  String get vibe_export_exportBundleDescription;

  /// No description provided for @vibe_export_exportAsFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Export as .naiv4vibe or .naiv4vibebundle files'**
  String get vibe_export_exportAsFilesDescription;

  /// No description provided for @vibe_export_exportAsZip.
  ///
  /// In en, this message translates to:
  /// **'Export as ZIP'**
  String get vibe_export_exportAsZip;

  /// No description provided for @vibe_export_exportAsZipDescription.
  ///
  /// In en, this message translates to:
  /// **'Pack the selected Vibe library entries into a .zip as separate files'**
  String get vibe_export_exportAsZipDescription;

  /// No description provided for @vibe_export_compressData.
  ///
  /// In en, this message translates to:
  /// **'Compress data'**
  String get vibe_export_compressData;

  /// No description provided for @vibe_export_compressDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Use compression to reduce file size (recommended for batch export)'**
  String get vibe_export_compressDataDescription;

  /// No description provided for @vibe_export_zipCompressDescription.
  ///
  /// In en, this message translates to:
  /// **'Compress files inside the ZIP to reduce size'**
  String get vibe_export_zipCompressDescription;

  /// No description provided for @vibe_export_exportAsPng.
  ///
  /// In en, this message translates to:
  /// **'Export as PNG'**
  String get vibe_export_exportAsPng;

  /// No description provided for @vibe_export_pngInternalBundleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Embedding into an image is not supported when exporting a single internal bundle vibe'**
  String get vibe_export_pngInternalBundleUnsupported;

  /// No description provided for @vibe_export_embedVibeDataIntoPng.
  ///
  /// In en, this message translates to:
  /// **'Embed Vibe data into PNG metadata'**
  String get vibe_export_embedVibeDataIntoPng;

  /// No description provided for @vibe_export_batchPngUsesFirstImage.
  ///
  /// In en, this message translates to:
  /// **'Batch export uses each Vibe\'s first available image. Entries without images are skipped automatically.'**
  String get vibe_export_batchPngUsesFirstImage;

  /// No description provided for @vibe_export_exportCarrierImage.
  ///
  /// In en, this message translates to:
  /// **'Export carrier image'**
  String get vibe_export_exportCarrierImage;

  /// No description provided for @vibe_export_usingExternalCarrierImage.
  ///
  /// In en, this message translates to:
  /// **'Using an external PNG as the export carrier image'**
  String get vibe_export_usingExternalCarrierImage;

  /// No description provided for @vibe_export_exportAsEncodings.
  ///
  /// In en, this message translates to:
  /// **'Export as Encodings'**
  String get vibe_export_exportAsEncodings;

  /// No description provided for @vibe_export_exportAsEncodingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Export data as encodings (JSON or Base64)'**
  String get vibe_export_exportAsEncodingsDescription;

  /// No description provided for @vibe_export_jsonDescription.
  ///
  /// In en, this message translates to:
  /// **'Export as a formatted JSON file for easier reading and editing'**
  String get vibe_export_jsonDescription;

  /// No description provided for @vibe_export_base64Description.
  ///
  /// In en, this message translates to:
  /// **'Export as plain Base64 for copying and sharing'**
  String get vibe_export_base64Description;

  /// No description provided for @vibe_export_selectAtLeastOneMethod.
  ///
  /// In en, this message translates to:
  /// **'Select at least one export method'**
  String get vibe_export_selectAtLeastOneMethod;

  /// No description provided for @vibe_export_batchPngUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Batch Vibe export does not support embedding into PNG. Use the single Vibe export screen.'**
  String get vibe_export_batchPngUnsupported;

  /// No description provided for @vibe_export_selectPngCarrier.
  ///
  /// In en, this message translates to:
  /// **'Select a PNG carrier image for export'**
  String get vibe_export_selectPngCarrier;

  /// No description provided for @vibe_export_selectAtLeastOneInternalVibe.
  ///
  /// In en, this message translates to:
  /// **'Select at least one internal vibe to export'**
  String get vibe_export_selectAtLeastOneInternalVibe;

  /// No description provided for @vibe_export_selectVibeExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Vibe export folder'**
  String get vibe_export_selectVibeExportFolder;

  /// No description provided for @vibe_export_saveEncodingFile.
  ///
  /// In en, this message translates to:
  /// **'Save encoding file'**
  String get vibe_export_saveEncodingFile;

  /// No description provided for @vibe_export_preparingExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get vibe_export_preparingExport;

  /// No description provided for @vibe_export_preparingVibeProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading Vibe {current}/{total}...'**
  String vibe_export_preparingVibeProgress(int current, int total);

  /// No description provided for @vibe_export_exportingBundle.
  ///
  /// In en, this message translates to:
  /// **'Exporting Bundle...'**
  String get vibe_export_exportingBundle;

  /// No description provided for @vibe_export_exportingZip.
  ///
  /// In en, this message translates to:
  /// **'Exporting ZIP...'**
  String get vibe_export_exportingZip;

  /// No description provided for @vibe_export_embeddingImage.
  ///
  /// In en, this message translates to:
  /// **'Embedding image...'**
  String get vibe_export_embeddingImage;

  /// No description provided for @vibe_export_exportingEncoding.
  ///
  /// In en, this message translates to:
  /// **'Exporting encoding...'**
  String get vibe_export_exportingEncoding;

  /// No description provided for @vibe_export_exportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String vibe_export_exportFailedWithError(String error);

  /// No description provided for @vibe_export_noExportableEntries.
  ///
  /// In en, this message translates to:
  /// **'No exportable Vibe entries'**
  String get vibe_export_noExportableEntries;

  /// No description provided for @vibe_export_bundleFilePathEmpty.
  ///
  /// In en, this message translates to:
  /// **'Bundle file path is empty'**
  String get vibe_export_bundleFilePathEmpty;

  /// No description provided for @vibe_export_invalidImageFormatWithError.
  ///
  /// In en, this message translates to:
  /// **'Invalid image format: {error}'**
  String vibe_export_invalidImageFormatWithError(String error);

  /// No description provided for @vibe_export_embedFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Embed failed: {error}'**
  String vibe_export_embedFailedWithError(String error);

  /// No description provided for @vibe_export_embedImageFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to embed image: {error}'**
  String vibe_export_embedImageFailedWithError(String error);

  /// No description provided for @vibe_export_extractingVibeProgress.
  ///
  /// In en, this message translates to:
  /// **'Extracting vibe {current}/{total}...'**
  String vibe_export_extractingVibeProgress(int current, int total);

  /// No description provided for @vibe_export_selectImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image: {error}'**
  String vibe_export_selectImageFailed(String error);

  /// No description provided for @vibe_export_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {count} Vibes'**
  String vibe_export_dialogTitle(int count);

  /// No description provided for @vibe_export_chooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how to export the vibes'**
  String get vibe_export_chooseMethod;

  /// No description provided for @vibe_export_asBundle.
  ///
  /// In en, this message translates to:
  /// **'As Bundle'**
  String get vibe_export_asBundle;

  /// No description provided for @vibe_export_individually.
  ///
  /// In en, this message translates to:
  /// **'Individually'**
  String get vibe_export_individually;

  /// No description provided for @vibe_export_noData.
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get vibe_export_noData;

  /// No description provided for @vibe_export_success.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get vibe_export_success;

  /// No description provided for @vibe_export_failed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get vibe_export_failed;

  /// No description provided for @vibe_export_skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} vibes without data'**
  String vibe_export_skipped(int count);

  /// No description provided for @vibe_export_bundleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bundle exported: {count} vibes'**
  String vibe_export_bundleSuccess(int count);

  /// No description provided for @vibe_export_selectToEmbed.
  ///
  /// In en, this message translates to:
  /// **'Select vibes to embed'**
  String get vibe_export_selectToEmbed;

  /// No description provided for @vibe_export_pngRequired.
  ///
  /// In en, this message translates to:
  /// **'PNG file required'**
  String get vibe_export_pngRequired;

  /// No description provided for @vibe_export_noEmbeddableData.
  ///
  /// In en, this message translates to:
  /// **'No embeddable data'**
  String get vibe_export_noEmbeddableData;

  /// No description provided for @vibe_export_embedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Embedded {count} vibes into image'**
  String vibe_export_embedSuccess(int count);

  /// No description provided for @vibe_export_embedFailed.
  ///
  /// In en, this message translates to:
  /// **'Embed failed'**
  String get vibe_export_embedFailed;

  /// No description provided for @vibe_embedToImage.
  ///
  /// In en, this message translates to:
  /// **'Embed to Image'**
  String get vibe_embedToImage;

  /// No description provided for @vibe_import_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get vibe_import_skip;

  /// No description provided for @vibe_import_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get vibe_import_confirm;

  /// No description provided for @vibe_import_noEncodingData.
  ///
  /// In en, this message translates to:
  /// **'No encoding data'**
  String get vibe_import_noEncodingData;

  /// No description provided for @vibe_import_encodingCost.
  ///
  /// In en, this message translates to:
  /// **'Encoding will cost 2 Anlas'**
  String get vibe_import_encodingCost;

  /// No description provided for @vibe_import_confirmCost.
  ///
  /// In en, this message translates to:
  /// **'Continue and consume Anlas?'**
  String get vibe_import_confirmCost;

  /// No description provided for @vibe_import_encodeNow.
  ///
  /// In en, this message translates to:
  /// **'Encode immediately (2 Anlas)'**
  String get vibe_import_encodeNow;

  /// No description provided for @vibe_addImageOnly.
  ///
  /// In en, this message translates to:
  /// **'Add image only'**
  String get vibe_addImageOnly;

  /// No description provided for @vibe_import_autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto-save to library'**
  String get vibe_import_autoSave;

  /// No description provided for @vibe_import_encodingFailed.
  ///
  /// In en, this message translates to:
  /// **'Encoding failed'**
  String get vibe_import_encodingFailed;

  /// No description provided for @vibe_import_encodingFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to encode vibe. Continue adding unencoded image?'**
  String get vibe_import_encodingFailedMessage;

  /// No description provided for @vibe_import_encodingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Encoding...'**
  String get vibe_import_encodingInProgress;

  /// No description provided for @vibe_import_encodingComplete.
  ///
  /// In en, this message translates to:
  /// **'Encoding complete'**
  String get vibe_import_encodingComplete;

  /// No description provided for @vibe_import_partialFailed.
  ///
  /// In en, this message translates to:
  /// **'Partial encoding failed'**
  String get vibe_import_partialFailed;

  /// No description provided for @vibe_import_timeout.
  ///
  /// In en, this message translates to:
  /// **'Encoding timeout'**
  String get vibe_import_timeout;

  /// No description provided for @vibe_import_title.
  ///
  /// In en, this message translates to:
  /// **'Import from Library'**
  String get vibe_import_title;

  /// No description provided for @vibe_import_result.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} vibes'**
  String vibe_import_result(int count);

  /// No description provided for @vibe_import_fileParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse file'**
  String get vibe_import_fileParseFailed;

  /// No description provided for @vibe_import_fileSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'File selection failed'**
  String get vibe_import_fileSelectionFailed;

  /// No description provided for @vibe_import_importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get vibe_import_importFailed;

  /// No description provided for @vibe_import_bundleTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Vibe Bundle'**
  String get vibe_import_bundleTitle;

  /// No description provided for @vibe_import_bundleChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose import method'**
  String get vibe_import_bundleChooseMethod;

  /// No description provided for @vibe_import_bundleAsWhole.
  ///
  /// In en, this message translates to:
  /// **'Import as whole'**
  String get vibe_import_bundleAsWhole;

  /// No description provided for @vibe_import_bundleAsWholeDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep the bundle structure and import it as one library entry'**
  String get vibe_import_bundleAsWholeDescription;

  /// No description provided for @vibe_import_bundleSplitEntries.
  ///
  /// In en, this message translates to:
  /// **'Split into separate entries'**
  String get vibe_import_bundleSplitEntries;

  /// No description provided for @vibe_import_bundleSplitEntriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Import each vibe as a separate library entry'**
  String get vibe_import_bundleSplitEntriesDescription;

  /// No description provided for @vibe_import_bundleSelectVibes.
  ///
  /// In en, this message translates to:
  /// **'Select vibes to import'**
  String get vibe_import_bundleSelectVibes;

  /// No description provided for @vibe_import_bundleSelectVibesDescription.
  ///
  /// In en, this message translates to:
  /// **'Import only the selected vibes'**
  String get vibe_import_bundleSelectVibesDescription;

  /// No description provided for @vibe_import_bundleConfigureEachVibe.
  ///
  /// In en, this message translates to:
  /// **'Configure each Vibe\'s parameters'**
  String get vibe_import_bundleConfigureEachVibe;

  /// No description provided for @vibe_import_bundleSelectAndConfigureEachVibe.
  ///
  /// In en, this message translates to:
  /// **'Select and configure each Vibe\'s parameters'**
  String get vibe_import_bundleSelectAndConfigureEachVibe;

  /// No description provided for @vibe_import_bundleSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{total} selected'**
  String vibe_import_bundleSelectedCount(int selected, int total);

  /// No description provided for @vibe_saveToLibrary_title.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get vibe_saveToLibrary_title;

  /// No description provided for @vibe_saveToLibrary_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get vibe_saveToLibrary_strength;

  /// No description provided for @vibe_saveToLibrary_infoExtracted.
  ///
  /// In en, this message translates to:
  /// **'Information Extracted'**
  String get vibe_saveToLibrary_infoExtracted;

  /// No description provided for @vibe_saveToLibrary_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving {count} vibes'**
  String vibe_saveToLibrary_saving(int count);

  /// No description provided for @vibe_saveToLibrary_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save to library'**
  String get vibe_saveToLibrary_saveFailed;

  /// No description provided for @vibe_saveToLibrary_savingCount.
  ///
  /// In en, this message translates to:
  /// **'Saving {count} vibes'**
  String vibe_saveToLibrary_savingCount(int count);

  /// No description provided for @vibe_saveToLibrary_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vibe_saveToLibrary_nameLabel;

  /// No description provided for @vibe_saveToLibrary_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter vibe name'**
  String get vibe_saveToLibrary_nameHint;

  /// No description provided for @vibe_saveToLibrary_mixed.
  ///
  /// In en, this message translates to:
  /// **'Saved {saved}, reused {reused}'**
  String vibe_saveToLibrary_mixed(int saved, int reused);

  /// No description provided for @vibe_saveToLibrary_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} to library'**
  String vibe_saveToLibrary_saved(int count);

  /// No description provided for @vibe_saveToLibrary_reused.
  ///
  /// In en, this message translates to:
  /// **'Reused {count} from library'**
  String vibe_saveToLibrary_reused(int count);

  /// No description provided for @vibe_saveToLibrary_saveAsBundle.
  ///
  /// In en, this message translates to:
  /// **'Save as bundle'**
  String get vibe_saveToLibrary_saveAsBundle;

  /// No description provided for @vibe_saveToLibrary_saveAsBundleDescription.
  ///
  /// In en, this message translates to:
  /// **'Save {count} Vibes as one bundle'**
  String vibe_saveToLibrary_saveAsBundleDescription(int count);

  /// No description provided for @vibe_saveToLibrary_tagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag, then press Add'**
  String get vibe_saveToLibrary_tagHint;

  /// No description provided for @vibe_maxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 16 vibes reached'**
  String get vibe_maxReached;

  /// No description provided for @vibe_addedCount.
  ///
  /// In en, this message translates to:
  /// **'Added {count} vibes'**
  String vibe_addedCount(int count);

  /// No description provided for @vibe_statusEncoded.
  ///
  /// In en, this message translates to:
  /// **'Encoded'**
  String get vibe_statusEncoded;

  /// No description provided for @vibe_statusEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding...'**
  String get vibe_statusEncoding;

  /// No description provided for @vibe_statusPendingEncode.
  ///
  /// In en, this message translates to:
  /// **'Encode (2 Anlas)'**
  String get vibe_statusPendingEncode;

  /// No description provided for @vibe_encodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Vibe Encoding'**
  String get vibe_encodeDialogTitle;

  /// No description provided for @vibe_encodeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Encode this image for generation?'**
  String get vibe_encodeDialogMessage;

  /// No description provided for @vibe_encodeCostWarning.
  ///
  /// In en, this message translates to:
  /// **'This will cost 2 Anlas (credits)'**
  String get vibe_encodeCostWarning;

  /// No description provided for @vibe_encodeButton.
  ///
  /// In en, this message translates to:
  /// **'Encode'**
  String get vibe_encodeButton;

  /// No description provided for @vibe_encodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vibe encoded successfully!'**
  String get vibe_encodeSuccess;

  /// No description provided for @vibe_encodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Vibe encoding failed, please retry'**
  String get vibe_encodeFailed;

  /// No description provided for @vibe_encodeError.
  ///
  /// In en, this message translates to:
  /// **'Encoding failed: {error}'**
  String vibe_encodeError(String error);

  /// No description provided for @shortcuts_customize.
  ///
  /// In en, this message translates to:
  /// **'Customize Shortcuts'**
  String get shortcuts_customize;

  /// No description provided for @selection_clear_selection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get selection_clear_selection;

  /// No description provided for @selection_invert_selection.
  ///
  /// In en, this message translates to:
  /// **'Invert Selection'**
  String get selection_invert_selection;

  /// No description provided for @selection_cut_to_layer.
  ///
  /// In en, this message translates to:
  /// **'Cut to Layer'**
  String get selection_cut_to_layer;

  /// No description provided for @search_results.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get search_results;

  /// No description provided for @search_noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get search_noResults;

  /// No description provided for @addToCurrent.
  ///
  /// In en, this message translates to:
  /// **'Add to Current'**
  String get addToCurrent;

  /// No description provided for @replaceExisting.
  ///
  /// In en, this message translates to:
  /// **'Replace Existing'**
  String get replaceExisting;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @shortcut_context_vibe_detail.
  ///
  /// In en, this message translates to:
  /// **'Vibe Detail'**
  String get shortcut_context_vibe_detail;

  /// No description provided for @shortcut_action_vibe_detail_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get shortcut_action_vibe_detail_rename;

  /// No description provided for @vibeSelectorFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get vibeSelectorFilterFavorites;

  /// No description provided for @vibeSelectorFilterSourceAll.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get vibeSelectorFilterSourceAll;

  /// No description provided for @vibeSelectorSortCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get vibeSelectorSortCreated;

  /// No description provided for @vibeSelectorSortLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last Used'**
  String get vibeSelectorSortLastUsed;

  /// No description provided for @vibeSelectorSortUsedCount.
  ///
  /// In en, this message translates to:
  /// **'Usage Count'**
  String get vibeSelectorSortUsedCount;

  /// No description provided for @vibeSelectorSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vibeSelectorSortName;

  /// No description provided for @vibeSelectorItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String vibeSelectorItemsCount(int count);

  /// No description provided for @tray_show.
  ///
  /// In en, this message translates to:
  /// **'Show Window'**
  String get tray_show;

  /// No description provided for @tray_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get tray_exit;

  /// No description provided for @settings_shortcutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize keyboard shortcuts'**
  String get settings_shortcutsSubtitle;

  /// No description provided for @settings_openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get settings_openFolder;

  /// No description provided for @settings_openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder'**
  String get settings_openFolderFailed;

  /// No description provided for @settings_vibePathSaved.
  ///
  /// In en, this message translates to:
  /// **'Vibe library path saved'**
  String get settings_vibePathSaved;

  /// No description provided for @settings_selectFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select folder'**
  String get settings_selectFolderFailed;

  /// No description provided for @settings_hivePathSaved.
  ///
  /// In en, this message translates to:
  /// **'Data storage path saved, effective after restart'**
  String get settings_hivePathSaved;

  /// No description provided for @settings_restartRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Required'**
  String get settings_restartRequiredTitle;

  /// No description provided for @settings_changePathConfirm.
  ///
  /// In en, this message translates to:
  /// **'After changing the data storage path, the app needs to restart to take effect.\\n\\nThe new path will take effect on the next startup. Continue?'**
  String get settings_changePathConfirm;

  /// No description provided for @settings_resetPathConfirm.
  ///
  /// In en, this message translates to:
  /// **'After resetting the data storage path, the app needs to restart to take effect.\\n\\nThe default path will take effect on the next startup. Continue?'**
  String get settings_resetPathConfirm;

  /// No description provided for @settings_kritaBridgeEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable local bridge'**
  String get settings_kritaBridgeEnable;

  /// No description provided for @settings_kritaBridgeDisabledText.
  ///
  /// In en, this message translates to:
  /// **'Off by default; listens only on local 127.0.0.1 when enabled'**
  String get settings_kritaBridgeDisabledText;

  /// No description provided for @settings_kritaBridgeStartingText.
  ///
  /// In en, this message translates to:
  /// **'Starting local bridge service...'**
  String get settings_kritaBridgeStartingText;

  /// No description provided for @settings_kritaBridgeListeningText.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an external Agent or Krita'**
  String get settings_kritaBridgeListeningText;

  /// No description provided for @settings_kritaBridgeConnectedText.
  ///
  /// In en, this message translates to:
  /// **'Krita plugin connected'**
  String get settings_kritaBridgeConnectedText;

  /// No description provided for @settings_kritaBridgeErrorText.
  ///
  /// In en, this message translates to:
  /// **'Startup failed, check the error message'**
  String get settings_kritaBridgeErrorText;

  /// No description provided for @settings_kritaBridgeRegenerateSession.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Session'**
  String get settings_kritaBridgeRegenerateSession;

  /// No description provided for @settings_kritaBridgeDiscoveryFile.
  ///
  /// In en, this message translates to:
  /// **'Discovery File'**
  String get settings_kritaBridgeDiscoveryFile;

  /// No description provided for @settings_kritaBridgeWaitingEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Waiting for local WebSocket listener'**
  String get settings_kritaBridgeWaitingEndpoint;

  /// No description provided for @settings_kritaBridgeClient.
  ///
  /// In en, this message translates to:
  /// **'Client: {client}'**
  String settings_kritaBridgeClient(Object client);

  /// No description provided for @settings_fontScale.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settings_fontScale;

  /// No description provided for @settings_fontScale_previewSmall.
  ///
  /// In en, this message translates to:
  /// **'光影落在画布上。'**
  String get settings_fontScale_previewSmall;

  /// No description provided for @settings_fontScale_previewMedium.
  ///
  /// In en, this message translates to:
  /// **'色から物語が生まれる。'**
  String get settings_fontScale_previewMedium;

  /// No description provided for @settings_fontScale_previewLarge.
  ///
  /// In en, this message translates to:
  /// **'Let colors tell a story.'**
  String get settings_fontScale_previewLarge;

  /// No description provided for @settings_fontScale_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settings_fontScale_done;

  /// No description provided for @settings_historyClickBehavior.
  ///
  /// In en, this message translates to:
  /// **'History click behavior'**
  String get settings_historyClickBehavior;

  /// No description provided for @settings_historyClickBehavior_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get settings_historyClickBehavior_classic;

  /// No description provided for @settings_historyClickBehavior_classicDescription.
  ///
  /// In en, this message translates to:
  /// **'Click a history image to open its details'**
  String get settings_historyClickBehavior_classicDescription;

  /// No description provided for @settings_historyClickBehavior_linked.
  ///
  /// In en, this message translates to:
  /// **'Linked preview'**
  String get settings_historyClickBehavior_linked;

  /// No description provided for @settings_historyClickBehavior_linkedDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to switch the central preview, double-click or hold for details, and browse with Left/Right'**
  String get settings_historyClickBehavior_linkedDescription;

  /// No description provided for @settings_outputViewer.
  ///
  /// In en, this message translates to:
  /// **'Output viewer'**
  String get settings_outputViewer;

  /// No description provided for @settings_outputViewer_canvas.
  ///
  /// In en, this message translates to:
  /// **'Free canvas'**
  String get settings_outputViewer_canvas;

  /// No description provided for @settings_outputViewer_canvasDescription.
  ///
  /// In en, this message translates to:
  /// **'NAI5-style infinite canvas: all generated images laid out by batch, middle/Shift+left drag to pan, Ctrl+wheel to zoom, WASD/f/q to navigate'**
  String get settings_outputViewer_canvasDescription;

  /// No description provided for @settings_outputViewer_simple.
  ///
  /// In en, this message translates to:
  /// **'Simple view'**
  String get settings_outputViewer_simple;

  /// No description provided for @settings_outputViewer_simpleDescription.
  ///
  /// In en, this message translates to:
  /// **'Classic centered/grid preview for low-spec machines or the familiar layout'**
  String get settings_outputViewer_simpleDescription;

  /// No description provided for @settings_canvasLockCamera.
  ///
  /// In en, this message translates to:
  /// **'Lock canvas camera'**
  String get settings_canvasLockCamera;

  /// No description provided for @settings_canvasLockCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Disables wheel zoom/pan, drag panning, WASD and other manual camera input; auto-select and navigation jumps still work'**
  String get settings_canvasLockCameraDescription;

  /// No description provided for @settings_canvasReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce canvas motion'**
  String get settings_canvasReducedMotion;

  /// No description provided for @settings_canvasReducedMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Camera flights, zooms and inertia become instant, reducing animation'**
  String get settings_canvasReducedMotionDescription;

  /// No description provided for @image_viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get image_viewDetail;

  /// No description provided for @settings_defaultImagesPath.
  ///
  /// In en, this message translates to:
  /// **'Default (Documents/NAI_Launcher/images/)'**
  String get settings_defaultImagesPath;

  /// No description provided for @settings_defaultHivePath.
  ///
  /// In en, this message translates to:
  /// **'Default (%APPDATA%/NAI_Launcher/hive/)'**
  String get settings_defaultHivePath;

  /// No description provided for @settings_protectionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Protection Features'**
  String get settings_protectionFeatures;

  /// No description provided for @settings_stripMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all metadata when copying or dragging'**
  String get settings_stripMetadataTitle;

  /// No description provided for @settings_stripMetadataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a sanitized copy, remove PNG text chunks, EXIF, and NAI steganographic watermark data, and avoid exposing the original path while dragging.'**
  String get settings_stripMetadataSubtitle;

  /// No description provided for @settings_confirmDangerousActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Double-confirm dangerous asset actions'**
  String get settings_confirmDangerousActionsTitle;

  /// No description provided for @settings_confirmDangerousActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting, moving, or batch-moving local assets will show an additional protection confirmation.'**
  String get settings_confirmDangerousActionsSubtitle;

  /// No description provided for @settings_warnExternalImageSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm before sending to external services'**
  String get settings_warnExternalImageSendTitle;

  /// No description provided for @settings_warnExternalImageSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm before local images cross the app boundary to LLMs, NovelAI, ComfyUI, or similar services.'**
  String get settings_warnExternalImageSendSubtitle;

  /// No description provided for @settings_preventOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid overwriting existing files on export'**
  String get settings_preventOverwriteTitle;

  /// No description provided for @settings_preventOverwriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically number duplicate export or package paths to avoid replacing existing assets by mistake.'**
  String get settings_preventOverwriteSubtitle;

  /// No description provided for @settings_warnHighAnlasCostTitle.
  ///
  /// In en, this message translates to:
  /// **'High Anlas cost warning'**
  String get settings_warnHighAnlasCostTitle;

  /// No description provided for @settings_warnHighAnlasCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a confirmation before generation when the estimated single request cost reaches {threshold} Anlas.'**
  String settings_warnHighAnlasCostSubtitle(Object threshold);

  /// No description provided for @settings_highAnlasCostThresholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Anlas Warning Threshold'**
  String get settings_highAnlasCostThresholdTitle;

  /// No description provided for @settings_setHighAnlasCostThresholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Anlas Warning Threshold'**
  String get settings_setHighAnlasCostThresholdTitle;

  /// No description provided for @settings_threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get settings_threshold;

  /// No description provided for @settings_highAnlasCostThresholdHelper.
  ///
  /// In en, this message translates to:
  /// **'Show a confirmation when the estimated single generation cost reaches or exceeds this value.'**
  String get settings_highAnlasCostThresholdHelper;

  /// No description provided for @settings_limitGenerationIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit generation frequency'**
  String get settings_limitGenerationIntervalTitle;

  /// No description provided for @settings_limitGenerationIntervalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require the configured minimum time between generation starts. The Generate button is disabled during the cooldown.'**
  String get settings_limitGenerationIntervalSubtitle;

  /// No description provided for @settings_generationIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Generation interval'**
  String get settings_generationIntervalTitle;

  /// No description provided for @settings_generationIntervalValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String settings_generationIntervalValue(Object seconds);

  /// No description provided for @settings_setGenerationIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Generation Interval'**
  String get settings_setGenerationIntervalTitle;

  /// No description provided for @settings_generationIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter 1–3600 seconds. The cooldown starts when generation begins.'**
  String get settings_generationIntervalHelper;

  /// No description provided for @settings_generationIntervalJitterTitle.
  ///
  /// In en, this message translates to:
  /// **'Interval jitter'**
  String get settings_generationIntervalJitterTitle;

  /// No description provided for @settings_generationIntervalJitterValue.
  ///
  /// In en, this message translates to:
  /// **'±{percent}%'**
  String settings_generationIntervalJitterValue(Object percent);

  /// No description provided for @settings_setGenerationIntervalJitterTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Interval Jitter'**
  String get settings_setGenerationIntervalJitterTitle;

  /// No description provided for @settings_generationIntervalJitterHelper.
  ///
  /// In en, this message translates to:
  /// **'Each cooldown is drawn at random from base interval ± this percentage, so the pacing is less mechanical. Enter 0–50; 0 disables jitter.'**
  String get settings_generationIntervalJitterHelper;

  /// No description provided for @settings_confirmExternalSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Protection Mode: Confirm External Send'**
  String get settings_confirmExternalSendTitle;

  /// No description provided for @settings_confirmExternalSendContent.
  ///
  /// In en, this message translates to:
  /// **'About to send {count} local image(s) to {target}. The image data will leave the local app boundary. Confirm this is expected.'**
  String settings_confirmExternalSendContent(Object count, Object target);

  /// No description provided for @settings_confirmExternalSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get settings_confirmExternalSend;

  /// No description provided for @settings_highAnlasCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Anlas usage reminder'**
  String get settings_highAnlasCostTitle;

  /// No description provided for @settings_continueGeneration.
  ///
  /// In en, this message translates to:
  /// **'Continue Generation'**
  String get settings_continueGeneration;

  /// No description provided for @dataSource_syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get dataSource_syncNow;

  /// No description provided for @settings_comfyUiEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable ComfyUI Integration'**
  String get settings_comfyUiEnable;

  /// No description provided for @settings_comfyUiDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When disabled, local upscale and other ComfyUI features are hidden'**
  String get settings_comfyUiDisabledSubtitle;

  /// No description provided for @settings_comfyUiServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settings_comfyUiServerUrl;

  /// No description provided for @settings_comfyUiConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get settings_comfyUiConnectionSuccess;

  /// No description provided for @settings_comfyUiConnectionSuccessFull.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI connection successful'**
  String get settings_comfyUiConnectionSuccessFull;

  /// No description provided for @settings_comfyUiConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String settings_comfyUiConnectionFailed(Object error);

  /// No description provided for @settings_comfyUiConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settings_comfyUiConnected;

  /// No description provided for @settings_comfyUiDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settings_comfyUiDisconnect;

  /// No description provided for @settings_comfyUiNoResponse.
  ///
  /// In en, this message translates to:
  /// **'Server did not respond'**
  String get settings_comfyUiNoResponse;

  /// No description provided for @settings_comfyUiStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get settings_comfyUiStatusDisconnected;

  /// No description provided for @settings_comfyUiStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get settings_comfyUiStatusConnecting;

  /// No description provided for @settings_comfyUiStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settings_comfyUiStatusConnected;

  /// No description provided for @settings_comfyUiStatusError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get settings_comfyUiStatusError;

  /// No description provided for @settings_comfyUiCategoryEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance/Upscale'**
  String get settings_comfyUiCategoryEnhance;

  /// No description provided for @settings_comfyUiCategoryImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Image2Image'**
  String get settings_comfyUiCategoryImg2Img;

  /// No description provided for @settings_comfyUiCategoryInpaint.
  ///
  /// In en, this message translates to:
  /// **'Inpaint'**
  String get settings_comfyUiCategoryInpaint;

  /// No description provided for @settings_comfyUiCategoryTxt2Img.
  ///
  /// In en, this message translates to:
  /// **'Text-to-Image'**
  String get settings_comfyUiCategoryTxt2Img;

  /// No description provided for @settings_comfyUiCategoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settings_comfyUiCategoryCustom;

  /// No description provided for @comfyWorkflow_seedvr2UpscaleName.
  ///
  /// In en, this message translates to:
  /// **'SeedVR2 Upscale'**
  String get comfyWorkflow_seedvr2UpscaleName;

  /// No description provided for @comfyWorkflow_seedvr2UpscaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Upscale with the SeedVR2 AI model. Produces high-quality results.'**
  String get comfyWorkflow_seedvr2UpscaleDescription;

  /// No description provided for @comfyWorkflow_seedvr2TiledUpscaleName.
  ///
  /// In en, this message translates to:
  /// **'SeedVR2 Tiled Upscale'**
  String get comfyWorkflow_seedvr2TiledUpscaleName;

  /// No description provided for @comfyWorkflow_seedvr2TiledUpscaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Use SeedVR2TilingUpscaler for tiled upscale to reduce VRAM pressure on large images.'**
  String get comfyWorkflow_seedvr2TiledUpscaleDescription;

  /// No description provided for @comfyWorkflow_modelUpscaleName.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI Standard Upscale Model'**
  String get comfyWorkflow_modelUpscaleName;

  /// No description provided for @comfyWorkflow_modelUpscaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Load a standard upscale model with ComfyUI UpscaleModelLoader, then correct the final scale with Lanczos.'**
  String get comfyWorkflow_modelUpscaleDescription;

  /// No description provided for @comfyWorkflow_rtxUpscaleName.
  ///
  /// In en, this message translates to:
  /// **'RTX Upscale'**
  String get comfyWorkflow_rtxUpscaleName;

  /// No description provided for @comfyWorkflow_rtxUpscaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the Nvidia RTX Video Super Resolution node for local upscaling.'**
  String get comfyWorkflow_rtxUpscaleDescription;

  /// No description provided for @comfyWorkflowSlot_inputImage.
  ///
  /// In en, this message translates to:
  /// **'Input Image'**
  String get comfyWorkflowSlot_inputImage;

  /// No description provided for @comfyWorkflowSlot_targetShortSide.
  ///
  /// In en, this message translates to:
  /// **'Target Short Side'**
  String get comfyWorkflowSlot_targetShortSide;

  /// No description provided for @comfyWorkflowSlot_targetLongSide.
  ///
  /// In en, this message translates to:
  /// **'Target Long Side'**
  String get comfyWorkflowSlot_targetLongSide;

  /// No description provided for @comfyWorkflowSlot_upscaleModel.
  ///
  /// In en, this message translates to:
  /// **'Upscale Model'**
  String get comfyWorkflowSlot_upscaleModel;

  /// No description provided for @comfyWorkflowSlot_randomSeed.
  ///
  /// In en, this message translates to:
  /// **'Random Seed'**
  String get comfyWorkflowSlot_randomSeed;

  /// No description provided for @comfyWorkflowSlot_outputImage.
  ///
  /// In en, this message translates to:
  /// **'Output Image'**
  String get comfyWorkflowSlot_outputImage;

  /// No description provided for @comfyWorkflowSlot_tileWidth.
  ///
  /// In en, this message translates to:
  /// **'Tile Width'**
  String get comfyWorkflowSlot_tileWidth;

  /// No description provided for @comfyWorkflowSlot_tileHeight.
  ///
  /// In en, this message translates to:
  /// **'Tile Height'**
  String get comfyWorkflowSlot_tileHeight;

  /// No description provided for @comfyWorkflowSlot_tileUpscaleResolution.
  ///
  /// In en, this message translates to:
  /// **'Tile Upscale Resolution'**
  String get comfyWorkflowSlot_tileUpscaleResolution;

  /// No description provided for @comfyWorkflowSlot_targetWidth.
  ///
  /// In en, this message translates to:
  /// **'Target Width'**
  String get comfyWorkflowSlot_targetWidth;

  /// No description provided for @comfyWorkflowSlot_targetHeight.
  ///
  /// In en, this message translates to:
  /// **'Target Height'**
  String get comfyWorkflowSlot_targetHeight;

  /// No description provided for @comfyWorkflowSlot_scale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get comfyWorkflowSlot_scale;

  /// No description provided for @comfyWorkflow_parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get comfyWorkflow_parameters;

  /// No description provided for @comfyWorkflow_selectImage.
  ///
  /// In en, this message translates to:
  /// **'Click to select image'**
  String get comfyWorkflow_selectImage;

  /// No description provided for @comfyWorkflow_pickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image: {error}'**
  String comfyWorkflow_pickImageFailed(Object error);

  /// No description provided for @comfyWorkflow_useResult.
  ///
  /// In en, this message translates to:
  /// **'Use Result'**
  String get comfyWorkflow_useResult;

  /// No description provided for @comfyWorkflow_execute.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get comfyWorkflow_execute;

  /// No description provided for @comfyWorkflow_uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get comfyWorkflow_uploadingImage;

  /// No description provided for @comfyWorkflow_queued.
  ///
  /// In en, this message translates to:
  /// **'Queued...'**
  String get comfyWorkflow_queued;

  /// No description provided for @comfyWorkflow_runningSteps.
  ///
  /// In en, this message translates to:
  /// **'Processing {current}/{total}'**
  String comfyWorkflow_runningSteps(Object current, Object total);

  /// No description provided for @comfyWorkflow_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get comfyWorkflow_processing;

  /// No description provided for @comfyWorkflow_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get comfyWorkflow_complete;

  /// No description provided for @comfyWorkflow_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String comfyWorkflow_imageCount(Object count);

  /// No description provided for @cacheStats_title.
  ///
  /// In en, this message translates to:
  /// **'Cache Statistics'**
  String get cacheStats_title;

  /// No description provided for @cacheStats_autoRefreshUpdated.
  ///
  /// In en, this message translates to:
  /// **'Auto refresh · Last updated: {time}'**
  String cacheStats_autoRefreshUpdated(Object time);

  /// No description provided for @cacheStats_secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds ago'**
  String cacheStats_secondsAgo(Object seconds);

  /// No description provided for @cacheStats_resetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics'**
  String get cacheStats_resetStats;

  /// No description provided for @cacheStats_statsReset.
  ///
  /// In en, this message translates to:
  /// **'Statistics reset'**
  String get cacheStats_statsReset;

  /// No description provided for @cacheStats_l1Memory.
  ///
  /// In en, this message translates to:
  /// **'L1 Memory Cache'**
  String get cacheStats_l1Memory;

  /// No description provided for @cacheStats_l2Hive.
  ///
  /// In en, this message translates to:
  /// **'L2 Hive Cache'**
  String get cacheStats_l2Hive;

  /// No description provided for @cacheStats_l3Sqlite.
  ///
  /// In en, this message translates to:
  /// **'L3 SQLite Database'**
  String get cacheStats_l3Sqlite;

  /// No description provided for @galleryCache_rescanTitle.
  ///
  /// In en, this message translates to:
  /// **'Rescan Gallery'**
  String get galleryCache_rescanTitle;

  /// No description provided for @galleryCache_rescanContent.
  ///
  /// In en, this message translates to:
  /// **'This will:\n\n1. Check data consistency and mark missing files\n2. Scan new and changed files\n3. Retry metadata extraction that failed before, including failed records\n\nThis will not clear existing data or delete image files.'**
  String get galleryCache_rescanContent;

  /// No description provided for @galleryCache_startScan.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get galleryCache_startScan;

  /// No description provided for @galleryCache_scanAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'A scan task is already running. Please wait for it to finish.'**
  String get galleryCache_scanAlreadyRunning;

  /// No description provided for @galleryCache_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get galleryCache_preparing;

  /// No description provided for @galleryCache_noGalleryFolder.
  ///
  /// In en, this message translates to:
  /// **'Gallery folder is not set'**
  String get galleryCache_noGalleryFolder;

  /// No description provided for @galleryCache_scanningPhase.
  ///
  /// In en, this message translates to:
  /// **'Scanning {processed}/{total}...'**
  String galleryCache_scanningPhase(Object processed, Object total);

  /// No description provided for @galleryCache_scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get galleryCache_scanComplete;

  /// No description provided for @galleryCache_scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String galleryCache_scanFailed(Object error);

  /// No description provided for @galleryCache_rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get galleryCache_rescan;

  /// No description provided for @galleryCache_rescanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check data consistency, find missing files, and extract metadata'**
  String get galleryCache_rescanSubtitle;

  /// No description provided for @galleryCache_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get galleryCache_scanning;

  /// No description provided for @galleryCache_scanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get galleryCache_scanAction;

  /// No description provided for @galleryCache_evictThumbnailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean Thumbnail Cache'**
  String get galleryCache_evictThumbnailsTitle;

  /// No description provided for @galleryCache_evictThumbnailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evict least-recently-used .thumbs files over the limit (originals untouched)'**
  String get galleryCache_evictThumbnailsSubtitle;

  /// No description provided for @galleryCache_evictThumbnailsContent.
  ///
  /// In en, this message translates to:
  /// **'Evicts the on-disk thumbnail cache over its limit, least recently used first.\n\nOnly .thumb.jpg files inside .thumbs directories are deleted; original images are never removed or modified. Removed thumbnails will be regenerated on demand the next time you browse.'**
  String get galleryCache_evictThumbnailsContent;

  /// No description provided for @galleryCache_evictThumbnailsStart.
  ///
  /// In en, this message translates to:
  /// **'Clean Now'**
  String get galleryCache_evictThumbnailsStart;

  /// No description provided for @galleryCache_evictThumbnailsRunning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning thumbnail cache...'**
  String get galleryCache_evictThumbnailsRunning;

  /// No description provided for @galleryCache_evictThumbnailsDone.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} thumbnails, freed {size} MB'**
  String galleryCache_evictThumbnailsDone(int count, String size);

  /// No description provided for @galleryCache_evictThumbnailsNone.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail cache is under the limit; nothing to clean'**
  String get galleryCache_evictThumbnailsNone;

  /// No description provided for @galleryCache_evictThumbnailsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clean thumbnail cache: {error}'**
  String galleryCache_evictThumbnailsFailed(Object error);

  /// No description provided for @workflowImport_title.
  ///
  /// In en, this message translates to:
  /// **'Import ComfyUI Workflow'**
  String get workflowImport_title;

  /// No description provided for @workflowImport_step.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/4: {title}'**
  String workflowImport_step(Object current, Object title);

  /// No description provided for @workflowImport_stepFile.
  ///
  /// In en, this message translates to:
  /// **'Select Workflow File'**
  String get workflowImport_stepFile;

  /// No description provided for @workflowImport_stepInfo.
  ///
  /// In en, this message translates to:
  /// **'Workflow Info'**
  String get workflowImport_stepInfo;

  /// No description provided for @workflowImport_stepSlots.
  ///
  /// In en, this message translates to:
  /// **'Confirm Slot Config'**
  String get workflowImport_stepSlots;

  /// No description provided for @workflowImport_stepDone.
  ///
  /// In en, this message translates to:
  /// **'Complete Import'**
  String get workflowImport_stepDone;

  /// No description provided for @workflowImport_previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get workflowImport_previous;

  /// No description provided for @workflowImport_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get workflowImport_next;

  /// No description provided for @workflowImport_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish Import'**
  String get workflowImport_finish;

  /// No description provided for @workflowImport_defaultName.
  ///
  /// In en, this message translates to:
  /// **'Custom Workflow'**
  String get workflowImport_defaultName;

  /// No description provided for @workflowImport_fileInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select a workflow_api.json file exported from ComfyUI.\n\nIn ComfyUI, open the menu and choose Export (API format) to get this file.'**
  String get workflowImport_fileInstructions;

  /// No description provided for @workflowImport_nodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes'**
  String workflowImport_nodeCount(Object count);

  /// No description provided for @workflowImport_reselect.
  ///
  /// In en, this message translates to:
  /// **'Click to choose another file'**
  String get workflowImport_reselect;

  /// No description provided for @workflowImport_selectWorkflowApi.
  ///
  /// In en, this message translates to:
  /// **'Click to select workflow_api.json'**
  String get workflowImport_selectWorkflowApi;

  /// No description provided for @workflowImport_invalidTopLevel.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format: top level should be a JSON object'**
  String get workflowImport_invalidTopLevel;

  /// No description provided for @workflowImport_noComfyNodes.
  ///
  /// In en, this message translates to:
  /// **'No ComfyUI nodes detected. Make sure this is an API-format export.'**
  String get workflowImport_noComfyNodes;

  /// No description provided for @workflowImport_readFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file: {error}'**
  String workflowImport_readFailed(Object error);

  /// No description provided for @workflowImport_analysisResult.
  ///
  /// In en, this message translates to:
  /// **'Automatic Analysis Result'**
  String get workflowImport_analysisResult;

  /// No description provided for @workflowImport_inputImageNodes.
  ///
  /// In en, this message translates to:
  /// **'Input image nodes'**
  String get workflowImport_inputImageNodes;

  /// No description provided for @workflowImport_adjustableParams.
  ///
  /// In en, this message translates to:
  /// **'Adjustable parameters'**
  String get workflowImport_adjustableParams;

  /// No description provided for @workflowImport_outputNodes.
  ///
  /// In en, this message translates to:
  /// **'Output nodes'**
  String get workflowImport_outputNodes;

  /// No description provided for @workflowImport_totalNodes.
  ///
  /// In en, this message translates to:
  /// **'Total nodes'**
  String get workflowImport_totalNodes;

  /// No description provided for @workflowImport_countUnit.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String workflowImport_countUnit(Object count);

  /// No description provided for @workflowImport_workflowName.
  ///
  /// In en, this message translates to:
  /// **'Workflow Name *'**
  String get workflowImport_workflowName;

  /// No description provided for @workflowImport_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get workflowImport_description;

  /// No description provided for @workflowImport_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get workflowImport_category;

  /// No description provided for @workflowImport_slotsHint.
  ///
  /// In en, this message translates to:
  /// **'Select the slots to expose in the UI. Input and output slots should usually stay enabled; parameters that users do not need to adjust can be disabled.'**
  String get workflowImport_slotsHint;

  /// No description provided for @workflowImport_inputSection.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get workflowImport_inputSection;

  /// No description provided for @workflowImport_outputSection.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get workflowImport_outputSection;

  /// No description provided for @workflowImport_parameterSection.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get workflowImport_parameterSection;

  /// No description provided for @workflowImport_noSlotsWarning.
  ///
  /// In en, this message translates to:
  /// **'No usable slots were detected. This workflow may not integrate correctly.\nMake sure the workflow includes LoadImage and SaveImage/SaveImageWebsocket nodes.'**
  String get workflowImport_noSlotsWarning;

  /// No description provided for @workflowImport_nodeRef.
  ///
  /// In en, this message translates to:
  /// **'Node {node}'**
  String workflowImport_nodeRef(Object node);

  /// No description provided for @workflowImport_confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'About to import this workflow'**
  String get workflowImport_confirmTitle;

  /// No description provided for @workflowImport_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workflowImport_name;

  /// No description provided for @workflowImport_inputSlots.
  ///
  /// In en, this message translates to:
  /// **'Input Slots'**
  String get workflowImport_inputSlots;

  /// No description provided for @workflowImport_parameterSlots.
  ///
  /// In en, this message translates to:
  /// **'Parameter Slots'**
  String get workflowImport_parameterSlots;

  /// No description provided for @workflowImport_outputSlots.
  ///
  /// In en, this message translates to:
  /// **'Output Slots'**
  String get workflowImport_outputSlots;

  /// No description provided for @workflowImport_afterImportHint.
  ///
  /// In en, this message translates to:
  /// **'After import, it can be used from the ComfyUI workflow list on the generation screen.'**
  String get workflowImport_afterImportHint;

  /// No description provided for @workflowImport_success.
  ///
  /// In en, this message translates to:
  /// **'Workflow \"{name}\" imported'**
  String workflowImport_success(Object name);

  /// No description provided for @shortcut_settings_help.
  ///
  /// In en, this message translates to:
  /// **'View shortcut help'**
  String get shortcut_settings_help;

  /// No description provided for @shortcut_settings_show_in_menus.
  ///
  /// In en, this message translates to:
  /// **'Show in menus'**
  String get shortcut_settings_show_in_menus;

  /// No description provided for @shortcut_settings_defaultShortcut.
  ///
  /// In en, this message translates to:
  /// **'Default: {shortcut}'**
  String shortcut_settings_defaultShortcut(Object shortcut);

  /// No description provided for @shortcut_settings_unassigned.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get shortcut_settings_unassigned;

  /// No description provided for @shortcut_settings_no_matches.
  ///
  /// In en, this message translates to:
  /// **'No matching shortcuts found'**
  String get shortcut_settings_no_matches;

  /// No description provided for @shortcut_settings_reset_all_title.
  ///
  /// In en, this message translates to:
  /// **'Reset All Shortcuts'**
  String get shortcut_settings_reset_all_title;

  /// No description provided for @shortcut_settings_reset_all_confirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all shortcuts to their default settings? This cannot be undone.'**
  String get shortcut_settings_reset_all_confirm;

  /// No description provided for @shortcut_settings_reset_to_default.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get shortcut_settings_reset_to_default;

  /// No description provided for @toast_previewUpdated.
  ///
  /// In en, this message translates to:
  /// **'Preview image updated'**
  String get toast_previewUpdated;

  /// No description provided for @toast_styleReferenceLimit.
  ///
  /// In en, this message translates to:
  /// **'Style References reached the limit ({max} images)'**
  String toast_styleReferenceLimit(Object max);

  /// No description provided for @toast_noValidMaskIgnored.
  ///
  /// In en, this message translates to:
  /// **'No valid mask detected; save result was ignored.'**
  String get toast_noValidMaskIgnored;

  /// No description provided for @toast_kritaBusy.
  ///
  /// In en, this message translates to:
  /// **'Krita Bridge is generating. Wait for the current task to finish.'**
  String get toast_kritaBusy;

  /// No description provided for @toast_kritaNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Krita is not connected. Enable the bridge in Settings and connect the plugin first.'**
  String get toast_kritaNotConnected;

  /// No description provided for @toast_sentToKrita.
  ///
  /// In en, this message translates to:
  /// **'Image sent to Krita'**
  String get toast_sentToKrita;

  /// No description provided for @toast_kritaUnsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'This image format cannot be sent to Krita. Use a common image format.'**
  String get toast_kritaUnsupportedImageFormat;

  /// No description provided for @toast_deletedNamed.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {name}'**
  String toast_deletedNamed(Object name);

  /// No description provided for @toast_vibeParamSaveReencodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save parameters because Vibe re-encoding failed'**
  String get toast_vibeParamSaveReencodeFailed;

  /// No description provided for @toast_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get toast_exportSuccess;

  /// No description provided for @toast_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String toast_exportFailed(Object error);

  /// No description provided for @toast_selectVibeToExport.
  ///
  /// In en, this message translates to:
  /// **'Select a Vibe to export first'**
  String get toast_selectVibeToExport;

  /// No description provided for @toast_embedPngSingleVibeOnly.
  ///
  /// In en, this message translates to:
  /// **'Embedding into PNG only supports exporting one Vibe'**
  String get toast_embedPngSingleVibeOnly;

  /// No description provided for @toast_selectPngCarrier.
  ///
  /// In en, this message translates to:
  /// **'Select a PNG carrier image for export'**
  String get toast_selectPngCarrier;

  /// No description provided for @toast_renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed successfully'**
  String get toast_renameSuccess;

  /// No description provided for @toast_paramsSaved.
  ///
  /// In en, this message translates to:
  /// **'Parameters saved'**
  String get toast_paramsSaved;

  /// No description provided for @toast_paramsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save parameters'**
  String get toast_paramsSaveFailed;

  /// No description provided for @toast_dropNoReadableImageOrVibe.
  ///
  /// In en, this message translates to:
  /// **'The drop source did not provide a readable image or Vibe file'**
  String get toast_dropNoReadableImageOrVibe;

  /// No description provided for @toast_contentCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Content cannot be empty'**
  String get toast_contentCannotBeEmpty;

  /// No description provided for @toast_addedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to library'**
  String get toast_addedToLibrary;

  /// No description provided for @toast_addFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String toast_addFailed(Object error);

  /// No description provided for @toast_libraryNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Library is not loaded'**
  String get toast_libraryNotLoaded;

  /// No description provided for @toast_noValidTagContent.
  ///
  /// In en, this message translates to:
  /// **'No valid tag content'**
  String get toast_noValidTagContent;

  /// No description provided for @toast_allTagsAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'All tags already exist in the library'**
  String get toast_allTagsAlreadyExist;

  /// No description provided for @toast_noAddableTags.
  ///
  /// In en, this message translates to:
  /// **'No tags can be added'**
  String get toast_noAddableTags;

  /// No description provided for @toast_addedTagsSkippedDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Added {added} tags, skipped {skipped} duplicate tags'**
  String toast_addedTagsSkippedDuplicates(Object added, Object skipped);

  /// No description provided for @toast_favorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get toast_favorited;

  /// No description provided for @toast_unfavorited.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited'**
  String get toast_unfavorited;

  /// No description provided for @toast_favoriteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite state: {error}'**
  String toast_favoriteUpdateFailed(Object error);

  /// No description provided for @toast_packingImages.
  ///
  /// In en, this message translates to:
  /// **'Packing {count} images...'**
  String toast_packingImages(Object count);

  /// No description provided for @toast_packedImages.
  ///
  /// In en, this message translates to:
  /// **'Packed {count} images'**
  String toast_packedImages(Object count);

  /// No description provided for @toast_packFailed.
  ///
  /// In en, this message translates to:
  /// **'Pack failed'**
  String get toast_packFailed;

  /// No description provided for @toast_packFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Pack failed: {error}'**
  String toast_packFailedWithError(Object error);

  /// No description provided for @toast_saveDirNotSet.
  ///
  /// In en, this message translates to:
  /// **'Save directory is not set'**
  String get toast_saveDirNotSet;

  /// No description provided for @toast_savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String toast_savedTo(Object path);

  /// No description provided for @toast_tagAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Tag already exists'**
  String get toast_tagAlreadyExists;

  /// No description provided for @toast_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get toast_nameRequired;

  /// No description provided for @toast_savedToVibeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to Vibe Library'**
  String get toast_savedToVibeLibrary;

  /// No description provided for @toast_saveBundleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save bundle'**
  String get toast_saveBundleFailed;

  /// No description provided for @toast_saveEntryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save entry'**
  String get toast_saveEntryFailed;

  /// No description provided for @toast_imagePromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied'**
  String get toast_imagePromptCopied;

  /// No description provided for @toast_imageHasNoPrompt.
  ///
  /// In en, this message translates to:
  /// **'This image has no Prompt'**
  String get toast_imageHasNoPrompt;

  /// No description provided for @toast_useDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Use the delete button in the UI'**
  String get toast_useDeleteButton;

  /// No description provided for @toast_imageDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image data is unavailable and cannot be copied'**
  String get toast_imageDataUnavailable;

  /// No description provided for @toast_vibeDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Vibe data copied'**
  String get toast_vibeDataCopied;

  /// No description provided for @toast_characterPromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Character prompt copied'**
  String get toast_characterPromptCopied;

  /// No description provided for @toast_copiedTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} copied'**
  String toast_copiedTitle(Object title);

  /// No description provided for @toast_replacedVibesCount.
  ///
  /// In en, this message translates to:
  /// **'Replaced with {count} Vibes: {name}'**
  String toast_replacedVibesCount(Object count, Object name);

  /// No description provided for @toast_sentVibesCount.
  ///
  /// In en, this message translates to:
  /// **'Sent {count} Vibes to generation: {name}'**
  String toast_sentVibesCount(Object count, Object name);

  /// No description provided for @toast_replacedVibe.
  ///
  /// In en, this message translates to:
  /// **'Replaced with: {name}'**
  String toast_replacedVibe(Object name);

  /// No description provided for @toast_sentVibeToGeneration.
  ///
  /// In en, this message translates to:
  /// **'Sent to generation: {name}'**
  String toast_sentVibeToGeneration(Object name);

  /// No description provided for @toast_unreadableDroppedImageSource.
  ///
  /// In en, this message translates to:
  /// **'The drop source did not provide a readable image file or image URL'**
  String get toast_unreadableDroppedImageSource;

  /// No description provided for @toast_appendedStyleReferences.
  ///
  /// In en, this message translates to:
  /// **'Appended {count} Style References'**
  String toast_appendedStyleReferences(Object count);

  /// No description provided for @toast_appendedPreencodedVibe.
  ///
  /// In en, this message translates to:
  /// **'Appended 1 Style Reference (reused pre-encoded Vibe)'**
  String get toast_appendedPreencodedVibe;

  /// No description provided for @toast_addedPreencodedVibe.
  ///
  /// In en, this message translates to:
  /// **'Added Style Reference (reused pre-encoded Vibe, saved 2 Anlas)'**
  String get toast_addedPreencodedVibe;

  /// No description provided for @toast_vibesMissingEncoding.
  ///
  /// In en, this message translates to:
  /// **'{count} Vibes are missing encoded data and cannot be saved'**
  String toast_vibesMissingEncoding(Object count);

  /// No description provided for @toast_savedBundle.
  ///
  /// In en, this message translates to:
  /// **'Saved Bundle ({count} Vibes)'**
  String toast_savedBundle(Object count);

  /// No description provided for @toast_extractMetadataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract metadata: {error}'**
  String toast_extractMetadataFailed(Object error);

  /// No description provided for @toast_renameNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get toast_renameNameRequired;

  /// No description provided for @toast_renameNameConflict.
  ///
  /// In en, this message translates to:
  /// **'Name already exists. Use another name.'**
  String get toast_renameNameConflict;

  /// No description provided for @toast_renameEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'The entry no longer exists and may have been deleted'**
  String get toast_renameEntryNotFound;

  /// No description provided for @toast_renameFilePathMissing.
  ///
  /// In en, this message translates to:
  /// **'This entry has no file path and cannot be renamed'**
  String get toast_renameFilePathMissing;

  /// No description provided for @toast_renameFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename file. Try again later.'**
  String get toast_renameFileFailed;

  /// No description provided for @toast_renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed. Try again later.'**
  String get toast_renameFailed;

  /// No description provided for @toast_processImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process image: {error}'**
  String toast_processImageFailed(Object error);

  /// No description provided for @toast_savePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preview image'**
  String get toast_savePreviewFailed;

  /// No description provided for @common_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get common_justNow;

  /// No description provided for @common_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String common_minutesAgo(Object minutes);

  /// No description provided for @common_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String common_hoursAgo(Object hours);

  /// No description provided for @common_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get common_saving;

  /// No description provided for @common_pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get common_pleaseWait;

  /// No description provided for @common_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get common_change;

  /// No description provided for @common_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get common_expand;

  /// No description provided for @common_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get common_collapse;

  /// No description provided for @vibeLibrary_emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching Vibes'**
  String get vibeLibrary_emptySearchTitle;

  /// No description provided for @vibeLibrary_emptySearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get vibeLibrary_emptySearchSubtitle;

  /// No description provided for @vibeLibrary_emptyFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite Vibes yet'**
  String get vibeLibrary_emptyFavoritesTitle;

  /// No description provided for @vibeLibrary_emptyFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Click the heart icon to favorite a Vibe'**
  String get vibeLibrary_emptyFavoritesSubtitle;

  /// No description provided for @vibeLibrary_emptyCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No Vibes in this category'**
  String get vibeLibrary_emptyCategoryTitle;

  /// No description provided for @vibeLibrary_emptyCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"All Vibes\" to see all entries'**
  String get vibeLibrary_emptyCategorySubtitle;

  /// No description provided for @vibeLibrary_emptyNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get vibeLibrary_emptyNoMatchesTitle;

  /// No description provided for @vibeLibrary_emptySaveFromGenerationHint.
  ///
  /// In en, this message translates to:
  /// **'Save Vibes from the generation page to add them to the library'**
  String get vibeLibrary_emptySaveFromGenerationHint;

  /// No description provided for @vibe_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get vibe_nameRequired;

  /// No description provided for @vibe_import_namingTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Vibe'**
  String get vibe_import_namingTitle;

  /// No description provided for @vibe_import_nameConflictOverwrite.
  ///
  /// In en, this message translates to:
  /// **'This name already exists and will be overwritten'**
  String get vibe_import_nameConflictOverwrite;

  /// No description provided for @vibe_previewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preview'**
  String get vibe_previewLoadFailed;

  /// No description provided for @vibe_import_applyToRemainingFiles.
  ///
  /// In en, this message translates to:
  /// **'Apply to all remaining files'**
  String get vibe_import_applyToRemainingFiles;

  /// No description provided for @vibe_import_applyNamingToRemainingFiles.
  ///
  /// In en, this message translates to:
  /// **'Use this naming rule for the remaining files'**
  String get vibe_import_applyNamingToRemainingFiles;

  /// No description provided for @vibe_encodeImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Encode Image as Vibe'**
  String get vibe_encodeImageTitle;

  /// No description provided for @vibe_imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image preview'**
  String get vibe_imagePreview;

  /// No description provided for @vibe_encodeStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Encoding'**
  String get vibe_encodeStartButton;

  /// No description provided for @vibe_encodeImageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Encoding image...'**
  String get vibe_encodeImageInProgress;

  /// No description provided for @vibe_encodeErrorImage.
  ///
  /// In en, this message translates to:
  /// **'Image: {fileName}'**
  String vibe_encodeErrorImage(Object fileName);

  /// No description provided for @vibe_encodeErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String vibe_encodeErrorMessage(Object error);

  /// No description provided for @vibe_encodeSkipImage.
  ///
  /// In en, this message translates to:
  /// **'Skip this image'**
  String get vibe_encodeSkipImage;

  /// No description provided for @detail_sendToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Send to Image2Image'**
  String get detail_sendToImg2Img;

  /// No description provided for @detail_loadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get detail_loadingImage;

  /// No description provided for @detail_imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get detail_imageLoadFailed;

  /// No description provided for @detail_noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get detail_noImage;

  /// No description provided for @detail_parsingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Parsing metadata...'**
  String get detail_parsingMetadata;

  /// No description provided for @detail_noMetadata.
  ///
  /// In en, this message translates to:
  /// **'This image has no metadata'**
  String get detail_noMetadata;

  /// No description provided for @detail_metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get detail_metadata;

  /// No description provided for @detail_imageDetails.
  ///
  /// In en, this message translates to:
  /// **'Image Details'**
  String get detail_imageDetails;

  /// No description provided for @detail_basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get detail_basicInfo;

  /// No description provided for @detail_fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get detail_fileName;

  /// No description provided for @detail_modifiedTime.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get detail_modifiedTime;

  /// No description provided for @detail_fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get detail_fileSize;

  /// No description provided for @detail_noContent.
  ///
  /// In en, this message translates to:
  /// **'(No content)'**
  String get detail_noContent;

  /// No description provided for @detail_saveBlock.
  ///
  /// In en, this message translates to:
  /// **'Save as Block'**
  String get detail_saveBlock;

  /// No description provided for @saveBlock_title.
  ///
  /// In en, this message translates to:
  /// **'Save as Block'**
  String get saveBlock_title;

  /// No description provided for @saveBlock_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block title'**
  String get saveBlock_nameLabel;

  /// No description provided for @saveBlock_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter block title'**
  String get saveBlock_nameHint;

  /// No description provided for @saveBlock_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a block title'**
  String get saveBlock_nameRequired;

  /// No description provided for @saveBlock_selectContent.
  ///
  /// In en, this message translates to:
  /// **'Select content to save'**
  String get saveBlock_selectContent;

  /// No description provided for @saveBlock_negativeSuffix.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get saveBlock_negativeSuffix;

  /// No description provided for @saveBlock_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to block library'**
  String get saveBlock_saved;

  /// No description provided for @detail_copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String detail_copyLabel(Object label);

  /// No description provided for @detail_copyCharacterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Character Prompt'**
  String get detail_copyCharacterPrompt;

  /// No description provided for @detail_copyAllVibeData.
  ///
  /// In en, this message translates to:
  /// **'Copy all Vibe data'**
  String get detail_copyAllVibeData;

  /// No description provided for @detail_saveToVibeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Vibe Library'**
  String get detail_saveToVibeLibrary;

  /// No description provided for @comfyImport_detectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Detected ComfyUI multi-character prompt'**
  String get comfyImport_detectedTitle;

  /// No description provided for @comfyImport_characterList.
  ///
  /// In en, this message translates to:
  /// **'Character List ({count})'**
  String comfyImport_characterList(Object count);

  /// No description provided for @comfyImport_usePositionInfo.
  ///
  /// In en, this message translates to:
  /// **'Use position information'**
  String get comfyImport_usePositionInfo;

  /// No description provided for @comfyImport_usePositionInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map ComfyUI regions to NAI character positions'**
  String get comfyImport_usePositionInfoSubtitle;

  /// No description provided for @comfyImport_convertCharacters.
  ///
  /// In en, this message translates to:
  /// **'Convert {count} characters'**
  String comfyImport_convertCharacters(Object count);

  /// No description provided for @comfyImport_syntaxCouple.
  ///
  /// In en, this message translates to:
  /// **'COUPLE syntax'**
  String get comfyImport_syntaxCouple;

  /// No description provided for @comfyImport_syntaxAndMask.
  ///
  /// In en, this message translates to:
  /// **'AND+MASK syntax'**
  String get comfyImport_syntaxAndMask;

  /// No description provided for @comfyImport_syntaxPipe.
  ///
  /// In en, this message translates to:
  /// **'Pipe format'**
  String get comfyImport_syntaxPipe;

  /// No description provided for @comfyImport_syntaxUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown syntax'**
  String get comfyImport_syntaxUnknown;

  /// No description provided for @comfyImport_globalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Global Prompt'**
  String get comfyImport_globalPrompt;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdate;

  /// No description provided for @neverChecked.
  ///
  /// In en, this message translates to:
  /// **'Never checked'**
  String get neverChecked;

  /// No description provided for @lastCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {time}'**
  String lastCheckedAt(Object time);

  /// No description provided for @includePrereleaseUpdates.
  ///
  /// In en, this message translates to:
  /// **'Include Prerelease Versions'**
  String get includePrereleaseUpdates;

  /// No description provided for @includePrereleaseUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Include beta/alpha versions when checking for updates'**
  String get includePrereleaseUpdatesDescription;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get updateChecking;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get updateDownloading;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Starting installer...'**
  String get updateInstalling;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get updateUpToDate;

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get updateError;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersion;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @updateDownloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading update package: {percent}%'**
  String updateDownloadingProgress(Object percent);

  /// No description provided for @updateDownloadSizeSpeed.
  ///
  /// In en, this message translates to:
  /// **'{received} / {total} · {speed}'**
  String updateDownloadSizeSpeed(Object received, Object total, Object speed);

  /// No description provided for @updateDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Update Package Ready'**
  String get updateDownloaded;

  /// No description provided for @updateDownloadedHint.
  ///
  /// In en, this message translates to:
  /// **'v{version} has been downloaded and verified. Installing will close the app and restart it automatically.'**
  String updateDownloadedHint(Object version);

  /// No description provided for @updateInstallAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Install and Restart'**
  String get updateInstallAndRestart;

  /// No description provided for @updateInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install Now'**
  String get updateInstallNow;

  /// No description provided for @updateInstallLater.
  ///
  /// In en, this message translates to:
  /// **'Install Later'**
  String get updateInstallLater;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Update'**
  String get updateDownload;

  /// No description provided for @updateDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled; you can resume later'**
  String get updateDownloadCancelled;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the update'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to install the update'**
  String get updateInstallFailed;

  /// No description provided for @updateInstallingHint.
  ///
  /// In en, this message translates to:
  /// **'The installer has started. The app will close and finish updating automatically.'**
  String get updateInstallingHint;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me in 4 Hours'**
  String get remindMeLater;

  /// No description provided for @updateNoticeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version v{version} is available'**
  String updateNoticeAvailable(Object version);

  /// No description provided for @updateNoticeAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download and finish the update automatically in the app'**
  String get updateNoticeAvailableSubtitle;

  /// No description provided for @updateNoticeManualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This platform must be updated manually from the Release page'**
  String get updateNoticeManualSubtitle;

  /// No description provided for @updateNoticeReady.
  ///
  /// In en, this message translates to:
  /// **'Version v{version} is ready'**
  String updateNoticeReady(Object version);

  /// No description provided for @updateNoticeReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The package is verified and ready to install on restart'**
  String get updateNoticeReadySubtitle;

  /// No description provided for @updateNoticeFailed.
  ///
  /// In en, this message translates to:
  /// **'The previous update did not finish'**
  String get updateNoticeFailed;

  /// No description provided for @updateViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Update'**
  String get updateViewDetails;

  /// No description provided for @updateSettingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'v{version} is available; select to view details'**
  String updateSettingsAvailable(Object version);

  /// No description provided for @updateSettingsReady.
  ///
  /// In en, this message translates to:
  /// **'v{version} is downloaded; select to install'**
  String updateSettingsReady(Object version);

  /// No description provided for @goToDownload.
  ///
  /// In en, this message translates to:
  /// **'Go to Download'**
  String get goToDownload;

  /// No description provided for @cannotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link'**
  String get cannotOpenUrl;

  /// No description provided for @model3d_editorTitle.
  ///
  /// In en, this message translates to:
  /// **'3D Model Layer'**
  String get model3d_editorTitle;

  /// No description provided for @model3d_modeTransform.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get model3d_modeTransform;

  /// No description provided for @model3d_modePose.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get model3d_modePose;

  /// No description provided for @model3d_gizmoTranslate.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get model3d_gizmoTranslate;

  /// No description provided for @model3d_gizmoRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get model3d_gizmoRotate;

  /// No description provided for @model3d_gizmoScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get model3d_gizmoScale;

  /// No description provided for @model3d_replaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the current model? Unapplied pose will be lost.'**
  String get model3d_replaceConfirm;

  /// No description provided for @model3d_discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard unapplied changes?'**
  String get model3d_discardConfirm;

  /// No description provided for @model3d_missingModel.
  ///
  /// In en, this message translates to:
  /// **'Model file is missing. You can re-import it.'**
  String get model3d_missingModel;

  /// No description provided for @model3d_loadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load model'**
  String get model3d_loadError;

  /// No description provided for @model3d_light.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get model3d_light;

  /// No description provided for @model3d_addLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add 3D Model Layer'**
  String get model3d_addLayerTooltip;

  /// No description provided for @nav_preciseRefLibrary.
  ///
  /// In en, this message translates to:
  /// **'Precise Ref Library'**
  String get nav_preciseRefLibrary;

  /// No description provided for @preciseRefLib_title.
  ///
  /// In en, this message translates to:
  /// **'Precise Reference Library'**
  String get preciseRefLib_title;

  /// No description provided for @preciseRefLib_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search references...'**
  String get preciseRefLib_searchHint;

  /// No description provided for @preciseRefLib_empty.
  ///
  /// In en, this message translates to:
  /// **'Drop or paste images here to build your library'**
  String get preciseRefLib_empty;

  /// No description provided for @preciseRefLib_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'You can also right-click images in preview, history, or gallery to save them here'**
  String get preciseRefLib_emptyHint;

  /// No description provided for @preciseRefLib_import.
  ///
  /// In en, this message translates to:
  /// **'Import Images'**
  String get preciseRefLib_import;

  /// No description provided for @preciseRefLib_entryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String preciseRefLib_entryCount(int count);

  /// No description provided for @preciseRefLib_sendToPreciseRef.
  ///
  /// In en, this message translates to:
  /// **'Send to Precise Reference'**
  String get preciseRefLib_sendToPreciseRef;

  /// No description provided for @preciseRefLib_sendToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Send to Image to Image'**
  String get preciseRefLib_sendToImg2Img;

  /// No description provided for @preciseRefLib_editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Parameters'**
  String get preciseRefLib_editEntry;

  /// No description provided for @preciseRefLib_confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get preciseRefLib_confirmDeleteTitle;

  /// No description provided for @preciseRefLib_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? The image file will also be removed.'**
  String preciseRefLib_confirmDelete(String name);

  /// No description provided for @preciseRefLib_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\" to Precise Ref Library'**
  String preciseRefLib_saved(String name);

  /// No description provided for @preciseRefLib_savedHint.
  ///
  /// In en, this message translates to:
  /// **'You can edit parameters in the library'**
  String get preciseRefLib_savedHint;

  /// No description provided for @preciseRefLib_sent.
  ///
  /// In en, this message translates to:
  /// **'Sent \"{name}\" to Precise Reference'**
  String preciseRefLib_sent(String name);

  /// No description provided for @preciseRefLib_sentToImg2Img.
  ///
  /// In en, this message translates to:
  /// **'Sent \"{name}\" to Image to Image'**
  String preciseRefLib_sentToImg2Img(String name);

  /// No description provided for @preciseRefLib_imageMissing.
  ///
  /// In en, this message translates to:
  /// **'Image file is missing'**
  String get preciseRefLib_imageMissing;

  /// No description provided for @preciseRefLib_invalidImage.
  ///
  /// In en, this message translates to:
  /// **'The image format is unsupported or the file is corrupt'**
  String get preciseRefLib_invalidImage;

  /// No description provided for @preciseRefLib_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed. The entry and original image were kept; try again later'**
  String get preciseRefLib_deleteFailed;

  /// No description provided for @preciseRefLib_favoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get preciseRefLib_favoritesOnly;

  /// No description provided for @preciseRefLib_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get preciseRefLib_sortBy;

  /// No description provided for @preciseRefLib_sortCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get preciseRefLib_sortCreatedAt;

  /// No description provided for @preciseRefLib_sortLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get preciseRefLib_sortLastUsed;

  /// No description provided for @preciseRefLib_sortUsedCount.
  ///
  /// In en, this message translates to:
  /// **'Most used'**
  String get preciseRefLib_sortUsedCount;

  /// No description provided for @preciseRefLib_sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get preciseRefLib_sortName;

  /// No description provided for @preciseRefLib_importedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} images'**
  String preciseRefLib_importedCount(int count);

  /// No description provided for @preciseRefLib_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the Precise Reference Library: {error}'**
  String preciseRefLib_loadFailed(String error);

  /// No description provided for @preciseRefLib_importFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save to the Precise Reference Library: {error}'**
  String preciseRefLib_importFailed(String error);

  /// No description provided for @preciseRefLib_importFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images could not be imported into the Precise Reference Library'**
  String preciseRefLib_importFailedCount(int count);

  /// No description provided for @preciseRefLib_fromLibrary.
  ///
  /// In en, this message translates to:
  /// **'From Library'**
  String get preciseRefLib_fromLibrary;

  /// No description provided for @preciseRefLib_saveCurrentToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get preciseRefLib_saveCurrentToLibrary;

  /// No description provided for @preciseRefLib_saveCurrentCount.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} references to library'**
  String preciseRefLib_saveCurrentCount(int count);

  /// No description provided for @preciseRefLib_selectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select from Precise Ref Library'**
  String get preciseRefLib_selectorTitle;

  /// No description provided for @preciseRefLib_selectorConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add Selected ({count})'**
  String preciseRefLib_selectorConfirm(int count);

  /// No description provided for @preciseRefLib_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get preciseRefLib_nameLabel;

  /// No description provided for @preciseRefLib_typeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get preciseRefLib_typeFilterAll;

  /// No description provided for @img2img_fromPreciseRefLibrary.
  ///
  /// In en, this message translates to:
  /// **'From Precise Ref Library'**
  String get img2img_fromPreciseRefLibrary;

  /// No description provided for @localGallery_saveToPreciseRefLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Precise Ref Library'**
  String get localGallery_saveToPreciseRefLibrary;

  /// No description provided for @drop_saveToPreciseRefLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Precise Ref Library'**
  String get drop_saveToPreciseRefLibrary;

  /// No description provided for @common_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get common_enabled;

  /// No description provided for @common_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get common_disabled;

  /// No description provided for @bulkAction_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bulkAction_selectedCount(int count);

  /// No description provided for @comfyTask_errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the ComfyUI server'**
  String get comfyTask_errorConnectionFailed;

  /// No description provided for @comfyTask_errorConnectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The ComfyUI connection is unavailable'**
  String get comfyTask_errorConnectionUnavailable;

  /// No description provided for @comfyTask_errorExecutionFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI execution failed'**
  String get comfyTask_errorExecutionFailedGeneric;

  /// No description provided for @comfyTask_errorExecutionFailed.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI execution failed: {error}'**
  String comfyTask_errorExecutionFailed(String error);

  /// No description provided for @comfyTask_errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The ComfyUI task timed out after 10 minutes'**
  String get comfyTask_errorTimeout;

  /// No description provided for @comfyTask_errorWorkflowNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workflow not found: {workflowId}'**
  String comfyTask_errorWorkflowNotFound(String workflowId);

  /// No description provided for @comfyWorkflowSlot_vaeEncodeTileSize.
  ///
  /// In en, this message translates to:
  /// **'VAE encode tile size'**
  String get comfyWorkflowSlot_vaeEncodeTileSize;

  /// No description provided for @comfyWorkflowSlot_vaeDecodeTileSize.
  ///
  /// In en, this message translates to:
  /// **'VAE decode tile size'**
  String get comfyWorkflowSlot_vaeDecodeTileSize;

  /// No description provided for @comfyWorkflowSlot_blocksToSwap.
  ///
  /// In en, this message translates to:
  /// **'Blocks to swap'**
  String get comfyWorkflowSlot_blocksToSwap;

  /// No description provided for @comfyWorkflowSlot_swapIoComponents.
  ///
  /// In en, this message translates to:
  /// **'Swap I/O components'**
  String get comfyWorkflowSlot_swapIoComponents;

  /// No description provided for @localGallery_firstIndexHint.
  ///
  /// In en, this message translates to:
  /// **'Detected {count} images. The initial index may take a few minutes; you can continue using the app.'**
  String localGallery_firstIndexHint(int count);

  /// No description provided for @localGallery_errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Unable to access the image folder. Check the folder permissions.'**
  String get localGallery_errorPermissionDenied;

  /// No description provided for @localGallery_errorScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan images: {error}'**
  String localGallery_errorScanFailed(String error);

  /// No description provided for @localGallery_errorInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize the gallery: {error}'**
  String localGallery_errorInitializationFailed(String error);

  /// No description provided for @localGallery_errorServiceInitializing.
  ///
  /// In en, this message translates to:
  /// **'The gallery service is still initializing. Try again shortly.'**
  String get localGallery_errorServiceInitializing;

  /// No description provided for @localGallery_errorDatabaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Gallery database error: {error}'**
  String localGallery_errorDatabaseFailed(String error);

  /// No description provided for @localGallery_errorRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the gallery: {error}'**
  String localGallery_errorRefreshFailed(String error);

  /// No description provided for @localGallery_errorFilterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply gallery filters: {error}'**
  String localGallery_errorFilterFailed(String error);

  /// No description provided for @localGallery_errorFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the favorite status: {error}'**
  String localGallery_errorFavoriteFailed(String error);

  /// No description provided for @localGallery_errorRebuildFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rebuild the gallery index: {error}'**
  String localGallery_errorRebuildFailed(String error);

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get common_optional;

  /// No description provided for @common_emptyValue.
  ///
  /// In en, this message translates to:
  /// **'(Empty)'**
  String get common_emptyValue;

  /// No description provided for @common_clickToRetry.
  ///
  /// In en, this message translates to:
  /// **'Click to retry'**
  String get common_clickToRetry;

  /// No description provided for @common_opening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get common_opening;

  /// No description provided for @common_swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get common_swap;

  /// No description provided for @addToLibrary_displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name to identify this entry'**
  String get addToLibrary_displayNameHint;

  /// No description provided for @addToLibrary_tagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag and press Enter to add it'**
  String get addToLibrary_tagHint;

  /// No description provided for @drop_saveVibeBundle.
  ///
  /// In en, this message translates to:
  /// **'Save Vibe Bundle'**
  String get drop_saveVibeBundle;

  /// No description provided for @history_dragFilePreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to prepare the drag file. Try again later.'**
  String get history_dragFilePreparationFailed;

  /// No description provided for @history_dragFilePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the drag file...'**
  String get history_dragFilePreparing;

  /// No description provided for @history_dragFileNotReady.
  ///
  /// In en, this message translates to:
  /// **'The drag file is not ready yet'**
  String get history_dragFileNotReady;

  /// No description provided for @vibe_import_overwriteOriginalParams.
  ///
  /// In en, this message translates to:
  /// **'Replace Original Vibe Parameters'**
  String get vibe_import_overwriteOriginalParams;

  /// No description provided for @vibe_import_overwriteOriginalParamsHint.
  ///
  /// In en, this message translates to:
  /// **'Only replace the library parameters for {name}; disabled by default'**
  String vibe_import_overwriteOriginalParamsHint(String name);

  /// No description provided for @vibe_import_reencodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to re-encode Vibe: {name}'**
  String vibe_import_reencodeFailed(String name);

  /// No description provided for @galleryScan_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed {count}'**
  String galleryScan_failed(int count);

  /// No description provided for @galleryScan_organizingGallery.
  ///
  /// In en, this message translates to:
  /// **'Organizing gallery'**
  String get galleryScan_organizingGallery;

  /// No description provided for @galleryScan_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get galleryScan_processing;

  /// No description provided for @vibeDetail_useAll.
  ///
  /// In en, this message translates to:
  /// **'Use All'**
  String get vibeDetail_useAll;

  /// No description provided for @vibeDetail_longPressSetCover.
  ///
  /// In en, this message translates to:
  /// **'Long-press to set as cover'**
  String get vibeDetail_longPressSetCover;

  /// No description provided for @vibeDetail_noPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'No preview image'**
  String get vibeDetail_noPreviewImage;

  /// No description provided for @vibeDetail_dropPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Drop an image here to set the preview'**
  String get vibeDetail_dropPreviewImage;

  /// No description provided for @vibeDetail_releasePreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Release to set the preview image'**
  String get vibeDetail_releasePreviewImage;

  /// No description provided for @imagePicker_dropReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the dropped image: {error}'**
  String imagePicker_dropReadFailed(String error);

  /// No description provided for @imagePicker_dropNoReadableImage.
  ///
  /// In en, this message translates to:
  /// **'The dropped data does not contain a readable image file or image URL'**
  String get imagePicker_dropNoReadableImage;

  /// No description provided for @imagePicker_fileDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to read file data'**
  String get imagePicker_fileDataUnavailable;

  /// No description provided for @imagePicker_fileSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select file: {error}'**
  String imagePicker_fileSelectionFailed(String error);

  /// No description provided for @imagePicker_directorySelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select directory: {error}'**
  String imagePicker_directorySelectionFailed(String error);

  /// No description provided for @editor_shiftEdges.
  ///
  /// In en, this message translates to:
  /// **'Shift Edges'**
  String get editor_shiftEdges;

  /// No description provided for @editor_edgeLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get editor_edgeLeft;

  /// No description provided for @editor_edgeRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get editor_edgeRight;

  /// No description provided for @editor_edgeTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get editor_edgeTop;

  /// No description provided for @editor_edgeBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get editor_edgeBottom;

  /// No description provided for @editor_enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get editor_enterNumber;

  /// No description provided for @onlineGallery_videoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get onlineGallery_videoLoadFailed;

  /// No description provided for @vibe_releaseToAddStyleReference.
  ///
  /// In en, this message translates to:
  /// **'Release to add style reference'**
  String get vibe_releaseToAddStyleReference;

  /// No description provided for @router_pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {error}'**
  String router_pageNotFound(String error);

  /// No description provided for @autocomplete_resultLimit.
  ///
  /// In en, this message translates to:
  /// **'Result count'**
  String get autocomplete_resultLimit;

  /// No description provided for @autocomplete_relatedTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Expansion'**
  String get autocomplete_relatedTagsTitle;

  /// No description provided for @autocomplete_relatedTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+click to search local tags; Ctrl+drag to explore related tags'**
  String get autocomplete_relatedTagsSubtitle;

  /// No description provided for @tagExpansion_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags or aliases'**
  String get tagExpansion_searchHint;

  /// No description provided for @tagExpansion_relatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Related tags'**
  String get tagExpansion_relatedTitle;

  /// No description provided for @tagExpansion_empty.
  ///
  /// In en, this message translates to:
  /// **'Type to search local tags'**
  String get tagExpansion_empty;

  /// No description provided for @tagExpansion_noResults.
  ///
  /// In en, this message translates to:
  /// **'No local tags found'**
  String get tagExpansion_noResults;

  /// No description provided for @tagExpansion_insert.
  ///
  /// In en, this message translates to:
  /// **'Insert tag'**
  String get tagExpansion_insert;

  /// No description provided for @tagExpansion_showRelated.
  ///
  /// In en, this message translates to:
  /// **'Show related tags'**
  String get tagExpansion_showRelated;

  /// No description provided for @tagExpansion_localOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get tagExpansion_localOnly;

  /// No description provided for @tagExpansion_popularSource.
  ///
  /// In en, this message translates to:
  /// **'Popular local tags'**
  String get tagExpansion_popularSource;

  /// No description provided for @tagExpansion_tabComplete.
  ///
  /// In en, this message translates to:
  /// **'Tab to complete:'**
  String get tagExpansion_tabComplete;

  /// No description provided for @tagExpansion_wikiTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag wiki'**
  String get tagExpansion_wikiTitle;

  /// No description provided for @tagExpansion_wikiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No local article for this tag yet.'**
  String get tagExpansion_wikiUnavailable;

  /// No description provided for @autocomplete_cooccurrence.
  ///
  /// In en, this message translates to:
  /// **'Offline related-tag database'**
  String get autocomplete_cooccurrence;

  /// No description provided for @autocomplete_entryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String autocomplete_entryCount(int count);

  /// No description provided for @autocomplete_clearDanbooruCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Danbooru cache'**
  String get autocomplete_clearDanbooruCache;

  /// No description provided for @autocomplete_clearAiCache.
  ///
  /// In en, this message translates to:
  /// **'Clear AI translation cache'**
  String get autocomplete_clearAiCache;

  /// No description provided for @autocomplete_cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} cached entries'**
  String autocomplete_cacheCleared(int count);

  /// No description provided for @autocomplete_baseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Base Danbooru catalog'**
  String get autocomplete_baseCatalog;

  /// No description provided for @autocomplete_catalogStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} tags · data version {version}'**
  String autocomplete_catalogStatus(String count, String version);

  /// No description provided for @nav_promptBlockLibrary.
  ///
  /// In en, this message translates to:
  /// **'Prompt Blocks'**
  String get nav_promptBlockLibrary;

  /// No description provided for @promptBlockLibrary_title.
  ///
  /// In en, this message translates to:
  /// **'Prompt Blocks'**
  String get promptBlockLibrary_title;

  /// No description provided for @promptBlockLibrary_folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get promptBlockLibrary_folders;

  /// No description provided for @promptBlockLibrary_allBlocks.
  ///
  /// In en, this message translates to:
  /// **'All blocks'**
  String get promptBlockLibrary_allBlocks;

  /// No description provided for @promptBlockLibrary_rootFolder.
  ///
  /// In en, this message translates to:
  /// **'Root / Unfiled'**
  String get promptBlockLibrary_rootFolder;

  /// No description provided for @promptBlockLibrary_unnamedBlock.
  ///
  /// In en, this message translates to:
  /// **'Untitled block'**
  String get promptBlockLibrary_unnamedBlock;

  /// No description provided for @promptBlockLibrary_noBlockSelected.
  ///
  /// In en, this message translates to:
  /// **'No block selected'**
  String get promptBlockLibrary_noBlockSelected;

  /// No description provided for @promptBlockLibrary_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get promptBlockLibrary_details;

  /// No description provided for @promptBlockLibrary_useCount.
  ///
  /// In en, this message translates to:
  /// **'Used {count} times'**
  String promptBlockLibrary_useCount(int count);

  /// No description provided for @promptBlockPill_missing.
  ///
  /// In en, this message translates to:
  /// **'Block deleted'**
  String get promptBlockPill_missing;

  /// No description provided for @promptBlockPill_unknown.
  ///
  /// In en, this message translates to:
  /// **'Invalid block'**
  String get promptBlockPill_unknown;

  /// No description provided for @pillCardReroll.
  ///
  /// In en, this message translates to:
  /// **'Re-roll'**
  String get pillCardReroll;

  /// No description provided for @pillCardRerollLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked; re-roll unavailable'**
  String get pillCardRerollLocked;

  /// No description provided for @pillCardLock.
  ///
  /// In en, this message translates to:
  /// **'Lock current roll'**
  String get pillCardLock;

  /// No description provided for @pillCardUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get pillCardUnlock;

  /// No description provided for @pillCardSettings.
  ///
  /// In en, this message translates to:
  /// **'Random settings'**
  String get pillCardSettings;

  /// No description provided for @pillCardEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get pillCardEnable;

  /// No description provided for @pillCardDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get pillCardDisable;

  /// No description provided for @pillCardDeleteInstance.
  ///
  /// In en, this message translates to:
  /// **'Remove instance'**
  String get pillCardDeleteInstance;

  /// No description provided for @pillCardEmptyRoll.
  ///
  /// In en, this message translates to:
  /// **'(empty roll this time)'**
  String get pillCardEmptyRoll;

  /// No description provided for @pillCardEvolutionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable evolution'**
  String get pillCardEvolutionEnable;

  /// No description provided for @pillCardEvolutionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable evolution'**
  String get pillCardEvolutionDisable;

  /// No description provided for @pillCardEvolutionRequiresEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable the instance first'**
  String get pillCardEvolutionRequiresEnabled;

  /// No description provided for @pillCardStepBack.
  ///
  /// In en, this message translates to:
  /// **'Step back one scene'**
  String get pillCardStepBack;

  /// No description provided for @pillCardStepForward.
  ///
  /// In en, this message translates to:
  /// **'Step forward one scene'**
  String get pillCardStepForward;

  /// No description provided for @pillSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Block instance settings'**
  String get pillSettingsTitle;

  /// No description provided for @pillSettingsModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get pillSettingsModeFixed;

  /// No description provided for @pillSettingsModeSequential.
  ///
  /// In en, this message translates to:
  /// **'Sequential'**
  String get pillSettingsModeSequential;

  /// No description provided for @pillSettingsModeRandom.
  ///
  /// In en, this message translates to:
  /// **'Random draw'**
  String get pillSettingsModeRandom;

  /// No description provided for @pillSettingsCount.
  ///
  /// In en, this message translates to:
  /// **'Draw count'**
  String get pillSettingsCount;

  /// No description provided for @pillSettingsOrder.
  ///
  /// In en, this message translates to:
  /// **'Output order'**
  String get pillSettingsOrder;

  /// No description provided for @pillSettingsOrderDrawn.
  ///
  /// In en, this message translates to:
  /// **'As drawn'**
  String get pillSettingsOrderDrawn;

  /// No description provided for @pillSettingsOrderOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original order'**
  String get pillSettingsOrderOriginal;

  /// No description provided for @pillSettingsWeight.
  ///
  /// In en, this message translates to:
  /// **'Random weight'**
  String get pillSettingsWeight;

  /// No description provided for @pillSettingsWeightMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get pillSettingsWeightMin;

  /// No description provided for @pillSettingsWeightMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get pillSettingsWeightMax;

  /// No description provided for @pillSettingsWeightAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get pillSettingsWeightAverage;

  /// No description provided for @pillSettingsDispersion.
  ///
  /// In en, this message translates to:
  /// **'Dispersion'**
  String get pillSettingsDispersion;

  /// No description provided for @pillSettingsDispersionFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get pillSettingsDispersionFocused;

  /// No description provided for @pillSettingsDispersionBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get pillSettingsDispersionBalanced;

  /// No description provided for @pillSettingsDispersionSpread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get pillSettingsDispersionSpread;

  /// No description provided for @pillSettingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get pillSettingsAdvanced;

  /// No description provided for @pillSettingsLeftDispersion.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get pillSettingsLeftDispersion;

  /// No description provided for @pillSettingsRightDispersion.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get pillSettingsRightDispersion;

  /// No description provided for @pillSettingsSoftBalance.
  ///
  /// In en, this message translates to:
  /// **'Soft balance'**
  String get pillSettingsSoftBalance;

  /// No description provided for @pillSettingsSoftBalanceStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get pillSettingsSoftBalanceStrength;

  /// No description provided for @pillSettingsTriggerProbability.
  ///
  /// In en, this message translates to:
  /// **'Trigger chance'**
  String get pillSettingsTriggerProbability;

  /// No description provided for @pillSettingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pillSettingsCancel;

  /// No description provided for @pillSettingsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get pillSettingsApply;

  /// No description provided for @promptBlockLibrary_unnamedFolder.
  ///
  /// In en, this message translates to:
  /// **'Untitled folder'**
  String get promptBlockLibrary_unnamedFolder;

  /// No description provided for @promptBlockLibrary_scope.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get promptBlockLibrary_scope;

  /// No description provided for @promptBlockLibrary_newBlock.
  ///
  /// In en, this message translates to:
  /// **'New block'**
  String get promptBlockLibrary_newBlock;

  /// No description provided for @promptBlockLibrary_editBlock.
  ///
  /// In en, this message translates to:
  /// **'Edit block'**
  String get promptBlockLibrary_editBlock;

  /// No description provided for @promptBlockLibrary_newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get promptBlockLibrary_newFolder;

  /// No description provided for @promptBlockLibrary_newSubfolder.
  ///
  /// In en, this message translates to:
  /// **'New subfolder'**
  String get promptBlockLibrary_newSubfolder;

  /// No description provided for @promptBlockLibrary_renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get promptBlockLibrary_renameFolder;

  /// No description provided for @promptBlockLibrary_moveToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to root'**
  String get promptBlockLibrary_moveToRoot;

  /// No description provided for @promptBlockLibrary_moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get promptBlockLibrary_moveToFolder;

  /// No description provided for @promptBlockLibrary_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get promptBlockLibrary_favorites;

  /// No description provided for @promptBlockLibrary_unclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get promptBlockLibrary_unclassified;

  /// No description provided for @promptBlockLibrary_newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get promptBlockLibrary_newCollection;

  /// No description provided for @promptBlockLibrary_newSubcollection.
  ///
  /// In en, this message translates to:
  /// **'New sub-collection'**
  String get promptBlockLibrary_newSubcollection;

  /// No description provided for @promptBlockLibrary_newCollectionFolder.
  ///
  /// In en, this message translates to:
  /// **'New collection folder'**
  String get promptBlockLibrary_newCollectionFolder;

  /// No description provided for @promptBlockLibrary_renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename collection'**
  String get promptBlockLibrary_renameCollection;

  /// No description provided for @promptBlockLibrary_renameCollectionFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename collection folder'**
  String get promptBlockLibrary_renameCollectionFolder;

  /// No description provided for @promptBlockLibrary_moveToFavoritesRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to favorites root'**
  String get promptBlockLibrary_moveToFavoritesRoot;

  /// No description provided for @promptBlockLibrary_unnamedCollection.
  ///
  /// In en, this message translates to:
  /// **'Unnamed collection'**
  String get promptBlockLibrary_unnamedCollection;

  /// No description provided for @promptBlockLibrary_unnamedCollectionFolder.
  ///
  /// In en, this message translates to:
  /// **'Unnamed collection folder'**
  String get promptBlockLibrary_unnamedCollectionFolder;

  /// No description provided for @promptBlockLibrary_collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get promptBlockLibrary_collectionName;

  /// No description provided for @promptBlockLibrary_collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get promptBlockLibrary_collectionNameHint;

  /// No description provided for @promptBlockLibrary_noCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections yet — use the + next to Favorites, or drag a block onto a collection'**
  String get promptBlockLibrary_noCollections;

  /// No description provided for @promptBlockLibrary_noFolders.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get promptBlockLibrary_noFolders;

  /// No description provided for @promptBlockLibrary_emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite blocks yet — tap the ★ on a block to favorite it'**
  String get promptBlockLibrary_emptyFavorites;

  /// No description provided for @promptBlockLibrary_emptyCollection.
  ///
  /// In en, this message translates to:
  /// **'This collection is empty'**
  String get promptBlockLibrary_emptyCollection;

  /// No description provided for @promptBlockLibrary_deleteCollectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete collection \"{name}\"? Blocks inside are not deleted, only unlinked from the collection.'**
  String promptBlockLibrary_deleteCollectionConfirm(String name);

  /// No description provided for @promptBlockLibrary_deleteCollectionFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete collection folder \"{name}\"? Its collections and sub-folders are deleted too; the blocks themselves are unaffected.'**
  String promptBlockLibrary_deleteCollectionFolderConfirm(String name);

  /// No description provided for @promptBlockLibrary_blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get promptBlockLibrary_blockTitle;

  /// No description provided for @promptBlockLibrary_titleHint.
  ///
  /// In en, this message translates to:
  /// **'Block title'**
  String get promptBlockLibrary_titleHint;

  /// No description provided for @promptBlockLibrary_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, prompt, or tag'**
  String get promptBlockLibrary_searchHint;

  /// No description provided for @promptBlockLibrary_folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get promptBlockLibrary_folder;

  /// No description provided for @promptBlockLibrary_folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get promptBlockLibrary_folderName;

  /// No description provided for @promptBlockLibrary_folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get promptBlockLibrary_folderNameHint;

  /// No description provided for @promptBlockLibrary_basicPrompt.
  ///
  /// In en, this message translates to:
  /// **'Base Prompt'**
  String get promptBlockLibrary_basicPrompt;

  /// No description provided for @promptBlockLibrary_generationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get promptBlockLibrary_generationSettings;

  /// No description provided for @promptBlockLibrary_settingsOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Only filled parameters are saved. Apply settings manually after inserting the block.'**
  String get promptBlockLibrary_settingsOptionalHint;

  /// No description provided for @promptBlockLibrary_notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get promptBlockLibrary_notSpecified;

  /// No description provided for @promptBlockLibrary_stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get promptBlockLibrary_stepsLabel;

  /// No description provided for @promptBlockLibrary_noiseScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Noise Schedule'**
  String get promptBlockLibrary_noiseScheduleLabel;

  /// No description provided for @promptBlockLibrary_invalidGenerationSettings.
  ///
  /// In en, this message translates to:
  /// **'Check settings: steps 1–50, Prompt Guidance 1–20, Prompt Guidance Rescale 0–1, and model compatibility.'**
  String get promptBlockLibrary_invalidGenerationSettings;

  /// No description provided for @promptBlockLibrary_applySettings.
  ///
  /// In en, this message translates to:
  /// **'Import settings'**
  String get promptBlockLibrary_applySettings;

  /// No description provided for @promptBlockLibrary_settingsApplied.
  ///
  /// In en, this message translates to:
  /// **'Block settings imported to the current image'**
  String get promptBlockLibrary_settingsApplied;

  /// No description provided for @promptBlockLibrary_settingsIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Block settings are incompatible with the target model. No parameters were imported.'**
  String get promptBlockLibrary_settingsIncompatible;

  /// No description provided for @promptBlockLibrary_noSettings.
  ///
  /// In en, this message translates to:
  /// **'No generation settings saved'**
  String get promptBlockLibrary_noSettings;

  /// No description provided for @promptBlockLibrary_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get promptBlockLibrary_tags;

  /// No description provided for @promptBlockLibrary_addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get promptBlockLibrary_addTag;

  /// No description provided for @promptBlockLibrary_tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get promptBlockLibrary_tagName;

  /// No description provided for @promptBlockLibrary_tagColor.
  ///
  /// In en, this message translates to:
  /// **'Tag color (hex)'**
  String get promptBlockLibrary_tagColor;

  /// No description provided for @promptBlockLibrary_duplicateTag.
  ///
  /// In en, this message translates to:
  /// **'This block already has a tag with that name'**
  String get promptBlockLibrary_duplicateTag;

  /// No description provided for @promptBlockLibrary_invalidTagColor.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hex color'**
  String get promptBlockLibrary_invalidTagColor;

  /// No description provided for @pillCard_rollScope.
  ///
  /// In en, this message translates to:
  /// **'Variation scope'**
  String get pillCard_rollScope;

  /// No description provided for @pillCard_positiveScope.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get pillCard_positiveScope;

  /// No description provided for @pillCard_negativeScope.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get pillCard_negativeScope;

  /// No description provided for @promptBlockLibrary_modelResetNotice.
  ///
  /// In en, this message translates to:
  /// **'Unsupported values were cleared after changing the model.'**
  String get promptBlockLibrary_modelResetNotice;

  /// No description provided for @promptBlockLibrary_atomInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type text, press Enter to make an atom'**
  String get promptBlockLibrary_atomInputHint;

  /// No description provided for @promptBlockLibrary_atomRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Click to restore as editable text'**
  String get promptBlockLibrary_atomRestoreHint;

  /// No description provided for @promptBlockLibrary_atomOrphan.
  ///
  /// In en, this message translates to:
  /// **'Unknown marker'**
  String get promptBlockLibrary_atomOrphan;

  /// No description provided for @promptBlockLibrary_atomEditorTutorial.
  ///
  /// In en, this message translates to:
  /// **'Enter makes a block, click a block to restore text; unblocked text becomes atoms on save.'**
  String get promptBlockLibrary_atomEditorTutorial;

  /// No description provided for @promptBlockLibrary_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get promptBlockLibrary_color;

  /// No description provided for @promptBlockLibrary_icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get promptBlockLibrary_icon;

  /// No description provided for @promptBlockLibrary_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get promptBlockLibrary_saved;

  /// No description provided for @promptBlockLibrary_copied.
  ///
  /// In en, this message translates to:
  /// **'Content copied'**
  String get promptBlockLibrary_copied;

  /// No description provided for @promptBlockLibrary_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get promptBlockLibrary_deleted;

  /// No description provided for @promptBlockLibrary_multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get promptBlockLibrary_multiSelect;

  /// No description provided for @promptBlockLibrary_exitMultiSelect.
  ///
  /// In en, this message translates to:
  /// **'Exit multi-select'**
  String get promptBlockLibrary_exitMultiSelect;

  /// No description provided for @promptBlockLibrary_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String promptBlockLibrary_selectedCount(int count);

  /// No description provided for @promptBlockLibrary_selectAllVisible.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get promptBlockLibrary_selectAllVisible;

  /// No description provided for @promptBlockLibrary_clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get promptBlockLibrary_clearSelection;

  /// No description provided for @promptBlockLibrary_moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get promptBlockLibrary_moveTo;

  /// No description provided for @promptBlockLibrary_moveToFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get promptBlockLibrary_moveToFolderTitle;

  /// No description provided for @promptBlockLibrary_deleteBlocksConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected blocks? This cannot be undone.'**
  String promptBlockLibrary_deleteBlocksConfirm(int count);

  /// No description provided for @promptBlockLibrary_deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected blocks'**
  String promptBlockLibrary_deleteSelected(int count);

  /// No description provided for @promptBlockLibrary_empty.
  ///
  /// In en, this message translates to:
  /// **'No prompt blocks yet'**
  String get promptBlockLibrary_empty;

  /// No description provided for @promptBlockLibrary_emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get promptBlockLibrary_emptyFolder;

  /// No description provided for @promptBlockLibrary_noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching blocks'**
  String get promptBlockLibrary_noSearchResults;

  /// No description provided for @promptBlockLibrary_tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get promptBlockLibrary_tryDifferentSearch;

  /// No description provided for @promptBlockLibrary_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create a block to start organizing reusable text'**
  String get promptBlockLibrary_emptyHint;

  /// No description provided for @promptBlockLibrary_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prompt blocks: {error}'**
  String promptBlockLibrary_loadFailed(String error);

  /// No description provided for @promptBlockLibrary_deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete folder \"{name}\"?'**
  String promptBlockLibrary_deleteFolderTitle(Object name);

  /// No description provided for @promptBlockLibrary_deleteFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what to do with blocks inside this folder and its subfolders.'**
  String get promptBlockLibrary_deleteFolderDescription;

  /// No description provided for @promptBlockLibrary_moveContentsToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move contents to root'**
  String get promptBlockLibrary_moveContentsToRoot;

  /// No description provided for @promptBlockLibrary_moveContentsToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move contents to another folder'**
  String get promptBlockLibrary_moveContentsToFolder;

  /// No description provided for @promptBlockLibrary_destinationFolder.
  ///
  /// In en, this message translates to:
  /// **'Destination folder'**
  String get promptBlockLibrary_destinationFolder;

  /// No description provided for @promptBlockLibrary_deleteContents.
  ///
  /// In en, this message translates to:
  /// **'Delete contents'**
  String get promptBlockLibrary_deleteContents;

  /// No description provided for @promptBlockLibrary_deleteContentsWarning.
  ///
  /// In en, this message translates to:
  /// **'This also permanently deletes all blocks in the folder tree.'**
  String get promptBlockLibrary_deleteContentsWarning;

  /// No description provided for @promptBlockLibrary_importExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get promptBlockLibrary_importExport;

  /// No description provided for @promptBlockLibrary_importTxtFiles.
  ///
  /// In en, this message translates to:
  /// **'Import TXT files'**
  String get promptBlockLibrary_importTxtFiles;

  /// No description provided for @promptBlockLibrary_importFromFolder.
  ///
  /// In en, this message translates to:
  /// **'Import from folder…'**
  String get promptBlockLibrary_importFromFolder;

  /// No description provided for @promptBlockLibrary_exportLibraryBackup.
  ///
  /// In en, this message translates to:
  /// **'Export library backup…'**
  String get promptBlockLibrary_exportLibraryBackup;

  /// No description provided for @promptBlockLibrary_importLibraryBackup.
  ///
  /// In en, this message translates to:
  /// **'Import library backup…'**
  String get promptBlockLibrary_importLibraryBackup;

  /// No description provided for @promptBlockLibrary_importTxtTitle.
  ///
  /// In en, this message translates to:
  /// **'Select TXT files'**
  String get promptBlockLibrary_importTxtTitle;

  /// No description provided for @promptBlockLibrary_txtImportDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {created} blocks, skipped {skipped} existing sources'**
  String promptBlockLibrary_txtImportDone(int created, int skipped);

  /// No description provided for @promptBlockLibrary_curationTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from folder'**
  String get promptBlockLibrary_curationTitle;

  /// No description provided for @promptBlockLibrary_curationSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} TXT files: {created} new · {skipped} unchanged · {changed} changed'**
  String promptBlockLibrary_curationSummary(
    int total,
    int created,
    int skipped,
    int changed,
  );

  /// No description provided for @promptBlockLibrary_curationLocalModifiedHint.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks were manually edited after import; updating overwrites local edits'**
  String promptBlockLibrary_curationLocalModifiedHint(int count);

  /// No description provided for @promptBlockLibrary_curationUpdateChanged.
  ///
  /// In en, this message translates to:
  /// **'Update changed blocks with file content'**
  String get promptBlockLibrary_curationUpdateChanged;

  /// No description provided for @promptBlockLibrary_curationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No TXT files in the selected folder'**
  String get promptBlockLibrary_curationEmpty;

  /// No description provided for @promptBlockLibrary_curationDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {created} created · {updated} updated · {skipped} skipped'**
  String promptBlockLibrary_curationDone(int created, int updated, int skipped);

  /// No description provided for @promptBlockLibrary_curationNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get promptBlockLibrary_curationNew;

  /// No description provided for @promptBlockLibrary_curationUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get promptBlockLibrary_curationUnchanged;

  /// No description provided for @promptBlockLibrary_curationChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get promptBlockLibrary_curationChanged;

  /// No description provided for @promptBlockLibrary_curationLocalModified.
  ///
  /// In en, this message translates to:
  /// **'Locally modified'**
  String get promptBlockLibrary_curationLocalModified;

  /// No description provided for @promptBlockLibrary_libraryBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Exported backup with {count} blocks'**
  String promptBlockLibrary_libraryBackupDone(int count);

  /// No description provided for @promptBlockLibrary_libraryImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Select library backup'**
  String get promptBlockLibrary_libraryImportTitle;

  /// No description provided for @promptBlockLibrary_libraryBackupInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid block library backup'**
  String get promptBlockLibrary_libraryBackupInvalid;

  /// No description provided for @promptBlockLibrary_libraryImportDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {blocks} blocks and {folders} folders, skipped {skipped} existing'**
  String promptBlockLibrary_libraryImportDone(
    int blocks,
    int folders,
    int skipped,
  );

  /// No description provided for @promptBlockLibrary_importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String promptBlockLibrary_importFailed(String error);

  /// No description provided for @promptBlockLibrary_sourceFile.
  ///
  /// In en, this message translates to:
  /// **'Source file'**
  String get promptBlockLibrary_sourceFile;

  /// No description provided for @promptBlockLibrary_importedAt.
  ///
  /// In en, this message translates to:
  /// **'Imported at'**
  String get promptBlockLibrary_importedAt;

  /// No description provided for @promptBlockLibrary_listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get promptBlockLibrary_listView;

  /// No description provided for @promptBlockLibrary_gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get promptBlockLibrary_gridView;

  /// No description provided for @promptBlockLibrary_waterfallView.
  ///
  /// In en, this message translates to:
  /// **'Waterfall view'**
  String get promptBlockLibrary_waterfallView;

  /// No description provided for @promptBlockPalette_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get promptBlockPalette_tooltip;

  /// No description provided for @promptBlockPalette_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep prompt blocks or translation blocks here; click to insert at the caret, or drag them into the prompt box.'**
  String get promptBlockPalette_emptyHint;

  /// No description provided for @promptBlockPalette_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove from blocks'**
  String get promptBlockPalette_remove;

  /// No description provided for @promptBlockPalette_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear blocks'**
  String get promptBlockPalette_clearAll;

  /// No description provided for @promptBlockPalette_clearAllArmed.
  ///
  /// In en, this message translates to:
  /// **'Tap again to clear all'**
  String get promptBlockPalette_clearAllArmed;

  /// No description provided for @promptBlockPalette_removeSelected.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} selected'**
  String promptBlockPalette_removeSelected(int count);

  /// No description provided for @promptBlockLibrary_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get promptBlockLibrary_sortBy;

  /// No description provided for @promptBlockLibrary_sortCustom.
  ///
  /// In en, this message translates to:
  /// **'Default (manual order)'**
  String get promptBlockLibrary_sortCustom;

  /// No description provided for @promptBlockLibrary_sortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get promptBlockLibrary_sortUpdated;

  /// No description provided for @promptBlockLibrary_sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get promptBlockLibrary_sortTitle;

  /// No description provided for @promptBlockLibrary_sortColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get promptBlockLibrary_sortColor;

  /// No description provided for @promptBlockLibrary_sortIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get promptBlockLibrary_sortIcon;

  /// No description provided for @promptBlockLibrary_sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get promptBlockLibrary_sortAscending;

  /// No description provided for @promptBlockLibrary_sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get promptBlockLibrary_sortDescending;

  /// No description provided for @promptBlockLibrary_cardSize.
  ///
  /// In en, this message translates to:
  /// **'Card size'**
  String get promptBlockLibrary_cardSize;

  /// No description provided for @promptBlockLibrary_reorderFolders.
  ///
  /// In en, this message translates to:
  /// **'Reorder folders'**
  String get promptBlockLibrary_reorderFolders;

  /// No description provided for @nav_styleExplore.
  ///
  /// In en, this message translates to:
  /// **'Style Explore'**
  String get nav_styleExplore;

  /// No description provided for @styleExplore_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get styleExplore_rename;

  /// No description provided for @styleExplore_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get styleExplore_nameRequired;

  /// No description provided for @styleExplore_operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get styleExplore_operationFailed;

  /// No description provided for @styleExplore_discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get styleExplore_discardChangesTitle;

  /// No description provided for @styleExplore_discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'The workspace has unsaved changes. Continuing will discard them.'**
  String get styleExplore_discardChangesMessage;

  /// No description provided for @styleExplore_discardChangesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue and discard'**
  String get styleExplore_discardChangesConfirm;

  /// No description provided for @styleExplore_newRun.
  ///
  /// In en, this message translates to:
  /// **'New exploration'**
  String get styleExplore_newRun;

  /// No description provided for @styleExplore_runDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted exploration “{name}”'**
  String styleExplore_runDeleted(String name);

  /// No description provided for @styleExplore_runStatusGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get styleExplore_runStatusGenerating;

  /// No description provided for @styleExplore_runStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get styleExplore_runStatusPaused;

  /// No description provided for @styleExplore_runStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get styleExplore_runStatusCancelled;

  /// No description provided for @styleExplore_pauseRun.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get styleExplore_pauseRun;

  /// No description provided for @styleExplore_cancelRun.
  ///
  /// In en, this message translates to:
  /// **'Cancel exploration'**
  String get styleExplore_cancelRun;

  /// No description provided for @styleExplore_retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed ({count})'**
  String styleExplore_retryFailed(int count);

  /// No description provided for @styleExplore_manualRunName.
  ///
  /// In en, this message translates to:
  /// **'Manual capture {time}'**
  String styleExplore_manualRunName(String time);

  /// No description provided for @styleExplore_runBusy.
  ///
  /// In en, this message translates to:
  /// **'Generation busy, try again later'**
  String get styleExplore_runBusy;

  /// No description provided for @styleExplore_deleteRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exploration'**
  String get styleExplore_deleteRunTitle;

  /// No description provided for @styleExplore_deleteRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Deletes \"{name}\" and its candidate image copies; source images in the gallery are not affected.'**
  String styleExplore_deleteRunMessage(String name);

  /// No description provided for @styleExplore_cancelRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel exploration'**
  String get styleExplore_cancelRunTitle;

  /// No description provided for @styleExplore_cancelRunMessage.
  ///
  /// In en, this message translates to:
  /// **'A cancelled exploration cannot be restarted; remaining queued candidates are marked as cancelled.'**
  String get styleExplore_cancelRunMessage;

  /// No description provided for @styleExplore_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get styleExplore_filterAll;

  /// No description provided for @styleExplore_filterHearted.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get styleExplore_filterHearted;

  /// No description provided for @styleExplore_renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get styleExplore_renameFolder;

  /// No description provided for @styleExplore_deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get styleExplore_deleteFolder;

  /// No description provided for @styleExplore_deleteFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete group “{name}”? Its candidates become ungrouped; images are kept.'**
  String styleExplore_deleteFolderMessage(String name);

  /// No description provided for @styleExplore_folderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get styleExplore_folderNameLabel;

  /// No description provided for @styleExplore_deleteFamily.
  ///
  /// In en, this message translates to:
  /// **'Delete evolution line'**
  String get styleExplore_deleteFamily;

  /// No description provided for @styleExplore_deleteFamilyMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete evolution line “{name}”, all parents and offspring records ({count} images)? Image files are kept.'**
  String styleExplore_deleteFamilyMessage(String name, int count);

  /// No description provided for @styleExplore_familyBusy.
  ///
  /// In en, this message translates to:
  /// **'This evolution line still has candidates generating. Stop generation first.'**
  String get styleExplore_familyBusy;

  /// No description provided for @styleExplore_folderUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get styleExplore_folderUncategorized;

  /// No description provided for @styleExplore_folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Created group “{name}”'**
  String styleExplore_folderCreated(String name);

  /// No description provided for @styleExplore_candidateMissing.
  ///
  /// In en, this message translates to:
  /// **'Image file missing'**
  String get styleExplore_candidateMissing;

  /// No description provided for @styleExplore_candidateDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate detail'**
  String get styleExplore_candidateDetailTitle;

  /// No description provided for @styleExplore_prevCandidate.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get styleExplore_prevCandidate;

  /// No description provided for @styleExplore_nextCandidate.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get styleExplore_nextCandidate;

  /// No description provided for @styleExplore_roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String styleExplore_roundNumber(int number);

  /// No description provided for @styleExplore_adoptBlockSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as block “{name}”'**
  String styleExplore_adoptBlockSaved(String name);

  /// No description provided for @styleExplore_adoptBlockEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected candidates have no artist strings or positive prompts to save'**
  String get styleExplore_adoptBlockEmpty;

  /// No description provided for @styleExplore_deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get styleExplore_deleteImage;

  /// No description provided for @styleExplore_deleteImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete candidate image'**
  String get styleExplore_deleteImageTitle;

  /// No description provided for @styleExplore_deleteImageMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this candidate’s image copy and record? Library originals are kept.'**
  String get styleExplore_deleteImageMessage;

  /// No description provided for @styleExplore_deleteImageDone.
  ///
  /// In en, this message translates to:
  /// **'Candidate image and record deleted'**
  String get styleExplore_deleteImageDone;

  /// No description provided for @styleExplore_selectCandidates.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get styleExplore_selectCandidates;

  /// No description provided for @styleExplore_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String styleExplore_selectedCount(int count);

  /// No description provided for @promptBlockEditor_library.
  ///
  /// In en, this message translates to:
  /// **'Block library'**
  String get promptBlockEditor_library;

  /// No description provided for @promptBlockPicker_title.
  ///
  /// In en, this message translates to:
  /// **'Select Block'**
  String get promptBlockPicker_title;

  /// No description provided for @promptBlockLibrary_thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get promptBlockLibrary_thumbnail;

  /// No description provided for @promptBlockLibrary_selectNewImage.
  ///
  /// In en, this message translates to:
  /// **'Select New Image'**
  String get promptBlockLibrary_selectNewImage;

  /// No description provided for @promptBlockLibrary_selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get promptBlockLibrary_selectImage;

  /// No description provided for @promptBlockLibrary_adjustDisplayRange.
  ///
  /// In en, this message translates to:
  /// **'Adjust Display Range'**
  String get promptBlockLibrary_adjustDisplayRange;

  /// No description provided for @promptBlockLibrary_adjustThumbnailTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust Thumbnail Display Range'**
  String get promptBlockLibrary_adjustThumbnailTitle;

  /// No description provided for @promptBlockLibrary_dragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move, scroll or pinch to zoom'**
  String get promptBlockLibrary_dragToMove;

  /// No description provided for @promptBlockLibrary_addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Block Library'**
  String get promptBlockLibrary_addToLibrary;

  /// No description provided for @promptBlockLibrary_contentPreview.
  ///
  /// In en, this message translates to:
  /// **'Content Preview'**
  String get promptBlockLibrary_contentPreview;

  /// No description provided for @promptBlockLibrary_confirmAdd.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get promptBlockLibrary_confirmAdd;

  /// No description provided for @promptBlockLibrary_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Block Library'**
  String get promptBlockLibrary_saveToLibrary;

  /// No description provided for @promptBlockLibrary_droppedImage.
  ///
  /// In en, this message translates to:
  /// **'Dropped Image'**
  String get promptBlockLibrary_droppedImage;

  /// No description provided for @promptBlockLibrary_createBlockFromImage.
  ///
  /// In en, this message translates to:
  /// **'Create New Block'**
  String get promptBlockLibrary_createBlockFromImage;

  /// No description provided for @promptBlockLibrary_createBlockFromImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new block from this image'**
  String get promptBlockLibrary_createBlockFromImageSubtitle;

  /// No description provided for @promptBlockLibrary_promptExtracted.
  ///
  /// In en, this message translates to:
  /// **'Prompt extracted: \"{prompt}\"'**
  String promptBlockLibrary_promptExtracted(Object prompt);

  /// No description provided for @promptBlockLibrary_updateExistingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Update Existing Block Thumbnail'**
  String get promptBlockLibrary_updateExistingThumbnail;

  /// No description provided for @promptBlockLibrary_updateExistingThumbnailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a block and replace its thumbnail'**
  String get promptBlockLibrary_updateExistingThumbnailSubtitle;

  /// No description provided for @styleExplore_deepRoundCountHint.
  ///
  /// In en, this message translates to:
  /// **'At least {min} images (one guaranteed for each parent)'**
  String styleExplore_deepRoundCountHint(int min);

  /// No description provided for @styleExplore_deepRoundNoInstance.
  ///
  /// In en, this message translates to:
  /// **'No enabled genetic random block in the main prompt; offspring cannot be generated'**
  String get styleExplore_deepRoundNoInstance;

  /// No description provided for @styleExplore_deepRoundEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough distinct offspring artist combinations could be created'**
  String get styleExplore_deepRoundEmpty;

  /// No description provided for @styleExplore_sortLeft.
  ///
  /// In en, this message translates to:
  /// **'Left is better'**
  String get styleExplore_sortLeft;

  /// No description provided for @styleExplore_sortRight.
  ///
  /// In en, this message translates to:
  /// **'Right is better'**
  String get styleExplore_sortRight;

  /// No description provided for @styleExplore_sortNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither is good'**
  String get styleExplore_sortNeither;

  /// No description provided for @styleExplore_sortSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get styleExplore_sortSkip;

  /// No description provided for @styleExplore_sortProgress.
  ///
  /// In en, this message translates to:
  /// **'Pair {current} / {total}'**
  String styleExplore_sortProgress(int current, int total);

  /// No description provided for @styleExplore_sortDone.
  ///
  /// In en, this message translates to:
  /// **'Pairwise comparison complete'**
  String get styleExplore_sortDone;

  /// No description provided for @styleExplore_branchCreated.
  ///
  /// In en, this message translates to:
  /// **'Next generation bred ({count} parents)'**
  String styleExplore_branchCreated(int count);

  /// No description provided for @styleExplore_branchNeedLatest.
  ///
  /// In en, this message translates to:
  /// **'Use offspring from the latest generation to breed the next one'**
  String get styleExplore_branchNeedLatest;

  /// No description provided for @styleExplore_branchRoundsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This generation has unfinished offspring; wait or stop generation'**
  String get styleExplore_branchRoundsIncomplete;

  /// No description provided for @styleExplore_branchDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A selected offspring candidate duplicates a first-generation parent string'**
  String get styleExplore_branchDuplicate;

  /// No description provided for @styleExplore_branchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select at least one offspring candidate'**
  String get styleExplore_branchEmpty;

  /// No description provided for @styleExplore_pileManageDeleteDone.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} candidates and their image copies'**
  String styleExplore_pileManageDeleteDone(int count);

  /// No description provided for @subscriptionExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String subscriptionExpiresOn(String date);

  /// No description provided for @subscriptionDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String subscriptionDaysLeft(int days);

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Grace period'**
  String get subscriptionGracePeriod;

  /// No description provided for @subscriptionTierNone.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get subscriptionTierNone;

  /// No description provided for @settings_modelsAndInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Models & APIs'**
  String get settings_modelsAndInterfaces;

  /// No description provided for @tips_kind_guide.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tips_kind_guide;

  /// No description provided for @tips_kind_trick.
  ///
  /// In en, this message translates to:
  /// **'Pro tip'**
  String get tips_kind_trick;

  /// No description provided for @tips_kind_wolf.
  ///
  /// In en, this message translates to:
  /// **'Wolf'**
  String get tips_kind_wolf;

  /// No description provided for @tips_hint.
  ///
  /// In en, this message translates to:
  /// **'{label}: {tip}'**
  String tips_hint(String label, String tip);

  /// Shortcut generateImage (ctrl+enter); canvas controls from settings_outputViewer_canvasDescription.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+Enter to generate once your prompt is ready. Results spread across this canvas batch by batch: middle-drag or Shift+left-drag to pan, Ctrl+scroll to zoom, and WASD to move around.'**
  String get tips_studio_guide_1;

  /// Pill instance modes (pillSettingsModeFixed / Sequential / Random).
  ///
  /// In en, this message translates to:
  /// **'Write your go-to artist strings, quality tags and composition notes once, save them as blocks, and pull them from the block library next time. Blocks are more than copy-paste: set them to Fixed, Sequential or Random draw and every generation gets a new combination.'**
  String get tips_studio_guide_2;

  /// pillCardLock / pillCardReroll.
  ///
  /// In en, this message translates to:
  /// **'Got a random roll you love? Lock it, then re-roll the other blocks. Locked blocks stay put while the rest keeps shuffling — perfect for \"keep this pose, try a few more outfits.\"'**
  String get tips_studio_guide_3;

  /// Image drop dialog (drop_dialogTitle).
  ///
  /// In en, this message translates to:
  /// **'Drag an image into the window and you\'ll be asked how to use it: Image2Image, Vibe Transfer, Precise Reference, or just extracting its prompt and settings. If it carries NovelAI metadata, one drag shows exactly how it was made.'**
  String get tips_studio_guide_4;

  /// Character position canvas (characterCanvas_custom, characterCanvas_dragHint).
  ///
  /// In en, this message translates to:
  /// **'A character box is really a placement box. Besides people, you can put a cat, a lamp or a shop sign in one. Switch Position to Custom and drag its anchor on the preview to tell the model where it belongs.'**
  String get tips_studio_guide_5;

  /// Weight scroll modifier (settings_enablePromptWeightScrollSubtitle).
  ///
  /// In en, this message translates to:
  /// **'Select part of a prompt and hold Alt while scrolling to adjust its weight. Without Alt the wheel just scrolls, so weights never change by accident. You can switch the modifier to Ctrl in Settings.'**
  String get tips_studio_guide_6;

  /// Default shortcuts: showShortcutHelp f1, navigateTo* ctrl+1/2/3, settings ctrl+comma.
  ///
  /// In en, this message translates to:
  /// **'Press F1 any time for the shortcut list. Ctrl+1, Ctrl+2 and Ctrl+3 jump between Generate, Gallery and Online Gallery, and Ctrl+, opens Settings. Every shortcut can be remapped in Settings.'**
  String get tips_studio_guide_7;

  /// settings_warnHighAnlasCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Worried about burning a pile of Anlas by accident? Turn on the High Anlas cost warning in Settings, and any generation estimated above your threshold will ask before it runs.'**
  String get tips_studio_guide_8;

  /// NovelAI output is deterministic for identical parameters and seed.
  ///
  /// In en, this message translates to:
  /// **'The seed decides which image you pull. Same settings plus the same seed means the same picture. Want to recreate a masterpiece? Keep the seed. Want new luck? Stop staring at that seed.'**
  String get tips_studio_trick_1;

  /// drop_reuseVibeSubtitle / drop_useAsRawImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reusing a pre-encoded Vibe skips the 2 Anlas encoding fee. Two Anlas doesn\'t sound like much — until you count how many Vibes you use in a day.'**
  String get tips_studio_trick_2;

  /// UC preset selector on the negative tab (ucPreset_label).
  ///
  /// In en, this message translates to:
  /// **'Undesired Content isn\'t a wishing well. Writing \"bad hands\" a hundred times does less than describing the hands clearly in the prompt. Leave the usual boilerplate to the Undesired Content preset.'**
  String get tips_studio_trick_3;

  /// Random draw block mode.
  ///
  /// In en, this message translates to:
  /// **'Longer artist strings aren\'t always better. Past ten names, the model probably can\'t tell whose brushwork you actually want. Split them into a few blocks and let random draws rotate them in.'**
  String get tips_studio_trick_4;

  /// Button count = nSamples x imagesPerRequest; estimatedCost uses both.
  ///
  /// In en, this message translates to:
  /// **'Requests per click and images per request are two different numbers. The button shows the total, and Anlas is charged on the total too. Check before you click. Don\'t ask how I know.'**
  String get tips_studio_trick_5;

  /// promptTranslation_guideMiddleText.
  ///
  /// In en, this message translates to:
  /// **'Middle-click a translation block to flip between the original and the translation. However good the AI is, peek at the original now and then to make sure \"cat ears\" didn\'t become something strange.'**
  String get tips_studio_trick_6;

  /// settings_limitGenerationIntervalTitle / settings_setGenerationIntervalJitterTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit generation frequency in Settings forces a cooldown between runs, and a little random jitter keeps the rhythm from feeling mechanical. Good for slow late-night sessions — and for anyone whose finger won\'t leave the button.'**
  String get tips_studio_trick_7;

  /// No description provided for @tips_studio_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the den. I carry the images you make back here and stack them neatly in the gallery. Honestly, I\'m far better at tidying than at drawing.'**
  String get tips_studio_wolf_1;

  /// No description provided for @tips_studio_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Wolves see best at night. So if you\'re still here at 3 a.m., I won\'t say a word. I\'ll just keep you company for one more pull.'**
  String get tips_studio_wolf_2;

  /// No description provided for @tips_studio_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'They say an AI artist comes of age the first time they count the fingers on one hand without panicking. I don\'t have fingers, so I\'ve always been calm.'**
  String get tips_studio_wolf_3;

  /// No description provided for @tips_studio_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Pack rules: share good seeds, save good prompts as blocks, and save good images before you admire them. The last one matters most. Don\'t ask why.'**
  String get tips_studio_wolf_4;

  /// No description provided for @tips_studio_wolf_5.
  ///
  /// In en, this message translates to:
  /// **'I can\'t draw, but I\'m very good at waiting. Those few seconds when the live preview slowly sharpens are the quietest part of my day.'**
  String get tips_studio_wolf_5;

  /// No description provided for @tips_studio_wolf_6.
  ///
  /// In en, this message translates to:
  /// **'W.O.F stands for WolF. As for the dots in between? Those are my paw prints in the snow.'**
  String get tips_studio_wolf_6;

  /// No description provided for @tips_studio_wolf_7.
  ///
  /// In en, this message translates to:
  /// **'When the canvas is empty, I curl up here for a nap. Hit Generate and I\'m awake.'**
  String get tips_studio_wolf_7;

  /// No description provided for @tips_studio_night_1.
  ///
  /// In en, this message translates to:
  /// **'It\'s the middle of the night. Friendly reminder: your taste runs about 30% bolder at this hour. Take another look in the morning.'**
  String get tips_studio_night_1;

  /// No description provided for @tips_studio_night_2.
  ///
  /// In en, this message translates to:
  /// **'It\'s late, and somewhere in a server room a GPU just yawned. Finish this batch and get some sleep. I\'ll guard the gallery.'**
  String get tips_studio_night_2;

  /// Explore runs snapshot prompt and parameters; branches turn picked children into parents.
  ///
  /// In en, this message translates to:
  /// **'Style Explore is an audition. Start an explore run to lock in the prompt and settings, then generate a batch of candidates. The children you pick become the next generation\'s parents, and the style moves toward what you want one generation at a time.'**
  String get tips_lab_guide_1;

  /// Heart/folder are annotations only (explore_candidate_gallery); styleExplore_branchSelect.
  ///
  /// In en, this message translates to:
  /// **'Hearts and folders are for your own organizing; they don\'t affect inheritance. What decides the next generation is the set you pick with \"Select for branch.\"'**
  String get tips_lab_guide_2;

  /// Preference values weight parent selection in ExploreMutationEngine.
  ///
  /// In en, this message translates to:
  /// **'Cannot decide? Use the A/B comparison: two parent images appear side by side and you only answer which is closer to the style you want. Parents ranked higher are more likely to get children next round.'**
  String get tips_lab_guide_3;

  /// styleExplore_deepRoundNoInstance.
  ///
  /// In en, this message translates to:
  /// **'To generate the next round, the main prompt needs at least one random block with evolution enabled. No variable genes, nothing for the mutation engine to work with.'**
  String get tips_lab_guide_4;

  /// styleExplore_adoptAsBlock / styleExplore_mergeAdopt.
  ///
  /// In en, this message translates to:
  /// **'Found a candidate with a great combination? Adopt as block saves it to the block library so you can use it on the Generate page too. Select several and Merge & adopt combines them into one block.'**
  String get tips_lab_guide_5;

  /// styleExplore_deleteRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting an explore run only removes the candidate copies in its run folder; originals in the gallery stay untouched. Clean up freely — a lab is supposed to be a bit messy.'**
  String get tips_lab_guide_6;

  /// styleExplore_deepRoundCountHint.
  ///
  /// In en, this message translates to:
  /// **'Every parent is guaranteed at least one child per round, so more parents means more images per round. Get greedy and your Anlas will call time for you.'**
  String get tips_lab_trick_1;

  /// styleExplore_branchNeedLatest.
  ///
  /// In en, this message translates to:
  /// **'You can only branch from the latest generation\'s pile. You can look back, but you can\'t fork from halfway. Evolution is ruthless like that.'**
  String get tips_lab_trick_2;

  /// styleExplore_deepRoundEmpty; injection draws new atoms from the block pool.
  ///
  /// In en, this message translates to:
  /// **'Sometimes the mutation engine says it can\'t produce enough distinct children. It isn\'t slacking — the gene pool is just too small. Add a few more options to the random block and it gets right back to work.'**
  String get tips_lab_trick_3;

  /// Pile thumbnail hover preview (ExploreCandidateHoverSession).
  ///
  /// In en, this message translates to:
  /// **'Hover a thumbnail in the candidate pile to see it large. No need to open them one by one; a judge has to be efficient.'**
  String get tips_lab_trick_4;

  /// styleExplore_fixateAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Like a candidate\'s whole setup? Import metadata moves its prompt and settings straight back into the editor so you can keep tweaking from there.'**
  String get tips_lab_trick_5;

  /// No description provided for @tips_lab_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'No wolf is born the strongest in the pack. Styles are the same: a rough first generation is normal. Judge it at the third.'**
  String get tips_lab_wolf_1;

  /// No description provided for @tips_lab_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Survival of the fittest has a gentle version here: candidates you don\'t pick don\'t disappear. It just wasn\'t their turn this round.'**
  String get tips_lab_wolf_2;

  /// No description provided for @tips_lab_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'My entire understanding of genetics: good-looking parents usually have good-looking pups. The rest is mutation and a little luck.'**
  String get tips_lab_wolf_3;

  /// No description provided for @tips_lab_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'The lights in the LAB usually stay on late. I\'m on duty at the door, keeping count of which generation we\'re on.'**
  String get tips_lab_wolf_4;

  /// No description provided for @tips_lab_wolf_5.
  ///
  /// In en, this message translates to:
  /// **'Never underestimate mutation. Sometimes the thing you couldn\'t find in ten generations shows up by accident. So don\'t rush to delete the one that looks off.'**
  String get tips_lab_wolf_5;

  /// Shortcuts generateImage ctrl+enter / cancelGeneration escape (web_style_layout).
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Enter generates; Esc cancels a run in progress.'**
  String get tips_prompt_guide_1;

  /// Weight scroll modifier (default Alt).
  ///
  /// In en, this message translates to:
  /// **'Select some text and hold Alt while scrolling to change its weight. Without Alt, the wheel just scrolls.'**
  String get tips_prompt_guide_2;

  /// prompt_cooccurrenceRecommendationSubtitle (default on).
  ///
  /// In en, this message translates to:
  /// **'Ctrl+click a tag to look it up in the local tag library; Ctrl+drag across a phrase to see tags that often appear with it.'**
  String get tips_prompt_guide_3;

  /// Selection context menu promptBlockLibrary_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Right-click selected text to save it straight to the block library. Next time, one click or drag brings it back.'**
  String get tips_prompt_guide_4;

  /// QualityTagsSelector / UcPresetSelector in the prompt card footer.
  ///
  /// In en, this message translates to:
  /// **'The quality tag preset at the bottom of this box adds the usual quality tags for you; switch to Undesired Content and the same spot holds its preset.'**
  String get tips_prompt_guide_5;

  /// showShortcutHelp f1.
  ///
  /// In en, this message translates to:
  /// **'Press F1 to see every shortcut.'**
  String get tips_prompt_guide_6;

  /// ComfyuiImportWrapper detects ComfyUI multi-character syntax.
  ///
  /// In en, this message translates to:
  /// **'Paste a multi-character prompt copied from ComfyUI and it\'s recognized, with an offer to import it as character boxes — no retyping one by one.'**
  String get tips_prompt_guide_7;

  /// prompt_sdSyntaxAutoConvertSubtitle (default off).
  ///
  /// In en, this message translates to:
  /// **'With SD Syntax Auto Convert on, weights like (tag:1.2) are converted to the NovelAI format when you leave the box or generate.'**
  String get tips_prompt_guide_8;

  /// NovelAI V4+ numeric emphasis syntax.
  ///
  /// In en, this message translates to:
  /// **'1.2::tag:: sets an exact weight; a negative number pushes the other way.'**
  String get tips_prompt_guide_9;

  /// NovelAI bracket emphasis.
  ///
  /// In en, this message translates to:
  /// **'Each layer of curly braces multiplies the weight by 1.05; each layer of square brackets divides it by 1.05. Anyone wrapping five layers of braces is usually arguing with the model.'**
  String get tips_prompt_trick_1;

  /// prompt_autoFormatSubtitle (default on).
  ///
  /// In en, this message translates to:
  /// **'Auto Format strips useless 1.0 weights. It isn\'t judging you; it\'s saving tokens.'**
  String get tips_prompt_trick_2;

  /// PromptTokenCountFooter.
  ///
  /// In en, this message translates to:
  /// **'The thin bar at the bottom shows token usage. Once it\'s full, the model barely sees anything past it. If you\'re writing a novel, this isn\'t the place.'**
  String get tips_prompt_trick_3;

  /// No description provided for @tips_prompt_trick_4.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Start with the biggest thing in the picture.'**
  String get tips_prompt_trick_4;

  /// No description provided for @tips_prompt_trick_5.
  ///
  /// In en, this message translates to:
  /// **'One set of quality tags is enough. Typing masterpiece three times doesn\'t make you look more sincere to the model.'**
  String get tips_prompt_trick_5;

  /// NovelAI numeric emphasis.
  ///
  /// In en, this message translates to:
  /// **'Want something present but not stealing the show? 0.8:: works better than deleting it. Deleting means gone; lowering the weight means low-key.'**
  String get tips_prompt_trick_6;

  /// Random draw block mode.
  ///
  /// In en, this message translates to:
  /// **'Swapping the same few words over and over? Make a block and let random draws do it.'**
  String get tips_prompt_trick_7;

  /// No description provided for @tips_prompt_trick_8.
  ///
  /// In en, this message translates to:
  /// **'Put what you want in the prompt and what you don\'t want in Undesired Content. Write \"no hat\" in the prompt and the model mostly just hears \"hat.\"'**
  String get tips_prompt_trick_8;

  /// No description provided for @tips_prompt_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'This box has seen thousands of masterpieces, and a few things best left unshared.'**
  String get tips_prompt_wolf_1;

  /// No description provided for @tips_prompt_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Describe the picture in one plain sentence first, then break it into tags. Do it the other way around and you often get a pile of tags and a picture nobody understands.'**
  String get tips_prompt_wolf_2;

  /// No description provided for @tips_prompt_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'I\'m watching you type. Relax, I can\'t read.'**
  String get tips_prompt_wolf_3;

  /// No description provided for @tips_prompt_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Somewhere far away, a GPU just sighed at your prompt.'**
  String get tips_prompt_wolf_4;

  /// No description provided for @tips_prompt_wolf_5.
  ///
  /// In en, this message translates to:
  /// **'Gacha ends in superstition. Superstition ends in a fixed seed.'**
  String get tips_prompt_wolf_5;

  /// No description provided for @tips_prompt_wolf_6.
  ///
  /// In en, this message translates to:
  /// **'By the twelfth artist tag, the model no longer knows whose style it\'s drawing. Neither do you.'**
  String get tips_prompt_wolf_6;

  /// pillCardEvolutionEnable (explore only).
  ///
  /// In en, this message translates to:
  /// **'This is the parent prompt. To let part of it evolve, turn that part into a random block and enable evolution on the block.'**
  String get tips_explore_guide_1;

  /// pillCardEvolutionRequiresEnabled.
  ///
  /// In en, this message translates to:
  /// **'Evolution can only be enabled once the block instance is enabled. If it\'s greyed out, enable the block first.'**
  String get tips_explore_guide_2;

  /// styleExplore_createDeepRound count box.
  ///
  /// In en, this message translates to:
  /// **'The number next to Generate candidates sets how many images this round makes.'**
  String get tips_explore_guide_3;

  /// pillCardStepBack / pillCardStepForward.
  ///
  /// In en, this message translates to:
  /// **'Block instances can step back and forward one scene at a time through the combinations they have already rolled.'**
  String get tips_explore_guide_4;

  /// styleExplore_runEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'An explore run keeps a snapshot of the prompt and settings. Editing here afterwards won\'t change rounds that already finished.'**
  String get tips_explore_guide_5;

  /// pillCardSettings / pillSettingsCount / TriggerProbability / Weight.
  ///
  /// In en, this message translates to:
  /// **'A block\'s random settings control draw count, trigger chance and random weight — that\'s where all the genetic variety lives.'**
  String get tips_explore_guide_6;

  /// No description provided for @tips_explore_trick_1.
  ///
  /// In en, this message translates to:
  /// **'The bigger the gene pool, the more mutation has to work with. Put only two words in a random block and ten generations will just bounce between two answers.'**
  String get tips_explore_trick_1;

  /// No description provided for @tips_explore_trick_2.
  ///
  /// In en, this message translates to:
  /// **'Hard-code what you\'re sure about and make the uncertain parts random. All random means no direction; all fixed means no evolution.'**
  String get tips_explore_trick_2;

  /// pillCardRerollLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked blocks don\'t get re-rolled. To keep a trait, lock it first and let the other blocks do the experimenting.'**
  String get tips_explore_trick_3;

  /// pillSettingsTriggerProbability.
  ///
  /// In en, this message translates to:
  /// **'Set a trigger chance of 30% and the block shows up in roughly three out of ten combinations — great for touches that only look good once in a while.'**
  String get tips_explore_trick_4;

  /// No description provided for @tips_explore_trick_5.
  ///
  /// In en, this message translates to:
  /// **'Expecting perfection in the first generation? That\'s called wishing, not exploring.'**
  String get tips_explore_trick_5;

  /// No description provided for @tips_explore_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'A pack\'s bloodline is chosen one generation at a time. So is your style.'**
  String get tips_explore_wolf_1;

  /// No description provided for @tips_explore_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Every round is an open audition with exactly one judge: you. I\'m in charge of applause.'**
  String get tips_explore_wolf_2;

  /// No description provided for @tips_explore_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'Good genes come from good parents. Good parents come from that one click where your hand didn\'t slip.'**
  String get tips_explore_wolf_3;

  /// No description provided for @tips_explore_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know much genetics, but I know this: picky judges raise the best-looking pups.'**
  String get tips_explore_wolf_4;

  /// Character prompts carry a position; content is free-form.
  ///
  /// In en, this message translates to:
  /// **'A character box is really a placement box: cats, lamps, signs — it doesn\'t have to be a person.'**
  String get tips_character_guide_1;

  /// CharacterPositionModeSegments / characterCanvas_dragHint.
  ///
  /// In en, this message translates to:
  /// **'Switch Position above to Custom, then drag the anchor on the preview. It applies when you let go.'**
  String get tips_character_guide_2;

  /// AI choice hides anchors but keeps position data (character_position_canvas).
  ///
  /// In en, this message translates to:
  /// **'AI\'s Choice lets the model handle placement. Switch back to Custom and your earlier positions are still there.'**
  String get tips_character_guide_3;

  /// CharacterPromptEditor negative tab.
  ///
  /// In en, this message translates to:
  /// **'Every character box has its own Undesired Content tab that only applies to that character.'**
  String get tips_character_guide_4;

  /// toggleCharacterEnabled header button.
  ///
  /// In en, this message translates to:
  /// **'The check mark at the top right disables this character for now — no need to delete and retype.'**
  String get tips_character_guide_5;

  /// CharacterNameField.
  ///
  /// In en, this message translates to:
  /// **'Click the title to rename this character. Much easier to tell apart than numbers.'**
  String get tips_character_guide_6;

  /// Character header menu addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Use the ⋯ menu at the top right to add this character to the block library and reuse its description later.'**
  String get tips_character_guide_7;

  /// No description provided for @tips_character_trick_1.
  ///
  /// In en, this message translates to:
  /// **'Keep scene and style in the main prompt and only this character here. Write an outfit twice and the model assumes you love it.'**
  String get tips_character_trick_1;

  /// No description provided for @tips_character_trick_2.
  ///
  /// In en, this message translates to:
  /// **'Two people placed too close tend to merge. Pulling their anchors apart works better than writing \"separate\" ten times.'**
  String get tips_character_trick_2;

  /// No description provided for @tips_character_trick_3.
  ///
  /// In en, this message translates to:
  /// **'Want a tree on the left? Give it a character box and drag it there. The tree won\'t complain about not being a character.'**
  String get tips_character_trick_3;

  /// Character boxes use PromptPillEditor.
  ///
  /// In en, this message translates to:
  /// **'Blocks and weight syntax work in character boxes too, just like the main prompt.'**
  String get tips_character_trick_4;

  /// No description provided for @tips_character_trick_5.
  ///
  /// In en, this message translates to:
  /// **'Too many characters? Disable a few. In a crowded frame the model picks who stays — usually not the one you wanted.'**
  String get tips_character_trick_5;

  /// No description provided for @tips_character_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'I\'d like a character box too, but I think I\'m better off watching from outside the frame.'**
  String get tips_character_wolf_1;

  /// No description provided for @tips_character_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'One box, one place, one job. Sounds like a good philosophy for life.'**
  String get tips_character_wolf_2;

  /// No description provided for @tips_character_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'You handle the blocking; I\'ll stand on the side yelling \"a little more to the left.\"'**
  String get tips_character_wolf_3;

  /// No description provided for @tips_character_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Even a wolf pack moves in formation. With lots of characters, decide who stands in the middle first.'**
  String get tips_character_wolf_4;

  /// Local gallery searchable text (gallery_data_source _buildSearchablePromptText).
  ///
  /// In en, this message translates to:
  /// **'Search filenames or prompt text'**
  String get tips_gallery_guide_1;

  /// gallery_filter_service comma-delimited required tags.
  ///
  /// In en, this message translates to:
  /// **'Commas mean all terms must match'**
  String get tips_gallery_guide_2;

  /// Searchable metadata fields.
  ///
  /// In en, this message translates to:
  /// **'Model, sampler and source match too'**
  String get tips_gallery_guide_3;

  /// focusSearch ctrl+f.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+F jumps here any time'**
  String get tips_gallery_guide_4;

  /// Character prompts are part of searchable text.
  ///
  /// In en, this message translates to:
  /// **'Character prompts count too'**
  String get tips_gallery_guide_5;

  /// Local image context menu.
  ///
  /// In en, this message translates to:
  /// **'Right-click an image for more'**
  String get tips_gallery_guide_6;

  /// refreshGallery f5.
  ///
  /// In en, this message translates to:
  /// **'F5 refreshes the gallery'**
  String get tips_gallery_guide_7;

  /// Negative prompt excluded from searchable text.
  ///
  /// In en, this message translates to:
  /// **'Negatives never match'**
  String get tips_gallery_trick_1;

  /// No description provided for @tips_gallery_trick_2.
  ///
  /// In en, this message translates to:
  /// **'Search first. It\'s probably here'**
  String get tips_gallery_trick_2;

  /// No description provided for @tips_gallery_trick_3.
  ///
  /// In en, this message translates to:
  /// **'Your prompts are the best keywords'**
  String get tips_gallery_trick_3;

  /// localGallery_trashHint.
  ///
  /// In en, this message translates to:
  /// **'Trash empties at next launch'**
  String get tips_gallery_trick_4;

  /// No description provided for @tips_gallery_trick_5.
  ///
  /// In en, this message translates to:
  /// **'masterpiece matches everything'**
  String get tips_gallery_trick_5;

  /// No description provided for @tips_gallery_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s prey is on page three'**
  String get tips_gallery_wolf_1;

  /// No description provided for @tips_gallery_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'I smell a masterpiece in here'**
  String get tips_gallery_wolf_2;

  /// No description provided for @tips_gallery_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'Scrolling is cardio. I\'ll run too'**
  String get tips_gallery_wolf_3;

  /// No description provided for @tips_gallery_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Big den. Take your time'**
  String get tips_gallery_wolf_4;

  /// Online search splitOnSpaces, onSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Space between tags, then Enter'**
  String get tips_online_guide_1;

  /// onlineGallery_fuzzySearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fuzzy Match: *tag* finds similar tags'**
  String get tips_online_guide_2;

  /// onlineGallery_blacklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted tags stay hidden'**
  String get tips_online_guide_3;

  /// danbooru_loginHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Danbooru for favorites'**
  String get tips_online_guide_4;

  /// Danbooru tag syntax.
  ///
  /// In en, this message translates to:
  /// **'Multi-word tags: blue_eyes'**
  String get tips_online_trick_1;

  /// No description provided for @tips_online_trick_2.
  ///
  /// In en, this message translates to:
  /// **'Great post? Borrow its tags'**
  String get tips_online_trick_2;

  /// No description provided for @tips_online_trick_3.
  ///
  /// In en, this message translates to:
  /// **'More tags, fewer results'**
  String get tips_online_trick_3;

  /// No description provided for @tips_online_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Big world out there. I\'ll scout'**
  String get tips_online_wolf_1;

  /// No description provided for @tips_online_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Other packs\' turf. Just looking'**
  String get tips_online_wolf_2;

  /// No description provided for @tips_online_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'Which forest are we hunting in?'**
  String get tips_online_wolf_3;

  /// promptBlockLibrary_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles, prompts or tags'**
  String get tips_blocks_guide_1;

  /// PromptPillEditor DragTarget<PromptBlockDragData>.
  ///
  /// In en, this message translates to:
  /// **'Drag a block into the prompt'**
  String get tips_blocks_guide_2;

  /// promptBlockLibrary_emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Star the ones you use most'**
  String get tips_blocks_guide_3;

  /// Block thumbnails.
  ///
  /// In en, this message translates to:
  /// **'Thumbnails make picking faster'**
  String get tips_blocks_guide_4;

  /// promptBlockLibrary_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Right-click text to save a block'**
  String get tips_blocks_guide_5;

  /// No description provided for @tips_blocks_trick_1.
  ///
  /// In en, this message translates to:
  /// **'Typed it thrice? Make it a block'**
  String get tips_blocks_trick_1;

  /// No description provided for @tips_blocks_trick_2.
  ///
  /// In en, this message translates to:
  /// **'Unsure? Save it. Deleting is fast'**
  String get tips_blocks_trick_2;

  /// No description provided for @tips_blocks_trick_3.
  ///
  /// In en, this message translates to:
  /// **'Future you loves clear names'**
  String get tips_blocks_trick_3;

  /// No description provided for @tips_blocks_trick_4.
  ///
  /// In en, this message translates to:
  /// **'More options, more surprises'**
  String get tips_blocks_trick_4;

  /// No description provided for @tips_blocks_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Every block wants to be picked'**
  String get tips_blocks_wolf_1;

  /// No description provided for @tips_blocks_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'These blocks are your pack'**
  String get tips_blocks_wolf_2;

  /// No description provided for @tips_blocks_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'The only block I know is meat'**
  String get tips_blocks_wolf_3;

  /// No description provided for @tips_blocks_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Folders in folders. So organized'**
  String get tips_blocks_wolf_4;

  /// No description provided for @tips_generating_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Haggling with the random numbers…'**
  String get tips_generating_wolf_1;

  /// No description provided for @tips_generating_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Having a word with the sixth finger…'**
  String get tips_generating_wolf_2;

  /// No description provided for @tips_generating_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'Asking the pixels to line up…'**
  String get tips_generating_wolf_3;

  /// No description provided for @tips_generating_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Wiping away the noise, grain by grain…'**
  String get tips_generating_wolf_4;

  /// No description provided for @tips_generating_wolf_5.
  ///
  /// In en, this message translates to:
  /// **'A wolf is howling encouragement…'**
  String get tips_generating_wolf_5;

  /// No description provided for @tips_generating_wolf_6.
  ///
  /// In en, this message translates to:
  /// **'Explaining your taste to the GPU…'**
  String get tips_generating_wolf_6;

  /// No description provided for @tips_generating_wolf_7.
  ///
  /// In en, this message translates to:
  /// **'Translating your prompt into a dream…'**
  String get tips_generating_wolf_7;

  /// No description provided for @tips_generating_wolf_8.
  ///
  /// In en, this message translates to:
  /// **'Double-checking the eye count…'**
  String get tips_generating_wolf_8;

  /// No description provided for @tips_generating_wolf_9.
  ///
  /// In en, this message translates to:
  /// **'Finding a flattering light…'**
  String get tips_generating_wolf_9;

  /// No description provided for @tips_generating_wolf_10.
  ///
  /// In en, this message translates to:
  /// **'Convincing the background not to steal the show…'**
  String get tips_generating_wolf_10;

  /// No description provided for @tips_generating_wolf_11.
  ///
  /// In en, this message translates to:
  /// **'Fishing your image out of the noise…'**
  String get tips_generating_wolf_11;

  /// No description provided for @tips_generating_wolf_12.
  ///
  /// In en, this message translates to:
  /// **'Counting fingers: one, two, three…'**
  String get tips_generating_wolf_12;

  /// No description provided for @tips_generating_wolf_13.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the paint to dry…'**
  String get tips_generating_wolf_13;

  /// No description provided for @tips_generating_wolf_14.
  ///
  /// In en, this message translates to:
  /// **'Summoning today\'s luck…'**
  String get tips_generating_wolf_14;

  /// cancelGeneration escape.
  ///
  /// In en, this message translates to:
  /// **'Changed your mind? Esc cancels'**
  String get tips_generating_trick_1;

  /// Streaming preview frames.
  ///
  /// In en, this message translates to:
  /// **'The preview sharpens frame by frame'**
  String get tips_generating_trick_2;

  /// autoSaveImages default true.
  ///
  /// In en, this message translates to:
  /// **'Finished images save to the gallery by default'**
  String get tips_generating_trick_3;

  /// No description provided for @tips_generating_trick_4.
  ///
  /// In en, this message translates to:
  /// **'Each sampling step removes a little more noise'**
  String get tips_generating_trick_4;

  /// showShortcutHelp f1.
  ///
  /// In en, this message translates to:
  /// **'Press F1 any time to see every shortcut.'**
  String get tips_splash_guide_1;

  /// generateImage ctrl+enter; shortcut settings.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Enter generates, and every shortcut can be remapped in Settings.'**
  String get tips_splash_guide_2;

  /// drop_extractMetadataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop an image into the window to read its prompt and settings.'**
  String get tips_splash_guide_3;

  /// Prompt blocks.
  ///
  /// In en, this message translates to:
  /// **'Save prompts you use often as blocks and reuse them in one click.'**
  String get tips_splash_guide_4;

  /// Splash STEP xx/28 counter.
  ///
  /// In en, this message translates to:
  /// **'That STEP /28 up there is a nod to the default 28 sampling steps.'**
  String get tips_splash_trick_1;

  /// drop_reuseVibeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-encoded Vibes can be reused for free — that\'s 2 Anlas saved.'**
  String get tips_splash_trick_2;

  /// localGallery_firstIndexHint.
  ///
  /// In en, this message translates to:
  /// **'Building the gallery index takes a while the first time; keep working meanwhile.'**
  String get tips_splash_trick_3;

  /// No description provided for @tips_splash_wolf_1.
  ///
  /// In en, this message translates to:
  /// **'Five more minutes… fine, I\'m up.'**
  String get tips_splash_wolf_1;

  /// No description provided for @tips_splash_wolf_2.
  ///
  /// In en, this message translates to:
  /// **'Tidying up the den. Almost ready.'**
  String get tips_splash_wolf_2;

  /// No description provided for @tips_splash_wolf_3.
  ///
  /// In en, this message translates to:
  /// **'GPU ready. Moon ready. Just waiting on you.'**
  String get tips_splash_wolf_3;

  /// No description provided for @tips_splash_wolf_4.
  ///
  /// In en, this message translates to:
  /// **'Smell that? Fresh prompts.'**
  String get tips_splash_wolf_4;

  /// No description provided for @tips_splash_wolf_5.
  ///
  /// In en, this message translates to:
  /// **'Let\'s have some good pulls today.'**
  String get tips_splash_wolf_5;

  /// No description provided for @genButton_normal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Generate 1 Image} other{Generate {count} Images}}'**
  String genButton_normal(int count);

  /// No description provided for @genButton_one_1.
  ///
  /// In en, this message translates to:
  /// **'Just this one'**
  String get genButton_one_1;

  /// No description provided for @genButton_one_2.
  ///
  /// In en, this message translates to:
  /// **'One good one, please'**
  String get genButton_one_2;

  /// No description provided for @genButton_one_3.
  ///
  /// In en, this message translates to:
  /// **'Single pull, leap of faith'**
  String get genButton_one_3;

  /// No description provided for @genButton_one_4.
  ///
  /// In en, this message translates to:
  /// **'Testing the waters'**
  String get genButton_one_4;

  /// No description provided for @genButton_one_5.
  ///
  /// In en, this message translates to:
  /// **'One shot, one verdict'**
  String get genButton_one_5;

  /// No description provided for @genButton_one_6.
  ///
  /// In en, this message translates to:
  /// **'This one is a masterpiece'**
  String get genButton_one_6;

  /// No description provided for @genButton_one_7.
  ///
  /// In en, this message translates to:
  /// **'Just one, I swear'**
  String get genButton_one_7;

  /// No description provided for @genButton_one_8.
  ///
  /// In en, this message translates to:
  /// **'New avatar incoming'**
  String get genButton_one_8;

  /// No description provided for @genButton_one_9.
  ///
  /// In en, this message translates to:
  /// **'One and done'**
  String get genButton_one_9;

  /// No description provided for @genButton_one_10.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper material, please'**
  String get genButton_one_10;

  /// No description provided for @genButton_one_11.
  ///
  /// In en, this message translates to:
  /// **'A gentle single pull'**
  String get genButton_one_11;

  /// No description provided for @genButton_one_12.
  ///
  /// In en, this message translates to:
  /// **'Fetch me one'**
  String get genButton_one_12;

  /// No description provided for @genButton_few_1.
  ///
  /// In en, this message translates to:
  /// **'{count} images, pick the best'**
  String genButton_few_1(int count);

  /// No description provided for @genButton_few_2.
  ///
  /// In en, this message translates to:
  /// **'{count} to compare'**
  String genButton_few_2(int count);

  /// No description provided for @genButton_few_3.
  ///
  /// In en, this message translates to:
  /// **'{count}-pull'**
  String genButton_few_3(int count);

  /// No description provided for @genButton_few_4.
  ///
  /// In en, this message translates to:
  /// **'{count} tries, one will land'**
  String genButton_few_4(int count);

  /// No description provided for @genButton_few_5.
  ///
  /// In en, this message translates to:
  /// **'Pick 1 of {count}'**
  String genButton_few_5(int count);

  /// No description provided for @genButton_few_6.
  ///
  /// In en, this message translates to:
  /// **'{count} to warm up'**
  String genButton_few_6(int count);

  /// No description provided for @genButton_few_7.
  ///
  /// In en, this message translates to:
  /// **'{count} auditions'**
  String genButton_few_7(int count);

  /// No description provided for @genButton_few_8.
  ///
  /// In en, this message translates to:
  /// **'{count} little wins'**
  String genButton_few_8(int count);

  /// No description provided for @genButton_batch_1.
  ///
  /// In en, this message translates to:
  /// **'{count}-shot burst'**
  String genButton_batch_1(int count);

  /// No description provided for @genButton_batch_2.
  ///
  /// In en, this message translates to:
  /// **'{count} at once'**
  String genButton_batch_2(int count);

  /// No description provided for @genButton_batch_3.
  ///
  /// In en, this message translates to:
  /// **'{count} images, getting hooked'**
  String genButton_batch_3(int count);

  /// No description provided for @genButton_batch_4.
  ///
  /// In en, this message translates to:
  /// **'{count} in one go'**
  String genButton_batch_4(int count);

  /// No description provided for @genButton_batch_5.
  ///
  /// In en, this message translates to:
  /// **'{count} to fill the screen'**
  String genButton_batch_5(int count);

  /// No description provided for @genButton_batch_6.
  ///
  /// In en, this message translates to:
  /// **'{count}-pull, playing it safe'**
  String genButton_batch_6(int count);

  /// No description provided for @genButton_batch_7.
  ///
  /// In en, this message translates to:
  /// **'{count} images, the pack is out'**
  String genButton_batch_7(int count);

  /// No description provided for @genButton_batch_8.
  ///
  /// In en, this message translates to:
  /// **'{count} servings coming up'**
  String genButton_batch_8(int count);

  /// No description provided for @genButton_many_1.
  ///
  /// In en, this message translates to:
  /// **'{count} images, turning it up'**
  String genButton_many_1(int count);

  /// No description provided for @genButton_many_2.
  ///
  /// In en, this message translates to:
  /// **'{count} images, GPU sweating'**
  String genButton_many_2(int count);

  /// No description provided for @genButton_many_3.
  ///
  /// In en, this message translates to:
  /// **'{count} images, stockpiling'**
  String genButton_many_3(int count);

  /// No description provided for @genButton_many_4.
  ///
  /// In en, this message translates to:
  /// **'{count} images, assembly line on'**
  String genButton_many_4(int count);

  /// No description provided for @genButton_many_5.
  ///
  /// In en, this message translates to:
  /// **'{count} images, Anlas burning'**
  String genButton_many_5(int count);

  /// No description provided for @genButton_many_6.
  ///
  /// In en, this message translates to:
  /// **'{count} images, daily upload mode'**
  String genButton_many_6(int count);

  /// No description provided for @genButton_many_7.
  ///
  /// In en, this message translates to:
  /// **'{count}-image batch run'**
  String genButton_many_7(int count);

  /// No description provided for @genButton_many_8.
  ///
  /// In en, this message translates to:
  /// **'{count} images, the wolf is stunned'**
  String genButton_many_8(int count);

  /// No description provided for @genButton_huge_1.
  ///
  /// In en, this message translates to:
  /// **'{count}?! Opening a gallery?'**
  String genButton_huge_1(int count);

  /// No description provided for @genButton_huge_2.
  ///
  /// In en, this message translates to:
  /// **'{count} images, the drive is shaking'**
  String genButton_huge_2(int count);

  /// No description provided for @genButton_huge_3.
  ///
  /// In en, this message translates to:
  /// **'{count} images, industrial revolution'**
  String genButton_huge_3(int count);

  /// No description provided for @genButton_huge_4.
  ///
  /// In en, this message translates to:
  /// **'{count} images, deep breath first'**
  String genButton_huge_4(int count);

  /// No description provided for @genButton_huge_5.
  ///
  /// In en, this message translates to:
  /// **'{count} images, got the space?'**
  String genButton_huge_5(int count);

  /// No description provided for @genButton_huge_6.
  ///
  /// In en, this message translates to:
  /// **'{count} images, print shop open'**
  String genButton_huge_6(int count);

  /// No description provided for @genButton_huge_7.
  ///
  /// In en, this message translates to:
  /// **'{count} images, wholesale'**
  String genButton_huge_7(int count);

  /// No description provided for @genButton_huge_8.
  ///
  /// In en, this message translates to:
  /// **'{count} images, the wolf went for backup'**
  String genButton_huge_8(int count);

  /// No description provided for @genButton_rare_1.
  ///
  /// In en, this message translates to:
  /// **'SSR guaranteed'**
  String get genButton_rare_1;

  /// No description provided for @genButton_rare_2.
  ///
  /// In en, this message translates to:
  /// **'The AI feels lucky today'**
  String get genButton_rare_2;

  /// No description provided for @genButton_rare_3.
  ///
  /// In en, this message translates to:
  /// **'Today\'s fortune: excellent'**
  String get genButton_rare_3;

  /// No description provided for @genButton_rare_4.
  ///
  /// In en, this message translates to:
  /// **'They say this button likes you'**
  String get genButton_rare_4;

  /// No description provided for @genButton_rare_5.
  ///
  /// In en, this message translates to:
  /// **'The wolf howled at the moon'**
  String get genButton_rare_5;

  /// No description provided for @genButton_rare_6.
  ///
  /// In en, this message translates to:
  /// **'Luck buff active'**
  String get genButton_rare_6;

  /// No description provided for @genButton_rare_7.
  ///
  /// In en, this message translates to:
  /// **'Luck recharged'**
  String get genButton_rare_7;

  /// No description provided for @genButton_rare_8.
  ///
  /// In en, this message translates to:
  /// **'This pull is sponsored by the wolf'**
  String get genButton_rare_8;

  /// No description provided for @genButton_rare_9.
  ///
  /// In en, this message translates to:
  /// **'Come on, luck!'**
  String get genButton_rare_9;

  /// No description provided for @genButton_rare_10.
  ///
  /// In en, this message translates to:
  /// **'Press to believe'**
  String get genButton_rare_10;

  /// No description provided for @genButton_night_1.
  ///
  /// In en, this message translates to:
  /// **'Late night, last pull'**
  String get genButton_night_1;

  /// No description provided for @genButton_night_2.
  ///
  /// In en, this message translates to:
  /// **'One more batch, then bed'**
  String get genButton_night_2;

  /// No description provided for @genButton_night_3.
  ///
  /// In en, this message translates to:
  /// **'3 a.m. taste is wild'**
  String get genButton_night_3;

  /// No description provided for @genButton_night_4.
  ///
  /// In en, this message translates to:
  /// **'The wolf is up with you'**
  String get genButton_night_4;

  /// No description provided for @genButton_special_7.
  ///
  /// In en, this message translates to:
  /// **'Lucky {count}'**
  String genButton_special_7(int count);

  /// No description provided for @genButton_special_9.
  ///
  /// In en, this message translates to:
  /// **'{count} for a full 3×3 grid'**
  String genButton_special_9(int count);

  /// No description provided for @genButton_special_42.
  ///
  /// In en, this message translates to:
  /// **'{count}: the answer to everything'**
  String genButton_special_42(int count);

  /// No description provided for @genButton_special_99.
  ///
  /// In en, this message translates to:
  /// **'{count}, one short of a hundred'**
  String genButton_special_99(int count);

  /// No description provided for @genButton_special_100.
  ///
  /// In en, this message translates to:
  /// **'A clean {count}. Satisfying'**
  String genButton_special_100(int count);

  /// No description provided for @titleBar_minimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get titleBar_minimize;

  /// No description provided for @titleBar_maximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get titleBar_maximize;

  /// No description provided for @titleBar_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get titleBar_restore;

  /// No description provided for @titleBar_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get titleBar_close;

  /// No description provided for @img2img_pixelSnap.
  ///
  /// In en, this message translates to:
  /// **'Pixel Snap'**
  String get img2img_pixelSnap;

  /// No description provided for @img2img_directorAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Use result as next input'**
  String get img2img_directorAddToQueue;

  /// No description provided for @img2img_transform.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get img2img_transform;

  /// No description provided for @img2img_palette.
  ///
  /// In en, this message translates to:
  /// **'Palettize'**
  String get img2img_palette;

  /// No description provided for @img2img_paletteOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get img2img_paletteOff;

  /// No description provided for @img2img_paletteAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get img2img_paletteAuto;

  /// No description provided for @img2img_paletteCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get img2img_paletteCustom;

  /// No description provided for @img2img_avoidOverRefining.
  ///
  /// In en, this message translates to:
  /// **'Avoid Over-Refining'**
  String get img2img_avoidOverRefining;

  /// No description provided for @img2img_keepGridHint.
  ///
  /// In en, this message translates to:
  /// **'Preserve the detected pixel grid.'**
  String get img2img_keepGridHint;

  /// No description provided for @img2img_refineGridHint.
  ///
  /// In en, this message translates to:
  /// **'A finer pixel size may be used when it matches the image better.'**
  String get img2img_refineGridHint;

  /// No description provided for @img2img_pixelUpscaleHint.
  ///
  /// In en, this message translates to:
  /// **'Enlarge the result with crisp, nearest-neighbor pixels.'**
  String get img2img_pixelUpscaleHint;

  /// No description provided for @img2img_pixelNativeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the result at its snapped pixel size.'**
  String get img2img_pixelNativeHint;

  /// No description provided for @img2img_masked.
  ///
  /// In en, this message translates to:
  /// **'Masked'**
  String get img2img_masked;

  /// No description provided for @img2img_generated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get img2img_generated;

  /// No description provided for @img2img_blend.
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get img2img_blend;

  /// No description provided for @img2img_emotionHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get img2img_emotionHappy;

  /// No description provided for @img2img_emotionLaugh.
  ///
  /// In en, this message translates to:
  /// **'Laughing'**
  String get img2img_emotionLaugh;

  /// No description provided for @img2img_emotionSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get img2img_emotionSad;

  /// No description provided for @img2img_emotionAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get img2img_emotionAngry;

  /// No description provided for @img2img_emotionSurprised.
  ///
  /// In en, this message translates to:
  /// **'Surprised'**
  String get img2img_emotionSurprised;

  /// No description provided for @img2img_emotionShy.
  ///
  /// In en, this message translates to:
  /// **'Shy'**
  String get img2img_emotionShy;

  /// No description provided for @img2img_emotionExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get img2img_emotionExcited;

  /// No description provided for @img2img_emotionDisgusted.
  ///
  /// In en, this message translates to:
  /// **'Disgusted'**
  String get img2img_emotionDisgusted;

  /// No description provided for @img2img_emotionSmug.
  ///
  /// In en, this message translates to:
  /// **'Smug'**
  String get img2img_emotionSmug;

  /// No description provided for @img2img_emotionWorried.
  ///
  /// In en, this message translates to:
  /// **'Worried'**
  String get img2img_emotionWorried;

  /// No description provided for @img2img_emotionLove.
  ///
  /// In en, this message translates to:
  /// **'Loving'**
  String get img2img_emotionLove;

  /// No description provided for @img2img_emotionPlayful.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get img2img_emotionPlayful;

  /// No description provided for @img2img_emotionTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get img2img_emotionTired;

  /// No description provided for @img2img_emotionNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get img2img_emotionNeutral;

  /// No description provided for @img2img_enhanceAction.
  ///
  /// In en, this message translates to:
  /// **'Enhance!'**
  String get img2img_enhanceAction;

  /// No description provided for @img2img_showAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Show Advanced'**
  String get img2img_showAdvanced;

  /// No description provided for @img2img_hideAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Hide Advanced'**
  String get img2img_hideAdvanced;

  /// No description provided for @promptToken_usage.
  ///
  /// In en, this message translates to:
  /// **'Token usage: {used} / {limit}'**
  String promptToken_usage(int used, int limit);

  /// No description provided for @promptToken_promptShare.
  ///
  /// In en, this message translates to:
  /// **'This prompt: {used} tokens; total usage: {total} / {limit}'**
  String promptToken_promptShare(int used, int total, int limit);

  /// No description provided for @promptToken_blockReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'This block\'s progress is a guide; the total depends on how blocks are combined.'**
  String get promptToken_blockReferenceHint;

  /// No description provided for @settings_geistDark.
  ///
  /// In en, this message translates to:
  /// **'Geist Dark'**
  String get settings_geistDark;

  /// No description provided for @settings_geistLight.
  ///
  /// In en, this message translates to:
  /// **'Geist Light'**
  String get settings_geistLight;

  /// No description provided for @settings_geistDescription.
  ///
  /// In en, this message translates to:
  /// **'One appearance across your studio. Black or white surfaces, with blue accents.'**
  String get settings_geistDescription;

  /// No description provided for @updateCapsuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateCapsuleLabel;

  /// No description provided for @updateWaitForTask.
  ///
  /// In en, this message translates to:
  /// **'Wait for the current task to finish before restarting'**
  String get updateWaitForTask;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @nav_tagWiki.
  ///
  /// In en, this message translates to:
  /// **'Tag Wiki'**
  String get nav_tagWiki;

  /// No description provided for @wiki_title.
  ///
  /// In en, this message translates to:
  /// **'Tag Wiki'**
  String get wiki_title;

  /// No description provided for @wiki_allTags.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get wiki_allTags;

  /// No description provided for @wiki_bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get wiki_bookmarks;

  /// No description provided for @wiki_newCollection.
  ///
  /// In en, this message translates to:
  /// **'New bookmark collection'**
  String get wiki_newCollection;

  /// No description provided for @wiki_newChildCollection.
  ///
  /// In en, this message translates to:
  /// **'New child collection'**
  String get wiki_newChildCollection;

  /// No description provided for @wiki_renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get wiki_renameCollection;

  /// No description provided for @wiki_deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get wiki_deleteCollection;

  /// No description provided for @wiki_officialDirectory.
  ///
  /// In en, this message translates to:
  /// **'Official directory'**
  String get wiki_officialDirectory;

  /// No description provided for @wiki_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags or aliases'**
  String get wiki_searchHint;

  /// No description provided for @wiki_typeAllShort.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get wiki_typeAllShort;

  /// No description provided for @wiki_coverageAll.
  ///
  /// In en, this message translates to:
  /// **'All descriptions'**
  String get wiki_coverageAll;

  /// No description provided for @wiki_withArticle.
  ///
  /// In en, this message translates to:
  /// **'Has description'**
  String get wiki_withArticle;

  /// No description provided for @wiki_withoutArticle.
  ///
  /// In en, this message translates to:
  /// **'No description yet'**
  String get wiki_withoutArticle;

  /// No description provided for @wiki_sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get wiki_sortPopular;

  /// No description provided for @wiki_sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wiki_sortName;

  /// No description provided for @wiki_dataStatus.
  ///
  /// In en, this message translates to:
  /// **'Data status'**
  String get wiki_dataStatus;

  /// No description provided for @wiki_scopeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current section'**
  String get wiki_scopeCurrent;

  /// No description provided for @wiki_scopeAll.
  ///
  /// In en, this message translates to:
  /// **'Search all tags'**
  String get wiki_scopeAll;

  /// No description provided for @wiki_readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get wiki_readingSettings;

  /// No description provided for @wiki_textSize.
  ///
  /// In en, this message translates to:
  /// **'Article text'**
  String get wiki_textSize;

  /// No description provided for @wiki_readingWidth.
  ///
  /// In en, this message translates to:
  /// **'Reading width'**
  String get wiki_readingWidth;

  /// No description provided for @wiki_small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get wiki_small;

  /// No description provided for @wiki_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get wiki_standard;

  /// No description provided for @wiki_large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get wiki_large;

  /// No description provided for @wiki_wide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get wiki_wide;

  /// No description provided for @wiki_articleMissing.
  ///
  /// In en, this message translates to:
  /// **'This tag has no local Wiki description yet.'**
  String get wiki_articleMissing;

  /// No description provided for @wiki_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get wiki_source;

  /// No description provided for @wiki_addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get wiki_addBookmark;

  /// No description provided for @wiki_removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get wiki_removeBookmark;

  /// No description provided for @wiki_addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get wiki_addToCollection;

  /// No description provided for @wiki_loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get wiki_loadMore;

  /// No description provided for @wiki_noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching tags'**
  String get wiki_noResults;

  /// No description provided for @wiki_noSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a tag to read its description'**
  String get wiki_noSelection;

  /// No description provided for @wiki_collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get wiki_collectionNameHint;

  /// No description provided for @wiki_syncTags.
  ///
  /// In en, this message translates to:
  /// **'Sync Danbooru tags'**
  String get wiki_syncTags;

  /// No description provided for @wiki_directorySource.
  ///
  /// In en, this message translates to:
  /// **'Official group directory snapshot'**
  String get wiki_directorySource;

  /// No description provided for @wiki_openFull.
  ///
  /// In en, this message translates to:
  /// **'Open in Tag Wiki'**
  String get wiki_openFull;

  /// No description provided for @shortcut_action_vibe_detail_prev_sub_vibe.
  ///
  /// In en, this message translates to:
  /// **'Previous sub-Vibe'**
  String get shortcut_action_vibe_detail_prev_sub_vibe;

  /// No description provided for @shortcut_action_vibe_detail_next_sub_vibe.
  ///
  /// In en, this message translates to:
  /// **'Next sub-Vibe'**
  String get shortcut_action_vibe_detail_next_sub_vibe;

  /// No description provided for @settings_addAccountsSwitchBetweenThem.
  ///
  /// In en, this message translates to:
  /// **'Add accounts to switch between them here.'**
  String get settings_addAccountsSwitchBetweenThem;

  /// No description provided for @settings_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get settings_current;

  /// No description provided for @settings_emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Email login'**
  String get settings_emailLogin;

  /// No description provided for @settings_signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settings_signedIn;

  /// No description provided for @settings_switch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get settings_switch;

  /// No description provided for @settings_accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account actions'**
  String get settings_accountActions;

  /// No description provided for @settings_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settings_editProfile;

  /// No description provided for @settings_setDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get settings_setDefault;

  /// No description provided for @settings_credentialsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Credentials updated'**
  String get settings_credentialsUpdated;

  /// No description provided for @settings_updateCredentials.
  ///
  /// In en, this message translates to:
  /// **'Update credentials'**
  String get settings_updateCredentials;

  /// No description provided for @settings_accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get settings_accountDetails;

  /// No description provided for @settings_localAccountProfile.
  ///
  /// In en, this message translates to:
  /// **'Local account profile'**
  String get settings_localAccountProfile;

  /// No description provided for @settings_setDefault2.
  ///
  /// In en, this message translates to:
  /// **'Set default'**
  String get settings_setDefault2;

  /// No description provided for @settings_credentialsWereNotUpdatedCheck.
  ///
  /// In en, this message translates to:
  /// **'Credentials were not updated. Check the token and connection.'**
  String get settings_credentialsWereNotUpdatedCheck;

  /// No description provided for @settings_updateCredentials2.
  ///
  /// In en, this message translates to:
  /// **'Update credentials'**
  String get settings_updateCredentials2;

  /// No description provided for @settings_checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settings_checking;

  /// No description provided for @settings_enterNewSignInToken.
  ///
  /// In en, this message translates to:
  /// **'Enter a new sign-in token. This account updates after validation.'**
  String get settings_enterNewSignInToken;

  /// No description provided for @auth_signInAccounts.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & accounts'**
  String get auth_signInAccounts;

  /// No description provided for @auth_notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get auth_notSignedIn;

  /// No description provided for @auth_chooseAccountContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose an account to continue'**
  String get auth_chooseAccountContinue;

  /// No description provided for @auth_manageAccounts2.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts'**
  String get auth_manageAccounts2;

  /// No description provided for @auth_subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription expired'**
  String get auth_subscriptionExpired;

  /// No description provided for @settings_tagExpansion.
  ///
  /// In en, this message translates to:
  /// **'Tag expansion'**
  String get settings_tagExpansion;

  /// No description provided for @settings_tagDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Tag dictionaries'**
  String get settings_tagDictionaries;

  /// No description provided for @settings_cacheMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Cache maintenance'**
  String get settings_cacheMaintenance;

  /// No description provided for @settings_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_clear;

  /// No description provided for @settings_autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto refresh'**
  String get settings_autoRefresh;

  /// No description provided for @settings_searchFonts.
  ///
  /// In en, this message translates to:
  /// **'Search fonts'**
  String get settings_searchFonts;

  /// No description provided for @settings_couldNotLoadFonts.
  ///
  /// In en, this message translates to:
  /// **'Could not load fonts'**
  String get settings_couldNotLoadFonts;

  /// No description provided for @settings_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get settings_recommended;

  /// No description provided for @settings_included.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get settings_included;

  /// No description provided for @settings_systemFonts.
  ///
  /// In en, this message translates to:
  /// **'System fonts'**
  String get settings_systemFonts;

  /// No description provided for @settings_fontPreview.
  ///
  /// In en, this message translates to:
  /// **'Font preview'**
  String get settings_fontPreview;

  /// No description provided for @settings_onlineFontsLoadAfterApplying.
  ///
  /// In en, this message translates to:
  /// **'Online fonts load after applying; preview uses the interface font.'**
  String get settings_onlineFontsLoadAfterApplying;

  /// No description provided for @settings_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get settings_saving;

  /// No description provided for @settings_howGeneratedImagesSaved.
  ///
  /// In en, this message translates to:
  /// **'How generated images are saved'**
  String get settings_howGeneratedImagesSaved;

  /// No description provided for @settings_assetsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Assets & display'**
  String get settings_assetsDisplay;

  /// No description provided for @settings_vibeLocationThumbnailQuality.
  ///
  /// In en, this message translates to:
  /// **'Vibe location and thumbnail quality'**
  String get settings_vibeLocationThumbnailQuality;

  /// No description provided for @settings_applicationData.
  ///
  /// In en, this message translates to:
  /// **'Application data'**
  String get settings_applicationData;

  /// No description provided for @settings_gallerySources.
  ///
  /// In en, this message translates to:
  /// **'Gallery sources'**
  String get settings_gallerySources;

  /// No description provided for @settings_manageAdditionalGalleryFolders.
  ///
  /// In en, this message translates to:
  /// **'Manage additional gallery folders'**
  String get settings_manageAdditionalGalleryFolders;

  /// No description provided for @settings_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settings_default;

  /// No description provided for @settings_keyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get settings_keyboard;

  /// No description provided for @settings_customizeFrequentlyUsedActions.
  ///
  /// In en, this message translates to:
  /// **'Customize frequently used actions'**
  String get settings_customizeFrequentlyUsedActions;

  /// No description provided for @settings_manageShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Manage shortcuts'**
  String get settings_manageShortcuts;

  /// No description provided for @settings_costReminders.
  ///
  /// In en, this message translates to:
  /// **'Cost reminders'**
  String get settings_costReminders;

  /// No description provided for @settings_requestPacing.
  ///
  /// In en, this message translates to:
  /// **'Request pacing'**
  String get settings_requestPacing;

  /// No description provided for @settings_notificationsSound.
  ///
  /// In en, this message translates to:
  /// **'Notifications & sound'**
  String get settings_notificationsSound;

  /// No description provided for @settings_lockCanvasCamera.
  ///
  /// In en, this message translates to:
  /// **'Lock canvas camera'**
  String get settings_lockCanvasCamera;

  /// No description provided for @settings_dictionariesCache.
  ///
  /// In en, this message translates to:
  /// **'Dictionaries & cache'**
  String get settings_dictionariesCache;

  /// No description provided for @settings_defaultAccount2.
  ///
  /// In en, this message translates to:
  /// **'Default account'**
  String get settings_defaultAccount2;

  /// No description provided for @settings_signInAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Sign in automatically'**
  String get settings_signInAutomatically;

  /// No description provided for @settings_signInCredentials.
  ///
  /// In en, this message translates to:
  /// **'Sign-in credentials'**
  String get settings_signInCredentials;

  /// No description provided for @settings_translationInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Translation interfaces'**
  String get settings_translationInterfaces;

  /// No description provided for @settings_presetsBuiltInRules.
  ///
  /// In en, this message translates to:
  /// **'Presets & built-in rules'**
  String get settings_presetsBuiltInRules;

  /// No description provided for @settings_preferenceBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Preference backup & restore'**
  String get settings_preferenceBackupRestore;

  /// No description provided for @settings_searchSettingsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Search settings and features'**
  String get settings_searchSettingsFeatures;

  /// No description provided for @settings_noMatchingSettings.
  ///
  /// In en, this message translates to:
  /// **'No matching settings'**
  String get settings_noMatchingSettings;

  /// No description provided for @settings_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settings_change;

  /// No description provided for @settings_couldNotPlaySoundCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not play the sound. Check the audio file.'**
  String get settings_couldNotPlaySoundCheck;

  /// No description provided for @settings_useDefaultCompletionSound.
  ///
  /// In en, this message translates to:
  /// **'Use the default completion sound'**
  String get settings_useDefaultCompletionSound;

  /// No description provided for @settings_soundPreview.
  ///
  /// In en, this message translates to:
  /// **'Sound preview'**
  String get settings_soundPreview;

  /// No description provided for @settings_listenCurrentCompletionSound.
  ///
  /// In en, this message translates to:
  /// **'Listen to the current completion sound'**
  String get settings_listenCurrentCompletionSound;

  /// No description provided for @settings_playSound.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get settings_playSound;

  /// No description provided for @settings_searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get settings_searchResults;

  /// No description provided for @settings_promptInput.
  ///
  /// In en, this message translates to:
  /// **'Prompt input'**
  String get settings_promptInput;

  /// No description provided for @settings_manageTranslationModelsRules.
  ///
  /// In en, this message translates to:
  /// **'Manage translation models & rules'**
  String get settings_manageTranslationModelsRules;

  /// No description provided for @settings_browsing.
  ///
  /// In en, this message translates to:
  /// **'Browsing'**
  String get settings_browsing;

  /// No description provided for @settings_chooseHowViewImages.
  ///
  /// In en, this message translates to:
  /// **'Choose how to view images'**
  String get settings_chooseHowViewImages;

  /// No description provided for @settings_canvasControls.
  ///
  /// In en, this message translates to:
  /// **'Canvas controls'**
  String get settings_canvasControls;

  /// No description provided for @settings_keepViewSteady.
  ///
  /// In en, this message translates to:
  /// **'Keep the view steady'**
  String get settings_keepViewSteady;

  /// No description provided for @settings_appearance2.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance2;

  /// No description provided for @settings_chooseLightDarkWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose a light or dark workspace'**
  String get settings_chooseLightDarkWorkspace;

  /// No description provided for @settings_textLanguage.
  ///
  /// In en, this message translates to:
  /// **'Text & language'**
  String get settings_textLanguage;

  /// No description provided for @settings_makeReadingComfortable.
  ///
  /// In en, this message translates to:
  /// **'Make reading comfortable'**
  String get settings_makeReadingComfortable;

  /// No description provided for @settings_adjustSettingsPagesDialogsOnly.
  ///
  /// In en, this message translates to:
  /// **'Adjust settings pages and dialogs only'**
  String get settings_adjustSettingsPagesDialogsOnly;

  /// No description provided for @settings_motionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Motion & notifications'**
  String get settings_motionNotifications;

  /// No description provided for @settings_reduceDistractionsKnowWorkFinishes.
  ///
  /// In en, this message translates to:
  /// **'Reduce distractions, know when work finishes'**
  String get settings_reduceDistractionsKnowWorkFinishes;

  /// No description provided for @settings_notificationStyle.
  ///
  /// In en, this message translates to:
  /// **'Notification style'**
  String get settings_notificationStyle;

  /// No description provided for @settings_notificationsAppearUpperRightWrap.
  ///
  /// In en, this message translates to:
  /// **'Notifications appear at the upper right, wrap long messages, and close when progress tasks finish.'**
  String get settings_notificationsAppearUpperRightWrap;

  /// No description provided for @settings_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settings_preview;

  /// No description provided for @settings_versionUpdates.
  ///
  /// In en, this message translates to:
  /// **'Version & updates'**
  String get settings_versionUpdates;

  /// No description provided for @settings_currentVersionUpdateOptions.
  ///
  /// In en, this message translates to:
  /// **'Current version and update options'**
  String get settings_currentVersionUpdateOptions;

  /// No description provided for @settings_diagnosticsResources.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics & resources'**
  String get settings_diagnosticsResources;

  /// No description provided for @settings_logsFontsOpenSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Logs, fonts and the open-source project'**
  String get settings_logsFontsOpenSourceProject;

  /// No description provided for @settings_viewLicenses.
  ///
  /// In en, this message translates to:
  /// **'View licenses'**
  String get settings_viewLicenses;

  /// No description provided for @settings_openProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get settings_openProject;

  /// No description provided for @settings_actionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Action incomplete'**
  String get settings_actionIncomplete;

  /// No description provided for @settings_exportPreferences.
  ///
  /// In en, this message translates to:
  /// **'Export preferences'**
  String get settings_exportPreferences;

  /// No description provided for @settings_preferencesExported.
  ///
  /// In en, this message translates to:
  /// **'Preferences exported'**
  String get settings_preferencesExported;

  /// No description provided for @settings_noAutomaticBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup yet'**
  String get settings_noAutomaticBackupYet;

  /// No description provided for @settings_restorePreviousPreferences.
  ///
  /// In en, this message translates to:
  /// **'Restore previous preferences'**
  String get settings_restorePreviousPreferences;

  /// No description provided for @settings_importPreferences.
  ///
  /// In en, this message translates to:
  /// **'Import preferences'**
  String get settings_importPreferences;

  /// No description provided for @settings_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get settings_apply;

  /// No description provided for @settings_preferencesAppliedPreviousSettingsBacked.
  ///
  /// In en, this message translates to:
  /// **'Preferences applied; previous settings backed up'**
  String get settings_preferencesAppliedPreviousSettingsBacked;

  /// No description provided for @settings_restoreDefaultPreferences.
  ///
  /// In en, this message translates to:
  /// **'Restore default preferences'**
  String get settings_restoreDefaultPreferences;

  /// No description provided for @settings_choosePreferencesResetCurrentSettings.
  ///
  /// In en, this message translates to:
  /// **'Choose the preferences to reset. Current settings will be backed up.'**
  String get settings_choosePreferencesResetCurrentSettings;

  /// No description provided for @settings_appearanceSoundControls.
  ///
  /// In en, this message translates to:
  /// **'Appearance, sound & controls'**
  String get settings_appearanceSoundControls;

  /// No description provided for @settings_inputAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Input & autocomplete'**
  String get settings_inputAutocomplete;

  /// No description provided for @settings_privacyGenerationProtection.
  ///
  /// In en, this message translates to:
  /// **'Privacy & generation protection'**
  String get settings_privacyGenerationProtection;

  /// No description provided for @settings_moveAppearanceControlsInputProtection.
  ///
  /// In en, this message translates to:
  /// **'Move appearance, controls, input and protection preferences between devices.'**
  String get settings_moveAppearanceControlsInputProtection;

  /// No description provided for @settings_rollbackCopySavedBeforeImport.
  ///
  /// In en, this message translates to:
  /// **'A rollback copy is saved before an import or reset.'**
  String get settings_rollbackCopySavedBeforeImport;

  /// No description provided for @settings_resetSelectedScopeWhileKeeping.
  ///
  /// In en, this message translates to:
  /// **'Reset a selected scope while keeping accounts, models, libraries and creative work.'**
  String get settings_resetSelectedScopeWhileKeeping;

  /// No description provided for @settings_chooseScope.
  ///
  /// In en, this message translates to:
  /// **'Choose scope'**
  String get settings_chooseScope;

  /// No description provided for @settings_preferenceManagement.
  ///
  /// In en, this message translates to:
  /// **'Preference management'**
  String get settings_preferenceManagement;

  /// No description provided for @settings_backupMigrationRecovery.
  ///
  /// In en, this message translates to:
  /// **'Backup, migration and recovery'**
  String get settings_backupMigrationRecovery;

  /// No description provided for @settings_generalAppearance.
  ///
  /// In en, this message translates to:
  /// **'General & appearance'**
  String get settings_generalAppearance;

  /// No description provided for @settings_makeWorkspaceComfortableReadUse.
  ///
  /// In en, this message translates to:
  /// **'Make the workspace comfortable to read and use.'**
  String get settings_makeWorkspaceComfortableReadUse;

  /// No description provided for @settings_controlsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Controls & shortcuts'**
  String get settings_controlsShortcuts;

  /// No description provided for @settings_chooseInteractionCanvasControlsKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Choose interaction, canvas controls and keyboard shortcuts.'**
  String get settings_chooseInteractionCanvasControlsKeyboard;

  /// No description provided for @settings_generationPrompts.
  ///
  /// In en, this message translates to:
  /// **'Generation & prompts'**
  String get settings_generationPrompts;

  /// No description provided for @settings_managePromptInputGenerationReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage prompt input, generation reminders and request pacing.'**
  String get settings_managePromptInputGenerationReminders;

  /// No description provided for @settings_galleryFiles.
  ///
  /// In en, this message translates to:
  /// **'Gallery & files'**
  String get settings_galleryFiles;

  /// No description provided for @settings_manageImageSavingGallerySources.
  ///
  /// In en, this message translates to:
  /// **'Manage image saving, gallery sources and display.'**
  String get settings_manageImageSavingGallerySources;

  /// No description provided for @settings_manageTagDictionariesIndexesCache.
  ///
  /// In en, this message translates to:
  /// **'Manage tag dictionaries, indexes and cache maintenance.'**
  String get settings_manageTagDictionariesIndexesCache;

  /// No description provided for @settings_novelaiAccounts.
  ///
  /// In en, this message translates to:
  /// **'NovelAI accounts'**
  String get settings_novelaiAccounts;

  /// No description provided for @settings_viewAccountManageSignIn.
  ///
  /// In en, this message translates to:
  /// **'View your account and manage sign-in and the default account.'**
  String get settings_viewAccountManageSignIn;

  /// No description provided for @settings_connectionsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Connections & integrations'**
  String get settings_connectionsIntegrations;

  /// No description provided for @settings_manageExternalToolsBridgesNetwork.
  ///
  /// In en, this message translates to:
  /// **'Manage external tools, bridges and network settings.'**
  String get settings_manageExternalToolsBridgesNetwork;

  /// No description provided for @settings_privacySharing2.
  ///
  /// In en, this message translates to:
  /// **'Privacy & sharing'**
  String get settings_privacySharing2;

  /// No description provided for @settings_controlSharedInformationConfirmationBefore.
  ///
  /// In en, this message translates to:
  /// **'Control shared information and confirmation before sensitive actions.'**
  String get settings_controlSharedInformationConfirmationBefore;

  /// No description provided for @settings_aboutDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'About & diagnostics'**
  String get settings_aboutDiagnostics;

  /// No description provided for @settings_updatesLogsProjectInformation.
  ///
  /// In en, this message translates to:
  /// **'Updates, logs and project information.'**
  String get settings_updatesLogsProjectInformation;

  /// No description provided for @settings_searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settings_searchSettings;

  /// No description provided for @settings_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_preferences;

  /// No description provided for @settings_creationResources.
  ///
  /// In en, this message translates to:
  /// **'Creation & resources'**
  String get settings_creationResources;

  /// No description provided for @settings_servicesConnections.
  ///
  /// In en, this message translates to:
  /// **'Services & connections'**
  String get settings_servicesConnections;

  /// No description provided for @settings_safetyMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Safety & maintenance'**
  String get settings_safetyMaintenance;

  /// No description provided for @settings_subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get settings_subscriptionActive;

  /// No description provided for @settings_availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get settings_availableBalance;

  /// No description provided for @settings_subscriptionExpiry2.
  ///
  /// In en, this message translates to:
  /// **'Subscription expiry'**
  String get settings_subscriptionExpiry2;

  /// No description provided for @settings_subscriptionDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription details are unavailable'**
  String get settings_subscriptionDetailsUnavailable;

  /// No description provided for @settings_loadingSubscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading subscription details…'**
  String get settings_loadingSubscriptionDetails;

  /// No description provided for @settings_localDataStaysAvailableAfter.
  ///
  /// In en, this message translates to:
  /// **'Local data stays available after expiry.'**
  String get settings_localDataStaysAvailableAfter;

  /// No description provided for @settings_records.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get settings_records;

  /// No description provided for @settings_hitRate.
  ///
  /// In en, this message translates to:
  /// **'Hit rate'**
  String get settings_hitRate;

  /// No description provided for @settings_images.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get settings_images;

  /// No description provided for @settings_cacheOverview.
  ///
  /// In en, this message translates to:
  /// **'Cache overview'**
  String get settings_cacheOverview;

  /// No description provided for @settings_loginPreferences.
  ///
  /// In en, this message translates to:
  /// **'Login preferences'**
  String get settings_loginPreferences;

  /// No description provided for @settings_preselectedSignInPage.
  ///
  /// In en, this message translates to:
  /// **'Preselected on the sign-in page.'**
  String get settings_preselectedSignInPage;

  /// No description provided for @settings_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get settings_noAccounts;

  /// No description provided for @settings_useLastSessionOffNext.
  ///
  /// In en, this message translates to:
  /// **'Use the last session. When off, the next launch opens sign-in.'**
  String get settings_useLastSessionOffNext;

  /// No description provided for @settings_couldNotSaveLoginPreference.
  ///
  /// In en, this message translates to:
  /// **'Could not save the login preference.'**
  String get settings_couldNotSaveLoginPreference;

  /// No description provided for @settings_loginPreferencesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Login preferences are unavailable.'**
  String get settings_loginPreferencesUnavailable;

  /// No description provided for @settings_applyPreferencesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} preferences. Current preferences are backed up automatically and can be recovered from “Restore previous preferences”. Accounts, secrets, drafts, libraries and model configurations are kept separately.'**
  String settings_applyPreferencesConfirm(Object count);

  /// No description provided for @settings_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settings_restore;

  /// No description provided for @wiki_translating.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get wiki_translating;

  /// No description provided for @wiki_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wiki_back;

  /// No description provided for @wiki_readingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get wiki_readingTranslation;

  /// No description provided for @wiki_readingOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get wiki_readingOriginal;

  /// No description provided for @wiki_readingBilingual.
  ///
  /// In en, this message translates to:
  /// **'Bilingual'**
  String get wiki_readingBilingual;

  /// No description provided for @wiki_bilingualUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No aligned source text for this translation; showing the translation'**
  String get wiki_bilingualUnavailable;

  /// No description provided for @wiki_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get wiki_open;

  /// No description provided for @wiki_switchToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get wiki_switchToOriginal;

  /// No description provided for @wiki_switchToTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get wiki_switchToTranslation;

  /// No description provided for @wiki_retranslate.
  ///
  /// In en, this message translates to:
  /// **'Retranslate'**
  String get wiki_retranslate;

  /// No description provided for @wiki_onThisPage.
  ///
  /// In en, this message translates to:
  /// **'On this page'**
  String get wiki_onThisPage;

  /// No description provided for @wiki_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get wiki_overview;

  /// No description provided for @wiki_untranslated.
  ///
  /// In en, this message translates to:
  /// **'Not translated yet'**
  String get wiki_untranslated;

  /// No description provided for @wiki_autoTranslateTagsArticles.
  ///
  /// In en, this message translates to:
  /// **'Auto-translate tags and articles'**
  String get wiki_autoTranslateTagsArticles;

  /// No description provided for @wiki_readingContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get wiki_readingContent;

  /// No description provided for @wiki_categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get wiki_categoryGeneral;

  /// No description provided for @wiki_categoryArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get wiki_categoryArtist;

  /// No description provided for @wiki_categoryCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get wiki_categoryCopyright;

  /// No description provided for @wiki_categoryCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get wiki_categoryCharacter;

  /// No description provided for @wiki_categoryMeta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get wiki_categoryMeta;

  /// No description provided for @wiki_categoryContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get wiki_categoryContributor;

  /// No description provided for @wiki_categorySpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get wiki_categorySpecies;

  /// No description provided for @wiki_categoryLore.
  ///
  /// In en, this message translates to:
  /// **'Lore'**
  String get wiki_categoryLore;

  /// No description provided for @wiki_categoryLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get wiki_categoryLibrary;

  /// No description provided for @wiki_addToBlock.
  ///
  /// In en, this message translates to:
  /// **'Add to blocks'**
  String get wiki_addToBlock;

  /// No description provided for @wiki_forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get wiki_forward;

  /// No description provided for @wiki_posts.
  ///
  /// In en, this message translates to:
  /// **'posts'**
  String get wiki_posts;

  /// No description provided for @wiki_aliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get wiki_aliases;

  /// No description provided for @wiki_relatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Often used with'**
  String get wiki_relatedTitle;

  /// No description provided for @wiki_relatedHint.
  ///
  /// In en, this message translates to:
  /// **'Click to open · Shift+click to add to blocks'**
  String get wiki_relatedHint;

  /// No description provided for @wiki_inDirectory.
  ///
  /// In en, this message translates to:
  /// **'In directory'**
  String get wiki_inDirectory;

  /// No description provided for @wiki_noArticle.
  ///
  /// In en, this message translates to:
  /// **'No wiki'**
  String get wiki_noArticle;

  /// No description provided for @wiki_moreCategories.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get wiki_moreCategories;

  /// No description provided for @wiki_shortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts: / search · ↑↓ move · Enter add to blocks · B bookmark · Alt+←/→ history'**
  String get wiki_shortcutsHint;

  /// No description provided for @toast_titleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get toast_titleSuccess;

  /// No description provided for @toast_titleError.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get toast_titleError;

  /// No description provided for @toast_titleWarning.
  ///
  /// In en, this message translates to:
  /// **'Please note'**
  String get toast_titleWarning;

  /// No description provided for @toast_titleInfo.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get toast_titleInfo;

  /// No description provided for @toast_titleProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get toast_titleProgress;

  /// No description provided for @tagExpansion_autoTranslateVisible.
  ///
  /// In en, this message translates to:
  /// **'Auto-translate visible tags'**
  String get tagExpansion_autoTranslateVisible;

  /// No description provided for @translationEditor_title.
  ///
  /// In en, this message translates to:
  /// **'Translation block'**
  String get translationEditor_title;

  /// No description provided for @translationEditor_source.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get translationEditor_source;

  /// No description provided for @translationEditor_sourcePrefix.
  ///
  /// In en, this message translates to:
  /// **'Src'**
  String get translationEditor_sourcePrefix;

  /// No description provided for @translationEditor_generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get translationEditor_generation;

  /// No description provided for @translationEditor_editable.
  ///
  /// In en, this message translates to:
  /// **'Editable'**
  String get translationEditor_editable;

  /// No description provided for @translationEditor_modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get translationEditor_modified;

  /// No description provided for @translationEditor_edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get translationEditor_edited;

  /// No description provided for @translationEditor_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get translationEditor_close;

  /// No description provided for @translationEditor_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get translationEditor_save;

  /// No description provided for @translationEditor_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get translationEditor_delete;

  /// No description provided for @translationEditor_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore original text'**
  String get translationEditor_restore;

  /// No description provided for @translationEditor_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure translation model'**
  String get translationEditor_configure;

  /// No description provided for @translationEditor_readingFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'{language} reading text'**
  String translationEditor_readingFieldTitle(Object language);

  /// No description provided for @translationEditor_sourceWarning.
  ///
  /// In en, this message translates to:
  /// **'Original modified; {language} needs syncing'**
  String translationEditor_sourceWarning(Object language);

  /// No description provided for @translationEditor_editHint.
  ///
  /// In en, this message translates to:
  /// **'Translation edited manually; original review status is unchanged'**
  String get translationEditor_editHint;

  /// No description provided for @translationLanguage_chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get translationLanguage_chinese;

  /// No description provided for @translationLanguage_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get translationLanguage_english;

  /// No description provided for @translationLanguage_japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get translationLanguage_japanese;

  /// No description provided for @translationLanguage_korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get translationLanguage_korean;

  /// No description provided for @translationLanguage_traditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get translationLanguage_traditionalChinese;

  /// No description provided for @promptBlockEditor_translationNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Original changed; translation needs updating'**
  String get promptBlockEditor_translationNeedsReview;

  /// No description provided for @promptBlockEditor_translationReviewHint.
  ///
  /// In en, this message translates to:
  /// **'After editing the original, review this translation as well'**
  String get promptBlockEditor_translationReviewHint;

  /// No description provided for @modelTask_translateTitle.
  ///
  /// In en, this message translates to:
  /// **'Original → reading language'**
  String get modelTask_translateTitle;

  /// No description provided for @modelTask_promptReverseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading language → original'**
  String get modelTask_promptReverseTitle;

  /// No description provided for @modelTask_tagTranslateTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag name translation'**
  String get modelTask_tagTranslateTitle;

  /// No description provided for @modelTask_wikiTranslateTitle.
  ///
  /// In en, this message translates to:
  /// **'Wiki article translation'**
  String get modelTask_wikiTranslateTitle;

  /// No description provided for @modelTask_translateDescription.
  ///
  /// In en, this message translates to:
  /// **'Translate prompts and blocks while preserving weights, groups and tag meaning.'**
  String get modelTask_translateDescription;

  /// No description provided for @modelTask_promptReverseDescription.
  ///
  /// In en, this message translates to:
  /// **'Apply additions, deletions and edits from the translation to the original, then return it for review.'**
  String get modelTask_promptReverseDescription;

  /// No description provided for @modelTask_tagTranslateDescription.
  ///
  /// In en, this message translates to:
  /// **'Give visible tags concise, accurate names.'**
  String get modelTask_tagTranslateDescription;

  /// No description provided for @modelTask_wikiTranslateDescription.
  ///
  /// In en, this message translates to:
  /// **'Translate wiki articles, tidy the layout and choose clickable tags from context.'**
  String get modelTask_wikiTranslateDescription;

  /// No description provided for @modelTask_connectionTest.
  ///
  /// In en, this message translates to:
  /// **'Model connection test'**
  String get modelTask_connectionTest;

  /// No description provided for @modelReasoning_serviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Service default'**
  String get modelReasoning_serviceDefault;

  /// No description provided for @modelReasoning_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get modelReasoning_off;

  /// No description provided for @modelReasoning_on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get modelReasoning_on;

  /// No description provided for @modelReasoning_minimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get modelReasoning_minimal;

  /// No description provided for @modelReasoning_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get modelReasoning_low;

  /// No description provided for @modelReasoning_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get modelReasoning_medium;

  /// No description provided for @modelReasoning_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get modelReasoning_high;

  /// No description provided for @modelReasoning_xhigh.
  ///
  /// In en, this message translates to:
  /// **'Extra high'**
  String get modelReasoning_xhigh;

  /// No description provided for @modelReasoning_max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get modelReasoning_max;

  /// No description provided for @modelProvider_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom service'**
  String get modelProvider_custom;

  /// No description provided for @modelProvider_qwen.
  ///
  /// In en, this message translates to:
  /// **'Qwen · Alibaba Model Studio'**
  String get modelProvider_qwen;

  /// No description provided for @modelProvider_moonshot.
  ///
  /// In en, this message translates to:
  /// **'Kimi · Moonshot AI'**
  String get modelProvider_moonshot;

  /// No description provided for @modelProvider_zhipu.
  ///
  /// In en, this message translates to:
  /// **'Zhipu GLM'**
  String get modelProvider_zhipu;

  /// No description provided for @modelProvider_doubao.
  ///
  /// In en, this message translates to:
  /// **'Doubao · Volcano Ark'**
  String get modelProvider_doubao;

  /// No description provided for @modelProvider_hunyuan.
  ///
  /// In en, this message translates to:
  /// **'Tencent Hunyuan'**
  String get modelProvider_hunyuan;

  /// No description provided for @modelProvider_qianfan.
  ///
  /// In en, this message translates to:
  /// **'Baidu Qianfan'**
  String get modelProvider_qianfan;

  /// No description provided for @modelProvider_siliconflow.
  ///
  /// In en, this message translates to:
  /// **'SiliconFlow'**
  String get modelProvider_siliconflow;

  /// No description provided for @modelProvider_zai.
  ///
  /// In en, this message translates to:
  /// **'Z.AI · International'**
  String get modelProvider_zai;

  /// No description provided for @modelProvider_zhipuCodingPlan.
  ///
  /// In en, this message translates to:
  /// **'Zhipu Coding Plan'**
  String get modelProvider_zhipuCodingPlan;

  /// No description provided for @modelProvider_kimiCoding.
  ///
  /// In en, this message translates to:
  /// **'Kimi Coding'**
  String get modelProvider_kimiCoding;

  /// No description provided for @modelProvider_moonshotInternational.
  ///
  /// In en, this message translates to:
  /// **'Moonshot AI · International'**
  String get modelProvider_moonshotInternational;

  /// No description provided for @modelProvider_minimaxChinaChat.
  ///
  /// In en, this message translates to:
  /// **'MiniMax · China OpenAI'**
  String get modelProvider_minimaxChinaChat;

  /// No description provided for @modelProvider_minimaxChinaMessages.
  ///
  /// In en, this message translates to:
  /// **'MiniMax · China Anthropic'**
  String get modelProvider_minimaxChinaMessages;

  /// No description provided for @modelProvider_minimaxInternationalMessages.
  ///
  /// In en, this message translates to:
  /// **'MiniMax · International Anthropic'**
  String get modelProvider_minimaxInternationalMessages;

  /// No description provided for @modelProvider_xiaomi.
  ///
  /// In en, this message translates to:
  /// **'Xiaomi MiMo'**
  String get modelProvider_xiaomi;

  /// No description provided for @modelProvider_antLing.
  ///
  /// In en, this message translates to:
  /// **'Ant Ling'**
  String get modelProvider_antLing;

  /// No description provided for @modelProvider_stepfunPlan.
  ///
  /// In en, this message translates to:
  /// **'StepFun Step Plan'**
  String get modelProvider_stepfunPlan;

  /// No description provided for @modelProvider_qwenTokenPlanChina.
  ///
  /// In en, this message translates to:
  /// **'Qwen Token Plan · China'**
  String get modelProvider_qwenTokenPlanChina;

  /// No description provided for @modelProvider_hintHuggingFace.
  ///
  /// In en, this message translates to:
  /// **'Use a Hugging Face token with inference permission; router model IDs can be added manually.'**
  String get modelProvider_hintHuggingFace;

  /// No description provided for @modelProvider_hintPlanKey.
  ///
  /// In en, this message translates to:
  /// **'Use the API key for this plan; available models and scope follow what the plan returns.'**
  String get modelProvider_hintPlanKey;

  /// No description provided for @modelProvider_hintInternationalEndpoint.
  ///
  /// In en, this message translates to:
  /// **'International endpoint; use an API key from the international platform.'**
  String get modelProvider_hintInternationalEndpoint;

  /// No description provided for @modelProvider_hintRegionOpenAi.
  ///
  /// In en, this message translates to:
  /// **'Use the API key for the matching region; the OpenAI Chat Completions compatible address is prefilled.'**
  String get modelProvider_hintRegionOpenAi;

  /// No description provided for @modelProvider_hintRegionAnthropic.
  ///
  /// In en, this message translates to:
  /// **'Use the API key for the matching region; the Anthropic Messages compatible address is prefilled.'**
  String get modelProvider_hintRegionAnthropic;

  /// No description provided for @modelProvider_hintQwen.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the Beijing region; for other regions use the matching key and change the endpoint.'**
  String get modelProvider_hintQwen;

  /// No description provided for @modelProvider_hintMinimax.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the international pay-as-you-go endpoint; for the China platform use its key and endpoint.'**
  String get modelProvider_hintMinimax;

  /// No description provided for @modelProvider_hintMoonshot.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the China platform; for the international platform use its key and endpoint.'**
  String get modelProvider_hintMoonshot;

  /// No description provided for @modelProvider_hintZhipu.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the pay-as-you-go endpoint; Coding Plan uses its own address.'**
  String get modelProvider_hintZhipu;

  /// No description provided for @modelProvider_hintDoubao.
  ///
  /// In en, this message translates to:
  /// **'Use an Ark API key; enable the model first, or add an inference endpoint ID.'**
  String get modelProvider_hintDoubao;

  /// No description provided for @modelProvider_hintCustom.
  ///
  /// In en, this message translates to:
  /// **'Enter the compatible service address and key, then choose the protocol in the connection details.'**
  String get modelProvider_hintCustom;

  /// No description provided for @modelProvider_hintLocal.
  ///
  /// In en, this message translates to:
  /// **'Start the local service first, then read the loaded model list.'**
  String get modelProvider_hintLocal;

  /// No description provided for @modelProvider_hintDefault.
  ///
  /// In en, this message translates to:
  /// **'Address and protocol are prefilled; save a key to start choosing models.'**
  String get modelProvider_hintDefault;

  /// No description provided for @modelParams_temperatureRange.
  ///
  /// In en, this message translates to:
  /// **'Temperature must be between 0 and 2.'**
  String get modelParams_temperatureRange;

  /// No description provided for @modelParams_topPRange.
  ///
  /// In en, this message translates to:
  /// **'Top P must be greater than 0 and at most 1.'**
  String get modelParams_topPRange;

  /// No description provided for @modelParams_maxOutputPositive.
  ///
  /// In en, this message translates to:
  /// **'Max output tokens must be greater than 0.'**
  String get modelParams_maxOutputPositive;

  /// No description provided for @modelParams_anthropicTemperatureRange.
  ///
  /// In en, this message translates to:
  /// **'Anthropic temperature must be between 0 and 1.'**
  String get modelParams_anthropicTemperatureRange;

  /// No description provided for @modelParams_anthropicSamplingConflict.
  ///
  /// In en, this message translates to:
  /// **'Anthropic accepts either temperature or Top P; check the model parameters.'**
  String get modelParams_anthropicSamplingConflict;

  /// No description provided for @modelParams_thinkingBudgetTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Max output must be larger than the minimum thinking budget of {minimum}.'**
  String modelParams_thinkingBudgetTooSmall(Object minimum);

  /// No description provided for @modelOverrides_invalidHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid header name'**
  String get modelOverrides_invalidHeaderName;

  /// No description provided for @modelOverrides_invalidHeaderValue.
  ///
  /// In en, this message translates to:
  /// **'Header values cannot contain line breaks or control characters'**
  String get modelOverrides_invalidHeaderValue;

  /// No description provided for @modelOverrides_emptyBodyField.
  ///
  /// In en, this message translates to:
  /// **'Body field names cannot be empty'**
  String get modelOverrides_emptyBodyField;

  /// No description provided for @modelOverrides_modelFromList.
  ///
  /// In en, this message translates to:
  /// **'Set the model ID from the model list'**
  String get modelOverrides_modelFromList;

  /// No description provided for @modelOverrides_streamMustBeFalse.
  ///
  /// In en, this message translates to:
  /// **'This connection uses non-streaming requests; stream must be false'**
  String get modelOverrides_streamMustBeFalse;

  /// No description provided for @modelConfig_changedSaveAgain.
  ///
  /// In en, this message translates to:
  /// **'The configuration changed. Save again.'**
  String get modelConfig_changedSaveAgain;

  /// No description provided for @modelConfig_presetChanged.
  ///
  /// In en, this message translates to:
  /// **'The selected preset changed. Choose again.'**
  String get modelConfig_presetChanged;

  /// No description provided for @modelConfig_serviceDisabled.
  ///
  /// In en, this message translates to:
  /// **'The selected service was disabled. Choose again.'**
  String get modelConfig_serviceDisabled;

  /// No description provided for @modelConfig_modelChanged.
  ///
  /// In en, this message translates to:
  /// **'The selected model changed. Choose again.'**
  String get modelConfig_modelChanged;

  /// No description provided for @modelConfig_reasoningChanged.
  ///
  /// In en, this message translates to:
  /// **'The model’s reasoning levels changed. Choose again or follow the model.'**
  String get modelConfig_reasoningChanged;

  /// No description provided for @modelConfig_presetIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Preset ID cannot be empty.'**
  String get modelConfig_presetIdRequired;

  /// No description provided for @modelConfig_saveBuiltinAsCustom.
  ///
  /// In en, this message translates to:
  /// **'Save the built-in preset as a custom preset.'**
  String get modelConfig_saveBuiltinAsCustom;

  /// No description provided for @modelConfig_namePromptRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and prompt cannot be empty.'**
  String get modelConfig_namePromptRequired;

  /// No description provided for @modelConfig_builtinNotDeletable.
  ///
  /// In en, this message translates to:
  /// **'Built-in rules cannot be deleted.'**
  String get modelConfig_builtinNotDeletable;

  /// No description provided for @modelConfig_pasteFullJson.
  ///
  /// In en, this message translates to:
  /// **'Paste the complete model configuration JSON.'**
  String get modelConfig_pasteFullJson;

  /// No description provided for @modelConfig_builtinNotOverwritable.
  ///
  /// In en, this message translates to:
  /// **'Built-in presets cannot be overwritten; copy them as custom presets.'**
  String get modelConfig_builtinNotOverwritable;

  /// No description provided for @modelConfig_invalidProvider.
  ///
  /// In en, this message translates to:
  /// **'Invalid service ID, name or address.'**
  String get modelConfig_invalidProvider;

  /// No description provided for @modelConfig_missingProvider.
  ///
  /// In en, this message translates to:
  /// **'The model’s service does not exist.'**
  String get modelConfig_missingProvider;

  /// No description provided for @modelConfig_invalidCustomPreset.
  ///
  /// In en, this message translates to:
  /// **'Invalid custom preset ID, name or prompt.'**
  String get modelConfig_invalidCustomPreset;

  /// No description provided for @modelConfig_changedImportAgain.
  ///
  /// In en, this message translates to:
  /// **'The configuration changed. Import again.'**
  String get modelConfig_changedImportAgain;

  /// No description provided for @modelHealth_unverified.
  ///
  /// In en, this message translates to:
  /// **'Connection not verified yet; it updates after using a model or “Test connection”.'**
  String get modelHealth_unverified;

  /// No description provided for @modelHealth_healthy.
  ///
  /// In en, this message translates to:
  /// **'The last request succeeded'**
  String get modelHealth_healthy;

  /// No description provided for @modelHealth_limited.
  ///
  /// In en, this message translates to:
  /// **'Reachable, but the last request was rate limited (HTTP 429); try later or check your quota'**
  String get modelHealth_limited;

  /// No description provided for @modelHealth_authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed; check the API key'**
  String get modelHealth_authentication;

  /// No description provided for @modelHealth_permission.
  ///
  /// In en, this message translates to:
  /// **'Access denied; check the service permissions'**
  String get modelHealth_permission;

  /// No description provided for @modelHealth_timeout.
  ///
  /// In en, this message translates to:
  /// **'The last request timed out'**
  String get modelHealth_timeout;

  /// No description provided for @modelHealth_network.
  ///
  /// In en, this message translates to:
  /// **'The last request could not reach the service'**
  String get modelHealth_network;

  /// No description provided for @modelHealth_invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The last response was invalid; see the request log for details'**
  String get modelHealth_invalidResponse;

  /// No description provided for @modelHealth_failed.
  ///
  /// In en, this message translates to:
  /// **'The last request failed'**
  String get modelHealth_failed;

  /// No description provided for @modelHealth_failedStatus.
  ///
  /// In en, this message translates to:
  /// **'The last request failed (HTTP {status})'**
  String modelHealth_failedStatus(Object status);

  /// No description provided for @modelRequest_statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get modelRequest_statusPending;

  /// No description provided for @modelRequest_statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Requesting'**
  String get modelRequest_statusRunning;

  /// No description provided for @modelRequest_statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get modelRequest_statusSuccess;

  /// No description provided for @modelRequest_statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get modelRequest_statusFailed;

  /// No description provided for @modelRequest_statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get modelRequest_statusCancelled;

  /// No description provided for @modelRequest_fieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get modelRequest_fieldTime;

  /// No description provided for @modelRequest_fieldMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get modelRequest_fieldMethod;

  /// No description provided for @modelRequest_fieldUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get modelRequest_fieldUrl;

  /// No description provided for @modelRequest_fieldRequestHeaders.
  ///
  /// In en, this message translates to:
  /// **'Request headers'**
  String get modelRequest_fieldRequestHeaders;

  /// No description provided for @modelRequest_fieldBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get modelRequest_fieldBody;

  /// No description provided for @modelRequest_fieldStatusCode.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get modelRequest_fieldStatusCode;

  /// No description provided for @modelRequest_fieldResponseHeaders.
  ///
  /// In en, this message translates to:
  /// **'Response headers'**
  String get modelRequest_fieldResponseHeaders;

  /// No description provided for @modelRequest_fieldError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get modelRequest_fieldError;

  /// No description provided for @modelRequest_fieldInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get modelRequest_fieldInterface;

  /// No description provided for @modelRequest_fieldProvider.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get modelRequest_fieldProvider;

  /// No description provided for @modelRequest_fieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelRequest_fieldModel;

  /// No description provided for @modelRequest_fieldProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get modelRequest_fieldProtocol;

  /// No description provided for @modelRequest_fieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get modelRequest_fieldStatus;

  /// No description provided for @modelRequest_fieldElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed (ms)'**
  String get modelRequest_fieldElapsed;

  /// No description provided for @modelRequest_fieldAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get modelRequest_fieldAttempts;

  /// No description provided for @modelRequest_fieldHttpRequests.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests'**
  String get modelRequest_fieldHttpRequests;

  /// No description provided for @modelRequest_fieldParameters.
  ///
  /// In en, this message translates to:
  /// **'Effective parameters'**
  String get modelRequest_fieldParameters;

  /// No description provided for @modelRequest_redacted.
  ///
  /// In en, this message translates to:
  /// **'[redacted]'**
  String get modelRequest_redacted;

  /// No description provided for @modelRequest_emptyResponse.
  ///
  /// In en, this message translates to:
  /// **'The model returned empty content.'**
  String get modelRequest_emptyResponse;

  /// No description provided for @modelService_testFieldsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The test response is missing fields.'**
  String get modelService_testFieldsIncomplete;

  /// No description provided for @modelService_testFieldsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The test response has invalid fields.'**
  String get modelService_testFieldsInvalid;

  /// No description provided for @modelService_testGroupsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The test response has invalid groups.'**
  String get modelService_testGroupsInvalid;

  /// No description provided for @modelService_testSourceEmpty.
  ///
  /// In en, this message translates to:
  /// **'The test response returned an empty original.'**
  String get modelService_testSourceEmpty;

  /// No description provided for @modelService_conversionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Conversion cancelled'**
  String get modelService_conversionCancelled;

  /// No description provided for @modelService_chooseInterfaceModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a service and model in Settings → Models & APIs → Interfaces first.'**
  String get modelService_chooseInterfaceModel;

  /// No description provided for @modelService_enableServiceModel.
  ///
  /// In en, this message translates to:
  /// **'Enable a service in Settings, then fetch or add a model and select it.'**
  String get modelService_enableServiceModel;

  /// No description provided for @modelSettings_keepEditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep current edits?'**
  String get modelSettings_keepEditsTitle;

  /// No description provided for @modelSettings_keepEditsBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes are not saved yet. Save before switching?'**
  String get modelSettings_keepEditsBody;

  /// No description provided for @modelSettings_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get modelSettings_discard;

  /// No description provided for @modelSettings_saveAndSwitch.
  ///
  /// In en, this message translates to:
  /// **'Save and switch'**
  String get modelSettings_saveAndSwitch;

  /// No description provided for @modelSettings_addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get modelSettings_addProvider;

  /// No description provided for @modelSettings_deleteProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String modelSettings_deleteProviderTitle(Object name);

  /// No description provided for @modelSettings_deleteProviderBody.
  ///
  /// In en, this message translates to:
  /// **'This service’s connection, key and selected models will be deleted.'**
  String get modelSettings_deleteProviderBody;

  /// No description provided for @modelSettings_deleteProviderBindings.
  ///
  /// In en, this message translates to:
  /// **'{count} interface model bindings will be cleared; presets are kept.'**
  String modelSettings_deleteProviderBindings(Object count);

  /// No description provided for @modelSettings_deletePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String modelSettings_deletePresetTitle(Object name);

  /// No description provided for @modelSettings_deletePresetBody.
  ///
  /// In en, this message translates to:
  /// **'Interfaces using this preset return to the built-in preset. Model bindings are kept.'**
  String get modelSettings_deletePresetBody;

  /// No description provided for @modelSettings_configCopied.
  ///
  /// In en, this message translates to:
  /// **'Configuration copied, without keys, custom headers or bodies.'**
  String get modelSettings_configCopied;

  /// No description provided for @modelSettings_importConfig.
  ///
  /// In en, this message translates to:
  /// **'Import configuration'**
  String get modelSettings_importConfig;

  /// No description provided for @modelSettings_importConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Paste an exported configuration. The current configuration is backed up first; keys stay stored separately.'**
  String get modelSettings_importConfigHint;

  /// No description provided for @modelSettings_configJson.
  ///
  /// In en, this message translates to:
  /// **'Configuration JSON'**
  String get modelSettings_configJson;

  /// No description provided for @modelSettings_importPreview.
  ///
  /// In en, this message translates to:
  /// **'Imports {providers} services, {models} models and {presets} custom presets.'**
  String modelSettings_importPreview(
    Object providers,
    Object models,
    Object presets,
  );

  /// No description provided for @modelSettings_importMissingProviders.
  ///
  /// In en, this message translates to:
  /// **'Service or model configuration is missing.'**
  String get modelSettings_importMissingProviders;

  /// No description provided for @modelSettings_checkConfig.
  ///
  /// In en, this message translates to:
  /// **'Check configuration'**
  String get modelSettings_checkConfig;

  /// No description provided for @modelSettings_importAndReplace.
  ///
  /// In en, this message translates to:
  /// **'Import and replace'**
  String get modelSettings_importAndReplace;

  /// No description provided for @modelSettings_configImported.
  ///
  /// In en, this message translates to:
  /// **'Configuration imported'**
  String get modelSettings_configImported;

  /// No description provided for @modelSettings_description.
  ///
  /// In en, this message translates to:
  /// **'Manage service connections and translation preferences.'**
  String get modelSettings_description;

  /// No description provided for @modelSettings_configMenu.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get modelSettings_configMenu;

  /// No description provided for @modelSettings_copyConfig.
  ///
  /// In en, this message translates to:
  /// **'Copy configuration'**
  String get modelSettings_copyConfig;

  /// No description provided for @modelSettings_tabProviders.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get modelSettings_tabProviders;

  /// No description provided for @modelSettings_tabInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Interfaces'**
  String get modelSettings_tabInterfaces;

  /// No description provided for @modelSettings_tabPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets & prompts'**
  String get modelSettings_tabPresets;

  /// No description provided for @modelSettings_tabRequests.
  ///
  /// In en, this message translates to:
  /// **'Request log'**
  String get modelSettings_tabRequests;

  /// No description provided for @modelSettings_providersCount.
  ///
  /// In en, this message translates to:
  /// **'Services · {count}'**
  String modelSettings_providersCount(Object count);

  /// No description provided for @modelSettings_providerModelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} models'**
  String modelSettings_providerModelCount(Object count);

  /// No description provided for @modelSettings_providerDisabledSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Disabled'**
  String get modelSettings_providerDisabledSuffix;

  /// No description provided for @modelSettings_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first model service'**
  String get modelSettings_emptyTitle;

  /// No description provided for @modelSettings_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a common service or connect a custom endpoint.'**
  String get modelSettings_emptyBody;

  /// No description provided for @modelSettings_customService.
  ///
  /// In en, this message translates to:
  /// **'Custom service'**
  String get modelSettings_customService;

  /// No description provided for @modelSettings_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get modelSettings_notConfigured;

  /// No description provided for @modelSettings_preset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get modelSettings_preset;

  /// No description provided for @modelSettings_presetBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get modelSettings_presetBuiltin;

  /// No description provided for @modelSettings_presetUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get modelSettings_presetUser;

  /// No description provided for @modelSettings_deletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete preset'**
  String get modelSettings_deletePreset;

  /// No description provided for @modelSettings_presetCopyName.
  ///
  /// In en, this message translates to:
  /// **'{title} ({number})'**
  String modelSettings_presetCopyName(Object title, Object number);

  /// No description provided for @modelSettings_recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent requests'**
  String get modelSettings_recentRequests;

  /// No description provided for @modelSettings_recentRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Last 100 in this session · full requests and responses, with authentication redacted'**
  String get modelSettings_recentRequestsHint;

  /// No description provided for @modelSettings_clearRequests.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get modelSettings_clearRequests;

  /// No description provided for @modelSettings_requestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Requests appear here after you translate or test a model.'**
  String get modelSettings_requestsEmpty;

  /// No description provided for @modelSettings_interfaceChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'The interface configuration changed elsewhere. Reopen it to edit.'**
  String get modelSettings_interfaceChangedElsewhere;

  /// No description provided for @modelSettings_configSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get modelSettings_configSaved;

  /// No description provided for @modelSettings_viewBuiltinRules.
  ///
  /// In en, this message translates to:
  /// **'View built-in rules'**
  String get modelSettings_viewBuiltinRules;

  /// No description provided for @modelSettings_viewEditPreset.
  ///
  /// In en, this message translates to:
  /// **'View and edit preset'**
  String get modelSettings_viewEditPreset;

  /// No description provided for @modelSettings_restoreBuiltinPreset.
  ///
  /// In en, this message translates to:
  /// **'Restore built-in preset'**
  String get modelSettings_restoreBuiltinPreset;

  /// No description provided for @modelSettings_followUiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow interface language'**
  String get modelSettings_followUiLanguage;

  /// No description provided for @modelSettings_providerAndModel.
  ///
  /// In en, this message translates to:
  /// **'Service and model'**
  String get modelSettings_providerAndModel;

  /// No description provided for @modelSettings_providerAndModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Only selected models from enabled services are listed'**
  String get modelSettings_providerAndModelHelp;

  /// No description provided for @modelSettings_chooseProviderModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a service and model'**
  String get modelSettings_chooseProviderModel;

  /// No description provided for @modelSettings_reasoning.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get modelSettings_reasoning;

  /// No description provided for @modelSettings_reasoningHelp.
  ///
  /// In en, this message translates to:
  /// **'Plain translation usually needs no thinking. For tagging, semantic grouping and similar work, use the lowest thinking level the model supports.'**
  String get modelSettings_reasoningHelp;

  /// No description provided for @modelSettings_reasoningHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'Thinking level advice'**
  String get modelSettings_reasoningHelpLabel;

  /// No description provided for @modelSettings_usePreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get modelSettings_usePreset;

  /// No description provided for @modelSettings_outputLanguage.
  ///
  /// In en, this message translates to:
  /// **'Output language'**
  String get modelSettings_outputLanguage;

  /// No description provided for @modelSettings_englishPrompt.
  ///
  /// In en, this message translates to:
  /// **'English generation prompt'**
  String get modelSettings_englishPrompt;

  /// No description provided for @modelSettings_englishPromptHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies the edits against the original and outputs an English generation prompt.'**
  String get modelSettings_englishPromptHelp;

  /// No description provided for @modelSettings_targetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get modelSettings_targetLanguage;

  /// No description provided for @modelSettings_effective.
  ///
  /// In en, this message translates to:
  /// **'Effective'**
  String get modelSettings_effective;

  /// No description provided for @modelSettings_noModelSelected.
  ///
  /// In en, this message translates to:
  /// **'No available model selected'**
  String get modelSettings_noModelSelected;

  /// No description provided for @modelSettings_reasoningSummaryInterface.
  ///
  /// In en, this message translates to:
  /// **'Thinking: {level} (this interface)'**
  String modelSettings_reasoningSummaryInterface(Object level);

  /// No description provided for @modelSettings_reasoningSummaryModel.
  ///
  /// In en, this message translates to:
  /// **'Thinking: {level} (follows model)'**
  String modelSettings_reasoningSummaryModel(Object level);

  /// No description provided for @modelSettings_promptBlocksHint.
  ///
  /// In en, this message translates to:
  /// **'When translation isn’t needed, you can also split prompts into blocks and arrange them freely with the block feature.'**
  String get modelSettings_promptBlocksHint;

  /// No description provided for @modelSettings_wikiFormatHint.
  ///
  /// In en, this message translates to:
  /// **'When translation isn’t needed, it can still tidy the layout and link related tags.'**
  String get modelSettings_wikiFormatHint;

  /// No description provided for @modelSettings_unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get modelSettings_unsavedChanges;

  /// No description provided for @modelSettings_testPreset.
  ///
  /// In en, this message translates to:
  /// **'Test preset'**
  String get modelSettings_testPreset;

  /// No description provided for @modelSettings_tabModelPreset.
  ///
  /// In en, this message translates to:
  /// **'Model & preset'**
  String get modelSettings_tabModelPreset;

  /// No description provided for @modelSettings_tabPromptOutput.
  ///
  /// In en, this message translates to:
  /// **'Prompt & output'**
  String get modelSettings_tabPromptOutput;

  /// No description provided for @modelSettings_translationStrategy.
  ///
  /// In en, this message translates to:
  /// **'Translation strategy'**
  String get modelSettings_translationStrategy;

  /// No description provided for @modelSettings_editPreset.
  ///
  /// In en, this message translates to:
  /// **'Edit preset'**
  String get modelSettings_editPreset;

  /// No description provided for @modelSettings_outputContract.
  ///
  /// In en, this message translates to:
  /// **'App output contract'**
  String get modelSettings_outputContract;

  /// No description provided for @modelSettings_outputContractHint.
  ///
  /// In en, this message translates to:
  /// **'Returned fields and validation rules are maintained by the app'**
  String get modelSettings_outputContractHint;

  /// No description provided for @modelSettings_testResult.
  ///
  /// In en, this message translates to:
  /// **'Test result'**
  String get modelSettings_testResult;

  /// No description provided for @modelRequest_detailsRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get modelRequest_detailsRequests;

  /// No description provided for @modelRequest_detailsIndex.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get modelRequest_detailsIndex;

  /// No description provided for @modelRequest_detailsResponses.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get modelRequest_detailsResponses;

  /// No description provided for @modelRequest_detailsOutput.
  ///
  /// In en, this message translates to:
  /// **'Extracted result'**
  String get modelRequest_detailsOutput;

  /// No description provided for @modelRequest_detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request log'**
  String get modelRequest_detailsTitle;

  /// No description provided for @modelRequest_detailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get modelRequest_detailsCopied;

  /// No description provided for @modelRequest_detailsCopyPage.
  ///
  /// In en, this message translates to:
  /// **'Copy this page'**
  String get modelRequest_detailsCopyPage;

  /// No description provided for @modelRequest_detailsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get modelRequest_detailsOverview;

  /// No description provided for @modelRequest_detailsMissing.
  ///
  /// In en, this message translates to:
  /// **'This record was cleared or is older than the last 100.'**
  String get modelRequest_detailsMissing;

  /// No description provided for @modelPreset_changedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'The preset changed elsewhere. Reopen it to edit.'**
  String get modelPreset_changedElsewhere;

  /// No description provided for @modelPreset_interfacePresetChanged.
  ///
  /// In en, this message translates to:
  /// **'The interface’s preset changed elsewhere. Reopen it to create a new one.'**
  String get modelPreset_interfacePresetChanged;

  /// No description provided for @modelPreset_builtinReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Built-in · Read only'**
  String get modelPreset_builtinReadOnly;

  /// No description provided for @modelPreset_newInterfacePreset.
  ///
  /// In en, this message translates to:
  /// **'New interface preset'**
  String get modelPreset_newInterfacePreset;

  /// No description provided for @modelPreset_tabPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get modelPreset_tabPrompt;

  /// No description provided for @modelPreset_tabOutputContract.
  ///
  /// In en, this message translates to:
  /// **'Output contract'**
  String get modelPreset_tabOutputContract;

  /// No description provided for @modelPreset_name.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get modelPreset_name;

  /// No description provided for @modelPreset_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get modelPreset_nameRequired;

  /// No description provided for @modelPreset_behavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior & translation strategy'**
  String get modelPreset_behavior;

  /// No description provided for @modelPreset_builtinLocked.
  ///
  /// In en, this message translates to:
  /// **'Built-in rules are locked. Create an interface preset to edit your own translation preferences.'**
  String get modelPreset_builtinLocked;

  /// No description provided for @modelPreset_editHint.
  ///
  /// In en, this message translates to:
  /// **'Edit translation preferences here; the response format is maintained by the app.'**
  String get modelPreset_editHint;

  /// No description provided for @modelPreset_strategyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a translation strategy'**
  String get modelPreset_strategyHint;

  /// No description provided for @modelPreset_promptRequired.
  ///
  /// In en, this message translates to:
  /// **'Prompt cannot be empty'**
  String get modelPreset_promptRequired;

  /// No description provided for @modelPreset_restoreStrategy.
  ///
  /// In en, this message translates to:
  /// **'Restore built-in strategy'**
  String get modelPreset_restoreStrategy;

  /// No description provided for @modelPreset_outputContractNote.
  ///
  /// In en, this message translates to:
  /// **'This section keeps translation results writable back and displayable; the app maintains it.'**
  String get modelPreset_outputContractNote;

  /// No description provided for @modelPreset_save.
  ///
  /// In en, this message translates to:
  /// **'Save preset'**
  String get modelPreset_save;

  /// No description provided for @modelReasoning_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported'**
  String get modelReasoning_unsupported;

  /// No description provided for @modelReasoning_followModel.
  ///
  /// In en, this message translates to:
  /// **'Follow model'**
  String get modelReasoning_followModel;

  /// No description provided for @modelReasoning_followModelLevel.
  ///
  /// In en, this message translates to:
  /// **'Follow model ({level})'**
  String modelReasoning_followModelLevel(Object level);

  /// No description provided for @modelReasoning_notAdjustable.
  ///
  /// In en, this message translates to:
  /// **'This model does not support thinking adjustment'**
  String get modelReasoning_notAdjustable;

  /// No description provided for @modelReasoning_strength.
  ///
  /// In en, this message translates to:
  /// **'Thinking strength'**
  String get modelReasoning_strength;

  /// No description provided for @modelReasoning_modelDefault.
  ///
  /// In en, this message translates to:
  /// **'Model default: {level}'**
  String modelReasoning_modelDefault(Object level);

  /// No description provided for @modelReasoning_levelsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Available levels are not confirmed yet\nSet them in the service’s model settings'**
  String get modelReasoning_levelsUnknown;

  /// No description provided for @modelReasoning_strengthValue.
  ///
  /// In en, this message translates to:
  /// **'Thinking strength: {level}'**
  String modelReasoning_strengthValue(Object level);

  /// No description provided for @modelProvider_customEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Custom endpoint'**
  String get modelProvider_customEndpoint;

  /// No description provided for @modelProvider_pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get modelProvider_pickerTitle;

  /// No description provided for @modelProvider_pickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search vendors, platforms or local services'**
  String get modelProvider_pickerSearch;

  /// No description provided for @modelProvider_pickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching services'**
  String get modelProvider_pickerEmpty;

  /// No description provided for @modelProvider_groupApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key connections'**
  String get modelProvider_groupApiKey;

  /// No description provided for @modelProvider_groupLocal.
  ///
  /// In en, this message translates to:
  /// **'Local services'**
  String get modelProvider_groupLocal;

  /// No description provided for @modelProvider_enterCompatibleAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a compatible endpoint address'**
  String get modelProvider_enterCompatibleAddress;

  /// No description provided for @modelConnection_provider.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get modelConnection_provider;

  /// No description provided for @modelConnection_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get modelConnection_name;

  /// No description provided for @modelConnection_nameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. my relay'**
  String get modelConnection_nameExample;

  /// No description provided for @modelConnection_protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get modelConnection_protocol;

  /// No description provided for @modelConnection_address.
  ///
  /// In en, this message translates to:
  /// **'Endpoint address'**
  String get modelConnection_address;

  /// No description provided for @modelConnection_apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get modelConnection_apiKey;

  /// No description provided for @modelControls_decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label} ({step} {unit})'**
  String modelControls_decrease(Object label, Object step, Object unit);

  /// No description provided for @modelControls_increase.
  ///
  /// In en, this message translates to:
  /// **'Increase {label} ({step} {unit})'**
  String modelControls_increase(Object label, Object step, Object unit);

  /// No description provided for @modelControls_retryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get modelControls_retryOff;

  /// No description provided for @modelControls_retryTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String modelControls_retryTimes(Object count);

  /// No description provided for @settings_positiveIntegerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an integer greater than 0'**
  String get settings_positiveIntegerRequired;

  /// No description provided for @modelSettings_testingPreset.
  ///
  /// In en, this message translates to:
  /// **'Testing preset'**
  String get modelSettings_testingPreset;

  /// No description provided for @modelHealth_lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String modelHealth_lastUpdated(Object time);

  /// No description provided for @modelSettings_backToEditing.
  ///
  /// In en, this message translates to:
  /// **'Back to editing'**
  String get modelSettings_backToEditing;

  /// No description provided for @modelService_loadOverridesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read custom request settings: {error}'**
  String modelService_loadOverridesFailed(Object error);

  /// No description provided for @modelService_timeoutRange.
  ///
  /// In en, this message translates to:
  /// **'Request timeout must be between 10 and 600 seconds.'**
  String get modelService_timeoutRange;

  /// No description provided for @modelService_concurrencyRange.
  ///
  /// In en, this message translates to:
  /// **'Max concurrency must be between 1 and 20.'**
  String get modelService_concurrencyRange;

  /// No description provided for @modelService_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a service name.'**
  String get modelService_nameRequired;

  /// No description provided for @modelService_invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'The endpoint must be a complete http:// or https:// URL.'**
  String get modelService_invalidUrl;

  /// No description provided for @modelService_contextPositive.
  ///
  /// In en, this message translates to:
  /// **'Context window must be greater than 0.'**
  String get modelService_contextPositive;

  /// No description provided for @modelService_readingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Reading the model list…'**
  String get modelService_readingCatalog;

  /// No description provided for @modelService_catalogReturned.
  ///
  /// In en, this message translates to:
  /// **'The service returned {count} models. Check the ones you want to use.'**
  String modelService_catalogReturned(Object count);

  /// No description provided for @modelService_catalogUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Model list unavailable: {error}. You can add model IDs manually.'**
  String modelService_catalogUnavailable(Object error);

  /// No description provided for @modelService_catalogCached.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} models fetched last time. Click “Fetch list” to refresh.'**
  String modelService_catalogCached(Object count);

  /// No description provided for @modelService_catalogCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Model list fetched, but saving the local cache failed; fetch again next time.'**
  String get modelService_catalogCacheFailed;

  /// No description provided for @modelService_selectModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a model first.'**
  String get modelService_selectModelFirst;

  /// No description provided for @modelService_testingModel.
  ///
  /// In en, this message translates to:
  /// **'Testing a model request…'**
  String get modelService_testingModel;

  /// No description provided for @modelService_testSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Model request succeeded: {reply}'**
  String modelService_testSucceeded(Object reply);

  /// No description provided for @modelService_testFailed.
  ///
  /// In en, this message translates to:
  /// **'Model request failed: {error}'**
  String modelService_testFailed(Object error);

  /// No description provided for @modelService_tokensPositive.
  ///
  /// In en, this message translates to:
  /// **'Token counts for model “{name}” must be greater than 0.'**
  String modelService_tokensPositive(Object name);

  /// No description provided for @modelService_changedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'The service configuration changed elsewhere. Reopen it to edit.'**
  String get modelService_changedElsewhere;

  /// No description provided for @modelService_overridesChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Model request settings changed elsewhere. Reopen them to edit.'**
  String get modelService_overridesChangedElsewhere;

  /// No description provided for @modelService_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String modelService_saveFailed(Object error);

  /// No description provided for @modelService_keyHintNew.
  ///
  /// In en, this message translates to:
  /// **'Enter a key; local services can leave it empty'**
  String get modelService_keyHintNew;

  /// No description provided for @modelService_keyHintVendor.
  ///
  /// In en, this message translates to:
  /// **'Enter the key for this service'**
  String get modelService_keyHintVendor;

  /// No description provided for @modelService_keyHintSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved; leave empty to keep it'**
  String get modelService_keyHintSaved;

  /// No description provided for @modelService_enabledModels.
  ///
  /// In en, this message translates to:
  /// **'{count} enabled models'**
  String modelService_enabledModels(Object count);

  /// No description provided for @modelService_pendingSave.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get modelService_pendingSave;

  /// No description provided for @modelService_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get modelService_saved;

  /// No description provided for @modelService_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get modelService_enable;

  /// No description provided for @modelService_testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get modelService_testConnection;

  /// No description provided for @modelService_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete service'**
  String get modelService_delete;

  /// No description provided for @modelService_save.
  ///
  /// In en, this message translates to:
  /// **'Save service'**
  String get modelService_save;

  /// No description provided for @modelService_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving service'**
  String get modelService_saving;

  /// No description provided for @modelService_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get modelService_notConfigured;

  /// No description provided for @modelService_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get modelService_optional;

  /// No description provided for @modelService_editConnection.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get modelService_editConnection;

  /// No description provided for @modelService_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get modelService_collapse;

  /// No description provided for @modelService_connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get modelService_connectionSettings;

  /// No description provided for @modelService_dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder models'**
  String get modelService_dragToReorder;

  /// No description provided for @modelService_capacityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Context / max output; adjust in Advanced'**
  String get modelService_capacityTooltip;

  /// No description provided for @modelService_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get modelService_advanced;

  /// No description provided for @modelService_removeModel.
  ///
  /// In en, this message translates to:
  /// **'Remove model {name}'**
  String modelService_removeModel(Object name);

  /// No description provided for @modelService_linkedInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Linked interfaces'**
  String get modelService_linkedInterfaces;

  /// No description provided for @modelService_noLinkedInterfaces.
  ///
  /// In en, this message translates to:
  /// **'No linked interfaces yet'**
  String get modelService_noLinkedInterfaces;

  /// No description provided for @modelService_advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get modelService_advancedSettings;

  /// No description provided for @modelService_requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get modelService_requestTimeout;

  /// No description provided for @modelService_requestTimeoutHelp.
  ///
  /// In en, this message translates to:
  /// **'Longest wait for a single request'**
  String get modelService_requestTimeoutHelp;

  /// No description provided for @modelService_seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get modelService_seconds;

  /// No description provided for @modelService_maxConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Max concurrency'**
  String get modelService_maxConcurrency;

  /// No description provided for @modelService_maxConcurrencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Requests this service handles at once'**
  String get modelService_maxConcurrencyHelp;

  /// No description provided for @modelService_countUnit.
  ///
  /// In en, this message translates to:
  /// **''**
  String get modelService_countUnit;

  /// No description provided for @modelService_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry on failure'**
  String get modelService_retry;

  /// No description provided for @modelService_retryHelp.
  ///
  /// In en, this message translates to:
  /// **'Retry when the connection fails or the service is busy'**
  String get modelService_retryHelp;

  /// No description provided for @modelService_searchModelId.
  ///
  /// In en, this message translates to:
  /// **'Search model IDs…'**
  String get modelService_searchModelId;

  /// No description provided for @modelService_serviceModels.
  ///
  /// In en, this message translates to:
  /// **'Available models'**
  String get modelService_serviceModels;

  /// No description provided for @modelService_fetchList.
  ///
  /// In en, this message translates to:
  /// **'Fetch list'**
  String get modelService_fetchList;

  /// No description provided for @modelService_catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Click “Fetch list” to read this service’s models,\nor add model IDs on the right.'**
  String get modelService_catalogEmpty;

  /// No description provided for @modelService_noMatchingModels.
  ///
  /// In en, this message translates to:
  /// **'No matching models'**
  String get modelService_noMatchingModels;

  /// No description provided for @modelService_catalogLimitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Catalog limits: context / max output'**
  String get modelService_catalogLimitTooltip;

  /// No description provided for @modelService_searchAddedModels.
  ///
  /// In en, this message translates to:
  /// **'Search added models…'**
  String get modelService_searchAddedModels;

  /// No description provided for @modelService_modelSettings.
  ///
  /// In en, this message translates to:
  /// **'Model settings'**
  String get modelService_modelSettings;

  /// No description provided for @modelService_addedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Check models on the left, or add one below'**
  String get modelService_addedEmpty;

  /// No description provided for @modelService_customModelId.
  ///
  /// In en, this message translates to:
  /// **'Custom model ID'**
  String get modelService_customModelId;

  /// No description provided for @modelService_customModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Add models the catalog cannot list'**
  String get modelService_customModelHelp;

  /// No description provided for @modelService_addCustomModel.
  ///
  /// In en, this message translates to:
  /// **'Add custom model'**
  String get modelService_addCustomModel;

  /// No description provided for @modelCard_positiveInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive integer'**
  String get modelCard_positiveInteger;

  /// No description provided for @modelCard_catalogLimit.
  ///
  /// In en, this message translates to:
  /// **'Catalog limit {limit}'**
  String modelCard_catalogLimit(Object limit);

  /// No description provided for @modelCard_outputExceedsContext.
  ///
  /// In en, this message translates to:
  /// **'Output cannot exceed the context window'**
  String get modelCard_outputExceedsContext;

  /// No description provided for @modelCard_contextWindow.
  ///
  /// In en, this message translates to:
  /// **'Context window'**
  String get modelCard_contextWindow;

  /// No description provided for @modelCard_maxOutput.
  ///
  /// In en, this message translates to:
  /// **'Max output'**
  String get modelCard_maxOutput;

  /// No description provided for @modelCard_unlabeled.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get modelCard_unlabeled;

  /// No description provided for @modelCard_protocolStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get modelCard_protocolStandard;

  /// No description provided for @modelCard_protocolAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive'**
  String get modelCard_protocolAdaptive;

  /// No description provided for @modelCard_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get modelCard_default;

  /// No description provided for @modelCard_thinkingLevels.
  ///
  /// In en, this message translates to:
  /// **'Thinking levels'**
  String get modelCard_thinkingLevels;

  /// No description provided for @modelCard_thinkingLevelsUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Not listed in the catalog; you can enable them manually'**
  String get modelCard_thinkingLevelsUnlisted;

  /// No description provided for @modelCard_thinkingLevelsFromCatalog.
  ///
  /// In en, this message translates to:
  /// **'Supported levels are checked from the local catalog; adjust them to match the actual API.'**
  String get modelCard_thinkingLevelsFromCatalog;

  /// No description provided for @modelCard_thinkingProtocol.
  ///
  /// In en, this message translates to:
  /// **'Thinking protocol'**
  String get modelCard_thinkingProtocol;

  /// No description provided for @modelCard_defaultThinkingLevel.
  ///
  /// In en, this message translates to:
  /// **'Default level'**
  String get modelCard_defaultThinkingLevel;

  /// No description provided for @modelCard_alias.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get modelCard_alias;

  /// No description provided for @modelCard_aliasHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown wherever the model name appears; requests still use the model ID.'**
  String get modelCard_aliasHelp;

  /// No description provided for @modelCard_aliasExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. fast'**
  String get modelCard_aliasExample;

  /// No description provided for @modelCard_capabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get modelCard_capabilities;

  /// No description provided for @modelCard_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get modelCard_images;

  /// No description provided for @modelCard_nativeSearch.
  ///
  /// In en, this message translates to:
  /// **'Native web search'**
  String get modelCard_nativeSearch;

  /// No description provided for @modelCard_nativeSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'The app does not use native search on this connection yet; this does not mean the vendor or other APIs lack search.'**
  String get modelCard_nativeSearchHelp;

  /// No description provided for @modelOverrides_duplicateHeader.
  ///
  /// In en, this message translates to:
  /// **'Duplicate header name'**
  String get modelOverrides_duplicateHeader;

  /// No description provided for @modelOverrides_fieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a field name'**
  String get modelOverrides_fieldNameRequired;

  /// No description provided for @modelOverrides_duplicateField.
  ///
  /// In en, this message translates to:
  /// **'Duplicate field name'**
  String get modelOverrides_duplicateField;

  /// No description provided for @modelOverrides_invalidJson.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid JSON value'**
  String get modelOverrides_invalidJson;

  /// No description provided for @modelOverrides_customBody.
  ///
  /// In en, this message translates to:
  /// **'Custom body'**
  String get modelOverrides_customBody;

  /// No description provided for @modelOverrides_customHeaders.
  ///
  /// In en, this message translates to:
  /// **'Custom headers'**
  String get modelOverrides_customHeaders;

  /// No description provided for @modelOverrides_fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get modelOverrides_fieldName;

  /// No description provided for @modelOverrides_headerName.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get modelOverrides_headerName;

  /// No description provided for @modelOverrides_valueJson.
  ///
  /// In en, this message translates to:
  /// **'Value (JSON)'**
  String get modelOverrides_valueJson;

  /// No description provided for @modelOverrides_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get modelOverrides_value;

  /// No description provided for @modelOverrides_removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get modelOverrides_removeItem;

  /// No description provided for @modelOverrides_body.
  ///
  /// In en, this message translates to:
  /// **'Request body'**
  String get modelOverrides_body;

  /// No description provided for @modelOverrides_headers.
  ///
  /// In en, this message translates to:
  /// **'Request headers'**
  String get modelOverrides_headers;

  /// No description provided for @modelOverrides_itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String modelOverrides_itemCount(Object count);

  /// No description provided for @modelOverrides_valueTypes.
  ///
  /// In en, this message translates to:
  /// **'Supports strings, numbers, booleans, arrays and objects'**
  String get modelOverrides_valueTypes;

  /// No description provided for @modelOverrides_addBodyField.
  ///
  /// In en, this message translates to:
  /// **'Add body field'**
  String get modelOverrides_addBodyField;

  /// No description provided for @modelOverrides_addHeader.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get modelOverrides_addHeader;

  /// No description provided for @promptTranslation_translating.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get promptTranslation_translating;

  /// No description provided for @promptTranslation_needsModel.
  ///
  /// In en, this message translates to:
  /// **'Translate · configure a model first'**
  String get promptTranslation_needsModel;

  /// No description provided for @promptTranslation_withRoute.
  ///
  /// In en, this message translates to:
  /// **'Translate · {provider} / {model}'**
  String promptTranslation_withRoute(Object provider, Object model);

  /// No description provided for @promptTranslation_actions.
  ///
  /// In en, this message translates to:
  /// **'Translation actions'**
  String get promptTranslation_actions;

  /// No description provided for @promptTranslation_promptChanged.
  ///
  /// In en, this message translates to:
  /// **'The prompt changed; new edits were not overwritten'**
  String get promptTranslation_promptChanged;

  /// No description provided for @promptTranslation_nothingToTranslate.
  ///
  /// In en, this message translates to:
  /// **'There is no plain text to translate'**
  String get promptTranslation_nothingToTranslate;

  /// No description provided for @promptTranslation_failed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed: {error}'**
  String promptTranslation_failed(Object error);

  /// No description provided for @promptTranslation_setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure a translation model first'**
  String get promptTranslation_setupTitle;

  /// No description provided for @promptTranslation_setupBody.
  ///
  /// In en, this message translates to:
  /// **'Translation needs an explicitly selected service and model. Go to Settings → Integrations → Models & APIs, add a service and fetch its model list, then choose a model for prompt translation.'**
  String get promptTranslation_setupBody;

  /// No description provided for @promptTranslation_later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get promptTranslation_later;

  /// No description provided for @promptTranslation_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get promptTranslation_openSettings;

  /// No description provided for @promptTranslation_toolTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get promptTranslation_toolTitle;

  /// No description provided for @promptTranslation_noModel.
  ///
  /// In en, this message translates to:
  /// **'No model configured'**
  String get promptTranslation_noModel;

  /// No description provided for @promptTranslation_configureModel.
  ///
  /// In en, this message translates to:
  /// **'Configure translation model'**
  String get promptTranslation_configureModel;

  /// No description provided for @promptTranslation_translateNew.
  ///
  /// In en, this message translates to:
  /// **'Translate new content'**
  String get promptTranslation_translateNew;

  /// No description provided for @promptTranslation_undoRestore.
  ///
  /// In en, this message translates to:
  /// **'Undo the restore and bring translation blocks back'**
  String get promptTranslation_undoRestore;

  /// No description provided for @promptTranslation_restoreAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all translation blocks to original text'**
  String get promptTranslation_restoreAll;

  /// No description provided for @promptTranslation_tutorial.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get promptTranslation_tutorial;

  /// No description provided for @promptTranslation_guideBack.
  ///
  /// In en, this message translates to:
  /// **'Back to actions'**
  String get promptTranslation_guideBack;

  /// No description provided for @promptTranslation_guideMiddleTitle.
  ///
  /// In en, this message translates to:
  /// **'Middle-click a block'**
  String get promptTranslation_guideMiddleTitle;

  /// No description provided for @promptTranslation_guideMiddleText.
  ///
  /// In en, this message translates to:
  /// **'Switch original and translation'**
  String get promptTranslation_guideMiddleText;

  /// No description provided for @promptTranslation_guideSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Left-click the original'**
  String get promptTranslation_guideSourceTitle;

  /// No description provided for @promptTranslation_guideSourceText.
  ///
  /// In en, this message translates to:
  /// **'Place the cursor and edit directly'**
  String get promptTranslation_guideSourceText;

  /// No description provided for @promptTranslation_guideReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Left-click the translation'**
  String get promptTranslation_guideReadingTitle;

  /// No description provided for @promptTranslation_guideReadingText.
  ///
  /// In en, this message translates to:
  /// **'Open the block editor'**
  String get promptTranslation_guideReadingText;

  /// No description provided for @promptTranslation_guideCtrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Ctrl + click / drag-select'**
  String get promptTranslation_guideCtrlTitle;

  /// No description provided for @promptTranslation_guideCtrlText.
  ///
  /// In en, this message translates to:
  /// **'Search tags / find related tags in the editor'**
  String get promptTranslation_guideCtrlText;

  /// No description provided for @promptTranslation_guideConvertTitle.
  ///
  /// In en, this message translates to:
  /// **'↑ Translation to original'**
  String get promptTranslation_guideConvertTitle;

  /// No description provided for @promptTranslation_guideConvertText.
  ///
  /// In en, this message translates to:
  /// **'↓ Original to translation; review before saving'**
  String get promptTranslation_guideConvertText;

  /// No description provided for @promptTranslation_guideRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'A / Restore'**
  String get promptTranslation_guideRestoreTitle;

  /// No description provided for @promptTranslation_guideRestoreText.
  ///
  /// In en, this message translates to:
  /// **'Restore the whole group / bring blocks back'**
  String get promptTranslation_guideRestoreText;

  /// No description provided for @promptTranslation_middleButton.
  ///
  /// In en, this message translates to:
  /// **'Middle mouse button'**
  String get promptTranslation_middleButton;

  /// No description provided for @promptTranslation_leftButton.
  ///
  /// In en, this message translates to:
  /// **'Left mouse button'**
  String get promptTranslation_leftButton;

  /// No description provided for @promptTranslation_blockShowingOriginal.
  ///
  /// In en, this message translates to:
  /// **'Translation block, showing original'**
  String get promptTranslation_blockShowingOriginal;

  /// No description provided for @promptTranslation_blockShowingReading.
  ///
  /// In en, this message translates to:
  /// **'Translation block, showing translation'**
  String get promptTranslation_blockShowingReading;

  /// No description provided for @promptTranslation_blockNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Original changed · translation needs updating'**
  String get promptTranslation_blockNeedsReview;

  /// No description provided for @promptTranslation_badgeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Original changed; translation needs syncing'**
  String get promptTranslation_badgeTooltip;

  /// No description provided for @promptTranslation_sourceChanged.
  ///
  /// In en, this message translates to:
  /// **'The original changed; reopen the translation block'**
  String get promptTranslation_sourceChanged;

  /// No description provided for @promptTranslation_retranslateFailed.
  ///
  /// In en, this message translates to:
  /// **'Retranslation failed: {error}'**
  String promptTranslation_retranslateFailed(Object error);

  /// No description provided for @promptTranslation_draftChanged.
  ///
  /// In en, this message translates to:
  /// **'Content changed; convert again. The new draft is kept.'**
  String get promptTranslation_draftChanged;

  /// No description provided for @promptTranslation_convertFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed; the draft is kept: {error}'**
  String promptTranslation_convertFailed(Object error);

  /// No description provided for @promptTranslation_invalidResultFormat.
  ///
  /// In en, this message translates to:
  /// **'The conversion result format is invalid; the draft is kept'**
  String get promptTranslation_invalidResultFormat;

  /// No description provided for @promptTranslation_noValidText.
  ///
  /// In en, this message translates to:
  /// **'The model returned no valid text; the draft is kept'**
  String get promptTranslation_noValidText;

  /// No description provided for @promptTranslation_invalidResultContent.
  ///
  /// In en, this message translates to:
  /// **'The conversion result contains invalid formatting; the draft is kept'**
  String get promptTranslation_invalidResultContent;

  /// No description provided for @promptTranslation_incompleteStructure.
  ///
  /// In en, this message translates to:
  /// **'The conversion result has incomplete weights or groups; the draft is kept'**
  String get promptTranslation_incompleteStructure;

  /// No description provided for @promptTranslation_inputRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the content to convert first'**
  String get promptTranslation_inputRequired;

  /// No description provided for @wiki_configureTagModel.
  ///
  /// In en, this message translates to:
  /// **'Configure an available tag translation model in Models & APIs first.'**
  String get wiki_configureTagModel;

  /// No description provided for @blockOrganizer_barrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Block organizer'**
  String get blockOrganizer_barrierLabel;

  /// No description provided for @blockOrganizer_replaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace copies from the same source?'**
  String get blockOrganizer_replaceTitle;

  /// No description provided for @blockOrganizer_replaceMoveBody.
  ///
  /// In en, this message translates to:
  /// **'The target already has {count} copies from the same source. After replacing, the source is hidden from the library; instances already inserted in prompts can still reference the original block.'**
  String blockOrganizer_replaceMoveBody(Object count);

  /// No description provided for @blockOrganizer_replaceCopyBody.
  ///
  /// In en, this message translates to:
  /// **'The target already has {count} copies from the same source. Replacing updates the target copies; the source is kept.'**
  String blockOrganizer_replaceCopyBody(Object count);

  /// No description provided for @blockOrganizer_replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get blockOrganizer_replace;

  /// No description provided for @blockOrganizer_customTagColor.
  ///
  /// In en, this message translates to:
  /// **'Custom tag color'**
  String get blockOrganizer_customTagColor;

  /// No description provided for @blockOrganizer_colorHint.
  ///
  /// In en, this message translates to:
  /// **'#RRGGBB or #AARRGGBB'**
  String get blockOrganizer_colorHint;

  /// No description provided for @blockOrganizer_invalidColor.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6- or 8-digit hexadecimal color'**
  String get blockOrganizer_invalidColor;

  /// No description provided for @blockOrganizer_deleteFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? Its blocks will move to the root folder.'**
  String blockOrganizer_deleteFolderConfirm(Object name);

  /// No description provided for @blockOrganizer_deleteCollectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? The blocks themselves are kept.'**
  String blockOrganizer_deleteCollectionConfirm(Object name);

  /// No description provided for @blockOrganizer_titleFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites & collections'**
  String get blockOrganizer_titleFavorites;

  /// No description provided for @blockOrganizer_titleFolders.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get blockOrganizer_titleFolders;

  /// No description provided for @blockOrganizer_itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String blockOrganizer_itemCount(Object count);

  /// No description provided for @blockOrganizer_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get blockOrganizer_search;

  /// No description provided for @blockOrganizer_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get blockOrganizer_name;

  /// No description provided for @blockOrganizer_customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color…'**
  String get blockOrganizer_customColor;

  /// No description provided for @blockOrganizer_newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get blockOrganizer_newCollection;

  /// No description provided for @blockOrganizer_newCollectionFolder.
  ///
  /// In en, this message translates to:
  /// **'New collection folder'**
  String get blockOrganizer_newCollectionFolder;

  /// No description provided for @blockOrganizer_newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get blockOrganizer_newTag;

  /// No description provided for @blockOrganizer_newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get blockOrganizer_newFolder;

  /// No description provided for @blockOrganizer_rootUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Root / Uncategorized'**
  String get blockOrganizer_rootUncategorized;

  /// No description provided for @blockOrganizer_manageDrag.
  ///
  /// In en, this message translates to:
  /// **'Manage; drag to reorder'**
  String get blockOrganizer_manageDrag;

  /// No description provided for @blockLibrary_dragSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the selected blocks onto a favorite or folder on the left, then choose copy or move when you release.'**
  String get blockLibrary_dragSelectedHint;

  /// No description provided for @blockLibrary_blockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks'**
  String blockLibrary_blockCount(Object count);

  /// No description provided for @blockLibrary_changedSelectAgain.
  ///
  /// In en, this message translates to:
  /// **'The block library changed. Select again and retry.'**
  String get blockLibrary_changedSelectAgain;

  /// No description provided for @blockLibrary_hiddenSource.
  ///
  /// In en, this message translates to:
  /// **'Hidden blocks cannot be organized'**
  String get blockLibrary_hiddenSource;

  /// No description provided for @blockLibrary_sameSourceSelected.
  ///
  /// In en, this message translates to:
  /// **'The selection contains copies from the same source; organize them separately'**
  String get blockLibrary_sameSourceSelected;

  /// No description provided for @blockLibrary_sameSourceExists.
  ///
  /// In en, this message translates to:
  /// **'Copies from the same source already exist; confirm replacement'**
  String get blockLibrary_sameSourceExists;

  /// No description provided for @blockLibrary_collectionMissing.
  ///
  /// In en, this message translates to:
  /// **'The collection does not exist'**
  String get blockLibrary_collectionMissing;

  /// No description provided for @promptBlockEditor_appearance.
  ///
  /// In en, this message translates to:
  /// **'Block appearance'**
  String get promptBlockEditor_appearance;

  /// No description provided for @promptBlockEditor_imageUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected image'**
  String get promptBlockEditor_imageUnreadable;

  /// No description provided for @blockAppearance_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get blockAppearance_classic;

  /// No description provided for @blockAppearance_stripes.
  ///
  /// In en, this message translates to:
  /// **'Fine stripes'**
  String get blockAppearance_stripes;

  /// No description provided for @blockAppearance_dots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get blockAppearance_dots;

  /// No description provided for @blockAppearance_solid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get blockAppearance_solid;

  /// No description provided for @blockAppearance_gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get blockAppearance_gradient;

  /// No description provided for @blockAppearance_translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get blockAppearance_translation;

  /// No description provided for @opusUsage_exhausted.
  ///
  /// In en, this message translates to:
  /// **'Free account quota used up; V5 generation is billed in Anlas'**
  String get opusUsage_exhausted;

  /// No description provided for @opusUsage_remaining.
  ///
  /// In en, this message translates to:
  /// **'Free account quota remaining: {percent}%'**
  String opusUsage_remaining(Object percent);

  /// No description provided for @opusUsage_recharging.
  ///
  /// In en, this message translates to:
  /// **'Recharging: next +1% in {time}'**
  String opusUsage_recharging(Object time);

  /// No description provided for @opusUsage_notRecharging.
  ///
  /// In en, this message translates to:
  /// **'Not recharging (the pool is above the threshold or used up)'**
  String get opusUsage_notRecharging;

  /// No description provided for @opusUsage_clickToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Click to refresh'**
  String get opusUsage_clickToRefresh;

  /// No description provided for @opusUsage_hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String opusUsage_hoursMinutes(Object hours, Object minutes);

  /// No description provided for @opusUsage_hours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String opusUsage_hours(Object hours);

  /// No description provided for @opusUsage_minutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String opusUsage_minutesSeconds(Object minutes, Object seconds);

  /// No description provided for @opusUsage_minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String opusUsage_minutes(Object minutes);

  /// No description provided for @opusUsage_seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String opusUsage_seconds(Object seconds);

  /// No description provided for @metadataImport_noCharactersReplaceClears.
  ///
  /// In en, this message translates to:
  /// **'No character data; replace clears current characters'**
  String get metadataImport_noCharactersReplaceClears;

  /// No description provided for @metadataImport_replaceCharacters.
  ///
  /// In en, this message translates to:
  /// **'Replace characters'**
  String get metadataImport_replaceCharacters;

  /// No description provided for @metadataImport_appendCharacters.
  ///
  /// In en, this message translates to:
  /// **'Append characters'**
  String get metadataImport_appendCharacters;

  /// No description provided for @drop_dragToShare.
  ///
  /// In en, this message translates to:
  /// **'Drag to share'**
  String get drop_dragToShare;

  /// No description provided for @promptSyntax_weightTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Numeric weight is too large: {value}::'**
  String promptSyntax_weightTooLarge(Object value);

  /// No description provided for @promptSyntax_spaceBeforeColons.
  ///
  /// In en, this message translates to:
  /// **'No space allowed between the weight and :: : {value} ::'**
  String promptSyntax_spaceBeforeColons(Object value);

  /// No description provided for @promptSyntax_weightAfterColons.
  ///
  /// In en, this message translates to:
  /// **'Numeric weights go before :: : ::{value}'**
  String promptSyntax_weightAfterColons(Object value);

  /// No description provided for @update_errorInAppUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This version does not support automatic in-app updates'**
  String get update_errorInAppUnsupported;

  /// No description provided for @update_errorNoInstallablePackage.
  ///
  /// In en, this message translates to:
  /// **'No automatically installable update package was found'**
  String get update_errorNoInstallablePackage;

  /// No description provided for @update_errorMissingSha256.
  ///
  /// In en, this message translates to:
  /// **'The update package is missing its SHA256 checksum'**
  String get update_errorMissingSha256;

  /// No description provided for @update_errorDiskFull.
  ///
  /// In en, this message translates to:
  /// **'Not enough disk space to save the update package'**
  String get update_errorDiskFull;

  /// No description provided for @update_errorWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to write the update package'**
  String get update_errorWriteFailed;

  /// No description provided for @update_errorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the update package'**
  String get update_errorDownloadFailed;

  /// No description provided for @update_errorSizeMismatch.
  ///
  /// In en, this message translates to:
  /// **'The update package size check failed'**
  String get update_errorSizeMismatch;

  /// No description provided for @update_errorChecksumMismatch.
  ///
  /// In en, this message translates to:
  /// **'The update package checksum failed'**
  String get update_errorChecksumMismatch;

  /// No description provided for @update_errorResumeRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected resuming the update download'**
  String get update_errorResumeRejected;

  /// No description provided for @update_errorEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'The update server returned an empty response'**
  String get update_errorEmptyResponse;

  /// No description provided for @update_errorPlatformUnsupported.
  ///
  /// In en, this message translates to:
  /// **'In-app updates are not supported on this platform'**
  String get update_errorPlatformUnsupported;

  /// No description provided for @update_errorPackageRemoved.
  ///
  /// In en, this message translates to:
  /// **'The update package was cleaned up; download it again'**
  String get update_errorPackageRemoved;

  /// No description provided for @update_errorPackageCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The update package is corrupted; download it again'**
  String get update_errorPackageCorrupted;

  /// No description provided for @update_errorLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start the updater'**
  String get update_errorLaunchFailed;

  /// No description provided for @update_errorCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get update_errorCheckFailed;

  /// No description provided for @update_errorCheckUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred while checking for updates'**
  String get update_errorCheckUnknown;

  /// No description provided for @update_errorLogPath.
  ///
  /// In en, this message translates to:
  /// **'Log: {path}'**
  String update_errorLogPath(Object path);

  /// No description provided for @update_errorInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to install the update'**
  String get update_errorInstallFailed;

  /// No description provided for @update_errorInstallFailedSeeLog.
  ///
  /// In en, this message translates to:
  /// **'Failed to install the update; see the update log'**
  String get update_errorInstallFailedSeeLog;

  /// No description provided for @auth_tokenEmpty.
  ///
  /// In en, this message translates to:
  /// **'The token is empty and cannot be verified'**
  String get auth_tokenEmpty;

  /// No description provided for @auth_tokenFormatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid token format'**
  String get auth_tokenFormatInvalid;

  /// No description provided for @auth_tokenInvalidOrExpired.
  ///
  /// In en, this message translates to:
  /// **'The token is invalid or expired; check that it is correct. A persistent token starts with pst-.'**
  String get auth_tokenInvalidOrExpired;

  /// No description provided for @auth_tokenMustStartPst.
  ///
  /// In en, this message translates to:
  /// **'Invalid token format; it should start with pst-'**
  String get auth_tokenMustStartPst;

  /// No description provided for @auth_tokenFormatDetail.
  ///
  /// In en, this message translates to:
  /// **'Invalid token format. A persistent token starts with pst- followed by at least 10 characters. Check the token you entered.'**
  String get auth_tokenFormatDetail;

  /// No description provided for @danbooru_credentialsExpired.
  ///
  /// In en, this message translates to:
  /// **'Credentials expired; sign in again'**
  String get danbooru_credentialsExpired;

  /// No description provided for @danbooru_networkRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed; it will retry when the network is back'**
  String get danbooru_networkRetryLater;

  /// No description provided for @danbooru_invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Could not verify the credentials; check the username and API key'**
  String get danbooru_invalidCredentials;

  /// No description provided for @danbooru_verifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String danbooru_verifyFailed(Object error);

  /// No description provided for @danbooru_credentialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Username and API key cannot be empty'**
  String get danbooru_credentialsRequired;

  /// No description provided for @danbooru_networkCheck.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed; check your connection'**
  String get danbooru_networkCheck;

  /// No description provided for @danbooru_loginFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed; check your network connection'**
  String get danbooru_loginFailedNetwork;

  /// No description provided for @danbooru_blacklistLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to a Danbooru account first'**
  String get danbooru_blacklistLoginRequired;

  /// No description provided for @danbooru_blacklistPushFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to push the Danbooru blacklist'**
  String get danbooru_blacklistPushFailed;

  /// No description provided for @danbooru_blacklistSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String danbooru_blacklistSyncFailed(Object error);

  /// No description provided for @comfyui_submitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit the workflow: {detail}'**
  String comfyui_submitFailed(Object detail);

  /// No description provided for @comfyui_uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload the image: {detail}'**
  String comfyui_uploadFailed(Object detail);

  /// No description provided for @comfyui_fetchImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch the image: {detail}'**
  String comfyui_fetchImageFailed(Object detail);

  /// No description provided for @comfyui_historyMissing.
  ///
  /// In en, this message translates to:
  /// **'Task history not found: {id}'**
  String comfyui_historyMissing(Object id);

  /// No description provided for @comfyui_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get comfyui_unknownError;

  /// No description provided for @comfyui_cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the ComfyUI server ({url})'**
  String comfyui_cannotConnect(Object url);

  /// No description provided for @comfyui_noOutput.
  ///
  /// In en, this message translates to:
  /// **'The task produced no output'**
  String get comfyui_noOutput;

  /// No description provided for @comfyui_nodesNoImage.
  ///
  /// In en, this message translates to:
  /// **'The specified output nodes produced no image: {nodes}'**
  String comfyui_nodesNoImage(Object nodes);

  /// No description provided for @comfyui_noImageOutput.
  ///
  /// In en, this message translates to:
  /// **'The task produced no image'**
  String get comfyui_noImageOutput;

  /// No description provided for @comfyui_executionError.
  ///
  /// In en, this message translates to:
  /// **'Execution error'**
  String get comfyui_executionError;

  /// No description provided for @comfyui_missingNodes.
  ///
  /// In en, this message translates to:
  /// **'Missing ComfyUI nodes: {nodes}. Install or enable the custom nodes in ComfyUI, then restart ComfyUI.'**
  String comfyui_missingNodes(Object nodes);

  /// No description provided for @enhance_cannotReadSize.
  ///
  /// In en, this message translates to:
  /// **'Could not read the image size'**
  String get enhance_cannotReadSize;

  /// No description provided for @enhance_upscaleFailed.
  ///
  /// In en, this message translates to:
  /// **'Upscale failed: {error}'**
  String enhance_upscaleFailed(Object error);

  /// No description provided for @enhance_vibeEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Vibe encoding failed: {error}'**
  String enhance_vibeEncodeFailed(Object error);

  /// No description provided for @enhance_enhanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Image enhancement failed: {error}'**
  String enhance_enhanceFailed(Object error);

  /// No description provided for @enhance_annotateFailed.
  ///
  /// In en, this message translates to:
  /// **'Image annotation failed: {error}'**
  String enhance_annotateFailed(Object error);

  /// No description provided for @enhance_timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get enhance_timeout;

  /// No description provided for @enhance_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error'**
  String get enhance_networkError;

  /// No description provided for @enhance_serverError.
  ///
  /// In en, this message translates to:
  /// **'Server returned an error: {status}'**
  String enhance_serverError(Object status);

  /// No description provided for @enhance_serverErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Server returned an error: {status} ({detail})'**
  String enhance_serverErrorDetail(Object status, Object detail);

  /// No description provided for @proxy_connectTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out'**
  String get proxy_connectTimeout;

  /// No description provided for @proxy_cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the server'**
  String get proxy_cannotConnect;

  /// No description provided for @proxy_connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get proxy_connectFailed;

  /// No description provided for @proxy_testServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the test server'**
  String get proxy_testServerUnreachable;

  /// No description provided for @proxy_testFailed.
  ///
  /// In en, this message translates to:
  /// **'Test failed: {error}'**
  String proxy_testFailed(Object error);

  /// No description provided for @avatar_noFilePath.
  ///
  /// In en, this message translates to:
  /// **'Could not get the file path'**
  String get avatar_noFilePath;

  /// No description provided for @avatar_sourceMissing.
  ///
  /// In en, this message translates to:
  /// **'The source file does not exist or was deleted'**
  String get avatar_sourceMissing;

  /// No description provided for @avatar_copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the file: {error}'**
  String avatar_copyFailed(Object error);

  /// No description provided for @avatar_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the avatar: {error}'**
  String avatar_saveFailed(Object error);

  /// No description provided for @avatar_operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String avatar_operationFailed(Object error);

  /// No description provided for @vibeExport_rawImage.
  ///
  /// In en, this message translates to:
  /// **'Original image'**
  String get vibeExport_rawImage;

  /// No description provided for @vibeExport_vibePreview.
  ///
  /// In en, this message translates to:
  /// **'Vibe preview'**
  String get vibeExport_vibePreview;

  /// No description provided for @vibeExport_libraryThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Library thumbnail'**
  String get vibeExport_libraryThumbnail;

  /// No description provided for @vibeExport_pngTitle.
  ///
  /// In en, this message translates to:
  /// **'Export PNG Vibe image'**
  String get vibeExport_pngTitle;

  /// No description provided for @vibeExport_pngDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PNG export folder'**
  String get vibeExport_pngDirectoryTitle;

  /// No description provided for @vibeExport_fileTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Vibe file'**
  String get vibeExport_fileTitle;

  /// No description provided for @vibeExport_bundleTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Vibe bundle'**
  String get vibeExport_bundleTitle;

  /// No description provided for @vibeExport_zipTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Vibe ZIP'**
  String get vibeExport_zipTitle;

  /// No description provided for @vibeExport_nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'No Vibe entries to export'**
  String get vibeExport_nothingToExport;

  /// No description provided for @vibeImport_fileParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse the file'**
  String get vibeImport_fileParseFailed;

  /// No description provided for @vibeImport_importFiles.
  ///
  /// In en, this message translates to:
  /// **'Importing files'**
  String get vibeImport_importFiles;

  /// No description provided for @vibeImport_noVibeData.
  ///
  /// In en, this message translates to:
  /// **'The image contains no valid Vibe data'**
  String get vibeImport_noVibeData;

  /// No description provided for @vibeImport_importImages.
  ///
  /// In en, this message translates to:
  /// **'Importing images'**
  String get vibeImport_importImages;

  /// No description provided for @vibeImport_encodingParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse the encoding'**
  String get vibeImport_encodingParseFailed;

  /// No description provided for @vibeImport_importEncodings.
  ///
  /// In en, this message translates to:
  /// **'Importing encodings'**
  String get vibeImport_importEncodings;

  /// No description provided for @vibeImport_namingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Naming cancelled; skipped: {name}'**
  String vibeImport_namingCancelled(Object name);

  /// No description provided for @vibeImport_nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name is empty; skipped: {name}'**
  String vibeImport_nameEmpty(Object name);

  /// No description provided for @vibeImport_nameConflict.
  ///
  /// In en, this message translates to:
  /// **'Name conflict; skipped: {name}'**
  String vibeImport_nameConflict(Object name);

  /// No description provided for @vibeImport_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get vibeImport_saveFailed;

  /// No description provided for @vibeFile_missingRawImage.
  ///
  /// In en, this message translates to:
  /// **'The file has no usable original image data: {file} (type=image). It may be damaged or incomplete; delete it and save again.'**
  String vibeFile_missingRawImage(Object file);

  /// No description provided for @generation_countMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Generation count must be greater than 0'**
  String get generation_countMustBePositive;

  /// No description provided for @generation_allTasksFailed.
  ///
  /// In en, this message translates to:
  /// **'All generation tasks failed'**
  String get generation_allTasksFailed;

  /// No description provided for @generation_failedShort.
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get generation_failedShort;

  /// No description provided for @generation_tasksFailedAfterRetry.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks still failed after retrying'**
  String generation_tasksFailedAfterRetry(Object count);

  /// No description provided for @generation_streamFallbackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Streaming generation is unsupported and cannot fall back automatically (parameters were lost)'**
  String get generation_streamFallbackUnavailable;

  /// No description provided for @generation_streamFallbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Falling back to non-streaming generation failed: {error}'**
  String generation_streamFallbackFailed(Object error);

  /// No description provided for @generation_batchSizeMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Batch count and batch size must be greater than 0'**
  String get generation_batchSizeMustBePositive;

  /// No description provided for @clipboard_unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'The system clipboard is not supported on this platform'**
  String get clipboard_unsupportedPlatform;

  /// No description provided for @clipboard_decodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decode the image to copy it to the clipboard'**
  String get clipboard_decodeFailed;

  /// No description provided for @drop_remoteImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The remote image download exceeds {size} MB'**
  String drop_remoteImageTooLarge(Object size);

  /// No description provided for @apiEndpoint_empty.
  ///
  /// In en, this message translates to:
  /// **'API address cannot be empty'**
  String get apiEndpoint_empty;

  /// No description provided for @apiEndpoint_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid API address'**
  String get apiEndpoint_invalid;

  /// No description provided for @apiEndpoint_httpOnly.
  ///
  /// In en, this message translates to:
  /// **'Only http or https API addresses are supported'**
  String get apiEndpoint_httpOnly;

  /// No description provided for @apiEndpoint_noExtras.
  ///
  /// In en, this message translates to:
  /// **'The API address cannot contain query parameters, fragments or user info'**
  String get apiEndpoint_noExtras;

  /// No description provided for @gallery_folderInaccessible.
  ///
  /// In en, this message translates to:
  /// **'Cannot access the image folder: {error}'**
  String gallery_folderInaccessible(Object error);

  /// No description provided for @gallery_scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Image scan failed: {error}'**
  String gallery_scanFailed(Object error);

  /// No description provided for @gallery_galleryInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Gallery initialization failed: {error}'**
  String gallery_galleryInitFailed(Object error);

  /// No description provided for @vibeImport_imageProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing image ({current}/{total}): {source}'**
  String vibeImport_imageProgress(Object current, Object total, Object source);

  /// No description provided for @vibeImport_clipboardSource.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get vibeImport_clipboardSource;

  /// No description provided for @resolution_noAdjustment.
  ///
  /// In en, this message translates to:
  /// **'No adjustment needed'**
  String get resolution_noAdjustment;

  /// No description provided for @dataRefresh_updating.
  ///
  /// In en, this message translates to:
  /// **'Updating data...'**
  String get dataRefresh_updating;

  /// No description provided for @dataRefresh_updatingService.
  ///
  /// In en, this message translates to:
  /// **'Updating {service}...'**
  String dataRefresh_updatingService(Object service);

  /// No description provided for @imageUse_title.
  ///
  /// In en, this message translates to:
  /// **'Use image'**
  String get imageUse_title;

  /// No description provided for @imageUse_importContent.
  ///
  /// In en, this message translates to:
  /// **'Import content'**
  String get imageUse_importContent;

  /// No description provided for @imageUse_characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get imageUse_characters;

  /// No description provided for @imageUse_characterMode.
  ///
  /// In en, this message translates to:
  /// **'Character handling'**
  String get imageUse_characterMode;

  /// No description provided for @imageMenu_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get imageMenu_details;

  /// No description provided for @imageMenu_creation.
  ///
  /// In en, this message translates to:
  /// **'Create & reference'**
  String get imageMenu_creation;

  /// No description provided for @imageMenu_editAndDerive.
  ///
  /// In en, this message translates to:
  /// **'Edit & derive'**
  String get imageMenu_editAndDerive;

  /// No description provided for @imageMenu_more.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get imageMenu_more;

  /// No description provided for @imageMenu_fileActions.
  ///
  /// In en, this message translates to:
  /// **'File actions'**
  String get imageMenu_fileActions;

  /// No description provided for @imageMenu_saveToBlock.
  ///
  /// In en, this message translates to:
  /// **'Save to blocks'**
  String get imageMenu_saveToBlock;

  /// No description provided for @settings_highAnlasCostEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated usage'**
  String get settings_highAnlasCostEstimate;

  /// No description provided for @settings_highAnlasCostThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder threshold'**
  String get settings_highAnlasCostThresholdLabel;

  /// No description provided for @settings_highAnlasCostQuestion.
  ///
  /// In en, this message translates to:
  /// **'Continue with this generation?'**
  String get settings_highAnlasCostQuestion;

  /// No description provided for @bridge_title.
  ///
  /// In en, this message translates to:
  /// **'Local bridge'**
  String get bridge_title;

  /// No description provided for @bridge_agent.
  ///
  /// In en, this message translates to:
  /// **'External Agent'**
  String get bridge_agent;

  /// No description provided for @bridge_agentHint.
  ///
  /// In en, this message translates to:
  /// **'Copy the instructions to an Agent that can run local commands.'**
  String get bridge_agentHint;

  /// No description provided for @bridge_synced.
  ///
  /// In en, this message translates to:
  /// **'Current content confirmed'**
  String get bridge_synced;

  /// No description provided for @bridge_changed.
  ///
  /// In en, this message translates to:
  /// **'Content changed. Awaiting confirmation'**
  String get bridge_changed;

  /// No description provided for @bridge_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get bridge_waiting;

  /// No description provided for @bridge_ready.
  ///
  /// In en, this message translates to:
  /// **'Waiting for activity'**
  String get bridge_ready;

  /// No description provided for @bridge_clients.
  ///
  /// In en, this message translates to:
  /// **'{count} Agent(s) connected'**
  String bridge_clients(int count);

  /// No description provided for @bridge_activity.
  ///
  /// In en, this message translates to:
  /// **'{client}: {action}'**
  String bridge_activity(Object client, Object action);

  /// No description provided for @bridge_read.
  ///
  /// In en, this message translates to:
  /// **'Reading parameters'**
  String get bridge_read;

  /// No description provided for @bridge_write.
  ///
  /// In en, this message translates to:
  /// **'Updating parameters'**
  String get bridge_write;

  /// No description provided for @bridge_quote.
  ///
  /// In en, this message translates to:
  /// **'Estimating cost'**
  String get bridge_quote;

  /// No description provided for @bridge_generate.
  ///
  /// In en, this message translates to:
  /// **'Generating an image'**
  String get bridge_generate;

  /// No description provided for @bridge_cancel.
  ///
  /// In en, this message translates to:
  /// **'Stopping generation'**
  String get bridge_cancel;

  /// No description provided for @bridge_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get bridge_recent;

  /// No description provided for @bridge_empty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get bridge_empty;

  /// No description provided for @bridge_copyGuide.
  ///
  /// In en, this message translates to:
  /// **'Copy connection instructions'**
  String get bridge_copyGuide;

  /// No description provided for @bridge_showGuide.
  ///
  /// In en, this message translates to:
  /// **'View instructions'**
  String get bridge_showGuide;

  /// No description provided for @bridge_copied.
  ///
  /// In en, this message translates to:
  /// **'Instructions copied'**
  String get bridge_copied;

  /// No description provided for @bridge_disconnect.
  ///
  /// In en, this message translates to:
  /// **'End Agent connections'**
  String get bridge_disconnect;

  /// No description provided for @bridge_settings.
  ///
  /// In en, this message translates to:
  /// **'Bridge settings'**
  String get bridge_settings;

  /// No description provided for @bridge_clientMissing.
  ///
  /// In en, this message translates to:
  /// **'The bundled client is unavailable. Update Studio.'**
  String get bridge_clientMissing;

  /// No description provided for @bridge_conflict.
  ///
  /// In en, this message translates to:
  /// **'Content changed. Read it again.'**
  String get bridge_conflict;

  /// No description provided for @bridge_busy.
  ///
  /// In en, this message translates to:
  /// **'Another operation is in progress'**
  String get bridge_busy;

  /// No description provided for @bridge_interrupted.
  ///
  /// In en, this message translates to:
  /// **'Operation interrupted'**
  String get bridge_interrupted;

  /// No description provided for @bridge_failed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed. Check the Agent response.'**
  String get bridge_failed;

  /// No description provided for @bridge_timeout.
  ///
  /// In en, this message translates to:
  /// **'Operation timed out. Retry.'**
  String get bridge_timeout;

  /// No description provided for @bridge_guide.
  ///
  /// In en, this message translates to:
  /// **'Use the local bridge to assist with W.O.F NAI Studio.\nClient: {clientPath}\n\n1. Quote the path correctly for your shell. Run status --name <your-name> and verify success; copying these instructions does not connect.\n2. Run get --name <your-name> --out current.json. Editable original text is in _draft.fields; field_versions protect against concurrent edits. Other fields may include effective quality tags. Do not duplicate them into the original text.\n3. Change only user-authorized fields. Save a patch to changes.json, then run set-json changes.json --base current.json --name <your-name>. Studio backs up and rechecks the edited fields. On conflict, stop and read again; never automatically overwrite newer user edits. Verify readback. characters replaces the entire list: preserve unrelated names, enabled flags, positions, and IDs. Reference images are currently read-only.\n4. Connecting or editing does not authorize generation. Only after an explicit generation request, run quote --out quote.json --name <your-name> and report the estimated Anlas price and cached account balance; server billing is authoritative. After authorization and reporting, run gen --quote quote.json --authorized --name <your-name>. One image per request; a changed draft invalidates the quote.\n5. Each command disconnects when done. Krita can remain connected. Wait on busy and avoid immediate retry loops after errors. Stop generation in Studio, use Ctrl+C, or cancel <request_id> --name <same-name> using the returned request ID. Never print the discovery-file session secret.\n'**
  String bridge_guide(Object clientPath);

  /// No description provided for @editor_drawMask.
  ///
  /// In en, this message translates to:
  /// **'Draw Mask'**
  String get editor_drawMask;

  /// No description provided for @editor_eraseMask.
  ///
  /// In en, this message translates to:
  /// **'Erase Mask'**
  String get editor_eraseMask;

  /// No description provided for @editor_squareBrush.
  ///
  /// In en, this message translates to:
  /// **'Square Brush'**
  String get editor_squareBrush;

  /// No description provided for @editor_focusedArea.
  ///
  /// In en, this message translates to:
  /// **'Focused Area'**
  String get editor_focusedArea;

  /// No description provided for @editor_minimumContext.
  ///
  /// In en, this message translates to:
  /// **'Minimum Context Area'**
  String get editor_minimumContext;

  /// No description provided for @editor_maskAppearance.
  ///
  /// In en, this message translates to:
  /// **'Mask Appearance'**
  String get editor_maskAppearance;

  /// No description provided for @editor_maskColor.
  ///
  /// In en, this message translates to:
  /// **'Mask Color'**
  String get editor_maskColor;

  /// No description provided for @editor_maskOpacity.
  ///
  /// In en, this message translates to:
  /// **'Mask Opacity'**
  String get editor_maskOpacity;

  /// No description provided for @editor_maskBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get editor_maskBorder;

  /// No description provided for @editor_patternSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get editor_patternSolid;

  /// No description provided for @editor_patternLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get editor_patternLines;

  /// No description provided for @editor_patternCrosshatch.
  ///
  /// In en, this message translates to:
  /// **'Crosshatch'**
  String get editor_patternCrosshatch;

  /// No description provided for @editor_patternDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get editor_patternDots;

  /// No description provided for @editor_patternGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get editor_patternGrid;

  /// No description provided for @editor_patternChecker.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get editor_patternChecker;

  /// No description provided for @editor_patternHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get editor_patternHearts;

  /// No description provided for @editor_resize.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get editor_resize;

  /// No description provided for @editor_penSize.
  ///
  /// In en, this message translates to:
  /// **'Pen Size'**
  String get editor_penSize;

  /// No description provided for @editor_sourceChanged.
  ///
  /// In en, this message translates to:
  /// **'The source image changed while editing. Please reopen the editor.'**
  String get editor_sourceChanged;

  /// No description provided for @editor_draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get editor_draw;

  /// No description provided for @editor_erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get editor_erase;

  /// No description provided for @editor_select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get editor_select;

  /// No description provided for @editor_lasso.
  ///
  /// In en, this message translates to:
  /// **'Lasso'**
  String get editor_lasso;

  /// No description provided for @editor_roundTip.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get editor_roundTip;

  /// No description provided for @editor_softRoundTip.
  ///
  /// In en, this message translates to:
  /// **'Soft Round'**
  String get editor_softRoundTip;

  /// No description provided for @editor_squareTip.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get editor_squareTip;

  /// No description provided for @editor_pressureSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Pressure Sensitivity'**
  String get editor_pressureSensitivity;

  /// No description provided for @editor_hsvAdjustment.
  ///
  /// In en, this message translates to:
  /// **'HSV Adjustment'**
  String get editor_hsvAdjustment;

  /// No description provided for @editor_hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get editor_hue;

  /// No description provided for @editor_cloneSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Alt+Click to set source'**
  String get editor_cloneSourceHint;

  /// No description provided for @editor_colorAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get editor_colorAlpha;

  /// No description provided for @editor_colorHex.
  ///
  /// In en, this message translates to:
  /// **'Color HEX'**
  String get editor_colorHex;

  /// No description provided for @editor_closestValidSize.
  ///
  /// In en, this message translates to:
  /// **'Crop to closest valid generation size'**
  String get editor_closestValidSize;

  /// No description provided for @model3d_projection.
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get model3d_projection;

  /// No description provided for @model3d_perspective.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get model3d_perspective;

  /// No description provided for @model3d_orthographic.
  ///
  /// In en, this message translates to:
  /// **'Orthographic'**
  String get model3d_orthographic;

  /// No description provided for @model3d_fov.
  ///
  /// In en, this message translates to:
  /// **'FOV'**
  String get model3d_fov;

  /// No description provided for @model3d_ambient.
  ///
  /// In en, this message translates to:
  /// **'Ambient'**
  String get model3d_ambient;

  /// No description provided for @model3d_direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get model3d_direct;

  /// No description provided for @model3d_direction.
  ///
  /// In en, this message translates to:
  /// **'Light Direction'**
  String get model3d_direction;

  /// No description provided for @model3d_front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get model3d_front;

  /// No description provided for @model3d_frontTop.
  ///
  /// In en, this message translates to:
  /// **'Front-Top'**
  String get model3d_frontTop;

  /// No description provided for @model3d_top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get model3d_top;

  /// No description provided for @model3d_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get model3d_left;

  /// No description provided for @model3d_right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get model3d_right;

  /// No description provided for @model3d_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get model3d_back;

  /// No description provided for @model3d_shadows.
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get model3d_shadows;

  /// No description provided for @model3d_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get model3d_quality;

  /// No description provided for @model3d_veryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get model3d_veryLow;

  /// No description provided for @model3d_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get model3d_low;

  /// No description provided for @model3d_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get model3d_medium;

  /// No description provided for @model3d_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get model3d_high;

  /// No description provided for @model3d_veryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get model3d_veryHigh;

  /// No description provided for @model3d_display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get model3d_display;

  /// No description provided for @model3d_showBones.
  ///
  /// In en, this message translates to:
  /// **'Show Bones'**
  String get model3d_showBones;

  /// No description provided for @model3d_bones.
  ///
  /// In en, this message translates to:
  /// **'Bone List'**
  String get model3d_bones;

  /// No description provided for @model3d_noBones.
  ///
  /// In en, this message translates to:
  /// **'No bones found'**
  String get model3d_noBones;

  /// No description provided for @model3d_morphs.
  ///
  /// In en, this message translates to:
  /// **'Morph Targets'**
  String get model3d_morphs;

  /// No description provided for @model3d_noMorphs.
  ///
  /// In en, this message translates to:
  /// **'No morph targets found'**
  String get model3d_noMorphs;

  /// No description provided for @model3d_settings.
  ///
  /// In en, this message translates to:
  /// **'3D Render Settings'**
  String get model3d_settings;

  /// No description provided for @model3d_resetModel.
  ///
  /// In en, this message translates to:
  /// **'Reset model position'**
  String get model3d_resetModel;

  /// No description provided for @model3d_removeModel.
  ///
  /// In en, this message translates to:
  /// **'Remove model'**
  String get model3d_removeModel;

  /// No description provided for @model3d_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this model? Unsaved model edits will be lost.'**
  String get model3d_removeConfirm;

  /// No description provided for @model3d_toolTransform.
  ///
  /// In en, this message translates to:
  /// **'Model\nTransform'**
  String get model3d_toolTransform;

  /// No description provided for @model3d_toolPose.
  ///
  /// In en, this message translates to:
  /// **'Model Pose'**
  String get model3d_toolPose;

  /// No description provided for @img2img_directorEmotionHint.
  ///
  /// In en, this message translates to:
  /// **'Anime only. Start with a neutral emotion image.'**
  String get img2img_directorEmotionHint;

  /// No description provided for @img2img_emotionStrengthNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get img2img_emotionStrengthNormal;

  /// No description provided for @img2img_emotionStrengthSlightlyWeak.
  ///
  /// In en, this message translates to:
  /// **'Slightly Weak'**
  String get img2img_emotionStrengthSlightlyWeak;

  /// No description provided for @img2img_emotionStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get img2img_emotionStrengthWeak;

  /// No description provided for @img2img_emotionStrengthWeaker.
  ///
  /// In en, this message translates to:
  /// **'Even Weaker'**
  String get img2img_emotionStrengthWeaker;

  /// No description provided for @img2img_emotionStrengthVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very Weak'**
  String get img2img_emotionStrengthVeryWeak;

  /// No description provided for @img2img_emotionStrengthWeakest.
  ///
  /// In en, this message translates to:
  /// **'Weakest'**
  String get img2img_emotionStrengthWeakest;

  /// No description provided for @img2img_directorWeaken.
  ///
  /// In en, this message translates to:
  /// **'Weaken emotion'**
  String get img2img_directorWeaken;

  /// No description provided for @img2img_directorStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Strengthen emotion'**
  String get img2img_directorStrengthen;

  /// No description provided for @img2img_emotionScared.
  ///
  /// In en, this message translates to:
  /// **'Scared'**
  String get img2img_emotionScared;

  /// No description provided for @img2img_emotionNervous.
  ///
  /// In en, this message translates to:
  /// **'Nervous'**
  String get img2img_emotionNervous;

  /// No description provided for @img2img_emotionThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get img2img_emotionThinking;

  /// No description provided for @img2img_emotionConfused.
  ///
  /// In en, this message translates to:
  /// **'Confused'**
  String get img2img_emotionConfused;

  /// No description provided for @img2img_emotionBored.
  ///
  /// In en, this message translates to:
  /// **'Bored'**
  String get img2img_emotionBored;

  /// No description provided for @img2img_emotionIrritated.
  ///
  /// In en, this message translates to:
  /// **'Irritated'**
  String get img2img_emotionIrritated;

  /// No description provided for @img2img_emotionAroused.
  ///
  /// In en, this message translates to:
  /// **'Aroused'**
  String get img2img_emotionAroused;

  /// No description provided for @img2img_emotionEmbarrassed.
  ///
  /// In en, this message translates to:
  /// **'Embarrassed'**
  String get img2img_emotionEmbarrassed;

  /// No description provided for @img2img_emotionDetermined.
  ///
  /// In en, this message translates to:
  /// **'Determined'**
  String get img2img_emotionDetermined;

  /// No description provided for @img2img_emotionHurt.
  ///
  /// In en, this message translates to:
  /// **'Hurt'**
  String get img2img_emotionHurt;

  /// No description provided for @localUpscale_local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localUpscale_local;

  /// No description provided for @localUpscale_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage models'**
  String get localUpscale_manage;

  /// No description provided for @localUpscale_description.
  ///
  /// In en, this message translates to:
  /// **'Upscale images locally without spending Anlas.'**
  String get localUpscale_description;

  /// No description provided for @localUpscale_bundled.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get localUpscale_bundled;

  /// No description provided for @localUpscale_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get localUpscale_download;

  /// No description provided for @localUpscale_importHelp.
  ///
  /// In en, this message translates to:
  /// **'Import a matching .param and .bin pair from a 4× Real-ESRGAN NCNN model (data/output blobs). PyTorch and safetensors models are not supported.'**
  String get localUpscale_importHelp;

  /// No description provided for @localUpscale_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing image…'**
  String get localUpscale_preparing;

  /// No description provided for @localUpscale_inference.
  ///
  /// In en, this message translates to:
  /// **'Upscaling…'**
  String get localUpscale_inference;

  /// No description provided for @localUpscale_resizing.
  ///
  /// In en, this message translates to:
  /// **'Finishing image…'**
  String get localUpscale_resizing;

  /// No description provided for @localUpscale_complete.
  ///
  /// In en, this message translates to:
  /// **'Upscale complete'**
  String get localUpscale_complete;

  /// No description provided for @localUpscale_cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get localUpscale_cancelling;

  /// No description provided for @localUpscale_unsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Local upscaling currently supports Windows.'**
  String get localUpscale_unsupportedPlatform;

  /// No description provided for @localUpscale_engineMissing.
  ///
  /// In en, this message translates to:
  /// **'Local engine unavailable. Reinstall the complete Studio package.'**
  String get localUpscale_engineMissing;

  /// No description provided for @localUpscale_integrity.
  ///
  /// In en, this message translates to:
  /// **'File verification failed. Reinstall the affected model or Studio package.'**
  String get localUpscale_integrity;

  /// No description provided for @localUpscale_modelMissing.
  ///
  /// In en, this message translates to:
  /// **'Model unavailable. Choose an installed model or check the model folder path length.'**
  String get localUpscale_modelMissing;

  /// No description provided for @localUpscale_invalidModel.
  ///
  /// In en, this message translates to:
  /// **'Incompatible model. Import a matching 4× Real-ESRGAN NCNN pair.'**
  String get localUpscale_invalidModel;

  /// No description provided for @localUpscale_invalidImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot read this image. Try a PNG, JPEG or WebP file.'**
  String get localUpscale_invalidImage;

  /// No description provided for @localUpscale_sizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Image too large: the model output must fit within 64 megapixels.'**
  String get localUpscale_sizeLimit;

  /// No description provided for @localUpscale_noVulkan.
  ///
  /// In en, this message translates to:
  /// **'No usable Vulkan GPU. Update your graphics driver and try again.'**
  String get localUpscale_noVulkan;

  /// No description provided for @localUpscale_processFailed.
  ///
  /// In en, this message translates to:
  /// **'Upscaling failed. Check the model and graphics driver. Your source image is preserved.'**
  String get localUpscale_processFailed;

  /// No description provided for @localUpscale_timeout.
  ///
  /// In en, this message translates to:
  /// **'Upscaling timed out. Try a smaller image.'**
  String get localUpscale_timeout;

  /// No description provided for @localUpscale_busy.
  ///
  /// In en, this message translates to:
  /// **'Another upscale or model operation is still running.'**
  String get localUpscale_busy;

  /// No description provided for @localUpscale_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Upscaling cancelled'**
  String get localUpscale_cancelled;

  /// No description provided for @localUpscale_anime.
  ///
  /// In en, this message translates to:
  /// **'Anime · Quality'**
  String get localUpscale_anime;

  /// No description provided for @localUpscale_animeFast.
  ///
  /// In en, this message translates to:
  /// **'Anime · Fast'**
  String get localUpscale_animeFast;

  /// No description provided for @localUpscale_general.
  ///
  /// In en, this message translates to:
  /// **'General · Photos'**
  String get localUpscale_general;

  /// No description provided for @localUpscale_downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading model…'**
  String get localUpscale_downloadProgress;

  /// No description provided for @localUpscale_importModel.
  ///
  /// In en, this message translates to:
  /// **'Import model'**
  String get localUpscale_importModel;

  /// No description provided for @localUpscale_modelOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Model operation failed. Check your connection, file permissions and free disk space, then retry.'**
  String get localUpscale_modelOperationFailed;

  /// No description provided for @settings_localUpscale.
  ///
  /// In en, this message translates to:
  /// **'Local upscaling'**
  String get settings_localUpscale;

  /// No description provided for @settings_localUpscaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage local upscaling models and components.'**
  String get settings_localUpscaleDescription;

  /// No description provided for @localUpscale_noCuda.
  ///
  /// In en, this message translates to:
  /// **'A CUDA-capable NVIDIA GPU and a compatible driver are required.'**
  String get localUpscale_noCuda;

  /// No description provided for @localUpscale_noRtx.
  ///
  /// In en, this message translates to:
  /// **'RTX Video is unavailable. Check your NVIDIA RTX GPU and driver.'**
  String get localUpscale_noRtx;

  /// No description provided for @localUpscale_encoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding image…'**
  String get localUpscale_encoding;

  /// No description provided for @localUpscale_decoding.
  ///
  /// In en, this message translates to:
  /// **'Decoding image…'**
  String get localUpscale_decoding;

  /// No description provided for @localUpscale_optionalComponents.
  ///
  /// In en, this message translates to:
  /// **'Optional components'**
  String get localUpscale_optionalComponents;

  /// No description provided for @localUpscale_noAutomaticDownload.
  ///
  /// In en, this message translates to:
  /// **'Download components as needed. Existing local models are ready to use.'**
  String get localUpscale_noAutomaticDownload;

  /// No description provided for @localUpscale_notInstalledShort.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get localUpscale_notInstalledShort;

  /// No description provided for @localUpscale_seedvr2ThreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Balances quality and resources for everyday upscaling.'**
  String get localUpscale_seedvr2ThreeSummary;

  /// No description provided for @localUpscale_seedvr2SevenSummary.
  ///
  /// In en, this message translates to:
  /// **'Higher quality potential with more VRAM and processing time.'**
  String get localUpscale_seedvr2SevenSummary;

  /// No description provided for @localUpscale_seedvr2SharpSummary.
  ///
  /// In en, this message translates to:
  /// **'Sharper details for images where stronger textures are desired.'**
  String get localUpscale_seedvr2SharpSummary;

  /// No description provided for @localUpscale_seedvr2SharpHelp.
  ///
  /// In en, this message translates to:
  /// **'7B Sharp FP8 emphasizes sharper textures and edges. Weights are about 8.2 GB; shares the VAE and Python/CUDA runtime with other SeedVR2 variants.'**
  String get localUpscale_seedvr2SharpHelp;

  /// No description provided for @localUpscale_seedvr2Int8Help.
  ///
  /// In en, this message translates to:
  /// **'INT8 ConvRot (experimental): requires NVIDIA Turing or newer. Shares the FP8 runtime; speed and image quality vary with the image and GPU.'**
  String get localUpscale_seedvr2Int8Help;

  /// No description provided for @localUpscale_noInt8.
  ///
  /// In en, this message translates to:
  /// **'Native INT8 is unavailable on this GPU or CUDA runtime. Select FP8.'**
  String get localUpscale_noInt8;

  /// No description provided for @localUpscale_seedvr2SharedHelp.
  ///
  /// In en, this message translates to:
  /// **'Models share the VAE (about 0.5 GB) and Python/CUDA runtime. Requires an NVIDIA GPU.'**
  String get localUpscale_seedvr2SharedHelp;

  /// No description provided for @localUpscale_seedvr2Help.
  ///
  /// In en, this message translates to:
  /// **'3B FP8 balances quality and resources. About 3.4 GB of weights plus a 0.5 GB VAE; shares its VAE and Python/CUDA runtime with 7B. Requires an NVIDIA GPU.'**
  String get localUpscale_seedvr2Help;

  /// No description provided for @localUpscale_seedvr2SevenHelp.
  ///
  /// In en, this message translates to:
  /// **'7B FP8 offers higher quality potential with more VRAM and processing time. About 8.2 GB of weights; shares the VAE and Python/CUDA runtime with 3B.'**
  String get localUpscale_seedvr2SevenHelp;

  /// No description provided for @localUpscale_outOfMemory.
  ///
  /// In en, this message translates to:
  /// **'Not enough VRAM. Try 3B, a smaller scale, or Low VRAM and VAE tiling in advanced settings. The model was not switched automatically.'**
  String get localUpscale_outOfMemory;

  /// No description provided for @localUpscale_modelWeights.
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get localUpscale_modelWeights;

  /// No description provided for @localUpscale_advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get localUpscale_advancedSettings;

  /// No description provided for @localUpscale_seedvr2Color.
  ///
  /// In en, this message translates to:
  /// **'Color correction'**
  String get localUpscale_seedvr2Color;

  /// No description provided for @localUpscale_colorNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get localUpscale_colorNone;

  /// No description provided for @localUpscale_seedvr2Seed.
  ///
  /// In en, this message translates to:
  /// **'Random seed'**
  String get localUpscale_seedvr2Seed;

  /// No description provided for @localUpscale_seedvr2Memory.
  ///
  /// In en, this message translates to:
  /// **'Memory strategy'**
  String get localUpscale_seedvr2Memory;

  /// No description provided for @localUpscale_memoryRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get localUpscale_memoryRecommended;

  /// No description provided for @localUpscale_memoryLow.
  ///
  /// In en, this message translates to:
  /// **'Low VRAM'**
  String get localUpscale_memoryLow;

  /// No description provided for @localUpscale_blocksToSwap.
  ///
  /// In en, this message translates to:
  /// **'CPU-offloaded blocks'**
  String get localUpscale_blocksToSwap;

  /// No description provided for @localUpscale_memoryHelp.
  ///
  /// In en, this message translates to:
  /// **'More offloaded blocks save VRAM but use more RAM and run slower. Low VRAM mode does not guarantee that every output size will fit.'**
  String get localUpscale_memoryHelp;

  /// No description provided for @localUpscale_vaeTiled.
  ///
  /// In en, this message translates to:
  /// **'VAE tiling'**
  String get localUpscale_vaeTiled;

  /// No description provided for @localUpscale_vaeTileSize.
  ///
  /// In en, this message translates to:
  /// **'Tile size'**
  String get localUpscale_vaeTileSize;

  /// No description provided for @localUpscale_vaeOverlap.
  ///
  /// In en, this message translates to:
  /// **'Tile overlap'**
  String get localUpscale_vaeOverlap;

  /// No description provided for @localUpscale_vaeHelp.
  ///
  /// In en, this message translates to:
  /// **'Smaller tiles save VRAM; overlap reduces seams. This tiles VAE encoding and decoding, not the complete upscaling pipeline.'**
  String get localUpscale_vaeHelp;

  /// No description provided for @localUpscale_experimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental variation'**
  String get localUpscale_experimental;

  /// No description provided for @localUpscale_inputNoise.
  ///
  /// In en, this message translates to:
  /// **'Input noise'**
  String get localUpscale_inputNoise;

  /// No description provided for @localUpscale_latentNoise.
  ///
  /// In en, this message translates to:
  /// **'Latent noise'**
  String get localUpscale_latentNoise;

  /// No description provided for @localUpscale_noiseHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep both at 0 to preserve the current behavior. Increasing noise adds variation, not guaranteed detail or quality, and may change lines and faces.'**
  String get localUpscale_noiseHelp;

  /// No description provided for @localUpscale_restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get localUpscale_restoreDefaults;

  /// No description provided for @localUpscale_rtxHelp.
  ///
  /// In en, this message translates to:
  /// **'Fast GPU upscaling with NVIDIA RTX Video. Downloads a separate component of about 64 MB; requires a compatible RTX GPU.'**
  String get localUpscale_rtxHelp;

  /// No description provided for @localUpscale_installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get localUpscale_installed;

  /// No description provided for @localUpscale_notInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed — open Manage models to install'**
  String get localUpscale_notInstalled;

  /// No description provided for @localUpscale_license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get localUpscale_license;

  /// No description provided for @localUpscale_installComponent.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get localUpscale_installComponent;

  /// No description provided for @localUpscale_installingRuntime.
  ///
  /// In en, this message translates to:
  /// **'Installing Python/CUDA runtime…'**
  String get localUpscale_installingRuntime;

  /// No description provided for @localUpscale_installingPython.
  ///
  /// In en, this message translates to:
  /// **'Preparing isolated Python…'**
  String get localUpscale_installingPython;

  /// No description provided for @localUpscale_installFailed.
  ///
  /// In en, this message translates to:
  /// **'Installation failed at: {stage}'**
  String localUpscale_installFailed(String stage);

  /// No description provided for @wiki_translationQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting to translate'**
  String get wiki_translationQueued;

  /// No description provided for @wiki_translationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Translation failed — click to retry'**
  String get wiki_translationFailedRetry;

  /// No description provided for @localUpscale_checkingComponent.
  ///
  /// In en, this message translates to:
  /// **'Checking component and GPU…'**
  String get localUpscale_checkingComponent;

  /// No description provided for @localUpscale_installingComponent.
  ///
  /// In en, this message translates to:
  /// **'Downloading component…'**
  String get localUpscale_installingComponent;

  /// No description provided for @upscale_settings.
  ///
  /// In en, this message translates to:
  /// **'Upscale settings'**
  String get upscale_settings;

  /// No description provided for @upscale_cloudCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated {cost} Anlas · 2×'**
  String upscale_cloudCost(int cost);

  /// No description provided for @enhance_localAfterGeneration.
  ///
  /// In en, this message translates to:
  /// **'Automatically upscale each generated image locally.'**
  String get enhance_localAfterGeneration;

  /// No description provided for @enhance_localAction.
  ///
  /// In en, this message translates to:
  /// **'Generate and upscale locally'**
  String get enhance_localAction;

  /// No description provided for @localUpscale_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop upscaling'**
  String get localUpscale_stop;

  /// No description provided for @localUpscale_scrollDown.
  ///
  /// In en, this message translates to:
  /// **'Scroll down'**
  String get localUpscale_scrollDown;

  /// No description provided for @wiki_exampleImages.
  ///
  /// In en, this message translates to:
  /// **'Example image'**
  String get wiki_exampleImages;

  /// No description provided for @wiki_exampleImagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Example images are temporarily unavailable'**
  String get wiki_exampleImagesUnavailable;

  /// No description provided for @generation_moduleImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get generation_moduleImage;

  /// No description provided for @generation_perRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get generation_perRequestLabel;

  /// No description provided for @generation_perRequestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Images per request (1–4)'**
  String get generation_perRequestTooltip;

  /// No description provided for @generation_repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get generation_repeatLabel;

  /// No description provided for @generation_referenceUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get generation_referenceUpload;

  /// No description provided for @generation_seedPinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed · Fixed'**
  String get generation_seedPinnedLabel;

  /// No description provided for @generation_paramsDrawerTooltip.
  ///
  /// In en, this message translates to:
  /// **'More parameters'**
  String get generation_paramsDrawerTooltip;

  /// Number of images in one generation history batch
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String generation_historyBatchCount(int count);

  /// No description provided for @library_sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get library_sizeSmall;

  /// No description provided for @library_sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get library_sizeMedium;

  /// No description provided for @library_sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get library_sizeLarge;

  /// No description provided for @library_currentModel.
  ///
  /// In en, this message translates to:
  /// **'Current model'**
  String get library_currentModel;

  /// No description provided for @library_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get library_available;

  /// No description provided for @library_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get library_unavailable;

  /// No description provided for @library_inGeneration.
  ///
  /// In en, this message translates to:
  /// **'In generation'**
  String get library_inGeneration;

  /// No description provided for @library_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String library_selectedCount(int count);

  /// No description provided for @library_invertSelection.
  ///
  /// In en, this message translates to:
  /// **'Invert selection'**
  String get library_invertSelection;

  /// No description provided for @library_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get library_more;

  /// No description provided for @library_addToGeneration.
  ///
  /// In en, this message translates to:
  /// **'Add to generation'**
  String get library_addToGeneration;

  /// No description provided for @library_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get library_strength;

  /// No description provided for @library_information.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get library_information;

  /// No description provided for @library_fidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get library_fidelity;

  /// No description provided for @library_encodeOnUse.
  ///
  /// In en, this message translates to:
  /// **'Encode on use'**
  String get library_encodeOnUse;

  /// No description provided for @library_reencode.
  ///
  /// In en, this message translates to:
  /// **'Re-encode'**
  String get library_reencode;

  /// No description provided for @library_unusableModel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable for {model}'**
  String library_unusableModel(String model);

  /// No description provided for @library_exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all'**
  String get library_exportAll;

  /// No description provided for @library_rescanFolders.
  ///
  /// In en, this message translates to:
  /// **'Rescan folders'**
  String get library_rescanFolders;

  /// No description provided for @library_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get library_preview;

  /// No description provided for @viewer_backLocalGallery.
  ///
  /// In en, this message translates to:
  /// **'Local gallery'**
  String get viewer_backLocalGallery;

  /// No description provided for @viewer_fit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get viewer_fit;

  /// No description provided for @viewer_showInfo.
  ///
  /// In en, this message translates to:
  /// **'Show information panel (I)'**
  String get viewer_showInfo;

  /// No description provided for @viewer_hideInfo.
  ///
  /// In en, this message translates to:
  /// **'Hide information panel (I)'**
  String get viewer_hideInfo;

  /// No description provided for @viewer_originalSize.
  ///
  /// In en, this message translates to:
  /// **'Original size (1)'**
  String get viewer_originalSize;

  /// No description provided for @viewer_fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (F11)'**
  String get viewer_fullscreen;

  /// No description provided for @shortcut_action_toggle_info_panel.
  ///
  /// In en, this message translates to:
  /// **'Toggle information panel'**
  String get shortcut_action_toggle_info_panel;

  /// No description provided for @styleExplore_runNamingHint.
  ///
  /// In en, this message translates to:
  /// **'Named from rolling blocks and the date. Double-click a name to rename it.'**
  String get styleExplore_runNamingHint;

  /// No description provided for @styleExplore_roundGenerating.
  ///
  /// In en, this message translates to:
  /// **'Round {round} · Generating'**
  String styleExplore_roundGenerating(int round);

  /// No description provided for @styleExplore_inspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get styleExplore_inspectorTitle;

  /// No description provided for @styleExplore_failedBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String styleExplore_failedBadge(int count);

  /// No description provided for @styleExplore_showInspector.
  ///
  /// In en, this message translates to:
  /// **'Show inspector'**
  String get styleExplore_showInspector;

  /// No description provided for @styleExplore_roundProgress.
  ///
  /// In en, this message translates to:
  /// **'Round {round} · {current} / {total}'**
  String styleExplore_roundProgress(int round, int current, int total);

  /// No description provided for @styleExplore_earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get styleExplore_earlier;

  /// No description provided for @styleExplore_noMatchingRuns.
  ///
  /// In en, this message translates to:
  /// **'No matching explorations'**
  String get styleExplore_noMatchingRuns;

  /// No description provided for @styleExplore_lineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} evolution lines'**
  String styleExplore_lineCount(int count);

  /// No description provided for @styleExplore_newRunDescription.
  ///
  /// In en, this message translates to:
  /// **'Start with the current prompts and parameters; rename it later'**
  String get styleExplore_newRunDescription;

  /// No description provided for @styleExplore_autoRunName.
  ///
  /// In en, this message translates to:
  /// **'{blocks} · {time}'**
  String styleExplore_autoRunName(String blocks, String time);

  /// No description provided for @styleExplore_largeCandidates.
  ///
  /// In en, this message translates to:
  /// **'Large candidates'**
  String get styleExplore_largeCandidates;

  /// No description provided for @styleExplore_hideInspector.
  ///
  /// In en, this message translates to:
  /// **'Hide inspector'**
  String get styleExplore_hideInspector;

  /// No description provided for @styleExplore_searchRuns.
  ///
  /// In en, this message translates to:
  /// **'Search exploration names or artists'**
  String get styleExplore_searchRuns;

  /// No description provided for @styleExplore_favoriteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} favorites'**
  String styleExplore_favoriteCount(int count);

  /// No description provided for @styleExplore_generatingBadge.
  ///
  /// In en, this message translates to:
  /// **'Generating {current}/{total}'**
  String styleExplore_generatingBadge(int current, int total);

  /// No description provided for @styleExplore_roundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String styleExplore_roundCount(int count);

  /// No description provided for @styleExplore_pausedRemaining.
  ///
  /// In en, this message translates to:
  /// **'Paused · {count} remaining'**
  String styleExplore_pausedRemaining(int count);

  /// No description provided for @styleExplore_stopRun.
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get styleExplore_stopRun;

  /// No description provided for @styleExplore_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get styleExplore_thisWeek;

  /// No description provided for @styleExplore_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get styleExplore_today;

  /// No description provided for @styleExplore_smallCandidates.
  ///
  /// In en, this message translates to:
  /// **'Small candidates'**
  String get styleExplore_smallCandidates;

  /// No description provided for @styleExplore_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String styleExplore_imageCount(int count);

  /// Style exploration workbench: styleExplore_variablesTitle
  ///
  /// In en, this message translates to:
  /// **'Random variables'**
  String get styleExplore_variablesTitle;

  /// Style exploration workbench: styleExplore_variablesHint
  ///
  /// In en, this message translates to:
  /// **'Redraw each image'**
  String get styleExplore_variablesHint;

  /// Style exploration workbench: styleExplore_variablesExplanation
  ///
  /// In en, this message translates to:
  /// **'Enabled random and sequential evolution blocks are recorded for each candidate.'**
  String get styleExplore_variablesExplanation;

  /// Style exploration workbench: styleExplore_variablePoolSize
  ///
  /// In en, this message translates to:
  /// **'Pool: {count} items'**
  String styleExplore_variablePoolSize(int count);

  /// Style exploration workbench: styleExplore_variableEvolutionTarget
  ///
  /// In en, this message translates to:
  /// **'Evolution target'**
  String get styleExplore_variableEvolutionTarget;

  /// Style exploration workbench: styleExplore_variableNegative
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get styleExplore_variableNegative;

  /// Style exploration workbench: styleExplore_variablesEmpty
  ///
  /// In en, this message translates to:
  /// **'No random blocks in the prompt yet; candidates will look alike.'**
  String get styleExplore_variablesEmpty;

  /// Style exploration workbench: styleExplore_openBlockLibrary
  ///
  /// In en, this message translates to:
  /// **'Open block library'**
  String get styleExplore_openBlockLibrary;

  /// Style exploration workbench: styleExplore_drawCountLabel
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get styleExplore_drawCountLabel;

  /// Style exploration workbench: styleExplore_drawCountSuffix
  ///
  /// In en, this message translates to:
  /// **'images · one at a time'**
  String get styleExplore_drawCountSuffix;

  /// Style explore task03: candidatesTab
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get styleExplore_candidatesTab;

  /// Style explore task03: evolutionTab
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get styleExplore_evolutionTab;

  /// Style explore task03: deepRoundTitle
  ///
  /// In en, this message translates to:
  /// **'Evolution · {name} · Generation {generation}'**
  String styleExplore_deepRoundTitle(String name, int generation);

  /// Style explore task03: wallRoundCount
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String styleExplore_wallRoundCount(int count);

  /// Style explore task03: wallGenerating
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get styleExplore_wallGenerating;

  /// Style explore task03: roundFailures
  ///
  /// In en, this message translates to:
  /// **'Failed {count}'**
  String styleExplore_roundFailures(int count);

  /// Style explore task03: queued
  ///
  /// In en, this message translates to:
  /// **'Queued #{number}'**
  String styleExplore_queued(int number);

  /// Style explore task03: generatingCandidate
  ///
  /// In en, this message translates to:
  /// **'Generating #{number}'**
  String styleExplore_generatingCandidate(int number);

  /// Style explore task03: generationFailed
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get styleExplore_generationFailed;

  /// Style explore task03: failureHint
  ///
  /// In en, this message translates to:
  /// **'Hover to see the reason'**
  String get styleExplore_failureHint;

  /// Style explore task03: imageDeleted
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get styleExplore_imageDeleted;

  /// Style explore task03: parentBadge
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get styleExplore_parentBadge;

  /// Style explore task03: opMutation
  ///
  /// In en, this message translates to:
  /// **'Mutation'**
  String get styleExplore_opMutation;

  /// Style explore task03: opCrossover
  ///
  /// In en, this message translates to:
  /// **'Crossover'**
  String get styleExplore_opCrossover;

  /// Style explore task03: opInjection
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get styleExplore_opInjection;

  /// Style explore task03: copyArtists
  ///
  /// In en, this message translates to:
  /// **'Copy artists'**
  String get styleExplore_copyArtists;

  /// Style explore task03: interrupted
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get styleExplore_interrupted;

  /// Style explore task03: emptyFilter
  ///
  /// In en, this message translates to:
  /// **'No matching candidates'**
  String get styleExplore_emptyFilter;

  /// Style explore task03: emptyRound
  ///
  /// In en, this message translates to:
  /// **'This round has no candidates'**
  String get styleExplore_emptyRound;

  /// Explore workbench selection: unfavorite
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get styleExplore_unfavorite;

  /// Explore workbench selection: groupLabel
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get styleExplore_groupLabel;

  /// Explore workbench selection: newGroup
  ///
  /// In en, this message translates to:
  /// **'New group…'**
  String get styleExplore_newGroup;

  /// Explore workbench selection: saveBlock
  ///
  /// In en, this message translates to:
  /// **'Save as block'**
  String get styleExplore_saveBlock;

  /// Explore workbench selection: startEvolution
  ///
  /// In en, this message translates to:
  /// **'Start evolution'**
  String get styleExplore_startEvolution;

  /// Explore workbench selection: newestFirst
  ///
  /// In en, this message translates to:
  /// **'Newest rounds first'**
  String get styleExplore_newestFirst;

  /// Explore workbench selection: oldestFirst
  ///
  /// In en, this message translates to:
  /// **'Oldest rounds first'**
  String get styleExplore_oldestFirst;

  /// Explore workbench selection: pickEvolution
  ///
  /// In en, this message translates to:
  /// **'Pick candidates to evolve'**
  String get styleExplore_pickEvolution;

  /// Delete candidates with or without local copies
  ///
  /// In en, this message translates to:
  /// **'Delete candidates'**
  String get styleExplore_deleteCandidatesTitle;

  /// Delete candidates with or without local copies
  ///
  /// In en, this message translates to:
  /// **'Delete {count} candidates and their image copies? Library originals are kept.'**
  String styleExplore_deleteCandidatesMessage(int count);

  /// styleExplore_inspectorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a candidate to view details'**
  String get styleExplore_inspectorEmpty;

  /// styleExplore_drawsTitle.
  ///
  /// In en, this message translates to:
  /// **'Drawn for this image'**
  String get styleExplore_drawsTitle;

  /// styleExplore_drawsAfterGeneration.
  ///
  /// In en, this message translates to:
  /// **'Shown after generation'**
  String get styleExplore_drawsAfterGeneration;

  /// styleExplore_emptyDraw.
  ///
  /// In en, this message translates to:
  /// **'Nothing drawn (the pool contains empty entries)'**
  String get styleExplore_emptyDraw;

  /// styleExplore_hearted.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get styleExplore_hearted;

  /// styleExplore_joinEvolution.
  ///
  /// In en, this message translates to:
  /// **'Add to evolution'**
  String get styleExplore_joinEvolution;

  /// styleExplore_applyToEditor.
  ///
  /// In en, this message translates to:
  /// **'Apply to editor'**
  String get styleExplore_applyToEditor;

  /// styleExplore_seedName.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get styleExplore_seedName;

  /// styleExplore_elapsedName.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get styleExplore_elapsedName;

  /// styleExplore_parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get styleExplore_parameters;

  /// styleExplore_modelName.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get styleExplore_modelName;

  /// styleExplore_fullPrompt.
  ///
  /// In en, this message translates to:
  /// **'Full prompt'**
  String get styleExplore_fullPrompt;

  /// styleExplore_mergedArtists.
  ///
  /// In en, this message translates to:
  /// **'Combined artists (deduplicated)'**
  String get styleExplore_mergedArtists;

  /// styleExplore_selectionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Save as block combines these into one block; evolution uses each image’s artist string as a parent.'**
  String get styleExplore_selectionExplanation;

  /// styleExplore_quickGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Group with 1–9'**
  String get styleExplore_quickGroupHint;

  /// Inspector compact new group chip.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get styleExplore_newGroupChip;

  /// Inspector generation parameter summary.
  ///
  /// In en, this message translates to:
  /// **'{width}×{height} · {steps} steps · {scale}'**
  String styleExplore_parameterSummary(
    int width,
    int height,
    int steps,
    String scale,
  );

  /// Exploration viewer.
  ///
  /// In en, this message translates to:
  /// **'Style exploration'**
  String get styleExplore_viewerBack;

  /// Exploration viewer.
  ///
  /// In en, this message translates to:
  /// **'Image {index} / {total}'**
  String styleExplore_viewerPosition(int index, int total);

  /// Exploration viewer.
  ///
  /// In en, this message translates to:
  /// **'1–9: group; 0: ungroup'**
  String get styleExplore_viewerGroupsShortcut;

  /// Exploration viewer.
  ///
  /// In en, this message translates to:
  /// **'Seed (click to copy)'**
  String get styleExplore_seedClickCopy;

  /// Candidate prompt applied to editor.
  ///
  /// In en, this message translates to:
  /// **'Applied to editor'**
  String get styleExplore_appliedToEditor;

  /// No description provided for @styleExplore_generationNumber.
  ///
  /// In en, this message translates to:
  /// **'Generation {index}'**
  String styleExplore_generationNumber(int index);

  /// No description provided for @styleExplore_currentGeneration.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get styleExplore_currentGeneration;

  /// No description provided for @styleExplore_generationStart.
  ///
  /// In en, this message translates to:
  /// **'Started with {count} candidates'**
  String styleExplore_generationStart(int count);

  /// No description provided for @styleExplore_generationSource.
  ///
  /// In en, this message translates to:
  /// **'{count} picked from generation {index} + {roots} founders'**
  String styleExplore_generationSource(int index, int count, int roots);

  /// No description provided for @styleExplore_parentsByPreference.
  ///
  /// In en, this message translates to:
  /// **'Parents · By preference'**
  String get styleExplore_parentsByPreference;

  /// No description provided for @styleExplore_backcross.
  ///
  /// In en, this message translates to:
  /// **'Backcross'**
  String get styleExplore_backcross;

  /// No description provided for @styleExplore_childrenCount.
  ///
  /// In en, this message translates to:
  /// **'Offspring · {count}'**
  String styleExplore_childrenCount(int count);

  /// No description provided for @styleExplore_breedSelected.
  ///
  /// In en, this message translates to:
  /// **'Breed generation {index} with {count} selected'**
  String styleExplore_breedSelected(int count, int index);

  /// No description provided for @styleExplore_generationBusy.
  ///
  /// In en, this message translates to:
  /// **'This generation is still generating'**
  String get styleExplore_generationBusy;

  /// No description provided for @styleExplore_regeneratePrefix.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get styleExplore_regeneratePrefix;

  /// No description provided for @styleExplore_regenerateSuffix.
  ///
  /// In en, this message translates to:
  /// **'offspring'**
  String get styleExplore_regenerateSuffix;

  /// No description provided for @styleExplore_pairCompare.
  ///
  /// In en, this message translates to:
  /// **'Rank by pairwise comparison'**
  String get styleExplore_pairCompare;

  /// No description provided for @styleExplore_howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get styleExplore_howToUse;

  /// No description provided for @styleExplore_helpParents.
  ///
  /// In en, this message translates to:
  /// **'Parents are the artist combinations you pick; higher preference makes them more likely to contribute.'**
  String get styleExplore_helpParents;

  /// No description provided for @styleExplore_helpChildren.
  ///
  /// In en, this message translates to:
  /// **'Offspring come from crossing parents, mutations, or new artists injected from a pool.'**
  String get styleExplore_helpChildren;

  /// No description provided for @styleExplore_helpCompare.
  ///
  /// In en, this message translates to:
  /// **'Pairwise comparison updates parent preferences and influences later combinations.'**
  String get styleExplore_helpCompare;

  /// No description provided for @styleExplore_helpBackcross.
  ///
  /// In en, this message translates to:
  /// **'Breeding the next generation automatically includes first-generation parents for backcrossing.'**
  String get styleExplore_helpBackcross;

  /// No description provided for @styleExplore_originTitle.
  ///
  /// In en, this message translates to:
  /// **'How it was made'**
  String get styleExplore_originTitle;

  /// No description provided for @styleExplore_originCross.
  ///
  /// In en, this message translates to:
  /// **'Artist combinations crossed from these parents'**
  String get styleExplore_originCross;

  /// No description provided for @styleExplore_originMutation.
  ///
  /// In en, this message translates to:
  /// **'Some artists were replaced in the parent combination'**
  String get styleExplore_originMutation;

  /// No description provided for @styleExplore_originInjection.
  ///
  /// In en, this message translates to:
  /// **'New artists were injected from the pool'**
  String get styleExplore_originInjection;

  /// No description provided for @styleExplore_newArtist.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get styleExplore_newArtist;

  /// No description provided for @styleExplore_evolutionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick a few favorites from the candidates to start an evolution line'**
  String get styleExplore_evolutionEmpty;

  /// No description provided for @styleExplore_pickFromCandidates.
  ///
  /// In en, this message translates to:
  /// **'Pick candidates'**
  String get styleExplore_pickFromCandidates;

  /// No description provided for @styleExplore_generationSummary.
  ///
  /// In en, this message translates to:
  /// **'{parents} parents · {children} offspring · {selected} picked for the next generation'**
  String styleExplore_generationSummary(
    int parents,
    int children,
    int selected,
  );

  /// No description provided for @styleExplore_breedNext.
  ///
  /// In en, this message translates to:
  /// **'Breed next generation'**
  String get styleExplore_breedNext;

  /// No description provided for @styleExplore_optionalName.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get styleExplore_optionalName;

  /// No description provided for @styleExplore_childrenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offspring yet. Generate a batch above.'**
  String get styleExplore_childrenEmpty;

  /// No description provided for @styleExplore_evolutionStepOne.
  ///
  /// In en, this message translates to:
  /// **'Mix parent artists to generate offspring'**
  String get styleExplore_evolutionStepOne;

  /// No description provided for @styleExplore_evolutionStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Compare pairs to show your preferences'**
  String get styleExplore_evolutionStepTwo;

  /// No description provided for @styleExplore_evolutionStepThree.
  ///
  /// In en, this message translates to:
  /// **'Pick the best offspring for the next generation'**
  String get styleExplore_evolutionStepThree;

  /// No description provided for @styleExplore_evolutionNewLine.
  ///
  /// In en, this message translates to:
  /// **'New evolution line'**
  String get styleExplore_evolutionNewLine;

  /// No description provided for @styleExplore_evolutionJoinLine.
  ///
  /// In en, this message translates to:
  /// **'Join the current generation of “{name}”'**
  String styleExplore_evolutionJoinLine(String name);

  /// No description provided for @styleExplore_evolutionName.
  ///
  /// In en, this message translates to:
  /// **'Evolution line name'**
  String get styleExplore_evolutionName;

  /// No description provided for @styleExplore_defaultEvolutionName.
  ///
  /// In en, this message translates to:
  /// **'Evolution line {n}'**
  String styleExplore_defaultEvolutionName(int n);

  /// No description provided for @styleExplore_evolutionAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add a custom artist string'**
  String get styleExplore_evolutionAddCustom;

  /// No description provided for @styleExplore_evolutionCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an artist string'**
  String get styleExplore_evolutionCustomHint;

  /// No description provided for @styleExplore_evolutionParentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No usable artist string'**
  String get styleExplore_evolutionParentEmpty;

  /// No description provided for @styleExplore_evolutionTarget.
  ///
  /// In en, this message translates to:
  /// **'Offspring replace'**
  String get styleExplore_evolutionTarget;

  /// No description provided for @styleExplore_evolutionOnlyCreate.
  ///
  /// In en, this message translates to:
  /// **'Create only'**
  String get styleExplore_evolutionOnlyCreate;

  /// No description provided for @styleExplore_evolutionOnlyJoin.
  ///
  /// In en, this message translates to:
  /// **'Add only'**
  String get styleExplore_evolutionOnlyJoin;

  /// No description provided for @styleExplore_evolutionCreateGenerate.
  ///
  /// In en, this message translates to:
  /// **'Create and generate {count}'**
  String styleExplore_evolutionCreateGenerate(int count);

  /// No description provided for @styleExplore_evolutionJoinGenerate.
  ///
  /// In en, this message translates to:
  /// **'Add and generate {count}'**
  String styleExplore_evolutionJoinGenerate(int count);

  /// No description provided for @styleExplore_evolutionFirstBatch.
  ///
  /// In en, this message translates to:
  /// **'First offspring batch'**
  String get styleExplore_evolutionFirstBatch;

  /// No description provided for @styleExplore_evolutionMinimum.
  ///
  /// In en, this message translates to:
  /// **'images (at least {count})'**
  String styleExplore_evolutionMinimum(int count);

  /// No description provided for @styleExplore_evolutionCreated.
  ///
  /// In en, this message translates to:
  /// **'Created evolution line “{name}”'**
  String styleExplore_evolutionCreated(String name);

  /// No description provided for @styleExplore_evolutionJoined.
  ///
  /// In en, this message translates to:
  /// **'Added to evolution line “{name}”'**
  String styleExplore_evolutionJoined(String name);

  /// No description provided for @styleExplore_sortLiveSave.
  ///
  /// In en, this message translates to:
  /// **'Results save live; close at any time'**
  String get styleExplore_sortLiveSave;

  /// No description provided for @styleExplore_sortRanking.
  ///
  /// In en, this message translates to:
  /// **'Current ranking · Live'**
  String get styleExplore_sortRanking;

  /// No description provided for @styleExplore_sortRankingHint.
  ///
  /// In en, this message translates to:
  /// **'Ranking affects each parent’s chance of selection in the next offspring batch'**
  String get styleExplore_sortRankingHint;

  /// No description provided for @styleExplore_sortSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get styleExplore_sortSpace;

  /// No description provided for @styleExplore_saveSingleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save the artists from #{n} as one block'**
  String styleExplore_saveSingleSubtitle(int n);

  /// No description provided for @styleExplore_saveManySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine artists from {count} candidates into one library block'**
  String styleExplore_saveManySubtitle(int count);

  /// No description provided for @styleExplore_saveArtistsOnly.
  ///
  /// In en, this message translates to:
  /// **'Drawn artists only'**
  String get styleExplore_saveArtistsOnly;

  /// No description provided for @styleExplore_saveFullPositive.
  ///
  /// In en, this message translates to:
  /// **'Full positive prompt'**
  String get styleExplore_saveFullPositive;

  /// No description provided for @styleExplore_saveNoDraws.
  ///
  /// In en, this message translates to:
  /// **'These candidates have no positive genetic draw records; save the full positive prompt'**
  String get styleExplore_saveNoDraws;

  /// No description provided for @styleExplore_saveContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get styleExplore_saveContent;

  /// No description provided for @styleExplore_saveRemoveAtoms.
  ///
  /// In en, this message translates to:
  /// **'Click × to remove unwanted artists'**
  String get styleExplore_saveRemoveAtoms;

  /// No description provided for @styleExplore_saveRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {count}'**
  String styleExplore_saveRemoved(int count);

  /// No description provided for @styleExplore_saveRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get styleExplore_saveRestore;

  /// No description provided for @styleExplore_saveName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get styleExplore_saveName;

  /// No description provided for @styleExplore_saveColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get styleExplore_saveColor;

  /// No description provided for @styleExplore_saveIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get styleExplore_saveIcon;

  /// No description provided for @styleExplore_saveFolder.
  ///
  /// In en, this message translates to:
  /// **'Library folder'**
  String get styleExplore_saveFolder;

  /// No description provided for @styleExplore_saveRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get styleExplore_saveRoot;

  /// No description provided for @styleExplore_saveHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the saved block from the library into a prompt'**
  String get styleExplore_saveHint;

  /// No description provided for @styleExplore_onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore styles with random blocks'**
  String get styleExplore_onboardingTitle;

  /// No description provided for @styleExplore_onboardingRandomTitle.
  ///
  /// In en, this message translates to:
  /// **'Add random blocks'**
  String get styleExplore_onboardingRandomTitle;

  /// No description provided for @styleExplore_onboardingDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw a candidate batch'**
  String get styleExplore_onboardingDrawTitle;

  /// No description provided for @styleExplore_onboardingDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw {count} candidates'**
  String styleExplore_onboardingDraw(int count);

  /// No description provided for @styleExplore_onboardingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite, compare, evolve'**
  String get styleExplore_onboardingReviewTitle;

  /// No description provided for @styleExplore_onboardingOpenPrevious.
  ///
  /// In en, this message translates to:
  /// **'Open previous explorations'**
  String get styleExplore_onboardingOpenPrevious;

  /// No description provided for @styleExplore_onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each image draws artists again from random blocks. Just choose your favorites.'**
  String get styleExplore_onboardingSubtitle;

  /// No description provided for @styleExplore_onboardingRandomDescription.
  ///
  /// In en, this message translates to:
  /// **'Insert an artist-pool block in the prompt, such as the 400-artist pool. Detected random variables appear on the left.'**
  String get styleExplore_onboardingRandomDescription;

  /// No description provided for @styleExplore_onboardingDrawDescription.
  ///
  /// In en, this message translates to:
  /// **'Click “Draw {count} candidates” at the bottom left. Each image lists the artists it drew.'**
  String styleExplore_onboardingDrawDescription(int count);

  /// No description provided for @styleExplore_onboardingReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Press F to favorite images; select a few to evolve and combine promising artists into the next generation.'**
  String get styleExplore_onboardingReviewDescription;

  /// No description provided for @styleExplore_onboardingDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected {count}'**
  String styleExplore_onboardingDetected(int count);

  /// No description provided for @styleExplore_compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair comparison · Rank parents'**
  String get styleExplore_compareTitle;

  /// No description provided for @styleExplore_compareQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which image is closer to the style you want?'**
  String get styleExplore_compareQuestion;

  /// No description provided for @styleExplore_childLabel.
  ///
  /// In en, this message translates to:
  /// **'Child #{index}'**
  String styleExplore_childLabel(int index);

  /// No description provided for @styleExplore_generationCounts.
  ///
  /// In en, this message translates to:
  /// **'{parents} parents → {children} children'**
  String styleExplore_generationCounts(int parents, int children);

  /// No description provided for @styleExplore_viewLarge.
  ///
  /// In en, this message translates to:
  /// **'View large'**
  String get styleExplore_viewLarge;

  /// No description provided for @styleExplore_saveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save as a prompt block'**
  String get styleExplore_saveDialogTitle;

  /// No description provided for @styleExplore_startDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Start evolution with {count} candidates'**
  String styleExplore_startDialogTitle(int count);

  /// No description provided for @styleExplore_stepGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate offspring'**
  String get styleExplore_stepGenerate;

  /// No description provided for @styleExplore_stepPick.
  ///
  /// In en, this message translates to:
  /// **'Pick the best'**
  String get styleExplore_stepPick;

  /// No description provided for @styleExplore_stepBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed the next generation'**
  String get styleExplore_stepBreed;

  /// No description provided for @styleExplore_firstGenerationParents.
  ///
  /// In en, this message translates to:
  /// **'Generation 1 parents · {count}'**
  String styleExplore_firstGenerationParents(int count);

  /// No description provided for @styleExplore_evolutionTargetAfter.
  ///
  /// In en, this message translates to:
  /// **'while keeping the rest unchanged'**
  String get styleExplore_evolutionTargetAfter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
