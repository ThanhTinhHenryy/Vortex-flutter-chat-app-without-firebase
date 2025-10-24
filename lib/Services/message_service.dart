import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';

class MessageService {
  static Future<List<Map<String, dynamic>>> fetchMessages(int sourceId, int targetId) async {
    final uri = Uri.parse('${getServerBase()}/routes/messages/$sourceId/$targetId');
    // Debug: log URL and status
    // ignore: avoid_print
    print('🔎 GET messages: $uri');
    final res = await http.get(uri);
    // ignore: avoid_print
    print('📡 messages status: ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) return [];
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // ignore: avoid_print
      print('❌ Invalid JSON for messages');
      return [];
    }
    final arr = (data['messages'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // ignore: avoid_print
    print('✅ messages fetched: ${arr.length}');
    return arr;
  }

  static String summarize(Map<String, dynamic> m) {
    final path = (m['path'] ?? '') as String;
    final msg = (m['message'] ?? '') as String;
    if (path.isNotEmpty && msg.isEmpty) return '[Ảnh]';
    if (msg.isNotEmpty) return msg;
    return path.isNotEmpty ? '[Ảnh]' : '';
  }
}