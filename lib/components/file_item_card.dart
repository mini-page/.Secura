import 'package:flutter/material.dart';
import '../features/vault/vault_file_model.dart';

enum FileAction { open, share, encrypt, restore, delete }

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
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.file.isEncrypted ? Icons.lock_rounded : Icons.insert_drive_file_rounded,
                      color: widget.file.isEncrypted ? Theme.of(context).primaryColor : Colors.grey,
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
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.file.isEncrypted ? Icons.lock_rounded : Icons.insert_drive_file_rounded,
                          color: widget.file.isEncrypted ? Theme.of(context).primaryColor : Colors.grey,
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
