import 'dart:convert';

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

  Future<Map<String, dynamic>> read() async {
    await _migrateLegacyData();
    final encoded = await _storage.read(key: _payloadKey);
    if (encoded == null) return <String, dynamic>{};
    try {
      final bytes = base64Url.decode(encoded);
      final key = await _key();
      final box = SecretBox(
        bytes.sublist(12, bytes.length - 16),
        nonce: bytes.sublist(0, 12),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      );
      final plain = await _cipher.decrypt(box, secretKey: key);
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } on Exception {
      throw StateError('স্থানীয় encrypted data পড়া যায়নি।');
    }
  }

  Future<void> write(Map<String, dynamic> payload) async {
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

  Future<void> clear() async {
    await _storage.delete(key: _payloadKey);
    await _storage.delete(key: _keyKey);
  }

  Future<String> exportEncryptedPayload() async {
    final encoded = await _storage.read(key: _payloadKey);
    if (encoded == null) {
      await write(<String, dynamic>{});
      return (await _storage.read(key: _payloadKey))!;
    }
    return encoded;
  }

  Future<void> importEncryptedPayload(String encoded) async {
    try {
      final bytes = base64Url.decode(encoded.trim());
      if (bytes.length < 28) throw const FormatException();
      final key = await _key();
      final box = SecretBox(
        bytes.sublist(12, bytes.length - 16),
        nonce: bytes.sublist(0, 12),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      );
      await _cipher.decrypt(box, secretKey: key);
      await _storage.write(key: _payloadKey, value: encoded.trim());
    } on Exception {
      throw StateError('Backup ফাইলটি বৈধ নয় বা এই ডিভাইসের নয়।');
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
