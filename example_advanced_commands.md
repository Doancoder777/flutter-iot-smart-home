# 🚀 Ví dụ mở rộng Smart Home Commands

## 1. 🌀 **Fan Control - Nâng cao**

### Hiện tại (0/1):
```
Topic: smarthome/control/fan
Message: "1"  // Chỉ bật/tắt
```

### Mở rộng với JSON:
```json
// Điều chỉnh tốc độ
{
  "device": "fan",
  "command": "set_speed",
  "value": 3,
  "max_speed": 5
}

// Bật quạt với hẹn giờ
{
  "device": "fan", 
  "command": "turn_on_with_timer",
  "duration_minutes": 30,
  "speed": 2
}

// Chế độ tự động theo nhiệt độ
{
  "device": "fan",
  "command": "auto_mode",
  "trigger_temp": 28,
  "target_temp": 25
}
```

## 2. 💧 **Pump Control - Nâng cao**

### Hiện tại (0/1):
```
Topic: smarthome/control/pump
Message: "1"
```

### Mở rộng với JSON:
```json
// Tưới với lượng nước cụ thể
{
  "device": "pump",
  "command": "water_amount",
  "volume_liters": 5,
  "duration_seconds": 120
}

// Lịch tưới tự động
{
  "device": "pump",
  "command": "schedule",
  "times": ["06:00", "18:00"],
  "duration_minutes": 10,
  "days": ["mon", "wed", "fri"]
}

// Tưới theo độ ẩm đất
{
  "device": "pump",
  "command": "auto_irrigation",
  "soil_threshold": 30,
  "target_moisture": 60
}
```

## 3. 💡 **Lighting - Nâng cao**

### Hiện tại (0/1):
```
Topic: smarthome/control/light_living
Message: "1"
```

### Mở rộng với JSON:
```json
// Điều chỉnh độ sáng
{
  "device": "light_living",
  "command": "dimmer",
  "brightness": 75,
  "fade_duration": 2000
}

// Thay đổi màu sắc (nếu có RGB)
{
  "device": "light_living",
  "command": "set_color",
  "color": {
    "r": 255,
    "g": 100,
    "b": 50
  }
}

// Scene lighting
{
  "command": "scene",
  "name": "movie_night",
  "devices": {
    "light_living": {"brightness": 20, "color": "warm_white"},
    "light_yard": {"state": "off"}
  }
}
```

## 4. 🏠 **Smart Scenarios**

### Với JSON có thể làm:
```json
// Chế độ "Về nhà"
{
  "command": "scenario",
  "name": "arriving_home",
  "actions": [
    {"device": "gate_servo", "command": "open"},
    {"device": "light_yard", "command": "on"},
    {"device": "light_living", "command": "on", "brightness": 60},
    {"device": "fan", "command": "on", "speed": 1}
  ],
  "trigger": "phone_detected"
}

// Chế độ "Đi ngủ"
{
  "command": "scenario", 
  "name": "good_night",
  "actions": [
    {"device": "light_living", "command": "off"},
    {"device": "light_yard", "command": "on", "brightness": 10},
    {"device": "gate_servo", "command": "close"},
    {"device": "pump", "command": "auto_mode", "enable": true}
  ],
  "delay_between_actions": 1000
}

// Chế độ tiết kiệm điện
{
  "command": "energy_saving",
  "level": "high",
  "exceptions": ["security_light"],
  "duration_hours": 8
}
```

## 5. 📊 **Monitoring & Feedback**

### Với JSON có phản hồi chi tiết:
```json
// ESP32 phản hồi trạng thái
{
  "device": "pump",
  "status": "success", 
  "current_state": "on",
  "execution_time": 145,
  "error": null,
  "sensor_readings": {
    "soil_moisture": 45,
    "water_flow": 2.3
  }
}

// Báo lỗi chi tiết
{
  "device": "pump",
  "status": "error",
  "error_code": "WATER_LOW",
  "error_message": "Water tank level below minimum",
  "suggested_action": "refill_tank"
}
```

## 6. 🔧 **Configuration Commands**

```json
// Cập nhật cấu hình thiết bị
{
  "command": "config_update",
  "device": "pump",
  "settings": {
    "max_runtime_minutes": 30,
    "safety_shutoff": true,
    "flow_rate_lpm": 5
  }
}

// Firmware update
{
  "command": "system",
  "action": "update_firmware",
  "version": "1.2.3",
  "url": "https://firmware.smarthouse.com/esp32/v1.2.3.bin"
}
```

---

## 🎯 **Kết luận:**

**Cách đơn giản (0/1):** Phù hợp cho MVP và demo
**Cách JSON:** Cần thiết khi muốn:
- Điều khiển phức tạp (tốc độ, độ sáng, màu sắc)
- Automation và scenarios  
- Monitoring và logging chi tiết
- Scalability cho tương lai

**Khuyến nghị:** Bắt đầu với 0/1, sau đó migrate sang JSON khi cần mở rộng! 🚀