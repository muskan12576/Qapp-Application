import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/widgets/chat_media_bubble.dart';

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
    } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
      final fullUrl = resolveMediaUrl(message.fileUrl!);
      final raw = message.text.trim().isEmpty
          ? (message.fileUrl!.split('/').last)
          : message.text.trim();
      var safe = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      if (message.kind == ChatKind.pdf && !safe.toLowerCase().endsWith('.pdf')) {
        safe = '$safe.pdf';
      }
      final tempPath = '${Directory.systemTemp.path}${Platform.pathSeparator}$safe';
      final candidate = File(tempPath);
      if (candidate.existsSync() && candidate.lengthSync() > 0) {
        file = candidate;
      } else {
        final res = await http.get(Uri.parse(fullUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          await candidate.writeAsBytes(res.bodyBytes, flush: true);
          file = candidate;
        }
      }
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
  } catch (e) {
    debugPrint('Error opening chat file: $e');
  }
}
