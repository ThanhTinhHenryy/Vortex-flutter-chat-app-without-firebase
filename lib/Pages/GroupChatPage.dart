import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Services/message_service.dart';
import 'package:chat_app_flutter/Services/socket_service.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Services/conversation_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:chat_app_flutter/Services/image_resize.dart';
import 'package:chat_app_flutter/Screens/CameraView.dart';
import 'package:chat_app_flutter/Screens/CropImageScreen.dart';
import 'package:chat_app_flutter/Screens/CropImageWebScreen.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.conversation});
  final Map<String, dynamic> conversation;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  bool _loading = false;
  int? _myId;
  final Set<String> _seenSigs = {}; // de-dup
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // Helper: scroll to bottom
  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position.maxScrollExtent;
      if (instant) {
        _scrollController.jumpTo(pos);
      } else {
        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      await Future.delayed(const Duration(milliseconds: 60));
      if (!_scrollController.hasClients) return;
      final latestPos = _scrollController.position.maxScrollExtent;
      if ((_scrollController.offset - latestPos).abs() > 1) {
        _scrollController.jumpTo(latestPos);
      }
    });
  }
  String get _convoId => (widget.conversation['_id'] as String?) ?? (widget.conversation['id']?.toString() ?? '');
  String get _groupName => (widget.conversation['name'] as String?)?.isNotEmpty == true ? widget.conversation['name'] as String : 'Nhóm';
  List<int> get _participants => ((widget.conversation['participants'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList());

  String _sigFrom(Map<String, dynamic> m) {
    final sid = (m['senderId'] is num) ? (m['senderId'] as num).toInt() : int.tryParse('${m['senderId']}') ?? 0;
    final msg = (m['message'] ?? '').toString();
    final path = (m['path'] ?? '').toString();
    final at = (m['createdAt'] ?? m['at'] ?? '').toString();
    return '$sid|$msg|$path|$at';
  }
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = await AuthService.getUserId();
    await SocketService.instance.signin(_myId ?? 0);
    // Load messages
    await _loadMessages();
    // Listen socket
    final s = SocketService.instance.socket;
    s.off('group_message');
    s.on('group_message', (msg) {
      try {
        final cid = (msg['conversationId'] ?? '').toString();
        if (cid == _convoId) {
          final incoming = {
            'senderId': (msg['sourceId'] is num) ? (msg['sourceId'] as num).toInt() : int.tryParse('${msg['sourceId']}') ?? 0,
            'message': (msg['message'] ?? '').toString(),
            'path': (msg['path'] ?? '').toString(),
            'at': (msg['createdAt'] ?? msg['at'] ?? DateTime.now().toIso8601String()).toString(),
          };
          final sig = _sigFrom(incoming);
          if (!_seenSigs.contains(sig)) {
            setState(() {
              _messages.add(incoming);
              _seenSigs.add(sig);
            });
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadMessages() async {
    if (_convoId.isEmpty) return;
    setState(() => _loading = true);
    final arr = await MessageService.fetchByConversationId(_convoId);
    setState(() {
      _messages.clear();
      _seenSigs.clear();
      for (final m in arr) {
        final map = Map<String, dynamic>.from(m);
        // normalize key name
        map['senderId'] = map['senderId'] ?? map['sourceId'] ?? 0;
        final sig = _sigFrom(map);
        if (!_seenSigs.contains(sig)) {
          _messages.add(map);
          _seenSigs.add(sig);
        }
      }
      _loading = false;
    });
    _scrollToBottom(instant: true);
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _myId == null) return;
    final nowIso = DateTime.now().toIso8601String();
    final local = {
      'senderId': _myId,
      'message': text,
      'path': '',
      'at': nowIso,
    };
    final sig = _sigFrom(local);
    setState(() {
      if (!_seenSigs.contains(sig)) {
        _messages.add(local);
        _seenSigs.add(sig);
      }
    });
    _scrollToBottom();
    _textCtrl.clear();
    SocketService.instance.emit('group_message', {
      'conversationId': _convoId,
      'sourceId': _myId,
      'message': text,
      'path': '',
      'at': nowIso,
    });
  }

  // Pick image with crop & preview before sending
  Future<void> _onPickGalleryTap() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        final croppedBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(builder: (_) => CropImageWebScreen(bytes: bytes)),
        );
        if (croppedBytes == null) return;
        await _uploadBytesAndSend(croppedBytes);
        return;
      }
      // Mobile: crop -> preview -> send
      final croppedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => CropImageScreen(path: img.path)),
      );
      final previewPath = croppedPath ?? img.path;
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraView(
            path: previewPath,
            onImageSend: (p) async => _uploadPathAndSend(p),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được Gallery: $e')),
      );
    }
  }

  Future<void> _uploadPathAndSend(String path) async {
    try {
      final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
      final req = http.MultipartRequest('POST', uri);
      req.files.add(await http.MultipartFile.fromPath('img', path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final filename = (data['path'] ?? '') as String;
      if (filename.isEmpty) throw Exception('Upload thất bại');
      final imageUrl = buildUploadUrl(filename);
      _sendImageUrl(imageUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
    }
  }

  Future<void> _uploadBytesAndSend(Uint8List bytes) async {
    try {
      final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
      final req = http.MultipartRequest('POST', uri);
      req.files.add(http.MultipartFile.fromBytes('img', bytes, filename: 'upload.jpg'));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final filename = (data['path'] ?? '') as String;
      if (filename.isEmpty) throw Exception('Upload thất bại');
      final imageUrl = buildUploadUrl(filename);
      _sendImageUrl(imageUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload ảnh: $e')));
    }
  }

  void _sendImageUrl(String imageUrl) {
    if (_myId == null || imageUrl.isEmpty) return;
    final nowIso = DateTime.now().toIso8601String();
    final local = {
      'senderId': _myId,
      'message': '',
      'path': imageUrl,
      'at': nowIso,
    };
    final sig = _sigFrom(local);
    setState(() {
      if (!_seenSigs.contains(sig)) {
        _messages.add(local);
        _seenSigs.add(sig);
      }
    });
    SocketService.instance.emit('group_message', {
      'conversationId': _convoId,
      'sourceId': _myId,
      'message': '',
      'path': imageUrl,
      'at': nowIso,
    });
  }

  void _viewImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(url),
          ),
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final int senderId = (m['senderId'] is num)
        ? (m['senderId'] as num).toInt()
        : int.tryParse(m['senderId'].toString()) ?? 0;
    final bool fromMe = senderId == _myId;
    final String content = (m['message'] as String?) ?? '';
    final String imgPath = (m['path'] as String?) ?? '';
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: fromMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!fromMe)
              FutureBuilder<Map<String, dynamic>?>(
                future: UserService.getById(senderId),
                builder: (context, snapshot) {
                  final name = (snapshot.data?['name'] as String?) ?? 'User $senderId';
                  return Text(name, style: const TextStyle(fontSize: 12, color: Colors.black54));
                },
              ),
            if (imgPath.isNotEmpty)
              GestureDetector(
                onTap: () => _viewImage(imgPath),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
                  child: Image.network(imgPath, fit: BoxFit.cover),
                ),
              )
            else
              Text(content),
          ],
        ),
      ),
    );
  }

  Future<void> _renameGroup() async {
    final TextEditingController ctrl = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên nhóm'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên nhóm mới'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final updated = await ConversationService.renameGroup(conversationId: _convoId, name: newName);
    if (updated != null) {
      setState(() {
        widget.conversation['name'] = updated['name'] ?? newName;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đổi tên nhóm')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi tên thất bại')));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _renameGroup,
            tooltip: 'Đổi tên nhóm',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _bubble(_messages[i]),
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(hintText: 'Nhập tin nhắn...'),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  color: const Color(0xFF128C7E),
                  onPressed: _onPickGalleryTap,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF128C7E),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}