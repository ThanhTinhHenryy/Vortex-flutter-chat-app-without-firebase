import 'package:chat_app_flutter/CustomUI/CustomCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/SelectContact.dart';
import 'package:flutter/material.dart';

class ChatPages extends StatefulWidget {
  const ChatPages({
    super.key,
    required this.chatModels,
    required this.sourceChat,
  });
  final List<ChatModel> chatModels;
  final ChatModel sourceChat;

  @override
  State<ChatPages> createState() => _ChatPagesState();
}

class _ChatPagesState extends State<ChatPages> {
  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.chatModels.isEmpty;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (builder) => SelectContact()),
          );
        },
        backgroundColor: Color(0xFF075E54),
        child: Icon(Icons.chat),
      ),
      body: isEmpty
          ? const Center(
              child: Text(
                'Chưa có cuộc trò chuyện\nHãy tìm bạn bè và bắt đầu nhắn tin!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: widget.chatModels.length,
              itemBuilder: (context, index) => CustomCard(
                chatModel: widget.chatModels[index],
                sourceChat: widget.sourceChat,
              ),
            ),
    );
  }
}
