import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/file_transfer_service.dart';

class FileTransferScreen extends StatefulWidget {
  final String sessionId;
  const FileTransferScreen({super.key, required this.sessionId});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  final _service = FileTransferService();
  List<FileTransfer> _transfers = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadTransfers());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    final transfers = await _service.listTransfers(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _transfers = transfers;
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    final file = File(picked.path!);
    final transfer = await _service.startUpload(
      widget.sessionId,
      file,
      onProgress: (transferred, total) {
        if (!mounted) return;
        setState(() {
          final idx = _transfers.indexWhere((t) => t.id == transfer.id);
          if (idx >= 0) {
            _transfers[idx].transferred = transferred;
          } else {
            _transfers.add(transfer);
          }
        });
      },
    );
    if (!mounted) return;
    setState(() {
      final idx = _transfers.indexWhere((t) => t.id == transfer.id);
      if (idx >= 0) {
        _transfers[idx] = transfer;
      } else {
        _transfers.add(transfer);
      }
    });
    await _loadTransfers();
  }

  Future<void> _cancel(int transferId) async {
    await _service.cancelTransfer(transferId);
    if (!mounted) return;
    setState(() {
      final idx = _transfers.indexWhere((t) => t.id == transferId);
      if (idx >= 0) {
        _transfers[idx].status = TransferStatus.cancelled;
      }
    });
  }

  Future<void> _retry(int transferId) async {
    final transfer = _transfers.firstWhere((t) => t.id == transferId);
    setState(() {
      final idx = _transfers.indexWhere((t) => t.id == transferId);
      if (idx >= 0) {
        _transfers[idx].status = TransferStatus.pending;
        _transfers[idx].transferred = 0;
        _transfers[idx].errorMessage = null;
      }
    });
    if (transfer.direction == TransferDirection.upload) {
      final file = File(transfer.fileName);
      if (file.existsSync()) {
        await _service.startUpload(widget.sessionId, file, onProgress: (transferred, total) {
          if (!mounted) return;
          setState(() {
            final idx = _transfers.indexWhere((t) => t.id == transferId);
            if (idx >= 0) _transfers[idx].transferred = transferred;
          });
        });
      }
    } else {
      await _service.startDownload(widget.sessionId, transfer.fileName, transfer.fileSize);
    }
    await _loadTransfers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Transfers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transfers.isEmpty
              ? const Center(child: Text('No transfers yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = _transfers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          transfer.direction == TransferDirection.upload
                              ? Icons.upload_file
                              : Icons.download,
                          color: const Color(0xFF007AFF),
                        ),
                        title: Text(transfer.fileName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${transfer.fileSize ~/ 1024} KB'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: transfer.progress),
                            if (transfer.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                transfer.errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              transfer.status.name,
                              style: TextStyle(
                                color: transfer.status == TransferStatus.completed
                                    ? const Color(0xFF34C759)
                                    : Colors.orange,
                              ),
                            ),
                            if (transfer.status == TransferStatus.transferring) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _cancel(transfer.id),
                                tooltip: 'Cancel',
                                icon: const Icon(Icons.cancel, color: Colors.red),
                              ),
                            ] else if (transfer.status == TransferStatus.failed) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _retry(transfer.id),
                                tooltip: 'Retry',
                                icon: const Icon(Icons.refresh, color: Color(0xFF007AFF)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
