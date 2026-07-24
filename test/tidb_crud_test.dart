import 'dart:convert';
import 'dart:io';

import 'package:bibleapi_songs/config/tidb_config.dart';
import 'package:bibleapi_songs/db/songs_repository.dart';
import 'package:bibleapi_songs/db/tidb_client.dart';
import 'package:bibleapi_songs/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Songs CRUD against live TiDB', () async {
    final envPath = Platform.environment['TIDB_ENV_JSON'] ??
        '${Platform.environment['HOME']}/Library/Application Support/praisehub/bibleapi.env.json';
    final file = File(envPath);
    expect(file.existsSync(), isTrue, reason: 'Missing $envPath');

    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final config = TidbConfig(
      host: '${map['MYSQL_HOST']}',
      port: int.parse('${map['MYSQL_PORT'] ?? 4000}'),
      user: '${map['MYSQL_USER']}',
      password: '${map['MYSQL_PASSWORD']}',
      database: '${map['MYSQL_DB']}',
    );

    final client = TidbClient();
    final repo = SongsRepository(client);

    await client.connect(config);
    await client.ping();

    final listed = await repo.listSongs();
    expect(listed, isNotEmpty);

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final id = await repo.createSong(
      Song(
        title: 'APK Verify $stamp',
        artist: 'BibleAPI-Songs',
        album: 'Verify',
        genre: 'test',
        lyrics: const [
          LyricSection(songPart: 'Verse', lyrics: 'Line one\nLine two'),
          LyricSection(songPart: 'Chorus', lyrics: 'Chorus line'),
        ],
      ),
    );
    expect(id, greaterThan(0));

    final loaded = await repo.getSong(id);
    expect(loaded.lyrics, hasLength(2));

    await repo.updateSong(
      loaded.copyWith(title: 'APK Verify Updated $stamp', genre: 'updated'),
    );
    final updated = await repo.getSong(id);
    expect(updated.title, contains('Updated'));
    expect(updated.genre, 'updated');

    await repo.deleteSong(id);
    await expectLater(repo.getSong(id), throwsA(isA<StateError>()));
    await client.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
