import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/Services/chat_audio_service.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/theme/app_theme.dart';

String resolveMediaUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('file://')) {
    return trimmed;
  }
  final base = AppConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.path.startsWith('/uploads/') ||
            uri.path.startsWith('/media/') ||
            uri.path.contains('/chats/'))) {
      return '$base${uri.path}';
    }
    return trimmed;
  }
  if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }
  if (!trimmed.contains('/')) {
    return '$base/uploads/chats/$trimmed';
  }
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$path';
}

bool isAudioUrl(String text) {
  final clean = text.trim().toLowerCase();
  if (clean.isEmpty) return false;
  return clean.endsWith('.m4a') ||
      clean.endsWith('.mp3') ||
      clean.endsWith('.aac') ||
      clean.endsWith('.wav') ||
      clean.endsWith('.ogg') ||
      clean.endsWith('.opus') ||
      clean.endsWith('.amr') ||
      clean.contains('/audio');
}

bool isVideoUrl(String text) {
  final clean = text.trim().toLowerCase();
  if (clean.isEmpty) return false;
  return clean.endsWith('.mp4') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.mkv') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.3gp') ||
      clean.contains('/video');
}

bool isImageUrl(String text) {
  final clean = text.trim().toLowerCase();
  if (clean.isEmpty) return false;
  // An audio, video, or document file is never an image
  if (isAudioUrl(clean) ||
      isVideoUrl(clean) ||
      clean.endsWith('.pdf') ||
      clean.endsWith('.doc') ||
      clean.endsWith('.docx') ||
      clean.endsWith('.xls') ||
      clean.endsWith('.xlsx')) {
    return false;
  }
  if (clean.endsWith('.jpg') ||
      clean.endsWith('.jpeg') ||
      clean.endsWith('.png') ||
      clean.endsWith('.webp') ||
      clean.endsWith('.gif') ||
      clean.endsWith('.bmp') ||
      clean.endsWith('.heic') ||
      clean.endsWith('.heif') ||
      clean.endsWith('.svg')) {
    return true;
  }
  if ((clean.startsWith('http://') ||
          clean.startsWith('https://') ||
          clean.startsWith('/uploads/') ||
          clean.startsWith('uploads/')) &&
      (clean.contains('/image') || clean.contains('/photos'))) {
    return true;
  }
  return false;
}

bool isLocationUrl(String text) {
  final clean = text.trim().toLowerCase();
  return clean.contains('maps.google.com') ||
      clean.contains('google.com/maps') ||
      clean.startsWith('geo:');
}

