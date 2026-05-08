# AI Agent Guide - Secura Project

> **FOR OTHER AI AGENTS**: Read this and memory.md before making changes.

---

## Quick Start

1. Read `.claude/memory.md` first
2. Recent security upgrades - see memory.md for details
3. Use Riverpod for state management
4. Follow error handling patterns below

---

## Key Rules

- ❌ Don't use SHA-256 loop for key derivation → Use PBKDF2 with 600k iterations
- ❌ Don't store plain JSON backup → Encrypt before upload
- ❌ Don't restore without user confirmation
- ❌ Don't skip warnings before destructive operations

---

## Commands

```bash
flutter pub get    # Install
flutter run        # Run
flutter analyze    # Lint
flutter build apk  # Build
```

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/core/services/encryption_service.dart` | PBKDF2 (600k iterations) |
| `lib/core/services/backup_service.dart` | Encrypted backup |
| `lib/features/auth/auth_screen.dart` | PIN rate limiting |
| `lib/features/vault/vault_provider.dart` | Error handling |

---

## Error Patterns

```dart
// File ops
try { ... } on VaultException catch (e) {
  ref.read(lastErrorProvider.notifier).state = e.displayMessage;
}

// Backup ops
final result = await BackupService.performBackup(account);
if (!result.success) { /* show result.errorMessage */ }
```

---

## Memory

After changes: Update `.claude/memory.md` with what changed.

---

*Last updated: 2026-05-09*