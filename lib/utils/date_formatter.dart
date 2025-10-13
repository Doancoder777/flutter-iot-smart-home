import 'package:intl/intl.dart';

class DateFormatter {
  // Format date to Vietnamese style
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format time
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Format to relative time (e.g., "2 giờ trước", "3 ngày trước")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  // Format time for chart labels (e.g., "14:30", "15:00")
  static String formatChartTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Format date for chart labels (e.g., "12/10", "13/10")
  static String formatChartDate(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  // Format full date time with seconds
  static String formatFullDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  // Format time with seconds
  static String formatTimeWithSeconds(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  // Get day name in Vietnamese
  static String getDayName(DateTime date) {
    const days = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    return days[date.weekday % 7];
  }

  // Get month name in Vietnamese
  static String getMonthName(DateTime date) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[date.month - 1];
  }

  // Format for export filename (e.g., "2024-10-07_14-30-00")
  static String formatForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(date);
  }

  // Parse string to DateTime
  static DateTime? parseDateTime(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Format with "Hôm nay", "Hôm qua"
  static String formatSmartDate(DateTime date) {
    if (isToday(date)) {
      return 'Hôm nay ${formatTime(date)}';
    } else if (isYesterday(date)) {
      return 'Hôm qua ${formatTime(date)}';
    } else {
      return formatDateTime(date);
    }
  }
}
