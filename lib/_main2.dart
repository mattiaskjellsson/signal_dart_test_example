import 'package:signal_example_flutter/workers/communication.dart';
import 'package:signal_example_flutter/workers/local_back_and_forth.dart';
import 'helpers/get_names.dart';
import 'helpers/names_holder.dart';

Future<void> main() async {
  Communication stuff = LocalBackAndForth();
  NamesHolder holder = GetNames()();
  stuff.start(alice: holder.alicesName, bob: holder.bobsName);
}
