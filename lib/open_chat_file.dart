import 'dart:io';

import 'package:flutter/services.dart';
import 'package:qapp/data/demo_data.dart';

Future<void> openChatFile(ChatMessage message) async {
  try {
    File? file;
    final given = message.path;
    if (given != null && given.isNotEmpty && File(given).existsSync()) {
      file = File(given);
    } else if (message.bytes != null && message.bytes!.isNotEmpty) {
      final raw = message.text.trim().isEmpty ? 'file' : message.text.trim();
      final safe = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      file = File('${Directory.systemTemp.path}${Platform.pathSeparator}$safe');
      await file.writeAsBytes(message.bytes!, flush: true);
    }
    if (file == null) {
      return;
    }
    if (Platform.isAndroid) {
      await const MethodChannel('qapp/open_file').invokeMethod<bool>('open', {
        'path': file.path,
      });
      return;
    }
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    }
  } catch (_) {}
}
