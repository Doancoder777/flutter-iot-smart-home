import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../../../models/automation_rule.dart';

/// Database service for storing automation rules persistently
class AutomationDatabase {
  static final AutomationDatabase _instance = AutomationDatabase._internal();
  factory AutomationDatabase() => _instance;
  AutomationDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'automation_rules.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE automation_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        enabled INTEGER NOT NULL,
        conditions TEXT NOT NULL,
        actions TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_triggered TEXT,
        trigger_count INTEGER DEFAULT 0,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rule_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rule_id TEXT NOT NULL,
        triggered_at TEXT NOT NULL,
        sensor_values TEXT,
        actions_executed TEXT,
        FOREIGN KEY (rule_id) REFERENCES automation_rules (id) ON DELETE CASCADE
      )
    ''');

    print('✅ Automation Database: Tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
    if (oldVersion < 2) {
      // Example: await db.execute('ALTER TABLE...');
    }
  }

  // ════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Insert a new automation rule
  Future<int> insertRule(AutomationRule rule) async {
    final db = await database;

    final data = {
      'id': rule.id,
      'name': rule.name,
      'enabled': rule.enabled ? 1 : 0,
      'conditions': jsonEncode(rule.conditions.map((e) => e.toJson()).toList()),
      'startActions': jsonEncode(
        rule.startActions.map((e) => e.toJson()).toList(),
      ),
      'endActions': jsonEncode(rule.endActions.map((e) => e.toJson()).toList()),
      'hasEndActions': rule.hasEndActions,
      'created_at': rule.createdAt.toIso8601String(),
      'last_triggered': rule.lastTriggered?.toIso8601String(),
      'trigger_count': 0,
    };

    return await db.insert(
      'automation_rules',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all automation rules
  Future<List<AutomationRule>> getAllRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'automation_rules',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _ruleFromMap(map)).toList();
  }

  /// Get a single rule by ID
  Future<AutomationRule?> getRule(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _ruleFromMap(maps.first);
  }

  /// Get only enabled rules
  Future<List<AutomationRule>> getEnabledRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'automation_rules',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _ruleFromMap(map)).toList();
  }

  /// Update an existing rule
  Future<int> updateRule(AutomationRule rule) async {
    final db = await database;

    final data = {
      'name': rule.name,
      'enabled': rule.enabled ? 1 : 0,
      'conditions': jsonEncode(rule.conditions.map((e) => e.toJson()).toList()),
      'startActions': jsonEncode(
        rule.startActions.map((e) => e.toJson()).toList(),
      ),
      'endActions': jsonEncode(rule.endActions.map((e) => e.toJson()).toList()),
      'hasEndActions': rule.hasEndActions,
      'last_triggered': rule.lastTriggered?.toIso8601String(),
    };

    return await db.update(
      'automation_rules',
      data,
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// Toggle rule enabled/disabled
  Future<int> toggleRule(String id, bool enabled) async {
    final db = await database;
    return await db.update(
      'automation_rules',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update last triggered time and increment counter
  Future<void> markRuleTriggered(String id) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE automation_rules 
      SET last_triggered = ?, trigger_count = trigger_count + 1
      WHERE id = ?
    ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Delete a rule
  Future<int> deleteRule(String id) async {
    final db = await database;
    return await db.delete(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all rules
  Future<int> deleteAllRules() async {
    final db = await database;
    return await db.delete('automation_rules');
  }

  // ════════════════════════════════════════════════════════
  // RULE HISTORY
  // ════════════════════════════════════════════════════════

  /// Log rule trigger
  Future<int> logRuleTrigger({
    required String ruleId,
    required Map<String, dynamic> sensorValues,
    required List<String> actionsExecuted,
  }) async {
    final db = await database;

    return await db.insert('rule_history', {
      'rule_id': ruleId,
      'triggered_at': DateTime.now().toIso8601String(),
      'sensor_values': jsonEncode(sensorValues),
      'actions_executed': jsonEncode(actionsExecuted),
    });
  }

  /// Get rule history
  Future<List<Map<String, dynamic>>> getRuleHistory(
    String ruleId, {
    int limit = 50,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rule_history',
      where: 'rule_id = ?',
      whereArgs: [ruleId],
      orderBy: 'triggered_at DESC',
      limit: limit,
    );

    return maps;
  }

  /// Clear old history (keep last 100 records per rule)
  Future<void> cleanupHistory() async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM rule_history 
      WHERE id NOT IN (
        SELECT id FROM rule_history 
        ORDER BY triggered_at DESC 
        LIMIT 100
      )
    ''');
  }

  // ════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════

  AutomationRule _ruleFromMap(Map<String, dynamic> map) {
    return AutomationRule(
      id: map['id'],
      name: map['name'],
      enabled: map['enabled'] == 1,
      conditions: (jsonDecode(map['conditions']) as List)
          .map((e) => Condition.fromJson(e))
          .toList(),
      actions: (jsonDecode(map['actions']) as List)
          .map((e) => Action.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(map['created_at']),
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'])
          : null,
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
