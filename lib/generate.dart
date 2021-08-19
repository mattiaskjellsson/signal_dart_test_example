import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:fixnum/fixnum.dart';

void main() async {
  ECKeyPair generatedKey = Curve.generateKeyPair();
  ECKeyPair preKeyPair = Curve.generateKeyPair();
  ECKeyPair signedPreKeyPair = Curve.generateKeyPair();
  int deviceId = 1;
  int preKeyId = 31337;
  int signedPreKeyId = 22;
  print('{');
  print(
      '"generatedPublicKey": ${generatedKey.publicKey.serialize().toString()},');
  print(
      '"generatedPrivateKey": ${generatedKey.privateKey.serialize().toString()},');

  print(
      '"preKeyPairPublicKey": ${preKeyPair.publicKey.serialize().toString()},');
  print(
      '"preKeyPairPrivateKey": ${preKeyPair.privateKey.serialize().toString()},');

  print(
      '"signedPreKeyPairPublicKey": ${signedPreKeyPair.publicKey.serialize().toString()},');
  print(
      '"signedPreKeyPairPrivateKey": ${signedPreKeyPair.privateKey.serialize().toString()},');

  print('"deviceId": ${deviceId.toString()},');
  print('"preKeyId": ${preKeyId.toString()},');
  print('"signedPreKeyId": ${signedPreKeyId.toString()}');
  print('"timestamp": ${Int64(DateTime.now().millisecondsSinceEpoch)}');
  print('}');
}
