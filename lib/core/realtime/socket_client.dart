import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/env.dart';
import '../config/socket_events.dart';

class SocketClient {
  io.Socket? _socket;

  io.Socket get socket {
    final s = _socket;
    if (s == null) throw StateError('Socket not initialized');
    return s;
  }

  Future<void> connect({required String accessToken}) async {
    // force websocket to avoid polling issues
    _socket = io.io(
      Env.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    final s = socket;
    final ready = Completer<void>();

    s.onConnect((_) {
      s.emitWithAck(
        SocketEvents.authJoin,
        {'token': accessToken},
        ack: (data) {
          final ok = data is Map && data['ok'] == true;
          if (ok) {
            ready.complete();
          } else {
            ready.completeError(StateError('Socket auth failed: $data'));
          }
        },
      );
    });

    s.on(SocketEvents.error, (e) {
      // optional: log
    });

    s.connect();
    return ready.future.timeout(const Duration(seconds: 10));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
