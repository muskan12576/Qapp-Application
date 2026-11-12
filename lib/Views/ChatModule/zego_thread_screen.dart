import 'package:flutter/material.dart';
import 'package:qapp/Services/zego_session.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:zego_zim/zego_zim.dart';

class ZegoThreadScreen extends StatefulWidget {
  const ZegoThreadScreen({super.key, required this.zegoId, required this.name});

  final String zegoId;
  final String name;

  @override
  State<ZegoThreadScreen> createState() => _ZegoThreadScreenState();
}

class _ZegoThreadScreenState extends State<ZegoThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ZIMMessage> _messages = const [];
  bool _busy = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    ZegoSession.instance.addListener(_onInbox);
    _load();
  }

  @override
  void dispose() {
    ZegoSession.instance.removeListener(_onInbox);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onInbox() {
    _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    final zim = ZIM.getInstance();
    if (zim == null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Zego login nahi hai';
        });
      }
      return;
    }
    try {
      final result = await zim.queryHistoryMessage(
        widget.zegoId,
        ZIMConversationType.peer,
        ZIMMessageQueryConfig(count: 50, reverse: true),
      );
      final list = List<ZIMMessage>.from(result.messageList)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (!mounted) return;
      setState(() {
        _messages = list;
        _error = '';
        _busy = false;
      });
      _jump();
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _busy = false;
        _error = 'Messages load nahi hue';
      });
    }
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final zim = ZIM.getInstance();
    if (text.isEmpty || zim == null) return;
    _input.clear();
    try {
      await zim.sendMessage(
        ZIMTextMessage(message: text),
        widget.zegoId,
        ZIMConversationType.peer,
        ZIMMessageSendConfig(),
      );
      await _load(silent: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message nahi gaya')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(widget.name, style: AppText.title),
                  ),
                ],
              ),
              Expanded(
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: _messages.length + (_error.isEmpty ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (_error.isNotEmpty && index == 0) {
                            return Text(_error, style: const TextStyle(color: Color(0xFFFF8A80)));
                          }
                          final message = _messages[_error.isEmpty ? index : index - 1];
                          final mine = message.direction == ZIMMessageDirection.send;
                          final text = message is ZIMTextMessage ? message.message : message.toMap()['message']?.toString() ?? '';
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.outgoing : AppColors.incoming,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(text, style: TextStyle(color: AppColors.ink, fontSize: 16)),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        style: TextStyle(color: AppColors.ink),
                        cursorColor: AppColors.accent,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: AppColors.faint),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: Icon(Icons.send_rounded, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
