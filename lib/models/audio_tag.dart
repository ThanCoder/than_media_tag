part of '../core/av_format.dart';

class AudioTag {
  const AudioTag({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.comment = '',
    this.year = '',
    required this._attachedPicStream,
  });
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String comment;
  final String year;
  final Pointer<AVStream> _attachedPicStream;

  @override
  String toString() {
    return 'AudioTag(title: $title, artist: $artist, album: $album, genre: $genre, comment: $comment, year: $year)';
  }

  bool get attachedPictureExists =>
      _attachedPicStream == nullptr ? false : true;

  Uint8List? get readAttachedPicture {
    if (_attachedPicStream == nullptr) return null;
    final packet = _attachedPicStream.ref.attached_pic;

    if (packet.data == nullptr || packet.size <= 0) {
      return null;
    }

    return Uint8List.fromList(packet.data.asTypedList(packet.size));
  }

  Result<bool, String> attachedPictureAsFile(String outpath) {
    try {
      if (!attachedPictureExists) {
        return Ok(false);
      }
      final bytes = readAttachedPicture;
      if (bytes == null) {
        return Ok(false);
      }
      final f = File(outpath);
      f.writeAsBytesSync(bytes);
      return Ok(true);
    } catch (e) {
      return Err(e.toString());
    }
  }
}
