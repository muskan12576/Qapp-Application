import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/l10n/packs.dart';
import 'package:qapp/screens/calls_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/qapp_logo.dart';

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
                const Center(child: QappLogo(width: 92)),
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
              _InfoTile(
                icon: Icons.notifications_none_rounded,
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
              if (tab)
                _InfoTile(
                  icon: Icons.call_rounded,
                  title: s.callsTitle,
                  subtitle: s.callHistory,
                  onTap: () {
                    Navigator.of(context).push(qRoute(const CallsScreen()));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouHeader extends StatelessWidget {
  const _YouHeader({
    required this.name,
    required this.bio,
    required this.photo,
  });

  final String name;
  final String bio;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final shown = name.trim().isEmpty ? S.of(context).you : name.trim();
    return Column(
      children: [
        const SizedBox(height: 12),
        QAvatar(name: shown, size: 92, bytes: photo),
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
        if (bio.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(bio.trim(), textAlign: TextAlign.center, style: AppText.subtitle),
        ],
      ],
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
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
