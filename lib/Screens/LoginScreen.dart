import 'package:chat_app_flutter/CustomUI/ButtonCard.dart';
import 'package:chat_app_flutter/Models/ChatModel.dart';
import 'package:chat_app_flutter/Screens/HomeScreen.dart';
import 'package:chat_app_flutter/Screens/RegisterScreen.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ChatModel sourceChat;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  List<ChatModel> chatsModel = [
    ChatModel(
      name: 'Yarushi',
      isGroup: false,
      currentMessage: "Hello",
      time: "3:00",
      icon: 'person.png',
      id: 1,
    ),
    ChatModel(
      name: 'Thanh Tinh',
      isGroup: false,
      currentMessage: "whats up",
      time: "7:00",
      icon: 'person.png',
      id: 2,
    ),
    ChatModel(
      name: 'puu',
      isGroup: false,
      currentMessage: "mun bu",
      time: "2:00",
      icon: 'person.png',
      id: 3,
    ),
  ];

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = (data['user'] as Map<String, dynamic>);
      final int uid = user['userId'] as int;
      final String uname = (user['name'] as String?)?.trim() ?? '';
      sourceChat = ChatModel(
        name: uname.isNotEmpty ? uname : _emailController.text.trim(),
        isGroup: false,
        icon: 'person.png',
        id: uid,
      );
      chatsModel = []; // bỏ danh sách mẫu, để HomeScreen dùng dữ liệu thật sau này
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(chatModels: chatsModel, sourceChat: sourceChat),
        ),
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Nhập email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                child: _loading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Tạo tài khoản'),
                ),
              ),
              const SizedBox(height: 24),
              // const Text('Chọn tài khoản mẫu để vào Home:'), // Ẩn danh sách mẫu để tránh nhầm
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: chatsModel.length,
              //     itemBuilder: (context, index) => InkWell(
              //       onTap: () {
              //         sourceChat = chatsModel.removeAt(index);
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (builder) => HomeScreen(chatModels: chatsModel, sourceChat: sourceChat),
              //           ),
              //         );
              //       },
              //       child: ButtonCard(
              //         name: chatsModel[index].name ?? 'unknown',
              //         icon: Icons.person,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
