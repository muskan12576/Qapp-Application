import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/contact_screen.dart';
import 'package:qapp/screens/video_call_screen.dart';
import 'package:qapp/screens/voice_call_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/open_chat_file.dart';
import 'package:qapp/theme/q_route.dart';
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
  final _pending = <_Pending>[];
  var _finding = false;
  var _recording = false;
  var _recSeconds = 0;
  Timer? _recTimer;
  ChatMessage? _reply;

  List<ChatMessage> get _messages => widget.thread.messages;

  @override
  void initState() {
    super.initState();
    for (final message in widget.thread.messages) {
      if (message.mine && message.tick != Tick.read) {
        _arm(message);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.thread.unread == 0) {
        return;
      }
      widget.thread.unread = 0;
      ChatBook.instance.ping();
    });
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    if (_recording) {
      const MethodChannel('qapp/audio').invokeMethod<String>('cancel');
    }
    _controller.dispose();
    _find.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _arm(ChatMessage message) {
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || message.tick != Tick.sent) {
        return;
      }
      setState(() => message.tick = Tick.delivered);
    });
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || message.tick == Tick.read) {
        return;
      }
      setState(() => message.tick = Tick.read);
      ChatBook.instance.ping();
    });
  }

  void _push(ChatMessage message) {
    final thread = widget.thread;
    thread.messages.add(message);
    thread.preview = message.kind == ChatKind.text ? message.text : message.text;
    thread.time = message.time ?? S.of(context).now;
    _arm(message);
    ChatBook.instance.ping();
  }

  void _send() {
    if (widget.thread.blocked) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty && _pending.isEmpty) {
      return;
    }
    final s = S.of(context);
    final now = s.now;
    setState(() {
      for (final item in _pending) {
        _push(
          ChatMessage(
            text: item.name,
            mine: true,
            time: now,
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
            time: now,
            tick: Tick.sent,
            replyName: _reply == null ? null : (_reply!.mine ? s.you : widget.thread.name),
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

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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
        setState(() => thread.blocked = !thread.blocked);
      case 'delete':
        ChatBook.instance.remove(thread);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
    }
    ChatBook.instance.ping();
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
              if (!message.deleted)
                ListTile(
                  leading: Icon(Icons.reply_rounded, color: AppColors.ink),
                  title: Text(s.reply, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  onTap: () {
                    setState(() => _reply = message);
                    Navigator.pop(sheet);
                  },
                ),
              ListTile(
                leading: Icon(Icons.star_rounded, color: AppColors.ink),
                title: Text(s.starred, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                onTap: () {
                  setState(() => message.starred = !message.starred);
                  Navigator.pop(sheet);
                },
              ),
              if (!message.deleted)
                ListTile(
                  leading: Icon(Icons.forward_rounded, color: AppColors.ink),
                  title: Text(s.forward, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(sheet);
                    _forward(message);
                  },
                ),
              if (!message.deleted)
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: AppColors.ink),
                  title: Text('Copy', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(sheet);
                  },
                ),
              if (message.mine && !message.deleted)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: AppColors.ink),
                  title: Text(s.deleteAll, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
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
    final targets = ChatBook.instance.threads.where((thread) => !identical(thread, widget.thread)).toList();
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
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      final copy = ChatMessage(
                        text: message.text,
                        mine: true,
                        time: S.of(sheet).now,
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
                      Future<void>.delayed(const Duration(milliseconds: 450), () {
                        if (copy.tick == Tick.sent) {
                          copy.tick = Tick.delivered;
                          ChatBook.instance.ping();
                        }
                      });
                      Future<void>.delayed(const Duration(milliseconds: 1100), () {
                        if (copy.tick != Tick.read) {
                          copy.tick = Tick.read;
                          ChatBook.instance.ping();
                        }
                      });
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
                style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _shareTile(Icons.image_rounded, s.image, const Color(0xFF1C8F7C), () => _pick(ChatKind.image)),
                  _shareTile(Icons.photo_camera_rounded, s.camera, const Color(0xFF1FA37A), _takePhoto),
                  _shareTile(Icons.videocam_rounded, s.video, const Color(0xFF8A5A2B), () => _pick(ChatKind.video)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _shareTile(Icons.picture_as_pdf_rounded, s.pdf, const Color(0xFFD4656A), () => _pick(ChatKind.pdf)),
                  _shareTile(Icons.description_rounded, s.document, const Color(0xFF3D8FD1), () => _pick(ChatKind.doc)),
                  _shareTile(Icons.person_rounded, s.shareContact, const Color(0xFF1C6B8A), _sharePerson),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shareTile(IconData icon, String label, Color color, VoidCallback onTap) {
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
                  CircleAvatar(backgroundColor: color, child: Icon(icon, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
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
        setState(() => _pending.add(_Pending(file.name, ChatKind.video, null, file.path)));
        return;
      }
      if (kind == ChatKind.image) {
        final files = await FilePicker.pickFiles(type: FileType.image, compressionQuality: 50);
        final room = 10 - _pending.length;
        if (!mounted || files.isEmpty || room <= 0) {
          return;
        }
        final next = <_Pending>[];
        for (final file in files.take(room)) {
          final bytes = await file.readAsBytes();
          next.add(_Pending(file.name, kind, bytes));
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
    final bytes = await Navigator.of(context).push<Uint8List>(qRoute(const _ChatCamera()));
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
                              style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${chosen.length}',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: shareContacts.length,
                        itemBuilder: (context, index) {
                          final person = shareContacts[index];
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
                              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(person.phone, style: AppText.subtitle),
                            trailing: Icon(
                              on ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: on ? AppColors.accent : AppColors.faint,
                            ),
                          );
                        },
                      ),
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
                                final order = chosen.toList()..sort();
                                Navigator.pop(sheet, [for (final index in order) shareContacts[index]]);
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
    final now = S.of(context).now;
    setState(() {
      for (final person in picked) {
        _push(
          ChatMessage(
            text: '${person.name}\n${person.phone}',
            mine: true,
            time: now,
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
      await _sendAudio();
      return;
    }
    try {
      final ok = await const MethodChannel('qapp/audio').invokeMethod<bool>('grant');
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

  Future<void> _sendAudio() async {
    _recTimer?.cancel();
    String? path;
    try {
      path = await const MethodChannel('qapp/audio').invokeMethod<String>('stop');
    } catch (_) {}
    if (!mounted) {
      return;
    }
    final label = _clock(_recSeconds);
    setState(() {
      _recording = false;
      if (path != null && path.isNotEmpty) {
        _push(
          ChatMessage(
            text: label,
            mine: true,
            time: S.of(context).now,
            kind: ChatKind.audio,
            path: path,
            tick: Tick.sent,
          ),
        );
      }
    });
    _jumpToEnd();
  }

  Future<void> _cancelAudio() async {
    _recTimer?.cancel();
    try {
      await const MethodChannel('qapp/audio').invokeMethod<String>('cancel');
    } catch (_) {}
    if (mounted) {
      setState(() => _recording = false);
    }
  }

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _openContact() async {
    final result = await Navigator.of(context).push(
      qRoute(ContactScreen(thread: widget.thread)),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      if (result == 'search') {
        _finding = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final s = S.of(context);
    final query = _find.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? _messages
        : _messages.where((message) => message.text.toLowerCase().contains(query)).toList();

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
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      thread.online ? s.online : thread.time,
                                      style: TextStyle(
                                        color: thread.online ? AppColors.accent : AppColors.faint,
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
                          PopupMenuItem(value: 'pin', child: Text(thread.pinned ? s.unpin : s.pinned, style: TextStyle(color: AppColors.ink))),
                          PopupMenuItem(value: 'mute', child: Text(thread.muted ? s.unmute : s.muteNotif, style: TextStyle(color: AppColors.ink))),
                          PopupMenuItem(value: 'clear', child: Text(s.clearChat, style: TextStyle(color: AppColors.ink))),
                          PopupMenuItem(value: 'block', child: Text(thread.blocked ? s.unblock : s.block, style: TextStyle(color: AppColors.ink))),
                          PopupMenuItem(value: 'delete', child: Text(s.deleteChat, style: TextStyle(color: AppColors.ink))),
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
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 13, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.encrypted,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: shown.length,
                itemBuilder: (context, index) {
                  final message = shown[index];
                  return _Bubble(
                    message: message,
                    color: AppColors.chatThemes[thread.themeIndex % AppColors.chatThemes.length],
                    onMenu: () => _messageMenu(message),
                  );
                },
              ),
            ),
                ],
              ),
            ),
            if (thread.blocked)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12 + MediaQuery.paddingOf(context).bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.blocked, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => thread.blocked = false);
                        ChatBook.instance.ping();
                      },
                      child: Text(s.unblock),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + MediaQuery.paddingOf(context).bottom),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
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
                            padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
                            child: Row(
                              children: [
                                Container(width: 3, height: 32, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _reply!.deleted ? s.deletedMsg : _reply!.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _reply = null),
                                  icon: const Icon(Icons.close_rounded, size: 18),
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
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                                        child: item.bytes != null
                                            ? Image.memory(item.bytes!, fit: BoxFit.cover, cacheWidth: 200, filterQuality: FilterQuality.low)
                                            : ColoredBox(
                                                color: AppColors.background,
                                                child: Icon(
                                                  switch (item.kind) {
                                                    ChatKind.pdf => Icons.picture_as_pdf_rounded,
                                                    ChatKind.video => Icons.videocam_rounded,
                                                    ChatKind.audio => Icons.mic_rounded,
                                                    ChatKind.contact => Icons.person_rounded,
                                                    _ => Icons.description_rounded,
                                                  },
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _pending.removeAt(index)),
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.black87,
                                          child: Icon(Icons.close_rounded, size: 14, color: AppColors.ink),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _shareSheet,
                              icon: const Icon(Icons.add_circle_rounded, color: AppColors.accent),
                            ),
                            if (_recording)
                              Expanded(
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _cancelAudio,
                                      icon: Icon(Icons.close_rounded, color: AppColors.inkSoft),
                                    ),
                                    const Icon(Icons.fiber_manual_record, color: Color(0xFFE36B6B), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _clock(_recSeconds),
                                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: TextStyle(color: AppColors.ink, fontSize: 15),
                                  cursorColor: AppColors.accent,
                                  decoration: InputDecoration(
                                    hintText: s.messageHint,
                                    hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.42)),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onSubmitted: (_) => _send(),
                                ),
                              ),
                            GestureDetector(
                              onTap: _mic,
                              child: Icon(
                                _recording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                                color: _recording ? const Color(0xFFE36B6B) : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _recording ? _sendAudio : _send,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.buttonGradient,
                                ),
                                child: Icon(Icons.send_rounded, color: AppColors.ink, size: 18),
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.color, required this.onMenu});

  final ChatMessage message;
  final Color color;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Padding(
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
            if (message.kind == ChatKind.pdf ||
                message.kind == ChatKind.doc ||
                message.kind == ChatKind.audio ||
                message.kind == ChatKind.video) {
              openChatFile(message);
            }
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? AppColors.bubbleMine(color) : AppColors.bubbleIn,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 18),
                ),
                border: Border.all(color: AppColors.ink.withValues(alpha: mine ? 0.08 : 0.06)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          S.of(context).deletedMsg,
                          style: TextStyle(color: AppColors.inkSoft, fontStyle: FontStyle.italic),
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
                          ),
                          child: Text(
                            message.replyText!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                          ),
                        ),
                      _bubbleBody(message),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.starred)
                          const Padding(
                            padding: EdgeInsets.only(right: 3),
                            child: Icon(Icons.star_rounded, size: 12, color: Color(0xFFE7C56A)),
                          ),
                        if (message.time != null)
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _bubbleBody(ChatMessage message) {
  switch (message.kind) {
    case ChatKind.image:
      final bytes = message.bytes;
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 210,
            height: 160,
            fit: BoxFit.cover,
            cacheWidth: 420,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          ),
        );
      }
      if (message.asset != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            message.asset!,
            width: 210,
            height: 160,
            fit: BoxFit.cover,
            cacheWidth: 420,
            filterQuality: FilterQuality.low,
          ),
        );
      }
      return _fileCard(message, Icons.image_rounded, const Color(0xFF1C8F7C));
    case ChatKind.pdf:
      return _fileCard(message, Icons.picture_as_pdf_rounded, const Color(0xFFD4656A));
    case ChatKind.doc:
      return _fileCard(message, Icons.description_rounded, const Color(0xFF3D8FD1));
    case ChatKind.audio:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: AppColors.accent, size: 34),
          const SizedBox(width: 8),
          Text(
            message.text,
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      );
    case ChatKind.video:
      return _fileCard(message, Icons.videocam_rounded, const Color(0xFF8A5A2B));
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
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                  if (phone.isNotEmpty)
                    Text(phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    case ChatKind.text:
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
                style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(phone, style: TextStyle(color: AppColors.inkSoft, fontSize: 15)),
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
                        await const MethodChannel('qapp/open_file').invokeMethod<bool>('dial', {
                          'number': number,
                        });
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.call_rounded, color: AppColors.onAccent),
                    label: Text(
                      s.voiceCall,
                      style: const TextStyle(color: AppColors.onAccent, fontWeight: FontWeight.w800),
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
      final ok = await const MethodChannel('qapp/camera_perm').invokeMethod<bool>('grant');
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
      final raw = await MethodChannel('qapp/camera_$id').invokeMethod<Uint8List>('snap');
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
                    : const Center(child: Icon(Icons.photo_camera_rounded, color: Colors.white54, size: 48)),
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
                child: Icon(Icons.circle, color: _busy ? AppColors.faint : AppColors.accent, size: 42),
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
