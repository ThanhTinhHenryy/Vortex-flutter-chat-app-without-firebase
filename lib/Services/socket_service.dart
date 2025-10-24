import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'server_config.dart';

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  IO.Socket? _socket;
  int? _signedUserId;

  IO.Socket get socket {
    if (_socket == null) {
      _socket = IO.io(getServerBase(), {
        'transports': ['websocket'],
        'autoConnect': false,
      });
      _socket!.connect();
    }
    return _socket!;
  }

  Future<void> signin(int userId) async {
    // Tránh emit signin trùng lặp
    if (_signedUserId == userId && _socket?.connected == true) return;
    final s = socket;
    if (!s.connected) {
      s.onConnect((_) {
        s.emit('signin', userId);
      });
      s.connect();
    } else {
      s.emit('signin', userId);
    }
    _signedUserId = userId;
  }

  void on(String event, void Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      socket.off(event, handler);
    } else {
      socket.off(event);
    }
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }
}