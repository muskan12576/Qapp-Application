import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Utills/app_colors.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/StatusModule/model/status_vm.dart';
import 'package:qapp/Views/StatusModule/my_status_screen.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/chat_media_bubble.dart';
import 'package:qapp/widgets/q_avatar.dart';

class StatusViewScreen extends StatefulWidget {
  const StatusViewScreen({
    super.key,
    required this.name,
    this.caption = '',
    this.colorIndex = 1,
    this.bytes,
    this.mediaUrl,
    this.kind = 'text',
    this.youtubeVideoId,
    this.sourceUrl,
    this.ownerId,
    this.statusId,
    this.isMine = false,
    this.viewCount = 0,
    this.statuses = const [],
    this.initialIndex = 0,
  });

  final String name;
  final String caption;
  final int colorIndex;
  final Uint8List? bytes;
  final String? mediaUrl;
  final String kind;
  final String? youtubeVideoId;
  final String? sourceUrl;
  final String? ownerId;
  final String? statusId;
  final bool isMine;
  final int viewCount;
  final List<Map<String, dynamic>> statuses;
  final int initialIndex;

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  final _replyCtrl = TextEditingController();
  final _replyFocus = FocusNode();
  bool _isReplying = false;
  bool _isSendingReply = false;
  int _currentIndex = 0;

  int get _totalCount =>
      widget.statuses.isNotEmpty ? widget.statuses.length : 1;

  Map<String, dynamic>? get _currentStatus =>
      widget.statuses.isNotEmpty ? widget.statuses[_currentIndex] : null;

  String get _currentCaption => widget.statuses.isNotEmpty
      ? (_currentStatus?['caption']?.toString() ?? '')
      : widget.caption;

  String get _currentKind => widget.statuses.isNotEmpty
      ? (_currentStatus?['kind']?.toString() ??
            _currentStatus?['statusType']?.toString() ??
            'text')
      : widget.kind;

  String? get _currentMediaUrl => widget.statuses.isNotEmpty
      ? (_currentStatus?['mediaUrl']?.toString())
      : widget.mediaUrl;

  String? get _currentYtId => widget.statuses.isNotEmpty
      ? (_currentStatus?['youtubeVideoId']?.toString())
      : widget.youtubeVideoId;

  String? get _currentSourceUrl => widget.statuses.isNotEmpty
      ? (_currentStatus?['sourceUrl']?.toString() ??
            _currentStatus?['originalUrl']?.toString())
      : widget.sourceUrl;

  String? get _currentPlatform => _currentStatus?['platform']?.toString();

  String? get _currentPlaybackType =>
      _currentStatus?['playbackType']?.toString();

  String? get _currentEmbedUrl => _currentStatus?['embedUrl']?.toString();

  String? get _currentStatusId => widget.statuses.isNotEmpty
      ? (_currentStatus?['id']?.toString())
      : widget.statusId;

  int get _currentViews {
    final v = _currentStatus?['viewCount'];
    if (v is int) return v;
    if (v != null) return int.tryParse(v.toString()) ?? 0;
    return widget.viewCount;
  }

  final Map<String, bool> _localLikes = {};
  final Map<String, int> _localLikeCounts = {};
  bool _isVideoBuffering = true;
  Timer? _bufferTimer;

  bool get _isCurrentLiked {
    final id = _currentStatusId;
    if (id != null && _localLikes.containsKey(id)) {
      return _localLikes[id]!;
    }
    return _currentStatus?['isLiked'] == true;
  }

