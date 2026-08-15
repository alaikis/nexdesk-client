import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'share_provider.dart';

class ShareBrowserScreen extends StatefulWidget {
  final int shareId;

  const ShareBrowserScreen({super.key, required this.shareId});

  @override
  State<ShareBrowserScreen> createState() => _ShareBrowserScreenState();
}

class _ShareBrowserScreenState extends State<ShareBrowserScreen> {
  @override
  Widget build(BuildContext context) {
    final files = context.watch<ShareProvider>().currentFiles;
    final path = context.watch<ShareProvider>().currentPath;
    final loading = context.watch<ShareProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(path),
        actions: [
          IconButton(
            onPressed: () async {
              final url = await context.read<ShareProvider>().getDownloadUrl(widget.shareId, path);
              if (url != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download: $url')));
              }
            },
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? const Center(child: Text('Empty folder'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(file.isDir ? Icons.folder : Icons.insert_drive_file),
                        title: Text(file.name),
                        subtitle: Text(file.isDir ? 'Folder' : '${file.size} bytes'),
                        trailing: file.isDir
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  final url = await context.read<ShareProvider>().getDownloadUrl(widget.shareId, file.path);
                                  if (url != null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download: $url')));
                                  }
                                },
                                icon: const Icon(Icons.download),
                              ),
                        onTap: file.isDir
                            ? () {
                                context.read<ShareProvider>().browseShare(widget.shareId, file.path);
                              }
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
