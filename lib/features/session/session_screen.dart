import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/webrtc_service.dart';
import '../../core/screen_service.dart';
import '../../core/signaling_service.dart';
import '../../core/storage_service.dart';
import '../../config/app_config.dart';
import '../../core/error_handler.dart';
import 'screen_selector.dart';
import 'file_transfer_screen.dart';
import 'clipboard_screen.dart';
import 'quality_settings_sheet.dart';
import 'recording_screen.dart';

class SessionScreen extends StatefulWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with ErrorHandler {
  final WebRtcService _webrtc = WebRtcService();
  final ScreenService _screenService = ScreenService();
  SignalingService? _signaling;

  List<ScreenInfo> _screens = [];
  Set<int> _selectedScreenIds = {};
  bool _selectingScreens = true;
  bool _reconnecting = false;

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

      _signaling = SignalingService(
        serverUrl: AppConfig.wsSignalUrl,
        token: token,
        deviceId: deviceId,
        onConnectionChanged: (connected) {
          if (mounted) {
            setState(() => _reconnecting = !connected);
          }
        },
        onSessionResume: (sessionId) {
          debugPrint('Session resume requested: $sessionId');
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
            onPressed: () => _showClipboard(),
            tooltip: 'Clipboard',
            icon: const Icon(Icons.content_paste),
          ),
          IconButton(
            onPressed: () => _showRecording(),
            tooltip: 'Recording',
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
    final streams = _webrtc.remoteStreams;
    if (streams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_reconnecting)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFF3B30),
            child: const Text(
              'Reconnecting...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
