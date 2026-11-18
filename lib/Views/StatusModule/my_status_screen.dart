import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Utills/app_colors.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/StatusModule/model/status_vm.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
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

  Future<void> _pickGallery() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.any, compressionQuality: 65);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _pickedName = file.name;
        _mode = 'media';
      });
    } catch (_) {}
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text('New Status', style: AppText.title.copyWith(fontSize: 22)),
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _save,
                        child: const Text(
                          'Post',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Mode Tabs: Media, Link, Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildModeChip('Photo / Video', 'media', Icons.photo_library_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip('Link (YouTube/Insta)', 'link', Icons.link_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip('Text', 'text', Icons.text_fields_rounded),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // Mode: Link
                    if (_mode == 'link') ...[
                      TextField(
                        controller: _linkCtrl,
                        onChanged: _onLinkChanged,
                        style: TextStyle(color: AppColors.ink),
                        cursorColor: AppColors.accent,
                        decoration: InputDecoration(
                          hintText: 'Paste YouTube, Instagram reel, or video link...',
                          hintStyle: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: AppColors.card,
                          prefixIcon: const Icon(Icons.link_rounded, color: AppColors.accent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Link live preview card
                      if (_fetchingLink)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Checking link content...', style: TextStyle(color: AppColors.accent)),
                              ],
                            ),
                          ),
                        )
                      else if (_linkPreview != null) ...[
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_linkPreview!['thumbnailUrl'] != null)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      _linkPreview!['thumbnailUrl'].toString(),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                    ),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _linkPreview!['kind'] == 'youtube'
                                              ? Icons.play_circle_fill_rounded
                                              : Icons.videocam_rounded,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _linkPreview!['kind'] == 'youtube' ? 'YouTube' : 'Video Link',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _linkPreview!['title']?.toString() ?? 'Direct Video Status',
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],

                    // Mode: Media (Photo / Video preview)
                    if (_mode == 'media') ...[
                      GestureDetector(
                        onTap: _pickGallery,
                        child: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
                          ),
                          child: _bytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    _bytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 38,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to choose Photo or Video',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gallery se image ya video select karein',
                                        style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Caption Input
                    TextField(
                      controller: _caption,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: AppColors.ink),
                      cursorColor: AppColors.accent,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: _mode == 'text'
                            ? 'What is on your mind?...'
                            : 'Add a caption (optional)...',
                        hintStyle: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _busy ? 'Posting...' : 'Post Status',
                      onPressed: _busy ? () {} : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, String modeVal, IconData icon) {
    final active = _mode == modeVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = modeVal),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.black : AppColors.inkSoft),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.black : AppColors.ink,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
