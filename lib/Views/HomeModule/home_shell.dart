import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Services/firebase_notification_service.dart';
import 'package:qapp/Views/CallModule/calls_screen.dart';
import 'package:qapp/Views/CallModule/widgets/incoming_call_dialog.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/Views/ChatModule/chats_screen.dart';
import 'package:qapp/Views/GroupModule/groups_screen.dart';
import 'package:qapp/Views/ProfileModule/settings_screen.dart';
import 'package:qapp/Views/StatusModule/status_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/widgets/q_bottom_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 2;
  int _statusTick = 0;
  StreamSubscription? _activitySub;
  StreamSubscription? _callSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activitySub = ChatSocketService.instance.onActivityNotification.listen((data) {
      FirebaseNotificationService.instance.showNotificationFromData(data);
    });

    _callSub = ChatSocketService.instance.onIncomingCall.listen((data) {
      if (mounted) {
        IncomingCallDialog.show(context, data);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activitySub?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ChatSocketService.instance.notifyBackground();
    } else if (state == AppLifecycleState.resumed) {
      ChatSocketService.instance.notifyForeground();
      ChatBook.instance.loadLiveChats();
    }
  }

  void _addStatus() {
    setState(() {
      _index = 0;
      _statusTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          StatusScreen(focusTick: _statusTick),
          const GroupsScreen(),
          ChatsScreen(onAddStatus: _addStatus),
          const SettingsScreen(tab: true),
          const CallsScreen(),
        ],
      ),
      bottomNavigationBar: QBottomBar(
        index: _index,
        youName: MyProfile.name,
        youPhoto: MyProfile.photo,
        onChanged: (value) => setState(() => _index = value),
        onAdd: () => setState(() => _index = 4),
      ),
    );
  }
}
