import 'package:flutter/material.dart';

/// Widget trang onboarding
class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hình ảnh
          Icon(_getIcon(imagePath), size: 200, color: Colors.white),
          const SizedBox(height: 60),

          // Tiêu đề
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Mô tả
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String path) {
    switch (path) {
      case 'welcome':
        return Icons.home;
      case 'sensors':
        return Icons.sensors;
      case 'devices':
        return Icons.devices;
      case 'automation':
        return Icons.auto_awesome;
      default:
        return Icons.info;
    }
  }
}
