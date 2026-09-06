import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:than_media_tag/than_media_tag_bindings_generated.dart';

/// ```dart
/// final lib = getMediaReader(libName: '[custom path]');
/// ```
MediaReaderBindings getMediaReader({String? libName}) {
  if (libName != null) {
    return MediaReaderBindings(.open(libName));
  }
  final lib = DynamicLibrary.open('libthan_media_tag.so');
  // final lib = DynamicLibrary.open(
  //   '/home/thancoder/Downloads/ffmpeg-9.0.1-media-reader-native-so/linux/libthan_media_tag.so',
  // );

  return MediaReaderBindings(lib);
}

void showVersionInfo() {
  final lib = getMediaReader();
  print('avutil_version: ${lib.avutil_version()}');
  print('avcodec_version: ${lib.avcodec_version()}');
  print('avformat_version: ${lib.avformat_version()}');
  print(
    'av_version_info: ${lib.av_version_info().cast<Utf8>().toDartString()}',
  );
}
