import 'package:chat_app_flutter/CustomUI/AvatarCard.dart';
import 'package:chat_app_flutter/CustomUI/ButtonCard.dart';
import 'package:chat_app_flutter/CustomUI/ContactCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Services/conversation_service.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Pages/GroupChatPage.dart';
import 'package:chat_app_flutter/Services/user_service.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  List<ChatModel> contacts = [];
  List<ChatModel> groups = [];
  final TextEditingController _nameCtrl = TextEditingController();
  bool _creating = false;
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final myId = await AuthService.getUserId();
      if (myId == null) {
        setState(() {
          contacts = [];
          _loadingContacts = false;
        });
        return;
      }
      final convos = await ConversationService.fetchConversations(myId);
      final dms = convos.where((c) => (c['isGroup'] == false) && (c['participants'] is List)).toList();
      final List<ChatModel> list = [];
      for (final c in dms) {
        final parts = (c['participants'] as List<dynamic>).map((e) => (e as num).toInt()).toList();
        if (!parts.contains(myId) || parts.length != 2) continue;
        final otherId = parts.firstWhere((x) => x != myId, orElse: () => -1);
        if (otherId <= 0) continue;
        final u = await UserService.getById(otherId);
        final title = (u != null && (u['name'] as String?)?.isNotEmpty == true)
            ? (u!['name'] as String)
            : (u != null ? (u['email'] as String? ?? 'User $otherId') : 'User $otherId');
        list.add(ChatModel(
          id: otherId,
          name: title,
          icon: 'person.png',
          isGroup: false,
          time: '',
          currentMessage: '',
          status: '',
        ));
      }
      setState(() {
        contacts = list;
        _loadingContacts = false;
      });
    } catch (e) {
      setState(() => _loadingContacts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh bạ: $e')));
      }
    }
  }

  Future<void> _createGroup() async {
    if (_creating) return;
    final name = _nameCtrl.text.trim();
    final myId = await AuthService.getUserId();
    final ids = groups.map((e) => e.id).toList();
    if (myId != null) ids.add(myId);
    final unique = ids.toSet().toList();
    if (unique.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhóm cần ít nhất 3 thành viên (bao gồm bạn)')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final convo = await ConversationService.createGroup(name: name.isEmpty ? 'Nhóm mới' : name, participants: unique);
      if (convo != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GroupChatPage(conversation: convo)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo nhóm thất bại')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        title: const Text('New Group'),
        backgroundColor: const Color(0xFF075E54),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.more_vert),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Thành viên đã nhắn tin 1-1 với bạn'),
            subtitle: _loadingContacts
                ? const Text('Đang tải danh sách...')
                : Text('${contacts.length} liên hệ'),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length + 2,
              itemBuilder: (builder, index) {
                if (index == 0) {
                  return const ButtonCard(icon: Icons.group, name: 'New Group');
                } else if (index == 1) {
                  return const ButtonCard(icon: Icons.person_add, name: 'New Contact');
                }
                return InkWell(
                  onTap: () {
                    if (contacts[index - 2].selected == false) {
                      setState(() {
                        groups.add(contacts[index - 2]);
                        contacts[index - 2].selected = true;
                      });
                    } else {
                      setState(() {
                        groups.remove(contacts[index - 2]);
                        contacts[index - 2].selected = false;
                      });
                    }
                  },
                  child: ContactCard(contacts: contacts[index - 2]),
                );
              },
            ),
          ),
          groups.isNotEmpty
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
                    const Divider(thickness: 1, color: Colors.black),
                  ],
                )
              : Container(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF075E54),
        onPressed: _creating ? null : _createGroup,
        label: _creating ? const Text('Đang tạo...') : const Text('Tạo nhóm'),
        icon: const Icon(Icons.group_add),
      ),
    );
  }
}
