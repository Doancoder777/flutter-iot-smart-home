# 📱 Sensor Query UI Example

## 🎯 Cách hiển thị sensor query (CHỈ DATA, không text response)

### 📊 Cấu trúc Response mới

```dart
class CommandResult {
  final bool success;
  final ResponseType responseType; // deviceControl hoặc sensorQuery
  
  // Device Control fields
  final String? deviceKeyName;
  final String? action;
  final int? value;
  
  // Sensor Query fields - CHỈ DATA, KHÔNG TEXT
  final String? sensorType;    // 'temperature', 'humidity', 'rain', ...
  final dynamic sensorValue;   // Giá trị sensor (số hoặc bool)
  
  final String? error;
}
```

---

## ✅ CÁCH XỬ LÝ SENSOR QUERY Ở UI

### 1️⃣ Kiểm tra response type

```dart
final result = await aiVoiceService.processVoiceCommand(
  command,
  sensorData: currentSensorData, // Truyền sensor data
);

if (result.success) {
  if (result.responseType == ResponseType.sensorQuery) {
    // Xử lý SENSOR QUERY
    _displaySensorResult(result);
  } else if (result.responseType == ResponseType.deviceControl) {
    // Xử lý DEVICE CONTROL
    _executeDeviceControl(result);
  }
}
```

---

### 2️⃣ Format và hiển thị sensor value

```dart
void _displaySensorResult(CommandResult result) {
  final sensorType = result.sensorType!;
  final value = result.sensorValue;
  
  String displayText;
  
  switch (sensorType) {
    case 'temperature':
      displayText = 'Nhiệt độ: ${value.toStringAsFixed(1)}°C';
      break;
      
    case 'humidity':
      displayText = 'Độ ẩm: ${value.toStringAsFixed(0)}%';
      break;
      
    case 'rain':
      displayText = value == 1 ? 'Đang mưa' : 'Không mưa';
      break;
      
    case 'gas':
      displayText = 'Khí gas: ${value.toStringAsFixed(0)} ppm';
      break;
      
    case 'dust':
      displayText = 'Bụi PM2.5: ${value.toStringAsFixed(1)} µg/m³';
      break;
      
    case 'light':
      displayText = 'Ánh sáng: ${value.toStringAsFixed(0)} lux';
      break;
      
    case 'soil':
      displayText = 'Độ ẩm đất: ${value.toStringAsFixed(0)}%';
      break;
      
    case 'motion':
      displayText = value ? 'Có chuyển động' : 'Không có chuyển động';
      break;
      
    case 'all':
      // Value sẽ là object với nhiều sensors
      displayText = _formatAllSensors(value);
      break;
      
    default:
      displayText = 'Sensor: $sensorType = $value';
  }
  
  // Hiển thị bằng text hoặc TTS
  _showSensorDialog(displayText);
  _speakText(displayText);
}
```

---

### 3️⃣ Format "all sensors"

```dart
String _formatAllSensors(Map<String, dynamic> allValues) {
  final parts = <String>[];
  
  if (allValues['temperature'] != null) {
    parts.add('Nhiệt độ ${allValues['temperature']}°C');
  }
  if (allValues['humidity'] != null) {
    parts.add('độ ẩm ${allValues['humidity']}%');
  }
  if (allValues['rain'] != null) {
    parts.add(allValues['rain'] == 1 ? 'có mưa' : 'không mưa');
  }
  
  return parts.join(', ');
}
```

---

### 4️⃣ Hiển thị UI với icon và màu

```dart
void _showSensorDialog(String text) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.sensors, color: Colors.blue),
          SizedBox(width: 8),
          Text('Cảm biến'),
        ],
      ),
      content: Text(
        text,
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

### 5️⃣ Text-to-Speech (TTS)

```dart
Future<void> _speakText(String text) async {
  await flutterTts.setLanguage('vi-VN');
  await flutterTts.speak(text);
}
```

---

## 🧪 Test Cases

### ✅ Device Control (KHÔNG CẦN TEXT RESPONSE)

```dart
// User: "Bật đèn phòng ngủ"
CommandResult(
  success: true,
  responseType: ResponseType.deviceControl,
  deviceKeyName: 'led_bedroom',
  action: 'on',
)

