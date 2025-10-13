class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  // Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  // Number validation
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Trường này'} phải là số';
    }
    return null;
  }

  // Integer validation
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Trường này'} phải là số nguyên';
    }
    return null;
  }

  // Range validation
  static String? range(
    String? value, {
    required double min,
    required double max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Trường này'} phải là số';
    }
    if (number < min || number > max) {
      return '${fieldName ?? 'Giá trị'} phải từ $min đến $max';
    }
    return null;
  }

  // IP Address validation
  static String? ipAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Địa chỉ IP không được để trống';
    }
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(value)) {
      return 'Địa chỉ IP không hợp lệ';
    }
    return null;
  }

  // Port validation
  static String? port(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port không được để trống';
    }
    final portNumber = int.tryParse(value);
    if (portNumber == null) {
      return 'Port phải là số';
    }
    if (portNumber < 1 || portNumber > 65535) {
      return 'Port phải từ 1 đến 65535';
    }
    return null;
  }

  // MQTT Topic validation
  static String? mqttTopic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Topic không được để trống';
    }
    if (value.contains('#') && !value.endsWith('#')) {
      return 'Ký tự # chỉ được ở cuối topic';
    }
    if (value.contains('+') &&
        value.split('/').any((part) => part.contains('+') && part != '+')) {
      return 'Ký tự + phải đứng độc lập giữa các /';
    }
    return null;
  }

  // Device name validation
  static String? deviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên thiết bị không được để trống';
    }
    if (value.length < 2) {
      return 'Tên thiết bị phải có ít nhất 2 ký tự';
    }
    if (value.length > 50) {
      return 'Tên thiết bị không được quá 50 ký tự';
    }
    return null;
  }

  // Phone number validation (Vietnam)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}
