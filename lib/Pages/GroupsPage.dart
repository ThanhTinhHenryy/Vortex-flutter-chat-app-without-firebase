import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Pages/GroupChatPage.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/CreateGroup.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key, required this.conversations, required this.sourceChat});
  final List<Map<String, dynamic>> conversations;
  final ChatModel sourceChat;

  @override
  Widget build(BuildContext context) {
    final isEmpty = conversations.isEmpty;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroup()),
          );
        },
        backgroundColor: const Color(0xFF075E54),
        child: const Icon(Icons.group_add),
      ),
      body: isEmpty
          ? const Center(
              child: Text(
                'Chưa có nhóm nào\nHãy tạo nhóm mới!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final c = conversations[index];
                final String name = (c['name'] as String?)?.isNotEmpty == true
                    ? c['name'] as String
                    : 'Nhóm';
                final String lastMessage = (c['lastMessage'] as String?) ?? '';
                final String time = (c['time'] as String?) ?? '';
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatPage(conversation: c),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.group, size: 26),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.done_all, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lastMessage.isNotEmpty ? lastMessage : 'Bắt đầu trò chuyện',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(time.isNotEmpty ? time : ''),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 20, left: 80),
                        child: Divider(thickness: 1.5, color: Colors.black12),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}