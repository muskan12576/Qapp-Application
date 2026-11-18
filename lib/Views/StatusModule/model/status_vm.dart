import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Views/ChatModule/model/chat_vm.dart';

class StatusViewModel extends BaseViewModel {
  StatusViewModel._();
  static final StatusViewModel instance = StatusViewModel._();

  final ApiBaseService _api = ApiBaseService();

  List<Map<String, dynamic>> otherStatuses = [];
  Map<String, dynamic>? myStatus;

  Future<Map<String, dynamic>?> createStatus({
    required String kind,
    String? mediaUrl,
    String? youtubeVideoId,
    String? sourceUrl,
    String? caption,
    String? platform,
    String? embedUrl,
    String? thumbnailUrl,
    String? playbackType,
    String? title,
    String? originalUrl,
  }) async {
    final payload = <String, dynamic>{'kind': kind};
    if (mediaUrl != null) payload['mediaUrl'] = mediaUrl;
    if (youtubeVideoId != null) payload['youtubeVideoId'] = youtubeVideoId;
    if (sourceUrl != null) payload['sourceUrl'] = sourceUrl;
    if (caption != null) payload['caption'] = caption;
    if (platform != null) payload['platform'] = platform;
    if (embedUrl != null) payload['embedUrl'] = embedUrl;
    if (thumbnailUrl != null) payload['thumbnailUrl'] = thumbnailUrl;
    if (playbackType != null) payload['playbackType'] = playbackType;
    if (title != null) payload['title'] = title;
    if (originalUrl != null) payload['originalUrl'] = originalUrl;

    final res = await _api.postRequest(AppConstants.statusApi, payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data']?['status'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>?> uploadStatusMedia({
    required Uint8List bytes,
    required String fileName,
    String type = 'image',
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.mediaTypeUploadApi(type)}',
      );
      final headers = await _api.getMultipartHeaders();
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: ChatViewModel.resolveMediaType(fileName, type),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        return Map<String, dynamic>.from(json['data'] ?? {});
      }
    } catch (e) {
      debugPrint('Status upload media error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> previewLink(String url) async {
    final res = await _api.postRequest(AppConstants.statusPreviewLinkApi, {
      'url': url,
    });
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'];
      if (data is Map) {
        final preview = data['preview'];
        if (preview is Map) {
          final resMap = Map<String, dynamic>.from(preview);
          if (data['embedUrl'] != null) resMap['embedUrl'] ??= data['embedUrl'];
          if (data['platform'] != null) resMap['platform'] ??= data['platform'];
          if (data['playbackType'] != null) resMap['playbackType'] ??= data['playbackType'];
          return resMap;
        }
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> getStatusFeed() async {
    final res = await _api.getRequest(AppConstants.statusFeedApi);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = Map<String, dynamic>.from(json['data'] ?? {});
      final others = data['others'] as List? ?? [];
      otherStatuses = others.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (data['myStatus'] is Map) {
        myStatus = Map<String, dynamic>.from(data['myStatus'] as Map);
      }
      notifyListeners();
      return data;
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> getMyStatuses() async {
    final res = await _api.getRequest(AppConstants.statusMyApi);
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['statuses'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<bool> viewStatus(String statusId) async {
    final res = await _api.postRequest(
      AppConstants.statusViewApi(statusId),
      {},
    );
    return res != null && res.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getStatusViewers(String statusId) async {
    final res = await _api.getRequest(AppConstants.statusViewersApi(statusId));
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['viewers'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<bool> deleteStatus(String statusId) async {
    final res = await _api.deleteRequest(
      AppConstants.statusDeleteApi(statusId),
    );
    return res != null && res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> toggleLike(String statusId) async {
    final res = await _api.postRequest('/api/v1/status/$statusId/like', {});
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  Future<bool> replyToStatus({
    required String recipientId,
    required String replyText,
    String? statusCaption,
    String? mediaUrl,
  }) async {
    final direct = await ChatViewModel.instance.openDirectChat(recipientId);
    if (direct != null && direct['id'] != null) {
      final chatId = direct['id'].toString();
      final body = statusCaption != null && statusCaption.isNotEmpty
          ? 'Story reply to "$statusCaption":\n$replyText'
          : 'Story reply:\n$replyText';
      final sent = await ChatViewModel.instance.sendMessage(
        chatId,
        body: body,
        kind: 'text',
      );
      return sent != null;
    }
    return false;
  }
}
