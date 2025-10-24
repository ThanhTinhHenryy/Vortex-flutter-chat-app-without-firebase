import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Web-only: crop ảnh trên bytes, trả về bytes đã crop qua Navigator.pop
class CropImageWebScreen extends StatefulWidget {
  const CropImageWebScreen({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<CropImageWebScreen> createState() => _CropImageWebScreenState();
}

class _CropImageWebScreenState extends State<CropImageWebScreen> {
  final _controller = CropController();
  bool _processing = false;

  Future<void> _onCropped(CropResult result) async {
    setState(() => _processing = true);
    try {
      switch (result) {
        case CropSuccess(:final croppedImage):
          final decoded = img.decodeImage(croppedImage);
          final jpg = img.encodeJpg(decoded!, quality: 90);
          if (!mounted) return;
          Navigator.pop<Uint8List>(context, Uint8List.fromList(jpg));
        case CropFailure(:final cause):
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không lưu được ảnh crop: $cause')),
          );
          Navigator.pop<Uint8List>(context, widget.bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được ảnh crop: $e')),
      );
      Navigator.pop<Uint8List>(context, widget.bytes);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop ảnh (Web)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _processing ? null : () => _controller.crop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Crop(
            image: widget.bytes,
            controller: _controller,
            withCircleUi: false,
            baseColor: Colors.black,
            maskColor: Colors.black.withOpacity(0.6),
            cornerDotBuilder: (size, edgeAlignment) => Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            onCropped: _onCropped,
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}