import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/password_entry.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _key = 'password_entries';
  static const _categoriesKey = 'categories';
  static const _themeKey = 'is_dark_mode';

  Future<List<PasswordEntry>> readAll() async {
    final String? data = await _storage.read(key: _key);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => PasswordEntry.fromJson(json)).toList();
  }

  Future<void> write(List<PasswordEntry> entries) async {
    final String data = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _storage.write(key: _key, value: data);
  }

  Future<List<String>> readCategories() async {
    final String? data = await _storage.read(key: _categoriesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.cast<String>();
  }

  Future<void> writeCategories(List<String> categories) async {
    final String jsonString = jsonEncode(categories);
    await _storage.write(key: _categoriesKey, value: jsonString);
  }

  Future<void> saveThemeMode(bool isDark) async {
    await _storage.write(key: _themeKey, value: isDark.toString());
  }

  Future<bool> readThemeMode() async {
    final String? value = await _storage.read(key: _themeKey);
    // Default to true (Dark Mode) if not set
    return value == null ? true : value == 'true';
  }

  Future<void> saveSheetsUrl(String url) async {
    await _storage.write(key: 'sheets_url', value: url);
  }

  Future<String?> readSheetsUrl() async {
    return await _storage.read(key: 'sheets_url');
  }

  Future<void> deleteAll() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _categoriesKey);
    await _storage.delete(key: _themeKey);
    await _storage.delete(key: 'sheets_url');
  }
}
