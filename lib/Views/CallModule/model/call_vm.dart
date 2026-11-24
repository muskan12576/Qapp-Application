import 'dart:convert';
import 'package:qapp/Model/base_view_model.dart';
import 'package:qapp/Services/api_service.dart';

class CallViewModel extends BaseViewModel {
  CallViewModel._();
  static final CallViewModel instance = CallViewModel._();

  final ApiBaseService _api = ApiBaseService();

  Future<Map<String, dynamic>?> initiateVoiceCall({
    required String recipientId,
    String? chatId,
  }) async {
    final payload = {'recipientId': recipientId};
    if (chatId != null) payload['chatId'] = chatId;
    final res = await _api.postRequest('/api/v1/voice-call/initiate', payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>?> initiateVideoCall({
    required String recipientId,
    String? chatId,
  }) async {
    final payload = {'recipientId': recipientId};
    if (chatId != null) payload['chatId'] = chatId;
    final res = await _api.postRequest('/api/v1/video-call/initiate', payload);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>?> getVoiceToken(String roomId) async {
    final res = await _api.postRequest('/api/v1/voice-call/token', {'roomId': roomId});
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  Future<Map<String, dynamic>?> getVideoToken(String roomId) async {
    final res = await _api.postRequest('/api/v1/video-call/token', {'roomId': roomId});
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Map<String, dynamic>.from(json['data'] ?? {});
    }
    return null;
  }

  Future<bool> endVoiceCall({required String callId, int durationSec = 0}) async {
    final res = await _api.postRequest('/api/v1/voice-call/end', {
      'callId': callId,
      'durationSec': durationSec,
    });
    return res != null && res.statusCode == 200;
  }

  Future<bool> endVideoCall({required String callId, int durationSec = 0}) async {
    final res = await _api.postRequest('/api/v1/video-call/end', {
      'callId': callId,
      'durationSec': durationSec,
    });
    return res != null && res.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getCallHistory() async {
    final res = await _api.getRequest('/api/v1/voice-call/history');
    if (res != null && res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data']?['calls'];
      if (list is List) {
        return list.map((c) => Map<String, dynamic>.from(c as Map)).toList();
      }
    }
    return [];
  }
}
