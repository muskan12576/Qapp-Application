import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';

enum ChatKind { text, image, pdf, doc, audio, video, contact, location }

enum Tick { sent, delivered, read }

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.mine,
    this.id,
    this.clientId,
    this.senderId,
    this.senderName,
    this.fileUrl,
    this.time,
    this.createdAt,
    this.kind = ChatKind.text,
    this.bytes,
    this.asset,
    this.path,
    this.tick = Tick.read,
    this.starred = false,
    this.replyId,
    this.replyName,
    this.replyText,
    this.deleted = false,
    this.forwarded = false,
    this.reactions,
  });

  String? id;
  String? clientId;
  final String? senderId;
  final String? senderName;
  String? fileUrl;
  final String text;
  final bool mine;
  String? time;
  DateTime? createdAt;
  ChatKind kind;
  final Uint8List? bytes;
  final String? asset;
  final String? path;
  final String? replyId;
  final String? replyName;
  final String? replyText;
  Tick tick;
  bool starred;
  bool deleted;
  bool forwarded;
  Map<String, String>? reactions;
}

class ChatThread {
  ChatThread({
    required this.name,
    required this.header,
    required this.time,
    required this.preview,
    required this.colorIndex,
    required this.messages,
    required this.phone,
    required this.about,
    this.photo,
    this.photoBytes,
    this.unread = 0,
    this.favourite = false,
    this.pinned = false,
    this.muted = false,
    this.blocked = false,
    this.groups = const [],
    this.disappear = 'off',
    this.themeIndex = 0,
    this.wallpaperPath,
    this.wallpaperColor,
    this.listName,
    this.online = false,
    this.isTyping = false,
    this.typingUserName,
    this.chatId,
    this.peerId,
    this.photoUrl,
    this.isGroup = false,
    this.lastSeen,
  });

  final String name;
  final String header;
  final int colorIndex;
  final String phone;
  final String about;
  final String? photo;
  final Uint8List? photoBytes;
  final List<ChatMessage> messages;
  final List<String> groups;

  String time;
  String preview;
  int unread;
  bool favourite;
  bool pinned;
  bool muted;
  bool blocked;
  String disappear;
  int themeIndex;
  String? wallpaperPath;
  int? wallpaperColor;
  String? listName;
  bool online;
  bool isTyping;
  String? typingUserName;
  Timer? typingTimer;
  String? chatId;
  final String? peerId;
  final String? photoUrl;
  final bool isGroup;
  DateTime? lastSeen;
}

class MyProfile {
  static Uint8List? photo;
  static String name = '';
  static String bio = '';
}

class ShareContact {
  const ShareContact(this.name, this.phone, this.colorIndex, {this.photo});

  final String name;
  final String phone;
  final int colorIndex;
  final String? photo;
}

// No static dummy contacts
const shareContacts = <ShareContact>[];

class ChatBook extends ChangeNotifier {
  ChatBook._();

  static final ChatBook instance = ChatBook._();

  // No static mock threads: starts completely empty, loads only real data from APIs!
  final List<ChatThread> threads = [];
  final List<Map<String, dynamic>> peers = [];

  void ping() => notifyListeners();

  bool _liveInitialized = false;

