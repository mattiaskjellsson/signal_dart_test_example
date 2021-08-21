import 'package:fixnum/fixnum.dart';
import 'dart:typed_data';
import 'dart:convert';

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
    return KeyObject(
      username: data['username'],
      identityKeyPair:
          Uint8List.fromList(json.decode(data['identityKeyPair']).cast<int>()),
      deviceId: int.parse(data['deviceId']),
      preKeyId: int.parse(data['preKeyId']),
      preKey: Uint8List.fromList(json.decode(data['preKey']).cast<int>()),
      signedPreKeyId: int.parse(data['signedPreKeyId']),
      signedPreKey:
          Uint8List.fromList(json.decode(data['signedPreKey']).cast<int>()),
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
