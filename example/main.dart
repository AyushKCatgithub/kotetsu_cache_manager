import 'package:kotetsu_cache_manager/kotetsu_cache_manager.dart';
import 'package:flutter/material.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = CacheManager(persistentStore: PersistentStore());
  await cache.put('text', 'Hello', ttl: Duration(seconds: 10));
  final value = await cache.get<String>('text');
  final user = User(id: '1', name: 'Ayush');
  await cache.put('user:1', user);
  final fetched = await cache.get<User>('user:1', fromJson: (data) => User.fromJson(data));
  runApp(MaterialApp(home: Scaffold(body: Center(child: Text(value.toString() + fetched!.name)))));
}
