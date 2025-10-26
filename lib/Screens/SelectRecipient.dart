import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Services/conversation_service.dart';
import 'package:chat_app_flutter/Services/socket_service.dart';

class SelectRecipientScreen extends StatefulWidget {
  const SelectRecipientScreen({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  State<SelectRecipientScreen> createState() => _SelectRecipientScreenState();
}

class _SelectRecipientScreenState extends State<SelectRecipientScreen> {
  int? _myId;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _directUsers = []; // danh sách 1-1 từ hội thoại
  bool _loadingConversations = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = await AuthService.getUserId();
    if (_myId != null) await SocketService.instance.signin(_myId!);
    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loadingConversations = true);
    try {
      final convs = await ConversationService.fetchConversations(_myId ?? 0);
      // Nhóm: có isGroup === true
      _groups = convs.where((c) => c['isGroup'] == true).toList();
      // 1-1: không phải nhóm, lấy userId còn lại
      final dms = convs.where((c) => c['isGroup'] != true).toList();
      final List<Map<String, dynamic>> users = [];
      for (final c in dms) {
        final partsRaw = (c['participants'] as List<dynamic>? ?? []);
        final parts = partsRaw
            .map((e) {
              if (e is num) return e.toInt();
              if (e is String) return int.tryParse(e) ?? 0;
              return 0;
            })
            .where((v) => v > 0)
            .toList();
        if (parts.length == 2 && _myId != null) {
          final other = parts.firstWhere((id) => id != _myId, orElse: () => parts[0]);
          users.add({'userId': other, 'name': 'User $other'});
          // Load tên hiển thị thật (nếu có)
          try {
            final profile = await UserService.getById(other);
            if (profile != null) {
              final idx = users.indexWhere((u) => u['userId'] == other);
              if (idx >= 0) users[idx] = {...users[idx], 'name': (profile['name'] ?? users[idx]['name'])};
            }
          } catch (_) {}
        }
      }
      _directUsers = users;
    } catch (_) {}
    setState(() => _loadingConversations = false);
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _users = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final arr = await UserService.searchUsers(q.trim());
      setState(() => _users = arr);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tìm người dùng lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendToUser(int targetId) async {
    if (_myId == null) return;
    SocketService.instance.emit('message', {
      'message': '',
      'sourceId': _myId,
      'targetId': targetId,
      'path': widget.imageUrl,
      'at': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi ảnh')));
    Navigator.pop(context, true);
  }

  Future<void> _sendToGroup(Map<String, dynamic> c) async {
    if (_myId == null) return;
    final conversationId = (c['_id'] as String?) ?? (c['id']?.toString() ?? '');
    if (conversationId.isEmpty) return;
    SocketService.instance.emit('group_message', {
      'conversationId': conversationId,
      'sourceId': _myId,
      'message': '',
      'path': widget.imageUrl,
      'at': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi ảnh đến nhóm')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final showingSearch = _searchCtrl.text.trim().isNotEmpty && _users.isNotEmpty;
    final userList = showingSearch ? _users : _directUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn người nhận'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm người dùng theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_loadingConversations && !showingSearch)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (userList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Nhập để tìm người nhận...'),
                  )
                else
                  ...userList.map((u) {
                    final name = (u['name'] as String?) ?? 'User';
                    final id = (u['userId'] as num?)?.toInt() ?? 0;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Text('ID: $id'),
                      onTap: () => _sendToUser(id),
                    );
                  }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Text('Nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_loadingConversations)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Chưa có nhóm'),
                  )
                else
                  ..._groups.map((c) {
                    final name = (c['name'] as String?)?.isNotEmpty == true ? c['name'] as String : 'Nhóm';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.group)),
                      title: Text(name),
                      onTap: () => _sendToGroup(c),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}