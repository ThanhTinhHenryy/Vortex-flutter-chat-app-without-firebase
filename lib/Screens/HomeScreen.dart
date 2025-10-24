import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Pages/CameraPage.dart';
import 'package:chat_app_flutter/Pages/ChatPages.dart';
import 'package:chat_app_flutter/Pages/StatusPage.dart';
import 'package:chat_app_flutter/Pages/GroupsPage.dart'
    as groups_page; // new
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
import 'package:chat_app_flutter/Screens/UserProfileScreen.dart';

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
  List<Map<String, dynamic>> _groupConversations = []; // new
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
    setState(() {
      _loading = true;
    });
    final myId = (await AuthService.getUserId()) ?? widget.sourceChat.id;
    print("👤 Current user ID (with fallback): $myId");
    if (myId != null) {
      final convs = await ConversationService.fetchConversations(myId);
      print("💬 Received ${convs.length} conversations");
      final List<ChatModel> dms = [];
      final List<Map<String, dynamic>> groups = [];
      for (final c in convs) {
        final bool isGroup = c['isGroup'] == true;
        if (isGroup) {
          // Group conversation mapping
          String time = '';
          String preview = '';
          try {
            final msgs = await MessageService.fetchByConversationId((c['_id'] ?? c['id']).toString());
            if (msgs.isNotEmpty) {
              final last = msgs.last;
              preview = MessageService.summarize(last);
              final rawAt = (last['createdAt'] ?? last['at'])?.toString();
              final dt = rawAt != null ? DateTime.tryParse(rawAt) : null;
              if (dt != null) {
                time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }
            }
          } catch (_) {}
          groups.add({
            ...c,
            'lastMessage': preview,
            'time': time,
          });
        } else {
          // Direct message mapping (existing behavior)
          final List<dynamic> parts = (c['participants'] as List<dynamic>? ?? []);
          int otherId = myId;
          for (final p in parts) {
            final pid = (p is num) ? p.toInt() : int.tryParse(p.toString()) ?? myId;
            if (pid != myId) {
              otherId = pid;
              break;
            }
          }
          final u = await UserService.getById(otherId);
          final displayName = ((u?['name'] as String?)?.isNotEmpty == true)
              ? (u!['name'] as String)
              : 'User $otherId';
          String time = '';
          String currentMessage = '';
          try {
            final msgs = await MessageService.fetchMessages(myId, otherId);
            if (msgs.isNotEmpty) {
              final last = msgs.last;
              currentMessage = MessageService.summarize(last);
              final rawAt = (last['createdAt'] ?? last['at'])?.toString();
              final dt = rawAt != null ? DateTime.tryParse(rawAt) : null;
              if (dt != null) {
                time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }
            }
          } catch (_) {}
          dms.add(ChatModel(
            id: otherId,
            name: displayName,
            isGroup: false,
            icon: 'person.png',
            time: time,
            currentMessage: currentMessage,
            status: '',
          ));
        }
      }
      setState(() {
        _chatModels = dms;
        _groupConversations = groups;
      });
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
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
        backgroundColor: const Color(0xFF075E54),
        title: const Text('WhatsApp'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: 'Groups'),
            Tab(text: 'Status'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              final myId = await AuthService.getUserId();
              if (myId == null) return;
              // Navigate to profile screen of current user
              // ignore: use_build_context_synchronously
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: myId),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'Find Friends':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
                  );
                  break;
                case 'Logout':
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  break;
                default:
                  debugPrint('Menu: ' + value);
              }
            },
            itemBuilder: (BuildContext contexts) {
              return const [
                PopupMenuItem(value: 'New Group', child: Text('New Group')),
                PopupMenuItem(value: 'New broadcast', child: Text('New broadcast')),
                PopupMenuItem(value: 'Find Friends', child: Text('Find Friends')),
                PopupMenuItem(value: 'WhatsApp Webs', child: Text('WhatsApp Webs')),
                PopupMenuItem(value: 'Started Message', child: Text('Started Message')),
                PopupMenuItem(value: 'New Call', child: Text('New Call')),
                PopupMenuItem(value: 'Settings', child: Text('Settings')),
                PopupMenuItem(value: 'Logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatPages(
            chatModels: _chatModels,
            sourceChat: widget.sourceChat,
          ),
          CameraPage(),
          groups_page.GroupsPage(
            conversations: _groupConversations,
            sourceChat: widget.sourceChat,
          ),
          StatusPage(),
        ],
      ),
    );
  }
}
