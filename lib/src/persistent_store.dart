import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';
import 'serialization.dart';

class PersistentStore {
  final String prefix;
  PersistentStore({this.prefix = 'kotetsu_'});

  Future<void> save<T>(String key, T value, {DateTime? expiresAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'value': encodeForStorage(value),
      'expiresAt': expiresAt?.toIso8601String(),
      'type': value.runtimeType.toString(),
    };
    await prefs.setString(prefix + key, jsonEncode(map));
  }

  Future<CacheEntry<T>?> load<T>(String key, {T Function(dynamic)? fromJson}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefix + key);
    if (raw == null) return null;
    final map = jsonDecode(raw);
    final expiresAt = map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null;
    final decoded = decodeFromStorage(map['value']);
    final value = fromJson != null ? fromJson(decoded) : decoded as T;
    return CacheEntry<T>(value, expiresAt: expiresAt);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefix + key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (var k in keys) {
      await prefs.remove(k);
    }
  }
}
