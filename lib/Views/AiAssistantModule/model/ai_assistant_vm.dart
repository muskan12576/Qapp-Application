import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';
import 'package:qapp/data/demo_data.dart';

enum AiIntent { shareLocation, sendMessage, voiceCall, videoCall, unknown }

class AiCommandResult {
  final AiIntent intent;
  final String? contactName;
  final ChatThread? matchedThread;
  final String? messageText;
  final String? durationText;
  final int durationHours;
  final String rawQuery;
  final String explanation;

  AiCommandResult({
    required this.intent,
    this.contactName,
    this.matchedThread,
    this.messageText,
    this.durationText,
    this.durationHours = 1,
    required this.rawQuery,
    required this.explanation,
  });
}

class AiAssistantViewModel extends BaseViewModel {
  AiAssistantViewModel._();
  static final AiAssistantViewModel instance = AiAssistantViewModel._();

  ChatThread? findDefaultThread() {
    final threads = ChatBook.instance.threads;
    if (threads.isNotEmpty) return threads.first;
    return null;
  }

  AiCommandResult parseCommand(String input) {
    final clean = input.trim();
    final lower = clean.toLowerCase();

    // 1. Detect Intent
    AiIntent intent = AiIntent.unknown;
    int durationHours = 1;
    String durationText = '1 hour';

    if (lower.contains('location') ||
        lower.contains('jagah') ||
        lower.contains('address')) {
      intent = AiIntent.shareLocation;
      if (lower.contains('24 hour') ||
          lower.contains('24 ghante') ||
          lower.contains('1 din')) {
        durationHours = 24;
        durationText = '24 hours';
      } else if (lower.contains('8 hour') || lower.contains('8 ghante')) {
        durationHours = 8;
        durationText = '8 hours';
      } else {
        durationHours = 1;
        durationText = '1 hour';
      }
    } else if (lower.contains('video call') || lower.contains('video')) {
      intent = AiIntent.videoCall;
    } else if (lower.contains('call') || lower.contains('phone')) {
      intent = AiIntent.voiceCall;
    } else if (lower.contains('message') ||
        lower.contains('bhej') ||
        lower.contains('bol') ||
        lower.contains('msg')) {
      intent = AiIntent.sendMessage;
    }

    // 2. Find target contact
    ChatThread? matchedThread;
    String? matchedName;

    final allThreads = ChatBook.instance.threads;
    for (final thread in allThreads) {
      final name = thread.name.toLowerCase();
      if (lower.contains(name) ||
          (name.contains(' ') && lower.contains(name.split(' ').first))) {
        matchedThread = thread;
        matchedName = thread.name;
        break;
      }
    }

    // If not in direct threads, check peers
    if (matchedThread == null) {
      for (final peer in ChatBook.instance.peers) {
        final pName = (peer['name']?.toString() ?? '').toLowerCase();
        if (pName.isNotEmpty &&
            (lower.contains(pName) ||
                (pName.contains(' ') &&
                    lower.contains(pName.split(' ').first)))) {
          matchedName = peer['name']?.toString();
          final tName = matchedName ?? 'User';
          matchedThread = ChatThread(
            name: tName,
            header: tName,
            colorIndex: 1,
            phone: peer['phone']?.toString() ?? '',
            about: peer['about']?.toString() ?? '',
            time: 'Now',
            preview: '',
            peerId: peer['id']?.toString(),
            messages: [],
          );
          break;
        }
      }
    }

    // 3. Extract message text if intent is message
    String? messageText;
    if (intent == AiIntent.sendMessage) {
      // Strip common prefixes
      final pattern = RegExp(
        r'(bhejo|bhej do|bol do|likho|ki)\s+(.*)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(clean);
      if (match != null && match.groupCount >= 2) {
        messageText = match.group(2)?.trim();
      } else {
        messageText = clean;
      }
    }

    String explanation;
    if (intent == AiIntent.shareLocation) {
      explanation = matchedName != null
          ? '$matchedName ko aapki live location ($durationText ke liye) share ki jayegi.'
          : 'Live location ($durationText) share ki jayegi.';
    } else if (intent == AiIntent.sendMessage) {
      explanation = matchedName != null
          ? '$matchedName ko message bheja jayega: "${messageText ?? ''}"'
          : 'Message bheja jayega.';
    } else if (intent == AiIntent.voiceCall) {
      explanation = matchedName != null
          ? '$matchedName ko voice call connect ki jayegi.'
          : 'Voice call shuru hogi.';
    } else if (intent == AiIntent.videoCall) {
      explanation = matchedName != null
          ? '$matchedName ko video call connect ki jayegi.'
          : 'Video call shuru hogi.';
    } else {
      explanation = 'Aap location, message ya call command bol sakte hain.';
    }

    return AiCommandResult(
      intent: intent,
      contactName: matchedName,
      matchedThread: matchedThread,
      messageText: messageText,
      durationText: durationText,
      durationHours: durationHours,
      rawQuery: clean,
      explanation: explanation,
    );
  }

  Future<bool> executeCommand(AiCommandResult cmd) async {
    final thread = cmd.matchedThread;
    if (thread == null) return false;

    // Ensure chat ID exists
    String? chatId = thread.chatId;
    if (chatId == null && thread.peerId != null) {
      final direct = await ChatViewModel.instance.openDirectChat(
        thread.peerId!,
      );
      if (direct != null && direct['id'] != null) {
        chatId = direct['id'].toString();
        thread.chatId = chatId;
      }
    }

    if (chatId == null) return false;

    if (cmd.intent == AiIntent.shareLocation) {
      final locationUrl =
          'https://maps.google.com/?q=26.4499,74.6399&live=1&exp=${cmd.durationHours}h';
      final sent = await ChatViewModel.instance.sendMessage(
        chatId,
        body: locationUrl,
        kind: 'location',
      );

      final now = DateTime.now();
      final msg = ChatMessage(
        id: sent?['id']?.toString(),
        text: locationUrl,
        mine: true,
        time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        createdAt: now,
        kind: ChatKind.location,
        tick: Tick.sent,
      );
      thread.messages.add(msg);
      thread.preview = '📍 Live Location (${cmd.durationText})';
      ChatBook.instance.ping();
      return true;
    } else if (cmd.intent == AiIntent.sendMessage &&
        cmd.messageText != null &&
        cmd.messageText!.isNotEmpty) {
      final sent = await ChatViewModel.instance.sendMessage(
        chatId,
        body: cmd.messageText!,
        kind: 'text',
      );

      final now = DateTime.now();
      final msg = ChatMessage(
        id: sent?['id']?.toString(),
        text: cmd.messageText!,
        mine: true,
        time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        createdAt: now,
        kind: ChatKind.text,
        tick: Tick.sent,
      );
      thread.messages.add(msg);
      thread.preview = cmd.messageText!;
      ChatBook.instance.ping();
      return true;
    }

    return false;
  }
}
