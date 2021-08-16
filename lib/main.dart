import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

Future<void> main() async {
  await install();
}

late SessionCipher _sessionCipher;

Future<void> install() async {
  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(false);

  final preKeys = generatePreKeys(0, 110);

  final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

  final sessionStore = InMemorySessionStore();
  final preKeyStore = InMemoryPreKeyStore();
  final signedPreKeyStore = InMemorySignedPreKeyStore();
  final identityStore =
      InMemoryIdentityKeyStore(identityKeyPair, registrationId);

  for (var p in preKeys) {
    await preKeyStore.storePreKey(p.id, p);
  }
  await signedPreKeyStore.storeSignedPreKey(signedPreKey.id, signedPreKey);

  final bobAddress = SignalProtocolAddress('bob', 1);
  final sessionBuilder = SessionBuilder(
      sessionStore, preKeyStore, signedPreKeyStore, identityStore, bobAddress);

  // Should get remote from the server
  final remoteRegId = generateRegistrationId(false);
  final remoteIdentityKeyPair = generateIdentityKeyPair();
  final remotePreKeys = generatePreKeys(0, 110);
  final remoteSignedPreKey = generateSignedPreKey(remoteIdentityKeyPair, 0);

  final retrievedPreKey = PreKeyBundle(
      remoteRegId,
      1,
      remotePreKeys[0].id,
      remotePreKeys[0].getKeyPair().publicKey,
      remoteSignedPreKey.id,
      remoteSignedPreKey.getKeyPair().publicKey,
      remoteSignedPreKey.signature,
      remoteIdentityKeyPair.getPublicKey());

  await sessionBuilder.processPreKeyBundle(retrievedPreKey);

  _sessionCipher = SessionCipher(
      sessionStore, preKeyStore, signedPreKeyStore, identityStore, bobAddress);

  final signalProtocolStore =
      InMemorySignalProtocolStore(remoteIdentityKeyPair, 1);
  final aliceAddress = SignalProtocolAddress('alice', 1);
  final remoteSessionCipher =
      SessionCipher.fromStore(signalProtocolStore, aliceAddress);

  for (var p in remotePreKeys) {
    await signalProtocolStore.storePreKey(p.id, p);
  }
  await signalProtocolStore.storeSignedPreKey(
      remoteSignedPreKey.id, remoteSignedPreKey);

  CiphertextMessage ciphertext = await newMethod('Hello Mixin🤣');

  await receiveEncrypted(ciphertext, remoteSessionCipher);
}

Future<void> receiveEncrypted(
    CiphertextMessage ciphertext, SessionCipher remoteSessionCipher) async {
  if (ciphertext.getType() == CiphertextMessage.prekeyType) {
    await remoteSessionCipher
        .decryptWithCallback(ciphertext as PreKeySignalMessage, (plaintext) {
      print(utf8.decode(plaintext));
    });
  }
}

Future<CiphertextMessage> newMethod(String text) async {
  final ciphertext =
      await _sessionCipher.encrypt(Uint8List.fromList(utf8.encode(text)));
  print(ciphertext);
  print(ciphertext.serialize());

  return ciphertext;
}
