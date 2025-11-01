# 🏠 Smart Home Sensor System - Arduino Guide

## 📊 Sensor Mapping

| Device Code | Sensor Type | Pin | App Display | Unit |
|------------|-------------|-----|-------------|------|
| `DHT22_001` | Temperature | GPIO 4 | 🌡️ Circular Gauge | °C |
| `DHT22_002` | Humidity | GPIO 4 | 💧 Water Droplet | % |
| `SOIL_001` | Soil Moisture | GPIO 34 (A) | 🌱 Plant Health | % |
| `LDR_001` | Light | GPIO 35 (A) | ☀️ Sun with Rays | lux |
| `MQ2_001` | Gas | GPIO 32 (A) | ⚠️ Danger Alert | ppm |
| `GP2Y_001` | Dust | GPIO 33 (A) | 🌫️ AQI Circle | µg/m³ |
| `PIR_001` | Motion | GPIO 27 (D) | 📡 Ripple Waves | 0/1 |
| `RAIN_001` | Rain | GPIO 36 (A) | 🌧️ Rain Drops | level |
| `BMP280_001` | Pressure | I2C (21,22) | 🌡️ Pressure Gauge | hPa |
| `SMOKE_001` | Smoke | GPIO 32 (A) | 💨 Fire Alert | ppm |

## 🎯 Smart Publishing Strategy

### 1. **First Boot**
- All sensors send data immediately
- App displays initial values

### 2. **Normal Operation (Every 5 minutes)**
- All sensors publish automatically
- Keeps app data fresh

### 3. **Change Detection**
Publishes immediately if change exceeds threshold:
- Temperature: ±2°C
- Humidity: ±5%
- Soil Moisture: ±10%
- Light: ±100 lux
- Gas: ±50 ppm
- Dust: ±20 µg/m³
- Rain: ±100 level
- Pressure: ±5 hPa
- Smoke: ±50 ppm

### 4. **Motion Sensor (Special)**
- Only publishes on **state change** (0→1 or 1→0)
- Does NOT publish continuously
- Saves bandwidth and battery

## 🔧 Setup Instructions

### 1. Install Required Libraries
```cpp
// Arduino IDE → Tools → Manage Libraries
- WiFi (built-in)
- PubSubClient by Nick O'Leary
- DHT sensor library by Adafruit
- ArduinoJson by Benoit Blanchon
// Optional:
- Adafruit BMP280 (for pressure sensor)
```

### 2. Configure WiFi & MQTT
Edit `Complete_Smart_Sensor_System.ino`:
```cpp
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// MQTT already configured for HiveMQ Cloud:
// Server: 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud
// Port: 8883 (SSL/TLS)
// User: doancoder
// Password: Abc@123456
```

### 3. Connect Hardware

#### DHT22 (Temperature & Humidity)
```
DHT22 → ESP32
VCC   → 3.3V
GND   → GND
DATA  → GPIO 4
```

#### Soil Moisture
```
Soil Sensor → ESP32
VCC         → 3.3V
GND         → GND
AOUT        → GPIO 34
```

#### LDR (Light)
```
LDR → ESP32
One leg → 3.3V (with 10kΩ resistor to GND)
Junction → GPIO 35
```

#### MQ2 (Gas)
```
MQ2   → ESP32
VCC   → 5V (external power recommended)
GND   → GND
AOUT  → GPIO 32
```

#### PIR (Motion)
```
PIR   → ESP32
VCC   → 5V
GND   → GND
OUT   → GPIO 27
```

#### Rain Sensor
```
Rain Sensor → ESP32
VCC         → 3.3V
GND         → GND
AOUT        → GPIO 36
```

### 4. Upload Code
1. Open `Complete_Smart_Sensor_System.ino` in Arduino IDE
2. Select board: **ESP32 Dev Module**
3. Select port
4. Click **Upload**
5. Open Serial Monitor (115200 baud)

## 📱 App Sensor Configuration

### Create Sensors in App:

1. **Temperature (DHT22_001)**
   - Type: Temperature
   - Device Code: `DHT22_001`
   - Topic: `smart_home/sensors/DHT22_001/state`
   - Display: Circular gauge with needle

2. **Humidity (DHT22_002)**
   - Type: Humidity
   - Device Code: `DHT22_002`
   - Topic: `smart_home/sensors/DHT22_002/state`
   - Display: Water droplet fill

