import 'dart:convert';
import 'dart:typed_data';
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

  // New: upload avatar from local path; return filename
  static Future<String?> uploadAvatarFromPath(String filePath) async {
    final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('img', filePath));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final path = (data['path'] as String?) ?? '';
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  static Future<String?> uploadAvatarFromBytes(Uint8List bytes, {String filename = 'upload.jpg'}) async {
    final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(http.MultipartFile.fromBytes('img', bytes, filename: filename));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final path = (data['path'] as String?) ?? '';
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  // New: update profile; optional fields
  static Future<Map<String, dynamic>?> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? avatar,
    String? password,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${getServerBase()}/routes/users/$userId');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatar != null) body['avatar'] = avatar;
    if (password != null) body['password'] = password;
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['ok'] == true) return (data['user'] as Map<String, dynamic>);
    }
    return null;
  }
}