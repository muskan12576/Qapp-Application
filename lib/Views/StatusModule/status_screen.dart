import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/Views/StatusModule/my_status_screen.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, this.focusTick = 0});

  final int focusTick;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void didUpdateWidget(StatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTick != oldWidget.focusTick) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open(String name, String caption, int colorIndex) {
    Navigator.of(context).push(
      qRoute(
        StatusViewScreen(
          name: name,
          caption: caption,
          colorIndex: colorIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mine = MyProfile.name.trim().isEmpty ? s.you : MyProfile.name.trim();
    final query = _search.text.trim().toLowerCase();
    bool matches(String name, String caption) {
      if (query.isEmpty) {
        return true;
      }
      return name.toLowerCase().contains(query) || caption.toLowerCase().contains(query);
    }

    final people = statusFriends.where((person) => matches(person.name, person.caption)).toList();
    final recent = people.take(2).toList();
    final viewed = people.skip(2).toList();
    return ListenableBuilder(
      listenable: StatusBook.instance,
      builder: (context, _) {
        final latest = StatusBook.instance.mine.isEmpty ? null : StatusBook.instance.mine.first;
        final mineCaption = latest == null
            ? s.tapStatus
            : (latest.caption.isEmpty ? s.image : latest.caption);
        final showMine = matches(mine, mineCaption) || matches(s.myStatus, mineCaption);
        return QBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.statusTitle, style: AppText.title)),
                Material(
                  color: AppColors.bubbleIn,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() {}),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.refresh_rounded, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bubbleIn,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                cursorColor: AppColors.accent,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: s.search,
                  hintStyle: TextStyle(color: AppColors.faint),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.inkSoft),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (showMine) ...[
              Text(s.myStatus, style: _label),
              const SizedBox(height: 8),
              _card(
                name: mine,
                title: s.myStatus,
                subtitle: mineCaption,
                colorIndex: 2,
                bytes: MyProfile.photo,
                badge: true,
                onTap: () {
                  Navigator.of(context).push(qRoute(const MyStatusScreen()));
                },
                onBadge: () {
                  Navigator.of(context).push(qRoute(const AddStatusScreen()));
                },
              ),
              const SizedBox(height: 16),
            ],
            if (recent.isNotEmpty) Text(s.recentUpdates, style: _label),
            const SizedBox(height: 8),
            for (var i = 0; i < recent.length; i++)
              _card(
                name: recent[i].name,
                title: recent[i].name,
                subtitle: recent[i].caption.isEmpty
                    ? (i == 0 ? '2 minutes ago' : '15 minutes ago')
                    : recent[i].caption,
                colorIndex: recent[i].colorIndex,
                photo: recent[i].photo,
                onTap: () => _open(
                  recent[i].name,
                  recent[i].caption.isEmpty ? recent[i].name : recent[i].caption,
                  recent[i].colorIndex,
                ),
              ),
            if (viewed.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(s.viewedUpdates, style: _label),
            const SizedBox(height: 8),
            for (final person in viewed)
              _card(
                name: person.name,
                title: person.name,
                subtitle: person.caption.isEmpty ? 'Today, 9:12 PM' : person.caption,
                colorIndex: person.colorIndex,
                photo: person.photo,
                seen: true,
                onTap: () => _open(
                  person.name,
                  person.caption.isEmpty ? person.name : person.caption,
                  person.colorIndex,
                ),
              ),
            ],
            if (!showMine && people.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(child: Text(s.noChats, style: AppText.subtitle)),
              ),
          ],
        ),
      ),
    );
      },
    );
  }

  static final _label = TextStyle(
    color: AppColors.inkSoft,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  Widget _card({
    required String name,
    required String title,
    required String subtitle,
    required int colorIndex,
    required VoidCallback onTap,
    String? photo,
    Uint8List? bytes,
    bool badge = false,
    bool seen = false,
    VoidCallback? onBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: seen ? AppColors.line : AppColors.accent,
                          width: 2,
                        ),
                      ),
                      child: QAvatar(
                        name: name,
                        size: 46,
                        colorIndex: colorIndex,
                        photo: photo,
                        bytes: bytes,
                      ),
                    ),
                    if (badge)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: GestureDetector(
                          onTap: onBadge,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1FA37A),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add, size: 14, color: AppColors.ink),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
