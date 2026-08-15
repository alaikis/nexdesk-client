// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NEX';

  @override
  String get signInToNex => 'Sign in to NEX';

  @override
  String get accessRemoteDevices => 'Access your remote devices securely.';

  @override
  String get createAccount => 'Create your account';

  @override
  String get startControllingDevices =>
      'Start controlling devices with WebRTC.';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get requestTimedOut => 'Request timed out. Please try again.';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get hasAccountSignIn => 'Already have an account? Sign in';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmail => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get nameRequired => 'Name is required';

  @override
  String requestFailed(Object error) {
    return 'Request failed: $error';
  }

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get settings => 'Settings';

  @override
  String get security => 'Security';

  @override
  String get manageSecuritySettings => 'Manage connection security settings';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get manage2FASettings => 'Manage 2FA settings';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get viewPrivacyPolicy => 'View privacy policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get viewTermsOfService => 'View terms of service';

  @override
  String versionInfo(Object version) {
    return 'NEX version $version';
  }

  @override
  String cannotOpenLink(Object path) {
    return 'Cannot open link: $path';
  }

  @override
  String get magicPacketSent => 'Magic packet sent';

  @override
  String get failedToWakeDevice => 'Failed to wake device';

  @override
  String get failedToStartSession => 'Failed to start session';

  @override
  String get copied => 'Copied';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String failedToUpdateFavorite(Object error) {
    return 'Failed to update favorite: $error';
  }

  @override
  String renamedTo(Object name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String failedToRename(Object error) {
    return 'Failed to rename: $error';
  }

  @override
  String get editTags => 'Edit Tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String tagsUpdatedFor(Object name) {
    return 'Tags updated for $name';
  }

  @override
  String failedToUpdateTags(Object error) {
    return 'Failed to update tags: $error';
  }

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupName => 'Group name';

  @override
  String groupCreated(Object name) {
    return 'Group \"$name\" created';
  }

  @override
  String failedToCreateGroup(Object error) {
    return 'Failed to create group: $error';
  }

  @override
  String get renameGroup => 'Rename Group';

  @override
  String groupRenamed(Object name) {
    return 'Group renamed to \"$name\"';
  }

  @override
  String failedToRenameGroup(Object error) {
    return 'Failed to rename group: $error';
  }

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String deleteGroupConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String groupDeleted(Object name) {
    return 'Group \"$name\" deleted';
  }

  @override
  String failedToDeleteGroup(Object error) {
    return 'Failed to delete group: $error';
  }

  @override
  String get noGroupsAvailable => 'No groups available. Create one first.';

  @override
  String addToGroup(Object name) {
    return 'Add $name to group';
  }

  @override
  String addedToGroup(Object name) {
    return '$name added to group';
  }

  @override
  String failedToAddToGroup(Object error) {
    return 'Failed to add to group: $error';
  }

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String removeFromGroupConfirm(Object name) {
    return 'Remove $name from its group?';
  }

  @override
  String removedFromGroup(Object name) {
    return '$name removed from group';
  }

  @override
  String failedToRemoveFromGroup(Object error) {
    return 'Failed to remove from group: $error';
  }

  @override
  String get addToGroupCtx => 'Add to group';

  @override
  String get removeFromGroupCtx => 'Remove from group';

  @override
  String get renameCtx => 'Rename';

  @override
  String get editTagsCtx => 'Edit tags';

  @override
  String get renameDevice => 'Rename Device';

  @override
  String get deviceName => 'Device name';

  @override
  String get devices => 'Devices';

  @override
  String get sessions => 'Sessions';

  @override
  String get shares => 'Shares';

  @override
  String get searchDevices => 'Search devices...';

  @override
  String get groupManagement => 'Group management';

  @override
  String get createGroupMenu => 'Create group';

  @override
  String get create => 'Create';

  @override
  String get remove => 'Remove';

  @override
  String get paste => 'Paste';

  @override
  String get filterAll => 'All';

  @override
  String get filterUngrouped => 'Ungrouped';

  @override
  String get favorites => 'Favorites';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Unfavorite';

  @override
  String online(Object count) {
    return 'Online ($count)';
  }

  @override
  String offline(Object count) {
    return 'Offline ($count)';
  }

  @override
  String get osLabel => 'OS';

  @override
  String get statusLabel => 'Status';

  @override
  String get deviceCodeLabel => 'Device Code';

  @override
  String get enterCode => 'Enter code';

  @override
  String get control => 'Control';

  @override
  String get view => 'View';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get actions => 'Actions';

  @override
  String get connect => 'Connect';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get wakeDevice => 'Wake Device';

  @override
  String get restart => 'Restart';

  @override
  String get shareFiles => 'Share Files';

  @override
  String get editTagsAction => 'Edit Tags';

  @override
  String get restartCommandSent => 'Restart command sent';

  @override
  String get fileSharingComingSoon => 'File sharing coming soon';

  @override
  String get removeFromFavoritesTooltip => 'Remove from favorites';

  @override
  String get addToFavoritesTooltip => 'Add to favorites';

  @override
  String get close => 'Close';

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get thisDevice => 'This Device';

  @override
  String get clientIdLabel => 'Client ID';

  @override
  String get controlPasswordLabel => 'Control Password';

  @override
  String get set => 'Set';

  @override
  String get notSet => 'Not set';

  @override
  String get screenWall => 'Screen Wall';

  @override
  String get allDevices => 'All Devices';

  @override
  String sessionIdLabel(Object id) {
    return 'Session $id';
  }

  @override
  String get closeSession => 'Close session';

  @override
  String get quality => 'Quality';

  @override
  String get qualitySettings => 'Quality settings';

  @override
  String get hideScreen => 'Hide screen';

  @override
  String get privacy => 'Privacy';

  @override
  String get disablePrivacy => 'Disable privacy';

  @override
  String get enablePrivacy => 'Enable privacy';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get muteAudio => 'Mute audio';

  @override
  String get unmuteAudio => 'Unmute audio';

  @override
  String get files => 'Files';

  @override
  String get fileTransfers => 'File transfers';

  @override
  String get recordings => 'Recordings';

  @override
  String get record => 'Record';

  @override
  String get startRecording => 'Start recording';

  @override
  String get password => 'Password';

  @override
  String get sessionPassword => 'Session password';

  @override
  String get chat => 'Chat';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get print => 'Print';

  @override
  String get remotePrint => 'Remote print';

  @override
  String get camera => 'Camera';

  @override
  String get remoteCamera => 'Remote camera';

  @override
  String get terminal => 'Terminal';

  @override
  String get remoteTerminal => 'Remote terminal';

  @override
  String get whiteboard => 'Whiteboard';

  @override
  String get disableWhiteboard => 'Disable whiteboard';

  @override
  String get enableWhiteboard => 'Enable whiteboard';

  @override
  String get selectScreensToShare => 'Select screens to share';

  @override
  String get chooseDisplays =>
      'Choose one or more displays to control remotely.';

  @override
  String get selectAtLeastOneScreen => 'Select at least one screen';

  @override
  String get startSession => 'Start Session';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String failedAfterAttempts(Object attempts) {
    return 'Failed after $attempts attempts';
  }

  @override
  String get retry => 'Retry';

  @override
  String get returnToDevices => 'Return to devices';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String reconnectingAttempt(Object attempt) {
    return 'Reconnecting... (attempt $attempt)';
  }

  @override
  String get selectSharingSource => 'Select sharing source';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String shareScreens(Object screens) {
    return 'Share $screens';
  }

  @override
  String get windows => 'Windows';

  @override
  String get untitledWindow => 'Untitled Window';

  @override
  String windowSize(Object height, Object width) {
    return '$width×$height';
  }

  @override
  String get noWindowsDetected => 'No windows detected';

  @override
  String get screenCapturePermissionDenied =>
      'Screen capture permission denied';

  @override
  String get sessionPasswordTitle => 'Session Password';

  @override
  String get enterSessionPassword => 'Enter session password';

  @override
  String get join => 'Join';

  @override
  String get setSessionPasswordTitle => 'Set Session Password';

  @override
  String get enterPasswordHint => 'Enter password (leave empty to remove)';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String failedToSetPassword(Object error) {
    return 'Failed to set password: $error';
  }

  @override
  String get sendPrintJob => 'Send Print Job';

  @override
  String get format => 'Format';

  @override
  String get imagePng => 'Image (PNG)';

  @override
  String get pdf => 'PDF';

  @override
  String get text => 'Text';

  @override
  String get fileName => 'File name';

  @override
  String get captureAndSend => 'Capture & Send';

  @override
  String get printJobSent => 'Print job sent to controller';

  @override
  String sendFailed(Object error) {
    return 'Send failed: $error';
  }

  @override
  String get dropToSend => 'Drop to send';

  @override
  String queuedFiles(Object count) {
    return 'Queued $count file(s) for upload';
  }

  @override
  String get primaryLabel => 'PRIMARY';

  @override
  String get createShare => 'Create Share';

  @override
  String get shareName => 'Share Name';

  @override
  String get localPath => 'Local Path';

  @override
  String get deviceLabel => 'Device';

  @override
  String get shareCreated => 'Share created';

  @override
  String get shareDeleted => 'Share deleted';

  @override
  String get noSharesYet => 'No shares yet';

  @override
  String get streamQuality => 'Stream Quality';

  @override
  String get customSettings => 'Custom Settings';

  @override
  String get widthLabel => 'Width';

  @override
  String get heightLabel => 'Height';

  @override
  String get fpsLabel => 'FPS';

  @override
  String get bitrateLabel => 'Bitrate (kbps)';

  @override
  String get applyCustom => 'Apply Custom';

  @override
  String get fileTransfersTitle => 'File Transfers';

  @override
  String get noTransfersYet => 'No transfers yet';

  @override
  String get cancelTransfer => 'Cancel';

  @override
  String get retryTransfer => 'Retry';

  @override
  String get chatTitle => 'Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get sessionRecording => 'Session Recording';

  @override
  String get recording => 'Recording...';

  @override
  String get notRecording => 'Not recording';

  @override
  String recordingFailed(Object error) {
    return 'Recording failed: $error';
  }

  @override
  String get deleteRecording => 'Delete recording?';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get recordingsTitle => 'Recordings';

  @override
  String get noRecordingsYet => 'No recordings yet';

  @override
  String get clipboardTitle => 'Clipboard';

  @override
  String get noClipboardHistory => 'No clipboard history';

  @override
  String get copyToRemote => 'Copy to Remote';

  @override
  String get pasteText => 'Paste text';

  @override
  String get textLabel => 'Text';

  @override
  String get pasteFromRemote => 'Paste from Remote';

  @override
  String get copiedToRemote => 'Copied to remote';

  @override
  String get pastedFromRemote => 'Pasted from remote';

  @override
  String get remotePrintTitle => 'Remote Print';

  @override
  String get refresh => 'Refresh';

  @override
  String get selectPrinterFirst => 'Please select a printer first';

  @override
  String get printerLabel => 'Printer';

  @override
  String get noPrintJobs => 'No print jobs';

  @override
  String get printJob => 'Print';

  @override
  String get cancelJob => 'Cancel';

  @override
  String get saveJob => 'Save';

  @override
  String sentToPrinter(Object printer) {
    return 'Sent to $printer';
  }

  @override
  String get printFailed => 'Print failed';

  @override
  String cancelFailed(Object error) {
    return 'Cancel failed: $error';
  }

  @override
  String savedToFile(Object path) {
    return 'Saved to $path';
  }

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get remoteCameraTitle => 'Remote Camera';

  @override
  String cameraError(Object error) {
    return 'Camera error: $error';
  }

  @override
  String get remoteTerminalTitle => 'Remote Terminal';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get clear => 'Clear';

  @override
  String get terminalError => 'Terminal error';

  @override
  String get enterCommand => 'Enter command...';

  @override
  String get send => 'Send';

  @override
  String get signalingNotReady => 'Signaling not ready';

  @override
  String get noSessionHistory => 'No session history yet';

  @override
  String sessionLabel(Object id) {
    return 'Session $id';
  }

  @override
  String get twoFactorAuthTitle => 'Two-Factor Authentication';

  @override
  String get enterCodeHint =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get verify => 'Verify';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get enter6DigitCode => 'Please enter a 6-digit code';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get scanSecret => 'Scan this secret with your authenticator app';

  @override
  String get twoFactorEnabled => '2FA enabled';

  @override
  String get failedToEnable2FA => 'Failed to enable 2FA';

  @override
  String get twoFactorDisabled => '2FA disabled';

  @override
  String get failedToDisable2FA => 'Failed to disable 2FA';

  @override
  String get twoFactorIsEnabled => '2FA is enabled';

  @override
  String get twoFactorIsDisabled => '2FA is disabled';

  @override
  String get secretKey => 'Secret key:';

  @override
  String get manualEntryUrl => 'Manual entry URL:';

  @override
  String get setupAuthenticator => 'Setup Authenticator';

  @override
  String get enable2FA => 'Enable 2FA';

  @override
  String get disable2FA => 'Disable 2FA';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get connectionSecurity => 'Connection Security';

  @override
  String get lockPasswordEnabled => 'Lock password enabled';

  @override
  String get lockPasswordDisabled => 'Lock password disabled';

  @override
  String get newLockPassword => 'New lock password';

  @override
  String get setLockPassword => 'Set Lock Password';

  @override
  String get removeLockPassword => 'Remove Lock Password';

  @override
  String get lockPasswordSet => 'Lock password set';

  @override
  String get lockPasswordRemoved => 'Lock password removed';

  @override
  String get allowedUsers => 'Allowed Users';

  @override
  String get allowedUserIds => 'Allowed user IDs (comma separated)';

  @override
  String get allowedUsersExample => 'e.g. 1, 2, 3';

  @override
  String get saveAllowedUsers => 'Save Allowed Users';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get blockedUserIds => 'Blocked user IDs (comma separated)';

  @override
  String get blockedUsersExample => 'e.g. 4, 5';

  @override
  String get saveBlockedUsers => 'Save Blocked Users';

  @override
  String get connectionPermissions => 'Connection Permissions';

  @override
  String get lockPasswordInfo =>
      'When a lock password is set, remote connections must provide the password.';

  @override
  String get allowedUsersInfo =>
      'Allowed users restrict connections to only the specified users.';

  @override
  String get blockedUsersInfo =>
      'Blocked users prevent specific users from connecting.';

  @override
  String failed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get allowedUsersUpdated => 'Allowed users updated';

  @override
  String get blockedUsersUpdated => 'Blocked users updated';

  @override
  String get screenWallTitle => 'Screen Wall';

  @override
  String get grid2x2 => '2×2';

  @override
  String get grid3x3 => '3×3';

  @override
  String get grid4x4 => '4×4';

  @override
  String get addDevices => 'Add Devices';

  @override
  String get noDevicesInWall => 'No devices in screen wall';

  @override
  String get selectDevices => 'Select Devices';

  @override
  String get noDevicesAvailable => 'No devices available';

  @override
  String get done => 'Done';

  @override
  String get onlineStatus => 'Online';

  @override
  String get offlineStatus => 'Offline';

  @override
  String get waitingForStream => 'Waiting for stream...';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get penTool => 'Pen';

  @override
  String get eraserTool => 'Eraser';

  @override
  String get undo => 'Undo';

  @override
  String get clearAll => 'Clear';

  @override
  String get logout => 'Logout';

  @override
  String get noDevicesYet => 'No devices yet';

  @override
  String updateAvailable(Object current, Object version) {
    return 'Update available: $version (current: $current)';
  }

  @override
  String get updateMessage =>
      'A new version is available. Would you like to download it?';

  @override
  String get later => 'Later';

  @override
  String get download => 'Download';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get deviceNotFound => 'Device not found';

  @override
  String get recent => 'Recent';

  @override
  String get connectModeControl => 'Control';

  @override
  String get connectModeFile => 'File';

  @override
  String get connectModeView => 'View';

  @override
  String get connectModeCollab => 'Collab';

  @override
  String qualitySetTo(Object preset) {
    return 'Quality set to $preset';
  }

  @override
  String get customQualityApplied => 'Custom quality applied';

  @override
  String downloadLink(Object url) {
    return 'Download: $url';
  }

  @override
  String get emptyFolder => 'Empty folder';

  @override
  String get folder => 'Folder';

  @override
  String get bytes => 'bytes';

  @override
  String moreTags(Object count) {
    return '+$count';
  }
}
