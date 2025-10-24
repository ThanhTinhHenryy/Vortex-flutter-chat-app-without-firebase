import 'dart:io';
import 'package:flutter/material.dart';

class FullImageView extends StatelessWidget {
  const FullImageView({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = path.startsWith('http');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ảnh', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 0.5,
            maxScale: 5.0,
            child: isNetwork
                ? Image.network(
                    path,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}