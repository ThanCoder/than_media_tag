// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:than_media_tag/core/av_format.dart';

abstract class MediaStreamInfo {
  final int codecId;
  final String codecName;
  final Duration duration;
  final int bitrate;
  final int format;
  final int streamDuration;
  const MediaStreamInfo({
    required this.codecId,
    required this.duration,
    required this.bitrate,
    required this.format,
    required this.streamDuration,
    required this.codecName,
  });

  String get bitrateLabel {
    if (bitrate <= 0) return '';
    final kbps = bitrate / 1000;
    return '${kbps.round()} kb/s';
  }

  @override
  String toString() {
    return 'MediaStreamInfo(codecId: $codecId, codecName: $codecName, duration: $duration, bitrate: $bitrate, format: $format, streamDuration: $streamDuration)';
  }
}

class AudioStreamInfo extends MediaStreamInfo {
  final int sampleRate;
  final int channels;
  final AudioTag tag;

  new({
    required super.codecId,
    required super.duration,
    required super.bitrate,
    required super.format,
    required this.sampleRate,
    required this.channels,
    required super.streamDuration,
    required super.codecName,
    required this.tag,
  });

  String get sampleRateLabel {
    if (sampleRate <= 0) return '';
    final khz = sampleRate / 1000;
    return '${khz.toStringAsFixed(khz % 1 == 0 ? 0 : 1)} kHz';
  }
}

class VideoStreamInfo extends MediaStreamInfo {
  final int width;
  final int height;
  final double fps;

  new({
    required super.codecId,
    required super.duration,
    required super.bitrate,
    required super.format,
    required this.width,
    required this.height,
    required this.fps,
    required super.streamDuration,
    required super.codecName,
  });
}

class SubtitleStreamInfo extends MediaStreamInfo {
  final String? language;

  new({
    required super.codecId,
    required super.duration,
    required super.bitrate,
    required super.format,
    required super.streamDuration,
    required super.codecName,
    required this.language,
  });
}
