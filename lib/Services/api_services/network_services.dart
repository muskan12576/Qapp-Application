import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:qapp/Api/api_exceptions.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Utills/token_storage.dart';

class ApiBaseService {
  static Future<String>? _refreshing;

  Future<Map<String, dynamic>> postRequest(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool sendToken = true,
    bool refresh = true,
  }) async {
    final uri = _apiUri(path);
    final headers = <String, String>{'Content-Type': 'application/json'};
    final bearer = sendToken ? (token ?? TokenStorage.instance.token) : '';
    if (bearer.isNotEmpty) headers['Authorization'] = 'Bearer $bearer';
    http.Response response;
    try {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? const {}));
    } catch (err) {
      apiLog(method: 'POST', url: uri, headers: headers, request: body, status: 0, response: '$err');
      throw ApiException('Server tak nahi pahunch sake. Backend chalu hai?', 0);
    }
    try {
      return _read('POST', uri, headers, body, response);
    } on UnauthorizedException {
      if (refresh && sendToken && bearer.isNotEmpty && bearer == TokenStorage.instance.token) {
        final next = await _refreshAccess();
        return postRequest(path, body: body, token: next, refresh: false);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRequest(String path, {bool refresh = true}) async {
    final uri = _apiUri(path);
    final headers = <String, String>{'Accept': 'application/json'};
    final bearer = TokenStorage.instance.token;
    if (bearer.isNotEmpty) headers['Authorization'] = 'Bearer $bearer';
    http.Response response;
    try {
      response = await http.get(uri, headers: headers);
    } catch (err) {
      apiLog(method: 'GET', url: uri, headers: headers, status: 0, response: '$err');
      throw ApiException('Server tak nahi pahunch sake. Backend chalu hai?', 0);
    }
    try {
      return _read('GET', uri, headers, null, response);
    } on UnauthorizedException {
      if (refresh && bearer.isNotEmpty && bearer == TokenStorage.instance.token) {
        final next = await _refreshAccess();
        headers['Authorization'] = 'Bearer $next';
        final again = await http.get(uri, headers: headers);
        return _read('GET', uri, headers, null, again);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postPhoto(
    String path, {
    required List<int> bytes,
    String? token,
    bool refresh = true,
  }) async {
    final uri = _apiUri(path);
    final bearer = token ?? TokenStorage.instance.token;
    final request = http.MultipartRequest('POST', uri);
    if (bearer.isNotEmpty) request.headers['Authorization'] = 'Bearer $bearer';
    final png = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: png ? 'profile.png' : 'profile.jpg',
    ));
    http.Response response;
    try {
      final sent = await request.send();
      response = await http.Response.fromStream(sent);
    } catch (err) {
      apiLog(method: 'POST', url: uri, headers: request.headers, request: {'photo': '${bytes.length} bytes'}, status: 0, response: '$err');
      throw ApiException('Photo upload nahi ho payi', 0);
    }
    try {
      return _read('POST', uri, request.headers, {'photo': '${bytes.length} bytes'}, response);
    } on UnauthorizedException {
      if (refresh && bearer == TokenStorage.instance.token && TokenStorage.instance.refreshToken.isNotEmpty) {
        final next = await _refreshAccess();
        return postPhoto(path, bytes: bytes, token: next, refresh: false);
      }
      rethrow;
    }
  }

  Future<void> sendSmsOtp({required String phone, required String otp}) async {
    if (otp.isEmpty) throw ApiException('OTP nahi bana', 500);
    final uri = Uri.parse(AppConstants.sendOtpUrl).replace(queryParameters: {
      'authkey': AppConstants.otpAuthKey,
      'mobile': phone,
      'otp': otp,
    });
    final logged = uri.replace(queryParameters: {'mobile': phone, 'otp': '******'});
    const headers = {'Accept': 'application/json'};
    http.Response response;
    try {
      response = await http.get(uri, headers: headers);
    } catch (err) {
      apiLog(method: 'GET', url: logged, headers: headers, request: {'mobile': phone}, status: 0, response: '$err');
      throw ApiException('OTP SMS nahi ja paya', 0);
    }
    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } catch (_) {}
    }
    apiLog(
      method: 'GET',
      url: logged,
      headers: headers,
      request: {'mobile': phone},
      status: response.statusCode,
      response: payload.isEmpty ? response.body : payload,
    );
    final sent = payload['status']?.toString().toLowerCase() == 'success';
    if (response.statusCode >= 400 || !sent) {
      throw ApiException(payload['message']?.toString() ?? 'OTP SMS nahi gaya', response.statusCode);
    }
  }

  Uri _apiUri(String path) {
    final base = AppConstants.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final clean = path.trim();
    final suffix = clean.startsWith('/') ? clean : '/$clean';
    return Uri.parse('$base$suffix');
  }

  Future<String> _refreshAccess() {
    return _refreshing ??= _callRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _callRefresh() async {
    final uri = _apiUri(AppConstants.refreshTokenApi);
    final headers = <String, String>{'Content-Type': 'application/json'};
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'refresh_token': TokenStorage.instance.refreshToken}),
      );
    } catch (err) {
      apiLog(method: 'POST', url: uri, headers: headers, request: {'refresh_token': '******'}, status: 0, response: '$err');
      throw ApiException('Token refresh nahi ho paya', 0);
    }
    try {
      final data = _read('POST', uri, headers, {'refresh_token': '******'}, response);
      await TokenStorage.instance.saveLogin(data);
      final next = data['token']?.toString() ?? '';
      if (next.isEmpty) {
        await TokenStorage.instance.clear();
        throw UnauthorizedException('Session khatam. Dubara OTP se login karo', 401);
      }
      return next;
    } on ApiException catch (err) {
      if (err.statusCode == 401) await TokenStorage.instance.clear();
      rethrow;
    }
  }

  Map<String, dynamic> _read(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? request,
    http.Response response,
  ) {
    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    }
    apiLog(
      method: method,
      url: uri,
      headers: headers,
      request: request,
      status: response.statusCode,
      response: payload.isEmpty ? response.body : _hideOtp(payload),
    );
    final message = payload['message']?.toString() ?? 'Request fail ho gayi';
    final status = response.statusCode;
    if (status >= 400 || payload['success'] == false) {
      if (status == 401) throw UnauthorizedException(message, status);
      if (status == 400) throw BadRequestException(message, status);
      if (status == 404) throw NotFoundException(message, status);
      if (status >= 500) throw ServerErrorException(message, status);
      throw ApiException(message, status);
    }
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    return payload;
  }
}

Object? _hideOtp(Object? value) {
  if (value is Map) {
    final copy = <String, dynamic>{};
    value.forEach((key, item) {
      final hidden = key == 'otp' || key == 'token' || key == 'refresh_token' || key == 'appSign';
      copy[key.toString()] = hidden ? '******' : _hideOtp(item);
    });
    return copy;
  }
  if (value is List) return value.map(_hideOtp).toList();
  return value;
}
