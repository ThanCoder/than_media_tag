// ignore_for_file: avoid_print

import 'package:ffi/ffi.dart';
import 'package:than_media_tag/than_media_tag.dart';

void main() {
  final lib = getMediaReader();
  print('avutil_version: ${lib.avutil_version()}');
  print('avcodec_version: ${lib.avcodec_version()}');
  print('avformat_version: ${lib.avformat_version()}');
  print(
    'av_version_info: ${lib.av_version_info().cast<Utf8>().toDartString()}',
  );
}
