import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/Services/api_service.dart';

class ChatSocketService {
  ChatSocketService._() {
    ApiBaseService.onTokenRefreshed = () {
      debugPrint('⚡ [SOCKET] Token refreshed by API, reconnecting socket...');
      reconnect();
    };
  }
  static final ChatSocketService instance = ChatSocketService._();
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isRefreshingToken = false;
  DateTime? _lastRefreshAttempt;
  Timer? _reconnectDebounce;

  bool get isConnected => _isConnected;

  // Stream controllers for real-time events
  final _messageStream = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveredStream = StreamController<Map<String, dynamic>>.broadcast();
  final _readStream = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStream = StreamController<Map<String, dynamic>>.broadcast();
  final _stopTypingStream = StreamController<Map<String, dynamic>>.broadcast();
  final _userOnlineStream = StreamController<Map<String, dynamic>>.broadcast();
  final _userOfflineStream = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedStream =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageEditedStream =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReactionStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageStream.stream;
  Stream<Map<String, dynamic>> get onDelivered => _deliveredStream.stream;
  Stream<Map<String, dynamic>> get onRead => _readStream.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingStream.stream;
  Stream<Map<String, dynamic>> get onStopTyping => _stopTypingStream.stream;
  Stream<Map<String, dynamic>> get onUserOnline => _userOnlineStream.stream;
  Stream<Map<String, dynamic>> get onUserOffline => _userOfflineStream.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedStream.stream;
  Stream<Map<String, dynamic>> get onMessageEdited =>
      _messageEditedStream.stream;
  Stream<Map<String, dynamic>> get onMessageReaction =>
      _messageReactionStream.stream;

  Future<void> reconnect() async {
    _reconnectDebounce?.cancel();
    final completer = Completer<void>();
    _reconnectDebounce = Timer(const Duration(milliseconds: 300), () async {
      disconnect();
      await connect();
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (_socket != null && _isConnected) return;

    _isConnecting = true;
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚡ [SOCKET] Access token not found in storage');
        return;
      }

      disconnect();

      final options = io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableMultiplex()
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(3000)
          .setReconnectionAttempts(5)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .build();

      _socket = io.io(AppConstants.baseUrl, options);

      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        debugPrint(
          '⚡ [SOCKET] Connected successfully to: ${AppConstants.baseUrl}',
        );
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        _isConnecting = false;
        debugPrint('⚡ [SOCKET] Disconnected: $reason');
      });

      _socket!.onConnectError((err) async {
        _isConnected = false;
        _isConnecting = false;
        debugPrint('⚡ [SOCKET] Connect error: $err');

        final errStr = err.toString().toLowerCase();
        if (errStr.contains('invalid or expired token') ||
            errStr.contains('jwt expired') ||
            errStr.contains('authentication')) {
          _socket?.disconnect();

          final now = DateTime.now();
          if (_isRefreshingToken ||
              (_lastRefreshAttempt != null &&
                  now.difference(_lastRefreshAttempt!).inSeconds < 10)) {
            debugPrint(
              '⚡ [SOCKET] Refresh already running or in 10s cooldown, skipping.',
            );
            return;
          }

          _isRefreshingToken = true;
          _lastRefreshAttempt = now;
          debugPrint('⚡ [SOCKET] Token expired, requesting refresh...');
          try {
            await ApiBaseService().refreshAccess();
          } catch (e) {
            debugPrint('⚡ [SOCKET] Refresh token failed: $e');
            disconnect();
          } finally {
            _isRefreshingToken = false;
          }
        }
      });

      // Receive message
      _socket!.on('receive_message', (data) {
        debugPrint('⚡ [SOCKET RECV] receive_message: $data');
        if (data is Map) {
          _messageStream.add(Map<String, dynamic>.from(data));
        }
      });

      // Message sent ack
      _socket!.on('message_sent', (data) {
        debugPrint('⚡ [SOCKET RECV] message_sent (Ack): $data');
        if (data is Map && data['message'] is Map) {
          _messageStream.add(Map<String, dynamic>.from(data['message']));
        }
      });

      // Message delivered (Double tick)
      _socket!.on('message_delivered', (data) {
        debugPrint('⚡ [SOCKET RECV] message_delivered (Double Tick): $data');
        if (data is Map) {
          _deliveredStream.add(Map<String, dynamic>.from(data));
        }
      });

