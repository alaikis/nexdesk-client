import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../core/signaling_service.dart';
import '../../features/session/session_provider.dart';
import '../../core/secure_storage_service.dart';
import '../../l10n/app_localizations.dart';

class RemoteCameraScreen extends StatefulWidget {
  final String sessionId;
  const RemoteCameraScreen({super.key, required this.sessionId});

  @override
  State<RemoteCameraScreen> createState() => _RemoteCameraScreenState();
}

class _RemoteCameraScreenState extends State<RemoteCameraScreen> {
  SignalingService? _signaling;
  StreamSubscription<dynamic>? _cameraSub;
  RTCPeerConnection? _pc;
  RTCVideoRenderer? _renderer;
  MediaStream? _localStream;
  bool _loading = true;
  String? _error;
  bool _isController = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sp = context.read<SessionProvider>();
    final session = sp.activeSession;
    if (session == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final localDeviceId = await SecureStorageService.getString('device_id') ?? 'local';
    _isController = localDeviceId == session.controllerDeviceId;

    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();

    _signaling = sp.signalingService;
    if (_signaling == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _cameraSub = _signaling!.messages.listen(_onCameraMessage);

    if (_isController) {
      _requestCamera();
    }
  }

  void _requestCamera() {
    final sp = context.read<SessionProvider>();
    final session = sp.activeSession;
    if (session == null || _signaling == null) return;

    _signaling!.sendRemoteCamera(
      session.controlleeDeviceId,
      widget.sessionId,
      {'action': 'request', 'from': _signaling!.deviceId},
    );
  }

  Future<void> _onCameraMessage(SignalingMessage msg) async {
    if (msg.type != SignalingMessageType.remoteCamera || msg.sessionId != widget.sessionId) return;

    final payload = Map<String, dynamic>.from(msg.payload);
    final action = payload['action'] as String? ?? '';

    switch (action) {
      case 'request':
        if (!_isController) {
          await _startCameraCapture();
        }
        break;
      case 'offer':
        if (_isController) {
          await _handleOffer(payload);
        }
        break;
      case 'answer':
        if (!_isController) {
          await _handleAnswer(payload);
        }
        break;
      case 'ice':
        await _handleIce(payload);
        break;
    }
  }

  Future<void> _startCameraCapture() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': false});
      await _createPeerConnection();

      _localStream!.getTracks().forEach((track) => _pc!.addTrack(track, _localStream!));

      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);

      if (!mounted) return;
      final sp = context.read<SessionProvider>();
      _signaling!.sendRemoteCamera(
        sp.activeSession?.controllerDeviceId ?? '',
        widget.sessionId,
        {
          'action': 'offer',
          'sdp': offer.sdp,
          'type': offer.type,
          'from': _signaling!.deviceId,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Camera error: $e');
      }
    }
  }

  Future<void> _createPeerConnection() async {
    final iceServers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
    ];

    final configuration = <String, dynamic>{'iceServers': iceServers};
    _pc = await createPeerConnection(configuration);

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _renderer!.srcObject = event.streams.first;
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    };

    _pc!.onIceCandidate = (candidate) {
      final sp = context.read<SessionProvider>();
      final target = _isController
          ? sp.activeSession?.controlleeDeviceId ?? ''
          : sp.activeSession?.controllerDeviceId ?? '';
      _signaling!.sendRemoteCamera(
        target,
        widget.sessionId,
        {
          'action': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'from': _signaling!.deviceId,
        },
      );
    };
  }

  Future<void> _handleOffer(Map<String, dynamic> payload) async {
    await _createPeerConnection();

    final sdp = payload['sdp'] as String?;
    final type = payload['type'] as String? ?? 'offer';
    if (sdp == null) return;

    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    if (!mounted) return;
    final sp = context.read<SessionProvider>();
    _signaling!.sendRemoteCamera(
      sp.activeSession?.controlleeDeviceId ?? '',
      widget.sessionId,
      {
        'action': 'answer',
        'sdp': answer.sdp,
        'type': answer.type,
        'from': _signaling!.deviceId,
      },
    );
  }

  Future<void> _handleAnswer(Map<String, dynamic> payload) async {
    final sdp = payload['sdp'] as String?;
    final type = payload['type'] as String? ?? 'answer';
    if (sdp == null || _pc == null) return;

    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> _handleIce(Map<String, dynamic> payload) async {
    if (_pc == null) return;
    final candidate = RTCIceCandidate(
      payload['candidate'] as String? ?? '',
      payload['sdpMid'] as String? ?? '',
      int.tryParse(payload['sdpMLineIndex']?.toString() ?? '0') ?? 0,
    );
    await _pc!.addCandidate(candidate);
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    _localStream?.dispose();
    _renderer?.dispose();
    _pc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remoteCameraTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: l10n.close,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                    ],
                  ),
                )
              : Center(
                  child: _renderer != null
                      ? RTCVideoView(_renderer!)
                      : const CircularProgressIndicator(),
                ),
    );
  }
}
