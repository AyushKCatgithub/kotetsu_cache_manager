import 'package:flutter_test/flutter_test.dart';
import 'package:kotetsu_cache_manager/kotetsu_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User implements JsonSerializable {
  final String id;
  final String name;
  User({required this.id, required this.name});
  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('put and get with ttl expiry', () async {
    final cache = CacheManager(maxEntries: 10);
    await cache.put('a', 1, ttl: Duration(milliseconds: 80));
    final v1 = await cache.get<int>('a');
    expect(v1, 1);
    await Future.delayed(Duration(milliseconds: 120));
    final v2 = await cache.get<int>('a');
    expect(v2, null);
    cache.dispose();
  });

  test('LRU eviction respects maxEntries and recency updates', () async {
    final cache = CacheManager(maxEntries: 2);
    await cache.put('a', 'A');
    await cache.put('b', 'B');
    var b1 = await cache.get<String>('b');
    expect(b1, 'B');
    await cache.put('c', 'C');
    final a = await cache.get<String>('a');
    final b = await cache.get<String>('b');
    final c = await cache.get<String>('c');
    expect(a, null);
    expect(b, 'B');
    expect(c, 'C');
    cache.dispose();
  });

  test('persistence rehydrate for primitive and custom model', () async {
    final store = PersistentStore();
    final cache1 = CacheManager(persistentStore: store, maxEntries: 5);
    await cache1.put('num', 42);
    final user = User(id: 'u1', name: 'Ayush');
    await cache1.put('user:u1', user, ttl: Duration(minutes: 5));
    cache1.dispose();

    final cache2 = CacheManager(persistentStore: store, maxEntries: 5);
    final n = await cache2.get<int>('num');
    final fetchedUser = await cache2.get<User>('user:u1', fromJson: (j) => User.fromJson(j as Map<String, dynamic>));
    expect(n, 42);
    expect(fetchedUser?.id, 'u1');
    expect(fetchedUser?.name, 'Ayush');
    cache2.dispose();
  });

  test('remove and clear remove from memory and persistent storage', () async {
    final store = PersistentStore();
    final cache = CacheManager(persistentStore: store, maxEntries: 5);
    await cache.put('k1', 'v1');
    await cache.put('k2', 'v2');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kotetsu_k1'), isNotNull);
    await cache.remove('k1');
    final afterRemove = await cache.get<String>('k1');
    expect(afterRemove, null);
    await cache.clear();
    final afterClearK2 = await cache.get<String>('k2');
    expect(afterClearK2, null);
    cache.dispose();
  });

  test('cleanup timer removes expired entries from memory', () async {
    final cache = CacheManager(maxEntries: 10, cleanupInterval: Duration(milliseconds: 50));
    await cache.put('t', 'x', ttl: Duration(milliseconds: 80));
    final immediate = await cache.get<String>('t');
    expect(immediate, 'x');
    await Future.delayed(Duration(milliseconds: 200));
    final after = await cache.get<String>('t');
    expect(after, null);
    cache.dispose();
  });

  test('concurrent puts and gets remain consistent', () async {
    final cache = CacheManager(maxEntries: 50);
    final futures = <Future>[];
    for (var i = 0; i < 20; i++) {
      futures.add(cache.put('k$i', i));
    }
    await Future.wait(futures);
    final reads = await Future.wait(List.generate(20, (i) => cache.get<int>('k$i')));
    for (var i = 0; i < 20; i++) {
      expect(reads[i], i);
    }
    cache.dispose();
  });
}
