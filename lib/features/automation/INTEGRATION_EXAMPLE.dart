// /// INTEGRATION EXAMPLE
// /// 
// /// Đây là ví dụ cách tích hợp Automation Rules với MQTT service
// /// Copy code này vào main.dart và mqtt_service.dart

// // ============================================================================
// // FILE: lib/main.dart
// // ============================================================================

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'features/automation/providers/automation_provider.dart';
// import 'features/automation/data/automation_database.dart';
// import 'services/mqtt_service.dart';
// import 'models/automation_rule.dart' hide Action; // Hide to avoid conflict

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize automation database
//   final automationDb = AutomationDatabase();
//   await automationDb.database;
//   print('✅ Automation Database initialized');
  
//   runApp(
//     MultiProvider(
//       providers: [
//         // Existing providers...
//         ChangeNotifierProvider(create: (_) => MqttService()),
        
//         // ⭐ New: Automation Provider
//         ChangeNotifierProxyProvider<MqttService, AutomationProvider>(
//           create: (context) => AutomationProvider(
//             onRuleTriggered: (ruleId, actions) {
//               // Get MQTT service from context
//               final mqttService = context.read<MqttService>();
//               _executeAutomationActions(mqttService, ruleId, actions);
//             },
//           )..loadRules(),
//           update: (context, mqttService, previous) {
//             // Update callback if needed
//             return previous ?? AutomationProvider();
//           },
//         ),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// /// Execute automation actions via MQTT
// void _executeAutomationActions(
//   MqttService mqttService,
//   String ruleId,
//   List<model.Action> actions,
// ) {
//   print('🎯 Executing automation rule: $ruleId');
  
//   for (final action in actions) {
//     print('  → ${action.deviceId}: ${action.action}');
    
//     try {
//       switch (action.action.toLowerCase()) {
//         case 'turn_on':
//           mqttService.publishDeviceCommand(action.deviceId, 'ON');
//           break;
          
//         case 'turn_off':
//           mqttService.publishDeviceCommand(action.deviceId, 'OFF');
//           break;
          
//         case 'toggle':
//           // Get current state and toggle
//           final currentState = mqttService.getDeviceState(action.deviceId);
//           final newState = currentState ? 'OFF' : 'ON';
//           mqttService.publishDeviceCommand(action.deviceId, newState);
//           break;
          
//         case 'set_value':
//           if (action.value != null) {
//             mqttService.publishDeviceCommand(
//               action.deviceId,
//               action.value.toString(),
//             );
//           }
//           break;
          
//         default:
//           print('⚠️ Unknown action: ${action.action}');
//       }
      
//       // Optional: Show notification
//       // _showNotification('Rule Triggered', 'Executed ${action.action} on ${action.deviceId}');
      
//     } catch (e) {
//       print('❌ Error executing action: $e');
//     }
//   }
// }

// // ============================================================================
// // FILE: lib/services/mqtt_service.dart (ADDITIONS)
// // ============================================================================

// class MqttService extends ChangeNotifier {
//   // ... existing code ...
  
//   SensorData? _latestSensorData;
  
//   /// Handle incoming MQTT sensor data
//   void _onSensorDataReceived(String topic, String payload) {
//     try {
//       final json = jsonDecode(payload);
//       final sensorData = SensorData.fromJson(json);
      
//       _latestSensorData = sensorData;
//       notifyListeners();
      
//       // ⭐ NEW: Trigger automation rules evaluation
//       _evaluateAutomationRules(sensorData);
      
//     } catch (e) {
//       print('❌ Error parsing sensor data: $e');
//     }
//   }
  
//   /// Evaluate automation rules against sensor data
//   void _evaluateAutomationRules(SensorData sensorData) {
//     // Get automation provider from context (if available)
//     // Note: You might need to pass BuildContext or use a global key
    
//     // Option 1: Using callback pattern
//     if (_automationCallback != null) {
//       _automationCallback!(sensorData);
//     }
    
//     // Option 2: Using GetIt or service locator
//     // final provider = GetIt.I<AutomationProvider>();
//     // provider.evaluateRules(sensorData);
//   }
  
//   // Callback for automation evaluation
//   Function(SensorData)? _automationCallback;
  
//   void setAutomationCallback(Function(SensorData) callback) {
//     _automationCallback = callback;
//   }
  
//   /// Publish device command via MQTT
//   void publishDeviceCommand(String deviceId, String command) {
//     final topic = 'home/device/$deviceId/command';
//     publishMessage(topic, command);
//     print('📤 MQTT: $topic → $command');
//   }
  
//   /// Get device state (mock - replace with actual logic)
//   bool getDeviceState(String deviceId) {
//     // TODO: Implement actual state tracking
//     return false;
//   }
// }

// // ============================================================================
// // ALTERNATIVE: Using BuildContext in Widget Tree
// // ============================================================================

// class HomePage extends StatefulWidget {
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
    
//     // Setup automation callback when MQTT service receives data
//     final mqttService = context.read<MqttService>();
//     final automationProvider = context.read<AutomationProvider>();
    
//     mqttService.setAutomationCallback((sensorData) {
//       automationProvider.evaluateRules(sensorData);
//     });
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // ... your UI
//     );
//   }
// }

// // ============================================================================
// // NAVIGATION: Add to Settings or Menu
// // ============================================================================

// ListTile(
//   leading: const Icon(Icons.auto_awesome),
//   title: const Text('Automation Rules'),
//   subtitle: const Text('Create smart home automations'),
//   trailing: const Icon(Icons.chevron_right),
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const AutomationRulesScreen(),
//       ),
//     );
//   },
// ),

// // ============================================================================
// // OPTIONAL: Notification Service Integration
// // ============================================================================

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static Future<void> showRuleTriggeredNotification(
//     String ruleId,
//     String ruleName,
//   ) async {
//     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
//     const androidDetails = AndroidNotificationDetails(
//       'automation_channel',
//       'Automation Rules',
//       channelDescription: 'Notifications for automation rule triggers',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
    
//     const details = NotificationDetails(android: androidDetails);
    
//     await flutterLocalNotificationsPlugin.show(
//       ruleId.hashCode,
//       'Automation Triggered',
//       'Rule "$ruleName" has been executed',
//       details,
//     );
//   }
// }

// // Then in _executeAutomationActions:
// // await NotificationService.showRuleTriggeredNotification(ruleId, ruleName);
