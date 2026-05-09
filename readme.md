# Secura - Secure File Vault

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![License](https://img.shields.io/badge/License-MIT-green)

Secura is a production-ready mobile-first secure file vault application built with Flutter. It provides AES-256-GCM encryption for securing files with a local PIN protection system and Google Drive cloud backup.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Security Implementation](#security-implementation)
4. [Features](#features)
5. [Project Structure](#project-structure)
6. [Core Services](#core-services)
7. [State Management](#state-management)
8. [UI/UX Design System](#uiux-design-system)
9. [Setup & Installation](#setup--installation)
10. [Security & Privacy](#security--privacy)
11. [API & Dependencies](#api--dependencies)
12. [Testing](#testing)
13. [Recent Improvements](#recent-improvements)
14. [Known Limitations](#known-limitations)
15. [Future Improvements](#future-improvements)

---

## Project Overview

**Secura** is a privacy-focused file vault application designed for users who need secure, encrypted storage for sensitive files on their mobile devices. The app uses a zero-knowledge architecture where encryption keys are derived from the user's PIN and never stored in plaintext.

### Key Highlights

- **Military-Grade Encryption**: AES-256-GCM with PBKDF2-HMAC-SHA256 key derivation
- **Zero-Knowledge Architecture**: Server never sees user PIN or encryption keys
- **Cloud Backup**: Encrypted backups to Google Drive App Data Folder
- **Secure File Handling**: Secure deletion with file shredding
- **Activity Logging**: Comprehensive audit trail for security awareness

---

## Architecture

Secura follows a **feature-first modular architecture** using **Riverpod** for reactive state management.

```
lib/
├── main.dart                 # App entry point
├── app_shell.dart           # Root shell with navigation
├── features/                # Feature modules (auth, vault, settings, etc.)
│   ├── auth/               # Authentication & login flow
│   ├── vault/              # File vault & storage
│   ├── settings/           # App settings & preferences
│   ├── onboarding/         # First-time user experience
│   └── splash/             # App initialization
├── components/              # Reusable UI components
│   ├── file_item_card.dart
│   ├── app_header.dart
│   └── ...
└── core/                    # Shared business logic
    ├── services/           # Business services
    │   ├── encryption_service.dart
    │   ├── backup_service.dart
    │   ├── file_vault_service.dart
    │   ├── storage_service.dart
    │   └── google_auth_service.dart
    └── theme/              # Theming & design system
```

### Design Patterns

- **Provider Pattern**: Riverpod for dependency injection and state management
- **Repository Pattern**: FileVaultService abstracts file operations
- **Service Layer**: Encryption, backup, and auth logic separated into services

---

## Security Implementation

### Encryption

| Aspect | Implementation |
|--------|---------------|
| **Algorithm** | AES-256-GCM |
| **IV Size** | 12 bytes (96-bit) |
| **Key Derivation** | PBKDF2-HMAC-SHA256 |
| **Iterations** | 10,000 (Simple) / 600,000 (Advanced) |
| **Salt Size** | 32 bytes (256-bit) |
| **Key Size** | 32 bytes (256-bit) |

### Key Derivation Flow

```
User PIN + Random Salt → PBKDF2 (600k iterations) → 256-bit AES Key
                                              ↓
                                       SHA-256 Hash (stored for verification)
```

### Security Features

1. **PIN-Based Access**: 4-digit PIN with rate limiting (3 attempts → 30s lockout)
2. **Security Questions**: Account recovery with 5-minute lockout after 3 failed attempts
3. **PIN Complexity Check**: Blocks common patterns (0000, 1234, etc.)
4. **Secure Deletion**: File shredding with multi-pass overwrite
5. **Encrypted Backups**: Backup data encrypted before upload to Google Drive
6. **Session Management**: Session cleared on logout

### Data Protection

- **At Rest**: All files encrypted with unique per-file IV
- **In Transit**: HTTPS for all network communications
- **In Memory**: Session key held only in memory, cleared on logout

---

## Features

### Authentication
- Google Sign-In for identity management
- Local PIN-based vault access
- PIN reset with security question verification
- Rate limiting on failed attempts
- Session management with logout capability

### File Vault
- Add files with optional encryption
- Browse encrypted and plain files
- Search files by name
- View file details (size, date, type)
- File type-specific icons (images, videos, documents, etc.)

### Security Operations
- **Encrypt**: Encrypt plain files to vault
- **Decrypt**: Decrypt files for viewing
- **Delete**: Move to recycle bin
- **Permanent Delete**: Secure file shredding
- **Restore**: Export decrypted files to public storage

### Cloud Backup
- Manual backup to Google Drive
- Backup metadata with timestamps
- Encrypted backup data
- Restore with user confirmation dialog
- Delete cloud backup option

### Settings & Preferences
- Theme selection (Light/Dark/System)
- Strict 2FA mode (Google sign-in every launch)
- Auto-lock timeout (5 minutes inactivity)
- Change PIN
- Activity logs viewing
- Factory reset

---

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── app_shell.dart                      # Root shell with bottom navigation
├── components/
│   ├── components.dart                 # Barrel file for exports
│   ├── app_header.dart                # Screen header component
│   ├── app_toggle_tile.dart           # Settings toggle switch
│   ├── file_item_card.dart            # File list item with actions
│   ├── onboarding_page_indicator.dart  # Onboarding dots
│   ├── primary_cta_button.dart        # Primary button component
│   ├── theme_mode_selector.dart       # Theme selection widget
│   ├── shimmer_card.dart              # Loading placeholder
│   ├── team_accordion.dart            # Accordion component
│   └── secaura_notifications.dart      # Toast/notification helper
├── core/
│   ├── services/
│   │   ├── encryption_service.dart    # AES-256-GCM encryption
│   │   ├── storage_service.dart       # Secure local storage
│   │   ├── file_vault_service.dart    # File operations
│   │   ├── backup_service.dart        # Google Drive backup
│   │   ├── google_auth_service.dart   # Google Sign-In
│   │   └── activity_logger.dart       # Audit logging
│   ├── theme/
│   │   ├── app_theme.dart              # Theme definitions
│   │   └── theme_provider.dart        # Theme state management
│   └── file_action_handler.dart       # File action routing
├── features/
│   ├── auth/
│   │   ├── auth_screen.dart           # PIN entry/setup
│   │   ├── google_auth_screen.dart    # Google Sign-In
│   │   ├── user_provider.dart        # User state
│   │   ├── user_model.dart            # User data model
│   │   └── profile_edit_screen.dart   # Profile editing
│   ├── vault/
│   │   ├── home_screen.dart           # Main vault view
│   │   ├── encrypt_screen.dart        # Encrypted files tab
│   │   ├── decrypt_screen.dart        # Decrypted files tab
│   │   ├── import_screen.dart         # File import
│   │   ├── vault_provider.dart        # Vault state management
│   │   └── vault_file_model.dart      # File data model
│   ├── settings/
│   │   ├── settings_screen.dart       # Settings main screen
│   │   ├── settings_provider.dart    # Settings state
│   │   ├── about_screen.dart          # About page
│   │   ├── recycle_bin_screen.dart    # Deleted files
│   │   └── activity_logs_screen.dart  # Audit trail view
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # First-time user flow
│   └── splash/
│       └── splash_screen.dart         # App initialization
└── app_shell.dart                     # Navigation shell
```

---

## Core Services

### EncryptionService (`lib/core/services/encryption_service.dart`)

Responsible for all cryptographic operations:

- **generateSalt()**: Create cryptographically secure random salt (32 bytes)
- **deriveKey(pin, salt, iterations)**: PBKDF2 key derivation with configurable iterations
- **deriveKeyWithMode(pin, salt, mode)**: Derive key using simple (10k) or advanced (600k) mode
- **hashKey(key)**: Double SHA-256 for verification hash
- **hashString(input)**: SHA-256 for security answers
- **encryptBytes(data, key)**: AES-256-GCM encryption with unique IV
- **decryptBytes(data, key)**: AES-256-GCM decryption with legacy fallback
- **verifyHash()**: Verify plaintext against stored hash

### StorageService (`lib/core/services/storage_service.dart`)

Manages secure local storage using Flutter Secure Storage:

- **saveAuthHash() / getAuthHash()**: PIN verification hash
- **saveSalt() / getSalt()**: Key derivation salt
- **saveUser() / getUser()**: User profile persistence
- **getCurrentUser()**: Get last logged in user
- **saveThemeMode() / getThemeMode()**: Theme preference
- **setStrict2FA() / getStrict2FA()**: 2FA setting
- **setAutoLock() / getAutoLock()**: Auto-lock setting
- **setEncryptionMode() / getEncryptionMode()**: Simple or advanced encryption
- **getAllSettings()**: Export all settings for backup
- **restoreSettings()**: Restore from backup

### FileVaultService (`lib/core/services/file_vault_service.dart`)

Handles all file operations in the vault:

- **addFile()**: Import files with optional encryption
- **readFile()**: Decrypt and read file contents
- **deleteFile()**: Move to recycle bin
- **permanentlyDeleteFile()**: Secure file shredding
- **encryptFile()**: Encrypt existing plain files
- **restoreFile()**: Export to public storage
- **listFiles()**: Get all vault files
- **listRecycleBin()**: Get deleted files
- **cleanupTempFiles()**: Clean up temp decrypted files

### KeyCacheService (`lib/core/services/key_cache_service.dart`)

In-memory key caching for fast access:
- **cacheKey()**: Cache derived key in memory
- **clearCache()**: Clear key when app goes to background
- **cachedKey / hasKey**: Check if key is available

### MigrationService (`lib/core/services/migration_service.dart`)

Handles encryption mode switching:
- **getCurrentMode()**: Get current encryption mode
- **quickSwitchMode()**: Switch between simple/advanced mode

### BackupService (`lib/core/services/backup_service.dart`)

Manages encrypted cloud backups:

- **checkBackupExists()**: Check for backup without restoring
- **performBackup()**: Create encrypted backup
- **performRestore()**: Restore from encrypted backup
- **getBackupMetadata()**: Get backup timestamp/info
- **deleteBackup()**: Remove cloud backup

### GoogleAuthService (`lib/core/services/google_auth_service.dart`)

Handles Google Sign-In integration:

- **initialize()**: Setup Google Sign-In
- **signIn()**: Authenticate with Google
- **signOut()**: Sign out and clear session
- **signInSilently()**: Attempt silent re-authentication
- **registerSessionInvalidationCallback()**: Listen for external sign-outs

---

## State Management

### Riverpod Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `sessionProvider` | NotifierProvider | Current vault session key (derived from PIN) |
| `userProvider` | NotifierProvider | Current user profile from Google |
| `vaultProvider` | AsyncNotifierProvider | List of vault files |
| `searchQueryProvider` | NotifierProvider | Current search query |
| `filteredVaultProvider` | Provider | Search-filtered file list |
| `themeProvider` | StateNotifierProvider | App theme mode |
| `strict2FAProvider` | StateNotifierProvider | 2FA setting |
| `autoLockProvider` | StateNotifierProvider | Auto-lock setting |
| `encryptionModeProvider` | NotifierProvider | Simple (10k) or advanced (600k) iterations |
| `lastErrorProvider` | StateProvider | Last error for UI feedback |
| `vaultOperationStatusProvider` | StateProvider | Operation loading state |

### Authentication Flow

```
Splash → GoogleAuth (sign in) → AuthScreen (PIN entry/setup)
                                      ↓
                                VaultShell (main app with tabs)
```

### PIN Verification Flow

1. User enters 4-digit PIN
2. PIN + stored salt → PBKDF2 (600k iterations) → derived key
3. Derived key → SHA-256 hash
4. Compare hash with stored verification hash
5. If match, set session key and proceed

---

## UI/UX Design System

### Theme

The app uses Material Design 3 with custom theming:

- **Primary**: Deep blue (#1565C0)
- **Secondary**: Teal accent
- **Surface**: Adaptive (light/dark)
- **Cards**: Rounded corners (16-32px radius)
- **Typography**: Roboto with bold weights

### Color Scheme

```dart
// Light Theme
primary: #1565C0
onPrimary: #FFFFFF
surface: #FAFAFA
onSurface: #212121

// Dark Theme
primary: #42A5F5
onPrimary: #000000
surface: #121212
onSurface: #E0E0E0
```

### Key UI Components

- **FileItemCard**: Animated file list item with swipe actions, file type icons
- **AppHeader**: Consistent header across screens
- **ThemeModeSelector**: Theme selection widget
- **AppToggleTile**: Settings toggle switches
- **ShimmerCard**: Loading placeholder animation
- **PrimaryCtaButton**: Main call-to-action buttons

### File Type Icons

The app displays type-specific icons based on file extension:

- **Images**: Purple icon (jpg, png, gif, etc.)
- **Videos**: Red icon (mp4, mov, avi, etc.)
- **Audio**: Orange icon (mp3, wav, etc.)
- **Documents**: Blue icon (doc, txt, etc.)
- **PDF**: Red icon
- **Spreadsheets**: Green icon (xls, csv, etc.)
- **Archives**: Amber icon (zip, rar, etc.)
- **Code**: Teal icon (dart, js, py, etc.)
- **Encrypted**: Lock icon with primary color

---

## Setup & Installation

### Prerequisites

- Flutter SDK 3.x or later
- Dart SDK 3.x
- Android SDK (for Android builds)
- Xcode (for iOS builds)
- Google Cloud project with OAuth 2.0 configured

### Installation Steps

```bash
# 1. Clone the repository
git clone <repository-url>
cd Secura

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Building

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# iOS
flutter build ios

# Web
flutter build web
```

### Required Permissions

**Android (AndroidManifest.xml):**
- `INTERNET` - For Google Sign-In and cloud backup
- `READ_EXTERNAL_STORAGE` - File picker access
- `WRITE_EXTERNAL_STORAGE` - For older Android versions

**iOS (Info.plist):**
- `NSPhotoLibraryUsageDescription` - Photo library access

### Google Cloud Setup

The app uses Google Sign-In with the following configuration:

- **Server Client ID**: `788854121443-ntgt3ddqs5bvp87421il73sn7slh8pcm.apps.googleusercontent.com`
- **Scopes**: `email`, `https://www.googleapis.com/auth/drive.appdata`
- **Application Type**: Installed (Mobile)

---

## Security & Privacy

### Threat Model

1. **Device Theft**: Files encrypted at rest, PIN required to access
2. **Network Interception**: HTTPS only, no plaintext transmissions
3. **Backup Theft**: Backup data encrypted, key derived from user PIN
4. **Brute Force**: Rate limiting on PIN and security questions
5. **Memory Dumping**: Session key in memory only, cleared on logout

### Privacy Considerations

- No analytics or tracking
- No data sharing with third parties
- All encryption/decryption happens on-device
- Google Drive only stores encrypted blobs
- No server-side data processing

### Security Best Practices Implemented

- Zero-knowledge architecture
- OWASP-recommended PBKDF2 iterations
- Secure random number generation
- Constant-time comparison for hashes
- Secure file deletion (multi-pass overwrite)

---

## API & Dependencies

### Key Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Encryption
  encrypt: ^5.0.3
  crypto: ^3.0.3
  pointycastle: ^3.7.3

  # Storage
  flutter_secure_storage: ^9.0.0
  path_provider: ^2.1.2
  path: ^1.8.3

  # Google Services
  google_sign_in: ^6.2.1
  googleapis: ^12.0.0
  extension_google_sign_in_as_googleapis_auth: ^6.0.2

  # UI Utilities
  intl: ^0.19.0
```

### Environment Configuration

Create `android/app/google-services.json` from Firebase/Google Cloud Console for Android.

---

## Testing

### Recommended Test Coverage

1. **Unit Tests**
   - Encryption/decryption correctness with various keys
   - Key derivation with different PINs and salts
   - Hash verification accuracy
   - File type detection logic
   - Error handling in services

2. **Integration Tests**
   - Full authentication flow (Google → PIN → Vault)
   - File add/encrypt/delete workflow
   - Backup/restore cycle with encryption
   - Theme switching persistence

3. **Widget Tests**
   - Navigation flows between screens
   - Error message displays
   - Theme switching UI updates
   - File card interactions

### Test Utilities

- Use `flutter_test` for unit and widget tests
- Use `mocktail` for mocking services
- Use `integration_test` for end-to-end tests

---

## Recent Improvements

### Security Enhancements (Latest)

1. **PBKDF2 Key Derivation**
   - Upgraded from simple SHA-256 loop to PBKDF2-HMAC-SHA256
   - Two modes: Simple (10k iterations - fast) and Advanced (600k iterations - secure)
   - Default to Simple mode for fast daily use
   - Advanced mode available as "Coming Soon" feature for maximum security

2. **Encryption Modes**
   - **Simple Mode**: 10,000 iterations - fast app unlock and file operations
   - **Advanced Mode**: 600,000 iterations - OWASP recommended, for maximum security
   - Key caching in memory for performance, cleared on app background
   - Settings UI shows "Advanced Encryption" with Coming Soon badge

2. **Encrypted Cloud Backup**
   - Backup data now encrypted before upload
   - Added backup metadata with integrity checksums
   - Fixed restore dialog to check backup existence BEFORE applying
   - Split restore into check/apply phases for user safety

3. **PIN Complexity Enforcement**
   - Blocks common PINs (0000, 1234, 4321, etc.)
   - Prevents weak security codes during setup

4. **Security Question Rate Limiting**
   - 3 failed attempts → 5-minute lockout
   - Prevents brute-force attacks on recovery
   - Clear feedback on remaining attempts

5. **Warning Before PIN Reset**
   - Shows critical warning dialog BEFORE starting PIN reset
   - Educates users about file loss implications
   - Prevents accidental data loss

6. **Session Management**
   - Added logout functionality in settings
   - Session key cleared on sign out
   - Proper session invalidation callbacks from Google Auth

### User Experience Improvements

1. **File Type Icons**
   - Visual differentiation of file types (images, videos, documents, etc.)
   - Type-specific colors for quick recognition
   - Consistent encrypted file indicators

2. **Better Error Handling**
   - VaultException with user-friendly error messages
   - Proper error propagation from services to UI
   - File size validation (max 50MB for encryption)
   - File existence checks before operations

3. **Scoped Storage Handling**
   - Better Android storage path handling
   - File collision handling in recycle bin
   - Temp file tracking and cleanup on app lifecycle changes

4. **Security Question Expansion**
   - Expanded from 4 to 8 security questions
   - More diverse and harder to guess

5. **Backup Metadata**
   - Tracks backup timestamp, version, and checksum
   - Allows checking backup before restore

---

## Known Limitations

1. **File Size**: Encryption limited to 50MB per file
2. **Backup Only**: No selective file backup, all-or-nothing approach
3. **Single Device**: No multi-device sync (files stored locally)
4. **No Biometrics**: PIN-only authentication, no fingerprint/face unlock
5. **No Versioning**: Only latest backup stored, no history
6. **Manual Backup**: No automatic scheduled backups

---

## Future Improvements

### Planned Features

- [ ] Biometric authentication (fingerprint/face unlock)
- [ ] Auto-backup scheduling (daily/weekly)
- [ ] File integrity verification (hash check after decrypt)
- [ ] Export encrypted backup to local file
- [ ] In-app file preview (images, PDFs without temp files)
- [ ] Bulk operations (multi-select, batch encrypt)
- [ ] Advanced search filters (date, type, encrypted status)
- [ ] Export activity logs to file
- [ ] PIN change without data loss (re-encrypt files)
- [ ] File categories/folders organization

### Technical Improvements

- [ ] Unit test coverage > 80%
- [ ] Widget tests for UI components
- [ ] Integration tests for critical flows
- [ ] CI/CD pipeline setup
- [ ] Error monitoring and crash reporting

---

## License

MIT License - See LICENSE file for details.

---

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

---

## Support

For issues and questions:
- Open an issue on GitHub
- Check the FAQ section in the app settings
- Review the activity logs for operation details

---

## Code Quality Standards

- Run `flutter analyze` before committing
- Follow Dart style guide
- Add documentation for public APIs
- Keep functions focused and single-purpose
- Use meaningful variable and function names

---

*Built with Flutter and ❤️ for privacy*

**Version**: 1.0.0 (Production Ready)
**Last Updated**: May 2026