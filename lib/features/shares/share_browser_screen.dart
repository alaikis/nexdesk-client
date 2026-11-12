import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'share_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ShareBrowserScreen extends StatefulWidget {
  final int shareId;

  const ShareBrowserScreen({super.key, required this.shareId});

  @override
  State<ShareBrowserScreen> createState() => _ShareBrowserScreenState();
}

class _ShareBrowserScreenState extends State<ShareBrowserScreen> {
  Color _fileIconColor(String name, bool isDir, WiseTheme wise) {
    if (isDir) {
      return wise.primary;
    }
    final ext = name.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'svg':
      case 'webp':
        return wise.warning;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
      case 'xlsx':
      case 'pptx':
        return wise.primary;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return wise.error;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return wise.success;
      default:
        return wise.textSecondary;
    }
  }

  IconData _fileIcon(String name, bool isDir) {
    if (isDir) return Icons.folder;
    final ext = name.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'svg':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  List<String> _buildBreadcrumbs(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final files = context.watch<ShareProvider>().currentFiles;
    final path = context.watch<ShareProvider>().currentPath;
    final loading = context.watch<ShareProvider>().loading;
    final l10n = AppLocalizations.of(context)!;
    final shareProvider = context.read<ShareProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final backgroundColor = wise.background;
    final cardColor = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;
    final borderColor = wise.border;

    final breadcrumbs = _buildBreadcrumbs(path);

    final scaffoldActions = <Widget>[
      IconButton(
        onPressed: () async {
          final url = await shareProvider.getDownloadUrl(widget.shareId, path);
          if (url != null && mounted) {
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.downloadLink(url))));
          }
        },
        icon: Icon(Icons.download, size: 20, color: textSecondary),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(wise.radius.sm),
          ),
        ),
        tooltip: l10n.download,
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: breadcrumbs.isEmpty
            ? Text('/', style: TextStyle(fontSize: 15, color: textSecondary, fontFamily: 'monospace'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => shareProvider.browseShare(widget.shareId, '/'),
                      borderRadius: BorderRadius.circular(wise.radius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Root',
                          style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    ...breadcrumbs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final seg = entry.value;
                      final isLast = idx == breadcrumbs.length - 1;
                      final subPath = '/${breadcrumbs.sublist(0, idx + 1).join('/')}';
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('/', style: TextStyle(fontSize: 13, color: textTertiary)),
                          ),
                          if (isLast)
                            Text(
                              seg,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                fontFamily: 'monospace',
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => shareProvider.browseShare(widget.shareId, subPath),
                              borderRadius: BorderRadius.circular(wise.radius.sm),
                              child: Text(
                                seg,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
        actions: scaffoldActions,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
          : files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: wise.primarySoft,
                          borderRadius: BorderRadius.circular(wise.radius.lg),
                        ),
                        child: Icon(Icons.folder_open, size: 32, color: textTertiary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.emptyFolder,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textSecondary, height: 1.53),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final iconColor = _fileIconColor(file.name, file.isDir, WiseTheme.of(context));
                    return _FileItem(
                      name: file.name,
                      subtitle: file.isDir ? l10n.folder : '${file.size} ${l10n.bytes}',
                      isDir: file.isDir,
                      icon: _fileIcon(file.name, file.isDir),
                      iconColor: iconColor,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      onTap: file.isDir
                          ? () {
                              shareProvider.browseShare(widget.shareId, file.path);
                            }
                          : null,
                      onDownload: file.isDir
                          ? null
                          : () async {
                              final url = await shareProvider.getDownloadUrl(widget.shareId, file.path);
                              if (url != null && mounted) {
                                scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.downloadLink(url))));
                              }
                            },
                    );
                  },
                ),
    );
  }
}

class _FileItem extends StatefulWidget {
  final String name;
  final String subtitle;
  final bool isDir;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color primaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  const _FileItem({
    required this.name,
    required this.subtitle,
    required this.isDir,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.primaryColor,
    this.onTap,
    this.onDownload,
  });

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final wise = WiseTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering
                ? wise.surface.withValues(alpha: 0.5)
                : widget.cardColor,
            borderRadius: BorderRadius.circular(wise.radius.medium),
            border: Border.all(color: widget.borderColor),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 24, color: widget.iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                        height: 1.53,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 13, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.onDownload != null)
                IconButton(
                  onPressed: widget.onDownload,
                  icon: Icon(Icons.download, size: 20),
                  color: widget.primaryColor,
                  style: IconButton.styleFrom(
                    foregroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(wise.radius.sm),
                    ),
                  ),
                  tooltip: 'Download',
                )
              else if (widget.isDir)
                Icon(Icons.chevron_right, size: 20, color: widget.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
