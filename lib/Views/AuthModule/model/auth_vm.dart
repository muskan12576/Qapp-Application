import 'package:qapp/Api/api_exceptions.dart';
import 'package:qapp/Api/api_service.dart';
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/zego_session.dart';
import 'package:qapp/Utills/token_storage.dart';

class AuthController extends BaseViewModel {
  AuthController._();
  static final AuthController instance = AuthController._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> sendPhone(String phone) {
    return _run(() => _api.sendPhone(phone));
  }

  Future<Map<String, dynamic>> verifyOtp({required String phoneToken, required String otp}) {
    return _run(() => _api.verifyOtp(phoneToken: phoneToken, otp: otp));
  }

  Future<Map<String, dynamic>> saveName({
    required String setupToken,
    required String name,
    required String about,
  }) {
    return _run(() => _api.saveName(setupToken: setupToken, name: name, about: about));
  }

  Future<Map<String, dynamic>> savePhoto({required String setupToken, required List<int> bytes}) {
    return _run(() => _api.savePhoto(setupToken: setupToken, bytes: bytes));
  }

  Future<Map<String, dynamic>> skipPhoto(String setupToken) {
    return _run(() => _api.skipPhoto(setupToken));
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await ZegoSession.instance.disconnect();
    await TokenStorage.instance.clear();
  }

  Future<void> saveSession(Map<String, dynamic> data, {String? phone}) {
    return TokenStorage.instance.saveLogin(data, phone: phone);
  }

  Future<T> _run<T>(Future<T> Function() call) async {
    setLoading(true);
    clearError();
    try {
      return await call();
    } on ApiException catch (err) {
      setError(err.message);
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
