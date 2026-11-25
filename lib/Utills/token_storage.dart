import 'dart:convert';
import 'package:qapp/Services/firebase_notification_service.dart';
import 'package:qapp/Utills/app_utils.dart';
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
  String photoUrl = '';
  Map<String, dynamic> user = const {};

  String get userId => user['id']?.toString() ?? '';

  bool get isLoggedIn =>
      refreshToken.isNotEmpty || (token.isNotEmpty && tokenType == 'bearer');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(SharedPrefsConstants.authToken) ?? '';
    refreshToken = prefs.getString(SharedPrefsConstants.refreshToken) ?? '';
    tokenType = prefs.getString(SharedPrefsConstants.tokenType) ?? '';
    phone = prefs.getString(SharedPrefsConstants.userNumber) ?? '';
    name = prefs.getString(SharedPrefsConstants.userName) ?? '';
    about = prefs.getString(SharedPrefsConstants.userAbout) ?? '';
    photoUrl = prefs.getString('user_photo_url') ?? '';
    final raw = prefs.getString(SharedPrefsConstants.userJson);
    if (raw == null || raw.isEmpty) {
      user = const {};
      return;
    }
    final decoded = jsonDecode(raw);
    user = decoded is Map<String, dynamic> ? decoded : const {};
    if (user['name']?.toString().isNotEmpty == true) {
      name = user['name'].toString();
    }
    about = user['about']?.toString() ?? about;
    final uPhoto = user['profile_image_url']?.toString() ?? user['photoUrl']?.toString() ?? user['photo']?.toString();
    if (uPhoto != null && uPhoto.isNotEmpty) {
      photoUrl = uPhoto;
    }
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
    final uPhoto = user['profile_image_url']?.toString() ?? user['photoUrl']?.toString() ?? user['photo']?.toString();
    if (uPhoto != null && uPhoto.isNotEmpty) {
      photoUrl = uPhoto;
    }
    await prefs.setString(SharedPrefsConstants.authToken, token);
    await prefs.setString(SharedPrefsConstants.refreshToken, refreshToken);
    await prefs.setString(SharedPrefsConstants.tokenType, tokenType);
    await prefs.setString(SharedPrefsConstants.userNumber, this.phone);
    await prefs.setString(SharedPrefsConstants.userName, name);
    await prefs.setString(SharedPrefsConstants.userAbout, about);
    await prefs.setString('user_photo_url', photoUrl);
    await prefs.setString(SharedPrefsConstants.userJson, jsonEncode(user));
    debug('SESSION SAVED type=$tokenType');
    try {
      FirebaseNotificationService.instance.syncDeviceToken();
    } catch (_) {}
  }

  Future<void> updatePhotoUrl(String url) async {
    photoUrl = url;
    final map = Map<String, dynamic>.from(user);
    map['profile_image_url'] = url;
    user = map;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo_url', url);
    await prefs.setString(SharedPrefsConstants.userJson, jsonEncode(user));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    token = '';
    refreshToken = '';
    tokenType = '';
    phone = '';
    name = '';
    about = '';
    photoUrl = '';
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
