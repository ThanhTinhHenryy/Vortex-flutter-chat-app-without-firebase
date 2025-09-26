import 'package:chat_app_flutter/Pages/ChatPages.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text('Votex Chat'),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          // IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
          PopupMenuButton<String>(
            // TODO: menu cho phan 3 cham
            onSelected: (value) {
              print(value);
            },
            itemBuilder: (BuildContext contexts) {
              return [
                PopupMenuItem(child: Text('New Group'), value: "New Group"),
                PopupMenuItem(
                  value: "New broadcast",
                  child: Text('New broadcast'),
                ),
                PopupMenuItem(
                  value: "Find Friends",
                  child: Text('Find Friends'),
                ),
                PopupMenuItem(
                  value: "WhatsApp Webs",
                  child: Text('WhatsApp Webs'),
                ),
                PopupMenuItem(
                  value: "Started Message",
                  child: Text('Started Message'),
                ),
                PopupMenuItem(value: "New Call", child: Text('New Call')),
                PopupMenuItem(value: "Settings", child: Text('Settings')),
              ];
            },
          ),
        ],
        bottom: TabBar(
          labelStyle: TextStyle(color: Colors.white),
          indicatorColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: 'Chat'),
            Tab(text: 'Group Chat'),
            Tab(text: 'Call'),
            // Tab(text: 'TB'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [Text('Cam'), ChatPages(), Text('Group chat'), Text('Call')],
      ),
    );
  }
}
