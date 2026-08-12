import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';

class UpdateInfo {
  final String version;
  final String url;
  final String? notes;

  UpdateInfo({required this.version, required this.url, this.notes});
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  UpdateInfo? _latestUpdate;
  bool _updateAvailable = false;
  bool _checking = false;

  bool get updateAvailable => _updateAvailable;
  bool get checking => _checking;
  UpdateInfo? get latestUpdate => _latestUpdate;

  Future<void> checkForUpdates() async {
    if (_checking) return;
    _checking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final api = ApiClient();
      final platform = Platform.operatingSystem;
      final release = await api.getRelease(platform);
      final latestVersion = release['version'] as String?;
      final updateUrl = release['url'] as String?;
      final notes = release['notes'] as String?;

      if (latestVersion == null || updateUrl == null) {
        _updateAvailable = false;
        return;
      }

      _latestUpdate = UpdateInfo(
        version: latestVersion,
        url: updateUrl,
        notes: notes,
      );

      if (latestVersion.compareTo(info.version) > 0) {
        _updateAvailable = true;
      } else {
        _updateAvailable = false;
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      _updateAvailable = false;
    } finally {
      _checking = false;
    }
  }

  Future<void> downloadUpdate() async {
    if (_latestUpdate == null) return;
    final uri = Uri.parse(_latestUpdate!.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
