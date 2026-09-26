// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'av_format.dart';

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
    bool infoLog = false,
  }) {
    final outData = calloc<Pointer<Uint8>>();
    final outWidth = calloc<Int>();
    final outHeight = calloc<Int>();
    final outSize = calloc<Int>();

    try {
      final result = lib.than_decode_thumbnail_rgba(
        context,
        position.inMicroseconds,
        targetWidth,
        targetHeight,
        outData,
        outWidth,
        outHeight,
        outSize,
        infoLog ? 1 : 0,
      );

      if (result < 0) {
        final error = lib
            .than_media_tag_error(result)
            .cast<Utf8>()
            .toDartString();

        return Err('[thumb error] code=$result error=$error');
      }

      final data = outData.value;

      if (data == nullptr || outSize.value <= 0) {
        return Err('Thumbnail data is empty');
      }

      final rgba = Uint8List.fromList(data.asTypedList(outSize.value));

      lib.than_free_bytes(data);

      final image = img.Image.fromBytes(
        width: outWidth.value,
        height: outHeight.value,
        bytes: rgba.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      Uint8List encoded;

      switch (type) {
        case ImageType.jpg:
          encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));

        case ImageType.png:
          encoded = Uint8List.fromList(img.encodePng(image));

        case ImageType.webp:
          encoded = Uint8List.fromList(img.encodeWebP(image));
      }

      return Ok(encoded);
    } finally {
      calloc.free(outData);
      calloc.free(outWidth);
      calloc.free(outHeight);
      calloc.free(outSize);
    }
  }
}
