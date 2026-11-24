import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Utills/token_storage.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel._();
  static final AuthViewModel instance = AuthViewModel._();

  final ApiBaseService _api = ApiBaseService();

  Future<Map<String, dynamic>> sendPhone(String phone) {
    return _run(() async {
      final res = await _api.postRequest(
        AppConstants.sendPhoneApi,
        {'phone': phone},
        sendToken: false,
      );
      if (res == null) throw ApiException('Server tak nahi pahunch sake');
      final data = _api.handleHttpResponse(res) as Map<String, dynamic>;
      final dataMap = Map<String, dynamic>.from(data['data'] ?? data);
      // SMS API disabled per user request - OTP returned directly for screen display
      return dataMap;
    });
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneToken,
    required String otp,
  }) {
    return _run(() async {
      final fullUrl = _api.resolveUrl(AppConstants.verifyOtpApi);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': phoneToken.startsWith('Bearer ') ? phoneToken : 'Bearer $phoneToken',
      };
      final res = await http
          .post(
            Uri.parse(fullUrl),
            headers: headers,
            body: jsonEncode({'otp': otp}),
          )
          .timeout(_api.timeoutDuration);
      final body = _api.handleHttpResponse(res);
      return Map<String, dynamic>.from(body['data'] ?? body);
    });
  }

  Future<Map<String, dynamic>> saveName({
    required String setupToken,
    required String name,
    required String about,
  }) {
    return _run(() async {
      final fullUrl = _api.resolveUrl(AppConstants.saveNameApi);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': setupToken.startsWith('Bearer ') ? setupToken : 'Bearer $setupToken',
      };
      final res = await http
          .post(
            Uri.parse(fullUrl),
            headers: headers,
            body: jsonEncode({'name': name, 'about': about}),
          )
          .timeout(_api.timeoutDuration);
      final body = _api.handleHttpResponse(res);
      return Map<String, dynamic>.from(body['data'] ?? body);
    });
  }

  Future<Map<String, dynamic>> savePhoto({
    required String setupToken,
    required List<int> bytes,
  }) {
    return _run(() async {
      final fullUrl = _api.resolveUrl(AppConstants.savePhotoApi);
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      request.headers['Authorization'] =
          setupToken.startsWith('Bearer ') ? setupToken : 'Bearer $setupToken';
      final png = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: png ? 'profile.png' : 'profile.jpg',
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      final body = _api.handleHttpResponse(res);
      return Map<String, dynamic>.from(body['data'] ?? body);
    });
  }

  Future<Map<String, dynamic>> updateUserPhoto(List<int> bytes) {
    return _run(() async {
      final token = await TokenStorage.getAccessToken();
      final fullUrl = _api.resolveUrl(AppConstants.updateUserPhotoApi);
      final request = http.MultipartRequest('PUT', Uri.parse(fullUrl));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] =
            token.startsWith('Bearer ') ? token : 'Bearer $token';
      }
      final png = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: png ? 'profile.png' : 'profile.jpg',
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      final body = _api.handleHttpResponse(res);
      return Map<String, dynamic>.from(body['data'] ?? body);
    });
  }

  Future<Map<String, dynamic>> skipPhoto(String setupToken) {
    return _run(() async {
      final fullUrl = _api.resolveUrl(AppConstants.skipPhotoApi);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': setupToken.startsWith('Bearer ') ? setupToken : 'Bearer $setupToken',
      };
      final res = await http
          .post(Uri.parse(fullUrl), headers: headers, body: jsonEncode({}))
          .timeout(_api.timeoutDuration);
      final body = _api.handleHttpResponse(res);
      return Map<String, dynamic>.from(body['data'] ?? body);
    });
  }

  Future<void> logout() async {
    try {
      await _api.postRequest(AppConstants.logoutApi, {});
    } catch (_) {}
    await TokenStorage.instance.clear();
  }

  Future<void> sendSmsOtp({required String phone, required String otp}) async {
    if (otp.isEmpty) return;
    try {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
      final uri = Uri.parse(AppConstants.sendOtpUrl).replace(
        queryParameters: {
          'authkey': AppConstants.otpAuthKey,
          'mobile': ten,
          'country_code': '91',
          'sid': '15548',
          'otp': otp,
        },
      );
      await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (err) {
      log('[SMS] Error sending OTP SMS: $err');
    }
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

// Keep typedef so AuthController references continue to work seamlessly
typedef AuthController = AuthViewModel;