  int get _currentLikesCount {
    final id = _currentStatusId;
    if (id != null && _localLikeCounts.containsKey(id)) {
      return _localLikeCounts[id]!;
    }
    final v = _currentStatus?['likesCount'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  void _resetBufferTimer() {
    _bufferTimer?.cancel();
    setState(() => _isVideoBuffering = true);
    _bufferTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _isVideoBuffering = false);
    });
  }

  Future<void> _toggleStatusLike() async {
    final id = _currentStatusId;
    if (id == null) return;
    final currentlyLiked = _isCurrentLiked;
    final currentCount = _currentLikesCount;
    setState(() {
      _localLikes[id] = !currentlyLiked;
      _localLikeCounts[id] = currentlyLiked ? (currentCount > 0 ? currentCount - 1 : 0) : currentCount + 1;
    });
    await StatusViewModel.instance.toggleLike(id);
  }

  Future<void> _shareStatus() async {
    final caption = _currentCaption;
    final url = _currentSourceUrl ?? _currentMediaUrl ?? '';
    final shareText = caption.isNotEmpty
        ? (url.isNotEmpty ? '$caption\n$url' : caption)
        : (url.isNotEmpty ? url : 'Shared via Qapp');
    try {
      await const MethodChannel('qapp/open_file').invokeMethod('share', {
        'text': shareText,
        'title': 'Share Status',
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _totalCount - 1);
    _play = AnimationController(vsync: this, duration: _getDuration())
      ..forward();
    _play.addStatusListener(_onDone);

    _replyFocus.addListener(() {
      if (_replyFocus.hasFocus) {
        _play.stop();
        setState(() => _isReplying = true);
      }
    });

    _markCurrentViewed();
    _resetBufferTimer();
  }

  Duration _getDuration() {
    final k = _currentKind;
    if (k == 'video' || k == 'youtube' || k == 'link' || _currentEmbedUrl != null) {
      return const Duration(seconds: 30);
    }
    return const Duration(seconds: 8);
  }

  void _markCurrentViewed() {
    final sId = _currentStatusId;
    if (!widget.isMine && sId != null) {
      StatusViewModel.instance.viewStatus(sId);
    }
  }

  void _onDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_isReplying) {
      _nextStatus();
    }
  }

  void _nextStatus() {
    if (_currentIndex < _totalCount - 1) {
      setState(() {
        _currentIndex++;
        _play.duration = _getDuration();
        _play.reset();
        _play.forward();
      });
      _markCurrentViewed();
      _resetBufferTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _play.duration = _getDuration();
        _play.reset();
        _play.forward();
      });
      _markCurrentViewed();
      _resetBufferTimer();
    } else {
      _play.reset();
      _play.forward();
    }
  }

  @override
  void dispose() {
    _bufferTimer?.cancel();
    _play.removeStatusListener(_onDone);
    _play.dispose();
    _replyCtrl.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isReplying) {
      FocusScope.of(context).unfocus();
      setState(() => _isReplying = false);
      _play.forward();
      return;
    }

    if (_play.isAnimating) {
      _play.stop();
    } else {
      _play.forward();
    }
    setState(() {});
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || widget.ownerId == null || _isSendingReply) return;

    setState(() => _isSendingReply = true);
    final success = await StatusViewModel.instance.replyToStatus(
      recipientId: widget.ownerId!,
      replyText: text,
      statusCaption: _currentCaption,
      mediaUrl: _currentMediaUrl,
    );

    if (mounted) {
      setState(() => _isSendingReply = false);
      _replyCtrl.clear();
      _replyFocus.unfocus();
      setState(() => _isReplying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Reply sent to ${widget.name}'
                : 'Reply bhejne mein error aaya',
          ),
          backgroundColor: success ? AppColors.accent : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );

      if (success) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        _play.forward();
      }
    }
  }

  void _showViewersBottomSheet() {
    _play.stop();
    final statusId = _currentStatusId;
    if (statusId == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: StatusViewModel.instance.getStatusViewers(statusId),
          builder: (context, snapshot) {
            final viewers = snapshot.data ?? [];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inkSoft.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Viewed by (${viewers.length})',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        ),
                      )
                    else if (viewers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'Abhi tak kisi ne nahi dekha',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: viewers.length,
                          separatorBuilder: (context, index) => Divider(
                            color: AppColors.ink.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, i) {
                            final v = viewers[i];
                            final vName = v['name']?.toString() ?? 'User';
                            final vTime = v['viewedAt'] != null
                                ? formatMessageTime(
                                    DateTime.tryParse(v['viewedAt'].toString()),
                                  )
                                : '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: QAvatar(
                                name: vName,
                                size: 40,
                                colorIndex: i % 4,
                              ),
                              title: Text(
                                vName,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                v['phone']?.toString() ?? '',
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                vTime,
                                style: TextStyle(
                                  color: AppColors.faint,
                                  fontSize: 12,
                                ),
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
      },
    ).whenComplete(() {
      if (mounted) _play.forward();
    });
  }

  void _confirmDelete() {
    _play.stop();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete status?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Ye status aapke sabhi contacts ke feed se delete ho jayega.',
          style: TextStyle(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _play.forward();
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final sId = _currentStatusId;
              if (sId != null) {
                await StatusViewModel.instance.deleteStatus(sId);
              }
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final kind = _currentKind;
    final mediaUrl = _currentMediaUrl ?? '';
    final fullUrl = resolveMediaUrl(mediaUrl);
    final caption = _currentCaption;
    final sourceUrl = _currentSourceUrl;
    final platform = _currentPlatform;
    final playbackType = _currentPlaybackType;
    final embedUrl = _currentEmbedUrl;

    // Detect YouTube / Embed links for the CURRENT status only
    String? ytId = _currentYtId;
    if (ytId == null || ytId.isEmpty) {
      final target = (sourceUrl != null && sourceUrl.isNotEmpty)
          ? sourceUrl
          : mediaUrl;
      final ytMatch = RegExp(
        r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/|live\/))([\w-]{11})',
      ).firstMatch(target);
      if (ytMatch != null) {
        ytId = ytMatch.group(1);
      } else {
        final vMatch = RegExp(r'[?&]v=([\w-]{11})').firstMatch(target);
        if (vMatch != null) {
          ytId = vMatch.group(1);
        } else {
          final rdMatch = RegExp(r'list=RD([\w-]{11})').firstMatch(target);
          if (rdMatch != null) {
            ytId = rdMatch.group(1);
          }
        }
      }
    }

    final isYouTube =
        kind == 'youtube' ||
        platform == 'youtube' ||
        (ytId != null && ytId.isNotEmpty);

    final isEmbed =
        isYouTube ||
        kind == 'link' ||
        playbackType == 'official_embed' ||
        (embedUrl != null && embedUrl.isNotEmpty);

    final isDirectVideo =
        (kind == 'video' ||
            playbackType == 'direct_video' ||
            isVideoUrl(mediaUrl) ||
            isVideoUrl(sourceUrl ?? '')) &&
        kind != 'image' &&
        kind != 'text';

    final isVideo =
        (isEmbed || isDirectVideo) && kind != 'image' && kind != 'text';

    final String? thumbUrl = (_currentStatus?['thumbnailUrl']?.toString()) ??
        (ytId != null && ytId.isNotEmpty ? 'https://i.ytimg.com/vi/$ytId/hqdefault.jpg' : null);

    final String videoPlayUrl;
    if (embedUrl != null && embedUrl.isNotEmpty) {
      videoPlayUrl = embedUrl;
    } else if (isYouTube) {
      videoPlayUrl = (ytId != null && ytId.isNotEmpty)
          ? 'https://www.youtube.com/watch?v=$ytId'
          : (sourceUrl != null && sourceUrl.isNotEmpty ? sourceUrl : mediaUrl);
    } else if (isDirectVideo) {
      videoPlayUrl = fullUrl.isNotEmpty ? fullUrl : mediaUrl;
    } else if (sourceUrl != null && sourceUrl.isNotEmpty) {
      videoPlayUrl = sourceUrl;
    } else {
      videoPlayUrl = fullUrl;
    }

    final Uint8List? activeBytes = widget.statuses.isNotEmpty
        ? null
        : widget.bytes;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media / Video / Image / Text
          Positioned.fill(
            child: isVideo
                ? (Platform.isAndroid && videoPlayUrl.isNotEmpty)
                      ? GestureDetector(
                          onTap: _togglePlayPause,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. High-res Video Thumbnail Preview (Zero black screen!)
                              if (thumbUrl != null && thumbUrl.isNotEmpty)
                                Image.network(
                                  thumbUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.expand(),
                                ),
                              // 2. Video Player / Web Player on top
                              AndroidView(
                                key: ValueKey(
                                  'status_${_currentIndex}_${_currentStatusId ?? ""}_$videoPlayUrl',
                                ),
                                viewType: 'qapp/video_player',
                                creationParams: {'path': videoPlayUrl},
                                creationParamsCodec: const StandardMessageCodec(),
                              ),
                              // 3. Smooth loader overlay while video initializes
                              if (_isVideoBuffering)
                                Container(
                                  color: Colors.black38,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Loading video...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Container(
                          color: Colors.black87,
                          child: const SizedBox.expand(),
                        )
                : (activeBytes != null || mediaUrl.isNotEmpty)
                ? (activeBytes != null
                      ? Image.memory(activeBytes, fit: BoxFit.contain)
                      : Image.network(
                          fullUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white38,
                                  size: 64,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Image load nahi hui',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0C2426),
                          Color(0xFF13383B),
                          Color(0xFF06181C),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      caption.isNotEmpty ? caption : widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),

          // Tap overlay for story navigation (left: prev, right: next)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _prevStatus,
                    onLongPressStart: (_) => _play.stop(),
                    onLongPressEnd: (_) => _play.forward(),
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _nextStatus,
                    onLongPressStart: (_) => _play.stop(),
                    onLongPressEnd: (_) => _play.forward(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          // Top Header: Segmented Progress Bars & User Profile
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Story Timer Bars
                    Row(
                      children: [
                        for (int i = 0; i < _totalCount; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: i < _currentIndex
                                  ? Container(
                                      height: 3,
                                      color: AppColors.accent,
                                    )
                                  : (i == _currentIndex
                                        ? AnimatedBuilder(
                                            animation: _play,
                                            builder: (context, _) =>
                                                LinearProgressIndicator(
                                                  value: _play.value,
                                                  minHeight: 3,
                                                  backgroundColor:
                                                      Colors.white24,
                                                  color: AppColors.accent,
                                                ),
                                          )
                                        : Container(
                                            height: 3,
                                            color: Colors.white24,
                                          )),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        QAvatar(
                          name: widget.name,
                          size: 40,
                          colorIndex: widget.colorIndex,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                s.statusPlay,
                                style: AppText.subtitle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isMine) ...[
                          IconButton(
                            tooltip: 'Add Status',
                            onPressed: () {
                              _play.stop();
                              Navigator.of(
                                context,
                              ).push(qRoute(const AddStatusScreen())).then((_) {
                                if (mounted) _play.forward();
                              });
                            },
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          IconButton(
                            onPressed: _confirmDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Caption & Reply Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (caption.isNotEmpty &&
                      (kind != 'text' ||
                          widget.bytes != null ||
                          mediaUrl.isNotEmpty))
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  widget.isMine
                      // Viewers Pill & Likes / Share
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _showViewersBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility_rounded,
                                        color: AppColors.accent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$_currentViews views',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_currentLikesCount > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_currentLikesCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _shareStatus,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      // Reply Bar with Like and Share
                      : Material(
                          type: MaterialType.transparency,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              12 + MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.75,
                                      ),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextField(
                                      controller: _replyCtrl,
                                      focusNode: _replyFocus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      cursorColor: AppColors.accent,
                                      decoration: InputDecoration(
                                        hintText: 'Reply to ${widget.name}...',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                      onSubmitted: (_) => _sendReply(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _toggleStatusLike,
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _isCurrentLiked
                                            ? Colors.redAccent
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isCurrentLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: _isCurrentLiked
                                              ? Colors.redAccent
                                              : Colors.white,
                                          size: 20,
                                        ),
                                        if (_currentLikesCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '$_currentLikesCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _shareStatus,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _sendReply,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isSendingReply
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
