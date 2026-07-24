import 'package:flutter/material.dart';

import '../db/songs_repository.dart';
import '../models/song.dart';

class SongEditorScreen extends StatefulWidget {
  final SongsRepository repository;
  final int? songId;

  const SongEditorScreen({
    super.key,
    required this.repository,
    this.songId,
  });

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _album = TextEditingController();
  final _genre = TextEditingController();

  final List<_SectionControllers> _sections = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.songId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadSong();
    } else {
      _addSection();
    }
  }

  Future<void> _loadSong() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final song = await widget.repository.getSong(widget.songId!);
      _title.text = song.title;
      _artist.text = song.artist;
      _album.text = song.album;
      _genre.text = song.genre;
      for (final s in _sections) {
        s.dispose();
      }
      _sections
        ..clear()
        ..addAll(
          song.lyrics.map(
            (l) => _SectionControllers(
              part: TextEditingController(text: l.songPart),
              lyrics: TextEditingController(text: l.lyrics),
            ),
          ),
        );
      if (_sections.isEmpty) {
        _addSection();
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(
        _SectionControllers(
          part: TextEditingController(text: 'Verse'),
          lyrics: TextEditingController(),
        ),
      );
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song title is required.')),
      );
      return;
    }

    final song = Song(
      id: widget.songId,
      title: title,
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      genre: _genre.text.trim(),
      lyrics: _sections
          .map(
            (s) => LyricSection(
              songPart: s.part.text.trim(),
              lyrics: s.lyrics.text,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await widget.repository.updateSong(song);
      } else {
        await widget.repository.createSong(song);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit song' : 'Add song'),
        actions: [
          TextButton(
            onPressed: _loading || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadSong,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _artist,
                      decoration: const InputDecoration(
                        labelText: 'Artist',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _album,
                      decoration: const InputDecoration(
                        labelText: 'Album',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _genre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Lyric sections',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _saving ? null : _addSection,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _sections.length; i++) ...[
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _sections[i].part,
                                      decoration: const InputDecoration(
                                        labelText: 'Part (Verse, Chorus, …)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove section',
                                    onPressed: _saving || _sections.length <= 1
                                        ? null
                                        : () => _removeSection(i),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _sections[i].lyrics,
                                decoration: const InputDecoration(
                                  labelText: 'Lyrics',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                minLines: 4,
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_isEdit ? 'Update song' : 'Create song'),
                    ),
                  ],
                ),
    );
  }
}

class _SectionControllers {
  final TextEditingController part;
  final TextEditingController lyrics;

  _SectionControllers({required this.part, required this.lyrics});

  void dispose() {
    part.dispose();
    lyrics.dispose();
  }
}
