import 'cache_manager.dart';

class InMemoryStore {
  final int maxEntries;
  final Map<String, CacheEntry> _map = {};
  final List<String> _lru = [];

  InMemoryStore({this.maxEntries = 1000});

  void put(String key, CacheEntry entry) {
    if (_map.containsKey(key)) {
      _lru.remove(key);
    }
    _map[key] = entry;
    _lru.insert(0, key);
    if (_map.length > maxEntries) {
      final removed = _lru.removeLast();
      _map.remove(removed);
    }
  }

  CacheEntry<T>? get<T>(String key) {
    final entry = _map[key] as CacheEntry<T>?;
    if (entry != null) {
      _lru.remove(key);
      _lru.insert(0, key);
    }
    return entry;
  }

  void remove(String key) {
    _map.remove(key);
    _lru.remove(key);
  }

  void clear() {
    _map.clear();
    _lru.clear();
  }

  void removeExpired() {
    final now = DateTime.now();
    final expired = <String>[];
    _map.forEach((key, entry) {
      if (entry.expiresAt != null && now.isAfter(entry.expiresAt!)) {
        expired.add(key);
      }
    });
    for (var key in expired) {
      remove(key);
    }
  }
}
