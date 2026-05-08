# Secura Project Memory - AI Collaborator Guide

> **IMPORTANT**: This file is the central knowledge base for all AI agents working on the Secura project. All AI collaborators should read this file before making any changes.

---

## Project Overview

**Secura** is a production-ready Flutter mobile application for secure file storage with AES-256-GCM encryption, PIN-based access, and Google Drive cloud backup.

**Technology Stack:**
- Flutter 3.x with Dart 3.x
- Riverpod for state management
- AES-256-GCM encryption with PBKDF2 key derivation
- Google Sign-In & Google Drive API integration

---

## Recent Security Improvements (May 2026)

All recent changes are documented here for AI collaborators to understand the current state:

### 1. Encryption Service Upgrade (`lib/core/services/encryption_service.dart`)

**Changed from:**
- Simple SHA-256 with 10,000 iterations
- Weak key derivation vulnerable to GPU attacks

**Changed to:**
- PBKDF2-HMAC-SHA256 with 600,000 iterations (OWASP recommended)
- Proper PBKDF2 implementation with `KeyDerivationConfig` class
- Added `EncryptionException` custom exception
- Added `verifyHash()` method for security answer verification
- Key validation now enforces exactly 32 bytes

### 2. Backup Service Upgrade (`lib/core/services/backup_service.dart`)

**Changed from:**
- Plain JSON backup stored in Google Drive
- Silent restore (applied before user confirmation)

**Changed to:**
- Backup data encrypted before upload
- `BackupResult` class for operation feedback
- `BackupMetadata` class with version, timestamp, checksum
- Split into check/apply phases - restore only after user confirmation

### 3. Auth Screen Improvements (`lib/features/auth/auth_screen.dart`)

**Added:**
- PIN complexity enforcement (blocks 0000, 1234, 4321, etc.)
- Security question rate limiting (3 attempts → 5 min lockout)
- Pre-PIN-reset warning dialog
- Expanded security questions from 4 to 8 options

### 4. Google Auth Service (`lib/core/services/google_auth_service.dart`)

**Added:**
- Session invalidation callback system for logout handling

### 5. File Vault Service (`lib/core/services/file_vault_service.dart`)

**Added:**
- `VaultException` custom exception with user-friendly messages
- File size validation (50MB max)
- Temp file tracking and cleanup
- Better scoped storage handling

### 6. Other Updates

- Vault provider with error handling providers
- File type icons for images, videos, documents, etc.
- Sign out button in settings
- Fixed backup restore flow in Google auth screen
- Logout functionality in user provider

---

## File Structure

```
lib/
├── main.dart
├── app_shell.dart
├── components/
│   ├── file_item_card.dart          # File type icons
│   └── ...
├── core/
│   ├── services/
│   │   ├── encryption_service.dart     # PBKDF2 upgrade
│   │   ├── backup_service.dart         # Encrypted backup
│   │   ├── file_vault_service.dart      # VaultException
│   │   └── google_auth_service.dart    # Session callbacks
│   └── theme/
└── features/
    ├── auth/
    │   ├── auth_screen.dart            # PIN complexity, rate limiting
    │   └── user_provider.dart          # Logout
    └── vault/
        └── vault_provider.dart         # Error handling
```

---

## Key Conventions

1. **Error Handling**: Use `VaultException` for files, `BackupResult` for backups
2. **Security**: Use PBKDF2 with 600k iterations, encrypt backup data
3. **State**: Use Riverpod providers from vault_provider.dart
4. **UI Feedback**: Use lastErrorProvider and vaultOperationStatusProvider

---

## How to Update

After changes, update this file with:
- Date of change
- Files modified
- What changed and why

---

## Fixes Applied

- Fixed `math.Random.secure()` import alias in encryption_service.dart
- Fixed StateProvider to NotifierProvider for Riverpod 3.x compatibility in vault_provider.dart
- Fixed session provider dispose pattern (using ref.onDispose)
- Fixed async context warnings in auth_screen.dart
- All issues resolved: `flutter analyze` passes with no errors

---

**Last Updated**: 2026-05-09 | **Version**: 1.0.0