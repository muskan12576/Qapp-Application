import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Utills/app_constants.dart';

class ChatViewModel extends BaseViewModel {
  ChatViewModel._();
  static final ChatViewModel instance = ChatViewModel._();

  final ApiBaseService _api = ApiBaseService();

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
    final res = await _api.postRequest(AppConstants.chatDirect, {'userId': userId});
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
    bool forwarded = false,
  }) async {
    final payload = <String, dynamic>{
      'body': body,
      'kind': kind,
      'forwarded': forwarded,
    };
    if (clientId != null) payload['clientId'] = clientId;
    if (replyTo != null) payload['replyTo'] = replyTo;
    if (fileInfo != null) payload['fileInfo'] = fileInfo;

    final res = await _api.postRequest(AppConstants.chatMessagesApi(chatId), payload);
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
    final res = await _api.putRequest(AppConstants.chatMessageApi(messageId), {'body': newBody});
    return res != null && res.statusCode == 200;
  }

  Future<bool> deleteMessage(String messageId, {bool deleteForEveryone = false}) async {
    final fullUrl = _api.resolveUrl('${AppConstants.chatMessageApi(messageId)}?everyone=$deleteForEveryone');
    final res = await _api.deleteRequest(fullUrl);
    return res != null && res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> toggleReaction(String messageId, String reaction) async {
    final res = await _api.postRequest('/api/v1/chat/message/$messageId/reaction', {
      'reaction': reaction,
    });
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
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

  static MediaType resolveMediaType(String fileName, String defaultType) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'webm':
        return defaultType == 'video' ? MediaType('video', 'webm') : MediaType('audio', 'webm');
      case '3gp':
        return MediaType('video', '3gpp');
      case 'mkv':
        return MediaType('video', 'x-matroska');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'm4a':
        return MediaType('audio', 'mp4');
      case 'wav':
        return MediaType('audio', 'wav');
      case 'aac':
        return MediaType('audio', 'aac');
      case 'ogg':
        return MediaType('audio', 'ogg');
      case 'amr':
        return MediaType('audio', 'amr');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'txt':
        return MediaType('text', 'plain');
      case 'zip':
        return MediaType('application', 'zip');
      default:
        if (defaultType == 'image') return MediaType('image', 'jpeg');
        if (defaultType == 'video') return MediaType('video', 'mp4');
        if (defaultType == 'audio') return MediaType('audio', 'mp4');
        return MediaType('application', 'octet-stream');
    }
  }

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
    final contentType = resolveMediaType(fileName, type);
    final files = [
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: contentType,
      ),
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

  Future<bool> clearChat(String chatId) async {
    final res = await _api.deleteRequest('/api/v1/chat/$chatId/clear');
    return res != null && res.statusCode == 200;
  }

  Future<bool> updateWallpaper(String chatId, {String? wallpaperUrl, int? wallpaperColor}) async {
    final payload = <String, dynamic>{};
    if (wallpaperUrl != null) payload['wallpaperUrl'] = wallpaperUrl;
    if (wallpaperColor != null) payload['wallpaperColor'] = wallpaperColor;
    final res = await _api.putRequest('/api/v1/chat/$chatId/wallpaper', payload);
    return res != null && res.statusCode == 200;
  }

  Future<bool> blockUser(String userId) async {
    final res = await _api.postRequest(AppConstants.userBlockApi, {'userId': userId});
    return res != null && res.statusCode == 200;
  }

  Future<bool> unblockUser(String userId) async {
    final res = await _api.postRequest(AppConstants.userUnblockApi, {'userId': userId});
    return res != null && res.statusCode == 200;
  }

  Future<bool> reportAndBlockUser({
    required String targetUserId,
    String category = 'spam',
    required String reason,
    String? description,
    bool block = true,
  }) async {
    try {
      final res = await _api.postRequest(AppConstants.userReportApi, {
        'targetUserId': targetUserId,
        'category': category,
        'reason': reason,
        'description': description,
        'block': block,
      });
      return res != null && (res.statusCode == 200 || res.statusCode == 201);
    } catch (_) {
      return false;
    }
  }
}
