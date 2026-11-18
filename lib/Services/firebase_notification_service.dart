import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qapp/Services/api_service.dart';
import 'package:qapp/Utills/app_constants.dart';
import 'package:qapp/Utills/token_storage.dart';
import 'package:qapp/data/demo_data.dart';

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

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final chatId = data['chatId']?.toString();
    final senderId = data['senderId']?.toString();

    // Suppress notification if thread is muted
    if (chatId != null || senderId != null) {
      final isMuted = ChatBook.instance.threads.any((t) =>
          ((chatId != null && t.chatId == chatId) ||
           (senderId != null && t.peerId == senderId)) &&
          t.muted);
      if (isMuted) {
        debugPrint('🔇 [FCM] Notification suppressed because chat thread is muted');
        return;
      }
    }

    final title = notification?.title ?? data['senderName'] ?? 'Qapp';
    String body = notification?.body ?? data['body'] ?? 'New message';

    final kind = data['kind']?.toString() ?? 'text';
    final type = data['type']?.toString() ?? 'chat_message';

    if (type == 'call') {
      body = '📞 Incoming voice call...';
    } else if (type == 'video_call') {
      body = '📹 Incoming video call...';
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

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('⚡ [FCM CLICK] Navigating for data: $data');
    // Global navigation can be triggered when user clicks notification
  }
}
