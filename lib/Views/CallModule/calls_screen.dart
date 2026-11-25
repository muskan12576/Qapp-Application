import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Views/CallModule/group_call_select_screen.dart';
import 'package:qapp/Views/CallModule/model/call_vm.dart';
import 'package:qapp/Views/CallModule/video_call_screen.dart';
import 'package:qapp/Views/CallModule/voice_call_screen.dart';
import 'package:qapp/Views/ChatModule/new_chat_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  List<Map<String, dynamic>> _calls = [];
  bool _loading = true;
  Timer? _refreshTimer;
  String _activeFilter = 'All';

  List<Map<String, dynamic>> get _filteredCalls {
    if (_activeFilter == 'Incoming') {
      return _calls.where((c) {
        final d = c['direction']?.toString().toLowerCase() ?? '';
        final status = c['status']?.toString().toLowerCase() ?? '';
        return d == 'incoming' && status != 'missed' && status != 'no_answer';
      }).toList();
    } else if (_activeFilter == 'Outgoing') {
      return _calls.where((c) {
        final d = c['direction']?.toString().toLowerCase() ?? '';
        return d == 'outgoing';
      }).toList();
    } else if (_activeFilter == 'Missed') {
      return _calls.where((c) {
        final d = c['direction']?.toString().toLowerCase() ?? '';
        final status = c['status']?.toString().toLowerCase() ?? '';
        return d == 'missed' || status == 'missed' || status == 'no_answer' || status == 'rejected';
      }).toList();
    }
    return _calls;
  }

  Widget _filterChip(String label, int count) {
    final active = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.18) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accent : Colors.white12,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.accent : AppColors.inkSoft,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE53935) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCalls();
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) _fetchCalls(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCalls({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final list = await CallViewModel.instance.getCallHistory();
      if (mounted) {
        setState(() {
          _calls = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startVoiceCall(Map<String, dynamic> call) {
    final peerName = call['peer_name']?.toString() ?? 'User';
    final peerId = call['peer_id']?.toString();
    final photo = call['peer_photo']?.toString();
    final t = threadFor(peerName);

    Navigator.of(context).push(
      qRoute(
        VoiceCallScreen(
          name: peerName,
          recipientId: peerId ?? t?.peerId,
          photo: photo ?? t?.photo,
          chatId: t?.chatId,
        ),
      ),
    );
  }

  void _startVideoCall(Map<String, dynamic> call) {
    final peerName = call['peer_name']?.toString() ?? 'User';
    final peerId = call['peer_id']?.toString();
    final photo = call['peer_photo']?.toString();
    final t = threadFor(peerName);

    Navigator.of(context).push(
      qRoute(
        VideoCallScreen(
          name: peerName,
          recipientId: peerId ?? t?.peerId,
          photo: photo ?? t?.photo,
          chatId: t?.chatId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Text(
                      'Calls',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Group Call',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.group_add_rounded, color: Color(0xFF25D366), size: 20),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(qRoute(const GroupCallSelectScreen()));
                      },
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: Icon(Icons.refresh_rounded, color: AppColors.inkSoft, size: 22),
                      onPressed: () => _fetchCalls(),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _filterChip('All', _calls.length),
                    const SizedBox(width: 8),
                    _filterChip('Incoming', _calls.where((c) {
                      final d = c['direction']?.toString().toLowerCase() ?? '';
                      final status = c['status']?.toString().toLowerCase() ?? '';
                      return d == 'incoming' && status != 'missed' && status != 'no_answer';
                    }).length),
                    const SizedBox(width: 8),
                    _filterChip('Outgoing', _calls.where((c) => (c['direction']?.toString().toLowerCase() ?? '') == 'outgoing').length),
                    const SizedBox(width: 8),
                    _filterChip('Missed', _calls.where((c) {
                      final d = c['direction']?.toString().toLowerCase() ?? '';
                      final status = c['status']?.toString().toLowerCase() ?? '';
                      return d == 'missed' || status == 'missed' || status == 'no_answer' || status == 'rejected';
                    }).length),
                  ],
                ),
              ),

              // Section Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Recent',
                  style: TextStyle(
                    color: AppColors.inkSoft.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              // List of Calls
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF25D366),
                  backgroundColor: AppColors.card,
                  onRefresh: () => _fetchCalls(),
                  child: _loading && _calls.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF25D366)),
                        )
                      : _calls.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.phone_missed_rounded,
                                          color: Color(0xFF25D366),
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No recent calls',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Voice and video calls will appear here',
                                        style: TextStyle(
                                          color: AppColors.inkSoft,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF25D366),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        icon: const Icon(Icons.add_call, size: 18),
                                        label: const Text('Start New Call', style: TextStyle(fontWeight: FontWeight.w800)),
                                        onPressed: () {
                                          Navigator.of(context).push(qRoute(const NewChatScreen()));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Builder(
                              builder: (context) {
                                final displayCalls = _filteredCalls;
                                if (displayCalls.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'No $_activeFilter calls found',
                                        style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  itemCount: displayCalls.length,
                                  separatorBuilder: (context, idx) => Divider(
                                    color: AppColors.ink.withValues(alpha: 0.08),
                                    height: 1,
                                    indent: 64,
                                  ),
                                  itemBuilder: (context, index) {
                                    final call = displayCalls[index];
                                final peerName = call['peer_name']?.toString() ?? 'User';
                                final peerPhoto = call['peer_photo']?.toString();
                                final kind = call['kind']?.toString() ?? 'voice';
                                final isVideo = kind == 'video';
                                final direction = call['direction']?.toString() ?? 'incoming';
                                final isMissed = direction == 'missed';
                                final isOutgoing = direction == 'outgoing';

                                final createdStr = call['createddate']?.toString();
                                DateTime? createdDate;
                                if (createdStr != null) {
                                  createdDate = DateTime.tryParse(createdStr);
                                }
                                final timeDisplay = createdDate != null
                                    ? formatLastSeen(createdDate)
                                    : 'Recent';

                                final durationSec = call['duration_sec'];
                                final durInt = durationSec is int
                                    ? durationSec
                                    : int.tryParse(durationSec?.toString() ?? '') ?? 0;
                                final durText = durInt > 0 ? ' • ${durInt}s' : '';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: QAvatar(
                                    name: peerName,
                                    photo: peerPhoto,
                                    size: 50,
                                  ),
                                  title: Text(
                                    peerName,
                                    style: TextStyle(
                                      color: isMissed ? Colors.redAccent : AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        isMissed
                                            ? Icons.call_missed_rounded
                                            : isOutgoing
                                                ? Icons.call_made_rounded
                                                : Icons.call_received_rounded,
                                        color: isMissed ? Colors.redAccent : const Color(0xFF25D366),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$timeDisplay$durText',
                                        style: TextStyle(
                                          color: AppColors.inkSoft.withValues(alpha: 0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.call_rounded,
                                          color: Color(0xFF25D366),
                                          size: 22,
                                        ),
                                        tooltip: 'Voice Call',
                                        onPressed: () => _startVoiceCall(call),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.videocam_rounded,
                                          color: Color(0xFF25D366),
                                          size: 24,
                                        ),
                                        tooltip: 'Video Call',
                                        onPressed: () => _startVideoCall(call),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (isVideo) {
                                      _startVideoCall(call);
                                    } else {
                                      _startVoiceCall(call);
                                    }
                                  },
                                );
                              },
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
