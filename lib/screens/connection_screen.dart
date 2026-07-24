import 'package:flutter/material.dart';

import '../config/tidb_config.dart';
import '../db/tidb_client.dart';

class ConnectionScreen extends StatefulWidget {
  final TidbClient client;
  final TidbConfigStore store;
  final TidbConfig initialConfig;
  final VoidCallback onConnected;

  const ConnectionScreen({
    super.key,
    required this.client,
    required this.store,
    required this.initialConfig,
    required this.onConnected,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final TextEditingController _database;

  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig;
    _host = TextEditingController(text: c.host);
    _port = TextEditingController(text: c.port.toString());
    _user = TextEditingController(text: c.user);
    _password = TextEditingController(text: c.password);
    _database = TextEditingController(text: c.database);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _password.dispose();
    _database.dispose();
    super.dispose();
  }

  TidbConfig _readForm() {
    return TidbConfig(
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? 0,
      user: _user.text.trim(),
      password: _password.text,
      database: _database.text.trim(),
    );
  }

  Future<void> _testAndSave({required bool navigateOnSuccess}) async {
    final config = _readForm();
    if (!config.isComplete) {
      setState(() {
        _messageIsError = true;
        _message = 'Fill in host, port, user, password, and database.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await widget.client.connect(config);
      await widget.client.ping();
      await widget.store.save(config);
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message = 'Connected to TiDB.';
      });
      if (navigateOnSuccess) {
        widget.onConnected();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = 'Connection failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TiDB Connection'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Connect directly to your TiDB Cloud database. '
            'Credentials are stored securely on this device.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _host,
            decoration: const InputDecoration(
              labelText: 'Host',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            decoration: const InputDecoration(
              labelText: 'User',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            textInputAction: TextInputAction.next,
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _database,
            decoration: const InputDecoration(
              labelText: 'Database',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            enabled: !_busy,
            onSubmitted: (_) => _testAndSave(navigateOnSuccess: true),
          ),
          const SizedBox(height: 20),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _messageIsError
                      ? Theme.of(context).colorScheme.error
                      : Colors.green.shade700,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _testAndSave(navigateOnSuccess: false),
                  child: const Text('Test connection'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _testAndSave(navigateOnSuccess: true),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
