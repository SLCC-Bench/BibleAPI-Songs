import 'package:mysql_client/mysql_client.dart';

import '../config/tidb_config.dart';

class TidbClient {
  MySQLConnection? _conn;
  TidbConfig? _config;

  bool get isConnected => _conn != null && _config != null;

  TidbConfig? get config => _config;

  Future<void> connect(TidbConfig config) async {
    await close();
    final conn = await MySQLConnection.createConnection(
      host: config.host.trim(),
      port: config.port,
      userName: config.user.trim(),
      password: config.password,
      databaseName: config.database.trim(),
      secure: true,
    );
    await conn.connect();
    _conn = conn;
    _config = config;
  }

  Future<void> ping() async {
    final conn = _requireConn();
    await conn.execute('SELECT 1');
  }

  Future<IResultSet> execute(
    String query, [
    Map<String, dynamic>? params,
  ]) {
    return _requireConn().execute(query, params);
  }

  MySQLConnection _requireConn() {
    final conn = _conn;
    if (conn == null) {
      throw StateError('Not connected to TiDB. Configure connection first.');
    }
    return conn;
  }

  Future<void> close() async {
    final conn = _conn;
    _conn = null;
    _config = null;
    if (conn != null) {
      try {
        await conn.close();
      } catch (_) {
        // Ignore close errors from already-closed sockets.
      }
    }
  }
}
