import 'package:chat_app_flutter/CustomUI/CustomCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';

class ChatPages extends StatefulWidget {
  const ChatPages({super.key});

  @override
  State<ChatPages> createState() => _ChatPagesState();
}

class _ChatPagesState extends State<ChatPages> {
  List<ChatModel> chats = [
    ChatModel(
      name: 'Yarushi',
      isGroup: false,
      currentMessage: "Hello",
      time: "3:00",
      icon: 'person.png',
    ),
    ChatModel(
      name: 'Yarushi 2',
      isGroup: false,
      currentMessage: "Hello",
      time: "3:00",
      icon: 'person.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFF075E54),
        child: Icon(Icons.chat),
      ),
      body: ListView(children: [CustomCard(), CustomCard()]),
    );
  }
}
