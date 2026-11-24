import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';
import 'package:qapp/Views/GroupModule/model/group_vm.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/open_chat_file.dart';
import 'package:qapp/Views/CallModule/video_call_screen.dart';
import 'package:qapp/Views/CallModule/voice_call_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/chat_media_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  ChatThread get thread => widget.thread;

  List<Map<String, dynamic>> _groupMembers = [];
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    if (!thread.isGroup && thread.phone.trim().isNotEmpty) return;
    final groupId = thread.chatId;
    if (groupId == null || groupId.isEmpty) return;
    setState(() => _loadingMembers = true);
    try {
      final details = await GroupViewModel.instance.getGroupDetails(groupId);
      if (details != null && details['members'] is List && mounted) {
        setState(() {
          _groupMembers = List<Map<String, dynamic>>.from(details['members']);
          _loadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final memberId = member['id']?.toString() ?? member['userId']?.toString();
    final memberName = member['name']?.toString() ?? 'Member';
    if (memberId == null || thread.chatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove $memberName?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              S.of(context).cancel,
              style: TextStyle(color: AppColors.faint),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await GroupViewModel.instance.removeMember(
      thread.chatId!,
      memberId,
    );
    if (success && mounted) {
      setState(() {
        _groupMembers.removeWhere(
          (m) => (m['id']?.toString() ?? m['userId']?.toString()) == memberId,
        );
      });
      _toast('$memberName removed from group');
    } else if (mounted) {
      _toast('Failed to remove member');
    }
  }

  Future<void> _saveWallpaperPrefs(
    String? path,
    int? color,
    int themeIdx,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = thread.chatId ?? thread.peerId ?? thread.phone;
      if (idKey.isNotEmpty) {
        if (path != null) {
          await prefs.setString('qapp_wallpaper_path_$idKey', path);
        } else {
          await prefs.remove('qapp_wallpaper_path_$idKey');
        }
        if (color != null) {
          await prefs.setInt('qapp_wallpaper_color_$idKey', color);
        } else {
          await prefs.remove('qapp_wallpaper_color_$idKey');
        }
        await prefs.setInt('qapp_theme_idx_$idKey', themeIdx);
      }
    } catch (_) {}
  }

  void _call(bool video) {
    final page = video
        ? VideoCallScreen(
            name: thread.header,
            colorIndex: thread.colorIndex,
            photo: thread.photo,
            status: S.of(context).callStatus(thread.header),
            recipientId: thread.peerId,
            chatId: thread.chatId,
          )
        : VoiceCallScreen(
            name: thread.header,
            colorIndex: thread.colorIndex,
            photo: thread.photo,
            status: S.of(context).callStatus(thread.header),
            recipientId: thread.peerId,
            chatId: thread.chatId,
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

  void _viewStarredMessages() {
    final starred = thread.messages.where((m) => m.starred).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Starred Messages (${starred.length})',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (starred.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No starred messages in this chat',
                        style: TextStyle(color: AppColors.faint),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: starred.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: AppColors.line),
                      itemBuilder: (context, index) {
                        final msg = starred[index];
                        Widget? mediaLeading;
                        final isImg =
                            msg.kind == ChatKind.image ||
                            (msg.fileUrl != null &&
                                msg.fileUrl!.isNotEmpty &&
                                (msg.fileUrl!.endsWith('.jpg') ||
                                    msg.fileUrl!.endsWith('.jpeg') ||
                                    msg.fileUrl!.endsWith('.png') ||
                                    msg.fileUrl!.endsWith('.webp'))) ||
                            msg.bytes != null ||
                            (msg.path != null && File(msg.path!).existsSync());

                        if (isImg) {
                          Widget imgContent;
                          if (msg.bytes != null) {
                            imgContent = Image.memory(
                              msg.bytes!,
                              fit: BoxFit.cover,
                            );
                          } else if (msg.path != null &&
                              File(msg.path!).existsSync()) {
                            imgContent = Image.file(
                              File(msg.path!),
                              fit: BoxFit.cover,
                            );
                          } else {
                            final rawUrl =
                                (msg.fileUrl != null && msg.fileUrl!.isNotEmpty)
                                ? msg.fileUrl!
                                : (isImageUrl(msg.text) ? msg.text : '');
                            imgContent = rawUrl.isNotEmpty
                                ? Image.network(
                                    rawUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.image_rounded,
                                          color: Colors.grey,
                                        ),
                                  )
                                : const Icon(
                                    Icons.image_rounded,
                                    color: AppColors.accent,
                                  );
                          }
                          mediaLeading = Container(
                            width: 50,
                            height: 50,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.card,
                              border: Border.all(color: AppColors.line),
                            ),
                            child: imgContent,
                          );
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: mediaLeading,
                          title: Text(
                            msg.text.isNotEmpty
                                ? msg.text
                                : (isImg ? 'Photo' : '[Media]'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${msg.mine ? "You" : thread.name} • ${msg.time ?? ""}',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() => msg.starred = false);
                              ChatBook.instance.ping();
                              Navigator.pop(context);
                              _toast('Message unstarred');
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _theme() async {
    final solidColors = [
      (0xFF0B141A, 'Default Dark (WhatsApp)'),
      (0xFF0D2818, 'Olive Green'),
      (0xFF0B1E2D, 'Midnight Navy'),
      (0xFF1F1A17, 'Warm Espresso'),
      (0xFF181818, 'Charcoal Black'),
      (0xFF1E172B, 'Plum Purple'),
      (0xFF054C44, 'Classic Teal'),
    ];

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
                Text(
                  'Chat Wallpaper & Theme',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await FilePicker.pickFile(
                        type: FileType.image,
                      );
                      if (file != null && file.path != null) {
                        setState(() {
                          thread.wallpaperPath = file.path;
                          thread.wallpaperColor = null;
                        });
                        _saveWallpaperPrefs(file.path, null, thread.themeIndex);
                        ChatBook.instance.ping();
                        _toast('Wallpaper updated from Gallery!');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose from Gallery',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Set custom image as chat wallpaper',
                                  style: TextStyle(
                                    color: AppColors.faint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.faint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Solid Wallpaper Colors',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: solidColors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final c = solidColors[i];
                      final isSelected =
                          thread.wallpaperPath == null &&
                          (thread.wallpaperColor == c.$1 ||
                              (thread.wallpaperColor == null && i == 0));
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            thread.wallpaperPath = null;
                            thread.wallpaperColor = c.$1;
                            thread.themeIndex = i;
                          });
                          _saveWallpaperPrefs(null, c.$1, i);
                          ChatBook.instance.ping();
                          Navigator.pop(context);
                          _toast('Wallpaper color applied');
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(c.$1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.accent,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (thread.wallpaperPath != null ||
                    thread.wallpaperColor != null)
                  Center(
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.faint,
                        size: 18,
                      ),
                      label: Text(
                        'Reset to Default Wallpaper',
                        style: TextStyle(color: AppColors.faint),
                      ),
                      onPressed: () {
                        setState(() {
                          thread.wallpaperPath = null;
                          thread.wallpaperColor = null;
                          thread.themeIndex = 0;
                        });
                        _saveWallpaperPrefs(null, null, 0);
                        ChatBook.instance.ping();
                        Navigator.pop(context);
                        _toast('Wallpaper reset to default');
                      },
                    ),
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

  Future<void> _export() async {
    final s = S.of(context);
    final buffer = StringBuffer();
    buffer.writeln('Qapp Chat Export: ${thread.name}');
    buffer.writeln(
      'Date: ${DateTime.now().toLocal().toString().split('.')[0]}',
    );
    buffer.writeln('----------------------------------------');
    for (final message in thread.messages) {
      final who = message.mine ? s.you : thread.name;
      final timeStr = message.time ?? '';
      buffer.writeln('[$timeStr] $who: ${message.text}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Total messages: ${thread.messages.length}');

    final text = buffer.toString();
    await Clipboard.setData(ClipboardData(text: text));

    try {
      await const MethodChannel('qapp/open_file').invokeMethod('share', {
        'text': text,
        'title': 'Export Chat - ${thread.name}',
      });
    } catch (_) {}

    if (mounted) {
      _toast('Chat exported and copied to clipboard');
    }
  }

  Future<void> _clear() async {
    if (!await _ask(S.of(context).clearAsk) || !mounted) {
      return;
    }
    if (thread.chatId != null) {
      await ChatViewModel.instance.clearChat(thread.chatId!);
    }
    thread.messages.clear();
    thread.preview = '';
    ChatBook.instance.ping();
    _toast('Chat history cleared');
    Navigator.pop(context);
  }

  Future<void> _block() async {
    if (!await _ask(S.of(context).blockAsk) || !mounted) {
      return;
    }
    thread.blocked = true;
    if (thread.peerId != null) {
      await ChatViewModel.instance.blockUser(thread.peerId!);
    }
    ChatBook.instance.ping();
    _toast('${thread.name} has been blocked');
    Navigator.pop(context);
  }

  Future<void> _report() async {
    String category = 'spam';
    final descCtrl = TextEditingController();
    bool alsoBlock = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.report_problem_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Report ${thread.name}',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please specify the reason for reporting this contact. Our safety & moderation team will review it immediately.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'spam',
                              child: Text('Spam or unsolicited messages'),
                            ),
                            DropdownMenuItem(
                              value: 'harassment',
                              child: Text('Harassment or abusive behavior'),
                            ),
                            DropdownMenuItem(
                              value: 'inappropriate',
                              child: Text('Inappropriate content'),
                            ),
                            DropdownMenuItem(
                              value: 'fraud',
                              child: Text('Scam, phishing, or fraud'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDlgState(() => category = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.ink, fontSize: 13),
                      cursorColor: AppColors.accent,
                      decoration: InputDecoration(
                        hintText: 'Describe what happened (optional)...',
                        hintStyle: TextStyle(
                          color: AppColors.faint,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: alsoBlock,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            setDlgState(() => alsoBlock = val == true);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Also block contact and delete chat',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    S.of(context).cancel,
                    style: TextStyle(color: AppColors.faint),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final desc = descCtrl.text.trim();
    if (thread.peerId != null) {
      await ChatViewModel.instance.reportAndBlockUser(
        targetUserId: thread.peerId!,
        category: category,
        reason: category,
        description: desc.isNotEmpty
            ? desc
            : 'Reported from mobile contact screen',
        block: alsoBlock,
      );
    }

    if (alsoBlock) {
      thread.blocked = true;
      ChatBook.instance.remove(thread);
    }
    ChatBook.instance.ping();
    _toast('Report submitted successfully. Thank you for keeping Qapp safe.');
    if (alsoBlock && mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    if (!await _ask(S.of(context).deleteAsk) || !mounted) {
      return;
    }
    if (thread.chatId != null) {
      await ChatViewModel.instance.clearChat(thread.chatId!);
    }
    final nav = Navigator.of(context);
    ChatBook.instance.remove(thread);
    _toast('Chat deleted');
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
              if (thread.phone.trim().isNotEmpty)
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: thread.phone.trim()),
                      );
                      _toast('Phone number copied!');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            thread.phone,
                            textAlign: TextAlign.center,
                            style: AppText.subtitle.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
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
              _tile(
                Icons.star_border_rounded,
                s.starred,
                '$stars',
                null,
                onTap: _viewStarredMessages,
              ),
              _tile(
                Icons.notifications_none_rounded,
                s.muteNotif,
                null,
                Switch(
                  value: thread.muted,
                  activeThumbColor: AppColors.accent,
                  onChanged: (value) {
                    ChatBook.instance.toggleMute(thread);
                    setState(() {});
                  },
                ),
              ),
              _tile(
                Icons.palette_outlined,
                'Chat Wallpaper & Theme',
                thread.wallpaperPath != null ? 'Custom' : null,
                null,
                onTap: _theme,
              ),
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
              if (thread.isGroup || thread.phone.trim().isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: Row(
                    children: [
                      Text(
                        '${_groupMembers.isNotEmpty ? _groupMembers.length : thread.groups.length} ${s.members}',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (_loadingMembers)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_groupMembers.isNotEmpty)
                  for (final m in _groupMembers) _buildGroupMemberTile(m)
                else if (thread.groups.isNotEmpty)
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
                thread.favourite ? 'Remove from Favourites' : s.addFav,
                null,
                null,
                onTap: () {
                  ChatBook.instance.toggleFavourite(thread);
                  setState(() {});
                  _toast(
                    thread.favourite
                        ? 'Added to Favourites'
                        : 'Removed from Favourites',
                  );
                },
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
          title: Text(
            name,
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
          subtitle: person == null || person.phone.isEmpty
              ? null
              : Text(person.phone, style: AppText.subtitle),
        ),
      ),
    );
  }

  Widget _buildGroupMemberTile(Map<String, dynamic> member) {
    final name = member['name']?.toString() ?? 'Member';
    final phone = member['phone']?.toString() ?? '';
    final role = member['role']?.toString() ?? 'member';
    final photo =
        member['photoUrl']?.toString() ?? member['profileImageUrl']?.toString();
    final isAdmin = role == 'admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: QAvatar(name: name, size: 44, colorIndex: 2, photo: photo),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Group Admin',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: phone.isNotEmpty
              ? Text(phone, style: AppText.subtitle)
              : null,
          trailing: IconButton(
            icon: const Icon(
              Icons.person_remove_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            tooltip: 'Remove member',
            onPressed: () => _removeMember(member),
          ),
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
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
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
