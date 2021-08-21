import 'dart:convert';
import 'dart:io';

import 'names_holder.dart';

class GetNames {
  NamesHolder call() {
    final Encoding encoding = Encoding.getByName('utf-8') ?? Utf8Codec();
    print('What is your name? ');
    final aliceName =
        stdin.readLineSync(encoding: encoding, retainNewlines: false) ??
            'NoName';
    print('With who do you want to chat? ');
    final bobName =
        stdin.readLineSync(encoding: encoding, retainNewlines: false) ??
            'NoName';

    return NamesHolder(alicesName: aliceName, bobsName: bobName);
  }
}
