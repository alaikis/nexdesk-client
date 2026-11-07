import 'package:flutter/material.dart';
import '../../core/quality_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_button.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCurrentPreset();
  }

  Future<void> _loadCurrentPreset() async {
    final profile = await _qualityService.getProfile(widget.sessionId);
    setState(() {
      if (profile == QualityProfile.auto) {
        _preset = QualityPreset.custom;
      } else if (profile == QualityProfile.low) {
        _preset = QualityPreset.smooth;
      } else if (profile == QualityProfile.medium) {
        _preset = QualityPreset.hd;
      } else if (profile == QualityProfile.high) {
        _preset = QualityPreset.original;
      }
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

  String _presetDescription(QualityPreset preset) {
    switch (preset) {
      case QualityPreset.smooth:
        return 'Optimized for low bandwidth';
      case QualityPreset.hd:
        return 'Balanced quality and performance';
      case QualityPreset.ultraHd:
        return 'High detail, requires more bandwidth';
      case QualityPreset.original:
        return 'Original screen resolution';
      case QualityPreset.custom:
        return 'Configure your own settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(NexRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(NexSpacing.xxl, NexSpacing.md, NexSpacing.xxl, NexSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: NexSpacing.lg),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.streamQuality,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: NexSpacing.lg),
              ...QualityPreset.values.map((preset) {
                final isSelected = _preset == preset;
                final label = QualityProfileConfig.presetLabels[preset] ?? preset.name;
                return Padding(
                  padding: const EdgeInsets.only(bottom: NexSpacing.sm),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _applyPreset(preset),
                      borderRadius: BorderRadius.circular(NexRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: NexSpacing.lg, vertical: NexSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withValues(alpha: 0.1) : surfaceColor,
                          borderRadius: BorderRadius.circular(NexRadius.md),
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? primaryColor : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _presetDescription(preset),
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, size: 20, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_preset == QualityPreset.custom) ...[
                const SizedBox(height: NexSpacing.lg),
                Text(
                  l10n.customSettings,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: NexSpacing.md),
                _buildSlider(l10n.widthLabel, _customWidth.toDouble(), 320, 3840, 10,
                    (v) => setState(() => _customWidth = v.round()), primaryColor, textPrimary, textSecondary),
                _buildSlider(l10n.heightLabel, _customHeight.toDouble(), 240, 2160, 10,
                    (v) => setState(() => _customHeight = v.round()), primaryColor, textPrimary, textSecondary),
                _buildSlider(l10n.fpsLabel, _customFps.toDouble(), 1, 144, 1,
                    (v) => setState(() => _customFps = v.round()), primaryColor, textPrimary, textSecondary),
                _buildSlider(l10n.bitrateLabel, _customBitrate.toDouble(), 100, 50000, 100,
                    (v) => setState(() => _customBitrate = v.round()), primaryColor, textPrimary, textSecondary),
                const SizedBox(height: NexSpacing.md),
                NexButton(
                  text: l10n.applyCustom,
                  fullWidth: true,
                  onPressed: _applyCustom,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
    Color primaryColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
              Text('${value.toInt()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              thumbColor: primaryColor,
              inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
              overlayColor: primaryColor.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
