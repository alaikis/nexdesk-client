import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/signaling_service.dart';
import '../../core/api_client.dart';
import '../../features/session/session_provider.dart';
import '../../platform/windows_print_service.dart';
import '../../platform/macos_print_service.dart';
import '../../platform/linux_print_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nex_button.dart';

class PrintJobItem {
  String id;
  String fileName;
  int fileSize;
  String format;
  String status;
  String? printerName;
  String? errorMessage;
  Uint8List? fileBytes;
  DateTime createdAt;

  PrintJobItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.format,
    this.status = 'pending',
    this.printerName,
    this.errorMessage,
    this.fileBytes,
    required this.createdAt,
  });

  factory PrintJobItem.fromJson(Map<String, dynamic> json) {
    return PrintJobItem(
      id: json['id']?.toString() ?? const Uuid().v4(),
      fileName: json['file_name'] as String? ?? 'unknown',
      fileSize: json['file_size'] as int? ?? 0,
      format: json['format'] as String? ?? 'image',
      status: json['status'] as String? ?? 'pending',
      printerName: json['printer_name'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RemotePrintScreen extends StatefulWidget {
  final String sessionId;
  const RemotePrintScreen({super.key, required this.sessionId});

  @override
  State<RemotePrintScreen> createState() => _RemotePrintScreenState();
}

class _RemotePrintScreenState extends State<RemotePrintScreen> {
  final List<PrintJobItem> _jobs = [];
  bool _loading = true;
  String? _selectedPrinter;
  List<String> _printers = [];
  SignalingService? _signaling;
  StreamSubscription<dynamic>? _printSub;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadPrinters();
    _listenForPrintJobs();
  }

  @override
  void dispose() {
    _printSub?.cancel();
    super.dispose();
  }

  void _listenForPrintJobs() {
    final sp = context.read<SessionProvider>();
    _signaling = sp.signalingService;
    if (_signaling == null) return;

    _printSub = _signaling!.messages.listen((msg) {
      if (msg.type == SignalingMessageType.remotePrint && msg.sessionId == widget.sessionId) {
        final payload = Map<String, dynamic>.from(msg.payload);
        final fileData = payload['file_data'] as String?;
        Uint8List? bytes;
        if (fileData != null && fileData.isNotEmpty) {
          bytes = base64Decode(fileData);
        }
        final job = PrintJobItem(
          id: payload['job_id']?.toString() ?? const Uuid().v4(),
          fileName: payload['file_name'] as String? ?? 'print_job',
          fileSize: (payload['file_size'] as int?) ?? bytes?.length ?? 0,
          format: payload['format'] as String? ?? 'image',
          fileBytes: bytes,
          createdAt: DateTime.now(),
        );
        if (mounted) {
          setState(() {
            _jobs.insert(0, job);
          });
        }
      }
    });
  }

  Future<void> _loadJobs() async {
    try {
      final api = ApiClient();
      final jobs = await api.listPrintJobs(widget.sessionId);
      if (mounted) {
        setState(() {
          _jobs.clear();
          for (final j in jobs) {
            _jobs.add(PrintJobItem.fromJson(j as Map<String, dynamic>));
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadPrinters() async {
    List<String> printers = [];
    try {
      if (Theme.of(context).platform == TargetPlatform.windows) {
        printers = await WindowsPrintService.getPrinters();
      } else if (Theme.of(context).platform == TargetPlatform.macOS) {
        printers = await MacOSPrintService.getPrinters();
      } else if (Theme.of(context).platform == TargetPlatform.linux) {
        printers = await LinuxPrintService.getPrinters();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _printers = printers;
        if (printers.isNotEmpty && _selectedPrinter == null) {
          _selectedPrinter = printers.first;
        }
      });
    }
  }

  Future<void> _printJob(PrintJobItem job) async {
    if (_selectedPrinter == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectPrinterFirst)),
      );
      return;
    }

    job.status = 'printing';
    if (mounted) setState(() {});

    try {
      bool success = false;
      if (job.fileBytes != null && job.fileBytes!.isNotEmpty) {
        if (Theme.of(context).platform == TargetPlatform.windows) {
          success = await WindowsPrintService.printBytes(
            _selectedPrinter!,
            job.fileBytes!,
            job.fileName,
            job.format,
          );
        } else if (Theme.of(context).platform == TargetPlatform.macOS) {
          success = await MacOSPrintService.printBytes(
            _selectedPrinter!,
            job.fileBytes!,
            job.fileName,
            job.format,
          );
        } else if (Theme.of(context).platform == TargetPlatform.linux) {
          success = await LinuxPrintService.printBytes(
            _selectedPrinter!,
            job.fileBytes!,
            job.fileName,
            job.format,
          );
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          job.status = 'completed';
          job.printerName = _selectedPrinter;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sentToPrinter(_selectedPrinter!))),
          );
        } else {
          job.status = 'failed';
          job.errorMessage = l10n.printFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.printFailed)),
          );
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        job.status = 'failed';
        job.errorMessage = e.toString();
        setState(() {});
      }
    }
  }

  Future<void> _cancelJob(PrintJobItem job) async {
    try {
      await ApiClient().cancelPrintJob(widget.sessionId, int.tryParse(job.id) ?? 0);
      if (mounted) {
        job.status = 'cancelled';
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cancelFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _saveToFile(PrintJobItem job) async {
    if (job.fileBytes == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${job.fileName}';
      final file = File(filePath);
      await file.writeAsBytes(job.fileBytes!);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedToFile(filePath))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    final warningColor = isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(l10n.remotePrintTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPrinter,
                          decoration: InputDecoration(
                            labelText: l10n.printerLabel,
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(NexRadius.md),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(NexRadius.md),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(NexRadius.md),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                          items: _printers
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPrinter = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _loadPrinters,
                        icon: Icon(Icons.search, color: primaryColor, size: 18),
                        label: Text(
                          l10n.refresh,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _jobs.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noPrintJobs,
                            style: TextStyle(fontSize: 15, color: textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(NexRadius.md),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildFormatIcon(
                                        job.format,
                                        errorColor,
                                        warningColor,
                                        primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.fileName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${job.format.toUpperCase()} • ${_formatSize(job.fileSize)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(job.status, isDark),
                                    ],
                                  ),
                                  if (job.errorMessage != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      job.errorMessage!,
                                      style: TextStyle(color: errorColor, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (job.status == 'pending')
                                        NexButton(
                                          text: l10n.printJob,
                                          variant: NexButtonVariant.primary,
                                          size: NexButtonSize.small,
                                          icon: const Icon(Icons.print, size: 16),
                                          onPressed: () => _printJob(job),
                                        ),
                                      if (job.status == 'pending' || job.status == 'printing') ...[
                                        if (job.status == 'pending') const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => _cancelJob(job),
                                          style: TextButton.styleFrom(
                                            foregroundColor: errorColor,
                                          ),
                                          child: Text(
                                            l10n.cancelJob,
                                            style: TextStyle(
                                              color: errorColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (job.fileBytes != null && job.fileBytes!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.download, color: successColor, size: 20),
                                          onPressed: () => _saveToFile(job),
                                          tooltip: l10n.saveJob,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormatIcon(
    String format,
    Color errorColor,
    Color warningColor,
    Color primaryColor,
  ) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: errorColor, size: 32);
      case 'image':
        return Icon(Icons.image, color: warningColor, size: 32);
      default:
        return Icon(Icons.description, color: primaryColor, size: 32);
    }
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);

    Color bgColor;
    Color textColor;

    switch (status) {
      case 'printing':
        bgColor = primaryColor.withValues(alpha: 0.12);
        textColor = primaryColor;
        break;
      case 'completed':
        bgColor = successColor.withValues(alpha: 0.12);
        textColor = successColor;
        break;
      case 'failed':
      case 'cancelled':
        bgColor = errorColor.withValues(alpha: 0.12);
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
        borderRadius: BorderRadius.circular(NexRadius.full),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
