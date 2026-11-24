import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:qapp/Services/api_service.dart';

class AiVoiceCommandResponse {
  final String intent;
  final Map<String, dynamic>? recipient;
  final List<dynamic>? recipients;
  final Map<String, dynamic>? group;
  final String? messageBody;
  final String callType;
  final bool requiresConfirmation;
  final String responsePrompt;
  final bool isDuplicate;
  final List<dynamic>? duplicateContacts;
  final bool keepListening;
  final bool isClosing;
  final Map<String, dynamic>? context;

  AiVoiceCommandResponse({
    required this.intent,
    this.recipient,
    this.recipients,
    this.group,
    this.messageBody,
    this.callType = 'voice',
    this.requiresConfirmation = false,
    this.responsePrompt = '',
    this.isDuplicate = false,
    this.duplicateContacts,
    this.keepListening = true,
    this.isClosing = false,
    this.context,
  });

  factory AiVoiceCommandResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    return AiVoiceCommandResponse(
      intent: data['intent']?.toString() ?? 'UNKNOWN',
      recipient: data['recipient'] is Map ? Map<String, dynamic>.from(data['recipient']) : null,
      recipients: data['recipients'] as List?,
      group: data['group'] is Map ? Map<String, dynamic>.from(data['group']) : null,
      messageBody: data['messageBody']?.toString(),
      callType: data['callType']?.toString() ?? 'voice',
      requiresConfirmation: data['requiresConfirmation'] == true,
      responsePrompt: data['responsePrompt']?.toString() ?? '',
      isDuplicate: data['isDuplicate'] == true,
      duplicateContacts: data['contacts'] as List?,
      keepListening: data['keepListening'] != false,
      isClosing: data['isClosing'] == true,
      context: data['context'] is Map ? Map<String, dynamic>.from(data['context']) : null,
    );
  }
}

class AiAssistantService {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();
  final ApiBaseService _api = ApiBaseService();

  /// Send voice command to backend with conversational multi-turn context
  Future<AiVoiceCommandResponse?> sendVoiceCommand(
    String command, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final payload = <String, dynamic>{
        'command': command,
      };
      if (context != null) payload['context'] = context;

      final res = await _api.postRequest('/api/v1/ai/voice-command', payload);

      if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        return AiVoiceCommandResponse.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ [AI SERVICE] Error in sendVoiceCommand: $e');
    }
    return null;
  }

  /// Execute the confirmed action (e.g. Share Location or Send Message)
  Future<Map<String, dynamic>?> executeAction({
    required String intent,
    String? recipientId,
    String? chatId,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? messageBody,
  }) async {
    try {
      final payload = <String, dynamic>{
        'intent': intent,
      };
      if (recipientId != null) payload['recipientId'] = recipientId;
      if (chatId != null) payload['chatId'] = chatId;
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;
      if (mapsUrl != null) payload['mapsUrl'] = mapsUrl;
      if (messageBody != null) payload['messageBody'] = messageBody;

      final res = await _api.postRequest('/api/v1/ai/execute-action', payload);

      if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        return json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
      }
    } catch (e) {
      debugPrint('⚠️ [AI SERVICE] Error in executeAction: $e');
    }
    return null;
  }
}
