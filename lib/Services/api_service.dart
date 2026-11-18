// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qapp/Utills/app_colors.dart';
import 'package:qapp/Utills/app_constants.dart'
    show AppConstants, SharedPrefsConstants;
import 'package:qapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qapp/Utills/app_utils.dart';
import 'package:qapp/Utills/token_storage.dart';

// --- API Exceptions ---

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, [super.statusCode]);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message, [super.statusCode]);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message, [super.statusCode]);
}

class ServerErrorException extends ApiException {
  ServerErrorException(super.message, [super.statusCode]);
}

// --- Base API Service ---

class ApiBaseService {
  final Duration timeoutDuration = const Duration(seconds: 30);
  final Uuid _uuid = const Uuid();

  ApiBaseService();

  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  String _resolveUrl(String url) => resolveUrl(url);

  Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(SharedPrefsConstants.authToken);
    final authValue = (token != null && token.isNotEmpty)
        ? (token.startsWith('Bearer ') ? token : 'Bearer $token')
        : '';
    return {'Content-Type': 'application/json', 'Authorization': authValue};
  }

  Future<Map<String, String>> getMultipartHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(SharedPrefsConstants.authToken) ?? "";
    final authValue = token.isNotEmpty
        ? (token.startsWith('Bearer ') ? token : 'Bearer $token')
        : '';
    return {'Authorization': authValue};
  }

  Future<bool> _isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isInternet = connectivityResult.contains(ConnectivityResult.none);
    return !isInternet;
  }

  String _extractErrorMessage(dynamic body, http.Response response) {
    if (body == null) {
      return response.reasonPhrase ?? 'Unknown error occurred';
    }

    if (body is String) {
      return body;
    }

    if (body is Map) {
      final keys = ['message', 'error', 'detail', 'error_description'];
      for (final k in keys) {
        final v = body[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String) return first;
        if (first is Map && first['message'] is String) return first['message'];
      }
    }

    return response.reasonPhrase ?? 'Unknown error occurred';
  }

  dynamic handleHttpResponse(http.Response response) {
    final status = response.statusCode;
    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      body = response.body;
    }

    if (status >= 200 && status < 300) {
      return body;
    }

    final message = _extractErrorMessage(body, response);

    switch (status) {
      case 400:
        throw BadRequestException(message, status);
      case 401:
        throw UnauthorizedException(message, status);
      case 403:
        throw UnauthorizedException('Access denied', status);
      case 404:
        throw NotFoundException(message, status);
      case 405:
        throw ApiException(message, status);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerErrorException(message, status);
      default:
        throw ApiException(message, status);
    }
  }

  ApiException handleNetworkError(Object e, String method) {
    if (e is SocketException) {
      return ApiException('No Internet connection');
    } else if (e is HttpException) {
      return ApiException('Failed to perform $method request');
    } else if (e is FormatException) {
      return ApiException('Bad response format');
    } else if (e is TimeoutException) {
      return ApiException('Request timed out');
    } else if (e is ApiException) {
      return e;
    }
    unawaited(
      reportError(
        message: 'Mobile $method Error: $e',
        service: 'Flutter HTTP',
        level: 'error',
      ),
    );
    return ApiException('Unexpected error: $e');
  }

  Future<void> reportError({
    required String message,
    String? service,
    String? stack,
    String level = 'error',
    String? screen,
  }) async {
    try {
      final fullUrl = resolveUrl(AppConstants.errorReportApi);
      final userId = TokenStorage.instance.userId;
      final userName = TokenStorage.instance.name;
      final userPhone = TokenStorage.instance.phone;

      await http
          .post(
            Uri.parse(fullUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'service': service ?? 'Mobile Flutter',
              'level': level,
              'stack': stack,
              'source': 'mobile',
              'screen': screen,
              'userId': userId.isNotEmpty ? userId : null,
              'userName': userName.isNotEmpty ? userName : null,
              'userPhone': userPhone.isNotEmpty ? userPhone : null,
              'deviceInfo': 'Qapp Android/iOS',
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<String>? _refreshing;
  static void Function()? onTokenRefreshed;

  Future<String> refreshAccess() => _refreshAccess();

  Future<String> _refreshAccess() {
    return _refreshing ??= _callRefresh().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<String> _callRefresh() async {
    final refreshTok = TokenStorage.instance.refreshToken;
    if (refreshTok.isEmpty) {
      _log("Refresh token is empty, cannot refresh token");
      throw UnauthorizedException(
        "Session khatam ho gayi, dubara login karo",
        401,
      );
    }

    final fullUrl = _resolveUrl(AppConstants.refreshTokenApi);
    final headers = {'Content-Type': 'application/json'};
    final body = {'refresh_token': refreshTok};
    final requestId = _uuid.v4();

    http.Response response;
    try {
      response = await http
          .post(Uri.parse(fullUrl), headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);
    } catch (err) {
      _logApiCall(
        requestId: requestId,
        method: "POST",
        url: fullUrl,
        headers: headers,
        body: {'refresh_token': '******'},
        response: null,
        error: '$err',
      );
      throw ApiException('Token refresh nahi ho paya: $err', 0);
    }

    _logApiCall(
      requestId: requestId,
      method: "POST",
      url: fullUrl,
      headers: headers,
      body: {'refresh_token': '******'},
      response: response,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) {
          await TokenStorage.instance.saveLogin(data);
          final nextToken = data['token']?.toString() ?? '';
          _log("Token refreshed successfully! New token issued.");
          try {
            onTokenRefreshed?.call();
          } catch (e) {
            _log("Error in onTokenRefreshed callback: $e");
          }
          return nextToken;
        }
      } catch (err) {
        _log("Error parsing refresh response: $err");
      }
    }

    _log("Token refresh failed with status ${response.statusCode}");
    await TokenStorage.instance.clear();
    throw UnauthorizedException(
      "Session khatam ho gayi, dubara login karo",
      401,
    );
  }

  Future<http.Response?> handleApiResponse({
    required http.Response response,
    required Future<http.Response> Function() retryFn,
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    required String requestId,
  }) async {
    _logApiCall(
      requestId: requestId,
      method: method,
      url: url,
      headers: headers,
      body: body,
      response: response,
    );

    if (response.statusCode == 401) {
      final isRefreshCall = url.contains(AppConstants.refreshTokenApi);
      final hasRefreshToken = TokenStorage.instance.refreshToken.isNotEmpty;

      if (!isRefreshCall && hasRefreshToken) {
        _log("Received 401 status, attempting token refresh...");
        try {
          final nextToken = await _refreshAccess();
          if (nextToken.isNotEmpty) {
            _log("Retrying $method request with refreshed token for: $url");
            final retryResponse = await retryFn();
            _logApiCall(
              requestId: requestId,
              method: "$method (RETRIED)",
              url: url,
              headers: await getHeaders(),
              body: body,
              response: retryResponse,
            );
            if (retryResponse.statusCode >= 200 &&
                retryResponse.statusCode < 300) {
              return retryResponse;
            } else if (retryResponse.statusCode == 400) {
              return retryResponse;
            }
            handleHttpResponse(retryResponse);
            return retryResponse;
          }
        } catch (err) {
          _log("Token refresh failed: $err");
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 400) {
      return response;
    } else {
      handleHttpResponse(response);
      return response;
    }
  }

  void _logOffline(String method, String url) {
    _log("No internet connection - $method request cancelled for: $url");
  }

  Future<http.Response?> getRequest(
    String url, {
    bool sendToken = true,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("GET", fullUrl);
      return null;
    }

    final uri = Uri.parse(fullUrl).replace(queryParameters: queryParams);
    Map<String, String> headers;
    if (token != null && token.isNotEmpty) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };
    } else if (sendToken) {
      headers = await getHeaders();
    } else {
      headers = {'Content-Type': 'application/json'};
    }
    final requestId = _uuid.v4();

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeoutDuration);

      return await handleApiResponse(
        response: response,
        retryFn: () async => await http
            .get(
              uri,
              headers: sendToken
                  ? await getHeaders()
                  : {'Content-Type': 'application/json'},
            )
            .timeout(timeoutDuration),
        method: "GET",
        url: uri.toString(),
        headers: headers,
        body: null,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "GET",
        url: uri.toString(),
        headers: headers,
        body: null,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "GET");
      }
    }
  }

  Future<http.Response?> postRequest(
    String url,
    Map<String, dynamic> body, {
    bool sendToken = true,
    String? token,
  }) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("POST", fullUrl);
      return null;
    }

    final requestId = _uuid.v4();
    Map<String, String> headers;
    if (token != null && token.isNotEmpty) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };
    } else if (sendToken) {
      headers = await getHeaders();
    } else {
      headers = {"Content-Type": "application/json"};
    }

    try {
      final response = await http
          .post(Uri.parse(fullUrl), headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      return await handleApiResponse(
        response: response,
        retryFn: () async => await http
            .post(
              Uri.parse(fullUrl),
              headers: sendToken
                  ? await getHeaders()
                  : {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
            .timeout(timeoutDuration),
        method: "POST",
        url: fullUrl,
        headers: headers,
        body: body,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "POST",
        url: fullUrl,
        headers: headers,
        body: body,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "POST");
      }
    }
  }

  Future<http.Response?> postMultipartRequest(
    String url, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    String? token,
  }) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("POST-MULTIPART", fullUrl);
      return null;
    }

    final requestId = _uuid.v4();
    final headers = await getMultipartHeaders();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = token.startsWith('Bearer ')
          ? token
          : 'Bearer $token';
    }
    const uploadTimeout = Duration(seconds: 90);

    Future<http.Response> sendMultipart() async {
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      request.headers.addAll(headers);
      request.fields.addAll(fields);
      request.files.addAll(files);
      final streamed = await request.send().timeout(uploadTimeout);
      return http.Response.fromStream(streamed);
    }

    try {
      final response = await sendMultipart();
      return await handleApiResponse(
        response: response,
        retryFn: sendMultipart,
        method: "POST-MULTIPART",
        url: fullUrl,
        headers: headers,
        body: fields,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "POST-MULTIPART",
        url: fullUrl,
        headers: headers,
        body: fields,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "POST-MULTIPART");
      }
    }
  }

  Future<http.Response?> putRequest(
    String url,
    Map<String, dynamic> body, {
    bool sendToken = true,
  }) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("PUT", fullUrl);
      return null;
    }

    final headers = sendToken
        ? await getHeaders()
        : {"Content-Type": "application/json"};
    final requestId = _uuid.v4();

    try {
      final response = await http
          .put(Uri.parse(fullUrl), headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      return await handleApiResponse(
        response: response,
        retryFn: () async => await http
            .put(
              Uri.parse(fullUrl),
              headers: await getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeoutDuration),
        method: "PUT",
        url: fullUrl,
        headers: sendToken
            ? await getHeaders()
            : {"Content-Type": "application/json"},
        body: body,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "PUT",
        url: fullUrl,
        headers: headers,
        body: body,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "PUT");
      }
    }
  }

  Future<http.Response?> patchRequest(
    String url,
    Map<String, dynamic> body, {
    bool sendToken = true,
  }) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("PATCH", fullUrl);
      return null;
    }

    final headers = sendToken
        ? await getHeaders()
        : {"Content-Type": "application/json"};
    final requestId = _uuid.v4();

    try {
      final response = await http
          .patch(Uri.parse(fullUrl), headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      return await handleApiResponse(
        response: response,
        retryFn: () async => await http
            .patch(
              Uri.parse(fullUrl),
              headers: sendToken
                  ? await getHeaders()
                  : {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
            .timeout(timeoutDuration),
        method: "PATCH",
        url: fullUrl,
        headers: headers,
        body: body,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "PATCH",
        url: fullUrl,
        headers: headers,
        body: body,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "PATCH");
      }
    }
  }

  Future<http.Response?> deleteRequest(
    String url, [
    Map<String, dynamic>? body,
  ]) async {
    final fullUrl = _resolveUrl(url);
    if (!await _isInternetAvailable()) {
      _logOffline("DELETE", fullUrl);
      return null;
    }

    final headers = await getHeaders();
    final requestId = _uuid.v4();

    try {
      final response = await http
          .delete(Uri.parse(fullUrl), headers: headers)
          .timeout(timeoutDuration);

      return await handleApiResponse(
        response: response,
        retryFn: () async => await http
            .delete(Uri.parse(fullUrl), headers: await getHeaders())
            .timeout(timeoutDuration),
        method: "DELETE",
        url: fullUrl,
        headers: headers,
        body: body,
        requestId: requestId,
      );
    } catch (e) {
      _logApiCall(
        requestId: requestId,
        method: "DELETE",
        url: fullUrl,
        headers: headers,
        body: null,
        response: null,
        error: e.toString(),
      );

      if (e is ApiException) {
        rethrow;
      } else {
        throw handleNetworkError(e, "DELETE");
      }
    }
  }

  void _logApiCall({
    required String requestId,
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    http.Response? response,
    String? error,
  }) {
    final border = "═" * 60;
    final isResponse = response != null;

    final buffer = StringBuffer();

    if (isResponse) {
      buffer.writeln("┌$border");
      buffer.writeln("│  API CALL COMPLETED [$method] ");
      buffer.writeln("│  URL: $url");
      if (headers != null) {
        buffer.writeln("│  Headers: ${jsonEncode(headers)}");
      }
      if (body != null) {
        buffer.writeln("│  Request Body: ${jsonEncode(body)}");
      }
      buffer.writeln("│  Status: ${response.statusCode}");
      buffer.writeln("│  Response Body: ${response.body}");
      buffer.writeln("│  ${DateTime.now().toIso8601String()}");
      buffer.writeln("└$border");
    } else if (error != null) {
      buffer.writeln("┌$border");
      buffer.writeln("│  API CALL FAILED [$method] ");
      buffer.writeln("│  URL: $url");
      if (headers != null) {
        buffer.writeln("│  Headers: ${jsonEncode(headers)}");
      }
      if (body != null) {
        buffer.writeln("│  Request Body: ${jsonEncode(body)}");
      }
      buffer.writeln("│  Error: $error");
      buffer.writeln("│  ${DateTime.now().toIso8601String()}");
      buffer.writeln("└$border");
    }

    final output = buffer.toString();
    log(output);
    if (output.isNotEmpty) {
      debugLog(output);
    }
  }

  void _log(String message) {
    log(" API LOG: $message");
    debug("API LOG: $message");
  }
}

