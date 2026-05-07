# Secura Project Instructions

Welcome to the Secura codebase. Secura is a mobile-first secure file vault app scaffold built with Flutter, designed for cross-platform expansion.

## Project Overview

Secura aims to provide a secure environment for managing sensitive files. It features onboarding, authentication, a file vault (locker), and encryption/decryption capabilities.

- **Tech Stack:** Flutter (Material 3)
- **Architecture:** Feature-first modular structure
- **State Management:** **Riverpod** is used for reactive state management of the vault and authentication.
- **Local Storage:** **Flutter Secure Storage** (hardware-backed) is used for keys/PINs, and the local file system is used for the "locker" directory.
- **Security:**
  - **AES-256-GCM** encryption with unique 16-byte IVs per file.
  - **Secure Gate** (Secure Application) to protect UI in task switcher and prevent screenshots.
  - **Local PIN** authentication.

## Project Structure

```text
lib/
  components/       # Reusable UI components (barrel-exported via components.dart)
  core/
    theme/          # App-wide theme definitions
  features/         # Feature-specific logic and UI
    auth/           # Authentication screens and logic
    onboarding/     # Initial user experience
    settings/       # App configuration and theme switching
    vault/          # Core vault functionality (home, encrypt, decrypt)
  main.dart         # Entry point and app shell
```

## Building and Running

### Prerequisites
- Flutter SDK (>=3.3.0)
- Android Studio / VS Code with Flutter extensions

### Commands
- **Install Dependencies:** `flutter pub get`
- **Run App:** `flutter run`
- **Run Tests:** `flutter test`
- **Build Web:** `flutter build web`
- **Build Android:** `flutter build apk` or `flutter build appbundle`

## Development Conventions

### Architecture & Style
- **Feature-First:** Group code by feature, not by layer. Each directory in `lib/features/` should contain its own screens, controllers/providers, and models.
- **Shared Components:** Place reusable UI elements in `lib/components/`. Always export new components through `lib/components/components.dart`.
- **Theming:** Use `Theme.of(context)` to access colors and text styles. Avoid hardcoding values; use `AppTheme` constants in `lib/core/theme/app_theme.dart`.
- **Standard Guidelines:** Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter best practices](https://docs.flutter.dev/perf/best-practices).

### State Management (Riverpod)
- When implementing new features or refactoring existing ones, use **Riverpod**.
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for widgets that need to listen to state.
- Keep providers in a `providers/` subdirectory within each feature folder.

### Testing
- Add widget tests for new UI components in the `test/` directory.
- Unit test business logic (providers/services) to ensure security protocols are correctly implemented.

## Roadmap & Next Steps
1. **Authentication:** Integrate Supabase Auth for user management.
2. **Persistence:** Implement Isar or Hive for local file metadata storage.
3. **Encryption:** Implement the AES-256-GCM encryption service.
4. **File Handling:** Integrate `file_picker` and implement local directory management for the vault.
