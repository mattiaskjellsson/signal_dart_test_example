import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:fixnum/fixnum.dart';

import 'communication.dart';

class LocalBackAndForth implements Communication {
  late final InMemorySignalProtocolStore _aliceStore;
  late final SessionCipher _bobSessionCipher;

  Future<void> start({required String alice, required String bob}) async {
    final aliAddress = SignalProtocolAddress(alice, 1);
    final bobAddress = SignalProtocolAddress(bob, 1);

    //////////////////////////////////////////////////////////////////////////////
    //Alice receive kind of this stuff.
    final bobPreKey = await createBobStore(aliAddress: aliAddress);

    //Start Alice session
    await createAliceStoreAndBuilder(
        receiverAddress: bobAddress, preKey: bobPreKey);
    final aliceSessionCipher = SessionCipher.fromStore(_aliceStore, bobAddress);

    sendMessages(aliceSessionCipher, alice, _bobSessionCipher, bob);
  }

  Future<void> createAliceStoreAndBuilder(
      {required SignalProtocolAddress receiverAddress,
      required PreKeyBundle preKey}) async {
    final generatedKey = Curve.generateKeyPair();
    _aliceStore = InMemorySignalProtocolStore(
        IdentityKeyPair(
            IdentityKey(generatedKey.publicKey), generatedKey.privateKey),
        generateRegistrationId(false));

    final SessionBuilder aliceSessionBuilder =
        SessionBuilder.fromSignalStore(_aliceStore, receiverAddress);

    await aliceSessionBuilder.processPreKeyBundle(preKey);
  }

  Future<PreKeyBundle> createBobStore(
      {required SignalProtocolAddress aliAddress}) async {
    final ECKeyPair generatedKey = Curve.generateKeyPair();
    final ECKeyPair preKeyPair = Curve.generateKeyPair();
    final ECKeyPair signedPreKeyPair = Curve.generateKeyPair();
    final int deviceId = 1;
    final int preKeyId = 31337;
    final int signedPreKeyId = 22;

    final InMemorySignalProtocolStore bobStore = InMemorySignalProtocolStore(
        IdentityKeyPair(
            IdentityKey(generatedKey.publicKey), generatedKey.privateKey),
        generateRegistrationId(false));

    final Uint8List bobSignedPreKeySignature = Curve.calculateSignature(
        await bobStore
            .getIdentityKeyPair()
            .then((value) => value.getPrivateKey()),
        signedPreKeyPair.publicKey.serialize());

    final bobPreKey = PreKeyBundle(
      await bobStore.getLocalRegistrationId(),
      deviceId,
      preKeyId,
      preKeyPair.publicKey,
      signedPreKeyId,
      signedPreKeyPair.publicKey,
      bobSignedPreKeySignature,
      await bobStore.getIdentityKeyPair().then((value) => value.getPublicKey()),
    );

    // Set keys in bob's store.
    await bobStore.storePreKey(
        preKeyId, PreKeyRecord(bobPreKey.getPreKeyId(), preKeyPair));

    await bobStore.storeSignedPreKey(
        signedPreKeyId,
        SignedPreKeyRecord(
            signedPreKeyId,
            Int64(DateTime.now().millisecondsSinceEpoch),
            signedPreKeyPair,
            bobSignedPreKeySignature));

    // Init bob's session cipher
    _bobSessionCipher = SessionCipher.fromStore(bobStore, aliAddress);

    return Future.value(bobPreKey);
  }

  Future<Uint8List> encryptMessage(
      {required SessionCipher cipher, required String clearText}) async {
    final CiphertextMessage encryptedMessage =
        await cipher.encrypt(Uint8List.fromList(utf8.encode(clearText)));
    return encryptedMessage.serialize();
  }

  // TODO: UGLY UGLY UGLY! Never do like this! But for the sake of simplicity.
  Future<String> decryptMessage(
      {required SessionCipher cipher, required Uint8List fromServer}) async {
    try {
      final encodedPlainText =
          await cipher.decrypt(PreKeySignalMessage(fromServer));
      return utf8.decode(encodedPlainText, allowMalformed: true);
    } on Exception {
      try {
        final encodedPlainText = await cipher
            .decryptFromSignal(SignalMessage.fromSerialized(fromServer));

        return utf8.decode(encodedPlainText, allowMalformed: true);
      } on Exception {
        throw Exception('Out of ideas');
      }
    }
  }

  Future<void> sendMessages(SessionCipher aliceSessionCipher, String alice,
      SessionCipher bobSessionCipher, String bob) async {
    // Alice send first message
    final Uint8List aliceOutgoing0 = await encryptMessage(
        cipher: aliceSessionCipher, clearText: 'Message from $alice');

    final f = await decryptMessage(
        cipher: _bobSessionCipher, fromServer: aliceOutgoing0);
    print(f);

    //Bob send a message
    final bobOutgoingMessage = await encryptMessage(
        cipher: bobSessionCipher, clearText: 'Message from $bob');

    // Alice receive message
    final alicePlaintext = await decryptMessage(
        cipher: aliceSessionCipher, fromServer: bobOutgoingMessage);

    print(alicePlaintext);

    //////////////////////////////////////////////////////////////////////////////

    //Alice send message
    final aliceOutgoing2 = await encryptMessage(
        cipher: aliceSessionCipher, clearText: 'Second message from $alice');

    // Bob receive message
    final alice2Plaintext = await decryptMessage(
        cipher: bobSessionCipher, fromServer: aliceOutgoing2);
    print(alice2Plaintext);

    //////////////////////////////////////////////////////////////////////////////

    // Bob send another message
    final bobOutgoing2 = await encryptMessage(
        cipher: bobSessionCipher, clearText: 'Second message from $bob');

    // Alice receive another message.
    final bob2Plaintext = await decryptMessage(
        cipher: aliceSessionCipher, fromServer: bobOutgoing2);
    print(bob2Plaintext);

    //////////////////////////////////////////////////////////////////////////////

    //Alice send message
    final aliceOutgoing3 = await encryptMessage(
        cipher: aliceSessionCipher, clearText: 'Third message from $alice');

    // Bob receive message
    final alice3Plaintext = await decryptMessage(
        cipher: bobSessionCipher, fromServer: aliceOutgoing3);
    print(alice3Plaintext);

    //////////////////////////////////////////////////////////////////////////////

    // Bob send another message
    final bobOutgoing3 = await encryptMessage(
        cipher: bobSessionCipher, clearText: 'Third message from $bob');

    // Alice receive another message.
    final bob3Plaintext = await decryptMessage(
        cipher: aliceSessionCipher, fromServer: bobOutgoing3);
    print(bob3Plaintext);

    //////////////////////////////////////////////////////////////////////////////

    // Bob send another message
    final bobOutgoing4 = await encryptMessage(
        cipher: bobSessionCipher, clearText: 'Fourth message from $bob');

    // Alice receive another message.
    final bob4Plaintext = await decryptMessage(
        cipher: aliceSessionCipher, fromServer: bobOutgoing4);
    print(bob4Plaintext);

    //////////////////////////////////////////////////////////////////////////////

    // Bob send another message
    final bobOutgoing5 = await encryptMessage(
        cipher: bobSessionCipher, clearText: 'Fifth message from $bob');

    // Alice receive another message.
    final bob5Plaintext = await decryptMessage(
        cipher: aliceSessionCipher, fromServer: bobOutgoing5);
    print(bob5Plaintext);
  }
}
