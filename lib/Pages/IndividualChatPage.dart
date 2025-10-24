import 'package:chat_app_flutter/CustomUI/OwnFileCard.dart';
import 'package:chat_app_flutter/CustomUI/OwnMessagesCard.dart';
import 'package:chat_app_flutter/CustomUI/ReplyFileCard.dart';
import 'package:chat_app_flutter/CustomUI/ReplyMesageCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Models/MessageModel.dart';
import 'package:chat_app_flutter/Screens/CameraScreen.dart';
import 'package:chat_app_flutter/Screens/CameraView.dart';
import 'package:chat_app_flutter/Screens/CropImageWebScreen.dart';
import 'package:chat_app_flutter/Screens/CropImageScreen.dart';
import 'package:chat_app_flutter/Screens/UserProfileScreen.dart';
import 'package:chat_app_flutter/Services/image_resize.dart';
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:chat_app_flutter/Services/message_service.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Services/socket_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:http_parser/http_parser.dart';

class IndividualChatPage extends StatefulWidget {
  const IndividualChatPage({
    super.key,
    required this.chatModel,
    required this.sourceChat,
  });
  final ChatModel chatModel;
  final ChatModel sourceChat;

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  // ? emoji
  final _textController = TextEditingController();
  final _emojiScrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _emojiShowing = false;

  // ?Nhan tin
  bool sendButton = false;
  List<MessageModel> messages = [];
  String _partnerName = '';

  final ScrollController _scrollController = ScrollController();

