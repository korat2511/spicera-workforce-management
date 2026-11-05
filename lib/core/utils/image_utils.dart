import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static const int maxSizeBytes = 5 * 1024 * 1024;

  static Future<File?> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    return picked == null ? null : File(picked.path);
  }

  static Future<bool> isWithinSizeLimit(File file) async {
    return await file.length() <= maxSizeBytes;
  }
}
