import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

Future<void> main() async {
  await install();
}

// Stores stuff
late InMemorySessionStore _sessionStore;
late InMemoryPreKeyStore _preKeyStore;
late InMemorySignedPreKeyStore _signedPreKeyStore;
late InMemoryIdentityKeyStore _identityStore;

late SessionCipher _sessionCipher;
late InMemorySignalProtocolStore _signalProtocolStore;
late final SessionBuilder _sessionBuilder;

class RetrevedKeys {
  final int remoteRegId;
  final IdentityKeyPair remoteIdentityKeyPair;
  final PreKeyRecord remotePreKey;
  final int remotePreKeyId;
  final SignedPreKeyRecord remoteSignedPreKey;

  RetrevedKeys(
      {required this.remoteRegId,
      required this.remoteIdentityKeyPair,
      required this.remotePreKey,
      required this.remotePreKeyId,
      required this.remoteSignedPreKey});
}

class MyKeys {
  final IdentityKeyPair identityKeyPair;
  final int registrationId;
  final List<PreKeyRecord> preKeys;
  final SignedPreKeyRecord signedPreKey;

  MyKeys(
      {required this.identityKeyPair,
      required this.registrationId,
      required this.preKeys,
      required this.signedPreKey});
}

MyKeys generateMyKeys() {
  final IdentityKeyPair identityKeyPair = generateIdentityKeyPair();
  final int registrationId = generateRegistrationId(false);
  final List<PreKeyRecord> preKeys = generatePreKeys(0, 110);
  final SignedPreKeyRecord signedPreKey =
      generateSignedPreKey(identityKeyPair, 0);

  return MyKeys(
      identityKeyPair: identityKeyPair,
      registrationId: registrationId,
      preKeys: preKeys,
      signedPreKey: signedPreKey);
}

Future<void> initStores(MyKeys myKeys) async {
  _sessionStore = InMemorySessionStore();
  _preKeyStore = InMemoryPreKeyStore();
  _signedPreKeyStore = InMemorySignedPreKeyStore();
  _identityStore =
      InMemoryIdentityKeyStore(myKeys.identityKeyPair, myKeys.registrationId);

  for (var p in myKeys.preKeys) {
    await _preKeyStore.storePreKey(p.id, p);
  }

  await _signedPreKeyStore.storeSignedPreKey(
      myKeys.signedPreKey.id, myKeys.signedPreKey);
}

Future<void> install() async {
  final myKeys = generateMyKeys();

  await initStores(myKeys);

  final SignalProtocolAddress bobAddress = SignalProtocolAddress('bob', 1);

  final retrevedKeys = await fetchRemoteKeys();
  final PreKeyBundle retrievedPreKey = PreKeyBundle(
      retrevedKeys.remoteRegId,
      1,
      retrevedKeys.remotePreKeyId,
      retrevedKeys.remotePreKey.getKeyPair().publicKey,
      retrevedKeys.remoteSignedPreKey.id,
      retrevedKeys.remoteSignedPreKey.getKeyPair().publicKey,
      retrevedKeys.remoteSignedPreKey.signature,
      retrevedKeys.remoteIdentityKeyPair.getPublicKey());

  _sessionBuilder = SessionBuilder(_sessionStore, _preKeyStore,
      _signedPreKeyStore, _identityStore, bobAddress);
  await _sessionBuilder.processPreKeyBundle(retrievedPreKey);

  _sessionCipher = SessionCipher(_sessionStore, _preKeyStore,
      _signedPreKeyStore, _identityStore, bobAddress);

  _signalProtocolStore =
      InMemorySignalProtocolStore(retrevedKeys.remoteIdentityKeyPair, 1);
  final aliceAddress = SignalProtocolAddress('alice', 1);
  final remoteSessionCipher =
      SessionCipher.fromStore(_signalProtocolStore, aliceAddress);

  for (var p in [retrevedKeys.remotePreKey]) {
    await _signalProtocolStore.storePreKey(p.id, p);
  }

  await _signalProtocolStore.storeSignedPreKey(
      retrevedKeys.remoteSignedPreKey.id, retrevedKeys.remoteSignedPreKey);

  CiphertextMessage ciphertext = await encryptText('Hello Mixin🤣');
  await receiveEncrypted(ciphertext, remoteSessionCipher);

  CiphertextMessage ciphertext2 = await encryptText('Hey hey hey');
  await receiveEncrypted(ciphertext2, remoteSessionCipher);
}

Future<RetrevedKeys> fetchRemoteKeys() {
  // Should get remote from the server
  final int remoteRegId = generateRegistrationId(false);
  final IdentityKeyPair remoteIdentityKeyPair = generateIdentityKeyPair();
  final List<PreKeyRecord> remotePreKeys = generatePreKeys(0, 110);
  final SignedPreKeyRecord remoteSignedPreKey =
      generateSignedPreKey(remoteIdentityKeyPair, 0);

  return Future.value(RetrevedKeys(
    remoteRegId: remoteRegId,
    remoteIdentityKeyPair: remoteIdentityKeyPair,
    remotePreKey: remotePreKeys[0],
    remotePreKeyId: remotePreKeys[0].id,
    remoteSignedPreKey: remoteSignedPreKey,
  ));
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

Future<CiphertextMessage> encryptText(String text) async {
  final ciphertext =
      await _sessionCipher.encrypt(Uint8List.fromList(utf8.encode(text)));
  print(ciphertext);
  print(ciphertext.serialize());

  return ciphertext;
}
