import 'package:flutter/material.dart';
import '../../core/webrtc_service.dart';

class SessionScreen extends StatefulWidget {
  final String sessionId;
  const SessionScreen({super.key, required this.sessionId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _webrtc = WebRtcService();

  @override
  void initState() {
    super.initState();
    _initWebRtc();
  }

  Future<void> _initWebRtc() async {
    await _webrtc.initialize(
      role: SessionRole.controller,
      onLocalDescription: (desc) {
        // send via signaling
      },
      onIceCandidate: (candidate) {
        // send via signaling
      },
      onRemoteStream: (stream) {
        // Remote stream received
      },
    );
    await _webrtc.createOffer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
        actions: [
          IconButton(
            onPressed: () => _webrtc.dispose(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _webrtc.remoteRenderer,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final renderer = snapshot.data as dynamic;
            return Center(child: renderer.renderer as Widget);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  void dispose() {
    _webrtc.dispose();
    super.dispose();
  }
}
