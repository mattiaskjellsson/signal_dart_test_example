import 'dart:convert';

import 'package:signal_example_flutter/local_communication.dart';
import 'dart:io';

import 'communication.dart';

Future<void> main() async {
  Communication stuff = LocalCommunication();
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

class NamesHolder {
  final String alicesName;
  final String bobsName;

  NamesHolder({required this.alicesName, required this.bobsName});
}
