import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:than_media_tag/core/av_format.dart';
import 'package:than_media_tag/core/result_t.dart';

part 'media_tag_worker_bg.dart';

class MediaTagWorker {
  static final MediaTagWorker instance = MediaTagWorker._();
  MediaTagWorker._();

  Isolate? _isolate;
  SendPort? _bgSendPort;
  Completer? _completer;
  Timer? _autoCloseTimer;
  int _reqCount = 0;

  Future<void> _init() async {
    final rp = ReceivePort();
    _isolate = await Isolate.spawn(_mediaTagWorkerBg, rp.sendPort);
    _bgSendPort = await rp.first as SendPort;
    rp.close();
  }

  Future<void> _startThread() async {
    if (_bgSendPort != null) return;

    if (_completer != null) {
      return _completer!.future;
    }

    final completer = Completer<void>();
    _completer = completer;

    try {
      await _init();
      completer.complete();
      print('[MediaTagWorker]: Start Thread');
    } catch (e, st) {
      completer.completeError(e, st);
      _completer = null;
      rethrow;
    }
  }

  Future<void> dispose() async {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;

    _isolate?.kill(priority: Isolate.immediate);

    _bgSendPort = null;
    _isolate = null;
    _completer = null;

    print('[MediaTagWorker]: Close Thread');
  }

  void _scheduleAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(Duration(seconds: 5), () {
      if (_reqCount != 0) return;
      dispose();
    });
  }

  Future<Result<Uint8List, String>> getAudioThumbnail(String path) async {
    _reqCount++;
    final rp = ReceivePort();
    try {
      await _startThread();
      _bgSendPort?.send({
        'command': GenCommandType.genAudioPic,
        'rp': rp.sendPort,
        'path': path,
      });

      final map = await rp.first as Map;

      final success = map['success'] as bool;
      if (!success) {
        final message = map['message'] as String;
        return Err(message);
      }
      final data = map['data'] as TransferableTypedData;
      return Ok(data.materialize().asUint8List());
    } catch (e) {
      return Err(e.toString());
    } finally {
      rp.close();
      _reqCount--;
      _scheduleAutoClose();
    }
  }

  Future<Result<Uint8List, String>> getVideoThumbnail(
    String path, {
    Duration position = const Duration(seconds: 5),
    int targetWidth = 0,
    int targetHeight = 0,
    ImageType type = .jpg,
    int quality = 90,
    bool infoLog = false,
  }) async {
    _reqCount++;
    final rp = ReceivePort();

    try {
      await _startThread();

      _bgSendPort?.send({
        'command': GenCommandType.genVideoThumbnail,
        'rp': rp.sendPort,
        'path': path,
        'infoLog': infoLog,
        'positionSec': position.inSeconds,
        'quality': quality,
        'targetHeight': targetHeight,
        'targetWidth': targetWidth,
        'type': type,
      });

      final map = await rp.first as Map;

      final success = map['success'] as bool;
      if (!success) {
        final message = map['message'] as String;
        return Err(message);
      }
      final data = map['data'] as TransferableTypedData;
      return Ok(data.materialize().asUint8List());
    } catch (e) {
      return Err(e.toString());
    } finally {
      rp.close();

      _reqCount--;
      _scheduleAutoClose();
    }
  }

  /// saved -> true
  Future<Result<bool, String>> saveAudioThumbnail(
    String path,
    String savePath, {
    bool isOverride = false,
  }) async {
    try {
      final f = File(savePath);
      if (f.existsSync() && !isOverride) return Ok(false);

      final res = await getAudioThumbnail(path);
      if (res.isErr) {
        return Err(res.unwrapError());
      }
      await f.writeAsBytes(res.unwrap());

      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// saved -> true
  Future<Result<bool, String>> saveVideoThumbnail(
    String path,
    String savePath, {
    bool isOverride = false,
    Duration position = const Duration(seconds: 5),
    int targetWidth = 0,
    int targetHeight = 0,
    ImageType type = .jpg,
    int quality = 90,
    bool infoLog = false,
  }) async {
    try {
      final f = File(savePath);
      if (f.existsSync() && !isOverride) return Ok(false);

      final res = await getVideoThumbnail(
        path,
        position: position,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        type: type,
        quality: quality,
        infoLog: infoLog,
      );
      if (res.isErr) {
        return Err(res.unwrapError());
      }
      await f.writeAsBytes(res.unwrap());

      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }
}
