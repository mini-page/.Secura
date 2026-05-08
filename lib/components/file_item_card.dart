import 'package:flutter/material.dart';
import '../features/vault/vault_file_model.dart';

enum FileAction { open, share, encrypt, restore, delete }

/// File type categories for icon display
enum FileType { image, video, audio, document, pdf, spreadsheet, archive, code, unknown }

/// Determine file type from extension
FileType getFileType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();

  // Images
  if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'heic', 'heif'].contains(ext)) {
    return FileType.image;
  }

  // Videos
  if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'].contains(ext)) {
    return FileType.video;
  }

  // Audio
  if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'].contains(ext)) {
    return FileType.audio;
  }

  // Documents
  if (['doc', 'docx', 'txt', 'rtf', 'odt', 'pages'].contains(ext)) {
    return FileType.document;
  }

  // PDF
  if (['pdf'].contains(ext)) {
    return FileType.pdf;
  }

  // Spreadsheets
  if (['xls', 'xlsx', 'csv', 'ods', 'numbers'].contains(ext)) {
    return FileType.spreadsheet;
  }

  // Archives
  if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(ext)) {
    return FileType.archive;
  }

  // Code
  if (['dart', 'js', 'ts', 'py', 'java', 'cpp', 'c', 'h', 'html', 'css', 'json', 'xml', 'yaml'].contains(ext)) {
    return FileType.code;
  }

  return FileType.unknown;
}

/// Get icon for file type
IconData getFileTypeIcon(FileType type, {bool isEncrypted = false}) {
  if (isEncrypted) return Icons.lock_rounded;

  switch (type) {
    case FileType.image:
      return Icons.image_rounded;
    case FileType.video:
      return Icons.video_file_rounded;
    case FileType.audio:
      return Icons.audio_file_rounded;
    case FileType.document:
      return Icons.description_rounded;
    case FileType.pdf:
      return Icons.picture_as_pdf_rounded;
    case FileType.spreadsheet:
      return Icons.table_chart_rounded;
    case FileType.archive:
      return Icons.folder_zip_rounded;
    case FileType.code:
      return Icons.code_rounded;
    case FileType.unknown:
      return Icons.insert_drive_file_rounded;
  }
}

/// Get color for file type
Color getFileTypeColor(FileType type, BuildContext context) {
  switch (type) {
    case FileType.image:
      return Colors.purple;
    case FileType.video:
      return Colors.red;
    case FileType.audio:
      return Colors.orange;
    case FileType.document:
      return Colors.blue;
    case FileType.pdf:
      return Colors.red.shade700;
    case FileType.spreadsheet:
      return Colors.green;
    case FileType.archive:
      return Colors.amber.shade700;
    case FileType.code:
      return Colors.teal;
    case FileType.unknown:
      return Colors.grey;
  }
}

class FileItemCard extends StatefulWidget {
  const FileItemCard({
    required this.file,
    this.onAction,
    this.index = 0,
    super.key,
  });

  final VaultFile file;
  final Function(FileAction)? onAction;
  final int index;

  @override
  State<FileItemCard> createState() => _FileItemCardState();
}

class _FileItemCardState extends State<FileItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (widget.index * 0.1).clamp(0, 0.5),
        1.0,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (widget.index * 0.1).clamp(0, 0.5),
        1.0,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true, // Allow it to expand correctly
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.file.isEncrypted
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : getFileTypeColor(getFileType(widget.file.name), context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        getFileTypeIcon(getFileType(widget.file.name), isEncrypted: widget.file.isEncrypted),
                        color: widget.file.isEncrypted
                            ? Theme.of(context).primaryColor
                            : getFileTypeColor(getFileType(widget.file.name), context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.isEncrypted ? widget.file.name.replaceAll('.secura', '') : widget.file.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.file.sizeString} • Secure Vault Storage',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildActionItem(context, FileAction.open, Icons.open_in_new_rounded, 'Open File', 'View content securely'),
              _buildActionItem(context, FileAction.share, Icons.share_rounded, 'Share Copy', 'Export a decrypted copy'),
              if (!widget.file.isEncrypted)
                _buildActionItem(context, FileAction.encrypt, Icons.lock_outline_rounded, 'Encrypt Now', 'Protect with AES-256'),
              _buildActionItem(context, FileAction.restore, Icons.settings_backup_restore_rounded, 'Restore File', 'Move back to public storage'),
              _buildActionItem(context, FileAction.delete, Icons.delete_outline_rounded, 'Delete Permanently', 'Wipe from device', isDestructive: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, 
    FileAction action, 
    IconData icon, 
    String label, 
    String sub, 
    {bool isDestructive = false}
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onAction?.call(action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withValues(alpha: 0.1) 
                    : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isDestructive ? Colors.red : Theme.of(context).primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isDestructive ? Colors.red.withValues(alpha: 0.5) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(widget.file.path),
            direction: DismissDirection.horizontal,
            // Swipe Left to Open, Swipe Right to Delete
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                // Swipe Left -> Open
                widget.onAction?.call(FileAction.open);
                return false; 
              } else if (direction == DismissDirection.startToEnd) {
                // Swipe Right -> Delete
                widget.onAction?.call(FileAction.delete);
                return false; 
              }
              return false;
            },
            background: _buildSwipeBackground(
              Alignment.centerLeft, 
              Colors.red, 
              Icons.delete_outline_rounded, 
              'DELETE'
            ),
            secondaryBackground: _buildSwipeBackground(
              Alignment.centerRight, 
              Theme.of(context).primaryColor, 
              Icons.open_in_new_rounded, 
              'OPEN'
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showActionMenu(context),
                borderRadius: BorderRadius.circular(28),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Hero(
                      tag: widget.file.path,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.file.isEncrypted
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : getFileTypeColor(getFileType(widget.file.name), context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          getFileTypeIcon(getFileType(widget.file.name), isEncrypted: widget.file.isEncrypted),
                          color: widget.file.isEncrypted
                              ? Theme.of(context).primaryColor
                              : getFileTypeColor(getFileType(widget.file.name), context),
                          size: 26,
                        ),
                      ),
                    ),
                    title: Text(
                      widget.file.isEncrypted ? widget.file.name.replaceAll('.secura', '') : widget.file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${widget.file.sizeString} • ${widget.file.modified.day}/${widget.file.modified.month}/${widget.file.modified.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Alignment alignment, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}
