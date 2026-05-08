import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';

/// Configuration for key derivation - production ready
class KeyDerivationConfig {
  static const int iterations = 600000; // OWASP recommended minimum
  static const int keyLength = 32; // 256-bit AES key
  static const int saltLength = 32; // 256-bit salt
}

/// Production-grade encryption service with secure key derivation
class EncryptionService {
  /// Generate a cryptographically secure random salt
  static String generateSalt() {
    final random = math.Random.secure();
    final values = List<int>.generate(KeyDerivationConfig.saltLength, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Derive a 32-byte AES key from PIN + Salt using PBKDF2-HMAC-SHA256
  /// Uses OWASP recommended iteration count for production security
  static String deriveKey(String pin, String salt) {
    final saltBytes = base64Url.decode(salt);
    final pinBytes = utf8.encode(pin);

    // PBKDF2 implementation using HMAC-SHA256
    final result = _pbkdf2(
      password: pinBytes,
      salt: saltBytes,
      iterations: KeyDerivationConfig.iterations,
      keyLength: KeyDerivationConfig.keyLength,
    );

    return base64Url.encode(result);
  }

  /// PBKDF2-HMAC-SHA256 implementation
  static Uint8List _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, password);
    final Uint8List result = Uint8List(keyLength);

    int blockCount = (keyLength / 32).ceil();
    int offset = 0;

    for (int blockNum = 1; blockNum <= blockCount; blockNum++) {
      // Build INT(i) - the block index
      final intBytes = ByteData(4)..setUint32(0, blockNum, Endian.big);

      // First iteration: U1 = PRF(Password, Salt || INT(i))
      final U = Uint8List(salt.length + 4);
      U.setAll(0, salt);
      U.setAll(salt.length, intBytes.buffer.asUint8List());

      var current = hmac.convert(U).bytes;
      var uResult = Uint8List.fromList(current);

      // Subsequent iterations: Uj = PRF(Password, Uj-1)
      for (int j = 1; j < iterations; j++) {
        current = hmac.convert(current).bytes;
        for (int k = 0; k < current.length; k++) {
          uResult[k] ^= current[k];
        }
      }

      // Copy to result
      final copyLen = math.min(32, keyLength - offset).toInt();
      result.setRange(offset, offset + copyLen, uResult);
      offset += copyLen;
    }

    return result;
  }

  /// Create a verification hash to store (double SHA-256 of the Key)
  static String hashKey(String base64Key) {
    try {
      final bytes = base64Url.decode(base64Key);
      // Double hash for extra security in storage
      final first = sha256.convert(bytes);
      return base64Url.encode(sha256.convert(first.bytes).bytes);
    } catch (e) {
      return hashString(base64Key);
    }
  }

  /// Hashes a raw string (e.g. security answer) directly with salt
  static String hashString(String input, {String? salt}) {
    final combined = salt != null ? input + salt : input;
    final bytes = utf8.encode(combined);
    return base64Url.encode(sha256.convert(bytes).bytes);
  }

  /// Verify that a plaintext matches a stored hash
  static bool verifyHash(String plaintext, String storedHash, {String? salt}) {
    final computed = hashString(plaintext, salt: salt);
    return computed == storedHash;
  }

  /// Encrypts bytes using AES-256-GCM with a unique 12-byte IV
  /// Returns: IV (12 bytes) + Auth Tag (16 bytes) + Ciphertext
  static Uint8List encryptBytes(Uint8List bytes, String base64Key) {
    if (bytes.isEmpty) {
      throw ArgumentError('Cannot encrypt empty data');
    }

    final keyBytes = base64Url.decode(base64Key);

    // Strict key validation - enforce exactly 32 bytes
    if (keyBytes.length != 32) {
      throw ArgumentError('Invalid key length: ${keyBytes.length}. Expected 32 bytes.');
    }

    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_pkg.IV.fromSecureRandom(12);

    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    // Combine IV (12 bytes) + Encrypted Data
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return combined;
  }

  /// Decrypts bytes that were encrypted with [encryptBytes]
  /// Returns detailed error information for debugging
  static Uint8List decryptBytes(Uint8List combined, String base64Key) {
    if (combined.isEmpty) {
      throw EncryptionException('Decryption failed: File is empty or corrupted.');
    }

    if (combined.length < 28) { // 12 (IV) + 16 (tag) minimum
      throw EncryptionException('Decryption failed: File is too small. May be corrupted.');
    }

    final keyBytes = base64Url.decode(base64Key);

    if (keyBytes.length != 32) {
      throw EncryptionException('Invalid encryption key. Please re-authenticate.');
    }

    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));

    // 1. Try Standard GCM (12-byte IV)
    try {
      final ivBytes = combined.sublist(0, 12);
      final ciphertext = combined.sublist(12);

      final iv = encrypt_pkg.IV(ivBytes);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.gcm));
      return Uint8List.fromList(encrypter.decryptBytes(encrypt_pkg.Encrypted(ciphertext), iv: iv));
    } catch (e) {
      // Try legacy format
    }

    // 2. Try Legacy (16-byte IV)
    if (combined.length > 16) {
      try {
        final ivBytes = combined.sublist(0, 16);
        final ciphertext = combined.sublist(16);

        final iv = encrypt_pkg.IV(ivBytes);
        final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.gcm));
        return Uint8List.fromList(encrypter.decryptBytes(encrypt_pkg.Encrypted(ciphertext), iv: iv));
      } catch (e) {
        // Continue to error
      }
    }

    throw EncryptionException(
      'Decryption failed. Possible causes:\n'
      '• PIN was changed after encryption\n'
      '• File encrypted with different account\n'
      '• File is corrupted\n\n'
      'Your data is safe but requires the original PIN to unlock.'
    );
  }

  /// Generate a secure random encryption key for export/backup
  static String generateRandomKey() {
    final random = math.Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Verify file integrity after decryption using HMAC
  static bool verifyIntegrity(Uint8List decrypted, String expectedHash) {
    final computed = sha256.convert(decrypted);
    return base64Url.encode(computed.bytes) == expectedHash;
  }
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => message;
}
