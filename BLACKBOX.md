# BLACKBOX.md

This file provides instructional context for Blackbox Code AI when interacting with the Secura project.

## Project Overview

**Secura** is a mobile-first secure file vault application built with Flutter (Dart). It provides a secure environment for managing sensitive files with AES-256-GCM encryption, featuring onboarding, authentication, a file vault (locker), and encryption/decryption capabilities.

### Technology Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter (>=3.3.0) |
| Language | Dart |
| State Management | Riverpod |
| UI Framework | Material Design 3 |
| Encryption | AES-256-GCM |
| Typography | Bricolage Grotesque (Google Fonts) |
| Local Storage | Flutter Secure Storage |
| Architecture | Feature-first modular |

---

## Commands

### Development

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a single test
flutter test path/to/test.dart

# Lint and analyze code
flutter analyze

# Build for web
flutter build web

# Build Android APK
flutter build apk

# Build Android App Bundle
flutter build appbundle
```

---

## Architecture

The codebase follows a **feature-first** modular architecture using **Riverpod** for reactive state management.

### Directory Structure

```
lib/
├── main.dart                    # App entry point
├── app_shell.dart              # Root shell configuration
├── components/                # Reusable UI components
│   └── components.dart         # Barrel file for exports
├── core/                     # App-wide logic and configuration
│   ├── theme/                # Theming (app_theme.dart, theme_provider.dart)
│   ├── services/             # Business logic services
│   │   ├── encryption_service.dart
│   │   ├── file_vault_service.dart
│   │   ├── storage_service.dart
│   │   └── activity_logger.dart
│   └── file_action_handler.dart
└── features/                 # Feature-specific modules
    ├── auth/                 # Authentication
    ├── onboarding/            # Onboarding experience
    ├── settings/              # App settings
    ├── splash/               # Splash screen
    └── vault/                # Core vault functionality
```

### Key Architectural Patterns

1. **Feature-First Organization**: Each feature directory in `lib/features/` contains its own screens, providers (Riverpod), and models.
2. **Component Export via Barrel File**: All reusable UI components are exported through `lib/components/components.dart`.
3. **Riverpod Providers**: Use `ConsumerWidget` or `ConsumerStatefulWidget` for stateful widgets that need to listen to providers.
4. **Secure Gate**: The app uses `secure_application` to protect the UI in task switcher and prevent screenshots.

---

## Security Implementation

### Encryption Service (`lib/core/services/encryption_service.dart`)

- **Algorithm**: AES-256-GCM
- **IV**: Unique 16-byte random IV per file (prepended to ciphertext)
- **Key Derivation**: SHA-256 of (PIN + Salt) with 10,000 iterations
- **File Storage**: Hidden `.locker_private` directory in application support directory

### File Vault Service (`lib/core/services/file_vault_service.dart`)

- **Locker Directory**: `.locker_private` (hidden from system file manager/search)
- **Recycle Bin**: `.secura_recycle` (soft-delete feature)
- **Secure Shred**: Overwrites file with zeros before deletion
- **Base64 Filenames**: Original filenames encoded to hide from OS search

### App Security

- **Secure Gate**: Blurs app content in task switcher (20px blur, 0.6 opacity)
- **Secure Storage**: Keys and PINs stored in Flutter Secure Storage
- **PIN Authentication**: Local PIN protection with session-based key management

---

## Theming

### Custom Theme (`lib/core/theme/app_theme.dart`)

- **Primary Color**: `#575992` (Purple-blue)
- **Light Background**: `#F4F6FA`
- **Dark Background**: `#0E1117`
- **Typography**: Bricolage Grotesque via Google Fonts
- **Card Style**: Rounded corners (32px), no elevation

### Theme Modes

The app supports light/dark mode switching via `theme_provider.dart`.

---

## Development Conventions

### UI & Styling

- Use `Theme.of(context)` to access colors and text styles dynamically
- **Never hardcode** styling values; use `AppTheme` constants defined in `lib/core/theme/app_theme.dart`
- Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style)

### State Management

- Use **Riverpod** for all state management
- Keep providers co-located with their features
- Read providers via `ref.watch()` or `ref.read()`

### Testing

- Add widget tests in `test/` directory for new UI components
- Unit test business logic (providers/services) for security protocols
- Run tests before committing: `flutter test`

### Linting

- Run analysis before committing: `flutter analyze`
- Address all warnings and errors

---

## Key Features

### Current Features

1. **Onboarding**: 3-page onboarding flow
2. **Authentication**: Login / Sign Up screens
3. **File Vault**: Home screen with vault overview
4. **Encrypt Tab**: List of encrypted/decrypted files
5. **Decrypt Tab**: View and manage encrypted files
6. **Settings**: App lock, theme mode switching
7. **Activity Logs**: Track file operations

### Planned Features

1. Supabase auth integration (signup/login/reset)
2. Local DB (Isar/Hive) for file metadata
3. File picker integration
4. Connect component actions (Encrypt, Decrypt, Delete, View) to services

---

## Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.5.1 | State management |
| encrypt | ^5.0.3 | AES encryption |
| flutter_secure_storage | ^10.0.0 | Secure key storage |
| secure_application | ^4.1.0 | Screen security |
| file_picker | ^8.0.0 | File selection |
| path_provider | ^2.1.3 | File system paths |
| google_fonts | ^8.1.0 | Typography |
| permission_handler | ^12.0.0 | Runtime permissions |

---

## Assets

The application uses the following assets:

- `assets/app_brand.png` - App branding icon
- `assets/UmangGupta.png` - Team member
- `assets/VineetVRao.png` - Team member
- `assets/VipulKumar.png` - Team member
- `assets/TribhuvanPSingh.png` - Team member
- `assets/VaishnavendraDDiwvedi.png` - Team member

---

## Important Files

| File | Description |
|------|-------------|
| `lib/main.dart` | App entry point with SecureApplication wrapper |
| `lib/core/services/encryption_service.dart` | Core AES-256-GCM encryption logic |
| `lib/core/services/file_vault_service.dart` | File management and vault operations |
| `lib/core/theme/app_theme.dart` | Material 3 theme configuration |
| `lib/features/vault/vault_provider.dart` | Vault state management |
| `lib/features/auth/user_provider.dart` | User/session management |
| `pubspec.yaml` | Project dependencies and configuration |