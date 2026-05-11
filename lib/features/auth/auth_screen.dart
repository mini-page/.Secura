import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:async';
import '../../core/services/storage_service.dart';
import '../../core/services/activity_logger.dart';
import '../../core/services/encryption_service.dart';
import '../../components/secura_notifications.dart';
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
  String _message = 'Enter your PIN';
  String _subMessage = 'Please enter your current vault PIN';
  bool _isVerifying = false;
  late List<String> _keys;

  // Rate limiting state
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  int _secondsRemaining = 0;

  // Security question rate limiting
  int _securityAnswerAttempts = 0;
  DateTime? _securityLockoutEndTime;
  Timer? _securityLockoutTimer;
  int _securitySecondsRemaining = 0;

  bool _isSettingUpSecurityQuestion = false;
  bool _isVerifyingSecurityQuestion = false;
  bool _isVerifyingOldPin = false;
  bool _oldPinVerified = false;
  String? _selectedQuestion;
  String? _answerError;
  final _answerController = TextEditingController();

  final _recoveryRegex = RegExp(r'^[A-Za-z0-9_-]{4,}$');

  // Expanded security questions for better security
  final List<String> _securityQuestions = [
    'What is your favorite character?',
    'What is your favorite food?',
    'What was the name of your first pet?',
    'In what city were you born?',
    'What was the name of your first school?',
    'What is your mother\'s maiden name?',
    'What was your first job?',
    'What is the name of your closest friend?',
  ];

  @override
  void initState() {
    super.initState();
    _selectedQuestion = _securityQuestions.first;
    _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _keys.shuffle(Random());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _answerController.addListener(_validateAnswer);

    // Check PIN in background
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExistingPin());
  }

  void _validateAnswer() {
    // Always trigger rebuild to update button enabled state (Verify Answer / Finish Setup)
    setState(() {});
    
    if (!_isSettingUpSecurityQuestion) return;
    
    final text = _answerController.text;
    if (text.isEmpty) {
      setState(() => _answerError = null);
      return;
    }

    if (text.contains(' ')) {
      setState(() => _answerError = 'Spaces are not allowed. Use JohnSnow instead.');
    } else if (text.length < 4) {
      setState(() => _answerError = 'Minimum 4 characters required.');
    } else if (!_recoveryRegex.hasMatch(text)) {
      setState(() => _answerError = 'Only letters, numbers, _ and - allowed.');
    } else {
      setState(() => _answerError = null);
    }
  }

  bool _isPinWeak(String pin) {
    final simplePins = ['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '1234', '4321', '0123', '3210', '1212', '2121', '0001', '1235'];
    if (simplePins.contains(pin)) return true;
    
    // Check for sequential patterns (e.g., 2345)
    final digits = pin.split('').map(int.parse).toList();
    bool sequentialInc = true;
    bool sequentialDec = true;
    for (int i = 0; i < digits.length - 1; i++) {
      if (digits[i + 1] != digits[i] + 1) sequentialInc = false;
      if (digits[i + 1] != digits[i] - 1) sequentialDec = false;
    }
    if (sequentialInc || sequentialDec) return true;
    
    return false;
  }

  Future<void> _checkExistingPin() async {
    final hash = await _storage.getAuthHash();
    if (widget.isSetup && hash != null) {
      setState(() {
        _isVerifyingOldPin = true;
        _message = 'Verify Current PIN';
        _subMessage = 'Enter your old PIN to authorize change';
      });
    } else {
      setState(() {
        _message = widget.isSetup ? 'Set your PIN' : 'Enter your PIN';
        _subMessage = widget.isSetup ? 'Create a 4-digit code to secure your vault' : 'Please enter your current vault PIN';
      });
    }
  }

  void _randomizeKeys() {
    _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _keys.shuffle(Random());
  }

  @override
  void dispose() {
    _answerController.removeListener(_validateAnswer);
    _answerController.dispose();
    _lockoutTimer?.cancel();
    _securityLockoutTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool get _isLockedOut => _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);

  bool get _isSecurityLockedOut => _securityLockoutEndTime != null && DateTime.now().isBefore(_securityLockoutEndTime!);

  void _startSecurityLockoutTimer() {
    _securityLockoutTimer?.cancel();
    _updateSecurityLockout();
    _securityLockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateSecurityLockout();
      if (!_isSecurityLockedOut) {
        timer.cancel();
      }
    });
  }

  void _updateSecurityLockout() {
    if (_securityLockoutEndTime == null) return;
    final remaining = _securityLockoutEndTime!.difference(DateTime.now()).inSeconds;
    setState(() {
      _securitySecondsRemaining = max(0, remaining);
      if (_securitySecondsRemaining <= 0) {
        _securityAnswerAttempts = 0;
        _securityLockoutEndTime = null;
      }
    });
  }

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

  bool _canSubmitAnswer() {
    final text = _answerController.text.trim();
    if (text.isEmpty) return false;
    
    // In setup mode, we also require no error (regex/length)
    if (_isSettingUpSecurityQuestion) {
      return _answerError == null && text.length >= 4;
    }
    
    // In verification mode, any non-empty answer is allowed for check
    return true;
  }

  void _onKeyTap(String key) {
    // BLOCK input if already 4 digits, verifying, locked out, or showing a blocking error
    if (_pin.length >= 4 || _isVerifying || _isLockedOut || _message == 'PIN Too Simple') return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _pin += key;
    });
    if (_pin.length == 4) {
      _processSubmission();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isVerifying || _isLockedOut || _message == 'PIN Too Simple') return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _processSubmission() async {
    if (!mounted) return;
    setState(() => _isVerifying = true);

    if (_isVerifyingOldPin && !_oldPinVerified) {
      final savedSalt = await _storage.getSalt();
      final savedHash = await _storage.getAuthHash();

      if (savedSalt != null && savedHash != null) {
        // Use simple mode (10k iterations) for fast unlock
        final testKey = EncryptionService.deriveKey(_pin, savedSalt, iterations: KeyDerivationConfig.simpleIterations);
        final testHash = EncryptionService.hashKey(testKey);

        if (testHash == savedHash) {
          HapticFeedback.mediumImpact();
          setState(() {
            _pin = '';
            _isVerifying = false;
            _oldPinVerified = true;
            _isVerifyingOldPin = false;
            _message = 'Set New PIN';
            _subMessage = 'Choose a new 4-digit security code';
          });
          return;
        }
      }

      // Failed old PIN verification
      _handleFailure();
      return;
    }

    if (widget.isSetup || _oldPinVerified) {
      if (_firstPin == null) {
        // PIN complexity check - prevent weak PINs on FIRST entry
        if (_isPinWeak(_pin)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _pin = ''; // Clear immediately
            _message = 'PIN Too Simple';
            _subMessage = 'Patterns like 1111 or 1234 are not allowed.';
          });
          
          // Show error for 2 seconds then reset to prompt
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          setState(() {
            _isVerifying = false;
            _message = 'Set your PIN';
            _subMessage = 'Create a 4-digit code to secure your vault';
          });
          return;
        }

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
          // Final safety check for PIN complexity
          if (_isPinWeak(_pin)) {
            HapticFeedback.heavyImpact();
            setState(() {
              _pin = '';
              _firstPin = null;
              _isVerifying = false;
              _message = 'PIN Too Simple';
              _subMessage = 'Please choose a more complex PIN.';
            });
            return;
          }

          final salt = EncryptionService.generateSalt();
          // Use simple mode (10k iterations) for fast encryption
          final key = EncryptionService.deriveKey(_pin, salt, iterations: KeyDerivationConfig.simpleIterations);
          final hash = EncryptionService.hashKey(key);

          await _storage.saveSalt(salt);
          await _storage.saveAuthHash(hash);
          ref.read(sessionProvider.notifier).setSession(key);
          await _storage.saveSessionKey(key);

          // Log PIN setup or change
          if (widget.isSetup && _oldPinVerified) {
            await _logger.logEvent('PIN Changed', details: 'PIN successfully updated');
          } else {
            await _logger.logEvent('PIN Established', details: 'First-time PIN setup');
          }
          if (!mounted) return;
          
          setState(() {
            _isVerifying = false;
            _isSettingUpSecurityQuestion = true;
            _message = 'Recovery Setup';
            _subMessage = 'Choose a question for account recovery';
            _answerError = null; // Reset errors
            _answerController.clear();
          });

          // Show mandatory info popup
          _showRecoveryRulesPopup();
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
        // Use simple mode (10k iterations) for fast unlock
        final testKey = EncryptionService.deriveKey(_pin, savedSalt, iterations: KeyDerivationConfig.simpleIterations);
        final testHash = EncryptionService.hashKey(testKey);

        if (testHash == savedHash) {
          ref.read(sessionProvider.notifier).setSession(testKey);
          await _storage.saveSessionKey(testKey);
          await _logger.logEvent('App Unlocked');
          if (!mounted) return;
          _completeAuth();
          return;
        }
      }

      _handleFailure();
    }
  }

  void _showRecoveryRulesPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('Recovery Setup Rules', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your recovery answer is used to recover access if you forget your PIN.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Rules:'),
              const Text('• Minimum 4 characters'),
              const Text('• Single-word answers only'),
              const Text('• Spaces are NOT allowed'),
              const SizedBox(height: 12),
              const Text('Use: JohnSnow, John_Snow'),
              const Text('NOT: John Snow'),
              const SizedBox(height: 12),
              const Text('Important: Your input will be normalized to lowercase for verification.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showDetailedRecoveryGuide(),
            child: const Text('More'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDetailedRecoveryGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('Detailed Guide', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good examples:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              Text('• StarkFamily\n• MyDog2024\n• John_Snow\n• WinterIsComing'),
              SizedBox(height: 12),
              Text('Bad examples:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text('• John Snow (spaces)\n• my pin (spaces)\n• 123 (too short)\n• abc (too short)'),
              SizedBox(height: 16),
              Text('Validation Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Minimum 4 characters\n• No spaces allowed\n• Letters, Numbers, _ and - only'),
              SizedBox(height: 16),
              Text('⚠️ SECURITY WARNING', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
              Text('Do not share your recovery answer. Do not use publicly known information. This method protects your entire account access.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _handleFailure() {
    // Fallback or failed login
    HapticFeedback.vibrate();
    _failedAttempts++;

    // Log failed login attempt
    _logger.logEvent('Failed PIN Attempt', details: 'Attempt ${_failedAttempts}/3');

    if (_failedAttempts >= 3) {
      if (!mounted) return;
      setState(() {
        _pin = '';
        _isVerifying = false;
        _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
        _message = 'Security Lockout';
        _subMessage = 'Too many failed attempts.';
      });
      _logger.logEvent('Failed Login: Locked Out', details: '3+ attempts');
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
      _logger.logEvent('Failed Login Attempt');
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
    if (_isSettingUpSecurityQuestion || _isVerifyingSecurityQuestion) {
      return _buildSecurityQuestionUI();
    }

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
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                    _buildPinDisplay(),
                  ],
                ),
              ),
              
              if (!widget.isSetup && !_isLockedOut && !_isSettingUpSecurityQuestion && !_isVerifyingOldPin)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: _startForgotPinFlow,
                        child: const Text('Forgot PIN?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Biometric unlock coming soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
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

  Widget _buildSecurityQuestionUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSettingUpSecurityQuestion ? 'Setup Recovery' : 'Recover PIN'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSettingUpSecurityQuestion 
                ? 'Choose a question you\'ll remember' 
                : 'Answer your security question',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            if (_isSettingUpSecurityQuestion)
              DropdownButtonFormField<String>(
                value: _selectedQuestion,
                isExpanded: true, // Prevent horizontal overflow
                decoration: InputDecoration(
                  labelText: 'Security Question',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedQuestion = v),
              )
            else
              Text(
                _selectedQuestion ?? 'Loading question...',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            if (!_isSettingUpSecurityQuestion)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'WARNING: Resetting your PIN will make your currently encrypted files unreadable.',
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              onChanged: (v) => setState(() {}), // Force rebuild to update button state
              decoration: InputDecoration(
                labelText: 'Your Answer',
                errorText: _answerError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _answerController,
              builder: (context, value, _) {
                final canSubmit = _canSubmitAnswer();
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _saveOrVerifySecurityQuestion : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    child: Text(_isSettingUpSecurityQuestion ? 'Finish Setup' : 'Verify Answer', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startForgotPinFlow() async {
    final user = await _storage.getCurrentUser();
    if (user?.securityQuestion == null) {
      if (!mounted) return;
      SecuraNotifications.showError(context, 'No recovery method set for this account.');
      return;
    }

    // Show CRITICAL warning BEFORE allowing PIN reset attempt
    if (!mounted) return;
    final confirmDangerous = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text('PIN Reset Warning', style: TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ CRITICAL: Resetting your PIN will make ALL currently encrypted files UNRECOVERABLE.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              const Text(
                'This happens because your files are encrypted with your old PIN-derived key. '
                'Without the original PIN, the encryption key cannot be recreated.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Before proceeding:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Export your files while you still know your PIN'),
              const Text('• Ensure you remember your security answer'),
              const Text('• Consider writing down your current PIN'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel & Keep PIN'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('I Understand - Proceed'),
          ),
        ],
      ),
    );

    if (confirmDangerous != true) return;

    setState(() {
      _isVerifyingSecurityQuestion = true;
      _selectedQuestion = user!.securityQuestion;
      _answerController.clear();
      _answerError = null; // Clear any old error
      _securityAnswerAttempts = 0;
    });
  }

  Future<void> _saveOrVerifySecurityQuestion() async {
    // Check for security answer lockout
    if (_isSecurityLockedOut) {
      if (!mounted) return;
      SecuraNotifications.showError(
        context,
        'Too many failed attempts. Please wait $_securitySecondsRemaining seconds.',
      );
      return;
    }

    final inputAnswer = _answerController.text.trim().toLowerCase();
    if (inputAnswer.isEmpty) return;

    if (_isSettingUpSecurityQuestion) {
      if (_selectedQuestion == null) return;

      final user = ref.read(userProvider);
      if (user != null) {
        final answerHash = EncryptionService.hashString(inputAnswer);
        
        final updatedUser = user.copyWith(
          securityQuestion: _selectedQuestion,
          securityAnswerHash: answerHash,
        );

        // Explicitly await the save operation
        await ref.read(userProvider.notifier).saveUser(updatedUser);
        await _logger.logEvent('Security Question Configured', details: 'Question: $_selectedQuestion');

        if (mounted) {
          setState(() {
            _isVerifying = false;
            _isSettingUpSecurityQuestion = false;
          });
          _completeAuth();
        }
      } else {
        if (ref.read(sessionProvider) != null) {
          _completeAuth();
        }
      }
    } else {
      final user = await _storage.getCurrentUser();
      if (user != null) {
        final answerHash = EncryptionService.hashString(inputAnswer);

        if (answerHash == user.securityAnswerHash) {
          // Success - reset attempts and allow PIN reset
          setState(() {
            _securityAnswerAttempts = 0;
            _isVerifyingSecurityQuestion = false;
            _oldPinVerified = true;
            _isVerifyingOldPin = false;
            _message = 'Reset PIN';
            _subMessage = 'Choose a new 4-digit security code';
          });
          await _logger.logEvent('Security Answer Verified - PIN Reset Initiated');
        } else {
          // Failed attempt - increment counter and apply lockout if too many
          _securityAnswerAttempts++;

          if (!mounted) return;

          if (_securityAnswerAttempts >= 3) {
            _securityLockoutEndTime = DateTime.now().add(const Duration(minutes: 5));
            _startSecurityLockoutTimer();
            await _logger.logEvent('Security Answer: Locked Out');
            if (!mounted) return;
            SecuraNotifications.showError(
              context,
              'Too many failed attempts. Locked for 5 minutes.',
            );
          } else {
            await _logger.logEvent('Security Answer: Incorrect Attempt $_securityAnswerAttempts/3');
            if (!mounted) return;
            SecuraNotifications.showError(
              context,
              'Incorrect answer. ${3 - _securityAnswerAttempts} attempts remaining.',
            );
          }
        }
      }
    }
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        final isActive = index == _pin.length && !_isVerifying && _message != 'PIN Too Simple';
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 48,
          height: 58,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                : (isFilled ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).dividerColor),
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
    const keySpacing = 18.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKey(_keys[i * 3]),
                  const SizedBox(width: keySpacing),
                  _buildKey(_keys[i * 3 + 1]),
                  const SizedBox(width: keySpacing),
                  _buildKey(_keys[i * 3 + 2]),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 60),
              const SizedBox(width: keySpacing),
              _buildKey(_keys[9]),
              const SizedBox(width: keySpacing),
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
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2), 
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isIcon
              ? Icon(Icons.backspace_rounded, size: 18, color: Theme.of(context).hintColor)
              : Text(
                  label,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}
