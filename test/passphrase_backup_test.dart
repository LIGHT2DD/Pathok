import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Passphrase Backup Cryptography', () {
    final cipher = AesGcm.with256bits();

    test('derives key with PBKDF2-SHA256 and encrypts/decrypts successfully', () async {
      const passphrase = 'MySecretPassphrase123';
      const samplePayload = {'documents': ['Doc1', 'Doc2'], 'medicine_reminders': []};
      final jsonText = jsonEncode(samplePayload);

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

      final box = await cipher.encrypt(
        utf8.encode(jsonText),
        secretKey: secretKey,
      );

      // Verify decryption with correct passphrase
      final decryptedKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );

      final decryptedBytes = await cipher.decrypt(box, secretKey: decryptedKey);
      final decryptedJson = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;

      expect(decryptedJson['documents'], equals(['Doc1', 'Doc2']));
    });

    test('fails decryption when passphrase is wrong', () async {
      const correctPass = 'CorrectPass123';
      const wrongPass = 'WrongPassphrase456';
      const jsonText = '{"data": "confidential"}';

      final salt = Uint8List(16);
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(correctPass)),
        nonce: salt,
      );

      final box = await cipher.encrypt(
        utf8.encode(jsonText),
        secretKey: secretKey,
      );

      final wrongKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(wrongPass)),
        nonce: salt,
      );

      expect(
        () async => await cipher.decrypt(box, secretKey: wrongKey),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}

