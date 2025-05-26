// ignore_for_file: avoid_print

import 'dart:async';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _locationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  void connect(String userId) {
    _socket = IO.io('https://socket.tusitio.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('Conectado al socket');
      _socket!.emit('join', {'userId': userId});
    });

    _socket!.on('location_update', (data) {
      _locationController.add(data);
    });

    _socket!.on('disconnect', (_) {
      print('Desconectado del socket');
    });
  }

  void sendLocation(double lat, double lng) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('location', {
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _locationController.close();
    disconnect();
  }
}
