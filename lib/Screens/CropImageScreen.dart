import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Màn hình crop ảnh tự do.
/// Trả về đường dẫn file tạm sau khi crop (JPEG) qua Navigator.pop(context, path)
class CropImageScreen extends StatefulWidget {
  const CropImageScreen({super.key, required this.path});
  final String path;

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final _controller = CropController();
  Uint8List? _imageBytes;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không đọc được ảnh: $e')),
      );
      Navigator.pop(context, widget.path);
    }
  }

  Future<void> _onCropped(CropResult result) async {
    setState(() => _processing = true);
    try {
      switch (result) {
        case CropSuccess(:final croppedImage):
          final decoded = img.decodeImage(croppedImage);
          final jpg = img.encodeJpg(decoded!, quality: 90);

          final tempDir = await getTemporaryDirectory();
          final outName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final outPath = p.join(tempDir.path, outName);
          final f = File(outPath);
          await f.writeAsBytes(jpg, flush: true);

          if (!mounted) return;
          Navigator.pop(context, outPath);
        case CropFailure(:final cause):
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Crop thất bại: $cause')),
          );
          Navigator.pop(context, widget.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được ảnh crop: $e')),
      );
      Navigator.pop(context, widget.path);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop ảnh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _imageBytes == null || _processing
                ? null
                : () {
                    _controller.crop();
                  },
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Crop(
                  image: _imageBytes!,
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