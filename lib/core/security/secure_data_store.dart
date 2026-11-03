import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureDataStore {
  SecureDataStore._();

  static final instance = SecureDataStore._();
  static const _payloadKey = 'encrypted_pathok_payload';
  static const _keyKey = 'pathok_data_key';
  static const _legacyDocumentsKey = 'documents';
  static const _legacyRemindersKey = 'medicine_reminders';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AesGcm _cipher = AesGcm.with256bits();
  Map<String, dynamic>? _cachedPayload;

  /// Reads internal encrypted application state with in-memory caching
  Future<Map<String, dynamic>> read() async {
    if (_cachedPayload != null) {
      return Map<String, dynamic>.from(_cachedPayload!);
    }
    await _migrateLegacyData();
    final encoded = await _storage.read(key: _payloadKey);
    if (encoded == null) {
      _cachedPayload = <String, dynamic>{};
      return <String, dynamic>{};
    }
    try {
      final bytes = base64Url.decode(encoded);
      final key = await _key();
      final box = SecretBox(
        bytes.sublist(12, bytes.length - 16),
        nonce: bytes.sublist(0, 12),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      );
      final plain = await _cipher.decrypt(box, secretKey: key);
      _cachedPayload = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      return Map<String, dynamic>.from(_cachedPayload!);
    } on Exception {
      throw StateError('স্থানীয় encrypted data পড়া যায়নি।');
    }
  }

  /// Writes internal encrypted application state
  Future<void> write(Map<String, dynamic> payload) async {
    _cachedPayload = Map<String, dynamic>.from(payload);
    final key = await _key();
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
    );
    final bytes = <int>[...box.nonce, ...box.cipherText, ...box.mac.bytes];
    await _storage.write(
      key: _payloadKey,
      value: base64UrlEncode(bytes),
    );
  }

  /// Deletes all encrypted data from secure storage
  Future<void> clear() async {
    _cachedPayload = null;
    await _storage.delete(key: _payloadKey);
    await _storage.delete(key: _keyKey);
  }

  /// Encrypts raw bytes (e.g. sensitive document photo or PDF) with local AES-GCM-256 key
  Future<Uint8List> encryptBytes(List<int> plainBytes) async {
    final key = await _key();
    final box = await _cipher.encrypt(plainBytes, secretKey: key);
    return Uint8List.fromList(<int>[...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Decrypts raw encrypted bytes with local AES-GCM-256 key
  Future<Uint8List> decryptBytes(List<int> encryptedBytes) async {
    if (encryptedBytes.length < 28) {
      throw const FormatException('Invalid encrypted payload size');
    }
    final key = await _key();
    final box = SecretBox(
      encryptedBytes.sublist(12, encryptedBytes.length - 16),
      nonce: encryptedBytes.sublist(0, 12),
      mac: Mac(encryptedBytes.sublist(encryptedBytes.length - 16)),
    );
    final plain = await _cipher.decrypt(box, secretKey: key);
    return Uint8List.fromList(plain);
  }

  /// Exports backup protected by user's chosen passphrase (cross-device compatible)
  Future<String> exportWithPassphrase(String passphrase) async {
    if (passphrase.trim().length < 6) {
      throw ArgumentError('Passphrase must be at least 6 characters.');
    }
    final payload = await read();
    final jsonString = jsonEncode(payload);

    // Generate 16-byte random salt
    final random = Random.secure();
    final salt = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      salt[i] = random.nextInt(256);
    }

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );

    final box = await _cipher.encrypt(
      utf8.encode(jsonString),
      secretKey: secretKey,
    );

    final backupPayload = <String, dynamic>{
      'version': '2.0',
      'salt': base64UrlEncode(salt),
      'nonce': base64UrlEncode(box.nonce),
      'cipherText': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };

    return jsonEncode(backupPayload);
  }

  /// Imports backup protected by passphrase
  Future<void> importWithPassphrase(String backupContent, String passphrase) async {
    try {
      final decoded = jsonDecode(backupContent.trim()) as Map<String, dynamic>;
      if (decoded['version'] != '2.0' ||
          decoded['salt'] == null ||
          decoded['nonce'] == null ||
          decoded['cipherText'] == null ||
          decoded['mac'] == null) {
        throw const FormatException('Unsupported backup format');
      }

      final salt = base64Url.decode(decoded['salt'] as String);
      final nonce = base64Url.decode(decoded['nonce'] as String);
      final cipherText = base64Url.decode(decoded['cipherText'] as String);
      final mac = base64Url.decode(decoded['mac'] as String);

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      );
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );

      final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final plainBytes = await _cipher.decrypt(box, secretKey: secretKey);
      final newPayload = jsonDecode(utf8.decode(plainBytes)) as Map<String, dynamic>;

      await write(newPayload);
    } on Exception {
      throw StateError('Backup ফাইলটি অবৈধ বা পাসওয়ার্ডটি ভুল।');
    }
  }

  Future<SecretKey> _key() async {
    final existing = await _storage.read(key: _keyKey);
    if (existing != null) {
      return SecretKey(base64Url.decode(existing));
    }
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _storage.write(key: _keyKey, value: base64UrlEncode(bytes));
    return SecretKey(bytes);
  }

  Future<void> _migrateLegacyData() async {
    final preferences = await SharedPreferences.getInstance();
    final hasEncrypted = await _storage.containsKey(key: _payloadKey);
    if (hasEncrypted) return;
    final documents = preferences.getStringList(_legacyDocumentsKey);
    final reminders = preferences.getStringList(_legacyRemindersKey);
    if (documents == null && reminders == null) return;
    await write({
      'documents': documents ?? <String>[],
      'medicine_reminders': reminders ?? <String>[],
    });
    await preferences.remove(_legacyDocumentsKey);
    await preferences.remove(_legacyRemindersKey);
  }
}