/// ✅ Inline Location Bubble
class ChatLocationBubble extends StatelessWidget {
  const ChatLocationBubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  void _openMap(BuildContext context) {
    String url = '';
    final lines = message.text.split('\n');
    for (final line in lines) {
      if (line.contains('http://') || line.contains('https://')) {
        url = line.trim();
        break;
      }
    }
    if (url.isEmpty && message.text.contains(',')) {
      url = 'https://maps.google.com/?q=${message.text.trim()}';
    }
    if (url.isNotEmpty) {
      const MethodChannel('qapp/open_file').invokeMethod('map', {'url': url});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMap(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 240,
          color: const Color(0xFF0C2426),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF13383B), Color(0xFF0B1F24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(240, 120),
                      painter: _MapGridPainter(),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location_rounded, color: AppColors.accent, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Live Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.text.split('https://').first.trim().isNotEmpty
                            ? message.text.split('https://').first.trim()
                            : 'Shared Location',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ✅ Inline Image Bubble
class ChatImageBubble extends StatefulWidget {
  const ChatImageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatImageBubble> createState() => _ChatImageBubbleState();
}

class _ChatImageBubbleState extends State<ChatImageBubble> {
  int _retryKey = 0;

  String _getHeroTag() {
    final m = widget.message;
    return 'chat_img_${m.id ?? m.clientId ?? "${m.createdAt?.millisecondsSinceEpoch}_${m.hashCode}"}';
  }

  bool _isFilename(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    final lower = t.toLowerCase();
    if (lower.startsWith('image_') ||
        lower.startsWith('photo_') ||
        lower.startsWith('file_') ||
        lower == 'photo.jpg') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final heroTag = _getHeroTag();

    Widget imageWidget;

    if (message.bytes != null && message.bytes!.isNotEmpty) {
      imageWidget = Image.memory(
        message.bytes!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (message.path != null &&
        message.path!.isNotEmpty &&
        File(message.path!).existsSync()) {
      imageWidget = Image.file(
        File(message.path!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      final raw = (message.fileUrl != null && message.fileUrl!.isNotEmpty)
          ? message.fileUrl!
          : (isImageUrl(message.text) && (message.text.startsWith('http') || message.text.startsWith('/'))
              ? message.text
              : '');

      if (raw.isNotEmpty) {
        final fullUrl = resolveMediaUrl(raw);
        imageWidget = Image.network(
          fullUrl,
          key: ValueKey('img_${fullUrl}_$_retryKey'),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null;
            return Container(
              color: const Color(0xFF0C1F26),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: progress,
                    color: AppColors.accent,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      } else if (message.asset != null) {
        imageWidget = Image.asset(
          message.asset!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      } else {
        imageWidget = _buildErrorPlaceholder();
      }
    }

    final hasCaption = message.text.isNotEmpty && !_isFilename(message.text);

    return GestureDetector(
      onTap: () => _openFullscreen(context, heroTag),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 240,
          color: const Color(0xFF07181D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(tag: heroTag, child: imageWidget),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCaption)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: const Color(0xFF132A32),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_rounded,
                  color: Color(0xFFE28B88),
                  size: 34,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Image load nahi hui',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => setState(() => _retryKey++),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, color: AppColors.accent, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _openFullscreen(BuildContext context, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, anim1, anim2) {
          return _FullscreenImageViewer(
            message: widget.message,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({
    required this.message,
    required this.heroTag,
  });

  final ChatMessage message;
  final String heroTag;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    Widget content;

    if (message.bytes != null && message.bytes!.isNotEmpty) {
      content = Image.memory(
        message.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFullscreenError(),
      );
    } else if (message.path != null &&
        message.path!.isNotEmpty &&
        File(message.path!).existsSync()) {
      content = Image.file(
        File(message.path!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFullscreenError(),
      );
    } else {
      final raw = (message.fileUrl != null && message.fileUrl!.isNotEmpty)
          ? message.fileUrl!
          : (isImageUrl(message.text) && (message.text.startsWith('http') || message.text.startsWith('/'))
              ? message.text
              : '');

      final fullUrl = raw.isNotEmpty ? resolveMediaUrl(raw) : '';
      if (fullUrl.isNotEmpty) {
        content = Image.network(
          fullUrl,
          key: ValueKey('fs_${fullUrl}_$_retryKey'),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loading photo...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFullscreenError(),
        );
      } else if (message.asset != null) {
        content = Image.asset(
          message.asset!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFullscreenError(),
        );
      } else {
        content = _buildFullscreenError();
      }
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.5,
              child: Hero(
                tag: widget.heroTag,
                child: content,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (message.time != null && message.time!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.time!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenError() {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF132A32),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_rounded,
                    color: Color(0xFFE28B88),
                    size: 52,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Image open nahi ho saki',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Server se image load nahi ho payi ya file corrupt ho sakti hai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => setState(() => _retryKey++),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Inline Voice / Audio Bubble with Play/Pause
class ChatVoiceBubble extends StatelessWidget {
  const ChatVoiceBubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  String _resolveAudioPath() {
    if (message.path != null && message.path!.isNotEmpty) {
      if (File(message.path!).existsSync()) {
        return message.path!;
      }
    }
    if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
      return resolveMediaUrl(message.fileUrl!);
    }
    if (message.path != null && message.path!.isNotEmpty) {
      return message.path!;
    }
    if (isAudioUrl(message.text)) {
      return resolveMediaUrl(message.text);
    }
    return '';
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final path = _resolveAudioPath();

    return AnimatedBuilder(
      animation: ChatAudioService.instance,
      builder: (context, _) {
        final audio = ChatAudioService.instance;
        final isPlaying = audio.isCurrentPlaying(path);
        final isCurrent = audio.isCurrent(path);

        final currentMs = isCurrent ? audio.positionMs : 0;
        final totalMs = isCurrent && audio.durationMs > 0
            ? audio.durationMs
            : 15000;

        final double progress = totalMs > 0
            ? (currentMs / totalMs).clamp(0.0, 1.0)
            : 0.0;

        final timeLabel = isPlaying || currentMs > 0
            ? _formatTime(currentMs)
            : (message.text.isNotEmpty && message.text.contains(':')
                  ? message.text
                  : _formatTime(totalMs));

        return Container(
          width: 230,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              // Play / Pause Circular Button
              GestureDetector(
                onTap: () {
                  if (path.isEmpty) return;
                  if (isPlaying) {
                    audio.pause();
                  } else {
                    audio.play(path);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Waveform / Progress Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: mine
                            ? AppColors.ink.withValues(alpha: 0.15)
                            : AppColors.ink.withValues(alpha: 0.12),
                        thumbColor: AppColors.accent,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          if (isCurrent && audio.durationMs > 0) {
                            final seekMs = (val * audio.durationMs).toInt();
                            audio.seek(seekMs);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeLabel,
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.mic_rounded,
                            size: 14,
                            color: isPlaying
                                ? AppColors.accent
                                : AppColors.inkSoft,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ✅ Inline Video Bubble
class ChatVideoBubble extends StatelessWidget {
  const ChatVideoBubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  String _resolveVideoPath() {
    if (message.path != null && message.path!.isNotEmpty && File(message.path!).existsSync()) {
      return message.path!;
    }
    if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
      return resolveMediaUrl(message.fileUrl!);
    }
    if (isVideoUrl(message.text) && (message.text.startsWith('http') || message.text.startsWith('/'))) {
      return resolveMediaUrl(message.text);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final videoPath = _resolveVideoPath();

    return GestureDetector(
      onTap: () => _openVideoPlayer(context, videoPath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 230,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Central Play Overlay
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black45,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              // Top Badge: "VIDEO"
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'VIDEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Title / Filename
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  message.text.isNotEmpty && !isVideoUrl(message.text)
                      ? message.text
                      : 'Video',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context, String path) {
    if (path.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, anim1, anim2) {
          return _InAppVideoDialog(path: path);
        },
      ),
    );
  }
}

class _InAppVideoDialog extends StatefulWidget {
  const _InAppVideoDialog({required this.path});
  final String path;

  @override
  State<_InAppVideoDialog> createState() => _InAppVideoDialogState();
}

class _InAppVideoDialogState extends State<_InAppVideoDialog> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox.expand(
              child: Platform.isAndroid
                  ? AndroidView(
                      key: ValueKey(widget.path),
                      viewType: 'qapp/video_player',
                      creationParams: {'path': widget.path},
                      creationParamsCodec: const StandardMessageCodec(),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.path,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
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
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
