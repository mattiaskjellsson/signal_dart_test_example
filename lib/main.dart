import 'package:socket_io_client/socket_io_client.dart';

import 'helpers/get_names.dart';
import 'workers/communication.dart';
import 'key_server/key_api.dart';
import 'helpers/names_holder.dart';
import 'workers/server_communication.dart';

Future<void> main() async {
  try {
    final Communication stuff = ServerConnection(
        keyApi: KeyApi(serverUrl: 'http://localhost:3000/'),
        socket: io('http://localhost:3002/', <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        }));
    final NamesHolder holder = GetNames()();

    stuff.start(alice: holder.alicesName, bob: holder.bobsName);
  } on Exception {
    print('ops');
  }
}
