// ignore_for_file: unused_import, avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:media_reader_example/v_thumb_gen.dart';
import 'package:than_media_tag/core/av_format.dart';
import 'package:than_media_tag/than_media_tag.dart';

void main() {
  runApp(MaterialApp(theme: .dark(), home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ListTile(
            title: Text('Thumbnail'),
            onTap: () {
              context.goRoute(
                builder: (mainCtx) => VThumbGen(
                  dir: Directory('/home/thancoder/Downloads/New Folder'),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _test(),
    );
  }

  FloatingActionButton _test() {
    return FloatingActionButton(
      onPressed: () async {
        // final dir = Directory('/home/thancoder/Downloads/New Folder');

        // for (var f in dir.listSync()) {
        //   if (f is! File) continue;
        //   final res = await MediaTagWorker.instance.getVideoThumbnail(f.path);
        //   if (res.isOk) {
        //     print('data: len ${res.unwrap().length}');
        //   }
        // }

        // final dir = Directory('/home/thancoder/Downloads/Music');
        // final list = dir.listSync();
        // genAThumb(list[1].path);

        // for (var f in list) {
        //   if (f is! File) continue;
        //   final res = await MediaTagWorker.instance.getAudioThumbnail(f.path);
        //   if (res.isOk) {
        //     print('data: len ${res.unwrap().length}');
        //   }
        //   // return;
        // }
      },
    );
  }

  void genAThumb(String path) {
    // print('[gen:] -> $path');
    final fmt = AvFormat();
    final fmtRes = fmt.open(path);

    if (fmtRes.isErr) {
      print('[fmtRes Error:]: ${fmtRes.unwrapError()} -> $path');
      return;
    }

    final pic = fmt.attachedPicBytes;
    if (pic != null) {
      print('pic len: ${pic.length} -> $path');
    }

    fmt.close();
  }
}

void genVThumb(String path) {
  // print('[gen:] -> $path');
  final fmt = AvFormat();
  final fmtRes = fmt.open(path);

  if (fmtRes.isErr) {
    print('[fmtRes Error:]: ${fmtRes.unwrapError()} -> $path');
    return;
  }

  final de = fmt.toDecoder;
  final genRes = de.genThumbnail();
  if (genRes.isErr) {
    print('[gen Error:] ${genRes.unwrapError()} -> $path');
  }

  if (genRes.isOk) {
    final bytes = genRes.unwrap();
    print('[thumb size]: ${bytes.length} ->  $path');
  }

  fmt.close();
}

extension Ctx on BuildContext {
  void goRoute({required Widget Function(BuildContext mainCtx) builder}) {
    Navigator.push(this, MaterialPageRoute(builder: builder));
  }
}
