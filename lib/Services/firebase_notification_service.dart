import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Services/call_manager_service.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/data/demo_data.dart';
import 'package:qapp/main.dart';
import 'package:qapp/Views/ChatModule/chat_open_screen.dart';
import 'package:qapp/theme/q_route.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('⚡ [FCM BG] Message received: ${message.messageId} - ${message.notification?.title}');
}

class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'qapp_high_importance_channel',
    'Qapp Notifications',
    description: 'Messages, voice and video call alerts for Qapp',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('⚠️ [FCM] Firebase.initializeApp() error: $e');
      return;
    }

    // Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    await _requestPermissions();

    // Setup local notifications
    await _setupLocalNotifications();

    // Sync device token
    await syncDeviceToken();

    // Listen for refreshed token
    // ignore: deprecated_member_use
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('⚡ [FCM] Token refreshed: $newToken');
      syncDeviceToken(explicitToken: newToken);
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('⚡ [FCM FG] Foreground message received: ${message.notification?.title}');
      final data = message.data;
      final type = data['type']?.toString();
      if (type == 'call' || type == 'video_call' || type == 'incoming_call') {
        CallManagerService.instance.handleIncomingCall({
          'callId': data['callId'],
          'roomId': data['roomId'] ?? data['callId'],
          'kind': type == 'video_call' ? 'video' : 'voice',
          'callerId': data['callerId'] ?? data['senderId'],
          'callerName': data['callerName'] ?? message.notification?.title ?? 'Caller',
          'callerPhoto': data['callerPhoto'],
          'token': data['token'],
        });
      }
      _showLocalNotification(message);
    });

    // Handle notification tap when app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('⚡ [FCM OPEN] App opened from notification: ${message.data}');
      _handleNotificationClick(message.data);
    });

    // Handle notification click if app was launched from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('⚡ [FCM] Authorization status: ${settings.authorizationStatus}');

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('⚠️ [FCM] Permission request error: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationClick(data);
          } catch (_) {}
        }
      },
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }
  }

  Future<void> syncDeviceToken({String? explicitToken}) async {
    try {
      // ignore: deprecated_member_use
      final token = explicitToken ?? await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      debugPrint('⚡ [FCM] Device Token: $token');

      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        // Will be synced once user logs in
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      await ApiBaseService().postRequest(
        AppConstants.deviceTokenApi,
        {
          'token': token,
          'platform': platform,
        },
      );
      debugPrint('📲 [FCM] Device token registered successfully with backend!');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error syncing device token: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type']?.toString() ?? 'chat_message';
    final isCall = type == 'call' || type == 'video_call' || type == 'incoming_call';

    // Check if user disabled notifications in profile settings (calls bypass mute)
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('app_notifications_enabled') ?? true;
      if (!enabled && !isCall) {
        debugPrint('🔇 [FCM] Notification suppressed by user app settings');
        return;
      }

      final chatId = data['chatId']?.toString();
      final senderId = data['senderId']?.toString();

      final blockedList = prefs.getStringList('qapp_blocked_users') ?? [];
      if ((chatId != null && blockedList.contains(chatId)) ||
          (senderId != null && blockedList.contains(senderId))) {
        debugPrint('🚫 [FCM] Notification suppressed because user is blocked in prefs');
        return;
      }

      final mutedList = prefs.getStringList('qapp_muted_threads') ?? [];
      if (!isCall && ((chatId != null && mutedList.contains(chatId)) ||
          (senderId != null && mutedList.contains(senderId)))) {
        debugPrint('🔇 [FCM] Notification suppressed because chat thread is muted in prefs');
        return;
      }
    } catch (_) {}

    final notification = message.notification;

    final chatId = data['chatId']?.toString();
    final senderId = data['senderId']?.toString();

    // Suppress notification if user is actively in this chat screen
    if (ChatOpenScreen.activeChatId != null &&
        (ChatOpenScreen.activeChatId == chatId || ChatOpenScreen.activeChatId == senderId)) {
      debugPrint('🔇 [FCM] Notification suppressed because user is currently inside this chat');
      return;
    }

    // Suppress notification if thread is blocked or muted
    if (chatId != null || senderId != null) {
      final isBlockedOrMuted = ChatBook.instance.threads.any((t) =>
          ((chatId != null && t.chatId == chatId) ||
           (senderId != null && t.peerId == senderId)) &&
          (t.blocked || t.blockedByPeer || (!isCall && t.muted)));
      if (isBlockedOrMuted) {
        debugPrint('🚫 [FCM] Notification suppressed because chat thread is blocked or muted');
        return;
      }
    }

    final title = notification?.title ?? data['senderName'] ?? 'Qapp';
    String body = notification?.body ?? data['body'] ?? 'New message';

    final kind = data['kind']?.toString() ?? 'text';

    if (type == 'call') {
      body = '📞 Incoming voice call...';
    } else if (type == 'video_call') {
      body = '📹 Incoming video call...';
    } else if (type == 'status_like') {
      body = notification?.body ?? data['body'] ?? 'Liked your status ❤️';
    } else if (type == 'message_reaction') {
      body = notification?.body ?? data['body'] ?? 'Reacted to your message';
    } else if (kind == 'image') {
      body = '📷 Photo';
    } else if (kind == 'video') {
      body = '🎥 Video';
    } else if (kind == 'audio') {
      body = '🎵 Voice message';
    } else if (kind == 'pdf' || kind == 'doc') {
      body = '📄 Document';
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _local.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  Future<void> showNotificationFromData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('app_notifications_enabled') ?? true;
      if (!enabled) return;

      final chatId = data['chatId']?.toString();
      final senderId = data['senderId']?.toString();

      // Suppress notification if user is actively in this chat screen
      if (ChatOpenScreen.activeChatId != null &&
          (ChatOpenScreen.activeChatId == chatId || ChatOpenScreen.activeChatId == senderId)) {
        return;
      }

      final blockedList = prefs.getStringList('qapp_blocked_users') ?? [];
      if ((chatId != null && blockedList.contains(chatId)) ||
          (senderId != null && blockedList.contains(senderId))) {
        return;
      }

      if (chatId != null || senderId != null) {
        final isBlocked = ChatBook.instance.threads.any((t) =>
            ((chatId != null && t.chatId == chatId) ||
             (senderId != null && t.peerId == senderId)) &&
            (t.blocked || t.blockedByPeer));
        if (isBlocked) return;
      }

      final mutedList = prefs.getStringList('qapp_muted_threads') ?? [];
      if ((chatId != null && mutedList.contains(chatId)) ||
          (senderId != null && mutedList.contains(senderId))) {
        return;
      }

      final title = data['title']?.toString() ?? data['senderName']?.toString() ?? 'Qapp';
      final body = data['body']?.toString() ?? 'New notification';

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _local.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(data),
      );
    } catch (_) {}
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('⚡ [FCM CLICK] Navigating for data: $data');
    final type = data['type']?.toString();
    if (type == 'call' || type == 'video_call' || type == 'incoming_call') {
      CallManagerService.instance.handleIncomingCall({
        'callId': data['callId'],
        'roomId': data['roomId'] ?? data['callId'],
        'kind': type == 'video_call' ? 'video' : 'voice',
        'callerId': data['callerId'] ?? data['senderId'],
        'callerName': data['callerName'] ?? data['title'] ?? 'Caller',
        'callerPhoto': data['callerPhoto'],
        'token': data['token'],
      });
      return;
    }

    final chatId = data['chatId']?.toString();
    final senderId = data['senderId']?.toString();
    final senderName = data['senderName']?.toString() ?? data['title']?.toString() ?? 'Chat';

    if (chatId == null && senderId == null) return;

    ChatThread? found;
    for (final t in ChatBook.instance.threads) {
      if ((chatId != null && t.chatId == chatId) ||
          (senderId != null && t.peerId == senderId)) {
        found = t;
        break;
      }
    }

    final thread = found ??
        ChatThread(
          chatId: chatId,
          peerId: senderId,
          name: senderName,
          header: senderName,
          time: '',
          preview: '',
          colorIndex: 2,
          phone: '',
          about: '',
          messages: [],
        );

    GlobalVariable.navState.currentState?.push(qRoute(ChatOpenScreen(thread: thread)));
  }
}
