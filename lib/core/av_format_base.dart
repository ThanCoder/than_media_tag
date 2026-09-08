part of 'av_format.dart';

sealed class AvFormatBase {
  Pointer<Pointer<AVFormatContext>> _fmtCtx = nullptr;
  Pointer<AVFormatContext> get context => _fmtCtx.value;

  Result<bool, String> open(String path) {
    try {
      _fmtCtx = calloc<Pointer<AVFormatContext>>();

      final pathPtr = path.toNativeUtf8();
      int ret = lib.avformat_open_input(
        _fmtCtx,
        pathPtr.cast<Char>(),
        nullptr,
        nullptr,
      );
      malloc.free(pathPtr);

      if (ret < 0) {
        close();
        return Ok(false);
      }

      Result<bool, String> res = _readStreamInfo();
      if (res.isErr) {
        return res;
      }
      return _readStreams();
    } catch (e) {
      close();
      return Err(e.toString());
    }
  }

  Result<bool, String> _readStreamInfo() {
    try {
      if (_fmtCtx == nullptr || context == nullptr) {
        return Ok(false);
      }

      final ret = lib.avformat_find_stream_info(context, nullptr);

      if (ret < 0) {
        return Ok(false);
      }

      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Pointer<AVStream> _audioStream = nullptr;
  Pointer<AVStream> _videoStream = nullptr;
  Pointer<AVStream> _attachedPicStream = nullptr;
  Pointer<AVStream> _subtitleStream = nullptr;
  List<MediaStreamInfo> infoList = [];

  Result<bool, String> _readStreams() {
    try {
      final ctx = context;

      final streamCount = ctx.ref.nb_streams;
      // print('stream count: $streamCount');

      for (var i = 0; i < streamCount; i++) {
        final stream = ctx.ref.streams[i];
        final codecpar = stream.ref.codecpar;
        final type = codecpar.ref.codec_type;

        if (type == .AVMEDIA_TYPE_VIDEO) {
          final attachPic =
              (stream.ref.disposition & AV_DISPOSITION_ATTACHED_PIC) != 0;
          if (attachPic) {
            _attachedPicStream = stream;
          } else {
            _videoStream = stream;
          }
        }
        if (type == .AVMEDIA_TYPE_AUDIO) {
          _audioStream = stream;
        }
        if (type == .AVMEDIA_TYPE_SUBTITLE) {
          _subtitleStream = stream;
        }
      }
      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Result<bool, String> loadInfo();

  void close() {
    if (_fmtCtx != nullptr) {
      lib.avformat_close_input(_fmtCtx);
      calloc.free(_fmtCtx);
      _fmtCtx = nullptr;
    }
    _audioStream = nullptr;
    _videoStream = nullptr;
    _attachedPicStream = nullptr;
    _subtitleStream = nullptr;
  }

  double rationalToDouble(AVRational q) {
    if (q.den == 0) return 0.0;
    return q.num / q.den;
  }

  Duration streamDuration(Pointer<AVStream> stream) {
    final duration = stream.ref.duration;
    final timeBase = stream.ref.time_base;

    if (duration == AV_NOPTS_VALUE || timeBase.den == 0) {
      return Duration.zero;
    }

    final seconds = duration * timeBase.num / timeBase.den;

    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }

  String _codecName(AVCodecID codecId) {
    final name = lib.avcodec_get_name(codecId);

    if (name == nullptr) {
      return 'unknown';
    }

    return name.cast<Utf8>().toDartString();
  }

  String? getMetadata(Pointer<AVDictionary> metadata, String key) {
    if (metadata == nullptr) {
      return null;
    }

    final keyPtr = key.toNativeUtf8();
    final entry = lib.av_dict_get(metadata, keyPtr.cast<Char>(), nullptr, 0);
    malloc.free(keyPtr);
    if (entry == nullptr) {
      return null;
    }
    return entry.ref.value.cast<Utf8>().toDartString();
  }
}
