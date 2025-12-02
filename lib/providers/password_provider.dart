import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';
import '../services/storage_service.dart';
import '../services/google_sheets_service.dart';

class PasswordProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<PasswordEntry> _entries = [];
  List<String> _categories = [];
  bool _isLoading = true;
  Timer? _syncTimer;
  DateTime? _lastSyncTime;

  List<PasswordEntry> get entries => _entries;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isCloudSyncEnabled => _sheetsService.isConfigured;
  DateTime? get lastSyncTime => _lastSyncTime;

  PasswordProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Load local data first for speed
      _entries = await _storageService.readAll();
      _categories = await _storageService.readCategories();
    } catch (e) {
      print('Error loading local data: $e');
      _entries = [];
      _categories = [];
    } finally {
      // Show local data immediately
      _isLoading = false;
      notifyListeners();
    }

    try {
      // Check for Sheets URL and sync in background
      final sheetsUrl = await _storageService.readSheetsUrl();
      if (sheetsUrl != null) {
        _sheetsService.setUrl(sheetsUrl);
        // Initial sync
        await syncNow();
        // Start auto-sync timer
        _startAutoSync();
      }
    } catch (e) {
      print('Error during background sync: $e');
    }
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isCloudSyncEnabled) {
        print('Auto-syncing...');
        syncNow();
      }
    });
  }

  Future<void> syncNow() async {
    if (!_sheetsService.isConfigured) return;

    try {
      // 1. Fetch from cloud
      final cloudEntries = await _sheetsService.fetchAll();
      final cloudCategories = await _sheetsService.fetchCategories();

      // 2. Merge strategies
      // Ideally, we should merge local and cloud.
      // For now, we prioritize Cloud for entries, but we ensure we don't lose local-only data if possible.
      // Actually, for "Restore" functionality (App Clear -> Connect), Cloud is truth.

      if (cloudEntries.isNotEmpty) {
        // Update local entries from cloud
        for (var cloudEntry in cloudEntries) {
          final index = _entries.indexWhere((e) => e.id == cloudEntry.id);
          if (index != -1) {
            _entries[index] = cloudEntry;
          } else {
            _entries.add(cloudEntry);
          }
        }
        await _storageService.write(_entries);
      }

      // 3. Push Local-only entries to Cloud
      // If we have entries locally that aren't in the cloud, we should push them.
      final cloudIds = cloudEntries.map((e) => e.id).toSet();
      for (var localEntry in _entries) {
        if (!cloudIds.contains(localEntry.id)) {
          print('Pushing local entry to cloud: ${localEntry.title}');
          await _sheetsService.syncEntry(localEntry);
        }
      }

      // 4. Robust Category Sync
      // Infer categories from passwords (in case Categories sheet is empty/outdated)
      final Set<String> allCategories = Set.from(_categories);
      allCategories.addAll(cloudCategories);

      // Add categories found in entries
      for (var entry in _entries) {
        if (entry.category != null && entry.category!.isNotEmpty) {
          allCategories.add(entry.category!);
        }
      }

      // Update local categories
      _categories = allCategories.toList()..sort();
      await _storageService.writeCategories(_categories);

      // 5. Push back to Cloud (Self-healing)
      // If we found categories locally or in entries that weren't in the cloud list,
      // we should update the Cloud 'Categories' sheet.
      if (allCategories.length > cloudCategories.length) {
        print('Syncing merged categories to cloud...');
        await _sheetsService.syncCategories(_categories);
      }

      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('Error syncing: $e');
    }
  }

  Future<void> openSheet() async {
    await _sheetsService.openSheet();
  }

  Future<void> setSheetsUrl(String url) async {
    _sheetsService.setUrl(url);
    await _storageService.saveSheetsUrl(url);
    notifyListeners();
    await syncNow();
    _startAutoSync();
  }

  Future<void> addEntry(
    String title,
    String username,
    String password,
    String? website,
    String? category,
    String? notes,
  ) async {
    final newEntry = PasswordEntry(
      id: const Uuid().v4(),
      title: title,
      username: username,
      password: password,
      website: website,
      category: category,
      notes: notes,
      lastModified: DateTime.now(),
    );
    _entries.add(newEntry);
    await _storageService.write(_entries);
    notifyListeners();

    if (isCloudSyncEnabled) {
      await _sheetsService.syncEntry(newEntry);
    }
  }

  Future<void> updateEntry(PasswordEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      updatedEntry.lastModified = DateTime.now();
      _entries[index] = updatedEntry;
      await _storageService.write(_entries);
      notifyListeners();

      if (isCloudSyncEnabled) {
        await _sheetsService.syncEntry(updatedEntry);
      }
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storageService.write(_entries);
    notifyListeners();

    if (isCloudSyncEnabled) {
      await _sheetsService.deleteEntry(id);
    }
  }

  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      await _storageService.writeCategories(_categories);
      notifyListeners();

      if (isCloudSyncEnabled) {
        await _sheetsService.syncCategories(_categories);
      }
    }
  }

  Future<void> deleteCategory(String category) async {
    _categories.remove(category);
    await _storageService.writeCategories(_categories);
    notifyListeners();

    if (isCloudSyncEnabled) {
      await _sheetsService.syncCategories(_categories);
    }
  }

  Future<void> updateCategory(String oldCategory, String newCategory) async {
    final index = _categories.indexOf(oldCategory);
    if (index != -1) {
      _categories[index] = newCategory;
      await _storageService.writeCategories(_categories);

      // Update entries using this category
      for (var entry in _entries) {
        if (entry.category == oldCategory) {
          entry.category = newCategory;
          if (isCloudSyncEnabled) await _sheetsService.syncEntry(entry);
        }
      }
      await _storageService.write(_entries);
      notifyListeners();

      if (isCloudSyncEnabled) {
        await _sheetsService.syncCategories(_categories);
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
