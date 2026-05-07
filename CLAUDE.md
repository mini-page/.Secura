# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Secura is a mobile-first secure file vault app built with Flutter (Material 3). It utilizes AES-256-GCM encryption for securing files and includes features such as authentication, a secure file locker, and local PIN protection. 

## Commands

- **Install Dependencies:** `flutter pub get`
- **Run App:** `flutter run`
- **Run Tests:** `flutter test` (run a single test with `flutter test path/to/test.dart`)
- **Lint Code:** `flutter analyze`
- **Build Android:** `flutter build apk` or `flutter build appbundle`
- **Build Web:** `flutter build web`

## Architecture & Structure

The codebase follows a **feature-first** modular architecture using **Riverpod** for reactive state management. 

- **`lib/main.dart` & `lib/app_shell.dart`**: App entry point and root shell configuration.
- **`lib/features/`**: Contains isolated feature modules. Each subdirectory (`auth/`, `onboarding/`, `settings/`, `splash/`, `vault/`) holds its own UI screens, Riverpod providers (`_provider.dart`), and domain models (`_model.dart`).
- **`lib/components/`**: Houses all reusable UI components (e.g., buttons, cards, headers, theme selectors). These are exported through a single barrel file at `lib/components/components.dart` so they can be easily imported across features.
- **`lib/core/`**: Contains app-wide logic and configuration.
  - **`lib/core/services/`**: Core business logic and integrations (e.g., `encryption_service.dart`, `file_vault_service.dart`, `storage_service.dart`).
  - **`lib/core/theme/`**: Centralized theming via `app_theme.dart`.

## Conventions & State Management

- **State Management:** Use Riverpod (`ConsumerWidget` or `ConsumerStatefulWidget`) to read and listen to state. Keep providers co-located with their features.
- **UI & Theming:** Use `Theme.of(context)` to access colors and text styles dynamically. Do not hardcode styling values; instead, reference the `AppTheme` constants defined in `lib/core/theme/app_theme.dart`.
- **Hardware/Storage Security:** Keys and PINs are backed by **Flutter Secure Storage**. The app implements a "Secure Gate" mechanism to protect the UI in the OS task switcher and prevent screenshots. 
- **Encryption Logic:** Files are encrypted via AES-256-GCM, utilizing unique 16-byte IVs for each file. Ensure strict adherence to this pattern when modifying the `encryption_service.dart`.