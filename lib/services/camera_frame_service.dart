import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class CameraFrameService {
  /// Convert CameraImage to JPEG bytes
  static Future<Uint8List> cameraImageToJpeg(CameraImage image) async {
    try {
      // Handle different image formats
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420toJpeg(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888toJpeg(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21toJpeg(image);
      }

      throw Exception('Unsupported image format: ${image.format.group}');
    } catch (e) {
      print('Error converting camera image: $e');
      rethrow;
    }
  }

  /// Convert YUV420 to JPEG
  static Uint8List _convertYUV420toJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    // Get planes
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    // Create RGB buffer
    final rgbData = Uint8List(width * height * 3);

    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        rgbData[pixelIndex] = r;
        rgbData[pixelIndex + 1] = g;
        rgbData[pixelIndex + 2] = b;

        pixelIndex += 3;
      }
    }

    // Encode to JPEG
    return _encodeToJpeg(rgbData, width, height);
  }

  /// Convert BGRA8888 to JPEG
  static Uint8List _convertBGRA8888toJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final rgbData = Uint8List(width * height * 3);
    final bgra = image.planes[0].bytes;

    int rgbIndex = 0;
    for (int i = 0; i < bgra.length; i += 4) {
      rgbData[rgbIndex] = bgra[i + 2]; // R
      rgbData[rgbIndex + 1] = bgra[i + 1]; // G
      rgbData[rgbIndex + 2] = bgra[i]; // B
      rgbIndex += 3;
    }

    return _encodeToJpeg(rgbData, width, height);
  }

  /// Convert NV21 to JPEG
  static Uint8List _convertNV21toJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uvPlane = image.planes[1];

    final rgbData = Uint8List(width * height * 3);

    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uvPlane.bytesPerRow + ((x ~/ 2) * 2);

        final yValue = yPlane.bytes[yIndex];
        final vValue = uvPlane.bytes[uvIndex];
        final uValue = uvPlane.bytes[uvIndex + 1];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        rgbData[pixelIndex] = r;
        rgbData[pixelIndex + 1] = g;
        rgbData[pixelIndex + 2] = b;

        pixelIndex += 3;
      }
    }

    return _encodeToJpeg(rgbData, width, height);
  }

  /// Encode RGB data to JPEG
  static Uint8List _encodeToJpeg(Uint8List rgbData, int width, int height) {
    // Create image from RGB data
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbData.buffer,
      format: img.Format.uint8,
      numChannels: 3,
    );

    // Encode to JPEG
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }
}
