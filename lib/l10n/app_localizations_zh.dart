// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'NEX';

  @override
  String get signInToNex => '登录 NEX';

  @override
  String get accessRemoteDevices => '安全访问您的远程设备。';

  @override
  String get createAccount => '创建您的账户';

  @override
  String get startControllingDevices => '开始使用 WebRTC 控制设备。';

  @override
  String get nameLabel => '姓名';

  @override
  String get emailLabel => '邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get requestTimedOut => '请求超时，请重试。';

  @override
  String get signIn => '登录';

  @override
  String get createAccountBtn => '创建账户';

  @override
  String get noAccountSignUp => '还没有账户？立即注册';

  @override
  String get hasAccountSignIn => '已有账户？立即登录';

  @override
  String get emailRequired => '请输入邮箱';

  @override
  String get validEmail => '请输入有效的邮箱';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get passwordMinLength => '密码至少需要 8 个字符';

  @override
  String get nameRequired => '请输入姓名';

  @override
  String requestFailed(Object error) {
    return '请求失败：$error';
  }

  @override
  String get loginFailed => '登录失败';

  @override
  String get registrationFailed => '注册失败';

  @override
  String get settings => '设置';

  @override
  String get security => '安全';

  @override
  String get manageSecuritySettings => '管理连接安全设置';

  @override
  String get twoFactorAuth => '双因素认证';

  @override
  String get manage2FASettings => '管理 2FA 设置';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get viewPrivacyPolicy => '查看隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get viewTermsOfService => '查看服务条款';

  @override
  String versionInfo(Object version) {
    return 'NEX 版本 $version';
  }

  @override
  String cannotOpenLink(Object path) {
    return '无法打开链接：$path';
  }

  @override
  String get magicPacketSent => '已发送魔法包';

  @override
  String get failedToWakeDevice => '唤醒设备失败';

  @override
  String get failedToStartSession => '启动会话失败';

  @override
  String get copied => '已复制';

  @override
  String get addedToFavorites => '已添加到收藏';

  @override
  String get removedFromFavorites => '已从收藏中移除';

  @override
  String failedToUpdateFavorite(Object error) {
    return '更新收藏失败：$error';
  }

  @override
  String renamedTo(Object name) {
    return '已重命名为 \"$name\"';
  }

  @override
  String failedToRename(Object error) {
    return '重命名失败：$error';
  }

  @override
  String get editTags => '编辑标签';

  @override
  String get addTag => '添加标签';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String tagsUpdatedFor(Object name) {
    return '已更新 $name 的标签';
  }

  @override
  String failedToUpdateTags(Object error) {
    return '更新标签失败：$error';
  }

  @override
  String get createGroup => '创建分组';

  @override
  String get groupName => '分组名称';

  @override
  String groupCreated(Object name) {
    return '分组 \"$name\" 已创建';
  }

  @override
  String failedToCreateGroup(Object error) {
    return '创建分组失败：$error';
  }

  @override
  String get renameGroup => '重命名分组';

  @override
  String groupRenamed(Object name) {
    return '分组已重命名为 \"$name\"';
  }

  @override
  String failedToRenameGroup(Object error) {
    return '重命名分组失败：$error';
  }

  @override
  String get deleteGroup => '删除分组';

  @override
  String deleteGroupConfirm(Object name) {
    return '确定要删除 \"$name\" 吗？';
  }

  @override
  String groupDeleted(Object name) {
    return '分组 \"$name\" 已删除';
  }

  @override
  String failedToDeleteGroup(Object error) {
    return '删除分组失败：$error';
  }

  @override
  String get noGroupsAvailable => '没有可用的分组，请先创建一个。';

  @override
  String addToGroup(Object name) {
    return '将 $name 添加到分组';
  }

  @override
  String addedToGroup(Object name) {
    return '$name 已添加到分组';
  }

  @override
  String failedToAddToGroup(Object error) {
    return '添加到分组失败：$error';
  }

  @override
  String get removeFromGroup => '从分组中移除';

  @override
  String removeFromGroupConfirm(Object name) {
    return '确定要从分组中移除 $name 吗？';
  }

  @override
  String removedFromGroup(Object name) {
    return '$name 已从分组中移除';
  }

  @override
  String failedToRemoveFromGroup(Object error) {
    return '从分组移除失败：$error';
  }

  @override
  String get addToGroupCtx => '添加到分组';

  @override
  String get removeFromGroupCtx => '从分组移除';

  @override
  String get renameCtx => '重命名';

  @override
  String get editTagsCtx => '编辑标签';

  @override
  String get renameDevice => '重命名设备';

  @override
  String get deviceName => '设备名称';

  @override
  String get devices => '设备';

  @override
  String get sessions => '会话';

  @override
  String get shares => '共享';

  @override
  String get searchDevices => '搜索设备...';

  @override
  String get groupManagement => '分组管理';

  @override
  String get createGroupMenu => '创建分组';

  @override
  String get create => 'Create';

  @override
  String get remove => 'Remove';

  @override
  String get paste => '粘贴';

  @override
  String get filterAll => '全部';

  @override
  String get filterUngrouped => '未分组';

  @override
  String get favorites => '收藏';

  @override
  String selectedCount(Object count) {
    return '已选择 $count 项';
  }

  @override
  String get favorite => '收藏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String online(Object count) {
    return '在线 ($count)';
  }

  @override
  String offline(Object count) {
    return '离线 ($count)';
  }

  @override
  String get osLabel => '操作系统';

  @override
  String get statusLabel => '状态';

  @override
  String get deviceCodeLabel => '设备码';

  @override
  String get enterCode => '输入代码';

  @override
  String get control => '控制';

  @override
  String get view => '查看';

  @override
  String get tagsLabel => '标签';

  @override
  String get actions => '操作';

  @override
  String get connect => '连接';

  @override
  String get copyCode => '复制代码';

  @override
  String get wakeDevice => '唤醒设备';

  @override
  String get restart => '重启';

  @override
  String get shareFiles => '共享文件';

  @override
  String get editTagsAction => '编辑标签';

  @override
  String get restartCommandSent => '已发送重启命令';

  @override
  String get fileSharingComingSoon => '文件共享即将推出';

  @override
  String get removeFromFavoritesTooltip => '从收藏中移除';

  @override
  String get addToFavoritesTooltip => '添加到收藏';

  @override
  String get close => '关闭';

  @override
  String get quickConnect => '快速连接';

  @override
  String get thisDevice => '本设备';

  @override
  String get clientIdLabel => '客户端 ID';

  @override
  String get controlPasswordLabel => '控制密码';

  @override
  String get set => '已设置';

  @override
  String get notSet => '未设置';

  @override
  String get screenWall => '屏幕墙';

  @override
  String get allDevices => '所有设备';

  @override
  String sessionIdLabel(Object id) {
    return '会话 $id';
  }

  @override
  String get closeSession => '关闭会话';

  @override
  String get quality => '画质';

  @override
  String get qualitySettings => '画质设置';

  @override
  String get hideScreen => '隐藏屏幕';

  @override
  String get privacy => '隐私';

  @override
  String get disablePrivacy => '关闭隐私模式';

  @override
  String get enablePrivacy => '开启隐私模式';

  @override
  String get mute => '静音';

  @override
  String get unmute => '取消静音';

  @override
  String get muteAudio => '静音音频';

  @override
  String get unmuteAudio => '取消静音音频';

  @override
  String get files => '文件';

  @override
  String get fileTransfers => '文件传输';

  @override
  String get recordings => '录制';

  @override
  String get record => '录制';

  @override
  String get startRecording => '开始录制';

  @override
  String get password => '密码';

  @override
  String get sessionPassword => '会话密码';

  @override
  String get chat => '聊天';

  @override
  String get clipboard => '剪贴板';

  @override
  String get print => '打印';

  @override
  String get remotePrint => '远程打印';

  @override
  String get camera => '摄像头';

  @override
  String get remoteCamera => '远程摄像头';

  @override
  String get terminal => '终端';

  @override
  String get remoteTerminal => '远程终端';

  @override
  String get whiteboard => '白板';

  @override
  String get disableWhiteboard => '关闭白板';

  @override
  String get enableWhiteboard => '开启白板';

  @override
  String get selectScreensToShare => '选择要共享的屏幕';

  @override
  String get chooseDisplays => '选择一个或多个显示器进行远程控制。';

  @override
  String get selectAtLeastOneScreen => '请至少选择一个屏幕';

  @override
  String get startSession => '开始会话';

  @override
  String get connectionLost => '连接丢失';

  @override
  String failedAfterAttempts(Object attempts) {
    return '在 $attempts 次尝试后失败';
  }

  @override
  String get retry => '重试';

  @override
  String get returnToDevices => '返回设备列表';

  @override
  String get reconnecting => '重新连接中...';

  @override
  String reconnectingAttempt(Object attempt) {
    return '重新连接中... (第 $attempt 次)';
  }

  @override
  String get selectSharingSource => '选择共享源';

  @override
  String get fullScreen => '全屏';

  @override
  String shareScreens(Object screens) {
    return '共享 $screens';
  }

  @override
  String get windows => '窗口';

  @override
  String get untitledWindow => '未命名窗口';

  @override
  String windowSize(Object height, Object width) {
    return '$width×$height';
  }

  @override
  String get noWindowsDetected => '未检测到窗口';

  @override
  String get screenCapturePermissionDenied => '屏幕录制权限被拒绝';

  @override
  String get sessionPasswordTitle => '会话密码';

  @override
  String get enterSessionPassword => '请输入会话密码';

  @override
  String get join => '加入';

  @override
  String get setSessionPasswordTitle => '设置会话密码';

  @override
  String get enterPasswordHint => '输入密码（留空则移除）';

  @override
  String get passwordUpdated => '密码已更新';

  @override
  String failedToSetPassword(Object error) {
    return '设置密码失败：$error';
  }

  @override
  String get sendPrintJob => '发送打印任务';

  @override
  String get format => '格式';

  @override
  String get imagePng => '图片 (PNG)';

  @override
  String get pdf => 'PDF';

  @override
  String get text => '文本';

  @override
  String get fileName => '文件名';

  @override
  String get captureAndSend => '捕获并发送';

  @override
  String get printJobSent => '打印任务已发送至控制器';

  @override
  String sendFailed(Object error) {
    return '发送失败：$error';
  }

  @override
  String get dropToSend => '拖放到此处发送';

  @override
  String queuedFiles(Object count) {
    return '已排队 $count 个文件待上传';
  }

  @override
  String get primaryLabel => '主显示器';

  @override
  String get createShare => '创建共享';

  @override
  String get shareName => '共享名称';

  @override
  String get localPath => '本地路径';

  @override
  String get deviceLabel => '设备';

  @override
  String get shareCreated => '共享已创建';

  @override
  String get shareDeleted => '共享已删除';

  @override
  String get noSharesYet => '还没有共享';

  @override
  String get streamQuality => '流画质';

  @override
  String get customSettings => '自定义设置';

  @override
  String get widthLabel => '宽度';

  @override
  String get heightLabel => '高度';

  @override
  String get fpsLabel => '帧率';

  @override
  String get bitrateLabel => '码率 (kbps)';

  @override
  String get applyCustom => '应用自定义';

  @override
  String get fileTransfersTitle => '文件传输';

  @override
  String get noTransfersYet => '还没有传输';

  @override
  String get cancelTransfer => '取消';

  @override
  String get retryTransfer => '重试';

  @override
  String get chatTitle => '聊天';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get sessionRecording => '会话录制';

  @override
  String get recording => '录制中...';

  @override
  String get notRecording => '未录制';

  @override
  String recordingFailed(Object error) {
    return '录制失败：$error';
  }

  @override
  String get deleteRecording => '删除录制？';

  @override
  String get cannotBeUndone => '此操作无法撤销。';

  @override
  String get delete => '删除';

  @override
  String get recordingsTitle => '录制';

  @override
  String get noRecordingsYet => '还没有录制';

  @override
  String get clipboardTitle => '剪贴板';

  @override
  String get noClipboardHistory => '没有剪贴板历史';

  @override
  String get copyToRemote => '复制到远程';

  @override
  String get pasteText => '粘贴文本';

  @override
  String get textLabel => '文本';

  @override
  String get pasteFromRemote => '从远程粘贴';

  @override
  String get copiedToRemote => '已复制到远程';

  @override
  String get pastedFromRemote => '已从远程粘贴';

  @override
  String get remotePrintTitle => '远程打印';

  @override
  String get refresh => '刷新';

  @override
  String get selectPrinterFirst => '请先选择打印机';

  @override
  String get printerLabel => '打印机';

  @override
  String get noPrintJobs => '没有打印任务';

  @override
  String get printJob => '打印';

  @override
  String get cancelJob => '取消';

  @override
  String get saveJob => '保存';

  @override
  String sentToPrinter(Object printer) {
    return '已发送至 $printer';
  }

  @override
  String get printFailed => '打印失败';

  @override
  String cancelFailed(Object error) {
    return '取消失败：$error';
  }

  @override
  String savedToFile(Object path) {
    return '已保存至 $path';
  }

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get remoteCameraTitle => '远程摄像头';

  @override
  String cameraError(Object error) {
    return '摄像头错误：$error';
  }

  @override
  String get remoteTerminalTitle => '远程终端';

  @override
  String get reconnect => '重新连接';

  @override
  String get clear => '清空';

  @override
  String get terminalError => '终端错误';

  @override
  String get enterCommand => '输入命令...';

  @override
  String get send => '发送';

  @override
  String get signalingNotReady => '信令未就绪';

  @override
  String get noSessionHistory => '还没有会话历史';

  @override
  String sessionLabel(Object id) {
    return '会话 $id';
  }

  @override
  String get twoFactorAuthTitle => '双因素认证';

  @override
  String get enterCodeHint => '请输入身份验证器应用中的 6 位验证码。';

  @override
  String get verify => '验证';

  @override
  String get backToSignIn => '返回登录';

  @override
  String get enter6DigitCode => '请输入 6 位验证码';

  @override
  String get verificationFailed => '验证失败';

  @override
  String get scanSecret => '使用您的身份验证器应用扫描此密钥';

  @override
  String get twoFactorEnabled => '2FA 已启用';

  @override
  String get failedToEnable2FA => '启用 2FA 失败';

  @override
  String get twoFactorDisabled => '2FA 已禁用';

  @override
  String get failedToDisable2FA => '禁用 2FA 失败';

  @override
  String get twoFactorIsEnabled => '2FA 已启用';

  @override
  String get twoFactorIsDisabled => '2FA 已禁用';

  @override
  String get secretKey => '密钥：';

  @override
  String get manualEntryUrl => '手动输入 URL：';

  @override
  String get setupAuthenticator => '设置身份验证器';

  @override
  String get enable2FA => '启用 2FA';

  @override
  String get disable2FA => '禁用 2FA';

  @override
  String get securitySettings => '安全设置';

  @override
  String get connectionSecurity => '连接安全';

  @override
  String get lockPasswordEnabled => '锁定密码已启用';

  @override
  String get lockPasswordDisabled => '锁定密码已禁用';

  @override
  String get newLockPassword => '新锁定密码';

  @override
  String get setLockPassword => '设置锁定密码';

  @override
  String get removeLockPassword => '移除锁定密码';

  @override
  String get lockPasswordSet => '锁定密码已设置';

  @override
  String get lockPasswordRemoved => '锁定密码已移除';

  @override
  String get allowedUsers => '允许用户';

  @override
  String get allowedUserIds => '允许的用户 ID（逗号分隔）';

  @override
  String get allowedUsersExample => '例如：1, 2, 3';

  @override
  String get saveAllowedUsers => '保存允许用户';

  @override
  String get blockedUsers => '阻止用户';

  @override
  String get blockedUserIds => '阻止的用户 ID（逗号分隔）';

  @override
  String get blockedUsersExample => '例如：4, 5';

  @override
  String get saveBlockedUsers => '保存阻止用户';

  @override
  String get connectionPermissions => '连接权限';

  @override
  String get lockPasswordInfo => '当设置锁定密码时，远程连接必须提供密码。';

  @override
  String get allowedUsersInfo => '允许用户将连接限制为仅指定的用户。';

  @override
  String get blockedUsersInfo => '阻止用户防止特定用户连接。';

  @override
  String failed(Object error) {
    return '失败：$error';
  }

  @override
  String get allowedUsersUpdated => '允许用户已更新';

  @override
  String get blockedUsersUpdated => '阻止用户已更新';

  @override
  String get screenWallTitle => '屏幕墙';

  @override
  String get grid2x2 => '2×2';

  @override
  String get grid3x3 => '3×3';

  @override
  String get grid4x4 => '4×4';

  @override
  String get addDevices => '添加设备';

  @override
  String get noDevicesInWall => '屏幕墙中没有设备';

  @override
  String get selectDevices => '选择设备';

  @override
  String get noDevicesAvailable => '没有可用的设备';

  @override
  String get done => '完成';

  @override
  String get onlineStatus => '在线';

  @override
  String get offlineStatus => '离线';

  @override
  String get waitingForStream => '等待流...';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get penTool => '画笔';

  @override
  String get eraserTool => '橡皮擦';

  @override
  String get undo => '撤销';

  @override
  String get clearAll => '清空';

  @override
  String get logout => '退出登录';

  @override
  String get noDevicesYet => '还没有设备';

  @override
  String updateAvailable(Object current, Object version) {
    return '发现更新：$version (当前：$current)';
  }

  @override
  String get updateMessage => '发现新版本，是否立即下载？';

  @override
  String get later => '稍后';

  @override
  String get download => '下载';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get deviceNotFound => '未找到设备';

  @override
  String get recent => '最近使用';

  @override
  String get connectModeControl => '控制';

  @override
  String get connectModeFile => '文件';

  @override
  String get connectModeView => '查看';

  @override
  String get connectModeCollab => '协作';

  @override
  String qualitySetTo(Object preset) {
    return '画质已设为 $preset';
  }

  @override
  String get customQualityApplied => '自定义画质已应用';

  @override
  String downloadLink(Object url) {
    return '下载：$url';
  }

  @override
  String get emptyFolder => '空文件夹';

  @override
  String get folder => '文件夹';

  @override
  String get bytes => '字节';

  @override
  String moreTags(Object count) {
    return '+$count';
  }
}
