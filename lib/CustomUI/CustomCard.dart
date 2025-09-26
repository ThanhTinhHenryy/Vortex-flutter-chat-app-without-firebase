import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Pages/IndividualChatPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomCard extends StatelessWidget {
  // const CustomCard({Key key, this.chatModel} ) : super(key: key);
  const CustomCard({super.key, required this.chatModel});
  final ChatModel chatModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IndividualChatPage()),
        );
      },
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: SvgPicture.asset(
                (chatModel.isGroup ?? false)
                    ? 'assets/svg/group.svg'
                    : 'assets/svg/person.svg',
                width: 28,
                height: 28,
                // color: Color(#fff),
              ),
            ),
            title: Text(
              chatModel.name ??
                  'unknown', // !FIXME: loi unknown name (fallback neu data ten null)
              // chatModel.name!, // chac chan co ten thi dung cai nay
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.done_all),
                SizedBox(width: 3),
                Text(
                  chatModel.currentMessage ?? 'new chat',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            trailing: Text(chatModel.time ?? '00:00'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 80),
            child: Divider(thickness: 1.5, color: Colors.black12),
          ),
        ],
      ),
    );
  }
}
