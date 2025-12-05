# kotetsu_cache_manager

A lightweight, fast, in-memory and persistent cache manager for Flutter and Dart with TTL-based expiry and LRU eviction. Designed to simplify state caching, reduce repeated API calls, and enable quick offline reads.

## Features
- In-memory cache with LRU eviction
- Optional persistence using SharedPreferences
- TTL-based auto expiry
- Works with primitives, maps, lists, and custom models
- Simple async API
- Lightweight and dependency-minimal

## Installation

Add the dependency:

```yaml
dependencies:
  kotetsu_cache_manager: ^0.0.1
```

Run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:kotetsu_cache_manager/kotetsu_cache_manager.dart';

final cache = CacheManager(
  maxEntries: 200,
  persistentStore: PersistentStore(),
);

await cache.put('greet', 'Hello', ttl: Duration(minutes: 5));
final value = await cache.get<String>('greet');
```

### Storing Custom Models

```dart
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

final user = User(id: '1', name: 'Ayush');
await cache.put('user:1', user);

final fetched = await cache.get<User>(
  'user:1',
  fromJson: (data) => User.fromJson(data),
);
```

### Removing and Clearing

```dart
await cache.remove('greet');
await cache.clear();
```

## API Summary

### CacheManager

```dart
CacheManager({
  int maxEntries = 1000,
  PersistentStore? persistentStore,
  Duration cleanupInterval = const Duration(minutes: 5),
});
```

### Methods

```dart
Future<void> put<T>(String key, T value, {Duration? ttl});
Future<T?> get<T>(String key, {T Function(dynamic)? fromJson});
Future<void> remove(String key);
Future<void> clear();
void dispose();
```

## Notes
- Persistence is optional and enabled through `PersistentStore()`.
- Custom model types require a `fromJson` mapper for reads from disk.
- TTL removes expired entries automatically.

## Example

A full example is available in the `example/` folder.

## License

MIT License
