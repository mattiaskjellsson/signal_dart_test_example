import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart';

class SocketClient {
  final Socket _socket;
  final Function(dynamic) _receiveHandler;

  SocketClient(
      {required Function(dynamic) receiveHandler, required Socket socket})
      : _receiveHandler = receiveHandler,
        _socket = socket;

  void connect() async {
    try {
      _socket.on('connect', (_) => {print('connect: ${_socket.id}')});
      _socket.on('message', _receiveHandler);
      _socket.on('disconnect', (_) => print('disconnect'));
      _socket.on('fromServer', (_) => print(_));
      _socket.connect();
    } catch (e) {
      print('Ops, something happened :(');
      print(e.toString());
    }
  }

  void sendMessage({required String text}) {
    final m = {
      "id": _socket.id,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      'message': text,
    };

    _socket.emit('message', json.encode(m));
  }
}
