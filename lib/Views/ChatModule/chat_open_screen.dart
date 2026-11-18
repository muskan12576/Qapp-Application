import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Services/chat_audio_service.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Views/CallModule/video_call_screen.dart';
import 'package:qapp/Views/CallModule/voice_call_screen.dart';
import 'package:qapp/Views/ChatModule/contact_screen.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/open_chat_file.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/chat_media_bubble.dart';
import 'package:qapp/widgets/pulsing_online_dot.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/tick_mark.dart';

class _Pending {
  _Pending(this.name, this.kind, this.bytes, [this.path]);

  final String name;
  final ChatKind kind;
  final Uint8List? bytes;
  final String? path;
}

class ChatOpenScreen extends StatefulWidget {
  const ChatOpenScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  State<ChatOpenScreen> createState() => _ChatOpenScreenState();
}

class _ChatOpenScreenState extends State<ChatOpenScreen> {
  final _controller = TextEditingController();
  final _find = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();
  final _pending = <_Pending>[];
  var _finding = false;
  var _recording = false;
  var _recSeconds = 0;
  Timer? _recTimer;
  ChatMessage? _reply;
  String? _pendingVoicePath;
  int _pendingVoiceSeconds = 0;

  List<ChatMessage> get _messages => widget.thread.messages;

  StreamSubscription? _msgSub;
  StreamSubscription? _delivSub;
  StreamSubscription? _readSub;
  StreamSubscription? _onlineSub;
  StreamSubscription? _offlineSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _stopTypingSub;
  StreamSubscription? _reactionSub;
  Timer? _peerTypingTimer;
  bool _peerTyping = false;
  String? _peerTypingName;
  Timer? _stopTypingDebounce;
  bool _isTypingActive = false;

