// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/material.dart';
import 'package:than_media_tag/than_media_tag.dart';

class TM {
  final String title;
  final Uint8List data;
  final Duration duration;

  const TM({required this.title, required this.data, required this.duration});
}

class VThumbGen extends StatefulWidget {
  const new({super.key, required this.dir});
  final Directory dir;

  @override
  State<VThumbGen> createState() => _ThumbGenState();
}

class _ThumbGenState extends State<VThumbGen> {
  @override
  void initState() {
    dir = widget.dir;
    init();
    super.initState();
  }

  late Directory dir;
  List<TM> list = [];
  bool isLoading = false;

  Future<void> init() async {
    setState(() {
      isLoading = true;
    });
    list.clear();
    for (var f in dir.listSync()) {
      if (f is! File) continue;
      // genThumb(f.path);
      final res = await MediaTagWorker.instance.getVideoThumbnail(f.path);
      if (res.isOk) {
        list.add(.new(title: f.name, data: res.unwrap(), duration: .zero));
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thumbnail Gen')),
      body: isLoading
          ? Center(child: CircularProgressIndicator.adaptive())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 150,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _gridItem(item);
              },
            ),
    );
  }

  Stack _gridItem(TM item) {
    return Stack(
      fit: .expand,
      children: [
        Column(
          children: [
            Image.memory(item.data, width: 100, height: 100),
            Expanded(child: Text(item.title)),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Text(item.duration.formatClockLabel()),
        ),
      ],
    );
  }
}