  // Helper: scroll to the latest message
  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;
      final double pos = _scrollController.position.maxScrollExtent;
      if (instant) {
        _scrollController.jumpTo(pos);
      } else {
        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      // Fallback: re-assert bottom after a short delay in case layout is not yet stable
      await Future.delayed(const Duration(milliseconds: 60));
      if (!_scrollController.hasClients) return;
      final double latestPos = _scrollController.position.maxScrollExtent;
      // If not at bottom yet, force a jump to the bottom
      if ((_scrollController.offset - latestPos).abs() > 1) {
        _scrollController.jumpTo(latestPos);
      }
    });
  }
  
  // ? docket.io
  late IO.Socket socket;

  // ? image
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;

  Future<void> _ensurePartnerName() async {
    final initial = widget.chatModel.name ?? 'User ${widget.chatModel.id}';
    setState(() => _partnerName = initial);
    try {
      final Map<String, dynamic>? user =
          await UserService.getById(widget.chatModel.id);
      final String display = (user?['name'] as String?) ?? initial;
      if (display.isNotEmpty && display != _partnerName) {
        setState(() => _partnerName = display);
      }
    } catch (_) {}
  }

  void _appendHistory(List<Map<String, dynamic>> arr) {
    final List<MessageModel> loaded = [];
    for (final m in arr) {
      final int sid = ((m['sourceId'] ?? m['senderId']) as num?)?.toInt() ?? -1;
      final String path = (m['path'] ?? '') as String;
      final String text = (m['message'] ?? '') as String;
      final String type = sid == widget.sourceChat.id ? 'source' : 'destination';
      String time = '';
      final rawAt = (m['createdAt'] ?? m['at'])?.toString();
      if (rawAt != null) {
        final dt = DateTime.tryParse(rawAt);
        if (dt != null) {
          time = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
        }
      }
      loaded.add(MessageModel(type: type, message: text, path: path, time: time));
    }
    setState(() { messages = loaded; });
    _scrollToBottom(instant: true);
  }

  Future<void> _loadHistory() async {
    final arr = await MessageService.fetchMessages(widget.sourceChat.id, widget.chatModel.id);
    _appendHistory(arr);
  }

  void _onPickGalleryTap() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      setState(() => _picked = img);
      if (!mounted) return;
      Navigator.pop(context);
      final bytes = await img.readAsBytes();
      if (foundation.kIsWeb) {
        final croppedBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (_) => CropImageWebScreen(bytes: bytes),
          ),
        );
        if (croppedBytes == null) return;
        await onImageSendBytes(croppedBytes);
        return;
      }
      final croppedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CropImageScreen(path: img.path),
        ),
      );
      if (!mounted) return;
      final previewPath = croppedPath ?? img.path;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraView(
            path: previewPath,
            onImageSend: onImageSend,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('pickImage error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được Gallery: $e')),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    setState(() {
      _picked = img;
    });
  }

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
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _emojiShowing = true);
    }
  }

  void connect() async {
    final myId = (await AuthService.getUserId()) ?? widget.sourceChat.id;
    await SocketService.instance.signin(myId);
    socket = SocketService.instance.socket;
    // Gỡ listener cũ để tránh nhân đôi
    socket.off("message");
    socket.on("message", (msg) {
      final int targetId = (msg['targetId'] is num) ? (msg['targetId'] as num).toInt() : int.tryParse(msg['targetId'].toString()) ?? -1;
      final int sourceId = (msg['sourceId'] is num) ? (msg['sourceId'] as num).toInt() : int.tryParse(msg['sourceId'].toString()) ?? -1;
      final int partnerId = widget.chatModel.id;
      if ((targetId == myId && sourceId == partnerId) || (sourceId == myId && targetId == partnerId)) {
        setMessage(sourceId == myId ? "source" : "destination", msg["message"] ?? '', msg["path"] ?? '');
        _scrollToBottom();
      }
    });
  }

  Future<void> sendMessage(String message, int sourceId, int targetId, String path) async {
    final myId = (await AuthService.getUserId()) ?? sourceId;
    setMessage("source", message, path);
    SocketService.instance.emit("message", {
      "message": message,
      "sourceId": myId,
      "targetId": targetId,
      "path": path,
      "at": DateTime.now().toIso8601String(),
    });
  }

  void setMessage(String type, String message, String path) {
    MessageModel messageModel = MessageModel(
      type: type,
      message: message,
      path: path,
      time: DateTime.now().toString().substring(10, 16),
    );
    setState(() {
      messages.add(messageModel);
    });
    _scrollToBottom();
  }

  Future<void> onImageSend(String path) async {
    try {
      final resizedPath = await resizeImageFile(
        path,
        maxDimension: 1280,
        quality: 85,
      );
      final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('img', resizedPath));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final filename = (data['path'] ?? '') as String;
      if (filename.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload thất bại')),
        );
        return;
      }
      final imageUrl = buildUploadUrl(filename);
      sendMessage('', widget.sourceChat.id, widget.chatModel.id, imageUrl);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    connect();
    _ensurePartnerName();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_emojiShowing && viewInsets == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_emojiShowing) {
          setState(() => _emojiShowing = false);
          _focusNode.requestFocus();
        } else if (viewInsets > 0) {
          _focusNode.unfocus();
        }
      },
      child: Stack(
        children: [
          Image.asset(
            "assets/whatsapp_Back.png",
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: AppBar(
                leadingWidth: 80,
                backgroundColor: const Color(0xFF075E54),
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
                          _partnerName.isNotEmpty
                              ? _partnerName
                              : (widget.chatModel.name ?? "Unknown"),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'last seen today at 07:30',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.call)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      final otherId = widget.chatModel.id;
                      if (otherId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: otherId),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      debugPrint(value);
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
                        PopupMenuItem(
                          value: "Wallpaper",
                          child: Text('Wallpaper'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height - 140,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final hasImage = (msg.path ?? '').isNotEmpty;
                        if ((msg.type ?? '') == "source") {
                          return hasImage
                              ? OwnFileCard(path: msg.path!)
                              : OwnMessageCard(
                                  message: msg.message ?? 'null',
                                  time: msg.time ?? 'null',
                                );
                        } else {
                          return hasImage
                              ? ReplyFileCard(path: msg.path!)
                              : ReplyMessageCard(
                                  message: msg.message ?? 'null',
                                  time: msg.time ?? 'null',
                                );
                        }
                      },
                    ),
                  ),
                ),
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
                              onChanged: (value) {
                                if (value.length > 0) {
                                  setState(() {
                                    sendButton = true;
                                  });
                                } else {
                                  setState(() {
                                    sendButton = false;
                                  });
                                }
                              },
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              minLines: 1,
                              onTap: () {
                                if (_emojiShowing) setState(() => _emojiShowing = false);
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
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (builder) => CameraScreen(),
                                          ),
                                        );
                                      },
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
                              onPressed: () {
                                if (sendButton) {
                                  // Auto-scroll handled in setMessage -> sendMessage
                                  sendMessage(
                                    _textController.text,
                                    widget.sourceChat.id,
                                    widget.chatModel.id,
                                    "",
                                  );
                                  _textController.clear();
                                  setState(() {
                                    sendButton = false;
                                  });
                                }
                              },
                              icon: Icon(
                                sendButton ? Icons.send : Icons.mic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Offstage(
                  offstage: !_emojiShowing || viewInsets > 0,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    bottom: true,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      scrollController: _emojiScrollController,
                      config: Config(
                        height: 280,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    () {},
                  ),
                  SizedBox(width: 40),
                  iconCreate(Icons.camera_alt, Colors.pink, "Camera", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => CameraScreen()),
                    );
                  }),
                  SizedBox(width: 40),
                  iconCreate(Icons.insert_photo, Colors.purple, "Gallery", () {
                    _onPickGalleryTap();
                  }),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreate(Icons.headset_mic, Colors.orange, "Audio", () {}),
                  SizedBox(width: 40),
                  iconCreate(
                    Icons.location_pin,
                    Colors.teal,
                    "Location",
                    () {},
                  ),
                  SizedBox(width: 40),
                  iconCreate(Icons.person, Colors.blue, "Contact", () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconCreate(
    IconData icon,
    Color color,
    String text,
    GestureTapCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
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

  Future<void> onImageSendBytes(Uint8List bytes) async {
    try {
      final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'img',
        bytes,
        filename: 'upload.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final filename = (data['path'] ?? '') as String;
      if (filename.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload thất bại')),
        );
        return;
      }
      final imageUrl = buildUploadUrl(filename);
      sendMessage('', widget.sourceChat.id, widget.chatModel.id, imageUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload ảnh thất bại: $e')),
      );
    }
  }
}
