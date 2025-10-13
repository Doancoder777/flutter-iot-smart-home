import 'dart:io';
import 'package:flutter/material.dart';

/// Widget hiển thị avatar thiết bị - có thể là icon hoặc ảnh
class DeviceAvatar extends StatelessWidget {
  final String? icon;
  final String? avatarPath;
  final double size;
  final bool isActive;
  final VoidCallback? onTap;

  const DeviceAvatar({
    Key? key,
    this.icon,
    this.avatarPath,
    this.size = 40,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.green : Colors.grey,
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipOval(child: _buildAvatarContent()),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Nếu có ảnh avatar, hiển thị ảnh
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return Image.file(
        File(avatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Nếu lỗi load ảnh, fallback về icon
          return _buildIconContent();
        },
      );
    }

    // Nếu không có ảnh, hiển thị icon
    return _buildIconContent();
  }

  Widget _buildIconContent() {
    return Center(
      child: Text(icon ?? '⚡', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Widget Avatar lớn cho device detail
class DeviceAvatarLarge extends StatelessWidget {
  final String? icon;
  final String? avatarPath;
  final bool isActive;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const DeviceAvatarLarge({
    Key? key,
    this.icon,
    this.avatarPath,
    this.isActive = false,
    this.onTap,
    this.showEditIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey,
              border: Border.all(
                color: isActive ? Colors.green : Colors.grey.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(child: _buildAvatarContent()),
          ),

          // Edit icon
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Nếu có ảnh avatar, hiển thị ảnh
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return Image.file(
        File(avatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Nếu lỗi load ảnh, fallback về icon
          return _buildIconContent();
        },
      );
    }

    // Nếu không có ảnh, hiển thị icon
    return _buildIconContent();
  }

  Widget _buildIconContent() {
    return Center(
      child: Text(icon ?? '⚡', style: const TextStyle(fontSize: 60)),
    );
  }
}
