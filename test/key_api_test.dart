import 'package:flutter_test/flutter_test.dart';
import 'package:signal_example_flutter/key_server/key_api.dart';

main() {
  group('Test that storing and retreiving an object yields the same object',
      () {
    late final keyApi = KeyApi(serverUrl: 'http://localhost:3000/');

    test('Store an object', () {});
  });
}
