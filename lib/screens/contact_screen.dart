import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/open_chat_file.dart';
import 'package:qapp/screens/video_call_screen.dart';
import 'package:qapp/screens/voice_call_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  ChatThread get thread => widget.thread;

  void _call(bool video) {
    final page = video
        ? VideoCallScreen(
            name: thread.header,
            colorIndex: thread.colorIndex,
            photo: thread.photo,
            status: S.of(context).callStatus(thread.header),
          )
        : VoiceCallScreen(
            name: thread.header,
            colorIndex: thread.colorIndex,
            photo: thread.photo,
            status: S.of(context).callStatus(thread.header),
          );
    Navigator.of(context).push(qRoute(page));
  }

  Future<bool> _ask(String title) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: TextStyle(color: AppColors.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _disappear() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final s = S.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                s.disappearing,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              for (final option in ['off', '24h', '7d', '90d'])
                ListTile(
                  title: Text(
                    option == 'off' ? s.off : option,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: thread.disappear == option
                      ? const Icon(Icons.check_rounded, color: AppColors.accent)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => thread.disappear = picked);
  }

  Future<void> _theme() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).theme,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < AppColors.chatThemes.length; i++)
                      GestureDetector(
                        onTap: () {
                          thread.themeIndex = i;
                          ChatBook.instance.ping();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.chatThemes[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: thread.themeIndex == i
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addList() async {
    final controller = TextEditingController(text: thread.listName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final s = S.of(context);
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(s.addList, style: TextStyle(color: AppColors.ink)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppColors.ink),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: s.favourite,
              hintStyle: TextStyle(color: AppColors.faint),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(s.yes),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) {
      return;
    }
    thread.listName = name;
    ChatBook.instance.ping();
    setState(() {});
    _toast(S.of(context).listAdded);
  }

  Future<void> _export() async {
    final s = S.of(context);
    final text = thread.messages
        .map((message) {
          final who = message.mine ? s.you : thread.name;
          return '$who: ${message.text}';
        })
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      _toast(s.copied);
    }
  }

  Future<void> _clear() async {
    if (!await _ask(S.of(context).clearAsk) || !mounted) {
      return;
    }
    thread.messages.clear();
    thread.preview = '';
    ChatBook.instance.ping();
    Navigator.pop(context);
  }

  Future<void> _block() async {
    if (!await _ask(S.of(context).blockAsk) || !mounted) {
      return;
    }
    thread.blocked = true;
    ChatBook.instance.ping();
    Navigator.pop(context);
  }

  Future<void> _report() async {
    if (!await _ask(S.of(context).report) || !mounted) {
      return;
    }
    _toast(S.of(context).reported);
  }

  Future<void> _delete() async {
    if (!await _ask(S.of(context).deleteAsk) || !mounted) {
      return;
    }
    final nav = Navigator.of(context);
    ChatBook.instance.remove(thread);
    nav.pop();
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final media = thread.messages
        .where((message) => message.kind != ChatKind.text)
        .toList();
    final stars = thread.messages.where((message) => message.starred).length;
    final disappear = thread.disappear == 'off' ? s.off : thread.disappear;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: QAvatar(
                  name: thread.name,
                  size: 112,
                  colorIndex: thread.colorIndex,
                  photo: thread.photo,
                  bytes: thread.photoBytes,
                  online: thread.online,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                thread.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                thread.phone,
                textAlign: TextAlign.center,
                style: AppText.subtitle,
              ),
              const SizedBox(height: 4),
              Text(
                thread.about,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _action(Icons.call_rounded, s.voiceCall, () => _call(false)),
                  const SizedBox(width: 18),
                  _action(
                    Icons.videocam_rounded,
                    s.videoCall,
                    () => _call(true),
                  ),
                  const SizedBox(width: 18),
                  _action(
                    Icons.search_rounded,
                    s.search,
                    () => Navigator.pop(context, 'search'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.media,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${media.length}',
                          style: TextStyle(
                            color: AppColors.faint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (media.isEmpty)
                      Text(s.noMedia, style: AppText.subtitle)
                    else
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: media.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => _thumb(media[index]),
                        ),
                      ),
                  ],
                ),
              ),
              _tile(Icons.star_border_rounded, s.starred, '$stars', null),
              _tile(
                Icons.notifications_none_rounded,
                s.muteNotif,
                null,
                Switch(
                  value: thread.muted,
                  activeThumbColor: AppColors.accent,
                  onChanged: (value) {
                    setState(() => thread.muted = value);
                    ChatBook.instance.ping();
                  },
                ),
              ),
              _tile(
                Icons.timer_outlined,
                s.disappearing,
                disappear,
                null,
                onTap: _disappear,
              ),
              _tile(
                Icons.lock_outline_rounded,
                s.privacyAdv,
                null,
                null,
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: Text(
                        s.privacyAdv,
                        style: TextStyle(color: AppColors.ink),
                      ),
                      content: Text(
                        s.privacyHint,
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.done),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _tile(Icons.palette_outlined, s.theme, null, null, onTap: _theme),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.encrypted, style: AppText.subtitle)),
                  ],
                ),
              ),
              if (thread.phone.trim().isEmpty && thread.groups.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: Text(
                    '${thread.groups.length} ${s.members}',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                  ),
                ),
                for (final name in thread.groups) _member(name),
              ] else if (thread.groups.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: Text(
                    '${thread.groups.length} ${s.commonGroups}',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final group in thread.groups)
                  _tile(
                    Icons.groups_rounded,
                    group,
                    '${s.you}, ${thread.header}',
                    null,
                  ),
              ],
              _tile(
                thread.favourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                s.addFav,
                null,
                null,
                onTap: () {
                  setState(() => thread.favourite = !thread.favourite);
                  ChatBook.instance.ping();
                },
              ),
              _tile(
                Icons.playlist_add_rounded,
                s.addList,
                thread.listName,
                null,
                onTap: _addList,
              ),
              _tile(
                Icons.upload_rounded,
                s.exportChat,
                null,
                null,
                onTap: _export,
              ),
              const SizedBox(height: 8),
              _danger(Icons.delete_outline_rounded, s.clearChat, _clear),
              _danger(Icons.block_rounded, '${s.block} ${thread.name}', _block),
              _danger(
                Icons.thumb_down_alt_outlined,
                '${s.report} ${thread.name}',
                _report,
              ),
              _danger(Icons.delete_forever_rounded, s.deleteChat, _delete),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Material(
          color: AppColors.card,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _member(String name) {
    ChatThread? person;
    for (final item in ChatBook.instance.threads) {
      if (item.name == name && item.phone.trim().isNotEmpty) {
        person = item;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: QAvatar(
            name: name,
            size: 44,
            colorIndex: person?.colorIndex ?? 1,
            photo: person?.photo,
            bytes: person?.photoBytes,
          ),
          title: Text(name, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          subtitle: person == null || person.phone.isEmpty
              ? null
              : Text(person.phone, style: AppText.subtitle),
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String? subtitle,
    Widget? trailing, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.ink),
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: AppText.subtitle),
          trailing: trailing,
        ),
      ),
    );
  }

  Widget _danger(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: const Color(0xFFE36B6B)),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE36B6B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(ChatMessage message) {
    Widget child;
    if (message.kind == ChatKind.image && message.bytes != null) {
      child = Image.memory(
        message.bytes!,
        fit: BoxFit.cover,
        cacheWidth: 240,
        filterQuality: FilterQuality.low,
      );
    } else if (message.kind == ChatKind.image && message.asset != null) {
      child = Image.asset(message.asset!, fit: BoxFit.cover, cacheWidth: 240);
    } else {
      child = ColoredBox(
        color: const Color(0xFF155659),
        child: Icon(
          message.kind == ChatKind.pdf
              ? Icons.picture_as_pdf_rounded
              : Icons.description_rounded,
          color: AppColors.ink,
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        if (message.kind != ChatKind.image) {
          openChatFile(message);
          return;
        }
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(16),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 92, height: 92, child: child),
      ),
    );
  }
}
