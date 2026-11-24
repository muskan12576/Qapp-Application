import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/StatusModule/model/status_vm.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_background.dart';

class MyStatusScreen extends StatefulWidget {
  const MyStatusScreen({super.key});

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  List<Map<String, dynamic>> _myStatuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _loading = true);
    try {
      final list = await StatusViewModel.instance.getMyStatuses();
      if (mounted) {
        setState(() {
          _myStatuses = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = MyProfile.name.trim().isEmpty ? s.you : MyProfile.name.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text(s.myStatus, style: AppText.title.copyWith(fontSize: 24)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(qRoute(const AddStatusScreen()));
                        _loadStatuses();
                      },
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.accent),
                      label: const Text(
                        'Add Status',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : _myStatuses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 54, color: AppColors.inkSoft.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(s.tapStatus, style: AppText.subtitle),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStatuses,
                            color: AppColors.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _myStatuses.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _myStatuses[index];
                                final kind = item['kind']?.toString() ?? 'text';
                                final caption = item['caption']?.toString() ?? '';
                                final mediaUrl = item['mediaUrl']?.toString();
                                final ytId = item['youtubeVideoId']?.toString();
                                final viewCount = item['viewCount'] ?? 0;
                                final createdDate = item['createdDate'] != null
                                    ? formatMessageTime(DateTime.tryParse(item['createdDate'].toString()))
                                    : 'Today';

                                return Material(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        qRoute(
                                          StatusViewScreen(
                                            name: name,
                                            caption: caption,
                                            colorIndex: 2,
                                            mediaUrl: mediaUrl,
                                            kind: kind,
                                            youtubeVideoId: ytId,
                                            sourceUrl: item['sourceUrl']?.toString(),
                                            statusId: item['id']?.toString(),
                                            isMine: true,
                                            viewCount: viewCount is int ? viewCount : int.tryParse(viewCount.toString()) ?? 0,
                                            statuses: _myStatuses,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                      _loadStatuses();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: ytId != null
                                                ? Image.network(
                                                    'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                                                    width: 54,
                                                    height: 54,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 54,
                                                      height: 54,
                                                      color: Colors.red.shade900,
                                                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                                    ),
                                                  )
                                                : mediaUrl != null && mediaUrl.isNotEmpty
                                                    ? Image.network(
                                                        mediaUrl,
                                                        width: 54,
                                                        height: 54,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          width: 54,
                                                          height: 54,
                                                          color: AppColors.accent.withValues(alpha: 0.2),
                                                          child: const Icon(Icons.image_rounded, color: AppColors.accent),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 54,
                                                        height: 54,
                                                        color: AppColors.accent.withValues(alpha: 0.2),
                                                        child: Center(
                                                          child: Icon(
                                                            kind == 'youtube'
                                                                ? Icons.play_circle_fill_rounded
                                                                : (kind == 'video'
                                                                    ? Icons.videocam_rounded
                                                                    : Icons.text_fields_rounded),
                                                            color: AppColors.accent,
                                                          ),
                                                        ),
                                                      ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  caption.isEmpty
                                                      ? (kind == 'youtube'
                                                          ? 'YouTube Video'
                                                          : (kind == 'video' ? 'Video' : 'Status'))
                                                      : caption,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: AppColors.ink,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  createdDate,
                                                  style: TextStyle(color: AppColors.faint, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility_rounded, color: AppColors.inkSoft, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$viewCount',
                                                style: TextStyle(
                                                  color: AppColors.inkSoft,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddStatusScreen extends StatefulWidget {
  const AddStatusScreen({super.key, this.initialMode = 'media'});

  final String initialMode;

  @override
  State<AddStatusScreen> createState() => _AddStatusScreenState();
}

class _AddStatusScreenState extends State<AddStatusScreen> {
  final _caption = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _mode = 'media'; // 'media', 'link', 'text'
  Uint8List? _bytes;
  String? _pickedName;
  bool _busy = false;

  Map<String, dynamic>? _linkPreview;
  bool _fetchingLink = false;
  Timer? _linkDebounce;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _caption.dispose();
    _linkCtrl.dispose();
    _linkDebounce?.cancel();
    super.dispose();
  }

  void _onLinkChanged(String url) {
    _linkDebounce?.cancel();
    final trimmed = url.trim();
    if (trimmed.isEmpty || (!trimmed.startsWith('http://') && !trimmed.startsWith('https://'))) {
      setState(() => _linkPreview = null);
      return;
    }

    _linkDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _fetchingLink = true);
      try {
        final preview = await StatusViewModel.instance.previewLink(trimmed);
        if (mounted) {
          setState(() {
            _linkPreview = preview;
            _fetchingLink = false;
            if (_caption.text.trim().isEmpty && preview?['title'] != null) {
              _caption.text = preview!['title'].toString();
            }
          });
        }
      } catch (_) {
        if (mounted) setState(() => _fetchingLink = false);
      }
    });
  }

  Future<void> _pickGallery([FileType type = FileType.any]) async {
    try {
      final file = await FilePicker.pickFile(type: type, compressionQuality: 65);
      if (file == null || !mounted) return;
      final isVideo = file.name.endsWith('.mp4') ||
          file.name.endsWith('.mov') ||
          file.name.endsWith('.m4v') ||
          file.name.endsWith('.webm');
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _pickedName = file.name;
        _mode = 'media';
      });
      if (isVideo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video Status: Maximum 30 seconds limit apply hoga.'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _pasteLink() async {
    final cdata = await Clipboard.getData(Clipboard.kTextPlain);
    if (cdata?.text != null && cdata!.text!.trim().isNotEmpty) {
      _linkCtrl.text = cdata.text!.trim();
      _onLinkChanged(cdata.text!.trim());
    }
  }

  Future<void> _save() async {
    final captionText = _caption.text.trim();
    final linkText = _linkCtrl.text.trim();

    if (_bytes == null && captionText.isEmpty && linkText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya media, link ya text status enter karein')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      if (_mode == 'link' || (_linkPreview != null && linkText.isNotEmpty) || linkText.startsWith('http://') || linkText.startsWith('https://')) {
        // Universal Link status (YouTube, Instagram, Social Video, Direct Video)
        final preview = _linkPreview;
        final kind = preview?['kind']?.toString() ?? (preview?['platform'] == 'youtube' ? 'youtube' : (preview?['playbackType'] == 'direct_video' ? 'video' : 'link'));
        final ytId = preview?['youtubeVideoId']?.toString() ?? preview?['videoId']?.toString();
        final mediaUrl = preview?['mediaUrl']?.toString() ?? preview?['embedUrl']?.toString();

        await StatusViewModel.instance.createStatus(
          kind: kind,
          mediaUrl: mediaUrl,
          youtubeVideoId: ytId,
          sourceUrl: linkText,
          caption: captionText.isNotEmpty ? captionText : preview?['title']?.toString(),
          platform: preview?['platform']?.toString(),
          embedUrl: preview?['embedUrl']?.toString(),
          thumbnailUrl: preview?['thumbnailUrl']?.toString(),
          playbackType: preview?['playbackType']?.toString(),
          title: preview?['title']?.toString(),
          originalUrl: linkText,
        );
      } else if (_bytes != null) {
        // Media upload status (Image / Video)
        final isVideo = _pickedName != null &&
            (_pickedName!.endsWith('.mp4') || _pickedName!.endsWith('.mov') || _pickedName!.endsWith('.m4v'));

        final uploaded = await StatusViewModel.instance.uploadStatusMedia(
          bytes: _bytes!,
          fileName: _pickedName ?? 'status_${DateTime.now().millisecondsSinceEpoch}.jpg',
          type: isVideo ? 'video' : 'image',
        );

        final mediaUrl = uploaded?['file']?['url']?.toString() ??
            uploaded?['url']?.toString() ??
            uploaded?['fileUrl']?.toString() ??
            uploaded?['data']?['url']?.toString();
        await StatusViewModel.instance.createStatus(
          kind: isVideo ? 'video' : 'image',
          mediaUrl: mediaUrl,
          caption: captionText,
        );
      } else {
        // Pure text status
        await StatusViewModel.instance.createStatus(
          kind: 'text',
          caption: captionText,
        );
      }

      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status update ho gaya!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status create error: $e'), backgroundColor: Colors.redAccent),
        );
      }
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
              // 1. Top Bar matching Image 2
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: AppColors.ink, size: 26),
                    ),
                    const Expanded(
                      child: Text(
                        'New Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.2),
                      )
                    else
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Scrollable Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Top Cards Row matching Image 2
                    SizedBox(
                      height: 196,
                      child: Row(
                        children: [
                          // Left Card: Open Camera / Picked Media
                          Expanded(
                            flex: 11,
                            child: GestureDetector(
                              onTap: () => _pickGallery(FileType.any),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.card,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_bytes != null)
                                      (_pickedName != null &&
                                              (_pickedName!.endsWith('.mp4') ||
                                                  _pickedName!.endsWith('.mov') ||
                                                  _pickedName!.endsWith('.m4v') ||
                                                  _pickedName!.endsWith('.webm')))
                                          ? Container(
                                              color: Colors.black87,
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.videocam_rounded, color: AppColors.accent, size: 54),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _pickedName ?? 'Video Selected',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text(
                                                    '30s Status Video',
                                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Image.memory(_bytes!, fit: BoxFit.cover)
                                    else
                                      Container(
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    // Frosted Glass "Open Camera" Pill at bottom
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            color: Colors.black.withValues(alpha: 0.38),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _bytes != null ? 'Change Photo' : 'Open Camera',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_bytes != null)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _bytes = null;
                                            _pickedName = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right Column: Text Status & Paste YouTube Link
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                // Top Right Card: Text Status (Aa)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTextStatusDialog,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Aa',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Text Status',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Bottom Right Card: Paste YouTube Link
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showLinkDialog,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppColors.card,
                                        border: Border.all(color: Colors.white12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Red YouTube Logo icon
                                          Container(
                                            width: 28,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF0000),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Paste YouTube\nLink',
                                            style: TextStyle(
                                              color: AppColors.ink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Link daalein',
                                            style: TextStyle(
                                              color: AppColors.inkSoft.withValues(alpha: 0.65),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Active Link Preview / Text Status Preview Card
                    if (_linkPreview != null || _fetchingLink) ...[
                      _buildLinkPreviewWidget(),
                      const SizedBox(height: 16),
                    ],

                    if (_mode == 'text' && _caption.text.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F2B26), Color(0xFF1B4D45)],
                          ),
                        ),
                        child: Text(
                          _caption.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Recent Gallery Header matching Image 2
                    Row(
                      children: [
                        Text(
                          'Recent Gallery',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _pickGallery(FileType.any),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. 2x3 Media Gallery Grid matching Image 2
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        return _buildGalleryGridItem(index);
                      },
                    ),
                  ],
                ),
              ),

              // 5. Bottom Caption & Share Bar matching Image 2
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Emoji Button
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.sentiment_satisfied_rounded, color: Colors.black54, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _caption,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(color: AppColors.ink, fontSize: 14),
                          cursorColor: const Color(0xFF10B981),
                          decoration: InputDecoration(
                            hintText: 'Add a caption or link...',
                            hintStyle: TextStyle(
                              color: AppColors.inkSoft.withValues(alpha: 0.55),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      // Send/Share Circular Green Button
                      GestureDetector(
                        onTap: _busy ? null : _save,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: _busy
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
    );
  }

  Widget _buildGalleryGridItem(int index) {
    // Curated high quality sample images matching the aesthetic in Image 2
    final sampleImages = [
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=300&auto=format&fit=crop&q=80',
    ];

    return GestureDetector(
      onTap: () => _pickGallery(FileType.any),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              sampleImages[index % sampleImages.length],
              fit: BoxFit.cover,
            ),
            // Translucent black tint
            Container(color: Colors.black.withValues(alpha: 0.18)),
            // Circular Play Icon
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ),
            // Duration Badge "0:15" matching Image 2
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '0:15',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextStatusDialog() {
    final textCtrl = TextEditingController(text: _caption.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Text Status', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          maxLines: 4,
          style: TextStyle(color: AppColors.ink),
          decoration: const InputDecoration(
            hintText: 'Apna status yahan likhein...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() {
                _caption.text = textCtrl.text;
                _mode = 'text';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_display_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Paste Video / YouTube Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: TextField(
          controller: _linkCtrl,
          autofocus: true,
          style: TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'https://youtube.com/... ya video link',
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste_rounded, color: Colors.redAccent),
              onPressed: _pasteLink,
            ),
          ),
          onChanged: _onLinkChanged,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _onLinkChanged(_linkCtrl.text);
            },
            child: const Text('Add Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPreviewWidget() {
    if (_fetchingLink) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Video details load ho rahi hain...', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final p = _linkPreview;
    if (p == null) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['thumbnailUrl'] != null)
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  p['thumbnailUrl'].toString(),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              p['title']?.toString() ?? _linkCtrl.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
