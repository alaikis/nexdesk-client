import 'package:flutter_webrtc/flutter_webrtc.dart';

enum SessionRole {
  controller,
  controllee,
}

class WebRtcService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  RTCVideoRenderer? _remoteRenderer;

  final List<RTCIceCandidate> _remoteCandidates = [];

  Future<void> initialize({
    required SessionRole role,
    required Function(RTCSessionDescription) onLocalDescription,
    required Function(RTCIceCandidate) onIceCandidate,
    required Function(MediaStream) onRemoteStream,
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
        onRemoteStream(event.streams.first);
      }
    };

    if (role == SessionRole.controllee) {
      try {
        final displayMedia = await navigator.mediaDevices.getDisplayMedia(
          {'video': true, 'audio': false},
        );
        _localStream = displayMedia;
        displayMedia.getTracks().forEach((track) => _pc!.addTrack(track, displayMedia));
      } catch (e) {
        // Screen capture permission denied
      }
    }
  }

  Future<void> createOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(await RTCSessionDescription(offer.sdp ?? '', 'offer'));
  }

  Future<void> createAnswer() async {
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(await RTCSessionDescription(answer.sdp ?? '', 'answer'));
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

  Future<RTCVideoRenderer> get remoteRenderer async {
    if (_remoteRenderer == null) {
      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer!.initialize();
    }
    return _remoteRenderer!;
  }

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _remoteRenderer?.dispose();
    _remoteRenderer = null;
    await _pc?.close();
    _pc = null;
    _remoteCandidates.clear();
  }
}
