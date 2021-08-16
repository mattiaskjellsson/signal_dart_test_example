import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

Future<void> main() async {
  await install();
}

late SessionCipher _sessionCipher;
late InMemorySignalProtocolStore _signalProtocolStore;

class RetrevedKeys {
  final int remoteRegId;
  final IdentityKeyPair remoteIdentityKeyPair;
  final List<PreKeyRecord> remotePreKeys;
  final SignedPreKeyRecord remoteSignedPreKey;

  RetrevedKeys(
      {required this.remoteRegId,
      required this.remoteIdentityKeyPair,
      required this.remotePreKeys,
      required this.remoteSignedPreKey});
}

Future<void> install() async {
  final IdentityKeyPair identityKeyPair = generateIdentityKeyPair();
  final int registrationId = generateRegistrationId(false);

  final List<PreKeyRecord> preKeys = generatePreKeys(0, 110);

  final SignedPreKeyRecord signedPreKey =
      generateSignedPreKey(identityKeyPair, 0);

  final InMemorySessionStore sessionStore = InMemorySessionStore();
  final InMemoryPreKeyStore preKeyStore = InMemoryPreKeyStore();
  final InMemorySignedPreKeyStore signedPreKeyStore =
      InMemorySignedPreKeyStore();
  final InMemoryIdentityKeyStore identityStore =
      InMemoryIdentityKeyStore(identityKeyPair, registrationId);

  for (var p in preKeys) {
    await preKeyStore.storePreKey(p.id, p);
  }

  await signedPreKeyStore.storeSignedPreKey(signedPreKey.id, signedPreKey);

  final SignalProtocolAddress bobAddress = SignalProtocolAddress('bob', 1);
  final SessionBuilder sessionBuilder = SessionBuilder(
      sessionStore, preKeyStore, signedPreKeyStore, identityStore, bobAddress);

  final retrevedKeys = await fetchRemoteKeys();

  final PreKeyBundle retrievedPreKey = PreKeyBundle(
      retrevedKeys.remoteRegId,
      1,
      retrevedKeys.remotePreKeys[0].id,
      retrevedKeys.remotePreKeys[0].getKeyPair().publicKey,
      retrevedKeys.remoteSignedPreKey.id,
      retrevedKeys.remoteSignedPreKey.getKeyPair().publicKey,
      retrevedKeys.remoteSignedPreKey.signature,
      retrevedKeys.remoteIdentityKeyPair.getPublicKey());

  await sessionBuilder.processPreKeyBundle(retrievedPreKey);

  _sessionCipher = SessionCipher(
      sessionStore, preKeyStore, signedPreKeyStore, identityStore, bobAddress);

  _signalProtocolStore =
      InMemorySignalProtocolStore(retrevedKeys.remoteIdentityKeyPair, 1);
  final aliceAddress = SignalProtocolAddress('alice', 1);
  final remoteSessionCipher =
      SessionCipher.fromStore(_signalProtocolStore, aliceAddress);

  for (var p in retrevedKeys.remotePreKeys) {
    await _signalProtocolStore.storePreKey(p.id, p);
  }

  await _signalProtocolStore.storeSignedPreKey(
      retrevedKeys.remoteSignedPreKey.id, retrevedKeys.remoteSignedPreKey);

  CiphertextMessage ciphertext = await encryptText('Hello Mixin🤣');

  await receiveEncrypted(ciphertext, remoteSessionCipher);
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
    remotePreKeys: remotePreKeys,
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
