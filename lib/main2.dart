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

late final SessionBuilder _bobSessionBuilder;
late final InMemorySignalProtocolStore _bobStore;
void createBobStoreAndBuilder(SignalProtocolAddress receiverAddress) {}

Future<void> main() async {
  final aliAddress = SignalProtocolAddress('ali', 1);
  final bobAddress = SignalProtocolAddress('bob', 1);

  //////////////////////////////////////////////////////////////////////////////
  createAliceStoreAndBuilder(bobAddress);
  createBobStoreAndBuilder(aliAddress);

  final _bobGeneratedKey = Curve.generateKeyPair();
  final _bobStore = InMemorySignalProtocolStore(
      IdentityKeyPair(
          IdentityKey(_bobGeneratedKey.publicKey), _bobGeneratedKey.privateKey),
      generateRegistrationId(false));

  var _bobPreKeyPair = Curve.generateKeyPair();
  var _bobSignedPreKeyPair = Curve.generateKeyPair();
  var _bobSignedPreKeySignature = Curve.calculateSignature(
      await _bobStore
          .getIdentityKeyPair()
          .then((value) => value.getPrivateKey()),
      _bobSignedPreKeyPair.publicKey.serialize());

  final _bobDeviceId = 1;
  final _bobPreKeyId = 31337;
  final _signedPreKeyId = 22;

  var _bobPreKey = PreKeyBundle(
      await _bobStore.getLocalRegistrationId(),
      _bobDeviceId,
      _bobPreKeyId,
      _bobPreKeyPair.publicKey,
      _signedPreKeyId,
      _bobSignedPreKeyPair.publicKey,
      _bobSignedPreKeySignature,
      await _bobStore
          .getIdentityKeyPair()
          .then((value) => value.getPublicKey()));

  //////////////////////////////////////////////////////////////////////////////

  await _aliceSessionBuilder.processPreKeyBundle(_bobPreKey);

  //////////////////////////////////////////////////////////////////////////////

  var aliceSessionCipher = SessionCipher.fromStore(_aliceStore, bobAddress);
  var outgoingMessage = await aliceSessionCipher
      .encrypt(Uint8List.fromList(utf8.encode("Message from alice")));
  var toServer = outgoingMessage.serialize();

////////////////////////////////////////////////////////////////////////////////

  var fromServer = toServer;

////////////////////////////////////////////////////////////////////////////////

  await _bobStore.storePreKey(
      _bobPreKeyId, PreKeyRecord(_bobPreKey.getPreKeyId(), _bobPreKeyPair));

  await _bobStore.storeSignedPreKey(
      _signedPreKeyId,
      SignedPreKeyRecord(
          _signedPreKeyId,
          Int64(DateTime.now().millisecondsSinceEpoch),
          _bobSignedPreKeyPair,
          _bobSignedPreKeySignature));

  final bobSessionCipher = SessionCipher.fromStore(_bobStore, aliAddress);

  //////////////////////////////////////////////////////////////////////////////

  final f = await bobSessionCipher.decrypt(PreKeySignalMessage(fromServer));
  print(utf8.decode(f));

  //////////////////////////////////////////////////////////////////////////////

  final bobOutgoingMessage =
      await encryptMessage(bobSessionCipher, 'MessageFromBob');

  final alicePlaintext =
      await decryptMessage(aliceSessionCipher, bobOutgoingMessage);

  print(alicePlaintext);
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
