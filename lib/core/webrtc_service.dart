import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'quality_service.dart';

enum SessionRole {
  controller,
  controllee,
}

class ScreenStream {
  final MediaStream stream;
  final int screenId;
  final String screenName;
  final RTCVideoRenderer renderer;

  ScreenStream({
    required this.stream,
    required this.screenId,
    required this.screenName,
    required this.renderer,
  });
}

class WebRtcService {
  RTCPeerConnection? _pc;
  final List<ScreenStream> _localStreams = [];
  final List<ScreenStream> _remoteStreams = [];

  final List<RTCIceCandidate> _remoteCandidates = [];

  Future<void> initialize({
    required SessionRole role,
    required List<int> selectedScreenIds,
    required Function(RTCSessionDescription) onLocalDescription,
    required Function(RTCIceCandidate) onIceCandidate,
    required Function(ScreenStream) onRemoteStream,
    QualityProfile? qualityProfile,
  }) async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(configuration);

    _pc!.onIceCandidate = onIceCandidate;

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        final screenId = stream.id.hashCode;
        final screenName = 'Screen ${_remoteStreams.length + 1}';
        final renderer = RTCVideoRenderer();
        renderer.initialize();
        final screenStream = ScreenStream(
          stream: stream,
          screenId: screenId,
          screenName: screenName,
          renderer: renderer,
        );
        _remoteStreams.add(screenStream);
        onRemoteStream(screenStream);
      }
    };

    if (qualityProfile != null) {
      _applyQualityProfile(qualityProfile);
    }

    if (role == SessionRole.controllee) {
      await _captureScreens(selectedScreenIds);
    }
  }

  void _applyQualityProfile(QualityProfile profile) {
    final constraints = QualityService().getWebRtcConstraints(profile);
    _pc?.setConfiguration({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'video': constraints['video'],
    });
  }

  Future<void> updateQualityProfile(QualityProfile profile) async {
    _applyQualityProfile(profile);
  }

  Future<void> _captureScreens(List<int> selectedScreenIds) async {
    for (final screenId in selectedScreenIds) {
      try {
        final displayMedia = await navigator.mediaDevices.getDisplayMedia(
          {'video': true, 'audio': false},
        );
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        final screenStream = ScreenStream(
          stream: displayMedia,
          screenId: screenId,
          screenName: 'Screen $screenId',
          renderer: renderer,
        );
        _localStreams.add(screenStream);
        displayMedia.getTracks().forEach((track) => _pc!.addTrack(track, displayMedia));
      } catch (e) {
        // Screen capture permission denied for this screen
      }
    }
  }

  void createOffer() {
    _pc!.createOffer().then((offer) {
      _pc!.setLocalDescription(offer);
    });
  }

  void createAnswer() {
    _pc!.createAnswer().then((answer) {
      _pc!.setLocalDescription(answer);
    });
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _pc!.setRemoteDescription(description);
    for (final candidate in _remoteCandidates) {
      await _pc!.addCandidate(candidate);
    }
    _remoteCandidates.clear();
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    if (_pc != null) {
      await _pc!.addCandidate(candidate);
    } else {
      _remoteCandidates.add(candidate);
    }
  }

  List<ScreenStream> get localStreams => List.unmodifiable(_localStreams);
  List<ScreenStream> get remoteStreams => List.unmodifiable(_remoteStreams);

  Future<void> dispose() async {
    for (final s in _localStreams) {
      await s.stream.dispose();
      await s.renderer.dispose();
    }
    for (final s in _remoteStreams) {
      await s.renderer.dispose();
    }
    _localStreams.clear();
    _remoteStreams.clear();
    await _pc?.close();
    _pc = null;
    _remoteCandidates.clear();
  }
}
