import 'dart:async';
import 'dart:convert';
import 'dart:io';

class StdIoHelper {
  Stream<String> _stdinLineStreamBroadcaster;
  StdIoHelper()
      : _stdinLineStreamBroadcaster = stdin
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

  /// Reads a single line from [stdin] asynchronously.
  Future<String> readStdinLine() async {
    var lineCompleter = Completer<String>();

    var listener = _stdinLineStreamBroadcaster.listen((line) {
      if (!lineCompleter.isCompleted) {
        lineCompleter.complete(line);
      }
    });

    return lineCompleter.future.then((line) {
      listener.cancel();
      return line;
    });
  }
}
