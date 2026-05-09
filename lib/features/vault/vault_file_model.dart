class VaultFile {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final bool isEncrypted;
  final DateTime? lastOpened;

  VaultFile({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.isEncrypted,
    this.lastOpened,
  });

  String get sizeString {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
