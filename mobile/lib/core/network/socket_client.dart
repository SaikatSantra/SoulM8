import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class SocketClient {
  static IO.Socket? _socket;
  static final List<void Function(IO.Socket)> _connectListeners = [];

  static IO.Socket? get socket => _socket;

  static void addConnectListener(void Function(IO.Socket) listener) {
    if (_socket != null && _socket!.connected) {
      listener(_socket!);
    } else {
      _connectListeners.add(listener);
    }
  }

  static Future<void> connect() async {
    final token = await SecureStorageService.getToken();
    if (token == null) return;

    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setQuery({'token': token})
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🔌 Socket connected successfully');
      for (final listener in _connectListeners) {
        try {
          listener(_socket!);
        } catch (e) {
          debugPrint('⚠️ Error in socket listener: $e');
        }
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 Socket disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('🔌 Socket connect error: $err');
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
