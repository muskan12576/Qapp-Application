import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/l10n/app_lang.dart';
import 'package:qapp/screens/video_call_screen.dart';
import 'package:qapp/screens/voice_call_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/primary_button.dart';
import 'package:qapp/widgets/q_background.dart';
import 'package:qapp/widgets/q_field.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final List<String> _groups = [];

  Future<void> _newGroup() async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).groupTitle,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              QField(
                controller: controller,
                hint: S.of(context).groupHint,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: S.of(context).create,
                onPressed: () => Navigator.of(context).pop(controller.text),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }
    setState(() => _groups.add(name.trim()));
  }

  void _voice(String name) {
    Navigator.of(context).push(
      qRoute(
        VoiceCallScreen(
          name: name,
          colorIndex: threadFor(name)?.colorIndex ?? 1,
          photo: threadFor(name)?.photo,
          status: S.of(context).callStatus(name),
        ),
      ),
    );
  }

  void _video(String name) {
    Navigator.of(context).push(
      qRoute(
        VideoCallScreen(
          name: name,
          colorIndex: threadFor(name)?.colorIndex ?? 1,
          photo: threadFor(name)?.photo,
          status: S.of(context).callStatus(name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return QBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                  Expanded(child: Text(s.callsTitle, style: AppText.title)),
                ],
              ),
              const SizedBox(height: 4),
              Text(s.callsSub, style: AppText.subtitle),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      s.callHistory,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final call in callHistory)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _voice(call.name),
                              child: QAvatar(
                                name: call.name,
                                size: 48,
                                colorIndex:
                                    threadFor(call.name)?.colorIndex ?? 1,
                                photo: threadFor(call.name)?.photo,
                                bytes: threadFor(call.name)?.photoBytes,
                                online: threadFor(call.name)?.online ?? false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _voice(call.name),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      call.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      call.time,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _video(call.name),
                              child: const _PhoneBadge(
                                compact: true,
                                video: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      s.groups,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final group in _groups)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const _PhoneBadge(group: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                group,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PrimaryButton(
                label: s.newGroup,
                icon: Icons.auto_awesome,
                iconOnEdge: true,
                onPressed: _newGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneBadge extends StatelessWidget {
  const _PhoneBadge({
    this.compact = false,
    this.group = false,
    this.video = false,
  });

  final bool compact;
  final bool group;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
      ),
      child: Icon(
        group
            ? Icons.groups_rounded
            : video
            ? Icons.videocam_rounded
            : Icons.phone_rounded,
        color: AppColors.ink,
        size: compact ? 18 : 22,
      ),
    );
  }
}
