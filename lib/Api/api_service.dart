import 'package:qapp/Services/api_services/network_services.dart';
import 'package:qapp/Utills/app_constants.dart';

class ApiService {
  final ApiBaseService _api = ApiBaseService();

  Future<Map<String, dynamic>> sendPhone(String phone) async {
    final data = await _api.postRequest(
      '/api/v1/login-mobile/phone',
      body: {'phone': phone},
      sendToken: false,
    );
    final otp = data.remove('otp')?.toString() ?? '';
    await _api.sendSmsOtp(phone: phone, otp: otp);
    return data;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneToken,
    required String otp,
  }) {
    print(
      'ApiService: verifyOtp called with phoneToken: $phoneToken, otp: $otp',
    );
    return _api.postRequest(
      AppConstants.verifyOtpApi,
      token: phoneToken,
      body: {'otp': otp},
      refresh: false,
    );
  }

  Future<Map<String, dynamic>> saveName({
    required String setupToken,
    required String name,
    required String about,
  }) {
    return _api.postRequest(
      AppConstants.saveNameApi,
      token: setupToken,
      body: {'name': name, 'about': about},
      refresh: false,
    );
  }

  Future<Map<String, dynamic>> savePhoto({
    required String setupToken,
    required List<int> bytes,
  }) {
    return _api.postPhoto(
      AppConstants.savePhotoApi,
      token: setupToken,
      bytes: bytes,
      refresh: false,
    );
  }

  Future<Map<String, dynamic>> logout() {
    return _api.postRequest(AppConstants.logoutApi);
  }

  Future<Map<String, dynamic>> zegoToken() {
    return _api.getRequest(AppConstants.zegoTokenApi);
  }

  Future<Map<String, dynamic>> zegoPeers() {
    return _api.getRequest(AppConstants.zegoPeersApi);
  }

  Future<Map<String, dynamic>> zegoOpen(String userId) {
    return _api.postRequest(AppConstants.zegoOpenApi, body: {'userId': userId});
  }

  Future<Map<String, dynamic>> skipPhoto(String setupToken) {
    return _api.postRequest(
      AppConstants.skipPhotoApi,
      token: setupToken,
      refresh: false,
    );
  }
}
