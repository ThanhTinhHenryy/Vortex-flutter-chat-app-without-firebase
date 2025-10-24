import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';
import 'auth_service.dart';

class UserService {
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final myId = await AuthService.getUserId();
    final uri = Uri.parse(
      '${getServerBase()}/routes/users/search?q=${Uri.encodeQueryComponent(query)}&excludeId=${myId ?? 0}',
    );
    final res = await http.get(uri);

    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }
    if (!contentType.contains('application/json')) {
      throw const FormatException('Unexpected non-JSON response from server');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      final preview = res.body.length > 120
          ? res.body.substring(0, 120)
          : res.body;
      throw FormatException('Invalid JSON response: $preview');
    }

    if (data['ok'] == true) {
      final arr = (data['users'] as List<dynamic>).cast<Map<String, dynamic>>();
      return arr;
    }
    throw Exception(data['error'] ?? 'Search failed');
  }

  // New: fetch single user by ID
  static Future<Map<String, dynamic>?> getById(int userId) async {
    final uri = Uri.parse('${getServerBase()}/routes/users/by-id/$userId');
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] == true) {
      return (data['user'] as Map<String, dynamic>);
    }
    return null;
  }
}