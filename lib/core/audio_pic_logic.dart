part of 'av_format.dart';

mixin AudioPicLogic on AvFormatBase {
  /// Audio Attached Picture Data
  Uint8List? get attachedPicBytes {
    if (_attachedPicStream == nullptr) {
      return null;
    }

    final packet = _attachedPicStream.ref.attached_pic;

    if (packet.data == nullptr || packet.size <= 0) {
      return null;
    }

    return Uint8List.fromList(packet.data.asTypedList(packet.size));
  }
}
