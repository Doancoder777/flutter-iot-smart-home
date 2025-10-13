import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao diện')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ListView(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('Chế độ sáng'),
                      subtitle: const Text('Giao diện sáng'),
                      value: false,
                      groupValue: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(false);
                      },
                      secondary: const Icon(Icons.light_mode),
                    ),
                    const Divider(),
                    RadioListTile<bool>(
                      title: const Text('Chế độ tối'),
                      subtitle: const Text('Giao diện tối'),
                      value: true,
                      groupValue: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(true);
                      },
                      secondary: const Icon(Icons.dark_mode),
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
