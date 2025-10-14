import 'package:chat_app_flutter/CustomUI/AvatarCard.dart';
import 'package:chat_app_flutter/CustomUI/ButtonCard.dart';
import 'package:chat_app_flutter/CustomUI/ContactCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  List<ChatModel> contacts = [
    ChatModel(name: 'Yarushi', status: 'dang bun', id: 1),
    ChatModel(name: 'Tinh', status: 'dang vui', id: 2),
    ChatModel(name: 'Thanh Tinh', status: 'hihi', id: 3),
    ChatModel(name: 'Trâm Ân', status: 'mún ăn canh mồng tơi', id: 4),
    ChatModel(name: 'Ân tửng', status: 'mún ăn bún đậu', id: 5),
  ];

  List<ChatModel> groups = [];

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
              'New Group',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text('Add participants', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search, size: 26)),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: contacts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(height: groups.length > 0 ? 90 : 10);
              }
              return InkWell(
                onTap: () {
                  if (contacts[index - 1].selected == false) {
                    setState(() {
                      groups.add(contacts[index - 1]);
                      contacts[index - 1].selected = true;
                    });
                  } else {
                    setState(() {
                      groups.remove(contacts[index - 1]);
                      contacts[index - 1].selected = false;
                    });
                  }
                },
                child: ContactCard(contacts: contacts[index - 1]),
              );
            },
          ),
          groups.length > 0
              ? Column(
                  children: [
                    Container(
                      height: 70,
                      color: Colors.white,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: contacts.length,
                        itemBuilder: (builder, index) {
                          if (contacts[index].selected == true) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  groups.remove(contacts[index]);
                                  contacts[index].selected = false;
                                });
                              },
                              child: AvatarCard(contact: contacts[index]),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
