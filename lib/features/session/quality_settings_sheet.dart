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
      switch (profile) {
        case QualityProfile.auto:
          _preset = QualityPreset.custom;
        case QualityProfile.low:
          _preset = QualityPreset.smooth;
        case QualityProfile.medium:
          _preset = QualityPreset.smooth;
        case QualityProfile.high:
          _preset = QualityPreset.hd;
        case QualityProfile.ultraHd:
          _preset = QualityPreset.ultraHd;
        case QualityProfile.original:
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
        return QualityProfile.ultraHd;
      case QualityPreset.original:
        return QualityProfile.original;
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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final cardColor = wise.card;
    final surfaceColor = wise.surface;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final borderColor = wise.border;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(wise.radius.lg)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(wise.spacing.xxl, wise.spacing.md, wise.spacing.xxl, wise.spacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: EdgeInsets.only(bottom: wise.spacing.lg),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.streamQuality,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary, height: 1.47),
              ),
              SizedBox(height: wise.spacing.lg),
              ...QualityPreset.values.map((preset) {
                final isSelected = _preset == preset;
                final label = QualityProfileConfig.presetLabels[preset] ?? preset.name;
                return Padding(
                  padding: EdgeInsets.only(bottom: wise.spacing.sm),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _applyPreset(preset),
                      borderRadius: BorderRadius.circular(wise.radius.medium),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.md),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withValues(alpha: 0.1) : surfaceColor,
                          borderRadius: BorderRadius.circular(wise.radius.medium),
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
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? primaryColor : textPrimary,
                                      height: 1.53,
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
                SizedBox(height: wise.spacing.lg),
                Text(
                  l10n.customSettings,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                SizedBox(height: wise.spacing.md),
                _buildSlider(l10n.widthLabel, _customWidth.toDouble(), 320, 3840, 10,
                    (v) => setState(() => _customWidth = v.round()), wise),
                _buildSlider(l10n.heightLabel, _customHeight.toDouble(), 240, 2160, 10,
                    (v) => setState(() => _customHeight = v.round()), wise),
                _buildSlider(l10n.fpsLabel, _customFps.toDouble(), 1, 144, 1,
                    (v) => setState(() => _customFps = v.round()), wise),
                _buildSlider(l10n.bitrateLabel, _customBitrate.toDouble(), 100, 50000, 100,
                    (v) => setState(() => _customBitrate = v.round()), wise),
                SizedBox(height: wise.spacing.md),
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
    WiseTheme wise,
  ) {
    final primaryColor = wise.primary;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    return Padding(
      padding: EdgeInsets.only(bottom: wise.spacing.sm),
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
