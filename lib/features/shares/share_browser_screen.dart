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
  Color _fileIconColor(String name, bool isDir, bool isDark) {
    if (isDir) {
      return isDark ? WiseColors.primaryDark : WiseColors.primaryLight;
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
        return isDark ? WiseColors.warningDark : WiseColors.warningLight;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
      case 'xlsx':
      case 'pptx':
        return isDark ? WiseColors.primaryDark : WiseColors.primaryLight;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return isDark ? WiseColors.destructiveDark : WiseColors.destructiveLight;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return isDark ? WiseColors.successDark : WiseColors.successLight;
      default:
        return isDark ? WiseColors.textSecondaryDark : WiseColors.textSecondaryLight;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? WiseColors.primaryDark : WiseColors.primaryLight;
    final backgroundColor = isDark ? WiseColors.backgroundDark : WiseColors.backgroundSubtleLight;
    final cardColor = isDark ? WiseColors.surfaceDark : WiseColors.backgroundLight;
    final textPrimary = isDark ? WiseColors.textPrimaryDark : WiseColors.textPrimaryLight;
    final textSecondary = isDark ? WiseColors.textSecondaryDark : WiseColors.textSecondaryLight;
    final textTertiary = isDark ? WiseColors.textTertiaryDark : WiseColors.textTertiaryLight;
    final borderColor = isDark ? WiseColors.borderDark : WiseColors.borderLight;

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
            borderRadius: BorderRadius.circular(NexRadius.sm),
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
                      borderRadius: BorderRadius.circular(NexRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Root',
                          style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w500),
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
                              borderRadius: BorderRadius.circular(NexRadius.sm),
                              child: Text(
                                seg,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
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
                          color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(NexRadius.lg),
                        ),
                        child: Icon(Icons.folder_open, size: 32, color: textTertiary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.emptyFolder,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final iconColor = _fileIconColor(file.name, file.isDir, isDark);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                ? (isDark ? WiseColors.surfaceDark.withValues(alpha: 0.5) : WiseColors.surfaceLight)
                : widget.cardColor,
            borderRadius: BorderRadius.circular(NexRadius.md),
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
                        fontWeight: FontWeight.w500,
                        color: widget.textPrimary,
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
                      borderRadius: BorderRadius.circular(NexRadius.sm),
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
