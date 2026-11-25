// Backend is http://192.168.6.56:5000.
// All API endpoints are centralized here.

class SharedPrefsConstants {
  static const String authToken = "qapp_access_token";
  static const String refreshToken = "qapp_refresh_token";
  static const String tokenType = "qapp_token_type";
  static const String userNumber = "qapp_phone";
  static const String userJson = "qapp_user_json";
  static const String userName = "qapp_name";
  static const String userAbout = "qapp_about";
}

class AppConstants {
  // static const String baseUrl = "http://192.168.1.4:5000";
  static const String baseUrl =
      "https://overcoat-effects-yippee.ngrok-free.dev";

  // SMS OTP Provider
  static const String otpAuthKey =
      "fS8kKJICPakfP_wcelEJf7I5QfS2Q4RViwE7sEpRxGs";
  static const String sendOtpUrl = "https://apitxt.com/api/sendOTP";

  // Auth APIs
  static const String sendPhoneApi = "/api/v1/login-mobile/phone";
  static const String verifyOtpApi = "/api/v1/login-mobile/verify-otp";
  static const String saveNameApi = "/api/v1/login-mobile/profile/name";
  static const String savePhotoApi = "/api/v1/login-mobile/profile/photo";
  static const String skipPhotoApi = "/api/v1/login-mobile/profile/skip-photo";
  static const String refreshTokenApi = "/api/v1/login-mobile/refresh";
  static const String logoutApi = "/api/v1/login-mobile/logout";

  // Chat & Conversation APIs
  static const String chatConversations = "/api/v1/chat/conversations";
  static const String chatDirect = "/api/v1/chat/direct";
  static const String chatPeers = "/api/v1/chat/peers";
  static const String chatUnreadCount = "/api/v1/chat/unread-count";

  // Group APIs
  static const String groupApi = "/api/v1/group";

  // Media APIs
  static const String mediaUploadApi = "/api/v1/media";

  // Status (Stories) APIs
  static const String statusApi = "/api/v1/status";
  static const String statusFeedApi = "/api/v1/status/feed";
  static const String statusMyApi = "/api/v1/status/my";
  static const String statusPreviewLinkApi = "/api/v1/status/preview-link";

  // User Block / Unblock & Report APIs
  static const String updateUserPhotoApi = "/api/v1/user/me/photo";
  static const String userBlockApi = "/api/v1/user/block";
  static const String userUnblockApi = "/api/v1/user/unblock";
  static const String userReportApi = "/api/v1/user/report";
  static const String errorReportApi = "/api/v1/error-report";
  static const String deviceTokenApi = "/api/v1/user/device-token";

  // Dynamic endpoint builders
  static String chatMessagesApi(String chatId) =>
      "/api/v1/chat/$chatId/messages";
  static String chatReadApi(String chatId) => "/api/v1/chat/$chatId/read";
  static String chatMessageApi(String messageId) =>
      "/api/v1/chat/message/$messageId";
  static String groupDetailsApi(String groupId) => "/api/v1/group/$groupId";
  static String groupMembersApi(String groupId) =>
      "/api/v1/group/$groupId/members";
  static String groupLeaveApi(String groupId) => "/api/v1/group/$groupId/leave";
  static String groupAdminApi(String groupId) => "/api/v1/group/$groupId/admin";
  static String statusViewApi(String statusId) =>
      "/api/v1/status/$statusId/view";
  static String statusViewersApi(String statusId) =>
      "/api/v1/status/$statusId/viewers";
  static String statusDeleteApi(String statusId) => "/api/v1/status/$statusId";
  static String mediaTypeUploadApi(String type) => "/api/v1/media/$type";
}
