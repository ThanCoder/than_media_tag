// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    final libName = 'libthan_media_tag.so';
    final sourceLib =
        '/home/thancoder/Downloads/ffmpeg-9.0.1-than-media-tag-native-so';
    late File libFile;
    if (targetOS == .linux) {
      libFile = File(sourceLib.join('linux').join(libName));
    }
    if (targetOS == .android) {
      if (targetArchitecture == .arm64) {
        libFile = File(sourceLib.join('android').join('arm64').join(libName));
      }
    }

    output.assets.code.add(
      .new(
        package: packageName,
        name: libName,
        linkMode: DynamicLoadingBundled(),
        file: libFile.uri,
      ),
    );
  });
}

extension StringJoin on String {
  String join(String name) {
    return '$this${Platform.pathSeparator}$name';
  }
}
