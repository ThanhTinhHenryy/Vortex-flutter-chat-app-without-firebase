import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IndividualChatPage extends StatefulWidget {
  const IndividualChatPage({super.key, required this.chatModel});
  final ChatModel chatModel;

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          leadingWidth: 80,
          // titleSpacing: 0,
          backgroundColor: Color(0xFF075E54),
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_ios, size: 24),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueAccent,
                  child: SvgPicture.asset(
                    (widget.chatModel.isGroup ?? false)
                        ? 'assets/svg/group.svg'
                        : 'assets/svg/person.svg',
                    width: 28,
                    height: 28,
                    // color: Color(#fff),
                  ),
                ),
              ],
            ),
          ),
          title: InkWell(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatModel.name ?? "Unknown",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ), // !fix
                  Text(
                    'last seen today at 07:30',
                    style: TextStyle(fontSize: 12, color: Colors.lightGreen),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.call)),
            IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
            PopupMenuButton<String>(
              // TODO: menu cho phan 3 cham
              onSelected: (value) {
                print(value);
              },
              itemBuilder: (BuildContext contexts) {
                return [
                  PopupMenuItem(
                    value: "View Contact",
                    child: Text('View Contact'),
                  ),
                  PopupMenuItem(
                    value: "Media, links, docs",
                    child: Text('Media, links, docs'),
                  ),
                  PopupMenuItem(value: "Search", child: Text('Search')),
                  PopupMenuItem(
                    value: "WhatsApp Webs",
                    child: Text('WhatsApp Webs'),
                  ),
                  PopupMenuItem(
                    value: "Mute Notification",
                    child: Text('Mute Notification'),
                  ),
                  PopupMenuItem(value: "Wallpaper", child: Text('Wallpaper')),
                ];
              },
            ),
          ],
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            ListView(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 60,
                    child: Card(
                      margin: EdgeInsets.only(left: 2, right: 2, bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        minLines: 1,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message",
                          prefixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.emoji_emotions),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.attach_file),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.camera_alt),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.all(5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                      right: 2,
                      left: 2,
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF128C7E),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.mic, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