// --- App Dialog Helper ---

enum DialogType { success, error, warning, info }

class AppDialog {
  static Future<void> show({
    required DialogType type,
    required String message,
    String title = "",
    bool barrierDismissible = false,
    VoidCallback? onConfirm,
    String confirmText = "OK",
    Duration? autoDismissDuration,
  }) {
    IconData icon;
    Color color;

    switch (type) {
      case DialogType.success:
        icon = Icons.check_circle_outline;
        color = AppColors.kAmber;
        title = title.isEmpty ? "Success" : title;
        break;
      case DialogType.error:
        icon = Icons.error_outline;
        color = AppColors.redcolor;
        title = title.isEmpty ? "Error" : title;
        break;
      case DialogType.warning:
        icon = Icons.warning_amber_rounded;
        color = AppColors.kAmber;
        title = title.isEmpty ? "Warning" : title;
        break;
      case DialogType.info:
        icon = Icons.info_outline;
        color = Colors.blue;
        title = title.isEmpty ? "Information" : title;
        break;
    }

    final navContext = GlobalVariable.navState.currentContext;
    if (navContext == null || !navContext.mounted) {
      log(
        "⚠️ AppDialog.show skipped: Navigator context is null or unmounted ($message)",
      );
      return Future.value();
    }

    return showDialog(
      context: navContext,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        if (autoDismissDuration != null) {
          Timer(autoDismissDuration, () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            if (onConfirm != null) onConfirm();
          });
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                if (autoDismissDuration == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: AppColors.whitetext,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onConfirm != null) onConfirm();
                      },
                      child: Text(confirmText),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Common Unified ApiService ---

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  factory ApiService() => instance;

  final ApiBaseService _api = ApiBaseService();
  ApiBaseService get base => _api;

  // --- Auth APIs ---

  Future<Map<String, dynamic>> sendPhone(String phone) async {
    final res = await _api.postRequest(AppConstants.sendPhoneApi, {
      'phone': phone,
    }, sendToken: false);
    if (res == null) throw ApiException('Server tak nahi pahunch sake');
    final data = _api.handleHttpResponse(res) as Map<String, dynamic>;
    final dataMap = Map<String, dynamic>.from(data['data'] ?? data);
    final otp = dataMap.remove('otp')?.toString() ?? '';
    await sendSmsOtp(phone: phone, otp: otp);
    return dataMap;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneToken,
    required String otp,
  }) async {
    final res = await _api.postRequest(AppConstants.verifyOtpApi, {
      'otp': otp,
    }, token: phoneToken);
    if (res == null) throw ApiException('Server tak nahi pahunch sake');
    final body = _api.handleHttpResponse(res);
    return Map<String, dynamic>.from(body['data'] ?? body);
  }

