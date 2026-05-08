# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **IMPORTANT**: For detailed project history, security updates, and AI collaborator guidance, see:
> - `.claude/memory.md` - Comprehensive project memory (in-repo, committed)
> - `.claude/AGENT.md` - Quick reference for AI agents
> - `readme.md` - Complete documentation

## Overview

Secura is a production-ready mobile-first secure file vault app built with Flutter (Material 3). It utilizes AES-256-GCM encryption with PBKDF2-HMAC-SHA256 key derivation (600k iterations) and includes Google Drive encrypted backup.

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
  - **`lib/core/services/`**: Core business logic and integrations.
  - **`lib/core/theme/`**: Centralized theming via `app_theme.dart`.

## Security Requirements (Updated May 2026)

**CRITICAL**: Before modifying encryption or security code, read the memory file.

### Key Requirements:
1. **Key Derivation**: Use PBKDF2-HMAC-SHA256 with 600,000 iterations (see `encryption_service.dart`)
2. **Backup**: Must encrypt data before upload (`backup_service.dart`)
3. **PIN Complexity**: Blocks weak PINs like 0000, 1234
4. **Rate Limiting**: PIN has 30s lockout after 3 failures; security questions have 5-min lockout
5. **Error Handling**: Use `VaultException` for file ops, `BackupResult` for backups

## Conventions & State Management

- **State Management:** Use Riverpod (`ConsumerWidget` or `ConsumerStatefulWidget`) to read and listen to state. Keep providers co-located with their features.
- **UI & Theming:** Use `Theme.of(context)` to access colors and text styles dynamically. Do not hardcode styling values; instead, reference the `AppTheme` constants defined in `lib/core/theme/app_theme.dart`.
- **Hardware/Storage Security:** Keys and PINs are backed by **Flutter Secure Storage**. The app implements a "Secure Gate" mechanism to protect the UI in the OS task switcher and prevent screenshots.
- **Encryption Logic:** Files are encrypted via AES-256-GCM, utilizing unique 12-byte IVs for each file. Key derivation uses PBKDF2 with 600k iterations.

## Error Handling Patterns

Use these patterns for consistent error handling:
- **File Operations**: Use `VaultException` with `userMessage` parameter
- **Backup Operations**: Use `BackupResult` class for success/error status
- **UI Feedback**: Use `lastErrorProvider` and `vaultOperationStatusProvider`

## Memory System

After making changes:
1. Update `memory/memory.md` with changes and rationale
2. Update `memory/AGENT.md` for quick reference if significant
3. Update `readme.md` if adding features or changing APIs