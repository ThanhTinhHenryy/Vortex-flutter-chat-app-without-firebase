import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Trả về base URL phù hợp với nền tảng đang chạy
String getServerBase() {
  if (kIsWeb) return "http://localhost:1715"; // chạy web cùng máy
  if (Platform.isAndroid) return "http://10.0.2.2:1715"; // Android emulator
  return "http://localhost:1715"; // iOS simulator / desktop
}

const String uploadEndpoint = "/routes/addImage";

String buildUploadUrl(String filename) => "${getServerBase()}/uploads/$filename";