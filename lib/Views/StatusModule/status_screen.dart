import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/StatusModule/model/status_vm.dart';
import 'package:qapp/Views/StatusModule/my_status_screen.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/status_progress_ring.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, this.focusTick = 0});

  final int focusTick;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  Map<String, dynamic>? _myStatusData;
  List<Map<String, dynamic>> _othersData = [];
  bool _loading = true;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      final feed = await StatusViewModel.instance.getStatusFeed();
      if (mounted) {
        setState(() {
          _myStatusData = feed['myStatus'] is Map<String, dynamic>
              ? feed['myStatus'] as Map<String, dynamic>
              : (feed['myStatus'] is Map ? Map<String, dynamic>.from(feed['myStatus'] as Map) : null);

          final others = feed['others'] as List? ?? [];
          _othersData = others.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(StatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTick != oldWidget.focusTick) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openStatusGroup(Map<String, dynamic> userGroup, {bool isMine = false}) {
    final statuses = (userGroup['statuses'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    if (statuses.isEmpty) return;

    final latest = statuses.first;
    final name = isMine ? 'My Status' : (userGroup['userName']?.toString() ?? 'User');

    Navigator.of(context).push(
      qRoute(
        StatusViewScreen(
          name: name,
          caption: latest['caption']?.toString() ?? '',
          colorIndex: 2,
          mediaUrl: latest['mediaUrl']?.toString(),
          kind: latest['kind']?.toString() ?? 'text',
          youtubeVideoId: latest['youtubeVideoId']?.toString(),
          sourceUrl: latest['sourceUrl']?.toString(),
          ownerId: userGroup['userId']?.toString(),
          statusId: latest['id']?.toString(),
          isMine: isMine,
          viewCount: latest['viewCount'] is int
              ? latest['viewCount'] as int
              : int.tryParse(latest['viewCount']?.toString() ?? '0') ?? 0,
          statuses: statuses,
        ),
      ),
    ).then((_) => _loadFeed());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mineName = MyProfile.name.trim().isEmpty ? s.you : MyProfile.name.trim();
    final query = _search.text.trim().toLowerCase();

    final myStatuses = (_myStatusData?['statuses'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final hasMyStatus = myStatuses.isNotEmpty;
    final latestMyStatus = hasMyStatus ? myStatuses.first : null;

    final filteredOthers = _othersData.where((u) {
      final name = u['userName']?.toString().toLowerCase() ?? '';
      return query.isEmpty || name.contains(query);
    }).toList();

    final recent = filteredOthers.where((u) {
      final sts = (u['statuses'] as List? ?? []);
      return sts.any((s) => s['hasViewed'] != true);
    }).toList();

    final viewed = filteredOthers.where((u) {
      final sts = (u['statuses'] as List? ?? []);
      return sts.isNotEmpty && sts.every((s) => s['hasViewed'] == true);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadFeed,
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Expanded(child: Text(s.statusTitle, style: AppText.title)),
                    Material(
                      color: AppColors.bubbleIn,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _loadFeed,
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

                // Search Bar
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

                // My Status Card
                Text(s.myStatus, style: _label),
                const SizedBox(height: 8),
                _card(
                  name: mineName,
                  title: s.myStatus,
                  subtitle: hasMyStatus
                      ? (latestMyStatus!['caption']?.toString().isNotEmpty == true
                          ? latestMyStatus['caption'].toString()
                          : (latestMyStatus['kind'] == 'youtube'
                              ? 'YouTube Video'
                              : (latestMyStatus['kind'] == 'video' ? 'Video' : 'Photo')))
                      : s.tapStatus,
                  colorIndex: 2,
                  bytes: MyProfile.photo,
                  badge: true,
                  hasStories: hasMyStatus,
                  seen: true,
                  statusCount: (_myStatusData?['statuses'] as List? ?? []).length,
                  onTap: () {
                    if (hasMyStatus) {
                      _openStatusGroup(_myStatusData!, isMine: true);
                    } else {
                      Navigator.of(context)
                          .push(qRoute(const AddStatusScreen()))
                          .then((_) => _loadFeed());
                    }
                  },
                  onBadge: () {
                    Navigator.of(context)
                        .push(qRoute(const AddStatusScreen()))
                        .then((_) => _loadFeed());
                  },
                  onMore: hasMyStatus
                      ? () {
                          Navigator.of(context)
                              .push(qRoute(const MyStatusScreen()))
                              .then((_) => _loadFeed());
                        }
                      : null,
                ),
                const SizedBox(height: 16),

                // Recent Updates (Unviewed statuses)
                if (recent.isNotEmpty) ...[
                  Text(s.recentUpdates, style: _label),
                  const SizedBox(height: 8),
                  for (final peer in recent)
                    _card(
                      name: peer['userName']?.toString() ?? 'User',
                      title: peer['userName']?.toString() ?? 'User',
                      subtitle: _getSubtitle(peer),
                      colorIndex: 1,
                      photo: peer['userPhoto']?.toString(),
                      hasStories: true,
                      statusCount: (peer['statuses'] as List? ?? []).length,
                      seen: false,
                      onTap: () => _openStatusGroup(peer),
                    ),
                  const SizedBox(height: 16),
                ],

                // Viewed Updates (Already seen statuses)
                if (viewed.isNotEmpty) ...[
                  Text(s.viewedUpdates, style: _label),
                  const SizedBox(height: 8),
                  for (final peer in viewed)
                    _card(
                      name: peer['userName']?.toString() ?? 'User',
                      title: peer['userName']?.toString() ?? 'User',
                      subtitle: _getSubtitle(peer),
                      colorIndex: 3,
                      photo: peer['userPhoto']?.toString(),
                      hasStories: true,
                      statusCount: (peer['statuses'] as List? ?? []).length,
                      seen: true,
                      onTap: () => _openStatusGroup(peer),
                    ),
                ],

                if (!_loading && recent.isEmpty && viewed.isEmpty && !hasMyStatus)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.amp_stories_rounded, size: 54, color: AppColors.inkSoft.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Koi recent status nahi hai', style: AppText.subtitle),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle(Map<String, dynamic> peer) {
    final sts = (peer['statuses'] as List? ?? []);
    if (sts.isEmpty) return 'Today';
    final latest = sts.first;
    if (latest['caption'] != null && latest['caption'].toString().isNotEmpty) {
      return latest['caption'].toString();
    }
    if (latest['createdDate'] != null) {
      return formatMessageTime(DateTime.tryParse(latest['createdDate'].toString()));
    }
    return 'Recent Update';
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
    bool hasStories = false,
    int statusCount = 1,
    VoidCallback? onBadge,
    VoidCallback? onMore,
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
                    StatusProgressRing(
                      hasStatus: hasStories,
                      hasUnviewed: !seen,
                      totalStatuses: statusCount,
                      ringWidth: 2.5,
                      padding: 2.2,
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
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 15, color: Colors.black),
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
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: Icon(Icons.more_horiz_rounded, color: AppColors.inkSoft),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
