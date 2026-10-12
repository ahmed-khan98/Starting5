import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String loginKey = "is_logged_in";
  static const String userIdKey = "user_id"; 
  static const String _cookieKey = "session_cookie";
  static const String userNameKey = "user_name";
  static const String firstNameKey = "first_name";
  static const String lastNameKey = "last_name";
  static const String emailKey = "email"; 
  static const String fcmTokenKey = "fcm_token";

  /// Save Login
  static Future<void> setLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginKey, value);
  }

  /// Save User ID
  static Future<void> setUserId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, value);
  }

 /// Save FCM Token
  static Future<void> setFcmToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(fcmTokenKey, value);
  }

/// Get FCM Token
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(fcmTokenKey);
  }

 /// Save User Name
  static Future<void> setUserName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, value);
  }

/// Get User Name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(userNameKey);
  }

   /// Save User First Name
  static Future<void> setUserFirstName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(firstNameKey, value);
  }

/// Get User First Name
  static Future<String?> getUserFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(firstNameKey);
  }

  /// Save User Last Name
  static Future<void> setUserLastName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastNameKey, value);
  }

/// Get User Last Name
  static Future<String?> getUserLastName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(lastNameKey);
  }

  /// Save User Email
  static Future<void> setUserEmail(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, value);
  }

/// Get User Email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(emailKey);
  }

  /// Check Login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(loginKey) ?? false;
  }

  /// Get User ID 
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); 
    return prefs.getString(userIdKey);
  }

  /// Full Clear 
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  

  // Save the cookie string
  static Future<void> saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookie);
  }

  // Retrieve the cookie for API calls
  static Future<String?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  // Clear cookie on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }

}