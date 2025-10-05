import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarCard extends StatelessWidget {
  const AvatarCard({super.key, required this.contact});
  final ChatModel contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,

        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Colors.blueGrey[200],
                child: SvgPicture.asset(
                  'assets/svg/person.svg',
                  alignment: AlignmentGeometry.center,
                  width: 28,
                  height: 28,
                ),
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 11,
                  child: Icon(Icons.clear, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(contact.name ?? 'unknown', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
