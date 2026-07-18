import 'package:flutter/material.dart';
import '../../core/quality_service.dart';

class QualitySettingsSheet extends StatefulWidget {
  final String sessionId;
  const QualitySettingsSheet({super.key, required this.sessionId});

  @override
  State<QualitySettingsSheet> createState() => _QualitySettingsSheetState();
}

class _QualitySettingsSheetState extends State<QualitySettingsSheet> {
  final QualityService _qualityService = QualityService();
  late Future<QualityProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _qualityService.getProfile(widget.sessionId);
  }

  Future<void> _changeProfile(QualityProfile profile) async {
    await _qualityService.setProfile(widget.sessionId, profile);
    setState(() {
      _profileFuture = Future.value(profile);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quality set to ${profile.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QualityProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final current = snapshot.data ?? QualityProfile.auto;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stream Quality', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ...QualityProfile.values.map((p) {
                final isSelected = current == p;
                return ListTile(
                  title: Text(p.name.toUpperCase()),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF007AFF)) : null,
                  onTap: () => _changeProfile(p),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
