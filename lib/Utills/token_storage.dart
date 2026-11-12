import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  String token = '';
  String refreshToken = '';
  String tokenType = '';
  String phone = '';
  String name = '';
  String about = '';
  Map<String, dynamic> user = const {};

  bool get isLoggedIn => refreshToken.isNotEmpty || (token.isNotEmpty && tokenType == 'bearer');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(SharedPrefsConstants.authToken) ?? '';
    refreshToken = prefs.getString(SharedPrefsConstants.refreshToken) ?? '';
    tokenType = prefs.getString(SharedPrefsConstants.tokenType) ?? '';
    phone = prefs.getString(SharedPrefsConstants.userNumber) ?? '';
    name = prefs.getString(SharedPrefsConstants.userName) ?? '';
    about = prefs.getString(SharedPrefsConstants.userAbout) ?? '';
    final raw = prefs.getString(SharedPrefsConstants.userJson);
    if (raw == null || raw.isEmpty) {
      user = const {};
      return;
    }
    final decoded = jsonDecode(raw);
    user = decoded is Map<String, dynamic> ? decoded : const {};
    if (user['name']?.toString().isNotEmpty == true) name = user['name'].toString();
    about = user['about']?.toString() ?? about;
  }

  Future<void> saveLogin(Map<String, dynamic> data, {String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    final nextToken = data['token']?.toString() ?? '';
    if (nextToken.isNotEmpty) token = nextToken;
    final nextRefresh = data['refresh_token']?.toString() ?? '';
    if (nextRefresh.isNotEmpty) refreshToken = nextRefresh;
    final nextType = data['token_type']?.toString() ?? '';
    if (nextType.isNotEmpty) tokenType = nextType;
    final nextUser = data['user'];
    if (nextUser is Map<String, dynamic>) user = nextUser;
    if (phone != null && phone.isNotEmpty) this.phone = phone;
    name = user['name']?.toString() ?? name;
    about = user['about']?.toString() ?? about;
    await prefs.setString(SharedPrefsConstants.authToken, token);
    await prefs.setString(SharedPrefsConstants.refreshToken, refreshToken);
    await prefs.setString(SharedPrefsConstants.tokenType, tokenType);
    await prefs.setString(SharedPrefsConstants.userNumber, this.phone);
    await prefs.setString(SharedPrefsConstants.userName, name);
    await prefs.setString(SharedPrefsConstants.userAbout, about);
    await prefs.setString(SharedPrefsConstants.userJson, jsonEncode(user));
    debugPrint('\x1b[32mSESSION SAVED\x1b[0m type=$tokenType');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    token = '';
    refreshToken = '';
    tokenType = '';
    phone = '';
    name = '';
    about = '';
    user = const {};
    await prefs.clear();
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPrefsConstants.authToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPrefsConstants.refreshToken);
  }

  static Future<void> clearTokens() => instance.clear();
}
