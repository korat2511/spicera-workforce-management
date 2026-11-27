import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthController extends ValueNotifier<String?> {
  AuthController() : super(null);

  static const String _prefsKey = 'auth_token';

  bool get isLoggedIn => value != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsKey);
    ApiClient.setAuthToken(token);
    value = token;
  }

  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, token);
    ApiClient.setAuthToken(token);
    value = token;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    ApiClient.setAuthToken(null);
    value = null;
  }
}

final authController = AuthController();
