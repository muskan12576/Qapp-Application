import 'package:flutter/material.dart';
import 'package:qapp/Api/api_exceptions.dart';
import 'package:qapp/Api/api_service.dart';
import 'package:qapp/Views/ChatModule/zego_thread_screen.dart';
import 'package:qapp/theme/app_theme.dart';
import 'package:qapp/theme/q_route.dart';
import 'package:qapp/widgets/q_avatar.dart';
import 'package:qapp/widgets/q_background.dart';

class ZegoPeopleScreen extends StatefulWidget {
  const ZegoPeopleScreen({super.key});

  @override
  State<ZegoPeopleScreen> createState() => _ZegoPeopleScreenState();
}

class _ZegoPeopleScreenState extends State<ZegoPeopleScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _users = const [];
  bool _busy = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final data = await _api.zegoPeers();
      final raw = data['users'];
      final users = raw is List
          ? raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _users = users);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Users load nahi hue');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, dynamic> user) async {
    try {
      final opened = await _api.zegoOpen(user['id'].toString());
      if (!mounted) return;
      await Navigator.of(context).push(qRoute(ZegoThreadScreen(
        zegoId: opened['zego_user_id']?.toString() ?? '',
        name: opened['name']?.toString() ?? user['name']?.toString() ?? 'Qapp',
      )));
    } on ApiException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: QBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text('New chat', style: AppText.title),
                  ),
                ],
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error, style: const TextStyle(color: Color(0xFFFF8A80))),
                ),
              Expanded(
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final name = user['name']?.toString().trim().isNotEmpty == true
                              ? user['name'].toString()
                              : 'Qapp user';
                          return ListTile(
                            onTap: () => _open(user),
                            leading: QAvatar(name: name, size: 46),
                            title: Text(name, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              user['about']?.toString() ?? '',
                              style: AppText.subtitle,
                            ),
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
