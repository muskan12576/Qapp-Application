import 'dart:convert';

import 'package:flutter/foundation.dart';

void apiLog({
  required String method,
  required Uri url,
  Map<String, String>? headers,
  Object? request,
  required int status,
  Object? response,
}) {
  if (!kDebugMode) return;
  final ok = status >= 200 && status < 400;
  final color = ok ? '\x1b[32m' : '\x1b[31m';
  const reset = '\x1b[0m';
  const dim = '\x1b[36m';
  final title = ok ? 'API CALL COMPLETED' : 'API CALL FAILED';
  debugPrint('$color$title [$method]$reset');
  debugPrint('$dim│$reset  URL: $url');
  debugPrint('$dim│$reset  Headers: ${jsonEncode(headers ?? const <String, String>{})}');
  debugPrint('$dim│$reset  Request Body: ${_clip(request)}');
  debugPrint('$dim│$reset  Status: $status');
  debugPrint('$dim│$reset  Response Body: ${_clip(response)}');
  debugPrint('$dim│$reset  ${DateTime.now().toIso8601String()}');
}

String _clip(Object? value) {
  if (value == null) return '';
  final text = value is String ? value : jsonEncode(value);
  if (text.length <= 700) return text;
  return '${text.substring(0, 700)}…';
}
