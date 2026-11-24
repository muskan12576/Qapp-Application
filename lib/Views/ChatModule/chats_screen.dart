import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Services/speech_service.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';
import 'package:qapp/Views/StatusModule/model/status_vm.dart';
import 'package:qapp/Views/StatusModule/my_status_screen.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/Views/ChatModule/chat_open_screen.dart';
import 'package:qapp/Views/ChatModule/new_chat_screen.dart';
import 'package:qapp/Views/AiAssistantModule/ai_assistant_sheet.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/q_field.dart';
import 'package:qapp/widgets/qapp_logo.dart';
import 'package:qapp/widgets/status_progress_ring.dart';
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
  Timer? _refreshTimer;
  StreamSubscription? _activitySub;
  bool _searchOpen = false;
  bool _isListeningVoice = false;

  @override
  void initState() {
    super.initState();
    ChatBook.instance.loadLiveChats();
    StatusViewModel.instance.getStatusFeed();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ChatBook.instance.loadLiveChats();
        StatusViewModel.instance.getStatusFeed();
      }
    });

    // Real-time activity notifications (likes, message reactions)
    _activitySub = ChatSocketService.instance.onActivityNotification.listen((data) {
      if (!mounted) return;
      final title = data['title']?.toString() ?? 'Qapp';
      final body = data['body']?.toString() ?? 'New activity';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFFF2A6D), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title: $body',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    if (_isListeningVoice) {
      SpeechService.instance.stopListening();
    }
    _activitySub?.cancel();
    _refreshTimer?.cancel();
    _pulse.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListeningVoice) {
      await SpeechService.instance.stopListening();
      if (mounted) setState(() => _isListeningVoice = false);
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _isListeningVoice = true;
      _searchOpen = true;
      _chip = 'all';
    });

    final ok = await SpeechService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        final clean = text.trim().replaceAll(RegExp(r'[\.\,\!\?]+$'), '');
        setState(() {
          _search.text = clean;
          _search.selection = TextSelection.fromPosition(
            TextPosition(offset: _search.text.length),
          );
          if (isFinal) {
            _isListeningVoice = false;
          }
        });
      },
    );

    if (!ok && mounted) {
      setState(() => _isListeningVoice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mic permission ya speech service available nahi hai'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return QBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListenableBuilder(
            listenable: Listenable.merge([ChatBook.instance, StatusViewModel.instance]),
            builder: (context, _) {
              final query = _search.text.trim().toLowerCase();
              final everyone = ChatBook.instance.threads;
              final unreadCount = everyone.where((thread) => thread.unread > 0).length;
              final groupCount = everyone.where((thread) => thread.isGroup || thread.phone.trim().isEmpty).length;
              final threads = everyone.where((thread) {
                final matchesQuery = query.isEmpty ||
                    thread.name.toLowerCase().contains(query) ||
                    thread.preview.toLowerCase().contains(query) ||
                    thread.phone.toLowerCase().contains(query);
                if (!matchesQuery) {
                  return false;
                }
                // When actively searching, search across all chats/groups
                if (query.isEmpty) {
                  if (_chip == 'unread') {
                    return thread.unread > 0;
                  }
                  if (_chip == 'fav') {
                    return thread.favourite;
                  }
                  if (_chip == 'groups') {
                    return thread.isGroup || thread.phone.trim().isEmpty;
                  }
                  // In main chats tab ('all' filter), show 1-on-1 chats so duplicate groups don't clutter chats list
                  if (_chip == 'all' && (thread.isGroup || thread.phone.trim().isEmpty)) {
                    return false;
                  }
                }
                return true;
              }).toList()
                ..sort((a, b) {
                  // When searching, sort exact matches and prefix matches to the very top (e.g. Muskan)
                  if (query.isNotEmpty) {
                    final aName = a.name.toLowerCase();
                    final bName = b.name.toLowerCase();

                    // 1. Exact contact name match comes first
                    final aExact = aName == query;
                    final bExact = bName == query;
                    if (aExact != bExact) {
                      return aExact ? -1 : 1;
                    }

                    // 2. Starts with name comes second
                    final aStarts = aName.startsWith(query);
                    final bStarts = bName.startsWith(query);
                    if (aStarts != bStarts) {
                      return aStarts ? -1 : 1;
                    }

                    // 3. Name contains query before preview contains query
                    final aInName = aName.contains(query);
                    final bInName = bName.contains(query);
                    if (aInName != bInName) {
                      return aInName ? -1 : 1;
                    }
                  }
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
                      // Top Bar (Matching Image 2 Style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            // Qapp Logo and App Name
                            const QappLogo(width: 32),
                            const SizedBox(width: 10),
                            Text(
                              'Qapp',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              tooltip: 'Qapp AI Voice Assistant',
                              onPressed: () => AiAssistantSheet.show(context),
                              icon: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3DDC97), Color(0xFF149E86)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.black,
                                  size: 17,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchOpen = !_searchOpen;
                                  if (!_searchOpen) {
                                    _search.clear();
                                  }
                                });
                              },
                              icon: Icon(
                                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                                color: AppColors.ink.withValues(alpha: 0.9),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Collapsible Search Field
                      if (_searchOpen) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: QField(
                            controller: _search,
                            hint: _isListeningVoice ? 'Listening... Bolie' : s.search,
                            dense: true,
                            onChanged: (_) => setState(() {}),
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 6),
                              child: Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 22),
                            ),
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_search.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: AppColors.inkSoft, size: 20),
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                                    color: _isListeningVoice ? Colors.redAccent : const Color(0xFF25D366),
                                    size: 22,
                                  ),
                                  tooltip: _isListeningVoice ? 'Listening... Tap to stop' : 'Voice Search',
                                  onPressed: _toggleVoiceSearch,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Horizontal Stories Row at the Top (Image 2)
                      _storiesBar(context),

                      // Section Title: RECENT CHATS (Image 2)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              'RECENT CHATS',
                              style: TextStyle(
                                color: AppColors.inkSoft.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            // Chip filter row in line or below
                          ],
                        ),
                      ),

                      // Filter Chips
                      SizedBox(
                        height: 34,
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
                      const SizedBox(height: 6),

                      // Chat List
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFF25D366),
                          backgroundColor: AppColors.card,
                          onRefresh: () async {
                            await Future.wait([
                              ChatBook.instance.loadLiveChats(),
                              StatusViewModel.instance.getStatusFeed(),
                            ]);
                          },
                          child: threads.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.sizeOf(context).height * 0.35,
                                      child: Center(
                                        child: Text(s.noChats, style: AppText.subtitle),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 4, bottom: 90),
                                  itemCount: threads.length,
                                  itemBuilder: (context, index) => _ChatRow(thread: threads[index]),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Floating Action Button at Bottom Right (Image 2)
                  Positioned(
                    right: 18,
                    bottom: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(qRoute(const NewChatScreen()));
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.buttonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1FA37A).withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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

  Widget _storiesBar(BuildContext context) {
    final myStatus = StatusViewModel.instance.myStatus;
    final myStatuses = (myStatus?['statuses'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    final hasMyStatus = myStatuses.isNotEmpty;
    final others = StatusViewModel.instance.otherStatuses;

    return Container(
      height: 98,
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 1 + others.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            // My Status Item
            return _MyStoryAvatarItem(
              hasStatus: hasMyStatus,
              statuses: myStatuses,
              onAdd: () {
                Navigator.of(context)
                    .push(qRoute(const AddStatusScreen()))
                    .then((_) => StatusViewModel.instance.getStatusFeed());
              },
              onView: () {
                if (hasMyStatus) {
                  final latest = myStatuses.first;
                  Navigator.of(context).push(
                    qRoute(
                      StatusViewScreen(
                        name: 'My Status',
                        caption: latest['caption']?.toString() ?? '',
                        colorIndex: 2,
                        mediaUrl: latest['mediaUrl']?.toString(),
                        kind: latest['kind']?.toString() ?? 'text',
                        youtubeVideoId: latest['youtubeVideoId']?.toString(),
                        sourceUrl: latest['sourceUrl']?.toString(),
                        ownerId: myStatus?['userId']?.toString(),
                        statusId: latest['id']?.toString(),
                        isMine: true,
                        viewCount: latest['viewCount'] is int ? latest['viewCount'] as int : 0,
                        statuses: myStatuses,
                      ),
                    ),
                  ).then((_) => StatusViewModel.instance.getStatusFeed());
                } else {
                  Navigator.of(context)
                      .push(qRoute(const AddStatusScreen()))
                      .then((_) => StatusViewModel.instance.getStatusFeed());
                }
              },
            );
          }

          final peer = others[index - 1];
          final pStatuses = (peer['statuses'] as List? ?? [])
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList();
          final hasUnviewed = pStatuses.any((s) => s['hasViewed'] != true);
          final userName = peer['userName']?.toString() ?? peer['name']?.toString() ?? 'User';
          final userPhoto = peer['userPhoto']?.toString() ?? peer['photoUrl']?.toString();
          final userId = peer['userId']?.toString();

          return _PeerStoryAvatarItem(
            name: userName,
            photo: userPhoto,
            statuses: pStatuses,
            hasUnviewed: hasUnviewed,
            colorIndex: index % 5,
            onTap: () {
              if (pStatuses.isEmpty) return;
              final latest = pStatuses.first;
              Navigator.of(context).push(
                qRoute(
                  StatusViewScreen(
                    name: userName,
                    caption: latest['caption']?.toString() ?? '',
                    colorIndex: index % 5,
                    mediaUrl: latest['mediaUrl']?.toString(),
                    kind: latest['kind']?.toString() ?? 'text',
                    youtubeVideoId: latest['youtubeVideoId']?.toString(),
                    sourceUrl: latest['sourceUrl']?.toString(),
                    ownerId: userId,
                    statusId: latest['id']?.toString(),
                    isMine: false,
                    statuses: pStatuses,
                  ),
                ),
              ).then((_) => StatusViewModel.instance.getStatusFeed());
            },
          );
        },
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
                ? Color.lerp(const Color(0xFF25D366), const Color(0xFF1DB954), t)!
                : Colors.transparent;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: on ? fill : AppColors.ink.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: const Color(0xFF25D366).withValues(alpha: 0.25 + t * 0.25),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: on ? Colors.black : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyStoryAvatarItem extends StatelessWidget {
  const _MyStoryAvatarItem({
    required this.hasStatus,
    required this.statuses,
    required this.onAdd,
    required this.onView,
  });

  final bool hasStatus;
  final List<Map<String, dynamic>> statuses;
  final VoidCallback onAdd;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: hasStatus ? onView : onAdd,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  StatusProgressRing(
                    hasStatus: hasStatus,
                    hasUnviewed: false,
                    totalStatuses: statuses.length,
                    ringWidth: 2.5,
                    padding: 2.2,
                    child: QAvatar(
                      name: MyProfile.name.isNotEmpty ? MyProfile.name : 'Me',
                      bytes: MyProfile.photo,
                      size: 48,
                      colorIndex: 2,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.add, color: Colors.black, size: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'My status',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeerStoryAvatarItem extends StatelessWidget {
  const _PeerStoryAvatarItem({
    required this.name,
    required this.photo,
    required this.statuses,
    required this.hasUnviewed,
    required this.colorIndex,
    required this.onTap,
  });

  final String name;
  final String? photo;
  final List<Map<String, dynamic>> statuses;
  final bool hasUnviewed;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusProgressRing(
                hasStatus: true,
                hasUnviewed: hasUnviewed,
                totalStatuses: statuses.length,
                ringWidth: 2.5,
                padding: 2.2,
                child: QAvatar(
                  name: name,
                  photo: photo,
                  size: 48,
                  colorIndex: colorIndex,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
              ChatBook.instance.togglePin(thread);
              Navigator.pop(sheet);
            }),
            _sheetTile(
              thread.favourite ? 'Remove from Favourites' : s.addFav,
              thread.favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              () {
                ChatBook.instance.toggleFavourite(thread);
                Navigator.pop(sheet);
              },
            ),
            _sheetTile(thread.muted ? s.unmute : s.muteNotif, Icons.notifications_off_rounded, () {
              ChatBook.instance.toggleMute(thread);
              Navigator.pop(sheet);
            }),
            _sheetTile(s.clearChat, Icons.cleaning_services_rounded, () {
              final chatId = thread.chatId;
              if (chatId != null && chatId.isNotEmpty) {
                ChatViewModel.instance.clearChat(chatId);
              }
              thread.messages.clear();
              thread.preview = '';
              thread.unread = 0;
              ChatBook.instance.ping();
              Navigator.pop(sheet);
            }),
            _sheetTile(thread.blocked ? s.unblock : s.block, Icons.block_rounded, () {
              ChatBook.instance.toggleBlock(thread);
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

    // Story ring check for this contact
    final userGroup = StatusViewModel.instance.otherStatuses.firstWhere(
      (u) =>
          u['userId']?.toString() == thread.peerId ||
          (u['id'] != null && u['id']?.toString() == thread.peerId),
      orElse: () => {},
    );
    final statuses = (userGroup['statuses'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    final hasStatus = statuses.isNotEmpty;
    final hasUnviewed = statuses.any((s) => s['hasViewed'] != true);

    // Profile Avatar with StatusProgressRing
    final avatar = StatusProgressRing(
      hasStatus: hasStatus,
      hasUnviewed: hasUnviewed,
      totalStatuses: statuses.length,
      ringWidth: 2.6,
      padding: 2.4,
      onTap: hasStatus
          ? () {
              final latest = statuses.first;
              Navigator.of(context).push(
                qRoute(
                  StatusViewScreen(
                    name: thread.name,
                    caption: latest['caption']?.toString() ?? '',
                    colorIndex: thread.colorIndex,
                    mediaUrl: latest['mediaUrl']?.toString(),
                    kind: latest['kind']?.toString() ?? 'text',
                    youtubeVideoId: latest['youtubeVideoId']?.toString(),
                    sourceUrl: latest['sourceUrl']?.toString(),
                    ownerId: thread.peerId,
                    statusId: latest['id']?.toString(),
                    isMine: false,
                    statuses: statuses,
                  ),
                ),
              ).then((_) => StatusViewModel.instance.getStatusFeed());
            }
          : null,
      child: QAvatar(
        name: thread.name,
        size: hasStatus ? 48 : 52,
        colorIndex: thread.colorIndex,
        photo: thread.photo,
        bytes: thread.photoBytes,
        online: thread.online,
      ),
    );

    // Subtitle text: typing, last message preview, or live status / last seen
    Widget subtitleWidget;
    if (thread.isTyping) {
      subtitleWidget = Text(
        (thread.isGroup && thread.typingUserName != null && thread.typingUserName!.isNotEmpty)
            ? '${thread.typingUserName} is typing...'
            : 'typing...',
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF25D366),
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (thread.preview.isNotEmpty && thread.preview != 'Tap to chat') {
      subtitleWidget = Text(
        thread.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.muted, fontSize: 13.5),
      );
    } else {
      if (thread.online) {
        subtitleWidget = const Text(
          'Online',
          maxLines: 1,
          style: TextStyle(
            color: Color(0xFF25D366),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        );
      } else if (thread.lastSeen != null) {
        subtitleWidget = Text(
          'Last seen ${formatLastSeen(thread.lastSeen)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.faint, fontSize: 13),
        );
      } else if (thread.about.isNotEmpty) {
        subtitleWidget = Text(
          thread.about,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.faint, fontSize: 13),
        );
      } else {
        subtitleWidget = Text(
          'Tap to chat',
          maxLines: 1,
          style: TextStyle(color: AppColors.faint, fontSize: 13),
        );
      }
    }

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              thread.unread = 0;
              ChatBook.instance.ping();
              if (thread.chatId != null) {
                ChatSocketService.instance.markRead(thread.chatId!);
                ChatViewModel.instance.markAsRead(thread.chatId!);
              }
              Navigator.of(context).push(qRoute(ChatOpenScreen(thread: thread)));
            },
            onLongPress: () => _chatMenu(context, thread),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  avatar,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (thread.favourite)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.favorite_rounded, size: 13, color: Color(0xFFFF2A6D)),
                              ),
                            if (thread.pinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFF25D366)),
                              ),
                            if (thread.muted)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.notifications_off_rounded,
                                  size: 15,
                                  color: AppColors.faint,
                                ),
                              ),
                            // Real formatted message/last-seen time
                            Text(
                              thread.time,
                              style: TextStyle(
                                color: thread.unread > 0 ? const Color(0xFF25D366) : AppColors.faint,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (last != null && last.mine && !thread.isTyping) ...[
                              TickMark(last.tick, size: 15),
                              const SizedBox(width: 4),
                            ],
                            Expanded(child: subtitleWidget),
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
          margin: const EdgeInsets.only(left: 78),
          height: 0.5,
          color: AppColors.ink.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

Widget _unreadBadge(String count) {
  return Container(
    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFF25D366),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    child: Text(
      count,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}