  Future<Map<String, dynamic>> saveName({
    required String setupToken,
    required String name,
    required String about,
  }) async {
    final res = await _api.postRequest(AppConstants.saveNameApi, {
      'name': name,
      'about': about,
    }, token: setupToken);
    if (res == null) throw ApiException('Server tak nahi pahunch sake');
    final body = _api.handleHttpResponse(res);
    return Map<String, dynamic>.from(body['data'] ?? body);
  }

  Future<Map<String, dynamic>> savePhoto({
    required String setupToken,
    required List<int> bytes,
  }) async {
    final png = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final file = http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: png ? 'profile.png' : 'profile.jpg',
    );
    final res = await _api.postMultipartRequest(
      AppConstants.savePhotoApi,
      fields: {},
      files: [file],
      token: setupToken,
    );
    if (res == null) throw ApiException('Photo upload nahi ho payi');
    final body = _api.handleHttpResponse(res);
    return Map<String, dynamic>.from(body['data'] ?? body);
  }

  Future<Map<String, dynamic>> skipPhoto(String setupToken) async {
    final res = await _api.postRequest(
      AppConstants.skipPhotoApi,
      {},
      token: setupToken,
    );
    if (res == null) throw ApiException('Server tak nahi pahunch sake');
    final body = _api.handleHttpResponse(res);
    return Map<String, dynamic>.from(body['data'] ?? body);
  }

  Future<void> logout() async {
    try {
      await _api.postRequest(AppConstants.logoutApi, {});
    } catch (_) {}
  }

  Future<void> sendSmsOtp({required String phone, required String otp}) async {
    if (otp.isEmpty) return;
    try {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final ten = clean.length >= 10
          ? clean.substring(clean.length - 10)
          : clean;
      final uri = Uri.parse(AppConstants.sendOtpUrl).replace(
        queryParameters: {
          'authkey': AppConstants.otpAuthKey,
          'mobile': ten,
          'country_code': '91',
          'sid': '15548',
          'otp': otp,
        },
      );
      await _api.getRequest(uri.toString(), sendToken: false);
    } catch (err) {
      _api._log('[SMS] Error sending OTP SMS: $err');
    }
  }

  // --- Chat APIs ---

  Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await _api.getRequest(AppConstants.chatConversations);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['conversations'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> openDirectChat(String userId) async {
    final res = await _api.postRequest(AppConstants.chatDirect, {
      'userId': userId,
    });
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['chat'] ?? {});
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 40,
    String? before,
  }) async {
    final query = {'limit': limit.toString()};
    if (before != null) query['before'] = before;
    final res = await _api.getRequest(
      AppConstants.chatMessagesApi(chatId),
      queryParams: query,
    );
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['messages'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> sendMessage(
    String chatId, {
    String? body,
    String kind = 'text',
    String? clientId,
    String? replyTo,
    Map<String, dynamic>? fileInfo,
  }) async {
    final payload = <String, dynamic>{'body': body, 'kind': kind};
    if (clientId != null) payload['clientId'] = clientId;
    if (replyTo != null) payload['replyTo'] = replyTo;
    if (fileInfo != null) payload['fileInfo'] = fileInfo;

    final res = await _api.postRequest(
      AppConstants.chatMessagesApi(chatId),
      payload,
    );
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['message'] ?? {});
    }
    return null;
  }

  Future<bool> markAsRead(String chatId) async {
    final res = await _api.postRequest(AppConstants.chatReadApi(chatId), {});
    return res != null && res.statusCode == 200;
  }

  Future<bool> editMessage(String messageId, String newBody) async {
    final res = await _api.putRequest(AppConstants.chatMessageApi(messageId), {
      'body': newBody,
    });
    return res != null && res.statusCode == 200;
  }

  Future<bool> deleteMessage(
    String messageId, {
    bool deleteForEveryone = false,
  }) async {
    final fullUrl = _api._resolveUrl(
      '${AppConstants.chatMessageApi(messageId)}?everyone=$deleteForEveryone',
    );
    final res = await _api.deleteRequest(fullUrl);
    return res != null && res.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getPeers() async {
    final res = await _api.getRequest(AppConstants.chatPeers);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['peers'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    final res = await _api.getRequest(AppConstants.chatUnreadCount);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['data']?['unreadCount'] as int? ?? 0;
    }
    return 0;
  }

  // --- Group APIs ---

  Future<Map<String, dynamic>?> createGroup({
    required String title,
    String? photoUrl,
    List<String> memberIds = const [],
  }) async {
    final payload = <String, dynamic>{'title': title, 'memberIds': memberIds};
    if (photoUrl != null) payload['photoUrl'] = photoUrl;
    final res = await _api.postRequest(AppConstants.groupApi, payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['group'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    final res = await _api.getRequest(AppConstants.groupDetailsApi(groupId));
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['group'] ?? {});
    }
    return null;
  }

  // --- Media Upload APIs ---

  Future<Map<String, dynamic>?> uploadMedia({
    required List<int> bytes,
    required String fileName,
    required String type,
    String? chatId,
    String? caption,
  }) async {
    final fields = <String, String>{};
    if (chatId != null) fields['chatId'] = chatId;
    if (caption != null) fields['caption'] = caption;
    final files = [
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    ];
    final res = await _api.postMultipartRequest(
      AppConstants.mediaTypeUploadApi(type),
      fields: fields,
      files: files,
    );
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  // --- Status APIs ---

  Future<Map<String, dynamic>?> createStatus({
    required String kind,
    String? mediaUrl,
    String? caption,
  }) async {
    final payload = <String, dynamic>{'kind': kind};
    if (mediaUrl != null) payload['mediaUrl'] = mediaUrl;
    if (caption != null) payload['caption'] = caption;
    final res = await _api.postRequest(AppConstants.statusApi, payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['status'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>> getStatusFeed() async {
    final res = await _api.getRequest(AppConstants.statusFeedApi);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return {};
  }

  Future<bool> viewStatus(String statusId) async {
    final res = await _api.postRequest(
      AppConstants.statusViewApi(statusId),
      {},
    );
    return res != null && res.statusCode == 200;
  }

  // --- User Block / Unblock APIs ---

  Future<bool> blockUser(String userId) async {
    final res = await _api.postRequest(AppConstants.userBlockApi, {
      'userId': userId,
    });
    return res != null && res.statusCode == 200;
  }

  Future<bool> unblockUser(String userId) async {
    final res = await _api.postRequest(AppConstants.userUnblockApi, {
      'userId': userId,
    });
    return res != null && res.statusCode == 200;
  }
}

// Typedef so legacy ChatApiService calls resolve to this unified singleton
typedef ChatApiService = ApiService;
