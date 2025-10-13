import 'package:flutter/material.dart';

/// Màn hình thông báo
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Danh sách thông báo demo
    final notifications = _getNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // Xóa tất cả thông báo
                _showClearAllDialog(context);
              },
              child: const Text('Xóa tất cả'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận được thông báo khi có cảnh báo',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Xóa thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa thông báo'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () {
                // Khôi phục thông báo
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: _buildNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // Đánh dấu đã đọc
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.warning:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case NotificationType.danger:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case NotificationType.info:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      case NotificationType.success:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // Xóa tất cả
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả thông báo')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  List<NotificationItem> _getNotifications() {
    // Demo data
    return [
      NotificationItem(
        id: '1',
        type: NotificationType.danger,
        title: 'Cảnh báo khí gas',
        message: 'Nồng độ khí gas vượt ngưỡng an toàn (1850 ppm)',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.warning,
        title: 'Cảnh báo bụi',
        message: 'Mức bụi cao (165 µg/m³), nên đóng cửa',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.info,
        title: 'Phát hiện mưa',
        message: 'Hệ thống đã tự động đóng mái che',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.success,
        title: 'Tưới cây hoàn tất',
        message: 'Đã tưới cây tự động, độ ẩm đất đạt 45%',
        time: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
    ];
  }
}

enum NotificationType { warning, danger, info, success }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}
