# Safe Folder Mode - Implementation Plan

## Objective
Simplify Secura to work like Google Files' Safe Folder:
- Fast, simple encryption as default
- Optional "Advanced Encryption" toggle for power users
- Remove slow PBKDF2 iterations from common operations

---

## Current State Analysis

### Encryption Flow (Current - SLOW)
```
User PIN → PBKDF2 (600k iterations) → AES-256-GCM → File
         ↑ This takes 1-3 seconds every time!
```

### Performance Impact
- **App Launch**: 1-3s delay for PIN verification
- **File Open**: Decryption adds 0.5-2s per file
- **File Add**: Encryption adds 1-3s per file
- **User Experience**: Feels sluggish

---

## Proposed Design

### Settings UI
```
SECURITY
┌─────────────────────────────────────────────┐
│ [Toggle] Advanced Encryption      [Coming]  │
│                                             │
│ When enabled: PBKDF2 (600k), AES-256-GCM   │
│ Maximum security with cloud backup         │
│                                             │
│ When disabled: Fast AES-256, instant unlock │
│ Like Google Files Safe Folder               │
└─────────────────────────────────────────────┘
```

### Encryption Modes

| Feature | Simple Mode (Default) | Advanced Mode |
|---------|----------------------|---------------|
| Key Derivation | PBKDF2-10k (fast) | PBKDF2-600k (secure) |
| Encryption | AES-256-CBC | AES-256-GCM |
| Cloud Backup | ✅ Yes | ✅ Yes |
| Secure Shred | ✅ Yes | ✅ Yes |
| Rate Limiting | 3 attempts, 30s | 3 attempts, 30s |
| Files on Delete | Recoverable via backup | Recoverable via backup |

### Key Derivation Config
```dart
class KeyDerivationConfig {
  // Simple mode - fast, suitable for daily use
  static const int simpleIterations = 10000;

  // Advanced mode - OWASP recommended
  static const int advancedIterations = 600000;
}
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Priority: HIGH)
1. Add `encryptionModeProvider` in settings_provider.dart
   - Enum: `simple`, `advanced`
   - Default: `simple`
   - Persist to secure storage

2. Modify EncryptionService to accept iteration count
   ```dart
   static String deriveKey(String pin, String salt, {int iterations = 10000})
   ```

3. Add migration path for existing users
   - Detect if user has old 600k derived key
   - Offer re-derive with new iteration count

### Phase 2: UI Implementation (Priority: HIGH)
1. Add toggle in Settings Screen
   ```dart
   AppToggleTile(
     title: 'Advanced Encryption',
     subtitle: '600k PBKDF2 iterations, AES-256-GCM',
     trailing: Container(
       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: Colors.orange.withAlpha(50),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.orange),
       ),
       child: Text('Coming Soon', style: TextStyle(color: Colors.orange, fontSize: 10)),
     ),
     value: isAdvancedMode,
     onChanged: (v) => showComingSoonDialog(),
   )
   ```

2. Show info dialog when toggling between modes
   - Warn about re-encryption requirement
   - Explain speed difference

### Phase 3: File Migration (Priority: MEDIUM)
1. Add migration service
   - Detect files encrypted with old method
   - Re-encrypt with selected mode in background
   - Show progress indicator

2. File format change
   - Simple mode: `.secura_simple` extension
   - Advanced mode: `.secura` extension (current)

### Phase 4: Performance Optimization (Priority: MEDIUM)
1. Cache derived key in memory (cleared on app background)
2. Lazy decryption - only decrypt when viewing
3. Background thread for encryption operations

---

## Code Changes Required

### Files to Modify
1. `lib/core/services/encryption_service.dart` - Add iteration parameter
2. `lib/features/settings/settings_provider.dart` - Add mode provider
3. `lib/features/settings/settings_screen.dart` - Add toggle UI
4. `lib/features/vault/vault_provider.dart` - Use mode-aware encryption
5. `lib/core/services/file_vault_service.dart` - Accept encryption mode
6. `lib/core/services/backup_service.dart` - Track encryption mode in backup

### New Files
1. `lib/core/services/migration_service.dart` - Handle file re-encryption

---

## User Experience

### First-Time Users (Default: Simple Mode)
- Fast app startup (<500ms PIN verify)
- Instant file operations
- Same security as Google Safe Folder
- Cloud backup available

### Existing Users (Migration)
- Prompt: "Switch to Fast Mode?"
- Show speed improvement estimate
- Background migration of existing files
- Keep advanced mode as "Coming Soon" badge

### Power Users (Advanced Mode)
- Toggle available but marked "Coming Soon"
- 600k iterations for maximum security
- Slower but OWASP compliant

---

## Risk Mitigation

1. **Backward Compatibility**
   - Detect existing `.secura` files
   - Support both encryption modes
   - Never lose user data

2. **Migration Safety**
   - Keep old files until new encryption confirmed
   - Atomic operation with rollback
   - User can cancel mid-migration

3. **Default Selection**
   - Start with Simple Mode (fast)
   - User can enable Advanced when ready
   - "Coming Soon" tag creates anticipation

---

## Success Metrics

- **App Launch**: <500ms (from 1-3s)
- **File Encryption**: <1s (from 2-4s)
- **User Satisfaction**: Similar to Google Files
- **Security**: Still AES-256, just faster iterations

---

## Timeline Estimate

| Phase | Effort | Notes |
|-------|--------|-------|
| Phase 1: Core | 2-3 hours | Encryption service changes |
| Phase 2: UI | 1-2 hours | Settings toggle |
| Phase 3: Migration | 2-3 hours | File re-encryption |
| Phase 4: Optimization | 2 hours | Caching, threading |

**Total**: ~7-10 hours development

---

## Open Questions

1. Should Advanced Mode be free or premium?
2. How to handle the "Coming Soon" messaging?
3. Should we show speed comparison in settings?
4. Keep 50MB limit in simple mode?
5. Cloud backup works same in both modes?