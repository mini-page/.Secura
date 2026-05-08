import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Callback type for session invalidation
typedef SessionInvalidationCallback = void Function();

class GoogleAuthService {
  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;

  // Session invalidation callbacks
  static final List<SessionInvalidationCallback> _sessionInvalidationCallbacks = [];

  /// Register a callback to be called when user signs out
  static void registerSessionInvalidationCallback(SessionInvalidationCallback callback) {
    _sessionInvalidationCallbacks.add(callback);
  }

  /// Remove a session invalidation callback
  static void removeSessionInvalidationCallback(SessionInvalidationCallback callback) {
    _sessionInvalidationCallbacks.remove(callback);
  }

  /// Notify all registered callbacks of session invalidation
  static void _notifySessionInvalidation() {
    for (final callback in _sessionInvalidationCallbacks) {
      callback();
    }
  }

  static Future<void> init() async {
    try {
      // Use the provided serverClientId for modern Google Identity Services on Android.
      await GoogleSignIn.instance.initialize(
        serverClientId: '788854121443-ntgt3ddqs5bvp87421il73sn7slh8pcm.apps.googleusercontent.com',
      );

      // Listen for sign-in/out events to track current user
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _notifySessionInvalidation();
        }
      });

      // Attempt silent sign-in to refresh tokens
      _currentUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('GoogleAuthService init error: $e');
    }
  }

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: [
          'email',
          drive.DriveApi.driveAppdataScope,
        ],
      );
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('GoogleAuthService signIn error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
      // Notify all session invalidation callbacks
      _notifySessionInvalidation();
    } catch (e) {
      debugPrint('GoogleAuthService signOut error: $e');
    }
  }

  /// Check if user is currently signed in
  static bool get isSignedIn => _currentUser != null;

  /// Get current user's email
  static String? get currentUserEmail => _currentUser?.email;

  /// Get current user's display name
  static String? get currentUserDisplayName => _currentUser?.displayName;

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('GoogleAuthService signInSilently error: $e');
      return null;
    }
  }
}
