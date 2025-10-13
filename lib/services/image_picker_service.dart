import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ thư viện hoặc camera
  static Future<String?> pickDeviceAvatar(BuildContext context) async {
    try {
      // Hiển thị dialog chọn nguồn ảnh
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Chọn ảnh
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Lưu ảnh vào thư mục app
      final savedPath = await _saveImageToAppDirectory(image);
      return savedPath;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Hiển thị dialog chọn nguồn ảnh
  static Future<ImageSource?> _showImageSourceDialog(
    BuildContext context,
  ) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn nguồn ảnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Thư viện ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  /// Lưu ảnh vào thư mục app
  static Future<String> _saveImageToAppDirectory(XFile image) async {
    // Lấy thư mục documents của app
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String deviceAvatarsDir = path.join(appDocDir.path, 'device_avatars');

    // Tạo thư mục nếu chưa có
    final Directory avatarsDirectory = Directory(deviceAvatarsDir);
    if (!await avatarsDirectory.exists()) {
      await avatarsDirectory.create(recursive: true);
    }

    // Tạo tên file unique
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = path.extension(image.path);
    final String fileName = 'device_avatar_$timestamp$extension';
    final String savedPath = path.join(deviceAvatarsDir, fileName);

    // Copy file
    final File imageFile = File(image.path);
    await imageFile.copy(savedPath);

    return savedPath;
  }

  /// Xóa ảnh avatar cũ
  static Future<void> deleteOldAvatar(String? avatarPath) async {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        final File oldFile = File(avatarPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting old avatar: $e');
      }
    }
  }

  /// Kiểm tra xem file ảnh có tồn tại không
  static Future<bool> avatarExists(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return false;

    try {
      final File file = File(avatarPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Cleanup - xóa các ảnh avatar không sử dụng
  static Future<void> cleanupUnusedAvatars(List<String> usedAvatarPaths) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String deviceAvatarsDir = path.join(
        appDocDir.path,
        'device_avatars',
      );
      final Directory avatarsDirectory = Directory(deviceAvatarsDir);

      if (!await avatarsDirectory.exists()) return;

      final List<FileSystemEntity> files = await avatarsDirectory
          .list()
          .toList();

      for (final file in files) {
        if (file is File) {
          final String filePath = file.path;
          if (!usedAvatarPaths.contains(filePath)) {
            await file.delete();
            debugPrint('Deleted unused avatar: $filePath');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
