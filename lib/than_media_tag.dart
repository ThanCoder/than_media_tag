import 'dart:ffi';

import 'package:than_media_tag/than_media_tag_bindings_generated.dart';

MediaReaderBindings getMediaReader() {
  final lib = DynamicLibrary.open(
    '/home/thancoder/Downloads/ffmpeg-9.0.1-media-reader-native-so/build/lib/libmedia_reader.so',
  );
  return MediaReaderBindings(lib);
}
