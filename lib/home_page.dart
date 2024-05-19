// home_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_downloader.dart';
import 'video_player_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  List<File> _downloadedFiles = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final file = await downloadFile(
      'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      (bytesDownloaded, totalBytes) {
        setState(() {
          _downloadProgress = bytesDownloaded / totalBytes;
        });
      },
    );

    if (file != null) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
        _downloadedFiles.add(file);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download complete!')),
      );
    } else {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  Future<void> _listDownloadedFiles() async {
    Directory? downloadsDirectory;

    if (Platform.isAndroid) {
      downloadsDirectory = await getExternalStorageDirectory();
    } else {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }

    final List<FileSystemEntity> files = downloadsDirectory!.listSync();
    final List<File> videoFiles = files.whereType<File>().toList();

    setState(() {
      _downloadedFiles = videoFiles;
    });
  }

  @override
  void initState() {
    super.initState();
    _listDownloadedFiles();
  }

  void _playVideo(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _isDownloading
                ? Column(
                    children: [
                      const Text('Downloading...'),
                      LinearProgressIndicator(value: _downloadProgress),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _downloadFile,
                    child: const Text('Download File'),
                  ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _downloadedFiles.length,
                itemBuilder: (context, index) {
                  final file = _downloadedFiles[index];
                  return ListTile(
                    title: Text(file.path.split('/').last),
                    onTap: () => _playVideo(file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
