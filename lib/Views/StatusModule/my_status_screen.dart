import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/Views/StatusModule/status_view_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class MyStatusScreen extends StatelessWidget {
  const MyStatusScreen({super.key});

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
                      onPressed: () {
                        Navigator.of(context).push(qRoute(const AddStatusScreen()));
                      },
                      icon: const Icon(Icons.edit_rounded, color: AppColors.accent),
                      label: Text(
                        s.edit,
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: StatusBook.instance,
                  builder: (context, _) {
                    final items = StatusBook.instance.mine;
                    if (items.isEmpty) {
                      return Center(child: Text(s.tapStatus, style: AppText.subtitle));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Material(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                qRoute(
                                  StatusViewScreen(
                                    name: name,
                                    caption: item.caption.isEmpty ? s.myStatus : item.caption,
                                    colorIndex: 2,
                                    bytes: item.bytes,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.bytes == null
                                        ? QAvatar(name: name, size: 54, colorIndex: 2, bytes: MyProfile.photo)
                                        : Image.memory(
                                            item.bytes!,
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.caption.isEmpty ? s.image : item.caption,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item.time, style: TextStyle(color: AppColors.faint, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
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
  const AddStatusScreen({super.key});

  @override
  State<AddStatusScreen> createState() => _AddStatusScreenState();
}

class _AddStatusScreenState extends State<AddStatusScreen> {
  final _caption = TextEditingController();
  Uint8List? _bytes;
  bool _camera = false;
  bool _busy = false;
  int? _viewId;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      setState(() => _camera = false);
      return;
    }
    try {
      final ok = await const MethodChannel('qapp/camera_perm').invokeMethod<bool>('grant');
      if (!mounted) {
        return;
      }
      setState(() {
        _camera = ok == true;
        if (_camera) {
          _bytes = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _camera = false);
      }
    }
  }

  Future<void> _snap() async {
    final id = _viewId;
    if (id == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final raw = await MethodChannel('qapp/camera_$id').invokeMethod<Uint8List>('snap');
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = raw == null || raw.isEmpty ? _bytes : raw;
        _camera = false;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _gallery() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image, compressionQuality: 55);
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _camera = false;
      });
    } catch (_) {}
  }

  void _save() {
    final text = _caption.text.trim();
    if (text.isEmpty && _bytes == null) {
      return;
    }
    StatusBook.instance.add(
      StatusUpdate(caption: text, time: S.of(context).now, bytes: _bytes),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: AppColors.ink),
                    ),
                    Expanded(
                      child: Text(s.statusHint, style: AppText.title.copyWith(fontSize: 22)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    Container(
                      height: 340,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.accent, width: 2.4),
                      ),
                      child: _frame(s),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _mode(Icons.photo_camera_rounded, s.camera, _camera, _openCamera)),
                        const SizedBox(width: 10),
                        Expanded(child: _mode(Icons.photo_library_rounded, s.image, _bytes != null && !_camera, _gallery)),
                      ],
                    ),
                    if (_camera) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _viewId == null
                                ? null
                                : () => MethodChannel('qapp/camera_$_viewId').invokeMethod<void>('flip'),
                            icon: Icon(Icons.cameraswitch_rounded, color: AppColors.ink),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _busy ? null : _snap,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent, width: 4),
                                color: _busy ? AppColors.faint : AppColors.card,
                              ),
                              child: Icon(Icons.circle, color: AppColors.accent, size: 42),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _caption,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                      cursorColor: AppColors.accent,
                      decoration: InputDecoration(
                        hintText: s.bioHint,
                        hintStyle: TextStyle(color: AppColors.faint),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(label: s.done, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame(S s) {
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover, width: double.infinity);
    }
    if (_camera && defaultTargetPlatform == TargetPlatform.android) {
      return _StatusCamera(onReady: (id) => _viewId = id);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_rounded, color: AppColors.accent, size: 48),
          const SizedBox(height: 8),
          Text(s.camera, style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _mode(IconData icon, String label, bool on, VoidCallback tap) {
    return Material(
      color: on ? AppColors.accent : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: on ? AppColors.onAccent : AppColors.ink, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: on ? AppColors.onAccent : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCamera extends StatelessWidget {
  const _StatusCamera({required this.onReady});

  final ValueChanged<int> onReady;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'qapp/camera',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final view = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'qapp/camera',
          layoutDirection: Directionality.of(context),
          creationParams: null,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        );
        view
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            onReady(id);
          })
          ..create();
        return view;
      },
    );
  }
}
