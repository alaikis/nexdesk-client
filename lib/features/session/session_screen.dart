import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/webrtc_service.dart';
import '../../core/screen_service.dart';
import '../../core/signaling_service.dart';
import '../../core/storage_service.dart';
import '../../config/app_config.dart';
import '../../core/error_handler.dart';
import '../../core/screen_capture_service.dart';
import '../../core/api_client.dart';
import '../session/session_provider.dart';
import 'screen_selector.dart';
import 'file_transfer_screen.dart';
import 'clipboard_screen.dart';
import 'quality_settings_sheet.dart';
import 'recording_screen.dart';
import 'recording_list_screen.dart';

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
  SignalingService? _signaling;

  List<ScreenInfo> _screens = [];
  Set<int> _selectedScreenIds = {};
  bool _selectingScreens = true;

  @override
  void initState() {
    super.initState();
    _initScreens();
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
      final token = await StorageService.getString('jwt_token') ?? '';
      final deviceId = await StorageService.getString('device_id') ?? '';

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
      await _webrtc.initialize(
        role: SessionRole.controller,
        selectedScreenIds: _selectedScreenIds.toList(),
        onLocalDescription: (desc) {
          _signaling?.send(SignalingMessage(
            type: SignalingMessageType.callOffer,
            sessionId: widget.sessionId,
          ));
        },
        onIceCandidate: (candidate) {
          _signaling?.send(SignalingMessage(
            type: SignalingMessageType.ice,
            sessionId: widget.sessionId,
          ));
        },
        onRemoteStream: (stream) {
          // Remote screen stream received
        },
      );

      _webrtc.createOffer();
    } catch (e) {
      // ignore: use_build_context_synchronously
      handleError(e, context: context);
      if (mounted) {
        setState(() => _selectingScreens = true);
      }
    }
  }

  Future<void> _promptForPassword(String sessionId) async {
    final controller = TextEditingController();
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
  }

  Future<void> _setSessionPassword() async {
    final controller = TextEditingController();
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
  }

  Future<void> _retryConnection() async {
    context.read<SessionProvider>().setReconnectionState(ReconnectionState.connecting);
    await _signaling?.connect();
  }

  @visibleForTesting
  void simulateSessionStarted() {
    setState(() => _selectingScreens = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
        actions: [
          IconButton(
            onPressed: () => _showQualitySettings(),
            tooltip: 'Quality',
            icon: const Icon(Icons.hd),
          ),
          IconButton(
            onPressed: () => _showFileTransfers(),
            tooltip: 'Files',
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            onPressed: () => _showRecordings(),
            tooltip: 'Recordings',
            icon: const Icon(Icons.playlist_play),
          ),
          IconButton(
            onPressed: _setSessionPassword,
            tooltip: 'Password',
            icon: const Icon(Icons.lock_outline),
          ),
          IconButton(
            onPressed: () => _showClipboard(),
            tooltip: 'Clipboard',
            icon: const Icon(Icons.content_paste),
          ),
          IconButton(
            onPressed: () => _showRecording(),
            tooltip: 'Record',
            icon: const Icon(Icons.fiber_manual_record),
          ),
          IconButton(
            onPressed: () => _webrtc.dispose(),
            tooltip: 'Close',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _selectingScreens
          ? _buildScreenSelector()
          : _buildSessionView(),
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
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(stream.renderer),
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
      builder: (_) => QualitySettingsSheet(sessionId: widget.sessionId),
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
    _webrtc.dispose();
    super.dispose();
  }
}
