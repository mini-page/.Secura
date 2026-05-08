import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleAuthService {
  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;

  static Future<void> init() async {
    try {
      debugPrint('DEBUG: GoogleSignIn.instance.initialize() starting...');
      
      // Use the provided serverClientId for modern Google Identity Services on Android.
      await GoogleSignIn.instance.initialize(
        serverClientId: '788854121443-ntgt3ddqs5bvp87421il73sn7slh8pcm.apps.googleusercontent.com',
      );
      debugPrint('DEBUG: GoogleSignIn.instance.initialize() finished');
      
      // Listen for sign-in/out events to track current user
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        debugPrint('DEBUG: Google Auth Event: $event');
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
        }
      });

      // Initial check
      try {
        debugPrint('DEBUG: attemptLightweightAuthentication starting...');
        _currentUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
        debugPrint('DEBUG: attemptLightweightAuthentication finished. User: ${_currentUser?.email}');
      } catch (e) {
        debugPrint('DEBUG: Google Auth lightweight check failed (this is usually okay): $e');
      }
    } catch (e) {
      debugPrint('DEBUG: GoogleAuthService.init error: $e');
      // We don't rethrow here to allow the app to at least show the UI
    }
  }

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // Use scopeHint to inform the platform of intended scopes during authentication
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: [
          'email',
          drive.DriveApi.driveAppdataScope,
        ],
      );
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('DEBUG: GoogleAuthService.signIn error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('DEBUG: GoogleAuthService.signOut error: $e');
    }
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('DEBUG: GoogleAuthService.signInSilently error: $e');
      return null;
    }
  }
}
