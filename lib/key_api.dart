import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class KeyApi {
  final String serverUrl;

  KeyApi({required this.serverUrl});

  Future<KeyObject> fetchKey(String name) async {
    final response = await http.get(Uri.parse(serverUrl + name));

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final o = KeyObject.fromJson(jsonDecode(response.body));
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

class KeyObject {
  final String username;
  final Uint8List identityKeyPair;
  final int deviceId;
  final int preKeyId;
  final Uint8List preKey;
  final int signedPreKeyId;
  final Uint8List signedPreKey;
  final int registrationId;
  final Int64 timestamp;
  final Uint8List? signedPreKeySignature;

  KeyObject({
    required this.username,
    required this.identityKeyPair,
    required this.deviceId,
    required this.preKeyId,
    required this.preKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.registrationId,
    required this.timestamp,
    required this.signedPreKeySignature,
  });

  factory KeyObject.fromJson(Map<String, dynamic> data) {
    final f = json.decode(data['identityKeyPair']).cast<int>();
    Uint8List identityKeyPair = Uint8List.fromList(f);

    final g = json.decode(data['preKey']).cast<int>();
    Uint8List preKey = Uint8List.fromList(g);

    final h = json.decode(data['signedPreKey']).cast<int>();
    Uint8List signedPreKey = Uint8List.fromList(h);

    return KeyObject(
      username: data['username'],
      identityKeyPair: identityKeyPair,
      deviceId: int.parse(data['deviceId']),
      preKeyId: int.parse(data['preKeyId']),
      preKey: preKey,
      signedPreKeyId: int.parse(data['signedPreKeyId']),
      signedPreKey: signedPreKey,
      registrationId: int.parse(data['registrationId']),
      timestamp: Int64.parseInt(data['timestamp']),
      signedPreKeySignature: Uint8List.fromList(
          json.decode(data['signedPreKeySignature']).cast<int>()),
    );
  }

  Map<String, String> toJson() {
    return {
      'username': username.toString(),
      'identityKeyPair': identityKeyPair.toString(),
      'deviceId': deviceId.toString(),
      'preKeyId': preKeyId.toString(),
      'preKey': preKey.toString(),
      'signedPreKeyId': signedPreKeyId.toString(),
      'signedPreKey': signedPreKey.toString(),
      'registrationId': registrationId.toString(),
      'timestamp': timestamp.toString(),
      'signedPreKeySignature': signedPreKeySignature.toString(),
    };
  }
}
