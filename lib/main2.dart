import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:fixnum/fixnum.dart';

late final SessionBuilder _aliceSessionBuilder;
late final InMemorySignalProtocolStore _aliceStore;

void createAliceStoreAndBuilder(SignalProtocolAddress receiverAddress) {
  final aliGeneratedKey = Curve.generateKeyPair();
  _aliceStore = InMemorySignalProtocolStore(
      IdentityKeyPair(
          IdentityKey(aliGeneratedKey.publicKey), aliGeneratedKey.privateKey),
      generateRegistrationId(false));

  _aliceSessionBuilder =
      SessionBuilder.fromSignalStore(_aliceStore, receiverAddress);
}

late final InMemorySignalProtocolStore _bobStore;

Future<PreKeyBundle> createBobStore() async {
  final ECKeyPair bobGeneratedKey = Curve.generateKeyPair();
  final ECKeyPair bobPreKeyPair = Curve.generateKeyPair();
  final ECKeyPair bobSignedPreKeyPair = Curve.generateKeyPair();
  final int bobDeviceId = 1;
  final int bobPreKeyId = 31337;
  final int signedPreKeyId = 22;

  _bobStore = InMemorySignalProtocolStore(
      IdentityKeyPair(
          IdentityKey(bobGeneratedKey.publicKey), bobGeneratedKey.privateKey),
      generateRegistrationId(false));

  final Uint8List bobSignedPreKeySignature = Curve.calculateSignature(
      await _bobStore
          .getIdentityKeyPair()
          .then((value) => value.getPrivateKey()),
      bobSignedPreKeyPair.publicKey.serialize());

  final bobPreKey = PreKeyBundle(
    await _bobStore.getLocalRegistrationId(),
    bobDeviceId,
    bobPreKeyId,
    bobPreKeyPair.publicKey,
    signedPreKeyId,
    bobSignedPreKeyPair.publicKey,
    bobSignedPreKeySignature,
    await _bobStore.getIdentityKeyPair().then((value) => value.getPublicKey()),
  );

  // Set keys in bob's store.
  await _bobStore.storePreKey(
      bobPreKeyId, PreKeyRecord(bobPreKey.getPreKeyId(), bobPreKeyPair));

  await _bobStore.storeSignedPreKey(
      signedPreKeyId,
      SignedPreKeyRecord(
          signedPreKeyId,
          Int64(DateTime.now().millisecondsSinceEpoch),
          bobSignedPreKeyPair,
          bobSignedPreKeySignature));

  return Future.value(bobPreKey);
}

Future<void> main() async {
  final aliAddress = SignalProtocolAddress('ali', 1);
  final bobAddress = SignalProtocolAddress('bob', 1);

  //////////////////////////////////////////////////////////////////////////////

  createAliceStoreAndBuilder(bobAddress);

  //////////////////////////////////////////////////////////////////////////////
  //Alice receive kind of this stuff.
  final bobPreKey = await createBobStore();

  //Start Alice session
  await _aliceSessionBuilder.processPreKeyBundle(bobPreKey);
  final aliceSessionCipher = SessionCipher.fromStore(_aliceStore, bobAddress);

  // Alice send a message
  final toServer =
      await encryptMessage(aliceSessionCipher, 'Message from alice');

  //////////////////////////////////////////////////////////////////////////////
  // Init bob's session cipher

  final bobSessionCipher = SessionCipher.fromStore(_bobStore, aliAddress);

  //////////////////////////////////////////////////////////////////////////////

  //Bob decrypt first message from Alice. _This is special!_
  final fromServer = toServer;

  final f = await bobSessionCipher.decrypt(PreKeySignalMessage(fromServer));
  print(utf8.decode(f));

  //////////////////////////////////////////////////////////////////////////////
  //Bob send a message
  final bobOutgoingMessage =
      await encryptMessage(bobSessionCipher, 'Message from bob');

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
      await decryptMessage(bobSessionCipher, aliceOutgoing2);
  print(alice2Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing2 =
      await encryptMessage(bobSessionCipher, 'Second message from bob');

  // Alice receive another message.
  final bob2Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing2);
  print(bob2Plaintext);

  //////////////////////////////////////////////////////////////////////////////
  //Alice send message
  final aliceOutgoing3 =
      await encryptMessage(aliceSessionCipher, 'Third message from alice');

  // Bob receive message
  final alice3Plaintext =
      await decryptMessage(bobSessionCipher, aliceOutgoing3);
  print(alice3Plaintext);

  //////////////////////////////////////////////////////////////////////////////

  // Bob send another message
  final bobOutgoing3 =
      await encryptMessage(bobSessionCipher, 'Third message from bob');

  // Alice receive another message.
  final bob3Plaintext = await decryptMessage(aliceSessionCipher, bobOutgoing3);
  print(bob3Plaintext);
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
