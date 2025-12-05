import 'dart:async';
import 'in_memory_store.dart';
import 'persistent_store.dart';

class CacheEntry<T> {
  final T value;
  final DateTime? expiresAt;
  CacheEntry(this.value, {this.expiresAt});
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class CacheManager {
  final InMemoryStore _store;
  final PersistentStore? _persistentStore;
  final Duration _cleanupInterval;
  Timer? _cleanupTimer;

  CacheManager._(this._store, this._persistentStore, this._cleanupInterval) {
    _startCleanup();
  }

  factory CacheManager({
    int maxEntries = 1000,
    PersistentStore? persistentStore,
    Duration cleanupInterval = const Duration(minutes: 5),
  }) {
    final store = InMemoryStore(maxEntries: maxEntries);
    return CacheManager._(store, persistentStore, cleanupInterval);
  }

  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _cleanupExpired());
  }

  void _cleanupExpired() {
    _store.removeExpired();
  }

  Future<void> put<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _store.put(key, CacheEntry<T>(value, expiresAt: expiresAt));
    if (_persistentStore != null) {
      await _persistentStore!.save(key, value, expiresAt: expiresAt);
    }
  }

  Future<T?> get<T>(String key, {T Function(dynamic)? fromJson}) async {
    final entry = _store.get<T>(key);
    if (entry != null) {
      if (entry.isExpired) {
        await remove(key);
        return null;
      }
      return entry.value;
    }
    if (_persistentStore != null) {
      final persisted = await _persistentStore!.load<T>(key, fromJson: fromJson);
      if (persisted != null) {
        if (persisted.isExpired) {
          await _persistentStore!.remove(key);
          return null;
        }
        _store.put(key, persisted);
        return persisted.value;
      }
    }
    return null;
  }

  Future<void> remove(String key) async {
    _store.remove(key);
    if (_persistentStore != null) {
      await _persistentStore!.remove(key);
    }
  }

  Future<void> clear() async {
    _store.clear();
    if (_persistentStore != null) {
      await _persistentStore!.clear();
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}
