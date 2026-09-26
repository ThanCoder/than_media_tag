part of 'media_tag_worker.dart';

enum GenCommandType { genAudioPic, genVideoThumbnail }

void _mediaTagWorkerBg(SendPort sp) {
  final rp = ReceivePort();
  sp.send(rp.sendPort);

  rp.listen((map) {
    if (map is! Map) return;
    final command = map['command'] as GenCommandType;
    final rp = map['rp'] as SendPort;
    final path = map['path'] as String;

    if (command == .genAudioPic) {
      final res = _getAudioPicture(path);
      if (res.isErr) {
        rp.send({'success': false, 'message': res.unwrapError()});
        return;
      }
      rp.send({
        'success': true,
        'data': TransferableTypedData.fromList([res.unwrap()]),
      });
    }
    if (command == .genVideoThumbnail) {
      int targetWidth = map['targetWidth'] as int;
      int targetHeight = map['targetWidth'] as int;
      ImageType type = map['type'] as ImageType;
      int quality = map['quality'] as int;
      bool infoLog = map['infoLog'] as bool;
      final positionSec = map['positionSec'] as int;
      final res = _getVideoThumbnail(
        path,
        infoLog: infoLog,
        position: Duration(seconds: positionSec),
        quality: quality,
        targetHeight: targetHeight,
        targetWidth: targetWidth,
        type: type,
      );
      if (res.isErr) {
        rp.send({'success': false, 'message': res.unwrapError()});
        return;
      }
      rp.send({
        'success': true,
        'data': TransferableTypedData.fromList([res.unwrap()]),
      });
    }
  });
}

Result<Uint8List, String> _getAudioPicture(String path) {
  // print('[gen:] -> $path');
  final fmt = AvFormat();
  final fmtRes = fmt.open(path);

  if (fmtRes.isErr) {
    return Err(fmtRes.unwrapError());
  }

  final pic = fmt.attachedPicBytes;

  fmt.close();
  if (pic != null) {
    return Ok(pic);
  }
  return Err('Data Not Found!');
}

Result<Uint8List, String> _getVideoThumbnail(
  String path, {
  Duration position = const Duration(seconds: 5),
  int targetWidth = 0,
  int targetHeight = 0,
  ImageType type = .jpg,
  int quality = 90,
  bool infoLog = false,
}) {
  // print('[gen:] -> $path');
  final fmt = AvFormat();
  final fmtRes = fmt.open(path);

  if (fmtRes.isErr) {
    return Err(fmtRes.unwrapError());
  }

  final de = fmt.toDecoder;
  final genRes = de.genThumbnail(
    infoLog: infoLog,
    position: position,
    quality: quality,
    targetHeight: targetHeight,
    targetWidth: targetWidth,
    type: type,
  );

  fmt.close();

  if (genRes.isOk) {
    return Ok(genRes.unwrap());
  }
  return Err(genRes.unwrapError());
}
