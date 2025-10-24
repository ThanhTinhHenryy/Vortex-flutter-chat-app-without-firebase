import 'dart:io';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:chat_app_flutter/Services/user_service.dart';
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final int userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _avatarPath; // filename on server
  XFile? _picked;
  Map<String, dynamic>? _user;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final meId = await AuthService.getUserId();
    _isMe = (meId == widget.userId);
    final u = await UserService.getById(widget.userId);
    _user = u;
    _nameCtrl.text = (u?['name'] as String?) ?? '';
    _phoneCtrl.text = (u?['phone'] as String?) ?? '';
    _avatarPath = (u?['avatar'] as String?) ?? '';
    setState(() => _loading = false);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    _picked = img;
    // For preview
    setState(() {});
  }

  Widget _avatarWidget() {
    final double size = 90;
    Widget inner;
    if (_picked != null) {
      if (kIsWeb) {
        inner = CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(_picked!.path));
      } else {
        inner = CircleAvatar(radius: size / 2, backgroundImage: FileImage(File(_picked!.path)));
      }
    } else if ((_avatarPath ?? '').isNotEmpty) {
      inner = CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(buildUploadUrl(_avatarPath!)));
    } else {
      inner = const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 36));
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        SizedBox(width: size, height: size, child: inner),
        if (_isMe)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _pickAvatar,
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_isMe) return; // read-only for others
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    String? avatarFileName = _avatarPath;
    try {
      if (_picked != null) {
        if (kIsWeb) {
          final bytes = await _picked!.readAsBytes();
          final uploaded = await UserService.uploadAvatarFromBytes(bytes, filename: _picked!.name);
          if (uploaded != null) avatarFileName = uploaded;
        } else {
          final uploaded = await UserService.uploadAvatarFromPath(_picked!.path);
          if (uploaded != null) avatarFileName = uploaded;
        }
      }
      final updated = await UserService.updateProfile(
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        avatar: avatarFileName,
        password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      );
      if (updated != null) {
        _user = updated;
        _avatarPath = (updated['avatar'] as String?) ?? avatarFileName;
        if (_isMe) {
          final newName = (updated['name'] as String?) ?? _nameCtrl.text.trim();
          await AuthService.setUserName(newName);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật hồ sơ')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMe ? 'Hồ sơ của tôi' : 'Hồ sơ người dùng'),
        actions: [
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _loading ? null : _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _avatarWidget()),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: _isMe,
                      decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên không được trống' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      enabled: _isMe,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      enabled: _isMe,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Đổi mật khẩu (tuỳ chọn)'),
                    ),
                    const SizedBox(height: 24),
                    if (_user != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.public),
                          title: Text((_user?['name'] as String?) ?? ''),
                          subtitle: Text((_user?['email'] as String?) ?? ''),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_isMe)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu thay đổi'),
                        onPressed: _loading ? null : _save,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}