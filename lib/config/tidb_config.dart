import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TidbConfig {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  const TidbConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  static const defaults = TidbConfig(
    host: 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com',
    port: 4000,
    user: '',
    password: '',
    database: 'test',
  );

  bool get isComplete =>
      host.trim().isNotEmpty &&
      user.trim().isNotEmpty &&
      password.isNotEmpty &&
      database.trim().isNotEmpty &&
      port > 0;

  TidbConfig copyWith({
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
  }) {
    return TidbConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
    );
  }
}

class TidbConfigStore {
  static const _hostKey = 'mysql_host';
  static const _portKey = 'mysql_port';
  static const _userKey = 'mysql_user';
  static const _passwordKey = 'mysql_password';
  static const _databaseKey = 'mysql_db';

  final FlutterSecureStorage _storage;

  TidbConfigStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  Future<TidbConfig> load() async {
    final host = await _storage.read(key: _hostKey);
    final portStr = await _storage.read(key: _portKey);
    final user = await _storage.read(key: _userKey);
    final password = await _storage.read(key: _passwordKey);
    final database = await _storage.read(key: _databaseKey);

    if (host == null &&
        portStr == null &&
        user == null &&
        password == null &&
        database == null) {
      return TidbConfig.defaults;
    }

    return TidbConfig(
      host: host ?? TidbConfig.defaults.host,
      port: int.tryParse(portStr ?? '') ?? TidbConfig.defaults.port,
      user: user ?? '',
      password: password ?? '',
      database: database ?? TidbConfig.defaults.database,
    );
  }

  Future<void> save(TidbConfig config) async {
    await _storage.write(key: _hostKey, value: config.host.trim());
    await _storage.write(key: _portKey, value: config.port.toString());
    await _storage.write(key: _userKey, value: config.user.trim());
    await _storage.write(key: _passwordKey, value: config.password);
    await _storage.write(key: _databaseKey, value: config.database.trim());
  }

  Future<void> clear() async {
    await _storage.delete(key: _hostKey);
    await _storage.delete(key: _portKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _databaseKey);
  }
}
