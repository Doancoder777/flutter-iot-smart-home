import 'dart:convert';
import 'package:flutter/material.dart';

// Test script để kiểm tra logic MQTT
void main() {
  testMqttLogic();
}

void testMqttLogic() {
  print('🧪 Testing MQTT Logic...');
  
  // Test 1: Device với MQTT config
  final deviceWithMqtt = TestDevice(
    name: 'Test Device',
    mqttConfig: TestMqttConfig(
      broker: 'broker.hivemq.com',
      port: 1883,
      useCustomConfig: true,
    ),
  );
  
  print('Device: ${deviceWithMqtt.name}');
  print('hasCustomMqttConfig: ${deviceWithMqtt.hasCustomMqttConfig}');
  print('Broker: ${deviceWithMqtt.mqttConfig?.broker}');
  print('Port: ${deviceWithMqtt.mqttConfig?.port}');
  print('useCustomConfig: ${deviceWithMqtt.mqttConfig?.useCustomConfig}');
  
  // Test 2: Device không có MQTT config
  final deviceWithoutMqtt = TestDevice(
    name: 'Test Device 2',
    mqttConfig: null,
  );
  
  print('\nDevice: ${deviceWithoutMqtt.name}');
  print('hasCustomMqttConfig: ${deviceWithoutMqtt.hasCustomMqttConfig}');
  print('mqttConfig is null: ${deviceWithoutMqtt.mqttConfig == null}');
  
  // Test 3: JSON Serialization
  print('\n🧪 Testing JSON Serialization...');
  
  final deviceJson = deviceWithMqtt.toJson();
  print('Device JSON: ${jsonEncode(deviceJson)}');
  
  final deviceFromJson = TestDevice.fromJson(deviceJson);
  print('Device from JSON:');
  print('  Name: ${deviceFromJson.name}');
  print('  hasCustomMqttConfig: ${deviceFromJson.hasCustomMqttConfig}');
  print('  Broker: ${deviceFromJson.mqttConfig?.broker}');
  print('  useCustomConfig: ${deviceFromJson.mqttConfig?.useCustomConfig}');
  
  // Test 4: Logic check
  print('\n🧪 Testing Logic...');
  
  if (deviceFromJson.hasCustomMqttConfig) {
    print('✅ SUCCESS: Device has custom MQTT config');
    print('✅ Should use broker: ${deviceFromJson.mqttConfig!.broker}:${deviceFromJson.mqttConfig!.port}');
  } else {
    print('❌ FAILED: Device does not have custom MQTT config');
  }
}

class TestDevice {
  final String name;
  final TestMqttConfig? mqttConfig;
  
  TestDevice({
    required this.name,
    this.mqttConfig,
  });
  
  bool get hasCustomMqttConfig => mqttConfig?.useCustomConfig == true;
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mqttConfig': mqttConfig?.toJson(),
    };
  }
  
  factory TestDevice.fromJson(Map<String, dynamic> json) {
    return TestDevice(
      name: json['name'],
      mqttConfig: json['mqttConfig'] != null 
          ? TestMqttConfig.fromJson(json['mqttConfig']) 
          : null,
    );
  }
}

class TestMqttConfig {
  final String broker;
  final int port;
  final bool useCustomConfig;
  
  TestMqttConfig({
    required this.broker,
    required this.port,
    required this.useCustomConfig,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'broker': broker,
      'port': port,
      'useCustomConfig': useCustomConfig,
    };
  }
  
  factory TestMqttConfig.fromJson(Map<String, dynamic> json) {
    return TestMqttConfig(
      broker: json['broker'],
      port: json['port'],
      useCustomConfig: json['useCustomConfig'],
    );
  }
}

