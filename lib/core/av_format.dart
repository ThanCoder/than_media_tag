import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:than_media_tag/core/result_t.dart';
import 'package:than_media_tag/models/media_info.dart';
import 'package:than_media_tag/than_media_tag.dart';
import 'package:than_media_tag/than_media_tag_bindings_generated.dart';
import 'package:image/image.dart' as img;

part 'av_format_base.dart';
part 'av_decoder.dart';
part 'audio_pic_logic.dart';
part '../models/audio_tag.dart';

final lib = getMediaReader();

class AvFormat extends AvFormatBase with AudioPicLogic {
  /// video decoder
  AvDecoder get toDecoder {
    return .new(this);
  }

  @override
  Result<bool, String> loadInfo() {
    try {
      if (_audioStream != nullptr) {
        final codecpar = _audioStream.ref.codecpar;
        final strDuration = _audioStream.ref.duration;
        final codecNameValue = _codecName(codecpar.ref.codec_id);
        final duration = streamDuration(_audioStream);

        infoList.add(
          AudioStreamInfo(
            codecId: codecpar.ref.codec_id.value,
            codecName: codecNameValue,
            duration: duration,
            streamDuration: strDuration,
            bitrate: codecpar.ref.bit_rate,
            format: codecpar.ref.format,
            sampleRate: codecpar.ref.sample_rate,
            channels: codecpar.ref.ch_layout.nb_channels,
            tag: _readTag(),
          ),
        );
      }
      if (_videoStream != nullptr) {
        final codecpar = _videoStream.ref.codecpar;
        final strDuration = _videoStream.ref.duration;
        final codecNameValue = _codecName(codecpar.ref.codec_id);
        final duration = streamDuration(_videoStream);
        final width = codecpar.ref.width;
        final height = codecpar.ref.height;

        final fps = rationalToDouble(_videoStream.ref.avg_frame_rate);

        infoList.add(
          VideoStreamInfo(
            codecName: codecNameValue,
            codecId: codecpar.ref.codec_id.value,
            duration: duration,
            streamDuration: strDuration,
            bitrate: codecpar.ref.bit_rate,
            format: codecpar.ref.format,
            width: width,
            height: height,
            fps: fps,
          ),
        );
      }
      if (_subtitleStream != nullptr) {
        final codecpar = _subtitleStream.ref.codecpar;
        final strDuration = _subtitleStream.ref.duration;
        final codecNameValue = _codecName(codecpar.ref.codec_id);
        final duration = streamDuration(_subtitleStream);
        final language = getMetadata(_subtitleStream.ref.metadata, 'language');
        infoList.add(
          SubtitleStreamInfo(
            codecId: codecpar.ref.codec_id.value,
            codecName: codecNameValue,
            duration: duration,
            streamDuration: strDuration,
            bitrate: codecpar.ref.bit_rate,
            format: codecpar.ref.format,
            language: language,
          ),
        );
      }

      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }

  AudioTag _readTag() {
    final metadata = context.ref.metadata;

    return AudioTag(
      title: getMetadata(metadata, 'title') ?? '',
      artist: getMetadata(metadata, 'artist') ?? '',
      album: getMetadata(metadata, 'album') ?? '',
      genre: getMetadata(metadata, 'genre') ?? '',
      comment: getMetadata(metadata, 'comment') ?? '',
      year: getMetadata(metadata, 'date') ?? '',
      attachedPicStream: _attachedPicStream,
    );
  }
}
