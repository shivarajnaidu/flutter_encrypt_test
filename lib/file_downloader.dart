import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'utils.dart';

Future<File?> downloadFile(
  String url,
  Function(int, int) onProgress,
) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    final contentLength = response.contentLength ?? 0;
    int bytesDownloaded = 0;

    Directory? downloadsDirectory = await getDownlaodsDirectory();

    final filePath =
        '${downloadsDirectory!.path}/myvid_${DateTime.now().millisecondsSinceEpoch}.mp4'; // Adjust file name as needed
    final file = File(filePath);

    // Encryption setup
    final encrypter = Encrypter(AES(mykey));

    final fileStream = file.openWrite();
    response.stream.listen(
      (chunk) {
        bytesDownloaded += chunk.length;

        // Encrypt chunk
        final encryptedChunk = encrypter.encryptBytes(Uint8List.fromList(chunk), iv: myIV);

        // Write encrypted chunk to file
        fileStream.add(encryptedChunk.bytes);
        debugPrint("Downloading... $bytesDownloaded / $contentLength");
        onProgress(bytesDownloaded, contentLength);
      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();
        debugPrint("downlaod and encryption successful");
      },
      onError: (e) {
        fileStream.close();
        debugPrint("failed to encrypt");
        debugPrint(e.toString());
        return null;
      },
      cancelOnError: true,
    );

    return file;
  } catch (e) {
    return null;
  }
}
