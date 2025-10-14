import 'package:chat_app_flutter/CustomUI/ButtonCard.dart';
import 'package:chat_app_flutter/CustomUI/ContactCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/CreateGroup.dart';
import 'package:flutter/material.dart';

class SelectContact extends StatefulWidget {
  const SelectContact({super.key});

  @override
  State<SelectContact> createState() => _SelectContactState();
}

class _SelectContactState extends State<SelectContact> {
  List<ChatModel> contacts = [
    ChatModel(name: 'Yarushi', status: 'dang bun', id: 1),
    ChatModel(name: 'Tinh', status: 'dang vui', id: 2),
    ChatModel(name: 'Thanh Tinh', status: 'hihi', id: 3),
    ChatModel(name: 'Trâm Ân', status: 'mún ăn canh mồng tơi', id: 4),
    ChatModel(name: 'Ân tửng', status: 'mún ăn bún đậu', id: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Contact',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text('120 contacts', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search, size: 26)),
          PopupMenuButton<String>(
            // TODO: menu cho phan 3 cham
            onSelected: (value) {
              print(value);
            },
            itemBuilder: (BuildContext contexts) {
              return [
                PopupMenuItem(
                  value: "Invite a friend",
                  child: Text('Invite a friend'),
                ),
                PopupMenuItem(value: "Contacts", child: Text('Contacts')),
                PopupMenuItem(value: "Refresh", child: Text('Refresh')),
                PopupMenuItem(value: "Help", child: Text('Help ')),
              ];
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: contacts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => CreateGroup()),
                );
              },
              child: ButtonCard(icon: Icons.group, name: 'New Group'),
            );
          } else if (index == 1) {
            return ButtonCard(icon: Icons.person_add, name: 'New Contact');
          }
          return ContactCard(contacts: contacts[index - 2]);
        },
      ),
    );
  }
}
