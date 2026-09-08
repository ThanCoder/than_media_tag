// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'av_format.dart';

const avErrorAgain = -11;
const swsBilinear = 1;

enum ImageType { jpg, png, webp }

class AvDecoder {
  final AvFormatBase _avFormat;

  AvDecoder(this._avFormat);

  late final Pointer<Pointer<AVFormatContext>> _fmtCtx = _avFormat._fmtCtx;

  Pointer<AVFormatContext> get context => _fmtCtx.value;

  Result<Uint8List, String> genThumbnail({
    Duration position = const Duration(seconds: 5),
    int targetWidth = 0,
    int targetHeight = 0,
    ImageType type = .jpg,
    int quality = 90,
  }) {
    final stream = findVideoStream();

    if (stream == null) {
      return Err('video stream not found');
    }

    final codecCtx = openVideoDecoder(stream);

    if (codecCtx == null) {
      return Err('failed to open video decoder');
    }

    final packet = lib.av_packet_alloc();

    if (packet == nullptr) {
      freeCodecContext(codecCtx);
      return Err('failed to allocate packet');
    }

    final frame = lib.av_frame_alloc();

    if (frame == nullptr) {
      freePacket(packet);
      freeCodecContext(codecCtx);
      return Err('failed to allocate frame');
    }

    try {
      final streamIndex = stream.ref.index;
      final timeBase = stream.ref.time_base;

      final timestamp =
          (position.inMicroseconds *
                  timeBase.den /
                  (Duration.microsecondsPerSecond * timeBase.num))
              .round();

      //
      // Seek to the nearest keyframe before the requested position.
      //
      var ret = lib.av_seek_frame(
        context,
        streamIndex,
        timestamp,
        AVSEEK_FLAG_BACKWARD,
      );

      if (ret < 0) {
        return Err('seek failed: $ret');
      }

      //
      // Flush decoder after seeking.
      //
      lib.avcodec_flush_buffers(codecCtx);

      while ((ret = lib.av_read_frame(context, packet)) >= 0) {
        //
        // Ignore packets from other streams.
        //
        if (packet.ref.stream_index != streamIndex) {
          lib.av_packet_unref(packet);
          continue;
        }

        //
        // Send packet to decoder.
        //
        ret = lib.avcodec_send_packet(codecCtx, packet);

        //
        // Packet is no longer needed.
        //
        lib.av_packet_unref(packet);

        if (ret < 0) {
          continue;
        }

        //
        // One packet can produce multiple frames.
        //
        while (true) {
          ret = lib.avcodec_receive_frame(codecCtx, frame);

          if (ret == avErrorAgain) {
            break;
          }

          if (ret == AVERROR_EOF) {
            return Err('decoder reached EOF');
          }

          if (ret < 0) {
            return Err('decode failed: $ret');
          }

          final frameWidth = frame.ref.width;
          final frameHeight = frame.ref.height;

          if (frameWidth <= 0 || frameHeight <= 0) {
            return Err(
              'invalid frame size: '
              '${frameWidth}x$frameHeight',
            );
          }

          //
          // AVFrame -> RGBA.
          //
          final rgba = frameToRgba(
            frame,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
          );

          if (rgba.isErr) {
            return Err(rgba.unwrapError());
          }

          final rgbaBytes = rgba.unwrap();

          //
          // Actual output dimensions.
          //
          final outputSize = calculateOutputSize(
            frameWidth,
            frameHeight,
            targetWidth,
            targetHeight,
          );

          final image = img.Image.fromBytes(
            width: outputSize.width,
            height: outputSize.height,
            bytes: rgbaBytes.buffer,
            numChannels: 4,
          );

          final encoded = switch (type) {
            ImageType.jpg => img.encodeJpg(
              image,
              quality: quality.clamp(1, 100),
            ),
            ImageType.png => img.encodePng(image),
            ImageType.webp => img.encodeWebP(
              image,
              // quality: quality.clamp(1, 100),
            ),
          };

          return Ok(Uint8List.fromList(encoded));
        }
      }

      return Err('no frame found: $ret');
    } catch (e) {
      return Err(e.toString());
    } finally {
      freeFrame(frame);
      freePacket(packet);
      freeCodecContext(codecCtx);
    }
  }

