import 'package:camera/camera.dart';
import 'package:chat_app_flutter/Screens/CameraView.dart';
import 'package:chat_app_flutter/Screens/VideoView.dart';
import 'package:flutter/material.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraView(
            path: shot.path,
            onImageSend: (p) async {},
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
