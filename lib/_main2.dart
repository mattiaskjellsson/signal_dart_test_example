import 'dart:convert';
import 'dart:io';

import 'local_back_and_forth.dart';
import 'communication.dart';
import 'names_holder.dart';

Future<void> main() async {
  Communication stuff = LocalBackAndForth();
  NamesHolder holder = getNames();
  stuff.start(alice: holder.alicesName, bob: holder.bobsName);
}

NamesHolder getNames() {
  final Encoding encoding = Encoding.getByName('utf-8') ?? Utf8Codec();
  print('What is your name? ');
  final aliceName =
      stdin.readLineSync(encoding: encoding, retainNewlines: false) ?? 'NoName';
  print('With who do you want to chat? ');
  final bobName =
      stdin.readLineSync(encoding: encoding, retainNewlines: false) ?? 'NoName';

  return NamesHolder(alicesName: aliceName, bobsName: bobName);
}
