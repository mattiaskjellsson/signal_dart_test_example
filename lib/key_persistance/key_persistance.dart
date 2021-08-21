import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:signal_example_flutter/key_persistance/persisted_keys.dart';

class KeyPersistance {
  static PersistedKeys readKeys({required String receiverName}) {
    Map<String, dynamic> kg;
    if (receiverName == 'alice') {
      kg = json.decode(bobsPersistedKeys);
    } else {
      kg = json.decode(alicePersistedKeys);
    }

    List<int> generatedPublicKey = kg['generatedPublicKey'].cast<int>();
    List<int> generatedPrivateKey = kg['generatedPrivateKey'].cast<int>();
    List<int> preKeyPairPublicKey = kg['preKeyPairPublicKey'].cast<int>();
    List<int> preKeyPairPrivateKey = kg['preKeyPairPrivateKey'].cast<int>();
    List<int> signedPreKeyPairPublicKey =
        kg['signedPreKeyPairPublicKey'].cast<int>();
    List<int> signedPreKeyPairPrivateKey =
        kg['signedPreKeyPairPrivateKey'].cast<int>();

    final ECKeyPair generatedKey = ECKeyPair(
        Curve.decodePoint(Uint8List.fromList(generatedPublicKey), 0),
        Curve.decodePrivatePoint(Uint8List.fromList(generatedPrivateKey)));
    final ECKeyPair preKeyPair = ECKeyPair(
        Curve.decodePoint(Uint8List.fromList(preKeyPairPublicKey), 0),
        Curve.decodePrivatePoint(Uint8List.fromList(preKeyPairPrivateKey)));
    final ECKeyPair signedPreKeyPair = ECKeyPair(
        Curve.decodePoint(Uint8List.fromList(signedPreKeyPairPublicKey), 0),
        Curve.decodePrivatePoint(
            Uint8List.fromList(signedPreKeyPairPrivateKey)));
    final int deviceId = kg['deviceId'];
    final int preKeyId = kg['preKeyId'];
    final int signedPreKeyId = kg['signedPreKeyId'];
    final int registrationId = kg['registrationId'];
    final Int64 timestamp = Int64.parseInt(kg['timestamp']);

    return PersistedKeys(
      generatedKey: generatedKey,
      preKeyPair: preKeyPair,
      signedPreKeyPair: signedPreKeyPair,
      deviceId: deviceId,
      preKeyId: preKeyId,
      signedPreKeyId: signedPreKeyId,
      registrationId: registrationId,
      timestamp: timestamp,
    );
  }
}
