import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

const String alicePersistedKeys = '''
{
  "generatedPublicKey": [5, 67, 104, 251, 39, 100, 243, 146, 46, 55, 89, 77, 59, 207, 178, 130, 68, 98, 177, 217, 239, 134, 8, 235, 142, 202, 93, 106, 214, 82, 159, 85, 6],
  "generatedPrivateKey": [16, 109, 164, 3, 178, 46, 192, 158, 163, 93, 106, 87, 212, 182, 253, 56, 38, 223, 203, 96, 12, 247, 58, 248, 241, 83, 203, 241, 195, 225, 128, 77],
  "preKeyPairPublicKey": [5, 78, 175, 49, 23, 174, 18, 105, 138, 213, 5, 210, 105, 153, 190, 79, 122, 239, 116, 126, 84, 152, 236, 158, 71, 180, 23, 114, 34, 136, 69, 60, 21],
  "preKeyPairPrivateKey": [240, 25, 175, 183, 197, 199, 26, 7, 115, 128, 143, 232, 208, 11, 107, 32, 70, 152, 252, 60, 192, 224, 176, 80, 123, 19, 224, 231, 39, 200, 161, 95],
  "signedPreKeyPairPublicKey": [5, 56, 208, 127, 222, 230, 241, 66, 5, 191, 2, 39, 107, 201, 30, 187, 138, 16, 88, 160, 13, 91, 231, 45, 210, 104, 84, 231, 124, 25, 119, 80, 86],
  "signedPreKeyPairPrivateKey": [64, 142, 192, 74, 204, 26, 19, 48, 202, 139, 181, 57, 127, 235, 168, 246, 167, 11, 88, 194, 248, 250, 191, 133, 182, 128, 200, 86, 155, 1, 199, 97],
  "deviceId": 1,
  "preKeyId": 31337,
  "signedPreKeyId": 22,
  "registrationId": 321,
  "timestamp": "1629374662252"
}
''';

const String bobsPersistedKeys = '''
{
  "generatedPublicKey": [5, 67, 144, 132, 30, 211, 70, 176, 65, 224, 68, 169, 48, 250, 185, 64, 90, 73, 201, 149, 251, 88, 214, 212, 10, 223, 31, 178, 198, 195, 57, 182, 41],
  "generatedPrivateKey": [144, 46, 196, 221, 201, 216, 150, 252, 194, 107, 220, 201, 213, 114, 125, 247, 217, 187, 13, 81, 86, 171, 166, 83, 102, 15, 80, 119, 31, 141, 232, 86],
  "preKeyPairPublicKey": [5, 149, 26, 31, 160, 249, 81, 163, 27, 229, 180, 233, 126, 117, 119, 116, 67, 35, 90, 130, 100, 52, 106, 158, 58, 148, 105, 154, 32, 221, 125, 48, 106],
  "preKeyPairPrivateKey": [152, 57, 78, 249, 163, 135, 120, 147, 17, 111, 40, 246, 63, 12, 54, 242, 119, 83, 19, 246, 236, 235, 5, 58, 18, 122, 182, 57, 34, 85, 150, 85],
  "signedPreKeyPairPublicKey": [5, 67, 189, 19, 29, 17, 148, 148, 82, 85, 173, 238, 13, 14, 236, 138, 215, 229, 12, 182, 165, 13, 60, 19, 216, 95, 119, 221, 26, 196, 49, 73, 120],
  "signedPreKeyPairPrivateKey": [96, 90, 222, 80, 147, 58, 153, 148, 109, 127, 133, 211, 13, 9, 241, 66, 164, 188, 61, 4, 66, 183, 186, 141, 178, 151, 211, 211, 149, 41, 129, 91],
  "deviceId": 1,
  "preKeyId": 31337,
  "signedPreKeyId": 22,
  "registrationId": 123,
  "timestamp": "1629374685162"
}
''';

class PersistedKeys {
  final ECKeyPair generatedKey;
  final ECKeyPair preKeyPair;
  final ECKeyPair signedPreKeyPair;
  final int deviceId;
  final int preKeyId;
  final int signedPreKeyId;
  final int registrationId;
  final Int64 timestamp;

  const PersistedKeys(
      {required this.generatedKey,
      required this.preKeyPair,
      required this.signedPreKeyPair,
      required this.deviceId,
      required this.preKeyId,
      required this.signedPreKeyId,
      required this.registrationId,
      required this.timestamp});
}

class KeyPersistance {
  static PersistedKeys readKeys(String myName) {
    Map<String, dynamic> kg;
    if (myName == 'bob') {
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
