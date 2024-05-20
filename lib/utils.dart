import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

getRandomString(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random rnd = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

const String encryptionKey = "my 32 length key................";
final mykey = encrypt.Key.fromUtf8(encryptionKey); // Use the same key used for encryption
final myIV = encrypt.IV.fromLength(16);
// String encryptionKey = getRandomString(32);

getDownlaodsDirectory() async {
  Directory? downloadsDirectory;

  if (Platform.isAndroid) {
    downloadsDirectory = await getExternalStorageDirectory();
  } else {
    downloadsDirectory = await getApplicationDocumentsDirectory();
  }

  return downloadsDirectory;
}

Future<File?> decryptFile(File encryptedFile, String outputPath) async {
  try {
    final encrypter = encrypt.Encrypter(encrypt.AES(mykey, mode: encrypt.AESMode.cbc, padding: null));

    final decryptedFile = File(outputPath);
    final encryptedStream = encryptedFile.openRead();
    final decryptedStream = decryptedFile.openWrite();

    await for (var chunk in encryptedStream) {
      // Convert chunk to Uint8List
      final uint8ListChunk = Uint8List.fromList(chunk);

      // Decrypt chunk
      final decryptedChunk =
          encrypter.decryptBytes(encrypt.Encrypted(uint8ListChunk), iv: myIV);

      // Write decrypted chunk to file
      decryptedStream.add(decryptedChunk);
    }

    await decryptedStream.flush();
    await decryptedStream.close();
    debugPrint("decryption successful");

    return decryptedFile;
  } catch (e) {
    print(e);
    return null;
  }
}
