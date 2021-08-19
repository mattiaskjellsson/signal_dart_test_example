import 'package:libsignal_protocol_dart/src/state/pre_key_bundle.dart';
import 'package:libsignal_protocol_dart/src/signal_protocol_address.dart';
import 'package:libsignal_protocol_dart/src/session_cipher.dart';

import 'dart:typed_data';

import 'communication.dart';
import 'key_api.dart';

class ServerConnection implements Communication {
  late final KeyApi _keyApi = KeyApi(serverUrl: 'http://localhost:3000/');
  late final SessionCipher sessionCipher;

  @override
  Future<void> createAliceStoreAndBuilder(
      {required SignalProtocolAddress receiverAddress,
      required PreKeyBundle preKey}) {
    // TODO: implement createAliceStoreAndBuilder
    throw UnimplementedError();
  }

  @override
  Future<String> decryptMessage(
      {required SessionCipher cipher, required Uint8List fromServer}) {
    // TODO: implement decryptMessage
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> encryptMessage(
      {required SessionCipher cipher, required String clearText}) {
    // TODO: implement encryptMessage
    throw UnimplementedError();
  }

  @override
  Future<void> start({required String alice, required String bob}) {
    // TODO: implement start
    throw UnimplementedError();
  }
}
