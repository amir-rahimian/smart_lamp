import 'dart:convert';
import 'dart:math';

import 'package:aespack/aespack.dart';

class Encryption {
  static final String _defaultKey = '0123456789876543';

  static String _generateIV(int a, int b) {
    List<int> iv = List.filled(16, 0);
    for (int i = 0; i < 16; i++) {
      iv[i] = ((a ^ (b + i)) + ((a << 3) | (b >> 2)) + (i * 7)) % 10;
    }
    return iv.map((e) => e.toString()).join();
  }

  static Future<String> encrypt(String plainText, {String? key}) async {
    // Use provided key or default key
    String cipherKey = key ?? _defaultKey;

    // Generate the IV based on the logic similar to the C++ code
    int a = Random().nextInt(899) + 100;
    int b = Random().nextInt(899) + 100;
    a = b = 100;

    String iv = _generateIV(a, b);
    String encryptedText = await Aespack.encrypt(plainText, cipherKey, iv) ?? '';

    // Base64 encode and append a and b
    String base64Data = base64Encode(utf8.encode(encryptedText));
    return "$a:$encryptedText:$b";
  }

  static Future<String> decrypt(String encryptedData, {String? key}) async {
    // Use provided key or default key
    String cipherKey = key ?? _defaultKey;

    // Extract a and b from the string
    List<String> parts = encryptedData.split(':');
    if (parts.length != 3) return '';

    int a = int.tryParse(parts[0]) ?? 0;
    String base64Data = parts[1];
    int b = int.tryParse(parts[2]) ?? 0;

    if (a == 0 || b == 0) return '';

    String iv = _generateIV(a, b);

    // Base64 decode the encrypted string
    // String decodedData = utf8.decode(base64Decode(base64Data));

    // Decrypt the data
    String decryptedText = await Aespack.decrypt(base64Data, cipherKey, iv) ?? '';

    return decryptedText;
  }
}
