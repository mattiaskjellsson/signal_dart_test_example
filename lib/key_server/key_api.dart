import 'dart:convert';
import 'package:http/http.dart' as http;

import 'key_object.dart';

class KeyApi {
  final String serverUrl;
  KeyApi({required this.serverUrl});

  Future<KeyObject> fetchKey(String name) async {
    final response = await http.get(Uri.parse(serverUrl + name));

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final o = KeyObject.fromJson(jsonDecode(response.body));
      print('Response when fetching $name\'s keys');
      print('$name\'s deveicId ${o.deviceId}');
      print('$name\'s identityKeyPair ${o.identityKeyPair}');
      print('$name\'s preKey ${o.preKey}');
      print('$name\'s preKeyId ${o.preKeyId}');
      print('$name\'s registrationId ${o.registrationId}');
      print('$name\'s signedPreKey ${o.signedPreKey}');
      print('$name\'s signedPreKey ${o.signedPreKeyId}');
      print('$name\'s username ${o.username}');
      print('$name\'s timestamp ${o.timestamp}');
      print('$name\'s signedPreKeySignature ${o.signedPreKeySignature}');
      print('==========================================================');
      return o;
    } else {
      throw Exception('Failed to fetch $name\'s Key');
    }
  }

  Future<void> storeKey(KeyObject ko) async {
    final send = jsonEncode(ko.toJson());
    final send2 = '{"keys":' + send + '}';
    final response = await http.post(Uri.parse(serverUrl + ko.username),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: send2);

    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Something dumb happened');
    }
  }
}
