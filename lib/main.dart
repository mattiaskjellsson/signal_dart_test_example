import 'dart:convert';
import 'dart:io';

import 'communication.dart';
import 'names_holder.dart';
import 'server_communication.dart';

Future<void> main() async {
  try {
    Communication stuff = ServerConnection();
    NamesHolder holder = getNames();
    // NamesHolder holder = NamesHolder(alicesName: 'alice', bobsName: 'bob');
    stuff.start(alice: holder.alicesName, bob: holder.bobsName);
  } on Exception {
    print('ops');
  }
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
