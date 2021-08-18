import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:fixnum/fixnum.dart';

late final SessionBuilder _aliceSessionBuilder;
late final InMemorySignalProtocolStore _aliceStore;
late final SessionCipher _bobSessionCipher;

Future<void> main() async {
  final aliAddress = SignalProtocolAddress('ali', 1);
  final bobAddress = SignalProtocolAddress('bob', 1);

  //////////////////////////////////////////////////////////////////////////////

  createAliceStoreAndBuilder(bobAddress);

  //////////////////////////////////////////////////////////////////////////////
  //Alice receive kind of this stuff.
  final bobPreKey = await createBobStore(aliAddress);

  //Start Alice session
  await _aliceSessionBuilder.processPreKeyBundle(bobPreKey);
  final aliceSessionCipher = SessionCipher.fromStore(_aliceStore, bobAddress);

  // Alice send a message
  final toServer =
      await encryptMessage(aliceSessionCipher, 'Message from alice');

  //////////////////////////////////////////////////////////////////////////////

  //Bob decrypt first message from Alice. _This is special!_
  final fromServer = toServer;

  final f = await _bobSessionCipher.decrypt(PreKeySignalMessage(fromServer));
  print(utf8.decode(f));

  //////////////////////////////////////////////////////////////////////////////

  //Bob send a message
  final bobOutgoingMessage =
      await encryptMessage(_bobSessionCipher, 'Message from bob');

  // Alice receive message
  final alicePlaintext =
      await decryptMessage(aliceSessionCipher, bobOutgoingMessage);

  print(alicePlaintext);

  //////////////////////////////////////////////////////////////////////////////

  //Alice send message
  final aliceOutgoing2 =
      await encryptMessage(aliceSessionCipher, 'Second message from alice');

  // Bob receive message
  final alice2Plaintext =
      await decryptMessage(_bobSessionCipher, aliceOutgoing2);
  print(alice2Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing2 =
      await encryptMessage(_bobSessionCipher, 'Second message from bob');

  // Alice receive another message.
  final bob2Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing2);
  print(bob2Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  //Alice send message
  final aliceOutgoing3 =
      await encryptMessage(aliceSessionCipher, 'Third message from alice');

  // Bob receive message
  final alice3Plaintext =
      await decryptMessage(_bobSessionCipher, aliceOutgoing3);
  print(alice3Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing3 =
      await encryptMessage(_bobSessionCipher, 'Third message from bob');

  // Alice receive another message.
  final bob3Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing3);
  print(bob3Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing4 =
      await encryptMessage(_bobSessionCipher, 'Fourth message from bob');

  // Alice receive another message.
  final bob4Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing4);
  print(bob4Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing5 =
      await encryptMessage(_bobSessionCipher, 'Fifth message from bob');

  // Alice receive another message.
  final bob5Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing5);
  print(bob5Plaintext);
}

void createAliceStoreAndBuilder(SignalProtocolAddress receiverAddress) {
  final aliGeneratedKey = Curve.generateKeyPair();
  _aliceStore = InMemorySignalProtocolStore(
      IdentityKeyPair(
          IdentityKey(aliGeneratedKey.publicKey), aliGeneratedKey.privateKey),
      generateRegistrationId(false));

  _aliceSessionBuilder =
      SessionBuilder.fromSignalStore(_aliceStore, receiverAddress);
}

Future<PreKeyBundle> createBobStore(SignalProtocolAddress aliAddress) async {
  final ECKeyPair bobGeneratedKey = Curve.generateKeyPair();
  final ECKeyPair bobPreKeyPair = Curve.generateKeyPair();
  final ECKeyPair bobSignedPreKeyPair = Curve.generateKeyPair();
  final int bobDeviceId = 1;
  final int bobPreKeyId = 31337;
  final int signedPreKeyId = 22;
  final InMemorySignalProtocolStore bobStore;

  bobStore = InMemorySignalProtocolStore(
      IdentityKeyPair(
          IdentityKey(bobGeneratedKey.publicKey), bobGeneratedKey.privateKey),
      generateRegistrationId(false));

  final Uint8List bobSignedPreKeySignature = Curve.calculateSignature(
      await bobStore
          .getIdentityKeyPair()
          .then((value) => value.getPrivateKey()),
      bobSignedPreKeyPair.publicKey.serialize());

  final bobPreKey = PreKeyBundle(
    await bobStore.getLocalRegistrationId(),
    bobDeviceId,
    bobPreKeyId,
    bobPreKeyPair.publicKey,
    signedPreKeyId,
    bobSignedPreKeyPair.publicKey,
    bobSignedPreKeySignature,
    await bobStore.getIdentityKeyPair().then((value) => value.getPublicKey()),
  );

  // Set keys in bob's store.
  await bobStore.storePreKey(
      bobPreKeyId, PreKeyRecord(bobPreKey.getPreKeyId(), bobPreKeyPair));

  await bobStore.storeSignedPreKey(
      signedPreKeyId,
      SignedPreKeyRecord(
          signedPreKeyId,
          Int64(DateTime.now().millisecondsSinceEpoch),
          bobSignedPreKeyPair,
          bobSignedPreKeySignature));

  // Init bob's session cipher
  _bobSessionCipher = SessionCipher.fromStore(bobStore, aliAddress);

  return Future.value(bobPreKey);
}

Future<Uint8List> encryptMessage(SessionCipher cipher, String clearText) async {
  final encryptedMessage =
      await cipher.encrypt(Uint8List.fromList(utf8.encode(clearText)));
  return encryptedMessage.serialize();
}

Future<String> decryptMessage(
    SessionCipher sessionCipher, Uint8List fromServer) async {
  final plainText = await sessionCipher
      .decryptFromSignal(SignalMessage.fromSerialized(fromServer));

  return utf8.decode(plainText, allowMalformed: true);
}
