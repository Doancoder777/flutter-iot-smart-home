import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Script để cập nhật device hiện tại thành servo 360°
  final prefs = await SharedPreferences.getInstance();

  // Lấy danh sách devices
  final devicesJson = prefs.getString('user_devices_100923012805851518192');
  if (devicesJson != null) {
    final List<dynamic> devicesList = jsonDecode(devicesJson);

    // Cập nhật device "t1" thành servo 360°
    for (int i = 0; i < devicesList.length; i++) {
      final device = devicesList[i];
      if (device['name'] == 't1' && device['type'] == 'servo') {
        print('Found device t1, updating to servo 360°...');
        device['isServo360'] = true;
        devicesList[i] = device;
        break;
      }
    }

    // Lưu lại
    await prefs.setString(
      'user_devices_100923012805851518192',
      jsonEncode(devicesList),
    );
    print('Updated device t1 to servo 360°');
  } else {
    print('No devices found');
  }
}