      // Message read (Blue double tick)
      _socket!.on('message_read', (data) {
        debugPrint('⚡ [SOCKET RECV] message_read (Blue Tick): $data');
        if (data is Map) {
          _readStream.add(Map<String, dynamic>.from(data));
        }
      });

      // Typing
      _socket!.on('typing', (data) {
        debugPrint('⚡ [SOCKET RECV] typing: $data');
        if (data is Map) {
          _typingStream.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('stop_typing', (data) {
        debugPrint('⚡ [SOCKET RECV] stop_typing: $data');
        if (data is Map) {
          _stopTypingStream.add(Map<String, dynamic>.from(data));
        }
      });

      // User online / offline
      _socket!.on('user_online', (data) {
        debugPrint('⚡ [SOCKET RECV] user_online: $data');
        if (data is Map) {
          _userOnlineStream.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('user_offline', (data) {
        debugPrint('⚡ [SOCKET RECV] user_offline: $data');
        if (data is Map) {
          _userOfflineStream.add(Map<String, dynamic>.from(data));
        }
      });

      // Message delete / edit
      _socket!.on('message_deleted', (data) {
        debugPrint('⚡ [SOCKET RECV] message_deleted: $data');
        if (data is Map) {
          _messageDeletedStream.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('message_edited', (data) {
        debugPrint('⚡ [SOCKET RECV] message_edited: $data');
        if (data is Map) {
          _messageEditedStream.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('message:reaction', (data) {
        debugPrint('⚡ [SOCKET RECV] message:reaction: $data');
        if (data is Map) {
          _messageReactionStream.add(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      debugPrint('⚡ [SOCKET] Error during connect: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void joinChat(String chatId) {
    debugPrint('⚡ [SOCKET EMIT] join: chatId=$chatId');
    _socket?.emit('join', {'chatId': chatId});
  }

  void sendMessage({
    required String chatId,
    String? recipientId,
    String? clientId,
    String kind = 'text',
    String body = '',
    String? replyTo,
    bool forwarded = false,
    Map<String, dynamic>? file,
  }) {
    final payload = <String, dynamic>{
      'chatId': chatId,
      'kind': kind,
      'body': body,
      'forwarded': forwarded,
    };
    if (recipientId != null) payload['recipientId'] = recipientId;
    if (clientId != null) payload['clientId'] = clientId;
    if (replyTo != null) payload['replyTo'] = replyTo;
    if (file != null) payload['file'] = file;

    debugPrint('⚡ [SOCKET EMIT] send_message: $payload');
    _socket?.emit('send_message', payload);
  }

  void markDelivered(String messageId, String chatId) {
    debugPrint('⚡ [SOCKET EMIT] message_delivered: messageId=$messageId');
    _socket?.emit('message_delivered', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  void markRead(String chatId, [List<String>? messageIds]) {
    final payload = <String, dynamic>{'chatId': chatId};
    if (messageIds != null) payload['messageIds'] = messageIds;
    debugPrint('⚡ [SOCKET EMIT] message_read: $payload');
    _socket?.emit('message_read', payload);
  }

  void sendTyping(String chatId, [String? recipientId]) {
    final payload = <String, dynamic>{'chatId': chatId};
    if (recipientId != null) payload['recipientId'] = recipientId;
    _socket?.emit('typing', payload);
  }

  void sendStopTyping(String chatId, [String? recipientId]) {
    final payload = <String, dynamic>{'chatId': chatId};
    if (recipientId != null) payload['recipientId'] = recipientId;
    _socket?.emit('stop_typing', payload);
  }

  void editMessage(String messageId, String chatId, String newBody) {
    debugPrint('⚡ [SOCKET EMIT] message_edited: messageId=$messageId');
    _socket?.emit('message_edited', {
      'messageId': messageId,
      'chatId': chatId,
      'newBody': newBody,
    });
  }

  void deleteMessage(
    String messageId,
    String chatId, {
    bool deleteForEveryone = false,
  }) {
    debugPrint('⚡ [SOCKET EMIT] message_deleted: messageId=$messageId');
    _socket?.emit('message_deleted', {
      'messageId': messageId,
      'chatId': chatId,
      'deleteForEveryone': deleteForEveryone,
    });
  }

  void disconnect() {
    _reconnectDebounce?.cancel();
    _isConnected = false;
    _isConnecting = false;
    if (_socket != null) {
      try {
        _socket?.disconnect();
        _socket?.dispose();
      } catch (_) {}
      _socket = null;
    }
  }
}
