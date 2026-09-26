# than_media_tag

### Example
```dart
for (var f in dir.listSync()) {
    if (f is! File) continue;
    // genThumb(f.path);
    final res = await MediaTagWorker.instance.getVideoThumbnail(f.path);
    if (res.isOk) {
      list.add(.new(title: f.name, data: res.unwrap(), duration: .zero));
    }
  }
```

### Low Level
```dart
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

  // fmt.loadInfo()

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

  fmt.close();
```