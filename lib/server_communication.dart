import 'dart:convert';
import 'dart:io';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'communication.dart';
import 'key_server/key_api.dart';
import 'key_server/key_object.dart';
import 'persisted_keys.dart';
import './helpers/key_object_key_bundle.dart';

class ServerConnection implements Communication {
  late final KeyApi _keyApi;
  late final SessionCipher _sessionCipher;
  late final InMemorySignalProtocolStore _store;
  late final SessionBuilder _sessionBuilder;
  late final Socket _socket;
  late final Int64 _timestamp;

  ServerConnection({required KeyApi keyApi}) : _keyApi = keyApi;

  Future<PreKeyBundle> loadKeysAndSetupStore(
      {required SignalProtocolAddress receiverAddress}) async {
    PersistedKeys myPersistedKeys =
        KeyPersistance.readKeys(receiverName: receiverAddress.getName());

    _timestamp = myPersistedKeys.timestamp;

    // Create store
    final identityKeyPair = IdentityKeyPair(
        IdentityKey.fromBytes(
            Uint8List.fromList(
                myPersistedKeys.generatedKey.publicKey.serialize().toList()),
            0),
        Curve.decodePrivatePoint(Uint8List.fromList(
            myPersistedKeys.generatedKey.privateKey.serialize().toList())));

    final signedPreKeySignature = Curve.calculateSignature(
        myPersistedKeys.generatedKey.privateKey,
        myPersistedKeys.signedPreKeyPair.publicKey.serialize());

    _store = InMemorySignalProtocolStore(
        identityKeyPair, myPersistedKeys.registrationId);

    // Store keys.
    await _store.storePreKey(myPersistedKeys.preKeyId,
        PreKeyRecord(myPersistedKeys.preKeyId, myPersistedKeys.preKeyPair));

    await _store.storeSignedPreKey(
        myPersistedKeys.signedPreKeyId,
        SignedPreKeyRecord(myPersistedKeys.signedPreKeyId, _timestamp,
            myPersistedKeys.signedPreKeyPair, signedPreKeySignature));

    // Create public keys bundle
    final preKey = PreKeyBundle(
      myPersistedKeys.registrationId,
      myPersistedKeys.deviceId,
      myPersistedKeys.preKeyId,
      myPersistedKeys.preKeyPair.publicKey,
      myPersistedKeys.signedPreKeyId,
      myPersistedKeys.signedPreKeyPair.publicKey,
      signedPreKeySignature,
      identityKeyPair.getPublicKey(),
    );

    return Future.value(preKey);
  }

  @override
  Future<SessionCipher> createAliceSessionCipher(
      {required SignalProtocolAddress receiverAddress,
      required PreKeyBundle preKey}) async {
    _sessionBuilder = SessionBuilder.fromSignalStore(_store, receiverAddress);

    await _sessionBuilder.processPreKeyBundle(preKey);
    return SessionCipher.fromStore(_store, receiverAddress);
  }

  @override
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

  @override
  Future<Uint8List> encryptMessage(
      {required SessionCipher cipher, required String clearText}) async {
    final CiphertextMessage encryptedMessage =
        await cipher.encrypt(Uint8List.fromList(utf8.encode(clearText)));
    return encryptedMessage.serialize();
  }

  @override
  Future<void> start({required String alice, required String bob}) async {
    final bobAddress = SignalProtocolAddress(bob, 1);

    PreKeyBundle alicePreKeyBundle =
        await loadKeysAndSetupStore(receiverAddress: bobAddress);

    await _keyApi.storeKey(KeyObjectKeyBundleHelpers.keyObjectFromPreKeyBundle(
        name: alice, preKeyBundle: alicePreKeyBundle, timestamp: _timestamp));

    _sessionCipher = await createAliceSessionCipher(
      receiverAddress: bobAddress,
      preKey: KeyObjectKeyBundleHelpers.keyObjectToPreKeyBundle(
          keyObject: await _keyApi.fetchKey(bob)),
    );

    connectToServer();

    await _messageLoop();
  }

  Future<void> _messageLoop() async {
    String send = '';
    final Encoding encoding = Encoding.getByName('utf-8') ?? Utf8Codec();
    while (send != '!exit') {
      send = stdin.readLineSync(encoding: encoding, retainNewlines: false) ??
          '!exit';

      final m = {
        "id": _socket.id,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        'message':
            (await encryptMessage(cipher: _sessionCipher, clearText: send))
                .toList()
                .toString(),
      };

      _socket.emit('send_message', json.encode(m));
    }
  }

  void connectToServer() {
    try {
      _socket = io('http://localhost:3002/', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket.on('connect', (_) => {print('connect: ${_socket.id}')});
      _socket.on('message', _receiveHandler);
      _socket.on('disconnect', (_) => print('disconnect'));
      _socket.on('fromServer', (_) => print(_));
      _socket.connect();
    } catch (e) {
      print('Ops, something happened :(');
      print(e.toString());
    }
  }

  _receiveHandler(dynamic data) {
    Map<String, dynamic> d = json.decode(data);
    if (d['id'] != _socket.id) {
      final string =
          decryptMessage(cipher: _sessionCipher, fromServer: d['message']);
      print('$d::=> $string');
    }
  }
}
