import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/webrtc_service.dart';
import '../../core/screen_service.dart';
import '../../core/signaling_service.dart';
import '../../core/secure_storage_service.dart';
import '../../core/e2ee_service.dart';
import '../../config/app_config.dart';
import '../../core/error_handler.dart';
import '../../core/screen_capture_service.dart';
import '../../core/api_client.dart';
import '../../core/input_relay_service.dart';
import '../../core/quality_service.dart';
import '../../core/drag_drop_service.dart';
import '../session/session_provider.dart';
import 'screen_selector.dart';
import 'file_transfer_screen.dart';
import 'clipboard_screen.dart';
import 'quality_settings_sheet.dart';
import 'recording_screen.dart';
import 'recording_list_screen.dart';
import 'chat_panel.dart';
import '../../widgets/floating_toolbar.dart';
import 'whiteboard_screen.dart';
import '../../platform/windows_screen_capture.dart';
import '../../platform/macos_screen_capture.dart';
import '../../platform/linux_screen_capture.dart';
import 'remote_print_screen.dart';
import 'remote_camera_screen.dart';
import 'remote_terminal_screen.dart';

enum SharingSource { fullScreen, window }

class SessionScreen extends StatefulWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with ErrorHandler {
  final WebRtcService _webrtc = WebRtcService();
  final ScreenService _screenService = ScreenService();
  final ApiClient _api = ApiClient();
  final E2eeService _e2ee = E2eeService();
  final DragDropService _dragDrop = DragDropService();
  InputRelayService? _inputRelay;
  SignalingService? _signaling;
  bool _audioEnabled = true;
  bool _whiteboardActive = false;
  String _localDeviceId = 'local';
  final GlobalKey<WhiteboardScreenState> _whiteboardKey = GlobalKey<WhiteboardScreenState>();

  List<ScreenInfo> _screens = [];
  Set<int> _selectedScreenIds = {};
  bool _selectingScreens = true;

  List<WindowInfo> _windows = [];
  WindowInfo? _selectedWindow;
  SharingSource _sharingSource = SharingSource.fullScreen;

  bool _isDragOver = false;
  List<String> _dragFiles = [];
  int _dragTotalSize = 0;
  StreamSubscription<dynamic>? _dragStatusSub;
  StreamSubscription<dynamic>? _dragDropSub;

  @override
  void initState() {
    super.initState();
    _initScreens();
    _localDeviceIdInit();
    _dragDrop.startListening();
    _dragStatusSub = _dragDrop.onStatusChange.listen((status) {
      if (mounted) {
        setState(() {
          _isDragOver = status == DragDropStatus.dragging;
          if (!_isDragOver) {
            _dragFiles = [];
            _dragTotalSize = 0;
          }
        });
      }
    });
    _dragDropSub = _dragDrop.onDrop.listen((event) {
      if (mounted) {
        setState(() {
          _dragFiles = event.files;
          _dragTotalSize = event.totalSize;
        });
        _handleFileDrop(event.files);
        setState(() {
          _isDragOver = false;
          _dragFiles = [];
          _dragTotalSize = 0;
        });
      }
    });
  }

  Future<void> _localDeviceIdInit() async {
    final id = await SecureStorageService.getString('device_id');
    if (mounted) {
      setState(() => _localDeviceId = id ?? 'local');
    }
  }

  Future<void> _initScreens() async {
    await _screenService.init();
    final screens = _screenService.screens;
    if (screens.isNotEmpty) {
      setState(() {
        _screens = screens;
        _selectedScreenIds = {screens.first.id};
      });
    }
    await _initWindows();
  }

  Future<void> _initWindows() async {
    try {
      final windows = await _getPlatformCapture().enumerateWindows();
      final truncated = windows
          .map((w) => WindowInfo(
                id: w['hwnd'] as String? ?? w['windowId'] as String? ?? w['window_id'] as String? ?? '',
                title: (w['title'] as String? ?? '').length > 50
                    ? (w['title'] as String? ?? '').substring(0, 50)
                    : (w['title'] as String? ?? ''),
                processId: w['processId'] as int? ?? w['process_id'] as int? ?? 0,
                x: w['bounds']?['x'] as int? ?? w['x'] as int? ?? 0,
                y: w['bounds']?['y'] as int? ?? w['y'] as int? ?? 0,
                width: w['bounds']?['width'] as int? ?? w['width'] as int? ?? 0,
                height: w['bounds']?['height'] as int? ?? w['height'] as int? ?? 0,
              ))
          .where((w) => w.width > 0 && w.height > 0)
          .toList();
      if (mounted) {
        setState(() {
          _windows = truncated;
        });
      }
    } catch (_) {
      _windows = [];
    }
  }

