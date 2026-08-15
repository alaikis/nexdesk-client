import 'package:flutter/material.dart';
import '../../core/quality_service.dart';
import '../../l10n/app_localizations.dart';

class QualitySettingsSheet extends StatefulWidget {
  final String sessionId;
  final Future<void> Function(QualityProfile)? onProfileChanged;
  const QualitySettingsSheet({super.key, required this.sessionId, this.onProfileChanged});

  @override
  State<QualitySettingsSheet> createState() => _QualitySettingsSheetState();
}

class _QualitySettingsSheetState extends State<QualitySettingsSheet> {
  final QualityService _qualityService = QualityService();
  QualityPreset _preset = QualityPreset.hd;
  int _customWidth = 1920;
  int _customHeight = 1080;
  int _customFps = 60;
  int _customBitrate = 4000;
  String _customCodec = 'H264';

  @override
  void initState() {
    super.initState();
    _loadCurrentPreset();
  }

  Future<void> _loadCurrentPreset() async {
    final profile = await _qualityService.getProfile(widget.sessionId);
    setState(() {
      if (profile == QualityProfile.auto) _preset = QualityPreset.custom;
      else if (profile == QualityProfile.low) _preset = QualityPreset.smooth;
      else if (profile == QualityProfile.medium) _preset = QualityPreset.hd;
      else if (profile == QualityProfile.high) _preset = QualityPreset.original;
    });
  }

  Future<void> _applyPreset(QualityPreset preset) async {
    setState(() => _preset = preset);
    final profile = _getProfileFromPreset(preset);
    await _qualityService.setProfile(widget.sessionId, profile);
    await widget.onProfileChanged?.call(profile);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.qualitySetTo(QualityProfileConfig.presetLabels[preset] ?? preset.name))),
    );
  }

  Future<void> _applyCustom() async {
    await _qualityService.setProfile(widget.sessionId, QualityProfile.high);
    await widget.onProfileChanged?.call(QualityProfile.high);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.customQualityApplied)),
    );
  }

  QualityProfile _getProfileFromPreset(QualityPreset preset) {
    switch (preset) {
      case QualityPreset.smooth:
        return QualityProfile.medium;
      case QualityPreset.hd:
        return QualityProfile.high;
      case QualityPreset.ultraHd:
        return QualityProfile.high;
      case QualityPreset.original:
        return QualityProfile.high;
      case QualityPreset.custom:
        return QualityProfile.high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.streamQuality, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: QualityPreset.values.map((preset) {
              final isSelected = _preset == preset;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => _applyPreset(preset),
                label: Text(QualityProfileConfig.presetLabels[preset] ?? preset.name),
              );
            }).toList(),
          ),
          if (_preset == QualityPreset.custom) ...[
            const SizedBox(height: 24),
            Text(l10n.customSettings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSlider(l10n.widthLabel, _customWidth.toDouble(), 320, 3840, 10, (v) => setState(() => _customWidth = v.round())),
            _buildSlider(l10n.heightLabel, _customHeight.toDouble(), 240, 2160, 10, (v) => setState(() => _customHeight = v.round())),
            _buildSlider(l10n.fpsLabel, _customFps.toDouble(), 1, 144, 1, (v) => setState(() => _customFps = v.round())),
            _buildSlider(l10n.bitrateLabel, _customBitrate.toDouble(), 100, 50000, 100, (v) => setState(() => _customBitrate = v.round())),
            const SizedBox(height: 12),
            FilledButton(onPressed: _applyCustom, child: Text(l10n.applyCustom)),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}'),
        Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
      ],
    );
  }
}
