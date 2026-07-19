import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../config/app_config.dart';
import 'api_client.dart';

enum TransferDirection { upload, download }

enum TransferStatus { pending, transferring, completed, failed, cancelled }

class FileTransfer {
  final int id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final TransferDirection direction;
  TransferStatus status;
  int transferred;
  final String? checksum;
  String? errorMessage;

  FileTransfer({
    required this.id,
    required this.fileName,
    this.filePath = '',
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
      filePath: json['file_path'] ?? json['filePath'] as String? ?? '',
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
  final Map<int, http.Client> _activeClients = {};

  Future<FileTransfer> startUpload(String sessionId, File file, {void Function(int transferred, int total)? onProgress}) async {
    final stat = await file.stat();
    final res = await _api.post('/sessions/$sessionId/files', {
      'file_name': file.path.split('/').last,
      'file_size': stat.size,
      'direction': 'upload',
    });
    final transfer = FileTransfer.fromJson(res);
    transfer.status = TransferStatus.transferring;
    final client = http.Client();
    _activeClients[transfer.id] = client;

    try {
      final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/files/${transfer.id}/upload'));
      request.headers.addAll({'Authorization': 'Bearer ${_api.token ?? ''}'});
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final stream = await client.send(request);
      final total = stat.size;
      int transferred = 0;
      final buffer = Uint8List(8192);

      await for (final chunk in stream.stream) {
        transferred += chunk.length;
        buffer.setAll(0, chunk);
        onProgress?.call(transferred, total);
      }

      if (stream.statusCode >= 200 && stream.statusCode < 300) {
        transfer.status = TransferStatus.completed;
        transfer.transferred = total;
      } else {
        transfer.status = TransferStatus.failed;
        transfer.errorMessage = 'Upload failed with status ${stream.statusCode}';
      }
    } catch (e) {
      transfer.status = TransferStatus.failed;
      transfer.errorMessage = e.toString();
    } finally {
      _activeClients.remove(transfer.id);
      client.close();
    }

    return transfer;
  }

  Future<FileTransfer> startDownload(String sessionId, String fileName, int fileSize, {void Function(int transferred, int total)? onProgress}) async {
    final res = await _api.post('/sessions/$sessionId/files', {
      'file_name': fileName,
      'file_size': fileSize,
      'direction': 'download',
    });
    final transfer = FileTransfer.fromJson(res);
    transfer.status = TransferStatus.transferring;
    final client = http.Client();
    _activeClients[transfer.id] = client;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      final request = http.Request('GET', Uri.parse('${AppConfig.apiBaseUrl}/files/${transfer.id}/download'));
      request.headers.addAll({'Authorization': 'Bearer ${_api.token ?? ''}'});
      final streamed = await client.send(request);
      final sink = file.openWrite();
      int transferred = 0;

      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        transferred += chunk.length;
        onProgress?.call(transferred, fileSize);
      }
      await sink.flush();
      await sink.close();

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        transfer.status = TransferStatus.completed;
        transfer.transferred = fileSize;
      } else {
        transfer.status = TransferStatus.failed;
        transfer.errorMessage = 'Download failed with status ${streamed.statusCode}';
      }
    } catch (e) {
      transfer.status = TransferStatus.failed;
      transfer.errorMessage = e.toString();
    } finally {
      _activeClients.remove(transfer.id);
      client.close();
    }

    return transfer;
  }

  Future<void> cancelTransfer(int transferId) async {
    final client = _activeClients.remove(transferId);
    client?.close();
    await _api.post('/files/$transferId/cancel', {});
  }

  Future<List<FileTransfer>> listTransfers(String sessionId) async {
    final res = await _api.get('/sessions/$sessionId/files');
    final list = res['files'] as List<dynamic>? ?? [];
    return list.map((f) => FileTransfer.fromJson(f as Map<String, dynamic>)).toList();
  }
}
