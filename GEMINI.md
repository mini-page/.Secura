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

## Error Prevention & Pre-Flight Checks

To maintain high development velocity and avoid common compilation errors, always verify the following before finalizing any code change:

### 1. Constant Expression Validation
- **Pitfall:** Using `const` on widgets that depend on dynamic state, providers, or non-constant lists.
- **Check:** Ensure that `LockerScreen()`, `TeamScreen()`, and any screens using `ConsumerWidget` or `watch/read` are **NOT** instantiated with `const` in `app_shell.dart` or navigation calls.

### 2. Comprehensive Import Audits
- **Pitfall:** Adding new components or screens and forgetting to update the imports in the destination file.
- **Check:** When using `PrimaryCtaButton`, `LockerScreen`, or `SecuraNotifications`, double-check that `../../components/components.dart` or the relevant feature file is imported.

### 3. Widget Parameter Verification
- **Pitfall:** Using invalid parameters on common widgets (e.g., adding `padding` to a `SizedBox` instead of wrapping it in a `Padding` widget).
- **Check:** Verify widget properties against the Flutter API. Use `Container` or `Padding` for spacing/inset needs, and `SizedBox` only for fixed dimensions.

### 4. Code Integrity & Hygiene
- **Pitfall:** Accidental code duplication or leaving "stray" UI elements at the end of a file during complex refactors.
- **Check:** Always perform a final "surgical read" of the entire file after a `replace` call to ensure no duplicate blocks or broken syntax remain.

### 5. Plugin & Native Synchronization
- **Pitfall:** Encountering `MissingPluginException` after refactoring services or adding dependencies.
- **Check:** If a native-backed plugin (like `path_provider` or `local_auth`) fails, recommend a full **Cold Boot** (`flutter clean && flutter run`) instead of relying on Hot Reload.

---

## Roadmap & Next Steps
1. **Authentication:** Integrate Supabase Auth for user management.
2. **Persistence:** Implement Isar or Hive for local file metadata storage.
3. **Encryption:** Implement the AES-256-GCM encryption service.
4. **File Handling:** Integrate `file_picker` and implement local directory management for the vault.