  Future<void> loadLiveChats() async {
    try {
      await ChatSocketService.instance.connect();

      if (!_liveInitialized) {
        _liveInitialized = true;
        ChatSocketService.instance.onMessage.listen((msg) {
          final chatId = msg['chatId']?.toString();
          final senderId = msg['senderId']?.toString();
          final senderName = msg['senderName']?.toString();
          final body = msg['body']?.toString() ?? '';
          final currentUserId = TokenStorage.instance.userId;
          final isMine =
              (senderId != null && senderId == currentUserId) ||
              msg['mine'] == true;

          ChatThread? found;
          // STRICT MATCH: If incoming message has chatId, match ONLY thread with same chatId
          if (chatId != null) {
            for (final t in threads) {
              if (t.chatId != null && t.chatId == chatId) {
                found = t;
                break;
              }
            }
          } else {
            // Only fallback to peerId if chatId is null and thread is direct (NOT a group)
            for (final t in threads) {
              if (!t.isGroup &&
                  t.chatId == null &&
                  t.peerId != null &&
                  t.peerId == senderId) {
                found = t;
                break;
              }
            }
          }

          if (found != null) {
            found.chatId = chatId ?? found.chatId;
            found.preview =
                (found.isGroup &&
                    senderName != null &&
                    senderName.isNotEmpty &&
                    !isMine)
                ? '$senderName: $body'
                : body;
            found.time = 'Now';
            if (!isMine) {
              found.unread += 1;
            }
            final serverMsgId = msg['id']?.toString();
            final clientId = msg['clientId']?.toString();
            final alreadyIn = found.messages.any(
              (m) =>
                  (serverMsgId != null && m.id == serverMsgId) ||
                  (clientId != null && m.clientId == clientId),
            );
            if (!alreadyIn) {
              final rawFile = msg['file'] ?? msg['fileInfo'];
              final fileUrl = rawFile is Map
                  ? (rawFile['url']?.toString() ?? rawFile['path']?.toString())
                  : null;
              final kindStr = msg['kind']?.toString() ?? 'text';
              final kind = kindStr == 'image'
                  ? ChatKind.image
                  : (kindStr == 'video'
                        ? ChatKind.video
                        : (kindStr == 'audio'
                              ? ChatKind.audio
                              : (kindStr == 'document'
                                    ? ChatKind.pdf
                                    : ChatKind.text)));

              found.messages.add(
                ChatMessage(
                  id: serverMsgId,
                  clientId: clientId,
                  text: body,
                  mine: isMine,
                  senderName: senderName,
                  senderId: senderId,
                  kind: kind,
                  fileUrl: fileUrl,
                  time: 'Now',
                  createdAt: DateTime.now(),
                  tick: isMine ? Tick.sent : Tick.delivered,
                ),
              );
            }
            threads.remove(found);
            threads.insert(0, found);
            notifyListeners();
          } else {
            loadLiveChats();
          }
        });

        ChatSocketService.instance.onDelivered.listen((data) {
          final chatId = data['chatId']?.toString();
          final messageId = data['messageId']?.toString();
          for (final t in threads) {
            if (t.chatId == chatId) {
              for (final m in t.messages) {
                if (m.mine &&
                    (messageId == null || m.id == messageId) &&
                    m.tick == Tick.sent) {
                  m.tick = Tick.delivered;
                }
              }
            }
          }
          notifyListeners();
        });

        ChatSocketService.instance.onRead.listen((data) {
          final chatId = data['chatId']?.toString();
          for (final t in threads) {
            if (t.chatId == chatId) {
              for (final m in t.messages) {
                if (m.mine) {
                  m.tick = Tick.read;
                }
              }
            }
          }
          notifyListeners();
        });

        ChatSocketService.instance.onTyping.listen((data) {
          final chatId = data['chatId']?.toString();
          final senderId =
              data['senderId']?.toString() ?? data['userId']?.toString();
          final userName = data['userName']?.toString();
          for (final t in threads) {
            final match =
                (chatId != null && t.chatId == chatId) ||
                (chatId == null &&
                    senderId != null &&
                    !t.isGroup &&
                    t.peerId == senderId);
            if (match) {
              t.isTyping = true;
              t.typingUserName = userName;
              t.typingTimer?.cancel();
              t.typingTimer = Timer(const Duration(seconds: 4), () {
                t.isTyping = false;
                t.typingUserName = null;
                notifyListeners();
              });
              notifyListeners();
              break;
            }
          }
        });

        ChatSocketService.instance.onStopTyping.listen((data) {
          final chatId = data['chatId']?.toString();
          final senderId =
              data['senderId']?.toString() ?? data['userId']?.toString();
          for (final t in threads) {
            final match =
                (chatId != null && t.chatId == chatId) ||
                (chatId == null &&
                    senderId != null &&
                    !t.isGroup &&
                    t.peerId == senderId);
            if (match) {
              t.typingTimer?.cancel();
              t.isTyping = false;
              t.typingUserName = null;
              notifyListeners();
              break;
            }
          }
        });

        ChatSocketService.instance.onUserOnline.listen((data) {
          final uId = data['userId']?.toString();
          for (final t in threads) {
            if (t.peerId == uId) {
              t.online = true;
            }
          }
          notifyListeners();
        });

        ChatSocketService.instance.onUserOffline.listen((data) {
          final uId = data['userId']?.toString();
          for (final t in threads) {
            if (t.peerId == uId) {
              t.online = false;
            }
          }
          notifyListeners();
        });
      }

      final convos = await ChatViewModel.instance.getConversations();
      final peersList = await ChatViewModel.instance.getPeers();
      peers.clear();
      peers.addAll(peersList);

      final liveThreads = <ChatThread>[];

      for (var i = 0; i < convos.length; i++) {
        final c = convos[i];
        final isGroup = c['kind'] == 'group';
        final peer = c['peer'] as Map<String, dynamic>?;
        final peerId = peer?['id']?.toString();

        final lastMsg = c['lastMessage'] as Map<String, dynamic>?;

        liveThreads.add(
          ChatThread(
            chatId: c['id']?.toString(),
            peerId: peerId,
            isGroup: isGroup,
            name: c['title']?.toString() ?? 'User',
            header: c['title']?.toString() ?? 'User',
            time: lastMsg?['time'] != null ? 'Active' : '',
            preview: lastMsg?['body']?.toString() ?? 'Tap to chat',
            colorIndex: i % 5,
            phone: peer?['phone']?.toString() ?? '',
            about: peer?['about']?.toString() ?? '',
            photo: c['photoUrl']?.toString() ?? peer?['photoUrl']?.toString(),
            unread: c['unreadCount'] is int ? c['unreadCount'] as int : 0,
            online: peer?['isOnline'] == true,
            lastSeen: peer?['lastSeen'] != null
                ? DateTime.tryParse(peer!['lastSeen'].toString())
                : null,
            messages: [],
          ),
        );
      }

      for (final lt in liveThreads) {
        for (final existing in threads) {
          if ((lt.chatId != null && existing.chatId == lt.chatId) ||
              (lt.peerId != null && existing.peerId == lt.peerId)) {
            if (existing.messages.isNotEmpty) {
              lt.messages.clear();
              lt.messages.addAll(existing.messages);
            }
            break;
          }
        }
      }
      threads.clear();
      threads.addAll(liveThreads);
      notifyListeners();
    } catch (err) {
      debugPrint('[ChatBook] Error loading live chats: $err');
    }
  }

  void add(ChatThread thread) {
    threads.insert(0, thread);
    notifyListeners();
  }

  void remove(ChatThread thread) {
    threads.remove(thread);
    notifyListeners();
  }
}

class DemoPerson {
  const DemoPerson(this.name, this.colorIndex, {this.photo, this.caption = ''});

  final String name;
  final int colorIndex;
  final String? photo;
  final String caption;
}

class StatusUpdate {
  StatusUpdate({required this.caption, required this.time, this.bytes});

  final String caption;
  final String time;
  final Uint8List? bytes;
}

class StatusBook extends ChangeNotifier {
  StatusBook._();

  static final StatusBook instance = StatusBook._();

  final List<StatusUpdate> mine = [];

  void add(StatusUpdate update) {
    mine.insert(0, update);
    notifyListeners();
  }
}

class DemoCall {
  const DemoCall(this.name, this.time);

  final String name;
  final String time;
}

// No static mock friends or call history
const statusFriends = <DemoPerson>[];
const callHistory = <DemoCall>[];

ChatThread? threadFor(String name) {
  for (final thread in ChatBook.instance.threads) {
    if (thread.name == name || thread.header == name) {
      return thread;
    }
  }
  return null;
}
