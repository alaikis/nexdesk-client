import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NEX'**
  String get appName;

  /// No description provided for @signInToNex.
  ///
  /// In en, this message translates to:
  /// **'Sign in to NEX'**
  String get signInToNex;

  /// No description provided for @accessRemoteDevices.
  ///
  /// In en, this message translates to:
  /// **'Access your remote devices securely.'**
  String get accessRemoteDevices;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @startControllingDevices.
  ///
  /// In en, this message translates to:
  /// **'Start controlling devices with WebRTC.'**
  String get startControllingDevices;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimedOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountBtn;

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountSignUp;

  /// No description provided for @hasAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get hasAccountSignIn;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed: {error}'**
  String requestFailed(Object error);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @manageSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Manage connection security settings'**
  String get manageSecuritySettings;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @manage2FASettings.
  ///
  /// In en, this message translates to:
  /// **'Manage 2FA settings'**
  String get manage2FASettings;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View privacy policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @viewTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'View terms of service'**
  String get viewTermsOfService;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'NEX version {version}'**
  String versionInfo(Object version);

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link: {path}'**
  String cannotOpenLink(Object path);

  /// No description provided for @magicPacketSent.
  ///
  /// In en, this message translates to:
  /// **'Magic packet sent'**
  String get magicPacketSent;

  /// No description provided for @failedToWakeDevice.
  ///
  /// In en, this message translates to:
  /// **'Failed to wake device'**
  String get failedToWakeDevice;

  /// No description provided for @failedToStartSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to start session'**
  String get failedToStartSession;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @failedToUpdateFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite: {error}'**
  String failedToUpdateFavorite(Object error);

  /// No description provided for @renamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String renamedTo(Object name);

  /// No description provided for @failedToRename.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: {error}'**
  String failedToRename(Object error);

  /// No description provided for @editTags.
  ///
  /// In en, this message translates to:
  /// **'Edit Tags'**
  String get editTags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @tagsUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Tags updated for {name}'**
  String tagsUpdatedFor(Object name);

  /// No description provided for @failedToUpdateTags.
  ///
  /// In en, this message translates to:
  /// **'Failed to update tags: {error}'**
  String failedToUpdateTags(Object error);

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" created'**
  String groupCreated(Object name);

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group: {error}'**
  String failedToCreateGroup(Object error);

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get renameGroup;

  /// No description provided for @groupRenamed.
  ///
  /// In en, this message translates to:
  /// **'Group renamed to \"{name}\"'**
  String groupRenamed(Object name);

  /// No description provided for @failedToRenameGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename group: {error}'**
  String failedToRenameGroup(Object error);

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteGroupConfirm(Object name);

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" deleted'**
  String groupDeleted(Object name);

  /// No description provided for @failedToDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete group: {error}'**
  String failedToDeleteGroup(Object error);

  /// No description provided for @noGroupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No groups available. Create one first.'**
  String get noGroupsAvailable;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add {name} to group'**
  String addToGroup(Object name);

  /// No description provided for @addedToGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} added to group'**
  String addedToGroup(Object name);

  /// No description provided for @failedToAddToGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to group: {error}'**
  String failedToAddToGroup(Object error);

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @removeFromGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from its group?'**
  String removeFromGroupConfirm(Object name);

  /// No description provided for @removedFromGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from group'**
  String removedFromGroup(Object name);

  /// No description provided for @failedToRemoveFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from group: {error}'**
  String failedToRemoveFromGroup(Object error);

  /// No description provided for @addToGroupCtx.
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get addToGroupCtx;

  /// No description provided for @removeFromGroupCtx.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroupCtx;

  /// No description provided for @renameCtx.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameCtx;

  /// No description provided for @editTagsCtx.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get editTagsCtx;

  /// No description provided for @renameDevice.
  ///
  /// In en, this message translates to:
  /// **'Rename Device'**
  String get renameDevice;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @searchDevices.
  ///
  /// In en, this message translates to:
  /// **'Search devices...'**
  String get searchDevices;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group management'**
  String get groupManagement;

  /// No description provided for @createGroupMenu.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupMenu;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUngrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get filterUngrouped;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get unfavorite;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online ({count})'**
  String online(Object count);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline ({count})'**
  String offline(Object count);

  /// No description provided for @osLabel.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get osLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @deviceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Code'**
  String get deviceCodeLabel;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @control.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get control;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @wakeDevice.
  ///
  /// In en, this message translates to:
  /// **'Wake Device'**
  String get wakeDevice;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @shareFiles.
  ///
  /// In en, this message translates to:
  /// **'Share Files'**
  String get shareFiles;

  /// No description provided for @editTagsAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Tags'**
  String get editTagsAction;

  /// No description provided for @restartCommandSent.
  ///
  /// In en, this message translates to:
  /// **'Restart command sent'**
  String get restartCommandSent;

  /// No description provided for @fileSharingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'File sharing coming soon'**
  String get fileSharingComingSoon;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @addToFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesTooltip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @quickConnect.
  ///
  /// In en, this message translates to:
  /// **'Quick Connect'**
  String get quickConnect;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This Device'**
  String get thisDevice;

  /// No description provided for @clientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientIdLabel;

  /// No description provided for @controlPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Control Password'**
  String get controlPasswordLabel;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @screenWall.
  ///
  /// In en, this message translates to:
  /// **'Screen Wall'**
  String get screenWall;

  /// No description provided for @allDevices.
  ///
  /// In en, this message translates to:
  /// **'All Devices'**
  String get allDevices;

  /// No description provided for @sessionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Session {id}'**
  String sessionIdLabel(Object id);

  /// No description provided for @closeSession.
  ///
  /// In en, this message translates to:
  /// **'Close session'**
  String get closeSession;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualitySettings.
  ///
  /// In en, this message translates to:
  /// **'Quality settings'**
  String get qualitySettings;

  /// No description provided for @hideScreen.
  ///
  /// In en, this message translates to:
  /// **'Hide screen'**
  String get hideScreen;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @disablePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Disable privacy'**
  String get disablePrivacy;

  /// No description provided for @enablePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Enable privacy'**
  String get enablePrivacy;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @muteAudio.
  ///
  /// In en, this message translates to:
  /// **'Mute audio'**
  String get muteAudio;

  /// No description provided for @unmuteAudio.
  ///
  /// In en, this message translates to:
  /// **'Unmute audio'**
  String get unmuteAudio;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @fileTransfers.
  ///
  /// In en, this message translates to:
  /// **'File transfers'**
  String get fileTransfers;

  /// No description provided for @recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordings;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sessionPassword.
  ///
  /// In en, this message translates to:
  /// **'Session password'**
  String get sessionPassword;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @remotePrint.
  ///
  /// In en, this message translates to:
  /// **'Remote print'**
  String get remotePrint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @remoteCamera.
  ///
  /// In en, this message translates to:
  /// **'Remote camera'**
  String get remoteCamera;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @remoteTerminal.
  ///
  /// In en, this message translates to:
  /// **'Remote terminal'**
  String get remoteTerminal;

  /// No description provided for @whiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get whiteboard;

  /// No description provided for @disableWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Disable whiteboard'**
  String get disableWhiteboard;

  /// No description provided for @enableWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Enable whiteboard'**
  String get enableWhiteboard;

  /// No description provided for @selectScreensToShare.
  ///
  /// In en, this message translates to:
  /// **'Select screens to share'**
  String get selectScreensToShare;

  /// No description provided for @chooseDisplays.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more displays to control remotely.'**
  String get chooseDisplays;

  /// No description provided for @selectAtLeastOneScreen.
  ///
  /// In en, this message translates to:
  /// **'Select at least one screen'**
  String get selectAtLeastOneScreen;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLost;

  /// No description provided for @failedAfterAttempts.
  ///
  /// In en, this message translates to:
  /// **'Failed after {attempts} attempts'**
  String failedAfterAttempts(Object attempts);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @returnToDevices.
  ///
  /// In en, this message translates to:
  /// **'Return to devices'**
  String get returnToDevices;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @reconnectingAttempt.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting... (attempt {attempt})'**
  String reconnectingAttempt(Object attempt);

  /// No description provided for @selectSharingSource.
  ///
  /// In en, this message translates to:
  /// **'Select sharing source'**
  String get selectSharingSource;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// No description provided for @shareScreens.
  ///
  /// In en, this message translates to:
  /// **'Share {screens}'**
  String shareScreens(Object screens);

  /// No description provided for @windows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get windows;

  /// No description provided for @untitledWindow.
  ///
  /// In en, this message translates to:
  /// **'Untitled Window'**
  String get untitledWindow;

  /// No description provided for @windowSize.
  ///
  /// In en, this message translates to:
  /// **'{width}×{height}'**
  String windowSize(Object height, Object width);

  /// No description provided for @noWindowsDetected.
  ///
  /// In en, this message translates to:
  /// **'No windows detected'**
  String get noWindowsDetected;

  /// No description provided for @screenCapturePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Screen capture permission denied'**
  String get screenCapturePermissionDenied;

  /// No description provided for @sessionPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Password'**
  String get sessionPasswordTitle;

  /// No description provided for @enterSessionPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter session password'**
  String get enterSessionPassword;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @setSessionPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Session Password'**
  String get setSessionPasswordTitle;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password (leave empty to remove)'**
  String get enterPasswordHint;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @failedToSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to set password: {error}'**
  String failedToSetPassword(Object error);

  /// No description provided for @sendPrintJob.
  ///
  /// In en, this message translates to:
  /// **'Send Print Job'**
  String get sendPrintJob;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @imagePng.
  ///
  /// In en, this message translates to:
  /// **'Image (PNG)'**
  String get imagePng;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @captureAndSend.
  ///
  /// In en, this message translates to:
  /// **'Capture & Send'**
  String get captureAndSend;

  /// No description provided for @printJobSent.
  ///
  /// In en, this message translates to:
  /// **'Print job sent to controller'**
  String get printJobSent;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String sendFailed(Object error);

  /// No description provided for @dropToSend.
  ///
  /// In en, this message translates to:
  /// **'Drop to send'**
  String get dropToSend;

  /// No description provided for @queuedFiles.
  ///
  /// In en, this message translates to:
  /// **'Queued {count} file(s) for upload'**
  String queuedFiles(Object count);

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get primaryLabel;

  /// No description provided for @createShare.
  ///
  /// In en, this message translates to:
  /// **'Create Share'**
  String get createShare;

  /// No description provided for @shareName.
  ///
  /// In en, this message translates to:
  /// **'Share Name'**
  String get shareName;

  /// No description provided for @localPath.
  ///
  /// In en, this message translates to:
  /// **'Local Path'**
  String get localPath;

  /// No description provided for @deviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceLabel;

  /// No description provided for @shareCreated.
  ///
  /// In en, this message translates to:
  /// **'Share created'**
  String get shareCreated;

  /// No description provided for @shareDeleted.
  ///
  /// In en, this message translates to:
  /// **'Share deleted'**
  String get shareDeleted;

  /// No description provided for @noSharesYet.
  ///
  /// In en, this message translates to:
  /// **'No shares yet'**
  String get noSharesYet;

  /// No description provided for @streamQuality.
  ///
  /// In en, this message translates to:
  /// **'Stream Quality'**
  String get streamQuality;

  /// No description provided for @customSettings.
  ///
  /// In en, this message translates to:
  /// **'Custom Settings'**
  String get customSettings;

  /// No description provided for @widthLabel.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get widthLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @fpsLabel.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get fpsLabel;

  /// No description provided for @bitrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitrate (kbps)'**
  String get bitrateLabel;

  /// No description provided for @applyCustom.
  ///
  /// In en, this message translates to:
  /// **'Apply Custom'**
  String get applyCustom;

  /// No description provided for @fileTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'File Transfers'**
  String get fileTransfersTitle;

  /// No description provided for @noTransfersYet.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet'**
  String get noTransfersYet;

  /// No description provided for @cancelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTransfer;

  /// No description provided for @retryTransfer.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryTransfer;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @sessionRecording.
  ///
  /// In en, this message translates to:
  /// **'Session Recording'**
  String get sessionRecording;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @notRecording.
  ///
  /// In en, this message translates to:
  /// **'Not recording'**
  String get notRecording;

  /// No description provided for @recordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed: {error}'**
  String recordingFailed(Object error);

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete recording?'**
  String get deleteRecording;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @recordingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordingsTitle;

  /// No description provided for @noRecordingsYet.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordingsYet;

  /// No description provided for @clipboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboardTitle;

  /// No description provided for @noClipboardHistory.
  ///
  /// In en, this message translates to:
  /// **'No clipboard history'**
  String get noClipboardHistory;

  /// No description provided for @copyToRemote.
  ///
  /// In en, this message translates to:
  /// **'Copy to Remote'**
  String get copyToRemote;

  /// No description provided for @pasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get pasteText;

  /// No description provided for @textLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textLabel;

  /// No description provided for @pasteFromRemote.
  ///
  /// In en, this message translates to:
  /// **'Paste from Remote'**
  String get pasteFromRemote;

  /// No description provided for @copiedToRemote.
  ///
  /// In en, this message translates to:
  /// **'Copied to remote'**
  String get copiedToRemote;

  /// No description provided for @pastedFromRemote.
  ///
  /// In en, this message translates to:
  /// **'Pasted from remote'**
  String get pastedFromRemote;

  /// No description provided for @remotePrintTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Print'**
  String get remotePrintTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @selectPrinterFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a printer first'**
  String get selectPrinterFirst;

  /// No description provided for @printerLabel.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printerLabel;

  /// No description provided for @noPrintJobs.
  ///
  /// In en, this message translates to:
  /// **'No print jobs'**
  String get noPrintJobs;

  /// No description provided for @printJob.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printJob;

  /// No description provided for @cancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelJob;

  /// No description provided for @saveJob.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveJob;

  /// No description provided for @sentToPrinter.
  ///
  /// In en, this message translates to:
  /// **'Sent to {printer}'**
  String sentToPrinter(Object printer);

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed'**
  String get printFailed;

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {error}'**
  String cancelFailed(Object error);

  /// No description provided for @savedToFile.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedToFile(Object path);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @remoteCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Camera'**
  String get remoteCameraTitle;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String cameraError(Object error);

  /// No description provided for @remoteTerminalTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Terminal'**
  String get remoteTerminalTitle;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @terminalError.
  ///
  /// In en, this message translates to:
  /// **'Terminal error'**
  String get terminalError;

  /// No description provided for @enterCommand.
  ///
  /// In en, this message translates to:
  /// **'Enter command...'**
  String get enterCommand;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @signalingNotReady.
  ///
  /// In en, this message translates to:
  /// **'Signaling not ready'**
  String get signalingNotReady;

  /// No description provided for @noSessionHistory.
  ///
  /// In en, this message translates to:
  /// **'No session history yet'**
  String get noSessionHistory;

  /// No description provided for @sessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session {id}'**
  String sessionLabel(Object id);

  /// No description provided for @twoFactorAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthTitle;

  /// No description provided for @enterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get enterCodeHint;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 6-digit code'**
  String get enter6DigitCode;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @scanSecret.
  ///
  /// In en, this message translates to:
  /// **'Scan this secret with your authenticator app'**
  String get scanSecret;

  /// No description provided for @twoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA enabled'**
  String get twoFactorEnabled;

  /// No description provided for @failedToEnable2FA.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable 2FA'**
  String get failedToEnable2FA;

  /// No description provided for @twoFactorDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA disabled'**
  String get twoFactorDisabled;

  /// No description provided for @failedToDisable2FA.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable 2FA'**
  String get failedToDisable2FA;

  /// No description provided for @twoFactorIsEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA is enabled'**
  String get twoFactorIsEnabled;

  /// No description provided for @twoFactorIsDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA is disabled'**
  String get twoFactorIsDisabled;

  /// No description provided for @secretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret key:'**
  String get secretKey;

  /// No description provided for @manualEntryUrl.
  ///
  /// In en, this message translates to:
  /// **'Manual entry URL:'**
  String get manualEntryUrl;

  /// No description provided for @setupAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Setup Authenticator'**
  String get setupAuthenticator;

  /// No description provided for @enable2FA.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get enable2FA;

  /// No description provided for @disable2FA.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get disable2FA;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @connectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Connection Security'**
  String get connectionSecurity;

  /// No description provided for @lockPasswordEnabled.
  ///
  /// In en, this message translates to:
  /// **'Lock password enabled'**
  String get lockPasswordEnabled;

  /// No description provided for @lockPasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Lock password disabled'**
  String get lockPasswordDisabled;

  /// No description provided for @newLockPassword.
  ///
  /// In en, this message translates to:
  /// **'New lock password'**
  String get newLockPassword;

  /// No description provided for @setLockPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Lock Password'**
  String get setLockPassword;

  /// No description provided for @removeLockPassword.
  ///
  /// In en, this message translates to:
  /// **'Remove Lock Password'**
  String get removeLockPassword;

  /// No description provided for @lockPasswordSet.
  ///
  /// In en, this message translates to:
  /// **'Lock password set'**
  String get lockPasswordSet;

  /// No description provided for @lockPasswordRemoved.
  ///
  /// In en, this message translates to:
  /// **'Lock password removed'**
  String get lockPasswordRemoved;

  /// No description provided for @allowedUsers.
  ///
  /// In en, this message translates to:
  /// **'Allowed Users'**
  String get allowedUsers;

  /// No description provided for @allowedUserIds.
  ///
  /// In en, this message translates to:
  /// **'Allowed user IDs (comma separated)'**
  String get allowedUserIds;

  /// No description provided for @allowedUsersExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1, 2, 3'**
  String get allowedUsersExample;

  /// No description provided for @saveAllowedUsers.
  ///
  /// In en, this message translates to:
  /// **'Save Allowed Users'**
  String get saveAllowedUsers;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @blockedUserIds.
  ///
  /// In en, this message translates to:
  /// **'Blocked user IDs (comma separated)'**
  String get blockedUserIds;

  /// No description provided for @blockedUsersExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4, 5'**
  String get blockedUsersExample;

  /// No description provided for @saveBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Save Blocked Users'**
  String get saveBlockedUsers;

  /// No description provided for @connectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Connection Permissions'**
  String get connectionPermissions;

  /// No description provided for @lockPasswordInfo.
  ///
  /// In en, this message translates to:
  /// **'When a lock password is set, remote connections must provide the password.'**
  String get lockPasswordInfo;

  /// No description provided for @allowedUsersInfo.
  ///
  /// In en, this message translates to:
  /// **'Allowed users restrict connections to only the specified users.'**
  String get allowedUsersInfo;

  /// No description provided for @blockedUsersInfo.
  ///
  /// In en, this message translates to:
  /// **'Blocked users prevent specific users from connecting.'**
  String get blockedUsersInfo;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failed(Object error);

  /// No description provided for @allowedUsersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Allowed users updated'**
  String get allowedUsersUpdated;

  /// No description provided for @blockedUsersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Blocked users updated'**
  String get blockedUsersUpdated;

  /// No description provided for @screenWallTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Wall'**
  String get screenWallTitle;

  /// No description provided for @grid2x2.
  ///
  /// In en, this message translates to:
  /// **'2×2'**
  String get grid2x2;

  /// No description provided for @grid3x3.
  ///
  /// In en, this message translates to:
  /// **'3×3'**
  String get grid3x3;

  /// No description provided for @grid4x4.
  ///
  /// In en, this message translates to:
  /// **'4×4'**
  String get grid4x4;

  /// No description provided for @addDevices.
  ///
  /// In en, this message translates to:
  /// **'Add Devices'**
  String get addDevices;

  /// No description provided for @noDevicesInWall.
  ///
  /// In en, this message translates to:
  /// **'No devices in screen wall'**
  String get noDevicesInWall;

  /// No description provided for @selectDevices.
  ///
  /// In en, this message translates to:
  /// **'Select Devices'**
  String get selectDevices;

  /// No description provided for @noDevicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No devices available'**
  String get noDevicesAvailable;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// No description provided for @waitingForStream.
  ///
  /// In en, this message translates to:
  /// **'Waiting for stream...'**
  String get waitingForStream;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @penTool.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get penTool;

  /// No description provided for @eraserTool.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraserTool;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAll;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @noDevicesYet.
  ///
  /// In en, this message translates to:
  /// **'No devices yet'**
  String get noDevicesYet;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version} (current: {current})'**
  String updateAvailable(Object current, Object version);

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Would you like to download it?'**
  String get updateMessage;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @deviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device not found'**
  String get deviceNotFound;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @connectModeControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get connectModeControl;

  /// No description provided for @connectModeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get connectModeFile;

  /// No description provided for @connectModeView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get connectModeView;

  /// No description provided for @connectModeCollab.
  ///
  /// In en, this message translates to:
  /// **'Collab'**
  String get connectModeCollab;

  /// No description provided for @qualitySetTo.
  ///
  /// In en, this message translates to:
  /// **'Quality set to {preset}'**
  String qualitySetTo(Object preset);

  /// No description provided for @customQualityApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom quality applied'**
  String get customQualityApplied;

  /// No description provided for @downloadLink.
  ///
  /// In en, this message translates to:
  /// **'Download: {url}'**
  String downloadLink(Object url);

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyFolder;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @bytes.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get bytes;

  /// No description provided for @moreTags.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreTags(Object count);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
