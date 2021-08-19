import 'dart:convert';
import 'dart:io';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'communication.dart';
import 'key_api.dart';
import 'persisted_keys.dart';

class ServerConnection implements Communication {
  late final KeyApi _keyApi;
  late final SessionCipher _sessionCipher;
  late final InMemorySignalProtocolStore _store;
  late final SessionBuilder _sessionBuilder;
  late final Socket socket;
  ServerConnection() : _keyApi = KeyApi(serverUrl: 'http://localhost:3000/');

  Future<PreKeyBundle> generateKeysSetupStore(
      {required SignalProtocolAddress receiverAddress}) async {
    final myName = receiverAddress.getName() == 'bob' ? 'alice' : 'bob';
    PersistedKeys pks = KeyPersistance.readKeys(myName);

    // Create store
    _store = InMemorySignalProtocolStore(
        IdentityKeyPair(IdentityKey(pks.generatedKey.publicKey),
            pks.generatedKey.privateKey),
        pks.registrationId);

    // Create the final key.
    final signedPreKeySignature = Curve.calculateSignature(
        await _store
            .getIdentityKeyPair()
            .then((value) => value.getPrivateKey()),
        pks.signedPreKeyPair.publicKey.serialize());

    // Create public keys bundle
    final preKey = PreKeyBundle(
      await _store.getLocalRegistrationId(),
      pks.deviceId,
      pks.preKeyId,
      pks.preKeyPair.publicKey,
      pks.signedPreKeyId,
      pks.signedPreKeyPair.publicKey,
      signedPreKeySignature,
      await _store.getIdentityKeyPair().then((value) => value.getPublicKey()),
    );

    // Store keys.
    await _store.storePreKey(
        pks.preKeyId, PreKeyRecord(preKey.getPreKeyId(), pks.preKeyPair));
    await _store.storeSignedPreKey(
        pks.signedPreKeyId,
        SignedPreKeyRecord(pks.signedPreKeyId, pks.timestamp,
            pks.signedPreKeyPair, signedPreKeySignature));

    // Init session cipher
    _sessionCipher = SessionCipher.fromStore(_store, receiverAddress);

    return Future.value(preKey);
  }

  @override
  Future<void> createAliceStoreAndBuilder(
      {required SignalProtocolAddress receiverAddress,
      required PreKeyBundle preKey}) async {
    _sessionBuilder = SessionBuilder.fromSignalStore(_store, receiverAddress);
    await _sessionBuilder.processPreKeyBundle(preKey);
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

  PreKeyBundle _keyObjectToPreKeyBundle({required KeyObject keyObject}) {
    return PreKeyBundle(
        keyObject.registrationId,
        keyObject.deviceId,
        keyObject.preKeyId,
        Curve.decodePoint(keyObject.preKey, 0),
        keyObject.signedPreKeyId,
        Curve.decodePoint(keyObject.signedPreKey, 0),
        keyObject.signedPreKey,
        IdentityKey.fromBytes(keyObject.identityKeyPair, 0));
  }

  @override
  Future<void> start({required String alice, required String bob}) async {
    final bobAddress = SignalProtocolAddress(bob, 1);

    PreKeyBundle alicePreKeyBundle =
        await generateKeysSetupStore(receiverAddress: bobAddress);

    await _keyApi.storeKey(KeyObject(
      username: alice,
      identityKeyPair: alicePreKeyBundle.getIdentityKey().publicKey.serialize(),
      deviceId: alicePreKeyBundle.getDeviceId(),
      preKeyId: alicePreKeyBundle.getPreKeyId(),
      preKey: alicePreKeyBundle.getPreKey().serialize(),
      signedPreKeyId: alicePreKeyBundle.getSignedPreKeyId(),
      signedPreKey: alicePreKeyBundle.getSignedPreKey()!.serialize(),
      registrationId: alicePreKeyBundle.getRegistrationId(),
    ));

    final bobsKeys = await _keyApi.fetchKey(bob);

    await createAliceStoreAndBuilder(
      receiverAddress: bobAddress,
      preKey: _keyObjectToPreKeyBundle(keyObject: bobsKeys),
    );

    connectToSocketIoServer();

    String send = '';
    final Encoding encoding = Encoding.getByName('utf-8') ?? Utf8Codec();
    while (send != 'exit') {
      send = stdin.readLineSync(encoding: encoding, retainNewlines: false) ??
          'exit';

      if (send == 'exit') break;

      final m = {
        "id": socket.id,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        'message': send
      };

      socket.emit('send_message', json.encode(m));
    }
  }

  void connectToSocketIoServer() {
    try {
      socket = io('http://127.0.0.1:3001', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.on('connect', (_) => {print('connect: ${socket.id}')});
      socket.on('message', _receiveHandler);
      socket.on('disconnect', (_) => print('disconnect'));
      socket.on('fromServer', (_) => print(_));
      socket.connect();
    } catch (e) {
      print(e.toString());
    }
  }

  _receiveHandler(dynamic data) {
    Map<String, dynamic> d = json.decode(data);
    if (d['id'] != socket.id) {
      print(d);
    }
  }
}
