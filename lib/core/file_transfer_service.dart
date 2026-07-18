import 'dart:io';
import 'api_client.dart';

enum TransferDirection { upload, download }

enum TransferStatus { pending, transferring, completed, failed, cancelled }

class FileTransfer {
  final int id;
  final String fileName;
  final int fileSize;
  final TransferDirection direction;
  TransferStatus status;
  int transferred;
  final String? checksum;
  final String? errorMessage;

  FileTransfer({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.direction,
    this.status = TransferStatus.pending,
    this.transferred = 0,
    this.checksum,
    this.errorMessage,
  });

  factory FileTransfer.fromJson(Map<String, dynamic> json) {
    return FileTransfer(
      id: json['id'] ?? json['id'] as int,
      fileName: json['file_name'] ?? json['fileName'] as String,
      fileSize: (json['file_size'] ?? json['fileSize']) as int,
      direction: json['direction'] == 'upload' ? TransferDirection.upload : TransferDirection.download,
      status: TransferStatus.values.firstWhere((s) => s.name == (json['status'] ?? 'pending'), orElse: () => TransferStatus.pending),
      transferred: json['transferred'] ?? 0,
      checksum: json['checksum'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  double get progress => fileSize > 0 ? transferred / fileSize : 0;
}

class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  factory FileTransferService() => _instance;
  FileTransferService._internal();

  final ApiClient _api = ApiClient();

  Future<FileTransfer> startUpload(String sessionId, File file) async {
    final stat = await file.stat();
    final res = await _api.post('/sessions/$sessionId/files', {
      'file_name': file.path.split('/').last,
      'file_size': stat.size,
      'direction': 'upload',
    });
    return FileTransfer.fromJson(res);
  }

  Future<FileTransfer> startDownload(String sessionId, String fileName, int fileSize) async {
    final res = await _api.post('/sessions/$sessionId/files', {
      'file_name': fileName,
      'file_size': fileSize,
      'direction': 'download',
    });
    return FileTransfer.fromJson(res);
  }

  Future<void> updateProgress(int transferId, int transferred, {String? checksum, TransferStatus? status, String? error}) async {
    final body = <String, dynamic>{'transferred': transferred};
    if (checksum != null) body['checksum'] = checksum;
    if (status != null) body['status'] = status.name;
    if (error != null) body['error'] = error;
    await _api.patch('/files/$transferId/progress', body);
  }

  Future<List<FileTransfer>> listTransfers(String sessionId) async {
    final res = await _api.get('/sessions/$sessionId/files');
    final list = res['files'] as List<dynamic>? ?? [];
    return list.map((f) => FileTransfer.fromJson(f as Map<String, dynamic>)).toList();
  }
}
