# Profile Card Redesign Plan

## Objective
Update the `ProfileEditScreen` to use a modern, card-based layout for the user's avatar and identity information, ensuring visual consistency with the `GoogleSyncScreen`.

## Key Files & Context
- `lib/features/auth/profile_edit_screen.dart`

## Implementation Steps
1.  **Refactor Avatar Layout:** In `lib/features/auth/profile_edit_screen.dart`, remove the large, centered `CircleAvatar` from the top of the `ListView`.
2.  **Implement Identity Card:** Replace it with a `Card` widget containing a `Padding` and `Row`.
3.  **Align with Google Sync:** Inside the `Row`, place a smaller `CircleAvatar` (radius 28) on the left, and an `Expanded` `Column` on the right displaying the user's current `name` and `email`. This perfectly mirrors the structure found in `lib/features/settings/google_sync_screen.dart`.

## Verification & Testing
- Open the Settings screen and tap the edit icon on the profile card.
- Verify that the new `ProfileEditScreen` displays the user's avatar, name, and email inside a top-aligned card.
- Confirm the styling matches the account card on the Google Sync screen.