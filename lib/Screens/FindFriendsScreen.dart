import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Pages/IndividualChatPage.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  ChatModel? _me;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final id = await AuthService.getUserId();
    final name = await AuthService.getUserName();
    setState(() {
      _me = ChatModel(
        id: id ?? 0,
        name: (name ?? '').isNotEmpty ? name : 'Me',
        icon: 'person.png',
        isGroup: false,
        time: '',
        currentMessage: '',
        status: '',
      );
    });
  }

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final users = await UserService.searchUsers(q);
      setState(() => _results = users);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChat(Map<String, dynamic> u) {
    if (_me == null) return;
    final int uid = (u['userId'] as num).toInt();
    final chatModel = ChatModel(
      id: uid,
      name: ((u['name'] as String?)?.isNotEmpty == true)
          ? u['name'] as String
          : (u['email'] as String? ?? 'User'),
      icon: 'person.png',
      isGroup: false,
      time: '',
      currentMessage: '',
      status: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            IndividualChatPage(chatModel: chatModel, sourceChat: _me!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên hoặc email...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _doSearch,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tìm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Không có kết quả'))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final u = _results[i];
                      final title =
                          (u['name'] as String?) ??
                          (u['email'] as String? ?? '');
                      final subtitle = (u['email'] as String?) ?? '';
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(title.isNotEmpty ? title : 'Không tên'),
                        subtitle: Text(subtitle),
                        onTap: () => _openChat(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}