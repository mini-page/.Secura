# Combined Critical Security & Setup Plan

## Priority 1: Blocker-Level File Restoration Fix
The current restoration mechanism risks silent data loss by auto-deleting vault files after pushing them to external storage.

### 1. Transactional Restore & User Destination Choice
- **Target:** `lib/core/file_action_handler.dart` & `lib/core/services/file_vault_service.dart`
- **Action:** 
  - Change the `restore` action to use `FilePicker.platform.getDirectoryPath()` (or `saveFile`) so the user explicitly chooses the restore destination, preventing OS-level scoped storage routing issues.
  - **CRITICAL:** Remove the automatic `deleteFile(file)` call inside `restoreFile`. A restore operation should act as an **Export**. The file must remain safely in the secure vault until the user manually deletes it. This guarantees ZERO permanent data loss during restore failures.
  - Implement integrity verification: ensure the file exists at the target destination before confirming success.
  - Add "Decrypt & Export" as the primary terminology.

### 2. Encryption Workflow Safeguards
- **Action:** Ensure the UI clearly communicates whether a file is being moved, copied, encrypted, or decrypted, to avoid user confusion about file states.

---

## Priority 2: Mandatory First-Time Setup Flow
Enforce a strict, un-bypassable onboarding sequence to guarantee app security.

### 1. Fast Splash & Routing Middleware
- **Target:** `lib/features/splash/splash_screen.dart`
- **Action:** Reduce splash delay to 400ms. Implement strict sequential checks:
  1. `Onboarding` -> `Google Login` -> `Permissions` -> `PIN Setup` -> `Recovery Setup` -> `App Shell`.
  
### 2. Strict Recovery Question Protocol
- **Target:** `lib/features/auth/auth_screen.dart`
- **Action:**
  - Hide the "Forgot PIN" button entirely during the initial setup phase.
  - **Info Popup:** Automatically display a "Recovery Setup Rules" popup when the user reaches the recovery setup phase. This will include compact rules and an expanded "More" section.
  - **Regex Validation:** Implement real-time validation using `/^[A-Za-z0-9_-]{4,}$/`. Prevent the user from finishing setup until the answer strictly meets these criteria (no spaces, min 4 chars).

## Verification
- **Restore:** Attempt to restore a file. Verify the user is prompted for a location, the file is successfully decrypted to that location, and the original vault file is **NOT** deleted.
- **Setup Flow:** Wipe app data. Verify the strict sequence. Test invalid recovery answers against the regex rules to ensure the "Finish Setup" button remains disabled.