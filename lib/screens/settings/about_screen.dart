import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Về ứng dụng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Smart Home IoT',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phiên bản 3.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.developer_mode),
                  title: const Text('Phát triển bởi'),
                  subtitle: const Text('Sinh viên Đồ Án Flutter IOT'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Công nghệ'),
                  subtitle: const Text('Flutter + ESP32 + MQTT'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('Vi điều khiển'),
                  subtitle: const Text('ESP32 38-pin'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sensors),
                  title: const Text('Cảm biến'),
                  subtitle: const Text('DHT22, MQ-2, GP2Y1010AU0F, PIR'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Giấy phép'),
                  subtitle: const Text('MIT License'),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Chính sách bảo mật'),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Điều khoản sử dụng'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