  @override
  void initState() {
    super.initState();
    // Snap immediately to bottom (last message) without showing top
    _jumpToEndImmediate();
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _jumpToEndImmediate();
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _jumpToEndImmediate();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _jumpToEndImmediate();
    });
    _initLiveChat();
  }

  void _initLiveChat() async {
    final thread = widget.thread;
    if (thread.chatId == null && thread.peerId != null) {
      final chat = await ChatViewModel.instance.openDirectChat(thread.peerId!);
      if (chat != null && chat['id'] != null) {
        thread.chatId = chat['id'].toString();
      }
    }

    final chatId = thread.chatId;
    if (chatId != null) {
      ChatSocketService.instance.joinChat(chatId);
      ChatViewModel.instance.markAsRead(chatId);

      // Load messages from PostgreSQL
      final rawMsgs = await ChatViewModel.instance.getMessages(chatId);
      if (mounted && rawMsgs.isNotEmpty) {
        setState(() {
          thread.messages.clear();
          for (final m in rawMsgs) {
            final tickStr = m['tick']?.toString() ?? 'sent';
            Tick tick = Tick.sent;
            if (tickStr == 'read') {
              tick = Tick.read;
            } else if (tickStr == 'delivered') {
              tick = Tick.delivered;
            }

            final kindStr = m['kind']?.toString() ?? 'text';
            final body = m['body']?.toString() ?? '';
            final rawFile = m['file'] ?? m['fileInfo'];
            final Map<String, dynamic>? fileMap = rawFile is Map
                ? Map<String, dynamic>.from(rawFile)
                : null;
            final fileUrl =
                fileMap?['url']?.toString() ??
                fileMap?['path']?.toString() ??
                (m['file_url']?.toString() ??
                    m['fileUrl']?.toString() ??
                    m['url']?.toString());

            ChatKind kind = ChatKind.text;
            if (kindStr == 'audio' ||
                isAudioUrl(body) ||
                (fileUrl != null && isAudioUrl(fileUrl))) {
              kind = ChatKind.audio;
            } else if (kindStr == 'video' ||
                isVideoUrl(body) ||
                (fileUrl != null && isVideoUrl(fileUrl))) {
              kind = ChatKind.video;
            } else if (kindStr == 'image' ||
                isImageUrl(body) ||
                (fileUrl != null && isImageUrl(fileUrl))) {
              kind = ChatKind.image;
            } else if (kindStr == 'location' || isLocationUrl(body)) {
              kind = ChatKind.location;
            } else if (kindStr == 'document' ||
                kindStr == 'file' ||
                (fileUrl != null && fileUrl.endsWith('.pdf'))) {
              kind = ChatKind.pdf;
            }

            final createdDate =
                DateTime.tryParse(m['createdDate']?.toString() ?? '') ??
                DateTime.now();
            final timeStr = formatMessageTime(createdDate);

            Map<String, String>? reactionsMap;
            final rawRx = m['reactions'];
            if (rawRx is List) {
              reactionsMap = {};
              for (final r in rawRx) {
                if (r is Map && r['userId'] != null && r['reaction'] != null) {
                  reactionsMap[r['userId'].toString()] = r['reaction'].toString();
                }
              }
            } else if (rawRx is Map) {
              reactionsMap = rawRx.map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              );
            }

            thread.messages.add(
              ChatMessage(
                id: m['id']?.toString(),
                clientId: m['clientId']?.toString(),
                senderId:
                    m['senderId']?.toString() ?? m['sender_id']?.toString(),
                senderName:
                    m['senderName']?.toString() ?? m['sender_name']?.toString(),
                text: body,
                mine: m['mine'] == true,
                time: timeStr,
                createdAt: createdDate,
                kind: kind,
                fileUrl: fileUrl,
                tick: tick,
                replyId: m['reply']?['id']?.toString(),
                replyText: m['reply']?['body']?.toString(),
                replyName: m['reply']?['senderName']?.toString(),
                reactions: reactionsMap,
              ),
            );
          }
        });
        _jumpToEndImmediate();
        Future.delayed(const Duration(milliseconds: 60), () {
          if (mounted) _jumpToEndImmediate();
        });
      }
    }

    _msgSub = ChatSocketService.instance.onMessage.listen((msg) {
      final msgChatId = msg['chatId']?.toString();
      final msgSenderId = msg['senderId']?.toString();

      final bool matches;
      if (thread.chatId != null) {
        matches = (msgChatId != null && msgChatId == thread.chatId);
      } else if (!thread.isGroup && thread.peerId != null) {
        matches = (msgSenderId == thread.peerId);
        if (matches && msgChatId != null) {
          thread.chatId = msgChatId;
          ChatSocketService.instance.joinChat(msgChatId);
        }
      } else {
        matches = false;
      }

      if (!matches) return;

      if (thread.chatId == null && msgChatId != null) {
        thread.chatId = msgChatId;
        ChatSocketService.instance.joinChat(msgChatId);
      }

      final serverMsgId = msg['id']?.toString();
      final clientId = msg['clientId']?.toString();
      final currentUserId = TokenStorage.instance.userId;
      final isMine =
          (msgSenderId != null && msgSenderId == currentUserId) ||
          msg['mine'] == true;

      final kindStr = msg['kind']?.toString() ?? 'text';
      final body = msg['body']?.toString() ?? '';
      final rawFile = msg['file'] ?? msg['fileInfo'];
      final Map<String, dynamic>? fileMap = rawFile is Map
          ? Map<String, dynamic>.from(rawFile)
          : null;
      final fileUrl =
          fileMap?['url']?.toString() ??
          fileMap?['path']?.toString() ??
          (msg['file_url']?.toString() ??
              msg['fileUrl']?.toString() ??
              msg['url']?.toString());

      ChatKind kind = ChatKind.text;
      if (kindStr == 'audio' ||
          isAudioUrl(body) ||
          (fileUrl != null && isAudioUrl(fileUrl))) {
        kind = ChatKind.audio;
      } else if (kindStr == 'video' ||
          isVideoUrl(body) ||
          (fileUrl != null && isVideoUrl(fileUrl))) {
        kind = ChatKind.video;
      } else if (kindStr == 'image' ||
          isImageUrl(body) ||
          (fileUrl != null && isImageUrl(fileUrl))) {
        kind = ChatKind.image;
      } else if (kindStr == 'location' || isLocationUrl(body)) {
        kind = ChatKind.location;
      } else if (kindStr == 'document' ||
          kindStr == 'file' ||
          (fileUrl != null && fileUrl.endsWith('.pdf'))) {
        kind = ChatKind.pdf;
      }

      final createdDate =
          DateTime.tryParse(msg['createdDate']?.toString() ?? '') ??
          DateTime.now();
      final timeStr = formatMessageTime(createdDate);

      if (mounted) {
        setState(() {
          final existingIdx = thread.messages.indexWhere(
            (m) =>
                (clientId != null && m.clientId == clientId) ||
                (serverMsgId != null && m.id == serverMsgId),
          );

          if (existingIdx >= 0) {
            final existing = thread.messages[existingIdx];
            existing.id = serverMsgId ?? existing.id;
            if (fileUrl != null) existing.fileUrl = fileUrl;
            if (kind != ChatKind.text) existing.kind = kind;
            existing.createdAt ??= createdDate;
            if (existing.time == null ||
                existing.time == 'Now' ||
                existing.time == 'Just now') {
              existing.time = timeStr;
            }
            final tickStr = msg['tick']?.toString();
            if (tickStr == 'read') {
              existing.tick = Tick.read;
            } else if (tickStr == 'delivered') {
              existing.tick = Tick.delivered;
            } else if (isMine && existing.tick == Tick.sent) {
              existing.tick = Tick.sent;
            }
          } else {
            Map<String, String>? msgRxMap;
            final rawMsgRx = msg['reactions'];
            if (rawMsgRx is List) {
              msgRxMap = {};
              for (final r in rawMsgRx) {
                if (r is Map && r['userId'] != null && r['reaction'] != null) {
                  msgRxMap[r['userId'].toString()] = r['reaction'].toString();
                }
              }
            } else if (rawMsgRx is Map) {
              msgRxMap = rawMsgRx.map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              );
            }

            thread.messages.add(
              ChatMessage(
                id: serverMsgId,
                clientId: clientId,
                senderId: msgSenderId,
                senderName:
                    msg['senderName']?.toString() ??
                    msg['sender']?['name']?.toString(),
                text: body,
                mine: isMine,
                time: timeStr,
                createdAt: createdDate,
                kind: kind,
                fileUrl: fileUrl,
                tick: isMine ? Tick.sent : Tick.delivered,
                replyId:
                    msg['reply']?['id']?.toString() ??
                    msg['replyTo']?.toString(),
                replyText: msg['reply']?['body']?.toString(),
                replyName: msg['reply']?['senderName']?.toString(),
                reactions: msgRxMap,
              ),
            );
          }
        });

        if (!isMine && thread.chatId != null) {
          ChatSocketService.instance.markRead(thread.chatId!);
        }
        _jumpToEnd();
      }
    });

    _reactionSub = ChatSocketService.instance.onMessageReaction.listen((data) {
      final eventChatId = data['chatId']?.toString();
      final messageId = data['messageId']?.toString();
      if (thread.chatId != null && eventChatId != null && eventChatId != thread.chatId) {
        return;
      }
      if (!mounted) return;
      setState(() {
        for (final m in thread.messages) {
          if (m.id == messageId) {
            final rawReactions = data['reactions'];
            if (rawReactions is List) {
              m.reactions = {};
              for (final r in rawReactions) {
                if (r is Map && r['userId'] != null && r['reaction'] != null) {
                  m.reactions![r['userId'].toString()] = r['reaction'].toString();
                }
              }
            } else if (rawReactions is Map) {
              m.reactions = rawReactions.map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              );
            } else {
              final userId = data['userId']?.toString();
              final userReaction = data['userReaction']?.toString();
              m.reactions ??= {};
              if (userId != null) {
                if (userReaction != null && userReaction.isNotEmpty) {
                  m.reactions![userId] = userReaction;
                } else {
                  m.reactions!.remove(userId);
                }
              }
            }
            break;
          }
        }
      });
    });

    _delivSub = ChatSocketService.instance.onDelivered.listen((data) {
      if (data['chatId']?.toString() == thread.chatId && mounted) {
        final messageId = data['messageId']?.toString();
        setState(() {
          for (final m in thread.messages) {
            if (m.mine &&
                (messageId == null || m.id == messageId) &&
                m.tick == Tick.sent) {
              m.tick = Tick.delivered;
            }
          }
        });
      }
    });

    _readSub = ChatSocketService.instance.onRead.listen((data) {
      if (data['chatId']?.toString() == thread.chatId && mounted) {
        setState(() {
          for (final m in thread.messages) {
            if (m.mine) {
              m.tick = Tick.read;
            }
          }
        });
      }
    });

    _onlineSub = ChatSocketService.instance.onUserOnline.listen((data) {
      final userId = data['userId']?.toString();
      if (thread.peerId != null && thread.peerId == userId && mounted) {
        setState(() {
          thread.online = true;
        });
      }
    });

    _offlineSub = ChatSocketService.instance.onUserOffline.listen((data) {
      final userId = data['userId']?.toString();
      if (thread.peerId != null && thread.peerId == userId && mounted) {
        setState(() {
          thread.online = false;
        });
      }
    });

    _typingSub = ChatSocketService.instance.onTyping.listen((data) {
      final eventChatId = data['chatId']?.toString();
      final eventUserId = data['userId']?.toString();
      final currentUserId = TokenStorage.instance.userId;

      if (eventUserId != null && eventUserId == currentUserId) return;

      final bool matches;
      if (thread.chatId != null) {
        matches = (eventChatId != null && eventChatId == thread.chatId);
      } else if (!thread.isGroup && thread.peerId != null) {
        matches = (eventUserId == thread.peerId);
      } else {
        matches = false;
      }

      if (matches && mounted) {
        setState(() {
          _peerTyping = true;
          _peerTypingName = data['userName']?.toString();
        });
        _peerTypingTimer?.cancel();
        _peerTypingTimer = Timer(const Duration(milliseconds: 3500), () {
          if (mounted) {
            setState(() {
              _peerTyping = false;
              _peerTypingName = null;
            });
          }
        });
        _jumpToEndImmediate();
        Future.delayed(const Duration(milliseconds: 60), () {
          if (mounted) _jumpToEndImmediate();
        });
      }
    });

    _stopTypingSub = ChatSocketService.instance.onStopTyping.listen((data) {
      final eventChatId = data['chatId']?.toString();
      final eventUserId = data['userId']?.toString();
      final currentUserId = TokenStorage.instance.userId;

      if (eventUserId != null && eventUserId == currentUserId) return;

      final bool matches;
      if (thread.chatId != null) {
        matches = (eventChatId != null && eventChatId == thread.chatId);
      } else if (!thread.isGroup && thread.peerId != null) {
        matches = (eventUserId == thread.peerId);
      } else {
        matches = false;
      }

      if (matches && mounted) {
        _peerTypingTimer?.cancel();
        setState(() {
          _peerTyping = false;
          _peerTypingName = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _delivSub?.cancel();
    _readSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    _typingSub?.cancel();
    _stopTypingSub?.cancel();
    _reactionSub?.cancel();
    _peerTypingTimer?.cancel();
    _stopTypingDebounce?.cancel();
    _recTimer?.cancel();
    ChatAudioService.instance.stop();
    if (_recording) {
      const MethodChannel('qapp/audio').invokeMethod<String>('cancel');
    }
    _controller.dispose();
    _find.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    final thread = widget.thread;
    if (thread.blocked) return;

    if (text.trim().isNotEmpty) {
      if (!_isTypingActive) {
        _isTypingActive = true;
        if (thread.chatId != null) {
          ChatSocketService.instance.sendTyping(thread.chatId!, thread.peerId);
        }
      }
      _stopTypingDebounce?.cancel();
      _stopTypingDebounce = Timer(const Duration(milliseconds: 2500), () {
        _isTypingActive = false;
        if (thread.chatId != null) {
          ChatSocketService.instance.sendStopTyping(
            thread.chatId!,
            thread.peerId,
          );
        }
      });
    } else {
      if (_isTypingActive) {
        _isTypingActive = false;
        _stopTypingDebounce?.cancel();
        if (thread.chatId != null) {
          ChatSocketService.instance.sendStopTyping(
            thread.chatId!,
            thread.peerId,
          );
        }
      }
    }
  }

  void _onSlideReply(ChatMessage message) {
    HapticFeedback.lightImpact();
    setState(() {
      _reply = message;
    });
    _focusNode.requestFocus();
  }

  void _push(ChatMessage message) async {
    final thread = widget.thread;
    final clientId =
        'c_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode}';
    message.clientId = clientId;
    message.createdAt ??= DateTime.now();
    if (message.time == null ||
        message.time!.isEmpty ||
        message.time == 'Now' ||
        message.time == 'Just now') {
      message.time = formatMessageTime(message.createdAt);
    }

    thread.messages.add(message);
    thread.preview = message.kind == ChatKind.location
        ? '📍 Location'
        : (message.kind == ChatKind.image
              ? '📷 Photo'
              : (message.kind == ChatKind.video
                    ? '🎥 Video'
                    : (message.kind == ChatKind.audio
                          ? '🎤 Voice'
                          : message.text)));
    thread.time = message.time ?? S.of(context).now;
    ChatBook.instance.ping();

    // Ensure direct chat exists in database if not created yet
    if (thread.chatId == null && thread.peerId != null) {
      final direct = await ChatViewModel.instance.openDirectChat(
        thread.peerId!,
      );
      if (direct != null && direct['id'] != null) {
        thread.chatId = direct['id'].toString();
        ChatSocketService.instance.joinChat(thread.chatId!);
      }
    }

    Map<String, dynamic>? fileInfo;
    final uploadType = message.kind == ChatKind.video
        ? 'video'
        : (message.kind == ChatKind.audio
              ? 'audio'
              : (message.kind == ChatKind.pdf || message.kind == ChatKind.doc
                    ? 'document'
                    : 'image'));

    if (message.bytes != null && message.bytes!.isNotEmpty) {
      try {
        final uploaded = await ChatViewModel.instance.uploadMedia(
          bytes: message.bytes!,
          fileName: message.text.isNotEmpty ? message.text : 'file_$clientId',
          type: uploadType,
        );
        if (uploaded != null) {
          if (uploaded['file'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['file'] as Map);
          } else if (uploaded['media'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['media'] as Map);
          } else if (uploaded['data'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['data'] as Map);
          } else {
            fileInfo = Map<String, dynamic>.from(uploaded);
          }
          final extractedUrl =
              fileInfo['url']?.toString() ??
              fileInfo['path']?.toString() ??
              uploaded['url']?.toString() ??
              uploaded['file_url']?.toString();
          if (extractedUrl != null) {
            message.fileUrl = extractedUrl;
            fileInfo['url'] ??= extractedUrl;
          }
          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint('Media upload error: $e');
      }
    } else if (message.path != null && File(message.path!).existsSync()) {
      try {
        final bytes = await File(message.path!).readAsBytes();
        final name = File(message.path!).uri.pathSegments.last;
        final uploaded = await ChatViewModel.instance.uploadMedia(
          bytes: bytes,
          fileName: name,
          type: uploadType,
        );
        if (uploaded != null) {
          if (uploaded['file'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['file'] as Map);
          } else if (uploaded['media'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['media'] as Map);
          } else if (uploaded['data'] is Map) {
            fileInfo = Map<String, dynamic>.from(uploaded['data'] as Map);
          } else {
            fileInfo = Map<String, dynamic>.from(uploaded);
          }
          final extractedUrl =
              fileInfo['url']?.toString() ??
              fileInfo['path']?.toString() ??
              uploaded['url']?.toString() ??
              uploaded['file_url']?.toString();
          if (extractedUrl != null) {
            message.fileUrl = extractedUrl;
            fileInfo['url'] ??= extractedUrl;
          }
          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint('Media file upload error: $e');
      }
    }

    final isMedia = message.kind == ChatKind.image ||
        message.kind == ChatKind.video ||
        message.kind == ChatKind.audio ||
        message.kind == ChatKind.pdf ||
        message.kind == ChatKind.doc;

    if (isMedia && fileInfo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media upload failed. Please check internet and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (fileInfo != null) {
      fileInfo['kind'] ??= uploadType;
    }

    final kindStr = message.kind == ChatKind.location
        ? 'location'
        : (message.kind == ChatKind.image
              ? 'image'
              : (message.kind == ChatKind.video
                    ? 'video'
                    : (message.kind == ChatKind.audio
                          ? 'audio'
                          : (message.kind == ChatKind.pdf
                                ? 'document'
                                : 'text'))));

    if (thread.chatId != null) {
      if (ChatSocketService.instance.isConnected) {
        ChatSocketService.instance.sendMessage(
          chatId: thread.chatId!,
          recipientId: thread.peerId,
          clientId: clientId,
          body: message.text,
          kind: kindStr,
          replyTo: message.replyId,
          file: fileInfo,
        );
      } else {
        ChatViewModel.instance.sendMessage(
          thread.chatId!,
          clientId: clientId,
          body: message.text,
          kind: kindStr,
          replyTo: message.replyId,
          fileInfo: fileInfo,
        );
      }
    }
  }

  void _send() {
    if (widget.thread.blocked) {
      return;
    }
    if (_pendingVoicePath != null) {
      _sendPendingVoice();
    }
    final text = _controller.text.trim();
    if (text.isEmpty && _pending.isEmpty) {
      return;
    }

    if (_isTypingActive) {
      _isTypingActive = false;
      _stopTypingDebounce?.cancel();
      if (widget.thread.chatId != null) {
        ChatSocketService.instance.sendStopTyping(
          widget.thread.chatId!,
          widget.thread.peerId,
        );
      }
    }

    final s = S.of(context);
    final now = DateTime.now();
    final timeStr = formatMessageTime(now);

    setState(() {
      for (final item in _pending) {
        _push(
          ChatMessage(
            text: item.name,
            mine: true,
            time: timeStr,
            createdAt: now,
            kind: item.kind,
            bytes: item.bytes,
            path: item.path,
            tick: Tick.sent,
          ),
        );
      }
      if (text.isNotEmpty) {
        _push(
          ChatMessage(
            text: text,
            mine: true,
            time: timeStr,
            createdAt: now,
            tick: Tick.sent,
            replyId: _reply?.id,
            replyName: _reply == null
                ? null
                : (_reply!.mine ? s.you : widget.thread.name),
            replyText: _reply?.deleted == true ? s.deletedMsg : _reply?.text,
          ),
        );
      }
      _pending.clear();
      _reply = null;
      _controller.clear();
    });
    _jumpToEnd();
  }

  void _jumpToEndImmediate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _jumpToEnd({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      if (immediate) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _headerAction(String value) {
    final thread = widget.thread;
    switch (value) {
      case 'pin':
        setState(() => thread.pinned = !thread.pinned);
      case 'mute':
        setState(() => thread.muted = !thread.muted);
      case 'clear':
        setState(() {
          thread.messages.clear();
          thread.preview = '';
          thread.unread = 0;
        });
      case 'block':
        if (thread.blocked) {
          final peerId = thread.peerId;
          if (peerId != null) ChatViewModel.instance.unblockUser(peerId);
          setState(() => thread.blocked = false);
        } else {
          _showBlockReportDialog(thread);
          return;
        }
      case 'delete':
        ChatBook.instance.remove(thread);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
    }
    ChatBook.instance.ping();
  }

  void _showBlockReportDialog(ChatThread thread) {
    String category = 'spam';
    final descCtrl = TextEditingController();
    bool alsoReport = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block & Report ${thread.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reason:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Spam'),
                        selected: category == 'spam',
                        onSelected: (val) =>
                            setModalState(() => category = 'spam'),
                      ),
                      ChoiceChip(
                        label: const Text('Harassment'),
                        selected: category == 'harassment',
                        onSelected: (val) =>
                            setModalState(() => category = 'harassment'),
                      ),
                      ChoiceChip(
                        label: const Text('Inappropriate'),
                        selected: category == 'inappropriate',
                        onSelected: (val) =>
                            setModalState(() => category = 'inappropriate'),
                      ),
                      ChoiceChip(
                        label: const Text('Other'),
                        selected: category == 'other',
                        onSelected: (val) =>
                            setModalState(() => category = 'other'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      hintText: 'Problem description (Optional)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: alsoReport,
                        onChanged: (val) =>
                            setModalState(() => alsoReport = val ?? true),
                      ),
                      const Expanded(
                        child: Text(
                          'Report this contact to Qapp Admin',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final peerId = thread.peerId;
                          if (peerId != null) {
                            if (alsoReport) {
                              await ChatViewModel.instance.reportAndBlockUser(
                                targetUserId: peerId,
                                category: category,
                                reason: 'Reported: $category',
                                description: descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : null,
                                block: true,
                              );
                            } else {
                              await ChatViewModel.instance.blockUser(peerId);
                            }
                          }
                          setState(() => thread.blocked = true);
                          ChatBook.instance.ping();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${thread.name} has been blocked and reported',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Block & Report'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleMessageReaction(ChatMessage message, String emoji) async {
    final msgId = message.id;
    if (msgId == null) return;
    final currentUserId = TokenStorage.instance.userId;
    setState(() {
      message.reactions ??= {};
      if (message.reactions![currentUserId] == emoji) {
        message.reactions!.remove(currentUserId);
      } else {
        message.reactions![currentUserId] = emoji;
      }
    });
    try {
      await ChatViewModel.instance.toggleReaction(msgId, emoji);
    } catch (e) {
      debugPrint('Reaction error: $e');
    }
  }

  void _messageMenu(ChatMessage message) {
    final s = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.deleted && message.id != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final emoji in ['👍', '❤️', '😂', '😮', '😢', '🙏'])
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(sheet);
                            _toggleMessageReaction(message, emoji);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ListTile(
                leading: Icon(Icons.star_rounded, color: AppColors.ink),
                title: Text(
                  s.starred,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  setState(() => message.starred = !message.starred);
                  Navigator.pop(sheet);
                },
              ),
              if (!message.deleted)
                ListTile(
                  leading: Icon(Icons.forward_rounded, color: AppColors.ink),
                  title: Text(
                    s.forward,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheet);
                    _forward(message);
                  },
                ),
              if (!message.deleted)
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: AppColors.ink),
                  title: Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(sheet);
                  },
                ),
              if (message.mine && !message.deleted)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.ink,
                  ),
                  title: Text(
                    s.deleteAll,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    setState(() => message.deleted = true);
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _forward(ChatMessage message) {
    final targets = ChatBook.instance.threads
        .where((thread) => !identical(thread, widget.thread))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheet) {
        return SafeArea(
          child: SizedBox(
            height: 380,
            child: ListView(
              children: [
                for (final thread in targets)
                  ListTile(
                    leading: QAvatar(
                      name: thread.name,
                      size: 42,
                      colorIndex: thread.colorIndex,
                      photo: thread.photo,
                      bytes: thread.photoBytes,
                    ),
                    title: Text(
                      thread.name,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      final now = DateTime.now();
                      final copy = ChatMessage(
                        text: message.text,
                        mine: true,
                        time: formatMessageTime(now),
                        createdAt: now,
                        kind: message.kind,
                        bytes: message.bytes,
                        asset: message.asset,
                        path: message.path,
                        tick: Tick.sent,
                        forwarded: true,
                      );
                      thread.messages.add(copy);
                      thread.preview = message.text;
                      thread.time = copy.time ?? S.of(sheet).now;
                      ChatBook.instance.ping();
                      Future<void>.delayed(
                        const Duration(milliseconds: 450),
                        () {
                          if (copy.tick == Tick.sent) {
                            copy.tick = Tick.delivered;
                            ChatBook.instance.ping();
                          }
                        },
                      );
                      Future<void>.delayed(
                        const Duration(milliseconds: 1100),
                        () {
                          if (copy.tick != Tick.read) {
                            copy.tick = Tick.read;
                            ChatBook.instance.ping();
                          }
                        },
                      );
                      Navigator.pop(sheet);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareLocation() async {
    Navigator.of(context).pop();

    final duration = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.faint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Share Live Location',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose duration for how long your live location stays active.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: AppColors.accent),
                  title: Text('15 Minutes', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  subtitle: Text('Temporary live share', style: TextStyle(color: AppColors.faint, fontSize: 12)),
                  onTap: () => Navigator.pop(context, '15 Minutes'),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time_rounded, color: AppColors.accent),
                  title: Text('1 Hour', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  subtitle: Text('Standard live share (Recommended)', style: TextStyle(color: AppColors.faint, fontSize: 12)),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
                  onTap: () => Navigator.pop(context, '1 Hour'),
                ),
                ListTile(
                  leading: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.accent),
                  title: Text('8 Hours', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  subtitle: Text('Full workday / journey share', style: TextStyle(color: AppColors.faint, fontSize: 12)),
                  onTap: () => Navigator.pop(context, '8 Hours'),
                ),
                ListTile(
                  leading: const Icon(Icons.today_rounded, color: AppColors.accent),
                  title: Text('24 Hours (1 Day)', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  subtitle: Text('All day live location tracking', style: TextStyle(color: AppColors.faint, fontSize: 12)),
                  onTap: () => Navigator.pop(context, '24 Hours (1 Day)'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (duration == null || !mounted) return;

    try {
      final res = await const MethodChannel(
        'qapp/location',
      ).invokeMethod('getLocation');
      if (res is Map) {
        final lat = res['lat'];
        final lng = res['lng'];
        if (lat != null && lng != null) {
          final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
          final now = DateTime.now();
          final timeStr = formatMessageTime(now);
          setState(() {
            _push(
              ChatMessage(
                text: '📍 Live Location (Valid for $duration)\n$mapsUrl',
                mine: true,
                time: timeStr,
                createdAt: now,
                kind: ChatKind.location,
                tick: Tick.sent,
              ),
            );
          });
          _jumpToEnd();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  void _shareSheet() {
    final s = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.attach,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _shareTile(
                    Icons.image_rounded,
                    s.image,
                    const Color(0xFF1C8F7C),
                    () => _pick(ChatKind.image),
                  ),
                  _shareTile(
                    Icons.photo_camera_rounded,
                    s.camera,
                    const Color(0xFF1FA37A),
                    _takePhoto,
                  ),
                  _shareTile(
                    Icons.videocam_rounded,
                    s.video,
                    const Color(0xFF8A5A2B),
                    () => _pick(ChatKind.video),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _shareTile(
                    Icons.location_on_rounded,
                    'Location',
                    const Color(0xFF0F9D58),
                    _shareLocation,
                  ),
                  _shareTile(
                    Icons.picture_as_pdf_rounded,
                    s.pdf,
                    const Color(0xFFD4656A),
                    () => _pick(ChatKind.pdf),
                  ),
                  _shareTile(
                    Icons.person_rounded,
                    s.shareContact,
                    const Color(0xFF1C6B8A),
                    _sharePerson,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shareTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(ChatKind kind) async {
    Navigator.of(context).pop();
    try {
      if (kind == ChatKind.video) {
        final file = await FilePicker.pickFile(type: FileType.video);
        if (!mounted || file == null) {
          return;
        }
        setState(
          () => _pending.add(
            _Pending(file.name, ChatKind.video, null, file.path),
          ),
        );
        return;
      }
      if (kind == ChatKind.image) {
        final files = await FilePicker.pickFiles(
          type: FileType.image,
          compressionQuality: 50,
        );
        final room = 10 - _pending.length;
        if (!mounted || files.isEmpty || room <= 0) {
          return;
        }
        final next = <_Pending>[];
        for (final file in files.take(room)) {
          final bytes = await file.readAsBytes();
          next.add(_Pending(file.name, kind, bytes, file.path));
        }
        if (!mounted || next.isEmpty) {
          return;
        }
        setState(() => _pending.addAll(next));
        return;
      }
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: kind == ChatKind.pdf
            ? const ['pdf']
            : const ['doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );
      if (!mounted || file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _pending.add(_Pending(file.name, kind, bytes, file.path)));
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    Navigator.of(context).pop();
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(qRoute(const _ChatCamera()));
    if (!mounted || bytes == null || bytes.isEmpty) {
      return;
    }
    setState(() => _pending.add(_Pending('photo.jpg', ChatKind.image, bytes)));
  }

  Future<void> _sharePerson() async {
    Navigator.of(context).pop();
    if (!mounted || widget.thread.blocked) {
      return;
    }
    final picked = await showModalBottomSheet<List<ShareContact>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheet) {
        final chosen = <int>{};
        return StatefulBuilder(
          builder: (context, setSheet) {
            final s = S.of(context);
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(sheet).height * 0.72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.shareContact,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${chosen.length}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final contactsList = ChatBook.instance.threads
                            .where((t) => t.phone.isNotEmpty)
                            .map(
                              (t) => ShareContact(
                                t.name,
                                t.phone,
                                t.colorIndex,
                                photo: t.photo,
                              ),
                            )
                            .toList();
                        return Expanded(
                          child: contactsList.isEmpty
                              ? Center(
                                  child: Text(
                                    'No contacts available',
                                    style: TextStyle(color: AppColors.faint),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: contactsList.length,
                                  itemBuilder: (context, index) {
                                    final person = contactsList[index];
                                    final on = chosen.contains(index);
                                    return ListTile(
                                      onTap: () {
                                        setSheet(() {
                                          if (on) {
                                            chosen.remove(index);
                                          } else {
                                            chosen.add(index);
                                          }
                                        });
                                      },
                                      leading: QAvatar(
                                        name: person.name,
                                        size: 44,
                                        colorIndex: person.colorIndex,
                                        photo: person.photo,
                                      ),
                                      title: Text(
                                        person.name,
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        person.phone,
                                        style: AppText.subtitle,
                                      ),
                                      trailing: Icon(
                                        on
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: on
                                            ? AppColors.accent
                                            : AppColors.faint,
                                      ),
                                    );
                                  },
                                ),
                        );
                      },
                    ),
                    if (chosen.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.buttonGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextButton(
                              onPressed: () {
                                final contactsList = ChatBook.instance.threads
                                    .where((t) => t.phone.isNotEmpty)
                                    .map(
                                      (t) => ShareContact(
                                        t.name,
                                        t.phone,
                                        t.colorIndex,
                                        photo: t.photo,
                                      ),
                                    )
                                    .toList();
                                final order = chosen.toList()..sort();
                                Navigator.pop(sheet, [
                                  for (final index in order)
                                    if (index < contactsList.length)
                                      contactsList[index],
                                ]);
                              },
                              child: Text(
                                '${s.attach} (${chosen.length})',
                                style: AppText.button,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || picked == null || picked.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final timeStr = formatMessageTime(now);
    setState(() {
      for (final person in picked) {
        _push(
          ChatMessage(
            text: '${person.name}\n${person.phone}',
            mine: true,
            time: timeStr,
            createdAt: now,
            kind: ChatKind.contact,
            tick: Tick.sent,
          ),
        );
      }
    });
    _jumpToEnd();
  }

  Future<void> _mic() async {
    if (widget.thread.blocked) {
      return;
    }
    if (_recording) {
      await _stopVoiceRecording();
      return;
    }
    try {
      final ok = await const MethodChannel(
        'qapp/audio',
      ).invokeMethod<bool>('grant');
      if (ok != true || !mounted) {
        return;
      }
      await const MethodChannel('qapp/audio').invokeMethod<String>('start');
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recSeconds++);
        }
      });
      setState(() {
        _recording = true;
        _recSeconds = 0;
      });
    } catch (_) {}
  }

  Future<void> _stopVoiceRecording() async {
    _recTimer?.cancel();
    String? path;
    try {
      path = await const MethodChannel(
        'qapp/audio',
      ).invokeMethod<String>('stop');
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _recording = false;
      if (path != null && path.isNotEmpty) {
        _pendingVoicePath = path;
        _pendingVoiceSeconds = _recSeconds;
      }
    });
  }

  void _discardPendingVoice() {
    ChatAudioService.instance.stop();
    if (_pendingVoicePath != null) {
      try {
        File(_pendingVoicePath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _pendingVoicePath = null;
      _pendingVoiceSeconds = 0;
    });
  }

  void _sendPendingVoice() {
    if (_pendingVoicePath == null) return;
    final path = _pendingVoicePath!;
    final seconds = _pendingVoiceSeconds;
    final now = DateTime.now();
    final timeStr = formatMessageTime(now);
    final label = _clock(seconds > 0 ? seconds : 1);

    ChatAudioService.instance.stop();
    setState(() {
      _pendingVoicePath = null;
      _pendingVoiceSeconds = 0;
      _push(
        ChatMessage(
          text: label,
          mine: true,
          time: timeStr,
          createdAt: now,
          kind: ChatKind.audio,
          path: path,
          tick: Tick.sent,
        ),
      );
    });
    _jumpToEnd();
  }

  Future<void> _cancelAudio() async {
    _recTimer?.cancel();
    try {
      await const MethodChannel('qapp/audio').invokeMethod<String>('cancel');
    } catch (_) {}
    if (mounted) {
      setState(() {
        _recording = false;
        _pendingVoicePath = null;
        _pendingVoiceSeconds = 0;
      });
    }
  }

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _openContact() async {
    final result = await Navigator.of(
      context,
    ).push(qRoute(ContactScreen(thread: widget.thread)));
    if (!mounted) {
      return;
    }
    setState(() {
      if (result == 'search') {
        _finding = true;
      }
    });
  }

  Widget _activeVoicePlaybackBar() {
    return AnimatedBuilder(
      animation: ChatAudioService.instance,
      builder: (context, _) {
        final audio = ChatAudioService.instance;
        if (!audio.isPlaying && audio.currentPath == null) {
          return const SizedBox.shrink();
        }
        final duration = audio.totalDuration;
        final position = audio.currentPosition;
        final progress = duration > 0
            ? (position / duration).clamp(0.0, 1.0)
            : 0.0;
        final posStr = _clock((position / 1000).round());
        final durStr = duration > 0 ? _clock((duration / 1000).round()) : '...';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF132A2D),
            border: Border(
              bottom: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (audio.isPlaying) {
                        audio.pause();
                      } else if (audio.currentPath != null) {
                        audio.play(audio.currentPath!);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: Icon(
                        audio.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audio.isPlaying
                          ? 'Playing Voice Message ($posStr / $durStr)'
                          : 'Voice Message Paused ($posStr)',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => audio.stop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmUnblock(ChatThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock ${thread.name}?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to unblock ${thread.name} so you can send and receive messages?',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Unblock',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final peerId = thread.peerId;
      if (peerId != null) {
        await ChatViewModel.instance.unblockUser(peerId);
      }
      setState(() => thread.blocked = false);
      ChatBook.instance.ping();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${thread.name} unblocked')));
      }
    }
  }

  Widget _blockedBannerPill(ChatThread thread) {
    return Center(
      child: InkWell(
        onTap: () => _confirmUnblock(thread),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2830),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 14, color: AppColors.accent),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'You blocked this contact. Tap to unblock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final s = S.of(context);
    final query = _find.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? _messages
        : _messages
              .where((message) => message.text.toLowerCase().contains(query))
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: QBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_finding) {
                          setState(() {
                            _finding = false;
                            _find.clear();
                          });
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    if (_finding)
                      Expanded(
                        child: TextField(
                          controller: _find,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: AppColors.ink),
                          cursorColor: AppColors.accent,
                          decoration: InputDecoration(
                            hintText: s.search,
                            hintStyle: TextStyle(color: AppColors.faint),
                            border: InputBorder.none,
                          ),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: _openContact,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              QAvatar(
                                name: thread.name,
                                size: 40,
                                colorIndex: thread.colorIndex,
                                photo: thread.photo,
                                bytes: thread.photoBytes,
                                online: thread.online,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thread.header,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    _peerTyping
                                        ? Text(
                                            (thread.isGroup &&
                                                    _peerTypingName != null &&
                                                    _peerTypingName!.isNotEmpty)
                                                ? '$_peerTypingName is typing...'
                                                : 'typing...',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                        : thread.online
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const PulsingOnlineDot(
                                                size: 7,
                                                showRing: true,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                s.online,
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            thread.lastSeen != null
                                                ? 'Last seen ${formatLastSeen(thread.lastSeen)}'
                                                : (thread.time.isNotEmpty
                                                      ? thread.time
                                                      : ''),
                                            softWrap: true,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            qRoute(
                              VoiceCallScreen(
                                name: thread.header,
                                colorIndex: thread.colorIndex,
                                photo: thread.photo,
                                status: s.callStatus(thread.header),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_rounded),
                      ),
                      PopupMenuButton<String>(
                        color: AppColors.card,
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) => _headerAction(value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(
                              thread.pinned ? s.unpin : s.pinned,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'mute',
                            child: Text(
                              thread.muted ? s.unmute : s.muteNotif,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'clear',
                            child: Text(
                              s.clearChat,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Text(
                              thread.blocked ? s.unblock : s.block,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              s.deleteChat,
                              style: TextStyle(color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            qRoute(
                              VideoCallScreen(
                                name: thread.header,
                                colorIndex: thread.colorIndex,
                                photo: thread.photo,
                                status: s.callStatus(thread.header),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.videocam_rounded),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _activeVoicePlaybackBar(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thread.wallpaperPath != null &&
                      File(thread.wallpaperPath!).existsSync())
                    Positioned.fill(
                      child: Image.file(
                        File(thread.wallpaperPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (thread.wallpaperColor != null)
                    Positioned.fill(
                      child: Container(
                        color: Color(thread.wallpaperColor!),
                      ),
                    ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                s.encrypted,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount:
                              shown.length +
                              (_peerTyping ? 1 : 0) +
                              (thread.blocked ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (thread.blocked &&
                                index == shown.length + (_peerTyping ? 1 : 0)) {
                              return _blockedBannerPill(thread);
                            }
                            if (index == shown.length) {
                              return _TypingIndicatorBubble(
                                userName: thread.isGroup ? _peerTypingName : null,
                              );
                            }
                            final message = shown[index];
                            final showDate =
                                index == 0 && message.createdAt != null ||
                                (index > 0 &&
                                    message.createdAt != null &&
                                    shown[index - 1].createdAt != null &&
                                    !isSameDay(
                                      message.createdAt!,
                                      shown[index - 1].createdAt!,
                                    ));

                            final dateStr = showDate && message.createdAt != null
                                ? formatDateDivider(message.createdAt!)
                                : null;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (dateStr != null) _dateBadge(dateStr),
                                _Bubble(
                                  message: message,
                                  isGroup: thread.isGroup,
                                  color:
                                      AppColors.chatThemes[thread.themeIndex %
                                          AppColors.chatThemes.length],
                                  onMenu: () => _messageMenu(message),
                                  onSwipeReply: () => _onSlideReply(message),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (thread.blocked)
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.08),
                  ),
                ),
                child: InkWell(
                  onTap: () => _confirmUnblock(thread),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'You blocked this contact. Tap to unblock.',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.ink.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_reply != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 8, 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 36,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _reply!.mine
                                            ? s.you
                                            : widget.thread.name,
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _reply!.deleted
                                            ? s.deletedMsg
                                            : _reply!.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.inkSoft,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _reply = null),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_pending.isNotEmpty)
                          SizedBox(
                            height: 78,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                              itemCount: _pending.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final item = _pending[index];
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 68,
                                        height: 68,
                                        child: (item.kind == ChatKind.image && item.bytes != null)
                                            ? Image.memory(
                                                item.bytes!,
                                                fit: BoxFit.cover,
                                                cacheWidth: 200,
                                                filterQuality:
                                                    FilterQuality.low,
                                              )
                                            : ColoredBox(
                                                color: const Color(0xFF132A32),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      item.kind == ChatKind.pdf
                                                          ? Icons.picture_as_pdf_rounded
                                                          : (item.kind == ChatKind.video
                                                              ? Icons.videocam_rounded
                                                              : (item.kind == ChatKind.audio
                                                                  ? Icons.mic_rounded
                                                                  : (item.kind == ChatKind.contact
                                                                      ? Icons.person_rounded
                                                                      : Icons.description_rounded))),
                                                      color: item.kind == ChatKind.pdf
                                                          ? const Color(0xFFFF5252)
                                                          : AppColors.accent,
                                                      size: 28,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                                      child: Text(
                                                        item.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _pending.removeAt(index),
                                        ),
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.black87,
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        if (_pendingVoicePath != null)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Discard',
                                  onPressed: _discardPendingVoice,
                                ),
                                AnimatedBuilder(
                                  animation: ChatAudioService.instance,
                                  builder: (context, _) {
                                    final audio = ChatAudioService.instance;
                                    final isPlayingThis =
                                        audio.isPlaying &&
                                        audio.currentPath == _pendingVoicePath;
                                    return IconButton(
                                      icon: Icon(
                                        isPlayingThis
                                            ? Icons.pause_circle_filled_rounded
                                            : Icons.play_circle_fill_rounded,
                                        color: AppColors.accent,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        if (isPlayingThis) {
                                          audio.pause();
                                        } else {
                                          audio.play(_pendingVoicePath!);
                                        }
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.graphic_eq_rounded,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _clock(_pendingVoiceSeconds),
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(Voice note)',
                                        style: TextStyle(
                                          color: AppColors.inkSoft,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _sendPendingVoice,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.buttonGradient,
                                    ),
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: AppColors.ink,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _shareSheet,
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                            if (_recording)
                              Expanded(
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _cancelAudio,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.fiber_manual_record,
                                      color: Color(0xFFE36B6B),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _clock(_recSeconds),
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onChanged: _onInputChanged,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 15,
                                  ),
                                  cursorColor: AppColors.accent,
                                  decoration: InputDecoration(
                                    hintText: s.messageHint,
                                    hintStyle: TextStyle(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.42,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _send(),
                                ),
                              ),
                            GestureDetector(
                              onTap: _mic,
                              child: Icon(
                                _recording
                                    ? Icons.stop_circle_rounded
                                    : Icons.mic_none_rounded,
                                color: _recording
                                    ? const Color(0xFFE36B6B)
                                    : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _recording ? _stopVoiceRecording : _send,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.buttonGradient,
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: AppColors.ink,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateBadge(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.inkSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

Color _getSenderColor(String name) {
  const colors = [
    Color(0xFFE57373),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFFF8A65),
    Color(0xFF4DD0E1),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
  ];
  return colors[name.hashCode.abs() % colors.length];
}

Widget _buildReactionsPill(Map<String, String> reactions) {
  final list = reactions.values.where((e) => e.isNotEmpty).toList();
  if (list.isEmpty) return const SizedBox.shrink();
  final unique = list.toSet().take(3).join();
  final count = list.length;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(unique, style: const TextStyle(fontSize: 12)),
        if (count > 1) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.color,
    required this.onMenu,
    this.onSwipeReply,
    this.isGroup = false,
  });

  final ChatMessage message;
  final Color color;
  final VoidCallback onMenu;
  final VoidCallback? onSwipeReply;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final bubbleWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onMenu,
          onTap: () {
            if (message.deleted) {
              return;
            }
            if (message.kind == ChatKind.contact) {
              _contactCall(context, message);
              return;
            }
            if (message.kind == ChatKind.pdf || message.kind == ChatKind.doc) {
              openChatFile(message);
            }
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? AppColors.bubbleMine(color) : AppColors.bubbleIn,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 18),
                ),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: mine ? 0.08 : 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.deleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          S.of(context).deletedMsg,
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else ...[
                      if (message.forwarded)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              S.of(context).forward,
                              style: TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (message.replyText != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(
                                color: AppColors.accent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.replyName != null &&
                                  message.replyName!.isNotEmpty)
                                Text(
                                  message.replyName!,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                message.replyText!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!mine &&
                          (isGroup ||
                              (message.senderName != null &&
                                  message.senderName!.isNotEmpty)))
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              message.senderName ?? 'Member',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      _bubbleBody(message, mine: mine),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.starred)
                          const Padding(
                            padding: EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFE7C56A),
                            ),
                          ),
                        if (message.time != null && message.time!.isNotEmpty)
                          Text(
                            message.time!,
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (mine) ...[
                          const SizedBox(width: 3),
                          TickMark(message.tick, size: 15),
                        ],
                      ],
                    ),
                    if (message.reactions != null && message.reactions!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildReactionsPill(message.reactions!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (onSwipeReply == null) {
      return bubbleWidget;
    }

    return Dismissible(
      key: ValueKey(
        'msg_${message.id ?? message.clientId ?? "${message.text}_${message.createdAt?.millisecondsSinceEpoch}_${message.hashCode}"}',
      ),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.15},
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeReply!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.accent,
            size: 20,
          ),
        ),
      ),
      child: bubbleWidget,
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble({this.userName});

  final String? userName;

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bubbleIn,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.userName != null && widget.userName!.isNotEmpty) ...[
                Text(
                  widget.userName!,
                  style: TextStyle(
                    color: _getSenderColor(widget.userName!),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final offset = i * 0.2;
                      final val = ((_anim.value + offset) % 1.0);
                      final scale = 0.6 + 0.4 * (1 - (val - 0.5).abs() * 2);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(
                            alpha: 0.4 + 0.6 * scale,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _bubbleBody(ChatMessage message, {bool mine = false}) {
  // Auto-detect audio / voice message (Highest priority - never gets hijacked by image)
  if (message.kind == ChatKind.audio ||
      isAudioUrl(message.text) ||
      (message.fileUrl != null && isAudioUrl(message.fileUrl!)) ||
      (message.path != null && isAudioUrl(message.path!))) {
    return ChatVoiceBubble(message: message, mine: mine);
  }

  // Auto-detect video
  if (message.kind == ChatKind.video ||
      isVideoUrl(message.text) ||
      (message.fileUrl != null && isVideoUrl(message.fileUrl!))) {
    return ChatVideoBubble(message: message, mine: mine);
  }

  // Auto-detect location
  if (message.kind == ChatKind.location || isLocationUrl(message.text)) {
    return ChatLocationBubble(message: message, mine: mine);
  }

  // Auto-detect image
  if (message.kind == ChatKind.image ||
      isImageUrl(message.text) ||
      (message.fileUrl != null && isImageUrl(message.fileUrl!))) {
    return ChatImageBubble(message: message);
  }

  switch (message.kind) {
    case ChatKind.pdf:
      return _fileCard(
        message,
        Icons.picture_as_pdf_rounded,
        const Color(0xFFD4656A),
      );
    case ChatKind.doc:
      return _fileCard(
        message,
        Icons.description_rounded,
        const Color(0xFF3D8FD1),
      );
    case ChatKind.contact:
      final lines = message.text.split('\n');
      final name = lines.first;
      final phone = lines.length > 1 ? lines[1] : '';
      return SizedBox(
        width: 210,
        child: Row(
          children: [
            QAvatar(name: name, size: 40, colorIndex: 2),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    case ChatKind.text:
    default:
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            message.text,
            style: TextStyle(color: AppColors.ink, fontSize: 15, height: 1.3),
          ),
        ),
      );
  }
}

Widget _fileCard(ChatMessage message, IconData icon, Color color) {
  final label = message.kind == ChatKind.pdf
      ? 'PDF'
      : message.kind == ChatKind.video
      ? 'VID'
      : message.kind == ChatKind.image
      ? 'IMG'
      : 'DOC';
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 228,
      height: 78,
      child: Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: color,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _contactCall(BuildContext context, ChatMessage message) async {
  final lines = message.text.split('\n');
  final name = lines.first.trim();
  final phone = lines.length > 1 ? lines.sublist(1).join(' ').trim() : '';
  final s = S.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QAvatar(name: name, size: 72, colorIndex: 2),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 15),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheet);
                      final number = phone.replaceAll(RegExp(r'[^\d+]'), '');
                      if (number.isEmpty) {
                        return;
                      }
                      try {
                        await const MethodChannel(
                          'qapp/open_file',
                        ).invokeMethod<bool>('dial', {'number': number});
                      } catch (_) {}
                    },
                    icon: const Icon(
                      Icons.call_rounded,
                      color: AppColors.onAccent,
                    ),
                    label: Text(
                      s.voiceCall,
                      style: const TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChatCamera extends StatefulWidget {
  const _ChatCamera();

  @override
  State<_ChatCamera> createState() => _ChatCameraState();
}

class _ChatCameraState extends State<_ChatCamera> {
  int? _viewId;
  var _busy = false;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _grant();
  }

  Future<void> _grant() async {
    try {
      final ok = await const MethodChannel(
        'qapp/camera_perm',
      ).invokeMethod<bool>('grant');
      if (mounted) {
        setState(() => _ready = ok == true);
      }
    } catch (_) {}
  }

  Future<void> _snap() async {
    final id = _viewId;
    if (id == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final raw = await MethodChannel(
        'qapp/camera_$id',
      ).invokeMethod<Uint8List>('snap');
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(raw);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _ready && defaultTargetPlatform == TargetPlatform.android
                    ? _CamView(onReady: (id) => _viewId = id)
                    : const Center(
                        child: Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _busy ? null : _snap,
              child: Container(
                width: 68,
                height: 68,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 4),
                ),
                child: Icon(
                  Icons.circle,
                  color: _busy ? AppColors.faint : AppColors.accent,
                  size: 42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CamView extends StatelessWidget {
  const _CamView({required this.onReady});

  final ValueChanged<int> onReady;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'qapp/camera',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final view = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'qapp/camera',
          layoutDirection: Directionality.of(context),
          creationParams: null,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        );
        view
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            onReady(id);
          })
          ..create();
        return view;
      },
    );
  }
}
