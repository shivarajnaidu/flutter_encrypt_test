import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

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
    const url =
        'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'; // Replace with your file URL

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

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

        setState(() {
          _downloadProgress = bytesDownloaded / contentLength;
        });
      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();

        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
          _downloadedFiles.add(file);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download complete!')),
        );
      },
      onError: (e) {
        setState(() {
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      },
      cancelOnError: true,
    );
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

class VideoPlayerScreen extends StatefulWidget {
  final File file;

  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
