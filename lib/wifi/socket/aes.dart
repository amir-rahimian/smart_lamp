// import 'dart:math';
//
// import 'package:aespack/aespack.dart';
//
// class AesEncryption {
//   final List<int> cipherKey;
//
//   AesEncryption(this.cipherKey);
//
//   Future<String> encryptData(String plainData) async {
//     int a = Random().nextInt(899) + 100; // Random number between 100 and 999
//     int b = Random().nextInt(899) + 100; // Random number between 100 and 999
//     a = b = 100;
//     final encodedData = await
//       Aespack.encrypt(plainData, String.fromCharCodes(cipherKey), _generateIV(a, b)) ?? '';
//     return "$a:$encodedData:$b"; // Format: a:encryptedData:b
//   }
//
//   Future<String> decryptData(String encryptedData) async {
//     final List<String> sp = encryptedData.split(":");
//     if (sp.length != 3) return "ERROR!";
//     final int a = int.parse(sp[0]);
//     final int b = int.parse(sp[2]);
//
//     var decryptedData = await
//       Aespack.decrypt(sp[1], String.fromCharCodes(cipherKey), _generateIV(a, b)) ?? '';
//     return decryptedData; // Return decrypted data
//   }
//
//   String _generateIV(int a, int b) {
//     return
//       List.generate(16, (i) => ((a ^ (b + i)) + ((a << 3) | (b >> 2)) + (i * 7)) % 10)
//       .join();
//   }
// }