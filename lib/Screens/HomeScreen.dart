import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Pages/CameraPage.dart';
import 'package:chat_app_flutter/Pages/ChatPages.dart';
import 'package:chat_app_flutter/Pages/StatusPage.dart';
import 'package:chat_app_flutter/Screens/LoginScreen.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Services/conversation_service.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Screens/FindFriendsScreen.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Services/message_service.dart';
import 'package:chat_app_flutter/Services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.chatModels,
    required this.sourceChat,
  });
  final List<ChatModel> chatModels;
  final ChatModel sourceChat;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<ChatModel> _chatModels = [];
  bool _loading = false;
  Timer? _pollTimer;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadConversations());
    _initSocket();
  }

  Future<void> _loadConversations() async {
    if (_loading) return;
    setState(() { _loading = true; });
    final myId = (await AuthService.getUserId()) ?? widget.sourceChat.id;
    print("👤 Current user ID (with fallback): $myId");
    if (myId != null) {
      final convs = await ConversationService.fetchConversations(myId);
      print("💬 Received ${convs.length} conversations");
      final List<ChatModel> mapped = [];
      for (final c in convs) {
        final List<dynamic> parts = (c['participants'] as List<dynamic>? ?? []);
        int otherId = myId;
        for (final p in parts) {
          final pid = (p is num) ? p.toInt() : int.tryParse(p.toString()) ?? myId;
          if (pid != myId) { otherId = pid; break; }
        }
        // Lấy tên người dùng theo ID
        final u = await UserService.getById(otherId);
        final displayName = ((u?['name'] as String?)?.isNotEmpty == true)
            ? (u!['name'] as String)
            : 'User $otherId';

        // Lấy tin nhắn cuối cùng để hiển thị preview
        String time = '';
        String currentMessage = '';
        try {
          final msgs = await MessageService.fetchMessages(myId, otherId);
          if (msgs.isNotEmpty) {
            final last = msgs.last;
            currentMessage = MessageService.summarize(last);
            final rawAt = (last['createdAt'] ?? last['at'])?.toString();
            if (rawAt != null) {
              final dt = DateTime.tryParse(rawAt);
              if (dt != null) {
                time = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
              }
            }
          }
        } catch (_) {}

        mapped.add(ChatModel(
          id: otherId,
          name: displayName,
          isGroup: false,
          icon: 'person.png',
          time: time,
          currentMessage: currentMessage,
          status: '',
        ));
      }
      setState(() { _chatModels = mapped; });
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _initSocket() async {
    final myId = (await AuthService.getUserId()) ?? widget.sourceChat.id;
    await SocketService.instance.signin(myId);
    // Gỡ listener cũ nếu có để tránh nhân đôi
    _socket?.off('message');
    _socket?.off('conversations_updated');
    // Dùng socket chung
    _socket = SocketService.instance.socket;
    _socket!.on('message', (msg) {
      final int targetId = (msg['targetId'] is num) ? (msg['targetId'] as num).toInt() : int.tryParse(msg['targetId'].toString()) ?? -1;
      final int sourceId = (msg['sourceId'] is num) ? (msg['sourceId'] as num).toInt() : int.tryParse(msg['sourceId'].toString()) ?? -1;
      if (targetId == myId || sourceId == myId) {
        _loadConversations();
      }
    });
    _socket!.on('conversations_updated', (_) => _loadConversations());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    // Không disconnect socket chung; chỉ gỡ listener
    _socket?.off('message');
    _socket?.off('conversations_updated');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text('Votex Chat'),
        actions: [
          IconButton(onPressed: () { _loadConversations(); }, icon: Icon(Icons.refresh)),
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Logout') {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
              if (value == 'Find Friends') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext contexts) {
              return [
                PopupMenuItem(child: Text('New Group'), value: "New Group"),
                PopupMenuItem(value: "New broadcast", child: Text('New broadcast')),
                PopupMenuItem(value: "Find Friends", child: Text('Find Friends')),
                PopupMenuItem(value: "WhatsApp Webs", child: Text('WhatsApp Webs')),
                PopupMenuItem(value: "Started Message", child: Text('Started Message')),
                PopupMenuItem(value: "New Call", child: Text('New Call')),
                PopupMenuItem(value: "Settings", child: Text('Settings')),
                const PopupMenuItem(value: "Logout", child: Text('Logout')),
              ];
            },
          ),
        ],
        bottom: TabBar(
          labelStyle: TextStyle(color: Colors.white),
          indicatorColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(text: 'Chat'),
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: 'Group Chat'),
            Tab(text: 'Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatPages(
            chatModels: _chatModels,
            sourceChat: widget.sourceChat,
          ),
          CameraPage(),
          Text('Group chat'),
          StatusPage(),
        ],
      ),
    );
  }
}
