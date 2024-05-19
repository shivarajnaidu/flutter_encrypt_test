// file_downloader.dart
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File?> downloadFile(
  String url,
  Function(int, int) onProgress,
) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    final contentLength = response.contentLength ?? 0;
    int bytesDownloaded = 0;

    Directory? downloadsDirectory;

    if (Platform.isAndroid) {
      downloadsDirectory = await getExternalStorageDirectory();
    } else {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }

    final filePath =
        '${downloadsDirectory!.path}/myvid_${DateTime.now().millisecondsSinceEpoch}.mp4'; // Adjust file name as needed
    final file = File(filePath);

    final fileStream = file.openWrite();
    response.stream.listen(
      (chunk) {
        bytesDownloaded += chunk.length;
        fileStream.add(chunk);

        onProgress(bytesDownloaded, contentLength);
      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();
      },
      onError: (e) {
        fileStream.close();
        return null;
      },
      cancelOnError: true,
    );

    return file;
  } catch (e) {
    return null;
  }
}
