import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/Views/ChatModule/chat_open_screen.dart';
import 'package:qapp/Views/ChatModule/new_chat_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/q_field.dart';
import 'package:qapp/widgets/qapp_logo.dart';

void _openNamed(BuildContext context, String name, List<String> members) {
  final book = ChatBook.instance;
  ChatThread? found;
  for (final thread in book.threads) {
    if (thread.phone.trim().isEmpty && thread.name == name) {
      found = thread;
      break;
    }
  }
  final thread = found ??
      ChatThread(
        name: name,
        header: name,
        time: S.of(context).now,
        preview: members.join(', '),
        colorIndex: 2,
        phone: '',
        about: S.of(context).groups,
        messages: [],
        groups: members,
      );
  if (found == null) {
    book.add(thread);
  }
  Navigator.of(context).push(qRoute(ChatOpenScreen(thread: thread)));
}

class _GroupRow {
  const _GroupRow({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.count,
    required this.favourite,
    required this.pinned,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String time;
  final int count;
  final bool favourite;
  final bool pinned;
  final VoidCallback onTap;
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
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
              final threads = ChatBook.instance.threads;
              final created = threads.where((thread) => thread.phone.trim().isEmpty).toList();
              final named = <String, List<String>>{};
              for (final thread in threads) {
                if (thread.phone.trim().isEmpty) {
                  continue;
                }
                for (final group in thread.groups) {
                  named.putIfAbsent(group, () => []).add(thread.name);
                }
              }
              for (final group in created) {
                named.remove(group.name);
              }
              final rows = <_GroupRow>[
                for (final group in created)
                  _GroupRow(
                    name: group.name,
                    subtitle: group.preview.isEmpty
                        ? (group.groups.isEmpty ? s.groups : group.groups.join(', '))
                        : group.preview,
                    time: group.time,
                    count: group.unread,
                    favourite: group.favourite,
                    pinned: group.pinned,
                    onTap: () {
                      Navigator.of(context).push(qRoute(ChatOpenScreen(thread: group)));
                    },
                  ),
                for (final entry in named.entries)
                  _GroupRow(
                    name: entry.key,
                    subtitle: entry.value.join(', '),
                    time: '',
                    count: 0,
                    favourite: false,
                    pinned: false,
                    onTap: () => _openNamed(context, entry.key, entry.value),
                  ),
              ];
              final unreadCount = rows.where((row) => row.count > 0).length;
              final visible = rows.where((row) {
                final matches = query.isEmpty ||
                    row.name.toLowerCase().contains(query) ||
                    row.subtitle.toLowerCase().contains(query);
                if (!matches) {
                  return false;
                }
                if (_chip == 'unread') {
                  return row.count > 0;
                }
                if (_chip == 'fav') {
                  return row.favourite;
                }
                return true;
              }).toList()
                ..sort((a, b) {
                  if (a.pinned == b.pinned) {
                    return 0;
                  }
                  return a.pinned ? -1 : 1;
                });

              return Column(
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
                            s.groups,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(qRoute(const NewGroupScreen()));
                          },
                          icon: const Icon(Icons.group_add_rounded, color: AppColors.accent),
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
                        _chipButton(unreadCount > 0 ? '${s.unread} $unreadCount' : s.unread, 'unread'),
                        _chipButton(s.favourite, 'fav'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(child: Text(s.noChats, style: AppText.subtitle))
                        : ListView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(top: 8, bottom: 96),
                            children: [
                              for (final row in visible) _tile(row),
                            ],
                          ),
                  ),
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

  Widget _tile(_GroupRow row) {
    final badge = row.count > 99 ? '99+' : '${row.count}';
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: row.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3DDC97), Color(0xFF0E6A58)],
                      ),
                    ),
                    child: Icon(Icons.groups_rounded, color: AppColors.ink, size: 28),
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
                                row.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (row.pinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.accent),
                              ),
                            if (row.time.isNotEmpty)
                              Text(
                                row.time,
                                style: TextStyle(
                                  color: row.count > 0 ? AppColors.accent : AppColors.faint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.muted, fontSize: 14),
                              ),
                            ),
                            if (row.count > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _unreadBadge(badge),
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
