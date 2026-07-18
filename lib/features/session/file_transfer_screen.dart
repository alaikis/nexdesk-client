import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    final transfers = await _service.listTransfers(widget.sessionId);
    setState(() {
      _transfers = transfers;
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    // TODO: integrate file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker integration pending')),
    );
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
                          ],
                        ),
                        trailing: Text(
                          transfer.status.name,
                          style: TextStyle(
                            color: transfer.status == TransferStatus.completed
                                ? const Color(0xFF34C759)
                                : Colors.orange,
                          ),
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