  dynamic _getPlatformCapture() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.windows:
        return WindowsScreenCapture();
      case TargetPlatform.macOS:
        return MacOSScreenCapture();
      case TargetPlatform.linux:
        return LinuxScreenCapture();
      default:
        return LinuxScreenCapture();
    }
  }

  Future<void> _showSharingSourceDialog() async {
    final source = await showDialog<SharingSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select sharing source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Full Screen'),
              subtitle: Text('Share ${_screens.map((s) => s.name).join(", ")}'),
              leading: const Icon(Icons.desktop_windows_outlined),
              onTap: () => Navigator.pop(ctx, SharingSource.fullScreen),
            ),
            if (_windows.isNotEmpty) ...[
              const Divider(),
              const Text('Windows', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._windows.map((w) => ListTile(
                    title: Text(w.title.isEmpty ? 'Untitled Window' : w.title),
                    subtitle: Text('${w.width}×${w.height}'),
                    leading: const Icon(Icons.web_outlined),
                    onTap: () {
                      setState(() => _selectedWindow = w);
                      Navigator.pop(ctx, SharingSource.window);
                    },
                  )),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No windows detected', style: TextStyle(fontSize: 13, color: Color(0xFF636366))),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
    if (source == null) return;
    setState(() {
      _sharingSource = source;
      if (source == SharingSource.window) {
        _selectedWindow = _windows.first;
      } else {
        _selectedWindow = null;
      }
    });
  }

  Future<void> _startSession() async {
    if (_selectedScreenIds.isEmpty) return;

    await _showSharingSourceDialog();
    if (_sharingSource == SharingSource.fullScreen && _selectedScreenIds.isEmpty) return;
    if (_sharingSource == SharingSource.window && _selectedWindow == null) return;

    setState(() => _selectingScreens = false);

    try {
      final token = await SecureStorageService.getString('jwt_token') ?? '';
      final deviceId = await SecureStorageService.getString('device_id') ?? '';

      final granted = await ScreenCaptureService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screen capture permission denied')),
          );
        }
        setState(() => _selectingScreens = true);
        return;
      }
      await ScreenCaptureService.startService();

      _signaling = SignalingService(
        serverUrl: AppConfig.wsSignalUrl,
        token: token,
        deviceId: deviceId,
        onConnectionChanged: (connected) {
          if (!mounted) return;
          final sp = context.read<SessionProvider>();
          if (connected) {
            sp.setReconnectionState(ReconnectionState.connected);
          } else {
            sp.setReconnectionState(ReconnectionState.reconnecting, attempts: 0);
          }
        },
        onSessionResume: (sessionId) {
          debugPrint('Session resume requested: $sessionId');
          if (sessionId == '__session_invalid__') {
            if (mounted) {
              context.read<SessionProvider>().setActiveSession(null);
              GoRouter.of(context).go('/devices');
            }
          }
        },
        onPasswordRequired: (sessionId) {
          debugPrint('Password required for session $sessionId');
          _promptForPassword(sessionId);
        },
        onKeyExchange: (publicKey, fromDevice) {
          // Derive session key from remote public key
          _e2ee.deriveSessionKey(publicKey);
          debugPrint('E2EE session key derived from $fromDevice');
        },
        onPrivacyChanged: (enabled) {
          if (mounted) {
            context.read<SessionProvider>().setPrivacyEnabled(enabled);
          }
        },
        onWhiteboard: (event) {
          _handleWhiteboardEvent(event);
        },
        onReconnectAttempts: (attempts) {
          if (!mounted) return;
          context.read<SessionProvider>().setReconnectionState(ReconnectionState.reconnecting, attempts: attempts);
        },
        onReconnectFailed: (attempts) {
          if (!mounted) return;
          context.read<SessionProvider>().setReconnectionState(ReconnectionState.failed, attempts: attempts);
        },
        onRemoteCamera: (payload) {
          if (!mounted) return;
          final session = context.read<SessionProvider>().activeSession;
          if (session == null) return;
          if (_localDeviceId != session.controllerDeviceId) {
            _showRemoteCamera();
          }
        },
      );
      await _signaling!.connect();

      // Initialize E2EE and send public key
      await _e2ee.initialize();
      if (!mounted) return;
      final controlleeId = context.read<SessionProvider>().activeSession?.controlleeDeviceId ?? '';
      if (controlleeId.isNotEmpty) {
        _signaling!.sendKeyExchange(_e2ee.publicKey, controlleeId);
      }

      _inputRelay = InputRelayService(
        signaling: _signaling!,
        sessionId: widget.sessionId,
        targetDeviceId: controlleeId,
      );
      context.read<SessionProvider>().setSignalingService(_signaling);
      final qualityProfile = await QualityService().getProfile(widget.sessionId);
      final captureConstraints = _selectedWindow != null
          ? <String, dynamic>{
              'video': <String, dynamic>{
                'displaySurface': 'window',
                'cursor': 'always',
                if (_selectedWindow!.width > 0 && _selectedWindow!.height > 0)
                  'width': <String, dynamic>{'max': _selectedWindow!.width},
                if (_selectedWindow!.width > 0 && _selectedWindow!.height > 0)
                  'height': <String, dynamic>{'max': _selectedWindow!.height},
              },
            }
          : null;
      await _webrtc.initialize(
        role: SessionRole.controller,
        selectedScreenIds: _selectedScreenIds.toList(),
        qualityProfile: qualityProfile,
        captureConstraints: captureConstraints,
        onLocalDescription: (desc) {
          final payload = <String, dynamic>{
            'sdp': desc.sdp,
            'type': desc.type,
            if (_selectedWindow != null) 'window_id': _selectedWindow!.id,
            if (_selectedWindow != null) 'window_title': _selectedWindow!.title,
            if (_selectedWindow != null) 'window_bounds': _selectedWindow!.toJson(),
          };
          _signaling?.send(SignalingMessage(
            type: SignalingMessageType.callOffer,
            sessionId: widget.sessionId,
            payload: payload,
          ));
        },
        onIceCandidate: (candidate) {
          _signaling?.send(SignalingMessage(
            type: SignalingMessageType.ice,
            sessionId: widget.sessionId,
            payload: {'candidate': candidate.candidate, 'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex},
          ));
        },
        onRemoteStream: (stream) {
          // Remote screen stream received
        },
      );

      _webrtc.createOffer();
      // Add audio track for remote audio transmission
      await _webrtc.addAudioTrack();
      _inputRelay?.start();
    } catch (e) {
      if (!mounted) return;
      handleError(e, context: context);
      setState(() => _selectingScreens = true);
    }
  }

  Future<void> _promptForPassword(String sessionId) async {
    final controller = TextEditingController();
    try {
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Session Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter session password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Join'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (password == null || password.isEmpty) {
        GoRouter.of(context).go('/devices');
        return;
      }
      _signaling?.send(SignalingMessage(
        type: SignalingMessageType.resumeSession,
        sessionId: sessionId,
        payload: {'password': password},
      ));
    } finally {
      controller.dispose();
    }
  }

  void _toggleAudio() {
    setState(() => _audioEnabled = !_audioEnabled);
    for (final stream in _webrtc.remoteStreams) {
      for (final track in stream.getAudioTracks()) {
        track.enabled = _audioEnabled;
      }
    }
  }

  void _toggleWhiteboard() {
    setState(() => _whiteboardActive = !_whiteboardActive);
    context.read<SessionProvider>().toggleWhiteboard(_whiteboardActive);
  }

  void _handleWhiteboardEvent(Map<String, dynamic> event) {
    if (!_whiteboardActive) return;
    _whiteboardKey.currentState?.handleRemoteEvent(event);
  }

  void _showChat() {
    final sessionProvider = context.read<SessionProvider>();
    final targetDeviceId = sessionProvider.activeSession?.controlleeDeviceId ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ChatPanel(
          signaling: _signaling!,
          targetDeviceId: targetDeviceId.toString(),
        ),
      ),
    );
  }

  Future<void> _setSessionPassword() async {
    final controller = TextEditingController();
    try {
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Session Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter password (leave empty to remove)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (password == null) return;
      try {
        await _api.setSessionPassword(widget.sessionId, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set password: $e')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _retryConnection() async {
    context.read<SessionProvider>().setReconnectionState(ReconnectionState.connecting);
    await _signaling?.connect();
  }

  @visibleForTesting
  void simulateSessionStarted() {
    setState(() => _selectingScreens = false);
  }

  int _keyModifiers(KeyEvent event) {
    int modifiers = 0;
    final hw = HardwareKeyboard.instance;
    if (hw.isShiftPressed) modifiers |= 0x01;
    if (hw.isControlPressed) modifiers |= 0x02;
    if (hw.isAltPressed) modifiers |= 0x04;
    if (hw.isMetaPressed) modifiers |= 0x08;
    return modifiers;
  }

  @override
  Widget build(BuildContext context) {
    final privacyEnabled = context.watch<SessionProvider>().privacyEnabled;
    final toolbarMode = context.watch<SessionProvider>().toolbarMode;
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
        actions: [
          Semantics(
            label: 'Close session',
            child: IconButton(
              onPressed: () => _webrtc.dispose(),
              tooltip: 'Close',
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
      body: _selectingScreens
          ? _buildScreenSelector()
          : Stack(
              children: [
                _buildSessionView(),
                if (_whiteboardActive && _signaling != null)
                  WhiteboardScreen(
                    key: _whiteboardKey,
                    signaling: _signaling!,
                    sessionId: widget.sessionId,
                    localDeviceId: _localDeviceId,
                  ),
                if (toolbarMode == ToolbarMode.floating)
                  _buildFloatingToolbar(privacyEnabled)
                else
                  _buildClassicToolbar(privacyEnabled),
              ],
            ),
    );
  }

  Widget _buildClassicToolbar(bool privacyEnabled) {
    final actions = <ToolbarAction>[
      ToolbarAction(
        icon: Icons.hd,
        label: 'Quality',
        tooltip: 'Quality settings',
        onTap: _showQualitySettings,
        group: ToolbarGroup.display,
      ),
      ToolbarAction(
        icon: privacyEnabled ? Icons.visibility_off : Icons.visibility,
        label: privacyEnabled ? 'Hide screen' : 'Privacy',
        tooltip: privacyEnabled ? 'Disable privacy' : 'Enable privacy',
        onTap: () async {
          final sp = context.read<SessionProvider>();
          await sp.togglePrivacy(!privacyEnabled);
        },
        group: ToolbarGroup.display,
      ),
      ToolbarAction(
        icon: _audioEnabled ? Icons.mic : Icons.mic_off,
        label: _audioEnabled ? 'Mute' : 'Unmute',
        tooltip: _audioEnabled ? 'Mute audio' : 'Unmute audio',
        onTap: _toggleAudio,
        group: ToolbarGroup.audio,
      ),
      ToolbarAction(
        icon: Icons.folder_open,
        label: 'Files',
        tooltip: 'File transfers',
        onTap: _showFileTransfers,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.playlist_play,
        label: 'Recordings',
        tooltip: 'Recordings',
        onTap: _showRecordings,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.fiber_manual_record,
        label: 'Record',
        tooltip: 'Start recording',
        onTap: _showRecording,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.lock_outline,
        label: 'Password',
        tooltip: 'Session password',
        onTap: _setSessionPassword,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        tooltip: 'Chat',
        onTap: _showChat,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.content_paste,
        label: 'Clipboard',
        tooltip: 'Clipboard',
        onTap: _showClipboard,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.print,
        label: 'Print',
        tooltip: 'Remote print',
        onTap: _showRemotePrint,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.camera_alt_outlined,
        label: 'Camera',
        tooltip: 'Remote camera',
        onTap: _showRemoteCamera,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.terminal,
        label: 'Terminal',
        tooltip: 'Remote terminal',
        onTap: _showRemoteTerminal,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: _whiteboardActive ? Icons.brush : Icons.brush_outlined,
        label: _whiteboardActive ? 'Whiteboard' : 'Whiteboard',
        tooltip: _whiteboardActive ? 'Disable whiteboard' : 'Enable whiteboard',
        onTap: _toggleWhiteboard,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.close,
        label: 'Close',
        tooltip: 'Close session',
        onTap: () => _webrtc.dispose(),
        group: ToolbarGroup.end,
      ),
    ];

    final groups = <ToolbarGroup, List<ToolbarAction>>{};
    for (final a in actions) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in groups.entries) ...[
                ...entry.value.map((action) => _ClassicToolbarButton(
                  icon: action.icon,
                  label: action.label,
                  tooltip: action.tooltip,
                  onTap: action.onTap,
                  destructive: action.group == ToolbarGroup.end,
                )),
                if (entry.key != ToolbarGroup.end)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingToolbar(bool privacyEnabled) {
    final actions = <ToolbarAction>[
      ToolbarAction(
        icon: Icons.hd,
        label: 'Quality',
        tooltip: 'Quality settings',
        onTap: _showQualitySettings,
        group: ToolbarGroup.display,
      ),
      ToolbarAction(
        icon: privacyEnabled ? Icons.visibility_off : Icons.visibility,
        label: privacyEnabled ? 'Hide screen' : 'Privacy',
        tooltip: privacyEnabled ? 'Disable privacy' : 'Enable privacy',
        onTap: () async {
          final sp = context.read<SessionProvider>();
          await sp.togglePrivacy(!privacyEnabled);
        },
        group: ToolbarGroup.display,
      ),
      ToolbarAction(
        icon: _audioEnabled ? Icons.mic : Icons.mic_off,
        label: _audioEnabled ? 'Mute' : 'Unmute',
        tooltip: _audioEnabled ? 'Mute audio' : 'Unmute audio',
        onTap: _toggleAudio,
        group: ToolbarGroup.audio,
      ),
      ToolbarAction(
        icon: Icons.folder_open,
        label: 'Files',
        tooltip: 'File transfers',
        onTap: _showFileTransfers,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.playlist_play,
        label: 'Recordings',
        tooltip: 'Recordings',
        onTap: _showRecordings,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.fiber_manual_record,
        label: 'Record',
        tooltip: 'Start recording',
        onTap: _showRecording,
        group: ToolbarGroup.files,
      ),
      ToolbarAction(
        icon: Icons.lock_outline,
        label: 'Password',
        tooltip: 'Session password',
        onTap: _setSessionPassword,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        tooltip: 'Chat',
        onTap: _showChat,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.content_paste,
        label: 'Clipboard',
        tooltip: 'Clipboard',
        onTap: _showClipboard,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.print,
        label: 'Print',
        tooltip: 'Remote print',
        onTap: _showRemotePrint,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.camera_alt_outlined,
        label: 'Camera',
        tooltip: 'Remote camera',
        onTap: _showRemoteCamera,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.terminal,
        label: 'Terminal',
        tooltip: 'Remote terminal',
        onTap: _showRemoteTerminal,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: _whiteboardActive ? Icons.brush : Icons.brush_outlined,
        label: _whiteboardActive ? 'Whiteboard' : 'Whiteboard',
        tooltip: _whiteboardActive ? 'Disable whiteboard' : 'Enable whiteboard',
        onTap: _toggleWhiteboard,
        group: ToolbarGroup.tools,
      ),
      ToolbarAction(
        icon: Icons.close,
        label: 'Close',
        tooltip: 'Close session',
        onTap: () => _webrtc.dispose(),
        group: ToolbarGroup.end,
      ),
    ];

    return Positioned.fill(
      child: FloatingToolbar(
        actions: actions,
        onToggleMode: () async {
          final sp = context.read<SessionProvider>();
          await sp.toggleToolbarMode();
        },
      ),
    );
  }

  Widget _buildScreenSelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select screens to share',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1D1D1F)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose one or more displays to control remotely.',
            style: TextStyle(fontSize: 13, color: Color(0xFF636366)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _screens.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ScreenSelector(
                    screens: _screens,
                    selectedIds: _selectedScreenIds,
                    onSelectionChanged: (ids) => setState(() => _selectedScreenIds = ids),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _selectedScreenIds.isEmpty ? null : _startSession,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_selectedScreenIds.isEmpty ? 'Select at least one screen' : 'Start Session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionView() {
    final sessionProvider = context.watch<SessionProvider>();
    final streams = _webrtc.remoteStreams;

    if (sessionProvider.reconnectionState == ReconnectionState.failed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Connection lost', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Failed after ${sessionProvider.reconnectAttempts} attempts'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => GoRouter.of(context).go('/devices'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return to devices'),
            ),
          ],
        ),
      );
    }

    if (streams.isEmpty) {
      return Center(
        child: sessionProvider.reconnectionState == ReconnectionState.reconnecting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reconnecting...'),
                ],
              )
            : const CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            if (sessionProvider.reconnectionState == ReconnectionState.reconnecting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFFFF3B30),
                child: Text(
                  'Reconnecting... (attempt ${sessionProvider.reconnectAttempts + 1})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _inputRelay?.updateSize(Size(constraints.maxWidth, constraints.maxHeight));
                  return Listener(
                    onPointerDown: (e) => _inputRelay?.handlePointerEvent(e),
                    onPointerMove: (e) => _inputRelay?.handlePointerEvent(e),
                    onPointerUp: (e) => _inputRelay?.handlePointerEvent(e),
                    onPointerSignal: (e) {
                      if (e is PointerScrollEvent) _inputRelay?.handlePointerEvent(e);
                    },
                    child: KeyboardListener(
                      focusNode: FocusNode()..requestFocus(),
                      onKeyEvent: (e) => _inputRelay?.handleKeyEvent(e, _keyModifiers(e)),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 16 / 9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: streams.length,
                        itemBuilder: (context, index) {
                          final stream = streams[index];
                          final privacyEnabled = sessionProvider.privacyEnabled;
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E5EA)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _isDragOver
                                      ? Opacity(opacity: 0.6, child: RTCVideoView(stream.renderer))
                                      : RTCVideoView(stream.renderer),
                                ),
                              ),
                              if (privacyEnabled)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_isDragOver && sessionProvider.activeSessionId != null)
          _buildDragOverlay(),
      ],
    );
  }

  Future<void> _handleFileDrop(List<String> files) async {
    final sessionProvider = context.read<SessionProvider>();
    final activeSessionId = sessionProvider.activeSessionId;
    if (activeSessionId == null || files.isEmpty) return;

    for (final file in files) {
      sessionProvider.sendFile(file);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queued ${files.length} file(s) for upload'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDragOverlay() {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final fileCount = _dragFiles.length;
    final sizeText = _dragTotalSize > 0
        ? '${(_dragTotalSize / 1024 / 1024).toStringAsFixed(1)} MB'
        : '';

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary, width: 2),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Drop to send',
                    style: TextStyle(color: cs.onPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (fileCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$fileCount file${fileCount > 1 ? 's' : ''}${sizeText.isNotEmpty ? " • $sizeText" : ""}',
                      style: TextStyle(color: cs.onPrimary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQualitySettings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => QualitySettingsSheet(
        sessionId: widget.sessionId,
        onProfileChanged: (profile) => _webrtc.updateQualityProfile(profile),
      ),
    );
  }

  void _showFileTransfers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileTransferScreen(sessionId: widget.sessionId),
      ),
    );
  }

  void _showClipboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClipboardScreen(sessionId: widget.sessionId, deviceId: 0),
      ),
    );
  }

  void _showRecordings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingListScreen(sessionId: widget.sessionId),
      ),
    );
  }

  void _showRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingScreen(sessionId: widget.sessionId),
      ),
    );
  }

  Future<void> _showRemotePrint() async {
    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.activeSession;
    if (session == null) return;

    final isController = _localDeviceId == session.controllerDeviceId;

    if (isController) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RemotePrintScreen(sessionId: widget.sessionId),
        ),
      );
    } else {
      await _showSendPrintDialog();
    }
  }

  void _showRemoteCamera() {
    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.activeSession;
    if (session == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteCameraScreen(sessionId: widget.sessionId),
      ),
    );
  }

  void _showRemoteTerminal() {
    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.activeSession;
    if (session == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteTerminalScreen(sessionId: widget.sessionId),
      ),
    );
  }

  Future<void> _showSendPrintDialog() async {
    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.activeSession;
    if (session == null) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Print Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: 'image',
              decoration: InputDecoration(labelText: 'Format'),
              items: [
                DropdownMenuItem(value: 'image', child: Text('Image (PNG)')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'txt', child: Text('Text')),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'File name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final fileName = controller.text.isEmpty ? 'print_job' : controller.text;
              Navigator.pop(ctx, fileName);
            },
            child: const Text('Capture & Send'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      if (_signaling != null) {
        final targetDevice = session.controllerDeviceId;
        _signaling!.sendRemotePrint(targetDevice, {
          'job_id': '${DateTime.now().millisecondsSinceEpoch}_${_localDeviceId}',
          'file_name': result,
          'file_size': 0,
          'format': 'image',
          'file_data': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print job sent to controller')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dragStatusSub?.cancel();
    _dragDropSub?.cancel();
    _dragDrop.stopListening();
    _inputRelay?.stop();
    _webrtc.dispose();
    _e2ee.dispose();
    super.dispose();
  }
}

class _ClassicToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  const _ClassicToolbarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: destructive ? cs.errorContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: destructive ? cs.error : cs.outline,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: destructive ? cs.onErrorContainer : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: destructive ? cs.onErrorContainer : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
