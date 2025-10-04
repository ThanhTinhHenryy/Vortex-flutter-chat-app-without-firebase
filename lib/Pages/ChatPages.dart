import 'package:chat_app_flutter/CustomUI/CustomCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/SelectContact.dart';
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
      name: 'Thanh Tinh',
      isGroup: false,
      currentMessage: "whats up",
      time: "7:00",
      icon: 'person.png',
    ),
    ChatModel(
      name: 'puu',
      isGroup: false,
      currentMessage: "mun bu",
      time: "2:00",
      icon: 'person.png',
    ),
    ChatModel(
      name: 'Dev group',
      isGroup: true,
      currentMessage: "hi everyone",
      time: "13:00",
      icon: 'group.png',
    ),
    ChatModel(
      name: 'my bff group',
      isGroup: true,
      currentMessage: "chao may tml",
      time: "5:00",
      icon: 'group.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) => CustomCard(chatModel: chats[index]),
      ),
    );
  }
}
