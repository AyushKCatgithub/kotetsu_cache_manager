import 'dart:convert';

abstract class JsonSerializable {
  Map<String, dynamic> toJson();
}

String encodeForStorage(Object? value) {
  if (value == null) return jsonEncode(null);
  if (value is String) return jsonEncode(value);
  if (value is JsonSerializable) return jsonEncode(value.toJson());
  return jsonEncode(value);
}

dynamic decodeFromStorage(String json) {
  return jsonDecode(json);
}
