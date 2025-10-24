import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công, hãy đăng nhập')),
      );
      Navigator.pop(context); // quay lại LoginScreen
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên (tuỳ chọn)'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                  validator: (v) => (v != _passwordController.text) ? 'Mật khẩu không khớp' : null,
                ),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _handleRegister,
                  child: _loading ? const CircularProgressIndicator() : const Text('Tạo tài khoản'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}