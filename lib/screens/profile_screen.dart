import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/home_shell.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:flutter/services.dart';
import 'package:qapp/widgets/q_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  Uint8List? _photo;

  Future<void> _pickPhoto() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
        compressionQuality: 60,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _photo = bytes);
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final avatarName = _name.text.trim().isEmpty ? 'Qapp' : _name.text.trim();
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: QBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        Text(
                          s.profileTitle,
                          textAlign: TextAlign.center,
                          style: AppText.title,
                        ),
                        const SizedBox(height: 22),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.buttonGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.background,
                                ),
                                child: QAvatar(
                                  name: avatarName,
                                  size: 112,
                                  colorIndex: 2,
                                  bytes: _photo,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.photo_camera_rounded,
                                  size: 16,
                                  color: AppColors.background,
                                ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        QField(
                          controller: _name,
                          hint: s.nameHint,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(s.statusLabel, style: AppText.subtitle),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            QField(
                              controller: _bio,
                              hint: s.bioHint,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              inputFormatters: [LengthLimitingTextInputFormatter(60)],
                              onChanged: (_) => setState(() {}),
                            ),
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Text(
                                '${_bio.text.characters.length}/60',
                                style: TextStyle(color: AppColors.faint, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(s.profileSmall, style: AppText.subtitle),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in _statuses(s))
                              _StatusChip(
                                label: item,
                                onTap: () {
                                  _bio.text = item.length > 60 ? item.substring(0, 60) : item;
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PrimaryButton(
                  label: s.done,
                  onPressed: () {
                    MyProfile.photo = _photo;
                    MyProfile.name = _name.text.trim();
                    MyProfile.bio = _bio.text.trim();
                    Navigator.of(context).pushAndRemoveUntil(
                      qRoute(const HomeShell()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _statuses(S s) => [
  s.stAvailable,
  s.stBusy,
  s.stOnQapp,
  s.stMeeting,
  s.stWork,
  s.stEmergency,
  s.stSleep,
];

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
