import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';

class ConversationService {
  static Future<List<Map<String, dynamic>>> fetchConversations(int userId) async {
    final url = Uri.parse("${getServerBase()}/routes/conversations/$userId");
    print("🔍 Fetching conversations from: $url");
    try {
      final res = await http.get(url);
      print("📡 Response status: ${res.statusCode}");
      print("📡 Response body: ${res.body}");
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(res.body);
        final convs = data is Map<String, dynamic> ? data['conversations'] : null;
        if (convs is List) {
          print("✅ Found ${convs.length} conversations");
          return convs.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      print("❌ Error fetching conversations: $e");
    }
    return [];
  }

  // Tạo nhóm: cần token
  static Future<Map<String, dynamic>?> createGroup({
    required String name,
    required List<int> participants,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("${getServerBase()}/routes/conversations/group");
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'participants': participants}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['ok'] == true) return Map<String, dynamic>.from(data['conversation'] as Map);
    }
    return null;
  }

  // Đổi tên nhóm
  static Future<Map<String, dynamic>?> renameGroup({
    required String conversationId,
    required String name,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("${getServerBase()}/routes/conversations/$conversationId");
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['ok'] == true && data['conversation'] is Map) {
          return Map<String, dynamic>.from(data['conversation'] as Map);
        }
      } catch (e) {
        print('❌ renameGroup JSON parse error: $e');
      }
    } else {
      print('❌ renameGroup failed: ${res.statusCode} ${res.body}');
    }
    return null;
  }
}