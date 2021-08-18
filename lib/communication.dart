import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

abstract class Communication {
  Future<void> start({required String alice, required String bob});

  Future<void> createAliceStoreAndBuilder(
      {required SignalProtocolAddress receiverAddress,
      required PreKeyBundle preKey});

  Future<Uint8List> encryptMessage(
      {required SessionCipher cipher, required String clearText});

  Future<String> decryptMessage(
      {required SessionCipher cipher, required Uint8List fromServer});
}
