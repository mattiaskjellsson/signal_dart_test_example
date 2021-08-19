import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:signal_example_flutter/key_api.dart';
import 'package:signal_example_flutter/persisted_keys.dart';

main() {
  group('Test that storing and retreiving an object yields the same object',
      () {
    late final keyApi = KeyApi(serverUrl: 'http://localhost:3000/');

    test('Store an object', () {});
  });
}