// ❌ KHÔNG TRẢ VỀ TEXT: "Đã bật đèn phòng ngủ"
// ✅ UI tự format: "Đã bật đèn phòng ngủ"
```

### ✅ Sensor Query - Temperature

```dart
// User: "Nhiệt độ bao nhiêu?"
CommandResult(
  success: true,
  responseType: ResponseType.sensorQuery,
  sensorType: 'temperature',
  sensorValue: 28.5,
)

// UI format: "Nhiệt độ: 28.5°C"
// TTS: "Nhiệt độ 28.5 độ C"
```

### ✅ Sensor Query - Rain

```dart
// User: "Trời có mưa không?"
CommandResult(
  success: true,
  responseType: ResponseType.sensorQuery,
  sensorType: 'rain',
  sensorValue: 0,
)

// UI format: "Không mưa"
// TTS: "Không mưa"
```

### ✅ Sensor Query - All

```dart
// User: "Tình trạng các cảm biến?"
CommandResult(
  success: true,
  responseType: ResponseType.sensorQuery,
  sensorType: 'all',
  sensorValue: {
    'temperature': 28.5,
    'humidity': 65.0,
    'rain': 0,
  },
)

// UI format: "Nhiệt độ 28.5°C, độ ẩm 65%, không mưa"
```

---

## 💰 Token Savings

### Trước (Text Response)

```json
{
  "success": true,
  "response_type": "sensor_query",
  "text_response": "Nhiệt độ hiện tại 28°C, hơi nóng. Độ ẩm 65%, mức bình thường."
}
```

**Token cost:** ~50 tokens (AI phải tạo câu văn)

---

### Sau (Data Only)

```json
{
  "success": true,
  "response_type": "sensor_query",
  "sensor_type": "temperature",
  "sensor_value": 28.0
}
```

**Token cost:** ~20 tokens (CHỈ TRẢ DATA)

→ **Tiết kiệm 60% tokens** ✅

---

## 🎨 UI Component Example

```dart
class SensorResultCard extends StatelessWidget {
  final String sensorType;
  final dynamic value;
  
  @override
  Widget build(BuildContext context) {
    final info = _getSensorInfo(sensorType, value);
    
    return Card(
      child: ListTile(
        leading: Icon(info.icon, color: info.color),
        title: Text(info.label),
        subtitle: Text(info.valueText, style: TextStyle(fontSize: 18)),
      ),
    );
  }
  
  SensorInfo _getSensorInfo(String type, dynamic value) {
    switch (type) {
      case 'temperature':
        return SensorInfo(
          icon: Icons.thermostat,
          color: Colors.red,
          label: 'Nhiệt độ',
          valueText: '${value.toStringAsFixed(1)}°C',
        );
      case 'humidity':
        return SensorInfo(
          icon: Icons.water_drop,
          color: Colors.blue,
          label: 'Độ ẩm',
          valueText: '${value.toStringAsFixed(0)}%',
        );
      // ... other cases
    }
  }
}
```

---

## 🚀 Summary

### ❌ Cách CŨ (Lãng phí token)
- AI tạo text response dài dòng
- App chỉ hiển thị text đó
- Token cost cao

### ✅ Cách MỚI (Tối ưu)
- AI CHỈ TRẢ DATA (sensor_type + sensor_value)
- App tự format và hiển thị
- Token cost thấp (60% savings)

### 🎯 Benefits
✅ Tiết kiệm 60% API token costs  
✅ Response nhanh hơn (ít data cần parse)  
✅ UI linh hoạt format theo ý muốn  
✅ Dễ localization (đa ngôn ngữ)  
✅ Consistent formatting  
