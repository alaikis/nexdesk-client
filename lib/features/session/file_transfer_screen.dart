import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/file_transfer_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

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

  @visibleForTesting
  void simulateTransferAdded(FileTransfer transfer) {
    setState(() {
      _transfers.add(transfer);
      _loading = false;
    });
  }

  Future<void> _loadTransfers() async {
    try {
      final transfers = await _service.listTransfers(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _transfers = transfers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
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
    final stat = await file.stat();

    final placeholder = FileTransfer(
      id: -1,
      fileName: file.path.split('/').last,
      filePath: file.path,
      fileSize: stat.size,
      direction: TransferDirection.upload,
    );
    setState(() {
      _transfers.add(placeholder);
    });

    final transfer = await _service.startUpload(
      widget.sessionId,
      file,
      onProgress: (transferred, total) {
        if (!mounted) return;
        setState(() {
          if (_transfers.isNotEmpty && _transfers.last.id == placeholder.id) {
            _transfers.last.transferred = transferred;
          }
        });
      },
    );
    if (!mounted) return;
    setState(() {
      final idx = _transfers.indexWhere((t) => t.id == placeholder.id);
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
      final file = File(transfer.filePath);
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
    final l10n = AppLocalizations.of(context)!;
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final backgroundColor = wise.background;
    final cardColor = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final borderColor = wise.border;
    final successColor = wise.success;
    final errorColor = wise.error;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.fileTransfersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transfers.isEmpty
              ? Center(
                  child: Text(
                    l10n.noTransfersYet,
                    style: TextStyle(fontSize: 15, color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = _transfers[index];
                    final isUpload = transfer.direction == TransferDirection.upload;
                     return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(wise.radius.medium),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isUpload ? Icons.upload_file : Icons.download,
                                color: isUpload ? primaryColor : successColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                       Text(
                                         transfer.fileName,
                                         style: TextStyle(
                                           fontSize: 15,
                                           fontWeight: FontWeight.w600,
                                           color: textPrimary,
                                         ),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${transfer.fileSize ~/ 1024} KB',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                               _buildStatusBadge(transfer.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                           ClipRRect(
                             borderRadius: BorderRadius.circular(wise.radius.full),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: transfer.progress,
                                backgroundColor: borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          ),
                          if (transfer.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              transfer.errorMessage!,
                              style: TextStyle(color: errorColor, fontSize: 12),
                            ),
                          ],
                          if (transfer.status == TransferStatus.transferring) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _cancel(transfer.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: errorColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                 child: Text(
                                   l10n.cancelTransfer,
                                   style: TextStyle(
                                     color: errorColor,
                                     fontSize: 14,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                              ),
                            ),
                          ] else if (transfer.status == TransferStatus.failed) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _retry(transfer.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                 child: Text(
                                   l10n.retryTransfer,
                                   style: TextStyle(
                                     color: primaryColor,
                                     fontSize: 14,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        backgroundColor: primaryColor,
        foregroundColor: wise.onPrimary,
      ),
    );
  }

  Widget _buildStatusBadge(TransferStatus status) {
    final wise = WiseTheme.of(context);
    final successColor = wise.success;
    final errorColor = wise.error;
    final surfaceColor = wise.surface;
    final textSecondary = wise.textSecondary;

    Color bgColor;
    Color textColor;

    switch (status) {
      case TransferStatus.completed:
        bgColor = wise.successSoft;
        textColor = successColor;
        break;
      case TransferStatus.failed:
        bgColor = wise.errorSoft;
        textColor = errorColor;
        break;
      default:
        bgColor = surfaceColor;
        textColor = textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(wise.radius.full),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
