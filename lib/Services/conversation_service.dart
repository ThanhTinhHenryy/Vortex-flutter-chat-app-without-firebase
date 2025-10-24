import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app_flutter/Services/server_config.dart';

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
}