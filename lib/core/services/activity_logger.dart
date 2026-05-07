import 'dart:convert';
import 'storage_service.dart';

class ActivityLog {
  final String event;
  final DateTime timestamp;
  final String? details;

  ActivityLog({required this.event, required this.timestamp, this.details});

  Map<String, dynamic> toJson() => {
    'event': event,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    event: json['event'],
    timestamp: DateTime.parse(json['timestamp']),
    details: json['details'],
  );
}

class ActivityLogger {
  static const _logsKey = 'activity_logs';
  final StorageService _storage = StorageService();

  Future<void> logEvent(String event, {String? details}) async {
    final logs = await getLogs();
    logs.insert(0, ActivityLog(
      event: event,
      timestamp: DateTime.now(),
      details: details,
    ));
    
    // Keep only last 100 logs
    if (logs.length > 100) logs.removeRange(100, logs.length);
    
    final jsonList = logs.map((l) => l.toJson()).toList();
    await _storage.saveSecureData(_logsKey, jsonEncode(jsonList));
  }

  Future<List<ActivityLog>> getLogs() async {
    final data = await _storage.getSecureData(_logsKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((j) => ActivityLog.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    await _storage.deleteSecureData(_logsKey);
  }
}
