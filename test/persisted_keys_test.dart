import 'package:flutter_test/flutter_test.dart';
import 'package:signal_example_flutter/key_persistance/key_persistance.dart';
import 'package:signal_example_flutter/key_persistance/persisted_keys.dart';

void main() {
  // Alice persisted keys... just to have something to test with.
  const generatedPublicKey = [
    5,
    67,
    104,
    251,
    39,
    100,
    243,
    146,
    46,
    55,
    89,
    77,
    59,
    207,
    178,
    130,
    68,
    98,
    177,
    217,
    239,
    134,
    8,
    235,
    142,
    202,
    93,
    106,
    214,
    82,
    159,
    85,
    6
  ];
  const generatedPrivateKey = [
    16,
    109,
    164,
    3,
    178,
    46,
    192,
    158,
    163,
    93,
    106,
    87,
    212,
    182,
    253,
    56,
    38,
    223,
    203,
    96,
    12,
    247,
    58,
    248,
    241,
    83,
    203,
    241,
    195,
    225,
    128,
    77
  ];
  const preKeyPairPublicKey = [
    5,
    78,
    175,
    49,
    23,
    174,
    18,
    105,
    138,
    213,
    5,
    210,
    105,
    153,
    190,
    79,
    122,
    239,
    116,
    126,
    84,
    152,
    236,
    158,
    71,
    180,
    23,
    114,
    34,
    136,
    69,
    60,
    21
  ];
  const preKeyPairPrivateKey = [
    240,
    25,
    175,
    183,
    197,
    199,
    26,
    7,
    115,
    128,
    143,
    232,
    208,
    11,
    107,
    32,
    70,
    152,
    252,
    60,
    192,
    224,
    176,
    80,
    123,
    19,
    224,
    231,
    39,
    200,
    161,
    95
  ];
  const signedPreKeyPairPublicKey = [
    5,
    56,
    208,
    127,
    222,
    230,
    241,
    66,
    5,
    191,
    2,
    39,
    107,
    201,
    30,
    187,
    138,
    16,
    88,
    160,
    13,
    91,
    231,
    45,
    210,
    104,
    84,
    231,
    124,
    25,
    119,
    80,
    86
  ];
  const signedPreKeyPairPrivateKey = [
    64,
    142,
    192,
    74,
    204,
    26,
    19,
    48,
    202,
    139,
    181,
    57,
    127,
    235,
    168,
    246,
    167,
    11,
    88,
    194,
    248,
    250,
    191,
    133,
    182,
    128,
    200,
    86,
    155,
    1,
    199,
    97
  ];
  const deviceId = 1;
  const preKeyId = 31337;
  const signedPreKeyId = 22;
  const registrationId = 321;
  //
  group('Test reading persisted keys', () {
    final PersistedKeys keys = KeyPersistance.readKeys(receiverName: 'bob');

    test('Test generatedPublicKey', () {
      final actual = keys.generatedKey.publicKey.serialize();
      expect(actual, generatedPublicKey);
    });

    test('Test generatedPrivateKey', () {
      final actual = keys.generatedKey.privateKey.serialize();
      expect(actual, generatedPrivateKey);
    });

    test('Test preKeyPairPublicKey', () {
      final actual = keys.preKeyPair.publicKey.serialize();
      expect(actual, preKeyPairPublicKey);
    });

    test('Test preKeyPairPrivateKey', () {
      final actual = keys.preKeyPair.privateKey.serialize();
      expect(actual, preKeyPairPrivateKey);
    });

    test('Test signedPreKeyPairPublicKey', () {
      final actual = keys.signedPreKeyPair.publicKey.serialize();
      expect(actual, signedPreKeyPairPublicKey);
    });

    test('Test signedPreKeyPairPrivateKey', () {
      final actual = keys.signedPreKeyPair.privateKey.serialize();
      expect(actual, signedPreKeyPairPrivateKey);
    });

    test('Test deviceId', () {
      final actual = keys.deviceId;
      expect(actual, deviceId);
    });

    test('Test preKeyId', () {
      final actual = keys.preKeyId;
      expect(actual, preKeyId);
    });

    test('Test signedPreKeyId', () {
      final actual = keys.signedPreKeyId;
      expect(actual, signedPreKeyId);
    });

    test('Test registrationId', () {
      final actual = keys.registrationId;
      expect(actual, registrationId);
    });
  });
}
