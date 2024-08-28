// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:math';
// import 'package:encrypt/encrypt.dart' as aes;
//
// class Encryption {
//   final Uint8List cipherKey;
//
//   Encryption(this.cipherKey);
//
//   String encryptData(String plainData) {
//     final Uint8List data = _padData(plainData);
//     int a = Random().nextInt(899)+100;
//     int b = Random().nextInt(899)+100;
//     a = b = 100;
//     final Uint8List iv = _generateIV(a, b);
//     final aes.Encrypter encryptor = aes.Encrypter(aes.AES(aes.Key(cipherKey), mode: aes.AESMode.cbc));
//     final String encodedData = base64.encode(encryptor.encryptBytes(data, iv: aes.IV(iv)).bytes);
//     return "$a:$encodedData:$b";
//   }
//
//   String decryptData(String encryptedData) {
//     final List<String> sp = encryptedData.split(":");
//     if (sp.length!=3) return "ERROR!";
//     final int a = int.parse(sp[0]);
//     final int b = int.parse(sp[2]);
//     final Uint8List decodedData = base64.decode(sp[1]);
//     final Uint8List encryptedBytes = decodedData;
//     final aes.Encrypter decryptor = aes.Encrypter(aes.AES(aes.Key(cipherKey), mode: aes.AESMode.cbc));
//     final Uint8List decryptedData = Uint8List.fromList(decryptor.decryptBytes(aes.Encrypted(encryptedBytes), iv: aes.IV(_generateIV(a, b))));
//     return _removePadding(decryptedData);
//   }
//
//   Uint8List _padData(String plainData) {
//     final int len = plainData.length;
//     final int nPadding = (16 - len % 16) % 16;
//     final Uint8List data = Uint8List(len + nPadding);
//     data.setRange(0, len, utf8.encode(plainData));
//     for (int i = len; i < data.length; i++) {
//       data[i] = nPadding;
//     }
//     return data;
//   }
//
//   Uint8List _generateIV(int a, int b) {
//     return Uint8List.fromList(List.generate(16, (i) => (a ^ (b + i)) + ((a << 3) | (b >> 2)) + (i * 7)));
//   }
//
//   String _removePadding(Uint8List decryptedData) {
//     final int paddingLength = decryptedData.last;
//     return utf8.decode(decryptedData.sublist(0, decryptedData.length - paddingLength));
//   }
// }
