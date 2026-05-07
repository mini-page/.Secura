import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';

class EncryptionService {
  /// Generate a random 16-byte salt
  static String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Derive a 32-byte AES key from PIN + Salt using SHA-256
  static String deriveKey(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    // Simple fast derivation for mobile; in prod Argon2/PBKDF2 is better.
    // Doing multi-round SHA-256 to increase difficulty
    Digest digest = sha256.convert(bytes);
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return base64Url.encode(digest.bytes);
  }

  /// Create a verification hash to store (SHA-256 of the Key)
  static String hashKey(String base64Key) {
    final bytes = base64Url.decode(base64Key);
    return base64Url.encode(sha256.convert(bytes).bytes);
  }

  /// Encrypts bytes using AES-256-GCM with a unique IV
  /// The IV is prepended to the ciphertext
  static Uint8List encryptBytes(Uint8List bytes, String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    // Ensure key is exactly 32 bytes
    final paddedKey = Uint8List(32);
    for (int i = 0; i < keyBytes.length && i < 32; i++) {
      paddedKey[i] = keyBytes[i];
    }
    final key = encrypt_pkg.Key(paddedKey);
    final iv = encrypt_pkg.IV.fromSecureRandom(16);

    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    // Combine IV + Encrypted Data
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return combined;
  }

  /// Decrypts bytes that were encrypted with [encryptBytes]
  static Uint8List decryptBytes(Uint8List combined, String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    final paddedKey = Uint8List(32);
    for (int i = 0; i < keyBytes.length && i < 32; i++) {
      paddedKey[i] = keyBytes[i];
    }
    final key = encrypt_pkg.Key(paddedKey);

    // Extract IV (first 16 bytes)
    final ivBytes = combined.sublist(0, 16);
    final ciphertext = combined.sublist(16);

    final iv = encrypt_pkg.IV(ivBytes);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.gcm));

    final decrypted = encrypter.decryptBytes(encrypt_pkg.Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}
