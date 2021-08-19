import 'dart:convert';
import 'package:http/http.dart' as http;

class KeyApi {
  final String serverUrl;

  KeyApi({required this.serverUrl});

  Future<KeyObject> fetchKey(String name) async {
    final response = await http.get(Uri.parse(serverUrl + name));

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return KeyObject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Key');
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
  final String identityKeyPair;
  final String deviceId;
  final String preKeyId;
  final String preKey;
  final String signedPreKeyId;
  final String signedPreKey;
  final String registrationId;

  KeyObject({
    required this.username,
    required this.identityKeyPair,
    required this.deviceId,
    required this.preKeyId,
    required this.preKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.registrationId,
  });

  factory KeyObject.fromJson(Map<String, dynamic> json) {
    return KeyObject(
      username: json['username'],
      identityKeyPair: json['identityKeyPair'],
      deviceId: json['deviceId'],
      preKeyId: json['preKeyId'],
      preKey: json['preKey'],
      signedPreKeyId: json['signedPreKeyId'],
      signedPreKey: json['signedPreKey'],
      registrationId: json['registrationId'],
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
    };
  }
}
