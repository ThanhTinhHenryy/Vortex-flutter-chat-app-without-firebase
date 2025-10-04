import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contacts});

  final ChatModel contacts;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ListTile(
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: Colors.blueGrey[200],
          child: SvgPicture.asset(
            'assets/svg/person.svg',
            alignment: AlignmentGeometry.center,
            width: 28,
            height: 28,
          ),
        ),
        title: Text(
          contacts.name ?? 'unknown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          contacts.status ?? "don't known",
          style: TextStyle(
            fontSize: 12,
            color: Color.fromARGB(255, 19, 107, 97),
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
