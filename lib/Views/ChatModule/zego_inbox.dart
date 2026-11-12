import 'package:flutter/material.dart';
import 'package:qapp/Services/zego_session.dart';
import 'package:qapp/Views/ChatModule/zego_people_screen.dart';
import 'package:qapp/Views/ChatModule/zego_thread_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:zego_zim/zego_zim.dart';

class ZegoInbox extends StatefulWidget {
  const ZegoInbox({super.key});

  @override
  State<ZegoInbox> createState() => _ZegoInboxState();
}

class _ZegoInboxState extends State<ZegoInbox> {
  List<ZIMConversation> _rows = const [];

  @override
  void initState() {
    super.initState();
    ZegoSession.instance.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    ZegoSession.instance.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final zim = ZIM.getInstance();
    if (!ZegoSession.instance.ready || zim == null) {
      if (mounted) setState(() => _rows = const []);
      return;
    }
    try {
      final result = await zim.queryConversationList(ZIMConversationQueryConfig(count: 50));
      final peers = result.conversationList.where((item) => item.type == ZIMConversationType.peer).toList();
      if (mounted) setState(() => _rows = peers);
    } catch (_) {}
  }

  String _preview(ZIMMessage? message) {
    if (message is ZIMTextMessage) return message.message;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final session = ZegoSession.instance;
    if (!session.ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.busy
                    ? 'Chat connect ho raha hai'
                    : (session.error.isEmpty ? 'Chat abhi connect nahi hai' : session.error),
                textAlign: TextAlign.center,
                style: AppText.subtitle,
              ),
              if (!session.busy && session.error.contains('Zego')) ...[
                const SizedBox(height: 8),
                Text(
                  'Zego console se AppSign copy karke backend .env mein ZEGO_APP_SIGN=... daalo, server restart karo.',
                  textAlign: TextAlign.center,
                  style: AppText.subtitle.copyWith(fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: session.busy ? null : () => session.connect(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        _rows.isEmpty
            ? Center(child: Text('Abhi koi chat nahi. New chat se shuru karo.', style: AppText.subtitle))
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  final name = row.conversationName.trim().isEmpty ? 'Qapp user' : row.conversationName;
                  return ListTile(
                    onTap: () {
                      Navigator.of(context).push(qRoute(ZegoThreadScreen(
                        zegoId: row.conversationID,
                        name: name,
                      )));
                    },
                    leading: QAvatar(name: name, size: 48),
                    title: Text(name, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                    subtitle: Text(_preview(row.lastMessage), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle),
                    trailing: row.unreadMessageCount > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              '${row.unreadMessageCount}',
                              style: const TextStyle(color: Color(0xFF06221C), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          )
                        : null,
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent,
            onPressed: () => Navigator.of(context).push(qRoute(const ZegoPeopleScreen())),
            child: const Icon(Icons.chat_rounded, color: Color(0xFF06221C)),
          ),
        ),
      ],
    );
  }
}
