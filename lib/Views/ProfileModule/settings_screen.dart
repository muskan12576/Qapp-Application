import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Views/AuthModule/model/auth_vm.dart';
import 'package:qapp/Views/AuthModule/welcome_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/l10n/packs.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.tab = false});

  final bool tab;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final code = LangScope.codeOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          bottom: !tab,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (tab)
                _YouHeader(name: MyProfile.name, bio: MyProfile.bio, photo: MyProfile.photo)
              else ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(child: Text(s.settings, style: AppText.title)),
                  ],
                ),
                const SizedBox(height: 8),
                _YouHeader(name: MyProfile.name, bio: MyProfile.bio, photo: MyProfile.photo),
              ],
              const SizedBox(height: 22),
              Text(
                s.language,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(s.languageHint, style: AppText.subtitle),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: code,
                      isExpanded: true,
                      menuMaxHeight: 380,
                      dropdownColor: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.ink,
                      ),
                      items: [
                        for (final language in appLanguages)
                          DropdownMenuItem(
                            value: language.code,
                            child: Text(
                              language.label,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          AppLang.instance.use(value);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _NotificationToggleTile(
                title: s.notifications,
                subtitle: s.notificationsHint,
              ),
              _InfoTile(
                icon: Icons.lock_outline_rounded,
                title: s.privacy,
                subtitle: s.privacyHint,
              ),
              _InfoTile(
                icon: Icons.info_outline_rounded,
                title: s.about,
                subtitle: s.aboutHint,
              ),
              const _LogoutTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouHeader extends StatefulWidget {
  const _YouHeader({
    required this.name,
    required this.bio,
    required this.photo,
  });

  final String name;
  final String bio;
  final Uint8List? photo;

  @override
  State<_YouHeader> createState() => _YouHeaderState();
}

class _YouHeaderState extends State<_YouHeader> {
  Uint8List? _photoBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _photoBytes = widget.photo ?? MyProfile.photo;
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploading) return;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
        compressionQuality: 70,
      );
      if (file == null || file.path == null) return;
      final bytes = await File(file.path!).readAsBytes();
      if (bytes.isEmpty) return;
      setState(() {
        _photoBytes = bytes;
        _uploading = true;
      });
      final updated = await AuthController.instance.updateUserPhoto(bytes);
      final userObj = updated['user'] is Map ? updated['user'] as Map : updated;
      final url = userObj['profile_image_url']?.toString() ?? userObj['photoUrl']?.toString() ?? '';
      if (url.isNotEmpty) {
        await TokenStorage.instance.updatePhotoUrl(url);
        MyProfile.photoUrl = url;
      }
      MyProfile.photo = bytes;
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo update ho gayi!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo update error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.name.trim().isEmpty ? S.of(context).you : widget.name.trim();
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              QAvatar(
                name: shown,
                size: 96,
                bytes: _photoBytes,
                photo: MyProfile.photoUrl,
              ),
              if (_uploading)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          shown,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (widget.bio.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.bio.trim(), textAlign: TextAlign.center, style: AppText.subtitle),
        ],
      ],
    );
  }
}

class _LogoutTile extends StatefulWidget {
  const _LogoutTile();

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _busy = false;

  Future<void> _logout() async {
    if (_busy) return;
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          s.logoutAsk,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel, style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.logout, style: const TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await AuthController.instance.logout();
    MyProfile.name = '';
    MyProfile.bio = '';
    MyProfile.photo = null;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      qRoute(const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _InfoTile(
      icon: Icons.logout_rounded,
      title: _busy ? '...' : s.logout,
      subtitle: s.logoutSub,
      onTap: _busy ? null : _logout,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
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
          subtitle: Text(subtitle, style: AppText.subtitle),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatefulWidget {
  const _NotificationToggleTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_NotificationToggleTile> createState() => _NotificationToggleTileState();
}

class _NotificationToggleTileState extends State<_NotificationToggleTile> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enabled = prefs.getBool('app_notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggle(bool val) async {
    setState(() => _enabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notifications_enabled', val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _toggle(!_enabled),
          leading: Icon(
            _enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: _enabled ? AppColors.accent : AppColors.inkSoft,
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _enabled ? widget.subtitle : 'Notifications disabled',
            style: AppText.subtitle,
          ),
          trailing: Switch.adaptive(
            value: _enabled,
            activeTrackColor: AppColors.accent,
            onChanged: _toggle,
          ),
        ),
      ),
    );
  }
}
