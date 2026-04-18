# Secura (Flutter MVP Scaffold)

Secura is a mobile-first secure file vault app scaffold built for cross-platform expansion.

## Current Status

This repo now includes a from-scratch Flutter structure with reusable UI components and core screens:

- Onboarding (3 pages)
- Login / Sign Up
- Home (vault overview)
- Encrypt tab (decrypted files list)
- Decrypt tab (encrypted files list)
- Settings (app lock + theme mode)

## Why the `components/` folder

Shared UI elements now live in `lib/components/` and are exported through one barrel file:

- `components.dart`
- `app_header.dart`
- `primary_cta_button.dart`
- `file_item_card.dart`
- `onboarding_page_indicator.dart`
- `app_toggle_tile.dart`
- `theme_mode_selector.dart`

This means if you update one component, all screens using that component update automatically.

## Structure

```text
lib/
  components/
    components.dart
    app_header.dart
    app_toggle_tile.dart
    file_item_card.dart
    onboarding_page_indicator.dart
    primary_cta_button.dart
    theme_mode_selector.dart
  core/
    theme/
      app_theme.dart
  features/
    onboarding/
      onboarding_screen.dart
    auth/
      auth_screen.dart
    vault/
      home_screen.dart
      encrypt_screen.dart
      decrypt_screen.dart
    settings/
      settings_screen.dart
  main.dart
```

## Next Steps

1. Add Supabase auth wiring (signup/login/reset only).
2. Add local DB (Isar) for file metadata.
3. Implement AES-256-GCM encryption service.
4. Add file-picker + locker directory creation.
5. Connect component actions (`Encrypt`, `Decrypt`, `Delete`, `View`) to real services.
