import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyServerUrl = 'server_base_url';
  static const String _keyAuthToken = 'api_auth_token';

  // Varsayılan sunucu adresi (konyadinamik.com.tr Canlı Sunucu)
  static String get defaultBaseUrl {
    return 'https://konyadinamik.com.tr/klasorum';
  }

  static const String defaultAuthToken = 'klasorum-super-secret-token-change-in-production';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? defaultBaseUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  static Future<String> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken) ?? defaultAuthToken;
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token.trim());
  }
}
