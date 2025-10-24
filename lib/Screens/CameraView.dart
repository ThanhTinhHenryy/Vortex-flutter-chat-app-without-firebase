import 'dart:io';
import 'package:flutter/material.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key, required this.path, required this.onImageSend});
  final String path;
  final Future<void> Function(String) onImageSend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: const [
          Icon(Icons.crop_rotate, size: 27),
          Icon(Icons.emoji_emotions_outlined, size: 27),
          Icon(Icons.title, size: 27),
          Icon(Icons.edit, size: 27),
        ],
      ),
      body: Stack(
        children: [
          // Ảnh preview
          Positioned.fill(
            child: Image.file(
              File(path),
              fit: BoxFit.contain, // hoặc BoxFit.cover tuỳ bạn
            ),
          ),

          // Caption input
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black38,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: TextFormField(
                maxLines: 6,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add caption',
                  hintStyle: const TextStyle(color: Colors.white, fontSize: 17),
                  prefixIcon: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 27,
                  ),
                  suffixIcon: InkWell(
                    onTap: () async {
                      try {
                        await onImageSend(path);
                        Navigator.pop(context);
                      } catch (e) {
                        // Nếu có lỗi, hiển thị snack và không pop
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gửi ảnh thất bại: $e')),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.tealAccent[700],
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
