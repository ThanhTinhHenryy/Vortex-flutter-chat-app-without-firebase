import 'package:chat_app_flutter/CustomUI/ButtonCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/HomeScreen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ChatModel sourceChat;

  List<ChatModel> chatsModel = [
    ChatModel(
      name: 'Yarushi',
      isGroup: false,
      currentMessage: "Hello",
      time: "3:00",
      icon: 'person.png',
      id: 1,
    ),
    ChatModel(
      name: 'Thanh Tinh',
      isGroup: false,
      currentMessage: "whats up",
      time: "7:00",
      icon: 'person.png',
      id: 2,
    ),
    ChatModel(
      name: 'puu',
      isGroup: false,
      currentMessage: "mun bu",
      time: "2:00",
      icon: 'person.png',
      id: 3,
    ),
    // ChatModel(
    //   name: 'Dev group',
    //   isGroup: true,
    //   currentMessage: "hi everyone",
    //   time: "13:00",
    //   icon: 'group.png',
    // ),
    // ChatModel(
    //   name: 'my bff group',
    //   isGroup: true,
    //   currentMessage: "chao may tml",
    //   time: "5:00",
    //   icon: 'group.png',
    // ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: chatsModel.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            sourceChat = chatsModel.removeAt(index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) =>
                    HomeScreen(chatModels: chatsModel, sourceChat: sourceChat),
              ),
            );
          },
          child: ButtonCard(
            name: chatsModel[index].name ?? 'unknown',
            icon: Icons.person,
          ),
        ),
      ),
    );
  }
}