  Result<Uint8List, String> frameToRgba(
    Pointer<AVFrame> frame, {
    int targetWidth = 0,
    int targetHeight = 0,
  }) {
    final srcWidth = frame.ref.width;
    final srcHeight = frame.ref.height;

    if (srcWidth <= 0 || srcHeight <= 0) {
      return Err('invalid frame size: ${srcWidth}x$srcHeight');
    }

    final outputSize = calculateOutputSize(
      srcWidth,
      srcHeight,
      targetWidth,
      targetHeight,
    );

    final dstWidth = outputSize.width;
    final dstHeight = outputSize.height;

    final srcFormat = frame.ref.format;

    final swsCtx = lib.sws_getContext(
      srcWidth,
      srcHeight,
      AVPixelFormat.fromValue(srcFormat),
      dstWidth,
      dstHeight,
      AVPixelFormat.AV_PIX_FMT_RGBA,
      swsBilinear,
      nullptr,
      nullptr,
      nullptr,
    );

    if (swsCtx == nullptr) {
      return Err('failed to create swscale context');
    }

    final bufferSize = dstWidth * dstHeight * 4;
    final buffer = calloc<Uint8>(bufferSize);

    //
    // Temporary native arrays.
    //
    final srcData = calloc<Pointer<Uint8>>(8);
    final srcLinesize = calloc<Int>(8);

    final dstData = calloc<Pointer<Uint8>>(4);
    final dstLinesize = calloc<Int>(4);

    try {
      //
      // AVFrame.data -> native pointer array
      //
      for (var i = 0; i < 8; i++) {
        srcData[i] = frame.ref.data.elements[i];
        srcLinesize[i] = frame.ref.linesize.elements[i];
      }

      //
      // RGBA destination.
      //
      dstData[0] = buffer;
      dstLinesize[0] = dstWidth * 4;

      final scaledHeight = lib.sws_scale(
        swsCtx,
        srcData,
        srcLinesize,
        0,
        srcHeight,
        dstData,
        dstLinesize,
      );

      if (scaledHeight != dstHeight) {
        return Err(
          'sws_scale failed: '
          '$scaledHeight != $dstHeight',
        );
      }

      //
      // Copy native buffer to Dart memory.
      //
      return Ok(Uint8List.fromList(buffer.asTypedList(bufferSize)));
    } catch (e) {
      return Err('frame conversion failed: $e');
    } finally {
      calloc.free(dstLinesize);
      calloc.free(dstData);
      calloc.free(srcLinesize);
      calloc.free(srcData);
      calloc.free(buffer);

      lib.sws_freeContext(swsCtx);
    }
  }

  ({int width, int height}) calculateOutputSize(
    int sourceWidth,
    int sourceHeight,
    int targetWidth,
    int targetHeight,
  ) {
    //
    // Keep original size.
    //
    if (targetWidth <= 0 && targetHeight <= 0) {
      return (width: sourceWidth, height: sourceHeight);
    }

    //
    // Width only -> calculate height.
    //
    if (targetWidth > 0 && targetHeight <= 0) {
      final height = (sourceHeight * targetWidth / sourceWidth).round();

      return (width: targetWidth, height: height.clamp(1, 1 << 30));
    }

    //
    // Height only -> calculate width.
    //
    if (targetWidth <= 0 && targetHeight > 0) {
      final width = (sourceWidth * targetHeight / sourceHeight).round();

      return (width: width.clamp(1, 1 << 30), height: targetHeight);
    }

    //
    // Both specified.
    //
    return (width: targetWidth, height: targetHeight);
  }

  Pointer<AVStream>? findVideoStream() {
    final ctx = context;

    final streams = ctx.ref.streams;
    final count = ctx.ref.nb_streams;

    for (var i = 0; i < count; i++) {
      final stream = streams[i];

      final codecpar = stream.ref.codecpar;

      if (codecpar.ref.codec_type != .AVMEDIA_TYPE_VIDEO) {
        continue;
      }

      //
      // Do not use an embedded cover image as the video stream.
      //
      final isAttachedPic =
          (stream.ref.disposition & AV_DISPOSITION_ATTACHED_PIC) != 0;

      if (isAttachedPic) {
        continue;
      }

      return stream;
    }

    return null;
  }

  Pointer<AVCodecContext>? openVideoDecoder(Pointer<AVStream> stream) {
    final codecId = stream.ref.codecpar.ref.codec_id;

    final codec = lib.avcodec_find_decoder(codecId);

    if (codec == nullptr) {
      return null;
    }

    final codecCtx = lib.avcodec_alloc_context3(codec);

    if (codecCtx == nullptr) {
      return null;
    }

    final ret = lib.avcodec_parameters_to_context(
      codecCtx,
      stream.ref.codecpar,
    );

    if (ret < 0) {
      freeCodecContext(codecCtx);
      return null;
    }

    final openRet = lib.avcodec_open2(codecCtx, codec, nullptr);

    if (openRet < 0) {
      freeCodecContext(codecCtx);
      return null;
    }

    return codecCtx;
  }

  void freePacket(Pointer<AVPacket> packet) {
    final ptr = calloc<Pointer<AVPacket>>();

    try {
      ptr.value = packet;
      lib.av_packet_free(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  void freeFrame(Pointer<AVFrame> frame) {
    final ptr = calloc<Pointer<AVFrame>>();

    try {
      ptr.value = frame;
      lib.av_frame_free(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  void freeCodecContext(Pointer<AVCodecContext> codecCtx) {
    final ptr = calloc<Pointer<AVCodecContext>>();

    try {
      ptr.value = codecCtx;
      lib.avcodec_free_context(ptr);
    } finally {
      calloc.free(ptr);
    }
  }
}
