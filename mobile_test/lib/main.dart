import 'package:flutter/material.dart';

import 'torrent_download.dart';

void main() => runApp(const LibtorrentExampleApp());

class LibtorrentExampleApp extends StatelessWidget {
  const LibtorrentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'libtorrent_dart example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const TorrentDownloadPage(),
    );
  }
}
