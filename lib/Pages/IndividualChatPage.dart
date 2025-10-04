import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class IndividualChatPage extends StatefulWidget {
  const IndividualChatPage({super.key, required this.chatModel});
  final ChatModel chatModel;

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  // ? emoji
  final _textController = TextEditingController();
  final _emojiScrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _emojiShowing = false;

  @override
  void dispose() {
    _textController.dispose();
    _emojiScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmoji() {
    if (_emojiShowing) {
      setState(() => _emojiShowing = false);
      _focusNode.requestFocus(); // mở lại bàn phím
    } else {
      _focusNode.unfocus(); // đóng bàn phím
      setState(() => _emojiShowing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(
      context,
    ).viewInsets.bottom; // > 0 nếu bàn phím mở

    return PopScope(
      // Nếu đang mở emoji hoặc bàn phím → tạm thời KHÔNG cho pop route
      canPop: !_emojiShowing && viewInsets == 0,

      // API mới: có thêm tham số `result`
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return; // route đã pop rồi → không làm gì nữa

        if (_emojiShowing) {
          // Ưu tiên đóng emoji panel trước
          setState(() => _emojiShowing = false);
          _focusNode.requestFocus(); // mở lại bàn phím nếu muốn
        } else if (viewInsets > 0) {
          // Nếu bàn phím đang mở, đóng bàn phím trước (lần back này không pop)
          _focusNode.unfocus();
        }
        // Sau khi đóng emoji/keyboard, lần back tiếp theo mới pop route.
      },

      child: Scaffold(
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
        body: Column(
          children: [
            // 1) Danh sách tin nhắn chiếm phần còn lại
            Expanded(
              child: ListView(
                // reverse: true, // nếu muốn neo đáy
                padding: const EdgeInsets.only(bottom: 8),
              ),
            ),

            // 2) Composer (thanh nhập). Khi emoji mở => không cần SafeArea bottom cho composer
            SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: !_emojiShowing,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 65,
                      child: Card(
                        margin: const EdgeInsets.only(left: 6, right: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextFormField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          minLines: 1,
                          onTap: () {
                            if (_emojiShowing)
                              setState(() => _emojiShowing = false);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Type a message",
                            prefixIcon: IconButton(
                              onPressed: _toggleEmoji,
                              icon: const Icon(Icons.emoji_emotions),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      builder: (builder) => bottomSheet(),
                                    );
                                  },
                                  icon: const Icon(Icons.attach_file),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.camera_alt),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.all(5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2, left: 2),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF128C7E),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.mic, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3) Emoji panel ở DƯỚI composer, không chồng lấn
            Offstage(
              offstage:
                  !_emojiShowing ||
                  viewInsets > 0, // nếu bàn phím mở thì ẩn emoji
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true, // kê lên trên gesture bar
                child: EmojiPicker(
                  textEditingController: _textController,
                  scrollController: _emojiScrollController,
                  config: Config(
                    height: 280,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.2
                              : 1.0),
                    ),
                    // categoryViewConfig: const CategoryViewConfig(
                    //   initCategory: Category.SMILEYS,
                    //   recentTabBehavior: RecentTabBehavior.NONE,
                    // ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreate(
                    Icons.insert_drive_file,
                    Colors.indigo,
                    "Document",
                  ),
                  SizedBox(width: 40),
                  iconCreate(Icons.camera_alt, Colors.pink, "Camera"),
                  SizedBox(width: 40),
                  iconCreate(Icons.insert_photo, Colors.purple, "Gallery"),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreate(Icons.headset_mic, Colors.orange, "Audio"),
                  SizedBox(width: 40),
                  iconCreate(Icons.location_pin, Colors.teal, "Location"),
                  SizedBox(width: 40),
                  iconCreate(Icons.person, Colors.blue, "Contact"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconCreate(IconData icon, Color color, String text) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 29),
          ),
          SizedBox(height: 5),
          Text(text),
        ],
      ),
    );
  }
}
