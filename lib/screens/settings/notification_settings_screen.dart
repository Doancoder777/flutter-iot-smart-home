import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật thông báo'),
                      subtitle: const Text('Nhận thông báo từ ứng dụng'),
                      value: settings.settings.notificationsEnabled,
                      onChanged: (value) {
                        settings.setNotificationsEnabled(value);
                      },
                      secondary: const Icon(Icons.notifications),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Cảnh báo khí gas'),
                      subtitle: const Text('Thông báo khi phát hiện khí gas'),
                      value: settings.settings.gasAlertEnabled,
                      onChanged: (value) {
                        settings.setGasAlertEnabled(value);
                      },
                      secondary: const Icon(Icons.warning_amber),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Cảnh báo bụi'),
                      subtitle: const Text('Thông báo khi nồng độ bụi cao'),
                      value: settings.settings.dustAlertEnabled,
                      onChanged: (value) {
                        settings.setDustAlertEnabled(value);
                      },
                      secondary: const Icon(Icons.blur_on),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Cảnh báo mưa'),
                      subtitle: const Text('Thông báo khi phát hiện mưa'),
                      value: settings.settings.rainAlertEnabled,
                      onChanged: (value) {
                        settings.setRainAlertEnabled(value);
                      },
                      secondary: const Icon(Icons.cloud),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Cảnh báo chuyển động'),
                      subtitle: const Text(
                        'Thông báo khi phát hiện chuyển động',
                      ),
                      value: settings.settings.motionAlertEnabled,
                      onChanged: (value) {
                        settings.setMotionAlertEnabled(value);
                      },
                      secondary: const Icon(Icons.sensors),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
