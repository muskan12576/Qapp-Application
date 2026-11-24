import 'package:flutter/material.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Views/CallModule/group_call_screen.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';

class GroupCallSelectScreen extends StatefulWidget {
  const GroupCallSelectScreen({super.key});

  @override
  State<GroupCallSelectScreen> createState() => _GroupCallSelectScreenState();
}

class _GroupCallSelectScreenState extends State<GroupCallSelectScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedPeerIds = {};
  final List<ChatThread> _selectedContacts = [];
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleContact(ChatThread thread) {
    final peerId = thread.peerId ?? thread.chatId ?? thread.name;
    setState(() {
      if (_selectedPeerIds.contains(peerId)) {
        _selectedPeerIds.remove(peerId);
        _selectedContacts.removeWhere(
          (c) => (c.peerId ?? c.chatId ?? c.name) == peerId,
        );
      } else {
        _selectedPeerIds.add(peerId);
        _selectedContacts.add(thread);
      }
    });
  }

  void _startGroupCall({required bool isVideo}) {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kam se kam 1 contact select karein")),
      );
      return;
    }

    final roomId = 'group_call_${DateTime.now().millisecondsSinceEpoch}';
    final participantIds = _selectedPeerIds.toList();
    final groupName =
        _selectedContacts.map((c) => c.name).take(3).join(', ') +
        (_selectedContacts.length > 3
            ? ' +${_selectedContacts.length - 3}'
            : '');

    // Notify participants via socket
    ChatSocketService.instance.initiateAgoraCall(
      channelName: roomId,
      callType: isVideo ? 'video' : 'voice',
      isGroup: true,
      recipientIds: participantIds,
      callId: roomId,
    );

    Navigator.of(context).pushReplacement(
      qRoute(
        GroupCallScreen(
          groupName: groupName,
          roomId: roomId,
          participantIds: participantIds,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allChats = ChatBook.instance.threads
        .where((c) => !c.isGroup)
        .toList();
    final filtered = allChats.where((c) {
      if (_filter.isEmpty) return true;
      return c.name.toLowerCase().contains(_filter.toLowerCase()) ||
          c.phone.contains(_filter);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Group Call",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${_selectedContacts.length} selected",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selected contacts horizontal list
          if (_selectedContacts.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedContacts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final contact = _selectedContacts[i];
                  return Column(
                    children: [
                      Stack(
                        children: [
                          QAvatar(
                            name: contact.name,
                            size: 48,
                            photo: contact.photo,
                            colorIndex: contact.colorIndex,
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: GestureDetector(
                              onTap: () => _toggleContact(contact),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.name.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _filter = v.trim()),
              decoration: InputDecoration(
                hintText: "Search contacts...",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Contact List
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final chat = filtered[i];
                final peerId = chat.peerId ?? chat.chatId ?? chat.name;
                final isSelected = _selectedPeerIds.contains(peerId);

                return ListTile(
                  onTap: () => _toggleContact(chat),
                  leading: QAvatar(
                    name: chat.name,
                    size: 46,
                    photo: chat.photo,
                    colorIndex: chat.colorIndex,
                  ),
                  title: Text(
                    chat.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    chat.phone.isNotEmpty ? chat.phone : chat.about,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF25D366)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF25D366)
                            : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedContacts.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startGroupCall(isVideo: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF25D366)),
                        ),
                      ),
                      icon: const Icon(Icons.call, color: Color(0xFF25D366)),
                      label: const Text(
                        "Voice Call",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startGroupCall(isVideo: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.videocam, color: Colors.black),
                      label: const Text(
                        "Video Call",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
