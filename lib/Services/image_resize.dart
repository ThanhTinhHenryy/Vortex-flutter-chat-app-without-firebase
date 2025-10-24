import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resize và nén ảnh trước khi upload.
/// Trả về đường dẫn file tạm đã được resize (JPEG).
Future<String> resizeImageFile(
  String srcPath, {
  int maxDimension = 1280,
  int quality = 85,
}) async {
  try {
    final srcFile = File(srcPath);
    final bytes = await srcFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Không decode được → trả về file gốc
      return srcPath;
    }

    final int w = decoded.width;
    final int h = decoded.height;

    img.Image output;
    if (w <= maxDimension && h <= maxDimension) {
      // Không cần thu nhỏ, vẫn nén lại để giảm dung lượng
      output = decoded;
    } else {
      final double scale = (w > h ? w : h) / maxDimension;
      final int outW = (w / scale).round();
      final int outH = (h / scale).round();
      output = img.copyResize(
        decoded,
        width: outW,
        height: outH,
        interpolation: img.Interpolation.average,
      );
    }

    // Luôn encode JPEG (giảm dung lượng, tương thích tốt)
    final jpg = img.encodeJpg(output, quality: quality);

    final tempDir = await getTemporaryDirectory();
    final filename = 'resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outPath = p.join(tempDir.path, filename);
    final outFile = File(outPath);
    await outFile.writeAsBytes(jpg, flush: true);
    return outPath;
  } catch (_) {
    // Nếu có lỗi → fallback dùng đường dẫn gốc
    return srcPath;
  }
}