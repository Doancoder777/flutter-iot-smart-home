/// Automation Rules Feature - Public API
///
/// Import this file to use the automation rules feature:
/// ```dart
/// import 'features/automation/automation.dart';
/// ```

// Data Layer
// export 'data/automation_database.dart'; // ❌ REMOVED - Using Firestore now
export 'data/rule_engine_service.dart';

// State Management
export 'providers/automation_provider.dart';

// Screens
export 'screens/automation_rules_screen.dart';
export 'screens/add_edit_rule_screen.dart';
export 'screens/rule_detail_screen.dart';

// Models (re-export from main models)
export '../../models/automation_rule.dart';
