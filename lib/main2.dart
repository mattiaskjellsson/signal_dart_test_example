import 'dart:convert';

import 'package:signal_example_flutter/signal_stuff.dart';
import 'dart:io';

Future<void> main() async {
  SignalStuff stuff = SignalStuff();
  NamesHolder h = getNames();
  stuff.start(alice: h.alicesName, bob: h.bobsName);
}

class NamesHolder {
  final String alicesName;
  final String bobsName;

  NamesHolder({required this.alicesName, required this.bobsName});
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
