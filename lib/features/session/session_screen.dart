import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  InputRelayService? _inputRelay;
  SignalingService? _signaling;
  bool _audioEnabled = true;
  bool _whiteboardActive = false;
  String _localDeviceId = 'local';
  final GlobalKey<WhiteboardScreenState> _whiteboardKey = GlobalKey<WhiteboardScreenState>();

  List<ScreenInfo> _screens = [];
  Set<int> _selectedScreenIds = {};
  bool _selectingScreens = true;

  @override
  void initState() {
    super.initState();
    _initScreens();
    _localDeviceIdInit();
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
  }

  Future<void> _startSession() async {
    if (_selectedScreenIds.isEmpty) return;

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
      await _webrtc.initialize(
        role: SessionRole.controller,
        selectedScreenIds: _selectedScreenIds.toList(),
        qualityProfile: qualityProfile,
        onLocalDescription: (desc) {
          _signaling?.send(SignalingMessage(
            type: SignalingMessageType.callOffer,
            sessionId: widget.sessionId,
            payload: {'sdp': desc.sdp, 'type': desc.type},
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

    return Column(
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
                              child: RTCVideoView(stream.renderer),
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

  @override
  void dispose() {
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
