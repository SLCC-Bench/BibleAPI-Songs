class LyricSection {
  final int? id;
  final String songPart;
  final String lyrics;

  const LyricSection({
    this.id,
    this.songPart = '',
    this.lyrics = '',
  });

  LyricSection copyWith({
    int? id,
    String? songPart,
    String? lyrics,
  }) {
    return LyricSection(
      id: id ?? this.id,
      songPart: songPart ?? this.songPart,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  Map<String, dynamic> toMap() => {
        'songPart': songPart,
        'lyrics': lyrics,
      };
}

class Song {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final List<LyricSection> lyrics;

  const Song({
    this.id,
    required this.title,
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.lyrics = const [],
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    List<LyricSection>? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
    );
  }
}
