import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:signal_example_flutter/key_server/key_object.dart';
import 'package:fixnum/fixnum.dart';

class KeyObjectKeyBundleHelpers {
  static PreKeyBundle keyObjectToPreKeyBundle({required KeyObject keyObject}) {
    return PreKeyBundle(
        keyObject.registrationId,
        keyObject.deviceId,
        keyObject.preKeyId,
        Curve.decodePoint(keyObject.preKey, 0),
        keyObject.signedPreKeyId,
        Curve.decodePoint(keyObject.signedPreKey, 0),
        keyObject.signedPreKeySignature,
        IdentityKey.fromBytes(keyObject.identityKeyPair, 0));
  }

  static KeyObject keyObjectFromPreKeyBundle(
      {required String name,
      required PreKeyBundle preKeyBundle,
      required Int64 timestamp}) {
    return KeyObject(
      username: name,
      identityKeyPair: preKeyBundle.getIdentityKey().publicKey.serialize(),
      deviceId: preKeyBundle.getDeviceId(),
      preKeyId: preKeyBundle.getPreKeyId(),
      preKey: preKeyBundle.getPreKey().serialize(),
      signedPreKeyId: preKeyBundle.getSignedPreKeyId(),
      signedPreKey: preKeyBundle.getSignedPreKey()!.serialize(),
      registrationId: preKeyBundle.getRegistrationId(),
      timestamp: timestamp,
      signedPreKeySignature: preKeyBundle.getSignedPreKeySignature(),
    );
  }
}
