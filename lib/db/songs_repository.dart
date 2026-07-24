import '../models/song.dart';
import 'tidb_client.dart';

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  return int.tryParse('$value');
}

String _asString(dynamic value) => value == null ? '' : '$value';

class SongsRepository {
  final TidbClient client;

  SongsRepository(this.client);

  Future<List<Song>> listSongs() async {
    final result = await client.execute(
      'SELECT id, title, artist, album, genre FROM SongDetails ORDER BY title',
    );
    return result.rows
        .map(
          (row) => Song(
            id: _asInt(row.colByName('id')),
            title: _asString(row.colByName('title')),
            artist: _asString(row.colByName('artist')),
            album: _asString(row.colByName('album')),
            genre: _asString(row.colByName('genre')),
          ),
        )
        .where((s) => s.id != null)
        .toList();
  }

  Future<Song> getSong(int songId) async {
    final songResult = await client.execute(
      'SELECT id, title, artist, album, genre FROM SongDetails WHERE id = :id',
      {'id': songId},
    );
    if (songResult.rows.isEmpty) {
      throw StateError('Song not found.');
    }
    final row = songResult.rows.first;
    final lyricsResult = await client.execute(
      'SELECT id, songPart, lyrics FROM SongLyrics WHERE songId = :id ORDER BY id',
      {'id': songId},
    );
    final lyrics = lyricsResult.rows
        .map(
          (lyric) => LyricSection(
            id: _asInt(lyric.colByName('id')),
            songPart: _asString(lyric.colByName('songPart')),
            lyrics: _asString(lyric.colByName('lyrics')),
          ),
        )
        .toList();

    return Song(
      id: _asInt(row.colByName('id')),
      title: _asString(row.colByName('title')),
      artist: _asString(row.colByName('artist')),
      album: _asString(row.colByName('album')),
      genre: _asString(row.colByName('genre')),
      lyrics: lyrics,
    );
  }

  Future<int> createSong(Song song) async {
    final title = song.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Title is required.');
    }

    final insert = await client.execute(
      '''
      INSERT INTO SongDetails (title, artist, album, genre)
      VALUES (:title, :artist, :album, :genre)
      ''',
      {
        'title': title,
        'artist': song.artist.trim(),
        'album': song.album.trim(),
        'genre': song.genre.trim(),
      },
    );

    final songId = insert.lastInsertID.toInt();
    await _insertLyrics(songId, song.lyrics);
    return songId;
  }

  Future<void> updateSong(Song song) async {
    final songId = song.id;
    if (songId == null) {
      throw ArgumentError('Song id is required for update.');
    }
    final title = song.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Title is required.');
    }

    await client.execute(
      '''
      UPDATE SongDetails
      SET title = :title, artist = :artist, album = :album, genre = :genre
      WHERE id = :id
      ''',
      {
        'title': title,
        'artist': song.artist.trim(),
        'album': song.album.trim(),
        'genre': song.genre.trim(),
        'id': songId,
      },
    );

    await client.execute(
      'DELETE FROM SongLyrics WHERE songId = :id',
      {'id': songId},
    );
    await _insertLyrics(songId, song.lyrics);
  }

  Future<void> deleteSong(int songId) async {
    final existing = await client.execute(
      'SELECT id FROM SongDetails WHERE id = :id',
      {'id': songId},
    );
    if (existing.rows.isEmpty) {
      throw StateError('Song not found.');
    }
    await client.execute(
      'DELETE FROM SongDetails WHERE id = :id',
      {'id': songId},
    );
  }

  Future<void> _insertLyrics(int songId, List<LyricSection> lyrics) async {
    for (final lyric in lyrics) {
      await client.execute(
        '''
        INSERT INTO SongLyrics (songId, songPart, lyrics)
        VALUES (:songId, :songPart, :lyrics)
        ''',
        {
          'songId': songId,
          'songPart': lyric.songPart,
          'lyrics': lyric.lyrics,
        },
      );
    }
  }
}
