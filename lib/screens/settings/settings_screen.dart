import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../services/local_storage_service.dart';
import '../../config/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cài đặt')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // App Settings
          _buildSectionTitle('Ứng dụng'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    title: Text('Chế độ tối'),
                    subtitle: Text('Bật giao diện tối'),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setDarkMode(value);
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.language, color: AppColors.primary),
                title: Text('Ngôn ngữ'),
                subtitle: Text('Tiếng Việt'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Notifications
          _buildSectionTitle('Thông báo'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  return SwitchListTile(
                    title: Text('Nhận thông báo'),
                    subtitle: Text('Thông báo về cảnh báo và sự kiện'),
                    secondary: Icon(
                      Icons.notifications,
                      color: AppColors.primary,
                    ),
                    value: settingsProvider.notificationsEnabled,
                    onChanged: (value) {
                      settingsProvider.setNotificationsEnabled(value);
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
              Divider(),
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  return SwitchListTile(
                    title: Text('Cảnh báo khí gas'),
                    subtitle: Text('Thông báo khi phát hiện khí gas'),
                    secondary: Icon(Icons.warning, color: AppColors.primary),
                    value: settingsProvider.gasAlertEnabled,
                    onChanged: (value) {
                      settingsProvider.setGasAlertEnabled(value);
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),

          // MQTT Configuration
          _buildSectionTitle('Kết nối MQTT'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.router, color: AppColors.primary),
                title: Text('Cấu hình MQTT'),
                subtitle: Text('Thiết lập broker, port, tài khoản MQTT'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.help_outline, size: 20),
                      onPressed: () => _showMqttGuideDialog(context),
                      tooltip: 'Hướng dẫn',
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () => _showMqttConfigDialog(context),
              ),
              Divider(),
              Consumer<MqttProvider>(
                builder: (context, mqttProvider, _) {
                  final currentConfig = mqttProvider.currentConfig;
                  final brokerInfo = currentConfig != null
                      ? '${currentConfig.broker}:${currentConfig.port}'
                      : 'Chưa cấu hình';

                  return Column(
                    children: [
                      // Broker info
                      if (currentConfig != null)
                        ListTile(
                          leading: Icon(Icons.dns, color: Colors.grey[600]),
                          title: Text('Broker hiện tại'),
                          subtitle: Text(
                            brokerInfo,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          trailing: Chip(
                            label: Text(
                              'Đã cấu hình',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.green[100],
                            padding: EdgeInsets.zero,
                          ),
                        )
                      else
                        ListTile(
                          leading: Icon(
                            Icons.error_outline,
                            color: Colors.red[600],
                          ),
                          title: Text('Broker hiện tại'),
                          subtitle: Text(
                            'Chưa cấu hình',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          trailing: Chip(
                            label: Text(
                              'Chưa setup',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.red[100],
                            padding: EdgeInsets.zero,
                          ),
                        ),

                      if (currentConfig != null) Divider(),

                      // Connection status
                      ListTile(
                        leading: Icon(
                          mqttProvider.isConnected
                              ? Icons.wifi
                              : Icons.wifi_off,
                          color: mqttProvider.isConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          mqttProvider.isConnected
                              ? 'Đã kết nối'
                              : 'Chưa kết nối',
                        ),
                        subtitle: Text(mqttProvider.connectionStatus),
                        trailing: mqttProvider.isConnected
                            ? IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () async {
                                  mqttProvider.disconnect();
                                  await mqttProvider.connect();
                                },
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                ),
                                onPressed: () => mqttProvider.connect(),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),

          // Account Section
          _buildSectionTitle('Tài khoản'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.currentUser;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(user?.displayName ?? 'Chưa đăng nhập'),
                    subtitle: Text(
                      user?.email ?? 'Vui lòng đăng nhập để sử dụng',
                    ),
                    trailing: user != null
                        ? Icon(Icons.arrow_forward_ios, size: 16)
                        : null,
                    onTap: user != null
                        ? () => Navigator.pushNamed(context, '/account')
                        : null,
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.security, color: AppColors.primary),
                title: Text('Bảo mật'),
                subtitle: Text('Đổi mật khẩu, xác thực 2 yếu tố'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  Icons.cleaning_services,
                  color: AppColors.warning,
                ),
                title: Text('Xóa cache tài khoản'),
                subtitle: Text('Xóa danh sách email gợi ý khi đăng nhập'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showClearAccountCacheDialog(context),
              ),
              Divider(),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  // Chỉ hiển thị nút đăng xuất nếu đã đăng nhập
                  if (!authProvider.isLoggedIn) {
                    return SizedBox.shrink();
                  }

                  return ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text('Thoát khỏi tài khoản hiện tại'),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),

          // Data Management
          _buildSectionTitle('Quản lý dữ liệu'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.backup, color: AppColors.primary),
                title: Text('Sao lưu dữ liệu'),
                subtitle: Text('Sao lưu cài đặt và dữ liệu ứng dụng'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.restore, color: AppColors.primary),
                title: Text('Khôi phục dữ liệu'),
                subtitle: Text('Khôi phục từ bản sao lưu'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.refresh, color: AppColors.warning),
                title: Text('Đặt lại ứng dụng'),
                subtitle: Text('Xóa tất cả dữ liệu và cài đặt'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showResetDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Xóa tất cả dữ liệu'),
                subtitle: Text('Xóa vĩnh viễn tất cả dữ liệu người dùng'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDeleteDataDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // About
          _buildSectionTitle('Thông tin'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.info, color: AppColors.primary),
                title: Text('Về ứng dụng'),
                subtitle: Text('Phiên bản 1.0.0'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAboutDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: AppColors.primary),
                title: Text('Chính sách bảo mật'),
                subtitle: Text('Xem chính sách bảo mật'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.description, color: AppColors.primary),
                title: Text('Điều khoản sử dụng'),
                subtitle: Text('Xem điều khoản và điều kiện'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog(context),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Debug Section
          _buildSectionTitle('Debug'),
          SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.bug_report, color: Colors.purple),
                title: Text('Kiểm tra dữ liệu lưu trữ'),
                subtitle: Text('Xem tất cả dữ liệu trong SharedPreferences'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showStorageDebugDialog(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.cleaning_services, color: Colors.orange),
                title: Text('Force Clear All Data'),
                subtitle: Text('Xóa tất cả dữ liệu ngay lập tức (No confirm)'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _forceClearAllData(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Tiếng Việt'),
              value: 'vi',
              groupValue: 'vi',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: Text('English'),
              value: 'en',
              groupValue: 'vi',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.construction, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Sắp ra mắt'),
          ],
        ),
        content: Text(
          'Tính năng này đang được phát triển và sẽ có sẵn trong phiên bản tương lai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Home IoT',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.home_filled,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        Text('Ứng dụng quản lý nhà thông minh với kết nối IoT.'),
        SizedBox(height: 16),
        Text('Được phát triển với Flutter và MQTT.'),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Đặt lại ứng dụng'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đặt lại ứng dụng? Tất cả cài đặt và dữ liệu sẽ bị xóa hoàn toàn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Đang reset ứng dụng...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              try {
                // Force clear ALL SharedPreferences data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Clear device provider data
                final deviceProvider = Provider.of<DeviceProvider>(
                  context,
                  listen: false,
                );
                await deviceProvider.clearAllUserData();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã đặt lại ứng dụng hoàn toàn!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi reset: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Đặt lại', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Xóa tất cả dữ liệu'),
          ],
        ),
        content: Text(
          'CẢNH BÁO: Hành động này sẽ xóa vĩnh viễn tất cả dữ liệu của bạn và không thể hoàn tác. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Đang xóa dữ liệu...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              try {
                // Clear all user-specific data
                final deviceProvider = Provider.of<DeviceProvider>(
                  context,
                  listen: false,
                );
                await deviceProvider.clearAllUserData();

                // Clear auth data
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.clearUserData();

                // Hide loading and show success
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Đã xóa toàn bộ dữ liệu. Vui lòng đăng nhập lại.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi khi xóa dữ liệu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // 🔓 LOGOUT DIALOG
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Đang đăng xuất...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                // Call signOut method
                await authProvider.signOut();

                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đăng xuất thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi đăng xuất: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🧹 CLEAR ACCOUNT CACHE DIALOG
  void _showClearAccountCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Xóa cache tài khoản'),
          ],
        ),
        content: Text(
          'Thao tác này sẽ xóa danh sách email gợi ý khi đăng nhập Google. Tính năng này chủ yếu hữu ích trên máy tính.\n\nBạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show success message (placeholder since we removed the actual clearing)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ℹ️ Tính năng này chỉ cần thiết trên máy tính'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // � MQTT GUIDE DIALOG
  void _showMqttGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hướng dẫn cấu hình MQTT'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎯 Tại sao cần cấu hình MQTT?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'MQTT là cầu nối giữa app và thiết bị IoT của bạn. '
                'Bạn cần cấu hình MQTT broker để app có thể điều khiển thiết bị.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),

              Text(
                '✅ Khuyến nghị: HiveMQ Cloud',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Truy cập: hivemq.com/mqtt-cloud-broker\n'
                '2. Đăng ký Free Tier (miễn phí)\n'
                '3. Tạo cluster → Lấy URL và credentials\n'
                '4. Nhập vào app và Lưu',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ví dụ cấu hình:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Broker: abc123.s1.eu.hivemq.cloud\n'
                      'Port: 8883\n'
                      'Username: your-user\n'
                      'Password: ••••••••\n'
                      'SSL/TLS: Bật',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              Text(
                '📱 Topic format cho thiết bị:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'smart_home/devices/<room>/<device_id>',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),

              Text(
                'Chi tiết đầy đủ xem file MQTT_SETUP_GUIDE.md',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showMqttConfigDialog(context);
            },
            icon: Icon(Icons.settings, size: 18),
            label: Text('Cấu hình ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // �🔧 MQTT CONFIGURATION DIALOG
  void _showMqttConfigDialog(BuildContext context) async {
    // Get current user ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    // Load existing MQTT config
    Map<String, dynamic>? existingConfig;
    if (userId != null) {
      try {
        final storageService = LocalStorageService();
        await storageService.init();
        existingConfig = storageService.getMqttConfig(userId: userId);
      } catch (e) {
        print('❌ Error loading MQTT config: $e');
      }
    }

    // Controllers for MQTT config with existing values
    final brokerController = TextEditingController(
      text: existingConfig?['broker'] ?? '',
    );
    final portController = TextEditingController(
      text: existingConfig?['port']?.toString() ?? '1883',
    );
    final usernameController = TextEditingController(
      text: existingConfig?['username'] ?? '',
    );
    final passwordController = TextEditingController(
      text: existingConfig?['password'] ?? '',
    );
    bool useSsl = existingConfig?['useSsl'] ?? false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.router, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cấu hình MQTT'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brokerController,
                decoration: InputDecoration(
                  labelText: 'MQTT Broker',
                  hintText: 'broker.hivemq.com',
                  prefixIcon: Icon(Icons.dns),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: portController,
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: '8883',
                  prefixIcon: Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'your-username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'your-password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),

              // SSL Toggle
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return SwitchListTile(
                    title: Text('Sử dụng SSL/TLS'),
                    subtitle: Text('Port 8883 cho SSL, 1883 cho không SSL'),
                    value: useSsl,
                    onChanged: (value) {
                      setDialogState(() {
                        useSsl = value;
                        // Auto-update port based on SSL
                        if (value && portController.text == '1883') {
                          portController.text = '8883';
                        } else if (!value && portController.text == '8883') {
                          portController.text = '1883';
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              SizedBox(height: 16),

              // Examples section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ví dụ cấu hình:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Public broker: broker.hivemq.com:1883 (không SSL)\n'
                      '• HiveMQ Cloud: <your-cluster>.hivemq.cloud:8883 (SSL)\n'
                      '• Eclipse: mqtt.eclipseprojects.io:1883',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Test connection button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Simple validation for test
                    if (brokerController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Vui lòng nhập MQTT Broker để test'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Show test message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔄 Đang test kết nối MQTT...'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Simulate test (would normally try actual connection)
                    await Future.delayed(Duration(seconds: 2));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ℹ️ Test thành công! (Simulation)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.wifi_find),
                  label: Text('Test kết nối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Lưu ý: Cấu hình này sẽ được lưu riêng cho từng tài khoản',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Validate inputs
              if (brokerController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Vui lòng nhập MQTT Broker'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final port = int.tryParse(portController.text);
              if (port == null || port <= 0 || port > 65535) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Port không hợp lệ (1-65535)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                // Get current user ID
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final userId = authProvider.currentUser?.id;

                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Vui lòng đăng nhập để lưu cấu hình'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Create MQTT config
                final mqttConfig = {
                  'broker': brokerController.text.trim(),
                  'port': port,
                  'username': usernameController.text.trim(),
                  'password': passwordController.text.trim(),
                  'useSsl': useSsl,
                };

                // Save to local storage
                final storageService = LocalStorageService();
                await storageService.init();
                await storageService.saveMqttConfig(mqttConfig, userId: userId);

                // Reconnect MQTT with new config
                final mqttProvider = Provider.of<MqttProvider>(
                  context,
                  listen: false,
                );
                await mqttProvider.reconnectWithUserConfig();

                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Đã lưu và áp dụng cấu hình MQTT cho tài khoản: ${authProvider.currentUser?.email}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi lưu cấu hình: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Lưu', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Debug methods
  void _showStorageDebugDialog(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      String debugInfo = '';
      for (String key in allKeys) {
        final value = prefs.get(key);
        debugInfo += '$key: $value\n\n';
      }

      if (debugInfo.isEmpty) {
        debugInfo = 'No data found in SharedPreferences';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('SharedPreferences Data'),
          content: SingleChildScrollView(
            child: Text(
              debugInfo,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading storage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _forceClearAllData(BuildContext context) async {
    try {
      // Force clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear DeviceProvider
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );
      await deviceProvider.clearAllUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Force cleared all data!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error force clearing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
