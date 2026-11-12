import 'package:flutter/material.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/Views/ChatModule/chats_screen.dart';
import 'package:qapp/Views/GroupModule/groups_screen.dart';
import 'package:qapp/Views/ChatModule/new_chat_screen.dart';
import 'package:qapp/Views/ProfileModule/settings_screen.dart';
import 'package:qapp/Views/StatusModule/status_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_bottom_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 2;
  int _statusTick = 0;

  void _addGroup() {
    Navigator.of(context).push(qRoute(const NewGroupScreen()));
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
        ],
      ),
      bottomNavigationBar: QBottomBar(
        index: _index,
        youName: MyProfile.name,
        youPhoto: MyProfile.photo,
        onChanged: (value) => setState(() => _index = value),
        onAdd: _addGroup,
      ),
    );
  }
}
