import 'package:flutter/material.dart';

import 'config/tidb_config.dart';
import 'db/songs_repository.dart';
import 'db/tidb_client.dart';
import 'screens/connection_screen.dart';
import 'screens/songs_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BibleApiSongsApp());
}

class BibleApiSongsApp extends StatelessWidget {
  const BibleApiSongsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibleAPI Songs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _store = TidbConfigStore();
  final _client = TidbClient();

  TidbConfig? _config;
  bool _booting = true;
  bool _connected = false;
  bool _showConnection = false;

  SongsRepository get _repo => SongsRepository(_client);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final config = await _store.load();
    var connected = false;
    if (config.isComplete) {
      try {
        await _client.connect(config);
        await _client.ping();
        connected = true;
      } catch (_) {
        connected = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _config = config;
      _connected = connected;
      _showConnection = !connected;
      _booting = false;
    });
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting || _config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showConnection || !_connected) {
      return ConnectionScreen(
        client: _client,
        store: _store,
        initialConfig: _config!,
        onConnected: () async {
          final config = await _store.load();
          if (!mounted) return;
          setState(() {
            _config = config;
            _connected = true;
            _showConnection = false;
          });
        },
      );
    }

    return SongsListScreen(
      repository: _repo,
      onOpenConnection: () {
        setState(() => _showConnection = true);
      },
    );
  }
}
