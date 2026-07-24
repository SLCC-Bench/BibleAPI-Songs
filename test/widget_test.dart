import 'package:flutter_test/flutter_test.dart';

import 'package:bibleapi_songs/models/song.dart';

void main() {
  test('Song copyWith preserves fields', () {
    const song = Song(title: 'Above All', artist: 'Michael W. Smith');
    final updated = song.copyWith(album: 'Worship');
    expect(updated.title, 'Above All');
    expect(updated.artist, 'Michael W. Smith');
    expect(updated.album, 'Worship');
  });
}
