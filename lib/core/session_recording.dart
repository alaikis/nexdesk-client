import 'package:flutter/material.dart';

class SessionRecording {
  final int id;
  final int sessionId;
  final String filePath;
  final int fileSize;
  final int durationSec;
  final String status;
  final String? checksum;
  final DateTime createdAt;

  SessionRecording({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.fileSize,
    required this.durationSec,
    required this.status,
    this.checksum,
    required this.createdAt,
  });

  factory SessionRecording.fromJson(Map<String, dynamic> json) {
    return SessionRecording(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int? ?? 0,
      durationSec: json['duration_sec'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
      checksum: json['checksum'] as String?,
      createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
    );
  }

  String get fileSizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get durationLabel {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get statusColor {
    switch (status) {
      case 'recording':
        return const Color(0xFFFF3B30);
      case 'completed':
        return const Color(0xFF34C759);
      case 'failed':
        return const Color(0xFFFF9500);
      case 'deleted':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}
