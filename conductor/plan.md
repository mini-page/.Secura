# Implementation Plan: Offline-First Secura Ecosystem

## Executive Summary
This plan maps the requested "Secure File Storage System" flow to a strictly **offline, local-first architecture**. We will simulate complex backend interactions (OAuth, OTP, Rate Limiting) using sophisticated local state management. Concurrently, we will elevate the Material You Expressive UI, fix the PIN screen overflow, and perfect the floating 'Dynamic Island' navigation. Features from the original spec that require a true backend (e.g., Cloud Sync, real OAuth) will be added to the "Upcoming Features" section in the About screen.

## Phase 1: Navigation & UI Expressiveness
**Objective:** Perfect the Dynamic Island, fix PIN screen overflow, and use highly expressive Material icons.
*   **Brand Color:** Use `#575992` as the primary accent color across the app (Lock icons, Nav accents, etc.).
*   **Transparent Shell:** Ensure the `VaultShell` bottom navigation bar background is completely transparent outside the island.
*   **Expressive Iconography:** Update the bottom navigation icons to use bold, distinctive Material Symbols.
*   **Island Animation:** Add a micro-animation to the island container itself (e.g., width expansion) when navigating between tabs.
*   **PIN Screen Fixes:** Reduce padding, margins, and key sizes on `AuthScreen` to prevent overflow. Randomize keys on every entry.

## Phase 2: Advanced Local Authentication Flow
**Objective:** Implement the multi-stage, rate-limited auth flow locally with branded animations.
*   **Branded Verification:** Update `PhoneAuthScreen` to use the app's standard UI (not a plain black terminal) for the verification sequence.
*   **Optimized Timing:** Reduce the verification sequence to 3-4 seconds total.
*   **UI Perfection:** Refine the "CODE DETECTED" and verification stages to be visually polished and consistent with the app's Material You theme.
*   **Local Rate Limiting:** Implement logic in `AuthScreen` to block the user temporarily if the PIN is entered incorrectly too many times.

## Phase 3: The Recycle Bin Module
**Objective:** Implement soft-deletion to prevent accidental data loss.
*   **Soft Delete Logic:** Modify `FileVaultService.deleteFile()`. Instead of wiping the file, move it to a hidden `.secura_recycle` directory.
*   **Recycle Bin UI:** Create a `RecycleBinScreen` accessible via the Settings menu to view, restore, or permanently delete files.

## Phase 4: Activity Logging (Local Admin Module)
**Objective:** Provide a local audit trail for security and governance.
*   **Log Engine:** Create a local `ActivityLogger` using `StorageService`.
*   **Event Tracking:** Hook into actions: `App Unlocked`, `File Encrypted`, `File Restored`, `File Deleted`.
*   **Logs Dashboard:** Add an "Activity Logs" screen in the Settings menu.

## Phase 5: Encryption Flow Adjustments
**Objective:** Deepen the file management workflows locally.
*   **Simulated Routing:** When restoring, present a UI choice (Local Download, Cloud Sync). Currently, only "Local Download" will be functional; Cloud will show "Coming Soon".

## Phase 6: Settings Expansion & About Screen Updates
**Objective:** Add simulated settings and update the roadmap.
*   **New Toggles:** Add local UI switches in `SettingsScreen` for "Strict 2FA Mode" and "Auto-Lock Timeout".
*   **About Screen Roadmap:** Update the `AboutScreen` roadmap to explicitly list the deferred online features from the flow document:
    - Real OAuth / Google Authentication
    - Server-side Database Synchronization (MySQL)
    - Encrypted Cloud Drive Integration
    - Email-based OTP Recovery

## Hotfix: Dynamic Island Layout Repair
**Objective:** Resolve the issue where the navigation bar covers the entire screen, preventing actual screen content from being visible.
*   **Structural Refactor:** Modify `VaultShell` in `lib/app_shell.dart` to remove the `Scaffold.bottomNavigationBar` implementation.
*   **Stack Overlay:** Wrap the `Scaffold` body in a `Stack`.
*   **Positioned Navigation:** Place the 'Dynamic Island' animated container inside an `Align` or `Positioned` widget at the bottom center of the `Stack`. This ensures the navigation bar truly floats over the content without disrupting the primary layout constraints.

## Phase 7: Dynamic Island Contextual Polish
**Objective:** Refine the navigation bar aesthetics to match the requested design and add context-aware actions.
*   **Selected State Styling:** Update `_buildNavItem` in `lib/app_shell.dart`. Use a solid circular background for selected icons using the new `#575992` accent.
*   **Universal 'Plus' Action:** Introduce a new 'Plus' (upload/add) icon right in the center of the navigation bar (making it 5 items total). This icon will be visible on *all* screens.
*   **Subtle Accent Styling:** To avoid competing with the selected nav icons, the 'Plus' button will *not* have a background color. Instead, the icon itself will use the accent color `#575992`.
*   **Smooth Island Sizing:** The navigation bar will maintain a fixed, smoothly animated width (e.g., 90% of screen width) to perfectly accommodate the 5 icons across all screens.