import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:async';
import '../../core/services/storage_service.dart';
import '../../core/services/activity_logger.dart';
import '../../core/services/encryption_service.dart';
import '../../app_shell.dart';
import 'user_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    required this.isSetup,
    super.key,
  });

  final bool isSetup;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  final _logger = ActivityLogger();
  String _pin = '';
  String? _firstPin;
  String _message = '';
  String _subMessage = '';
  bool _isVerifying = false;
  late List<String> _keys;

  // Rate limiting state
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _message = widget.isSetup ? 'Set your PIN' : 'Enter your PIN';
    _subMessage = widget.isSetup ? 'Create a 4-digit code to secure your vault' : 'Please enter your current vault PIN';
    _randomizeKeys();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _randomizeKeys() {
    _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _keys.shuffle(Random());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool get _isLockedOut => _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _updateLockout();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateLockout();
      if (!_isLockedOut) {
        timer.cancel();
      }
    });
  }

  void _updateLockout() {
    if (_lockoutEndTime == null) return;
    final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    setState(() {
      _secondsRemaining = max(0, remaining);
      if (_secondsRemaining <= 0) {
        _failedAttempts = 0;
        _lockoutEndTime = null;
        _message = 'Enter your PIN';
        _subMessage = 'Please enter your current vault PIN';
      }
    });
  }

  void _onKeyTap(String key) {
    if (_pin.length >= 4 || _isVerifying || _isLockedOut) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pin += key;
    });
    if (_pin.length == 4) {
      _processSubmission();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isVerifying || _isLockedOut) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _processSubmission() async {
    if (!mounted) return;
    setState(() => _isVerifying = true);

    if (widget.isSetup) {
      if (_firstPin == null) {
        _firstPin = _pin;
        if (!mounted) return;
        setState(() {
          _pin = '';
          _isVerifying = false;
          _message = 'Confirm PIN';
          _subMessage = 'Repeat your code to ensure it is correct';
        });
      } else {
        if (_pin == _firstPin) {
          final salt = EncryptionService.generateSalt();
          final key = EncryptionService.deriveKey(_pin, salt);
          final hash = EncryptionService.hashKey(key);

          await _storage.saveSalt(salt);
          await _storage.saveAuthHash(hash);
          ref.read(sessionProvider.notifier).state = key;

          await _logger.logEvent('PIN Established (Zero-Knowledge)');
          if (!mounted) return;
          _completeAuth();
        } else {
          HapticFeedback.heavyImpact();
          if (!mounted) return;
          setState(() {
            _pin = '';
            _firstPin = null;
            _isVerifying = false;
            _message = 'Mismatch';
            _subMessage = 'PINs do not match. Let\'s try again.';
          });
        }
      }
    } else {
      final savedSalt = await _storage.getSalt();
      final savedHash = await _storage.getAuthHash();

      if (savedSalt != null && savedHash != null) {
        final testKey = EncryptionService.deriveKey(_pin, savedSalt);
        final testHash = EncryptionService.hashKey(testKey);

        if (testHash == savedHash) {
          ref.read(sessionProvider.notifier).state = testKey;
          await _logger.logEvent('App Unlocked');
          if (!mounted) return;
          _completeAuth();
          return;
        }
      }

      // Fallback or failed login
      HapticFeedback.vibrate();
      _failedAttempts++;

      if (_failedAttempts >= 3) {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _isVerifying = false;
          _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
          _message = 'Security Lockout';
          _subMessage = 'Too many failed attempts.';
        });
        await _logger.logEvent('Failed Login: Locked Out');
        _startLockoutTimer();
      } else {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _isVerifying = false;
          _message = 'Incorrect';
          _subMessage = 'Attempt $_failedAttempts of 3. Try again.';
          _randomizeKeys();
        });
        await _logger.logEvent('Failed Login Attempt');
      }
    }
  }

  void _completeAuth() {
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const VaultShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLockedOut)
                      const Icon(Icons.timer_outlined, size: 72, color: Colors.red)
                    else
                      Image.asset('assets/app_brand.png', width: 72, height: 72),
                    const SizedBox(height: 16),
                    Text(
                      _isLockedOut ? 'Locked for $_secondsRemaining s' : _message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: _isLockedOut ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                    _buildPinDisplay(),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              Opacity(
                opacity: _isLockedOut ? 0.3 : 1.0,
                child: _buildNumpad(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        final isActive = index == _pin.length && !_isVerifying;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 48,
          height: 58,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                : (isFilled ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isFilled 
                  ? Text(
                      _pin[index], 
                      key: ValueKey('filled_$index'),
                      style: TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.w900, 
                        color: Theme.of(context).primaryColor,
                        letterSpacing: -1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var j = 0; j < 3; j++)
                    _buildKey(_keys[i * 3 + j]),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 60),
              _buildKey(_keys[9]),
              _buildKey('backspace', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {bool isIcon = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isIcon ? _onBackspace() : _onKeyTap(label),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardTheme.color,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
          ),
          alignment: Alignment.center,
          child: isIcon 
              ? const Icon(Icons.backspace_rounded, size: 18, color: Colors.grey) 
              : Text(
                  label, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}
