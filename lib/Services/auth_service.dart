import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'server_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userNameKey = 'auth_user_name';

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final uri = Uri.parse('${getServerBase()}/routes/auth/register');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['ok'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setInt(_userIdKey, (data['user'] as Map<String, dynamic>)['userId'] as int);
      await prefs.setString(_userNameKey, (data['user'] as Map<String, dynamic>)['name'] as String? ?? '');
      return data;
    }
    throw Exception(data['error'] ?? 'Register failed');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${getServerBase()}/routes/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['ok'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setInt(_userIdKey, (data['user'] as Map<String, dynamic>)['userId'] as int);
      await prefs.setString(_userNameKey, (data['user'] as Map<String, dynamic>)['name'] as String? ?? '');
      return data;
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    try {
      final uri = Uri.parse('${getServerBase()}/routes/auth/logout');
      await http.post(uri, headers: {'Content-Type': 'application/json'});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }
}