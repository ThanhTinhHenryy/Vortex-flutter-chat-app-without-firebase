import 'package:camera/camera.dart';
import 'package:chat_app_flutter/Screens/CameraView.dart';
import 'package:chat_app_flutter/Screens/VideoView.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/Screens/SelectRecipient.dart';
import 'package:chat_app_flutter/Services/server_config.dart';
import 'package:chat_app_flutter/Services/image_resize.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chat_app_flutter/Screens/CropImageScreen.dart';
import 'package:chat_app_flutter/Screens/CropImageWebScreen.dart';
import 'dart:typed_data';

late List<CameraDescription> cameras;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraController _cameraController;
  late final Future<void> cameraValue;

  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      cameras.first, // hoặc chọn theo lensDirection
      ResolutionPreset.high,
      // enableAudio: true,      // nếu muốn ghi âm, bật và xin quyền RECORD_AUDIO
    );
    cameraValue = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: cameraValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController.value.aspectRatio,
                    child: CameraPreview(_cameraController),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Camera error: ${snapshot.error}'));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(
                        Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!isRecording) takePhoto(context);
                        },
                        onLongPress: () async {
                          try {
                            await cameraValue;
                            if (_cameraController.value.isRecordingVideo)
                              return;
                            await _cameraController.startVideoRecording();
                            setState(() => isRecording = true);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Start recording failed: $e'),
                              ),
                            );
                          }
                        },
                        onLongPressUp: () async {
                          try {
                            if (!_cameraController.value.isRecordingVideo)
                              return;
                            final XFile file = await _cameraController
                                .stopVideoRecording();
                            setState(() => isRecording = false);

                            if (!mounted) return;
                            // Điều hướng sang trang xem video với đường dẫn đúng
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoView(path: file.path),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => isRecording = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stop recording failed: $e'),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          isRecording
                              ? Icons.radio_button_on
                              : Icons.panorama_fish_eye,
                          color: isRecording ? Colors.red : Colors.white,
                          size: 70,
                        ),
                      ),
                      const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hold for video, tap for photo',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> takePhoto(BuildContext context) async {
    try {
      await cameraValue;
      final XFile shot = await _cameraController.takePicture();
      if (!mounted) return;
      if (kIsWeb) {
        final Uint8List bytes = await shot.readAsBytes();
        final croppedBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (_) => CropImageWebScreen(bytes: bytes),
          ),
        );
        if (croppedBytes == null) return;
        final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
        final req = http.MultipartRequest('POST', uri);
        req.files.add(http.MultipartFile.fromBytes('img', croppedBytes, filename: 'capture.jpg'));
        final streamed = await req.send();
        final resp = await http.Response.fromStream(streamed);
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final filename = (data['path'] as String?) ?? '';
        if (filename.isEmpty) {
          throw Exception('Upload thất bại');
        }
        final imageUrl = buildUploadUrl(filename);
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => SelectRecipientScreen(imageUrl: imageUrl),
          ),
        );
        if (ok != true) {
          throw Exception('Bạn chưa chọn người nhận');
        }
        return;
      }
      final croppedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CropImageScreen(path: shot.path),
        ),
      );
      final previewPath = croppedPath ?? shot.path;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraView(
            path: previewPath,
            onImageSend: (p) async {
              final resizedPath = await resizeImageFile(p, maxDimension: 1280, quality: 85);
              final uri = Uri.parse('${getServerBase()}$uploadEndpoint');
              final req = http.MultipartRequest('POST', uri);
              req.files.add(await http.MultipartFile.fromPath('img', resizedPath));
              final streamed = await req.send();
              final resp = await http.Response.fromStream(streamed);
              final data = json.decode(resp.body) as Map<String, dynamic>;
              final filename = (data['path'] as String?) ?? '';
              if (filename.isEmpty) {
                throw Exception('Upload thất bại');
              }
              final imageUrl = buildUploadUrl(filename);
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectRecipientScreen(imageUrl: imageUrl),
                ),
              );
              if (ok != true) {
                throw Exception('Bạn chưa chọn người nhận');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }
}
