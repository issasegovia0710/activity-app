import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> setItem(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }

    await _secureStorage.write(
      key: key,
      value: value,
    );
  }

  static Future<String?> getItem(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }

    return await _secureStorage.read(
      key: key,
    );
  }

  static Future<void> removeItem(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }

    await _secureStorage.delete(
      key: key,
    );
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return;
    }

    await _secureStorage.deleteAll();
  }
}