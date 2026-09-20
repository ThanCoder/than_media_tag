// ignore_for_file: unused_import, avoid_print
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:than_media_tag/core/av_format.dart';
import 'package:than_media_tag/models/media_info.dart';
import 'package:than_media_tag/than_media_tag.dart';

void main() {
  final dir = Directory('/home/thancoder/Downloads/New Folder');

  for (var f in dir.listSync()) {
    if (f is! File) continue;
    genThumb(f.path);
  }
}

void genThumb(String path) {
  final fmt = AvFormat();
  final fmtRes = fmt.open(path);

  if (fmtRes.isErr) {
    return;
  }

  final de = fmt.toDecoder;
  final genRes = de.genThumbnail();
  if (genRes.isOk) {
    final bytes = genRes.unwrap();
    print('thumb: ${bytes.length}');
  }

  fmt.close();
}
