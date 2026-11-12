// Backend is http://192.168.1.9:5000.
// Send OTP calls apitxt. Verify stays on this backend, which matches that OTP and returns the token.

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
  static const String baseUrl = "http://192.168.1.9:5000";

  static const String otpAuthKey =
      "fS8kKJICPakfP_wcelEJf7I5QfS2Q4RViwE7sEpRxGs";
  static const String sendOtpUrl = "https://apitxt.com/api/sendOTP";

  static const String verifyOtpApi = "/api/v1/login-mobile/verify-otp";
  static const String saveNameApi = "/api/v1/login-mobile/profile/name";
  static const String savePhotoApi = "/api/v1/login-mobile/profile/photo";
  static const String skipPhotoApi = "/api/v1/login-mobile/profile/skip-photo";
  static const String refreshTokenApi = "/api/v1/login-mobile/refresh";
  static const String logoutApi = "/api/v1/login-mobile/logout";
  static const String zegoTokenApi = "/api/v1/zego/token";
  static const String zegoPeersApi = "/api/v1/zego/peers";
  static const String zegoOpenApi = "/api/v1/zego/open";
}
