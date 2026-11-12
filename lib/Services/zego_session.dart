import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qapp/Api/api_exceptions.dart';
import 'package:qapp/Api/api_service.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:zego_zim/zego_zim.dart';

class ZegoSession extends ChangeNotifier {
  ZegoSession._();
  static final ZegoSession instance = ZegoSession._();

  final ApiService _api = ApiService();
  Future<void>? _pending;
  bool ready = false;
  bool busy = false;
  String error = '';
  String userID = '';
  int inboxTick = 0;

  Future<void> connect() {
    if (!TokenStorage.instance.isLoggedIn) return Future.value();
    return _pending ??= _connect().whenComplete(() => _pending = null);
  }

  Future<void> _connect() async {
    busy = true;
    error = '';
    notifyListeners();
    try {
      final data = await _api.zegoToken();
      final appID = int.parse(data['appID'].toString());
      final id = data['userID']?.toString() ?? '';
      final name = data['userName']?.toString() ?? 'Qapp';
      final token = data['token']?.toString() ?? '';
      final appSign = data['appSign']?.toString() ?? '';
      if (id.isEmpty) throw ApiException('Zego user id nahi mila', 500);
      if (appSign.isEmpty && token.isEmpty) {
        throw ApiException('Zego token/appSign nahi mila', 500);
      }

      await _resetNative();
      final zim = ZIM.create(ZIMAppConfig(appID: appID, appSign: appSign));
      if (zim == null) throw ApiException('Zego start nahi hua', 500);
      _hooks();

      final login = ZIMLoginConfig(
        userName: name,
        // AppSign mode: empty token. Token mode: server token.
        token: appSign.isEmpty ? token : '',
      );
      debugPrint('ZIM login start user=$id appSign=${appSign.isNotEmpty} token=${token.isNotEmpty}');
      await zim.login(id, login);
      ready = true;
      userID = id;
      error = '';
      debugPrint('ZIM LOGIN OK user=$id');
    } on PlatformException catch (err) {
      ready = false;
      userID = '';
      error = 'Zego ${err.code}: ${err.message ?? 'login fail'}';
      debugPrint('ZIM LOGIN FAILED platform code=${err.code} msg=${err.message}');
      await _resetNative();
    } catch (err) {
      ready = false;
      userID = '';
      error = err is ApiException ? err.message : '$err';
      debugPrint('ZIM LOGIN FAILED: $err');
      await _resetNative();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _resetNative() async {
    try {
      final zim = ZIM.getInstance();
      if (zim == null) return;
      try {
        zim.logout();
      } catch (_) {}
      zim.destroy();
    } catch (_) {}
  }

  void _hooks() {
    ZIMEventHandler.onTokenWillExpire = (engine, second) {
      _renew(engine);
    };
    ZIMEventHandler.onMessageReceived = (engine, result) {
      inboxTick++;
      notifyListeners();
    };
    ZIMEventHandler.onConversationChanged = (engine, infos) {
      inboxTick++;
      notifyListeners();
    };
  }

  Future<void> _renew(ZIM zim) async {
    try {
      final data = await _api.zegoToken();
      final token = data['token']?.toString() ?? '';
      if (token.isNotEmpty) await zim.renewToken(token);
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _resetNative();
    ready = false;
    userID = '';
    error = '';
    notifyListeners();
  }
}
