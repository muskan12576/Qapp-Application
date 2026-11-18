// ignore_for_file: avoid_print

/// ✅ Debug function with optional data/context
/// Usage: debug("Message") or debug("Message", data)
void debug(dynamic message, [dynamic data]) {
  final timestamp = DateTime.now().toString().substring(11, 19);

  if (data != null) {
    print("🐛 [$timestamp] $message | $data");
  } else {
    print("🐛 [$timestamp] $message");
  }
}

/// ✅ Debug with additional context
/// Usage: debugWithContext("Message", extra: response.statusCode, tag: "API")
void debugWithContext(
  String message, {
  dynamic extra,
  String? tag,
  dynamic product,
}) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  final tagStr = tag != null ? '[$tag] ' : '';
  var details = '';

  if (product != null) {
    details += ' | $product';
  }
  if (extra != null) {
    details += ' | Extra: $extra';
  }

  print("🐛 [$timestamp] $tagStr$message$details");
}

/// ✅ Log long text in chunks (works with API responses)
void debugLog(String text) {
  final pattern = RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/// ✅ For quick debugging with multiple data
void debugAll(String message, [List<dynamic>? data]) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  if (data != null && data.isNotEmpty) {
    print("🐛 [$timestamp] $message");
    for (var item in data) {
      print("   └─ $item");
    }
  } else {
    print("🐛 [$timestamp] $message");
  }
}

/// Formats a DateTime into 12-hour time format with am/pm (e.g. 10:32 am)
String formatMessageTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final hour24 = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm = hour24 >= 12 ? 'pm' : 'am';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hourStr = hour12.toString().padLeft(2, '0');
  return '$hourStr:$minute $ampm';
}

/// Checks if two DateTimes belong to the same calendar day
bool isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Formats date for chat dividers: "Today", "Yesterday", or "14 November 2026"
String formatDateDivider(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDay = DateTime(local.year, local.month, local.day);

  if (msgDay == today) {
    return 'Today';
  } else if (msgDay == yesterday) {
    return 'Yesterday';
  }

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Formats "Last seen today at 10:30 am", "Last seen yesterday at 4:15 pm", etc.
String formatLastSeen(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final seenDay = DateTime(local.year, local.month, local.day);
  final timeStr = formatMessageTime(local);

  if (seenDay == today) {
    return 'today at $timeStr';
  } else if (seenDay == yesterday) {
    return 'yesterday at $timeStr';
  } else {
    return '${local.day}/${local.month}/${local.year} at $timeStr';
  }
}

