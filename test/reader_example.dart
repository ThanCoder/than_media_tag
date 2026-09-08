// ignore_for_file: unused_import, avoid_print
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:than_media_tag/core/av_format.dart';
import 'package:than_media_tag/models/media_info.dart';
import 'package:than_media_tag/than_media_tag.dart';

void main() {
  // final version = getVersionInfo();
  // final path =
  //     '/home/thancoder/Music/The Crew - Get Low [GMV] [oQ6KD_FTix0].m4a';
  final path = '/home/thancoder/Videos/It Hunts (2026).mp4';
  final fmt = AvFormat();
  final res = fmt.open(path);
  if (res.isErr) {
    print(res.unwrapError());
    return;
  }

  final de = AvDecoder(fmt);
  final thRes = de.genThumbnail();
  if (thRes.isErr) {
    print('thumb: ${thRes.unwrapError()}');
    return;
  }
  final bytes = thRes.unwrap();
  print('thumb: ${bytes.length}');
  final f = File('thumb.png');
  f.writeAsBytesSync(bytes);

  // fmt.loadInfo();

  for (var stm in fmt.infoList) {
    print(stm);
    if (stm is AudioStreamInfo) {
      print('channels: ${stm.channels}');
      print('sampleRate: ${stm.sampleRateLabel}');
      print('bitrate: ${stm.bitrateLabel}');
      print('format: ${stm.format}');
      final tag = stm.tag;
      print('tag: $tag');

      print('attachedPictureExists: ${tag.attachedPictureExists}');
      print('attachedPicture data: ${tag.readAttachedPicture?.length}');
      // final saveRes = tag.attachedPictureAsFile('test.png');
      // if (saveRes.isOk) {
      //   print('saved');
      // }
    }
  }
}
