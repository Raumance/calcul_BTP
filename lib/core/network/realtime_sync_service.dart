import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Canal WebSocket pour synchronisation temps réel multi-appareils.
///
/// Protocole :
/// - Client → Server : `{ "type": "ping" | "subscribe" | "entity_changed", ... }`
/// - Server → Client : `{ "type": "pong" | "entity_update" | "conflict", ... }`
class RealtimeSyncService {
  RealtimeSyncService({
    required this.wsBaseUrl,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String wsBaseUrl;
  final FlutterSecureStorage _storage;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _heartbeat;
  bool _disposed = false;

  Stream<Map<String, dynamic>> get messages {
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();
    return _controller!.stream;
  }

  bool get isConnected => _channel != null;

  Future<void> connect({String? projetId}) async {
    await disconnect();
    _disposed = false;
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final uri = Uri.parse(
      '$wsBaseUrl/ws/sync/${projetId ?? "all"}/?token=$token',
    );
    _channel = WebSocketChannel.connect(uri);
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();

    _channel!.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller?.add(data);
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onError: (_) => _scheduleReconnect(projetId: projetId),
      onDone: () => _scheduleReconnect(projetId: projetId),
      cancelOnError: false,
    );

    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });

    if (projetId != null) {
      send({'type': 'subscribe', 'projet_id': projetId});
    }
  }

  void send(Map<String, dynamic> payload) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(payload));
    } catch (_) {
      // Canal fermé — reconnect géré par onDone.
    }
  }

  /// Diffuse une modification d'entité aux autres appareils connectés.
  void broadcastEntityChange({
    required String entiteType,
    required String entiteId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    send({
      'type': 'entity_changed',
      'entite_type': entiteType,
      'entite_id': entiteId,
      'operation': operation,
      'payload': payload,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> disconnect() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _controller?.close();
    _controller = null;
  }

  void _scheduleReconnect({String? projetId}) {
    if (_disposed) return;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!_disposed) connect(projetId: projetId);
    });
  }
}
