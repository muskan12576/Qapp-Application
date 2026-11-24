import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Utills/app_utils.dart';
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
  String? get mediaUrl => fileUrl;
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
    this.blockedByPeer = false,
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
    this.onlyAdminsCanSend = false,
    this.myRole = 'member',
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
  bool blockedByPeer;
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
  bool onlyAdminsCanSend;
  String myRole;
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
              if (data['lastSeen'] != null) {
                t.lastSeen = DateTime.tryParse(data['lastSeen'].toString());
              }
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

        String formattedTime = '';
        if (lastMsg != null && lastMsg['time'] != null) {
          final dt = DateTime.tryParse(lastMsg['time'].toString());
          if (dt != null) {
            final local = dt.toLocal();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final msgDay = DateTime(local.year, local.month, local.day);
            if (msgDay == today) {
              formattedTime = formatMessageTime(local);
            } else if (msgDay == yesterday) {
              formattedTime = 'Yesterday';
            } else {
              formattedTime =
                  '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year.toString().substring(2)}';
            }
          } else {
            formattedTime = lastMsg['time'].toString();
          }
        }

        liveThreads.add(
          ChatThread(
            chatId: c['id']?.toString(),
            peerId: peerId,
            isGroup: isGroup,
            name: c['title']?.toString() ?? 'User',
            header: c['title']?.toString() ?? 'User',
            time: formattedTime,
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
            onlyAdminsCanSend: c['onlyAdminsCanSend'] == true,
            myRole: c['myRole']?.toString() ?? 'member',
            favourite: c['isFavorite'] == true,
            muted: c['isMuted'] == true,
            blocked: peer?['blockedByMe'] == true,
            blockedByPeer: peer?['blockedByPeer'] == true,
            wallpaperPath: c['wallpaperUrl']?.toString(),
            wallpaperColor: c['wallpaperColor'] is int
                ? c['wallpaperColor'] as int
                : (c['wallpaperColor'] != null
                    ? int.tryParse(c['wallpaperColor'].toString())
                    : null),
            messages: [],
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = prefs.getStringList('qapp_pinned_chats') ?? [];
      final blockedIds = prefs.getStringList('qapp_blocked_users') ?? [];
      final favIds = prefs.getStringList('qapp_favourite_threads') ?? [];
      final mutedIds = prefs.getStringList('qapp_muted_threads') ?? [];

      for (final lt in liveThreads) {
        final idKey = lt.chatId ?? lt.peerId ?? lt.phone;
        final isPinned = pinnedIds.contains(idKey) ||
            (lt.chatId != null && pinnedIds.contains(lt.chatId)) ||
            (lt.peerId != null && pinnedIds.contains(lt.peerId)) ||
            (lt.phone.isNotEmpty && pinnedIds.contains(lt.phone));
        if (isPinned) {
          lt.pinned = true;
        }
        if (favIds.contains(idKey)) {
          lt.favourite = true;
        }
        if (mutedIds.contains(idKey)) {
          lt.muted = true;
        }
        if (lt.peerId != null && blockedIds.contains(lt.peerId)) {
          lt.blocked = true;
        }

        // Restore saved wallpaper & theme per chat
        final wpPath = prefs.getString('qapp_wallpaper_path_$idKey');
        if (wpPath != null && wpPath.isNotEmpty) {
          lt.wallpaperPath = wpPath;
        }
        final wpColor = prefs.getInt('qapp_wallpaper_color_$idKey');
        if (wpColor != null) {
          lt.wallpaperColor = wpColor;
        }
        final thIdx = prefs.getInt('qapp_theme_idx_$idKey');
        if (thIdx != null) {
          lt.themeIndex = thIdx;
        }

        for (final existing in threads) {
          if ((lt.chatId != null && existing.chatId == lt.chatId) ||
              (lt.peerId != null && existing.peerId == lt.peerId)) {
            if (existing.messages.isNotEmpty) {
              lt.messages.clear();
              lt.messages.addAll(existing.messages);
            }
            if (existing.pinned) lt.pinned = true;
            if (existing.favourite) lt.favourite = true;
            if (existing.muted) lt.muted = true;
            if (existing.blocked) lt.blocked = true;
            if (existing.blockedByPeer) lt.blockedByPeer = true;
            if (existing.wallpaperPath != null) lt.wallpaperPath = existing.wallpaperPath;
            if (existing.wallpaperColor != null) lt.wallpaperColor = existing.wallpaperColor;
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

  Future<void> togglePin(ChatThread thread) async {
    thread.pinned = !thread.pinned;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinned = prefs.getStringList('qapp_pinned_chats') ?? [];
      final keys = [
        if (thread.chatId != null && thread.chatId!.isNotEmpty) thread.chatId!,
        if (thread.peerId != null && thread.peerId!.isNotEmpty) thread.peerId!,
        if (thread.phone.isNotEmpty) thread.phone,
      ];
      if (thread.pinned) {
        for (final k in keys) {
          if (!pinned.contains(k)) pinned.add(k);
        }
      } else {
        for (final k in keys) {
          pinned.remove(k);
        }
      }
      await prefs.setStringList('qapp_pinned_chats', pinned);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleFavourite(ChatThread thread) async {
    thread.favourite = !thread.favourite;
    try {
      final prefs = await SharedPreferences.getInstance();
      final favs = prefs.getStringList('qapp_favourite_threads') ?? [];
      final idKey = thread.chatId ?? thread.peerId ?? thread.phone;
      if (idKey.isNotEmpty) {
        if (thread.favourite) {
          if (!favs.contains(idKey)) favs.add(idKey);
        } else {
          favs.remove(idKey);
        }
        await prefs.setStringList('qapp_favourite_threads', favs);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleMute(ChatThread thread) async {
    thread.muted = !thread.muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      final muted = prefs.getStringList('qapp_muted_threads') ?? [];
      final idKey = thread.chatId ?? thread.peerId ?? thread.phone;
      if (idKey.isNotEmpty) {
        if (thread.muted) {
          if (!muted.contains(idKey)) muted.add(idKey);
        } else {
          muted.remove(idKey);
        }
        await prefs.setStringList('qapp_muted_threads', muted);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleBlock(ChatThread thread) async {
    thread.blocked = !thread.blocked;
    try {
      if (thread.peerId != null) {
        final prefs = await SharedPreferences.getInstance();
        final blocked = threads
            .where((t) => t.blocked && t.peerId != null)
            .map((t) => t.peerId!)
            .toList();
        await prefs.setStringList('qapp_blocked_users', blocked);
        if (thread.blocked) {
          await ChatViewModel.instance.blockUser(thread.peerId!);
        } else {
          await ChatViewModel.instance.unblockUser(thread.peerId!);
        }
      }
    } catch (_) {}
    notifyListeners();
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