3. **Soil Moisture (SOIL_001)**
   - Type: Soil Moisture
   - Device Code: `SOIL_001`
   - Topic: `smart_home/sensors/SOIL_001/state`
   - Display: Plant health

4. **Light (LDR_001)**
   - Type: Light
   - Device Code: `LDR_001`
   - Topic: `smart_home/sensors/LDR_001/state`
   - Display: Sun with rays

5. **Gas (MQ2_001)**
   - Type: Gas
   - Device Code: `MQ2_001`
   - Topic: `smart_home/sensors/MQ2_001/state`
   - Display: Danger alert with smoke

6. **Dust (GP2Y_001)**
   - Type: Dust
   - Device Code: `GP2Y_001`
   - Topic: `smart_home/sensors/GP2Y_001/state`
   - Display: AQI with particles

7. **Motion (PIR_001)**
   - Type: Motion
   - Device Code: `PIR_001`
   - Topic: `smart_home/sensors/PIR_001/state`
   - Display: Ripple waves

8. **Rain (RAIN_001)**
   - Type: Rain
   - Device Code: `RAIN_001`
   - Topic: `smart_home/sensors/RAIN_001/state`
   - Display: Rain drops falling

9. **Pressure (BMP280_001)**
   - Type: Pressure
   - Device Code: `BMP280_001`
   - Topic: `smart_home/sensors/BMP280_001/state`
   - Display: Pressure gauge

10. **Smoke (SMOKE_001)**
    - Type: Smoke
    - Device Code: `SMOKE_001`
    - Topic: `smart_home/sensors/SMOKE_001/state`
    - Display: Fire alert

## 🧪 Testing

### 1. Serial Monitor Output
```
╔════════════════════════════════════════════╗
║  🏠 SMART HOME SENSOR SYSTEM STARTING...  ║
╚════════════════════════════════════════════╝

🔌 Connecting to WiFi........ ✅ Connected!
📡 IP Address: 192.168.1.100
🔗 Connecting to MQTT broker... ✅ Connected!

✅ System ready! Starting sensor monitoring...

📢 FIRST BOOT - Publishing all sensors...
📡 DHT22_001 → {"value":25.5}
📡 DHT22_002 → {"value":60.0}
📡 SOIL_001 → {"value":45.0}
📡 LDR_001 → {"value":450.0}
📡 MQ2_001 → {"value":120.0}
📡 GP2Y_001 → {"value":85.0}
📡 PIR_001 → {"value":0}
📡 RAIN_001 → {"value":0}
📡 BMP280_001 → {"value":1013.0}
📡 SMOKE_001 → {"value":50.0}
✅ All sensors published!
```

### 2. MQTT Messages (HiveMQ Web Client)
Subscribe to: `smart_home/sensors/#`

You should see:
```json
Topic: smart_home/sensors/DHT22_001/state
Payload: {"value":25.5}

Topic: smart_home/sensors/DHT22_002/state
Payload: {"value":60.0}

... (all sensors)
```

### 3. App Display
- All sensors show custom visualizations
- Health status colors
- Animations (water, sun, smoke, ripples)
- Tap to edit/delete

## 🔧 Troubleshooting

### No WiFi Connection
- Check SSID and password
- Ensure ESP32 is within WiFi range
- Try 2.4GHz network (ESP32 doesn't support 5GHz)

### MQTT Connection Fails
- Check HiveMQ credentials
- Verify internet connection
- Check firewall settings

### Sensors Not Publishing
- Check Serial Monitor for errors
- Verify sensor connections (loose wires?)
- Check pin numbers match code

### App Not Updating
- Verify sensor deviceCode matches Arduino
- Check MQTT topic format
- Ensure app is connected to MQTT (Settings)

## 📈 Next Steps

1. **Add BMP280 Library** for real pressure readings
2. **Calibrate sensors** with known values
3. **Add SSL/TLS** for secure MQTT (ESP32 supports it)
4. **Power optimization** - use deep sleep between readings
5. **Add more sensors** - UV, wind, noise, pH, CO2

## 🎉 Success Criteria

✅ All 10 sensors publish on first boot  
✅ Sensors publish every 5 minutes automatically  
✅ Significant changes trigger immediate publish  
✅ Motion sensor only publishes on state change  
✅ App displays custom UI for each sensor  
✅ Health status colors working  
✅ Animations smooth (water, sun, smoke, etc.)  

**Enjoy your Smart Home! 🏠✨**
