import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
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
    Locale('zh'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'NAI Launcher'**
  String get app_title;

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

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

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

  /// No description provided for @common_replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get common_replace;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get common_exit;

  /// No description provided for @common_folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get common_folder;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get common_grid;

  /// No description provided for @common_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get common_date;

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

  /// No description provided for @common_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get common_categories;

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

  /// No description provided for @nav_dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary (WIP)'**
  String get nav_dictionary;

  /// No description provided for @nav_discordCommunity.
  ///
  /// In en, this message translates to:
  /// **'Discord Community'**
  String get nav_discordCommunity;

  /// No description provided for @nav_githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get nav_githubRepo;

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

  /// No description provided for @auth_loginTip.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your NovelAI account\nAll data is stored locally only'**
  String get auth_loginTip;

  /// No description provided for @auth_guestEntry.
  ///
  /// In en, this message translates to:
  /// **'Skip login and continue as guest'**
  String get auth_guestEntry;

  /// No description provided for @auth_loggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get auth_loggedIn;

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

  /// No description provided for @auth_tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Persistent API Token'**
  String get auth_tokenHint;

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

  /// No description provided for @auth_nicknameOptional.
  ///
  /// In en, this message translates to:
  /// **'Nickname (optional)'**
  String get auth_nicknameOptional;

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

  /// No description provided for @auth_savedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Saved Accounts'**
  String get auth_savedAccounts;

  /// No description provided for @auth_addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get auth_addAccount;

  /// No description provided for @auth_manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get auth_manageAccounts;

  /// No description provided for @auth_moreAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count} more accounts'**
  String auth_moreAccounts(Object count);

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

  /// No description provided for @auth_removeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Avatar'**
  String get auth_removeAvatar;

  /// No description provided for @auth_selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get auth_selectFromGallery;

  /// No description provided for @auth_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get auth_takePhoto;

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

  /// No description provided for @auth_createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at {date}'**
  String auth_createdAt(Object date);

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

  /// No description provided for @auth_pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get auth_pleaseWait;

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

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

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

  /// No description provided for @settings_languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get settings_languageChinese;

  /// No description provided for @settings_languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_languageEnglish;

  /// No description provided for @settings_languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get settings_languageJapanese;

  /// No description provided for @settings_shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get settings_shortcuts;

  /// No description provided for @settings_generation.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get settings_generation;

  /// No description provided for @settings_dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settings_dataStorage;

  /// No description provided for @settings_privacySharing.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Sharing'**
  String get settings_privacySharing;

  /// No description provided for @settings_integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settings_integrations;

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

  /// No description provided for @settings_promptAssistant.
  ///
  /// In en, this message translates to:
  /// **'Prompt Assistant'**
  String get settings_promptAssistant;

  /// No description provided for @settings_selectStyle.
  ///
  /// In en, this message translates to:
  /// **'Select Style'**
  String get settings_selectStyle;

  /// No description provided for @settings_defaultPreset.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settings_defaultPreset;

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
  /// **'Extra gallery sources: add any folder to browse and search in the gallery (read-only, not used for auto-save). After adding, run a rescan in the gallery or at the bottom of this page.'**
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
  /// **'Gallery source added; rescan to apply'**
  String get settings_extraRootsAdded;

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

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

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

  /// No description provided for @settings_thirdPartyApiAccount.
  ///
  /// In en, this message translates to:
  /// **'Third-party Site API'**
  String get settings_thirdPartyApiAccount;

  /// No description provided for @settings_apiSite.
  ///
  /// In en, this message translates to:
  /// **'API Site'**
  String get settings_apiSite;

  /// No description provided for @settings_notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Log in to set avatar and nickname'**
  String get settings_notLoggedIn;

  /// No description provided for @settings_goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get settings_goToLogin;

  /// No description provided for @settings_tapToChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Tap to change avatar'**
  String get settings_tapToChangeAvatar;

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

  /// No description provided for @settings_editNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit Nickname'**
  String get settings_editNickname;

  /// No description provided for @settings_nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get settings_nickname;

  /// No description provided for @settings_nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 2-32 characters'**
  String get settings_nicknameHint;

  /// No description provided for @settings_nicknameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get settings_nicknameEmpty;

  /// No description provided for @settings_nicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname cannot exceed {maxLength} characters'**
  String settings_nicknameTooLong(int maxLength);

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

  /// No description provided for @generation_skipCurrentBatch.
  ///
  /// In en, this message translates to:
  /// **'Skip Current Batch'**
  String get generation_skipCurrentBatch;

  /// No description provided for @generation_stopAllGeneration.
  ///
  /// In en, this message translates to:
  /// **'Stop All'**
  String get generation_stopAllGeneration;

  /// No description provided for @generation_pleaseInputPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter prompt'**
  String get generation_pleaseInputPrompt;

  /// No description provided for @generation_emptyPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt and click generate'**
  String get generation_emptyPromptHint;

  /// No description provided for @generation_imageWillShowHere.
  ///
  /// In en, this message translates to:
  /// **'Image will be displayed here'**
  String get generation_imageWillShowHere;

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

  /// No description provided for @generation_cfgScale.
  ///
  /// In en, this message translates to:
  /// **'CFG Scale: {scale}'**
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

  /// No description provided for @generation_seedLock.
  ///
  /// In en, this message translates to:
  /// **'Lock Seed'**
  String get generation_seedLock;

  /// No description provided for @generation_seedUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Seed'**
  String get generation_seedUnlock;

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
  /// **'CFG Rescale: {value}'**
  String generation_cfgRescale(Object value);

  /// No description provided for @generation_noiseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Noise Schedule'**
  String get generation_noiseSchedule;

  /// No description provided for @prompt_positive.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get prompt_positive;

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

  /// No description provided for @prompt_inputPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt...'**
  String get prompt_inputPrompt;

  /// No description provided for @prompt_describeImage.
  ///
  /// In en, this message translates to:
  /// **'Describe the image you want to generate...'**
  String get prompt_describeImage;

  /// No description provided for @prompt_describeImageWithHint.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt to describe image, type < to reference library, supports tag autocomplete'**
  String get prompt_describeImageWithHint;

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

  /// No description provided for @promptAssistant_needPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a prompt before using the assistant'**
  String get promptAssistant_needPrompt;

  /// No description provided for @promptAssistant_requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Assistant request failed: {error}'**
  String promptAssistant_requestFailed(Object error);

  /// No description provided for @promptAssistant_enableAssistant.
  ///
  /// In en, this message translates to:
  /// **'Enable Prompt Assistant'**
  String get promptAssistant_enableAssistant;

  /// No description provided for @promptAssistant_desktopOverlay.
  ///
  /// In en, this message translates to:
  /// **'Desktop bottom-right overlay'**
  String get promptAssistant_desktopOverlay;

  /// No description provided for @kritaBridge_busyGenerating.
  ///
  /// In en, this message translates to:
  /// **'Krita Bridge is generating. Wait for the current task to finish.'**
  String get kritaBridge_busyGenerating;

  /// No description provided for @prompt_negativeFixedTagPrefix.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Fixed Tag Prefix'**
  String get prompt_negativeFixedTagPrefix;

  /// No description provided for @prompt_negativeFixedTagSuffix.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Fixed Tag Suffix'**
  String get prompt_negativeFixedTagSuffix;

  /// No description provided for @prompt_unwantedContent.
  ///
  /// In en, this message translates to:
  /// **'Content you don\'t want in the image...'**
  String get prompt_unwantedContent;

  /// No description provided for @prompt_smartAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Smart Autocomplete'**
  String get prompt_smartAutocomplete;

  /// No description provided for @prompt_smartAutocompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show tag suggestions while typing'**
  String get prompt_smartAutocompleteSubtitle;

  /// No description provided for @prompt_autoFormat.
  ///
  /// In en, this message translates to:
  /// **'Auto Format'**
  String get prompt_autoFormat;

  /// No description provided for @prompt_autoFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Normalize commas and whitespace, preserve word spaces and safely close weights'**
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

  /// No description provided for @prompt_resolveAliasOnCopy.
  ///
  /// In en, this message translates to:
  /// **'Expand Library On Copy'**
  String get prompt_resolveAliasOnCopy;

  /// No description provided for @prompt_resolveAliasOnCopySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace <library name> with its content when copying or cutting'**
  String get prompt_resolveAliasOnCopySubtitle;

  /// No description provided for @prompt_cooccurrenceRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Co-occurrence Tag Recommendation'**
  String get prompt_cooccurrenceRecommendation;

  /// No description provided for @prompt_cooccurrenceRecommendationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest after accepting a tag; Ctrl+Shift+Space or Ctrl+click also opens related tags'**
  String get prompt_cooccurrenceRecommendationSubtitle;

  /// No description provided for @prompt_regexRulesManage.
  ///
  /// In en, this message translates to:
  /// **'Regex Replace Rules...'**
  String get prompt_regexRulesManage;

  /// No description provided for @prompt_regexRulesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rule(s) configured'**
  String prompt_regexRulesCount(int count);

  /// No description provided for @prompt_regexReplaceApplied.
  ///
  /// In en, this message translates to:
  /// **'Regex replace: {count} rule(s)'**
  String prompt_regexReplaceApplied(int count);

  /// No description provided for @prompt_regexInvalidRules.
  ///
  /// In en, this message translates to:
  /// **'Skipped invalid regex rule(s): {names}'**
  String prompt_regexInvalidRules(Object names);

  /// No description provided for @regexRules_title.
  ///
  /// In en, this message translates to:
  /// **'Regex Replace Rules'**
  String get regexRules_title;

  /// No description provided for @regexRules_hint.
  ///
  /// In en, this message translates to:
  /// **'Rules run in order on the whole prompt, before SD conversion and auto format. Use \$1, \$2 in the replacement to reference capture groups.'**
  String get regexRules_hint;

  /// No description provided for @regexRules_empty.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Create one below.'**
  String get regexRules_empty;

  /// No description provided for @regexRules_add.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get regexRules_add;

  /// No description provided for @regexRules_unnamed.
  ///
  /// In en, this message translates to:
  /// **'Untitled rule'**
  String get regexRules_unnamed;

  /// No description provided for @regexRules_invalidBadge.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get regexRules_invalidBadge;

  /// No description provided for @regexRules_deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get regexRules_deleteConfirmTitle;

  /// No description provided for @regexRules_deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String regexRules_deleteConfirmMessage(Object name);

  /// No description provided for @regexRules_newTitle.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get regexRules_newTitle;

  /// No description provided for @regexRules_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get regexRules_editTitle;

  /// No description provided for @regexRules_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rule name (optional)'**
  String get regexRules_nameLabel;

  /// No description provided for @regexRules_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Normalize hair color'**
  String get regexRules_nameHint;

  /// No description provided for @regexRules_patternLabel.
  ///
  /// In en, this message translates to:
  /// **'Match (regular expression)'**
  String get regexRules_patternLabel;

  /// No description provided for @regexRules_patternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \\bblue[ _]hair\\b'**
  String get regexRules_patternHint;

  /// No description provided for @regexRules_replacementLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get regexRules_replacementLabel;

  /// No description provided for @regexRules_replacementHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. aqua hair'**
  String get regexRules_replacementHint;

  /// No description provided for @regexRules_caseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get regexRules_caseSensitive;

  /// No description provided for @regexRules_patternRequired.
  ///
  /// In en, this message translates to:
  /// **'The match pattern cannot be empty'**
  String get regexRules_patternRequired;

  /// No description provided for @regexRules_patternInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid regular expression: {error}'**
  String regexRules_patternInvalid(Object error);

  /// No description provided for @regexRules_testTitle.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get regexRules_testTitle;

  /// No description provided for @regexRules_testInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a prompt to preview the result'**
  String get regexRules_testInputHint;

  /// No description provided for @regexRules_testNoChange.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get regexRules_testNoChange;

  /// No description provided for @regexRules_testNoRules.
  ///
  /// In en, this message translates to:
  /// **'No enabled rules'**
  String get regexRules_testNoRules;

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

  /// No description provided for @img2img_directorToolsHint.
  ///
  /// In en, this message translates to:
  /// **'Send the current source image through a Director Tool. When the result is ready, you can apply it back as the new source image.'**
  String get img2img_directorToolsHint;

  /// No description provided for @img2img_directorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Extra Prompt'**
  String get img2img_directorPrompt;

  /// No description provided for @img2img_directorPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Add guidance when needed, such as target emotion or color direction'**
  String get img2img_directorPromptHint;

  /// No description provided for @img2img_directorRun.
  ///
  /// In en, this message translates to:
  /// **'Run {tool}'**
  String img2img_directorRun(Object tool);

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

  /// No description provided for @img2img_directorResultReady.
  ///
  /// In en, this message translates to:
  /// **'{tool} completed'**
  String img2img_directorResultReady(Object tool);

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

  /// No description provided for @img2img_directorDefryHint.
  ///
  /// In en, this message translates to:
  /// **'Reduce noise or over-saturation in the result (0 = off, 5 = max)'**
  String get img2img_directorDefryHint;

  /// No description provided for @img2img_directorEmotionLevel.
  ///
  /// In en, this message translates to:
  /// **'Emotion Level'**
  String get img2img_directorEmotionLevel;

  /// No description provided for @img2img_directorEmotionLevelHint.
  ///
  /// In en, this message translates to:
  /// **'How strongly the emotion is applied (0 = subtle, 5 = strong)'**
  String get img2img_directorEmotionLevelHint;

  /// No description provided for @img2img_directorEmotionPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get img2img_directorEmotionPresets;

  /// No description provided for @img2img_directorApplyAsSource.
  ///
  /// In en, this message translates to:
  /// **'Use as Source'**
  String get img2img_directorApplyAsSource;

  /// No description provided for @img2img_directorSourceImage.
  ///
  /// In en, this message translates to:
  /// **'Source Image'**
  String get img2img_directorSourceImage;

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

  /// No description provided for @img2img_enhanceHint.
  ///
  /// In en, this message translates to:
  /// **'Enhance keeps using the current prompt while it upscales and regenerates the source image in latent space.'**
  String get img2img_enhanceHint;

  /// No description provided for @img2img_enhanceMagnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get img2img_enhanceMagnitude;

  /// No description provided for @img2img_enhanceShowIndividualSettings.
  ///
  /// In en, this message translates to:
  /// **'Show Individual Settings'**
  String get img2img_enhanceShowIndividualSettings;

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

  /// No description provided for @img2img_focusedInpaint.
  ///
  /// In en, this message translates to:
  /// **'Focused Inpainting'**
  String get img2img_focusedInpaint;

  /// No description provided for @img2img_focusedInpaintEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Enabled. Adjust the focus area and Minimum Context Area from the top-left control in the inpaint editor.'**
  String get img2img_focusedInpaintEnabledHint;

  /// No description provided for @img2img_focusedInpaintDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Regular inpaint is the default. To use Focused Inpaint, enable it from the top-left control in the inpaint editor and draw a focus area.'**
  String get img2img_focusedInpaintDisabledHint;

  /// No description provided for @img2img_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get img2img_disabled;

  /// No description provided for @img2img_novelAiCloudUpscale.
  ///
  /// In en, this message translates to:
  /// **'NovelAI cloud upscale (fixed 4x)'**
  String get img2img_novelAiCloudUpscale;

  /// No description provided for @img2img_comfyuiEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Enable and connect ComfyUI in Settings > ComfyUI first.'**
  String get img2img_comfyuiEnableHint;

  /// No description provided for @img2img_upscaleMode.
  ///
  /// In en, this message translates to:
  /// **'Upscale Mode'**
  String get img2img_upscaleMode;

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

  /// No description provided for @img2img_noSeedvr2Models.
  ///
  /// In en, this message translates to:
  /// **'No SeedVR2 model found. Refresh the model list or check the SeedVR2 node/model files.'**
  String get img2img_noSeedvr2Models;

  /// No description provided for @img2img_noRegularUpscaleModels.
  ///
  /// In en, this message translates to:
  /// **'No regular upscale model found. Refresh the model list or check models/upscale_models.'**
  String get img2img_noRegularUpscaleModels;

  /// No description provided for @img2img_useSeedvr2TiledWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Using the SeedVR2TilingUpscaler tiled upscale workflow.'**
  String get img2img_useSeedvr2TiledWorkflow;

  /// No description provided for @img2img_useSeedvr2Workflow.
  ///
  /// In en, this message translates to:
  /// **'Using the SeedVR2VideoUpscaler workflow.'**
  String get img2img_useSeedvr2Workflow;

  /// No description provided for @img2img_useRegularUpscaleWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Using UpscaleModelLoader + ImageUpscaleWithModel, then correcting to the target scale with Lanczos.'**
  String get img2img_useRegularUpscaleWorkflow;

  /// No description provided for @img2img_useRtxUpscaleWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Using RTX Video Super Resolution. No model selection is required.'**
  String get img2img_useRtxUpscaleWorkflow;

  /// No description provided for @img2img_refreshModelList.
  ///
  /// In en, this message translates to:
  /// **'Refresh model list'**
  String get img2img_refreshModelList;

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

  /// No description provided for @img2img_upscaleComplete.
  ///
  /// In en, this message translates to:
  /// **'Upscale complete ({width}x{height})'**
  String img2img_upscaleComplete(Object width, Object height);

  /// No description provided for @img2img_regularUpscaleComplete.
  ///
  /// In en, this message translates to:
  /// **'Regular model upscale complete ({width}x{height})'**
  String img2img_regularUpscaleComplete(Object width, Object height);

  /// No description provided for @img2img_rtxUpscaleComplete.
  ///
  /// In en, this message translates to:
  /// **'RTX upscale complete ({width}x{height})'**
  String img2img_rtxUpscaleComplete(Object width, Object height);

  /// No description provided for @img2img_noAvailableSeedvr2Model.
  ///
  /// In en, this message translates to:
  /// **'No available SeedVR2 model selected'**
  String get img2img_noAvailableSeedvr2Model;

  /// No description provided for @img2img_noAvailableRegularUpscaleModel.
  ///
  /// In en, this message translates to:
  /// **'No available regular upscale model selected'**
  String get img2img_noAvailableRegularUpscaleModel;

  /// No description provided for @img2img_decodeSourceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode source image'**
  String get img2img_decodeSourceFailed;

  /// No description provided for @img2img_metricSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get img2img_metricSpeed;

  /// No description provided for @img2img_metricVram.
  ///
  /// In en, this message translates to:
  /// **'VRAM'**
  String get img2img_metricVram;

  /// No description provided for @img2img_metricQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get img2img_metricQuality;

  /// No description provided for @img2img_seedvr2VaeTileHint.
  ///
  /// In en, this message translates to:
  /// **'Also writes the SeedVR2 VAE MODEL encode/decode tile size.'**
  String get img2img_seedvr2VaeTileHint;

  /// No description provided for @img2img_seedvr2UseTiledUpscale.
  ///
  /// In en, this message translates to:
  /// **'Use tiled upscale'**
  String get img2img_seedvr2UseTiledUpscale;

  /// No description provided for @img2img_seedvr2UseTiledUpscaleHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, uses SeedVR2TilingUpscaler. Recommended for large images or high VRAM pressure.'**
  String get img2img_seedvr2UseTiledUpscaleHint;

  /// No description provided for @img2img_seedvr2TileSize.
  ///
  /// In en, this message translates to:
  /// **'Tile Size'**
  String get img2img_seedvr2TileSize;

  /// No description provided for @img2img_seedvr2TileSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Also controls SeedVR2TilingUpscaler tile_width / tile_height.'**
  String get img2img_seedvr2TileSizeHint;

  /// No description provided for @img2img_seedvr2BlocksToSwap.
  ///
  /// In en, this message translates to:
  /// **'Blocks Offloaded To RAM'**
  String get img2img_seedvr2BlocksToSwap;

  /// No description provided for @img2img_seedvr2BlocksToSwapHint.
  ///
  /// In en, this message translates to:
  /// **'How many DiT blocks stay in system RAM and are streamed to VRAM during inference. Higher saves VRAM but uses more RAM and runs slower; lower it (even to 0) when VRAM is plentiful. Raise it if you hit out-of-memory errors.'**
  String get img2img_seedvr2BlocksToSwapHint;

  /// No description provided for @img2img_upscalePanelOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened the Image2Image Upscale panel'**
  String get img2img_upscalePanelOpened;

  /// No description provided for @editor_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get editor_done;

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

  /// No description provided for @editor_clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get editor_clearSelection;

  /// No description provided for @editor_resetView.
  ///
  /// In en, this message translates to:
  /// **'Reset View'**
  String get editor_resetView;

  /// No description provided for @editor_zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get editor_zoom;

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

  /// No description provided for @editor_shortcutUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo (Ctrl+Z)'**
  String get editor_shortcutUndo;

  /// No description provided for @editor_shortcutRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo (Ctrl+Y)'**
  String get editor_shortcutRedo;

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

  /// No description provided for @editor_loadMask.
  ///
  /// In en, this message translates to:
  /// **'Load Mask'**
  String get editor_loadMask;

  /// No description provided for @editor_togglePanels.
  ///
  /// In en, this message translates to:
  /// **'Toggle Panels'**
  String get editor_togglePanels;

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

  /// No description provided for @editor_tempColorPickerShortcut.
  ///
  /// In en, this message translates to:
  /// **'Alt+Click: temporary color picker'**
  String get editor_tempColorPickerShortcut;

  /// No description provided for @editor_shortcutHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcut Help'**
  String get editor_shortcutHelpTitle;

  /// No description provided for @editor_shortcutPaintTools.
  ///
  /// In en, this message translates to:
  /// **'Paint Tools'**
  String get editor_shortcutPaintTools;

  /// No description provided for @editor_shortcutSelectionTools.
  ///
  /// In en, this message translates to:
  /// **'Selection Tools'**
  String get editor_shortcutSelectionTools;

  /// No description provided for @editor_shortcutCanvasView.
  ///
  /// In en, this message translates to:
  /// **'Canvas View'**
  String get editor_shortcutCanvasView;

  /// No description provided for @editor_shortcutBrushAdjust.
  ///
  /// In en, this message translates to:
  /// **'Brush Adjustments'**
  String get editor_shortcutBrushAdjust;

  /// No description provided for @editor_shortcutColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get editor_shortcutColors;

  /// No description provided for @editor_shortcutCanvasActions.
  ///
  /// In en, this message translates to:
  /// **'Canvas Actions'**
  String get editor_shortcutCanvasActions;

  /// No description provided for @editor_shortcutHistoryActions.
  ///
  /// In en, this message translates to:
  /// **'History Actions'**
  String get editor_shortcutHistoryActions;

  /// No description provided for @editor_shortcutSelectionActions.
  ///
  /// In en, this message translates to:
  /// **'Selection Actions'**
  String get editor_shortcutSelectionActions;

  /// No description provided for @editor_shortcutTemporaryColorPicker.
  ///
  /// In en, this message translates to:
  /// **'Temporary Color Picker'**
  String get editor_shortcutTemporaryColorPicker;

  /// No description provided for @editor_shortcutRectSelection.
  ///
  /// In en, this message translates to:
  /// **'Rectangle Selection'**
  String get editor_shortcutRectSelection;

  /// No description provided for @editor_shortcutEllipseSelection.
  ///
  /// In en, this message translates to:
  /// **'Ellipse Selection'**
  String get editor_shortcutEllipseSelection;

  /// No description provided for @editor_shortcutLassoSelection.
  ///
  /// In en, this message translates to:
  /// **'Lasso Selection'**
  String get editor_shortcutLassoSelection;

  /// No description provided for @editor_shortcut100Zoom.
  ///
  /// In en, this message translates to:
  /// **'100% Zoom'**
  String get editor_shortcut100Zoom;

  /// No description provided for @editor_shortcutFitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit Height'**
  String get editor_shortcutFitHeight;

  /// No description provided for @editor_shortcutFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit Width'**
  String get editor_shortcutFitWidth;

  /// No description provided for @editor_shortcutRotateLeft15.
  ///
  /// In en, this message translates to:
  /// **'Rotate Left 15°'**
  String get editor_shortcutRotateLeft15;

  /// No description provided for @editor_shortcutResetRotation.
  ///
  /// In en, this message translates to:
  /// **'Reset Rotation'**
  String get editor_shortcutResetRotation;

  /// No description provided for @editor_shortcutRotateRight15.
  ///
  /// In en, this message translates to:
  /// **'Rotate Right 15°'**
  String get editor_shortcutRotateRight15;

  /// No description provided for @editor_shortcutFlipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontal'**
  String get editor_shortcutFlipHorizontal;

  /// No description provided for @editor_shortcutWheel.
  ///
  /// In en, this message translates to:
  /// **'Mouse Wheel'**
  String get editor_shortcutWheel;

  /// No description provided for @editor_shortcutBrushSmaller.
  ///
  /// In en, this message translates to:
  /// **'Decrease Brush Size'**
  String get editor_shortcutBrushSmaller;

  /// No description provided for @editor_shortcutBrushLarger.
  ///
  /// In en, this message translates to:
  /// **'Increase Brush Size'**
  String get editor_shortcutBrushLarger;

  /// No description provided for @editor_shortcutOpacityLower.
  ///
  /// In en, this message translates to:
  /// **'Decrease Opacity'**
  String get editor_shortcutOpacityLower;

  /// No description provided for @editor_shortcutOpacityHigher.
  ///
  /// In en, this message translates to:
  /// **'Increase Opacity'**
  String get editor_shortcutOpacityHigher;

  /// No description provided for @editor_shortcutDragBrushSize.
  ///
  /// In en, this message translates to:
  /// **'Adjust Brush Size'**
  String get editor_shortcutDragBrushSize;

  /// No description provided for @editor_shortcutSwapColors.
  ///
  /// In en, this message translates to:
  /// **'Swap Foreground/Background Colors'**
  String get editor_shortcutSwapColors;

  /// No description provided for @editor_shortcutPanCanvas.
  ///
  /// In en, this message translates to:
  /// **'Pan Canvas'**
  String get editor_shortcutPanCanvas;

  /// No description provided for @editor_shortcutClearSelectionContent.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection Content'**
  String get editor_shortcutClearSelectionContent;

  /// No description provided for @editor_shortcutCancelCurrentAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Current Action'**
  String get editor_shortcutCancelCurrentAction;

  /// No description provided for @editor_selectUnlockedLayerWithContent.
  ///
  /// In en, this message translates to:
  /// **'Select an unlocked layer with content'**
  String get editor_selectUnlockedLayerWithContent;

  /// No description provided for @editor_readCurrentLayerFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the current layer'**
  String get editor_readCurrentLayerFailed;

  /// No description provided for @editor_localEffects.
  ///
  /// In en, this message translates to:
  /// **'Local Post-processing / Effects'**
  String get editor_localEffects;

  /// No description provided for @editor_basicAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Basic Adjustments'**
  String get editor_basicAdjustments;

  /// No description provided for @editor_styleAndRepair.
  ///
  /// In en, this message translates to:
  /// **'Style & Repair'**
  String get editor_styleAndRepair;

  /// No description provided for @editor_transformCrop.
  ///
  /// In en, this message translates to:
  /// **'Rotate / Flip / Crop'**
  String get editor_transformCrop;

  /// No description provided for @editor_transformCropDescription.
  ///
  /// In en, this message translates to:
  /// **'Geometry operations are separate. They generate a preview first and write back only after confirmation.'**
  String get editor_transformCropDescription;

  /// No description provided for @editor_effectPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Preview does not modify the original image. Click Apply to write the result to the active layer and undo history.'**
  String get editor_effectPreviewHint;

  /// No description provided for @editor_applyToCurrentLayer.
  ///
  /// In en, this message translates to:
  /// **'Apply to Current Layer'**
  String get editor_applyToCurrentLayer;

  /// No description provided for @editor_oneShotEffectHint.
  ///
  /// In en, this message translates to:
  /// **'{effect} is a one-shot operation and has no intensity slider.'**
  String editor_oneShotEffectHint(Object effect);

  /// No description provided for @editor_effectIntensity.
  ///
  /// In en, this message translates to:
  /// **'{effect} Intensity'**
  String editor_effectIntensity(Object effect);

  /// No description provided for @editor_original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get editor_original;

  /// No description provided for @editor_effectPreview.
  ///
  /// In en, this message translates to:
  /// **'Effect Preview'**
  String get editor_effectPreview;

  /// No description provided for @editor_effectBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get editor_effectBrightness;

  /// No description provided for @editor_effectContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get editor_effectContrast;

  /// No description provided for @editor_effectSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get editor_effectSaturation;

  /// No description provided for @editor_effectTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get editor_effectTemperature;

  /// No description provided for @editor_effectGamma.
  ///
  /// In en, this message translates to:
  /// **'Gamma'**
  String get editor_effectGamma;

  /// No description provided for @editor_effectGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get editor_effectGrayscale;

  /// No description provided for @editor_effectInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get editor_effectInvert;

  /// No description provided for @editor_effectSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get editor_effectSepia;

  /// No description provided for @editor_effectDenoise.
  ///
  /// In en, this message translates to:
  /// **'Denoise'**
  String get editor_effectDenoise;

  /// No description provided for @editor_effectBlur.
  ///
  /// In en, this message translates to:
  /// **'Gaussian Blur'**
  String get editor_effectBlur;

  /// No description provided for @editor_effectSharpen.
  ///
  /// In en, this message translates to:
  /// **'Sharpen'**
  String get editor_effectSharpen;

  /// No description provided for @editor_effectCropToSelection.
  ///
  /// In en, this message translates to:
  /// **'Crop to Selection'**
  String get editor_effectCropToSelection;

  /// No description provided for @editor_effectRotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate Left 90°'**
  String get editor_effectRotateLeft;

  /// No description provided for @editor_effectRotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate Right 90°'**
  String get editor_effectRotateRight;

  /// No description provided for @editor_effectFlipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontal'**
  String get editor_effectFlipHorizontal;

  /// No description provided for @editor_effectFlipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip Vertical'**
  String get editor_effectFlipVertical;

  /// No description provided for @editor_effectApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied {effect}'**
  String editor_effectApplied(Object effect);

  /// No description provided for @editor_applyEffectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply effect: {error}'**
  String editor_applyEffectFailed(Object error);

  /// No description provided for @editor_changeCanvasSize.
  ///
  /// In en, this message translates to:
  /// **'Change Canvas Size'**
  String get editor_changeCanvasSize;

  /// No description provided for @editor_canvasTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Canvas size is too small. Minimum size is {width} x {height} pixels'**
  String editor_canvasTooSmall(Object width, Object height);

  /// No description provided for @editor_canvasTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Canvas size is too large. Maximum size is {width} x {height} pixels'**
  String editor_canvasTooLarge(Object width, Object height);

  /// No description provided for @editor_canvasResized.
  ///
  /// In en, this message translates to:
  /// **'Canvas resized to {width} x {height}'**
  String editor_canvasResized(Object width, Object height);

  /// No description provided for @editor_canvasResizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resize canvas: {error}'**
  String editor_canvasResizeFailed(Object error);

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

  /// No description provided for @editor_clickInsideClosedRegion.
  ///
  /// In en, this message translates to:
  /// **'Click inside a closed region to fill it.'**
  String get editor_clickInsideClosedRegion;

  /// No description provided for @editor_drawClosedMaskOutlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Draw a closed mask outline first.'**
  String get editor_drawClosedMaskOutlineFirst;

  /// No description provided for @editor_noClosedRegionAtPosition.
  ///
  /// In en, this message translates to:
  /// **'No fillable closed region at this position.'**
  String get editor_noClosedRegionAtPosition;

  /// No description provided for @editor_generateMaskOverlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate mask overlay'**
  String get editor_generateMaskOverlayFailed;

  /// No description provided for @editor_maskLayerName.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get editor_maskLayerName;

  /// No description provided for @editor_updateMaskLayerFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update mask layer'**
  String get editor_updateMaskLayerFailed;

  /// No description provided for @editor_closedRegionFilled.
  ///
  /// In en, this message translates to:
  /// **'Closed region filled as mask.'**
  String get editor_closedRegionFilled;

  /// No description provided for @editor_fillMaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fill mask: {error}'**
  String editor_fillMaskFailed(Object error);

  /// No description provided for @editor_magicWandNoSource.
  ///
  /// In en, this message translates to:
  /// **'No editable image layer is available for sampling.'**
  String get editor_magicWandNoSource;

  /// No description provided for @editor_magicWandNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'The selected region is already transparent or masked.'**
  String get editor_magicWandNothingChanged;

  /// No description provided for @editor_magicWandModelPreparing.
  ///
  /// In en, this message translates to:
  /// **'Checking the EfficientViT-SAM model…'**
  String get editor_magicWandModelPreparing;

  /// No description provided for @editor_magicWandModelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading the EfficientViT-SAM model: {percent}%'**
  String editor_magicWandModelDownloading(int percent);

  /// No description provided for @editor_magicWandModelLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the EfficientViT-SAM model…'**
  String get editor_magicWandModelLoading;

  /// No description provided for @editor_magicWandEncoding.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image objects…'**
  String get editor_magicWandEncoding;

  /// No description provided for @editor_magicWandSegmenting.
  ///
  /// In en, this message translates to:
  /// **'Segmenting the object at the clicked point…'**
  String get editor_magicWandSegmenting;

  /// No description provided for @editor_magicWandPostprocessing.
  ///
  /// In en, this message translates to:
  /// **'Building the selection…'**
  String get editor_magicWandPostprocessing;

  /// No description provided for @editor_magicWandFailed.
  ///
  /// In en, this message translates to:
  /// **'Magic Wand failed: {error}'**
  String editor_magicWandFailed(Object error);

  /// No description provided for @editor_focusInactiveHint.
  ///
  /// In en, this message translates to:
  /// **'Click the button to enter focus mode, then draw a focus area and paint the mask.'**
  String get editor_focusInactiveHint;

  /// No description provided for @editor_focusReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Focus area selected. You can continue editing the mask with the brush.'**
  String get editor_focusReadyHint;

  /// No description provided for @editor_focusNeedsSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Draw a focus area first, then switch to the brush and paint the mask.'**
  String get editor_focusNeedsSelectionHint;

  /// No description provided for @editor_focusSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get editor_focusSelection;

  /// No description provided for @editor_focusBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get editor_focusBrush;

  /// No description provided for @editor_focusContextHint.
  ///
  /// In en, this message translates to:
  /// **'The outer rectangle is the area sent to Focused Inpaint. The inner rectangle is the main repaint area. The band between them is the Minimum Context Area.'**
  String get editor_focusContextHint;

  /// No description provided for @editor_compressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Output resolution'**
  String get editor_compressionTitle;

  /// No description provided for @editor_compressionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose output resolution'**
  String get editor_compressionTooltip;

  /// No description provided for @editor_compressionUncompressed.
  ///
  /// In en, this message translates to:
  /// **'Original work resolution; no compression will be applied.'**
  String get editor_compressionUncompressed;

  /// No description provided for @editor_compressionApplyOnDone.
  ///
  /// In en, this message translates to:
  /// **'Pica Lanczos3 compression runs once when you press Done. The work canvas stays unchanged.'**
  String get editor_compressionApplyOnDone;

  /// No description provided for @editor_compressionSizeSummary.
  ///
  /// In en, this message translates to:
  /// **'Work {workWidth}×{workHeight} → output {targetWidth}×{targetHeight}'**
  String editor_compressionSizeSummary(
    int workWidth,
    int workHeight,
    int targetWidth,
    int targetHeight,
  );

  /// No description provided for @editor_compressionNormalSummary.
  ///
  /// In en, this message translates to:
  /// **'Normal (about 1 MP): {normalWidth}×{normalHeight}. Lowest: {minimumWidth}×{minimumHeight}.'**
  String editor_compressionNormalSummary(
    int normalWidth,
    int normalHeight,
    int minimumWidth,
    int minimumHeight,
  );

  /// No description provided for @editor_compressionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This work canvas is already below the lowest compression step.'**
  String get editor_compressionUnavailable;

  /// No description provided for @editor_compressionFocusLimited.
  ///
  /// In en, this message translates to:
  /// **'Higher resolutions are unavailable because the current Focused Inpaint selection would exceed the request area limit.'**
  String get editor_compressionFocusLimited;

  /// No description provided for @editor_focusRequestSummary.
  ///
  /// In en, this message translates to:
  /// **'Outer crop {outerWidth}×{outerHeight}, request {requestWidth}×{requestHeight}, estimated {cost} Anlas.'**
  String editor_focusRequestSummary(
    int outerWidth,
    int outerHeight,
    int requestWidth,
    int requestHeight,
    int cost,
  );

  /// No description provided for @editor_unsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format: .{extension}\nPlease choose an image file (PNG, JPG, WEBP, etc.)'**
  String editor_unsupportedImageFormat(Object extension);

  /// No description provided for @editor_readFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file: {error}'**
  String editor_readFileFailed(Object error);

  /// No description provided for @editor_noFileData.
  ///
  /// In en, this message translates to:
  /// **'Failed to get file data'**
  String get editor_noFileData;

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

  /// No description provided for @editor_maskLayerAdded.
  ///
  /// In en, this message translates to:
  /// **'Mask layer added'**
  String get editor_maskLayerAdded;

  /// No description provided for @editor_parseImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse image file\nMake sure the file is not corrupted and the format is supported'**
  String get editor_parseImageFailed;

  /// No description provided for @editor_loadMaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load mask: {error}'**
  String editor_loadMaskFailed(Object error);

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

  /// No description provided for @editor_statusZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom: {value}%'**
  String editor_statusZoom(Object value);

  /// No description provided for @editor_statusCanvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas: {width} x {height}'**
  String editor_statusCanvas(Object width, Object height);

  /// No description provided for @editor_statusLayers.
  ///
  /// In en, this message translates to:
  /// **'Layers: {count}'**
  String editor_statusLayers(Object count);

  /// No description provided for @editor_statusHasSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection active'**
  String get editor_statusHasSelection;

  /// No description provided for @editor_statusRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation: {degrees}°'**
  String editor_statusRotation(Object degrees);

  /// No description provided for @editor_statusMirrored.
  ///
  /// In en, this message translates to:
  /// **'Mirrored'**
  String get editor_statusMirrored;

  /// No description provided for @editor_focusMinimumContextArea.
  ///
  /// In en, this message translates to:
  /// **'Minimum Context Area: {value}'**
  String editor_focusMinimumContextArea(Object value);

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

  /// No description provided for @editor_colorPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Click anywhere on the canvas to pick a color. Release to switch back to the previous tool.'**
  String get editor_colorPickerHint;

  /// No description provided for @editor_sample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get editor_sample;

  /// No description provided for @editor_samplePoint.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get editor_samplePoint;

  /// No description provided for @editor_sampleArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get editor_sampleArea;

  /// No description provided for @editor_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get editor_source;

  /// No description provided for @editor_sourceCurrentLayer.
  ///
  /// In en, this message translates to:
  /// **'Current Layer'**
  String get editor_sourceCurrentLayer;

  /// No description provided for @editor_sourceAllLayers.
  ///
  /// In en, this message translates to:
  /// **'All Layers'**
  String get editor_sourceAllLayers;

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
  /// **'Characters'**
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
  /// **'CFG Scale'**
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

  /// No description provided for @gallery_sentToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Image sent to reverse-prompt module'**
  String get gallery_sentToReversePrompt;

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

  /// No description provided for @onlineGallery_searchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get onlineGallery_searchTags;

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

  /// No description provided for @onlineGallery_sendToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Send to Reverse Prompt'**
  String get onlineGallery_sendToReversePrompt;

  /// No description provided for @onlineGallery_sentToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Sent to reverse-prompt module'**
  String get onlineGallery_sentToReversePrompt;

  /// No description provided for @onlineGallery_reversePromptSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send to reverse prompt: {error}'**
  String onlineGallery_reversePromptSendFailed(Object error);

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

  /// No description provided for @onlineGallery_noImageUrl.
  ///
  /// In en, this message translates to:
  /// **'This image has no available URL'**
  String get onlineGallery_noImageUrl;

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

  /// No description provided for @tooltip_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltip_edit;

  /// No description provided for @tooltip_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tooltip_copy;

  /// No description provided for @tooltip_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltip_delete;

  /// No description provided for @tooltip_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get tooltip_enable;

  /// No description provided for @tooltip_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get tooltip_disable;

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

  /// No description provided for @weight_title.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight_title;

  /// No description provided for @weight_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get weight_reset;

  /// No description provided for @weight_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get weight_done;

  /// No description provided for @weight_noBrackets.
  ///
  /// In en, this message translates to:
  /// **'No brackets'**
  String get weight_noBrackets;

  /// No description provided for @weight_editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get weight_editTag;

  /// No description provided for @weight_tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get weight_tagName;

  /// No description provided for @weight_tagNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name...'**
  String get weight_tagNameHint;

  /// No description provided for @tag_selected.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String tag_selected(Object count);

  /// No description provided for @tag_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get tag_enable;

  /// No description provided for @tag_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get tag_disable;

  /// No description provided for @tag_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tag_delete;

  /// No description provided for @tag_addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get tag_addTag;

  /// No description provided for @tag_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tag_add;

  /// No description provided for @tag_inputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag...'**
  String get tag_inputHint;

  /// No description provided for @tag_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get tag_copiedToClipboard;

  /// No description provided for @tag_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add tags to describe your desired image'**
  String get tag_emptyHint;

  /// No description provided for @tag_emptyHintSub.
  ///
  /// In en, this message translates to:
  /// **'You can browse, search, or add tags manually'**
  String get tag_emptyHintSub;

  /// No description provided for @tagCategory_artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get tagCategory_artist;

  /// No description provided for @tagCategory_copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get tagCategory_copyright;

  /// No description provided for @tagCategory_character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get tagCategory_character;

  /// No description provided for @tagCategory_meta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get tagCategory_meta;

  /// No description provided for @tagCategory_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get tagCategory_general;

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

  /// No description provided for @qualityTags_addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add from Library'**
  String get qualityTags_addFromLibrary;

  /// No description provided for @qualityTags_selectFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select Quality Tag Entry'**
  String get qualityTags_selectFromLibrary;

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

  /// No description provided for @ucPreset_addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add from Library'**
  String get ucPreset_addFromLibrary;

  /// No description provided for @ucPreset_selectFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select UC Entry'**
  String get ucPreset_selectFromLibrary;

  /// No description provided for @batchSize_title.
  ///
  /// In en, this message translates to:
  /// **'Batch Size'**
  String get batchSize_title;

  /// No description provided for @batchSize_tooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} images per request'**
  String batchSize_tooltip(int count);

  /// No description provided for @batchSize_description.
  ///
  /// In en, this message translates to:
  /// **'Number of images per API request'**
  String get batchSize_description;

  /// No description provided for @batchSize_formula.
  ///
  /// In en, this message translates to:
  /// **'Total images = {batchCount} × {batchSize} = {total}'**
  String batchSize_formula(int batchCount, int batchSize, int total);

  /// No description provided for @batchSize_hint.
  ///
  /// In en, this message translates to:
  /// **'Larger batch = fewer requests, but longer wait per request'**
  String get batchSize_hint;

  /// No description provided for @batchSize_costWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Batch size > 1 costs extra Anlas'**
  String get batchSize_costWarning;

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

  /// No description provided for @characterEditor_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get characterEditor_close;

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

  /// No description provided for @characterEditor_promptHint.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt for this character...'**
  String get characterEditor_promptHint;

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

  /// No description provided for @characterEditor_addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get characterEditor_addFromLibrary;

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

  /// No description provided for @toolbar_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get toolbar_clear;

  /// No description provided for @toolbar_confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get toolbar_confirmClear;

  /// No description provided for @toolbar_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get toolbar_settings;

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

  /// No description provided for @naiAlgorithm_mainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Main Prompt'**
  String get naiAlgorithm_mainPrompt;

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

  /// No description provided for @download_completed.
  ///
  /// In en, this message translates to:
  /// **'{name} download completed'**
  String download_completed(Object name);

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'{name} download failed'**
  String download_failed(Object name);

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

  /// No description provided for @download_tags_data.
  ///
  /// In en, this message translates to:
  /// **'Downloading tags data...'**
  String get download_tags_data;

  /// No description provided for @download_cooccurrence_data.
  ///
  /// In en, this message translates to:
  /// **'Downloading cooccurrence data...'**
  String get download_cooccurrence_data;

  /// No description provided for @download_parsing_data.
  ///
  /// In en, this message translates to:
  /// **'Parsing data...'**
  String get download_parsing_data;

  /// No description provided for @download_readingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading file...'**
  String get download_readingFile;

  /// No description provided for @download_mergingData.
  ///
  /// In en, this message translates to:
  /// **'Merging data...'**
  String get download_mergingData;

  /// No description provided for @download_loadComplete.
  ///
  /// In en, this message translates to:
  /// **'Loading complete'**
  String get download_loadComplete;

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

  /// No description provided for @category_selectEmoji.
  ///
  /// In en, this message translates to:
  /// **'Select Emoji'**
  String get category_selectEmoji;

  /// No description provided for @category_noRecentEmoji.
  ///
  /// In en, this message translates to:
  /// **'No recent emojis'**
  String get category_noRecentEmoji;

  /// No description provided for @category_searchEmoji.
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get category_searchEmoji;

  /// No description provided for @vibeNoEncodingWarning.
  ///
  /// In en, this message translates to:
  /// **'This image has no pre-encoded data'**
  String get vibeNoEncodingWarning;

  /// No description provided for @vibeWillCostAnlas.
  ///
  /// In en, this message translates to:
  /// **'Encoding will cost {count} Anlas'**
  String vibeWillCostAnlas(int count);

  /// No description provided for @vibeEncodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue and consume Anlas?'**
  String get vibeEncodeConfirm;

  /// No description provided for @vibeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vibeCancel;

  /// No description provided for @vibeConfirmEncode.
  ///
  /// In en, this message translates to:
  /// **'Encode'**
  String get vibeConfirmEncode;

  /// No description provided for @vibeParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse Vibe file'**
  String get vibeParseFailed;

  /// No description provided for @tagGroupBrowser_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get tagGroupBrowser_searchHint;

  /// No description provided for @tagGroupBrowser_tagCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tags'**
  String tagGroupBrowser_tagCount(Object count);

  /// No description provided for @tagGroupBrowser_filteredTagCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {filtered} of {total} tags'**
  String tagGroupBrowser_filteredTagCount(Object filtered, Object total);

  /// No description provided for @tagGroupBrowser_noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get tagGroupBrowser_noTags;

  /// No description provided for @tagGroupBrowser_noLibrary.
  ///
  /// In en, this message translates to:
  /// **'Tag library not loaded'**
  String get tagGroupBrowser_noLibrary;

  /// No description provided for @tagGroupBrowser_importLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Please import a tag library first'**
  String get tagGroupBrowser_importLibraryHint;

  /// No description provided for @tagGroupBrowser_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No enabled tag categories'**
  String get tagGroupBrowser_noCategories;

  /// No description provided for @tagGroupBrowser_enableCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Please enable tag categories in settings'**
  String get tagGroupBrowser_enableCategoriesHint;

  /// No description provided for @tagGroupBrowser_danbooruSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Danbooru Suggestions'**
  String get tagGroupBrowser_danbooruSuggestions;

  /// No description provided for @tag_favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Tags'**
  String get tag_favoritesTitle;

  /// No description provided for @tag_favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite tags yet'**
  String get tag_favoritesEmpty;

  /// No description provided for @tag_favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press on a tag to add it to favorites'**
  String get tag_favoritesEmptyHint;

  /// No description provided for @tag_alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Tag already added to current prompt'**
  String get tag_alreadyAdded;

  /// No description provided for @tag_removeFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get tag_removeFavoriteTitle;

  /// No description provided for @tag_removeFavoriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{tag}\" from favorites?'**
  String tag_removeFavoriteMessage(Object tag);

  /// No description provided for @tag_templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Templates'**
  String get tag_templatesTitle;

  /// No description provided for @tag_templatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tag templates yet'**
  String get tag_templatesEmpty;

  /// No description provided for @tag_templatesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Select tags and click the + button to create a template'**
  String get tag_templatesEmptyHint;

  /// No description provided for @tag_templateCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get tag_templateCreate;

  /// No description provided for @tag_templateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get tag_templateNameLabel;

  /// No description provided for @tag_templateNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter template name'**
  String get tag_templateNameHint;

  /// No description provided for @tag_templateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a template name'**
  String get tag_templateNameRequired;

  /// No description provided for @tag_templateDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get tag_templateDescLabel;

  /// No description provided for @tag_templateDescHint.
  ///
  /// In en, this message translates to:
  /// **'Enter template description'**
  String get tag_templateDescHint;

  /// No description provided for @tag_templatePreview.
  ///
  /// In en, this message translates to:
  /// **'Tag Preview'**
  String get tag_templatePreview;

  /// No description provided for @tag_templateTagCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tags'**
  String tag_templateTagCount(Object count);

  /// No description provided for @tag_templateMoreTags.
  ///
  /// In en, this message translates to:
  /// **'{count} more tags...'**
  String tag_templateMoreTags(Object count);

  /// No description provided for @tag_templateInserted.
  ///
  /// In en, this message translates to:
  /// **'Inserted template \"{name}\"'**
  String tag_templateInserted(Object name);

  /// No description provided for @tag_templateNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags to save'**
  String get tag_templateNoTags;

  /// No description provided for @tag_templateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get tag_templateSaved;

  /// No description provided for @tag_templateNameExists.
  ///
  /// In en, this message translates to:
  /// **'Template name already exists'**
  String get tag_templateNameExists;

  /// No description provided for @tag_templateDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get tag_templateDeleteTitle;

  /// No description provided for @tag_templateDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete template \"{name}\"?'**
  String tag_templateDeleteMessage(Object name);

  /// No description provided for @tag_categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get tag_categoryGeneral;

  /// No description provided for @tag_categoryArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get tag_categoryArtist;

  /// No description provided for @tag_categoryCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get tag_categoryCopyright;

  /// No description provided for @tag_categoryCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get tag_categoryCharacter;

  /// No description provided for @tag_categoryMeta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get tag_categoryMeta;

  /// No description provided for @tag_countBadgeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Tag Breakdown'**
  String get tag_countBadgeBreakdown;

  /// No description provided for @localGallery_progressiveLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get localGallery_progressiveLoadError;

  /// No description provided for @localGallery_noImagesFound.
  ///
  /// In en, this message translates to:
  /// **'No images found'**
  String get localGallery_noImagesFound;

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

  /// No description provided for @localGallery_loadingGroupedImages.
  ///
  /// In en, this message translates to:
  /// **'Loading grouped images...'**
  String get localGallery_loadingGroupedImages;

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

  /// No description provided for @localGallery_categoryPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get localGallery_categoryPanelTitle;

  /// No description provided for @localGallery_searchFilenamePromptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search filename/Prompt; comma-separated terms are matched together...'**
  String get localGallery_searchFilenamePromptPlaceholder;

  /// No description provided for @localGallery_selectCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Select Page'**
  String get localGallery_selectCurrentPage;

  /// No description provided for @localGallery_deselectCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Deselect Page'**
  String get localGallery_deselectCurrentPage;

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

  /// No description provided for @localGallery_sortToggleDirection.
  ///
  /// In en, this message translates to:
  /// **'Toggle sort direction'**
  String get localGallery_sortToggleDirection;

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

  /// No description provided for @localGallery_thumbnailQualityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose local gallery thumbnail quality'**
  String get localGallery_thumbnailQualityTooltip;

  /// No description provided for @localGallery_naiOnly.
  ///
  /// In en, this message translates to:
  /// **'NAI'**
  String get localGallery_naiOnly;

  /// No description provided for @localGallery_naiOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only show NAI-generated images'**
  String get localGallery_naiOnlyTooltip;

  /// No description provided for @localGallery_naiVersionFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get localGallery_naiVersionFilterLabel;

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

  /// No description provided for @localGallery_switchToMasonryView.
  ///
  /// In en, this message translates to:
  /// **'Switch to waterfall view'**
  String get localGallery_switchToMasonryView;

  /// No description provided for @localGallery_switchToGridLayout.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid view'**
  String get localGallery_switchToGridLayout;

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

  /// No description provided for @localGallery_openFilterPanel.
  ///
  /// In en, this message translates to:
  /// **'Open filter panel'**
  String get localGallery_openFilterPanel;

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

  /// No description provided for @localGallery_enterSelectionMode.
  ///
  /// In en, this message translates to:
  /// **'Enter selection mode'**
  String get localGallery_enterSelectionMode;

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

  /// No description provided for @localGallery_filterByTags.
  ///
  /// In en, this message translates to:
  /// **'Filter by Tags'**
  String get localGallery_filterByTags;

  /// No description provided for @localGallery_tagInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag, press Enter to add'**
  String get localGallery_tagInputHint;

  /// No description provided for @localGallery_addTag.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get localGallery_addTag;

  /// No description provided for @localGallery_createCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get localGallery_createCategoryTitle;

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

  /// No description provided for @localGallery_externalReadonly.
  ///
  /// In en, this message translates to:
  /// **'External gallery sources are read-only; this action is unavailable'**
  String get localGallery_externalReadonly;

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

  /// No description provided for @localGallery_sentToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Image sent to reverse prompt'**
  String get localGallery_sentToReversePrompt;

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

  /// No description provided for @localGallery_sendToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Send to Reverse Prompt'**
  String get localGallery_sendToReversePrompt;

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

  /// No description provided for @localGallery_moveToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to Root'**
  String get localGallery_moveToRoot;

  /// No description provided for @localGallery_folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get localGallery_folderName;

  /// No description provided for @localGallery_newFolderName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get localGallery_newFolderName;

  /// No description provided for @localGallery_folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get localGallery_folderNameHint;

  /// No description provided for @localGallery_folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get localGallery_folderCreated;

  /// No description provided for @localGallery_folderCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get localGallery_folderCreateFailed;

  /// No description provided for @localGallery_renameFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get localGallery_renameFolderTitle;

  /// No description provided for @localGallery_renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get localGallery_renameSuccess;

  /// No description provided for @localGallery_renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get localGallery_renameFailed;

  /// No description provided for @localGallery_deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get localGallery_deleteFolderTitle;

  /// No description provided for @localGallery_deleteFolderWithImagesContent.
  ///
  /// In en, this message translates to:
  /// **'Folder \"{name}\" contains {count} images. Delete it?\n\nNote: this will delete the folder and all images in it. This cannot be undone.'**
  String localGallery_deleteFolderWithImagesContent(Object name, Object count);

  /// No description provided for @localGallery_deleteEmptyFolderContent.
  ///
  /// In en, this message translates to:
  /// **'Delete empty folder \"{name}\"?'**
  String localGallery_deleteEmptyFolderContent(Object name);

  /// No description provided for @localGallery_folderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Folder deleted'**
  String get localGallery_folderDeleted;

  /// No description provided for @localGallery_folderDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete folder'**
  String get localGallery_folderDeleteFailed;

  /// No description provided for @localGallery_cachingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Caching metadata...'**
  String get localGallery_cachingMetadata;

  /// No description provided for @localGallery_metadataCacheStats.
  ///
  /// In en, this message translates to:
  /// **'Metadata Cache Stats'**
  String get localGallery_metadataCacheStats;

  /// No description provided for @localGallery_totalImages.
  ///
  /// In en, this message translates to:
  /// **'Total Images'**
  String get localGallery_totalImages;

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

  /// No description provided for @localGallery_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get localGallery_remaining;

  /// No description provided for @localGallery_cacheMonitor.
  ///
  /// In en, this message translates to:
  /// **'Cache Monitor'**
  String get localGallery_cacheMonitor;

  /// No description provided for @localGallery_threeLayerCacheStats.
  ///
  /// In en, this message translates to:
  /// **'Three-layer Cache Stats'**
  String get localGallery_threeLayerCacheStats;

  /// No description provided for @localGallery_updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String localGallery_updatedAt(Object time);

  /// No description provided for @localGallery_memoryCache.
  ///
  /// In en, this message translates to:
  /// **'Memory Cache'**
  String get localGallery_memoryCache;

  /// No description provided for @localGallery_hiveCache.
  ///
  /// In en, this message translates to:
  /// **'Hive Cache'**
  String get localGallery_hiveCache;

  /// No description provided for @localGallery_sqliteDatabase.
  ///
  /// In en, this message translates to:
  /// **'SQLite Database'**
  String get localGallery_sqliteDatabase;

  /// No description provided for @localGallery_imageUnit.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get localGallery_imageUnit;

  /// No description provided for @localGallery_metadataUnit.
  ///
  /// In en, this message translates to:
  /// **'metadata'**
  String get localGallery_metadataUnit;

  /// No description provided for @localGallery_entriesUnit.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get localGallery_entriesUnit;

  /// No description provided for @localGallery_hitRate.
  ///
  /// In en, this message translates to:
  /// **'Hit Rate'**
  String get localGallery_hitRate;

  /// No description provided for @localGallery_performanceStats.
  ///
  /// In en, this message translates to:
  /// **'Performance Stats'**
  String get localGallery_performanceStats;

  /// No description provided for @localGallery_cacheHit.
  ///
  /// In en, this message translates to:
  /// **'Hit'**
  String get localGallery_cacheHit;

  /// No description provided for @localGallery_cacheMiss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get localGallery_cacheMiss;

  /// No description provided for @localGallery_clearL1.
  ///
  /// In en, this message translates to:
  /// **'Clear L1'**
  String get localGallery_clearL1;

  /// No description provided for @localGallery_clearL2.
  ///
  /// In en, this message translates to:
  /// **'Clear L2'**
  String get localGallery_clearL2;

  /// No description provided for @localGallery_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get localGallery_clearAll;

  /// No description provided for @localGallery_resetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset Stats'**
  String get localGallery_resetStats;

  /// No description provided for @localGallery_confirmClearCache.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get localGallery_confirmClearCache;

  /// No description provided for @localGallery_confirmClearCacheContent.
  ///
  /// In en, this message translates to:
  /// **'Clear all caches? This will rescan all images.'**
  String get localGallery_confirmClearCacheContent;

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

  /// No description provided for @statistics_generatedCount.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get statistics_generatedCount;

  /// No description provided for @statistics_favoriteCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get statistics_favoriteCount;

  /// No description provided for @statistics_tooltipGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {count}'**
  String statistics_tooltipGenerated(Object count);

  /// No description provided for @statistics_tooltipFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorites: {count}'**
  String statistics_tooltipFavorite(Object count);

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

  /// No description provided for @localGallery_advancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get localGallery_advancedFilters;

  /// No description provided for @localGallery_filterByModel.
  ///
  /// In en, this message translates to:
  /// **'Filter by Model'**
  String get localGallery_filterByModel;

  /// No description provided for @localGallery_filterBySampler.
  ///
  /// In en, this message translates to:
  /// **'Filter by Sampler'**
  String get localGallery_filterBySampler;

  /// No description provided for @localGallery_filterBySteps.
  ///
  /// In en, this message translates to:
  /// **'Filter by Steps'**
  String get localGallery_filterBySteps;

  /// No description provided for @localGallery_filterByCfg.
  ///
  /// In en, this message translates to:
  /// **'Filter by CFG Scale'**
  String get localGallery_filterByCfg;

  /// No description provided for @localGallery_filterByResolution.
  ///
  /// In en, this message translates to:
  /// **'Filter by Resolution'**
  String get localGallery_filterByResolution;

  /// No description provided for @localGallery_filterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Precisely filter your image collection'**
  String get localGallery_filterSubtitle;

  /// No description provided for @localGallery_filterOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get localGallery_filterOrientation;

  /// No description provided for @localGallery_orientationAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get localGallery_orientationAny;

  /// No description provided for @localGallery_orientationLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get localGallery_orientationLandscape;

  /// No description provided for @localGallery_orientationPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get localGallery_orientationPortrait;

  /// No description provided for @localGallery_orientationSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get localGallery_orientationSquare;

  /// No description provided for @localGallery_filterNsfw.
  ///
  /// In en, this message translates to:
  /// **'Content Rating'**
  String get localGallery_filterNsfw;

  /// No description provided for @localGallery_nsfwAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get localGallery_nsfwAny;

  /// No description provided for @localGallery_nsfwSfw.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get localGallery_nsfwSfw;

  /// No description provided for @localGallery_nsfwOnly.
  ///
  /// In en, this message translates to:
  /// **'NSFW only'**
  String get localGallery_nsfwOnly;

  /// No description provided for @localGallery_noModelCandidates.
  ///
  /// In en, this message translates to:
  /// **'No model metadata found yet'**
  String get localGallery_noModelCandidates;

  /// No description provided for @localGallery_noSamplerCandidates.
  ///
  /// In en, this message translates to:
  /// **'No sampler metadata found yet'**
  String get localGallery_noSamplerCandidates;

  /// No description provided for @localGallery_noResolutionCandidates.
  ///
  /// In en, this message translates to:
  /// **'No resolution metadata found yet'**
  String get localGallery_noResolutionCandidates;

  /// No description provided for @localGallery_candidatesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load candidates'**
  String get localGallery_candidatesLoadFailed;

  /// No description provided for @localGallery_noTagSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No matching tags'**
  String get localGallery_noTagSuggestions;

  /// No description provided for @localGallery_activeFiltersSet.
  ///
  /// In en, this message translates to:
  /// **'Filters set'**
  String get localGallery_activeFiltersSet;

  /// No description provided for @localGallery_applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get localGallery_applyFilters;

  /// No description provided for @localGallery_resetAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Advanced Filters'**
  String get localGallery_resetAdvancedFilters;

  /// No description provided for @localGallery_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get localGallery_exportFailed;

  /// No description provided for @bulkExport_format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get bulkExport_format;

  /// No description provided for @bulkExport_jsonFormat.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get bulkExport_jsonFormat;

  /// No description provided for @bulkExport_csvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get bulkExport_csvFormat;

  /// No description provided for @bulkExport_includeMetadataHint.
  ///
  /// In en, this message translates to:
  /// **'Export generation parameters with images'**
  String get bulkExport_includeMetadataHint;

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

  /// No description provided for @localGallery_group_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get localGallery_group_thisWeek;

  /// No description provided for @localGallery_group_earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get localGallery_group_earlier;

  /// No description provided for @localGallery_cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open folder: {error}'**
  String localGallery_cannotOpenFolder(Object error);

  /// No description provided for @localGallery_permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get localGallery_permissionRequiredTitle;

  /// No description provided for @localGallery_permissionRequiredContent.
  ///
  /// In en, this message translates to:
  /// **'Local gallery needs storage permission to scan your generated images.\n\nPlease grant permission in settings and try again.'**
  String get localGallery_permissionRequiredContent;

  /// No description provided for @localGallery_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get localGallery_openSettings;

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

  /// No description provided for @localGallery_noFoldersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No folders available, please create a folder first'**
  String get localGallery_noFoldersAvailable;

  /// No description provided for @localGallery_moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get localGallery_moveToFolder;

  /// No description provided for @localGallery_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String localGallery_imageCount(Object count);

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

  /// No description provided for @fixedTags_label.
  ///
  /// In en, this message translates to:
  /// **'Fixed Tags'**
  String get fixedTags_label;

  /// No description provided for @fixedTags_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get fixedTags_enabled;

  /// No description provided for @fixedTags_empty.
  ///
  /// In en, this message translates to:
  /// **'No fixed tags'**
  String get fixedTags_empty;

  /// No description provided for @fixedTags_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to add fixed tags, they will be automatically applied to your prompts'**
  String get fixedTags_emptyHint;

  /// No description provided for @fixedTags_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage Fixed Tags'**
  String get fixedTags_manage;

  /// No description provided for @fixedTags_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get fixedTags_add;

  /// No description provided for @fixedTags_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Fixed Tag'**
  String get fixedTags_edit;

  /// No description provided for @fixedTags_openLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get fixedTags_openLibrary;

  /// No description provided for @fixedTags_prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get fixedTags_prefix;

  /// No description provided for @fixedTags_suffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get fixedTags_suffix;

  /// No description provided for @fixedTags_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get fixedTags_disabled;

  /// No description provided for @fixedTags_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get fixedTags_weight;

  /// No description provided for @fixedTags_position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get fixedTags_position;

  /// No description provided for @fixedTags_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fixedTags_name;

  /// No description provided for @fixedTags_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name (optional)'**
  String get fixedTags_nameHint;

  /// No description provided for @fixedTags_content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get fixedTags_content;

  /// No description provided for @fixedTags_contentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt content, NAI syntax supported'**
  String get fixedTags_contentHint;

  /// No description provided for @fixedTags_syntaxHelp.
  ///
  /// In en, this message translates to:
  /// **'Supports NAI syntax for weight enhancement/reduction and tag alternation'**
  String get fixedTags_syntaxHelp;

  /// No description provided for @fixedTags_linkedFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Linked from library (two-way sync)'**
  String get fixedTags_linkedFromLibrary;

  /// No description provided for @fixedTags_scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get fixedTags_scope;

  /// No description provided for @fixedTags_positive.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get fixedTags_positive;

  /// No description provided for @fixedTags_negative.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content'**
  String get fixedTags_negative;

  /// No description provided for @fixedTags_resetWeight.
  ///
  /// In en, this message translates to:
  /// **'Reset to 1.0'**
  String get fixedTags_resetWeight;

  /// No description provided for @fixedTags_weightPreview.
  ///
  /// In en, this message translates to:
  /// **'Weight preview:'**
  String get fixedTags_weightPreview;

  /// No description provided for @fixedTags_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Fixed Tag'**
  String get fixedTags_deleteTitle;

  /// No description provided for @fixedTags_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String fixedTags_deleteConfirm(Object name);

  /// No description provided for @fixedTags_enabledCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled}/{total} enabled'**
  String fixedTags_enabledCount(Object enabled, Object total);

  /// No description provided for @fixedTags_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Also save to library'**
  String get fixedTags_saveToLibrary;

  /// No description provided for @fixedTags_saveToLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'For reuse in the tag library later'**
  String get fixedTags_saveToLibraryHint;

  /// No description provided for @fixedTags_saveToCategory.
  ///
  /// In en, this message translates to:
  /// **'Save to category'**
  String get fixedTags_saveToCategory;

  /// No description provided for @fixedTags_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get fixedTags_clearAll;

  /// No description provided for @fixedTags_clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Fixed Tags'**
  String get fixedTags_clearAllTitle;

  /// No description provided for @fixedTags_clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all {count} fixed tags? This action cannot be undone.'**
  String fixedTags_clearAllConfirm(Object count);

  /// No description provided for @fixedTags_clearedSuccess.
  ///
  /// In en, this message translates to:
  /// **'All fixed tags cleared'**
  String get fixedTags_clearedSuccess;

  /// No description provided for @fixedTags_sidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed Tags Sidebar'**
  String get fixedTags_sidebarTitle;

  /// No description provided for @fixedTags_switchGridView.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid View'**
  String get fixedTags_switchGridView;

  /// No description provided for @fixedTags_switchListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to List View'**
  String get fixedTags_switchListView;

  /// No description provided for @fixedTags_addPositive.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt Fixed Tag'**
  String get fixedTags_addPositive;

  /// No description provided for @fixedTags_addNegative.
  ///
  /// In en, this message translates to:
  /// **'Add Undesired Content Fixed Tag'**
  String get fixedTags_addNegative;

  /// No description provided for @fixedTags_addPositiveFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt from Library'**
  String get fixedTags_addPositiveFromLibrary;

  /// No description provided for @fixedTags_addNegativeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add Undesired Content from Library'**
  String get fixedTags_addNegativeFromLibrary;

  /// No description provided for @fixedTags_searchNameOrContent.
  ///
  /// In en, this message translates to:
  /// **'Search name or content'**
  String get fixedTags_searchNameOrContent;

  /// No description provided for @fixedTags_clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get fixedTags_clearSearch;

  /// No description provided for @fixedTags_enabledPositive.
  ///
  /// In en, this message translates to:
  /// **'Enabled Prompt'**
  String get fixedTags_enabledPositive;

  /// No description provided for @fixedTags_emptyEnabledPositive.
  ///
  /// In en, this message translates to:
  /// **'No enabled prompt fixed tags'**
  String get fixedTags_emptyEnabledPositive;

  /// No description provided for @fixedTags_noMatchingEnabled.
  ///
  /// In en, this message translates to:
  /// **'No matching enabled fixed tags'**
  String get fixedTags_noMatchingEnabled;

  /// No description provided for @fixedTags_negativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Fixed Tags'**
  String get fixedTags_negativeTitle;

  /// No description provided for @fixedTags_emptyNegative.
  ///
  /// In en, this message translates to:
  /// **'No Undesired Content fixed tags'**
  String get fixedTags_emptyNegative;

  /// No description provided for @fixedTags_noMatchingNegative.
  ///
  /// In en, this message translates to:
  /// **'No matching Undesired Content fixed tags'**
  String get fixedTags_noMatchingNegative;

  /// No description provided for @fixedTags_addedToSidebar.
  ///
  /// In en, this message translates to:
  /// **'Added to fixed tags sidebar'**
  String get fixedTags_addedToSidebar;

  /// No description provided for @fixedTags_unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get fixedTags_unknownCategory;

  /// No description provided for @fixedTags_uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get fixedTags_uncategorized;

  /// No description provided for @fixedTags_clickManageLongPressSidebar.
  ///
  /// In en, this message translates to:
  /// **'Click to manage, long-press to open sidebar'**
  String get fixedTags_clickManageLongPressSidebar;

  /// No description provided for @fixedTags_clickManageLongPressCompact.
  ///
  /// In en, this message translates to:
  /// **'Click to manage, long-press sidebar'**
  String get fixedTags_clickManageLongPressCompact;

  /// No description provided for @fixedTags_linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get fixedTags_linked;

  /// No description provided for @fixedTags_linkCount.
  ///
  /// In en, this message translates to:
  /// **'{count} linked'**
  String fixedTags_linkCount(Object count);

  /// No description provided for @fixedTags_expandNegative.
  ///
  /// In en, this message translates to:
  /// **'Expand Undesired Content'**
  String get fixedTags_expandNegative;

  /// No description provided for @fixedTags_collapseNegative.
  ///
  /// In en, this message translates to:
  /// **'Collapse Undesired Content'**
  String get fixedTags_collapseNegative;

  /// No description provided for @fixedTags_undoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo fixed tag operation'**
  String get fixedTags_undoTooltip;

  /// No description provided for @fixedTags_redoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo fixed tag operation'**
  String get fixedTags_redoTooltip;

  /// No description provided for @fixedTags_positiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt Fixed Tags'**
  String get fixedTags_positiveTitle;

  /// No description provided for @fixedTags_columnCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled}/{total}'**
  String fixedTags_columnCount(Object enabled, Object total);

  /// No description provided for @fixedTags_columnFilteredCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled}/{total} · showing {shown}'**
  String fixedTags_columnFilteredCount(
    Object enabled,
    Object total,
    Object shown,
  );

  /// No description provided for @fixedTags_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get fixedTags_new;

  /// No description provided for @fixedTags_newTarget.
  ///
  /// In en, this message translates to:
  /// **'New {target}'**
  String fixedTags_newTarget(Object target);

  /// No description provided for @fixedTags_library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get fixedTags_library;

  /// No description provided for @fixedTags_addFromLibraryToTarget.
  ///
  /// In en, this message translates to:
  /// **'Add from library to {target}'**
  String fixedTags_addFromLibraryToTarget(Object target);

  /// No description provided for @fixedTags_enableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable All'**
  String get fixedTags_enableAll;

  /// No description provided for @fixedTags_disableAll.
  ///
  /// In en, this message translates to:
  /// **'Disable All'**
  String get fixedTags_disableAll;

  /// No description provided for @fixedTags_searchTarget.
  ///
  /// In en, this message translates to:
  /// **'Search {target}...'**
  String fixedTags_searchTarget(Object target);

  /// No description provided for @fixedTags_noMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching fixed tags'**
  String get fixedTags_noMatching;

  /// No description provided for @fixedTags_emptyTarget.
  ///
  /// In en, this message translates to:
  /// **'No {target}'**
  String fixedTags_emptyTarget(Object target);

  /// No description provided for @fixedTags_dragToLink.
  ///
  /// In en, this message translates to:
  /// **'Drag to create link'**
  String get fixedTags_dragToLink;

  /// No description provided for @fixedTags_linkedToNames.
  ///
  /// In en, this message translates to:
  /// **'Linked: {names}'**
  String fixedTags_linkedToNames(Object names);

  /// No description provided for @fixedTags_linkInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the link icon from a prompt fixed tag to an Undesired Content fixed tag to create a link'**
  String get fixedTags_linkInstruction;

  /// No description provided for @fixedTags_manageLinks.
  ///
  /// In en, this message translates to:
  /// **'Manage Links'**
  String get fixedTags_manageLinks;

  /// No description provided for @fixedTags_removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link: {name}'**
  String fixedTags_removeLink(Object name);

  /// No description provided for @fixedTags_footerExpandedHint.
  ///
  /// In en, this message translates to:
  /// **'Create or add from the library at the top of each column'**
  String get fixedTags_footerExpandedHint;

  /// No description provided for @fixedTags_newPositive.
  ///
  /// In en, this message translates to:
  /// **'New Prompt'**
  String get fixedTags_newPositive;

  /// No description provided for @fixedTags_addPositiveFromLibraryShort.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt from Library'**
  String get fixedTags_addPositiveFromLibraryShort;

  /// No description provided for @fixedTags_libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Library is empty. Add entries first'**
  String get fixedTags_libraryEmpty;

  /// No description provided for @fixedTags_addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add from Library'**
  String get fixedTags_addFromLibrary;

  /// No description provided for @fixedTags_searchLibraryEntries.
  ///
  /// In en, this message translates to:
  /// **'Search library entries...'**
  String get fixedTags_searchLibraryEntries;

  /// No description provided for @fixedTags_noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get fixedTags_noMatchingResults;

  /// No description provided for @reversePrompt_title.
  ///
  /// In en, this message translates to:
  /// **'Reverse Prompt'**
  String get reversePrompt_title;

  /// No description provided for @reversePrompt_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reversePrompt_pending;

  /// No description provided for @reversePrompt_imageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s)'**
  String reversePrompt_imageCount(Object count);

  /// No description provided for @reversePrompt_llmReverse.
  ///
  /// In en, this message translates to:
  /// **'LLM Reverse'**
  String get reversePrompt_llmReverse;

  /// No description provided for @reversePrompt_characterReplace.
  ///
  /// In en, this message translates to:
  /// **'Character Replace'**
  String get reversePrompt_characterReplace;

  /// No description provided for @reversePrompt_finalResult.
  ///
  /// In en, this message translates to:
  /// **'Final Result'**
  String get reversePrompt_finalResult;

  /// No description provided for @reversePrompt_dropToAdd.
  ///
  /// In en, this message translates to:
  /// **'Release to add to reverse prompt'**
  String get reversePrompt_dropToAdd;

  /// No description provided for @reversePrompt_addOrDropImages.
  ///
  /// In en, this message translates to:
  /// **'Add images / drop images'**
  String get reversePrompt_addOrDropImages;

  /// No description provided for @reversePrompt_localTaggerModel.
  ///
  /// In en, this message translates to:
  /// **'Local tagger model'**
  String get reversePrompt_localTaggerModel;

  /// No description provided for @reversePrompt_localTaggerModelHint.
  ///
  /// In en, this message translates to:
  /// **'Configure model folder in Settings'**
  String get reversePrompt_localTaggerModelHint;

  /// No description provided for @reversePrompt_generalThreshold.
  ///
  /// In en, this message translates to:
  /// **'General tag threshold'**
  String get reversePrompt_generalThreshold;

  /// No description provided for @reversePrompt_characterThreshold.
  ///
  /// In en, this message translates to:
  /// **'Character tag threshold'**
  String get reversePrompt_characterThreshold;

  /// No description provided for @reversePrompt_taggerFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Only General / Character tags are output. Rating, Artist, Copyright, Meta, and other categories are filtered.'**
  String get reversePrompt_taggerFilterHint;

  /// No description provided for @reversePrompt_replacementEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No replacement target character selected. Choose a character from the tag library here; it will not be injected into the prompt.'**
  String get reversePrompt_replacementEmptyHint;

  /// No description provided for @reversePrompt_selectReplacementCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose replacement target character from library'**
  String get reversePrompt_selectReplacementCharacter;

  /// No description provided for @reversePrompt_selectReplacementTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Replacement Target Character'**
  String get reversePrompt_selectReplacementTargetTitle;

  /// No description provided for @reversePrompt_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get reversePrompt_change;

  /// No description provided for @reversePrompt_start.
  ///
  /// In en, this message translates to:
  /// **'Start Reverse Prompt'**
  String get reversePrompt_start;

  /// No description provided for @reversePrompt_sentToPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sent to prompt'**
  String get reversePrompt_sentToPrompt;

  /// No description provided for @reversePrompt_sendToPrompt.
  ///
  /// In en, this message translates to:
  /// **'Send to Prompt'**
  String get reversePrompt_sendToPrompt;

  /// No description provided for @reversePrompt_externalTarget.
  ///
  /// In en, this message translates to:
  /// **'multimodal LLM reverse prompt service'**
  String get reversePrompt_externalTarget;

  /// No description provided for @reversePrompt_dropUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The dropped source did not provide a readable image file or image URL'**
  String get reversePrompt_dropUnreadable;

  /// No description provided for @reversePrompt_needImageAndMethod.
  ///
  /// In en, this message translates to:
  /// **'Add an image and enable at least ONNX tagger or LLM reverse prompt'**
  String get reversePrompt_needImageAndMethod;

  /// No description provided for @reversePrompt_stagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing reverse prompt'**
  String get reversePrompt_stagePreparing;

  /// No description provided for @reversePrompt_stageOnnxTagger.
  ///
  /// In en, this message translates to:
  /// **'ONNX tagger reverse prompting'**
  String get reversePrompt_stageOnnxTagger;

  /// No description provided for @reversePrompt_stageLlmReverse.
  ///
  /// In en, this message translates to:
  /// **'LLM image reverse prompting'**
  String get reversePrompt_stageLlmReverse;

  /// No description provided for @reversePrompt_stageCharacterReplace.
  ///
  /// In en, this message translates to:
  /// **'Replacing character'**
  String get reversePrompt_stageCharacterReplace;

  /// No description provided for @reversePrompt_needReplacementCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid character from the reverse-prompt character library first'**
  String get reversePrompt_needReplacementCharacter;

  /// No description provided for @reversePrompt_needPromptForCharacterReplace.
  ///
  /// In en, this message translates to:
  /// **'Character replacement requires a reverse-prompt result first'**
  String get reversePrompt_needPromptForCharacterReplace;

  /// No description provided for @reversePrompt_noOnnxModel.
  ///
  /// In en, this message translates to:
  /// **'No ONNX tagger model found. Configure the model folder in Settings first'**
  String get reversePrompt_noOnnxModel;

  /// No description provided for @promptAssistant_translateProcessing.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get promptAssistant_translateProcessing;

  /// No description provided for @promptAssistant_optimizeProcessing.
  ///
  /// In en, this message translates to:
  /// **'Optimizing'**
  String get promptAssistant_optimizeProcessing;

  /// No description provided for @promptAssistant_characterReplaceProcessing.
  ///
  /// In en, this message translates to:
  /// **'Replacing character'**
  String get promptAssistant_characterReplaceProcessing;

  /// No description provided for @promptAssistant_customProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing custom request'**
  String get promptAssistant_customProcessing;

  /// No description provided for @promptAssistant_imageInputDisabled.
  ///
  /// In en, this message translates to:
  /// **'The current custom-task provider does not have image input enabled'**
  String get promptAssistant_imageInputDisabled;

  /// No description provided for @promptAssistant_needCharacter.
  ///
  /// In en, this message translates to:
  /// **'Add a valid character in the reverse-prompt character library first'**
  String get promptAssistant_needCharacter;

  /// No description provided for @promptAssistant_assistantSettings.
  ///
  /// In en, this message translates to:
  /// **'Assistant Settings'**
  String get promptAssistant_assistantSettings;

  /// No description provided for @promptAssistant_serviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Service Settings'**
  String get promptAssistant_serviceSettings;

  /// No description provided for @promptAssistant_ruleSettings.
  ///
  /// In en, this message translates to:
  /// **'Rule Settings'**
  String get promptAssistant_ruleSettings;

  /// No description provided for @promptAssistant_cancelCurrentTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel Current Task'**
  String get promptAssistant_cancelCurrentTask;

  /// No description provided for @promptAssistant_collapseAssistant.
  ///
  /// In en, this message translates to:
  /// **'Collapse Assistant'**
  String get promptAssistant_collapseAssistant;

  /// No description provided for @promptAssistant_expandAssistant.
  ///
  /// In en, this message translates to:
  /// **'Expand Assistant'**
  String get promptAssistant_expandAssistant;

  /// No description provided for @promptAssistant_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get promptAssistant_history;

  /// No description provided for @promptAssistant_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get promptAssistant_undo;

  /// No description provided for @promptAssistant_redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get promptAssistant_redo;

  /// No description provided for @promptAssistant_translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get promptAssistant_translate;

  /// No description provided for @promptAssistant_optimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get promptAssistant_optimize;

  /// No description provided for @promptAssistant_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get promptAssistant_custom;

  /// No description provided for @promptAssistant_characterReplace.
  ///
  /// In en, this message translates to:
  /// **'Character Replace'**
  String get promptAssistant_characterReplace;

  /// No description provided for @promptAssistant_cancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel Task'**
  String get promptAssistant_cancelTask;

  /// No description provided for @promptAssistant_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get promptAssistant_menu;

  /// No description provided for @promptAssistant_customDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Prompt Assistant'**
  String get promptAssistant_customDialogTitle;

  /// No description provided for @promptAssistant_currentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Current Prompt'**
  String get promptAssistant_currentPrompt;

  /// No description provided for @promptAssistant_currentPromptEmpty.
  ///
  /// In en, this message translates to:
  /// **'(current prompt is empty)'**
  String get promptAssistant_currentPromptEmpty;

  /// No description provided for @promptAssistant_customRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Your modification request'**
  String get promptAssistant_customRequestLabel;

  /// No description provided for @promptAssistant_customRequestHint.
  ///
  /// In en, this message translates to:
  /// **'For example: make it more ominous, add a rainy night street background, make the action more dynamic, return only the final prompt'**
  String get promptAssistant_customRequestHint;

  /// No description provided for @promptAssistant_addReferenceImage.
  ///
  /// In en, this message translates to:
  /// **'Add Reference Image'**
  String get promptAssistant_addReferenceImage;

  /// No description provided for @promptAssistant_execute.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get promptAssistant_execute;

  /// No description provided for @promptAssistant_maxReferenceImages.
  ///
  /// In en, this message translates to:
  /// **'Add up to {count} reference images'**
  String promptAssistant_maxReferenceImages(Object count);

  /// No description provided for @promptAssistant_unsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format: {fileName}'**
  String promptAssistant_unsupportedImageFormat(Object fileName);

  /// No description provided for @promptAssistant_needCustomRequestOrImage.
  ///
  /// In en, this message translates to:
  /// **'Enter a custom request or add a reference image'**
  String get promptAssistant_needCustomRequestOrImage;

  /// No description provided for @promptAssistant_taskOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get promptAssistant_taskOptimize;

  /// No description provided for @promptAssistant_taskTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get promptAssistant_taskTranslate;

  /// No description provided for @promptAssistant_taskReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse Prompt'**
  String get promptAssistant_taskReverse;

  /// No description provided for @promptAssistant_taskCharacterReplace.
  ///
  /// In en, this message translates to:
  /// **'Character Replace'**
  String get promptAssistant_taskCharacterReplace;

  /// No description provided for @promptAssistant_taskCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get promptAssistant_taskCustom;

  /// No description provided for @promptAssistant_settingsInputSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant switch in the bottom-right of the prompt input'**
  String get promptAssistant_settingsInputSwitchSubtitle;

  /// No description provided for @promptAssistant_desktopOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop Overlay Interaction'**
  String get promptAssistant_desktopOverlayTitle;

  /// No description provided for @promptAssistant_desktopOverlaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable hover, right-click, and shortcut behavior'**
  String get promptAssistant_desktopOverlaySubtitle;

  /// No description provided for @promptAssistant_taskRouting.
  ///
  /// In en, this message translates to:
  /// **'Task Routing'**
  String get promptAssistant_taskRouting;

  /// No description provided for @promptAssistant_taskRoutingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bind optimize, translate, reverse prompt, and character replacement to different providers and models'**
  String get promptAssistant_taskRoutingSubtitle;

  /// No description provided for @promptAssistant_taskRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} Task'**
  String promptAssistant_taskRouteTitle(Object title);

  /// No description provided for @promptAssistant_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get promptAssistant_provider;

  /// No description provided for @promptAssistant_model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get promptAssistant_model;

  /// No description provided for @promptAssistant_noModelsPullFirst.
  ///
  /// In en, this message translates to:
  /// **'No models yet. Pull the model list first'**
  String get promptAssistant_noModelsPullFirst;

  /// No description provided for @promptAssistant_providerManagement.
  ///
  /// In en, this message translates to:
  /// **'Provider Management'**
  String get promptAssistant_providerManagement;

  /// No description provided for @promptAssistant_providerManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supports OpenAI Chat / Responses, Anthropic, Gemini, DeepSeek, LM Studio, Ollama, Pollinations, and custom compatible endpoints'**
  String get promptAssistant_providerManagementSubtitle;

  /// No description provided for @promptAssistant_apiKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'API Key: configured'**
  String get promptAssistant_apiKeyConfigured;

  /// No description provided for @promptAssistant_apiKeyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'API Key: not configured'**
  String get promptAssistant_apiKeyNotConfigured;

  /// No description provided for @promptAssistant_supportsImageInput.
  ///
  /// In en, this message translates to:
  /// **'Supports image input'**
  String get promptAssistant_supportsImageInput;

  /// No description provided for @promptAssistant_textOnly.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get promptAssistant_textOnly;

  /// No description provided for @promptAssistant_connectionConfig.
  ///
  /// In en, this message translates to:
  /// **'Connection Config'**
  String get promptAssistant_connectionConfig;

  /// No description provided for @promptAssistant_pullModelList.
  ///
  /// In en, this message translates to:
  /// **'Pull model list'**
  String get promptAssistant_pullModelList;

  /// No description provided for @promptAssistant_editProvider.
  ///
  /// In en, this message translates to:
  /// **'Edit provider'**
  String get promptAssistant_editProvider;

  /// No description provided for @promptAssistant_deleteProvider.
  ///
  /// In en, this message translates to:
  /// **'Delete provider'**
  String get promptAssistant_deleteProvider;

  /// No description provided for @promptAssistant_pullingModels.
  ///
  /// In en, this message translates to:
  /// **'Pulling model list...'**
  String get promptAssistant_pullingModels;

  /// No description provided for @promptAssistant_emptyModelList.
  ///
  /// In en, this message translates to:
  /// **'Provider returned an empty model list'**
  String get promptAssistant_emptyModelList;

  /// No description provided for @promptAssistant_modelsSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} models'**
  String promptAssistant_modelsSynced(Object count);

  /// No description provided for @promptAssistant_pullModelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pull models: {error}'**
  String promptAssistant_pullModelsFailed(Object error);

  /// No description provided for @promptAssistant_ruleTemplates.
  ///
  /// In en, this message translates to:
  /// **'Rule Templates'**
  String get promptAssistant_ruleTemplates;

  /// No description provided for @promptAssistant_ruleTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System prompts are assembled as rules + user input + task parameters'**
  String get promptAssistant_ruleTemplatesSubtitle;

  /// No description provided for @promptAssistant_addRule.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get promptAssistant_addRule;

  /// No description provided for @promptAssistant_addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add Provider'**
  String get promptAssistant_addProvider;

  /// No description provided for @promptAssistant_editProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Provider'**
  String get promptAssistant_editProviderTitle;

  /// No description provided for @promptAssistant_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get promptAssistant_name;

  /// No description provided for @promptAssistant_protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get promptAssistant_protocol;

  /// No description provided for @promptAssistant_allowImageInput.
  ///
  /// In en, this message translates to:
  /// **'Allow image input'**
  String get promptAssistant_allowImageInput;

  /// No description provided for @promptAssistant_allowImageInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable only when the model and provider actually support vision input'**
  String get promptAssistant_allowImageInputSubtitle;

  /// No description provided for @promptAssistant_apiKeyLeaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'API Key (leave empty to keep unchanged)'**
  String get promptAssistant_apiKeyLeaveEmpty;

  /// No description provided for @promptAssistant_connectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Connection Config'**
  String promptAssistant_connectionTitle(Object name);

  /// No description provided for @promptAssistant_baseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Example: https://api.openai.com/v1'**
  String get promptAssistant_baseUrlHint;

  /// No description provided for @promptAssistant_clearCurrentApiKey.
  ///
  /// In en, this message translates to:
  /// **'Clear current API Key'**
  String get promptAssistant_clearCurrentApiKey;

  /// No description provided for @promptAssistant_protocolSupportsImagePayload.
  ///
  /// In en, this message translates to:
  /// **'The current protocol supports image payloads; the model itself must still support vision input'**
  String get promptAssistant_protocolSupportsImagePayload;

  /// No description provided for @promptAssistant_protocolTextOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'The current protocol is text-only by default; enabling this may still be rejected by the server'**
  String get promptAssistant_protocolTextOnlyWarning;

  /// No description provided for @promptAssistant_addRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get promptAssistant_addRuleTitle;

  /// No description provided for @promptAssistant_editRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get promptAssistant_editRuleTitle;

  /// No description provided for @promptAssistant_taskType.
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get promptAssistant_taskType;

  /// No description provided for @promptAssistant_ruleContent.
  ///
  /// In en, this message translates to:
  /// **'Rule Content'**
  String get promptAssistant_ruleContent;

  /// No description provided for @promptAssistant_newRule.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get promptAssistant_newRule;

  /// No description provided for @autocomplete_resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String autocomplete_resultsCount(Object count);

  /// No description provided for @autocomplete_keyNavigate.
  ///
  /// In en, this message translates to:
  /// **'↑↓/Scroll'**
  String get autocomplete_keyNavigate;

  /// No description provided for @autocomplete_actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get autocomplete_actionSelect;

  /// No description provided for @autocomplete_actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get autocomplete_actionConfirm;

  /// No description provided for @autocomplete_actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get autocomplete_actionClose;

  /// No description provided for @autocomplete_categoryRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get autocomplete_categoryRecommended;

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

  /// No description provided for @promptToken_fixedTags.
  ///
  /// In en, this message translates to:
  /// **'Fixed Tags'**
  String get promptToken_fixedTags;

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

  /// No description provided for @promptToken_negativeFixedTags.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Fixed Tags'**
  String get promptToken_negativeFixedTags;

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

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @tagLibrary_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tagLibrary_categories;

  /// No description provided for @tagLibrary_newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get tagLibrary_newCategory;

  /// No description provided for @tagLibrary_addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get tagLibrary_addEntry;

  /// No description provided for @tagLibrary_editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get tagLibrary_editEntry;

  /// No description provided for @tagLibrary_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries...'**
  String get tagLibrary_searchHint;

  /// No description provided for @tagLibrary_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get tagLibrary_import;

  /// No description provided for @tagLibrary_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get tagLibrary_export;

  /// No description provided for @tagLibrary_sortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Sort'**
  String get tagLibrary_sortCustom;

  /// No description provided for @tagLibrary_sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagLibrary_sortName;

  /// No description provided for @tagLibrary_sortUseCount.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get tagLibrary_sortUseCount;

  /// No description provided for @tagLibrary_sortUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get tagLibrary_sortUpdatedAt;

  /// No description provided for @tagLibrary_transferCategory.
  ///
  /// In en, this message translates to:
  /// **'Move Category'**
  String get tagLibrary_transferCategory;

  /// No description provided for @tagLibrary_copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy Content'**
  String get tagLibrary_copyContent;

  /// No description provided for @tagLibrary_moveToCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to Category'**
  String get tagLibrary_moveToCategoryTitle;

  /// No description provided for @tagLibrary_selectTargetCategory.
  ///
  /// In en, this message translates to:
  /// **'Select target category:'**
  String get tagLibrary_selectTargetCategory;

  /// No description provided for @tagLibrary_includeThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Include thumbnails'**
  String get tagLibrary_includeThumbnails;

  /// No description provided for @tagLibrary_includeThumbnailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Increases file size'**
  String get tagLibrary_includeThumbnailsSubtitle;

  /// No description provided for @tagLibrary_selectedExportCount.
  ///
  /// In en, this message translates to:
  /// **'Export ({count} items)'**
  String tagLibrary_selectedExportCount(Object count);

  /// No description provided for @tagLibrary_selectedImportCount.
  ///
  /// In en, this message translates to:
  /// **'Import ({count} items)'**
  String tagLibrary_selectedImportCount(Object count);

  /// No description provided for @tagLibrary_entriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get tagLibrary_entriesLabel;

  /// No description provided for @tagLibrary_categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tagLibrary_categoriesLabel;

  /// No description provided for @tagLibrary_selectExportContent.
  ///
  /// In en, this message translates to:
  /// **'Select content to export'**
  String get tagLibrary_selectExportContent;

  /// No description provided for @tagLibrary_selectImportContent.
  ///
  /// In en, this message translates to:
  /// **'Select content to import'**
  String get tagLibrary_selectImportContent;

  /// No description provided for @tagLibrary_selectSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Select save location'**
  String get tagLibrary_selectSaveLocation;

  /// No description provided for @tagLibrary_preparingExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get tagLibrary_preparingExport;

  /// No description provided for @tagLibrary_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get tagLibrary_exportSuccess;

  /// No description provided for @tagLibrary_exportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String tagLibrary_exportFailedWithError(Object error);

  /// No description provided for @tagLibrary_selectZipFile.
  ///
  /// In en, this message translates to:
  /// **'Click to select ZIP file'**
  String get tagLibrary_selectZipFile;

  /// No description provided for @tagLibrary_zipFileHint.
  ///
  /// In en, this message translates to:
  /// **'Supports library files exported from this app'**
  String get tagLibrary_zipFileHint;

  /// No description provided for @tagLibrary_reselect.
  ///
  /// In en, this message translates to:
  /// **'Select Again'**
  String get tagLibrary_reselect;

  /// No description provided for @tagLibrary_fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get tagLibrary_fileInfo;

  /// No description provided for @tagLibrary_entryCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get tagLibrary_entryCountLabel;

  /// No description provided for @tagLibrary_categoryCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tagLibrary_categoryCountLabel;

  /// No description provided for @tagLibrary_exportDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Export Date'**
  String get tagLibrary_exportDateLabel;

  /// No description provided for @tagLibrary_importConflictsHint.
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts found. Click a conflicted item below to choose how to handle it.'**
  String tagLibrary_importConflictsHint(Object count);

  /// No description provided for @tagLibrary_categoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Categories ({count})'**
  String tagLibrary_categoriesSection(Object count);

  /// No description provided for @tagLibrary_entriesSection.
  ///
  /// In en, this message translates to:
  /// **'Entries ({count})'**
  String tagLibrary_entriesSection(Object count);

  /// No description provided for @tagLibrary_conflictResolutionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose conflict handling'**
  String get tagLibrary_conflictResolutionTooltip;

  /// No description provided for @tagLibrary_conflictSkip.
  ///
  /// In en, this message translates to:
  /// **'Conflict - will skip'**
  String get tagLibrary_conflictSkip;

  /// No description provided for @tagLibrary_conflictRename.
  ///
  /// In en, this message translates to:
  /// **'Conflict - will import with renamed name'**
  String get tagLibrary_conflictRename;

  /// No description provided for @tagLibrary_conflictOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Conflict - will replace existing'**
  String get tagLibrary_conflictOverwrite;

  /// No description provided for @tagLibrary_parseFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to parse file: {error}'**
  String tagLibrary_parseFileFailed(Object error);

  /// No description provided for @tagLibrary_preparingImport.
  ///
  /// In en, this message translates to:
  /// **'Preparing import...'**
  String get tagLibrary_preparingImport;

  /// No description provided for @tagLibrary_importCompleted.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get tagLibrary_importCompleted;

  /// No description provided for @tagLibrary_importSuccessSummary.
  ///
  /// In en, this message translates to:
  /// **'Import successful: {summary}'**
  String tagLibrary_importSuccessSummary(Object summary);

  /// No description provided for @tagLibrary_importFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String tagLibrary_importFailedWithError(Object error);

  /// No description provided for @tagLibrary_importedEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String tagLibrary_importedEntriesCount(Object count);

  /// No description provided for @tagLibrary_importedCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String tagLibrary_importedCategoriesCount(Object count);

  /// No description provided for @tagLibrary_renamedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} renamed'**
  String tagLibrary_renamedCount(Object count);

  /// No description provided for @tagLibrary_overwrittenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} replaced'**
  String tagLibrary_overwrittenCount(Object count);

  /// No description provided for @tagLibrary_skippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String tagLibrary_skippedCount(Object count);

  /// No description provided for @tagLibrary_dragToCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to the category panel to file'**
  String get tagLibrary_dragToCategoryHint;

  /// No description provided for @tagLibrary_unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get tagLibrary_unknownCategory;

  /// No description provided for @tagLibrary_selectEntryToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Select Entry to Update'**
  String get tagLibrary_selectEntryToUpdate;

  /// No description provided for @tagLibrary_updatePreview.
  ///
  /// In en, this message translates to:
  /// **'Update Preview'**
  String get tagLibrary_updatePreview;

  /// No description provided for @tagLibrary_replaceThumbnailHint.
  ///
  /// In en, this message translates to:
  /// **'Will replace existing thumbnail'**
  String get tagLibrary_replaceThumbnailHint;

  /// No description provided for @tagLibrary_sentEntriesToMainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sent {count} entries to main prompt'**
  String tagLibrary_sentEntriesToMainPrompt(Object count);

  /// No description provided for @tagLibrary_confirmDeleteSelectedEntries.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected entries? This action cannot be undone.'**
  String tagLibrary_confirmDeleteSelectedEntries(Object count);

  /// No description provided for @tagLibrary_deletedEntries.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} entries'**
  String tagLibrary_deletedEntries(Object count);

  /// No description provided for @tagLibrary_movedEntries.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} entries'**
  String tagLibrary_movedEntries(Object count);

  /// No description provided for @tagLibrary_favoritedEntries.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count} entries'**
  String tagLibrary_favoritedEntries(Object count);

  /// No description provided for @tagLibrary_unfavoritedEntries.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited {count} entries'**
  String tagLibrary_unfavoritedEntries(Object count);

  /// No description provided for @tagLibrary_copiedEntriesContent.
  ///
  /// In en, this message translates to:
  /// **'Copied content from {count} entries'**
  String tagLibrary_copiedEntriesContent(Object count);

  /// No description provided for @tagLibrary_droppedImage.
  ///
  /// In en, this message translates to:
  /// **'Dropped Image'**
  String get tagLibrary_droppedImage;

  /// No description provided for @tagLibrary_createEntryFromImage.
  ///
  /// In en, this message translates to:
  /// **'Create New Entry'**
  String get tagLibrary_createEntryFromImage;

  /// No description provided for @tagLibrary_promptExtracted.
  ///
  /// In en, this message translates to:
  /// **'Prompt extracted: \"{prompt}\"'**
  String tagLibrary_promptExtracted(Object prompt);

  /// No description provided for @tagLibrary_createEntryFromImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new entry from this image'**
  String get tagLibrary_createEntryFromImageSubtitle;

  /// No description provided for @tagLibrary_updateExistingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Update Existing Entry Thumbnail'**
  String get tagLibrary_updateExistingThumbnail;

  /// No description provided for @tagLibrary_updateExistingThumbnailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an entry and replace its thumbnail'**
  String get tagLibrary_updateExistingThumbnailSubtitle;

  /// No description provided for @tagLibrary_allEntries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tagLibrary_allEntries;

  /// No description provided for @tagLibrary_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tagLibrary_favorites;

  /// No description provided for @tagLibrary_addSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory'**
  String get tagLibrary_addSubCategory;

  /// No description provided for @tagLibrary_moveToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to Root'**
  String get tagLibrary_moveToRoot;

  /// No description provided for @tagLibrary_categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get tagLibrary_categoryNameHint;

  /// No description provided for @tagLibrary_deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get tagLibrary_deleteCategoryTitle;

  /// No description provided for @tagLibrary_deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete category \"{name}\"? {count} entries will be moved to root.'**
  String tagLibrary_deleteCategoryConfirm(Object name, Object count);

  /// No description provided for @tagLibrary_deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get tagLibrary_deleteEntryTitle;

  /// No description provided for @tagLibrary_deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete entry \"{name}\"?'**
  String tagLibrary_deleteEntryConfirm(Object name);

  /// No description provided for @tagLibrary_noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching entries found'**
  String get tagLibrary_noSearchResults;

  /// No description provided for @tagLibrary_tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tagLibrary_tryDifferentSearch;

  /// No description provided for @tagLibrary_categoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'This category is empty'**
  String get tagLibrary_categoryEmpty;

  /// No description provided for @tagLibrary_empty.
  ///
  /// In en, this message translates to:
  /// **'Library is empty'**
  String get tagLibrary_empty;

  /// No description provided for @tagLibrary_addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Click the button above to add your first entry'**
  String get tagLibrary_addFirstEntry;

  /// No description provided for @tagLibraryPicker_title.
  ///
  /// In en, this message translates to:
  /// **'Select Entry'**
  String get tagLibraryPicker_title;

  /// No description provided for @tagLibraryPicker_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries...'**
  String get tagLibraryPicker_searchHint;

  /// No description provided for @tagLibraryPicker_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get tagLibraryPicker_allCategories;

  /// No description provided for @tagLibrary_addedToFixed.
  ///
  /// In en, this message translates to:
  /// **'Added to Fixed Tags'**
  String get tagLibrary_addedToFixed;

  /// No description provided for @tagLibrary_entryMoved.
  ///
  /// In en, this message translates to:
  /// **'Entry moved to target category'**
  String get tagLibrary_entryMoved;

  /// No description provided for @tagLibrary_useCount.
  ///
  /// In en, this message translates to:
  /// **'Used {count} times'**
  String tagLibrary_useCount(Object count);

  /// No description provided for @tagLibrary_addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get tagLibrary_addFavorite;

  /// No description provided for @tagLibrary_thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get tagLibrary_thumbnail;

  /// No description provided for @tagLibrary_selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get tagLibrary_selectImage;

  /// No description provided for @tagLibrary_thumbnailHint.
  ///
  /// In en, this message translates to:
  /// **'Supports PNG, JPG, WEBP, GIF, BMP, TIFF, and more'**
  String get tagLibrary_thumbnailHint;

  /// No description provided for @tagLibrary_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagLibrary_name;

  /// No description provided for @tagLibrary_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter entry name'**
  String get tagLibrary_nameHint;

  /// No description provided for @tagLibrary_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tagLibrary_category;

  /// No description provided for @tagLibrary_rootCategory.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get tagLibrary_rootCategory;

  /// No description provided for @tagLibrary_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagLibrary_tags;

  /// No description provided for @tagLibrary_tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tags, separated by commas'**
  String get tagLibrary_tagsHint;

  /// No description provided for @tagLibrary_tagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Tags are used for filtering and searching'**
  String get tagLibrary_tagsHelper;

  /// No description provided for @tagLibrary_content.
  ///
  /// In en, this message translates to:
  /// **'Prompt Content'**
  String get tagLibrary_content;

  /// No description provided for @tagLibrary_contentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter prompt content, supports autocomplete'**
  String get tagLibrary_contentHint;

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

  /// No description provided for @tagLibrary_categoryNameExists.
  ///
  /// In en, this message translates to:
  /// **'Category name already exists'**
  String get tagLibrary_categoryNameExists;

  /// No description provided for @tagLibrary_addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get tagLibrary_addToLibrary;

  /// No description provided for @tagLibrary_saveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get tagLibrary_saveToLibrary;

  /// No description provided for @tagLibrary_entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to library'**
  String get tagLibrary_entrySaved;

  /// No description provided for @tagLibrary_entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get tagLibrary_entryUpdated;

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

  /// No description provided for @tagLibrary_confirmAdd.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get tagLibrary_confirmAdd;

  /// No description provided for @tagLibrary_entryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagLibrary_entryName;

  /// No description provided for @tagLibrary_entryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter entry name'**
  String get tagLibrary_entryNameHint;

  /// No description provided for @tagLibrary_selectNewImage.
  ///
  /// In en, this message translates to:
  /// **'Select New Image'**
  String get tagLibrary_selectNewImage;

  /// No description provided for @tagLibrary_adjustDisplayRange.
  ///
  /// In en, this message translates to:
  /// **'Adjust Display Range'**
  String get tagLibrary_adjustDisplayRange;

  /// No description provided for @tagLibrary_adjustThumbnailTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust Thumbnail Display Range'**
  String get tagLibrary_adjustThumbnailTitle;

  /// No description provided for @tagLibrary_dragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move, scroll or pinch to zoom'**
  String get tagLibrary_dragToMove;

  /// No description provided for @settings_enablePromptWeightScroll.
  ///
  /// In en, this message translates to:
  /// **'Adjust prompt weight with mouse wheel'**
  String get settings_enablePromptWeightScroll;

  /// No description provided for @settings_enablePromptWeightScrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When prompt text is selected, use the wheel only to adjust its weight and suppress other scroll actions.'**
  String get settings_enablePromptWeightScrollSubtitle;

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
  /// **'Play sound when generation completes'**
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

  /// No description provided for @sendToHome_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to Home'**
  String get sendToHome_dialogTitle;

  /// No description provided for @sendToHome_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendToHome_send;

  /// No description provided for @sendToHome_mainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Send to Main Prompt'**
  String get sendToHome_mainPrompt;

  /// No description provided for @sendToHome_mainPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill into the main prompt input field'**
  String get sendToHome_mainPromptSubtitle;

  /// No description provided for @sendToHome_mainPromptPipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send the full content to the main prompt (including pipes)'**
  String get sendToHome_mainPromptPipeSubtitle;

  /// No description provided for @sendToHome_smartDecompose.
  ///
  /// In en, this message translates to:
  /// **'Smart Decompose'**
  String get sendToHome_smartDecompose;

  /// No description provided for @sendToHome_smartDecomposeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Main prompt + {count} characters'**
  String sendToHome_smartDecomposeSubtitle(Object count);

  /// No description provided for @sendToHome_replaceCharacter.
  ///
  /// In en, this message translates to:
  /// **'Replace Character Prompt'**
  String get sendToHome_replaceCharacter;

  /// No description provided for @sendToHome_replaceCharacterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear existing characters and add as new'**
  String get sendToHome_replaceCharacterSubtitle;

  /// No description provided for @sendToHome_appendCharacter.
  ///
  /// In en, this message translates to:
  /// **'Append Character Prompt'**
  String get sendToHome_appendCharacter;

  /// No description provided for @sendToHome_appendCharacterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep existing characters and append new'**
  String get sendToHome_appendCharacterSubtitle;

  /// No description provided for @sendToHome_fixedTags.
  ///
  /// In en, this message translates to:
  /// **'Send to Fixed Tags'**
  String get sendToHome_fixedTags;

  /// No description provided for @sendToHome_fixedTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Append to the fixed tag list'**
  String get sendToHome_fixedTagsSubtitle;

  /// No description provided for @sendToHome_sendAsAlias.
  ///
  /// In en, this message translates to:
  /// **'Send as Alias'**
  String get sendToHome_sendAsAlias;

  /// No description provided for @sendToHome_sendAsAliasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wrap as <{name}> when sending to home'**
  String sendToHome_sendAsAliasSubtitle(Object name);

  /// No description provided for @sendToHome_preview.
  ///
  /// In en, this message translates to:
  /// **'Send Preview'**
  String get sendToHome_preview;

  /// No description provided for @sendToHome_characterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Character Prompt'**
  String get sendToHome_characterPrompt;

  /// No description provided for @sendToHome_characterPromptCount.
  ///
  /// In en, this message translates to:
  /// **'Character Prompt ({count})'**
  String sendToHome_characterPromptCount(Object count);

  /// No description provided for @sendToHome_characterIndex.
  ///
  /// In en, this message translates to:
  /// **'Character {index}'**
  String sendToHome_characterIndex(Object index);

  /// No description provided for @sendToHome_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sendToHome_recommended;

  /// No description provided for @sendToHome_successMainPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sent to main prompt'**
  String get sendToHome_successMainPrompt;

  /// No description provided for @sendToHome_successReplaceCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character prompt replaced'**
  String get sendToHome_successReplaceCharacter;

  /// No description provided for @sendToHome_successAppendCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character prompt appended'**
  String get sendToHome_successAppendCharacter;

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

  /// No description provided for @metadataImport_fixedTags.
  ///
  /// In en, this message translates to:
  /// **'Fixed Tags'**
  String get metadataImport_fixedTags;

  /// No description provided for @metadataImport_fixedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix: {text}'**
  String metadataImport_fixedPrefix(Object text);

  /// No description provided for @metadataImport_fixedSuffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix: {text}'**
  String metadataImport_fixedSuffix(Object text);

  /// No description provided for @metadataImport_negativeFixedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Prefix: {text}'**
  String metadataImport_negativeFixedPrefix(Object text);

  /// No description provided for @metadataImport_negativeFixedSuffix.
  ///
  /// In en, this message translates to:
  /// **'Undesired Content Suffix: {text}'**
  String metadataImport_negativeFixedSuffix(Object text);

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
  /// **'CFG Scale'**
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
  /// **'CFG Rescale'**
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

  /// No description provided for @shortcut_context_tag_library.
  ///
  /// In en, this message translates to:
  /// **'Tag Library'**
  String get shortcut_context_tag_library;

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
  /// **'Tag Library'**
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
  /// **'Open Tag Library'**
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
  /// **'Previous Page'**
  String get shortcut_action_previous_page;

  /// No description provided for @shortcut_action_next_page.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
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
  /// **'Enter Selection Mode'**
  String get shortcut_action_enter_selection_mode;

  /// No description provided for @shortcut_action_open_filter_panel.
  ///
  /// In en, this message translates to:
  /// **'Open Filter Panel'**
  String get shortcut_action_open_filter_panel;

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

  /// No description provided for @shortcut_action_select_all_tags.
  ///
  /// In en, this message translates to:
  /// **'Select All Tags'**
  String get shortcut_action_select_all_tags;

  /// No description provided for @shortcut_action_deselect_all_tags.
  ///
  /// In en, this message translates to:
  /// **'Deselect All Tags'**
  String get shortcut_action_deselect_all_tags;

  /// No description provided for @shortcut_action_new_category.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get shortcut_action_new_category;

  /// No description provided for @shortcut_action_new_tag.
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get shortcut_action_new_tag;

  /// No description provided for @shortcut_action_search_tags.
  ///
  /// In en, this message translates to:
  /// **'Search Tags'**
  String get shortcut_action_search_tags;

  /// No description provided for @shortcut_action_batch_delete_tags.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete Tags'**
  String get shortcut_action_batch_delete_tags;

  /// No description provided for @shortcut_action_batch_copy_tags.
  ///
  /// In en, this message translates to:
  /// **'Batch Copy Tags'**
  String get shortcut_action_batch_copy_tags;

  /// No description provided for @shortcut_action_send_to_home.
  ///
  /// In en, this message translates to:
  /// **'Send to Home'**
  String get shortcut_action_send_to_home;

  /// No description provided for @shortcut_action_exit_selection_mode.
  ///
  /// In en, this message translates to:
  /// **'Exit Selection Mode'**
  String get shortcut_action_exit_selection_mode;

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

  /// No description provided for @shortcut_help_tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: press F1 or ? anytime to open this help dialog'**
  String get shortcut_help_tip;

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

  /// No description provided for @drop_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use this image?'**
  String get drop_dialogTitle;

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

  /// No description provided for @drop_reversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Reverse Prompt'**
  String get drop_reversePrompt;

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

  /// No description provided for @drop_addedToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Added to Reverse Prompt'**
  String get drop_addedToReversePrompt;

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

  /// No description provided for @drop_extractMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extract Metadata'**
  String get drop_extractMetadata;

  /// No description provided for @drop_extractMetadataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read Prompt, Seed and other parameters from image'**
  String get drop_extractMetadataSubtitle;

  /// No description provided for @drop_vibeDetected.
  ///
  /// In en, this message translates to:
  /// **'Pre-encoded Vibe detected (saves 2 Anlas)'**
  String get drop_vibeDetected;

  /// No description provided for @drop_vibeStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength: {value}%'**
  String drop_vibeStrength(Object value);

  /// No description provided for @drop_vibeInfoExtracted.
  ///
  /// In en, this message translates to:
  /// **'Information Extracted: {value}%'**
  String drop_vibeInfoExtracted(Object value);

  /// No description provided for @drop_reuseVibe.
  ///
  /// In en, this message translates to:
  /// **'Reuse Vibe'**
  String get drop_reuseVibe;

  /// No description provided for @drop_reuseVibeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use pre-encoded data directly (free)'**
  String get drop_reuseVibeSubtitle;

  /// No description provided for @drop_useAsRawImage.
  ///
  /// In en, this message translates to:
  /// **'Use as Raw Image'**
  String get drop_useAsRawImage;

  /// No description provided for @drop_useAsRawImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-encode (costs 2 Anlas)'**
  String get drop_useAsRawImageSubtitle;

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

  /// No description provided for @vibeLibrary_hideCategoryPanel.
  ///
  /// In en, this message translates to:
  /// **'Hide category panel'**
  String get vibeLibrary_hideCategoryPanel;

  /// No description provided for @vibeLibrary_showCategoryPanel.
  ///
  /// In en, this message translates to:
  /// **'Show category panel'**
  String get vibeLibrary_showCategoryPanel;

  /// No description provided for @vibeLibrary_enterSelectionMode.
  ///
  /// In en, this message translates to:
  /// **'Enter selection mode'**
  String get vibeLibrary_enterSelectionMode;

  /// No description provided for @vibeLibrary_importTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import Vibe files or PNG/JPG/JPEG/WEBP images (right-click for more options)'**
  String get vibeLibrary_importTooltip;

  /// No description provided for @vibeLibrary_exportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export Vibe to file'**
  String get vibeLibrary_exportTooltip;

  /// No description provided for @vibeLibrary_openFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Vibe library folder'**
  String get vibeLibrary_openFolderTooltip;

  /// No description provided for @vibeLibrary_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get vibeLibrary_refresh;

  /// No description provided for @vibeLibrary_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get vibeLibrary_loading;

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

  /// No description provided for @vibeBulk_titleDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Vibes'**
  String get vibeBulk_titleDelete;

  /// No description provided for @vibeBulk_titleMove.
  ///
  /// In en, this message translates to:
  /// **'Move Vibes'**
  String get vibeBulk_titleMove;

  /// No description provided for @vibeBulk_titleToggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Update Favorites'**
  String get vibeBulk_titleToggleFavorite;

  /// No description provided for @vibeBulk_titleAddTags.
  ///
  /// In en, this message translates to:
  /// **'Add Tags'**
  String get vibeBulk_titleAddTags;

  /// No description provided for @vibeBulk_titleRemoveTags.
  ///
  /// In en, this message translates to:
  /// **'Remove Tags'**
  String get vibeBulk_titleRemoveTags;

  /// No description provided for @vibeBulk_titleExport.
  ///
  /// In en, this message translates to:
  /// **'Export Vibes'**
  String get vibeBulk_titleExport;

  /// No description provided for @vibeBulk_titleImport.
  ///
  /// In en, this message translates to:
  /// **'Import Vibes'**
  String get vibeBulk_titleImport;

  /// No description provided for @vibeBulk_processingProgress.
  ///
  /// In en, this message translates to:
  /// **'Processing: {current} / {total}'**
  String vibeBulk_processingProgress(int current, int total);

  /// No description provided for @vibeBulk_completed.
  ///
  /// In en, this message translates to:
  /// **'Operation complete'**
  String get vibeBulk_completed;

  /// No description provided for @vibeBulk_completedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'Operation complete with some failures'**
  String get vibeBulk_completedWithFailures;

  /// No description provided for @vibeBulk_successful.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get vibeBulk_successful;

  /// No description provided for @vibeBulk_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get vibeBulk_failed;

  /// No description provided for @vibeBulk_errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error details:'**
  String get vibeBulk_errorDetails;

  /// No description provided for @vibeBulk_moreErrors.
  ///
  /// In en, this message translates to:
  /// **'...and {count} more errors'**
  String vibeBulk_moreErrors(int count);

  /// No description provided for @vibeBulk_operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get vibeBulk_operationFailed;

  /// No description provided for @vibeBulk_operationFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check the operation settings and try again.'**
  String get vibeBulk_operationFailedHint;

  /// No description provided for @vibeBulk_errorEntryNotFoundOrDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'{item} was not found or could not be deleted'**
  String vibeBulk_errorEntryNotFoundOrDeleteFailed(String item);

  /// No description provided for @vibeBulk_errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {item}: {error}'**
  String vibeBulk_errorDeleteFailed(String item, String error);

  /// No description provided for @vibeBulk_errorEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Entry not found: {item}'**
  String vibeBulk_errorEntryNotFound(String item);

  /// No description provided for @vibeBulk_errorMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move {item}: {error}'**
  String vibeBulk_errorMoveFailed(String item, String error);

  /// No description provided for @vibeBulk_errorFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite status: {item}'**
  String vibeBulk_errorFavoriteFailed(String item);

  /// No description provided for @vibeBulk_errorFavoriteFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite status for {item}: {error}'**
  String vibeBulk_errorFavoriteFailedWithDetails(String item, String error);

  /// No description provided for @vibeBulk_errorAddTagsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add tags: {item}'**
  String vibeBulk_errorAddTagsFailed(String item);

  /// No description provided for @vibeBulk_errorAddTagsFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to add tags to {item}: {error}'**
  String vibeBulk_errorAddTagsFailedWithDetails(String item, String error);

  /// No description provided for @vibeBulk_errorRemoveTagsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove tags: {item}'**
  String vibeBulk_errorRemoveTagsFailed(String item);

  /// No description provided for @vibeBulk_errorRemoveTagsFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove tags from {item}: {error}'**
  String vibeBulk_errorRemoveTagsFailedWithDetails(String item, String error);

  /// No description provided for @vibeBulk_errorExportNoFile.
  ///
  /// In en, this message translates to:
  /// **'Export failed because no file was created'**
  String get vibeBulk_errorExportNoFile;

  /// No description provided for @vibeBulk_errorExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String vibeBulk_errorExportFailed(String error);

  /// No description provided for @vibeBulk_errorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found: {item}'**
  String vibeBulk_errorFileNotFound(String item);

  /// No description provided for @vibeBulk_errorNoVibeData.
  ///
  /// In en, this message translates to:
  /// **'No valid Vibe data was found in {item}'**
  String vibeBulk_errorNoVibeData(String item);

  /// No description provided for @vibeBulk_errorImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import Vibe from {item}: {error}'**
  String vibeBulk_errorImportFailed(String item, String error);

  /// No description provided for @vibeBulk_errorProcessFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process {item}: {error}'**
  String vibeBulk_errorProcessFileFailed(String item, String error);

  /// No description provided for @vibeBulkTag_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Tags in Bulk'**
  String get vibeBulkTag_title;

  /// No description provided for @vibeBulkTag_selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Vibes selected'**
  String vibeBulkTag_selectedCount(int count);

  /// No description provided for @vibeBulkTag_inputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new tag...'**
  String get vibeBulkTag_inputHint;

  /// No description provided for @vibeBulkTag_noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get vibeBulkTag_noTags;

  /// No description provided for @vibeBulkTag_noTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add tags to make filtering and management easier'**
  String get vibeBulkTag_noTagsHint;

  /// No description provided for @vibeBulkTag_currentTags.
  ///
  /// In en, this message translates to:
  /// **'Current tags ({count})'**
  String vibeBulkTag_currentTags(int count);

  /// No description provided for @vibeBulkTag_pendingRemoval.
  ///
  /// In en, this message translates to:
  /// **'Tags to remove ({count})'**
  String vibeBulkTag_pendingRemoval(int count);

  /// No description provided for @vibeBulkTag_removeTag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get vibeBulkTag_removeTag;

  /// No description provided for @vibeBulkTag_actionPreview.
  ///
  /// In en, this message translates to:
  /// **'Change preview'**
  String get vibeBulkTag_actionPreview;

  /// No description provided for @vibeBulkTag_addTagsSummary.
  ///
  /// In en, this message translates to:
  /// **'Add tags: {tags}'**
  String vibeBulkTag_addTagsSummary(String tags);

  /// No description provided for @vibeBulkTag_removeTagsSummary.
  ///
  /// In en, this message translates to:
  /// **'Remove tags: {tags}'**
  String vibeBulkTag_removeTagsSummary(String tags);

  /// No description provided for @vibeBulkTag_noChanges.
  ///
  /// In en, this message translates to:
  /// **'There are no changes to apply'**
  String get vibeBulkTag_noChanges;

  /// No description provided for @vibeBulkCategory_title.
  ///
  /// In en, this message translates to:
  /// **'Select Target Category'**
  String get vibeBulkCategory_title;

  /// No description provided for @vibeBulkCategory_moveCount.
  ///
  /// In en, this message translates to:
  /// **'Move {count} Vibes to:'**
  String vibeBulkCategory_moveCount(int count);

  /// No description provided for @vibeBulkCategory_cannotMoveToCurrent.
  ///
  /// In en, this message translates to:
  /// **'Cannot move to the current category'**
  String get vibeBulkCategory_cannotMoveToCurrent;

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

  /// No description provided for @vibe_import_failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String vibe_import_failedWithError(String error);

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

  /// No description provided for @vibe_maxReachedRemoveSome.
  ///
  /// In en, this message translates to:
  /// **'Maximum 16 vibes reached. Remove some vibes first.'**
  String get vibe_maxReachedRemoveSome;

  /// No description provided for @vibe_addedNamed.
  ///
  /// In en, this message translates to:
  /// **'Added Vibe: {name}'**
  String vibe_addedNamed(String name);

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

  /// No description provided for @image_editor_select_tool.
  ///
  /// In en, this message translates to:
  /// **'Select Tool'**
  String get image_editor_select_tool;

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

  /// No description provided for @settings_pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get settings_pleaseLoginFirst;

  /// No description provided for @settings_accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account information not found'**
  String get settings_accountNotFound;

  /// No description provided for @settings_goToLoginPage.
  ///
  /// In en, this message translates to:
  /// **'Go to login page'**
  String get settings_goToLoginPage;

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

  /// No description provided for @settings_kritaBridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Krita Bridge'**
  String get settings_kritaBridgeTitle;

  /// No description provided for @settings_kritaBridgeEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Krita local bridge'**
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
  /// **'Waiting for Krita plugin connection'**
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

  /// No description provided for @settings_kritaBridgeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settings_kritaBridgeDisabled;

  /// No description provided for @settings_kritaBridgeStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get settings_kritaBridgeStarting;

  /// No description provided for @settings_kritaBridgeListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get settings_kritaBridgeListening;

  /// No description provided for @settings_kritaBridgeConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settings_kritaBridgeConnected;

  /// No description provided for @settings_kritaBridgeError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get settings_kritaBridgeError;

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

  /// No description provided for @settings_fontScale_description.
  ///
  /// In en, this message translates to:
  /// **'Adjust global font scale'**
  String get settings_fontScale_description;

  /// No description provided for @settings_fontScale_previewSmall.
  ///
  /// In en, this message translates to:
  /// **'The setting sun and lone duck fly together'**
  String get settings_fontScale_previewSmall;

  /// No description provided for @settings_fontScale_previewMedium.
  ///
  /// In en, this message translates to:
  /// **'Autumn water merges with the endless sky'**
  String get settings_fontScale_previewMedium;

  /// No description provided for @settings_fontScale_previewLarge.
  ///
  /// In en, this message translates to:
  /// **'Font Size Preview'**
  String get settings_fontScale_previewLarge;

  /// No description provided for @settings_fontScale_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settings_fontScale_reset;

  /// No description provided for @settings_fontScale_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settings_fontScale_done;

  /// No description provided for @settings_generationLayout.
  ///
  /// In en, this message translates to:
  /// **'Generation page layout'**
  String get settings_generationLayout;

  /// No description provided for @settings_generationLayout_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get settings_generationLayout_classic;

  /// No description provided for @settings_generationLayout_classicDescription.
  ///
  /// In en, this message translates to:
  /// **'Parameters on the left, prompt above the preview'**
  String get settings_generationLayout_classicDescription;

  /// No description provided for @settings_generationLayout_webStyle.
  ///
  /// In en, this message translates to:
  /// **'Web style'**
  String get settings_generationLayout_webStyle;

  /// No description provided for @settings_generationLayout_webStyleDescription.
  ///
  /// In en, this message translates to:
  /// **'Prompt and settings docked on the far left, like the NovelAI website'**
  String get settings_generationLayout_webStyleDescription;

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

  /// No description provided for @settings_defaultVibePath.
  ///
  /// In en, this message translates to:
  /// **'{path} (Default)'**
  String settings_defaultVibePath(Object path);

  /// No description provided for @settings_defaultHivePath.
  ///
  /// In en, this message translates to:
  /// **'Default (%APPDATA%/NAI_Launcher/hive/)'**
  String get settings_defaultHivePath;

  /// No description provided for @settings_protectionMode.
  ///
  /// In en, this message translates to:
  /// **'Protection Mode'**
  String get settings_protectionMode;

  /// No description provided for @settings_protectionModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect local assets, shared copies, and high-cost or high-frequency generation operations through the options below. Turning this off keeps the option values but disables them.'**
  String get settings_protectionModeSubtitle;

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

  /// No description provided for @settings_selectLocalOnnxTaggerFolder.
  ///
  /// In en, this message translates to:
  /// **'Select ONNX tagger model folder'**
  String get settings_selectLocalOnnxTaggerFolder;

  /// No description provided for @settings_localOnnxTaggerFolderSaved.
  ///
  /// In en, this message translates to:
  /// **'ONNX tagger model folder saved'**
  String get settings_localOnnxTaggerFolderSaved;

  /// No description provided for @settings_localOnnxTaggerFolder.
  ///
  /// In en, this message translates to:
  /// **'Local ONNX tagger model folder'**
  String get settings_localOnnxTaggerFolder;

  /// No description provided for @settings_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settings_notConfigured;

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
  /// **'Protection Mode: High Anlas Cost'**
  String get settings_highAnlasCostTitle;

  /// No description provided for @settings_highAnlasCostContent.
  ///
  /// In en, this message translates to:
  /// **'This request is estimated to cost {cost} Anlas, which reaches or exceeds your {threshold} Anlas warning threshold. Continue generation?'**
  String settings_highAnlasCostContent(Object cost, Object threshold);

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

  /// No description provided for @settings_comfyUiWorkflowManagement.
  ///
  /// In en, this message translates to:
  /// **'Workflow Management'**
  String get settings_comfyUiWorkflowManagement;

  /// No description provided for @settings_comfyUiBuiltinWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Built-in Workflows'**
  String get settings_comfyUiBuiltinWorkflows;

  /// No description provided for @settings_comfyUiCustomWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Custom Workflows'**
  String get settings_comfyUiCustomWorkflows;

  /// No description provided for @settings_comfyUiNoCustomWorkflows.
  ///
  /// In en, this message translates to:
  /// **'No custom workflows yet. Click \"Import\" to add a ComfyUI workflow.'**
  String get settings_comfyUiNoCustomWorkflows;

  /// No description provided for @settings_comfyUiSlotCount.
  ///
  /// In en, this message translates to:
  /// **'{count} slots'**
  String settings_comfyUiSlotCount(Object count);

  /// No description provided for @settings_comfyUiBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get settings_comfyUiBuiltin;

  /// No description provided for @settings_comfyUiDeleteWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Workflow'**
  String get settings_comfyUiDeleteWorkflowTitle;

  /// No description provided for @settings_comfyUiDeleteWorkflowContent.
  ///
  /// In en, this message translates to:
  /// **'Delete workflow \"{name}\"? This cannot be undone.'**
  String settings_comfyUiDeleteWorkflowContent(Object name);

  /// No description provided for @settings_comfyUiDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {name}'**
  String settings_comfyUiDeleted(Object name);

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

  /// No description provided for @promptAssistant_defaultOptimizeRuleName.
  ///
  /// In en, this message translates to:
  /// **'Default Optimize Rule'**
  String get promptAssistant_defaultOptimizeRuleName;

  /// No description provided for @promptAssistant_defaultOptimizeRuleContent.
  ///
  /// In en, this message translates to:
  /// **'You are a prompt optimization assistant. Preserve the user intent, add actionable visual details, and output a single comma-separated prompt line.'**
  String get promptAssistant_defaultOptimizeRuleContent;

  /// No description provided for @promptAssistant_defaultTranslateRuleName.
  ///
  /// In en, this message translates to:
  /// **'Default Translate Rule'**
  String get promptAssistant_defaultTranslateRuleName;

  /// No description provided for @promptAssistant_defaultTranslateRuleContent.
  ///
  /// In en, this message translates to:
  /// **'You are a translation assistant. Detect the source language, translate between Chinese and English automatically, and return only the translation without explanation.'**
  String get promptAssistant_defaultTranslateRuleContent;

  /// No description provided for @promptAssistant_defaultReverseRuleName.
  ///
  /// In en, this message translates to:
  /// **'Default Reverse Prompt Rule'**
  String get promptAssistant_defaultReverseRuleName;

  /// No description provided for @promptAssistant_defaultReverseRuleContent.
  ///
  /// In en, this message translates to:
  /// **'You are an image reverse-prompt assistant. Based on the image and optional tagger results, output English comma-separated prompts suitable for NovelAI. Preserve subject, character, style, clothing, action, composition, lighting, and background. Do not explain.'**
  String get promptAssistant_defaultReverseRuleContent;

  /// No description provided for @promptAssistant_defaultCharacterReplaceRuleName.
  ///
  /// In en, this message translates to:
  /// **'Default Character Replace Rule'**
  String get promptAssistant_defaultCharacterReplaceRuleName;

  /// No description provided for @promptAssistant_defaultCharacterReplaceRuleContent.
  ///
  /// In en, this message translates to:
  /// **'You are a character replacement assistant. Replace the original character identity, hairstyle, outfit, and appearance in the input prompt with the target character while preserving action, composition, background, style, camera, and quality tags. Output only the replaced single-line prompt.'**
  String get promptAssistant_defaultCharacterReplaceRuleContent;

  /// No description provided for @promptAssistant_defaultCustomRuleName.
  ///
  /// In en, this message translates to:
  /// **'Default Custom Rule'**
  String get promptAssistant_defaultCustomRuleName;

  /// No description provided for @promptAssistant_defaultCustomRuleContent.
  ///
  /// In en, this message translates to:
  /// **'You are a prompt rewriting assistant. Modify the prompt according to the current prompt, the user request, and optional reference images. Output only the final single-line prompt that can be used directly, without explanation.'**
  String get promptAssistant_defaultCustomRuleContent;

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

  /// No description provided for @cacheStats_refreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get cacheStats_refreshNow;

  /// No description provided for @cacheStats_refreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get cacheStats_refreshed;

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

  /// No description provided for @cacheStats_recordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String cacheStats_recordCount(Object count);

  /// No description provided for @cacheStats_databaseValue.
  ///
  /// In en, this message translates to:
  /// **'{imageCount} images · {metadataCount} metadata rows'**
  String cacheStats_databaseValue(Object imageCount, Object metadataCount);

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

  /// No description provided for @toast_tagCopied.
  ///
  /// In en, this message translates to:
  /// **'Tags copied'**
  String get toast_tagCopied;

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

  /// No description provided for @toast_smartDecomposeSent.
  ///
  /// In en, this message translates to:
  /// **'Smart decomposed and sent'**
  String get toast_smartDecomposeSent;

  /// No description provided for @toast_addedToFixedTags.
  ///
  /// In en, this message translates to:
  /// **'Added to fixed tags'**
  String get toast_addedToFixedTags;

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

  /// No description provided for @detail_sendToReversePrompt.
  ///
  /// In en, this message translates to:
  /// **'Send to Reverse Prompt'**
  String get detail_sendToReversePrompt;

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

  /// No description provided for @pagination_firstPage.
  ///
  /// In en, this message translates to:
  /// **'First page'**
  String get pagination_firstPage;

  /// No description provided for @pagination_previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get pagination_previousPage;

  /// No description provided for @pagination_nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get pagination_nextPage;

  /// No description provided for @pagination_lastPage.
  ///
  /// In en, this message translates to:
  /// **'Last page'**
  String get pagination_lastPage;

  /// No description provided for @pagination_jumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Jump to page'**
  String get pagination_jumpToPage;

  /// No description provided for @pagination_jump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get pagination_jump;

  /// No description provided for @pagination_itemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Per page'**
  String get pagination_itemsPerPage;

  /// No description provided for @pagination_itemUnit.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get pagination_itemUnit;

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

  /// No description provided for @updatePortableManualHint.
  ///
  /// In en, this message translates to:
  /// **'This build cannot update in-app. Please download the new version from the Release page.'**
  String get updatePortableManualHint;

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

  /// No description provided for @updateInstallConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Install the update now?'**
  String get updateInstallConfirmationTitle;

  /// No description provided for @updateInstallConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'The app will shut down safely, install the update, and restart automatically. Active generation and download tasks will stop, so save anything important first.'**
  String get updateInstallConfirmationBody;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me in 4 Hours'**
  String get remindMeLater;

  /// No description provided for @skipThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip This Version'**
  String get skipThisVersion;

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

  /// No description provided for @versionSkipped.
  ///
  /// In en, this message translates to:
  /// **'Version skipped'**
  String get versionSkipped;

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

  /// No description provided for @model3d_addMannequin.
  ///
  /// In en, this message translates to:
  /// **'Add Built-in Mannequin'**
  String get model3d_addMannequin;

  /// No description provided for @model3d_importModel.
  ///
  /// In en, this message translates to:
  /// **'Import Model (.glb/.gltf)'**
  String get model3d_importModel;

  /// No description provided for @model3d_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Scene is empty. Add a mannequin or import a model.'**
  String get model3d_emptyHint;

  /// No description provided for @model3d_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply to Layer'**
  String get model3d_apply;

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

  /// No description provided for @model3d_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get model3d_undo;

  /// No description provided for @model3d_resetPose.
  ///
  /// In en, this message translates to:
  /// **'Reset Pose'**
  String get model3d_resetPose;

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

  /// No description provided for @model3d_lightIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get model3d_lightIntensity;

  /// No description provided for @model3d_lightAzimuth.
  ///
  /// In en, this message translates to:
  /// **'Azimuth'**
  String get model3d_lightAzimuth;

  /// No description provided for @model3d_lightElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get model3d_lightElevation;

  /// No description provided for @model3d_addLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add 3D Model Layer'**
  String get model3d_addLayerTooltip;

  /// No description provided for @model3d_webview2Missing.
  ///
  /// In en, this message translates to:
  /// **'The 3D editor requires the Microsoft Edge WebView2 Runtime. It ships with Windows 10/11; if missing, install the Evergreen runtime from Microsoft and retry.'**
  String get model3d_webview2Missing;

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

  /// No description provided for @preciseRefLib_deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get preciseRefLib_deleteEntry;

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

  /// No description provided for @common_previewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preview'**
  String get common_previewLoadFailed;

  /// No description provided for @common_clickToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Click to refresh'**
  String get common_clickToRefresh;

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

  /// No description provided for @common_prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get common_prefix;

  /// No description provided for @common_suffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get common_suffix;

  /// No description provided for @common_minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get common_minimum;

  /// No description provided for @common_maximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get common_maximum;

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

  /// No description provided for @drop_saveVibeBundleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save {name} and the other Vibes to the library'**
  String drop_saveVibeBundleSubtitle(String name);

  /// No description provided for @drop_saveEncodedVibeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save the pre-encoded Vibe data to the library'**
  String get drop_saveEncodedVibeSubtitle;

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

  /// No description provided for @localGallery_createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get localGallery_createFolder;

  /// No description provided for @galleryScan_skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count}'**
  String galleryScan_skipped(int count);

  /// No description provided for @galleryScan_withMetadata.
  ///
  /// In en, this message translates to:
  /// **'With metadata {count}'**
  String galleryScan_withMetadata(int count);

  /// No description provided for @galleryScan_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed {count}'**
  String galleryScan_failed(int count);

  /// No description provided for @galleryScan_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get galleryScan_processing;

  /// No description provided for @galleryScan_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get galleryScan_pending;

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

  /// No description provided for @editor_effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get editor_effects;

  /// No description provided for @editor_shiftEdges.
  ///
  /// In en, this message translates to:
  /// **'Shift Edges'**
  String get editor_shiftEdges;

  /// No description provided for @editor_currentSize.
  ///
  /// In en, this message translates to:
  /// **'Current: {width} x {height}'**
  String editor_currentSize(int width, int height);

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

  /// No description provided for @editor_nonNegativeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be 0 or more'**
  String get editor_nonNegativeNumber;

  /// No description provided for @editor_requestedSize.
  ///
  /// In en, this message translates to:
  /// **'Requested: {width} x {height}'**
  String editor_requestedSize(int width, int height);

  /// No description provided for @editor_requestedSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Requested: invalid'**
  String get editor_requestedSizeInvalid;

  /// No description provided for @editor_appliedSize.
  ///
  /// In en, this message translates to:
  /// **'Applied: {width} x {height}'**
  String editor_appliedSize(int width, int height);

  /// No description provided for @editor_appliedSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Applied: invalid'**
  String get editor_appliedSizeInvalid;

  /// No description provided for @editor_appliedEdges.
  ///
  /// In en, this message translates to:
  /// **'Applied edges: L {left}, T {top}, R {right}, B {bottom}'**
  String editor_appliedEdges(int left, int top, int right, int bottom);

  /// No description provided for @editor_appliedEdgesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Applied edges: invalid'**
  String get editor_appliedEdgesInvalid;

  /// No description provided for @editor_appliedDimensionLimit.
  ///
  /// In en, this message translates to:
  /// **'Applied dimensions must not exceed {max}.'**
  String editor_appliedDimensionLimit(int max);

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

  /// No description provided for @autocomplete_translating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get autocomplete_translating;

  /// No description provided for @autocomplete_missingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Not translated'**
  String get autocomplete_missingTranslation;

  /// No description provided for @autocomplete_translationCoverage.
  ///
  /// In en, this message translates to:
  /// **'Translation coverage: {translated}/{total}'**
  String autocomplete_translationCoverage(int translated, int total);

  /// No description provided for @autocomplete_aliasMatch.
  ///
  /// In en, this message translates to:
  /// **'Alias: {alias}'**
  String autocomplete_aliasMatch(String alias);

  /// No description provided for @autocomplete_settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Autocomplete'**
  String get autocomplete_settingsTitle;

  /// No description provided for @autocomplete_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable autocomplete'**
  String get autocomplete_enable;

  /// No description provided for @autocomplete_resultLimit.
  ///
  /// In en, this message translates to:
  /// **'Result count'**
  String get autocomplete_resultLimit;

  /// No description provided for @autocomplete_allResults.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get autocomplete_allResults;

  /// No description provided for @autocomplete_showAliases.
  ///
  /// In en, this message translates to:
  /// **'Show matched aliases'**
  String get autocomplete_showAliases;

  /// No description provided for @autocomplete_showTranslations.
  ///
  /// In en, this message translates to:
  /// **'Show Chinese translations'**
  String get autocomplete_showTranslations;

  /// No description provided for @autocomplete_autoComma.
  ///
  /// In en, this message translates to:
  /// **'Add a comma after insertion'**
  String get autocomplete_autoComma;

  /// No description provided for @autocomplete_dataSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Sources & Cache'**
  String get autocomplete_dataSourcesTitle;

  /// No description provided for @autocomplete_relatedTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Co-occurrence and related tags'**
  String get autocomplete_relatedTagsTitle;

  /// No description provided for @autocomplete_relatedTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest after accepting a tag; also use Ctrl+Shift+Space or Ctrl+click on a tag'**
  String get autocomplete_relatedTagsSubtitle;

  /// No description provided for @autocomplete_danbooruApi.
  ///
  /// In en, this message translates to:
  /// **'Danbooru online supplement'**
  String get autocomplete_danbooruApi;

  /// No description provided for @autocomplete_danbooruPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only the current English tag is sent; the full prompt is never uploaded'**
  String get autocomplete_danbooruPrivacy;

  /// No description provided for @autocomplete_llmTranslation.
  ///
  /// In en, this message translates to:
  /// **'Use Prompt Assistant for missing translations'**
  String get autocomplete_llmTranslation;

  /// No description provided for @autocomplete_llmRouteMissing.
  ///
  /// In en, this message translates to:
  /// **'Configure a Translate route in Prompt Assistant first'**
  String get autocomplete_llmRouteMissing;

  /// No description provided for @autocomplete_llmRoute.
  ///
  /// In en, this message translates to:
  /// **'Current route: {route}. Model usage may incur fees.'**
  String autocomplete_llmRoute(String route);

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

  /// No description provided for @autocomplete_cacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Online & AI Cache'**
  String get autocomplete_cacheTitle;

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

  /// No description provided for @autocomplete_zhDictionary.
  ///
  /// In en, this message translates to:
  /// **'ffdkj Simplified Chinese dictionary'**
  String get autocomplete_zhDictionary;

  /// No description provided for @autocomplete_zhInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed: {count} entries · version {version}'**
  String autocomplete_zhInstalled(int count, String version);

  /// No description provided for @autocomplete_zhNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed; English autocomplete remains available'**
  String get autocomplete_zhNotInstalled;

  /// No description provided for @autocomplete_zhInstallPrompt.
  ///
  /// In en, this message translates to:
  /// **'Install the ffdkj dictionary for Chinese labels and reverse lookup. It is downloaded directly from upstream.'**
  String get autocomplete_zhInstallPrompt;

  /// No description provided for @autocomplete_checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get autocomplete_checkUpdate;

  /// No description provided for @autocomplete_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get autocomplete_update;

  /// No description provided for @autocomplete_repair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get autocomplete_repair;

  /// No description provided for @autocomplete_install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get autocomplete_install;

  /// No description provided for @autocomplete_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get autocomplete_remove;

  /// No description provided for @autocomplete_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the installed Chinese translation dictionary? You can install it again later.'**
  String get autocomplete_removeConfirm;

  /// No description provided for @autocomplete_sourceBase.
  ///
  /// In en, this message translates to:
  /// **'Bundled base catalog'**
  String get autocomplete_sourceBase;

  /// No description provided for @autocomplete_sourceZh.
  ///
  /// In en, this message translates to:
  /// **'ffdkj Chinese dictionary'**
  String get autocomplete_sourceZh;

  /// No description provided for @autocomplete_sourceApi.
  ///
  /// In en, this message translates to:
  /// **'Danbooru API'**
  String get autocomplete_sourceApi;

  /// No description provided for @autocomplete_sourceRelated.
  ///
  /// In en, this message translates to:
  /// **'Offline related tags'**
  String get autocomplete_sourceRelated;

  /// No description provided for @autocomplete_sourceAi.
  ///
  /// In en, this message translates to:
  /// **'Prompt Assistant translation'**
  String get autocomplete_sourceAi;

  /// No description provided for @autocomplete_headerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag autocomplete'**
  String get autocomplete_headerTitle;

  /// No description provided for @autocomplete_relatedHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Related tags'**
  String get autocomplete_relatedHeaderTitle;

  /// No description provided for @autocomplete_relatedLoading.
  ///
  /// In en, this message translates to:
  /// **'Querying offline co-occurrences and online related tags…'**
  String get autocomplete_relatedLoading;

  /// No description provided for @autocomplete_relatedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related tags are available'**
  String get autocomplete_relatedEmpty;

  /// No description provided for @autocomplete_relatedMetric.
  ///
  /// In en, this message translates to:
  /// **'{count} co-occurrences · Jaccard {score}'**
  String autocomplete_relatedMetric(int count, String score);

  /// No description provided for @autocomplete_relatedPin.
  ///
  /// In en, this message translates to:
  /// **'Pin this tag to insert multiple related tags'**
  String get autocomplete_relatedPin;

  /// No description provided for @autocomplete_relatedUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin and resume chained recommendations'**
  String get autocomplete_relatedUnpin;

  /// No description provided for @autocomplete_statusBase.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get autocomplete_statusBase;

  /// No description provided for @autocomplete_statusRelated.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get autocomplete_statusRelated;

  /// No description provided for @autocomplete_statusDictionary.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get autocomplete_statusDictionary;

  /// No description provided for @autocomplete_statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get autocomplete_statusOnline;

  /// No description provided for @autocomplete_statusAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get autocomplete_statusAi;

  /// No description provided for @autocomplete_statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get autocomplete_statusReady;

  /// No description provided for @autocomplete_statusNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get autocomplete_statusNotInstalled;

  /// No description provided for @autocomplete_statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {progress}%'**
  String autocomplete_statusDownloading(int progress);

  /// No description provided for @autocomplete_statusUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get autocomplete_statusUpdateAvailable;

  /// No description provided for @autocomplete_statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get autocomplete_statusError;

  /// No description provided for @autocomplete_statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autocomplete_statusDisabled;

  /// No description provided for @autocomplete_statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get autocomplete_statusSearching;

  /// No description provided for @autocomplete_statusTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get autocomplete_statusTranslating;

  /// No description provided for @autocomplete_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open autocomplete and data source settings'**
  String get autocomplete_openSettings;

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

  /// No description provided for @pillCardEvolutionExploreOnly.
  ///
  /// In en, this message translates to:
  /// **'Evolution is available only in Style Explore'**
  String get pillCardEvolutionExploreOnly;

  /// No description provided for @pillCardEvolutionRequiresRandom.
  ///
  /// In en, this message translates to:
  /// **'Set the instance to random or sequential first'**
  String get pillCardEvolutionRequiresRandom;

  /// No description provided for @pillCardEvolutionRequiresEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable the instance first'**
  String get pillCardEvolutionRequiresEnabled;

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

  /// No description provided for @promptBlockLibrary_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search blocks...'**
  String get promptBlockLibrary_searchHint;

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

  /// No description provided for @promptBlockLibrary_blockContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get promptBlockLibrary_blockContent;

  /// No description provided for @promptBlockLibrary_contentHint.
  ///
  /// In en, this message translates to:
  /// **'Plain text content'**
  String get promptBlockLibrary_contentHint;

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

  /// No description provided for @promptBlockLibrary_favoriteSelected.
  ///
  /// In en, this message translates to:
  /// **'Favorite {count} selected blocks'**
  String promptBlockLibrary_favoriteSelected(int count);

  /// No description provided for @promptBlockLibrary_unfavoriteSelected.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite {count} selected blocks'**
  String promptBlockLibrary_unfavoriteSelected(int count);

  /// No description provided for @promptBlockLibrary_moveToSelected.
  ///
  /// In en, this message translates to:
  /// **'Move {count} blocks to…'**
  String promptBlockLibrary_moveToSelected(int count);

  /// No description provided for @promptBlockLibrary_deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected blocks'**
  String promptBlockLibrary_deleteSelected(int count);

  /// No description provided for @promptBlockLibrary_blocksMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} blocks'**
  String promptBlockLibrary_blocksMoved(int count);

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

  /// No description provided for @promptBlockLibrary_exportBlockAsTxt.
  ///
  /// In en, this message translates to:
  /// **'Export as TXT'**
  String get promptBlockLibrary_exportBlockAsTxt;

  /// No description provided for @promptBlockLibrary_exportTxtDone.
  ///
  /// In en, this message translates to:
  /// **'TXT exported'**
  String get promptBlockLibrary_exportTxtDone;

  /// No description provided for @promptBlockLibrary_exportTxtFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String promptBlockLibrary_exportTxtFailed(String error);

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

  /// No description provided for @styleExplore_recipeListTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get styleExplore_recipeListTitle;

  /// No description provided for @styleExplore_recipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet. Start a new one, or compose in the editor and \"Save as\".'**
  String get styleExplore_recipesEmpty;

  /// No description provided for @styleExplore_noActiveRecipe.
  ///
  /// In en, this message translates to:
  /// **'No recipe linked'**
  String get styleExplore_noActiveRecipe;

  /// No description provided for @styleExplore_unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get styleExplore_unsavedChanges;

  /// No description provided for @styleExplore_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get styleExplore_save;

  /// No description provided for @styleExplore_saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get styleExplore_saveAs;

  /// No description provided for @styleExplore_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get styleExplore_preview;

  /// No description provided for @styleExplore_positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get styleExplore_positive;

  /// No description provided for @styleExplore_negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get styleExplore_negative;

  /// No description provided for @styleExplore_newRecipe.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get styleExplore_newRecipe;

  /// No description provided for @styleExplore_load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get styleExplore_load;

  /// No description provided for @styleExplore_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get styleExplore_rename;

  /// No description provided for @styleExplore_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate recipe'**
  String get styleExplore_duplicate;

  /// No description provided for @styleExplore_deleteRecipe.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get styleExplore_deleteRecipe;

  /// No description provided for @styleExplore_recipeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe name'**
  String get styleExplore_recipeNameLabel;

  /// No description provided for @styleExplore_recipeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. soft lighting study'**
  String get styleExplore_recipeNameHint;

  /// No description provided for @styleExplore_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get styleExplore_nameRequired;

  /// No description provided for @styleExplore_recipeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\"'**
  String styleExplore_recipeSaved(String name);

  /// No description provided for @styleExplore_recipeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created \"{name}\"'**
  String styleExplore_recipeCreated(String name);

  /// No description provided for @styleExplore_recipeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded \"{name}\"'**
  String styleExplore_recipeLoaded(String name);

  /// No description provided for @styleExplore_recipeDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Duplicated \"{name}\"'**
  String styleExplore_recipeDuplicated(String name);

  /// No description provided for @styleExplore_recipeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String styleExplore_recipeDeleted(String name);

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

  /// No description provided for @styleExplore_previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt preview'**
  String get styleExplore_previewTitle;

  /// No description provided for @styleExplore_previewEmpty.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get styleExplore_previewEmpty;

  /// No description provided for @styleExplore_copyPositive.
  ///
  /// In en, this message translates to:
  /// **'Copy positive'**
  String get styleExplore_copyPositive;

  /// No description provided for @styleExplore_copyNegative.
  ///
  /// In en, this message translates to:
  /// **'Copy negative'**
  String get styleExplore_copyNegative;

  /// No description provided for @styleExplore_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get styleExplore_copiedToClipboard;

  /// No description provided for @styleExplore_runSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore runs'**
  String get styleExplore_runSectionTitle;

  /// No description provided for @styleExplore_runEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'An explore run captures prompt and parameter snapshots, generates candidates in batch, then reviews them.'**
  String get styleExplore_runEmptyHint;

  /// No description provided for @styleExplore_newRun.
  ///
  /// In en, this message translates to:
  /// **'New run'**
  String get styleExplore_newRun;

  /// No description provided for @styleExplore_manageRecipes.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get styleExplore_manageRecipes;

  /// No description provided for @styleExplore_recipeMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more…'**
  String styleExplore_recipeMoreCount(int count);

  /// No description provided for @styleExplore_galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate gallery'**
  String get styleExplore_galleryTitle;

  /// No description provided for @styleExplore_galleryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No candidates yet. Create or select an explore run to start batch generation.'**
  String get styleExplore_galleryEmptyHint;

  /// No description provided for @styleExplore_runNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Run name'**
  String get styleExplore_runNameLabel;

  /// No description provided for @styleExplore_runNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Soft light ×30'**
  String get styleExplore_runNameHint;

  /// No description provided for @styleExplore_runCreated.
  ///
  /// In en, this message translates to:
  /// **'Created \"{name}\"'**
  String styleExplore_runCreated(String name);

  /// No description provided for @styleExplore_runDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String styleExplore_runDeleted(String name);

  /// No description provided for @styleExplore_runTotalCount.
  ///
  /// In en, this message translates to:
  /// **'Total {total} images'**
  String styleExplore_runTotalCount(int total);

  /// No description provided for @styleExplore_runGeneratingProgress.
  ///
  /// In en, this message translates to:
  /// **'Image {current}/{total}'**
  String styleExplore_runGeneratingProgress(int current, int total);

  /// No description provided for @styleExplore_runStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get styleExplore_runStatusDraft;

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

  /// No description provided for @styleExplore_runStatusGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get styleExplore_runStatusGenerated;

  /// No description provided for @styleExplore_runStatusReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get styleExplore_runStatusReviewing;

  /// No description provided for @styleExplore_runStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get styleExplore_runStatusCompleted;

  /// No description provided for @styleExplore_runStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get styleExplore_runStatusCancelled;

  /// No description provided for @styleExplore_archivedTag.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get styleExplore_archivedTag;

  /// No description provided for @styleExplore_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get styleExplore_archive;

  /// No description provided for @styleExplore_unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get styleExplore_unarchive;

  /// No description provided for @styleExplore_loadSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Load snapshot to editor'**
  String get styleExplore_loadSnapshot;

  /// No description provided for @styleExplore_snapshotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded snapshot of \"{name}\"'**
  String styleExplore_snapshotLoaded(String name);

  /// No description provided for @styleExplore_pauseRun.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get styleExplore_pauseRun;

  /// No description provided for @styleExplore_cancelRun.
  ///
  /// In en, this message translates to:
  /// **'Cancel run'**
  String get styleExplore_cancelRun;

  /// No description provided for @styleExplore_retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed ({count})'**
  String styleExplore_retryFailed(int count);

  /// No description provided for @styleExplore_targetCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get styleExplore_targetCountLabel;

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
  /// **'Delete explore run'**
  String get styleExplore_deleteRunTitle;

  /// No description provided for @styleExplore_deleteRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Deletes \"{name}\" and its candidate image copies; source images in the gallery are not affected.'**
  String styleExplore_deleteRunMessage(String name);

  /// No description provided for @styleExplore_cancelRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel explore run'**
  String get styleExplore_cancelRunTitle;

  /// No description provided for @styleExplore_cancelRunMessage.
  ///
  /// In en, this message translates to:
  /// **'A cancelled run cannot be restarted; remaining pending candidates will be marked as cancelled.'**
  String get styleExplore_cancelRunMessage;

  /// No description provided for @styleExplore_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get styleExplore_filterAll;

  /// No description provided for @styleExplore_filterHearted.
  ///
  /// In en, this message translates to:
  /// **'Hearted'**
  String get styleExplore_filterHearted;

  /// No description provided for @styleExplore_filterPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed'**
  String get styleExplore_filterPendingReview;

  /// No description provided for @styleExplore_filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get styleExplore_filterFailed;

  /// No description provided for @styleExplore_markTreasure.
  ///
  /// In en, this message translates to:
  /// **'Treasure'**
  String get styleExplore_markTreasure;

  /// No description provided for @styleExplore_markSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get styleExplore_markSpecial;

  /// No description provided for @styleExplore_markReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get styleExplore_markReject;

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

  /// No description provided for @styleExplore_rollSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Roll snapshot'**
  String get styleExplore_rollSnapshot;

  /// No description provided for @styleExplore_seedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed {seed}'**
  String styleExplore_seedLabel(String seed);

  /// No description provided for @styleExplore_roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String styleExplore_roundNumber(int number);

  /// No description provided for @styleExplore_formalReview.
  ///
  /// In en, this message translates to:
  /// **'Formal review'**
  String get styleExplore_formalReview;

  /// No description provided for @styleExplore_reviewProgress.
  ///
  /// In en, this message translates to:
  /// **'Classified {labeled}/{total}'**
  String styleExplore_reviewProgress(int labeled, int total);

  /// No description provided for @styleExplore_reviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Finish review'**
  String get styleExplore_reviewComplete;

  /// No description provided for @styleExplore_reviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Review completed'**
  String get styleExplore_reviewCompleted;

  /// No description provided for @styleExplore_reviewUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo last'**
  String get styleExplore_reviewUndo;

  /// No description provided for @styleExplore_reviewExit.
  ///
  /// In en, this message translates to:
  /// **'Exit review'**
  String get styleExplore_reviewExit;

  /// No description provided for @styleExplore_reviewUnlabeled.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get styleExplore_reviewUnlabeled;

  /// No description provided for @styleExplore_viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get styleExplore_viewGrid;

  /// No description provided for @styleExplore_viewDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck view'**
  String get styleExplore_viewDeck;

  /// No description provided for @styleExplore_adoptAsBlock.
  ///
  /// In en, this message translates to:
  /// **'Adopt as block'**
  String get styleExplore_adoptAsBlock;

  /// No description provided for @styleExplore_adoptBlockNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block name'**
  String get styleExplore_adoptBlockNameLabel;

  /// No description provided for @styleExplore_adoptBlockSaved.
  ///
  /// In en, this message translates to:
  /// **'Adopted as block \"{name}\"'**
  String styleExplore_adoptBlockSaved(String name);

  /// No description provided for @styleExplore_adoptBlockEmpty.
  ///
  /// In en, this message translates to:
  /// **'Selected candidates have no roll text'**
  String get styleExplore_adoptBlockEmpty;

  /// No description provided for @styleExplore_fixateAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Fix as template'**
  String get styleExplore_fixateAsTemplate;

  /// No description provided for @styleExplore_fixateDone.
  ///
  /// In en, this message translates to:
  /// **'Positive prompt replaced; save as a recipe from the top bar'**
  String get styleExplore_fixateDone;

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
  /// **'Deletes this candidate\'s image copy in the run directory. The candidate record is kept and the gallery source image is untouched.'**
  String get styleExplore_deleteImageMessage;

  /// No description provided for @styleExplore_deleteImageDone.
  ///
  /// In en, this message translates to:
  /// **'Candidate image copy deleted'**
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

  /// No description provided for @styleExplore_mergeAdopt.
  ///
  /// In en, this message translates to:
  /// **'Merge & adopt'**
  String get styleExplore_mergeAdopt;

  /// No description provided for @styleExplore_noRunsYet.
  ///
  /// In en, this message translates to:
  /// **'No explore runs yet'**
  String get styleExplore_noRunsYet;

  /// No description provided for @promptBlockEditor_library.
  ///
  /// In en, this message translates to:
  /// **'Block library'**
  String get promptBlockEditor_library;

  /// No description provided for @styleExplore_lineageTitle.
  ///
  /// In en, this message translates to:
  /// **'Lineage'**
  String get styleExplore_lineageTitle;

  /// No description provided for @styleExplore_createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get styleExplore_createFamily;

  /// No description provided for @styleExplore_familyCreated.
  ///
  /// In en, this message translates to:
  /// **'Family \"{name}\" created'**
  String styleExplore_familyCreated(String name);

  /// No description provided for @styleExplore_familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get styleExplore_familyNameLabel;

  /// No description provided for @styleExplore_familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Soft light main line'**
  String get styleExplore_familyNameHint;

  /// No description provided for @styleExplore_familyParentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parents ({count})'**
  String styleExplore_familyParentsTitle(int count);

  /// No description provided for @styleExplore_customParentLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom parent string'**
  String get styleExplore_customParentLabel;

  /// No description provided for @styleExplore_customParentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a prompt string as a parent'**
  String get styleExplore_customParentHint;

  /// No description provided for @styleExplore_addCustomParent.
  ///
  /// In en, this message translates to:
  /// **'Add custom string'**
  String get styleExplore_addCustomParent;

  /// No description provided for @styleExplore_createFamilyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one valid parent string'**
  String get styleExplore_createFamilyEmpty;

  /// No description provided for @styleExplore_parentSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Gen {generation} parent set'**
  String styleExplore_parentSetTitle(int generation);

  /// No description provided for @styleExplore_candidatePileTitle.
  ///
  /// In en, this message translates to:
  /// **'Gen {generation} pile · {count}'**
  String styleExplore_candidatePileTitle(int generation, int count);

  /// No description provided for @styleExplore_parentSetActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get styleExplore_parentSetActive;

  /// No description provided for @styleExplore_parentSetUsed.
  ///
  /// In en, this message translates to:
  /// **'Backcrossed'**
  String get styleExplore_parentSetUsed;

  /// No description provided for @styleExplore_branchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch: {name}'**
  String styleExplore_branchLabel(String name);

  /// No description provided for @styleExplore_createDeepRound.
  ///
  /// In en, this message translates to:
  /// **'Create round'**
  String get styleExplore_createDeepRound;

  /// No description provided for @styleExplore_anotherDeepRound.
  ///
  /// In en, this message translates to:
  /// **'New round'**
  String get styleExplore_anotherDeepRound;

  /// No description provided for @styleExplore_deepRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep candidate round'**
  String get styleExplore_deepRoundTitle;

  /// No description provided for @styleExplore_deepRoundCountHint.
  ///
  /// In en, this message translates to:
  /// **'Count must be at least {min} (one per parent)'**
  String styleExplore_deepRoundCountHint(int min);

  /// No description provided for @styleExplore_deepRoundNoInstance.
  ///
  /// In en, this message translates to:
  /// **'No enabled random evolution block in the main prompt; deep round unavailable'**
  String get styleExplore_deepRoundNoInstance;

  /// No description provided for @styleExplore_deepRoundEmpty.
  ///
  /// In en, this message translates to:
  /// **'Mutation engine could not produce enough distinct children'**
  String get styleExplore_deepRoundEmpty;

  /// No description provided for @styleExplore_sortParents.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get styleExplore_sortParents;

  /// No description provided for @styleExplore_sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairwise parent ranking'**
  String get styleExplore_sortTitle;

  /// No description provided for @styleExplore_sortPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which string is closer to the desired result?'**
  String get styleExplore_sortPrompt;

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
  /// **'Neither'**
  String get styleExplore_sortNeither;

  /// No description provided for @styleExplore_sortSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get styleExplore_sortSkip;

  /// No description provided for @styleExplore_sortProgress.
  ///
  /// In en, this message translates to:
  /// **'Pair {current}/{total}'**
  String styleExplore_sortProgress(int current, int total);

  /// No description provided for @styleExplore_sortDone.
  ///
  /// In en, this message translates to:
  /// **'Ranking finished'**
  String get styleExplore_sortDone;

  /// No description provided for @styleExplore_branchSelect.
  ///
  /// In en, this message translates to:
  /// **'Select for branch'**
  String get styleExplore_branchSelect;

  /// No description provided for @styleExplore_createBranch.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get styleExplore_createBranch;

  /// No description provided for @styleExplore_branchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch name (optional)'**
  String get styleExplore_branchNameLabel;

  /// No description provided for @styleExplore_branchCreated.
  ///
  /// In en, this message translates to:
  /// **'Branch created ({count} parents)'**
  String styleExplore_branchCreated(int count);

  /// No description provided for @styleExplore_branchNeedLatest.
  ///
  /// In en, this message translates to:
  /// **'Branches can only be created from the latest generation pile'**
  String get styleExplore_branchNeedLatest;

  /// No description provided for @styleExplore_branchRoundsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The current generation still has unfinished rounds'**
  String get styleExplore_branchRoundsIncomplete;

  /// No description provided for @styleExplore_branchDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A selected child duplicates a first-generation parent string'**
  String get styleExplore_branchDuplicate;

  /// No description provided for @styleExplore_branchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select at least one child candidate'**
  String get styleExplore_branchEmpty;

  /// No description provided for @styleExplore_preferenceValue.
  ///
  /// In en, this message translates to:
  /// **'Pref {value}'**
  String styleExplore_preferenceValue(String value);

  /// No description provided for @styleExplore_roundsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String styleExplore_roundsSummary(int count);

  /// No description provided for @styleExplore_pileEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deep candidates yet — start with \"Create round\"'**
  String get styleExplore_pileEmpty;
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
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
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
