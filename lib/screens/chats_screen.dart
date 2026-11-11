import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/chat_open_screen.dart';
import 'package:qapp/screens/settings_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/qapp_logo.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/q_field.dart';
import 'package:qapp/widgets/tick_mark.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.onAddStatus});

  final VoidCallback onAddStatus;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final AnimationController _pulse;
  String _chip = 'all';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return QBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ListenableBuilder(
            listenable: ChatBook.instance,
            builder: (context, _) {
              final query = _search.text.trim().toLowerCase();
              final everyone = ChatBook.instance.threads;
              final unreadCount = everyone.where((thread) => thread.unread > 0).length;
              final groupCount = everyone.where((thread) => thread.phone.trim().isEmpty).length;
              final threads = everyone.where((thread) {
                final matchesQuery = query.isEmpty ||
                    thread.name.toLowerCase().contains(query) ||
                    thread.preview.toLowerCase().contains(query);
                if (!matchesQuery) {
                  return false;
                }
                if (_chip == 'unread') {
                  return thread.unread > 0;
                }
                if (_chip == 'fav') {
                  return thread.favourite;
                }
                if (_chip == 'groups') {
                  return thread.phone.trim().isEmpty;
                }
                return true;
              }).toList()
                ..sort((a, b) {
                  if (a.pinned == b.pinned) {
                    return 0;
                  }
                  return a.pinned ? -1 : 1;
                });

              return Stack(
                children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const QappLogo(width: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.chats,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(qRoute(const SettingsScreen()));
                          },
                          icon: Icon(
                            Icons.settings_rounded,
                            color: AppColors.ink.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QField(
                      controller: _search,
                      hint: s.search,
                      dense: true,
                      onChanged: (_) => setState(() {}),
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _chipButton(s.all, 'all'),
                        _chipButton(
                          unreadCount > 0 ? '${s.unread} $unreadCount' : s.unread,
                          'unread',
                        ),
                        _chipButton(s.favourite, 'fav'),
                        _chipButton(
                          groupCount > 0 ? '${s.groups} $groupCount' : s.groups,
                          'groups',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: threads.isEmpty
                        ? Center(
                            child: Text(s.noChats, style: AppText.subtitle),
                          )
                        : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(top: 8, bottom: 96),
                            itemCount: threads.length,
                            itemBuilder: (context, index) {
                              return _ChatRow(thread: threads[index]);
                            },
                          ),
                  ),
                ],
              ),
                  // Chat-list plus is off for now.
                  // Positioned(
                  //   right: 4,
                  //   bottom: 12,
                  //   child: _AddPulse(
                  //     animation: _pulse,
                  //     onTap: widget.onAddStatus,
                  //   ),
                  // ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chipButton(String label, String value) {
    final on = _chip == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _chip = value),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = on ? _pulse.value : 0.0;
            final fill = on
                ? Color.lerp(const Color(0xFFB8F5D8), const Color(0xFF3DDC97), t)!
                : Colors.transparent;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: on ? fill : AppColors.ink.withValues(alpha: 0.28),
                ),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3DDC97).withValues(alpha: 0.2 + t * 0.45),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: on ? const Color(0xFF06221C) : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AddPulse extends StatelessWidget {
  const _AddPulse({required this.animation, required this.onTap});

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow = 8 + (animation.value * 14);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3DDC97).withValues(alpha: 0.28 + animation.value * 0.35),
                blurRadius: glow,
                spreadRadius: animation.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: const Color(0xFF1FA37A),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(Icons.add_rounded, color: AppColors.ink, size: 30),
          ),
        ),
      ),
    );
  }
}

void _chatMenu(BuildContext context, ChatThread thread) {
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
            _sheetTile(thread.pinned ? s.unpin : s.pinned, Icons.push_pin_rounded, () {
              thread.pinned = !thread.pinned;
              ChatBook.instance.ping();
              Navigator.pop(sheet);
            }),
            _sheetTile(thread.muted ? s.unmute : s.muteNotif, Icons.notifications_off_rounded, () {
              thread.muted = !thread.muted;
              ChatBook.instance.ping();
              Navigator.pop(sheet);
            }),
            _sheetTile(s.clearChat, Icons.cleaning_services_rounded, () {
              thread.messages.clear();
              thread.preview = '';
              thread.unread = 0;
              ChatBook.instance.ping();
              Navigator.pop(sheet);
            }),
            _sheetTile(thread.blocked ? s.unblock : s.block, Icons.block_rounded, () {
              thread.blocked = !thread.blocked;
              ChatBook.instance.ping();
              Navigator.pop(sheet);
            }),
            _sheetTile(s.deleteChat, Icons.delete_outline_rounded, () {
              ChatBook.instance.remove(thread);
              Navigator.pop(sheet);
            }),
          ],
        ),
      );
    },
  );
}

Widget _sheetTile(String label, IconData icon, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: AppColors.ink),
    title: Text(label, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
    onTap: onTap,
  );
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final last = thread.messages.isEmpty ? null : thread.messages.last;
    final count = thread.unread > 99 ? '99+' : '${thread.unread}';
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(qRoute(ChatOpenScreen(thread: thread)));
            },
            onLongPress: () => _chatMenu(context, thread),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  QAvatar(
                    name: thread.name,
                    size: 52,
                    colorIndex: thread.colorIndex,
                    photo: thread.photo,
                    bytes: thread.photoBytes,
                    online: thread.online,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                thread.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (thread.pinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.accent),
                              ),
                            if (thread.muted)
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.notifications_off_rounded,
                                  size: 15,
                                  color: AppColors.faint,
                                ),
                              ),
                            Text(
                              thread.time,
                              style: TextStyle(
                                color: thread.unread > 0 ? AppColors.accent : AppColors.faint,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (last != null && last.mine) ...[
                              TickMark(last.tick, size: 15),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                thread.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.muted, fontSize: 14),
                              ),
                            ),
                            if (thread.unread > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _unreadBadge(count),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 80),
          height: 0.6,
          color: AppColors.ink.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

Widget _unreadBadge(String count) {
  return Container(
    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.all(Radius.circular(11)),
    ),
    child: Text(
      count,
      style: const TextStyle(
        color: AppColors.onAccent,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
